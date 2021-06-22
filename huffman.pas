UNIT huffman;
INTERFACE
CONST END_OF_INPUT=256;
TYPE
  T_symbolFrequency=array[0..255] of longint;
  T_modelEntry=record previousSymbol:byte; followerFrequency:T_symbolFrequency end;
  T_arrayOfBoolean=array of boolean;
  HuffmanModel=(hm_DEFAULT,hm_LUCKY,hm_NUMBERS,hm_WIKIPEDIA,hm_MNH);
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
      PROCEDURE append(CONST nextBit:boolean); inline;
      PROCEDURE append(CONST arr:T_bitArray; CONST finalAppend:boolean=false);
      PROCEDURE parseString(CONST stringOfZeroesAndOnes:ansistring);
      FUNCTION size:longint;
      PROPERTY bit[CONST index:longint]:boolean read getBit; default;
      FUNCTION getRawDataAsString:ansistring;
      FUNCTION getBitString:ansistring;
      FUNCTION bits:T_arrayOfBoolean;
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
      initialized:boolean;
      myModel:HuffmanModel;
      codeCs:TRTLCriticalSection;
      PROCEDURE initialize(CONST conservative:boolean);
      PROCEDURE initialize(CONST model:array of T_modelEntry);
      PROCEDURE initialize;
      PROCEDURE clean;
    public
      CONSTRUCTOR create(CONST model:HuffmanModel);
      DESTRUCTOR destroy;
      FUNCTION encode(CONST s:ansistring):ansistring;
      FUNCTION decode(CONST s:ansistring):ansistring;
  end;

FUNCTION huffyDecode(CONST s:ansistring; CONST model:HuffmanModel):ansistring;
FUNCTION huffyEncode(CONST s:ansistring; CONST model:HuffmanModel):ansistring;
IMPLEMENTATION
USES mySys;
VAR huffmanCode:array[HuffmanModel] of T_twoLevelHuffmanCode;

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
    result:=huffmanCode[model].decode(s);
  end;

FUNCTION huffyEncode(CONST s: ansistring; CONST model:HuffmanModel): ansistring;
  begin
    result:=huffmanCode[model].encode(s);
  end;

CONSTRUCTOR T_twoLevelHuffmanCode.create(CONST model:HuffmanModel);
  begin
    initCriticalSection(codeCs);
    initialized:=false;
    myModel:=model;
    memoryCleaner.registerObjectForCleanup(1,@clean);
  end;

CONST DEFAULT_MODEL:{$i huffman_model_default.inc}

PROCEDURE T_twoLevelHuffmanCode.initialize;
  CONST NUMERIC_MODEL:{$i huffman_model_numeric.inc}
  CONST WIKI_MODEL   :{$i huffman_model_wiki.inc}
  CONST MNH_MODEL    :{$i huffman_model_mnh.inc}
  begin
    enterCriticalSection(codeCs);
    try
      if not(initialized) then case myModel of
        hm_DEFAULT  : initialize(true);
        hm_LUCKY    : initialize(false);
        hm_NUMBERS  : initialize(NUMERIC_MODEL);
        hm_WIKIPEDIA: initialize(WIKI_MODEL);
        hm_MNH      : initialize(MNH_MODEL);
      end;
    finally
      leaveCriticalSection(codeCs);
    end;
  end;

PROCEDURE T_twoLevelHuffmanCode.initialize(CONST conservative:boolean);
  VAR i:longint;
  begin
    new(subCodes[-1],create);
    for i:=0 to 255 do subCodes[i]:=nil;
    for i:=0 to length(DEFAULT_MODEL)-1 do
      new(subCodes[DEFAULT_MODEL[i].previousSymbol],create(conservative,DEFAULT_MODEL[i].followerFrequency));
    for i:=0 to 255 do if (subCodes[i]=nil) then subCodes[i]:=subCodes[-1];
    initialized:=true;
  end;

PROCEDURE T_twoLevelHuffmanCode.initialize(CONST model:array of T_modelEntry);
  VAR fallbackModel:T_symbolFrequency;
      m:T_modelEntry;
      k:longint;
      i:longint;
      initCount:longint=0;
  begin
    for i:= 0 to 255 do fallbackModel[i]:=0;
    for i:=-1 to 255 do subCodes     [i]:=nil;

    for i:=0 to 255 do if subCodes[i]=nil then
    for k:=0 to length(model)-1 do
    if model[k].previousSymbol=i then begin
      m:=model[k];
      if subCodes[i]=nil then begin
        new(subCodes[i],create(false,m.followerFrequency));
        inc(initCount);
        fallbackModel+=m.followerFrequency;
      end else writeln('DUPLICATE MODEL ENTRY FOR previousSymbol=',i,' at index ',k);
    end;
    //All initialized, no fallback needed
    if initCount>=256 then exit;
    //Fill gaps by using default model:
    for i:=0 to 255 do if subCodes[i]=nil then
    for k:=0 to length(DEFAULT_MODEL)-1 do
    if DEFAULT_MODEL[k].previousSymbol=i then begin
      m:=DEFAULT_MODEL[k];
      new(subCodes[i],create(true,m.followerFrequency));
      inc(initCount);
      fallbackModel+=m.followerFrequency;
    end;
    //All initialized, no further fallback needed
    if initCount>=256 then exit;
    //Fill gaps by using fallback model
    new(subCodes[-1],create(true,fallbackModel));
    for i:=0 to 255 do if subCodes[i]=nil then begin
      subCodes[i]:=subCodes[-1];
    end;
    initialized:=true;
  end;

PROCEDURE T_twoLevelHuffmanCode.clean;
  VAR i:longint;
  begin
    enterCriticalSection(codeCs);
    try
      if initialized then begin
        for i:= 0 to 255 do if subCodes[i]=subCodes[-1] then subCodes[i]:=nil;
        for i:=-1 to 255 do if subCodes[i]<>nil then dispose(subCodes[i],destroy);
      end;
      initialized:=false;
    finally
      leaveCriticalSection(codeCs);
    end;
  end;

DESTRUCTOR T_twoLevelHuffmanCode.destroy;
  begin
    memoryCleaner.unregisterObjectForCleanup(@clean);
    clean;
    doneCriticalSection(codeCs);
  end;

FUNCTION T_twoLevelHuffmanCode.encode(CONST s: ansistring): ansistring;
  VAR resultArr:T_bitArray;
      i:longint;
      prevSymbol:word=DEFAULT_PREV_SYMBOL;
  begin
    enterCriticalSection(codeCs);
    initialize;
    try
      resultArr.create;
      for i:=1 to length(s) do begin
        subCodes[prevSymbol]^.encodeNextSymbol(s[i],resultArr);
        prevSymbol:=ord(s[i]);
      end;
      subCodes[prevSymbol]^.encodeEndOfInput(resultArr);
      result:=resultArr.getRawDataAsString;
      resultArr.destroy;
    finally
      leaveCriticalSection(codeCs);
    end;
  end;

FUNCTION T_twoLevelHuffmanCode.decode(CONST s: ansistring): ansistring;
  VAR inputArr:T_bitArray;
      prevSymbol:word=DEFAULT_PREV_SYMBOL;
      nextSymbol:word;
  begin
    enterCriticalSection(codeCs);
    initialize;
    try
      result:='';
      inputArr.create(s);
      while (inputArr.hasNextBit) and (prevSymbol<>END_OF_INPUT) do begin
        nextSymbol:=subCodes[prevSymbol]^.decodeNextSymbol(inputArr);
        if nextSymbol<>END_OF_INPUT then result:=result+chr(nextSymbol);
        prevSymbol:=nextSymbol;
      end;
      inputArr.destroy;
    finally
      leaveCriticalSection(codeCs);
    end;
  end;

CONSTRUCTOR T_huffmanCode.create;
  VAR symbolFrequency:T_symbolFrequency;
      entry:T_modelEntry;
      i:longint;
  begin
    for i:=0 to 255 do symbolFrequency[i]:=0;
    for entry in DEFAULT_MODEL do symbolFrequency+=entry.followerFrequency;
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
    VAR parentNodes:array of P_huffmanNode=();
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
      b:boolean;
  begin
    if finalAppend then begin
      i:=0;
      while (trashBits<>0) and (i<arr.size) do begin
        append(arr[i]);
        inc(i);
      end;
    end else for b in arr.bits do append(b);
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

FUNCTION T_bitArray.bits:T_arrayOfBoolean;
  CONST M:array[0..7] of byte=(1, 2, 4,  8,
                              16,32,64,128);
  VAR i:longint;
      k:longint=0;
  begin
    initialize(result);
    setLength(result,datFill shl 3);
    for i:=0 to datFill-1 do begin
      result[k]:=(data[i] and M[7])>0; inc(k);
      result[k]:=(data[i] and M[6])>0; inc(k);
      result[k]:=(data[i] and M[5])>0; inc(k);
      result[k]:=(data[i] and M[4])>0; inc(k);
      result[k]:=(data[i] and M[3])>0; inc(k);
      result[k]:=(data[i] and M[2])>0; inc(k);
      result[k]:=(data[i] and M[1])>0; inc(k);
      result[k]:=(data[i] and M[0])>0; inc(k);
    end;
    setLength(result,size);
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

INITIALIZATION
  huffmanCode[hm_DEFAULT  ].create(hm_DEFAULT  );
  huffmanCode[hm_LUCKY    ].create(hm_LUCKY    );
  huffmanCode[hm_NUMBERS  ].create(hm_NUMBERS  );
  huffmanCode[hm_WIKIPEDIA].create(hm_WIKIPEDIA);
  huffmanCode[hm_MNH      ].create(hm_MNH      );
FINALIZATION
  huffmanCode[hm_DEFAULT  ].destroy;
  huffmanCode[hm_LUCKY    ].destroy;
  huffmanCode[hm_NUMBERS  ].destroy;
  huffmanCode[hm_WIKIPEDIA].destroy;
  huffmanCode[hm_MNH      ].destroy;
end.
