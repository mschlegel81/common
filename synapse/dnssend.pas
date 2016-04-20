{==============================================================================|
| project : Ararat Synapse                                       | 002.007.006 |
|==============================================================================|
| content: DNS Client                                                          |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}
{: @abstract(DNS client by UDP or TCP)
Support for sending DNS queries by UDP or TCP protocol. it can retrieve zone
 transfers too!

used RFC: RFC-1035, RFC-1183, RFC1706, RFC1712, RFC2163, RFC2230
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT dnssend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, synaip, synsock;

CONST
  cDnsProtocol = '53';

  QTYPE_A = 1;
  QTYPE_NS = 2;
  QTYPE_MD = 3;
  QTYPE_MF = 4;
  QTYPE_CNAME = 5;
  QTYPE_SOA = 6;
  QTYPE_MB = 7;
  QTYPE_MG = 8;
  QTYPE_MR = 9;
  QTYPE_NULL = 10;
  QTYPE_WKS = 11; //
  QTYPE_PTR = 12;
  QTYPE_HINFO = 13;
  QTYPE_MINFO = 14;
  QTYPE_MX = 15;
  QTYPE_TXT = 16;

  QTYPE_RP = 17;
  QTYPE_AFSDB = 18;
  QTYPE_X25 = 19;
  QTYPE_ISDN = 20;
  QTYPE_RT = 21;
  QTYPE_NSAP = 22;
  QTYPE_NSAPPTR = 23;
  QTYPE_SIG = 24; // RFC-2065
  QTYPE_KEY = 25; // RFC-2065
  QTYPE_PX = 26;
  QTYPE_GPOS = 27;
  QTYPE_AAAA = 28;
  QTYPE_LOC = 29; // RFC-1876
  QTYPE_NXT = 30; // RFC-2065

  QTYPE_SRV = 33;
  QTYPE_NAPTR = 35; // RFC-2168
  QTYPE_KX = 36;
  QTYPE_SPF = 99;

  QTYPE_AXFR = 252;
  QTYPE_MAILB = 253; //
  QTYPE_MAILA = 254; //
  QTYPE_ALL = 255;

TYPE
  {:@abstract(Implementation of DNS protocol by UDP or TCP protocol.)

   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TDNSSend = class(TSynaClient)
  private
    FID: word;
    FRCode: integer;
    FBuffer: ansistring;
    FSock: TUDPBlockSocket;
    FTCPSock: TTCPBlockSocket;
    FUseTCP: boolean;
    FAnswerInfo: TStringList;
    FNameserverInfo: TStringList;
    FAdditionalInfo: TStringList;
    FAuthoritative: boolean;
    FTruncated: boolean;
    FUNCTION CompressName(CONST value: ansistring): ansistring;
    FUNCTION CodeHeader: ansistring;
    FUNCTION CodeQuery(CONST name: ansistring; QType: integer): ansistring;
    FUNCTION DecodeLabels(VAR From: integer): ansistring;
    FUNCTION DecodeString(VAR From: integer): ansistring;
    FUNCTION DecodeResource(VAR i: integer; CONST info: TStringList;
      QType: integer): ansistring;
    FUNCTION RecvTCPResponse(CONST WorkSock: TBlockSocket): ansistring;
    FUNCTION DecodeResponse(CONST Buf: ansistring; CONST Reply: TStrings;
      QType: integer):boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Query a DNSHost for QType resources correspond to a name. Supported QType
     values are: Qtype_A, Qtype_NS, Qtype_MD, Qtype_MF, Qtype_CNAME, Qtype_SOA,
     Qtype_MB, Qtype_MG, Qtype_MR, Qtype_NULL, Qtype_PTR, Qtype_HINFO,
     Qtype_MINFO, Qtype_MX, Qtype_TXT, Qtype_RP, Qtype_AFSDB, Qtype_X25,
     Qtype_ISDN, Qtype_RT, Qtype_NSAP, Qtype_NSAPPTR, Qtype_PX, Qtype_GPOS,
     Qtype_KX.

     TYPE for zone transfers QTYPE_AXFR is supported too, but only in TCP mode!

     "name" is domain name or host name for queried resource. if "name" is
     IP address, automatically convert to reverse domain form (.in-addr.arpa).

     if result is @true, Reply contains resource records. One record on one line.
     if Resource record have multiple fields, they are stored on line divided by
     comma. (example: MX record contains value 'rs.cesnet.cz' with preference
     number 10, string in Reply is: '10,rs.cesnet.cz'). all numbers or IP address
     in resource are converted to string form.}
    FUNCTION DNSQuery(name: ansistring; QType: integer;
      CONST Reply: TStrings): boolean;
  Published

    {:Socket object used for UDP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TUDPBlockSocket read FSock;

    {:Socket object used for TCP operation. Good for seting OnStatus hook, etc.}
    PROPERTY TCPSock: TTCPBlockSocket read FTCPSock;

    {:if @true, then is used TCP protocol instead UDP. It is needed for zone
     transfers, etc.}
    PROPERTY UseTCP: boolean read FUseTCP write FUseTCP;

    {:After DNS operation contains ResultCode of DNS operation.
      values are: 0-no error, 1-format error, 2-Server failure, 3-name error,
      4-not implemented, 5-refused.}
    PROPERTY RCode: integer read FRCode;

    {:@True, if answer is authoritative.}
    PROPERTY Authoritative: boolean read FAuthoritative;

    {:@True, if answer is truncated to 512 bytes.}
    PROPERTY Truncated: boolean read FTRuncated;

    {:Detailed informations from name server reply. One record per line. Record
     have comma delimited entries with TYPE number, TTL and data filelds.
     This information contains detailed information about query reply.}
    PROPERTY AnswerInfo: TStringList read FAnswerInfo;

    {:Detailed informations from name server reply. One record per line. Record
     have comma delimited entries with TYPE number, TTL and data filelds.
     This information contains detailed information about nameserver.}
    PROPERTY NameserverInfo: TStringList read FNameserverInfo;

    {:Detailed informations from name server reply. One record per line. Record
     have comma delimited entries with TYPE number, TTL and data filelds.
     This information contains detailed additional information.}
    PROPERTY AdditionalInfo: TStringList read FAdditionalInfo;
  end;

{:A very useful function, and example of it's use is found in the TDNSSend object.
 This FUNCTION is used to get mail servers for a domain and sort them by
 preference numbers. "Servers" contains only the domain names of the mail
 servers in the Right order (without preference number!). the first domain name
 will always be the highest preferenced mail Server. Returns boolean @true if
 all went well.}
FUNCTION GetMailServers(CONST DNSHost, Domain: ansistring;
  CONST Servers: TStrings): boolean;

IMPLEMENTATION

CONSTRUCTOR TDNSSend.create;
begin
  inherited create;
  FSock := TUDPBlockSocket.create;
  FSock.Owner := self;
  FTCPSock := TTCPBlockSocket.create;
  FTCPSock.Owner := self;
  FUseTCP := false;
  FTimeout := 10000;
  FTargetPort := cDnsProtocol;
  FAnswerInfo := TStringList.create;
  FNameserverInfo := TStringList.create;
  FAdditionalInfo := TStringList.create;
  randomize;
end;

DESTRUCTOR TDNSSend.destroy;
begin
  FAnswerInfo.free;
  FNameserverInfo.free;
  FAdditionalInfo.free;
  FTCPSock.free;
  FSock.free;
  inherited destroy;
end;

FUNCTION TDNSSend.CompressName(CONST value: ansistring): ansistring;
VAR
  n: integer;
  s: ansistring;
begin
  result := '';
  if value = '' then
    result := #0
  else
  begin
    s := '';
    for n := 1 to length(value) do
      if value[n] = '.' then
      begin
        result := result + AnsiChar(length(s)) + s;
        s := '';
      end
      else
        s := s + value[n];
    if s <> '' then
      result := result + AnsiChar(length(s)) + s;
    result := result + #0;
  end;
end;

FUNCTION TDNSSend.CodeHeader: ansistring;
begin
  FID := random(32767);
  result := CodeInt(FID); // ID
  result := result + CodeInt($0100); // flags
  result := result + CodeInt(1); // QDCount
  result := result + CodeInt(0); // ANCount
  result := result + CodeInt(0); // NSCount
  result := result + CodeInt(0); // ARCount
end;

FUNCTION TDNSSend.CodeQuery(CONST name: ansistring; QType: integer): ansistring;
begin
  result := CompressName(name);
  result := result + CodeInt(QType);
  result := result + CodeInt(1); // Type INTERNET
end;

FUNCTION TDNSSend.DecodeString(VAR From: integer): ansistring;
VAR
  len: integer;
begin
  len := ord(FBuffer[From]);
  inc(From);
  result := copy(FBuffer, From, len);
  inc(From, len);
end;

FUNCTION TDNSSend.DecodeLabels(VAR From: integer): ansistring;
VAR
  l, f: integer;
begin
  result := '';
  while true do
  begin
    if From >= length(FBuffer) then
      break;
    l := ord(FBuffer[From]);
    inc(From);
    if l = 0 then
      break;
    if result <> '' then
      result := result + '.';
    if (l and $C0) = $C0 then
    begin
      f := l and $3F;
      f := f * 256 + ord(FBuffer[From]) + 1;
      inc(From);
      result := result + DecodeLabels(f);
      break;
    end
    else
    begin
      result := result + copy(FBuffer, From, l);
      inc(From, l);
    end;
  end;
end;

FUNCTION TDNSSend.DecodeResource(VAR i: integer; CONST info: TStringList;
  QType: integer): ansistring;
VAR
  Rname: ansistring;
  RType, len, j, x, y, z, n: integer;
  R: ansistring;
  t1, t2, ttl: integer;
  ip6: TIp6bytes;
begin
  result := '';
  R := '';
  Rname := DecodeLabels(i);
  RType := DecodeInt(FBuffer, i);
  inc(i, 4);
  t1 := DecodeInt(FBuffer, i);
  inc(i, 2);
  t2 := DecodeInt(FBuffer, i);
  inc(i, 2);
  ttl := t1 * 65536 + t2;
  len := DecodeInt(FBuffer, i);
  inc(i, 2); // i point to begin of data
  j := i;
  i := i + len; // i point to next record
  if length(FBuffer) >= (i - 1) then
    case RType of
      QTYPE_A:
        begin
          R := intToStr(ord(FBuffer[j]));
          inc(j);
          R := R + '.' + intToStr(ord(FBuffer[j]));
          inc(j);
          R := R + '.' + intToStr(ord(FBuffer[j]));
          inc(j);
          R := R + '.' + intToStr(ord(FBuffer[j]));
        end;
      QTYPE_AAAA:
        begin
          for n := 0 to 15 do
            ip6[n] := ord(FBuffer[j + n]);
          R := IP6ToStr(ip6);
        end;
      QTYPE_NS, QTYPE_MD, QTYPE_MF, QTYPE_CNAME, QTYPE_MB,
        QTYPE_MG, QTYPE_MR, QTYPE_PTR, QTYPE_X25, QTYPE_NSAP,
        QTYPE_NSAPPTR:
        R := DecodeLabels(j);
      QTYPE_SOA:
        begin
          R := DecodeLabels(j);
          R := R + ',' + DecodeLabels(j);
          for n := 1 to 5 do
          begin
            x := DecodeInt(FBuffer, j) * 65536 + DecodeInt(FBuffer, j + 2);
            inc(j, 4);
            R := R + ',' + intToStr(x);
          end;
        end;
      QTYPE_NULL:
        begin
        end;
      QTYPE_WKS:
        begin
        end;
      QTYPE_HINFO:
        begin
          R := DecodeString(j);
          R := R + ',' + DecodeString(j);
        end;
      QTYPE_MINFO, QTYPE_RP, QTYPE_ISDN:
        begin
          R := DecodeLabels(j);
          R := R + ',' + DecodeLabels(j);
        end;
      QTYPE_MX, QTYPE_AFSDB, QTYPE_RT, QTYPE_KX:
        begin
          x := DecodeInt(FBuffer, j);
          inc(j, 2);
          R := intToStr(x);
          R := R + ',' + DecodeLabels(j);
        end;
      QTYPE_TXT, QTYPE_SPF:
        begin
          R := '';
          while j < i do
            R := R + DecodeString(j);
        end;
      QTYPE_GPOS:
        begin
          R := DecodeLabels(j);
          R := R + ',' + DecodeLabels(j);
          R := R + ',' + DecodeLabels(j);
        end;
      QTYPE_PX:
        begin
          x := DecodeInt(FBuffer, j);
          inc(j, 2);
          R := intToStr(x);
          R := R + ',' + DecodeLabels(j);
          R := R + ',' + DecodeLabels(j);
        end;
      QTYPE_SRV:
      // Author: Dan <ml@mutox.org>
        begin
          x := DecodeInt(FBuffer, j);
          inc(j, 2);
          y := DecodeInt(FBuffer, j);
          inc(j, 2);
          z := DecodeInt(FBuffer, j);
          inc(j, 2);
          R := intToStr(x);                     // Priority
          R := R + ',' + intToStr(y);           // Weight
          R := R + ',' + intToStr(z);           // Port
          R := R + ',' + DecodeLabels(j);       // Server DNS Name
        end;
    end;
  if R <> '' then
    info.add(RName + ',' + intToStr(RType) + ',' + intToStr(ttl) + ',' + R);
  if QType = RType then
    result := R;
end;

FUNCTION TDNSSend.RecvTCPResponse(CONST WorkSock: TBlockSocket): ansistring;
VAR
  l: integer;
begin
  result := '';
  l := WorkSock.recvbyte(FTimeout) * 256 + WorkSock.recvbyte(FTimeout);
  if l > 0 then
    result := WorkSock.RecvBufferStr(l, FTimeout);
end;

FUNCTION TDNSSend.DecodeResponse(CONST Buf: ansistring; CONST Reply: TStrings;
  QType: integer):boolean;
VAR
  n, i: integer;
  flag, qdcount, ancount, nscount, arcount: integer;
  s: ansistring;
begin
  result := false;
  Reply.clear;
  FAnswerInfo.clear;
  FNameserverInfo.clear;
  FAdditionalInfo.clear;
  FAuthoritative := false;
  if (length(Buf) > 13) and (FID = DecodeInt(Buf, 1)) then
  begin
    result := true;
    flag := DecodeInt(Buf, 3);
    FRCode := Flag and $000F;
    FAuthoritative := (Flag and $0400) > 0;
    FTruncated := (Flag and $0200) > 0;
    if FRCode = 0 then
    begin
      qdcount := DecodeInt(Buf, 5);
      ancount := DecodeInt(Buf, 7);
      nscount := DecodeInt(Buf, 9);
      arcount := DecodeInt(Buf, 11);
      i := 13; //begin of body
      if (qdcount > 0) and (length(Buf) > i) then //skip questions
        for n := 1 to qdcount do
        begin
          while (Buf[i] <> #0) and ((ord(Buf[i]) and $C0) <> $C0) do
            inc(i);
          inc(i, 5);
        end;
      if (ancount > 0) and (length(Buf) > i) then // decode reply
        for n := 1 to ancount do
        begin
          s := DecodeResource(i, FAnswerInfo, QType);
          if s <> '' then
            Reply.add(s);
        end;
      if (nscount > 0) and (length(Buf) > i) then // decode nameserver info
        for n := 1 to nscount do
          DecodeResource(i, FNameserverInfo, QType);
      if (arcount > 0) and (length(Buf) > i) then // decode additional info
        for n := 1 to arcount do
          DecodeResource(i, FAdditionalInfo, QType);
    end;
  end;
end;

FUNCTION TDNSSend.DNSQuery(name: ansistring; QType: integer;
  CONST Reply: TStrings): boolean;
VAR
  WorkSock: TBlockSocket;
  t: TStringList;
  b: boolean;
begin
  result := false;
  if IsIP(name) then
    name := ReverseIP(name) + '.in-addr.arpa';
  if IsIP6(name) then
    name := ReverseIP6(name) + '.ip6.arpa';
  FBuffer := CodeHeader + CodeQuery(name, QType);
  if FUseTCP then
    WorkSock := FTCPSock
  else
    WorkSock := FSock;
  WorkSock.Bind(FIPInterface, cAnyPort);
  WorkSock.Connect(FTargetHost, FTargetPort);
  if FUseTCP then
    FBuffer := Codeint(length(FBuffer)) + FBuffer;
  WorkSock.SendString(FBuffer);
  if FUseTCP then
    FBuffer := RecvTCPResponse(WorkSock)
  else
    FBuffer := WorkSock.RecvPacket(FTimeout);
  if FUseTCP and (QType = QTYPE_AXFR) then //zone transfer
  begin
    t := TStringList.create;
    try
      repeat
        b := DecodeResponse(FBuffer, Reply, QType);
        if (t.count > 1) and (AnswerInfo.count > 0) then  //find end of transfer
          b := b and (t[0] <> AnswerInfo[AnswerInfo.count - 1]);
        if b then
        begin
          t.AddStrings(AnswerInfo);
          FBuffer := RecvTCPResponse(WorkSock);
          if FBuffer = '' then
            break;
          if WorkSock.LastError <> 0 then
            break;
        end;
      until not b;
      Reply.assign(t);
      result := true;
    finally
      t.free;
    end;
  end
  else //normal query
    if WorkSock.LastError = 0 then
      result := DecodeResponse(FBuffer, Reply, QType);
end;

{==============================================================================}

FUNCTION GetMailServers(CONST DNSHost, Domain: ansistring;
  CONST Servers: TStrings): boolean;
VAR
  DNS: TDNSSend;
  t: TStringList;
  n, m, x: integer;
begin
  result := false;
  Servers.clear;
  t := TStringList.create;
  DNS := TDNSSend.create;
  try
    DNS.TargetHost := DNSHost;
    if DNS.DNSQuery(Domain, QType_MX, t) then
    begin
      { normalize preference number to 5 digits }
      for n := 0 to t.count - 1 do
      begin
        x := pos(',', t[n]);
        if x > 0 then
          for m := 1 to 6 - x do
            t[n] := '0' + t[n];
      end;
      { sort server list }
      t.Sorted := true;
      { result is sorted list without preference numbers }
      for n := 0 to t.count - 1 do
      begin
        x := pos(',', t[n]);
        Servers.add(copy(t[n], x + 1, length(t[n]) - x));
      end;
      result := true;
    end;
  finally
    DNS.free;
    t.free;
  end;
end;

end.
