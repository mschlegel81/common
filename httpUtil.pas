UNIT httpUtil;
INTERFACE
USES Classes, blcksock, synautil, sysutils, myGenerics,myStringUtil,synsock;
TYPE
  T_httpRequestMethod=(htrm_no_request,htrm_GET,htrm_POST,htrm_HEAD,htrm_PUT,htrm_PATCH,htrm_DELETE,htrm_TRACE,htrm_OPTIONS,htrm_CONNECT);
CONST
  C_httpRequestMethodName:array[T_httpRequestMethod] of string=('','GET','POST','HEAD','PUT','PATCH','DELETE','TRACE','OPTIONS','CONNECT');
TYPE
  T_httpHeader=array of record key,value:string; end;

  P_httpListener=^T_httpListener;
  P_httpConnectionForRequest=^T_httpConnectionForRequest;
  T_httpConnectionForRequest=object
    private
      //parent listener
      relatedListener:P_httpListener;
      //connection for this request
      ConnectionSocket: TTCPBlockSocket;
      //data parsed from request
      method:T_httpRequestMethod;
      request,protocol:string;
      header:T_httpHeader;
      body:string;
    public
      CONSTRUCTOR create(CONST conn:TSocket; CONST parent:P_httpListener);
      DESTRUCTOR destroy;
      PROCEDURE sendStringAndClose(CONST s:ansistring);
      //Read only access to parsed http fields
      PROPERTY getMethod:T_httpRequestMethod read method;
      PROPERTY getRequest :string            read request;
      PROPERTY getProtocol:string            read protocol;
      PROPERTY getHeader  :T_httpHeader      read header;
      PROPERTY getBody    :string            read body;
  end;

  T_httpListener=object
    private
      ListenerSocket: TTCPBlockSocket;
      id:ansistring;
      maxConnections:longint;
      openConnections:longint;
    public
      CONSTRUCTOR create(CONST ipAndPort:string; CONST maxConnections_:longint=8);
      CONSTRUCTOR create(CONST ip,port:string; CONST maxConnections_:longint=8);
      DESTRUCTOR destroy;
      FUNCTION getRequest(CONST timeOutInMilliseconds:longint=100):P_httpConnectionForRequest;
      FUNCTION getRawRequestSocket(CONST timeOutInMilliseconds:longint=100):TSocket;
      FUNCTION toString:ansistring;
      FUNCTION getLastListenerSocketError:longint;
  end;

CONST HTTP_404_RESPONSE='HTTP/1.0 404' + CRLF;
      HTTP_503_RESPONSE='HTTP/1.0 503' + CRLF + 'Retry-After: 10' + CRLF;

FUNCTION wrapTextInHttp(CONST OutputDataString,serverInfo:string; CONST contentType:string='Text/Html'):string;
FUNCTION wrapTextInHttp(CONST data:string; CONST code:longint; CONST header:T_httpHeader):string;
FUNCTION cleanIp(CONST dirtyIp:ansistring):ansistring;
PROCEDURE setHeaderDefaults(VAR header:T_httpHeader; CONST contentLength:longint=0; CONST contentType:string=''; CONST serverInfo:string='');
IMPLEMENTATION
USES strutils;
PROCEDURE disposeSocket(VAR socket:P_httpListener);
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
  emptyHeader:T_httpHeader=();

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
    ip:=ansiReplaceStr(
          cleanString(
            ansiReplaceStr(
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

CONSTRUCTOR T_httpConnectionForRequest.create(CONST conn: TSocket; CONST parent: P_httpListener);
  PROCEDURE parseTriplet(VAR s:string);
    VAR temp:string;
        inputLine:string;
        htrm:T_httpRequestMethod;
    begin
      //initialize result
      method:=htrm_no_request;
      request:='';
      protocol:='';
      body:='';
      setLength(header,0);
      //Parse request line
      inputLine:=fetch(s,CRLF);
      temp:=fetch(inputLine,' ');
      for htrm in T_httpRequestMethod do if C_httpRequestMethodName[htrm]=temp then method:=htrm;
      if method=htrm_no_request then exit;
      request :=fetch(inputLine, ' ');
      protocol:=fetch(inputLine, ' ');
      //parse additional header entries
      inputLine:=fetch(s,CRLF);
      while inputLine<>'' do begin
        setLength(header,length(header)+1);
        with header[length(header)-1] do begin
          key:=fetch(inputLine,':');
          value:=trim(inputLine);
        end;
        inputLine:=fetch(s,CRLF);
      end;
      body:=s;
    end;

  VAR s:string;
      receiveTimeout:longint=2000;
  begin
    relatedListener:=parent;
    ConnectionSocket := TTCPBlockSocket.create;
    ConnectionSocket.socket:=conn;
    ConnectionSocket.GetSins;
    repeat
      s := ConnectionSocket.RecvPacket(receiveTimeout);
      if method=htrm_no_request then begin
        parseTriplet(s);
        if method<>htrm_no_request then receiveTimeout:=1;
      end;
    until ConnectionSocket.LastError<>0;
  end;

DESTRUCTOR T_httpConnectionForRequest.destroy;
  begin
    ConnectionSocket.free;
  end;

PROCEDURE T_httpConnectionForRequest.sendStringAndClose(CONST s: ansistring);
  begin
    ConnectionSocket.sendString(s);
    ConnectionSocket.CloseSocket;
    interlockedDecrement(relatedListener^.openConnections);
  end;

CONSTRUCTOR T_httpListener.create(CONST ipAndPort: string; CONST maxConnections_:longint=8);
  VAR ip,port:string;
  begin
    id:=ipAndPort;
    cleanSocket(id,ip,port);
    create(ip,port,maxConnections_);
  end;

CONSTRUCTOR T_httpListener.create(CONST ip, port: string; CONST maxConnections_:longint=8);
  begin
    ListenerSocket := TTCPBlockSocket.create;
    ListenerSocket.CreateSocket;
    ListenerSocket.setLinger(true,100);
    ListenerSocket.bind(ip,port);
    ListenerSocket.listen;
    id:=ip+':'+port;
    maxConnections:=maxConnections_;
    openConnections:=0;
  end;

DESTRUCTOR T_httpListener.destroy;
  VAR shutdownTimeout:double;
  begin
    shutdownTimeout:=now+1/(24*60*60);
    ListenerSocket.CloseSocket;
    ListenerSocket.free;
    while (openConnections>0) and (now<shutdownTimeout) do sleep(1);
  end;

FUNCTION T_httpListener.getRequest(CONST timeOutInMilliseconds: longint):P_httpConnectionForRequest;
  begin
    if not(ListenerSocket.canread(timeOutInMilliseconds)) then exit(nil);
    new(result,create(ListenerSocket.accept,@self));
    interLockedIncrement(openConnections);
    if result^.getMethod=htrm_no_request then begin
      result^.sendStringAndClose(HTTP_404_RESPONSE);
      dispose(result,destroy);
      result:=nil;
    end else while openConnections>maxConnections do sleep(1);
  end;

FUNCTION T_httpListener.getRawRequestSocket(CONST timeOutInMilliseconds:longint=100):TSocket;
  begin
    if not(ListenerSocket.canread(timeOutInMilliseconds))
    then exit(0)
    else begin
      interLockedIncrement(openConnections);
      result:=ListenerSocket.accept;
      while openConnections>maxConnections do sleep(1);
    end;
  end;

FUNCTION T_httpListener.toString: ansistring;
  begin
    result:=id;
  end;

FUNCTION T_httpListener.getLastListenerSocketError:longint;
  begin
    result:=ListenerSocket.LastError;
  end;

end.
