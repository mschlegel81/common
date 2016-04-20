{==============================================================================|
| project : Ararat Synapse                                       | 002.000.009 |
|==============================================================================|
| content: Socket Independent Platform Layer - Linux definition include        |
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
| Portions created by Lukas Gebauer are Copyright (c)2003-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@exclude}

{$IFDEF LINUX}

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
INTERFACE

USES
  SyncObjs, sysutils, Classes,
  synafpc,
  Libc;

FUNCTION InitSocketInterface(stack: string): boolean;
FUNCTION DestroySocketInterface: boolean;

CONST
  WinsockLevel = $0202;

TYPE
  u_char = char;
  u_short = word;
  u_int = integer;
  u_long = longint;
  pu_long = ^u_long;
  pu_short = ^u_short;
  TSocket = u_int;
  TAddrFamily = integer;

  TMemory = pointer;


CONST
  DLLStackName = 'libc.so.6';

  cLocalhost = '127.0.0.1';
  cAnyHost = '0.0.0.0';
  cBroadcast = '255.255.255.255';
  c6Localhost = '::1';
  c6AnyHost = '::0';
  c6Broadcast = 'ffff::1';
  cAnyPort = '0';

TYPE
  dword = integer;
  __fd_mask = Longword;
CONST
  __FD_SETSIZE    = 1024;
  __NFDBITS       = 8 * sizeOf(__fd_mask);
TYPE
  __fd_set = {packed} record
    fds_bits: packed array[0..(__FD_SETSIZE div __NFDBITS)-1] of __fd_mask;
  end;
  TFDSet = __fd_set;
  PFDSet = ^TFDSet;

CONST
  FIONREAD        = $541B;
  FIONBIO         = $5421;
  FIOASYNC        = $5452;

TYPE
  PTimeVal = ^TTimeVal;
  TTimeVal = packed record
    tv_sec: longint;
    tv_usec: longint;
  end;

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
  TInAddr = packed record
    case integer of
      0: (S_bytes: packed array [0..3] of byte);
      1: (S_addr: u_long);
  end;

  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = packed record
    case integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of char);
      1: (sa_family: u_short;
          sa_data: array[0..13] of char)
  end;

  TIP_mreq =  record
    imr_multiaddr: TInAddr;     { IP multicast address of group }
    imr_interface: TInAddr;     { local IP address of interface }
  end;

  PInAddr6 = ^TInAddr6;
  TInAddr6 = packed record
    case integer of
      0: (S6_addr: packed array [0..15] of byte);
      1: (u6_addr8: packed array [0..15] of byte);
      2: (u6_addr16: packed array [0..7] of word);
      3: (u6_addr32: packed array [0..3] of integer);
  end;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = packed record
		sin6_family:   u_short;     // AF_INET6
		sin6_port:     u_short;     // Transport level port number
		sin6_flowinfo: u_long;	    // IPv6 flow information
		sin6_addr:     TInAddr6;    // IPv6 address
		sin6_scope_id: u_long;      // Scope Id: IF number for link-local
                                //           SITE id for site-local
  end;

  TIPv6_mreq = record
    ipv6mr_multiaddr: TInAddr6; // IPv6 multicast address.
    ipv6mr_interface: integer;   // Interface index.
    padding: u_long;
  end;

  PHostEnt = ^THostEnt;
  THostent = record
    h_name: PChar;
    h_aliases: PPChar;
    h_addrtype: integer;
    h_length: Cardinal;
    case byte of
      0: (h_addr_list: PPChar);
      1: (h_addr: PPChar);
  end;

  PNetEnt = ^TNetEnt;
  TNetEnt = record
    n_name: PChar;
    n_aliases: PPChar;
    n_addrtype: integer;
    n_net: uint32_t;
  end;

  PServEnt = ^TServEnt;
  TServEnt = record
    s_name: PChar;
    s_aliases: PPChar;
    s_port: integer;
    s_proto: PChar;
  end;

  PProtoEnt = ^TProtoEnt;
  TProtoEnt = record
    p_name: PChar;
    p_aliases: ^PChar;
    p_proto: u_short;
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
  IP_TOS             = 1;  { int; IP type of service and precedence.  }
  IP_TTL             = 2;  { int; IP time to live.  }
  IP_HDRINCL         = 3;  { int; Header is included with data.  }
  IP_OPTIONS         = 4;  { ip_opts; IP per-packet options.  }
  IP_ROUTER_ALERT    = 5;  { bool }
  IP_RECVOPTS        = 6;  { bool }
  IP_RETOPTS         = 7;  { bool }
  IP_PKTINFO         = 8;  { bool }
  IP_PKTOPTIONS      = 9;
  IP_PMTUDISC        = 10; { obsolete name? }
  IP_MTU_DISCOVER    = 10; { int; see below }
  IP_RECVERR         = 11; { bool }
  IP_RECVTTL         = 12; { bool }
  IP_RECVTOS         = 13; { bool }
  IP_MULTICAST_IF    = 32; { in_addr; set/get IP multicast i/f }
  IP_MULTICAST_TTL   = 33; { u_char; set/get IP multicast ttl }
  IP_MULTICAST_LOOP  = 34; { i_char; set/get IP multicast loopback }
  IP_ADD_MEMBERSHIP  = 35; { ip_mreq; add an IP group membership }
  IP_DROP_MEMBERSHIP = 36; { ip_mreq; drop an IP group membership }

  SOL_SOCKET    = 1;

  SO_DEBUG      = 1;
  SO_REUSEADDR  = 2;
  SO_TYPE       = 3;
  SO_ERROR      = 4;
  SO_DONTROUTE  = 5;
  SO_BROADCAST  = 6;
  SO_SNDBUF     = 7;
  SO_RCVBUF     = 8;
  SO_KEEPALIVE  = 9;
  SO_OOBINLINE  = 10;
  SO_NO_CHECK   = 11;
  SO_PRIORITY   = 12;
  SO_LINGER     = 13;
  SO_BSDCOMPAT  = 14;
  SO_REUSEPORT  = 15;
  SO_PASSCRED   = 16;
  SO_PEERCRED   = 17;
  SO_RCVLOWAT   = 18;
  SO_SNDLOWAT   = 19;
  SO_RCVTIMEO   = 20;
  SO_SNDTIMEO   = 21;
{ Security levels - as per NRL IPv6 - don't actually do anything }
  SO_SECURITY_AUTHENTICATION       = 22;
  SO_SECURITY_ENCRYPTION_TRANSPORT = 23;
  SO_SECURITY_ENCRYPTION_NETWORK   = 24;
  SO_BINDTODEVICE                  = 25;
{ Socket filtering }
  SO_ATTACH_FILTER = 26;
  SO_DETACH_FILTER = 27;

  SOMAXCONN       = 128;

  IPV6_UNICAST_HOPS     = 16;
  IPV6_MULTICAST_IF     = 17;
  IPV6_MULTICAST_HOPS   = 18;
  IPV6_MULTICAST_LOOP   = 19;
  IPV6_JOIN_GROUP       = 20;
  IPV6_LEAVE_GROUP      = 21;

  MSG_NOSIGNAL  = $4000;                // Do not generate SIGPIPE.

  // getnameinfo constants
  NI_MAXHOST	   = 1025;
  NI_MAXSERV	   = 32;
  NI_NOFQDN 	   = $4;
  NI_NUMERICHOST = $1;
  NI_NAMEREQD	   = $8;
  NI_NUMERICSERV = $2;
  NI_DGRAM       = $10;

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
  { Structure used by kernel to store most addresses. }
  PSockAddr = ^TSockAddr;
  TSockAddr = TSockAddrIn;

  { Structure used by kernel to pass protocol information in raw sockets. }
  PSockProto = ^TSockProto;
  TSockProto = packed record
    sp_family: u_short;
    sp_protocol: u_short;
  end;

TYPE
  PAddrInfo = ^TAddrInfo;
  TAddrInfo = record
                ai_flags: integer;    // AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST.
                ai_family: integer;   // PF_xxx.
                ai_socktype: integer; // SOCK_xxx.
                ai_protocol: integer; // 0 or IPPROTO_xxx for IPv4 and IPv6.
                ai_addrlen: u_int;    // Length of ai_addr.
                ai_addr: PSockAddr;   // Binary address.
                ai_canonname: PChar;  // Canonical name for nodename.
                ai_next: PAddrInfo;     // Next structure in linked list.
              end;

CONST
  // Flags used in "hints" argument to getaddrinfo().
  AI_PASSIVE     = $1;  // Socket address will be used in bind() call.
  AI_CANONNAME   = $2;  // Return canonical name in first ai_canonname.
  AI_NUMERICHOST = $4;  // Nodename must be a numeric address string.

TYPE
{ Structure used for manipulating linger option. }
  PLinger = ^TLinger;
  TLinger = packed record
    l_onoff: integer;
    l_linger: integer;
  end;

CONST

  MSG_OOB       = $01;                  // Process out-of-band data.
  MSG_PEEK      = $02;                  // Peek at incoming messages.

CONST
  WSAEINTR = EINTR;
  WSAEBADF = EBADF;
  WSAEACCES = EACCES;
  WSAEFAULT = EFAULT;
  WSAEINVAL = EINVAL;
  WSAEMFILE = EMFILE;
  WSAEWOULDBLOCK = EWOULDBLOCK;
  WSAEINPROGRESS = EINPROGRESS;
  WSAEALREADY = EALREADY;
  WSAENOTSOCK = ENOTSOCK;
  WSAEDESTADDRREQ = EDESTADDRREQ;
  WSAEMSGSIZE = EMSGSIZE;
  WSAEPROTOTYPE = EPROTOTYPE;
  WSAENOPROTOOPT = ENOPROTOOPT;
  WSAEPROTONOSUPPORT = EPROTONOSUPPORT;
  WSAESOCKTNOSUPPORT = ESOCKTNOSUPPORT;
  WSAEOPNOTSUPP = EOPNOTSUPP;
  WSAEPFNOSUPPORT = EPFNOSUPPORT;
  WSAEAFNOSUPPORT = EAFNOSUPPORT;
  WSAEADDRINUSE = EADDRINUSE;
  WSAEADDRNOTAVAIL = EADDRNOTAVAIL;
  WSAENETDOWN = ENETDOWN;
  WSAENETUNREACH = ENETUNREACH;
  WSAENETRESET = ENETRESET;
  WSAECONNABORTED = ECONNABORTED;
  WSAECONNRESET = ECONNRESET;
  WSAENOBUFS = ENOBUFS;
  WSAEISCONN = EISCONN;
  WSAENOTCONN = ENOTCONN;
  WSAESHUTDOWN = ESHUTDOWN;
  WSAETOOMANYREFS = ETOOMANYREFS;
  WSAETIMEDOUT = ETIMEDOUT;
  WSAECONNREFUSED = ECONNREFUSED;
  WSAELOOP = ELOOP;
  WSAENAMETOOLONG = ENAMETOOLONG;
  WSAEHOSTDOWN = EHOSTDOWN;
  WSAEHOSTUNREACH = EHOSTUNREACH;
  WSAENOTEMPTY = ENOTEMPTY;
  WSAEPROCLIM = -1;
  WSAEUSERS = EUSERS;
  WSAEDQUOT = EDQUOT;
  WSAESTALE = ESTALE;
  WSAEREMOTE = EREMOTE;
  WSASYSNOTREADY = -2;
  WSAVERNOTSUPPORTED = -3;
  WSANOTINITIALISED = -4;
  WSAEDISCON = -5;
  WSAHOST_NOT_FOUND = HOST_NOT_FOUND;
  WSATRY_AGAIN = TRY_AGAIN;
  WSANO_RECOVERY = NO_RECOVERY;
  WSANO_DATA = -6;

  EAI_BADFLAGS    = -1;   { Invalid value for `ai_flags' field.  }
  EAI_NONAME      = -2;   { NAME or SERVICE is unknown.  }
  EAI_AGAIN       = -3;   { Temporary failure in name resolution.  }
  EAI_FAIL        = -4;   { Non-recoverable failure in name res.  }
  EAI_NODATA      = -5;   { No address associated with NAME.  }
  EAI_FAMILY      = -6;   { `ai_family' not supported.  }
  EAI_SOCKTYPE    = -7;   { `ai_socktype' not supported.  }
  EAI_SERVICE     = -8;   { SERVICE not supported for `ai_socktype'.  }
  EAI_ADDRFAMILY  = -9;   { Address family for NAME not supported.  }
  EAI_MEMORY      = -10;  { Memory allocation failure.  }
  EAI_SYSTEM      = -11;  { System error returned in `errno'.  }

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

TYPE
  TWSAStartup = FUNCTION(wVersionRequired: word; VAR WSData: TWSAData): integer;
    cdecl;
  TWSACleanup = FUNCTION: integer;
    cdecl;
  TWSAGetLastError = FUNCTION: integer;
    cdecl;
  TGetServByName = FUNCTION(name, proto: PChar): PServEnt;
    cdecl;
  TGetServByPort = FUNCTION(port: integer; proto: PChar): PServEnt;
    cdecl;
  TGetProtoByName = FUNCTION(name: PChar): PProtoEnt;
    cdecl;
  TGetProtoByNumber = FUNCTION(proto: integer): PProtoEnt;
    cdecl;
  TGetHostByName = FUNCTION(name: PChar): PHostEnt;
    cdecl;
  TGetHostByAddr = FUNCTION(addr: pointer; len, struc: integer): PHostEnt;
    cdecl;
  TGetHostName = FUNCTION(name: PChar; len: integer): integer;
    cdecl;
  TShutdown = FUNCTION(s: TSocket; how: integer): integer;
    cdecl;
  TSetSockOpt = FUNCTION(s: TSocket; level, optname: integer; optval: PChar;
    optlen: integer): integer;
    cdecl;
  TGetSockOpt = FUNCTION(s: TSocket; level, optname: integer; optval: PChar;
    VAR optlen: integer): integer;
    cdecl;
  TSendTo = FUNCTION(s: TSocket; CONST Buf; len, flags: integer; addrto: PSockAddr;
    tolen: integer): integer;
    cdecl;
  TSend = FUNCTION(s: TSocket; CONST Buf; len, flags: integer): integer;
    cdecl;
  TRecv = FUNCTION(s: TSocket; VAR Buf; len, flags: integer): integer;
    cdecl;
  TRecvFrom = FUNCTION(s: TSocket; VAR Buf; len, flags: integer; from: PSockAddr;
    VAR fromlen: integer): integer;
    cdecl;
  Tntohs = FUNCTION(netshort: u_short): u_short;
    cdecl;
  Tntohl = FUNCTION(netlong: u_long): u_long;
    cdecl;
  TListen = FUNCTION(s: TSocket; backlog: integer): integer;
    cdecl;
  TIoctlSocket = FUNCTION(s: TSocket; cmd: dword; VAR arg: integer): integer;
    cdecl;
  TInet_ntoa = FUNCTION(inaddr: TInAddr): PChar;
    cdecl;
  TInet_addr = FUNCTION(cp: PChar): u_long;
    cdecl;
  Thtons = FUNCTION(hostshort: u_short): u_short;
    cdecl;
  Thtonl = FUNCTION(hostlong: u_long): u_long;
    cdecl;
  TGetSockName = FUNCTION(s: TSocket; name: PSockAddr; VAR namelen: integer): integer;
    cdecl;
  TGetPeerName = FUNCTION(s: TSocket; name: PSockAddr; VAR namelen: integer): integer;
    cdecl;
  TConnect = FUNCTION(s: TSocket; name: PSockAddr; namelen: integer): integer;
    cdecl;
  TCloseSocket = FUNCTION(s: TSocket): integer;
    cdecl;
  TBind = FUNCTION(s: TSocket; addr: PSockAddr; namelen: integer): integer;
    cdecl;
  TAccept = FUNCTION(s: TSocket; addr: PSockAddr; VAR addrlen: integer): TSocket;
    cdecl;
  TTSocket = FUNCTION(af, struc, Protocol: integer): TSocket;
    cdecl;
  TSelect = FUNCTION(nfds: integer; readfds, writefds, exceptfds: PFDSet;
    timeout: PTimeVal): longint;
    cdecl;

  TGetAddrInfo = FUNCTION(NodeName: PChar; ServName: PChar; Hints: PAddrInfo;
    VAR Addrinfo: PAddrInfo): integer;
    cdecl;
  TFreeAddrInfo = PROCEDURE(ai: PAddrInfo);
    cdecl;
  TGetNameInfo = FUNCTION( addr: PSockAddr; namelen: integer; host: PChar;
    hostlen: dword; serv: PChar; servlen: dword; flags: integer): integer;
    cdecl;

VAR
  WSAStartup: TWSAStartup = nil;
  WSACleanup: TWSACleanup = nil;
  WSAGetLastError: TWSAGetLastError = nil;
  GetServByName: TGetServByName = nil;
  GetServByPort: TGetServByPort = nil;
  GetProtoByName: TGetProtoByName = nil;
  GetProtoByNumber: TGetProtoByNumber = nil;
  GetHostByName: TGetHostByName = nil;
  GetHostByAddr: TGetHostByAddr = nil;
  ssGetHostName: TGetHostName = nil;
  Shutdown: TShutdown = nil;
  SetSockOpt: TSetSockOpt = nil;
  GetSockOpt: TGetSockOpt = nil;
  ssSendTo: TSendTo = nil;
  ssSend: TSend = nil;
  ssRecv: TRecv = nil;
  ssRecvFrom: TRecvFrom = nil;
  ntohs: Tntohs = nil;
  ntohl: Tntohl = nil;
  Listen: TListen = nil;
  IoctlSocket: TIoctlSocket = nil;
  Inet_ntoa: TInet_ntoa = nil;
  Inet_addr: TInet_addr = nil;
  htons: Thtons = nil;
  htonl: Thtonl = nil;
  ssGetSockName: TGetSockName = nil;
  ssGetPeerName: TGetPeerName = nil;
  ssConnect: TConnect = nil;
  CloseSocket: TCloseSocket = nil;
  ssBind: TBind = nil;
  ssAccept: TAccept = nil;
  Socket: TTSocket = nil;
  Select: TSelect = nil;

  GetAddrInfo: TGetAddrInfo = nil;
  FreeAddrInfo: TFreeAddrInfo = nil;
  GetNameInfo: TGetNameInfo = nil;

FUNCTION LSWSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer; cdecl;
FUNCTION LSWSACleanup: integer; cdecl;
FUNCTION LSWSAGetLastError: integer; cdecl;

VAR
  SynSockCS: SyncObjs.TCriticalSection;
  SockEnhancedApi: boolean;
  SockWship6Api: boolean;

TYPE
  TVarSin = packed record
    case integer of
      0: (AddressFamily: u_short);
      1: (
        case sin_family: u_short of
          AF_INET: (sin_port: u_short;
                    sin_addr: TInAddr;
                    sin_zero: array[0..7] of char);
          AF_INET6: (sin6_port:     u_short;
                		sin6_flowinfo: u_long;
      	    	      sin6_addr:     TInAddr6;
      		          sin6_scope_id: u_long);
          );
  end;

FUNCTION SizeOfVarSin(sin: TVarSin): integer;

FUNCTION Bind(s: TSocket; CONST addr: TVarSin): integer;
FUNCTION Connect(s: TSocket; CONST name: TVarSin): integer;
FUNCTION GetSockName(s: TSocket; VAR name: TVarSin): integer;
FUNCTION GetPeerName(s: TSocket; VAR name: TVarSin): integer;
FUNCTION GetHostName: string;
FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
FUNCTION accept(s: TSocket; VAR addr: TVarSin): TSocket;

FUNCTION IsNewApi(Family: integer): boolean;
FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family, SockProtocol, SockType: integer; PreferIP4: boolean): integer;
FUNCTION GetSinIP(sin: TVarSin): string;
FUNCTION GetSinPort(sin: TVarSin): integer;
PROCEDURE ResolveNameToIP(name: string;  Family, SockProtocol, SockType: integer; CONST IPList: TStrings);
FUNCTION ResolveIPToName(IP: string; Family, SockProtocol, SockType: integer): string;
FUNCTION ResolvePort(Port: string; Family, SockProtocol, SockType: integer): word;

{==============================================================================}
IMPLEMENTATION

VAR
  SynSockCount: integer = 0;
  LibHandle: TLibHandle = 0;
  Libwship6Handle: TLibHandle = 0;

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
VAR
{$IFNDEF VER1_0}  //FTP version 1.0.x
  errno_loc: FUNCTION: PInteger cdecl = nil;
{$ELSE}
  errno_loc: FUNCTION: PInteger = nil; cdecl;
{$ENDIF}

FUNCTION LSWSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer;
begin
  with WSData do
  begin
    wVersion := wVersionRequired;
    wHighVersion := $202;
    szDescription := 'Synsock - Synapse Platform Independent Socket Layer';
    szSystemStatus := 'Running on Linux';
    iMaxSockets := 32768;
    iMaxUdpDg := 8192;
  end;
  result := 0;
end;

FUNCTION LSWSACleanup: integer;
begin
  result := 0;
end;

FUNCTION LSWSAGetLastError: integer;
VAR
  p: PInteger;
begin
  p := errno_loc;
  result := p^;
end;

FUNCTION __FDELT(Socket: TSocket): integer;
begin
  result := Socket div __NFDBITS;
end;

FUNCTION __FDMASK(Socket: TSocket): __fd_mask;
begin
  result := Longword(1) shl (Socket mod __NFDBITS);
end;

FUNCTION FD_ISSET(Socket: TSocket; VAR fdset: TFDSet): boolean;
begin
  result := (fdset.fds_bits[__FDELT(Socket)] and __FDMASK(Socket)) <> 0;
end;

PROCEDURE FD_SET(Socket: TSocket; VAR fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(Socket)] := fdset.fds_bits[__FDELT(Socket)] or __FDMASK(Socket);
end;

PROCEDURE FD_CLR(Socket: TSocket; VAR fdset: TFDSet);
begin
  fdset.fds_bits[__FDELT(Socket)] := fdset.fds_bits[__FDELT(Socket)] and (not __FDMASK(Socket));
end;

PROCEDURE FD_ZERO(VAR fdset: TFDSet);
VAR
  I: integer;
begin
  with fdset do
    for I := low(fds_bits) to high(fds_bits) do
      fds_bits[I] := 0;
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
  result := ssBind(s, @addr, SizeOfVarSin(addr));
end;

FUNCTION Connect(s: TSocket; CONST name: TVarSin): integer;
begin
  result := ssConnect(s, @name, SizeOfVarSin(name));
end;

FUNCTION GetSockName(s: TSocket; VAR name: TVarSin): integer;
VAR
  len: integer;
begin
  len := sizeOf(name);
  FillChar(name, len, 0);
  result := ssGetSockName(s, @name, len);
end;

FUNCTION GetPeerName(s: TSocket; VAR name: TVarSin): integer;
VAR
  len: integer;
begin
  len := sizeOf(name);
  FillChar(name, len, 0);
  result := ssGetPeerName(s, @name, len);
end;

FUNCTION GetHostName: string;
VAR
  s: string;
begin
  result := '';
  setLength(s, 255);
  ssGetHostName(PChar(s), length(s) - 1);
  result := PChar(s);
end;

FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
begin
  result := ssSend(s, Buf^, len, flags);
end;

FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
begin
  result := ssRecv(s, Buf^, len, flags);
end;

FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
begin
  result := ssSendTo(s, Buf^, len, flags, @addrto, SizeOfVarSin(addrto));
end;

FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
VAR
  x: integer;
begin
  x := sizeOf(from);
  result := ssRecvFrom(s, Buf^, len, flags, @from, x);
end;

FUNCTION accept(s: TSocket; VAR addr: TVarSin): TSocket;
VAR
  x: integer;
begin
  x := sizeOf(addr);
  result := ssAccept(s, @addr, x);
end;

{=============================================================================}
FUNCTION IsNewApi(Family: integer): boolean;
begin
  result := SockEnhancedApi;
  if not result then
    result := (Family = AF_INET6) and SockWship6Api;
end;

FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family, SockProtocol, SockType: integer; PreferIP4: boolean): integer;
TYPE
  pu_long = ^u_long;
VAR
  ProtoEnt: PProtoEnt;
  ServEnt: PServEnt;
  HostEnt: PHostEnt;
  r: integer;
  Hints1, Hints2: TAddrInfo;
  Sin1, Sin2: TVarSin;
  TwoPass: boolean;

  FUNCTION GetAddr(CONST IP, port: string; Hints: TAddrInfo; VAR sin: TVarSin): integer;
  VAR
    Addr: PAddrInfo;
  begin
    Addr := nil;
    try
      FillChar(sin, sizeOf(sin), 0);
      if Hints.ai_socktype = SOCK_RAW then
      begin
        Hints.ai_socktype := 0;
        Hints.ai_protocol := 0;
        result := synsock.GetAddrInfo(PChar(IP), nil, @Hints, Addr);
      end
      else
      begin
        if (IP = cAnyHost) or (IP = c6AnyHost) then
        begin
          Hints.ai_flags := AI_PASSIVE;
          result := synsock.GetAddrInfo(nil, PChar(Port), @Hints, Addr);
        end
        else
          if (IP = cLocalhost) or (IP = c6Localhost) then
          begin
            result := synsock.GetAddrInfo(nil, PChar(Port), @Hints, Addr);
          end
          else
          begin
            result := synsock.GetAddrInfo(PChar(IP), PChar(Port), @Hints, Addr);
          end;
      end;
      if result = 0 then
        if (Addr <> nil) then
          move(Addr^.ai_addr^, sin, Addr^.ai_addrlen);
    finally
      if Assigned(Addr) then
        synsock.FreeAddrInfo(Addr);
    end;
  end;

begin
  result := 0;
  FillChar(sin, sizeOf(sin), 0);
  if not IsNewApi(family) then
  begin
    SynSockCS.Enter;
    try
      sin.sin_family := AF_INET;
      ProtoEnt := synsock.GetProtoByNumber(SockProtocol);
      ServEnt := nil;
      if ProtoEnt <> nil then
        ServEnt := synsock.GetServByName(PChar(Port), ProtoEnt^.p_name);
      if ServEnt = nil then
        sin.sin_port := synsock.htons(strToIntDef(Port, 0))
      else
        sin.sin_port := ServEnt^.s_port;
      if IP = cBroadcast then
        sin.sin_addr.s_addr := u_long(INADDR_BROADCAST)
      else
      begin
        sin.sin_addr.s_addr := synsock.inet_addr(PChar(IP));
        if sin.sin_addr.s_addr = u_long(INADDR_NONE) then
        begin
          HostEnt := synsock.GetHostByName(PChar(IP));
          result := synsock.WSAGetLastError;
          if HostEnt <> nil then
            sin.sin_addr.S_addr := u_long(Pu_long(HostEnt^.h_addr_list^)^);
        end;
      end;
    finally
      SynSockCS.Leave;
    end;
  end
  else
  begin
    FillChar(Hints1, sizeOf(Hints1), 0);
    FillChar(Hints2, sizeOf(Hints2), 0);
    TwoPass := false;
    if Family = AF_UNSPEC then
    begin
      if PreferIP4 then
      begin
        Hints1.ai_family := AF_INET;
        Hints2.ai_family := AF_INET6;
        TwoPass := true;
      end
      else
      begin
        Hints2.ai_family := AF_INET;
        Hints1.ai_family := AF_INET6;
        TwoPass := true;
      end;
    end
    else
      Hints1.ai_family := Family;

    Hints1.ai_socktype := SockType;
    Hints1.ai_protocol := SockProtocol;
    Hints2.ai_socktype := Hints1.ai_socktype;
    Hints2.ai_protocol := Hints1.ai_protocol;

    r := GetAddr(IP, Port, Hints1, Sin1);
    result := r;
    sin := sin1;
    if r <> 0 then
      if TwoPass then
      begin
        r := GetAddr(IP, Port, Hints2, Sin2);
        result := r;
        if r = 0 then
          sin := sin2;
      end;
  end;
end;

FUNCTION GetSinIP(sin: TVarSin): string;
VAR
  p: PChar;
  host, serv: string;
  hostlen, servlen: integer;
  r: integer;
begin
  result := '';
  if not IsNewApi(sin.AddressFamily) then
  begin
    p := synsock.inet_ntoa(sin.sin_addr);
    if p <> nil then
      result := p;
  end
  else
  begin
    hostlen := NI_MAXHOST;
    servlen := NI_MAXSERV;
    setLength(host, hostlen);
    setLength(serv, servlen);
    r := getnameinfo(@sin, SizeOfVarSin(sin), PChar(host), hostlen,
      PChar(serv), servlen, NI_NUMERICHOST + NI_NUMERICSERV);
    if r = 0 then
      result := PChar(host);
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
TYPE
  TaPInAddr = array[0..250] of PInAddr;
  PaPInAddr = ^TaPInAddr;
VAR
  Hints: TAddrInfo;
  Addr: PAddrInfo;
  AddrNext: PAddrInfo;
  r: integer;
  host, serv: string;
  hostlen, servlen: integer;
  RemoteHost: PHostEnt;
  IP: u_long;
  PAdrPtr: PaPInAddr;
  i: integer;
  s: string;
  InAddr: TInAddr;
begin
  IPList.clear;
  if not IsNewApi(Family) then
  begin
    IP := synsock.inet_addr(PChar(name));
    if IP = u_long(INADDR_NONE) then
    begin
      SynSockCS.Enter;
      try
        RemoteHost := synsock.GetHostByName(PChar(name));
        if RemoteHost <> nil then
        begin
          PAdrPtr := PAPInAddr(RemoteHost^.h_addr_list);
          i := 0;
          while PAdrPtr^[i] <> nil do
          begin
            InAddr := PAdrPtr^[i]^;
            s := format('%d.%d.%d.%d', [InAddr.S_bytes[0], InAddr.S_bytes[1],
              InAddr.S_bytes[2], InAddr.S_bytes[3]]);
            IPList.add(s);
            inc(i);
          end;
        end;
      finally
        SynSockCS.Leave;
      end;
    end
    else
      IPList.add(name);
  end
  else
  begin
    Addr := nil;
    try
      FillChar(Hints, sizeOf(Hints), 0);
      Hints.ai_family := AF_UNSPEC;
      Hints.ai_socktype := SockType;
      Hints.ai_protocol := SockProtocol;
      Hints.ai_flags := 0;
      r := synsock.GetAddrInfo(PChar(name), nil, @Hints, Addr);
      if r = 0 then
      begin
        AddrNext := Addr;
        while not(AddrNext = nil) do
        begin
          if not(((Family = AF_INET6) and (AddrNext^.ai_family = AF_INET))
            or ((Family = AF_INET) and (AddrNext^.ai_family = AF_INET6))) then
          begin
            hostlen := NI_MAXHOST;
            servlen := NI_MAXSERV;
            setLength(host, hostlen);
            setLength(serv, servlen);
            r := getnameinfo(AddrNext^.ai_addr, AddrNext^.ai_addrlen,
              PChar(host), hostlen, PChar(serv), servlen,
              NI_NUMERICHOST + NI_NUMERICSERV);
            if r = 0 then
            begin
              host := PChar(host);
              IPList.add(host);
            end;
          end;
          AddrNext := AddrNext^.ai_next;
        end;
      end;
    finally
      if Assigned(Addr) then
        synsock.FreeAddrInfo(Addr);
    end;
  end;
  if IPList.count = 0 then
    IPList.add(cAnyHost);
end;

FUNCTION ResolvePort(Port: string; Family, SockProtocol, SockType: integer): word;
VAR
  ProtoEnt: PProtoEnt;
  ServEnt: PServEnt;
  Hints: TAddrInfo;
  Addr: PAddrInfo;
  r: integer;
begin
  result := 0;
  if not IsNewApi(Family) then
  begin
    SynSockCS.Enter;
    try
      ProtoEnt := synsock.GetProtoByNumber(SockProtocol);
      ServEnt := nil;
      if ProtoEnt <> nil then
        ServEnt := synsock.GetServByName(PChar(Port), ProtoEnt^.p_name);
      if ServEnt = nil then
        result := strToIntDef(Port, 0)
      else
        result := synsock.htons(ServEnt^.s_port);
    finally
      SynSockCS.Leave;
    end;
  end
  else
  begin
    Addr := nil;
    try
      FillChar(Hints, sizeOf(Hints), 0);
      Hints.ai_family := AF_UNSPEC;
      Hints.ai_socktype := SockType;
      Hints.ai_protocol := Sockprotocol;
      Hints.ai_flags := AI_PASSIVE;
      r := synsock.GetAddrInfo(nil, PChar(Port), @Hints, Addr);
      if (r = 0) and Assigned(Addr) then
      begin
        if Addr^.ai_family = AF_INET then
          result := synsock.htons(Addr^.ai_addr^.sin_port);
        if Addr^.ai_family = AF_INET6 then
          result := synsock.htons(PSockAddrIn6(Addr^.ai_addr)^.sin6_port);
      end;
    finally
      if Assigned(Addr) then
        synsock.FreeAddrInfo(Addr);
    end;
  end;
end;

FUNCTION ResolveIPToName(IP: string; Family, SockProtocol, SockType: integer): string;
VAR
  Hints: TAddrInfo;
  Addr: PAddrInfo;
  r: integer;
  host, serv: string;
  hostlen, servlen: integer;
  RemoteHost: PHostEnt;
  IPn: u_long;
begin
  result := IP;
  if not IsNewApi(Family) then
  begin
    IPn := synsock.inet_addr(PChar(IP));
    if IPn <> u_long(INADDR_NONE) then
    begin
      SynSockCS.Enter;
      try
        RemoteHost := GetHostByAddr(@IPn, sizeOf(IPn), AF_INET);
        if RemoteHost <> nil then
          result := RemoteHost^.h_name;
      finally
        SynSockCS.Leave;
      end;
    end;
  end
  else
  begin
    Addr := nil;
    try
      FillChar(Hints, sizeOf(Hints), 0);
      Hints.ai_family := AF_UNSPEC;
      Hints.ai_socktype := SockType;
      Hints.ai_protocol := SockProtocol;
      Hints.ai_flags := 0;
      r := synsock.GetAddrInfo(PChar(IP), nil, @Hints, Addr);
      if (r = 0) and Assigned(Addr)then
      begin
        hostlen := NI_MAXHOST;
        servlen := NI_MAXSERV;
        setLength(host, hostlen);
        setLength(serv, servlen);
        r := getnameinfo(Addr^.ai_addr, Addr^.ai_addrlen,
          PChar(host), hostlen, PChar(serv), servlen,
          NI_NUMERICSERV);
        if r = 0 then
          result := PChar(host);
      end;
    finally
      if Assigned(Addr) then
        synsock.FreeAddrInfo(Addr);
    end;
  end;
end;

{=============================================================================}

FUNCTION InitSocketInterface(stack: string): boolean;
begin
  result := false;
  SockEnhancedApi := false;
  if stack = '' then
    stack := DLLStackName;
  SynSockCS.Enter;
  try
    if SynSockCount = 0 then
    begin
      SockEnhancedApi := false;
      SockWship6Api := false;
      Libc.signal(Libc.SIGPIPE, TSignalHandler(Libc.SIG_IGN));
      LibHandle := LoadLibrary(PChar(stack));
      if LibHandle <> 0 then
      begin
        errno_loc := GetProcAddress(LibHandle, PChar('__errno_location'));
        CloseSocket := GetProcAddress(LibHandle, PChar('close'));
        IoctlSocket := GetProcAddress(LibHandle, PChar('ioctl'));
        WSAGetLastError := LSWSAGetLastError;
        WSAStartup := LSWSAStartup;
        WSACleanup := LSWSACleanup;
        ssAccept := GetProcAddress(LibHandle, PChar('accept'));
        ssBind := GetProcAddress(LibHandle, PChar('bind'));
        ssConnect := GetProcAddress(LibHandle, PChar('connect'));
        ssGetPeerName := GetProcAddress(LibHandle, PChar('getpeername'));
        ssGetSockName := GetProcAddress(LibHandle, PChar('getsockname'));
        GetSockOpt := GetProcAddress(LibHandle, PChar('getsockopt'));
        Htonl := GetProcAddress(LibHandle, PChar('htonl'));
        Htons := GetProcAddress(LibHandle, PChar('htons'));
        Inet_Addr := GetProcAddress(LibHandle, PChar('inet_addr'));
        Inet_Ntoa := GetProcAddress(LibHandle, PChar('inet_ntoa'));
        Listen := GetProcAddress(LibHandle, PChar('listen'));
        Ntohl := GetProcAddress(LibHandle, PChar('ntohl'));
        Ntohs := GetProcAddress(LibHandle, PChar('ntohs'));
        ssRecv := GetProcAddress(LibHandle, PChar('recv'));
        ssRecvFrom := GetProcAddress(LibHandle, PChar('recvfrom'));
        Select := GetProcAddress(LibHandle, PChar('select'));
        ssSend := GetProcAddress(LibHandle, PChar('send'));
        ssSendTo := GetProcAddress(LibHandle, PChar('sendto'));
        SetSockOpt := GetProcAddress(LibHandle, PChar('setsockopt'));
        ShutDown := GetProcAddress(LibHandle, PChar('shutdown'));
        Socket := GetProcAddress(LibHandle, PChar('socket'));
        GetHostByAddr := GetProcAddress(LibHandle, PChar('gethostbyaddr'));
        GetHostByName := GetProcAddress(LibHandle, PChar('gethostbyname'));
        GetProtoByName := GetProcAddress(LibHandle, PChar('getprotobyname'));
        GetProtoByNumber := GetProcAddress(LibHandle, PChar('getprotobynumber'));
        GetServByName := GetProcAddress(LibHandle, PChar('getservbyname'));
        GetServByPort := GetProcAddress(LibHandle, PChar('getservbyport'));
        ssGetHostName := GetProcAddress(LibHandle, PChar('gethostname'));

{$IFNDEF FORCEOLDAPI}
        GetAddrInfo := GetProcAddress(LibHandle, PChar('getaddrinfo'));
        FreeAddrInfo := GetProcAddress(LibHandle, PChar('freeaddrinfo'));
        GetNameInfo := GetProcAddress(LibHandle, PChar('getnameinfo'));
        SockEnhancedApi := Assigned(GetAddrInfo) and Assigned(FreeAddrInfo)
          and Assigned(GetNameInfo);
{$ENDIF}
        result := true;
      end;
    end
    else result := true;
    if result then
      inc(SynSockCount);
  finally
    SynSockCS.Leave;
  end;
end;

FUNCTION DestroySocketInterface: boolean;
begin
  SynSockCS.Enter;
  try
    dec(SynSockCount);
    if SynSockCount < 0 then
      SynSockCount := 0;
    if SynSockCount = 0 then
    begin
      if LibHandle <> 0 then
      begin
        FreeLibrary(libHandle);
        LibHandle := 0;
      end;
      if LibWship6Handle <> 0 then
      begin
        FreeLibrary(LibWship6Handle);
        LibWship6Handle := 0;
      end;
    end;
  finally
    SynSockCS.Leave;
  end;
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

