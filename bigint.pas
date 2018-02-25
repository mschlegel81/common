UNIT bigint;
INTERFACE
USES sysutils,
     math,
     serializationUtil;
{$define bigDigits}
TYPE
  {$ifdef bigDigits}
  digitType=dword;
  carryType=qword;
  {$else}
  digitType=word;
  carryType=dword;
  {$endif}
  pDigitType=^digitType;
CONST
  {$ifdef bigDigits}
  BITS_PER_DIGIT=32;
  {$else}
  BITS_PER_DIGIT=16;
  {$endif}
  DIGIT_MAX_VALUE=(1 shl BITS_PER_DIGIT)-1;
  UPPER_DIGIT_BIT=1 shl (BITS_PER_DIGIT-1);
  WORD_BIT:array[0..BITS_PER_DIGIT-1] of digitType=
    (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768
    {$ifdef bigDigits},
    65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,67108864,134217728,268435456,536870912,1073741824,2147483648
    {$endif}
    );

TYPE
  T_comparisonResult=(CR_EQUAL,
                      CR_LESSER,
                      CR_GREATER,
                      CR_INVALID_COMPARAND);
  T_roundingMode=(RM_DEFAULT,RM_UP,RM_DOWN);
CONST
   C_FLIPPED:array[T_comparisonResult] of T_comparisonResult=(CR_EQUAL,CR_GREATER,CR_LESSER,CR_INVALID_COMPARAND);
TYPE
  P_bigint=^T_bigint;
  T_bigint=object
    private
      negative:boolean;
      digitCount:longint;
      digits:pDigitType;
      CONSTRUCTOR createFromRawData(CONST negative_:boolean; CONST digitCount_:longint; CONST digits_:pDigitType);
      PROCEDURE shlInc(CONST incFirstBit:boolean);
      FUNCTION relevantBits:longint;
      PROCEDURE setBit(CONST index:longint; CONST value:boolean);
      FUNCTION compareAbsValue(CONST big:T_bigint):T_comparisonResult; inline;
      FUNCTION compareAbsValue(CONST int:int64):T_comparisonResult; inline;
    public
      PROPERTY isNegative:boolean read negative;

      CONSTRUCTOR createZero;
      CONSTRUCTOR create(CONST negativeNumber:boolean; CONST digitCount_:longint);
      CONSTRUCTOR fromInt(CONST i:int64);
      CONSTRUCTOR fromString(CONST s:string);
      CONSTRUCTOR fromFloat(CONST f:extended; CONST rounding:T_roundingMode);
      CONSTRUCTOR create(CONST toClone:T_bigint);
      DESTRUCTOR destroy;

      FUNCTION toInt:int64;
      FUNCTION toFloat:extended;
      {if examineNicheCase is true, the case of -2^63 is considered; otherwise the function is symmetrical}
      FUNCTION canBeRepresentedAsInt64(CONST examineNicheCase: boolean=true): boolean;
      FUNCTION getBit(CONST index:longint):boolean;

      PROCEDURE flipSign;
      FUNCTION negated:T_bigint;
      FUNCTION compare(CONST big:T_bigint):T_comparisonResult; inline;
      FUNCTION compare(CONST int:int64   ):T_comparisonResult; inline;
      FUNCTION compare(CONST f:extended  ):T_comparisonResult; inline;
      FUNCTION plus (CONST big:T_bigint):T_bigint;
      FUNCTION minus(CONST big:T_bigint):T_bigint;
      FUNCTION mult (CONST big:T_bigint):T_bigint;
      FUNCTION pow  (power:dword ):T_bigint;
      FUNCTION bitAnd(CONST big:T_bigint):T_bigint;
      FUNCTION bitOr (CONST big:T_bigint):T_bigint;
      FUNCTION bitXor(CONST big:T_bigint):T_bigint;
      PROCEDURE multWith(CONST l:longint);
      PROCEDURE multWith(CONST b:T_bigint);
      PROCEDURE divBy(CONST divisor:digitType; OUT rest:digitType);
      PROCEDURE incAbsValue(CONST positiveIncrement:dword);
      {returns true on success, false on division by zero}
      FUNCTION divMod(CONST divisor:T_bigint; OUT quotient,rest:T_bigint):boolean;
      FUNCTION divide(CONST divisor:T_bigint):T_bigint;
      FUNCTION modulus(CONST divisor:T_bigint):T_bigint;
      FUNCTION toString:string;
      FUNCTION hash:dword;
      FUNCTION equals(CONST b:T_bigint):boolean;
      FUNCTION isZero:boolean;
      PROCEDURE shiftRightOneBit;

      PROCEDURE writeToStream(CONST stream:P_outputStreamWrapper);
      CONSTRUCTOR readFromStream(CONST stream:P_inputStreamWrapper);
      FUNCTION lowDigit:digitType;
      FUNCTION sign:shortint;
  end;

IMPLEMENTATION
PROCEDURE performSelfTest;
  CONST ix:int64= 1234567;
        iy:int64= 9876543;
        iz:int64=-1929176;
  VAR bx,by,bz:T_bigint;
      r:T_bigint;
      q:T_bigint;
  PROCEDURE assertEqualsAndDispose(CONST comparand:int64);
    VAR valueOfR:int64;
    begin
      valueOfR:=r.toInt;
      r.destroy;
      if valueOfR<>comparand then raise Exception.create('big int self test failed: '+intToStr(valueOfR)+'<>'+intToStr(comparand));
    end;

  begin
    try
      bx.fromInt(ix);
      by.fromInt(iy);
      bz.fromInt(iz);

      writeln(bx.toString,' ',ix,' ',bx.toInt);
      writeln(by.toString,' ',iy,' ',by.toInt);
      writeln(bz.toString,' ',iz,' ',bz.toInt);

      r:=bx.plus (by); assertEqualsAndDispose(ix+iy);
      r:=by.plus (bz); assertEqualsAndDispose(iy+iz);
      r:=bz.plus (bx); assertEqualsAndDispose(iz+ix);

      r:=bx.minus(by); assertEqualsAndDispose(ix-iy);
      r:=by.minus(bz); assertEqualsAndDispose(iy-iz);
      r:=bz.minus(bx); assertEqualsAndDispose(iz-ix);

      r:=bx.mult (by); assertEqualsAndDispose(ix*iy);
      r:=by.mult (bz); assertEqualsAndDispose(iy*iz);
      r:=bz.mult (bx); assertEqualsAndDispose(iz*ix);

      bx.divMod(by,r,q); assertEqualsAndDispose(ix div iy);
      r:=q;              assertEqualsAndDispose(ix mod iy);
      by.divMod(bx,r,q); assertEqualsAndDispose(iy div ix);
      r:=q;              assertEqualsAndDispose(iy mod ix);
      by.divMod(bz,r,q); assertEqualsAndDispose(iy div iz);
      r:=q;              assertEqualsAndDispose(iy mod iz);
      bz.divMod(bx,r,q); assertEqualsAndDispose(iz div ix);
      r:=q;              assertEqualsAndDispose(iz mod ix);

      r.fromString(intToStr(ix)); assertEqualsAndDispose(ix);
      r.fromString(intToStr(iy)); assertEqualsAndDispose(iy);
      r.fromString(intToStr(iz)); assertEqualsAndDispose(iz);
    finally
      bx.destroy;
      by.destroy;
      bz.destroy;
      bx.fromFloat(999999999999999900001.4,RM_DOWN);
      writeln(bx.toString);
      writeln(bx.toFloat=999999999999999900001.0);
      bx.destroy;
    end;
  end;

PROCEDURE rawDataPlus(CONST xDigits:pDigitType; CONST xDigitCount:longint;
                      CONST yDigits:pDigitType; CONST yDigitCount:longint;
                      OUT sumDigits:pDigitType; OUT sumDigitCount:longint); inline;
  VAR carry:carryType=0;
      i    :longint;
  begin
       sumDigitCount:=xDigitCount;
    if sumDigitCount< yDigitCount then
       sumDigitCount:=yDigitCount;
    getMem(sumDigits,sizeOf(digitType)*sumDigitCount);
    for i:=0 to sumDigitCount-1 do begin
      if i<xDigitCount then carry+=xDigits[i];
      if i<yDigitCount then carry+=yDigits[i];
      sumDigits[i]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
    if carry>0 then begin
      inc(sumDigitCount);
      ReAllocMem(sumDigits,sizeOf(digitType)*sumDigitCount);
      sumDigits[sumDigitCount-1]:=carry;
    end;
  end;

{Precondition: x>y}
PROCEDURE rawDataMinus(CONST xDigits:pDigitType; CONST xDigitCount:longint;
                       CONST yDigits:pDigitType; CONST yDigitCount:longint;
                       OUT diffDigits:pDigitType; OUT diffDigitCount:longint); inline;
  VAR carry:carryType=0;
      i    :longint;
  begin
    diffDigitCount:=xDigitCount;
    getMem(diffDigits,sizeOf(digitType)*diffDigitCount);
    for i:=0 to yDigitCount-1 do begin
      carry+=yDigits[i];
      if carry>xDigits[i] then begin
        diffDigits[i]:=((DIGIT_MAX_VALUE+1)-carry+xDigits[i]) and DIGIT_MAX_VALUE;
        carry:=1;
      end else begin
        diffDigits[i]:=xDigits[i]-carry;
        carry:=0;
      end;
    end;
    for i:=yDigitCount to xDigitCount-1 do begin
      if carry>xDigits[i] then begin
        diffDigits[i]:=((DIGIT_MAX_VALUE+1)-carry+xDigits[i]) and DIGIT_MAX_VALUE;
        carry:=1;
      end else begin
        diffDigits[i]:=xDigits[i]-carry;
        carry:=0;
      end;
    end;
    while (diffDigitCount>0) and (diffDigits[diffDigitCount-1]=0) do dec(diffDigitCount);
    if diffDigitCount<>xDigitCount then ReAllocMem(diffDigits,sizeOf(digitType)*diffDigitCount);
  end;

CONSTRUCTOR T_bigint.createFromRawData(CONST negative_: boolean;
  CONST digitCount_: longint; CONST digits_: pDigitType);
  begin
    negative  :=negative_ and (digitCount_>0); //no such thing as a negative zero
    digitCount:=digitCount_;
    digits    :=digits_;
  end;

PROCEDURE T_bigint.shlInc(CONST incFirstBit: boolean);
  VAR k:longint;
      carryBit:boolean;
      nextCarry:boolean;
  begin
    carryBit:=incFirstBit;
    nextCarry:=carryBit;
    for k:=0 to digitCount-1 do begin
      nextCarry:=(digits[k] and UPPER_DIGIT_BIT)<>0;
      {$R-}
      digits[k]:=digits[k] shl 1;
      {$R+}
      if carryBit then inc(digits[k]);
      carryBit:=nextCarry;
    end;
    if nextCarry then begin
      inc(digitCount);
      ReAllocMem(digits,digitCount*sizeOf(digitType));
      digits[digitCount-1]:=1;
    end;
  end;

FUNCTION T_bigint.relevantBits: longint;
  VAR upperDigit:digitType;
      k:longint;
  begin
    if digitCount=0 then exit(0);
    upperDigit:=digits[digitCount-1];
    result:=BITS_PER_DIGIT*digitCount;
    for k:=BITS_PER_DIGIT-1 downto 0 do
      if upperDigit<WORD_BIT[k]
      then dec (result)
      else exit(result);
  end;

FUNCTION T_bigint.getBit(CONST index: longint): boolean;
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    if digitIndex>=digitCount then exit(false);
    bitIndex  :=index mod BITS_PER_DIGIT;
    result:=(digits[digitIndex] and WORD_BIT[bitIndex])<>0;
  end;

PROCEDURE T_bigint.setBit(CONST index: longint; CONST value: boolean);
  VAR digitIndex:longint;
      bitIndex  :longint;
      k:longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    bitIndex:=index and (BITS_PER_DIGIT-1);
    if value then begin
      //setting a true bit means, we might have to increase the number of digits
      if (digitIndex>=digitCount) and value then begin
        ReAllocMem(digits,(digitIndex+1)*sizeOf(digitType));
        for k:=digitIndex downto digitCount do digits[k]:=0;
        digitCount:=digitIndex+1;
      end;
      digits[digitIndex]:=digits[digitIndex] or WORD_BIT[bitIndex];
    end else begin
      //setting a false bit means, we might have to decrease the number of digits
      if digitIndex>=digitCount then exit;
      digits[digitIndex]:=digits[digitIndex] and not(WORD_BIT[bitIndex]);
      k:=digitCount;
      while (digitCount>0) and (digits[digitCount-1]=0) do dec(digitCount);
      if k<>digitCount then ReAllocMem(digits,sizeOf(digitType)*digitCount);
    end;
  end;

CONSTRUCTOR T_bigint.createZero;
  begin
    create(false,0);
  end;

CONSTRUCTOR T_bigint.create(CONST negativeNumber: boolean;
  CONST digitCount_: longint);
  begin
    negative:=negativeNumber;
    digitCount:=digitCount_;
    getMem(digits,sizeOf(digitType)*digitCount);
  end;

CONSTRUCTOR T_bigint.fromInt(CONST i: int64);
  VAR unsigned:int64;
      d0,d1{$ifndef BIGDIGITS},d2,d3{$endif}:digitType;
  begin
    negative:=i<0;
    if negative
    then unsigned:=-i
    else unsigned:= i;
    d0:=(unsigned                       ) and DIGIT_MAX_VALUE;
    d1:=(unsigned shr (BITS_PER_DIGIT  )) and DIGIT_MAX_VALUE;
    {$ifndef BIGDIGITS}
    d2:=(unsigned shr (BITS_PER_DIGIT*2)) and DIGIT_MAX_VALUE;
    d3:=(unsigned shr (BITS_PER_DIGIT*3)) and DIGIT_MAX_VALUE;
    {$endif}
    digitCount:=4;
    {$ifndef BIGDIGITS}if d3=0 then{$endif} begin
      dec(digitCount);
      {$ifndef BIGDIGITS}if d3=0 then{$endif} begin
        dec(digitCount);
        if d1=0 then begin
          dec(digitCount);
          if d0=0 then dec(digitCount);
        end;
      end;
    end;
    getMem(digits,sizeOf(digitType)*digitCount);
    if digitCount>0 then digits[0]:=d0;
    if digitCount>1 then digits[1]:=d1;
    {$ifndef BIGDIGITS}
    if digitCount>2 then digits[2]:=d2;
    if digitCount>3 then digits[3]:=d3;
    {$endif}
  end;

CONSTRUCTOR T_bigint.fromString(CONST s: string);
  CONST MAX_CHUNK_SIZE={$ifdef bigDigits}9{$else}4{$endif};
        CHUNK_FACTOR:array[1..MAX_CHUNK_SIZE] of longint=(10,100,1000,10000{$ifdef bigDigits},100000,1000000,10000000,100000000,1000000000{$endif});
  VAR i:longint=1;
      chunkSize:longint;
      chunkValue:digitType;
  begin
    createZero;
    if length(s)=0 then raise Exception.create('Cannot parse empty string');
    if s[1]='-' then begin
      negative:=true;
      inc(i);
    end;
    while i<=length(s) do begin
      chunkSize:=length(s)-i+1;
      if chunkSize>4 then chunkSize:=4;
      chunkValue:=strToInt(copy(s,i,chunkSize));
      multWith(CHUNK_FACTOR[chunkSize]);
      incAbsValue(chunkValue);
      inc(i,chunkSize);
    end;
  end;

CONSTRUCTOR T_bigint.fromFloat(CONST f: extended; CONST rounding: T_roundingMode
  );
  VAR unsigned:extended;
      fraction:extended;
      addOne:boolean=false;
      k:longint;
      d:digitType;
  begin
    if isInfinite(f) or isNan(f) then raise Exception.create('Cannot create bigint from infinite or Nan float.');

    negative:=f<0;
    if negative then unsigned:=-f else unsigned:=f;
    fraction:=frac(unsigned);

    digitCount:=0;
    while unsigned>=1 do begin
      inc(digitCount);
      unsigned/=(DIGIT_MAX_VALUE+1);
    end;
    getMem(digits,sizeOf(digitType)*digitCount);
    for k:=digitCount-1 downto 0 do begin
      unsigned*=(DIGIT_MAX_VALUE+1);
      d:=trunc(unsigned);
      digits[k]:=d;
      unsigned-=d;
    end;
    case rounding of
      RM_DEFAULT: addOne:=(fraction>0.5) or (fraction=0.5) and getBit(0);
      RM_UP     : addOne:=not(negative) and (fraction<>0  );
      RM_DOWN   : addOne:=    negative  and (fraction<>0  );
    end;
    if addOne then incAbsValue(1);
  end;

CONSTRUCTOR T_bigint.create(CONST toClone: T_bigint);
  begin
    create(toClone.negative,toClone.digitCount);
    move(toClone.digits^,digits^,sizeOf(digitType)*digitCount);
  end;

FUNCTION T_bigint.toInt: int64;
  begin
    result:=0;
    if digitCount>0 then result:=         digits[0];
    if digitCount>1 then inc(result,int64(digits[1]) shl (BITS_PER_DIGIT  ));
    {$ifndef bigDigits}
    if digitCount>2 then inc(result,int64(digits[2]) shl (BITS_PER_DIGIT*2));
    if digitCount>3 then inc(result,int64(digits[3]) shl (BITS_PER_DIGIT*3));
    {$endif}
    if negative then result:=-result;
  end;

FUNCTION T_bigint.toFloat: extended;
  VAR k:longint;
  begin
    result:=0;
    for k:=digitCount-1 downto 0 do result:=result*(DIGIT_MAX_VALUE+1)+digits[k];
    if negative then result:=-result;
  end;

FUNCTION T_bigint.canBeRepresentedAsInt64(CONST examineNicheCase: boolean
  ): boolean;
  begin
    if digitCount*BITS_PER_DIGIT>64 then exit(false);
    if digitCount*BITS_PER_DIGIT<64 then exit(true);
    if not(getBit(63)) then exit(true);
    if negative and examineNicheCase then begin
      //in this case we can still represent -(2^63), so there is one special case to consider:
      result:=(digits[3]=UPPER_DIGIT_BIT) and (digits[2]=0) and (digits[1]=0) and (digits[0]=0);
    end else
    result:=false;
  end;

DESTRUCTOR T_bigint.destroy;
  begin
    freeMem(digits,sizeOf(digitType)*digitCount);
    digitCount:=0;
    negative:=false;
  end;

PROCEDURE T_bigint.flipSign;
  begin
    negative:=not(negative);
  end;

FUNCTION T_bigint.negated: T_bigint;
  begin
    result.create(self);
    result.flipSign;
  end;

FUNCTION T_bigint.compareAbsValue(CONST big: T_bigint): T_comparisonResult;
  VAR i:longint;
  begin
    if digitCount<big.digitCount then exit(CR_LESSER);
    if digitCount>big.digitCount then exit(CR_GREATER);
    //compare highest value digits first
    for i:=digitCount-1 downto 0 do begin
      if digits[i]<big.digits[i] then exit(CR_LESSER);
      if digits[i]>big.digits[i] then exit(CR_GREATER);
    end;
    result:=CR_EQUAL;
  end;

FUNCTION T_bigint.compareAbsValue(CONST int: int64): T_comparisonResult;
  VAR s,i:int64;
  begin
    if not(canBeRepresentedAsInt64(false)) then exit(CR_GREATER);
    s:=toInt; if s<0 then s:=-s;
    i:=  int; if i<0 then i:=-i;
    if s>i then exit(CR_GREATER);
    if s<i then exit(CR_LESSER);
    result:=CR_EQUAL;
  end;

FUNCTION T_bigint.compare(CONST big: T_bigint): T_comparisonResult;
  begin
    if negative and not(big.negative) then exit(CR_LESSER);
    if not(negative) and big.negative then exit(CR_GREATER);
    if negative then exit(C_FLIPPED[compareAbsValue(big)])
                else exit(          compareAbsValue(big) );
  end;

FUNCTION T_bigint.compare(CONST int: int64): T_comparisonResult;
  VAR s:int64;
  begin
    if int=0 then begin
      if digitCount=0  then exit(CR_EQUAL)
      else if negative then exit(CR_LESSER)
                       else exit(CR_GREATER);
    end;
    if not(canBeRepresentedAsInt64) then begin
      if negative then exit(CR_LESSER)
                  else exit(CR_GREATER);
    end;
    s:=toInt;
    if s>int then exit(CR_GREATER);
    if s<int then exit(CR_LESSER);
    result:=CR_EQUAL;
  end;

FUNCTION T_bigint.compare(CONST f: extended): T_comparisonResult;
  VAR unsigned:extended;
      fraction:extended;
      d:digitType;
      k:longint;
  begin
    if isNan(f) then exit(CR_INVALID_COMPARAND);
    if isInfinite(f) then begin
      if f>0 then exit(CR_LESSER)
             else exit(CR_GREATER);
    end;
    if     negative  and (f>=0) then exit(CR_LESSER);
    if not(negative) and (f< 0) then exit(CR_GREATER);
    //both have same sign; none is infinite

    if negative then unsigned:=-f else unsigned:=f;
    fraction:=frac(unsigned);

    k:=0;
    while unsigned>=1 do begin
      inc(k);
      unsigned/=(DIGIT_MAX_VALUE+1);
    end;
    if k>digitCount then begin
      if negative then exit(CR_GREATER)
                  else exit(CR_LESSER);
    end;
    for k:=digitCount-1 downto 0 do begin
      unsigned*=(DIGIT_MAX_VALUE+1);
      d:=trunc(unsigned);
      if d<digits[k] then begin
        if negative then exit(CR_GREATER)
                    else exit(CR_LESSER);
      end else if d>digits[k] then begin
        if negative then exit(CR_LESSER)
                    else exit(CR_GREATER);
      end;
      unsigned-=d;
    end;
    // all integer digits are equal; maybe there is a nonzero fraction...
    if fraction>0 then begin
      if negative then exit(CR_GREATER)
                  else exit(CR_LESSER);
    end;
    result:=CR_EQUAL;
  end;

FUNCTION T_bigint.plus(CONST big: T_bigint): T_bigint;
  VAR resultDigits:pDigitType;
      resultDigitCount:longint;
  begin
    if negative=big.negative then begin
      rawDataPlus(digits,      digitCount,
              big.digits,  big.digitCount,
            resultDigits,resultDigitCount);
      result.createFromRawData(negative,resultDigitCount,resultDigits);
    end else case compareAbsValue(big) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : begin
        rawDataMinus(big.digits,  big.digitCount,
                         digits,      digitCount,
                   resultDigits,resultDigitCount);
        result.createFromRawData(big.negative,resultDigitCount,resultDigits);
      end;
      CR_GREATER: begin
        rawDataMinus(digits,      digitCount,
                 big.digits,  big.digitCount,
               resultDigits,resultDigitCount);
        result.createFromRawData(negative,resultDigitCount,resultDigits);
      end;
    end;
  end;

//function T_bigint.plus(const int: Int64): T_bigint;
//  VAR carry:int64=0;
//      sumDigitCount:longint;
//      sumDigits:PWord;
//      bint:T_bigint;
//      i:longint;
//  begin
//    if (digitCount=0) then begin
//      new(result,fromInt(int));
//      exit(result);
//    end;
//    if negative then begin
//      if int>0 then exit(minus( int)) else carry:=-int;
//    end else begin
//      if int<0 then exit(minus(-int)) else carry:= int;
//    end;
//    {$Q-}{$R-}
//    carry:=carry+digits[0];
//    {$Q+}{$R+}
//    //If addition of the first digit overflows...
//    if (carry<0) then begin
//      bint.fromInt(int);
//      result:=plus(bint);
//      bint.destroy;
//      exit(result);
//    end;
//    //acutal addition:
//    sumDigitCount:=5;
//    getMem(sumDigits,sizeOf(word)*sumDigitCount);
//
//    sumDigits[0]:=carry and DIGIT_MAX_VALUE;
//    carry:=carry shr BITS_PER_DIGIT;
//
//    for i:=1 to 4 do begin
//      if i<digitCount then inc(carry,digits[i]);
//      sumDigits[i]:=carry and DIGIT_MAX_VALUE;
//      carry:=carry shr BITS_PER_DIGIT;
//    end;
//    //handle leading zeros
//    while (sumDigitCount>0) and (sumDigits[sumDigitCount-1]=0) do dec(sumDigitCount);
//    if sumDigitCount<>5 then ReAllocMem(sumDigits,sizeOf(word)*sumDigitCount);
//    //create result
//    new(result,createFromRawData(negative,sumDigitCount,sumDigits));
//  end;

FUNCTION T_bigint.minus(CONST big: T_bigint): T_bigint;
  VAR resultDigits:pDigitType;
      resultDigitCount:longint;
  begin
    if negative xor big.negative then begin
      //(-x)-y = -(x+y)
      //x-(-y) =   x+y
      rawDataPlus(digits,    digitCount,
              big.digits,big.digitCount,
                  resultDigits,resultDigitCount);
      result.createFromRawData(negative,resultDigitCount,resultDigits);
    end else case compareAbsValue(big) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : begin
        // x-y = -(y-x) //opposed sign as y
        rawDataMinus(big.digits,  big.digitCount,
                         digits,      digitCount,
                   resultDigits,resultDigitCount);
        result.createFromRawData(not(big.negative),resultDigitCount,resultDigits);
      end;
      CR_GREATER: begin
        rawDataMinus(digits,      digitCount,
                 big.digits,  big.digitCount,
               resultDigits,resultDigitCount);
        result.createFromRawData(negative,resultDigitCount,resultDigits);
      end;
    end;
  end;

//function T_bigint.minus(const int: int64): T_bigint;
//  VAR unsignedInt:int64;
//      resultDigits:Pword;
//      resultDigitCount:longint;
//  PROCEDURE subtractSmall;
//    VAR tmp:int64;
//        i:longint;
//    begin
//      resultDigitCount:=5;
//      getMem(resultDigits,sizeOf(word)*resultDigitCount);
//
//      for i:=0 to 4 do begin
//        tmp:=unsignedInt;
//        if i<digitCount then
//
//      end;
//    end;
//
//  PROCEDURE subtractBig;
//    begin
//      resultDigitCount:=5;
//      getMem(resultDigits,sizeOf(word)*resultDigitCount);
//
//    end;
//
//  begin
//    if (digitCount=0) then begin
//      new(result,fromInt(-int));
//      exit(result);
//    end;
//    if negative then begin
//      if int>0 then exit(plus(-int)) else unsignedInt:=-int;
//    end else begin
//      if int<0 then exit(plus(-int)) else unsignedInt:= int;
//    end;
//    case compareAbsValue(int) of
//      CR_EQUAL  : new(result,create(false,0));
//      CR_LESSER : subtractSmall;
//      CR_GREATER: subtractBig;
//    end;
//  end;

FUNCTION T_bigint.mult(CONST big: T_bigint): T_bigint;
  VAR resultDigits:pDigitType;
      resultDigitCount:longint;
      i,j,k:longint;
      carry:carryType=0;
  begin
    resultDigitCount:=digitCount+big.digitCount;
    getMem(resultDigits,sizeOf(DigitType)*resultDigitCount);
    for k:=0 to resultDigitCount-1 do resultDigits[k]:=0;
    for i:=0 to     digitCount-1 do
    for j:=0 to big.digitCount-1 do begin
      k:=i+j;
      carry:=carryType(digits[i])*carryType(big.digits[j]);
      while carry>0 do begin
        //x[i]*y[i]+r[i] <= (2^n-1)*(2^n-1)+2^n-1
        //                = (2^n)^2 - 2*2^n + 1 + 2^n-1
        //                = (2^n)^2 - 2*2^n + 1
        //                < (2^n)^2 - 2     + 1 = (max value of carry type)
        carry+=resultDigits[k];
        resultDigits[k]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        inc(k);
      end;
    end;
    k:=resultDigitCount-1;
    while (k>0) and (resultDigits[k]=0) do dec(k);
    if resultDigitCount<>k+1 then begin
      resultDigitCount:=k+1;
      ReAllocMem(resultDigits,sizeOf(digitType)*resultDigitCount);
    end;
    result.createFromRawData(negative xor big.negative,resultDigitCount,resultDigits);
  end;

FUNCTION T_bigint.pow(power: dword): T_bigint;
  VAR multiplicand:T_bigint;
  begin
    // x ** 0 = 1
    if power=0 then begin
      result.create(false,1);
      result.digits[0]:=1;
      exit(result);
    end;
    // x^1 = x
    if power=1 then begin
      result.create(self);
      exit(result);
    end;
    multiplicand.create(self);
    result      .create(false,1); result.digits[0]:=1;
    while power>0 do begin
      if odd(power) then result.multWith(multiplicand);
      multiplicand.multWith(multiplicand);
      power:=power shr 1;
    end;
    multiplicand.destroy;
  end;

FUNCTION T_bigint.bitAnd(CONST big: T_bigint): T_bigint;
  VAR k:longint;
  begin
    if big.digitCount<digitCount
    then k:=big.digitCount
    else k:=    digitCount;
    result.create(false,k);
    while k>0 do begin
      dec(k);
      result.digits[k]:=digits[k] and big.digits[k];
    end;
    k:=result.digitCount-1;
    while (k>0) and (result.digits[k]=0) do dec(k);
    if k+1<>result.digitCount then begin
      result.digitCount:=k+1;
      ReAllocMem(result.digits,result.digitCount*sizeOf(digitType));
    end;
  end;

FUNCTION T_bigint.bitOr(CONST big: T_bigint): T_bigint;
  VAR k:longint;
  begin
    if big.digitCount>digitCount
    then k:=big.digitCount
    else k:=    digitCount;
    result.create(false,k);
    while k>0 do begin
      dec(k);
      result.digits[k]:=digits[k] or big.digits[k];
    end;
    k:=result.digitCount-1;
    while (k>0) and (result.digits[k]=0) do dec(k);
    if k+1<>result.digitCount then begin
      result.digitCount:=k+1;
      ReAllocMem(result.digits,result.digitCount*sizeOf(digitType));
    end;
  end;

FUNCTION T_bigint.bitXor(CONST big: T_bigint): T_bigint;
  VAR k:longint;
  begin
    if big.digitCount>digitCount
    then k:=big.digitCount
    else k:=    digitCount;
    result.create(false,k);
    while k>0 do begin
      dec(k);
      result.digits[k]:=digits[k] xor big.digits[k];
    end;
    k:=result.digitCount-1;
    while (k>0) and (result.digits[k]=0) do dec(k);
    if k+1<>result.digitCount then begin
      result.digitCount:=k+1;
      ReAllocMem(result.digits,result.digitCount*sizeOf(digitType));
    end;
  end;

PROCEDURE T_bigint.multWith(CONST l: longint);
  VAR carry:carryType=0;
      factor:digitType;
      k:longint;
  begin
    if l=0 then begin
      digitCount:=0;
      ReAllocMem(digits,0);
      negative:=false;
      exit;
    end;
    if l<0 then begin
      factor:=-l;
      negative:=not(negative);
    end else factor:=l;
    for k:=0 to digitCount-1 do begin
      carry+=factor*digits[k];
      digits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
    if carry>0 then begin
      k:=digitCount+1;
      //need to grow... but how much ?
      if carry shr BITS_PER_DIGIT>0 then begin
        inc(k);
        if carry shr (2*BITS_PER_DIGIT)>0 then inc(k);
      end;
      ReAllocMem(digits,k*sizeOf(digitType));
      while digitCount<k do begin
        digits[digitCount]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        inc(digitCount);
      end;
    end;
  end;

PROCEDURE T_bigint.multWith(CONST b: T_bigint);
  VAR temp:T_bigint;
  begin
    temp:=mult(b);
    freeMem(digits,sizeOf(digitType)*digitCount);
    digitCount:=temp.digitCount;
    digits    :=temp.digits;
    negative  :=temp.negative;
  end;

PROCEDURE T_bigint.incAbsValue(CONST positiveIncrement: dword);
  VAR carry:int64;
      k:longint;
  begin
    carry:=positiveIncrement;
    k:=0;
    while carry>0 do begin
      if k>=digitCount then begin
        inc(digitCount);
        ReAllocMem(digits,digitCount*sizeOf(digitType));
        digits[k]:=0;
      end;
      carry+=digits[k];
      digits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
  end;

FUNCTION T_bigint.divMod(CONST divisor: T_bigint; OUT quotient, rest: T_bigint): boolean;
  PROCEDURE rawDec(VAR   xDigits:pDigitType; VAR   xDigitCount:longint;
                   CONST yDigits:pDigitType; CONST yDigitCount:longint); inline;
    VAR carry:carryType=0;
        i    :longint;
    begin
      for i:=0 to yDigitCount-1 do begin
        carry+=yDigits[i];
        if carry>xDigits[i] then begin
          xDigits[i]:=((DIGIT_MAX_VALUE+1)-carry+xDigits[i]) and DIGIT_MAX_VALUE;
          carry:=1;
        end else begin
          xDigits[i]:=xDigits[i]-carry;
          carry:=0;
        end;
      end;
      while (xDigitCount>0) and (xDigits[xDigitCount-1]=0) do dec(xDigitCount);
      if xDigitCount<>xDigitCount then ReAllocMem(xDigits,sizeOf(digitType)*xDigitCount);
    end;

  VAR bitIdx:longint;
  begin
    if divisor.digitCount=0 then exit(false);
    quotient.create(negative xor divisor.negative,0);
    rest    .create(negative                     ,0);
    for bitIdx:=relevantBits-1 downto 0 do begin
      rest.shlInc(getBit(bitIdx));
      if rest.compareAbsValue(divisor) in [CR_EQUAL,CR_GREATER] then begin
        rawDec(rest.digits,   rest.digitCount,
            divisor.digits,divisor.digitCount);
        quotient.setBit(bitIdx,true);
      end;
    end;
  end;

FUNCTION T_bigint.divide(CONST divisor: T_bigint): T_bigint;
  VAR temp:T_bigint;
  begin
    divMod(divisor,result,temp);
    temp.destroy;
  end;

FUNCTION T_bigint.modulus(CONST divisor: T_bigint): T_bigint;
  VAR temp:T_bigint;
  begin
    divMod(divisor,temp,result);
    temp.destroy;
  end;

PROCEDURE T_bigint.divBy(CONST divisor: digitType; OUT rest: digitType);
  VAR bitIdx:longint;
      quotient:T_bigint;
      tempRest:carryType=0;
  begin
    quotient.create(false,0);
    for bitIdx:=relevantBits-1 downto 0 do begin
      tempRest:=tempRest shl 1;
      if getBit(bitIdx) then inc(tempRest);
      if tempRest>=divisor then begin
        dec(tempRest,divisor);
        quotient.setBit(bitIdx,true);
      end;
    end;
    freeMem(digits,sizeOf(digitType)*digitCount);
    digits:=quotient.digits;
    digitCount:=quotient.digitCount;
    rest:=tempRest;
  end;

FUNCTION T_bigint.toString: string;
  VAR temp:T_bigint;
      chunkVal:digitType;
      chunkTxt:string;
  begin
    if digitCount=0 then exit('0');
    temp.create(self);
    result:='';
    {$ifdef BIGDIGITS}
    while temp.compareAbsValue(10000000) in [CR_EQUAL,CR_GREATER] do begin
      temp.divBy(100000000,chunkVal);
      chunkTxt:=intToStr(chunkVal);
      result:=StringOfChar('0',8-length(chunkTxt))+chunkTxt+result;
    end;
    {$endif}
    while temp.compareAbsValue(1000) in [CR_EQUAL,CR_GREATER] do begin
      temp.divBy(10000,chunkVal);
      chunkTxt:=intToStr(chunkVal);
      result:=StringOfChar('0',4-length(chunkTxt))+chunkTxt+result;
    end;
    while temp.compareAbsValue(1) in [CR_EQUAL,CR_GREATER] do begin
      temp.divBy(10,chunkVal);
      chunkTxt:=intToStr(chunkVal);
      result:=chunkTxt+result;
    end;
    if negative then result:='-'+result;
    temp.destroy;
  end;

FUNCTION T_bigint.hash: dword;
  VAR k:longint;
  begin
    {$Q-}{$R-}
    result:=31*digitCount;
    if negative then inc(result);
    for k:=0 to digitCount-1 do result:=result*31+digits[k];
    {$Q+}{$R+}
  end;

FUNCTION T_bigint.equals(CONST b: T_bigint): boolean;
  VAR k:longint;
  begin
    if not((negative  =b.negative) and
           (digitCount=b.digitCount)) then exit(false);
    for k:=0 to digitCount-1 do if (digits[k]<>b.digits[k]) then exit(false);
    result:=true;
  end;

FUNCTION T_bigint.isZero: boolean;
  begin
    result:=digitCount=0;
  end;

PROCEDURE T_bigint.shiftRightOneBit;
  VAR k:longint;
  begin
    for k:=0 to digitCount-1 do begin
      if (k>0) and odd(digits[k]) then digits[k-1]:=digits[k-1] or UPPER_DIGIT_BIT;
      digits[k]:=digits[k] shr 1;
    end;
    if digits[digitCount-1]=0 then begin
      dec(digitCount);
      ReAllocMem(digits,sizeOf(digitType)*digitCount);
    end;
  end;

PROCEDURE T_bigint.writeToStream(CONST stream: P_outputStreamWrapper);
  VAR value:int64;
      k:longint;
  begin
    if canBeRepresentedAsInt64 then begin
      value:=toInt;
      if      (value>=          0) and (value<=       249) then       stream^.writeByte(value)
      else if (value>=       -128) and (value<=       127) then begin stream^.writeByte(250); stream^.writeShortint(value); end
      else if (value>=     -32768) and (value<=     32767) then begin stream^.writeByte(251); stream^.writeSmallInt(value); end
      else if (value>=-2147483648) and (value<=2147483647) then begin stream^.writeByte(252); stream^.writeLongint (value); end
      else                                                      begin stream^.writeByte(253); stream^.writeInt64   (value); end;
    end else begin
      if negative then stream^.writeByte(255)
                  else stream^.writeByte(254);
      stream^.writeLongint(digitCount); //number of following Dwords
      for k:=0 to digitCount-1 do {$ifdef BIGDIGITS}stream^.writeDWord{$else}stream^.writeWord{$endif}(digits[k]);
    end;
  end;

CONSTRUCTOR T_bigint.readFromStream(CONST stream: P_inputStreamWrapper);
  VAR markerByte:byte;
      k:longint;
  begin
    markerByte:=stream^.readByte;
    case markerByte of
      254,255: begin
        negative:=odd(markerByte);
        digitCount:=stream^.readLongint;
        getMem(digits,sizeOf(digitType)*digitCount);
        for k:=0 to digitCount-1 do digits[k]:= {$ifdef BIGDIGITS}stream^.readDWord{$else}stream^.readWord{$endif};
      end;
      253: fromInt(stream^.readInt64);
      252: fromInt(stream^.readLongint);
      251: fromInt(stream^.readSmallInt);
      250: fromInt(stream^.readShortint);
      else fromInt(markerByte);
    end;
  end;

FUNCTION T_bigint.lowDigit: digitType;
  begin
    if digitCount=0 then exit(0) else exit(digits[0]);
  end;

FUNCTION T_bigint.sign: shortint;
  begin
    if  digitCount=0 then exit(0)
    else if negative then exit(-1)
                     else exit(1);
  end;

end.

