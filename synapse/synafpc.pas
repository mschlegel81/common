{==============================================================================|
| project : Ararat Synapse                                       | 001.002.000 |
|==============================================================================|
| content: Utils for FreePascal compatibility                                  |
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
| Portions created by Lukas Gebauer are Copyright (c)2003-2011.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

{:@exclude}

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}
//old Delphi does not have MSWINDOWS define.
{$IFDEF WIN32}
  {$IFNDEF MSWINDOWS}
    {$DEFINE MSWINDOWS}
  {$ENDIF}
{$ENDIF}

UNIT synafpc;

INTERFACE

USES
{$IFDEF FPC}
  dynlibs, sysutils;
{$ELSE}
  {$IFDEF MSWINDOWS}
  windows;
  {$ELSE}
  sysutils;
  {$ENDIF}
{$ENDIF}

{$IFDEF FPC}
TYPE
  TLibHandle = dynlibs.TLibHandle;

FUNCTION LoadLibrary(ModuleName: PChar): TLibHandle;
FUNCTION FreeLibrary(Module: TLibHandle): LongBool;
FUNCTION GetProcAddress(Module: TLibHandle; proc: PChar): pointer;
FUNCTION GetModuleFileName(Module: TLibHandle; buffer: PChar; BufLen: integer): integer;
{$ELSE}
TYPE
  {$IFDEF CIL}
  TLibHandle = integer;
  ptrint = integer;
  {$ELSE}
  TLibHandle = HModule;
    {$IFNDEF WIN64}
  ptrint = integer;
    {$ENDIF}
  {$ENDIF}
  {$IFDEF VER100}
  Longword = dword;
  {$ENDIF}
{$ENDIF}

PROCEDURE sleep(Milliseconds: Cardinal);


IMPLEMENTATION

{==============================================================================}
{$IFDEF FPC}
FUNCTION LoadLibrary(ModuleName: PChar): TLibHandle;
begin
  result := dynlibs.LoadLibrary(Modulename);
end;

FUNCTION FreeLibrary(Module: TLibHandle): LongBool;
begin
  result := dynlibs.UnloadLibrary(Module);
end;

FUNCTION GetProcAddress(Module: TLibHandle; proc: PChar): pointer;
begin
  result := dynlibs.GetProcedureAddress(Module, proc);
end;

FUNCTION GetModuleFileName(Module: TLibHandle; buffer: PChar; BufLen: integer): integer;
begin
  result := 0;
end;

{$ELSE}
{$ENDIF}

PROCEDURE sleep(Milliseconds: Cardinal);
begin
{$IFDEF MSWINDOWS}
  {$IFDEF FPC}
  sysutils.sleep(Milliseconds);
  {$ELSE}
  windows.sleep(Milliseconds);
  {$ENDIF}
{$ELSE}
  sysutils.sleep(Milliseconds);
{$ENDIF}

end;

end.
