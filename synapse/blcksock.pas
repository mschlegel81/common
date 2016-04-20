{==============================================================================|
| project : Ararat Synapse                                       | 009.008.005 |
|==============================================================================|
| content: Library base                                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)1999-2012.                |
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
 for good inspiration about SSL programming.
}

{$DEFINE ONCEWINSOCK}
{Note about define ONCEWINSOCK:
if you remove this compiler directive, then socket INTERFACE is loaded and
initialized on CONSTRUCTOR of TBlockSocket class for each socket separately.
Socket INTERFACE is used only if your need it.

if you leave this directive here, then socket INTERFACE is loaded and
initialized only once at start of your PROGRAM! it boost performace on high
count of created and destroyed sockets. it eliminate possible small resource
leak on windows systems too.
}

//{$DEFINE RAISEEXCEPT}
{When you enable this define, then is Raiseexcept property is on by default
}

{:@abstract(Synapse's library core)

core with IMPLEMENTATION basic socket Classes.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$IFDEF VER125}
  {$DEFINE BCB}
{$ENDIF}
{$IFDEF BCB}
  {$ObjExportAll On}
{$ENDIF}
{$Q-}
{$H+}
{$M+}
{$TYPEDADDRESS OFF}


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

UNIT blcksock;

INTERFACE

USES
  sysutils, Classes,
  synafpc,
  synsock, synautil, synacode, synaip
{$IFDEF CIL}
  ,system.Net
  ,system.Net.Sockets
  ,system.text
{$ENDIF}
  ;

CONST

  SynapseRelease = '38';

  cLocalhost = '127.0.0.1';
  cAnyHost = '0.0.0.0';
  cBroadcast = '255.255.255.255';
  c6Localhost = '::1';
  c6AnyHost = '::0';
  c6Broadcast = 'ffff::1';
  cAnyPort = '0';
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
  c64k = 65536;

TYPE

  {:@abstract(Exception clas used by Synapse)
   When you enable generating of exceptions, this Exception is raised by
   Synapse's units.}
  ESynapseError = class(Exception)
  private
    FErrorCode: integer;
    FErrorMessage: string;
  Published
    {:Code of error. Value depending on used operating system}
    PROPERTY ErrorCode: integer read FErrorCode write FErrorCode;
    {:Human readable description of error.}
    PROPERTY errorMessage: string read FErrorMessage write FErrorMessage;
  end;

  {:Types of OnStatus events}
  THookSocketReason = (
    {:Resolving is begin. Resolved IP and port is in parameter in format like:
     'localhost.somewhere.com:25'.}
    HR_ResolvingBegin,
    {:Resolving is done. Resolved IP and port is in parameter in format like:
     'localhost.somewhere.com:25'. it is always same as in HR_ResolvingBegin!}
    HR_ResolvingEnd,
    {:Socket created by CreateSocket method. It reporting Family of created
     socket too!}
    HR_SocketCreate,
    {:Socket closed by CloseSocket method.}
    HR_SocketClose,
    {:Socket binded to IP and Port. Binded IP and Port is in parameter in format
     like: 'localhost.somewhere.com:25'.}
    HR_Bind,
    {:Socket connected to IP and Port. Connected IP and Port is in parameter in
     format like: 'localhost.somewhere.com:25'.}
    HR_Connect,
    {:Called when CanRead method is used with @True result.}
    HR_CanRead,
    {:Called when CanWrite method is used with @True result.}
    HR_CanWrite,
    {:Socket is swithed to Listen mode. (TCP socket only)}
    HR_Listen,
    {:Socket Accepting client connection. (TCP socket only)}
    HR_Accept,
    {:report count of bytes readed from socket. Number is in parameter string.
     if you need is in integer, you must use strToInt FUNCTION!}
    HR_ReadCount,
    {:report count of bytes writed to socket. Number is in parameter string. If
     you need is in integer, you must use strToInt FUNCTION!}
    HR_WriteCount,
    {:If is limiting of bandwidth on, then this reason is called when sending or
     receiving is stopped for satisfy bandwidth limit. Parameter is count of
     waiting Milliseconds.}
    HR_Wait,
    {:report situation where communication error occured. When raiseexcept is
     @true, then Exception is called after this Hook reason.}
    HR_Error
    );

  {:Procedural type for OnStatus event. Sender is calling TBlockSocket object,
   Reason is one of set Status events and value is optional data.}
  THookSocketStatus = PROCEDURE(Sender: TObject; Reason: THookSocketReason;
    CONST value: string) of object;

  {:This procedural type is used for DataFilter hooks.}
  THookDataFilter = PROCEDURE(Sender: TObject; VAR value: ansistring) of object;

  {:This procedural type is used for hook OnCreateSocket. By this hook you can
   Insert your code after initialisation of socket. (you can set special socket
   options, etc.)}
  THookCreateSocket = PROCEDURE(Sender: TObject) of object;

  {:This procedural type is used for monitoring of communication.}
  THookMonitor = PROCEDURE(Sender: TObject; Writing: boolean;
    CONST buffer: TMemory; len: integer) of object;

  {:This procedural type is used for hook OnAfterConnect. By this hook you can
   Insert your code after TCP socket has been sucessfully connected.}
  THookAfterConnect = PROCEDURE(Sender: TObject) of object;

  {:This procedural type is used for hook OnVerifyCert. By this hook you can
   Insert your additional certificate verification code. Usefull to verify Server
   CN against URL. }

  THookVerifyCert = FUNCTION(Sender: TObject):boolean of object;

 {:This procedural type is used for hook OnHeartbeat. By this hook you can
   call your code repeately during long socket operations.
   You must enable heartbeats by @Link(HeartbeatRate) PROPERTY!}
  THookHeartbeat = PROCEDURE(Sender: TObject) of object;

  {:Specify family of socket.}
  TSocketFamily = (
    {:Default mode. Socket family is defined by target address for connection.
     it allows instant access to IPv4 and IPv6 nodes. When you need IPv6 address
     as destination, then is used IPv6 mode. othervise is used IPv4 mode.
     However this mode not working properly with preliminary IPv6 supports!}
    SF_Any,
    {:Turn this class to pure IPv4 mode. This mode is totally compatible with
     previous Synapse releases.}
    SF_IP4,
    {:Turn to only IPv6 mode.}
    SF_IP6
    );

  {:specify possible values of SOCKS modes.}
  TSocksType = (
    ST_Socks5,
    ST_Socks4
    );

  {:Specify requested SSL/TLS version for secure connection.}
  TSSLType = (
    LT_all,
    LT_SSLv2,
    LT_SSLv3,
    LT_TLSv1,
    LT_TLSv1_1,
    LT_SSHv2
    );

  {:Specify type of socket delayed option.}
  TSynaOptionType = (
    SOT_Linger,
    SOT_RecvBuff,
    SOT_SendBuff,
    SOT_NonBlock,
    SOT_RecvTimeout,
    SOT_SendTimeout,
    SOT_Reuse,
    SOT_TTL,
    SOT_Broadcast,
    SOT_MulticastTTL,
    SOT_MulticastLoop
    );

  {:@abstract(this object is used for remember delayed socket option set.)}
  TSynaOption = class(TObject)
  public
    Option: TSynaOptionType;
    Enabled: boolean;
    value: integer;
  end;

  TCustomSSL = class;
  TSSLClass = class of TCustomSSL;

  {:@abstract(Basic IP object.)
   This is parent class for other class with protocol implementations. do not
   use this class directly! use @link(TICMPBlockSocket), @link(TRAWBlockSocket),
   @link(TTCPBlockSocket) or @link(TUDPBlockSocket) instead.}
  TBlockSocket = class(TObject)
  private
    FOnStatus: THookSocketStatus;
    FOnReadFilter: THookDataFilter;
    FOnCreateSocket: THookCreateSocket;
    FOnMonitor: THookMonitor;
    FOnHeartbeat: THookHeartbeat;
    FLocalSin: TVarSin;
    FRemoteSin: TVarSin;
    FTag: integer;
    FBuffer: ansistring;
    FRaiseExcept: boolean;
    FNonBlockMode: boolean;
    FMaxLineLength: integer;
    FMaxSendBandwidth: integer;
    FNextSend: Longword;
    FMaxRecvBandwidth: integer;
    FNextRecv: Longword;
    FConvertLineEnd: boolean;
    FLastCR: boolean;
    FLastLF: boolean;
    FBinded: boolean;
    FFamily: TSocketFamily;
    FFamilySave: TSocketFamily;
    FIP6used: boolean;
    FPreferIP4: boolean;
    FDelayedOptions: TList;
    FInterPacketTimeout: boolean;
    {$IFNDEF CIL}
    FFDSet: TFDSet;
    {$ENDIF}
    FRecvCounter: integer;
    FSendCounter: integer;
    FSendMaxChunk: integer;
    FStopFlag: boolean;
    FNonblockSendTimeout: integer;
    FHeartbeatRate: integer;
    {$IFNDEF ONCEWINSOCK}
    FWsaDataOnce: TWSADATA;
    {$ENDIF}
    FUNCTION GetSizeRecvBuffer: integer;
    PROCEDURE SetSizeRecvBuffer(size: integer);
    FUNCTION GetSizeSendBuffer: integer;
    PROCEDURE SetSizeSendBuffer(size: integer);
    PROCEDURE SetNonBlockMode(value: boolean);
    PROCEDURE SetTTL(TTL: integer);
    FUNCTION GetTTL:integer;
    PROCEDURE SetFamily(value: TSocketFamily); virtual;
    PROCEDURE SetSocket(value: TSocket); virtual;
    FUNCTION GetWsaData: TWSAData;
    FUNCTION FamilyToAF(f: TSocketFamily): TAddrFamily;
  protected
    FSocket: TSocket;
    FLastError: integer;
    FLastErrorDesc: string;
    FOwner: TObject;
    PROCEDURE SetDelayedOption(CONST value: TSynaOption);
    PROCEDURE DelayedOption(CONST value: TSynaOption);
    PROCEDURE ProcessDelayedOptions;
    PROCEDURE InternalCreateSocket(sin: TVarSin);
    PROCEDURE SetSin(VAR sin: TVarSin; IP, Port: string);
    FUNCTION GetSinIP(sin: TVarSin): string;
    FUNCTION GetSinPort(sin: TVarSin): integer;
    PROCEDURE DoStatus(Reason: THookSocketReason; CONST value: string);
    PROCEDURE DoReadFilter(buffer: TMemory; VAR len: integer);
    PROCEDURE DoMonitor(Writing: boolean; CONST buffer: TMemory; len: integer);
    PROCEDURE DoCreateSocket;
    PROCEDURE DoHeartbeat;
    PROCEDURE LimitBandwidth(length: integer; MaxB: integer; VAR next: Longword);
    PROCEDURE SetBandwidth(value: integer);
    FUNCTION TestStopFlag: boolean;
    PROCEDURE InternalSendStream(CONST Stream: TStream; WithSize, Indy: boolean); virtual;
    FUNCTION InternalCanRead(Timeout: integer): boolean; virtual;
  public
    CONSTRUCTOR create;

    {:Create object and load all necessary socket library. What library is
     loaded is described by STUB parameter. if STUB is empty string, then is
     loaded default libraries.}
    CONSTRUCTOR CreateAlternate(Stub: string);
    DESTRUCTOR destroy; override;

    {:If @link(family) is not SF_Any, then create socket with type defined in
     @link(Family) PROPERTY. if family is SF_Any, then do nothing! (socket is
     created automaticly when you know what TYPE of socket you need to create.
     (i.e. inside @link(Connect) or @link(Bind) call.) When socket is created,
     then is aplyed all stored delayed socket options.}
    PROCEDURE CreateSocket;

    {:It create socket. Address resolving of Value tells what type of socket is
     created. if value is resolved as IPv4 IP, then is created IPv4 socket. if
     value is resolved as IPv6 address, then is created IPv6 socket.}
    PROCEDURE CreateSocketByName(CONST value: string);

    {:Destroy socket in use. This method is also automatically called from
     object DESTRUCTOR.}
    PROCEDURE CloseSocket; virtual;

    {:Abort any work on Socket and destroy them.}
    PROCEDURE AbortSocket; virtual;

    {:Connects socket to local IP address and PORT. IP address may be numeric or
     symbolic ('192.168.74.50', 'cosi.nekde.cz', 'ff08::1'). the same for PORT
     - it may be number or mnemonic port ('23', 'telnet').

     if port value is '0', system chooses itself and conects unused port in the
     range 1024 to 4096 (this depending by operating system!). structure
     LocalSin is filled after calling this method.

     Note: if you call this on non-created socket, then socket is created
     automaticly.

     Warning: when you call : Bind('0.0.0.0','0'); then is nothing done! in this
     case is used implicit system bind instead.}
    PROCEDURE Bind(IP, Port: string);

    {:Connects socket to remote IP address and PORT. The same rules as with
     @link(BIND) method are valid. the only Exception is that PORT with 0 value
     will not be connected!

     Structures LocalSin and RemoteSin will be filled with valid values.

     When you call this on non-created socket, then socket is created
     automaticly. TYPE of created socket is by @link(Family) PROPERTY. if is
     used SF_IP4, then is created socket for IPv4. if is used SF_IP6, then is
     created socket for IPv6. When you have family on SF_Any (default!), then
     TYPE of created socket is determined by address resolving of destination
     address. (not work properly on prilimitary winsock IPv6 support!)}
    PROCEDURE Connect(IP, Port: string); virtual;

    {:Sets socket to receive mode for new incoming connections. It is necessary
     to use @link(TBlockSocket.BIND) FUNCTION call before this method to select
     receiving port!}
    PROCEDURE Listen; virtual;

    {:Waits until new incoming connection comes. After it comes a new socket is
     automatically created (socket handler is returned by this FUNCTION as
     result).}
    FUNCTION accept: TSocket; virtual;

    {:Sends data of LENGTH from BUFFER address via connected socket. System
     automatically splits data to packets.}
    FUNCTION SendBuffer(buffer: Tmemory; length: integer): integer; virtual;

    {:One data BYTE is sent via connected socket.}
    PROCEDURE SendByte(data: byte); virtual;

    {:Send data string via connected socket. Any terminator is not added! If you
     need send true string with CR-LF termination, you must add CR-LF characters
     to sended string! Because any termination is not added automaticly, you can
     use this FUNCTION for sending any binary data in binary string.}
    PROCEDURE SendString(data: ansistring); virtual;

    {:Send integer as four bytes to socket.}
    PROCEDURE SendInteger(data: integer); virtual;

    {:Send data as one block to socket. Each block begin with 4 bytes with
     length of data in block. This 4 bytes is added automaticly by this
     FUNCTION.}
    PROCEDURE SendBlock(CONST data: ansistring); virtual;

    {:Send data from stream to socket.}
    PROCEDURE SendStreamRaw(CONST Stream: TStream); virtual;

    {:Send content of stream to socket. It using @link(SendBlock) method}
    PROCEDURE SendStream(CONST Stream: TStream); virtual;

    {:Send content of stream to socket. It using @link(SendBlock) method and
    this is compatible with streams in Indy library.}
    PROCEDURE SendStreamIndy(CONST Stream: TStream); virtual;

    {:Note: This is low-level receive function. You must be sure if data is
     waiting for read before call this FUNCTION for avoid deadlock!

     Waits until allocated buffer is filled by received data. Returns number of
     data received, which equals to length value under normal operation. if it
     is not equal the communication channel is possibly broken.

     on stream oriented sockets if is received 0 bytes, it mean 'socket is
     closed!"

     on datagram socket is readed first waiting datagram.}
    FUNCTION RecvBuffer(buffer: TMemory; length: integer): integer; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions!

     Method waits until data is received. if no data is received within TIMEOUT
     (in Milliseconds) period, @link(LastError) is set to WSAETIMEDOUT. methods
     serves for reading any size of data (i.e. one megabyte...). This method is
     preffered for reading from stream sockets (like TCP).}
    FUNCTION RecvBufferEx(buffer: Tmemory; len: integer;
      Timeout: integer): integer; virtual;

    {:Similar to @link(RecvBufferEx), but readed data is stored in binary
     string, not in memory buffer.}
    FUNCTION RecvBufferStr(len: integer; Timeout: integer): ansistring; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions.

     Waits until one data byte is received which is also returned as FUNCTION
     result. if no data is received within TIMEOUT (in Milliseconds)period,
     @link(LastError) is set to WSAETIMEDOUT and result have value 0.}
    FUNCTION RecvByte(Timeout: integer): byte; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions.

     Waits until one four bytes are received and return it as one Ineger value.
     if no data is received within TIMEOUT (in Milliseconds)period,
     @link(LastError) is set to WSAETIMEDOUT and result have value 0.}
    FUNCTION RecvInteger(Timeout: integer): integer; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions.

     Method waits until data string is received. This string is terminated by
     CR-LF characters. the resulting string is returned without this termination
     (CR-LF)! if @link(ConvertLineEnd) is used, then CR-LF sequence may not be
     exactly CR-LF. See @link(ConvertLineEnd) description. if no data is
     received within TIMEOUT (in Milliseconds) period, @link(LastError) is set
     to WSAETIMEDOUT. You may also specify maximum length of reading data by
     @link(maxLineLength) PROPERTY.}
    FUNCTION RecvString(Timeout: integer): ansistring; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions.

     Method waits until data string is received. This string is terminated by
     Terminator string. the resulting string is returned without this
     termination. if no data is received within TIMEOUT (in Milliseconds)
     period, @link(LastError) is set to WSAETIMEDOUT. You may also specify
     maximum length of reading data by @link(maxLineLength) PROPERTY.}
    FUNCTION RecvTerminated(Timeout: integer; CONST Terminator: ansistring): ansistring; virtual;

    {:Note: This is high-level receive function. It using internal
     @link(LineBuffer) and you can combine this FUNCTION freely with other
     high-level functions.

     Method reads all data waiting for read. if no data is received within
     TIMEOUT (in Milliseconds) period, @link(LastError) is set to WSAETIMEDOUT.
     methods serves for reading unknown size of data. Because before call this
     FUNCTION you don't know size of received data, returned data is stored in
     dynamic size binary string. This method is preffered for reading from
     stream sockets (like TCP). it is very goot for receiving datagrams too!
     (UDP protocol)}
    FUNCTION RecvPacket(Timeout: integer): ansistring; virtual;

    {:Read one block of data from socket. Each block begin with 4 bytes with
     length of data in block. This FUNCTION read first 4 bytes for get lenght,
     then it wait for reported count of bytes.}
    FUNCTION RecvBlock(Timeout: integer): ansistring; virtual;

    {:Read all data from socket to stream until socket is closed (or any error
     occured.)}
    PROCEDURE RecvStreamRaw(CONST Stream: TStream; Timeout: integer); virtual;
    {:Read requested count of bytes from socket to stream.}
    PROCEDURE RecvStreamSize(CONST Stream: TStream; Timeout: integer; size: integer);

    {:Receive data to stream. It using @link(RecvBlock) method.}
    PROCEDURE RecvStream(CONST Stream: TStream; Timeout: integer); virtual;

    {:Receive data to stream. This function is compatible with similar function
    in Indy library. it using @link(RecvBlock) method.}
    PROCEDURE RecvStreamIndy(CONST Stream: TStream; Timeout: integer); virtual;

    {:Same as @link(RecvBuffer), but readed data stays in system input buffer.
    Warning: this FUNCTION not respect data in @link(LineBuffer)! Is not
    recommended to use this FUNCTION!}
    FUNCTION PeekBuffer(buffer: TMemory; length: integer): integer; virtual;

    {:Same as @link(RecvByte), but readed data stays in input system buffer.
     Warning: this FUNCTION not respect data in @link(LineBuffer)! Is not
    recommended to use this FUNCTION!}
    FUNCTION PeekByte(Timeout: integer): byte; virtual;

    {:On stream sockets it returns number of received bytes waiting for picking.
     0 is returned when there is no such data. on datagram socket it returns
     length of the first waiting datagram. Returns 0 if no datagram is waiting.}
    FUNCTION WaitingData: integer; virtual;

    {:Same as @link(WaitingData), but if exists some of data in @link(Linebuffer),
     return their length instead.}
    FUNCTION WaitingDataEx: integer;

    {:Clear all waiting data for read from buffers.}
    PROCEDURE Purge;

    {:Sets linger. Enabled linger means that the system waits another LINGER
     (in Milliseconds) time for delivery of sent data. This FUNCTION is only for
     stream TYPE of socket! (TCP)}
    PROCEDURE SetLinger(Enable: boolean; Linger: integer);

    {:Actualize values in @link(LocalSin).}
    PROCEDURE GetSinLocal;

    {:Actualize values in @link(RemoteSin).}
    PROCEDURE GetSinRemote;

    {:Actualize values in @link(LocalSin) and @link(RemoteSin).}
    PROCEDURE GetSins;

    {:Reset @link(LastError) and @link(LastErrorDesc) to non-error state.}
    PROCEDURE ResetLastError;

    {:If you "manually" call Socket API functions, forward their return code as
     parameter to this FUNCTION, which evaluates it, eventually calls
     GetLastError and found error code returns and stores to @link(LastError).}
    FUNCTION SockCheck(SockResult: integer): integer; virtual;

    {:If @link(LastError) contains some error code and @link(RaiseExcept)
     PROPERTY is @true, raise adequate Exception.}
    PROCEDURE ExceptCheck;

    {:Returns local computer name as numerical or symbolic value. It try get
     fully qualified domain name. name is returned in the format acceptable by
     functions demanding IP as input parameter.}
    FUNCTION LocalName: string;

    {:Try resolve name to all possible IP address. i.e. If you pass as name
     result of @link(LocalName) method, you get all IP addresses used by local
     system.}
    PROCEDURE ResolveNameToIP(name: string; CONST IPList: TStrings);

    {:Try resolve name to primary IP address. i.e. If you pass as name result of
     @link(LocalName) method, you get primary IP addresses used by local system.}
    FUNCTION ResolveName(name: string): string;

    {:Try resolve IP to their primary domain name. If IP not have domain name,
     then is returned original IP.}
    FUNCTION ResolveIPToName(IP: string): string;

    {:Try resolve symbolic port name to port number. (i.e. 'Echo' to 8)}
    FUNCTION ResolvePort(Port: string): word;

    {:Set information about remote side socket. It is good for seting remote
     side for sending UDP packet, etc.}
    PROCEDURE SetRemoteSin(IP, Port: string);

    {:Picks IP socket address from @link(LocalSin).}
    FUNCTION GetLocalSinIP: string; virtual;

    {:Picks IP socket address from @link(RemoteSin).}
    FUNCTION GetRemoteSinIP: string; virtual;

    {:Picks socket PORT number from @link(LocalSin).}
    FUNCTION GetLocalSinPort: integer; virtual;

    {:Picks socket PORT number from @link(RemoteSin).}
    FUNCTION GetRemoteSinPort: integer; virtual;

    {:Return @TRUE, if you can read any data from socket or is incoming
     connection on TCP based socket. Status is tested for time Timeout (in
     Milliseconds). if value in Timeout is 0, status is only tested and
     continue. if value in Timeout is -1, run is breaked and waiting for read
     data maybe forever.

     This FUNCTION is need only on special cases, when you need use
     @link(RecvBuffer) FUNCTION directly! read functioms what have timeout as
     calling parameter, calling this FUNCTION internally.}
    FUNCTION CanRead(Timeout: integer): boolean; virtual;

    {:Same as @link(CanRead), but additionally return @TRUE if is some data in
     @link(LineBuffer).}
    FUNCTION CanReadEx(Timeout: integer): boolean; virtual;

    {:Return @TRUE, if you can to socket write any data (not full sending
     buffer). Status is tested for time Timeout (in Milliseconds). if value in
     Timeout is 0, status is only tested and continue. if value in Timeout is
     -1, run is breaked and waiting for write data maybe forever.

     This FUNCTION is need only on special cases!}
    FUNCTION CanWrite(Timeout: integer): boolean; virtual;

    {:Same as @link(SendBuffer), but send datagram to address from
     @link(RemoteSin). Usefull for sending reply to datagram received by
     FUNCTION @link(RecvBufferFrom).}
    FUNCTION SendBufferTo(buffer: TMemory; length: integer): integer; virtual;

    {:Note: This is low-lever receive function. You must be sure if data is
     waiting for read before call this FUNCTION for avoid deadlock!

     Receives first waiting datagram to allocated buffer. if there is no waiting
     one, then waits until one comes. Returns length of datagram stored in
     buffer. if length exceeds buffer datagram is truncated. After this
     @link(RemoteSin) structure contains information about Sender of UDP packet.}
    FUNCTION RecvBufferFrom(buffer: TMemory; length: integer): integer; virtual;
{$IFNDEF CIL}
    {:This function is for check for incoming data on set of sockets. Whitch
    sockets is Checked is decribed by SocketList TList with TBlockSocket
    objects. TList may have maximal number of objects defined by FD_SETSIZE
    constant. Return @true, if you can from some socket read any data or is
    incoming connection on TCP based socket. Status is tested for time Timeout
    (in Milliseconds). if value in Timeout is 0, status is only tested and
    continue. if value in Timeout is -1, run is breaked and waiting for read
    data maybe forever. if is returned @true, CanReadList TList is filled by all
    TBlockSocket objects what waiting for read.}
    FUNCTION GroupCanRead(CONST SocketList: TList; Timeout: integer;
      CONST CanReadList: TList): boolean;
{$ENDIF}
    {:By this method you may turn address reuse mode for local @link(bind). It
     is good specially for UDP protocol. Using this with TCP protocol is
     hazardous!}
    PROCEDURE EnableReuse(value: boolean);

    {:Try set timeout for all sending and receiving operations, if socket
     provider can do it. (it not supported by all socket providers!)}
    PROCEDURE SetTimeout(Timeout: integer);

    {:Try set timeout for all sending operations, if socket provider can do it.
     (it not supported by all socket providers!)}
    PROCEDURE SetSendTimeout(Timeout: integer);

    {:Try set timeout for all receiving operations, if socket provider can do
     it. (it not supported by all socket providers!)}
    PROCEDURE SetRecvTimeout(Timeout: integer);

    {:Return value of socket type.}
    FUNCTION GetSocketType: integer; virtual;

    {:Return value of protocol type for socket creation.}
    FUNCTION GetSocketProtocol: integer; virtual;

    {:WSA structure with information about socket provider. On non-windows
     platforms this structure is simulated!}
    PROPERTY WSAData: TWSADATA read GetWsaData;

    {:FDset structure prepared for usage with this socket.}
    PROPERTY FDset: TFDSet read FFDset;

    {:Structure describing local socket side.}
    PROPERTY LocalSin: TVarSin read FLocalSin write FLocalSin;

    {:Structure describing remote socket side.}
    PROPERTY RemoteSin: TVarSin read FRemoteSin write FRemoteSin;

    {:Socket handler. Suitable for "manual" calls to socket API or manual
     connection of socket to a previously created socket (i.e by accept method
     on TCP socket)}
    PROPERTY Socket: TSocket read FSocket write SetSocket;

    {:Last socket operation error code. Error codes are described in socket
     documentation. Human readable error description is stored in
     @link(LastErrorDesc) PROPERTY.}
    PROPERTY LastError: integer read FLastError;

    {:Human readable error description of @link(LastError) code.}
    PROPERTY LastErrorDesc: string read FLastErrorDesc;

    {:Buffer used by all high-level receiving functions. This buffer is used for
     optimized reading of data from socket. in normal cases you not need access
     to this buffer directly!}
    PROPERTY LineBuffer: ansistring read FBuffer write FBuffer;

    {:Size of Winsock receive buffer. If it is not supported by socket provider,
     it return as size one kilobyte.}
    PROPERTY SizeRecvBuffer: integer read GetSizeRecvBuffer write SetSizeRecvBuffer;

    {:Size of Winsock send buffer. If it is not supported by socket provider, it
     return as size one kilobyte.}
    PROPERTY SizeSendBuffer: integer read GetSizeSendBuffer write SetSizeSendBuffer;

    {:If @True, turn class to non-blocking mode. Not all functions are working
     properly in this mode, you must know exactly what you are doing! However
     when you have big experience with non-blocking programming, then you can
     optimise your PROGRAM by non-block mode!}
    PROPERTY NonBlockMode: boolean read FNonBlockMode write SetNonBlockMode;

    {:Set Time-to-live value. (if system supporting it!)}
    PROPERTY TTL: integer read GetTTL write SetTTL;

    {:If is @true, then class in in IPv6 mode.}
    PROPERTY IP6used: boolean read FIP6used;

    {:Return count of received bytes on this socket from begin of current
     connection.}
    PROPERTY RecvCounter: integer read FRecvCounter;

    {:Return count of sended bytes on this socket from begin of current
     connection.}
    PROPERTY SendCounter: integer read FSendCounter;
  Published
    {:Return descriptive string for given error code. This is class function.
     You may call it without created object!}
    class FUNCTION GetErrorDesc(ErrorCode: integer): string;

    {:Return descriptive string for @link(LastError).}
    FUNCTION GetErrorDescEx: string; virtual;

    {:this value is for free use.}
    PROPERTY Tag: integer read FTag write FTag;

    {:If @true, winsock errors raises exception. Otherwise is setted
    @link(LastError) value only and you must check it from your PROGRAM! default
    value is @false.}
    PROPERTY RaiseExcept: boolean read FRaiseExcept write FRaiseExcept;

    {:Define maximum length in bytes of @link(LineBuffer) for high-level
     receiving functions. if this functions try to read more data then this
     limit, error is returned! if value is 0 (default), no limitation is used.
     This is very good protection for stupid attacks to your Server by sending
     lot of data without proper terminator... until all your memory is allocated
     by LineBuffer!

     Note: This maximum length is Checked only in functions, what read unknown
     number of bytes! (like @link(RecvString) or @link(RecvTerminated))}
    PROPERTY maxLineLength: integer read FMaxLineLength write FMaxLineLength;

    {:Define maximal bandwidth for all sending operations in bytes per second.
     if value is 0 (default), bandwidth limitation is not used.}
    PROPERTY MaxSendBandwidth: integer read FMaxSendBandwidth write FMaxSendBandwidth;

    {:Define maximal bandwidth for all receiving operations in bytes per second.
     if value is 0 (default), bandwidth limitation is not used.}
    PROPERTY MaxRecvBandwidth: integer read FMaxRecvBandwidth write FMaxRecvBandwidth;

    {:Define maximal bandwidth for all sending and receiving operations in bytes
     per second. if value is 0 (default), bandwidth limitation is not used.}
    PROPERTY MaxBandwidth: integer write SetBandwidth;

    {:Do a conversion of non-standard line terminators to CRLF. (Off by default)
     if @true, then terminators like sigle CR, single LF or LFCR are converted
     to CRLF internally. This have effect only in @link(RecvString) method!}
    PROPERTY ConvertLineEnd: boolean read FConvertLineEnd write FConvertLineEnd;

    {:Specified Family of this socket. When you are using Windows preliminary
     support for IPv6, then I recommend to set this PROPERTY!}
    PROPERTY Family: TSocketFamily read FFamily write SetFamily;

    {:When resolving of domain name return both IPv4 and IPv6 addresses, then
     specify if is used IPv4 (dafault - @true) or IPv6.}
    PROPERTY PreferIP4: boolean read FPreferIP4 write FPreferIP4;

    {:By default (@true) is all timeouts used as timeout between two packets in
     reading operations. if you set this to @false, then Timeouts is for overall
     reading operation!}
    PROPERTY InterPacketTimeout: boolean read FInterPacketTimeout write FInterPacketTimeout;

    {:All sended datas was splitted by this value.}
    PROPERTY SendMaxChunk: integer read FSendMaxChunk write FSendMaxChunk;

    {:By setting this property to @true you can stop any communication. You can
     use this PROPERTY for soft abort of communication.}
    PROPERTY StopFlag: boolean read FStopFlag write FStopFlag;

    {:Timeout for data sending by non-blocking socket mode.}
    PROPERTY NonblockSendTimeout: integer read FNonblockSendTimeout write FNonblockSendTimeout;

    {:This event is called by various reasons. It is good for monitoring socket,
     create gauges for data transfers, etc.}
    PROPERTY OnStatus: THookSocketStatus read FOnStatus write FOnStatus;

    {:this event is good for some internal thinks about filtering readed datas.
     it is used by telnet Client by example.}
    PROPERTY OnReadFilter: THookDataFilter read FOnReadFilter write FOnReadFilter;

    {:This event is called after real socket creation for setting special socket
     options, because you not know when socket is created. (it is depended on
     Ipv4, IPv6 or automatic mode)}
    PROPERTY OnCreateSocket: THookCreateSocket read FOnCreateSocket write FOnCreateSocket;

    {:This event is good for monitoring content of readed or writed datas.}
    PROPERTY OnMonitor: THookMonitor read FOnMonitor write FOnMonitor;

    {:This event is good for calling your code during long socket operations.
      (example, for refresing UI if class in not called within the thread.)
      Rate of heartbeats can be modified by @link(HeartbeatRate) PROPERTY.}
    PROPERTY OnHeartbeat: THookHeartbeat read FOnHeartbeat write FOnHeartbeat;

    {:Specify typical rate of @link(OnHeartbeat) event and @link(StopFlag) testing.
      default value 0 disabling heartbeats! value is in Milliseconds.
      Real rate can be higher or smaller then this value, because it depending
      on real socket operations too!
      Note: Each heartbeat slowing socket processing.}
    PROPERTY HeartbeatRate: integer read FHeartbeatRate write FHeartbeatRate;
    {:What class own this socket? Used by protocol implementation classes.}
    PROPERTY Owner: TObject read FOwner write FOwner;
  end;

  {:@abstract(Support for SOCKS4 and SOCKS5 proxy)
   Layer with definition all necessary properties and functions for
   IMPLEMENTATION SOCKS proxy Client. do not use this class directly.}
  TSocksBlockSocket = class(TBlockSocket)
  protected
    FSocksIP: string;
    FSocksPort: string;
    FSocksTimeout: integer;
    FSocksUsername: string;
    FSocksPassword: string;
    FUsingSocks: boolean;
    FSocksResolver: boolean;
    FSocksLastError: integer;
    FSocksResponseIP: string;
    FSocksResponsePort: string;
    FSocksLocalIP: string;
    FSocksLocalPort: string;
    FSocksRemoteIP: string;
    FSocksRemotePort: string;
    FBypassFlag: boolean;
    FSocksType: TSocksType;
    FUNCTION SocksCode(IP, Port: string): ansistring;
    FUNCTION SocksDecode(value: ansistring): integer;
  public
    CONSTRUCTOR create;

    {:Open connection to SOCKS proxy and if @link(SocksUsername) is set, do
     authorisation to proxy. This is needed only in special cases! (it is called
     internally!)}
    FUNCTION SocksOpen: boolean;

    {:Send specified request to SOCKS proxy. This is needed only in special
     cases! (it is called internally!)}
    FUNCTION SocksRequest(cmd: byte; CONST IP, Port: string): boolean;

    {:Receive response to previosly sended request. This is needed only in
     special cases! (it is called internally!)}
    FUNCTION SocksResponse: boolean;

    {:Is @True when class is using SOCKS proxy.}
    PROPERTY UsingSocks: boolean read FUsingSocks;

    {:If SOCKS proxy failed, here is error code returned from SOCKS proxy.}
    PROPERTY SocksLastError: integer read FSocksLastError;
  Published
    {:Address of SOCKS server. If value is empty string, SOCKS support is
     disabled. Assingning any value to this PROPERTY enable SOCKS mode.
     Warning: You cannot combine this mode with HTTP-tunneling mode!}
    PROPERTY SocksIP: string read FSocksIP write FSocksIP;

    {:Port of SOCKS server. Default value is '1080'.}
    PROPERTY SocksPort: string read FSocksPort write FSocksPort;

    {:If you need authorisation on SOCKS server, set username here.}
    PROPERTY SocksUsername: string read FSocksUsername write FSocksUsername;

    {:If you need authorisation on SOCKS server, set password here.}
    PROPERTY SocksPassword: string read FSocksPassword write FSocksPassword;

    {:Specify timeout for communicatin with SOCKS server. Default is one minute.}
    PROPERTY SocksTimeout: integer read FSocksTimeout write FSocksTimeout;

    {:If @True, all symbolic names of target hosts is not translated to IP's
     locally, but resolving is by SOCKS proxy. default is @true.}
    PROPERTY SocksResolver: boolean read FSocksResolver write FSocksResolver;

    {:Specify SOCKS type. By default is used SOCKS5, but you can use SOCKS4 too.
     When you select SOCKS4, then if @link(SOCKSResolver) is Enabled, then is
     used SOCKS4a. Othervise is used pure SOCKS4.}
    PROPERTY SocksType: TSocksType read FSocksType write FSocksType;
  end;

  {:@abstract(Implementation of TCP socket.)
   Supported features: IPv4, IPv6, SSL/TLS or SSH (depending on used plugin),
   SOCKS5 proxy (outgoing connections and limited incomming), SOCKS4/4a proxy
   (outgoing connections and limited incomming), TCP through HTTP proxy tunnel.}
  TTCPBlockSocket = class(TSocksBlockSocket)
  protected
    FOnAfterConnect: THookAfterConnect;
    FSSL: TCustomSSL;
    FHTTPTunnelIP: string;
    FHTTPTunnelPort: string;
    FHTTPTunnel: boolean;
    FHTTPTunnelRemoteIP: string;
    FHTTPTunnelRemotePort: string;
    FHTTPTunnelUser: string;
    FHTTPTunnelPass: string;
    FHTTPTunnelTimeout: integer;
    PROCEDURE SocksDoConnect(IP, Port: string);
    PROCEDURE HTTPTunnelDoConnect(IP, Port: string);
    PROCEDURE DoAfterConnect;
  public
    {:Create TCP socket class with default plugin for SSL/TSL/SSH implementation
    (see @link(SSLImplementation))}
    CONSTRUCTOR create;

    {:Create TCP socket class with desired plugin for SSL/TSL/SSH implementation}
    CONSTRUCTOR CreateWithSSL(SSLPlugin: TSSLClass);
    DESTRUCTOR destroy; override;

    {:See @link(TBlockSocket.CloseSocket)}
    PROCEDURE CloseSocket; override;

    {:See @link(TBlockSocket.WaitingData)}
    FUNCTION WaitingData: integer; override;

    {:Sets socket to receive mode for new incoming connections. It is necessary
     to use @link(TBlockSocket.BIND) FUNCTION call before this method to select
     receiving port!

     if you use SOCKS, activate incoming TCP connection by this proxy. (by BIND
     method of SOCKS.)}
    PROCEDURE Listen; override;

    {:Waits until new incoming connection comes. After it comes a new socket is
     automatically created (socket handler is returned by this FUNCTION as
     result).

     if you use SOCKS, new socket is not created! in this case is used same
     socket as socket for listening! So, you can accept only one connection in
     SOCKS mode.}
    FUNCTION accept: TSocket; override;

    {:Connects socket to remote IP address and PORT. The same rules as with
     @link(TBlockSocket.BIND) method are valid. the only Exception is that PORT
     with 0 value will not be connected. After call to this method
     a communication channel between local and remote socket is created. Local
     socket is assigned automatically if not controlled by previous call to
     @link(TBlockSocket.BIND) method. Structures @link(TBlockSocket.LocalSin)
     and @link(TBlockSocket.RemoteSin) will be filled with valid values.

     if you use SOCKS, activate outgoing TCP connection by SOCKS proxy specified
     in @link(TSocksBlockSocket.SocksIP). (by CONNECT method of SOCKS.)

     if you use HTTP-tunnel mode, activate outgoing TCP connection by HTTP
     tunnel specified in @link(HTTPTunnelIP). (by CONNECT method of HTTP
     protocol.)

     Note: if you call this on non-created socket, then socket is created
     automaticly.}
    PROCEDURE Connect(IP, Port: string); override;

    {:If you need upgrade existing TCP connection to SSL/TLS (or SSH2, if plugin
     allows it) mode, then call this method. This method switch this class to
     SSL mode and do SSL/TSL handshake.}
    PROCEDURE SSLDoConnect;

    {:By this method you can downgrade existing SSL/TLS connection to normal TCP
     connection.}
    PROCEDURE SSLDoShutdown;

    {:If you need use this component as SSL/TLS TCP server, then after accepting
     of inbound connection you need start SSL/TLS session by this method. Before
     call this FUNCTION, you must have assigned all neeeded certificates and
     keys!}
    FUNCTION SSLAcceptConnection: boolean;

    {:See @link(TBlockSocket.GetLocalSinIP)}
    FUNCTION GetLocalSinIP: string; override;

    {:See @link(TBlockSocket.GetRemoteSinIP)}
    FUNCTION GetRemoteSinIP: string; override;

    {:See @link(TBlockSocket.GetLocalSinPort)}
    FUNCTION GetLocalSinPort: integer; override;

    {:See @link(TBlockSocket.GetRemoteSinPort)}
    FUNCTION GetRemoteSinPort: integer; override;

    {:See @link(TBlockSocket.SendBuffer)}
    FUNCTION SendBuffer(buffer: TMemory; length: integer): integer; override;

    {:See @link(TBlockSocket.RecvBuffer)}
    FUNCTION RecvBuffer(buffer: TMemory; len: integer): integer; override;

    {:Return value of socket type. For TCP return SOCK_STREAM.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For TCP return
     IPPROTO_TCP.}
    FUNCTION GetSocketProtocol: integer; override;

    {:Class implementing SSL/TLS support. It is allways some descendant
     of @link(TCustomSSL) class. When programmer not select some SSL plugin
     class, then is used @link(TSSLNone)}
    PROPERTY SSL: TCustomSSL read FSSL;

    {:@True if is used HTTP tunnel mode.}
    PROPERTY HTTPTunnel: boolean read FHTTPTunnel;
  Published
    {:Return descriptive string for @link(LastError). On case of error
     in SSL/TLS subsystem, it returns Right error description.}
    FUNCTION GetErrorDescEx: string; override;

    {:Specify IP address of HTTP proxy. Assingning non-empty value to this
     PROPERTY enable HTTP-tunnel mode. This mode is for tunnelling any outgoing
     TCP connection through HTTP proxy Server. (if policy on HTTP proxy Server
     allow this!) Warning: You cannot combine this mode with SOCK5 mode!}
    PROPERTY HTTPTunnelIP: string read FHTTPTunnelIP write FHTTPTunnelIP;

    {:Specify port of HTTP proxy for HTTP-tunneling.}
    PROPERTY HTTPTunnelPort: string read FHTTPTunnelPort write FHTTPTunnelPort;

    {:Specify authorisation username for access to HTTP proxy in HTTP-tunnel
     mode. if you not need authorisation, then let this PROPERTY empty.}
    PROPERTY HTTPTunnelUser: string read FHTTPTunnelUser write FHTTPTunnelUser;

    {:Specify authorisation password for access to HTTP proxy in HTTP-tunnel
     mode.}
    PROPERTY HTTPTunnelPass: string read FHTTPTunnelPass write FHTTPTunnelPass;

    {:Specify timeout for communication with HTTP proxy in HTTPtunnel mode.}
    PROPERTY HTTPTunnelTimeout: integer read FHTTPTunnelTimeout write FHTTPTunnelTimeout;

    {:This event is called after sucessful TCP socket connection.}
    PROPERTY OnAfterConnect: THookAfterConnect read FOnAfterConnect write FOnAfterConnect;
  end;

  {:@abstract(Datagram based communication)
   This class implementing datagram based communication instead default stream
   based communication style.}
  TDgramBlockSocket = class(TSocksBlockSocket)
  public
    {:Fill @link(TBlockSocket.RemoteSin) structure. This address is used for
     sending data.}
    PROCEDURE Connect(IP, Port: string); override;

    {:Silently redirected to @link(TBlockSocket.SendBufferTo).}
    FUNCTION SendBuffer(buffer: TMemory; length: integer): integer; override;

    {:Silently redirected to @link(TBlockSocket.RecvBufferFrom).}
    FUNCTION RecvBuffer(buffer: TMemory; length: integer): integer; override;
  end;

  {:@abstract(Implementation of UDP socket.)
   NOTE: in this class is all receiving redirected to RecvBufferFrom. You can
   use for reading any receive FUNCTION. Preffered is RecvPacket! Similary all
   sending is redirected to SendbufferTo. You can use for sending UDP packet any
   sending FUNCTION, like SendString.

   Supported features: IPv4, IPv6, unicasts, broadcasts, multicasts, SOCKS5
   proxy (only unicasts! outgoing and incomming.)}
  TUDPBlockSocket = class(TDgramBlockSocket)
  protected
    FSocksControlSock: TTCPBlockSocket;
    FUNCTION UdpAssociation: boolean;
    PROCEDURE SetMulticastTTL(TTL: integer);
    FUNCTION GetMulticastTTL:integer;
  public
    DESTRUCTOR destroy; override;

    {:Enable or disable sending of broadcasts. If seting OK, result is @true.
     This method is not supported in SOCKS5 mode! IPv6 does not support
     broadcasts! in this case you must use Multicasts instead.}
    PROCEDURE EnableBroadcast(value: boolean);

    {:See @link(TBlockSocket.SendBufferTo)}
    FUNCTION SendBufferTo(buffer: TMemory; length: integer): integer; override;

    {:See @link(TBlockSocket.RecvBufferFrom)}
    FUNCTION RecvBufferFrom(buffer: TMemory; length: integer): integer; override;
{$IFNDEF CIL}
    {:Add this socket to given multicast group. You cannot use Multicasts in
     SOCKS mode!}
    PROCEDURE AddMulticast(MCastIP:string);

    {:Remove this socket from given multicast group.}
    PROCEDURE DropMulticast(MCastIP:string);
{$ENDIF}
    {:All sended multicast datagrams is loopbacked to your interface too. (you
     can read your sended datas.) You can disable this feature by this FUNCTION.
     This FUNCTION not working on some windows systems!}
    PROCEDURE EnableMulticastLoop(value: boolean);

    {:Return value of socket type. For UDP return SOCK_DGRAM.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For UDP return
     IPPROTO_UDP.}
    FUNCTION GetSocketProtocol: integer; override;

    {:Set Time-to-live value for multicasts packets. It define number of routers
     for transfer of datas. if you set this to 1 (dafault system value), then
     multicasts packet goes only to you local network. if you need transport
     multicast packet to worldwide, then increase this value, but be carefull,
     lot of routers on internet does not transport multicasts packets!}
    PROPERTY MulticastTTL: integer read GetMulticastTTL write SetMulticastTTL;
  end;

  {:@abstract(Implementation of RAW ICMP socket.)
   for this object you must have rights for creating raw sockets!}
  TICMPBlockSocket = class(TDgramBlockSocket)
  public
    {:Return value of socket type. For RAW and ICMP return SOCK_RAW.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For ICMP returns
     IPPROTO_ICMP or IPPROTO_ICMPV6}
    FUNCTION GetSocketProtocol: integer; override;
  end;

  {:@abstract(Implementation of RAW socket.)
   for this object you must have rights for creating raw sockets!}
  TRAWBlockSocket = class(TBlockSocket)
  public
    {:Return value of socket type. For RAW and ICMP return SOCK_RAW.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For RAW returns
     IPPROTO_RAW.}
    FUNCTION GetSocketProtocol: integer; override;
  end;

  {:@abstract(Implementation of PGM-message socket.)
   not all systems supports this protocol!}
  TPGMMessageBlockSocket = class(TBlockSocket)
  public
    {:Return value of socket type. For PGM-message return SOCK_RDM.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For PGM-message returns
     IPPROTO_RM.}
    FUNCTION GetSocketProtocol: integer; override;
  end;

  {:@abstract(Implementation of PGM-stream socket.)
   not all systems supports this protocol!}
  TPGMStreamBlockSocket = class(TBlockSocket)
  public
    {:Return value of socket type. For PGM-stream return SOCK_STREAM.}
    FUNCTION GetSocketType: integer; override;

    {:Return value of protocol type for socket creation. For PGM-stream returns
     IPPROTO_RM.}
    FUNCTION GetSocketProtocol: integer; override;
  end;

  {:@abstract(Parent class for all SSL plugins.)
   This is abstract class defining INTERFACE for other SSL plugins.

   instance of this class will be created for each @link(TTCPBlockSocket).

   Warning: not all methods and propertis can work in all existing SSL plugins!
   Please, read documentation of used SSL plugin.}
  TCustomSSL = class(TObject)
  private
  protected
    FOnVerifyCert: THookVerifyCert;
    FSocket: TTCPBlockSocket;
    FSSLEnabled: boolean;
    FLastError: integer;
    FLastErrorDesc: string;
    FSSLType: TSSLType;
    FKeyPassword: string;
    FCiphers: string;
    FCertificateFile: string;
    FPrivateKeyFile: string;
    FCertificate: ansistring;
    FPrivateKey: ansistring;
    FPFX: ansistring;
    FPFXfile: string;
    FCertCA: ansistring;
    FCertCAFile: string;
    FTrustCertificate: ansistring;
    FTrustCertificateFile: string;
    FVerifyCert: boolean;
    FUsername: string;
    FPassword: string;
    FSSHChannelType: string;
    FSSHChannelArg1: string;
    FSSHChannelArg2: string;
    FCertComplianceLevel: integer;
    FSNIHost: string;
    PROCEDURE ReturnError;
    PROCEDURE SetCertCAFile(CONST value: string); virtual;
    FUNCTION DoVerifyCert:boolean;
    FUNCTION CreateSelfSignedCert(Host: string): boolean; virtual;
  public
    {: Create plugin class. it is called internally from @link(TTCPBlockSocket)}
    CONSTRUCTOR create(CONST value: TTCPBlockSocket); virtual;

    {: Assign settings (certificates and configuration) from another SSL plugin
     class.}
    PROCEDURE assign(CONST value: TCustomSSL); virtual;

    {: return description of used plugin. It usually return name and version
     of used SSL library.}
    FUNCTION LibVersion: string; virtual;

    {: return name of used plugin.}
    FUNCTION LibName: string; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for start SSL connection.}
    FUNCTION Connect: boolean; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for acept new SSL connection.}
    FUNCTION accept: boolean; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for hard shutdown of SSL connection. (for example,
     before socket is closed)}
    FUNCTION Shutdown: boolean; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for soft shutdown of SSL connection. (for example,
     when you need to continue with unprotected connection.)}
    FUNCTION BiShutdown: boolean; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for sending some datas by SSL connection.}
    FUNCTION SendBuffer(buffer: TMemory; len: integer): integer; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for receiving some datas by SSL connection.}
    FUNCTION RecvBuffer(buffer: TMemory; len: integer): integer; virtual;

    {: Do not call this directly. It is used internally by @link(TTCPBlockSocket)!

     Here is needed code for getting count of datas what waiting for read.
     if SSL plugin not allows this, then it should return 0.}
    FUNCTION WaitingData: integer; virtual;

    {:Return string with identificator of SSL/TLS version of existing
     connection.}
    FUNCTION GetSSLVersion: string; virtual;

    {:Return subject of remote SSL peer.}
    FUNCTION GetPeerSubject: string; virtual;

    {:Return Serial number if remote X509 certificate.}
    FUNCTION GetPeerSerialNo: integer; virtual;

    {:Return issuer certificate of remote SSL peer.}
    FUNCTION GetPeerIssuer: string; virtual;

    {:Return peer name from remote side certificate. This is good for verify,
     if certificate is generated for remote side IP name.}
    FUNCTION GetPeerName: string; virtual;

    {:Returns has of peer name from remote side certificate. This is good
     for fast remote side authentication.}
    FUNCTION GetPeerNameHash: Cardinal; virtual;

    {:Return fingerprint of remote SSL peer.}
    FUNCTION GetPeerFingerprint: string; virtual;

    {:Return all detailed information about certificate from remote side of
     SSL/TLS connection. result string can be multilined! Each plugin can return
     this informations in different format!}
    FUNCTION GetCertInfo: string; virtual;

    {:Return currently used Cipher.}
    FUNCTION GetCipherName: string; virtual;

    {:Return currently used number of bits in current Cipher algorythm.}
    FUNCTION GetCipherBits: integer; virtual;

    {:Return number of bits in current Cipher algorythm.}
    FUNCTION GetCipherAlgBits: integer; virtual;

    {:Return result value of verify remote side certificate. Look to OpenSSL
     documentation for possible values. for example 0 is successfuly verified
     certificate, or 18 is self-signed certificate.}
    FUNCTION GetVerifyCert: integer; virtual;

    {: Resurn @true if SSL mode is enabled on existing cvonnection.}
    PROPERTY SSLEnabled: boolean read FSSLEnabled;

    {:Return error code of last SSL operation. 0 is OK.}
    PROPERTY LastError: integer read FLastError;

    {:Return error description of last SSL operation.}
    PROPERTY LastErrorDesc: string read FLastErrorDesc;
  Published
    {:Here you can specify requested SSL/TLS mode. Default is autodetection, but
     on some servers autodetection not working properly. in this case you must
     specify requested SSL/TLS mode by your hand!}
    PROPERTY SSLType: TSSLType read FSSLType write FSSLType;

    {:Password for decrypting of encoded certificate or key.}
    PROPERTY KeyPassword: string read FKeyPassword write FKeyPassword;

    {:Username for possible credentials.}
    PROPERTY Username: string read FUsername write FUsername;

    {:password for possible credentials.}
    PROPERTY Password: string read FPassword write FPassword;

    {:By this property you can modify default set of SSL/TLS ciphers.}
    PROPERTY Ciphers: string read FCiphers write FCiphers;

    {:Used for loading certificate from disk file. See to plugin documentation
     if this method is supported and how!}
    PROPERTY CertificateFile: string read FCertificateFile write FCertificateFile;

    {:Used for loading private key from disk file. See to plugin documentation
     if this method is supported and how!}
    PROPERTY PrivateKeyFile: string read FPrivateKeyFile write FPrivateKeyFile;

    {:Used for loading certificate from binary string. See to plugin documentation
     if this method is supported and how!}
    PROPERTY Certificate: ansistring read FCertificate write FCertificate;

    {:Used for loading private key from binary string. See to plugin documentation
     if this method is supported and how!}
    PROPERTY PrivateKey: ansistring read FPrivateKey write FPrivateKey;

    {:Used for loading PFX from binary string. See to plugin documentation
     if this method is supported and how!}
    PROPERTY PFX: ansistring read FPFX write FPFX;

    {:Used for loading PFX from disk file. See to plugin documentation
     if this method is supported and how!}
    PROPERTY PFXfile: string read FPFXfile write FPFXfile;

    {:Used for loading trusted certificates from disk file. See to plugin documentation
     if this method is supported and how!}
    PROPERTY TrustCertificateFile: string read FTrustCertificateFile write FTrustCertificateFile;

    {:Used for loading trusted certificates from binary string. See to plugin documentation
     if this method is supported and how!}
    PROPERTY TrustCertificate: ansistring read FTrustCertificate write FTrustCertificate;

    {:Used for loading CA certificates from binary string. See to plugin documentation
     if this method is supported and how!}
    PROPERTY CertCA: ansistring read FCertCA write FCertCA;

    {:Used for loading CA certificates from disk file. See to plugin documentation
     if this method is supported and how!}
    PROPERTY CertCAFile: string read FCertCAFile write SetCertCAFile;

    {:If @true, then is verified client certificate. (it is good for writing
     SSL/TLS servers.) When you are not Server, but you are Client, then if this
     PROPERTY is @true, verify servers certificate.}
    PROPERTY VerifyCert: boolean read FVerifyCert write FVerifyCert;

    {:channel type for possible SSH connections}
    PROPERTY SSHChannelType: string read FSSHChannelType write FSSHChannelType;

    {:First argument of channel type for possible SSH connections}
    PROPERTY SSHChannelArg1: string read FSSHChannelArg1 write FSSHChannelArg1;

    {:Second argument of channel type for possible SSH connections}
    PROPERTY SSHChannelArg2: string read FSSHChannelArg2 write FSSHChannelArg2;

    {: Level of standards compliance level
      (CryptLib: values in cryptlib.pas, -1: use default value )  }
    PROPERTY CertComplianceLevel:integer read FCertComplianceLevel write FCertComplianceLevel;

    {:This event is called when verifying the server certificate immediatally after
     a successfull verification in the ssl library.}
    PROPERTY OnVerifyCert: THookVerifyCert read FOnVerifyCert write FOnVerifyCert;

    {: Server Name Identification. Host name to send to server. If empty the host name
       found in URL will be used, which should be the normal use (http Header Host = SNI Host).
       the value is cleared after the connection is established.
      (SNI support requires OpenSSL 0.9.8k or later. Cryptlib not supported, yet )  }
    PROPERTY SNIHost:string read FSNIHost write FSNIHost;
  end;

  {:@abstract(Default SSL plugin with no SSL support.)
   dummy SSL plugin IMPLEMENTATION for applications without SSL/TLS support.}
  TSSLNone = class (TCustomSSL)
  public
    {:See @inherited}
    FUNCTION LibVersion: string; override;
    {:See @inherited}
    FUNCTION LibName: string; override;
  end;

  {:@abstract(Record with definition of IP packet header.)
   for reading data from ICMP or raw sockets.}
  TIPHeader = record
    VerLen: byte;
    TOS: byte;
    TotalLen: word;
    Identifer: word;
    FragOffsets: word;
    TTL: byte;
    Protocol: byte;
    CheckSum: word;
    SourceIp: Longword;
    DestIp: Longword;
    options: Longword;
  end;

  {:@abstract(Parent class of application protocol implementations.)
   by this class is defined common properties.}
  TSynaClient = class(TObject)
  protected
    FTargetHost: string;
    FTargetPort: string;
    FIPInterface: string;
    FTimeout: integer;
    FUserName: string;
    FPassword: string;
  public
    CONSTRUCTOR create;
  Published
    {:Specify terget server IP (or symbolic name). Default is 'localhost'.}
    PROPERTY TargetHost: string read FTargetHost write FTargetHost;

    {:Specify terget server port (or symbolic name).}
    PROPERTY TargetPort: string read FTargetPort write FTargetPort;

    {:Defined local socket address. (outgoing IP address). By default is used
     '0.0.0.0' as wildcard for default IP.}
    PROPERTY IPInterface: string read FIPInterface write FIPInterface;

    {:Specify default timeout for socket operations.}
    PROPERTY Timeout: integer read FTimeout write FTimeout;

    {:If protocol need user authorization, then fill here username.}
    PROPERTY UserName: string read FUserName write FUserName;

    {:If protocol need user authorization, then fill here password.}
    PROPERTY Password: string read FPassword write FPassword;
  end;

VAR
  {:Selected SSL plugin. Default is @link(TSSLNone).

   do not change this value directly!!!

   Just add your plugin UNIT to your project USES instead. Each plugin UNIT have
   INITIALIZATION code what modify this variable.}
  SSLImplementation: TSSLClass = TSSLNone;

IMPLEMENTATION

{$IFDEF ONCEWINSOCK}
VAR
  WsaDataOnce: TWSADATA;
  e: ESynapseError;
{$ENDIF}


CONSTRUCTOR TBlockSocket.create;
begin
  CreateAlternate('');
end;

CONSTRUCTOR TBlockSocket.CreateAlternate(Stub: string);
{$IFNDEF ONCEWINSOCK}
VAR
  e: ESynapseError;
{$ENDIF}
begin
  inherited create;
  FDelayedOptions := TList.create;
  FRaiseExcept := false;
{$IFDEF RAISEEXCEPT}
  FRaiseExcept := true;
{$ENDIF}
  FSocket := INVALID_SOCKET;
  FBuffer := '';
  FLastCR := false;
  FLastLF := false;
  FBinded := false;
  FNonBlockMode := false;
  FMaxLineLength := 0;
  FMaxSendBandwidth := 0;
  FNextSend := 0;
  FMaxRecvBandwidth := 0;
  FNextRecv := 0;
  FConvertLineEnd := false;
  FFamily := SF_Any;
  FFamilySave := SF_Any;
  FIP6used := false;
  FPreferIP4 := true;
  FInterPacketTimeout := true;
  FRecvCounter := 0;
  FSendCounter := 0;
  FSendMaxChunk := c64k;
  FStopFlag := false;
  FNonblockSendTimeout := 15000;
  FHeartbeatRate := 0;
  FOwner := nil;
{$IFNDEF ONCEWINSOCK}
  if Stub = '' then
    Stub := DLLStackName;
  if not InitSocketInterface(Stub) then
  begin
    e := ESynapseError.create('Error loading Socket interface (' + Stub + ')!');
    e.ErrorCode := 0;
    e.errorMessage := 'Error loading Socket interface (' + Stub + ')!';
    raise e;
  end;
  SockCheck(synsock.WSAStartup(WinsockLevel, FWsaDataOnce));
  ExceptCheck;
{$ENDIF}
end;

DESTRUCTOR TBlockSocket.destroy;
VAR
  n: integer;
  p: TSynaOption;
begin
  CloseSocket;
{$IFNDEF ONCEWINSOCK}
  synsock.WSACleanup;
  DestroySocketInterface;
{$ENDIF}
  for n := FDelayedOptions.count - 1 downto 0 do
    begin
      p := TSynaOption(FDelayedOptions[n]);
      p.free;
    end;
  FDelayedOptions.free;
  inherited destroy;
end;

FUNCTION TBlockSocket.FamilyToAF(f: TSocketFamily): TAddrFamily;
begin
  case f of
    SF_ip4:
      result := AF_INET;
    SF_ip6:
      result := AF_INET6;
  else
    result := AF_UNSPEC;
  end;
end;

PROCEDURE TBlockSocket.SetDelayedOption(CONST value: TSynaOption);
VAR
  LI: TLinger;
  x: integer;
  Buf: TMemory;
{$IFNDEF MSWINDOWS}
  timeval: TTimeval;
{$ENDIF}
begin
  case value.Option of
    SOT_Linger:
      begin
        {$IFDEF CIL}
        LI := TLinger.create(value.Enabled, value.value div 1000);
        synsock.SetSockOptObj(FSocket, integer(SOL_SOCKET), integer(SO_LINGER), LI);
        {$ELSE}
        LI.l_onoff := ord(value.Enabled);
        LI.l_linger := value.value div 1000;
        Buf := @LI;
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_LINGER), Buf, sizeOf(LI));
        {$ENDIF}
      end;
    SOT_RecvBuff:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        {$ELSE}
        Buf := @value.value;
        {$ENDIF}
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_RCVBUF),
          Buf, sizeOf(value.value));
      end;
    SOT_SendBuff:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        {$ELSE}
        Buf := @value.value;
        {$ENDIF}
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_SNDBUF),
          Buf, sizeOf(value.value));
      end;
    SOT_NonBlock:
      begin
        FNonBlockMode := value.Enabled;
        x := ord(FNonBlockMode);
        synsock.IoctlSocket(FSocket, FIONBIO, x);
      end;
    SOT_RecvTimeout:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_RCVTIMEO),
          Buf, sizeOf(value.value));
        {$ELSE}
          {$IFDEF MSWINDOWS}
        Buf := @value.value;
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_RCVTIMEO),
          Buf, sizeOf(value.value));
          {$ELSE}
        timeval.tv_sec:=value.value div 1000;
        timeval.tv_usec:=(value.value mod 1000) * 1000;
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_RCVTIMEO),
          @timeval, sizeOf(timeval));
          {$ENDIF}
        {$ENDIF}
      end;
    SOT_SendTimeout:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        {$ELSE}
          {$IFDEF MSWINDOWS}
        Buf := @value.value;
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_SNDTIMEO),
          Buf, sizeOf(value.value));
          {$ELSE}
        timeval.tv_sec:=value.value div 1000;
        timeval.tv_usec:=(value.value mod 1000) * 1000;
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_SNDTIMEO),
          @timeval, sizeOf(timeval));
          {$ENDIF}
        {$ENDIF}
      end;
    SOT_Reuse:
      begin
        x := ord(value.Enabled);
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(x);
        {$ELSE}
        Buf := @x;
        {$ENDIF}
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_REUSEADDR), Buf, sizeOf(x));
      end;
    SOT_TTL:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        {$ELSE}
        Buf := @value.value;
        {$ENDIF}
        if FIP6Used then
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IPV6), integer(IPV6_UNICAST_HOPS),
            Buf, sizeOf(value.value))
        else
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IP), integer(IP_TTL),
            Buf, sizeOf(value.value));
      end;
    SOT_Broadcast:
      begin
//#todo1 broadcasty na IP6
        x := ord(value.Enabled);
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(x);
        {$ELSE}
        Buf := @x;
        {$ENDIF}
        synsock.SetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_BROADCAST), Buf, sizeOf(x));
      end;
    SOT_MulticastTTL:
      begin
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(value.value);
        {$ELSE}
        Buf := @value.value;
        {$ENDIF}
        if FIP6Used then
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IPV6), integer(IPV6_MULTICAST_HOPS),
            Buf, sizeOf(value.value))
        else
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IP), integer(IP_MULTICAST_TTL),
            Buf, sizeOf(value.value));
      end;
   SOT_MulticastLoop:
      begin
        x := ord(value.Enabled);
        {$IFDEF CIL}
        Buf := system.BitConverter.GetBytes(x);
        {$ELSE}
        Buf := @x;
        {$ENDIF}
        if FIP6Used then
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IPV6), integer(IPV6_MULTICAST_LOOP), Buf, sizeOf(x))
        else
          synsock.SetSockOpt(FSocket, integer(IPPROTO_IP), integer(IP_MULTICAST_LOOP), Buf, sizeOf(x));
      end;
  end;
  value.free;
end;

PROCEDURE TBlockSocket.DelayedOption(CONST value: TSynaOption);
begin
  if FSocket = INVALID_SOCKET then
  begin
    FDelayedOptions.Insert(0, value);
  end
  else
    SetDelayedOption(value);
end;

PROCEDURE TBlockSocket.ProcessDelayedOptions;
VAR
  n: integer;
  d: TSynaOption;
begin
  for n := FDelayedOptions.count - 1 downto 0 do
  begin
    d := TSynaOption(FDelayedOptions[n]);
    SetDelayedOption(d);
  end;
  FDelayedOptions.clear;
end;

PROCEDURE TBlockSocket.SetSin(VAR sin: TVarSin; IP, Port: string);
VAR
  f: TSocketFamily;
begin
  DoStatus(HR_ResolvingBegin, IP + ':' + Port);
  ResetLastError;
  //if socket exists, then use their type, else use users selection
  f := SF_Any;
  if (FSocket = INVALID_SOCKET) and (FFamily = SF_any) then
  begin
    if IsIP(IP) then
      f := SF_IP4
    else
      if IsIP6(IP) then
        f := SF_IP6;
  end
  else
    f := FFamily;
  FLastError := synsock.SetVarSin(sin, ip, port, FamilyToAF(f),
    GetSocketprotocol, GetSocketType, FPreferIP4);
  DoStatus(HR_ResolvingEnd, GetSinIP(sin) + ':' + intToStr(GetSinPort(sin)));
end;

FUNCTION TBlockSocket.GetSinIP(sin: TVarSin): string;
begin
  result := synsock.GetSinIP(sin);
end;

FUNCTION TBlockSocket.GetSinPort(sin: TVarSin): integer;
begin
  result := synsock.GetSinPort(sin);
end;

PROCEDURE TBlockSocket.CreateSocket;
VAR
  sin: TVarSin;
begin
  //dummy for SF_Any Family mode
  ResetLastError;
  if (FFamily <> SF_Any) and (FSocket = INVALID_SOCKET) then
  begin
    {$IFDEF CIL}
    if FFamily = SF_IP6 then
      sin := TVarSin.create(IPAddress.Parse('::0'), 0)
    else
      sin := TVarSin.create(IPAddress.Parse('0.0.0.0'), 0);
    {$ELSE}
    FillChar(sin, sizeOf(sin), 0);
    if FFamily = SF_IP6 then
      sin.sin_family := AF_INET6
    else
      sin.sin_family := AF_INET;
    {$ENDIF}
    InternalCreateSocket(sin);
  end;
end;

PROCEDURE TBlockSocket.CreateSocketByName(CONST value: string);
VAR
  sin: TVarSin;
begin
  ResetLastError;
  if FSocket = INVALID_SOCKET then
  begin
    SetSin(sin, value, '0');
    if FLastError = 0 then
      InternalCreateSocket(sin);
  end;
end;

PROCEDURE TBlockSocket.InternalCreateSocket(sin: TVarSin);
begin
  FStopFlag := false;
  FRecvCounter := 0;
  FSendCounter := 0;
  ResetLastError;
  if FSocket = INVALID_SOCKET then
  begin
    FBuffer := '';
    FBinded := false;
    FIP6Used := sin.AddressFamily = AF_INET6;
    FSocket := synsock.Socket(integer(sin.AddressFamily), GetSocketType, GetSocketProtocol);
    if FSocket = INVALID_SOCKET then
      FLastError := synsock.WSAGetLastError;
    {$IFNDEF CIL}
    FD_ZERO(FFDSet);
    FD_SET(FSocket, FFDSet);
    {$ENDIF}
    ExceptCheck;
    if FIP6used then
      DoStatus(HR_SocketCreate, 'IPv6')
    else
      DoStatus(HR_SocketCreate, 'IPv4');
    ProcessDelayedOptions;
    DoCreateSocket;
  end;
end;

PROCEDURE TBlockSocket.CloseSocket;
begin
  AbortSocket;
end;

PROCEDURE TBlockSocket.AbortSocket;
VAR
  n: integer;
  p: TSynaOption;
begin
  if FSocket <> INVALID_SOCKET then
    synsock.CloseSocket(FSocket);
  FSocket := INVALID_SOCKET;
  for n := FDelayedOptions.count - 1 downto 0 do
    begin
      p := TSynaOption(FDelayedOptions[n]);
      p.free;
    end;
  FDelayedOptions.clear;
  FFamily := FFamilySave;
  DoStatus(HR_SocketClose, '');
end;

PROCEDURE TBlockSocket.Bind(IP, Port: string);
VAR
  sin: TVarSin;
begin
  ResetLastError;
  if (FSocket <> INVALID_SOCKET)
    or not((FFamily = SF_ANY) and (IP = cAnyHost) and (Port = cAnyPort)) then
  begin
    SetSin(sin, IP, Port);
    if FLastError = 0 then
    begin
      if FSocket = INVALID_SOCKET then
        InternalCreateSocket(sin);
      SockCheck(synsock.Bind(FSocket, sin));
      GetSinLocal;
      FBuffer := '';
      FBinded := true;
    end;
    ExceptCheck;
    DoStatus(HR_Bind, IP + ':' + Port);
  end;
end;

PROCEDURE TBlockSocket.Connect(IP, Port: string);
VAR
  sin: TVarSin;
begin
  SetSin(sin, IP, Port);
  if FLastError = 0 then
  begin
    if FSocket = INVALID_SOCKET then
      InternalCreateSocket(sin);
    SockCheck(synsock.Connect(FSocket, sin));
    if FLastError = 0 then
      GetSins;
    FBuffer := '';
    FLastCR := false;
    FLastLF := false;
  end;
  ExceptCheck;
  DoStatus(HR_Connect, IP + ':' + Port);
end;

PROCEDURE TBlockSocket.Listen;
begin
  SockCheck(synsock.Listen(FSocket, SOMAXCONN));
  GetSins;
  ExceptCheck;
  DoStatus(HR_Listen, '');
end;

FUNCTION TBlockSocket.accept: TSocket;
begin
  result := synsock.accept(FSocket, FRemoteSin);
///    SockCheck(Result);
  ExceptCheck;
  DoStatus(HR_Accept, '');
end;

PROCEDURE TBlockSocket.GetSinLocal;
begin
  synsock.GetSockName(FSocket, FLocalSin);
end;

PROCEDURE TBlockSocket.GetSinRemote;
begin
  synsock.GetPeerName(FSocket, FRemoteSin);
end;

PROCEDURE TBlockSocket.GetSins;
begin
  GetSinLocal;
  GetSinRemote;
end;

PROCEDURE TBlockSocket.SetBandwidth(value: integer);
begin
  MaxSendBandwidth := value;
  MaxRecvBandwidth := value;
end;

PROCEDURE TBlockSocket.LimitBandwidth(length: integer; MaxB: integer; VAR next: Longword);
VAR
  x: Longword;
  y: Longword;
  n: integer;
begin
  if FStopFlag then
    exit;
  if MaxB > 0 then
  begin
    y := GetTick;
    if next > y then
    begin
      x := next - y;
      if x > 0 then
      begin
        DoStatus(HR_Wait, intToStr(x));
        sleep(x mod 250);
        for n := 1 to x div 250 do
          if FStopFlag then
            break
          else
            sleep(250);
      end;
    end;
    next := GetTick + trunc((length / MaxB) * 1000);
  end;
end;

FUNCTION TBlockSocket.TestStopFlag: boolean;
begin
  DoHeartbeat;
  result := FStopFlag;
  if result then
  begin
    FStopFlag := false;
    FLastError := WSAECONNABORTED;
    ExceptCheck;
  end;
end;


FUNCTION TBlockSocket.SendBuffer(buffer: TMemory; length: integer): integer;
{$IFNDEF CIL}
VAR
  x, y: integer;
  l, r: integer;
  p: pointer;
{$ENDIF}
begin
  result := 0;
  if TestStopFlag then
    exit;
  DoMonitor(true, buffer, length);
{$IFDEF CIL}
  result := synsock.Send(FSocket, buffer, length, 0);
{$ELSE}
  l := length;
  x := 0;
  while x < l do
  begin
    y := l - x;
    if y > FSendMaxChunk then
      y := FSendMaxChunk;
    if y > 0 then
    begin
      LimitBandwidth(y, FMaxSendBandwidth, FNextsend);
      p := IncPoint(buffer, x);
      r := synsock.Send(FSocket, p, y, MSG_NOSIGNAL);
      SockCheck(r);
      if FLastError = WSAEWOULDBLOCK then
      begin
        if CanWrite(FNonblockSendTimeout) then
        begin
          r := synsock.Send(FSocket, p, y, MSG_NOSIGNAL);
          SockCheck(r);
        end
        else
          FLastError := WSAETIMEDOUT;
      end;
      if FLastError <> 0 then
        break;
      inc(x, r);
      inc(result, r);
      inc(FSendCounter, r);
      DoStatus(HR_WriteCount, intToStr(r));
    end
    else
      break;
  end;
{$ENDIF}
  ExceptCheck;
end;

PROCEDURE TBlockSocket.SendByte(data: byte);
{$IFDEF CIL}
VAR
  Buf: TMemory;
{$ENDIF}
begin
{$IFDEF CIL}
  setLength(Buf, 1);
  Buf[0] := data;
  SendBuffer(Buf, 1);
{$ELSE}
  SendBuffer(@data, 1);
{$ENDIF}
end;

PROCEDURE TBlockSocket.SendString(data: ansistring);
VAR
  Buf: TMemory;
begin
  {$IFDEF CIL}
  Buf := BytesOf(data);
  {$ELSE}
  Buf := pointer(data);
  {$ENDIF}
  SendBuffer(Buf, length(data));
end;

PROCEDURE TBlockSocket.SendInteger(data: integer);
VAR
  Buf: TMemory;
begin
  {$IFDEF CIL}
  Buf := system.BitConverter.GetBytes(data);
  {$ELSE}
  Buf := @data;
  {$ENDIF}
  SendBuffer(Buf, sizeOf(data));
end;

PROCEDURE TBlockSocket.SendBlock(CONST data: ansistring);
VAR
  i: integer;
begin
  i := SwapBytes(length(data));
  SendString(Codelongint(i) + data);
end;

PROCEDURE TBlockSocket.InternalSendStream(CONST Stream: TStream; WithSize, Indy: boolean);
VAR
  l: integer;
  yr: integer;
  s: ansistring;
  b: boolean;
{$IFDEF CIL}
  Buf: TMemory;
{$ENDIF}
begin
  b := true;
  l := 0;
  if WithSize then
  begin
    l := Stream.size - Stream.position;;
    if not Indy then
      l := synsock.HToNL(l);
  end;
  repeat
    {$IFDEF CIL}
    setLength(Buf, FSendMaxChunk);
    yr := Stream.read(Buf, FSendMaxChunk);
    if yr > 0 then
    begin
      if WithSize and b then
      begin
        b := false;
        SendString(CodeLongInt(l));
      end;
      SendBuffer(Buf, yr);
      if FLastError <> 0 then
        break;
    end
    {$ELSE}
    setLength(s, FSendMaxChunk);
    yr := Stream.read(pointer(s)^, FSendMaxChunk);
    if yr > 0 then
    begin
      setLength(s, yr);
      if WithSize and b then
      begin
        b := false;
        SendString(CodeLongInt(l) + s);
      end
      else
        SendString(s);
      if FLastError <> 0 then
        break;
    end
    {$ENDIF}
  until yr <= 0;
end;

PROCEDURE TBlockSocket.SendStreamRaw(CONST Stream: TStream);
begin
  InternalSendStream(Stream, false, false);
end;

PROCEDURE TBlockSocket.SendStreamIndy(CONST Stream: TStream);
begin
  InternalSendStream(Stream, true, true);
end;

PROCEDURE TBlockSocket.SendStream(CONST Stream: TStream);
begin
  InternalSendStream(Stream, true, false);
end;

FUNCTION TBlockSocket.RecvBuffer(buffer: TMemory; length: integer): integer;
begin
  result := 0;
  if TestStopFlag then
    exit;
  LimitBandwidth(length, FMaxRecvBandwidth, FNextRecv);
//  Result := synsock.Recv(FSocket, Buffer^, Length, MSG_NOSIGNAL);
  result := synsock.Recv(FSocket, buffer, length, MSG_NOSIGNAL);
  if result = 0 then
    FLastError := WSAECONNRESET
  else
    SockCheck(result);
  ExceptCheck;
  if result > 0 then
  begin
    inc(FRecvCounter, result);
    DoStatus(HR_ReadCount, intToStr(result));
    DoMonitor(false, buffer, result);
    DoReadFilter(buffer, result);
  end;
end;

FUNCTION TBlockSocket.RecvBufferEx(buffer: TMemory; len: integer;
  Timeout: integer): integer;
VAR
  s: ansistring;
  rl, l: integer;
  ti: Longword;
{$IFDEF CIL}
  n: integer;
  b: TMemory;
{$ENDIF}
begin
  ResetLastError;
  result := 0;
  if len > 0 then
  begin
    rl := 0;
    repeat
      ti := GetTick;
      s := RecvPacket(Timeout);
      l := length(s);
      if (rl + l) > len then
        l := len - rl;
      {$IFDEF CIL}
      b := BytesOf(s);
      for n := 0 to l do
        buffer[rl + n] := b[n];
      {$ELSE}
      move(pointer(s)^, IncPoint(buffer, rl)^, l);
      {$ENDIF}
      rl := rl + l;
      if FLastError <> 0 then
        break;
      if rl >= len then
        break;
      if not FInterPacketTimeout then
      begin
        Timeout := Timeout - integer(TickDelta(ti, GetTick));
        if Timeout <= 0 then
        begin
          FLastError := WSAETIMEDOUT;
          break;
        end;
      end;
    until false;
    Delete(s, 1, l);
    FBuffer := s;
    result := rl;
  end;
end;

FUNCTION TBlockSocket.RecvBufferStr(len: integer; Timeout: integer): ansistring;
VAR
  x: integer;
{$IFDEF CIL}
  Buf: Tmemory;
{$ENDIF}
begin
  result := '';
  if len > 0 then
  begin
    {$IFDEF CIL}
    setLength(Buf, len);
    x := RecvBufferEx(Buf, len , Timeout);
    if FLastError = 0 then
    begin
      setLength(Buf, x);
      result := StringOf(Buf);
    end
    else
      result := '';
    {$ELSE}
    setLength(result, len);
    x := RecvBufferEx(pointer(result), len , Timeout);
    if FLastError = 0 then
      setLength(result, x)
    else
      result := '';
    {$ENDIF}
  end;
end;

FUNCTION TBlockSocket.RecvPacket(Timeout: integer): ansistring;
VAR
  x: integer;
{$IFDEF CIL}
  Buf: TMemory;
{$ENDIF}
begin
  result := '';
  ResetLastError;
  if FBuffer <> '' then
  begin
    result := FBuffer;
    FBuffer := '';
  end
  else
  begin
    {$IFDEF MSWINDOWS}
    //not drain CPU on large downloads...
    sleep(0);
    {$ENDIF}
    x := WaitingData;
    if x > 0 then
    begin
      {$IFDEF CIL}
      setLength(Buf, x);
      x := RecvBuffer(Buf, x);
      if x >= 0 then
      begin
        setLength(Buf, x);
        result := StringOf(Buf);
      end;
      {$ELSE}
      setLength(result, x);
      x := RecvBuffer(pointer(result), x);
      if x >= 0 then
        setLength(result, x);
      {$ENDIF}
    end
    else
    begin
      if CanRead(Timeout) then
      begin
        x := WaitingData;
        if x = 0 then
          FLastError := WSAECONNRESET;
        if x > 0 then
        begin
          {$IFDEF CIL}
          setLength(Buf, x);
          x := RecvBuffer(Buf, x);
          if x >= 0 then
          begin
            setLength(Buf, x);
            result := StringOf(Buf);
          end;
          {$ELSE}
          setLength(result, x);
          x := RecvBuffer(pointer(result), x);
          if x >= 0 then
            setLength(result, x);
          {$ENDIF}
        end;
      end
      else
        FLastError := WSAETIMEDOUT;
    end;
  end;
  if FConvertLineEnd and (result <> '') then
  begin
    if FLastCR and (result[1] = LF) then
      Delete(result, 1, 1);
    if FLastLF and (result[1] = CR) then
      Delete(result, 1, 1);
    FLastCR := false;
    FLastLF := false;
  end;
  ExceptCheck;
end;


FUNCTION TBlockSocket.RecvByte(Timeout: integer): byte;
begin
  result := 0;
  ResetLastError;
  if FBuffer = '' then
    FBuffer := RecvPacket(Timeout);
  if (FLastError = 0) and (FBuffer <> '') then
  begin
    result := ord(FBuffer[1]);
    Delete(FBuffer, 1, 1);
  end;
  ExceptCheck;
end;

FUNCTION TBlockSocket.RecvInteger(Timeout: integer): integer;
VAR
  s: ansistring;
begin
  result := 0;
  s := RecvBufferStr(4, Timeout);
  if FLastError = 0 then
    result := (ord(s[1]) + ord(s[2]) * 256) + (ord(s[3]) + ord(s[4]) * 256) * 65536;
end;

FUNCTION TBlockSocket.RecvTerminated(Timeout: integer; CONST Terminator: ansistring): ansistring;
VAR
  x: integer;
  s: ansistring;
  l: integer;
  CorCRLF: boolean;
  t: ansistring;
  tl: integer;
  ti: Longword;
begin
  ResetLastError;
  result := '';
  l := length(Terminator);
  if l = 0 then
    exit;
  tl := l;
  CorCRLF := FConvertLineEnd and (Terminator = CRLF);
  s := '';
  x := 0;
  repeat
    //get rest of FBuffer or incomming new data...
    ti := GetTick;
    s := s + RecvPacket(Timeout);
    if FLastError <> 0 then
      break;
    x := 0;
    if length(s) > 0 then
      if CorCRLF then
      begin
        t := '';
        x := PosCRLF(s, t);
        tl := length(t);
        if t = CR then
          FLastCR := true;
        if t = LF then
          FLastLF := true;
      end
      else
      begin
        x := pos(Terminator, s);
        tl := l;
      end;
    if (FMaxLineLength <> 0) and (length(s) > FMaxLineLength) then
    begin
      FLastError := WSAENOBUFS;
      break;
    end;
    if x > 0 then
      break;
    if not FInterPacketTimeout then
    begin
      Timeout := Timeout - integer(TickDelta(ti, GetTick));
      if Timeout <= 0 then
      begin
        FLastError := WSAETIMEDOUT;
        break;
      end;
    end;
  until false;
  if x > 0 then
  begin
    result := copy(s, 1, x - 1);
    Delete(s, 1, x + tl - 1);
  end;
  FBuffer := s;
  ExceptCheck;
end;

FUNCTION TBlockSocket.RecvString(Timeout: integer): ansistring;
VAR
  s: ansistring;
begin
  result := '';
  s := RecvTerminated(Timeout, CRLF);
  if FLastError = 0 then
    result := s;
end;

FUNCTION TBlockSocket.RecvBlock(Timeout: integer): ansistring;
VAR
  x: integer;
begin
  result := '';
  x := RecvInteger(Timeout);
  if FLastError = 0 then
    result := RecvBufferStr(x, Timeout);
end;

PROCEDURE TBlockSocket.RecvStreamRaw(CONST Stream: TStream; Timeout: integer);
VAR
  s: ansistring;
begin
  repeat
    s := RecvPacket(Timeout);
    if FLastError = 0 then
      WriteStrToStream(Stream, s);
  until FLastError <> 0;
end;

PROCEDURE TBlockSocket.RecvStreamSize(CONST Stream: TStream; Timeout: integer; size: integer);
VAR
  s: ansistring;
  n: integer;
{$IFDEF CIL}
  Buf: TMemory;
{$ENDIF}
begin
  for n := 1 to (size div FSendMaxChunk) do
  begin
    {$IFDEF CIL}
    setLength(Buf, FSendMaxChunk);
    RecvBufferEx(Buf, FSendMaxChunk, Timeout);
    if FLastError <> 0 then
      exit;
    Stream.write(Buf, FSendMaxChunk);
    {$ELSE}
    s := RecvBufferStr(FSendMaxChunk, Timeout);
    if FLastError <> 0 then
      exit;
    WriteStrToStream(Stream, s);
    {$ENDIF}
  end;
  n := size mod FSendMaxChunk;
  if n > 0 then
  begin
    {$IFDEF CIL}
    setLength(Buf, n);
    RecvBufferEx(Buf, n, Timeout);
    if FLastError <> 0 then
      exit;
    Stream.write(Buf, n);
    {$ELSE}
    s := RecvBufferStr(n, Timeout);
    if FLastError <> 0 then
      exit;
    WriteStrToStream(Stream, s);
    {$ENDIF}
  end;
end;

PROCEDURE TBlockSocket.RecvStreamIndy(CONST Stream: TStream; Timeout: integer);
VAR
  x: integer;
begin
  x := RecvInteger(Timeout);
  x := synsock.NToHL(x);
  if FLastError = 0 then
    RecvStreamSize(Stream, Timeout, x);
end;

PROCEDURE TBlockSocket.RecvStream(CONST Stream: TStream; Timeout: integer);
VAR
  x: integer;
begin
  x := RecvInteger(Timeout);
  if FLastError = 0 then
    RecvStreamSize(Stream, Timeout, x);
end;

FUNCTION TBlockSocket.PeekBuffer(buffer: TMemory; length: integer): integer;
begin
 {$IFNDEF CIL}
//  Result := synsock.Recv(FSocket, Buffer^, Length, MSG_PEEK + MSG_NOSIGNAL);
  result := synsock.Recv(FSocket, buffer, length, MSG_PEEK + MSG_NOSIGNAL);
  SockCheck(result);
  ExceptCheck;
  {$ENDIF}
end;

FUNCTION TBlockSocket.PeekByte(Timeout: integer): byte;
VAR
  s: string;
begin
 {$IFNDEF CIL}
  result := 0;
  if CanRead(Timeout) then
  begin
    setLength(s, 1);
    PeekBuffer(pointer(s), 1);
    if s <> '' then
      result := ord(s[1]);
  end
  else
    FLastError := WSAETIMEDOUT;
  ExceptCheck;
  {$ENDIF}
end;

PROCEDURE TBlockSocket.ResetLastError;
begin
  FLastError := 0;
  FLastErrorDesc := '';
end;

FUNCTION TBlockSocket.SockCheck(SockResult: integer): integer;
begin
  ResetLastError;
  if SockResult = integer(SOCKET_ERROR) then
  begin
    FLastError := synsock.WSAGetLastError;
    FLastErrorDesc := GetErrorDescEx;
  end;
  result := FLastError;
end;

PROCEDURE TBlockSocket.ExceptCheck;
VAR
  e: ESynapseError;
begin
  FLastErrorDesc := GetErrorDescEx;
  if (LastError <> 0) and (LastError <> WSAEINPROGRESS)
    and (LastError <> WSAEWOULDBLOCK) then
  begin
    DoStatus(HR_Error, intToStr(FLastError) + ',' + FLastErrorDesc);
    if FRaiseExcept then
    begin
      e := ESynapseError.create(format('Synapse TCP/IP Socket error %d: %s',
        [FLastError, FLastErrorDesc]));
      e.ErrorCode := FLastError;
      e.errorMessage := FLastErrorDesc;
      raise e;
    end;
  end;
end;

FUNCTION TBlockSocket.WaitingData: integer;
VAR
  x: integer;
begin
  result := 0;
  if synsock.IoctlSocket(FSocket, FIONREAD, x) = 0 then
    result := x;
  if result > c64k then
    result := c64k;
end;

FUNCTION TBlockSocket.WaitingDataEx: integer;
begin
  if FBuffer <> '' then
    result := length(FBuffer)
  else
    result := WaitingData;
end;

PROCEDURE TBlockSocket.Purge;
begin
  sleep(1);
  try
    while (length(FBuffer) > 0) or (WaitingData > 0) do
    begin
      RecvPacket(0);
      if FLastError <> 0 then
        break;
    end;
  except
    on Exception do;
  end;
  ResetLastError;
end;

PROCEDURE TBlockSocket.SetLinger(Enable: boolean; Linger: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_Linger;
  d.Enabled := Enable;
  d.value := Linger;
  DelayedOption(d);
end;

FUNCTION TBlockSocket.LocalName: string;
begin
  result := synsock.GetHostName;
  if result = '' then
    result := '127.0.0.1';
end;

PROCEDURE TBlockSocket.ResolveNameToIP(name: string; CONST IPList: TStrings);
begin
  IPList.clear;
  synsock.ResolveNameToIP(name, FamilyToAF(FFamily), GetSocketprotocol, GetSocketType, IPList);
  if IPList.count = 0 then
    IPList.add(cAnyHost);
end;

FUNCTION TBlockSocket.ResolveName(name: string): string;
VAR
  l: TStringList;
begin
  l := TStringList.create;
  try
    ResolveNameToIP(name, l);
    result := l[0];
  finally
    l.free;
  end;
end;

FUNCTION TBlockSocket.ResolvePort(Port: string): word;
begin
  result := synsock.ResolvePort(Port, FamilyToAF(FFamily), GetSocketProtocol, GetSocketType);
end;

FUNCTION TBlockSocket.ResolveIPToName(IP: string): string;
begin
  if not IsIP(IP) and not IsIp6(IP) then
    IP := ResolveName(IP);
  result := synsock.ResolveIPToName(IP, FamilyToAF(FFamily), GetSocketProtocol, GetSocketType);
end;

PROCEDURE TBlockSocket.SetRemoteSin(IP, Port: string);
begin
  SetSin(FRemoteSin, IP, Port);
end;

FUNCTION TBlockSocket.GetLocalSinIP: string;
begin
  result := GetSinIP(FLocalSin);
end;

FUNCTION TBlockSocket.GetRemoteSinIP: string;
begin
  result := GetSinIP(FRemoteSin);
end;

FUNCTION TBlockSocket.GetLocalSinPort: integer;
begin
  result := GetSinPort(FLocalSin);
end;

FUNCTION TBlockSocket.GetRemoteSinPort: integer;
begin
  result := GetSinPort(FRemoteSin);
end;

FUNCTION TBlockSocket.InternalCanRead(Timeout: integer): boolean;
{$IFDEF CIL}
begin
  result := FSocket.Poll(Timeout * 1000, SelectMode.SelectRead);
{$ELSE}
VAR
  timeval: PTimeVal;
  TimeV: TTimeVal;
  x: integer;
  FDSet: TFDSet;
begin
  TimeV.tv_usec := (Timeout mod 1000) * 1000;
  TimeV.tv_sec := Timeout div 1000;
  timeval := @TimeV;
  if Timeout = -1 then
    timeval := nil;
  FDSet := FFdSet;
  x := synsock.Select(FSocket + 1, @FDSet, nil, nil, timeval);
  SockCheck(x);
  if FLastError <> 0 then
    x := 0;
  result := x > 0;
{$ENDIF}
end;

FUNCTION TBlockSocket.CanRead(Timeout: integer): boolean;
VAR
  ti, tr: integer;
  n: integer;
begin
  if (FHeartbeatRate <> 0) and (Timeout <> -1) then
  begin
    ti := Timeout div FHeartbeatRate;
    tr := Timeout mod FHeartbeatRate;
  end
  else
  begin
    ti := 0;
    tr := Timeout;
  end;
  result := InternalCanRead(tr);
  if not result then
    for n := 0 to ti do
    begin
      DoHeartbeat;
      if FStopFlag then
      begin
        result := false;
        FStopFlag := false;
        break;
      end;
      result := InternalCanRead(FHeartbeatRate);
      if result then
        break;
    end;
  ExceptCheck;
  if result then
    DoStatus(HR_CanRead, '');
end;

FUNCTION TBlockSocket.CanWrite(Timeout: integer): boolean;
{$IFDEF CIL}
begin
  result := FSocket.Poll(Timeout * 1000, SelectMode.SelectWrite);
{$ELSE}
VAR
  timeval: PTimeVal;
  TimeV: TTimeVal;
  x: integer;
  FDSet: TFDSet;
begin
  TimeV.tv_usec := (Timeout mod 1000) * 1000;
  TimeV.tv_sec := Timeout div 1000;
  timeval := @TimeV;
  if Timeout = -1 then
    timeval := nil;
  FDSet := FFdSet;
  x := synsock.Select(FSocket + 1, nil, @FDSet, nil, timeval);
  SockCheck(x);
  if FLastError <> 0 then
    x := 0;
  result := x > 0;
{$ENDIF}
  ExceptCheck;
  if result then
    DoStatus(HR_CanWrite, '');
end;

FUNCTION TBlockSocket.CanReadEx(Timeout: integer): boolean;
begin
  if FBuffer <> '' then
    result := true
  else
    result := CanRead(Timeout);
end;

FUNCTION TBlockSocket.SendBufferTo(buffer: TMemory; length: integer): integer;
begin
  result := 0;
  if TestStopFlag then
    exit;
  DoMonitor(true, buffer, length);
  LimitBandwidth(length, FMaxSendBandwidth, FNextsend);
  result := synsock.SendTo(FSocket, buffer, length, MSG_NOSIGNAL, FRemoteSin);
  SockCheck(result);
  ExceptCheck;
  inc(FSendCounter, result);
  DoStatus(HR_WriteCount, intToStr(result));
end;

FUNCTION TBlockSocket.RecvBufferFrom(buffer: TMemory; length: integer): integer;
begin
  result := 0;
  if TestStopFlag then
    exit;
  LimitBandwidth(length, FMaxRecvBandwidth, FNextRecv);
  result := synsock.RecvFrom(FSocket, buffer, length, MSG_NOSIGNAL, FRemoteSin);
  SockCheck(result);
  ExceptCheck;
  inc(FRecvCounter, result);
  DoStatus(HR_ReadCount, intToStr(result));
  DoMonitor(false, buffer, result);
end;

FUNCTION TBlockSocket.GetSizeRecvBuffer: integer;
VAR
  l: integer;
{$IFDEF CIL}
  Buf: TMemory;
{$ENDIF}
begin
{$IFDEF CIL}
  setLength(Buf, 4);
  SockCheck(synsock.GetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_RCVBUF), Buf, l));
  result := system.BitConverter.ToInt32(Buf,0);
{$ELSE}
  l := sizeOf(result);
  SockCheck(synsock.GetSockOpt(FSocket, SOL_SOCKET, SO_RCVBUF, @result, l));
  if FLastError <> 0 then
    result := 1024;
  ExceptCheck;
{$ENDIF}
end;

PROCEDURE TBlockSocket.SetSizeRecvBuffer(size: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_RecvBuff;
  d.value := size;
  DelayedOption(d);
end;

FUNCTION TBlockSocket.GetSizeSendBuffer: integer;
VAR
  l: integer;
{$IFDEF CIL}
  Buf: TMemory;
{$ENDIF}
begin
{$IFDEF CIL}
  setLength(Buf, 4);
  SockCheck(synsock.GetSockOpt(FSocket, integer(SOL_SOCKET), integer(SO_SNDBUF), Buf, l));
  result := system.BitConverter.ToInt32(Buf,0);
{$ELSE}
  l := sizeOf(result);
  SockCheck(synsock.GetSockOpt(FSocket, SOL_SOCKET, SO_SNDBUF, @result, l));
  if FLastError <> 0 then
    result := 1024;
  ExceptCheck;
{$ENDIF}
end;

PROCEDURE TBlockSocket.SetSizeSendBuffer(size: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_SendBuff;
  d.value := size;
  DelayedOption(d);
end;

PROCEDURE TBlockSocket.SetNonBlockMode(value: boolean);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_nonblock;
  d.Enabled := value;
  DelayedOption(d);
end;

PROCEDURE TBlockSocket.SetTimeout(Timeout: integer);
begin
  SetSendTimeout(Timeout);
  SetRecvTimeout(Timeout);
end;

PROCEDURE TBlockSocket.SetSendTimeout(Timeout: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_sendtimeout;
  d.value := Timeout;
  DelayedOption(d);
end;

PROCEDURE TBlockSocket.SetRecvTimeout(Timeout: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_recvtimeout;
  d.value := Timeout;
  DelayedOption(d);
end;

{$IFNDEF CIL}
FUNCTION TBlockSocket.GroupCanRead(CONST SocketList: TList; Timeout: integer;
  CONST CanReadList: TList): boolean;
VAR
  FDSet: TFDSet;
  timeval: PTimeVal;
  TimeV: TTimeVal;
  x, n: integer;
  max: integer;
begin
  TimeV.tv_usec := (Timeout mod 1000) * 1000;
  TimeV.tv_sec := Timeout div 1000;
  timeval := @TimeV;
  if Timeout = -1 then
    timeval := nil;
  FD_ZERO(FDSet);
  max := 0;
  for n := 0 to SocketList.count - 1 do
    if TObject(SocketList.Items[n]) is TBlockSocket then
    begin
      if TBlockSocket(SocketList.Items[n]).Socket > max then
        max := TBlockSocket(SocketList.Items[n]).Socket;
      FD_SET(TBlockSocket(SocketList.Items[n]).Socket, FDSet);
    end;
  x := synsock.Select(max + 1, @FDSet, nil, nil, timeval);
  SockCheck(x);
  ExceptCheck;
  if FLastError <> 0 then
    x := 0;
  result := x > 0;
  CanReadList.clear;
  if result then
    for n := 0 to SocketList.count - 1 do
      if TObject(SocketList.Items[n]) is TBlockSocket then
        if FD_ISSET(TBlockSocket(SocketList.Items[n]).Socket, FDSet) then
          CanReadList.add(TBlockSocket(SocketList.Items[n]));
end;
{$ENDIF}

PROCEDURE TBlockSocket.EnableReuse(value: boolean);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_reuse;
  d.Enabled := value;
  DelayedOption(d);
end;

PROCEDURE TBlockSocket.SetTTL(TTL: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_TTL;
  d.value := TTL;
  DelayedOption(d);
end;

FUNCTION TBlockSocket.GetTTL:integer;
VAR
  l: integer;
begin
{$IFNDEF CIL}
  l := sizeOf(result);
  if FIP6Used then
    synsock.GetSockOpt(FSocket, IPPROTO_IPV6, IPV6_UNICAST_HOPS, @result, l)
  else
    synsock.GetSockOpt(FSocket, IPPROTO_IP, IP_TTL, @result, l);
{$ENDIF}
end;

PROCEDURE TBlockSocket.SetFamily(value: TSocketFamily);
begin
  FFamily := value;
  FFamilySave := value;
end;

PROCEDURE TBlockSocket.SetSocket(value: TSocket);
begin
  FRecvCounter := 0;
  FSendCounter := 0;
  FSocket := value;
{$IFNDEF CIL}
  FD_ZERO(FFDSet);
  FD_SET(FSocket, FFDSet);
{$ENDIF}
  GetSins;
  FIP6Used := FRemoteSin.AddressFamily = AF_INET6;
end;

FUNCTION TBlockSocket.GetWsaData: TWSAData;
begin
  {$IFDEF ONCEWINSOCK}
  result := WsaDataOnce;
  {$ELSE}
  result := FWsaDataOnce;
  {$ENDIF}
end;

FUNCTION TBlockSocket.GetSocketType: integer;
begin
  result := 0;
end;

FUNCTION TBlockSocket.GetSocketProtocol: integer;
begin
  result := integer(IPPROTO_IP);
end;

PROCEDURE TBlockSocket.DoStatus(Reason: THookSocketReason; CONST value: string);
begin
  if assigned(OnStatus) then
    OnStatus(self, Reason, value);
end;

PROCEDURE TBlockSocket.DoReadFilter(buffer: TMemory; VAR len: integer);
VAR
  s: ansistring;
begin
  if assigned(OnReadFilter) then
    if len > 0 then
      begin
        {$IFDEF CIL}
        s := StringOf(buffer);
        {$ELSE}
        setLength(s, len);
        move(buffer^, pointer(s)^, len);
        {$ENDIF}
        OnReadFilter(self, s);
        if length(s) > len then
          setLength(s, len);
        len := length(s);
        {$IFDEF CIL}
        buffer := BytesOf(s);
        {$ELSE}
        move(pointer(s)^, buffer^, len);
        {$ENDIF}
      end;
end;

PROCEDURE TBlockSocket.DoCreateSocket;
begin
  if assigned(OnCreateSocket) then
    OnCreateSocket(self);
end;

PROCEDURE TBlockSocket.DoMonitor(Writing: boolean; CONST buffer: TMemory; len: integer);
begin
  if assigned(OnMonitor) then
  begin
    OnMonitor(self, Writing, buffer, len);
  end;
end;

PROCEDURE TBlockSocket.DoHeartbeat;
begin
  if assigned(OnHeartbeat) and (FHeartbeatRate <> 0) then
  begin
    OnHeartbeat(self);
  end;
end;

FUNCTION TBlockSocket.GetErrorDescEx: string;
begin
  result := GetErrorDesc(FLastError);
end;

class FUNCTION TBlockSocket.GetErrorDesc(ErrorCode: integer): string;
begin
{$IFDEF CIL}
  if ErrorCode = 0 then
    result := ''
  else
  begin
    result := WSAGetLastErrorDesc;
    if result = '' then
      result := 'Other Winsock error (' + intToStr(ErrorCode) + ')';
  end;
{$ELSE}
  case ErrorCode of
    0:
      result := '';
    WSAEINTR: {10004}
      result := 'Interrupted system call';
    WSAEBADF: {10009}
      result := 'Bad file number';
    WSAEACCES: {10013}
      result := 'Permission denied';
    WSAEFAULT: {10014}
      result := 'Bad address';
    WSAEINVAL: {10022}
      result := 'Invalid argument';
    WSAEMFILE: {10024}
      result := 'Too many open files';
    WSAEWOULDBLOCK: {10035}
      result := 'Operation would block';
    WSAEINPROGRESS: {10036}
      result := 'Operation now in progress';
    WSAEALREADY: {10037}
      result := 'Operation already in progress';
    WSAENOTSOCK: {10038}
      result := 'Socket operation on nonsocket';
    WSAEDESTADDRREQ: {10039}
      result := 'Destination address required';
    WSAEMSGSIZE: {10040}
      result := 'Message too long';
    WSAEPROTOTYPE: {10041}
      result := 'Protocol wrong type for Socket';
    WSAENOPROTOOPT: {10042}
      result := 'Protocol not available';
    WSAEPROTONOSUPPORT: {10043}
      result := 'Protocol not supported';
    WSAESOCKTNOSUPPORT: {10044}
      result := 'Socket not supported';
    WSAEOPNOTSUPP: {10045}
      result := 'Operation not supported on Socket';
    WSAEPFNOSUPPORT: {10046}
      result := 'Protocol family not supported';
    WSAEAFNOSUPPORT: {10047}
      result := 'Address family not supported';
    WSAEADDRINUSE: {10048}
      result := 'Address already in use';
    WSAEADDRNOTAVAIL: {10049}
      result := 'Can''t assign requested address';
    WSAENETDOWN: {10050}
      result := 'Network is down';
    WSAENETUNREACH: {10051}
      result := 'Network is unreachable';
    WSAENETRESET: {10052}
      result := 'Network dropped connection on reset';
    WSAECONNABORTED: {10053}
      result := 'Software caused connection abort';
    WSAECONNRESET: {10054}
      result := 'Connection reset by peer';
    WSAENOBUFS: {10055}
      result := 'No Buffer space available';
    WSAEISCONN: {10056}
      result := 'Socket is already connected';
    WSAENOTCONN: {10057}
      result := 'Socket is not connected';
    WSAESHUTDOWN: {10058}
      result := 'Can''t send after Socket shutdown';
    WSAETOOMANYREFS: {10059}
      result := 'Too many references:can''t splice';
    WSAETIMEDOUT: {10060}
      result := 'Connection timed out';
    WSAECONNREFUSED: {10061}
      result := 'Connection refused';
    WSAELOOP: {10062}
      result := 'Too many levels of symbolic links';
    WSAENAMETOOLONG: {10063}
      result := 'File name is too long';
    WSAEHOSTDOWN: {10064}
      result := 'Host is down';
    WSAEHOSTUNREACH: {10065}
      result := 'No route to host';
    WSAENOTEMPTY: {10066}
      result := 'Directory is not empty';
    WSAEPROCLIM: {10067}
      result := 'Too many processes';
    WSAEUSERS: {10068}
      result := 'Too many users';
    WSAEDQUOT: {10069}
      result := 'Disk quota exceeded';
    WSAESTALE: {10070}
      result := 'Stale NFS file handle';
    WSAEREMOTE: {10071}
      result := 'Too many levels of remote in path';
    WSASYSNOTREADY: {10091}
      result := 'Network subsystem is unusable';
    WSAVERNOTSUPPORTED: {10092}
      result := 'Winsock DLL cannot support this application';
    WSANOTINITIALISED: {10093}
      result := 'Winsock not initialized';
    WSAEDISCON: {10101}
      result := 'Disconnect';
    WSAHOST_NOT_FOUND: {11001}
      result := 'Host not found';
    WSATRY_AGAIN: {11002}
      result := 'Non authoritative - host not found';
    WSANO_RECOVERY: {11003}
      result := 'Non recoverable error';
    WSANO_DATA: {11004}
      result := 'Valid name, no data record of requested type'
  else
    result := 'Other Winsock error (' + intToStr(ErrorCode) + ')';
  end;
{$ENDIF}
end;

{======================================================================}

CONSTRUCTOR TSocksBlockSocket.create;
begin
  inherited create;
  FSocksIP:= '';
  FSocksPort:= '1080';
  FSocksTimeout:= 60000;
  FSocksUsername:= '';
  FSocksPassword:= '';
  FUsingSocks := false;
  FSocksResolver := true;
  FSocksLastError := 0;
  FSocksResponseIP := '';
  FSocksResponsePort := '';
  FSocksLocalIP := '';
  FSocksLocalPort := '';
  FSocksRemoteIP := '';
  FSocksRemotePort := '';
  FBypassFlag := false;
  FSocksType := ST_Socks5;
end;

FUNCTION TSocksBlockSocket.SocksOpen: boolean;
VAR
  Buf: ansistring;
  n: integer;
begin
  result := false;
  FUsingSocks := false;
  if FSocksType <> ST_Socks5 then
  begin
    FUsingSocks := true;
    result := true;
  end
  else
  begin
    FBypassFlag := true;
    try
      if FSocksUsername = '' then
        Buf := #5 + #1 + #0
      else
        Buf := #5 + #2 + #2 +#0;
      SendString(Buf);
      Buf := RecvBufferStr(2, FSocksTimeout);
      if length(Buf) < 2 then
        exit;
      if Buf[1] <> #5 then
        exit;
      n := ord(Buf[2]);
      case n of
        0: //not need authorisation
          ;
        2:
          begin
            Buf := #1 + AnsiChar(length(FSocksUsername)) + FSocksUsername
              + AnsiChar(length(FSocksPassword)) + FSocksPassword;
            SendString(Buf);
            Buf := RecvBufferStr(2, FSocksTimeout);
            if length(Buf) < 2 then
              exit;
            if Buf[2] <> #0 then
              exit;
          end;
      else
        //other authorisation is not supported!
        exit;
      end;
      FUsingSocks := true;
      result := true;
    finally
      FBypassFlag := false;
    end;
  end;
end;

FUNCTION TSocksBlockSocket.SocksRequest(cmd: byte;
  CONST IP, Port: string): boolean;
VAR
  Buf: ansistring;
begin
  FBypassFlag := true;
  try
    if FSocksType <> ST_Socks5 then
      Buf := #4 + AnsiChar(cmd) + SocksCode(IP, Port)
    else
      Buf := #5 + AnsiChar(cmd) + #0 + SocksCode(IP, Port);
    SendString(Buf);
    result := FLastError = 0;
  finally
    FBypassFlag := false;
  end;
end;

FUNCTION TSocksBlockSocket.SocksResponse: boolean;
VAR
  Buf, s: ansistring;
  x: integer;
begin
  result := false;
  FBypassFlag := true;
  try
    FSocksResponseIP := '';
    FSocksResponsePort := '';
    FSocksLastError := -1;
    if FSocksType <> ST_Socks5 then
    begin
      Buf := RecvBufferStr(8, FSocksTimeout);
      if FLastError <> 0 then
        exit;
      if Buf[1] <> #0 then
        exit;
      FSocksLastError := ord(Buf[2]);
    end
    else
    begin
      Buf := RecvBufferStr(4, FSocksTimeout);
      if FLastError <> 0 then
        exit;
      if Buf[1] <> #5 then
        exit;
      case ord(Buf[4]) of
        1:
          s := RecvBufferStr(4, FSocksTimeout);
        3:
          begin
            x := RecvByte(FSocksTimeout);
            if FLastError <> 0 then
              exit;
            s := AnsiChar(x) + RecvBufferStr(x, FSocksTimeout);
          end;
        4:
          s := RecvBufferStr(16, FSocksTimeout);
      else
        exit;
      end;
      Buf := Buf + s + RecvBufferStr(2, FSocksTimeout);
      if FLastError <> 0 then
        exit;
      FSocksLastError := ord(Buf[2]);
    end;
    if ((FSocksLastError <> 0) and (FSocksLastError <> 90)) then
      exit;
    SocksDecode(Buf);
    result := true;
  finally
    FBypassFlag := false;
  end;
end;

FUNCTION TSocksBlockSocket.SocksCode(IP, Port: string): ansistring;
VAR
  ip6: TIp6Bytes;
  n: integer;
begin
  if FSocksType <> ST_Socks5 then
  begin
    result := CodeInt(ResolvePort(Port));
    if not FSocksResolver then
      IP := ResolveName(IP);
    if IsIP(IP) then
    begin
      result := result + IPToID(IP);
      result := result + FSocksUsername + #0;
    end
    else
    begin
      result := result + IPToID('0.0.0.1');
      result := result + FSocksUsername + #0;
      result := result + IP + #0;
    end;
  end
  else
  begin
    if not FSocksResolver then
      IP := ResolveName(IP);
    if IsIP(IP) then
      result := #1 + IPToID(IP)
    else
      if IsIP6(IP) then
      begin
        ip6 := StrToIP6(IP);
        result := #4;
        for n := 0 to 15 do
          result := result + AnsiChar(ip6[n]);
      end
      else
        result := #3 + AnsiChar(length(IP)) + IP;
    result := result + CodeInt(ResolvePort(Port));
  end;
end;

FUNCTION TSocksBlockSocket.SocksDecode(value: ansistring): integer;
VAR
  Atyp: byte;
  y, n: integer;
  w: word;
  ip6: TIp6Bytes;
begin
  FSocksResponsePort := '0';
  result := 0;
  if FSocksType <> ST_Socks5 then
  begin
    if length(value) < 8 then
      exit;
    result := 3;
    w := DecodeInt(value, result);
    FSocksResponsePort := intToStr(w);
    FSocksResponseIP := format('%d.%d.%d.%d',
      [ord(value[5]), ord(value[6]), ord(value[7]), ord(value[8])]);
    result := 9;
  end
  else
  begin
    if length(value) < 4 then
      exit;
    Atyp := ord(value[4]);
    result := 5;
    case Atyp of
      1:
        begin
          if length(value) < 10 then
            exit;
          FSocksResponseIP := format('%d.%d.%d.%d',
              [ord(value[5]), ord(value[6]), ord(value[7]), ord(value[8])]);
          result := 9;
        end;
      3:
        begin
          y := ord(value[5]);
          if length(value) < (5 + y + 2) then
            exit;
          for n := 6 to 6 + y - 1 do
            FSocksResponseIP := FSocksResponseIP + value[n];
          result := 5 + y + 1;
        end;
      4:
        begin
          if length(value) < 22 then
            exit;
          for n := 0 to 15 do
            ip6[n] := ord(value[n + 5]);
          FSocksResponseIP := IP6ToStr(ip6);
          result := 21;
        end;
    else
      exit;
    end;
    w := DecodeInt(value, result);
    FSocksResponsePort := intToStr(w);
    result := result + 2;
  end;
end;

{======================================================================}

PROCEDURE TDgramBlockSocket.Connect(IP, Port: string);
begin
  SetRemoteSin(IP, Port);
  InternalCreateSocket(FRemoteSin);
  FBuffer := '';
  DoStatus(HR_Connect, IP + ':' + Port);
end;

FUNCTION TDgramBlockSocket.RecvBuffer(buffer: TMemory; length: integer): integer;
begin
  result := RecvBufferFrom(buffer, length);
end;

FUNCTION TDgramBlockSocket.SendBuffer(buffer: TMemory; length: integer): integer;
begin
  result := SendBufferTo(buffer, length);
end;

{======================================================================}

DESTRUCTOR TUDPBlockSocket.destroy;
begin
  if Assigned(FSocksControlSock) then
    FSocksControlSock.free;
  inherited;
end;

PROCEDURE TUDPBlockSocket.EnableBroadcast(value: boolean);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_Broadcast;
  d.Enabled := value;
  DelayedOption(d);
end;

FUNCTION TUDPBlockSocket.UdpAssociation: boolean;
VAR
  b: boolean;
begin
  result := true;
  FUsingSocks := false;
  if FSocksIP <> '' then
  begin
    result := false;
    if not Assigned(FSocksControlSock) then
      FSocksControlSock := TTCPBlockSocket.create;
    FSocksControlSock.CloseSocket;
    FSocksControlSock.CreateSocketByName(FSocksIP);
    FSocksControlSock.Connect(FSocksIP, FSocksPort);
    if FSocksControlSock.LastError <> 0 then
      exit;
    // if not assigned local port, assign it!
    if not FBinded then
      Bind(cAnyHost, cAnyPort);
    //open control TCP connection to SOCKS
    FSocksControlSock.FSocksUsername := FSocksUsername;
    FSocksControlSock.FSocksPassword := FSocksPassword;
    b := FSocksControlSock.SocksOpen;
    if b then
      b := FSocksControlSock.SocksRequest(3, GetLocalSinIP, intToStr(GetLocalSinPort));
    if b then
      b := FSocksControlSock.SocksResponse;
    if not b and (FLastError = 0) then
      FLastError := WSANO_RECOVERY;
    FUsingSocks :=FSocksControlSock.UsingSocks;
    FSocksRemoteIP := FSocksControlSock.FSocksResponseIP;
    FSocksRemotePort := FSocksControlSock.FSocksResponsePort;
    result := b and (FLastError = 0);
  end;
end;

FUNCTION TUDPBlockSocket.SendBufferTo(buffer: TMemory; length: integer): integer;
VAR
  SIp: string;
  SPort: integer;
  Buf: ansistring;
begin
  result := 0;
  FUsingSocks := false;
  if (FSocksIP <> '') and (not UdpAssociation) then
    FLastError := WSANO_RECOVERY
  else
  begin
    if FUsingSocks then
    begin
{$IFNDEF CIL}
      Sip := GetRemoteSinIp;
      SPort := GetRemoteSinPort;
      SetRemoteSin(FSocksRemoteIP, FSocksRemotePort);
      setLength(Buf,length);
      move(buffer^, pointer(Buf)^, length);
      Buf := #0 + #0 + #0 + SocksCode(Sip, intToStr(SPort)) + Buf;
      result := inherited SendBufferTo(pointer(Buf), system.length(Buf));
      SetRemoteSin(Sip, intToStr(SPort));
{$ENDIF}
    end
    else
      result := inherited SendBufferTo(buffer, length);
  end;
end;

FUNCTION TUDPBlockSocket.RecvBufferFrom(buffer: TMemory; length: integer): integer;
VAR
  Buf: ansistring;
  x: integer;
begin
  result := inherited RecvBufferFrom(buffer, length);
  if FUsingSocks then
  begin
{$IFNDEF CIL}
    setLength(Buf, result);
    move(buffer^, pointer(Buf)^, result);
    x := SocksDecode(Buf);
    result := result - x + 1;
    Buf := copy(Buf, x, result);
    move(pointer(Buf)^, buffer^, result);
    SetRemoteSin(FSocksResponseIP, FSocksResponsePort);
{$ENDIF}
  end;
end;

{$IFNDEF CIL}
PROCEDURE TUDPBlockSocket.AddMulticast(MCastIP: string);
VAR
  Multicast: TIP_mreq;
  Multicast6: TIPv6_mreq;
  n: integer;
  ip6: Tip6bytes;
begin
  if FIP6Used then
  begin
    ip6 := StrToIp6(MCastIP);
    for n := 0 to 15 do
      Multicast6.ipv6mr_multiaddr.u6_addr8[n] := Ip6[n];
    Multicast6.ipv6mr_interface := 0;
    SockCheck(synsock.SetSockOpt(FSocket, IPPROTO_IPV6, IPV6_JOIN_GROUP,
      PAnsiChar(@Multicast6), sizeOf(Multicast6)));
  end
  else
  begin
    Multicast.imr_multiaddr.S_addr := swapbytes(strtoip(MCastIP));
    Multicast.imr_interface.S_addr := INADDR_ANY;
    SockCheck(synsock.SetSockOpt(FSocket, IPPROTO_IP, IP_ADD_MEMBERSHIP,
      PAnsiChar(@Multicast), sizeOf(Multicast)));
  end;
  ExceptCheck;
end;

PROCEDURE TUDPBlockSocket.DropMulticast(MCastIP: string);
VAR
  Multicast: TIP_mreq;
  Multicast6: TIPv6_mreq;
  n: integer;
  ip6: Tip6bytes;
begin
  if FIP6Used then
  begin
    ip6 := StrToIp6(MCastIP);
    for n := 0 to 15 do
      Multicast6.ipv6mr_multiaddr.u6_addr8[n] := Ip6[n];
    Multicast6.ipv6mr_interface := 0;
    SockCheck(synsock.SetSockOpt(FSocket, IPPROTO_IPV6, IPV6_LEAVE_GROUP,
      PAnsiChar(@Multicast6), sizeOf(Multicast6)));
  end
  else
  begin
    Multicast.imr_multiaddr.S_addr := swapbytes(strtoip(MCastIP));
    Multicast.imr_interface.S_addr := INADDR_ANY;
    SockCheck(synsock.SetSockOpt(FSocket, IPPROTO_IP, IP_DROP_MEMBERSHIP,
      PAnsiChar(@Multicast), sizeOf(Multicast)));
  end;
  ExceptCheck;
end;
{$ENDIF}

PROCEDURE TUDPBlockSocket.SetMulticastTTL(TTL: integer);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_MulticastTTL;
  d.value := TTL;
  DelayedOption(d);
end;

FUNCTION TUDPBlockSocket.GetMulticastTTL:integer;
VAR
  l: integer;
begin
{$IFNDEF CIL}
  l := sizeOf(result);
  if FIP6Used then
    synsock.GetSockOpt(FSocket, IPPROTO_IPV6, IPV6_MULTICAST_HOPS, @result, l)
  else
    synsock.GetSockOpt(FSocket, IPPROTO_IP, IP_MULTICAST_TTL, @result, l);
{$ENDIF}
end;

PROCEDURE TUDPBlockSocket.EnableMulticastLoop(value: boolean);
VAR
  d: TSynaOption;
begin
  d := TSynaOption.create;
  d.Option := SOT_MulticastLoop;
  d.Enabled := value;
  DelayedOption(d);
end;

FUNCTION TUDPBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_DGRAM);
end;

FUNCTION TUDPBlockSocket.GetSocketProtocol: integer;
begin
 result := integer(IPPROTO_UDP);
end;

{======================================================================}
CONSTRUCTOR TTCPBlockSocket.CreateWithSSL(SSLPlugin: TSSLClass);
begin
  inherited create;
  FSSL := SSLPlugin.create(self);
  FHTTPTunnelIP := '';
  FHTTPTunnelPort := '';
  FHTTPTunnel := false;
  FHTTPTunnelRemoteIP := '';
  FHTTPTunnelRemotePort := '';
  FHTTPTunnelUser := '';
  FHTTPTunnelPass := '';
  FHTTPTunnelTimeout := 30000;
end;

CONSTRUCTOR TTCPBlockSocket.create;
begin
  CreateWithSSL(SSLImplementation);
end;

DESTRUCTOR TTCPBlockSocket.destroy;
begin
  inherited destroy;
  FSSL.free;
end;

FUNCTION TTCPBlockSocket.GetErrorDescEx: string;
begin
  result := inherited GetErrorDescEx;
  if (FLastError = WSASYSNOTREADY) and (self.SSL.LastError <> 0) then
  begin
    result := self.SSL.LastErrorDesc;
  end;
end;

PROCEDURE TTCPBlockSocket.CloseSocket;
begin
  if FSSL.SSLEnabled then
    FSSL.Shutdown;
  if (FSocket <> INVALID_SOCKET) and (FLastError = 0) then
  begin
    Synsock.Shutdown(FSocket, 1);
    Purge;
  end;
  inherited CloseSocket;
end;

PROCEDURE TTCPBlockSocket.DoAfterConnect;
begin
  if assigned(OnAfterConnect) then
  begin
    OnAfterConnect(self);
  end;
end;

FUNCTION TTCPBlockSocket.WaitingData: integer;
begin
  result := 0;
  if FSSL.SSLEnabled and (FSocket <> INVALID_SOCKET) then
    result := FSSL.WaitingData;
  if result = 0 then
    result := inherited WaitingData;
end;

PROCEDURE TTCPBlockSocket.Listen;
VAR
  b: boolean;
  Sip,SPort: string;
begin
  if FSocksIP = '' then
  begin
    inherited Listen;
  end
  else
  begin
    Sip := GetLocalSinIP;
    if Sip = cAnyHost then
      Sip := LocalName;
    SPort := intToStr(GetLocalSinPort);
    inherited Connect(FSocksIP, FSocksPort);
    b := SocksOpen;
    if b then
      b := SocksRequest(2, Sip, SPort);
    if b then
      b := SocksResponse;
    if not b and (FLastError = 0) then
      FLastError := WSANO_RECOVERY;
    FSocksLocalIP := FSocksResponseIP;
    if FSocksLocalIP = cAnyHost then
      FSocksLocalIP := FSocksIP;
    FSocksLocalPort := FSocksResponsePort;
    FSocksRemoteIP := '';
    FSocksRemotePort := '';
    ExceptCheck;
    DoStatus(HR_Listen, '');
  end;
end;

FUNCTION TTCPBlockSocket.accept: TSocket;
begin
  if FUsingSocks then
  begin
    if not SocksResponse and (FLastError = 0) then
      FLastError := WSANO_RECOVERY;
    FSocksRemoteIP := FSocksResponseIP;
    FSocksRemotePort := FSocksResponsePort;
    result := FSocket;
    ExceptCheck;
    DoStatus(HR_Accept, '');
  end
  else
  begin
    result := inherited accept;
  end;
end;

PROCEDURE TTCPBlockSocket.Connect(IP, Port: string);
begin
  if FSocksIP <> '' then
    SocksDoConnect(IP, Port)
  else
    if FHTTPTunnelIP <> '' then
      HTTPTunnelDoConnect(IP, Port)
    else
      inherited Connect(IP, Port);
  if FLasterror = 0 then
    DoAfterConnect;
end;

PROCEDURE TTCPBlockSocket.SocksDoConnect(IP, Port: string);
VAR
  b: boolean;
begin
  inherited Connect(FSocksIP, FSocksPort);
  if FLastError = 0 then
  begin
    b := SocksOpen;
    if b then
      b := SocksRequest(1, IP, Port);
    if b then
      b := SocksResponse;
    if not b and (FLastError = 0) then
      FLastError := WSASYSNOTREADY;
    FSocksLocalIP := FSocksResponseIP;
    FSocksLocalPort := FSocksResponsePort;
    FSocksRemoteIP := IP;
    FSocksRemotePort := Port;
  end;
  ExceptCheck;
  DoStatus(HR_Connect, IP + ':' + Port);
end;

PROCEDURE TTCPBlockSocket.HTTPTunnelDoConnect(IP, Port: string);
//bugfixed by Mike Green (mgreen@emixode.com)
VAR
  s: string;
begin
  Port := intToStr(ResolvePort(Port));
  inherited Connect(FHTTPTunnelIP, FHTTPTunnelPort);
  if FLastError <> 0 then
    exit;
  FHTTPTunnel := false;
  if IsIP6(IP) then
    IP := '[' + IP + ']';
  SendString('CONNECT ' + IP + ':' + Port + ' HTTP/1.0' + CRLF);
  if FHTTPTunnelUser <> '' then
  Sendstring('Proxy-Authorization: Basic ' +
    EncodeBase64(FHTTPTunnelUser + ':' + FHTTPTunnelPass) + CRLF);
  SendString(CRLF);
  repeat
    s := RecvTerminated(FHTTPTunnelTimeout, #$0a);
    if FLastError <> 0 then
      break;
    if (pos('HTTP/', s) = 1) and (length(s) > 11) then
      FHTTPTunnel := s[10] = '2';
  until (s = '') or (s = #$0d);
  if (FLasterror = 0) and not FHTTPTunnel then
    FLastError := WSASYSNOTREADY;
  FHTTPTunnelRemoteIP := IP;
  FHTTPTunnelRemotePort := Port;
  ExceptCheck;
end;

PROCEDURE TTCPBlockSocket.SSLDoConnect;
begin
  ResetLastError;
  if not FSSL.Connect then
    FLastError := WSASYSNOTREADY;
  ExceptCheck;
end;

PROCEDURE TTCPBlockSocket.SSLDoShutdown;
begin
  ResetLastError;
  FSSL.BiShutdown;
end;

FUNCTION TTCPBlockSocket.GetLocalSinIP: string;
begin
  if FUsingSocks then
    result := FSocksLocalIP
  else
    result := inherited GetLocalSinIP;
end;

FUNCTION TTCPBlockSocket.GetRemoteSinIP: string;
begin
  if FUsingSocks then
    result := FSocksRemoteIP
  else
    if FHTTPTunnel then
      result := FHTTPTunnelRemoteIP
    else
      result := inherited GetRemoteSinIP;
end;

FUNCTION TTCPBlockSocket.GetLocalSinPort: integer;
begin
  if FUsingSocks then
    result := strToIntDef(FSocksLocalPort, 0)
  else
    result := inherited GetLocalSinPort;
end;

FUNCTION TTCPBlockSocket.GetRemoteSinPort: integer;
begin
  if FUsingSocks then
    result := ResolvePort(FSocksRemotePort)
  else
    if FHTTPTunnel then
      result := strToIntDef(FHTTPTunnelRemotePort, 0)
    else
      result := inherited GetRemoteSinPort;
end;

FUNCTION TTCPBlockSocket.RecvBuffer(buffer: TMemory; len: integer): integer;
begin
  if FSSL.SSLEnabled then
  begin
    result := 0;
    if TestStopFlag then
      exit;
    ResetLastError;
    LimitBandwidth(len, FMaxRecvBandwidth, FNextRecv);
    result := FSSL.RecvBuffer(buffer, len);
    if FSSL.LastError <> 0 then
      FLastError := WSASYSNOTREADY;
    ExceptCheck;
    inc(FRecvCounter, result);
    DoStatus(HR_ReadCount, intToStr(result));
    DoMonitor(false, buffer, result);
    DoReadFilter(buffer, result);
  end
  else
    result := inherited RecvBuffer(buffer, len);
end;

FUNCTION TTCPBlockSocket.SendBuffer(buffer: TMemory; length: integer): integer;
VAR
  x, y: integer;
  l, r: integer;
{$IFNDEF CIL}
  p: pointer;
{$ENDIF}
begin
  if FSSL.SSLEnabled then
  begin
    result := 0;
    if TestStopFlag then
      exit;
    ResetLastError;
    DoMonitor(true, buffer, length);
{$IFDEF CIL}
    result := FSSL.SendBuffer(buffer, length);
    if FSSL.LastError <> 0 then
      FLastError := WSASYSNOTREADY;
    inc(FSendCounter, result);
    DoStatus(HR_WriteCount, intToStr(result));
{$ELSE}
    l := length;
    x := 0;
    while x < l do
    begin
      y := l - x;
      if y > FSendMaxChunk then
        y := FSendMaxChunk;
      if y > 0 then
      begin
        LimitBandwidth(y, FMaxSendBandwidth, FNextsend);
        p := IncPoint(buffer, x);
        r := FSSL.SendBuffer(p, y);
        if FSSL.LastError <> 0 then
          FLastError := WSASYSNOTREADY;
        if Flasterror <> 0 then
          break;
        inc(x, r);
        inc(result, r);
        inc(FSendCounter, r);
        DoStatus(HR_WriteCount, intToStr(r));
      end
      else
        break;
    end;
{$ENDIF}
    ExceptCheck;
  end
  else
    result := inherited SendBuffer(buffer, length);
end;

FUNCTION TTCPBlockSocket.SSLAcceptConnection: boolean;
begin
  ResetLastError;
  if not FSSL.accept then
    FLastError := WSASYSNOTREADY;
  ExceptCheck;
  result := FLastError = 0;
end;

FUNCTION TTCPBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_STREAM);
end;

FUNCTION TTCPBlockSocket.GetSocketProtocol: integer;
begin
  result := integer(IPPROTO_TCP);
end;

{======================================================================}

FUNCTION TICMPBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_RAW);
end;

FUNCTION TICMPBlockSocket.GetSocketProtocol: integer;
begin
  if FIP6Used then
    result := integer(IPPROTO_ICMPV6)
  else
    result := integer(IPPROTO_ICMP);
end;

{======================================================================}

FUNCTION TRAWBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_RAW);
end;

FUNCTION TRAWBlockSocket.GetSocketProtocol: integer;
begin
  result := integer(IPPROTO_RAW);
end;

{======================================================================}

FUNCTION TPGMmessageBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_RDM);
end;

FUNCTION TPGMmessageBlockSocket.GetSocketProtocol: integer;
begin
  result := integer(IPPROTO_RM);
end;

{======================================================================}

FUNCTION TPGMstreamBlockSocket.GetSocketType: integer;
begin
  result := integer(SOCK_STREAM);
end;

FUNCTION TPGMstreamBlockSocket.GetSocketProtocol: integer;
begin
  result := integer(IPPROTO_RM);
end;

{======================================================================}

CONSTRUCTOR TSynaClient.create;
begin
  inherited create;
  FIPInterface := cAnyHost;
  FTargetHost := cLocalhost;
  FTargetPort := cAnyPort;
  FTimeout := 5000;
  FUsername := '';
  FPassword := '';
end;

{======================================================================}

CONSTRUCTOR TCustomSSL.create(CONST value: TTCPBlockSocket);
begin
  inherited create;
  FSocket := value;
  FSSLEnabled := false;
  FUsername := '';
  FPassword := '';
  FLastError := 0;
  FLastErrorDesc := '';
  FVerifyCert := false;
  FSSLType := LT_all;
  FKeyPassword := '';
  FCiphers := '';
  FCertificateFile := '';
  FPrivateKeyFile := '';
  FCertCAFile := '';
  FCertCA := '';
  FTrustCertificate := '';
  FTrustCertificateFile := '';
  FCertificate := '';
  FPrivateKey := '';
  FPFX := '';
  FPFXfile := '';
  FSSHChannelType := '';
  FSSHChannelArg1 := '';
  FSSHChannelArg2 := '';
  FCertComplianceLevel := -1; //default
  FSNIHost := '';
end;

PROCEDURE TCustomSSL.assign(CONST value: TCustomSSL);
begin
  FUsername := value.Username;
  FPassword := value.Password;
  FVerifyCert := value.VerifyCert;
  FSSLType := value.SSLType;
  FKeyPassword := value.KeyPassword;
  FCiphers := value.Ciphers;
  FCertificateFile := value.CertificateFile;
  FPrivateKeyFile := value.PrivateKeyFile;
  FCertCAFile := value.CertCAFile;
  FCertCA := value.CertCA;
  FTrustCertificate := value.TrustCertificate;
  FTrustCertificateFile := value.TrustCertificateFile;
  FCertificate := value.Certificate;
  FPrivateKey := value.PrivateKey;
  FPFX := value.PFX;
  FPFXfile := value.PFXfile;
  FCertComplianceLevel := value.CertComplianceLevel;
  FSNIHost := value.FSNIHost;
end;

PROCEDURE TCustomSSL.ReturnError;
begin
  FLastError := -1;
  FLastErrorDesc := 'SSL/TLS support is not compiled!';
end;

FUNCTION TCustomSSL.LibVersion: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.LibName: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.CreateSelfSignedCert(Host: string): boolean;
begin
  result := false;
end;

FUNCTION TCustomSSL.Connect: boolean;
begin
  ReturnError;
  result := false;
end;

FUNCTION TCustomSSL.accept: boolean;
begin
  ReturnError;
  result := false;
end;

FUNCTION TCustomSSL.Shutdown: boolean;
begin
  ReturnError;
  result := false;
end;

FUNCTION TCustomSSL.BiShutdown: boolean;
begin
  ReturnError;
  result := false;
end;

FUNCTION TCustomSSL.SendBuffer(buffer: TMemory; len: integer): integer;
begin
  ReturnError;
  result := integer(SOCKET_ERROR);
end;

PROCEDURE TCustomSSL.SetCertCAFile(CONST value: string);
begin
  FCertCAFile := value;
end;

FUNCTION TCustomSSL.RecvBuffer(buffer: TMemory; len: integer): integer;
begin
  ReturnError;
  result := integer(SOCKET_ERROR);
end;

FUNCTION TCustomSSL.WaitingData: integer;
begin
  ReturnError;
  result := 0;
end;

FUNCTION TCustomSSL.GetSSLVersion: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetPeerSubject: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetPeerSerialNo: integer;
begin
  result := -1;
end;

FUNCTION TCustomSSL.GetPeerName: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetPeerNameHash: Cardinal;
begin
  result := 0;
end;

FUNCTION TCustomSSL.GetPeerIssuer: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetPeerFingerprint: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetCertInfo: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetCipherName: string;
begin
  result := '';
end;

FUNCTION TCustomSSL.GetCipherBits: integer;
begin
  result := 0;
end;

FUNCTION TCustomSSL.GetCipherAlgBits: integer;
begin
  result := 0;
end;

FUNCTION TCustomSSL.GetVerifyCert: integer;
begin
  result := 1;
end;

FUNCTION TCustomSSL.DoVerifyCert:boolean;
begin
  if assigned(OnVerifyCert) then
  begin
    result:=OnVerifyCert(self);
  end
  else
    result:=true;
end;


{======================================================================}

FUNCTION TSSLNone.LibVersion: string;
begin
  result := 'Without SSL support';
end;

FUNCTION TSSLNone.LibName: string;
begin
  result := 'ssl_none';
end;

{======================================================================}

INITIALIZATION
begin
{$IFDEF ONCEWINSOCK}
  if not InitSocketInterface(DLLStackName) then
  begin
    e := ESynapseError.create('Error loading Socket interface (' + DLLStackName + ')!');
    e.ErrorCode := 0;
    e.errorMessage := 'Error loading Socket interface (' + DLLStackName + ')!';
    raise e;
  end;
  synsock.WSAStartup(WinsockLevel, WsaDataOnce);
{$ENDIF}
end;

FINALIZATION
begin
{$IFDEF ONCEWINSOCK}
  synsock.WSACleanup;
  DestroySocketInterface;
{$ENDIF}
end;

end.
