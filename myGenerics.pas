UNIT myGenerics;
INTERFACE
USES sysutils;
TYPE
  GENERIC G_list<ENTRY_TYPE>=object
    TYPE
      ENTRY_TYPE_ARRAY=array of ENTRY_TYPE;
    private VAR
      entry:ENTRY_TYPE_ARRAY;
      sortedUntilIndex:longint;
      isUnique:boolean;
      cs:system.TRTLCriticalSection;
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      FUNCTION contains(CONST value:ENTRY_TYPE):boolean;
      FUNCTION indexOf(CONST value:ENTRY_TYPE):longint;
      PROCEDURE add(CONST value:ENTRY_TYPE);
      PROCEDURE add(CONST value:ENTRY_TYPE; CONST index:longint);
      PROCEDURE remValue(CONST value:ENTRY_TYPE);
      PROCEDURE remValues(CONST values:ENTRY_TYPE_ARRAY);
      PROCEDURE remIndex(CONST index:longint);
      PROCEDURE addAll(CONST values:ENTRY_TYPE_ARRAY);
      PROCEDURE clear;
      PROCEDURE sort;
      PROCEDURE unique;
      FUNCTION size:longint;
      FUNCTION getEntry(CONST index:longint):ENTRY_TYPE;
      PROCEDURE setEntry(CONST index:longint; CONST value:ENTRY_TYPE);
      PROPERTY element[index:longint]:ENTRY_TYPE read getEntry write setEntry; default;
      FUNCTION elementArray:ENTRY_TYPE_ARRAY;
  end;

  T_listOfString=specialize G_list<ansistring>;
  T_listOfIntegers=specialize G_list<longint>;
  T_listOfDoubles=specialize G_list<double>;

  GENERIC G_sparseArray<ENTRY_TYPE>=object
    TYPE INDEXED_ENTRY=record index:longint; value:ENTRY_TYPE; end;
         INDEXED_ENTRY_ARRAY=array of INDEXED_ENTRY;
    private
      VAR map:array of INDEXED_ENTRY_ARRAY;
      hashMask:longint;
      entryCount:longint;
      FUNCTION indexInMap(CONST mapIdx,searchIdx:longint):longint;
      PROCEDURE rehash(CONST grow:boolean);
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      PROCEDURE add(CONST index:longint; CONST value:ENTRY_TYPE);
      FUNCTION containsIndex(CONST index:longint; OUT value:ENTRY_TYPE):boolean;
      FUNCTION remove(CONST index:longint):boolean;
      FUNCTION size:longint;
      FUNCTION entries:INDEXED_ENTRY_ARRAY;
  end;

  T_arrayOfString=array of ansistring;
  T_arrayOfDouble=array of double;
  T_arrayOfLongint=array of longint;
  T_arrayOfInt64 = array of int64;
  OPERATOR :=(x:ansistring):T_arrayOfString;
  PROCEDURE append(VAR x:T_arrayOfString; CONST y:ansistring);
  PROCEDURE append(VAR x:T_arrayOfLongint; CONST y:longint);
  PROCEDURE append(VAR x:T_arrayOfInt64; CONST y:int64);
  PROCEDURE append(VAR x:T_arrayOfDouble; CONST y:double);
  PROCEDURE appendIfNew(VAR x:T_arrayOfString; CONST y:ansistring);
  PROCEDURE appendIfNew(VAR x:T_arrayOfLongint; CONST y:longint);
  PROCEDURE append(VAR x:T_arrayOfString; CONST y:T_arrayOfString);
  PROCEDURE append(VAR x:T_arrayOfLongint; CONST y:T_arrayOfLongint);
  PROCEDURE append(VAR x:T_arrayOfInt64; CONST y:T_arrayOfInt64);
  PROCEDURE dropFirst(VAR x:T_arrayOfString; CONST dropCount:longint);
  FUNCTION clone(CONST s:T_arrayOfString):T_arrayOfString;

  FUNCTION C_EMPTY_STRING_ARRAY:T_arrayOfString;
  FUNCTION C_EMPTY_DOUBLE_ARRAY:T_arrayOfDouble;

TYPE
  GENERIC G_stringKeyMap<VALUE_TYPE>=object
    TYPE VALUE_TYPE_ARRAY=array of VALUE_TYPE;
         KEY_VALUE_PAIR=record
           hash:longint;
           key:ansistring;
           value:VALUE_TYPE;
         end;
         KEY_VALUE_LIST=array of KEY_VALUE_PAIR;
         VALUE_DISPOSER=PROCEDURE(VAR v:VALUE_TYPE);
         MY_TYPE=specialize G_stringKeyMap<VALUE_TYPE>;
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
      FUNCTION containsKey(CONST key:ansistring; OUT value:VALUE_TYPE):boolean;
      FUNCTION containsKey(CONST key:ansistring):boolean;
      FUNCTION get(CONST key:ansistring):VALUE_TYPE;
      PROCEDURE put(CONST key:ansistring; CONST value:VALUE_TYPE);
      PROCEDURE putAll(CONST entries:KEY_VALUE_LIST);
      PROCEDURE dropKey(CONST key:ansistring);
      PROCEDURE clear;
      FUNCTION keySet:T_arrayOfString;
      FUNCTION valueSet:VALUE_TYPE_ARRAY;
      FUNCTION entrySet:KEY_VALUE_LIST;
      FUNCTION size:longint;
  end;

  GENERIC G_safeVar<ENTRY_TYPE>=object
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

  GENERIC G_safeArray<ENTRY_TYPE>=object
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

  GENERIC G_lazyVar<ENTRY_TYPE>=object
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

FUNCTION hashOfAnsiString(CONST x:ansistring):longint; inline;

IMPLEMENTATION
OPERATOR :=(x:ansistring):T_arrayOfString;
  begin
    setLength(result,1);
    result[0]:=x;
  end;

PROCEDURE append(VAR x:T_arrayOfString; CONST y:ansistring);
  begin
    setLength(x,length(x)+1);
    x[length(x)-1]:=y;
  end;

PROCEDURE append(VAR x:T_arrayOfLongint; CONST y:longint);
  begin
    setLength(x,length(x)+1);
    x[length(x)-1]:=y;
  end;

PROCEDURE append(VAR x:T_arrayOfInt64; CONST y:int64);
  begin
    setLength(x,length(x)+1);
    x[length(x)-1]:=y;
  end;

PROCEDURE append(VAR x:T_arrayOfDouble; CONST y:double);
  begin
    setLength(x,length(x)+1);
    x[length(x)-1]:=y;
  end;

PROCEDURE appendIfNew(VAR x:T_arrayOfString; CONST y:ansistring);
  VAR i:longint;
  begin
    i:=0;
    while (i<length(x)) and (x[i]<>y) do inc(i);
    if i>=length(x) then begin
      setLength(x,length(x)+1);
      x[length(x)-1]:=y;
    end;
  end;

PROCEDURE appendIfNew(VAR x:T_arrayOfLongint; CONST y:longint);
  VAR i:longint;
  begin
    i:=0;
    while (i<length(x)) and (x[i]<>y) do inc(i);
    if i>=length(x) then begin
      setLength(x,length(x)+1);
      x[length(x)-1]:=y;
    end;
  end;

PROCEDURE append(VAR x:T_arrayOfString; CONST y:T_arrayOfString);
  VAR i,i0:longint;
  begin
    i0:=length(x);
    setLength(x,i0+length(y));
    for i:=0 to length(y)-1 do x[i+i0]:=y[i];
  end;

PROCEDURE append(VAR x:T_arrayOfLongint; CONST y:T_arrayOfLongint);
  VAR i,i0:longint;
  begin
    i0:=length(x);
    setLength(x,i0+length(y));
    for i:=0 to length(y)-1 do x[i+i0]:=y[i];
  end;

PROCEDURE append(VAR x:T_arrayOfInt64; CONST y:T_arrayOfInt64);
  VAR i,i0:longint;
  begin
    i0:=length(x);
    setLength(x,i0+length(y));
    for i:=0 to length(y)-1 do x[i+i0]:=y[i];
  end;

PROCEDURE dropFirst(VAR x:T_arrayOfString; CONST dropCount:longint);
  VAR i,dc:longint;
  begin
    if dropCount<=0 then exit;
    if dropCount>length(x) then dc:=length(x) else dc:=dropCount;
    for i:=0 to length(x)-dc-1 do x[i]:=x[i+dc];
    setLength(x,length(x)-dc);
  end;

FUNCTION clone(CONST s:T_arrayOfString):T_arrayOfString;
  VAR i:longint;
  begin
    setLength(result,length(s));
    for i:=0 to length(s)-1 do result[i]:=s[i];
  end;

FUNCTION C_EMPTY_STRING_ARRAY:T_arrayOfString; begin setLength(result,0); end;
FUNCTION C_EMPTY_DOUBLE_ARRAY:T_arrayOfDouble; begin setLength(result,0); end;

FUNCTION hashOfAnsiString(CONST x:ansistring):longint; inline;
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

CONSTRUCTOR G_list.create;
  begin system.initCriticalSection(cs); clear; end;

DESTRUCTOR G_list.destroy;
  begin clear; system.doneCriticalSection(cs); end;

FUNCTION G_list.contains(CONST value:ENTRY_TYPE):boolean;
  begin result:=indexOf(value)>=0; end;

FUNCTION G_list.indexOf(CONST value:ENTRY_TYPE):longint;
  VAR i0,i1:longint;
  begin
    system.enterCriticalSection(cs);
    i0:=0;
    i1:=sortedUntilIndex-1;
    while i1>=i0 do begin
      result:=(i0+i1) shr 1;
      if      entry[result]<value then i0:=result+1
      else if entry[result]>value then i1:=result-1
      else begin
        system.leaveCriticalSection(cs);
        exit(result);
      end;
    end;
    for i0:=sortedUntilIndex to length(entry)-1 do
      if entry[i0]=value then begin
        system.leaveCriticalSection(cs);
        exit(i0);
      end;
    result:=-1;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.add(CONST value:ENTRY_TYPE);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    i:=length(entry);
    setLength(entry,i+1);
    entry[i]:=value;
    isUnique:=false;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.add(CONST value:ENTRY_TYPE; CONST index:longint);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    i:=length(entry);
    setLength(entry,i+1);
    for i:=length(entry)-1 downto index+1 do entry[i]:=entry[i-1];
    entry[index]:=value;
    isUnique:=false;
    if sortedUntilIndex>index then sortedUntilIndex:=index;
    system.leaveCriticalSection(cs);
  end;


PROCEDURE G_list.remIndex(CONST index:longint);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    if (index>=0) and (index<length(entry)) then begin
      if index<sortedUntilIndex then dec(sortedUntilIndex);
      for i:=index to length(entry)-2 do entry[i]:=entry[i+1];
      setLength(entry,length(entry)-1);
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.remValue(CONST value:ENTRY_TYPE);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    i:=indexOf(value);
    while i>=0 do begin
      remIndex(i);
      i:=indexOf(value);
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.remValues(CONST values:ENTRY_TYPE_ARRAY);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    for i:=0 to length(values)-1 do remValue(values[i]);
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.addAll(CONST values:ENTRY_TYPE_ARRAY);
  VAR i,i0:longint;
  begin
    system.enterCriticalSection(cs);
    i0:=length(entry);
    setLength(entry,length(entry)+length(values));
    for i:=0 to length(values)-1 do entry[i0+i]:=values[i];
    isUnique:=false;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.clear;
  begin
    system.enterCriticalSection(cs);
    setLength(entry,0);
    sortedUntilIndex:=0;
    isUnique:=true;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.sort;
  VAR scale    :longint;
      i,j0,j1,k:longint;
      temp     :ENTRY_TYPE_ARRAY;
  begin
    system.enterCriticalSection(cs);
    if sortedUntilIndex<length(entry) then begin
      scale:=1;
      setLength(temp,length(entry)-sortedUntilIndex);
      while scale<length(temp) do begin
        //merge lists of size [scale] to lists of size [scale+scale]:---------------
        i:=0;
        while i<length(temp) do begin
          j0:=sortedUntilIndex+i;
          j1:=sortedUntilIndex+i+scale;
          k :=i;
          while (j0<sortedUntilIndex+i+scale) and (j1<sortedUntilIndex+i+scale+scale) and (j1<length(entry)) do begin
            if entry[j0]<=entry[j1]
              then begin temp[k]:=entry[j0]; inc(k); inc(j0); end
              else begin temp[k]:=entry[j1]; inc(k); inc(j1); end;
          end;
          while (j0<sortedUntilIndex+i+scale)       and (j0<length(entry)) do begin temp[k]:=entry[j0]; inc(k); inc(j0); end;
          while (j1<sortedUntilIndex+i+scale+scale) and (j1<length(entry)) do begin temp[k]:=entry[j1]; inc(k); inc(j1); end;
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
            k :=sortedUntilIndex+i;
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
        end else for k:=0 to length(temp)-1 do entry[sortedUntilIndex+k]:=temp[k];
      end;
      setLength(temp,length(entry));
      for k:=0 to length(entry)-1 do temp[k]:=entry[k];
      j0:=0;
      j1:=sortedUntilIndex;
      k:=0;
      while (j0<sortedUntilIndex) and (j1<length(entry)) do begin
        if temp[j0]<=temp[j1]
          then begin entry[k]:=temp[j0]; inc(k); inc(j0); end
          else begin entry[k]:=temp[j1]; inc(k); inc(j1); end;
      end;
      while (j0<sortedUntilIndex) do begin entry[k]:=temp[j0]; inc(k); inc(j0); end;
      while (j1<length(temp))     do begin entry[k]:=temp[j1]; inc(k); inc(j1); end;
      sortedUntilIndex:=length(entry);
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.unique;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    if not(isUnique) then begin
      sort;
      j:=1;
      for i:=1 to length(entry)-1 do if entry[i]<>entry[i-1] then begin
        entry[j]:=entry[i]; inc(j);
      end;
      setLength(entry,j);
      sortedUntilIndex:=length(entry);
    end;
    isUnique:=true;
    system.leaveCriticalSection(cs);
  end;

FUNCTION G_list.size:longint;
  begin
    system.enterCriticalSection(cs);
    result:=length(entry);
    system.leaveCriticalSection(cs);
  end;

FUNCTION G_list.getEntry(CONST index:longint):ENTRY_TYPE;
  begin
    system.enterCriticalSection(cs);
    result:=entry[index];
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_list.setEntry(CONST index:longint; CONST value:ENTRY_TYPE);
  begin
    system.enterCriticalSection(cs);
    entry[index]:=value;
    system.leaveCriticalSection(cs);
  end;

FUNCTION G_list.elementArray:ENTRY_TYPE_ARRAY;
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    setLength(result,length(entry));
    for i:=0 to length(result)-1 do result[i]:=entry[i];
    system.leaveCriticalSection(cs);
  end;

CONSTRUCTOR G_sparseArray.create;
  begin
    hashMask:=0;
    entryCount:=0;
    setLength(map,1);
    setLength(map[0],0);
  end;

DESTRUCTOR G_sparseArray.destroy;
  VAR i:longint;
  begin
    for i:=0 to length(map)-1 do setLength(map[i],0);
    setLength(map,0);
  end;

FUNCTION G_sparseArray.indexInMap(CONST mapIdx,searchIdx:longint):longint;
  VAR i0:longint;
  begin
    for i0:=0 to length(map[mapIdx])-1 do if map[mapIdx,i0].index=searchIdx then exit(i0);
    result:=-1;
  end;

PROCEDURE G_sparseArray.add(CONST index:longint; CONST value:ENTRY_TYPE);
  VAR hash:longint;
      i:longint;
  begin
    hash:=index and hashMask;
    i:=indexInMap(hash,index);
    if i<0 then begin
      i:=length(map[hash]);
      setLength(map[hash],i+1);
      map[hash,i].index:=index;
      inc(entryCount);
      map[hash,i].value:=value;
      if length(map) shl 4<entryCount then rehash(true);
    end else map[hash,i].value:=value;
  end;

FUNCTION G_sparseArray.containsIndex(CONST index:longint; OUT value:ENTRY_TYPE):boolean;
  VAR hash:longint;
      i:longint;
  begin
    hash:=index and hashMask;
    i:=indexInMap(hash,index);
    if i<0 then result:=false
    else begin
      result:=true;
      value:=map[hash,i].value;
    end;
  end;

FUNCTION G_sparseArray.remove(CONST index:longint):boolean;
  VAR hash:longint;
      i,j:longint;
  begin
    hash:=index and hashMask;
    i:=indexInMap(hash,index);
    if i<0 then result:=false
    else begin
      for j:=i to length(map[hash])-2 do map[hash][j]:=map[hash][j+1];
      setLength(map[hash],length(map[hash])-1);
      dec(entryCount);
      result:=true;
      if length(map) shl 3>entryCount then rehash(false);
    end;
  end;

PROCEDURE G_sparseArray.rehash(CONST grow:boolean);
  VAR i,k,j0,j1,oldLen:longint;
  begin
    if (length(map)>1) and not(grow) then begin
      //merge
      k:=length(map) shr 1;
      for i:=0 to k-1 do begin
        j0:=length(map[i]);
        setLength(map[i],length(map[i])+length(map[i+k]));
        for j1:=0 to length(map[i+k])-1 do map[i][j1+j0]:=map[i+k][j1];
        setLength(map[i+k],0);
      end;
      setLength(map,k);
      hashMask:=k-1;
    end else if grow then begin
      //split
      oldLen:=length(map);
      setLength(map,oldLen+oldLen);
      hashMask:=(oldLen+oldLen)-1;
      for i:=0 to oldLen-1 do begin
        j0:=0;
        setLength(map[i+oldLen],length(map[i])); j1:=0;
        for k:=0 to length(map[i])-1 do begin
          if (hashMask and map[i][k].index)=i
            then begin map[i       ][j0]:=map[i][k]; inc(j0); end
            else begin map[i+oldLen][j1]:=map[i][k]; inc(j1); end;
        end;
        setLength(map[i],j0);
        setLength(map[i+oldLen],j1);
      end;
    end;
  end;

FUNCTION G_sparseArray.size:longint;
  begin result:=entryCount;end;

FUNCTION G_sparseArray.entries:INDEXED_ENTRY_ARRAY;
  VAR i,j,k:longint;
  begin
    setLength(result,entryCount);
    k:=0;
    for i:=0 to length(map)-1 do for j:=0 to length(map[i])-1 do begin
      result[k]:=map[i,j];
      inc(k);
    end;
  end;

PROCEDURE G_stringKeyMap.rehash(CONST grow: boolean);
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
          k:=temp[j].hash and (length(bucket)-1);
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

CONSTRUCTOR G_stringKeyMap.create(CONST rebalanceFactor: double; CONST disposer_:VALUE_DISPOSER=nil);
  begin
    system.initCriticalSection(cs);
    rebalanceFac:=rebalanceFactor;
    setLength(bucket,1);
    setLength(bucket[0],0);
    entryCount:=0;
    disposer:=disposer_;
  end;

PROCEDURE G_stringKeyMap.clear;
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

CONSTRUCTOR G_stringKeyMap.create(CONST disposer_:VALUE_DISPOSER=nil);
  begin
    create(4,disposer_);
  end;

CONSTRUCTOR G_stringKeyMap.createClone(VAR map:MY_TYPE);
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

DESTRUCTOR G_stringKeyMap.destroy;
  begin
    clear;
    system.enterCriticalSection(cs);
    setLength(bucket,0);
    system.leaveCriticalSection(cs);
    system.doneCriticalSection(cs);
  end;

FUNCTION G_stringKeyMap.containsKey(CONST key: ansistring; OUT value: VALUE_TYPE): boolean;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=hashOfAnsiString(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    if (j<length(bucket[i])) then begin
      value:=bucket[i][j].value;
      result:=true;
    end else result:=false;
    system.leaveCriticalSection(cs);
  end;

FUNCTION G_stringKeyMap.containsKey(CONST key:ansistring):boolean;
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=hashOfAnsiString(key) and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    result:=(j<length(bucket[i]));
    system.leaveCriticalSection(cs);
  end;

FUNCTION G_stringKeyMap.get(CONST key: ansistring): VALUE_TYPE;
  begin
    containsKey(key,result);
  end;

PROCEDURE G_stringKeyMap.put(CONST key: ansistring; CONST value: VALUE_TYPE);
  VAR i,j,h:longint;
  begin
    system.enterCriticalSection(cs);
    h:=hashOfAnsiString(key);
    i:=h and (length(bucket)-1);
    j:=0;
    while (j<length(bucket[i])) and (bucket[i][j].key<>key) do inc(j);
    if j>=length(bucket[i]) then begin
      setLength(bucket[i],j+1);
      bucket[i][j].key:=key;
      bucket[i][j].hash:=h;
      bucket[i][j].value:=value;
      inc(entryCount);
      if entryCount>length(bucket)*rebalanceFac then rehash(true);
    end else begin
      if disposer<>nil then disposer(bucket[i][j].value);
      bucket[i][j].value:=value;
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_stringKeyMap.putAll(CONST entries:KEY_VALUE_LIST);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    for i:=0 to length(entries)-1 do put(entries[i].key,entries[i].value);
    system.leaveCriticalSection(cs);
  end;

PROCEDURE G_stringKeyMap.dropKey(CONST key: ansistring);
  VAR i,j:longint;
  begin
    system.enterCriticalSection(cs);
    i:=hashOfAnsiString(key) and (length(bucket)-1);
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

FUNCTION G_stringKeyMap.keySet: T_arrayOfString;
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

FUNCTION G_stringKeyMap.valueSet: VALUE_TYPE_ARRAY;
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

FUNCTION G_stringKeyMap.entrySet: KEY_VALUE_LIST;
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

FUNCTION G_stringKeyMap.size: longint;
  begin
    system.enterCriticalSection(cs);
    result:=entryCount;
    system.leaveCriticalSection(cs);
  end;

end.

