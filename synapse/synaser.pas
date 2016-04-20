{==============================================================================|
| project : Ararat Synapse                                       | 007.005.002 |
|==============================================================================|
| content: Serial port support                                                 |
|==============================================================================|
| Copyright (c)2001-2011, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2001-2011.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|  (c)2002, Hans-Georg Joepgen (cpom Comport Ownership Manager and bugfixes)   |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{: @abstract(Serial port communication library)
This UNIT contains a class that implements serial port communication
 for windows, Linux, unix or MacOSx. This class provides numerous methods with
 same name and functionality as methods of the Ararat Synapse TCP/IP library.

the following is a small example how establish a connection by modem (in this
case with my USB modem):
@longcode(#
  ser:=TBlockSerial.create;
  try
    ser.Connect('COM3');
    ser.config(460800,8,'N',0,false,true);
    ser.ATCommand('AT');
    if (ser.LastError <> 0) or (not ser.ATResult) then
      exit;
    ser.ATConnect('ATDT+420971200111');
    if (ser.LastError <> 0) or (not ser.ATResult) then
      exit;
    // you are now connected to a modem at +420971200111
    // you can transmit or receive data now
  finally
    ser.free;
  end;
#)
}

//old Delphi does not have MSWINDOWS define.
{$IFDEF WIN32}
  {$IFNDEF MSWINDOWS}
    {$DEFINE MSWINDOWS}
  {$ENDIF}
{$ENDIF}

//Kylix does not known UNIX define
{$IFDEF LINUX}
  {$IFNDEF UNIX}
    {$DEFINE UNIX}
  {$ENDIF}
{$ENDIF}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$IFDEF MSWINDOWS}
    {$ASMMODE intel}
  {$ENDIF}
  {define working mode w/o LIBC for fpc}
  {$DEFINE NO_LIBC}
{$ENDIF}
{$Q-}
{$H+}
{$M+}

UNIT synaser;

INTERFACE

USES
{$IFNDEF MSWINDOWS}
  {$IFNDEF NO_LIBC}
  Libc,
  KernelIoctl,
  {$ELSE}
  termio, baseunix, unix,
  {$ENDIF}
  {$IFNDEF FPC}
  types,
  {$ENDIF}
{$ELSE}
  windows, registry,
  {$IFDEF FPC}
  winver,
  {$ENDIF}
{$ENDIF}
  synafpc,
  Classes, sysutils, synautil;

CONST
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
  cSerialChunk = 8192;

  LockfileDirectory = '/var/lock'; {HGJ}
  PortIsClosed = -1;               {HGJ}
  ErrAlreadyOwned = 9991;          {HGJ}
  ErrAlreadyInUse = 9992;          {HGJ}
  ErrWrongParameter = 9993;        {HGJ}
  ErrPortNotOpen = 9994;           {HGJ}
  ErrNoDeviceAnswer =  9995;       {HGJ}
  ErrMaxBuffer = 9996;
  ErrTimeout = 9997;
  ErrNotRead = 9998;
  ErrFrame = 9999;
  ErrOverrun = 10000;
  ErrRxOver = 10001;
  ErrRxParity = 10002;
  ErrTxFull = 10003;

  dcb_Binary = $00000001;
  dcb_ParityCheck = $00000002;
  dcb_OutxCtsFlow = $00000004;
  dcb_OutxDsrFlow = $00000008;
  dcb_DtrControlMask = $00000030;
  dcb_DtrControlDisable = $00000000;
  dcb_DtrControlEnable = $00000010;
  dcb_DtrControlHandshake = $00000020;
  dcb_DsrSensivity = $00000040;
  dcb_TXContinueOnXoff = $00000080;
  dcb_OutX = $00000100;
  dcb_InX = $00000200;
  dcb_ErrorChar = $00000400;
  dcb_NullStrip = $00000800;
  dcb_RtsControlMask = $00003000;
  dcb_RtsControlDisable = $00000000;
  dcb_RtsControlEnable = $00001000;
  dcb_RtsControlHandshake = $00002000;
  dcb_RtsControlToggle = $00003000;
  dcb_AbortOnError = $00004000;
  dcb_Reserveds = $FFFF8000;

  {:stopbit value for 1 stopbit}
  SB1 = 0;
  {:stopbit value for 1.5 stopbit}
  SB1andHalf = 1;
  {:stopbit value for 2 stopbits}
  SB2 = 2;

{$IFNDEF MSWINDOWS}
CONST
  INVALID_HANDLE_VALUE = THandle(-1);
  CS7fix = $0000020;

TYPE
  TDCB = record
    DCBlength: dword;
    BaudRate: dword;
    Flags: longint;
    wReserved: word;
    XonLim: word;
    XoffLim: word;
    ByteSize: byte;
    Parity: byte;
    StopBits: byte;
    XonChar: char;
    XoffChar: char;
    ErrorChar: char;
    EofChar: char;
    EvtChar: char;
    wReserved1: word;
  end;
  PDCB = ^TDCB;

CONST
{$IFDEF UNIX}
  {$IFDEF DARWIN}
  MaxRates = 18;  //MAC
  {$ELSE}
   MaxRates = 30; //UNIX
  {$ENDIF}
{$ELSE}
  MaxRates = 19;  //WIN
{$ENDIF}
  Rates: array[0..MaxRates, 0..1] of Cardinal =
  (
    (0, B0),
    (50, B50),
    (75, B75),
    (110, B110),
    (134, B134),
    (150, B150),
    (200, B200),
    (300, B300),
    (600, B600),
    (1200, B1200),
    (1800, B1800),
    (2400, B2400),
    (4800, B4800),
    (9600, B9600),
    (19200, B19200),
    (38400, B38400),
    (57600, B57600),
    (115200, B115200),
    (230400, B230400)
{$IFNDEF DARWIN}
    ,(460800, B460800)
  {$IFDEF UNIX}
    ,(500000, B500000),
    (576000, B576000),
    (921600, B921600),
    (1000000, B1000000),
    (1152000, B1152000),
    (1500000, B1500000),
    (2000000, B2000000),
    (2500000, B2500000),
    (3000000, B3000000),
    (3500000, B3500000),
    (4000000, B4000000)
  {$ENDIF}
{$ENDIF}
    );
{$ENDIF}

{$IFDEF DARWIN}
CONST // From fcntl.h
  O_SYNC = $0080;  { synchronous writes }
{$ENDIF}

CONST
  sOK = 0;
  sErr = integer(-1);

TYPE

  {:Possible status event types for @link(THookSerialStatus)}
  THookSerialReason = (
    HR_SerialClose,
    HR_Connect,
    HR_CanRead,
    HR_CanWrite,
    HR_ReadCount,
    HR_WriteCount,
    HR_Wait
    );

  {:procedural prototype for status event hooking}
  THookSerialStatus = PROCEDURE(Sender: TObject; Reason: THookSerialReason;
    CONST value: string) of object;

  {:@abstract(Exception type for SynaSer errors)}
  ESynaSerError = class(Exception)
  public
    ErrorCode: integer;
    errorMessage: string;
  end;

  {:@abstract(Main class implementing all communication routines)}
  TBlockSerial = class(TObject)
  protected
    FOnStatus: THookSerialStatus;
    Fhandle: THandle;
    FTag: integer;
    FDevice: string;
    FLastError: integer;
    FLastErrorDesc: string;
    FBuffer: ansistring;
    FRaiseExcept: boolean;
    FRecvBuffer: integer;
    FSendBuffer: integer;
    FModemWord: integer;
    FRTSToggle: boolean;
    FDeadlockTimeout: integer;
    FInstanceActive: boolean;      {HGJ}
    FTestDSR: boolean;
    FTestCTS: boolean;
    FLastCR: boolean;
    FLastLF: boolean;
    FMaxLineLength: integer;
    FLinuxLock: boolean;
    FMaxSendBandwidth: integer;
    FNextSend: Longword;
    FMaxRecvBandwidth: integer;
    FNextRecv: Longword;
    FConvertLineEnd: boolean;
    FATResult: boolean;
    FAtTimeout: integer;
    FInterPacketTimeout: boolean;
    FComNr: integer;
{$IFDEF MSWINDOWS}
    FPortAddr: word;
    FUNCTION CanEvent(Event: dword; Timeout: integer): boolean;
    PROCEDURE DecodeCommError(Error: dword); virtual;
    FUNCTION GetPortAddr: word;  virtual;
    FUNCTION ReadTxEmpty(PortAddr: word): boolean; virtual;
{$ENDIF}
    PROCEDURE SetSizeRecvBuffer(size: integer); virtual;
    FUNCTION GetDSR: boolean; virtual;
    PROCEDURE SetDTRF(value: boolean); virtual;
    FUNCTION GetCTS: boolean; virtual;
    PROCEDURE SetRTSF(value: boolean); virtual;
    FUNCTION GetCarrier: boolean; virtual;
    FUNCTION GetRing: boolean; virtual;
    PROCEDURE DoStatus(Reason: THookSerialReason; CONST value: string); virtual;
    PROCEDURE GetComNr(value: string); virtual;
    FUNCTION PreTestFailing: boolean; virtual;{HGJ}
    FUNCTION TestCtrlLine: boolean; virtual;
{$IFDEF UNIX}
    PROCEDURE DcbToTermios(CONST dcb: TDCB; VAR term: termios); virtual;
    PROCEDURE TermiosToDcb(CONST term: termios; VAR dcb: TDCB); virtual;
    FUNCTION ReadLockfile: integer; virtual;
    FUNCTION LockfileName: string; virtual;
    PROCEDURE CreateLockfile(PidNr: integer); virtual;
{$ENDIF}
    PROCEDURE LimitBandwidth(length: integer; MaxB: integer; VAR next: Longword); virtual;
    PROCEDURE SetBandwidth(value: integer); virtual;
  public
    {: data Control Block with communication parameters. Usable only when you
     need to call API directly.}
    DCB: Tdcb;
{$IFDEF UNIX}
    TermiosStruc: termios;
{$ENDIF}
    {:Object constructor.}
    CONSTRUCTOR create;
    {:Object destructor.}
    DESTRUCTOR destroy; override;

    {:Returns a string containing the version number of the library.}
    class FUNCTION GetVersion: string; virtual;

    {:Destroy handle in use. It close connection to serial port.}
    PROCEDURE CloseSocket; virtual;

    {:Reconfigure communication parameters on the fly. You must be connected to
     port before!
     @param(baud define connection speed. Baud rate can be from 50 to 4000000
      bits per second. (it depends on your Hardware!))
     @param(bits Number of bits in communication.)
     @param(parity define communication parity (N - none, O - odd, E - Even, M - Mark or S - Space).)
     @param(stop define number of stopbits. use constants @link(SB1),
      @link(SB1andHalf) and @link(SB2).)
     @param(softflow Enable XON/XOFF handshake.)
     @param(hardflow Enable CTS/RTS handshake.)}
    PROCEDURE Config(baud, bits: integer; parity: char; stop: integer;
      softflow, hardflow: boolean); virtual;

    {:Connects to the port indicated by comport. Comport can be used in Windows
     style (COM2), or in Linux style (/dev/ttyS1). When you use windows style
     in Linux, then it will be converted to Linux name. and vice versa! However
     you can specify any device name! (other device names then standart is not
     converted!)

     After successfull connection the DTR signal is set (if you not set Hardware
     handshake, then the RTS signal is set, too!)

     Connection parameters is predefined by your system configuration. if you
     need use another parameters, then you can use Config method after.
     Notes:

      - Remember, the commonly used serial Laplink cable does not support
       Hardware handshake.

      - Before setting any handshake you must be sure that it is supported by
       your Hardware.

      - Some serial devices are slow. in some cases you must wait up to a few
       seconds after connection for the device to respond.

      - when you connect to a modem device, then is best to test it by an empty
       AT command. (call ATCommand('AT'))}
    PROCEDURE Connect(comport: string); virtual;

    {:Set communication parameters from the DCB structure (the DCB structure is
     simulated under Linux).}
    PROCEDURE SetCommState; virtual;

    {:Read communication parameters into the DCB structure (DCB structure is
     simulated under Linux).}
    PROCEDURE GetCommState; virtual;

    {:Sends Length bytes of data from Buffer through the connected port.}
    FUNCTION SendBuffer(buffer: pointer; length: integer): integer; virtual;

    {:One data BYTE is sent.}
    PROCEDURE SendByte(data: byte); virtual;

    {:Send the string in the data parameter. No terminator is appended by this
     method. if you need to send a string with CR/LF terminator, you must append
     the CR/LF characters to the data string!

     Since no terminator is appended, you can use this FUNCTION for sending
     binary data too.}
    PROCEDURE SendString(data: ansistring); virtual;

    {:send four bytes as integer.}
    PROCEDURE SendInteger(data: integer); virtual;

    {:send data as one block. Each block begins with integer value with Length
     of block.}
    PROCEDURE SendBlock(CONST data: ansistring); virtual;

    {:send content of stream from current position}
    PROCEDURE SendStreamRaw(CONST Stream: TStream); virtual;

    {:send content of stream as block. see @link(SendBlock)}
    PROCEDURE SendStream(CONST Stream: TStream); virtual;

    {:send content of stream as block, but this is compatioble with Indy library.
     (it have swapped lenght of block). See @link(SendStream)}
    PROCEDURE SendStreamIndy(CONST Stream: TStream); virtual;

    {:Waits until the allocated buffer is filled by received data. Returns number
     of data bytes received, which equals to the length value under normal
     operation. if it is not equal, the communication channel is possibly broken.

     This method not using any internal buffering, like all others receiving
     methods. You cannot freely combine this method with all others receiving
     methods!}
    FUNCTION RecvBuffer(buffer: pointer; length: integer): integer; virtual;

    {:Method waits until data is received. If no data is received within
     the Timeout (in Milliseconds) period, @link(LastError) is set to
     @link(ErrTimeout). This method is used to read any amount of data
     (e. g. 1MB), and may be freely combined with all receviving methods what
     have Timeout parameter, like the @link(RecvString), @link(RecvByte) or
     @link(RecvTerminated) methods.}
    FUNCTION RecvBufferEx(buffer: pointer; length: integer; timeout: integer): integer; virtual;

    {:It is like recvBufferEx, but data is readed to dynamicly allocated binary
     string.}
    FUNCTION RecvBufferStr(length: integer; Timeout: integer): ansistring; virtual;

    {:Read all available data and return it in the function result string. This
     FUNCTION may be combined with @link(RecvString), @link(RecvByte) or related
     methods.}
    FUNCTION RecvPacket(Timeout: integer): ansistring; virtual;

    {:Waits until one data byte is received which is returned as the function
     result. if no data is received within the Timeout (in Milliseconds) period,
     @link(LastError) is set to @link(ErrTimeout).}
    FUNCTION RecvByte(timeout: integer): byte; virtual;

    {:This method waits until a terminated data string is received. This string
     is terminated by the Terminator string. the resulting string is returned
     without this termination string! if no data is received within the Timeout
     (in Milliseconds) period, @link(LastError) is set to @link(ErrTimeout).}
    FUNCTION RecvTerminated(Timeout: integer; CONST Terminator: ansistring): ansistring; virtual;

    {:This method waits until a terminated data string is received. The string
     is terminated by a CR/LF sequence. the resulting string is returned without
     the terminator (CR/LF)! if no data is received within the Timeout (in
     Milliseconds) period, @link(LastError) is set to @link(ErrTimeout).

     if @link(ConvertLineEnd) is used, then the CR/LF sequence may not be exactly
     CR/LF. See the description of @link(ConvertLineEnd).

     This method serves for line protocol IMPLEMENTATION and USES its own
     buffers to maximize performance. Therefore do not use this method with the
     @link(RecvBuffer) method to receive data as it may cause data loss.}
    FUNCTION Recvstring(timeout: integer): ansistring; virtual;

    {:Waits until four data bytes are received which is returned as the function
     integer result. if no data is received within the Timeout (in Milliseconds) period,
     @link(LastError) is set to @link(ErrTimeout).}
    FUNCTION RecvInteger(Timeout: integer): integer; virtual;

    {:Waits until one data block is received. See @link(sendblock). If no data
     is received within the Timeout (in Milliseconds) period, @link(LastError)
     is set to @link(ErrTimeout).}
    FUNCTION RecvBlock(Timeout: integer): ansistring; virtual;

    {:Receive all data to stream, until some error occured. (for example timeout)}
    PROCEDURE RecvStreamRaw(CONST Stream: TStream; Timeout: integer); virtual;

    {:receive requested count of bytes to stream}
    PROCEDURE RecvStreamSize(CONST Stream: TStream; Timeout: integer; size: integer); virtual;

    {:receive block of data to stream. (Data can be sended by @link(sendstream)}
    PROCEDURE RecvStream(CONST Stream: TStream; Timeout: integer); virtual;

    {:receive block of data to stream. (Data can be sended by @link(sendstreamIndy)}
    PROCEDURE RecvStreamIndy(CONST Stream: TStream; Timeout: integer); virtual;

    {:Returns the number of received bytes waiting for reading. 0 is returned
     when there is no data waiting.}
    FUNCTION WaitingData: integer; virtual;

    {:Same as @link(WaitingData), but in respect to data in the internal
     @link(LineBuffer).}
    FUNCTION WaitingDataEx: integer; virtual;

    {:Returns the number of bytes waiting to be sent in the output buffer.
     0 is returned when the output buffer is empty.}
    FUNCTION SendingData: integer; virtual;

    {:Enable or disable RTS driven communication (half-duplex). It can be used
     to communicate with RS485 converters, or other special equipment. if you
     enable this feature, the system automatically Controls the RTS signal.

     Notes:

     - on windows NT (or higher) ir RTS signal driven by system driver.

     - on Win9x family is used special code for waiting until last byte is
      sended from your UART.

     - on Linux you must have kernel 2.1 or higher!}
    PROCEDURE EnableRTSToggle(value: boolean); virtual;

    {:Waits until all data to is sent and buffers are emptied.
     Warning: on windows systems is this method returns when all buffers are
     flushed to the serial port controller, before the last byte is sent!}
    PROCEDURE flush; virtual;

    {:Unconditionally empty all buffers. It is good when you need to interrupt
     communication and for cleanups.}
    PROCEDURE Purge; virtual;

    {:Returns @True, if you can from read any data from the port. Status is
     tested for a period of time given by the Timeout parameter (in Milliseconds).
     if the value of the Timeout parameter is 0, the status is tested only once
     and the FUNCTION returns immediately. if the value of the Timeout parameter
     is set to -1, the FUNCTION returns only after it detects data on the port
     (this may cause the Process to hang).}
    FUNCTION CanRead(Timeout: integer): boolean; virtual;

    {:Returns @True, if you can write any data to the port (this function is not
     sending the contents of the buffer). Status is tested for a period of time
     given by the Timeout parameter (in Milliseconds). if the value of
     the Timeout parameter is 0, the status is tested only once and the FUNCTION
     returns immediately. if the value of the  Timeout parameter is set to -1,
     the FUNCTION returns only after it detects that it can write data to
     the port (this may cause the Process to hang).}
    FUNCTION CanWrite(Timeout: integer): boolean; virtual;

    {:Same as @link(CanRead), but the test is against data in the internal
    @link(LineBuffer) too.}
    FUNCTION CanReadEx(Timeout: integer): boolean; virtual;

    {:Returns the status word of the modem. Decoding the status word could yield
     the status of carrier detect signaland other signals. This method is used
     internally by the modem status reading properties. You usually do not need
     to call this method directly.}
    FUNCTION ModemStatus: integer; virtual;

    {:Send a break signal to the communication device for Duration milliseconds.}
    PROCEDURE SetBreak(Duration: integer); virtual;

    {:This function is designed to send AT commands to the modem. The AT command
     is sent in the value parameter and the response is returned in the FUNCTION
     return value (may contain multiple lines!).
     if the AT command is processed successfully (modem returns ok), then the
     @link(ATResult) PROPERTY is set to true.

     This FUNCTION is designed only for AT commands that return ok or ERROR
     response! to call connection commands the @link(ATConnect) method.
     Remember, when you connect to a modem device, it is in AT command mode.
     now you can send AT commands to the modem. if you need to transfer data to
     the modem on the other side of the line, you must first switch to data mode
     using the @link(ATConnect) method.}
    FUNCTION ATCommand(value: ansistring): ansistring; virtual;

    {:This function is used to send connect type AT commands to the modem. It is
     for commands to switch to connected state. (ATD, ATA, ATO,...)
     it sends the AT command in the value parameter and returns the modem's
     response (may be multiple lines - usually with connection parameters info).
     if the AT command is processed successfully (the modem returns CONNECT),
     then the ATResult PROPERTY is set to @true.

     This FUNCTION is designed only for AT commands which respond by CONNECT,
     BUSY, no DIALTONE no CARRIER or ERROR. for other AT commands use the
     @link(ATCommand) method.

     the connect timeout is 90*@link(ATTimeout). if this command is successful
     (@link(ATresult) is @true), then the modem is in data state. When you now
     send or receive some data, it is not to or from your modem, but from the
     modem on other side of the line. now you can transfer your data.
     if the connection attempt failed (@link(ATResult) is @false), then the
     modem is still in AT command mode.}
    FUNCTION ATConnect(value: ansistring): ansistring; virtual;

    {:If you "manually" call API functions, forward their return code in
     the SerialResult parameter to this FUNCTION, which evaluates it and sets
     @link(LastError) and @link(LastErrorDesc).}
    FUNCTION SerialCheck(SerialResult: integer): integer; virtual;

    {:If @link(Lasterror) is not 0 and exceptions are enabled, then this procedure
     raises an Exception. This method is used internally. You may need it only
     in special cases.}
    PROCEDURE ExceptCheck; virtual;

    {:Set Synaser to error state with ErrNumber code. Usually used by internal
     routines.}
    PROCEDURE SetSynaError(ErrNumber: integer); virtual;

    {:Raise Synaser error with ErrNumber code. Usually used by internal routines.}
    PROCEDURE RaiseSynaError(ErrNumber: integer); virtual;
{$IFDEF UNIX}
    FUNCTION  cpomComportAccessible: boolean; virtual;{HGJ}
    PROCEDURE cpomReleaseComport; virtual; {HGJ}
{$ENDIF}
    {:True device name of currently used port}
    PROPERTY Device: string read FDevice;

    {:Error code of last operation. Value is defined by the host operating
     system, but value 0 is always ok.}
    PROPERTY LastError: integer read FLastError;

    {:Human readable description of LastError code.}
    PROPERTY LastErrorDesc: string read FLastErrorDesc;

    {:Indicates if the last @link(ATCommand) or @link(ATConnect) method was successful}
    PROPERTY ATResult: boolean read FATResult;

    {:Read the value of the RTS signal.}
    PROPERTY RTS: boolean write SetRTSF;

    {:Indicates the presence of the CTS signal}
    PROPERTY CTS: boolean read GetCTS;

    {:Use this property to set the value of the DTR signal.}
    PROPERTY DTR: boolean write SetDTRF;

    {:Exposes the status of the DSR signal.}
    PROPERTY DSR: boolean read GetDSR;

    {:Indicates the presence of the Carrier signal}
    PROPERTY Carrier: boolean read GetCarrier;

    {:Reflects the status of the Ring signal.}
    PROPERTY Ring: boolean read GetRing;

    {:indicates if this instance of SynaSer is active. (Connected to some port)}
    PROPERTY InstanceActive: boolean read FInstanceActive; {HGJ}

    {:Defines maximum bandwidth for all sending operations in bytes per second.
     if this value is set to 0 (default), bandwidth limitation is not used.}
    PROPERTY MaxSendBandwidth: integer read FMaxSendBandwidth write FMaxSendBandwidth;

    {:Defines maximum bandwidth for all receiving operations in bytes per second.
     if this value is set to 0 (default), bandwidth limitation is not used.}
    PROPERTY MaxRecvBandwidth: integer read FMaxRecvBandwidth write FMaxRecvBandwidth;

    {:Defines maximum bandwidth for all sending and receiving operations
     in bytes per second. if this value is set to 0 (default), bandwidth
     limitation is not used.}
    PROPERTY MaxBandwidth: integer write SetBandwidth;

    {:Size of the Windows internal receive buffer. Default value is usually
     4096 bytes. Note: valid only in windows versions!}
    PROPERTY SizeRecvBuffer: integer read FRecvBuffer write SetSizeRecvBuffer;
  Published
    {:Returns the descriptive text associated with ErrorCode. You need this
     method only in special cases. description of LastError is now accessible
     through the LastErrorDesc PROPERTY.}
    class FUNCTION GetErrorDesc(ErrorCode: integer): string;

    {:Freely usable property}
    PROPERTY Tag: integer read FTag write FTag;

    {:Contains the handle of the open communication port.
    You may need this value to directly call communication functions outside
    SynaSer.}
    PROPERTY handle: THandle read Fhandle write FHandle;

    {:Internally used read buffer.}
    PROPERTY LineBuffer: ansistring read FBuffer write FBuffer;

    {:If @true, communication errors raise exceptions. If @false (default), only
     the @link(LastError) value is set.}
    PROPERTY RaiseExcept: boolean read FRaiseExcept write FRaiseExcept;

    {:This event is triggered when the communication status changes. It can be
     used to monitor communication status.}
    PROPERTY OnStatus: THookSerialStatus read FOnStatus write FOnStatus;

    {:If you set this property to @true, then the value of the DSR signal
     is tested before every data transfer. it can be used to detect the presence
     of a communications device.}
    PROPERTY TestDSR: boolean read FTestDSR write FTestDSR;

    {:If you set this property to @true, then the value of the CTS signal
     is tested before every data transfer. it can be used to detect the presence
     of a communications device. Warning: This PROPERTY cannot be used if you
     need Hardware handshake!}
    PROPERTY TestCTS: boolean read FTestCTS write FTestCTS;

    {:Use this property you to limit the maximum size of LineBuffer
     (as a protection against unlimited memory allocation for LineBuffer).
     default value is 0 - no limit.}
    PROPERTY maxLineLength: integer read FMaxLineLength write FMaxLineLength;

    {:This timeout value is used as deadlock protection when trying to send data
     to (or receive data from) a device that stopped communicating during data
     transmission (e.g. by physically disconnecting the device).
     the timeout value is in Milliseconds. the default value is 30,000 (30 seconds).}
    PROPERTY DeadlockTimeout: integer read FDeadlockTimeout write FDeadlockTimeout;

    {:If set to @true (default value), port locking is enabled (under Linux only).
     WARNING: to use this feature, the application must run by a user with full
     permission to the /VAR/lock directory!}
    PROPERTY LinuxLock: boolean read FLinuxLock write FLinuxLock;

    {:Indicates if non-standard line terminators should be converted to a CR/LF pair
     (standard dos line terminator). if @true, line terminators CR, single LF
     or LF/CR are converted to CR/LF. Defaults to @false.
     This PROPERTY has effect only on the behavior of the RecvString method.}
    PROPERTY ConvertLineEnd: boolean read FConvertLineEnd write FConvertLineEnd;

    {:Timeout for AT modem based operations}
    PROPERTY AtTimeout: integer read FAtTimeout write FAtTimeout;

    {:If @true (default), then all timeouts is timeout between two characters.
     if @false, then timeout is overall for whoole reading operation.}
    PROPERTY InterPacketTimeout: boolean read FInterPacketTimeout write FInterPacketTimeout;
  end;

{:Returns list of existing computer serial ports. Working properly only in Windows!}
FUNCTION GetSerialPortNames: string;

IMPLEMENTATION

CONSTRUCTOR TBlockSerial.create;
begin
  inherited create;
  FRaiseExcept := false;
  FHandle := INVALID_HANDLE_VALUE;
  FDevice := '';
  FComNr:= PortIsClosed;               {HGJ}
  FInstanceActive:= false;             {HGJ}
  Fbuffer := '';
  FRTSToggle := false;
  FMaxLineLength := 0;
  FTestDSR := false;
  FTestCTS := false;
  FDeadlockTimeout := 30000;
  FLinuxLock := true;
  FMaxSendBandwidth := 0;
  FNextSend := 0;
  FMaxRecvBandwidth := 0;
  FNextRecv := 0;
  FConvertLineEnd := false;
  SetSynaError(sOK);
  FRecvBuffer := 4096;
  FLastCR := false;
  FLastLF := false;
  FAtTimeout := 1000;
  FInterPacketTimeout := true;
end;

DESTRUCTOR TBlockSerial.destroy;
begin
  CloseSocket;
  inherited destroy;
end;

class FUNCTION TBlockSerial.GetVersion: string;
begin
	result := 'SynaSer 7.5.0';
end;

PROCEDURE TBlockSerial.CloseSocket;
begin
  if Fhandle <> INVALID_HANDLE_VALUE then
  begin
    Purge;
    RTS := false;
    DTR := false;
    FileClose(FHandle);
  end;
  if InstanceActive then
  begin
    {$IFDEF UNIX}
    if FLinuxLock then
      cpomReleaseComport;
    {$ENDIF}
    FInstanceActive:= false
  end;
  Fhandle := INVALID_HANDLE_VALUE;
  FComNr:= PortIsClosed;
  SetSynaError(sOK);
  DoStatus(HR_SerialClose, FDevice);
end;

{$IFDEF MSWINDOWS}
FUNCTION TBlockSerial.GetPortAddr: word;
begin
  result := 0;
  if Win32Platform <> VER_PLATFORM_WIN32_NT then
  begin
    EscapeCommFunction(FHandle, 10);
    asm
      MOV @result, dx;
    end;
  end;
end;

FUNCTION TBlockSerial.ReadTxEmpty(PortAddr: word): boolean;
begin
  result := true;
  if Win32Platform <> VER_PLATFORM_WIN32_NT then
  begin
    asm
      MOV dx, PortAddr;
      add dx, 5;
      in AL, dx;
      and AL, $40;
      JZ @K;
      MOV AL,1;
    @K: MOV @result, AL;
    end;
  end;
end;
{$ENDIF}

PROCEDURE TBlockSerial.GetComNr(value: string);
begin
  FComNr := PortIsClosed;
  if pos('COM', uppercase(value)) = 1 then
    FComNr := strToIntDef(copy(value, 4, length(value) - 3), PortIsClosed + 1) - 1;
  if pos('/DEV/TTYS', uppercase(value)) = 1 then
    FComNr := strToIntDef(copy(value, 10, length(value) - 9), PortIsClosed - 1);
end;

PROCEDURE TBlockSerial.SetBandwidth(value: integer);
begin
  MaxSendBandwidth := value;
  MaxRecvBandwidth := value;
end;

PROCEDURE TBlockSerial.LimitBandwidth(length: integer; MaxB: integer; VAR next: Longword);
VAR
  x: Longword;
  y: Longword;
begin
  if MaxB > 0 then
  begin
    y := GetTick;
    if next > y then
    begin
      x := next - y;
      if x > 0 then
      begin
        DoStatus(HR_Wait, intToStr(x));
        sleep(x);
      end;
    end;
    next := GetTick + trunc((length / MaxB) * 1000);
  end;
end;

PROCEDURE TBlockSerial.Config(baud, bits: integer; parity: char; stop: integer;
  softflow, hardflow: boolean);
begin
  FillChar(dcb, sizeOf(dcb), 0);
  GetCommState;
  dcb.DCBlength := sizeOf(dcb);
  dcb.BaudRate := baud;
  dcb.ByteSize := bits;
  case parity of
    'N', 'n': dcb.parity := 0;
    'O', 'o': dcb.parity := 1;
    'E', 'e': dcb.parity := 2;
    'M', 'm': dcb.parity := 3;
    'S', 's': dcb.parity := 4;
  end;
  dcb.StopBits := stop;
  dcb.XonChar := #17;
  dcb.XoffChar := #19;
  dcb.XonLim := FRecvBuffer div 4;
  dcb.XoffLim := FRecvBuffer div 4;
  dcb.Flags := dcb_Binary;
  if softflow then
    dcb.Flags := dcb.Flags or dcb_OutX or dcb_InX;
  if hardflow then
    dcb.Flags := dcb.Flags or dcb_OutxCtsFlow or dcb_RtsControlHandshake
  else
    dcb.Flags := dcb.Flags or dcb_RtsControlEnable;
  dcb.Flags := dcb.Flags or dcb_DtrControlEnable;
  if dcb.Parity > 0 then
    dcb.Flags := dcb.Flags or dcb_ParityCheck;
  SetCommState;
end;

PROCEDURE TBlockSerial.Connect(comport: string);
{$IFDEF MSWINDOWS}
VAR
  CommTimeouts: TCommTimeouts;
{$ENDIF}
begin
  // Is this TBlockSerial Instance already busy?
  if InstanceActive then           {HGJ}
  begin                            {HGJ}
    RaiseSynaError(ErrAlreadyInUse);
    exit;                          {HGJ}
  end;                             {HGJ}
  FBuffer := '';
  FDevice := comport;
  GetComNr(comport);
{$IFDEF MSWINDOWS}
  SetLastError (sOK);
{$ELSE}
  {$IFNDEF FPC}
  SetLastError (sOK);
  {$ELSE}
  fpSetErrno(sOK);
  {$ENDIF}
{$ENDIF}
{$IFNDEF MSWINDOWS}
  if FComNr <> PortIsClosed then
    FDevice := '/dev/ttyS' + intToStr(FComNr);
  // Comport already owned by another process?          {HGJ}
  if FLinuxLock then
    if not cpomComportAccessible then
    begin
      RaiseSynaError(ErrAlreadyOwned);
      exit;
    end;
{$IFNDEF FPC}
  FHandle := THandle(Libc.open(PChar(FDevice), O_RDWR or O_SYNC));
{$ELSE}
  FHandle := THandle(FpOpen(FDevice, O_RDWR or O_SYNC));
{$ENDIF}
  if FHandle = INVALID_HANDLE_VALUE then  //because THandle is not integer on all platforms!
    SerialCheck(-1)
  else
    SerialCheck(0);
  {$IFDEF UNIX}
  if FLastError <> sOK then
    if FLinuxLock then
      cpomReleaseComport;
  {$ENDIF}
  ExceptCheck;
  if FLastError <> sOK then
    exit;
{$ELSE}
  if FComNr <> PortIsClosed then
    FDevice := '\\.\COM' + intToStr(FComNr + 1);
  FHandle := THandle(CreateFile(PChar(FDevice), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0));
  if FHandle = INVALID_HANDLE_VALUE then  //because THandle is not integer on all platforms!
    SerialCheck(-1)
  else
    SerialCheck(0);
  ExceptCheck;
  if FLastError <> sOK then
    exit;
  SetCommMask(FHandle, 0);
  SetupComm(Fhandle, FRecvBuffer, 0);
  CommTimeOuts.ReadIntervalTimeout := MAXWORD;
  CommTimeOuts.ReadTotalTimeoutMultiplier := 0;
  CommTimeOuts.ReadTotalTimeoutConstant := 0;
  CommTimeOuts.WriteTotalTimeoutMultiplier := 0;
  CommTimeOuts.WriteTotalTimeoutConstant := 0;
  SetCommTimeOuts(FHandle, CommTimeOuts);
  FPortAddr := GetPortAddr;
{$ENDIF}
  SetSynaError(sOK);
  if not TestCtrlLine then  {HGJ}
  begin
    SetSynaError(ErrNoDeviceAnswer);
    FileClose(FHandle);         {HGJ}
    {$IFDEF UNIX}
    if FLinuxLock then
      cpomReleaseComport;                {HGJ}
    {$ENDIF}                             {HGJ}
    Fhandle := INVALID_HANDLE_VALUE;     {HGJ}
    FComNr:= PortIsClosed;               {HGJ}
  end
  else
  begin
    FInstanceActive:= true;
    RTS := true;
    DTR := true;
    Purge;
  end;
  ExceptCheck;
  DoStatus(HR_Connect, FDevice);
end;

FUNCTION TBlockSerial.SendBuffer(buffer: pointer; length: integer): integer;
{$IFDEF MSWINDOWS}
VAR
  Overlapped: TOverlapped;
  x, y, Err: dword;
{$ENDIF}
begin
  result := 0;
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  LimitBandwidth(length, FMaxSendBandwidth, FNextsend);
  if FRTSToggle then
  begin
    flush;
    RTS := true;
  end;
{$IFNDEF MSWINDOWS}
  result := FileWrite(Fhandle, buffer^, length);
  serialcheck(result);
{$ELSE}
  FillChar(Overlapped, sizeOf(Overlapped), 0);
  SetSynaError(sOK);
  y := 0;
  if not writeFile(FHandle, buffer^, length, dword(result), @Overlapped) then
    y := GetLastError;
  if y = ERROR_IO_PENDING then
  begin
    x := WaitForSingleObject(FHandle, FDeadlockTimeout);
    if x = WAIT_TIMEOUT then
    begin
      PurgeComm(FHandle, PURGE_TXABORT);
      SetSynaError(ErrTimeout);
    end;
    GetOverlappedResult(FHandle, Overlapped, dword(result), false);
  end
  else
    SetSynaError(y);
  ClearCommError(FHandle, err, nil);
  if err <> 0 then
    DecodeCommError(err);
{$ENDIF}
  if FRTSToggle then
  begin
    flush;
    CanWrite(255);
    RTS := false;
  end;
  ExceptCheck;
  DoStatus(HR_WriteCount, intToStr(result));
end;

PROCEDURE TBlockSerial.SendByte(data: byte);
begin
  SendBuffer(@data, 1);
end;

PROCEDURE TBlockSerial.SendString(data: ansistring);
begin
  SendBuffer(pointer(data), length(data));
end;

PROCEDURE TBlockSerial.SendInteger(data: integer);
begin
  SendBuffer(@data, sizeOf(data));
end;

PROCEDURE TBlockSerial.SendBlock(CONST data: ansistring);
begin
  SendInteger(length(data));
  SendString(data);
end;

PROCEDURE TBlockSerial.SendStreamRaw(CONST Stream: TStream);
VAR
  si: integer;
  x, y, yr: integer;
  s: ansistring;
begin
  si := Stream.size - Stream.position;
  x := 0;
  while x < si do
  begin
    y := si - x;
    if y > cSerialChunk then
      y := cSerialChunk;
    setLength(s, y);
    yr := Stream.read(PAnsiChar(s)^, y);
    if yr > 0 then
    begin
      setLength(s, yr);
      SendString(s);
      inc(x, yr);
    end
    else
      break;
  end;
end;

PROCEDURE TBlockSerial.SendStreamIndy(CONST Stream: TStream);
VAR
  si: integer;
begin
  si := Stream.size - Stream.position;
  si := Swapbytes(si);
  SendInteger(si);
  SendStreamRaw(Stream);
end;

PROCEDURE TBlockSerial.SendStream(CONST Stream: TStream);
VAR
  si: integer;
begin
  si := Stream.size - Stream.position;
  SendInteger(si);
  SendStreamRaw(Stream);
end;

FUNCTION TBlockSerial.RecvBuffer(buffer: pointer; length: integer): integer;
{$IFNDEF MSWINDOWS}
begin
  result := 0;
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  LimitBandwidth(length, FMaxRecvBandwidth, FNextRecv);
  result := FileRead(FHandle, buffer^, length);
  serialcheck(result);
{$ELSE}
VAR
  Overlapped: TOverlapped;
  x, y, Err: dword;
begin
  result := 0;
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  LimitBandwidth(length, FMaxRecvBandwidth, FNextRecv);
  FillChar(Overlapped, sizeOf(Overlapped), 0);
  SetSynaError(sOK);
  y := 0;
  if not readFile(FHandle, buffer^, length, dword(result), @Overlapped) then
    y := GetLastError;
  if y = ERROR_IO_PENDING then
  begin
    x := WaitForSingleObject(FHandle, FDeadlockTimeout);
    if x = WAIT_TIMEOUT then
    begin
      PurgeComm(FHandle, PURGE_RXABORT);
      SetSynaError(ErrTimeout);
    end;
    GetOverlappedResult(FHandle, Overlapped, dword(result), false);
  end
  else
    SetSynaError(y);
  ClearCommError(FHandle, err, nil);
  if err <> 0 then
    DecodeCommError(err);
{$ENDIF}
  ExceptCheck;
  DoStatus(HR_ReadCount, intToStr(result));
end;

FUNCTION TBlockSerial.RecvBufferEx(buffer: pointer; length: integer; timeout: integer): integer;
VAR
  s: ansistring;
  rl, l: integer;
  ti: Longword;
begin
  result := 0;
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  SetSynaError(sOK);
  rl := 0;
  repeat
    ti := GetTick;
    s := RecvPacket(Timeout);
    l := system.length(s);
    if (rl + l) > length then
      l := length - rl;
    move(pointer(s)^, IncPoint(buffer, rl)^, l);
    rl := rl + l;
    if FLastError <> sOK then
      break;
    if rl >= length then
      break;
    if not FInterPacketTimeout then
    begin
      Timeout := Timeout - integer(TickDelta(ti, GetTick));
      if Timeout <= 0 then
      begin
        SetSynaError(ErrTimeout);
        break;
      end;
    end;
  until false;
  Delete(s, 1, l);
  FBuffer := s;
  result := rl;
end;

FUNCTION TBlockSerial.RecvBufferStr(length: integer; Timeout: integer): ansistring;
VAR
  x: integer;
begin
  result := '';
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  SetSynaError(sOK);
  if length > 0 then
  begin
    setLength(result, length);
    x := RecvBufferEx(PAnsiChar(result), length , Timeout);
    if FLastError = sOK then
      setLength(result, x)
    else
      result := '';
  end;
end;

FUNCTION TBlockSerial.RecvPacket(Timeout: integer): ansistring;
VAR
  x: integer;
begin
  result := '';
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  SetSynaError(sOK);
  if FBuffer <> '' then
  begin
    result := FBuffer;
    FBuffer := '';
  end
  else
  begin
    //not drain CPU on large downloads...
    sleep(0);
    x := WaitingData;
    if x > 0 then
    begin
      setLength(result, x);
      x := RecvBuffer(pointer(result), x);
      if x >= 0 then
        setLength(result, x);
    end
    else
    begin
      if CanRead(Timeout) then
      begin
        x := WaitingData;
        if x = 0 then
          SetSynaError(ErrTimeout);
        if x > 0 then
        begin
          setLength(result, x);
          x := RecvBuffer(pointer(result), x);
          if x >= 0 then
            setLength(result, x);
        end;
      end
      else
        SetSynaError(ErrTimeout);
    end;
  end;
  ExceptCheck;
end;


FUNCTION TBlockSerial.RecvByte(timeout: integer): byte;
begin
  result := 0;
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  SetSynaError(sOK);
  if FBuffer = '' then
    FBuffer := RecvPacket(Timeout);
  if (FLastError = sOK) and (FBuffer <> '') then
  begin
    result := ord(FBuffer[1]);
    system.Delete(FBuffer, 1, 1);
  end;
  ExceptCheck;
end;

FUNCTION TBlockSerial.RecvTerminated(Timeout: integer; CONST Terminator: ansistring): ansistring;
VAR
  x: integer;
  s: ansistring;
  l: integer;
  CorCRLF: boolean;
  t: ansistring;
  tl: integer;
  ti: Longword;
begin
  result := '';
  if PreTestFailing then   {HGJ}
    exit;                  {HGJ}
  SetSynaError(sOK);
  l := system.length(Terminator);
  if l = 0 then
    exit;
  tl := l;
  CorCRLF := FConvertLineEnd and (Terminator = CRLF);
  s := '';
  x := 0;
  repeat
    ti := GetTick;
    //get rest of FBuffer or incomming new data...
    s := s + RecvPacket(Timeout);
    if FLastError <> sOK then
      break;
    x := 0;
    if length(s) > 0 then
      if CorCRLF then
      begin
        if FLastCR and (s[1] = LF) then
          Delete(s, 1, 1);
        if FLastLF and (s[1] = CR) then
          Delete(s, 1, 1);
        FLastCR := false;
        FLastLF := false;
        t := '';
        x := PosCRLF(s, t);
        tl := system.length(t);
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
    if (FMaxLineLength <> 0) and (system.length(s) > FMaxLineLength) then
    begin
      SetSynaError(ErrMaxBuffer);
      break;
    end;
    if x > 0 then
      break;
    if not FInterPacketTimeout then
    begin
      Timeout := Timeout - integer(TickDelta(ti, GetTick));
      if Timeout <= 0 then
      begin
        SetSynaError(ErrTimeout);
        break;
      end;
    end;
  until false;
  if x > 0 then
  begin
    result := copy(s, 1, x - 1);
    system.Delete(s, 1, x + tl - 1);
  end;
  FBuffer := s;
  ExceptCheck;
end;


FUNCTION TBlockSerial.RecvString(Timeout: integer): ansistring;
VAR
  s: ansistring;
begin
  result := '';
  s := RecvTerminated(Timeout, #13 + #10);
  if FLastError = sOK then
    result := s;
end;

FUNCTION TBlockSerial.RecvInteger(Timeout: integer): integer;
VAR
  s: ansistring;
begin
  result := 0;
  s := RecvBufferStr(4, Timeout);
  if FLastError = 0 then
    result := (ord(s[1]) + ord(s[2]) * 256) + (ord(s[3]) + ord(s[4]) * 256) * 65536;
end;

FUNCTION TBlockSerial.RecvBlock(Timeout: integer): ansistring;
VAR
  x: integer;
begin
  result := '';
  x := RecvInteger(Timeout);
  if FLastError = 0 then
    result := RecvBufferStr(x, Timeout);
end;

PROCEDURE TBlockSerial.RecvStreamRaw(CONST Stream: TStream; Timeout: integer);
VAR
  s: ansistring;
begin
  repeat
    s := RecvPacket(Timeout);
    if FLastError = 0 then
      WriteStrToStream(Stream, s);
  until FLastError <> 0;
end;

PROCEDURE TBlockSerial.RecvStreamSize(CONST Stream: TStream; Timeout: integer; size: integer);
VAR
  s: ansistring;
  n: integer;
begin
  for n := 1 to (size div cSerialChunk) do
  begin
    s := RecvBufferStr(cSerialChunk, Timeout);
    if FLastError <> 0 then
      exit;
    Stream.write(PAnsiChar(s)^, cSerialChunk);
  end;
  n := size mod cSerialChunk;
  if n > 0 then
  begin
    s := RecvBufferStr(n, Timeout);
    if FLastError <> 0 then
      exit;
    Stream.write(PAnsiChar(s)^, n);
  end;
end;

PROCEDURE TBlockSerial.RecvStreamIndy(CONST Stream: TStream; Timeout: integer);
VAR
  x: integer;
begin
  x := RecvInteger(Timeout);
  x := SwapBytes(x);
  if FLastError = 0 then
    RecvStreamSize(Stream, Timeout, x);
end;

PROCEDURE TBlockSerial.RecvStream(CONST Stream: TStream; Timeout: integer);
VAR
  x: integer;
begin
  x := RecvInteger(Timeout);
  if FLastError = 0 then
    RecvStreamSize(Stream, Timeout, x);
end;

{$IFNDEF MSWINDOWS}
FUNCTION TBlockSerial.WaitingData: integer;
begin
{$IFNDEF FPC}
  serialcheck(ioctl(FHandle, FIONREAD, @result));
{$ELSE}
  serialcheck(fpIoctl(FHandle, FIONREAD, @result));
{$ENDIF}
  if FLastError <> 0 then
    result := 0;
  ExceptCheck;
end;
{$ELSE}
FUNCTION TBlockSerial.WaitingData: integer;
VAR
  stat: TComStat;
  err: dword;
begin
  if ClearCommError(FHandle, err, @stat) then
  begin
    SetSynaError(sOK);
    result := stat.cbInQue;
  end
  else
  begin
    SerialCheck(sErr);
    result := 0;
  end;
  ExceptCheck;
end;
{$ENDIF}

FUNCTION TBlockSerial.WaitingDataEx: integer;
begin
	if FBuffer <> '' then
  	result := length(FBuffer)
  else
  	result := Waitingdata;
end;

{$IFNDEF MSWINDOWS}
FUNCTION TBlockSerial.SendingData: integer;
begin
  SetSynaError(sOK);
  result := 0;
end;
{$ELSE}
FUNCTION TBlockSerial.SendingData: integer;
VAR
  stat: TComStat;
  err: dword;
begin
  SetSynaError(sOK);
  if not ClearCommError(FHandle, err, @stat) then
    serialcheck(sErr);
  ExceptCheck;
  result := stat.cbOutQue;
end;
{$ENDIF}

{$IFNDEF MSWINDOWS}
PROCEDURE TBlockSerial.DcbToTermios(CONST dcb: TDCB; VAR term: termios);
VAR
  n: integer;
  x: Cardinal;
begin
  //others
  cfmakeraw(term);
  term.c_cflag := term.c_cflag or CREAD;
  term.c_cflag := term.c_cflag or CLOCAL;
  term.c_cflag := term.c_cflag or HUPCL;
  //hardware handshake
  if (dcb.flags and dcb_RtsControlHandshake) > 0 then
    term.c_cflag := term.c_cflag or CRTSCTS
  else
    term.c_cflag := term.c_cflag and (not CRTSCTS);
  //software handshake
  if (dcb.flags and dcb_OutX) > 0 then
    term.c_iflag := term.c_iflag or IXON or IXOFF or IXANY
  else
    term.c_iflag := term.c_iflag and (not (IXON or IXOFF or IXANY));
  //size of byte
  term.c_cflag := term.c_cflag and (not CSIZE);
  case dcb.bytesize of
    5:
      term.c_cflag := term.c_cflag or CS5;
    6:
      term.c_cflag := term.c_cflag or CS6;
    7:
{$IFDEF FPC}
      term.c_cflag := term.c_cflag or CS7;
{$ELSE}
      term.c_cflag := term.c_cflag or CS7fix;
{$ENDIF}
    8:
      term.c_cflag := term.c_cflag or CS8;
  end;
  //parity
  if (dcb.flags and dcb_ParityCheck) > 0 then
    term.c_cflag := term.c_cflag or PARENB
  else
    term.c_cflag := term.c_cflag and (not PARENB);
  case dcb.parity of
    1: //'O'
      term.c_cflag := term.c_cflag or PARODD;
    2: //'E'
      term.c_cflag := term.c_cflag and (not PARODD);
  end;
  //stop bits
  if dcb.stopbits > 0 then
    term.c_cflag := term.c_cflag or CSTOPB
  else
    term.c_cflag := term.c_cflag and (not CSTOPB);
  //set baudrate;
  x := 0;
  for n := 0 to Maxrates do
    if rates[n, 0] = dcb.BaudRate then
    begin
      x := rates[n, 1];
      break;
    end;
  cfsetospeed(term, x);
  cfsetispeed(term, x);
end;

PROCEDURE TBlockSerial.TermiosToDcb(CONST term: termios; VAR dcb: TDCB);
VAR
  n: integer;
  x: Cardinal;
begin
  //set baudrate;
  dcb.baudrate := 0;
 {$IFDEF FPC}
  //why FPC not have cfgetospeed???
  x := term.c_oflag and $0F;
 {$ELSE}
  x := cfgetospeed(term);
 {$ENDIF}
  for n := 0 to Maxrates do
    if rates[n, 1] = x then
    begin
      dcb.baudrate := rates[n, 0];
      break;
    end;
  //hardware handshake
  if (term.c_cflag and CRTSCTS) > 0 then
    dcb.flags := dcb.flags or dcb_RtsControlHandshake or dcb_OutxCtsFlow
  else
    dcb.flags := dcb.flags and (not (dcb_RtsControlHandshake or dcb_OutxCtsFlow));
  //software handshake
  if (term.c_cflag and IXOFF) > 0 then
    dcb.flags := dcb.flags or dcb_OutX or dcb_InX
  else
    dcb.flags := dcb.flags and (not (dcb_OutX or dcb_InX));
  //size of byte
  case term.c_cflag and CSIZE of
    CS5:
      dcb.bytesize := 5;
    CS6:
      dcb.bytesize := 6;
    CS7fix:
      dcb.bytesize := 7;
    CS8:
      dcb.bytesize := 8;
  end;
  //parity
  if (term.c_cflag and PARENB) > 0 then
    dcb.flags := dcb.flags or dcb_ParityCheck
  else
    dcb.flags := dcb.flags and (not dcb_ParityCheck);
  dcb.parity := 0;
  if (term.c_cflag and PARODD) > 0 then
    dcb.parity := 1
  else
    dcb.parity := 2;
  //stop bits
  if (term.c_cflag and CSTOPB) > 0 then
    dcb.stopbits := 2
  else
    dcb.stopbits := 0;
end;
{$ENDIF}

{$IFNDEF MSWINDOWS}
PROCEDURE TBlockSerial.SetCommState;
begin
  DcbToTermios(dcb, termiosstruc);
  SerialCheck(tcsetattr(FHandle, TCSANOW, termiosstruc));
  ExceptCheck;
end;
{$ELSE}
PROCEDURE TBlockSerial.SetCommState;
begin
  SetSynaError(sOK);
  if not windows.SetCommState(Fhandle, dcb) then
    SerialCheck(sErr);
  ExceptCheck;
end;
{$ENDIF}

{$IFNDEF MSWINDOWS}
PROCEDURE TBlockSerial.GetCommState;
begin
  SerialCheck(tcgetattr(FHandle, termiosstruc));
  ExceptCheck;
  TermiostoDCB(termiosstruc, dcb);
end;
{$ELSE}
PROCEDURE TBlockSerial.GetCommState;
begin
  SetSynaError(sOK);
  if not windows.GetCommState(Fhandle, dcb) then
    SerialCheck(sErr);
  ExceptCheck;
end;
{$ENDIF}

PROCEDURE TBlockSerial.SetSizeRecvBuffer(size: integer);
begin
{$IFDEF MSWINDOWS}
  SetupComm(Fhandle, size, 0);
  GetCommState;
  dcb.XonLim := size div 4;
  dcb.XoffLim := size div 4;
  SetCommState;
{$ENDIF}
  FRecvBuffer := size;
end;

FUNCTION TBlockSerial.GetDSR: boolean;
begin
  ModemStatus;
{$IFNDEF MSWINDOWS}
  result := (FModemWord and TIOCM_DSR) > 0;
{$ELSE}
  result := (FModemWord and MS_DSR_ON) > 0;
{$ENDIF}
end;

PROCEDURE TBlockSerial.SetDTRF(value: boolean);
begin
{$IFNDEF MSWINDOWS}
  ModemStatus;
  if value then
    FModemWord := FModemWord or TIOCM_DTR
  else
    FModemWord := FModemWord and not TIOCM_DTR;
  {$IFNDEF FPC}
  ioctl(FHandle, TIOCMSET, @FModemWord);
  {$ELSE}
  fpioctl(FHandle, TIOCMSET, @FModemWord);
  {$ENDIF}
{$ELSE}
  if value then
    EscapeCommFunction(FHandle, SETDTR)
  else
    EscapeCommFunction(FHandle, CLRDTR);
{$ENDIF}
end;

FUNCTION TBlockSerial.GetCTS: boolean;
begin
  ModemStatus;
{$IFNDEF MSWINDOWS}
  result := (FModemWord and TIOCM_CTS) > 0;
{$ELSE}
  result := (FModemWord and MS_CTS_ON) > 0;
{$ENDIF}
end;

PROCEDURE TBlockSerial.SetRTSF(value: boolean);
begin
{$IFNDEF MSWINDOWS}
  ModemStatus;
  if value then
    FModemWord := FModemWord or TIOCM_RTS
  else
    FModemWord := FModemWord and not TIOCM_RTS;
  {$IFNDEF FPC}
  ioctl(FHandle, TIOCMSET, @FModemWord);
  {$ELSE}
  fpioctl(FHandle, TIOCMSET, @FModemWord);
  {$ENDIF}
{$ELSE}
  if value then
    EscapeCommFunction(FHandle, SETRTS)
  else
    EscapeCommFunction(FHandle, CLRRTS);
{$ENDIF}
end;

FUNCTION TBlockSerial.GetCarrier: boolean;
begin
  ModemStatus;
{$IFNDEF MSWINDOWS}
  result := (FModemWord and TIOCM_CAR) > 0;
{$ELSE}
  result := (FModemWord and MS_RLSD_ON) > 0;
{$ENDIF}
end;

FUNCTION TBlockSerial.GetRing: boolean;
begin
  ModemStatus;
{$IFNDEF MSWINDOWS}
  result := (FModemWord and TIOCM_RNG) > 0;
{$ELSE}
  result := (FModemWord and MS_RING_ON) > 0;
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
FUNCTION TBlockSerial.CanEvent(Event: dword; Timeout: integer): boolean;
VAR
  ex: dword;
  y: integer;
  Overlapped: TOverlapped;
begin
  FillChar(Overlapped, sizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, true, false, nil);
  try
    SetCommMask(FHandle, Event);
    SetSynaError(sOK);
    if (Event = EV_RXCHAR) and (Waitingdata > 0) then
      result := true
    else
    begin
      y := 0;
      if not WaitCommEvent(FHandle, ex, @Overlapped) then
        y := GetLastError;
      if y = ERROR_IO_PENDING then
      begin
        //timedout
        WaitForSingleObject(Overlapped.hEvent, Timeout);
        SetCommMask(FHandle, 0);
        GetOverlappedResult(FHandle, Overlapped, dword(y), true);
      end;
      result := (ex and Event) = Event;
    end;
  finally
    SetCommMask(FHandle, 0);
    CloseHandle(Overlapped.hEvent);
  end;
end;
{$ENDIF}

{$IFNDEF MSWINDOWS}
FUNCTION TBlockSerial.CanRead(Timeout: integer): boolean;
VAR
  FDSet: TFDSet;
  timeval: PTimeVal;
  TimeV: TTimeVal;
  x: integer;
begin
  TimeV.tv_usec := (Timeout mod 1000) * 1000;
  TimeV.tv_sec := Timeout div 1000;
  timeval := @TimeV;
  if Timeout = -1 then
    timeval := nil;
  {$IFNDEF FPC}
  FD_ZERO(FDSet);
  FD_SET(FHandle, FDSet);
  x := Select(FHandle + 1, @FDSet, nil, nil, timeval);
  {$ELSE}
  fpFD_ZERO(FDSet);
  fpFD_SET(FHandle, FDSet);
  x := fpSelect(FHandle + 1, @FDSet, nil, nil, timeval);
  {$ENDIF}
  SerialCheck(x);
  if FLastError <> sOK then
    x := 0;
  result := x > 0;
  ExceptCheck;
  if result then
    DoStatus(HR_CanRead, '');
end;
{$ELSE}
FUNCTION TBlockSerial.CanRead(Timeout: integer): boolean;
begin
  result := WaitingData > 0;
  if not result then
    result := CanEvent(EV_RXCHAR, Timeout) or (WaitingData > 0);
    //check WaitingData again due some broken virtual ports
  if result then
    DoStatus(HR_CanRead, '');
end;
{$ENDIF}

{$IFNDEF MSWINDOWS}
FUNCTION TBlockSerial.CanWrite(Timeout: integer): boolean;
VAR
  FDSet: TFDSet;
  timeval: PTimeVal;
  TimeV: TTimeVal;
  x: integer;
begin
  TimeV.tv_usec := (Timeout mod 1000) * 1000;
  TimeV.tv_sec := Timeout div 1000;
  timeval := @TimeV;
  if Timeout = -1 then
    timeval := nil;
  {$IFNDEF FPC}
  FD_ZERO(FDSet);
  FD_SET(FHandle, FDSet);
  x := Select(FHandle + 1, nil, @FDSet, nil, timeval);
  {$ELSE}
  fpFD_ZERO(FDSet);
  fpFD_SET(FHandle, FDSet);
  x := fpSelect(FHandle + 1, nil, @FDSet, nil, timeval);
  {$ENDIF}
  SerialCheck(x);
  if FLastError <> sOK then
    x := 0;
  result := x > 0;
  ExceptCheck;
  if result then
    DoStatus(HR_CanWrite, '');
end;
{$ELSE}
FUNCTION TBlockSerial.CanWrite(Timeout: integer): boolean;
VAR
  t: Longword;
begin
  result := SendingData = 0;
  if not result then
	  result := CanEvent(EV_TXEMPTY, Timeout);
  if result and (Win32Platform <> VER_PLATFORM_WIN32_NT) then
  begin
    t := GetTick;
    while not ReadTxEmpty(FPortAddr) do
    begin
      if TickDelta(t, GetTick) > 255 then
        break;
      sleep(0);
    end;
  end;
  if result then
    DoStatus(HR_CanWrite, '');
end;
{$ENDIF}

FUNCTION TBlockSerial.CanReadEx(Timeout: integer): boolean;
begin
	if Fbuffer <> '' then
  	result := true
  else
  	result := CanRead(Timeout);
end;

PROCEDURE TBlockSerial.EnableRTSToggle(value: boolean);
begin
  SetSynaError(sOK);
{$IFNDEF MSWINDOWS}
  FRTSToggle := value;
  if value then
    RTS:=false;
{$ELSE}
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    GetCommState;
    if value then
      dcb.Flags := dcb.Flags or dcb_RtsControlToggle
    else
      dcb.flags := dcb.flags and (not dcb_RtsControlToggle);
    SetCommState;
  end
  else
  begin
    FRTSToggle := value;
    if value then
      RTS:=false;
  end;
{$ENDIF}
end;

PROCEDURE TBlockSerial.flush;
begin
{$IFNDEF MSWINDOWS}
  SerialCheck(tcdrain(FHandle));
{$ELSE}
  SetSynaError(sOK);
  if not Flushfilebuffers(FHandle) then
    SerialCheck(sErr);
{$ENDIF}
  ExceptCheck;
end;

{$IFNDEF MSWINDOWS}
PROCEDURE TBlockSerial.Purge;
begin
  {$IFNDEF FPC}
  SerialCheck(ioctl(FHandle, TCFLSH, TCIOFLUSH));
  {$ELSE}
    {$IFDEF DARWIN}
    SerialCheck(fpioctl(FHandle, TCIOflush, TCIOFLUSH));
    {$ELSE}
    SerialCheck(fpioctl(FHandle, TCFLSH, pointer(ptrint(TCIOFLUSH))));
    {$ENDIF}
  {$ENDIF}
  FBuffer := '';
  ExceptCheck;
end;
{$ELSE}
PROCEDURE TBlockSerial.Purge;
VAR
  x: integer;
begin
  SetSynaError(sOK);
  x := PURGE_TXABORT or PURGE_TXCLEAR or PURGE_RXABORT or PURGE_RXCLEAR;
  if not PurgeComm(FHandle, x) then
    SerialCheck(sErr);
  FBuffer := '';
  ExceptCheck;
end;
{$ENDIF}

FUNCTION TBlockSerial.ModemStatus: integer;
begin
  result := 0;
{$IFNDEF MSWINDOWS}
  {$IFNDEF FPC}
  SerialCheck(ioctl(FHandle, TIOCMGET, @result));
  {$ELSE}
  SerialCheck(fpioctl(FHandle, TIOCMGET, @result));
  {$ENDIF}
{$ELSE}
  SetSynaError(sOK);
  if not GetCommModemStatus(FHandle, dword(result)) then
    SerialCheck(sErr);
{$ENDIF}
  ExceptCheck;
  FModemWord := result;
end;

PROCEDURE TBlockSerial.SetBreak(Duration: integer);
begin
{$IFNDEF MSWINDOWS}
  SerialCheck(tcsendbreak(FHandle, Duration));
{$ELSE}
  SetCommBreak(FHandle);
  sleep(Duration);
  SetSynaError(sOK);
  if not ClearCommBreak(FHandle) then
    SerialCheck(sErr);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
PROCEDURE TBlockSerial.DecodeCommError(Error: dword);
begin
  if (Error and dword(CE_FRAME)) > 1 then
    FLastError := ErrFrame;
  if (Error and dword(CE_OVERRUN)) > 1 then
    FLastError := ErrOverrun;
  if (Error and dword(CE_RXOVER)) > 1 then
    FLastError := ErrRxOver;
  if (Error and dword(CE_RXPARITY)) > 1 then
    FLastError := ErrRxParity;
  if (Error and dword(CE_TXFULL)) > 1 then
    FLastError := ErrTxFull;
end;
{$ENDIF}

//HGJ
FUNCTION TBlockSerial.PreTestFailing: boolean;
begin
  if not FInstanceActive then
  begin
    RaiseSynaError(ErrPortNotOpen);
    result:= true;
    exit;
  end;
  result := not TestCtrlLine;
  if result then
    RaiseSynaError(ErrNoDeviceAnswer)
end;

FUNCTION TBlockSerial.TestCtrlLine: boolean;
begin
  result := ((not FTestDSR) or DSR) and ((not FTestCTS) or CTS);
end;

FUNCTION TBlockSerial.ATCommand(value: ansistring): ansistring;
VAR
  s: ansistring;
  ConvSave: boolean;
begin
  result := '';
  FAtResult := false;
  ConvSave := FConvertLineEnd;
  try
    FConvertLineEnd := true;
    SendString(value + #$0D);
    repeat
      s := RecvString(FAtTimeout);
      if s <> value then
        result := result + s + CRLF;
      if s = 'OK' then
      begin
        FAtResult := true;
        break;
      end;
      if s = 'ERROR' then
        break;
    until FLastError <> sOK;
  finally
    FConvertLineEnd := Convsave;
  end;
end;


FUNCTION TBlockSerial.ATConnect(value: ansistring): ansistring;
VAR
  s: ansistring;
  ConvSave: boolean;
begin
  result := '';
  FAtResult := false;
  ConvSave := FConvertLineEnd;
  try
    FConvertLineEnd := true;
    SendString(value + #$0D);
    repeat
      s := RecvString(90 * FAtTimeout);
      if s <> value then
        result := result + s + CRLF;
      if s = 'NO CARRIER' then
        break;
      if s = 'ERROR' then
        break;
      if s = 'BUSY' then
        break;
      if s = 'NO DIALTONE' then
        break;
      if pos('CONNECT', s) = 1 then
      begin
        FAtResult := true;
        break;
      end;
    until FLastError <> sOK;
  finally
    FConvertLineEnd := Convsave;
  end;
end;

FUNCTION TBlockSerial.SerialCheck(SerialResult: integer): integer;
begin
  if SerialResult = integer(INVALID_HANDLE_VALUE) then
{$IFDEF MSWINDOWS}
    result := GetLastError
{$ELSE}
  {$IFNDEF FPC}
    result := GetLastError
  {$ELSE}
    result := fpGetErrno
  {$ENDIF}
{$ENDIF}
  else
    result := sOK;
  FLastError := result;
  FLastErrorDesc := GetErrorDesc(FLastError);
end;

PROCEDURE TBlockSerial.ExceptCheck;
VAR
  e: ESynaSerError;
  s: string;
begin
  if FRaiseExcept and (FLastError <> sOK) then
  begin
    s := GetErrorDesc(FLastError);
    e := ESynaSerError.CreateFmt('Communication error %d: %s', [FLastError, s]);
    e.ErrorCode := FLastError;
    e.errorMessage := s;
    raise e;
  end;
end;

PROCEDURE TBlockSerial.SetSynaError(ErrNumber: integer);
begin
  FLastError := ErrNumber;
  FLastErrorDesc := GetErrorDesc(FLastError);
end;

PROCEDURE TBlockSerial.RaiseSynaError(ErrNumber: integer);
begin
  SetSynaError(ErrNumber);
  ExceptCheck;
end;

PROCEDURE TBlockSerial.DoStatus(Reason: THookSerialReason; CONST value: string);
begin
  if assigned(OnStatus) then
    OnStatus(self, Reason, value);
end;

{======================================================================}

class FUNCTION TBlockSerial.GetErrorDesc(ErrorCode: integer): string;
begin
  result:= '';
  case ErrorCode of
    sOK:               result := 'OK';
    ErrAlreadyOwned:   result := 'Port owned by other process';{HGJ}
    ErrAlreadyInUse:   result := 'Instance already in use';    {HGJ}
    ErrWrongParameter: result := 'Wrong parameter at call';     {HGJ}
    ErrPortNotOpen:    result := 'Instance not yet connected'; {HGJ}
    ErrNoDeviceAnswer: result := 'No device answer detected';  {HGJ}
    ErrMaxBuffer:      result := 'Maximal buffer length exceeded';
    ErrTimeout:        result := 'Timeout during operation';
    ErrNotRead:        result := 'Reading of data failed';
    ErrFrame:          result := 'Receive framing error';
    ErrOverrun:        result := 'Receive Overrun Error';
    ErrRxOver:         result := 'Receive Queue overflow';
    ErrRxParity:       result := 'Receive Parity Error';
    ErrTxFull:         result := 'Tranceive Queue is full';
  end;
  if result = '' then
  begin
    result := SysErrorMessage(ErrorCode);
  end;
end;


{---------- cpom Comport Ownership Manager Routines -------------
 by Hans-Georg Joepgen of Stuttgart, Germany.
 Copyright (c) 2002, by Hans-Georg Joepgen

  Stefan Krauss of Stuttgart, Germany, contributed literature and Internet
  research results, invaluable advice and excellent answers to the Comport
  Ownership Manager.
}

{$IFDEF UNIX}

FUNCTION TBlockSerial.LockfileName: string;
VAR
  s: string;
begin
  s := SeparateRight(FDevice, '/dev/');
  result := LockfileDirectory + '/LCK..' + s;
end;

PROCEDURE TBlockSerial.CreateLockfile(PidNr: integer);
VAR
  f: textFile;
  s: string;
begin
  // Create content for file
  s := intToStr(PidNr);
  while length(s) < 10 do
    s := ' ' + s;
  // Create file
  try
    AssignFile(f, LockfileName);
    try
      rewrite(f);
      writeln(f, s);
    finally
      CloseFile(f);
    end;
    // Allow all users to enjoy the benefits of cpom
    s := 'chmod a+rw ' + LockfileName;
{$IFNDEF FPC}
    FileSetReadOnly( LockfileName, false ) ;
 // Libc.system(pchar(s));
{$ELSE}
    fpSystem(s);
{$ENDIF}
  except
    // not raise exception, if you not have write permission for lock.
    on Exception do
      ;
  end;
end;

FUNCTION TBlockSerial.ReadLockfile: integer;
{Returns PID from Lockfile. Lockfile must exist.}
VAR
  f: textFile;
  s: string;
begin
  AssignFile(f, LockfileName);
  reset(f);
  try
    readln(f, s);
  finally
    CloseFile(f);
  end;
  result := strToIntDef(s, -1)
end;

FUNCTION TBlockSerial.cpomComportAccessible: boolean;
VAR
  MyPid: integer;
  fileName: string;
begin
  fileName := LockfileName;
  {$IFNDEF FPC}
  MyPid := Libc.getpid;
  {$ELSE}
  MyPid := fpGetPID;
  {$ENDIF}
  // Make sure, the Lock Files Directory exists. We need it.
  if not DirectoryExists(LockfileDirectory) then
    CreateDir(LockfileDirectory);
  // Check the Lockfile
  if not fileExists (fileName) then
  begin // comport is not locked. Lock it for us.
    CreateLockfile(MyPid);
    result := true;
    exit;  // done.
  end;
  // Is port owned by orphan? Then it's time for error recovery.
  //FPC forgot to add getsid.. :-(
  {$IFNDEF FPC}
  if Libc.getsid(ReadLockfile) = -1 then
  begin //  Lockfile was left from former desaster
    DeleteFile(fileName); // error recovery
    CreateLockfile(MyPid);
    result := true;
    exit;
  end;
  {$ENDIF}
  result := false // Sorry, port is owned by living PID and locked
end;

PROCEDURE TBlockSerial.cpomReleaseComport;
begin
  DeleteFile(LockfileName);
end;

{$ENDIF}
{----------------------------------------------------------------}

{$IFDEF MSWINDOWS}
FUNCTION GetSerialPortNames: string;
VAR
  reg: TRegistry;
  l, v: TStringList;
  n: integer;
begin
  l := TStringList.create;
  v := TStringList.create;
  reg := TRegistry.create;
  try
{$IFNDEF VER100}
{$IFNDEF VER120}
    reg.Access := KEY_READ;
{$ENDIF}
{$ENDIF}
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.OpenKey('\HARDWARE\DEVICEMAP\SERIALCOMM', false);
    reg.GetValueNames(l);
    for n := 0 to l.count - 1 do
      v.add(reg.readString(l[n]));
    result := v.CommaText;
  finally
    reg.free;
    l.free;
    v.free;
  end;
end;
{$ENDIF}
{$IFNDEF MSWINDOWS}
FUNCTION GetSerialPortNames: string;
VAR
  index: integer;
  data: string;
  TmpPorts: string;
  sr : TSearchRec;
begin
  try
    TmpPorts := '';
    if FindFirst('/dev/ttyS*', $ffffffff, sr) = 0 then
    begin
      repeat
        if (sr.Attr and $ffffffff) = Sr.Attr then
        begin
          data := sr.name;
          index := length(data);
          while (index > 1) and (data[index] <> '/') do
            index := index - 1;
          TmpPorts := TmpPorts + ' ' + copy(data, 1, index + 1);
        end;
      until findNext(sr) <> 0;
    end;
    FindClose(sr);
  finally
    result:=TmpPorts;
  end;
end;
{$ENDIF}

end.
