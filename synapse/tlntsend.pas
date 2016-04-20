{==============================================================================|
| project : Ararat Synapse                                       | 001.003.001 |
|==============================================================================|
| content: TELNET and SSH2 Client                                              |
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
| Portions created by Lukas Gebauer are Copyright (c)2002-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Telnet script client)

used RFC: RFC-854
}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT tlntsend;

INTERFACE

USES
  sysutils, Classes,
  blcksock, synautil;

CONST
  cTelnetProtocol = '23';
  cSSHProtocol = '22';

  TLNT_EOR                = #239;
  TLNT_SE                 = #240;
  TLNT_NOP                = #241;
  TLNT_DATA_MARK          = #242;
  TLNT_BREAK              = #243;
  TLNT_IP                 = #244;
  TLNT_AO                 = #245;
  TLNT_AYT                = #246;
  TLNT_EC                 = #247;
  TLNT_EL                 = #248;
  TLNT_GA                 = #249;
  TLNT_SB                 = #250;
  TLNT_WILL               = #251;
  TLNT_WONT               = #252;
  TLNT_DO                 = #253;
  TLNT_DONT               = #254;
  TLNT_IAC                = #255;

TYPE
  {:@abstract(State of telnet protocol). Used internaly by TTelnetSend.}
  TTelnetState =(tsDATA, tsIAC, tsIAC_SB, tsIAC_WILL, tsIAC_DO, tsIAC_WONT,
     tsIAC_DONT, tsIAC_SBIAC, tsIAC_SBDATA, tsSBDATA_IAC);

  {:@abstract(Class with implementation of Telnet/SSH script client.)

   Note: Are you missing properties for specify Server address and port? Look to
   parent @link(TSynaClient) too!}
  TTelnetSend = class(TSynaClient)
  private
    FSock: TTCPBlockSocket;
    FBuffer: ansistring;
    FState: TTelnetState;
    FSessionLog: ansistring;
    FSubNeg: ansistring;
    FSubType: Ansichar;
    FTermType: ansistring;
    FUNCTION Connect: boolean;
    FUNCTION Negotiate(CONST Buf: ansistring): ansistring;
    PROCEDURE FilterHook(Sender: TObject; VAR value: ansistring);
  public
    CONSTRUCTOR create;
    DESTRUCTOR destroy; override;

    {:Connects to Telnet server.}
    FUNCTION Login: boolean;

    {:Connects to SSH2 server and login by Username and Password properties.

     You must use some of SSL plugins with SSH support. for exammple CryptLib.}
    FUNCTION SSHLogin: boolean;

    {:Logout from telnet server.}
    PROCEDURE Logout;

    {:Send this data to telnet server.}
    PROCEDURE Send(CONST value: string);

    {:Reading data from telnet server until Value is readed. If it is not readed
     until timeout, result is @false. Otherwise result is @true.}
    FUNCTION WaitFor(CONST value: string): boolean;

    {:Read data terminated by terminator from telnet server.}
    FUNCTION RecvTerminated(CONST Terminator: string): string;

    {:Read string from telnet server.}
    FUNCTION RecvString: string;
  Published
    {:Socket object used for TCP/IP operation. Good for seting OnStatus hook, etc.}
    PROPERTY Sock: TTCPBlockSocket read FSock;

    {:all readed datas in this session (from connect) is stored in this large
     string.}
    PROPERTY SessionLog: ansistring read FSessionLog write FSessionLog;

    {:Terminal type indentification. By default is 'SYNAPSE'.}
    PROPERTY TermType: ansistring read FTermType write FTermType;
  end;

IMPLEMENTATION

CONSTRUCTOR TTelnetSend.create;
begin
  inherited create;
  FSock := TTCPBlockSocket.create;
  FSock.Owner := self;
  FSock.OnReadFilter := FilterHook;
  FTimeout := 60000;
  FTargetPort := cTelnetProtocol;
  FSubNeg := '';
  FSubType := #0;
  FTermType := 'SYNAPSE';
end;

DESTRUCTOR TTelnetSend.destroy;
begin
  FSock.free;
  inherited destroy;
end;

FUNCTION TTelnetSend.Connect: boolean;
begin
  // Do not call this function! It is calling by LOGIN method!
  FBuffer := '';
  FSessionLog := '';
  FState := tsDATA;
  FSock.CloseSocket;
  FSock.LineBuffer := '';
  FSock.Bind(FIPInterface, cAnyPort);
  FSock.Connect(FTargetHost, FTargetPort);
  result := FSock.LastError = 0;
end;

FUNCTION TTelnetSend.RecvTerminated(CONST Terminator: string): string;
begin
  result := FSock.RecvTerminated(FTimeout, Terminator);
end;

FUNCTION TTelnetSend.RecvString: string;
begin
  result := FSock.RecvTerminated(FTimeout, CRLF);
end;

FUNCTION TTelnetSend.WaitFor(CONST value: string): boolean;
begin
  result := FSock.RecvTerminated(FTimeout, value) <> '';
end;

PROCEDURE TTelnetSend.FilterHook(Sender: TObject; VAR value: ansistring);
begin
  value := Negotiate(value);
  FSessionLog := FSessionLog + value;
end;

FUNCTION TTelnetSend.Negotiate(CONST Buf: ansistring): ansistring;
VAR
  n: integer;
  c: Ansichar;
  Reply: ansistring;
  SubReply: ansistring;
begin
  result := '';
  for n := 1 to length(Buf) do
  begin
    c := Buf[n];
    Reply := '';
    case FState of
      tsData:
        if c = TLNT_IAC then
          FState := tsIAC
        else
          result := result + c;

      tsIAC:
        case c of
          TLNT_IAC:
            begin
              FState := tsData;
              result := result + TLNT_IAC;
            end;
          TLNT_WILL:
            FState := tsIAC_WILL;
          TLNT_WONT:
            FState := tsIAC_WONT;
          TLNT_DONT:
            FState := tsIAC_DONT;
          TLNT_DO:
            FState := tsIAC_DO;
          TLNT_EOR:
            FState := tsDATA;
          TLNT_SB:
            begin
              FState := tsIAC_SB;
              FSubType := #0;
              FSubNeg := '';
            end;
        else
          FState := tsData;
        end;

      tsIAC_WILL:
        begin
        case c of
          #3:  //suppress GA
            Reply := TLNT_DO;
        else
          Reply := TLNT_DONT;
        end;
          FState := tsData;
        end;

      tsIAC_WONT:
        begin
          Reply := TLNT_DONT;
          FState := tsData;
        end;

      tsIAC_DO:
      begin
        case c of
          #24:  //termtype
            Reply := TLNT_WILL;
        else
          Reply := TLNT_WONT;
        end;
        FState := tsData;
      end;

      tsIAC_DONT:
      begin
        Reply := TLNT_WONT;
        FState := tsData;
      end;

      tsIAC_SB:
        begin
          FSubType := c;
          FState := tsIAC_SBDATA;
        end;

      tsIAC_SBDATA:
        begin
          if c = TLNT_IAC then
            FState := tsSBDATA_IAC
          else
            FSubNeg := FSubNeg + c;
        end;

      tsSBDATA_IAC:
        case c of
          TLNT_IAC:
            begin
              FState := tsIAC_SBDATA;
              FSubNeg := FSubNeg + c;
            end;
          TLNT_SE:
            begin
              SubReply := '';
              case FSubType of
                #24:  //termtype
                  begin
                    if (FSubNeg <> '') and (FSubNeg[1] = #1) then
                      SubReply := #0 + FTermType;
                  end;
              end;
              Sock.SendString(TLNT_IAC + TLNT_SB + FSubType + SubReply + TLNT_IAC + TLNT_SE);
              FState := tsDATA;
            end;
         else
           FState := tsDATA;
         end;

      else
        FState := tsData;
    end;
    if Reply <> '' then
      Sock.SendString(TLNT_IAC + Reply + c);
  end;

end;

PROCEDURE TTelnetSend.Send(CONST value: string);
begin
  Sock.SendString(ReplaceString(value, TLNT_IAC, TLNT_IAC + TLNT_IAC));
end;

FUNCTION TTelnetSend.Login: boolean;
begin
  result := false;
  if not Connect then
    exit;
  result := true;
end;

FUNCTION TTelnetSend.SSHLogin: boolean;
begin
  result := false;
  if Connect then
  begin
    FSock.SSL.SSLType := LT_SSHv2;
    FSock.SSL.Username := FUsername;
    FSock.SSL.Password := FPassword;
    FSock.SSLDoConnect;
    result := FSock.LastError = 0;
  end;
end;

PROCEDURE TTelnetSend.Logout;
begin
  FSock.CloseSocket;
end;


end.
