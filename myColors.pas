UNIT myColors;
INTERFACE
USES math,myGenerics;
TYPE
  T_colorChannel   =(cc_red, cc_green, cc_blue, cc_alpha);
  RGB_CHANNELS     =cc_red..cc_blue;
  T_rgbColor       =array[RGB_CHANNELS  ] of byte;
  T_rgbaColor      =array[T_colorChannel] of byte;
  T_rgbFloatColor  =array[RGB_CHANNELS  ] of single;
  T_rgbaFloatColor =array[T_colorChannel] of single;
  T_hsvChannel     =(hc_hue,hc_saturation,hc_value,hc_alpha);
  HSV_CHANNELS     =hc_hue..hc_value;
  T_hsvColor       =array[HSV_CHANNELS] of single;
  T_hsvaColor      =array[T_hsvChannel] of single;
CONST

  SUBJECTIVE_GREY_RED_WEIGHT  =0.2126;
  SUBJECTIVE_GREY_GREEN_WEIGHT=0.7152;
  SUBJECTIVE_GREY_BLUE_WEIGHT =0.0722;

  NO_COLOR:T_rgbaFloatColor=(0,0,0,0);

  RED    :T_rgbFloatColor=(1,0,0);
  GREEN  :T_rgbFloatColor=(0,1,0);
  BLUE   :T_rgbFloatColor=(0,0,1);
  CYAN   :T_rgbFloatColor=(0,1,1);
  YELLOW :T_rgbFloatColor=(1,1,0);
  MAGENTA:T_rgbFloatColor=(1,0,1);
  WHITE  :T_rgbFloatColor=(1,1,1);
  BLACK  :T_rgbFloatColor=(0,0,0);
  GREY   :T_rgbFloatColor=(0.5,0.5,0.5);

FUNCTION rgbColor (CONST r,g,b  :single):T_rgbFloatColor;
FUNCTION rgbaColor(CONST r,g,b,a:single):T_rgbaFloatColor;
FUNCTION hsvColor (CONST h,s,v  :single):T_hsvColor;
FUNCTION hsvaColor(CONST h,s,v,a:single):T_hsvaColor;
OPERATOR :=(CONST x:T_rgbColor      ):T_rgbaColor;
OPERATOR :=(CONST x:T_rgbFloatColor ):T_rgbaFloatColor;
OPERATOR :=(CONST x:T_rgbColor      ):T_rgbFloatColor;
OPERATOR :=(CONST x:T_rgbaColor     ):T_rgbaFloatColor;
FUNCTION projectedColor(CONST x:T_rgbFloatColor):T_rgbFloatColor;
OPERATOR :=(      x:T_rgbFloatColor ):T_rgbColor;
OPERATOR :=(CONST x:T_rgbaFloatColor):T_rgbaColor;
OPERATOR :=(CONST x:T_hsvColor      ):T_hsvaColor;
OPERATOR :=(CONST x:T_rgbFloatColor ):T_hsvColor;
OPERATOR :=(CONST x:T_rgbaFloatColor):T_hsvaColor;
OPERATOR :=(      x:T_hsvColor      ):T_rgbFloatColor;
OPERATOR :=(CONST x:T_hsvaColor     ):T_rgbaFloatColor;
OPERATOR =(CONST x,y:T_rgbFloatColor ):boolean;
OPERATOR =(CONST x,y:T_rgbaFloatColor):boolean;
OPERATOR =(CONST x,y:T_hsvColor      ):boolean;
OPERATOR =(CONST x,y:T_hsvaColor     ):boolean;

OPERATOR +(CONST x,y:T_rgbFloatColor ):T_rgbFloatColor; inline;
OPERATOR +(CONST x,y:T_rgbaFloatColor):T_rgbaFloatColor;
OPERATOR -(CONST x,y:T_rgbFloatColor ):T_rgbFloatColor;
OPERATOR -(CONST x,y:T_rgbaFloatColor):T_rgbaFloatColor;
OPERATOR *(CONST x:T_rgbFloatColor ; CONST y:double):T_rgbFloatColor; inline;
OPERATOR *(CONST x:T_rgbaFloatColor; CONST y:double):T_rgbaFloatColor;
OPERATOR *(CONST x,y:T_rgbFloatColor):T_rgbFloatColor;
FUNCTION blend(CONST below:T_rgbFloatColor; CONST atop:T_rgbaFloatColor):T_rgbFloatColor;
FUNCTION blend(CONST below,atop:T_rgbaFloatColor):T_rgbaFloatColor;

FUNCTION getOverbright(VAR x:T_rgbFloatColor):T_rgbFloatColor;
FUNCTION tint         (CONST c:T_hsvColor; CONST h:single):T_hsvColor; inline;
FUNCTION subjectiveGrey(CONST c:T_rgbFloatColor):T_rgbFloatColor;
FUNCTION greyLevel     (CONST c:T_rgbFloatColor):single; inline;
FUNCTION sepia         (CONST c:T_rgbFloatColor):T_rgbFloatColor; inline;
FUNCTION gamma         (CONST c:T_rgbFloatColor; CONST gR,gG,gB:single):T_rgbFloatColor;
FUNCTION gammaHSV      (CONST c:T_hsvColor;      CONST gH,gS,gV:single):T_hsvColor;
FUNCTION invert        (CONST c:T_rgbFloatColor):T_rgbFloatColor;
FUNCTION absCol        (CONST c:T_rgbFloatColor):T_rgbFloatColor;
FUNCTION calcErr       (CONST c00,c01,c02,c10,c11,c12,c20,c21,c22:T_rgbFloatColor):double; inline;
FUNCTION colDiff       (CONST x,y:T_rgbFloatColor):double;
FUNCTION subjectiveColDiff(CONST x,y:T_rgbFloatColor):double; inline;
FUNCTION innerProduct  (CONST x,y:T_rgbFloatColor):double;

FUNCTION rgbMax   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline;
FUNCTION rgbMin   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline;
FUNCTION rgbDiv   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline;
FUNCTION rgbScreen(CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline;
FUNCTION hasNanOrInfiniteComponent(CONST c:T_rgbFloatColor):boolean;

FUNCTION simpleIlluminatedColor(CONST baseColor:T_rgbFloatColor; CONST nx,ny,nz:double):T_rgbFloatColor;
PROCEDURE averageIllumination(CONST borderAccrossFraction,borderUpFraction:double; OUT baseFraction,whiteFraction:double);

CONST HISTOGRAM_ADDITIONAL_SPREAD=128;
TYPE
  T_histogram=object
    private
      isIncremental:boolean;
      globalMin,globalMax:single;
      bins:array [-HISTOGRAM_ADDITIONAL_SPREAD..255+HISTOGRAM_ADDITIONAL_SPREAD] of single;
      PROCEDURE switch;
      PROCEDURE incBin(CONST index:longint; CONST increment:single);
    public
      CONSTRUCTOR create;
      CONSTRUCTOR createSmoothingKernel(CONST sigma:single);
      DESTRUCTOR destroy;
      PROCEDURE clear;
      PROCEDURE putSample(CONST value:single; CONST weight:single=1);
      PROCEDURE putSampleSmooth(CONST value:single; CONST weight:single=1);
      PROCEDURE smoothen(CONST sigma:single);
      PROCEDURE smoothen(CONST kernel:T_histogram);

      FUNCTION percentile(CONST percent:single):single;
      PROCEDURE getNormalizationParams(OUT offset,stretch:single);
      FUNCTION median:single;
      FUNCTION mightHaveOutOfBoundsValues:boolean;
      FUNCTION mode:single;
      PROCEDURE merge(CONST other:T_histogram; CONST weight:single);
      FUNCTION lookup(CONST value:T_rgbFloatColor):T_rgbFloatColor;
      FUNCTION lookup(CONST value:single):single;
      FUNCTION sampleCount:longint;
  end;

  T_compoundHistogram=object
    R,G,B:T_histogram;

    CONSTRUCTOR create;
    DESTRUCTOR destroy;
    PROCEDURE putSample(CONST value:T_rgbFloatColor; CONST weight:single=1);
    PROCEDURE putSampleSmooth(CONST value:T_rgbFloatColor; CONST weight:single=1);
    PROCEDURE smoothen(CONST sigma:single);
    PROCEDURE smoothen(CONST kernel:T_histogram);
    FUNCTION subjectiveGreyHistogram:T_histogram;
    FUNCTION sumHistorgram:T_histogram;
    FUNCTION mightHaveOutOfBoundsValues:boolean;
    PROCEDURE clear;
  end;

  T_colorList=array of T_rgbFloatColor;
  T_intMapOfInt=specialize G_longintKeyMap<longint>;
  T_colorTree=object
    private
      hist:T_intMapOfInt;
      table:T_colorList;
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      PROCEDURE addSample(CONST c:T_rgbColor);
      PROCEDURE finishSampling(CONST colors:longint);
      PROPERTY colorTable:T_colorList read table;
      FUNCTION getQuantizedColorIndex(CONST c:T_rgbFloatColor):longint;
      FUNCTION getQuantizedColor(CONST c:T_rgbFloatColor):T_rgbFloatColor;
  end;

IMPLEMENTATION
CONST by255=1/255;

FUNCTION rgbColor(CONST r,g,b:single):T_rgbFloatColor;
  begin
    result[cc_red  ]:=r;
    result[cc_green]:=g;
    result[cc_blue ]:=b;
  end;

FUNCTION rgbaColor(CONST r,g,b,a:single):T_rgbaFloatColor;
  begin
    result[cc_red  ]:=r;
    result[cc_green]:=g;
    result[cc_blue ]:=b;
    result[cc_alpha]:=a;
  end;

FUNCTION hsvColor (CONST h,s,v  :single):T_hsvColor;
  begin
    result[hc_hue       ]:=h;
    result[hc_saturation]:=s;
    result[hc_value     ]:=v;
  end;

FUNCTION hsvaColor(CONST h,s,v,a:single):T_hsvaColor;
  begin
    result[hc_hue       ]:=h;
    result[hc_saturation]:=s;
    result[hc_value     ]:=v;
    result[hc_alpha     ]:=a;
  end;

OPERATOR:=(CONST x: T_rgbColor     ): T_rgbaColor;      VAR c:T_colorChannel; begin initialize(result); for c in RGB_CHANNELS do result[c]:=x[c]; result[cc_alpha]:=255; end;
OPERATOR:=(CONST x: T_rgbFloatColor): T_rgbaFloatColor; VAR c:T_colorChannel; begin initialize(result); for c in RGB_CHANNELS do result[c]:=x[c]; result[cc_alpha]:=1;   end;
OPERATOR:=(CONST x: T_rgbColor     ): T_rgbFloatColor;  VAR c:T_colorChannel; begin initialize(result); for c in RGB_CHANNELS   do result[c]:=x[c]*by255; end;
OPERATOR:=(CONST x: T_rgbaColor    ): T_rgbaFloatColor; VAR c:T_colorChannel; begin initialize(result); for c in T_colorChannel do result[c]:=x[c]*by255; end;

FUNCTION projectedColor(CONST x:T_rgbFloatColor):T_rgbFloatColor;
  VAR k1,k2,k3,j:T_colorChannel;
      aid:single;
  begin
    result:=x;
    for j in RGB_CHANNELS do if isNan(result[j]) or isInfinite(result[j]) then result[j]:=random;
    if (result[cc_red  ]<0) or (result[cc_red  ]>1) or
       (result[cc_green]<0) or (result[cc_green]>1) or
       (result[cc_blue ]<0) or (result[cc_blue ]>1) then begin
      k1:=cc_red; k2:=cc_green; k3:=cc_blue;
      if result[k2]<result[k1] then begin j:=k2; k2:=k1; k1:=j; end;
      if result[k3]<result[k1] then begin j:=k3; k3:=k1; k1:=j; end;
      if result[k3]<result[k2] then begin j:=k3; k3:=k2; k2:=j; end;
      //now we have result[k1]<=result[k2]<=result[k3]
      if result[k1]<0 then begin //if darkest channel is underbright...
        //distribute brightness:----//
        aid:=0.5*(result[k1]);      //
        result[k1]:=0;              //
        result[k2]:=result[k2]+aid; //
        result[k3]:=result[k3]+aid; //
        //------:distribute brightness
        if result[k2]<0 then begin //if originally second darkest channel is underbright...
          result[k3]:=max(0,result[k3]+result[k2]);
          result[k2]:=0;
        end;
      end; //if brightest channel is overbright...
      if result[k3]>1 then begin //if brightest channel is overbright...
        //distribute brightness:----//
        aid:=0.5*(result[k3]-1);    //
        result[k3]:=1;              //
        result[k2]:=result[k2]+aid; //
        result[k1]:=result[k1]+aid; //
        //------:distribute brightness
        if result[k2]>1 then begin //if originally second brightest channel is overbright...
          result[k1]:=min(1,result[k1]+result[k2]-1);
          result[k2]:=1;
        end;
      end; //if brightest channel is overbright...
      //now we have 0<=result[i]<=1 for all channels i
      for j in RGB_CHANNELS do if result[j]<0 then result[j]:=0;
    end;
  end;

OPERATOR:=(x: T_rgbFloatColor): T_rgbColor;
  VAR c:T_colorChannel;
  begin
    initialize(result);
    x:=projectedColor(x);
    for c in RGB_CHANNELS do result[c]:=round(255*x[c]);
  end;

OPERATOR:=(CONST x: T_rgbaFloatColor): T_rgbaColor;
  VAR c:T_colorChannel;
  begin
    initialize(result);
    for c in T_colorChannel do
    if isNan(x[c]) or (x[c]<0) then result[c]:=0
    else           if  x[c]>1  then result[c]:=255
    else                            result[c]:=round(x[c]*255);
  end;

OPERATOR :=(CONST x:T_hsvColor      ):T_hsvaColor;
  VAR c:T_hsvChannel;
  begin
    initialize(result);
    for c in HSV_CHANNELS do result[c]:=x[c]; result[hc_alpha]:=1;
  end;

OPERATOR :=(CONST x:T_rgbFloatColor ):T_hsvColor;
  VAR brightChannel:T_colorChannel;
  begin
    initialize(result);
    if x[cc_red]>x[cc_green]       then begin result[hc_value]:=x[cc_red];   brightChannel:=cc_red  ; end
                                   else begin result[hc_value]:=x[cc_green]; brightChannel:=cc_green; end;
    if x[cc_blue]>result[hc_value] then begin result[hc_value]:=x[cc_blue];  brightChannel:=cc_blue ; end;
    //result[hc_value] now holds the brightest component of x
    if x[cc_red]<x[cc_green]            then result[hc_saturation]:=x[cc_red]
                                        else result[hc_saturation]:=x[cc_green];
    if x[cc_blue]<result[hc_saturation] then result[hc_saturation]:=x[cc_blue];
    if result[hc_saturation]=result[hc_value] then brightChannel:=cc_alpha;
    //result[hc_saturation] now holds the darkest component of x
    case brightChannel of
      cc_red  : result[hc_hue]:=(  (x[cc_green]-x[cc_blue ])/(result[hc_value]-result[hc_saturation]))/6;
      cc_green: result[hc_hue]:=(2+(x[cc_blue ]-x[cc_red  ])/(result[hc_value]-result[hc_saturation]))/6;
      cc_blue : result[hc_hue]:=(4+(x[cc_red  ]-x[cc_green])/(result[hc_value]-result[hc_saturation]))/6;
      cc_alpha: result[hc_hue]:=0;
    end;
    if brightChannel=cc_alpha then result[hc_saturation]:=0
                              else result[hc_saturation]:=(result[hc_value]-result[hc_saturation])/result[hc_value];
    while result[hc_hue]<0 do result[hc_hue]:=result[hc_hue]+1;
    while result[hc_hue]>1 do result[hc_hue]:=result[hc_hue]-1;
  end;

OPERATOR :=(CONST x:T_rgbaFloatColor):T_hsvaColor;
  VAR tmp:T_rgbFloatColor;
      c:T_colorChannel;
  begin
    initialize(tmp);
    for c in RGB_CHANNELS do tmp[c]:=x[c];
    result:=T_hsvColor(tmp);
    result[hc_alpha]:=x[cc_alpha];
  end;

OPERATOR :=(      x:T_hsvColor      ):T_rgbFloatColor;
  VAR hi:byte;
      p,q,t:single;
  begin
    initialize(result);
    if isInfinite(x[hc_hue]) or isNan(x[hc_hue]) then exit(rgbColor(random,random,random));
    if x[hc_hue]>1 then x[hc_hue]:=frac(x[hc_hue])
    else if x[hc_hue]<0 then x[hc_hue]:=1+frac(x[hc_hue]);

    while x[hc_hue]<0 do x[hc_hue]:=x[hc_hue]+1;
    while x[hc_hue]>1 do x[hc_hue]:=x[hc_hue]-1;

    hi:=trunc(x[hc_hue]*6); x[hc_hue]:=x[hc_hue]*6-hi;
    p:=x[hc_value]*(1-x[hc_saturation]         );
    q:=x[hc_value]*(1-x[hc_saturation]*   x[hc_hue] );
    t:=x[hc_value]*(1-x[hc_saturation]*(1-x[hc_hue]));
    case hi of
      1  : result:=rgbColor(q,x[hc_value],p);
      2  : result:=rgbColor(p,x[hc_value],t);
      3  : result:=rgbColor(p,q,x[hc_value]);
      4  : result:=rgbColor(t,p,x[hc_value]);
      5  : result:=rgbColor(x[hc_value],p,q);
      else result:=rgbColor(x[hc_value],t,p);
    end;
  end;

OPERATOR :=(CONST x:T_hsvaColor     ):T_rgbaFloatColor;
  VAR tmp:T_hsvColor;
      c:T_hsvChannel;
  begin
    initialize(tmp);
    for c in HSV_CHANNELS do tmp[c]:=x[c];
    result:=T_rgbFloatColor(tmp);
    result[cc_alpha]:=x[hc_alpha];
  end;

OPERATOR =(CONST x,y:T_rgbFloatColor ):boolean; VAR c:T_colorChannel; begin for c in RGB_CHANNELS   do if x[c]<>y[c] then exit(false); result:=true; end;
OPERATOR =(CONST x,y:T_rgbaFloatColor):boolean; VAR c:T_colorChannel; begin for c in T_colorChannel do if x[c]<>y[c] then exit(false); result:=true; end;
OPERATOR =(CONST x,y:T_hsvColor      ):boolean; VAR c:T_hsvChannel;   begin for c in HSV_CHANNELS   do if x[c]<>y[c] then exit(false); result:=true; end;
OPERATOR =(CONST x,y:T_hsvaColor     ):boolean; VAR c:T_hsvChannel;   begin for c in T_hsvChannel   do if x[c]<>y[c] then exit(false); result:=true; end;

OPERATOR+(CONST x, y: T_rgbFloatColor ): T_rgbFloatColor;
  begin
    result[cc_red  ]:=x[cc_red  ]+y[cc_red  ];
    result[cc_green]:=x[cc_green]+y[cc_green];
    result[cc_blue ]:=x[cc_blue ]+y[cc_blue ];
  end;
OPERATOR+(CONST x, y: T_rgbaFloatColor): T_rgbaFloatColor; VAR c:T_colorChannel; begin initialize(result); for c in T_colorChannel do result[c]:=x[c]+y[c]; end;
OPERATOR-(CONST x, y: T_rgbFloatColor ): T_rgbFloatColor;  VAR c:T_colorChannel; begin initialize(result); for c in RGB_CHANNELS   do result[c]:=x[c]-y[c]; end;
OPERATOR-(CONST x, y: T_rgbaFloatColor): T_rgbaFloatColor; VAR c:T_colorChannel; begin initialize(result); for c in T_colorChannel do result[c]:=x[c]-y[c]; end;

OPERATOR *(CONST x: T_rgbFloatColor;  CONST y: double): T_rgbFloatColor;
  begin
    result[cc_red  ]:=x[cc_red  ]*y;
    result[cc_green]:=x[cc_green]*y;
    result[cc_blue ]:=x[cc_blue ]*y;
  end;
OPERATOR *(CONST x: T_rgbaFloatColor; CONST y: double): T_rgbaFloatColor; VAR c:T_colorChannel; begin initialize(result); for c in T_colorChannel do result[c]:=x[c]*y; end;
OPERATOR *(CONST x,y:T_rgbFloatColor                 ): T_rgbFloatColor;  VAR c:T_colorChannel; begin initialize(result); for c in RGB_CHANNELS do result[c]:=x[c]*y[c]; end;
FUNCTION blend(CONST below: T_rgbFloatColor; CONST atop: T_rgbaFloatColor): T_rgbFloatColor;
  VAR BF:single;
      c:T_colorChannel;
  begin
    initialize(result);
    BF:=1-atop[cc_alpha];
    for c in RGB_CHANNELS do result[c]:=atop[c]*atop[cc_alpha]+below[c]*BF;
  end;

FUNCTION blend(CONST below, atop: T_rgbaFloatColor): T_rgbaFloatColor;
  VAR af,BF:single;
      c:T_colorChannel;
  begin
    initialize(result);
    af:=       atop [cc_alpha];
    BF:=(1-af)*below[cc_alpha];
    result[cc_alpha]:=af+BF;
    af:=af/result[cc_alpha];
    BF:=BF/result[cc_alpha];
    for c in RGB_CHANNELS do result[c]:=atop[c]*af+below[c]*BF;
  end;

FUNCTION getOverbright(VAR x:T_rgbFloatColor):T_rgbFloatColor;
  VAR b:single;
  begin
    initialize(result);
    if x[cc_red]>x[cc_green] then b:=x[cc_red]  //find brightest channel
                             else b:=x[cc_green];
    if x[cc_blue]>b          then b:=x[cc_blue];
    if b<1.002 then result:=BLACK else begin //if brightest channel is darker than 1, there is no overbrightness
      result:=x*(1-1/b);  //else result is
      x     :=x-result;
    end;
    if x[cc_red  ]<0 then x[cc_red  ]:=0;
    if x[cc_green]<0 then x[cc_green]:=0;
    if x[cc_blue ]<0 then x[cc_blue ]:=0;
  end;

FUNCTION tint(CONST c:T_hsvColor; CONST h:single):T_hsvColor;
  begin
    result:=c;
    result[hc_hue]:=h;
  end;

FUNCTION subjectiveGrey(CONST c:T_rgbFloatColor):T_rgbFloatColor; inline;
  begin
    result:=WHITE*greyLevel(c);
  end;

FUNCTION greyLevel(CONST c:T_rgbFloatColor):single;
  begin
    result:=SUBJECTIVE_GREY_RED_WEIGHT  *c[cc_red]+
            SUBJECTIVE_GREY_GREEN_WEIGHT*c[cc_green]+
            SUBJECTIVE_GREY_BLUE_WEIGHT *c[cc_blue];
  end;

{local} FUNCTION safeGamma(CONST x,gamma:single):single; inline;
  begin
    if      x> 1E-4 then result:= exp(ln( x)*gamma)
    else if x<-1E-4 then result:=-exp(ln(-x)*gamma)
    else 		 result:=x;
  end;

FUNCTION sepia(CONST c:T_rgbFloatColor):T_rgbFloatColor; inline;
  begin
    result[cc_red  ]:=safeGamma(c[cc_red],0.5);
    result[cc_green]:=c[cc_green];
    result[cc_blue ]:=sqr(c[cc_blue]);
  end;

FUNCTION gamma(CONST c:T_rgbFloatColor; CONST gR,gG,gB:single):T_rgbFloatColor; inline;
  begin
    result[cc_red  ]:=safeGamma(c[cc_red  ],gR);
    result[cc_green]:=safeGamma(c[cc_green],gG);
    result[cc_blue ]:=safeGamma(c[cc_blue ],gB);
  end;

FUNCTION gammaHSV(CONST c:T_hsvColor; CONST gH,gS,gV:single):T_hsvColor; inline;
  begin
    result[hc_hue       ]:=safeGamma(c[hc_hue       ],gH);
    result[hc_saturation]:=safeGamma(c[hc_saturation],gS);
    result[hc_value     ]:=safeGamma(c[hc_value     ],gV);
  end;

FUNCTION invert(CONST c:T_rgbFloatColor):T_rgbFloatColor;
  begin
    result:=WHITE-c;
  end;

FUNCTION absCol(CONST c:T_rgbFloatColor):T_rgbFloatColor;
  VAR i:T_colorChannel;
  begin
    initialize(result);
    for i in RGB_CHANNELS do if c[i]<0 then result[i]:=-c[i] else result[i]:=c[i];
  end;

FUNCTION calcErr(CONST c00,c01,c02,c10,c11,c12,c20,c21,c22:T_rgbFloatColor):double; inline;
  VAR a0,a1,b0,b1:T_rgbFloatColor;
  begin
    a0:=c11-(c01+c21)*0.5;
    a1:=c11-(c10+c12)*0.5;
    b0:=c11-(c00+c22)*0.5;
    b1:=c11-(c20+c02)*0.5;
    result:=(a0[cc_red]*a0[cc_red]+a0[cc_green]*a0[cc_green]+a0[cc_blue]*a0[cc_blue]+
             a1[cc_red]*a1[cc_red]+a1[cc_green]*a1[cc_green]+a1[cc_blue]*a1[cc_blue])*3+
            (b0[cc_red]*b0[cc_red]+b0[cc_green]*b0[cc_green]+b0[cc_blue]*b0[cc_blue]+
             b1[cc_red]*b1[cc_red]+b1[cc_green]*b1[cc_green]+b1[cc_blue]*b1[cc_blue])*1.5;
  end;

FUNCTION colDiff(CONST x,y:T_rgbFloatColor):double;
  begin
    result:=(sqr(x[cc_red  ]-y[cc_red  ])+
             sqr(x[cc_green]-y[cc_green])+
             sqr(x[cc_blue ]-y[cc_blue ]));
  end;

FUNCTION subjectiveColDiff(CONST x,y:T_rgbFloatColor):double; inline;
  VAR dr,dg,db:double;
  begin
    dr:=x[cc_red]  -y[cc_red];
    dg:=x[cc_green]-y[cc_green];
    db:=x[cc_blue] -y[cc_blue];
    result:=sqr(dr*0.49   +dg*0.31  +db*0.2    )+
            sqr(dr*0.17697+dg*0.8124+db*0.01063)+
            sqr(           dg*0.01  +db*0.99   );
  end;

FUNCTION innerProduct  (CONST x,y:T_rgbFloatColor):double;
  VAR i:T_colorChannel;
  begin
    result:=0;
    for i in RGB_CHANNELS do result+=x[i]*y[i];
  end;

FUNCTION rgbMax   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline; VAR i:T_colorChannel; begin initialize(result);  for i in RGB_CHANNELS do if a[i]>b[i] then result[i]:=a[i] else result[i]:=b[i]; end;
FUNCTION rgbMin   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline; VAR i:T_colorChannel; begin initialize(result);  for i in RGB_CHANNELS do if a[i]<b[i] then result[i]:=a[i] else result[i]:=b[i]; end;
FUNCTION rgbDiv   (CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline; VAR i:T_colorChannel; begin initialize(result); for i in RGB_CHANNELS do result[i]:=a[i]/b[i]; end;
FUNCTION rgbScreen(CONST a,b:T_rgbFloatColor):T_rgbFloatColor; inline; VAR i:T_colorChannel; begin initialize(result); for i in RGB_CHANNELS do result[i]:=1-(1-a[i])*(1-b[i]); end;

FUNCTION hasNanOrInfiniteComponent(CONST c:T_rgbFloatColor):boolean;
  VAR i:T_colorChannel;
  begin
    for i in RGB_CHANNELS do if isNan(c[i]) or isInfinite(c[i]) then exit(true);
    result:=false;
  end;

FUNCTION simpleIlluminatedColor(CONST baseColor:T_rgbFloatColor; CONST nx,ny,nz:double):T_rgbFloatColor;
  CONST lx=-1/4;
        ly=-1/2;
        lz= 1;
        whiteFactor=6.866060555964674;
  VAR illumination:double;
  begin
    illumination:=nx*lx+ny*ly+nz*lz;
    if      illumination<0                then result:=BLACK
    else if illumination<1                then result:=baseColor*illumination
    else if illumination<1.14564392373896 then begin
      illumination:=whiteFactor*(illumination-1);
      result:=baseColor*(1-illumination)+WHITE*illumination;
    end else result:=BLACK;
  end;

PROCEDURE averageIllumination(CONST borderAccrossFraction,borderUpFraction:double; OUT baseFraction,whiteFraction:double);
  CONST lx=-1/4;
        ly=-1/2;
        lz= 1;
        whiteFactor=6.866060555964674;
  VAR illumination:double;
      alpha:double;
      k:longint;
  begin
    baseFraction:=0;
    whiteFraction:=0;
    for k:=0 to 999 do begin
      alpha:=k*2*pi/1000;
      illumination:=borderAccrossFraction*(cos(alpha)*lx+sin(alpha)*ly)+borderUpFraction*lz;
      if      illumination<0                then begin end
      else if illumination<1                then baseFraction+=illumination*1E-3
      else if illumination<1.14564392373896 then begin
        illumination:=whiteFactor*(illumination-1);
        baseFraction+=(1-illumination)*1E-3;
        whiteFraction+=illumination   *1E-3;
      end;
    end;
  end;

PROCEDURE T_histogram.switch;
  VAR i:longint;
  begin
    if isIncremental then begin
      for i:=high(bins) downto low(bins)+1 do bins[i]:=bins[i]-bins[i-1];
    end else begin
      for i:=low(bins)+1 to high(bins) do bins[i]:=bins[i]+bins[i-1];
    end;
    isIncremental:=not(isIncremental);
  end;

CONSTRUCTOR T_histogram.create;
  begin
    clear;
  end;

CONSTRUCTOR T_histogram.createSmoothingKernel(CONST sigma: single);
  VAR i:longint;
      s:double;
  begin
    clear;
    if sigma<1E-3 then s:=1E3 else s:=1/sigma;
    for i:=-HISTOGRAM_ADDITIONAL_SPREAD to HISTOGRAM_ADDITIONAL_SPREAD do bins[i]:=exp(-sqr(i*s));
  end;

DESTRUCTOR T_histogram.destroy;
  begin end;//Pro forma destructor

PROCEDURE T_histogram.clear;
  VAR i:longint;
  begin
    isIncremental:=false;
    globalMax:=-infinity;
    globalMin:= infinity;
    for i:=low(bins) to high(bins) do bins[i]:=0;
  end;

PROCEDURE T_histogram.incBin(CONST index: longint; CONST increment: single);
  VAR i:longint;
  begin
    if      index<low (bins) then i:=low(bins)
    else if index>high(bins) then i:=high(bins)
    else i:=index;
    bins[i]:=bins[i]+increment;
  end;

PROCEDURE T_histogram.putSample(CONST value: single; CONST weight: single);
  begin
    if isIncremental then switch;
    if isNan(value) or isInfinite(value) then exit;
    globalMax:=max(globalMax,value);
    globalMin:=min(globalMin,value);
    incBin(round(max(min(value,8E6),-8E6)*255),weight);
  end;

PROCEDURE T_histogram.putSampleSmooth(CONST value: single; CONST weight: single);
  VAR i:longint;
  begin
    if isIncremental then switch;
    if isNan(value) or isInfinite(value) then exit;
    if      value<-1 then i:=-255
    else if value> 2 then i:=510
    else                  i:=round(value*255);
    incBin(i-1,weight*0.25);
    incBin(i  ,weight*0.5 );
    incBin(i+1,weight*0.25);
  end;

PROCEDURE T_histogram.smoothen(CONST sigma: single);
  VAR kernel:T_histogram;
  begin
    if isIncremental then switch;
    kernel.createSmoothingKernel(sigma);
    smoothen(kernel);
    kernel.destroy;
  end;

PROCEDURE T_histogram.smoothen(CONST kernel: T_histogram);
  VAR temp:T_histogram;
      i,j:longint;
      sum1,sum2:double;
  begin
    if isIncremental then switch;
    temp.create;
    for i:=low(bins) to high(bins)-1 do begin
      sum1:=0;
      sum2:=0;
      for j:=-HISTOGRAM_ADDITIONAL_SPREAD to HISTOGRAM_ADDITIONAL_SPREAD do if (i+j>=low(bins)) and (i+j<high(bins)) then begin
        sum1:=sum1+kernel.bins[abs(j)]*bins[i+j];
        sum2:=sum2+kernel.bins[abs(j)];
      end;
      temp.bins[i]:=sum1/sum2;
    end;
    for i:=low(bins) to high(bins)-1 do bins[i]:=temp.bins[i];
    temp.destroy;
  end;

FUNCTION T_histogram.percentile(CONST percent: single): single;
  VAR absVal:single;
      i:longint;
  begin
    if not(isIncremental) then switch;
    absVal:=percent/100*bins[high(bins)];
    if bins[low(bins)]>absVal then exit(low(bins)/255);
    for i:=low(bins)+1 to high(bins) do if (bins[i-1]<=absVal) and (bins[i]>absVal) then exit((i+(absVal-bins[i-1])/(bins[i]-bins[i-1]))/255);
    result:=high(bins)/255;
  end;

PROCEDURE T_histogram.getNormalizationParams(OUT offset, stretch: single);
  VAR absVal0,absVal1:single;
      bin0:longint=low(bins);
      bin1:longint=low(bins);
      i:longint;
  begin
    if not(isIncremental) then switch;
    absVal0:=0.001*bins[high(bins)];
    absVal1:=0.999*bins[high(bins)];

    for i:=low(bins)+1 to high(bins) do begin
      if (bins[i-1]<=absVal0) and (bins[i]>absVal0) then bin0:=i;
      if (bins[i-1]<=absVal1) and (bins[i]>absVal1) then bin1:=i;
    end;
    if      bin0<=low (bins) then offset :=globalMin
    else if bin0>=high(bins) then offset :=globalMax
                             else offset :=(bin0+(absVal0-bins[bin0-1])/(bins[bin0]-bins[bin0-1]))/255;
    if      bin1<=low (bins) then stretch:=globalMin
    else if bin1>=high(bins) then stretch:=globalMax
                             else stretch:=(bin1+(absVal1-bins[bin1-1])/(bins[bin1]-bins[bin1-1]))/255;
    if (stretch-offset)>1E-20
    then stretch:=1/(stretch-offset)
    else stretch:=1;
  end;

FUNCTION T_histogram.median: single;
  begin
    result:=percentile(50);
  end;

FUNCTION T_histogram.mightHaveOutOfBoundsValues: boolean;
  begin
    if (isIncremental) then switch;
    result:=(bins[low(bins)]>0) or (bins[high(bins)]>0);
  end;

FUNCTION T_histogram.mode: single;
  VAR i:longint;
      ir:longint=low(bins);
  begin
    if isIncremental then switch;
    for i:=low(bins)+1 to high(bins) do if bins[i]>bins[ir] then ir:=i;
    result:=ir/255;
  end;

PROCEDURE T_histogram.merge(CONST other: T_histogram; CONST weight: single);
  VAR i:longint;
  begin
    if isIncremental then switch;
    if other.isIncremental then switch;
    for i:=low(bins) to high(bins) do bins[i]:=bins[i]+other.bins[i]*weight;
  end;

FUNCTION T_histogram.lookup(CONST value: T_rgbFloatColor): T_rgbFloatColor;
  VAR i:longint;
      c:T_colorChannel;
  begin
    initialize(result);
    if not(isIncremental) then switch;
    for c in RGB_CHANNELS do begin
      i:=round(255*value[c]);
      if i<low(bins) then i:=low(bins) else if i>high(bins) then i:=high(bins);
      result[c]:=bins[i];
    end;
    result:=result*(1/bins[high(bins)]);
  end;

FUNCTION T_histogram.lookup(CONST value: single): single;
  VAR i:longint;
  begin
    if not(isIncremental) then switch;
    i:=round(255*value);
    if i<low(bins) then i:=low(bins) else if i>high(bins) then i:=high(bins);
    result:=bins[i]*(1/bins[high(bins)]);
  end;

FUNCTION T_histogram.sampleCount: longint;
  begin
    if not(isIncremental) then switch;
    result:=round(bins[high(bins)]);
  end;

CONSTRUCTOR T_compoundHistogram.create;
  begin
    r.create;
    g.create;
    b.create;
  end;

DESTRUCTOR T_compoundHistogram.destroy;
  begin
    r.destroy;
    g.destroy;
    b.destroy;
  end;

PROCEDURE T_compoundHistogram.putSample(CONST value: T_rgbFloatColor;
  CONST weight: single);
  begin
    r.putSample(value[cc_red],weight);
    g.putSample(value[cc_green],weight);
    b.putSample(value[cc_blue],weight);
  end;

PROCEDURE T_compoundHistogram.putSampleSmooth(CONST value: T_rgbFloatColor;
  CONST weight: single);
  begin
    r.putSampleSmooth(value[cc_red],weight);
    g.putSampleSmooth(value[cc_green],weight);
    b.putSampleSmooth(value[cc_blue],weight);
  end;

PROCEDURE T_compoundHistogram.smoothen(CONST sigma: single);
  VAR kernel:T_histogram;
  begin
    kernel.createSmoothingKernel(sigma);
    smoothen(kernel);
    kernel.destroy;
  end;

PROCEDURE T_compoundHistogram.smoothen(CONST kernel: T_histogram);
  begin
    r.smoothen(kernel);
    g.smoothen(kernel);
    b.smoothen(kernel);
  end;

FUNCTION T_compoundHistogram.subjectiveGreyHistogram: T_histogram;
  begin
    result.create;
    result.merge(r,SUBJECTIVE_GREY_RED_WEIGHT);
    result.merge(g,SUBJECTIVE_GREY_GREEN_WEIGHT);
    result.merge(b,SUBJECTIVE_GREY_BLUE_WEIGHT);
  end;

FUNCTION T_compoundHistogram.sumHistorgram: T_histogram;
  begin
    result.create;
    result.merge(r,1/3);
    result.merge(g,1/3);
    result.merge(b,1/3);
  end;

FUNCTION T_compoundHistogram.mightHaveOutOfBoundsValues: boolean;
  begin
    result:=r.mightHaveOutOfBoundsValues or
            g.mightHaveOutOfBoundsValues or
            b.mightHaveOutOfBoundsValues;
  end;

PROCEDURE T_compoundHistogram.clear;
  begin
    r.clear;
    g.clear;
    b.clear;
  end;

CONSTRUCTOR T_colorTree.create;
  begin
    hist.create;
  end;

DESTRUCTOR T_colorTree.destroy;
  begin
    hist.destroy;
    setLength(table,0);
  end;

PROCEDURE T_colorTree.addSample(CONST c: T_rgbColor);
  VAR key:longint=0;
      count:longint;
  begin
    move(c,key,3);
    if hist.containsKey(key,count)
    then inc(count)
    else count:=1;
    hist.put(key,count+1);
  end;

PROCEDURE T_colorTree.finishSampling(CONST colors: longint);
  TYPE T_countedSample=record
         color:T_rgbFloatColor;
         count:longint;
       end;

  FUNCTION colorFromIndex(CONST index:longint):T_rgbFloatColor;
    VAR c24:T_rgbColor;
    begin
      initialize(c24);
      move(index,c24,3);
      result:=c24;
    end;

  FUNCTION fidelity(CONST entry:T_countedSample):double;
    VAR i:longint;
        dist:double;
    begin
      result:=1E50;
      for i:=0 to length(table)-1 do begin
        dist:=colDiff(entry.color,table[i]);
        if dist<result then result:=dist;
      end;
      result:=result*entry.count;
    end;

  VAR i,k:longint;

      digest:array of T_countedSample;
      histEntry:T_intMapOfInt.KEY_VALUE_LIST;
      best,
      next:T_countedSample;
      bestFid,
      nextFid:double;

  begin
    histEntry:=hist.entrySet;
    setLength(digest,0);
    for i:=0 to length(histEntry)-1 do begin
      if histEntry[i].value>=16 then begin
        setLength(digest,length(digest)+1);
        digest[length(digest)-1].color:=colorFromIndex(histEntry[i].key);
        digest[length(digest)-1].count:=histEntry[i].value;
      end;
    end;
    hist.destroy;
    hist.create;
    best:=digest[0];
    for i:=1 to length(digest)-1 do begin
      next:=digest[i];
      if next.count>best.count then best:=next;
    end;

    setLength(table,1);
    table[0]:=best.color;

    for k:=1 to colors-1 do begin
      best:=digest[0];
      bestFid:=fidelity(best);
      for i:=1 to length(digest)-1 do begin
        next:=digest[i];
        nextFid:=fidelity(next);
        if nextFid>bestFid then begin
          best   :=next;
          bestFid:=nextFid;
        end;
      end;
      setLength(table,k+1);
      table[k]:=best.color;
    end;
  end;

FUNCTION T_colorTree.getQuantizedColorIndex(CONST c: T_rgbFloatColor): longint;
  VAR newDist,dist1:double;
      i:longint;
  begin
    dist1:=colDiff(c,table[0]); result:=0;
    for i:=1 to length(table)-1 do begin
      newDist:=colDiff(c,table[i]);
      if newDist<dist1 then begin dist1:=newDist; result:=i;  end;
    end;
  end;

FUNCTION T_colorTree.getQuantizedColor(CONST c: T_rgbFloatColor): T_rgbFloatColor;
  VAR newDist,dist1:double;
      i:longint;
  begin
    dist1:=colDiff(c,table[0]); result:=table[0];
    for i:=1 to length(table)-1 do begin
      newDist:=colDiff(c,table[i]);
      if newDist<dist1 then begin dist1:=newDist; result:=table[i]; end;
    end;
  end;

end.

