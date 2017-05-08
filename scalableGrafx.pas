UNIT scalableGrafx;
INTERFACE
USES math,ExtCtrls,types,Graphics, IntfGraphics, GraphType, alphaColors;
TYPE
  T_zBufferedColor=record col:T_color; z:single; end;
  T_3DPoint=array[0..2] of double;
  T_anchorPoint=(topLeft   , top   , topRight,
                 Left      , center, Right,
                 bottomLeft, Bottom, bottomRight);
CONST
  BLOCK_LOG2SIZE=4;
  BLOCK_SIZE=1 shl BLOCK_LOG2SIZE;
  BY255=1/255;
  BLACK:T_color=(0,0,0,255);
  NO_COLOR:T_color=(0,0,0,0);
TYPE
  P_pixelLayerBlock=^T_pixelLayerBlock;
  T_pixelLayerBlock=object
    private
      pix:array [0..BLOCK_SIZE-1,0..BLOCK_SIZE-1] of T_zBufferedColor;
      PROCEDURE clear(CONST invertedZLevel:single; CONST color:T_color);
      FUNCTION getColor(CONST x,y:longint):T_color;
      PROCEDURE putPixel(CONST x,y:longint; CONST invZ:single; CONST color:T_color);
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
  end;

  T_fancyCanvas=object
    private
      dat:array of T_pixelLayerBlock;
      datXRes,
      xRes,yRes:longint;
    public
      CONSTRUCTOR create(CONST width,height:longint);
      DESTRUCTOR destroy;
      PROCEDURE resize(CONST width,height:longint);
      PROCEDURE clear(CONST invertedZLevel:single; CONST color:T_color);

      FUNCTION getColor(CONST x,y:longint):T_color;
      PROCEDURE putPixel(CONST x,y:longint; CONST invZ:single; CONST color:T_color);
      PROCEDURE line(CONST x0,y0:longint; CONST invZ0:single; CONST col0:T_color;
                     CONST x1,y1:longint; CONST invZ1:single; CONST col1:T_color; CONST omitLastPixel:boolean=false);
      PROCEDURE triangle(CONST x0,y0:longint; invZ0:single; CONST col0:T_color;
                         CONST x1,y1:longint; invZ1:single; CONST col1:T_color;
                         CONST x2,y2:longint; invZ2:single; CONST col2:T_color; CONST omitLastPixel:boolean=false);
      PROCEDURE putText(CONST helperImage:TImage; CONST text:string; CONST anchor:T_anchorPoint; CONST x,y:longint; CONST invZ:single; CONST col:T_floatColor);

  end;

FUNCTION blend(CONST intransparentBackColor,frontColor:T_color):T_color;
OPERATOR :=(CONST x:T_color):T_floatColor;
OPERATOR :=(CONST x:T_floatColor):T_color;
OPERATOR +(CONST x,y:T_floatColor):T_floatColor;
OPERATOR -(CONST x,y:T_floatColor):T_floatColor;
OPERATOR *(CONST x:T_floatColor; CONST y:double):T_floatColor;
IMPLEMENTATION
FUNCTION blend(CONST intransparentBackColor,frontColor:T_color):T_color;
  VAR fa,ba:double;
  begin
    fa:=frontColor[cc_alpha]*BY255;
    ba:=1-fa;
    result[cc_red  ]:=round(frontColor[cc_red  ]*fa+intransparentBackColor[cc_red  ]*ba);
    result[cc_green]:=round(frontColor[cc_green]*fa+intransparentBackColor[cc_green]*ba);
    result[cc_blue ]:=round(frontColor[cc_blue ]*fa+intransparentBackColor[cc_blue ]*ba);
    result[cc_alpha]:=255;
  end;

OPERATOR :=(CONST x:T_color):T_floatColor;
  VAR c:T_colorChannel;
  begin
    for c in T_colorChannel do result[c]:=x[c]*BY255;
  end;

OPERATOR :=(CONST x:T_floatColor):T_color;
  VAR c:T_colorChannel;
  begin
    for c in T_colorChannel do
    if  x[c]>1                   then result[c]:=255 else
    if (x[c]<0) or (isNan(x[c])) then result[c]:=0
                                 else result[c]:=round(255*x[c]);
  end;

OPERATOR +(CONST x,y:T_floatColor):T_floatColor;
  VAR c:T_colorChannel;
  begin
    for c in T_colorChannel do result[c]:=x[c]+y[c];
  end;

OPERATOR -(CONST x,y:T_floatColor):T_floatColor;
  VAR c:T_colorChannel;
  begin
    for c in T_colorChannel do result[c]:=x[c]-y[c];
  end;

OPERATOR *(CONST x:T_floatColor; CONST y:double):T_floatColor;
  VAR c:T_colorChannel;
  begin
    for c in T_colorChannel do result[c]:=x[c]*y;
  end;

CONSTRUCTOR T_fancyCanvas.create(CONST width, height: longint);
  begin
    setLength(dat,0);
    xRes:=0;
    yRes:=0;
    datXRes:=0;
    resize(width,height);
  end;

DESTRUCTOR T_fancyCanvas.destroy;
  VAR d:T_pixelLayerBlock;
  begin
    for d in dat do d.destroy;
    setLength(dat,0);
    xRes:=0;
    yRes:=0;
    datXRes:=0;
  end;

PROCEDURE T_fancyCanvas.resize(CONST width, height: longint);
  VAR datYRes:longint;
      d:T_pixelLayerBlock;
  begin
    if (xRes=width) and (yRes=height) then exit;
    datXRes:=width  shl BLOCK_LOG2SIZE; if datXRes shr BLOCK_LOG2SIZE<width  then inc(datXRes);
    datYRes:=height shl BLOCK_LOG2SIZE; if datYRes shr BLOCK_LOG2SIZE<height then inc(datYRes);
    for d in dat do d.destroy;
    setLength(dat,datXRes*datYRes);
    for d in dat do d.create;
    xRes:=width;
    yRes:=height;
  end;

PROCEDURE T_fancyCanvas.clear(CONST invertedZLevel: single; CONST color: T_color
  );
  VAR d:T_pixelLayerBlock;
  begin
    for d in dat do d.clear(invertedZLevel,color);
  end;

FUNCTION T_fancyCanvas.getColor(CONST x, y: longint): T_color;
  begin
    if (x<0) or (y<0) or (x>=xRes) or (y>=yRes) then exit(NO_COLOR);
    result:=dat[(x shl BLOCK_LOG2SIZE)+
                (y shl BLOCK_LOG2SIZE)*datXRes].getColor(
                 x and (BLOCK_LOG2SIZE-1),
                 y and (BLOCK_LOG2SIZE-1));
  end;

PROCEDURE T_fancyCanvas.putPixel(CONST x, y: longint; CONST invZ: single; CONST color: T_color);
  begin
    if (x<0) or (y<0) or (x>=xRes) or (y>=yRes) or (color[cc_alpha]=0) or isNan(invZ) or (isInfinite(invZ)) then exit;
    dat[(x shl BLOCK_LOG2SIZE)+
        (y shl BLOCK_LOG2SIZE)*datXRes].putPixel(
         x and (BLOCK_LOG2SIZE-1),
         y and (BLOCK_LOG2SIZE-1),
         invZ,
         color);
  end;

PROCEDURE T_fancyCanvas.line(CONST x0, y0: longint; CONST invZ0: single; CONST col0: T_color;
                             CONST x1, y1: longint; CONST invZ1: single; CONST col1: T_color;
                             CONST omitLastPixel: boolean);
  VAR x ,y ,z :double; c :T_floatColor;
      dx,dy,dz:double; dc:T_floatColor;
      i,imax:longint;
  begin
    x:=x0;
    y:=y0;
    z:=invZ0;
    c:=col0;
    if abs(y1-y0)>abs(x1-x0) then begin
      imax:=abs(y1-y0);
      dz:=1/imax;
      dx:=(x1-x0)*dz;
      dy:=1;
      dc:=(col1-col0)*dz;
    end else begin
      imax:=abs(x1-x0);
      dz:=1/imax;
      dx:=1;
      dy:=(y1-y0)*dz;
      dc:=(col1-col0)*dz;
    end;
    if imax=0 then begin
      if omitLastPixel then exit;
      if invZ1>invZ0
      then putPixel(x1,y1,invZ1,col1)
      else putPixel(x0,y0,invZ0,col0);
    end else begin
      if omitLastPixel then dec(imax);
      for i:=0 to imax do begin
        putPixel(round(x),round(y),z,c);
        x:=x+dx;
        y:=y+dy;
        z:=z+dz;
        c:=c+dc;
      end;
    end;
  end;

PROCEDURE T_fancyCanvas.triangle(CONST x0, y0: longint; invZ0: single; CONST col0: T_color;
                                 CONST x1, y1: longint; invZ1: single; CONST col1: T_color;
                                 CONST x2, y2: longint; invZ2: single; CONST col2: T_color;
                                 CONST omitLastPixel: boolean);
  PROCEDURE hLine(CONST y:longint; x0:longint; invZ0:single; col0:T_color;
                                   x1:longint; invZ1:single; col1:T_color);
    VAR i:longint;
        z,zSlope:double;
        c,cSlope:T_floatColor;
    begin
      if x0=x1 then begin
        if omitLastPixel then exit;
        if invZ1>invZ0
        then putPixel(x1,y1,invZ1,col1)
        else putPixel(x0,y0,invZ0,col0);
        exit;
      end else if x0>x1 then begin
        i:=x0;    x0   :=x1;    x1   :=i;
        z:=invZ0; invZ0:=invZ1; invZ1:=z;
        c:=col0;  col0 :=col1;  col1 :=c;
      end;
      zSlope:=(invZ1-invZ0)   /(x1-x0) ; z:=invZ0;
      cSlope:=(col1 -col0 )*(1/(x1-x0)); c:=col0;
      if omitLastPixel then dec(x1);
      for i:=x0 to x1 do begin
        if (i>=0) and (i<xRes) then putPixel(i,y,z,c);
        z:=z+zSlope;
        c:=c+cSlope;
      end;
    end;

  TYPE T_side=record
         x,invZ:double;
         col:T_floatColor;
       end;

       T_vertex=record
         x,y:longint;
         invZ:double;
         col:T_color;
       end;

  PROCEDURE incSide(VAR s:T_side; CONST i:T_side); inline;
    begin
      s.x   :=s.x   +i.x;
      s.invZ:=s.invZ+i.invZ;
      s.col :=s.col +i.col;
    end;

  FUNCTION vertexToSide(CONST v:T_vertex):T_side; inline;
    begin
      result.x   :=v.x;
      result.invZ:=v.invZ;
      result.col :=v.col;
    end;

  FUNCTION vertexToSlope(CONST v0,v1:T_Vertex):T_side; inline;
    VAR f:double;
    begin
      f:=1/(v1.y-v0.y);
      result.x   :=(v1.x   -v0.x   )*f;
      result.invZ:=(v1.invZ-v0.invZ)*f;
      result.col :=(v1.col -v0.col )*f;
    end;

  VAR v:array[0..3] of T_vertex;
      side0,side1,slope0,slope1:T_side;
      i,j:longint;
  begin
    //Copy/sort vertices by y-coordinate
    V[0].x:=x0; V[0].y:=y0; V[0].invZ:=invZ0; V[0].col:=col0;
    V[1].x:=x1; V[1].y:=y1; V[1].invZ:=invZ1; V[1].col:=col1;
    V[2].x:=x2; V[2].y:=y2; V[2].invZ:=invZ2; V[2].col:=col2;
    for i:=1 to 2 do for j:=0 to i-1 do if v[j].y>v[i].y then begin v[3]:=v[i]; v[i]:=v[j]; v[j]:=v[3]; end;

    if (V[1].y>V[0].y) then begin
      side0:=vertexToSide(v[0]);
      side1:=side0;
      slope0:=vertexToSlope(v[0],v[1]);
      slope1:=vertexToSlope(v[0],v[2]);
      for j:=V[0].y to V[1].y do begin
        if (j>=0) and (j<yRes) then
        hLine(j,round(side0.x),side0.invZ,side0.col,
                round(side1.x),side1.invZ,side1.col);
        incSide(side0,slope0);
        incSide(side1,slope1);
      end;
    end else if (V[0].y>=0) and (V[0].y<yRes) then
      hLine(V[0].y,V[0].x,V[0].invZ,V[0].col,
                   V[1].x,V[1].invZ,V[1].col);

    if (V[2].y>V[1].y) then begin
      side0:=vertexToSide(v[2]);
      side1:=side0;
      slope0:=vertexToSlope(v[2],v[0]);
      slope1:=vertexToSlope(v[1],v[0]);
      for j:=V[2].y downto V[1].y+1 do begin
        if (j>=0) and (j<yRes) then
        hLine(j,round(side0.x),side0.invZ,side0.col,
                round(side1.x),side1.invZ,side1.col);
        incSide(side0,slope0);
        incSide(side1,slope1);
      end;
    end else if (V[2].y>=0) and (V[2].y<yRes) then
      hLine(V[1].y,V[1].x,V[1].invZ,V[1].col,
                   V[2].x,V[2].invZ,V[2].col);
  end;

CONSTRUCTOR T_pixelLayerBlock.create;
  begin
    next:=nil;
    clear(-infinity,NO_COLOR);
  end;

DESTRUCTOR T_pixelLayerBlock.destroy;
  begin
    if next<>nil then dispose(next,destroy);
    next:=nil;
  end;

PROCEDURE T_pixelLayerBlock.clear(CONST invertedZLevel: single; CONST color: T_color);
  begin
    if next<>nil then dispose(next,destroy);
  end;

FUNCTION T_pixelLayerBlock.getColor(CONST x, y: longint): T_color;
  VAR layer:P_pixelLayerBlock;
  begin
    result:=pix[x,y].col;
    layer:=next;
    while layer<>nil do begin
      result:=blend(result,pix[x,y].col);
      layer:=layer^.next;
    end;
  end;

PROCEDURE T_pixelLayerBlock.putPixel(CONST x, y: longint; CONST invZ: single; CONST color: T_color);
  VAR closerLayer,
      furtherLayer:P_pixelLayerBlock;
      temp,tmp2:T_zBufferedColor;
  begin
    //Cases:
    //  A->[gone]
    //===FAR_PIXEL (this layer)=======
    //
    //------------------------------------
    //  B->[replace far]  C->[insert]
    //------closerLayer-------------------

    if (invZ<pix[x,y].z) then exit; //(A)

    closerLayer:=next;
    while (closerLayer<>nil) and (invZ<closerLayer^.pix[x,y].z) do closerLayer:=closerLayer^.next;

    if color[cc_alpha]=255 then begin
      //(B)
      pix[x,y].col:=color;
      pix[x,y].z  :=invZ;
      furtherLayer:=next;
      if furtherLayer<>closerLayer then begin
        while closerLayer<>nil do begin
          furtherLayer^.pix[x,y]:=closerLayer^.pix[x,y];
          furtherLayer:=furtherLayer^.next;
          closerLayer :=closerLayer^.next;
        end;
        while furtherLayer<>nil do begin
          furtherLayer^.pix[x,y].col:=NO_COLOR;
          furtherLayer^.pix[x,y].z  :=-infinity;
          furtherLayer:=furtherLayer^.next;
        end;
      end;
    end else begin
      //(C)
      //   0=======      0=======
      //
      //   1-------  --\ 1-------
      //     ***     --/
      //                 -***-new
      if closerLayer=nil then begin
        closerLayer:=@self;
        while closerLayer^.next<>nil do closerLayer:=closerLayer^.next;
        new(closerLayer^.next,create);
        closerLayer:=closerLayer^.next;
        closerLayer^.pix[x,y].col:=color;
        closerLayer^.pix[x,y].z  :=invZ;
        exit;
      end;
      //(C)
      //   0=======      0=======
      //
      //   1-------      1-------
      //     ***
      //   2-closer  --\ --***---
      //             --/
      //   3-------      2-------
      //
      //                 3----new
      temp.col:=color;
      temp.z  :=invZ;
      while closerLayer<>nil do begin
        tmp2:=closerLayer^.pix[x,y];
              closerLayer^.pix[x,y]:=temp;
                                     temp:=tmp2;
        //just replaced a fully transparent pixel
        if temp.col[cc_alpha]=0 then exit;
        furtherLayer:=closerLayer;
        closerLayer :=closerLayer^.next;
      end;
      //create new layer above furtherLayer:
      new(furtherLayer^.next,create);
      furtherLayer^.pix[x,y]:=temp;
    end;
  end;

end.
