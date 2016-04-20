{==============================================================================|
| project : Ararat Synapse                                       | 001.000.002 |
|==============================================================================|
| content: Socket Independent Platform Layer - .NET definition include         |
|==============================================================================|
| Copyright (c)2004, Lukas Gebauer                                             |
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
| Portions created by Lukas Gebauer are Copyright (c)2004.                     |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@exclude}

{$IFDEF CIL}

INTERFACE

USES
  SyncObjs, sysutils, Classes,
  system.Net,
  system.Net.Sockets;

CONST
  DLLStackName = '';
  WinsockLevel = $0202;

FUNCTION InitSocketInterface(stack: string): boolean;
FUNCTION DestroySocketInterface: boolean;

TYPE
  u_char = char;
  u_short = word;
  u_int = integer;
  u_long = longint;
  pu_long = ^u_long;
  pu_short = ^u_short;
  PSockAddr = IPEndPoint;
  dword = integer;
  ULong = Cardinal;
  TMemory = array of byte;
  TLinger = LingerOption;
  TSocket = socket;
  TAddrFamily = AddressFamily;

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
//    lpVendorInfo: PChar;
  end;

CONST
  MSG_NOSIGNAL = 0;
  INVALID_SOCKET = nil;
  AF_UNSPEC = AddressFamily.Unspecified;
  AF_INET = AddressFamily.InterNetwork;
  AF_INET6 = AddressFamily.InterNetworkV6;
  SOCKET_ERROR = integer(-1);

  FIONREAD     = integer($4004667f);
  FIONBIO      = integer($8004667e);
  FIOASYNC     = integer($8004667d);

  SOMAXCONN       = integer($7fffffff);

  IPPROTO_IP = ProtocolType.IP;
  IPPROTO_ICMP = ProtocolType.Icmp;
  IPPROTO_IGMP = ProtocolType.Igmp;
  IPPROTO_TCP = ProtocolType.Tcp;
  IPPROTO_UDP = ProtocolType.Udp;
  IPPROTO_RAW = ProtocolType.raw;
  IPPROTO_IPV6 = ProtocolType.IPV6;
//
  IPPROTO_ICMPV6 = ProtocolType.Icmp; //??

  SOCK_STREAM     = SocketType.Stream;
  SOCK_DGRAM      = SocketType.Dgram;
  SOCK_RAW        = SocketType.raw;
  SOCK_RDM        = SocketType.Rdm;
  SOCK_SEQPACKET  = SocketType.Seqpacket;

  SOL_SOCKET = SocketOptionLevel.Socket;
  SOL_IP = SocketOptionLevel.Ip;


  IP_OPTIONS          = SocketOptionName.IPOptions;
  IP_HDRINCL          = SocketOptionName.HeaderIncluded;
  IP_TOS              = SocketOptionName.TypeOfService;           { set/get IP Type Of Service       }
  IP_TTL              = SocketOptionName.IpTimeToLive;           { set/get IP Time To Live          }
  IP_MULTICAST_IF     = SocketOptionName.MulticastInterface;           { set/get IP multicast interface   }
  IP_MULTICAST_TTL    = SocketOptionName.MulticastTimeToLive;           { set/get IP multicast timetolive  }
  IP_MULTICAST_LOOP   = SocketOptionName.MulticastLoopback;           { set/get IP multicast loopback    }
  IP_ADD_MEMBERSHIP   = SocketOptionName.AddMembership;           { add  an IP group membership      }
  IP_DROP_MEMBERSHIP  = SocketOptionName.DropMembership;           { drop an IP group membership      }
  IP_DONTFRAGMENT     = SocketOptionName.DontFragment;           { set/get IP Don't Fragment flag   }

  IPV6_UNICAST_HOPS      = 8;  // TTL
  IPV6_MULTICAST_IF      = 9;  // set/get IP multicast i/f
  IPV6_MULTICAST_HOPS    = 10; // set/get IP multicast ttl
  IPV6_MULTICAST_LOOP    = 11; // set/get IP multicast loopback
  IPV6_JOIN_GROUP        = 12; // add an IP group membership
  IPV6_LEAVE_GROUP       = 13; // drop an IP group membership

  SO_DEBUG        = SocketOptionName.debug;          { turn on debugging info recording }
  SO_ACCEPTCONN   = SocketOptionName.AcceptConnection;          { socket has had listen() }
  SO_REUSEADDR    = SocketOptionName.ReuseAddress;          { allow local address reuse }
  SO_KEEPALIVE    = SocketOptionName.KeepAlive;          { keep connections alive }
  SO_DONTROUTE    = SocketOptionName.DontRoute;          { just use interface addresses }
  SO_BROADCAST    = SocketOptionName.Broadcast;          { permit sending of broadcast msgs }
  SO_USELOOPBACK  = SocketOptionName.UseLoopback;          { bypass hardware when possible }
  SO_LINGER       = SocketOptionName.Linger;          { linger on close if data present }
  SO_OOBINLINE    = SocketOptionName.OutOfBandInline;          { leave received OOB data in line }
  SO_DONTLINGER   = SocketOptionName.DontLinger;
{ Additional options. }
  SO_SNDBUF       = SocketOptionName.SendBuffer;          { send buffer size }
  SO_RCVBUF       = SocketOptionName.ReceiveBuffer;          { receive buffer size }
  SO_SNDLOWAT     = SocketOptionName.SendLowWater;          { send low-water mark }
  SO_RCVLOWAT     = SocketOptionName.ReceiveLowWater;          { receive low-water mark }
  SO_SNDTIMEO     = SocketOptionName.SendTimeout;          { send timeout }
  SO_RCVTIMEO     = SocketOptionName.ReceiveTimeout;          { receive timeout }
  SO_ERROR        = SocketOptionName.Error;          { get error status and clear }
  SO_TYPE         = SocketOptionName.TYPE;          { get socket type }

{ WinSock 2 extension -- new options }
//  SO_GROUP_ID       = $2001; { ID of a socket group}
//  SO_GROUP_PRIORITY = $2002; { the relative priority within a group}
//  SO_MAX_MSG_SIZE   = $2003; { maximum message size }
//  SO_PROTOCOL_INFOA = $2004; { WSAPROTOCOL_INFOA structure }
//  SO_PROTOCOL_INFOW = $2005; { WSAPROTOCOL_INFOW structure }
//  SO_PROTOCOL_INFO  = SO_PROTOCOL_INFOA;
//  PVD_CONFIG        = $3001; {configuration info for service provider }
{ Option for opening sockets for synchronous access. }
//  SO_OPENTYPE     = $7008;
//  SO_SYNCHRONOUS_ALERT    = $10;
//  SO_SYNCHRONOUS_NONALERT = $20;
{ Other NT-specific options. }
//  SO_MAXDG        = $7009;
//  SO_MAXPATHDG    = $700A;
//  SO_UPDATE_ACCEPT_CONTEXT     = $700B;
//  SO_CONNECT_TIME = $700C;


  { All Windows Sockets error constants are biased by WSABASEERR from the "normal" }
  WSABASEERR              = 10000;

{ Windows Sockets definitions of regular Microsoft C error constants }

  WSAEINTR                = (WSABASEERR+4);
  WSAEBADF                = (WSABASEERR+9);
  WSAEACCES               = (WSABASEERR+13);
  WSAEFAULT               = (WSABASEERR+14);
  WSAEINVAL               = (WSABASEERR+22);
  WSAEMFILE               = (WSABASEERR+24);

{ Windows Sockets definitions of regular Berkeley error constants }

  WSAEWOULDBLOCK          = (WSABASEERR+35);
  WSAEINPROGRESS          = (WSABASEERR+36);
  WSAEALREADY             = (WSABASEERR+37);
  WSAENOTSOCK             = (WSABASEERR+38);
  WSAEDESTADDRREQ         = (WSABASEERR+39);
  WSAEMSGSIZE             = (WSABASEERR+40);
  WSAEPROTOTYPE           = (WSABASEERR+41);
  WSAENOPROTOOPT          = (WSABASEERR+42);
  WSAEPROTONOSUPPORT      = (WSABASEERR+43);
  WSAESOCKTNOSUPPORT      = (WSABASEERR+44);
  WSAEOPNOTSUPP           = (WSABASEERR+45);
  WSAEPFNOSUPPORT         = (WSABASEERR+46);
  WSAEAFNOSUPPORT         = (WSABASEERR+47);
  WSAEADDRINUSE           = (WSABASEERR+48);
  WSAEADDRNOTAVAIL        = (WSABASEERR+49);
  WSAENETDOWN             = (WSABASEERR+50);
  WSAENETUNREACH          = (WSABASEERR+51);
  WSAENETRESET            = (WSABASEERR+52);
  WSAECONNABORTED         = (WSABASEERR+53);
  WSAECONNRESET           = (WSABASEERR+54);
  WSAENOBUFS              = (WSABASEERR+55);
  WSAEISCONN              = (WSABASEERR+56);
  WSAENOTCONN             = (WSABASEERR+57);
  WSAESHUTDOWN            = (WSABASEERR+58);
  WSAETOOMANYREFS         = (WSABASEERR+59);
  WSAETIMEDOUT            = (WSABASEERR+60);
  WSAECONNREFUSED         = (WSABASEERR+61);
  WSAELOOP                = (WSABASEERR+62);
  WSAENAMETOOLONG         = (WSABASEERR+63);
  WSAEHOSTDOWN            = (WSABASEERR+64);
  WSAEHOSTUNREACH         = (WSABASEERR+65);
  WSAENOTEMPTY            = (WSABASEERR+66);
  WSAEPROCLIM             = (WSABASEERR+67);
  WSAEUSERS               = (WSABASEERR+68);
  WSAEDQUOT               = (WSABASEERR+69);
  WSAESTALE               = (WSABASEERR+70);
  WSAEREMOTE              = (WSABASEERR+71);

{ Extended Windows Sockets error constant definitions }

  WSASYSNOTREADY          = (WSABASEERR+91);
  WSAVERNOTSUPPORTED      = (WSABASEERR+92);
  WSANOTINITIALISED       = (WSABASEERR+93);
  WSAEDISCON              = (WSABASEERR+101);
  WSAENOMORE              = (WSABASEERR+102);
  WSAECANCELLED           = (WSABASEERR+103);
  WSAEEINVALIDPROCTABLE   = (WSABASEERR+104);
  WSAEINVALIDPROVIDER     = (WSABASEERR+105);
  WSAEPROVIDERFAILEDINIT  = (WSABASEERR+106);
  WSASYSCALLFAILURE       = (WSABASEERR+107);
  WSASERVICE_NOT_FOUND    = (WSABASEERR+108);
  WSATYPE_NOT_FOUND       = (WSABASEERR+109);
  WSA_E_NO_MORE           = (WSABASEERR+110);
  WSA_E_CANCELLED         = (WSABASEERR+111);
  WSAEREFUSED             = (WSABASEERR+112);

{ Error return codes from gethostbyname() and gethostbyaddr()
  (when using the resolver). Note that these errors are
  retrieved via WSAGetLastError() and must therefore follow
  the rules for avoiding clashes with error numbers from
  specific implementations or language run-time systems.
  for this reason the codes are based at WSABASEERR+1001.
  Note also that [WSA]NO_ADDRESS is defined only for
  compatibility purposes. }

{ Authoritative Answer: Host not found }
  WSAHOST_NOT_FOUND       = (WSABASEERR+1001);
  HOST_NOT_FOUND          = WSAHOST_NOT_FOUND;
{ Non-Authoritative: Host not found, or SERVERFAIL }
  WSATRY_AGAIN            = (WSABASEERR+1002);
  TRY_AGAIN               = WSATRY_AGAIN;
{ Non recoverable errors, FORMERR, REFUSED, NOTIMP }
  WSANO_RECOVERY          = (WSABASEERR+1003);
  NO_RECOVERY             = WSANO_RECOVERY;
{ Valid name, no data record of requested type }
  WSANO_DATA              = (WSABASEERR+1004);
  NO_DATA                 = WSANO_DATA;
{ no address, look for MX record }
  WSANO_ADDRESS           = WSANO_DATA;
  NO_ADDRESS              = WSANO_ADDRESS;

  EWOULDBLOCK        =  WSAEWOULDBLOCK;
  EINPROGRESS        =  WSAEINPROGRESS;
  EALREADY           =  WSAEALREADY;
  ENOTSOCK           =  WSAENOTSOCK;
  EDESTADDRREQ       =  WSAEDESTADDRREQ;
  EMSGSIZE           =  WSAEMSGSIZE;
  EPROTOTYPE         =  WSAEPROTOTYPE;
  ENOPROTOOPT        =  WSAENOPROTOOPT;
  EPROTONOSUPPORT    =  WSAEPROTONOSUPPORT;
  ESOCKTNOSUPPORT    =  WSAESOCKTNOSUPPORT;
  EOPNOTSUPP         =  WSAEOPNOTSUPP;
  EPFNOSUPPORT       =  WSAEPFNOSUPPORT;
  EAFNOSUPPORT       =  WSAEAFNOSUPPORT;
  EADDRINUSE         =  WSAEADDRINUSE;
  EADDRNOTAVAIL      =  WSAEADDRNOTAVAIL;
  ENETDOWN           =  WSAENETDOWN;
  ENETUNREACH        =  WSAENETUNREACH;
  ENETRESET          =  WSAENETRESET;
  ECONNABORTED       =  WSAECONNABORTED;
  ECONNRESET         =  WSAECONNRESET;
  ENOBUFS            =  WSAENOBUFS;
  EISCONN            =  WSAEISCONN;
  ENOTCONN           =  WSAENOTCONN;
  ESHUTDOWN          =  WSAESHUTDOWN;
  ETOOMANYREFS       =  WSAETOOMANYREFS;
  ETIMEDOUT          =  WSAETIMEDOUT;
  ECONNREFUSED       =  WSAECONNREFUSED;
  ELOOP              =  WSAELOOP;
  ENAMETOOLONG       =  WSAENAMETOOLONG;
  EHOSTDOWN          =  WSAEHOSTDOWN;
  EHOSTUNREACH       =  WSAEHOSTUNREACH;
  ENOTEMPTY          =  WSAENOTEMPTY;
  EPROCLIM           =  WSAEPROCLIM;
  EUSERS             =  WSAEUSERS;
  EDQUOT             =  WSAEDQUOT;
  ESTALE             =  WSAESTALE;
  EREMOTE            =  WSAEREMOTE;


TYPE
  TVarSin = IPEndpoint;

{  function IN6_IS_ADDR_UNSPECIFIED(const a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_LOOPBACK(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_LINKLOCAL(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_SITELOCAL(CONST a: PInAddr6): boolean;
  FUNCTION IN6_IS_ADDR_MULTICAST(CONST a: PInAddr6): boolean;
  FUNCTION IN6_ADDR_EQUAL(CONST a: PInAddr6; CONST b: PInAddr6):boolean;
  PROCEDURE SET_IN6_IF_ADDR_ANY (CONST a: PInAddr6);
  PROCEDURE SET_LOOPBACK_ADDR6 (CONST a: PInAddr6);
VAR
  in6addr_any, in6addr_loopback : TInAddr6;
}

{procedure FD_CLR(Socket: TSocket; var FDSet: TFDSet);
FUNCTION FD_ISSET(Socket: TSocket; VAR FDSet: TFDSet): boolean;
PROCEDURE FD_SET(Socket: TSocket; VAR FDSet: TFDSet);
PROCEDURE FD_ZERO(VAR FDSet: TFDSet);
}
{=============================================================================}

  FUNCTION WSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer;
  FUNCTION WSACleanup: integer;
  FUNCTION WSAGetLastError: integer;
  FUNCTION WSAGetLastErrorDesc: string;
  FUNCTION GetHostName: string;
  FUNCTION Shutdown(s: TSocket; how: integer): integer;
//  function SetSockOpt(s: TSocket; level, optname: Integer; optval: PChar;
//    optlen: Integer): Integer;
  FUNCTION SetSockOpt(s: TSocket; level, optname: integer; optval: TMemory;
    optlen: integer): integer;
  FUNCTION SetSockOptObj(s: TSocket; level, optname: integer; optval: TObject): integer;
  FUNCTION GetSockOpt(s: TSocket; level, optname: integer; optval: TMemory;
    VAR optlen: integer): integer;
//  function SendTo(s: TSocket; const Buf; len, flags: Integer; addrto: PSockAddr;
//    tolen: Integer): Integer;
///  function SendTo(s: TSocket; const Buf; len, flags: Integer; addrto: TVarSin): Integer;
///  function Send(s: TSocket; const Buf; len, flags: Integer): Integer;
///  function  Recv(s: TSocket; var Buf; len, flags: Integer): Integer;
//  function  RecvFrom(s: TSocket; var Buf; len, flags: Integer; from: PSockAddr;
//    var fromlen: Integer): Integer;
///  function  RecvFrom(s: TSocket; var Buf; len, flags: Integer; from: TVarSin): Integer;
FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
  FUNCTION  ntohs(netshort: u_short): u_short;
  FUNCTION  ntohl(netlong: u_long): u_long;
  FUNCTION  Listen(s: TSocket; backlog: integer): integer;
  FUNCTION  IoctlSocket(s: TSocket; cmd: dword; VAR arg: integer): integer;
  FUNCTION  htons(hostshort: u_short): u_short;
  FUNCTION  htonl(hostlong: u_long): u_long;
//  function  GetSockName(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
  FUNCTION  GetSockName(s: TSocket; VAR name: TVarSin): integer;
//  function  GetPeerName(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
  FUNCTION  GetPeerName(s: TSocket; VAR name: TVarSin): integer;
//  function  Connect(s: TSocket; name: PSockAddr; namelen: Integer): Integer;
  FUNCTION  Connect(s: TSocket; CONST name: TVarSin): integer;
  FUNCTION  CloseSocket(s: TSocket): integer;
//  function  Bind(s: TSocket; addr: PSockAddr; namelen: Integer): Integer;
  FUNCTION  Bind(s: TSocket; CONST addr: TVarSin): integer;
//  function  Accept(s: TSocket; addr: PSockAddr; var addrlen: Integer): TSocket;
  FUNCTION  accept(s: TSocket; VAR addr: TVarSin): TSocket;
  FUNCTION  Socket(af, struc, Protocol: integer): TSocket;
//  Select = function(nfds: Integer; readfds, writefds, exceptfds: PFDSet;
//    timeout: PTimeVal): Longint;
//    {$IFDEF LINUX}cdecl{$ELSE}stdcall{$ENDIF};

//  TWSAIoctl = function (s: TSocket; dwIoControlCode: DWORD; lpvInBuffer: Pointer;
//    cbInBuffer: DWORD; lpvOutBuffer: Pointer; cbOutBuffer: DWORD;
//    lpcbBytesReturned: PDWORD; lpOverlapped: Pointer;
//    lpCompletionRoutine: pointer): u_int;
//    stdcall;

  FUNCTION GetPortService(value: string): integer;

FUNCTION IsNewApi(Family: TAddrFamily): boolean;
FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family: TAddrFamily; SockProtocol, SockType: integer; PreferIP4: boolean): integer;
FUNCTION GetSinIP(sin: TVarSin): string;
FUNCTION GetSinPort(sin: TVarSin): integer;
PROCEDURE ResolveNameToIP(name: string; Family: TAddrFamily; SockProtocol, SockType: integer; CONST IPList: TStrings);
FUNCTION ResolveIPToName(IP: string; Family: TAddrFamily; SockProtocol, SockType: integer): string;
FUNCTION ResolvePort(Port: string; Family: TAddrFamily; SockProtocol, SockType: integer): word;

VAR
  SynSockCS: SyncObjs.TCriticalSection;
  SockEnhancedApi: boolean;
  SockWship6Api: boolean;

{==============================================================================}
IMPLEMENTATION

threadvar
  WSALastError: integer;
  WSALastErrorDesc: string;

VAR
  services: array [0..139, 0..1] of string =
  (
    ('echo', '7'),
    ('discard', '9'),
    ('sink', '9'),
    ('null', '9'),
    ('systat', '11'),
    ('users', '11'),
    ('daytime', '13'),
    ('qotd', '17'),
    ('quote', '17'),
    ('chargen', '19'),
    ('ttytst', '19'),
    ('source', '19'),
    ('ftp-data', '20'),
    ('ftp', '21'),
    ('telnet', '23'),
    ('smtp', '25'),
    ('mail', '25'),
    ('time', '37'),
    ('timeserver', '37'),
    ('rlp', '39'),
    ('nameserver', '42'),
    ('name', '42'),
    ('nickname', '43'),
    ('whois', '43'),
    ('domain', '53'),
    ('bootps', '67'),
    ('dhcps', '67'),
    ('bootpc', '68'),
    ('dhcpc', '68'),
    ('tftp', '69'),
    ('gopher', '70'),
    ('finger', '79'),
    ('http', '80'),
    ('www', '80'),
    ('www-http', '80'),
    ('kerberos', '88'),
    ('hostname', '101'),
    ('hostnames', '101'),
    ('iso-tsap', '102'),
    ('rtelnet', '107'),
    ('pop2', '109'),
    ('postoffice', '109'),
    ('pop3', '110'),
    ('sunrpc', '111'),
    ('rpcbind', '111'),
    ('portmap', '111'),
    ('auth', '113'),
    ('ident', '113'),
    ('tap', '113'),
    ('uucp-path', '117'),
    ('nntp', '119'),
    ('usenet', '119'),
    ('ntp', '123'),
    ('epmap', '135'),
    ('loc-srv', '135'),
    ('netbios-ns', '137'),
    ('nbname', '137'),
    ('netbios-dgm', '138'),
    ('nbdatagram', '138'),
    ('netbios-ssn', '139'),
    ('nbsession', '139'),
    ('imap', '143'),
    ('imap4', '143'),
    ('pcmail-srv', '158'),
    ('snmp', '161'),
    ('snmptrap', '162'),
    ('snmp-trap', '162'),
    ('print-srv', '170'),
    ('bgp', '179'),
    ('irc', '194'),
    ('ipx', '213'),
    ('ldap', '389'),
    ('https', '443'),
    ('mcom', '443'),
    ('microsoft-ds', '445'),
    ('kpasswd', '464'),
    ('isakmp', '500'),
    ('ike', '500'),
    ('exec', '512'),
    ('biff', '512'),
    ('comsat', '512'),
    ('login', '513'),
    ('who', '513'),
    ('whod', '513'),
    ('cmd', '514'),
    ('shell', '514'),
    ('syslog', '514'),
    ('printer', '515'),
    ('spooler', '515'),
    ('talk', '517'),
    ('ntalk', '517'),
    ('efs', '520'),
    ('router', '520'),
    ('route', '520'),
    ('routed', '520'),
    ('timed', '525'),
    ('timeserver', '525'),
    ('tempo', '526'),
    ('newdate', '526'),
    ('courier', '530'),
    ('rpc', '530'),
    ('conference', '531'),
    ('chat', '531'),
    ('netnews', '532'),
    ('readnews', '532'),
    ('netwall', '533'),
    ('uucp', '540'),
    ('uucpd', '540'),
    ('klogin', '543'),
    ('kshell', '544'),
    ('krcmd', '544'),
    ('new-rwho', '550'),
    ('new-who', '550'),
    ('remotefs', '556'),
    ('rfs', '556'),
    ('rfs_server', '556'),
    ('rmonitor', '560'),
    ('rmonitord', '560'),
    ('monitor', '561'),
    ('ldaps', '636'),
    ('sldap', '636'),
    ('doom', '666'),
    ('kerberos-adm', '749'),
    ('kerberos-iv', '750'),
    ('kpop', '1109'),
    ('phone', '1167'),
    ('ms-sql-s', '1433'),
    ('ms-sql-m', '1434'),
    ('wins', '1512'),
    ('ingreslock', '1524'),
    ('ingres', '1524'),
    ('l2tp', '1701'),
    ('pptp', '1723'),
    ('radius', '1812'),
    ('radacct', '1813'),
    ('nfsd', '2049'),
    ('nfs', '2049'),
    ('knetd', '2053'),
    ('gds_db', '3050'),
    ('man', '9535')
    );

{function IN6_IS_ADDR_UNSPECIFIED(const a: PInAddr6): boolean;
begin
  result := ((a^.s_un_dw.s_dw1 = 0) and (a^.s_un_dw.s_dw2 = 0) and
             (a^.s_un_dw.s_dw3 = 0) and (a^.s_un_dw.s_dw4 = 0));
end;

FUNCTION IN6_IS_ADDR_LOOPBACK(CONST a: PInAddr6): boolean;
begin
  result := ((a^.s_un_dw.s_dw1 = 0) and (a^.s_un_dw.s_dw2 = 0) and
             (a^.s_un_dw.s_dw3 = 0) and
             (a^.s_un_b.s_b13 = char(0)) and (a^.s_un_b.s_b14 = char(0)) and
             (a^.s_un_b.s_b15 = char(0)) and (a^.s_un_b.s_b16 = char(1)));
end;

FUNCTION IN6_IS_ADDR_LINKLOCAL(CONST a: PInAddr6): boolean;
begin
  result := ((a^.s_un_b.s_b1 = u_char($FE)) and (a^.s_un_b.s_b2 = u_char($80)));
end;

FUNCTION IN6_IS_ADDR_SITELOCAL(CONST a: PInAddr6): boolean;
begin
  result := ((a^.s_un_b.s_b1 = u_char($FE)) and (a^.s_un_b.s_b2 = u_char($C0)));
end;

FUNCTION IN6_IS_ADDR_MULTICAST(CONST a: PInAddr6): boolean;
begin
  result := (a^.s_un_b.s_b1 = char($ff));
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
  a^.s_un_b.s_b16 := char(1);
end;
}

{=============================================================================}

PROCEDURE NullErr;
begin
  WSALastError := 0;
  WSALastErrorDesc := '';
end;

PROCEDURE GetErrCode(E: system.Exception);
VAR
  SE: system.Net.Sockets.SocketException;
begin
  if E is system.Net.Sockets.SocketException then
  begin
    SE := E as system.Net.Sockets.SocketException;
    WSALastError := SE.ErrorCode;
    WSALastErrorDesc := SE.message;
  end
end;

FUNCTION WSAStartup(wVersionRequired: word; VAR WSData: TWSAData): integer;
begin
  NullErr;
  with WSData do
  begin
    wVersion := wVersionRequired;
    wHighVersion := $202;
    szDescription := 'Synsock - Synapse Platform Independent Socket Layer';
    szSystemStatus := 'Running on .NET';
    iMaxSockets := 32768;
    iMaxUdpDg := 8192;
  end;
  result := 0;
end;

FUNCTION WSACleanup: integer;
begin
  NullErr;
  result := 0;
end;

FUNCTION WSAGetLastError: integer;
begin
  result := WSALastError;
end;

FUNCTION WSAGetLastErrorDesc: string;
begin
  result := WSALastErrorDesc;
end;

FUNCTION GetHostName: string;
begin
  result := system.Net.DNS.GetHostName;
end;

FUNCTION Shutdown(s: TSocket; how: integer): integer;
begin
  result := 0;
  NullErr;
  try
    s.ShutDown(SocketShutdown(how));
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION SetSockOpt(s: TSocket; level, optname: integer; optval: Tmemory;
  optlen: integer): integer;
begin
  result := 0;
  NullErr;
  try
    s.SetSocketOption(SocketOptionLevel(level), SocketOptionName(optname), optval);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION SetSockOptObj(s: TSocket; level, optname: integer; optval: TObject): integer;
begin
  result := 0;
  NullErr;
  try
    s.SetSocketOption(SocketOptionLevel(level), SocketOptionName(optname), optval);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION GetSockOpt(s: TSocket; level, optname: integer; optval: Tmemory;
  VAR optlen: integer): integer;
begin
  result := 0;
  NullErr;
  try
    s.GetSocketOption(SocketOptionLevel(level), SocketOptionName(optname), optval);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION SendTo(s: TSocket; Buf: TMemory; len, flags: integer; addrto: TVarSin): integer;
//function SendTo(s: TSocket; const Buf; len, flags: Integer; addrto: TVarSin): Integer;
begin
  NullErr;
  try
    result := s.SendTo(Buf, len, SocketFlags(flags), addrto);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION Send(s: TSocket; Buf: TMemory; len, flags: integer): integer;
//function Send(s: TSocket; const Buf; len, flags: Integer): Integer;
begin
  NullErr;
  try
    result := s.Send(Buf, len, SocketFlags(flags));
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION Recv(s: TSocket; Buf: TMemory; len, flags: integer): integer;
//function  Recv(s: TSocket; var Buf; len, flags: Integer): Integer;
begin
  NullErr;
  try
    result := s.Receive(Buf, len, SocketFlags(flags));
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

//function  RecvFrom(s: TSocket; var Buf; len, flags: Integer; from: PSockAddr;
//  var fromlen: Integer): Integer;
FUNCTION RecvFrom(s: TSocket; Buf: TMemory; len, flags: integer; VAR from: TVarSin): integer;
//function  RecvFrom(s: TSocket; var Buf; len, flags: Integer; from: TVarSin): Integer;
VAR
  ep: EndPoint;
begin
  NullErr;
  try
    ep := from;
    result := s.ReceiveFrom(Buf, len, SocketFlags(flags), EndPoint(ep));
    from := ep as IPEndPoint;
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION  ntohs(netshort: u_short): u_short;
begin
  result := IPAddress.NetworkToHostOrder(NetShort);
end;

FUNCTION  ntohl(netlong: u_long): u_long;
begin
  result := IPAddress.NetworkToHostOrder(NetLong);
end;

FUNCTION  Listen(s: TSocket; backlog: integer): integer;
begin
  result := 0;
  NullErr;
  try
    s.Listen(backlog);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION  IoctlSocket(s: TSocket; cmd: dword; VAR arg: integer): integer;
VAR
  inv, outv: TMemory;
begin
  result := 0;
  NullErr;
  try
    if cmd = dword(FIONBIO) then
      s.Blocking := arg = 0
    else
    begin
      inv := BitConverter.GetBytes(arg);
      outv := BitConverter.GetBytes(integer(0));
      s.IOControl(cmd, inv, outv);
      arg := BitConverter.ToInt32(outv, 0);
    end;
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION  htons(hostshort: u_short): u_short;
begin
  result := IPAddress.HostToNetworkOrder(Hostshort);
end;

FUNCTION  htonl(hostlong: u_long): u_long;
begin
  result := IPAddress.HostToNetworkOrder(HostLong);
end;

//function  GetSockName(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
FUNCTION  GetSockName(s: TSocket; VAR name: TVarSin): integer;
begin
  result := 0;
  NullErr;
  try
    name := s.localEndPoint as IPEndpoint;
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

//function  GetPeerName(s: TSocket; name: PSockAddr; var namelen: Integer): Integer;
FUNCTION  GetPeerName(s: TSocket; VAR name: TVarSin): integer;
begin
  result := 0;
  NullErr;
  try
    name := s.RemoteEndPoint as IPEndpoint;
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

//function  Connect(s: TSocket; name: PSockAddr; namelen: Integer): Integer;
FUNCTION Connect(s: TSocket; CONST name: TVarSin): integer;
begin
  result := 0;
  NullErr;
  try
    s.Connect(name);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

FUNCTION CloseSocket(s: TSocket): integer;
begin
  result := 0;
  NullErr;
  try
    s.close;
  except
    on e: system.Net.Sockets.SocketException do
    begin
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

//function  Bind(s: TSocket; addr: PSockAddr; namelen: Integer): Integer;
FUNCTION Bind(s: TSocket; CONST addr: TVarSin): integer;
begin
  result := 0;
  NullErr;
  try
    s.Bind(addr);
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := integer(SOCKET_ERROR);
    end;
  end;
end;

//function  Accept(s: TSocket; addr: PSockAddr; var addrlen: Integer): TSocket;
FUNCTION accept(s: TSocket; VAR addr: TVarSin): TSocket;
begin
  NullErr;
  try
    result := s.accept();
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := nil;
    end;
  end;
end;

FUNCTION Socket(af, struc, Protocol: integer): TSocket;
begin
  NullErr;
  try
    result := TSocket.create(AddressFamily(af), SocketType(struc), ProtocolType(Protocol));
  except
    on e: system.Net.Sockets.SocketException do
    begin
      GetErrCode(e);
      result := nil;
    end;
  end;
end;

{=============================================================================}
FUNCTION GetPortService(value: string): integer;
VAR
  n: integer;
begin
  result := 0;
  value := lowercase(value);
  for n := 0 to high(Services) do
    if services[n, 0] = value then
    begin
      result := strToIntDef(services[n, 1], 0);
      break;
    end;
  if result = 0 then
    result := strToIntDef(value, 0);
end;

{=============================================================================}
FUNCTION IsNewApi(Family: TAddrFamily): boolean;
begin
  result := true;
end;

FUNCTION SetVarSin(VAR sin: TVarSin; IP, Port: string; Family: TAddrFamily; SockProtocol, SockType: integer; PreferIP4: boolean): integer;
VAR
  IPs: array of IPAddress;
  n: integer;
  ip4, ip6: string;
  sip: string;
begin
  sip := '';
  ip4 := '';
  ip6 := '';
  IPs := Dns.Resolve(IP).AddressList;
  for n :=low(IPs) to high(IPs) do begin
    if (ip4 = '') and (IPs[n].AddressFamily = AF_INET) then
      ip4 := IPs[n].toString;
    if (ip6 = '') and (IPs[n].AddressFamily = AF_INET6) then
      ip6 := IPs[n].toString;
    if (ip4 <> '') and (ip6 <> '') then
      break;
  end;
  case Family of
    AF_UNSPEC:
      begin
        if (ip4 <> '') and (ip6 <> '') then
        begin
          if PreferIP4 then
            sip := ip4
          else
            Sip := ip6;
          end
        else
        begin
          sip := ip4;
          if (ip6 <> '') then
            sip := ip6;
        end;
      end;
    AF_INET:
      sip := ip4;
    AF_INET6:
      sip := ip6;
  end;
  sin := TVarSin.create(IPAddress.Parse(sip), GetPortService(Port));
end;

FUNCTION GetSinIP(sin: TVarSin): string;
begin
  result := sin.Address.toString;
end;

FUNCTION GetSinPort(sin: TVarSin): integer;
begin
  result := sin.Port;
end;

PROCEDURE ResolveNameToIP(name: string; Family: TAddrFamily; SockProtocol, SockType: integer; CONST IPList: TStrings);
VAR
  IPs :array of IPAddress;
  n: integer;
begin
  IPList.clear;
  IPs := Dns.Resolve(name).AddressList;
  for n := low(IPs) to high(IPs) do
  begin
    if not(((Family = AF_INET6) and (IPs[n].AddressFamily = AF_INET))
      or ((Family = AF_INET) and (IPs[n].AddressFamily = AF_INET6))) then
    begin
      IPList.add(IPs[n].toString);
    end;
  end;
end;

FUNCTION ResolvePort(Port: string; Family: TAddrFamily; SockProtocol, SockType: integer): word;
VAR
  n: integer;
begin
  result := strToIntDef(port, 0);
  if result = 0 then
  begin
    port := lowercase(port);
    for n := 0 to high(Services) do
      if services[n, 0] = port then
      begin
        result := strToIntDef(services[n, 1], 0);
        break;
      end;
  end;
end;

FUNCTION ResolveIPToName(IP: string; Family: TAddrFamily; SockProtocol, SockType: integer): string;
begin
  result := Dns.GetHostByAddress(IP).HostName;
end;


{=============================================================================}
FUNCTION InitSocketInterface(stack: string): boolean;
begin
  result := true;
end;

FUNCTION DestroySocketInterface: boolean;
begin
  NullErr;
  result := true;
end;

INITIALIZATION
begin
  SynSockCS := SyncObjs.TCriticalSection.create;
//  SET_IN6_IF_ADDR_ANY (@in6addr_any);
//  SET_LOOPBACK_ADDR6  (@in6addr_loopback);
end;

FINALIZATION
begin
  NullErr;
  SynSockCS.free;
end;

{$ENDIF}
