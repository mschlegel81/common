{==============================================================================|
| project : Ararat Synapse                                       | 004.000.000 |
|==============================================================================|
| content: SNMP Client                                                         |
|==============================================================================|
| Copyright (c)1999-2011, Lukas Gebauer                                        |
| all rights reserved.                                                         |
|                                                                              |
| Redistribution and use in Source and binary Forms, with or without           |
| modification, are permitted provided that the following conditions are met:  |
|                                                                              |
| Redistributions of Source code must retain the above copyright notice, this  |
| list of conditions and the following disclaimer.                             |
|                                                                              |
| Redistributions in binary form must reproduce the above copyright notice,    |
| this list of conditions and the following disclaimer in the documentation    |
| and/or other materials provided with the distribution.                       |
|                                                                              |
| Neither the name of Lukas Gebauer nor the names of its contributors may      |
| be used to endorse or promote products derived from this software without    |
| specific prior written permission.                                           |
|                                                                              |
| THIS SOFTWARE IS PROVIDED by the COPYRIGHT HOLDERS and CONTRIBUTORS "AS IS"  |
| and ANY EXPRESS or IMPLIED WARRANTIES, INCLUDING, BUT not limited to, the    |
| IMPLIED WARRANTIES of MERCHANTABILITY and FITNESS for A PARTICULAR PURPOSE   |
| ARE DISCLAIMED. in no EVENT SHALL the REGENTS or CONTRIBUTORS BE LIABLE for  |
| ANY direct, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, or CONSEQUENTIAL       |
| DAMAGES (INCLUDING, BUT not limited to, PROCUREMENT of SUBSTITUTE GOODS or   |
| SERVICES; LOSS of use, data, or PROFITS; or BUSINESS INTERRUPTION) HOWEVER   |
| CAUSED and on ANY THEORY of LIABILITY, WHETHER in CONTRACT, STRICT           |
| LIABILITY, or TORT (INCLUDING NEGLIGENCE or OTHERWISE) ARISING in ANY WAY    |
| OUT of the use of THIS SOFTWARE, EVEN if ADVISED of the POSSIBILITY of SUCH  |
| DAMAGE.                                                                      |
|==============================================================================|
| the Initial Developer of the original code is Lukas Gebauer (Czech Republic).|
| Portions created by Lukas Gebauer are Copyright (c)2000-2011.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|   Jean-Fabien Connault (cycocrew@worldnet.fr)                                |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(SNMP client)
Supports SNMPv1 include traps, SNMPv2c and SNMPv3 include authorization
and privacy encryption.

used RFC: RFC-1157, RFC-1901, RFC-3412, RFC-3414, RFC-3416, RFC-3826

Supported Authorization hashes: MD5, SHA1
Supported Privacy encryptions: DES, 3DES, AES
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT snmpsend;

INTERFACE

USES
  Classes, sysutils,
  blcksock, synautil, asn1util, synaip, synacode, synacrypt;

CONST
  cSnmpProtocol = '161';
  cSnmpTrapProtocol = '162';

  SNMP_V1 = 0;
  SNMP_V2C = 1;
  SNMP_V3 = 3;

  //PDU type
  PDUGetRequest = $A0;
  PDUGetNextRequest = $A1;
  PDUGetResponse = $A2;
  PDUSetRequest = $A3;
  PDUTrap = $A4; //Obsolete
  //for SNMPv2
  PDUGetBulkRequest = $A5;
  PDUInformRequest = $A6;
  PDUTrapV2 = $A7;
  PDUReport = $A8;

  //errors
  ENoError = 0;
  ETooBig = 1;
  ENoSuchName = 2;
  EBadValue = 3;
  EReadOnly = 4;
  EGenErr = 5;
  //errors SNMPv2
  ENoAccess = 6;
  EWrongType = 7;
  EWrongLength = 8;
  EWrongEncoding = 9;
  EWrongValue = 10;
  ENoCreation = 11;
  EInconsistentValue = 12;
  EResourceUnavailable = 13;
  ECommitFailed = 14;
  EUndoFailed = 15;
  EAuthorizationError = 16;
  ENotWritable = 17;
  EInconsistentName = 18;

TYPE

  {:@abstract(Possible values for SNMPv3 flags.)
   This flags specify level of authorization and encryption.}
  TV3Flags = (
    NoAuthNoPriv,
    AuthNoPriv,
    AuthPriv);

  {:@abstract(Type of SNMPv3 authorization)}
  TV3Auth = (
    AuthMD5,
    AuthSHA1);

  {:@abstract(Type of SNMPv3 privacy)}
  TV3Priv = (
    PrivDES,
    Priv3DES,
    PrivAES);

  {:@abstract(Data object with one record of MIB OID and corresponding values.)}
  TSNMPMib = class(TObject)
  protected
    FOID: ansistring;
    FValue: ansistring;
    FValueType: integer;
  Published
    {:OID number in string format.}
    PROPERTY OID: ansistring read FOID write FOID;

    {:Value of OID object in string format.}
    PROPERTY value: ansistring read FValue write FValue;

    {:Define type of Value. Supported values are defined in @link(asn1util).
     for queries use ASN1_NULL, becouse you don't know type in response!}
    PROPERTY ValueType: integer read FValueType write FValueType;
  end;

  {:@abstract(It holding all information for SNMPv3 agent synchronization)
   used internally.}
  TV3Sync = record
    EngineID: ansistring;
    EngineBoots: integer;
    EngineTime: integer;
    EngineStamp: Cardinal;
  end;

  {:@abstract(Data object abstracts SNMP data packet)}
  TSNMPRec = class(TObject)
  protected
    FVersion: integer;
    FPDUType: integer;
    FID: integer;
    FErrorStatus: integer;
    FErrorIndex: integer;
    FCommunity: ansistring;
    FSNMPMibList: TList;
    FMaxSize: integer;
    FFlags: TV3Flags;
    FFlagReportable: boolean;
    FContextEngineID: ansistring;
    FContextName: ansistring;
    FAuthMode: TV3Auth;
    FAuthEngineID: ansistring;
    FAuthEngineBoots: integer;
    FAuthEngineTime: integer;
    FAuthEngineTimeStamp: Cardinal;
    FUserName: ansistring;
    FPassword: ansistring;
    FAuthKey: ansistring;
    FPrivMode: TV3Priv;
    FPrivPassword: ansistring;
    FPrivKey: ansistring;
    FPrivSalt: ansistring;
    FPrivSaltCounter: integer;
    FOldTrapEnterprise: ansistring;
    FOldTrapHost: ansistring;
    FOldTrapGen: integer;
    FOldTrapSpec: integer;
    FOldTrapTimeTicks: integer;
    FUNCTION Pass2Key(CONST value: ansistring): ansistring;
    FUNCTION EncryptPDU(CONST value: ansistring): ansistring;
    FUNCTION DecryptPDU(CONST value: ansistring): ansistring;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Decode SNMP packet in buffer to object properties.}
    FUNCTION DecodeBuf(buffer: ansistring): boolean;

    {:Encode obeject properties to SNMP packet.}
    FUNCTION EncodeBuf: ansistring;

    {:Clears all object properties to default values.}
    PROCEDURE clear;

    {:Add entry to @link(SNMPMibList). For queries use value as empty string,
     and ValueType as ASN1_NULL.}
    PROCEDURE MIBAdd(CONST MIB, value: ansistring; ValueType: integer);

    {:Delete entry from @link(SNMPMibList).}
    PROCEDURE MIBDelete(index: integer);

    {:Search @link(SNMPMibList) list for MIB and return correspond value.}
    FUNCTION MIBGet(CONST MIB: ansistring): ansistring;

    {:return number of entries in MIB array.}
    FUNCTION MIBCount: integer;

    {:Return MIB information from given row of MIB array.}
    FUNCTION MIBByIndex(index: integer): TSNMPMib;

    {:List of @link(TSNMPMib) objects.}
    PROPERTY SNMPMibList: TList read FSNMPMibList;
  Published
    {:Version of SNMP packet. Default value is 0 (SNMP ver. 1). You can use
     value 1 for SNMPv2c or value 3 for SNMPv3.}
    PROPERTY Version: integer read FVersion write FVersion;

    {:Community string for autorize access to SNMP server. (Case sensitive!)
     Community string is not used in SNMPv3! use @link(Username) and
     @link(password) instead!}
    PROPERTY Community: ansistring read FCommunity write FCommunity;

    {:Define type of SNMP operation.}
    PROPERTY PDUType: integer read FPDUType write FPDUType;

    {:Contains ID number. Not need to use.}
    PROPERTY id: integer read FID write FID;

    {:When packet is reply, contains error code. Supported values are defined by
     E* constants.}
    PROPERTY ErrorStatus: integer read FErrorStatus write FErrorStatus;

    {:Point to error position in reply packet. Not usefull for users. It only
     good for debugging!}
    PROPERTY ErrorIndex: integer read FErrorIndex write FErrorIndex;

    {:special value for GetBulkRequest of SNMPv2 and v3.}
    PROPERTY NonRepeaters: integer read FErrorStatus write FErrorStatus;

    {:special value for GetBulkRequest of SNMPv2 and v3.}
    PROPERTY MaxRepetitions: integer read FErrorIndex write FErrorIndex;

    {:Maximum message size in bytes for SNMPv3. For sending is default 1472 bytes.}
    PROPERTY MaxSize: integer read FMaxSize write FMaxSize;

    {:Specify if message is authorised or encrypted. Used only in SNMPv3.}
    PROPERTY Flags: TV3Flags read FFlags write FFlags;

    {:For SNMPv3.... If is @true, SNMP agent must send reply (at least with some
     error).}
    PROPERTY FlagReportable: boolean read FFlagReportable write FFlagReportable;

    {:For SNMPv3. If not specified, is used value from @link(AuthEngineID)}
    PROPERTY ContextEngineID: ansistring read FContextEngineID write FContextEngineID;

    {:For SNMPv3.}
    PROPERTY ContextName: ansistring read FContextName write FContextName;

    {:For SNMPv3. Specify Authorization mode. (specify used hash for
     authorization)}
    PROPERTY AuthMode: TV3Auth read FAuthMode write FAuthMode;

    {:For SNMPv3. Specify Privacy mode.}
    PROPERTY PrivMode: TV3Priv read FPrivMode write FPrivMode;

    {:value used by SNMPv3 authorisation for synchronization with SNMP agent.}
    PROPERTY AuthEngineID: ansistring read FAuthEngineID write FAuthEngineID;

    {:value used by SNMPv3 authorisation for synchronization with SNMP agent.}
    PROPERTY AuthEngineBoots: integer read FAuthEngineBoots write FAuthEngineBoots;

    {:value used by SNMPv3 authorisation for synchronization with SNMP agent.}
    PROPERTY AuthEngineTime: integer read FAuthEngineTime write FAuthEngineTime;

    {:value used by SNMPv3 authorisation for synchronization with SNMP agent.}
    PROPERTY AuthEngineTimeStamp: Cardinal read FAuthEngineTimeStamp write FAuthEngineTimeStamp;

    {:SNMPv3 authorization username}
    PROPERTY UserName: ansistring read FUserName write FUserName;

    {:SNMPv3 authorization password}
    PROPERTY Password: ansistring read FPassword write FPassword;

    {:For SNMPv3. Computed Athorization key from @link(password).}
    PROPERTY AuthKey: ansistring read FAuthKey write FAuthKey;

    {:SNMPv3 privacy password}
    PROPERTY PrivPassword: ansistring read FPrivPassword write FPrivPassword;

    {:For SNMPv3. Computed Privacy key from @link(PrivPassword).}
    PROPERTY PrivKey: ansistring read FPrivKey write FPrivKey;

    {:MIB value to identify the object that sent the TRAPv1.}
    PROPERTY OldTrapEnterprise: ansistring read FOldTrapEnterprise write FOldTrapEnterprise;

    {:Address of TRAPv1 sender (IP address).}
    PROPERTY OldTrapHost: ansistring read FOldTrapHost write FOldTrapHost;

    {:Generic TRAPv1 identification.}
    PROPERTY OldTrapGen: integer read FOldTrapGen write FOldTrapGen;

    {:Specific TRAPv1 identification.}
    PROPERTY OldTrapSpec: integer read FOldTrapSpec write FOldTrapSpec;

    {:Number of 1/100th of seconds since last reboot or power up. (for TRAPv1)}
    PROPERTY OldTrapTimeTicks: integer read FOldTrapTimeTicks write FOldTrapTimeTicks;
  end;

  {:@abstract(Implementation of SNMP protocol.)

   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TSNMPSend = class(TSynaClient)
  protected
    FSock: TUDPBlockSocket;
    FBuffer: ansistring;
    FHostIP: ansistring;
    FQuery: TSNMPRec;
    FReply: TSNMPRec;
    FUNCTION InternalSendSnmp(CONST value: TSNMPRec): boolean;
    FUNCTION InternalRecvSnmp(CONST value: TSNMPRec): boolean;
    FUNCTION InternalSendRequest(CONST QValue, RValue: TSNMPRec): boolean;
    FUNCTION GetV3EngineID: ansistring;
    FUNCTION GetV3Sync: TV3Sync;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Connects to a Host and send there query. If in timeout SNMP server send
     back query, result is @true. if is used SNMPv3, then it synchronize self
     with SNMPv3 agent first. (it is needed for SNMPv3 auhorization!)}
    FUNCTION SendRequest: boolean;

    {:Send SNMP packet only, but not waits for reply. Good for sending traps.}
    FUNCTION SendTrap: boolean;

    {:Receive SNMP packet only. Good for receiving traps.}
    FUNCTION RecvTrap: boolean;

    {:Mapped to @link(SendRequest) internally. This function is only for
     backward compatibility.}
    FUNCTION DoIt: boolean;
  Published
    {:contains raw binary form of SNMP packet. Good for debugging.}
    PROPERTY buffer: ansistring read FBuffer write FBuffer;

    {:After SNMP operation hold IP address of remote side.}
    PROPERTY HostIP: ansistring read FHostIP;

    {:Data object contains SNMP query.}
    PROPERTY Query: TSNMPRec read FQuery;

    {:Data object contains SNMP reply.}
    PROPERTY Reply: TSNMPRec read FReply;

    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TUDPBlockSocket read FSock;
  end;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it implements basic get method of the SNMP protocol. the MIB value is
 located in the "OID" variable, and is sent to the requested "SNMPHost" with
 the proper "Community" access Identifier. Upon a successful retrieval, "value"
 will contain the information requested. if the SNMP operation is successful,
 the result returns @true.}
FUNCTION SNMPGet(CONST OID, Community, SNMPHost: ansistring; VAR value: ansistring): boolean;

{:This is useful function and example of use TSNMPSend object. It implements
 the basic set method of the SNMP protocol. if the SNMP operation is successful,
 the result is @true. "value" is value of MIB Oid for "SNMPHost" with "Community"
 access Identifier. You must specify "ValueType" too.}
FUNCTION SNMPSet(CONST OID, Community, SNMPHost, value: ansistring; ValueType: integer): boolean;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it implements basic GETNEXT method of the SNMP protocol. the MIB value
 is located in the "OID" variable, and is sent to the requested "SNMPHost" with
 the proper "Community" access Identifier. Upon a successful retrieval, "value"
 will contain the information requested. if the SNMP operation is successful,
 the result returns @true.}
FUNCTION SNMPGetNext(VAR OID: ansistring; CONST Community, SNMPHost: ansistring; VAR value: ansistring): boolean;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it implements basic read of SNMP MIB tables. As BaseOID you must
 specify basic MIB OID of requested table (base IOD is OID without row and
 column specificator!)
 table is readed into stringlist, where each string is comma delimited string.

 Warning: this FUNCTION is not have best performance. for better performance
 you must write your own FUNCTION. best performace you can get by knowledge
 of structuture of table and by more then one MIB on one query. }
FUNCTION SNMPGetTable(CONST BaseOID, Community, SNMPHost: ansistring; CONST value: TStrings): boolean;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it implements basic read of SNMP MIB table element. As BaseOID you must
 specify basic MIB OID of requested table (base IOD is OID without row and
 column specificator!)
 As next you must specify identificator of row and column for specify of needed
 field of table.}
FUNCTION SNMPGetTableElement(CONST BaseOID, rowId, ColID, Community, SNMPHost: ansistring; VAR value: ansistring): boolean;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it implements a TRAPv1 to send with all data in the parameters.}
FUNCTION SendTrap(CONST dest, Source, Enterprise, Community: ansistring;
  GENERIC, specific, Seconds: integer; CONST MIBName, MIBValue: ansistring;
  MIBtype: integer): integer;

{:A very useful function and example of its use would be found in the TSNMPSend
 object. it receives a TRAPv1 and returns all the data that comes with it.}
FUNCTION RecvTrap(VAR dest, Source, Enterprise, Community: ansistring;
  VAR GENERIC, specific, Seconds: integer; CONST MIBName,
  MIBValue: TStringList): integer;

IMPLEMENTATION

{==============================================================================}

CONSTRUCTOR TSNMPRec.create;
begin
  inherited create;
  FSNMPMibList := TList.create;
  clear;
  FAuthMode := AuthMD5;
  FPassword := '';
  FPrivMode := PrivDES;
  FPrivPassword := '';
  FID := 1;
  FMaxSize := 1472;
end;

DESTRUCTOR TSNMPRec.destroy;
VAR
  i: integer;
begin
  for i := 0 to FSNMPMibList.count - 1 do
    TSNMPMib(FSNMPMibList[i]).free;
  FSNMPMibList.clear;
  FSNMPMibList.free;
  inherited destroy;
end;

FUNCTION TSNMPRec.Pass2Key(CONST value: ansistring): ansistring;
VAR
  key: ansistring;
begin
  case FAuthMode of
    AuthMD5:
      begin
        key := MD5LongHash(value, 1048576);
        result := MD5(key + FAuthEngineID + key);
      end;
    AuthSHA1:
      begin
        key := SHA1LongHash(value, 1048576);
        result := SHA1(key + FAuthEngineID + key);
      end;
  else
    result := '';
  end;
end;

FUNCTION TSNMPRec.DecryptPDU(CONST value: ansistring): ansistring;
VAR
  des: TSynaDes;
  des3: TSyna3Des;
  aes: TSynaAes;
  s: string;
begin
  FPrivKey := '';
  if FFlags <> AuthPriv then
    result := value
  else
  begin
    case FPrivMode of
      Priv3DES:
        begin
          FPrivKey := Pass2Key(FPrivPassword);
          FPrivKey := FPrivKey + Pass2Key(FPrivKey);
          des3 := TSyna3Des.create(PadString(FPrivKey, 24, #0));
          try
            s := PadString(FPrivKey, 32, #0);
            Delete(s, 1, 24);
            des3.SetIV(xorstring(s, FPrivSalt));
            s := des3.DecryptCBC(value);
            result := s;
          finally
            des3.free;
          end;
        end;
      PrivAES:
        begin
          FPrivKey := Pass2Key(FPrivPassword);
          aes := TSynaAes.create(PadString(FPrivKey, 16, #0));
          try
            s := CodeLongInt(FAuthEngineBoots) + CodeLongInt(FAuthEngineTime) + FPrivSalt;
            aes.SetIV(s);
            s := aes.DecryptCFBblock(value);
            result := s;
          finally
            aes.free;
          end;
        end;
    else //PrivDES as default
      begin
        FPrivKey := Pass2Key(FPrivPassword);
        des := TSynaDes.create(PadString(FPrivKey, 8, #0));
        try
          s := PadString(FPrivKey, 16, #0);
          Delete(s, 1, 8);
          des.SetIV(xorstring(s, FPrivSalt));
          s := des.DecryptCBC(value);
          result := s;
        finally
          des.free;
        end;
      end;
    end;
  end;
end;

FUNCTION TSNMPRec.DecodeBuf(buffer: ansistring): boolean;
VAR
  pos: integer;
  EndPos: integer;
  SM, sv: ansistring;
  Svt: integer;
  s: ansistring;
  Spos: integer;
  x: byte;
begin
  clear;
  result := false;
  if length(buffer) < 2 then
    exit;
  if (ord(buffer[1]) and $20) = 0 then
    exit;
  pos := 2;
  EndPos := ASNDecLen(pos, buffer);
  if length(buffer) < (EndPos + 2) then
    exit;
  self.FVersion := strToIntDef(ASNItem(pos, buffer, Svt), 0);

  if FVersion = 3 then
  begin
    ASNItem(pos, buffer, Svt);  //header data seq
    ASNItem(pos, buffer, Svt);  //ID
    FMaxSize := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    s := ASNItem(pos, buffer, Svt);
    x := 0;
    if s <> '' then
      x := ord(s[1]);
    FFlagReportable := (x and 4) > 0;
    x := x and 3;
    case x of
      1:
        FFlags := AuthNoPriv;
      3:
        FFlags := AuthPriv;
    else
      FFlags := NoAuthNoPriv;
    end;

    x := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    s := ASNItem(pos, buffer, Svt); //SecurityParameters
    //if SecurityModel is USM, then try to decode SecurityParameters
    if (x = 3) and (s <> '') then
    begin
      spos := 1;
      ASNItem(SPos, s, Svt);
      FAuthEngineID := ASNItem(SPos, s, Svt);
      FAuthEngineBoots := strToIntDef(ASNItem(SPos, s, Svt), 0);
      FAuthEngineTime := strToIntDef(ASNItem(SPos, s, Svt), 0);
      FAuthEngineTimeStamp := GetTick;
      FUserName := ASNItem(SPos, s, Svt);
      FAuthKey := ASNItem(SPos, s, Svt);
      FPrivSalt := ASNItem(SPos, s, Svt);
    end;
    //scopedPDU
    if FFlags = AuthPriv then
    begin
      x := pos;
      s := ASNItem(pos, buffer, Svt);
      if Svt <> ASN1_OCTSTR then
        exit;
      s := DecryptPDU(s);
      //replace encoded content by decoded version and continue
      buffer := copy(buffer, 1, x - 1);
      buffer := buffer + s;
      pos := x;
      if length(buffer) < EndPos then
        EndPos := length(buffer);
    end;
    ASNItem(pos, buffer, Svt); //skip sequence mark
    FContextEngineID := ASNItem(pos, buffer, Svt);
    FContextName := ASNItem(pos, buffer, Svt);
  end
  else
  begin
    //old packet
    self.FCommunity := ASNItem(pos, buffer, Svt);
  end;

  ASNItem(pos, buffer, Svt);
  self.FPDUType := Svt;
  if self.FPDUType = PDUTrap then
  begin
    FOldTrapEnterprise := ASNItem(pos, buffer, Svt);
    FOldTrapHost := ASNItem(pos, buffer, Svt);
    FOldTrapGen := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    FOldTrapSpec := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    FOldTrapTimeTicks := strToIntDef(ASNItem(pos, buffer, Svt), 0);
  end
  else
  begin
    self.FID := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    self.FErrorStatus := strToIntDef(ASNItem(pos, buffer, Svt), 0);
    self.FErrorIndex := strToIntDef(ASNItem(pos, buffer, Svt), 0);
  end;
  ASNItem(pos, buffer, Svt);
  while pos < EndPos do
  begin
    ASNItem(pos, buffer, Svt);
    SM := ASNItem(pos, buffer, Svt);
    sv := ASNItem(pos, buffer, Svt);
    if SM <> '' then
      self.MIBAdd(SM, sv, Svt);
  end;
  result := true;
end;

FUNCTION TSNMPRec.EncryptPDU(CONST value: ansistring): ansistring;
VAR
  des: TSynaDes;
  des3: TSyna3Des;
  aes: TSynaAes;
  s: string;
  x: integer;
begin
  FPrivKey := '';
  if FFlags <> AuthPriv then
    result := value
  else
  begin
    case FPrivMode of
      Priv3DES:
        begin
          FPrivKey := Pass2Key(FPrivPassword);
          FPrivKey := FPrivKey + Pass2Key(FPrivKey);
          des3 := TSyna3Des.create(PadString(FPrivKey, 24, #0));
          try
            s := PadString(FPrivKey, 32, #0);
            Delete(s, 1, 24);
            FPrivSalt := CodeLongInt(FAuthEngineBoots) + CodeLongInt(FPrivSaltCounter);
            inc(FPrivSaltCounter);
            s := xorstring(s, FPrivSalt);
            des3.SetIV(s);
            x := length(value) mod 8;
            x := 8 - x;
            if x = 8 then
              x := 0;
            s := des3.EncryptCBC(value + StringOfChar(#0, x));
            result := ASNObject(s, ASN1_OCTSTR);
          finally
            des3.free;
          end;
        end;
      PrivAES:
        begin
          FPrivKey := Pass2Key(FPrivPassword);
          aes := TSynaAes.create(PadString(FPrivKey, 16, #0));
          try
            FPrivSalt := CodeLongInt(0) + CodeLongInt(FPrivSaltCounter);
            inc(FPrivSaltCounter);
            s := CodeLongInt(FAuthEngineBoots) + CodeLongInt(FAuthEngineTime) + FPrivSalt;
            aes.SetIV(s);
            s := aes.EncryptCFBblock(value);
            result := ASNObject(s, ASN1_OCTSTR);
          finally
            aes.free;
          end;
        end;
    else //PrivDES as default
      begin
        FPrivKey := Pass2Key(FPrivPassword);
        des := TSynaDes.create(PadString(FPrivKey, 8, #0));
        try
          s := PadString(FPrivKey, 16, #0);
          Delete(s, 1, 8);
          FPrivSalt := CodeLongInt(FAuthEngineBoots) + CodeLongInt(FPrivSaltCounter);
          inc(FPrivSaltCounter);
          s := xorstring(s, FPrivSalt);
          des.SetIV(s);
          x := length(value) mod 8;
          x := 8 - x;
          if x = 8 then
            x := 0;
          s := des.EncryptCBC(value + StringOfChar(#0, x));
          result := ASNObject(s, ASN1_OCTSTR);
        finally
          des.free;
        end;
      end;
    end;
  end;
end;

FUNCTION TSNMPRec.EncodeBuf: ansistring;
VAR
  s: ansistring;
  SNMPMib: TSNMPMib;
  n: integer;
  pdu, head, auth, authbeg: ansistring;
  x: byte;
begin
  pdu := '';
  for n := 0 to FSNMPMibList.count - 1 do
  begin
    SNMPMib := TSNMPMib(FSNMPMibList[n]);
    case SNMPMib.ValueType of
      ASN1_INT:
        s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
          ASNObject(ASNEncInt(strToIntDef(SNMPMib.value, 0)), SNMPMib.ValueType);
      ASN1_COUNTER, ASN1_GAUGE, ASN1_TIMETICKS:
        s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
          ASNObject(ASNEncUInt(strToIntDef(SNMPMib.value, 0)), SNMPMib.ValueType);
      ASN1_OBJID:
        s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
          ASNObject(MibToID(SNMPMib.value), SNMPMib.ValueType);
      ASN1_IPADDR:
        s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
          ASNObject(IPToID(SNMPMib.value), SNMPMib.ValueType);
      ASN1_NULL:
        s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
          ASNObject('', ASN1_NULL);
    else
      s := ASNObject(MibToID(SNMPMib.OID), ASN1_OBJID) +
        ASNObject(SNMPMib.value, SNMPMib.ValueType);
    end;
    pdu := pdu + ASNObject(s, ASN1_SEQ);
  end;
  pdu := ASNObject(pdu, ASN1_SEQ);

  if self.FPDUType = PDUTrap then
    pdu := ASNObject(MibToID(FOldTrapEnterprise), ASN1_OBJID) +
      ASNObject(IPToID(FOldTrapHost), ASN1_IPADDR) +
      ASNObject(ASNEncInt(FOldTrapGen), ASN1_INT) +
      ASNObject(ASNEncInt(FOldTrapSpec), ASN1_INT) +
      ASNObject(ASNEncUInt(FOldTrapTimeTicks), ASN1_TIMETICKS) +
      pdu
  else
    pdu := ASNObject(ASNEncInt(self.FID), ASN1_INT) +
      ASNObject(ASNEncInt(self.FErrorStatus), ASN1_INT) +
      ASNObject(ASNEncInt(self.FErrorIndex), ASN1_INT) +
      pdu;
  pdu := ASNObject(pdu, self.FPDUType);

  if FVersion = 3 then
  begin
    if FContextEngineID = '' then
      FContextEngineID := FAuthEngineID;
    //complete PDUv3...
    pdu := ASNObject(FContextEngineID, ASN1_OCTSTR)
      + ASNObject(FContextName, ASN1_OCTSTR)
      + pdu;
    pdu := ASNObject(pdu, ASN1_SEQ);
    //encrypt PDU if Priv mode is enabled
    pdu := EncryptPDU(pdu);

    //prepare flags
    case FFlags of
      AuthNoPriv:
        x := 1;
      AuthPriv:
        x := 3;
    else
      x := 0;
    end;
    if FFlagReportable then
      x := x or 4;
    head := ASNObject(ASNEncInt(self.FVersion), ASN1_INT);
    s := ASNObject(ASNEncInt(FID), ASN1_INT)
      + ASNObject(ASNEncInt(FMaxSize), ASN1_INT)
      + ASNObject(AnsiChar(x), ASN1_OCTSTR)
    //encode security model USM
      + ASNObject(ASNEncInt(3), ASN1_INT);
    head := head + ASNObject(s, ASN1_SEQ);

    //compute engine time difference
    if FAuthEngineTimeStamp = 0 then //out of sync
      x := 0
    else
      x := TickDelta(FAuthEngineTimeStamp, GetTick) div 1000;

    authbeg := ASNObject(FAuthEngineID, ASN1_OCTSTR)
      + ASNObject(ASNEncInt(FAuthEngineBoots), ASN1_INT)
      + ASNObject(ASNEncInt(FAuthEngineTime + x), ASN1_INT)
      + ASNObject(FUserName, ASN1_OCTSTR);


    case FFlags of
      AuthNoPriv,
      AuthPriv:
        begin
          s := authbeg + ASNObject(StringOfChar(#0, 12), ASN1_OCTSTR)
             + ASNObject(FPrivSalt, ASN1_OCTSTR);
          s := ASNObject(s, ASN1_SEQ);
          s := head + ASNObject(s, ASN1_OCTSTR);
          s := ASNObject(s + pdu, ASN1_SEQ);
          //in s is entire packet without auth info...
          case FAuthMode of
            AuthMD5:
              begin
                s := HMAC_MD5(s, Pass2Key(FPassword) + StringOfChar(#0, 48));
                //strip to HMAC-MD5-96
                Delete(s, 13, 4);
              end;
            AuthSHA1:
              begin
                s := HMAC_SHA1(s, Pass2Key(FPassword) + StringOfChar(#0, 44));
                //strip to HMAC-SHA-96
                Delete(s, 13, 8);
              end;
          else
            s := '';
          end;
          FAuthKey := s;
        end;
    end;

    auth := authbeg + ASNObject(FAuthKey, ASN1_OCTSTR)
     + ASNObject(FPrivSalt, ASN1_OCTSTR);
    auth := ASNObject(auth, ASN1_SEQ);

    head := head + ASNObject(auth, ASN1_OCTSTR);
    result := ASNObject(head + pdu, ASN1_SEQ);
  end
  else
  begin
    head := ASNObject(ASNEncInt(self.FVersion), ASN1_INT) +
      ASNObject(self.FCommunity, ASN1_OCTSTR);
    result := ASNObject(head + pdu, ASN1_SEQ);
  end;
  inc(self.FID);
end;

PROCEDURE TSNMPRec.clear;
VAR
  i: integer;
begin
  FVersion := SNMP_V1;
  FCommunity := 'public';
  FUserName := '';
  FPDUType := 0;
  FErrorStatus := 0;
  FErrorIndex := 0;
  for i := 0 to FSNMPMibList.count - 1 do
    TSNMPMib(FSNMPMibList[i]).free;
  FSNMPMibList.clear;
  FOldTrapEnterprise := '';
  FOldTrapHost := '';
  FOldTrapGen := 0;
  FOldTrapSpec := 0;
  FOldTrapTimeTicks := 0;
  FFlags := NoAuthNoPriv;
  FFlagReportable := false;
  FContextEngineID := '';
  FContextName := '';
  FAuthEngineID := '';
  FAuthEngineBoots := 0;
  FAuthEngineTime := 0;
  FAuthEngineTimeStamp := 0;
  FAuthKey := '';
  FPrivKey := '';
  FPrivSalt := '';
  FPrivSaltCounter := random(MAXINT);
end;

PROCEDURE TSNMPRec.MIBAdd(CONST MIB, value: ansistring; ValueType: integer);
VAR
  SNMPMib: TSNMPMib;
begin
  SNMPMib := TSNMPMib.create;
  SNMPMib.OID := MIB;
  SNMPMib.value := value;
  SNMPMib.ValueType := ValueType;
  FSNMPMibList.add(SNMPMib);
end;

PROCEDURE TSNMPRec.MIBDelete(index: integer);
begin
  if (index >= 0) and (index < MIBCount) then
  begin
    TSNMPMib(FSNMPMibList[index]).free;
    FSNMPMibList.Delete(index);
  end;
end;

FUNCTION TSNMPRec.MIBCount: integer;
begin
  result := FSNMPMibList.count;
end;

FUNCTION TSNMPRec.MIBByIndex(index: integer): TSNMPMib;
begin
  result := nil;
  if (index >= 0) and (index < MIBCount) then
    result := TSNMPMib(FSNMPMibList[index]);
end;

FUNCTION TSNMPRec.MIBGet(CONST MIB: ansistring): ansistring;
VAR
  i: integer;
begin
  result := '';
  for i := 0 to MIBCount - 1 do
  begin
    if ((TSNMPMib(FSNMPMibList[i])).OID = MIB) then
    begin
      result := (TSNMPMib(FSNMPMibList[i])).value;
      break;
    end;
  end;
end;

{==============================================================================}

CONSTRUCTOR TSNMPSend.create;
begin
  inherited create;
  FQuery := TSNMPRec.create;
  FReply := TSNMPRec.create;
  FQuery.clear;
  FReply.clear;
  FSock := TUDPBlockSocket.create;
  FSock.Owner := self;
  FTimeout := 5000;
  FTargetPort := cSnmpProtocol;
  FHostIP := '';
end;

DESTRUCTOR TSNMPSend.destroy;
begin
  FSock.free;
  FReply.free;
  FQuery.free;
  inherited destroy;
end;

FUNCTION TSNMPSend.InternalSendSnmp(CONST value: TSNMPRec): boolean;
begin
  FBuffer := value.EncodeBuf;
  FSock.SendString(FBuffer);
  result := FSock.LastError = 0;
end;

FUNCTION TSNMPSend.InternalRecvSnmp(CONST value: TSNMPRec): boolean;
begin
  result := false;
  FReply.clear;
  FHostIP := cAnyHost;
  FBuffer := FSock.RecvPacket(FTimeout);
  if FSock.LastError = 0 then
  begin
    FHostIP := FSock.GetRemoteSinIP;
    result := value.DecodeBuf(FBuffer);
  end;
end;

FUNCTION TSNMPSend.InternalSendRequest(CONST QValue, RValue: TSNMPRec): boolean;
begin
  result := false;
  RValue.AuthMode := QValue.AuthMode;
  RValue.Password := QValue.Password;
  RValue.PrivMode := QValue.PrivMode;
  RValue.PrivPassword := QValue.PrivPassword;
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(FTargetHost, FTargetPort);
  if InternalSendSnmp(QValue) then
    result := InternalRecvSnmp(RValue);
end;

FUNCTION TSNMPSend.SendRequest: boolean;
VAR
  sync: TV3Sync;
begin
  result := false;
  if FQuery.FVersion = 3 then
  begin
    sync := GetV3Sync;
    FQuery.AuthEngineBoots := Sync.EngineBoots;
    FQuery.AuthEngineTime := Sync.EngineTime;
    FQuery.AuthEngineTimeStamp := Sync.EngineStamp;
    FQuery.AuthEngineID := Sync.EngineID;
  end;
  result := InternalSendRequest(FQuery, FReply);
end;

FUNCTION TSNMPSend.SendTrap: boolean;
begin
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(FTargetHost, FTargetPort);
  result := InternalSendSnmp(FQuery);
end;

FUNCTION TSNMPSend.RecvTrap: boolean;
begin
  FSock.Bind(FIPInterface, FTargetPort);
  result := InternalRecvSnmp(FReply);
end;

FUNCTION TSNMPSend.DoIt: boolean;
begin
  result := SendRequest;
end;

FUNCTION TSNMPSend.GetV3EngineID: ansistring;
VAR
  DisQuery: TSNMPRec;
begin
  result := '';
  DisQuery := TSNMPRec.create;
  try
    DisQuery.Version := 3;
    DisQuery.UserName := '';
    DisQuery.FlagReportable := true;
    DisQuery.PDUType := PDUGetRequest;
    if InternalSendRequest(DisQuery, FReply) then
      result := FReply.FAuthEngineID;
  finally
    DisQuery.free;
  end;
end;

FUNCTION TSNMPSend.GetV3Sync: TV3Sync;
VAR
  SyncQuery: TSNMPRec;
begin
  result.EngineID := GetV3EngineID;
  result.EngineBoots := FReply.AuthEngineBoots;
  result.EngineTime := FReply.AuthEngineTime;
  result.EngineStamp := FReply.AuthEngineTimeStamp;
  if result.EngineTime = 0 then
  begin
    //still not have sync...
    SyncQuery := TSNMPRec.create;
    try
      SyncQuery.Version := 3;
      SyncQuery.UserName := FQuery.UserName;
      SyncQuery.Password := FQuery.Password;
      SyncQuery.FlagReportable := true;
      SyncQuery.Flags := FQuery.Flags;
      SyncQuery.AuthMode := FQuery.AuthMode;
      SyncQuery.PrivMode := FQuery.PrivMode;
      SyncQuery.PrivPassword := FQuery.PrivPassword;
      SyncQuery.PDUType := PDUGetRequest;
      SyncQuery.AuthEngineID := FReply.FAuthEngineID;
      if InternalSendRequest(SyncQuery, FReply) then
      begin
        result.EngineBoots := FReply.AuthEngineBoots;
        result.EngineTime := FReply.AuthEngineTime;
        result.EngineStamp := FReply.AuthEngineTimeStamp;
      end;
    finally
      SyncQuery.free;
    end;
  end;
end;

{==============================================================================}

FUNCTION SNMPGet(CONST OID, Community, SNMPHost: ansistring; VAR value: ansistring): boolean;
VAR
  SNMPSend: TSNMPSend;
begin
  SNMPSend := TSNMPSend.create;
  try
    SNMPSend.Query.clear;
    SNMPSend.Query.Community := Community;
    SNMPSend.Query.PDUType := PDUGetRequest;
    SNMPSend.Query.MIBAdd(OID, '', ASN1_NULL);
    SNMPSend.TargetHost := SNMPHost;
    result := SNMPSend.SendRequest;
    value := '';
    if result then
      value := SNMPSend.Reply.MIBGet(OID);
  finally
    SNMPSend.free;
  end;
end;

FUNCTION SNMPSet(CONST OID, Community, SNMPHost, value: ansistring; ValueType: integer): boolean;
VAR
  SNMPSend: TSNMPSend;
begin
  SNMPSend := TSNMPSend.create;
  try
    SNMPSend.Query.clear;
    SNMPSend.Query.Community := Community;
    SNMPSend.Query.PDUType := PDUSetRequest;
    SNMPSend.Query.MIBAdd(OID, value, ValueType);
    SNMPSend.TargetHost := SNMPHost;
    result := SNMPSend.Sendrequest = true;
  finally
    SNMPSend.free;
  end;
end;

FUNCTION InternalGetNext(CONST SNMPSend: TSNMPSend; VAR OID: ansistring;
  CONST Community: ansistring; VAR value: ansistring): boolean;
begin
  SNMPSend.Query.clear;
  SNMPSend.Query.id := SNMPSend.Query.id + 1;
  SNMPSend.Query.Community := Community;
  SNMPSend.Query.PDUType := PDUGetNextRequest;
  SNMPSend.Query.MIBAdd(OID, '', ASN1_NULL);
  result := SNMPSend.Sendrequest;
  value := '';
  if result then
    if SNMPSend.Reply.SNMPMibList.count > 0 then
    begin
      OID := TSNMPMib(SNMPSend.Reply.SNMPMibList[0]).OID;
      value := TSNMPMib(SNMPSend.Reply.SNMPMibList[0]).value;
    end;
end;

FUNCTION SNMPGetNext(VAR OID: ansistring; CONST Community, SNMPHost: ansistring; VAR value: ansistring): boolean;
VAR
  SNMPSend: TSNMPSend;
begin
  SNMPSend := TSNMPSend.create;
  try
    SNMPSend.TargetHost := SNMPHost;
    result := InternalGetNext(SNMPSend, OID, Community, value);
  finally
    SNMPSend.free;
  end;
end;

FUNCTION SNMPGetTable(CONST BaseOID, Community, SNMPHost: ansistring; CONST value: TStrings): boolean;
VAR
  OID: ansistring;
  s: ansistring;
  col,row: string;
  x: integer;
  SNMPSend: TSNMPSend;
  RowList: TStringList;
begin
  value.clear;
  SNMPSend := TSNMPSend.create;
  RowList := TStringList.create;
  try
    SNMPSend.TargetHost := SNMPHost;
    OID := BaseOID;
    repeat
      result := InternalGetNext(SNMPSend, OID, Community, s);
      if pos(BaseOID, OID) <> 1 then
          break;
      row := separateright(oid, baseoid + '.');
      col := fetch(row, '.');

      if IsBinaryString(s) then
        s := StrToHex(s);
      x := RowList.indexOf(row);
      if x < 0 then
      begin
        x := RowList.add(row);
        value.add('');
      end;
      if (value[x] <> '') then
        value[x] := value[x] + ',';
      value[x] := value[x] + AnsiQuotedStr(s, '"');
    until not result;
  finally
    SNMPSend.free;
    RowList.free;
  end;
end;

FUNCTION SNMPGetTableElement(CONST BaseOID, rowId, ColID, Community, SNMPHost: ansistring; VAR value: ansistring): boolean;
VAR
  s: ansistring;
begin
  s := BaseOID + '.' + ColID + '.' + rowId;
  result := SnmpGet(s, Community, SNMPHost, value);
end;

FUNCTION SendTrap(CONST dest, Source, Enterprise, Community: ansistring;
  GENERIC, specific, Seconds: integer; CONST MIBName, MIBValue: ansistring;
  MIBtype: integer): integer;
VAR
  SNMPSend: TSNMPSend;
begin
  SNMPSend := TSNMPSend.create;
  try
    SNMPSend.TargetHost := dest;
    SNMPSend.TargetPort := cSnmpTrapProtocol;
    SNMPSend.Query.Community := Community;
    SNMPSend.Query.Version := SNMP_V1;
    SNMPSend.Query.PDUType := PDUTrap;
    SNMPSend.Query.OldTrapHost := Source;
    SNMPSend.Query.OldTrapEnterprise := Enterprise;
    SNMPSend.Query.OldTrapGen := GENERIC;
    SNMPSend.Query.OldTrapSpec := specific;
    SNMPSend.Query.OldTrapTimeTicks := Seconds;
    SNMPSend.Query.MIBAdd(MIBName, MIBValue, MIBType);
    result := ord(SNMPSend.SendTrap);
  finally
    SNMPSend.free;
  end;
end;

FUNCTION RecvTrap(VAR dest, Source, Enterprise, Community: ansistring;
  VAR GENERIC, specific, Seconds: integer;
  CONST MIBName, MIBValue: TStringList): integer;
VAR
  SNMPSend: TSNMPSend;
  i: integer;
begin
  SNMPSend := TSNMPSend.create;
  try
    result := 0;
    SNMPSend.TargetPort := cSnmpTrapProtocol;
    if SNMPSend.RecvTrap then
    begin
      result := 1;
      dest := SNMPSend.HostIP;
      Community := SNMPSend.Reply.Community;
      Source := SNMPSend.Reply.OldTrapHost;
      Enterprise := SNMPSend.Reply.OldTrapEnterprise;
      GENERIC := SNMPSend.Reply.OldTrapGen;
      specific := SNMPSend.Reply.OldTrapSpec;
      Seconds := SNMPSend.Reply.OldTrapTimeTicks;
      MIBName.clear;
      MIBValue.clear;
      for i := 0 to SNMPSend.Reply.SNMPMibList.count - 1 do
      begin
        MIBName.add(TSNMPMib(SNMPSend.Reply.SNMPMibList[i]).OID);
        MIBValue.add(TSNMPMib(SNMPSend.Reply.SNMPMibList[i]).value);
      end;
    end;
  finally
    SNMPSend.free;
  end;
end;


end.


