UNIT cmdLineParseUtil;
INTERFACE
USES sysutils;
TYPE
  T_extendedParameter=record
    isFile:boolean;
    leadingSign:char;
    cmdString:string;
    intParam:array of longint;
    floatParam:array of double;
    stringSuffix:string;
  end;

  T_commandAbstraction=record
    isFile:boolean;
    leadingSign:char;
    cmdString:string;
    paramCount:longint;
  end;

FUNCTION extendedParam(index:longint):T_extendedParameter;
FUNCTION extendedParam(s:string     ):T_extendedParameter;
FUNCTION matches(ep:T_extendedParameter; ca:T_commandAbstraction):boolean;
FUNCTION matchingCmdIndex(ep:T_extendedParameter; cmdList: array of T_commandAbstraction):longint;
FUNCTION gotParam(cmd:T_commandAbstraction):boolean;
FUNCTION getParam(cmd:T_commandAbstraction):T_extendedParameter;
IMPLEMENTATION
FUNCTION extendedParam(s:string):T_extendedParameter;
  VAR i:longint;
  begin
    setLength(result.intParam,0);
    setLength(result.floatParam,0);
    result.stringSuffix:='';
    result.leadingSign:=s[1];
    if result.leadingSign in ['.','a'..'z','A'..'Z','_','0'..'9'] then begin
      result.isFile:=true;
      result.cmdString:=s;
      result.stringSuffix:=s;
    end else begin
      result.isFile:=false;
      s:=copy(s,2,length(s)-1); //remove leading '-'
      result.cmdString:='';
      i:=1;
      while (s[i] in ['a'..'z','A'..'Z']) and (i<=length(s)) do begin
        result.cmdString:=result.cmdString+s[i];
        inc(i);
      end;
      s:=copy(s,i,length(s));
      if (length(s)>0) and (s[1] in [':',',']) then s:=copy(s,2,length(s)-1);
      result.stringSuffix:=s;
      while length(s)>0 do begin
        i:=1;
        while (i<=length(s)) and (not(s[i] in ['x',',',':','='])) do inc(i);
        with result do begin
          setLength(floatParam,length(floatParam)+1);
          setLength(intParam  ,length(intParam)+1);
          floatParam[length(floatParam)-1]:=strToFloatDef(copy(s,1,i-1),0);
          intParam  [length(intParam)  -1]:=strToIntDef  (copy(s,1,i-1),0);
        end;
        s:=copy(s,i+1,length(s));
      end;
    end;
  end;

FUNCTION extendedParam(index:longint):T_extendedParameter;
  begin
    result:=extendedParam(paramStr(index));
  end;

FUNCTION matches(ep:T_extendedParameter; ca:T_commandAbstraction):boolean;
  begin
    result:=(ep.isFile) and (ca.isFile) or
            not(ep.isFile) and
            not(ca.isFile) and
           (ep.leadingSign=ca.leadingSign) and
           (ep.cmdString=ca.cmdString) and
           ((ca.paramCount=-1) or (length(ep.floatParam)=ca.paramCount));
  end;

FUNCTION matchingCmdIndex(ep:T_extendedParameter; cmdList: array of T_commandAbstraction):longint;
  begin
    result:=low(cmdList);
    while (result<=high(cmdList)) and not(matches(ep,cmdList[result])) do inc(result);
  end;

FUNCTION gotParam(cmd:T_commandAbstraction):boolean;
  VAR i:longint;
  begin
    result:=false;
    for i:=1 to paramCount do result:=result or matches(extendedParam(i),cmd);
  end;

FUNCTION getParam(cmd:T_commandAbstraction):T_extendedParameter;
  VAR i:longint;
  begin
    i:=1;
    while (i<=paramCount) and not(matches(extendedParam(i),cmd)) do inc(i);
    if i<=paramCount then result:=extendedParam(i);
  end;

INITIALIZATION
  DefaultFormatSettings.DecimalSeparator:='.';

end.
