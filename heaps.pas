UNIT heaps;
{$mode objfpc}{$H+}
INTERFACE
TYPE

{ T_binaryHeap }

GENERIC T_binaryHeap<T>=object
  TYPE
    T_entry=record prio:double; payload:T; end;
    T_payloadArray=array of T;
    F_calcPrio=FUNCTION(CONST entry:T):double;
    F_compare =FUNCTION(CONST x,y:T):boolean;
  private
    items:array of T_entry;
    fill:longint;
    prioCalculator:F_calcPrio;
    comparator:F_compare;

    PROCEDURE bubbleUp;
    PROCEDURE bubbleDown;
  public
    CONSTRUCTOR createWithNumericPriority(CONST prio:F_calcPrio);
    CONSTRUCTOR createWithComparator(CONST comp:F_compare);
    DESTRUCTOR destroy;
    PROCEDURE insert(CONST v:T);
    PROCEDURE insert(CONST v:T; CONST Priority:double);
    FUNCTION extractHighestPrio:T;
    PROPERTY size:longint read fill;
    FUNCTION getAll:T_payloadArray;
end;

IMPLEMENTATION
{ T_binaryHeap }

PROCEDURE T_binaryHeap.bubbleUp;
  VAR i,j:longint;
      tmp:T_entry;
  begin
    i:=fill-1;
    j:=(i-1) div 2;
    if comparator=nil then begin
      while (i>0) and (items[i].prio>items[j].prio) do begin
        tmp:=items[i]; items[i]:=items[j]; items[j]:=tmp;
        i:=j;
        j:=(i-1) div 2;
      end;
    end else begin
      while (i>0) and comparator(items[i].payload,items[j].payload) do begin
        tmp:=items[i]; items[i]:=items[j]; items[j]:=tmp;
        i:=j;
        j:=(i-1) div 2;
      end;
    end;
  end;

PROCEDURE T_binaryHeap.bubbleDown;
  FUNCTION largerChildIndex(CONST index:longint):longint; inline;
    VAR leftChildIndex,
        rightChildIndex:longint;
    begin
      leftChildIndex :=(index shl 1)+1;
      rightChildIndex:=leftChildIndex+1;

      if leftChildIndex>fill then result:=index else
      if rightChildIndex>fill then result:=leftChildIndex else
      if comparator<>nil then begin
        if comparator(items[leftChildIndex].payload,items[rightChildIndex].payload)
        then result:=leftChildIndex
        else result:=rightChildIndex;
      end else begin
        if items[leftChildIndex].prio>items[rightChildIndex].prio
        then result:=leftChildIndex
        else result:=rightChildIndex;
      end;
    end;

  FUNCTION isValidParent(CONST index:longint):boolean;
    VAR leftChildIndex,
        rightChildIndex:longint;
    begin
      leftChildIndex :=(index shl 1)+1;
      rightChildIndex:=leftChildIndex+1;
      if (leftChildIndex>fill) then exit(true);
      if comparator<>nil then begin
        if not(comparator(items[index].payload,items[leftChildIndex].payload)) then exit(false);
        result:=(rightChildIndex<=fill) and comparator(items[index].payload,items[rightChildIndex].payload);
      end else begin
        if not(items[index].prio>=items[leftChildIndex].prio) then exit(false);
        result:=(rightChildIndex<=fill) and (items[index].prio>=items[rightChildIndex].prio);
      end;
    end;

  VAR i:longint=0;
      j:longint;
      tmp:T_entry;
  begin
    while (i<=fill) and not isValidParent(i) do begin
      j:=largerChildIndex(i);
      tmp:=items[i]; items[i]:=items[j]; items[j]:=tmp;
      i:=j;
    end;
  end;

CONSTRUCTOR T_binaryHeap.createWithNumericPriority(CONST prio: F_calcPrio);
  begin
    setLength(items,1);
    fill:=0;
    prioCalculator:=prio;
    comparator:=nil;
  end;

CONSTRUCTOR T_binaryHeap.createWithComparator(CONST comp: F_compare);
  begin
    assert(comp<>nil);
    setLength(items,1);
    fill:=0;
    prioCalculator:=nil;
    comparator:=comp;
  end;

DESTRUCTOR T_binaryHeap.destroy;
  begin
    setLength(items,0);
  end;

PROCEDURE T_binaryHeap.insert(CONST v: T);
  begin
    assert((prioCalculator<>nil) or (comparator<>nil));
    //ensure space
    if fill>=length(items) then setLength(items,1+(length(items)*5 shr 2));
    //add item
    items[fill].payload:=v;
    //calculate priority if possible
    if prioCalculator<>nil then items[fill].prio:=prioCalculator(v);
    inc(fill);
    if fill>1 then bubbleUp;
  end;

PROCEDURE T_binaryHeap.insert(CONST v:T; CONST Priority:double);
  begin
    //ensure space
    if fill>=length(items) then setLength(items,1+(length(items)*5 shr 2));
    //add item
    items[fill].payload:=v;
    items[fill].prio   :=Priority;
    inc(fill);
    if fill>1 then bubbleUp;
  end;

FUNCTION T_binaryHeap.extractHighestPrio: T;
  begin
    assert(fill>0);
    result:=items[0].payload;
    dec(fill);
    if fill>0 then begin
      items[0]:=items[fill];
      bubbleDown;
    end;
  end;

FUNCTION T_binaryHeap.getAll: T_payloadArray;
  VAR i:longint;
  begin
    setLength(result,fill);
    for i:=0 to fill-1 do result[i]:=items[i].payload;
  end;

end.

