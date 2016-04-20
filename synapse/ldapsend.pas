{==============================================================================|
| project : Ararat Synapse                                       | 001.007.000 |
|==============================================================================|
| content: LDAP Client                                                         |
|==============================================================================|
| Copyright (c)1999-2010, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2003-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(LDAP client)

used RFC: RFC-2251, RFC-2254, RFC-2829, RFC-2830
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT ldapsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil, asn1util, synacode;

CONST
  cLDAPProtocol = '389';

  LDAP_ASN1_BIND_REQUEST = $60;
  LDAP_ASN1_BIND_RESPONSE = $61;
  LDAP_ASN1_UNBIND_REQUEST = $42;
  LDAP_ASN1_SEARCH_REQUEST = $63;
  LDAP_ASN1_SEARCH_ENTRY = $64;
  LDAP_ASN1_SEARCH_DONE = $65;
  LDAP_ASN1_SEARCH_REFERENCE = $73;
  LDAP_ASN1_MODIFY_REQUEST = $66;
  LDAP_ASN1_MODIFY_RESPONSE = $67;
  LDAP_ASN1_ADD_REQUEST = $68;
  LDAP_ASN1_ADD_RESPONSE = $69;
  LDAP_ASN1_DEL_REQUEST = $4A;
  LDAP_ASN1_DEL_RESPONSE = $6B;
  LDAP_ASN1_MODIFYDN_REQUEST = $6C;
  LDAP_ASN1_MODIFYDN_RESPONSE = $6D;
  LDAP_ASN1_COMPARE_REQUEST = $6E;
  LDAP_ASN1_COMPARE_RESPONSE = $6F;
  LDAP_ASN1_ABANDON_REQUEST = $70;
  LDAP_ASN1_EXT_REQUEST = $77;
  LDAP_ASN1_EXT_RESPONSE = $78;


TYPE

  {:@abstract(LDAP attribute with list of their values)
   This class holding name of LDAP attribute and list of their values. This is
   descendant of TStringList class enhanced by some new properties.}
  TLDAPAttribute = class(TStringList)
  private
    FAttributeName: ansistring;
    FIsBinary: boolean;
  protected
    FUNCTION get(index: integer): string; override;
    PROCEDURE put(index: integer; CONST value: string); override;
    PROCEDURE SetAttributeName(value: ansistring);
  Published
    {:Name of LDAP attribute.}
    PROPERTY AttributeName: ansistring read FAttributeName write SetAttributeName;
    {:Return @true when attribute contains binary data.}
    PROPERTY IsBinary: boolean read FIsBinary;
  end;

  {:@abstract(List of @link(TLDAPAttribute))
   This object can hold list of TLDAPAttribute objects.}
  TLDAPAttributeList = class(TObject)
  private
    FAttributeList: TList;
    FUNCTION GetAttribute(index: integer): TLDAPAttribute;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;
    {:Clear list.}
    PROCEDURE clear;
    {:Return count of TLDAPAttribute objects in list.}
    FUNCTION count: integer;
    {:Add new TLDAPAttribute object to list.}
    FUNCTION add: TLDAPAttribute;
    {:Delete one TLDAPAttribute object from list.}
    PROCEDURE Del(index: integer);
    {:Find and return attribute with requested name. Returns nil if not found.}
    FUNCTION find(AttributeName: ansistring): TLDAPAttribute;
    {:Find and return attribute value with requested name. Returns empty string if not found.}
    FUNCTION get(AttributeName: ansistring): string;
    {:List of TLDAPAttribute objects.}
    PROPERTY Items[index: integer]: TLDAPAttribute read GetAttribute; default;
  end;

  {:@abstract(LDAP result object)
   This object can hold LDAP object. (their name and all their attributes with
   values)}
  TLDAPResult = class(TObject)
  private
    FObjectName: ansistring;
    FAttributes: TLDAPAttributeList;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;
  Published
    {:Name of this LDAP object.}
    PROPERTY ObjectName: ansistring read FObjectName write FObjectName;
    {:Here is list of object attributes.}
    PROPERTY Attributes: TLDAPAttributeList read FAttributes;
  end;

  {:@abstract(List of LDAP result objects)
   This object can hold list of LDAP objects. (for example result of LDAP SEARCH.)}
  TLDAPResultList = class(TObject)
  private
    FResultList: TList;
    FUNCTION GetResult(index: integer): TLDAPResult;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;
    {:Clear all TLDAPResult objects in list.}
    PROCEDURE clear;
    {:Return count of TLDAPResult objects in list.}
    FUNCTION count: integer;
    {:Create and add new TLDAPResult object to list.}
    FUNCTION add: TLDAPResult;
    {:List of TLDAPResult objects.}
    PROPERTY Items[index: integer]: TLDAPResult read GetResult; default;
  end;

  {:Define possible operations for LDAP MODIFY operations.}
  TLDAPModifyOp = (
    MO_Add,
    MO_Delete,
    MO_Replace
  );

  {:Specify possible values for search scope.}
  TLDAPSearchScope = (
    SS_BaseObject,
    SS_SingleLevel,
    SS_WholeSubtree
  );

  {:Specify possible values about alias dereferencing.}
  TLDAPSearchAliases = (
    SA_NeverDeref,
    SA_InSearching,
    SA_FindingBaseObj,
    SA_Always
  );

  {:@abstract(Implementation of LDAP client)
   (version 2 and 3)

   Note: Are you missing properties for setting Username and Password? Look to
   parent @link(TSynaClient) object!

   Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TLDAPSend = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FResultCode: integer;
    FResultString: ansistring;
    FFullResult: ansistring;
    FAutoTLS: boolean;
    FFullSSL: boolean;
    FSeq: integer;
    FResponseCode: integer;
    FResponseDN: ansistring;
    FReferals: TStringList;
    FVersion: integer;
    FSearchScope: TLDAPSearchScope;
    FSearchAliases: TLDAPSearchAliases;
    FSearchSizeLimit: integer;
    FSearchTimeLimit: integer;
    FSearchResult: TLDAPResultList;
    FExtName: ansistring;
    FExtValue: ansistring;
    FUNCTION Connect: boolean;
    FUNCTION BuildPacket(CONST value: ansistring): ansistring;
    FUNCTION ReceiveResponse: ansistring;
    FUNCTION DecodeResponse(CONST value: ansistring): ansistring;
    FUNCTION LdapSasl(value: ansistring): ansistring;
    FUNCTION TranslateFilter(value: ansistring): ansistring;
    FUNCTION GetErrorString(value: integer): ansistring;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Try to connect to LDAP server and start secure channel, when it is required.}
    FUNCTION Login: boolean;

    {:Try to bind to LDAP server with @link(TSynaClient.Username) and
     @link(TSynaClient.Password). if this is empty strings, then it do annonymous
     Bind. When you not call Bind on LDAPv3, then is automaticly used anonymous
     mode.

     This method using plaintext transport of password! it is not secure!}
    FUNCTION Bind: boolean;

    {:Try to bind to LDAP server with @link(TSynaClient.Username) and
     @link(TSynaClient.Password). if this is empty strings, then it do annonymous
     Bind. When you not call Bind on LDAPv3, then is automaticly used anonymous
     mode.

     This method using SASL with DIGEST-MD5 method for secure transfer of your
     password.}
    FUNCTION BindSasl: boolean;

    {:Close connection to LDAP server.}
    FUNCTION Logout: boolean;

    {:Modify content of LDAP attribute on this object.}
    FUNCTION modify(obj: ansistring; op: TLDAPModifyOp; CONST value: TLDAPAttribute): boolean;

    {:Add list of attributes to specified object.}
    FUNCTION add(obj: ansistring; CONST value: TLDAPAttributeList): boolean;

    {:Delete this LDAP object from server.}
    FUNCTION Delete(obj: ansistring): boolean;

    {:Modify object name of this LDAP object.}
    FUNCTION ModifyDN(obj, newRDN, newSuperior: ansistring; DeleteoldRDN: boolean): boolean;

    {:Try to compare Attribute value with this LDAP object.}
    FUNCTION Compare(obj, AttributeValue: ansistring): boolean;

    {:Search LDAP base for LDAP objects by Filter.}
    FUNCTION Search(obj: ansistring; TypesOnly: boolean; Filter: ansistring;
      CONST Attributes: TStrings): boolean;

    {:Call any LDAPv3 extended command.}
    FUNCTION extended(CONST name, value: ansistring): boolean;

    {:Try to start SSL/TLS connection to LDAP server.}
    FUNCTION StartTLS: boolean;
  Published
    {:Specify version of used LDAP protocol. Default value is 3.}
    PROPERTY Version: integer read FVersion write FVersion;

    {:Result code of last LDAP operation.}
    PROPERTY ResultCode: integer read FResultCode;

    {:Human readable description of result code of last LDAP operation.}
    PROPERTY resultString: ansistring read FResultString;

    {:Binary string with full last response of LDAP server. This string is
     encoded by ASN.1 BER encoding! You need this only for debugging.}
    PROPERTY FullResult: ansistring read FFullResult;

    {:If @true, then try to start TSL mode in Login procedure.}
    PROPERTY AutoTLS: boolean read FAutoTLS write FAutoTLS;

    {:If @true, then use connection to LDAP server through SSL/TLS tunnel.}
    PROPERTY FullSSL: boolean read FFullSSL write FFullSSL;

    {:Sequence number of last LDAp command. It is incremented by any LDAP command.}
    PROPERTY Seq: integer read FSeq;

    {:Specify what search scope is used in search command.}
    PROPERTY SearchScope: TLDAPSearchScope read FSearchScope write FSearchScope;

    {:Specify how to handle aliases in search command.}
    PROPERTY SearchAliases: TLDAPSearchAliases read FSearchAliases write FSearchAliases;

    {:Specify result size limit in search command. Value 0 means without limit.}
    PROPERTY SearchSizeLimit: integer read FSearchSizeLimit write FSearchSizeLimit;

    {:Specify search time limit in search command (seconds). Value 0 means
     without limit.}
    PROPERTY SearchTimeLimit: integer read FSearchTimeLimit write FSearchTimeLimit;

    {:Here is result of search command.}
    PROPERTY SearchResult: TLDAPResultList read FSearchResult;

    {:On each LDAP operation can LDAP server return some referals URLs. Here is
     their list.}
    PROPERTY Referals: TStringList read FReferals;

    {:When you call @link(Extended) operation, then here is result Name returned
     by Server.}
    PROPERTY ExtName: ansistring read FExtName;

    {:When you call @link(Extended) operation, then here is result Value returned
     by Server.}
    PROPERTY ExtValue: ansistring read FExtValue;

    {:TCP socket used by all LDAP operations.}
    PROPERTY Sock: TTCPBlockSocket read FSock;
  end;

{:Dump result of LDAP SEARCH into human readable form. Good for debugging.}
FUNCTION LDAPResultDump(CONST value: TLDAPResultList): ansistring;

IMPLEMENTATION

{==============================================================================}
FUNCTION TLDAPAttribute.get(index: integer): string;
begin
  result := inherited get(index);
  if FIsbinary then
    result := DecodeBase64(result);
end;

PROCEDURE TLDAPAttribute.put(index: integer; CONST value: string);
VAR
  s: ansistring;
begin
  s := value;
  if FIsbinary then
    s := EncodeBase64(value)
  else
    s :=UnquoteStr(s, '"');
  inherited put(index, s);
end;

PROCEDURE TLDAPAttribute.SetAttributeName(value: ansistring);
begin
  FAttributeName := value;
  FIsBinary := pos(';binary', lowercase(value)) > 0;
end;

{==============================================================================}
CONSTRUCTOR TLDAPAttributeList.create;
begin
  inherited create;
  FAttributeList := TList.create;
end;

DESTRUCTOR TLDAPAttributeList.destroy;
begin
  clear;
  FAttributeList.free;
  inherited destroy;
end;

PROCEDURE TLDAPAttributeList.clear;
VAR
  n: integer;
  x: TLDAPAttribute;
begin
  for n := count - 1 downto 0 do
  begin
    x := GetAttribute(n);
    if Assigned(x) then
      x.free;
  end;
  FAttributeList.clear;
end;

FUNCTION TLDAPAttributeList.count: integer;
begin
  result := FAttributeList.count;
end;

FUNCTION TLDAPAttributeList.get(AttributeName: ansistring): string;
VAR
  x: TLDAPAttribute;
begin
  result := '';
  x := self.find(AttributeName);
  if x <> nil then
    if x.count > 0 then
      result := x[0];
end;

FUNCTION TLDAPAttributeList.GetAttribute(index: integer): TLDAPAttribute;
begin
  result := nil;
  if index < count then
    result := TLDAPAttribute(FAttributeList[index]);
end;

FUNCTION TLDAPAttributeList.add: TLDAPAttribute;
begin
  result := TLDAPAttribute.create;
  FAttributeList.add(result);
end;

PROCEDURE TLDAPAttributeList.Del(index: integer);
VAR
  x: TLDAPAttribute;
begin
  x := GetAttribute(index);
  if Assigned(x) then
    x.free;
  FAttributeList.Delete(index);
end;

FUNCTION TLDAPAttributeList.find(AttributeName: ansistring): TLDAPAttribute;
VAR
  n: integer;
  x: TLDAPAttribute;
begin
  result := nil;
  AttributeName := lowercase(AttributeName);
  for n := 0 to count - 1 do
  begin
    x := GetAttribute(n);
    if Assigned(x) then
      if lowercase(x.AttributeName) = Attributename then
      begin
        result := x;
        break;
      end;
  end;
end;

{==============================================================================}
CONSTRUCTOR TLDAPResult.create;
begin
  inherited create;
  FAttributes := TLDAPAttributeList.create;
end;

DESTRUCTOR TLDAPResult.destroy;
begin
  FAttributes.free;
  inherited destroy;
end;

{==============================================================================}
CONSTRUCTOR TLDAPResultList.create;
begin
  inherited create;
  FResultList := TList.create;
end;

DESTRUCTOR TLDAPResultList.destroy;
begin
  clear;
  FResultList.free;
  inherited destroy;
end;

PROCEDURE TLDAPResultList.clear;
VAR
  n: integer;
  x: TLDAPResult;
begin
  for n := count - 1 downto 0 do
  begin
    x := GetResult(n);
    if Assigned(x) then
      x.free;
  end;
  FResultList.clear;
end;

FUNCTION TLDAPResultList.count: integer;
begin
  result := FResultList.count;
end;

FUNCTION TLDAPResultList.GetResult(index: integer): TLDAPResult;
begin
  result := nil;
  if index < count then
    result := TLDAPResult(FResultList[index]);
end;

FUNCTION TLDAPResultList.add: TLDAPResult;
begin
  result := TLDAPResult.create;
  FResultList.add(result);
end;

{==============================================================================}
CONSTRUCTOR TLDAPSend.create;
begin
  inherited create;
  FReferals := TStringList.create;
  FFullResult := '';
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FTimeout := 60000;
  FTargetPort := cLDAPProtocol;
  FAutoTLS := false;
  FFullSSL := false;
  FSeq := 0;
  FVersion := 3;
  FSearchScope := SS_WholeSubtree;
  FSearchAliases := SA_Always;
  FSearchSizeLimit := 0;
  FSearchTimeLimit := 0;
  FSearchResult := TLDAPResultList.create;
end;

DESTRUCTOR TLDAPSend.destroy;
begin
  FSock.free;
  FSearchResult.free;
  FReferals.free;
  inherited destroy;
end;

FUNCTION TLDAPSend.GetErrorString(value: integer): ansistring;
begin
  case value of
    0:
      result := 'Success';
    1:
      result := 'Operations error';
    2:
      result := 'Protocol error';
    3:
      result := 'Time limit Exceeded';
    4:
      result := 'Size limit Exceeded';
    5:
      result := 'Compare FALSE';
    6:
      result := 'Compare TRUE';
    7:
      result := 'Auth method not supported';
    8:
      result := 'Strong auth required';
    9:
      result := '-- reserved --';
    10:
      result := 'Referal';
    11:
      result := 'Admin limit exceeded';
    12:
      result := 'Unavailable critical extension';
    13:
      result := 'Confidentality required';
    14:
      result := 'Sasl bind in progress';
    16:
      result := 'No such attribute';
    17:
      result := 'Undefined attribute type';
    18:
      result := 'Inappropriate matching';
    19:
      result := 'Constraint violation';
    20:
      result := 'Attribute or value exists';
    21:
      result := 'Invalid attribute syntax';
    32:
      result := 'No such object';
    33:
      result := 'Alias problem';
    34:
      result := 'Invalid DN syntax';
    36:
      result := 'Alias dereferencing problem';
    48:
      result := 'Inappropriate authentication';
    49:
      result := 'Invalid credentials';
    50:
      result := 'Insufficient access rights';
    51:
      result := 'Busy';
    52:
      result := 'Unavailable';
    53:
      result := 'Unwilling to perform';
    54:
      result := 'Loop detect';
    64:
      result := 'Naming violation';
    65:
      result := 'Object class violation';
    66:
      result := 'Not allowed on non leaf';
    67:
      result := 'Not allowed on RDN';
    68:
      result := 'Entry already exists';
    69:
      result := 'Object class mods prohibited';
    71:
      result := 'Affects multiple DSAs';
    80:
      result := 'Other';
  else
    result := '--unknown--';
  end;
end;

FUNCTION TLDAPSend.Connect: boolean;
begin
  // Do not call this function! It is calling by LOGIN method!
  FSock.CloseSocket;
  FSock.LineBuffer := '';
  FSeq := 0;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError = 0 then
    FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError = 0 then
    if FFullSSL then
      FSock.SSLDoConnect;
  result := FSock.LastError = 0;
end;

FUNCTION TLDAPSend.BuildPacket(CONST value: ansistring): ansistring;
begin
  inc(FSeq);
  result := ASNObject(ASNObject(ASNEncInt(FSeq), ASN1_INT) + value,  ASN1_SEQ);
end;

FUNCTION TLDAPSend.ReceiveResponse: ansistring;
VAR
  x: byte;
  i,j: integer;
begin
  result := '';
  FFullResult := '';
  x := FSock.RecvByte(FTimeout);
  if x <> ASN1_SEQ then
    exit;
  result := AnsiChar(x);
  x := FSock.RecvByte(FTimeout);
  result := result + AnsiChar(x);
  if x < $80 then
    i := 0
  else
    i := x and $7F;
  if i > 0 then
    result := result + FSock.RecvBufferStr(i, Ftimeout);
  if FSock.LastError <> 0 then
  begin
    result := '';
    exit;
  end;
  //get length of LDAP packet
  j := 2;
  i := ASNDecLen(j, result);
  //retreive rest of LDAP packet
  if i > 0 then
    result := result + FSock.RecvBufferStr(i, Ftimeout);
  if FSock.LastError <> 0 then
  begin
    result := '';
    exit;
  end;
  FFullResult := result;
end;

FUNCTION TLDAPSend.DecodeResponse(CONST value: ansistring): ansistring;
VAR
  i, x: integer;
  Svt: integer;
  s, t: ansistring;
begin
  result := '';
  FResultCode := -1;
  FResultstring := '';
  FResponseCode := -1;
  FResponseDN := '';
  FReferals.clear;
  i := 1;
  ASNItem(i, value, Svt);
  x := strToIntDef(ASNItem(i, value, Svt), 0);
  if (svt <> ASN1_INT) or (x <> FSeq) then
    exit;
  s := ASNItem(i, value, Svt);
  FResponseCode := svt;
  if FResponseCode in [LDAP_ASN1_BIND_RESPONSE, LDAP_ASN1_SEARCH_DONE,
    LDAP_ASN1_MODIFY_RESPONSE, LDAP_ASN1_ADD_RESPONSE, LDAP_ASN1_DEL_RESPONSE,
    LDAP_ASN1_MODIFYDN_RESPONSE, LDAP_ASN1_COMPARE_RESPONSE,
    LDAP_ASN1_EXT_RESPONSE] then
  begin
    FResultCode := strToIntDef(ASNItem(i, value, Svt), -1);
    FResponseDN := ASNItem(i, value, Svt);
    FResultString := ASNItem(i, value, Svt);
    if FResultString = '' then
      FResultString := GetErrorString(FResultCode);
    if FResultCode = 10 then
    begin
      s := ASNItem(i, value, Svt);
      if svt = $A3 then
      begin
        x := 1;
        while x < length(s) do
        begin
          t := ASNItem(x, s, Svt);
          FReferals.add(t);
        end;
      end;
    end;
  end;
  result := copy(value, i, length(value) - i + 1);
end;

FUNCTION TLDAPSend.LdapSasl(value: ansistring): ansistring;
VAR
  nonce, cnonce, nc, realm, qop, uri, response: ansistring;
  s: ansistring;
  a1, a2: ansistring;
  l: TStringList;
  n: integer;
begin
  l := TStringList.create;
  try
    nonce := '';
    realm := '';
    l.CommaText := value;
    n := IndexByBegin('nonce=', l);
    if n >= 0 then
      nonce := UnQuoteStr(trim(SeparateRight(l[n], 'nonce=')), '"');
    n := IndexByBegin('realm=', l);
    if n >= 0 then
      realm := UnQuoteStr(trim(SeparateRight(l[n], 'realm=')), '"');
    cnonce := IntToHex(GetTick, 8);
    nc := '00000001';
    qop := 'auth';
    uri := 'ldap/' + FSock.ResolveIpToName(FSock.GetRemoteSinIP);
    a1 := md5(FUsername + ':' + realm + ':' + FPassword)
      + ':' + nonce + ':' + cnonce;
    a2 := 'AUTHENTICATE:' + uri;
    s := strtohex(md5(a1))+':' + nonce + ':' + nc + ':' + cnonce + ':'
      + qop +':'+strtohex(md5(a2));
    response := strtohex(md5(s));

    result := 'username="' + Fusername + '",realm="' + realm + '",nonce="';
    result := result + nonce + '",cnonce="' + cnonce + '",nc=' + nc + ',qop=';
    result := result + qop + ',digest-uri="' + uri + '",response=' + response;
  finally
    l.free;
  end;
end;

FUNCTION TLDAPSend.TranslateFilter(value: ansistring): ansistring;
VAR
  x: integer;
  s, t, l: ansistring;
  r: string;
  c: Ansichar;
  Attr, rule: ansistring;
  dn: boolean;
begin
  result := '';
  if value = '' then
    exit;
  s := value;
  if value[1] = '(' then
  begin
    x := RPos(')', value);
    s := copy(value, 2, x - 2);
  end;
  if s = '' then
    exit;
  case s[1] of
    '!':
      // NOT rule (recursive call)
      begin
        result := ASNOBject(TranslateFilter(GetBetween('(', ')', s)), $A2);
      end;
    '&':
      // AND rule (recursive call)
      begin
        repeat
          t := GetBetween('(', ')', s);
          s := trim(SeparateRight(s, t));
          if s <> '' then
            if s[1] = ')' then
              {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(s, 1, 1);
          result := result + TranslateFilter(t);
        until s = '';
        result := ASNOBject(result, $A0);
      end;
    '|':
      // OR rule (recursive call)
      begin
        repeat
          t := GetBetween('(', ')', s);
          s := trim(SeparateRight(s, t));
          if s <> '' then
            if s[1] = ')' then
              {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(s, 1, 1);
          result := result + TranslateFilter(t);
        until s = '';
        result := ASNOBject(result, $A1);
      end;
    else
      begin
        l := trim(SeparateLeft(s, '='));
        r := trim(SeparateRight(s, '='));
        if l <> '' then
        begin
          c := l[length(l)];
          case c of
            ':':
              // Extensible match
              begin
                {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(l, length(l), 1);
                dn := false;
                Attr := '';
                rule := '';
                if pos(':dn', l) > 0 then
                begin
                  dn := true;
                  l := ReplaceString(l, ':dn', '');
                end;
                Attr := trim(SeparateLeft(l, ':'));
                rule := trim(SeparateRight(l, ':'));
                if rule = l then
                  rule := '';
                if rule <> '' then
                  result := ASNObject(rule, $81);
                if Attr <> '' then
                  result := result + ASNObject(Attr, $82);
                result := result + ASNObject(DecodeTriplet(r, '\'), $83);
                if dn then
                  result := result + ASNObject(AsnEncInt($ff), $84)
                else
                  result := result + ASNObject(AsnEncInt(0), $84);
                result := ASNOBject(result, $a9);
              end;
            '~':
              // Approx match
              begin
                {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(l, length(l), 1);
                result := ASNOBject(l, ASN1_OCTSTR)
                  + ASNOBject(DecodeTriplet(r, '\'), ASN1_OCTSTR);
                result := ASNOBject(result, $a8);
              end;
            '>':
              // Greater or equal match
              begin
                {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(l, length(l), 1);
                result := ASNOBject(l, ASN1_OCTSTR)
                  + ASNOBject(DecodeTriplet(r, '\'), ASN1_OCTSTR);
                result := ASNOBject(result, $a5);
              end;
            '<':
              // Less or equal match
              begin
                {$IFDEF CIL}Borland.Delphi.{$ENDIF}system.Delete(l, length(l), 1);
                result := ASNOBject(l, ASN1_OCTSTR)
                  + ASNOBject(DecodeTriplet(r, '\'), ASN1_OCTSTR);
                result := ASNOBject(result, $a6);
              end;
          else
            // present
            if r = '*' then
              result := ASNOBject(l, $87)
            else
              if pos('*', r) > 0 then
              // substrings
              begin
                s := Fetch(r, '*');
                if s <> '' then
                  result := ASNOBject(DecodeTriplet(s, '\'), $80);
                while r <> '' do
                begin
                  if pos('*', r) <= 0 then
                    break;
                  s := Fetch(r, '*');
                  result := result + ASNOBject(DecodeTriplet(s, '\'), $81);
                end;
                if r <> '' then
                  result := result + ASNOBject(DecodeTriplet(r, '\'), $82);
                result := ASNOBject(l, ASN1_OCTSTR)
                  + ASNOBject(result, ASN1_SEQ);
                result := ASNOBject(result, $a4);
              end
              else
              begin
                // Equality match
                result := ASNOBject(l, ASN1_OCTSTR)
                  + ASNOBject(DecodeTriplet(r, '\'), ASN1_OCTSTR);
                result := ASNOBject(result, $a3);
              end;
          end;
        end;
      end;
  end;
end;

FUNCTION TLDAPSend.Login: boolean;
begin
  result := false;
  if not Connect then
    exit;
  result := true;
  if FAutoTLS then
    result := StartTLS;
end;

FUNCTION TLDAPSend.Bind: boolean;
VAR
  s: ansistring;
begin
  s := ASNObject(ASNEncInt(FVersion), ASN1_INT)
    + ASNObject(FUsername, ASN1_OCTSTR)
    + ASNObject(FPassword, $80);
  s := ASNObject(s, LDAP_ASN1_BIND_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.BindSasl: boolean;
VAR
  s, t: ansistring;
  x, xt: integer;
  digreq: ansistring;
begin
  result := false;
  if FPassword = '' then
    result := Bind
  else
  begin
    digreq := ASNObject(ASNEncInt(FVersion), ASN1_INT)
      + ASNObject('', ASN1_OCTSTR)
      + ASNObject(ASNObject('DIGEST-MD5', ASN1_OCTSTR), $A3);
    digreq := ASNObject(digreq, LDAP_ASN1_BIND_REQUEST);
    Fsock.SendString(BuildPacket(digreq));
    s := ReceiveResponse;
    t := DecodeResponse(s);
    if FResultCode = 14 then
    begin
      s := t;
      x := 1;
      t := ASNItem(x, s, xt);
      s := ASNObject(ASNEncInt(FVersion), ASN1_INT)
        + ASNObject('', ASN1_OCTSTR)
        + ASNObject(ASNObject('DIGEST-MD5', ASN1_OCTSTR)
          + ASNObject(LdapSasl(t), ASN1_OCTSTR), $A3);
      s := ASNObject(s, LDAP_ASN1_BIND_REQUEST);
      Fsock.SendString(BuildPacket(s));
      s := ReceiveResponse;
      DecodeResponse(s);
      if FResultCode = 14 then
      begin
        Fsock.SendString(BuildPacket(digreq));
        s := ReceiveResponse;
        DecodeResponse(s);
      end;
      result := FResultCode = 0;
    end;
  end;
end;

FUNCTION TLDAPSend.Logout: boolean;
begin
  Fsock.SendString(BuildPacket(ASNObject('', LDAP_ASN1_UNBIND_REQUEST)));
  FSock.CloseSocket;
  result := true;
end;

FUNCTION TLDAPSend.modify(obj: ansistring; op: TLDAPModifyOp; CONST value: TLDAPAttribute): boolean;
VAR
  s: ansistring;
  n: integer;
begin
  s := '';
  for n := 0 to value.count -1 do
    s := s + ASNObject(value[n], ASN1_OCTSTR);
  s := ASNObject(value.AttributeName, ASN1_OCTSTR) + ASNObject(s, ASN1_SETOF);
  s := ASNObject(ASNEncInt(ord(op)), ASN1_ENUM) + ASNObject(s, ASN1_SEQ);
  s := ASNObject(s, ASN1_SEQ);
  s := ASNObject(obj, ASN1_OCTSTR) + ASNObject(s, ASN1_SEQ);
  s := ASNObject(s, LDAP_ASN1_MODIFY_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.add(obj: ansistring; CONST value: TLDAPAttributeList): boolean;
VAR
  s, t: ansistring;
  n, m: integer;
begin
  s := '';
  for n := 0 to value.count - 1 do
  begin
    t := '';
    for m := 0 to value[n].count - 1 do
      t := t + ASNObject(value[n][m], ASN1_OCTSTR);
    t := ASNObject(value[n].AttributeName, ASN1_OCTSTR)
      + ASNObject(t, ASN1_SETOF);
    s := s + ASNObject(t, ASN1_SEQ);
  end;
  s := ASNObject(obj, ASN1_OCTSTR) + ASNObject(s, ASN1_SEQ);
  s := ASNObject(s, LDAP_ASN1_ADD_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.Delete(obj: ansistring): boolean;
VAR
  s: ansistring;
begin
  s := ASNObject(obj, LDAP_ASN1_DEL_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.ModifyDN(obj, newRDN, newSuperior: ansistring; DeleteOldRDN: boolean): boolean;
VAR
  s: ansistring;
begin
  s := ASNObject(obj, ASN1_OCTSTR) + ASNObject(newRDN, ASN1_OCTSTR);
  if DeleteOldRDN then
    s := s + ASNObject(ASNEncInt($ff), ASN1_BOOL)
  else
    s := s + ASNObject(ASNEncInt(0), ASN1_BOOL);
  if newSuperior <> '' then
    s := s + ASNObject(newSuperior, $80);
  s := ASNObject(s, LDAP_ASN1_MODIFYDN_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.Compare(obj, AttributeValue: ansistring): boolean;
VAR
  s: ansistring;
begin
  s := ASNObject(trim(SeparateLeft(AttributeValue, '=')), ASN1_OCTSTR)
    + ASNObject(trim(SeparateRight(AttributeValue, '=')), ASN1_OCTSTR);
  s := ASNObject(obj, ASN1_OCTSTR) + ASNObject(s, ASN1_SEQ);
  s := ASNObject(s, LDAP_ASN1_COMPARE_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  DecodeResponse(s);
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.Search(obj: ansistring; TypesOnly: boolean; Filter: ansistring;
  CONST Attributes: TStrings): boolean;
VAR
  s, t, u: ansistring;
  n, i, x: integer;
  r: TLDAPResult;
  a: TLDAPAttribute;
begin
  FSearchResult.clear;
  FReferals.clear;
  s := ASNObject(obj, ASN1_OCTSTR);
  s := s + ASNObject(ASNEncInt(ord(FSearchScope)), ASN1_ENUM);
  s := s + ASNObject(ASNEncInt(ord(FSearchAliases)), ASN1_ENUM);
  s := s + ASNObject(ASNEncInt(FSearchSizeLimit), ASN1_INT);
  s := s + ASNObject(ASNEncInt(FSearchTimeLimit), ASN1_INT);
  if TypesOnly then
    s := s + ASNObject(ASNEncInt($ff), ASN1_BOOL)
  else
    s := s + ASNObject(ASNEncInt(0), ASN1_BOOL);
  if Filter = '' then
    Filter := '(objectclass=*)';
  t := TranslateFilter(Filter);
  if t = '' then
    s := s + ASNObject('', ASN1_NULL)
  else
    s := s + t;
  t := '';
  for n := 0 to Attributes.count - 1 do
    t := t + ASNObject(Attributes[n], ASN1_OCTSTR);
  s := s + ASNObject(t, ASN1_SEQ);
  s := ASNObject(s, LDAP_ASN1_SEARCH_REQUEST);
  Fsock.SendString(BuildPacket(s));
  repeat
    s := ReceiveResponse;
    t := DecodeResponse(s);
    if FResponseCode = LDAP_ASN1_SEARCH_ENTRY then
    begin
      //dekoduj zaznam
      r := FSearchResult.add;
      n := 1;
      r.ObjectName := ASNItem(n, t, x);
      ASNItem(n, t, x);
      if x = ASN1_SEQ then
      begin
        while n < length(t) do
        begin
          s := ASNItem(n, t, x);
          if x = ASN1_SEQ then
          begin
            i := n + length(s);
            a := r.Attributes.add;
            u := ASNItem(n, t, x);
            a.AttributeName := u;
            ASNItem(n, t, x);
            if x = ASN1_SETOF then
              while n < i do
              begin
                u := ASNItem(n, t, x);
                a.add(u);
              end;
          end;
        end;
      end;
    end;
    if FResponseCode = LDAP_ASN1_SEARCH_REFERENCE then
    begin
      n := 1;
      while n < length(t) do
        FReferals.add(ASNItem(n, t, x));
    end;
  until FResponseCode = LDAP_ASN1_SEARCH_DONE;
  result := FResultCode = 0;
end;

FUNCTION TLDAPSend.extended(CONST name, value: ansistring): boolean;
VAR
  s, t: ansistring;
  x, xt: integer;
begin
  s := ASNObject(name, $80);
  if value <> '' then
    s := s + ASNObject(value, $81);
  s := ASNObject(s, LDAP_ASN1_EXT_REQUEST);
  Fsock.SendString(BuildPacket(s));
  s := ReceiveResponse;
  t := DecodeResponse(s);
  result := FResultCode = 0;
  if result then
  begin
    x := 1;
    FExtName := ASNItem(x, t, xt);
    FExtValue := ASNItem(x, t, xt);
  end;
end;


FUNCTION TLDAPSend.StartTLS: boolean;
begin
  result := extended('1.3.6.1.4.1.1466.20037', '');
  if result then
  begin
    Fsock.SSLDoConnect;
    result := FSock.LastError = 0;
  end;
end;

{==============================================================================}
FUNCTION LDAPResultDump(CONST value: TLDAPResultList): ansistring;
VAR
  n, m, o: integer;
  r: TLDAPResult;
  a: TLDAPAttribute;
begin
  result := 'Results: ' + intToStr(value.count) + CRLF +CRLF;
  for n := 0 to value.count - 1 do
  begin
    result := result + 'Result: ' + intToStr(n) + CRLF;
    r := value[n];
    result := result + '  Object: ' + r.ObjectName + CRLF;
    for m := 0 to r.Attributes.count - 1 do
    begin
      a := r.Attributes[m];
      result := result + '  Attribute: ' + a.AttributeName + CRLF;
      for o := 0 to a.count - 1 do
        result := result + '    ' + a[o] + CRLF;
    end;
  end;
end;

end.
