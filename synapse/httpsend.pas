{==============================================================================|
| project : Ararat Synapse                                       | 003.012.006 |
|==============================================================================|
| content: HTTP Client                                                         |
|==============================================================================|
| Copyright (c)1999-2011, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2011.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(HTTP protocol client)

used RFC: RFC-1867, RFC-1947, RFC-2388, RFC-2616
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
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

UNIT httpsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, synaip, synacode, synsock;

CONST
  cHttpProtocol = '80';

TYPE
  {:These encoding types are used internally by the THTTPSend object to identify
   the transfer data types.}
  TTransferEncoding = (TE_UNKNOWN, TE_IDENTITY, TE_CHUNKED);

  {:abstract(Implementation of HTTP protocol.)}
  THTTPSend = class(TSynaClient)
  protected
    FSock: TTCPBlockSocket;
    FTransferEncoding: TTransferEncoding;
    FAliveHost: string;
    FAlivePort: string;
    FHeaders: TStringList;
    FDocument: TMemoryStream;
    FMimeType: string;
    FProtocol: string;
    FKeepAlive: boolean;
    FKeepAliveTimeout: integer;
    FStatus100: boolean;
    FProxyHost: string;
    FProxyPort: string;
    FProxyUser: string;
    FProxyPass: string;
    FResultCode: integer;
    FResultString: string;
    FUserAgent: string;
    FCookies: TStringList;
    FDownloadSize: integer;
    FUploadSize: integer;
    FRangeStart: integer;
    FRangeEnd: integer;
    FAddPortNumberToHost: boolean;
    FUNCTION ReadUnknown: boolean;
    FUNCTION ReadIdentity(size: integer): boolean;
    FUNCTION ReadChunked: boolean;
    PROCEDURE ParseCookies;
    FUNCTION PrepareHeaders: ansistring;
    FUNCTION InternalDoConnect(needssl: boolean): boolean;
    FUNCTION InternalConnect(needssl: boolean): boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Reset headers and document and Mimetype.}
    PROCEDURE clear;

    {:Decode ResultCode and ResultString from Value.}
    PROCEDURE DecodeStatus(CONST value: string);

    {:Connects to host define in URL and access to resource defined in URL by
     method. if Document is not empty, send it to Server as part of HTTP request.
     Server response is in Document and headers. Connection may be authorised
     by username and password in URL. if you define proxy properties, connection
     is made by this proxy. if all ok, result is @true, else result is @false.

     if you use in URL 'https:' instead only 'http:', then your request is made
     by SSL/TLS connection (if you not specify port, then port 443 is used
     instead standard port 80). if you use SSL/TLS request and you have defined
     HTTP proxy, then HTTP-tunnel mode is automaticly used .}
    FUNCTION HTTPMethod(CONST Method, URL: string): boolean;

    {:You can call this method from OnStatus event for break current data
     transfer. (or from another thread.)}
    PROCEDURE Abort;
  Published
    {:Before HTTP operation you may define any non-standard headers for HTTP
     request, except of: 'Expect: 100-continue', 'Content-Length', 'Content-Type',
     'Connection', 'Authorization', 'Proxy-Authorization' and 'Host' headers.
     After HTTP operation contains full headers of returned document.}
    PROPERTY Headers: TStringList read FHeaders;

    {:This is stringlist with name-value stringlist pairs. Each this pair is one
     cookie. After HTTP request is returned cookies parsed to this stringlist.
     You can leave this cookies untouched for next HTTP request. You can also
     save this stringlist for later use.}
    PROPERTY Cookies: TStringList read FCookies;

    {:Stream with document to send (before request, or with document received
     from HTTP Server (after request).}
    PROPERTY Document: TMemoryStream read FDocument;

    {:If you need download only part of requested document, here specify
     possition of subpart begin. if here 0, then is requested full document.}
    PROPERTY RangeStart: integer read FRangeStart write FRangeStart;

    {:If you need download only part of requested document, here specify
     possition of subpart end. if here 0, then is requested document from
     rangeStart to end of document. (for broken download restoration,
     for example.)}
    PROPERTY RangeEnd: integer read FRangeEnd write FRangeEnd;

    {:Mime type of sending data. Default is: 'text/html'.}
    PROPERTY MimeType: string read FMimeType write FMimeType;

    {:Define protocol version. Possible values are: '1.1', '1.0' (default)
     and '0.9'.}
    PROPERTY Protocol: string read FProtocol write FProtocol;

    {:If @true (default value), keepalives in HTTP protocol 1.1 is enabled.}
    PROPERTY KeepAlive: boolean read FKeepAlive write FKeepAlive;

    {:Define timeout for keepalives in seconds!}
    PROPERTY KeepAliveTimeout: integer read FKeepAliveTimeout write FKeepAliveTimeout;

    {:if @true, then server is requested for 100status capability when uploading
     data. default is @false (off).}
    PROPERTY Status100: boolean read FStatus100 write FStatus100;

    {:Address of proxy server (IP address or domain name) where you want to
     connect in @link(HTTPMethod) method.}
    PROPERTY ProxyHost: string read FProxyHost write FProxyHost;

    {:Port number for proxy connection. Default value is 8080.}
    PROPERTY ProxyPort: string read FProxyPort write FProxyPort;

    {:Username for connect to proxy server where you want to connect in
     HTTPMethod method.}
    PROPERTY ProxyUser: string read FProxyUser write FProxyUser;

    {:Password for connect to proxy server where you want to connect in
     HTTPMethod method.}
    PROPERTY ProxyPass: string read FProxyPass write FProxyPass;

    {:Here you can specify custom User-Agent indentification. By default is
     used: 'Mozilla/4.0 (compatible; Synapse)'}
    PROPERTY UserAgent: string read FUserAgent write FUserAgent;

    {:After successful @link(HTTPMethod) method contains result code of
     operation.}
    PROPERTY ResultCode: integer read FResultCode;

    {:After successful @link(HTTPMethod) method contains string after result code.}
    PROPERTY resultString: string read FResultString;

    {:if this value is not 0, then data download pending. In this case you have
     here total sice of downloaded data. it is good for draw download
     progressbar from OnStatus event.}
    PROPERTY DownloadSize: integer read FDownloadSize;

    {:if this value is not 0, then data upload pending. In this case you have
     here total sice of uploaded data. it is good for draw upload progressbar
     from OnStatus event.}
    PROPERTY UploadSize: integer read FUploadSize;
    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;

    {:To have possibility to switch off port number in 'Host:' HTTP header, by
    default @true. Some buggy servers not like port informations in this header.}
    PROPERTY AddPortNumberToHost: boolean read FAddPortNumberToHost write FAddPortNumberToHost;
  end;

{:A very usefull function, and example of use can be found in the THTTPSend
 object. it implements the get method of the HTTP protocol. This FUNCTION sends
 the get method for URL document to an HTTP Server. Returned document is in the
 "Response" stringlist (without any headers). Returns boolean true if all went
 well.}
FUNCTION HttpGetText(CONST URL: string; CONST Response: TStrings): boolean;

{:A very usefull function, and example of use can be found in the THTTPSend
 object. it implements the get method of the HTTP protocol. This FUNCTION sends
 the get method for URL document to an HTTP Server. Returned document is in the
 "Response" stream. Returns boolean true if all went well.}
FUNCTION HttpGetBinary(CONST URL: string; CONST Response: TStream): boolean;

{:A very useful function, and example of use can be found in the THTTPSend
 object. it implements the POST method of the HTTP protocol. This FUNCTION sends
 the SEND method for a URL document to an HTTP Server. the document to be sent
 is located in "data" stream. the returned document is in the "data" stream.
 Returns boolean true if all went well.}
FUNCTION HttpPostBinary(CONST URL: string; CONST data: TStream): boolean;

{:A very useful function, and example of use can be found in the THTTPSend
 object. it implements the POST method of the HTTP protocol. This FUNCTION is
 good for POSTing form data. it sends the POST method for a URL document to
 an HTTP Server. You must prepare the form data in the same manner as you would
 the URL data, and pass this prepared data to "URLdata". the following is
 a sample of how the data would appear: 'name=Lukas&field1=some%20data'.
 the information in the field must be encoded by EncodeURLElement FUNCTION.
 the returned document is in the "data" stream. Returns boolean true if all
 went well.}
FUNCTION HttpPostURL(CONST URL, URLData: string; CONST data: TStream): boolean;

{:A very useful function, and example of use can be found in the THTTPSend
 object. it implements the POST method of the HTTP protocol. This FUNCTION sends
 the POST method for a URL document to an HTTP Server. This FUNCTION simulate
 posting of file by html form used method 'multipart/form-data'. Posting file
 is in data stream. Its name is fileName string. Fieldname is for name of
 formular field with file. (simulate html input file) the returned document is
 in the ResultData Stringlist. Returns boolean true if all went well.}
FUNCTION HttpPostFile(CONST URL, FieldName, fileName: string;
  CONST data: TStream; CONST ResultData: TStrings): boolean;

IMPLEMENTATION

CONSTRUCTOR THTTPSend.create;
begin
  inherited create;
  FHeaders := TStringList.create;
  FCookies := TStringList.create;
  FDocument := TMemoryStream.create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.ConvertLineEnd := true;
  FSock.SizeRecvBuffer := c64k;
  FSock.SizeSendBuffer := c64k;
  FTimeout := 90000;
  FTargetPort := cHttpProtocol;
  FProxyHost := '';
  FProxyPort := '8080';
  FProxyUser := '';
  FProxyPass := '';
  FAliveHost := '';
  FAlivePort := '';
  FProtocol := '1.0';
  FKeepAlive := true;
  FStatus100 := false;
  FUserAgent := 'Mozilla/4.0 (compatible; Synapse)';
  FDownloadSize := 0;
  FUploadSize := 0;
  FAddPortNumberToHost := true;
  FKeepAliveTimeout := 300;
  clear;
end;

DESTRUCTOR THTTPSend.destroy;
begin
  FSock.free;
  FDocument.free;
  FCookies.free;
  FHeaders.free;
  inherited destroy;
end;

PROCEDURE THTTPSend.clear;
begin
  FRangeStart := 0;
  FRangeEnd := 0;
  FDocument.clear;
  FHeaders.clear;
  FMimeType := 'text/html';
end;

PROCEDURE THTTPSend.DecodeStatus(CONST value: string);
VAR
  s, su: string;
begin
  s := trim(SeparateRight(value, ' '));
  su := trim(SeparateLeft(s, ' '));
  FResultCode := strToIntDef(su, 0);
  FResultString := trim(SeparateRight(s, ' '));
  if FResultString = s then
    FResultString := '';
end;

FUNCTION THTTPSend.PrepareHeaders: ansistring;
begin
  if FProtocol = '0.9' then
    result := FHeaders[0] + CRLF
  else
{$IFNDEF MSWINDOWS}
    result := {$IFDEF UNICODE}ansistring{$ENDIF}(AdjustLineBreaks(FHeaders.text, tlbsCRLF));
{$ELSE}
    result := FHeaders.text;
{$ENDIF}
end;

FUNCTION THTTPSend.InternalDoConnect(needssl: boolean): boolean;
begin
  result := false;
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError <> 0 then
    exit;
  FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError <> 0 then
    exit;
  if needssl then
  begin
    if (FSock.SSL.SNIHost='') then
      FSock.SSL.SNIHost:=FTargetHost;
    FSock.SSLDoConnect;
    FSock.SSL.SNIHost:=''; //don't need it anymore and don't wan't to reuse it in next connection
    if FSock.LastError <> 0 then
      exit;
  end;
  FAliveHost := FTargetHost;
  FAlivePort := FTargetPort;
  result := true;
end;

FUNCTION THTTPSend.InternalConnect(needssl: boolean): boolean;
begin
  if FSock.Socket = INVALID_SOCKET then
    result := InternalDoConnect(needssl)
  else
    if (FAliveHost <> FTargetHost) or (FAlivePort <> FTargetPort)
      or FSock.CanRead(0) then
      result := InternalDoConnect(needssl)
    else
      result := true;
end;

FUNCTION THTTPSend.HTTPMethod(CONST Method, URL: string): boolean;
VAR
  Sending, Receiving: boolean;
  status100: boolean;
  status100error: string;
  ToClose: boolean;
  size: integer;
  Prot, User, Pass, Host, Port, path, Para, URI: string;
  s, su: ansistring;
  HttpTunnel: boolean;
  n: integer;
  pp: string;
  UsingProxy: boolean;
  l: TStringList;
  x: integer;
begin
  {initial values}
  result := false;
  FResultCode := 500;
  FResultString := '';
  FDownloadSize := 0;
  FUploadSize := 0;

  URI := ParseURL(URL, Prot, User, Pass, Host, Port, path, Para);
  User := DecodeURL(user);
  Pass := DecodeURL(pass);
  if User = '' then
  begin
    User := FUsername;
    Pass := FPassword;
  end;
  if uppercase(Prot) = 'HTTPS' then
  begin
    HttpTunnel := FProxyHost <> '';
    FSock.HTTPTunnelIP := FProxyHost;
    FSock.HTTPTunnelPort := FProxyPort;
    FSock.HTTPTunnelUser := FProxyUser;
    FSock.HTTPTunnelPass := FProxyPass;
  end
  else
  begin
    HttpTunnel := false;
    FSock.HTTPTunnelIP := '';
    FSock.HTTPTunnelPort := '';
    FSock.HTTPTunnelUser := '';
    FSock.HTTPTunnelPass := '';
  end;
  UsingProxy := (FProxyHost <> '') and not(HttpTunnel);
  Sending := FDocument.size > 0;
  {Headers for Sending data}
  status100 := FStatus100 and Sending and (FProtocol = '1.1');
  if status100 then
    FHeaders.Insert(0, 'Expect: 100-continue');
  if Sending then
  begin
    FHeaders.Insert(0, 'Content-Length: ' + intToStr(FDocument.size));
    if FMimeType <> '' then
      FHeaders.Insert(0, 'Content-Type: ' + FMimeType);
  end;
  { setting User-agent }
  if FUserAgent <> '' then
    FHeaders.Insert(0, 'User-Agent: ' + FUserAgent);
  { setting Ranges }
  if (FRangeStart > 0) or (FRangeEnd > 0) then
  begin
    if FRangeEnd >= FRangeStart then
      FHeaders.Insert(0, 'Range: bytes=' + intToStr(FRangeStart) + '-' + intToStr(FRangeEnd))
    else
      FHeaders.Insert(0, 'Range: bytes=' + intToStr(FRangeStart) + '-');
  end;
  { setting Cookies }
  s := '';
  for n := 0 to FCookies.count - 1 do
  begin
    if s <> '' then
      s := s + '; ';
    s := s + FCookies[n];
  end;
  if s <> '' then
    FHeaders.Insert(0, 'Cookie: ' + s);
  { setting KeepAlives }
  pp := '';
  if UsingProxy then
    pp := 'Proxy-';
  if FKeepAlive then
  begin
    FHeaders.Insert(0, pp + 'Connection: keep-alive');
    FHeaders.Insert(0, 'Keep-Alive: ' + intToStr(FKeepAliveTimeout));
  end
  else
    FHeaders.Insert(0, pp + 'Connection: close');
  { set target servers/proxy, authorizations, etc... }
  if User <> '' then
    FHeaders.Insert(0, 'Authorization: Basic ' + EncodeBase64(User + ':' + Pass));
  if UsingProxy and (FProxyUser <> '') then
    FHeaders.Insert(0, 'Proxy-Authorization: Basic ' +
      EncodeBase64(FProxyUser + ':' + FProxyPass));
  if isIP6(Host) then
    s := '[' + Host + ']'
  else
    s := Host;
  if FAddPortNumberToHost and (Port <> '80') then
     FHeaders.Insert(0, 'Host: ' + s + ':' + Port)
  else
     FHeaders.Insert(0, 'Host: ' + s);
  if UsingProxy then
    URI := Prot + '://' + s + ':' + Port + URI;
  if URI = '/*' then
    URI := '*';
  if FProtocol = '0.9' then
    FHeaders.Insert(0, uppercase(Method) + ' ' + URI)
  else
    FHeaders.Insert(0, uppercase(Method) + ' ' + URI + ' HTTP/' + FProtocol);
  if UsingProxy then
  begin
    FTargetHost := FProxyHost;
    FTargetPort := FProxyPort;
  end
  else
  begin
    FTargetHost := Host;
    FTargetPort := Port;
  end;
  if FHeaders[FHeaders.count - 1] <> '' then
    FHeaders.add('');

  { connect }
  if not InternalConnect(uppercase(Prot) = 'HTTPS') then
  begin
    FAliveHost := '';
    FAlivePort := '';
    exit;
  end;

  { reading Status }
  FDocument.position := 0;
  Status100Error := '';
  if status100 then
  begin
    { send Headers }
    FSock.SendString(PrepareHeaders);
    if FSock.LastError <> 0 then
      exit;
    repeat
      s := FSock.RecvString(FTimeout);
      if s <> '' then
        break;
    until FSock.LastError <> 0;
    DecodeStatus(s);
    Status100Error := s;
    repeat
      s := FSock.recvstring(FTimeout);
      if s = '' then
        break;
    until FSock.LastError <> 0;
    if (FResultCode >= 100) and (FResultCode < 200) then
    begin
      { we can upload content }
      Status100Error := '';
      FUploadSize := FDocument.size;
      FSock.SendBuffer(FDocument.memory, FDocument.size);
    end;
  end
  else
    { upload content }
    if sending then
    begin
      if FDocument.size >= c64k then
      begin
        FSock.SendString(PrepareHeaders);
        FUploadSize := FDocument.size;
        FSock.SendBuffer(FDocument.memory, FDocument.size);
      end
      else
      begin
        s := PrepareHeaders + ReadStrFromStream(FDocument, FDocument.size);
        FUploadSize := length(s);
        FSock.SendString(s);
      end;
    end
    else
    begin
      { we not need to upload document, send headers only }
      FSock.SendString(PrepareHeaders);
    end;

  if FSock.LastError <> 0 then
    exit;

  clear;
  size := -1;
  FTransferEncoding := TE_UNKNOWN;

  { read status }
  if Status100Error = '' then
  begin
    repeat
      repeat
        s := FSock.RecvString(FTimeout);
        if s <> '' then
          break;
      until FSock.LastError <> 0;
      if pos('HTTP/', uppercase(s)) = 1 then
      begin
        FHeaders.add(s);
        DecodeStatus(s);
      end
      else
      begin
        { old HTTP 0.9 and some buggy servers not send result }
        s := s + CRLF;
        WriteStrToStream(FDocument, s);
        FResultCode := 0;
      end;
    until (FSock.LastError <> 0) or (FResultCode <> 100);
  end
  else
    FHeaders.add(Status100Error);

  { if need receive headers, receive and parse it }
  ToClose := FProtocol <> '1.1';
  if FHeaders.count > 0 then
  begin
    l := TStringList.create;
    try
      repeat
        s := FSock.RecvString(FTimeout);
        l.add(s);
        if s = '' then
          break;
      until FSock.LastError <> 0;
      x := 0;
      while l.count > x do
      begin
        s := NormalizeHeader(l, x);
        FHeaders.add(s);
        su := uppercase(s);
        if pos('CONTENT-LENGTH:', su) = 1 then
        begin
          size := strToIntDef(trim(SeparateRight(s, ' ')), -1);
          if (size <> -1) and (FTransferEncoding = TE_UNKNOWN) then
            FTransferEncoding := TE_IDENTITY;
        end;
        if pos('CONTENT-TYPE:', su) = 1 then
          FMimeType := trim(SeparateRight(s, ' '));
        if pos('TRANSFER-ENCODING:', su) = 1 then
        begin
          s := trim(SeparateRight(su, ' '));
          if pos('CHUNKED', s) > 0 then
            FTransferEncoding := TE_CHUNKED;
        end;
        if UsingProxy then
        begin
          if pos('PROXY-CONNECTION:', su) = 1 then
            if pos('CLOSE', su) > 0 then
              ToClose := true;
        end
        else
        begin
          if pos('CONNECTION:', su) = 1 then
            if pos('CLOSE', su) > 0 then
              ToClose := true;
        end;
      end;
    finally
      l.free;
    end;
  end;

  result := FSock.LastError = 0;
  if not result then
    exit;

  {if need receive response body, read it}
  Receiving := Method <> 'HEAD';
  Receiving := Receiving and (FResultCode <> 204);
  Receiving := Receiving and (FResultCode <> 304);
  if Receiving then
    case FTransferEncoding of
      TE_UNKNOWN:
        result := ReadUnknown;
      TE_IDENTITY:
        result := ReadIdentity(size);
      TE_CHUNKED:
        result := ReadChunked;
    end;

  FDocument.Seek(0, soFromBeginning);
  if ToClose then
  begin
    FSock.CloseSocket;
    FAliveHost := '';
    FAlivePort := '';
  end;
  ParseCookies;
end;

FUNCTION THTTPSend.ReadUnknown: boolean;
VAR
  s: ansistring;
begin
  result := false;
  repeat
    s := FSock.RecvPacket(FTimeout);
    if FSock.LastError = 0 then
      WriteStrToStream(FDocument, s);
  until FSock.LastError <> 0;
  if FSock.LastError = WSAECONNRESET then
  begin
    result := true;
    FSock.ResetLastError;
  end;
end;

FUNCTION THTTPSend.ReadIdentity(size: integer): boolean;
begin
  if size > 0 then
  begin
    FDownloadSize := size;
    FSock.RecvStreamSize(FDocument, FTimeout, size);
    FDocument.position := FDocument.size;
    result := FSock.LastError = 0;
  end
  else
    result := true;
end;

FUNCTION THTTPSend.ReadChunked: boolean;
VAR
  s: ansistring;
  size: integer;
begin
  repeat
    repeat
      s := FSock.RecvString(FTimeout);
    until (s <> '') or (FSock.LastError <> 0);
    if FSock.LastError <> 0 then
      break;
    s := trim(SeparateLeft(s, ' '));
    s := trim(SeparateLeft(s, ';'));
    size := strToIntDef('$' + s, 0);
    if size = 0 then
      break;
    if not ReadIdentity(size) then
      break;
  until false;
  result := FSock.LastError = 0;
end;

PROCEDURE THTTPSend.ParseCookies;
VAR
  n: integer;
  s: string;
  sn, sv: string;
begin
  for n := 0 to FHeaders.count - 1 do
    if pos('set-cookie:', lowercase(FHeaders[n])) = 1 then
    begin
      s := SeparateRight(FHeaders[n], ':');
      s := trim(SeparateLeft(s, ';'));
      sn := trim(SeparateLeft(s, '='));
      sv := trim(SeparateRight(s, '='));
      FCookies.values[sn] := sv;
    end;
end;

PROCEDURE THTTPSend.Abort;
begin
  FSock.StopFlag := true;
end;

{==============================================================================}

FUNCTION HttpGetText(CONST URL: string; CONST Response: TStrings): boolean;
VAR
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.create;
  try
    result := HTTP.HTTPMethod('GET', URL);
    if result then
      Response.LoadFromStream(HTTP.Document);
  finally
    HTTP.free;
  end;
end;

FUNCTION HttpGetBinary(CONST URL: string; CONST Response: TStream): boolean;
VAR
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.create;
  try
    result := HTTP.HTTPMethod('GET', URL);
    if result then
    begin
      Response.Seek(0, soFromBeginning);
      Response.CopyFrom(HTTP.Document, 0);
    end;
  finally
    HTTP.free;
  end;
end;

FUNCTION HttpPostBinary(CONST URL: string; CONST data: TStream): boolean;
VAR
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.create;
  try
    HTTP.Document.CopyFrom(data, 0);
    HTTP.MimeType := 'Application/octet-stream';
    result := HTTP.HTTPMethod('POST', URL);
    data.size := 0;
    if result then
    begin
      data.Seek(0, soFromBeginning);
      data.CopyFrom(HTTP.Document, 0);
    end;
  finally
    HTTP.free;
  end;
end;

FUNCTION HttpPostURL(CONST URL, URLData: string; CONST data: TStream): boolean;
VAR
  HTTP: THTTPSend;
begin
  HTTP := THTTPSend.create;
  try
    WriteStrToStream(HTTP.Document, URLData);
    HTTP.MimeType := 'application/x-www-form-urlencoded';
    result := HTTP.HTTPMethod('POST', URL);
    if result then
      data.CopyFrom(HTTP.Document, 0);
  finally
    HTTP.free;
  end;
end;

FUNCTION HttpPostFile(CONST URL, FieldName, fileName: string;
  CONST data: TStream; CONST ResultData: TStrings): boolean;
VAR
  HTTP: THTTPSend;
  Bound, s: string;
begin
  Bound := IntToHex(random(MAXINT), 8) + '_Synapse_boundary';
  HTTP := THTTPSend.create;
  try
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="' + FieldName + '";';
    s := s + ' filename="' + fileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.Document.CopyFrom(data, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    result := HTTP.HTTPMethod('POST', URL);
    if result then
      ResultData.LoadFromStream(HTTP.Document);
  finally
    HTTP.free;
  end;
end;

end.
