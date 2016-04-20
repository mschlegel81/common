{==============================================================================|
| project : Ararat Synapse                                       | 001.001.011 |
|==============================================================================|
| content: inline MIME support procedures and functions                        |
|==============================================================================|
| Copyright (c)1999-2006, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2006.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Utilities for inline MIME)
Support for inline MIME encoding and decoding.

used RFC: RFC-2047, RFC-2231
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT mimeinln;

INTERFACE

USES
  sysutils, Classes,
  synachar, synacode, synautil;

{:Decodes mime inline encoding (i.e. in headers) uses target characterset "CP".}
FUNCTION InlineDecode(CONST value: string; CP: TMimeChar): string;

{:Encodes string to MIME inline encoding. The source characterset is "CP", and
 the target charSet is "MimeP".}
FUNCTION InlineEncode(CONST value: string; CP, MimeP: TMimeChar): string;

{:Returns @true, if "Value" contains characters needed for inline coding.}
FUNCTION NeedInline(CONST value: ansistring): boolean;

{:Inline mime encoding similar to @link(InlineEncode), but you can specify
 Source charSet, and the target characterset is automatically assigned.}
FUNCTION InlineCodeEx(CONST value: string; FromCP: TMimeChar): string;

{:Inline MIME encoding similar to @link(InlineEncode), but the source charset
 is automatically set to the system default charSet, and the target charSet is
 automatically assigned from set of allowed encoding for MIME.}
FUNCTION InlineCode(CONST value: string): string;

{:Converts e-mail address to canonical mime form. You can specify source charset.}
FUNCTION InlineEmailEx(CONST value: string; FromCP: TMimeChar): string;

{:Converts e-mail address to canonical mime form. Source charser it system
 default charSet.}
FUNCTION InlineEmail(CONST value: string): string;

IMPLEMENTATION

{==============================================================================}

FUNCTION InlineDecode(CONST value: string; CP: TMimeChar): string;
VAR
  s, su, v: string;
  x, y, z, n: integer;
  ichar: TMimeChar;
  c: char;

  FUNCTION SearchEndInline(CONST value: string; be: integer): integer;
  VAR
    n, q: integer;
  begin
    q := 0;
    result := 0;
    for n := be + 2 to length(value) - 1 do
      if value[n] = '?' then
      begin
        inc(q);
        if (q > 2) and (value[n + 1] = '=') then
        begin
          result := n;
          break;
        end;
      end;
  end;

begin
  result := '';
  v := value;
  x := pos('=?', v);
  y := SearchEndInline(v, x);
  //fix for broken coding with begin, but not with end.
  if (x > 0) and (y <= 0) then
    y := length(result);
  while (y > x) and (x > 0) do
  begin
    s := copy(v, 1, x - 1);
    if trim(s) <> '' then
      result := result + s;
    s := copy(v, x, y - x + 2);
    Delete(v, 1, y + 1);
    su := copy(s, 3, length(s) - 4);
    z := pos('?', su);
    if (length(su) >= (z + 2)) and (su[z + 2] = '?') then
    begin
      ichar := GetCPFromID(SeparateLeft(copy(su, 1, z - 1), '*'));
      c := uppercase(su)[z + 1];
      su := copy(su, z + 3, length(su) - z - 2);
      if c = 'B' then
      begin
        s := DecodeBase64(su);
        s := CharsetConversion(s, ichar, CP);
      end;
      if c = 'Q' then
      begin
        s := '';
        for n := 1 to length(su) do
          if su[n] = '_' then
            s := s + ' '
          else
            s := s + su[n];
        s := DecodeQuotedPrintable(s);
        s := CharsetConversion(s, ichar, CP);
      end;
    end;
    result := result + s;
    x := pos('=?', v);
    y := SearchEndInline(v, x);
  end;
  result := result + v;
end;

{==============================================================================}

FUNCTION InlineEncode(CONST value: string; CP, MimeP: TMimeChar): string;
VAR
  s, s1, e: string;
  n: integer;
begin
  s := CharsetConversion(value, CP, MimeP);
  s := EncodeSafeQuotedPrintable(s);
  e := GetIdFromCP(MimeP);
  s1 := '';
  result := '';
  for n := 1 to length(s) do
    if s[n] = ' ' then
    begin
//      s1 := s1 + '=20';
      s1 := s1 + '_';
      if length(s1) > 32 then
      begin
        if result <> '' then
          result := result + ' ';
        result := result + '=?' + e + '?Q?' + s1 + '?=';
        s1 := '';
      end;
    end
    else
      s1 := s1 + s[n];
  if s1 <> '' then
  begin
    if result <> '' then
      result := result + ' ';
    result := result + '=?' + e + '?Q?' + s1 + '?=';
  end;
end;

{==============================================================================}

FUNCTION NeedInline(CONST value: ansistring): boolean;
VAR
  n: integer;
begin
  result := false;
  for n := 1 to length(value) do
    if value[n] in (SpecialChar + NonAsciiChar - ['_']) then
    begin
      result := true;
      break;
    end;
end;

{==============================================================================}

FUNCTION InlineCodeEx(CONST value: string; FromCP: TMimeChar): string;
VAR
  c: TMimeChar;
begin
  if NeedInline(value) then
  begin
    c := IdealCharsetCoding(value, FromCP, IdealCharsets);
    result := InlineEncode(value, FromCP, c);
  end
  else
    result := value;
end;

{==============================================================================}

FUNCTION InlineCode(CONST value: string): string;
begin
  result := InlineCodeEx(value, GetCurCP);
end;

{==============================================================================}

FUNCTION InlineEmailEx(CONST value: string; FromCP: TMimeChar): string;
VAR
  sd, SE: string;
begin
  sd := GetEmailDesc(value);
  SE := GetEmailAddr(value);
  if sd = '' then
    result := SE
  else
    result := '"' + InlineCodeEx(sd, FromCP) + '" <' + SE + '>';
end;

{==============================================================================}

FUNCTION InlineEmail(CONST value: string): string;
begin
  result := InlineEmailEx(value, GetCurCP);
end;

end.
