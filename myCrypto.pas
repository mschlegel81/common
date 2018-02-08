UNIT myCrypto;
INTERFACE
TYPE T_ISAAC=object
  private 
    randrsl: ARRAY[0..256] OF CARDINAL;
    randcnt: cardinal;
    mm: ARRAY[0..256] OF CARDINAL;
    aa,bb,cc: CARDINAL;
    PROCEDURE isaac;
    PROCEDURE irandInit;
    FUNCTION iRandA: BYTE;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy;
    PROCEDURE setSeedByTime;
    PROCEDURE setSeed(CONST seed:int64);
    PROCEDURE setSeed(CONST seed:string);
    FUNCTION iRandom : Cardinal;
    { XOR encrypt on random stream. Output: ASCII string }
    FUNCTION Vernam(CONST msg: STRING): STRING;
  end;

FUNCTION sha256(CONST data:string):string;
IMPLEMENTATION
 
PROCEDURE T_ISAAC.Isaac;
  VAR i,x,y: CARDINAL;
  begin
    cc := cc + 1;    // cc just gets incremented once per 256 results 
    bb := bb + cc;   // then combined with bb 
    FOR i := 0 TO 255 DO BEGIN
      x := mm[i];
      CASE (i mod 4) OF
         0: aa := aa xor (aa shl 13);
         1: aa := aa xor (aa shr 6 );
         2: aa := aa xor (aa shl 2 );
         3: aa := aa xor (aa shr 16);
      END;
      aa := mm[(i+128) mod 256] + aa;
      y  := mm[(x shr 2) mod 256] + aa + bb;
      mm[i] := y;    
      bb := mm[(y shr 10) mod 256] + x; 
      randrsl[i]:= bb; 
    END;
    randcnt:=0;  // prepare to use the first set of results 
  END;
 
CONSTRUCTOR T_ISAAC.create;
  begin
    setSeedByTime;
  end;

DESTRUCTOR T_ISAAC.destroy;
  begin
  end;
  
PROCEDURE T_ISAAC.setSeedByTime;
  VAR i: CARDINAL;
  BEGIN
    randomize;
    FOR i:=0 TO 255 DO mm[i]:=0;
    FOR i:=0 TO 255 DO randrsl[i]:=random(256);
    iRandInit;
  END;

PROCEDURE T_ISAAC.setSeed(CONST seed:int64);
  VAR i: CARDINAL;
      s:int64;
  BEGIN
    FOR i:=0 TO 255 DO mm[i]:=0;
    s:=seed;
    FOR i:=0 TO 255 DO begin
      randrsl[i]:=s and 255;
      s:=((s*31) shr 1) xor s;
    end;
    iRandInit;
  END;

PROCEDURE T_ISAAC.setSeed(CONST seed:string);
  VAR i,m: CARDINAL;
  BEGIN
    FOR i:= 0 TO 255 DO mm[i]:=0;
    m := Length(seed)-1;
    FOR i:= 0 TO 255 DO BEGIN
      IF i>m THEN randrsl[i]:=0
             ELSE randrsl[i]:=ord(seed[i+1]);
    END;
    iRandInit;
  END;

PROCEDURE T_isaac.iRandInit;
  PROCEDURE mix(VAR a,b,c,d,e,f,g,h: CARDINAL);
    BEGIN
      a := a xor b shl 11; d:=d+a; b:=b+c;
      b := b xor c shr  2; e:=e+b; c:=c+d;
      c := c xor d shl  8; f:=f+c; d:=d+e;
      d := d xor e shr 16; g:=g+d; e:=e+f;
      e := e xor f shl 10; h:=h+e; f:=f+g;
      f := f xor g shr  4; a:=a+f; g:=g+h;
      g := g xor h shl  8; b:=b+g; h:=h+a;
      h := h xor a shr  9; c:=c+h; a:=a+b;
    END;

  VAR i,a,b,c,d,e,f,g,h: CARDINAL;
  BEGIN
    aa:=0; bb:=0; cc:=0;
    a:=$9e3779b9;    // the golden ratio

    b:=a; c:=a; d:=a; e:=a; f:=a; g:=a; h:=a;

    FOR i := 0 TO 3 DO          // scramble it
         mix(a,b,c,d,e,f,g,h);

    i:=0;
    REPEAT  // fill in mm[] with messy stuff
      a+=randrsl[i  ]; b+=randrsl[i+1]; c+=randrsl[i+2]; d+=randrsl[i+3];
      e+=randrsl[i+4]; f+=randrsl[i+5]; g+=randrsl[i+6]; h+=randrsl[i+7];

     mix(a,b,c,d,e,f,g,h);
     mm[i  ]:=a; mm[i+1]:=b; mm[i+2]:=c; mm[i+3]:=d;
     mm[i+4]:=e; mm[i+5]:=f; mm[i+6]:=g; mm[i+7]:=h;
     i+=8;
    UNTIL i>255;

    // do a second pass to make all of the seed affect all of mm
    i:=0;
    REPEAT
     a+=mm[i  ]; b+=mm[i+1]; c+=mm[i+2]; d+=mm[i+3];
     e+=mm[i+4]; f+=mm[i+5]; g+=mm[i+6]; h+=mm[i+7];
     mix(a,b,c,d,e,f,g,h);
     mm[i  ]:=a; mm[i+1]:=b; mm[i+2]:=c; mm[i+3]:=d;
     mm[i+4]:=e; mm[i+5]:=f; mm[i+6]:=g; mm[i+7]:=h;
     i+=8;
    UNTIL i>255;
    isaac();           // fill in the first set of results
    randcnt:=0;       // prepare to use the first set of results
  END; {randinit}
 
{ Get a random 32-bit value 0..MAXINT }
FUNCTION T_isaac.iRandom : Cardinal;
  BEGIN
    iRandom := randrsl[randcnt];
    inc(randcnt);
    IF (randcnt >255) THEN BEGIN
        Isaac();
        randcnt := 0;
    END;
  END; {iRandom}
 
{ Get a random character in printable ASCII range }
FUNCTION T_isaac.iRandA: BYTE;
  BEGIN
    iRandA := iRandom mod 95 + 32;
  END;
 
{ XOR encrypt on random stream. Output: ASCII string }
FUNCTION T_isaac.Vernam(CONST msg: STRING): STRING;
  VAR i: CARDINAL;
  BEGIN
    setLength(result,length(msg));
    FOR i:=1 to length(msg) DO result[i]:=chr(iRandA xor ord(msg[i]));
  END;
 
FUNCTION sha256(CONST data:string):string;
  {$Q-}{$R-}
  VAR CurrentHash: array[0..7] of DWord;
      HashBuffer: array[0..63] of byte;
      LenHi: longword=0;
      LenLo: longword=0;
      Index: DWord=0;

  procedure Init;
    begin
      FillChar(HashBuffer ,Sizeof(HashBuffer ),0);
      FillChar(CurrentHash,Sizeof(CurrentHash),0);
      CurrentHash[0]:= $6a09e667;
      CurrentHash[1]:= $bb67ae85;
      CurrentHash[2]:= $3c6ef372;
      CurrentHash[3]:= $a54ff53a;
      CurrentHash[4]:= $510e527f;
      CurrentHash[5]:= $9b05688c;
      CurrentHash[6]:= $1f83d9ab;
      CurrentHash[7]:= $5be0cd19;
    end;

  function SwapDWord(CONST a: dword): dword;
    begin
      Result:= ((a and $FF) shl 24) or ((a and $FF00) shl 8) or ((a and $FF0000) shr 8) or ((a and $FF000000) shr 24);
    end;

  procedure compress;
    var
      a, b, c, d, e, f, g, h, t1, t2: DWord;
      W: array[0..63] of DWord;
      i: longword;
    begin
      Index:= 0;
      fillChar(W, SizeOf(W), 0);
      a:= CurrentHash[0]; b:= CurrentHash[1]; c:= CurrentHash[2]; d:= CurrentHash[3];
      e:= CurrentHash[4]; f:= CurrentHash[5]; g:= CurrentHash[6]; h:= CurrentHash[7];
      Move(HashBuffer,W,Sizeof(HashBuffer));
      for i:= 0 to 15 do
        W[i]:= SwapDWord(W[i]);
      for i:= 16 to 63 do
        W[i]:= (((W[i-2] shr 17) or (W[i-2] shl 15)) xor ((W[i-2] shr 19) or (W[i-2] shl 13)) xor
          (W[i-2] shr 10)) + W[i-7] + (((W[i-15] shr 7) or (W[i-15] shl 25)) xor
          ((W[i-15] shr 18) or (W[i-15] shl 14)) xor (W[i-15] shr 3)) + W[i-16];
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $428a2f98 + W[0]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $71374491 + W[1]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $b5c0fbcf + W[2]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $e9b5dba5 + W[3]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $3956c25b + W[4]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $59f111f1 + W[5]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $923f82a4 + W[6]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $ab1c5ed5 + W[7]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $d807aa98 + W[8]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $12835b01 + W[9]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $243185be + W[10]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $550c7dc3 + W[11]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $72be5d74 + W[12]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $80deb1fe + W[13]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $9bdc06a7 + W[14]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $c19bf174 + W[15]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $e49b69c1 + W[16]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $efbe4786 + W[17]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $0fc19dc6 + W[18]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $240ca1cc + W[19]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $2de92c6f + W[20]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $4a7484aa + W[21]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $5cb0a9dc + W[22]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $76f988da + W[23]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $983e5152 + W[24]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $a831c66d + W[25]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $b00327c8 + W[26]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $bf597fc7 + W[27]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $c6e00bf3 + W[28]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $d5a79147 + W[29]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $06ca6351 + W[30]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $14292967 + W[31]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $27b70a85 + W[32]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $2e1b2138 + W[33]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $4d2c6dfc + W[34]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $53380d13 + W[35]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $650a7354 + W[36]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $766a0abb + W[37]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $81c2c92e + W[38]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $92722c85 + W[39]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $a2bfe8a1 + W[40]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $a81a664b + W[41]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $c24b8b70 + W[42]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $c76c51a3 + W[43]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $d192e819 + W[44]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $d6990624 + W[45]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $f40e3585 + W[46]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $106aa070 + W[47]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $19a4c116 + W[48]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $1e376c08 + W[49]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $2748774c + W[50]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $34b0bcb5 + W[51]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $391c0cb3 + W[52]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $4ed8aa4a + W[53]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $5b9cca4f + W[54]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $682e6ff3 + W[55]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;
      t1:= h + (((e shr 6) or (e shl 26)) xor ((e shr 11) or (e shl 21)) xor ((e shr 25) or (e shl 7))) + ((e and f) xor (not e and g)) + $748f82ee + W[56]; t2:= (((a shr 2) or (a shl 30)) xor ((a shr 13) or (a shl 19)) xor ((a shr 22) xor (a shl 10))) + ((a and b) xor (a and c) xor (b and c)); h:= t1 + t2; d:= d + t1;
      t1:= g + (((d shr 6) or (d shl 26)) xor ((d shr 11) or (d shl 21)) xor ((d shr 25) or (d shl 7))) + ((d and e) xor (not d and f)) + $78a5636f + W[57]; t2:= (((h shr 2) or (h shl 30)) xor ((h shr 13) or (h shl 19)) xor ((h shr 22) xor (h shl 10))) + ((h and a) xor (h and b) xor (a and b)); g:= t1 + t2; c:= c + t1;
      t1:= f + (((c shr 6) or (c shl 26)) xor ((c shr 11) or (c shl 21)) xor ((c shr 25) or (c shl 7))) + ((c and d) xor (not c and e)) + $84c87814 + W[58]; t2:= (((g shr 2) or (g shl 30)) xor ((g shr 13) or (g shl 19)) xor ((g shr 22) xor (g shl 10))) + ((g and h) xor (g and a) xor (h and a)); f:= t1 + t2; b:= b + t1;
      t1:= e + (((b shr 6) or (b shl 26)) xor ((b shr 11) or (b shl 21)) xor ((b shr 25) or (b shl 7))) + ((b and c) xor (not b and d)) + $8cc70208 + W[59]; t2:= (((f shr 2) or (f shl 30)) xor ((f shr 13) or (f shl 19)) xor ((f shr 22) xor (f shl 10))) + ((f and g) xor (f and h) xor (g and h)); e:= t1 + t2; a:= a + t1;
      t1:= d + (((a shr 6) or (a shl 26)) xor ((a shr 11) or (a shl 21)) xor ((a shr 25) or (a shl 7))) + ((a and b) xor (not a and c)) + $90befffa + W[60]; t2:= (((e shr 2) or (e shl 30)) xor ((e shr 13) or (e shl 19)) xor ((e shr 22) xor (e shl 10))) + ((e and f) xor (e and g) xor (f and g)); d:= t1 + t2; h:= h + t1;
      t1:= c + (((h shr 6) or (h shl 26)) xor ((h shr 11) or (h shl 21)) xor ((h shr 25) or (h shl 7))) + ((h and a) xor (not h and b)) + $a4506ceb + W[61]; t2:= (((d shr 2) or (d shl 30)) xor ((d shr 13) or (d shl 19)) xor ((d shr 22) xor (d shl 10))) + ((d and e) xor (d and f) xor (e and f)); c:= t1 + t2; g:= g + t1;
      t1:= b + (((g shr 6) or (g shl 26)) xor ((g shr 11) or (g shl 21)) xor ((g shr 25) or (g shl 7))) + ((g and h) xor (not g and a)) + $bef9a3f7 + W[62]; t2:= (((c shr 2) or (c shl 30)) xor ((c shr 13) or (c shl 19)) xor ((c shr 22) xor (c shl 10))) + ((c and d) xor (c and e) xor (d and e)); b:= t1 + t2; f:= f + t1;
      t1:= a + (((f shr 6) or (f shl 26)) xor ((f shr 11) or (f shl 21)) xor ((f shr 25) or (f shl 7))) + ((f and g) xor (not f and h)) + $c67178f2 + W[63]; t2:= (((b shr 2) or (b shl 30)) xor ((b shr 13) or (b shl 19)) xor ((b shr 22) xor (b shl 10))) + ((b and c) xor (b and d) xor (c and d)); a:= t1 + t2; e:= e + t1;

      CurrentHash[0]:= CurrentHash[0] + a;
      CurrentHash[1]:= CurrentHash[1] + b;
      CurrentHash[2]:= CurrentHash[2] + c;
      CurrentHash[3]:= CurrentHash[3] + d;
      CurrentHash[4]:= CurrentHash[4] + e;
      CurrentHash[5]:= CurrentHash[5] + f;
      CurrentHash[6]:= CurrentHash[6] + g;
      CurrentHash[7]:= CurrentHash[7] + h;
      FillChar(W,Sizeof(W),0);
      FillChar(HashBuffer,Sizeof(HashBuffer),0);
    end;

  VAR size:Dword;
      i:longint=1;
      digest:array[0..Sizeof(CurrentHash)-1] of byte;
  CONST hexDig:array[0..15]of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  begin
    init;
    size:=length(Data);
    LenHi:=size shr 29;
    LenLo:=size*8;

    while Size> 0 do begin
      if (Sizeof(HashBuffer)-Index)<= Size then begin
        Move(data[i],HashBuffer[Index],Sizeof(HashBuffer)-Index);
        Dec(Size,Sizeof(HashBuffer)-Index);
        Inc(i   ,Sizeof(HashBuffer)-Index);
        Compress;
      end else begin
        Move(data[i],HashBuffer[Index],Size);
        Inc(Index,Size);
        Size:= 0;
      end;
    end;
    HashBuffer[Index]:= $80;
    if Index>= 56 then
      Compress;
    PDWord(@HashBuffer[56])^:= SwapDWord(LenHi);
    PDWord(@HashBuffer[60])^:= SwapDWord(LenLo);
    Compress;
    CurrentHash[0]:= SwapDWord(CurrentHash[0]);
    CurrentHash[1]:= SwapDWord(CurrentHash[1]);
    CurrentHash[2]:= SwapDWord(CurrentHash[2]);
    CurrentHash[3]:= SwapDWord(CurrentHash[3]);
    CurrentHash[4]:= SwapDWord(CurrentHash[4]);
    CurrentHash[5]:= SwapDWord(CurrentHash[5]);
    CurrentHash[6]:= SwapDWord(CurrentHash[6]);
    CurrentHash[7]:= SwapDWord(CurrentHash[7]);
    Move(CurrentHash,Digest,Sizeof(CurrentHash));
    setLength(result,length(digest)*2);
    for i:=0 to length(digest)-1 do begin
      result[2*i+1]:=hexDig[(digest[i] shr 4) and 15];
      result[2*i+2]:=hexDig[ digest[i]        and 15];
    end;
    {$Q+}{$R+}

  end;

END.
 
