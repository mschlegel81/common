{==============================================================================|
| project : Ararat Synapse                                       | 003.000.003 |
|==============================================================================|
| content: SNTP Client                                                         |
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
|   Patrick Chevalley                                                          |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract( NTP and SNTP client)

used RFC: RFC-1305, RFC-2030
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

UNIT sntpsend;

INTERFACE

USES
  sysutils,
  synsock, blcksock, synautil;

CONST
  cNtpProtocol = '123';

TYPE

  {:@abstract(Record containing the NTP packet.)}
  TNtp = packed record
    mode: byte;
    stratum: byte;
    poll: byte;
    Precision: byte;
    RootDelay: longint;
    RootDisperson: longint;
    RefID: longint;
    Ref1: longint;
    Ref2: longint;
    Org1: longint;
    Org2: longint;
    Rcv1: longint;
    Rcv2: longint;
    Xmit1: longint;
    Xmit2: longint;
  end;

  {:@abstract(Implementation of NTP and SNTP client protocol),
   include time synchronisation. it can send NTP or SNTP time queries, or it
   can receive NTP broadcasts too.

   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TSNTPSend = class(TSynaClient)
  private
    FNTPReply: TNtp;
    FNTPTime: TDateTime;
    FNTPOffset: double;
    FNTPDelay: double;
    FMaxSyncDiff: double;
    FSyncTime: boolean;
    FSock: TUDPBlockSocket;
    FBuffer: ansistring;
    FLi, FVn, Fmode : byte;
    FUNCTION StrToNTP(CONST value: ansistring): TNtp;
    FUNCTION NTPtoStr(CONST value: Tntp): ansistring;
    PROCEDURE ClearNTP(VAR value: Tntp);
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Decode 128 bit timestamp used in NTP packet to TDateTime type.}
    FUNCTION DecodeTs(Nsec, Nfrac: longint): TDateTime;

    {:Decode TDateTime type to 128 bit timestamp used in NTP packet.}
    PROCEDURE EncodeTs(dt: TDateTime; VAR Nsec, Nfrac: longint);

    {:Send request to @link(TSynaClient.TargetHost) and wait for reply. If all
     is ok, then result is @true and @link(NTPReply) and @link(NTPTime) are
     valid.}
    FUNCTION GetSNTP: boolean;

    {:Send request to @link(TSynaClient.TargetHost) and wait for reply. If all
     is ok, then result is @true and @link(NTPReply) and @link(NTPTime) are
     valid. result time is after all needed corrections.}
    FUNCTION GetNTP: boolean;

    {:Wait for broadcast NTP packet. If all OK, result is @true and
     @link(NTPReply) and @link(NTPTime) are valid.}
    FUNCTION GetBroadcastNTP: boolean;

    {:Holds last received NTP packet.}
    PROPERTY NTPReply: TNtp read FNTPReply;
  Published
    {:Date and time of remote NTP or SNTP server. (UTC time!!!)}
    PROPERTY NTPTime: TDateTime read FNTPTime;

    {:Offset between your computer and remote NTP or SNTP server.}
    PROPERTY NTPOffset: double read FNTPOffset;

    {:Delay between your computer and remote NTP or SNTP server.}
    PROPERTY NTPDelay: double read FNTPDelay;

    {:Define allowed maximum difference between your time and remote time for
     synchronising time. if difference is bigger, your system time is not
     changed!}
    PROPERTY MaxSyncDiff: double read FMaxSyncDiff write FMaxSyncDiff;

    {:If @true, after successfull getting time is local computer clock
     synchronised to given time.
     for synchronising time you must have proper rights! (Usually Administrator)}
    PROPERTY SyncTime: boolean read FSyncTime write FSyncTime;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TUDPBlockSocket read FSock;
  end;

IMPLEMENTATION

CONSTRUCTOR TSNTPSend.create;
begin
  inherited create;
  FSock := TUDPBlockSocket.create;
  FSock.Owner := self;
  FTimeout := 5000;
  FTargetPort := cNtpProtocol;
  FMaxSyncDiff := 3600;
  FSyncTime := false;
end;

DESTRUCTOR TSNTPSend.destroy;
begin
  FSock.free;
  inherited destroy;
end;

FUNCTION TSNTPSend.StrToNTP(CONST value: ansistring): TNtp;
begin
  if length(FBuffer) >= sizeOf(result) then
  begin
    result.mode := ord(value[1]);
    result.stratum := ord(value[2]);
    result.poll := ord(value[3]);
    result.Precision := ord(value[4]);
    result.RootDelay := DecodeLongInt(value, 5);
    result.RootDisperson := DecodeLongInt(value, 9);
    result.RefID := DecodeLongInt(value, 13);
    result.Ref1 := DecodeLongInt(value, 17);
    result.Ref2 := DecodeLongInt(value, 21);
    result.Org1 := DecodeLongInt(value, 25);
    result.Org2 := DecodeLongInt(value, 29);
    result.Rcv1 := DecodeLongInt(value, 33);
    result.Rcv2 := DecodeLongInt(value, 37);
    result.Xmit1 := DecodeLongInt(value, 41);
    result.Xmit2 := DecodeLongInt(value, 45);
  end;

end;

FUNCTION TSNTPSend.NTPtoStr(CONST value: Tntp): ansistring;
begin
  setLength(result, 4);
  result[1] := AnsiChar(value.mode);
  result[2] := AnsiChar(value.stratum);
  result[3] := AnsiChar(value.poll);
  result[4] := AnsiChar(value.precision);
  result := result + CodeLongInt(value.RootDelay);
  result := result + CodeLongInt(value.RootDisperson);
  result := result + CodeLongInt(value.RefID);
  result := result + CodeLongInt(value.Ref1);
  result := result + CodeLongInt(value.Ref2);
  result := result + CodeLongInt(value.Org1);
  result := result + CodeLongInt(value.Org2);
  result := result + CodeLongInt(value.Rcv1);
  result := result + CodeLongInt(value.Rcv2);
  result := result + CodeLongInt(value.Xmit1);
  result := result + CodeLongInt(value.Xmit2);
end;

PROCEDURE TSNTPSend.ClearNTP(VAR value: Tntp);
begin
  value.mode := 0;
  value.stratum := 0;
  value.poll := 0;
  value.Precision := 0;
  value.RootDelay := 0;
  value.RootDisperson := 0;
  value.RefID := 0;
  value.Ref1 := 0;
  value.Ref2 := 0;
  value.Org1 := 0;
  value.Org2 := 0;
  value.Rcv1 := 0;
  value.Rcv2 := 0;
  value.Xmit1 := 0;
  value.Xmit2 := 0;
end;

FUNCTION TSNTPSend.DecodeTs(Nsec, Nfrac: longint): TDateTime;
CONST
  maxi = 4294967295.0;
VAR
  d, d1: double;
begin
  d := Nsec;
  if d < 0 then
    d := maxi + d + 1;
  d1 := Nfrac;
  if d1 < 0 then
    d1 := maxi + d1 + 1;
  d1 := d1 / maxi;
  d1 := trunc(d1 * 10000) / 10000;
  result := (d + d1) / 86400;
  result := result + 2;
end;

PROCEDURE TSNTPSend.EncodeTs(dt: TDateTime; VAR Nsec, Nfrac: longint);
CONST
  maxi = 4294967295.0;
  maxilongint = 2147483647;
VAR
  d, d1: double;
begin
  d  := (dt - 2) * 86400;
  d1 := frac(d);
  if d > maxilongint then
     d := d - maxi - 1;
  d  := trunc(d);
  d1 := trunc(d1 * 10000) / 10000;
  d1 := d1 * maxi;
  if d1 > maxilongint then
     d1 := d1 - maxi - 1;
  Nsec:=trunc(d);
  Nfrac:=trunc(d1);
end;

FUNCTION TSNTPSend.GetBroadcastNTP: boolean;
VAR
  x: integer;
begin
  result := false;
  FSock.Bind(FIPInterface, FTargetPort);
  FBuffer := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
  begin
    x := length(FBuffer);
    if (FTargetHost = '0.0.0.0') or (FSock.GetRemoteSinIP = FSock.ResolveName(FTargetHost)) then
      if x >= sizeOf(NTPReply) then
      begin
        FNTPReply := StrToNTP(FBuffer);
        FNTPTime := DecodeTs(NTPReply.Xmit1, NTPReply.Xmit2);
        if FSyncTime and ((abs(FNTPTime - GetUTTime) * 86400) <= FMaxSyncDiff) then
          SetUTTime(FNTPTime);
        result := true;
      end;
  end;
end;

FUNCTION TSNTPSend.GetSNTP: boolean;
VAR
  q: TNtp;
  x: integer;
begin
  result := false;
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(FTargetHost, FTargetPort);
  ClearNtp(q);
  q.mode := $1B;
  FBuffer := NTPtoStr(q);
  FSock.SendString(FBuffer);
  FBuffer := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
  begin
    x := length(FBuffer);
    if x >= sizeOf(NTPReply) then
    begin
      FNTPReply := StrToNTP(FBuffer);
      FNTPTime := DecodeTs(NTPReply.Xmit1, NTPReply.Xmit2);
      if FSyncTime and ((abs(FNTPTime - GetUTTime) * 86400) <= FMaxSyncDiff) then
        SetUTTime(FNTPTime);
      result := true;
    end;
  end;
end;

FUNCTION TSNTPSend.GetNTP: boolean;
VAR
  q: TNtp;
  x: integer;
  t1, t2, t3, t4 : TDateTime;
begin
  result := false;
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(FTargetHost, FTargetPort);
  ClearNtp(q);
  q.mode := $1B;
  t1 := GetUTTime;
  EncodeTs(t1, q.org1, q.org2);
  FBuffer := NTPtoStr(q);
  FSock.SendString(FBuffer);
  FBuffer := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
  begin
    x := length(FBuffer);
    t4 := GetUTTime;
    if x >= sizeOf(NTPReply) then
    begin
      FNTPReply := StrToNTP(FBuffer);
      FLi := (NTPReply.mode and $C0) shr 6;
      FVn := (NTPReply.mode and $38) shr 3;
      Fmode := NTPReply.mode and $07;
      if (Fli < 3) and (Fmode = 4) and
         (NTPReply.stratum >= 1) and (NTPReply.stratum <= 15) and
         (NTPReply.Rcv1 <> 0) and (NTPReply.Xmit1 <> 0)
         then begin
           t2 := DecodeTs(NTPReply.Rcv1, NTPReply.Rcv2);
           t3 := DecodeTs(NTPReply.Xmit1, NTPReply.Xmit2);
           FNTPDelay := (T4 - T1) - (T2 - T3);
           FNTPTime := t3 + FNTPDelay / 2;
           FNTPOffset := (((T2 - T1) + (T3 - T4)) / 2) * 86400;
           FNTPDelay := FNTPDelay * 86400;
           if FSyncTime and ((abs(FNTPTime - t1) * 86400) <= FMaxSyncDiff) then
             SetUTTime(FNTPTime);
           result := true;
           end
         else result:=false;
    end;
  end;
end;

end.
