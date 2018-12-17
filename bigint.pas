UNIT bigint;
INTERFACE
USES sysutils,
     math,
     myGenerics,
     serializationUtil;
TYPE
  digitType=dword;
  carryType=qword;
  pDigitType=^digitType;
CONST
  BITS_PER_DIGIT=32;
  DIGIT_MAX_VALUE=(1 shl BITS_PER_DIGIT)-1;
  UPPER_DIGIT_BIT=1 shl (BITS_PER_DIGIT-1);
  WORD_BIT:array[0..BITS_PER_DIGIT-1] of digitType=
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
      digitCount:longint;
      digits:pDigitType;
      CONSTRUCTOR createFromRawData(CONST negative_:boolean; CONST digitCount_:longint; CONST digits_:pDigitType);
      PROCEDURE nullBits(CONST numberOfBitsToKeep:longint);

      PROCEDURE shlInc(CONST incFirstBit:boolean);
      FUNCTION relevantBits:longint;
      PROCEDURE setBit(CONST index:longint; CONST value:boolean);
      FUNCTION compareAbsValue(CONST big:T_bigInt):T_comparisonResult; inline;
      FUNCTION compareAbsValue(CONST int:int64):T_comparisonResult; inline;

      PROCEDURE multWith(CONST l:longint);
      PROCEDURE multWith(CONST b:T_bigInt);
      PROCEDURE divBy(CONST divisor:digitType; OUT rest:digitType);
      PROCEDURE incAbsValue(CONST positiveIncrement:dword);
      PROCEDURE shiftRightOneBit;
    public
      PROCEDURE shiftRight(CONST rightShift:longint);
      PROPERTY isNegative:boolean read negative;

      CONSTRUCTOR createZero;
      CONSTRUCTOR create(CONST negativeNumber:boolean; CONST digitCount_:longint);
      CONSTRUCTOR fromInt(CONST i:int64);
      CONSTRUCTOR fromString(CONST s:string);
      CONSTRUCTOR fromFloat(CONST f:extended; CONST rounding:T_roundingMode);
      CONSTRUCTOR create(CONST toClone:T_bigInt);
      CONSTRUCTOR createFromDigits(CONST base:longint; CONST digits_:T_arrayOfLongint);
      DESTRUCTOR destroy;

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
      FUNCTION plus (CONST big:T_bigInt):T_bigInt;
      FUNCTION minus(CONST big:T_bigInt):T_bigInt;
      FUNCTION minus(CONST small:digitType):T_bigInt;
      FUNCTION mult (CONST big:T_bigInt):T_bigInt;
      FUNCTION pow  (power:dword ):T_bigInt;
      FUNCTION powMod(CONST power,modul:T_bigInt):T_bigInt;
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
      FUNCTION divideIfRestless(CONST divisor:digitType):boolean;

      PROCEDURE writeToStream(CONST stream:P_outputStreamWrapper);
      CONSTRUCTOR readFromStream(CONST stream:P_inputStreamWrapper);
      CONSTRUCTOR readFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper);
      FUNCTION lowDigit:digitType;
      FUNCTION sign:shortint;
      FUNCTION greatestCommonDivider(CONST other:T_bigInt):T_bigInt;
      FUNCTION greatestCommonDivider(CONST other:int64):int64;
      FUNCTION modularInverse(CONST modul:T_bigInt; OUT thereIsAModularInverse:boolean):T_bigInt;
      FUNCTION iSqrt(OUT isSquare:boolean):T_bigInt;
      FUNCTION iLog2(OUT isPowerOfTwo:boolean):longint;
      FUNCTION hammingWeight:longint;
      FUNCTION getRawBytes:T_arrayOfByte;
    end;

  {Can handle up to 1024bit integers - used mainly for internal purposes}
  T_fixedSizeNonnegativeInt=object
    private
      digitCount:longint;
      digits:array[0..31] of digitType;
    public
    FUNCTION isOdd:boolean;
    PROCEDURE shiftRightOneBit;
    PROCEDURE shlInc(CONST incFirstBit:boolean);
    FUNCTION relevantBits:longint;
    PROCEDURE setBit(CONST index:longint; CONST value:boolean);
    FUNCTION getBit(CONST index:longint):boolean;
    PROCEDURE shiftRight(CONST rightShift:longint);

    FUNCTION plus (CONST fixed:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
    FUNCTION minus(CONST fixed:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
    FUNCTION mult (CONST fixed:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
    FUNCTION divMod(CONST divisor:T_fixedSizeNonnegativeInt; OUT quotient,rest:T_fixedSizeNonnegativeInt):boolean;
    FUNCTION powMod(CONST power,modul:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
    FUNCTION iSqrt(CONST computeEvenIfNotSquare:boolean; OUT isSquare:boolean):T_fixedSizeNonnegativeInt;
    FUNCTION greatestCommonDivider(CONST other:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;

    FUNCTION toString:string;
    FUNCTION toFloat:extended;
    FUNCTION toNewBigInt:T_bigInt;
  end;

  T_arrayOfBigint=array of T_bigInt;
  T_factorizationResult=record
    smallFactors:T_arrayOfLongint;
    bigFactors:T_arrayOfBigint;
  end;

FUNCTION randomInt(CONST randomSource:F_rand32Source        ; CONST maxValExclusive:T_bigInt):T_bigInt;
FUNCTION randomInt(CONST randomSource:F_rand32SourceOfObject; CONST maxValExclusive:T_bigInt):T_bigInt;
FUNCTION factorizeSmall(n:longint):T_arrayOfLongint;
FUNCTION factorize(CONST B:T_bigInt):T_factorizationResult;
FUNCTION isPrime(CONST n:longint ):boolean;
FUNCTION isPrime(CONST n:T_fixedSizeNonnegativeInt):boolean;
FUNCTION bigDigits(CONST value,base:T_bigInt):T_arrayOfBigint;
FUNCTION newFromBigDigits(CONST digits:T_arrayOfBigint; CONST base:T_bigInt):T_bigInt;
{For compatibility with constructor T_bigInt.readFromStream}
FUNCTION readLongintFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper):longint;
PROCEDURE writeLongintToStream(CONST value:longint; CONST stream:P_outputStreamWrapper);

FUNCTION plus   (CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION minus  (CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION minus  (CONST x:int64; CONST y:T_bigInt):T_bigInt;
FUNCTION mult   (CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION divide (CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION divide (CONST x:int64; CONST y:T_bigInt):T_bigInt;
FUNCTION modulus(CONST x:T_bigInt; CONST y:int64):T_bigInt;
FUNCTION modulus(CONST x:int64; CONST y:T_bigInt):T_bigInt;

OPERATOR :=(CONST x:T_bigInt):T_fixedSizeNonnegativeInt;
OPERATOR :=(CONST x:int64):T_fixedSizeNonnegativeInt;
OPERATOR :=(CONST x:T_fixedSizeNonnegativeInt):int64;
OPERATOR =(CONST x,y:T_fixedSizeNonnegativeInt):boolean;
OPERATOR =(CONST x:T_fixedSizeNonnegativeInt; CONST y:int64):boolean;
OPERATOR >=(CONST x,y:T_fixedSizeNonnegativeInt):boolean;
OPERATOR >=(CONST x:T_fixedSizeNonnegativeInt; CONST y:int64):boolean;
OPERATOR <=(CONST x,y:T_fixedSizeNonnegativeInt):boolean;
OPERATOR <=(CONST x:T_fixedSizeNonnegativeInt; CONST y:int64):boolean;
OPERATOR <=(CONST x:T_fixedSizeNonnegativeInt; CONST y:double):boolean;
OPERATOR +(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
OPERATOR -(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
OPERATOR *(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
OPERATOR div(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
OPERATOR mod(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
FUNCTION floatToFixedSizeNonnegativeInt(CONST f:double; CONST rounding:T_roundingMode):T_fixedSizeNonnegativeInt;

IMPLEMENTATION
OPERATOR :=(CONST x:T_bigInt):T_fixedSizeNonnegativeInt;
  VAR i:longint;
  begin
    if (x.negative) or (x.digitCount>length(result.digits)) then raise Exception.create('Cannot cast to T_fixedSizeNonnegativeInt');
    for i:=0 to length(result.digits)-1 do result.digits[i]:=0;
    move(x.digits^,result.digits,x.digitCount*(BITS_PER_DIGIT shr 3));
    result.digitCount:=x.digitCount;
  end;

OPERATOR :=(CONST x:int64):T_fixedSizeNonnegativeInt;
  VAR i:longint;
  begin
    for i:=2 to length(result.digits)-1 do result.digits[i]:=0;
    result.digits[0]:=(x                     ) and DIGIT_MAX_VALUE;
    result.digits[1]:=(x shr (BITS_PER_DIGIT)) and DIGIT_MAX_VALUE;
    if result.digits[1]>0 then result.digitCount:=2 else
    if result.digits[0]>0 then result.digitCount:=1
                          else result.digitCount:=0;
  end;

OPERATOR :=(CONST x:T_fixedSizeNonnegativeInt):int64;
  begin
    result:=x.digits[0]+(int64(x.digits[1]) shl BITS_PER_DIGIT);
  end;

OPERATOR=(CONST x, y: T_fixedSizeNonnegativeInt): boolean;
  VAR k:longint;
  begin
    result:=x.digitCount=y.digitCount;
    for k:=0 to max(x.digitCount,y.digitCount)-1 do result:=result and (x.digits[k]=y.digits[k]);
  end;

OPERATOR=(CONST x: T_fixedSizeNonnegativeInt; CONST y: int64): boolean;
  begin
    if y<0 then exit(false);
    if x.digitCount>2 then exit(false);
    result:=(x.digits[0]=(y                     ) and DIGIT_MAX_VALUE) and
            (x.digits[1]=(y shr (BITS_PER_DIGIT)) and DIGIT_MAX_VALUE);
  end;

OPERATOR>=(CONST x, y: T_fixedSizeNonnegativeInt): boolean;
  VAR k:longint;
  begin
    for k:=max(x.digitCount,y.digitCount)-1 downto 0 do
    if      x.digits[k]>y.digits[k] then exit(true)
    else if x.digits[k]<y.digits[k] then exit(false);
    result:=true;
  end;

OPERATOR>=(CONST x: T_fixedSizeNonnegativeInt; CONST y: int64): boolean;
  VAR k:longint;
      d:digitType;
  begin
    if y<0 then exit(true);
    for k:=length(x.digits)-1 downto 2 do if x.digits[k]>0 then exit(true);
    d:=(y shr BITS_PER_DIGIT) and DIGIT_MAX_VALUE;
    if x.digits[1]>d then exit(true) else if x.digits[1]<d then exit(false);
    result:=x.digits[0]>=(y and DIGIT_MAX_VALUE);
  end;

OPERATOR<=(CONST x, y: T_fixedSizeNonnegativeInt): boolean;
  VAR k:longint;
  begin
    for k:=max(x.digitCount,y.digitCount)-1 downto 0 do
    if      x.digits[k]<y.digits[k] then exit(true)
    else if x.digits[k]>y.digits[k] then exit(false);
    result:=true;
  end;

OPERATOR<=(CONST x: T_fixedSizeNonnegativeInt; CONST y: int64): boolean;
  VAR d:digitType;
  begin
    if y<0 then exit(false);
    if x.digitCount>2 then exit(false);
    d:=(y shr BITS_PER_DIGIT) and DIGIT_MAX_VALUE;
    if x.digits[1]<d then exit(true) else if x.digits[1]>d then exit(false);
    result:=x.digits[0]<=(y and DIGIT_MAX_VALUE);
  end;

OPERATOR <=(CONST x:T_fixedSizeNonnegativeInt; CONST y:double):boolean;
  begin
    result:=x.toFloat<=y;
  end;

OPERATOR+(CONST x, y: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt; begin result:=x.plus(y); end;
OPERATOR-(CONST x, y: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt; begin result:=x.minus(y); end;
OPERATOR*(CONST x, y: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt; begin result:=x.mult(y); end;
OPERATOR div(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt; VAR dummy:T_fixedSizeNonnegativeInt; begin x.divMod(y,result,dummy); end;
OPERATOR mod(CONST x,y:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt; VAR dummy:T_fixedSizeNonnegativeInt; begin x.divMod(y,dummy,result); end;

FUNCTION floatToFixedSizeNonnegativeInt(CONST f:double; CONST rounding:T_roundingMode):T_fixedSizeNonnegativeInt;
  VAR big:T_bigInt;
      k:longint;
  begin
    if isNan(f) or isInfinite(f) or (f<0) then exit(0);
    big.fromFloat(f,rounding);
    if big.digitCount>length(result.digits)
    then result:=0
    else begin
      result.digitCount:=big.digitCount;
      for k:=0 to length(result.digits)-1 do result.digits[k]:=0;
      move(big.digits^,result.digits,result.digitCount*(BITS_PER_DIGIT shr 3));
    end;
  end;

FUNCTION randomInt(CONST randomSource:F_rand32Source; CONST maxValExclusive:T_bigInt):T_bigInt;
  VAR k:longint;
      temp:T_bigInt;
  begin
    if maxValExclusive.isZero then begin
      result.createZero;
      exit;
    end;
    temp.create(false,maxValExclusive.digitCount);
    for k:=0 to temp.digitCount-1 do temp.digits[k]:=randomSource();
    result:=temp.modulus(maxValExclusive);
    temp.destroy;
  end;

FUNCTION randomInt(CONST randomSource:F_rand32SourceOfObject; CONST maxValExclusive:T_bigInt):T_bigInt;
  VAR k:longint;
      temp:T_bigInt;
  begin
    if maxValExclusive.isZero then begin
      result.createZero;
      exit;
    end;
    temp.create(false,maxValExclusive.digitCount);
    for k:=0 to temp.digitCount-1 do temp.digits[k]:=randomSource();
    result:=temp.modulus(maxValExclusive);
    temp.destroy;
  end;

FUNCTION plus   (CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.plus(bigY);
    bigY.destroy;
  end;

FUNCTION minus  (CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.minus(bigY);
    bigY.destroy;
  end;

FUNCTION minus  (CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    bigX.fromInt(x);
    result:=bigX.minus(y);
    bigX.destroy;
  end;

FUNCTION mult   (CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.mult(bigY);
    bigY.destroy;
  end;

FUNCTION divide (CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.divide(bigY);
    bigY.destroy;
  end;

FUNCTION divide (CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    bigX.fromInt(x);
    result:=bigX.divide(y);
    bigX.destroy;
  end;

FUNCTION modulus(CONST x:T_bigInt; CONST y:int64):T_bigInt;
  VAR bigY:T_bigInt;
  begin
    bigY.fromInt(y);
    result:=x.modulus(bigY);
    bigY.destroy;
  end;

FUNCTION modulus(CONST x:int64; CONST y:T_bigInt):T_bigInt;
  VAR bigX:T_bigInt;
  begin
    bigX.fromInt(x);
    result:=bigX.modulus(y);
    bigX.destroy;
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

FUNCTION T_fixedSizeNonnegativeInt.plus(CONST fixed: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt;
  VAR carry:carryType=0;
      i    :longint;
  begin
    result.digitCount:=0;
    for i:=0 to length(result.digits)-1 do begin
      carry+=carryType(digits[i])+carryType(fixed.digits[i]);
      result.digits[i]:=carry and DIGIT_MAX_VALUE;
      if result.digits[i]>0 then result.digitCount:=i+1;
      carry:=carry shr BITS_PER_DIGIT;
    end;
  end;

PROCEDURE trimLeadingZeros(VAR digitCount:longint; VAR digits:pDigitType); inline;
  VAR i:longint;
  begin
    i:=digitCount;
    while (i>0) and (digits[i-1]=0) do dec(i);
    if i<>digitCount then begin
      digitCount:=i;
      ReAllocMem(digits,sizeOf(digitType)*digitCount);
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
    trimLeadingZeros(diffDigitCount,diffDigits);
  end;

FUNCTION T_fixedSizeNonnegativeInt.minus(CONST fixed: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt;
  VAR carry:carryType=0;
      i    :longint;
  begin
    result.digitCount:=0;
    for i:=0 to length(result.digits)-1 do begin
      carry+=fixed.digits[i];
      if carry>digits[i] then begin
        result.digits[i]:=((DIGIT_MAX_VALUE+1)-carry+digits[i]) and DIGIT_MAX_VALUE;
        carry:=1;
      end else begin
        result.digits[i]:=digits[i]-carry;
        carry:=0;
      end;
      if result.digits[i]>0 then result.digitCount:=i+1;
    end;
  end;

FUNCTION T_fixedSizeNonnegativeInt.isOdd: boolean;
  begin
    result:=odd(digits[0]);
  end;

CONSTRUCTOR T_bigInt.createFromRawData(CONST negative_: boolean; CONST digitCount_: longint; CONST digits_: pDigitType);
  begin
    negative  :=negative_ and (digitCount_>0); //no such thing as a negative zero
    digitCount:=digitCount_;
    digits    :=digits_;
  end;

PROCEDURE T_bigInt.nullBits(CONST numberOfBitsToKeep:longint);
  VAR i:longint;
  begin
    for i:=digitCount*BITS_PER_DIGIT-1 downto numberOfBitsToKeep do setBit(i,false);
  end;

PROCEDURE T_bigInt.shlInc(CONST incFirstBit: boolean);
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

PROCEDURE T_fixedSizeNonnegativeInt.shlInc(CONST incFirstBit:boolean);
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
    if nextCarry and (digitCount<length(digits)) then begin
      digits[digitCount]:=digits[digitCount]+1;
      inc(digitCount);
    end;
  end;

FUNCTION T_bigInt.relevantBits: longint;
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

FUNCTION T_fixedSizeNonnegativeInt.relevantBits:longint;
  VAR i:longint;
      k:longint;
  begin
    result:=0;
    for i:=length(digits)-1 downto 0 do if digits[i]>0 then begin;
      result:=BITS_PER_DIGIT*(i+1);
      for k:=BITS_PER_DIGIT-1 downto 0 do
        if digits[i]<WORD_BIT[k]
        then dec (result)
        else exit(result);
    end;
  end;

FUNCTION T_bigInt.getBit(CONST index: longint): boolean;
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    if digitIndex>=digitCount then exit(false);
    bitIndex  :=index mod BITS_PER_DIGIT;
    result:=(digits[digitIndex] and WORD_BIT[bitIndex])<>0;
  end;

FUNCTION T_fixedSizeNonnegativeInt.getBit(CONST index: longint): boolean;
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    bitIndex  :=index mod BITS_PER_DIGIT;
    result:=(digitIndex<length(digits)) and ((digits[digitIndex] and WORD_BIT[bitIndex])<>0);
  end;

PROCEDURE T_bigInt.setBit(CONST index: longint; CONST value: boolean);
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
      trimLeadingZeros(digitCount,digits);
    end;
  end;

PROCEDURE T_fixedSizeNonnegativeInt.setBit(CONST index: longint; CONST value: boolean);
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index div BITS_PER_DIGIT;
    bitIndex:=index and (BITS_PER_DIGIT-1);
    if digitIndex>=length(digits) then exit;
    if value then begin
      digits[digitIndex]:=digits[digitIndex] or      WORD_BIT[bitIndex];
      if digitIndex>=digitCount then digitCount:=digitIndex+1;
    end else begin
      digits[digitIndex]:=digits[digitIndex] and not(WORD_BIT[bitIndex]);
      if (digitIndex=digitCount-1) then while (digitCount>0) and (digits[digitCount-1]=0) do dec(digitCount);
    end;
  end;

CONSTRUCTOR T_bigInt.createZero;
  begin
    create(false,0);
  end;

CONSTRUCTOR T_bigInt.create(CONST negativeNumber: boolean; CONST digitCount_: longint);
  begin
    negative:=negativeNumber;
    digitCount:=digitCount_;
    getMem(digits,sizeOf(digitType)*digitCount);
  end;

CONSTRUCTOR T_bigInt.fromInt(CONST i: int64);
  VAR unsigned:int64;
      d0,d1:digitType;
  begin
    negative:=i<0;
    if negative
    then unsigned:=-i
    else unsigned:= i;
    d0:=(unsigned                       ) and DIGIT_MAX_VALUE;
    d1:=(unsigned shr (BITS_PER_DIGIT  )) and DIGIT_MAX_VALUE;
    digitCount:=2;
    if d1=0 then begin
      dec(digitCount);
      if d0=0 then dec(digitCount);
    end;
    getMem(digits,sizeOf(digitType)*digitCount);
    if digitCount>0 then digits[0]:=d0;
    if digitCount>1 then digits[1]:=d1;
  end;

CONSTRUCTOR T_bigInt.fromString(CONST s: string);
  CONST MAX_CHUNK_SIZE=9;
        CHUNK_FACTOR:array[1..MAX_CHUNK_SIZE] of longint=(10,100,1000,10000,100000,1000000,10000000,100000000,1000000000);
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

CONSTRUCTOR T_bigInt.fromFloat(CONST f: extended; CONST rounding: T_roundingMode);
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

CONSTRUCTOR T_bigInt.create(CONST toClone: T_bigInt);
  begin
    create(toClone.negative,toClone.digitCount);
    move(toClone.digits^,digits^,sizeOf(digitType)*digitCount);
  end;

CONSTRUCTOR T_bigInt.createFromDigits(CONST base: longint; CONST digits_:T_arrayOfLongint);
  VAR i:longint;
  begin
    createZero;
    for i:=0 to length(digits_)-1 do begin
      multWith(base);
      incAbsValue(digits_[i]);
    end;
  end;

FUNCTION newFromBigDigits(CONST digits:T_arrayOfBigint; CONST base:T_bigInt):T_bigInt;
  VAR i:longint;
      tmp:T_bigInt;
      allSmall:boolean;
      baseAsInt:longint;
  begin
    allSmall:=(base.canBeRepresentedAsInt32()) and not(base.negative);
    for i:=0 to length(digits)-1 do allSmall:=allSmall and (digits[i].digitCount<=1) and not(digits[i].negative);
    result.createZero;
    if allSmall then begin
      baseAsInt:=base.toInt;
      for i:=0 to length(digits)-1 do begin
        result.multWith(baseAsInt);
        if digits[i].digitCount>0 then result.incAbsValue(digits[i].digits[0]);
      end;
    end else begin
      for i:=0 to length(digits)-1 do begin
        tmp:=result.mult(base);
        result.destroy;
        result:=tmp.plus(digits[i]);
        tmp.destroy;
      end;
    end;
  end;

FUNCTION T_bigInt.toInt: int64;
  begin
    if digitCount>0 then begin
      result:=digits[0];
      if digitCount>1 then inc(result,int64(digits[1]) shl BITS_PER_DIGIT);
      if negative then result:=-result;
    end else result:=0;
  end;

FUNCTION T_bigInt.toFloat: extended;
  VAR k:longint;
  begin
    result:=0;
    for k:=digitCount-1 downto 0 do result:=result*(DIGIT_MAX_VALUE+1)+digits[k];
    if negative then result:=-result;
  end;

FUNCTION T_bigInt.canBeRepresentedAsInt64(CONST examineNicheCase: boolean): boolean;
  begin
    if digitCount*BITS_PER_DIGIT>64 then exit(false);
    if digitCount*BITS_PER_DIGIT<64 then exit(true);
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
    if digitCount*BITS_PER_DIGIT>62 then exit(false);
    if digitCount*BITS_PER_DIGIT<62 then exit(true);
    result:=digits[1] and UPPER_TWO_BITS=0;
  end;

FUNCTION T_bigInt.canBeRepresentedAsInt32(CONST examineNicheCase: boolean): boolean;
  begin
    if digitCount*BITS_PER_DIGIT>32 then exit(false);
    if digitCount*BITS_PER_DIGIT<32 then exit(true);
    if not(getBit(31)) then exit(true);
    if negative and examineNicheCase then begin
      //in this case we can still represent -(2^31), so there is one special case to consider:
      result:=(digits[0]=UPPER_DIGIT_BIT);
    end else
    result:=false;
  end;

DESTRUCTOR T_bigInt.destroy;
  begin
    freeMem(digits,sizeOf(digitType)*digitCount);
    digitCount:=0;
    negative:=false;
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
    if digitCount<big.digitCount then exit(CR_LESSER);
    if digitCount>big.digitCount then exit(CR_GREATER);
    //compare highest value digits first
    for i:=digitCount-1 downto 0 do begin
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

FUNCTION T_bigInt.compare(CONST f: extended): T_comparisonResult;
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
    end else if k<digitCount then begin
      if negative then exit(CR_LESSER)
                  else exit(CR_GREATER);
    end;
    for k:=digitCount-1 downto 0 do begin
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

FUNCTION T_bigInt.plus(CONST big: T_bigInt): T_bigInt;
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

FUNCTION T_bigInt.minus(CONST big: T_bigInt): T_bigInt;
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

FUNCTION T_bigInt.minus(CONST small:digitType):T_bigInt;
  VAR resultDigits:pDigitType;
      resultDigitCount:longint;
  begin
    if negative then begin
      //(-x)-y = -(x+y)
      //x-(-y) =   x+y
      rawDataPlus(digits,    digitCount,
              @small,1,
                  resultDigits,resultDigitCount);
      result.createFromRawData(negative,resultDigitCount,resultDigits);
    end else case compareAbsValue(small) of
      CR_EQUAL  : result.createZero;
      CR_LESSER : begin
        // x-y = -(y-x) //opposed sign as y
        rawDataMinus(@small,  1,
                         digits,      digitCount,
                   resultDigits,resultDigitCount);
        result.createFromRawData(true,resultDigitCount,resultDigits);
      end;
      CR_GREATER: begin
        rawDataMinus(digits,      digitCount,
                 @small,  1,
               resultDigits,resultDigitCount);
        result.createFromRawData(false,resultDigitCount,resultDigits);
      end;
    end;
  end;

FUNCTION T_bigInt.mult(CONST big: T_bigInt): T_bigInt;
  VAR resultDigits:pDigitType;
      resultDigitCount:longint;
      i,j,k:longint;
      carry:carryType=0;
  begin
    {$ifndef debugMode}
    if canBeRepresentedAsInt32() then begin
      if big.canBeRepresentedAsInt32()  then begin
        result.fromInt(toInt*big.toInt);
        exit(result);
      end else begin
        result.create(big);
        result.multWith(toInt);
        exit(result);
      end;
    end else if big.canBeRepresentedAsInt32() then begin
      result.create(self);
      result.multWith(big.toInt);
      exit(result);
    end;
    {$endif}
    resultDigitCount:=digitCount+big.digitCount;
    getMem(resultDigits,sizeOf(digitType)*resultDigitCount);
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

FUNCTION T_fixedSizeNonnegativeInt.mult(CONST fixed: T_fixedSizeNonnegativeInt): T_fixedSizeNonnegativeInt;
  VAR i,j,k:longint;
      carry:carryType=0;
  begin
    result.digitCount:=0;
    for k:=0 to length(result.digits)-1 do result.digits[k]:=0;
    for i:=0 to digitCount-1 do
    for j:=0 to min(fixed.digitCount,length(result.digits)-i)-1 do begin
      k:=i+j;
      carry:=carryType(digits[i])*carryType(fixed.digits[j]);
      while (carry>0) and (k<length(result.digits)) do begin
        carry+=result.digits[k];
        result.digits[k]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        result.digitCount:=k+1;
        inc(k);
      end;
    end;
    if (result.digitCount=1) and (result.digits[0]=0) then result.digitCount:=0;
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
      multiplicand.destroy;
    end;
  end;

FUNCTION T_bigInt.powMod(CONST power,modul:T_bigInt):T_bigInt;
  PROCEDURE doModulus(VAR inOut:T_bigInt);
    VAR temp:T_bigInt;
    begin
      if inOut.compareAbsValue(modul)=CR_LESSER then exit;
      temp:=inOut.modulus(modul);
      inOut.destroy;
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
    p.destroy;
    f.destroy;
  end;

FUNCTION T_fixedSizeNonnegativeInt.powMod(CONST power,modul:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
  VAR p,f:T_fixedSizeNonnegativeInt;
  begin
    if (power= 0) then exit(1);
    if (modul<=1) then exit(0);
    p:=power;
    f:=self mod modul;
    result:=1;
    while p<>0 do begin
      if p.isOdd then result:=result*f mod modul;
      f:=f*f mod modul;
      p.shiftRightOneBit;
    end;
  end;

FUNCTION T_fixedSizeNonnegativeInt.toString:string;
  VAR big:T_bigInt;
  begin
    big.createFromRawData(false,digitCount,@digits);
    result:=big.toString;
  end;

FUNCTION T_fixedSizeNonnegativeInt.toFloat:extended;
  VAR big:T_bigInt;
  begin
    big.createFromRawData(false,digitCount,@digits);
    result:=big.toFloat;
  end;

FUNCTION T_fixedSizeNonnegativeInt.toNewBigInt:T_bigInt;
  VAR big:T_bigInt;
  begin
    big.createFromRawData(false,digitCount,@digits);
    result.create(big);
    trimLeadingZeros(result.digitCount,result.digits);
  end;

FUNCTION T_bigInt.bitAnd(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=min(digitCount,big.digitCount);
    result.create(isNegative and big.isNegative,k);
    for i:=0 to result.digitCount-1 do result.digits[i]:=digits[i] and big.digits[i];
    trimLeadingZeros(result.digitCount,result.digits);
  end;

FUNCTION T_bigInt.bitOr(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=max(digitCount,big.digitCount);
    result.create(isNegative or big.isNegative,k);
    for i:=0 to result.digitCount-1 do begin
      if (i<    digitCount) then result.digits[i]:=digits[i]
                            else result.digits[i]:=0;
      if (i<big.digitCount) then result.digits[i]:=result.digits[i] or big.digits[i];
    end;
    trimLeadingZeros(result.digitCount,result.digits);
  end;

FUNCTION T_bigInt.bitXor(CONST big: T_bigInt): T_bigInt;
  VAR k,i:longint;
  begin
    k:=max(digitCount,big.digitCount);
    result.create(isNegative xor big.isNegative,k);
    for i:=0 to result.digitCount-1 do begin
      if (i<    digitCount) then result.digits[i]:=digits[i]
                            else result.digits[i]:=0;
      if (i<big.digitCount) then result.digits[i]:=result.digits[i] xor big.digits[i];
    end;
    trimLeadingZeros(result.digitCount,result.digits);
  end;

FUNCTION T_bigInt.bitAnd(CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitAnd(big); big.destroy; end;
FUNCTION T_bigInt.bitOr (CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitOr (big); big.destroy; end;
FUNCTION T_bigInt.bitXor(CONST small:int64): T_bigInt; VAR big:T_bigInt; begin big.fromInt(small); result:=bitXor(big); big.destroy; end;

FUNCTION T_bigInt.bitNegate(CONST consideredBits:longint):T_bigInt;
  VAR k,i:longint;
  begin
    if consideredBits<=0 then k:=relevantBits
                         else k:=consideredBits;
    result.create(false,digitCount);
    for i:=0 to min(digitCount,result.digitCount)-1 do result.digits[i]:=not(digits[i]);
    result.nullBits(k);
  end;

FUNCTION isPowerOf2(CONST i:digitType; OUT log2:longint):boolean; inline;
  VAR k:longint;
  begin
    result:=false;
    for k:=0 to length(WORD_BIT)-1 do if i=WORD_BIT[k] then begin
      log2:=k;
      exit(true);
    end;
  end;

PROCEDURE T_bigInt.multWith(CONST l: longint);
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
    if isPowerOf2(factor,k) then begin
      shiftRight(-k);
      exit;
    end;

    for k:=0 to digitCount-1 do begin
      carry+=carryType(factor)*carryType(digits[k]);
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

PROCEDURE T_bigInt.multWith(CONST b: T_bigInt);
  VAR temp:T_bigInt;
  begin
    temp:=mult(b);
    freeMem(digits,sizeOf(digitType)*digitCount);
    digitCount:=temp.digitCount;
    digits    :=temp.digits;
    negative  :=temp.negative;
  end;

PROCEDURE T_bigInt.incAbsValue(CONST positiveIncrement: dword);
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

FUNCTION T_bigInt.divMod(CONST divisor: T_bigInt; OUT quotient, rest: T_bigInt): boolean;
  PROCEDURE rawDec; inline;
    VAR carry:carryType=0;
        i    :longint;
    begin
      for i:=0 to divisor.digitCount-1 do begin
        carry+=divisor.digits[i];
        if carry>rest.digits[i] then begin
          rest.digits[i]:=((DIGIT_MAX_VALUE+1)-carry+rest.digits[i]) and DIGIT_MAX_VALUE;
          carry:=1;
        end else begin
          rest.digits[i]-=carry;
          carry:=0;
        end;
      end;
      for i:=divisor.digitCount to rest.digitCount-1 do begin
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
      if divisor.digitCount>rest.digitCount then exit(false);
      for i:=rest.digitCount-1 downto divisor.digitCount do if rest.digits[i]>0 then exit(true);
      for i:=divisor.digitCount-1 downto 0 do
        if       divisor.digits[i]<rest.digits[i] then exit(true)
        else if  divisor.digits[i]>rest.digits[i] then exit(false);
      result:=true;
    end;

  VAR bitIdx:longint;
      divIsPow2:boolean;
  begin
    if divisor.digitCount=0 then exit(false);
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
    rest    .create(negative,divisor.digitCount);
    //Initialize rest with (probably) enough digits
    for bitIdx:=0 to rest.digitCount-1 do rest.digits[bitIdx]:=0;
    for bitIdx:=relevantBits-1 downto 0 do begin
      rest.shlInc(getBit(bitIdx));
      if restGeqDivisor then begin
        rawDec();
        quotient.setBit(bitIdx,true);
      end;
    end;
    trimLeadingZeros(rest.digitCount,rest.digits);
  end;

FUNCTION T_fixedSizeNonnegativeInt.divMod(CONST divisor: T_fixedSizeNonnegativeInt; OUT quotient, rest: T_fixedSizeNonnegativeInt): boolean;
  VAR bitIdx:longint;
  begin
    quotient:=0;
    rest    :=0;
    if divisor=0 then exit(false);
    result:=true;
    for bitIdx:=relevantBits-1 downto 0 do begin
      rest.shlInc(getBit(bitIdx));
      if rest>=divisor then begin
        rest-=divisor;
        quotient.setBit(bitIdx,true);
      end;
    end;
  end;

FUNCTION T_bigInt.divide(CONST divisor: T_bigInt): T_bigInt;
  VAR temp:T_bigInt;
      {$ifndef debugMode} intRest:digitType; {$endif}
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
    temp.destroy;
  end;

FUNCTION T_bigInt.modulus(CONST divisor: T_bigInt): T_bigInt;
  VAR temp:T_bigInt;
      {$ifndef debugMode} intRest:digitType; {$endif}
  begin
    {$ifndef debugMode}
    if (canBeRepresentedAsInt64() and divisor.canBeRepresentedAsInt64()) then begin
      result.fromInt(toInt mod divisor.toInt);
      exit(result);
    end else if divisor.canBeRepresentedAsInt32(false) and not(divisor.negative) then begin
      temp.create(self);
      temp.divBy(divisor.toInt,intRest);
      temp.destroy;
      result.fromInt(intRest);
      exit(result);
    end;
    {$endif}
    divMod(divisor,temp,result);
    temp.destroy;
  end;

PROCEDURE T_bigInt.divBy(CONST divisor: digitType; OUT rest: digitType);
  VAR bitIdx:longint;
      quotient:T_bigInt;
      divisorLog2:longint;
      tempRest:carryType=0;
  begin
    if digitCount=0 then begin
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
      freeMem(digits,sizeOf(digitType)*digitCount);
      digits:=quotient.digits;
      digitCount:=quotient.digitCount;
      rest:=tempRest;
    end;
  end;

FUNCTION T_bigInt.divideIfRestless(CONST divisor:digitType):boolean;
  VAR bitIdx:longint;
      quotient:T_bigInt;
      tempRest:carryType=0;
  begin
    quotient.createZero;
    for bitIdx:=relevantBits-1 downto 0 do begin
      tempRest:=tempRest shl 1;
      if getBit(bitIdx) then inc(tempRest);
      if tempRest>=divisor then begin
        dec(tempRest,divisor);
        quotient.setBit(bitIdx,true);
      end;
    end;
    if tempRest=0 then begin;
      freeMem(digits,sizeOf(digitType)*digitCount);
      digits:=quotient.digits;
      digitCount:=quotient.digitCount;
      result:=true;
    end else begin
      quotient.destroy;
      result:=false;
    end;
  end;

FUNCTION T_bigInt.toString: string;
  VAR temp:T_bigInt;
      chunkVal:digitType;
      chunkTxt:string;
  begin
    if digitCount=0 then exit('0');
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
    temp.destroy;
  end;

FUNCTION T_bigInt.toHexString:string;
  CONST hexChar:array [0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
        shifts:array[0..7] of byte=(28,24,20,16,12,8,4,0);
  VAR hasADigit:boolean=false;
      digit :digitType;
      hexDig:byte;
      Shift :byte;
      i:longint;
  begin
    if digitCount=0 then exit('0');
    if negative then result:='-' else result:='';
    for i:=digitCount-1 downto 0 do begin
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
      digit:digitType;
      iTemp:int64;
      s:string;
      resLen:longint=0;
  begin
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
      temp.destroy;
    end;
  end;

FUNCTION bigDigits(CONST value,base:T_bigInt):T_arrayOfBigint;
  VAR temp,quotient,rest:T_bigInt;
      smallDigits:T_arrayOfLongint;
      k:longint;
      resSize:longint=0;
  begin
    if base.canBeRepresentedAsInt32 then begin
      smallDigits:=value.getDigits(base.toInt);
      setLength(result,length(smallDigits));
      for k:=0 to length(smallDigits)-1 do result[k].fromInt(smallDigits[k]);
      setLength(smallDigits,0);
    end else begin
      setLength(result,round(1+1.01*value.digitCount));
      temp.create(value);
      temp.negative:=false;
      while temp.compareAbsValue(1) in [CR_EQUAL,CR_GREATER] do begin
        temp.divMod(base,quotient,rest);
        result[resSize]:=rest; inc(resSize);
        temp.destroy;
        temp:=quotient;
      end;
      setLength(result,resSize);
      temp.destroy;
    end;
  end;

FUNCTION T_bigInt.equals(CONST b: T_bigInt): boolean;
  VAR k:longint;
  begin
    if (negative  <>b.negative) or
       (digitCount<>b.digitCount) then exit(false);
    for k:=0 to digitCount-1 do if (digits[k]<>b.digits[k]) then exit(false);
    result:=true;
  end;

FUNCTION T_bigInt.isZero: boolean;
  begin
    result:=digitCount=0;
  end;

FUNCTION T_bigInt.isOne: boolean;
  begin
    result:=(digitCount=1) and not(isNegative) and (digits[0]=1);
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
    for k:=0 to digitCount-1 do begin
      if (k>0) and odd(digits[k]) then digits[k-1]:=digits[k-1] or UPPER_DIGIT_BIT;
      digits[k]:=digits[k] shr 1;
    end;
    if (digitCount>0) and (digits[digitCount-1]=0) then begin
      dec(digitCount);
      ReAllocMem(digits,sizeOf(digitType)*digitCount);
    end;
  end;

PROCEDURE T_fixedSizeNonnegativeInt.shiftRightOneBit;
  VAR k:longint;
  begin
    for k:=0 to digitCount-1 do begin
      if (k>0) and odd(digits[k]) then digits[k-1]:=digits[k-1] or UPPER_DIGIT_BIT;
      digits[k]:=digits[k] shr 1;
    end;
    if (digitCount>0) and (digits[digitCount-1]=0) then dec(digitCount);
  end;

PROCEDURE T_bigInt.shiftRight(CONST rightShift:longint);
  VAR digitsToShift:longint;
      bitsToShift  :longint;
      newBitCount  :longint;
      newDigitCount:longint;
      carry,nextCarry:digitType;
      k:longint;
  begin
    if rightShift=0 then exit;
    bitsToShift  :=abs(rightShift);
    digitsToShift:=bitsToShift div BITS_PER_DIGIT;
    bitsToShift  -=digitsToShift * BITS_PER_DIGIT;
    if rightShift>0 then begin
      if rightShift>=relevantBits then begin
        digitCount:=0;
        ReAllocMem(digits,0);
        negative:=false;
        exit;
      end;
      if digitsToShift>0 then begin
        for k:=0 to digitCount-digitsToShift-1 do digits[k]:=digits[k+digitsToShift];
        for k:=digitCount-digitsToShift to digitCount-1 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=digitCount-digitsToShift-1 downto 0 do begin
          nextCarry:=digits[k];
          digits[k]:=(digits[k] shr bitsToShift) or (carry shl (BITS_PER_DIGIT-bitsToShift));
          carry:=nextCarry;
        end;
      end;
      trimLeadingZeros(digitCount,digits);
    end else begin
      newBitCount:=relevantBits-rightShift;
      newDigitCount:=newBitCount div BITS_PER_DIGIT; if newDigitCount*BITS_PER_DIGIT<newBitCount then inc(newDigitCount);
      if newDigitCount>digitCount then begin
        ReAllocMem(digits,newDigitCount*sizeOf(digitType));
        for k:=digitCount to newDigitCount-1 do digits[k]:=0;
        digitCount:=newDigitCount;
      end;
      if digitsToShift>0 then begin
        for k:=digitCount-1 downto digitsToShift do digits[k]:=digits[k-digitsToShift];
        for k:=digitsToShift-1 downto 0 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=0 to digitCount-1 do begin
          nextCarry:=digits[k] shr (BITS_PER_DIGIT-bitsToShift);
          digits[k]:=(digits[k] shl bitsToShift) or carry;
          carry:=nextCarry;
        end;
      end;
    end;
  end;

PROCEDURE T_fixedSizeNonnegativeInt.shiftRight(CONST rightShift:longint);
  VAR digitsToShift:longint;
      bitsToShift  :longint;
      newBitCount  :longint;
      newDigitCount:longint;
      carry,nextCarry:digitType;
      k:longint;
  begin
    if rightShift=0 then exit;
    bitsToShift  :=abs(rightShift);
    digitsToShift:=bitsToShift div BITS_PER_DIGIT;
    bitsToShift  -=digitsToShift * BITS_PER_DIGIT;
    if rightShift>0 then begin
      if digitsToShift>0 then begin
        for k:=0 to digitCount-digitsToShift-1 do digits[k]:=digits[k+digitsToShift];
        for k:=digitCount-digitsToShift to digitCount-1 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=digitCount-digitsToShift-1 downto 0 do begin
          nextCarry:=digits[k];
          digits[k]:=(digits[k] shr bitsToShift) or (carry shl (BITS_PER_DIGIT-bitsToShift));
          carry:=nextCarry;
        end;
      end;
      while (digitCount>0) and (digits[digitCount-1]=0) do dec(digitCount);
    end else begin
      newBitCount:=relevantBits-rightShift;
      newDigitCount:=newBitCount div BITS_PER_DIGIT; if newDigitCount*BITS_PER_DIGIT<newBitCount then inc(newDigitCount);
      digitCount:=newDigitCount;
      if digitsToShift>0 then begin
        for k:=digitCount-1 downto digitsToShift do digits[k]:=digits[k-digitsToShift];
        for k:=digitsToShift-1 downto 0 do digits[k]:=0;
      end;
      if bitsToShift>0 then begin
        carry:=0;
        for k:=0 to digitCount-1 do begin
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
      stream^.writeLongint(digitCount); //number of following Dwords
      for k:=0 to digitCount-1 do stream^.writeDWord(digits[k]);
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

CONSTRUCTOR T_bigInt.readFromStream(CONST markerByte:byte; CONST stream:P_inputStreamWrapper);
  VAR k:longint;
  begin
    case markerByte of
      254,255: begin
        negative:=odd(markerByte);
        digitCount:=stream^.readLongint;
        getMem(digits,sizeOf(digitType)*digitCount);
        for k:=0 to digitCount-1 do digits[k]:=stream^.readDWord;
      end;
      253: fromInt(stream^.readInt64);
      252: fromInt(stream^.readLongint);
      251: fromInt(stream^.readSmallInt);
      250: fromInt(stream^.readShortint);
      else fromInt(markerByte);
    end;
  end;

CONSTRUCTOR T_bigInt.readFromStream(CONST stream: P_inputStreamWrapper);
  begin
    readFromStream(stream^.readByte,stream);
  end;

FUNCTION T_bigInt.lowDigit: digitType;
  begin
    if digitCount=0 then exit(0) else exit(digits[0]);
  end;

FUNCTION T_bigInt.sign: shortint;
  begin
    if digitCount=0 then exit(0) else if negative then exit(-1) else exit(1);;
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
        result.destroy;
        result:=b;
        b:=temp;
      end;
      b.destroy;
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
      tempO.destroy;
      result:=tempR.toInt;
      tempR.destroy;
    end;
  end;

FUNCTION T_fixedSizeNonnegativeInt.greatestCommonDivider(CONST other:T_fixedSizeNonnegativeInt):T_fixedSizeNonnegativeInt;
  VAR b,temp:T_fixedSizeNonnegativeInt;
  begin
    result:=self;
    b:=other;
    while not(b=0) do begin
      temp:=result mod b;
      result:=b;
      b:=temp;
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
      while not(r1.isZero) do begin
        r0.divMod(r1,quotient,rest);
        r0.destroy; r0:=r1; r1:=rest;
        rest:=quotient.mult(t1); quotient.destroy; quotient:=t0.minus(rest); rest.destroy;
        t0.destroy; t0:=t1; t1:=quotient;
      end;
      thereIsAModularInverse:=r0.compare(1) in [CR_LESSER,CR_EQUAL];
      r0.destroy;
      r1.destroy;
      t1.destroy;
      if (t0.isNegative) then begin
        result:=t0.plus(modul);
        t0.destroy;
      end else  result:=t0;
    end;
  end;
CONST SQUARE_LOW_BYTE_VALUES:set of byte=[0,1,4,9,16,17,25,33,36,41,49,57,64,65,68,73,81,89,97,100,105,113,121,129,132,137,144,145,153,161,164,169,177,185,193,196,201,209,217,225,228,233,241,249];

FUNCTION T_bigInt.iSqrt(OUT isSquare:boolean):T_bigInt;
  VAR resDt,temp:T_bigInt;
      done:boolean=false;
      step:longint=0;
      selfShl16:T_bigInt;
      {$ifndef debugMode}intRoot:int64;{$endif}
      floatSqrt:double;
  begin
    if negative or isZero then begin
      isSquare:=digitCount=0;
      result.createZero;
      exit(result);
    end;
    if not((digits[0] and 255) in SQUARE_LOW_BYTE_VALUES) then begin
      isSquare:=false;
      result.createZero;
      exit;
    end;
    {$ifndef debugMode}
    if canBeRepresentedAsInt64 then begin
      intRoot:=trunc(sqrt(toFloat));
      result.fromInt(intRoot);
      isSquare:=toInt=intRoot*intRoot;
      exit;
    end else if relevantBits<102 then begin
      result.fromFloat(sqrt(toFloat),RM_DOWN);
      temp:=result.mult(result);
      isSquare:=equals(temp);
      temp.destroy;
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
      selfShl16.divMod(result,resDt,temp);
      isSquare:=temp.isZero;
      temp.destroy;
      temp:=resDt.plus(result); resDt.destroy;
      isSquare:=isSquare and not odd(temp.digits[0]);
      temp.shiftRightOneBit;
      done:=result.equals(temp);
      result.destroy;
      result:=temp;
      inc(step);
    until done or (step>100);

    selfShl16.destroy;
    isSquare:=isSquare and ((result.digits[0] and 255)=0);
    if isSquare then result.shiftRight(8)
                else begin
                  result.digitCount:=0;
                  ReAllocMem(result.digits,0);
                end;
  end;

FUNCTION T_fixedSizeNonnegativeInt.iSqrt(CONST computeEvenIfNotSquare:boolean; OUT isSquare:boolean):T_fixedSizeNonnegativeInt;
  VAR resDt,temp:T_fixedSizeNonnegativeInt;
      done:boolean=false;
      step:longint=0;
      selfShl16:T_fixedSizeNonnegativeInt;
      {$ifndef debugMode}intRoot:int64;{$endif}
  begin
    if self=0 then begin
      isSquare:=true;
      result:=0;
      exit(result);
    end;
    {$ifndef debugMode}
    if self<=9223372036854775807 then begin
      intRoot:=trunc(sqrt(toFloat));
      result:=intRoot;
      isSquare:=self=intRoot*intRoot;
      exit;
    end;
    {$endif}
    if not((digits[0] and 255) in SQUARE_LOW_BYTE_VALUES) then begin
      isSquare:=false;
      if not(computeEvenIfNotSquare) then exit(0);
    end;
    //compute the square root of this*2^16, validate by checking lower 8 bits
    //find most significant digit:
    step:=digitCount-1;
    try
      result:=round(sqrt(toFloat)*256);
    except
      //n           =      2^dc  *      x
      //sqrt(n)*256 = sqrt(2^dc) * sqrt(x) *256
      //            = 2^(dc/2+8) * sqrt(x);
      result:=round(sqrt(digits[digitCount-1]));
      result.shiftRight(8-digitCount*(BITS_PER_DIGIT div 2));
    end;
    selfShl16:=self;
    selfShl16.shiftRight(-16);
    step:=0;
    repeat
      selfShl16.divMod(result,resDt,temp);
      isSquare:=temp=0;
      temp:=resDt+result;
      isSquare:=isSquare and not odd(temp.digits[0]);
      temp.shiftRightOneBit;
      done:=result=temp;
      result:=temp;
      inc(step);
    until done or (step>100);

    isSquare:=isSquare and ((result.digits[0] and 255)=0);
    if isSquare or computeEvenIfNotSquare then result.shiftRight(8);
  end;

FUNCTION T_bigInt.iLog2(OUT isPowerOfTwo:boolean):longint;
  VAR i:longint;
  begin
    isPowerOfTwo:=false;
    if digitCount=0 then exit(0);
    i:=digitCount-1;
    if isPowerOf2(digits[digitCount-1],result) then begin
      inc(result,BITS_PER_DIGIT*(digitCount-1));
      isPowerOfTwo:=true;
      for i:=digitCount-2 downto 0 do isPowerOfTwo:=isPowerOfTwo and (digits[i]=0);
    end else result:=0;
  end;

FUNCTION T_bigInt.hammingWeight:longint;
  VAR i:longint;
  begin
    result:=0;
    for i:=0 to digitCount*BITS_PER_DIGIT-1 do if getBit(i) then inc(result);
  end;

FUNCTION T_bigInt.getRawBytes: T_arrayOfByte;
  VAR i:longint;
      tmp:dword=0;
  begin
    i:=relevantBits shr 3;
    if i*8<relevantBits then inc(i);
    setLength(result,i);
    for i:=0 to length(result)-1 do begin
      if i and 3=0 then tmp:=digits[i shr 2]
                   else tmp:=tmp shr 8;
      result[i]:=tmp and 255;
    end;
  end;

CONST primes:array[0..144] of word=(3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,839);
CONST skip:array[0..47] of byte=(10,2,4,2,4,6,2,6,4,2,4,6,6,2,6,4,2,6,4,6,8,4,2,4,2,4,8,6,4,6,2,4,6,2,6,6,4,2,4,6,2,6,4,2,4,2,10,2);
FUNCTION factorizeSmall(n:longint):T_arrayOfLongint;
  VAR p:longint;
      skipIdx:longint=0;
  begin
    setLength(result,0);
    if n<0 then begin
      n:=-n;
      append(result,-1);
      if n=1 then exit(result);
    end;
    if n=1 then begin
      append(result,1);
      exit(result);
    end;
    while (n>0) and not(odd(n)) do begin
      n:=n shr 1;
      append(result,2);
    end;
    for p in primes do begin
      if (int64(p)*p>n) then begin
        if n>1 then append(result,n);
        exit;
      end;
      while n mod p=0 do begin
        n:=n div p;
        append(result,p);
      end;
    end;
    p:=primes[length(primes)-1]+skip[length(skip)-1]; //=841
    while int64(p)*p<=n do begin
      while n mod p=0 do begin
        n:=n div p;
        append(result,p);
      end;
      inc(p,skip[skipIdx]);
      skipIdx:=(skipIdx+1) mod length(skip);
    end;
    if n>1 then append(result,n);
  end;

FUNCTION factorize(CONST B:T_bigInt):T_factorizationResult;
  FUNCTION basicFactorize(VAR inputAndRest:T_fixedSizeNonnegativeInt; OUT furtherFactorsPossible:boolean):T_factorizationResult;
    VAR workInInt64:boolean=false;
        n:int64=9223358842721533952; //to simplify conditions
    FUNCTION trySwitchToInt64:boolean; inline;
      begin
        if workInInt64 then exit(true);
        if inputAndRest.relevantBits<63 then begin
          n:=inputAndRest;
          workInInt64:=true;
        end;
        result:=workInInt64;
      end;

    FUNCTION longDivideIfRestless(CONST divider:T_fixedSizeNonnegativeInt):boolean;
      VAR quotient,rest:T_fixedSizeNonnegativeInt;
      begin
        inputAndRest.divMod(divider,quotient,rest);
        if rest=0 then begin
          result:=true;
          inputAndRest:=quotient;
        end else begin
          result:=false;
        end;
      end;

    VAR p:longint;
        bigP:T_fixedSizeNonnegativeInt;
        skipIdx:longint=0;
        thirdRootOfInputAndRest:double;
    begin
      furtherFactorsPossible:=true;
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
          inputAndRest:=n;
          furtherFactorsPossible:=false;
          exit;
        end;
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
          end;
        end else begin
          while longDivideIfRestless(p) do append(result.smallFactors,p);
        end;
      end;
      //By skipping:
      p:=primes[length(primes)-1]+skip[length(skip)-1]; //=841
      while p<2097151 do begin
        if workInInt64 and ((int64(p)*p*p>n)) then begin
          inputAndRest:=n;
          furtherFactorsPossible:=int64(p)*p<=n;
          exit;
        end;
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
          end;
        end else begin
          while longDivideIfRestless(p) do append(result.smallFactors,p);
        end;
        inc(p,skip[skipIdx]);
        skipIdx:=(skipIdx+1) mod length(skip);
      end;
      if     workInInt64  and isPrime(n) then begin inputAndRest:=n; furtherFactorsPossible:=false; exit(result); end;
      if not(workInInt64) and isPrime(inputAndRest)  then begin      furtherFactorsPossible:=false; exit(result); end;
      thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
      while (p<maxLongint-10) and (p<thirdRootOfInputAndRest) do begin
        if trySwitchToInt64 then begin
          while n mod p=0 do begin
            n:=n div p;
            append(result.smallFactors,p);
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
        end else begin
          while longDivideIfRestless(p) do begin
            append(result.smallFactors,p);
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
        end;
        inc(p,skip[skipIdx]);
        skipIdx:=(skipIdx+1) mod length(skip);
      end;
      if workInInt64 then begin
        inputAndRest:=n;
        workInInt64:=false;
      end;
      if p<thirdRootOfInputAndRest then begin
        bigP:=p;
        while (bigP<=thirdRootOfInputAndRest) do begin
          while longDivideIfRestless(bigP) do begin
            setLength(result.bigFactors,length(result.bigFactors)+1);
            result.bigFactors[length(result.bigFactors)-1]:=bigP.toNewBigInt;
            thirdRootOfInputAndRest:=power(inputAndRest.toFloat,1/3);
          end;
          bigP+=skip[skipIdx];
          skipIdx:=(skipIdx+1) mod length(skip);
        end;
      end;
    end;

  VAR bigFourKN:T_fixedSizeNonnegativeInt;
  FUNCTION squareOfMinus4kn(CONST z:int64):T_fixedSizeNonnegativeInt;
    begin
      result:=T_fixedSizeNonnegativeInt(z);
      result*=result;
      result-=bigFourKN;
    end;

  PROCEDURE myInc(VAR y:T_bigInt; CONST increment:int64);
    VAR temp1,temp2:T_bigInt;
    begin
      if increment<DIGIT_MAX_VALUE then y.incAbsValue(increment)
      else begin
        temp1.fromInt(increment);
        temp2:=temp1.plus(y);
        temp1.destroy;
        y.destroy;
        y:=temp2;
      end;
    end;

  FUNCTION smallGcd(x,y:int64):int64;
    begin
      result:=x;
      while (y<>0) do begin
        x:=result mod y; result:=y; y:=x;
      end;
    end;

  FUNCTION floor64(CONST d:double):int64; begin result:=trunc(d); if frac(d)<0 then dec(result); end;
  FUNCTION ceil64 (CONST d:double):int64; begin result:=trunc(d); if frac(d)>0 then inc(result); end;

  VAR r:T_fixedSizeNonnegativeInt;
      sixthRootOfR:double;

      furtherFactorsPossible:boolean;
      temp:double;

      k,kMax:int64;
      x,xMax:int64;
      bigX,bigXMax:T_fixedSizeNonnegativeInt;

      bigY:T_fixedSizeNonnegativeInt;
      bigRootOfY:T_fixedSizeNonnegativeInt;
      yIsSquare:boolean;
      lehmannTestCompleted:boolean=false;
  begin
    setLength(result.bigFactors,0);
    if B.isZero or (B.compareAbsValue(1)=CR_EQUAL) then begin
      setLength(result.smallFactors,1);
      result.smallFactors[0]:=B.toInt;
      exit;
    end;
    r:=B;
    if B.isNegative then append(result.smallFactors,-1);

    if r.relevantBits<=31 then begin
      result.smallFactors:=factorizeSmall(int64(r));
      exit;
    end else begin
      if isPrime(r) then begin
        setLength(result.bigFactors,1);
        result.bigFactors[0]:=r.toNewBigInt;
        exit(result);
      end;
      result:=basicFactorize(r,furtherFactorsPossible);
      if not(furtherFactorsPossible) then begin
        if not(r<=1) then begin
          setLength(result.bigFactors,length(result.bigFactors)+1);
          result.bigFactors[length(result.bigFactors)-1]:=r.toNewBigInt;
        end;
        exit;
      end;
    end;

    sixthRootOfR:=power(r.toFloat,1/6);
    temp:=power(r.toFloat,1/3);
    if temp<9223372036854774000
    then kMax:=trunc(temp)
    else kMax:=9223372036854774000;
    k:=1;
    if not(isPrime(r)) then while (k<=kMax) and not(lehmannTestCompleted) do begin
      bigFourKN:=r*k;
      bigFourKN.shlInc(false);
      bigFourKN.shlInc(false);
      if r<=59172824724903 then begin
        temp:=sqrt(bigFourKN.toFloat);
        x:=ceil64(temp); //<= 4*r^(4/3) < 2^63 ->  r < 2^(61*3/4) = 59172824724903
        while not(T_fixedSizeNonnegativeInt(x)*x>=bigFourKN) do inc(x);
        xMax:=floor64(temp+sixthRootOfR/(4*sqrt(k))); //<= 4*r^(4/3)+r^(1/6)/(4*sqrt(r^(1/3))) -> r< 59172824724903
        while x<=xMax do begin
          bigY:=squareOfMinus4kn(x);
          bigRootOfY:=bigY.iSqrt(false,yIsSquare);
          if yIsSquare then begin
            bigY:=(bigRootOfY+x).greatestCommonDivider(r); //=gcd(sqrt(bigY)+x,r)
            bigRootOfY:=r div bigY;
            if bigY=1
            then       setLength(result.bigFactors,length(result.bigFactors)+1)
            else begin setLength(result.bigFactors,length(result.bigFactors)+2);
                       result.bigFactors[length(result.bigFactors)-2]:=bigY.toNewBigInt; end;
            result           .bigFactors[length(result.bigFactors)-1]:=bigRootOfY.toNewBigInt;
            lehmannTestCompleted:=true;
            x:=xMax;
          end;
          inc(x);
        end;
      end else begin
        bigX:=bigFourKN.iSqrt(true,yIsSquare);
        while not(bigX*bigX>=bigFourKN) do inc(x);
        bigXMax:=bigFourKN+floatToFixedSizeNonnegativeInt(sixthRootOfR/(4*sqrt(k)),RM_DEFAULT);
        while bigX<=bigXMax do begin
          bigY:=bigX*bigX-bigFourKN;
          bigRootOfY:=bigY.iSqrt(false,yIsSquare);
          if yIsSquare then begin
            bigY:=(bigRootOfY+bigX).greatestCommonDivider(r); //=gcd(sqrt(bigY)+x,r)
            bigRootOfY:=r div bigY;
            if bigY=1
            then       setLength(result.bigFactors,length(result.bigFactors)+1)
            else begin setLength(result.bigFactors,length(result.bigFactors)+2);
                       result.bigFactors[length(result.bigFactors)-2]:=bigY.toNewBigInt; end;
            result           .bigFactors[length(result.bigFactors)-1]:=bigRootOfY.toNewBigInt;
            lehmannTestCompleted:=true;
            x:=xMax;
          end;
          bigX+=1;
        end;
      end;
      inc(k);
    end;
    if not(lehmannTestCompleted) then begin
      setLength(result.bigFactors,length(result.bigFactors)+1);
      result.bigFactors[length(result.bigFactors)-1]:=r.toNewBigInt;
    end;
  end;

FUNCTION millerRabinTest(CONST n,a:longint):boolean;
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
      p:=p*p mod n;
      if odd(d) then t:=t*p mod n;
    end;
    if (t=1) or (t=n1) then exit(true);
    for k:=1 to j-1 do begin
      t:=t*t mod n;
      if t=n1 then exit(true);
      if t<=1 then break;
    end;
    result:=false;
  end;

FUNCTION bigMillerRabinTest(CONST n:T_fixedSizeNonnegativeInt; CONST a:int64):boolean;
  VAR n1,d,t:T_fixedSizeNonnegativeInt;
      j:longint=1;
      k:longint;
  begin
    n1:=n-1;
    d:=n; d.shiftRightOneBit;
    while not(d.isOdd) do begin
      d.shiftRightOneBit;
      inc(j);
    end;
    t:=T_fixedSizeNonnegativeInt(a).powMod(d,n);
    if (t=1) or (t=n1) then exit(true);
    for k:=1 to j-1 do begin
      t:=t*t mod n;
      if (t=n1) then exit(true);
      if (t<=1) then break;
    end;
    result:=false;
  end;

FUNCTION isPrime(CONST n:longint ):boolean;
  begin
    if (n    =2)   or (n    =3  ) or (n    =5  ) or (n    =7  ) then exit(true);
    if (n    =1) or
       (n mod 2=0) or (n mod 3=0) or (n mod 5=0) or (n mod 7=0) then exit(false);
    if n<1373653 then exit(millerRabinTest(n, 2) and millerRabinTest(n, 3));
    if n<9080191 then exit(millerRabinTest(n,31) and millerRabinTest(n,37));
    exit(millerRabinTest(n,2) and millerRabinTest(n,7) and millerRabinTest(n,61));
  end;

FUNCTION isPrime(CONST n:T_fixedSizeNonnegativeInt):boolean;
  VAR relBits :longint;

   FUNCTION isComposite(x:int64):boolean; inline;
     VAR y:int64=2*3*5*7*11*13*17*19*23*29*31*37*41*43*47;
         z:int64=1;
     begin
       z:=x;
       while (y<>0) do begin x:=z mod y; z:=y; y:=x; end;
       result:=z>1;
     end;

  FUNCTION isComposite(CONST bigX:T_fixedSizeNonnegativeInt):boolean; inline;
    VAR x:int64=1;
        y:int64=2*3*5*7*11*13*17*19*23*29*31*37*41*43*47;
        z:int64=1;
    begin
      x:=bigX mod y;
      z:=y;
      y:=x;
      while (y<>0) do begin x:=z mod y; z:=y; y:=x; end;
      result:=z>1;
    end;

  CONST pr:array[0..41] of byte=(3,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251);
  VAR a:byte;
      fixedN:T_fixedSizeNonnegativeInt;
  begin
    if n=0 then exit(false);
    if n<=9223372036854775807
    then begin if isComposite(int64(n)) then exit(false); end
    else begin if isComposite(      n ) then exit(false); end;
    if n<=2147483647 then exit(isPrime(int64(n)));
    fixedN:=n;
    if not(n>=4759123141) then exit(bigMillerRabinTest(fixedN,2) and bigMillerRabinTest(fixedN,7) and bigMillerRabinTest(fixedN,61));
    result:=bigMillerRabinTest(fixedN,2) and bigMillerRabinTest(fixedN,5) and bigMillerRabinTest(fixedN,7) and bigMillerRabinTest(fixedN,11);
    if not(result) or not(n>=2152302898747) then exit;
    result:=bigMillerRabinTest(fixedN,13);
    if not(result) or not(n>=3474749660383) then exit;
    result:=bigMillerRabinTest(fixedN,17);
    if not(result) or not(n>=341550071728321) then exit;
    result:=bigMillerRabinTest(fixedN,19) and bigMillerRabinTest(fixedN,23);
    if not(result) or not(n>=3825123056546413051) then exit;
    result:=bigMillerRabinTest(fixedN,29) and bigMillerRabinTest(fixedN,31) and bigMillerRabinTest(fixedN,37);
    relBits:=n.relevantBits;
    if not(result) or (relBits<79) then exit;
    result:=bigMillerRabinTest(fixedN,41);
    if not(result) or (relBits<82) then exit;
    for a in pr do if not(bigMillerRabinTest(fixedN,a)) then exit(false);
    result:=true;
  end;

end.
