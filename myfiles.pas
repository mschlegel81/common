UNIT myFiles;
INTERFACE
USES sysutils;
{$MACRO ON}
CONST bufferSize=1000;
TYPE

  T_file=object
    private
      readMode,stateOkay:boolean;
      handle:file of byte;
      buffer:array[0..bufferSize-1] of byte;
      bufFill:longint;
      PROCEDURE flushBuffer;
      PROCEDURE readBuffer;
    public

    CONSTRUCTOR createToRead (fileName:string);
    CONSTRUCTOR createToWrite(fileName:string);
    DESTRUCTOR  destroy;
    FUNCTION    allOkay:boolean;

    PROCEDURE writeByte(x:byte);
    FUNCTION   readByte  :byte;
    PROCEDURE writeBoolean(x:boolean);
    FUNCTION   readBoolean:boolean;
    PROCEDURE writeWord(x:word);
    FUNCTION   readWord  :word;
    PROCEDURE writeDWord(x:dword);
    FUNCTION   readDWord  :dword;
    PROCEDURE writeQWord(x:qword);
    FUNCTION   readQWord  :qword;
    PROCEDURE writeLongint(x:longint);
    FUNCTION   readLongint  :longint;
    PROCEDURE writeShortint(x:shortint);
    FUNCTION   readShortint  :shortint;
    PROCEDURE writeChar(x:char);
    FUNCTION   readChar  :char;
    PROCEDURE writeSingle(x:single);
    FUNCTION   readSingle  :single;
    PROCEDURE writeDouble(x:double);
    FUNCTION   readDouble  :double;
    PROCEDURE writeExtended(x:extended);
    FUNCTION   readExtended  :extended;

    PROCEDURE writeShortstring(x:shortString);
    FUNCTION   readShortstring  :shortString;
    PROCEDURE writeAnsiString (x:ansistring);
    FUNCTION   readAnsiString   :ansistring;
    PROCEDURE writeBuf(p:PByte; pSize:longint);
    PROCEDURE readBuf (p:PByte; pSize:longint);
  end;

  T_serializable=object
    CONSTRUCTOR notReallyAConstructor;
    FUNCTION  loadFromFile(fileName:string):boolean;                 overload; //liest die Inhalte des Objektes aus der Datei mit dem übergebenen Namen und gibt true zurück gdw. kein Fehler auftrat
    PROCEDURE saveToFile(fileName:string);                           overload; //schreibt die Inhalte des Objektes in die Datei mit dem übergebenen Namen
    FUNCTION  loadFromFile(VAR F:T_file):boolean; virtual; abstract; overload; //liest die Inhalte des Objektes aus einer bereits geöffneten Datei und gibt true zurück gdw. kein Fehler auftrat
    PROCEDURE saveToFile(VAR F:T_file);           virtual; abstract; overload; //schreibt die Inhalte des Objektes in eine bereits geöffnete Datei

  end;

IMPLEMENTATION
PROCEDURE T_file.flushBuffer;
  begin
    if not(readMode) and stateOkay then begin
      BlockWrite(handle,buffer,bufFill);
      bufFill:=0;
    end;
  end;

PROCEDURE T_file.readBuffer;
  VAR actuallyRead:longint;
  begin
    if readMode and stateOkay then begin
      BlockRead(handle,buffer[bufFill],bufferSize-bufFill,actuallyRead);
      bufFill:=bufFill+actuallyRead;
    end;
  end;

CONSTRUCTOR T_file.createToRead (fileName:string);
  begin
    readMode:=true;
    bufFill:=0;
    if fileExists(fileName) then begin
      assign(handle,fileName);
      reset(handle);
      readBuffer;
      stateOkay:=true;
    end else stateOkay:=false;
  end;

CONSTRUCTOR T_file.createToWrite(fileName:string);
  begin
    try
      readMode:=false;
      assign(handle,fileName);
      rewrite(handle);
      bufFill:=0;
      stateOkay:=true;
    except stateOkay:=false; end;
  end;

DESTRUCTOR  T_file.destroy;
  begin
    if not(readMode) then flushBuffer;
    close(handle);
  end;

FUNCTION    T_file.allOkay:boolean;
  begin
    result:=stateOkay;
  end;

{$define macro_genericWrite:=
  begin
    if bufFill+sizeOf(x)>bufferSize then flushBuffer;
    if stateOkay then move(x,buffer[bufFill],sizeOf(x));
    inc(bufFill,sizeOf(x));
  end}
{$define macro_genericRead:=
  begin
    if stateOkay then begin
      if bufFill<sizeOf(result) then readBuffer;
      stateOkay:=stateOkay and (bufFill>=sizeOf(result));
      move(buffer[0],result,sizeOf(result));
      move(buffer[sizeOf(result)],buffer[0],bufFill-sizeOf(result));
      dec(bufFill,sizeOf(result));
    end;
  end}

PROCEDURE T_file.writeByte    (x:byte    ); macro_genericWrite;
FUNCTION  T_file. readByte      :byte     ; macro_genericRead;
PROCEDURE T_file.writeWord    (x:word    ); macro_genericWrite;
FUNCTION  T_file. readWord      :word     ; macro_genericRead;
PROCEDURE T_file.writeDWord   (x:dword   ); macro_genericWrite;
FUNCTION  T_file. readDWord     :dword    ; macro_genericRead;
PROCEDURE T_file.writeQWord   (x:qword   ); macro_genericWrite;
FUNCTION  T_file. readQWord     :qword    ; macro_genericRead;
PROCEDURE T_file.writeLongint (x:longint ); macro_genericWrite;
FUNCTION  T_file. readLongint   :longint  ; macro_genericRead;
PROCEDURE T_file.writeShortint(x:shortint); macro_genericWrite;
FUNCTION  T_file. readShortint  :shortint ; macro_genericRead;
PROCEDURE T_file.writeChar    (x:char    ); macro_genericWrite;
FUNCTION  T_file. readChar      :char     ; macro_genericRead;
PROCEDURE T_file.writeSingle  (x:single  ); macro_genericWrite;
FUNCTION  T_file. readSingle    :single   ; macro_genericRead;
PROCEDURE T_file.writeDouble  (x:double  ); macro_genericWrite;
FUNCTION  T_file. readDouble    :double   ; macro_genericRead;
PROCEDURE T_file.writeExtended(x:extended); macro_genericWrite;
FUNCTION  T_file. readExtended  :extended ; macro_genericRead;

PROCEDURE T_file.writeShortstring(x:shortString);
  VAR i:longint;
  begin
    writeByte(length(x));
    for i:=1 to length(x) do writeChar(x[i]);
  end;

FUNCTION  T_file. readShortstring  :shortString;
  VAR i:longint;
      charsToRead:byte;
  begin
    charsToRead:=readByte;
    result:='';
    for i:=1 to charsToRead do result:=result+readChar;
  end;

PROCEDURE T_file.writeAnsiString (x:ansistring);
  VAR i:longint;
  begin
    writeWord(length(x));
    for i:=1 to length(x) do writeChar(x[i]);
  end;

FUNCTION  T_file. readAnsiString   :ansistring;
  VAR i:longint;
      charsToRead:word;
  begin
    charsToRead:=readWord;
    result:='';
    for i:=1 to charsToRead do result:=result+readChar;
  end;

PROCEDURE T_file.writeBoolean(x:boolean);
  begin
    if x then writeByte(255) else writeByte(0);
  end;

FUNCTION  T_file.readBoolean:boolean;
  VAR b:byte;
  begin
    b:=readByte;
    result:=(b=255);
    stateOkay:=stateOkay and (b in [0,255]);
  end;

PROCEDURE T_file.writeBuf(p:PByte; pSize:longint);
  begin
    if not(readMode) then begin
      flushBuffer;                 //write all that is stored in buffer
      BlockWrite(handle,p^,pSize); //write bytes from pointer
    end;
  end;

PROCEDURE T_file.readBuf (p:PByte; pSize:longint);
  VAR actuallyRead:longint;
  begin
    if readMode then begin
      if bufFill>=pSize then begin //if buffer contains enough data...
        move(buffer[0],p^,pSize);                    //move data from buffer to pointer
        move(buffer[pSize],buffer[0],bufFill-pSize); //buffer shift
        dec(bufFill,pSize);                          //decrement buffer-fill
      end else begin               //if buffer contains less than necessary...
        move(buffer[0],p^,bufFill);                                //read first bytes from buffer
        BlockRead(handle,(p+bufFill)^,pSize-bufFill,actuallyRead); //read remaining bytes from file
        stateOkay:=stateOkay and (actuallyRead=pSize-bufFill);     //check the number of sucessfully read bytes
        bufFill:=0;                                                //buffer is empty now
      end;
    end;
  end;

CONSTRUCTOR T_serializable.notReallyAConstructor; begin end;
FUNCTION    T_serializable.loadFromFile(fileName:string):boolean;
  VAR ff:T_file;
  begin
    if fileExists(fileName) then begin
      ff.createToRead(fileName);
      result:=loadFromFile(ff);
      ff.destroy;
    end else result:=false;
  end;

PROCEDURE T_serializable.saveToFile(fileName:string);
  VAR ff:T_file;
  begin
    ff.createToWrite(fileName);
    saveToFile(ff);
    ff.destroy;
  end;


end.
