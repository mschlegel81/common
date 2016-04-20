{==============================================================================|
| project : Ararat Synapse                                       | 004.000.002 |
|==============================================================================|
| content: PING Sender                                                         |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(ICMP PING implementation.)
Allows create PING and TRACEROUTE. or you can diagnose your network.

This UNIT using IpHlpApi (on WinXP or higher) if available. Otherwise it trying
 to use raw sockets.

Warning: for use of raw sockets you must have some special rights on some
 systems. So, it working allways when you have administator/root rights.
 Otherwise you can have problems!

Note: This UNIT is not portable to .NET!
  use native .NET Classes for Ping instead.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$R-}
{$H+}

{$IFDEF CIL}
  Sorry, this UNIT is not for .NET!
{$ENDIF}
//old Delphi does not have MSWINDOWS define.
{$IFDEF WIN32}
  {$IFNDEF MSWINDOWS}
    {$DEFINE MSWINDOWS}
  {$ENDIF}
{$ENDIF}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT pingsend;

INTERFACE

USES
  sysutils,
  synsock, blcksock, synautil, synafpc, synaip
{$IFDEF MSWINDOWS}
  , windows
{$ENDIF}
  ;

CONST
  ICMP_ECHO = 8;
  ICMP_ECHOREPLY = 0;
  ICMP_UNREACH = 3;
  ICMP_TIME_EXCEEDED = 11;
//rfc-2292
  ICMP6_ECHO = 128;
  ICMP6_ECHOREPLY = 129;
  ICMP6_UNREACH = 1;
  ICMP6_TIME_EXCEEDED = 3;

TYPE
  {:List of possible ICMP reply packet types.}
  TICMPError = (
    IE_NoError,
    IE_Other,
    IE_TTLExceed,
    IE_UnreachOther,
    IE_UnreachRoute,
    IE_UnreachAdmin,
    IE_UnreachAddr,
    IE_UnreachPort
    );

  {:@abstract(Implementation of ICMP PING and ICMPv6 PING.)}
  TPINGSend = class(TSynaClient)
  private
    FSock: TICMPBlockSocket;
    FBuffer: ansistring;
    FSeq: integer;
    FId: integer;
    FPacketSize: integer;
    FPingTime: integer;
    FIcmpEcho: byte;
    FIcmpEchoReply: byte;
    FIcmpUnreach: byte;
    FReplyFrom: string;
    FReplyType: byte;
    FReplyCode: byte;
    FReplyError: TICMPError;
    FReplyErrorDesc: string;
    FTTL: byte;
    Fsin: TVarSin;
    FUNCTION Checksum(value: ansistring): word;
    FUNCTION Checksum6(value: ansistring): word;
    FUNCTION ReadPacket: boolean;
    PROCEDURE TranslateError;
    PROCEDURE TranslateErrorIpHlp(value: integer);
    FUNCTION InternalPing(CONST Host: string): boolean;
    FUNCTION InternalPingIpHlp(CONST Host: string): boolean;
    FUNCTION IsHostIP6(CONST Host: string): boolean;
    PROCEDURE GenErrorDesc;
  public
    {:Send ICMP ping to host and count @link(pingtime). If ping OK, result is
     @true.}
    FUNCTION Ping(CONST Host: string): boolean;
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;
  Published
    {:Size of PING packet. Default size is 32 bytes.}
    PROPERTY PacketSize: integer read FPacketSize write FPacketSize;

    {:Time between request and reply.}
    PROPERTY PingTime: integer read FPingTime;

    {:From this address is sended reply for your PING request. It maybe not your
     requested destination, when some error occured!}
    PROPERTY ReplyFrom: string read FReplyFrom;

    {:ICMP type of PING reply. Each protocol using another values! For IPv4 and
     IPv6 are used different values!}
    PROPERTY ReplyType: byte read FReplyType;

    {:ICMP code of PING reply. Each protocol using another values! For IPv4 and
     IPv6 are used different values! for protocol independent value look to
     @link(ReplyError)}
    PROPERTY ReplyCode: byte read FReplyCode;

    {:Return type of returned ICMP message. This value is independent on used
     protocol!}
    PROPERTY ReplyError: TICMPError read FReplyError;

    {:Return human readable description of returned packet type.}
    PROPERTY ReplyErrorDesc: string read FReplyErrorDesc;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TICMPBlockSocket read FSock;

    {:TTL value for ICMP query}
    PROPERTY TTL: byte read FTTL write FTTL;
  end;

{:A very useful function and example of its use would be found in the TPINGSend
 object. use it to ping to any host. if successful, returns the ping time in
 Milliseconds.  Returns -1 if an error occurred.}
FUNCTION PingHost(CONST Host: string): integer;

{:A very useful function and example of its use would be found in the TPINGSend
 object. use it to TraceRoute to any host.}
FUNCTION TraceRouteHost(CONST Host: string): string;

IMPLEMENTATION

TYPE
  {:Record for ICMP ECHO packet header.}
  TIcmpEchoHeader = packed record
    i_type: byte;
    i_code: byte;
    i_checkSum: word;
    i_Id: word;
    i_seq: word;
    TimeStamp: integer;
  end;

  {:record used internally by TPingSend for compute checksum of ICMPv6 packet
   pseudoheader.}
  TICMP6Packet = packed record
    in_source: TInAddr6;
    in_dest: TInAddr6;
    length: integer;
    free0: byte;
    free1: byte;
    free2: byte;
    proto: byte;
  end;

{$IFDEF MSWINDOWS}
CONST
  DLLIcmpName = 'iphlpapi.dll';
TYPE
  TIP_OPTION_INFORMATION = record
    TTL: byte;
    TOS: byte;
    Flags: byte;
    OptionsSize: byte;
    OptionsData: PAnsiChar;
  end;
  PIP_OPTION_INFORMATION = ^TIP_OPTION_INFORMATION;

  TICMP_ECHO_REPLY = record
    Address: TInAddr;
    Status: integer;
    RoundTripTime: integer;
    DataSize: word;
    Reserved: word;
    data: pointer;
    options: TIP_OPTION_INFORMATION;
  end;
  PICMP_ECHO_REPLY = ^TICMP_ECHO_REPLY;

  TICMPV6_ECHO_REPLY = record
    Address: TSockAddrIn6;
    Status: integer;
    RoundTripTime: integer;
  end;
  PICMPV6_ECHO_REPLY = ^TICMPV6_ECHO_REPLY;

  TIcmpCreateFile = FUNCTION: integer; stdcall;
  TIcmpCloseHandle = FUNCTION(handle: integer): boolean; stdcall;
  TIcmpSendEcho2 = FUNCTION(handle: integer; Event: pointer; ApcRoutine: pointer;
    ApcContext: pointer; DestinationAddress: TInAddr; RequestData: pointer;
    RequestSize: integer; RequestOptions: PIP_OPTION_INFORMATION;
    ReplyBuffer: pointer; ReplySize: integer; Timeout: integer): integer; stdcall;
  TIcmp6CreateFile = FUNCTION: integer; stdcall;
  TIcmp6SendEcho2 = FUNCTION(handle: integer; Event: pointer; ApcRoutine: pointer;
    ApcContext: pointer; SourceAddress: PSockAddrIn6; DestinationAddress: PSockAddrIn6;
    RequestData: pointer; RequestSize: integer; RequestOptions: PIP_OPTION_INFORMATION;
    ReplyBuffer: pointer; ReplySize: integer; Timeout: integer): integer; stdcall;

VAR
  IcmpDllHandle: TLibHandle = 0;
  IcmpHelper4: boolean = false;
  IcmpHelper6: boolean = false;
  IcmpCreateFile: TIcmpCreateFile = nil;
  IcmpCloseHandle: TIcmpCloseHandle = nil;
  IcmpSendEcho2: TIcmpSendEcho2 = nil;
  Icmp6CreateFile: TIcmp6CreateFile = nil;
  Icmp6SendEcho2: TIcmp6SendEcho2 = nil;
{$ENDIF}
{==============================================================================}

CONSTRUCTOR TPINGSend.create;
begin
  inherited create;
  FSock := TICMPBlockSocket.create;
  FSock.Owner := self;
  FTimeout := 5000;
  FPacketSize := 32;
  FSeq := 0;
  randomize;
  FTTL := 128;
end;

DESTRUCTOR TPINGSend.destroy;
begin
  FSock.free;
  inherited destroy;
end;

FUNCTION TPINGSend.ReadPacket: boolean;
begin
  FBuffer := FSock.RecvPacket(Ftimeout);
  result := FSock.LastError = 0;
end;

PROCEDURE TPINGSend.GenErrorDesc;
begin
  case FReplyError of
    IE_NoError:
      FReplyErrorDesc := '';
    IE_Other:
      FReplyErrorDesc := 'Unknown error';
    IE_TTLExceed:
      FReplyErrorDesc := 'TTL Exceeded';
    IE_UnreachOther:
      FReplyErrorDesc := 'Unknown unreachable';
    IE_UnreachRoute:
      FReplyErrorDesc := 'No route to destination';
    IE_UnreachAdmin:
      FReplyErrorDesc := 'Administratively prohibited';
    IE_UnreachAddr:
      FReplyErrorDesc := 'Address unreachable';
    IE_UnreachPort:
      FReplyErrorDesc := 'Port unreachable';
  end;
end;

FUNCTION TPINGSend.IsHostIP6(CONST Host: string): boolean;
VAR
  f: integer;
begin
  f := AF_UNSPEC;
  if IsIp(Host) then
    f := AF_INET
  else
    if IsIp6(Host) then
      f := AF_INET6;
  synsock.SetVarSin(Fsin, host, '0', f,
    IPPROTO_UDP, SOCK_DGRAM, Fsock.PreferIP4);
  result := Fsin.sin_family = AF_INET6;
end;

FUNCTION TPINGSend.Ping(CONST Host: string): boolean;
VAR
  b: boolean;
begin
  FPingTime := -1;
  FReplyFrom := '';
  FReplyType := 0;
  FReplyCode := 0;
  FReplyError := IE_Other;
  GenErrorDesc;
  FBuffer := StringOfChar(#55, sizeOf(TICMPEchoHeader) + FPacketSize);
{$IFDEF MSWINDOWS}
  b := IsHostIP6(host);
  if not(b) and IcmpHelper4 then
    result := InternalPingIpHlp(host)
  else
    if b and IcmpHelper6 then
      result := InternalPingIpHlp(host)
    else
      result := InternalPing(host);
{$ELSE}
   result := InternalPing(host);
{$ENDIF}
end;

FUNCTION TPINGSend.InternalPing(CONST Host: string): boolean;
VAR
  IPHeadPtr: ^TIPHeader;
  IpHdrLen: integer;
  IcmpEchoHeaderPtr: ^TICMPEchoHeader;
  t: boolean;
  x: Cardinal;
  IcmpReqHead: string;
begin
  result := false;
  FSock.TTL := FTTL;
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(Host, '0');
  if FSock.LastError <> 0 then
    exit;
  FSock.SizeRecvBuffer := 60 * 1024;
  if FSock.IP6used then
  begin
    FIcmpEcho := ICMP6_ECHO;
    FIcmpEchoReply := ICMP6_ECHOREPLY;
    FIcmpUnreach := ICMP6_UNREACH;
  end
  else
  begin
    FIcmpEcho := ICMP_ECHO;
    FIcmpEchoReply := ICMP_ECHOREPLY;
    FIcmpUnreach := ICMP_UNREACH;
  end;
  IcmpEchoHeaderPtr := pointer(FBuffer);
  with IcmpEchoHeaderPtr^ do
  begin
    i_type := FIcmpEcho;
    i_code := 0;
    i_CheckSum := 0;
    FId := system.random(32767);
    i_Id := FId;
    TimeStamp := GetTick;
    inc(FSeq);
    i_Seq := FSeq;
    if fSock.IP6used then
      i_CheckSum := CheckSum6(FBuffer)
    else
      i_CheckSum := CheckSum(FBuffer);
  end;
  FSock.SendString(FBuffer);
  // remember first 8 bytes of ICMP packet
  IcmpReqHead := copy(FBuffer, 1, 8);
  x := GetTick;
  repeat
    t := ReadPacket;
    if not t then
      break;
    if fSock.IP6used then
    begin
{$IFNDEF MSWINDOWS}
      IcmpEchoHeaderPtr := pointer(FBuffer);
{$ELSE}
//WinXP SP1 with networking update doing this think by another way ;-O
//      FBuffer := StringOfChar(#0, 4) + FBuffer;
      IcmpEchoHeaderPtr := pointer(FBuffer);
//      IcmpEchoHeaderPtr^.i_type := FIcmpEchoReply;
{$ENDIF}
    end
    else
    begin
      IPHeadPtr := pointer(FBuffer);
      IpHdrLen := (IPHeadPtr^.VerLen and $0F) * 4;
      IcmpEchoHeaderPtr := @FBuffer[IpHdrLen + 1];
    end;
  //check for timeout
    if TickDelta(x, GetTick) > FTimeout then
    begin
      t := false;
      break;
    end;
  //it discard sometimes possible 'echoes' of previosly sended packet
  //or other unwanted ICMP packets...
  until (IcmpEchoHeaderPtr^.i_type <> FIcmpEcho)
    and ((IcmpEchoHeaderPtr^.i_id = FId)
    or (pos(IcmpReqHead, FBuffer) > 0));
  if t then
    begin
      FPingTime := TickDelta(x, GetTick);
      FReplyFrom := FSock.GetRemoteSinIP;
      FReplyType := IcmpEchoHeaderPtr^.i_type;
      FReplyCode := IcmpEchoHeaderPtr^.i_code;
      TranslateError;
      result := true;
    end;
end;

FUNCTION TPINGSend.Checksum(value: ansistring): word;
VAR
  CkSum: integer;
  Num, Remain: integer;
  n, i: integer;
begin
  Num := length(value) div 2;
  Remain := length(value) mod 2;
  CkSum := 0;
  i := 1;
  for n := 0 to Num - 1 do
  begin
    CkSum := CkSum + Synsock.HtoNs(DecodeInt(value, i));
    inc(i, 2);
  end;
  if Remain <> 0 then
    CkSum := CkSum + ord(value[length(value)]);
  CkSum := (CkSum shr 16) + (CkSum and $FFFF);
  CkSum := CkSum + (CkSum shr 16);
  result := word(not CkSum);
end;

FUNCTION TPINGSend.Checksum6(value: ansistring): word;
CONST
  IOC_OUT = $40000000;
  IOC_IN = $80000000;
  IOC_INOUT = (IOC_IN or IOC_OUT);
  IOC_WS2 = $08000000;
  SIO_ROUTING_INTERFACE_QUERY = 20 or IOC_WS2 or IOC_INOUT;
VAR
  ICMP6Ptr: ^TICMP6Packet;
  s: ansistring;
  b: integer;
  ip6: TSockAddrIn6;
  x: integer;
begin
  result := 0;
{$IFDEF MSWINDOWS}
  s := StringOfChar(#0, sizeOf(TICMP6Packet)) + value;
  ICMP6Ptr := pointer(s);
  x := synsock.WSAIoctl(FSock.Socket, SIO_ROUTING_INTERFACE_QUERY,
    @FSock.RemoteSin, sizeOf(FSock.RemoteSin),
    @ip6, sizeOf(ip6), @b, nil, nil);
  if x <> -1 then
    ICMP6Ptr^.in_dest := ip6.sin6_addr
  else
    ICMP6Ptr^.in_dest := FSock.LocalSin.sin6_addr;
  ICMP6Ptr^.in_source := FSock.RemoteSin.sin6_addr;
  ICMP6Ptr^.length := synsock.htonl(length(value));
  ICMP6Ptr^.proto := IPPROTO_ICMPV6;
  result := Checksum(s);
{$ENDIF}
end;

PROCEDURE TPINGSend.TranslateError;
begin
  if fSock.IP6used then
  begin
    case FReplyType of
      ICMP6_ECHOREPLY:
        FReplyError := IE_NoError;
      ICMP6_TIME_EXCEEDED:
        FReplyError := IE_TTLExceed;
      ICMP6_UNREACH:
        case FReplyCode of
          0:
            FReplyError := IE_UnreachRoute;
          3:
            FReplyError := IE_UnreachAddr;
          4:
            FReplyError := IE_UnreachPort;
          1:
            FReplyError := IE_UnreachAdmin;
        else
          FReplyError := IE_UnreachOther;
        end;
    else
      FReplyError := IE_Other;
    end;
  end
  else
  begin
    case FReplyType of
      ICMP_ECHOREPLY:
        FReplyError := IE_NoError;
      ICMP_TIME_EXCEEDED:
        FReplyError := IE_TTLExceed;
      ICMP_UNREACH:
        case FReplyCode of
          0:
            FReplyError := IE_UnreachRoute;
          1:
            FReplyError := IE_UnreachAddr;
          3:
            FReplyError := IE_UnreachPort;
          13:
            FReplyError := IE_UnreachAdmin;
        else
          FReplyError := IE_UnreachOther;
        end;
    else
      FReplyError := IE_Other;
    end;
  end;
  GenErrorDesc;
end;

PROCEDURE TPINGSend.TranslateErrorIpHlp(value: integer);
begin
  case value of
    11000, 0:
      FReplyError := IE_NoError;
    11013:
      FReplyError := IE_TTLExceed;
    11002:
      FReplyError := IE_UnreachRoute;
    11003:
      FReplyError := IE_UnreachAddr;
    11005:
      FReplyError := IE_UnreachPort;
    11004:
      FReplyError := IE_UnreachAdmin;
  else
    FReplyError := IE_Other;
  end;
  GenErrorDesc;
end;

FUNCTION TPINGSend.InternalPingIpHlp(CONST Host: string): boolean;
{$IFDEF MSWINDOWS}
VAR
  PingIp6: boolean;
  PingHandle: integer;
  r: integer;
  ipo: TIP_OPTION_INFORMATION;
  RBuff: ansistring;
  ip4reply: PICMP_ECHO_REPLY;
  ip6reply: PICMPV6_ECHO_REPLY;
  ip6: TSockAddrIn6;
begin
  result := false;
  PingIp6 := Fsin.sin_family = AF_INET6;
  if pingIp6 then
    PingHandle := Icmp6CreateFile
  else
    PingHandle := IcmpCreateFile;
  if PingHandle <> -1 then
  begin
    try
      ipo.TTL := FTTL;
      ipo.TOS := 0;
      ipo.Flags := 0;
      ipo.OptionsSize := 0;
      ipo.OptionsData := nil;
      setLength(RBuff, 4096);
      if pingIp6 then
      begin
        FillChar(ip6, sizeOf(ip6), 0);
        r := Icmp6SendEcho2(PingHandle, nil, nil, nil, @ip6, @Fsin,
          PAnsiChar(FBuffer), length(FBuffer), @ipo, PAnsiChar(RBuff), length(RBuff), FTimeout);
        if r > 0 then
        begin
          RBuff := #0 + #0 + RBuff;
          ip6reply := PICMPV6_ECHO_REPLY(pointer(RBuff));
          FPingTime := ip6reply^.RoundTripTime;
          ip6reply^.Address.sin6_family := AF_INET6;
          FReplyFrom := GetSinIp(TVarSin(ip6reply^.Address));
          TranslateErrorIpHlp(ip6reply^.Status);
          result := true;
        end;
      end
      else
      begin
        r := IcmpSendEcho2(PingHandle, nil, nil, nil, Fsin.sin_addr,
          PAnsiChar(FBuffer), length(FBuffer), @ipo, PAnsiChar(RBuff), length(RBuff), FTimeout);
        if r > 0 then
        begin
          ip4reply := PICMP_ECHO_REPLY(pointer(RBuff));
          FPingTime := ip4reply^.RoundTripTime;
          FReplyFrom := IpToStr(swapbytes(ip4reply^.Address.S_addr));
          TranslateErrorIpHlp(ip4reply^.Status);
          result := true;
        end;
      end
    finally
      IcmpCloseHandle(PingHandle);
    end;
  end;
end;
{$ELSE}
begin
  result := false;
end;
{$ENDIF}

{==============================================================================}

FUNCTION PingHost(CONST Host: string): integer;
begin
  with TPINGSend.create do
  try
    result := -1;
    if Ping(Host) then
      if ReplyError = IE_NoError then
        result := PingTime;
  finally
    free;
  end;
end;

FUNCTION TraceRouteHost(CONST Host: string): string;
VAR
  Ping: TPingSend;
  ttl : byte;
begin
  result := '';
  Ping := TPINGSend.create;
  try
    ttl := 1;
    repeat
      ping.TTL := ttl;
      inc(ttl);
      if ttl > 30 then
        break;
      if not ping.Ping(Host) then
      begin
        result := result + cAnyHost+ ' Timeout' + CRLF;
        continue;
      end;
      if (ping.ReplyError <> IE_NoError)
        and (ping.ReplyError <> IE_TTLExceed) then
      begin
        result := result + Ping.ReplyFrom + ' ' + Ping.ReplyErrorDesc + CRLF;
        break;
      end;
      result := result + Ping.ReplyFrom + ' ' + intToStr(Ping.PingTime) + CRLF;
    until ping.ReplyError = IE_NoError;
  finally
    Ping.free;
  end;
end;

{$IFDEF MSWINDOWS}
INITIALIZATION
begin
  IcmpHelper4 := false;
  IcmpHelper6 := false;
  IcmpDllHandle := LoadLibrary(DLLIcmpName);
  if IcmpDllHandle <> 0 then
  begin
    IcmpCreateFile := GetProcAddress(IcmpDLLHandle, 'IcmpCreateFile');
    IcmpCloseHandle := GetProcAddress(IcmpDLLHandle, 'IcmpCloseHandle');
    IcmpSendEcho2 := GetProcAddress(IcmpDLLHandle, 'IcmpSendEcho2');
    Icmp6CreateFile := GetProcAddress(IcmpDLLHandle, 'Icmp6CreateFile');
    Icmp6SendEcho2 := GetProcAddress(IcmpDLLHandle, 'Icmp6SendEcho2');
    IcmpHelper4 := assigned(IcmpCreateFile)
      and assigned(IcmpCloseHandle)
      and assigned(IcmpSendEcho2);
    IcmpHelper6 := assigned(Icmp6CreateFile)
      and assigned(Icmp6SendEcho2);
  end;
end;

FINALIZATION
begin
  FreeLibrary(IcmpDllHandle);
end;
{$ENDIF}

end.
