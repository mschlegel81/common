{==============================================================================|
| project : Ararat Synapse                                       | 001.000.006 |
|==============================================================================|
| content: SSL support by StreamSecII                                          |
|==============================================================================|
| Copyright (c)1999-2005, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2005.                     |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Henrick Hellström <henrick@streamsec.SE>                                   |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(SSL plugin for StreamSecII or OpenStreamSecII)

StreamSecII is native pascal library, you not need any external libraries!

You can tune lot of StreamSecII properties by using your GlobalServer. if you not
using your GlobalServer, then this plugin create own TSimpleTLSInternalServer
instance for each TCP connection. Formore information about GlobalServer usage
refer StreamSecII documentation.

if you are not using key and certificate by GlobalServer, then you can use
properties of this plugin instead, but this have limited features and
@link(TCustomSSL.KeyPassword) not working properly yet!

for handling keys and certificates you can use this properties:
@link(TCustomSSL.CertCAFile), @link(TCustomSSL.CertCA),
@link(TCustomSSL.TrustCertificateFile), @link(TCustomSSL.TrustCertificate),
@link(TCustomSSL.PrivateKeyFile), @link(TCustomSSL.PrivateKey),
@link(TCustomSSL.CertificateFile), @link(TCustomSSL.Certificate),
@link(TCustomSSL.PFXFile). for usage of this properties and for possible formats
of keys and certificates refer to StreamSecII documentation.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

UNIT ssl_streamsec;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synsock, synautil, synacode,
  TlsInternalServer, TlsSynaSock, TlsConst, StreamSecII, Asn1, X509Base,
  SecUtils;

TYPE
  {:@exclude}
  TMyTLSSynSockSlave = class(TTLSSynSockSlave)
  protected
    PROCEDURE SetMyTLSServer(CONST value: TCustomTLSInternalServer);
    FUNCTION GetMyTLSServer: TCustomTLSInternalServer;
  Published
    PROPERTY MyTLSServer: TCustomTLSInternalServer read GetMyTLSServer write SetMyTLSServer;
  end;

  {:@abstract(class implementing StreamSecII SSL plugin.)
   instance of this class will be created for each @link(TTCPBlockSocket).
   You not need to create instance of this class, all is done by Synapse itself!}
  TSSLStreamSec = class(TCustomSSL)
  protected
    FSlave: TMyTLSSynSockSlave;
    FIsServer: boolean;
    FTLSServer: TCustomTLSInternalServer;
    FServerCreated: boolean;
    FUNCTION SSLCheck: boolean;
    FUNCTION init(Server:boolean): boolean;
    FUNCTION DeInit: boolean;
    FUNCTION Prepare(Server:boolean): boolean;
    PROCEDURE NotTrustEvent(Sender: TObject; Cert: TASN1Struct; VAR ExplicitTrust: boolean);
    FUNCTION X500StrToStr(CONST prefix: string; CONST value: TX500String): string;
    FUNCTION X501NameToStr(CONST value: TX501Name): string;
    FUNCTION GetCert: PASN1Struct;
  public
    CONSTRUCTOR create(CONST value: TTCPBlockSocket); override;
    DESTRUCTOR destroy; override;
    {:See @inherited}
    FUNCTION LibVersion: string; override;
    {:See @inherited}
    FUNCTION LibName: string; override;
    {:See @inherited and @link(ssl_streamsec) for more details.}
    FUNCTION Connect: boolean; override;
    {:See @inherited and @link(ssl_streamsec) for more details.}
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
    FUNCTION GetCertInfo: string; override;
  Published
    {:TLS server for tuning of StreamSecII.}
    PROPERTY TLSServer: TCustomTLSInternalServer read FTLSServer write FTLSServer;
  end;

IMPLEMENTATION

{==============================================================================}
PROCEDURE TMyTLSSynSockSlave.SetMyTLSServer(CONST value: TCustomTLSInternalServer);
begin
  TLSServer := value;
end;

FUNCTION TMyTLSSynSockSlave.GetMyTLSServer: TCustomTLSInternalServer;
begin
  result := TLSServer;
end;

{==============================================================================}

CONSTRUCTOR TSSLStreamSec.create(CONST value: TTCPBlockSocket);
begin
  inherited create(value);
  FSlave := nil;
  FIsServer := false;
  FTLSServer := nil;
end;

DESTRUCTOR TSSLStreamSec.destroy;
begin
  DeInit;
  inherited destroy;
end;

FUNCTION TSSLStreamSec.LibVersion: string;
begin
  result := 'StreamSecII';
end;

FUNCTION TSSLStreamSec.LibName: string;
begin
  result := 'ssl_streamsec';
end;

FUNCTION TSSLStreamSec.SSLCheck: boolean;
begin
  result := true;
  FLastErrorDesc := '';
  if not Assigned(FSlave) then
    exit;
  FLastError := FSlave.ErrorCode;
  if FLastError <> 0 then
  begin
    FLastErrorDesc := TlsConst.AlertMsg(FLastError);
  end;
end;

PROCEDURE TSSLStreamSec.NotTrustEvent(Sender: TObject; Cert: TASN1Struct; VAR ExplicitTrust: boolean);
begin
  ExplicitTrust := true;
end;

FUNCTION TSSLStreamSec.init(Server:boolean): boolean;
VAR
  st: TMemoryStream;
  pass: ISecretKey;
  ws: WideString;
begin
  result := false;
  ws := FKeyPassword;
  pass := TSecretKey.CreateBmpStr(PWideChar(ws), length(ws));
  try
    FIsServer := Server;
    FSlave := TMyTLSSynSockSlave.CreateSocket(FSocket.Socket);
    if Assigned(FTLSServer) then
      FSlave.MyTLSServer := FTLSServer
    else
      if Assigned(TLSInternalServer.GlobalServer) then
        FSlave.MyTLSServer := TLSInternalServer.GlobalServer
      else begin
        FSlave.MyTLSServer := TSimpleTLSInternalServer.create(nil);
        FServerCreated := true;
      end;
    if Server then
      FSlave.MyTLSServer.ClientOrServer := cosServerSide
    else
      FSlave.MyTLSServer.ClientOrServer := cosClientSide;
    if not FVerifyCert then
    begin
      FSlave.MyTLSServer.OnCertNotTrusted := NotTrustEvent;
    end;
    FSlave.MyTLSServer.options.VerifyServerName := [];
    FSlave.MyTLSServer.options.Export40Bit := prAllowed;
    FSlave.MyTLSServer.options.Export56Bit := prAllowed;
    FSlave.MyTLSServer.options.RequestClientCertificate := false;
    FSlave.MyTLSServer.options.RequireClientCertificate := false;
    if Server and FVerifyCert then
    begin
      FSlave.MyTLSServer.options.RequestClientCertificate := true;
      FSlave.MyTLSServer.options.RequireClientCertificate := true;
    end;
    if FCertCAFile <> '' then
      FSlave.MyTLSServer.LoadRootCertsFromFile(CertCAFile);
    if FCertCA <> '' then
    begin
      st := TMemoryStream.create;
      try
        WriteStrToStream(st, FCertCA);
        st.Seek(0, soFromBeginning);
        FSlave.MyTLSServer.LoadRootCertsFromStream(st);
      finally
        st.free;
      end;
    end;
    if FTrustCertificateFile <> '' then
      FSlave.MyTLSServer.LoadTrustedCertsFromFile(FTrustCertificateFile);
    if FTrustCertificate <> '' then
    begin
      st := TMemoryStream.create;
      try
        WriteStrToStream(st, FTrustCertificate);
        st.Seek(0, soFromBeginning);
        FSlave.MyTLSServer.LoadTrustedCertsFromStream(st);
      finally
        st.free;
      end;
    end;
    if FPrivateKeyFile <> '' then
      FSlave.MyTLSServer.LoadPrivateKeyRingFromFile(FPrivateKeyFile, pass);
//      FSlave.MyTLSServer.PrivateKeyRing.LoadPrivateKeyFromFile(FPrivateKeyFile, pass);
    if FPrivateKey <> '' then
    begin
      st := TMemoryStream.create;
      try
        WriteStrToStream(st, FPrivateKey);
        st.Seek(0, soFromBeginning);
        FSlave.MyTLSServer.LoadPrivateKeyRingFromStream(st, pass);
      finally
        st.free;
      end;
    end;
    if FCertificateFile <> '' then
      FSlave.MyTLSServer.LoadMyCertsFromFile(FCertificateFile);
    if FCertificate <> '' then
    begin
      st := TMemoryStream.create;
      try
        WriteStrToStream(st, FCertificate);
        st.Seek(0, soFromBeginning);
        FSlave.MyTLSServer.LoadMyCertsFromStream(st);
      finally
        st.free;
      end;
    end;
    if FPFXfile <> '' then
      FSlave.MyTLSServer.ImportFromPFX(FPFXfile, pass);
    if Server and FServerCreated then
    begin
      FSlave.MyTLSServer.options.BulkCipherAES128 := prPrefer;
      FSlave.MyTLSServer.options.BulkCipherAES256 := prAllowed;
      FSlave.MyTLSServer.options.EphemeralECDHKeySize := ecs256;
      FSlave.MyTLSServer.options.SignatureRSA := prPrefer;
      FSlave.MyTLSServer.options.KeyAgreementRSA := prAllowed;
      FSlave.MyTLSServer.options.KeyAgreementECDHE := prAllowed;
      FSlave.MyTLSServer.options.KeyAgreementDHE := prPrefer;
      FSlave.MyTLSServer.TLSSetupServer;
    end;
    result := true;
  finally
    pass := nil;
  end;
end;

FUNCTION TSSLStreamSec.DeInit: boolean;
VAR
  obj: TObject;
begin
  result := true;
  if assigned(FSlave) then
  begin
    FSlave.close;
    if FServerCreated then
      obj := FSlave.TLSServer
    else
      obj := nil;
    FSlave.free;
    obj.free;
    FSlave := nil;
  end;
  FSSLEnabled := false;
end;

FUNCTION TSSLStreamSec.Prepare(Server:boolean): boolean;
begin
  result := false;
  DeInit;
  if init(Server) then
    result := true
  else
    DeInit;
end;

FUNCTION TSSLStreamSec.Connect: boolean;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(false) then
  begin
    FSlave.Open;
    SSLCheck;
    if FLastError <> 0 then
      exit;
    FSSLEnabled := true;
    result := true;
  end;
end;

FUNCTION TSSLStreamSec.accept: boolean;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(true) then
  begin
    FSlave.DoConnect;
    SSLCheck;
    if FLastError <> 0 then
      exit;
    FSSLEnabled := true;
    result := true;
  end;
end;

FUNCTION TSSLStreamSec.Shutdown: boolean;
begin
  result := BiShutdown;
end;

FUNCTION TSSLStreamSec.BiShutdown: boolean;
begin
  DeInit;
  result := true;
end;

FUNCTION TSSLStreamSec.SendBuffer(buffer: TMemory; len: integer): integer;
VAR
  l: integer;
begin
  l := len;
  FSlave.SendBuf(buffer^, l, true);
  result := l;
  SSLCheck;
end;

FUNCTION TSSLStreamSec.RecvBuffer(buffer: TMemory; len: integer): integer;
VAR
  l: integer;
begin
  l := len;
  result := FSlave.ReceiveBuf(buffer^, l);
  SSLCheck;
end;

FUNCTION TSSLStreamSec.WaitingData: integer;
begin
  result := 0;
  while FSlave.Connected do begin
    result := FSlave.ReceiveLength;
    if result > 0 then
      break;
    sleep(1);
  end;
end;

FUNCTION TSSLStreamSec.GetSSLVersion: string;
begin
  result := 'SSLv3 or TLSv1';
end;

FUNCTION TSSLStreamSec.GetCert: PASN1Struct;
begin
  if FIsServer then
    result := FSlave.GetClientCert
  else
    result := FSlave.GetServerCert;
end;

FUNCTION TSSLStreamSec.GetPeerSubject: string;
VAR
  XName: TX501Name;
  Cert: PASN1Struct;
begin
  result := '';
  Cert := GetCert;
  if Assigned(cert) then
  begin
    ExtractSubject(Cert^,XName, false);
    result := X501NameToStr(XName);
  end;
end;

FUNCTION TSSLStreamSec.GetPeerName: string;
VAR
  XName: TX501Name;
  Cert: PASN1Struct;
begin
  result := '';
  Cert := GetCert;
  if Assigned(cert) then
  begin
    ExtractSubject(Cert^,XName, false);
    result := XName.commonName.Str;
  end;
end;

FUNCTION TSSLStreamSec.GetPeerIssuer: string;
VAR
  XName: TX501Name;
  Cert: PASN1Struct;
begin
  result := '';
  Cert := GetCert;
  if Assigned(cert) then
  begin
    ExtractIssuer(Cert^, XName, false);
    result := X501NameToStr(XName);
  end;
end;

FUNCTION TSSLStreamSec.GetPeerFingerprint: string;
VAR
  Cert: PASN1Struct;
begin
  result := '';
  Cert := GetCert;
  if Assigned(cert) then
    result := MD5(Cert.ContentAsOctetString);
end;

FUNCTION TSSLStreamSec.GetCertInfo: string;
VAR
  Cert: PASN1Struct;
  l: TStringList;
begin
  result := '';
  Cert := GetCert;
  if Assigned(cert) then
  begin
    l := TStringList.create;
    try
      Asn1.RenderAsText(cert^, l, true, true, true, 2);
      result := l.text;
    finally
      l.free;
    end;
  end;
end;

FUNCTION TSSLStreamSec.X500StrToStr(CONST prefix: string;
  CONST value: TX500String): string;
begin
  if value.Str = '' then
    result := ''
  else
    result := '/' + prefix + '=' + value.Str;
end;

FUNCTION TSSLStreamSec.X501NameToStr(CONST value: TX501Name): string;
begin
  result := X500StrToStr('CN',value.commonName) +
           X500StrToStr('C',value.countryName) +
           X500StrToStr('L',value.localityName) +
           X500StrToStr('ST',value.stateOrProvinceName) +
           X500StrToStr('O',value.organizationName) +
           X500StrToStr('OU',value.organizationalUnitName) +
           X500StrToStr('T',value.title) +
           X500StrToStr('N',value.name) +
           X500StrToStr('G',value.givenName) +
           X500StrToStr('I',value.initials) +
           X500StrToStr('SN',value.surname) +
           X500StrToStr('GQ',value.generationQualifier) +
           X500StrToStr('DNQ',value.dnQualifier) +
           X500StrToStr('E',value.emailAddress);
end;


{==============================================================================}

INITIALIZATION
  SSLImplementation := TSSLStreamSec;

FINALIZATION

end.


