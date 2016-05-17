UNIT mySys;
INTERFACE
USES dos,myGenerics,sysutils,Process,{$ifdef WINDOWS}windows,{$endif}FileUtil,Classes;

FUNCTION getEnvironment:T_arrayOfString;
FUNCTION findDeeply(CONST rootPath,searchPattern:ansistring):ansistring;
FUNCTION findOne(CONST searchPattern:ansistring):ansistring;
PROCEDURE clearConsole;
PROCEDURE getFileInfo(CONST filePath:string; OUT time:double; OUT size:int64; OUT isExistent, isArchive, isDirectory, isReadOnly, isSystem, isHidden:boolean);
FUNCTION getNumberOfCPUs:longint;
FUNCTION MemoryUsed: int64;
PROCEDURE writeString(VAR handle:file; CONST s:ansistring);
FUNCTION readString(VAR handle:file):ansistring;
{$ifdef WINDOWS}
  PROCEDURE deleteMyselfOnExit;
  {$ifndef debugMode}
  FUNCTION GetConsoleWindow: HWND; stdcall; external kernel32;
  {$endif}
{$endif}
PROCEDURE showConsole;
PROCEDURE hideConsole;
PROCEDURE writeFile(CONST fileName:string; CONST lines:T_arrayOfString);
FUNCTION readFile(CONST fileName:string):T_arrayOfString;

IMPLEMENTATION
FUNCTION getNumberOfCPUs:longint;
{$ifdef WINDOWS}
  VAR SystemInfo:SYSTEM_INFO;
  begin
    getSystemInfo(SystemInfo);
    result:=SystemInfo.dwNumberOfProcessors;
  end;
{$else}
  begin
    result:=1;
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
      if (result='') and (FindFirst(path+searchPattern, faAnyFile, info) = 0) then result:=path+info.name;
      sysutils.FindClose(info);

      if FindFirst(path+'*', faDirectory, info) = 0 then repeat
        if ((info.Attr and faDirectory) = faDirectory) and
           (info.name<>'.') and
           (info.name<>'..')
        then recursePath(deeper);
      until (findNext(info)<>0) or (result<>'');
      sysutils.FindClose(info);
    end;

  begin
    result:='';
    recursePath(rootPath);
  end;

FUNCTION findOne(CONST searchPattern:ansistring):ansistring;
  VAR info: TSearchRec;
  begin
    if FindFirst(searchPattern,faAnyFile,info)=0
    then result:=info.name
    else result:='';
    sysutils.FindClose(info);
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

PROCEDURE getFileInfo(CONST filePath:string;
  OUT time:double;
  OUT size:int64;
  OUT isExistent,
      isArchive,
      isDirectory,
      isReadOnly,
      isSystem,
      isHidden:boolean);
  VAR f:file of byte;
      Attr:word=0;
      ft:longint;
  begin
    time:=-1;
    size:=-1;
    isExistent :=false;
    isArchive  :=false;
    isDirectory:=false;
    isReadOnly :=false;
    isSystem   :=false;
    isHidden   :=false;
    if DirectoryExists(filePath) or fileExists(filePath) then begin
      isExistent:=true;
      ft:=fileAge(filePath);
      if ft<>-1 then time:=FileDateToDateTime(ft);

      assign (f,filePath);
      GetFAttr(f,Attr);
      isArchive  :=(Attr and archive  )<>0;
      isDirectory:=(Attr and directory)<>0;
      isReadOnly :=(Attr and readonly )<>0;
      isSystem   :=(Attr and sysfile  )<>0;
      isHidden   :=(Attr and hidden   )<>0;
      if fileExists(filePath) then try
        size:=filesize(filePath);
      except
        size:=-2;
      end;
    end;
  end;

FUNCTION MemoryUsed: int64;
  begin
    result:=GetHeapStatus.TotalAllocated;
  end;

VAR consoleShowing:longint=1;
PROCEDURE showConsole;
  begin
    inc(consoleShowing);
    if consoleShowing<1 then consoleShowing:=1;
    {$ifdef WINDOWS}{$ifndef debugMode}
    ShowWindow(GetConsoleWindow, SW_SHOW);
    {$endif}{$endif}
  end;

PROCEDURE hideConsole;
  begin
    dec(consoleShowing);
    if consoleShowing<=0 then begin
      {$ifdef WINDOWS}{$ifndef debugMode}
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

{$ifdef WINDOWS}
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
    proc.CommandLine:='cmd /C '+batName;
    proc.execute;
  end;
{$endif}

PROCEDURE writeString(VAR handle:file; CONST s:ansistring);
  VAR buffer:array[0..1023] of char;
      bufferFill:longint=0;
  PROCEDURE flushBuffer;
    begin
      if bufferFill=0 then exit;
      BlockWrite(handle,buffer,bufferFill);
      bufferFill:=0;
    end;

  PROCEDURE putChar(CONST c:char);
    begin
      buffer[bufferFill]:=c;
      inc(bufferFill);
      if bufferFill>=length(buffer) then flushBuffer;
    end;

  VAR size:SizeInt;
      i:longint;
  begin
    size:=length(s);
    move(size,buffer,sizeOf(SizeInt)); inc(bufferFill,sizeOf(SizeInt));
    for i:=1 to length(s) do putChar(s[i]);
    flushBuffer;
  end;

FUNCTION readString(VAR handle:file):ansistring;
  VAR buffer:array[0..1023] of char;
      size:SizeInt=0;
      i,j1,j:longint;
  begin
    BlockRead(handle,size,sizeOf(SizeInt));
    i:=0; result:='';
    while i<size do begin
      j1:=size-i; if j1>length(buffer) then j1:=length(buffer);
      BlockRead(handle,buffer,j1);
      for j:=0 to j1-1 do result:=result+buffer[j];
      inc(i,j1);
    end;
  end;

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

end.
