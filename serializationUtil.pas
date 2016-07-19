UNIT serializationUtil;
INTERFACE
USES Classes;
TYPE

  { T_streamWrapper }

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
      FUNCTION readDWord:dword;
      PROCEDURE writeDWord(CONST value:dword);
      FUNCTION readLongint:longint;
      PROCEDURE writeLongint(CONST value:longint);
      FUNCTION readShortint:shortint;
      PROCEDURE writeShortint(CONST value:shortint);
      FUNCTION readInt64:int64;
      PROCEDURE writeInt64(CONST value:int64);
      FUNCTION readBoolean:boolean;
      PROCEDURE writeBoolean(CONST value:boolean);
      FUNCTION readByte:byte;
      PROCEDURE writeByte(CONST value:byte);
      FUNCTION readWord:word;
      PROCEDURE writeWord(CONST value:word);
      FUNCTION readChar:char;
      PROCEDURE writeChar(CONST value:char);
      FUNCTION readDouble:double;
      PROCEDURE writeDouble(CONST value:double);
      FUNCTION readAnsiString:ansistring;
      PROCEDURE writeAnsiString(CONST value:ansistring);
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

{$MACRO ON}
{$define genericRead:=VALUE_TYPE;
begin
  try
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

{$define VALUE_TYPE:=DWord}
FUNCTION T_streamWrapper.readDWord:genericRead;
PROCEDURE T_streamWrapper.writeDWord genericWrite;
{$define VALUE_TYPE:=longint}
FUNCTION T_streamWrapper.readLongint:genericRead;
PROCEDURE T_streamWrapper.writeLongint genericWrite;
{$define VALUE_TYPE:=shortInt}
FUNCTION T_streamWrapper.readShortint:genericRead;
PROCEDURE T_streamWrapper.writeShortint genericWrite;
{$define VALUE_TYPE:=Int64}
FUNCTION T_streamWrapper.readInt64:genericRead;
PROCEDURE T_streamWrapper.writeInt64 genericWrite;
{$define VALUE_TYPE:=boolean}
FUNCTION T_streamWrapper.readBoolean:genericRead;
PROCEDURE T_streamWrapper.writeBoolean genericWrite;
{$define VALUE_TYPE:=byte}
FUNCTION T_streamWrapper.readByte:genericRead;
PROCEDURE T_streamWrapper.writeByte  genericWrite;
{$define VALUE_TYPE:=word}
FUNCTION T_streamWrapper.readWord:genericRead;
PROCEDURE T_streamWrapper.writeWord  genericWrite;
{$define VALUE_TYPE:=char}
FUNCTION T_streamWrapper.readChar:genericRead;
PROCEDURE T_streamWrapper.writeChar genericWrite;
{$define VALUE_TYPE:=double}
FUNCTION T_streamWrapper.readDouble:genericRead;
PROCEDURE T_streamWrapper.writeDouble genericWrite;

FUNCTION T_streamWrapper.readAnsiString:ansistring;
  VAR i:longint;
  begin
    setLength(result,readDWord);
    for i:=1 to length(result) do result[i]:=readChar;
  end;

PROCEDURE T_streamWrapper.writeAnsiString(CONST value:ansistring);
  VAR i:longint;
  begin
    writeLongint(length(value));
    for i:=1 to length(value) do writeChar(value[i]);
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
