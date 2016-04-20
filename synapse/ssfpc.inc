{==============================================================================|
| project : Ararat Synapse                                       | 001.001.004 |
|==============================================================================|
| content: Socket Independent Platform Layer - FreePascal definition include   |
|==============================================================================|
| Copyright (c)2006-2011, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2006-2011.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@exclude}

{$IFDEF FPC}
{For FreePascal 2.x.x}

//{$DEFINE FORCEOLDAPI}
{Note about define FORCEOLDAPI:
if you activate this compiler directive, then is allways used old socket API
for name resolution. if you leave this directive inactive, then the new API
is used, when running system allows it.

for IPv6 support you must have new API!
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$ifdef FreeBSD}
{$DEFINE SOCK_HAS_SINLEN}               // BSD definition of scoketaddr
{$endif}
{$ifdef darwin}
{$DEFINE SOCK_HAS_SINLEN}               // BSD definition of scoketaddr
{$endif}

INTERFACE

USES
  SyncObjs, sysutils, Classes,
  synafpc, baseunix, unix, termio, sockets, netdb;

FUNCTION InitSocketInterface(stack: string): boolean;
FUNCTION DestroySocketInterface: boolean;

CONST
  DLLStackName = '';
  WinsockLevel = $0202;

  cLocalHost = '127.0.0.1';
  cAnyHost = '0.0.0.0';
  c6AnyHost = '::0';
  c6Localhost = '::1';
  cLocalHostStr = 'localhost';

TYPE
  TSocket = longint;
  TAddrFamily = integer;

  TMemory = pointer;


TYPE
  TFDSet = baseunix.TFDSet;
  PFDSet = ^TFDSet;
  Ptimeval = baseunix.ptimeval;
  Ttimeval = baseunix.ttimeval;

CONST
  FIONREAD        = termio.FIONREAD;
  FIONBIO         = termio.FIONBIO;
  FIOASYNC        = termio.FIOASYNC;

CONST
  IPPROTO_IP     =   0;		{ Dummy					}
  IPPROTO_ICMP   =   1;		{ Internet Control Message Protocol }
  IPPROTO_IGMP   =   2;		{ Internet Group Management Protocol}
  IPPROTO_TCP    =   6;		{ TCP           			}
  IPPROTO_UDP    =   17;	{ User Datagram Protocol		}
  IPPROTO_IPV6   =   41;
  IPPROTO_ICMPV6 =   58;
  IPPROTO_RM     =  113;

  IPPROTO_RAW    =   255;
  IPPROTO_MAX    =   256;

TYPE
  PInAddr = ^TInAddr;
  TInAddr = sockets.in_addr;

  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = sockets.TInetSockAddr;


  TIP_mreq =  record
    imr_multiaddr: TInAddr;     // IP multicast address of group
    imr_interface: TInAddr;     // local IP address of interface
  end;


  PInAddr6 = ^TInAddr6;
  TInAddr6 = sockets.Tin6_addr;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = sockets.TInetSockAddr6;


  TIPv6_mreq = record
    ipv6mr_multiaddr: TInAddr6; // IPv6 multicast address.
    ipv6mr_interface: integer;   // Interface index.
  end;

CONST
  INADDR_ANY       = $00000000;
  INADDR_LOOPBACK  = $7F000001;
  INADDR_BROADCAST = $ffffffff;
  INADDR_NONE      = $ffffffff;
  ADDR_ANY		 = INADDR_ANY;
  INVALID_SOCKET		= TSocket(not(0));
  SOCKET_ERROR			= -1;

CONST
  IP_TOS             = sockets.IP_TOS;             { int; IP type of service and precedence.  }
  IP_TTL             = sockets.IP_TTL;             { int; IP time to live.  }
  IP_HDRINCL         = sockets.IP_HDRINCL;         { int; Header is included with data.  }
  IP_OPTIONS         = sockets.IP_OPTIONS;         { ip_opts; IP per-packet options.  }
//  IP_ROUTER_ALERT    = sockets.IP_ROUTER_ALERT;    { bool }
  IP_RECVOPTS        = sockets.IP_RECVOPTS;        { bool }
  IP_RETOPTS         = sockets.IP_RETOPTS;         { bool }
//  IP_PKTINFO         = sockets.IP_PKTINFO;         { bool }
//  IP_PKTOPTIONS      = sockets.IP_PKTOPTIONS;
//  IP_PMTUDISC        = sockets.IP_PMTUDISC;        { obsolete name? }
//  IP_MTU_DISCOVER    = sockets.IP_MTU_DISCOVER;    { int; see below }
//  IP_RECVERR         = sockets.IP_RECVERR;         { bool }
//  IP_RECVTTL         = sockets.IP_RECVTTL;         { bool }
//  IP_RECVTOS         = sockets.IP_RECVTOS;         { bool }
  IP_MULTICAST_IF    = sockets.IP_MULTICAST_IF;    { in_addr; set/get IP multicast i/f }
  IP_MULTICAST_TTL   = sockets.IP_MULTICAST_TTL;   { u_char; set/get IP multicast ttl }
  IP_MULTICAST_LOOP  = sockets.IP_MULTICAST_LOOP;  { i_char; set/get IP multicast loopback }
  IP_ADD_MEMBERSHIP  = sockets.IP_ADD_MEMBERSHIP;  { ip_mreq; add an IP group membership }
  IP_DROP_MEMBERSHIP = sockets.IP_DROP_MEMBERSHIP; { ip_mreq; drop an IP group membership }

  SOL_SOCKET    = sockets.SOL_SOCKET;

  SO_DEBUG      = sockets.SO_DEBUG;
  SO_REUSEADDR  = sockets.SO_REUSEADDR;
  SO_TYPE       = sockets.SO_TYPE;
  SO_ERROR      = sockets.SO_ERROR;
  SO_DONTROUTE  = sockets.SO_DONTROUTE;
  SO_BROADCAST  = sockets.SO_BROADCAST;
  SO_SNDBUF     = sockets.SO_SNDBUF;
  SO_RCVBUF     = sockets.SO_RCVBUF;
  SO_KEEPALIVE  = sockets.SO_KEEPALIVE;
  SO_OOBINLINE  = sockets.SO_OOBINLINE;
//  SO_NO_CHECK   = sockets.SO_NO_CHECK;
//  SO_PRIORITY   = sockets.SO_PRIORITY;
  SO_LINGER     = sockets.SO_LINGER;
//  SO_BSDCOMPAT  = sockets.SO_BSDCOMPAT;
//  SO_REUSEPORT  = sockets.SO_REUSEPORT;
//  SO_PASSCRED   = sockets.SO_PASSCRED;
//  SO_PEERCRED   = sockets.SO_PEERCRED;
  SO_RCVLOWAT   = sockets.SO_RCVLOWAT;
  SO_SNDLOWAT   = sockets.SO_SNDLOWAT;
  SO_RCVTIMEO   = sockets.SO_RCVTIMEO;
  SO_SNDTIMEO   = sockets.SO_SNDTIMEO;
{ Security levels - as per NRL IPv6 - don't actually do anything }
//  SO_SECURITY_AUTHENTICATION       = sockets.SO_SECURITY_AUTHENTICATION;
//  SO_SECURITY_ENCRYPTION_TRANSPORT = sockets.SO_SECURITY_ENCRYPTION_TRANSPORT;
//  SO_SECURITY_ENCRYPTION_NETWORK   = sockets.SO_SECURITY_ENCRYPTION_NETWORK;
//  SO_BINDTODEVICE                  = sockets.SO_BINDTODEVICE;
{ Socket filtering }
//  SO_ATTACH_FILTER = sockets.SO_ATTACH_FILTER;
//  SO_DETACH_FILTER = sockets.SO_DETACH_FILTER;

  SOMAXCONN       = 1024;

  IPV6_UNICAST_HOPS     = sockets.IPV6_UNICAST_HOPS;
  IPV6_MULTICAST_IF     = sockets.IPV6_MULTICAST_IF;
  IPV6_MULTICAST_HOPS   = sockets.IPV6_MULTICAST_HOPS;
  IPV6_MULTICAST_LOOP   = sockets.IPV6_MULTICAST_LOOP;
  IPV6_JOIN_GROUP       = sockets.IPV6_JOIN_GROUP;
  IPV6_LEAVE_GROUP      = sockets.IPV6_LEAVE_GROUP;

CONST
  SOCK_STREAM     = 1;               { stream socket }
  SOCK_DGRAM      = 2;               { datagram socket }
  SOCK_RAW        = 3;               { raw-protocol interface }
  SOCK_RDM        = 4;               { reliably-delivered message }
  SOCK_SEQPACKET  = 5;               { sequenced packet stream }

{ TCP options. }
  TCP_NODELAY     = $0001;

{ Address families. }

  AF_UNSPEC       = 0;               { unspecified }
  AF_INET         = 2;               { internetwork: UDP, TCP, etc. }
  AF_INET6        = 10;              { Internetwork Version 6 }
  AF_MAX          = 24;

{ Protocol families, same as address families for now. }
  PF_UNSPEC       = AF_UNSPEC;
  PF_INET         = AF_INET;
  PF_INET6        = AF_INET6;
  PF_MAX          = AF_MAX;

TYPE
{ Structure used for manipulating linger option. }
  PLinger = ^TLinger;
  TLinger = packed record
    l_onoff: integer;
    l_linger: integer;
  end;

CONST

  MSG_OOB       = sockets.MSG_OOB;      // Process out-of-band data.
  MSG_PEEK      = sockets.MSG_PEEK;     // Peek at incoming messages.
  {$ifdef DARWIN}
  MSG_NOSIGNAL  = $20000;  // Do not generate SIGPIPE.
                           // Works under MAC OS X, but is undocumented,
                           // So FPC doesn't include it
  {$else}
   MSG_NOSIGNAL  = sockets.MSG_NOSIGNAL; // Do not generate SIGPIPE.
  {$endif}

CONST
  WSAEINTR = ESysEINTR;
  WSAEBADF = ESysEBADF;
  WSAEACCES = ESysEACCES;
  WSAEFAULT = ESysEFAULT;
  WSAEINVAL = ESysEINVAL;
  WSAEMFILE = ESysEMFILE;
  WSAEWOULDBLOCK = ESysEWOULDBLOCK;
  WSAEINPROGRESS = ESysEINPROGRESS;
  WSAEALREADY = ESysEALREADY;
  WSAENOTSOCK = ESysENOTSOCK;
  WSAEDESTADDRREQ = ESysEDESTADDRREQ;
  WSAEMSGSIZE = ESysEMSGSIZE;
  WSAEPROTOTYPE = ESysEPROTOTYPE;
  WSAENOPROTOOPT = ESysENOPROTOOPT;
  WSAEPROTONOSUPPORT = ESysEPROTONOSUPPORT;
  WSAESOCKTNOSUPPORT = ESysESOCKTNOSUPPORT;
  WSAEOPNOTSUPP = ESysEOPNOTSUPP;
  WSAEPFNOSUPPORT = ESysEPFNOSUPPORT;
  WSAEAFNOSUPPORT = ESysEAFNOSUPPORT;
  WSAEADDRINUSE = ESysEADDRINUSE;
  WSAEADDRNOTAVAIL = ESysEADDRNOTAVAIL;
  WSAENETDOWN = ESysENETDOWN;
  WSAENETUNREACH = ESysENETUNREACH;
  WSAENETRESET = ESysENETRESET;
  WSAECONNABORTED = ESysECONNABORTED;
  WSAECONNRESET = ESysECONNRESET;
  WSAENOBUFS = ESysENOBUFS;
  WSAEISCONN = ESysEISCONN;
  WSAENOTCONN = ESysENOTCONN;
  WSAESHUTDOWN = ESysESHUTDOWN;
  WSAETOOMANYREFS = ESysETOOMANYREFS;
  WSAETIMEDOUT = ESysETIMEDOUT;
  WSAECONNREFUSED = ESysECONNREFUSED;
  WSAELOOP = ESysELOOP;
  WSAENAMETOOLONG = ESysENAMETOOLONG;
  WSAEHOSTDOWN = ESysEHOSTDOWN;
  WSAEHOSTUNREACH = ESysEHOSTUNREACH;
  WSAENOTEMPTY = ESysENOTEMPTY;
  WSAEPROCLIM = -1;
  WSAEUSERS = ESysEUSERS;
  WSAEDQUOT = ESysEDQUOT;
  WSAESTALE = ESysESTALE;
  WSAEREMOTE = ESysEREMOTE;
  WSASYSNOTREADY = -2;
  WSAVERNOTSUPPORTED = -3;
  WSANOTINITIALISED = -4;
  WSAEDISCON = -5;
  WSAHOST_NOT_FOUND = 1;
  WSATRY_AGAIN = 2;
  WSANO_RECOVERY = 3;
  WSANO_DATA = -6;

CONST
  WSADESCRIPTION_LEN     =   256;
  WSASYS_STATUS_LEN      =   128;
TYPE
  PWSAData = ^TWSAData;
  TWSAData = packed record
    wVersion: word;
    wHighVersion: word;
    szDescription: array[0..WSADESCRIPTION_LEN] of char;
    szSystemStatus: array[0..WSASYS_STATUS_LEN] of char;
    iMaxSockets: word;
    iMaxUdpDg: word;
    lpVendorInfo: PChar;
  end;

  FUNCTION IN6_IS_ADDR_UNSPECIFIED(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_LOOPBACK(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_LINKLOCAL(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_SITELOCAL(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_MULTICAST(CONST a: PInAddr6): boolean;
  FUNCTION IN6_ADDR_EQUAL(CONST a: PInAddr6; CONST b: PInAddr6):boolean;
  PROCEDURE SET_IN6_IF_ADDR_ANY (CONST a: PInAddr6);
  PROCEDURE SET_LOOPBACK_ADDR6 (CONST a: PInAddr6);

VAR
  in6addr_any, in6addr_loopback : TInAddr6;

PROCEDURE FD_CLR(Socket: TSocket; VAR FDSet: TFDSet);
FUNCTION FD_ISSET(Socket: TSocket; VAR FDSet: TFDSet): boolean;
PROCEDURE FD_SET(Socket: TSocket; VAR FDSet: TFDSet);
PROCEDURE FD_ZERO(VAR FDSet: TFDSet);

{=============================================================================}

VAR
  SynSockCS: SyncObjs.TCriticalSection;
  SockEnhancedApi: boolean;
  SockWship6Api: boolean;

TYPE
  TVarSin = packed record
  {$ifdef SOCK_HAS_SINLEN}
     sin_len     : cuchar;
  {$endif}
    case integer of
      0: (AddressFamily: sa_family_t);
      1: (
        case sin_family: sa_family_t of
          AF_INET: (sin_port: word;
                    sin_addr: TInAddr;
                    sin_zero: array[0..7] of char);
          AF_INET6: (sin6_port:     word;
                		sin6_flowinfo: Longword;
      	    	      sin6_addr:     TInAddr6;
      		          sin6_scope_id: Longword);
          );
  end;

FUNCTION SizeOfVarSin(sin: TVarSin): integer;

  FUNCTION WSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer;
  FUNCTION WSACleanup: integer;
  FUNCTION WSAGetLastError: integer;
  FUNCTION GetHostName: string;
  FUNCTION Shutdown(s: TSocket; how: integer): integer;
  FUNCTION SetSockOpt(s: TSocket; level, optname: integer; optval: TMemory;
    optlen: integer): integer;
  FUNCTION GetSockOpt(s: TSocket; level, optname: integer; optval: TMemory;
    VAR optlen: integer): integer;
  FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
  FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
  FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
  FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
  FUNCTION ntohs(netshort: word): word;
  FUNCTION ntohl(netlong: Longword): Longword;
  FUNCTION Listen(s: TSocket; backlog: integer): integer;
  FUNCTION IoctlSocket(s: TSocket; cmd: dword; VAR arg: integer): integer;
  FUNCTION htons(hostshort: word): word;
  FUNCTION htonl(hostlong: Longword): Longword;
  FUNCTION GetSockName(s: TSocket; VAR name: TVarSin): integer;
  FUNCTION GetPeerName(s: TSocket; VAR name: TVarSin): integer;
  FUNCTION Connect(s: TSocket; CONST name: TVarSin): integer;
  FUNCTION CloseSocket(s: TSocket): integer;
  FUNCTION Bind(s: TSocket; CONST addr: TVarSin): integer;
  FUNCTION accept(s: TSocket; VAR addr: TVarSin): TSocket;
  FUNCTION Socket(af, struc, Protocol: integer): TSocket;
  FUNCTION Select(nfds: integer; readfds, writefds, exceptfds: PFDSet;
    timeout: PTimeVal): longint;

FUNCTION IsNewApi(Family: integer): boolean;
FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family, SockProtocol, SockType: integer; PreferIP4: boolean): integer;
FUNCTION GetSinIP(sin: TVarSin): string;
FUNCTION GetSinPort(sin: TVarSin): integer;
PROCEDURE ResolveNameToIP(name: string;  Family, SockProtocol, SockType: integer; CONST IPList: TStrings);
FUNCTION ResolveIPToName(IP: string; Family, SockProtocol, SockType: integer): string;
FUNCTION ResolvePort(Port: string; Family, SockProtocol, SockType: integer): word;


{==============================================================================}
IMPLEMENTATION


FUNCTION IN6_IS_ADDR_UNSPECIFIED(CONST a: PInAddr6): boolean;
begin
  result := ((a^.u6_addr32[0] = 0) and (a^.u6_addr32[1] = 0) and
             (a^.u6_addr32[2] = 0) and (a^.u6_addr32[3] = 0));
end;

FUNCTION IN6_IS_ADDR_LOOPBACK(CONST a: PInAddr6): boolean;
begin
  result := ((a^.u6_addr32[0] = 0) and (a^.u6_addr32[1] = 0) and
             (a^.u6_addr32[2] = 0) and
             (a^.u6_addr8[12] = 0) and (a^.u6_addr8[13] = 0) and
             (a^.u6_addr8[14] = 0) and (a^.u6_addr8[15] = 1));
end;

FUNCTION IN6_IS_ADDR_LINKLOCAL(CONST a: PInAddr6): boolean;
begin
  result := ((a^.u6_addr8[0] = $FE) and (a^.u6_addr8[1] = $80));
end;

FUNCTION IN6_IS_ADDR_SITELOCAL(CONST a: PInAddr6): boolean;
begin
  result := ((a^.u6_addr8[0] = $FE) and (a^.u6_addr8[1] = $C0));
end;

FUNCTION IN6_IS_ADDR_MULTICAST(CONST a: PInAddr6): boolean;
begin
  result := (a^.u6_addr8[0] = $ff);
end;

FUNCTION IN6_ADDR_EQUAL(CONST a: PInAddr6; CONST b: PInAddr6): boolean;
begin
  result := (CompareMem( a, b, sizeOf(TInAddr6)));
end;

PROCEDURE SET_IN6_IF_ADDR_ANY (CONST a: PInAddr6);
begin
  FillChar(a^, sizeOf(TInAddr6), 0);
end;

PROCEDURE SET_LOOPBACK_ADDR6 (CONST a: PInAddr6);
begin
  FillChar(a^, sizeOf(TInAddr6), 0);
  a^.u6_addr8[15] := 1;
end;

{=============================================================================}

FUNCTION WSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer;
begin
  with WSData do
  begin
    wVersion := wVersionRequired;
    wHighVersion := $202;
    szDescription := 'Synsock - Synapse Platform Independent Socket Layer';
    szSystemStatus := 'Running on Unix/Linux by FreePascal';
    iMaxSockets := 32768;
    iMaxUdpDg := 8192;
  end;
  result := 0;
end;

FUNCTION WSACleanup: integer;
begin
  result := 0;
end;

FUNCTION WSAGetLastError: integer;
begin
  result := fpGetErrno;
end;

FUNCTION FD_ISSET(Socket: TSocket; VAR fdset: TFDSet): boolean;
begin
  result := fpFD_ISSET(socket, fdset) <> 0;
end;

PROCEDURE FD_SET(Socket: TSocket; VAR fdset: TFDSet);
begin
  fpFD_SET(Socket, fdset);
end;

PROCEDURE FD_CLR(Socket: TSocket; VAR fdset: TFDSet);
begin
  fpFD_CLR(Socket, fdset);
end;

PROCEDURE FD_ZERO(VAR fdset: TFDSet);
begin
  fpFD_ZERO(fdset);
end;

{=============================================================================}

FUNCTION SizeOfVarSin(sin: TVarSin): integer;
begin
  case sin.sin_family of
    AF_INET:
            result := sizeOf(TSockAddrIn);
    AF_INET6:
            result := sizeOf(TSockAddrIn6);
  else
    result := 0;
  end;
end;

{=============================================================================}

FUNCTION Bind(s: TSocket; CONST addr: TVarSin): integer;
begin
  if fpBind(s, @addr, SizeOfVarSin(addr)) = 0 then
    result := 0
  else
    result := SOCKET_ERROR;
end;

FUNCTION Connect(s: TSocket; CONST name: TVarSin): integer;
begin
  if fpConnect(s, @name, SizeOfVarSin(name)) = 0 then
    result := 0
  else
    result := SOCKET_ERROR;
end;

FUNCTION GetSockName(s: TSocket; VAR name: TVarSin): integer;
VAR
  len: integer;
begin
  len := sizeOf(name);
  FillChar(name, len, 0);
  result := fpGetSockName(s, @name, @len);
end;

FUNCTION GetPeerName(s: TSocket; VAR name: TVarSin): integer;
VAR
  len: integer;
begin
  len := sizeOf(name);
  FillChar(name, len, 0);
  result := fpGetPeerName(s, @name, @len);
end;

FUNCTION GetHostName: string;
begin
  result := unix.GetHostName;
end;

FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
begin
  result := fpSend(s, pointer(Buf), len, flags);
end;

FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
begin
  result := fpRecv(s, pointer(Buf), len, flags);
end;

FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
begin
  result := fpSendTo(s, pointer(Buf), len, flags, @addrto, SizeOfVarSin(addrto));
end;

FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
VAR
  x: integer;
begin
  x := sizeOf(from);
  result := fpRecvFrom(s, pointer(Buf), len, flags, @from, @x);
end;

FUNCTION accept(s: TSocket; VAR addr: TVarSin): TSocket;
VAR
  x: integer;
begin
  x := sizeOf(addr);
  result := fpAccept(s, @addr, @x);
end;

FUNCTION Shutdown(s: TSocket; how: integer): integer;
begin
  result := fpShutdown(s, how);
end;

FUNCTION SetSockOpt(s: TSocket; level, optname: integer; optval: Tmemory;
  optlen: integer): integer;
begin
  result := fpsetsockopt(s, level, optname, pointer(optval), optlen);
end;

FUNCTION GetSockOpt(s: TSocket; level, optname: integer; optval: Tmemory;
  VAR optlen: integer): integer;
begin
  result := fpgetsockopt(s, level, optname, pointer(optval), @optlen);
end;

FUNCTION  ntohs(netshort: word): word;
begin
  result := sockets.ntohs(NetShort);
end;

FUNCTION  ntohl(netlong: Longword): Longword;
begin
  result := sockets.ntohl(NetLong);
end;

FUNCTION  Listen(s: TSocket; backlog: integer): integer;
begin
  if fpListen(s, backlog) = 0 then
    result := 0
  else
    result := SOCKET_ERROR;
end;

FUNCTION  IoctlSocket(s: TSocket; cmd: dword; VAR arg: integer): integer;
begin
  result := fpIoctl(s, cmd, @arg);
end;

FUNCTION  htons(hostshort: word): word;
begin
  result := sockets.htons(Hostshort);
end;

FUNCTION  htonl(hostlong: Longword): Longword;
begin
  result := sockets.htonl(HostLong);
end;

FUNCTION CloseSocket(s: TSocket): integer;
begin
  result := sockets.CloseSocket(s);
end;

FUNCTION Socket(af, struc, Protocol: integer): TSocket;
begin
  result := fpSocket(af, struc, protocol);
end;

FUNCTION Select(nfds: integer; readfds, writefds, exceptfds: PFDSet;
  timeout: PTimeVal): longint;
begin
  result := fpSelect(nfds, readfds, writefds, exceptfds, timeout);
end;

{=============================================================================}
FUNCTION IsNewApi(Family: integer): boolean;
begin
  result := SockEnhancedApi;
  if not result then
    result := (Family = AF_INET6) and SockWship6Api;
end;

FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family, SockProtocol, SockType: integer; PreferIP4: boolean): integer;
VAR
  TwoPass: boolean;
  f1, f2: integer;

  FUNCTION GetAddr(f:integer): integer;
  VAR
    a4: array [1..1] of in_addr;
    a6: array [1..1] of Tin6_addr;
    he: THostEntry;
  begin
    result := WSAEPROTONOSUPPORT;
    case f of
      AF_INET:
        begin
          if IP = cAnyHost then
          begin
            sin.sin_family := AF_INET;
            result := 0;
          end
          else
          begin
            if lowercase(IP) = cLocalHostStr then
              a4[1].s_addr := htonl(INADDR_LOOPBACK)
            else
            begin
              a4[1].s_addr := 0;
              result := WSAHOST_NOT_FOUND;
              a4[1] := StrTonetAddr(IP);
              if a4[1].s_addr = INADDR_ANY then
                if GetHostByName(ip, he) then
                  a4[1]:=HostToNet(he.Addr)
                else
                  Resolvename(ip, a4);
            end;
            if a4[1].s_addr <> INADDR_ANY then
            begin
              sin.sin_family := AF_INET;
              sin.sin_addr := a4[1];
              result := 0;
            end;
          end;
        end;
      AF_INET6:
        begin
          if IP = c6AnyHost then
          begin
            sin.sin_family := AF_INET6;
            result := 0;
          end
          else
          begin
            if lowercase(IP) = cLocalHostStr then
              SET_LOOPBACK_ADDR6(@a6[1])
            else
            begin
              result := WSAHOST_NOT_FOUND;
              SET_IN6_IF_ADDR_ANY(@a6[1]);
              a6[1] := StrTonetAddr6(IP);
              if IN6_IS_ADDR_UNSPECIFIED(@a6[1]) then
                Resolvename6(ip, a6);
            end;
            if not IN6_IS_ADDR_UNSPECIFIED(@a6[1]) then
            begin
              sin.sin_family := AF_INET6;
              sin.sin6_addr := a6[1];
              result := 0;
            end;
          end;
        end;
    end;
  end;
begin
  result := 0;
  FillChar(sin, sizeOf(sin), 0);
  sin.sin_port := Resolveport(port, family, SockProtocol, SockType);
  TwoPass := false;
  if Family = AF_UNSPEC then
  begin
    if PreferIP4 then
    begin
      f1 := AF_INET;
      f2 := AF_INET6;
      TwoPass := true;
    end
    else
    begin
      f2 := AF_INET;
      f1 := AF_INET6;
      TwoPass := true;
    end;
  end
  else
    f1 := Family;
  result := GetAddr(f1);
  if result <> 0 then
    if TwoPass then
      result := GetAddr(f2);
end;

FUNCTION GetSinIP(sin: TVarSin): string;
begin
  result := '';
  case sin.AddressFamily of
    AF_INET:
      begin
        result := NetAddrToStr(sin.sin_addr);
      end;
    AF_INET6:
      begin
        result := NetAddrToStr6(sin.sin6_addr);
      end;
  end;
end;

FUNCTION GetSinPort(sin: TVarSin): integer;
begin
  if (sin.sin_family = AF_INET6) then
    result := synsock.ntohs(sin.sin6_port)
  else
    result := synsock.ntohs(sin.sin_port);
end;

PROCEDURE ResolveNameToIP(name: string; Family, SockProtocol, SockType: integer; CONST IPList: TStrings);
VAR
  x, n: integer;
  a4: array [1..255] of in_addr;
  a6: array [1..255] of Tin6_addr;
  he: THostEntry;
begin
  IPList.clear;
  if (family = AF_INET) or (family = AF_UNSPEC) then
  begin
    if lowercase(name) = cLocalHostStr then
      IpList.add(cLocalHost)
    else
    begin
      a4[1] := StrTonetAddr(name);
      if a4[1].s_addr = INADDR_ANY then
        if GetHostByName(name, he) then
        begin
          a4[1]:=HostToNet(he.Addr);
          x := 1;
        end
        else
          x := Resolvename(name, a4)
      else
        x := 1;
      for n := 1  to x do
        IpList.add(netaddrToStr(a4[n]));
    end;
  end;

  if (family = AF_INET6) or (family = AF_UNSPEC) then
  begin
    if lowercase(name) = cLocalHostStr then
      IpList.add(c6LocalHost)
    else
    begin
      a6[1] := StrTonetAddr6(name);
      if IN6_IS_ADDR_UNSPECIFIED(@a6[1]) then
        x := Resolvename6(name, a6)
      else
        x := 1;
      for n := 1  to x do
        IpList.add(netaddrToStr6(a6[n]));
    end;
  end;

  if IPList.count = 0 then
    IPList.add(cLocalHost);
end;

FUNCTION ResolvePort(Port: string; Family, SockProtocol, SockType: integer): word;
VAR
  ProtoEnt: TProtocolEntry;
  ServEnt: TServiceEntry;
begin
  result := synsock.htons(strToIntDef(Port, 0));
  if result = 0 then
  begin
    ProtoEnt.name := '';
    GetProtocolByNumber(SockProtocol, ProtoEnt);
    ServEnt.port := 0;
    GetServiceByName(Port, ProtoEnt.name, ServEnt);
    result := ServEnt.port;
  end;
end;

FUNCTION ResolveIPToName(IP: string; Family, SockProtocol, SockType: integer): string;
VAR
  n: integer;
  a4: array [1..1] of in_addr;
  a6: array [1..1] of Tin6_addr;
  a: array [1..1] of string;
begin
  result := IP;
  a4[1] := StrToNetAddr(IP);
  if a4[1].s_addr <> INADDR_ANY then
  begin
//why ResolveAddress need address in HOST order? :-O
    n := ResolveAddress(nettohost(a4[1]), a);
    if n > 0 then
      result := a[1];
  end
  else
  begin
    a6[1] := StrToNetAddr6(IP);
    n := ResolveAddress6(a6[1], a);
    if n > 0 then
      result := a[1];
  end;
end;

{=============================================================================}

FUNCTION InitSocketInterface(stack: string): boolean;
begin
  SockEnhancedApi := false;
  SockWship6Api := false;
//  Libc.Signal(Libc.SIGPIPE, TSignalHandler(Libc.SIG_IGN));
  result := true;
end;

FUNCTION DestroySocketInterface: boolean;
begin
  result := true;
end;

INITIALIZATION
begin
  SynSockCS := SyncObjs.TCriticalSection.create;
  SET_IN6_IF_ADDR_ANY (@in6addr_any);
  SET_LOOPBACK_ADDR6  (@in6addr_loopback);
end;

FINALIZATION
begin
  SynSockCS.free;
end;

{$ENDIF}

