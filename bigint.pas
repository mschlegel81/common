UNIT bigint;
INTERFACE
USES sysutils,
     math,
     myGenerics,
     serializationUtil;
TYPE
  DigitType=dword;
  CarryType=qword;
  DigitTypeArray=array of DigitType;
CONST
  BITS_PER_DIGIT=32;
  DIGIT_MAX_VALUE:int64=(1 shl BITS_PER_DIGIT)-1;
  UPPER_DIGIT_BIT=1 shl (BITS_PER_DIGIT-1);
  WORD_BIT:array[0..BITS_PER_DIGIT-1] of DigitType=
    (      1,       2,       4,        8,       16,       32,        64,       128,
         256,     512,    1024,     2048,     4096,     8192,     16384,     32768,
       65536,  131072,  262144,   524288,  1048576,  2097152,   4194304,   8388608,
    16777216,33554432,67108864,134217728,268435456,536870912,1073741824,2147483648);

TYPE
  T_comparisonResult=(CR_EQUAL,
                      CR_LESSER,
                      CR_GREATER,
                      CR_INVALID_COMPARAND);
  T_roundingMode=(RM_DEFAULT,RM_UP,RM_DOWN);
CONST
   C_FLIPPED:array[T_comparisonResult] of T_comparisonResult=(CR_EQUAL,CR_GREATER,CR_LESSER,CR_INVALID_COMPARAND);
TYPE
  F_rand32Source        =FUNCTION:dword;
  F_rand32SourceOfObject=FUNCTION:dword of object;
  T_arrayOfByte=array of byte;

  T_bigInt=object
    private
      negative:boolean;
      digits:DigitTypeArray;
      PROCEDURE createFromRawData(CONST negative_:boolean; CONST digits_:DigitTypeArray);
      PROCEDURE nullBits(CONST numberOfBitsToKeep:longint);

      PROCEDURE shlInc(CONST incFirstBit:boolean);
      PROCEDURE setBit(CONST index:longint; CONST value:boolean);
      FUNCTION compareAbsValue(CONST big:T_bigInt):T_comparisonResult; inline;
      FUNCTION compareAbsValue(CONST int:int64):T_comparisonResult; inline;

      PROCEDURE multWith(CONST l:longint);
      PROCEDURE multWith(CONST b:T_bigInt);
      PROCEDURE divBy(CONST divisor:DigitType; OUT rest:DigitType);
      PROCEDURE incAbsValue(CONST positiveIncrement:DigitType);
      PROCEDURE shiftRightOneBit;
    public
      FUNCTION relevantBits:longint;
      PROCEDURE shiftRight(CONST rightShift:longint);
      PROPERTY isNegative:boolean read negative;

      PROCEDURE createZero;
      PROCEDURE create(CONST negativeNumber:boolean; CONST digitCount_:longint);
      PROCEDURE fromInt(CONST i:int64);
      PROCEDURE fromString(CONST s:string);
      PROCEDURE fromFloat(CONST f:extended; CONST rounding:T_roundingMode);
      PROCEDURE create(CONST toClone:T_bigInt);
      PROCEDURE createFromDigits(CONST base:longint; CONST digits_:T_arrayOfLongint);
      PROCEDURE clear;
      FUNCTION toInt:int64;
      FUNCTION toFloat:extended;
      {if examineNicheCase is true, the case of -2^63 is considered; otherwise the function is symmetrical}
      FUNCTION canBeRepresentedAsInt64(CONST examineNicheCase: boolean=true): boolean;
      FUNCTION canBeRepresentedAsInt62:boolean;
      FUNCTION canBeRepresentedAsInt32(CONST examineNicheCase: boolean=true): boolean;
      FUNCTION getBit(CONST index:longint):boolean;
      FUNCTION getDigits(CONST base:longint):T_arrayOfLongint;

      PROCEDURE flipSign;
      FUNCTION negated:T_bigInt;
      FUNCTION compare(CONST big:T_bigInt):T_comparisonResult; inline;
      FUNCTION compare(CONST int:int64   ):T_comparisonResult; inline;
      FUNCTION compare(CONST f:extended  ):T_comparisonResult; inline;
      FUNCTION minus(CONST small:DigitType):T_bigInt;
      FUNCTION pow  (power:dword ):T_bigInt;
      FUNCTION powMod(CONST power,modul:T_bigInt):T_bigInt;
      FUNCTION isOdd:boolean;
      FUNCTION bitAnd(CONST big:T_bigInt):T_bigInt;
      FUNCTION bitAnd(CONST small:int64 ):T_bigInt;
      FUNCTION bitOr (CONST big:T_bigInt):T_bigInt;
      FUNCTION bitOr (CONST small:int64 ):T_bigInt;
      FUNCTION bitXor(CONST big:T_bigInt):T_bigInt;
      FUNCTION bitXor(CONST small:int64 ):T_bigInt;
      FUNCTION bitNegate(CONST consideredBits:longint):T_bigInt;
      {returns true on success, false on division by zero}
      FUNCTION divMod(CONST divisor:T_bigInt; OUT quotient,rest:T_bigInt):boolean;
      FUNCTION divide(CONST divisor:T_bigInt):T_bigInt;
      FUNCTION modulus(CONST divisor:T_bigInt):T_bigInt;
      FUNCTION toString:string;
      FUNCTION toHexString:string;
      FUNCTION equals(CONST b:T_bigInt):boolean;
      FUNCTION isZero:boolean;
      FUNCTION isOne:boolean;

      FUNCTION isBetween(CONST lowerBoundInclusive,upperBoundInclusive:longint):boolean;

      PROCEDURE writeToStream(CONST stream:P_outputStreamWrapper);
      PROCEDURE readFromStream(CONST stream:P_inputStreamWrapper);
      PROCEDURE readFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper);
      FUNCTION lowDigit:DigitType;
      FUNCTION sign:shortint;
      FUNCTION greatestCommonDivider(CONST other:T_bigInt):T_bigInt;
      FUNCTION greatestCommonDivider(CONST other:int64):int64;
      FUNCTION modularInverse(CONST modul:T_bigInt; OUT thereIsAModularInverse:boolean):T_bigInt;
      FUNCTION iSqrt(CONST computeEvenIfNotSquare:boolean; CONST roundingMode:T_roundingMode; OUT isSquare:boolean):T_bigInt;
      FUNCTION iLog2(OUT isPowerOfTwo:boolean):longint;
      FUNCTION hammingWeight:longint;
      FUNCTION getRawBytes:T_arrayOfByte;
      FUNCTION hash:dword;
    end;

  T_arrayOfBigint=array of T_bigInt;
  T_factorizationResult=record
    smallFactors:T_arrayOfLongint;
    bigFactors:T_arrayOfBigint;
  end;

  T_dynamicContinueFlag=FUNCTION:boolean of object;

FUNCTION randomInt(CONST randomSource:F_rand32Source        ; CONST maxValExclusive:T_bigInt):T_bigInt;
FUNCTION randomInt(CONST randomSource:F_rand32SourceOfObject; CONST maxValExclusive:T_bigInt):T_bigInt;
FUNCTION factorizeSmall(n:int64):T_factorizationResult;
FUNCTION factorize(CONST B:T_bigInt; CONST continue:T_dynamicContinueFlag):T_factorizationResult;
FUNCTION isPrime(CONST n:int64 ):boolean;
FUNCTION isPrime(CONST B:T_bigInt):boolean;
FUNCTION bigDigits(CONST value,base:T_bigInt):T_arrayOfBigint;
FUNCTION newFromBigDigits(CONST digits:T_arrayOfBigint; CONST base:T_bigInt):T_bigInt;
{For compatibility with constructor T_bigInt.readFromStream}
FUNCTION readLongintFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper):longint;
PROCEDURE writeLongintToStream(CONST value:longint; CONST stream:P_outputStreamWrapper);

OPERATOR +(CONST x:T_bigInt; CONST y:int64):T_bigInt;
OPERATOR +(CONST x,y:T_bigInt):T_bigInt;
OPERATOR -(CONST x:T_bigInt; CONST y:int64):T_bigInt;
OPERATOR -(CONST x:int64; CONST y:T_bigInt):T_bigInt;
OPERATOR -(CONST x,y:T_bigInt):T_bigInt;
OPERATOR *(CONST x:T_bigInt; CONST y:int64):T_bigInt;
OPERATOR *(CONST x,y:T_bigInt):T_bigInt;
FUNCTION divide (CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION divide (CONST x:int64; CONST y:T_bigInt):T_bigInt;
OPERATOR mod(CONST x:T_bigInt; CONST y:int64):int64;
FUNCTION modulus(CONST x:int64; CONST y:T_bigInt):T_bigInt;

IMPLEMENTATION
FUNCTION randomInt(CONST randomSource:F_rand32Source; CONST maxValExclusive:T_bigInt):T_bigInt;
  VAR k:longint;
      temp:T_bigInt;
  begin
    if maxValExclusive.isZero then begin
      result.createZero;
      exit;
    end;
    temp.create(false,length(maxValExclusive.digits));
    for k:=0 to length(temp.digits)-1 do temp.digits[k]:=randomSource();
    result:=temp.modulus(maxValExclusive);
  end;

FUNCTION randomInt(CONST randomSource:F_rand32SourceOfObject; CONST maxValExclusive:T_bigInt):T_bigInt;
  VAR k:longint;
      temp:T_bigInt;
  begin
    if maxValExclusive.isZero then begin
      result.createZero;
      exit;
    end;
    temp.create(false,length(maxValExclusive.digits));
    for k:=0 to length(temp.digits)-1 do temp.digits[k]:=randomSource();
    result:=temp.modulus(maxValExclusive);
  end;

OPERATOR +(CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x+bigY;
  end;

FUNCTION rawDataPlus(CONST xDigits,yDigits:DigitTypeArray):DigitTypeArray;
  VAR carry:CarryType=0;
      i    :longint;
  begin
       i:=length(xDigits);
    if i< length(yDigits) then
       i:=length(yDigits);
    initialize(result);
    setLength(result,i);
    for i:=0 to length(result)-1 do begin
      if i<length(xDigits) then carry+=xDigits[i];
      if i<length(yDigits) then carry+=yDigits[i];
      result[i]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
    if carry>0 then begin
      setLength(result,length(result)+1);
      result[length(result)-1]:=carry;
    end;
  end;

PROCEDURE trimLeadingZeros(VAR digits:DigitTypeArray); inline;
  VAR i:longint;
  begin
    i:=length(digits);
    while (i>0) and (digits[i-1]=0) do dec(i);
    if i<>length(digits) then setLength(digits,i);
  end;

{Precondition: x>y}
FUNCTION rawDataMinus(CONST xDigits,yDigits:DigitTypeArray):DigitTypeArray; inline;
  VAR carry:CarryType=0;
      i    :longint;
  begin
    initialize(result);
    setLength(result,length(xDigits));
    for i:=0 to length(yDigits)-1 do begin
      carry+=yDigits[i];
      if carry>xDigits[i] then begin
        result[i]:=((DIGIT_MAX_VALUE+1)-carry+xDigits[i]) and DIGIT_MAX_VALUE;
        carry:=1;
      end else begin
        result[i]:=xDigits[i]-carry;
        carry:=0;
      end;
    end;
    for i:=length(yDigits) to length(xDigits)-1 do begin
      if carry>xDigits[i] then begin
        result[i]:=((DIGIT_MAX_VALUE+1)-carry+xDigits[i]) and DIGIT_MAX_VALUE;
        carry:=1;
      end else begin
        result[i]:=xDigits[i]-carry;
        carry:=0;
      end;
    end;
    trimLeadingZeros(result);
  end;

OPERATOR +(CONST x,y:T_bigInt):T_bigInt;
  begin
    if x.negative=y.negative
    then result.createFromRawData(x.negative,rawDataPlus(x.digits,y.digits))
    else case x.compareAbsValue(y) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : result.createFromRawData(y.negative,rawDataMinus(y.digits,x.digits));
      CR_GREATER: result.createFromRawData(x.negative,rawDataMinus(x.digits,y.digits));
    end;
  end;

OPERATOR -(CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x-bigY;
  end;

OPERATOR -(CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    bigX.fromInt(x);
    result:=bigX-y;
  end;

OPERATOR -(CONST x,y:T_bigInt):T_bigInt;
  begin
    if x.negative xor y.negative then
      //(-x)-y = -(x+y)
      //x-(-y) =   x+y
      result.createFromRawData(x.negative,rawDataPlus(x.digits,y.digits))
    else case x.compareAbsValue(y) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : // x-y = -(y-x) //opposed sign as y
                  result.createFromRawData(not(y.negative),rawDataMinus(y.digits,x.digits));
      CR_GREATER: result.createFromRawData(x.negative     ,rawDataMinus(x.digits,y.digits));
    end;
  end;

OPERATOR *(CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x*bigY;
  end;

OPERATOR *(CONST x,y:T_bigInt):T_bigInt;
  VAR i,j,k:longint;
      carry:CarryType=0;
  begin
    {$ifndef debugMode}
    if x.canBeRepresentedAsInt32() then begin
      if y.canBeRepresentedAsInt32()  then begin
        result.fromInt(x.toInt*y.toInt);
        exit(result);
      end else begin
        result.create(y);
        result.multWith(x);
        exit(result);
      end;
    end else if y.canBeRepresentedAsInt32() then begin
      result.create(x);
      result.multWith(y.toInt);
      exit(result);
    end;
    {$endif}
    result.create(x.negative xor y.negative,length(x.digits)+length(y.digits));
    for k:=0 to length(result.digits)-1 do result.digits[k]:=0;
    for i:=0 to length(x.digits)-1 do
    for j:=0 to length(y.digits)-1 do begin
      k:=i+j;
      carry:=CarryType(x.digits[i])*CarryType(y.digits[j]);
      while carry>0 do begin
        //x[i]*y[i]+r[i] <= (2^n-1)*(2^n-1)+2^n-1
        //                = (2^n)^2 - 2*2^n + 1 + 2^n-1
        //                = (2^n)^2 - 2*2^n + 1
        //                < (2^n)^2 - 2     + 1 = (max value of carry type)
        carry+=result.digits[k];
        result.digits[k]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        inc(k);
      end;
    end;
    trimLeadingZeros(result.digits);
  end;

FUNCTION divide (CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.divide(bigY);
  end;

FUNCTION divide (CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    bigX.fromInt(x);
    result:=bigX.divide(y);
  end;

OPERATOR mod(CONST x:T_bigInt; CONST y:int64):int64;
  FUNCTION digitValue(CONST index:longint):int64; inline;
    VAR f:int64;
        i:longint;
    begin
      result:=x.digits[index] mod y;
      i:=index;
      f:=(DIGIT_MAX_VALUE+1) mod y;
      while i>0 do begin
        if odd(i) then begin
          result:=(result * f) mod y;
        end;
        f:=(f*f) mod y;
        i:=i shr 1;
      end;
    end;

  VAR bigY,bigResult,bigQuotient:T_bigInt;
      k:longint;
  begin
    if (y>-3025451648) and (y<3025451648) then begin
      result:=0;
      for k:=0 to length(x.digits)-1 do result:=(result+digitValue(k)) mod y;
    end else begin
      bigY.fromInt(y);
      x.divMod(bigY,bigQuotient,bigResult);
      result:=bigResult.toInt;
    end;
  end;

FUNCTION modulus(CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    if y.canBeRepresentedAsInt64() then result.fromInt(x) else begin
      bigX.fromInt(x);
      result:=bigX.modulus(y);
    end;
  end;

FUNCTION T_bigInt.isOdd:boolean; begin result:=(length(digits)>0) and odd(digits[0]); end;

PROCEDURE T_bigInt.createFromRawData(CONST negative_:boolean; CONST digits_:DigitTypeArray);
  begin
    negative  :=negative_ and (length(digits_)>0); //no such thing as a negative zero
    digits    :=digits_;
  end;

PROCEDURE T_bigInt.nullBits(CONST numberOfBitsToKeep:longint);
  VAR i:longint;
  begin
    for i:=length(digits)*BITS_PER_DIGIT-1 downto numberOfBitsToKeep do setBit(i,false);
  end;

PROCEDURE T_bigInt.shlInc(CONST incFirstBit: boolean);
  VAR k:longint;
      carryBit:boolean;
      nextCarry:boolean;
  begin
    carryBit:=incFirstBit;
    nextCarry:=carryBit;
    for k:=0 to length(digits)-1 do begin
      nextCarry:=(digits[k] and UPPER_DIGIT_BIT)<>0;
      {$R-}
      digits[k]:=digits[k] shl 1;
      {$R+}
      if carryBit then inc(digits[k]);
      carryBit:=nextCarry;
    end;
    if nextCarry then begin
      k:=length(digits);
      setLength(digits,k+1);
      digits[k]:=1;
    end;
  end;

FUNCTION T_bigInt.relevantBits: longint;
  VAR upperDigit:DigitType;
      k:longint;
  begin
    if length(digits)=0 then exit(0);
    upperDigit:=digits[length(digits)-1];
    result:=BITS_PER_DIGIT*length(digits);
    for k:=BITS_PER_DIGIT-1 downto 0 do
      if upperDigit<WORD_BIT[k]
      then dec (result)
      else exit(result);
  end;

FUNCTION T_bigInt.getBit(CONST index: longint): boolean;
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    if digitIndex>=length(digits) then exit(false);
    bitIndex  :=index mod BITS_PER_DIGIT;
    result:=(digits[digitIndex] and WORD_BIT[bitIndex])<>0;
  end;

PROCEDURE T_bigInt.setBit(CONST index: longint; CONST value: boolean);
  VAR digitIndex:longint;
      bitIndex  :longint;
      oldLength:longint;
      k:longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    bitIndex:=index and (BITS_PER_DIGIT-1);
    if value then begin
      //setting a true bit means, we might have to increase the number of digits
      if (digitIndex>=length(digits)) and value then begin
        oldLength:=length(digits);
        setLength(digits,digitIndex+1);
        for k:=length(digits)-1 downto oldLength do digits[k]:=0;
      end;
      digits[digitIndex]:=digits[digitIndex] or WORD_BIT[bitIndex];
    end else begin
      //setting a false bit means, we might have to decrease the number of digits
      if digitIndex>=length(digits) then exit;
      digits[digitIndex]:=digits[digitIndex] and not(WORD_BIT[bitIndex]);
      trimLeadingZeros(digits);
    end;
  end;

PROCEDURE T_bigInt.createZero;
  begin
    create(false,0);
  end;

PROCEDURE T_bigInt.create(CONST negativeNumber: boolean; CONST digitCount_: longint);
  begin
    negative:=negativeNumber;
    setLength(digits,digitCount_);
  end;

PROCEDURE T_bigInt.fromInt(CONST i: int64);
  VAR unsigned:int64;
      d0,d1:DigitType;
  begin
    negative:=i<0;
    if negative
    then unsigned:=-i
    else unsigned:= i;
    d0:=(unsigned                       ) and DIGIT_MAX_VALUE;
    d1:=(unsigned shr (BITS_PER_DIGIT  )) and DIGIT_MAX_VALUE;
    if d1=0 then begin
      if d0=0
      then setLength(digits,0)
      else setLength(digits,1);
    end else setLength(digits,2);
    if length(digits)>0 then digits[0]:=d0;
    if length(digits)>1 then digits[1]:=d1;
  end;

PROCEDURE T_bigInt.fromString(CONST s: string);
  CONST MAX_CHUNK_SIZE=9;
        CHUNK_FACTOR:array[1..MAX_CHUNK_SIZE] of longint=(10,100,1000,10000,100000,1000000,10000000,100000000,1000000000);
  VAR i:longint=1;
      chunkSize:longint;
      chunkValue:DigitType;
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

PROCEDURE T_bigInt.fromFloat(CONST f: extended; CONST rounding: T_roundingMode);
  VAR r:TDoubleRec;
      fraction:double;
  begin
    r.value:=f;
    fromInt(r.Mantissa+4503599627370496);
    shiftRight(52-r.exponent);
    case rounding of
      RM_DEFAULT: begin fraction:=frac(abs(f)); if (fraction>0.5) or (fraction=0.5) and getBit(0) then incAbsValue(1); end;
      RM_UP     :                               if not(r.sign) and (frac(f)<>0) then incAbsValue(1);
      RM_DOWN   :                               if     r.sign  and (frac(f)<>0) then incAbsValue(1);
    end;
    negative:=r.sign;
  end;

PROCEDURE T_bigInt.create(CONST toClone: T_bigInt);
  VAR k:longint;
  begin
    create(toClone.negative,length(toClone.digits));
    for k:=0 to length(digits)-1 do digits[k]:=toClone.digits[k];
  end;

PROCEDURE T_bigInt.createFromDigits(CONST base: longint; CONST digits_:T_arrayOfLongint);
  VAR i:longint;
  begin
    createZero;
    for i:=0 to length(digits_)-1 do begin
      multWith(base);
      incAbsValue(digits_[i]);
    end;
  end;

PROCEDURE T_bigInt.clear;
  begin
    setLength(digits,0);
  end;

FUNCTION newFromBigDigits(CONST digits:T_arrayOfBigint; CONST base:T_bigInt):T_bigInt;
  VAR i:longint;
      tmp:T_bigInt;
      allSmall:boolean;
      baseAsInt:longint;
  begin
    allSmall:=(base.canBeRepresentedAsInt32()) and not(base.negative);
    for i:=0 to length(digits)-1 do allSmall:=allSmall and (length(digits[i].digits)<=1) and not(digits[i].negative);
    result.createZero;
    if allSmall then begin
      baseAsInt:=base.toInt;
      for i:=0 to length(digits)-1 do begin
        result.multWith(baseAsInt);
        if length(digits[i].digits)>0 then result.incAbsValue(digits[i].digits[0]);
      end;
    end else begin
      for i:=0 to length(digits)-1 do begin
        tmp:=result*base;
        result:=tmp + digits[i];
      end;
    end;
  end;

FUNCTION T_bigInt.toInt: int64;
  begin
    if length(digits)>0 then begin
      result:=digits[0];
      if length(digits)>1 then inc(result,int64(digits[1]) shl BITS_PER_DIGIT);
      if negative then result:=-result;
    end else result:=0;
  end;

FUNCTION T_bigInt.toFloat: extended;
  VAR k:longint;
  begin
    result:=0;
    for k:=length(digits)-1 downto 0 do result:=result*(DIGIT_MAX_VALUE+1)+digits[k];
    if negative then result:=-result;
  end;

FUNCTION T_bigInt.canBeRepresentedAsInt64(CONST examineNicheCase: boolean): boolean;
  begin
    if length(digits)*BITS_PER_DIGIT>64 then exit(false);
    if length(digits)*BITS_PER_DIGIT<64 then exit(true);
    if not(getBit(63)) then exit(true);
    if negative and examineNicheCase then begin
      //in this case we can still represent -(2^63), so there is one special case to consider:
      result:=(digits[1]=UPPER_DIGIT_BIT) and (digits[0]=0);
    end else
    result:=false;
  end;

FUNCTION T_bigInt.canBeRepresentedAsInt62:boolean;
  CONST UPPER_TWO_BITS=3 shl (BITS_PER_DIGIT-2);
  begin
    if length(digits)*BITS_PER_DIGIT>62 then exit(false);
    if length(digits)*BITS_PER_DIGIT<62 then exit(true);
    result:=digits[1] and UPPER_TWO_BITS=0;
  end;

FUNCTION T_bigInt.canBeRepresentedAsInt32(CONST examineNicheCase: boolean): boolean;
  begin
    if length(digits)*BITS_PER_DIGIT>32 then exit(false);
    if length(digits)*BITS_PER_DIGIT<32 then exit(true);
    if not(getBit(31)) then exit(true);
    if negative and examineNicheCase then begin
      //in this case we can still represent -(2^31), so there is one special case to consider:
      result:=(digits[0]=UPPER_DIGIT_BIT);
    end else
    result:=false;
  end;

PROCEDURE T_bigInt.flipSign;
  begin
    negative:=not(negative);
  end;

FUNCTION T_bigInt.negated: T_bigInt;
  begin
    result.create(self);
    result.flipSign;
  end;

FUNCTION T_bigInt.compareAbsValue(CONST big: T_bigInt): T_comparisonResult;
  VAR i:longint;
  begin
    if length(digits)<length(big.digits) then exit(CR_LESSER);
    if length(digits)>length(big.digits) then exit(CR_GREATER);
    //compare highest value digits first
    for i:=length(digits)-1 downto 0 do begin
      if digits[i]<big.digits[i] then exit(CR_LESSER);
      if digits[i]>big.digits[i] then exit(CR_GREATER);
    end;
    result:=CR_EQUAL;
  end;

FUNCTION T_bigInt.compareAbsValue(CONST int: int64): T_comparisonResult;
  VAR s,i:int64;
  begin
    if not(canBeRepresentedAsInt64(false)) then exit(CR_GREATER);
    s:=toInt; if s<0 then s:=-s;
    i:=  int; if i<0 then i:=-i;
    if s>i then exit(CR_GREATER);
    if s<i then exit(CR_LESSER);
    result:=CR_EQUAL;
  end;

FUNCTION T_bigInt.compare(CONST big: T_bigInt): T_comparisonResult;
  begin
    if negative and not(big.negative) then exit(CR_LESSER);
    if not(negative) and big.negative then exit(CR_GREATER);
    if negative then exit(C_FLIPPED[compareAbsValue(big)])
                else exit(          compareAbsValue(big) );
  end;

FUNCTION T_bigInt.compare(CONST int: int64): T_comparisonResult;
  VAR s:int64;
  begin
    if int=0 then begin
      if length(digits)=0  then exit(CR_EQUAL)
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

FUNCTION T_bigInt.compare(CONST f: extended): T_comparisonResult;
  VAR unsigned:extended;
      fraction:extended;
      d:DigitType;
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
    if k>length(digits) then begin
      if negative then exit(CR_GREATER)
                  else exit(CR_LESSER);
    end else if k<length(digits) then begin
      if negative then exit(CR_LESSER)
                  else exit(CR_GREATER);
    end;
    for k:=length(digits)-1 downto 0 do begin
      unsigned*=(DIGIT_MAX_VALUE+1);
      d:=trunc(unsigned);
      if d<digits[k] then begin
        if negative then exit(CR_LESSER)
                    else exit(CR_GREATER);
      end else if d>digits[k] then begin
        if negative then exit(CR_GREATER)
                    else exit(CR_LESSER);
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

FUNCTION T_bigInt.minus(CONST small:DigitType):T_bigInt;
  VAR smallAsArray:DigitTypeArray=();
  begin
    setLength(smallAsArray,1);
    smallAsArray[0]:=small;
    if negative then
      //(-x)-y = -(x+y)
      //x-(-y) =   x+y
      result.createFromRawData(negative,rawDataPlus(digits,smallAsArray))
    else case compareAbsValue(small) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : // x-y = -(y-x) //opposed sign as y
                  result.createFromRawData(true ,rawDataMinus(smallAsArray,digits));
      CR_GREATER: result.createFromRawData(false,rawDataMinus(digits,smallAsArray));
    end;
  end;

FUNCTION T_bigInt.pow(power: dword): T_bigInt;
  CONST BASE_THRESHOLD_FOR_EXPONENT:array[2..62] of longint=(maxLongint,2097151,55108,6208,1448,511,234,127,78,52,38,28,22,18,15,13,11,9,8,7,7,6,6,5,5,5,4,4,4,4,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2);
  VAR multiplicand:T_bigInt;
      m:int64;
      r:int64;
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
    if (power<=62) and (compareAbsValue(BASE_THRESHOLD_FOR_EXPONENT[power]) in [CR_EQUAL,CR_LESSER]) then begin
      r:=1;
      m:=toInt;
      {$R-}{$Q-}
      while power>0 do begin
        if odd(power) then r*=m;
        m*=m;
        power:=power shr 1;
      end;
      {$R+}{$Q+}
      result.fromInt(r);
    end else begin
      result.create(false,1); result.digits[0]:=1;
      multiplicand.create(self);
      while power>0 do begin
        if odd(power) then result.multWith(multiplicand);
        multiplicand.multWith(multiplicand);
        power:=power shr 1;
      end;
    end;
  end;

FUNCTION T_bigInt.powMod(CONST power,modul:T_bigInt):T_bigInt;
  PROCEDURE doModulus(VAR inOut:T_bigInt);
    VAR temp:T_bigInt;
    begin
      if inOut.compareAbsValue(modul)=CR_LESSER then exit;
      temp:=inOut.modulus(modul);
      inOut:=temp;
    end;

  VAR p,f:T_bigInt;
  begin
    if (power.isZero) or (power.negative) or
       (modul.negative) or (modul.isZero) then begin
      result.fromInt(1);
      exit(result);
    end;
    if (power.compare(1)=CR_EQUAL) or (modul.compare(1)=CR_EQUAL) then begin
      result:=modulus(modul);
      exit(result);
    end;
    p.create(power);
    f:=modulus(modul);
    result.fromInt(1);
    while not(p.isZero) do begin
      if p.getBit(0) then begin
        result.multWith(f); doModulus(result);
      end;
      f.multWith(f);  doModulus(f);
      p.shiftRightOneBit;
    end;
  end;

FUNCTION T_bigInt.bitAnd(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=min(length(digits),length(big.digits));
    result.create(isNegative and big.isNegative,k);
    for i:=0 to length(result.digits)-1 do result.digits[i]:=digits[i] and big.digits[i];
    trimLeadingZeros(result.digits);
  end;

FUNCTION T_bigInt.bitOr(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=max(length(digits),length(big.digits));
    result.create(isNegative or big.isNegative,k);
    for i:=0 to length(result.digits)-1 do begin
      if (i<    length(digits)) then result.digits[i]:=digits[i]
                                else result.digits[i]:=0;
      if (i<length(big.digits)) then result.digits[i]:=result.digits[i] or big.digits[i];
    end;
    trimLeadingZeros(result.digits);
  end;

FUNCTION T_bigInt.bitXor(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=max(length(digits),length(big.digits));
    result.create(isNegative xor big.isNegative,k);
    for i:=0 to length(result.digits)-1 do begin
      if (i<    length(digits)) then result.digits[i]:=digits[i]
                                else result.digits[i]:=0;
      if (i<length(big.digits)) then result.digits[i]:=result.digits[i] xor big.digits[i];
    end;
    trimLeadingZeros(result.digits);
  end;

FUNCTION T_bigInt.bitAnd(CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitAnd(big); end;
FUNCTION T_bigInt.bitOr (CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitOr (big); end;
FUNCTION T_bigInt.bitXor(CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitXor(big); end;

FUNCTION T_bigInt.bitNegate(CONST consideredBits:longint):T_bigInt;
  VAR k,i:longint;
  begin
    if consideredBits<=0 then k:=relevantBits
                         else k:=consideredBits;
    result.create(false,length(digits));
    for i:=0 to min(length(digits),length(result.digits))-1 do result.digits[i]:=not(digits[i]);
    result.nullBits(k);
  end;

FUNCTION isPowerOf2(CONST i:DigitType; OUT log2:longint):boolean; inline;
  VAR k:longint;
  begin
    result:=false;
    for k:=0 to length(WORD_BIT)-1 do if i=WORD_BIT[k] then begin
      log2:=k;
      exit(true);
    end;
  end;

PROCEDURE T_bigInt.multWith(CONST l: longint);
  VAR carry:CarryType=0;
      factor:DigitType;
      i:longint;
      k:longint;
  begin
    if l=0 then begin
      setLength(digits,0);
      negative:=false;
      exit;
    end;
    if l<0 then begin
      factor:=-l;
      negative:=not(negative);
    end else factor:=l;
    if isPowerOf2(factor,k) then begin
      shiftRight(-k);
      exit;
    end;

    for k:=0 to length(digits)-1 do begin
      carry+=CarryType(factor)*CarryType(digits[k]);
      digits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
    if carry>0 then begin
      k:=length(digits)+1;
      //need to grow... but how much ?
      if carry shr BITS_PER_DIGIT>0 then begin
        inc(k);
        if carry shr (2*BITS_PER_DIGIT)>0 then inc(k);
      end;
      i:=length(digits);
      setLength(digits,k);
      while i<k do begin
        digits[i]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        inc(i);
      end;
    end;
  end;

PROCEDURE T_bigInt.multWith(CONST b: T_bigInt);
  VAR temp:T_bigInt;
  begin
    temp      :=self*b;
    setLength(digits,0);
    digits    :=temp.digits;
    negative  :=temp.negative;
  end;

PROCEDURE T_bigInt.incAbsValue(CONST positiveIncrement: DigitType);
  VAR carry:int64;
      k:longint;
  begin
    carry:=positiveIncrement;
    k:=0;
    while carry>0 do begin
      if k>=length(digits) then begin
        setLength(digits,length(digits)+1);
        digits[k]:=0;
      end;
      carry+=digits[k];
      digits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
  end;

FUNCTION T_bigInt.divMod(CONST divisor: T_bigInt; OUT quotient, rest: T_bigInt): boolean;
  PROCEDURE rawDec; inline;
    VAR carry:CarryType=0;
        i    :longint;
    begin
      for i:=0 to length(divisor.digits)-1 do begin
        carry+=divisor.digits[i];
        if carry>rest.digits[i] then begin
          rest.digits[i]:=((DIGIT_MAX_VALUE+1)-carry+rest.digits[i]) and DIGIT_MAX_VALUE;
          carry:=1;
        end else begin
          rest.digits[i]-=carry;
          carry:=0;
        end;
      end;
      for i:=length(divisor.digits) to length(rest.digits)-1 do begin
        if carry>rest.digits[i] then begin
          rest.digits[i]:=((DIGIT_MAX_VALUE+1)-carry+rest.digits[i]) and DIGIT_MAX_VALUE;
          carry:=1;
        end else begin
          rest.digits[i]-=carry;
          carry:=0;
        end;
      end;
    end;

  FUNCTION restGeqDivisor:boolean; inline;
    VAR i:longint;
    begin
      if length(divisor.digits)>length(rest.digits) then exit(false);
      for i:=length(rest.digits)-1 downto length(divisor.digits) do if rest.digits[i]>0 then exit(true);
      for i:=length(divisor.digits)-1 downto 0 do
        if       divisor.digits[i]<rest.digits[i] then exit(true)
        else if  divisor.digits[i]>rest.digits[i] then exit(false);
      result:=true;
    end;

  VAR bitIdx:longint;
      divIsPow2:boolean;
  begin
    if length(divisor.digits)=0 then exit(false);
    bitIdx:=divisor.iLog2(divIsPow2);
    if divIsPow2 then begin
      rest.create(self);
      rest.nullBits(bitIdx);
      quotient.create(self);
      quotient.shiftRight(bitIdx);
      exit(true);
    end;

    result:=true;
    quotient.create(negative xor divisor.negative,0);
    rest    .create(negative,length(divisor.digits));
    //Initialize rest with (probably) enough digits
    for bitIdx:=0 to length(rest.digits)-1 do rest.digits[bitIdx]:=0;
    for bitIdx:=relevantBits-1 downto 0 do begin
      rest.shlInc(getBit(bitIdx));
      if restGeqDivisor then begin
        rawDec();
        quotient.setBit(bitIdx,true);
      end;
    end;
    trimLeadingZeros(rest.digits);
  end;

FUNCTION T_bigInt.divide(CONST divisor: T_bigInt): T_bigInt;
  VAR temp:T_bigInt;
      {$ifndef debugMode} intRest:DigitType; {$endif}
  begin
    {$ifndef debugMode}
    if (canBeRepresentedAsInt64() and divisor.canBeRepresentedAsInt64()) then begin
      result.fromInt(toInt div divisor.toInt);
      exit(result);
    end else if divisor.canBeRepresentedAsInt32(false) and not(divisor.negative) then begin
      result.create(self);
      result.divBy(divisor.toInt,intRest);
      exit(result);
    end;
    {$endif}
    divMod(divisor,result,temp);
  end;

FUNCTION T_bigInt.modulus(CONST divisor: T_bigInt): T_bigInt;
  VAR temp:T_bigInt;
      {$ifndef debugMode} intRest:DigitType; {$endif}
  begin
    {$ifndef debugMode}
    if (canBeRepresentedAsInt64() and divisor.canBeRepresentedAsInt64()) then begin
      result.fromInt(toInt mod divisor.toInt);
      exit(result);
    end else if divisor.canBeRepresentedAsInt32(false) and not(divisor.negative) then begin
      temp.create(self);
      temp.divBy(divisor.toInt,intRest);
      result.fromInt(intRest);
      exit(result);
    end;
    {$endif}
    divMod(divisor,temp,result);
  end;

PROCEDURE T_bigInt.divBy(CONST divisor: DigitType; OUT rest: DigitType);
  VAR bitIdx:longint;
      quotient:T_bigInt;
      divisorLog2:longint;
      tempRest:CarryType=0;
  begin
    if length(digits)=0 then begin
      rest:=0;
      exit;
    end;
    if isPowerOf2(divisor,divisorLog2) then begin
      rest:=digits[0] and (divisor-1);
      shiftRight(divisorLog2);
      exit;
    end else begin
      quotient.createZero;
      for bitIdx:=relevantBits-1 downto 0 do begin
        tempRest:=tempRest shl 1;
        if getBit(bitIdx) then inc(tempRest);
        if tempRest>=divisor then begin
          dec(tempRest,divisor);
          quotient.setBit(bitIdx,true);
        end;
      end;
      setLength(digits,0);
      digits:=quotient.digits;
      rest:=tempRest;
    end;
  end;

FUNCTION T_bigInt.toString: string;
  VAR temp:T_bigInt;
      chunkVal:DigitType;
      chunkTxt:string;
  begin
    if length(digits)=0 then exit('0');
    temp.create(self);
    result:='';
    while temp.compareAbsValue(10000000) in [CR_EQUAL,CR_GREATER] do begin
      temp.divBy(100000000,chunkVal);
      chunkTxt:=intToStr(chunkVal);
      result:=StringOfChar('0',8-length(chunkTxt))+chunkTxt+result;
    end;
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
  end;

FUNCTION T_bigInt.toHexString:string;
  CONST hexChar:array [0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
        shifts:array[0..7] of byte=(28,24,20,16,12,8,4,0);
  VAR hasADigit:boolean=false;
      digit :DigitType;
      hexDig:byte;
      Shift :byte;
      i:longint;
  begin
    if length(digits)=0 then exit('0');
    if negative then result:='-' else result:='';
    for i:=length(digits)-1 downto 0 do begin
      digit:=digits[i];
      for Shift in shifts do begin
        hexDig:=(digit shr Shift) and 15;
        if (hexDig>0) or hasADigit then begin
          hasADigit:=true;
          result+=hexChar[hexDig];
        end;
      end;
    end;
  end;

FUNCTION T_bigInt.getDigits(CONST base: longint): T_arrayOfLongint;
  VAR temp:T_bigInt;
      digit:DigitType;
      iTemp:int64;
      s:string;
      resLen:longint=0;
  begin
    initialize(result);
    setLength(result,0);
    if isZero then exit(0);
    if canBeRepresentedAsInt64(false) then begin
      setLength(result,64);
      iTemp:=toInt;
      if negative then iTemp:=-iTemp;
      while (iTemp>0) do begin
        digit:=iTemp mod base;
        iTemp:=iTemp div base;
        result[resLen]:=digit;
        inc(resLen);
      end;
      setLength(result,resLen);
    end else if base=10 then begin
      s:=toString;
      if negative then s:=copy(s,2,length(s)-1);
      setLength(result,length(s));
      for digit:=1 to length(s) do
      result[length(s)-digit]:=ord(s[digit])-ord('0');
    end else if base=2 then begin
      iTemp:=relevantBits;
      setLength(result,iTemp);
      for digit:=0 to iTemp-1 do if getBit(digit) then result[digit]:=1 else result[digit]:=0;
    end else begin
      temp.create(self);
      if negative then temp.flipSign;
      while temp.compareAbsValue(1) in [CR_EQUAL,CR_GREATER] do begin
        temp.divBy(base,digit);
        setLength(result,length(result)+1);
        result[length(result)-1]:=digit;
      end;
    end;
  end;

FUNCTION bigDigits(CONST value,base:T_bigInt):T_arrayOfBigint;
  VAR temp,quotient,rest:T_bigInt;
      smallDigits:T_arrayOfLongint;
      k:longint;
      resSize:longint=0;
  begin
    initialize(result);
    if base.canBeRepresentedAsInt32 then begin
      smallDigits:=value.getDigits(base.toInt);
      setLength(result,length(smallDigits));
      for k:=0 to length(smallDigits)-1 do result[k].fromInt(smallDigits[k]);
      setLength(smallDigits,0);
    end else begin
      setLength(result,round(1+1.01*length(value.digits)));
      temp.create(value);
      temp.negative:=false;
      while temp.compareAbsValue(1) in [CR_EQUAL,CR_GREATER] do begin
        temp.divMod(base,quotient,rest);
        result[resSize]:=rest; inc(resSize);
        temp:=quotient;
      end;
      setLength(result,resSize);
    end;
  end;

FUNCTION T_bigInt.equals(CONST b: T_bigInt): boolean;
  VAR k:longint;
  begin
    if (negative      <>b.negative) or
       (length(digits)<>length(b.digits)) then exit(false);
    for k:=0 to length(digits)-1 do if (digits[k]<>b.digits[k]) then exit(false);
    result:=true;
  end;

FUNCTION T_bigInt.isZero: boolean;
  begin
    result:=length(digits)=0;
  end;

FUNCTION T_bigInt.isOne: boolean;
  begin
    result:=(length(digits)=1) and not(isNegative) and (digits[0]=1);
  end;

FUNCTION T_bigInt.isBetween(CONST lowerBoundInclusive, upperBoundInclusive: longint): boolean;
  VAR i:int64;
  begin
    if not(canBeRepresentedAsInt32()) then exit(false);
    i:=toInt;
    result:=(i>=lowerBoundInclusive) and (i<=upperBoundInclusive);
  end;

PROCEDURE T_bigInt.shiftRightOneBit;
  VAR k:longint;
  begin
    for k:=0 to length(digits)-1 do begin
      if (k>0) and odd(digits[k]) then digits[k-1]:=digits[k-1] or UPPER_DIGIT_BIT;
      digits[k]:=digits[k] shr 1;
    end;
    if (length(digits)>0) and (digits[length(digits)-1]=0) then setLength(digits,length(digits)-1);
  end;

PROCEDURE T_bigInt.shiftRight(CONST rightShift:longint);
  VAR digitsToShift:longint;
      bitsToShift  :longint;
      newBitCount  :longint;
      newDigitCount:longint;
      carry,nextCarry:DigitType;
      oldLength:longint;
      k:longint;
  begin
    if rightShift=0 then exit;
    bitsToShift  :=abs(rightShift);
    digitsToShift:=bitsToShift div BITS_PER_DIGIT;
    bitsToShift  -=digitsToShift * BITS_PER_DIGIT;
    if rightShift>0 then begin
      if rightShift>=relevantBits then begin
        setLength(digits,0);
        negative:=false;
        exit;
      end;
      if digitsToShift>0 then begin
        for k:=0 to length(digits)-digitsToShift-1 do digits[k]:=digits[k+digitsToShift];
        for k:=length(digits)-digitsToShift to length(digits)-1 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=length(digits)-digitsToShift-1 downto 0 do begin
          nextCarry:=digits[k];
          digits[k]:=(digits[k] shr bitsToShift) or (carry shl (BITS_PER_DIGIT-bitsToShift));
          carry:=nextCarry;
        end;
      end;
      trimLeadingZeros(digits);
    end else begin
      newBitCount:=relevantBits-rightShift;
      newDigitCount:=newBitCount div BITS_PER_DIGIT; if newDigitCount*BITS_PER_DIGIT<newBitCount then inc(newDigitCount);
      if newDigitCount>length(digits) then begin
        oldLength:=length(digits);
        setLength(digits,newDigitCount);
        for k:=oldLength to newDigitCount-1 do digits[k]:=0;
      end;
      if digitsToShift>0 then begin
        for k:=length(digits)-1 downto digitsToShift do digits[k]:=digits[k-digitsToShift];
        for k:=digitsToShift-1 downto 0 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=0 to length(digits)-1 do begin
          nextCarry:=digits[k] shr (BITS_PER_DIGIT-bitsToShift);
          digits[k]:=(digits[k] shl bitsToShift) or carry;
          carry:=nextCarry;
        end;
      end;
    end;
  end;

PROCEDURE T_bigInt.writeToStream(CONST stream: P_outputStreamWrapper);
  VAR value:int64;
      k:longint;
  begin
    if canBeRepresentedAsInt64() then begin
      value:=toInt;
      if      (value>=          0) and (value<=       249) then       stream^.writeByte(value)
      else if (value>=       -128) and (value<=       127) then begin stream^.writeByte(250); stream^.writeShortint(value); end
      else if (value>=     -32768) and (value<=     32767) then begin stream^.writeByte(251); stream^.writeSmallInt(value); end
      else if (value>=-2147483648) and (value<=2147483647) then begin stream^.writeByte(252); stream^.writeLongint (value); end
      else                                                      begin stream^.writeByte(253); stream^.writeInt64   (value); end;
    end else begin
      if negative
      then stream^.writeByte(255)
      else stream^.writeByte(254);
      stream^.writeLongint(length(digits)); //number of following Dwords
      for k:=0 to length(digits)-1 do stream^.writeDWord(digits[k]);
    end;
  end;

FUNCTION readLongintFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper):longint;
  begin
    case markerByte of
      253..255: raise Exception.create('Could not read longint from stream; the number is too big.');
      252: result:=stream^.readLongint;
      251: result:=stream^.readSmallInt;
      250: result:=stream^.readShortint;
      else result:=markerByte;
    end;
  end;

PROCEDURE writeLongintToStream(CONST value:longint; CONST stream:P_outputStreamWrapper);
  begin
    if      (value>=     0) and (value<=  249) then       stream^.writeByte(value)
    else if (value>=  -128) and (value<=  127) then begin stream^.writeByte(250); stream^.writeShortint(value); end
    else if (value>=-32768) and (value<=32767) then begin stream^.writeByte(251); stream^.writeSmallInt(value); end
    else                                            begin stream^.writeByte(252); stream^.writeLongint (value); end;
  end;

PROCEDURE T_bigInt.readFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper);
  VAR k:longint;
  begin
    case markerByte of
      254,255: begin
        negative:=odd(markerByte);
        setLength(digits,stream^.readLongint);
        for k:=0 to length(digits)-1 do digits[k]:=stream^.readDWord;
      end;
      253: fromInt(stream^.readInt64);
      252: fromInt(stream^.readLongint);
      251: fromInt(stream^.readSmallInt);
      250: fromInt(stream^.readShortint);
      else fromInt(markerByte);
    end;
  end;

PROCEDURE T_bigInt.readFromStream(CONST stream: P_inputStreamWrapper);
  begin
    readFromStream(stream^.readByte,stream);
  end;

FUNCTION T_bigInt.lowDigit: DigitType;
  begin
    if length(digits)=0 then exit(0) else exit(digits[0]);
  end;

FUNCTION T_bigInt.sign: shortint;
  begin
    if length(digits)=0 then exit(0) else if negative then exit(-1) else exit(1);
  end;

FUNCTION T_bigInt.greatestCommonDivider(CONST other: T_bigInt): T_bigInt;
  VAR b,temp:T_bigInt;
      x,y,t:int64;
  begin
    if canBeRepresentedAsInt64(false) and other.canBeRepresentedAsInt64(false) then begin
      x:=      toInt;
      y:=other.toInt;
      while (y<>0) do begin
        t:=x mod y; x:=y; y:=t;
      end;
      result.fromInt(x);
    end else begin
      result.create(self);
      b.create(other);
      while not(b.isZero) do begin
        temp:=result.modulus(b);
        result:=b;
        b:=temp;
      end;
    end;
  end;

FUNCTION T_bigInt.greatestCommonDivider(CONST other:int64):int64;
  VAR y,t:int64;
      tempO,tempR:T_bigInt;
  begin
    if canBeRepresentedAsInt64(false) then begin
      result:=toInt;
      y:=other;
      while (y<>0) do begin
        t:=result mod y; result:=y; y:=t;
      end;
    end else begin
      tempO.fromInt(other);
      tempR:=greatestCommonDivider(tempO);
      result:=tempR.toInt;
    end;
  end;

FUNCTION T_bigInt.modularInverse(CONST modul:T_bigInt; OUT thereIsAModularInverse:boolean):T_bigInt;
  VAR r0,r1,
      t0,t1,
      quotient,rest:T_bigInt;
      {$ifndef debugMode}
      iq,ir0,ir1,tmp:int64;
      it0:int64=0;
      it1:int64=1;
      {$endif}

  begin
    {$ifndef debugMode}
    if canBeRepresentedAsInt64(false) and modul.canBeRepresentedAsInt64(false) then begin
      ir0:=abs(modul.toInt);
      ir1:=abs(      toInt);
      while(ir1<>0) do begin
        iq:=ir0 div ir1;
        tmp:=ir1; ir1:=ir0-ir1*iq; ir0:=tmp;
        tmp:=it1; it1:=it0-it1*iq; it0:=tmp;
      end;
      thereIsAModularInverse:=ir0<=1;
      if it0<0 then inc(it0,modul.toInt);
      result.fromInt(it0);
    end else
    {$endif}
    begin
      t0.createZero;
      t1.fromInt(1);
      r0.create(modul); r0.negative:=false;
      r1.create(self);  r1.negative:=false;
      initialize(quotient);
      initialize(rest);
      while not(r1.isZero) do begin
        setLength(quotient.digits,0);
        setLength(rest.digits,0);
        r0.divMod(r1,quotient,rest);
        r0:=r1;
        r1:=rest;
        quotient:=t0-quotient*t1;
        t0:=t1;
        t1:=quotient;
      end;
      setLength(r0.digits,0);
      setLength(r1.digits,0);
      setLength(t1.digits,0);
      setLength(rest.digits,0);
      setLength(quotient.digits,0);
      thereIsAModularInverse:=r0.compare(1) in [CR_LESSER,CR_EQUAL];
      if (t0.isNegative) then begin
        result:=t0 + modul;
      end else  result:=t0;
    end;
  end;

FUNCTION T_bigInt.iSqrt(CONST computeEvenIfNotSquare:boolean; CONST roundingMode:T_roundingMode; OUT isSquare:boolean):T_bigInt;
  CONST SQUARE_LOW_BYTE_VALUES:set of byte=[0,1,4,9,16,17,25,33,36,41,49,57,64,65,68,73,81,89,97,100,105,113,121,129,132,137,144,145,153,161,164,169,177,185,193,196,201,209,217,225,228,233,241,249];
  VAR resDt,temp:T_bigInt;
      done:boolean=false;
      step:longint=0;
      selfShl16:T_bigInt;
      {$ifndef debugMode}intRoot:int64;{$endif}
      floatSqrt:double;
  begin
    if negative or isZero then begin
      isSquare:=length(digits)=0;
      result.createZero;
      exit(result);
    end;
    if not((digits[0] and 255) in SQUARE_LOW_BYTE_VALUES) then begin
      isSquare:=false;
      if not(computeEvenIfNotSquare) then begin
        result.createZero;
        exit;
      end;
    end;
    {$ifndef debugMode}
    if canBeRepresentedAsInt64 then begin
      intRoot:=trunc(sqrt(toFloat));
      result.fromInt(intRoot);
      isSquare:=toInt=intRoot*intRoot;
      exit;
    end else if relevantBits<102 then begin
      result.fromFloat(sqrt(toFloat),RM_DOWN);
      temp:=result*result;
      isSquare:=equals(temp);
      exit;
    end;
    {$endif}
    //compute the square root of this*2^16, validate by checking lower 8 bits
    selfShl16.create(self);
    selfShl16.multWith(1 shl 16);
    floatSqrt:=sqrt(toFloat)*256;
    if isInfinite(floatSqrt) or isNan(floatSqrt) then begin
      result.createZero;
      result.setBit(selfShl16.relevantBits shr 1+1,true);
    end else result.fromFloat(floatSqrt,RM_DOWN);
    repeat
      selfShl16.divMod(result,resDt,temp);     //resDt = y div x@pre; temp = y mod x@pre
      isSquare:=temp.isZero;
      temp:=resDt + result;                //temp = y div x@pre + x@pre
      isSquare:=isSquare and not odd(temp.digits[0]);
      temp.shiftRightOneBit;
      done:=result.equals(temp);
      result:=temp;
      inc(step);
    until done or (step>100);

    isSquare:=isSquare and ((result.digits[0] and 255)=0);
    case roundingMode of
      RM_UP     : if (result.digits[0] and 255)=0 then begin
                    result.shiftRight(8);
                  end else begin
                    result.shiftRight(8);
                    result.incAbsValue(1);
                  end;
      RM_DEFAULT: if (result.digits[0] and 255)<127 then begin
                    result.shiftRight(8);
                  end else begin
                    result.shiftRight(8);
                    result.incAbsValue(1);
                  end;
       else result.shiftRight(8);
    end;
  end;

FUNCTION T_bigInt.iLog2(OUT isPowerOfTwo:boolean):longint;
  VAR i:longint;
  begin
    isPowerOfTwo:=false;
    if length(digits)=0 then exit(0);
    i:=length(digits)-1;
    if isPowerOf2(digits[length(digits)-1],result) then begin
      inc(result,BITS_PER_DIGIT*(length(digits)-1));
      isPowerOfTwo:=true;
      for i:=length(digits)-2 downto 0 do isPowerOfTwo:=isPowerOfTwo and (digits[i]=0);
    end else result:=0;
  end;

FUNCTION T_bigInt.hammingWeight:longint;
  VAR i:longint;
  begin
    result:=0;
    for i:=0 to length(digits)*BITS_PER_DIGIT-1 do if getBit(i) then inc(result);
  end;

FUNCTION T_bigInt.getRawBytes: T_arrayOfByte;
  VAR i:longint;
      tmp:dword=0;
  begin
    i:=relevantBits shr 3;
    if i*8<relevantBits then inc(i);
    initialize(result);
    setLength(result,i);
    for i:=0 to length(result)-1 do begin
      if i and 3=0 then tmp:=digits[i shr 2]
                   else tmp:=tmp shr 8;
      result[i]:=tmp and 255;
    end;
  end;

FUNCTION T_bigInt.hash:dword;
  VAR i:longint;
  begin
    {$Q-}{$R-}
    if isNegative then result:=1+2*length(digits) else result:=2*length(digits);
    for i:=0 to length(digits)-1 do result:=result*dword(127) + ((digits[i]*dword(11)) shr 3);
    {$Q+}{$R+}
  end;

CONST primes:array[0..144] of word=(3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,839);
CONST skip:array[0..47] of byte=(10,2,4,2,4,6,2,6,4,2,4,6,6,2,6,4,2,6,4,6,8,4,2,4,2,4,8,6,4,6,2,4,6,2,6,6,4,2,4,6,2,6,4,2,4,2,10,2);
FUNCTION factorizeSmall(n:int64):T_factorizationResult;
  FUNCTION isSquare(CONST y:int64; OUT rootOfY:int64):boolean;
    CONST SQUARE_LOW_BYTE_VALUES:set of byte=[0,1,4,9,16,17,25,33,36,41,49,57,64,65,68,73,81,89,97,100,105,113,121,129,132,137,144,145,153,161,164,169,177,185,193,196,201,209,217,225,228,233,241,249];
    begin
      if (y>=0) and (byte(y and 255) in SQUARE_LOW_BYTE_VALUES) then begin
        rootOfY:=round(sqrt(y));
        result:=rootOfY*rootOfY=y;
      end else result:=false;
    end;

  FUNCTION gcd(x,y:int64):int64; inline;
    begin
      result:=x;
      while (y<>0) do begin
        x:=result mod y; result:=y; y:=x;
      end;
    end;

  VAR p,k,x:int64;
      rootOfY:int64;
      skipIdx:longint=0;
      sqrt4KN,sixthRootOfN: double;
  begin
    initialize(result);
    setLength(result.smallFactors,0);
    if n<0 then begin
      n:=-n;
      append(result.smallFactors,-1);
      if n=1 then exit(result);
    end;
    if n=1 then begin
      append(result.smallFactors,1);
      exit(result);
    end;
    while (n>0) and not(odd(n)) do begin
      n:=n shr 1;
      append(result.smallFactors,2);
    end;
    for p in primes do begin
      if (int64(p)*p>n) then begin
        if n>1 then append(result.smallFactors,n);
        exit;
      end;
      while n mod p=0 do begin
        n:=n div p;
        append(result.smallFactors,p);
      end;
    end;
    p:=primes[length(primes)-1]+skip[length(skip)-1]; //=841
    while int64(p)*p*p<=n do begin
      while n mod p=0 do begin
        n:=n div p;
        append(result.smallFactors,p);
      end;
      inc(p,skip[skipIdx]);
      skipIdx:=(skipIdx+1) mod length(skip);
    end;
    if n=1 then exit(result);
    if isPrime(n) then begin
      if n<=maxLongint
      then append(result.smallFactors,n)
      else begin
        setLength(result.bigFactors,1);
        result.bigFactors[0].fromInt(n);
      end;
      exit(result);
    end;
    //Lehman...
    sixthRootOfN:=power(n,1/6)*0.25;
    writeln('Factorizing ',n);
    for k:=1 to floor(power(n,1/3)) do begin
      sqrt4KN:=2.0*sqrt(1.0*k*n);
      writeln('scanning k=',k,'; x = ',ceil64(sqrt4KN),'..',floor64(sqrt4KN+sixthRootOfN/sqrt(k)),' (',sqrt4KN:0:3,',',sixthRootOfN/sqrt(k):0:3,')');
      for x:=ceil64(sqrt4KN) to floor64(sqrt4KN+sixthRootOfN/sqrt(k)) do begin
        if isSquare(int64(x)*x-4*n*k,rootOfY) then begin
          p:=gcd(x+rootOfY,n);
          if p<=maxLongint
          then append(result.smallFactors,p)
          else begin
            setLength(result.bigFactors,1);
            result.bigFactors[0].fromInt(p);
          end;
          p:=n div p;
          if p<=maxLongint
          then append(result.smallFactors,p)
          else begin
            setLength(result.bigFactors,length(result.bigFactors)+1);
            result.bigFactors[length(result.bigFactors)-1].fromInt(p);
          end;
          exit(result);
        end;
      end;
    end;
    if n>1 then begin
      if n<=maxLongint
      then append(result.smallFactors,n)
      else begin
        setLength(result.bigFactors,1);
        result.bigFactors[0].fromInt(n);
      end;
    end;
  end;

FUNCTION factorize(CONST B:T_bigInt; CONST continue:T_dynamicContinueFlag):T_factorizationResult;
  FUNCTION basicFactorize(VAR inputAndRest:T_bigInt; OUT furtherFactorsPossible:boolean):T_factorizationResult;
    VAR workInInt64:boolean=false;
        n:int64=9223358842721533952; //to simplify conditions
    FUNCTION trySwitchToInt64:boolean; inline;
      begin
        if workInInt64 then exit(true);
        if inputAndRest.relevantBits<63 then begin
          n:=inputAndRest.toInt;
          workInInt64:=true;
        end;
        result:=workInInt64;
      end;

    FUNCTION longDivideIfRestless(CONST divider:T_bigInt):boolean;
      VAR quotient,rest:T_bigInt;
      begin
        inputAndRest.divMod(divider,quotient,rest);
        if rest.isZero then begin
          result:=true;
          inputAndRest:=quotient;
        end else begin
          result:=false;
        end;
      end;

    VAR p:longint;
        bigP:T_bigInt;
        skipIdx:longint=0;
        thirdRootOfInputAndRest:double;
    begin
      furtherFactorsPossible:=true;
      initialize(result);
      setLength(result.smallFactors,0);
      setLength(result.bigFactors,0);
      //2:
      if trySwitchToInt64 then begin
        while (n>0) and not(odd(n)) do begin
          n:=n shr 1;
          append(result.smallFactors,2);
        end;
      end else begin
        while (inputAndRest.relevantBits>0) and not(inputAndRest.isOdd) do begin
          inputAndRest.shiftRightOneBit;
          append(result.smallFactors,2);
        end;
      end;
      //By list of primes:
      for p in primes do begin
        if (int64(p)*p>n) then begin
          inputAndRest.fromInt(n);
          furtherFactorsPossible:=false;
          exit;
        end;
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
          end;
        end else begin
          while (inputAndRest mod p)=0 do begin
            inputAndRest:=divide(inputAndRest,p);
            append(result.smallFactors,p);
          end;
        end;
      end;
      if (continue<>nil) and not(continue()) then exit;
      //By skipping:
      p:=primes[length(primes)-1]+skip[length(skip)-1]; //=841
      //2097151.999999 = (2^63-1)^(1/3)
      while p<2097151 do begin
        if workInInt64 and ((int64(p)*p*p>n)) then begin
          inputAndRest.fromInt(n);
          furtherFactorsPossible:=int64(p)*p<=n;
          exit(result);
        end;
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
          end;
        end else begin
          while (inputAndRest mod p)=0 do begin
            inputAndRest:=divide(inputAndRest,p);
            append(result.smallFactors,p);
          end;
        end;
        inc(p,skip[skipIdx]);
        skipIdx:=(skipIdx+1) mod length(skip);
      end;
      if     workInInt64  and isPrime(n) then begin inputAndRest.fromInt(n); furtherFactorsPossible:=false; exit(result); end;
      if not(workInInt64) and isPrime(inputAndRest)  then begin              furtherFactorsPossible:=false; exit(result); end;
      if (continue<>nil) and not(continue()) then exit;
      thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
      while (p<maxLongint-10) and (p<thirdRootOfInputAndRest) do begin
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
        end else begin
          while (inputAndRest mod p)=0 do begin
            inputAndRest:=divide(inputAndRest,p);
            append(result.smallFactors,p);
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
        end;
        inc(p,skip[skipIdx]);
        skipIdx:=(skipIdx+1) mod length(skip);
      end;
      if workInInt64 then begin
        inputAndRest.fromInt(n);
        workInInt64:=false;
      end;
      if p<thirdRootOfInputAndRest then begin
        bigP.fromInt( p);
        while (bigP.compare(thirdRootOfInputAndRest) in [CR_LESSER,CR_EQUAL]) do begin
          while longDivideIfRestless(bigP) do begin
            setLength(result.bigFactors,length(result.bigFactors)+1);
            result.bigFactors[length(result.bigFactors)-1].create(bigP);
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
          bigP.incAbsValue(skip[skipIdx]);
          skipIdx:=(skipIdx+1) mod length(skip);
        end;
      end;
    end;

  VAR bigFourKN:T_bigInt;
  FUNCTION squareOfMinus4kn(CONST z:int64):T_bigInt;
    begin
      result.fromInt(z);
      result:=result*result-bigFourKN;
    end;

  FUNCTION floor64(CONST d:double):int64; begin result:=trunc(d); if frac(d)<0 then dec(result); end;
  FUNCTION ceil64 (CONST d:double):int64; begin result:=trunc(d); if frac(d)>0 then inc(result); end;
  FUNCTION squareIsLesser(CONST toBeSqared:int64; CONST comparand:T_bigInt):boolean; inline;
    VAR tmp:T_bigInt;
    begin
      tmp.fromInt(toBeSqared);
      result:=not((tmp*tmp).compare(comparand) in [CR_GREATER,CR_EQUAL]);
    end;
  FUNCTION bigOfFloat(CONST f:double; CONST rounding:T_roundingMode):T_bigInt;
    begin
      result.fromFloat(f,rounding);
    end;

  VAR r:T_bigInt;
      sixthRootOfR:double;

      furtherFactorsPossible:boolean;
      temp:double;

      k,kMax:int64;
      x,xMax:int64;
      bigX,bigXMax:T_bigInt;

      bigY:T_bigInt;
      bigRootOfY:T_bigInt;
      yIsSquare:boolean;
      lehmannTestCompleted:boolean=false;
  begin
    initialize(result);
    setLength(result.bigFactors,0);
    if B.isZero or (B.compareAbsValue(1)=CR_EQUAL) then begin
      setLength(result.smallFactors,1);
      result.smallFactors[0]:=B.toInt;
      exit;
    end;
    r.create(B);
    if B.isNegative then append(result.smallFactors,-1);

    if r.relevantBits<=63 then begin
      try
        result:=factorizeSmall(r.toInt);
        lehmannTestCompleted:=true;
      except
        lehmannTestCompleted:=false;
        setLength(result.smallFactors,0);
        for k:=0 to length(result.bigFactors)-1 do result.bigFactors[k].clear;
        setLength(result.bigFactors,0);
      end;
      if lehmannTestCompleted then exit;
    end;

    //if isPrime(r) then begin
    //  setLength(result.bigFactors,1);
    //  result.bigFactors[0]:=r;
    //  exit(result);
    //end;
    result:=basicFactorize(r,furtherFactorsPossible);
    if not(furtherFactorsPossible) then begin
      if not(r.compare(1) in [CR_LESSER,CR_EQUAL]) then begin
        setLength(result.bigFactors,length(result.bigFactors)+1);
        result.bigFactors[length(result.bigFactors)-1]:=r;
      end;
      exit;
    end;

    sixthRootOfR:=power(r.toFloat,1/6);
    temp        :=power(r.toFloat,1/3);
    if temp<9223372036854774000
    then kMax:=trunc(temp)
    else kMax:=9223372036854774000;
    k:=1;
    writeln('Factorizing ',r.toString);
    if not(isPrime(r)) then while (k<=kMax) and not(lehmannTestCompleted) and ((continue=nil) or continue()) do begin
      bigFourKN:=r*k;
      bigFourKN.shlInc(false);
      bigFourKN.shlInc(false);

      if r.compare(59172824724903) in [CR_LESSER,CR_EQUAL] then begin
        temp:=sqrt(bigFourKN.toFloat);
        x:=ceil64(temp); //<= 4*r^(4/3) < 2^63 ->  r < 2^(61*3/4) = 59172824724903
        while squareIsLesser(x,bigFourKN) do inc(x);
        xMax:=floor64(temp+sixthRootOfR/(4*sqrt(k))); //<= 4*r^(4/3)+r^(1/6)/(4*sqrt(r^(1/3))) -> r< 59172824724903

        writeln('scanning k=',k,'; x = ',x,'..',xMax);
        while x<=xMax do begin
          if (continue<>nil) and not(continue()) then exit;
          bigY:=squareOfMinus4kn(x);
          bigRootOfY:=bigY.iSqrt(false,RM_DEFAULT,yIsSquare);
          if yIsSquare then begin
            bigY:=(bigRootOfY + x).greatestCommonDivider(r); //=gcd(sqrt(bigY)+x,r)
            bigRootOfY:=r.divide(bigY);
            if bigY.isOne
            then       setLength(result.bigFactors,length(result.bigFactors)+1)
            else begin setLength(result.bigFactors,length(result.bigFactors)+2);
                       result.bigFactors[length(result.bigFactors)-2]:=bigY; end;
            result           .bigFactors[length(result.bigFactors)-1]:=bigRootOfY;
            lehmannTestCompleted:=true;
            x:=xMax;
          end;
          inc(x);
        end;
      end else begin
        bigX   :=bigFourKN.iSqrt(true,RM_UP,yIsSquare);
        bigXMax:=bigOfFloat(sqrt(bigFourKN.toFloat)+sixthRootOfR/(4*sqrt(k)),RM_DOWN);
        while bigX.compare(bigXMax) in [CR_EQUAL,CR_LESSER] do begin
          if (continue<>nil) and not(continue()) then exit;
          bigY:=bigX*bigX-bigFourKN;
          bigRootOfY:=bigY.iSqrt(false,RM_DEFAULT,yIsSquare);
          if yIsSquare then begin
            bigY:=(bigRootOfY + bigX).greatestCommonDivider(r); //=gcd(sqrt(bigY)+x,r)
            bigRootOfY:=r.divide(bigY);
            if bigY.isOne
            then       setLength(result.bigFactors,length(result.bigFactors)+1)
            else begin setLength(result.bigFactors,length(result.bigFactors)+2);
                       result.bigFactors[length(result.bigFactors)-2]:=bigY; end;
            result           .bigFactors[length(result.bigFactors)-1]:=bigRootOfY;
            lehmannTestCompleted:=true;
            bigX.create(bigXMax);
          end;
          bigX.incAbsValue(1);
        end;
      end;
      inc(k);
    end;
    if not(lehmannTestCompleted) then begin
      setLength(result.bigFactors,length(result.bigFactors)+1);
      result.bigFactors[length(result.bigFactors)-1]:=r;
    end;
  end;

FUNCTION isPrime(CONST n:int64):boolean;
  FUNCTION millerRabinTest(CONST n,a:int64):boolean;
    FUNCTION modularMultiply(x,y:qword):int64;
      VAR d:qword;
          mp2:qword;
          i:longint;
      begin
        if (x or y) and 9223372034707292160=0
        then result:=x*y mod n
        else begin
          d:=0;
          mp2:=n shr 1;
          for i:=0 to 62 do begin
            if d>mp2
            then d:=(d shl 1)-qword(n)
            else d:= d shl 1;
            if (x and 4611686018427387904)>0 then d+=y;
            if d>=qword(n) then d-=qword(n);
            x:=x shl 1;
          end;
          result:=d;
        end;
      end;

    VAR n1,d,t,p:int64;
        j:longint=1;
        k:longint;
    begin
      n1:=int64(n)-1;
      d :=n shr 1;
      while not(odd(d)) do begin
        d:=d shr 1;
        inc(j);
      end;
      //1<=j<=63, 1<=d<=2^63-1
      t:=a;
      p:=a;
      while (d>1) do begin
        d:=d shr 1;
        //p:=p*p mod n;
        p:=modularMultiply(p,p);
        if odd(d) then t:=modularMultiply(t,p);//t:=t*p mod n;
      end;
      if (t=1) or (t=n1) then exit(true);
      for k:=1 to j-1 do begin
        //t:=t*t mod n;
        t:=modularMultiply(t,t);
        if t=n1 then exit(true);
        if t<=1 then break;
      end;
      result:=false;
    end;

  FUNCTION isComposite:boolean;
    VAR x:int64=1;
        y:int64=2*3*5*7*11*13*17*19*23*29*31*37*41*43*47;
        z:int64=1;
    begin
      x:=n mod y;
      z:=y;
      y:=x;
      while (y<>0) do begin x:=z mod y; z:=y; y:=x; end;
      result:=z>1;
    end;

  begin
    if (n<=1) then exit(false);
    if (n<48) then exit(byte(n) in [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47]);
    if isComposite then exit(false)
    else if n<2209 then exit(true); //2209=47*47
    if n< 9080191
    then exit(millerRabinTest(n,31) and
              millerRabinTest(n,73)) else
    if n<25326001
    then exit(millerRabinTest(n,2) and
              millerRabinTest(n,3) and
              millerRabinTest(n,5)) else
    if n < 4759123141
    then exit(millerRabinTest(n,2) and
              millerRabinTest(n,7) and
              millerRabinTest(n,61)) else
    if n < 2152302898747   //[41bit] it is enough to test a =   array[0..4] of byte=(2,3,5,7,11);
    then exit(millerRabinTest(n, 2) and
              millerRabinTest(n, 3) and
              millerRabinTest(n, 5) and
              millerRabinTest(n, 7) and
              millerRabinTest(n,11)) else
    if n < 3474749660383   //[42bit] it is enough to test a =   array[0..5] of byte=(2,3,5,7,11,13);
    then exit(millerRabinTest(n, 2) and
              millerRabinTest(n, 3) and
              millerRabinTest(n, 5) and
              millerRabinTest(n, 7) and
              millerRabinTest(n,11) and
              millerRabinTest(n,13)) else
    if n < 341550071728321 //[49bit] it is enough to test a = array[0..6] of byte=(2,3,5,7,11,13,17);
    then exit(millerRabinTest(n, 2) and
              millerRabinTest(n, 3) and
              millerRabinTest(n, 5) and
              millerRabinTest(n, 7) and
              millerRabinTest(n,11) and
              millerRabinTest(n,13) and
              millerRabinTest(n,17)) else
    //if n < 18446744073709551616 = 2^64, it is enough to test a = 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, and 37.
    result:=millerRabinTest(n, 2) and
            millerRabinTest(n, 3) and
            millerRabinTest(n, 5) and
            millerRabinTest(n, 7) and
            millerRabinTest(n,11) and
            millerRabinTest(n,13) and
            millerRabinTest(n,17) and
            millerRabinTest(n,19) and
            millerRabinTest(n,23) and
            millerRabinTest(n,29) and
            millerRabinTest(n,31) and
            millerRabinTest(n,37);
  end;

FUNCTION isPrime(CONST B:T_bigInt):boolean;
  FUNCTION isComposite:boolean;
    VAR x:int64=1;
        y:int64=2*3*5*7*11*13*17*19*23*29*31*37*41*43*47;
        z:int64=1;
    begin
      x:=B mod y;
      z:=y;
      y:=x;
      while (y<>0) do begin x:=z mod y; z:=y; y:=x; end;
      result:=z>1;
    end;

  FUNCTION bigMillerRabinTest(CONST n:T_bigInt; CONST a:int64):boolean;
    VAR n1,d,t,tmp:T_bigInt;
        j:longint=1;
        k:longint;
    begin
      n1:=n.minus(1);
      d.create(n);
      d.shiftRightOneBit;
      while not(d.isOdd) do begin
        d.shiftRightOneBit;
        inc(j);
      end;
      tmp.fromInt(a); t:=tmp.powMod(d,n);
      if (t.compare(1)=CR_EQUAL) or (t.compare(n1)=CR_EQUAL) then exit(true);
      for k:=1 to j-1 do begin
        tmp:=t*t;
        t:=tmp.modulus(n);
        if (t.compare(n1)=CR_EQUAL) then begin
          exit(true);
        end;
        if (t.compare(1) in [CR_EQUAL,CR_LESSER]) then break;
      end;
      result:=false;
    end;

  CONST
    pr_79Bit:array[0..12] of byte=(2,3,5,7,11,13,17,19,23,29,31,37,41);
    pr:array[0..53] of byte=(2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251);
  VAR a:byte;
  begin
    if B.isNegative then exit(false);
    if B.canBeRepresentedAsInt64(false) then exit(isPrime(B.toInt));
    if (B.compare(1) in [CR_EQUAL,CR_LESSER]) or isComposite then exit(false);
    if B.relevantBits<79 then begin for a in pr_79Bit do if not(bigMillerRabinTest(B,a)) then exit(false) end
    else                      begin for a in pr       do if not(bigMillerRabinTest(B,a)) then exit(false) end;
    result:=true;
  end;

end.
