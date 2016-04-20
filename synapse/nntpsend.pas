{==============================================================================|
| project : Ararat Synapse                                       | 001.005.003 |
|==============================================================================|
| content: NNTP Client                                                         |
|==============================================================================|
| Copyright (c)1999-2011, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2011.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(NNTP client)
NNTP (network news transfer protocol)

used RFC: RFC-977, RFC-2980
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  {$WARN SUSPICIOUS_TYPECAST OFF}
{$ENDIF}

UNIT nntpsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil;

CONST
  cNNTPProtocol = '119';

TYPE

  {:abstract(Implementation of Network News Transfer Protocol.

   Note: Are you missing properties for setting Username and Password? Look to
   parent @link(TSynaClient) object!

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TNNTPSend = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FResultCode: integer;
    FResultString: string;
    FData: TStringList;
    FDataToSend: TStringList;
    FAutoTLS: boolean;
    FFullSSL: boolean;
    FNNTPcap: TStringList;
    FUNCTION ReadResult: integer;
    FUNCTION ReadData: boolean;
    FUNCTION SendData: boolean;
    FUNCTION Connect: boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Connects to NNTP server and begin session.}
    FUNCTION Login: boolean;

    {:Logout from NNTP server and terminate session.}
    FUNCTION Logout: boolean;

    {:By this you can call any NNTP command.}
    FUNCTION DoCommand(CONST command: string): boolean;

    {:by this you can call any NNTP command. This variant is used for commands
     for download information from Server.}
    FUNCTION DoCommandRead(CONST command: string): boolean;

    {:by this you can call any NNTP command. This variant is used for commands
     for upload information to Server.}
    FUNCTION DoCommandWrite(CONST command: string): boolean;

    {:Download full message to @link(data) property. Value can be number of
     message or message-id (in brackets).}
    FUNCTION GetArticle(CONST value: string): boolean;

    {:Download only body of message to @link(data) property. Value can be number
     of message or message-id (in brackets).}
    FUNCTION GetBody(CONST value: string): boolean;

    {:Download only headers of message to @link(data) property. Value can be
     number of message or message-id (in brackets).}
    FUNCTION GetHead(CONST value: string): boolean;

    {:Get message status. Value can be number of message or message-id
     (in brackets).}
    FUNCTION GetStat(CONST value: string): boolean;

    {:Select given group.}
    FUNCTION SelectGroup(CONST value: string): boolean;

    {:Tell to server 'I have mesage with given message-ID.' If server need this
     message, message is uploaded to Server.}
    FUNCTION IHave(CONST MessID: string): boolean;

    {:Move message pointer to last item in group.}
    FUNCTION GotoLast: boolean;

    {:Move message pointer to next item in group.}
    FUNCTION GotoNext: boolean;

    {:Download to @link(data) property list of all groups on NNTP server.}
    FUNCTION ListGroups: boolean;

    {:Download to @link(data) property list of all groups created after given time.}
    FUNCTION ListNewGroups(Since: TDateTime): boolean;

    {:Download to @link(data) property list of message-ids in given group since
     given time.}
    FUNCTION NewArticles(CONST Group: string; Since: TDateTime): boolean;

    {:Upload new article to server. (for new messages by you)}
    FUNCTION PostArticle: boolean;

    {:Tells to remote NNTP server 'I am not NNTP client, but I am another NNTP
     Server'.}
    FUNCTION SwitchToSlave: boolean;

    {:Call NNTP XOVER command.}
    FUNCTION Xover(xoStart, xoEnd: string): boolean;

    {:Call STARTTLS command for upgrade connection to SSL/TLS mode.}
    FUNCTION StartTLS: boolean;

    {:Try to find given capability in extension list. This list is getted after
     successful login to NNTP Server. if extension capability is not found,
     then return is empty string.}
    FUNCTION FindCap(CONST value: string): string;

    {:Try get list of server extensions. List is returned in @link(data) property.}
    FUNCTION ListExtensions: boolean;
  Published
    {:Result code number of last operation.}
    PROPERTY ResultCode: integer read FResultCode;

    {:String description of last result code from NNTP server.}
    PROPERTY resultString: string read FResultString;

    {:Readed data. (message, etc.)}
    PROPERTY data: TStringList read FData;

    {:If is set to @true, then upgrade to SSL/TLS mode after login if remote
     Server support it.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:SSL/TLS mode is used from first contact to server. Servers with full
     SSL/TLS mode usualy using non-standard TCP port!}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;
  end;

IMPLEMENTATION

CONSTRUCTOR TNNTPSend.create;
begin
  inherited create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FData := TStringList.create;
  FDataToSend := TStringList.create;
  FNNTPcap := TStringList.create;
  FSock.ConvertLineEnd := true;
  FTimeout := 60000;
  FTargetPort := cNNTPProtocol;
  FAutoTLS := false;
  FFullSSL := false;
end;

DESTRUCTOR TNNTPSend.destroy;
begin
  FSock.free;
  FDataToSend.free;
  FData.free;
  FNNTPcap.free;
  inherited destroy;
end;

FUNCTION TNNTPSend.ReadResult: integer;
VAR
  s: string;
begin
  result := 0;
  FData.clear;
  s := FSock.RecvString(FTimeout);
  FResultString := copy(s, 5, length(s) - 4);
  if FSock.LastError <> 0 then
    exit;
  if length(s) >= 3 then
    result := strToIntDef(copy(s, 1, 3), 0);
  FResultCode := result;
end;

FUNCTION TNNTPSend.ReadData: boolean;
VAR
  s: string;
begin
  repeat
    s := FSock.RecvString(FTimeout);
    if s = '.' then
      break;
    if (s <> '') and (s[1] = '.') then
      s := copy(s, 2, length(s) - 1);
    FData.add(s);
  until FSock.LastError <> 0;
  result := FSock.LastError = 0;
end;

FUNCTION TNNTPSend.SendData: boolean;
VAR
  s: string;
  n: integer;
begin
  for n := 0 to FDataToSend.count - 1 do
  begin
    s := FDataToSend[n];
    if (s <> '') and (s[1] = '.') then
      s := s + '.';
    FSock.SendString(s + CRLF);
    if FSock.LastError <> 0 then
      break;
  end;
  if FDataToSend.count = 0 then
    FSock.SendString(CRLF);
  if FSock.LastError = 0 then
    FSock.SendString('.' + CRLF);
  FDataToSend.clear;
  result := FSock.LastError = 0;
end;

FUNCTION TNNTPSend.Connect: boolean;
begin
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError = 0 then
    FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError = 0 then
    if FFullSSL then
      FSock.SSLDoConnect;
  result := FSock.LastError = 0;
end;

FUNCTION TNNTPSend.Login: boolean;
begin
  result := false;
  FNNTPcap.clear;
  if not Connect then
    exit;
  result := (ReadResult div 100) = 2;
  if result then
  begin
    ListExtensions;
    FNNTPcap.assign(Fdata);
    if (not FullSSL) and FAutoTLS and (FindCap('STARTTLS') <> '') then
      result := StartTLS;
  end;
  if (FUsername <> '') and result then
  begin
    FSock.SendString('AUTHINFO USER ' + FUsername + CRLF);
    if (ReadResult div 100) = 3 then
    begin
      FSock.SendString('AUTHINFO PASS ' + FPassword + CRLF);
      result := (ReadResult div 100) = 2;
    end;
  end;
end;

FUNCTION TNNTPSend.Logout: boolean;
begin
  FSock.SendString('QUIT' + CRLF);
  result := (ReadResult div 100) = 2;
  FSock.CloseSocket;
end;

FUNCTION TNNTPSend.DoCommand(CONST command: string): boolean;
begin
  FSock.SendString(command + CRLF);
  result := (ReadResult div 100) = 2;
  result := result and (FSock.LastError = 0);
end;

FUNCTION TNNTPSend.DoCommandRead(CONST command: string): boolean;
begin
  result := DoCommand(command);
  if result then
  begin
    result := ReadData;
    result := result and (FSock.LastError = 0);
  end;
end;

FUNCTION TNNTPSend.DoCommandWrite(CONST command: string): boolean;
VAR
  x: integer;
begin
  FDataToSend.assign(FData);
  FSock.SendString(command + CRLF);
  x := (ReadResult div 100);
  if x = 3 then
  begin
    SendData;
    x := (ReadResult div 100);
  end;
  result := x = 2;
  result := result and (FSock.LastError = 0);
end;

FUNCTION TNNTPSend.GetArticle(CONST value: string): boolean;
VAR
  s: string;
begin
  s := 'ARTICLE';
  if value <> '' then
    s := s + ' ' + value;
  result := DoCommandRead(s);
end;

FUNCTION TNNTPSend.GetBody(CONST value: string): boolean;
VAR
  s: string;
begin
  s := 'BODY';
  if value <> '' then
    s := s + ' ' + value;
  result := DoCommandRead(s);
end;

FUNCTION TNNTPSend.GetHead(CONST value: string): boolean;
VAR
  s: string;
begin
  s := 'HEAD';
  if value <> '' then
    s := s + ' ' + value;
  result := DoCommandRead(s);
end;

FUNCTION TNNTPSend.GetStat(CONST value: string): boolean;
VAR
  s: string;
begin
  s := 'STAT';
  if value <> '' then
    s := s + ' ' + value;
  result := DoCommand(s);
end;

FUNCTION TNNTPSend.SelectGroup(CONST value: string): boolean;
begin
  result := DoCommand('GROUP ' + value);
end;

FUNCTION TNNTPSend.IHave(CONST MessID: string): boolean;
begin
  result := DoCommandWrite('IHAVE ' + MessID);
end;

FUNCTION TNNTPSend.GotoLast: boolean;
begin
  result := DoCommand('LAST');
end;

FUNCTION TNNTPSend.GotoNext: boolean;
begin
  result := DoCommand('NEXT');
end;

FUNCTION TNNTPSend.ListGroups: boolean;
begin
  result := DoCommandRead('LIST');
end;

FUNCTION TNNTPSend.ListNewGroups(Since: TDateTime): boolean;
begin
  result := DoCommandRead('NEWGROUPS ' + SimpleDateTime(Since) + ' GMT');
end;

FUNCTION TNNTPSend.NewArticles(CONST Group: string; Since: TDateTime): boolean;
begin
  result := DoCommandRead('NEWNEWS ' + Group + ' ' + SimpleDateTime(Since) + ' GMT');
end;

FUNCTION TNNTPSend.PostArticle: boolean;
begin
  result := DoCommandWrite('POST');
end;

FUNCTION TNNTPSend.SwitchToSlave: boolean;
begin
  result := DoCommand('SLAVE');
end;

FUNCTION TNNTPSend.Xover(xoStart, xoEnd: string): boolean;
VAR
  s: string;
begin
  s := 'XOVER ' + xoStart;
  if xoEnd <> xoStart then
    s := s + '-' + xoEnd;
  result := DoCommandRead(s);
end;

FUNCTION TNNTPSend.StartTLS: boolean;
begin
  result := false;
  if FindCap('STARTTLS') <> '' then
  begin
    if DoCommand('STARTTLS') then
    begin
      Fsock.SSLDoConnect;
      result := FSock.LastError = 0;
    end;
  end;
end;

FUNCTION TNNTPSend.ListExtensions: boolean;
begin
  result := DoCommandRead('LIST EXTENSIONS');
end;

FUNCTION TNNTPSend.FindCap(CONST value: string): string;
VAR
  n: integer;
  s: string;
begin
  s := uppercase(value);
  result := '';
  for n := 0 to FNNTPcap.count - 1 do
    if pos(s, uppercase(FNNTPcap[n])) = 1 then
    begin
      result := FNNTPcap[n];
      break;
    end;
end;

{==============================================================================}

end.
