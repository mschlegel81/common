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

FUNCTION compressString(CONST src: ansistring; CONST algorithm:byte):ansistring;
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
  begin
    if (pos(C_lineBreakChar,s)>0) or (pos(C_tabChar,s)>0) then exit(javaStyle);
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

FUNCTION gzip_compressString(CONST ASrc: ansistring):ansistring;
  VAR vDest: TStringStream;
      vSource: TStream;
      vCompressor: TCompressionStream;
  begin
    result:='';
    vDest := TStringStream.create('');
    try
      vCompressor := TCompressionStream.create(clMax, vDest,true);
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
      vDecompressor := TDecompressionStream.create(vSource,true);
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

FUNCTION compressString(CONST src: ansistring; CONST algorithm:byte):ansistring;
  VAR alternative:ansistring;
  begin
    case algorithm of
      1: exit(#126+gzip_compressString(src));
      2: exit(#188+huffyEncode(src));
      3: exit(#195+huffyEncode2(src));
    end;
    if length(src)=0 then exit(src);
    if src[1] in [#96,#126,#188,#195] then result:=#96+src
                                      else result:=    src;
    alternative:=#126+gzip_compressString(src);
    if length(alternative)<length(result) then result:=alternative;
    alternative:=#188+huffyEncode(src);
    if length(alternative)<length(result) then result:=alternative;
    alternative:=#195+huffyEncode2(src);
    if length(alternative)<length(result) then result:=alternative;
  end;

FUNCTION decompressString(CONST src:ansistring):ansistring;
  begin
    if length(src)=0 then exit(src);
    case src[1] of
       #96: exit(                      copy(src,2,length(src)-1));
      #126: exit(gzip_decompressString(copy(src,2,length(src)-1)));
      #188: exit(huffyDecode(          copy(src,2,length(src)-1)));
      #195: exit(huffyDecode2(         copy(src,2,length(src)-1)));
    end;
    result:=src;
  end;

end.
