UNIT myGenerics;
INTERFACE
USES sysutils;
{$MACRO ON}
TYPE
  T_arrayOfString =array of ansistring;
  T_arrayOfPointer=array of pointer   ;
  T_arrayOfDouble =array of double    ;
  T_arrayOfLongint=array of longint   ;
  T_arrayOfInt64  =array of int64     ;

  {$define arrayOp:=OPERATOR :=(x:M_VALUE_TYPE):M_ARRAY_TYPE}
  {$define arrayFunctions:=
  PROCEDURE prepend(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  PROCEDURE append(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  PROCEDURE append(VAR x:M_ARRAY_TYPE; CONST y:M_ARRAY_TYPE);
  PROCEDURE appendIfNew(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  PROCEDURE dropFirst(VAR x:M_ARRAY_TYPE; CONST dropCount:longint);
  PROCEDURE dropValues(VAR x:M_ARRAY_TYPE; CONST toDrop:M_VALUE_TYPE);
  PROCEDURE sort(VAR entry:M_ARRAY_TYPE);
  PROCEDURE sortUnique(VAR entry:M_ARRAY_TYPE)}
  {$define M_ARRAY_TYPE:=T_arrayOfString } {$define M_VALUE_TYPE:=ansistring} arrayFunctions; arrayOp;
  {$define M_ARRAY_TYPE:=T_arrayOfPointer} {$define M_VALUE_TYPE:=pointer   } arrayFunctions;
  {$define M_ARRAY_TYPE:=T_arrayOfDouble } {$define M_VALUE_TYPE:=double    } arrayFunctions; arrayOp;
  {$define M_ARRAY_TYPE:=T_arrayOfLongint} {$define M_VALUE_TYPE:=longint   } arrayFunctions; arrayOp;
  {$define M_ARRAY_TYPE:=T_arrayOfInt64  } {$define M_VALUE_TYPE:=int64     } arrayFunctions; arrayOp;
  {$undef arrayFunctions}
  {$undef arrayOp}

  FUNCTION C_EMPTY_STRING_ARRAY :T_arrayOfString ;
  FUNCTION C_EMPTY_POINTER_ARRAY:T_arrayOfPointer;
  FUNCTION C_EMPTY_DOUBLE_ARRAY :T_arrayOfDouble ;
  FUNCTION C_EMPTY_LONGINT_ARRAY:T_arrayOfLongint;
  FUNCTION C_EMPTY_INT64_ARRAY  :T_arrayOfInt64  ;

TYPE
  {$define someKeyMapInterface:=
  object
    TYPE VALUE_TYPE_ARRAY=array of VALUE_TYPE;
         KEY_VALUE_PAIR=record
           key:M_KEY_TYPE;
           value:VALUE_TYPE;
         end;
         KEY_VALUE_LIST=array of KEY_VALUE_PAIR;
         VALUE_DISPOSER=PROCEDURE(VAR v:VALUE_TYPE);
         MY_TYPE=specialize M_MAP_TYPE<VALUE_TYPE>;
    private VAR
      cs:TRTLCriticalSection;
      entryCount:longint;
      rebalanceFac:double;
      bucket:array of KEY_VALUE_LIST;
      disposer:VALUE_DISPOSER;
      PROCEDURE rehash(CONST grow:boolean);
    public
      CONSTRUCTOR create(CONST rebalanceFactor:double; CONST disposer_:VALUE_DISPOSER=nil);
      CONSTRUCTOR create(CONST disposer_:VALUE_DISPOSER=nil);
      CONSTRUCTOR createClone(VAR map:MY_TYPE);
      DESTRUCTOR destroy;
      FUNCTION containsKey(CONST key:M_KEY_TYPE; OUT value:VALUE_TYPE):boolean;
      FUNCTION containsKey(CONST key:M_KEY_TYPE):boolean;
      FUNCTION get(CONST key:M_KEY_TYPE):VALUE_TYPE;
      PROCEDURE put(CONST key:M_KEY_TYPE; CONST value:VALUE_TYPE);
      PROCEDURE putAll(CONST entries:KEY_VALUE_LIST);
      PROCEDURE dropKey(CONST key:M_KEY_TYPE);
      PROCEDURE clear;
      FUNCTION keySet:M_KEY_ARRAY_TYPE;
      FUNCTION valueSet:VALUE_TYPE_ARRAY;
      FUNCTION entrySet:KEY_VALUE_LIST;
      FUNCTION size:longint;
  end}

  {$define someSetInterface:=
  object
    TYPE backingMapType=specialize M_MAP_TYPE<boolean>;
    private
      map:backingMapType;
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      PROCEDURE put(CONST e:M_KEY_TYPE);
      PROCEDURE put(CONST e:M_KEY_ARRAY_TYPE);
      PROCEDURE put(CONST e:M_SET_TYPE);
      PROCEDURE drop(CONST e:M_KEY_TYPE);
      PROCEDURE clear;
      FUNCTION values:M_KEY_ARRAY_TYPE;
      FUNCTION contains(CONST e:M_KEY_TYPE):boolean;
      FUNCTION size:longint;
  end}

  {$define M_KEY_TYPE:=ansistring}
  {$define M_MAP_TYPE:=G_stringKeyMap}
  {$define M_SET_TYPE:=T_setOfString}
  {$define M_KEY_ARRAY_TYPE:=T_arrayOfString}
  {$define M_HASH_FUNC:=hashOfAnsistring}
  generic G_stringKeyMap<VALUE_TYPE>=someKeyMapInterface;
  T_setOfString=someSetInterface;

  {$define M_KEY_TYPE:=pointer}
  {$define M_MAP_TYPE:=G_pointerKeyMap}
  {$define M_SET_TYPE:=T_setOfPointer}
  {$define M_KEY_ARRAY_TYPE:=T_arrayOfPointer}
  {$define M_HASH_FUNC:=ptruint}
  generic G_pointerKeyMap<VALUE_TYPE>=someKeyMapInterface;
  T_setOfPointer=someSetInterface;

  {$define M_KEY_TYPE:=longint}
  {$define M_MAP_TYPE:=G_longintKeyMap}
  {$define M_SET_TYPE:=T_setOfLongint}
  {$define M_KEY_ARRAY_TYPE:=T_arrayOfLongint}
  {$define M_HASH_FUNC:=}
  generic G_longintKeyMap<VALUE_TYPE>=someKeyMapInterface;
  T_setOfLongint=someSetInterface;

  {$undef someKeyMapInterface}
  {$undef someSetInterface}

  generic G_safeVar<ENTRY_TYPE>=object
    private VAR
      v :ENTRY_TYPE;
      saveCS:TRTLCriticalSection;
      FUNCTION getValue:ENTRY_TYPE;
      PROCEDURE setValue(CONST newValue:ENTRY_TYPE);
    public
      CONSTRUCTOR create(CONST intialValue:ENTRY_TYPE);
      DESTRUCTOR destroy;
      PROPERTY value:ENTRY_TYPE read getValue write setValue;
      PROCEDURE lock;
      PROCEDURE unlock;
  end;

  generic G_safeArray<ENTRY_TYPE>=object
    TYPE ENTRY_TYPE_ARRAY=array of ENTRY_TYPE;
    private VAR
      data :ENTRY_TYPE_ARRAY;
      saveCS:TRTLCriticalSection;
      FUNCTION getValue(index:longint):ENTRY_TYPE;
      PROCEDURE setValue(index:longint; newValue:ENTRY_TYPE);
    public
      CONSTRUCTOR create();
      DESTRUCTOR destroy;
      PROCEDURE clear;
      FUNCTION size:longint;
      PROPERTY value[index:longint]:ENTRY_TYPE read getValue write setValue; default;
      PROCEDURE append(CONST newValue:ENTRY_TYPE);
      PROCEDURE appendAll(CONST newValue:ENTRY_TYPE_ARRAY);
      PROCEDURE lock;
      PROCEDURE unlock;
  end;

  generic G_lazyVar<ENTRY_TYPE>=object
    TYPE T_obtainer=FUNCTION():ENTRY_TYPE;
         T_disposer=PROCEDURE(x:ENTRY_TYPE);
    private
      valueObtained:boolean;
      obtainer:T_obtainer;
      disposer:T_disposer;
      v :ENTRY_TYPE;
      saveCS:TRTLCriticalSection;
      FUNCTION getValue:ENTRY_TYPE;
    public
      CONSTRUCTOR create(CONST o:T_obtainer; CONST d:T_disposer);
      DESTRUCTOR destroy;
      PROPERTY value:ENTRY_TYPE read getValue;
      FUNCTION isObtained:boolean;
  end;

FUNCTION hashOfAnsiString(CONST x:ansistring):PtrUInt; inline;

IMPLEMENTATION
{$define arrayFunctionImpl:=
PROCEDURE prepend(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  VAR i:longint;
  begin
    setLength(x,length(x)+1);
    for i:=length(x)-1 downto 1 do x[i]:=x[i-1];
    x[0]:=y;
  end;

PROCEDURE append(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  begin
    setLength(x,length(x)+1);
    x[length(x)-1]:=y;
  end;

PROCEDURE append(VAR x:M_ARRAY_TYPE; CONST y:M_ARRAY_TYPE);
  VAR i,i0:longint;
  begin
    i0:=length(x);
    setLength(x,i0+length(y));
    for i:=0 to length(y)-1 do x[i+i0]:=y[i];
  end;

PROCEDURE appendIfNew(VAR x:M_ARRAY_TYPE; CONST y:M_VALUE_TYPE);
  VAR i:longint;
  begin
    i:=0;
    while (i<length(x)) and (x[i]<>y) do inc(i);
    if i>=length(x) then begin
      setLength(x,length(x)+1);
      x[length(x)-1]:=y;
    end;
  end;

PROCEDURE dropFirst(VAR x:M_ARRAY_TYPE; CONST dropCount:longint);
  VAR i,dc:longint;
  begin
    if dropCount<=0 then exit;
    if dropCount>length(x) then dc:=length(x) else dc:=dropCount;
    for i:=0 to length(x)-dc-1 do x[i]:=x[i+dc];
    setLength(x,length(x)-dc);
  end;

PROCEDURE dropValues(VAR x:M_ARRAY_TYPE; CONST toDrop:M_VALUE_TYPE);
  VAR i,j:longint;
  begin
    j:=0;
    for i:=0 to length(x)-1 do if x[i]<>toDrop then begin
      x[j]:=x[i]; inc(j);
    end;
    setLength(x,j);
  end;

PROCEDURE sort(VAR entry:M_ARRAY_TYPE);
  VAR scale    :longint;
      i,j0,j1,k:longint;
      temp     :M_ARRAY_TYPE;
  begin
    scale:=1;
    setLength(temp,length(entry));
    while scale<length(temp) do begin
      //merge lists of size [scale] to lists of size [scale+scale]:---------------
      i:=0;
      while i<length(temp) do begin
        j0:=i;
        j1:=i+scale;
        k :=i;
        while (j0<i+scale) and (j1<i+scale+scale) and (j1<length(entry)) do begin
          if entry[j0]<=entry[j1]
            then begin temp[k]:=entry[j0]; inc(k); inc(j0); end
            else begin temp[k]:=entry[j1]; inc(k); inc(j1); end;
        end;
        while (j0<i+scale)       and (j0<length(entry)) do begin temp[k]:=entry[j0]; inc(k); inc(j0); end;
        while (j1<i+scale+scale) and (j1<length(entry)) do begin temp[k]:=entry[j1]; inc(k); inc(j1); end;
        inc(i,scale+scale);
      end;
      //---------------:merge lists of size [scale] to lists of size [scale+scale]
      inc(scale,scale);
      if (scale<length(temp)) then begin
        //The following is equivalent to the above with swapped roles of "list" and "temp".
        //while making the code a little more complicated it avoids unnecessary copys.
        //merge lists of size [scale] to lists of size [scale+scale]:---------------
        i:=0;
        while i<length(temp) do begin
          j0:=i;
          j1:=i+scale;
          k :=i;
          while (j0<i+scale) and (j1<i+scale+scale) and (j1<length(temp)) do begin
            if temp[j0]<=temp[j1]
              then begin entry[k]:=temp[j0]; inc(k); inc(j0); end
              else begin entry[k]:=temp[j1]; inc(k); inc(j1); end;
          end;
          while (j0<i+scale)       and (j0<length(temp)) do begin entry[k]:=temp[j0]; inc(k); inc(j0); end;
          while (j1<i+scale+scale) and (j1<length(temp)) do begin entry[k]:=temp[j1]; inc(k); inc(j1); end;
          inc(i,scale+scale);
        end;
        //---------------:merge lists of size [scale] to lists of size [scale+scale]
        inc(scale,scale);
      end else for k:=0 to length(temp)-1 do entry[k]:=temp[k];
    end;
  end;

PROCEDURE sortUnique(VAR entry:M_ARRAY_TYPE);
  VAR i,j:longint;
  begin
    sort(entry);
    j:=1;
    for i:=1 to length(entry)-1 do if entry[i]<>entry[i-1] then begin
      entry[j]:=entry[i]; inc(j);
    end;
    setLength(entry,j);
  end}
{$define arrayOpImpl:=
OPERATOR :=(x:M_VALUE_TYPE):M_ARRAY_TYPE;
  begin
    setLength(result,1);
    result[0]:=x;
  end}

{$define M_ARRAY_TYPE:=T_arrayOfString } {$define M_VALUE_TYPE:=ansistring} arrayFunctionImpl; arrayOpImpl;
{$define M_ARRAY_TYPE:=T_arrayOfPointer} {$define M_VALUE_TYPE:=pointer   } arrayFunctionImpl;
{$define M_ARRAY_TYPE:=T_arrayOfDouble } {$define M_VALUE_TYPE:=double    } arrayFunctionImpl; arrayOpImpl;
{$define M_ARRAY_TYPE:=T_arrayOfLongint} {$define M_VALUE_TYPE:=longint   } arrayFunctionImpl; arrayOpImpl;
{$define M_ARRAY_TYPE:=T_arrayOfInt64  } {$define M_VALUE_TYPE:=int64     } arrayFunctionImpl; arrayOpImpl;
{$undef arrayFunctionImpl}
{$undef arrayOpImpl}

FUNCTION C_EMPTY_STRING_ARRAY :T_arrayOfString ; begin setLength(result,0); end;
FUNCTION C_EMPTY_POINTER_ARRAY:T_arrayOfPointer; begin setLength(result,0); end;
FUNCTION C_EMPTY_DOUBLE_ARRAY :T_arrayOfDouble ; begin setLength(result,0); end;
FUNCTION C_EMPTY_LONGINT_ARRAY:T_arrayOfLongint; begin setLength(result,0); end;
FUNCTION C_EMPTY_INT64_ARRAY  :T_arrayOfInt64  ; begin setLength(result,0); end;

FUNCTION hashOfAnsiString(CONST x:ansistring):PtrUInt; inline;
  VAR i:longint;
  begin
    {$Q-}{$R-}
    result:=length(x);
    for i:=1 to length(x) do result:=result*31+ord(x[i]);
    {$Q+}{$R+}
  end;

CONSTRUCTOR G_safeArray.create;
  begin
    system.initCriticalSection(saveCS);
    clear;
  end;

FUNCTION G_safeArray.getValue(index: longint): ENTRY_TYPE;
  begin
    system.enterCriticalSection(saveCS);
    result:=data[index];
    system.leaveCriticalSection(saveCS);
  end;

PROCEDURE G_safeArray.setValue(index: longint; newValue: ENTRY_TYPE);
  begin
    system.enterCriticalSection(saveCS);
    if index=length(data) then append(newValue)
                          else data[index]:=newValue;
    system.leaveCriticalSection(saveCS);
  end;

PROCEDURE G_safeArray.clear;
  begin
    system.enterCriticalSection(saveCS);
    setLength(data,0);
    system.leaveCriticalSection(saveCS);
  end;

FUNCTION G_safeArray.size: longint;
  begin
    system.enterCriticalSection(saveCS);
    result:=length(data);
    system.leaveCriticalSection(saveCS);
  end;

PROCEDURE G_safeArray.append(CONST newValue: ENTRY_TYPE);
  begin
    system.enterCriticalSection(saveCS);
    setLength(data,length(data)+1);
    data[length(data)-1]:=newValue;
    system.leaveCriticalSection(saveCS);
  end;

PROCEDURE G_safeArray.appendAll(CONST newValue: ENTRY_TYPE_ARRAY);
  VAR i,i0:longint;
  begin
    system.enterCriticalSection(saveCS);
    i0:=length(data);
    setLength(data,i0+length(newValue));
    for i:=0 to length(newValue)-1 do data[i0+i]:=newValue[i];
    system.leaveCriticalSection(saveCS);
  end;


PROCEDURE G_safeArray.lock;
  begin
    system.enterCriticalSection(saveCS);
  end;

PROCEDURE G_safeArray.unlock;
  begin
    system.leaveCriticalSection(saveCS);
  end;

DESTRUCTOR G_safeArray.destroy;
  begin
    clear;
    system.doneCriticalSection(saveCS);
  end;

{ G_lazyVar }

FUNCTION G_lazyVar.getValue: ENTRY_TYPE;
  begin
    enterCriticalSection(saveCS);
    if not(valueObtained) then begin
      v:=obtainer();
      valueObtained:=true;
    end;
    result:=v;
    leaveCriticalSection(saveCS);
  end;

CONSTRUCTOR G_lazyVar.create(CONST o:T_obtainer; CONST d:T_disposer);
  begin
    obtainer:=o;
    disposer:=d;
    valueObtained:=false;
    initCriticalSection(saveCS);
  end;

DESTRUCTOR G_lazyVar.destroy;
  begin
    if valueObtained and (disposer<>nil) then disposer(v);
    doneCriticalSection(saveCS);
  end;

FUNCTION G_lazyVar.isObtained:boolean;
  begin
    enterCriticalSection(saveCS);
    result:=valueObtained;
    leaveCriticalSection(saveCS);
  end;

{ G_safeVar }

CONSTRUCTOR G_safeVar.create(CONST intialValue: ENTRY_TYPE);
  begin
    system.initCriticalSection(saveCS);
    v:=intialValue;
  end;

FUNCTION G_safeVar.getValue: ENTRY_TYPE;
  begin
    system.enterCriticalSection(saveCS);
    result:=v;
    system.leaveCriticalSection(saveCS);
  end;

PROCEDURE G_safeVar.setValue(CONST newValue: ENTRY_TYPE);
  begin
    system.enterCriticalSection(saveCS);
    v:=newValue;
    system.leaveCriticalSection(saveCS);
  end;

DESTRUCTOR G_safeVar.destroy;
  begin
    system.doneCriticalSection(saveCS);
  end;

PROCEDURE G_safeVar.lock;
  begin
    system.enterCriticalSection(saveCS);
  end;

PROCEDURE G_safeVar.unlock;
  begin
    system.leaveCriticalSection(saveCS);
  end;

{$define someKeyMapImplementation:=
PROCEDURE M_MAP_TYPE.rehash(CONST grow: boolean);
  VAR i,i0,j,k,c0,c1:longint;
      temp:array of KEY_VALUE_PAIR;
  begin
    if grow then begin
      i0:=length(bucket);
      setLength(bucket,i0+i0);
      for i:=0 to i0-1 do begin
        temp:=bucket[i];
        setLength(bucket[i+i0],length(bucket[i]));
        c0:=0;
        c1:=0;
        for j:=0 to length(temp)-1 do begin
          k:=M_HASH_FUNC(temp[j].key) and (length(bucket)-1);
          if k=i then begin
            bucket[i][c0]:=temp[j];
            inc(c0);
          end else begin
            bucket[k][c1]:=temp[j];
            inc(c1);
          end;
        end;
        setLength(bucket[i   ],c0);
        setLength(bucket[i+i0],c1);
        setLength(temp,0);
      end;
    end else begin
      i0:=length(bucket) shr 1;
      for i:=0 to i0-1 do
      for j:=0 to length(bucket[i0+i])-1 do begin
        setLength(bucket[i],length(bucket[i])+1);
        bucket[i][length(bucket[i])-1]:=bucket[i0+i][j];
      end;
    end;
  end;

CONSTRUCTOR M_MAP_TYPE.create(CONST rebalanceFactor: double; CONST disposer_:VALUE_DISPOSER=nil);
  begin
    system.initCriticalSection(cs);
    rebalanceFac:=rebalanceFactor;
    setLength(bucket,1);
    setLength(bucket[0],0);
    entryCount:=0;
    disposer:=disposer_;
  end;

PROCEDURE M_MAP_TYPE.clear;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    for i:=0 to length(bucket)-1 do begin
      if disposer<>nil then for j:=0 to length(bucket[i])-1 do disposer(bucket[i,j].value);
      setLength(bucket[i],0);
    end;
    setLength(bucket,1);
    entryCount:=0;
    system.leaveCriticalSection(cs);
  end;

CONSTRUCTOR M_MAP_TYPE.create(CONST disposer_:VALUE_DISPOSER=nil);
  begin
    create(4,disposer_);
  end;

CONSTRUCTOR M_MAP_TYPE.createClone(VAR map:MY_TYPE);
  VAR i,j:longint;
  begin
    create(map.rebalanceFac,map.disposer);
    if disposer<>nil then raise Exception.create('You must not clone maps with an associated disposer');
    setLength(bucket,length(map.bucket));
    for i:=0 to length(bucket)-1 do begin
      setLength(bucket[i],length(map.bucket[i]));
      for j:=0 to length(bucket[i])-1 do bucket[i,j]:=map.bucket[i,j];
    end;
    entryCount:=map.entryCount;
  end;

DESTRUCTOR M_MAP_TYPE.destroy;
  begin
    clear;
    system.enterCriticalSection(cs);
    setLength(bucket,0);
    system.leaveCriticalSection(cs);
    system.doneCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.containsKey(CONST key: M_KEY_TYPE; OUT value: VALUE_TYPE): boolean;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=M_HASH_FUNC(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    if (j<length(bucket[i])) then begin
      value:=bucket[i][j].value;
      result:=true;
    end else result:=false;
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.containsKey(CONST key:M_KEY_TYPE):boolean;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=M_HASH_FUNC(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    result:=(j<length(bucket[i]));
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.get(CONST key: M_KEY_TYPE): VALUE_TYPE;
  begin
    containsKey(key,result);
  end;

PROCEDURE M_MAP_TYPE.put(CONST key: M_KEY_TYPE; CONST value: VALUE_TYPE);
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=M_HASH_FUNC(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    if j>=length(bucket[i]) then begin
      setLength(bucket[i],j+1);
      bucket[i][j].key:=key;
      bucket[i][j].value:=value;
      inc(entryCount);
      if entryCount>length(bucket)*rebalanceFac then rehash(true);
    end else begin
      if disposer<>nil then disposer(bucket[i][j].value);
      bucket[i][j].value:=value;
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE M_MAP_TYPE.putAll(CONST entries:KEY_VALUE_LIST);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    for i:=0 to length(entries)-1 do put(entries[i].key,entries[i].value);
    system.leaveCriticalSection(cs);
  end;

PROCEDURE M_MAP_TYPE.dropKey(CONST key: M_KEY_TYPE);
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=M_HASH_FUNC(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    if j<length(bucket[i]) then begin
      if disposer<>nil then disposer(bucket[i][j].value);
      while j<length(bucket[i])-1 do begin
        bucket[i][j]:=bucket[i][j+1];
        inc(j);
      end;
      setLength(bucket[i],length(bucket[i])-1);
      dec(entryCount);
      if entryCount<0.4*length(bucket)*rebalanceFac then rehash(false);
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.keySet: M_KEY_ARRAY_TYPE;
  VAR k,i,j:longint;
  begin
    system.enterCriticalSection(cs);
    setLength(result,entryCount);
    k:=0;
    for i:=0 to length(bucket)-1 do
    for j:=0 to length(bucket[i])-1 do begin
      result[k]:=bucket[i][j].key;
      inc(k);
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.valueSet: VALUE_TYPE_ARRAY;
  VAR k,i,j:longint;
  begin
    system.enterCriticalSection(cs);
    setLength(result,entryCount);
    k:=0;
    for i:=0 to length(bucket)-1 do
    for j:=0 to length(bucket[i])-1 do begin
      result[k]:=bucket[i][j].value;
      inc(k);
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.entrySet: KEY_VALUE_LIST;
  VAR k,i,j:longint;
  begin
    system.enterCriticalSection(cs);
    setLength(result,entryCount);
    k:=0;
    for i:=0 to length(bucket)-1 do
    for j:=0 to length(bucket[i])-1 do begin
      result[k]:=bucket[i][j];
      inc(k);
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION M_MAP_TYPE.size: longint;
  begin
    system.enterCriticalSection(cs);
    result:=entryCount;
    system.leaveCriticalSection(cs);
  end}

{$define someSetImplementation:=
CONSTRUCTOR M_SET_TYPE.create; begin map.create; end;
DESTRUCTOR M_SET_TYPE.destroy; begin map.destroy; end;
PROCEDURE M_SET_TYPE.put(CONST e:M_KEY_TYPE); begin map.put(e,true); end;
PROCEDURE M_SET_TYPE.put(CONST e:M_KEY_ARRAY_TYPE); VAR k:M_KEY_TYPE; begin for k in e do map.put(k,true); end;
PROCEDURE M_SET_TYPE.put(CONST e:M_SET_TYPE); VAR k:M_KEY_TYPE; begin for k in e.map.keySet do map.put(k,true); end;
PROCEDURE M_SET_TYPE.drop(CONST e:M_KEY_TYPE); begin map.dropKey(e); end;
PROCEDURE M_SET_TYPE.clear; begin map.clear; end;
FUNCTION M_SET_TYPE.values:M_KEY_ARRAY_TYPE; begin result:=map.keySet; sort(result); end;
FUNCTION M_SET_TYPE.contains(CONST e:M_KEY_TYPE):boolean; begin result:=map.containsKey(e); end;
FUNCTION M_SET_TYPE.size:longint; begin result:=map.size; end}

{$define M_KEY_TYPE:=ansistring}
{$define M_MAP_TYPE:=G_stringKeyMap}
{$define M_SET_TYPE:=T_setOfString}
{$define M_KEY_ARRAY_TYPE:=T_arrayOfString}
{$define M_HASH_FUNC:=hashOfAnsistring}
someKeyMapImplementation;
someSetImplementation;

{$define M_KEY_TYPE:=pointer}
{$define M_MAP_TYPE:=G_pointerKeyMap}
{$define M_SET_TYPE:=T_setOfPointer}
{$define M_KEY_ARRAY_TYPE:=T_arrayOfPointer}
{$define M_HASH_FUNC:=ptruint}
someKeyMapImplementation;
someSetImplementation;

{$define M_KEY_TYPE:=longint}
{$define M_MAP_TYPE:=G_longintKeyMap}
{$define M_SET_TYPE:=T_setOfLongint}
{$define M_KEY_ARRAY_TYPE:=T_arrayOfLongint}
{$define M_HASH_FUNC:=}
someKeyMapImplementation;
someSetImplementation;

end.

