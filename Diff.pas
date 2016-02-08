UNIT diff;
INTERFACE
USES sysutils, Classes, math;
CONST MAX_DIAGONAL = $FFFFFF; //~16 million
TYPE

{$IFDEF UNICODE}
  P8Bits = PByte;
{$ELSE}
  P8Bits = PAnsiChar;
{$ENDIF}

  PDiags = ^TDiags;
  TDiags = array [-MAX_DIAGONAL .. MAX_DIAGONAL] of integer;

  TChangeKind = (ckNone, ckAdd, ckDelete, ckModify);

  PCompareRec = ^TCompareRec;
  TCompareRec = record
    kind      : TChangeKind;
    oldIndex1,
    oldIndex2,
    int1,int2: integer;
  end;

  PDiffVars = ^TDiffVars;
  TDiffVars = record
    offset1 : integer;
    offset2 : integer;
    len1    : integer;
    len2    : integer;
  end;

  TDiffStats = record
    matches  : integer;
    adds     : integer;
    deletes  : integer;
    modifies : integer;
  end;

  TDiff = object
  private
    fCompareList: TList;
    fDiffList: TList;      //this TList circumvents the need for recursion
    DiagBufferF: pointer;
    DiagBufferB: pointer;
    DiagF, DiagB: PDiags;
    Ints1, Ints2: PInteger;
    fDiffStats: TDiffStats;
    fLastCompareRec: TCompareRec;
    PROCEDURE PushDiff(CONST offset1, offset2, len1, len2: integer);
    FUNCTION  PopDiff: boolean;
    PROCEDURE InitDiagArrays(CONST len1, len2: integer);
    PROCEDURE DiffInt(offset1, offset2, len1, len2: integer);
    FUNCTION SnakeIntF(CONST k,offset1,offset2,len1,len2: integer): boolean;
    FUNCTION SnakeIntB(CONST k,offset1,offset2,len1,len2: integer): boolean;
    PROCEDURE AddChangeInt(CONST offset1, range: integer; ChangeKind: TChangeKind);
    FUNCTION GetCompareCount: integer;
    FUNCTION GetCompare(CONST index: integer): TCompareRec;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy;

    //compare either and array of characters or an array of integers ...
    FUNCTION execute(CONST pInts1, pInts2: PInteger; CONST len1, len2: integer): boolean; overload;
    FUNCTION execute(CONST txt1,txt2:ansistring): boolean; overload;
    //Cancel allows interrupting excessively prolonged comparisons
    PROCEDURE clear;
    PROPERTY count: integer read GetCompareCount;
    PROPERTY Compares[index: integer]: TCompareRec read GetCompare; default;
    PROPERTY DiffStats: TDiffStats read fDiffStats;
  end;

IMPLEMENTATION
CONSTRUCTOR TDiff.create;
begin
  fCompareList := TList.create;
  fDiffList := TList.create;
end;
//------------------------------------------------------------------------------

DESTRUCTOR TDiff.destroy;
begin
  clear;
  fCompareList.free;
  fDiffList.free;
  inherited;
end;
//------------------------------------------------------------------------------

FUNCTION TDiff.execute(CONST pInts1, pInts2: PInteger; CONST len1, len2: integer): boolean;
VAR i, Len1Minus1: integer;
begin
  result:=true;
  try
    clear;

    Len1Minus1 := len1 -1;
    fCompareList.Capacity := len1 + len2;
    getMem(DiagBufferF, sizeOf(integer)*(len1+len2+3));
    getMem(DiagBufferB, sizeOf(integer)*(len1+len2+3));
    Ints1 := pInts1;
    Ints2 := pInts2;
    try
      PushDiff(0, 0, len1, len2);
      while PopDiff do;
    finally
      freeMem(DiagBufferF);
      freeMem(DiagBufferB);
    end;

    //correct the occasional missed match ...
    for i := 1 to count -1 do
      with PCompareRec(fCompareList[i])^ do
        if (kind = ckModify) and (int1 = int2) then
        begin
          kind := ckNone;
          dec(fDiffStats.modifies);
          inc(fDiffStats.matches);
        end;

    //finally, append any trailing matches onto compareList ...
    with fLastCompareRec do
      AddChangeInt(oldIndex1,Len1Minus1-oldIndex1, ckNone);
  finally
  end;
end;
//------------------------------------------------------------------------------

FUNCTION TDiff.execute(CONST txt1,txt2:ansistring): boolean;
  VAR i:longint;
      pInts1,pInts2:PInteger;
  begin
    getMem(pInts1,length(txt1)*sizeOf(integer));
    for i:=1 to length(txt1) do pInts1[i-1]:=ord(txt1[i]);
    getMem(pInts2,length(txt2)*sizeOf(integer));
    for i:=1 to length(txt2) do pInts2[i-1]:=ord(txt2[i]);
    result:=execute(pInts1,pInts2,length(txt1),length(txt2));
    freeMem(pInts1,length(txt1)*sizeOf(integer));
    freeMem(pInts2,length(txt2)*sizeOf(integer));
  end;
//------------------------------------------------------------------------------

PROCEDURE TDiff.PushDiff(CONST offset1, offset2, len1, len2: integer);
  VAR DiffVars: PDiffVars;
  begin
    new(DiffVars);
    DiffVars^.offset1 := offset1;
    DiffVars^.offset2 := offset2;
    DiffVars^.len1 := len1;
    DiffVars^.len2 := len2;
    fDiffList.add(DiffVars);
  end;
//------------------------------------------------------------------------------

FUNCTION  TDiff.PopDiff: boolean;
VAR
  DiffVars: PDiffVars;
  idx: integer;
begin
  idx := fDiffList.count -1;
  result := idx >= 0;
  if not result then exit;
  DiffVars := PDiffVars(fDiffList[idx]);
  with DiffVars^ do
      DiffInt(offset1, offset2, len1, len2);
  dispose(DiffVars);
  fDiffList.Delete(idx);
end;
//------------------------------------------------------------------------------

PROCEDURE TDiff.InitDiagArrays(CONST len1, len2: integer);
VAR
  i: integer;
begin
  //assumes that top and bottom matches have been excluded
  P8Bits(DiagF) := P8Bits(DiagBufferF) - sizeOf(integer)*(MAX_DIAGONAL-(len1+1));
  for i := - (len1+1) to (len2+1) do DiagF^[i] := -MAXINT;
  DiagF^[1] := -1;

  P8Bits(DiagB) := P8Bits(DiagBufferB) - sizeOf(integer)*(MAX_DIAGONAL-(len1+1));
  for i := - (len1+1) to (len2+1) do DiagB^[i] := MAXINT;
  DiagB^[len2-len1+1] := len2;
end;
//------------------------------------------------------------------------------

PROCEDURE TDiff.DiffInt(offset1, offset2, len1, len2: integer);
VAR
  p, k, delta: integer;
begin
  //trim matching bottoms ...
  while (len1 > 0) and (len2 > 0) and (Ints1[offset1] = Ints2[offset2]) do
  begin
    inc(offset1); inc(offset2); dec(len1); dec(len2);
  end;
  //trim matching tops ...
  while (len1 > 0) and (len2 > 0) and (Ints1[offset1+len1-1] = Ints2[offset2+len2-1]) do begin
    dec(len1); dec(len2);
  end;

  //stop diff'ing if minimal conditions reached ...
  if (len1 = 0) then
  begin
    AddChangeInt(offset1 ,len2, ckAdd);
    exit;
  end
  else if (len2 = 0) then
  begin
    AddChangeInt(offset1 ,len1, ckDelete);
    exit;
  end
  else if (len1 = 1) and (len2 = 1) then
  begin
    AddChangeInt(offset1, 1, ckDelete);
    AddChangeInt(offset1, 1, ckAdd);
    exit;
  end;

  p := -1;
  delta := len2 - len1;
  InitDiagArrays(len1, len2);
  if delta < 0 then
  begin
    repeat
      inc(p);
      //nb: the Snake order is important here
      for k := p downto delta +1 do
        if SnakeIntF(k,offset1,offset2,len1,len2) then exit;
      for k := -p + delta to delta-1 do
        if SnakeIntF(k,offset1,offset2,len1,len2) then exit;
      for k := delta -p to -1 do
        if SnakeIntB(k,offset1,offset2,len1,len2) then exit;
      for k := p downto 1 do
        if SnakeIntB(k,offset1,offset2,len1,len2) then exit;
      if SnakeIntF(delta,offset1,offset2,len1,len2) then exit;
      if SnakeIntB(0,offset1,offset2,len1,len2) then exit;
    until(false);
  end else
  begin
    repeat
      inc(p);
      //nb: the Snake order is important here
      for k := -p to delta -1 do
        if SnakeIntF(k,offset1,offset2,len1,len2) then exit;
      for k := p + delta downto delta +1 do
        if SnakeIntF(k,offset1,offset2,len1,len2) then exit;
      for k := delta + p downto 1 do
        if SnakeIntB(k,offset1,offset2,len1,len2) then exit;
      for k := -p to -1 do
        if SnakeIntB(k,offset1,offset2,len1,len2) then exit;
      if SnakeIntF(delta,offset1,offset2,len1,len2) then exit;
      if SnakeIntB(0,offset1,offset2,len1,len2) then exit;
    until(false);
  end;
end;
//------------------------------------------------------------------------------
FUNCTION TDiff.SnakeIntF(CONST k,offset1,offset2,len1,len2: integer): boolean;
VAR
  x,y: integer;
begin
  if DiagF^[k+1] > DiagF^[k-1] then
    y := DiagF^[k+1] else
    y := DiagF^[k-1]+1;
  x := y - k;
  while (x < len1-1) and (y < len2-1) and
    (Ints1[offset1+x+1] = Ints2[offset2+y+1]) do
  begin
    inc(x); inc(y);
  end;
  DiagF^[k] := y;
  result := (DiagF^[k] >= DiagB^[k]);
  if not result then exit;

  inc(x); inc(y);
  PushDiff(offset1+x, offset2+y, len1-x, len2-y);
  PushDiff(offset1, offset2, x, y);
end;
//------------------------------------------------------------------------------

FUNCTION TDiff.SnakeIntB(CONST k,offset1,offset2,len1,len2: integer): boolean;
VAR
  x,y: integer;
begin
  if DiagB^[k-1] < DiagB^[k+1] then
    y := DiagB^[k-1] else
    y := DiagB^[k+1]-1;
  x := y - k;
  while (x >= 0) and (y >= 0) and (Ints1[offset1+x] = Ints2[offset2+y]) do
  begin
    dec(x); dec(y);
  end;
  DiagB^[k] := y;
  result := DiagB^[k] <= DiagF^[k];
  if not result then exit;

  inc(x); inc(y);
  PushDiff(offset1+x, offset2+y, len1-x, len2-y);
  PushDiff(offset1, offset2, x, y);
end;
//------------------------------------------------------------------------------
PROCEDURE TDiff.AddChangeInt(CONST offset1, range: integer; ChangeKind: TChangeKind);
VAR
  i,j: integer;
  compareRec: PCompareRec;
begin
  //first, add any unchanged items into this list ...
  while (fLastCompareRec.oldIndex1 < offset1 -1) do
  begin
    with fLastCompareRec do
    begin
      kind := ckNone;
      inc(oldIndex1);
      inc(oldIndex2);
      int1 := Ints1[oldIndex1];
      int2 := Ints2[oldIndex2];
    end;
    new(compareRec);
    compareRec^ := fLastCompareRec;
    fCompareList.add(compareRec);
    inc(fDiffStats.matches);
  end;

  case ChangeKind of
    ckNone:
      for i := 1 to range do
      begin
        with fLastCompareRec do
        begin
          kind := ckNone;
          inc(oldIndex1);
          inc(oldIndex2);
          int1 := Ints1[oldIndex1];
          int2 := Ints2[oldIndex2];
        end;
        new(compareRec);
        compareRec^ := fLastCompareRec;
        fCompareList.add(compareRec);
        inc(fDiffStats.matches);
      end;
    ckAdd :
      begin
        for i := 1 to range do
        begin
          with fLastCompareRec do
          begin

            //check if a range of adds are following a range of deletes
            //and convert them to modifies ...
            if kind = ckDelete then
            begin
              j := fCompareList.count -1;
              while (j > 0) and (PCompareRec(fCompareList[j-1])^.kind = ckDelete) do
                dec(j);
              PCompareRec(fCompareList[j])^.kind := ckModify;
              dec(fDiffStats.deletes);
              inc(fDiffStats.modifies);
              inc(fLastCompareRec.oldIndex2);
              PCompareRec(fCompareList[j])^.oldIndex2 := fLastCompareRec.oldIndex2;
              PCompareRec(fCompareList[j])^.int2 := Ints2[oldIndex2];
              if j = fCompareList.count-1 then fLastCompareRec.kind := ckModify;
              continue;
            end;

            kind := ckAdd;
            int1 := $0;
            inc(oldIndex2);
            int2 := Ints2[oldIndex2]; //ie what we added
          end;
          new(compareRec);
          compareRec^ := fLastCompareRec;
          fCompareList.add(compareRec);
          inc(fDiffStats.adds);
        end;
      end;
    ckDelete :
      begin
        for i := 1 to range do
        begin
          with fLastCompareRec do
          begin

            //check if a range of deletes are following a range of adds
            //and convert them to modifies ...
            if kind = ckAdd then
            begin
              j := fCompareList.count -1;
              while (j > 0) and (PCompareRec(fCompareList[j-1])^.kind = ckAdd) do
                dec(j);
              PCompareRec(fCompareList[j])^.kind := ckModify;
              dec(fDiffStats.adds);
              inc(fDiffStats.modifies);
              inc(fLastCompareRec.oldIndex1);
              PCompareRec(fCompareList[j])^.oldIndex1 := fLastCompareRec.oldIndex1;
              PCompareRec(fCompareList[j])^.int1 := Ints1[oldIndex1];
              if j = fCompareList.count-1 then fLastCompareRec.kind := ckModify;
              continue;
            end;

            kind := ckDelete;
            int2 := $0;
            inc(oldIndex1);
            int1 := Ints1[oldIndex1]; //ie what we deleted
          end;
          new(compareRec);
          compareRec^ := fLastCompareRec;
          fCompareList.add(compareRec);
          inc(fDiffStats.deletes);
        end;
      end;
  end;
end;
//------------------------------------------------------------------------------

PROCEDURE TDiff.clear;
VAR
  i: integer;
begin
  for i := 0 to fCompareList.count-1 do
    dispose(PCompareRec(fCompareList[i]));
  fCompareList.clear;
  fLastCompareRec.kind := ckNone;
  fLastCompareRec.oldIndex1 := -1;
  fLastCompareRec.oldIndex2 := -1;
  fDiffStats.matches := 0;
  fDiffStats.adds := 0;
  fDiffStats.deletes :=0;
  fDiffStats.modifies :=0;
  Ints1 := nil; Ints2 := nil;
end;
//------------------------------------------------------------------------------

FUNCTION TDiff.GetCompareCount: integer;
begin
  result := fCompareList.count;
end;
//------------------------------------------------------------------------------

FUNCTION TDiff.GetCompare(CONST index: integer): TCompareRec;
begin
  result := PCompareRec(fCompareList[index])^;
end;
//------------------------------------------------------------------------------


end.
