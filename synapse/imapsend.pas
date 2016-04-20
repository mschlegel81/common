{==============================================================================|
| project : Ararat Synapse                                       | 002.005.003 |
|==============================================================================|
| content: IMAP4rev1 Client                                                    |
|==============================================================================|
| Copyright (c)1999-2012, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2001-2012.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(IMAP4 rev1 protocol client)

used RFC: RFC-2060, RFC-2595
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT imapsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil;

CONST
  cIMAPProtocol = '143';

TYPE
  {:@abstract(Implementation of IMAP4 protocol.)
   Note: Are you missing properties for setting Username and Password? Look to
   parent @link(TSynaClient) object!

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TIMAPSend = class(TSynaClient)
  protected
    FSock: TTCPBlockSocket;
    FTagCommand: integer;
    FResultString: string;
    FFullResult: TStringList;
    FIMAPcap: TStringList;
    FAuthDone: boolean;
    FSelectedFolder: string;
    FSelectedCount: integer;
    FSelectedRecent: integer;
    FSelectedUIDvalidity: integer;
    FUID: boolean;
    FAutoTLS: boolean;
    FFullSSL: boolean;
    FUNCTION ReadResult: string;
    FUNCTION AuthLogin: boolean;
    FUNCTION Connect: boolean;
    PROCEDURE ParseMess(value:TStrings);
    PROCEDURE ParseFolderList(value:TStrings);
    PROCEDURE ParseSelect;
    PROCEDURE ParseSearch(value:TStrings);
    PROCEDURE ProcessLiterals;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:By this function you can call any IMAP command. Result of this command is
     in adequate properties.}
    FUNCTION IMAPcommand(value: string): string;

    {:By this function you can call any IMAP command what need upload any data.
     result of this command is in adequate properties.}
    FUNCTION IMAPuploadCommand(value: string; CONST data:TStrings): string;

    {:Call CAPABILITY command and fill IMAPcap property by new values.}
    FUNCTION Capability: boolean;

    {:Connect to IMAP server and do login to this server. This command begin
     session.}
    FUNCTION Login: boolean;

    {:Disconnect from IMAP server and terminate session session. If exists some
     deleted and non-purged messages, these messages are not deleted!}
    FUNCTION Logout: boolean;

    {:Do NOOP. It is for prevent disconnect by timeout.}
    FUNCTION NoOp: boolean;

    {:Lists folder names. You may specify level of listing. If you specify
     FromFolder as empty string, return is all folders in system.}
    FUNCTION list(FromFolder: string; CONST FolderList: TStrings): boolean;

    {:Lists folder names what match search criteria. You may specify level of
     listing. if you specify FromFolder as empty string, return is all folders
     in system.}
    FUNCTION ListSearch(FromFolder, Search: string; CONST FolderList: TStrings): boolean;

    {:Lists subscribed folder names. You may specify level of listing. If you
     specify FromFolder as empty string, return is all subscribed folders in
     system.}
    FUNCTION ListSubscribed(FromFolder: string; CONST FolderList: TStrings): boolean;

    {:Lists subscribed folder names what matching search criteria. You may
     specify level of listing. if you specify FromFolder as empty string, return
     is all subscribed folders in system.}
    FUNCTION ListSearchSubscribed(FromFolder, Search: string; CONST FolderList: TStrings): boolean;

    {:Create a new folder.}
    FUNCTION CreateFolder(FolderName: string): boolean;

    {:Delete a folder.}
    FUNCTION DeleteFolder(FolderName: string): boolean;

    {:Rename folder names.}
    FUNCTION RenameFolder(FolderName, NewFolderName: string): boolean;

    {:Subscribe folder.}
    FUNCTION SubscribeFolder(FolderName: string): boolean;

    {:Unsubscribe folder.}
    FUNCTION UnsubscribeFolder(FolderName: string): boolean;

    {:Select folder.}
    FUNCTION SelectFolder(FolderName: string): boolean;

    {:Select folder, but only for reading. Any changes are not allowed!}
    FUNCTION SelectROFolder(FolderName: string): boolean;

    {:Close a folder. (end of Selected state)}
    FUNCTION CloseFolder: boolean;

    {:Ask for given status of folder. I.e. if you specify as value 'UNSEEN',
     result is number of unseen messages in folder. for another status
     indentificator check IMAP documentation and documentation of your IMAP
     Server (each IMAP Server can have their own statuses.)}
    FUNCTION StatusFolder(FolderName, value: string): integer;

    {:Hardly delete all messages marked as 'deleted' in current selected folder.}
    FUNCTION ExpungeFolder: boolean;

    {:Touch to folder. (use as update status of folder, etc.)}
    FUNCTION CheckFolder: boolean;

    {:Append given message to specified folder.}
    FUNCTION AppendMess(ToFolder: string; CONST Mess: TStrings): boolean;

    {:'Delete' message from current selected folder. It mark message as Deleted.
     Real deleting will be done after sucessfull @link(CloseFolder) or
     @link(ExpungeFolder)}
    FUNCTION DeleteMess(MessID: integer): boolean;

    {:Get full message from specified message in selected folder.}
    FUNCTION FetchMess(MessID: integer; CONST Mess: TStrings): boolean;

    {:Get message headers only from specified message in selected folder.}
    FUNCTION FetchHeader(MessID: integer; CONST Headers: TStrings): boolean;

    {:Return message size of specified message from current selected folder.}
    FUNCTION MessageSize(MessID: integer): integer;

    {:Copy message from current selected folder to another folder.}
    FUNCTION CopyMess(MessID: integer; ToFolder: string): boolean;

    {:Return message numbers from currently selected folder as result
     of searching. Search criteria is very complex language (see to IMAP
     specification) similar to SQL (but not same syntax!).}
    FUNCTION SearchMess(Criteria: string; CONST FoundMess: TStrings): boolean;

    {:Sets flags of message from current selected folder.}
    FUNCTION SetFlagsMess(MessID: integer; Flags: string): boolean;

    {:Gets flags of message from current selected folder.}
    FUNCTION GetFlagsMess(MessID: integer; VAR Flags: string): boolean;

    {:Add flags to message's flags.}
    FUNCTION AddFlagsMess(MessID: integer; Flags: string): boolean;

    {:Remove flags from message's flags.}
    FUNCTION DelFlagsMess(MessID: integer; Flags: string): boolean;

    {:Call STARTTLS command for upgrade connection to SSL/TLS mode.}
    FUNCTION StartTLS: boolean;

    {:return UID of requested message ID.}
    FUNCTION GetUID(MessID: integer; VAR uid : integer): boolean;

    {:Try to find given capabily in capabilty string returned from IMAP server.}
    FUNCTION FindCap(CONST value: string): string;
  Published
    {:Status line with result of last operation.}
    PROPERTY resultString: string read FResultString;

    {:Full result of last IMAP operation.}
    PROPERTY FullResult: TStringList read FFullResult;

    {:List of server capabilites.}
    PROPERTY IMAPcap: TStringList read FIMAPcap;

    {:Authorization is successful done.}
    PROPERTY AuthDone: boolean read FAuthDone;

    {:Turn on or off usage of UID (unicate identificator) of messages instead
     only sequence numbers.}
    PROPERTY uid: boolean read FUID write FUID;

    {:Name of currently selected folder.}
    PROPERTY SelectedFolder: string read FSelectedFolder;

    {:Count of messages in currently selected folder.}
    PROPERTY SelectedCount: integer read FSelectedCount;

    {:Count of not-visited messages in currently selected folder.}
    PROPERTY SelectedRecent: integer read FSelectedRecent;

    {:This number with name of folder is unique indentificator of folder.
     (if someone Delete folder and next create new folder with exactly same name
     of folder, this number is must be different!)}
    PROPERTY SelectedUIDvalidity: integer read FSelectedUIDvalidity;

    {:If is set to true, then upgrade to SSL/TLS mode if remote server support it.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:SSL/TLS mode is used from first contact to server. Servers with full
     SSL/TLS mode usualy using non-standard TCP port!}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;
  end;

IMPLEMENTATION

CONSTRUCTOR TIMAPSend.create;
begin
  inherited create;
  FFullResult := TStringList.create;
  FIMAPcap := TStringList.create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.ConvertLineEnd := true;
  FSock.SizeRecvBuffer := 32768;
  FSock.SizeSendBuffer := 32768;
  FTimeout := 60000;
  FTargetPort := cIMAPProtocol;
  FTagCommand := 0;
  FSelectedFolder := '';
  FSelectedCount := 0;
  FSelectedRecent := 0;
  FSelectedUIDvalidity := 0;
  FUID := false;
  FAutoTLS := false;
  FFullSSL := false;
end;

DESTRUCTOR TIMAPSend.destroy;
begin
  FSock.free;
  FIMAPcap.free;
  FFullResult.free;
  inherited destroy;
end;


FUNCTION TIMAPSend.ReadResult: string;
VAR
  s: string;
  x, l: integer;
begin
  result := '';
  FFullResult.clear;
  FResultString := '';
  repeat
    s := FSock.RecvString(FTimeout);
    if pos('S' + intToStr(FTagCommand) + ' ', s) = 1 then
    begin
      FResultString := s;
      break;
    end
    else
      FFullResult.add(s);
    if (s <> '') and (s[length(s)]='}') then
    begin
      s := copy(s, 1, length(s) - 1);
      x := RPos('{', s);
      s := copy(s, x + 1, length(s) - x);
      l := strToIntDef(s, -1);
      if l <> -1 then
      begin
        s := FSock.RecvBufferStr(l, FTimeout);
        FFullResult.add(s);
      end;
    end;
  until FSock.LastError <> 0;
  s := trim(separateright(FResultString, ' '));
  result:=uppercase(trim(separateleft(s, ' ')));
end;

PROCEDURE TIMAPSend.ProcessLiterals;
VAR
  l: TStringList;
  n, x: integer;
  b: integer;
  s: string;
begin
  l := TStringList.create;
  try
    l.assign(FFullResult);
    FFullResult.clear;
    b := 0;
    for n := 0 to l.count - 1 do
    begin
      s := l[n];
      if b > 0 then
      begin
        FFullResult[FFullresult.count - 1] :=
          FFullResult[FFullresult.count - 1] + s;
        inc(b);
        if b > 2 then
          b := 0;
      end
      else
      begin
        if (s <> '') and (s[length(s)]='}') then
        begin
          x := RPos('{', s);
          Delete(s, x, length(s) - x + 1);
          b := 1;
        end
        else
          b := 0;
        FFullResult.add(s);
      end;
    end;
  finally
    l.free;
  end;
end;

FUNCTION TIMAPSend.IMAPcommand(value: string): string;
begin
  inc(FTagCommand);
  FSock.SendString('S' + intToStr(FTagCommand) + ' ' + value + CRLF);
  result := ReadResult;
end;

FUNCTION TIMAPSend.IMAPuploadCommand(value: string; CONST data:TStrings): string;
VAR
  l: integer;
begin
  inc(FTagCommand);
  l := length(data.text);
  FSock.SendString('S' + intToStr(FTagCommand) + ' ' + value + ' {'+ intToStr(l) + '}' + CRLF);
  FSock.RecvString(FTimeout);
  FSock.SendString(data.text + CRLF);
  result := ReadResult;
end;

PROCEDURE TIMAPSend.ParseMess(value:TStrings);
VAR
  n: integer;
begin
  value.clear;
  for n := 0 to FFullResult.count - 2 do
    if (length(FFullResult[n]) > 0) and (FFullResult[n][length(FFullResult[n])] = '}') then
    begin
      value.text := FFullResult[n + 1];
      break;
    end;
end;

PROCEDURE TIMAPSend.ParseFolderList(value:TStrings);
VAR
  n, x: integer;
  s: string;
begin
  ProcessLiterals;
  value.clear;
  for n := 0 to FFullResult.count - 1 do
  begin
    s := FFullResult[n];
    if (s <> '') and (pos('\NOSELECT', uppercase(s)) = 0) then
    begin
      if s[length(s)] = '"' then
      begin
        Delete(s, length(s), 1);
        x := RPos('"', s);
      end
      else
        x := RPos(' ', s);
      if (x > 0) then
        value.add(copy(s, x + 1, length(s) - x));
    end;
  end;
end;

PROCEDURE TIMAPSend.ParseSelect;
VAR
  n: integer;
  s, t: string;
begin
  ProcessLiterals;
  FSelectedCount := 0;
  FSelectedRecent := 0;
  FSelectedUIDvalidity := 0;
  for n := 0 to FFullResult.count - 1 do
  begin
    s := uppercase(FFullResult[n]);
    if pos(' EXISTS', s) > 0 then
    begin
      t := trim(separateleft(s, ' EXISTS'));
      t := trim(separateright(t, '* '));
      FSelectedCount := strToIntDef(t, 0);
    end;
    if pos(' RECENT', s) > 0 then
    begin
      t := trim(separateleft(s, ' RECENT'));
      t := trim(separateright(t, '* '));
      FSelectedRecent := strToIntDef(t, 0);
    end;
    if pos('UIDVALIDITY', s) > 0 then
    begin
      t := trim(separateright(s, 'UIDVALIDITY '));
      t := trim(separateleft(t, ']'));
      FSelectedUIDvalidity := strToIntDef(t, 0);
    end;
  end;
end;

PROCEDURE TIMAPSend.ParseSearch(value:TStrings);
VAR
  n: integer;
  s: string;
begin
  ProcessLiterals;
  value.clear;
  for n := 0 to FFullResult.count - 1 do
  begin
    s := uppercase(FFullResult[n]);
    if pos('* SEARCH', s) = 1 then
    begin
      s := trim(SeparateRight(s, '* SEARCH'));
      while s <> '' do
        value.add(Fetch(s, ' '));
    end;
  end;
end;

FUNCTION TIMAPSend.FindCap(CONST value: string): string;
VAR
  n: integer;
  s: string;
begin
  s := uppercase(value);
  result := '';
  for n := 0 to FIMAPcap.count - 1 do
    if pos(s, uppercase(FIMAPcap[n])) = 1 then
    begin
      result := FIMAPcap[n];
      break;
    end;
end;

FUNCTION TIMAPSend.AuthLogin: boolean;
begin
  result := IMAPcommand('LOGIN "' + FUsername + '" "' + FPassword + '"') = 'OK';
end;

FUNCTION TIMAPSend.Connect: boolean;
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

FUNCTION TIMAPSend.Capability: boolean;
VAR
  n: integer;
  s, t: string;
begin
  result := false;
  FIMAPcap.clear;
  s := IMAPcommand('CAPABILITY');
  if s = 'OK' then
  begin
    ProcessLiterals;
    for n := 0 to FFullResult.count - 1 do
      if pos('* CAPABILITY ', FFullResult[n]) = 1 then
      begin
        s := trim(SeparateRight(FFullResult[n], '* CAPABILITY '));
        while not (s = '') do
        begin
          t := trim(separateleft(s, ' '));
          s := trim(separateright(s, ' '));
          if s = t then
            s := '';
          FIMAPcap.add(t);
        end;
      end;
    result := true;
  end;
end;

FUNCTION TIMAPSend.Login: boolean;
VAR
  s: string;
begin
  FSelectedFolder := '';
  FSelectedCount := 0;
  FSelectedRecent := 0;
  FSelectedUIDvalidity := 0;
  result := false;
  FAuthDone := false;
  if not Connect then
    exit;
  s := FSock.RecvString(FTimeout);
  if pos('* PREAUTH', s) = 1 then
    FAuthDone := true
  else
    if pos('* OK', s) = 1 then
      FAuthDone := false
    else
      exit;
  if Capability then
  begin
    if Findcap('IMAP4rev1') = '' then
      exit;
    if FAutoTLS and (Findcap('STARTTLS') <> '') then
      if StartTLS then
        Capability;
  end;
  result := AuthLogin;
end;

FUNCTION TIMAPSend.Logout: boolean;
begin
  result := IMAPcommand('LOGOUT') = 'OK';
  FSelectedFolder := '';
  FSock.CloseSocket;
end;

FUNCTION TIMAPSend.NoOp: boolean;
begin
  result := IMAPcommand('NOOP') = 'OK';
end;

FUNCTION TIMAPSend.list(FromFolder: string; CONST FolderList: TStrings): boolean;
begin
  result := IMAPcommand('LIST "' + FromFolder + '" *') = 'OK';
  ParseFolderList(FolderList);
end;

FUNCTION TIMAPSend.ListSearch(FromFolder, Search: string; CONST FolderList: TStrings): boolean;
begin
  result := IMAPcommand('LIST "' + FromFolder + '" "' + Search +'"') = 'OK';
  ParseFolderList(FolderList);
end;

FUNCTION TIMAPSend.ListSubscribed(FromFolder: string; CONST FolderList: TStrings): boolean;
begin
  result := IMAPcommand('LSUB "' + FromFolder + '" *') = 'OK';
  ParseFolderList(FolderList);
end;

FUNCTION TIMAPSend.ListSearchSubscribed(FromFolder, Search: string; CONST FolderList: TStrings): boolean;
begin
  result := IMAPcommand('LSUB "' + FromFolder + '" "' + Search +'"') = 'OK';
  ParseFolderList(FolderList);
end;

FUNCTION TIMAPSend.CreateFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('CREATE "' + FolderName + '"') = 'OK';
end;

FUNCTION TIMAPSend.DeleteFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('DELETE "' + FolderName + '"') = 'OK';
end;

FUNCTION TIMAPSend.RenameFolder(FolderName, NewFolderName: string): boolean;
begin
  result := IMAPcommand('RENAME "' + FolderName + '" "' + NewFolderName + '"') = 'OK';
end;

FUNCTION TIMAPSend.SubscribeFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('SUBSCRIBE "' + FolderName + '"') = 'OK';
end;

FUNCTION TIMAPSend.UnsubscribeFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('UNSUBSCRIBE "' + FolderName + '"') = 'OK';
end;

FUNCTION TIMAPSend.SelectFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('SELECT "' + FolderName + '"') = 'OK';
  FSelectedFolder := FolderName;
  ParseSelect;
end;

FUNCTION TIMAPSend.SelectROFolder(FolderName: string): boolean;
begin
  result := IMAPcommand('EXAMINE "' + FolderName + '"') = 'OK';
  FSelectedFolder := FolderName;
  ParseSelect;
end;

FUNCTION TIMAPSend.CloseFolder: boolean;
begin
  result := IMAPcommand('CLOSE') = 'OK';
  FSelectedFolder := '';
end;

FUNCTION TIMAPSend.StatusFolder(FolderName, value: string): integer;
VAR
  n: integer;
  s, t: string;
begin
  result := -1;
  value := uppercase(value);
  if IMAPcommand('STATUS "' + FolderName + '" (' + value + ')' ) = 'OK' then
  begin
    ProcessLiterals;
    for n := 0 to FFullResult.count - 1 do
    begin
      s := FFullResult[n];
//      s := UpperCase(FFullResult[n]);
      if (pos('* ', s) = 1) and (pos(FolderName, s) >= 1) and (pos(value, s) > 0 ) then
      begin
        t := SeparateRight(s, value);
        t := SeparateLeft(t, ')');
        t := trim(t);
        result := strToIntDef(t, -1);
        break;
      end;
    end;
  end;
end;

FUNCTION TIMAPSend.ExpungeFolder: boolean;
begin
  result := IMAPcommand('EXPUNGE') = 'OK';
end;

FUNCTION TIMAPSend.CheckFolder: boolean;
begin
  result := IMAPcommand('CHECK') = 'OK';
end;

FUNCTION TIMAPSend.AppendMess(ToFolder: string; CONST Mess: TStrings): boolean;
begin
  result := IMAPuploadCommand('APPEND "' + ToFolder + '"', Mess) = 'OK';
end;

FUNCTION TIMAPSend.DeleteMess(MessID: integer): boolean;
VAR
  s: string;
begin
  s := 'STORE ' + intToStr(MessID) + ' +FLAGS.SILENT (\Deleted)';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
end;

FUNCTION TIMAPSend.FetchMess(MessID: integer; CONST Mess: TStrings): boolean;
VAR
  s: string;
begin
  s := 'FETCH ' + intToStr(MessID) + ' (RFC822)';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
  ParseMess(Mess);
end;

FUNCTION TIMAPSend.FetchHeader(MessID: integer; CONST Headers: TStrings): boolean;
VAR
  s: string;
begin
  s := 'FETCH ' + intToStr(MessID) + ' (RFC822.HEADER)';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
  ParseMess(Headers);
end;

FUNCTION TIMAPSend.MessageSize(MessID: integer): integer;
VAR
  n: integer;
  s, t: string;
begin
  result := -1;
  s := 'FETCH ' + intToStr(MessID) + ' (RFC822.SIZE)';
  if FUID then
    s := 'UID ' + s;
  if IMAPcommand(s) = 'OK' then
  begin
    ProcessLiterals;
    for n := 0 to FFullResult.count - 1 do
    begin
      s := uppercase(FFullResult[n]);
      if (pos('* ', s) = 1) and (pos('RFC822.SIZE', s) > 0 ) then
      begin
        t := SeparateRight(s, 'RFC822.SIZE ');
        t := trim(SeparateLeft(t, ')'));
        t := trim(SeparateLeft(t, ' '));
        result := strToIntDef(t, -1);
        break;
      end;
    end;
  end;
end;

FUNCTION TIMAPSend.CopyMess(MessID: integer; ToFolder: string): boolean;
VAR
  s: string;
begin
  s := 'COPY ' + intToStr(MessID) + ' "' + ToFolder + '"';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
end;

FUNCTION TIMAPSend.SearchMess(Criteria: string; CONST FoundMess: TStrings): boolean;
VAR
  s: string;
begin
  s := 'SEARCH ' + Criteria;
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
  ParseSearch(FoundMess);
end;

FUNCTION TIMAPSend.SetFlagsMess(MessID: integer; Flags: string): boolean;
VAR
  s: string;
begin
  s := 'STORE ' + intToStr(MessID) + ' FLAGS.SILENT (' + Flags + ')';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
end;

FUNCTION TIMAPSend.AddFlagsMess(MessID: integer; Flags: string): boolean;
VAR
  s: string;
begin
  s := 'STORE ' + intToStr(MessID) + ' +FLAGS.SILENT (' + Flags + ')';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
end;

FUNCTION TIMAPSend.DelFlagsMess(MessID: integer; Flags: string): boolean;
VAR
  s: string;
begin
  s := 'STORE ' + intToStr(MessID) + ' -FLAGS.SILENT (' + Flags + ')';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
end;

FUNCTION TIMAPSend.GetFlagsMess(MessID: integer; VAR Flags: string): boolean;
VAR
  s: string;
  n: integer;
begin
  Flags := '';
  s := 'FETCH ' + intToStr(MessID) + ' (FLAGS)';
  if FUID then
    s := 'UID ' + s;
  result := IMAPcommand(s) = 'OK';
  ProcessLiterals;
  for n := 0 to FFullResult.count - 1 do
  begin
    s := uppercase(FFullResult[n]);
    if (pos('* ', s) = 1) and (pos('FLAGS', s) > 0 ) then
    begin
      s := SeparateRight(s, 'FLAGS');
      s := Separateright(s, '(');
      Flags := trim(SeparateLeft(s, ')'));
    end;
  end;
end;

FUNCTION TIMAPSend.StartTLS: boolean;
begin
  result := false;
  if FindCap('STARTTLS') <> '' then
  begin
    if IMAPcommand('STARTTLS') = 'OK' then
    begin
      Fsock.SSLDoConnect;
      result := FSock.LastError = 0;
    end;
  end;
end;

//Paul Buskermolen <p.buskermolen@pinkroccade.com>
FUNCTION TIMAPSend.GetUID(MessID: integer; VAR uid : integer): boolean;
VAR
  s, sUid: string;
  n: integer;
begin
  sUID := '';
  s := 'FETCH ' + intToStr(MessID) + ' UID';
  result := IMAPcommand(s) = 'OK';
  ProcessLiterals;
  for n := 0 to FFullResult.count - 1 do
  begin
    s := uppercase(FFullResult[n]);
    if pos('FETCH (UID', s) >= 1 then
    begin
      s := Separateright(s, '(UID ');
      sUID := trim(SeparateLeft(s, ')'));
    end;
  end;
  uid := strToIntDef(sUID, 0);
end;

{==============================================================================}

end.
