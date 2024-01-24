UNIT pixMaps;
INTERFACE
USES math,types, myGenerics,myColors;
TYPE
  T_imageDimensions=object
    width,height:longint;
    FUNCTION fitsInto(CONST containedIn:T_imageDimensions):boolean;
    FUNCTION max(CONST other:T_imageDimensions):T_imageDimensions;
    FUNCTION min(CONST other:T_imageDimensions):T_imageDimensions;
    FUNCTION getFittingRectangle(CONST aspectRatio:double):T_imageDimensions;
    FUNCTION toRect:TRect;
  end;
CONST
  MAX_HEIGHT_OR_WIDTH=9999;
  C_maxImageDimensions:T_imageDimensions=(width:MAX_HEIGHT_OR_WIDTH;height:MAX_HEIGHT_OR_WIDTH);
TYPE
  F_stopRequested=FUNCTION ():boolean of object;
  GENERIC G_pixelMap<PIXEL_TYPE>=object
    TYPE PIXEL_POINTER=^PIXEL_TYPE;
         SELF_TYPE=specialize G_pixelMap<PIXEL_TYPE>;
         P_SELF_TYPE=^SELF_TYPE;
    protected
      dim:T_imageDimensions;
      data:PIXEL_POINTER;
      FUNCTION  getPixel(CONST x,y:longint):PIXEL_TYPE;
      PROCEDURE setPixel(CONST x,y:longint; CONST value:PIXEL_TYPE);
      PROCEDURE resize(CONST newSize:T_imageDimensions);
      FUNCTION dataSize:longint;
      FUNCTION dataSize(CONST width,height:longint):longint;
    public
      CONSTRUCTOR create(CONST initialWidth:longint=1; CONST initialHeight:longint=1);
      DESTRUCTOR destroy;
      PROPERTY pixel[x,y:longint]:PIXEL_TYPE read getPixel write setPixel; default;
      PROPERTY rawData:PIXEL_POINTER read data;
      FUNCTION linePtr(CONST y:longint):PIXEL_POINTER;
      PROPERTY dimensions:T_imageDimensions read dim write resize;
      FUNCTION pixelCount:longint;
      FUNCTION diagonal:double;
      FUNCTION getClone:P_SELF_TYPE;
      PROCEDURE blur(CONST relativeXBlur,relativeYBlur:double; CONST stopRequested:F_stopRequested=nil);
      PROCEDURE boxBlur(CONST relativeXBlur:double; CONST relativeYBlur:double);
      PROCEDURE flip;
      PROCEDURE flop;
      PROCEDURE rotRight;
      PROCEDURE rotLeft;
      PROCEDURE crop(CONST rx0,rx1,ry0,ry1:double);
      PROCEDURE cropAbsolute(CONST x0,x1,y0,y1:longint);
      PROCEDURE clear;
      PROCEDURE copyFromPixMap(VAR srcImage: G_pixelMap);
      PROCEDURE simpleScaleDown(powerOfTwo:byte);
      FUNCTION constantFalse:boolean;
  end;

FUNCTION transpose(CONST dim:T_imageDimensions):T_imageDimensions;
FUNCTION crop(CONST dim:T_imageDimensions; CONST rx0,rx1,ry0,ry1:double):T_imageDimensions;

FUNCTION getSmoothingKernel(CONST sigma:double):T_arrayOfDouble;
OPERATOR =(CONST d1,d2:T_imageDimensions):boolean;
FUNCTION imageDimensions(CONST width,height:longint):T_imageDimensions;
//FUNCTION getFittingRectangle(CONST availableWidth,availableHeight:longint; CONST aspectRatio:double):TRect;

IMPLEMENTATION
OPERATOR =(CONST d1,d2:T_imageDimensions):boolean;
  begin
    result:=(d1.width=d2.width) and (d1.height=d2.height);
  end;

FUNCTION imageDimensions(CONST width, height: longint): T_imageDimensions;
  begin
    result.width:=width;
    result.height:=height;
  end;

FUNCTION T_imageDimensions.fitsInto(CONST containedIn: T_imageDimensions): boolean;
  begin
    result:=(width <=containedIn.width ) and
            (height<=containedIn.height);
  end;

FUNCTION T_imageDimensions.max(CONST other: T_imageDimensions): T_imageDimensions;
  begin
    result.width :=math.max(width ,other.width );
    result.height:=math.max(height,other.height);
  end;

FUNCTION T_imageDimensions.min(CONST other: T_imageDimensions): T_imageDimensions;
  begin
    result.width :=math.min(width ,other.width );
    result.height:=math.min(height,other.height);
  end;

FUNCTION T_imageDimensions.getFittingRectangle(CONST aspectRatio: double): T_imageDimensions;
  begin
    if height*aspectRatio<width
    then result:=imageDimensions(round(height*aspectRatio),height)
    else result:=imageDimensions(width,round(width/aspectRatio));
  end;

FUNCTION T_imageDimensions.toRect: TRect;
  begin
    result:=rect(0,0,width,height);
  end;

FUNCTION getSmoothingKernel(CONST sigma:double):T_arrayOfDouble;
  VAR radius,i:longint;
      sum:double=-1;
      factor:double;
  begin
    if sigma<=1E-3 then begin
      setLength(result,1);
      result[0]:=1;
      exit(result);
    end;
    radius:=round(3*sigma);
    if radius<2 then radius:=2;
    setLength(result,radius+1);
    for i:=0 to radius do begin
      result[i]:=exp(-0.5*sqr(i/sigma));
      sum:=sum+2*result[i];
    end;
    factor:=1/sum;
    for i:=0 to radius do result[i]:=result[i]*factor;
  end;

FUNCTION G_pixelMap.getPixel(CONST x, y: longint): PIXEL_TYPE; begin result:=data[x+y*dim.width]; end;
PROCEDURE G_pixelMap.setPixel(CONST x, y: longint; CONST value: PIXEL_TYPE); begin data[x+y*dim.width]:=value; end;

CONSTRUCTOR G_pixelMap.create(CONST initialWidth: longint;
  CONST initialHeight: longint);
  begin
    dim.width:=initialWidth;
    dim.height:=initialHeight;
    getMem(data,dim.width*dim.height*sizeOf(PIXEL_TYPE));
  end;

DESTRUCTOR G_pixelMap.destroy;
  begin
    freeMem(data,dim.width*dim.height*sizeOf(PIXEL_TYPE));
  end;

PROCEDURE G_pixelMap.resize(CONST newSize: T_imageDimensions);
  begin
    if (newSize.width=dim.width) and (newSize.height=dim.height) then exit;
    freeMem(data,dataSize);
    dim:=newSize;
    getMem(data,dataSize);
  end;

FUNCTION G_pixelMap.dataSize: longint;
  begin
    result:=pixelCount*sizeOf(PIXEL_TYPE);
  end;

FUNCTION G_pixelMap.dataSize(CONST width, height: longint): longint;
  begin
    result:=width*height*sizeOf(PIXEL_TYPE);
  end;

FUNCTION G_pixelMap.linePtr(CONST y: longint): PIXEL_POINTER;
  begin
    result:=@(data[dim.width*y]);
  end;

FUNCTION G_pixelMap.pixelCount: longint;
  begin
    result:=dim.width*dim.height;
  end;

FUNCTION G_pixelMap.diagonal: double;
  begin
    result:=sqrt(sqr(double(dim. width))+
                 sqr(double(dim.height)));
  end;

FUNCTION G_pixelMap.getClone: P_SELF_TYPE;
  begin
    new(result,create(dim.width,dim.height));
    move(data^,result^.data^,dataSize);
  end;

PROCEDURE G_pixelMap.blur(CONST relativeXBlur,relativeYBlur:double; CONST stopRequested:F_stopRequested=nil);
  VAR kernel:T_arrayOfDouble;
      temp:SELF_TYPE;
      ptmp:PIXEL_POINTER;
      x,y,z:longint;
      sum:PIXEL_TYPE;
      weight:double;
      shouldStop:F_stopRequested;
  begin
    if stopRequested=nil then shouldStop:=@constantFalse else shouldStop:=stopRequested;
    temp.create(dim.width,dim.height);
    ptmp:=temp.data;
    kernel:=getSmoothingKernel(relativeXBlur/100*diagonal);
    //blur in x-direction:-----------------------------------------------
    for y:=0 to dim.height-1 do if not shouldStop() then for x:=0 to dim.width-1 do begin
      sum:=BLACK; weight:=0;
      for z:=max(-x,1-length(kernel)) to min(dim.width-x,length(kernel))-1 do begin
        sum   :=sum   +data[x+z+y*dim.width]*kernel[abs(z)];
        weight:=weight+                      kernel[abs(z)];
      end;
      if (x<length(kernel)) or (x>dim.width-1-length(kernel))
      then ptmp[x+y*dim.width]:=sum*(1/weight)
      else ptmp[x+y*dim.width]:=sum;
    end;
    //-------------------------------------------------:blur in x-direction
    setLength(kernel,0);
    kernel:=getSmoothingKernel(relativeYBlur/100*diagonal);
    //blur in y-direction:---------------------------------------------------
    for x:=0 to dim.width-1 do if not shouldStop() then for y:=0 to dim.height-1 do begin
      sum:=BLACK; weight:=0;
      for z:=max(-y,1-length(kernel)) to min(dim.height-y,length(kernel))-1 do begin
        sum   :=sum   +ptmp[x+(z+y)*dim.width]*kernel[abs(z)];
        weight:=weight+                        kernel[abs(z)];
      end;
      if (y<length(kernel)) or (y>dim.height-1-length(kernel))
      then data[x+y*dim.width]:=sum*(1/weight)
      else data[x+y*dim.width]:=sum;
    end;
    //-----------------------------------------------------:blur in y-direction
    temp.destroy;
    setLength(kernel,0);
  end;

PROCEDURE G_pixelMap.boxBlur(CONST relativeXBlur:double; CONST relativeYBlur:double);

  VAR radX,radY:longint;
      temp:SELF_TYPE;
      ptmp:PIXEL_POINTER;
      x,y,z:longint;
      sum:PIXEL_TYPE;
      sampleCount:longint;
  begin
    radX:=round(relativeXBlur*diagonal*0.01*sqrt(3)); if radX<0 then radX:=0;
    radY:=round(relativeYBlur*diagonal*0.01*sqrt(3)); if radY<0 then radY:=0;
    if (radX<=0) and (radY<=0) then exit;
    temp.create(dim.width,dim.height);
    ptmp:=temp.data;
    //blur in x-direction:-----------------------------------------------
    for y:=0 to dim.height-1 do for x:=0 to dim.width-1 do begin
      sum:=BLACK;
      sampleCount:=0;
      for z:=max(-x,-radX) to min(dim.width-x-1,radX) do begin
        sum:=sum+data[x+z+y*dim.width];
        inc(sampleCount);
      end;
      ptmp[x+y*dim.width]:=sum*(1/sampleCount);
    end;
    //-------------------------------------------------:blur in x-direction
    //blur in y-direction:---------------------------------------------------
    for x:=0 to dim.width-1 do for y:=0 to dim.height-1 do begin
      sum:=BLACK;
      sampleCount:=0;
      for z:=max(-y,-radY) to min(dim.height-y-1,radY) do begin
        sum:=sum+ptmp[x+(z+y)*dim.width];
        inc(sampleCount);
      end;
      data[x+y*dim.width]:=sum*(1/sampleCount);
    end;
    //-----------------------------------------------------:blur in y-direction
    temp.destroy;
  end;

PROCEDURE G_pixelMap.flip;
  VAR x,y,y1,i0,i1:longint;
      tempCol:PIXEL_TYPE;
  begin
    for y:=0 to dim.height shr 1 do begin
      y1:=dim.height-1-y;
      if y1>y then for x:=0 to dim.width-1 do begin
        i0:=x+y *dim.width;
        i1:=x+y1*dim.width;
        tempCol :=data[i0];
        data[i0]:=data[i1];
        data[i1]:=tempCol;
      end;
    end;
  end;

PROCEDURE G_pixelMap.flop;
  VAR x,y,x1,i0,i1:longint;
      tempCol:PIXEL_TYPE;
  begin
    for y:=0 to dim.height-1 do
    for x:=0 to dim.width shr 1 do begin
      x1:=dim.width-1-x;
      if x1>x then begin
        i0:=x +y*dim.width;
        i1:=x1+y*dim.width;
        tempCol :=data[i0];
        data[i0]:=data[i1];
        data[i1]:=tempCol;
      end;
    end;
  end;

FUNCTION transpose(CONST dim:T_imageDimensions):T_imageDimensions;
  begin
    result.width :=dim.height;
    result.height:=dim.width;
  end;

PROCEDURE G_pixelMap.rotLeft;
    VAR x,y:longint;
      temp:P_SELF_TYPE;
      tempDat:PIXEL_POINTER;
  begin
    temp:=getClone;
    tempDat:=temp^.data;
    x         :=dim.width;
    dim.width :=dim.height;
    dim.height:=x;
    for y:=0 to dim.height-1 do for x:=0 to dim.width -1 do
      data[x+y*dim.width]:=tempDat[(dim.height-1-y)+x*dim.height];
    dispose(temp,destroy);
  end;

PROCEDURE G_pixelMap.rotRight;
  VAR x,y:longint;
      temp:P_SELF_TYPE;
      tempDat:PIXEL_POINTER;
  begin
    temp:=getClone;
    tempDat:=temp^.data;
    x         :=dim.width;
    dim.width :=dim.height;
    dim.height:=x;
    for y:=0 to dim.height-1 do for x:=0 to dim.width -1 do
      data[x+y*dim.width]:=tempDat[y+(dim.width-1-x)*dim.height];
    dispose(temp,destroy);
  end;

FUNCTION crop(CONST dim:T_imageDimensions; CONST rx0,rx1,ry0,ry1:double):T_imageDimensions;
  begin
    result.width :=round(rx1*dim.width )-round(rx0*dim.width );
    result.height:=round(ry1*dim.height)-round(ry0*dim.height);
  end;

PROCEDURE G_pixelMap.crop(CONST rx0, rx1, ry0, ry1: double);
  begin
    cropAbsolute(round(rx0*dim.width),
                 round(rx1*dim.width),
                 round(ry0*dim.height),
                 round(ry1*dim.height));
  end;

PROCEDURE G_pixelMap.cropAbsolute(CONST x0,x1,y0,y1:longint);
  VAR newData:PIXEL_POINTER;
      newXRes,newYRes,x,y:longint;
  begin
    if (x1<=x0) or (y1<=y0) then exit;
    newXRes:=x1-x0;
    newYRes:=y1-y0;
    getMem(newData,dataSize(newXRes,newYRes));
    for y:=y0 to y1-1 do for x:=x0 to x1-1 do
    if (x>=0) and (x<dim.width) and (y>=0) and (y<dim.height)
    then newData[(x-x0)+(y-y0)*newXRes]:=pixel[x,y]
    else newData[(x-x0)+(y-y0)*newXRes]:=BLACK;
    freeMem(data,dataSize);
    dim.width:=newXRes;
    dim.height:=newYRes;
    data:=newData;
  end;

PROCEDURE G_pixelMap.clear;
  begin
    if pixelCount>1 then freeMem(data,dataSize);
    dim.width:=1;
    dim.height:=1;
    getMem(data,dataSize);
  end;

PROCEDURE G_pixelMap.copyFromPixMap(VAR srcImage: G_pixelMap);
  VAR i:longint;
  begin
    resize(srcImage.dim);
    for i:=0 to pixelCount-1 do data[i]:=srcImage.data[i];
  end;

PROCEDURE G_pixelMap.simpleScaleDown(powerOfTwo: byte);
  VAR nx,ny,nw,nh:longint;
      newDat:PIXEL_POINTER;
      l1,l2:PIXEL_POINTER;
  begin
    while powerOfTwo>1 do begin
      nw:=dim.width  shr 1;
      nh:=dim.height shr 1;
      getMem(newDat,dataSize(nw,nh));
      for ny:=0 to nh-1 do begin
        l1:=data+((ny+ny  )*dim.height);
        l2:=data+((ny+ny+1)*dim.height);
        for nx:=0 to nw-1 do
          newDat[nx+ny*nw]:=(l1[nx+nx]+l1[nx+nx+1]
                            +l2[nx+nx]+l2[nx+nx+1])*0.25;
      end;
      freeMem(data,dataSize);
      data:=newDat; newDat:=nil;
      dim.width :=nw;
      dim.height:=nh;
      powerOfTwo:=powerOfTwo shr 1;
    end;
  end;

FUNCTION G_pixelMap.constantFalse:boolean;
  begin result:=false; end;

{FUNCTION FastBitmapToBitmap(FastBitmap: TFastBitmap; Bitmap: TBitmap);
VAR
  X, Y: integer;
  tempIntfImage: TLazIntfImage;
begin
  try
    tempIntfImage := Bitmap.CreateIntfImage; // Temp image could be pre-created and help by owner class to avoid new creation in each frame
    for Y := 0 to FastBitmap.size.Y - 1 do
      for X := 0 to FastBitmap.size.X - 1 do begin
        tempIntfImage.colors[X, Y] := TColorToFPColor(FastPixelToTColor(FastBitmap.Pixels[X, Y]));
      end;
    Bitmap.LoadFromIntfImage(tempIntfImage);
  finally
    tempIntfImage.free;
  end;
end;}

end.
