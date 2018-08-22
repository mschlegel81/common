UNIT myStringUtil;

INTERFACE
USES math, strutils, sysutils,  myGenerics, zstream, Classes, huffman, LazUTF8;

TYPE T_charSet=set of char;
     T_escapeStyle=(es_javaStyle,es_mnhPascalStyle,es_strictPascalStyle,es_pickShortest,es_dontCare);
     T_stringEncoding=(se_testPending,se_ascii,se_utf8,se_mixed);
CONST
  C_lineBreakChar = #10;
  C_carriageReturnChar = #13;
  C_tabChar = #9;
  C_invisibleTabChar = #11;
  C_formFeedChar = #12;
  C_shiftOutChar=#14;
  C_shiftInChar =#15;
  BLANK_TEXT = '';
  IDENTIFIER_CHARS:T_charSet=['a'..'z','A'..'Z','0'..'9','.','_'];

FUNCTION formatTabs(CONST s: T_arrayOfString): T_arrayOfString;
FUNCTION isBlank(CONST s: ansistring): boolean;
FUNCTION replaceAll(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
FUNCTION replaceRecursively(CONST original, lookFor, replaceBy: ansistring; OUT isValid: boolean): ansistring; inline;
FUNCTION replaceOne(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
FUNCTION escapeString(CONST s: ansistring; CONST style:T_escapeStyle): ansistring;
FUNCTION unescapeString(CONST input: ansistring; CONST offset:longint; OUT parsedLength: longint): ansistring;
FUNCTION isIdentifier(CONST s: ansistring; CONST allowDot: boolean): boolean;
FUNCTION isFilename(CONST s: ansistring; CONST acceptedExtensions:array of string):boolean;
PROCEDURE collectIdentifiers(CONST s:ansistring; VAR list:T_setOfString; CONST skipWordAtPosition:longint);
FUNCTION startsWith(CONST input, head: ansistring): boolean;
FUNCTION endsWith(CONST input, tail: ansistring): boolean;
FUNCTION unbrace(CONST s:ansistring):ansistring;
FUNCTION split(CONST s:ansistring):T_arrayOfString;
FUNCTION reSplit(CONST s:T_arrayOfString):T_arrayOfString;
FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString):T_arrayOfString;
FUNCTION join(CONST lines:T_arrayOfString; CONST joiner:ansistring):ansistring;
FUNCTION cleanString(CONST s:ansistring; CONST whiteList:T_charSet; CONST instead:char):ansistring;
FUNCTION myTimeToStr(dt:double):string;
FUNCTION isAsciiEncoded(CONST s: ansistring): boolean;
FUNCTION isUtf8Encoded(CONST s: ansistring): boolean;
FUNCTION encoding(CONST s: ansistring):T_stringEncoding;
FUNCTION StripHTML(CONST S: string): string;
FUNCTION ensureSysEncoding(CONST s:ansistring):ansistring;
FUNCTION ensureUtf8Encoding(CONST s:ansistring):ansistring;

FUNCTION compressString(CONST src: ansistring; CONST algorithm:byte):ansistring;
FUNCTION decompressString(CONST src:ansistring):ansistring;
FUNCTION tokenSplit(CONST stringToSplit:ansistring; CONST language:string='MNH'):T_arrayOfString;
FUNCTION anistringInfo(VAR s:ansistring):string;
FUNCTION typingSimilarity(CONST s1,s2:shortstring):longint;
PROCEDURE sortByTypingSimilarity(target:shortstring; VAR list:T_arrayOfString);
IMPLEMENTATION

FUNCTION formatTabs(CONST s: T_arrayOfString): T_arrayOfString;
  TYPE TcellInfo=record
    cellType:(ctLeftAlignedString,ctRightAlignedString,ctNumeric);
    posOfDot,txtLength:longint;
    txt:ansistring;
  end;

  FUNCTION infoFromString(CONST s:ansistring):TcellInfo;
    FUNCTION isNumeric(CONST untrimmedString: ansistring): boolean;
      VAR i: longint;
          hasDot, hasExpo: boolean;
          s:ansistring;
      begin
        s:=trim(untrimmedString);
        result:=length(s)>0;
        hasDot:=false;
        hasExpo:=false;
        for i:=1 to length(s)-1 do if s [i] in ['.',','] then begin
          result:=result and not(hasDot);
          hasDot:=true;
        end else if (s [i] in ['e', 'E']) and (i>1) then begin
          result:=result and not(hasExpo);
          hasExpo:=true;
        end else result:=result and ((s [i] in ['0'..'9']) or ((i = 1) or (s [i-1] in ['e', 'E'])) and (s [i] in ['-', '+']));
      end;

    FUNCTION findDot(s: ansistring): longint;
      begin
        result:=pos('.', s); if result>0 then exit(result);
        result:=pos(',', s); if result>0 then exit(result);
        result:=UTF8Length(s)+1;
      end;

    begin
      with result do begin
        txt:=s;
        txtLength:=UTF8Length(txt);
        if isNumeric(txt) then begin
          cellType:=ctNumeric;
          posOfDot:=findDot(s);
        end else begin
          posOfDot:=txtLength+1;
          if (length(txt)>=1) and (txt[1]=C_shiftInChar) then begin
            dec(txtLength);
            txt:=copy(txt,2,length(txt)-1);
            cellType:=ctRightAlignedString;
          end else cellType:=ctLeftAlignedString;
        end;
      end;
    end;

  PROCEDURE padLeft(VAR c:TcellInfo; CONST dotPos:longint); inline;
    VAR count:longint;
    begin
      count:=dotPos-c.posOfDot;
      if count<=0 then exit;
      c.txt:=StringOfChar(' ',count)+c.txt;
      inc(c.posOfDot,count);
      inc(c.txtLength,count);
    end;

  PROCEDURE padRight(VAR c:TcellInfo; CONST targetLength:longint); inline;
    VAR count:longint;
    begin
      count:=targetLength-c.txtLength;
      if count<=0 then exit;
      c.txt:=c.txt+StringOfChar(' ',count);
      inc(c.txtLength,count);
    end;

  VAR matrix: array of array of TcellInfo;
      i, j, maxJ, maxLength, dotPos: longint;
      anyTab:boolean=false;
      anyInvisibleTab:boolean=false;
      tmp:T_arrayOfString;

  begin
    for i:=0 to length(s)-1 do begin
      anyTab         :=anyTab           or (pos(C_tabChar         ,s[i])>0);
      anyInvisibleTab:=anyInvisibleTab  or (pos(C_invisibleTabChar,s[i])>0);
    end;
    if not(anyTab or anyInvisibleTab) then exit(s);

    result:=s;
    setLength(matrix,length(result));
    if anyInvisibleTab then begin
      if anyTab then
      for i:=0 to length(result)-1 do result[i]:=replaceAll(result[i],C_tabChar         ,' '+C_tabChar);
      for i:=0 to length(result)-1 do result[i]:=replaceAll(result[i],C_invisibleTabChar,    C_tabChar);
    end;
    j:=-1;
    maxJ:=-1;
    for i:=0 to length(result)-1 do begin
      tmp:=split(result[i],C_tabChar);
      setLength(matrix[i],length(tmp));
      for j:=0 to length(tmp)-1 do matrix[i][j]:=infoFromString(tmp[j]);
      j:=length(matrix[i])-1;
      if j>maxJ then maxJ:=j;
    end;
    //expand columns to equal size:
    for j:=0 to maxJ do begin
      //Align numeric cells at decimal point
      dotPos:=0;
      for i:=0 to length(matrix)-1 do if (length(matrix[i])>j) and (matrix[i][j].cellType=ctNumeric) and (matrix[i][j].posOfDot>dotPos) then dotPos:=matrix[i][j].posOfDot;
      if dotPos>0 then
      for i:=0 to length(matrix)-1 do if (length(matrix[i])>j) and (matrix[i][j].cellType=ctNumeric) then padLeft(matrix[i][j],dotPos);
      //Expand cells to equal width
      if j<maxJ then begin //skip last column 'cause it will be trimmed right anyway
        maxLength:=0;
        for i:=0 to length(matrix)-1 do if (length(matrix[i])>j) and (matrix[i][j].txtLength>maxLength) then maxLength:=matrix[i][j].txtLength;
        if not(anyInvisibleTab) then inc(maxLength);
        for i:=0 to length(matrix)-1 do if (length(matrix[i])>j) then begin
          if matrix[i][j].cellType=ctRightAlignedString
          then padLeft (matrix[i][j],maxLength+1);
          padRight(matrix[i][j],maxLength);
        end;
      end;
    end;
    //join matrix to result;
    for i:=0 to length(matrix)-1 do begin
      result[i]:='';
      for j:=0 to length(matrix[i])-1 do result[i]:=result[i]+matrix[i][j].txt;
      setLength(matrix[i],0);
      result[i]:=trimRight(result[i]);
    end;
    setLength(matrix,0);
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

FUNCTION escapeString(CONST s: ansistring; CONST style:T_escapeStyle): ansistring;
  CONST javaEscapes:array[0..7,0..1] of char=(('\','\'),(#8 ,'b'),(#9 ,'t'),(#10,'n'),(#11,'v'),(#12,'f'),(#13,'r'),('"','"'));
        javaEscapable:T_charSet=[#8,#9,#10,#11,#12,#13];
  FUNCTION containsJavaEscapable:boolean;
    VAR c:char;
    begin
      for c in s do if c in javaEscapable then exit(true);
      result:=false;
    end;

  FUNCTION pascalStyle:ansistring;
    CONST DELIM='''';
    begin
      result:=DELIM+replaceAll(s,DELIM,DELIM+DELIM)+DELIM;
    end;

  FUNCTION strictPascalStyle:ansistring;
    CONST DELIM='''';
    VAR nonAsciiChars:set of char=[];
        c:char;
        nonAsciiMode:boolean=true;
    begin
      for c in s do if (c<#32) or (c>#126) then include(nonAsciiChars,c);
      if nonAsciiChars=[] then exit(pascalStyle);
      result:='';
      for c in s do if (c in nonAsciiChars) then begin
        if not(nonAsciiMode) then result:=result+DELIM;
        nonAsciiMode:=true;
        result:=result+'#'+intToStr(ord(c))
      end else if c=DELIM then begin
        if nonAsciiMode then result:=result+'#39'
                        else result:=result+DELIM+DELIM;
      end else begin
        if nonAsciiMode then result:=result+DELIM;
        nonAsciiMode:=false;
        result:=result+c;
      end;
      if not(nonAsciiMode) then result:=result+DELIM;
    end;

  FUNCTION javaStyle:ansistring;
    VAR i:longint;
    begin
      result:=s;
      for i:=0 to length(javaEscapes)-1 do result:=replaceAll(result,javaEscapes[i,0],'\'+javaEscapes[i,1]);
      result:='"'+result+'"';
    end;

  VAR tmp:ansistring;
  begin
    result:='';
    case style of
      es_javaStyle        : exit(javaStyle);
      es_mnhPascalStyle   : exit(pascalStyle);
      es_strictPascalStyle: exit(strictPascalStyle);
      es_pickShortest     : begin
        tmp:=javaStyle;
        if containsJavaEscapable then exit(tmp);
        result:=pascalStyle;
        if length(tmp)<length(result) then result:=tmp;
      end;
      es_dontCare         : if containsJavaEscapable then exit(javaStyle)
                                                     else exit(pascalStyle);
    end;
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
      i0:=offset+1; i:=i0; i1:=offset; continue:=true; result:='';
      if input[offset]=SQ then begin
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
        result:=result+unescapeString(input,offset+parsedLength,i1);
        inc(parsedLength,i1);
        exit(result);
      end else if input[offset]=DQ then begin
        while (i<=length(input)) and (input[i]<>DQ) do if input[i]='\' then begin
          if (i<length(input)) then begin
            case input[i+1] of
              'b': result:=result+copy(input,i0,i1-i0+1)+#8  ;
              't': result:=result+copy(input,i0,i1-i0+1)+#9  ;
              'n': result:=result+copy(input,i0,i1-i0+1)+#10 ;
              'v': result:=result+copy(input,i0,i1-i0+1)+#11 ;
              'f': result:=result+copy(input,i0,i1-i0+1)+#12 ;
              'r': result:=result+copy(input,i0,i1-i0+1)+#13 ;
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
        result:=result+unescapeString(input,offset+parsedLength,i1);
        inc(parsedLength,i1);
        exit(result);
      end else if input[offset]='#' then begin
        i:=offset+1;
        while (i<length(input)) and (input[i+1] in ['0'..'9']) do inc(i);
        result:=copy(input,offset+1,i-offset);
        i0:=strToIntDef(result,256);
        if (i0<0) or (i0>255)
        then exitFailing
        else begin
          result:=chr(i0);
          parsedLength:=i-offset+1;
          result:=result+unescapeString(input,offset+parsedLength,i1);
          inc(parsedLength,i1);
          exit(result);
        end;
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

PROCEDURE collectIdentifiers(CONST s:ansistring; VAR list:T_setOfString; CONST skipWordAtPosition:longint);
  VAR i,i0:longint;
  begin
    i:=1;
    while i<=length(s) do begin
      if s[i] in ['a'..'z','A'..'Z'] then begin
        i0:=i;
        while (i<=length(s)) and (s[i] in IDENTIFIER_CHARS) do inc(i);
        if not((i0<=skipWordAtPosition) and (i>=skipWordAtPosition)) then list.put(copy(s,i0,i-i0));
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
    append(lineSplitters,                C_lineBreakChar+C_carriageReturnChar);
    append(lineSplitters,                C_lineBreakChar);
    result:=split(s,lineSplitters);
  end;

FUNCTION reSplit(CONST s:T_arrayOfString):T_arrayOfString;
  VAR i:longint;
  begin
    setLength(result,0);
    for i:=0 to length(s)-1 do append(result,split(s[i]));
  end;

FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString):T_arrayOfString;
  PROCEDURE nextSplitterPos(CONST startSearchAt:longint; OUT splitterStart,splitterEnd:longint); inline;
    VAR splitter:string;
        firstSplitterChar:char;
        thisSplitterFound:boolean;
        i:longint;
    begin
      splitterStart:=length(s)+1;
      splitterEnd:=splitterStart;
      for splitter in splitters do if length(splitter)>0 then begin
        firstSplitterChar:=splitter[1];
        thisSplitterFound:=false;
        i:=startSearchAt;
        if length(splitter)=1 then begin
          while (i<splitterStart) and not(thisSplitterFound) do begin
            if (s[i]=firstSplitterChar) then begin
              thisSplitterFound:=true;
              splitterStart:=i;
              splitterEnd:=i+1;
            end;
            inc(i);
          end;
        end else begin
          while (i<splitterStart) and not(thisSplitterFound) do begin
            if (s[i]=firstSplitterChar) and (copy(s,i,length(splitter))=splitter) then begin
              thisSplitterFound:=true;
              splitterStart:=i;
              splitterEnd:=i+length(splitter);
            end;
            inc(i);
          end;
        end;
      end;
    end;

  VAR resultLen:longint=0;
  PROCEDURE appendToResult(CONST part:string); inline;
    begin
      if length(result)<resultLen+1 then setLength(result,round(length(result)*1.1)+2);
      result[resultLen]:=part;
      inc(resultLen);
    end;

  VAR partStart:longint=1;
      splitterStart,splitterEnd:longint;
      endsOnSplitter:boolean=false;
  begin
    setLength(result,0);
    nextSplitterPos(partStart,splitterStart,splitterEnd);
    endsOnSplitter:=splitterEnd>splitterStart;
    while(partStart<=length(s)) do begin
      appendToResult(copy(s,partStart,splitterStart-partStart));
      partStart:=splitterEnd;
      endsOnSplitter:=splitterEnd>splitterStart;
      nextSplitterPos(partStart,splitterStart,splitterEnd);
    end;
    if endsOnSplitter then appendToResult('');
    setLength(result,resultLen);
  end;

FUNCTION join(CONST lines:T_arrayOfString; CONST joiner:ansistring):ansistring;
  VAR i:longint;
      k:longint=0;
      hasJoiner:boolean;
  begin
    if length(lines)=0 then exit('');
    hasJoiner:=length(joiner)>0;
    for i:=0 to length(lines)-1 do inc(k,length(lines[i]));
    inc(k,length(joiner)*(length(lines)-1));
    setLength(result,k);
    k:=1;
    if length(lines[0])>0 then begin
      move(lines[0][1],result[k],length(lines[0]));
      inc(k,length(lines[0]));
    end;
    if hasJoiner then for i:=1 to length(lines)-1 do begin
      move(joiner  [1],result[k],length(joiner  )); inc(k,length(joiner  ));
      if length(lines[i])>0 then begin
        move(lines[i][1],result[k],length(lines[i])); inc(k,length(lines[i]));
      end;
    end else for i:=1 to length(lines)-1 do begin
      if length(lines[i])>0 then begin
        move(lines[i][1],result[k],length(lines[i])); inc(k,length(lines[i]));
      end;
    end
  end;

FUNCTION cleanString(CONST s:ansistring; CONST whiteList:T_charSet; CONST instead:char):ansistring;
  VAR k:longint;
      tmp:shortstring;
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

FUNCTION encoding(CONST s: ansistring):T_stringEncoding;
  VAR i:longint;
      asciiOnly:boolean=true;
  begin
    if length(s)=0 then exit(se_ascii);
    i:=1;
    while i<=length(s) do begin
      // ASCII
      if (s[i] in [#$09,#$0A,#$0D,#$20..#$7E]) then begin
        inc(i);
        continue;
      end;
      asciiOnly:=false;
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
      exit(se_mixed);
    end;
    if asciiOnly then result:=se_ascii
                 else result:=se_utf8;
  end;

FUNCTION ensureSysEncoding(CONST s:ansistring):ansistring;
  begin
    if isUtf8Encoded(s) or isAsciiEncoded(s) then result:=UTF8ToWinCP(s) else result:=s;
  end;

FUNCTION ensureUtf8Encoding(CONST s:ansistring):ansistring;
  begin
    if isUtf8Encoded(s) or isAsciiEncoded(s) then result:=s else result:=WinCPToUTF8(s);
  end;

FUNCTION StripHTML(CONST S: string): string;
  VAR TagBegin, TagEnd, TagLength: integer;
  begin
    result:=s;
    TagBegin := pos( '<', result);      // search position of first <
    while (TagBegin > 0) do begin  // while there is a < in S
      TagEnd := pos('>', result);              // find the matching >
      TagEnd := PosEx('>',result,TagBegin);
      TagLength := TagEnd - TagBegin + 1;
      delete(result, TagBegin, TagLength);     // delete the tag
      TagBegin:= pos( '<', result);            // search for next <
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
      vCompressor := TCompressionStream.create(clMax, vDest,false);
      try
	vSource := TStringStream.create(ASrc);
	try     vCompressor.copyFrom(vSource, 0);
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
      vDecompressor := TDecompressionStream.create(vSource,false);
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
  PROCEDURE checkAlternative(CONST alternativeSuffix:ansistring; CONST c0:char);
    VAR alternative:ansistring;
    begin
      alternative:=c0+alternativeSuffix;
      if length(alternative)<length(result) then result:=alternative;
    end;

  begin
    case algorithm of
      1: exit(#36+gzip_compressString(src));
      2: exit(#37+huffyEncode(src));
      3: exit(#38+huffyEncode2(src));
    end;
    if length(src)=0 then exit(src);
    if src[1] in [#35..#38] then result:=#35+src
                            else result:=    src;
    if algorithm=255 then exit(result);
    checkAlternative(gzip_compressString(src),#36);
    checkAlternative(huffyEncode (src),#37);
    checkAlternative(huffyEncode2(src),#38);
  end;

FUNCTION decompressString(CONST src:ansistring):ansistring;
  begin
    if length(src)=0 then exit(src);
    case src[1] of
      #35: exit(                      copy(src,2,length(src)-1));
      #36: exit(gzip_decompressString(copy(src,2,length(src)-1)));
      #37: exit(huffyDecode(          copy(src,2,length(src)-1)));
      #38: exit(huffyDecode2(         copy(src,2,length(src)-1)));
    end;
    result:=src;
  end;

FUNCTION tokenSplit(CONST stringToSplit: ansistring; CONST language: string): T_arrayOfString;
  VAR i0,i1:longint;
      resultCount:longint=0;
  PROCEDURE stepToken;
    begin
      if length(result)<=resultCount then setLength(result,resultCount+128);
      result[resultCount]:=copy(stringToSplit,i0,i1-i0);
      inc(resultCount);
      i0:=i1;
    end;

  VAR doubleQuoteString:boolean=false;
      singleQuoteString:boolean=false;
      escapeStringDelimiter:boolean=false;
      cStyleComments:boolean=false;
      dollarVariables:boolean=false;
      commentDelimiters:array of array[0..1] of string;

  PROCEDURE parseNumber(CONST input: ansistring; CONST offset:longint; OUT parsedLength: longint);
    VAR i: longint;
    begin
      parsedLength:=0;
      if (length(input)>=offset) and (input [offset] in ['0'..'9', '-', '+']) then begin
        i:=offset;
        while (i<length(input)) and (input [i+1] in ['0'..'9']) do inc(i);
        parsedLength:=i+1-offset;
        //Only digits on indexes [1..i]; accept decimal point and following digts
        if (i<length(input)) and (input [i+1] = '.') then begin
          inc(i);
          if (i<length(input)) and (input [i+1] = '.') then dec(i);
        end;
        while (i<length(input)) and (input [i+1] in ['0'..'9']) do  inc(i);
        //Accept exponent marker and following exponent
        if (i<length(input)) and (input [i+1] in ['e', 'E']) then begin
          inc(i);
          if (i<length(input)) and (input [i+1] in ['+', '-']) then inc(i);
        end;
        while (i<length(input)) and (input [i+1] in ['0'..'9']) do inc(i);
        if i+1-offset>parsedLength then begin
          parsedLength:=i+1-offset;
        end;
      end;
    end;

  PROCEDURE setLanguage(name:string);
    PROCEDURE addCommentDelimiter(CONST opening,closing:string);
      begin
        setLength(commentDelimiters,length(commentDelimiters)+1);
        commentDelimiters[length(commentDelimiters)-1,0]:=opening;
        commentDelimiters[length(commentDelimiters)-1,1]:=closing;
      end;

    begin
      setLength(commentDelimiters,0);
      if trim(uppercase(name))='MNH' then begin
        doubleQuoteString:=true;
        singleQuoteString:=true;
        escapeStringDelimiter:=true;
        cStyleComments:=true;
        dollarVariables:=true;
      end else if trim(uppercase(name))='JAVA' then begin
        addCommentDelimiter('/**','*/');
        addCommentDelimiter('/*','*/');
        doubleQuoteString:=true;
        singleQuoteString:=true;
        escapeStringDelimiter:=true;
        cStyleComments:=true;
      end else if trim(uppercase(name))='PASCAL' then begin
        addCommentDelimiter('{','}');
        addCommentDelimiter('(*','*)');
        doubleQuoteString:=false;
        singleQuoteString:=true;
        escapeStringDelimiter:=false;
        cStyleComments:=true;
      end;
    end;

  FUNCTION readComment:boolean;
    VAR i,nextOpen,nextClose:longint;
        depth:longint=1;
    begin
      for i:=0 to length(commentDelimiters)-1 do
      if copy(stringToSplit,i0,length(commentDelimiters[i,0]))=commentDelimiters[i,0]
      then begin
        i1:=i0+length(commentDelimiters[i,0]);
        while (depth>0) and (i1<length(stringToSplit)) do begin
          nextOpen :=PosEx(commentDelimiters[i,0],stringToSplit,i1); if nextOpen <=0 then nextOpen :=maxLongint;
          nextClose:=PosEx(commentDelimiters[i,1],stringToSplit,i1); if nextClose<=0 then nextClose:=maxLongint;
          if (nextOpen=nextClose) then begin
            exit(true);
          end else if (nextOpen<nextClose) then begin
            inc(depth);
            i1:=nextOpen+length(commentDelimiters[i,0]);
          end else begin
            dec(depth);
            i1:=nextClose+length(commentDelimiters[i,1]);
          end;
        end;
        if i1>length(stringToSplit)+1 then i1:=length(stringToSplit)+1;
        exit(true);
      end;
      result:=false;
    end;

  begin
    setLanguage(language);
    setLength(result,0);
    i0:=1;
    while i0<=length(stringToSplit) do begin
      if stringToSplit[i0] in [' ',C_lineBreakChar,C_carriageReturnChar,C_tabChar] then begin //whitespace
        i1:=i0;
        while (i1<=length(stringToSplit)) and (stringToSplit[i1] in [' ',C_lineBreakChar,C_carriageReturnChar,C_tabChar]) do inc(i1);
      end else if readComment then begin
      end else if (stringToSplit[i0]='''') and singleQuoteString or
                  (stringToSplit[i0]='"') and doubleQuoteString then begin
        if escapeStringDelimiter then begin
          unescapeString(copy(stringToSplit,i0,length(stringToSplit)-i0+1),1,i1);
          if i1<=0 then i1:=i0+1
                   else i1:=i0+i1;
        end else begin
          i1:=i0+1;
          while (i1<=length(stringToSplit)) and (stringToSplit[i1]<>stringToSplit[i0]) do inc(i1);
          inc(i1);
        end;
      end else if (stringToSplit[i0] in ['(',')','[',']','{','}']) then begin
        i1:=i0+1;
      end else if (copy(stringToSplit,i0,2)='//') and cStyleComments then begin
        i1:=i0+1;
        while (i1<=length(stringToSplit)) and not(stringToSplit[i1] in [C_lineBreakChar,C_carriageReturnChar]) do inc(i1);
      end else if (stringToSplit[i0] in ['a'..'z','A'..'Z']) or (stringToSplit[i0]='$') and dollarVariables then begin
        i1:=i0+1;
        while (i1<=length(stringToSplit)) and (stringToSplit[i1] in ['a'..'z','A'..'Z','_','0'..'9']) do inc(i1);
      end else if stringToSplit[i0] in ['0'..'9'] then begin //numbers
        parseNumber(stringToSplit,i0,i1);
        if i1<=0 then i1:=i0
                 else i1:=i0+i1;
      end else begin
        i1:=i0;
        while (i1<=length(stringToSplit)) and (stringToSplit[i1] in ['+','-','*','/','?',':','=','<','>','!','%','&','|']) do inc(i1);
        if i1=i0 then i1:=i0+1;
      end;
      stepToken;
    end;
    setLength(result,resultCount);
  end;

FUNCTION anistringInfo(VAR s:ansistring):string;
  begin
    result:=IntToHex(ptrint  (pointer(s)-24) ,16)
       +' '+IntToHex(PByte   (pointer(s)-24)^,2)
       +' '+IntToHex(PByte   (pointer(s)-23)^,2)
       +' '+IntToHex(PByte   (pointer(s)-22)^,2)
       +' '+IntToHex(PByte   (pointer(s)-21)^,2)
       +' '+intToStr(plongint(pointer(s)-20)^)
       +' '+intToStr(PInt64  (pointer(s)-16)^)
       +' '+intToStr(PInt64  (pointer(s)- 8)^)
       +' '+s;
  end;

FUNCTION typingSimilarity(CONST s1,s2:shortstring):longint;
  VAR i:longint=1;
      j:longint=1;
  begin
    result:=0;
    while (i<=length(s1)) and (j<=length(s2)) do begin
      //matching character: +4
      if                s1[i]=           s2[j]  then begin inc(result,4); inc(i); inc(j); end
      //character in wrong case: +2
      else if uppercase(s1[i])=uppercase(s2[j]) then begin inc(result,2); inc(i); inc(j); end
      //mismatch: -1
      else begin dec(result); inc(j); end;
    end;
    //mismatches, because s2 is too short
    dec(result,length(s1)+1-i);
    //Ignore mismatches due to too short s1; we are typing s1
  end;

PROCEDURE sortByTypingSimilarity(target:shortstring; VAR list:T_arrayOfString);
  VAR temp1,temp2:array of record similarity:longint; s:string; end;
      scale:longint=1;
      i,j0,j1,k:longint;
  begin
    setLength(temp1,length(list));
    i:=0;
    for k:=0 to length(list)-1 do begin
      temp1[i].s:=list[k];
      temp1[i].similarity:=typingSimilarity(target,list[k]);
      if temp1[i].similarity>=0 then inc(i);
    end;
    setLength(temp1,i);
    setLength(temp2,i);
    setLength(list ,i);
    while scale<length(list) do begin
      //merge lists of size [scale] to lists of size [scale+scale]:---------------
      i:=0;
      while i<length(list) do begin
        j0:=i;
        j1:=i+scale;
        k :=i;
        while (j0<i+scale) and (j1<i+scale+scale) and (j1<length(list)) do begin
          if (temp1[j0].similarity>=temp1[j1].similarity)
          then begin temp2[k]:=temp1[j0]; inc(k); inc(j0); end
          else begin temp2[k]:=temp1[j1]; inc(k); inc(j1); end;
        end;
        while (j0<i+scale)       and (j0<length(list)) do begin temp2[k]:=temp1[j0]; inc(k); inc(j0); end;
        while (j1<i+scale+scale) and (j1<length(list)) do begin temp2[k]:=temp1[j1]; inc(k); inc(j1); end;
        inc(i,scale+scale);
      end;
      //---------------:merge lists of size [scale] to lists of size [scale+scale]
      inc(scale,scale);
      if (scale<length(list)) then begin
        //The following is equivalent to the above with swapped roles of "list" and "temp".
        //while making the code a little more complicated it avoids unnecessary copys.
        //merge lists of size [scale] to lists of size [scale+scale]:---------------
        i:=0;
        while i<length(list) do begin
          j0:=i;
          j1:=i+scale;
          k :=i;
          while (j0<i+scale) and (j1<i+scale+scale) and (j1<length(list)) do begin
            if (temp2[j0].similarity>=temp2[j1].similarity)
            then begin temp1[k]:=temp2[j0]; inc(k); inc(j0); end
            else begin temp1[k]:=temp2[j1]; inc(k); inc(j1); end;
          end;
          while (j0<i+scale)       and (j0<length(list)) do begin temp1[k]:=temp2[j0]; inc(k); inc(j0); end;
          while (j1<i+scale+scale) and (j1<length(list)) do begin temp1[k]:=temp2[j1]; inc(k); inc(j1); end;
          inc(i,scale+scale);
        end;
        //---------------:merge lists of size [scale] to lists of size [scale+scale]
        inc(scale,scale);
      end else begin
        for k:=0 to length(list)-1 do begin
          if temp2[k].similarity=0 then begin
            setLength(list,k);
            exit;
          end;
          list[k]:=temp2[k].s;
        end;
        exit;
      end;
    end;
    for k:=0 to length(list)-1 do begin
      if temp1[k].similarity=0 then begin
        setLength(list,k);
        exit;
      end;
      list[k]:=temp1[k].s;
    end;
  end;

end.
