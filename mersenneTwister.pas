{ ******************************************************************
    Mersenne Twister random Number Generator for pascal
  ******************************************************************}

UNIT mersenneTwister;

INTERFACE

PROCEDURE InitMT(seed : longint);
{ Initializes MT generator with a seed }

PROCEDURE InitMTbyArray(InitKey : array of longint; KeyLength : word);
{ Initialize MT generator with an array InitKey[0..(KeyLength - 1)] }

FUNCTION IRanMT : longint;
{ Generates a Random number on [-231 .. 231 - 1] interval }

IMPLEMENTATION

CONST
  N          = 624;
  M          = 397;
  MATRIX_A   = $9908b0df;  { constant vector a }
  UPPER_MASK = $80000000;  { most significant w-r bits }
  LOWER_MASK = $7fffffff;  { least significant r bits }

  mag01 : array[0..1] of Cardinal{LongInt} = (0, MATRIX_A);

VAR
  mt  : array[0..(N-1)] of Cardinal{LongInt};  { the array for the state vector }
  mti : word;                        { mti == N+1 means mt[N] is not initialized }

PROCEDURE InitMT(seed : longint);
VAR
  i : word;
begin
  mt[0] := seed and $ffffffff;
  for i := 1 to N-1 do
    begin
      mt[i] := (1812433253 * (mt[i-1] xor (mt[i-1] shr 30)) + i);
        { See Knuth TAOCP Vol2. 3rd Ed. P.106 For multiplier.
          in the previous versions, MSBs of the seed affect
          only MSBs of the array mt[].
          2002/01/09 Modified by Makoto Matsumoto }
      mt[i] := mt[i] and $ffffffff;
        { For >32 Bit machines }
    end;
  mti := N;
end;

PROCEDURE InitMTbyArray(InitKey : array of longint; KeyLength : word);
VAR
  i, j, k, k1 : word;
begin
  InitMT(19650218);

  i := 1;
  j := 0;

  if N > KeyLength then k1 := N else k1 := KeyLength;

  for k := k1 downto 1 do
    begin
      mt[i] := (mt[i] xor ((mt[i-1] xor (mt[i-1] shr 30)) * 1664525)) + InitKey[j] + j; { non linear }
      mt[i] := mt[i] and $ffffffff; { for WORDSIZE > 32 machines }
      i := i + 1;
      j := j + 1;
      if i >= N then
        begin
          mt[0] := mt[N-1];
          i := 1;
        end;
      if j >= KeyLength then j := 0;
    end;

  for k := N-1 downto 1 do
    begin
      mt[i] := (mt[i] xor ((mt[i-1] xor (mt[i-1] shr 30)) * 1566083941)) - i; { non linear }
      mt[i] := mt[i] and $ffffffff; { for WORDSIZE > 32 machines }
      i := i + 1;
      if i >= N then
        begin
          mt[0] := mt[N-1];
          i := 1;
        end;
    end;

    mt[0] := $80000000; { MSB is 1; assuring non-zero initial array }
end;

FUNCTION IRanMT : longint;
VAR
  y : longint;
  k : word;
begin
  if mti >= N then  { generate N words at one Time }
    begin
      { If IRanMT() has not been called, a default initial seed is used }
      if mti = N + 1 then InitMT(5489);

      for k := 0 to (N-M)-1 do
        begin
          y := (mt[k] and UPPER_MASK) or (mt[k+1] and LOWER_MASK);
          mt[k] := mt[k+M] xor (y shr 1) xor mag01[y and $1];
        end;

      for k := (N-M) to (N-2) do
        begin
          y := (mt[k] and UPPER_MASK) or (mt[k+1] and LOWER_MASK);
          mt[k] := mt[k - (N - M)] xor (y shr 1) xor mag01[y and $1];
        end;

      y := (mt[N-1] and UPPER_MASK) or (mt[0] and LOWER_MASK);
      mt[N-1] := mt[M-1] xor (y shr 1) xor mag01[y and $1];

      mti := 0;
    end;

  y := mt[mti];
  mti := mti + 1;

  { Tempering }
  y := y xor (y shr 11);
  y := y xor ((y shl  7) and $9d2c5680);
  y := y xor ((y shl 15) and $efc60000);
  y := y xor (y shr 18);

  IRanMT := y
end;

CONST
  init : array[0..3] of longint = ($123, $234, $345, $456);

begin
  InitMTbyArray(init, 4);
end.

{ ******************************************************************
    Mersenne Twister random Number Generator end
  ******************************************************************}
