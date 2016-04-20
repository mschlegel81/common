{==============================================================================|
| project : Ararat Synapse                                       | 001.001.000 |
|==============================================================================|
| content: SSL/SSH support by Peter Gutmann's CryptLib                         |
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
| Portions created by Lukas Gebauer are Copyright (c)2005-2012.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(SSL/SSH plugin for CryptLib)

This plugin requires cl32.dll at least version 3.2.0! it can be used on Win32
and Linux. This library is staticly linked - when you compile your application
with this plugin, you MUST distribute it with Cryptib library, otherwise you
cannot run your application!

it can work with keys and certificates stored as PKCS#15 only! it must be stored
as disk file only, you cannot load them from memory! Each file can hold multiple
keys and certificates. You must identify it by 'label' stored in
@link(TSSLCryptLib.PrivateKeyLabel).

if you need to use secure connection and authorize self by certificate
(each SSL/TLS Server or Client with Client authorization), then use
@link(TCustomSSL.PrivateKeyFile), @link(TSSLCryptLib.PrivateKeyLabel) and
@link(TCustomSSL.KeyPassword) properties.

if you need to use Server what verifying Client certificates, then use
@link(TCustomSSL.CertCAFile) as PKCS#15 file with public keyas of allowed clients. Clients
with non-matching certificates will be rejected by cryptLib.

This plugin is capable to create ad-Hoc certificates. When you start SSL/TLS
Server without explicitly assigned key and certificate, then this plugin create
ad-Hoc key and certificate for each incomming connection by self. it slowdown
accepting of new connections!

You can use this plugin for SSHv2 connections too! You must explicitly set
@link(TCustomSSL.SSLType) to value LT_SSHv2 and set @link(TCustomSSL.username)
and @link(TCustomSSL.password). You can use special SSH channels too, see
@link(TCustomSSL).
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

UNIT ssl_cryptlib;

INTERFACE

USES
  windows,
  sysutils,
  blcksock, synsock, synautil, synacode,
  cryptlib;

TYPE
  {:@abstract(class implementing CryptLib SSL/SSH plugin.)
   instance of this class will be created for each @link(TTCPBlockSocket).
   You not need to create instance of this class, all is done by Synapse itself!}
  TSSLCryptLib = class(TCustomSSL)
  protected
    FCryptSession: CRYPT_SESSION;
    FPrivateKeyLabel: string;
    FDelCert: boolean;
    FReadBuffer: string;
    FTrustedCAs: array of integer;
    FUNCTION SSLCheck(value: integer): boolean;
    FUNCTION init(Server:boolean): boolean;
    FUNCTION DeInit: boolean;
    FUNCTION Prepare(Server:boolean): boolean;
    FUNCTION GetString(CONST cryptHandle: CRYPT_HANDLE; CONST attributeType: CRYPT_ATTRIBUTE_TYPE): string;
    FUNCTION CreateSelfSignedCert(Host: string): boolean; override;
    FUNCTION PopAll: string;
  public
    {:See @inherited}
    CONSTRUCTOR create(CONST value: TTCPBlockSocket); override;
    DESTRUCTOR destroy; override;
    {:Load trusted CA's in PEM format}
    PROCEDURE SetCertCAFile(CONST value: string); override;
    {:See @inherited}
    FUNCTION LibVersion: string; override;
    {:See @inherited}
    FUNCTION LibName: string; override;
    {:See @inherited}
    PROCEDURE assign(CONST value: TCustomSSL); override;
    {:See @inherited and @link(ssl_cryptlib) for more details.}
    FUNCTION Connect: boolean; override;
    {:See @inherited and @link(ssl_cryptlib) for more details.}
    FUNCTION accept: boolean; override;
    {:See @inherited}
    FUNCTION Shutdown: boolean; override;
    {:See @inherited}
    FUNCTION BiShutdown: boolean; override;
    {:See @inherited}
    FUNCTION SendBuffer(buffer: TMemory; len: integer): integer; override;
    {:See @inherited}
    FUNCTION RecvBuffer(buffer: TMemory; len: integer): integer; override;
    {:See @inherited}
    FUNCTION WaitingData: integer; override;
    {:See @inherited}
    FUNCTION GetSSLVersion: string; override;
    {:See @inherited}
    FUNCTION GetPeerSubject: string; override;
    {:See @inherited}
    FUNCTION GetPeerIssuer: string; override;
    {:See @inherited}
    FUNCTION GetPeerName: string; override;
    {:See @inherited}
    FUNCTION GetPeerFingerprint: string; override;
    {:See @inherited}
    FUNCTION GetVerifyCert: integer; override;
  Published
    {:name of certificate/key within PKCS#15 file. It can hold more then one
     certificate/key and each certificate/key must have unique label within one file.}
    PROPERTY PrivateKeyLabel: string read FPrivateKeyLabel write FPrivateKeyLabel;
  end;

IMPLEMENTATION

{==============================================================================}

CONSTRUCTOR TSSLCryptLib.create(CONST value: TTCPBlockSocket);
begin
  inherited create(value);
  FcryptSession := CRYPT_SESSION(CRYPT_SESSION_NONE);
  FPrivateKeyLabel := 'synapse';
  FDelCert := false;
  FTrustedCAs := nil;
end;

DESTRUCTOR TSSLCryptLib.destroy;
begin
  SetCertCAFile('');  // destroy certificates
  DeInit;
  inherited destroy;
end;

PROCEDURE TSSLCryptLib.assign(CONST value: TCustomSSL);
begin
  inherited assign(value);
  if value is TSSLCryptLib then
  begin
    FPrivateKeyLabel := TSSLCryptLib(value).privatekeyLabel;
  end;
end;

FUNCTION TSSLCryptLib.GetString(CONST cryptHandle: CRYPT_HANDLE; CONST attributeType: CRYPT_ATTRIBUTE_TYPE): string;
VAR
  l: integer;
begin
  l := 0;
  cryptGetAttributeString(cryptHandle, attributeType, nil, l);
  setLength(result, l);
  cryptGetAttributeString(cryptHandle, attributeType, pointer(result), l);
  setLength(result, l);
end;

FUNCTION TSSLCryptLib.LibVersion: string;
VAR
  x: integer;
begin
  result := GetString(CRYPT_UNUSED, CRYPT_OPTION_INFO_DESCRIPTION);
  cryptGetAttribute(CRYPT_UNUSED, CRYPT_OPTION_INFO_MAJORVERSION, x);
  result := result + ' v' + intToStr(x);
  cryptGetAttribute(CRYPT_UNUSED, CRYPT_OPTION_INFO_MINORVERSION, x);
  result := result + '.' + intToStr(x);
  cryptGetAttribute(CRYPT_UNUSED, CRYPT_OPTION_INFO_STEPPING, x);
  result := result + '.' + intToStr(x);
end;

FUNCTION TSSLCryptLib.LibName: string;
begin
  result := 'ssl_cryptlib';
end;

FUNCTION TSSLCryptLib.SSLCheck(value: integer): boolean;
begin
  result := true;
  FLastErrorDesc := '';
  if value = CRYPT_ERROR_COMPLETE then
    value := 0;
  FLastError := value;
  if FLastError <> 0 then
  begin
    result := false;
{$IF CRYPTLIB_VERSION >= 3400}
    FLastErrorDesc := GetString(FCryptSession, CRYPT_ATTRIBUTE_ERRORMESSAGE);
{$ELSE}
    FLastErrorDesc := GetString(FCryptSession, CRYPT_ATTRIBUTE_INT_ERRORMESSAGE);
{$IFEND}
  end;
end;

FUNCTION TSSLCryptLib.CreateSelfSignedCert(Host: string): boolean;
VAR
  privateKey: CRYPT_CONTEXT;
  keySet: CRYPT_KEYSET;
  cert: CRYPT_CERTIFICATE;
  publicKey: CRYPT_CONTEXT;
begin
  if FPrivatekeyFile = '' then
    FPrivatekeyFile := GetTempFile('', 'key');
  cryptCreateContext(privateKey, CRYPT_UNUSED, CRYPT_ALGO_RSA);
  cryptSetAttributeString(privateKey, CRYPT_CTXINFO_LABEL, pointer(FPrivatekeyLabel),
    length(FPrivatekeyLabel));
  cryptSetAttribute(privateKey, CRYPT_CTXINFO_KEYSIZE, 1024);
  cryptGenerateKey(privateKey);
  cryptKeysetOpen(keySet, CRYPT_UNUSED, CRYPT_KEYSET_FILE, PChar(FPrivatekeyFile), CRYPT_KEYOPT_CREATE);
  FDelCert := true;
  cryptAddPrivateKey(keySet, privateKey, PChar(FKeyPassword));
  cryptCreateCert(cert, CRYPT_UNUSED, CRYPT_CERTTYPE_CERTIFICATE);
  cryptSetAttribute(cert, CRYPT_CERTINFO_XYZZY, 1);
  cryptGetPublicKey(keySet, publicKey, CRYPT_KEYID_NAME, PChar(FPrivatekeyLabel));
  cryptSetAttribute(cert, CRYPT_CERTINFO_SUBJECTPUBLICKEYINFO, publicKey);
  cryptSetAttributeString(cert, CRYPT_CERTINFO_COMMONNAME, pointer(host), length(host));
  cryptSignCert(cert, privateKey);
  cryptAddPublicKey(keySet, cert);
  cryptKeysetClose(keySet);
  cryptDestroyCert(cert);
  cryptDestroyContext(privateKey);
  cryptDestroyContext(publicKey);
  result := true;
end;

FUNCTION TSSLCryptLib.PopAll: string;
CONST
  BufferMaxSize = 32768;
VAR
  Outbuffer: string;
  WriteLen: integer;
begin
  result := '';
  repeat
    setLength(outbuffer, BufferMaxSize);
    Writelen := 0;
    SSLCheck(CryptPopData(FCryptSession, @OutBuffer[1], BufferMaxSize, Writelen));
    if FLastError <> 0 then
      break;
    if WriteLen > 0 then
    begin
      setLength(outbuffer, WriteLen);
      result := result + outbuffer;
    end;
  until WriteLen = 0;
end;

FUNCTION TSSLCryptLib.init(Server:boolean): boolean;
VAR
  st: CRYPT_SESSION_TYPE;
  keysetobj: CRYPT_KEYSET;
  cryptContext: CRYPT_CONTEXT;
  x: integer;
begin
  result := false;
  FLastErrorDesc := '';
  FLastError := 0;
  FDelCert := false;
  FcryptSession := CRYPT_SESSION(CRYPT_SESSION_NONE);
  if Server then
    case FSSLType of
      LT_all, LT_SSLv3, LT_TLSv1, LT_TLSv1_1:
        st := CRYPT_SESSION_SSL_SERVER;
      LT_SSHv2:
        st := CRYPT_SESSION_SSH_SERVER;
    else
      exit;
    end
  else
    case FSSLType of
      LT_all, LT_SSLv3, LT_TLSv1, LT_TLSv1_1:
        st := CRYPT_SESSION_SSL;
      LT_SSHv2:
        st := CRYPT_SESSION_SSH;
    else
      exit;
    end;
  if not SSLCheck(cryptCreateSession(FcryptSession, CRYPT_UNUSED, st)) then
    exit;
  x := -1;
  case FSSLType of
    LT_SSLv3:
      x := 0;
    LT_TLSv1:
      x := 1;
    LT_TLSv1_1:
      x := 2;
  end;
  if x >= 0 then
    if not SSLCheck(cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_VERSION, x)) then
      exit;

  if (FCertComplianceLevel <> -1) then
    if not SSLCheck(cryptSetAttribute (CRYPT_UNUSED, CRYPT_OPTION_CERT_COMPLIANCELEVEL,
      FCertComplianceLevel)) then
      exit;

  if FUsername <> '' then
  begin
    cryptSetAttributeString(FcryptSession, CRYPT_SESSINFO_USERNAME,
      pointer(FUsername), length(FUsername));
    cryptSetAttributeString(FcryptSession, CRYPT_SESSINFO_PASSWORD,
      pointer(FPassword), length(FPassword));
  end;
  if FSSLType = LT_SSHv2 then
    if FSSHChannelType <> '' then
    begin
      cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_SSH_CHANNEL, CRYPT_UNUSED);
      cryptSetAttributeString(FCryptSession, CRYPT_SESSINFO_SSH_CHANNEL_TYPE,
        pointer(FSSHChannelType), length(FSSHChannelType));
      if FSSHChannelArg1 <> '' then
        cryptSetAttributeString(FCryptSession, CRYPT_SESSINFO_SSH_CHANNEL_ARG1,
          pointer(FSSHChannelArg1), length(FSSHChannelArg1));
      if FSSHChannelArg2 <> '' then
        cryptSetAttributeString(FCryptSession, CRYPT_SESSINFO_SSH_CHANNEL_ARG2,
          pointer(FSSHChannelArg2), length(FSSHChannelArg2));
    end;


  if Server and (FPrivatekeyFile = '') then
  begin
    if FPrivatekeyLabel = '' then
      FPrivatekeyLabel := 'synapse';
    if FkeyPassword = '' then
      FkeyPassword := 'synapse';
    CreateSelfSignedcert(FSocket.ResolveIPToName(FSocket.GetRemoteSinIP));
  end;

  if (FPrivatekeyLabel <> '') and (FPrivatekeyFile <> '') then
  begin
    if not SSLCheck(cryptKeysetOpen(KeySetObj, CRYPT_UNUSED, CRYPT_KEYSET_FILE,
      PChar(FPrivatekeyFile), CRYPT_KEYOPT_READONLY)) then
      exit;
    try
    if not SSLCheck(cryptGetPrivateKey(KeySetObj, cryptcontext, CRYPT_KEYID_NAME,
      PChar(FPrivatekeyLabel), PChar(FKeyPassword))) then
      exit;
    if not SSLCheck(cryptSetAttribute(FcryptSession, CRYPT_SESSINFO_PRIVATEKEY,
      cryptcontext)) then
      exit;
    finally
      cryptKeysetClose(keySetObj);
      cryptDestroyContext(cryptcontext);
    end;
  end;
  if Server and FVerifyCert then
  begin
    if not SSLCheck(cryptKeysetOpen(KeySetObj, CRYPT_UNUSED, CRYPT_KEYSET_FILE,
      PChar(FCertCAFile), CRYPT_KEYOPT_READONLY)) then
      exit;
    try
    if not SSLCheck(cryptSetAttribute(FcryptSession, CRYPT_SESSINFO_KEYSET,
      keySetObj)) then
      exit;
    finally
      cryptKeysetClose(keySetObj);
    end;
  end;
  result := true;
end;

FUNCTION TSSLCryptLib.DeInit: boolean;
begin
  result := true;
  if FcryptSession <> CRYPT_SESSION(CRYPT_SESSION_NONE) then
    CryptDestroySession(FcryptSession);
  FcryptSession := CRYPT_SESSION(CRYPT_SESSION_NONE);
  FSSLEnabled := false;
  if FDelCert then
    sysutils.DeleteFile(FPrivatekeyFile);
end;

FUNCTION TSSLCryptLib.Prepare(Server:boolean): boolean;
begin
  result := false;
  DeInit;
  if init(Server) then
    result := true
  else
    DeInit;
end;

FUNCTION TSSLCryptLib.Connect: boolean;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(false) then
  begin
    if not SSLCheck(cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_NETWORKSOCKET, FSocket.Socket)) then
      exit;
    if not SSLCheck(cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_ACTIVE, 1)) then
      exit;
    if FverifyCert then
      if (GetVerifyCert <> 0) or (not DoVerifyCert) then
        exit;
    FSSLEnabled := true;
    result := true;
    FReadBuffer := '';
  end;
end;

FUNCTION TSSLCryptLib.accept: boolean;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(true) then
  begin
    if not SSLCheck(cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_NETWORKSOCKET, FSocket.Socket)) then
      exit;
    if not SSLCheck(cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_ACTIVE, 1)) then
      exit;
    FSSLEnabled := true;
    result := true;
    FReadBuffer := '';
  end;
end;

FUNCTION TSSLCryptLib.Shutdown: boolean;
begin
  result := BiShutdown;
end;

FUNCTION TSSLCryptLib.BiShutdown: boolean;
begin
  if FcryptSession <> CRYPT_SESSION(CRYPT_SESSION_NONE) then
    cryptSetAttribute(FCryptSession, CRYPT_SESSINFO_ACTIVE, 0);
  DeInit;
  FReadBuffer := '';
  result := true;
end;

FUNCTION TSSLCryptLib.SendBuffer(buffer: TMemory; len: integer): integer;
VAR
  l: integer;
begin
  FLastError := 0;
  FLastErrorDesc := '';
  SSLCheck(cryptPushData(FCryptSession, buffer, len, L));
  cryptFlushData(FcryptSession);
  result := l;
end;

FUNCTION TSSLCryptLib.RecvBuffer(buffer: TMemory; len: integer): integer;
begin
  FLastError := 0;
  FLastErrorDesc := '';
  if length(FReadBuffer) = 0 then
    FReadBuffer := PopAll;
  if len > length(FReadBuffer) then
    len := length(FReadBuffer);
  move(pointer(FReadBuffer)^, buffer^, len);
  Delete(FReadBuffer, 1, len);
  result := len;
end;

FUNCTION TSSLCryptLib.WaitingData: integer;
begin
  result := length(FReadBuffer);
end;

FUNCTION TSSLCryptLib.GetSSLVersion: string;
VAR
  x: integer;
begin
  result := '';
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_VERSION, x);
  if FSSLType in [LT_SSLv3, LT_TLSv1, LT_TLSv1_1, LT_all] then
    case x of
      0:
        result := 'SSLv3';
      1:
        result := 'TLSv1';
      2:
        result := 'TLSv1.1';
    end;
  if FSSLType in [LT_SSHv2] then
    case x of
      0:
        result := 'SSHv1';
      1:
        result := 'SSHv2';
    end;
end;

FUNCTION TSSLCryptLib.GetPeerSubject: string;
VAR
  cert: CRYPT_CERTIFICATE;
begin
  result := '';
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_RESPONSE, cert);
  cryptSetAttribute(cert, CRYPT_ATTRIBUTE_CURRENT, CRYPT_CERTINFO_SUBJECTNAME);
  result := GetString(cert, CRYPT_CERTINFO_DN);
  cryptDestroyCert(cert);
end;

FUNCTION TSSLCryptLib.GetPeerName: string;
VAR
  cert: CRYPT_CERTIFICATE;
begin
  result := '';
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_RESPONSE, cert);
  cryptSetAttribute(cert, CRYPT_ATTRIBUTE_CURRENT, CRYPT_CERTINFO_SUBJECTNAME);
  result := GetString(cert, CRYPT_CERTINFO_COMMONNAME);
  cryptDestroyCert(cert);
end;

FUNCTION TSSLCryptLib.GetPeerIssuer: string;
VAR
  cert: CRYPT_CERTIFICATE;
begin
  result := '';
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_RESPONSE, cert);
  cryptSetAttribute(cert, CRYPT_ATTRIBUTE_CURRENT, CRYPT_CERTINFO_ISSUERNAME);
  result := GetString(cert, CRYPT_CERTINFO_COMMONNAME);
  cryptDestroyCert(cert);
end;

FUNCTION TSSLCryptLib.GetPeerFingerprint: string;
VAR
  cert: CRYPT_CERTIFICATE;
begin
  result := '';
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_RESPONSE, cert);
  result := GetString(cert, CRYPT_CERTINFO_FINGERPRINT);
  cryptDestroyCert(cert);
end;


PROCEDURE TSSLCryptLib.SetCertCAFile(CONST value: string);

VAR F:textFile;
  bInCert:boolean;
  s,sCert:string;
  cert: CRYPT_CERTIFICATE;
  idx:integer;

begin
if assigned(FTrustedCAs) then
  begin
  for idx := 0 to high(FTrustedCAs) do
    cryptDestroyCert(FTrustedCAs[idx]);
  FTrustedCAs:=nil;
  end;
if value<>'' then
  begin
  AssignFile(F,value);
  reset(F);
  bInCert:=false;
  idx:=0;
  while not eof(F) do
    begin
    readln(F,s);
    if pos('-----END CERTIFICATE-----',s)>0 then
      begin
      bInCert:=false;
      cert:=0;
      if (cryptImportCert(PAnsiChar(sCert),length(sCert)-2,CRYPT_UNUSED,cert)=CRYPT_OK) then
        begin
        cryptSetAttribute( cert, CRYPT_CERTINFO_TRUSTED_IMPLICIT, 1 );
        setLength(FTrustedCAs,idx+1);
        FTrustedCAs[idx]:=cert;
        idx:=idx+1;
        end;
      end;
    if bInCert then
      sCert:=sCert+s+#13#10;
    if pos('-----BEGIN CERTIFICATE-----',s)>0 then
      begin
      bInCert:=true;
      sCert:='';
      end;
    end;
  CloseFile(F);
  end;
end;

FUNCTION TSSLCryptLib.GetVerifyCert: integer;
VAR
  cert: CRYPT_CERTIFICATE;
  itype,ilocus:integer;
begin
  result := -1;
  if FcryptSession = CRYPT_SESSION(CRYPT_SESSION_NONE) then
    exit;
  cryptGetAttribute(FCryptSession, CRYPT_SESSINFO_RESPONSE, cert);
  result:=cryptCheckCert(cert,CRYPT_UNUSED);
  if result<>CRYPT_OK then
    begin
    //get extended error info if available
    cryptGetAttribute(cert,CRYPT_ATTRIBUTE_ERRORtype,itype);
    cryptGetAttribute(cert,CRYPT_ATTRIBUTE_ERRORLOCUS,ilocus);
    cryptSetAttribute(cert, CRYPT_ATTRIBUTE_CURRENT, CRYPT_CERTINFO_SUBJECTNAME);
    FLastError := result;
    FLastErrorDesc := format('SSL/TLS certificate verification failed for "%s"'#13#10'Status: %d. ERRORTYPE: %d. ERRORLOCUS: %d.',
      [GetString(cert, CRYPT_CERTINFO_COMMONNAME),result,itype,ilocus]);
    end;
  cryptDestroyCert(cert);
end;

{==============================================================================}

VAR imajor,iminor,iver:integer;
//    e: ESynapseError;

INITIALIZATION
  if cryptInit = CRYPT_OK then
    SSLImplementation := TSSLCryptLib;
  cryptAddRandom(nil, CRYPT_RANDOM_SLOWPOLL);
  cryptGetAttribute (CRYPT_UNUSED, CRYPT_OPTION_INFO_MAJORVERSION,imajor);
  cryptGetAttribute (CRYPT_UNUSED, CRYPT_OPTION_INFO_MINORVERSION,iminor);
// according to the documentation CRYPTLIB version has 3 digits. recent versions use 4 digits
  if CRYPTLIB_VERSION >1000 then
    iver:=CRYPTLIB_VERSION div 100
  else
    iver:=CRYPTLIB_VERSION div 10;
  if (iver <> imajor*10+iminor) then
  begin
    SSLImplementation :=TSSLNone;
//    e := ESynapseError.Create(format('Error wrong cryptlib version (is %d.%d expected %d.%d). ',
//       [imajor,iminor,iver div 10, iver mod 10]));
//    e.ErrorCode := 0;
//    e.ErrorMessage := format('Error wrong cryptlib version (%d.%d expected %d.%d)',
//       [imajor,iminor,iver div 10, iver mod 10]);
//    raise e;
  end;
FINALIZATION
  cryptEnd;
end.


