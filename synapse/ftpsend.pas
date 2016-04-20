{==============================================================================|
| project : Ararat Synapse                                       | 004.000.000 |
|==============================================================================|
| content: FTP Client                                                          |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2010.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Petr Esner <petr.esner@atlas.cz>                                           |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{: @abstract(FTP client protocol)

used RFC: RFC-959, RFC-2228, RFC-2428
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
{$TYPEINFO ON}// Borland changed defualt Visibility from Public to Published
                // and it requires RTTI to be generated $M+
{$M+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT ftpsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, synaip, synsock;

CONST
  cFtpProtocol = '21';
  cFtpDataProtocol = '20';

  {:Terminating value for TLogonActions}
  FTP_OK = 255;
  {:Terminating value for TLogonActions}
  FTP_ERR = 254;

TYPE
  {:Array for holding definition of logon sequence.}
  TLogonActions = array [0..17] of byte;

  {:Procedural type for OnStatus event. Sender is calling @link(TFTPSend) object.
   value is FTP command or reply to this comand. (if it is reply, Response
   is @true).}
  TFTPStatus = PROCEDURE(Sender: TObject; Response: boolean;
    CONST value: string) of object;

  {: @abstract(Object for holding file information) parsed from directory
   listing of FTP Server.}
  TFTPListRec = class(TObject)
  private
    FFileName: string;
    FDirectory: boolean;
    FReadable: boolean;
    FFileSize: int64;
    FFileTime: TDateTime;
    FOriginalLine: string;
    FMask: string;
    FPermission: string;
  public
    {: You can assign another TFTPListRec to this object.}
    PROCEDURE assign(value: TFTPListRec); virtual;
    {:name of file}
    PROPERTY fileName: string read FFileName write FFileName;
    {:if name is subdirectory not file.}
    PROPERTY directory: boolean read FDirectory write FDirectory;
    {:if you have rights to read}
    PROPERTY Readable: boolean read FReadable write FReadable;
    {:size of file in bytes}
    PROPERTY filesize: int64 read FFileSize write FFileSize;
    {:date and time of file. Local server timezone is used. Any timezone
     conversions was not done!}
    PROPERTY FileTime: TDateTime read FFileTime write FFileTime;
    {:original unparsed line}
    PROPERTY OriginalLine: string read FOriginalLine write FOriginalLine;
    {:mask what was used for parsing}
    PROPERTY mask: string read FMask write FMask;
    {:permission string (depending on used mask!)}
    PROPERTY Permission: string read FPermission write FPermission;
  end;

  {:@abstract(This is TList of TFTPListRec objects.)
   This object is used for holding lististing of all files information in listed
   directory on FTP Server.}
  TFTPList = class(TObject)
  protected
    FList: TList;
    FLines: TStringList;
    FMasks: TStringList;
    FUnparsedLines: TStringList;
    Monthnames: string;
    BlockSize: string;
    DirFlagValue: string;
    fileName: string;
    VMSFileName: string;
    Day: string;
    Month: string;
    ThreeMonth: string;
    YearTime: string;
    Year: string;
    Hours: string;
    HoursModif: ansistring;
    Minutes: string;
    Seconds: string;
    size: ansistring;
    Permissions: ansistring;
    DirFlag: string;
    FUNCTION GetListItem(index: integer): TFTPListRec; virtual;
    FUNCTION ParseEPLF(value: string): boolean; virtual;
    PROCEDURE ClearStore; virtual;
    FUNCTION ParseByMask(value, NextValue, mask: ansistring): integer; virtual;
    FUNCTION CheckValues: boolean; virtual;
    PROCEDURE FillRecord(CONST value: TFTPListRec); virtual;
  public
    {:Constructor. You not need create this object, it is created by TFTPSend
     class as their PROPERTY.}
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Clear list.}
    PROCEDURE clear; virtual;

    {:count of holded @link(TFTPListRec) objects}
    FUNCTION count: integer; virtual;

    {:Assigns one list to another}
    PROCEDURE assign(value: TFTPList); virtual;

    {:try to parse raw directory listing in @link(lines) to list of
     @link(TFTPListRec).}
    PROCEDURE ParseLines; virtual;

    {:By this property you have access to list of @link(TFTPListRec).
     This is for compatibility only. Please, use @link(Items) instead.}
    PROPERTY list: TList read FList;

    {:By this property you have access to list of @link(TFTPListRec).}
    PROPERTY Items[index: integer]: TFTPListRec read GetListItem; default;

    {:Set of lines with RAW directory listing for @link(parseLines)}
    PROPERTY lines: TStringList read FLines;

    {:Set of masks for directory listing parser. It is predefined by default,
    however you can modify it as you need. (for example, you can add your own
    definition mask.) mask is same as mask used in TotalCommander.}
    PROPERTY Masks: TStringList read FMasks;

    {:After @link(ParseLines) it holding lines what was not sucessfully parsed.}
    PROPERTY UnparsedLines: TStringList read FUnparsedLines;
  end;

  {:@abstract(Implementation of FTP protocol.)
   Note: Are you missing properties for setting Username and Password? Look to
   parent @link(TSynaClient) object! (Username and Password have default values
   for "anonymous" FTP login)

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TFTPSend = class(TSynaClient)
  protected
    FOnStatus: TFTPStatus;
    FSock: TTCPBlockSocket;
    FDSock: TTCPBlockSocket;
    FResultCode: integer;
    FResultString: string;
    FFullResult: TStringList;
    FAccount: string;
    FFWHost: string;
    FFWPort: string;
    FFWUsername: string;
    FFWPassword: string;
    FFWMode: integer;
    FDataStream: TMemoryStream;
    FDataIP: string;
    FDataPort: string;
    FDirectFile: boolean;
    FDirectFileName: string;
    FCanResume: boolean;
    FPassiveMode: boolean;
    FForceDefaultPort: boolean;
    FForceOldPort: boolean;
    FFtpList: TFTPList;
    FBinaryMode: boolean;
    FAutoTLS: boolean;
    FIsTLS: boolean;
    FIsDataTLS: boolean;
    FTLSonData: boolean;
    FFullSSL: boolean;
    FUNCTION Auth(mode: integer): boolean; virtual;
    FUNCTION Connect: boolean; virtual;
    FUNCTION InternalStor(CONST command: string; RestoreAt: int64): boolean; virtual;
    FUNCTION DataSocket: boolean; virtual;
    FUNCTION AcceptDataSocket: boolean; virtual;
    PROCEDURE DoStatus(Response: boolean; CONST value: string); virtual;
  public
    {:Custom definition of login sequence. You can use this when you set
     @link(FWMode) to value -1.}
    CustomLogon: TLogonActions;

    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Waits and read FTP server response. You need this only in special cases!}
    FUNCTION ReadResult: integer; virtual;

    {:Parse remote side information of data channel from value string (returned
     by PASV command). This FUNCTION you need only in special cases!}
    PROCEDURE ParseRemote(value: string); virtual;

    {:Parse remote side information of data channel from value string (returned
     by EPSV command). This FUNCTION you need only in special cases!}
    PROCEDURE ParseRemoteEPSV(value: string); virtual;

    {:Send Value as FTP command to FTP server. Returned result code is result of
     this FUNCTION.
     This command is good for sending site specific command, or non-standard
     commands.}
    FUNCTION FTPCommand(CONST value: string): integer; virtual;

    {:Connect and logon to FTP server. If you specify any FireWall, connect to
     firewall and throw them connect to FTP Server. Login sequence depending on
     @link(FWMode).}
    FUNCTION Login: boolean; virtual;

    {:Logoff and disconnect from FTP server.}
    FUNCTION Logout: boolean; virtual;

    {:Break current transmission of data. (You can call this method from
     Sock.OnStatus event, or from another thread.)}
    PROCEDURE Abort; virtual;

    {:Break current transmission of data. It is same as Abort, but it send abort
     telnet commands prior ABOR FTP command. Some servers need it. (You can call
     this method from Sock.OnStatus event, or from another thread.)}
    PROCEDURE TelnetAbort; virtual;

    {:Download directory listing of Directory on FTP server. If Directory is
     empty string, download listing of current working directory.
     if NameList is @true, download only names of files in directory.
     (internally use NLST command instead list command)
     if NameList is @false, returned list is also parsed to @link(FTPList)
     PROPERTY.}
    FUNCTION list(directory: string; NameList: boolean): boolean; virtual;

    {:Read data from FileName on FTP server. If Restore is @true and server
     supports resume dowloads, download is resumed. (received is only rest
     of file)}
    FUNCTION RetrieveFile(CONST fileName: string; Restore: boolean): boolean; virtual;

    {:Send data to FileName on FTP server. If Restore is @true and server
     supports resume upload, upload is resumed. (send only rest of file)
     in this case if remote file is same length as local file, nothing will be
     done. if remote file is larger then local, resume is disabled and file is
     transfered from begin!}
    FUNCTION StoreFile(CONST fileName: string; Restore: boolean): boolean; virtual;

    {:Send data to FTP server and assing unique name for this file.}
    FUNCTION StoreUniqueFile: boolean; virtual;

    {:Append data to FileName on FTP server.}
    FUNCTION AppendFile(CONST fileName: string): boolean; virtual;

    {:Rename on FTP server file with OldName to NewName.}
    FUNCTION RenameFile(CONST OldName, NewName: string): boolean; virtual;

    {:Delete file FileName on FTP server.}
    FUNCTION DeleteFile(CONST fileName: string): boolean; virtual;

    {:Return size of Filename file on FTP server. If command failed (i.e. not
     implemented), return -1.}
    FUNCTION filesize(CONST fileName: string): int64; virtual;

    {:Send NOOP command to FTP server for preserve of disconnect by inactivity
     timeout.}
    FUNCTION NoOp: boolean; virtual;

    {:Change currect working directory to Directory on FTP server.}
    FUNCTION ChangeWorkingDir(CONST directory: string): boolean; virtual;

    {:walk to upper directory on FTP server.}
    FUNCTION ChangeToParentDir: boolean; virtual;

    {:walk to root directory on FTP server. (May not work with all servers properly!)}
    FUNCTION ChangeToRootDir: boolean; virtual;

    {:Delete Directory on FTP server.}
    FUNCTION DeleteDir(CONST directory: string): boolean; virtual;

    {:Create Directory on FTP server.}
    FUNCTION CreateDir(CONST directory: string): boolean; virtual;

    {:Return current working directory on FTP server.}
    FUNCTION GetCurrentDir: string; virtual;

    {:Establish data channel to FTP server and retrieve data.
     This FUNCTION you need only in special cases, i.e. when you need to implement
     some special unsupported FTP command!}
    FUNCTION DataRead(CONST DestStream: TStream): boolean; virtual;

    {:Establish data channel to FTP server and send data.
     This FUNCTION you need only in special cases, i.e. when you need to implement
     some special unsupported FTP command.}
    FUNCTION DataWrite(CONST SourceStream: TStream): boolean; virtual;
  Published
    {:After FTP command contains result number of this operation.}
    PROPERTY ResultCode: integer read FResultCode;

    {:After FTP command contains main line of result.}
    PROPERTY resultString: string read FResultString;

    {:After any FTP command it contains all lines of FTP server reply.}
    PROPERTY FullResult: TStringList read FFullResult;

    {:Account information used in some cases inside login sequence.}
    PROPERTY Account: string read FAccount write FAccount;

    {:Address of firewall. If empty string (default), firewall not used.}
    PROPERTY FWHost: string read FFWHost write FFWHost;

    {:port of firewall. standard value is same port as ftp server used. (21)}
    PROPERTY FWPort: string read FFWPort write FFWPort;

    {:Username for login to firewall. (if needed)}
    PROPERTY FWUsername: string read FFWUsername write FFWUsername;

    {:password for login to firewall. (if needed)}
    PROPERTY FWPassword: string read FFWPassword write FFWPassword;

    {:Type of Firewall. Used only if you set some firewall address. Supported
     predefined firewall login sequences are described by comments in Source
     file where you can see pseudocode decribing each sequence.}
    PROPERTY FWMode: integer read FFWMode write FFWMode;

    {:Socket object used for TCP/IP operation on control channel. Good for
     seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;

    {:Socket object used for TCP/IP operation on data channel. Good for seting
     OnStatus hook, etc.}
    PROPERTY DSock: TTCPBlockSocket read FDSock;

    {:If you not use @link(DirectFile) mode, all data transfers is made to or
     from this stream.}
    PROPERTY DataStream: TMemoryStream read FDataStream;

    {:After data connection is established, contains remote side IP of this
     connection.}
    PROPERTY DataIP: string read FDataIP;

    {:After data connection is established, contains remote side port of this
     connection.}
    PROPERTY DataPort: string read FDataPort;

    {:Mode of data handling by data connection. If @False, all data operations
     are made to or from @link(DataStream) TMemoryStream.
     if @true, data operations is made directly to file in your disk. (fileName
     is specified by @link(DirectFileName) PROPERTY.) Dafault is @false!}
    PROPERTY DirectFile: boolean read FDirectFile write FDirectFile;

    {:Filename for direct disk data operations.}
    PROPERTY DirectFileName: string read FDirectFileName write FDirectFileName;

    {:Indicate after @link(Login) if remote server support resume downloads and
     uploads.}
    PROPERTY CanResume: boolean read FCanResume;

    {:If true (default value), all transfers is made by passive method.
     it is safer method for various firewalls.}
    PROPERTY PassiveMode: boolean read FPassiveMode write FPassiveMode;

    {:Force to listen for dataconnection on standard port (20). Default is @false,
     dataconnections will be made to any non-standard port reported by PORT FTP
     command. This setting is not used, if you use passive mode.}
    PROPERTY ForceDefaultPort: boolean read FForceDefaultPort write FForceDefaultPort;

    {:When is @true, then is disabled EPSV and EPRT support. However without this
     commands you cannot use IPv6! (Disabling of this commands is needed only
     when you are behind some crap firewall/NAT.}
    PROPERTY ForceOldPort: boolean read FForceOldPort write FForceOldPort;

    {:You may set this hook for monitoring FTP commands and replies.}
    PROPERTY OnStatus: TFTPStatus read FOnStatus write FOnStatus;

    {:After LIST command is here parsed list of files in given directory.}
    PROPERTY FtpList: TFTPList read FFtpList;

    {:if @true (default), then data transfers is in binary mode. If this is set
     to @false, then ASCII mode is used.}
    PROPERTY BinaryMode: boolean read FBinaryMode write FBinaryMode;

    {:if is true, then if server support upgrade to SSL/TLS mode, then use them.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:if server listen on SSL/TLS port, then you set this to true.}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;

    {:Signalise, if control channel is in SSL/TLS mode.}
    PROPERTY IsTLS: boolean read FIsTLS;

    {:Signalise, if data transfers is in SSL/TLS mode.}
    PROPERTY IsDataTLS: boolean read FIsDataTLS;

    {:If @true (default), then try to use SSL/TLS on data transfers too.
     if @false, then SSL/TLS is used only for control connection.}
    PROPERTY TLSonData: boolean read FTLSonData write FTLSonData;
  end;

{:A very useful function, and example of use can be found in the TFtpSend object.
 Dowload specified file from FTP Server to LocalFile.}
FUNCTION FtpGetFile(CONST IP, Port, fileName, LocalFile,
  User, Pass: string): boolean;

{:A very useful function, and example of use can be found in the TFtpSend object.
 Upload specified LocalFile to FTP Server.}
FUNCTION FtpPutFile(CONST IP, Port, fileName, LocalFile,
  User, Pass: string): boolean;

{:A very useful function, and example of use can be found in the TFtpSend object.
 Initiate transfer of file between two FTP servers.}
FUNCTION FtpInterServerTransfer(
  CONST FromIP, FromPort, FromFile, FromUser, FromPass: string;
  CONST ToIP, ToPort, ToFile, ToUser, ToPass: string): boolean;

IMPLEMENTATION

CONSTRUCTOR TFTPSend.create;
begin
  inherited create;
  FFullResult := TStringList.create;
  FDataStream := TMemoryStream.create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.ConvertLineEnd := true;
  FDSock := TTCPBlockSocket.create;
  FDSock.Owner := self;
  FFtpList := TFTPList.create;
  FTimeout := 300000;
  FTargetPort := cFtpProtocol;
  FUsername := 'anonymous';
  FPassword := 'anonymous@' + FSock.LocalName;
  FDirectFile := false;
  FPassiveMode := true;
  FForceDefaultPort := false;
  FForceOldPort := false;
  FAccount := '';
  FFWHost := '';
  FFWPort := cFtpProtocol;
  FFWUsername := '';
  FFWPassword := '';
  FFWMode := 0;
  FBinaryMode := true;
  FAutoTLS := false;
  FFullSSL := false;
  FIsTLS := false;
  FIsDataTLS := false;
  FTLSonData := true;
end;

DESTRUCTOR TFTPSend.destroy;
begin
  FDSock.free;
  FSock.free;
  FFTPList.free;
  FDataStream.free;
  FFullResult.free;
  inherited destroy;
end;

PROCEDURE TFTPSend.DoStatus(Response: boolean; CONST value: string);
begin
  if assigned(OnStatus) then
    OnStatus(self, Response, value);
end;

FUNCTION TFTPSend.ReadResult: integer;
VAR
  s, c: ansistring;
begin
  FFullResult.clear;
  c := '';
  repeat
    s := FSock.RecvString(FTimeout);
    if c = '' then
      if length(s) > 3 then
        if s[4] in [' ', '-'] then
          c :=copy(s, 1, 3);
    FResultString := s;
    FFullResult.add(s);
    DoStatus(true, s);
    if FSock.LastError <> 0 then
      break;
  until (c <> '') and (pos(c + ' ', s) = 1);
  result := strToIntDef(c, 0);
  FResultCode := result;
end;

FUNCTION TFTPSend.FTPCommand(CONST value: string): integer;
begin
  FSock.Purge;
  FSock.SendString(value + CRLF);
  DoStatus(false, value);
  result := ReadResult;
end;

// based on idea by Petr Esner <petr.esner@atlas.cz>
FUNCTION TFTPSend.Auth(mode: integer): boolean;
CONST
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action0: TLogonActions =
    (0, FTP_OK, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if SITE <FTPServer> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action1: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     5, FTP_ERR, 9,
     0, FTP_OK, 12,
     1, FTP_OK, 15,
     2, FTP_OK, FTP_ERR);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if USER <UserName>'@'<FTPServer> then OK!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action2: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     6, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //if not USER <FWusername> then
  //  if not PASS <FWPassword> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action3: TLogonActions =
    (3, 6, 3,
     4, 6, FTP_ERR,
     0, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //OPEN <FTPserver>
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action4: TLogonActions =
    (7, 3, 3,
     0, FTP_OK, 6,
     1, FTP_OK, 9,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0);

  //if USER <UserName>'@'<FTPServer> then OK!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action5: TLogonActions =
    (6, FTP_OK, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <FWUserName>@<FTPServer> then
  //  if not PASS <FWPassword> then ERROR!
  //if not USER <username> then
  //  if not PASS <password> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action6: TLogonActions =
    (8, 6, 3,
     4, 6, FTP_ERR,
     0, FTP_OK, 9,
     1, FTP_OK, 12,
     2, FTP_OK, FTP_ERR,
     0, 0, 0);

  //if USER <UserName>@<FTPServer> <FWUserName> then ERROR!
  //if not PASS <password> then
  //  if not ACCT <account> then ERROR!
  //OK!
  Action7: TLogonActions =
    (9, FTP_ERR, 3,
     1, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);

  //if not USER <UserName>@<FWUserName>@<FTPServer> then
  //  if not PASS <Password>@<FWPassword> then
  //    if not ACCT <account> then ERROR!
  //OK!
  Action8: TLogonActions =
    (10, FTP_OK, 3,
     11, FTP_OK, 6,
     2, FTP_OK, FTP_ERR,
     0, 0, 0, 0, 0, 0, 0, 0, 0);
VAR
  FTPServer: string;
  LogonActions: TLogonActions;
  i: integer;
  s: string;
  x: integer;
begin
  result := false;
  if FFWHost = '' then
    mode := 0;
  if (FTargetPort = cFtpProtocol) or (FTargetPort = '21') then
    FTPServer := FTargetHost
  else
    FTPServer := FTargetHost + ':' + FTargetPort;
  case mode of
    -1:
      LogonActions := CustomLogon;
    1:
      LogonActions := Action1;
    2:
      LogonActions := Action2;
    3:
      LogonActions := Action3;
    4:
      LogonActions := Action4;
    5:
      LogonActions := Action5;
    6:
      LogonActions := Action6;
    7:
      LogonActions := Action7;
    8:
      LogonActions := Action8;
  else
    LogonActions := Action0;
  end;
  i := 0;
  repeat
    case LogonActions[i] of
      0:  s := 'USER ' + FUserName;
      1:  s := 'PASS ' + FPassword;
      2:  s := 'ACCT ' + FAccount;
      3:  s := 'USER ' + FFWUserName;
      4:  s := 'PASS ' + FFWPassword;
      5:  s := 'SITE ' + FTPServer;
      6:  s := 'USER ' + FUserName + '@' + FTPServer;
      7:  s := 'OPEN ' + FTPServer;
      8:  s := 'USER ' + FFWUserName + '@' + FTPServer;
      9:  s := 'USER ' + FUserName + '@' + FTPServer + ' ' + FFWUserName;
      10: s := 'USER ' + FUserName + '@' + FFWUserName + '@' + FTPServer;
      11: s := 'PASS ' + FPassword + '@' + FFWPassword;
    end;
    x := FTPCommand(s);
    x := x div 100;
    if (x <> 2) and (x <> 3) then
      exit;
    i := LogonActions[i + x - 1];
    case i of
      FTP_ERR:
        exit;
      FTP_OK:
        begin
          result := true;
          exit;
        end;
    end;
  until false;
end;


FUNCTION TFTPSend.Connect: boolean;
begin
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError = 0 then
    if FFWHost = '' then
      FSock.Connect(FTargetHost, FTargetPort)
    else
      FSock.Connect(FFWHost, FFWPort);
  if FSock.LastError = 0 then
    if FFullSSL then
      FSock.SSLDoConnect;
  result := FSock.LastError = 0;
end;

FUNCTION TFTPSend.Login: boolean;
VAR
  x: integer;
begin
  result := false;
  FCanResume := false;
  if not Connect then
    exit;
  FIsTLS := FFullSSL;
  FIsDataTLS := false;
  repeat
    x := ReadResult div 100;
  until x <> 1;
  if x <> 2 then
    exit;
  if FAutoTLS and not(FIsTLS) then
    if (FTPCommand('AUTH TLS') div 100) = 2 then
    begin
      FSock.SSLDoConnect;
      FIsTLS := FSock.LastError = 0;
      if not FIsTLS then
      begin
        result := false;
        exit;
      end;
    end;
  if not Auth(FFWMode) then
    exit;
  if FIsTLS then
  begin
    FTPCommand('PBSZ 0');
    if FTLSonData then
      FIsDataTLS := (FTPCommand('PROT P') div 100) = 2;
    if not FIsDataTLS then
      FTPCommand('PROT C');
  end;
  FTPCommand('TYPE I');
  FTPCommand('STRU F');
  FTPCommand('MODE S');
  if FTPCommand('REST 0') = 350 then
    if FTPCommand('REST 1') = 350 then
    begin
      FTPCommand('REST 0');
      FCanResume := true;
    end;
  result := true;
end;

FUNCTION TFTPSend.Logout: boolean;
begin
  result := (FTPCommand('QUIT') div 100) = 2;
  FSock.CloseSocket;
end;

PROCEDURE TFTPSend.ParseRemote(value: string);
VAR
  n: integer;
  nb, ne: integer;
  s: string;
  x: integer;
begin
  value := trim(value);
  nb := pos('(',value);
  ne := pos(')',value);
  if (nb = 0) or (ne = 0) then
  begin
    nb:=RPos(' ',value);
    s:=copy(value, nb + 1, length(value) - nb);
  end
  else
  begin
    s:=copy(value,nb+1,ne-nb-1);
  end;
  for n := 1 to 4 do
    if n = 1 then
      FDataIP := Fetch(s, ',')
    else
      FDataIP := FDataIP + '.' + Fetch(s, ',');
  x := strToIntDef(Fetch(s, ','), 0) * 256;
  x := x + strToIntDef(Fetch(s, ','), 0);
  FDataPort := intToStr(x);
end;

PROCEDURE TFTPSend.ParseRemoteEPSV(value: string);
VAR
  n: integer;
  s, v: ansistring;
begin
  s := SeparateRight(value, '(');
  s := trim(SeparateLeft(s, ')'));
  Delete(s, length(s), 1);
  v := '';
  for n := length(s) downto 1 do
    if s[n] in ['0'..'9'] then
      v := s[n] + v
    else
      break;
  FDataPort := v;
  FDataIP := FTargetHost;
end;

FUNCTION TFTPSend.DataSocket: boolean;
VAR
  s: string;
begin
  result := false;
  if FIsDataTLS then
    FPassiveMode := true;
  if FPassiveMode then
  begin
    if FSock.IP6used then
      s := '2'
    else
      s := '1';
    if FSock.IP6used and not(FForceOldPort) and ((FTPCommand('EPSV ' + s) div 100) = 2) then
    begin
      ParseRemoteEPSV(FResultString);
    end
    else
      if FSock.IP6used then
        exit
      else
      begin
        if (FTPCommand('PASV') div 100) <> 2 then
          exit;
        ParseRemote(FResultString);
      end;
    FDSock.CloseSocket;
    FDSock.Bind(FIPInterface, cAnyPort);
    FDSock.Connect(FDataIP, FDataPort);
    result := FDSock.LastError = 0;
  end
  else
  begin
    FDSock.CloseSocket;
    if FForceDefaultPort then
      s := cFtpDataProtocol
    else
      s := '0';
    //data conection from same interface as command connection
    FDSock.Bind(FSock.GetLocalSinIP, s);
    if FDSock.LastError <> 0 then
      exit;
    FDSock.SetLinger(true, 10000);
    FDSock.Listen;
    FDSock.GetSins;
    FDataIP := FDSock.GetLocalSinIP;
    FDataIP := FDSock.ResolveName(FDataIP);
    FDataPort := intToStr(FDSock.GetLocalSinPort);
    if FSock.IP6used and (not FForceOldPort) then
    begin
      if IsIp6(FDataIP) then
        s := '2'
      else
        s := '1';
      s := 'EPRT |' + s +'|' + FDataIP + '|' + FDataPort + '|';
      result := (FTPCommand(s) div 100) = 2;
    end;
    if not result and IsIP(FDataIP) then
    begin
      s := ReplaceString(FDataIP, '.', ',');
      s := 'PORT ' + s + ',' + intToStr(FDSock.GetLocalSinPort div 256)
        + ',' + intToStr(FDSock.GetLocalSinPort mod 256);
      result := (FTPCommand(s) div 100) = 2;
    end;
  end;
end;

FUNCTION TFTPSend.AcceptDataSocket: boolean;
VAR
  x: TSocket;
begin
  if FPassiveMode then
    result := true
  else
  begin
    result := false;
    if FDSock.CanRead(FTimeout) then
    begin
      x := FDSock.accept;
      if not FDSock.UsingSocks then
        FDSock.CloseSocket;
      FDSock.Socket := x;
      result := true;
    end;
  end;
  if result and FIsDataTLS then
  begin
    FDSock.SSL.assign(FSock.SSL);
    FDSock.SSLDoConnect;
    result := FDSock.LastError = 0;
  end;
end;

FUNCTION TFTPSend.DataRead(CONST DestStream: TStream): boolean;
VAR
  x: integer;
begin
  result := false;
  try
    if not AcceptDataSocket then
      exit;
    FDSock.RecvStreamRaw(DestStream, FTimeout);
    FDSock.CloseSocket;
    x := ReadResult;
    result := (x div 100) = 2;
  finally
    FDSock.CloseSocket;
  end;
end;

FUNCTION TFTPSend.DataWrite(CONST SourceStream: TStream): boolean;
VAR
  x: integer;
  b: boolean;
begin
  result := false;
  try
    if not AcceptDataSocket then
      exit;
    FDSock.SendStreamRaw(SourceStream);
    b := FDSock.LastError = 0;
    FDSock.CloseSocket;
    x := ReadResult;
    result := b and ((x div 100) = 2);
  finally
    FDSock.CloseSocket;
  end;
end;

FUNCTION TFTPSend.list(directory: string; NameList: boolean): boolean;
VAR
  x: integer;
begin
  result := false;
  FDataStream.clear;
  FFTPList.clear;
  if directory <> '' then
    directory := ' ' + directory;
  FTPCommand('TYPE A');
  if not DataSocket then
    exit;
  if NameList then
    x := FTPCommand('NLST' + directory)
  else
    x := FTPCommand('LIST' + directory);
  if (x div 100) <> 1 then
    exit;
  result := DataRead(FDataStream);
  if (not NameList) and result then
  begin
    FDataStream.position := 0;
    FFTPList.lines.LoadFromStream(FDataStream);
    FFTPList.ParseLines;
  end;
  FDataStream.position := 0;
end;

FUNCTION TFTPSend.RetrieveFile(CONST fileName: string; Restore: boolean): boolean;
VAR
  RetrStream: TStream;
begin
  result := false;
  if fileName = '' then
    exit;
  if not DataSocket then
    exit;
  Restore := Restore and FCanResume;
  if FDirectFile then
    if Restore and fileExists(FDirectFileName) then
      RetrStream := TFileStream.create(FDirectFileName,
        fmOpenReadWrite  or fmShareExclusive)
    else
      RetrStream := TFileStream.create(FDirectFileName,
        fmCreate or fmShareDenyWrite)
  else
    RetrStream := FDataStream;
  try
    if FBinaryMode then
      FTPCommand('TYPE I')
    else
      FTPCommand('TYPE A');
    if Restore then
    begin
      RetrStream.position := RetrStream.size;
      if (FTPCommand('REST ' + intToStr(RetrStream.size)) div 100) <> 3 then
        exit;
    end
    else
      if RetrStream is TMemoryStream then
        TMemoryStream(RetrStream).clear;
    if (FTPCommand('RETR ' + fileName) div 100) <> 1 then
      exit;
    result := DataRead(RetrStream);
    if not FDirectFile then
      RetrStream.position := 0;
  finally
    if FDirectFile then
      RetrStream.free;
  end;
end;

FUNCTION TFTPSend.InternalStor(CONST command: string; RestoreAt: int64): boolean;
VAR
  SendStream: TStream;
  StorSize: int64;
begin
  result := false;
  if FDirectFile then
    if not fileExists(FDirectFileName) then
      exit
    else
      SendStream := TFileStream.create(FDirectFileName,
        fmOpenRead or fmShareDenyWrite)
  else
    SendStream := FDataStream;
  try
    if not DataSocket then
      exit;
    if FBinaryMode then
      FTPCommand('TYPE I')
    else
      FTPCommand('TYPE A');
    StorSize := SendStream.size;
    if not FCanResume then
      RestoreAt := 0;
    if (StorSize > 0) and (RestoreAt = StorSize) then
    begin
      result := true;
      exit;
    end;
    if RestoreAt > StorSize then
      RestoreAt := 0;
    FTPCommand('ALLO ' + intToStr(StorSize - RestoreAt));
    if FCanResume then
      if (FTPCommand('REST ' + intToStr(RestoreAt)) div 100) <> 3 then
        exit;
    SendStream.position := RestoreAt;
    if (FTPCommand(command) div 100) <> 1 then
      exit;
    result := DataWrite(SendStream);
  finally
    if FDirectFile then
      SendStream.free;
  end;
end;

FUNCTION TFTPSend.StoreFile(CONST fileName: string; Restore: boolean): boolean;
VAR
  RestoreAt: int64;
begin
  result := false;
  if fileName = '' then
    exit;
  RestoreAt := 0;
  Restore := Restore and FCanResume;
  if Restore then
  begin
    RestoreAt := self.filesize(fileName);
    if RestoreAt < 0 then
      RestoreAt := 0;
  end;
  result := InternalStor('STOR ' + fileName, RestoreAt);
end;

FUNCTION TFTPSend.StoreUniqueFile: boolean;
begin
  result := InternalStor('STOU', 0);
end;

FUNCTION TFTPSend.AppendFile(CONST fileName: string): boolean;
begin
  result := false;
  if fileName = '' then
    exit;
  result := InternalStor('APPE ' + fileName, 0);
end;

FUNCTION TFTPSend.NoOp: boolean;
begin
  result := (FTPCommand('NOOP') div 100) = 2;
end;

FUNCTION TFTPSend.RenameFile(CONST OldName, NewName: string): boolean;
begin
  result := false;
  if (FTPCommand('RNFR ' + OldName) div 100) <> 3  then
    exit;
  result := (FTPCommand('RNTO ' + NewName) div 100) = 2;
end;

FUNCTION TFTPSend.DeleteFile(CONST fileName: string): boolean;
begin
  result := (FTPCommand('DELE ' + fileName) div 100) = 2;
end;

FUNCTION TFTPSend.filesize(CONST fileName: string): int64;
VAR
  s: string;
begin
  result := -1;
  if (FTPCommand('SIZE ' + fileName) div 100) = 2 then
  begin
    s := trim(SeparateRight(resultString, ' '));
    s := trim(SeparateLeft(s, ' '));
    {$IFDEF VER100}
      result := strToIntDef(s, -1);
    {$ELSE}
      result := StrToInt64Def(s, -1);
    {$ENDIF}
  end;
end;

FUNCTION TFTPSend.ChangeWorkingDir(CONST directory: string): boolean;
begin
  result := (FTPCommand('CWD ' + directory) div 100) = 2;
end;

FUNCTION TFTPSend.ChangeToParentDir: boolean;
begin
  result := (FTPCommand('CDUP') div 100) = 2;
end;

FUNCTION TFTPSend.ChangeToRootDir: boolean;
begin
  result := ChangeWorkingDir('/');
end;

FUNCTION TFTPSend.DeleteDir(CONST directory: string): boolean;
begin
  result := (FTPCommand('RMD ' + directory) div 100) = 2;
end;

FUNCTION TFTPSend.CreateDir(CONST directory: string): boolean;
begin
  result := (FTPCommand('MKD ' + directory) div 100) = 2;
end;

FUNCTION TFTPSend.GetCurrentDir: string;
begin
  result := '';
  if (FTPCommand('PWD') div 100) = 2 then
  begin
    result := SeparateRight(FResultString, '"');
    result := trim(Separateleft(result, '"'));
  end;
end;

PROCEDURE TFTPSend.Abort;
begin
  FSock.SendString('ABOR' + CRLF);
  FDSock.StopFlag := true;
end;

PROCEDURE TFTPSend.TelnetAbort;
begin
  FSock.SendString(#$ff + #$F4 + #$ff + #$F2);
  Abort;
end;

{==============================================================================}

PROCEDURE TFTPListRec.assign(value: TFTPListRec);
begin
  FFileName := value.fileName;
  FDirectory := value.directory;
  FReadable := value.Readable;
  FFileSize := value.filesize;
  FFileTime := value.FileTime;
  FOriginalLine := value.OriginalLine;
  FMask := value.mask;
end;

CONSTRUCTOR TFTPList.create;
begin
  inherited create;
  FList := TList.create;
  FLines := TStringList.create;
  FMasks := TStringList.create;
  FUnparsedLines := TStringList.create;
  //various UNIX
  FMasks.add('pppppppppp $!!!S*$TTT$DD$hh mm ss$YYYY$n*');
  FMasks.add('pppppppppp $!!!S*$DD$TTT$hh mm ss$YYYY$n*');
  FMasks.add('pppppppppp $!!!S*$TTT$DD$UUUUU$n*');  //mostly used UNIX format
  FMasks.add('pppppppppp $!!!S*$DD$TTT$UUUUU$n*');
  //MacOS
  FMasks.add('pppppppppp $!!S*$TTT$DD$UUUUU$n*');
  FMasks.add('pppppppppp $!S*$TTT$DD$UUUUU$n*');
  //Novell
  FMasks.add('d            $!S*$TTT$DD$UUUUU$n*');
  //Windows
  FMasks.add('MM DD YY  hh mmH !S* n*');
  FMasks.add('MM DD YY  hh mmH $ d!n*');
  FMasks.add('MM DD YYYY  hh mmH !S* n*');
  FMasks.add('MM DD YYYY  hh mmH $ d!n*');
  FMasks.add('DD MM YYYY  hh mmH !S* n*');
  FMasks.add('DD MM YYYY  hh mmH $ d!n*');
  //VMS
  FMasks.add('v*$  DD TTT YYYY hh mm');
  FMasks.add('v*$!DD TTT YYYY hh mm');
  FMasks.add('n*$                 YYYY MM DD hh mm$S*');
  //AS400
  FMasks.add('!S*$MM DD YY hh mm ss !n*');
  FMasks.add('!S*$DD MM YY hh mm ss !n*');
  FMasks.add('n*!S*$MM DD YY hh mm ss d');
  FMasks.add('n*!S*$DD MM YY hh mm ss d');
  //VxWorks
  FMasks.add('$S*    TTT DD YYYY  hh mm ss $n* $ d');
  FMasks.add('$S*    TTT DD YYYY  hh mm ss $n*');
  //Distinct
  FMasks.add('d    $S*$TTT DD YYYY  hh mm$n*');
  FMasks.add('d    $S*$TTT DD$hh mm$n*');
  //PC-NFSD
  FMasks.add('nnnnnnnn.nnn  dSSSSSSSSSSS MM DD YY  hh mmH');
  //VOS
  FMasks.add('-   SSSSS            YY MM DD hh mm ss  n*');
  FMasks.add('- d=  SSSSS  YY MM DD hh mm ss  n*');
  //Unissys ClearPath
  FMasks.add('nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn               SSSSSSSSS MM DD YYYY hh mm');
  FMasks.add('n*\x                                               SSSSSSSSS MM DD YYYY hh mm');
  //IBM
  FMasks.add('-     SSSSSSSSSSSS           d   MM DD YYYY   hh mm  n*');
  //OS9
  FMasks.add('-         YY MM DD hhmm d                        SSSSSSSSS n*');
  //tandem
  FMasks.add('nnnnnnnn                   SSSSSSS DD TTT YY hh mm ss');
  //MVS
  FMasks.add('-             YYYY MM DD                     SSSSS   d=O n*');
  //BullGCOS8
  FMasks.add('             $S* MM DD YY hh mm ss  !n*');
  FMasks.add('d            $S* MM DD YY           !n*');
  //BullGCOS7
  FMasks.add('                                         TTT DD  YYYY n*');
  FMasks.add('  d                                                   n*');
end;

DESTRUCTOR TFTPList.destroy;
begin
  clear;
  FList.free;
  FLines.free;
  FMasks.free;
  FUnparsedLines.free;
  inherited destroy;
end;

PROCEDURE TFTPList.clear;
VAR
  n:integer;
begin
  for n := 0 to FList.count - 1 do
    if Assigned(FList[n]) then
      TFTPListRec(FList[n]).free;
  FList.clear;
  FLines.clear;
  FUnparsedLines.clear;
end;

FUNCTION TFTPList.count: integer;
begin
  result := FList.count;
end;

FUNCTION TFTPList.GetListItem(index: integer): TFTPListRec;
begin
  result := nil;
  if index < count then
    result := TFTPListRec(FList[index]);
end;

PROCEDURE TFTPList.assign(value: TFTPList);
VAR
  flr: TFTPListRec;
  n: integer;
begin
  clear;
  for n := 0 to value.count - 1 do
  begin
    flr := TFTPListRec.create;
    flr.assign(value[n]);
    Flist.add(flr);
  end;
  lines.assign(value.lines);
  Masks.assign(value.Masks);
  UnparsedLines.assign(value.UnparsedLines);
end;

PROCEDURE TFTPList.ClearStore;
begin
  Monthnames := '';
  BlockSize := '';
  DirFlagValue := '';
  fileName := '';
  VMSFileName := '';
  Day := '';
  Month := '';
  ThreeMonth := '';
  YearTime := '';
  Year := '';
  Hours := '';
  HoursModif := '';
  Minutes := '';
  Seconds := '';
  size := '';
  Permissions := '';
  DirFlag := '';
end;

FUNCTION TFTPList.ParseByMask(value, NextValue, mask: ansistring): integer;
VAR
  Ivalue, IMask: integer;
  MaskC, LastMaskC: AnsiChar;
  c: AnsiChar;
  s: string;
begin
  ClearStore;
  result := 0;
  if value = '' then
    exit;
  if mask = '' then
    exit;
  Ivalue := 1;
  IMask := 1;
  result := 1;
  LastMaskC := ' ';
  while Imask <= length(mask) do
  begin
    if (mask[Imask] <> '*') and (Ivalue > length(value)) then
    begin
      result := 0;
      exit;
    end;
    MaskC := mask[Imask];
    if Ivalue > length(value) then
      exit;
    c := value[Ivalue];
    case MaskC of
      'n':
        fileName := fileName + c;
      'v':
        VMSFileName := VMSFileName + c;
      '.':
        begin
          if c in ['.', ' '] then
            fileName := TrimSP(fileName) + '.'
          else
          begin
            result := 0;
            exit;
          end;
        end;
      'D':
        Day := Day + c;
      'M':
        Month := Month + c;
      'T':
        ThreeMonth := ThreeMonth + c;
      'U':
        YearTime := YearTime + c;
      'Y':
        Year := Year + c;
      'h':
        Hours := Hours + c;
      'H':
        HoursModif := HoursModif + c;
      'm':
        Minutes := Minutes + c;
      's':
        Seconds := Seconds + c;
      'S':
        size := size + c;
      'p':
        Permissions := Permissions + c;
      'd':
        DirFlag := DirFlag + c;
      'x':
        if c <> ' ' then
          begin
            result := 0;
            exit;
          end;
      '*':
        begin
          s := '';
          if LastMaskC in ['n', 'v'] then
          begin
            if Imask = length(mask) then
              s := copy(value, IValue, MAXINT)
            else
              while IValue <= length(value) do
              begin
                if value[Ivalue] = ' ' then
                  break;
                s := s + value[Ivalue];
                inc(Ivalue);
              end;
            if LastMaskC = 'n' then
              fileName := fileName + s
            else
              VMSFileName := VMSFileName + s;
          end
          else
          begin
            while IValue <= length(value) do
            begin
              if not(value[Ivalue] in ['0'..'9']) then
                break;
              s := s + value[Ivalue];
              inc(Ivalue);
            end;
            case LastMaskC of
              'S':
                size := size + s;
            end;
          end;
          dec(IValue);
        end;
      '!':
        begin
          while IValue <= length(value) do
          begin
            if value[Ivalue] = ' ' then
              break;
            inc(Ivalue);
          end;
          while IValue <= length(value) do
          begin
            if value[Ivalue] <> ' ' then
              break;
            inc(Ivalue);
          end;
          dec(IValue);
        end;
      '$':
        begin
          while IValue <= length(value) do
          begin
            if not(value[Ivalue] in [' ', #9]) then
              break;
            inc(Ivalue);
          end;
          dec(IValue);
        end;
      '=':
        begin
          s := '';
          case LastmaskC of
            'S':
              begin
                while Imask <= length(mask) do
                begin
                  if not(mask[Imask] in ['0'..'9']) then
                    break;
                  s := s + mask[Imask];
                  inc(Imask);
                end;
                dec(Imask);
                BlockSize := s;
              end;
            'T':
              begin
                Monthnames := copy(mask, IMask, 12 * 3);
                inc(IMask, 12 * 3);
              end;
            'd':
              begin
                inc(Imask);
                DirFlagValue := mask[Imask];
              end;
          end;
        end;
      '\':
        begin
          value := NextValue;
          IValue := 0;
          result := 2;
        end;
    end;
    inc(Ivalue);
    inc(Imask);
    LastMaskC := MaskC;
  end;
end;

FUNCTION TFTPList.CheckValues: boolean;
VAR
  x, n: integer;
begin
  result := false;
  if fileName <> '' then
  begin
    if pos('?', VMSFilename) > 0 then
      exit;
    if pos('*', VMSFilename) > 0 then
      exit;
  end;
  if VMSFileName <> '' then
    if pos(';', VMSFilename) <= 0 then
      exit;
  if (fileName = '') and (VMSFileName = '') then
    exit;
  if Permissions <> '' then
  begin
    if length(Permissions) <> 10 then
      exit;
    for n := 1 to 10 do
      if not(Permissions[n] in
        ['a', 'b', 'c', 'd', 'h', 'l', 'p', 'r', 's', 't', 'w', 'x', 'y', '-']) then
        exit;
  end;
  if Day <> '' then
  begin
    Day := TrimSP(Day);
    x := strToIntDef(day, -1);
    if (x < 1) or (x > 31) then
      exit;
  end;
  if Month <> '' then
  begin
    Month := TrimSP(Month);
    x := strToIntDef(Month, -1);
    if (x < 1) or (x > 12) then
      exit;
  end;
  if Hours <> '' then
  begin
    Hours := TrimSP(Hours);
    x := strToIntDef(Hours, -1);
    if (x < 0) or (x > 24) then
      exit;
  end;
  if HoursModif <> '' then
  begin
    if not (HoursModif[1] in ['a', 'A', 'p', 'P']) then
      exit;
  end;
  if Minutes <> '' then
  begin
    Minutes := TrimSP(Minutes);
    x := strToIntDef(Minutes, -1);
    if (x < 0) or (x > 59) then
      exit;
  end;
  if Seconds <> '' then
  begin
    Seconds := TrimSP(Seconds);
    x := strToIntDef(Seconds, -1);
    if (x < 0) or (x > 59) then
      exit;
  end;
  if size <> '' then
  begin
    size := TrimSP(size);
    for n := 1 to length(size) do
      if not (size[n] in ['0'..'9']) then
        exit;
  end;

  if length(Monthnames) = (12 * 3) then
    for n := 1 to 12 do
      CustomMonthNames[n] := copy(Monthnames, ((n - 1) * 3) + 1, 3);
  if ThreeMonth <> '' then
  begin
    x := GetMonthNumber(ThreeMonth);
    if (x = 0) then
      exit;
  end;
  if YearTime <> '' then
  begin
    YearTime := ReplaceString(YearTime, '-', ':');
    if pos(':', YearTime) > 0 then
    begin
      if (GetTimeFromstr(YearTime) = -1) then
        exit;
    end
    else
    begin
      YearTime := TrimSP(YearTime);
      x := strToIntDef(YearTime, -1);
      if (x = -1) then
        exit;
      if (x < 1900) or (x > 2100) then
        exit;
    end;
  end;
  if Year <> '' then
  begin
    Year := TrimSP(Year);
    x := strToIntDef(Year, -1);
    if (x = -1) then
      exit;
    if length(Year) = 4 then
    begin
      if not((x > 1900) and (x < 2100)) then
        exit;
    end
    else
      if length(Year) = 2 then
      begin
        if not((x >= 0) and (x <= 99)) then
          exit;
      end
      else
        if length(Year) = 3 then
        begin
          if not((x >= 100) and (x <= 110)) then
            exit;
        end
        else
          exit;
  end;
  result := true;
end;

PROCEDURE TFTPList.FillRecord(CONST value: TFTPListRec);
VAR
  s: string;
  x: integer;
  myear: word;
  mmonth: word;
  mday: word;
  mhours, mminutes, mseconds: word;
  n: integer;
begin
  s := DirFlagValue;
  if s = '' then
    s := 'D';
  s := uppercase(s);
  value.directory :=  s = uppercase(DirFlag);
  if fileName <> '' then
    value.fileName := SeparateLeft(fileName, ' -> ');
  if VMSFileName <> '' then
  begin
    value.fileName := VMSFilename;
    value.directory := pos('.DIR;',VMSFilename) > 0;
  end;
  value.fileName := TrimSPRight(value.fileName);
  value.Readable := not value.directory;
  if BlockSize <> '' then
    x := strToIntDef(BlockSize, 1)
  else
    x := 1;
  {$IFDEF VER100}
  value.filesize := x * strToIntDef(size, 0);
  {$ELSE}
  value.filesize := x * StrToInt64Def(size, 0);
  {$ENDIF}

  DecodeDate(Date,myear,mmonth,mday);
  mhours := 0;
  mminutes := 0;
  mseconds := 0;

  if Day <> '' then
    mday := strToIntDef(day, 1);
  if Month <> '' then
    mmonth := strToIntDef(Month, 1);
  if length(Monthnames) = (12 * 3) then
    for n := 1 to 12 do
      CustomMonthNames[n] := copy(Monthnames, ((n - 1) * 3) + 1, 3);
  if ThreeMonth <> '' then
    mmonth := GetMonthNumber(ThreeMonth);
  if Year <> '' then
  begin
    myear := strToIntDef(Year, 0);
    if (myear <= 99) and (myear > 50) then
      myear := myear + 1900;
    if myear <= 50 then
      myear := myear + 2000;
  end;
  if YearTime <> '' then
  begin
    if pos(':', YearTime) > 0 then
    begin
      YearTime := TrimSP(YearTime);
      mhours := strToIntDef(Separateleft(YearTime, ':'), 0);
      mminutes := strToIntDef(SeparateRight(YearTime, ':'), 0);
      if (EncodeDate(myear, mmonth, mday)
        + EncodeTime(mHours, mminutes, 0, 0)) > now then
        dec(mYear);
    end
    else
      myear := strToIntDef(YearTime, 0);
  end;
  if Minutes <> '' then
    mminutes := strToIntDef(Minutes, 0);
  if Seconds <> '' then
    mseconds := strToIntDef(Seconds, 0);
  if Hours <> '' then
  begin
    mHours := strToIntDef(Hours, 0);
    if HoursModif <> '' then
      if uppercase(HoursModif[1]) = 'P' then
        if mHours <> 12 then
          mHours := MHours + 12;
  end;
  value.FileTime := EncodeDate(myear, mmonth, mday)
    + EncodeTime(mHours, mminutes, mseconds, 0);
  if Permissions <> '' then
  begin
    value.Permission := Permissions;
    value.Readable := uppercase(permissions)[2] = 'R';
    if uppercase(permissions)[1] = 'D' then
    begin
      value.directory := true;
      value.Readable := false;
    end
    else
      if uppercase(permissions)[1] = 'L' then
        value.directory := true;
  end;
end;

FUNCTION TFTPList.ParseEPLF(value: string): boolean;
VAR
  s, os: string;
  flr: TFTPListRec;
begin
  result := false;
  if value <> '' then
    if value[1] = '+' then
    begin
      os := value;
      Delete(value, 1, 1);
      flr := TFTPListRec.create;
      flr.fileName := SeparateRight(value, #9);
      s := Fetch(value, ',');
      while s <> '' do
      begin
        if s[1] = #9 then
          break;
        case s[1] of
          '/':
            flr.directory := true;
          'r':
            flr.Readable := true;
          's':
            {$IFDEF VER100}
            flr.filesize := strToIntDef(copy(s, 2, length(s) - 1), 0);
            {$ELSE}
            flr.filesize := StrToInt64Def(copy(s, 2, length(s) - 1), 0);
            {$ENDIF}
          'm':
            flr.FileTime := (strToIntDef(copy(s, 2, length(s) - 1), 0) / 86400)
              + 25569;
        end;
        s := Fetch(value, ',');
      end;
      if flr.fileName <> '' then
      if (flr.directory and ((flr.fileName = '.') or (flr.fileName = '..')))
        or (flr.fileName = '') then
        flr.free
      else
      begin
        flr.OriginalLine := os;
        flr.mask := 'EPLF';
        Flist.add(flr);
        result := true;
      end;
    end;
end;

PROCEDURE TFTPList.ParseLines;
VAR
  flr: TFTPListRec;
  n, m: integer;
  S: string;
  x: integer;
  b: boolean;
begin
  n := 0;
  while n < lines.count do
  begin
    if n = lines.count - 1 then
      s := ''
    else
      s := lines[n + 1];
    b := false;
    x := 0;
    if ParseEPLF(lines[n]) then
    begin
      b := true;
      x := 1;
    end
    else
      for m := 0 to Masks.count - 1 do
      begin
        x := ParseByMask(lines[n], s, Masks[m]);
        if x > 0 then
          if CheckValues then
          begin
            flr := TFTPListRec.create;
            FillRecord(flr);
            flr.OriginalLine := lines[n];
            flr.mask := Masks[m];
            if flr.directory and ((flr.fileName = '.') or (flr.fileName = '..')) then
              flr.free
            else
              Flist.add(flr);
            b := true;
            break;
          end;
      end;
    if not b then
      FUnparsedLines.add(lines[n]);
    inc(n);
    if x > 1 then
      inc(n, x - 1);
  end;
end;

{==============================================================================}

FUNCTION FtpGetFile(CONST IP, Port, fileName, LocalFile,
  User, Pass: string): boolean;
begin
  result := false;
  with TFTPSend.create do
  try
    if User <> '' then
    begin
      Username := User;
      Password := Pass;
    end;
    TargetHost := IP;
    TargetPort := Port;
    if not Login then
      exit;
    DirectFileName := LocalFile;
    DirectFile:=true;
    result := RetrieveFile(fileName, false);
    Logout;
  finally
    free;
  end;
end;

FUNCTION FtpPutFile(CONST IP, Port, fileName, LocalFile,
  User, Pass: string): boolean;
begin
  result := false;
  with TFTPSend.create do
  try
    if User <> '' then
    begin
      Username := User;
      Password := Pass;
    end;
    TargetHost := IP;
    TargetPort := Port;
    if not Login then
      exit;
    DirectFileName := LocalFile;
    DirectFile:=true;
    result := StoreFile(fileName, false);
    Logout;
  finally
    free;
  end;
end;

FUNCTION FtpInterServerTransfer(
  CONST FromIP, FromPort, FromFile, FromUser, FromPass: string;
  CONST ToIP, ToPort, ToFile, ToUser, ToPass: string): boolean;
VAR
  FromFTP, ToFTP: TFTPSend;
  s: string;
  x: integer;
begin
  result := false;
  FromFTP := TFTPSend.create;
  toFTP := TFTPSend.create;
  try
    if FromUser <> '' then
    begin
      FromFTP.Username := FromUser;
      FromFTP.Password := FromPass;
    end;
    if ToUser <> '' then
    begin
      ToFTP.Username := ToUser;
      ToFTP.Password := ToPass;
    end;
    FromFTP.TargetHost := FromIP;
    FromFTP.TargetPort := FromPort;
    ToFTP.TargetHost := ToIP;
    ToFTP.TargetPort := ToPort;
    if not FromFTP.Login then
      exit;
    if not ToFTP.Login then
      exit;
    if (FromFTP.FTPCommand('PASV') div 100) <> 2 then
      exit;
    FromFTP.ParseRemote(FromFTP.resultString);
    s := ReplaceString(FromFTP.DataIP, '.', ',');
    s := 'PORT ' + s + ',' + intToStr(strToIntDef(FromFTP.DataPort, 0) div 256)
      + ',' + intToStr(strToIntDef(FromFTP.DataPort, 0) mod 256);
    if (ToFTP.FTPCommand(s) div 100) <> 2 then
      exit;
    x := ToFTP.FTPCommand('RETR ' + FromFile);
    if (x div 100) <> 1 then
      exit;
    x := FromFTP.FTPCommand('STOR ' + ToFile);
    if (x div 100) <> 1 then
      exit;
    FromFTP.Timeout := 21600000;
    x := FromFTP.ReadResult;
    if (x  div 100) <> 2 then
      exit;
    ToFTP.Timeout := 21600000;
    x := ToFTP.ReadResult;
    if (x div 100) <> 2 then
      exit;
    result := true;
  finally
    ToFTP.free;
    FromFTP.free;
  end;
end;

end.
