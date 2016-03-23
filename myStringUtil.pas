UNIT myStringUtil;

INTERFACE
USES math, strutils, sysutils,  myGenerics, zstream, Classes;

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

FUNCTION compressString(const src: AnsiString):AnsiString;
FUNCTION decompressString(const src:ansistring):ansistring;

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

CONST
  MOST_FREQUENT_SUCCESSOR:array[#32..#126] of char=(
    #32,#45,#62,#82,#105,#115,#115,#44,#112,#59,#115,#39,#32,#45,#10,#47,#65,#48,#65,#65,#65,#65,
    #65,#65,#65,#65,#32,#13,#47,#61,#60,#32,#115,#110,#101,#104,#97,#103,#111,#111,#101,#32,#101,
    #105,#111,#111,#83,#78,#95,#117,#101,#84,#104,#78,#65,#104,#44,#101,#101,#39,#116,#44,#49,#95,
    #32,#110,#101,#111,#32,#32,#32,#32,#101,#110,#117,#101,#108,#101,#100,#114,#101,#117,#101,#32,
    #104,#110,#101,#105,#116,#32,#101,#36,#32,#13,#39);

FUNCTION RLE_compress(CONST s:ansistring):ansistring;
  VAR prevChar:char=#32;
      i:longint;
      runLength:byte=0;
  begin
    if s='' then exit(s);
    result:=s[1];
    if s[1] in [#32..#126] then prevChar:=s[1];
    for i:=2 to length(s) do begin
      if (s[i]>#126) then begin
        result:=result+#255;
        result:=result+s[i];
      end else if (s[i]=MOST_FREQUENT_SUCCESSOR[prevChar]) and (runLength<127) then inc(runLength)
      else begin
        if runLength>0 then result:=result+chr(runLength+127);
        runLength:=0;
        result:=result+s[i];
      end;
      if s[i] in [#32..#126] then prevChar:=s[i];
    end;
  end;

FUNCTION RLE_decompress(CONST s:ansistring):ansistring;
  VAR prevChar:char=#32;
      i,j:longint;
      runLength:byte;
  begin
    if s='' then exit(s);
    result:=s[1];
    if s[1] in [#32..#126] then prevChar:=s[1];
    i:=2;
    while i<=length(s) do begin
      if s[i]=#255 then begin
        inc(i);
        result:=result+s[i];
        inc(i);
      end else if s[i]>=#128 then begin
        runLength:=ord(s[i])-127;
        for j:=1 to runLength do begin
          result:=result+MOST_FREQUENT_SUCCESSOR[prevChar];
          prevChar:=MOST_FREQUENT_SUCCESSOR[prevChar];
        end;
        inc(i);
      end else begin
        result:=result+s[i];
        if s[i] in [#32..#126] then prevChar:=s[i];
        inc(i);
      end;
    end;
  end;

CONST
  MOST_FREQUENT_PAIRS:array[#128..#255] of string[2]=(
    #32#32,#116#104,#32#116,#101#32,#104#101,#10#32,#100#32,#32#97,#95#95,#110#100,#97#110,#44#32,
    #116#32,#105#110,#101#114,#32#115,#32#104,#115#32,#32#111,#114#101,#110#32,#32#119,#104#97,
    #101#110,#111#114,#97#116,#111#102,#102#32,#114#32,#97#108,#32#105,#111#110,#116#111,#104#105,
    #32#98,#111#32,#111#117,#121#32,#10#10,#101#115,#105#116,#105#115,#32#94,#110#116,#32#102,
    #115#116,#32#109,#115#101,#116#101,#97#114,#108#108,#104#32,#110#103,#101#100,#108#101,#108#32,
    #118#101,#32#99,#46#10,#101#97,#109#101,#98#101,#104#111,#97#115,#115#104,#110#101,#32#100,
    #114#105,#100#101,#32#112,#32#117,#13#10,#114#97,#101#116,#117#110,#102#111,#114#111,#32#110,
    #105#108,#101#108,#99#111,#119#105,#116#105,#32#101,#110#111,#97#105,#101#10,#101#109,#32#108,
    #99#104,#114#100,#115#97,#111#109,#109#97,#117#115,#117#116,#111#116,#109#32,#108#105,#117#114,
    #119#104,#99#97,#65#110,#97#109,#101#101,#58#32,#32#114,#115#44,#32#103,#105#109,#100#44,#119#101,
    #59#13,#105#100,#103#32,#115#111,#32#73,#107#101,#108#97,#99#101,#119#97,#101#44,#112#101,
    #114#115,#116#114,#105#99,#110#115,#97#121);

FUNCTION pair_Compress(CONST source:ansistring):ansistring;
  VAR c:char;
  begin
    result:=source;
    for c:=#128 to #255 do result:=replaceAll(result,MOST_FREQUENT_PAIRS[c],c);
  end;

FUNCTION pair_decompress(CONST source:ansistring):ansistring;
  VAR c:char;
  begin
    result:=source;
    for c:=#255 downto #128 do result:=replaceAll(result,c,MOST_FREQUENT_PAIRS[c]);
  end;


FUNCTION gzip_compressString(const ASrc: AnsiString):AnsiString;
  var vDest: TStringStream;
      vSource: TStream;
      vCompressor: TCompressionStream;
  begin
    result:='';
    vDest := TStringStream.Create('');
    try
      vCompressor := TCompressionStream.Create(clMax, vDest);
      try
	vSource := TStringStream.Create(ASrc);
	try     vCompressor.CopyFrom(vSource, 0);
	finally vSource.Free; end;
      finally
	vCompressor.Free;
      end;
      vDest.Position := 0;
      result := vDest.DataString;
    finally
      vDest.Free;
    end;
  end;

FUNCTION gzip_decompressString(const ASrc; const ASrcSize: Int64):ansistring;
  CONST MAXWORD=65535;
  var vDest: TStringStream;
      vSource: TStream;
      vDecompressor: TDecompressionStream;
      vBuffer: Pointer;
      vCount : Integer;
  begin
    result:='';
    vSource := TMemoryStream.Create;
    try
      vSource.Write(ASrc, ASrcSize);
      vSource.Position := 0;
      vDecompressor := TDecompressionStream.Create(vSource);
      try
	vDest := TStringStream.Create('');
	try
	  GetMem(vBuffer, MAXWORD);
	  try
	    repeat
	      vCount := vDecompressor.Read(vBuffer^, MAXWORD);
	      if vCount > 0 then vDest.WriteBuffer(vBuffer^, vCount);
	    until vCount < MAXWORD;
	  finally
	    FreeMem(vBuffer);
	  end;
	  vDest.Position := 0;
	  result := vDest.DataString;
	finally
	  vDest.Free;
	end;
      finally
	vDecompressor.Free;
      end;
    finally
      vSource.Free;
    end;
  end;

FUNCTION gzip_decompressString(const src:ansistring):ansistring;
  begin
    result:=gzip_decompressString(src[1],length(src));
  end;

FUNCTION compressString(const src: AnsiString):AnsiString;
  VAR alternative:ansistring;
  begin
    result:=' '+src;
    alternative:=gzip_compressString(src);
    if length(escapeString(alternative))<length(escapeString(result)) then Result:=alternative;
    alternative:='y'+RLE_compress(src);
    if length(escapeString(alternative))<length(escapeString(result)) then Result:=alternative;
    if isAsciiEncoded(src) then begin
      alternative:='z'+pair_Compress(src);
      if length(escapeString(alternative))<length(escapeString(result)) then result:=alternative;
    end;
  end;

FUNCTION decompressString(const src:ansistring):ansistring;
  begin
    if length(src)=0 then exit(src);
    case src[1] of
      'x': exit(gzip_decompressString(src));
      'y': exit(RLE_decompress(copy(src,2,length(src)-1)));
      'z': exit(pair_decompress(copy(src,2,length(src)-1)));
    end;
    result:=src;
  end;

end.
