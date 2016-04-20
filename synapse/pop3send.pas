{==============================================================================|
| project : Ararat Synapse                                       | 002.006.002 |
|==============================================================================|
| content: POP3 Client                                                         |
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
| Portions created by Lukas Gebauer are Copyright (c)2001-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(POP3 protocol client)

used RFC: RFC-1734, RFC-1939, RFC-2195, RFC-2449, RFC-2595
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
{$M+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT pop3send;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, synacode;

CONST
  cPop3Protocol = '110';

TYPE

  {:The three types of possible authorization methods for "logging in" to a POP3
   Server.}
  TPOP3AuthType = (POP3AuthAll, POP3AuthLogin, POP3AuthAPOP);

  {:@abstract(Implementation of POP3 client protocol.)

   Note: Are you missing properties for setting Username and Password? Look to
   parent @link(TSynaClient) object!

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TPOP3Send = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FResultCode: integer;
    FResultString: string;
    FFullResult: TStringList;
    FStatCount: integer;
    FStatSize: integer;
    FListSize: integer;
    FTimeStamp: string;
    FAuthType: TPOP3AuthType;
    FPOP3cap: TStringList;
    FAutoTLS: boolean;
    FFullSSL: boolean;
    FUNCTION ReadResult(Full: boolean): integer;
    FUNCTION Connect: boolean;
    FUNCTION AuthLogin: boolean;
    FUNCTION AuthApop: boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:You can call any custom by this method. Call Command without trailing CRLF.
      if MultiLine parameter is @true, multilined response are expected.
      result is @true on sucess.}
    FUNCTION CustomCommand(CONST command: string; MultiLine: boolean): boolean;

    {:Call CAPA command for get POP3 server capabilites.
     note: not all servers support this command!}
    FUNCTION Capability: boolean;

    {:Connect to remote POP3 host. If all OK, result is @true.}
    FUNCTION Login: boolean;

    {:Disconnects from POP3 server.}
    FUNCTION Logout: boolean;

    {:Send RSET command. If all OK, result is @true.}
    FUNCTION reset: boolean;

    {:Send NOOP command. If all OK, result is @true.}
    FUNCTION NoOp: boolean;

    {:Send STAT command and fill @link(StatCount) and @link(StatSize) property.
     if all ok, result is @true.}
    FUNCTION Stat: boolean;

    {:Send LIST command. If Value is 0, LIST is for all messages. After
     successful operation is listing in FullResult. if all ok, result is @true.}
    FUNCTION list(value: integer): boolean;

    {:Send RETR command. After successful operation dowloaded message in
     @link(FullResult). if all ok, result is @true.}
    FUNCTION Retr(value: integer): boolean;

    {:Send RETR command. After successful operation dowloaded message in
     @link(Stream). if all ok, result is @true.}
    FUNCTION RetrStream(value: integer; Stream: TStream): boolean;

    {:Send DELE command for delete specified message. If all OK, result is @true.}
    FUNCTION Dele(value: integer): boolean;

    {:Send TOP command. After successful operation dowloaded headers of message
     and maxlines count of message in @link(FullResult). if all ok, result is
     @true.}
    FUNCTION top(value, Maxlines: integer): boolean;

    {:Send UIDL command. If Value is 0, UIDL is for all messages. After
     successful operation is listing in FullResult. if all ok, result is @true.}
    FUNCTION Uidl(value: integer): boolean;

    {:Call STLS command for upgrade connection to SSL/TLS mode.}
    FUNCTION StartTLS: boolean;

    {:Try to find given capabily in capabilty string returned from POP3 server
     by CAPA command.}
    FUNCTION FindCap(CONST value: string): string;
  Published
    {:Result code of last POP3 operation. 0 - error, 1 - OK.}
    PROPERTY ResultCode: integer read FResultCode;

    {:Result string of last POP3 operation.}
    PROPERTY resultString: string read FResultString;

    {:Stringlist with full lines returned as result of POP3 operation. I.e. if
     operation is list, this PROPERTY is filled by list of messages. if
     operation is RETR, this PROPERTY have downloaded message.}
    PROPERTY FullResult: TStringList read FFullResult;

    {:After STAT command is there count of messages in inbox.}
    PROPERTY StatCount: integer read FStatCount;

    {:After STAT command is there size of all messages in inbox.}
    PROPERTY StatSize: integer read  FStatSize;

    {:After LIST 0 command size of all messages on server, After LIST x size of message x on server}
    PROPERTY listSize: integer read  FListSize;

    {:If server support this, after comnnect is in this property timestamp of
     remote Server.}
    PROPERTY TimeStamp: string read FTimeStamp;

    {:Type of authorisation for login to POP3 server. Dafault is autodetect one
     of possible authorisation. Autodetect do this:

     if remote POP3 Server support APOP, try login by APOP method. if APOP is
     not supported, or if APOP login failed, try classic USER+PASS login method.}
    PROPERTY AuthType: TPOP3AuthType read FAuthType write FAuthType;

    {:If is set to @true, then upgrade to SSL/TLS mode if remote server support it.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:SSL/TLS mode is used from first contact to server. Servers with full
     SSL/TLS mode usualy using non-standard TCP port!}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;
    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;
  end;

IMPLEMENTATION

CONSTRUCTOR TPOP3Send.create;
begin
  inherited create;
  FFullResult := TStringList.create;
  FPOP3cap := TStringList.create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.ConvertLineEnd := true;
  FTimeout := 60000;
  FTargetPort := cPop3Protocol;
  FStatCount := 0;
  FStatSize := 0;
  FListSize := 0;
  FAuthType := POP3AuthAll;
  FAutoTLS := false;
  FFullSSL := false;
end;

DESTRUCTOR TPOP3Send.destroy;
begin
  FSock.free;
  FPOP3cap.free;
  FullResult.free;
  inherited destroy;
end;

FUNCTION TPOP3Send.ReadResult(Full: boolean): integer;
VAR
  s: ansistring;
begin
  result := 0;
  FFullResult.clear;
  s := FSock.RecvString(FTimeout);
  if pos('+OK', s) = 1 then
    result := 1;
  FResultString := s;
  if Full and (result = 1) then
    repeat
      s := FSock.RecvString(FTimeout);
      if s = '.' then
        break;
      if s <> '' then
        if s[1] = '.' then
          Delete(s, 1, 1);
      FFullResult.add(s);
    until FSock.LastError <> 0;
  if not Full and (result = 1) then
    FFullResult.add(SeparateRight(FResultString, ' '));
  if FSock.LastError <> 0 then
    result := 0;
  FResultCode := result;
end;

FUNCTION TPOP3Send.CustomCommand(CONST command: string; MultiLine: boolean): boolean;
begin
  FSock.SendString(command + CRLF);
  result := ReadResult(MultiLine) <> 0;
end;

FUNCTION TPOP3Send.AuthLogin: boolean;
begin
  result := false;
  if not CustomCommand('USER ' + FUserName, false) then
    exit;
  result := CustomCommand('PASS ' + FPassword, false)
end;

FUNCTION TPOP3Send.AuthAPOP: boolean;
VAR
  s: string;
begin
  s := StrToHex(MD5(FTimeStamp + FPassWord));
  result := CustomCommand('APOP ' + FUserName + ' ' + s, false);
end;

FUNCTION TPOP3Send.Connect: boolean;
begin
  // Do not call this function! It is calling by LOGIN method!
  FStatCount := 0;
  FStatSize := 0;
  FSock.CloseSocket;
  FSock.LineBuffer := '';
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError = 0 then
    FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError = 0 then
    if FFullSSL then
      FSock.SSLDoConnect;
  result := FSock.LastError = 0;
end;

FUNCTION TPOP3Send.Capability: boolean;
begin
  FPOP3cap.clear;
  result := CustomCommand('CAPA', true);
  if result then
    FPOP3cap.AddStrings(FFullResult);
end;

FUNCTION TPOP3Send.Login: boolean;
VAR
  s, s1: string;
begin
  result := false;
  FTimeStamp := '';
  if not Connect then
    exit;
  if ReadResult(false) <> 1 then
    exit;
  s := SeparateRight(FResultString, '<');
  if s <> FResultString then
  begin
    s1 := trim(SeparateLeft(s, '>'));
    if s1 <> s then
      FTimeStamp := '<' + s1 + '>';
  end;
  result := false;
  if Capability then
    if FAutoTLS and (Findcap('STLS') <> '') then
      if StartTLS then
        Capability
      else
      begin
        result := false;
        exit;
      end;
  if (FTimeStamp <> '') and not (FAuthType = POP3AuthLogin) then
  begin
    result := AuthApop;
    if not result then
    begin
      if not Connect then
        exit;
      if ReadResult(false) <> 1 then
        exit;
    end;
  end;
  if not result and not (FAuthType = POP3AuthAPOP) then
    result := AuthLogin;
end;

FUNCTION TPOP3Send.Logout: boolean;
begin
  result := CustomCommand('QUIT', false);
  FSock.CloseSocket;
end;

FUNCTION TPOP3Send.reset: boolean;
begin
  result := CustomCommand('RSET', false);
end;

FUNCTION TPOP3Send.NoOp: boolean;
begin
  result := CustomCommand('NOOP', false);
end;

FUNCTION TPOP3Send.Stat: boolean;
VAR
  s: string;
begin
  result := CustomCommand('STAT', false);
  if result then
  begin
    s := SeparateRight(resultString, '+OK ');
    FStatCount := strToIntDef(trim(SeparateLeft(s, ' ')), 0);
    FStatSize := strToIntDef(trim(SeparateRight(s, ' ')), 0);
  end;
end;

FUNCTION TPOP3Send.list(value: integer): boolean;
VAR
  s: string;
  n: integer;
begin
  if value = 0 then
    s := 'LIST'
  else
    s := 'LIST ' + intToStr(value);
  result := CustomCommand(s, value = 0);
  FListSize := 0;
  if result then
    if value <> 0 then
    begin
      s := SeparateRight(resultString, '+OK ');
      FListSize := strToIntDef(SeparateLeft(SeparateRight(s, ' '), ' '), 0);
    end
    else
      for n := 0 to FFullResult.count - 1 do
        FListSize := FListSize + strToIntDef(SeparateLeft(SeparateRight(s, ' '), ' '), 0);
end;

FUNCTION TPOP3Send.Retr(value: integer): boolean;
begin
  result := CustomCommand('RETR ' + intToStr(value), true);
end;

//based on code by Miha Vrhovnik
FUNCTION TPOP3Send.RetrStream(value: integer; Stream: TStream): boolean;
VAR
  s: string;
begin
  result := false;
  FFullResult.clear;
  Stream.size := 0;
  FSock.SendString('RETR ' + intToStr(value) + CRLF);

  s := FSock.RecvString(FTimeout);
  if pos('+OK', s) = 1 then
    result := true;
  FResultString := s;
  if result then begin
    repeat
      s := FSock.RecvString(FTimeout);
      if s = '.' then
        break;
      if s <> '' then begin
        if s[1] = '.' then
          Delete(s, 1, 1);
      end;
      WriteStrToStream(Stream, s);
      WriteStrToStream(Stream, CRLF);
    until FSock.LastError <> 0;
  end;

  if result then
    FResultCode := 1
  else
    FResultCode := 0;
end;

FUNCTION TPOP3Send.Dele(value: integer): boolean;
begin
  result := CustomCommand('DELE ' + intToStr(value), false);
end;

FUNCTION TPOP3Send.top(value, Maxlines: integer): boolean;
begin
  result := CustomCommand('TOP ' + intToStr(value) + ' ' + intToStr(Maxlines), true);
end;

FUNCTION TPOP3Send.Uidl(value: integer): boolean;
VAR
  s: string;
begin
  if value = 0 then
    s := 'UIDL'
  else
    s := 'UIDL ' + intToStr(value);
  result := CustomCommand(s, value = 0);
end;

FUNCTION TPOP3Send.StartTLS: boolean;
begin
  result := false;
  if CustomCommand('STLS', false) then
  begin
    Fsock.SSLDoConnect;
    result := FSock.LastError = 0;
  end;
end;

FUNCTION TPOP3Send.FindCap(CONST value: string): string;
VAR
  n: integer;
  s: string;
begin
  s := uppercase(value);
  result := '';
  for n := 0 to FPOP3cap.count - 1 do
    if pos(s, uppercase(FPOP3cap[n])) = 1 then
    begin
      result := FPOP3cap[n];
      break;
    end;
end;

end.
