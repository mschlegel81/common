{==============================================================================|
| project : Ararat Synapse                                       | 002.002.001 |
|==============================================================================|
| content: Coding and decoding support                                         |
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
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Various encoding and decoding support)}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$R-}
{$H+}
{$TYPEDADDRESS OFF}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  {$WARN SUSPICIOUS_TYPECAST OFF}
{$ENDIF}

UNIT synacode;

INTERFACE

USES
  sysutils;

TYPE
  TSpecials = set of AnsiChar;

CONST

  SpecialChar: TSpecials =
  ['=', '(', ')', '[', ']', '<', '>', ':', ';', ',', '@', '/', '?', '\',
    '"', '_'];
  NonAsciiChar: TSpecials =
  [#0..#31, #127..#255];
  URLFullSpecialChar: TSpecials =
  [';', '/', '?', ':', '@', '=', '&', '#', '+'];
  URLSpecialChar: TSpecials =
  [#$00..#$20, '_', '<', '>', '"', '%', '{', '}', '|', '\', '^', '~', '[', ']',
    '`', #$7F..#$ff];
  TableBase64 =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  TableBase64mod =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+,=';
  TableUU =
    '`!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_';
  TableXX =
    '+-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  ReTablebase64 =
    #$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$3E +#$40
    +#$40 +#$40 +#$3F +#$34 +#$35 +#$36 +#$37 +#$38 +#$39 +#$3A +#$3B +#$3C
    +#$3D +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$00 +#$01 +#$02 +#$03
    +#$04 +#$05 +#$06 +#$07 +#$08 +#$09 +#$0A +#$0B +#$0C +#$0D +#$0E +#$0F
    +#$10 +#$11 +#$12 +#$13 +#$14 +#$15 +#$16 +#$17 +#$18 +#$19 +#$40 +#$40
    +#$40 +#$40 +#$40 +#$40 +#$1A +#$1B +#$1C +#$1D +#$1E +#$1F +#$20 +#$21
    +#$22 +#$23 +#$24 +#$25 +#$26 +#$27 +#$28 +#$29 +#$2A +#$2B +#$2C +#$2D
    +#$2E +#$2F +#$30 +#$31 +#$32 +#$33 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40;
  ReTableUU =
    #$01 +#$02 +#$03 +#$04 +#$05 +#$06 +#$07 +#$08 +#$09 +#$0A +#$0B +#$0C
    +#$0D +#$0E +#$0F +#$10 +#$11 +#$12 +#$13 +#$14 +#$15 +#$16 +#$17 +#$18
    +#$19 +#$1A +#$1B +#$1C +#$1D +#$1E +#$1F +#$20 +#$21 +#$22 +#$23 +#$24
    +#$25 +#$26 +#$27 +#$28 +#$29 +#$2A +#$2B +#$2C +#$2D +#$2E +#$2F +#$30
    +#$31 +#$32 +#$33 +#$34 +#$35 +#$36 +#$37 +#$38 +#$39 +#$3A +#$3B +#$3C
    +#$3D +#$3E +#$3F +#$00 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40
    +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40
    +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40;
  ReTableXX =
    #$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$00 +#$40
    +#$01 +#$40 +#$40 +#$02 +#$03 +#$04 +#$05 +#$06 +#$07 +#$08 +#$09 +#$0A
    +#$0B +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$0C +#$0D +#$0E +#$0F
    +#$10 +#$11 +#$12 +#$13 +#$14 +#$15 +#$16 +#$17 +#$18 +#$19 +#$1A +#$1B
    +#$1C +#$1D +#$1E +#$1F +#$20 +#$21 +#$22 +#$23 +#$24 +#$25 +#$40 +#$40
    +#$40 +#$40 +#$40 +#$40 +#$26 +#$27 +#$28 +#$29 +#$2A +#$2B +#$2C +#$2D
    +#$2E +#$2F +#$30 +#$31 +#$32 +#$33 +#$34 +#$35 +#$36 +#$37 +#$38 +#$39
    +#$3A +#$3B +#$3C +#$3D +#$3E +#$3F +#$40 +#$40 +#$40 +#$40 +#$40 +#$40;

{:Decodes triplet encoding with a given character delimiter. It is used for
 decoding quoted-printable or URL encoding.}
FUNCTION DecodeTriplet(CONST value: ansistring; Delimiter: AnsiChar): ansistring;

{:Decodes a string from quoted printable form. (also decodes triplet sequences
 like '=7F')}
FUNCTION DecodeQuotedPrintable(CONST value: ansistring): ansistring;

{:Decodes a string of URL encoding. (also decodes triplet sequences like '%7F')}
FUNCTION DecodeURL(CONST value: ansistring): ansistring;

{:Performs triplet encoding with a given character delimiter. Used for encoding
 quoted-printable or URL encoding.}
FUNCTION EncodeTriplet(CONST value: ansistring; Delimiter: AnsiChar;
  Specials: TSpecials): ansistring;

{:Encodes a string to triplet quoted printable form. All @link(NonAsciiChar)
 are encoded.}
FUNCTION EncodeQuotedPrintable(CONST value: ansistring): ansistring;

{:Encodes a string to triplet quoted printable form. All @link(NonAsciiChar) and
 @link(SpecialChar) are encoded.}
FUNCTION EncodeSafeQuotedPrintable(CONST value: ansistring): ansistring;

{:Encodes a string to URL format. Used for encoding data from a form field in
 HTTP, etc. (Encodes all critical characters including characters used as URL
 delimiters ('/',':', etc.)}
FUNCTION EncodeURLElement(CONST value: ansistring): ansistring;

{:Encodes a string to URL format. Used to encode critical characters in all
 URLs.}
FUNCTION EncodeURL(CONST value: ansistring): ansistring;

{:Decode 4to3 encoding with given table. If some element is not found in table,
 first item from table is used. This is good for buggy coded Items by Microsoft
 Outlook. This software sometimes using wrong table for UUcode, where is used
 ' ' instead '`'.}
FUNCTION Decode4to3(CONST value, table: ansistring): ansistring;

{:Decode 4to3 encoding with given REVERSE table. Using this function with
reverse table is much faster then @link(Decode4to3). This FUNCTION is used
internally for Base64, UU or xx decoding.}
FUNCTION Decode4to3Ex(CONST value, table: ansistring): ansistring;

{:Encode by system 3to4 (used by Base64, UU coding, etc) by given table.}
FUNCTION Encode3to4(CONST value, table: ansistring): ansistring;

{:Decode string from base64 format.}
FUNCTION DecodeBase64(CONST value: ansistring): ansistring;

{:Encodes a string to base64 format.}
FUNCTION EncodeBase64(CONST value: ansistring): ansistring;

{:Decode string from modified base64 format. (used in IMAP, for example.)}
FUNCTION DecodeBase64mod(CONST value: ansistring): ansistring;

{:Encodes a string to  modified base64 format. (used in IMAP, for example.)}
FUNCTION EncodeBase64mod(CONST value: ansistring): ansistring;

{:Decodes a string from UUcode format.}
FUNCTION DecodeUU(CONST value: ansistring): ansistring;

{:encode UUcode. it encode only datas, you must also add header and footer for
 proper encode.}
FUNCTION EncodeUU(CONST value: ansistring): ansistring;

{:Decodes a string from XXcode format.}
FUNCTION DecodeXX(CONST value: ansistring): ansistring;

{:decode line with Yenc code. This code is sometimes used in newsgroups.}
FUNCTION DecodeYEnc(CONST value: ansistring): ansistring;

{:Returns a new CRC32 value after adding a new byte of data.}
FUNCTION UpdateCrc32(value: byte; Crc32: integer): integer;

{:return CRC32 from a value string.}
FUNCTION Crc32(CONST value: ansistring): integer;

{:Returns a new CRC16 value after adding a new byte of data.}
FUNCTION UpdateCrc16(value: byte; Crc16: word): word;

{:return CRC16 from a value string.}
FUNCTION Crc16(CONST value: ansistring): word;

{:Returns a binary string with a RSA-MD5 hashing of "Value" string.}
FUNCTION MD5(CONST value: ansistring): ansistring;

{:Returns a binary string with HMAC-MD5 hash.}
FUNCTION HMAC_MD5(text, key: ansistring): ansistring;

{:Returns a binary string with a RSA-MD5 hashing of string what is constructed
 by repeating "value" until length is "len".}
FUNCTION MD5LongHash(CONST value: ansistring; len: integer): ansistring;

{:Returns a binary string with a SHA-1 hashing of "Value" string.}
FUNCTION SHA1(CONST value: ansistring): ansistring;

{:Returns a binary string with HMAC-SHA1 hash.}
FUNCTION HMAC_SHA1(text, key: ansistring): ansistring;

{:Returns a binary string with a SHA-1 hashing of string what is constructed
 by repeating "value" until length is "len".}
FUNCTION SHA1LongHash(CONST value: ansistring; len: integer): ansistring;

{:Returns a binary string with a RSA-MD4 hashing of "Value" string.}
FUNCTION MD4(CONST value: ansistring): ansistring;

IMPLEMENTATION

CONST

  Crc32Tab: array[0..255] of integer = (
    integer($00000000), integer($77073096), integer($EE0E612C), integer($990951BA),
    integer($076DC419), integer($706AF48F), integer($E963A535), integer($9E6495A3),
    integer($0EDB8832), integer($79DCB8A4), integer($E0D5E91E), integer($97D2D988),
    integer($09B64C2B), integer($7EB17CBD), integer($E7B82D07), integer($90BF1D91),
    integer($1DB71064), integer($6AB020F2), integer($F3B97148), integer($84BE41DE),
    integer($1ADAD47D), integer($6DDDE4EB), integer($F4D4B551), integer($83D385C7),
    integer($136C9856), integer($646BA8C0), integer($FD62F97A), integer($8A65C9EC),
    integer($14015C4F), integer($63066CD9), integer($FA0F3D63), integer($8D080DF5),
    integer($3B6E20C8), integer($4C69105E), integer($D56041E4), integer($A2677172),
    integer($3C03E4D1), integer($4B04D447), integer($D20D85FD), integer($A50AB56B),
    integer($35B5A8FA), integer($42B2986C), integer($DBBBC9D6), integer($ACBCF940),
    integer($32D86CE3), integer($45DF5C75), integer($DCD60DCF), integer($ABD13D59),
    integer($26D930AC), integer($51DE003A), integer($C8D75180), integer($BFD06116),
    integer($21B4F4B5), integer($56B3C423), integer($CFBA9599), integer($B8BDA50F),
    integer($2802B89E), integer($5F058808), integer($C60CD9B2), integer($B10BE924),
    integer($2F6F7C87), integer($58684C11), integer($C1611DAB), integer($B6662D3D),
    integer($76DC4190), integer($01DB7106), integer($98D220BC), integer($EFD5102A),
    integer($71B18589), integer($06B6B51F), integer($9FBFE4A5), integer($E8B8D433),
    integer($7807C9A2), integer($0F00F934), integer($9609A88E), integer($E10E9818),
    integer($7F6A0DBB), integer($086D3D2D), integer($91646C97), integer($E6635C01),
    integer($6B6B51F4), integer($1C6C6162), integer($856530D8), integer($F262004E),
    integer($6C0695ED), integer($1B01A57B), integer($8208F4C1), integer($F50FC457),
    integer($65B0D9C6), integer($12B7E950), integer($8BBEB8EA), integer($FCB9887C),
    integer($62DD1DDF), integer($15DA2D49), integer($8CD37CF3), integer($FBD44C65),
    integer($4DB26158), integer($3AB551CE), integer($A3BC0074), integer($D4BB30E2),
    integer($4ADFA541), integer($3DD895D7), integer($A4D1C46D), integer($D3D6F4FB),
    integer($4369E96A), integer($346ED9FC), integer($AD678846), integer($DA60B8D0),
    integer($44042D73), integer($33031DE5), integer($AA0A4C5F), integer($DD0D7CC9),
    integer($5005713C), integer($270241AA), integer($BE0B1010), integer($C90C2086),
    integer($5768B525), integer($206F85B3), integer($B966D409), integer($CE61E49F),
    integer($5EDEF90E), integer($29D9C998), integer($B0D09822), integer($C7D7A8B4),
    integer($59B33D17), integer($2EB40D81), integer($B7BD5C3B), integer($C0BA6CAD),
    integer($EDB88320), integer($9ABFB3B6), integer($03B6E20C), integer($74B1D29A),
    integer($EAD54739), integer($9DD277AF), integer($04DB2615), integer($73DC1683),
    integer($E3630B12), integer($94643B84), integer($0D6D6A3E), integer($7A6A5AA8),
    integer($E40ECF0B), integer($9309FF9D), integer($0A00AE27), integer($7D079EB1),
    integer($F00F9344), integer($8708A3D2), integer($1E01F268), integer($6906C2FE),
    integer($F762575D), integer($806567CB), integer($196C3671), integer($6E6B06E7),
    integer($FED41B76), integer($89D32BE0), integer($10DA7A5A), integer($67DD4ACC),
    integer($F9B9DF6F), integer($8EBEEFF9), integer($17B7BE43), integer($60B08ED5),
    integer($D6D6A3E8), integer($A1D1937E), integer($38D8C2C4), integer($4FDFF252),
    integer($D1BB67F1), integer($A6BC5767), integer($3FB506DD), integer($48B2364B),
    integer($D80D2BDA), integer($AF0A1B4C), integer($36034AF6), integer($41047A60),
    integer($DF60EFC3), integer($A867DF55), integer($316E8EEF), integer($4669BE79),
    integer($CB61B38C), integer($BC66831A), integer($256FD2A0), integer($5268E236),
    integer($CC0C7795), integer($BB0B4703), integer($220216B9), integer($5505262F),
    integer($C5BA3BBE), integer($B2BD0B28), integer($2BB45A92), integer($5CB36A04),
    integer($C2D7FFA7), integer($B5D0CF31), integer($2CD99E8B), integer($5BDEAE1D),
    integer($9B64C2B0), integer($EC63F226), integer($756AA39C), integer($026D930A),
    integer($9C0906A9), integer($EB0E363F), integer($72076785), integer($05005713),
    integer($95BF4A82), integer($E2B87A14), integer($7BB12BAE), integer($0CB61B38),
    integer($92D28E9B), integer($E5D5BE0D), integer($7CDCEFB7), integer($0BDBDF21),
    integer($86D3D2D4), integer($F1D4E242), integer($68DDB3F8), integer($1FDA836E),
    integer($81BE16CD), integer($F6B9265B), integer($6FB077E1), integer($18B74777),
    integer($88085AE6), integer($FF0F6A70), integer($66063BCA), integer($11010B5C),
    integer($8F659EFF), integer($F862AE69), integer($616BFFD3), integer($166CCF45),
    integer($A00AE278), integer($D70DD2EE), integer($4E048354), integer($3903B3C2),
    integer($A7672661), integer($D06016F7), integer($4969474D), integer($3E6E77DB),
    integer($AED16A4A), integer($D9D65ADC), integer($40DF0B66), integer($37D83BF0),
    integer($A9BCAE53), integer($DEBB9EC5), integer($47B2CF7F), integer($30B5FFE9),
    integer($BDBDF21C), integer($CABAC28A), integer($53B39330), integer($24B4A3A6),
    integer($BAD03605), integer($CDD70693), integer($54DE5729), integer($23D967BF),
    integer($B3667A2E), integer($C4614AB8), integer($5D681B02), integer($2A6F2B94),
    integer($B40BBE37), integer($C30C8EA1), integer($5A05DF1B), integer($2D02EF8D)
    );

  Crc16Tab: array[0..255] of word = (
    $0000, $1189, $2312, $329B, $4624, $57ad, $6536, $74BF,
    $8C48, $9DC1, $AF5A, $BED3, $CA6C, $DBE5, $E97E, $F8F7,
    $1081, $0108, $3393, $221A, $56A5, $472C, $75B7, $643E,
    $9CC9, $8D40, $BFDB, $AE52, $DAED, $CB64, $F9FF, $E876,
    $2102, $308B, $0210, $1399, $6726, $76AF, $4434, $55BD,
    $AD4A, $BCC3, $8E58, $9FD1, $EB6E, $FAE7, $C87C, $D9F5,
    $3183, $200A, $1291, $0318, $77A7, $662E, $54B5, $453C,
    $BDCB, $AC42, $9ED9, $8F50, $FBEF, $EA66, $D8FD, $C974,
    $4204, $538D, $6116, $709F, $0420, $15A9, $2732, $36BB,
    $CE4C, $DFC5, $ED5E, $FCD7, $8868, $99E1, $AB7A, $BAF3,
    $5285, $430C, $7197, $601E, $14A1, $0528, $37B3, $263A,
    $DECD, $CF44, $FDDF, $EC56, $98E9, $8960, $BBFB, $AA72,
    $6306, $728F, $4014, $519D, $2522, $34AB, $0630, $17B9,
    $EF4E, $FEC7, $CC5C, $DDD5, $A96A, $B8E3, $8A78, $9BF1,
    $7387, $620E, $5095, $411C, $35A3, $242A, $16B1, $0738,
    $FFCF, $EE46, $DCDD, $CD54, $B9EB, $A862, $9AF9, $8B70,
    $8408, $9581, $A71A, $B693, $C22C, $D3A5, $E13E, $F0B7,
    $0840, $19C9, $2B52, $3ADB, $4E64, $5FED, $6D76, $7CFF,
    $9489, $8500, $B79B, $A612, $D2AD, $C324, $F1BF, $E036,
    $18C1, $0948, $3BD3, $2A5A, $5EE5, $4F6C, $7DF7, $6C7E,
    $A50A, $B483, $8618, $9791, $E32E, $F2A7, $C03C, $D1B5,
    $2942, $38CB, $0A50, $1BD9, $6F66, $7EEF, $4C74, $5DFD,
    $B58B, $A402, $9699, $8710, $F3AF, $E226, $D0BD, $C134,
    $39C3, $284A, $1AD1, $0B58, $7FE7, $6E6E, $5CF5, $4D7C,
    $C60C, $D785, $E51E, $F497, $8028, $91A1, $A33A, $B2B3,
    $4A44, $5BCD, $6956, $78DF, $0C60, $1DE9, $2F72, $3Efb,
    $D68D, $C704, $F59F, $E416, $90A9, $8120, $B3BB, $A232,
    $5AC5, $4B4C, $79D7, $685E, $1CE1, $0D68, $3FF3, $2E7A,
    $E70E, $F687, $C41C, $D595, $A12A, $B0A3, $8238, $93B1,
    $6B46, $7ACF, $4854, $59DD, $2D62, $3CEB, $0E70, $1FF9,
    $F78F, $E606, $D49D, $C514, $B1AB, $A022, $92B9, $8330,
    $7BC7, $6A4E, $58D5, $495C, $3DE3, $2C6A, $1EF1, $0F78
    );

PROCEDURE ArrByteToLong(VAR ArByte: array of byte; VAR ArLong: array of integer);
{$IFDEF CIL}
VAR
  n: integer;
{$ENDIF}
begin
  if (high(ArByte) + 1) > ((high(ArLong) + 1) * 4) then
    exit;
  {$IFDEF CIL}
  for n := 0 to ((high(ArByte) + 1) div 4) - 1 do
    ArLong[n] := ArByte[n * 4 + 0]
      + (ArByte[n * 4 + 1] shl 8)
      + (ArByte[n * 4 + 2] shl 16)
      + (ArByte[n * 4 + 3] shl 24);
  {$ELSE}
  move(ArByte[0], ArLong[0], high(ArByte) + 1);
  {$ENDIF}
end;

PROCEDURE ArrLongToByte(VAR ArLong: array of integer; VAR ArByte: array of byte);
{$IFDEF CIL}
VAR
  n: integer;
{$ENDIF}
begin
  if (high(ArByte) + 1) < ((high(ArLong) + 1) * 4) then
    exit;
  {$IFDEF CIL}
  for n := 0 to high(ArLong) do
  begin
    ArByte[n * 4 + 0] := ArLong[n] and $000000ff;
    ArByte[n * 4 + 1] := (ArLong[n] shr 8) and $000000ff;
    ArByte[n * 4 + 2] := (ArLong[n] shr 16) and $000000ff;
    ArByte[n * 4 + 3] := (ArLong[n] shr 24) and $000000ff;
  end;
  {$ELSE}
  move(ArLong[0], ArByte[0], high(ArByte) + 1);
  {$ENDIF}
end;

TYPE
  TMDCtx = record
    state: array[0..3] of integer;
    count: array[0..1] of integer;
    BufAnsiChar: array[0..63] of byte;
    BufLong: array[0..15] of integer;
  end;
  TSHA1Ctx= record
    hi, Lo: integer;
    buffer: array[0..63] of byte;
    index: integer;
    hash: array[0..4] of integer;
    HashByte: array[0..19] of byte;
  end;

  TMDTransform = PROCEDURE(VAR Buf: array of longint; CONST data: array of longint);

{==============================================================================}

FUNCTION DecodeTriplet(CONST value: ansistring; Delimiter: AnsiChar): ansistring;
VAR
  x, l, lv: integer;
  c: AnsiChar;
  b: byte;
  bad: boolean;
begin
  lv := length(value);
  setLength(result, lv);
  x := 1;
  l := 1;
  while x <= lv do
  begin
    c := value[x];
    inc(x);
    if c <> Delimiter then
    begin
      result[l] := c;
      inc(l);
    end
    else
      if x < lv then
      begin
        case value[x] of
          #13:
            if (value[x + 1] = #10) then
              inc(x, 2)
            else
              inc(x);
          #10:
            if (value[x + 1] = #13) then
              inc(x, 2)
            else
              inc(x);
        else
          begin
            bad := false;
            case value[x] of
              '0'..'9': b := (byte(value[x]) - 48) shl 4;
              'a'..'f', 'A'..'F': b := ((byte(value[x]) and 7) + 9) shl 4;
            else
              begin
                b := 0;
                bad := true;
              end;
            end;
            case value[x + 1] of
              '0'..'9': b := b or (byte(value[x + 1]) - 48);
              'a'..'f', 'A'..'F': b := b or ((byte(value[x + 1]) and 7) + 9);
            else
              bad := true;
            end;
            if bad then
            begin
              result[l] := c;
              inc(l);
            end
            else
            begin
              inc(x, 2);
              result[l] := AnsiChar(b);
              inc(l);
            end;
          end;
        end;
      end
      else
        break;
  end;
  dec(l);
  setLength(result, l);
end;

{==============================================================================}

FUNCTION DecodeQuotedPrintable(CONST value: ansistring): ansistring;
begin
  result := DecodeTriplet(value, '=');
end;

{==============================================================================}

FUNCTION DecodeURL(CONST value: ansistring): ansistring;
begin
  result := DecodeTriplet(value, '%');
end;

{==============================================================================}

FUNCTION EncodeTriplet(CONST value: ansistring; Delimiter: AnsiChar;
  Specials: TSpecials): ansistring;
VAR
  n, l: integer;
  s: ansistring;
  c: AnsiChar;
begin
  setLength(result, length(value) * 3);
  l := 1;
  for n := 1 to length(value) do
  begin
    c := value[n];
    if c in Specials then
    begin
      result[l] := Delimiter;
      inc(l);
      s := IntToHex(ord(c), 2);
      result[l] := s[1];
      inc(l);
      result[l] := s[2];
      inc(l);
    end
    else
    begin
      result[l] := c;
      inc(l);
    end;
  end;
  dec(l);
  setLength(result, l);
end;

{==============================================================================}

FUNCTION EncodeQuotedPrintable(CONST value: ansistring): ansistring;
begin
  result := EncodeTriplet(value, '=',  ['='] + NonAsciiChar);
end;

{==============================================================================}

FUNCTION EncodeSafeQuotedPrintable(CONST value: ansistring): ansistring;
begin
  result := EncodeTriplet(value, '=', SpecialChar + NonAsciiChar);
end;

{==============================================================================}

FUNCTION EncodeURLElement(CONST value: ansistring): ansistring;
begin
  result := EncodeTriplet(value, '%', URLSpecialChar + URLFullSpecialChar);
end;

{==============================================================================}

FUNCTION EncodeURL(CONST value: ansistring): ansistring;
begin
  result := EncodeTriplet(value, '%', URLSpecialChar);
end;

{==============================================================================}

FUNCTION Decode4to3(CONST value, table: ansistring): ansistring;
VAR
  x, y, n, l: integer;
  d: array[0..3] of byte;
begin
  setLength(result, length(value));
  x := 1;
  l := 1;
  while x <= length(value) do
  begin
    for n := 0 to 3 do
    begin
      if x > length(value) then
        d[n] := 64
      else
      begin
        y := pos(value[x], table);
        if y < 1 then
          y := 1;
        d[n] := y - 1;
      end;
      inc(x);
    end;
    result[l] := AnsiChar((D[0] and $3F) shl 2 + (D[1] and $30) shr 4);
    inc(l);
    if d[2] <> 64 then
    begin
      result[l] := AnsiChar((D[1] and $0F) shl 4 + (D[2] and $3C) shr 2);
      inc(l);
      if d[3] <> 64 then
      begin
        result[l] := AnsiChar((D[2] and $03) shl 6 + (D[3] and $3F));
        inc(l);
      end;
    end;
  end;
  dec(l);
  setLength(result, l);
end;

{==============================================================================}
FUNCTION Decode4to3Ex(CONST value, table: ansistring): ansistring;
VAR
  x, y, lv: integer;
  d: integer;
  dl: integer;
  c: byte;
  p: integer;
begin
  lv := length(value);
  setLength(result, lv);
  x := 1;
  dl := 4;
  d := 0;
  p := 1;
  while x <= lv do
  begin
    y := ord(value[x]);
    if y in [33..127] then
      c := ord(table[y - 32])
    else
      c := 64;
    inc(x);
    if c > 63 then
      continue;
    d := (d shl 6) or c;
    dec(dl);
    if dl <> 0 then
      continue;
    result[p] := AnsiChar((d shr 16) and $ff);
    inc(p);
    result[p] := AnsiChar((d shr 8) and $ff);
    inc(p);
    result[p] := AnsiChar(d and $ff);
    inc(p);
    d := 0;
    dl := 4;
  end;
  case dl of
    1:
      begin
        d := d shr 2;
        result[p] := AnsiChar((d shr 8) and $ff);
        inc(p);
        result[p] := AnsiChar(d and $ff);
        inc(p);
      end;
    2:
      begin
        d := d shr 4;
        result[p] := AnsiChar(d and $ff);
        inc(p);
      end;
  end;
  setLength(result, p - 1);
end;

{==============================================================================}

FUNCTION Encode3to4(CONST value, table: ansistring): ansistring;
VAR
  c: byte;
  n, l: integer;
  count: integer;
  DOut: array[0..3] of byte;
begin
  setLength(result, ((length(value) + 2) div 3) * 4);
  l := 1;
  count := 1;
  while count <= length(value) do
  begin
    c := ord(value[count]);
    inc(count);
    DOut[0] := (c and $FC) shr 2;
    DOut[1] := (c and $03) shl 4;
    if count <= length(value) then
    begin
      c := ord(value[count]);
      inc(count);
      DOut[1] := DOut[1] + (c and $F0) shr 4;
      DOut[2] := (c and $0F) shl 2;
      if count <= length(value) then
      begin
        c := ord(value[count]);
        inc(count);
        DOut[2] := DOut[2] + (c and $C0) shr 6;
        DOut[3] := (c and $3F);
      end
      else
      begin
        DOut[3] := $40;
      end;
    end
    else
    begin
      DOut[2] := $40;
      DOut[3] := $40;
    end;
    for n := 0 to 3 do
    begin
      if (DOut[n] + 1) <= length(table) then
      begin
        result[l] := table[DOut[n] + 1];
        inc(l);
      end;
    end;
  end;
  setLength(result, l - 1);
end;

{==============================================================================}

FUNCTION DecodeBase64(CONST value: ansistring): ansistring;
begin
  result := Decode4to3Ex(value, ReTableBase64);
end;

{==============================================================================}

FUNCTION EncodeBase64(CONST value: ansistring): ansistring;
begin
  result := Encode3to4(value, TableBase64);
end;

{==============================================================================}

FUNCTION DecodeBase64mod(CONST value: ansistring): ansistring;
begin
  result := Decode4to3(value, TableBase64mod);
end;

{==============================================================================}

FUNCTION EncodeBase64mod(CONST value: ansistring): ansistring;
begin
  result := Encode3to4(value, TableBase64mod);
end;

{==============================================================================}

FUNCTION DecodeUU(CONST value: ansistring): ansistring;
VAR
  s: ansistring;
  uut: ansistring;
  x: integer;
begin
  result := '';
  uut := TableUU;
  s := trim(uppercase(value));
  if s = '' then exit;
  if pos('BEGIN', s) = 1 then
    exit;
  if pos('END', s) = 1 then
    exit;
  if pos('TABLE', s) = 1 then
    exit; //ignore Table yet (set custom UUT)
  //begin decoding
  x := pos(value[1], uut) - 1;
  case (x mod 3) of
    0: x :=(x div 3)* 4;
    1: x :=((x div 3) * 4) + 2;
    2: x :=((x  div 3) * 4) + 3;
  end;
  //x - lenght UU line
  s := copy(value, 2, x);
  if s = '' then
    exit;
  s := s + StringOfChar(' ', x - length(s));
  result := Decode4to3(s, uut);
end;

{==============================================================================}

FUNCTION EncodeUU(CONST value: ansistring): ansistring;
begin
  result := '';
  if length(value) < length(TableUU) then
    result := TableUU[length(value) + 1] + Encode3to4(value, TableUU);
end;

{==============================================================================}

FUNCTION DecodeXX(CONST value: ansistring): ansistring;
VAR
  s: ansistring;
  x: integer;
begin
  result := '';
  s := trim(uppercase(value));
  if s = '' then
    exit;
  if pos('BEGIN', s) = 1 then
    exit;
  if pos('END', s) = 1 then
    exit;
  //begin decoding
  x := pos(value[1], TableXX) - 1;
  case (x mod 3) of
    0: x :=(x div 3)* 4;
    1: x :=((x div 3) * 4) + 2;
    2: x :=((x  div 3) * 4) + 3;
  end;
  //x - lenght XX line
  s := copy(value, 2, x);
  if s = '' then
    exit;
  s := s + StringOfChar(' ', x - length(s));
  result := Decode4to3(s, TableXX);
end;

{==============================================================================}

FUNCTION DecodeYEnc(CONST value: ansistring): ansistring;
VAR
  C : byte;
  i: integer;
begin
  result := '';
  i := 1;
  while i <= length(value) do
  begin
    c := ord(value[i]);
    inc(i);
    if c = ord('=') then
    begin
      c := ord(value[i]);
      inc(i);
      dec(c, 64);
    end;
    dec(C, 42);
    result := result + AnsiChar(C);
  end;
end;

{==============================================================================}

FUNCTION UpdateCrc32(value: byte; Crc32: integer): integer;
begin
  result := (Crc32 shr 8)
    xor crc32tab[byte(value xor (Crc32 and integer($000000ff)))];
end;

{==============================================================================}

FUNCTION Crc32(CONST value: ansistring): integer;
VAR
  n: integer;
begin
  result := integer($ffffffff);
  for n := 1 to length(value) do
    result := UpdateCrc32(ord(value[n]), result);
  result := not result;
end;

{==============================================================================}

FUNCTION UpdateCrc16(value: byte; Crc16: word): word;
begin
  result := ((Crc16 shr 8) and $00ff) xor
    crc16tab[byte(Crc16 xor (word(value)) and $00ff)];
end;

{==============================================================================}

FUNCTION Crc16(CONST value: ansistring): word;
VAR
  n: integer;
begin
  result := $FFFF;
  for n := 1 to length(value) do
    result := UpdateCrc16(ord(value[n]), result);
end;

{==============================================================================}

PROCEDURE MDInit(VAR MDContext: TMDCtx);
VAR
  n: integer;
begin
  MDContext.count[0] := 0;
  MDContext.count[1] := 0;
  for n := 0 to high(MDContext.BufAnsiChar) do
    MDContext.BufAnsiChar[n] := 0;
  for n := 0 to high(MDContext.BufLong) do
    MDContext.BufLong[n] := 0;
  MDContext.state[0] := integer($67452301);
  MDContext.state[1] := integer($EFCDAB89);
  MDContext.state[2] := integer($98BADCFE);
  MDContext.state[3] := integer($10325476);
end;

PROCEDURE MD5Transform(VAR Buf: array of longint; CONST data: array of longint);
VAR
  A, B, C, D: longint;

  PROCEDURE Round1(VAR W: longint; X, Y, Z, data: longint; S: byte);
  begin
    inc(W, (Z xor (X and (Y xor Z))) + data);
    W := (W shl S) or (W shr (32 - S));
    inc(W, X);
  end;

  PROCEDURE Round2(VAR W: longint; X, Y, Z, data: longint; S: byte);
  begin
    inc(W, (Y xor (Z and (X xor Y))) + data);
    W := (W shl S) or (W shr (32 - S));
    inc(W, X);
  end;

  PROCEDURE Round3(VAR W: longint; X, Y, Z, data: longint; S: byte);
  begin
    inc(W, (X xor Y xor Z) + data);
    W := (W shl S) or (W shr (32 - S));
    inc(W, X);
  end;

  PROCEDURE Round4(VAR W: longint; X, Y, Z, data: longint; S: byte);
  begin
    inc(W, (Y xor (X or not Z)) + data);
    W := (W shl S) or (W shr (32 - S));
    inc(W, X);
  end;
begin
  A := Buf[0];
  B := Buf[1];
  C := Buf[2];
  D := Buf[3];

  Round1(A, B, C, D, data[0] + longint($D76AA478), 7);
  Round1(D, A, B, C, data[1] + longint($E8C7B756), 12);
  Round1(C, D, A, B, data[2] + longint($242070DB), 17);
  Round1(B, C, D, A, data[3] + longint($C1BDCEEE), 22);
  Round1(A, B, C, D, data[4] + longint($F57C0FAF), 7);
  Round1(D, A, B, C, data[5] + longint($4787C62A), 12);
  Round1(C, D, A, B, data[6] + longint($A8304613), 17);
  Round1(B, C, D, A, data[7] + longint($FD469501), 22);
  Round1(A, B, C, D, data[8] + longint($698098D8), 7);
  Round1(D, A, B, C, data[9] + longint($8B44F7AF), 12);
  Round1(C, D, A, B, data[10] + longint($FFFF5BB1), 17);
  Round1(B, C, D, A, data[11] + longint($895CD7BE), 22);
  Round1(A, B, C, D, data[12] + longint($6B901122), 7);
  Round1(D, A, B, C, data[13] + longint($FD987193), 12);
  Round1(C, D, A, B, data[14] + longint($A679438E), 17);
  Round1(B, C, D, A, data[15] + longint($49B40821), 22);

  Round2(A, B, C, D, data[1] + longint($F61E2562), 5);
  Round2(D, A, B, C, data[6] + longint($C040B340), 9);
  Round2(C, D, A, B, data[11] + longint($265E5A51), 14);
  Round2(B, C, D, A, data[0] + longint($E9B6C7AA), 20);
  Round2(A, B, C, D, data[5] + longint($D62F105D), 5);
  Round2(D, A, B, C, data[10] + longint($02441453), 9);
  Round2(C, D, A, B, data[15] + longint($D8A1E681), 14);
  Round2(B, C, D, A, data[4] + longint($E7D3FBC8), 20);
  Round2(A, B, C, D, data[9] + longint($21E1CDE6), 5);
  Round2(D, A, B, C, data[14] + longint($C33707D6), 9);
  Round2(C, D, A, B, data[3] + longint($F4D50D87), 14);
  Round2(B, C, D, A, data[8] + longint($455A14ED), 20);
  Round2(A, B, C, D, data[13] + longint($A9E3E905), 5);
  Round2(D, A, B, C, data[2] + longint($FCEFA3F8), 9);
  Round2(C, D, A, B, data[7] + longint($676F02D9), 14);
  Round2(B, C, D, A, data[12] + longint($8D2A4C8A), 20);

  Round3(A, B, C, D, data[5] + longint($FFFA3942), 4);
  Round3(D, A, B, C, data[8] + longint($8771F681), 11);
  Round3(C, D, A, B, data[11] + longint($6D9D6122), 16);
  Round3(B, C, D, A, data[14] + longint($FDE5380C), 23);
  Round3(A, B, C, D, data[1] + longint($A4BEEA44), 4);
  Round3(D, A, B, C, data[4] + longint($4BDECFA9), 11);
  Round3(C, D, A, B, data[7] + longint($F6BB4B60), 16);
  Round3(B, C, D, A, data[10] + longint($BEBFBC70), 23);
  Round3(A, B, C, D, data[13] + longint($289B7EC6), 4);
  Round3(D, A, B, C, data[0] + longint($EAA127FA), 11);
  Round3(C, D, A, B, data[3] + longint($D4EF3085), 16);
  Round3(B, C, D, A, data[6] + longint($04881D05), 23);
  Round3(A, B, C, D, data[9] + longint($D9D4D039), 4);
  Round3(D, A, B, C, data[12] + longint($E6DB99E5), 11);
  Round3(C, D, A, B, data[15] + longint($1FA27CF8), 16);
  Round3(B, C, D, A, data[2] + longint($C4AC5665), 23);

  Round4(A, B, C, D, data[0] + longint($F4292244), 6);
  Round4(D, A, B, C, data[7] + longint($432AFF97), 10);
  Round4(C, D, A, B, data[14] + longint($AB9423A7), 15);
  Round4(B, C, D, A, data[5] + longint($FC93A039), 21);
  Round4(A, B, C, D, data[12] + longint($655B59C3), 6);
  Round4(D, A, B, C, data[3] + longint($8F0CCC92), 10);
  Round4(C, D, A, B, data[10] + longint($FFEFF47D), 15);
  Round4(B, C, D, A, data[1] + longint($85845DD1), 21);
  Round4(A, B, C, D, data[8] + longint($6FA87E4F), 6);
  Round4(D, A, B, C, data[15] + longint($FE2CE6E0), 10);
  Round4(C, D, A, B, data[6] + longint($A3014314), 15);
  Round4(B, C, D, A, data[13] + longint($4E0811A1), 21);
  Round4(A, B, C, D, data[4] + longint($F7537E82), 6);
  Round4(D, A, B, C, data[11] + longint($BD3AF235), 10);
  Round4(C, D, A, B, data[2] + longint($2AD7D2BB), 15);
  Round4(B, C, D, A, data[9] + longint($EB86D391), 21);

  inc(Buf[0], A);
  inc(Buf[1], B);
  inc(Buf[2], C);
  inc(Buf[3], D);
end;

//fixed by James McAdams
PROCEDURE MDUpdate(VAR MDContext: TMDCtx; CONST data: ansistring; transform: TMDTransform);
VAR
  index, partLen, InputLen, I: integer;
{$IFDEF CIL}
  n: integer;
{$ENDIF}
begin
  InputLen := length(data);
  with MDContext do
  begin
    index := (count[0] shr 3) and $3F;
    inc(count[0], InputLen shl 3);
    if count[0] < (InputLen shl 3) then
      inc(count[1]);
    inc(count[1], InputLen shr 29);
    partLen := 64 - index;
    if InputLen >= partLen then
    begin
      ArrLongToByte(BufLong, BufAnsiChar);
      {$IFDEF CIL}
      for n := 1 to partLen do
        BufAnsiChar[index - 1 + n] := ord(data[n]);
      {$ELSE}
      move(data[1], BufAnsiChar[index], partLen);
      {$ENDIF}
      ArrByteToLong(BufAnsiChar, BufLong);
      transform(state, Buflong);
      I := partLen;
  		while I + 63 < InputLen do
      begin
        ArrLongToByte(BufLong, BufAnsiChar);
        {$IFDEF CIL}
        for n := 1 to 64 do
          BufAnsiChar[n - 1] := ord(data[i + n]);
        {$ELSE}
        move(data[I+1], BufAnsiChar, 64);
        {$ENDIF}
        ArrByteToLong(BufAnsiChar, BufLong);
        transform(state, Buflong);
	  	  inc(I, 64);
		  end;
      index := 0;
    end
    else
      I := 0;
    ArrLongToByte(BufLong, BufAnsiChar);
    {$IFDEF CIL}
    for n := 1 to InputLen-I do
      BufAnsiChar[index + n - 1] := ord(data[i + n]);
    {$ELSE}
    move(data[I+1], BufAnsiChar[index], InputLen-I);
    {$ENDIF}
    ArrByteToLong(BufAnsiChar, BufLong);
  end
end;

FUNCTION MDFinal(VAR MDContext: TMDCtx; transform: TMDTransform): ansistring;
VAR
  Cnt: word;
  P: byte;
  digest: array[0..15] of byte;
  i: integer;
  n: integer;
begin
  for I := 0 to 15 do
    Digest[I] := I + 1;
  with MDContext do
  begin
    Cnt := (count[0] shr 3) and $3F;
    P := Cnt;
    BufAnsiChar[P] := $80;
    inc(P);
    Cnt := 64 - 1 - Cnt;
    if Cnt < 8 then
    begin
      for n := 0 to cnt - 1 do
        BufAnsiChar[P + n] := 0;
      ArrByteToLong(BufAnsiChar, BufLong);
//      FillChar(BufAnsiChar[P], Cnt, #0);
      transform(state, BufLong);
      ArrLongToByte(BufLong, BufAnsiChar);
      for n := 0 to 55 do
        BufAnsiChar[n] := 0;
      ArrByteToLong(BufAnsiChar, BufLong);
//      FillChar(BufAnsiChar, 56, #0);
    end
    else
    begin
      for n := 0 to Cnt - 8 - 1 do
        BufAnsiChar[p + n] := 0;
      ArrByteToLong(BufAnsiChar, BufLong);
//      FillChar(BufAnsiChar[P], Cnt - 8, #0);
    end;
    BufLong[14] := count[0];
    BufLong[15] := count[1];
    transform(state, BufLong);
    ArrLongToByte(state, Digest);
//    Move(State, Digest, 16);
    result := '';
    for i := 0 to 15 do
      result := result + AnsiChar(digest[i]);
  end;
//  FillChar(MD5Context, SizeOf(TMD5Ctx), #0)
end;

{==============================================================================}

FUNCTION MD5(CONST value: ansistring): ansistring;
VAR
  MDContext: TMDCtx;
begin
  MDInit(MDContext);
  MDUpdate(MDContext, value, @MD5Transform);
  result := MDFinal(MDContext, @MD5Transform);
end;

{==============================================================================}

FUNCTION HMAC_MD5(text, key: ansistring): ansistring;
VAR
  ipad, opad, s: ansistring;
  n: integer;
  MDContext: TMDCtx;
begin
  if length(key) > 64 then
    key := md5(key);
  ipad := StringOfChar(#$36, 64);
  opad := StringOfChar(#$5C, 64);
  for n := 1 to length(key) do
  begin
    ipad[n] := AnsiChar(byte(ipad[n]) xor byte(key[n]));
    opad[n] := AnsiChar(byte(opad[n]) xor byte(key[n]));
  end;
  MDInit(MDContext);
  MDUpdate(MDContext, ipad, @MD5Transform);
  MDUpdate(MDContext, text, @MD5Transform);
  s := MDFinal(MDContext, @MD5Transform);
  MDInit(MDContext);
  MDUpdate(MDContext, opad, @MD5Transform);
  MDUpdate(MDContext, s, @MD5Transform);
  result := MDFinal(MDContext, @MD5Transform);
end;

{==============================================================================}

FUNCTION MD5LongHash(CONST value: ansistring; len: integer): ansistring;
VAR
  cnt, rest: integer;
  l: integer;
  n: integer;
  MDContext: TMDCtx;
begin
  l := length(value);
  cnt := len div l;
  rest := len mod l;
  MDInit(MDContext);
  for n := 1 to cnt do
    MDUpdate(MDContext, value, @MD5Transform);
  if rest > 0 then
    MDUpdate(MDContext, copy(value, 1, rest), @MD5Transform);
  result := MDFinal(MDContext, @MD5Transform);
end;

{==============================================================================}
// SHA1 is based on sources by Dave Barton (davebarton@bigfoot.com)

PROCEDURE SHA1init( VAR SHA1Context: TSHA1Ctx );
VAR
  n: integer;
begin
  SHA1Context.hi := 0;
  SHA1Context.Lo := 0;
  SHA1Context.index := 0;
  for n := 0 to high(SHA1Context.buffer) do
    SHA1Context.buffer[n] := 0;
  for n := 0 to high(SHA1Context.HashByte) do
    SHA1Context.HashByte[n] := 0;
//  FillChar(SHA1Context, SizeOf(TSHA1Ctx), #0);
  SHA1Context.hash[0] := integer($67452301);
  SHA1Context.hash[1] := integer($EFCDAB89);
  SHA1Context.hash[2] := integer($98BADCFE);
  SHA1Context.hash[3] := integer($10325476);
  SHA1Context.hash[4] := integer($C3D2E1F0);
end;

//******************************************************************************
FUNCTION RB(A: integer): integer;
begin
  result := (A shr 24) or ((A shr 8) and $FF00) or ((A shl 8) and $FF0000) or (A shl 24);
end;

PROCEDURE SHA1Compress(VAR data: TSHA1Ctx);
VAR
  A, B, C, D, E, T: integer;
  W: array[0..79] of integer;
  i: integer;
  n: integer;

  FUNCTION F1(x, y, z: integer): integer;
  begin
    result := z xor (x and (y xor z));
  end;
  FUNCTION F2(x, y, z: integer): integer;
  begin
    result := x xor y xor z;
  end;
  FUNCTION F3(x, y, z: integer): integer;
  begin
    result := (x and y) or (z and (x or y));
  end;
  FUNCTION LRot32(X: integer; c: integer): integer;
  begin
    result := (x shl c) or (x shr (32 - c));
  end;
begin
  ArrByteToLong(data.buffer, W);
//  Move(Data.Buffer, W, Sizeof(Data.Buffer));
  for i := 0 to 15 do
    W[i] := RB(W[i]);
  for i := 16 to 79 do
    W[i] := LRot32(W[i-3] xor W[i-8] xor W[i-14] xor W[i-16], 1);
  A := data.hash[0];
  B := data.hash[1];
  C := data.hash[2];
  D := data.hash[3];
  E := data.hash[4];
  for i := 0 to 19 do
  begin
    T := LRot32(A, 5) + F1(B, C, D) + E + W[i] + integer($5A827999);
    E := D;
    D := C;
    C := LRot32(B, 30);
    B := A;
    A := T;
  end;
  for i := 20 to 39 do
  begin
    T := LRot32(A, 5) + F2(B, C, D) + E + W[i] + integer($6ED9EBA1);
    E := D;
    D := C;
    C := LRot32(B, 30);
    B := A;
    A := T;
  end;
  for i := 40 to 59 do
  begin
    T := LRot32(A, 5) + F3(B, C, D) + E + W[i] + integer($8F1BBCDC);
    E := D;
    D := C;
    C := LRot32(B, 30);
    B := A;
    A := T;
  end;
  for i := 60 to 79 do
  begin
    T := LRot32(A, 5) + F2(B, C, D) + E + W[i] + integer($CA62C1D6);
    E := D;
    D := C;
    C := LRot32(B, 30);
    B := A;
    A := T;
  end;
  data.hash[0] := data.hash[0] + A;
  data.hash[1] := data.hash[1] + B;
  data.hash[2] := data.hash[2] + C;
  data.hash[3] := data.hash[3] + D;
  data.hash[4] := data.hash[4] + E;
  for n := 0 to high(w) do
    w[n] := 0;
//  FillChar(W, Sizeof(W), 0);
  for n := 0 to high(data.buffer) do
    data.buffer[n] := 0;
//  FillChar(Data.Buffer, Sizeof(Data.Buffer), 0);
end;

//******************************************************************************
PROCEDURE SHA1Update(VAR context: TSHA1Ctx; CONST data: ansistring);
VAR
  len: integer;
  n: integer;
  i, k: integer;
begin
  len := length(data);
  for k := 0 to 7 do
  begin
    i := context.Lo;
    inc(context.Lo, len);
    if context.Lo < i then
      inc(context.hi);
  end;
  for n := 1 to len do
  begin
    context.buffer[context.index] := byte(data[n]);
    inc(context.index);
    if context.index = 64 then
    begin
      context.index := 0;
      SHA1Compress(context);
    end;
  end;
end;

//******************************************************************************
FUNCTION SHA1Final(VAR context: TSHA1Ctx): ansistring;
TYPE
  PInteger = ^integer;
VAR
  i: integer;
  PROCEDURE ItoArr(VAR Ar: array of byte; I, value: integer);
  begin
    Ar[i + 0] := value and $000000ff;
    Ar[i + 1] := (value shr 8) and $000000ff;
    Ar[i + 2] := (value shr 16) and $000000ff;
    Ar[i + 3] := (value shr 24) and $000000ff;
  end;
begin
  context.buffer[context.index] := $80;
  if context.index >= 56 then
    SHA1Compress(context);
  ItoArr(context.buffer, 56, RB(context.hi));
  ItoArr(context.buffer, 60, RB(context.Lo));
//  Pinteger(@Context.Buffer[56])^ := RB(Context.Hi);
//  Pinteger(@Context.Buffer[60])^ := RB(Context.Lo);
  SHA1Compress(context);
  context.hash[0] := RB(context.hash[0]);
  context.hash[1] := RB(context.hash[1]);
  context.hash[2] := RB(context.hash[2]);
  context.hash[3] := RB(context.hash[3]);
  context.hash[4] := RB(context.hash[4]);
  ArrLongToByte(context.hash, context.HashByte);
  result := '';
  for i := 0 to 19 do
    result := result + AnsiChar(context.HashByte[i]);
end;

FUNCTION SHA1(CONST value: ansistring): ansistring;
VAR
  SHA1Context: TSHA1Ctx;
begin
  SHA1Init(SHA1Context);
  SHA1Update(SHA1Context, value);
  result := SHA1Final(SHA1Context);
end;

{==============================================================================}

FUNCTION HMAC_SHA1(text, key: ansistring): ansistring;
VAR
  ipad, opad, s: ansistring;
  n: integer;
  SHA1Context: TSHA1Ctx;
begin
  if length(key) > 64 then
    key := SHA1(key);
  ipad := StringOfChar(#$36, 64);
  opad := StringOfChar(#$5C, 64);
  for n := 1 to length(key) do
  begin
    ipad[n] := AnsiChar(byte(ipad[n]) xor byte(key[n]));
    opad[n] := AnsiChar(byte(opad[n]) xor byte(key[n]));
  end;
  SHA1Init(SHA1Context);
  SHA1Update(SHA1Context, ipad);
  SHA1Update(SHA1Context, text);
  s := SHA1Final(SHA1Context);
  SHA1Init(SHA1Context);
  SHA1Update(SHA1Context, opad);
  SHA1Update(SHA1Context, s);
  result := SHA1Final(SHA1Context);
end;

{==============================================================================}

FUNCTION SHA1LongHash(CONST value: ansistring; len: integer): ansistring;
VAR
  cnt, rest: integer;
  l: integer;
  n: integer;
  SHA1Context: TSHA1Ctx;
begin
  l := length(value);
  cnt := len div l;
  rest := len mod l;
  SHA1Init(SHA1Context);
  for n := 1 to cnt do
    SHA1Update(SHA1Context, value);
  if rest > 0 then
    SHA1Update(SHA1Context, copy(value, 1, rest));
  result := SHA1Final(SHA1Context);
end;

{==============================================================================}

PROCEDURE MD4Transform(VAR Buf: array of longint; CONST data: array of longint);
VAR
  A, B, C, D: longint;
  FUNCTION LRot32(a, b: longint): longint;
  begin
    result:= (a shl b) or (a shr (32 - b));
  end;
begin
  A := Buf[0];
  B := Buf[1];
  C := Buf[2];
  D := Buf[3];

  A:= LRot32(A + (D xor (B and (C xor D))) + data[ 0], 3);
  D:= LRot32(D + (C xor (A and (B xor C))) + data[ 1], 7);
  C:= LRot32(C + (B xor (D and (A xor B))) + data[ 2], 11);
  B:= LRot32(B + (A xor (C and (D xor A))) + data[ 3], 19);
  A:= LRot32(A + (D xor (B and (C xor D))) + data[ 4], 3);
  D:= LRot32(D + (C xor (A and (B xor C))) + data[ 5], 7);
  C:= LRot32(C + (B xor (D and (A xor B))) + data[ 6], 11);
  B:= LRot32(B + (A xor (C and (D xor A))) + data[ 7], 19);
  A:= LRot32(A + (D xor (B and (C xor D))) + data[ 8], 3);
  D:= LRot32(D + (C xor (A and (B xor C))) + data[ 9], 7);
  C:= LRot32(C + (B xor (D and (A xor B))) + data[10], 11);
  B:= LRot32(B + (A xor (C and (D xor A))) + data[11], 19);
  A:= LRot32(A + (D xor (B and (C xor D))) + data[12], 3);
  D:= LRot32(D + (C xor (A and (B xor C))) + data[13], 7);
  C:= LRot32(C + (B xor (D and (A xor B))) + data[14], 11);
  B:= LRot32(B + (A xor (C and (D xor A))) + data[15], 19);

  A:= LRot32(A + ((B and C) or (B and D) or (C and D)) + data[ 0] + longint($5a827999), 3);
  D:= LRot32(D + ((A and B) or (A and C) or (B and C)) + data[ 4] + longint($5a827999), 5);
  C:= LRot32(C + ((D and A) or (D and B) or (A and B)) + data[ 8] + longint($5a827999), 9);
  B:= LRot32(B + ((C and D) or (C and A) or (D and A)) + data[12] + longint($5a827999), 13);
  A:= LRot32(A + ((B and C) or (B and D) or (C and D)) + data[ 1] + longint($5a827999), 3);
  D:= LRot32(D + ((A and B) or (A and C) or (B and C)) + data[ 5] + longint($5a827999), 5);
  C:= LRot32(C + ((D and A) or (D and B) or (A and B)) + data[ 9] + longint($5a827999), 9);
  B:= LRot32(B + ((C and D) or (C and A) or (D and A)) + data[13] + longint($5a827999), 13);
  A:= LRot32(A + ((B and C) or (B and D) or (C and D)) + data[ 2] + longint($5a827999), 3);
  D:= LRot32(D + ((A and B) or (A and C) or (B and C)) + data[ 6] + longint($5a827999), 5);
  C:= LRot32(C + ((D and A) or (D and B) or (A and B)) + data[10] + longint($5a827999), 9);
  B:= LRot32(B + ((C and D) or (C and A) or (D and A)) + data[14] + longint($5a827999), 13);
  A:= LRot32(A + ((B and C) or (B and D) or (C and D)) + data[ 3] + longint($5a827999), 3);
  D:= LRot32(D + ((A and B) or (A and C) or (B and C)) + data[ 7] + longint($5a827999), 5);
  C:= LRot32(C + ((D and A) or (D and B) or (A and B)) + data[11] + longint($5a827999), 9);
  B:= LRot32(B + ((C and D) or (C and A) or (D and A)) + data[15] + longint($5a827999), 13);

  A:= LRot32(A + (B xor C xor D) + data[ 0] + longint($6ed9eba1), 3);
  D:= LRot32(D + (A xor B xor C) + data[ 8] + longint($6ed9eba1), 9);
  C:= LRot32(C + (D xor A xor B) + data[ 4] + longint($6ed9eba1), 11);
  B:= LRot32(B + (C xor D xor A) + data[12] + longint($6ed9eba1), 15);
  A:= LRot32(A + (B xor C xor D) + data[ 2] + longint($6ed9eba1), 3);
  D:= LRot32(D + (A xor B xor C) + data[10] + longint($6ed9eba1), 9);
  C:= LRot32(C + (D xor A xor B) + data[ 6] + longint($6ed9eba1), 11);
  B:= LRot32(B + (C xor D xor A) + data[14] + longint($6ed9eba1), 15);
  A:= LRot32(A + (B xor C xor D) + data[ 1] + longint($6ed9eba1), 3);
  D:= LRot32(D + (A xor B xor C) + data[ 9] + longint($6ed9eba1), 9);
  C:= LRot32(C + (D xor A xor B) + data[ 5] + longint($6ed9eba1), 11);
  B:= LRot32(B + (C xor D xor A) + data[13] + longint($6ed9eba1), 15);
  A:= LRot32(A + (B xor C xor D) + data[ 3] + longint($6ed9eba1), 3);
  D:= LRot32(D + (A xor B xor C) + data[11] + longint($6ed9eba1), 9);
  C:= LRot32(C + (D xor A xor B) + data[ 7] + longint($6ed9eba1), 11);
  B:= LRot32(B + (C xor D xor A) + data[15] + longint($6ed9eba1), 15);

  inc(Buf[0], A);
  inc(Buf[1], B);
  inc(Buf[2], C);
  inc(Buf[3], D);
end;

{==============================================================================}

FUNCTION MD4(CONST value: ansistring): ansistring;
VAR
  MDContext: TMDCtx;
begin
  MDInit(MDContext);
  MDUpdate(MDContext, value, @MD4Transform);
  result := MDFinal(MDContext, @MD4Transform);
end;

{==============================================================================}


end.
