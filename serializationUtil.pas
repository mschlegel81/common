UNIT serializationUtil;
INTERFACE
USES Classes;
TYPE

  T_streamWrapper=object
    private
      stream:TStream;
      wrongTypeError,earlyEndOfFileError,fileAccessError:boolean;
    public
      CONSTRUCTOR create(CONST stream_:TStream);
      CONSTRUCTOR createToReadFromFile(CONST fileName:string);
      CONSTRUCTOR createToWriteToFile(CONST fileName:string);
      DESTRUCTOR destroy;
      FUNCTION hasWrongTypeError:boolean;
      FUNCTION hasEarlyEndOfFileError:boolean;
      FUNCTION hasFileAccessError:boolean;
      PROCEDURE logWrongTypeError;
      FUNCTION allOkay:boolean;
      FUNCTION streamPosition:int64;
      PROCEDURE jumpToStreamPosition(CONST position:int64);

      FUNCTION readBoolean:boolean;
      PROCEDURE writeBoolean(CONST value:boolean);
      FUNCTION readByte:byte;
      PROCEDURE writeByte(CONST value:byte);
      FUNCTION readWord:word;
      PROCEDURE writeWord(CONST value:word);
      FUNCTION readDWord:dword;
      PROCEDURE writeDWord(CONST value:dword);
      FUNCTION readQWord:qword;
      PROCEDURE writeQWord(CONST value:qword);

      FUNCTION readShortint:shortint;
      PROCEDURE writeShortint(CONST value:shortint);
      FUNCTION readLongint:longint;
      PROCEDURE writeLongint(CONST value:longint);
      FUNCTION readInt64:int64;
      PROCEDURE writeInt64(CONST value:int64);

      FUNCTION readDouble:double;
      PROCEDURE writeDouble(CONST value:double);
      FUNCTION readSingle:single;
      PROCEDURE writeSingle(CONST value:single);

      FUNCTION readChar:char;
      PROCEDURE writeChar(CONST value:char);
      FUNCTION readAnsiString:ansistring;
      PROCEDURE writeAnsiString(CONST value:ansistring);

      FUNCTION readNaturalNumber:qword;
      PROCEDURE writeNaturalNumber(CONST value:qword);
  end;

  T_serializable=object
    FUNCTION getSerialVersion:dword; virtual; abstract;
    FUNCTION loadFromStream(VAR stream:T_streamWrapper):boolean; virtual;
    PROCEDURE saveToStream(VAR stream:T_streamWrapper); virtual;

    FUNCTION loadFromFile(CONST fileName:string):boolean;
    PROCEDURE saveToFile(CONST fileName:string);
  end;

IMPLEMENTATION
CONSTRUCTOR T_streamWrapper.create(CONST stream_: TStream);
  begin
    stream:=stream_;
    fileAccessError:=false;
    wrongTypeError:=false;
    earlyEndOfFileError:=false;
  end;

CONSTRUCTOR T_streamWrapper.createToReadFromFile(CONST fileName: string);
  begin
    fileAccessError:=false;
    wrongTypeError:=false;
    earlyEndOfFileError:=false;
    try
      stream:=TFileStream.create(fileName,fmOpenRead);
    except
      fileAccessError:=true;
      try
        stream.destroy;
      except
      end;
      stream:=nil;
    end;
  end;

CONSTRUCTOR T_streamWrapper.createToWriteToFile(CONST fileName: string);
  begin
    fileAccessError:=false;
    wrongTypeError:=false;
    earlyEndOfFileError:=false;
    try
      stream:=TFileStream.create(fileName,fmCreate);
    except
      fileAccessError:=true;
      try
        stream.destroy;
      except
      end;
      stream:=nil;
    end;
  end;

DESTRUCTOR T_streamWrapper.destroy;
  begin
    if stream<>nil then stream.destroy;
  end;

FUNCTION T_streamWrapper.hasWrongTypeError: boolean;
  begin
    result:=wrongTypeError;
  end;

FUNCTION T_streamWrapper.hasEarlyEndOfFileError: boolean;
  begin
    result:=earlyEndOfFileError;
  end;

FUNCTION T_streamWrapper.hasFileAccessError: boolean;
  begin
    result:=fileAccessError;
  end;

PROCEDURE T_streamWrapper.logWrongTypeError;
  begin
    wrongTypeError:=true;
  end;

FUNCTION T_streamWrapper.allOkay: boolean;
  begin
    result:=not(wrongTypeError or earlyEndOfFileError or fileAccessError);
  end;

FUNCTION T_streamWrapper.streamPosition:int64;
  begin
    result:=stream.position;
  end;

PROCEDURE T_streamWrapper.jumpToStreamPosition(CONST position:int64);
  begin
    stream.position:=position;
  end;

{$MACRO ON}
{$define genericRead:=VALUE_TYPE;
begin
  try
    initialize(result);
    if stream.read(result,sizeOf(result))<>sizeOf(result)
    then earlyEndOfFileError:=true;
  except
    fileAccessError:=true;
  end;
end}
{$define genericWrite:=(CONST value:VALUE_TYPE);
begin
  try
    if stream.write(value,sizeOf(value))<>sizeOf(value)
    then fileAccessError:=true;
  except
    fileAccessError:=true;
  end;
end}

{$define VALUE_TYPE:=boolean}
FUNCTION T_streamWrapper.readBoolean:genericRead;
PROCEDURE T_streamWrapper.writeBoolean genericWrite;
{$define VALUE_TYPE:=byte}
FUNCTION T_streamWrapper.readByte:genericRead;
PROCEDURE T_streamWrapper.writeByte  genericWrite;
{$define VALUE_TYPE:=word}
FUNCTION T_streamWrapper.readWord:genericRead;
PROCEDURE T_streamWrapper.writeWord  genericWrite;
{$define VALUE_TYPE:=DWord}
FUNCTION T_streamWrapper.readDWord:genericRead;
PROCEDURE T_streamWrapper.writeDWord genericWrite;
{$define VALUE_TYPE:=QWord}
FUNCTION T_streamWrapper.readQWord:genericRead;
PROCEDURE T_streamWrapper.writeQWord genericWrite;
{$define VALUE_TYPE:=shortInt}
FUNCTION T_streamWrapper.readShortint:genericRead;
PROCEDURE T_streamWrapper.writeShortint genericWrite;
{$define VALUE_TYPE:=longint}
FUNCTION T_streamWrapper.readLongint:genericRead;
PROCEDURE T_streamWrapper.writeLongint genericWrite;
{$define VALUE_TYPE:=Int64}
FUNCTION T_streamWrapper.readInt64:genericRead;
PROCEDURE T_streamWrapper.writeInt64 genericWrite;
{$define VALUE_TYPE:=single}
FUNCTION T_streamWrapper.readSingle:genericRead;
PROCEDURE T_streamWrapper.writeSingle genericWrite;
{$define VALUE_TYPE:=double}
FUNCTION T_streamWrapper.readDouble:genericRead;
PROCEDURE T_streamWrapper.writeDouble genericWrite;
{$define VALUE_TYPE:=char}
FUNCTION T_streamWrapper.readChar:genericRead;
PROCEDURE T_streamWrapper.writeChar genericWrite;

FUNCTION T_streamWrapper.readAnsiString:ansistring;
  VAR i:longint;
  begin
    setLength(result,readNaturalNumber);
    for i:=1 to length(result) do if not(earlyEndOfFileError) then result[i]:=readChar;
    if earlyEndOfFileError then result:='';
  end;

PROCEDURE T_streamWrapper.writeAnsiString(CONST value:ansistring);
  VAR i:longint;
  begin
    writeNaturalNumber(length(value));
    for i:=1 to length(value) do writeChar(value[i]);
  end;

FUNCTION T_streamWrapper.readNaturalNumber:qword;
  begin
    result:=readByte;
    if result>=128 then result:=result and 127 + (readNaturalNumber() shl 7);
  end;

PROCEDURE T_streamWrapper.writeNaturalNumber(CONST value:qword);
  begin
    if value<=127
    then writeByte(value)
    else begin
      writeByte((value and 127) or 128);
      writeNaturalNumber(value shr 7);
    end;
  end;

FUNCTION T_serializable.loadFromFile(CONST fileName: string): boolean;
  VAR stream:T_streamWrapper;
  begin
    stream.createToReadFromFile(fileName);
    result:=stream.allOkay and loadFromStream(stream);
    stream.destroy;
  end;

FUNCTION T_serializable.loadFromStream(VAR stream:T_streamWrapper): boolean;
  begin
    result:=stream.readDWord=getSerialVersion;
    if not(result) then stream.wrongTypeError:=true;
  end;

PROCEDURE T_serializable.saveToFile(CONST fileName: string);
  VAR stream:T_streamWrapper;
  begin
    stream.createToWriteToFile(fileName);
    saveToStream(stream);
    stream.destroy;
  end;

PROCEDURE T_serializable.saveToStream(VAR stream:T_streamWrapper);
  begin
    stream.writeDWord(getSerialVersion);
  end;



end.
