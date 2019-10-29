UNIT httpUtil;
INTERFACE
USES Classes, blcksock, synautil, sysutils, myGenerics,myStringUtil;
TYPE
  T_httpRequestMethod=(htrm_no_request,htrm_GET,htrm_POST,htrm_HEAD,htrm_PUT,htrm_PATCH,htrm_DELETE,htrm_TRACE,htrm_OPTIONS,htrm_CONNECT);
CONST
  C_httpRequestMethodName:array[T_httpRequestMethod] of string=('','GET','POST','HEAD','PUT','PATCH','DELETE','TRACE','OPTIONS','CONNECT');
TYPE
  T_httpHeader=array of record key,value:string; end;

  T_httpRequest=record
    method:T_httpRequestMethod;
    request,protocol:string;
    header:T_httpHeader;
    body:string;
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
      FUNCTION getRequest(CONST timeOutInMilliseconds:longint=100):T_httpRequest;
      PROCEDURE sendString(CONST s:ansistring);
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
FUNCTION wrapTextInHttp(CONST data:string; CONST code:longint; CONST header:T_httpHeader):string;
FUNCTION cleanIp(CONST dirtyIp:ansistring):ansistring;
PROCEDURE setHeaderDefaults(VAR header:T_httpHeader; CONST contentLength:longint=0; CONST contentType:string=''; CONST serverInfo:string='');
IMPLEMENTATION
PROCEDURE disposeSocket(VAR socket:P_socketPair);
  begin
    dispose(socket,destroy);
  end;

CONST
  HP_Splitter=': ';
  HP_ContentType='Content-type';
  HP_ContentLength='Content-length';
  HP_Connection='Connection';
  HP_Date='Date';
  HP_Server='Server';

FUNCTION emptyHeader:T_httpHeader;
  begin setLength(result,0); end;

PROCEDURE setHeaderDefaults(VAR header:T_httpHeader; CONST contentLength:longint=0; CONST contentType:string=''; CONST serverInfo:string='');
  VAR i               :longint;
      idxContentType  :longint=-1;
      idxContentLength:longint=-1;
      hasConnection   :boolean=false;
      hasServer       :boolean=false;
      hasDate         :boolean=false;
  begin
    for i:=0 to length(header)-1 do begin
      if header[i].key=HP_ContentType then begin
        if contentType<>'' then header[i].value:=contentType;
        idxContentType:=i;
      end else if header[i].key=HP_ContentLength then begin
        if contentLength<>0 then header[i].value:=intToStr(contentLength);
        idxContentLength:=i;
      end else if header[i].key=HP_Connection then begin
        header[i].value:='close';
        hasConnection:=true;
      end else if header[i].key=HP_Server then begin
        hasServer:=true;
      end else if header[i].key=HP_Date then begin
        header[i].value:=Rfc822DateTime(now);
        hasDate:=true;
      end;
    end;
    if not(hasDate)                               then begin i:=length(header); setLength(header,i+1); header[i].key:=HP_Date;          header[i].value:=Rfc822DateTime(now);     end;
    if not(hasServer) and (serverInfo<>'')        then begin i:=length(header); setLength(header,i+1); header[i].key:=HP_Server;        header[i].value:=serverInfo;              end;
    if not(hasConnection)                         then begin i:=length(header); setLength(header,i+1); header[i].key:=HP_Connection;    header[i].value:='close';                 end;
    if (contentLength>0) and (idxContentLength<0) then begin i:=length(header); setLength(header,i+1); header[i].key:=HP_ContentLength; header[i].value:=intToStr(contentLength); end;
    if (contentType<>'') and (idxContentType  <0) then begin i:=length(header); setLength(header,i+1); header[i].key:=HP_ContentType;   header[i].value:=contentType;             end;
  end;

FUNCTION wrapTextInHttp(CONST OutputDataString,serverInfo: string; CONST contentType:string='Text/Html'): string;
  VAR header:T_httpHeader;
  begin
    header:=emptyHeader;
    setHeaderDefaults(header,length(OutputDataString),contentType,serverInfo);
    result:=wrapTextInHttp(OutputDataString,200,header);
  end;

FUNCTION wrapTextInHttp(CONST data:string; CONST code:longint; CONST header:T_httpHeader):string;
  FUNCTION headerToString:string;
    VAR i:longint;
    begin
      result:='';
      for i:=0 to length(header)-1 do result+=trim(header[i].key)+HP_Splitter+trim(header[i].value)+CRLF;
    end;
  begin
   result:='HTTP/1.0 '+intToStr(code) + CRLF +
           headerToString + CRLF +
           data;
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
  VAR request:T_httpRequest;
      sleepTime:longint=minSleepTime;
  begin
    repeat
      request:=socket.getRequest(sleepTime);
      if request.method=htrm_no_request then begin
        sleep(sleepTime);
        inc(sleepTime);
        if sleepTime>maxSleepTime then sleepTime:=maxSleepTime;
      end else begin
        socket.sendString(requestToResponseMapper(request.method,request.request,request.protocol));
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

FUNCTION T_socketPair.getRequest(CONST timeOutInMilliseconds: longint):T_httpRequest;
  VAR s:string;
      receiveTimeout:longint=100;

  FUNCTION parseTriplet(VAR s:string):T_httpRequest; inline;
    VAR temp:string;
        inputLine:string;
        htrm:T_httpRequestMethod;
    begin
      //initialize result
      result.method:=htrm_no_request;
      result.request:='';
      result.protocol:='';
      result.body:='';
      setLength(result.header,0);
      //Parse request line
      inputLine:=fetch(s,CRLF);
      temp:=fetch(inputLine,' ');
      for htrm in T_httpRequestMethod do if C_httpRequestMethodName[htrm]=temp then result.method:=htrm;
      if result.method=htrm_no_request then exit(result);
      result.request :=fetch(inputLine, ' ');
      result.protocol:=fetch(inputLine, ' ');
      //parse additional header entries
      inputLine:=fetch(s,CRLF);
      while inputLine<>'' do begin
        setLength(result.header,length(result.header)+1);
        with result.header[length(result.header)-1] do begin
          key:=fetch(inputLine,':');
          value:=trim(inputLine);
        end;
        inputLine:=fetch(s,CRLF);
      end;
      result.body:=s;
    end;

  begin
    result.method:=htrm_no_request;
    result.request:='';
    result.protocol:='';
    if acceptingRequest then sendString(HTTP_503_RESPONSE);
    if not(ListenerSocket.canread(timeOutInMilliseconds)) then exit(result);
    ConnectionSocket.socket := ListenerSocket.accept;
    repeat
      s := ConnectionSocket.RecvPacket(receiveTimeout);
      if result.method=htrm_no_request then begin
        result:=parseTriplet(s);
        if result.method<>htrm_no_request then receiveTimeout:=1;
      end;
    until ConnectionSocket.LastError<>0;
    acceptingRequest:=result.method<>htrm_no_request;
    if not(acceptingRequest) then sendString(HTTP_404_RESPONSE);
  end;

PROCEDURE T_socketPair.sendString(CONST s: ansistring);
  begin
    ConnectionSocket.sendString(s);
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
