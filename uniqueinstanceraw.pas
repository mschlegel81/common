UNIT UniqueInstanceRaw;
{$mode objfpc}{$H+}

INTERFACE

USES
 {$ifdef UNIX}cmem,cthreads,{$endif}
  Classes, sysutils, SimpleIPC;

  FUNCTION InstanceRunning(CONST Identifier: string; SendParameters: boolean = false): boolean;

  FUNCTION InstanceRunning: boolean;
VAR
  FIPCServer: TSimpleIPCServer;
IMPLEMENTATION

USES
  SimpleIPCWrapper;

CONST
  BaseServerId = 'tuniqueinstance_';
  Separator = '|';



FUNCTION GetFormattedParams: string;
VAR
  i: integer;
begin
  result := '';
  {$ifdef expandFileNames}
  for i := 1 to paramCount do if paramStr(i)[1]='-'
    then result := result +                paramStr(i)  + Separator
    else result := result + expandFileName(paramStr(i)) + Separator;
  {$else}
  for i := 1 to paramCount do result := result + paramStr(i)  + Separator;
  {$endif}
end;

FUNCTION InstanceRunning(CONST Identifier: string; SendParameters: boolean = false): boolean;

  FUNCTION GetServerId: string;
  begin
    if Identifier <> '' then
      result := BaseServerId + Identifier
    else
      result := BaseServerId + extractFileName(paramStr(0));
  end;

VAR
  Client: TSimpleIPCClient;

begin
  Client := TSimpleIPCClient.create(nil);
  with Client do
  try
    ServerID := GetServerId;
    result := IsServerRunning(Client);
    if not result then
    begin
      //It's the first instance. Init the server
      if FIPCServer = nil then
        FIPCServer := TSimpleIPCServer.create(nil);
      FIPCServer.ServerID := ServerID;
      FIPCServer.Global := true;
      InitServer(FIPCServer);
    end
    else
      // an instance already exists
      if SendParameters then
      begin
        Active := true;
        SendStringMessage(paramCount, GetFormattedParams);
      end;
  finally
    free;
  end;
end;

FUNCTION InstanceRunning: boolean;
begin
  result := InstanceRunning('');
end;

FINALIZATION
  FIPCServer.free;

end.

