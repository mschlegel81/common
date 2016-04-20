{==============================================================================|
| project : Ararat Synapse                                       | 003.005.001 |
|==============================================================================|
| content: SMTP Client                                                         |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2010.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(SMTP client)

used RFC: RFC-1869, RFC-1870, RFC-1893, RFC-2034, RFC-2104, RFC-2195, RFC-2487,
 RFC-2554, RFC-2821
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT smtpsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, synacode;

CONST
  cSmtpProtocol = '25';

TYPE
  {:@abstract(Implementation of SMTP and ESMTP procotol),
   include some ESMTP extensions, include SSL/TLS too.

   Note: Are you missing properties for setting Username and Password for ESMTP?
   Look to parent @link(TSynaClient) object!

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TSMTPSend = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FResultCode: integer;
    FResultString: string;
    FFullResult: TStringList;
    FESMTPcap: TStringList;
    FESMTP: boolean;
    FAuthDone: boolean;
    FESMTPSize: boolean;
    FMaxSize: integer;
    FEnhCode1: integer;
    FEnhCode2: integer;
    FEnhCode3: integer;
    FSystemName: string;
    FAutoTLS: boolean;
    FFullSSL: boolean;
    PROCEDURE EnhancedCode(CONST value: string);
    FUNCTION ReadResult: integer;
    FUNCTION AuthLogin: boolean;
    FUNCTION AuthCram: boolean;
    FUNCTION AuthPlain: boolean;
    FUNCTION Helo: boolean;
    FUNCTION Ehlo: boolean;
    FUNCTION Connect: boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Connects to SMTP server (defined in @link(TSynaClient.TargetHost)) and
     begin SMTP session. (first try ESMTP EHLO, next old HELO handshake). Parses
     ESMTP capabilites and if you specified Username and password and remote
     Server can handle AUTH command, try login by AUTH command. Preffered login
     method is CRAM-MD5 (if safer!). if all ok, result is @true, else result is
     @false.}
    FUNCTION Login: boolean;

    {:Close SMTP session (QUIT command) and disconnect from SMTP server.}
    FUNCTION Logout: boolean;

    {:Send RSET SMTP command for reset SMTP session. If all OK, result is @true,
     else result is @false.}
    FUNCTION reset: boolean;

    {:Send NOOP SMTP command for keep SMTP session. If all OK, result is @true,
     else result is @false.}
    FUNCTION NoOp: boolean;

    {:Send MAIL FROM SMTP command for set sender e-mail address. If sender's
     e-mail address is empty string, transmited message is error message.

     if size not 0 and remote Server can handle size parameter, append size
     parameter to request. if all ok, result is @true, else result is @false.}
    FUNCTION MailFrom(CONST value: string; size: integer): boolean;

    {:Send RCPT TO SMTP command for set receiver e-mail address. It cannot be an
     empty string. if all ok, result is @true, else result is @false.}
    FUNCTION MailTo(CONST value: string): boolean;

    {:Send DATA SMTP command and transmit message data. If all OK, result is
     @true, else result is @false.}
    FUNCTION MailData(CONST value: TStrings): boolean;

    {:Send ETRN SMTP command for start sending of remote queue for domain in
     value. if all ok, result is @true, else result is @false.}
    FUNCTION Etrn(CONST value: string): boolean;

    {:Send VRFY SMTP command for check receiver e-mail address. It cannot be
     an empty string. if all ok, result is @true, else result is @false.}
    FUNCTION Verify(CONST value: string): boolean;

    {:Call STARTTLS command for upgrade connection to SSL/TLS mode.}
    FUNCTION StartTLS: boolean;

    {:Return string descriptive text for enhanced result codes stored in
     @link(EnhCode1), @link(EnhCode2) and @link(EnhCode3).}
    FUNCTION EnhCodeString: string;

    {:Try to find specified capability in ESMTP response.}
    FUNCTION FindCap(CONST value: string): string;
  Published
    {:result code of last SMTP command.}
    PROPERTY ResultCode: integer read FResultCode;

    {:result string of last SMTP command (begin with string representation of
     result code).}
    PROPERTY resultString: string read FResultString;

    {:All result strings of last SMTP command (result is maybe multiline!).}
    PROPERTY FullResult: TStringList read FFullResult;

    {:List of ESMTP capabilites of remote ESMTP server. (If you connect to ESMTP
     Server only!).}
    PROPERTY ESMTPcap: TStringList read FESMTPcap;

    {:@TRUE if you successfuly logged to ESMTP server.}
    PROPERTY ESMTP: boolean read FESMTP;

    {:@TRUE if you successfuly pass authorisation to remote server.}
    PROPERTY AuthDone: boolean read FAuthDone;

    {:@TRUE if remote server can handle SIZE parameter.}
    PROPERTY ESMTPSize: boolean read FESMTPSize;

    {:When @link(ESMTPsize) is @TRUE, contains max length of message that remote
     Server can handle.}
    PROPERTY MaxSize: integer read FMaxSize;

    {:First digit of Enhanced result code. If last operation does not have
     enhanced result code, values is 0.}
    PROPERTY EnhCode1: integer read FEnhCode1;

    {:Second digit of Enhanced result code. If last operation does not have
     enhanced result code, values is 0.}
    PROPERTY EnhCode2: integer read FEnhCode2;

    {:Third digit of Enhanced result code. If last operation does not have
     enhanced result code, values is 0.}
    PROPERTY EnhCode3: integer read FEnhCode3;

    {:name of our system used in HELO and EHLO command. Implicit value is
     internet address of your machine.}
    PROPERTY SystemName: string read FSystemName write FSystemName;

    {:If is set to true, then upgrade to SSL/TLS mode if remote server support it.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:SSL/TLS mode is used from first contact to server. Servers with full
     SSL/TLS mode usualy using non-standard TCP port!}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;
  end;

{:A very useful function and example of its use would be found in the TSMTPsend
 object. Send maildata (text of e-mail with all SMTP headers! for example when
 text of message is created by @link(TMimemess) object) from "MailFrom" e-mail
 address to "MailTo" e-mail address (if you need more then one receiver, then
 separate their addresses by comma).

 FUNCTION sends e-mail to a SMTP Server defined in "SMTPhost" parameter.
 Username and password are used for authorization to the "SMTPhost". if you
 don't want authorization, set "Username" and "Password" to empty strings. If
 e-mail message is successfully sent, the result returns @true.

 if you need use different port number then standard, then add this port number
 to SMTPhost after colon. (i.e. '127.0.0.1:1025')}
FUNCTION SendToRaw(CONST MailFrom, MailTo, SMTPHost: string;
  CONST MailData: TStrings; CONST Username, Password: string): boolean;

{:A very useful function and example of its use would be found in the TSMTPsend
 object. Send "Maildata" (text of e-mail without any SMTP headers!) from
 "MailFrom" e-mail address to "MailTo" e-mail address with "Subject".  (if you
 need more then one receiver, then separate their addresses by comma).

 This FUNCTION constructs all needed SMTP headers (with DATE header) and sends
 the e-mail to the SMTP Server defined in the "SMTPhost" parameter. if the
 e-mail message is successfully sent, the result will be @true.

 if you need use different port number then standard, then add this port number
 to SMTPhost after colon. (i.e. '127.0.0.1:1025')}
FUNCTION SendTo(CONST MailFrom, MailTo, Subject, SMTPHost: string;
  CONST MailData: TStrings): boolean;

{:A very useful function and example of its use would be found in the TSMTPsend
 object. Sends "MailData" (text of e-mail without any SMTP headers!) from
 "MailFrom" e-mail address to "MailTo" e-mail address (if you need more then one
 receiver, then separate their addresses by comma).

 This FUNCTION sends the e-mail to the SMTP Server defined in the "SMTPhost"
 parameter. Username and password are used for authorization to the "SMTPhost".
 if you dont want authorization, set "Username" and "Password" to empty Strings.
 if the e-mail message is successfully sent, the result will be @true.

 if you need use different port number then standard, then add this port number
 to SMTPhost after colon. (i.e. '127.0.0.1:1025')}
FUNCTION SendToEx(CONST MailFrom, MailTo, Subject, SMTPHost: string;
  CONST MailData: TStrings; CONST Username, Password: string): boolean;

IMPLEMENTATION

CONSTRUCTOR TSMTPSend.create;
begin
  inherited create;
  FFullResult := TStringList.create;
  FESMTPcap := TStringList.create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.ConvertLineEnd := true;
  FTimeout := 60000;
  FTargetPort := cSmtpProtocol;
  FSystemName := FSock.LocalName;
  FAutoTLS := false;
  FFullSSL := false;
end;

DESTRUCTOR TSMTPSend.destroy;
begin
  FSock.free;
  FESMTPcap.free;
  FFullResult.free;
  inherited destroy;
end;

PROCEDURE TSMTPSend.EnhancedCode(CONST value: string);
VAR
  s, t: string;
  e1, e2, e3: integer;
begin
  FEnhCode1 := 0;
  FEnhCode2 := 0;
  FEnhCode3 := 0;
  s := copy(value, 5, length(value) - 4);
  t := trim(SeparateLeft(s, '.'));
  s := trim(SeparateRight(s, '.'));
  if t = '' then
    exit;
  if length(t) > 1 then
    exit;
  e1 := strToIntDef(t, 0);
  if e1 = 0 then
    exit;
  t := trim(SeparateLeft(s, '.'));
  s := trim(SeparateRight(s, '.'));
  if t = '' then
    exit;
  if length(t) > 3 then
    exit;
  e2 := strToIntDef(t, 0);
  t := trim(SeparateLeft(s, ' '));
  if t = '' then
    exit;
  if length(t) > 3 then
    exit;
  e3 := strToIntDef(t, 0);
  FEnhCode1 := e1;
  FEnhCode2 := e2;
  FEnhCode3 := e3;
end;

FUNCTION TSMTPSend.ReadResult: integer;
VAR
  s: string;
begin
  result := 0;
  FFullResult.clear;
  repeat
    s := FSock.RecvString(FTimeout);
    FResultString := s;
    FFullResult.add(s);
    if FSock.LastError <> 0 then
      break;
  until pos('-', s) <> 4;
  s := FFullResult[0];
  if length(s) >= 3 then
    result := strToIntDef(copy(s, 1, 3), 0);
  FResultCode := result;
  EnhancedCode(s);
end;

FUNCTION TSMTPSend.AuthLogin: boolean;
begin
  result := false;
  FSock.SendString('AUTH LOGIN' + CRLF);
  if ReadResult <> 334 then
    exit;
  FSock.SendString(EncodeBase64(FUsername) + CRLF);
  if ReadResult <> 334 then
    exit;
  FSock.SendString(EncodeBase64(FPassword) + CRLF);
  result := ReadResult = 235;
end;

FUNCTION TSMTPSend.AuthCram: boolean;
VAR
  s: ansistring;
begin
  result := false;
  FSock.SendString('AUTH CRAM-MD5' + CRLF);
  if ReadResult <> 334 then
    exit;
  s := copy(FResultString, 5, length(FResultString) - 4);
  s := DecodeBase64(s);
  s := HMAC_MD5(s, FPassword);
  s := FUsername + ' ' + StrToHex(s);
  FSock.SendString(EncodeBase64(s) + CRLF);
  result := ReadResult = 235;
end;

FUNCTION TSMTPSend.AuthPlain: boolean;
VAR
  s: ansistring;
begin
  s := ansichar(0) + FUsername + ansichar(0) + FPassword;
  FSock.SendString('AUTH PLAIN ' + EncodeBase64(s) + CRLF);
  result := ReadResult = 235;
end;

FUNCTION TSMTPSend.Connect: boolean;
begin
  FSock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError = 0 then
    FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError = 0 then
    if FFullSSL then
      FSock.SSLDoConnect;
  result := FSock.LastError = 0;
end;

FUNCTION TSMTPSend.Helo: boolean;
VAR
  x: integer;
begin
  FSock.SendString('HELO ' + FSystemName + CRLF);
  x := ReadResult;
  result := (x >= 250) and (x <= 259);
end;

FUNCTION TSMTPSend.Ehlo: boolean;
VAR
  x: integer;
begin
  FSock.SendString('EHLO ' + FSystemName + CRLF);
  x := ReadResult;
  result := (x >= 250) and (x <= 259);
end;

FUNCTION TSMTPSend.Login: boolean;
VAR
  n: integer;
  auths: string;
  s: string;
begin
  result := false;
  FESMTP := true;
  FAuthDone := false;
  FESMTPcap.clear;
  FESMTPSize := false;
  FMaxSize := 0;
  if not Connect then
    exit;
  if ReadResult <> 220 then
    exit;
  if not Ehlo then
  begin
    FESMTP := false;
    if not Helo then
      exit;
  end;
  result := true;
  if FESMTP then
  begin
    for n := 1 to FFullResult.count - 1 do
      FESMTPcap.add(copy(FFullResult[n], 5, length(FFullResult[n]) - 4));
    if (not FullSSL) and FAutoTLS and (FindCap('STARTTLS') <> '') then
      if StartTLS then
      begin
        Ehlo;
        FESMTPcap.clear;
        for n := 1 to FFullResult.count - 1 do
          FESMTPcap.add(copy(FFullResult[n], 5, length(FFullResult[n]) - 4));
      end
      else
      begin
        result := false;
        exit;
      end;
    if not ((FUsername = '') and (FPassword = '')) then
    begin
      s := FindCap('AUTH ');
      if s = '' then
        s := FindCap('AUTH=');
      auths := uppercase(s);
      if s <> '' then
      begin
        if pos('CRAM-MD5', auths) > 0 then
          FAuthDone := AuthCram;
        if (not FauthDone) and (pos('PLAIN', auths) > 0) then
          FAuthDone := AuthPlain;
        if (not FauthDone) and (pos('LOGIN', auths) > 0) then
          FAuthDone := AuthLogin;
      end;
    end;
    s := FindCap('SIZE');
    if s <> '' then
    begin
      FESMTPsize := true;
      FMaxSize := strToIntDef(copy(s, 6, length(s) - 5), 0);
    end;
  end;
end;

FUNCTION TSMTPSend.Logout: boolean;
begin
  FSock.SendString('QUIT' + CRLF);
  result := ReadResult = 221;
  FSock.CloseSocket;
end;

FUNCTION TSMTPSend.reset: boolean;
begin
  FSock.SendString('RSET' + CRLF);
  result := ReadResult div 100 = 2;
end;

FUNCTION TSMTPSend.NoOp: boolean;
begin
  FSock.SendString('NOOP' + CRLF);
  result := ReadResult div 100 = 2;
end;

FUNCTION TSMTPSend.MailFrom(CONST value: string; size: integer): boolean;
VAR
  s: string;
begin
  s := 'MAIL FROM:<' + value + '>';
  if FESMTPsize and (size > 0) then
    s := s + ' SIZE=' + intToStr(size);
  FSock.SendString(s + CRLF);
  result := ReadResult div 100 = 2;
end;

FUNCTION TSMTPSend.MailTo(CONST value: string): boolean;
begin
  FSock.SendString('RCPT TO:<' + value + '>' + CRLF);
  result := ReadResult div 100 = 2;
end;

FUNCTION TSMTPSend.MailData(CONST value: TStrings): boolean;
VAR
  n: integer;
  s: string;
  t: string;
  x: integer;
begin
  result := false;
  FSock.SendString('DATA' + CRLF);
  if ReadResult <> 354 then
    exit;
  t := '';
  x := 1500;
  for n := 0 to value.count - 1 do
  begin
    s := value[n];
    if length(s) >= 1 then
      if s[1] = '.' then
        s := '.' + s;
    if length(t) + length(s) >= x then
    begin
      FSock.SendString(t);
      t := '';
    end;
    t := t + s + CRLF;
  end;
  if t <> '' then
    FSock.SendString(t);
  FSock.SendString('.' + CRLF);
  result := ReadResult div 100 = 2;
end;

FUNCTION TSMTPSend.Etrn(CONST value: string): boolean;
VAR
  x: integer;
begin
  FSock.SendString('ETRN ' + value + CRLF);
  x := ReadResult;
  result := (x >= 250) and (x <= 259);
end;

FUNCTION TSMTPSend.Verify(CONST value: string): boolean;
VAR
  x: integer;
begin
  FSock.SendString('VRFY ' + value + CRLF);
  x := ReadResult;
  result := (x >= 250) and (x <= 259);
end;

FUNCTION TSMTPSend.StartTLS: boolean;
begin
  result := false;
  if FindCap('STARTTLS') <> '' then
  begin
    FSock.SendString('STARTTLS' + CRLF);
    if (ReadResult = 220) and (FSock.LastError = 0) then
    begin
      Fsock.SSLDoConnect;
      result := FSock.LastError = 0;
    end;
  end;
end;

FUNCTION TSMTPSend.EnhCodeString: string;
VAR
  s, t: string;
begin
  s := intToStr(FEnhCode2) + '.' + intToStr(FEnhCode3);
  t := '';
  if s = '0.0' then t := 'Other undefined Status';
  if s = '1.0' then t := 'Other address status';
  if s = '1.1' then t := 'Bad destination mailbox address';
  if s = '1.2' then t := 'Bad destination system address';
  if s = '1.3' then t := 'Bad destination mailbox address syntax';
  if s = '1.4' then t := 'Destination mailbox address ambiguous';
  if s = '1.5' then t := 'Destination mailbox address valid';
  if s = '1.6' then t := 'Mailbox has moved';
  if s = '1.7' then t := 'Bad sender''s mailbox address syntax';
  if s = '1.8' then t := 'Bad sender''s system address';
  if s = '2.0' then t := 'Other or undefined mailbox status';
  if s = '2.1' then t := 'Mailbox disabled, not accepting messages';
  if s = '2.2' then t := 'Mailbox full';
  if s = '2.3' then t := 'Message Length exceeds administrative limit';
  if s = '2.4' then t := 'Mailing list expansion problem';
  if s = '3.0' then t := 'Other or undefined mail system status';
  if s = '3.1' then t := 'Mail system full';
  if s = '3.2' then t := 'System not accepting network messages';
  if s = '3.3' then t := 'System not capable of selected features';
  if s = '3.4' then t := 'Message too big for system';
  if s = '3.5' then t := 'System incorrectly configured';
  if s = '4.0' then t := 'Other or undefined network or routing status';
  if s = '4.1' then t := 'No answer from host';
  if s = '4.2' then t := 'Bad connection';
  if s = '4.3' then t := 'Routing server failure';
  if s = '4.4' then t := 'Unable to route';
  if s = '4.5' then t := 'Network congestion';
  if s = '4.6' then t := 'Routing loop detected';
  if s = '4.7' then t := 'Delivery time expired';
  if s = '5.0' then t := 'Other or undefined protocol status';
  if s = '5.1' then t := 'Invalid command';
  if s = '5.2' then t := 'Syntax error';
  if s = '5.3' then t := 'Too many recipients';
  if s = '5.4' then t := 'Invalid command arguments';
  if s = '5.5' then t := 'Wrong protocol version';
  if s = '6.0' then t := 'Other or undefined media error';
  if s = '6.1' then t := 'Media not supported';
  if s = '6.2' then t := 'Conversion required and prohibited';
  if s = '6.3' then t := 'Conversion required but not supported';
  if s = '6.4' then t := 'Conversion with loss performed';
  if s = '6.5' then t := 'Conversion failed';
  if s = '7.0' then t := 'Other or undefined security status';
  if s = '7.1' then t := 'Delivery not authorized, message refused';
  if s = '7.2' then t := 'Mailing list expansion prohibited';
  if s = '7.3' then t := 'Security conversion required but not possible';
  if s = '7.4' then t := 'Security features not supported';
  if s = '7.5' then t := 'Cryptographic failure';
  if s = '7.6' then t := 'Cryptographic algorithm not supported';
  if s = '7.7' then t := 'Message integrity failure';
  s := '???-';
  if FEnhCode1 = 2 then s := 'Success-';
  if FEnhCode1 = 4 then s := 'Persistent Transient Failure-';
  if FEnhCode1 = 5 then s := 'Permanent Failure-';
  result := s + t;
end;

FUNCTION TSMTPSend.FindCap(CONST value: string): string;
VAR
  n: integer;
  s: string;
begin
  s := uppercase(value);
  result := '';
  for n := 0 to FESMTPcap.count - 1 do
    if pos(s, uppercase(FESMTPcap[n])) = 1 then
    begin
      result := FESMTPcap[n];
      break;
    end;
end;

{==============================================================================}

FUNCTION SendToRaw(CONST MailFrom, MailTo, SMTPHost: string;
  CONST MailData: TStrings; CONST Username, Password: string): boolean;
VAR
  SMTP: TSMTPSend;
  s, t: string;
begin
  result := false;
  SMTP := TSMTPSend.create;
  try
// if you need SOCKS5 support, uncomment next lines:
    // SMTP.Sock.SocksIP := '127.0.0.1';
    // SMTP.Sock.SocksPort := '1080';
// if you need support for upgrade session to TSL/SSL, uncomment next lines:
    // SMTP.AutoTLS := True;
// if you need support for TSL/SSL tunnel, uncomment next lines:
    // SMTP.FullSSL := True;
    SMTP.TargetHost := trim(SeparateLeft(SMTPHost, ':'));
    s := trim(SeparateRight(SMTPHost, ':'));
    if (s <> '') and (s <> SMTPHost) then
      SMTP.TargetPort := s;
    SMTP.Username := Username;
    SMTP.Password := Password;
    if SMTP.Login then
    begin
      if SMTP.MailFrom(GetEmailAddr(MailFrom), length(MailData.text)) then
      begin
        s := MailTo;
        repeat
          t := GetEmailAddr(trim(FetchEx(s, ',', '"')));
          if t <> '' then
            result := SMTP.MailTo(t);
          if not result then
            break;
        until s = '';
        if result then
          result := SMTP.MailData(MailData);
      end;
      SMTP.Logout;
    end;
  finally
    SMTP.free;
  end;
end;

FUNCTION SendToEx(CONST MailFrom, MailTo, Subject, SMTPHost: string;
  CONST MailData: TStrings; CONST Username, Password: string): boolean;
VAR
  t: TStrings;
begin
  t := TStringList.create;
  try
    t.assign(MailData);
    t.Insert(0, '');
    t.Insert(0, 'X-mailer: Synapse - Delphi & Kylix TCP/IP library by Lukas Gebauer');
    t.Insert(0, 'Subject: ' + Subject);
    t.Insert(0, 'Date: ' + Rfc822DateTime(now));
    t.Insert(0, 'To: ' + MailTo);
    t.Insert(0, 'From: ' + MailFrom);
    result := SendToRaw(MailFrom, MailTo, SMTPHost, t, Username, Password);
  finally
    t.free;
  end;
end;

FUNCTION SendTo(CONST MailFrom, MailTo, Subject, SMTPHost: string;
  CONST MailData: TStrings): boolean;
begin
  result := SendToEx(MailFrom, MailTo, Subject, SMTPHost, MailData, '', '');
end;

end.
