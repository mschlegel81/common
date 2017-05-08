UNIT serializationUtil;
INTERFACE
USES Classes;
CONST C_bufferSize=4096;
TYPE
  T_abstractStreamWrapper=object
    private
      wrongTypeError     ,
      earlyEndOfFileError,
      fileAccessError    :boolean;
    public
      CONSTRUCTOR create;
      DESTRUCTOR destroy;
      PROPERTY hasWrongTypeError     :boolean read wrongTypeError     ;
      PROPERTY hasEarlyEndOfFileError:boolean read earlyEndOfFileError;
      PROPERTY hasFileAccessError    :boolean read fileAccessError    ;
      PROCEDURE logWrongTypeError;
      FUNCTION allOkay:boolean;
  end;

  P_inputStreamWrapper=^T_inputStreamWrapper;
  T_inputStreamWrapper=object(T_abstractStreamWrapper)
    private
      stream:TStream;
      PROCEDURE read(VAR targetBuffer; CONST count: longint); virtual;
    public
      CONSTRUCTOR create(CONST stream_:TStream);
      CONSTRUCTOR createToReadFromFile(CONST fileName:string);
      DESTRUCTOR destroy;

      FUNCTION readBoolean:boolean;
      FUNCTION readByte:byte;
      FUNCTION readWord:word;
      FUNCTION readDWord:dword;
      FUNCTION readQWord:qword;
      FUNCTION readShortint:shortint;
      FUNCTION readLongint:longint;
      FUNCTION readInt64:int64;
      FUNCTION readDouble:double;
      FUNCTION readSingle:single;
      FUNCTION readChar:char;
      FUNCTION readAnsiString:ansistring;
      FUNCTION readNaturalNumber:qword;
  end;

  P_bufferedInputStreamWrapper=^T_bufferedInputStreamWrapper;
  T_bufferedInputStreamWrapper=object(T_inputStreamWrapper)
    private
      buffer:array[0..C_bufferSize-1] of byte;
      bufferFill:longint;
      PROCEDURE read(VAR targetBuffer; CONST count: longint); virtual;
    public
      CONSTRUCTOR create(CONST stream_:TStream);
      CONSTRUCTOR createToReadFromFile(CONST fileName:string);
      DESTRUCTOR destroy;
  end;

  P_outputStreamWrapper=^T_outputStreamWrapper;
  T_outputStreamWrapper=object(T_abstractStreamWrapper)
    private
      stream:TStream;
      PROCEDURE write(CONST sourceBuffer; CONST count: longint); virtual;
    public
      CONSTRUCTOR create(CONST stream_:TStream);
      CONSTRUCTOR createToWriteToFile(CONST fileName:string);
      DESTRUCTOR destroy;

      PROCEDURE writeBoolean(CONST value:boolean);
      PROCEDURE writeByte(CONST value:byte);
      PROCEDURE writeWord(CONST value:word);
      PROCEDURE writeDWord(CONST value:dword);
      PROCEDURE writeQWord(CONST value:qword);
      PROCEDURE writeShortint(CONST value:shortint);
      PROCEDURE writeLongint(CONST value:longint);
      PROCEDURE writeInt64(CONST value:int64);
      PROCEDURE writeDouble(CONST value:double);
      PROCEDURE writeSingle(CONST value:single);
      PROCEDURE writeChar(CONST value:char);
      PROCEDURE writeAnsiString(CONST value:ansistring);
      PROCEDURE writeNaturalNumber(CONST value:qword);
  end;

  P_bufferedOutputStreamWrapper=^T_bufferedOutputStreamWrapper;
  T_bufferedOutputStreamWrapper=object(T_outputStreamWrapper)
    private
      buffer:array[0..C_bufferSize-1] of byte;
      bufferFill:longint;
      PROCEDURE write(CONST sourceBuffer; CONST count: longint); virtual;
    public
      PROCEDURE flush;
      CONSTRUCTOR create(CONST stream_:TStream);
      CONSTRUCTOR createToWriteToFile(CONST fileName:string);
      DESTRUCTOR destroy;
  end;

  T_serializable=object
    FUNCTION getSerialVersion:dword; virtual; abstract;
    FUNCTION loadFromStream(VAR stream:T_bufferedInputStreamWrapper):boolean; virtual;
    PROCEDURE saveToStream(VAR stream:T_bufferedOutputStreamWrapper); virtual;

    FUNCTION loadFromFile(CONST fileName:string):boolean;
    PROCEDURE saveToFile(CONST fileName:string);
  end;

IMPLEMENTATION
CONSTRUCTOR T_abstractStreamWrapper.create;
  begin
    wrongTypeError     :=false;
    earlyEndOfFileError:=false;
    fileAccessError    :=false;
  end;

DESTRUCTOR T_abstractStreamWrapper.destroy;
  begin
  end;

PROCEDURE T_abstractStreamWrapper.logWrongTypeError;
  begin
    wrongTypeError:=true;
  end;

FUNCTION T_abstractStreamWrapper.allOkay: boolean;
  begin
    result:=not(wrongTypeError or earlyEndOfFileError or fileAccessError);
  end;

PROCEDURE T_inputStreamWrapper.read(VAR targetBuffer; CONST count: longint);
  begin
    try
      if stream.read(targetBuffer,count)<>count
      then earlyEndOfFileError:=true;
    except
      fileAccessError:=true;
    end;
  end;

CONSTRUCTOR T_inputStreamWrapper.create(CONST stream_: TStream);
  begin
    inherited create;
    stream:=stream_;
  end;

CONSTRUCTOR T_inputStreamWrapper.createToReadFromFile(CONST fileName: string);
  begin
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

DESTRUCTOR T_inputStreamWrapper.destroy;
  begin
    if stream<>nil then stream.destroy;
  end;

FUNCTION T_inputStreamWrapper.readBoolean: boolean;   begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readByte: byte;         begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readWord: word;         begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readDWord: dword;       begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readQWord: qword;       begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readShortint: shortint; begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readLongint: longint;   begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readInt64: int64;       begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readDouble: double;     begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readSingle: single;     begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readChar: char;         begin initialize(result); read(result,sizeOf(result)); end;
FUNCTION T_inputStreamWrapper.readAnsiString: ansistring;
  VAR i:longint;
  begin
    setLength(result,readNaturalNumber);
    for i:=1 to length(result) do if not(earlyEndOfFileError) then result[i]:=readChar;
    if earlyEndOfFileError then result:='';
  end;

FUNCTION T_inputStreamWrapper.readNaturalNumber: qword;
  begin
    result:=readByte;
    if result>=128 then result:=result and 127 + (readNaturalNumber() shl 7);
  end;

PROCEDURE T_bufferedInputStreamWrapper.read(VAR targetBuffer; CONST count: longint);
  VAR toRead,actuallyRead:longint;
  begin
    if count>bufferFill then begin
      toRead:=length(buffer)-bufferFill;
      try
        actuallyRead:=stream.read(buffer[bufferFill],toRead);
      except
        fileAccessError:=true;
        exit;
      end;
      inc(bufferFill,actuallyRead);
    end;
    if count>bufferFill
    then earlyEndOfFileError:=true
    else begin
      move(buffer,targetBuffer,count);
      move(buffer[count],buffer,bufferFill-count);
      dec(bufferFill,count);
    end;
  end;

CONSTRUCTOR T_bufferedInputStreamWrapper.create(CONST stream_: TStream);
  begin
    inherited create(stream_);
    bufferFill:=0;
  end;

CONSTRUCTOR T_bufferedInputStreamWrapper.createToReadFromFile(CONST fileName: string);
  begin
    inherited createToReadFromFile(fileName);
    bufferFill:=0;
  end;

DESTRUCTOR T_bufferedInputStreamWrapper.destroy;
  begin inherited destroy; end;

PROCEDURE T_outputStreamWrapper.write(CONST sourceBuffer; CONST count: longint);
  begin
    try
      if stream.write(sourceBuffer,count)<>count
      then fileAccessError:=true;
    except
      fileAccessError:=true;
    end;
  end;

CONSTRUCTOR T_outputStreamWrapper.create(CONST stream_: TStream);
  begin
    inherited create;
    stream:=stream_;
  end;

CONSTRUCTOR T_outputStreamWrapper.createToWriteToFile(CONST fileName: string);
  begin
    inherited create;
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

DESTRUCTOR T_outputStreamWrapper.destroy;
  begin
    if stream<>nil then stream.destroy;
  end;

PROCEDURE T_outputStreamWrapper.writeBoolean(CONST value: boolean);   begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeByte(CONST value: byte);         begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeWord(CONST value: word);         begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeDWord(CONST value: dword);       begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeQWord(CONST value: qword);       begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeShortint(CONST value: shortint); begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeLongint(CONST value: longint);   begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeInt64(CONST value: int64);       begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeDouble(CONST value: double);     begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeSingle(CONST value: single);     begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeChar(CONST value: char);         begin write(value,sizeOf(value)); end;
PROCEDURE T_outputStreamWrapper.writeAnsiString(CONST value: ansistring);
  VAR i:longint;
  begin
    writeNaturalNumber(length(value));
    for i:=1 to length(value) do writeChar(value[i]);
  end;

PROCEDURE T_outputStreamWrapper.writeNaturalNumber(CONST value: qword);
  begin
    if value<=127
    then writeByte(value)
    else begin
      writeByte((value and 127) or 128);
      writeNaturalNumber(value shr 7);
    end;
  end;

PROCEDURE T_bufferedOutputStreamWrapper.flush;
  begin
    inherited write(buffer,bufferFill);
    bufferFill:=0;
  end;

PROCEDURE T_bufferedOutputStreamWrapper.write(CONST sourceBuffer; CONST count: longint);
  begin
    if bufferFill+count>length(buffer) then flush;
    move(sourceBuffer,buffer[bufferFill],count);
    inc(bufferFill,count);
  end;

CONSTRUCTOR T_bufferedOutputStreamWrapper.create(CONST stream_: TStream);
  begin
    inherited create(stream_);
    bufferFill:=0;
  end;

CONSTRUCTOR T_bufferedOutputStreamWrapper.createToWriteToFile(CONST fileName: string);
  begin
    inherited createToWriteToFile(fileName);
    bufferFill:=0;
  end;

DESTRUCTOR T_bufferedOutputStreamWrapper.destroy;
  begin
    flush;
    inherited destroy;
  end;

FUNCTION T_serializable.loadFromFile(CONST fileName: string): boolean;
  VAR stream:T_bufferedInputStreamWrapper;
  begin
    stream.createToReadFromFile(fileName);
    result:=stream.allOkay and loadFromStream(stream);
    stream.destroy;
  end;

FUNCTION T_serializable.loadFromStream(VAR stream:T_bufferedInputStreamWrapper): boolean;
  begin
    result:=stream.readDWord=getSerialVersion;
    if not(result) then stream.wrongTypeError:=true;
  end;

PROCEDURE T_serializable.saveToFile(CONST fileName: string);
  VAR stream:T_bufferedOutputStreamWrapper;
  begin
    stream.createToWriteToFile(fileName);
    saveToStream(stream);
    stream.flush;
    stream.destroy;
  end;

PROCEDURE T_serializable.saveToStream(VAR stream:T_bufferedOutputStreamWrapper);
  begin
    stream.writeDWord(getSerialVersion);
  end;

end.
