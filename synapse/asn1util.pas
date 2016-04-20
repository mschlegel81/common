{==============================================================================|
| project : Ararat Synapse                                       | 001.004.004 |
|==============================================================================|
| content: support for ASN.1 BER coding and decoding                           |
|==============================================================================|
| Copyright (c)1999-2003, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c) 1999-2003                |
| Portions created by Hernan Sanchez are Copyright (c) 2000.                   |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Hernan Sanchez (hernan.sanchez@iname.com)                                  |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{: @abstract(Utilities for handling ASN.1 BER encoding)
by this UNIT you can parse ASN.1 BER encoded data to elements or build back any
 elements to ASN.1 BER encoded buffer. You can dump ASN.1 BER encoded data to
 human readable form for easy debugging, too.

Supported element types are: ASN1_BOOL, ASN1_INT, ASN1_OCTSTR, ASN1_NULL,
 ASN1_OBJID, ASN1_ENUM, ASN1_SEQ, ASN1_SETOF, ASN1_IPADDR, ASN1_COUNTER,
 ASN1_GAUGE, ASN1_TIMETICKS, ASN1_OPAQUE

for sample of using, look to @link(TSnmpSend) or @link(TLdapSend)class.
}

{$Q-}
{$H+}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT asn1util;

INTERFACE

USES
  sysutils, Classes, synautil;

CONST
  ASN1_BOOL = $01;
  ASN1_INT = $02;
  ASN1_OCTSTR = $04;
  ASN1_NULL = $05;
  ASN1_OBJID = $06;
  ASN1_ENUM = $0a;
  ASN1_SEQ = $30;
  ASN1_SETOF = $31;
  ASN1_IPADDR = $40;
  ASN1_COUNTER = $41;
  ASN1_GAUGE = $42;
  ASN1_TIMETICKS = $43;
  ASN1_OPAQUE = $44;

{:Encodes OID item to binary form.}
FUNCTION ASNEncOIDItem(value: integer): ansistring;

{:Decodes an OID item of the next element in the "Buffer" from the "Start"
 position.}
FUNCTION ASNDecOIDItem(VAR start: integer; CONST buffer: ansistring): integer;

{:Encodes the length of ASN.1 element to binary.}
FUNCTION ASNEncLen(len: integer): ansistring;

{:Decodes length of next element in "Buffer" from the "Start" position.}
FUNCTION ASNDecLen(VAR start: integer; CONST buffer: ansistring): integer;

{:Encodes a signed integer to ASN.1 binary}
FUNCTION ASNEncInt(value: integer): ansistring;

{:Encodes unsigned integer into ASN.1 binary}
FUNCTION ASNEncUInt(value: integer): ansistring;

{:Encodes ASN.1 object to binary form.}
FUNCTION ASNObject(CONST data: ansistring; ASNType: integer): ansistring;

{:Beginning with the "Start" position, decode the ASN.1 item of the next element
 in "buffer". TYPE of item is stored in "ValueType."}
FUNCTION ASNItem(VAR start: integer; CONST buffer: ansistring;
  VAR ValueType: integer): ansistring;

{:Encodes an MIB OID string to binary form.}
FUNCTION MibToId(Mib: string): ansistring;

{:Decodes MIB OID from binary form to string form.}
FUNCTION IdToMib(CONST id: ansistring): string;

{:Encodes an one number from MIB OID to binary form. (used internally from
@link(MibToId))}
FUNCTION IntMibToStr(CONST value: ansistring): ansistring;

{:Convert ASN.1 BER encoded buffer to human readable form for debugging.}
FUNCTION ASNdump(CONST value: ansistring): ansistring;

IMPLEMENTATION

{==============================================================================}
FUNCTION ASNEncOIDItem(value: integer): ansistring;
VAR
  x, xm: integer;
  b: boolean;
begin
  x := value;
  b := false;
  result := '';
  repeat
    xm := x mod 128;
    x := x div 128;
    if b then
      xm := xm or $80;
    if x > 0 then
      b := true;
    result := AnsiChar(xm) + result;
  until x = 0;
end;

{==============================================================================}
FUNCTION ASNDecOIDItem(VAR start: integer; CONST buffer: ansistring): integer;
VAR
  x: integer;
  b: boolean;
begin
  result := 0;
  repeat
    result := result * 128;
    x := ord(buffer[start]);
    inc(start);
    b := x > $7F;
    x := x and $7F;
    result := result + x;
  until not b;
end;

{==============================================================================}
FUNCTION ASNEncLen(len: integer): ansistring;
VAR
  x, y: integer;
begin
  if len < $80 then
    result := AnsiChar(len)
  else
  begin
    x := len;
    result := '';
    repeat
      y := x mod 256;
      x := x div 256;
      result := AnsiChar(y) + result;
    until x = 0;
    y := length(result);
    y := y or $80;
    result := AnsiChar(y) + result;
  end;
end;

{==============================================================================}
FUNCTION ASNDecLen(VAR start: integer; CONST buffer: ansistring): integer;
VAR
  x, n: integer;
begin
  x := ord(buffer[start]);
  inc(start);
  if x < $80 then
    result := x
  else
  begin
    result := 0;
    x := x and $7F;
    for n := 1 to x do
    begin
      result := result * 256;
      x := ord(buffer[start]);
      inc(start);
      result := result + x;
    end;
  end;
end;

{==============================================================================}
FUNCTION ASNEncInt(value: integer): ansistring;
VAR
  x, y: Cardinal;
  neg: boolean;
begin
  neg := value < 0;
  x := abs(value);
  if neg then
    x := not (x - 1);
  result := '';
  repeat
    y := x mod 256;
    x := x div 256;
    result := AnsiChar(y) + result;
  until x = 0;
  if (not neg) and (result[1] > #$7F) then
    result := #0 + result;
end;

{==============================================================================}
FUNCTION ASNEncUInt(value: integer): ansistring;
VAR
  x, y: integer;
  neg: boolean;
begin
  neg := value < 0;
  x := value;
  if neg then
    x := x and $7fffffff;
  result := '';
  repeat
    y := x mod 256;
    x := x div 256;
    result := AnsiChar(y) + result;
  until x = 0;
  if neg then
    result[1] := AnsiChar(ord(result[1]) or $80);
end;

{==============================================================================}
FUNCTION ASNObject(CONST data: ansistring; ASNType: integer): ansistring;
begin
  result := AnsiChar(ASNType) + ASNEncLen(length(data)) + data;
end;

{==============================================================================}
FUNCTION ASNItem(VAR start: integer; CONST buffer: ansistring;
  VAR ValueType: integer): ansistring;
VAR
  ASNType: integer;
  ASNSize: integer;
  y, n: integer;
  x: byte;
  s: ansistring;
  c: AnsiChar;
  neg: boolean;
  l: integer;
begin
  result := '';
  ValueType := ASN1_NULL;
  l := length(buffer);
  if l < (start + 1) then
    exit;
  ASNType := ord(buffer[start]);
  ValueType := ASNType;
  inc(start);
  ASNSize := ASNDecLen(start, buffer);
  if (start + ASNSize - 1) > l then
    exit;
  if (ASNType and $20) > 0 then
//    Result := '$' + IntToHex(ASNType, 2)
    result := copy(buffer, start, ASNSize)
  else
    case ASNType of
      ASN1_INT, ASN1_ENUM, ASN1_BOOL:
        begin
          y := 0;
          neg := false;
          for n := 1 to ASNSize do
          begin
            x := ord(buffer[start]);
            if (n = 1) and (x > $7F) then
              neg := true;
            if neg then
              x := not x;
            y := y * 256 + x;
            inc(start);
          end;
          if neg then
            y := -(y + 1);
          result := intToStr(y);
        end;
      ASN1_COUNTER, ASN1_GAUGE, ASN1_TIMETICKS:
        begin
          y := 0;
          for n := 1 to ASNSize do
          begin
            y := y * 256 + ord(buffer[start]);
            inc(start);
          end;
          result := intToStr(y);
        end;
      ASN1_OCTSTR, ASN1_OPAQUE:
        begin
          for n := 1 to ASNSize do
          begin
            c := AnsiChar(buffer[start]);
            inc(start);
            s := s + c;
          end;
          result := s;
        end;
      ASN1_OBJID:
        begin
          for n := 1 to ASNSize do
          begin
            c := AnsiChar(buffer[start]);
            inc(start);
            s := s + c;
          end;
          result := IdToMib(s);
        end;
      ASN1_IPADDR:
        begin
          s := '';
          for n := 1 to ASNSize do
          begin
            if (n <> 1) then
              s := s + '.';
            y := ord(buffer[start]);
            inc(start);
            s := s + intToStr(y);
          end;
          result := s;
        end;
      ASN1_NULL:
        begin
          result := '';
          start := start + ASNSize;
        end;
    else // unknown
      begin
        for n := 1 to ASNSize do
        begin
          c := AnsiChar(buffer[start]);
          inc(start);
          s := s + c;
        end;
        result := s;
      end;
    end;
end;

{==============================================================================}
FUNCTION MibToId(Mib: string): ansistring;
VAR
  x: integer;

  FUNCTION WalkInt(VAR s: string): integer;
  VAR
    x: integer;
    t: ansistring;
  begin
    x := pos('.', s);
    if x < 1 then
    begin
      t := s;
      s := '';
    end
    else
    begin
      t := copy(s, 1, x - 1);
      s := copy(s, x + 1, length(s) - x);
    end;
    result := strToIntDef(t, 0);
  end;

begin
  result := '';
  x := WalkInt(Mib);
  x := x * 40 + WalkInt(Mib);
  result := ASNEncOIDItem(x);
  while Mib <> '' do
  begin
    x := WalkInt(Mib);
    result := result + ASNEncOIDItem(x);
  end;
end;

{==============================================================================}
FUNCTION IdToMib(CONST id: ansistring): string;
VAR
  x, y, n: integer;
begin
  result := '';
  n := 1;
  while length(id) + 1 > n do
  begin
    x := ASNDecOIDItem(n, id);
    if (n - 1) = 1 then
    begin
      y := x div 40;
      x := x mod 40;
      result := intToStr(y);
    end;
    result := result + '.' + intToStr(x);
  end;
end;

{==============================================================================}
FUNCTION IntMibToStr(CONST value: ansistring): ansistring;
VAR
  n, y: integer;
begin
  y := 0;
  for n := 1 to length(value) - 1 do
    y := y * 256 + ord(value[n]);
  result := intToStr(y);
end;

{==============================================================================}
FUNCTION ASNdump(CONST value: ansistring): ansistring;
VAR
  i, at, x, n: integer;
  s, indent: ansistring;
  il: TStringList;
begin
  il := TStringList.create;
  try
    result := '';
    i := 1;
    indent := '';
    while i < length(value) do
    begin
      for n := il.count - 1 downto 0 do
      begin
        x := strToIntDef(il[n], 0);
        if x <= i then
        begin
          il.Delete(n);
          Delete(indent, 1, 2);
        end;
      end;
      s := ASNItem(i, value, at);
      result := result + indent + '$' + IntToHex(at, 2);
      if (at and $20) > 0 then
      begin
        x := length(s);
        result := result + ' constructed: length ' + intToStr(x);
        indent := indent + '  ';
        il.add(intToStr(x + i - 1));
      end
      else
      begin
        case at of
          ASN1_BOOL:
            result := result + ' BOOL: ';
          ASN1_INT:
            result := result + ' INT: ';
          ASN1_ENUM:
            result := result + ' ENUM: ';
          ASN1_COUNTER:
            result := result + ' COUNTER: ';
          ASN1_GAUGE:
            result := result + ' GAUGE: ';
          ASN1_TIMETICKS:
            result := result + ' TIMETICKS: ';
          ASN1_OCTSTR:
            result := result + ' OCTSTR: ';
          ASN1_OPAQUE:
            result := result + ' OPAQUE: ';
          ASN1_OBJID:
            result := result + ' OBJID: ';
          ASN1_IPADDR:
            result := result + ' IPADDR: ';
          ASN1_NULL:
            result := result + ' NULL: ';
        else // other
          result := result + ' unknown: ';
        end;
        if IsBinaryString(s) then
          s := DumpExStr(s);
        result := result + s;
      end;
      result := result + #$0d + #$0a;
    end;
  finally
    il.free;
  end;
end;

{==============================================================================}

end.
