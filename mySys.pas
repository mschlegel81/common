UNIT mySys;
INTERFACE
USES dos,myGenerics,sysutils,Process,{$ifdef Windows}windows,{$endif}FileUtil,Classes,LazUTF8;

TYPE
  T_fileAttrib=(aExistent ,
                aReadOnly ,
                aHidden   ,
                aSysFile  ,
                aDirectory,
                aArchive  ,
                aSymLink  );
CONST
  C_fileAttribName:array[T_fileAttrib] of string=(
    'existent',
    'readOnly',
    'hidden',
    'sysFile',
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

TYPE
  T_xosPrng = object
    private
      criticalSection:TRTLCriticalSection;
      w,x,y,z:dword;
      FUNCTION XOS:dword;inline;
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      PROCEDURE resetSeed(CONST newSeed:dword);
      PROCEDURE resetSeed(CONST s:array of byte);
      PROCEDURE randomize;inline;
      FUNCTION intRandom(CONST imax:int64):int64;
      FUNCTION realRandom:double;
      FUNCTION dwordRandom:dword;
  end;

  F_cleanupCallback=PROCEDURE;

  T_memoryCleaner=object
    private
      cleanerCs:TRTLCriticalSection;
      methods:array of F_cleanupCallback;
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
    public
      PROCEDURE registerCleanupMethod(CONST m:F_cleanupCallback);
      PROCEDURE callCleanupMethods;
  end;

FUNCTION getEnvironment:T_arrayOfString;
FUNCTION findDeeply(CONST rootPath,searchPattern:ansistring):ansistring;
FUNCTION findOne(CONST searchPattern:ansistring):ansistring;
FUNCTION runCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString; OUT output: TStringList): boolean;
PROCEDURE runDetachedCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString);
FUNCTION myCommandLineParameters:T_arrayOfString;
PROCEDURE clearConsole;
FUNCTION containsPlaceholder(CONST S:string):boolean;
FUNCTION findFileInfo(CONST pathOrPattern:string):T_fileInfoArray;
FUNCTION getNumberOfCPUs:longint;
{$ifdef Windows}
  PROCEDURE deleteMyselfOnExit;
  {$ifndef debugMode}
  FUNCTION GetConsoleWindow: HWND; stdcall; external kernel32;
  {$endif}
{$endif}
PROCEDURE showConsole;
PROCEDURE hideConsole;
FUNCTION isConsoleShowing:boolean;
PROCEDURE writeFile(CONST fileName:string; CONST lines:T_arrayOfString);
FUNCTION readFile(CONST fileName:string):T_arrayOfString;
FUNCTION isMemoryInComfortZone:boolean;
FUNCTION getMemoryUsedAsString:string;
VAR memoryComfortThreshold:int64={$ifdef UNIX}1 shl 30{$else}{$ifdef CPU32}1 shl 30{$else}4 shl 30{$endif}{$endif};
    memoryCleaner:T_memoryCleaner;
IMPLEMENTATION
VAR numberOfCPUs:longint=0;
CONSTRUCTOR T_memoryCleaner.create;
  begin
    setLength(methods,0);
    initCriticalSection(cleanerCs);
  end;

DESTRUCTOR T_memoryCleaner.destroy;
  begin
    enterCriticalSection(cleanerCs);
    setLength(methods,0);
    leaveCriticalSection(cleanerCs);
    doneCriticalSection(cleanerCs);
  end;

PROCEDURE T_memoryCleaner.registerCleanupMethod(CONST m:F_cleanupCallback);
  begin
    enterCriticalSection(cleanerCs);
    setLength(methods,length(methods)+1);
    methods[length(methods)-1]:=m;
    leaveCriticalSection(cleanerCs);
  end;

PROCEDURE T_memoryCleaner.callCleanupMethods;
  VAR m:F_cleanupCallback;
  begin
    enterCriticalSection(cleanerCs);
    for m in methods do m();
    leaveCriticalSection(cleanerCs);
  end;

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

FUNCTION runProcess(CONST Process:TProcess; OUT output: TStringList): boolean;
  CONST
    READ_BYTES = 2048;
  VAR
    memStream: TMemoryStream;
    n: longint;
    BytesRead: longint;
    sleepTime: longint = 1;
  begin
    memStream := TMemoryStream.create;
    BytesRead := 0;
    Process.options := [poUsePipes, poStderrToOutPut];
    Process.ShowWindow := swoHIDE;
    try
      Process.execute;
      Process.CloseInput;
      while Process.running do begin
        memStream.setSize(BytesRead+READ_BYTES);
        n := Process.output.read((memStream.memory+BytesRead)^, READ_BYTES);
        if n>0 then begin sleepTime:=1; inc(BytesRead, n); end
               else begin inc(sleepTime); sleep(sleepTime); end;
      end;
      if Process.running then Process.Terminate(999);
      repeat
        memStream.setSize(BytesRead+READ_BYTES);
        n := Process.output.read((memStream.memory+BytesRead)^, READ_BYTES);
        if n>0 then inc(BytesRead, n);
      until n<=0;
      result := (Process.exitStatus = 0);
    except
      result := false;
    end;
    memStream.setSize(BytesRead);
    output := TStringList.create;
    output.loadFromStream(memStream);
    memStream.free;
  end;

FUNCTION runCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString; OUT output: TStringList): boolean;
  VAR tempProcess: TProcess;
      n:longint;
  begin
    tempProcess := TProcess.create(nil);
    tempProcess.executable := {$ifdef Windows}UTF8ToWinCP{$endif}(executable);
    for n := 0 to length(parameters)-1 do
      tempProcess.parameters.add(UTF8ToWinCP(parameters[n]));
    tempProcess.options := [poUsePipes, poStderrToOutPut];
    tempProcess.ShowWindow := swoHIDE;
    result:=runProcess(tempProcess,output);
    tempProcess.free;
  end;

PROCEDURE runDetachedCommand(CONST executable: ansistring; CONST parameters: T_arrayOfString);
  VAR tempProcess: TProcess;
      n:longint;
  begin
    tempProcess := TProcess.create(nil);
    tempProcess.executable := {$ifdef Windows}UTF8ToWinCP{$endif}(executable);
    for n := 0 to length(parameters)-1 do
      tempProcess.parameters.add(UTF8ToWinCP(parameters[n]));
    tempProcess.ShowWindow := swoShowNormal;
    tempProcess.execute;
    tempProcess.free;
  end;

FUNCTION myCommandLineParameters:T_arrayOfString;
  VAR i:longint;
  begin
    setLength(result,paramCount);
    for i:=1 to paramCount do result[i-1]:=paramStr(i);
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
           if info.Attr and faDirectory>0 then include(attributes,aDirectory);
           if info.Attr and faArchive  >0 then include(attributes,aArchive  );
           {$ifdef Windows}
           if info.Attr and faHidden   >0 then include(attributes,aHidden   );
           if info.Attr and faSysFile  >0 then include(attributes,aSysFile  );
           if info.Attr and faSymLink  >0 then include(attributes,aSymLink  );
           {$endif}
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

VAR consoleShowing:longint=1;
FUNCTION isConsoleShowing:boolean;
  begin
    result:={$ifdef Windows}consoleShowing>=1{$else}true{$endif};
  end;

PROCEDURE showConsole;
  begin
    inc(consoleShowing);
    if consoleShowing<1 then consoleShowing:=1;
    {$ifdef Windows}{$ifndef debugMode}
    ShowWindow(GetConsoleWindow, SW_SHOW);
    {$endif}{$endif}
  end;

PROCEDURE hideConsole;
  begin
    dec(consoleShowing);
    if consoleShowing<=0 then begin
      {$ifdef Windows}{$ifndef debugMode}
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

CONSTRUCTOR T_xosPrng.create;
  begin
    initCriticalSection(criticalSection);
    w:=521288629;
    x:=0;
    y:=0;
    z:=362436069;
  end;

DESTRUCTOR T_xosPrng.destroy;
  begin
    doneCriticalSection(criticalSection);
  end;

FUNCTION T_xosPrng.XOS:dword;
  VAR tmp:dword;
  begin
    tmp:=(x xor (x<<15));
    x:=y;
    y:=z;
    z:=w;
    w:=(w xor (w>>21)) xor (tmp xor(tmp>>4));
    result := w;
  end;

PROCEDURE T_xosPrng.resetSeed(CONST newSeed:dword);
  CONST P:array[0..31] of dword=(102334155, 433494437,3185141890, 695895453,1845853122,4009959909, 887448560,2713352312,
                                4204349121,1490993585,1919601489,1252772578,1126134829,1407432322,2942850377,1798021602,
                                2032742589, 663677033, 447430277,1407736169,2048113432,2516238737,2570330033, 510369096,
                                4127319575,3313982129, 668544240, 976072482,1798380843,3210299713,3471333957,3014961506);
  begin
    enterCriticalSection(criticalSection);
    {$Q-}{$R-}
    w:=newSeed;
    x:=(w xor P[ w    and 31]);
    y:=(w xor P[(w+1) and 31]);
    z:=(w xor P[(w+2) and 31]);
    {$Q+}{$R+}
    leaveCriticalSection(criticalSection);
  end;

PROCEDURE T_xosPrng.resetSeed(CONST s:array of byte);
  VAR fullBytes:array[0..15] of byte;
      k:longint;
  begin
    if length(s)=0 then begin
      resetSeed(0);
      exit;
    end;
    enterCriticalSection(criticalSection);
    for k:=0 to 15 do fullBytes[k]:=0;
    if length(s)<length(fullBytes)
    then for k:=0 to length(fullBytes)-1 do fullBytes[k]:=s[k mod length(s)]
    else for k:=0 to length(s)-1 do fullBytes[k mod length(fullBytes)]:=fullBytes[k mod length(fullBytes)] xor s[k];

    move(fullBytes[ 0],w,4);
    move(fullBytes[ 4],x,4);
    move(fullBytes[ 8],y,4);
    move(fullBytes[12],z,4);
    leaveCriticalSection(criticalSection);
  end;

PROCEDURE T_xosPrng.randomize;
  begin
    resetSeed(GetTickCount64);
  end;

FUNCTION T_xosPrng.intRandom(CONST imax:int64):int64;
  begin
    if imax<=1 then exit(0);
    enterCriticalSection(criticalSection);
    {$Q-}{$R-}
    if imax<=4294967296
    then result:=       XOS                           mod imax
    else result:=(int64(XOS) xor (int64(XOS) shl 31)) mod imax;
    {$Q+}{$R+}
    leaveCriticalSection(criticalSection);
  end;

FUNCTION T_xosPrng.realRandom:double;
  begin
    enterCriticalSection(criticalSection);
    result:=XOS*2.3283064365386963E-10;
    leaveCriticalSection(criticalSection);
  end;

FUNCTION T_xosPrng.dwordRandom:dword;
  begin
    enterCriticalSection(criticalSection);
    result:=XOS;
    leaveCriticalSection(criticalSection);
  end;

VAR memCheckThreadsRunning:longint=0;
    memCheckKillRequests:longint=0;
    MemoryUsed:ptrint=0;
FUNCTION memCheckThread({$WARN 5024 OFF}p:pointer):ptrint;
  VAR Process:TProcess;
      output: TStringList;
      i:longint;
      tempMem:ptrint;
  begin
    Process:=TProcess.create(nil);
    {$ifdef UNIX}
      Process.executable:='ps';
      Process.parameters.add('o');
      Process.parameters.add('vsize');
      Process.parameters.add('-p');
      Process.parameters.add(intToStr(GetProcessID));
    {$else}
      Process.executable:='wmic';
      Process.parameters.add('process');
      Process.parameters.add('where');
      Process.parameters.add('ProcessId="'+intToStr(GetProcessID)+'"');
      Process.parameters.add('get');
      Process.parameters.add('workingsetsize');
    {$endif}
    while (memCheckKillRequests<=0) and (memCheckThreadsRunning=1) do begin
      runProcess(Process,output);
      tempMem:=-1;
      for i:=0 to output.count-1 do if tempMem<0 then tempMem:=StrToInt64Def(trim(output[i]),-1);
      if tempMem<0 then MemoryUsed:=GetHeapStatus.TotalAllocated
                   else MemoryUsed:=tempMem;
      output.destroy;
      if MemoryUsed>memoryComfortThreshold then memoryCleaner.callCleanupMethods;
      if (memCheckKillRequests=0) and (MemoryUsed<memoryComfortThreshold) then begin
        sleep(1000);
        ThreadSwitch;
      end;
    end;
    Process.destroy;
    interlockedDecrement(memCheckThreadsRunning);
    interlockedDecrement(memCheckKillRequests);
    result:=0;
  end;

FUNCTION getMemoryUsedAsString:string;
  VAR val:ptrint;
  begin
    val:=MemoryUsed;
    if val<8192 then exit(intToStr(val)+' B');
    val:=val shr 10;
    if val<8192 then exit(intToStr(val)+' kB');
    val:=val shr 10;
    if val<8192 then exit(intToStr(val)+' MB');
    val:=val shr 10;
    result:=intToStr(val)+' GB';
  end;

FUNCTION isMemoryInComfortZone:boolean; inline;
  begin
    if (memCheckThreadsRunning<=0) then begin
      MemoryUsed:=-1;
      interLockedIncrement(memCheckThreadsRunning);
      beginThread(@memCheckThread);
      while MemoryUsed<0 do ThreadSwitch;
    end;
    result:=MemoryUsed<memoryComfortThreshold;
  end;

INITIALIZATION
  memoryCleaner.create;

FINALIZATION
  while memCheckThreadsRunning<0 do begin
    interLockedIncrement(memCheckKillRequests);
    ThreadSwitch;
    sleep(10);
  end;
  if clearConsoleProcess<>nil then clearConsoleProcess.destroy;
  memoryCleaner.destroy;

end.
