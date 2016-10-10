UNIT globalFormHandler;
INTERFACE
USES
  Classes, sysutils,Forms,math;

CONST SLOT_SIZE:longint=32;
      FREE_INDEX=255;
      DESKTOP_INDEX=254;
      MIN_FORM_WIDTH=4;
      MIN_FORM_HEIGHT=4;
TYPE
  T_slotRange=record
    x0,x1,y0,y1:longint;
  end;

  T_direction=(d_left,d_right,d_up,d_down);

  { T_slotMap }

  T_slotMap=object
    mapWidth,mapHeight:longint;
    occupied:array of byte;
    CONSTRUCTOR create;
    DESTRUCTOR destroy;
    PROCEDURE clear;
    FUNCTION occupy(CONST r:T_slotRange; CONST occupyIndex:byte):byte;
    FUNCTION isFree(CONST r:T_slotRange):boolean;
    FUNCTION windowPositionToSlotRange(CONST Left,top,height,width:longint):T_slotRange;
    PROCEDURE slotRangeToWindowPosition(CONST r:T_slotRange; OUT Left,top,height,width:longint);
  end;

  P_formMeta=^T_formMeta;

  { T_formMeta }

  T_formMeta=object
    form:TForm;
    sizable:boolean;
    slotRange:T_slotRange;
    myIndex:byte;
    callbacks:record
      resize,changeBounds,show,hide:TNotifyEvent;
    end;

    CONSTRUCTOR create(CONST form_:TForm; CONST sizable_:boolean; CONST index:byte);
    DESTRUCTOR destroy;
    PROCEDURE fetchPosition(VAR map:T_slotMap);
    PROCEDURE trimToDesktop(VAR map:T_slotMap);
    PROCEDURE applyPosition(VAR map:T_slotMap);
    FUNCTION shrinks(CONST dir:T_direction; VAR map:T_slotMap):boolean;
    FUNCTION moves(CONST dir:T_direction; VAR map:T_slotMap):boolean;
    FUNCTION grows(VAR map:T_slotMap):boolean;
    FUNCTION visible: boolean;
    FUNCTION requiredSlotSize:T_slotRange;

    PROCEDURE FormResize(Sender: TObject);
    PROCEDURE FormChangeBounds(Sender: TObject);
    PROCEDURE FormShow(Sender: TObject);
    PROCEDURE FormHide(Sender: TObject);
  end;

PROCEDURE registerForm(CONST f:TForm; CONST canResize:boolean);
PROCEDURE unregisterForm(CONST f:TForm);
PROCEDURE formStatusChange(CONST f:TForm);
PROCEDURE arrangeForms(CONST triggeredBy:longint);

VAR autoarrangeForms:boolean=true;
IMPLEMENTATION
VAR formMeta:array of P_formMeta;
    arranging:boolean=false;

FUNCTION indexOfForm(CONST f:TForm):longint;
  VAR i:longint;
  begin
    for i:=0 to length(formMeta)-1 do if formMeta[i]^.form=f then exit(i);
    result:=-1;
  end;

PROCEDURE arrangeForms(CONST triggeredBy:longint);
  VAR i:longint;
      conflictIndex:byte;
      conflictForm1,conflictForm2:byte;
      growing,
      changedInThisLoop:boolean;
      changed:boolean=false;
      map:T_slotMap;

  FUNCTION slotCenterX(CONST r:T_slotRange):longint;
    begin
      result:=r.x0+r.x1;
    end;

  FUNCTION slotCenterY(CONST r:T_slotRange):longint;
    begin
      result:=r.y0+r.y1;
    end;

  PROCEDURE resolveUnbiasedConflict(CONST meta1,meta2:P_formMeta);
    VAR dx,dy:longint;
    begin
      dx:=slotCenterX(meta1^.slotRange)-slotCenterX(meta2^.slotRange);
      dy:=slotCenterY(meta1^.slotRange)-slotCenterY(meta2^.slotRange);
      writeln('Resolving unbiased conflict between ',meta1^.form.toString,' and ',meta2^.form.toString,'; dx=',dx,'; dy=',dy);
      map.clear;
      if abs(dx)>abs(dy) then begin
        if dx<0 then begin
          meta1^.shrinks(d_left,map);
          meta2^.shrinks(d_right,map);
        end else begin
          meta1^.shrinks(d_right,map);
          meta2^.shrinks(d_left,map);
        end;
      end else if dy<0 then begin
        meta1^.shrinks(d_up,map);
        meta2^.shrinks(d_down,map);
      end else if dy>0 then begin
        meta1^.shrinks(d_down,map);
        meta2^.shrinks(d_up,map);
      end else begin
        meta1^.shrinks(d_left,map);
        meta2^.shrinks(d_right,map);
      end;
    end;


  PROCEDURE resolveBiasedConflict(CONST other:P_formMeta);
    VAR triggeringMeta:P_formMeta;
        dx,dy:longint;
    begin
      triggeringMeta:=formMeta[triggeredBy];
      dx:=slotCenterX(other^.slotRange)-slotCenterX(triggeringMeta^.slotRange);
      dy:=slotCenterY(other^.slotRange)-slotCenterY(triggeringMeta^.slotRange);
      map.clear;
      if abs(dx)>abs(dy) then begin
        if dx<0 then begin
          //other is left of triggering -> shrink leftwards, triggering shrinks rightwards as fallback
          if not(other^.shrinks(d_left,map)) then triggeringMeta^.shrinks(d_right,map);
        end else begin
          if not(other^.shrinks(d_right,map)) then triggeringMeta^.shrinks(d_left,map);
        end;
      end else if dy<0 then begin
        if not(other^.shrinks(d_up,map)) then triggeringMeta^.shrinks(d_down,map);
      end else if dy>0 then begin
        if not(other^.shrinks(d_down,map)) then triggeringMeta^.shrinks(d_up,map);
      end else begin
        if not(other^.shrinks(d_left,map)) then triggeringMeta^.shrinks(d_right,map);
      end;
    end;


  begin
    if arranging then exit;
    arranging:=true;
    map.create;
    for i:=0 to length(formMeta)-1 do formMeta[i]^.fetchPosition(map);
    repeat
      changedInThisLoop:=false;
      //collect conflicts
      map.clear;
      conflictForm1:=FREE_INDEX;
      conflictForm2:=FREE_INDEX;
      for i:=0 to length(formMeta)-1 do if formMeta[i]^.visible then begin
        conflictIndex:=map.occupy(formMeta[i]^.slotRange,i);
        if (conflictForm1=FREE_INDEX) and (conflictIndex<>FREE_INDEX) then begin
          conflictForm1:=conflictIndex;
          conflictForm2:=i;
        end;
      end;
      //resolve conflicts
      if (conflictForm1<>FREE_INDEX) then begin
        if conflictForm1=DESKTOP_INDEX then formMeta[conflictForm2]^.trimToDesktop(map)
        else if conflictForm1=triggeredBy then resolveBiasedConflict(formMeta[conflictForm2])
        else if conflictForm2=triggeredBy then resolveBiasedConflict(formMeta[conflictForm1])
        else resolveUnbiasedConflict(formMeta[conflictForm1],formMeta[conflictForm2]);
        changedInThisLoop:=true;
      end else
      //grow
      repeat
        growing:=false;
        for i:=0 to length(formMeta)-1 do growing:=growing or formMeta[i]^.grows(map);
        changedInThisLoop:=changedInThisLoop or growing;
      until not(growing);
      changed:=changed or changedInThisLoop;
    until not(changedInThisLoop);
    if changed then for i:=0 to length(formMeta)-1 do formMeta[i]^.applyPosition(map);
    map.destroy;
    arranging:=false;
  end;

PROCEDURE registerForm(CONST f: TForm; CONST canResize: boolean);
  VAR i:longint;
  begin
    i:=indexOfForm(f);
    if i<0 then begin
      i:=length(formMeta);
      setLength(formMeta,i+1);
      new(formMeta[i],create(f,canResize,i));
    end;
  end;

PROCEDURE unregisterForm(CONST f: TForm);
  VAR i:longint;
  begin
    i:=indexOfForm(f);
    if i<0 then exit;
    dispose(formMeta[i],destroy);
    while i<length(formMeta)-1 do begin
      formMeta[i]:=formMeta[i+1];
      inc(i);
    end;
    setLength(formMeta,length(formMeta)-1);
  end;

PROCEDURE formStatusChange(CONST f: TForm);
  VAR i:longint;
  begin
    if not(autoarrangeForms) then exit;
    i:=indexOfForm(f);
    if i<0 then exit;
    arrangeForms(i);
  end;

{ T_slotMap }

CONSTRUCTOR T_slotMap.create;
  begin
    mapWidth:=screen.WorkAreaWidth div SLOT_SIZE;
    mapHeight:=screen.WorkAreaHeight div SLOT_SIZE;
    setLength(occupied,mapWidth*mapHeight);
    clear;
  end;

DESTRUCTOR T_slotMap.destroy;
  begin
    setLength(occupied,0);
  end;

PROCEDURE T_slotMap.clear;
  VAR i:longint;
  begin
    for i:=0 to length(occupied)-1 do occupied[i]:=FREE_INDEX;
  end;

FUNCTION T_slotMap.occupy(CONST r: T_slotRange; CONST occupyIndex: byte): byte;
  VAR x,y:longint;
  begin
    if (r.x0<0) or (r.y0<0) or (r.x1>=mapWidth) or (r.y1>=mapHeight)
    then result:=DESKTOP_INDEX
    else result:=FREE_INDEX;
    for y:=max(0,r.y0) to min(mapHeight-1,r.y1) do
    for x:=max(0,r.x0) to min(mapWidth -1,r.x1) do begin
      if result=FREE_INDEX then result:=occupied[x+y*mapWidth];
      occupied[x+y*mapWidth]:=occupyIndex;
    end;
  end;

FUNCTION T_slotMap.isFree(CONST r: T_slotRange): boolean;
  VAR x,y:longint;
  begin
    result:=(r.y0>=0) and (r.x0>=0) and (r.y1<mapHeight) and (r.x1<mapWidth);
    if not(result) then exit(result);
    for y:=max(0,r.y0) to min(mapHeight-1,r.y1) do
    for x:=max(0,r.x0) to min(mapWidth-1 ,r.x1) do result:=result and (occupied[x+y*mapWidth]=FREE_INDEX);
  end;

FUNCTION T_slotMap.windowPositionToSlotRange(CONST Left, top, height, width: longint): T_slotRange;
  begin
    result.x0:=(Left-screen.WorkAreaLeft)         div SLOT_SIZE;
    if Left+width-screen.WorkAreaLeft=screen.WorkAreaWidth
    then result.x1:=mapWidth-1
    else result.x1:=(Left-screen.WorkAreaLeft+width-1) div SLOT_SIZE;
    result.y0:=(top-screen.WorkAreaTop)           div SLOT_SIZE;
    if top+height-screen.WorkAreaTop=screen.WorkAreaHeight
    then result.y1:=mapHeight-1
    else result.y1:=(top-screen.WorkAreaTop+height-1)  div SLOT_SIZE;
  end;

PROCEDURE T_slotMap.slotRangeToWindowPosition(CONST r: T_slotRange; OUT Left, top, height, width: longint);
  begin
    Left:=r.x0*SLOT_SIZE+screen.WorkAreaLeft;
    if r.x1=mapWidth-1
    then width:=screen.WorkAreaWidth-Left
    else width:=(r.x1-r.x0+1)*SLOT_SIZE-1;
    top:=r.y0*SLOT_SIZE+screen.WorkAreaTop;
    if r.y1=mapHeight-1
    then height:=screen.WorkAreaHeight-top
    else height:=(r.y1-r.y0+1)*SLOT_SIZE-1;
  end;

{ T_formMeta }

constructor T_formMeta.create(const form_: TForm; const sizable_: boolean;
  const index: byte);
  begin
    form:=form_;
    sizable:=(sizable_) and (form_<>nil);
    myIndex:=index;
    callbacks.resize:=form.OnResize;             form.OnResize:=@FormResize;
    callbacks.changeBounds:=form.OnChangeBounds; form.OnChangeBounds:=@FormChangeBounds;
    callbacks.hide:=form.OnHide;                 form.OnHide:=@FormHide;
    callbacks.show:=form.OnShow;                 form.OnShow:=@FormShow;
  end;

destructor T_formMeta.destroy;
  begin
    form.OnResize:=callbacks.resize;
    form.OnChangeBounds:=callbacks.changeBounds;
    form.OnHide:=callbacks.hide;
    form.OnShow:=callbacks.show;
  end;

procedure T_formMeta.fetchPosition(var map: T_slotMap);
  begin
    if not(visible) then exit;
    slotRange:=map.windowPositionToSlotRange(form.Left,form.top,form.height,form.width);
  end;

procedure T_formMeta.trimToDesktop(var map: T_slotMap);
  VAR required:T_slotRange;
  begin
    required:=requiredSlotSize;
    if slotRange.x0<0 then begin
      slotRange.x0:=0;
      if slotRange.x1-slotRange.x0<required.x1 then begin
        slotRange.x1:=slotRange.x0+required.x1;
        map.occupy(slotRange,myIndex);
      end;
    end;
    if slotRange.y0<0 then begin
      slotRange.y0:=0;
      if slotRange.y1-slotRange.y0<required.y1 then begin
        slotRange.y1:=slotRange.y0+required.y1;
        map.occupy(slotRange,myIndex);
      end;
    end;
    if slotRange.x1>=map.mapWidth then begin
      slotRange.x1:=map.mapWidth-1;
      if slotRange.x1-slotRange.x0<required.x1 then begin
        slotRange.x0:=slotRange.x1-required.x1;
        map.occupy(slotRange,myIndex);
      end;
    end;
    if slotRange.y1>=map.mapHeight then begin
      slotRange.y1:=map.mapHeight-1;
      if slotRange.y1-slotRange.y0<required.y1 then begin
        slotRange.y0:=slotRange.y1-required.y1;
        map.occupy(slotRange,myIndex);
      end;
    end;
  end;

procedure T_formMeta.applyPosition(var map: T_slotMap);
  VAR Left,width,top,height:longint;
  begin
    if not(visible) then exit;
    map.slotRangeToWindowPosition(slotRange,Left,top,height,width);
    form.Left:=Left;
    form.width:=width;
    form.top:=top;
    form.height:=height;
    with slotRange do writeln(form.toString,' apply position ',x0,'..',x1,'x',y0,'..',y1);
  end;

FUNCTION vStrip(CONST x,y0,y1:longint):T_slotRange;
  begin
    result.x0:=x;  result.x1:=x;
    result.y0:=y0; result.y1:=y1;
  end;
FUNCTION hStrip(CONST x0,x1,y:longint):T_slotRange;
  begin
    result.x0:=x0; result.x1:=x1;
    result.y0:=y;  result.y1:=y;
  end;

function T_formMeta.shrinks(const dir: T_direction; var map: T_slotMap
  ): boolean;
  begin
    result:=false;
    case dir of
      d_left: if (slotRange.x1-slotRange.x0)<=requiredSlotSize.x1 then result:=moves(d_left,map) else begin
        map.occupy(vStrip(slotRange.x1,slotRange.y0,slotRange.y1),FREE_INDEX);
        dec(slotRange.x1);
        result:=true;
      end;
      d_right: if (slotRange.x1-slotRange.x0)<=requiredSlotSize.x1 then result:=moves(d_right,map) else begin
        map.occupy(vStrip(slotRange.x0,slotRange.y0,slotRange.y1),FREE_INDEX);
        inc(slotRange.x0);
        result:=true;
      end;
      d_up: if (slotRange.y1-slotRange.y0)<=requiredSlotSize.y1 then result:=moves(d_up,map) else begin
        map.occupy(hStrip(slotRange.x0,slotRange.x1,slotRange.y1),FREE_INDEX);
        dec(slotRange.y1);
        result:=true;
      end;
      d_down: if (slotRange.y1-slotRange.y0)<=requiredSlotSize.y1 then result:=moves(d_down,map) else begin
        map.occupy(hStrip(slotRange.x0,slotRange.x1,slotRange.y0),FREE_INDEX);
        inc(slotRange.y0);
        result:=true;
      end;
    end;
    writeln(form.toString,' shrinks ',dir,' ',result);
    with slotRange do writeln('    ',x0,'..',x1,'x',y0,'..',y1);
  end;

function T_formMeta.moves(const dir: T_direction; var map: T_slotMap): boolean;
  begin
    result:=false;
    case dir of
      d_left: if map.isFree(vStrip(slotRange.x0-1,slotRange.y0,slotRange.y1)) then begin
        dec(slotRange.x0);
        map.occupy(slotRange,myIndex);
        map.occupy(vStrip(slotRange.x1,slotRange.y0,slotRange.y1),FREE_INDEX);
        dec(slotRange.x1);
        result:=true;
      end;
      d_right: if map.isFree(vStrip(slotRange.x1+1,slotRange.y0,slotRange.y1)) then begin
        inc(slotRange.x1);
        map.occupy(slotRange,myIndex);
        map.occupy(vStrip(slotRange.x0,slotRange.y0,slotRange.y1),FREE_INDEX);
        inc(slotRange.x0);
        result:=true;
      end;
      d_up: if map.isFree(hStrip(slotRange.x0,slotRange.x1,slotRange.y0-1)) then begin
        dec(slotRange.y0);
        map.occupy(slotRange,myIndex);
        map.occupy(hStrip(slotRange.x0,slotRange.x1,slotRange.y1),FREE_INDEX);
        dec(slotRange.y1);
        result:=true;
      end;
      d_down: if map.isFree(hStrip(slotRange.x0,slotRange.x1,slotRange.y1+1)) then begin
        inc(slotRange.y1);
        map.occupy(slotRange,myIndex);
        map.occupy(hStrip(slotRange.x0,slotRange.x1,slotRange.y0),FREE_INDEX);
        inc(slotRange.y0);
        result:=true;
      end;
    end;
    writeln(form.toString,' moves ',dir,' ',result);
    with slotRange do writeln('    ',x0,'..',x1,'x',y0,'..',y1);
  end;

function T_formMeta.grows(var map: T_slotMap): boolean;
  begin
    if not(visible) then exit(false);
    if not(sizable) then exit(moves(d_left ,map) or
                              moves(d_up   ,map) or
                              moves(d_right,map) or
                              moves(d_down ,map));
    result:=false;
    if map.isFree(vStrip(slotRange.x0-1,slotRange.y0,slotRange.y1)) then begin
      dec(slotRange.x0);
      map.occupy(slotRange,myIndex);
      result:=true;
    end;
    if map.isFree(hStrip(slotRange.x0,slotRange.x1,slotRange.y0-1)) then begin
      dec(slotRange.y0);
      map.occupy(slotRange,myIndex);
      result:=true;
    end;
    if not(sizable) and result then exit(result);
    if map.isFree(vStrip(slotRange.x1+1,slotRange.y0,slotRange.y1)) then begin
      inc(slotRange.x1);
      map.occupy(slotRange,myIndex);
      result:=true;
    end;
    if map.isFree(hStrip(slotRange.x0,slotRange.x1,slotRange.y1+1)) then begin
      inc(slotRange.y1);
      map.occupy(slotRange,myIndex);
      result:=true;
    end;
  end;

function T_formMeta.visible: boolean;
  begin
    result:=(form<>nil) and (form.visible);
  end;

function T_formMeta.requiredSlotSize: T_slotRange;
  begin
    result.x0:=0;
    result.y0:=0;
    if sizable then result.x1:=MIN_FORM_WIDTH-1
               else result.x1:=slotRange.x1-slotRange.x0;
    if sizable then result.y1:=MIN_FORM_HEIGHT-1
               else result.y1:=slotRange.y1-slotRange.y0;
  end;

VAR handlingGUIevent:boolean=false;

procedure T_formMeta.FormResize(Sender: TObject);
  begin
    writeln('FormResize for ',form.ToString);
    if not(handlingGUIevent) then begin
      handlingGUIevent:=true;
      formStatusChange(form);
      handlingGUIevent:=false;
    end;
    if Assigned(callbacks.resize) then callbacks.resize(sender);
  end;

procedure T_formMeta.FormChangeBounds(Sender: TObject);
  begin
    writeln('FormChangeBounds for ',form.ToString);
    if not(handlingGUIevent) then begin
      handlingGUIevent:=true;
      formStatusChange(form);
      handlingGUIevent:=false;
    end;
    if Assigned(callbacks.changeBounds) then callbacks.changeBounds(sender);
  end;

procedure T_formMeta.FormShow(Sender: TObject);
  begin
    writeln('FormShow for ',form.ToString);
    if not(handlingGUIevent) then begin
      handlingGUIevent:=true;
      formStatusChange(form);
      handlingGUIevent:=false;
    end;
    if Assigned(callbacks.show) then callbacks.show(sender);
  end;

procedure T_formMeta.FormHide(Sender: TObject);
  begin
    writeln('FormShow for ',form.ToString);
    if not(handlingGUIevent) then begin
      handlingGUIevent:=true;
      formStatusChange(form);
      handlingGUIevent:=false;
    end;
    if Assigned(callbacks.hide) then callbacks.hide(sender);
  end;


end.

