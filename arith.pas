UNIT Arith;
INTERFACE
{$B-,R-,S-}

CONST
  (* size of ARITHMETIC code values. *)

  Code_value=16; (* Number of bits in a code value *)
  Top_value=1 shl Code_value-1; (* Largest code value *)
  Max_frequency=(Top_value+1) div 4-1; (* Maximum allowed frequency count *)

TYPE
  Code_type=longint; (* TYPE of an arithmetic code value *)

CONST
  (* HALF and QUARTER POINTS in the code value range. *)

  First_qtr:Code_type=Top_value div 4+1; (* point after first quarter *)
  Half:Code_type=2*(Top_value div 4+1); (* point after first half *)
  Third_qtr:Code_type=3*(Top_value div 4+1); (* point after third half *)

  (* the set of SYMBOLS THAT MAY BE ENCODE. *)

  No_of_chars=256; (* Number of character symbols *)
  EOF_symbol=No_of_chars+1; (* index of eof symbol *)
  No_of_symbols=No_of_chars+1; (* total number of symbols *)

  MODEL_STYLE_BASIC   =0;
  MODEL_STYLE_MARKOV  =1;
  MODEL_STYLE_ADAPTIVE=2;
  MODEL_STYLE_ADAPTIVE_MARKOV=MODEL_STYLE_MARKOV + MODEL_STYLE_ADAPTIVE;


TYPE
  T_model=object
    style:byte; // in [0,1,2,3]
    (* TRANSLATION TABLES BETWEEN CHARACTERS and SYMBOL INDEXES. *)
    char_to_index:array of array[0..No_of_chars-1] of word; (* to index from character *)
    index_to_char:array of array[1..No_of_chars] of byte; (* to character from index *)
    (* CUMULATIVE FREQUENCY table. *)
    freq:array of array[0..No_of_symbols] of word;
    cum_freq:array of array[0..No_of_symbols] of word; (* Cumulative symbol frequencies *)

    CONSTRUCTOR create(CONST style_:byte; CONST initWithDefaultValues:boolean);
    DESTRUCTOR cestroy;
  end;

  T_codingState=record
    (* current state of the ENCODING/DECODING. *)

    range:Code_type; (* size of the current code region *)
    low,high:Code_type; (* Ends of the current code region *)
    value:Code_type; (* Number of opposite bits to output after the *)
                     (* next bit or currently seen code value *)

    loop:boolean;
    ch:byte;
    symbol:word; (* Symbol to encode/decode *)

    (* the BIT buffer. *)

    buffer:byte; (* Bits waiting for input/output *)
    bits_to_go:byte; (* Number of bits still in buffer *)
    garbage:byte; (* Number of bits past end of file *)

    InFile,outFile:file;
    nb:word;
  end;

IMPLEMENTATION
PROCEDURE start_inputing_bits;
begin
  bits_to_go:=0;
  garbage:=0;
end;

FUNCTION input_bit:byte;
begin
  if bits_to_go=0 then
    begin
      if not eof(InFile) then
        BlockRead(InFile,buffer,1,nb)
      else
        begin
          inc(garbage);
          if garbage>Code_value-2 then
            begin
              writeln('Unexpected end of file');
              halt(1);
            end;
        end;
      bits_to_go:=8;
    end;
  input_bit:=buffer and 1; (* read the bit from the Bottom of the byte *)
  buffer:=buffer shr 1;
  dec(bits_to_go);
end;

PROCEDURE start_outputing_bits;
begin
  buffer:=0;
  bits_to_go:=8;
end;

PROCEDURE output_bit(bit:byte);
begin
  buffer:=buffer shr 1;
  if bit>0 then
    buffer:=buffer or 128; (* write the bit on the top of buffer *)
  dec(bits_to_go);
  if bits_to_go=0 then
    begin
      BlockWrite(outFile,buffer,1,nb);
      bits_to_go:=8;
    end;
end;

PROCEDURE done_outputing_bits;
begin
  buffer:=buffer shr bits_to_go;
  BlockWrite(outFile,buffer,1,nb);
end;

PROCEDURE start_model;
VAR
  i:word;
begin
  for i:=0 to Pred(No_of_chars) do
    begin
      char_to_index[i]:=i+1; (* set up tables that translate between *)
      index_to_char[i+1]:=i; (* symbol indexes and characters *)
    end;
  freq[0]:=0; (* Must not be the same as freq[1] *)
  cum_freq[0]:=No_of_symbols;
  for i:=1 to No_of_symbols do
    begin
      freq[i]:=1; (* set up initial frequency counts *)
      cum_freq[i]:=No_of_symbols-i; (* to be one for all symbols *)
    end;
end;

PROCEDURE update_model;
VAR
  i:word; (* new index for symbol *)
  Cum:word;
  xi:byte;
  xsymbol:word;
begin
  if cum_freq[0]=Max_frequency then (* See if frequency count *)
    begin (* are at his maximum *)
      cum:=0;
      for i:=No_of_symbols downto 0 do (* if so, halve all *)
        begin (* the counts (keeping them non zero) *)
          freq[i]:=(freq[i]+1) shr 1;
          cum_freq[i]:=cum;
          inc(cum,freq[i]);
        end;
    end;
  i:=symbol;
  while freq[i]=freq[i-1] do (* find symbol's new index *)
    dec(i);
  if i<symbol then (* Update the translation *)
    begin (* tables if the symbol has moved *)
      xi:=index_to_char[i];
      xsymbol:=index_to_char[symbol];
      index_to_char[i]:=xsymbol;
      index_to_char[symbol]:=xi;
      char_to_index[xi]:=symbol;
      char_to_index[xsymbol]:=i;
    end;
  inc(freq[i]); (* increment the frequency count for the symbol and *)
  while i>0 do (* update the cumulative frequencies *)
    begin
      dec(i);
      inc(cum_freq[i]);
    end;
end;

PROCEDURE start_encoding;
begin
  low:=0; (* Full range code *)
  high:=Top_value;
  value:=0; (* no bits to follow next *)
end;

PROCEDURE bit_plus_follow(bit:byte);
begin
  output_bit(bit); (* output the bit *)
  bit:=(bit+1) and 1;
  while value>0 do
    begin
      output_bit(bit); (* output value opposite bits. set *)
      dec(value); (* value to zero *)
    end;
end;

PROCEDURE encode_symbol;
begin
  range:=high-low+1;
  high:=low+ (* Narrow the code region to that *)
    range*cum_freq[symbol-1] div cum_freq[0]-1; (* allotted to this symbol *)
  low:=low+
    range*cum_freq[symbol] div cum_freq[0];
  loop:=true;
  while loop do
    begin
      if high<Half then
        begin
          bit_plus_follow(0); (* output 0 if in low half *)
          low:=low shl 1; (* scale up code range *)
          high:=high shl 1+1;
        end
      else if low>=Half then
        begin
          bit_plus_follow(1); (* output 1 if in high half *)
          low:=(low-Half) shl 1; (* Subtract offset to top *)
          high:=(high-Half) shl 1+1;
        end
      else if (low>=First_qtr) and (high<Third_qtr) then
        begin
          inc(value); (* output an opposite bit later if in middle half *)
          low:=(low-First_qtr) shl 1; (* Subtract offset to middle *)
          high:=(high-First_qtr) shl 1+1;
        end
      else
        loop:=false;
    end;
end;

PROCEDURE done_encoding;
begin
  inc(value); (* output two bits that select the quarter that *)
  if low<First_qtr then (* the current code range contains *)
    bit_plus_follow(0)
  else
    bit_plus_follow(1);
end;

PROCEDURE start_decoding;
VAR
  i:byte;
begin
  value:=0;
  for i:=1 to Code_value do
    value:=value shl 1+input_bit; (* input bits to fill the code value *)
  low:=0; (* Full range code *)
  high:=Top_value;
end;

FUNCTION decode_symbol:word;
VAR
  Cum:word; (* Cumulative frequency calculated *)
  symbol:word;
  Left,Right,mid:word;
begin
  range:=high-low+1;
  cum:=Code_type((value-low+1)*cum_freq[0]-1) div
    range; (* find cum freq for value *)
  Left:=1; (* then find symbol with binary search *)
  Right:=No_of_symbols;
  while Left<Right do
    begin
      mid:=(Left+Right) shr 1;
      if cum_freq[mid]>cum then
        Left:=mid+1
      else
        Right:=mid;
    end;
  if (Left=Right) and (cum_freq[Left]<=cum) then
    symbol:=Left
  else
    begin
      writeln('The interval does not match');
      halt(1);
    end;
  decode_symbol:=symbol;
(*  if symbol<>EOF_symbol then
    begin*)
  high:=low+ (* Narrow the code region to that *)
    range*cum_freq[symbol-1] div cum_freq[0]-1; (* allotted to this symbol *)
  low:=low+
    range*cum_freq[symbol] div cum_freq[0];
  loop:=true;
  while loop do
    begin
      if high<Half then (* Expand low half *)
        begin
          value:=value shl 1+input_bit; (* move in next input bit *)
          low:=low shl 1; (* scale up code range *)
          high:=high shl 1+1;
        end
      else if low>=Half then (* Expand high half *)
        begin
          value:=(value-Half) shl 1+input_bit;
          low:=(low-Half) shl 1; (* Subtract offset to top *)
          high:=(high-Half) shl 1+1;
        end
      else if (low>=First_qtr) and (high<Third_qtr) then
        begin
          value:=(value-First_qtr) shl 1+input_bit;
          low:=(low-First_qtr) shl 1; (* Subtract offset to middle *)
          high:=(high-First_qtr) shl 1+1;
        end
      else
        loop:=false;
    end;
(*  end;*)
end;

//begin
//  if paramCount=3 then
//    begin
//      assign(InFile,paramStr(2));
//      {$I-}reset(InFile,1);{$I+}
//      if IOResult>0 then
//        begin
//          writeln('File not found');
//          halt(1);
//        end;
//      assign(outFile,paramStr(3));
//      rewrite(outFile,1);
//      start_model;
//      if paramStr(1)='e' then
//        begin
//          start_outputing_bits;
//          start_encoding;
//          while not eof(InFile) do
//            begin
//              BlockRead(InFile,ch,1,nb);
//              symbol:=char_to_index[ch];
//              encode_symbol;
//              update_model;
//            end;
//          symbol:=EOF_symbol;
//          encode_symbol;
//          done_encoding;
//          done_outputing_bits;
//        end
//      else if paramStr(1)='d' then
//        begin
//          start_inputing_bits;
//          start_decoding;
//          if not eof(InFile) then
//            symbol:=decode_symbol
//          else
//            symbol:=EOF_symbol;
//          while symbol<>EOF_symbol do
//            begin
//              ch:=index_to_char[symbol];
//              BlockWrite(outFile,ch,1,nb);
//              update_model;
//              symbol:=decode_symbol;
//            end;
//        end;
//      close(InFile);
//      close(outFile);
//    end
//  else
//    writeln('Usage: arith e|d infile outfile');
end.
