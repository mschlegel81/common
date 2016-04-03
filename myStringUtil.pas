UNIT myStringUtil;

INTERFACE
USES math, strutils, sysutils,  myGenerics, zstream, Classes, huffman;

TYPE charSet=set of char;

CONST
  C_lineBreakChar = #10;
  C_carriageReturnChar = #13;
  C_tabChar = #9;
  C_formFeedChar = #12;
  BLANK_TEXT = '';
  IDENTIFIER_CHARS:charSet=['a'..'z','A'..'Z','0'..'9','.','_'];

FUNCTION formatTabs(CONST s: T_arrayOfString): T_arrayOfString;
FUNCTION isBlank(CONST s: ansistring): boolean;
FUNCTION replaceAll(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
FUNCTION replaceRecursively(CONST original, lookFor, replaceBy: ansistring; OUT isValid: boolean): ansistring; inline;
FUNCTION replaceOne(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
FUNCTION escapeString(CONST s: ansistring): ansistring;
FUNCTION unescapeString(CONST input: ansistring; CONST offset:longint; OUT parsedLength: longint): ansistring;
FUNCTION isIdentifier(CONST s: ansistring; CONST allowDot: boolean): boolean;
FUNCTION isFilename(CONST s: ansistring; CONST acceptedExtensions:array of string):boolean;
PROCEDURE collectIdentifiers(CONST s:ansistring; VAR list:T_listOfString; CONST skipWordAtPosition:longint);
FUNCTION startsWith(CONST input, head: ansistring): boolean;
FUNCTION endsWith(CONST input, tail: ansistring): boolean;
FUNCTION unbrace(CONST s:ansistring):ansistring;
FUNCTION split(CONST s:ansistring):T_arrayOfString;
FUNCTION reSplit(CONST s:T_arrayOfString):T_arrayOfString;
FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString):T_arrayOfString;
FUNCTION join(CONST lines:T_arrayOfString; CONST joiner:ansistring):ansistring;
FUNCTION cleanString(CONST s:ansistring; CONST whiteList:charSet; CONST instead:char):ansistring;
FUNCTION myTimeToStr(dt:double):string;
FUNCTION isAsciiEncoded(CONST s: ansistring): boolean;
FUNCTION isUtf8Encoded(CONST s: ansistring): boolean;
FUNCTION StripHTML(S: string): string;

FUNCTION compressString(CONST src: ansistring):ansistring;
FUNCTION decompressString(CONST src:ansistring):ansistring;

IMPLEMENTATION

FUNCTION formatTabs(CONST s: T_arrayOfString): T_arrayOfString;
  VAR matrix: array of T_arrayOfString;
      i, j, maxJ, maxLength, dotPos: longint;
      anyTab:boolean=false;
  FUNCTION isNumeric(s: ansistring): boolean;
    VAR i: longint;
        hasDot, hasExpo: boolean;
    begin
      result:=length(s)>0;
      hasDot:=false;
      hasExpo:=false;
      for i:=1 to length(s)-1 do if s [i] = '.' then begin
        result:=result and not (hasDot);
        hasDot:=true;
      end else if (s [i] in ['e', 'E']) and (i>1) then begin
        result:=result and not (hasExpo);
        hasExpo:=true;
      end else result:=result and ((s [i] in ['0'..'9']) or ((i = 1) or (s [i-1] in ['e', 'E'])) and (s [i] in ['-', '+']));
    end;

  FUNCTION posOfDot(s: ansistring): longint;
    begin
      result:=pos('.', s);
      if result = 0 then result:=length(s)+1;
    end;

  begin
    for i:=0 to length(s)-1 do anyTab:=anyTab or (pos(C_tabChar,s[i])>0);
    if not(anyTab) then exit(s);

    result:=s;
    setLength(matrix,length(result));
    j:=-1;
    maxJ:=-1;
    for i:=0 to length(result)-1 do begin
      matrix[i]:=split(result[i],C_tabChar);
      j:=length(matrix[i])-1;
      if j>maxJ then maxJ:=j;
    end;
    //expand columns to equal size:
    for j:=0 to maxJ do begin
      dotPos:=0;
      for i:=0 to length(matrix)-1 do
        if (length(matrix [i])>j) and (isNumeric(matrix [i] [j])) and
          (posOfDot(matrix [i] [j])>dotPos) then
          dotPos:=posOfDot(matrix [i] [j]);
      if dotPos>0 then
        for i:=0 to length(matrix)-1 do
          if (length(matrix [i])>j) and (isNumeric(matrix [i] [j])) then
            while posOfDot(matrix [i] [j])<dotPos do
              matrix[i][j]:=' '+matrix [i] [j];

      maxLength:=0;
      for i:=0 to length(matrix)-1 do
        if (length(matrix [i])>j) and (length(matrix [i] [j])>maxLength) then
          maxLength:=length(matrix [i] [j]);
      for i:=0 to length(matrix)-1 do
        if (length(matrix [i])>j) then
          while length(matrix [i] [j])<=maxLength do
            matrix[i][j]:=matrix [i] [j]+' ';
    end;

    //join matrix to result;
    for i:=0 to length(matrix)-1 do result[i]:=trimRight(join(matrix[i],''));
  end;

FUNCTION isBlank(CONST s: ansistring): boolean;
  VAR
    i: longint;
  begin
    result:=true;
    for i:=1 to length(s) do
      if not (s [i] in [C_lineBreakChar, C_carriageReturnChar, C_tabChar, ' ']) then
        exit(false);
  end;

FUNCTION replaceOne(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
  VAR
    p: longint;
  begin
    p:=pos(lookFor, original);
    if p>0 then
      result:=copy(original, 1, p-1)+replaceBy+
        copy(original, p+length(lookFor), length(original))
    else
      result:=original;
  end;

FUNCTION replaceAll(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
  FUNCTION anyOfLookFor(CONST c:char):boolean;
    VAR k:longint;
    begin
      for k:=1 to length(lookFor) do if lookFor[k]=c then exit(true);
      result:=false;
    end;

  VAR i:longint;
  begin
    if length(original)>65536 then begin
      i:=round(length(original)*0.49);
      while (i<=length(original)) and anyOfLookFor(original[i]) do inc(i);
      result:=replaceAll(copy(original,1,                 i-1),lookFor,replaceBy)+
              replaceAll(copy(original,i,length(original)+1-i),lookFor,replaceBy);
    end else result:=AnsiReplaceStr(original,lookFor,replaceBy);
  end;

FUNCTION replaceRecursively(CONST original, lookFor, replaceBy: ansistring; OUT isValid: boolean): ansistring; inline;
  FUNCTION anyOfLookFor(CONST c:char):boolean;
    VAR k:longint;
    begin
      for k:=1 to length(lookFor) do if lookFor[k]=c then exit(true);
      result:=false;
    end;

  VAR prev:ansistring;
      i:longint;
  begin
    if pos(lookFor, replaceBy)>0 then begin
      isValid:=false;
      exit(replaceAll(original, lookFor, replaceBy));
    end else isValid:=true;
    if length(original)>65536 then begin
      i:=round(length(original)*0.49);
      while (i<=length(original)) and anyOfLookFor(original[i]) do inc(i);
      result:=replaceAll(
              replaceRecursively(copy(original,1,                 i-1),lookFor,replaceBy,isValid)+
              replaceRecursively(copy(original,i,length(original)+1-i),lookFor,replaceBy,isValid),
                                                                       lookFor,replaceBy);
    end else begin
      result:=original;
      repeat
        prev:=result;
        result:=AnsiReplaceStr(prev,lookFor,replaceBy);
      until prev=result;
    end;
  end;

FUNCTION escapeString(CONST s: ansistring): ansistring;
  FUNCTION pascalStyle:ansistring;
    CONST DELIM='''';
    begin
      result:=DELIM+replaceAll(s,DELIM,DELIM+DELIM)+DELIM;
    end;

  CONST escapes:array[0..34,0..1] of char=
       (('\','\'),
        (#0 ,'0'),(#1 ,'1'),(#2 ,'2'),(#3 ,'3'),(#4 ,'4'),(#5 ,'5'),(#6 ,'6'),(#7 ,'a'),
        (#8 ,'b'),(#9 ,'t'),(#10,'n'),(#11,'v'),(#12,'f'),(#13,'r'),(#14,'S'),(#15,'s'),
        (#16,'d'),(#17,'A'),(#18,'B'),(#19,'C'),(#20,'D'),(#21,'N'),(#22,'X'),(#23,'T'),
        (#24,'Z'),(#25,'M'),(#26,'Y'),(#27,'x'),(#28,'F'),(#29,'G'),(#30,'R'),(#31,'U'),
        (#127,'-'),('"','"'));
  FUNCTION javaStyle:ansistring;
    VAR i:longint;
    begin
      result:=s;
      for i:=0 to length(escapes)-1 do result:=replaceAll(result,escapes[i,0],'\'+escapes[i,1]);
      result:='"'+result+'"';
    end;

  VAR tmp:ansistring;
      i:longint;
  begin
    for i:=1 to length(escapes)-2 do if pos(escapes[i,0],s)>0 then exit(javaStyle);
    tmp:=javaStyle;
    result:=pascalStyle;
    if length(tmp)<length(result) then result:=tmp;
  end;

FUNCTION unescapeString(CONST input: ansistring; CONST offset:longint; OUT parsedLength: longint): ansistring;
  {$MACRO ON}
  {$define exitFailing:=begin parsedLength:=0; exit(''); end}
  CONST SQ='''';
        DQ='"';
  VAR i,i0,i1: longint;
      continue:boolean;
  begin
    if length(input)>=offset+1 then begin //need at least a leading and a trailing delimiter
      if input[offset]=SQ then begin
        i0:=offset+1; i:=i0; i1:=offset; continue:=true; result:='';
        while (i<=length(input)) and continue do if input[i]=SQ then begin
          if (i<length(input)) and (input[i+1]=SQ) then begin
            result:=result+copy(input,i0,i1-i0+1)+SQ;
            inc(i,2);
            i0:=i;
            i1:=i0-1;
          end else continue:=false;
        end else begin
          i1:=i;
          inc(i);
        end;
        if continue then exitFailing;
        result:=result+copy(input,i0,i1-i0+1);
        parsedLength:=i+1-offset;
        exit(result);
      end else if input[offset]=DQ then begin
        i0:=offset+1; i:=i0; i1:=offset; continue:=true; result:='';
        while (i<=length(input)) and (input[i]<>DQ) do if input[i]='\' then begin
          if (i<length(input)) then begin
            case input[i+1] of
              '0': result:=result+copy(input,i0,i1-i0+1)+#0  ;
              '1': result:=result+copy(input,i0,i1-i0+1)+#1  ;
              '2': result:=result+copy(input,i0,i1-i0+1)+#2  ;
              '3': result:=result+copy(input,i0,i1-i0+1)+#3  ;
              '4': result:=result+copy(input,i0,i1-i0+1)+#4  ;
              '5': result:=result+copy(input,i0,i1-i0+1)+#5  ;
              '6': result:=result+copy(input,i0,i1-i0+1)+#6  ;
              'a': result:=result+copy(input,i0,i1-i0+1)+#7  ;
              'b': result:=result+copy(input,i0,i1-i0+1)+#8  ;
              't': result:=result+copy(input,i0,i1-i0+1)+#9  ;
              'n': result:=result+copy(input,i0,i1-i0+1)+#10 ;
              'v': result:=result+copy(input,i0,i1-i0+1)+#11 ;
              'f': result:=result+copy(input,i0,i1-i0+1)+#12 ;
              'r': result:=result+copy(input,i0,i1-i0+1)+#13 ;
              'S': result:=result+copy(input,i0,i1-i0+1)+#14 ;
              's': result:=result+copy(input,i0,i1-i0+1)+#15 ;
              'd': result:=result+copy(input,i0,i1-i0+1)+#16 ;
              'A': result:=result+copy(input,i0,i1-i0+1)+#17 ;
              'B': result:=result+copy(input,i0,i1-i0+1)+#18 ;
              'C': result:=result+copy(input,i0,i1-i0+1)+#19 ;
              'D': result:=result+copy(input,i0,i1-i0+1)+#20 ;
              'N': result:=result+copy(input,i0,i1-i0+1)+#21 ;
              'X': result:=result+copy(input,i0,i1-i0+1)+#22 ;
              'T': result:=result+copy(input,i0,i1-i0+1)+#23 ;
              'Z': result:=result+copy(input,i0,i1-i0+1)+#24 ;
              'M': result:=result+copy(input,i0,i1-i0+1)+#25 ;
              'Y': result:=result+copy(input,i0,i1-i0+1)+#26 ;
              'x': result:=result+copy(input,i0,i1-i0+1)+#27 ;
              'F': result:=result+copy(input,i0,i1-i0+1)+#28 ;
              'G': result:=result+copy(input,i0,i1-i0+1)+#29 ;
              'R': result:=result+copy(input,i0,i1-i0+1)+#30 ;
              'U': result:=result+copy(input,i0,i1-i0+1)+#31 ;
              '-': result:=result+copy(input,i0,i1-i0+1)+#127;
              else result:=result+copy(input,i0,i1-i0+1)+input[i+1];
            end;
            inc(i,2);
            i0:=i;
            i1:=i0-1;
          end else exitFailing;
        end else begin
          i1:=i;
          inc(i);
        end;
        result:=result+copy(input,i0,i1-i0+1);
        parsedLength:=i+1-offset;
        exit(result);
      end;
    end;
    exitFailing;
  end;

FUNCTION isIdentifier(CONST s: ansistring; CONST allowDot: boolean): boolean;
  VAR i: longint;
      dotAllowed: boolean;
  begin
    dotAllowed:=allowDot;
    result:=(length(s)>=1) and (s[1] in ['a'..'z', 'A'..'Z']);
    i:=2;
    while result and (i<=length(s)) do
      if (s [i] in IDENTIFIER_CHARS) then inc(i)
      else if (s [i] = '.') and dotAllowed then begin
        inc(i);
        dotAllowed:=false;
      end else
        result:=false;
  end;

FUNCTION isFilename(CONST s: ansistring; CONST acceptedExtensions:array of string):boolean;
  VAR i:longint;
      ext:string;
  begin
    if length(s)=0 then exit(false);
    ext:=uppercase(extractFileExt(s));
    if length(acceptedExtensions)=0 then exit(true);
    for i:=0 to length(acceptedExtensions)-1 do
      if uppercase(acceptedExtensions[i])=ext then exit(true);
    result:=false;
  end;

PROCEDURE collectIdentifiers(CONST s:ansistring; VAR list:T_listOfString; CONST skipWordAtPosition:longint);
  VAR i,i0:longint;
  begin
    i:=1;
    while i<=length(s) do begin
      if s[i] in ['a'..'z','A'..'Z'] then begin
        i0:=i;
        while (i<=length(s)) and (s[i] in IDENTIFIER_CHARS) do inc(i);
        if not((i0<=skipWordAtPosition) and (i>=skipWordAtPosition)) then list.add(copy(s,i0,i-i0));
      end else if (s[i]='/') and (i+1<=length(s)) and (s[i+1]='/') then exit
      else inc(i);
    end;
  end;

FUNCTION startsWith(CONST input, head: ansistring): boolean;
  begin
    result:=copy(input, 1, length(head)) = head;
  end;

FUNCTION endsWith(CONST input, tail: ansistring): boolean;
  begin
    result:=(length(input)>=length(tail)) and (copy(input,length(input)-length(tail)+1,length(tail))=tail);
  end;

FUNCTION unbrace(CONST s:ansistring):ansistring;
  begin
    if (length(s)>=2) and (
        (s[1]='(') and (s[length(s)]=')') or
        (s[1]='[') and (s[length(s)]=']') or
        (s[1]='{') and (s[length(s)]='}'))
    then result:=copy(s,2,length(s)-2)
    else result:=s;
  end;


FUNCTION split(CONST s:ansistring):T_arrayOfString;
  VAR lineSplitters:T_arrayOfString;
  begin
    lineSplitters:=(C_carriageReturnChar+C_lineBreakChar);
    append(lineSplitters,C_lineBreakChar+C_carriageReturnChar);
    append(lineSplitters,C_lineBreakChar);
    result:=split(s,lineSplitters);
  end;

FUNCTION reSplit(CONST s:T_arrayOfString):T_arrayOfString;
  VAR i:longint;
  begin
    setLength(result,0);
    for i:=0 to length(s)-1 do append(result,split(s[i]));
  end;

FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString):T_arrayOfString;
  PROCEDURE firstSplitterPos(CONST s:ansistring; OUT splitterStart,splitterEnd:longint);
    VAR i,p:longint;
    begin
      splitterStart:=0;
      for i:=0 to length(splitters)-1 do begin
        p:=pos(splitters[i],s);
        if (p>0) and ((splitterStart=0) or (p<splitterStart)) then begin
          splitterStart:=p;
          splitterEnd:=p+length(splitters[i]);
        end;
      end;
    end;

  VAR sp0,sp1:longint;
      rest:ansistring;
  begin
    setLength(result,0);
    firstSplitterPos(s,sp0,sp1);
    if sp0<=0 then exit(s);
    rest:=s;
    while sp0>0 do begin
      append(result,copy(rest,1,sp0-1));
      rest:=copy(rest,sp1,length(rest));
      firstSplitterPos(rest,sp0,sp1);
    end;
    append(result,rest);
  end;

FUNCTION join(CONST lines:T_arrayOfString; CONST joiner:ansistring):ansistring;
  VAR i:longint;
  begin
    if length(lines)>0 then result:=lines[0] else result:='';
    for i:=1 to length(lines)-1 do result:=result+joiner+lines[i];
  end;

FUNCTION cleanString(CONST s:ansistring; CONST whiteList:charSet; CONST instead:char):ansistring;
  VAR k:longint;
      tmp:shortString;
  begin
    if length(s)<=255 then begin
      tmp:=s;
      for k:=1 to length(s) do if not(tmp[k] in whiteList) then tmp[k]:=instead;
      exit(tmp);
    end;
    result:='';
    for k:=1 to length(s) do if s[k] in whiteList then result:=result+s[k] else result:=result+instead;
  end;

FUNCTION myTimeToStr(dt:double):string;
  CONST oneMinute=1/(24*60);
        oneSecond=oneMinute/60;
  begin
    if dt<oneMinute
      then begin
        result:=formatFloat('#0.00',dt/oneSecond)+'sec';
        if length(result)<8 then result:=' '+result;
      end
    else if dt>1
      then begin
        dt:=dt*24;             result:=       formatFloat('00',floor(dt))+':';
        dt:=(dt-floor(dt))*60; result:=result+formatFloat('00',floor(dt))+':';
        dt:=(dt-floor(dt))*60; result:=result+formatFloat('00',floor(dt));
      end
    else result:=timeToStr(dt);
  end;

FUNCTION isAsciiEncoded(CONST s: ansistring): boolean;
  VAR i:longint;
  begin
    for i:=1 to length(s) do if ord(s[i])>127 then exit(false);
    result:=true;
  end;

FUNCTION isUtf8Encoded(CONST s: ansistring): boolean;
  VAR i:longint;
  begin
    if length(s)=0 then exit(true);
    i:=1;
    while i<=length(s) do begin
      // ASCII
      if (s[i] in [#$09,#$0A,#$0D,#$20..#$7E]) then begin
        inc(i);
        continue;
      end;
      // non-overlong 2-byte
      if (i+1<=length(s)) and
         (s[i  ] in [#$C2..#$DF]) and
         (s[i+1] in [#$80..#$BF]) then begin
        inc(i,2);
        continue;
      end;
      // excluding overlongs
      if (i+2<=length(s)) and
         (((s[i]=#$E0) and
           (s[i+1] in [#$A0..#$BF]) and
           (s[i+2] in [#$80..#$BF])) or
          ((s[i] in [#$E1..#$EC,#$EE,#$EF]) and
           (s[i+1] in [#$80..#$BF]) and
           (s[i+2] in [#$80..#$BF])) or
          ((s[i]=#$ED) and
           (s[i+1] in [#$80..#$9F]) and
           (s[i+2] in [#$80..#$BF]))) then
      begin
        inc(i,3);
        continue;
      end;
      // planes 1-3
      if (i+3<=length(s)) and
         (((s[i  ]=#$F0) and
           (s[i+1] in [#$90..#$BF]) and
           (s[i+2] in [#$80..#$BF]) and
           (s[i+3] in [#$80..#$BF])) or
          ((s[i  ] in [#$F1..#$F3]) and
           (s[i+1] in [#$80..#$BF]) and
           (s[i+2] in [#$80..#$BF]) and
           (s[i+3] in [#$80..#$BF])) or
          ((s[i]=#$F4) and
           (s[i+1] in [#$80..#$8F]) and
           (s[i+2] in [#$80..#$BF]) and
           (s[i+3] in [#$80..#$BF]))) then
      begin
        inc(i,4);
        continue;
      end;
      exit(false);
    end;
    exit(true);
  end;

FUNCTION StripHTML(S: string): string;
  VAR TagBegin, TagEnd, TagLength: integer;
  begin
    TagBegin := pos( '<', S);      // search position of first <
    while (TagBegin > 0) do begin  // while there is a < in S
      TagEnd := pos('>', S);              // find the matching >
      TagEnd := PosEx('>',S,TagBegin);
      TagLength := TagEnd - TagBegin + 1;
      Delete(S, TagBegin, TagLength);     // delete the tag
      TagBegin:= pos( '<', S);            // search for next <
    end;
    result := S;
  end;

CONST ESCAPER:char=#30;
      MAX_IDX :array['0'..'9'] of byte=(152,157,162,167,172,177,182,187,192,195);
      UNUSED  :array[0..195] of char=(#0,#1,#2,#3,#4,#5,#6,#7,#8,#11,#12,#14,#15,#16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#31,#127,#128,#129,#130,#131,#132,#133,#134,#135,#136,#137,#138,#139,#140,#141,#142,#143,#144,#145,#146,#147,#148,#149,#150,#151,#152,#153,#154,#155,#156,#157,#158,#160,#161,#162,#163,#165,#166,#167,#168,#169,#170,#171,#172,#173,#174,#175,#176,#177,#178,#179,#180,#181,#183,#184,#185,#186,#187,#189,#190,#191,#192,#193,#194,#196,#197,#198,#199,#200,#201,#202,#203,#204,#205,#206,#207,#208,#209,#210,#211,#212,#213,#214,#215,#216,#217,#218,#219,#220,#221,#222,#223,#224,#225,#226,#227,#228,#229,#230,#231,#232,#233,#234,#235,#236,#237,#238,#239,#240,#241,#242,#243,#244,#245,#246,#247,#248,#249,#250,#251,#252,#253,#254,#255,#96,#126,#159,#164,#182,#188,#195,#9,#81,#92,#38,#64,#124,#88,#37,#42,#35,#123,#125,#36,#33,#75,#90,#89,#43,#86,#113,#34,#85,#87,#122,#63,#106,#72,#93,#91,#77,#68,#47,#60,#82,#55,#71,#80);
      FREQUENT:array[0..195] of string[2]=(#32#32,#116#104,#32#116,#101#32,#104#101,#10#32,#100#32,#32#97,#95#95,#110#100,#97#110,#44#32,#116#32,#105#110,#101#114,#32#115,#32#104,#115#32,#32#111,#114#101,#110#32,#32#119,#104#97,#101#110,#111#114,#97#116,#111#102,#102#32,#114#32,#97#108,#32#105,#111#110,#116#111,#104#105,#32#98,#111#32,#111#117,#121#32,#10#10,#101#115,#105#116,#105#115,#32#94,#110#116,#32#102,#115#116,#32#109,#115#101,#116#101,#97#114,#108#108,#104#32,#110#103,#101#100,#108#101,#108#32,#118#101,#32#99,#46#10,#101#97,#109#101,#98#101,#104#111,#97#115,#115#104,#110#101,#32#100,#114#105,#100#101,#32#112,#32#117,#13#10,#114#97,#101#116,#117#110,#102#111,#114#111,#32#110,#105#108,#101#108,#99#111,#119#105,#116#105,#32#101,#110#111,#97#105,#101#109,#101#10,#32#108,#99#104,#114#100,#115#97,#111#109,#109#97,#117#115,#117#116,#111#116,#109#32,#108#105,#117#114,#119#104,#99#97,#65#110,#97#109,#101#101,#58#32,#32#114,#115#44,#32#103,#105#109,#100#44,#119#101,#59#13,#105#100,#103#32,#115#111,#32#73,#107#101,#108#97,#99#101,#119#97,#101#44,#112#101,#114#115,#116#114,#105#99,#110#115,#97#121,#32#121,#97#100,#105#114,#105#111,#94#49,#101#121,#59#32,#108#111,#97#99,#111#119,#111#100,#97#32,#116#97,#115#115,#117#108,#108#100,#115#105,#103#104,#114#116,#109#111,#97#118,#101#105,#111#108,#32#76,#76#111,#112#114,#105#101,#73#32,#103#101,#112#97,#111#115,#100#97,#101#118,#100#111,#100#105,#94#50,#112#111,#104#116,#105#103,#101#99,#102#105,#84#104,#108#116,#121#101,#112#108,#44#10,#111#111,#105#118,#110#44,#105#102,#109#105,#100#10,#117#112,#32#107,#39#44,#119#111,#110#97,#32#74,#103#105,#115#117,#101#102,#97#98,#117#32,#98#114,#110#105,#103#97,#110#99,#97#103);

FUNCTION pair_compress(CONST Source:ansistring):ansistring;
  VAR lev:char;
      newResult:ansistring;
      i:longint;
      freqIdx:byte;

  FUNCTION needsEscaping:boolean;
    VAR j:longint;
    begin
      for j:=0 to MAX_IDX[lev]-1 do if UNUSED[j]=Source[i] then exit(true);
      result:=false;
    end;

  FUNCTION getFreqIdx:byte;
    VAR part:string[2];
        j:longint;
    begin
      if i>=length(Source) then exit(255);
      part:=Source[i]+Source[i+1];
      for j:=0 to MAX_IDX[lev]-1 do if FREQUENT[j]=part then exit(j);
      exit(255)
    end;

  begin
    result:='';
    for lev:='0' to '9' do begin
      newResult:=lev;
      i:=1;
      while i<=length(Source) do begin
        if needsEscaping then begin
          newResult:=newResult+ESCAPER+Source[i];
          inc(i);
        end else begin
          freqIdx:=getFreqIdx;
          if freqIdx<255 then begin
            newResult:=newResult+UNUSED[freqIdx];
            inc(i,2);
          end else begin
            newResult:=newResult+Source[i];
            inc(i);
          end;
        end;
      end;
      if (lev='0') or (length(newResult)<length(result)) then result:=newResult;
    end;
  end;

FUNCTION pair_decompress(CONST Source:ansistring):ansistring;
  VAR lev:char;
      freqIdx:byte;
      i:longint;

  FUNCTION getFreqIdx:byte;
    VAR j:longint;
    begin
      for j:=0 to MAX_IDX[lev]-1 do if UNUSED[j]=Source[i] then exit(j);
      exit(255)
    end;

  begin
    if (length(Source)=0) or not(Source[1] in ['0'..'9']) then exit(Source);
    lev:=Source[1];
    result:='';
    i:=2;
    while i<=length(Source) do begin
      if (i<length(Source)) and (Source[i]=ESCAPER) then begin
        inc(i);
        result:=result+Source[i];
        inc(i);
      end else begin
        freqIdx:=getFreqIdx;
        if freqIdx<255 then result:=result+FREQUENT[freqIdx]
                       else result:=result+Source[i];
        inc(i);
      end;
    end;
  end;


FUNCTION gzip_compressString(CONST ASrc: ansistring):ansistring;
  VAR vDest: TStringStream;
      vSource: TStream;
      vCompressor: TCompressionStream;
  begin
    result:='';
    vDest := TStringStream.create('');
    try
      vCompressor := TCompressionStream.create(clMax, vDest);
      try
	vSource := TStringStream.create(ASrc);
	try     vCompressor.CopyFrom(vSource, 0);
	finally vSource.free; end;
      finally
	vCompressor.free;
      end;
      vDest.position := 0;
      result := vDest.DataString;
    finally
      vDest.free;
    end;
  end;

FUNCTION gzip_decompressString(CONST ASrc; CONST ASrcSize: int64):ansistring;
  CONST MAXWORD=65535;
  VAR vDest: TStringStream;
      vSource: TStream;
      vDecompressor: TDecompressionStream;
      vBuffer: pointer;
      vCount : integer;
  begin
    result:='';
    vSource := TMemoryStream.create;
    try
      vSource.write(ASrc, ASrcSize);
      vSource.position := 0;
      vDecompressor := TDecompressionStream.create(vSource);
      try
	vDest := TStringStream.create('');
	try
	  getMem(vBuffer, MAXWORD);
	  try
	    repeat
	      vCount := vDecompressor.read(vBuffer^, MAXWORD);
	      if vCount > 0 then vDest.WriteBuffer(vBuffer^, vCount);
	    until vCount < MAXWORD;
	  finally
	    freeMem(vBuffer);
	  end;
	  vDest.position := 0;
	  result := vDest.DataString;
	finally
	  vDest.free;
	end;
      finally
	vDecompressor.free;
      end;
    finally
      vSource.free;
    end;
  end;

FUNCTION gzip_decompressString(CONST src:ansistring):ansistring;
  begin
    result:=gzip_decompressString(src[1],length(src));
  end;

FUNCTION compressString(CONST src: ansistring):ansistring;
  VAR alternative:ansistring;
  begin
    if length(src)=0 then exit(src);
    if src[1] in [' ','x','%','$','0'..'9'] then result:='$'+src
                                            else result:=    src;
    alternative:=gzip_compressString(src);
    if length(alternative)<length(result) then result:=alternative;
    alternative:=pair_compress(src);
    if length(alternative)<length(result) then result:=alternative;
    alternative:='%'+huffyEncode(src);
    if length(alternative)<length(result) then result:=alternative;
  end;

FUNCTION decompressString(CONST src:ansistring):ansistring;
  begin
    if length(src)=0 then exit(src);
    case src[1] of
      '$': exit(copy(src,2,length(src)-1));
      '%': exit(huffyDecode(copy(src,2,length(src)-1)));
      'x': exit(gzip_decompressString(src));
      '0'..'9': exit(pair_decompress(src));
    end;
    result:=src;
  end;

end.
