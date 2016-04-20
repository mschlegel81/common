{==============================================================================|
| project : Ararat Synapse                                       | 002.009.000 |
|==============================================================================|
| content: MIME support procedures and functions                               |
|==============================================================================|
| Copyright (c)1999-200812                                                         |
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
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(MIME part handling)
Handling with MIME parts.

used RFC: RFC-2045
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
{$Q-}
{$R-}
{$M+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT mimepart;

INTERFACE

USES
  sysutils, Classes,
  synafpc,
  synachar, synacode, synautil, mimeinln;

TYPE

  TMimePart = class;

  {:@abstract(Procedural type for @link(TMimepart.Walkpart) hook). This hook is used for
   easy walking through MIME subparts.}
  THookWalkPart = PROCEDURE(CONST Sender: TMimePart) of object;

  {:The four types of MIME parts. (textual, multipart, message or any other
   binary data.)}
  TMimePrimary = (MP_TEXT, MP_MULTIPART, MP_MESSAGE, MP_BINARY);

  {:The various types of possible part encodings.}
  TMimeEncoding = (ME_7BIT, ME_8BIT, ME_QUOTED_PRINTABLE,
    ME_BASE64, ME_UU, ME_XX);

  {:@abstract(Object for working with parts of MIME e-mail.)
   Each TMimePart object can handle any number of nested subparts as new
   TMimepart objects. it can handle any tree hierarchy structure of nested MIME
   subparts itself.

   Basic tasks are:

   Decoding of MIME message:
   - store message into lines PROPERTY
   - call DecomposeParts. now you have decomposed MIME parts in all nested levels!
   - now you can explore all properties and subparts. (You can use WalkPart method)
   - if you need decode part, call DecodePart.

   Encoding of MIME message:

   - if you need multipart message, you must create subpart by AddSubPart.
   - set all properties of all parts.
   - set content of part into DecodedLines stream
   - encode this stream by EncodePart.
   - compose full message by ComposeParts. (it build full MIME message from all subparts. do not call this method for each subpart! it is needed on root part!)
   - encoded MIME message is stored in lines PROPERTY.
  }
  TMimePart = class(TObject)
  private
    FPrimary: string;
    FPrimaryCode: TMimePrimary;
    FSecondary: string;
    FEncoding: string;
    FEncodingCode: TMimeEncoding;
    FDefaultCharset: string;
    FCharset: string;
    FCharsetCode: TMimeChar;
    FTargetCharset: TMimeChar;
    FDescription: string;
    FDisposition: string;
    FContentID: string;
    FBoundary: string;
    FFileName: string;
    FLines: TStringList;
    FPartBody: TStringList;
    FHeaders: TStringList;
    FPrePart: TStringList;
    FPostPart: TStringList;
    FDecodedLines: TMemoryStream;
    FSubParts: TList;
    FOnWalkPart: THookWalkPart;
    FMaxLineLength: integer;
    FSubLevel: integer;
    FMaxSubLevel: integer;
    FAttachInside: boolean;
    FConvertCharset: boolean;
    FForcedHTMLConvert: boolean;
    FBinaryDecomposer: boolean;
    PROCEDURE SetPrimary(value: string);
    PROCEDURE SetEncoding(value: string);
    PROCEDURE SetCharset(value: string);
    FUNCTION IsUUcode(value: string): boolean;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Assign content of another object to this object. (Only this part,
     not subparts!)}
    PROCEDURE assign(value: TMimePart);

    {:Assign content of another object to this object. (With all subparts!)}
    PROCEDURE AssignSubParts(value: TMimePart);

    {:Clear all data values to default values. It also call @link(ClearSubparts).}
    PROCEDURE clear;

    {:Decode Mime part from @link(Lines) to @link(DecodedLines).}
    PROCEDURE DecodePart;

    {:Parse header lines from Headers property into another properties.}
    PROCEDURE DecodePartHeader;

    {:Encode mime part from @link(DecodedLines) to @link(Lines) and build mime
     headers.}
    PROCEDURE EncodePart;

    {:Build header lines in Headers property from another properties.}
    PROCEDURE EncodePartHeader;

    {:generate primary and secondary mime type from filename extension in value.
     if TYPE not recognised, it return 'Application/octet-string' TYPE.}
    PROCEDURE MimeTypeFromExt(value: string);

    {:Return number of decomposed subparts. (On this level! Each of this
     subparts can hold any number of their own nested subparts!)}
    FUNCTION GetSubPartCount: integer;

    {:Get nested subpart object as new TMimePart. For getting maximum possible
     index you can use @link(GetSubPartCount) method.}
    FUNCTION GetSubPart(index: integer): TMimePart;

    {:delete subpart on given index.}
    PROCEDURE DeleteSubPart(index: integer);

    {:Clear and destroy all subpart TMimePart objects.}
    PROCEDURE ClearSubParts;

    {:Add and create new subpart.}
    FUNCTION AddSubPart: TMimePart;

    {:E-mail message in @link(Lines) property is parsed into this object.
     E-mail headers are stored in @link(Headers) PROPERTY and is parsed into
     another properties automaticly. not need call @link(DecodePartHeader)!
     content of message (part) is stored into @link(PartBody) PROPERTY. This
     part is in undecoded form! if you need decode it, then you must call
     @link(DecodePart) method by your hands. Lot of another properties is filled
     also.

     Decoding of parts you must call separately due performance reasons. (not
     needed to decode all parts in all reasons.)

     for each MIME subpart is created new TMimepart object (accessible via
     method @link(GetSubPart)).}
    PROCEDURE DecomposeParts;

    {pf}
    {: HTTP message is received by @link(THTTPSend) component in two parts:
     headers are stored in @link(THTTPSend.Headers) and a body in memory stream
     @link(THTTPSend.Document).

     on the top of it, HTTP connections are always 8-bit, hence data are
     transferred in native format i.e. no transfer encoding is applied.

     This method operates the similiar way and produces the same
     result as @link(DecomposeParts).
    }
    PROCEDURE DecomposePartsBinary(AHeader:TStrings; AStx,AEtx:PAnsiChar);
    {/pf}

    {:This part and all subparts is composed into one MIME message stored in
     @link(lines) PROPERTY.}
    PROCEDURE ComposeParts;

    {:By calling this method is called @link(OnWalkPart) event for each part
     and their subparts. it is very good for calling some code for each part in
     MIME message}
    PROCEDURE WalkPart;

    {:Return @true when is possible create next subpart. (@link(maxSublevel)
     is still not reached)}
    FUNCTION CanSubPart: boolean;
  Published
    {:Primary Mime type of part. (i.e. 'application') Writing to this property
     automaticly generate value of @link(PrimaryCode).}
    PROPERTY Primary: string read FPrimary write SetPrimary;

    {:String representation of used Mime encoding in part. (i.e. 'base64')
     Writing to this PROPERTY automaticly generate value of @link(EncodingCode).}
    PROPERTY Encoding: string read FEncoding write SetEncoding;

    {:String representation of used Mime charset in part. (i.e. 'iso-8859-1')
     Writing to this PROPERTY automaticly generate value of @link(CharsetCode).
     charSet is used only for text parts.}
    PROPERTY charSet: string read FCharset write SetCharset;

    {:Define default charset for decoding text MIME parts without charset
     specification. default value is 'ISO-8859-1' by RCF documents.
     But Microsoft Outlook use windows codings as default. This PROPERTY allows
     properly decode textual parts from some broken versions of Microsoft
     Outlook. (this is bad software!)}
    PROPERTY DefaultCharset: string read FDefaultCharset write FDefaultCharset;

    {:Decoded primary type. Possible values are: MP_TEXT, MP_MULTIPART,
     MP_MESSAGE and MP_BINARY. if TYPE not recognised, result is MP_BINARY.}
    PROPERTY PrimaryCode: TMimePrimary read FPrimaryCode write FPrimaryCode;

    {:Decoded encoding type. Possible values are: ME_7BIT, ME_8BIT,
     ME_QUOTED_PRINTABLE and ME_BASE64. if TYPE not recognised, result is
     ME_7BIT.}
    PROPERTY EncodingCode: TMimeEncoding read FEncodingCode write FEncodingCode;

    {:Decoded charset type. Possible values are defined in @link(SynaChar) unit.}
    PROPERTY CharsetCode: TMimeChar read FCharsetCode write FCharsetCode;

    {:System charset type. Default value is charset used by default in your
     operating system.}
    PROPERTY TargetCharset: TMimeChar read FTargetCharset write FTargetCharset;

    {:If @true, then do internal charset translation of part content between @link(CharsetCode)
     and @link(TargetCharset)}
    PROPERTY ConvertCharset: boolean read FConvertCharset write FConvertCharset;

    {:If @true, then allways do internal charset translation of HTML parts
     by MIME even it have their own charSet in META Tag. default is @false.}
    PROPERTY ForcedHTMLConvert: boolean read FForcedHTMLConvert write FForcedHTMLConvert;

    {:Secondary Mime type of part. (i.e. 'mixed')}
    PROPERTY Secondary: string read FSecondary write FSecondary;

    {:Description of Mime part.}
    PROPERTY description: string read FDescription write FDescription;

    {:Value of content disposition field. (i.e. 'inline' or 'attachment')}
    PROPERTY Disposition: string read FDisposition write FDisposition;

    {:Content ID.}
    PROPERTY ContentID: string read FContentID write FContentID;

    {:Boundary delimiter of multipart Mime part. Used only in multipart part.}
    PROPERTY Boundary: string read FBoundary write FBoundary;

    {:Filename of file in binary part.}
    PROPERTY fileName: string read FFileName write FFileName;

    {:String list with lines contains mime part (It can be a full message).}
    PROPERTY lines: TStringList read FLines;

    {:Encoded form of MIME part data.}
    PROPERTY PartBody: TStringList read FPartBody;

    {:All header lines of MIME part.}
    PROPERTY Headers: TStringList read FHeaders;

    {:On multipart this contains part of message between first line of message
     and first boundary.}
    PROPERTY PrePart: TStringList read FPrePart;

    {:On multipart this contains part of message between last boundary and end
     of message.}
    PROPERTY PostPart: TStringList read FPostPart;

    {:Stream with decoded form of budy part.}
    PROPERTY DecodedLines: TMemoryStream read FDecodedLines;

    {:Show nested level in subpart tree. Value 0 means root part. 1 means
     subpart from this root. etc.}
    PROPERTY SubLevel: integer read FSubLevel write FSubLevel;

    {:Specify maximum sublevel value for decomposing.}
    PROPERTY MaxSubLevel: integer read FMaxSubLevel write FMaxSubLevel;

    {:When is @true, then this part maybe(!) have included some uuencoded binary
    data.}
    PROPERTY AttachInside: boolean read FAttachInside;

    {:Here you can assign hook procedure for walking through all part and their
     subparts.}
    PROPERTY OnWalkPart: THookWalkPart read FOnWalkPart write FOnWalkPart;

    {:Here you can specify maximum line length for encoding of MIME part.
     if line is longer, then is splitted by standard of MIME. Correct MIME
     mailers can de-split this line into original length.}
    PROPERTY maxLineLength: integer read FMaxLineLength write FMaxLineLength;
  end;

CONST
  MaxMimeType = 25;
  MimeType: array[0..MaxMimeType, 0..2] of string =
  (
    ('AU', 'audio', 'basic'),
    ('AVI', 'video', 'x-msvideo'),
    ('BMP', 'image', 'BMP'),
    ('DOC', 'application', 'MSWord'),
    ('EPS', 'application', 'Postscript'),
    ('GIF', 'image', 'GIF'),
    ('JPEG', 'image', 'JPEG'),
    ('JPG', 'image', 'JPEG'),
    ('MID', 'audio', 'midi'),
    ('MOV', 'video', 'quicktime'),
    ('MPEG', 'video', 'MPEG'),
    ('MPG', 'video', 'MPEG'),
    ('MP2', 'audio', 'mpeg'),
    ('MP3', 'audio', 'mpeg'),
    ('PDF', 'application', 'PDF'),
    ('PNG', 'image', 'PNG'),
    ('PS', 'application', 'Postscript'),
    ('QT', 'video', 'quicktime'),
    ('RA', 'audio', 'x-realaudio'),
    ('RTF', 'application', 'RTF'),
    ('SND', 'audio', 'basic'),
    ('TIF', 'image', 'TIFF'),
    ('TIFF', 'image', 'TIFF'),
    ('WAV', 'audio', 'x-wav'),
    ('WPD', 'application', 'Wordperfect5.1'),
    ('ZIP', 'application', 'ZIP')
    );

{:Generates a unique boundary string.}
FUNCTION GenerateBoundary: string;

IMPLEMENTATION

{==============================================================================}

CONSTRUCTOR TMIMEPart.create;
begin
  inherited create;
  FOnWalkPart := nil;
  FLines := TStringList.create;
  FPartBody := TStringList.create;
  FHeaders := TStringList.create;
  FPrePart := TStringList.create;
  FPostPart := TStringList.create;
  FDecodedLines := TMemoryStream.create;
  FSubParts := TList.create;
  FTargetCharset := GetCurCP;
  //was 'US-ASCII' before, but RFC-ignorant Outlook sometimes using default
  //system charset instead.
  FDefaultCharset := GetIDFromCP(GetCurCP);
  FMaxLineLength := 78;
  FSubLevel := 0;
  FMaxSubLevel := -1;
  FAttachInside := false;
  FConvertCharset := true;
  FForcedHTMLConvert := false;
end;

DESTRUCTOR TMIMEPart.destroy;
begin
  ClearSubParts;
  FSubParts.free;
  FDecodedLines.free;
  FPartBody.free;
  FLines.free;
  FHeaders.free;
  FPrePart.free;
  FPostPart.free;
  inherited destroy;
end;

{==============================================================================}

PROCEDURE TMIMEPart.clear;
begin
  FPrimary := '';
  FEncoding := '';
  FCharset := '';
  FPrimaryCode := MP_TEXT;
  FEncodingCode := ME_7BIT;
  FCharsetCode := ISO_8859_1;
  FTargetCharset := GetCurCP;
  FSecondary := '';
  FDisposition := '';
  FContentID := '';
  FDescription := '';
  FBoundary := '';
  FFileName := '';
  FAttachInside := false;
  FPartBody.clear;
  FHeaders.clear;
  FPrePart.clear;
  FPostPart.clear;
  FDecodedLines.clear;
  FConvertCharset := true;
  FForcedHTMLConvert := false;
  ClearSubParts;
end;

{==============================================================================}

PROCEDURE TMIMEPart.assign(value: TMimePart);
begin
  Primary := value.Primary;
  Encoding := value.Encoding;
  charSet := value.charSet;
  DefaultCharset := value.DefaultCharset;
  PrimaryCode := value.PrimaryCode;
  EncodingCode := value.EncodingCode;
  CharsetCode := value.CharsetCode;
  TargetCharset := value.TargetCharset;
  Secondary := value.Secondary;
  description := value.description;
  Disposition := value.Disposition;
  ContentID := value.ContentID;
  Boundary := value.Boundary;
  fileName := value.fileName;
  lines.assign(value.lines);
  PartBody.assign(value.PartBody);
  Headers.assign(value.Headers);
  PrePart.assign(value.PrePart);
  PostPart.assign(value.PostPart);
  maxLineLength := value.maxLineLength;
  FAttachInside := value.AttachInside;
  FConvertCharset := value.ConvertCharset;
end;

{==============================================================================}

PROCEDURE TMIMEPart.AssignSubParts(value: TMimePart);
VAR
  n: integer;
  p: TMimePart;
begin
  assign(value);
  for n := 0 to value.GetSubPartCount - 1 do
  begin
    p := AddSubPart;
    p.AssignSubParts(value.GetSubPart(n));
  end;
end;

{==============================================================================}

FUNCTION TMIMEPart.GetSubPartCount: integer;
begin
  result :=  FSubParts.count;
end;

{==============================================================================}

FUNCTION TMIMEPart.GetSubPart(index: integer): TMimePart;
begin
  result := nil;
  if index < GetSubPartCount then
    result := TMimePart(FSubParts[index]);
end;

{==============================================================================}

PROCEDURE TMIMEPart.DeleteSubPart(index: integer);
begin
  if index < GetSubPartCount then
  begin
    GetSubPart(index).free;
    FSubParts.Delete(index);
  end;
end;

{==============================================================================}

PROCEDURE TMIMEPart.ClearSubParts;
VAR
  n: integer;
begin
  for n := 0 to GetSubPartCount - 1 do
    TMimePart(FSubParts[n]).free;
  FSubParts.clear;
end;

{==============================================================================}

FUNCTION TMIMEPart.AddSubPart: TMimePart;
begin
  result := TMimePart.create;
  result.DefaultCharset := FDefaultCharset;
  FSubParts.add(result);
  result.SubLevel := FSubLevel + 1;
  result.MaxSubLevel := FMaxSubLevel;
end;

{==============================================================================}

PROCEDURE TMIMEPart.DecomposeParts;
VAR
  x: integer;
  s: string;
  Mime: TMimePart;

  PROCEDURE SkipEmpty;
  begin
    while FLines.count > x do
    begin
      s := trimRight(FLines[x]);
      if s <> '' then
        break;
      inc(x);
    end;
  end;

begin
  FBinaryDecomposer := false;
  x := 0;
  clear;
  //extract headers
  while FLines.count > x do
  begin
    s := NormalizeHeader(FLines, x);
    if s = '' then
      break;
    FHeaders.add(s);
  end;
  DecodePartHeader;
  //extract prepart
  if FPrimaryCode = MP_MULTIPART then
  begin
    while FLines.count > x do
    begin
      s := FLines[x];
      inc(x);
      if trimRight(s) = '--' + FBoundary then
        break;
      FPrePart.add(s);
      if not FAttachInside then
        FAttachInside := IsUUcode(s);
    end;
  end;
  //extract body part
  if FPrimaryCode = MP_MULTIPART then
  begin
    repeat
      if CanSubPart then
      begin
        Mime := AddSubPart;
        while FLines.count > x do
        begin
          s := FLines[x];
          inc(x);
          if pos('--' + FBoundary, s) = 1 then
            break;
          Mime.lines.add(s);
        end;
        Mime.DecomposeParts;
      end
      else
      begin
        s := FLines[x];
        inc(x);
        FPartBody.add(s);
      end;
      if x >= FLines.count then
        break;
    until s = '--' + FBoundary + '--';
  end;
  if (FPrimaryCode = MP_MESSAGE) and CanSubPart then
  begin
    Mime := AddSubPart;
    SkipEmpty;
    while FLines.count > x do
    begin
      s := trimRight(FLines[x]);
      inc(x);
      Mime.lines.add(s);
    end;
    Mime.DecomposeParts;
  end
  else
  begin
    while FLines.count > x do
    begin
      s := FLines[x];
      inc(x);
      FPartBody.add(s);
      if not FAttachInside then
        FAttachInside := IsUUcode(s);
    end;
  end;
  //extract postpart
  if FPrimaryCode = MP_MULTIPART then
  begin
    while FLines.count > x do
    begin
      s := trimRight(FLines[x]);
      inc(x);
      FPostPart.add(s);
      if not FAttachInside then
        FAttachInside := IsUUcode(s);
    end;
  end;
end;

PROCEDURE TMIMEPart.DecomposePartsBinary(AHeader:TStrings; AStx,AEtx:PAnsiChar);
VAR
  x:    integer;
  s:    ansistring;
  Mime: TMimePart;
  BOP:  PAnsiChar; // Beginning of Part
  EOP:  PAnsiChar; // End of Part

  FUNCTION ___HasUUCode(ALines:TStrings): boolean;
  VAR
    x: integer;
  begin
    result := false;
    for x:=0 to ALines.count-1 do
      if IsUUcode(ALInes[x]) then
      begin
        result := true;
        exit;
      end;
  end;

begin
  FBinaryDecomposer := true;
  clear;
  // Parse passed headers (THTTPSend returns HTTP headers and body separately)
  x := 0;
  while x<AHeader.count do
    begin
      s := NormalizeHeader(AHeader,x);
      if s = '' then
        break;
      FHeaders.add(s);
    end;
  DecodePartHeader;
  // Extract prepart
  if FPrimaryCode=MP_MULTIPART then
    begin
      CopyLinesFromStreamUntilBoundary(AStx,AEtx,FPrePart,FBoundary);
      FAttachInside := FAttachInside or ___HasUUCode(FPrePart);
    end;
  // Extract body part
  if FPrimaryCode=MP_MULTIPART then
    begin
      repeat
        if CanSubPart then
          begin
            Mime := AddSubPart;
            BOP  := AStx;
            EOP  := SearchForBoundary(AStx,AEtx,FBoundary);
            CopyLinesFromStreamUntilNullLine(BOP,EOP,Mime.lines);
            Mime.DecomposePartsBinary(Mime.lines,BOP,EOP);
          end
        else
          begin
            EOP := SearchForBoundary(AStx,AEtx,FBoundary);
            FPartBody.add(BuildStringFromBuffer(AStx,EOP));
          end;
        //
        BOP := MatchLastBoundary(EOP,AEtx,FBoundary);
        if Assigned(BOP) then
          begin
            AStx := BOP;
            break;
          end;
      until false;
    end;
  // Extract nested MIME message
  if (FPrimaryCode=MP_MESSAGE) and CanSubPart then
    begin
      Mime := AddSubPart;
      SkipNullLines(AStx,AEtx);
      CopyLinesFromStreamUntilNullLine(AStx,AEtx,Mime.lines);
      Mime.DecomposePartsBinary(Mime.lines,AStx,AEtx);
    end
  // Extract body of single part
  else
    begin
      FPartBody.add(BuildStringFromBuffer(AStx,AEtx));
      FAttachInside := FAttachInside or ___HasUUCode(FPartBody);
    end;
  // Extract postpart
  if FPrimaryCode=MP_MULTIPART then
    begin
      CopyLinesFromStreamUntilBoundary(AStx,AEtx,FPostPart,'');
      FAttachInside := FAttachInside or ___HasUUCode(FPostPart);
    end;
end;
{/pf}

{==============================================================================}

PROCEDURE TMIMEPart.ComposeParts;
VAR
  n: integer;
  mime: TMimePart;
  s, t: string;
  d1, d2, d3: integer;
  x: integer;
begin
  FLines.clear;
  //add headers
  for n := 0 to FHeaders.count -1 do
  begin
    s := FHeaders[n];
    repeat
      if length(s) < FMaxLineLength then
      begin
        t := s;
        s := '';
      end
      else
      begin
        d1 := RPosEx('; ', s, FMaxLineLength);
        d2 := RPosEx(' ', s, FMaxLineLength);
        d3 := RPosEx(', ', s, FMaxLineLength);
        if (d1 <= 1) and (d2 <= 1) and (d3 <= 1) then
        begin
          x := pos(' ', copy(s, 2, length(s) - 1));
          if x < 1 then
            x := length(s);
        end
        else
          if d1 > 0 then
            x := d1
          else
            if d3 > 0 then
              x := d3
            else
              x := d2 - 1;
        t := copy(s, 1, x);
        Delete(s, 1, x);
      end;
      Flines.add(t);
    until s = '';
  end;

  Flines.add('');
  //add body
  //if multipart
  if FPrimaryCode = MP_MULTIPART then
  begin
    Flines.AddStrings(FPrePart);
    for n := 0 to GetSubPartCount - 1 do
    begin
      Flines.add('--' + FBoundary);
      mime := GetSubPart(n);
      mime.ComposeParts;
      FLines.AddStrings(mime.lines);
    end;
    Flines.add('--' + FBoundary + '--');
    Flines.AddStrings(FPostPart);
  end;
  //if message
  if FPrimaryCode = MP_MESSAGE then
  begin
    if GetSubPartCount > 0 then
    begin
      mime := GetSubPart(0);
      mime.ComposeParts;
      FLines.AddStrings(mime.lines);
    end;
  end
  else
  //if normal part
  begin
    FLines.AddStrings(FPartBody);
  end;
end;

{==============================================================================}

PROCEDURE TMIMEPart.DecodePart;
VAR
  n: integer;
  s, t, t2: string;
  b: boolean;
begin
  FDecodedLines.clear;
  {pf}
  // The part decomposer passes data via TStringList which appends trailing line
  // break inherently. But in a case of native 8-bit data transferred withouth
  // encoding (default e.g. for HTTP protocol), the redundant line terminators
  // has to be removed
  if FBinaryDecomposer and (FPartBody.count=1) then
    begin
      case FEncodingCode of
          ME_QUOTED_PRINTABLE:
            s := DecodeQuotedPrintable(FPartBody[0]);
          ME_BASE64:
            s := DecodeBase64(FPartBody[0]);
          ME_UU, ME_XX:
            begin
              s := '';
              for n := 0 to FPartBody.count - 1 do
                if FEncodingCode = ME_UU then
                  s := s + DecodeUU(FPartBody[n])
                else
                  s := s + DecodeXX(FPartBody[n]);
            end;
        else
          s := FPartBody[0];
        end;
    end
  else
  {/pf}
  case FEncodingCode of
    ME_QUOTED_PRINTABLE:
      s := DecodeQuotedPrintable(FPartBody.text);
    ME_BASE64:
      s := DecodeBase64(FPartBody.text);
    ME_UU, ME_XX:
      begin
        s := '';
        for n := 0 to FPartBody.count - 1 do
          if FEncodingCode = ME_UU then
            s := s + DecodeUU(FPartBody[n])
          else
            s := s + DecodeXX(FPartBody[n]);
      end;
  else
    s := FPartBody.text;
  end;
  if FConvertCharset and (FPrimaryCode = MP_TEXT) then
    if (not FForcedHTMLConvert) and (uppercase(FSecondary) = 'HTML') then
    begin
      b := false;
      t2 := uppercase(s);
      t := SeparateLeft(t2, '</HEAD>');
      if length(t) <> length(s) then
      begin
        t := SeparateRight(t, '<HEAD>');
        t := ReplaceString(t, '"', '');
        t := ReplaceString(t, ' ', '');
        b := pos('HTTP-EQUIV=CONTENT-TYPE', t) > 0;
      end;
      //workaround for shitty M$ Outlook 11 which is placing this information
      //outside <head> section
      if not b then
      begin
        t := copy(t2, 1, 2048);
        t := ReplaceString(t, '"', '');
        t := ReplaceString(t, ' ', '');
        b := pos('HTTP-EQUIV=CONTENT-TYPE', t) > 0;
      end;
      if not b then
        s := CharsetConversion(s, FCharsetCode, FTargetCharset);
    end
    else
      s := CharsetConversion(s, FCharsetCode, FTargetCharset);
  WriteStrToStream(FDecodedLines, s);
  FDecodedLines.Seek(0, soFromBeginning);
end;

{==============================================================================}

PROCEDURE TMIMEPart.DecodePartHeader;
VAR
  n: integer;
  s, su, fn: string;
  st, st2: string;
begin
  Primary := 'text';
  FSecondary := 'plain';
  FDescription := '';
  charSet := FDefaultCharset;
  FFileName := '';
  //was 7bit before, but this is more compatible with RFC-ignorant outlook
  Encoding := '8BIT';
  FDisposition := '';
  FContentID := '';
  fn := '';
  for n := 0 to FHeaders.count - 1 do
    if FHeaders[n] <> '' then
    begin
      s := FHeaders[n];
      su := uppercase(s);
      if pos('CONTENT-TYPE:', su) = 1 then
      begin
        st := trim(SeparateRight(su, ':'));
        st2 := trim(SeparateLeft(st, ';'));
        Primary := trim(SeparateLeft(st2, '/'));
        FSecondary := trim(SeparateRight(st2, '/'));
        if (FSecondary = Primary) and (pos('/', st2) < 1) then
          FSecondary := '';
        case FPrimaryCode of
          MP_TEXT:
            begin
              charSet := uppercase(getParameter(s, 'charset'));
              FFileName := getParameter(s, 'name');
            end;
          MP_MULTIPART:
            FBoundary := getParameter(s, 'Boundary');
          MP_MESSAGE:
            begin
            end;
          MP_BINARY:
            FFileName := getParameter(s, 'name');
        end;
      end;
      if pos('CONTENT-TRANSFER-ENCODING:', su) = 1 then
        Encoding := trim(SeparateRight(su, ':'));
      if pos('CONTENT-DESCRIPTION:', su) = 1 then
        FDescription := trim(SeparateRight(s, ':'));
      if pos('CONTENT-DISPOSITION:', su) = 1 then
      begin
        FDisposition := SeparateRight(su, ':');
        FDisposition := trim(SeparateLeft(FDisposition, ';'));
        fn := getParameter(s, 'FileName');
      end;
      if pos('CONTENT-ID:', su) = 1 then
        FContentID := trim(SeparateRight(s, ':'));
    end;
  if fn <> '' then
    FFileName := fn;
  FFileName := InlineDecode(FFileName, FTargetCharset);
  FFileName := extractFileName(FFileName);
end;

{==============================================================================}

PROCEDURE TMIMEPart.EncodePart;
VAR
  l: TStringList;
  s, t: string;
  n, x: integer;
  d1, d2: integer;
begin
  if (FEncodingCode = ME_UU) or (FEncodingCode = ME_XX) then
    Encoding := 'base64';
  l := TStringList.create;
  FPartBody.clear;
  FDecodedLines.Seek(0, soFromBeginning);
  try
    case FPrimaryCode of
      MP_MULTIPART, MP_MESSAGE:
        FPartBody.LoadFromStream(FDecodedLines);
      MP_TEXT, MP_BINARY:
        begin
          s := ReadStrFromStream(FDecodedLines, FDecodedLines.size);
          if FConvertCharset and (FPrimaryCode = MP_TEXT) and (FEncodingCode <> ME_7BIT) then
            s := GetBOM(FCharSetCode) + CharsetConversion(s, FTargetCharset, FCharsetCode);
          if FEncodingCode = ME_BASE64 then
          begin
            x := 1;
            while x <= length(s) do
            begin
              t := copy(s, x, 54);
              x := x + length(t);
              t := EncodeBase64(t);
              FPartBody.add(t);
            end;
          end
          else
          begin
            if FPrimaryCode = MP_BINARY then
              l.add(s)
            else
              l.text := s;
            for n := 0 to l.count - 1 do
            begin
              s := l[n];
              if FEncodingCode = ME_QUOTED_PRINTABLE then
              begin
                s := EncodeQuotedPrintable(s);
                repeat
                  if length(s) < FMaxLineLength then
                  begin
                    t := s;
                    s := '';
                  end
                  else
                  begin
                    d1 := RPosEx('=', s, FMaxLineLength);
                    d2 := RPosEx(' ', s, FMaxLineLength);
                    if (d1 = 0) and (d2 = 0) then
                      x := FMaxLineLength
                    else
                      if d1 > d2 then
                        x := d1 - 1
                      else
                        x := d2 - 1;
                    if x = 0 then
                      x := FMaxLineLength;
                    t := copy(s, 1, x);
                    Delete(s, 1, x);
                    if s <> '' then
                      t := t + '=';
                  end;
                  FPartBody.add(t);
                until s = '';
              end
              else
                FPartBody.add(s);
            end;
            if (FPrimaryCode = MP_BINARY)
              and (FEncodingCode = ME_QUOTED_PRINTABLE) then
              FPartBody[FPartBody.count - 1] := FPartBody[FPartBody.count - 1] + '=';
          end;
        end;
    end;
  finally
    l.free;
  end;
end;

{==============================================================================}

PROCEDURE TMIMEPart.EncodePartHeader;
VAR
  s: string;
begin
  FHeaders.clear;
  if FSecondary = '' then
    case FPrimaryCode of
      MP_TEXT:
        FSecondary := 'plain';
      MP_MULTIPART:
        FSecondary := 'mixed';
      MP_MESSAGE:
        FSecondary := 'rfc822';
      MP_BINARY:
        FSecondary := 'octet-stream';
    end;
  if FDescription <> '' then
    FHeaders.Insert(0, 'Content-Description: ' + FDescription);
  if FDisposition <> '' then
  begin
    s := '';
    if FFileName <> '' then
      s := '; FileName=' + QuoteStr(InlineCodeEx(fileName, FTargetCharset), '"');
    FHeaders.Insert(0, 'Content-Disposition: ' + lowercase(FDisposition) + s);
  end;
  if FContentID <> '' then
    FHeaders.Insert(0, 'Content-ID: ' + FContentID);

  case FEncodingCode of
    ME_7BIT:
      s := '7bit';
    ME_8BIT:
      s := '8bit';
    ME_QUOTED_PRINTABLE:
      s := 'Quoted-printable';
    ME_BASE64:
      s := 'Base64';
  end;
  case FPrimaryCode of
    MP_TEXT,
      MP_BINARY: FHeaders.Insert(0, 'Content-Transfer-Encoding: ' + s);
  end;
  case FPrimaryCode of
    MP_TEXT:
      s := FPrimary + '/' + FSecondary + '; charset=' + GetIDfromCP(FCharsetCode);
    MP_MULTIPART:
      s := FPrimary + '/' + FSecondary + '; boundary="' + FBoundary + '"';
    MP_MESSAGE, MP_BINARY:
      s := FPrimary + '/' + FSecondary;
  end;
  if FFileName <> '' then
    s := s + '; name=' + QuoteStr(InlineCodeEx(fileName, FTargetCharset), '"');
  FHeaders.Insert(0, 'Content-type: ' + s);
end;

{==============================================================================}

PROCEDURE TMIMEPart.MimeTypeFromExt(value: string);
VAR
  s: string;
  n: integer;
begin
  Primary := '';
  FSecondary := '';
  s := uppercase(extractFileExt(value));
  if s = '' then
    s := uppercase(value);
  s := SeparateRight(s, '.');
  for n := 0 to MaxMimeType do
    if MimeType[n, 0] = s then
    begin
      Primary := MimeType[n, 1];
      FSecondary := MimeType[n, 2];
      break;
    end;
  if Primary = '' then
    Primary := 'application';
  if FSecondary = '' then
    FSecondary := 'octet-stream';
end;

{==============================================================================}

PROCEDURE TMIMEPart.WalkPart;
VAR
  n: integer;
  m: TMimepart;
begin
  if assigned(OnWalkPart) then
  begin
    OnWalkPart(self);
    for n := 0 to GetSubPartCount - 1 do
    begin
      m := GetSubPart(n);
      m.OnWalkPart := OnWalkPart;
      m.WalkPart;
    end;
  end;
end;

{==============================================================================}

PROCEDURE TMIMEPart.SetPrimary(value: string);
VAR
  s: string;
begin
  FPrimary := value;
  s := uppercase(value);
  FPrimaryCode := MP_BINARY;
  if pos('TEXT', s) = 1 then
    FPrimaryCode := MP_TEXT;
  if pos('MULTIPART', s) = 1 then
    FPrimaryCode := MP_MULTIPART;
  if pos('MESSAGE', s) = 1 then
    FPrimaryCode := MP_MESSAGE;
end;

PROCEDURE TMIMEPart.SetEncoding(value: string);
VAR
  s: string;
begin
  FEncoding := value;
  s := uppercase(value);
  FEncodingCode := ME_7BIT;
  if pos('8BIT', s) = 1 then
    FEncodingCode := ME_8BIT;
  if pos('QUOTED-PRINTABLE', s) = 1 then
    FEncodingCode := ME_QUOTED_PRINTABLE;
  if pos('BASE64', s) = 1 then
    FEncodingCode := ME_BASE64;
  if pos('X-UU', s) = 1 then
    FEncodingCode := ME_UU;
  if pos('X-XX', s) = 1 then
    FEncodingCode := ME_XX;
end;

PROCEDURE TMIMEPart.SetCharset(value: string);
begin
  if value <> '' then
  begin
    FCharset := value;
    FCharsetCode := GetCPFromID(value);
  end;
end;

FUNCTION TMIMEPart.CanSubPart: boolean;
begin
  result := true;
  if FMaxSubLevel <> -1 then
    result := FMaxSubLevel > FSubLevel;
end;

FUNCTION TMIMEPart.IsUUcode(value: string): boolean;
begin
  value := uppercase(value);
  result := (pos('BEGIN ', value) = 1) and (trim(SeparateRight(value, ' ')) <> '');
end;

{==============================================================================}

FUNCTION GenerateBoundary: string;
VAR
  x, y: integer;
begin
  y := GetTick;
  x := y;
  while TickDelta(y, x) = 0 do
  begin
    sleep(1);
    x := GetTick;
  end;
  randomize;
  y := random(MAXINT);
  result := IntToHex(x, 8) + '_' + IntToHex(y, 8) + '_Synapse_boundary';
end;

end.
