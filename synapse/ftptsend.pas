{==============================================================================|
| project : Ararat Synapse                                       | 001.001.001 |
|==============================================================================|
| content: Trivial FTP (TFTP) Client and Server                                |
|==============================================================================|
| Copyright (c)1999-2010, Lukas Gebauer                                        |
| all rights reserved.                                                         |
|                                                                              |
| Redistribution and use in Source and binary Forms, with or without           |
| modification, are permitted provided that the following conditions are met:  |
|                                                                              |
| Redistributions of Source code must retain the above copyright notice, this  |
| list of conditions and the following disclaimer.                             |
|                                                                              |
| Redistributions in binary form must reproduce the above copyright notice,    |
| this list of conditions and the following disclaimer in the documentation    |
| and/or other materials provided with the distribution.                       |
|                                                                              |
| Neither the name of Lukas Gebauer nor the names of its contributors may      |
| be used to endorse or promote products derived from this software without    |
| specific prior written permission.                                           |
|                                                                              |
| THIS SOFTWARE IS PROVIDED by the COPYRIGHT HOLDERS and CONTRIBUTORS "AS IS"  |
| and ANY EXPRESS or IMPLIED WARRANTIES, INCLUDING, BUT not limited to, the    |
| IMPLIED WARRANTIES of MERCHANTABILITY and FITNESS for A PARTICULAR PURPOSE   |
| ARE DISCLAIMED. in no EVENT SHALL the REGENTS or CONTRIBUTORS BE LIABLE for  |
| ANY direct, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, or CONSEQUENTIAL       |
| DAMAGES (INCLUDING, BUT not limited to, PROCUREMENT of SUBSTITUTE GOODS or   |
| SERVICES; LOSS of use, data, or PROFITS; or BUSINESS INTERRUPTION) HOWEVER   |
| CAUSED and on ANY THEORY of LIABILITY, WHETHER in CONTRACT, STRICT           |
| LIABILITY, or TORT (INCLUDING NEGLIGENCE or OTHERWISE) ARISING in ANY WAY    |
| OUT of the use of THIS SOFTWARE, EVEN if ADVISED of the POSSIBILITY of SUCH  |
| DAMAGE.                                                                      |
|==============================================================================|
| the Initial Developer of the original code is Lukas Gebauer (Czech Republic).|
| Portions created by Lukas Gebauer are Copyright (c)2003-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{: @abstract(TFTP client and server protocol)

used RFC: RFC-1350
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT ftptsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil;

CONST
  cTFTPProtocol = '69';

  cTFTP_RRQ = word(1);
  cTFTP_WRQ = word(2);
  cTFTP_DTA = word(3);
  cTFTP_ACK = word(4);
  cTFTP_ERR = word(5);

TYPE
  {:@abstract(Implementation of TFTP client and server)
   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TTFTPSend = class(TSynaClient)
  private
    FSock: TUDPBlockSocket;
    FErrorCode: integer;
    FErrorString: string;
    FData: TMemoryStream;
    FRequestIP: string;
    FRequestPort: string;
    FUNCTION SendPacket(cmd: word; Serial: word; CONST value: string): boolean;
    FUNCTION RecvPacket(Serial: word; VAR value: string): boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Upload @link(data) as file to TFTP server.}
    FUNCTION SendFile(CONST fileName: string): boolean;

    {:Download file from TFTP server to @link(data).}
    FUNCTION RecvFile(CONST fileName: string): boolean;

    {:Acts as TFTP server and wait for client request. When some request
     incoming within Timeout, result is @true and parametres is filled with
     information from request. You must handle this request, validate it, and
     call @link(ReplyError), @link(ReplyRecv) or @link(ReplySend) for send reply
     to TFTP Client.}
    FUNCTION WaitForRequest(VAR Req: word; VAR fileName: string): boolean;

    {:send error to TFTP client, when you acts as TFTP server.}
    PROCEDURE ReplyError(Error: word; description: string);

    {:Accept uploaded file from TFTP client to @link(data), when you acts as
     TFTP Server.}
    FUNCTION ReplyRecv: boolean;

    {:Accept download request file from TFTP client and send content of
     @link(data), when you acts as TFTP Server.}
    FUNCTION ReplySend: boolean;
  Published
    {:Code of TFTP error.}
    PROPERTY ErrorCode: integer read FErrorCode;

    {:Human readable decription of TFTP error. (if is sended by remote side)}
    PROPERTY ErrorString: string read FErrorString;

    {:MemoryStream with datas for sending or receiving}
    PROPERTY data: TMemoryStream read FData;

    {:Address of TFTP remote side.}
    PROPERTY RequestIP: string read FRequestIP write FRequestIP;

    {:Port of TFTP remote side.}
    PROPERTY RequestPort: string read FRequestPort write FRequestPort;
  end;

IMPLEMENTATION

CONSTRUCTOR TTFTPSend.create;
begin
  inherited create;
  FSock := TUDPBlockSocket.create;
  FSock.Owner := self;
  FTargetPort := cTFTPProtocol;
  FData := TMemoryStream.create;
  FErrorCode := 0;
  FErrorString := '';
end;

DESTRUCTOR TTFTPSend.destroy;
begin
  FSock.free;
  FData.free;
  inherited destroy;
end;

FUNCTION TTFTPSend.SendPacket(cmd: word; Serial: word; CONST value: string): boolean;
VAR
  s, sh: string;
begin
  FErrorCode := 0;
  FErrorString := '';
  result := false;
  if cmd <> 2 then
    s := CodeInt(cmd) + CodeInt(Serial) + value
  else
    s := CodeInt(cmd) + value;
  FSock.SendString(s);
  s := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
    if length(s) >= 4 then
    begin
      sh := CodeInt(4) + CodeInt(Serial);
      if pos(sh, s) = 1 then
        result := true
      else
        if s[1] = #5 then
        begin
          FErrorCode := DecodeInt(s, 3);
          Delete(s, 1, 4);
          FErrorString := SeparateLeft(s, #0);
        end;
    end;
end;

FUNCTION TTFTPSend.RecvPacket(Serial: word; VAR value: string): boolean;
VAR
  s: string;
  ser: word;
begin
  FErrorCode := 0;
  FErrorString := '';
  result := false;
  value := '';
  s := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
    if length(s) >= 4 then
      if DecodeInt(s, 1) = 3 then
      begin
        ser := DecodeInt(s, 3);
        if ser = Serial then
        begin
          Delete(s, 1, 4);
          value := s;
          S := CodeInt(4) + CodeInt(ser);
          FSock.SendString(s);
          result := FSock.LastError = 0;
        end
        else
        begin
          S := CodeInt(5) + CodeInt(5) + 'Unexcepted serial#' + #0;
          FSock.SendString(s);
        end;
      end;
      if DecodeInt(s, 1) = 5 then
      begin
        FErrorCode := DecodeInt(s, 3);
        Delete(s, 1, 4);
        FErrorString := SeparateLeft(s, #0);
      end;
end;

FUNCTION TTFTPSend.SendFile(CONST fileName: string): boolean;
VAR
  s: string;
  ser: word;
  n, n1, n2: integer;
begin
  result := false;
  FErrorCode := 0;
  FErrorString := '';
  FSock.CloseSocket;
  FSock.Connect(FTargetHost, FTargetPort);
  try
    if FSock.LastError = 0 then
    begin
      s := fileName + #0 + 'octet' + #0;
      if not Sendpacket(2, 0, s) then
        exit;
      ser := 1;
      FData.position := 0;
      n1 := FData.size div 512;
      n2 := FData.size mod 512;
      for n := 1 to n1 do
      begin
        s := ReadStrFromStream(FData, 512);
//        SetLength(s, 512);
//        FData.Read(pointer(s)^, 512);
        if not Sendpacket(3, ser, s) then
          exit;
        inc(ser);
      end;
      s := ReadStrFromStream(FData, n2);
//      SetLength(s, n2);
//      FData.Read(pointer(s)^, n2);
      if not Sendpacket(3, ser, s) then
        exit;
      result := true;
    end;
  finally
    FSock.CloseSocket;
  end;
end;

FUNCTION TTFTPSend.RecvFile(CONST fileName: string): boolean;
VAR
  s: string;
  ser: word;
begin
  result := false;
  FErrorCode := 0;
  FErrorString := '';
  FSock.CloseSocket;
  FSock.Connect(FTargetHost, FTargetPort);
  try
    if FSock.LastError = 0 then
    begin
      s := CodeInt(1) + fileName + #0 + 'octet' + #0;
      FSock.SendString(s);
      if FSock.LastError <> 0 then
        exit;
      FData.clear;
      ser := 1;
      repeat
        if not RecvPacket(ser, s) then
          exit;
        inc(ser);
        WriteStrToStream(FData, s);
//        FData.Write(pointer(s)^, length(s));
      until length(s) <> 512;
      FData.position := 0;
      result := true;
    end;
  finally
    FSock.CloseSocket;
  end;
end;

FUNCTION TTFTPSend.WaitForRequest(VAR Req: word; VAR fileName: string): boolean;
VAR
  s: string;
begin
  result := false;
  FErrorCode := 0;
  FErrorString := '';
  FSock.CloseSocket;
  FSock.Bind('0.0.0.0', FTargetPort);
  if FSock.LastError = 0 then
  begin
    s := FSock.RecvPacket(FTimeout);
    if FSock.LastError = 0 then
      if length(s) >= 4 then
      begin
        FRequestIP := FSock.GetRemoteSinIP;
        FRequestPort := intToStr(FSock.GetRemoteSinPort);
        Req := DecodeInt(s, 1);
        Delete(s, 1, 2);
        fileName := trim(SeparateLeft(s, #0));
        s := SeparateRight(s, #0);
        s := SeparateLeft(s, #0);
        result := lowercase(trim(s)) = 'octet';
      end;
  end;
end;

PROCEDURE TTFTPSend.ReplyError(Error: word; description: string);
VAR
  s: string;
begin
  FSock.CloseSocket;
  FSock.Connect(FRequestIP, FRequestPort);
  s := CodeInt(5) + CodeInt(Error) + description + #0;
  FSock.SendString(s);
  FSock.CloseSocket;
end;

FUNCTION TTFTPSend.ReplyRecv: boolean;
VAR
  s: string;
  ser: integer;
begin
  result := false;
  FErrorCode := 0;
  FErrorString := '';
  FSock.CloseSocket;
  FSock.Connect(FRequestIP, FRequestPort);
  try
    s := CodeInt(4) + CodeInt(0);
    FSock.SendString(s);
    FData.clear;
    ser := 1;
    repeat
      if not RecvPacket(ser, s) then
        exit;
      inc(ser);
      WriteStrToStream(FData, s);
//      FData.Write(pointer(s)^, length(s));
    until length(s) <> 512;
    FData.position := 0;
    result := true;
  finally
    FSock.CloseSocket;
  end;
end;

FUNCTION TTFTPSend.ReplySend: boolean;
VAR
  s: string;
  ser: word;
  n, n1, n2: integer;
begin
  result := false;
  FErrorCode := 0;
  FErrorString := '';
  FSock.CloseSocket;
  FSock.Connect(FRequestIP, FRequestPort);
  try
    ser := 1;
    FData.position := 0;
    n1 := FData.size div 512;
    n2 := FData.size mod 512;
    for n := 1 to n1 do
    begin
      s := ReadStrFromStream(FData, 512);
//      SetLength(s, 512);
//      FData.Read(pointer(s)^, 512);
      if not Sendpacket(3, ser, s) then
        exit;
      inc(ser);
    end;
    s := ReadStrFromStream(FData, n2);
//    SetLength(s, n2);
//    FData.Read(pointer(s)^, n2);
    if not Sendpacket(3, ser, s) then
      exit;
    result := true;
  finally
    FSock.CloseSocket;
  end;
end;

{==============================================================================}

end.
