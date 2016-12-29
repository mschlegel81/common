UNIT mySys;
INTERFACE
USES dos,myGenerics,sysutils,Process,{$ifdef Windows}windows,{$endif}FileUtil,Classes,LazUTF8;

TYPE
  T_fileAttrib=(aExistent ,
                aReadOnly ,
                aHidden   ,
                aSysFile  ,
                aVolumeId ,
                aDirectory,
                aArchive  ,
                aSymLink  );
CONST
  C_fileAttribName:array[T_fileAttrib] of string=(
    'existent',
    'readOnly',
    'hidden',
    'sysFile',
    'volumeId',
    'directory',
    'archive',
    'symLink');
TYPE
  T_fileAttribs=set of T_fileAttrib;
  T_fileInfo=record
    filePath:string;
    time:double;
    size:int64;
    attributes:T_fileAttribs;
  end;
  T_fileInfoArray=array of T_fileInfo;

FUNCTION getEnvironment:T_arrayOfString;
FUNCTION findDeeply(CONST rootPath,searchPattern:ansistring):ansistring;
FUNCTION findOne(CONST searchPattern:ansistring):ansistring;
FUNCTION runCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString; OUT output: TStringList): boolean;
PROCEDURE clearConsole;
FUNCTION containsPlaceholder(CONST S:string):boolean;
FUNCTION findFileInfo(CONST pathOrPattern:string):T_fileInfoArray;
FUNCTION getNumberOfCPUs:longint;
FUNCTION MemoryUsed: int64;
{$ifdef Windows}
  PROCEDURE deleteMyselfOnExit;
  {$ifndef DEBUGMODE}
  FUNCTION GetConsoleWindow: HWND; stdcall; external kernel32;
  {$endif}
{$endif}
PROCEDURE showConsole;
PROCEDURE hideConsole;
FUNCTION isConsoleShowing:boolean;
PROCEDURE writeFile(CONST fileName:string; CONST lines:T_arrayOfString);
FUNCTION readFile(CONST fileName:string):T_arrayOfString;

IMPLEMENTATION
VAR numberOfCPUs:longint=0;
FUNCTION getNumberOfCPUs:longint;
{$ifdef Windows}
{$WARN 5057 OFF}
  VAR SystemInfo:SYSTEM_INFO;
  begin
    if numberOfCPUs>0 then exit(numberOfCPUs);
    getSystemInfo(SystemInfo);
    numberOfCPUs:=SystemInfo.dwNumberOfProcessors;
    result:=numberOfCPUs;
  end;
{$else}
  VAR param:T_arrayOfString;
      output: TStringList;
      i:longint;
  begin
    if numberOfCPUs>=0 then exit(numberOfCPUs);
    param:='-c';
    append(param,'nproc');
    runCommand('sh',param,output);
    result:=-1;
    for i:=0 to output.count-1 do if result<0 then result:=strToIntDef(output[i],-1);
    if result<0 then result:=1;
    numberOfCPUs:=result;
    output.destroy;
  end;
{$endif}

FUNCTION getEnvironment:T_arrayOfString;
  VAR i:longint;
      s:string;
  begin
    setLength(result,0);
    for i:=1 to GetEnvironmentVariableCount do begin
      s:=GetEnvironmentString(i);
      if copy(s,1,1)<>'=' then append(result,s);
    end;
  end;

FUNCTION findDeeply(CONST rootPath,searchPattern:ansistring):ansistring;
  PROCEDURE recursePath(CONST path: ansistring);
    VAR info: TSearchRec;
    FUNCTION deeper:ansistring;
      begin
        if (pos('?',path)>=0) or (pos('*',path)>=0)
        then result:=ExtractFileDir(path)+DirectorySeparator+info.name+DirectorySeparator
        else result:=path+info.name+DirectorySeparator;
      end;

    begin
      if (result='') and (findFirst(path+searchPattern, faAnyFile, info) = 0) then result:=path+info.name;
      sysutils.findClose(info);

      if findFirst(path+'*', faDirectory, info) = 0 then repeat
        if ((info.Attr and faDirectory) = faDirectory) and
           (info.name<>'.') and
           (info.name<>'..')
        then recursePath(deeper);
      until (findNext(info)<>0) or (result<>'');
      sysutils.findClose(info);
    end;

  begin
    result:='';
    recursePath(rootPath);
  end;

FUNCTION findOne(CONST searchPattern:ansistring):ansistring;
  VAR info: TSearchRec;
  begin
    if findFirst(searchPattern,faAnyFile,info)=0
    then result:=info.name
    else result:='';
    sysutils.findClose(info);
  end;

FUNCTION runCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString; OUT output: TStringList): boolean;
  CONST
    READ_BYTES = 2048;
  VAR
    memStream: TMemoryStream;
    tempProcess: TProcess;
    n: longint;
    BytesRead: longint;
    sleepTime: longint = 1;
  begin
    memStream := TMemoryStream.create;
    BytesRead := 0;
    tempProcess := TProcess.create(nil);
    tempProcess.executable := UTF8ToWinCP(executable);
    for n := 0 to length(parameters)-1 do
      tempProcess.parameters.add(UTF8ToWinCP(parameters[n]));
    tempProcess.options := [poUsePipes, poStderrToOutPut];
    tempProcess.ShowWindow := swoHIDE;
    try
      tempProcess.execute;
      tempProcess.CloseInput;
      while tempProcess.running do begin
        memStream.SetSize(BytesRead+READ_BYTES);
        n := tempProcess.output.read((memStream.memory+BytesRead)^, READ_BYTES);
        if n>0 then begin sleepTime:=1; inc(BytesRead, n); end
               else begin inc(sleepTime); sleep(sleepTime); end;
      end;
      if tempProcess.running then tempProcess.Terminate(999);
      repeat
        memStream.SetSize(BytesRead+READ_BYTES);
        n := tempProcess.output.read((memStream.memory+BytesRead)^, READ_BYTES);
        if n>0 then inc(BytesRead, n);
      until n<=0;
      result := (tempProcess.exitStatus = 0);
    except
      result := false;
    end;
    tempProcess.free;
    memStream.SetSize(BytesRead);
    output := TStringList.create;
    output.loadFromStream(memStream);
    memStream.free;
  end;

VAR clearConsoleProcess:TProcess=nil;
PROCEDURE clearConsole;
  begin
    if clearConsoleProcess=nil then begin
      clearConsoleProcess := TProcess.create(nil);
      clearConsoleProcess.options:=clearConsoleProcess.options+[poWaitOnExit];
      {$ifdef LINUX}
      clearConsoleProcess.executable := 'sh';
      clearConsoleProcess.parameters.add('-c');
      clearConsoleProcess.parameters.add('clear');
      {$else}
      clearConsoleProcess.executable := 'cmd';
      clearConsoleProcess.parameters.add('/C');
      clearConsoleProcess.parameters.add('cls');
      {$endif}
    end;
    try
      flush(StdOut);
      clearConsoleProcess.execute;
    except
    end;
  end;

FUNCTION containsPlaceholder(CONST S:string):boolean;
  begin
    result:=(pos('*',s)>0) or (pos('?',s)>0);
  end;

FUNCTION findFileInfo(CONST pathOrPattern:string):T_fileInfoArray;
   VAR info: TSearchRec;
       path: ansistring;
   begin
     path := extractFilePath(pathOrPattern);
     setLength(result, 0);
     if findFirst(pathOrPattern, faAnyFile, info) = 0 then repeat
       if (info.name<>'.') and (info.name<>'..') then begin
         setLength(result, length(result)+1);
         with result[length(result)-1] do begin
           filePath:=path+info.name;
           time:=FileDateToDateTime(info.time);
           size:=info.size;
           attributes:=[aExistent];
           if info.Attr and faReadOnly >0 then include(attributes,aReadOnly );
           if info.Attr and faHidden   >0 then include(attributes,aHidden   );
           if info.Attr and faSysFile  >0 then include(attributes,aSysFile  );
           if info.Attr and faVolumeId >0 then include(attributes,aVolumeId );
           if info.Attr and faDirectory>0 then include(attributes,aDirectory);
           if info.Attr and faArchive  >0 then include(attributes,aArchive  );
           if info.Attr and faSymLink  >0 then include(attributes,aSymLink  );
         end;
       end;
     until (findNext(info)<>0);
     if (length(result)=0) and not(containsPlaceholder(pathOrPattern)) then begin
       setLength(result,1);
       with result[0] do begin
         filePath:=pathOrPattern;
         time:=0;
         size:=-1;
         attributes:=[];
       end;
     end;
     sysutils.findClose(info);
   end;

FUNCTION MemoryUsed: int64;
  begin
    result:=GetHeapStatus.TotalAllocated;
  end;

VAR consoleShowing:longint=1;
FUNCTION isConsoleShowing:boolean;
  begin
    result:={$ifdef Windows}consoleShowing>=1{$else}true{$endif};
  end;

PROCEDURE showConsole;
  begin
    inc(consoleShowing);
    if consoleShowing<1 then consoleShowing:=1;
    {$ifdef Windows}{$ifndef DEBUGMODE}
    ShowWindow(GetConsoleWindow, SW_SHOW);
    {$endif}{$endif}
  end;

PROCEDURE hideConsole;
  begin
    dec(consoleShowing);
    if consoleShowing<=0 then begin
      {$ifdef Windows}{$ifndef DEBUGMODE}
      ShowWindow(GetConsoleWindow, SW_HIDE);
      {$endif}{$endif}
      if consoleShowing<0 then consoleShowing:=0;
    end;
  end;

FUNCTION isValidFilename(CONST fileName: string; CONST requirePathExistence:boolean=true) : boolean;
  CONST ForbiddenChars  : set of char = ['<', '>', '|', '"', '\', ':', '*', '?'];
  VAR i:integer;
      name,path:string;
  begin
    if requirePathExistence then begin
      path:=extractFilePath(fileName);
      name:=extractFileName(fileName);
      result:=(name<>'') and (DirectoryExists(path));
      for i:=1 to length(name)-1 do result:=result and not(name[i] in ForbiddenChars) and not(name[i]='\');
    end else begin
      name:=fileName;
      result:=(fileName<>'');
      for i:=1 to length(name)-1 do result:=result and not(name[i] in ForbiddenChars);
    end;
  end;

FUNCTION dateToSortable(t:TDateTime):ansistring;
  begin
    DateTimeToString(result,'YYYYMMDD_HHmmss',t);
  end;

{$ifdef Windows}
PROCEDURE deleteMyselfOnExit;
  VAR handle:text;
      batName:string;
      counter:longint;
      proc:TProcess;
  begin
    counter:=0;
    repeat
      batName:=paramStr(0)+'delete'+intToStr(counter)+'.bat';
      inc(counter);
    until not(fileExists(batName));
    assign(handle,batName);
    rewrite(handle);
    writeln(handle,':Repeat');
    writeln(handle,'@ping -n 2 127.0.0.1 > NUL');
    writeln(handle,'@del "',paramStr(0),'"');
    writeln(handle,'@if exist "',paramStr(0),'" goto Repeat');
    writeln(handle,'@del %0');
    close(handle);
    proc:=TProcess.create(nil);
    proc.executable:='cmd';
    proc.parameters.add('/C');
    proc.parameters.add(batName);
    proc.execute;
  end;
{$endif}

PROCEDURE writeFile(CONST fileName:string; CONST lines:T_arrayOfString);
  VAR handle:text;
      i:longint;
  begin
    assign(handle,fileName);
    rewrite(handle);
    for i:=0 to length(lines)-1 do writeln(handle,lines[i]);
    close(handle);
  end;

FUNCTION readFile(CONST fileName:string):T_arrayOfString;
  VAR handle:text;
  begin
    if not(fileExists(fileName)) then exit(C_EMPTY_STRING_ARRAY);
    assign(handle,fileName);
    reset(handle);
    setLength(result,0);
    while not(eof(handle)) do begin
      setLength(result,length(result)+1);
      readln(handle,result[length(result)-1]);
    end;
    close(handle);
  end;

FINALIZATION
  if clearConsoleProcess<>nil then clearConsoleProcess.destroy;

end.
