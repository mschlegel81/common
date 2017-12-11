UNIT httpUtil;
INTERFACE
USES Classes, blcksock, synautil, sysutils, myGenerics,myStringUtil;
TYPE
  T_httpRequestMethod=(htrm_no_request,htrm_GET,htrm_POST,htrm_HEAD,htrm_PUT,htrm_PATCH,htrm_DELETE,htrm_TRACE,htrm_OPTIONS,htrm_CONNECT);
CONST
  C_httpRequestMethodName:array[T_httpRequestMethod] of string=('','GET','POST','HEAD','PUT','PATCH','DELETE','TRACE','OPTIONS','CONNECT');
TYPE
  T_requestTriplet=record
    method:T_httpRequestMethod;
    request,protocol:string;
  end;

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
      FUNCTION getRequest(CONST timeOutInMilliseconds:longint=100):T_requestTriplet;
      PROCEDURE SendString(CONST s:ansistring);
      FUNCTION toString:ansistring;
      FUNCTION getLastListenerSocketError:longint;
      PROPERTY isAcceptingRequest:boolean read acceptingRequest;
  end;

  F_stringX3ToString=FUNCTION(CONST method:T_httpRequestMethod; CONST request,protocol:string):string;

  P_customSocketListener=^T_customSocketListener;
  T_customSocketListener=object
    private
      socket:T_socketPair;
      requestToResponseMapper:F_stringX3ToString;
      killSignalled:boolean;
    public
      CONSTRUCTOR create(CONST ipAndPort:string; CONST requestToResponseMapper_:F_stringX3ToString);
      DESTRUCTOR destroy;
      PROCEDURE attend;
      PROCEDURE kill;
  end;

CONST HTTP_404_RESPONSE='HTTP/1.0 404' + CRLF;
      HTTP_503_RESPONSE='HTTP/1.0 503' + CRLF + 'Retry-After: 10' + CRLF;

FUNCTION wrapTextInHttp(CONST OutputDataString,serverInfo:string; CONST contentType:string='Text/Html'):string;
FUNCTION cleanIp(CONST dirtyIp:ansistring):ansistring;
IMPLEMENTATION
PROCEDURE disposeSocket(VAR socket:P_socketPair);
  begin
    dispose(socket,destroy);
  end;

FUNCTION wrapTextInHttp(CONST OutputDataString,serverInfo: string; CONST contentType:string='Text/Html'): string;
  begin
    result:='HTTP/1.0 200' + CRLF +
            'Content-type: '+ contentType + CRLF +
            'Content-length: ' + intToStr(length(OutputDataString)) + CRLF +
            'Connection: close' + CRLF +
            'Date: ' + Rfc822DateTime(now) + CRLF +
            'Server: '+serverInfo + CRLF +
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

CONSTRUCTOR T_customSocketListener.create(CONST ipAndPort: string; CONST requestToResponseMapper_: F_stringX3ToString);
  begin
    socket.create(ipAndPort);
    requestToResponseMapper:=requestToResponseMapper_;
    killSignalled:=false;
    beginThread(@customSocketListenerThread,@self);
  end;

DESTRUCTOR T_customSocketListener.destroy;
  begin
    socket.destroy;
  end;

PROCEDURE T_customSocketListener.attend;
  CONST minSleepTime=1;
        maxSleepTime=100;
  VAR request:T_requestTriplet;
      sleepTime:longint=minSleepTime;
  begin
    repeat
      request:=socket.getRequest(sleepTime);
      if request.method=htrm_no_request then begin
        sleep(sleepTime);
        inc(sleepTime);
        if sleepTime>maxSleepTime then sleepTime:=maxSleepTime;
      end else begin
        socket.SendString(requestToResponseMapper(request.method,request.request,request.protocol));
        sleepTime:=minSleepTime;
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
    ListenerSocket.setLinger(true,1);
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

FUNCTION T_socketPair.getRequest(CONST timeOutInMilliseconds: longint):T_requestTriplet;
  VAR s:string;
      receiveTimeout:longint=100;

  FUNCTION parseTriplet(VAR s:string):T_requestTriplet; inline;
    VAR methodPart:string;
        htrm:T_httpRequestMethod;
    begin
      methodPart:=fetch(s,' ');
      result.method:=htrm_no_request;
      result.request:='';
      result.protocol:='';
      for htrm in T_httpRequestMethod do if C_httpRequestMethodName[htrm]=methodPart then result.method:=htrm;
      if result.method=htrm_no_request then exit(result);
      result.request :=fetch(s, ' ');
      result.protocol:=fetch(s, ' ');
    end;

  begin
    result.method:=htrm_no_request;
    result.request:='';
    result.protocol:='';
    if acceptingRequest then SendString(HTTP_503_RESPONSE);
    if not(ListenerSocket.canread(timeOutInMilliseconds)) then exit(result);
    ConnectionSocket.socket := ListenerSocket.accept;
    repeat
      s := ConnectionSocket.RecvString(receiveTimeout);
      if result.method=htrm_no_request then begin
        result:=parseTriplet(s);
        if result.method<>htrm_no_request then receiveTimeout:=1;
      end;
    until ConnectionSocket.LastError<>0;
    acceptingRequest:=result.method<>htrm_no_request;
    if not(acceptingRequest) then SendString(HTTP_404_RESPONSE);
  end;

PROCEDURE T_socketPair.SendString(CONST s: ansistring);
  begin
    ConnectionSocket.SendString(s);
    ConnectionSocket.CloseSocket;
    acceptingRequest:=false;
  end;

FUNCTION T_socketPair.toString: ansistring;
  begin
    result:=id;
  end;

FUNCTION T_socketPair.getLastListenerSocketError:longint;
  begin
    result:=ListenerSocket.LastError;
  end;

end.
