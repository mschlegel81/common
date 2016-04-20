{==============================================================================|
| project : Ararat Synapse                                       | 001.000.003 |
|==============================================================================|
| content: SSL support for SecureBlackBox                                     |
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
|   Allen Drennan (adrennan@wiredred.com)                                      |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(SSL plugin for Eldos SecureBlackBox)

for handling keys and certificates you can use this properties:
@link(TCustomSSL.CertCAFile), @link(TCustomSSL.CertCA),
@link(TCustomSSL.TrustCertificateFile), @link(TCustomSSL.TrustCertificate),
@link(TCustomSSL.PrivateKeyFile), @link(TCustomSSL.PrivateKey),
@link(TCustomSSL.CertificateFile), @link(TCustomSSL.Certificate),
@link(TCustomSSL.PFXFile). for usage of this properties and for possible formats
of keys and certificates refer to SecureBlackBox documentation.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

UNIT ssl_sbb;

INTERFACE

USES
  sysutils, Classes, windows, blcksock, synsock, synautil, synacode,
  SBClient, SBServer, SBX509, SBWinCertStorage, SBCustomCertStorage,
  SBUtils, SBConstants, SBSessionPool;

CONST
  DEFAULT_RECV_BUFFER=32768;

TYPE
  {:@abstract(class implementing SecureBlackbox SSL plugin.)
   instance of this class will be created for each @link(TTCPBlockSocket).
   You not need to create instance of this class, all is done by Synapse itself!}
  TSSLSBB=class(TCustomSSL)
  protected
    FServer: boolean;
    FElSecureClient:TElSecureClient;
    FElSecureServer:TElSecureServer;
    FElCertStorage:TElMemoryCertStorage;
    FElX509Certificate:TElX509Certificate;
    FElX509CACertificate:TElX509Certificate;
    FCipherSuites:TBits;
  private
    FRecvBuffer:string;
    FRecvBuffers:string;
    FRecvBuffersLock:TRTLCriticalSection;
    FRecvDecodedBuffers:string;
    FUNCTION GetCipherSuite:integer;
    PROCEDURE reset;
    FUNCTION Prepare(Server:boolean):boolean;
    PROCEDURE OnError(Sender:TObject; ErrorCode:integer; Fatal:boolean; Remote:boolean);
    PROCEDURE OnSend(Sender:TObject;buffer:pointer;size:longint);
    PROCEDURE OnReceive(Sender:TObject;buffer:pointer;MaxSize:longint;VAR Written:longint);
    PROCEDURE OnData(Sender:TObject;buffer:pointer;size:longint);
  public
    CONSTRUCTOR create(CONST value: TTCPBlockSocket); override;
    DESTRUCTOR destroy; override;
    {:See @inherited}
    FUNCTION LibVersion: string; override;
    {:See @inherited}
    FUNCTION LibName: string; override;
    {:See @inherited and @link(ssl_sbb) for more details.}
    FUNCTION Connect: boolean; override;
    {:See @inherited and @link(ssl_sbb) for more details.}
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
    PROPERTY ElSecureClient:TElSecureClient read FElSecureClient write FElSecureClient;
    PROPERTY ElSecureServer:TElSecureServer read FElSecureServer write FElSecureServer;
    PROPERTY CipherSuites:TBits read FCipherSuites write FCipherSuites;
    PROPERTY CipherSuite:integer read GetCipherSuite;
  end;

IMPLEMENTATION

VAR
  FAcceptThread:THandle=0;

// on error
PROCEDURE TSSLSBB.OnError(Sender:TObject; ErrorCode:integer; Fatal:boolean; Remote:boolean);

begin
  FLastErrorDesc:='';
  FLastError:=ErrorCode;
end;

// on send
PROCEDURE TSSLSBB.OnSend(Sender:TObject;buffer:pointer;size:longint);

VAR
  lResult:integer;

begin
  if FSocket.Socket=INVALID_SOCKET then
    exit;
  lResult:=Send(FSocket.Socket,buffer,size,0);
  if lResult=SOCKET_ERROR then
    begin
      FLastErrorDesc:='';
      FLastError:=WSAGetLastError;
    end;
end;

// on receive
PROCEDURE TSSLSBB.OnReceive(Sender:TObject;buffer:pointer;MaxSize:longint;VAR Written:longint);

begin
  if GetCurrentThreadId<>FAcceptThread then enterCriticalSection(FRecvBuffersLock);
  try
    if length(FRecvBuffers)<=MaxSize then
      begin
        Written:=length(FRecvBuffers);
        move(FRecvBuffers[1],buffer^,Written);
        FRecvBuffers:='';
      end
    else
      begin
        Written:=MaxSize;
        move(FRecvBuffers[1],buffer^,Written);
        Delete(FRecvBuffers,1,Written);
      end;
  finally
    if GetCurrentThreadId<>FAcceptThread then leaveCriticalSection(FRecvBuffersLock);
  end;
end;

// on data
PROCEDURE TSSLSBB.OnData(Sender:TObject;buffer:pointer;size:longint);

VAR
  lString:string;

begin
  setLength(lString,size);
  move(buffer^,lString[1],size);
  FRecvDecodedBuffers:=FRecvDecodedBuffers+lString;
end;

{ inherited }

CONSTRUCTOR TSSLSBB.create(CONST value: TTCPBlockSocket);

VAR
  loop1:integer;

begin
  inherited create(value);
  FServer:=false;
  FElSecureClient:=nil;
  FElSecureServer:=nil;
  FElCertStorage:=nil;
  FElX509Certificate:=nil;
  FElX509CACertificate:=nil;
  setLength(FRecvBuffer,DEFAULT_RECV_BUFFER);
  FRecvBuffers:='';
  InitializeCriticalSection(FRecvBuffersLock);
  FRecvDecodedBuffers:='';
  FCipherSuites:=TBits.create;
  if FCipherSuites<>nil then
    begin
      FCipherSuites.size:=SB_SUITE_LAST+1;
      for loop1:=SB_SUITE_FIRST to SB_SUITE_LAST do
        FCipherSuites[loop1]:=true;
    end;
end;

DESTRUCTOR TSSLSBB.destroy;

begin
  reset;
  inherited destroy;
  if FCipherSuites<>nil then
    FreeAndNIL(FCipherSuites);
  DeleteCriticalSection(FRecvBuffersLock);
end;

FUNCTION TSSLSBB.LibVersion: string;

begin
  result:='SecureBlackBox';
end;

FUNCTION TSSLSBB.LibName: string;

begin
  result:='ssl_sbb';
end;

FUNCTION FileToString(lFile:string):string;

VAR
  lStream:TMemoryStream;

begin
  result:='';
  lStream:=TMemoryStream.create;
  if lStream<>nil then
    begin
      lStream.loadFromFile(lFile);
      if lStream.size>0 then
        begin
          lStream.position:=0;
          setLength(result,lStream.size);
          move(lStream.memory^,result[1],lStream.size);
        end;
      lStream.free;
    end;
end;

FUNCTION TSSLSBB.GetCipherSuite:integer;

begin
  if FServer then
    result:=FElSecureServer.CipherSuite
  else
    result:=FElSecureClient.CipherSuite;
end;

PROCEDURE TSSLSBB.reset;

begin
  if FElSecureServer<>nil then
    FreeAndNIL(FElSecureServer);
  if FElSecureClient<>nil then
    FreeAndNIL(FElSecureClient);
  if FElX509Certificate<>nil then
    FreeAndNIL(FElX509Certificate);
  if FElX509CACertificate<>nil then
    FreeAndNIL(FElX509CACertificate);
  if FElCertStorage<>nil then
    FreeAndNIL(FElCertStorage);
  FSSLEnabled:=false;
end;

FUNCTION TSSLSBB.Prepare(Server:boolean): boolean;

VAR
  loop1:integer;
  lStream:TMemoryStream;
  lCertificate,lPrivateKey,lCertCA:string;

begin
  result:=false;
  FServer:=Server;

  // reset, if necessary
  reset;

  // init, certificate
  if FCertificateFile<>'' then
    lCertificate:=FileToString(FCertificateFile)
  else
    lCertificate:=FCertificate;
  if FPrivateKeyFile<>'' then
    lPrivateKey:=FileToString(FPrivateKeyFile)
  else
    lPrivateKey:=FPrivateKey;
  if FCertCAFile<>'' then
    lCertCA:=FileToString(FCertCAFile)
  else
    lCertCA:=FCertCA;
  if (lCertificate<>'') and (lPrivateKey<>'') then
    begin
      FElCertStorage:=TElMemoryCertStorage.create(nil);
      if FElCertStorage<>nil then
        FElCertStorage.clear;

      // apply ca certificate
      if lCertCA<>'' then
        begin
          FElX509CACertificate:=TElX509Certificate.create(nil);
          if FElX509CACertificate<>nil then
            begin
              with FElX509CACertificate do
                begin
                  lStream:=TMemoryStream.create;
                  try
                    WriteStrToStream(lStream,lCertCA);
                    lStream.Seek(0,soFromBeginning);
                    LoadFromStream(lStream);
                  finally
                    lStream.free;
                  end;
                end;
              if FElCertStorage<>nil then
                FElCertStorage.add(FElX509CACertificate);
            end;
        end;

      // apply certificate
      FElX509Certificate:=TElX509Certificate.create(nil);
      if FElX509Certificate<>nil then
        begin
          with FElX509Certificate do
            begin
              lStream:=TMemoryStream.create;
              try
                WriteStrToStream(lStream,lCertificate);
                lStream.Seek(0,soFromBeginning);
                LoadFromStream(lStream);
              finally
                lStream.free;
              end;
              lStream:=TMemoryStream.create;
              try
                WriteStrToStream(lStream,lPrivateKey);
                lStream.Seek(0,soFromBeginning);
                LoadKeyFromStream(lStream);
              finally
                lStream.free;
              end;
              if FElCertStorage<>nil then
                FElCertStorage.add(FElX509Certificate);
            end;
        end;
    end;

  // init, as server
  if FServer then
    begin
      FElSecureServer:=TElSecureServer.create(nil);
      if FElSecureServer<>nil then
        begin
          // init, ciphers
          for loop1:=SB_SUITE_FIRST to SB_SUITE_LAST do
            FElSecureServer.CipherSuites[loop1]:=FCipherSuites[loop1];
          FElSecureServer.Versions:=[sbSSL2,sbSSL3,sbTLS1];
          FElSecureServer.ClientAuthentication:=false;
          FElSecureServer.OnError:=OnError;
          FElSecureServer.OnSend:=OnSend;
          FElSecureServer.OnReceive:=OnReceive;
          FElSecureServer.OnData:=OnData;
          FElSecureServer.CertStorage:=FElCertStorage;
          result:=true;
        end;
    end
  else
    // init, as client
    begin
      FElSecureClient:=TElSecureClient.create(nil);
      if FElSecureClient<>nil then
        begin
          // init, ciphers
          for loop1:=SB_SUITE_FIRST to SB_SUITE_LAST do
            FElSecureClient.CipherSuites[loop1]:=FCipherSuites[loop1];
          FElSecureClient.Versions:=[sbSSL3,sbTLS1];
          FElSecureClient.OnError:=OnError;
          FElSecureClient.OnSend:=OnSend;
          FElSecureClient.OnReceive:=OnReceive;
          FElSecureClient.OnData:=OnData;
          FElSecureClient.CertStorage:=FElCertStorage;
          result:=true;
        end;
    end;
end;

FUNCTION TSSLSBB.Connect:boolean;

VAR
  lResult:integer;

begin
  result:=false;
  if FSocket.Socket=INVALID_SOCKET then
    exit;
  if Prepare(false) then
    begin
      FElSecureClient.Open;

      // reset
      FRecvBuffers:='';
      FRecvDecodedBuffers:='';

      // wait for open or error
      while (not FElSecureClient.active) and
        (FLastError=0) do
        begin
          // data available?
          if FRecvBuffers<>'' then
            FElSecureClient.DataAvailable
          else
            begin
              // socket recv
              lResult:=Recv(FSocket.Socket,@FRecvBuffer[1],length(FRecvBuffer),0);
              if lResult=SOCKET_ERROR then
                begin
                  FLastErrorDesc:='';
                  FLastError:=WSAGetLastError;
                end
              else
                begin
                  if lResult>0 then
                    FRecvBuffers:=FRecvBuffers+copy(FRecvBuffer,1,lResult)
                  else
                    break;
                end;
            end;
        end;
      if FLastError<>0 then
        exit;
      FSSLEnabled:=FElSecureClient.active;
      result:=FSSLEnabled;
    end;
end;

FUNCTION TSSLSBB.accept:boolean;

VAR
  lResult:integer;

begin
  result:=false;
  if FSocket.Socket=INVALID_SOCKET then
    exit;
  if Prepare(true) then
    begin
      FAcceptThread:=GetCurrentThreadId;
      FElSecureServer.Open;

      // reset
      FRecvBuffers:='';
      FRecvDecodedBuffers:='';

      // wait for open or error
      while (not FElSecureServer.active) and
        (FLastError=0) do
        begin
          // data available?
          if FRecvBuffers<>'' then
            FElSecureServer.DataAvailable
          else
            begin
              // socket recv
              lResult:=Recv(FSocket.Socket,@FRecvBuffer[1],length(FRecvBuffer),0);
              if lResult=SOCKET_ERROR then
                begin
                  FLastErrorDesc:='';
                  FLastError:=WSAGetLastError;
                end
              else
                begin
                  if lResult>0 then
                    FRecvBuffers:=FRecvBuffers+copy(FRecvBuffer,1,lResult)
                  else
                    break;
                end;
            end;
        end;
      if FLastError<>0 then
        exit;
      FSSLEnabled:=FElSecureServer.active;
      result:=FSSLEnabled;
    end;
end;

FUNCTION TSSLSBB.Shutdown:boolean;

begin
  result:=BiShutdown;
end;

FUNCTION TSSLSBB.BiShutdown: boolean;

begin
  reset;
  result:=true;
end;

FUNCTION TSSLSBB.SendBuffer(buffer: TMemory; len: integer): integer;

begin
  if FServer then
    FElSecureServer.SendData(buffer,len)
  else
    FElSecureClient.SendData(buffer,len);
  result:=len;
end;

FUNCTION TSSLSBB.RecvBuffer(buffer: TMemory; len: integer): integer;

begin
  result:=0;
  try
    // recv waiting, if necessary
    if FRecvDecodedBuffers='' then
      WaitingData;

    // received
    if length(FRecvDecodedBuffers)<len then
      begin
        result:=length(FRecvDecodedBuffers);
        move(FRecvDecodedBuffers[1],buffer^,result);
        FRecvDecodedBuffers:='';
      end
    else
      begin
        result:=len;
        move(FRecvDecodedBuffers[1],buffer^,result);
        Delete(FRecvDecodedBuffers,1,result);
      end;
  except
    // ignore
  end;
end;

FUNCTION TSSLSBB.WaitingData: integer;

VAR
  lResult:integer;
  lRecvBuffers:boolean;

begin
  result:=0;
  if FSocket.Socket=INVALID_SOCKET then
    exit;
  // data available?
  if GetCurrentThreadId<>FAcceptThread then enterCriticalSection(FRecvBuffersLock);
  try
    lRecvBuffers:=FRecvBuffers<>'';
  finally
    if GetCurrentThreadId<>FAcceptThread then leaveCriticalSection(FRecvBuffersLock);
  end;
  if lRecvBuffers then
    begin
      if FServer then
        FElSecureServer.DataAvailable
      else
        FElSecureClient.DataAvailable;
    end
  else
    begin
      // socket recv
      lResult:=Recv(FSocket.Socket,@FRecvBuffer[1],length(FRecvBuffer),0);
      if lResult=SOCKET_ERROR then
        begin
          FLastErrorDesc:='';
          FLastError:=WSAGetLastError;
        end
      else
        begin
          if GetCurrentThreadId<>FAcceptThread then enterCriticalSection(FRecvBuffersLock);
          try
            FRecvBuffers:=FRecvBuffers+copy(FRecvBuffer,1,lResult);
          finally
            if GetCurrentThreadId<>FAcceptThread then leaveCriticalSection(FRecvBuffersLock);
          end;

          // data available?
          if GetCurrentThreadId<>FAcceptThread then enterCriticalSection(FRecvBuffersLock);
          try
            lRecvBuffers:=FRecvBuffers<>'';
          finally
            if GetCurrentThreadId<>FAcceptThread then leaveCriticalSection(FRecvBuffersLock);
          end;
          if lRecvBuffers then
            begin
              if FServer then
                FElSecureServer.DataAvailable
              else
                FElSecureClient.DataAvailable;
            end;
        end;
    end;

  // decoded buffers result
  result:=length(FRecvDecodedBuffers);
end;

FUNCTION TSSLSBB.GetSSLVersion: string;

begin
  result:='SSLv3 or TLSv1';
end;

FUNCTION TSSLSBB.GetPeerSubject: string;

begin
  result := '';
//  if FServer then
    // must return subject of the client certificate
//  else
    // must return subject of the server certificate
end;

FUNCTION TSSLSBB.GetPeerName: string;

begin
  result := '';
//  if FServer then
    // must return commonname of the client certificate
//  else
    // must return commonname of the server certificate
end;

FUNCTION TSSLSBB.GetPeerIssuer: string;

begin
  result := '';
//  if FServer then
    // must return issuer of the client certificate
//  else
    // must return issuer of the server certificate
end;

FUNCTION TSSLSBB.GetPeerFingerprint: string;

begin
  result := '';
//  if FServer then
    // must return a unique hash string of the client certificate
//  else
    // must return a unique hash string of the server certificate
end;

FUNCTION TSSLSBB.GetCertInfo: string;

begin
  result := '';
//  if FServer then
    // must return a text representation of the ASN of the client certificate
//  else
    // must return a text representation of the ASN of the server certificate
end;

{==============================================================================}

INITIALIZATION
  SSLImplementation := TSSLSBB;

FINALIZATION

end.
