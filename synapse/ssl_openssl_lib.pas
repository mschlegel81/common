{==============================================================================|
| project : Ararat Synapse                                       | 003.007.000 |
|==============================================================================|
| content: SSL support by OpenSSL                                              |
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
| Portions created by Lukas Gebauer are Copyright (c)2002-2012.                |
| Portions created by Petr Fejfar are Copyright (c)2011-2012.                  |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{
Special thanks to Gregor Ibic <gregor.ibic@intelicom.si>
 (Intelicom d.o.o., http://www.intelicom.si)
 for good inspiration about begin with SSL programming.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
{$IFDEF VER125}
  {$DEFINE BCB}
{$ENDIF}
{$IFDEF BCB}
  {$ObjExportAll On}
  (*$HPPEMIT 'namespace ssl_openssl_lib { using System::Shortint; }' *)
{$ENDIF}

//old Delphi does not have MSWINDOWS define.
{$IFDEF WIN32}
  {$IFNDEF MSWINDOWS}
    {$DEFINE MSWINDOWS}
  {$ENDIF}
{$ENDIF}

{:@abstract(OpenSSL support)

This UNIT is Pascal INTERFACE to OpenSSL library (used by @link(ssl_openssl) UNIT).
OpenSSL is loaded dynamicly on-demand. if this library is not found in system,
requested OpenSSL FUNCTION just return errorcode.
}
UNIT ssl_openssl_lib;

INTERFACE

USES
{$IFDEF CIL}
  system.Runtime.InteropServices,
  system.text,
{$ENDIF}
  Classes,
  synafpc,
{$IFNDEF MSWINDOWS}
  {$IFDEF FPC}
  baseunix, sysutils;
  {$ELSE}
   Libc, sysutils;
  {$ENDIF}
{$ELSE}
  windows;
{$ENDIF}


{$IFDEF CIL}
CONST
  {$IFDEF LINUX}
  DLLSSLName = 'libssl.so';
  DLLUtilName = 'libcrypto.so';
  {$ELSE}
  DLLSSLName = 'ssleay32.dll';
  DLLUtilName = 'libeay32.dll';
  {$ENDIF}
{$ELSE}
VAR
  {$IFNDEF MSWINDOWS}
    {$IFDEF DARWIN}
    DLLSSLName: string = 'libssl.dylib';
    DLLUtilName: string = 'libcrypto.dylib';
    {$ELSE}
    DLLSSLName: string = 'libssl.so';
    DLLUtilName: string = 'libcrypto.so';
    {$ENDIF}
  {$ELSE}
  DLLSSLName: string = 'ssleay32.dll';
  DLLSSLName2: string = 'libssl32.dll';
  DLLUtilName: string = 'libeay32.dll';
  {$ENDIF}
{$ENDIF}

TYPE
{$IFDEF CIL}
  SslPtr = IntPtr;
{$ELSE}
  SslPtr = pointer;
{$ENDIF}
  PSslPtr = ^SslPtr;
  PSSL_CTX = SslPtr;
  PSSL = SslPtr;
  PSSL_METHOD = SslPtr;
  PX509 = SslPtr;
  PX509_NAME = SslPtr;
  PEVP_MD	= SslPtr;
  PInteger = ^integer;
  PBIO_METHOD = SslPtr;
  PBIO = SslPtr;
  EVP_PKEY = SslPtr;
  PRSA = SslPtr;
  PASN1_UTCTIME = SslPtr;
  PASN1_INTEGER = SslPtr;
  PPasswdCb = SslPtr;
  PFunction = PROCEDURE;
  PSTACK = SslPtr; {pf}
  TSkPopFreeFunc = PROCEDURE(p:SslPtr); cdecl; {pf}
  TX509Free = PROCEDURE(x: PX509); cdecl; {pf}

  DES_cblock = array[0..7] of byte;
  PDES_cblock = ^DES_cblock;
  des_ks_struct = packed record
    ks: DES_cblock;
    weak_key: integer;
  end;
  des_key_schedule = array[1..16] of des_ks_struct;

CONST
  EVP_MAX_MD_SIZE = 16 + 20;

  SSL_ERROR_NONE = 0;
  SSL_ERROR_SSL = 1;
  SSL_ERROR_WANT_READ = 2;
  SSL_ERROR_WANT_WRITE = 3;
  SSL_ERROR_WANT_X509_LOOKUP = 4;
  SSL_ERROR_SYSCALL = 5; //look at error stack/return value/errno
  SSL_ERROR_ZERO_RETURN = 6;
  SSL_ERROR_WANT_CONNECT = 7;
  SSL_ERROR_WANT_ACCEPT = 8;

  SSL_OP_NO_SSLv2 = $01000000;
  SSL_OP_NO_SSLv3 = $02000000;
  SSL_OP_NO_TLSv1 = $04000000;
  SSL_OP_ALL = $000FFFFF;
  SSL_VERIFY_NONE = $00;
  SSL_VERIFY_PEER = $01;

  OPENSSL_DES_DECRYPT = 0;
  OPENSSL_DES_ENCRYPT = 1;

  X509_V_OK =	0;
  X509_V_ILLEGAL = 1;
  X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT = 2;
  X509_V_ERR_UNABLE_TO_GET_CRL = 3;
  X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE = 4;
  X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE = 5;
  X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY = 6;
  X509_V_ERR_CERT_SIGNATURE_FAILURE = 7;
  X509_V_ERR_CRL_SIGNATURE_FAILURE = 8;
  X509_V_ERR_CERT_NOT_YET_VALID = 9;
  X509_V_ERR_CERT_HAS_EXPIRED = 10;
  X509_V_ERR_CRL_NOT_YET_VALID = 11;
  X509_V_ERR_CRL_HAS_EXPIRED = 12;
  X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD = 13;
  X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD = 14;
  X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD = 15;
  X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD = 16;
  X509_V_ERR_OUT_OF_MEM = 17;
  X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT = 18;
  X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN = 19;
  X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY = 20;
  X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE = 21;
  X509_V_ERR_CERT_CHAIN_TOO_LONG = 22;
  X509_V_ERR_CERT_REVOKED = 23;
  X509_V_ERR_INVALID_CA = 24;
  X509_V_ERR_PATH_LENGTH_EXCEEDED = 25;
  X509_V_ERR_INVALID_PURPOSE = 26;
  X509_V_ERR_CERT_UNTRUSTED = 27;
  X509_V_ERR_CERT_REJECTED = 28;
  //These are 'informational' when looking for issuer cert
  X509_V_ERR_SUBJECT_ISSUER_MISMATCH = 29;
  X509_V_ERR_AKID_SKID_MISMATCH = 30;
  X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH = 31;
  X509_V_ERR_KEYUSAGE_NO_CERTSIGN = 32;
  X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER = 33;
  X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION = 34;
  //The application is not happy
  X509_V_ERR_APPLICATION_VERIFICATION = 50;

  SSL_FILETYPE_ASN1	= 2;
  SSL_FILETYPE_PEM = 1;
  EVP_PKEY_RSA = 6;

  SSL_CTRL_SET_TLSEXT_HOSTNAME = 55;
  TLSEXT_NAMETYPE_host_name = 0;

VAR
  SSLLibHandle: TLibHandle = 0;
  SSLUtilHandle: TLibHandle = 0;
  SSLLibFile: string = '';
  SSLUtilFile: string = '';

{$IFDEF CIL}
  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_get_error')]
    FUNCTION SslGetError(s: PSSL; ret_code: integer): integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_library_init')]
    FUNCTION SslLibraryInit: integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_load_error_strings')]
    PROCEDURE SslLoadErrorStrings; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_set_cipher_list')]
    FUNCTION SslCtxSetCipherList(arg0: PSSL_CTX; VAR str: string): integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_new')]
    FUNCTION SslCtxNew(meth: PSSL_METHOD):PSSL_CTX;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_free')]
    PROCEDURE SslCtxFree (arg0: PSSL_CTX);   external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_set_fd')]
    FUNCTION SslSetFd(s: PSSL; fd: integer):integer;    external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSLv2_method')]
    FUNCTION SslMethodV2 : PSSL_METHOD; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSLv3_method')]
    FUNCTION SslMethodV3 : PSSL_METHOD;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'TLSv1_method')]
    FUNCTION SslMethodTLSV1:PSSL_METHOD;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSLv23_method')]
    FUNCTION SslMethodV23 : PSSL_METHOD; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_PrivateKey')]
    FUNCTION SslCtxUsePrivateKey(ctx: PSSL_CTX; pkey: SslPtr):integer;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_PrivateKey_ASN1')]
    FUNCTION SslCtxUsePrivateKeyASN1(pk: integer; ctx: PSSL_CTX; d: string; len: integer):integer;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_RSAPrivateKey_file')]
    FUNCTION SslCtxUsePrivateKeyFile(ctx: PSSL_CTX; CONST _file: string; _TYPE: integer):integer;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_certificate')]
    FUNCTION SslCtxUseCertificate(ctx: PSSL_CTX; x: SslPtr):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_certificate_ASN1')]
    FUNCTION SslCtxUseCertificateASN1(ctx: PSSL_CTX; len: integer; d: string):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_certificate_file')]
    FUNCTION SslCtxUseCertificateFile(ctx: PSSL_CTX; CONST _file: string; _TYPE: integer):integer;external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_use_certificate_chain_file')]
    FUNCTION SslCtxUseCertificateChainFile(ctx: PSSL_CTX; CONST _file: string):integer;external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_check_private_key')]
    FUNCTION SslCtxCheckPrivateKeyFile(ctx: PSSL_CTX):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_set_default_passwd_cb')]
    PROCEDURE SslCtxSetDefaultPasswdCb(ctx: PSSL_CTX; cb: PPasswdCb); external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_set_default_passwd_cb_userdata')]
    PROCEDURE SslCtxSetDefaultPasswdCbUserdata(ctx: PSSL_CTX; u: IntPtr); external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_load_verify_locations')]
    FUNCTION SslCtxLoadVerifyLocations(ctx: PSSL_CTX; CAfile: string; CApath: string):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_ctrl')]
    FUNCTION SslCtxCtrl(ctx: PSSL_CTX; cmd: integer; larg: integer; parg: IntPtr): integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_new')]
    FUNCTION SslNew(ctx: PSSL_CTX):PSSL;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_free')]
    PROCEDURE SslFree(ssl: PSSL); external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_accept')]
    FUNCTION SslAccept(ssl: PSSL):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_connect')]
    FUNCTION SslConnect(ssl: PSSL):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_shutdown')]
    FUNCTION SslShutdown(s: PSSL):integer;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_read')]
    FUNCTION SslRead(ssl: PSSL; Buf: StringBuilder; num: integer):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_peek')]
    FUNCTION SslPeek(ssl: PSSL; Buf: StringBuilder; num: integer):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_write')]
    FUNCTION SslWrite(ssl: PSSL; Buf: string; num: integer):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_pending')]
    FUNCTION SslPending(ssl: PSSL):integer; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_get_version')]
    FUNCTION SslGetVersion(ssl: PSSL):string; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_get_peer_certificate')]
    FUNCTION SslGetPeerCertificate(s: PSSL):PX509; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CTX_set_verify')]
    PROCEDURE SslCtxSetVerify(ctx: PSSL_CTX; mode: integer; arg2: PFunction); external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_get_current_cipher')]
    FUNCTION SSLGetCurrentCipher(s: PSSL): SslPtr;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CIPHER_get_name')]
    FUNCTION SSLCipherGetName(c: SslPtr):string; external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_CIPHER_get_bits')]
    FUNCTION SSLCipherGetBits(c: SslPtr; VAR alg_bits: integer):integer;  external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_get_verify_result')]
    FUNCTION SSLGetVerifyResult(ssl: PSSL):integer;external;

  [DllImport(DLLSSLName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'SSL_ctrl')]
    FUNCTION SslCtrl(ssl: PSSL; cmd: integer; larg: integer; parg: IntPtr): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_new')]
    FUNCTION X509New: PX509; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_free')]
    PROCEDURE X509Free(x: PX509); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_NAME_oneline')]
    FUNCTION X509NameOneline(a: PX509_NAME; Buf: StringBuilder; size: integer): string; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_get_subject_name')]
    FUNCTION X509GetSubjectName(a: PX509):PX509_NAME; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_get_issuer_name')]
    FUNCTION X509GetIssuerName(a: PX509):PX509_NAME;  external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_NAME_hash')]
    FUNCTION X509NameHash(x: PX509_NAME):Cardinal;   external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'X509_digest')]
    FUNCTION X509Digest (data: PX509; _TYPE: PEVP_MD; md: StringBuilder; VAR len: integer):integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_set_version')]
    FUNCTION X509SetVersion(x: PX509; version: integer): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_set_pubkey')]
    FUNCTION X509SetPubkey(x: PX509; pkey: EVP_PKEY): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_set_issuer_name')]
    FUNCTION X509SetIssuerName(x: PX509; name: PX509_NAME): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_NAME_add_entry_by_txt')]
    FUNCTION X509NameAddEntryByTxt(name: PX509_NAME; field: string; _TYPE: integer;
      bytes: string; len, loc, _set: integer): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_sign')]
    FUNCTION X509Sign(x: PX509; pkey: EVP_PKEY; CONST md: PEVP_MD): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_print')]
    FUNCTION X509print(b: PBIO; a: PX509): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_gmtime_adj')]
    FUNCTION X509GmtimeAdj(s: PASN1_UTCTIME; adj: integer): PASN1_UTCTIME; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_set_notBefore')]
    FUNCTION X509SetNotBefore(x: PX509; tm: PASN1_UTCTIME): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_set_notAfter')]
    FUNCTION X509SetNotAfter(x: PX509; tm: PASN1_UTCTIME): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'X509_get_serialNumber')]
    FUNCTION X509GetSerialNumber(x: PX509): PASN1_INTEGER; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'EVP_PKEY_new')]
    FUNCTION EvpPkeyNew: EVP_PKEY; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'EVP_PKEY_free')]
    PROCEDURE EvpPkeyFree(pk: EVP_PKEY); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'EVP_PKEY_assign')]
    FUNCTION EvpPkeyAssign(pkey: EVP_PKEY; _TYPE: integer; key: Prsa): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'EVP_get_digestbyname')]
    FUNCTION EvpGetDigestByName(name: string): PEVP_MD; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'EVP_cleanup')]
    PROCEDURE EVPcleanup; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'SSLeay_version')]
    FUNCTION SSLeayversion(t: integer): string; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ERR_error_string_n')]
    PROCEDURE ErrErrorString(e: integer; Buf: StringBuilder; len: integer); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ERR_get_error')]
    FUNCTION ErrGetError: integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ERR_clear_error')]
    PROCEDURE ErrClearError; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ERR_free_strings')]
    PROCEDURE ErrFreeStrings; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ERR_remove_state')]
    PROCEDURE ErrRemoveState(pid: integer); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'OPENSSL_add_all_algorithms_noconf')]
    PROCEDURE OPENSSLaddallalgorithms; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'CRYPTO_cleanup_all_ex_data')]
    PROCEDURE CRYPTOcleanupAllExData; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'RAND_screen')]
    PROCEDURE RandScreen; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_new')]
    FUNCTION BioNew(b: PBIO_METHOD): PBIO; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_free_all')]
    PROCEDURE BioFreeAll(b: PBIO); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_s_mem')]
    FUNCTION BioSMem: PBIO_METHOD; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_ctrl_pending')]
    FUNCTION BioCtrlPending(b: PBIO): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_read')]
    FUNCTION BioRead(b: PBIO; Buf: StringBuilder; len: integer): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'BIO_write')]
    FUNCTION BioWrite(b: PBIO; VAR Buf: string; len: integer): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'd2i_PKCS12_bio')]
    FUNCTION d2iPKCS12bio(b:PBIO; Pkcs12: SslPtr): SslPtr; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'PKCS12_parse')]
    FUNCTION PKCS12parse(p12: SslPtr; pass: string; VAR pkey, cert, ca: SslPtr): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'PKCS12_free')]
    PROCEDURE PKCS12free(p12: SslPtr); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'RSA_generate_key')]
    FUNCTION RsaGenerateKey(bits, e: integer; callback: PFunction; cb_arg: SslPtr): PRSA; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ASN1_UTCTIME_new')]
    FUNCTION Asn1UtctimeNew: PASN1_UTCTIME; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ASN1_UTCTIME_free')]
    PROCEDURE Asn1UtctimeFree(a: PASN1_UTCTIME); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'ASN1_INTEGER_set')]
    FUNCTION Asn1IntegerSet(a: PASN1_INTEGER; v: integer): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'i2d_X509_bio')]
    FUNCTION i2dX509bio(b: PBIO; x: PX509): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint =  'i2d_PrivateKey_bio')]
    FUNCTION i2dPrivateKeyBio(b: PBIO; pkey: EVP_PKEY): integer; external;

  // 3DES functions
  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'DES_set_odd_parity')]
    PROCEDURE DESsetoddparity(key: des_cblock); external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'DES_set_key_checked')]
    FUNCTION DESsetkeychecked(key: des_cblock; schedule: des_key_schedule): integer; external;

  [DllImport(DLLUtilName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'DES_ecb_encrypt')]
    PROCEDURE DESecbencrypt(input: des_cblock; output: des_cblock; ks: des_key_schedule; enc: integer); external;

{$ELSE}
// libssl.dll
  FUNCTION SslGetError(s: PSSL; ret_code: integer):integer;
  FUNCTION SslLibraryInit:integer;
  PROCEDURE SslLoadErrorStrings;
//  function SslCtxSetCipherList(arg0: PSSL_CTX; str: PChar):Integer;
  FUNCTION SslCtxSetCipherList(arg0: PSSL_CTX; VAR str: ansistring):integer;
  FUNCTION SslCtxNew(meth: PSSL_METHOD):PSSL_CTX;
  PROCEDURE SslCtxFree(arg0: PSSL_CTX);
  FUNCTION SslSetFd(s: PSSL; fd: integer):integer;
  FUNCTION SslMethodV2:PSSL_METHOD;
  FUNCTION SslMethodV3:PSSL_METHOD;
  FUNCTION SslMethodTLSV1:PSSL_METHOD;
  FUNCTION SslMethodV23:PSSL_METHOD;
  FUNCTION SslCtxUsePrivateKey(ctx: PSSL_CTX; pkey: SslPtr):integer;
  FUNCTION SslCtxUsePrivateKeyASN1(pk: integer; ctx: PSSL_CTX; d: ansistring; len: integer):integer;
//  function SslCtxUsePrivateKeyFile(ctx: PSSL_CTX; const _file: PChar; _type: Integer):Integer;
  FUNCTION SslCtxUsePrivateKeyFile(ctx: PSSL_CTX; CONST _file: ansistring; _TYPE: integer):integer;
  FUNCTION SslCtxUseCertificate(ctx: PSSL_CTX; x: SslPtr):integer;
  FUNCTION SslCtxUseCertificateASN1(ctx: PSSL_CTX; len: integer; d: ansistring):integer;
  FUNCTION SslCtxUseCertificateFile(ctx: PSSL_CTX; CONST _file: ansistring; _TYPE: integer):integer;
//  function SslCtxUseCertificateChainFile(ctx: PSSL_CTX; const _file: PChar):Integer;
  FUNCTION SslCtxUseCertificateChainFile(ctx: PSSL_CTX; CONST _file: ansistring):integer;
  FUNCTION SslCtxCheckPrivateKeyFile(ctx: PSSL_CTX):integer;
  PROCEDURE SslCtxSetDefaultPasswdCb(ctx: PSSL_CTX; cb: PPasswdCb);
  PROCEDURE SslCtxSetDefaultPasswdCbUserdata(ctx: PSSL_CTX; u: SslPtr);
//  function SslCtxLoadVerifyLocations(ctx: PSSL_CTX; const CAfile: PChar; const CApath: PChar):Integer;
  FUNCTION SslCtxLoadVerifyLocations(ctx: PSSL_CTX; CONST CAfile: ansistring; CONST CApath: ansistring):integer;
  FUNCTION SslCtxCtrl(ctx: PSSL_CTX; cmd: integer; larg: integer; parg: SslPtr): integer;
  FUNCTION SslNew(ctx: PSSL_CTX):PSSL;
  PROCEDURE SslFree(ssl: PSSL);
  FUNCTION SslAccept(ssl: PSSL):integer;
  FUNCTION SslConnect(ssl: PSSL):integer;
  FUNCTION SslShutdown(ssl: PSSL):integer;
  FUNCTION SslRead(ssl: PSSL; Buf: SslPtr; num: integer):integer;
  FUNCTION SslPeek(ssl: PSSL; Buf: SslPtr; num: integer):integer;
  FUNCTION SslWrite(ssl: PSSL; Buf: SslPtr; num: integer):integer;
  FUNCTION SslPending(ssl: PSSL):integer;
  FUNCTION SslGetVersion(ssl: PSSL):ansistring;
  FUNCTION SslGetPeerCertificate(ssl: PSSL):PX509;
  PROCEDURE SslCtxSetVerify(ctx: PSSL_CTX; mode: integer; arg2: PFunction);
  FUNCTION SSLGetCurrentCipher(s: PSSL):SslPtr;
  FUNCTION SSLCipherGetName(c: SslPtr): ansistring;
  FUNCTION SSLCipherGetBits(c: SslPtr; VAR alg_bits: integer):integer;
  FUNCTION SSLGetVerifyResult(ssl: PSSL):integer;
  FUNCTION SSLCtrl(ssl: PSSL; cmd: integer; larg: integer; parg: SslPtr):integer;

// libeay.dll
  FUNCTION X509New: PX509;
  PROCEDURE X509Free(x: PX509);
  FUNCTION X509NameOneline(a: PX509_NAME; VAR Buf: ansistring; size: integer):ansistring;
  FUNCTION X509GetSubjectName(a: PX509):PX509_NAME;
  FUNCTION X509GetIssuerName(a: PX509):PX509_NAME;
  FUNCTION X509NameHash(x: PX509_NAME):Cardinal;
//  function SslX509Digest(data: PX509; _type: PEVP_MD; md: PChar; len: PInteger):Integer;
  FUNCTION X509Digest(data: PX509; _TYPE: PEVP_MD; md: ansistring; VAR len: integer):integer;
  FUNCTION X509print(b: PBIO; a: PX509): integer;
  FUNCTION X509SetVersion(x: PX509; version: integer): integer;
  FUNCTION X509SetPubkey(x: PX509; pkey: EVP_PKEY): integer;
  FUNCTION X509SetIssuerName(x: PX509; name: PX509_NAME): integer;
  FUNCTION X509NameAddEntryByTxt(name: PX509_NAME; field: ansistring; _TYPE: integer;
    bytes: ansistring; len, loc, _set: integer): integer;
  FUNCTION X509Sign(x: PX509; pkey: EVP_PKEY; CONST md: PEVP_MD): integer;
  FUNCTION X509GmtimeAdj(s: PASN1_UTCTIME; adj: integer): PASN1_UTCTIME;
  FUNCTION X509SetNotBefore(x: PX509; tm: PASN1_UTCTIME): integer;
  FUNCTION X509SetNotAfter(x: PX509; tm: PASN1_UTCTIME): integer;
  FUNCTION X509GetSerialNumber(x: PX509): PASN1_INTEGER;
  FUNCTION EvpPkeyNew: EVP_PKEY;
  PROCEDURE EvpPkeyFree(pk: EVP_PKEY);
  FUNCTION EvpPkeyAssign(pkey: EVP_PKEY; _TYPE: integer; key: Prsa): integer;
  FUNCTION EvpGetDigestByName(name: ansistring): PEVP_MD;
  PROCEDURE EVPcleanup;
//  function ErrErrorString(e: integer; buf: PChar): PChar;
  FUNCTION SSLeayversion(t: integer): ansistring;
  PROCEDURE ErrErrorString(e: integer; VAR Buf: ansistring; len: integer);
  FUNCTION ErrGetError: integer;
  PROCEDURE ErrClearError;
  PROCEDURE ErrFreeStrings;
  PROCEDURE ErrRemoveState(pid: integer);
  PROCEDURE OPENSSLaddallalgorithms;
  PROCEDURE CRYPTOcleanupAllExData;
  PROCEDURE RandScreen;
  FUNCTION BioNew(b: PBIO_METHOD): PBIO;
  PROCEDURE BioFreeAll(b: PBIO);
  FUNCTION BioSMem: PBIO_METHOD;
  FUNCTION BioCtrlPending(b: PBIO): integer;
  FUNCTION BioRead(b: PBIO; VAR Buf: ansistring; len: integer): integer;
  FUNCTION BioWrite(b: PBIO; Buf: ansistring; len: integer): integer;
  FUNCTION d2iPKCS12bio(b:PBIO; Pkcs12: SslPtr): SslPtr;
  FUNCTION PKCS12parse(p12: SslPtr; pass: ansistring; VAR pkey, cert, ca: SslPtr): integer;
  PROCEDURE PKCS12free(p12: SslPtr);
  FUNCTION RsaGenerateKey(bits, e: integer; callback: PFunction; cb_arg: SslPtr): PRSA;
  FUNCTION Asn1UtctimeNew: PASN1_UTCTIME;
  PROCEDURE Asn1UtctimeFree(a: PASN1_UTCTIME);
  FUNCTION Asn1IntegerSet(a: PASN1_INTEGER; v: integer): integer;
  FUNCTION Asn1IntegerGet(a: PASN1_INTEGER): integer; {pf}
  FUNCTION i2dX509bio(b: PBIO; x: PX509): integer;
  FUNCTION d2iX509bio(b:PBIO; x:PX509):  PX509;    {pf}
  FUNCTION PEMReadBioX509(b:PBIO; {var x:PX509;}x:PSslPtr; callback:PFunction; cb_arg: SslPtr):  PX509;    {pf}
  PROCEDURE SkX509PopFree(st: PSTACK; func: TSkPopFreeFunc); {pf}


  FUNCTION i2dPrivateKeyBio(b: PBIO; pkey: EVP_PKEY): integer;

  // 3DES functions
  PROCEDURE DESsetoddparity(key: des_cblock);
  FUNCTION DESsetkeychecked(key: des_cblock; schedule: des_key_schedule): integer;
  PROCEDURE DESecbencrypt(input: des_cblock; output: des_cblock; ks: des_key_schedule; enc: integer);

{$ENDIF}

FUNCTION IsSSLloaded: boolean;
FUNCTION InitSSLInterface: boolean;
FUNCTION DestroySSLInterface: boolean;

VAR
  _X509Free: TX509Free = nil; {pf}

IMPLEMENTATION

USES SyncObjs;

{$IFNDEF CIL}
TYPE
// libssl.dll
  TSslGetError = FUNCTION(s: PSSL; ret_code: integer):integer; cdecl;
  TSslLibraryInit = FUNCTION:integer; cdecl;
  TSslLoadErrorStrings = PROCEDURE; cdecl;
  TSslCtxSetCipherList = FUNCTION(arg0: PSSL_CTX; str: PAnsiChar):integer; cdecl;
  TSslCtxNew = FUNCTION(meth: PSSL_METHOD):PSSL_CTX; cdecl;
  TSslCtxFree = PROCEDURE(arg0: PSSL_CTX); cdecl;
  TSslSetFd = FUNCTION(s: PSSL; fd: integer):integer; cdecl;
  TSslMethodV2 = FUNCTION:PSSL_METHOD; cdecl;
  TSslMethodV3 = FUNCTION:PSSL_METHOD; cdecl;
  TSslMethodTLSV1 = FUNCTION:PSSL_METHOD; cdecl;
  TSslMethodV23 = FUNCTION:PSSL_METHOD; cdecl;
  TSslCtxUsePrivateKey = FUNCTION(ctx: PSSL_CTX; pkey: sslptr):integer; cdecl;
  TSslCtxUsePrivateKeyASN1 = FUNCTION(pk: integer; ctx: PSSL_CTX; d: sslptr; len: integer):integer; cdecl;
  TSslCtxUsePrivateKeyFile = FUNCTION(ctx: PSSL_CTX; CONST _file: PAnsiChar; _TYPE: integer):integer; cdecl;
  TSslCtxUseCertificate = FUNCTION(ctx: PSSL_CTX; x: SslPtr):integer; cdecl;
  TSslCtxUseCertificateASN1 = FUNCTION(ctx: PSSL_CTX; len: integer; d: SslPtr):integer; cdecl;
  TSslCtxUseCertificateFile = FUNCTION(ctx: PSSL_CTX; CONST _file: PAnsiChar; _TYPE: integer):integer; cdecl;
  TSslCtxUseCertificateChainFile = FUNCTION(ctx: PSSL_CTX; CONST _file: PAnsiChar):integer; cdecl;
  TSslCtxCheckPrivateKeyFile = FUNCTION(ctx: PSSL_CTX):integer; cdecl;
  TSslCtxSetDefaultPasswdCb = PROCEDURE(ctx: PSSL_CTX; cb: SslPtr); cdecl;
  TSslCtxSetDefaultPasswdCbUserdata = PROCEDURE(ctx: PSSL_CTX; u: SslPtr); cdecl;
  TSslCtxLoadVerifyLocations = FUNCTION(ctx: PSSL_CTX; CONST CAfile: PAnsiChar; CONST CApath: PAnsiChar):integer; cdecl;
  TSslCtxCtrl = FUNCTION(ctx: PSSL_CTX; cmd: integer; larg: integer; parg: SslPtr): integer; cdecl;
  TSslNew = FUNCTION(ctx: PSSL_CTX):PSSL; cdecl;
  TSslFree = PROCEDURE(ssl: PSSL); cdecl;
  TSslAccept = FUNCTION(ssl: PSSL):integer; cdecl;
  TSslConnect = FUNCTION(ssl: PSSL):integer; cdecl;
  TSslShutdown = FUNCTION(ssl: PSSL):integer; cdecl;
  TSslRead = FUNCTION(ssl: PSSL; Buf: PAnsiChar; num: integer):integer; cdecl;
  TSslPeek = FUNCTION(ssl: PSSL; Buf: PAnsiChar; num: integer):integer; cdecl;
  TSslWrite = FUNCTION(ssl: PSSL; CONST Buf: PAnsiChar; num: integer):integer; cdecl;
  TSslPending = FUNCTION(ssl: PSSL):integer; cdecl;
  TSslGetVersion = FUNCTION(ssl: PSSL):PAnsiChar; cdecl;
  TSslGetPeerCertificate = FUNCTION(ssl: PSSL):PX509; cdecl;
  TSslCtxSetVerify = PROCEDURE(ctx: PSSL_CTX; mode: integer; arg2: SslPtr); cdecl;
  TSSLGetCurrentCipher = FUNCTION(s: PSSL):SslPtr; cdecl;
  TSSLCipherGetName = FUNCTION(c: Sslptr):PAnsiChar; cdecl;
  TSSLCipherGetBits = FUNCTION(c: SslPtr; alg_bits: PInteger):integer; cdecl;
  TSSLGetVerifyResult = FUNCTION(ssl: PSSL):integer; cdecl;
  TSSLCtrl = FUNCTION(ssl: PSSL; cmd: integer; larg: integer; parg: SslPtr):integer; cdecl;

  TSSLSetTlsextHostName = FUNCTION(ssl: PSSL; Buf: PAnsiChar):integer; cdecl;

// libeay.dll
  TX509New = FUNCTION: PX509; cdecl;
  TX509NameOneline = FUNCTION(a: PX509_NAME; Buf: PAnsiChar; size: integer):PAnsiChar; cdecl;
  TX509GetSubjectName = FUNCTION(a: PX509):PX509_NAME; cdecl;
  TX509GetIssuerName = FUNCTION(a: PX509):PX509_NAME; cdecl;
  TX509NameHash = FUNCTION(x: PX509_NAME):Cardinal; cdecl;
  TX509Digest = FUNCTION(data: PX509; _TYPE: PEVP_MD; md: PAnsiChar; len: PInteger):integer; cdecl;
  TX509print = FUNCTION(b: PBIO; a: PX509): integer; cdecl;
  TX509SetVersion = FUNCTION(x: PX509; version: integer): integer; cdecl;
  TX509SetPubkey = FUNCTION(x: PX509; pkey: EVP_PKEY): integer; cdecl;
  TX509SetIssuerName = FUNCTION(x: PX509; name: PX509_NAME): integer; cdecl;
  TX509NameAddEntryByTxt = FUNCTION(name: PX509_NAME; field: PAnsiChar; _TYPE: integer;
    bytes: PAnsiChar; len, loc, _set: integer): integer; cdecl;
  TX509Sign = FUNCTION(x: PX509; pkey: EVP_PKEY; CONST md: PEVP_MD): integer; cdecl;
  TX509GmtimeAdj = FUNCTION(s: PASN1_UTCTIME; adj: integer): PASN1_UTCTIME; cdecl;
  TX509SetNotBefore = FUNCTION(x: PX509; tm: PASN1_UTCTIME): integer; cdecl;
  TX509SetNotAfter = FUNCTION(x: PX509; tm: PASN1_UTCTIME): integer; cdecl;
  TX509GetSerialNumber = FUNCTION(x: PX509): PASN1_INTEGER; cdecl;
  TEvpPkeyNew = FUNCTION: EVP_PKEY; cdecl;
  TEvpPkeyFree = PROCEDURE(pk: EVP_PKEY); cdecl;
  TEvpPkeyAssign = FUNCTION(pkey: EVP_PKEY; _TYPE: integer; key: Prsa): integer; cdecl;
  TEvpGetDigestByName = FUNCTION(name: PAnsiChar): PEVP_MD; cdecl;
  TEVPcleanup = PROCEDURE; cdecl;
  TSSLeayversion = FUNCTION(t: integer): PAnsiChar; cdecl;
  TErrErrorString = PROCEDURE(e: integer; Buf: PAnsiChar; len: integer); cdecl;
  TErrGetError = FUNCTION: integer; cdecl;
  TErrClearError = PROCEDURE; cdecl;
  TErrFreeStrings = PROCEDURE; cdecl;
  TErrRemoveState = PROCEDURE(pid: integer); cdecl;
  TOPENSSLaddallalgorithms = PROCEDURE; cdecl;
  TCRYPTOcleanupAllExData = PROCEDURE; cdecl;
  TRandScreen = PROCEDURE; cdecl;
  TBioNew = FUNCTION(b: PBIO_METHOD): PBIO; cdecl;
  TBioFreeAll = PROCEDURE(b: PBIO); cdecl;
  TBioSMem = FUNCTION: PBIO_METHOD; cdecl;
  TBioCtrlPending = FUNCTION(b: PBIO): integer; cdecl;
  TBioRead = FUNCTION(b: PBIO; Buf: PAnsiChar; len: integer): integer; cdecl;
  TBioWrite = FUNCTION(b: PBIO; Buf: PAnsiChar; len: integer): integer; cdecl;
  Td2iPKCS12bio = FUNCTION(b:PBIO; Pkcs12: SslPtr): SslPtr; cdecl;
  TPKCS12parse = FUNCTION(p12: SslPtr; pass: PAnsiChar; VAR pkey, cert, ca: SslPtr): integer; cdecl;
  TPKCS12free = PROCEDURE(p12: SslPtr); cdecl;
  TRsaGenerateKey = FUNCTION(bits, e: integer; callback: PFunction; cb_arg: SslPtr): PRSA; cdecl;
  TAsn1UtctimeNew = FUNCTION: PASN1_UTCTIME; cdecl;
  TAsn1UtctimeFree = PROCEDURE(a: PASN1_UTCTIME); cdecl;
  TAsn1IntegerSet = FUNCTION(a: PASN1_INTEGER; v: integer): integer; cdecl;
  TAsn1IntegerGet = FUNCTION(a: PASN1_INTEGER): integer; cdecl; {pf}
  Ti2dX509bio = FUNCTION(b: PBIO; x: PX509): integer; cdecl;
  Td2iX509bio = FUNCTION(b:PBIO;  x:PX509):   PX509;   cdecl; {pf}
  TPEMReadBioX509 = FUNCTION(b:PBIO;  {var x:PX509;}x:PSslPtr; callback:PFunction; cb_arg:SslPtr): PX509;   cdecl; {pf}
  TSkX509PopFree = PROCEDURE(st: PSTACK; func: TSkPopFreeFunc); cdecl; {pf}
  Ti2dPrivateKeyBio= FUNCTION(b: PBIO; pkey: EVP_PKEY): integer; cdecl;

  // 3DES functions
  TDESsetoddparity = PROCEDURE(key: des_cblock); cdecl;
  TDESsetkeychecked = FUNCTION(key: des_cblock; schedule: des_key_schedule): integer; cdecl;
  TDESecbencrypt = PROCEDURE(input: des_cblock; output: des_cblock; ks: des_key_schedule; enc: integer); cdecl;
  //thread lock functions
  TCRYPTOnumlocks = FUNCTION: integer; cdecl;
  TCRYPTOSetLockingCallback = PROCEDURE(cb: Sslptr); cdecl;

VAR
// libssl.dll
  _SslGetError: TSslGetError = nil;
  _SslLibraryInit: TSslLibraryInit = nil;
  _SslLoadErrorStrings: TSslLoadErrorStrings = nil;
  _SslCtxSetCipherList: TSslCtxSetCipherList = nil;
  _SslCtxNew: TSslCtxNew = nil;
  _SslCtxFree: TSslCtxFree = nil;
  _SslSetFd: TSslSetFd = nil;
  _SslMethodV2: TSslMethodV2 = nil;
  _SslMethodV3: TSslMethodV3 = nil;
  _SslMethodTLSV1: TSslMethodTLSV1 = nil;
  _SslMethodV23: TSslMethodV23 = nil;
  _SslCtxUsePrivateKey: TSslCtxUsePrivateKey = nil;
  _SslCtxUsePrivateKeyASN1: TSslCtxUsePrivateKeyASN1 = nil;
  _SslCtxUsePrivateKeyFile: TSslCtxUsePrivateKeyFile = nil;
  _SslCtxUseCertificate: TSslCtxUseCertificate = nil;
  _SslCtxUseCertificateASN1: TSslCtxUseCertificateASN1 = nil;
  _SslCtxUseCertificateFile: TSslCtxUseCertificateFile = nil;
  _SslCtxUseCertificateChainFile: TSslCtxUseCertificateChainFile = nil;
  _SslCtxCheckPrivateKeyFile: TSslCtxCheckPrivateKeyFile = nil;
  _SslCtxSetDefaultPasswdCb: TSslCtxSetDefaultPasswdCb = nil;
  _SslCtxSetDefaultPasswdCbUserdata: TSslCtxSetDefaultPasswdCbUserdata = nil;
  _SslCtxLoadVerifyLocations: TSslCtxLoadVerifyLocations = nil;
  _SslCtxCtrl: TSslCtxCtrl = nil;
  _SslNew: TSslNew = nil;
  _SslFree: TSslFree = nil;
  _SslAccept: TSslAccept = nil;
  _SslConnect: TSslConnect = nil;
  _SslShutdown: TSslShutdown = nil;
  _SslRead: TSslRead = nil;
  _SslPeek: TSslPeek = nil;
  _SslWrite: TSslWrite = nil;
  _SslPending: TSslPending = nil;
  _SslGetVersion: TSslGetVersion = nil;
  _SslGetPeerCertificate: TSslGetPeerCertificate = nil;
  _SslCtxSetVerify: TSslCtxSetVerify = nil;
  _SSLGetCurrentCipher: TSSLGetCurrentCipher = nil;
  _SSLCipherGetName: TSSLCipherGetName = nil;
  _SSLCipherGetBits: TSSLCipherGetBits = nil;
  _SSLGetVerifyResult: TSSLGetVerifyResult = nil;
  _SSLCtrl: TSSLCtrl = nil;

// libeay.dll
  _X509New: TX509New = nil;
  _X509NameOneline: TX509NameOneline = nil;
  _X509GetSubjectName: TX509GetSubjectName = nil;
  _X509GetIssuerName: TX509GetIssuerName = nil;
  _X509NameHash: TX509NameHash = nil;
  _X509Digest: TX509Digest = nil;
  _X509print: TX509print = nil;
  _X509SetVersion: TX509SetVersion = nil;
  _X509SetPubkey: TX509SetPubkey = nil;
  _X509SetIssuerName: TX509SetIssuerName = nil;
  _X509NameAddEntryByTxt: TX509NameAddEntryByTxt = nil;
  _X509Sign: TX509Sign = nil;
  _X509GmtimeAdj: TX509GmtimeAdj = nil;
  _X509SetNotBefore: TX509SetNotBefore = nil;
  _X509SetNotAfter: TX509SetNotAfter = nil;
  _X509GetSerialNumber: TX509GetSerialNumber = nil;
  _EvpPkeyNew: TEvpPkeyNew = nil;
  _EvpPkeyFree: TEvpPkeyFree = nil;
  _EvpPkeyAssign: TEvpPkeyAssign = nil;
  _EvpGetDigestByName: TEvpGetDigestByName = nil;
  _EVPcleanup: TEVPcleanup = nil;
  _SSLeayversion: TSSLeayversion = nil;
  _ErrErrorString: TErrErrorString = nil;
  _ErrGetError: TErrGetError = nil;
  _ErrClearError: TErrClearError = nil;
  _ErrFreeStrings: TErrFreeStrings = nil;
  _ErrRemoveState: TErrRemoveState = nil;
  _OPENSSLaddallalgorithms: TOPENSSLaddallalgorithms = nil;
  _CRYPTOcleanupAllExData: TCRYPTOcleanupAllExData = nil;
  _RandScreen: TRandScreen = nil;
  _BioNew: TBioNew = nil;
  _BioFreeAll: TBioFreeAll = nil;
  _BioSMem: TBioSMem = nil;
  _BioCtrlPending: TBioCtrlPending = nil;
  _BioRead: TBioRead = nil;
  _BioWrite: TBioWrite = nil;
  _d2iPKCS12bio: Td2iPKCS12bio = nil;
  _PKCS12parse: TPKCS12parse = nil;
  _PKCS12free: TPKCS12free = nil;
  _RsaGenerateKey: TRsaGenerateKey = nil;
  _Asn1UtctimeNew: TAsn1UtctimeNew = nil;
  _Asn1UtctimeFree: TAsn1UtctimeFree = nil;
  _Asn1IntegerSet: TAsn1IntegerSet = nil;
  _Asn1IntegerGet: TAsn1IntegerGet = nil; {pf}
  _i2dX509bio: Ti2dX509bio = nil;
  _d2iX509bio: Td2iX509bio = nil; {pf}
  _PEMReadBioX509: TPEMReadBioX509 = nil; {pf}
  _SkX509PopFree: TSkX509PopFree = nil; {pf}
  _i2dPrivateKeyBio: Ti2dPrivateKeyBio = nil;

  // 3DES functions
  _DESsetoddparity: TDESsetoddparity = nil;
  _DESsetkeychecked: TDESsetkeychecked = nil;
  _DESecbencrypt: TDESecbencrypt = nil;
  //thread lock functions
  _CRYPTOnumlocks: TCRYPTOnumlocks = nil;
  _CRYPTOSetLockingCallback: TCRYPTOSetLockingCallback = nil;
{$ENDIF}

VAR
  SSLCS: TCriticalSection;
  SSLloaded: boolean = false;
{$IFNDEF CIL}
  Locks: TList;
{$ENDIF}

{$IFNDEF CIL}
// libssl.dll
FUNCTION SslGetError(s: PSSL; ret_code: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslGetError) then
    result := _SslGetError(s, ret_code)
  else
    result := SSL_ERROR_SSL;
end;

FUNCTION SslLibraryInit:integer;
begin
  if InitSSLInterface and Assigned(_SslLibraryInit) then
    result := _SslLibraryInit
  else
    result := 1;
end;

PROCEDURE SslLoadErrorStrings;
begin
  if InitSSLInterface and Assigned(_SslLoadErrorStrings) then
    _SslLoadErrorStrings;
end;

//function SslCtxSetCipherList(arg0: PSSL_CTX; str: PChar):Integer;
FUNCTION SslCtxSetCipherList(arg0: PSSL_CTX; VAR str: ansistring):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxSetCipherList) then
    result := _SslCtxSetCipherList(arg0, PAnsiChar(str))
  else
    result := 0;
end;

FUNCTION SslCtxNew(meth: PSSL_METHOD):PSSL_CTX;
begin
  if InitSSLInterface and Assigned(_SslCtxNew) then
    result := _SslCtxNew(meth)
  else
    result := nil;
end;

PROCEDURE SslCtxFree(arg0: PSSL_CTX);
begin
  if InitSSLInterface and Assigned(_SslCtxFree) then
    _SslCtxFree(arg0);
end;

FUNCTION SslSetFd(s: PSSL; fd: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslSetFd) then
    result := _SslSetFd(s, fd)
  else
    result := 0;
end;

FUNCTION SslMethodV2:PSSL_METHOD;
begin
  if InitSSLInterface and Assigned(_SslMethodV2) then
    result := _SslMethodV2
  else
    result := nil;
end;

FUNCTION SslMethodV3:PSSL_METHOD;
begin
  if InitSSLInterface and Assigned(_SslMethodV3) then
    result := _SslMethodV3
  else
    result := nil;
end;

FUNCTION SslMethodTLSV1:PSSL_METHOD;
begin
  if InitSSLInterface and Assigned(_SslMethodTLSV1) then
    result := _SslMethodTLSV1
  else
    result := nil;
end;

FUNCTION SslMethodV23:PSSL_METHOD;
begin
  if InitSSLInterface and Assigned(_SslMethodV23) then
    result := _SslMethodV23
  else
    result := nil;
end;

FUNCTION SslCtxUsePrivateKey(ctx: PSSL_CTX; pkey: SslPtr):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUsePrivateKey) then
    result := _SslCtxUsePrivateKey(ctx, pkey)
  else
    result := 0;
end;

FUNCTION SslCtxUsePrivateKeyASN1(pk: integer; ctx: PSSL_CTX; d: ansistring; len: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUsePrivateKeyASN1) then
    result := _SslCtxUsePrivateKeyASN1(pk, ctx, Sslptr(d), len)
  else
    result := 0;
end;

//function SslCtxUsePrivateKeyFile(ctx: PSSL_CTX; const _file: PChar; _type: Integer):Integer;
FUNCTION SslCtxUsePrivateKeyFile(ctx: PSSL_CTX; CONST _file: ansistring; _TYPE: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUsePrivateKeyFile) then
    result := _SslCtxUsePrivateKeyFile(ctx, PAnsiChar(_file), _TYPE)
  else
    result := 0;
end;

FUNCTION SslCtxUseCertificate(ctx: PSSL_CTX; x: SslPtr):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUseCertificate) then
    result := _SslCtxUseCertificate(ctx, x)
  else
    result := 0;
end;

FUNCTION SslCtxUseCertificateASN1(ctx: PSSL_CTX; len: integer; d: ansistring):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUseCertificateASN1) then
    result := _SslCtxUseCertificateASN1(ctx, len, SslPtr(d))
  else
    result := 0;
end;

FUNCTION SslCtxUseCertificateFile(ctx: PSSL_CTX; CONST _file: ansistring; _TYPE: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUseCertificateFile) then
    result := _SslCtxUseCertificateFile(ctx, PAnsiChar(_file), _TYPE)
  else
    result := 0;
end;

//function SslCtxUseCertificateChainFile(ctx: PSSL_CTX; const _file: PChar):Integer;
FUNCTION SslCtxUseCertificateChainFile(ctx: PSSL_CTX; CONST _file: ansistring):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxUseCertificateChainFile) then
    result := _SslCtxUseCertificateChainFile(ctx, PAnsiChar(_file))
  else
    result := 0;
end;

FUNCTION SslCtxCheckPrivateKeyFile(ctx: PSSL_CTX):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxCheckPrivateKeyFile) then
    result := _SslCtxCheckPrivateKeyFile(ctx)
  else
    result := 0;
end;

PROCEDURE SslCtxSetDefaultPasswdCb(ctx: PSSL_CTX; cb: PPasswdCb);
begin
  if InitSSLInterface and Assigned(_SslCtxSetDefaultPasswdCb) then
    _SslCtxSetDefaultPasswdCb(ctx, cb);
end;

PROCEDURE SslCtxSetDefaultPasswdCbUserdata(ctx: PSSL_CTX; u: SslPtr);
begin
  if InitSSLInterface and Assigned(_SslCtxSetDefaultPasswdCbUserdata) then
    _SslCtxSetDefaultPasswdCbUserdata(ctx, u);
end;

//function SslCtxLoadVerifyLocations(ctx: PSSL_CTX; const CAfile: PChar; const CApath: PChar):Integer;
FUNCTION SslCtxLoadVerifyLocations(ctx: PSSL_CTX; CONST CAfile: ansistring; CONST CApath: ansistring):integer;
begin
  if InitSSLInterface and Assigned(_SslCtxLoadVerifyLocations) then
    result := _SslCtxLoadVerifyLocations(ctx, SslPtr(CAfile), SslPtr(CApath))
  else
    result := 0;
end;

FUNCTION SslCtxCtrl(ctx: PSSL_CTX; cmd: integer; larg: integer; parg: SslPtr): integer;
begin
  if InitSSLInterface and Assigned(_SslCtxCtrl) then
    result := _SslCtxCtrl(ctx, cmd, larg, parg)
  else
    result := 0;
end;

FUNCTION SslNew(ctx: PSSL_CTX):PSSL;
begin
  if InitSSLInterface and Assigned(_SslNew) then
    result := _SslNew(ctx)
  else
    result := nil;
end;

PROCEDURE SslFree(ssl: PSSL);
begin
  if InitSSLInterface and Assigned(_SslFree) then
    _SslFree(ssl);
end;

FUNCTION SslAccept(ssl: PSSL):integer;
begin
  if InitSSLInterface and Assigned(_SslAccept) then
    result := _SslAccept(ssl)
  else
    result := -1;
end;

FUNCTION SslConnect(ssl: PSSL):integer;
begin
  if InitSSLInterface and Assigned(_SslConnect) then
    result := _SslConnect(ssl)
  else
    result := -1;
end;

FUNCTION SslShutdown(ssl: PSSL):integer;
begin
  if InitSSLInterface and Assigned(_SslShutdown) then
    result := _SslShutdown(ssl)
  else
    result := -1;
end;

//function SslRead(ssl: PSSL; buf: PChar; num: Integer):Integer;
FUNCTION SslRead(ssl: PSSL; Buf: SslPtr; num: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslRead) then
    result := _SslRead(ssl, PAnsiChar(Buf), num)
  else
    result := -1;
end;

//function SslPeek(ssl: PSSL; buf: PChar; num: Integer):Integer;
FUNCTION SslPeek(ssl: PSSL; Buf: SslPtr; num: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslPeek) then
    result := _SslPeek(ssl, PAnsiChar(Buf), num)
  else
    result := -1;
end;

//function SslWrite(ssl: PSSL; const buf: PChar; num: Integer):Integer;
FUNCTION SslWrite(ssl: PSSL; Buf: SslPtr; num: integer):integer;
begin
  if InitSSLInterface and Assigned(_SslWrite) then
    result := _SslWrite(ssl, PAnsiChar(Buf), num)
  else
    result := -1;
end;

FUNCTION SslPending(ssl: PSSL):integer;
begin
  if InitSSLInterface and Assigned(_SslPending) then
    result := _SslPending(ssl)
  else
    result := 0;
end;

//function SslGetVersion(ssl: PSSL):PChar;
FUNCTION SslGetVersion(ssl: PSSL):ansistring;
begin
  if InitSSLInterface and Assigned(_SslGetVersion) then
    result := _SslGetVersion(ssl)
  else
    result := '';
end;

FUNCTION SslGetPeerCertificate(ssl: PSSL):PX509;
begin
  if InitSSLInterface and Assigned(_SslGetPeerCertificate) then
    result := _SslGetPeerCertificate(ssl)
  else
    result := nil;
end;

//procedure SslCtxSetVerify(ctx: PSSL_CTX; mode: Integer; arg2: SslPtr);
PROCEDURE SslCtxSetVerify(ctx: PSSL_CTX; mode: integer; arg2: PFunction);
begin
  if InitSSLInterface and Assigned(_SslCtxSetVerify) then
    _SslCtxSetVerify(ctx, mode, @arg2);
end;

FUNCTION SSLGetCurrentCipher(s: PSSL):SslPtr;
begin
  if InitSSLInterface and Assigned(_SSLGetCurrentCipher) then
{$IFDEF CIL}
{$ELSE}
    result := _SSLGetCurrentCipher(s)
{$ENDIF}
  else
    result := nil;
end;

//function SSLCipherGetName(c: SslPtr):PChar;
FUNCTION SSLCipherGetName(c: SslPtr):ansistring;
begin
  if InitSSLInterface and Assigned(_SSLCipherGetName) then
    result := _SSLCipherGetName(c)
  else
    result := '';
end;

//function SSLCipherGetBits(c: SslPtr; alg_bits: PInteger):Integer;
FUNCTION SSLCipherGetBits(c: SslPtr; VAR alg_bits: integer):integer;
begin
  if InitSSLInterface and Assigned(_SSLCipherGetBits) then
    result := _SSLCipherGetBits(c, @alg_bits)
  else
    result := 0;
end;

FUNCTION SSLGetVerifyResult(ssl: PSSL):integer;
begin
  if InitSSLInterface and Assigned(_SSLGetVerifyResult) then
    result := _SSLGetVerifyResult(ssl)
  else
    result := X509_V_ERR_APPLICATION_VERIFICATION;
end;


FUNCTION SSLCtrl(ssl: PSSL; cmd: integer; larg: integer; parg: SslPtr):integer;
begin
  if InitSSLInterface and Assigned(_SSLCtrl) then
    result := _SSLCtrl(ssl, cmd, larg, parg)
  else
    result := X509_V_ERR_APPLICATION_VERIFICATION;
end;

// libeay.dll
FUNCTION X509New: PX509;
begin
  if InitSSLInterface and Assigned(_X509New) then
    result := _X509New
  else
    result := nil;
end;

PROCEDURE X509Free(x: PX509);
begin
  if InitSSLInterface and Assigned(_X509Free) then
    _X509Free(x);
end;

//function SslX509NameOneline(a: PX509_NAME; buf: PChar; size: Integer):PChar;
FUNCTION X509NameOneline(a: PX509_NAME; VAR Buf: ansistring; size: integer):ansistring;
begin
  if InitSSLInterface and Assigned(_X509NameOneline) then
    result := _X509NameOneline(a, PAnsiChar(Buf),size)
  else
    result := '';
end;

FUNCTION X509GetSubjectName(a: PX509):PX509_NAME;
begin
  if InitSSLInterface and Assigned(_X509GetSubjectName) then
    result := _X509GetSubjectName(a)
  else
    result := nil;
end;

FUNCTION X509GetIssuerName(a: PX509):PX509_NAME;
begin
  if InitSSLInterface and Assigned(_X509GetIssuerName) then
    result := _X509GetIssuerName(a)
  else
    result := nil;
end;

FUNCTION X509NameHash(x: PX509_NAME):Cardinal;
begin
  if InitSSLInterface and Assigned(_X509NameHash) then
    result := _X509NameHash(x)
  else
    result := 0;
end;

//function SslX509Digest(data: PX509; _type: PEVP_MD; md: PChar; len: PInteger):Integer;
FUNCTION X509Digest(data: PX509; _TYPE: PEVP_MD; md: ansistring; VAR len: integer):integer;
begin
  if InitSSLInterface and Assigned(_X509Digest) then
    result := _X509Digest(data, _TYPE, PAnsiChar(md), @len)
  else
    result := 0;
end;

FUNCTION EvpPkeyNew: EVP_PKEY;
begin
  if InitSSLInterface and Assigned(_EvpPkeyNew) then
    result := _EvpPkeyNew
  else
    result := nil;
end;

PROCEDURE EvpPkeyFree(pk: EVP_PKEY);
begin
  if InitSSLInterface and Assigned(_EvpPkeyFree) then
    _EvpPkeyFree(pk);
end;

FUNCTION SSLeayversion(t: integer): ansistring;
begin
  if InitSSLInterface and Assigned(_SSLeayversion) then
    result := PAnsiChar(_SSLeayversion(t))
  else
    result := '';
end;

PROCEDURE ErrErrorString(e: integer; VAR Buf: ansistring; len: integer);
begin
  if InitSSLInterface and Assigned(_ErrErrorString) then
    _ErrErrorString(e, pointer(Buf), len);
  Buf := PAnsiChar(Buf);
end;

FUNCTION ErrGetError: integer;
begin
  if InitSSLInterface and Assigned(_ErrGetError) then
    result := _ErrGetError
  else
    result := SSL_ERROR_SSL;
end;

PROCEDURE ErrClearError;
begin
  if InitSSLInterface and Assigned(_ErrClearError) then
    _ErrClearError;
end;

PROCEDURE ErrFreeStrings;
begin
  if InitSSLInterface and Assigned(_ErrFreeStrings) then
    _ErrFreeStrings;
end;

PROCEDURE ErrRemoveState(pid: integer);
begin
  if InitSSLInterface and Assigned(_ErrRemoveState) then
    _ErrRemoveState(pid);
end;

PROCEDURE OPENSSLaddallalgorithms;
begin
  if InitSSLInterface and Assigned(_OPENSSLaddallalgorithms) then
    _OPENSSLaddallalgorithms;
end;

PROCEDURE EVPcleanup;
begin
  if InitSSLInterface and Assigned(_EVPcleanup) then
    _EVPcleanup;
end;

PROCEDURE CRYPTOcleanupAllExData;
begin
  if InitSSLInterface and Assigned(_CRYPTOcleanupAllExData) then
    _CRYPTOcleanupAllExData;
end;

PROCEDURE RandScreen;
begin
  if InitSSLInterface and Assigned(_RandScreen) then
    _RandScreen;
end;

FUNCTION BioNew(b: PBIO_METHOD): PBIO;
begin
  if InitSSLInterface and Assigned(_BioNew) then
    result := _BioNew(b)
  else
    result := nil;
end;

PROCEDURE BioFreeAll(b: PBIO);
begin
  if InitSSLInterface and Assigned(_BioFreeAll) then
    _BioFreeAll(b);
end;

FUNCTION BioSMem: PBIO_METHOD;
begin
  if InitSSLInterface and Assigned(_BioSMem) then
    result := _BioSMem
  else
    result := nil;
end;

FUNCTION BioCtrlPending(b: PBIO): integer;
begin
  if InitSSLInterface and Assigned(_BioCtrlPending) then
    result := _BioCtrlPending(b)
  else
    result := 0;
end;

//function BioRead(b: PBIO; Buf: PChar; Len: integer): integer;
FUNCTION BioRead(b: PBIO; VAR Buf: ansistring; len: integer): integer;
begin
  if InitSSLInterface and Assigned(_BioRead) then
    result := _BioRead(b, PAnsiChar(Buf), len)
  else
    result := -2;
end;

//function BioWrite(b: PBIO; Buf: PChar; Len: integer): integer;
FUNCTION BioWrite(b: PBIO; Buf: ansistring; len: integer): integer;
begin
  if InitSSLInterface and Assigned(_BioWrite) then
    result := _BioWrite(b, PAnsiChar(Buf), len)
  else
    result := -2;
end;

FUNCTION X509print(b: PBIO; a: PX509): integer;
begin
  if InitSSLInterface and Assigned(_X509print) then
    result := _X509print(b, a)
  else
    result := 0;
end;

FUNCTION d2iPKCS12bio(b:PBIO; Pkcs12: SslPtr): SslPtr;
begin
  if InitSSLInterface and Assigned(_d2iPKCS12bio) then
    result := _d2iPKCS12bio(b, Pkcs12)
  else
    result := nil;
end;

FUNCTION PKCS12parse(p12: SslPtr; pass: ansistring; VAR pkey, cert, ca: SslPtr): integer;
begin
  if InitSSLInterface and Assigned(_PKCS12parse) then
    result := _PKCS12parse(p12, SslPtr(pass), pkey, cert, ca)
  else
    result := 0;
end;

PROCEDURE PKCS12free(p12: SslPtr);
begin
  if InitSSLInterface and Assigned(_PKCS12free) then
    _PKCS12free(p12);
end;

FUNCTION RsaGenerateKey(bits, e: integer; callback: PFunction; cb_arg: SslPtr): PRSA;
begin
  if InitSSLInterface and Assigned(_RsaGenerateKey) then
    result := _RsaGenerateKey(bits, e, callback, cb_arg)
  else
    result := nil;
end;

FUNCTION EvpPkeyAssign(pkey: EVP_PKEY; _TYPE: integer; key: Prsa): integer;
begin
  if InitSSLInterface and Assigned(_EvpPkeyAssign) then
    result := _EvpPkeyAssign(pkey, _TYPE, key)
  else
    result := 0;
end;

FUNCTION X509SetVersion(x: PX509; version: integer): integer;
begin
  if InitSSLInterface and Assigned(_X509SetVersion) then
    result := _X509SetVersion(x, version)
  else
    result := 0;
end;

FUNCTION X509SetPubkey(x: PX509; pkey: EVP_PKEY): integer;
begin
  if InitSSLInterface and Assigned(_X509SetPubkey) then
    result := _X509SetPubkey(x, pkey)
  else
    result := 0;
end;

FUNCTION X509SetIssuerName(x: PX509; name: PX509_NAME): integer;
begin
  if InitSSLInterface and Assigned(_X509SetIssuerName) then
    result := _X509SetIssuerName(x, name)
  else
    result := 0;
end;

FUNCTION X509NameAddEntryByTxt(name: PX509_NAME; field: ansistring; _TYPE: integer;
  bytes: ansistring; len, loc, _set: integer): integer;
begin
  if InitSSLInterface and Assigned(_X509NameAddEntryByTxt) then
    result := _X509NameAddEntryByTxt(name, PAnsiChar(field), _TYPE, PAnsiChar(Bytes), len, loc, _set)
  else
    result := 0;
end;

FUNCTION X509Sign(x: PX509; pkey: EVP_PKEY; CONST md: PEVP_MD): integer;
begin
  if InitSSLInterface and Assigned(_X509Sign) then
    result := _X509Sign(x, pkey, md)
  else
    result := 0;
end;

FUNCTION Asn1UtctimeNew: PASN1_UTCTIME;
begin
  if InitSSLInterface and Assigned(_Asn1UtctimeNew) then
    result := _Asn1UtctimeNew
  else
    result := nil;
end;

PROCEDURE Asn1UtctimeFree(a: PASN1_UTCTIME);
begin
  if InitSSLInterface and Assigned(_Asn1UtctimeFree) then
    _Asn1UtctimeFree(a);
end;

FUNCTION X509GmtimeAdj(s: PASN1_UTCTIME; adj: integer): PASN1_UTCTIME;
begin
  if InitSSLInterface and Assigned(_X509GmtimeAdj) then
    result := _X509GmtimeAdj(s, adj)
  else
    result := nil;
end;

FUNCTION X509SetNotBefore(x: PX509; tm: PASN1_UTCTIME): integer;
begin
  if InitSSLInterface and Assigned(_X509SetNotBefore) then
    result := _X509SetNotBefore(x, tm)
  else
    result := 0;
end;

FUNCTION X509SetNotAfter(x: PX509; tm: PASN1_UTCTIME): integer;
begin
  if InitSSLInterface and Assigned(_X509SetNotAfter) then
    result := _X509SetNotAfter(x, tm)
  else
    result := 0;
end;

FUNCTION i2dX509bio(b: PBIO; x: PX509): integer;
begin
  if InitSSLInterface and Assigned(_i2dX509bio) then
    result := _i2dX509bio(b, x)
  else
    result := 0;
end;

FUNCTION d2iX509bio(b: PBIO; x: PX509): PX509; {pf}
begin
  if InitSSLInterface and Assigned(_d2iX509bio) then
    result := _d2iX509bio(x,b)
  else
    result := nil;
end;

FUNCTION PEMReadBioX509(b:PBIO; {var x:PX509;}x:PSslPtr; callback:PFunction; cb_arg: SslPtr):  PX509;    {pf}
begin
  if InitSSLInterface and Assigned(_PEMReadBioX509) then
    result := _PEMReadBioX509(b,x,callback,cb_arg)
  else
    result := nil;
end;

PROCEDURE SkX509PopFree(st: PSTACK; func:TSkPopFreeFunc); {pf}
begin
  if InitSSLInterface and Assigned(_SkX509PopFree) then
    _SkX509PopFree(st,func);
end;

FUNCTION i2dPrivateKeyBio(b: PBIO; pkey: EVP_PKEY): integer;
begin
  if InitSSLInterface and Assigned(_i2dPrivateKeyBio) then
    result := _i2dPrivateKeyBio(b, pkey)
  else
    result := 0;
end;

FUNCTION EvpGetDigestByName(name: ansistring): PEVP_MD;
begin
  if InitSSLInterface and Assigned(_EvpGetDigestByName) then
    result := _EvpGetDigestByName(PAnsiChar(name))
  else
    result := nil;
end;

FUNCTION Asn1IntegerSet(a: PASN1_INTEGER; v: integer): integer;
begin
  if InitSSLInterface and Assigned(_Asn1IntegerSet) then
    result := _Asn1IntegerSet(a, v)
  else
    result := 0;
end;

FUNCTION Asn1IntegerGet(a: PASN1_INTEGER): integer; {pf}
begin
  if InitSSLInterface and Assigned(_Asn1IntegerGet) then
    result := _Asn1IntegerGet(a)
  else
    result := 0;
end;

FUNCTION X509GetSerialNumber(x: PX509): PASN1_INTEGER;
begin
  if InitSSLInterface and Assigned(_X509GetSerialNumber) then
    result := _X509GetSerialNumber(x)
  else
    result := nil;
end;

// 3DES functions
PROCEDURE DESsetoddparity(key: des_cblock);
begin
  if InitSSLInterface and Assigned(_DESsetoddparity) then
    _DESsetoddparity(key);
end;

FUNCTION DESsetkeychecked(key: des_cblock; schedule: des_key_schedule): integer;
begin
  if InitSSLInterface and Assigned(_DESsetkeychecked) then
    result := _DESsetkeychecked(key, schedule)
  else
    result := -1;
end;

PROCEDURE DESecbencrypt(input: des_cblock; output: des_cblock; ks: des_key_schedule; enc: integer);
begin
  if InitSSLInterface and Assigned(_DESecbencrypt) then
    _DESecbencrypt(input, output, ks, enc);
end;

PROCEDURE locking_callback(mode, ltype: integer; lfile: PChar; line: integer); cdecl;
begin
  if (mode and 1) > 0 then
    TCriticalSection(Locks[ltype]).Enter
  else
    TCriticalSection(Locks[ltype]).Leave;
end;

PROCEDURE InitLocks;
VAR
  n: integer;
  max: integer;
begin
  Locks := TList.create;
  max := _CRYPTOnumlocks;
  for n := 1 to max do
    Locks.add(TCriticalSection.create);
  _CRYPTOsetlockingcallback(@locking_callback);
end;

PROCEDURE FreeLocks;
VAR
  n: integer;
begin
  _CRYPTOsetlockingcallback(nil);
  for n := 0 to Locks.count - 1 do
    TCriticalSection(Locks[n]).free;
  Locks.free;
end;

{$ENDIF}

FUNCTION LoadLib(CONST value: string): HModule;
begin
{$IFDEF CIL}
  result := LoadLibrary(value);
{$ELSE}
  result := LoadLibrary(PChar(value));
{$ENDIF}
end;

FUNCTION GetProcAddr(module: HModule; CONST ProcName: string): SslPtr;
begin
{$IFDEF CIL}
  result := GetProcAddress(module, ProcName);
{$ELSE}
  result := GetProcAddress(module, PChar(ProcName));
{$ENDIF}
end;

FUNCTION InitSSLInterface: boolean;
VAR
  s: string;
  x: integer;
begin
  {pf}
  if SSLLoaded then
    begin
      result := true;
      exit;
    end;
  {/pf}
  SSLCS.Enter;
  try
    if not IsSSLloaded then
    begin
{$IFDEF CIL}
      SSLLibHandle := 1;
      SSLUtilHandle := 1;
{$ELSE}
      SSLLibHandle := LoadLib(DLLSSLName);
      SSLUtilHandle := LoadLib(DLLUtilName);
  {$IFDEF MSWINDOWS}
      if (SSLLibHandle = 0) then
        SSLLibHandle := LoadLib(DLLSSLName2);
  {$ENDIF}
{$ENDIF}
      if (SSLLibHandle <> 0) and (SSLUtilHandle <> 0) then
      begin
{$IFNDEF CIL}
        _SslGetError := GetProcAddr(SSLLibHandle, 'SSL_get_error');
        _SslLibraryInit := GetProcAddr(SSLLibHandle, 'SSL_library_init');
        _SslLoadErrorStrings := GetProcAddr(SSLLibHandle, 'SSL_load_error_strings');
        _SslCtxSetCipherList := GetProcAddr(SSLLibHandle, 'SSL_CTX_set_cipher_list');
        _SslCtxNew := GetProcAddr(SSLLibHandle, 'SSL_CTX_new');
        _SslCtxFree := GetProcAddr(SSLLibHandle, 'SSL_CTX_free');
        _SslSetFd := GetProcAddr(SSLLibHandle, 'SSL_set_fd');
        _SslMethodV2 := GetProcAddr(SSLLibHandle, 'SSLv2_method');
        _SslMethodV3 := GetProcAddr(SSLLibHandle, 'SSLv3_method');
        _SslMethodTLSV1 := GetProcAddr(SSLLibHandle, 'TLSv1_method');
        _SslMethodV23 := GetProcAddr(SSLLibHandle, 'SSLv23_method');
        _SslCtxUsePrivateKey := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_PrivateKey');
        _SslCtxUsePrivateKeyASN1 := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_PrivateKey_ASN1');
        //use SSL_CTX_use_RSAPrivateKey_file instead SSL_CTX_use_PrivateKey_file,
        //because SSL_CTX_use_PrivateKey_file not support DER format. :-O
        _SslCtxUsePrivateKeyFile := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_RSAPrivateKey_file');
        _SslCtxUseCertificate := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_certificate');
        _SslCtxUseCertificateASN1 := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_certificate_ASN1');
        _SslCtxUseCertificateFile := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_certificate_file');
        _SslCtxUseCertificateChainFile := GetProcAddr(SSLLibHandle, 'SSL_CTX_use_certificate_chain_file');
        _SslCtxCheckPrivateKeyFile := GetProcAddr(SSLLibHandle, 'SSL_CTX_check_private_key');
        _SslCtxSetDefaultPasswdCb := GetProcAddr(SSLLibHandle, 'SSL_CTX_set_default_passwd_cb');
        _SslCtxSetDefaultPasswdCbUserdata := GetProcAddr(SSLLibHandle, 'SSL_CTX_set_default_passwd_cb_userdata');
        _SslCtxLoadVerifyLocations := GetProcAddr(SSLLibHandle, 'SSL_CTX_load_verify_locations');
        _SslCtxCtrl := GetProcAddr(SSLLibHandle, 'SSL_CTX_ctrl');
        _SslNew := GetProcAddr(SSLLibHandle, 'SSL_new');
        _SslFree := GetProcAddr(SSLLibHandle, 'SSL_free');
        _SslAccept := GetProcAddr(SSLLibHandle, 'SSL_accept');
        _SslConnect := GetProcAddr(SSLLibHandle, 'SSL_connect');
        _SslShutdown := GetProcAddr(SSLLibHandle, 'SSL_shutdown');
        _SslRead := GetProcAddr(SSLLibHandle, 'SSL_read');
        _SslPeek := GetProcAddr(SSLLibHandle, 'SSL_peek');
        _SslWrite := GetProcAddr(SSLLibHandle, 'SSL_write');
        _SslPending := GetProcAddr(SSLLibHandle, 'SSL_pending');
        _SslGetPeerCertificate := GetProcAddr(SSLLibHandle, 'SSL_get_peer_certificate');
        _SslGetVersion := GetProcAddr(SSLLibHandle, 'SSL_get_version');
        _SslCtxSetVerify := GetProcAddr(SSLLibHandle, 'SSL_CTX_set_verify');
        _SslGetCurrentCipher := GetProcAddr(SSLLibHandle, 'SSL_get_current_cipher');
        _SslCipherGetName := GetProcAddr(SSLLibHandle, 'SSL_CIPHER_get_name');
        _SslCipherGetBits := GetProcAddr(SSLLibHandle, 'SSL_CIPHER_get_bits');
        _SslGetVerifyResult := GetProcAddr(SSLLibHandle, 'SSL_get_verify_result');
        _SslCtrl := GetProcAddr(SSLLibHandle, 'SSL_ctrl');

        _X509New := GetProcAddr(SSLUtilHandle, 'X509_new');
        _X509Free := GetProcAddr(SSLUtilHandle, 'X509_free');
        _X509NameOneline := GetProcAddr(SSLUtilHandle, 'X509_NAME_oneline');
        _X509GetSubjectName := GetProcAddr(SSLUtilHandle, 'X509_get_subject_name');
        _X509GetIssuerName := GetProcAddr(SSLUtilHandle, 'X509_get_issuer_name');
        _X509NameHash := GetProcAddr(SSLUtilHandle, 'X509_NAME_hash');
        _X509Digest := GetProcAddr(SSLUtilHandle, 'X509_digest');
        _X509print := GetProcAddr(SSLUtilHandle, 'X509_print');
        _X509SetVersion := GetProcAddr(SSLUtilHandle, 'X509_set_version');
        _X509SetPubkey := GetProcAddr(SSLUtilHandle, 'X509_set_pubkey');
        _X509SetIssuerName := GetProcAddr(SSLUtilHandle, 'X509_set_issuer_name');
        _X509NameAddEntryByTxt := GetProcAddr(SSLUtilHandle, 'X509_NAME_add_entry_by_txt');
        _X509Sign := GetProcAddr(SSLUtilHandle, 'X509_sign');
        _X509GmtimeAdj := GetProcAddr(SSLUtilHandle, 'X509_gmtime_adj');
        _X509SetNotBefore := GetProcAddr(SSLUtilHandle, 'X509_set_notBefore');
        _X509SetNotAfter := GetProcAddr(SSLUtilHandle, 'X509_set_notAfter');
        _X509GetSerialNumber := GetProcAddr(SSLUtilHandle, 'X509_get_serialNumber');
        _EvpPkeyNew := GetProcAddr(SSLUtilHandle, 'EVP_PKEY_new');
        _EvpPkeyFree := GetProcAddr(SSLUtilHandle, 'EVP_PKEY_free');
        _EvpPkeyAssign := GetProcAddr(SSLUtilHandle, 'EVP_PKEY_assign');
        _EVPCleanup := GetProcAddr(SSLUtilHandle, 'EVP_cleanup');
        _EvpGetDigestByName := GetProcAddr(SSLUtilHandle, 'EVP_get_digestbyname');
        _SSLeayversion := GetProcAddr(SSLUtilHandle, 'SSLeay_version');
        _ErrErrorString := GetProcAddr(SSLUtilHandle, 'ERR_error_string_n');
        _ErrGetError := GetProcAddr(SSLUtilHandle, 'ERR_get_error');
        _ErrClearError := GetProcAddr(SSLUtilHandle, 'ERR_clear_error');
        _ErrFreeStrings := GetProcAddr(SSLUtilHandle, 'ERR_free_strings');
        _ErrRemoveState := GetProcAddr(SSLUtilHandle, 'ERR_remove_state');
        _OPENSSLaddallalgorithms := GetProcAddr(SSLUtilHandle, 'OPENSSL_add_all_algorithms_noconf');
        _CRYPTOcleanupAllExData := GetProcAddr(SSLUtilHandle, 'CRYPTO_cleanup_all_ex_data');
        _RandScreen := GetProcAddr(SSLUtilHandle, 'RAND_screen');
        _BioNew := GetProcAddr(SSLUtilHandle, 'BIO_new');
        _BioFreeAll := GetProcAddr(SSLUtilHandle, 'BIO_free_all');
        _BioSMem := GetProcAddr(SSLUtilHandle, 'BIO_s_mem');
        _BioCtrlPending := GetProcAddr(SSLUtilHandle, 'BIO_ctrl_pending');
        _BioRead := GetProcAddr(SSLUtilHandle, 'BIO_read');
        _BioWrite := GetProcAddr(SSLUtilHandle, 'BIO_write');
        _d2iPKCS12bio := GetProcAddr(SSLUtilHandle, 'd2i_PKCS12_bio');
        _PKCS12parse := GetProcAddr(SSLUtilHandle, 'PKCS12_parse');
        _PKCS12free := GetProcAddr(SSLUtilHandle, 'PKCS12_free');
        _RsaGenerateKey := GetProcAddr(SSLUtilHandle, 'RSA_generate_key');
        _Asn1UtctimeNew := GetProcAddr(SSLUtilHandle, 'ASN1_UTCTIME_new');
        _Asn1UtctimeFree := GetProcAddr(SSLUtilHandle, 'ASN1_UTCTIME_free');
        _Asn1IntegerSet := GetProcAddr(SSLUtilHandle, 'ASN1_INTEGER_set');
        _Asn1IntegerGet := GetProcAddr(SSLUtilHandle, 'ASN1_INTEGER_get'); {pf}
        _i2dX509bio := GetProcAddr(SSLUtilHandle, 'i2d_X509_bio');
        _d2iX509bio := GetProcAddr(SSLUtilHandle, 'd2i_X509_bio'); {pf}
        _PEMReadBioX509 := GetProcAddr(SSLUtilHandle, 'PEM_read_bio_X509'); {pf}
        _SkX509PopFree := GetProcAddr(SSLUtilHandle, 'SK_X509_POP_FREE'); {pf}
        _i2dPrivateKeyBio := GetProcAddr(SSLUtilHandle, 'i2d_PrivateKey_bio');

        // 3DES functions
        _DESsetoddparity := GetProcAddr(SSLUtilHandle, 'DES_set_odd_parity');
        _DESsetkeychecked := GetProcAddr(SSLUtilHandle, 'DES_set_key_checked');
        _DESecbencrypt := GetProcAddr(SSLUtilHandle, 'DES_ecb_encrypt');
        //
        _CRYPTOnumlocks := GetProcAddr(SSLUtilHandle, 'CRYPTO_num_locks');
        _CRYPTOsetlockingcallback := GetProcAddr(SSLUtilHandle, 'CRYPTO_set_locking_callback');
{$ENDIF}
{$IFDEF CIL}
        SslLibraryInit;
        SslLoadErrorStrings;
        OPENSSLaddallalgorithms;
        RandScreen;
{$ELSE}
        setLength(s, 1024);
        x := GetModuleFilename(SSLLibHandle,PChar(s),length(s));
        setLength(s, x);
        SSLLibFile := s;
        setLength(s, 1024);
        x := GetModuleFilename(SSLUtilHandle,PChar(s),length(s));
        setLength(s, x);
        SSLUtilFile := s;
        //init library
        if assigned(_SslLibraryInit) then
          _SslLibraryInit;
        if assigned(_SslLoadErrorStrings) then
          _SslLoadErrorStrings;
        if assigned(_OPENSSLaddallalgorithms) then
          _OPENSSLaddallalgorithms;
        if assigned(_RandScreen) then
          _RandScreen;
        if assigned(_CRYPTOnumlocks) and assigned(_CRYPTOsetlockingcallback) then
          InitLocks;
{$ENDIF}
        result := true;
        SSLloaded := true;
      end
      else
      begin
        //load failed!
        if SSLLibHandle <> 0 then
        begin
{$IFNDEF CIL}
          FreeLibrary(SSLLibHandle);
{$ENDIF}
          SSLLibHandle := 0;
        end;
        if SSLUtilHandle <> 0 then
        begin
{$IFNDEF CIL}
          FreeLibrary(SSLUtilHandle);
{$ENDIF}
          SSLLibHandle := 0;
        end;
        result := false;
      end;
    end
    else
      //loaded before...
      result := true;
  finally
    SSLCS.Leave;
  end;
end;

FUNCTION DestroySSLInterface: boolean;
begin
  SSLCS.Enter;
  try
    if IsSSLLoaded then
    begin
      //deinit library
{$IFNDEF CIL}
      if assigned(_CRYPTOnumlocks) and assigned(_CRYPTOsetlockingcallback) then
        FreeLocks;
{$ENDIF}
      EVPCleanup;
      CRYPTOcleanupAllExData;
      ErrRemoveState(0);
    end;
    SSLloaded := false;
    if SSLLibHandle <> 0 then
    begin
{$IFNDEF CIL}
      FreeLibrary(SSLLibHandle);
{$ENDIF}
      SSLLibHandle := 0;
    end;
    if SSLUtilHandle <> 0 then
    begin
{$IFNDEF CIL}
      FreeLibrary(SSLUtilHandle);
{$ENDIF}
      SSLLibHandle := 0;
    end;

{$IFNDEF CIL}
    _SslGetError := nil;
    _SslLibraryInit := nil;
    _SslLoadErrorStrings := nil;
    _SslCtxSetCipherList := nil;
    _SslCtxNew := nil;
    _SslCtxFree := nil;
    _SslSetFd := nil;
    _SslMethodV2 := nil;
    _SslMethodV3 := nil;
    _SslMethodTLSV1 := nil;
    _SslMethodV23 := nil;
    _SslCtxUsePrivateKey := nil;
    _SslCtxUsePrivateKeyASN1 := nil;
    _SslCtxUsePrivateKeyFile := nil;
    _SslCtxUseCertificate := nil;
    _SslCtxUseCertificateASN1 := nil;
    _SslCtxUseCertificateFile := nil;
    _SslCtxUseCertificateChainFile := nil;
    _SslCtxCheckPrivateKeyFile := nil;
    _SslCtxSetDefaultPasswdCb := nil;
    _SslCtxSetDefaultPasswdCbUserdata := nil;
    _SslCtxLoadVerifyLocations := nil;
    _SslCtxCtrl := nil;
    _SslNew := nil;
    _SslFree := nil;
    _SslAccept := nil;
    _SslConnect := nil;
    _SslShutdown := nil;
    _SslRead := nil;
    _SslPeek := nil;
    _SslWrite := nil;
    _SslPending := nil;
    _SslGetPeerCertificate := nil;
    _SslGetVersion := nil;
    _SslCtxSetVerify := nil;
    _SslGetCurrentCipher := nil;
    _SslCipherGetName := nil;
    _SslCipherGetBits := nil;
    _SslGetVerifyResult := nil;
    _SslCtrl := nil;

    _X509New := nil;
    _X509Free := nil;
    _X509NameOneline := nil;
    _X509GetSubjectName := nil;
    _X509GetIssuerName := nil;
    _X509NameHash := nil;
    _X509Digest := nil;
    _X509print := nil;
    _X509SetVersion := nil;
    _X509SetPubkey := nil;
    _X509SetIssuerName := nil;
    _X509NameAddEntryByTxt := nil;
    _X509Sign := nil;
    _X509GmtimeAdj := nil;
    _X509SetNotBefore := nil;
    _X509SetNotAfter := nil;
    _X509GetSerialNumber := nil;
    _EvpPkeyNew := nil;
    _EvpPkeyFree := nil;
    _EvpPkeyAssign := nil;
    _EVPCleanup := nil;
    _EvpGetDigestByName := nil;
    _SSLeayversion := nil;
    _ErrErrorString := nil;
    _ErrGetError := nil;
    _ErrClearError := nil;
    _ErrFreeStrings := nil;
    _ErrRemoveState := nil;
    _OPENSSLaddallalgorithms := nil;
    _CRYPTOcleanupAllExData := nil;
    _RandScreen := nil;
    _BioNew := nil;
    _BioFreeAll := nil;
    _BioSMem := nil;
    _BioCtrlPending := nil;
    _BioRead := nil;
    _BioWrite := nil;
    _d2iPKCS12bio := nil;
    _PKCS12parse := nil;
    _PKCS12free := nil;
    _RsaGenerateKey := nil;
    _Asn1UtctimeNew := nil;
    _Asn1UtctimeFree := nil;
    _Asn1IntegerSet := nil;
    _Asn1IntegerGet := nil; {pf}
    _SkX509PopFree := nil; {pf}
    _i2dX509bio := nil;
    _i2dPrivateKeyBio := nil;

    // 3DES functions
    _DESsetoddparity := nil;
    _DESsetkeychecked := nil;
    _DESecbencrypt := nil;
    //
    _CRYPTOnumlocks := nil;
    _CRYPTOsetlockingcallback := nil;
{$ENDIF}
  finally
    SSLCS.Leave;
  end;
  result := true;
end;

FUNCTION IsSSLloaded: boolean;
begin
  result := SSLLoaded;
end;

INITIALIZATION
begin
  SSLCS:= TCriticalSection.create;
end;

FINALIZATION
begin
{$IFNDEF CIL}
  DestroySSLInterface;
{$ENDIF}
  SSLCS.free;
end;

end.
