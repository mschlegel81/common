{==============================================================================|
| project : Ararat Synapse                                       | 004.015.000 |
|==============================================================================|
| content: support procedures and functions                                    |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2012.               |
| Portions created by Hernan Sanchez are Copyright (c) 2000.                   |
| Portions created by Petr Fejfar are Copyright (c)2011-2012.                  |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Hernan Sanchez (hernan.sanchez@iname.com)                                  |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Support procedures and functions)}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$R-}
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
  {$WARN SUSPICIOUS_TYPECAST OFF}
{$ENDIF}

UNIT synautil;

INTERFACE

USES
{$IFDEF MSWINDOWS}
  windows,
{$ELSE}
  {$IFDEF FPC}
    unixutil, unix, baseunix,
  {$ELSE}
    Libc,
  {$ENDIF}
{$ENDIF}
{$IFDEF CIL}
  system.IO,
{$ENDIF}
  sysutils, Classes, SynaFpc;

{$IFDEF VER100}
TYPE
  int64 = integer;
{$ENDIF}

{:Return your timezone bias from UTC time in minutes.}
FUNCTION TimeZoneBias: integer;

{:Return your timezone bias from UTC time in string representation like "+0200".}
FUNCTION TimeZone: string;

{:Returns current time in format defined in RFC-822. Useful for SMTP messages,
 but other protocols use this time format as well. Results contains the timezone
 specification. Four digit year is used to break any Y2K concerns. (example
 'Fri, 15 Oct 1999 21:14:56 +0200')}
FUNCTION Rfc822DateTime(t: TDateTime): string;

{:Returns date and time in format defined in C compilers in format "mmm dd hh:nn:ss"}
FUNCTION CDateTime(t: TDateTime): string;

{:Returns date and time in format defined in format 'yymmdd hhnnss'}
FUNCTION SimpleDateTime(t: TDateTime): string;

{:Returns date and time in format defined in ANSI C compilers in format
 "ddd mmm d hh:NN:SS yyyy" }
FUNCTION AnsiCDateTime(t: TDateTime): string;

{:Decode three-letter string with name of month to their month number. If string
 not match any month name, then is returned 0. for parsing are used predefined
 names for English, French and German and names from system locale too.}
FUNCTION GetMonthNumber(value: string): integer;

{:Return decoded time from given string. Time must be witch separator ':'. You
 can use "hh:mm" or "hh:mm:SS".}
FUNCTION GetTimeFromStr(value: string): TDateTime;

{:Decode string in format "m-d-y" to TDateTime type.}
FUNCTION GetDateMDYFromStr(value: string): TDateTime;

{:Decode various string representations of date and time to Tdatetime type.
 This FUNCTION do all timezone corrections too! This FUNCTION can decode lot of
  formats like:
 @longcode(#
 ddd, d mmm yyyy hh:mm:SS
 ddd, d mmm yy hh:mm:SS
 ddd, mmm d yyyy hh:mm:SS
 ddd mmm dd hh:mm:SS yyyy #)

and more with lot of modifications, include:
@longcode(#
Sun, 06 Nov 1994 08:49:37 GMT    ; RFC 822, updated by RFC 1123
Sunday, 06-Nov-94 08:49:37 GMT   ; RFC 850, obsoleted by RFC 1036
Sun Nov  6 08:49:37 1994         ; ANSI C's asctime() Format
#)
Timezone corrections known lot of symbolic timezone names (like CEST, EDT, etc.)
or numeric representation (like +0200). by convention defined in RFC timezone
 +0000 is GMT and -0000 is current your system timezone.}
FUNCTION DecodeRfcDateTime(value: string): TDateTime;

{:Return current system date and time in UTC timezone.}
FUNCTION GetUTTime: TDateTime;

{:Set Newdt as current system date and time in UTC timezone. This function work
 only if you have administrator rights!}
FUNCTION SetUTTime(Newdt: TDateTime): boolean;

{:Return current value of system timer with precizion 1 millisecond. Good for
 measure time difference.}
FUNCTION GetTick: Longword;

{:Return difference between two timestamps. It working fine only for differences
 smaller then MAXINT. (difference must be smaller then 24 days.)}
FUNCTION TickDelta(TickOld, TickNew: Longword): Longword;

{:Return two characters, which ordinal values represents the value in byte
 format. (high-endian)}
FUNCTION CodeInt(value: word): ansistring;

{:Decodes two characters located at "Index" offset position of the "Value"
 string to word values.}
FUNCTION DecodeInt(CONST value: ansistring; index: integer): word;

{:Return four characters, which ordinal values represents the value in byte
 format. (high-endian)}
FUNCTION CodeLongInt(value: longint): ansistring;

{:Decodes four characters located at "Index" offset position of the "Value"
 string to longint values.}
FUNCTION DecodeLongInt(CONST value: ansistring; index: integer): longint;

{:Dump binary buffer stored in a string to a result string.}
FUNCTION DumpStr(CONST buffer: ansistring): string;

{:Dump binary buffer stored in a string to a result string. All bytes with code
 of character is written as character, not as hexadecimal value.}
FUNCTION DumpExStr(CONST buffer: ansistring): string;

{:Dump binary buffer stored in a string to a file with DumpFile filename.}
PROCEDURE Dump(CONST buffer: ansistring; DumpFile: string);

{:Dump binary buffer stored in a string to a file with DumpFile filename. All
 bytes with code of character is written as character, not as hexadecimal value.}
PROCEDURE DumpEx(CONST buffer: ansistring; DumpFile: string);

{:Like TrimLeft, but remove only spaces, not control characters!}
FUNCTION TrimSPLeft(CONST S: string): string;

{:Like TrimRight, but remove only spaces, not control characters!}
FUNCTION TrimSPRight(CONST S: string): string;

{:Like Trim, but remove only spaces, not control characters!}
FUNCTION TrimSP(CONST S: string): string;

{:Returns a portion of the "Value" string located to the left of the "Delimiter"
 string. if a delimiter is not found, results is original string.}
FUNCTION SeparateLeft(CONST value, Delimiter: string): string;

{:Returns the portion of the "Value" string located to the right of the
 "Delimiter" string. if a delimiter is not found, results is original string.}
FUNCTION SeparateRight(CONST value, Delimiter: string): string;

{:Returns parameter value from string in format:
 parameter1="value1"; parameter2=value2}
FUNCTION getParameter(CONST value, Parameter: string): string;

{:parse value string with elements differed by Delimiter into stringlist.}
PROCEDURE ParseParametersEx(value, Delimiter: string; CONST parameters: TStrings);

{:parse value string with elements differed by ';' into stringlist.}
PROCEDURE ParseParameters(value: string; CONST parameters: TStrings);

{:Index of string in stringlist with same beginning as Value is returned.}
FUNCTION IndexByBegin(value: string; CONST list: TStrings): integer;

{:Returns only the e-mail portion of an address from the full address format.
 i.e. returns 'nobody@@somewhere.com' from '"someone" <nobody@@somewhere.com>'}
FUNCTION GetEmailAddr(CONST value: string): string;

{:Returns only the description part from a full address format. i.e. returns
 'someone' from '"someone" <nobody@@somewhere.com>'}
FUNCTION GetEmailDesc(value: string): string;

{:Returns a string with hexadecimal digits representing the corresponding values
 of the bytes found in "value" string.}
FUNCTION StrToHex(CONST value: ansistring): string;

{:Returns a string of binary "Digits" representing "Value".}
FUNCTION IntToBin(value: integer; digits: byte): string;

{:Returns an integer equivalent of the binary string in "Value".
 (i.e. ('10001010') returns 138)}
FUNCTION BinToInt(CONST value: string): integer;

{:Parses a URL to its various components.}
FUNCTION ParseURL(URL: string; VAR Prot, User, Pass, Host, Port, path,
  Para: string): string;

{:Replaces all "Search" string values found within "Value" string, with the
 "Replace" string value.}
FUNCTION ReplaceString(value, Search, Replace: ansistring): ansistring;

{:It is like RPos, but search is from specified possition.}
FUNCTION RPosEx(CONST sub, value: string; From: integer): integer;

{:It is like POS function, but from right side of Value string.}
FUNCTION RPos(CONST sub, value: string): integer;

{:Like @link(fetch), but working with binary strings, not with text.}
FUNCTION FetchBin(VAR value: string; CONST Delimiter: string): string;

{:Fetch string from left of Value string.}
FUNCTION Fetch(VAR value: string; CONST Delimiter: string): string;

{:Fetch string from left of Value string. This function ignore delimitesr inside
 quotations.}
FUNCTION FetchEx(VAR value: string; CONST Delimiter, Quotation: string): string;

{:If string is binary string (contains non-printable characters), then is
 returned true.}
FUNCTION IsBinaryString(CONST value: ansistring): boolean;

{:return position of string terminator in string. If terminator found, then is
 returned in terminator parameter.
 Possible line terminators are: CRLF, LFCR, CR, LF}
FUNCTION PosCRLF(CONST value: ansistring; VAR Terminator: ansistring): integer;

{:Delete empty strings from end of stringlist.}
PROCEDURE StringsTrim(CONST value: TStrings);

{:Like Pos function, buf from given string possition.}
FUNCTION PosFrom(CONST SubStr, value: string; From: integer): integer;

{$IFNDEF CIL}
{:Increase pointer by value.}
FUNCTION IncPoint(CONST p: pointer; value: integer): pointer;
{$ENDIF}

{:Get string between PairBegin and PairEnd. This function respect nesting.
 for example:
 @longcode(#
 value is: 'Hi! (hello(yes!))'
 pairbegin is: '('
 pairend is: ')'
 in this case result is: 'hello(yes!)'#)}
FUNCTION GetBetween(CONST PairBegin, PairEnd, value: string): string;

{:Return count of Chr in Value string.}
FUNCTION CountOfChar(CONST value: string; chr: char): integer;

{:Remove quotation from Value string. If Value is not quoted, then return same
 string without any modification. }
FUNCTION UnquoteStr(CONST value: string; Quote: char): string;

{:Quote Value string. If Value contains some Quote chars, then it is doubled.}
FUNCTION QuoteStr(CONST value: string; Quote: char): string;

{:Convert lines in stringlist from 'name: value' form to 'name=value' form.}
PROCEDURE HeadersToList(CONST value: TStrings);

{:Convert lines in stringlist from 'name=value' form to 'name: value' form.}
PROCEDURE ListToHeaders(CONST value: TStrings);

{:swap bytes in integer.}
FUNCTION SwapBytes(value: integer): integer;

{:read string with requested length form stream.}
FUNCTION ReadStrFromStream(CONST Stream: TStream; len: integer): ansistring;

{:write string to stream.}
PROCEDURE WriteStrToStream(CONST Stream: TStream; value: ansistring);

{:Return filename of new temporary file in Dir (if empty, then default temporary
 directory is used) and with optional fileName prefix.}
FUNCTION GetTempFile(CONST dir, prefix: ansistring): ansistring;

{:Return padded string. If length is greater, string is truncated. If length is
 smaller, string is padded by Pad character.}
FUNCTION PadString(CONST value: ansistring; len: integer; Pad: AnsiChar): ansistring;

{:XOR each byte in the strings}
FUNCTION XorString(Indata1, Indata2: ansistring): ansistring;

{:Read header from "Value" stringlist beginning at "Index" position. If header
 is Splitted into multiple lines, then this PROCEDURE de-split it into one line.}
FUNCTION NormalizeHeader(value: TStrings; VAR index: integer): string;

{pf}
{:Search for one of line terminators CR, LF or NUL. Return position of the
 line beginning and length of text.}
PROCEDURE SearchForLineBreak(VAR APtr:PAnsiChar; AEtx:PAnsiChar; OUT ABol:PAnsiChar; OUT ALength:integer);
{:Skip both line terminators CR LF (if any). Move APtr position forward.}
PROCEDURE SkipLineBreak(VAR APtr:PAnsiChar; AEtx:PAnsiChar);
{:Skip all blank lines in a buffer starting at APtr and move APtr position forward.}
PROCEDURE SkipNullLines                   (VAR APtr:PAnsiChar; AEtx:PAnsiChar);
{:Copy all lines from a buffer starting at APtr to ALines until empty line
 or end of the buffer is reached. move APtr position forward).}
PROCEDURE CopyLinesFromStreamUntilNullLine(VAR APtr:PAnsiChar; AEtx:PAnsiChar; ALines:TStrings);
{:Copy all lines from a buffer starting at APtr to ALines until ABoundary
 or end of the buffer is reached. move APtr position forward).}
PROCEDURE CopyLinesFromStreamUntilBoundary(VAR APtr:PAnsiChar; AEtx:PAnsiChar; ALines:TStrings; CONST ABoundary:ansistring);
{:Search ABoundary in a buffer starting at APtr.
 Return beginning of the ABoundary. move APtr forward behind a trailing CRLF if any).}
FUNCTION  SearchForBoundary               (VAR APtr:PAnsiChar; AEtx:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
{:Compare a text at position ABOL with ABoundary and return position behind the
 match (including a trailing CRLF if any).}
FUNCTION  MatchBoundary                   (ABOL,AETX:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
{:Compare a text at position ABOL with ABoundary + the last boundary suffix
 and return position behind the match (including a trailing CRLF if any).}
FUNCTION  MatchLastBoundary               (ABOL,AETX:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
{:Copy data from a buffer starting at position APtr and delimited by AEtx
 position into ansistring.}
FUNCTION  BuildStringFromBuffer           (AStx,AEtx:PAnsiChar): ansistring;
{/pf}

VAR
  {:can be used for your own months strings for @link(getmonthnumber)}
  CustomMonthNames: array[1..12] of string;

IMPLEMENTATION

{==============================================================================}

CONST
  MyDayNames: array[1..7] of ansistring =
    ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
VAR
  MyMonthNames: array[0..6, 1..12] of string =
    (
    ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',  //rewrited by system locales
     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
    ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',  //English
     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
    ('jan', 'fév', 'mar', 'avr', 'mai', 'jun', //French
     'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'),
    ('jan', 'fev', 'mar', 'avr', 'mai', 'jun',  //French#2
     'jul', 'aou', 'sep', 'oct', 'nov', 'dec'),
    ('Jan', 'Feb', 'Mar', 'Apr', 'Mai', 'Jun',  //German
     'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
    ('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',  //German#2
     'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
    ('Led', 'Úno', 'Bøe', 'Dub', 'Kvì', 'Èen',  //Czech
     'Èec', 'Srp', 'Záø', 'Øíj', 'Lis', 'Pro')
     );


{==============================================================================}

FUNCTION TimeZoneBias: integer;
{$IFNDEF MSWINDOWS}
{$IFNDEF FPC}
VAR
  t: TTime_T;
  UT: TUnixTime;
begin
  __time(@T);
  localtime_r(@T, UT);
  result := ut.__tm_gmtoff div 60;
{$ELSE}
begin
  result := TZSeconds div 60;
{$ENDIF}
{$ELSE}
VAR
  zoneinfo: TTimeZoneInformation;
  bias: integer;
begin
  case GetTimeZoneInformation(Zoneinfo) of
    2:
      bias := zoneinfo.Bias + zoneinfo.DaylightBias;
    1:
      bias := zoneinfo.Bias + zoneinfo.StandardBias;
  else
    bias := zoneinfo.Bias;
  end;
  result := bias * (-1);
{$ENDIF}
end;

{==============================================================================}

FUNCTION TimeZone: string;
VAR
  bias: integer;
  h, m: integer;
begin
  bias := TimeZoneBias;
  if bias >= 0 then
    result := '+'
  else
    result := '-';
  bias := abs(bias);
  h := bias div 60;
  m := bias mod 60;
  result := result + format('%.2d%.2d', [h, m]);
end;

{==============================================================================}

FUNCTION Rfc822DateTime(t: TDateTime): string;
VAR
  wYear, wMonth, wDay: word;
begin
  DecodeDate(t, wYear, wMonth, wDay);
  result := format('%s, %d %s %s %s', [MyDayNames[DayOfWeek(t)], wDay,
    MyMonthNames[1, wMonth], FormatDateTime('yyyy hh":"nn":"ss', t), TimeZone]);
end;

{==============================================================================}

FUNCTION CDateTime(t: TDateTime): string;
VAR
  wYear, wMonth, wDay: word;
begin
  DecodeDate(t, wYear, wMonth, wDay);
  result:= format('%s %2d %s', [MyMonthNames[1, wMonth], wDay,
    FormatDateTime('hh":"nn":"ss', t)]);
end;

{==============================================================================}

FUNCTION SimpleDateTime(t: TDateTime): string;
begin
  result := FormatDateTime('yymmdd hhnnss', t);
end;

{==============================================================================}

FUNCTION AnsiCDateTime(t: TDateTime): string;
VAR
  wYear, wMonth, wDay: word;
begin
  DecodeDate(t, wYear, wMonth, wDay);
  result := format('%s %s %d %s', [MyDayNames[DayOfWeek(t)], MyMonthNames[1, wMonth],
    wDay, FormatDateTime('hh":"nn":"ss yyyy ', t)]);
end;

{==============================================================================}

FUNCTION DecodeTimeZone(value: string; VAR Zone: integer): boolean;
VAR
  x: integer;
  zh, zm: integer;
  s: string;
begin
  result := false;
  s := value;
  if (pos('+', s) = 1) or (pos('-',s) = 1) then
  begin
    if s = '-0000' then
      Zone := TimeZoneBias
    else
      if length(s) > 4 then
      begin
        zh := strToIntDef(s[2] + s[3], 0);
        zm := strToIntDef(s[4] + s[5], 0);
        zone := zh * 60 + zm;
        if s[1] = '-' then
          zone := zone * (-1);
      end;
    result := true;
  end
  else
  begin
    x := 32767;
    if s = 'NZDT' then x := 13;
    if s = 'IDLE' then x := 12;
    if s = 'NZST' then x := 12;
    if s = 'NZT' then x := 12;
    if s = 'EADT' then x := 11;
    if s = 'GST' then x := 10;
    if s = 'JST' then x := 9;
    if s = 'CCT' then x := 8;
    if s = 'WADT' then x := 8;
    if s = 'WAST' then x := 7;
    if s = 'ZP6' then x := 6;
    if s = 'ZP5' then x := 5;
    if s = 'ZP4' then x := 4;
    if s = 'BT' then x := 3;
    if s = 'EET' then x := 2;
    if s = 'MEST' then x := 2;
    if s = 'MESZ' then x := 2;
    if s = 'SST' then x := 2;
    if s = 'FST' then x := 2;
    if s = 'CEST' then x := 2;
    if s = 'CET' then x := 1;
    if s = 'FWT' then x := 1;
    if s = 'MET' then x := 1;
    if s = 'MEWT' then x := 1;
    if s = 'SWT' then x := 1;
    if s = 'UT' then x := 0;
    if s = 'UTC' then x := 0;
    if s = 'GMT' then x := 0;
    if s = 'WET' then x := 0;
    if s = 'WAT' then x := -1;
    if s = 'BST' then x := -1;
    if s = 'AT' then x := -2;
    if s = 'ADT' then x := -3;
    if s = 'AST' then x := -4;
    if s = 'EDT' then x := -4;
    if s = 'EST' then x := -5;
    if s = 'CDT' then x := -5;
    if s = 'CST' then x := -6;
    if s = 'MDT' then x := -6;
    if s = 'MST' then x := -7;
    if s = 'PDT' then x := -7;
    if s = 'PST' then x := -8;
    if s = 'YDT' then x := -8;
    if s = 'YST' then x := -9;
    if s = 'HDT' then x := -9;
    if s = 'AHST' then x := -10;
    if s = 'CAT' then x := -10;
    if s = 'HST' then x := -10;
    if s = 'EAST' then x := -10;
    if s = 'NT' then x := -11;
    if s = 'IDLW' then x := -12;
    if x <> 32767 then
    begin
      zone := x * 60;
      result := true;
    end;
  end;
end;

{==============================================================================}

FUNCTION GetMonthNumber(value: string): integer;
VAR
  n: integer;
  FUNCTION TestMonth(value: string; index: integer): boolean;
  VAR
    n: integer;
  begin
    result := false;
    for n := 0 to 6 do
      if value = AnsiUppercase(MyMonthNames[n, index]) then
      begin
        result := true;
        break;
      end;
  end;
begin
  result := 0;
  value := AnsiUppercase(value);
  for n := 1 to 12 do
    if TestMonth(value, n) or (value = AnsiUppercase(CustomMonthNames[n])) then
    begin
      result := n;
      break;
    end;
end;

{==============================================================================}

FUNCTION GetTimeFromStr(value: string): TDateTime;
VAR
  x: integer;
begin
  x := rpos(':', value);
  if (x > 0) and ((length(value) - x) > 2) then
    value := copy(value, 1, x + 2);
  value := ReplaceString(value, ':', TimeSeparator);
  result := -1;
  try
    result := StrToTime(value);
  except
    on Exception do ;
  end;
end;

{==============================================================================}

FUNCTION GetDateMDYFromStr(value: string): TDateTime;
VAR
  wYear, wMonth, wDay: word;
  s: string;
begin
  result := 0;
  s := Fetch(value, '-');
  wMonth := strToIntDef(s, 12);
  s := Fetch(value, '-');
  wDay := strToIntDef(s, 30);
  wYear := strToIntDef(value, 1899);
  if wYear < 1000 then
    if (wYear > 99) then
      wYear := wYear + 1900
    else
      if wYear > 50 then
        wYear := wYear + 1900
      else
        wYear := wYear + 2000;
  try
    result := EncodeDate(wYear, wMonth, wDay);
  except
    on Exception do ;
  end;
end;

{==============================================================================}

FUNCTION DecodeRfcDateTime(value: string): TDateTime;
VAR
  day, month, year: word;
  zone: integer;
  x, y: integer;
  s: string;
  t: TDateTime;
begin
// ddd, d mmm yyyy hh:mm:ss
// ddd, d mmm yy hh:mm:ss
// ddd, mmm d yyyy hh:mm:ss
// ddd mmm dd hh:mm:ss yyyy
// Sun, 06 Nov 1994 08:49:37 GMT    ; RFC 822, updated by RFC 1123
// Sunday, 06-Nov-94 08:49:37 GMT   ; RFC 850, obsoleted by RFC 1036
// Sun Nov  6 08:49:37 1994         ; ANSI C's asctime() Format

  result := 0;
  if value = '' then
    exit;
  day := 0;
  month := 0;
  year := 0;
  zone := 0;
  value := ReplaceString(value, ' -', ' #');
  value := ReplaceString(value, '-', ' ');
  value := ReplaceString(value, ' #', ' -');
  while value <> '' do
  begin
    s := Fetch(value, ' ');
    s := uppercase(s);
    // timezone
    if DecodetimeZone(s, x) then
    begin
      zone := x;
      continue;
    end;
    x := strToIntDef(s, 0);
    // day or year
    if x > 0 then
      if (x < 32) and (day = 0) then
      begin
        day := x;
        continue;
      end
      else
      begin
        if (year = 0) and ((month > 0) or (x > 12)) then
        begin
          year := x;
          if year < 32 then
            year := year + 2000;
          if year < 1000 then
           year := year + 1900;
          continue;
        end;
      end;
    // time
    if rpos(':', s) > pos(':', s) then
    begin
      t := GetTimeFromStr(s);
      if t <> -1 then
        result := t;
      continue;
    end;
    //timezone daylight saving time
    if s = 'DST' then
    begin
      zone := zone + 60;
      continue;
    end;
    // month
    y := GetMonthNumber(s);
    if (y > 0) and (month = 0) then
      month := y;
  end;
  if year = 0 then
    year := 1980;
  if month < 1 then
    month := 1;
  if month > 12 then
    month := 12;
  if day < 1 then
    day := 1;
  x := MonthDays[IsLeapYear(year), month];
  if day > x then
    day := x;
  result := result + EncodeDate(year, month, day);
  zone := zone - TimeZoneBias;
  x := zone div 1440;
  result := result - x;
  zone := zone mod 1440;
  t := EncodeTime(abs(zone) div 60, abs(zone) mod 60, 0, 0);
  if zone < 0 then
    t := 0 - t;
  result := result - t;
end;

{==============================================================================}

FUNCTION GetUTTime: TDateTime;
{$IFDEF MSWINDOWS}
{$IFNDEF FPC}
VAR
  st: TSystemTime;
begin
  GetSystemTime(st);
  result := SystemTimeToDateTime(st);
{$ELSE}
VAR
  st: sysutils.TSystemTime;
  stw: windows.TSystemTime;
begin
  GetSystemTime(stw);
  st.Year := stw.wYear;
  st.Month := stw.wMonth;
  st.Day := stw.wDay;
  st.hour := stw.wHour;
  st.Minute := stw.wMinute;
  st.Second := stw.wSecond;
  st.Millisecond := stw.wMilliseconds;
  result := SystemTimeToDateTime(st);
{$ENDIF}
{$ELSE}
{$IFNDEF FPC}
VAR
  TV: TTimeVal;
begin
  gettimeofday(TV, nil);
  result := UnixDateDelta + (TV.tv_sec + TV.tv_usec / 1000000) / 86400;
{$ELSE}
VAR
  TV: timeval;
begin
  fpgettimeofday(@TV, nil);
  result := UnixDateDelta + (TV.tv_sec + TV.tv_usec / 1000000) / 86400;
{$ENDIF}
{$ENDIF}
end;

{==============================================================================}

FUNCTION SetUTTime(Newdt: TDateTime): boolean;
{$IFDEF MSWINDOWS}
{$IFNDEF FPC}
VAR
  st: TSystemTime;
begin
  DateTimeToSystemTime(newdt,st);
  result := SetSystemTime(st);
{$ELSE}
VAR
  st: sysutils.TSystemTime;
  stw: windows.TSystemTime;
begin
  DateTimeToSystemTime(newdt,st);
  stw.wYear := st.Year;
  stw.wMonth := st.Month;
  stw.wDay := st.Day;
  stw.wHour := st.hour;
  stw.wMinute := st.Minute;
  stw.wSecond := st.Second;
  stw.wMilliseconds := st.Millisecond;
  result := SetSystemTime(stw);
{$ENDIF}
{$ELSE}
{$IFNDEF FPC}
VAR
  TV: TTimeVal;
  d: double;
  tz: Ttimezone;
  PZ: PTimeZone;
begin
  tz.tz_minuteswest := 0;
  tz.tz_dsttime := 0;
  PZ := @tz;
  gettimeofday(TV, PZ);
  d := (newdt - UnixDateDelta) * 86400;
  TV.tv_sec := trunc(d);
  TV.tv_usec := trunc(frac(d) * 1000000);
  result := settimeofday(TV, tz) <> -1;
{$ELSE}
VAR
  TV: timeval;
  d: double;
begin
  d := (newdt - UnixDateDelta) * 86400;
  TV.tv_sec := trunc(d);
  TV.tv_usec := trunc(frac(d) * 1000000);
  result := fpsettimeofday(@TV, nil) <> -1;
{$ENDIF}
{$ENDIF}
end;

{==============================================================================}

{$IFNDEF MSWINDOWS}
FUNCTION GetTick: Longword;
VAR
  Stamp: TTimeStamp;
begin
  Stamp := DateTimeToTimeStamp(now);
  result := Stamp.time;
end;
{$ELSE}
FUNCTION GetTick: Longword;
VAR
  tick, freq: TLargeInteger;
{$IFDEF VER100}
  x: TLargeInteger;
{$ENDIF}
begin
  if windows.QueryPerformanceFrequency(freq) then
  begin
    windows.QueryPerformanceCounter(tick);
{$IFDEF VER100}
    x.QuadPart := (tick.QuadPart / freq.QuadPart) * 1000;
    result := x.LowPart;
{$ELSE}
    result := trunc((tick / freq) * 1000) and high(Longword)
{$ENDIF}
  end
  else
    result := windows.GetTickCount;
end;
{$ENDIF}

{==============================================================================}

FUNCTION TickDelta(TickOld, TickNew: Longword): Longword;
begin
//if DWord is signed type (older Deplhi),
// then it not work properly on differencies larger then maxint!
  result := 0;
  if TickOld <> TickNew then
  begin
    if TickNew < TickOld then
    begin
      TickNew := TickNew + Longword(MAXINT) + 1;
      TickOld := TickOld + Longword(MAXINT) + 1;
    end;
    result := TickNew - TickOld;
    if TickNew < TickOld then
      if result > 0 then
        result := 0 - result;
  end;
end;

{==============================================================================}

FUNCTION CodeInt(value: word): ansistring;
begin
  setLength(result, 2);
  result[1] := AnsiChar(value div 256);
  result[2] := AnsiChar(value mod 256);
//  Result := AnsiChar(Value div 256) + AnsiChar(Value mod 256)
end;

{==============================================================================}

FUNCTION DecodeInt(CONST value: ansistring; index: integer): word;
VAR
  x, y: byte;
begin
  if length(value) > index then
    x := ord(value[index])
  else
    x := 0;
  if length(value) >= (index + 1) then
    y := ord(value[index + 1])
  else
    y := 0;
  result := x * 256 + y;
end;

{==============================================================================}

FUNCTION CodeLongInt(value: longint): ansistring;
VAR
  x, y: word;
begin
  // this is fix for negative numbers on systems where longint = integer
  x := (value shr 16) and integer($FFFF);
  y := value and integer($FFFF);
  setLength(result, 4);
  result[1] := AnsiChar(x div 256);
  result[2] := AnsiChar(x mod 256);
  result[3] := AnsiChar(y div 256);
  result[4] := AnsiChar(y mod 256);
end;

{==============================================================================}

FUNCTION DecodeLongInt(CONST value: ansistring; index: integer): longint;
VAR
  x, y: byte;
  xl, yl: byte;
begin
  if length(value) > index then
    x := ord(value[index])
  else
    x := 0;
  if length(value) >= (index + 1) then
    y := ord(value[index + 1])
  else
    y := 0;
  if length(value) >= (index + 2) then
    xl := ord(value[index + 2])
  else
    xl := 0;
  if length(value) >= (index + 3) then
    yl := ord(value[index + 3])
  else
    yl := 0;
  result := ((x * 256 + y) * 65536) + (xl * 256 + yl);
end;

{==============================================================================}

FUNCTION DumpStr(CONST buffer: ansistring): string;
VAR
  n: integer;
begin
  result := '';
  for n := 1 to length(buffer) do
    result := result + ' +#$' + IntToHex(ord(buffer[n]), 2);
end;

{==============================================================================}

FUNCTION DumpExStr(CONST buffer: ansistring): string;
VAR
  n: integer;
  x: byte;
begin
  result := '';
  for n := 1 to length(buffer) do
  begin
    x := ord(buffer[n]);
    if x in [65..90, 97..122] then
      result := result + ' +''' + char(x) + ''''
    else
      result := result + ' +#$' + IntToHex(ord(buffer[n]), 2);
  end;
end;

{==============================================================================}

PROCEDURE Dump(CONST buffer: ansistring; DumpFile: string);
VAR
  f: text;
begin
  AssignFile(f, DumpFile);
  if fileExists(DumpFile) then
    DeleteFile(DumpFile);
  rewrite(f);
  try
    writeln(f, DumpStr(buffer));
  finally
    CloseFile(f);
  end;
end;

{==============================================================================}

PROCEDURE DumpEx(CONST buffer: ansistring; DumpFile: string);
VAR
  f: text;
begin
  AssignFile(f, DumpFile);
  if fileExists(DumpFile) then
    DeleteFile(DumpFile);
  rewrite(f);
  try
    writeln(f, DumpExStr(buffer));
  finally
    CloseFile(f);
  end;
end;

{==============================================================================}

FUNCTION TrimSPLeft(CONST S: string): string;
VAR
  I, L: integer;
begin
  result := '';
  if S = '' then
    exit;
  L := length(S);
  I := 1;
  while (I <= L) and (S[I] = ' ') do
    inc(I);
  result := copy(S, I, MAXINT);
end;

{==============================================================================}

FUNCTION TrimSPRight(CONST S: string): string;
VAR
  I: integer;
begin
  result := '';
  if S = '' then
    exit;
  I := length(S);
  while (I > 0) and (S[I] = ' ') do
    dec(I);
  result := copy(S, 1, I);
end;

{==============================================================================}

FUNCTION TrimSP(CONST S: string): string;
begin
  result := TrimSPLeft(s);
  result := TrimSPRight(result);
end;

{==============================================================================}

FUNCTION SeparateLeft(CONST value, Delimiter: string): string;
VAR
  x: integer;
begin
  x := pos(Delimiter, value);
  if x < 1 then
    result := value
  else
    result := copy(value, 1, x - 1);
end;

{==============================================================================}

FUNCTION SeparateRight(CONST value, Delimiter: string): string;
VAR
  x: integer;
begin
  x := pos(Delimiter, value);
  if x > 0 then
    x := x + length(Delimiter) - 1;
  result := copy(value, x + 1, length(value) - x);
end;

{==============================================================================}

FUNCTION getParameter(CONST value, Parameter: string): string;
VAR
  s: string;
  v: string;
begin
  result := '';
  v := value;
  while v <> '' do
  begin
    s := trim(FetchEx(v, ';', '"'));
    if pos(uppercase(parameter), uppercase(s)) = 1 then
    begin
      Delete(s, 1, length(Parameter));
      s := trim(s);
      if s = '' then
        break;
      if s[1] = '=' then
      begin
        result := trim(SeparateRight(s, '='));
        result := UnquoteStr(result, '"');
        break;
      end;
    end;
  end;
end;

{==============================================================================}

PROCEDURE ParseParametersEx(value, Delimiter: string; CONST parameters: TStrings);
VAR
  s: string;
begin
  parameters.clear;
  while value <> '' do
  begin
    s := trim(FetchEx(value, Delimiter, '"'));
    parameters.add(s);
  end;
end;

{==============================================================================}

PROCEDURE ParseParameters(value: string; CONST parameters: TStrings);
begin
  ParseParametersEx(value, ';', parameters);
end;

{==============================================================================}

FUNCTION IndexByBegin(value: string; CONST list: TStrings): integer;
VAR
  n: integer;
  s: string;
begin
  result := -1;
  value := uppercase(value);
  for n := 0 to list.count -1 do
  begin
    s := uppercase(list[n]);
    if pos(value, s) = 1 then
    begin
      result := n;
      break;
    end;
  end;
end;

{==============================================================================}

FUNCTION GetEmailAddr(CONST value: string): string;
VAR
  s: string;
begin
  s := SeparateRight(value, '<');
  s := SeparateLeft(s, '>');
  result := trim(s);
end;

{==============================================================================}

FUNCTION GetEmailDesc(value: string): string;
VAR
  s: string;
begin
  value := trim(value);
  s := SeparateRight(value, '"');
  if s <> value then
    s := SeparateLeft(s, '"')
  else
  begin
    s := SeparateLeft(value, '<');
    if s = value then
    begin
      s := SeparateRight(value, '(');
      if s <> value then
        s := SeparateLeft(s, ')')
      else
        s := '';
    end;
  end;
  result := trim(s);
end;

{==============================================================================}

FUNCTION StrToHex(CONST value: ansistring): string;
VAR
  n: integer;
begin
  result := '';
  for n := 1 to length(value) do
    result := result + IntToHex(byte(value[n]), 2);
  result := lowercase(result);
end;

{==============================================================================}

FUNCTION IntToBin(value: integer; digits: byte): string;
VAR
  x, y, n: integer;
begin
  result := '';
  x := value;
  repeat
    y := x mod 2;
    x := x div 2;
    if y > 0 then
      result := '1' + result
    else
      result := '0' + result;
  until x = 0;
  x := length(result);
  for n := x to digits - 1 do
    result := '0' + result;
end;

{==============================================================================}

FUNCTION BinToInt(CONST value: string): integer;
VAR
  n: integer;
begin
  result := 0;
  for n := 1 to length(value) do
  begin
    if value[n] = '0' then
      result := result * 2
    else
      if value[n] = '1' then
        result := result * 2 + 1
      else
        break;
  end;
end;

{==============================================================================}

FUNCTION ParseURL(URL: string; VAR Prot, User, Pass, Host, Port, path,
  Para: string): string;
VAR
  x, y: integer;
  sURL: string;
  s: string;
  s1, s2: string;
begin
  Prot := 'http';
  User := '';
  Pass := '';
  Port := '80';
  Para := '';

  x := pos('://', URL);
  if x > 0 then
  begin
    Prot := SeparateLeft(URL, '://');
    sURL := SeparateRight(URL, '://');
  end
  else
    sURL := URL;
  if uppercase(Prot) = 'HTTPS' then
    Port := '443';
  if uppercase(Prot) = 'FTP' then
    Port := '21';
  x := pos('@', sURL);
  y := pos('/', sURL);
  if (x > 0) and ((x < y) or (y < 1))then
  begin
    s := SeparateLeft(sURL, '@');
    sURL := SeparateRight(sURL, '@');
    x := pos(':', s);
    if x > 0 then
    begin
      User := SeparateLeft(s, ':');
      Pass := SeparateRight(s, ':');
    end
    else
      User := s;
  end;
  x := pos('/', sURL);
  if x > 0 then
  begin
    s1 := SeparateLeft(sURL, '/');
    s2 := SeparateRight(sURL, '/');
  end
  else
  begin
    s1 := sURL;
    s2 := '';
  end;
  if pos('[', s1) = 1 then
  begin
    Host := Separateleft(s1, ']');
    Delete(Host, 1, 1);
    s1 := SeparateRight(s1, ']');
    if pos(':', s1) = 1 then
      Port := SeparateRight(s1, ':');
  end
  else
  begin
    x := pos(':', s1);
    if x > 0 then
    begin
      Host := SeparateLeft(s1, ':');
      Port := SeparateRight(s1, ':');
    end
    else
      Host := s1;
  end;
  result := '/' + s2;
  x := pos('?', s2);
  if x > 0 then
  begin
    path := '/' + SeparateLeft(s2, '?');
    Para := SeparateRight(s2, '?');
  end
  else
    path := '/' + s2;
  if Host = '' then
    Host := 'localhost';
end;

{==============================================================================}

FUNCTION ReplaceString(value, Search, Replace: ansistring): ansistring;
VAR
  x, l, ls, lr: integer;
begin
  if (value = '') or (Search = '') then
  begin
    result := value;
    exit;
  end;
  ls := length(Search);
  lr := length(Replace);
  result := '';
  x := pos(Search, value);
  while x > 0 do
  begin
    {$IFNDEF CIL}
    l := length(result);
    setLength(result, l + x - 1);
    move(pointer(value)^, pointer(@result[l + 1])^, x - 1);
    {$ELSE}
    result:=result+copy(value,1,x-1);
    {$ENDIF}
    {$IFNDEF CIL}
    l := length(result);
    setLength(result, l + lr);
    move(pointer(Replace)^, pointer(@result[l + 1])^, lr);
    {$ELSE}
    result:=result+Replace;
    {$ENDIF}
    Delete(value, 1, x - 1 + ls);
    x := pos(Search, value);
  end;
  result := result + value;
end;

{==============================================================================}

FUNCTION RPosEx(CONST sub, value: string; From: integer): integer;
VAR
  n: integer;
  l: integer;
begin
  result := 0;
  l := length(sub);
  for n := From - l + 1 downto 1 do
  begin
    if copy(value, n, l) = sub then
    begin
      result := n;
      break;
    end;
  end;
end;

{==============================================================================}

FUNCTION RPos(CONST sub, value: string): integer;
begin
  result := RPosEx(sub, value, length(value));
end;

{==============================================================================}

FUNCTION FetchBin(VAR value: string; CONST Delimiter: string): string;
VAR
  s: string;
begin
  result := SeparateLeft(value, Delimiter);
  s := SeparateRight(value, Delimiter);
  if s = value then
    value := ''
  else
    value := s;
end;

{==============================================================================}

FUNCTION Fetch(VAR value: string; CONST Delimiter: string): string;
begin
  result := FetchBin(value, Delimiter);
  result := TrimSP(result);
  value := TrimSP(value);
end;

{==============================================================================}

FUNCTION FetchEx(VAR value: string; CONST Delimiter, Quotation: string): string;
VAR
  b: boolean;
begin
  result := '';
  b := false;
  while length(value) > 0 do
  begin
    if b then
    begin
      if pos(Quotation, value) = 1 then
        b := false;
      result := result + value[1];
      Delete(value, 1, 1);
    end
    else
    begin
      if pos(Delimiter, value) = 1 then
      begin
        Delete(value, 1, length(delimiter));
        break;
      end;
      b := pos(Quotation, value) = 1;
      result := result + value[1];
      Delete(value, 1, 1);
    end;
  end;
end;

{==============================================================================}

FUNCTION IsBinaryString(CONST value: ansistring): boolean;
VAR
  n: integer;
begin
  result := false;
  for n := 1 to length(value) do
    if value[n] in [#0..#8, #10..#31] then
      //ignore null-terminated strings
      if not ((n = length(value)) and (value[n] = AnsiChar(#0))) then
      begin
        result := true;
        break;
      end;
end;

{==============================================================================}

FUNCTION PosCRLF(CONST value: ansistring; VAR Terminator: ansistring): integer;
VAR
  n, l: integer;
begin
  result := -1;
  Terminator := '';
  l := length(value);
  for n := 1 to l do
    if value[n] in [#$0d, #$0a] then
    begin
      result := n;
      Terminator := value[n];
      if n <> l then
        case value[n] of
          #$0d:
            if value[n + 1] = #$0a then
              Terminator := #$0d + #$0a;
          #$0a:
            if value[n + 1] = #$0d then
              Terminator := #$0a + #$0d;
        end;
      break;
    end;
end;

{==============================================================================}

PROCEDURE StringsTrim(CONST value: TStrings);
VAR
  n: integer;
begin
  for n := value.count - 1 downto 0 do
    if value[n] = '' then
      value.Delete(n)
    else
      break;
end;

{==============================================================================}

FUNCTION PosFrom(CONST SubStr, value: string; From: integer): integer;
VAR
  ls,lv: integer;
begin
  result := 0;
  ls := length(SubStr);
  lv := length(value);
  if (ls = 0) or (lv = 0) then
    exit;
  if From < 1 then
    From := 1;
  while (ls + from - 1) <= (lv) do
  begin
    {$IFNDEF CIL}
    if CompareMem(@SubStr[1],@value[from],ls) then
    {$ELSE}
    if SubStr = copy(value, from, ls) then
    {$ENDIF}
    begin
      result := from;
      break;
    end
    else
      inc(from);
  end;
end;

{==============================================================================}

{$IFNDEF CIL}
FUNCTION IncPoint(CONST p: pointer; value: integer): pointer;
begin
  result := PAnsiChar(p) + value;
end;
{$ENDIF}

{==============================================================================}
//improved by 'DoggyDawg'
FUNCTION GetBetween(CONST PairBegin, PairEnd, value: string): string;
VAR
  n: integer;
  x: integer;
  s: string;
  lenBegin: integer;
  lenEnd: integer;
  str: string;
  max: integer;
begin
  lenBegin := length(PairBegin);
  lenEnd := length(PairEnd);
  n := length(value);
  if (value = PairBegin + PairEnd) then
  begin
    result := '';//nothing between
    exit;
  end;
  if (n < lenBegin + lenEnd) then
  begin
    result := value;
    exit;
  end;
  s := SeparateRight(value, PairBegin);
  if (s = value) then
  begin
    result := value;
    exit;
  end;
  n := pos(PairEnd, s);
  if (n = 0) then
  begin
    result := value;
    exit;
  end;
  result := '';
  x := 1;
  max := length(s) - lenEnd + 1;
  for n := 1 to max do
  begin
    str := copy(s, n, lenEnd);
    if (str = PairEnd) then
    begin
      dec(x);
      if (x <= 0) then
        break;
    end;
    str := copy(s, n, lenBegin);
    if (str = PairBegin) then
      inc(x);
    result := result + s[n];
  end;
end;

{==============================================================================}

FUNCTION CountOfChar(CONST value: string; chr: char): integer;
VAR
  n: integer;
begin
  result := 0;
  for n := 1 to length(value) do
    if value[n] = chr then
      inc(result);
end;

{==============================================================================}
// ! do not use AnsiExtractQuotedStr, it's very buggy and can crash application!
FUNCTION UnquoteStr(CONST value: string; Quote: char): string;
VAR
  n: integer;
  inq, DQ: boolean;
  c, cn: char;
begin
  result := '';
  if value = '' then
    exit;
  if value = Quote + Quote then
    exit;
  inq := false;
  DQ := false;
  for n := 1 to length(value) do
  begin
    c := value[n];
    if n <> length(value) then
      cn := value[n + 1]
    else
      cn := #0;
    if c = quote then
      if DQ then
        DQ := false
      else
        if not inq then
          inq := true
        else
          if cn = quote then
          begin
            result := result + Quote;
            DQ := true;
          end
          else
            inq := false
    else
      result := result + c;
  end;
end;

{==============================================================================}

FUNCTION QuoteStr(CONST value: string; Quote: char): string;
VAR
  n: integer;
begin
  result := '';
  for n := 1 to length(value) do
  begin
    result := result + value[n];
    if value[n] = Quote then
      result := result + Quote;
  end;
  result :=  Quote + result + Quote;
end;

{==============================================================================}

PROCEDURE HeadersToList(CONST value: TStrings);
VAR
  n, x, y: integer;
  s: string;
begin
  for n := 0 to value.count -1 do
  begin
    s := value[n];
    x := pos(':', s);
    if x > 0 then
    begin
      y:= pos('=',s);
      if not ((y > 0) and (y < x)) then
      begin
        s[x] := '=';
        value[n] := s;
      end;
    end;
  end;
end;

{==============================================================================}

PROCEDURE ListToHeaders(CONST value: TStrings);
VAR
  n, x: integer;
  s: string;
begin
  for n := 0 to value.count -1 do
  begin
    s := value[n];
    x := pos('=', s);
    if x > 0 then
    begin
      s[x] := ':';
      value[n] := s;
    end;
  end;
end;

{==============================================================================}

FUNCTION SwapBytes(value: integer): integer;
VAR
  s: ansistring;
  x, y, xl, yl: byte;
begin
  s := CodeLongInt(value);
  x := ord(s[4]);
  y := ord(s[3]);
  xl := ord(s[2]);
  yl := ord(s[1]);
  result := ((x * 256 + y) * 65536) + (xl * 256 + yl);
end;

{==============================================================================}

FUNCTION ReadStrFromStream(CONST Stream: TStream; len: integer): ansistring;
VAR
  x: integer;
{$IFDEF CIL}
  Buf: array of byte;
{$ENDIF}
begin
{$IFDEF CIL}
  setLength(Buf, len);
  x := Stream.read(Buf, len);
  setLength(Buf, x);
  result := StringOf(Buf);
{$ELSE}
  setLength(result, len);
  x := Stream.read(PAnsiChar(result)^, len);
  setLength(result, x);
{$ENDIF}
end;

{==============================================================================}

PROCEDURE WriteStrToStream(CONST Stream: TStream; value: ansistring);
{$IFDEF CIL}
VAR
  Buf: array of byte;
{$ENDIF}
begin
{$IFDEF CIL}
  Buf := BytesOf(value);
  Stream.write(Buf,length(value));
{$ELSE}
  Stream.write(PAnsiChar(value)^, length(value));
{$ENDIF}
end;

{==============================================================================}
FUNCTION GetTempFile(CONST dir, prefix: ansistring): ansistring;
{$IFNDEF FPC}
{$IFDEF MSWINDOWS}
VAR
  path: ansistring;
  x: integer;
{$ENDIF}
{$ENDIF}
begin
{$IFDEF FPC}
  result := GetTempFileName(dir, prefix);
{$ELSE}
  {$IFNDEF MSWINDOWS}
    result := tempnam(pointer(dir), pointer(prefix));
  {$ELSE}
    {$IFDEF CIL}
  result := system.IO.path.GetTempFileName;
    {$ELSE}
  if dir = '' then
  begin
    setLength(path, MAX_PATH);
	  x := GetTempPath(length(path), PChar(path));
  	setLength(path, x);
  end
  else
    path := dir;
  x := length(path);
  if path[x] <> '\' then
    path := path + '\';
  setLength(result, MAX_PATH + 1);
  GetTempFileName(PChar(path), PChar(prefix), 0, PChar(result));
  result := PChar(result);
  SetFileattributes(PChar(result), GetFileAttributes(PChar(result)) or FILE_ATTRIBUTE_TEMPORARY);
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end;

{==============================================================================}

FUNCTION PadString(CONST value: ansistring; len: integer; Pad: AnsiChar): ansistring;
begin
  if length(value) >= len then
    result := copy(value, 1, len)
  else
    result := value + StringOfChar(Pad, len - length(value));
end;

{==============================================================================}

FUNCTION XorString(Indata1, Indata2: ansistring): ansistring;
VAR
  i: integer;
begin
  Indata2 := PadString(Indata2, length(Indata1), #0);
  result := '';
  for i := 1 to length(Indata1) do
    result := result + AnsiChar(ord(Indata1[i]) xor ord(Indata2[i]));
end;

{==============================================================================}

FUNCTION NormalizeHeader(value: TStrings; VAR index: integer): string;
VAR
  s, t: string;
  n: integer;
begin
  s := value[index];
  inc(index);
  if s <> '' then
    while (value.count - 1) > index do
    begin
      t := value[index];
      if t = '' then
        break;
      for n := 1 to length(t) do
        if t[n] = #9 then
          t[n] := ' ';
      if not(AnsiChar(t[1]) in [' ', '"', ':', '=']) then
        break
      else
      begin
        s := s + ' ' + trim(t);
        inc(index);
      end;
    end;
  result := trimRight(s);
end;

{==============================================================================}

{pf}
PROCEDURE SearchForLineBreak(VAR APtr:PAnsiChar; AEtx:PAnsiChar; OUT ABol:PAnsiChar; OUT ALength:integer);
begin
  ABol := APtr;
  while (APtr<AEtx) and not (APtr^ in [#0,#10,#13]) do
    inc(APtr);
  ALength := APtr-ABol;
end;
{/pf}

{pf}
PROCEDURE SkipLineBreak(VAR APtr:PAnsiChar; AEtx:PAnsiChar);
begin
  if (APtr<AEtx) and (APtr^=#13) then
    inc(APtr);
  if (APtr<AEtx) and (APtr^=#10) then
    inc(APtr);
end;
{/pf}

{pf}
PROCEDURE SkipNullLines(VAR APtr:PAnsiChar; AEtx:PAnsiChar);
VAR
  bol: PAnsiChar;
  lng: integer;
begin
  while (APtr<AEtx) do
    begin
      SearchForLineBreak(APtr,AEtx,bol,lng);
      SkipLineBreak(APtr,AEtx);
      if lng>0 then
        begin
          APtr := bol;
          break;
        end;
    end;
end;
{/pf}

{pf}
PROCEDURE CopyLinesFromStreamUntilNullLine(VAR APtr:PAnsiChar; AEtx:PAnsiChar; ALines:TStrings);
VAR
  bol: PAnsiChar;
  lng: integer;
  s:   ansistring;
begin
  // Copying until body separator will be reached
  while (APtr<AEtx) and (APtr^<>#0) do
    begin
      SearchForLineBreak(APtr,AEtx,bol,lng);
      SkipLineBreak(APtr,AEtx);
      if lng=0 then
        break;
      SetString(s,bol,lng);
      ALines.add(s);
    end;
end;
{/pf}

{pf}
PROCEDURE CopyLinesFromStreamUntilBoundary(VAR APtr:PAnsiChar; AEtx:PAnsiChar; ALines:TStrings; CONST ABoundary:ansistring);
VAR
  bol:      PAnsiChar;
  lng:      integer;
  s:        ansistring;
  BackStop: ansistring;
  eob1:     PAnsiChar;
  eob2:     PAnsiChar;
begin
  BackStop := '--'+ABoundary;
  eob2     := nil;
  // Copying until Boundary will be reached
  while (APtr<AEtx) do
    begin
      SearchForLineBreak(APtr,AEtx,bol,lng);
      SkipLineBreak(APtr,AEtx);
      eob1 := MatchBoundary(bol,APtr,ABoundary);
      if Assigned(eob1) then
        eob2 := MatchLastBoundary(bol,AEtx,ABoundary);
      if Assigned(eob2) then
        begin
          APtr := eob2;
          break;
        end
      else if Assigned(eob1) then
        begin
          APtr := eob1;
          break;
        end
      else
        begin
          SetString(s,bol,lng);
          ALines.add(s);
        end;
    end;
end;
{/pf}

{pf}
FUNCTION SearchForBoundary(VAR APtr:PAnsiChar; AEtx:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
VAR
  eob:  PAnsiChar;
  step: integer;
begin
  result := nil;
  // Moving Aptr position forward until boundary will be reached
  while (APtr<AEtx) do
    begin
      if strlcomp(APtr,#13#10'--',4)=0 then
        begin
          eob  := MatchBoundary(APtr,AEtx,ABoundary);
          step := 4;
        end
      else if strlcomp(APtr,'--',2)=0 then
        begin
          eob  := MatchBoundary(APtr,AEtx,ABoundary);
          step := 2;
        end
      else
        begin
          eob  := nil;
          step := 1;
        end;
      if Assigned(eob) then
        begin
          result := APtr;  // boundary beginning
          APtr   := eob;   // boundary end
          exit;
        end
      else
        inc(APtr,step);
    end;
end;
{/pf}

{pf}
FUNCTION MatchBoundary(ABol,AEtx:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
VAR
  MatchPos:   PAnsiChar;
  Lng:        integer;
begin
  result   := nil;
  MatchPos := ABol;
  Lng := length(ABoundary);
  if (MatchPos+2+Lng)>AETX then
    exit;
  if strlcomp(MatchPos,#13#10,2)=0 then
    inc(MatchPos,2);
  if (MatchPos+2+Lng)>AETX then
    exit;
  if strlcomp(MatchPos,'--',2)<>0 then
    exit;
  inc(MatchPos,2);
  if strlcomp(MatchPos,PAnsiChar(ABoundary),Lng)<>0 then
    exit;
  inc(MatchPos,Lng);
  if ((MatchPos+2)<=AEtx) and (strlcomp(MatchPos,#13#10,2)=0) then
    inc(MatchPos,2);
  result := MatchPos;
end;
{/pf}

{pf}
FUNCTION MatchLastBoundary(ABOL,AETX:PAnsiChar; CONST ABoundary:ansistring): PAnsiChar;
VAR
  MatchPos: PAnsiChar;
begin
  result   := nil;
  MatchPos := MatchBoundary(ABOL,AETX,ABoundary);
  if not Assigned(MatchPos) then
    exit;
  if strlcomp(MatchPos,'--',2)<>0 then
    exit;
  inc(MatchPos,2);
  if (MatchPos+2<=AEtx) and (strlcomp(MatchPos,#13#10,2)=0) then
    inc(MatchPos,2);
  result := MatchPos;
end;
{/pf}

{pf}
FUNCTION  BuildStringFromBuffer(AStx,AEtx:PAnsiChar): ansistring;
VAR
  lng: integer;
begin
  Lng := 0;
  if Assigned(AStx) and Assigned(AEtx) then
    begin
      Lng := AEtx-AStx;
      if Lng<0 then
        Lng := 0;
    end;
  SetString(result,AStx,lng);
end;
{/pf}




{==============================================================================}
VAR
  n: integer;
begin
  for n :=  1 to 12 do
  begin
    CustomMonthNames[n] := ShortMonthNames[n];
    MyMonthNames[0, n] := ShortMonthNames[n];
  end;
end.
