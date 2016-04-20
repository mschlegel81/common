{==============================================================================|
| project : Ararat Synapse                                       | 001.003.001 |
|==============================================================================|
| content: misc. procedures and functions                                      |
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
| Portions created by Lukas Gebauer are Copyright (c) 2002-2010.               |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Misc. network based utilities)}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$Q-}
{$H+}

//Kylix does not known UNIX define
{$IFDEF LINUX}
  {$IFNDEF UNIX}
    {$DEFINE UNIX}
  {$ENDIF}
{$ENDIF}

{$TYPEDADDRESS OFF}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT synamisc;

INTERFACE

{$IFDEF VER125}
  {$DEFINE BCB}
{$ENDIF}
{$IFDEF BCB}
  {$ObjExportAll On}
  {$HPPEMIT '#pragma comment( lib , "wininet.lib" )'}
{$ENDIF}

USES
  synautil, blcksock, sysutils, Classes
{$IFDEF UNIX}
  {$IFNDEF FPC}
  , Libc
  {$ENDIF}
{$ELSE}
  , windows
{$ENDIF}
;

TYPE
  {:@abstract(This record contains information about proxy setting.)}
  TProxySetting = record
    Host: string;
    Port: string;
    Bypass: string;
  end;

{:By this function you can turn-on computer on network, if this computer
 supporting Wake-on-lan feature. You need MAC number (network card indentifier)
 of computer for turn-on. You can also assign target IP addres. if you not
 specify it, then is used broadcast for delivery magic wake-on packet. However
 broadcasts workinh only on your local network. When you need to wake-up
 computer on another network, you must specify any existing IP addres on same
 network segment as targeting computer.}
PROCEDURE WakeOnLan(MAC, IP: string);

{:Autodetect current DNS servers used by system. If is defined more then one DNS
 Server, then result is comma-delimited.}
FUNCTION GetDNS: string;

{:Autodetect InternetExplorer proxy setting for given protocol. This function
working only on windows!}
FUNCTION GetIEProxy(protocol: string): TProxySetting;

{:Return all known IP addresses on local system. Addresses are divided by comma.}
FUNCTION GetLocalIPs: string;

IMPLEMENTATION

{==============================================================================}
PROCEDURE WakeOnLan(MAC, IP: string);
VAR
  sock: TUDPBlockSocket;
  HexMac: ansistring;
  data: ansistring;
  n: integer;
  b: byte;
begin
  if MAC <> '' then
  begin
    MAC := ReplaceString(MAC, '-', '');
    MAC := ReplaceString(MAC, ':', '');
    if length(MAC) < 12 then
      exit;
    HexMac := '';
    for n := 0 to 5 do
    begin
      b := strToIntDef('$' + MAC[n * 2 + 1] + MAC[n * 2 + 2], 0);
      HexMac := HexMac + char(b);
    end;
    if IP = '' then
      IP := cBroadcast;
    sock := TUDPBlockSocket.create;
    try
      sock.CreateSocket;
      sock.EnableBroadcast(true);
      sock.Connect(IP, '9');
      data := #$ff + #$ff + #$ff + #$ff + #$ff + #$ff;
      for n := 1 to 16 do
        data := data + HexMac;
      sock.SendString(data);
    finally
      sock.free;
    end;
  end;
end;

{==============================================================================}

{$IFNDEF UNIX}
FUNCTION GetDNSbyIpHlp: string;
TYPE
  PTIP_ADDRESS_STRING = ^TIP_ADDRESS_STRING;
  TIP_ADDRESS_STRING = array[0..15] of Ansichar;
  PTIP_ADDR_STRING = ^TIP_ADDR_STRING;
  TIP_ADDR_STRING = packed record
    next: PTIP_ADDR_STRING;
    IpAddress: TIP_ADDRESS_STRING;
    IpMask: TIP_ADDRESS_STRING;
    context: dword;
  end;
  PTFixedInfo = ^TFixedInfo;
  TFixedInfo = packed record
    HostName: array[1..128 + 4] of Ansichar;
    DomainName: array[1..128 + 4] of Ansichar;
    CurrentDNSServer: PTIP_ADDR_STRING;
    DNSServerList: TIP_ADDR_STRING;
    NodeType: UINT;
    ScopeID: array[1..256 + 4] of Ansichar;
    EnableRouting: UINT;
    EnableProxy: UINT;
    EnableDNS: UINT;
  end;
CONST
  IpHlpDLL = 'IPHLPAPI.DLL';
VAR
  IpHlpModule: THandle;
  FixedInfo: PTFixedInfo;
  InfoSize: longint;
  PDnsServer: PTIP_ADDR_STRING;
  err: integer;
  GetNetworkParams: FUNCTION(FixedInfo: PTFixedInfo; pOutPutLen: PULONG): dword; stdcall;
begin
  InfoSize := 0;
  result := '...';
  IpHlpModule := LoadLibrary(IpHlpDLL);
  if IpHlpModule = 0 then
    exit;
  try
    GetNetworkParams := GetProcAddress(IpHlpModule,PAnsiChar(ansistring('GetNetworkParams')));
    if @GetNetworkParams = nil then
      exit;
    err := GetNetworkParams(nil, @InfoSize);
    if err <> ERROR_BUFFER_OVERFLOW then
      exit;
    result := '';
    getMem (FixedInfo, InfoSize);
    try
      err := GetNetworkParams(FixedInfo, @InfoSize);
      if err <> ERROR_SUCCESS then
        exit;
      with FixedInfo^ do
      begin
        result := DnsServerList.IpAddress;
        PDnsServer := DnsServerList.next;
        while PDnsServer <> nil do
        begin
          if result <> '' then
            result := result + ',';
          result := result + PDnsServer^.IPAddress;
          PDnsServer := PDnsServer.next;
        end;
    end;
    finally
      freeMem(FixedInfo);
    end;
  finally
    FreeLibrary(IpHlpModule);
  end;
end;

FUNCTION ReadReg(SubKey, Vn: PChar): string;
VAR
 OpenKey: HKEY;
 DataType, DataSize: integer;
 temp: array [0..2048] of char;
begin
  result := '';
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, SubKey, REG_OPTION_NON_VOLATILE,
    KEY_READ, OpenKey) = ERROR_SUCCESS then
  begin
    DataType := REG_SZ;
    DataSize := sizeOf(temp);
    if RegQueryValueEx(OpenKey, Vn, nil, @DataType, @temp, @DataSize) = ERROR_SUCCESS then
      SetString(result, temp, DataSize div sizeOf(char) - 1);
    RegCloseKey(OpenKey);
   end;
end ;
{$ENDIF}

FUNCTION GetDNS: string;
{$IFDEF UNIX}
VAR
  l: TStringList;
  n: integer;
begin
  result := '';
  l := TStringList.create;
  try
    l.loadFromFile('/etc/resolv.conf');
    for n := 0 to l.count - 1 do
      if pos('NAMESERVER', uppercase(l[n])) = 1 then
      begin
        if result <> '' then
          result := result + ',';
        result := result + SeparateRight(l[n], ' ');
      end;
  finally
    l.free;
  end;
end;
{$ELSE}
CONST
  NTdyn = 'System\CurrentControlSet\Services\Tcpip\Parameters\Temporary';
  NTfix = 'System\CurrentControlSet\Services\Tcpip\Parameters';
  W9xfix = 'System\CurrentControlSet\Services\MSTCP';
begin
  result := GetDNSbyIpHlp;
  if result = '...' then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      result := ReadReg(NTdyn, 'NameServer');
      if result = '' then
        result := ReadReg(NTfix, 'NameServer');
      if result = '' then
        result := ReadReg(NTfix, 'DhcpNameServer');
    end
    else
      result := ReadReg(W9xfix, 'NameServer');
    result := ReplaceString(trim(result), ' ', ',');
  end;
end;
{$ENDIF}

{==============================================================================}

FUNCTION GetIEProxy(protocol: string): TProxySetting;
{$IFDEF UNIX}
begin
  result.Host := '';
  result.Port := '';
  result.Bypass := '';
end;
{$ELSE}
TYPE
  PInternetProxyInfo = ^TInternetProxyInfo;
  TInternetProxyInfo = packed record
    dwAccessType: dword;
    lpszProxy: LPCSTR;
    lpszProxyBypass: LPCSTR;
  end;
CONST
  INTERNET_OPTION_PROXY = 38;
  INTERNET_OPEN_TYPE_PROXY = 3;
  WininetDLL = 'WININET.DLL';
VAR
  WininetModule: THandle;
  ProxyInfo: PInternetProxyInfo;
  Err: boolean;
  len: dword;
  Proxy: string;
  DefProxy: string;
  ProxyList: TStringList;
  n: integer;
  InternetQueryOption: FUNCTION (hInet: pointer; dwOption: dword;
    lpBuffer: pointer; VAR lpdwBufferLength: dword): BOOL; stdcall;
begin
  result.Host := '';
  result.Port := '';
  result.Bypass := '';
  WininetModule := LoadLibrary(WininetDLL);
  if WininetModule = 0 then
    exit;
  try
    InternetQueryOption := GetProcAddress(WininetModule,PAnsiChar(ansistring('InternetQueryOptionA')));
    if @InternetQueryOption = nil then
      exit;

    if protocol = '' then
      protocol := 'http';
    len := 4096;
    getMem(ProxyInfo, len);
    ProxyList := TStringList.create;
    try
      Err := InternetQueryOption(nil, INTERNET_OPTION_PROXY, ProxyInfo, len);
      if Err then
        if ProxyInfo^.dwAccessType = INTERNET_OPEN_TYPE_PROXY then
        begin
          ProxyList.CommaText := ReplaceString(ProxyInfo^.lpszProxy, ' ', ',');
          Proxy := '';
          DefProxy := '';
          for n := 0 to ProxyList.count -1 do
          begin
            if pos(lowercase(protocol) + '=', lowercase(ProxyList[n])) = 1 then
            begin
              Proxy := SeparateRight(ProxyList[n], '=');
              break;
            end;
            if pos('=', ProxyList[n]) < 1 then
              DefProxy := ProxyList[n];
          end;
          if Proxy = '' then
            Proxy := DefProxy;
          if Proxy <> '' then
          begin
            result.Host := trim(SeparateLeft(Proxy, ':'));
            result.Port := trim(SeparateRight(Proxy, ':'));
          end;
          result.Bypass := ReplaceString(ProxyInfo^.lpszProxyBypass, ' ', ',');
        end;
    finally
      ProxyList.free;
      freeMem(ProxyInfo);
    end;
  finally
    FreeLibrary(WininetModule);
  end;
end;
{$ENDIF}

{==============================================================================}

FUNCTION GetLocalIPs: string;
VAR
  TcpSock: TTCPBlockSocket;
  ipList: TStringList;
begin
  result := '';
  ipList := TStringList.create;
  try
    TcpSock := TTCPBlockSocket.create;
    try
      TcpSock.ResolveNameToIP(TcpSock.LocalName, ipList);
      result := ipList.CommaText;
    finally
      TcpSock.free;
    end;
  finally
    ipList.free;
  end;
end;

{==============================================================================}

end.
