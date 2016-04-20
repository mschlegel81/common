{==============================================================================|
| project : Ararat Synapse                                       | 001.001.002 |
|==============================================================================|
| content: Socket debug tools                                                  |
|==============================================================================|
| Copyright (c)2008-2011, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2008-2011.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@abstract(Socket debug tools)

routines for help with debugging of events on the Sockets.
}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

UNIT synadbg;

INTERFACE

USES
  blcksock, synsock, synautil, Classes, sysutils, synafpc;

TYPE
  TSynaDebug = class(TObject)
    class PROCEDURE HookStatus(Sender: TObject; Reason: THookSocketReason; CONST value: string);
    class PROCEDURE HookMonitor(Sender: TObject; Writing: boolean; CONST buffer: TMemory; len: integer);
  end;

PROCEDURE AppendToLog(CONST value: ansistring);

VAR
  LogFile: string;

IMPLEMENTATION

PROCEDURE AppendToLog(CONST value: ansistring);
VAR
  st: TFileStream;
  s: string;
  h, m, SS, ms: word;
  dt: TDateTime;
begin
  if fileExists(LogFile) then
    st := TFileStream.create(LogFile, fmOpenReadWrite or fmShareDenyWrite)
  else
    st := TFileStream.create(LogFile, fmCreate or fmShareDenyWrite);
  try
    st.position := st.size;
    dt := now;
    decodetime(dt, h, m, SS, ms);
    s := FormatDateTime('yyyymmdd-hhnnss', dt) + format('.%.3d', [ms]) + ' ' + value;
    WriteStrToStream(st, s);
  finally
    st.free;
  end;
end;

class PROCEDURE TSynaDebug.HookStatus(Sender: TObject; Reason: THookSocketReason; CONST value: string);
VAR
  s: string;
begin
  case Reason of
    HR_ResolvingBegin:
      s := 'HR_ResolvingBegin';
    HR_ResolvingEnd:
      s := 'HR_ResolvingEnd';
    HR_SocketCreate:
      s := 'HR_SocketCreate';
    HR_SocketClose:
      s := 'HR_SocketClose';
    HR_Bind:
      s := 'HR_Bind';
    HR_Connect:
      s := 'HR_Connect';
    HR_CanRead:
      s := 'HR_CanRead';
    HR_CanWrite:
      s := 'HR_CanWrite';
    HR_Listen:
      s := 'HR_Listen';
    HR_Accept:
      s := 'HR_Accept';
    HR_ReadCount:
      s := 'HR_ReadCount';
    HR_WriteCount:
      s := 'HR_WriteCount';
    HR_Wait:
      s := 'HR_Wait';
    HR_Error:
      s := 'HR_Error';
  else
    s := '-unknown-';
  end;
  s := inttohex(ptrint(Sender), 8) + s + ': ' + value + CRLF;
  AppendToLog(s);
end;

class PROCEDURE TSynaDebug.HookMonitor(Sender: TObject; Writing: boolean; CONST buffer: TMemory; len: integer);
VAR
  s, d: ansistring;
begin
  setLength(s, len);
  move(buffer^, pointer(s)^, len);
  if writing then
    d := '-> '
  else
    d := '<- ';
  s :=inttohex(ptrint(Sender), 8) + d + s + CRLF;
  AppendToLog(s);
end;

INITIALIZATION
begin
  Logfile := ChangeFileExt(paramStr(0), '.slog');
end;

end.
