{==============================================================================|
| project : Ararat Synapse                                       | 001.002.003 |
|==============================================================================|
| content: SysLog Client                                                       |
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
| Portions created by Lukas Gebauer are Copyright (c)2001-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|    Christian Brosius                                                         |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(BSD SYSLOG protocol)

used RFC: RFC-3164
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

UNIT slogsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil;

CONST
  cSysLogProtocol = '514';

  FCL_Kernel = 0;
  FCL_UserLevel = 1;
  FCL_MailSystem = 2;
  FCL_System = 3;
  FCL_Security = 4;
  FCL_Syslogd = 5;
  FCL_Printer = 6;
  FCL_News = 7;
  FCL_UUCP = 8;
  FCL_Clock = 9;
  FCL_Authorization = 10;
  FCL_FTP = 11;
  FCL_NTP = 12;
  FCL_LogAudit = 13;
  FCL_LogAlert = 14;
  FCL_Time = 15;
  FCL_Local0 = 16;
  FCL_Local1 = 17;
  FCL_Local2 = 18;
  FCL_Local3 = 19;
  FCL_Local4 = 20;
  FCL_Local5 = 21;
  FCL_Local6 = 22;
  FCL_Local7 = 23;

TYPE
  {:@abstract(Define possible priority of Syslog message)}
  TSyslogSeverity = (Emergency, Alert, Critical, Error, Warning, Notice, info,
    debug);

  {:@abstract(encoding or decoding of SYSLOG message)}
  TSyslogMessage = class(TObject)
  private
    FFacility:byte;
    FSeverity:TSyslogSeverity;
    FDateTime:TDateTime;
    FTag:string;
    FMessage:string;
    FLocalIP:string;
    FUNCTION GetPacketBuf:string;
    PROCEDURE SetPacketBuf(value:string);
  public
    {:Reset values to defaults}
    PROCEDURE clear;
  Published
    {:Define facilicity of Syslog message. For specify you may use predefined
     FCL_* constants. default is "FCL_Local0".}
    PROPERTY Facility:byte read FFacility write FFacility;

    {:Define possible priority of Syslog message. Default is "Debug".}
    PROPERTY Severity:TSyslogSeverity read FSeverity write FSeverity;

    {:date and time of Syslog message}
    PROPERTY DateTime:TDateTime read FDateTime write FDateTime;

    {:This is used for identify process of this message. Default is filename
     of your executable file.}
    PROPERTY Tag:string read FTag write FTag;

    {:Text of your message for log.}
    PROPERTY LogMessage:string read FMessage write FMessage;

    {:IP address of message sender.}
    PROPERTY LocalIP:string read FLocalIP write FLocalIP;

    {:This property holds encoded binary SYSLOG packet}
    PROPERTY PacketBuf:string read GetPacketBuf write SetPacketBuf;
  end;

  {:@abstract(This object implement BSD SysLog client)

   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TSyslogSend = class(TSynaClient)
  private
    FSock: TUDPBlockSocket;
    FSysLogMessage: TSysLogMessage;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;
    {:Send Syslog UDP packet defined by @link(SysLogMessage).}
    FUNCTION DoIt: boolean;
  Published
    {:Syslog message for send}
    PROPERTY SysLogMessage:TSysLogMessage read FSysLogMessage write FSysLogMessage;
  end;

{:Simply send packet to specified Syslog server.}
FUNCTION ToSysLog(CONST SyslogServer: string; Facil: byte;
  Sever: TSyslogSeverity; CONST content: string): boolean;

IMPLEMENTATION

FUNCTION TSyslogMessage.GetPacketBuf:string;
begin
  result := '<' + intToStr((FFacility * 8) + ord(FSeverity)) + '>';
  result := result + CDateTime(FDateTime) + ' ';
  result := result + FLocalIP + ' ';
  result := result + FTag + ': ' + FMessage;
end;

PROCEDURE TSyslogMessage.SetPacketBuf(value:string);
VAR StrBuf:string;
    IntBuf,pos:integer;
begin
  if length(value) < 1 then exit;
  pos := 1;
  if value[pos] <> '<' then exit;
  inc(pos);
  // Facility and Severity
  StrBuf := '';
  while (value[pos] <> '>')do
  begin
    StrBuf := StrBuf + value[pos];
    inc(pos);
  end;
  IntBuf := strToInt(StrBuf);
  FFacility := IntBuf div 8;
  case (IntBuf mod 8)of
    0:FSeverity := Emergency;
    1:FSeverity := Alert;
    2:FSeverity := Critical;
    3:FSeverity := Error;
    4:FSeverity := Warning;
    5:FSeverity := Notice;
    6:FSeverity := info;
    7:FSeverity := debug;
  end;
  // DateTime
  inc(pos);
  StrBuf := '';
    // Month
  while (value[pos] <> ' ')do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
    StrBuf := StrBuf + value[pos];
    inc(pos);
    // Day
  while (value[pos] <> ' ')do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
    StrBuf := StrBuf + value[pos];
    inc(pos);
    // Time
  while (value[pos] <> ' ')do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
  FDateTime := DecodeRFCDateTime(StrBuf);
  inc(pos);

  // LocalIP
  StrBuf := '';
  while (value[pos] <> ' ')do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
  FLocalIP := StrBuf;
  inc(pos);
  // Tag
  StrBuf := '';
  while (value[pos] <> ':')do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
  FTag := StrBuf;
  // LogMessage
  inc(pos);
  StrBuf := '';
  while (pos <= length(value))do
    begin
      StrBuf := StrBuf + value[pos];
      inc(pos);
    end;
  FMessage := TrimSP(StrBuf);
end;

PROCEDURE TSysLogMessage.clear;
begin
  FFacility := FCL_Local0;
  FSeverity := debug;
  FTag := extractFileName(paramStr(0));
  FMessage := '';
  FLocalIP  := '0.0.0.0';
end;

//------------------------------------------------------------------------------

CONSTRUCTOR TSyslogSend.create;
begin
  inherited create;
  FSock := TUDPBlockSocket.create;
  FSock.Owner := self;
  FSysLogMessage := TSysLogMessage.create;
  FTargetPort := cSysLogProtocol;
end;

DESTRUCTOR TSyslogSend.destroy;
begin
  FSock.free;
  FSysLogMessage.free;
  inherited destroy;
end;

FUNCTION TSyslogSend.DoIt: boolean;
VAR
  L: TStringList;
begin
  result := false;
  L := TStringList.create;
  try
    FSock.ResolveNameToIP(FSock.Localname, L);
    if L.count < 1 then
      FSysLogMessage.LocalIP := '0.0.0.0'
    else
      FSysLogMessage.LocalIP := L[0];
  finally
    L.free;
  end;
  FSysLogMessage.DateTime := now;
  if length(FSysLogMessage.PacketBuf) <= 1024 then
  begin
    FSock.Connect(FTargetHost, FTargetPort);
    FSock.SendString(FSysLogMessage.PacketBuf);
    result := FSock.LastError = 0;
  end;
end;

{==============================================================================}

FUNCTION ToSysLog(CONST SyslogServer: string; Facil: byte;
  Sever: TSyslogSeverity; CONST content: string): boolean;
begin
  with TSyslogSend.create do
    try
      TargetHost :=SyslogServer;
      SysLogMessage.Facility := Facil;
      SysLogMessage.Severity := Sever;
      SysLogMessage.LogMessage := content;
      result := DoIt;
    finally
      free;
    end;
end;

end.
