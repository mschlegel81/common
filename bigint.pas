UNIT bigint;
INTERFACE
USES sysutils;
CONST
  BITS_PER_DIGIT=16;
  DIGIT_MAX_VALUE=(1 shl BITS_PER_DIGIT)-1;
  UPPER_DIGIT_BIT=1 shl (BITS_PER_DIGIT-1);
  WORD_BIT:array[0..BITS_PER_DIGIT-1] of word=(1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768);

TYPE
  T_comparisonResult=(CR_EQUAL,
                      CR_LESSER,
                      CR_GREATER);
  P_bigint=^T_bigint;
  T_bigint=object
    private
      negative:boolean;
      digitCount:longint;
      digits:Pword;
      CONSTRUCTOR createFromRawData(CONST negative_:boolean; CONST digitCount_:longint; CONST digits_:Pword);
      PROCEDURE shlInc(CONST incFirstBit:boolean);
      FUNCTION relevantBits:longint;
      FUNCTION getBit(CONST index:longint):boolean;
      PROCEDURE setBit(CONST index:longint; CONST value:boolean);
    public
      CONSTRUCTOR createZero;
      CONSTRUCTOR create(CONST negativeNumber:boolean; CONST digitCount_:longint);
      CONSTRUCTOR fromInt(CONST i:int64);
      CONSTRUCTOR fromString(CONST s:string);
      CONSTRUCTOR create(CONST toClone:T_bigint);
      FUNCTION toInt:int64;
      {if examineNicheCase is true, the case of -2^63 is considered; otherwise the function is symmetrical}
      FUNCTION canBeRepresentedAsInt64(CONST examineNicheCase: boolean=true): boolean;

      DESTRUCTOR destroy;
      PROCEDURE flipSign;
      FUNCTION compareAbsValue(CONST big:T_bigint):T_comparisonResult; inline;
      FUNCTION compareAbsValue(CONST int:int64):T_comparisonResult; inline;
      FUNCTION compare(CONST big:T_bigint):T_comparisonResult; inline;
      FUNCTION compare(CONST int:int64):T_comparisonResult; inline;
      FUNCTION plus (CONST big:T_bigint):P_bigint;
      FUNCTION minus(CONST big:T_bigint):P_bigint;
      FUNCTION mult (CONST big:T_bigint):P_bigint;
      PROCEDURE multWith(CONST l:longint);
      PROCEDURE divBy(CONST divisor:word; OUT rest:word);
      PROCEDURE incAbsValue(CONST positiveIncrement:dword);
      {returns true on success, false on division by zero}
      FUNCTION divMod(CONST divisor:T_bigint; OUT quotient,rest:P_bigint):boolean;
      FUNCTION toString:string;
  end;

IMPLEMENTATION
PROCEDURE performSelfTest;
  CONST ix:int64= 1234567;
        iy:int64= 9876543;
        iz:int64=-1929176;
  VAR bx,by,bz:T_bigint;
      r:P_bigint;
      q:P_bigint=nil;
  PROCEDURE assertEqualsAndDispose(CONST comparand:int64);
    VAR valueOfR:int64;
    begin
      valueOfR:=r^.toInt;
      dispose(r,destroy);
      if valueOfR<>comparand then raise Exception.create('big int self test failed: '+intToStr(valueOfR)+'<>'+intToStr(comparand));
    end;

  begin
    try
      bx.fromInt(ix);
      by.fromInt(iy);
      bz.fromInt(iz);

      writeln(bx.toString,' ',ix);
      writeln(by.toString,' ',iy);
      writeln(bz.toString,' ',iz);

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

      new(r,fromString(intToStr(ix))); assertEqualsAndDispose(ix);
      new(r,fromString(intToStr(iy))); assertEqualsAndDispose(iy);
      new(r,fromString(intToStr(iz))); assertEqualsAndDispose(iz);
    finally
      bx.destroy;
      by.destroy;
      bz.destroy;
      if (q<>r) and (q<>nil) then dispose(q,destroy);
    end;
  end;

PROCEDURE rawDataPlus(CONST xDigits:Pword; CONST xDigitCount:longint;
                      CONST yDigits:Pword; CONST yDigitCount:longint;
                      OUT sumDigits:Pword; OUT sumDigitCount:longint); inline;
  VAR carry:int64=0;
      tmp  :int64=0;
      i    :longint;
  begin
       sumDigitCount:=xDigitCount;
    if sumDigitCount< yDigitCount then
       sumDigitCount:=yDigitCount;
    getMem(sumDigits,sizeOf(word)*sumDigitCount);
    for i:=0 to sumDigitCount-1 do begin
      tmp:=carry;
      if i<xDigitCount then tmp+=xDigits[i];
      if i<yDigitCount then tmp+=yDigits[i];
      sumDigits[i]:=tmp and DIGIT_MAX_VALUE;
      carry:=tmp shr BITS_PER_DIGIT;
    end;
    if carry>0 then begin
      inc(sumDigitCount);
      ReAllocMem(sumDigits,sizeOf(word)*sumDigitCount);
      sumDigits[sumDigitCount-1]:=carry;
    end;
  end;

{Precondition: x>y}
PROCEDURE rawDataMinus(CONST xDigits:Pword; CONST xDigitCount:longint;
                       CONST yDigits:Pword; CONST yDigitCount:longint;
                       OUT diffDigits:Pword; OUT diffDigitCount:longint); inline;
  VAR carry:int64=0;
      tmp  :int64=0;
      i    :longint;
  begin
    diffDigitCount:=xDigitCount;
    getMem(diffDigits,sizeOf(word)*diffDigitCount);
    for i:=0 to diffDigitCount-1 do begin
      tmp:=carry+xDigits[i];
      if i<yDigitCount then tmp-=yDigits[i];
      if tmp<0 then begin
        carry:=-1;
        inc(tmp,DIGIT_MAX_VALUE+1);
      end else carry:=0;
      diffDigits[i]:=tmp;
    end;
    while (diffDigitCount>0) and (diffDigits[diffDigitCount-1]=0) do dec(diffDigitCount);
    if diffDigitCount<>xDigitCount then ReAllocMem(diffDigits,sizeOf(word)*diffDigitCount);
  end;

CONSTRUCTOR T_bigint.createFromRawData(CONST negative_: boolean; CONST digitCount_: longint; CONST digits_: Pword);
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
      ReAllocMem(digits,digitCount*sizeOf(word));
      digits[digitCount-1]:=1;
    end;
  end;

FUNCTION T_bigint.relevantBits: longint;
  VAR upperDigit:word;
      k:longint;
  begin
    if digitCount=0 then exit(0);
    upperDigit:=digits[digitCount-1];
    result:=BITS_PER_DIGIT*digitCount;
    for k:=15 downto 0 do
      if upperDigit<WORD_BIT[k]
      then dec (result)
      else exit(result);
  end;

FUNCTION T_bigint.getBit(CONST index: longint): boolean;
  VAR digitIndex:longint;
      bitIndex  :longint;
  begin
    digitIndex:=index shr 4;
    if digitIndex>=digitCount then exit(false);
    bitIndex  :=index and (BITS_PER_DIGIT-1);
    result:=(digits[digitIndex] and WORD_BIT[bitIndex])<>0;
  end;

PROCEDURE T_bigint.setBit(CONST index: longint; CONST value: boolean);
  VAR digitIndex:longint;
      bitIndex  :longint;
      k:longint;
  begin
    digitIndex:=index shr 4;
    bitIndex:=index and (BITS_PER_DIGIT-1);
    if value then begin
      //setting a true bit means, we might have to increase the number of digits
      if (digitIndex>=digitCount) and value then begin
        ReAllocMem(digits,(digitIndex+1)*sizeOf(word));
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
      if k<>digitCount then ReAllocMem(digits,sizeOf(word)*digitCount);
    end;
  end;

CONSTRUCTOR T_bigint.createZero;
  begin
    create(false,0);
  end;

CONSTRUCTOR T_bigint.create(CONST negativeNumber: boolean; CONST digitCount_: longint);
  begin
    negative:=negativeNumber;
    digitCount:=digitCount_;
    getMem(digits,sizeOf(word)*digitCount);
  end;

CONSTRUCTOR T_bigint.fromInt(CONST i: int64);
  VAR unsigned:int64;
      d0,d1,d2,d3:word;
  begin
    negative:=i<0;
    if negative
    then unsigned:=-i
    else unsigned:= i;
    d0:=(unsigned                       ) and DIGIT_MAX_VALUE;
    d1:=(unsigned shr (BITS_PER_DIGIT  )) and DIGIT_MAX_VALUE;
    d2:=(unsigned shr (BITS_PER_DIGIT*2)) and DIGIT_MAX_VALUE;
    d3:=(unsigned shr (BITS_PER_DIGIT*3)) and DIGIT_MAX_VALUE;
    digitCount:=4;
    if d3=0 then begin
      dec(digitCount);
      if d2=0 then begin
        dec(digitCount);
        if d1=0 then begin
          dec(digitCount);
          if d0=0 then dec(digitCount);
        end;
      end;
    end;
    getMem(digits,sizeOf(word)*digitCount);
    if digitCount>0 then digits[0]:=d0;
    if digitCount>1 then digits[1]:=d1;
    if digitCount>2 then digits[2]:=d2;
    if digitCount>3 then digits[3]:=d3;
  end;

CONSTRUCTOR T_bigint.fromString(CONST s: string);
  CONST CHUNK_FACTOR:array[1..4] of longint=(10,100,1000,10000);
  VAR i:longint=1;
      chunkSize:longint;
      chunkValue:word;
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

CONSTRUCTOR T_bigint.create(CONST toClone: T_bigint);
  begin
    create(toClone.negative,toClone.digitCount);
    move(toClone.digits^,digits^,sizeOf(word)*digitCount);
  end;

FUNCTION T_bigint.toInt: int64;
  begin
    result:=0;
    if digitCount>0 then result:=         digits[0];
    if digitCount>1 then inc(result,int64(digits[1]) shl (BITS_PER_DIGIT  ));
    if digitCount>2 then inc(result,int64(digits[2]) shl (BITS_PER_DIGIT*2));
    if digitCount>3 then inc(result,int64(digits[3]) shl (BITS_PER_DIGIT*3));
    if negative then result:=-result;
  end;

FUNCTION T_bigint.canBeRepresentedAsInt64(CONST examineNicheCase: boolean): boolean;
  begin
    if digitCount>4 then exit(false);
    if digitCount<4 then exit(true);
    if (UPPER_DIGIT_BIT and digits[3]=0) then exit(true);
    if negative and examineNicheCase then begin
      //in this case we can still represent -(2^63), so there is one special case to consider:
      result:=(digits[3]=UPPER_DIGIT_BIT) and (digits[2]=0) and (digits[1]=0) and (digits[0]=0);
    end else
    result:=false;
  end;

DESTRUCTOR T_bigint.destroy;
  begin
    freeMem(digits,sizeOf(word)*digitCount);
  end;

PROCEDURE T_bigint.flipSign;
  begin
    negative:=not(negative);
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
  CONST flipped:array[T_comparisonResult] of T_comparisonResult=(CR_EQUAL,CR_GREATER,CR_LESSER);
  begin
    if negative and not(big.negative) then exit(CR_LESSER);
    if not(negative) and big.negative then exit(CR_GREATER);
    if negative then exit(flipped[compareAbsValue(big)])
                else exit(        compareAbsValue(big) );
  end;

FUNCTION T_bigint.compare(CONST int: int64): T_comparisonResult;
  VAR s:int64;
  begin
    if not(canBeRepresentedAsInt64) then begin
      if negative then exit(CR_LESSER)
                  else exit(CR_GREATER);
    end;
    s:=toInt;
    if s>int then exit(CR_GREATER);
    if s<int then exit(CR_LESSER);
    result:=CR_EQUAL;
  end;

FUNCTION T_bigint.plus(CONST big: T_bigint): P_bigint;
  VAR resultDigits:Pword;
      resultDigitCount:longint;
  begin
    if negative=big.negative then begin
      rawDataPlus(digits,      digitCount,
              big.digits,  big.digitCount,
            resultDigits,resultDigitCount);
      new(result,createFromRawData(negative,resultDigitCount,resultDigits));
    end else case compareAbsValue(big) of
      CR_EQUAL  : new(result,create(false,0));
      CR_LESSER : begin
        rawDataMinus(big.digits,  big.digitCount,
                         digits,      digitCount,
                   resultDigits,resultDigitCount);
        new(result,createFromRawData(big.negative,resultDigitCount,resultDigits));
      end;
      CR_GREATER: begin
        rawDataMinus(digits,      digitCount,
                 big.digits,  big.digitCount,
               resultDigits,resultDigitCount);
        new(result,createFromRawData(negative,resultDigitCount,resultDigits));
      end;
    end;
  end;

//function T_bigint.plus(const int: Int64): P_bigint;
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

FUNCTION T_bigint.minus(CONST big: T_bigint): P_bigint;
  VAR resultDigits:Pword;
      resultDigitCount:longint;
  begin
    if negative xor big.negative then begin
      //(-x)-y = -(x+y)
      //x-(-y) =   x+y
      rawDataPlus(digits,    digitCount,
              big.digits,big.digitCount,
                  resultDigits,resultDigitCount);
      new(result,createFromRawData(negative,resultDigitCount,resultDigits));
    end else case compareAbsValue(big) of
      CR_EQUAL  : new(result,create(false,0));
      CR_LESSER : begin
        // x-y = -(y-x) //opposed sign as y
        rawDataMinus(big.digits,  big.digitCount,
                         digits,      digitCount,
                   resultDigits,resultDigitCount);
        new(result,createFromRawData(not(big.negative),resultDigitCount,resultDigits));
      end;
      CR_GREATER: begin
        rawDataMinus(digits,      digitCount,
                 big.digits,  big.digitCount,
               resultDigits,resultDigitCount);
        new(result,createFromRawData(negative,resultDigitCount,resultDigits));
      end;
    end;
  end;

//function T_bigint.minus(const int: int64): P_bigint;
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

FUNCTION T_bigint.mult(CONST big: T_bigint): P_bigint;
  VAR resultDigits:Pword;
      resultDigitCount:longint;
      i,j,k:longint;
      carry:int64=0;
  begin
    resultDigitCount:=digitCount+big.digitCount;
    getMem(resultDigits,sizeOf(word)*resultDigitCount);
    for k:=0 to resultDigitCount-1 do begin
      for i:=0 to k do if (i<digitCount) and (digits[i]<>0) then begin
        j:=k-i;
        //each increment is < 2**32
        //an overflow cannot occur before the 32769th increment if we started with the greatest possible carry
        if (j<big.digitCount) and (big.digits[j]<>0) then inc(carry,digits[i]*big.digits[j]);
      end;
      resultDigits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
    //find highest valued nonzero digit
    k:=resultDigitCount-1;
    while (k>0) and (resultDigits[k]=0) do dec(k);
    if resultDigitCount<>k+1 then begin
       resultDigitCount:=k+1;
       ReAllocMem(resultDigits,sizeOf(word)*resultDigitCount);
    end;

    new(result,createFromRawData(negative xor big.negative,resultDigitCount,resultDigits));
  end;

PROCEDURE T_bigint.multWith(CONST l: longint);
  VAR carry:int64=0;
      factor:int64;
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
      ReAllocMem(digits,k*sizeOf(word));
      while digitCount<k do begin
        digits[digitCount]:=carry and DIGIT_MAX_VALUE;
        carry:=carry shr BITS_PER_DIGIT;
        inc(digitCount);
      end;
    end;
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
        ReAllocMem(digits,digitCount*sizeOf(word));
        digits[k]:=0;
      end;
      carry+=digits[k];
      digits[k]:=carry and DIGIT_MAX_VALUE;
      carry:=carry shr BITS_PER_DIGIT;
    end;
  end;

FUNCTION T_bigint.divMod(CONST divisor: T_bigint; OUT quotient, rest: P_bigint): boolean;
  VAR bitIdx:longint;
  begin
    if divisor.digitCount=0 then exit(false);
    new(quotient,create(negative xor divisor.negative,0));
    new(rest    ,create(negative                     ,0));
    for bitIdx:=relevantBits-1 downto 0 do begin
      rest^.shlInc(getBit(bitIdx));
      if rest^.compareAbsValue(divisor) in [CR_EQUAL,CR_GREATER] then begin
        rawDataMinus(rest^.digits,  rest^.digitCount,
                   divisor.digits,divisor.digitCount,
                     rest^.digits,  rest^.digitCount);
        quotient^.setBit(bitIdx,true);
      end;
    end;
  end;

PROCEDURE T_bigint.divBy(CONST divisor: word; OUT rest: word);
  VAR bitIdx:longint;
      quotient:T_bigint;
      tempRest:dword=0;
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
    freeMem(digits,sizeOf(word)*digitCount);
    digits:=quotient.digits;
    digitCount:=quotient.digitCount;
    rest:=tempRest;
  end;

FUNCTION T_bigint.toString: string;
  VAR temp:T_bigint;
      chunkVal:word;
      chunkTxt:string;
  begin
    if digitCount=0 then exit('0');
    temp.create(self);
    result:='';
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

INITIALIZATION
  performSelfTest;

end.

