UNIT huffman;
INTERFACE
CONST END_OF_INPUT=256;
TYPE
  T_symbolFrequency=array[0..255] of longint;
  T_modelEntry=record previousSymbol:byte; followerFrequency:T_symbolFrequency end;

  HuffmanModel=(hm_DEFAULT,hm_LUCKY,hm_NUMBERS,hm_WIKIPEDIA,hm_MNH,hm_BINARY);
CONST
  DEFAULT_PREV_SYMBOL=32;

TYPE
  T_bitArray=object
    private
      datFill:longint;
      data:array of byte;
      trashBits:byte;
      cursorIndex:longint;
      FUNCTION getBit(CONST index:longint):boolean;
    public
      CONSTRUCTOR create;
      CONSTRUCTOR create(CONST rawData:ansistring);
      CONSTRUCTOR create(CONST prevArray:T_bitArray; CONST nextBit:boolean);
      DESTRUCTOR destroy;
      PROCEDURE append(CONST nextBit:boolean);
      PROCEDURE append(CONST arr:T_bitArray; CONST finalAppend:boolean=false);
      PROCEDURE parseString(CONST stringOfZeroesAndOnes:ansistring);
      FUNCTION size:longint;
      PROPERTY bit[CONST index:longint]:boolean read getBit; default;
      FUNCTION getRawDataAsString:ansistring;
      FUNCTION getBitString:ansistring;
      FUNCTION nextBit:boolean;
      FUNCTION hasNextBit:boolean;
  end;

  P_huffmanNode=^T_huffmanNode;
  T_huffmanNode=record
    symbol:word;
    frequency:longint;
    children:array[false..true] of P_huffmanNode;
  end;

  T_arrayOfHuffmanNode=array of P_huffmanNode;

  P_huffmanCode=^T_huffmanCode;
  T_huffmanCode=object
    private
      table:array [0..256] of T_bitArray;
      tree:P_huffmanNode;
    public
      CONSTRUCTOR create;
      CONSTRUCTOR create(CONST conservative:boolean; frequency: T_symbolFrequency);
      DESTRUCTOR destroy;
      PROCEDURE encodeNextSymbol(CONST c:char; VAR output:T_bitArray);
      PROCEDURE encodeEndOfInput(VAR output:T_bitArray);
      FUNCTION decodeNextSymbol(VAR input:T_bitArray):word;
  end;

  T_twoLevelHuffmanCode=object
    private
      subCodes:array[-1..255] of P_huffmanCode;
    public
      CONSTRUCTOR create(CONST conservative:boolean);
      CONSTRUCTOR create(CONST model:array of T_modelEntry);
      DESTRUCTOR destroy;
      FUNCTION encode(CONST s:ansistring):ansistring;
      FUNCTION decode(CONST s:ansistring):ansistring;
  end;

FUNCTION huffyDecode(CONST s:ansistring; CONST model:HuffmanModel):ansistring;
FUNCTION huffyEncode(CONST s:ansistring; CONST model:HuffmanModel):ansistring;
IMPLEMENTATION
USES myGenerics;
VAR huffmanCode:array[HuffmanModel] of specialize G_lazyVar<T_twoLevelHuffmanCode>;

OPERATOR +(CONST x,y:T_symbolFrequency):T_symbolFrequency;
  VAR i:longint;
      k:int64;
  begin
    for i:=0 to 255 do begin
      k:=int64(x[i])+int64(y[i]);
      if (k>=0) and (k<maxLongint)
      then result[i]:=k
      else result[i]:=0;
    end;
  end;

FUNCTION huffyDecode(CONST s: ansistring; CONST model:HuffmanModel): ansistring;
  begin
    result:=huffmanCode[model].value.decode(s);
  end;

FUNCTION huffyEncode(CONST s: ansistring; CONST model:HuffmanModel): ansistring;
  begin
    result:=huffmanCode[model].value.encode(s);
  end;

CONST DEFAULT_MODEL:{$i huffman_model_default.inc}

CONSTRUCTOR T_twoLevelHuffmanCode.create(CONST conservative:boolean);
  VAR i:longint;
  begin
    new(subCodes[-1],create);
    for i:=0 to high(subCodes) do subCodes[i]:=nil;
    for i:=0 to length(DEFAULT_MODEL)-1 do
      new(subCodes[DEFAULT_MODEL[i].previousSymbol],create(conservative,DEFAULT_MODEL[i].followerFrequency));
    for i:=0 to high(subCodes) do if (subCodes[i]=nil) then subCodes[i]:=subCodes[-1];
  end;

CONSTRUCTOR T_twoLevelHuffmanCode.create(CONST model:array of T_modelEntry);
  VAR model0:T_symbolFrequency;
      m:T_modelEntry;
      i:longint;
      ok:boolean=true;
  begin
    try
      for i:= 0 to 255 do model0  [i]:=0;
      for i:=-1 to 255 do subCodes[i]:=nil;
      for m in model do begin
        new(subCodes[m.previousSymbol],create(false,m.followerFrequency));
        model0+=m.followerFrequency;
      end;
      //Fill gaps by using default model:
      for i:=0 to 255 do if subCodes[i]=nil then for m in DEFAULT_MODEL do if m.previousSymbol=i then begin
        new(subCodes[i],create(true,m.followerFrequency));
        model0+=m.followerFrequency;
      end;
      //Create fallback model for all of the rest:
      new(subCodes[-1],create(true,model0));
    except
      ok:=false;
    end;
    if ok then begin
      //Fill gaps by using fallback model
      for i:=0 to 255 do if subCodes[i]=nil then subCodes[i]:=subCodes[-1];
    end else begin
      for i:=-1 to 255 do if subCodes[i]<>nil then begin
        dispose(subCodes[i],destroy);
        subCodes[i]:=nil;
      end;
    end;
  end;

DESTRUCTOR T_twoLevelHuffmanCode.destroy;
  VAR i:longint;
  begin
    for i:=0 to high(subCodes) do if subCodes[i]=subCodes[-1] then subCodes[i]:=nil;
    for i:=-1 to high(subCodes) do if subCodes[i]<>nil then dispose(subCodes[i],destroy);
  end;

FUNCTION T_twoLevelHuffmanCode.encode(CONST s: ansistring): ansistring;
  VAR resultArr:T_bitArray;
      i:longint;
      prevSymbol:word=DEFAULT_PREV_SYMBOL;
  begin
    resultArr.create;
    for i:=1 to length(s) do begin
      subCodes[prevSymbol]^.encodeNextSymbol(s[i],resultArr);
      prevSymbol:=ord(s[i]);
    end;
    subCodes[prevSymbol]^.encodeEndOfInput(resultArr);
    result:=resultArr.getRawDataAsString;
    resultArr.destroy;
  end;

FUNCTION T_twoLevelHuffmanCode.decode(CONST s: ansistring): ansistring;
  VAR inputArr:T_bitArray;
      prevSymbol:word=DEFAULT_PREV_SYMBOL;
      nextSymbol:word;
  begin
    result:='';
    inputArr.create(s);
    while (inputArr.hasNextBit) and (prevSymbol<>END_OF_INPUT) do begin
      nextSymbol:=subCodes[prevSymbol]^.decodeNextSymbol(inputArr);
      if nextSymbol<>END_OF_INPUT then result:=result+chr(nextSymbol);
      prevSymbol:=nextSymbol;
    end;
    inputArr.destroy;
  end;

CONSTRUCTOR T_huffmanCode.create;
  VAR symbolFrequency:T_symbolFrequency;
      i,j:longint;
  begin
    for i:=0 to length(symbolFrequency)-1 do begin
      symbolFrequency[i]:=0;
      for j:=low(DEFAULT_MODEL) to high(DEFAULT_MODEL) do inc(symbolFrequency[i],DEFAULT_MODEL[j].followerFrequency[i]);
    end;
    create(true,symbolFrequency);
  end;

PROCEDURE disposeTree(VAR root:P_huffmanNode);
  begin
    if root=nil then exit;
    if root^.children[false]<>nil then disposeTree(root^.children[false]);
    if root^.children[true ]<>nil then disposeTree(root^.children[true ]);
    freeMem(root,sizeOf(T_huffmanNode));
  end;

CONSTRUCTOR T_huffmanCode.create(CONST conservative:boolean; frequency: T_symbolFrequency);
  PROCEDURE buildTreeFromLeafs(L: T_arrayOfHuffmanNode);
  VAR i,i0,i1,j:longint;
      newNode:P_huffmanNode;
  PROCEDURE traverseTree(CONST prefix:ansistring; VAR root:P_huffmanNode);
    begin
      if root^.symbol<=256
      then table[root^.symbol].parseString(prefix)
      else begin
        traverseTree(prefix+'0',root^.children[false]);
        traverseTree(prefix+'1',root^.children[true ]);
      end;
    end;

  begin
    //Build binary tree
    while length(L)>1 do begin
      i0:=0;
      i1:=1;
      for i:=2 to length(L)-1 do
        if      (L[i]^.frequency<L[i0]^.frequency) then i0:=i
        else if (L[i]^.frequency<L[i1]^.frequency) then i1:=i;
      getMem(newNode,sizeOf(T_huffmanNode));

      newNode^.symbol:=65535; //no leaf-> no symbol
      newNode^.frequency:=L[i0]^.frequency+L[i1]^.frequency;
      newNode^.children[false]:=L[i0];
      newNode^.children[true ]:=L[i1];

      j:=0;
      for i:=0 to length(L)-1 do if (i<>i0) and (i<>i1) then begin
        L[j]:=L[i];
        inc(j);
      end;
      setLength(L,length(L)-1);
      L[length(L)-1]:=newNode;
    end;

    //parse tree:
    tree:=L[0];
    traverseTree('',tree);
  end;

  PROCEDURE initModel;
    VAR parentNodes:array of P_huffmanNode;
        i:longint;
    begin
      setLength(parentNodes,END_OF_INPUT+1);
      for i:=0 to length(frequency)-1 do begin
        getMem(parentNodes[i],sizeOf(T_huffmanNode));
        parentNodes[i]^.frequency:=frequency[i];
        parentNodes[i]^.symbol:=i;
        parentNodes[i]^.children[false]:=nil;
        parentNodes[i]^.children[true ]:=nil;
      end;
      getMem(parentNodes[END_OF_INPUT],sizeOf(T_huffmanNode));
      parentNodes[END_OF_INPUT]^.frequency:=1;
      parentNodes[END_OF_INPUT]^.symbol:=END_OF_INPUT;
      parentNodes[END_OF_INPUT]^.children[false]:=nil;
      parentNodes[END_OF_INPUT]^.children[true ]:=nil;
      buildTreeFromLeafs(parentNodes);
    end;

  VAR i:longint;
      k:longint=0;
      tot:int64=0;

  begin
    //Fix frequencies:----------------------
    for i:=0 to 255 do inc(tot,frequency[i]);
    while tot>(maxLongint shr 2) do begin
      tot:=tot shr 1;
      inc(k);
    end;
    if k>0 then for i:=0 to 255 do frequency[i]:=frequency[i] shr k;
    //----------------------:Fix frequencies
    for i:=0 to length(table)-1 do table[i].create;
    tree:=nil;
    if conservative or (k>0)
    then begin for i:=0 to length(frequency)-1 do if frequency[i]<=0 then frequency[i]:=1; end
    else begin for i:=0 to length(frequency)-1 do if frequency[i]<=0 then frequency[i]:=0; end;
    initModel;
  end;

DESTRUCTOR T_huffmanCode.destroy;
  VAR i:longint;
  begin
    disposeTree(tree);
    for i:=0 to length(table)-1 do table[i].destroy;
  end;

PROCEDURE T_huffmanCode.encodeNextSymbol(CONST c: char; VAR output: T_bitArray);
  begin
    output.append(table[ord(c)]);
  end;

PROCEDURE T_huffmanCode.encodeEndOfInput(VAR output: T_bitArray);
  begin
    output.append(table[END_OF_INPUT],true);
  end;

FUNCTION T_huffmanCode.decodeNextSymbol(VAR input:T_bitArray): word;
  VAR currentNode:P_huffmanNode;
  begin
    currentNode:=tree;
    while input.hasNextBit do begin
      currentNode:=currentNode^.children[input.nextBit];
      if currentNode^.symbol<=END_OF_INPUT then exit(currentNode^.symbol);
    end;
    result:=END_OF_INPUT;
  end;

FUNCTION T_bitArray.getBit(CONST index: longint): boolean;
  VAR byteIndex:longint;
      bitMask:byte;
  begin
    if index<size then begin
      byteIndex:=index shr 3;
      bitMask:=1 shl (7-(index and 7));
      result:=data[byteIndex] and bitMask=bitMask;
    end else result:=false;
  end;

CONSTRUCTOR T_bitArray.create;
  begin
    setLength(data,0);
    datFill:=0;
    trashBits:=0;
    cursorIndex:=0;
  end;

CONSTRUCTOR T_bitArray.create(CONST rawData: ansistring);
  VAR i:longint;
  begin
    setLength(data,length(rawData));
    for i:=0 to length(data)-1 do data[i]:=ord(rawData[i+1]);
    datFill:=length(data);
    trashBits:=0;
    cursorIndex:=0;
  end;

CONSTRUCTOR T_bitArray.create(CONST prevArray: T_bitArray; CONST nextBit: boolean);
  VAR i:longint;
  begin
    setLength(data,length(prevArray.data));
    for i:=0 to length(data)-1 do data[i]:=prevArray.data[i];
    trashBits:=prevArray.trashBits;
    datFill:=prevArray.datFill;
    append(nextBit);
    cursorIndex:=0;
  end;

DESTRUCTOR T_bitArray.destroy;
  begin
    setLength(data,0);
    trashBits:=0;
  end;

PROCEDURE T_bitArray.append(CONST nextBit: boolean);
  begin
    if trashBits=0 then begin
      if datFill>=length(data) then setLength(data,1+round(1.1*datFill));
      inc(datFill);
      data[datFill-1]:=0;
      trashBits:=7;
      if nextBit then data[datFill-1]:=data[datFill-1] or (1 shl trashBits);
    end else begin
      dec(trashBits);
      if nextBit then data[datFill-1]:=data[datFill-1] or (1 shl trashBits);
    end;
  end;

PROCEDURE T_bitArray.append(CONST arr: T_bitArray; CONST finalAppend: boolean);
  VAR i:longint;
  begin
    if finalAppend then begin
      i:=0;
      while (trashBits<>0) and (i<arr.size) do begin
        append(arr[i]);
        inc(i);
      end;
    end else for i:=0 to arr.size-1 do append(arr[i]);
  end;

PROCEDURE T_bitArray.parseString(CONST stringOfZeroesAndOnes: ansistring);
  VAR i:longint;
  begin
    setLength(data,0);
    trashBits:=0;
    for i:=1 to length(stringOfZeroesAndOnes) do append(stringOfZeroesAndOnes[i]='1');
  end;

FUNCTION T_bitArray.size: longint;
  begin
    result:=datFill shl 3-trashBits;
  end;

FUNCTION T_bitArray.getRawDataAsString: ansistring;
  VAR i:longint;
  begin
    result:='';
    for i:=0 to datFill-1 do result:=result+chr(data[i]);
  end;

FUNCTION T_bitArray.getBitString: ansistring;
  VAR i:longint;
  begin
    result:='';
    for i:=0 to size-1 do if bit[i]
    then result:=result+'1'
    else result:=result+'0';
  end;

FUNCTION T_bitArray.nextBit: boolean;
  begin
    result:=getBit(cursorIndex);
    inc(cursorIndex);
  end;

FUNCTION T_bitArray.hasNextBit: boolean;
  begin
    result:=cursorIndex<size;
  end;

FUNCTION initDefault:T_twoLevelHuffmanCode; begin result.create(true); end;
FUNCTION initLucky  :T_twoLevelHuffmanCode; begin result.create(false); end;
FUNCTION initNumeric:T_twoLevelHuffmanCode; CONST NUMERIC_MODEL:{$i huffman_model_numeric.inc} begin result.create(NUMERIC_MODEL); end;
FUNCTION initWiki   :T_twoLevelHuffmanCode; CONST WIKI_MODEL   :{$i huffman_model_wiki.inc}    begin result.create(WIKI_MODEL); end;
FUNCTION initMnh    :T_twoLevelHuffmanCode; CONST MNH_MODEL    :{$i huffman_model_mnh.inc}     begin result.create(MNH_MODEL); end;
FUNCTION initBinary :T_twoLevelHuffmanCode; CONST BINARY_MODEL :{$i huffman_model_binary.inc}  begin result.create(BINARY_MODEL); end;

PROCEDURE clearCode(c:T_twoLevelHuffmanCode);
  begin
    c.destroy;
  end;

INITIALIZATION
  huffmanCode[hm_DEFAULT  ].create(@initDefault,@clearCode);
  huffmanCode[hm_LUCKY    ].create(@initLucky  ,@clearCode);
  huffmanCode[hm_NUMBERS  ].create(@initNumeric,@clearCode);
  huffmanCode[hm_WIKIPEDIA].create(@initWiki   ,@clearCode);
  huffmanCode[hm_MNH      ].create(@initMnh    ,@clearCode);
  huffmanCode[hm_BINARY   ].create(@initBinary ,@clearCode);
FINALIZATION;
  huffmanCode[hm_DEFAULT  ].destroy;
  huffmanCode[hm_LUCKY    ].destroy;
  huffmanCode[hm_NUMBERS  ].destroy;
  huffmanCode[hm_WIKIPEDIA].destroy;
  huffmanCode[hm_MNH      ].destroy;
  huffmanCode[hm_BINARY   ].destroy;
end.
