UNIT fileHistories;
INTERFACE
USES mySys,myGenerics,sysutils,FileUtil,myStringUtil;

PROCEDURE removeNonexistent;
PROCEDURE addToHistory(CONST utfFile1:ansistring; CONST utfFile2:ansistring=''; CONST utfFile3:ansistring=''; CONST utfFile4:ansistring='');
PROCEDURE limitHistory(CONST sizeLimit:longint);
PROCEDURE historyItemRecalled(CONST index:longint);
VAR history:T_arrayOfString;
IMPLEMENTATION
PROCEDURE removeNonexistent;
  VAR i,j,i2,j2:longint;
      fileSet:T_arrayOfString;
  begin
    j:=0;
    for i:=0 to length(history)-1 do
    if fileExists(history[i]) then begin
      history[j]:=history[i];
      inc(j);
    end else if pos('&',history[i])>0 then begin
      fileSet:=split(history[i],T_arrayOfString('&'));
      j2:=0;
      for i2:=0 to length(fileSet)-1 do
      if fileExists(fileSet[i2]) then begin
        fileSet[j2]:=fileSet[i2];
        inc(j2);
      end;
      setLength(fileSet,j2);
      if (j2>0) then begin
        history[j]:=join(fileSet,'&');
        inc(j);
      end;
    end;
    setLength(history,j);

    j:=1;
    for i:=1 to length(history)-1 do begin
      i2:=0;
      while (i2<i) and (history[i2]<>history[i]) do inc(i2);
      if i2>=i then begin
        history[j]:=history[i];
        inc(j);
      end;
    end;
    setLength(history,j);
  end;

PROCEDURE addToHistory(CONST utfFile1: ansistring; CONST utfFile2: ansistring; CONST utfFile3: ansistring; CONST utfFile4: ansistring);
  VAR historyLine:ansistring;
      i,j:longint;
  begin
    historyLine:=utfFile1;
    if utfFile2<>'' then historyLine:=historyLine+'&'+utfFile2;
    if utfFile3<>'' then historyLine:=historyLine+'&'+utfFile3;
    if utfFile4<>'' then historyLine:=historyLine+'&'+utfFile4;

    j:=0;
    for i:=0 to length(history)-1 do if history[i]<>historyLine then begin
      history[j]:=history[i];
      inc(j);
    end;
    setLength(history,j);

    setLength(history,length(history)+1);
    for i:=length(history)-1 downto 1 do history[i]:=history[i-1];
    history[0]:=historyLine;

    removeNonexistent;
  end;

PROCEDURE limitHistory(CONST sizeLimit: longint);
  begin
    if sizeLimit>length(history) then setLength(history,sizeLimit);
  end;

PROCEDURE historyItemRecalled(CONST index: longint);
  VAR i:longint;
      temp:ansistring;
  begin
    for i:=index-1 downto 0 do begin
      temp:=history[i];
      history[i]:=history[i+1];
      history[i+1]:=temp;
    end;
    removeNonexistent;
  end;

INITIALIZATION
  history:=readFile(ChangeFileExt(paramStr(0),'.fileHist'));
  removeNonexistent;
FINALIZATION
  writeFile(ChangeFileExt(paramStr(0),'.fileHist'),history);
end.
