{==============================================================================|
| project : Ararat Synapse                                       | 001.001.001 |
|==============================================================================|
| content: ClamAV-daemon Client                                                |
|==============================================================================|
| Copyright (c)2005-2010, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2005-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract( ClamAV-daemon client)

This UNIT is capable to do antivirus scan of your data by TCP channel to ClamD
daemon from ClamAV. See more about ClamAV on @LINK(http://www.clamav.net)
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

UNIT clamsend;

INTERFACE

USES
  sysutils, Classes,
  synsock, blcksock, synautil;

CONST
  cClamProtocol = '3310';

TYPE

  {:@abstract(Implementation of ClamAV-daemon client protocol)
   by this class you can scan any your data by ClamAV opensource antivirus.

   This class can connect to ClamD by TCP channel, send your data to ClamD
   and read result.}
  TClamSend = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FDSock: TTCPBlockSocket;
    FSession: boolean;
    FUNCTION Login: boolean; virtual;
    FUNCTION Logout: boolean; virtual;
    FUNCTION OpenStream: boolean; virtual;
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Call any command to ClamD. Used internally by other methods.}
    FUNCTION DoCommand(CONST value: ansistring): ansistring; virtual;

    {:Return ClamAV version and version of loaded databases.}
    FUNCTION GetVersion: ansistring; virtual;

    {:Scan content of TStrings.}
    FUNCTION ScanStrings(CONST value: TStrings): ansistring; virtual;

    {:Scan content of TStream.}
    FUNCTION ScanStream(CONST value: TStream): ansistring; virtual;

    {:Scan content of TStrings by new 0.95 API.}
    FUNCTION ScanStrings2(CONST value: TStrings): ansistring; virtual;

    {:Scan content of TStream by new 0.95 API.}
    FUNCTION ScanStream2(CONST value: TStream): ansistring; virtual;
  Published
    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;

    {:Socket object used for TCP data transfer operation. Good for seting OnStatus hook, etc.}
    PROPERTY DSock: TTCPBlockSocket read FDSock;

    {:Can turn-on session mode of communication with ClamD. Default is @false,
     because ClamAV developers design their TCP code very badly and session mode
     is broken now (CVS-20051031). Maybe ClamAV developers fix their bugs
     and this mode will be possible in future.}
    PROPERTY Session: boolean read FSession write FSession;
  end;

IMPLEMENTATION

CONSTRUCTOR TClamSend.create;
begin
  inherited create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FDSock := TTCPBlockSocket.create;
  FDSock.Owner := self;
  FTimeout := 60000;
  FTargetPort := cClamProtocol;
  FSession := false;
end;

DESTRUCTOR TClamSend.destroy;
begin
  Logout;
  FDSock.free;
  FSock.free;
  inherited destroy;
end;

FUNCTION TClamSend.DoCommand(CONST value: ansistring): ansistring;
begin
  result := '';
  if not FSession then
    FSock.CloseSocket
  else
    FSock.SendString(value + LF);
  if not FSession or (FSock.LastError <> 0) then
  begin
    if Login then
      FSock.SendString(value + LF)
    else
      exit;
  end;
  result := FSock.RecvTerminated(FTimeout, LF);
end;

FUNCTION TClamSend.Login: boolean;
begin
  result := false;
  Sock.CloseSocket;
  FSock.Bind(FIPInterface, cAnyPort);
  if FSock.LastError <> 0 then
    exit;
  FSock.Connect(FTargetHost, FTargetPort);
  if FSock.LastError <> 0 then
    exit;
  if FSession then
    FSock.SendString('SESSION' + LF);
  result := FSock.LastError = 0;
end;

FUNCTION TClamSend.Logout: boolean;
begin
  FSock.SendString('END' + LF);
  result := FSock.LastError = 0;
  FSock.CloseSocket;
end;

FUNCTION TClamSend.GetVersion: ansistring;
begin
  result := DoCommand('nVERSION');
end;

FUNCTION TClamSend.OpenStream: boolean;
VAR
  S: ansistring;
begin
  result := false;
  s := DoCommand('nSTREAM');
  if (s <> '') and (copy(s, 1, 4) = 'PORT') then
  begin
    s := SeparateRight(s, ' ');
    FDSock.CloseSocket;
    FDSock.Bind(FIPInterface, cAnyPort);
    if FDSock.LastError <> 0 then
      exit;
    FDSock.Connect(FTargetHost, s);
    if FDSock.LastError <> 0 then
      exit;
    result := true;
  end;
end;

FUNCTION TClamSend.ScanStrings(CONST value: TStrings): ansistring;
begin
  result := '';
  if OpenStream then
  begin
    DSock.SendString(value.text);
    DSock.CloseSocket;
    result := FSock.RecvTerminated(FTimeout, LF);
  end;
end;

FUNCTION TClamSend.ScanStream(CONST value: TStream): ansistring;
begin
  result := '';
  if OpenStream then
  begin
    DSock.SendStreamRaw(value);
    DSock.CloseSocket;
    result := FSock.RecvTerminated(FTimeout, LF);
  end;
end;

FUNCTION TClamSend.ScanStrings2(CONST value: TStrings): ansistring;
VAR
  i: integer;
  s: ansistring;
begin
  result := '';
  if not FSession then
    FSock.CloseSocket
  else
    FSock.sendstring('nINSTREAM' + LF);
  if not FSession or (FSock.LastError <> 0) then
  begin
    if Login then
      FSock.sendstring('nINSTREAM' + LF)
    else
      exit;
  end;
  s := value.text;
  i := length(s);
  FSock.SendString(CodeLongint(i) + s + #0#0#0#0);
  result := FSock.RecvTerminated(FTimeout, LF);
end;

FUNCTION TClamSend.ScanStream2(CONST value: TStream): ansistring;
VAR
  i: integer;
begin
  result := '';
  if not FSession then
    FSock.CloseSocket
  else
    FSock.sendstring('nINSTREAM' + LF);
  if not FSession or (FSock.LastError <> 0) then
  begin
    if Login then
      FSock.sendstring('nINSTREAM' + LF)
    else
      exit;
  end;
  i := value.size;
  FSock.SendString(CodeLongint(i));
  FSock.SendStreamRaw(value);
  FSock.SendString(#0#0#0#0);
  result := FSock.RecvTerminated(FTimeout, LF);
end;

end.
