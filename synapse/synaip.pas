{==============================================================================|
| project : Ararat Synapse                                       | 001.002.001 |
|==============================================================================|
| content: IP address support procedures and functions                         |
|==============================================================================|
| Copyright (c)2006-2010, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c) 2006-2010.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(IP adress support procedures and functions)}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$R-}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  {$WARN SUSPICIOUS_TYPECAST OFF}
{$ENDIF}

UNIT synaip;

INTERFACE

USES
  sysutils, SynaUtil;

TYPE
{:binary form of IPv6 adress (for string conversion routines)}
  TIp6Bytes = array [0..15] of byte;
{:binary form of IPv6 adress (for string conversion routines)}
  TIp6Words = array [0..7] of word;

{:Returns @TRUE, if "Value" is a valid IPv4 address. Cannot be a symbolic Name!}
FUNCTION IsIP(CONST value: string): boolean;

{:Returns @TRUE, if "Value" is a valid IPv6 address. Cannot be a symbolic Name!}
FUNCTION IsIP6(CONST value: string): boolean;

{:Returns a string with the "Host" ip address converted to binary form.}
FUNCTION IPToID(Host: string): ansistring;

{:Convert IPv6 address from their string form to binary byte array.}
FUNCTION StrToIp6(value: string): TIp6Bytes;

{:Convert IPv6 address from binary byte array to string form.}
FUNCTION Ip6ToStr(value: TIp6Bytes): string;

{:Convert IPv4 address from their string form to binary.}
FUNCTION StrToIp(value: string): integer;

{:Convert IPv4 address from binary to string form.}
FUNCTION IpToStr(value: integer): string;

{:Convert IPv4 address to reverse form.}
FUNCTION ReverseIP(value: ansistring): ansistring;

{:Convert IPv6 address to reverse form.}
FUNCTION ReverseIP6(value: ansistring): ansistring;

{:Expand short form of IPv6 address to long form.}
FUNCTION ExpandIP6(value: ansistring): ansistring;


IMPLEMENTATION

{==============================================================================}

FUNCTION IsIP(CONST value: string): boolean;
VAR
  TempIP: string;
  FUNCTION ByteIsOk(CONST value: string): boolean;
  VAR
    x, n: integer;
  begin
    x := strToIntDef(value, -1);
    result := (x >= 0) and (x < 256);
    // X may be in correct range, but value still may not be correct value!
    // i.e. "$80"
    if result then
      for n := 1 to length(value) do
        if not (AnsiChar(value[n]) in ['0'..'9']) then
        begin
          result := false;
          break;
        end;
  end;
begin
  TempIP := value;
  result := false;
  if not ByteIsOk(Fetch(TempIP, '.')) then
    exit;
  if not ByteIsOk(Fetch(TempIP, '.')) then
    exit;
  if not ByteIsOk(Fetch(TempIP, '.')) then
    exit;
  if ByteIsOk(TempIP) then
    result := true;
end;

{==============================================================================}

FUNCTION IsIP6(CONST value: string): boolean;
VAR
  TempIP: string;
  s,t: string;
  x: integer;
  partcount: integer;
  zerocount: integer;
  first: boolean;
begin
  TempIP := value;
  result := false;
  if value = '::' then
  begin
    result := true;
    exit;
  end;
  partcount := 0;
  zerocount := 0;
  first := true;
  while tempIP <> '' do
  begin
    s := fetch(TempIP, ':');
    if not(first) and (s = '') then
      inc(zerocount);
    first := false;
    if zerocount > 1 then
      break;
    inc(partCount);
    if s = '' then
      continue;
    if partCount > 8 then
      break;
    if tempIP = '' then
    begin
      t := SeparateRight(s, '%');
      s := SeparateLeft(s, '%');
      x := strToIntDef('$' + t, -1);
      if (x < 0) or (x > $FFFF) then
        break;
    end;
    x := strToIntDef('$' + s, -1);
    if (x < 0) or (x > $FFFF) then
      break;
    if tempIP = '' then
      if not((PartCount = 1) and (ZeroCount = 0)) then
        result := true;
  end;
end;

{==============================================================================}
FUNCTION IPToID(Host: string): ansistring;
VAR
  s: string;
  i, x: integer;
begin
  result := '';
  for x := 0 to 3 do
  begin
    s := Fetch(Host, '.');
    i := strToIntDef(s, 0);
    result := result + AnsiChar(i);
  end;
end;

{==============================================================================}

FUNCTION StrToIp(value: string): integer;
VAR
  s: string;
  i, x: integer;
begin
  result := 0;
  for x := 0 to 3 do
  begin
    s := Fetch(value, '.');
    i := strToIntDef(s, 0);
    result := (256 * result) + i;
  end;
end;

{==============================================================================}

FUNCTION IpToStr(value: integer): string;
VAR
  x1, x2: word;
  y1, y2: byte;
begin
  result := '';
  x1 := value shr 16;
  x2 := value and $FFFF;
  y1 := x1 div $100;
  y2 := x1 mod $100;
  result := intToStr(y1) + '.' + intToStr(y2) + '.';
  y1 := x2 div $100;
  y2 := x2 mod $100;
  result := result + intToStr(y1) + '.' + intToStr(y2);
end;

{==============================================================================}

FUNCTION ExpandIP6(value: ansistring): ansistring;
VAR
 n: integer;
 s: ansistring;
 x: integer;
begin
  result := '';
  if value = '' then
    exit;
  x := countofchar(value, ':');
  if x > 7 then
    exit;
  if value[1] = ':' then
    value := '0' + value;
  if value[length(value)] = ':' then
    value := value + '0';
  x := 8 - x;
  s := '';
  for n := 1 to x do
    s := s + ':0';
  s := s + ':';
  result := replacestring(value, '::', s);
end;
{==============================================================================}

FUNCTION StrToIp6(value: string): TIp6Bytes;
VAR
 IPv6: TIp6Words;
 index: integer;
 n: integer;
 b1, b2: byte;
 s: string;
 x: integer;
begin
  for n := 0 to 15 do
    result[n] := 0;
  for n := 0 to 7 do
    Ipv6[n] := 0;
  index := 0;
  value := ExpandIP6(value);
  if value = '' then
    exit;
  while value <> '' do
  begin
    if index > 7 then
      exit;
    s := fetch(value, ':');
    if s = '@' then
      break;
    if s = '' then
    begin
      IPv6[index] := 0;
    end
    else
    begin
      x := strToIntDef('$' + s, -1);
      if (x > 65535) or (x < 0) then
        exit;
      IPv6[index] := x;
    end;
    inc(index);
  end;
  for n := 0 to 7 do
  begin
    b1 := ipv6[n] div 256;
    b2 := ipv6[n] mod 256;
    result[n * 2] := b1;
    result[(n * 2) + 1] := b2;
  end;
end;

{==============================================================================}
//based on routine by the Free Pascal development team
FUNCTION Ip6ToStr(value: TIp6Bytes): string;
VAR
  i, x: byte;
  zr1,zr2: set of byte;
  zc1,zc2: byte;
  have_skipped: boolean;
  ip6w: TIp6words;
begin
  zr1 := [];
  zr2 := [];
  zc1 := 0;
  zc2 := 0;
  for i := 0 to 7 do
  begin
    x := i * 2;
    ip6w[i] := value[x] * 256 + value[x + 1];
    if ip6w[i] = 0 then
    begin
      include(zr2, i);
      inc(zc2);
    end
    else
    begin
      if zc1 < zc2 then
      begin
        zc1 := zc2;
        zr1 := zr2;
        zc2 := 0;
        zr2 := [];
      end;
    end;
  end;
  if zc1 < zc2 then
  begin
    zr1 := zr2;
  end;
  setLength(result, 8*5-1);
  setLength(result, 0);
  have_skipped := false;
  for i := 0 to 7 do
  begin
    if not(i in zr1) then
    begin
      if have_skipped then
      begin
        if result = '' then
          result := '::'
        else
          result := result + ':';
        have_skipped := false;
      end;
      result := result + IntToHex(Ip6w[i], 1) + ':';
    end
    else
    begin
      have_skipped := true;
    end;
  end;
  if have_skipped then
    if result = '' then
      result := '::0'
    else
      result := result + ':';

  if result = '' then
    result := '::0';
  if not (7 in zr1) then
    setLength(result, length(result)-1);
  result := lowercase(result);
end;

{==============================================================================}
FUNCTION ReverseIP(value: ansistring): ansistring;
VAR
  x: integer;
begin
  result := '';
  repeat
    x := LastDelimiter('.', value);
    result := result + '.' + copy(value, x + 1, length(value) - x);
    Delete(value, x, length(value) - x + 1);
  until x < 1;
  if length(result) > 0 then
    if result[1] = '.' then
      Delete(result, 1, 1);
end;

{==============================================================================}
FUNCTION ReverseIP6(value: ansistring): ansistring;
VAR
  ip6: TIp6bytes;
  n: integer;
  x, y: integer;
begin
  ip6 := StrToIP6(value);
  x := ip6[15] div 16;
  y := ip6[15] mod 16;
  result := IntToHex(y, 1) + '.' + IntToHex(x, 1);
  for n := 14 downto 0 do
  begin
    x := ip6[n] div 16;
    y := ip6[n] mod 16;
    result := result + '.' + IntToHex(y, 1) + '.' + IntToHex(x, 1);
  end;
end;

{==============================================================================}
end.
