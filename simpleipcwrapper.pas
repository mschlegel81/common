UNIT SimpleIPCWrapper;

// SimpleIPC has a flaw under unix (bug 17248).
// Use this workaround since there's no way to extend SimpleIPC classes directly (bug 19136)

{$mode objfpc}{$H+}

INTERFACE

USES
  {$ifdef UNIX}cmem,cthreads,{$endif}
  Classes, sysutils, SimpleIPC;

PROCEDURE InitServer(Server: TSimpleIPCServer);

FUNCTION IsServerRunning(Client: TSimpleIPCClient): boolean;

IMPLEMENTATION

{$ifdef unix}
USES
  baseunix;

CONST
  //F_RDLCK = 0;
  F_WRLCK = 1;
  //F_UNLCK = 2;

FUNCTION GetPipeFileName(Server: TSimpleIPCServer): string;
begin
  result := Server.ServerID;
  if not Server.Global then
    result := result + '-' + intToStr(fpGetPID);
  result := '/tmp/' + result;
end;

FUNCTION GetPipeFileName(Client: TSimpleIPCClient): string;
begin
  result := Client.ServerID;
  if Client.ServerInstance <> '' then
    result := result + '-' + Client.ServerInstance;
  result := '/tmp/' + result;
end;

FUNCTION SetLock(FileDescriptor: cint): boolean;
VAR
  LockInfo: FLock;
begin
  LockInfo.l_type := F_WRLCK;
  LockInfo.l_whence := SEEK_SET;
  LockInfo.l_len := 0;
  LockInfo.l_start := 0;
  result := FpFcntl(FileDescriptor, F_SetLk, LockInfo) <> -1;
end;

PROCEDURE InitServer(Server: TSimpleIPCServer);
VAR
  PipeFileName: string;
  PipeDescriptor: cint;
begin
  Server.StartServer;
  PipeFileName := GetPipeFileName(Server);
  PipeDescriptor := FpOpen(PipeFileName, O_RDWR, $1B6);
  if PipeDescriptor <> -1 then
  begin
    //Pipe file created. Try to set the lock
    if not SetLock(PipeDescriptor) then
    begin
      FpClose(PipeDescriptor);
      raise Exception.CreateFmt('UniqueInstance - A server instance of %s is already running', [Server.ServerID]);
    end;
  end
  else
    raise Exception.CreateFmt('UniqueInstance - Error creating pipe file for server %s', [Server.ServerID]);
end;

FUNCTION IsServerRunning(Client: TSimpleIPCClient): boolean;
VAR
  PipeFileName: string;
  PipeDescriptor: cint;
begin
  //check the pipe file
  PipeFileName := GetPipeFileName(Client);
  PipeDescriptor := FpOpen(PipeFileName, O_RDWR, $1B6);
  result := PipeDescriptor <> -1;
  if result then
  begin
    // pipe file exists
    // try to set the lock
    // if lock is created then is a stale file (server process crashed or killed)
    result := not SetLock(PipeDescriptor);
    FpClose(PipeDescriptor);
    if not result then
    begin
      //delete stale file
      FpUnlink(PipeFileName);
    end;
  end;
end;

{$else}

PROCEDURE InitServer(Server: TSimpleIPCServer);
begin
  Server.StartServer;
end;

FUNCTION IsServerRunning(Client: TSimpleIPCClient): boolean;
begin
  result := Client.ServerRunning;
end;

{$endif}


end.

