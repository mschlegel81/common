{==============================================================================|
| project : Ararat Synapse                                       | 001.002.000 |
|==============================================================================|
| content: SSL support by OpenSSL                                              |
|==============================================================================|
| Copyright (c)1999-2008, Lukas Gebauer                                        |
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
| Portions created by Petr Fejfar are Copyright (c)2011-2012.                  |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

//requires OpenSSL libraries!

{:@abstract(SSL plugin for OpenSSL)

You need OpenSSL libraries version 0.9.7. it can work with 0.9.6 too, but
application mysteriously crashing when you are using freePascal on Linux.
use Kylix on Linux is ok! if you have version 0.9.7 on Linux, then I not see
any problems with FreePascal.

OpenSSL libraries are loaded dynamicly - you not need OpenSSl librares even you
compile your application with this UNIT. SSL just not working when you not have
OpenSSL libraries.

This plugin have limited support for .NET too! Because is not possible to use
callbacks with CDECL calling convention under .NET, is not supported
key/certificate passwords and multithread locking. :-(

for handling keys and certificates you can use this properties:

@link(TCustomSSL.CertificateFile) for PEM or ASN1 DER (cer) format. @br
@link(TCustomSSL.Certificate) for ASN1 DER format only. @br
@link(TCustomSSL.PrivateKeyFile) for PEM or ASN1 DER (key) format. @br
@link(TCustomSSL.PrivateKey) for ASN1 DER format only. @br
@link(TCustomSSL.CertCAFile) for PEM ca certificate bundle. @br
@link(TCustomSSL.PFXFile) for PFX format. @br
@link(TCustomSSL.PFX) for PFX format from binary string. @br

This plugin is capable to create ad-Hoc certificates. When you start SSL/TLS
Server without explicitly assigned key and certificate, then this plugin create
ad-Hoc key and certificate for each incomming connection by self. it slowdown
accepting of new connections!
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT ssl_openssl;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synsock, synautil,
{$IFDEF CIL}
  system.text,
{$ENDIF}
  ssl_openssl_lib;

TYPE
  {:@abstract(class implementing OpenSSL SSL plugin.)
   instance of this class will be created for each @link(TTCPBlockSocket).
   You not need to create instance of this class, all is done by Synapse itself!}
  TSSLOpenSSL = class(TCustomSSL)
  protected
    FSsl: PSSL;
    Fctx: PSSL_CTX;
    FUNCTION SSLCheck: boolean;
    FUNCTION SetSslKeys: boolean;
    FUNCTION init(Server:boolean): boolean;
    FUNCTION DeInit: boolean;
    FUNCTION Prepare(Server:boolean): boolean;
    FUNCTION LoadPFX(pfxdata: ansistring): boolean;
    FUNCTION CreateSelfSignedCert(Host: string): boolean; override;
  public
    {:See @inherited}
    CONSTRUCTOR create(CONST value: TTCPBlockSocket); override;
    DESTRUCTOR destroy; override;
    {:See @inherited}
    FUNCTION LibVersion: string; override;
    {:See @inherited}
    FUNCTION LibName: string; override;
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
    FUNCTION GetPeerSerialNo: integer; override; {pf}
    {:See @inherited}
    FUNCTION GetPeerIssuer: string; override;
    {:See @inherited}
    FUNCTION GetPeerName: string; override;
    {:See @inherited}
    FUNCTION GetPeerNameHash: Cardinal; override; {pf}
    {:See @inherited}
    FUNCTION GetPeerFingerprint: string; override;
    {:See @inherited}
    FUNCTION GetCertInfo: string; override;
    {:See @inherited}
    FUNCTION GetCipherName: string; override;
    {:See @inherited}
    FUNCTION GetCipherBits: integer; override;
    {:See @inherited}
    FUNCTION GetCipherAlgBits: integer; override;
    {:See @inherited}
    FUNCTION GetVerifyCert: integer; override;
  end;

IMPLEMENTATION

{==============================================================================}

{$IFNDEF CIL}
FUNCTION PasswordCallback(Buf:PAnsiChar; size:integer; rwflag:integer; userdata: pointer):integer; cdecl;
VAR
  Password: ansistring;
begin
  Password := '';
  if TCustomSSL(userdata) is TCustomSSL then
    Password := TCustomSSL(userdata).KeyPassword;
  if length(Password) > (size - 1) then
    setLength(Password, size - 1);
  result := length(Password);
  StrLCopy(Buf, PAnsiChar(Password + #0), result + 1);
end;
{$ENDIF}

{==============================================================================}

CONSTRUCTOR TSSLOpenSSL.create(CONST value: TTCPBlockSocket);
begin
  inherited create(value);
  FCiphers := 'DEFAULT';
  FSsl := nil;
  Fctx := nil;
end;

DESTRUCTOR TSSLOpenSSL.destroy;
begin
  DeInit;
  inherited destroy;
end;

FUNCTION TSSLOpenSSL.LibVersion: string;
begin
  result := SSLeayversion(0);
end;

FUNCTION TSSLOpenSSL.LibName: string;
begin
  result := 'ssl_openssl';
end;

FUNCTION TSSLOpenSSL.SSLCheck: boolean;
VAR
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
  s : ansistring;
begin
  result := true;
  FLastErrorDesc := '';
  FLastError := ErrGetError;
  ErrClearError;
  if FLastError <> 0 then
  begin
    result := false;
{$IFDEF CIL}
    sb := StringBuilder.create(256);
    ErrErrorString(FLastError, sb, 256);
    FLastErrorDesc := trim(sb.toString);
{$ELSE}
    s := StringOfChar(#0, 256);
    ErrErrorString(FLastError, s, length(s));
    FLastErrorDesc := s;
{$ENDIF}
  end;
end;

FUNCTION TSSLOpenSSL.CreateSelfSignedCert(Host: string): boolean;
VAR
  pk: EVP_PKEY;
  x: PX509;
  rsa: PRSA;
  t: PASN1_UTCTIME;
  name: PX509_NAME;
  b: PBIO;
  xn, y: integer;
  s: ansistring;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  result := true;
  pk := EvpPkeynew;
  x := X509New;
  try
    rsa := RsaGenerateKey(1024, $10001, nil, nil);
    EvpPkeyAssign(pk, EVP_PKEY_RSA, rsa);
    X509SetVersion(x, 2);
    Asn1IntegerSet(X509getSerialNumber(x), 0);
    t := Asn1UtctimeNew;
    try
      X509GmtimeAdj(t, -60 * 60 *24);
      X509SetNotBefore(x, t);
      X509GmtimeAdj(t, 60 * 60 * 60 *24);
      X509SetNotAfter(x, t);
    finally
      Asn1UtctimeFree(t);
    end;
    X509SetPubkey(x, pk);
    name := X509GetSubjectName(x);
    X509NameAddEntryByTxt(name, 'C', $1001, 'CZ', -1, -1, 0);
    X509NameAddEntryByTxt(name, 'CN', $1001, host, -1, -1, 0);
    x509SetIssuerName(x, name);
    x509Sign(x, pk, EvpGetDigestByName('SHA1'));
    b := BioNew(BioSMem);
    try
      i2dX509Bio(b, x);
      xn := bioctrlpending(b);
{$IFDEF CIL}
      sb := StringBuilder.create(xn);
      y := bioread(b, sb, xn);
      if y > 0 then
      begin
        sb.length := y;
        s := sb.toString;
      end;
{$ELSE}
      setLength(s, xn);
      y := bioread(b, s, xn);
      if y > 0 then
        setLength(s, y);
{$ENDIF}
    finally
      BioFreeAll(b);
    end;
    FCertificate := s;
    b := BioNew(BioSMem);
    try
      i2dPrivatekeyBio(b, pk);
      xn := bioctrlpending(b);
{$IFDEF CIL}
      sb := StringBuilder.create(xn);
      y := bioread(b, sb, xn);
      if y > 0 then
      begin
        sb.length := y;
        s := sb.toString;
      end;
{$ELSE}
      setLength(s, xn);
      y := bioread(b, s, xn);
      if y > 0 then
        setLength(s, y);
{$ENDIF}
    finally
      BioFreeAll(b);
    end;
    FPrivatekey := s;
  finally
    X509free(x);
    EvpPkeyFree(pk);
  end;
end;

FUNCTION TSSLOpenSSL.LoadPFX(pfxdata: ansistring): boolean;
VAR
  cert, pkey, ca: SslPtr;
  b: PBIO;
  p12: SslPtr;
begin
  result := false;
  b := BioNew(BioSMem);
  try
    BioWrite(b, pfxdata, length(PfxData));
    p12 := d2iPKCS12bio(b, nil);
    if not Assigned(p12) then
      exit;
    try
      cert := nil;
      pkey := nil;
      ca := nil;
      try {pf}
        if PKCS12parse(p12, FKeyPassword, pkey, cert, ca) > 0 then
          if SSLCTXusecertificate(Fctx, cert) > 0 then
            if SSLCTXusePrivateKey(Fctx, pkey) > 0 then
              result := true;
      {pf}
      finally
        EvpPkeyFree(pkey);
        X509free(cert);
        SkX509PopFree(ca,_X509Free); // for ca=nil a new STACK was allocated...
      end;
      {/pf}
    finally
      PKCS12free(p12);
    end;
  finally
    BioFreeAll(b);
  end;
end;

FUNCTION TSSLOpenSSL.SetSslKeys: boolean;
VAR
  st: TFileStream;
  s: string;
begin
  result := false;
  if not assigned(FCtx) then
    exit;
  try
    if FCertificateFile <> '' then
      if SslCtxUseCertificateChainFile(FCtx, FCertificateFile) <> 1 then
        if SslCtxUseCertificateFile(FCtx, FCertificateFile, SSL_FILETYPE_PEM) <> 1 then
          if SslCtxUseCertificateFile(FCtx, FCertificateFile, SSL_FILETYPE_ASN1) <> 1 then
            exit;
    if FCertificate <> '' then
      if SslCtxUseCertificateASN1(FCtx, length(FCertificate), FCertificate) <> 1 then
        exit;
    SSLCheck;
    if FPrivateKeyFile <> '' then
      if SslCtxUsePrivateKeyFile(FCtx, FPrivateKeyFile, SSL_FILETYPE_PEM) <> 1 then
        if SslCtxUsePrivateKeyFile(FCtx, FPrivateKeyFile, SSL_FILETYPE_ASN1) <> 1 then
          exit;
    if FPrivateKey <> '' then
      if SslCtxUsePrivateKeyASN1(EVP_PKEY_RSA, FCtx, FPrivateKey, length(FPrivateKey)) <> 1 then
        exit;
    SSLCheck;
    if FCertCAFile <> '' then
      if SslCtxLoadVerifyLocations(FCtx, FCertCAFile, '') <> 1 then
        exit;
    if FPFXfile <> '' then
    begin
      try
        st := TFileStream.create(FPFXfile, fmOpenRead	 or fmShareDenyNone);
        try
          s := ReadStrFromStream(st, st.size);
        finally
          st.free;
        end;
        if not LoadPFX(s) then
          exit;
      except
        on Exception do
          exit;
      end;
    end;
    if FPFX <> '' then
      if not LoadPFX(FPfx) then
        exit;
    SSLCheck;
    result := true;
  finally
    SSLCheck;
  end;
end;

FUNCTION TSSLOpenSSL.init(Server:boolean): boolean;
VAR
  s: ansistring;
begin
  result := false;
  FLastErrorDesc := '';
  FLastError := 0;
  Fctx := nil;
  case FSSLType of
    LT_SSLv2:
      Fctx := SslCtxNew(SslMethodV2);
    LT_SSLv3:
      Fctx := SslCtxNew(SslMethodV3);
    LT_TLSv1:
      Fctx := SslCtxNew(SslMethodTLSV1);
    LT_all:
      Fctx := SslCtxNew(SslMethodV23);
  else
    exit;
  end;
  if Fctx = nil then
  begin
    SSLCheck;
    exit;
  end
  else
  begin
    s := FCiphers;
    SslCtxSetCipherList(Fctx, s);
    if FVerifyCert then
      SslCtxSetVerify(FCtx, SSL_VERIFY_PEER, nil)
    else
      SslCtxSetVerify(FCtx, SSL_VERIFY_NONE, nil);
{$IFNDEF CIL}
    SslCtxSetDefaultPasswdCb(FCtx, @PasswordCallback);
    SslCtxSetDefaultPasswdCbUserdata(FCtx, self);
{$ENDIF}

    if Server and (FCertificateFile = '') and (FCertificate = '')
      and (FPFXfile = '') and (FPFX = '') then
    begin
      CreateSelfSignedcert(FSocket.ResolveIPToName(FSocket.GetRemoteSinIP));
    end;

    if not SetSSLKeys then
      exit
    else
    begin
      Fssl := nil;
      Fssl := SslNew(Fctx);
      if Fssl = nil then
      begin
        SSLCheck;
        exit;
      end;
    end;
  end;
  result := true;
end;

FUNCTION TSSLOpenSSL.DeInit: boolean;
begin
  result := true;
  if assigned (Fssl) then
    sslfree(Fssl);
  Fssl := nil;
  if assigned (Fctx) then
  begin
    SslCtxFree(Fctx);
    Fctx := nil;
    ErrRemoveState(0);
  end;
  FSSLEnabled := false;
end;

FUNCTION TSSLOpenSSL.Prepare(Server:boolean): boolean;
begin
  result := false;
  DeInit;
  if init(Server) then
    result := true
  else
    DeInit;
end;

FUNCTION TSSLOpenSSL.Connect: boolean;
VAR
  x: integer;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(false) then
  begin
{$IFDEF CIL}
    if sslsetfd(FSsl, FSocket.Socket.handle.ToInt32) < 1 then
{$ELSE}
    if sslsetfd(FSsl, FSocket.Socket) < 1 then
{$ENDIF}
    begin
      SSLCheck;
      exit;
    end;
    if SNIHost<>'' then
      SSLCtrl(Fssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, PAnsiChar(SNIHost));
    x := sslconnect(FSsl);
    if x < 1 then
    begin
      SSLcheck;
      exit;
    end;
  if FverifyCert then
    if (GetVerifyCert <> 0) or (not DoVerifyCert) then
      exit;
    FSSLEnabled := true;
    result := true;
  end;
end;

FUNCTION TSSLOpenSSL.accept: boolean;
VAR
  x: integer;
begin
  result := false;
  if FSocket.Socket = INVALID_SOCKET then
    exit;
  if Prepare(true) then
  begin
{$IFDEF CIL}
    if sslsetfd(FSsl, FSocket.Socket.handle.ToInt32) < 1 then
{$ELSE}
    if sslsetfd(FSsl, FSocket.Socket) < 1 then
{$ENDIF}
    begin
      SSLCheck;
      exit;
    end;
    x := sslAccept(FSsl);
    if x < 1 then
    begin
      SSLcheck;
      exit;
    end;
    FSSLEnabled := true;
    result := true;
  end;
end;

FUNCTION TSSLOpenSSL.Shutdown: boolean;
begin
  if assigned(FSsl) then
    sslshutdown(FSsl);
  DeInit;
  result := true;
end;

FUNCTION TSSLOpenSSL.BiShutdown: boolean;
VAR
  x: integer;
begin
  if assigned(FSsl) then
  begin
    x := sslshutdown(FSsl);
    if x = 0 then
    begin
      Synsock.Shutdown(FSocket.Socket, 1);
      sslshutdown(FSsl);
    end;
  end;
  DeInit;
  result := true;
end;

FUNCTION TSSLOpenSSL.SendBuffer(buffer: TMemory; len: integer): integer;
VAR
  err: integer;
{$IFDEF CIL}
  s: ansistring;
{$ENDIF}
begin
  FLastError := 0;
  FLastErrorDesc := '';
  repeat
{$IFDEF CIL}
    s := StringOf(buffer);
    result := SslWrite(FSsl, s, len);
{$ELSE}
    result := SslWrite(FSsl, buffer , len);
{$ENDIF}
    err := SslGetError(FSsl, result);
  until (err <> SSL_ERROR_WANT_READ) and (err <> SSL_ERROR_WANT_WRITE);
  if err = SSL_ERROR_ZERO_RETURN then
    result := 0
  else
    if (err <> 0) then
      FLastError := err;
end;

FUNCTION TSSLOpenSSL.RecvBuffer(buffer: TMemory; len: integer): integer;
VAR
  err: integer;
{$IFDEF CIL}
  sb: stringbuilder;
  s: ansistring;
{$ENDIF}
begin
  FLastError := 0;
  FLastErrorDesc := '';
  repeat
{$IFDEF CIL}
    sb := StringBuilder.create(len);
    result := SslRead(FSsl, sb, len);
    if result > 0 then
    begin
      sb.length := result;
      s := sb.toString;
      system.array.copy(BytesOf(s), buffer, length(s));
    end;
{$ELSE}
    result := SslRead(FSsl, buffer , len);
{$ENDIF}
    err := SslGetError(FSsl, result);
  until (err <> SSL_ERROR_WANT_READ) and (err <> SSL_ERROR_WANT_WRITE);
  if err = SSL_ERROR_ZERO_RETURN then
    result := 0
  {pf}// Verze 1.1.0 byla s else tak jak to ted mam,
      // ve verzi 1.1.1 bylo ELSE zruseno, ale pak je SSL_ERROR_ZERO_RETURN
      // propagovano jako Chyba.
  {pf} else {/pf} if (err <> 0) then
    FLastError := err;
end;

FUNCTION TSSLOpenSSL.WaitingData: integer;
begin
  result := sslpending(Fssl);
end;

FUNCTION TSSLOpenSSL.GetSSLVersion: string;
begin
  if not assigned(FSsl) then
    result := ''
  else
    result := SSlGetVersion(FSsl);
end;

FUNCTION TSSLOpenSSL.GetPeerSubject: string;
VAR
  cert: PX509;
  s: ansistring;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    result := '';
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    result := '';
    exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.create(4096);
  result := X509NameOneline(X509GetSubjectName(cert), sb, 4096);
{$ELSE}
  setLength(s, 4096);
  result := X509NameOneline(X509GetSubjectName(cert), s, length(s));
{$ENDIF}
  X509Free(cert);
end;


FUNCTION TSSLOpenSSL.GetPeerSerialNo: integer; {pf}
VAR
  cert: PX509;
  SN:   PASN1_INTEGER;
begin
  if not assigned(FSsl) then
  begin
    result := -1;
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  try
    if not assigned(cert) then
    begin
      result := -1;
      exit;
    end;
    SN := X509GetSerialNumber(cert);
    result := Asn1IntegerGet(SN);
  finally
    X509Free(cert);
  end;
end;

FUNCTION TSSLOpenSSL.GetPeerName: string;
VAR
  s: ansistring;
begin
  s := GetPeerSubject;
  s := SeparateRight(s, '/CN=');
  result := trim(SeparateLeft(s, '/'));
end;

FUNCTION TSSLOpenSSL.GetPeerNameHash: Cardinal; {pf}
VAR
  cert: PX509;
begin
  if not assigned(FSsl) then
  begin
    result := 0;
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  try
    if not assigned(cert) then
    begin
      result := 0;
      exit;
    end;
    result := X509NameHash(X509GetSubjectName(cert));
  finally
    X509Free(cert);
  end;
end;

FUNCTION TSSLOpenSSL.GetPeerIssuer: string;
VAR
  cert: PX509;
  s: ansistring;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    result := '';
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    result := '';
    exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.create(4096);
  result := X509NameOneline(X509GetIssuerName(cert), sb, 4096);
{$ELSE}
  setLength(s, 4096);
  result := X509NameOneline(X509GetIssuerName(cert), s, length(s));
{$ENDIF}
  X509Free(cert);
end;

FUNCTION TSSLOpenSSL.GetPeerFingerprint: string;
VAR
  cert: PX509;
  x: integer;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    result := '';
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    result := '';
    exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.create(EVP_MAX_MD_SIZE);
  X509Digest(cert, EvpGetDigestByName('MD5'), sb, x);
  sb.length := x;
  result := sb.toString;
{$ELSE}
  setLength(result, EVP_MAX_MD_SIZE);
  X509Digest(cert, EvpGetDigestByName('MD5'), result, x);
  setLength(result, x);
{$ENDIF}
  X509Free(cert);
end;

FUNCTION TSSLOpenSSL.GetCertInfo: string;
VAR
  cert: PX509;
  x, y: integer;
  b: PBIO;
  s: ansistring;
{$IFDEF CIL}
  sb: stringbuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    result := '';
    exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    result := '';
    exit;
  end;
  try {pf}
    b := BioNew(BioSMem);
    try
      X509Print(b, cert);
      x := bioctrlpending(b);
  {$IFDEF CIL}
      sb := StringBuilder.create(x);
      y := bioread(b, sb, x);
      if y > 0 then
      begin
        sb.length := y;
        s := sb.toString;
      end;
  {$ELSE}
      setLength(s,x);
      y := bioread(b,s,x);
      if y > 0 then
        setLength(s, y);
  {$ENDIF}
      result := ReplaceString(s, LF, CRLF);
    finally
      BioFreeAll(b);
    end;
  {pf}
  finally
    X509Free(cert);
  end;
  {/pf}
end;

FUNCTION TSSLOpenSSL.GetCipherName: string;
begin
  if not assigned(FSsl) then
    result := ''
  else
    result := SslCipherGetName(SslGetCurrentCipher(FSsl));
end;

FUNCTION TSSLOpenSSL.GetCipherBits: integer;
VAR
  x: integer;
begin
  if not assigned(FSsl) then
    result := 0
  else
    result := SSLCipherGetBits(SslGetCurrentCipher(FSsl), x);
end;

FUNCTION TSSLOpenSSL.GetCipherAlgBits: integer;
begin
  if not assigned(FSsl) then
    result := 0
  else
    SSLCipherGetBits(SslGetCurrentCipher(FSsl), result);
end;

FUNCTION TSSLOpenSSL.GetVerifyCert: integer;
begin
  if not assigned(FSsl) then
    result := 1
  else
    result := SslGetVerifyResult(FSsl);
end;

{==============================================================================}

INITIALIZATION
  if InitSSLInterface then
    SSLImplementation := TSSLOpenSSL;

end.
