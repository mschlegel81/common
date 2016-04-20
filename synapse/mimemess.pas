{==============================================================================|
| project : Ararat Synapse                                       | 002.006.000 |
|==============================================================================|
| content: MIME message object                                                 |
|==============================================================================|
| Copyright (c)1999-2012, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2012.                |
| Portions created by Petr Fejfar are Copyright (c)2011-2012.                  |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM From distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(MIME message handling)
Classes for easy handling with e-mail message.
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
{$M+}

UNIT mimemess;

INTERFACE

USES
  Classes, sysutils,
  mimepart, synachar, synautil, mimeinln;

TYPE

  {:Possible values for message priority}
  TMessPriority = (MP_unknown, MP_low, MP_normal, MP_high);

  {:@abstract(Object for basic e-mail header fields.)}
  TMessHeader = class(TObject)
  private
    FFrom: string;
    FToList: TStringList;
    FCCList: TStringList;
    FSubject: string;
    FOrganization: string;
    FCustomHeaders: TStringList;
    FDate: TDateTime;
    FXMailer: string;
    FCharsetCode: TMimeChar;
    FReplyTo: string;
    FMessageID: string;
    FPriority: TMessPriority;
    Fpri: TMessPriority;
    Fxpri: TMessPriority;
    Fxmspri: TMessPriority;
  protected
    FUNCTION ParsePriority(value: string): TMessPriority;
    FUNCTION DecodeHeader(value: string): boolean; virtual;
  public
    CONSTRUCTOR create; virtual;
    DESTRUCTOR destroy; override;

    {:Clears all data fields.}
    PROCEDURE clear; virtual;

    {Add headers from from this object to Value.}
    PROCEDURE EncodeHeaders(CONST value: TStrings); virtual;

    {:Parse header from Value to this object.}
    PROCEDURE DecodeHeaders(CONST value: TStrings);

    {:Try find specific header in CustomHeader. Search is case insensitive.
     This is good for reading any non-parsed header.}
    FUNCTION FindHeader(value: string): string;

    {:Try find specific headers in CustomHeader. This metod is for repeatly used
     headers like 'received' header, etc. Search is case insensitive.
     This is good for reading ano non-parsed header.}
    PROCEDURE FindHeaderList(value: string; CONST HeaderList: TStrings);
  Published
    {:Sender of message.}
    PROPERTY From: string read FFrom write FFrom;

    {:Stringlist with receivers of message. (one per line)}
    PROPERTY ToList: TStringList read FToList;

    {:Stringlist with Carbon Copy receivers of message. (one per line)}
    PROPERTY CCList: TStringList read FCCList;

    {:Subject of message.}
    PROPERTY Subject: string read FSubject write FSubject;

    {:Organization string.}
    PROPERTY Organization: string read FOrganization write FOrganization;

    {:After decoding contains all headers lines witch not have parsed to any
     other structures in this object. it mean: this conatins all other headers
     except:

     X-MAILER, FROM, SUBJECT, ORGANIZATION, to, CC, DATE, MIME-VERSION,
     content-TYPE, content-description, content-DISPOSITION, content-id,
     content-TRANSFER-ENCODING, REPLY-to, message-id, X-MSMAIL-PRIORITY,
     X-PRIORITY, PRIORITY

     When you encode headers, all this lines is added as headers. Be carefull
     for duplicites!}
    PROPERTY CustomHeaders: TStringList read FCustomHeaders;

    {:Date and time of message.}
    PROPERTY Date: TDateTime read FDate write FDate;

    {:Mailer identification.}
    PROPERTY XMailer: string read FXMailer write FXMailer;

    {:Address for replies}
    PROPERTY ReplyTo: string read FReplyTo write FReplyTo;

    {:message indetifier}
    PROPERTY MessageID: string read FMessageID write FMessageID;

    {:message priority}
    PROPERTY Priority: TMessPriority read FPriority write FPriority;

    {:Specify base charset. By default is used system charset.}
    PROPERTY CharsetCode: TMimeChar read FCharsetCode write FCharsetCode;
  end;

  TMessHeaderClass = class of TMessHeader;

  {:@abstract(Object for handling of e-mail message.)}
  TMimeMess = class(TObject)
  private
    FMessagePart: TMimePart;
    FLines: TStringList;
    FHeader: TMessHeader;
  public
    CONSTRUCTOR create;
    {:create this object and assign your own descendant of @link(TMessHeader)
     object to @link(header) PROPERTY. So, you can create your own message
     headers parser and use it by this object.}
    CONSTRUCTOR CreateAltHeaders(HeadClass: TMessHeaderClass);
    DESTRUCTOR destroy; override;

    {:Reset component to default state.}
    PROCEDURE clear; virtual;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then one subpart,
     you must have PartParent of multipart TYPE!}
    FUNCTION AddPart(CONST PartParent: TMimePart): TMimePart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     This part is marked as multipart with secondary MIME TYPE specified by
     MultipartType parameter. (typical value is 'mixed')

     This part can be used as PartParent for another parts (include next
     multipart). if you need only one part, then you not need Multipart part.}
    FUNCTION AddPartMultipart(CONST MultipartType: string; CONST PartParent: TMimePart): TMimePart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     After creation of part set TYPE to text part and set all necessary
     properties. content of part is readed from value stringlist.}
    FUNCTION AddPartText(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     After creation of part set TYPE to text part and set all necessary
     properties. content of part is readed from value stringlist. You can select
     your charSet and your encoding TYPE. if raw is @true, then it not doing
     charSet conversion!}
    FUNCTION AddPartTextEx(CONST value: TStrings; CONST PartParent: TMimePart;
      PartCharset: TMimeChar; raw: boolean; PartEncoding: TMimeEncoding): TMimepart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     After creation of part set TYPE to text part to html TYPE and set all
     necessary properties. content of html part is readed from value stringlist.}
    FUNCTION AddPartHTML(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;

    {:Same as @link(AddPartText), but content is readed from file}
    FUNCTION AddPartTextFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;

    {:Same as @link(AddPartHTML), but content is readed from file}
    FUNCTION AddPartHTMLFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart,
     you must have PartParent of multipart TYPE!

     After creation of part set TYPE to binary and set all necessary properties.
     MIME primary and secondary types defined automaticly by fileName extension.
     content of binary part is readed from Stream. This binary part is encoded
     as file attachment.}
    FUNCTION AddPartBinary(CONST Stream: TStream; CONST fileName: string; CONST PartParent: TMimePart): TMimepart;

    {:Same as @link(AddPartBinary), but content is readed from file}
    FUNCTION AddPartBinaryFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     After creation of part set TYPE to binary and set all necessary properties.
     MIME primary and secondary types defined automaticly by fileName extension.
     content of binary part is readed from Stream.

     This binary part is encoded as inline data with given Conten id (cid).
     content id can be used as reference id in html Source in html part.}
    FUNCTION AddPartHTMLBinary(CONST Stream: TStream; CONST fileName, Cid: string; CONST PartParent: TMimePart): TMimepart;

    {:Same as @link(AddPartHTMLBinary), but content is readed from file}
    FUNCTION AddPartHTMLBinaryFromFile(CONST fileName, Cid: string; CONST PartParent: TMimePart): TMimepart;

    {:Add MIME part as subpart of PartParent. If you need set root MIME part,
     then set as PartParent @nil value. if you need set more then 1 subpart, you
     must have PartParent of multipart TYPE!

     After creation of part set TYPE to message and set all necessary properties.
     MIME primary and secondary types are setted to 'message/rfc822'.
     content of raw RFC-822 message is readed from Stream.}
    FUNCTION AddPartMess(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;

    {:Same as @link(AddPartMess), but content is readed from file}
    FUNCTION AddPartMessFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;

    {:Compose message from @link(MessagePart) to @link(Lines). Headers from
     @link(Header) object is added also.}
    PROCEDURE EncodeMessage;

    {:Decode message from @link(Lines) to @link(MessagePart). Massage headers
     are parsed into @link(Header) object.}
    PROCEDURE DecodeMessage;

    {pf}
    {: HTTP message is received by @link(THTTPSend) component in two parts:
     headers are stored in @link(THTTPSend.Headers) and a body in memory stream
     @link(THTTPSend.Document).

     on the top of it, HTTP connections are always 8-bit, hence data are
     transferred in native format i.e. no transfer encoding is applied.

     This method operates the similiar way and produces the same
     result as @link(DecodeMessage).
    }
    PROCEDURE DecodeMessageBinary(AHeader:TStrings; AData:TMemoryStream);
    {/pf}
  Published
    {:@link(TMimePart) object with decoded MIME message. This object can handle
     any number of nested @link(TMimePart) objects itself. it is used for handle
     any tree of MIME subparts.}
    PROPERTY MessagePart: TMimePart read FMessagePart;

    {:Raw MIME encoded message.}
    PROPERTY lines: TStringList read FLines;

    {:Object for e-mail header fields. This object is created automaticly.
     do not free this object!}
    PROPERTY Header: TMessHeader read FHeader;
  end;

IMPLEMENTATION

{==============================================================================}

CONSTRUCTOR TMessHeader.create;
begin
  inherited create;
  FToList := TStringList.create;
  FCCList := TStringList.create;
  FCustomHeaders := TStringList.create;
  FCharsetCode := GetCurCP;
end;

DESTRUCTOR TMessHeader.destroy;
begin
  FCustomHeaders.free;
  FCCList.free;
  FToList.free;
  inherited destroy;
end;

{==============================================================================}

PROCEDURE TMessHeader.clear;
begin
  FFrom := '';
  FToList.clear;
  FCCList.clear;
  FSubject := '';
  FOrganization := '';
  FCustomHeaders.clear;
  FDate := 0;
  FXMailer := '';
  FReplyTo := '';
  FMessageID := '';
  FPriority := MP_unknown;
end;

PROCEDURE TMessHeader.EncodeHeaders(CONST value: TStrings);
VAR
  n: integer;
  s: string;
begin
  if FDate = 0 then
    FDate := now;
  for n := FCustomHeaders.count - 1 downto 0 do
    if FCustomHeaders[n] <> '' then
      value.Insert(0, FCustomHeaders[n]);
  if FPriority <> MP_unknown then
    case FPriority of
      MP_high:
        begin
          value.Insert(0, 'X-MSMAIL-Priority: High');
          value.Insert(0, 'X-Priority: 1');
          value.Insert(0, 'Priority: urgent');
        end;
      MP_low:
        begin
          value.Insert(0, 'X-MSMAIL-Priority: low');
          value.Insert(0, 'X-Priority: 5');
          value.Insert(0, 'Priority: non-urgent');
        end;
    end;
  if FReplyTo <> '' then
    value.Insert(0, 'Reply-To: ' + GetEmailAddr(FReplyTo));
  if FMessageID <> '' then
    value.Insert(0, 'Message-ID: <' + trim(FMessageID) + '>');
  if FXMailer = '' then
    value.Insert(0, 'X-mailer: Synapse - Pascal TCP/IP library by Lukas Gebauer')
  else
    value.Insert(0, 'X-mailer: ' + FXMailer);
  value.Insert(0, 'MIME-Version: 1.0 (produced by Synapse)');
  if FOrganization <> '' then
    value.Insert(0, 'Organization: ' + InlineCodeEx(FOrganization, FCharsetCode));
  s := '';
  for n := 0 to FCCList.count - 1 do
    if s = '' then
      s := InlineEmailEx(FCCList[n], FCharsetCode)
    else
      s := s + ', ' + InlineEmailEx(FCCList[n], FCharsetCode);
  if s <> '' then
    value.Insert(0, 'CC: ' + s);
  value.Insert(0, 'Date: ' + Rfc822DateTime(FDate));
  if FSubject <> '' then
    value.Insert(0, 'Subject: ' + InlineCodeEx(FSubject, FCharsetCode));
  s := '';
  for n := 0 to FToList.count - 1 do
    if s = '' then
      s := InlineEmailEx(FToList[n], FCharsetCode)
    else
      s := s + ', ' + InlineEmailEx(FToList[n], FCharsetCode);
  if s <> '' then
    value.Insert(0, 'To: ' + s);
  value.Insert(0, 'From: ' + InlineEmailEx(FFrom, FCharsetCode));
end;

FUNCTION TMessHeader.ParsePriority(value: string): TMessPriority;
VAR
  s: string;
  x: integer;
begin
  result := MP_unknown;
  s := trim(separateright(value, ':'));
  s := Separateleft(s, ' ');
  x := strToIntDef(s, -1);
  if x >= 0 then
    case x of
      1, 2:
        result := MP_High;
      3:
        result := MP_Normal;
      4, 5:
        result := MP_Low;
    end
  else
  begin
    s := lowercase(s);
    if (s = 'urgent') or (s = 'high') or (s = 'highest') then
      result := MP_High;
    if (s = 'normal') or (s = 'medium') then
      result := MP_Normal;
    if (s = 'low') or (s = 'lowest')
      or (s = 'no-priority')  or (s = 'non-urgent') then
      result := MP_Low;
  end;
end;

FUNCTION TMessHeader.DecodeHeader(value: string): boolean;
VAR
  s, t: string;
  cp: TMimeChar;
begin
  result := true;
  cp := FCharsetCode;
  s := uppercase(value);
  if pos('X-MAILER:', s) = 1 then
  begin
    FXMailer := trim(SeparateRight(value, ':'));
    exit;
  end;
  if pos('FROM:', s) = 1 then
  begin
    FFrom := InlineDecode(trim(SeparateRight(value, ':')), cp);
    exit;
  end;
  if pos('SUBJECT:', s) = 1 then
  begin
    FSubject := InlineDecode(trim(SeparateRight(value, ':')), cp);
    exit;
  end;
  if pos('ORGANIZATION:', s) = 1 then
  begin
    FOrganization := InlineDecode(trim(SeparateRight(value, ':')), cp);
    exit;
  end;
  if pos('TO:', s) = 1 then
  begin
    s := trim(SeparateRight(value, ':'));
    repeat
      t := InlineDecode(trim(FetchEx(s, ',', '"')), cp);
      if t <> '' then
        FToList.add(t);
    until s = '';
    exit;
  end;
  if pos('CC:', s) = 1 then
  begin
    s := trim(SeparateRight(value, ':'));
    repeat
      t := InlineDecode(trim(FetchEx(s, ',', '"')), cp);
      if t <> '' then
        FCCList.add(t);
    until s = '';
    exit;
  end;
  if pos('DATE:', s) = 1 then
  begin
    FDate := DecodeRfcDateTime(trim(SeparateRight(value, ':')));
    exit;
  end;
  if pos('REPLY-TO:', s) = 1 then
  begin
    FReplyTo := InlineDecode(trim(SeparateRight(value, ':')), cp);
    exit;
  end;
  if pos('MESSAGE-ID:', s) = 1 then
  begin
    FMessageID := GetEmailAddr(trim(SeparateRight(value, ':')));
    exit;
  end;
  if pos('PRIORITY:', s) = 1 then
  begin
    FPri := ParsePriority(value);
    exit;
  end;
  if pos('X-PRIORITY:', s) = 1 then
  begin
    FXPri := ParsePriority(value);
    exit;
  end;
  if pos('X-MSMAIL-PRIORITY:', s) = 1 then
  begin
    FXmsPri := ParsePriority(value);
    exit;
  end;
  if pos('MIME-VERSION:', s) = 1 then
    exit;
  if pos('CONTENT-TYPE:', s) = 1 then
    exit;
  if pos('CONTENT-DESCRIPTION:', s) = 1 then
    exit;
  if pos('CONTENT-DISPOSITION:', s) = 1 then
    exit;
  if pos('CONTENT-ID:', s) = 1 then
    exit;
  if pos('CONTENT-TRANSFER-ENCODING:', s) = 1 then
    exit;
  result := false;
end;

PROCEDURE TMessHeader.DecodeHeaders(CONST value: TStrings);
VAR
  s: string;
  x: integer;
begin
  clear;
  Fpri := MP_unknown;
  Fxpri := MP_unknown;
  Fxmspri := MP_unknown;
  x := 0;
  while value.count > x do
  begin
    s := NormalizeHeader(value, x);
    if s = '' then
      break;
    if not DecodeHeader(s) then
      FCustomHeaders.add(s);
  end;
  if Fpri <> MP_unknown then
    FPriority := Fpri
  else
    if Fxpri <> MP_unknown then
      FPriority := Fxpri
    else
      if Fxmspri <> MP_unknown then
        FPriority := Fxmspri
end;

FUNCTION TMessHeader.FindHeader(value: string): string;
VAR
  n: integer;
begin
  result := '';
  for n := 0 to FCustomHeaders.count - 1 do
    if pos(uppercase(value), uppercase(FCustomHeaders[n])) = 1 then
    begin
      result := trim(SeparateRight(FCustomHeaders[n], ':'));
      break;
    end;
end;

PROCEDURE TMessHeader.FindHeaderList(value: string; CONST HeaderList: TStrings);
VAR
  n: integer;
begin
  HeaderList.clear;
  for n := 0 to FCustomHeaders.count - 1 do
    if pos(uppercase(value), uppercase(FCustomHeaders[n])) = 1 then
    begin
      HeaderList.add(trim(SeparateRight(FCustomHeaders[n], ':')));
    end;
end;

{==============================================================================}

CONSTRUCTOR TMimeMess.create;
begin
  CreateAltHeaders(TMessHeader);
end;

CONSTRUCTOR TMimeMess.CreateAltHeaders(HeadClass: TMessHeaderClass);
begin
  inherited create;
  FMessagePart := TMimePart.create;
  FLines := TStringList.create;
  FHeader := HeadClass.create;
end;

DESTRUCTOR TMimeMess.destroy;
begin
  FMessagePart.free;
  FHeader.free;
  FLines.free;
  inherited destroy;
end;

{==============================================================================}

PROCEDURE TMimeMess.clear;
begin
  FMessagePart.clear;
  FLines.clear;
  FHeader.clear;
end;

{==============================================================================}

FUNCTION TMimeMess.AddPart(CONST PartParent: TMimePart): TMimePart;
begin
  if PartParent = nil then
    result := FMessagePart
  else
    result := PartParent.AddSubPart;
  result.clear;
end;

{==============================================================================}

FUNCTION TMimeMess.AddPartMultipart(CONST MultipartType: string; CONST PartParent: TMimePart): TMimePart;
begin
  result := AddPart(PartParent);
  with result do
  begin
    Primary := 'Multipart';
    Secondary := MultipartType;
    description := 'Multipart message';
    Boundary := GenerateBoundary;
    EncodePartHeader;
  end;
end;

FUNCTION TMimeMess.AddPartText(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;
begin
  result := AddPart(PartParent);
  with result do
  begin
    value.SaveToStream(DecodedLines);
    Primary := 'text';
    Secondary := 'plain';
    description := 'Message text';
    Disposition := 'inline';
    CharsetCode := IdealCharsetCoding(value.text, TargetCharset, IdealCharsets);
    EncodingCode := ME_QUOTED_PRINTABLE;
    EncodePart;
    EncodePartHeader;
  end;
end;

FUNCTION TMimeMess.AddPartTextEx(CONST value: TStrings; CONST PartParent: TMimePart;
  PartCharset: TMimeChar; raw: boolean; PartEncoding: TMimeEncoding): TMimepart;
begin
  result := AddPart(PartParent);
  with result do
  begin
    value.SaveToStream(DecodedLines);
    Primary := 'text';
    Secondary := 'plain';
    description := 'Message text';
    Disposition := 'inline';
    CharsetCode := PartCharset;
    EncodingCode := PartEncoding;
    ConvertCharset := not raw;
    EncodePart;
    EncodePartHeader;
  end;
end;

FUNCTION TMimeMess.AddPartHTML(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;
begin
  result := AddPart(PartParent);
  with result do
  begin
    value.SaveToStream(DecodedLines);
    Primary := 'text';
    Secondary := 'html';
    description := 'HTML text';
    Disposition := 'inline';
    CharsetCode := UTF_8;
    EncodingCode := ME_QUOTED_PRINTABLE;
    EncodePart;
    EncodePartHeader;
  end;
end;

FUNCTION TMimeMess.AddPartTextFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;
VAR
  tmp: TStrings;
begin
  tmp := TStringList.create;
  try
    tmp.loadFromFile(fileName);
    result := AddPartText(tmp, PartParent);
  finally
    tmp.free;
  end;
end;

FUNCTION TMimeMess.AddPartHTMLFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;
VAR
  tmp: TStrings;
begin
  tmp := TStringList.create;
  try
    tmp.loadFromFile(fileName);
    result := AddPartHTML(tmp, PartParent);
  finally
    tmp.free;
  end;
end;

FUNCTION TMimeMess.AddPartBinary(CONST Stream: TStream; CONST fileName: string; CONST PartParent: TMimePart): TMimepart;
begin
  result := AddPart(PartParent);
  result.DecodedLines.LoadFromStream(Stream);
  result.MimeTypeFromExt(fileName);
  result.description := 'Attached file: ' + fileName;
  result.Disposition := 'attachment';
  result.fileName := fileName;
  result.EncodingCode := ME_BASE64;
  result.EncodePart;
  result.EncodePartHeader;
end;

FUNCTION TMimeMess.AddPartBinaryFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;
VAR
  tmp: TMemoryStream;
begin
  tmp := TMemoryStream.create;
  try
    tmp.loadFromFile(fileName);
    result := AddPartBinary(tmp, extractFileName(fileName), PartParent);
  finally
    tmp.free;
  end;
end;

FUNCTION TMimeMess.AddPartHTMLBinary(CONST Stream: TStream; CONST fileName, Cid: string; CONST PartParent: TMimePart): TMimepart;
begin
  result := AddPart(PartParent);
  result.DecodedLines.LoadFromStream(Stream);
  result.MimeTypeFromExt(fileName);
  result.description := 'Included file: ' + fileName;
  result.Disposition := 'inline';
  result.ContentID := Cid;
  result.fileName := fileName;
  result.EncodingCode := ME_BASE64;
  result.EncodePart;
  result.EncodePartHeader;
end;

FUNCTION TMimeMess.AddPartHTMLBinaryFromFile(CONST fileName, Cid: string; CONST PartParent: TMimePart): TMimepart;
VAR
  tmp: TMemoryStream;
begin
  tmp := TMemoryStream.create;
  try
    tmp.loadFromFile(fileName);
    result :=AddPartHTMLBinary(tmp, extractFileName(fileName), Cid, PartParent);
  finally
    tmp.free;
  end;
end;

FUNCTION TMimeMess.AddPartMess(CONST value: TStrings; CONST PartParent: TMimePart): TMimepart;
VAR
  part: Tmimepart;
begin
  result := AddPart(PartParent);
  part := AddPart(result);
  part.lines.addstrings(value);
  part.DecomposeParts;
  with result do
  begin
    Primary := 'message';
    Secondary := 'rfc822';
    description := 'E-mail Message';
    EncodePart;
    EncodePartHeader;
  end;
end;

FUNCTION TMimeMess.AddPartMessFromFile(CONST fileName: string; CONST PartParent: TMimePart): TMimepart;
VAR
  tmp: TStrings;
begin
  tmp := TStringList.create;
  try
    tmp.loadFromFile(fileName);
    result := AddPartMess(tmp, PartParent);
  finally
    tmp.free;
  end;
end;

{==============================================================================}

PROCEDURE TMimeMess.EncodeMessage;
VAR
  l: TStringList;
  x: integer;
begin
  //merge headers from THeaders and header field from MessagePart
  l := TStringList.create;
  try
    FHeader.EncodeHeaders(l);
    x := IndexByBegin('CONTENT-TYPE', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-DESCRIPTION', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-DISPOSITION', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-ID', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    x := IndexByBegin('CONTENT-TRANSFER-ENCODING', FMessagePart.Headers);
    if x >= 0 then
      l.add(FMessagePart.Headers[x]);
    FMessagePart.Headers.assign(l);
  finally
    l.free;
  end;
  FMessagePart.ComposeParts;
  FLines.assign(FMessagePart.lines);
end;

{==============================================================================}

PROCEDURE TMimeMess.DecodeMessage;
begin
  FHeader.clear;
  FHeader.DecodeHeaders(FLines);
  FMessagePart.lines.assign(FLines);
  FMessagePart.DecomposeParts;
end;

{pf}
PROCEDURE TMimeMess.DecodeMessageBinary(AHeader:TStrings; AData:TMemoryStream);
begin
  FHeader.clear;
  FLines.clear;
  FLines.assign(AHeader);
  FHeader.DecodeHeaders(FLines);
  FMessagePart.DecomposePartsBinary(AHeader,PAnsiChar(AData.memory),PAnsiChar(AData.memory)+AData.size);
end;
{/pf}

end.
