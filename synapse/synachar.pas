{==============================================================================|
| project : Ararat Synapse                                       | 005.002.002 |
|==============================================================================|
| content: charSet conversion support                                          |
|==============================================================================|
| Copyright (c)1999-2004, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2000-2004.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{: @abstract(Charset conversion support)
This UNIT contains a routines for lot of charSet conversions.

it using built-in conversion tables or external Iconv library. Iconv is used
 when needed conversion is known by Iconv library. When Iconv library is not
 found or Iconv not know requested conversion, then are internal routines used
 for conversion. (You can disable Iconv support from your PROGRAM too!)

Internal routines knows all major charsets for Europe or America. for East-Asian
 charsets you must use Iconv library!
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT synachar;

INTERFACE

USES
{$IFNDEF WIN32}
  {$IFNDEF FPC}
  Libc,
  {$ELSE}
    {$IFDEF FPC_USE_LIBC}
  Libc,
    {$ENDIF}
  {$ENDIF}
{$ELSE}
  windows,
{$ENDIF}
  sysutils,
  synautil, synacode, synaicnv;

TYPE
  {:Type with all supported charsets.}
  TMimeChar = (ISO_8859_1, ISO_8859_2, ISO_8859_3, ISO_8859_4, ISO_8859_5,
    ISO_8859_6, ISO_8859_7, ISO_8859_8, ISO_8859_9, ISO_8859_10, ISO_8859_13,
    ISO_8859_14, ISO_8859_15, CP1250, CP1251, CP1252, CP1253, CP1254, CP1255,
    CP1256, CP1257, CP1258, KOI8_R, CP895, CP852, UCS_2, UCS_4, UTF_8, UTF_7,
    UTF_7mod, UCS_2LE, UCS_4LE,
    //next is supported by Iconv only...
    UTF_16, UTF_16LE, UTF_32, UTF_32LE, C99, JAVA, ISO_8859_16, KOI8_U, KOI8_RU,
    CP862, CP866, MAC, MACCE, MACICE, MACCRO, MACRO, MACCYR, MACUK, MACGR, MACTU,
    MACHEB, MACAR, MACTH, ROMAN8, NEXTSTEP, ARMASCII, GEORGIAN_AC, GEORGIAN_PS,
    KOI8_T, MULELAO, CP1133, TIS620, CP874, VISCII, TCVN, ISO_IR_14, JIS_X0201,
    JIS_X0208, JIS_X0212, GB1988_80, GB2312_80, ISO_IR_165, ISO_IR_149, EUC_JP,
    SHIFT_JIS, CP932, ISO_2022_JP, ISO_2022_JP1, ISO_2022_JP2, GB2312, CP936,
    GB18030, ISO_2022_CN, ISO_2022_CNE, HZ, EUC_TW, BIG5, CP950, BIG5_HKSCS,
    EUC_KR, CP949, CP1361, ISO_2022_KR, CP737, CP775, CP853, CP855, CP857,
    CP858, CP860, CP861, CP863, CP864, CP865, CP869, CP1125);

  {:Set of any charsets.}
  TMimeSetChar = set of TMimeChar;

CONST
  {:Set of charsets supported by Iconv library only.}
  IconvOnlyChars: set of TMimeChar = [UTF_16, UTF_16LE, UTF_32, UTF_32LE,
    C99, JAVA, ISO_8859_16, KOI8_U, KOI8_RU, CP862, CP866, MAC, MACCE, MACICE,
    MACCRO, MACRO, MACCYR, MACUK, MACGR, MACTU, MACHEB, MACAR, MACTH, ROMAN8,
    NEXTSTEP, ARMASCII, GEORGIAN_AC, GEORGIAN_PS, KOI8_T, MULELAO, CP1133,
    TIS620, CP874, VISCII, TCVN, ISO_IR_14, JIS_X0201, JIS_X0208, JIS_X0212,
    GB1988_80, GB2312_80, ISO_IR_165, ISO_IR_149, EUC_JP, SHIFT_JIS, CP932,
    ISO_2022_JP, ISO_2022_JP1, ISO_2022_JP2, GB2312, CP936, GB18030,
    ISO_2022_CN, ISO_2022_CNE, HZ, EUC_TW, BIG5, CP950, BIG5_HKSCS, EUC_KR,
    CP949, CP1361, ISO_2022_KR, CP737, CP775, CP853, CP855, CP857, CP858,
    CP860, CP861, CP863, CP864, CP865, CP869, CP1125];

  {:Set of charsets supported by internal routines only.}
  NoIconvChars: set of TMimeChar = [CP895, UTF_7mod];

  {:null character replace table. (Usable for disable charater replacing.)}
  Replace_None: array[0..0] of word =
    (0);

  {:Character replace table for remove Czech diakritics.}
  Replace_Czech: array[0..59] of word =
    (
      $00E1, $0061,
      $010D, $0063,
      $010F, $0064,
      $010E, $0044,
      $00E9, $0065,
      $011B, $0065,
      $00ED, $0069,
      $0148, $006E,
      $00F3, $006F,
      $0159, $0072,
      $0161, $0073,
      $0165, $0074,
      $00fa, $0075,
      $016F, $0075,
      $00FD, $0079,
      $017E, $007A,
      $00C1, $0041,
      $010C, $0043,
      $00C9, $0045,
      $011A, $0045,
      $00CD, $0049,
      $0147, $004E,
      $00D3, $004F,
      $0158, $0052,
      $0160, $0053,
      $0164, $0054,
      $00da, $0055,
      $016E, $0055,
      $00DD, $0059,
      $017D, $005A
    );

VAR
  {:By this you can generally disable/enable Iconv support.}
  DisableIconv: boolean = false;

  {:Default set of charsets for @link(IdealCharsetCoding) function.}
  IdealCharsets: TMimeSetChar =
    [ISO_8859_1, ISO_8859_2, ISO_8859_3, ISO_8859_4, ISO_8859_5,
    ISO_8859_6, ISO_8859_7, ISO_8859_8, ISO_8859_9, ISO_8859_10,
    KOI8_R, KOI8_U
    {$IFNDEF CIL} //error URW778 ??? :-O
    , GB2312, EUC_KR, ISO_2022_JP, EUC_TW
    {$ENDIF}
    ];

{==============================================================================}
{:Convert Value from one charset to another. See: @link(CharsetConversionEx)}
FUNCTION CharsetConversion(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar): ansistring;

{:Convert Value from one charset to another with additional character conversion.
see: @link(Replace_None) and @link(Replace_Czech)}
FUNCTION CharsetConversionEx(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar; CONST TransformTable: array of word): ansistring;

{:Convert Value from one charset to another with additional character conversion.
 This funtion is similar to @link(CharsetConversionEx), but you can disable
 transliteration of unconvertible characters.}
FUNCTION CharsetConversionTrans(value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar; CONST TransformTable: array of word; Translit: boolean): ansistring;

{:Returns charset used by operating system.}
FUNCTION GetCurCP: TMimeChar;

{:Returns charset used by operating system as OEM charset. (in Windows DOS box,
 for example)}
FUNCTION GetCurOEMCP: TMimeChar;

{:Converting string with charset name to TMimeChar.}
FUNCTION GetCPFromID(value: ansistring): TMimeChar;

{:Converting TMimeChar to string with name of charset.}
FUNCTION GetIDFromCP(value: TMimeChar): ansistring;

{:return @true when value need to be converted. (It is not 7-bit ASCII)}
FUNCTION NeedCharsetConversion(CONST value: ansistring): boolean;

{:Finding best target charset from set of TMimeChars with minimal count of
 unconvertible characters.}
FUNCTION IdealCharsetCoding(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeSetChar): TMimeChar;

{:Return BOM (Byte Order Mark) for given unicode charset.}
FUNCTION GetBOM(value: TMimeChar): ansistring;

{:Convert binary string with unicode content to WideString.}
FUNCTION StringToWide(CONST value: ansistring): WideString;

{:Convert WideString to binary string with unicode content.}
FUNCTION WideToString(CONST value: WideString): ansistring;

{==============================================================================}
IMPLEMENTATION

//character transcoding tables X to UCS-2
{
//dummy table
$0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
$0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
$0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
$0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
$00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
$00A8, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
$00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
$00B8, $00B9, $00BA, $00BB, $00BC, $00BD, $00BE, $00BF,
$00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
$00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
$00D0, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
$00D8, $00D9, $00da, $00DB, $00dc, $00DD, $00DE, $00DF,
$00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
$00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
$00F0, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
$00F8, $00F9, $00fa, $00fb, $00FC, $00FD, $00FE, $00ff
}

CONST

{Latin-1
  Danish, Dutch, English, Faeroese, Finnish, French, German, Icelandic,
  Irish, Italian, Norwegian, Portuguese, Spanish and Swedish.
}
  CharISO_8859_1: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00BA, $00BB, $00BC, $00BD, $00BE, $00BF,
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $00D0, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $00DD, $00DE, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $00F0, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $00FD, $00FE, $00ff
    );

{Latin-2
  Albanian, Czech, English, German, Hungarian, polish, Rumanian,
  Serbo-Croatian, Slovak, Slovene and Swedish.
}
  CharISO_8859_2: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0104, $02D8, $0141, $00A4, $013D, $015A, $00A7,
    $00A8, $0160, $015E, $0164, $0179, $00ad, $017D, $017B,
    $00B0, $0105, $02DB, $0142, $00B4, $013E, $015B, $02C7,
    $00B8, $0161, $015F, $0165, $017A, $02DD, $017E, $017C,
    $0154, $00C1, $00C2, $0102, $00C4, $0139, $0106, $00C7,
    $010C, $00C9, $0118, $00CB, $011A, $00CD, $00CE, $010E,
    $0110, $0143, $0147, $00D3, $00D4, $0150, $00D6, $00D7,
    $0158, $016E, $00da, $0170, $00dc, $00DD, $0162, $00DF,
    $0155, $00E1, $00E2, $0103, $00E4, $013A, $0107, $00E7,
    $010D, $00E9, $0119, $00EB, $011B, $00ED, $00EE, $010F,
    $0111, $0144, $0148, $00F3, $00F4, $0151, $00F6, $00F7,
    $0159, $016F, $00fa, $0171, $00FC, $00FD, $0163, $02D9
    );

{Latin-3
  Afrikaans, Catalan, English, Esperanto, French, Galician,
  German, Italian, Maltese and Turkish.
}
  CharISO_8859_3: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0126, $02D8, $00A3, $00A4, $FFFD, $0124, $00A7,
    $00A8, $0130, $015E, $011E, $0134, $00ad, $FFFD, $017B,
    $00B0, $0127, $00B2, $00B3, $00B4, $00B5, $0125, $00B7,
    $00B8, $0131, $015F, $011F, $0135, $00BD, $FFFD, $017C,
    $00C0, $00C1, $00C2, $FFFD, $00C4, $010A, $0108, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $FFFD, $00D1, $00D2, $00D3, $00D4, $0120, $00D6, $00D7,
    $011C, $00D9, $00da, $00DB, $00dc, $016C, $015C, $00DF,
    $00E0, $00E1, $00E2, $FFFD, $00E4, $010B, $0109, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $FFFD, $00F1, $00F2, $00F3, $00F4, $0121, $00F6, $00F7,
    $011D, $00F9, $00fa, $00fb, $00FC, $016D, $015D, $02D9
    );

{Latin-4
  Danish, English, Estonian, Finnish, German, Greenlandic,
  Lappish, Latvian, Lithuanian, Norwegian and Swedish.
}
  CharISO_8859_4: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0104, $0138, $0156, $00A4, $0128, $013B, $00A7,
    $00A8, $0160, $0112, $0122, $0166, $00ad, $017D, $00AF,
    $00B0, $0105, $02DB, $0157, $00B4, $0129, $013C, $02C7,
    $00B8, $0161, $0113, $0123, $0167, $014A, $017E, $014B,
    $0100, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $012E,
    $010C, $00C9, $0118, $00CB, $0116, $00CD, $00CE, $012A,
    $0110, $0145, $014C, $0136, $00D4, $00D5, $00D6, $00D7,
    $00D8, $0172, $00da, $00DB, $00dc, $0168, $016A, $00DF,
    $0101, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $012F,
    $010D, $00E9, $0119, $00EB, $0117, $00ED, $00EE, $012B,
    $0111, $0146, $014D, $0137, $00F4, $00F5, $00F6, $00F7,
    $00F8, $0173, $00fa, $00fb, $00FC, $0169, $016B, $02D9
    );

{CYRILLIC
  Bulgarian, Bielorussian, English, Macedonian, Russian,
  Serbo-Croatian and Ukrainian.
}
  CharISO_8859_5: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0401, $0402, $0403, $0404, $0405, $0406, $0407,
    $0408, $0409, $040A, $040B, $040C, $00ad, $040E, $040F,
    $0410, $0411, $0412, $0413, $0414, $0415, $0416, $0417,
    $0418, $0419, $041A, $041B, $041C, $041D, $041E, $041F,
    $0420, $0421, $0422, $0423, $0424, $0425, $0426, $0427,
    $0428, $0429, $042A, $042B, $042C, $042D, $042E, $042F,
    $0430, $0431, $0432, $0433, $0434, $0435, $0436, $0437,
    $0438, $0439, $043A, $043B, $043C, $043D, $043E, $043F,
    $0440, $0441, $0442, $0443, $0444, $0445, $0446, $0447,
    $0448, $0449, $044A, $044B, $044C, $044D, $044E, $044F,
    $2116, $0451, $0452, $0453, $0454, $0455, $0456, $0457,
    $0458, $0459, $045A, $045B, $045C, $00A7, $045E, $045F
    );

{ARABIC
}
  CharISO_8859_6: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $FFFD, $FFFD, $FFFD, $00A4, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $060C, $00ad, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $061B, $FFFD, $FFFD, $FFFD, $061F,
    $FFFD, $0621, $0622, $0623, $0624, $0625, $0626, $0627,
    $0628, $0629, $062A, $062B, $062C, $062D, $062E, $062F,
    $0630, $0631, $0632, $0633, $0634, $0635, $0636, $0637,
    $0638, $0639, $063A, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $0640, $0641, $0642, $0643, $0644, $0645, $0646, $0647,
    $0648, $0649, $064A, $064B, $064C, $064D, $064E, $064F,
    $0650, $0651, $0652, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD
    );

{GREEK
}
  CharISO_8859_7: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $2018, $2019, $00A3, $FFFD, $FFFD, $00A6, $00A7,
    $00A8, $00A9, $FFFD, $00AB, $00AC, $00ad, $FFFD, $2015,
    $00B0, $00B1, $00B2, $00B3, $0384, $0385, $0386, $00B7,
    $0388, $0389, $038A, $00BB, $038C, $00BD, $038E, $038F,
    $0390, $0391, $0392, $0393, $0394, $0395, $0396, $0397,
    $0398, $0399, $039A, $039B, $039C, $039D, $039E, $039F,
    $03A0, $03A1, $FFFD, $03A3, $03A4, $03A5, $03A6, $03A7,
    $03A8, $03A9, $03AA, $03AB, $03AC, $03ad, $03AE, $03AF,
    $03B0, $03B1, $03B2, $03B3, $03B4, $03B5, $03B6, $03B7,
    $03B8, $03B9, $03BA, $03BB, $03BC, $03BD, $03BE, $03BF,
    $03C0, $03C1, $03C2, $03C3, $03C4, $03C5, $03C6, $03C7,
    $03C8, $03C9, $03ca, $03CB, $03CC, $03CD, $03CE, $FFFD
    );

{HEBREW
}
  CharISO_8859_8: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $FFFD, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00D7, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00F7, $00BB, $00BC, $00BD, $00BE, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $2017,
    $05D0, $05D1, $05D2, $05D3, $05D4, $05D5, $05D6, $05D7,
    $05D8, $05D9, $05da, $05DB, $05dc, $05DD, $05DE, $05DF,
    $05E0, $05E1, $05E2, $05E3, $05E4, $05E5, $05E6, $05E7,
    $05E8, $05E9, $05EA, $FFFD, $FFFD, $200E, $200F, $FFFD
    );

{Latin-5
  English, Finnish, French, German, Irish, Italian, Norwegian,
  Portuguese, Spanish, Swedish and Turkish.
}
  CharISO_8859_9: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0104, $02D8, $0141, $00A4, $013D, $015A, $00A7,
    $00A8, $0160, $015E, $0164, $0179, $00ad, $017D, $017B,
    $00B0, $0105, $02DB, $0142, $00B4, $013E, $015B, $02C7,
    $00B8, $0161, $015F, $0165, $017A, $02DD, $017E, $017C,
    $0154, $00C1, $00C2, $0102, $00C4, $0139, $0106, $00C7,
    $010C, $00C9, $0118, $00CB, $011A, $00CD, $00CE, $010E,
    $011E, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $0130, $015E, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $011F, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $0131, $015F, $00ff
    );

{Latin-6
  Danish, English, Estonian, Faeroese, Finnish, German, Greenlandic,
  Icelandic, Lappish, Latvian, Lithuanian, Norwegian and Swedish.
}
  CharISO_8859_10: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $0104, $0112, $0122, $012A, $0128, $0136, $00A7,
    $013B, $0110, $0160, $0166, $017D, $00ad, $016A, $014A,
    $00B0, $0105, $0113, $0123, $012B, $0129, $0137, $00B7,
    $013C, $0111, $0161, $0167, $017E, $2015, $016B, $014B,
    $0100, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $012E,
    $010C, $00C9, $0118, $00CB, $0116, $00CD, $00CE, $00CF,
    $00D0, $0145, $014C, $00D3, $00D4, $00D5, $00D6, $0168,
    $00D8, $0172, $00da, $00DB, $00dc, $00DD, $00DE, $00DF,
    $0101, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $012F,
    $010D, $00E9, $0119, $00EB, $0117, $00ED, $00EE, $00EF,
    $00F0, $0146, $014D, $00F3, $00F4, $00F5, $00F6, $0169,
    $00F8, $0173, $00fa, $00fb, $00FC, $00FD, $00FE, $0138
    );

  CharISO_8859_13: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $201D, $00A2, $00A3, $00A4, $201E, $00A6, $00A7,
    $00D8, $00A9, $0156, $00AB, $00AC, $00ad, $00AE, $00C6,
    $00B0, $00B1, $00B2, $00B3, $201C, $00B5, $00B6, $00B7,
    $00F8, $00B9, $0157, $00BB, $00BC, $00BD, $00BE, $00E6,
    $0104, $012E, $0100, $0106, $00C4, $00C5, $0118, $0112,
    $010C, $00C9, $0179, $0116, $0122, $0136, $012A, $013B,
    $0160, $0143, $0145, $00D3, $014C, $00D5, $00D6, $00D7,
    $0172, $0141, $015A, $016A, $00dc, $017B, $017D, $00DF,
    $0105, $012F, $0101, $0107, $00E4, $00E5, $0119, $0113,
    $010D, $00E9, $017A, $0117, $0123, $0137, $012B, $013C,
    $0161, $0144, $0146, $00F3, $014D, $00F5, $00F6, $00F7,
    $0173, $0142, $015B, $016B, $00FC, $017C, $017E, $2019
    );

  CharISO_8859_14: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $1E02, $1E03, $00A3, $010A, $010B, $1E0A, $00A7,
    $1E80, $00A9, $1E82, $1E0B, $1EF2, $00ad, $00AE, $0178,
    $1E1E, $1E1F, $0120, $0121, $1E40, $1E41, $00B6, $1E56,
    $1E81, $1E57, $1E83, $1E60, $1EF3, $1E84, $1E85, $1E61,
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $0174, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $1E6A,
    $00D8, $00D9, $00da, $00DB, $00dc, $00DD, $0176, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $0175, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $1E6B,
    $00F8, $00F9, $00fa, $00fb, $00FC, $00FD, $0177, $00ff
    );

  CharISO_8859_15: array[128..255] of word =
  (
    $0080, $0081, $0082, $0083, $0084, $0085, $0086, $0087,
    $0088, $0089, $008A, $008B, $008C, $008D, $008E, $008F,
    $0090, $0091, $0092, $0093, $0094, $0095, $0096, $0097,
    $0098, $0099, $009A, $009B, $009C, $009D, $009E, $009F,
    $00A0, $00A1, $00A2, $00A3, $20AC, $00A5, $0160, $00A7,
    $0161, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $017D, $00B5, $00B6, $00B7,
    $017E, $00B9, $00BA, $00BB, $0152, $0153, $0178, $00BF,
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $00D0, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $00DD, $00DE, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $00F0, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $00FD, $00FE, $00ff
    );

{Eastern European
}
  CharCP_1250: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $FFFD, $201E, $2026, $2020, $2021,
    $FFFD, $2030, $0160, $2039, $015A, $0164, $017D, $0179,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $FFFD, $2122, $0161, $203A, $015B, $0165, $017E, $017A,
    $00A0, $02C7, $02D8, $0141, $00A4, $0104, $00A6, $00A7,
    $00A8, $00A9, $015E, $00AB, $00AC, $00ad, $00AE, $017B,
    $00B0, $00B1, $02DB, $0142, $00B4, $00B5, $00B6, $00B7,
    $00B8, $0105, $015F, $00BB, $013D, $02DD, $013E, $017C,
    $0154, $00C1, $00C2, $0102, $00C4, $0139, $0106, $00C7,
    $010C, $00C9, $0118, $00CB, $011A, $00CD, $00CE, $010E,
    $0110, $0143, $0147, $00D3, $00D4, $0150, $00D6, $00D7,
    $0158, $016E, $00da, $0170, $00dc, $00DD, $0162, $00DF,
    $0155, $00E1, $00E2, $0103, $00E4, $013A, $0107, $00E7,
    $010D, $00E9, $0119, $00EB, $011B, $00ED, $00EE, $010F,
    $0111, $0144, $0148, $00F3, $00F4, $0151, $00F6, $00F7,
    $0159, $016F, $00fa, $0171, $00FC, $00FD, $0163, $02D9
    );

{Cyrillic
}
  CharCP_1251: array[128..255] of word =
  (
    $0402, $0403, $201A, $0453, $201E, $2026, $2020, $2021,
    $20AC, $2030, $0409, $2039, $040A, $040C, $040B, $040F,
    $0452, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $FFFD, $2122, $0459, $203A, $045A, $045C, $045B, $045F,
    $00A0, $040E, $045E, $0408, $00A4, $0490, $00A6, $00A7,
    $0401, $00A9, $0404, $00AB, $00AC, $00ad, $00AE, $0407,
    $00B0, $00B1, $0406, $0456, $0491, $00B5, $00B6, $00B7,
    $0451, $2116, $0454, $00BB, $0458, $0405, $0455, $0457,
    $0410, $0411, $0412, $0413, $0414, $0415, $0416, $0417,
    $0418, $0419, $041A, $041B, $041C, $041D, $041E, $041F,
    $0420, $0421, $0422, $0423, $0424, $0425, $0426, $0427,
    $0428, $0429, $042A, $042B, $042C, $042D, $042E, $042F,
    $0430, $0431, $0432, $0433, $0434, $0435, $0436, $0437,
    $0438, $0439, $043A, $043B, $043C, $043D, $043E, $043F,
    $0440, $0441, $0442, $0443, $0444, $0445, $0446, $0447,
    $0448, $0449, $044A, $044B, $044C, $044D, $044E, $044F
    );

{Latin-1 (US, Western Europe)
}
  CharCP_1252: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $0192, $201E, $2026, $2020, $2021,
    $02C6, $2030, $0160, $2039, $0152, $FFFD, $017D, $FFFD,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $02dc, $2122, $0161, $203A, $0153, $FFFD, $017E, $0178,
    $00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00BA, $00BB, $00BC, $00BD, $00BE, $00BF,
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $00D0, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $00DD, $00DE, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $00F0, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $00FD, $00FE, $00ff
    );

{Greek
}
  CharCP_1253: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $0192, $201E, $2026, $2020, $2021,
    $FFFD, $2030, $FFFD, $2039, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $FFFD, $2122, $FFFD, $203A, $FFFD, $FFFD, $FFFD, $FFFD,
    $00A0, $0385, $0386, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $FFFD, $00AB, $00AC, $00ad, $00AE, $2015,
    $00B0, $00B1, $00B2, $00B3, $0384, $00B5, $00B6, $00B7,
    $0388, $0389, $038A, $00BB, $038C, $00BD, $038E, $038F,
    $0390, $0391, $0392, $0393, $0394, $0395, $0396, $0397,
    $0398, $0399, $039A, $039B, $039C, $039D, $039E, $039F,
    $03A0, $03A1, $FFFD, $03A3, $03A4, $03A5, $03A6, $03A7,
    $03A8, $03A9, $03AA, $03AB, $03AC, $03ad, $03AE, $03AF,
    $03B0, $03B1, $03B2, $03B3, $03B4, $03B5, $03B6, $03B7,
    $03B8, $03B9, $03BA, $03BB, $03BC, $03BD, $03BE, $03BF,
    $03C0, $03C1, $03C2, $03C3, $03C4, $03C5, $03C6, $03C7,
    $03C8, $03C9, $03ca, $03CB, $03CC, $03CD, $03CE, $FFFD
    );

{Turkish
}
  CharCP_1254: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $0192, $201E, $2026, $2020, $2021,
    $02C6, $2030, $0160, $2039, $0152, $FFFD, $FFFD, $FFFD,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $02dc, $2122, $0161, $203A, $0153, $FFFD, $FFFD, $0178,
    $00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00BA, $00BB, $00BC, $00BD, $00BE, $00BF,
    $00C0, $00C1, $00C2, $00C3, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $00CC, $00CD, $00CE, $00CF,
    $011E, $00D1, $00D2, $00D3, $00D4, $00D5, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $0130, $015E, $00DF,
    $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $00EC, $00ED, $00EE, $00EF,
    $011F, $00F1, $00F2, $00F3, $00F4, $00F5, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $0131, $015F, $00ff
    );

{Hebrew
}
  CharCP_1255: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $0192, $201E, $2026, $2020, $2021,
    $02C6, $2030, $FFFD, $2039, $FFFD, $FFFD, $FFFD, $FFFD,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $02dc, $2122, $FFFD, $203A, $FFFD, $FFFD, $FFFD, $FFFD,
    $00A0, $00A1, $00A2, $00A3, $20AA, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00D7, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00F7, $00BB, $00BC, $00BD, $00BE, $00BF,
    $05B0, $05B1, $05B2, $05B3, $05B4, $05B5, $05B6, $05B7,
    $05B8, $05B9, $FFFD, $05BB, $05BC, $05BD, $05BE, $05BF,
    $05C0, $05C1, $05C2, $05C3, $05F0, $05F1, $05F2, $05F3,
    $05F4, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD,
    $05D0, $05D1, $05D2, $05D3, $05D4, $05D5, $05D6, $05D7,
    $05D8, $05D9, $05da, $05DB, $05dc, $05DD, $05DE, $05DF,
    $05E0, $05E1, $05E2, $05E3, $05E4, $05E5, $05E6, $05E7,
    $05E8, $05E9, $05EA, $FFFD, $FFFD, $200E, $200F, $FFFD
    );

{Arabic
}
  CharCP_1256: array[128..255] of word =
  (
    $20AC, $067E, $201A, $0192, $201E, $2026, $2020, $2021,
    $02C6, $2030, $0679, $2039, $0152, $0686, $0698, $0688,
    $06AF, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $06A9, $2122, $0691, $203A, $0153, $200C, $200D, $06BA,
    $00A0, $060C, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $06BE, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $061B, $00BB, $00BC, $00BD, $00BE, $061F,
    $06C1, $0621, $0622, $0623, $0624, $0625, $0626, $0627,
    $0628, $0629, $062A, $062B, $062C, $062D, $062E, $062F,
    $0630, $0631, $0632, $0633, $0634, $0635, $0636, $00D7,
    $0637, $0638, $0639, $063A, $0640, $0641, $0642, $0643,
    $00E0, $0644, $00E2, $0645, $0646, $0647, $0648, $00E7,
    $00E8, $00E9, $00EA, $00EB, $0649, $064A, $00EE, $00EF,
    $064B, $064C, $064D, $064E, $00F4, $064F, $0650, $00F7,
    $0651, $00F9, $0652, $00fb, $00FC, $200E, $200F, $06D2
    );

{Baltic
}
  CharCP_1257: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $FFFD, $201E, $2026, $2020, $2021,
    $FFFD, $2030, $FFFD, $2039, $FFFD, $00A8, $02C7, $00B8,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $FFFD, $2122, $FFFD, $203A, $FFFD, $00AF, $02DB, $FFFD,
    $00A0, $FFFD, $00A2, $00A3, $00A4, $FFFD, $00A6, $00A7,
    $00D8, $00A9, $0156, $00AB, $00AC, $00ad, $00AE, $00C6,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00F8, $00B9, $0157, $00BB, $00BC, $00BD, $00BE, $00E6,
    $0104, $012E, $0100, $0106, $00C4, $00C5, $0118, $0112,
    $010C, $00C9, $0179, $0116, $0122, $0136, $012A, $013B,
    $0160, $0143, $0145, $00D3, $014C, $00D5, $00D6, $00D7,
    $0172, $0141, $015A, $016A, $00dc, $017B, $017D, $00DF,
    $0105, $012F, $0101, $0107, $00E4, $00E5, $0119, $0113,
    $010D, $00E9, $017A, $0117, $0123, $0137, $012B, $013C,
    $0161, $0144, $0146, $00F3, $014D, $00F5, $00F6, $00F7,
    $0173, $0142, $015B, $016B, $00FC, $017C, $017E, $02D9
    );

{Vietnamese
}
  CharCP_1258: array[128..255] of word =
  (
    $20AC, $FFFD, $201A, $0192, $201E, $2026, $2020, $2021,
    $02C6, $2030, $FFFD, $2039, $0152, $FFFD, $FFFD, $FFFD,
    $FFFD, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $02dc, $2122, $FFFD, $203A, $0153, $FFFD, $FFFD, $0178,
    $00A0, $00A1, $00A2, $00A3, $00A4, $00A5, $00A6, $00A7,
    $00A8, $00A9, $00AA, $00AB, $00AC, $00ad, $00AE, $00AF,
    $00B0, $00B1, $00B2, $00B3, $00B4, $00B5, $00B6, $00B7,
    $00B8, $00B9, $00BA, $00BB, $00BC, $00BD, $00BE, $00BF,
    $00C0, $00C1, $00C2, $0102, $00C4, $00C5, $00C6, $00C7,
    $00C8, $00C9, $00ca, $00CB, $0300, $00CD, $00CE, $00CF,
    $0110, $00D1, $0309, $00D3, $00D4, $01A0, $00D6, $00D7,
    $00D8, $00D9, $00da, $00DB, $00dc, $01AF, $0303, $00DF,
    $00E0, $00E1, $00E2, $0103, $00E4, $00E5, $00E6, $00E7,
    $00E8, $00E9, $00EA, $00EB, $0301, $00ED, $00EE, $00EF,
    $0111, $00F1, $0323, $00F3, $00F4, $01A1, $00F6, $00F7,
    $00F8, $00F9, $00fa, $00fb, $00FC, $01B0, $20AB, $00ff
    );

{Cyrillic
}
  CharKOI8_R: array[128..255] of word =
  (
    $2500, $2502, $250C, $2510, $2514, $2518, $251C, $2524,
    $252C, $2534, $253C, $2580, $2584, $2588, $258C, $2590,
    $2591, $2592, $2593, $2320, $25A0, $2219, $221A, $2248,
    $2264, $2265, $00A0, $2321, $00B0, $00B2, $00B7, $00F7,
    $2550, $2551, $2552, $0451, $2553, $2554, $2555, $2556,
    $2557, $2558, $2559, $255A, $255B, $255C, $255D, $255E,
    $255F, $2560, $2561, $0401, $2562, $2563, $2564, $2565,
    $2566, $2567, $2568, $2569, $256A, $256B, $256C, $00A9,
    $044E, $0430, $0431, $0446, $0434, $0435, $0444, $0433,
    $0445, $0438, $0439, $043A, $043B, $043C, $043D, $043E,
    $043F, $044F, $0440, $0441, $0442, $0443, $0436, $0432,
    $044C, $044B, $0437, $0448, $044D, $0449, $0447, $044A,
    $042E, $0410, $0411, $0426, $0414, $0415, $0424, $0413,
    $0425, $0418, $0419, $041A, $041B, $041C, $041D, $041E,
    $041F, $042F, $0420, $0421, $0422, $0423, $0416, $0412,
    $042C, $042B, $0417, $0428, $042D, $0429, $0427, $042A
    );

{Czech (Kamenicky)
}
  CharCP_895: array[128..255] of word =
  (
    $010C, $00FC, $00E9, $010F, $00E4, $010E, $0164, $010D,
    $011B, $011A, $0139, $00CD, $013E, $013A, $00C4, $00C1,
    $00C9, $017E, $017D, $00F4, $00F6, $00D3, $016F, $00da,
    $00FD, $00D6, $00dc, $0160, $013D, $00DD, $0158, $0165,
    $00E1, $00ED, $00F3, $00fa, $0148, $0147, $016E, $00D4,
    $0161, $0159, $0155, $0154, $00BC, $00A7, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556,
    $2555, $2563, $2551, $2557, $255D, $255C, $255B, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567,
    $2568, $2564, $2565, $2559, $2558, $2552, $2553, $256B,
    $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
    $03B1, $03B2, $0393, $03C0, $03A3, $03C3, $03BC, $03C4,
    $03A6, $0398, $03A9, $03B4, $221E, $2205, $03B5, $2229,
    $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248,
    $2218, $00B7, $2219, $221A, $207F, $00B2, $25A0, $00A0
    );

{Eastern European
}
  CharCP_852: array[128..255] of word =
  (
    $00C7, $00FC, $00E9, $00E2, $00E4, $016F, $0107, $00E7,
    $0142, $00EB, $0150, $0151, $00EE, $0179, $00C4, $0106,
    $00C9, $0139, $013A, $00F4, $00F6, $013D, $013E, $015A,
    $015B, $00D6, $00dc, $0164, $0165, $0141, $00D7, $010D,
    $00E1, $00ED, $00F3, $00fa, $0104, $0105, $017D, $017E,
    $0118, $0119, $00AC, $017A, $010C, $015F, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $00C1, $00C2, $011A,
    $015E, $2563, $2551, $2557, $255D, $017B, $017C, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $0102, $0103,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $00A4,
    $0111, $0110, $010E, $00CB, $010F, $0147, $00CD, $00CE,
    $011B, $2518, $250C, $2588, $2584, $0162, $016E, $2580,
    $00D3, $00DF, $00D4, $0143, $0144, $0148, $0160, $0161,
    $0154, $00da, $0155, $0170, $00FD, $00DD, $0163, $00B4,
    $00ad, $02DD, $02DB, $02C7, $02D8, $00A7, $00F7, $00B8,
    $00B0, $00A8, $02D9, $0171, $0158, $0159, $25A0, $00A0
    );

{==============================================================================}
TYPE
  TIconvChar = record
    charSet: TMimeChar;
    CharName: string;
  end;
  TIconvArr = array [0..112] of TIconvChar;

CONST
  NotFoundChar = '_';

VAR
  SetTwo: set of TMimeChar = [UCS_2, UCS_2LE, UTF_7, UTF_7mod];
  SetFour: set of TMimeChar = [UCS_4, UCS_4LE, UTF_8];
  SetLE: set of TMimeChar = [UCS_2LE, UCS_4LE];

  IconvArr: TIconvArr;

{==============================================================================}
FUNCTION FindIconvID(CONST value, Charname: string): boolean;
VAR
  s: string;
begin
  result := true;
  //exact match
  if value = Charname then
    exit;
  //Value is on begin of charname
  s := value + ' ';
  if s = copy(Charname, 1, length(s)) then
    exit;
  //Value is on end of charname
  s := ' ' + value;
  if s = copy(Charname, length(Charname) - length(s) + 1, length(s)) then
    exit;
  //value is somewhere inside charname
  if pos( s + ' ', Charname) > 0 then
    exit;
  result := false;
end;

FUNCTION GetCPFromIconvID(value: ansistring): TMimeChar;
VAR
  n: integer;
begin
  result := ISO_8859_1;
  value := uppercase(value);
  for n := 0 to high(IconvArr) do
    if FindIconvID(value, IconvArr[n].Charname) then
    begin
      result := IconvArr[n].charSet;
      break;
    end;
end;

{==============================================================================}
FUNCTION GetIconvIDFromCP(value: TMimeChar): ansistring;
VAR
  n: integer;
begin
  result := 'ISO-8859-1';
  for n := 0 to high(IconvArr) do
    if IconvArr[n].charSet = value then
    begin
      result := Separateleft(IconvArr[n].Charname, ' ');
      break;
    end;
end;

{==============================================================================}
FUNCTION ReplaceUnicode(value: word; CONST TransformTable: array of word): word;
VAR
  n: integer;
begin
  if high(TransformTable) <> 0 then
    for n := 0 to high(TransformTable) do
      if not odd(n) then
        if TransformTable[n] = value then
          begin
            value := TransformTable[n+1];
            break;
          end;
  result := value;
end;

{==============================================================================}
PROCEDURE CopyArray(CONST SourceTable: array of word;
  VAR TargetTable: array of word);
VAR
  n: integer;
begin
  for n := 0 to 127 do
    TargetTable[n] := SourceTable[n];
end;

{==============================================================================}
PROCEDURE GetArray(charSet: TMimeChar; VAR result: array of word);
begin
  case charSet of
    ISO_8859_2:
      CopyArray(CharISO_8859_2, result);
    ISO_8859_3:
      CopyArray(CharISO_8859_3, result);
    ISO_8859_4:
      CopyArray(CharISO_8859_4, result);
    ISO_8859_5:
      CopyArray(CharISO_8859_5, result);
    ISO_8859_6:
      CopyArray(CharISO_8859_6, result);
    ISO_8859_7:
      CopyArray(CharISO_8859_7, result);
    ISO_8859_8:
      CopyArray(CharISO_8859_8, result);
    ISO_8859_9:
      CopyArray(CharISO_8859_9, result);
    ISO_8859_10:
      CopyArray(CharISO_8859_10, result);
    ISO_8859_13:
      CopyArray(CharISO_8859_13, result);
    ISO_8859_14:
      CopyArray(CharISO_8859_14, result);
    ISO_8859_15:
      CopyArray(CharISO_8859_15, result);
    CP1250:
      CopyArray(CharCP_1250, result);
    CP1251:
      CopyArray(CharCP_1251, result);
    CP1252:
      CopyArray(CharCP_1252, result);
    CP1253:
      CopyArray(CharCP_1253, result);
    CP1254:
      CopyArray(CharCP_1254, result);
    CP1255:
      CopyArray(CharCP_1255, result);
    CP1256:
      CopyArray(CharCP_1256, result);
    CP1257:
      CopyArray(CharCP_1257, result);
    CP1258:
      CopyArray(CharCP_1258, result);
    KOI8_R:
      CopyArray(CharKOI8_R, result);
    CP895:
      CopyArray(CharCP_895, result);
    CP852:
      CopyArray(CharCP_852, result);
  else
      CopyArray(CharISO_8859_1, result);
  end;
end;

{==============================================================================}
PROCEDURE ReadMulti(CONST value: ansistring; VAR index: integer; mb: byte;
  VAR b1, b2, b3, b4: byte; le: boolean);
begin
  b1 := 0;
  b2 := 0;
  b3 := 0;
  b4 := 0;
  if index < 0 then
    index := 1;
  if mb > 4 then
    mb := 1;
  if (index + mb - 1) <= length(value) then
  begin
    if le then
      case mb of
        1:
          b1 := ord(value[index]);
        2:
          begin
            b1 := ord(value[index]);
            b2 := ord(value[index + 1]);
          end;
        3:
          begin
            b1 := ord(value[index]);
            b2 := ord(value[index + 1]);
            b3 := ord(value[index + 2]);
          end;
        4:
          begin
            b1 := ord(value[index]);
            b2 := ord(value[index + 1]);
            b3 := ord(value[index + 2]);
            b4 := ord(value[index + 3]);
          end;
      end
    else
      case mb of
        1:
          b1 := ord(value[index]);
        2:
          begin
            b2 := ord(value[index]);
            b1 := ord(value[index + 1]);
          end;
        3:
          begin
            b3 := ord(value[index]);
            b2 := ord(value[index + 1]);
            b1 := ord(value[index + 2]);
          end;
        4:
          begin
            b4 := ord(value[index]);
            b3 := ord(value[index + 1]);
            b2 := ord(value[index + 2]);
            b1 := ord(value[index + 3]);
          end;
      end;
  end;
  inc(index, mb);
end;

{==============================================================================}
FUNCTION WriteMulti(b1, b2, b3, b4: byte; mb: byte; le: boolean): ansistring;
begin
  if mb > 4 then
    mb := 1;
  setLength(result, mb);
  if le then
    case mb of
      1:
        result[1] := AnsiChar(b1);
      2:
        begin
          result[1] := AnsiChar(b1);
          result[2] := AnsiChar(b2);
        end;
      3:
        begin
          result[1] := AnsiChar(b1);
          result[2] := AnsiChar(b2);
          result[3] := AnsiChar(b3);
        end;
      4:
        begin
          result[1] := AnsiChar(b1);
          result[2] := AnsiChar(b2);
          result[3] := AnsiChar(b3);
          result[4] := AnsiChar(b4);
        end;
    end
  else
    case mb of
      1:
        result[1] := AnsiChar(b1);
      2:
        begin
          result[2] := AnsiChar(b1);
          result[1] := AnsiChar(b2);
        end;
      3:
        begin
          result[3] := AnsiChar(b1);
          result[2] := AnsiChar(b2);
          result[1] := AnsiChar(b3);
        end;
      4:
        begin
          result[4] := AnsiChar(b1);
          result[3] := AnsiChar(b2);
          result[2] := AnsiChar(b3);
          result[1] := AnsiChar(b4);
        end;
    end;
end;

{==============================================================================}
FUNCTION UTF8toUCS4(CONST value: ansistring): ansistring;
VAR
  n, x, ul, m: integer;
  s: ansistring;
  w1, w2: word;
begin
  result := '';
  n := 1;
  while length(value) >= n do
  begin
    x := ord(value[n]);
    inc(n);
    if x < 128 then
      result := result + WriteMulti(x, 0, 0, 0, 4, false)
    else
    begin
      m := 0;
      if (x and $E0) = $C0 then
        m := $1F;
      if (x and $F0) = $E0 then
        m := $0F;
      if (x and $F8) = $F0 then
        m := $07;
      if (x and $FC) = $F8 then
        m := $03;
      if (x and $FE) = $FC then
        m := $01;
      ul := x and m;
      s := IntToBin(ul, 0);
      while length(value) >= n do
      begin
        x := ord(value[n]);
        inc(n);
        if (x and $C0) = $80 then
          s := s + IntToBin(x and $3F, 6)
        else
        begin
          dec(n);
          break;
        end;
      end;
      ul := BinToInt(s);
      w1 := ul div 65536;
      w2 := ul mod 65536;
      result := result + WriteMulti(Lo(w2), hi(w2), Lo(w1), hi(w1), 4, false);
    end;
  end;
end;

{==============================================================================}
FUNCTION UCS4toUTF8(CONST value: ansistring): ansistring;
VAR
  s, l, k: ansistring;
  b1, b2, b3, b4: byte;
  n, m, x, y: integer;
  b: byte;
begin
  result := '';
  n := 1;
  while length(value) >= n do
  begin
    ReadMulti(value, n, 4, b1, b2, b3, b4, false);
    if (b2 = 0) and (b3 = 0) and (b4 = 0) and (b1 < 128) then
      result := result + AnsiChar(b1)
    else
    begin
      x := (b1 + 256 * b2) + (b3 + 256 * b4) * 65536;
      l := IntToBin(x, 0);
      y := length(l) div 6;
      s := '';
      for m := 1 to y do
      begin
        k := copy(l, length(l) - 5, 6);
        l := copy(l, 1, length(l) - 6);
        b := BinToInt(k) or $80;
        s := AnsiChar(b) + s;
      end;
      b := BinToInt(l);
      case y of
        5:
          b := b or $FC;
        4:
          b := b or $F8;
        3:
          b := b or $F0;
        2:
          b := b or $E0;
        1:
          b := b or $C0;
      end;
      s := AnsiChar(b) + s;
      result := result + s;
    end;
  end;
end;

{==============================================================================}
FUNCTION UTF7toUCS2(CONST value: ansistring; Modified: boolean): ansistring;
VAR
  n, i: integer;
  c: AnsiChar;
  s, t: ansistring;
  Shift: AnsiChar;
  table: string;
begin
  result := '';
  n := 1;
  if modified then
  begin
    Shift := '&';
    table := TableBase64mod;
  end
  else
  begin
    Shift := '+';
    table := TableBase64;
  end;
  while length(value) >= n do
  begin
    c := value[n];
    inc(n);
    if c <> Shift then
      result := result + WriteMulti(ord(c), 0, 0, 0, 2, false)
    else
    begin
      s := '';
      while length(value) >= n do
      begin
        c := value[n];
        inc(n);
        if c = '-' then
          break;
        if (c = '=') or (pos(c, table) < 1) then
        begin
          dec(n);
          break;
        end;
        s := s + c;
      end;
      if s = '' then
        s := WriteMulti(ord(Shift), 0, 0, 0, 2, false)
      else
      begin
        if modified then
          t := DecodeBase64mod(s)
        else
          t := DecodeBase64(s);
        if not odd(length(t)) then
          s := t
        else
        begin //ill-formed sequence
          t := s;
          s := WriteMulti(ord(Shift), 0, 0, 0, 2, false);
          for i := 1 to length(t) do
            s := s + WriteMulti(ord(t[i]), 0, 0, 0, 2, false);
        end;
      end;
      result := result + s;
    end;
  end;
end;

{==============================================================================}
FUNCTION UCS2toUTF7(CONST value: ansistring; Modified: boolean): ansistring;
VAR
  s: ansistring;
  b1, b2, b3, b4: byte;
  n, m: integer;
  Shift: AnsiChar;
begin
  result := '';
  n := 1;
  if modified then
    Shift := '&'
  else
    Shift := '+';
  while length(value) >= n do
  begin
    ReadMulti(value, n, 2, b1, b2, b3, b4, false);
    if (b2 = 0) and (b1 < 128) then
      if AnsiChar(b1) = Shift then
        result := result + Shift + '-'
      else
        result := result + AnsiChar(b1)
    else
    begin
      s := AnsiChar(b2) + AnsiChar(b1);
      while length(value) >= n do
      begin
        ReadMulti(value, n, 2, b1, b2, b3, b4, false);
        if (b2 = 0) and (b1 < 128) then
        begin
          dec(n, 2);
          break;
        end;
        s := s + AnsiChar(b2) + AnsiChar(b1);
      end;
      if modified then
        s := EncodeBase64mod(s)
      else
        s := EncodeBase64(s);
      m := pos('=', s);
      if m > 0 then
        s := copy(s, 1, m - 1);
      result := result + Shift + s + '-';
    end;
  end;
end;

{==============================================================================}
FUNCTION CharsetConversion(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar): ansistring;
begin
  result := CharsetConversionEx(value, CharFrom, CharTo, Replace_None);
end;

{==============================================================================}
FUNCTION CharsetConversionEx(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar; CONST TransformTable: array of word): ansistring;
begin
  result := CharsetConversionTrans(value, CharFrom, CharTo, TransformTable, true);
end;

{==============================================================================}

FUNCTION InternalToUcs(CONST value: ansistring; Charfrom: TMimeChar): ansistring;
VAR
  uni: word;
  n: integer;
  b1, b2, b3, b4: byte;
  SourceTable: array[128..255] of word;
  mbf: byte;
  lef: boolean;
  s: ansistring;
begin
  if CharFrom = UTF_8 then
    s := UTF8toUCS4(value)
  else
    if CharFrom = UTF_7 then
      s := UTF7toUCS2(value, false)
    else
      if CharFrom = UTF_7mod then
        s := UTF7toUCS2(value, true)
      else
        s := value;
  GetArray(CharFrom, SourceTable);
  mbf := 1;
  if CharFrom in SetTwo then
    mbf := 2;
  if CharFrom in SetFour then
    mbf := 4;
  lef := CharFrom in SetLe;
  result := '';
  n := 1;
  while length(s) >= n do
  begin
    ReadMulti(s, n, mbf, b1, b2, b3, b4, lef);
    //handle BOM
    if (b3 = 0) and (b4 = 0) then
    begin
      if (b1 = $FE) and (b2 = $ff) then
      begin
        lef := not lef;
        continue;
      end;
      if (b1 = $ff) and (b2 = $FE) then
        continue;
    end;
    if mbf = 1 then
      if b1 > 127 then
      begin
        uni := SourceTable[b1];
        b1 := Lo(uni);
        b2 := hi(uni);
      end;
    result := result + WriteMulti(b1, b2, b3, b4, 2, false);
  end;
end;

FUNCTION CharsetConversionTrans(value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeChar; CONST TransformTable: array of word; Translit: boolean): ansistring;
VAR
  uni: word;
  n, m: integer;
  b: byte;
  b1, b2, b3, b4: byte;
  TargetTable: array[128..255] of word;
  mbt: byte;
  let: boolean;
  ucsstring, s, t: ansistring;
  cd: iconv_t;
  f: boolean;
  NotNeedTransform: boolean;
  FromID, ToID: string;
begin
  NotNeedTransform := (high(TransformTable) = 0);
  if (CharFrom = CharTo) and NotNeedTransform then
  begin
    result := value;
    exit;
  end;
  FromID := GetIDFromCP(CharFrom);
  ToID := GetIDFromCP(CharTo);
  cd := Iconv_t(-1);
  //do two-pass conversion. Transform to UCS-2 first.
  if not DisableIconv then
    cd := SynaIconvOpenIgnore('UCS-2BE', FromID);
  try
    if cd <> iconv_t(-1) then
      SynaIconv(cd, value, ucsstring)
    else
      ucsstring := InternalToUcs(value, CharFrom);
  finally
    SynaIconvClose(cd);
  end;
  //here we allways have ucstring with UCS-2 encoding
  //second pass... from UCS-2 to target encoding.
    if not DisableIconv then
      if translit then
        cd := SynaIconvOpenTranslit(ToID, 'UCS-2BE')
      else
        cd := SynaIconvOpenIgnore(ToID, 'UCS-2BE');
  try
    if (cd <> iconv_t(-1)) and NotNeedTransform then
    begin
      if CharTo = UTF_7 then
        ucsstring := ucsstring + #0 + '-';
      //when transformtable is not needed and Iconv know target charset,
      //do it fast by one call.
      SynaIconv(cd, ucsstring, result);
      if CharTo = UTF_7 then
        Delete(result, length(result), 1);
    end
    else
    begin
      GetArray(CharTo, TargetTable);
      mbt := 1;
      if CharTo in SetTwo then
        mbt := 2;
      if CharTo in SetFour then
        mbt := 4;
      let := CharTo in SetLe;
      b3 := 0;
      b4 := 0;
      result := '';
      for n:= 0 to (length(ucsstring) div 2) - 1 do
      begin
        s := copy(ucsstring, n * 2 + 1, 2);
        b2 := ord(s[1]);
        b1 := ord(s[2]);
        uni := b2 * 256 + b1;
        if not NotNeedTransform then
        begin
          uni := ReplaceUnicode(uni, TransformTable);
          b1 := Lo(uni);
          b2 := hi(uni);
          s[1] := AnsiChar(b2);
          s[2] := AnsiChar(b1);
        end;
        if cd <> iconv_t(-1) then
        begin
          if CharTo = UTF_7 then
            s := s + #0 + '-';
          SynaIconv(cd, s, t);
          if CharTo = UTF_7 then
            Delete(t, length(t), 1);
          result := result + t;
        end
        else
        begin
          f := true;
          if mbt = 1 then
            if uni > 127 then
            begin
              f := false;
              b := 0;
              for m := 128 to 255 do
                if TargetTable[m] = uni then
                begin
                  b := m;
                  f := true;
                  break;
                end;
              b1 := b;
              b2 := 0;
            end
            else
              b1 := Lo(uni);
          if not f then
            if translit then
            begin
              b1 := ord(NotFoundChar);
              b2 := 0;
              f := true;
            end;
          if f then
            result := result + WriteMulti(b1, b2, b3, b4, mbt, let)
        end;
      end;
      if cd = iconv_t(-1) then
      begin
        if CharTo = UTF_7 then
          result := UCS2toUTF7(result, false);
        if CharTo = UTF_7mod then
          result := UCS2toUTF7(result, true);
        if CharTo = UTF_8 then
          result := UCS4toUTF8(result);
      end;
    end;
  finally
    SynaIconvClose(cd);
  end;
end;

{==============================================================================}
{$IFNDEF WIN32}

FUNCTION GetCurCP: TMimeChar;
begin
  {$IFNDEF FPC}
  result := GetCPFromID(nl_langinfo(_NL_CTYPE_CODESET_NAME));
  {$ELSE}
    {$IFDEF FPC_USE_LIBC}
  result := GetCPFromID(nl_langinfo(_NL_CTYPE_CODESET_NAME));
    {$ELSE}
  //How to get system codepage without LIBC?
  result := UTF_8;
    {$ENDIF}
  {$ENDIF}
end;

FUNCTION GetCurOEMCP: TMimeChar;
begin
  result := GetCurCP;
end;

{$ELSE}

FUNCTION CPToMimeChar(value: integer): TMimeChar;
begin
  case value of
    437, 850, 20127:
      result := ISO_8859_1; //I know, it is not ideal!
    737:
      result := CP737;
    775:
      result := CP775;
    852:
      result := CP852;
    855:
      result := CP855;
    857:
      result := CP857;
    858:
      result := CP858;
    860:
      result := CP860;
    861:
      result := CP861;
    862:
      result := CP862;
    863:
      result := CP863;
    864:
      result := CP864;
    865:
      result := CP865;
    866:
      result := CP866;
    869:
      result := CP869;
    874:
      result := ISO_8859_15;
    895:
      result := CP895;
    932:
      result := CP932;
    936:
      result := CP936;
    949:
      result := CP949;
    950:
      result := CP950;
    1200:
      result := UCS_2LE;
    1201:
      result := UCS_2;
    1250:
      result := CP1250;
    1251:
      result := CP1251;
    1253:
      result := CP1253;
    1254:
      result := CP1254;
    1255:
      result := CP1255;
    1256:
      result := CP1256;
    1257:
      result := CP1257;
    1258:
      result := CP1258;
    1361:
      result := CP1361;
    10000:
      result := MAC;
    10004:
      result := MACAR;
    10005:
      result := MACHEB;
    10006:
      result := MACGR;
    10007:
      result := MACCYR;
    10010:
      result := MACRO;
    10017:
      result := MACUK;
    10021:
      result := MACTH;
    10029:
      result := MACCE;
    10079:
      result := MACICE;
    10081:
      result := MACTU;
    10082:
      result := MACCRO;
    12000:
      result := UCS_4LE;
    12001:
      result := UCS_4;
    20866:
      result := KOI8_R;
    20932:
      result := JIS_X0208;
    20936:
      result := GB2312;
    21866:
      result := KOI8_U;
    28591:
      result := ISO_8859_1;
    28592:
      result := ISO_8859_2;
    28593:
      result := ISO_8859_3;
    28594:
      result := ISO_8859_4;
    28595:
      result := ISO_8859_5;
    28596, 708:
      result := ISO_8859_6;
    28597:
      result := ISO_8859_7;
    28598, 38598:
      result := ISO_8859_8;
    28599:
      result := ISO_8859_9;
    28605:
      result := ISO_8859_15;
    50220:
      result := ISO_2022_JP; //? ISO 2022 Japanese with no halfwidth Katakana
    50221:
      result := ISO_2022_JP1;//? Japanese with halfwidth Katakana
    50222:
      result := ISO_2022_JP2;//? Japanese JIS X 0201-1989
    50225:
      result := ISO_2022_KR;
    50227:
      result := ISO_2022_CN;//? ISO 2022 Simplified Chinese
    50229:
      result := ISO_2022_CNE;//? ISO 2022 Traditional Chinese
    51932:
      result := EUC_JP;
    51936:
      result := GB2312;
    51949:
      result := EUC_KR;
    52936:
      result := HZ;
    54936:
      result := GB18030;
    65000:
      result := UTF_7;
    65001:
      result := UTF_8;
    0:
      result := UCS_2LE;
  else
    result := CP1252;
  end;
end;

FUNCTION GetCurCP: TMimeChar;
begin
  result := CPToMimeChar(GetACP);
end;

FUNCTION GetCurOEMCP: TMimeChar;
begin
  result := CPToMimeChar(GetOEMCP);
end;
{$ENDIF}

{==============================================================================}
FUNCTION NeedCharsetConversion(CONST value: ansistring): boolean;
VAR
  n: integer;
begin
  result := false;
  for n := 1 to length(value) do
    if (ord(value[n]) > 127) or (ord(value[n]) = 0) then
    begin
      result := true;
      break;
    end;
end;

{==============================================================================}
FUNCTION IdealCharsetCoding(CONST value: ansistring; CharFrom: TMimeChar;
  CharTo: TMimeSetChar): TMimeChar;
VAR
  n: integer;
  max: integer;
  s, t, u: ansistring;
  charSet: TMimeChar;
begin
  result := ISO_8859_1;
  s := copy(value, 1, 1024);  //max first 1KB for next procedure
  max := 0;
  for n := ord(low(TMimeChar)) to ord(high(TMimeChar)) do
  begin
    charSet := TMimeChar(n);
    if charSet in CharTo then
    begin
      t := CharsetConversionTrans(s, CharFrom, charSet, Replace_None, false);
      u := CharsetConversionTrans(t, charSet, CharFrom, Replace_None, false);
      if s = u then
      begin
        result := charSet;
        exit;
      end;
      if length(u) > max then
      begin
        result := charSet;
        max := length(u);
      end;
    end;
  end;
end;

{==============================================================================}
FUNCTION GetBOM(value: TMimeChar): ansistring;
begin
  result := '';
  case value of
    UCS_2:
      result := #$fe + #$ff;
    UCS_4:
      result := #$00 + #$00 + #$fe + #$ff;
    UCS_2LE:
      result := #$ff + #$fe;
    UCS_4LE:
      result := #$ff + #$fe + #$00 + #$00;
    UTF_8:
      result := #$EF + #$bb + #$BF;
  end;
end;

{==============================================================================}
FUNCTION GetCPFromID(value: ansistring): TMimeChar;
begin
  value := uppercase(value);
  if (pos('KAMENICKY', value) > 0) or (pos('895', value) > 0) then
    result := CP895
  else
  if pos('MUTF-7', value) > 0 then
    result := UTF_7mod
  else
    result := GetCPFromIconvID(value);
end;

{==============================================================================}
FUNCTION GetIDFromCP(value: TMimeChar): ansistring;
begin
  case value of
    CP895:
      result := 'CP-895';
    UTF_7mod:
      result := 'mUTF-7';
  else
    result := GetIconvIDFromCP(value);
  end;
end;

{==============================================================================}
FUNCTION StringToWide(CONST value: ansistring): WideString;
VAR
  n: integer;
  x, y: integer;
begin
  setLength(result, length(value) div 2);
  for n := 1 to length(value) div 2 do
  begin
    x := ord(value[((n-1) * 2) + 1]);
    y := ord(value[((n-1) * 2) + 2]);
    result[n] := WideChar(x * 256 + y);
  end;
end;

{==============================================================================}
FUNCTION WideToString(CONST value: WideString): ansistring;
VAR
  n: integer;
  x: integer;
begin
  setLength(result, length(value) * 2);
  for n := 1 to length(value) do
  begin
    x := ord(value[n]);
    result[((n-1) * 2) + 1] := AnsiChar(x div 256);
    result[((n-1) * 2) + 2] := AnsiChar(x mod 256);
  end;
end;

{==============================================================================}
INITIALIZATION
begin
  IconvArr[0].charSet := ISO_8859_1;
  IconvArr[0].Charname := 'ISO-8859-1 CP819 IBM819 ISO-IR-100 ISO8859-1 ISO_8859-1 ISO_8859-1:1987 L1 LATIN1 CSISOLATIN1';
  IconvArr[1].charSet := UTF_8;
  IconvArr[1].Charname := 'UTF-8';
  IconvArr[2].charSet := UCS_2;
  IconvArr[2].Charname := 'ISO-10646-UCS-2 UCS-2 CSUNICODE';
  IconvArr[3].charSet := UCS_2;
  IconvArr[3].Charname := 'UCS-2BE UNICODE-1-1 UNICODEBIG CSUNICODE11';
  IconvArr[4].charSet := UCS_2LE;
  IconvArr[4].Charname := 'UCS-2LE UNICODELITTLE';
  IconvArr[5].charSet := UCS_4;
  IconvArr[5].Charname := 'ISO-10646-UCS-4 UCS-4 CSUCS4';
  IconvArr[6].charSet := UCS_4;
  IconvArr[6].Charname := 'UCS-4BE';
  IconvArr[7].charSet := UCS_2LE;
  IconvArr[7].Charname := 'UCS-4LE';
  IconvArr[8].charSet := UTF_16;
  IconvArr[8].Charname := 'UTF-16';
  IconvArr[9].charSet := UTF_16;
  IconvArr[9].Charname := 'UTF-16BE';
  IconvArr[10].charSet := UTF_16LE;
  IconvArr[10].Charname := 'UTF-16LE';
  IconvArr[11].charSet := UTF_32;
  IconvArr[11].Charname := 'UTF-32';
  IconvArr[12].charSet := UTF_32;
  IconvArr[12].Charname := 'UTF-32BE';
  IconvArr[13].charSet := UTF_32;
  IconvArr[13].Charname := 'UTF-32LE';
  IconvArr[14].charSet := UTF_7;
  IconvArr[14].Charname := 'UNICODE-1-1-UTF-7 UTF-7 CSUNICODE11UTF7';
  IconvArr[15].charSet := C99;
  IconvArr[15].Charname := 'C99';
  IconvArr[16].charSet := JAVA;
  IconvArr[16].Charname := 'JAVA';
  IconvArr[17].charSet := ISO_8859_1;
  IconvArr[17].Charname := 'US-ASCII ANSI_X3.4-1968 ANSI_X3.4-1986 ASCII CP367 IBM367 ISO-IR-6 ISO646-US ISO_646.IRV:1991 US CSASCII';
  IconvArr[18].charSet := ISO_8859_2;
  IconvArr[18].Charname := 'ISO-8859-2 ISO-IR-101 ISO8859-2 ISO_8859-2 ISO_8859-2:1987 L2 LATIN2 CSISOLATIN2';
  IconvArr[19].charSet := ISO_8859_3;
  IconvArr[19].Charname := 'ISO-8859-3 ISO-IR-109 ISO8859-3 ISO_8859-3 ISO_8859-3:1988 L3 LATIN3 CSISOLATIN3';
  IconvArr[20].charSet := ISO_8859_4;
  IconvArr[20].Charname := 'ISO-8859-4 ISO-IR-110 ISO8859-4 ISO_8859-4 ISO_8859-4:1988 L4 LATIN4 CSISOLATIN4';
  IconvArr[21].charSet := ISO_8859_5;
  IconvArr[21].Charname := 'ISO-8859-5 CYRILLIC ISO-IR-144 ISO8859-5 ISO_8859-5 ISO_8859-5:1988 CSISOLATINCYRILLIC';
  IconvArr[22].charSet := ISO_8859_6;
  IconvArr[22].Charname := 'ISO-8859-6 ARABIC ASMO-708 ECMA-114 ISO-IR-127 ISO8859-6 ISO_8859-6 ISO_8859-6:1987 CSISOLATINARABIC';
  IconvArr[23].charSet := ISO_8859_7;
  IconvArr[23].Charname := 'ISO-8859-7 ECMA-118 ELOT_928 GREEK GREEK8 ISO-IR-126 ISO8859-7 ISO_8859-7 ISO_8859-7:1987 CSISOLATINGREEK';
  IconvArr[24].charSet := ISO_8859_8;
  IconvArr[24].Charname := 'ISO-8859-8 HEBREW ISO_8859-8 ISO-IR-138 ISO8859-8 ISO_8859-8:1988 CSISOLATINHEBREW ISO-8859-8-I';
  IconvArr[25].charSet := ISO_8859_9;
  IconvArr[25].Charname := 'ISO-8859-9 ISO-IR-148 ISO8859-9 ISO_8859-9 ISO_8859-9:1989 L5 LATIN5 CSISOLATIN5';
  IconvArr[26].charSet := ISO_8859_10;
  IconvArr[26].Charname := 'ISO-8859-10 ISO-IR-157 ISO8859-10 ISO_8859-10 ISO_8859-10:1992 L6 LATIN6 CSISOLATIN6';
  IconvArr[27].charSet := ISO_8859_13;
  IconvArr[27].Charname := 'ISO-8859-13 ISO-IR-179 ISO8859-13 ISO_8859-13 L7 LATIN7';
  IconvArr[28].charSet := ISO_8859_14;
  IconvArr[28].Charname := 'ISO-8859-14 ISO-CELTIC ISO-IR-199 ISO8859-14 ISO_8859-14 ISO_8859-14:1998 L8 LATIN8';
  IconvArr[29].charSet := ISO_8859_15;
  IconvArr[29].Charname := 'ISO-8859-15 ISO-IR-203 ISO8859-15 ISO_8859-15 ISO_8859-15:1998';
  IconvArr[30].charSet := ISO_8859_16;
  IconvArr[30].Charname := 'ISO-8859-16 ISO-IR-226 ISO8859-16 ISO_8859-16 ISO_8859-16:2000';
  IconvArr[31].charSet := KOI8_R;
  IconvArr[31].Charname := 'KOI8-R CSKOI8R';
  IconvArr[32].charSet := KOI8_U;
  IconvArr[32].Charname := 'KOI8-U';
  IconvArr[33].charSet := KOI8_RU;
  IconvArr[33].Charname := 'KOI8-RU';
  IconvArr[34].charSet := CP1250;
  IconvArr[34].Charname := 'WINDOWS-1250 CP1250 MS-EE';
  IconvArr[35].charSet := CP1251;
  IconvArr[35].Charname := 'WINDOWS-1251 CP1251 MS-CYRL';
  IconvArr[36].charSet := CP1252;
  IconvArr[36].Charname := 'WINDOWS-1252 CP1252 MS-ANSI';
  IconvArr[37].charSet := CP1253;
  IconvArr[37].Charname := 'WINDOWS-1253 CP1253 MS-GREEK';
  IconvArr[38].charSet := CP1254;
  IconvArr[38].Charname := 'WINDOWS-1254 CP1254 MS-TURK';
  IconvArr[39].charSet := CP1255;
  IconvArr[39].Charname := 'WINDOWS-1255 CP1255 MS-HEBR';
  IconvArr[40].charSet := CP1256;
  IconvArr[40].Charname := 'WINDOWS-1256 CP1256 MS-ARAB';
  IconvArr[41].charSet := CP1257;
  IconvArr[41].Charname := 'WINDOWS-1257 CP1257 WINBALTRIM';
  IconvArr[42].charSet := CP1258;
  IconvArr[42].Charname := 'WINDOWS-1258 CP1258';
  IconvArr[43].charSet := ISO_8859_1;
  IconvArr[43].Charname := '850 CP850 IBM850 CSPC850MULTILINGUAL';
  IconvArr[44].charSet := CP862;
  IconvArr[44].Charname := '862 CP862 IBM862 CSPC862LATINHEBREW';
  IconvArr[45].charSet := CP866;
  IconvArr[45].Charname := '866 CP866 IBM866 CSIBM866';
  IconvArr[46].charSet := MAC;
  IconvArr[46].Charname := 'MAC MACINTOSH MACROMAN CSMACINTOSH';
  IconvArr[47].charSet := MACCE;
  IconvArr[47].Charname := 'MACCENTRALEUROPE';
  IconvArr[48].charSet := MACICE;
  IconvArr[48].Charname := 'MACICELAND';
  IconvArr[49].charSet := MACCRO;
  IconvArr[49].Charname := 'MACCROATIAN';
  IconvArr[50].charSet := MACRO;
  IconvArr[50].Charname := 'MACROMANIA';
  IconvArr[51].charSet := MACCYR;
  IconvArr[51].Charname := 'MACCYRILLIC';
  IconvArr[52].charSet := MACUK;
  IconvArr[52].Charname := 'MACUKRAINE';
  IconvArr[53].charSet := MACGR;
  IconvArr[53].Charname := 'MACGREEK';
  IconvArr[54].charSet := MACTU;
  IconvArr[54].Charname := 'MACTURKISH';
  IconvArr[55].charSet := MACHEB;
  IconvArr[55].Charname := 'MACHEBREW';
  IconvArr[56].charSet := MACAR;
  IconvArr[56].Charname := 'MACARABIC';
  IconvArr[57].charSet := MACTH;
  IconvArr[57].Charname := 'MACTHAI';
  IconvArr[58].charSet := ROMAN8;
  IconvArr[58].Charname := 'HP-ROMAN8 R8 ROMAN8 CSHPROMAN8';
  IconvArr[59].charSet := NEXTSTEP;
  IconvArr[59].Charname := 'NEXTSTEP';
  IconvArr[60].charSet := ARMASCII;
  IconvArr[60].Charname := 'ARMSCII-8';
  IconvArr[61].charSet := GEORGIAN_AC;
  IconvArr[61].Charname := 'GEORGIAN-ACADEMY';
  IconvArr[62].charSet := GEORGIAN_PS;
  IconvArr[62].Charname := 'GEORGIAN-PS';
  IconvArr[63].charSet := KOI8_T;
  IconvArr[63].Charname := 'KOI8-T';
  IconvArr[64].charSet := MULELAO;
  IconvArr[64].Charname := 'MULELAO-1';
  IconvArr[65].charSet := CP1133;
  IconvArr[65].Charname := 'CP1133 IBM-CP1133';
  IconvArr[66].charSet := TIS620;
  IconvArr[66].Charname := 'TIS-620 ISO-IR-166 TIS620 TIS620-0 TIS620.2529-1 TIS620.2533-0 TIS620.2533-1';
  IconvArr[67].charSet := CP874;
  IconvArr[67].Charname := 'CP874 WINDOWS-874';
  IconvArr[68].charSet := VISCII;
  IconvArr[68].Charname := 'VISCII VISCII1.1-1 CSVISCII';
  IconvArr[69].charSet := TCVN;
  IconvArr[69].Charname := 'TCVN TCVN-5712 TCVN5712-1 TCVN5712-1:1993';
  IconvArr[70].charSet := ISO_IR_14;
  IconvArr[70].Charname := 'ISO-IR-14 ISO646-JP JIS_C6220-1969-RO JP CSISO14JISC6220RO';
  IconvArr[71].charSet := JIS_X0201;
  IconvArr[71].Charname := 'JISX0201-1976 JIS_X0201 X0201 CSHALFWIDTHKATAKANA';
  IconvArr[72].charSet := JIS_X0208;
  IconvArr[72].Charname := 'ISO-IR-87 JIS0208 JIS_C6226-1983 JIS_X0208 JIS_X0208-1983 JIS_X0208-1990 X0208 CSISO87JISX0208';
  IconvArr[73].charSet := JIS_X0212;
  IconvArr[73].Charname := 'ISO-IR-159 JIS_X0212 JIS_X0212-1990 JIS_X0212.1990-0 X0212 CSISO159JISX02121990';
  IconvArr[74].charSet := GB1988_80;
  IconvArr[74].Charname := 'CN GB_1988-80 ISO-IR-57 ISO646-CN CSISO57GB1988';
  IconvArr[75].charSet := GB2312_80;
  IconvArr[75].Charname := 'CHINESE GB_2312-80 ISO-IR-58 CSISO58GB231280';
  IconvArr[76].charSet := ISO_IR_165;
  IconvArr[76].Charname := 'CN-GB-ISOIR165 ISO-IR-165';
  IconvArr[77].charSet := ISO_IR_149;
  IconvArr[77].Charname := 'ISO-IR-149 KOREAN KSC_5601 KS_C_5601-1987 KS_C_5601-1989 CSKSC56011987';
  IconvArr[78].charSet := EUC_JP;
  IconvArr[78].Charname := 'EUC-JP EUCJP EXTENDED_UNIX_CODE_PACKED_FORMAT_FOR_JAPANESE CSEUCPKDFMTJAPANESE';
  IconvArr[79].charSet := SHIFT_JIS;
  IconvArr[79].Charname := 'SHIFT-JIS MS_KANJI SHIFT_JIS SJIS CSSHIFTJIS';
  IconvArr[80].charSet := CP932;
  IconvArr[80].Charname := 'CP932';
  IconvArr[81].charSet := ISO_2022_JP;
  IconvArr[81].Charname := 'ISO-2022-JP CSISO2022JP';
  IconvArr[82].charSet := ISO_2022_JP1;
  IconvArr[82].Charname := 'ISO-2022-JP-1';
  IconvArr[83].charSet := ISO_2022_JP2;
  IconvArr[83].Charname := 'ISO-2022-JP-2 CSISO2022JP2';
  IconvArr[84].charSet := GB2312;
  IconvArr[84].Charname := 'CN-GB EUC-CN EUCCN GB2312 CSGB2312';
  IconvArr[85].charSet := CP936;
  IconvArr[85].Charname := 'CP936 GBK';
  IconvArr[86].charSet := GB18030;
  IconvArr[86].Charname := 'GB18030';
  IconvArr[87].charSet := ISO_2022_CN;
  IconvArr[87].Charname := 'ISO-2022-CN CSISO2022CN';
  IconvArr[88].charSet := ISO_2022_CNE;
  IconvArr[88].Charname := 'ISO-2022-CN-EXT';
  IconvArr[89].charSet := HZ;
  IconvArr[89].Charname := 'HZ HZ-GB-2312';
  IconvArr[90].charSet := EUC_TW;
  IconvArr[90].Charname := 'EUC-TW EUCTW CSEUCTW';
  IconvArr[91].charSet := BIG5;
  IconvArr[91].Charname := 'BIG5 BIG-5 BIG-FIVE BIGFIVE CN-BIG5 CSBIG5';
  IconvArr[92].charSet := CP950;
  IconvArr[92].Charname := 'CP950';
  IconvArr[93].charSet := BIG5_HKSCS;
  IconvArr[93].Charname := 'BIG5-HKSCS BIG5HKSCS';
  IconvArr[94].charSet := EUC_KR;
  IconvArr[94].Charname := 'EUC-KR EUCKR CSEUCKR';
  IconvArr[95].charSet := CP949;
  IconvArr[95].Charname := 'CP949 UHC';
  IconvArr[96].charSet := CP1361;
  IconvArr[96].Charname := 'CP1361 JOHAB';
  IconvArr[97].charSet := ISO_2022_KR;
  IconvArr[97].Charname := 'ISO-2022-KR CSISO2022KR';
  IconvArr[98].charSet := ISO_8859_1;
  IconvArr[98].Charname := '437 CP437 IBM437 CSPC8CODEPAGE437';
  IconvArr[99].charSet := CP737;
  IconvArr[99].Charname := 'CP737';
  IconvArr[100].charSet := CP775;
  IconvArr[100].Charname := 'CP775 IBM775 CSPC775BALTIC';
  IconvArr[101].charSet := CP852;
  IconvArr[101].Charname := '852 CP852 IBM852 CSPCP852';
  IconvArr[102].charSet := CP853;
  IconvArr[102].Charname := 'CP853';
  IconvArr[103].charSet := CP855;
  IconvArr[103].Charname := '855 CP855 IBM855 CSIBM855';
  IconvArr[104].charSet := CP857;
  IconvArr[104].Charname := '857 CP857 IBM857 CSIBM857';
  IconvArr[105].charSet := CP858;
  IconvArr[105].Charname := 'CP858';
  IconvArr[106].charSet := CP860;
  IconvArr[106].Charname := '860 CP860 IBM860 CSIBM860';
  IconvArr[107].charSet := CP861;
  IconvArr[107].Charname := '861 CP-IS CP861 IBM861 CSIBM861';
  IconvArr[108].charSet := CP863;
  IconvArr[108].Charname := '863 CP863 IBM863 CSIBM863';
  IconvArr[109].charSet := CP864;
  IconvArr[109].Charname := 'CP864 IBM864 CSIBM864';
  IconvArr[110].charSet := CP865;
  IconvArr[110].Charname := '865 CP865 IBM865 CSIBM865';
  IconvArr[111].charSet := CP869;
  IconvArr[111].Charname := '869 CP-GR CP869 IBM869 CSIBM869';
  IconvArr[112].charSet := CP1125;
  IconvArr[112].Charname := 'CP1125';
end;

end.
