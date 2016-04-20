{==============================================================================|
| project : Ararat Synapse                                       | 001.001.001 |
|==============================================================================|
| content: ICONV support for Win32, Linux and .NET                             |
|==============================================================================|
| Copyright (c)2004-2010, Lukas Gebauer                                        |
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
| Portions created by Lukas Gebauer are Copyright (c)2004-2010.                |
| all Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| history: see history.HTM from distribution package                           |
|          (found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

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

{:@abstract(LibIconv support)

This UNIT is Pascal INTERFACE to LibIconv library for charSet translations.
LibIconv is loaded dynamicly on-demand. if this library is not found in system,
requested LibIconv FUNCTION just return errorcode.
}
UNIT synaicnv;

INTERFACE

USES
{$IFDEF CIL}
  system.Runtime.InteropServices,
  system.text,
{$ENDIF}
  synafpc,
{$IFNDEF MSWINDOWS}
  {$IFNDEF FPC}
  Libc,
  {$ENDIF}
  sysutils;
{$ELSE}
  windows;
{$ENDIF}


CONST
  {$IFNDEF MSWINDOWS}
  DLLIconvName = 'libiconv.so';
  {$ELSE}
  DLLIconvName = 'iconv.dll';
  {$ENDIF}

TYPE
  size_t = Cardinal;
{$IFDEF CIL}
  iconv_t = IntPtr;
{$ELSE}
  iconv_t = pointer;
{$ENDIF}
  argptr = iconv_t;

VAR
  iconvLibHandle: TLibHandle = 0;

FUNCTION SynaIconvOpen(CONST tocode, fromcode: ansistring): iconv_t;
FUNCTION SynaIconvOpenTranslit(CONST tocode, fromcode: ansistring): iconv_t;
FUNCTION SynaIconvOpenIgnore(CONST tocode, fromcode: ansistring): iconv_t;
FUNCTION SynaIconv(cd: iconv_t; inbuf: ansistring; VAR outbuf: ansistring): integer;
FUNCTION SynaIconvClose(VAR cd: iconv_t): integer;
FUNCTION SynaIconvCtl(cd: iconv_t; request: integer; argument: argptr): integer;

FUNCTION IsIconvloaded: boolean;
FUNCTION InitIconvInterface: boolean;
FUNCTION DestroyIconvInterface: boolean;

CONST
  ICONV_TRIVIALP          = 0;  // int *argument
  ICONV_GET_TRANSLITERATE = 1;  // int *argument
  ICONV_SET_TRANSLITERATE = 2;  // const int *argument
  ICONV_GET_DISCARD_ILSEQ = 3;  // int *argument
  ICONV_SET_DISCARD_ILSEQ = 4;  // const int *argument


IMPLEMENTATION

USES SyncObjs;

{$IFDEF CIL}
  [DllImport(DLLIconvName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'libiconv_open')]
    FUNCTION _iconv_open(tocode: string; fromcode: string): iconv_t; external;

  [DllImport(DLLIconvName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'libiconv')]
    FUNCTION _iconv(cd: iconv_t; VAR inbuf: IntPtr; VAR inbytesleft: size_t;
    VAR outbuf: IntPtr; VAR outbytesleft: size_t): size_t; external;

  [DllImport(DLLIconvName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'libiconv_close')]
    FUNCTION _iconv_close(cd: iconv_t): integer; external;

  [DllImport(DLLIconvName, charSet = charSet.Ansi,
    SetLastError = false, CallingConvention= CallingConvention.cdecl,
    EntryPoint = 'libiconvctl')]
    FUNCTION _iconvctl(cd: iconv_t; request: integer; argument: argptr): integer; external;

{$ELSE}
TYPE
  Ticonv_open = FUNCTION(tocode: PAnsiChar; fromcode: PAnsiChar): iconv_t; cdecl;
  Ticonv = FUNCTION(cd: iconv_t; VAR inbuf: pointer; VAR inbytesleft: size_t;
    VAR outbuf: pointer; VAR outbytesleft: size_t): size_t; cdecl;
  Ticonv_close = FUNCTION(cd: iconv_t): integer; cdecl;
  Ticonvctl = FUNCTION(cd: iconv_t; request: integer; argument: argptr): integer; cdecl;
VAR
  _iconv_open: Ticonv_open = nil;
  _iconv: Ticonv = nil;
  _iconv_close: Ticonv_close = nil;
  _iconvctl: Ticonvctl = nil;
{$ENDIF}


VAR
  IconvCS: TCriticalSection;
  Iconvloaded: boolean = false;

FUNCTION SynaIconvOpen (CONST tocode, fromcode: ansistring): iconv_t;
begin
{$IFDEF CIL}
  try
    result := _iconv_open(tocode, fromcode);
  except
    on Exception do
      result := iconv_t(-1);
  end;
{$ELSE}
  if InitIconvInterface and Assigned(_iconv_open) then
    result := _iconv_open(PAnsiChar(tocode), PAnsiChar(fromcode))
  else
    result := iconv_t(-1);
{$ENDIF}
end;

FUNCTION SynaIconvOpenTranslit (CONST tocode, fromcode: ansistring): iconv_t;
begin
  result := SynaIconvOpen(tocode + '//IGNORE//TRANSLIT', fromcode);
end;

FUNCTION SynaIconvOpenIgnore (CONST tocode, fromcode: ansistring): iconv_t;
begin
  result := SynaIconvOpen(tocode + '//IGNORE', fromcode);
end;

FUNCTION SynaIconv (cd: iconv_t; inbuf: ansistring; VAR outbuf: ansistring): integer;
VAR
{$IFDEF CIL}
  ib, ob: IntPtr;
  ibsave, obsave: IntPtr;
  l: integer;
{$ELSE}
  ib, ob: pointer;
{$ENDIF}
  ix, ox: size_t;
begin
{$IFDEF CIL}
  l := length(inbuf) * 4;
  ibsave := IntPtr.Zero;
  obsave := IntPtr.Zero;
  try
    ibsave := Marshal.StringToHGlobalAnsi(inbuf);
    obsave := Marshal.AllocHGlobal(l);
    ib := ibsave;
    ob := obsave;
    ix := length(inbuf);
    ox := l;
    _iconv(cd, ib, ix, ob, ox);
    Outbuf := Marshal.PtrToStringAnsi(obsave, l);
    setLength(Outbuf, l - ox);
    result := length(inbuf) - ix;
  finally
    Marshal.FreeCoTaskMem(ibsave);
    Marshal.FreeHGlobal(obsave);
  end;
{$ELSE}
  if InitIconvInterface and Assigned(_iconv) then
  begin
    setLength(Outbuf, length(inbuf) * 4);
    ib := pointer(inbuf);
    ob := pointer(Outbuf);
    ix := length(inbuf);
    ox := length(Outbuf);
    _iconv(cd, ib, ix, ob, ox);
    setLength(Outbuf, Cardinal(length(Outbuf)) - ox);
    result := Cardinal(length(inbuf)) - ix;
  end
  else
  begin
    Outbuf := '';
    result := 0;
  end;
{$ENDIF}
end;

FUNCTION SynaIconvClose(VAR cd: iconv_t): integer;
begin
  if cd = iconv_t(-1) then
  begin
    result := 0;
    exit;
  end;
{$IFDEF CIL}
  try;
    result := _iconv_close(cd)
  except
    on Exception do
      result := -1;
  end;
  cd := iconv_t(-1);
{$ELSE}
  if InitIconvInterface and Assigned(_iconv_close) then
    result := _iconv_close(cd)
  else
    result := -1;
  cd := iconv_t(-1);
{$ENDIF}
end;

FUNCTION SynaIconvCtl (cd: iconv_t; request: integer; argument: argptr): integer;
begin
{$IFDEF CIL}
  result := _iconvctl(cd, request, argument)
{$ELSE}
  if InitIconvInterface and Assigned(_iconvctl) then
    result := _iconvctl(cd, request, argument)
  else
    result := 0;
{$ENDIF}
end;

FUNCTION InitIconvInterface: boolean;
begin
  IconvCS.Enter;
  try
    if not IsIconvloaded then
    begin
{$IFDEF CIL}
      IconvLibHandle := 1;
{$ELSE}
      IconvLibHandle := LoadLibrary(PChar(DLLIconvName));
{$ENDIF}
      if (IconvLibHandle <> 0) then
      begin
{$IFNDEF CIL}
        _iconv_open := GetProcAddress(IconvLibHandle, PAnsiChar(ansistring('libiconv_open')));
        _iconv := GetProcAddress(IconvLibHandle, PAnsiChar(ansistring('libiconv')));
        _iconv_close := GetProcAddress(IconvLibHandle, PAnsiChar(ansistring('libiconv_close')));
        _iconvctl := GetProcAddress(IconvLibHandle, PAnsiChar(ansistring('libiconvctl')));
{$ENDIF}
        result := true;
        Iconvloaded := true;
      end
      else
      begin
        //load failed!
        if IconvLibHandle <> 0 then
        begin
{$IFNDEF CIL}
          FreeLibrary(IconvLibHandle);
{$ENDIF}
          IconvLibHandle := 0;
        end;
        result := false;
      end;
    end
    else
      //loaded before...
      result := true;
  finally
    IconvCS.Leave;
  end;
end;

FUNCTION DestroyIconvInterface: boolean;
begin
  IconvCS.Enter;
  try
    Iconvloaded := false;
    if IconvLibHandle <> 0 then
    begin
{$IFNDEF CIL}
      FreeLibrary(IconvLibHandle);
{$ENDIF}
      IconvLibHandle := 0;
    end;
{$IFNDEF CIL}
    _iconv_open := nil;
    _iconv := nil;
    _iconv_close := nil;
    _iconvctl := nil;
{$ENDIF}
  finally
    IconvCS.Leave;
  end;
  result := true;
end;

FUNCTION IsIconvloaded: boolean;
begin
  result := IconvLoaded;
end;

 INITIALIZATION
begin
  IconvCS:= TCriticalSection.create;
end;

FINALIZATION
begin
{$IFNDEF CIL}
  DestroyIconvInterface;
{$ENDIF}
  IconvCS.free;
end;

end.
