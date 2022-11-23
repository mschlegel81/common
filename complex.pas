UNIT complex;
{$MACRO ON}
INTERFACE
USES sysutils,math;
TYPE
  T_Complex   =record re,im:double; end;
  P_Complex   =^T_Complex;
  T_arrayOfComplex=array of T_Complex;

CONST
   II:T_Complex=(re:0; im:1);
   C_invalidComplex:T_Complex=(re:Nan; im:Nan);

TYPE
  T_boundingBox=record
    x0,y0,x1,y1:double;
  end;

  T_scaler=object
    private
      //input
      relativeZoom,
      rotation:double;
      worldCenter:T_Complex;
      screenWidth  ,screenHeight:longint;
      //derived:
      zoomRot,invZoomRot:T_Complex;
      screenCenter:T_Complex;

      PROCEDURE recalc;
    public
      FUNCTION getCenterX:double;
      PROCEDURE setCenterX(CONST value:double);
      FUNCTION getCenterY:double;
      PROCEDURE setCenterY(CONST value:double);
      FUNCTION getZoom:double;
      PROCEDURE setZoom(CONST value:double);
      FUNCTION getRotation:double;
      PROCEDURE setRotation(CONST value:double);

      CONSTRUCTOR create  (CONST width,height:longint; CONST centerX,centerY,zoom,rotationInDegrees:double);
      PROCEDURE   recreate(CONST width,height:longint; CONST centerX,centerY,zoom,rotationInDegrees:double);
      DESTRUCTOR  destroy;
      FUNCTION    transform(CONST x,y:double   ):T_Complex;
      FUNCTION    mrofsnart(CONST x,y:double   ):T_Complex;
      PROCEDURE   rescale (CONST newWidth,newHeight:longint);
      PROCEDURE   recenter(CONST newCenter:T_Complex);
      PROCEDURE   moveCenter(CONST dx,dy:double);
      PROCEDURE   rotateToHorizontal(CONST screenDx,screenDy:longint);
      FUNCTION getAbsoluteZoom:T_Complex;
      FUNCTION getPositionString(CONST x,y:double; CONST Separator:ansistring='+i*'):ansistring;
      FUNCTION getPixelsBoundingBox:T_boundingBox;
      FUNCTION getWorldBoundingBox:T_boundingBox;
  end;

OPERATOR :=(CONST x:double):T_Complex; inline;

OPERATOR +(CONST x,y:T_Complex):T_Complex; inline;
OPERATOR -(CONST x,y:T_Complex):T_Complex; inline;
OPERATOR *(CONST x,y:T_Complex):T_Complex; inline;
FUNCTION inverse(CONST x:T_Complex):T_Complex; inline;
OPERATOR /(CONST x,y:T_Complex):T_Complex; inline;
OPERATOR **(x:T_Complex; y:longint):T_Complex; inline;
OPERATOR **(x:T_Complex; CONST y:double):T_Complex; inline;
OPERATOR **(x:T_Complex; CONST y:T_Complex):T_Complex; inline;
FUNCTION abs(CONST x:double):double; inline;
FUNCTION abs(CONST x:T_Complex):double; inline;
FUNCTION arg(CONST x:T_Complex):double; inline;
FUNCTION sqr(CONST x:T_Complex):T_Complex; inline;
FUNCTION sqrabs(CONST x:T_Complex):double; inline;
FUNCTION exp(CONST x:double):double; inline;
FUNCTION exp(CONST x:T_Complex):T_Complex; inline;
FUNCTION ln (CONST x:T_Complex):T_Complex; inline;
FUNCTION sin(x:T_Complex):T_Complex; inline;
FUNCTION cos(x:T_Complex):T_Complex; inline;
FUNCTION tan(CONST x:T_Complex):T_Complex; inline;
FUNCTION isValid(CONST c:T_Complex):boolean; inline;

FUNCTION bbIntersect(CONST b1,b2:T_boundingBox):T_boundingBox;
FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2      :T_Complex):boolean;
FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2,p3   :T_Complex):boolean;
FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2,p3,p4,p5:T_Complex):boolean;

FUNCTION DiscreteFourierTransform(CONST X:T_arrayOfComplex; CONST inverse:boolean):T_arrayOfComplex;
FUNCTION FastFourierTransform(CONST X:T_arrayOfComplex; CONST inverse:boolean):T_arrayOfComplex;
IMPLEMENTATION
FUNCTION abs(CONST x:double):double;
  begin
    if x>0 then result:=x else result:=-x;
  end;

OPERATOR :=(CONST x:double):T_Complex;
  begin
    result.re:=x; result.im:=0;
  end;

OPERATOR +(CONST x,y:T_Complex):T_Complex;
  begin
    result.re:=x.re+y.re;
    result.im:=x.im+y.im;
  end;

OPERATOR -(CONST x,y:T_Complex):T_Complex;
  begin
    result.re:=x.re-y.re;
    result.im:=x.im-y.im;
  end;

OPERATOR *(CONST x,y:T_Complex):T_Complex;
  begin
    result.re:=x.re*y.re-x.im*y.im;
    result.im:=x.re*y.im+x.im*y.re;
  end;

FUNCTION inverse(CONST x:T_Complex):T_Complex;
  begin
    result.im:=1/(x.re*x.re+x.im*x.im);
    result.re:= x.re*result.im;
    result.im:=-x.im*result.im;
  end;

OPERATOR /(CONST x,y:T_Complex):T_Complex;
  begin
    result.im:=1/(y.re*y.re+y.im*y.im);
    result.re:=(x.re*y.re+x.im*y.im)*result.im;
    result.im:=(x.im*y.re-x.re*y.im)*result.im;
  end;

FUNCTION exp(CONST x:double):double; inline;
  begin
    {$ifdef CPU32}
    result:=system.exp(x);
    {$else}
    if      x<-745.133219101925 then result:=0
    else if x> 709.782712893375 then result:=infinity
                                else result:=system.exp(x);
    {$endif}
  end;

OPERATOR **(x:T_Complex; CONST y:T_Complex):T_Complex;
  begin
    //result:=exp(ln(x)*y);
    result.re:=x.re*x.re+x.im*x.im;
    result.re:=0.5*system.ln(result.re);
    result.im:=arctan2(x.im,x.re);
    x.re:=result.re*y.re-result.im*y.im;
    x.im:=result.im*y.re+result.re*y.im;
    result.im:=exp(x.re);
    result.re:=system.cos(x.im)*result.im;
    result.im:=system.sin(x.im)*result.im;
  end;

OPERATOR **(x:T_Complex; CONST y:double):T_Complex;
  begin
    //result:=exp(ln(x)*y);
    result.re:=x.re*x.re+x.im*x.im;
    result.re:=0.5*system.ln(result.re);
    result.im:=arctan2(x.im,x.re);
    x.re:=result.re*y;
    x.im:=result.im*y;
    result.im:=exp(x.re);
    result.re:=system.cos(x.im)*result.im;
    result.im:=system.sin(x.im)*result.im;
  end;

OPERATOR **(x:T_Complex; y:longint):T_Complex;
  //Note: This implementation is 100% equivalent to the
  //      academical recursive implementation, but it
  //      avoids the recursion, thus reducing both stack
  //      usage and overhead due to function calls.
  //      Computational cost is in log(y)
  VAR k  :longint;
  begin
    if y=0 then result:=1
    else begin
      if y<0 then begin x:=1/x; y:=-y; end;
      result:=1;
      k:=1;
      while y>0 do begin
        if (y and k)=k then begin
          result:=result*x;
          dec(y,k);
        end;
        k:=k+k;
        x:=sqr(x);
      end;
    end;
  end;

FUNCTION abs(CONST x:T_Complex):double;
  begin
    result:=sqrt(x.re*x.re+x.im*x.im);
  end;

FUNCTION arg(CONST x:T_Complex):double ;
  begin
    result:=arctan2(x.im,x.re);
  end;

FUNCTION sqr(CONST x:T_Complex):T_Complex;
  begin
    result.re:=x.re*x.re-x.im*x.im;
    result.im:=2*x.re*x.im;
  end;

FUNCTION sqrabs(CONST x:T_Complex):double; inline;
  begin result:=x.re*x.re+x.im*x.im; if isNan(result) then result:=infinity; end;

FUNCTION exp(CONST x:T_Complex):T_Complex;
  begin
    result.im:=exp(x.re);
    result.re:=system.cos(x.im)*result.im;
    result.im:=system.sin(x.im)*result.im;
  end;

FUNCTION ln (CONST x:T_Complex):T_Complex;
  begin
    result.re:=0.5*system.ln(x.re*x.re+x.im*x.im);
    result.im:=arctan2(x.im,x.re);
  end;

FUNCTION sin(x:T_Complex):T_Complex;
  begin
    //result:=exp(i*x) --------------------//
    result.im:=exp(-x.im);
    result.re:=system.cos( x.re)*result.im;//
    result.im:=system.sin( x.re)*result.im;//
    //-------------------------------------//
    //result:=result-1/result ------------------------//
    x.im:=1/(result.re*result.re+result.im*result.im);//
    result.re:=result.re-result.re*x.im;              //
    result.im:=result.im+result.im*x.im;              //
    //------------------------------------------------//
    //result:=result/(2*i)=-0.5*i*result //
    x.re:=      0.5*result.im;           //
    result.im:=-0.5*result.re;           //
    result.re:=x.re;                     //
    //-----------------------------------//
  end;

FUNCTION cos(x:T_Complex):T_Complex;
  begin
    //result:=exp(i*x) --------------------//
    result.im:=exp(-x.im);
    result.re:=system.cos( x.re)*result.im;//
    result.im:=system.sin( x.re)*result.im;//
    //-------------------------------------//
    //result:=result+1/result ------------------------//
    x.im:=1/(result.re*result.re+result.im*result.im);//
    result.re:=result.re+result.re*x.im;              //
    result.im:=result.im-result.im*x.im;              //
    //------------------------------------------------//
    //result:=result/(2)=-0.5*result //
    result.re:=result.re*0.5;        //
    result.im:=result.im*0.5;        //
    //-------------------------------//

  end;

FUNCTION tan(CONST x:T_Complex):T_Complex;
  begin
    result:=sin(x)/cos(x);
  end;

FUNCTION isValid(CONST c:T_Complex):boolean; inline;
  begin
    result:=not(isNan     (c.re) or
                isInfinite(c.re) or
                isNan     (c.im) or
                isInfinite(c.im));
  end;

FUNCTION bbIntersect(CONST b1,b2:T_boundingBox):T_boundingBox;
  begin
    result.x0:=max(b1.x0,b2.x0); result.y0:=max(b1.y0,b2.y0);
    result.x1:=min(b1.x1,b2.x1); result.y1:=min(b1.y1,b2.y1);
  end;

FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2      :T_Complex):boolean;
  begin
    result:=(max(p0.re,max(p1.re,p2.re))<b.x0) or
            (min(p0.re,min(p1.re,p2.re))>b.x1) or
            (max(p0.im,max(p1.im,p2.im))<b.y0) or
            (min(p0.im,min(p1.im,p2.im))>b.y1);
  end;

FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2,p3   :T_Complex):boolean;
  begin
    result:=(max(p0.re,max(p1.re,max( p2.re,p3.re)))<b.x0) or
            (min(p0.re,min(p1.re,min( p2.re,p3.re)))>b.x1) or
            (max(p0.im,max(p1.im,max( p2.im,p3.im)))<b.y0) or
            (min(p0.im,min(p1.im,min( p2.im,p3.im)))>b.y1);
  end;

FUNCTION allOutside(CONST b:T_boundingBox; CONST p0,p1,p2,p3,p4,p5:T_Complex):boolean;
  begin
    result:=(max(p0.re,max(p1.re,max( p2.re,max(p3.re,max(p4.re,p5.re)))))<b.x0) or
            (min(p0.re,min(p1.re,min( p2.re,min(p3.re,min(p4.re,p5.re)))))>b.x1) or
            (max(p0.im,max(p1.im,max( p2.im,max(p3.im,max(p4.im,p5.im)))))<b.y0) or
            (min(p0.im,min(p1.im,min( p2.im,min(p3.im,min(p4.im,p5.im)))))>b.y1);
  end;

//T_scaler:======================================================================================================================================
CONSTRUCTOR T_scaler.create(CONST width, height: longint; CONST centerX,centerY, zoom, rotationInDegrees: double);
  begin
    recreate(width,height,centerX,centerY,zoom,rotationInDegrees);
  end;

PROCEDURE T_scaler.recreate(CONST width, height: longint; CONST centerX,centerY, zoom, rotationInDegrees: double);
  begin
    screenWidth :=width;
    screenHeight:=height;
    worldCenter.re:=centerX;
    worldCenter.im:=centerY;
    relativeZoom:=zoom;
    rotation:=rotationInDegrees*pi/180;
    recalc;
  end;

DESTRUCTOR T_scaler.destroy; begin end;

PROCEDURE T_scaler.recalc;
  begin
    zoomRot.re:=system.cos(rotation);
    zoomRot.im:=system.sin(rotation);
    zoomRot:=zoomRot/(relativeZoom*sqrt(screenWidth*screenWidth+screenHeight*screenHeight));
    invZoomRot:=1/zoomRot;
    screenCenter.re:=0.5*screenWidth;
    screenCenter.im:=0.5*screenHeight;
  end;

FUNCTION T_scaler.getCenterX: double;
  begin
    result:=worldCenter.re;
  end;

PROCEDURE T_scaler.setCenterX(CONST value: double);
  begin
    worldCenter.re:=value;
    recalc;
  end;

FUNCTION T_scaler.getCenterY: double;
  begin
    result:=worldCenter.im;
  end;

PROCEDURE T_scaler.setCenterY(CONST value: double);
  begin
    worldCenter.im:=value;
    recalc;
  end;

PROCEDURE T_scaler.recenter(CONST newCenter:T_Complex);
  begin
    worldCenter:=newCenter;
    recalc;
  end;

FUNCTION T_scaler.getZoom: double;
  begin
    result:=relativeZoom;
  end;

PROCEDURE T_scaler.setZoom(CONST value: double);
  begin
    relativeZoom:=value;
    recalc;
  end;

FUNCTION T_scaler.getRotation: double;
  begin
    result:=rotation/pi*180;
  end;

PROCEDURE T_scaler.setRotation(CONST value: double);
  begin
    rotation:=value/180*pi;
    while rotation<-pi do rotation:=rotation+2*pi;
    while rotation> pi do rotation:=rotation-2*pi;
    recalc;
  end;

FUNCTION T_scaler.transform(CONST x, y: double): T_Complex;
  begin
    result.re:=x;
    result.im:=screenHeight-y;
    result:=(result-screenCenter)*zoomRot+worldCenter;
  end;

FUNCTION T_scaler.mrofsnart(CONST x, y: double): T_Complex;
  begin
    result.re:=x;
    result.im:=y;
    result:=(result-worldCenter)*invZoomRot+screenCenter;
    result.im:=screenHeight-result.im;
  end;

PROCEDURE T_scaler.rescale(CONST newWidth, newHeight: longint);
  begin
    screenWidth:=newWidth;
    screenHeight:=newHeight;
    recalc;
  end;

PROCEDURE T_scaler.moveCenter(CONST dx, dy: double);
  VAR delta:T_Complex;
  begin
    delta.re:= dx;
    delta.im:=-dy;
    worldCenter:=worldCenter+delta*zoomRot;
    recalc;
  end;

PROCEDURE T_scaler.rotateToHorizontal(CONST screenDx,screenDy:longint);
  begin
    rotation:=rotation-arctan2(screenDy,screenDx);
    recalc;
  end;

FUNCTION T_scaler.getAbsoluteZoom: T_Complex;
  begin
    result:=zoomRot;
  end;

FUNCTION T_scaler.getPositionString(CONST x, y: double; CONST Separator: ansistring): ansistring;
  VAR p:T_Complex;
  begin
    p:=transform(x,y);
    result:=floatToStr(p.re)+Separator+floatToStr(p.im);
  end;

FUNCTION T_scaler.getPixelsBoundingBox:T_boundingBox;
  begin
    result.x0:=0;
    result.y0:=0;
    result.x1:=screenWidth ;
    result.y1:=screenHeight;
  end;

FUNCTION T_scaler.getWorldBoundingBox:T_boundingBox;
  VAR p:T_Complex;
  begin
    p:=transform(0,0);
    result.x0:=p.re;
    result.x1:=p.re;
    result.y0:=p.im;
    result.y1:=p.im;
    p:=transform(screenWidth,0);
    result.x0:=min(result.x0,p.re);
    result.x1:=max(result.x1,p.re);
    result.y0:=min(result.y0,p.im);
    result.y1:=max(result.y1,p.im);
    p:=transform(screenWidth,screenHeight);
    result.x0:=min(result.x0,p.re);
    result.x1:=max(result.x1,p.re);
    result.y0:=min(result.y0,p.im);
    result.y1:=max(result.y1,p.im);
    p:=transform(0,screenHeight);
    result.x0:=min(result.x0,p.re);
    result.x1:=max(result.x1,p.re);
    result.y0:=min(result.y0,p.im);
    result.y1:=max(result.y1,p.im);
  end;

FUNCTION rootOfUnity(CONST alpha:double):T_Complex; inline;
  begin
    result.re:=system.cos(alpha);
    result.im:=system.sin(alpha);
  end;

FUNCTION DiscreteFourierTransform(CONST X:T_arrayOfComplex; CONST inverse:boolean):T_arrayOfComplex;
  VAR i,j:longint;
      r:T_Complex;
      commonFactor:double;
  begin
    if inverse
    then commonFactor:= 2*pi/length(X)
    else commonFactor:=-2*pi/length(X);

    setLength(result,length(X));
    for j:=0 to length(result)-1 do begin
      r:=0;
      for i:=0 to length(X)-1 do r+=X[i]*rootOfUnity(commonFactor*i*j);
      if inverse
      then result[j]:=r*(1/length(X))
      else result[j]:=r;
    end;
  end;

FUNCTION FastFourierTransform(CONST X:T_arrayOfComplex; CONST inverse:boolean):T_arrayOfComplex;
  CONST Q3a:T_Complex=(re:-0.5;im:-0.86602540378443837);
        Q3b:T_Complex=(re:-0.5;im: 0.86602540378443837);
        Q5a:T_Complex=(re: 0.3090169943749474; im:-0.951056516295153);
        Q5b:T_Complex=(re:-0.8090169943749474; im:-0.587785252292473);
        Q5c:T_Complex=(re:-0.8090169943749474; im: 0.587785252292473);
        Q5d:T_Complex=(re: 0.3090169943749474; im: 0.951056516295153);
  VAR N1:longint=2;
      N2:longint;
      commonFactor:double;
      innerX ,
      innerFT:array of T_arrayOfComplex;
      i,k:longint;
  begin
    N2:=length(x);
    //Find smallest divider of length(X) by trial division
    while (N1*N1<N2) and (N2 mod N1<>0) do inc(N1);
    //Revert to DFT for prime cases
    if N2 mod N1 <> 0 then exit(DiscreteFourierTransform(X,inverse));
    N2:=N2 div N1;

    setLength(innerX ,N1);
    for i:=0 to N1-1 do setLength(innerX[i],N2);
    for i:=0 to length(X)-1 do innerX[i mod N1,i div N1]:=X[i];

    setLength(innerFT,N1);
    for i:=0 to N1-1 do innerFT[i]:=FastFourierTransform(innerX[i],inverse);

    //Twiddle...
    for k:=1 to N1-1 do begin
      if inverse
      then commonFactor:= 2*pi/length(x)*k
      else commonFactor:=-2*pi/length(x)*k;
      for i:=0 to N2-1 do innerFT[k,i]*=rootOfUnity(commonFactor*i);
    end;

    setLength(result,length(X));
    if N1=2 then begin
      if inverse
      then commonFactor:=1/2
      else commonFactor:=1;
      for i:=0 to N2-1 do result[   i]:=(innerFT[0,i]+innerFT[1,i])*commonFactor;
      for i:=0 to N2-1 do result[N2+i]:=(innerFT[0,i]-innerFT[1,i])*commonFactor;
    end else if N1=3 then begin
      if inverse then begin
        commonFactor:=1/3;
        for i:=0 to N2-1 do result[      i]:=(innerFT[0,i]+innerFT[1,i]    +innerFT[2,i]    )*commonFactor;
        for i:=0 to N2-1 do result[   N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q3b+innerFT[2,i]*Q3a)*commonFactor;
        for i:=0 to N2-1 do result[N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q3a+innerFT[2,i]*Q3b)*commonFactor;
      end else begin
        for i:=0 to N2-1 do result[      i]:=(innerFT[0,i]+innerFT[1,i]    +innerFT[2,i]    );
        for i:=0 to N2-1 do result[   N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q3a+innerFT[2,i]*Q3b);
        for i:=0 to N2-1 do result[N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q3b+innerFT[2,i]*Q3a);
      end;
    end else if N1=5 then begin
      if inverse then begin
        commonFactor:=1/5;
        for i:=0 to N2-1 do result[            i]:=(innerFT[0,i]+innerFT[1,i]    +innerFT[2,i]    +innerFT[3,i]    +innerFT[4,i]    )*commonFactor;
        for i:=0 to N2-1 do result[         N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5d+innerFT[2,i]*Q5c+innerFT[3,i]*Q5b+innerFT[4,i]*Q5a)*commonFactor;
        for i:=0 to N2-1 do result[      N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5c+innerFT[2,i]*Q5a+innerFT[3,i]*Q5d+innerFT[4,i]*Q5b)*commonFactor;
        for i:=0 to N2-1 do result[   N2+N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5b+innerFT[2,i]*Q5d+innerFT[3,i]*Q5a+innerFT[4,i]*Q5c)*commonFactor;
        for i:=0 to N2-1 do result[N2+N2+N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5a+innerFT[2,i]*Q5b+innerFT[3,i]*Q5c+innerFT[4,i]*Q5d)*commonFactor;
      end else begin
        for i:=0 to N2-1 do result[            i]:=(innerFT[0,i]+innerFT[1,i]    +innerFT[2,i]    +innerFT[3,i]    +innerFT[4,i]    );
        for i:=0 to N2-1 do result[         N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5a+innerFT[2,i]*Q5b+innerFT[3,i]*Q5c+innerFT[4,i]*Q5d);
        for i:=0 to N2-1 do result[      N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5b+innerFT[2,i]*Q5d+innerFT[3,i]*Q5a+innerFT[4,i]*Q5c);
        for i:=0 to N2-1 do result[   N2+N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5c+innerFT[2,i]*Q5a+innerFT[3,i]*Q5d+innerFT[4,i]*Q5b);
        for i:=0 to N2-1 do result[N2+N2+N2+N2+i]:=(innerFT[0,i]+innerFT[1,i]*Q5d+innerFT[2,i]*Q5c+innerFT[3,i]*Q5b+innerFT[4,i]*Q5a);
      end;
    end else begin
      setLength(innerX,N2);
      //Map    0,0 0,1 0,2 ...    0,N2-1     (N1 arrays of length N2 each)
      //       1,0 1,1 1,2 ...    1,N2-1
      //       ...         ...
      //    N1-1,0         ... N1-1,N2-1
      // to  0,0    1,0 2,0 ... N1-1,0       (N2 array of length N1 each)
      //     0,1    1,1 2,1 ... N1-1,1
      //     ...            ...
      //     0,N2-1         ... N1-1,N2-1
      for i:=0 to N2-1 do setLength(innerX[i],N1);
      for i:=0 to length(X)-1 do innerX[i div N1,i mod N1]:=innerFT[i mod N1,i div N1];
      //Note: N1 is prime by construction, so...
      setLength(innerFT,N2);
      for i:=0 to N2-1 do innerFT[i]:=DiscreteFourierTransform(innerX[i],inverse);
      for i:=0 to length(X)-1 do result[i]:=innerFT[i mod N2,i div N2];
    end;
  end;

INITIALIZATION
  randomize;

end.
