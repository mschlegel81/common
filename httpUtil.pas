UNIT httpUtil;
INTERFACE
USES Classes, blcksock, sockets, synautil, sysutils, myGenerics,myStringUtil;
TYPE
  P_socketPair=^T_socketPair;
  T_socketPair=object
    private
      ListenerSocket,
      ConnectionSocket: TTCPBlockSocket;
      id:ansistring;
      acceptingRequest:boolean;
    public
      CONSTRUCTOR create(CONST ipAndPort:string);
      CONSTRUCTOR create(CONST ip,port:string);
      DESTRUCTOR destroy;
      FUNCTION getRequest(CONST timeOutInMilliseconds:longint=100):ansistring;
      PROCEDURE sendString(CONST s:ansistring);
      FUNCTION toString:ansistring;
  end;

  F_stringToString=FUNCTION(CONST request:string):string;

  P_customSocketListener=^T_customSocketListener;
  T_customSocketListener=object
    private
      Socket:T_socketPair;
      requestToResponseMapper:F_stringToString;
      killSignalled:boolean;
    public
      CONSTRUCTOR create(CONST ipAndPort:string; CONST requestToResponseMapper_:F_stringToString);
      DESTRUCTOR destroy;
      PROCEDURE attend;
      PROCEDURE kill;
  end;

CONST HTTP_404_RESPONSE='HTTP/1.0 404' + CRLF;

FUNCTION wrapTextInHttp(CONST OutputDataString:string; CONST contentType:string='Text/Html'):string;
FUNCTION cleanIp(CONST dirtyIp:ansistring):ansistring;
IMPLEMENTATION
PROCEDURE disposeSocket(VAR socket:P_socketPair);
  begin
    dispose(socket,destroy);
  end;

FUNCTION wrapTextInHttp(CONST OutputDataString: string; CONST contentType:string='Text/Html'): string;
  begin
    result:='HTTP/1.0 200' + CRLF +
            'Content-type: '+ contentType + CRLF +
            'Content-length: ' + intToStr(length(OutputDataString)) + CRLF +
            'Connection: close' + CRLF +
            'Date: ' + Rfc822DateTime(now) + CRLF +
            'Server: MNH5 using Synapse' + CRLF +
            '' + CRLF +
            OutputDataString;
  end;

PROCEDURE cleanSocket(VAR ipAndPort:string; OUT ip,port:string);
  CONST default_port=60000;
  VAR temp:T_arrayOfString;
      intPort:longint;
  begin
    temp:=split(ipAndPort,':');
    if length(temp)>1 then begin
      intPort:=strToIntDef(trim(temp[1]),-1);
      if intPort<0 then intPort:=default_port;
    end else intPort:=default_port;
    port:=intToStr(intPort);
    ip:=replaceAll(
          cleanString(
            replaceAll(
              lowercase(trim(temp[0])),
              'localhost',
              '127.0.0.1'),
            ['0'..'9','.'],
            ' '),
          ' ',
          '');
    if CountOfChar(ip,'.')<>3 then ip:='127.0.0.1';
    ipAndPort:=ip+':'+port;
  end;

FUNCTION cleanIp(CONST dirtyIp:ansistring):ansistring;
  VAR ip,port:string;
  begin
    result:=dirtyIp;
    cleanSocket(result,ip,port);
  end;

FUNCTION customSocketListenerThread(p:pointer):ptrint;
  begin
    P_customSocketListener(p)^.attend;
    dispose(P_customSocketListener(p),destroy);
    result:=0;
  end;

CONSTRUCTOR T_customSocketListener.create(CONST ipAndPort: string; CONST requestToResponseMapper_: F_stringToString);
  begin
    Socket.create(ipAndPort);
    requestToResponseMapper:=requestToResponseMapper_;
    killSignalled:=false;
    beginThread(@customSocketListenerThread,@self);
  end;

DESTRUCTOR T_customSocketListener.destroy;
  begin
    Socket.destroy;
  end;

PROCEDURE T_customSocketListener.attend;
  CONST minSleepTime=1;
        maxSleepTime=1000;
  VAR request:ansistring;
      sleepTime:longint=minSleepTime;
  begin
    repeat
      request:=Socket.getRequest;
      if request<>'' then begin
        Socket.SendString(requestToResponseMapper(request));
        sleepTime:=minSleepTime;
      end else begin
        sleep(sleepTime);
        inc(sleepTime);
        if sleepTime>maxSleepTime then sleepTime:=maxSleepTime;
      end;
    until killSignalled;
  end;

PROCEDURE T_customSocketListener.kill;
  begin
    killSignalled:=true;
  end;

CONSTRUCTOR T_socketPair.create(CONST ipAndPort: string);
  VAR ip,port:string;
  begin
    id:=ipAndPort;
    cleanSocket(id,ip,port);
    create(ip,port);
  end;

CONSTRUCTOR T_socketPair.create(CONST ip, port: string);
  begin
    ListenerSocket := TTCPBlockSocket.create;
    ConnectionSocket := TTCPBlockSocket.create;
    ListenerSocket.CreateSocket;
    ListenerSocket.setLinger(true,10);
    ListenerSocket.bind(ip,port);
    ListenerSocket.listen;
    id:=ip+':'+port;
    acceptingRequest:=false;
  end;

DESTRUCTOR T_socketPair.destroy;
  begin
    ListenerSocket.free;
    ConnectionSocket.free;
  end;

FUNCTION T_socketPair.getRequest(CONST timeOutInMilliseconds: longint): ansistring;
  VAR s:string;
  begin
    if acceptingRequest then sendString(HTTP_404_RESPONSE);
    if not(ListenerSocket.canread(timeOutInMilliseconds)) then exit('');
    ConnectionSocket.Socket := ListenerSocket.accept;
    acceptingRequest:=true;
    s := ConnectionSocket.RecvString(timeOutInMilliseconds);
    if s='' then exit('/');
    {method :=} fetch(s, ' ');
    result := fetch(s, ' ');
    {protocol :=} fetch(s, ' ');
    repeat
      s := ConnectionSocket.RecvString(timeOutInMilliseconds);
    until s = '';
  end;

PROCEDURE T_socketPair.sendString(CONST s: ansistring);
  begin
    ConnectionSocket.SendString(s);
    ConnectionSocket.CloseSocket;
    acceptingRequest:=false;
  end;

FUNCTION T_socketPair.toString: ansistring;
  begin
    result:=id;
  end;

end.
