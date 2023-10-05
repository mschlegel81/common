UNIT myStringUtil;

INTERFACE
USES math, strutils, sysutils,  myGenerics, zstream, Classes, huffman, LazUTF8;

TYPE T_charSet=set of char;
     T_byteSet=set of byte;
     T_escapeStyle=(es_javaStyle,es_mnhPascalStyle,es_pickShortest,es_dontCare);
     T_stringEncoding=(se_testPending,se_ascii,se_utf8,se_mixed);
CONST
  C_backspaceChar     =  #8;
  C_tabChar           =  #9;
  C_lineBreakChar     = #10;
  C_invisibleTabChar  = #11;
  C_formFeedChar      = #12;
  C_carriageReturnChar= #13;
  C_shiftOutChar      = #14;
  C_shiftInChar       = #15;

  C_compression_gzip             :byte=1;
  C_compression_huffman_default  :byte=2;
  C_compression_huffman_lucky    :byte=3;
  C_compression_huffman_numbers  :byte=4;
  C_compression_huffman_wikipedia:byte=5;
  C_compression_huffman_mnh      :byte=6;

  BLANK_TEXT = '';
  IDENTIFIER_CHARS:T_charSet=['a'..'z','A'..'Z','0'..'9','.','_'];

FUNCTION canonicalFileName(CONST s:string):string;
FUNCTION formatTabs(CONST s: T_arrayOfString): T_arrayOfString;
FUNCTION isBlank(CONST s: ansistring): boolean;
FUNCTION replaceRecursively(CONST original, lookFor, replaceBy: ansistring; OUT isValid: boolean): ansistring; inline;
FUNCTION replaceOne(CONST original, lookFor, replaceBy: ansistring): ansistring; inline;
FUNCTION escapeString(CONST s: ansistring; CONST style:T_escapeStyle; enc:T_stringEncoding; OUT nonescapableFound:boolean): ansistring;
FUNCTION unescapeString(CONST input: ansistring; CONST offset:longint; OUT parsedLength: longint): ansistring;
FUNCTION isIdentifier(CONST s: ansistring; CONST allowDot: boolean): boolean;
FUNCTION isFilename(CONST s: ansistring; CONST acceptedExtensions:array of string):boolean;
PROCEDURE collectIdentifiers(CONST s:ansistring; VAR list:T_setOfString; CONST skipWordAtPosition:longint);
FUNCTION startsWith(CONST input, head: ansistring): boolean;
FUNCTION endsWith(CONST input, tail: ansistring): boolean;
FUNCTION unbrace(CONST s:ansistring):ansistring;
FUNCTION split(CONST s:ansistring):T_arrayOfString;
FUNCTION reSplit(CONST s:T_arrayOfString):T_arrayOfString;
FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString; CONST retainSplitters:boolean=false):T_arrayOfString;
FUNCTION splitCommandLine(CONST s:ansistring):T_arrayOfString;
FUNCTION join(CONST lines:T_arrayOfString; CONST joiner:ansistring):ansistring;
FUNCTION cleanString(CONST s:ansistring; CONST whiteList:T_charSet; CONST instead:char):ansistring;
FUNCTION myTimeToStr(dt:double; CONST useSecondsIfLessThanOneMinute:boolean=true):string;
FUNCTION isAsciiEncoded(CONST s: ansistring): boolean;
FUNCTION isUtf8Encoded(CONST s: ansistring): boolean;
FUNCTION encoding(CONST s: ansistring):T_stringEncoding;
FUNCTION StripHTML(CONST S: string): string;
FUNCTION ensureSysEncoding(CONST s:ansistring):ansistring;
FUNCTION ensureUtf8Encoding(CONST s:ansistring):ansistring;

FUNCTION compressString(CONST src: ansistring; CONST algorithmsToConsider:T_byteSet):ansistring;
FUNCTION decompressString(CONST src:ansistring):ansistring;
FUNCTION tokenSplit(CONST stringToSplit:ansistring; CONST language:string='MNH'):T_arrayOfString;
FUNCTION ansistringInfo(VAR s:ansistring):string;
FUNCTION getListOfSimilarWords(CONST typedSoFar:string; CONST completionList:T_arrayOfString; CONST targetResultSize:longint; CONST ignorePosition:boolean):T_arrayOfString;

FUNCTION percentEncode(CONST s:string):string;
FUNCTION percentDecode(CONST s:string):string;

FUNCTION base92Encode(CONST src:ansistring):ansistring;
FUNCTION base92Decode(CONST src:ansistring):ansistring;

FUNCTION shortcutToString(CONST ShortCut:word):string;

IMPLEMENTATION
USES LCLType;

FUNCTION canonicalFileName(CONST s:string):string;
  VAR isValidDummy:boolean;
  begin
    result:=ansiReplaceStr(replaceRecursively(ansiReplaceStr(expandFileName(s),'\','/'),'//','/',isValidDummy),'/',DirectorySeparator);
    if result[length(result)]=DirectorySeparator then result:=copy(result,1,length(result)-1);
  end;

FUNCTION TrimRightRetainingSpecials(CONST S: string): string;
  CONST MY_WHITESPACE:T_charSet=[#0..#7,#16..' '];
  VAR l:integer;
  begin
    l := length(s);
    while (l>0) and (s[l] in MY_WHITESPACE) do
     dec(l);
    result := copy(s,1,l);
  end ;

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

  VAR matrix: array of array of TcellInfo=();
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
      for i:=0 to length(result)-1 do result[i]:=ansiReplaceStr(result[i],C_tabChar         ,' '+C_tabChar);
      for i:=0 to length(result)-1 do result[i]:=ansiReplaceStr(result[i],C_invisibleTabChar,    C_tabChar);
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
      result[i]:=TrimRightRetainingSpecials(result[i]);
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

FUNCTION replaceRecursively(CONST original, lookFor, replaceBy: ansistring; OUT isValid: boolean): ansistring; inline;
  VAR prev:ansistring;
  begin
    if pos(lookFor, replaceBy)>0 then begin
      isValid:=false;
      exit(ansiReplaceStr(original, lookFor, replaceBy));
    end else begin
      isValid:=true;
      result:=original;
      repeat
        prev:=result;
        result:=ansiReplaceStr(prev,lookFor,replaceBy);
      until prev=result;
    end;
  end;

FUNCTION escapeString(CONST s: ansistring; CONST style:T_escapeStyle; enc:T_stringEncoding; OUT nonescapableFound:boolean): ansistring;
  CONST javaEscapes:array[0..9,0..1] of char=(('\','\'),(C_backspaceChar ,'b'),
                                              (C_tabChar ,'t'),
                                              (C_lineBreakChar,'n'),
                                              (C_invisibleTabChar,'v'),
                                              (C_formFeedChar,'f'),
                                              (C_carriageReturnChar,'r'),
                                              (C_shiftInChar,'i'),
                                              (C_shiftOutChar,'o'),
                                              ('"','"'));
        javaEscapable:T_charSet=[C_backspaceChar,C_tabChar,C_lineBreakChar,C_invisibleTabChar,C_formFeedChar,C_carriageReturnChar,C_shiftInChar,C_shiftOutChar];
  FUNCTION isJavaEscapable:boolean;
    VAR c:char;
    begin
      if enc=se_testPending then enc:=encoding(s);
      for c in s do if (c<#32) and not(c in javaEscapable) or ((enc<>se_utf8) and (c>#127)) then exit(false);
      result:=true;
    end;

  FUNCTION pascalStyle:ansistring;
    CONST DELIM='''';
    begin
      result:=DELIM+ansiReplaceStr(s,DELIM,DELIM+DELIM)+DELIM;
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
      for i:=0 to length(javaEscapes)-1 do result:=ansiReplaceStr(result,javaEscapes[i,0],'\'+javaEscapes[i,1]);
      result:='"'+result+'"';
    end;

  VAR tmp:ansistring;
  begin
    result:='';
    nonescapableFound:=false;
    case style of
      es_javaStyle: begin
        nonescapableFound:=not(isJavaEscapable);
        exit(javaStyle);
      end;
      es_mnhPascalStyle: exit(strictPascalStyle);
      es_pickShortest  : begin
        if isJavaEscapable then begin
          tmp:=javaStyle;
          result:=strictPascalStyle;
          if (length(tmp)<length(result)) then result:=tmp;
        end else result:=strictPascalStyle;
      end;
      es_dontCare: if isJavaEscapable then exit(javaStyle)
                                      else exit(strictPascalStyle);
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
    result:=(length(s)>=1) and (s[1] in ['a'..'z', 'A'..'Z', '_']);
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
    initialize(result);
    setLength(result,0);
    for i:=0 to length(s)-1 do append(result,split(s[i]));
  end;

FUNCTION split(CONST s:ansistring; CONST splitters:T_arrayOfString; CONST retainSplitters:boolean=false):T_arrayOfString;
  PROCEDURE nextSplitterPos(CONST startSearchAt:longint; OUT splitterStart,splitterEnd:longint); inline;
    VAR splitter:string;
        i:longint;
    begin
      splitterStart:=length(s)+1;
      splitterEnd:=splitterStart;
      for splitter in splitters do if length(splitter)>0 then begin
        i:=PosEx(splitter,s,startSearchAt);
        if (i>0) and (i<splitterStart) then begin
          splitterStart:=i;
          splitterEnd:=i+length(splitter);
        end;
      end;
    end;

  VAR resultLen:longint=0;
  PROCEDURE appendToResult(CONST part:string); inline;
    begin
      if length(result)<resultLen+1 then setLength(result,round(length(result)*1.2)+2);
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
      if endsOnSplitter and retainSplitters then appendToResult(copy(s,splitterStart,splitterEnd-splitterStart));
      nextSplitterPos(partStart,splitterStart,splitterEnd);
    end;
    if endsOnSplitter and not retainSplitters then appendToResult('');
    setLength(result,resultLen);
  end;

FUNCTION splitCommandLine(CONST s:ansistring):T_arrayOfString;
  VAR parseIndex:longint=1;
      k:longint;
  begin
    initialize(result);
    setLength(result,0);
    while parseIndex<=length(s) do case s[parseIndex] of
      ' ': inc(parseIndex);
      '"': begin
             append(result,unescapeString(s,parseIndex,k));
             if k<=0 then inc(parseIndex) else inc(parseIndex,k);
           end;
      else begin
        k:=parseIndex;
        while (k<=length(s)) and (s[k]<>' ') do inc(k);
        append(result,copy(s,parseIndex,k-parseIndex));
        parseIndex:=k+1;
      end;
    end;
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

FUNCTION myTimeToStr(dt:double; CONST useSecondsIfLessThanOneMinute:boolean=true):string;
  CONST oneMinute=1/(24*60);
        oneSecond=oneMinute/60;
  begin
    if (dt<oneMinute) and useSecondsIfLessThanOneMinute
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

FUNCTION gzip_decompressString(CONST ASrc:ansistring):ansistring;
  VAR vDest: TStringStream;
      vSource: TStream;
      vDecompressor: TDecompressionStream;
  begin
    result:='';
    vSource := TMemoryStream.create;
    try
      vSource.write(ASrc[1], length(ASrc));
      vSource.position := 0;
      vDecompressor := TDecompressionStream.create(vSource,false);
      try
	vDest := TStringStream.create('');
        vDest.copyFrom(vDecompressor,0);
	vDest.position := 0;
	result := vDest.DataString;
	vDest.free;
      finally
	vDecompressor.free;
      end;
    finally
      vSource.free;
    end;
  end;

FUNCTION compressString(CONST src: ansistring; CONST algorithmsToConsider:T_byteSet):ansistring;
  PROCEDURE checkAlternative(CONST alternativeSuffix:ansistring; CONST c0:char);
    VAR alternative:ansistring;
    begin
      alternative:=c0+alternativeSuffix;
      if length(alternative)<length(result) then result:=alternative;
    end;

  begin
    if length(src)=0 then exit(src);
    if src[1] in [#1..#4,#35..#38] then result:=#35+src
                                   else result:=    src;
    if 1 in algorithmsToConsider then checkAlternative(gzip_compressString(src),#36);
    if 2 in algorithmsToConsider then checkAlternative(huffyEncode(src,hm_DEFAULT  ),#37);
    if 3 in algorithmsToConsider then checkAlternative(huffyEncode(src,hm_LUCKY    ),#38);
    if 4 in algorithmsToConsider then checkAlternative(huffyEncode(src,hm_NUMBERS  ),#1);
    if 5 in algorithmsToConsider then checkAlternative(huffyEncode(src,hm_WIKIPEDIA),#2);
    if 6 in algorithmsToConsider then checkAlternative(huffyEncode(src,hm_MNH      ),#3);
  end;

FUNCTION decompressString(CONST src:ansistring):ansistring;
  begin
    if length(src)=0 then exit(src);
    case src[1] of
      #35: exit(                      copy(src,2,length(src)-1));
      #36: exit(gzip_decompressString(copy(src,2,length(src)-1)));
      #37: exit(huffyDecode(          copy(src,2,length(src)-1),hm_DEFAULT  ));
      #38: exit(huffyDecode(          copy(src,2,length(src)-1),hm_LUCKY    ));
       #1: exit(huffyDecode(          copy(src,2,length(src)-1),hm_NUMBERS  ));
       #2: exit(huffyDecode(          copy(src,2,length(src)-1),hm_WIKIPEDIA));
       #3: exit(huffyDecode(          copy(src,2,length(src)-1),hm_MNH      ));
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

FUNCTION ansistringInfo(VAR s:ansistring):string;
  begin
    try
    result:=IntToHex(ptrint  (pointer(s)-24) ,16)
       +' '+IntToHex(PByte   (pointer(s)-24)^,2)
       +' '+IntToHex(PByte   (pointer(s)-23)^,2)
       +' '+IntToHex(PByte   (pointer(s)-22)^,2)
       +' '+IntToHex(PByte   (pointer(s)-21)^,2)
       +' '+intToStr(plongint(pointer(s)-20)^)
       +' '+intToStr(PInt64  (pointer(s)-16)^)
       +' '+intToStr(PInt64  (pointer(s)- 8)^)
       +' '+s;
    except
      result:=IntToHex(ptrint  (pointer(s)-24) ,16)+' <?!?> '+s;
    end;
  end;

FUNCTION getListOfSimilarWords(CONST typedSoFar:string; CONST completionList:T_arrayOfString; CONST targetResultSize:longint; CONST ignorePosition:boolean):T_arrayOfString;
  CONST BUCKET_COUNT=32;
  VAR i:longint;
      j:longint=0;
      s:string;
      typedUpper:string;
      buckets:array of T_arrayOfString=();
  PROCEDURE putToBucket(CONST match:string; CONST dist,uppercaseDist:longint);
    VAR bin:longint=BUCKET_COUNT;
    begin
      if dist>0 then begin
        if uppercaseDist>0
        then bin:=min(dist,uppercaseDist)-1
        else bin:=dist-1;
      end else if uppercaseDist>0 then bin:=uppercaseDist-1;
      if bin>=BUCKET_COUNT then exit;
      append(buckets[bin],match);
    end;

  begin
    if typedSoFar='' then exit(completionList);
    setLength(result,targetResultSize);
    if ignorePosition then begin
      for s in completionList do if (pos(uppercase(typedSoFar),uppercase(s))>0) then begin
        result[j]:=s;
        inc(j);
        if j>=targetResultSize then exit(result);
      end;
    end else begin
      typedUpper:=uppercase(typedSoFar);
      setLength(buckets,BUCKET_COUNT);
      for i:=0 to length(buckets)-1 do buckets[i]:=C_EMPTY_STRING_ARRAY;
      for s in completionList do
        putToBucket(s,pos(typedSoFar,s)
                   ,2*pos(typedUpper,uppercase(s)));
      j:=0;
      for i:=0 to BUCKET_COUNT-1 do for s in buckets[i] do begin;
        result[j]:=s;
        inc(j);
        if j>=targetResultSize then exit(result);
      end;
    end;
    setLength(result,j);
  end;

FUNCTION percentCode(CONST c:byte):string;
  CONST hexDigit:array[0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  begin
    result:='%'+hexDigit[c shr 4]+hexDigit[c and 15];
  end;

FUNCTION percentEncode(CONST s:string):string;
  VAR c:char;
  begin
    result:='';
    for c in s do if c in ['A'..'Z','a'..'z','0'..'9','-','_'] then result:=result+c else result:=result+percentCode(ord(c));
  end;

FUNCTION percentDecode(CONST s:string):string;
  VAR c:byte;
  begin
    result:=s;
    for c:=0 to 255 do result:=ansiReplaceStr(result,percentCode(c),chr(c));
  end;

FUNCTION base92Encode(CONST src:ansistring):ansistring;
  VAR k:longint;

  FUNCTION encodeQuartet(CONST startIdx:longint):string;
    CONST CODE92:array[0..91] of char=('!','"','#','$','%','&','(',')','*','+',',','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_','`','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}');
    VAR i:longint;
        j:byte;
        value:int64=0;
    begin
      for i:=3 downto 0 do if startIdx+i<=length(src)
      then value:=value*257+ord(src[startIdx+i])
      else value:=value*257+256;

      setLength(result,5);
      for i:=0 to 4 do begin
        j:=value mod 92; value:=value div 92;
        result[i+1]:=CODE92[j];
      end;
    end;

  begin
    result:='';
    k:=1;
    while k<=length(src) do begin
      result:=result+encodeQuartet(k);
      inc(k,4);
    end;
  end;

FUNCTION base92Decode(CONST src:ansistring):ansistring;
  VAR oneNum:int64;
      i,j,k:longint;
  CONST coded:T_charSet=['!'..'&','('..'}'];

  FUNCTION nextNum:longint;
    CONST DECODE92:array['!'..'}'] of byte=(0,1,2,3,4,5,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91);
    begin
      inc(i);
      while (i<=length(src)) and not(src[i] in coded) do inc(i);
      if i>length(src) then exit(91)
      else result:=DECODE92[src[i]];
    end;

  begin
    result:='';
    i:=0;
    while i<length(src) do begin
      oneNum:=nextNum;
      oneNum:=oneNum+int64(92      )*nextNum;
      oneNum:=oneNum+int64(8464    )*nextNum;
      oneNum:=oneNum+int64(778688  )*nextNum;
      oneNum:=oneNum+int64(71639296)*nextNum;
      for j:=0 to 3 do begin
        k:=oneNum mod 257; oneNum:=oneNum div 257;
        if (k<256) and (k>=0) then result:=result+chr(k);
      end;
      while (i<length(src)) and not(src[i+1] in coded) do inc(i);
    end;
  end;

FUNCTION shortcutToString(CONST ShortCut:word):string;
  begin
    if ShortCut and scMeta >0 then result:='Meta+' else result:='';
    if ShortCut and scShift>0 then result+='Shift+';
    if ShortCut and scCtrl >0 then result+='Ctrl+';
    if ShortCut and scAlt  >0 then result+='Alt+';
    if chr(ShortCut and 255) in ['0'..'9','A'..'Z'] then exit(result+chr(ShortCut and 255));
    if (ShortCut and 255)=0            then exit('');
    if (ShortCut and 255)=VK_OEM_PLUS  then exit(result+'(+)');
    if (ShortCut and 255)=VK_OEM_MINUS then exit(result+'(-)');
    if (ShortCut and 255)=VK_F1        then exit(result+'F1');
    if (ShortCut and 255)=VK_F2        then exit(result+'F2');
    if (ShortCut and 255)=VK_F3        then exit(result+'F3');
    if (ShortCut and 255)=VK_F4        then exit(result+'F4');
    if (ShortCut and 255)=VK_F5        then exit(result+'F5');
    if (ShortCut and 255)=VK_F6        then exit(result+'F6');
    if (ShortCut and 255)=VK_F7        then exit(result+'F7');
    if (ShortCut and 255)=VK_F8        then exit(result+'F8');
    if (ShortCut and 255)=VK_F9        then exit(result+'F9');
    if (ShortCut and 255)=VK_F10       then exit(result+'F10');
    if (ShortCut and 255)=VK_F11       then exit(result+'F11');
    if (ShortCut and 255)=VK_F12       then exit(result+'F12');
    result:=result+'[unresolved key '+intToStr(ShortCut and 255)+']';
  end;

end.
