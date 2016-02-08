UNIT EpikTimer;

// Name: EpikTimer
// Description: Precision timer/stopwatch component for Lazarus/FPC
// Author: Tom Lisjac <netdxr@gmail.com>
// Started on: June 24, 2003
// Features:
//   Dual selectable timebases: Default:System (uSec timeofday or "now" in Win32)
//                              Optional: Pentium Time Stamp Counter.
//   Default timebase should work on most Unix systems of any architecture.
//   Timebase correlation locks time stamp counter accuracy to system clock.
//   Timers can be started, stopped, paused and resumed.
//   Unlimited number of timers can be implemented with one component.
//   Low resources required: 25 bytes per timer; No CPU overhead.
//   Internal call overhead compensation.
//   System sleep function
//   Designed to support multiple operating systems and Architectures
//   Designed to support other hardware tick sources
//
// Credits: Thanks to Martin Waldenburg for a lot of great ideas for using
//          the Pentium's RDTSC instruction in wmFastTime and QwmFastTime.
//
//
// Copyright (C) 2003-2014 by Tom Lisjac <netdxr@gmail.com>,
//  Felipe Monteiro de Carvalho and Marcel Minderhoud
//
// This library is licensed on the same Modified LGPL as Free Pascal RTL and LCL are
//
// Please contact the author if you'd like to use this component but the Modified LGPL
// doesn't work with your project licensing.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.
//
// Contributor(s):
//
// * Felipe Monteiro de Carvalho (felipemonteiro.carvalho@gmail.com)
// * Marcel Minderhoud
// * Graeme Geldenhuys <graemeg@gmail.com>
//
//
//
//Known Issues
//
//  - If system doesn't have microsecond system clock resolution, the component
//    falls back to a single gated measurement of the hardware tick frequency via
//    nanosleep. This usually results in poor absolute accuracy due large amounts
//    of jitter in nanosleep... but for typical short term measurements, this
//    shouldn't be a problem.


{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFNDEF FPC}
  {$DEFINE Windows}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

INTERFACE

USES
{$IFDEF Windows}
  windows,
{$ELSE}
  unix, unixutil, baseunix,
{$ENDIF}
  Classes, sysutils, dateutils;

CONST
  DefaultSystemTicksPerSecond = 1000000; //Divisor for microsecond resolution
  // HW Tick frequency falls back to gated measurement if the initial system
  // clock measurement is outside this range plus or minus.
  SystemTicksNormalRangeLimit = 100000;

TYPE

  TickType = int64; // Global declaration for all tick processing routines

  FormatPrecision = 1..12; // Number of decimal places in elapsed text format

  // Component powers up in System mode to provide some cross-platform safety.
  TickSources = (SystemTimeBase, HardwareTimebase); // add others if desired

  (* * * * * * * * * * * TimeBase declarations  * * * * * * * * * * *)

  // There are two timebases currently implemented in this component but others
  // can be added by declaring them as "TickSources", adding a TimebaseData
  // variable to the Private area of TEpikTimer and providing a "Ticks" routine
  // that returns the current counter value.
  //
  // Timebases are "calibrated" during initialization by taking samples of the
  // execution times of the SystemSleep and Ticks functions measured with in the
  // tick period of the selected timebase. At runtime, these values are retrieved
  // and used to remove the call overhead to the best degree possible.
  //
  // System latency is always present and contributes "jitter" to the edges of
  // the sample measurements. This is especially true if a microsecond system
  // clock isn't detected on the host system and a fallback gated measurement
  // (based on nanosleep in Linux and sleep in Win32) is used to determine the
  // timebase frequency. This is sufficient for short term measurements where
  // high resolution comparisons are desired... but over a long measurement
  // period, the hardware and system wall clock will diverge significantly.
  //
  // If a microsecond system clock is found, timebase correlation is used to
  // synchronize the hardware counter and system clock. This is described below.

  TickCallFunc = FUNCTION: TickType; // Ticks interface function

  // Contains timebase overhead compensation factors in ticks for each timebase
  TimebaseCalibrationParameters = record
    FreqCalibrated: boolean; // Indicates that the tickfrequency has been calibrated
    OverheadCalibrated: boolean; // Indicates that all call overheads have been calibrated
    TicksIterations: integer; // number of iterations to use when measuring ticks overhead
    SleepIterations: integer; // number of iterations to use when measuring SystemSleep overhead
    FreqIterations: integer;  // number of iterations to use when measuring ticks frequency
    FrequencyGateTimeMS: integer;  // gate time to use when measuring ticks frequency
   end;

  // This record defines the Timebase context
  TimeBaseData = record
    CalibrationParms: TimebaseCalibrationParameters; // Calibration data for this timebase
    TicksFrequency: TickType; // Tick frequency of this timebase
    TicksOverhead: TickType;  // Ticks call overhead in TicksFrequency for this timebase
    SleepOverhead: TickType;   // SystemSleep all overhead in TicksFrequency for this timebase
    Ticks: TickCallFunc; // all methods get their ticks from this function when selected
  end;

  TimeBaseSelector = ^TimeBaseData;

  (*  * * * * * * * * * * TimeBase correlation  * * * * * * * * * * *)

  // The TimeBaseCorrelation record stores snapshot samples of both the system
  // ticks (the source of known accuracy) and the hardware tick source (the
  // source of high measurement resolution). An initial sample is taken at power
  // up. The CorrelationMode property sets where and when updates are acquired.
  //
  // When an update snapshot is acquired, the differences between it and the
  // startup value can be used to calculate the hardware clock frequency with
  // high precision from the accuracy of the accumulated system clocks. The
  // longer time that elapses between startup and a call to "CorrelateTimebases",
  // the better the accuracy will be. On a 1.6 Ghz P4, it only takes a few
  // seconds to achieve measurement certainty down to a few Hertz.
  //
  // Of course this system is only as good as your system clock accuracy, so
  // it's a good idea to periodically sync it with NTP or against another source
  // of known accuracy if you want to maximize the long term of the timers.

  TimeBaseCorrelationData = record
    SystemTicks: TickType;
    HWTicks: TickType;
  end;

  // If the Correlation property is set to automatic, an update sample is taken
  // anytime the user calls Start or Elapsed. If in manual, the correlation
  // update is only done when "CorrelateTimebases" is called. Doing updates
  // with every call adds a small amount of overhead... and after the first few
  // minutes of operation, there won't be very much correcting to do!

  CorrelationModes=(Manual, OnTimebaseSelect, OnGetElapsed);

  (* * * * * * * * * * * timer data record structure  * * * * * * * * * * *)

  // This is the timer data context. There is an internal declaration of this
  // record and overloaded methods if you only want to use the component for a
  // single timer... or you can declare multiple TimerData records in your
  // program and create as many instances as you want with only a single
  // component on the form. See the "Stopwatch" methods in the TEpikTimer class.

  // Each timers points to the timebase that started it... so you can mix system
  // and hardware timers in the same application.

  TimerData = record
    running:boolean; // Timer is currently running
    TimeBaseUsed:TimeBaseSelector; // keeps timer aligned with the source that started it.
    startTime:TickType; // Ticks sample when timer was started
    TotalTicks:TickType; // Total ticks... for snapshotting and pausing
  end;

  TEpikTimer= class(TComponent)
    private
      BuiltInTimer:TimerData; // Used to provide a single built-in timer;
      FHWTickSupportAvailable:boolean; // True if hardware tick support is available
      FHWCapabilityDataAvailable:boolean; // True if hardware tick support is available
      FHWTicks:TimeBaseData;     // The hardware timebase
      FSystemTicks:TimeBaseData; // The system timebase
      FSelectedTimebase:TimeBaseSelector; // Pointer to selected database

      FTimeBaseSource: TickSources; // use hardware or system timebase
      FWantDays: boolean; // true if days are to be displayed in string returns
      FWantMS: boolean; // True to display milliseconds in string formatted calls
      FSPrecision: FormatPrecision; // number of digits to display in string calls
      FMicrosecondSystemClockAvailable:boolean; // true if system has microsecond clock

      StartupCorrelationSample:TimeBaseCorrelationData; // Starting ticks correlation snapshot
      UpdatedCorrelationSample:TimeBaseCorrelationData; // Snapshot of last correlation sample
      FCorrelationMode: CorrelationModes; // mode to control when correlation updates are performed
    protected
      FUNCTION GetSelectedTimebase: TimeBaseData;
      PROCEDURE SetSelectedTimebase(CONST AValue: TimeBaseData);
      PROCEDURE SetTimebaseSource(CONST AValue: TickSources); //setter for TB
      PROCEDURE GetCorrelationSample(VAR CorrelationData:TimeBaseCorrelationData);
    public
      //                       Stopwatch emulation routines
      // These routines behave exactly like a conventional stopwatch with start,
      // stop, elapsed (lap) and clear methods. The timers can be started,
      // stopped and resumed. The Elapsed routines provide a "lap" time analog.
      //
      // The methods are overloaded to make it easy to simply use the component's
      // BuiltInTimer as a single timer... or to declare your own TimerData records
      // in order to implement unlimited numbers of timers using a single component
      // on the form. The timers are very resource efficient because they consume
      // no CPU overhead and only require about 25 bytes of memory.

      // Stops and resets the timer
      PROCEDURE clear; overload;// Call this routine to use the built-in timer record
      PROCEDURE clear(VAR T:TimerData); overload; // pass your TimerData record to this one

      //Start or resume a stopped timer
      PROCEDURE start; overload;
      PROCEDURE start(VAR T:TimerData); overload;

      //Stop or pause a timer
      PROCEDURE stop; overload;
      PROCEDURE stop(VAR T:TimerData); overload;

      //Return elapsed time in seconds as an extended type
      FUNCTION Elapsed:extended; overload;
      FUNCTION Elapsed(VAR T: TimerData):extended; overload;

      //Return a string in Day:Hour:Minute:Second format. Milliseconds can be
      //optionally appended via the WantMilliseconds property
      FUNCTION ElapsedDHMS:string; overload;
      FUNCTION ElapsedDHMS(VAR T: TimerData):string; overload;

      //Return a string in the format of seconds.milliseconds
      FUNCTION ElapsedStr:string; overload;
      FUNCTION ElapsedStr(VAR T:TimerData):string; overload;

      FUNCTION WallClockTime:string; // Return time of day string from system time

      //Overhead compensated system sleep to provide a best possible precision delay
      FUNCTION SystemSleep(Milliseconds: integer):integer; virtual;

      //Diagnostic taps for development and fine grained timebase adjustment
      PROPERTY HWTimebase: TimeBaseData read FHWTicks write FHWTicks; // The hardware timebase
      PROPERTY SysTimebase: TimeBaseData read FSystemTicks write FSystemTicks;
      FUNCTION GetHardwareTicks:TickType; // return raw tick value from hardware source
      FUNCTION GetSystemTicks:TickType;   // Return system tick value(in microseconds of Epoch time)
      FUNCTION GetTimebaseCorrelation:TickType;
      FUNCTION CalibrateCallOverheads(VAR TimeBase:TimeBaseData) : integer; virtual;
      FUNCTION CalibrateTickFrequency(VAR TimeBase:TimeBaseData): integer; virtual;

      PROPERTY MicrosecondSystemClockAvailable:boolean read FMicrosecondSystemClockAvailable;
      PROPERTY SelectedTimebase:TimeBaseSelector read FSelectedTimebase write FSelectedTimebase;
      PROPERTY HWTickSupportAvailable:boolean read FHWTickSupportAvailable;
      PROPERTY HWCapabilityDataAvailable:boolean read FHWCapabilityDataAvailable;
      PROCEDURE CorrelateTimebases; // Manually call to do timebase correlation snapshot and update

      CONSTRUCTOR create(AOwner:TComponent); override;
      DESTRUCTOR destroy; override;
    Published
      PROPERTY StringPrecision: FormatPrecision read FSPrecision write FSPrecision;
      PROPERTY WantMilliseconds: boolean read FWantMS write FWantMS;
      PROPERTY WantDays: boolean read FWantDays write FWantDays;
      PROPERTY TimebaseSource: TickSources read FTimeBaseSource write SetTimebaseSource;
      PROPERTY CorrelationMode:CorrelationModes read FCorrelationMode write FCorrelationMode;
  end;


IMPLEMENTATION

(* * * * * * * * * * * * * * TimeBase section  * * * * * * * * * * * * *)
//
// There are two tick sources defined in this section. The first uses a hardware
// source which, in this case, is the Pentium's internal 64 Time Stamp Counter.
// The second source (the default) uses the given environment's most precision
// "timeofday" system call so it can work across OS platforms and architectures.
//
// The hardware timer's accuracy depends on the frequency of the timebase tick
// source that drives it... in other words, how many of the timebase's ticks
// there are in a second. This frequency is measured by capturing a sample of the
// timebase ticks for a known period against a source of known accuracy. There
// are two ways to do this.
//
// The first is to capture a large sample of ticks from both the unknown and
// known timing sources. Then the frequency of the unknown tick stream can be
// calculated by: UnknownSampleTicks / (KnownSampleTicks / KnownTickFrequency).
// Over a short period of time, this can provide a precise synchronization
// mechanism that effectively locks the measurements taken with the high
// resolution source to the known accuracy of the system clock.
//
// The first method depends on the existance of an accurate system time source of
// microsecond resolution. If the host system doesn't provide this, the second
// fallback method is to gate the unknown tick stream by a known time. This isn't
// as good because it usually involves calling a system "delay" routine that
// usually has a lot of overhead "jitter" and non-deterministic behavior. This
// approach is usable, however, for short term, high resolution comparisons where
// absolute accuracy isn't important.
//

CONST
  MilliPerSec = 1000;


(* * * * * * * * start of i386 Hardware specific code  * * * * * * *)

{$IFDEF CPUI386}
// Some references for this section can be found at:
//     http://www.sandpile.org/ia32/cpuid.htm
//     http://www.sandpile.org/ia32/opc_2.htm
//     http://www.sandpile.org/ia32/msr.htm

// Pentium specific... push and pop the flags and check for CPUID availability
FUNCTION HasHardwareCapabilityData: boolean;
begin
  asm
   PUSHFD
   pop    EAX
   MOV    EDX,EAX
   xor    EAX,$200000
   push   EAX
   POPFD
   PUSHFD
   pop    EAX
   xor    EAX,EDX
   JZ     @exit
   MOV    AL,true
   @exit:
  end;
end;

FUNCTION HasHardwareTickCounter: boolean;
  VAR FeatureFlags: Longword;
  begin
    FeatureFlags:=0;
    asm
      push   EBX
      xor    EAX,EAX
      DW     $A20F
      pop    EBX
      CMP    EAX,1
      JL     @exit
      xor    EAX,EAX
      MOV    EAX,1
      push   EBX
      DW     $A20F
      MOV    FeatureFlags,EDX
      pop    EBX
      @exit:
    end;
    result := (FeatureFlags and $10) <> 0;
  end;

// Execute the Pentium's RDTSC instruction to access the counter value.
FUNCTION HardwareTicks: TickType; assembler; asm DW 0310FH end;

(* * * * * * * * end of i386 Hardware specific code  * * * * * * *)


// These are here for architectures that don't have a precision hardware
// timing source. They'll return zeros for overhead values. The timers
// will work but there won't be any error compensation for long
// term accuracy.
{$ELSE} // add other architectures and hardware specific tick sources here
FUNCTION HasHardwareCapabilityData: boolean; begin result:=false end;
FUNCTION HasHardwareTickCounter: boolean; begin result:=false end;
FUNCTION HardwareTicks:TickType; begin result:=0 end;
{$ENDIF}

FUNCTION NullHardwareTicks:TickType; begin result:=0 end;

// Return microsecond normalized time source for a given platform.
// This should be sync'able to an external time standard (via NTP, for example).
FUNCTION SystemTicks: TickType;
{$IFDEF WINDOWS}
begin
  result:=0;
  QueryPerformanceCounter(result);
{$ELSE}
  {$IFDEF LINUX}
  CONST
    CLOCK_MONOTONIC = 1;

          { Experimental, no idea if this works or is implemented correctly }
          FUNCTION newGetTickCount: Cardinal;
          VAR
            ts: TTimeSpec;
            i: TickType;
            t: timeval;
          begin
            // use the Posix clock_gettime() call
            if clock_gettime(CLOCK_MONOTONIC, @ts)=0 then
            begin
              // Use the FPC fallback
              fpgettimeofday(@t,nil);
              // Build a 64 bit microsecond tick from the seconds and microsecond longints
              result := (TickType(t.tv_sec) * NanoPerMilli) + t.tv_usec;
              exit;
            end;
            i := ts.tv_sec;
            i := (i*MilliPerSec) + ts.tv_nsec div NanoPerMilli;
            result := i;
          end;
  begin
    result := newGetTickCount;
  {$ELSE}
  VAR
    t: timeval;
  begin
    // Use the FPC fallback
    fpgettimeofday(@t,nil);
    // Build a 64 bit microsecond tick from the seconds and microsecond longints
    result := (TickType(t.tv_sec) * NanoPerMilli) + t.tv_usec;
  {$ENDIF LINUX}
{$ENDIF WINDOWS}
end;

FUNCTION TEpikTimer.SystemSleep(Milliseconds: integer): integer;
begin
  sleep(Milliseconds);
  result := 0;
end;

FUNCTION TEpikTimer.GetHardwareTicks: TickType;
begin
  result:=FHWTicks.Ticks();
end;

FUNCTION TEpikTimer.GetSystemTicks: TickType;
begin
  result:=FSystemTicks.Ticks();
end;

PROCEDURE TEpikTimer.SetTimebaseSource(CONST AValue: TickSources);

  PROCEDURE UseSystemTimer;
  begin
    FTimeBaseSource := SystemTimeBase;
    SelectedTimebase := @FSystemTicks;
  end;

begin
  case AValue of
    HardwareTimebase:
      try
        if HWTickSupportAvailable then
          begin
            SelectedTimebase:=@FHWTicks;
            FTimeBaseSource:=HardwareTimebase;
            if CorrelationMode<>Manual then CorrelateTimebases
          end
      except // If HW init fails, fall back to system tick source
        UseSystemTimer
      end;
    SystemTimeBase: UseSystemTimer
  end
end;

FUNCTION TEpikTimer.GetSelectedTimebase: TimeBaseData;
begin
  result := FSelectedTimebase^;
end;

PROCEDURE TEpikTimer.SetSelectedTimebase(CONST AValue: TimeBaseData);
begin
  FSelectedTimebase^ := AValue;
end;

(* * * * * * * * * * time measurement core routines * * * * * * * * * *)

PROCEDURE TEpikTimer.clear(VAR T: TimerData);
begin
  with T do
    begin
      running:=false; startTime:=0; TotalTicks:=0; TimeBaseUsed:=FSelectedTimebase
    end;
end;

PROCEDURE TEpikTimer.start(VAR T: TimerData);
begin
  if not T.running then
    with FSelectedTimebase^ do
    begin
      T.startTime:=Ticks()-TicksOverhead;
      T.TimeBaseUsed:=FSelectedTimebase;
      T.running:=true
    end
end;

PROCEDURE TEpikTimer.stop(VAR T: TimerData);
  VAR CurTicks:TickType;
begin
  if T.running then
    with T.TimeBaseUsed^ do
    begin
      CurTicks:=Ticks()-TicksOverhead; // Back out the call overhead
      T.TotalTicks:=(CurTicks - T.startTime)+T.TotalTicks; T.running:=false
    end
end;

FUNCTION TEpikTimer.Elapsed(VAR T: TimerData): extended;
VAR
  CurTicks: TickType;
begin
  with T.TimeBaseUsed^ do
    if T.running then
      begin

        CurTicks:=Ticks()-TicksOverhead; // Back out the call overhead
        if CorrelationMode>OnTimebaseSelect then CorrelateTimebases;

        result := ((CurTicks - T.startTime)+T.TotalTicks) / TicksFrequency
      end
    else result := T.TotalTicks / TicksFrequency;
end;

(* * * * * * * * * * output formatting routines  * * * * * * * * * *)

FUNCTION TEpikTimer.ElapsedDHMS(VAR T: TimerData): string;
VAR
  tmp, ms: extended;
  D, H, M, S: integer;
  P, SM: string;
begin
  tmp := Elapsed(T);
  P := intToStr(FSPrecision);
  ms := frac(tmp); SM:=format('%0.'+P+'f',[ms]); Delete(SM,1,1);
  D := trunc(tmp / 86400); tmp:=trunc(tmp) mod 86400;
  H := trunc(tmp / 3600); tmp:=trunc(tmp) mod 3600;
  M := trunc(tmp / 60); S:=(trunc(tmp) mod 60);
  if FWantDays then
    result := format('%2.3d:%2.2d:%2.2d:%2.2d',[D,H,M,S])
  else
    result := format('%2.2d:%2.2d:%2.2d',[H,M,S]);
  if FWantMS then result:=result+SM;
end;

FUNCTION TEpikTimer.ElapsedStr(VAR T: TimerData): string;
begin
  result := format('%.'+intToStr(FSPrecision)+'f',[Elapsed(T)]);
end;

FUNCTION TEpikTimer.WallClockTime: string;
VAR
  Y, D, M, hour, min, sec, ms, us: word;
{$IFNDEF Windows}
  t: timeval;
{$ENDIF}
begin
{$IFDEF Windows}
  DecodeDatetime(now, Y, D, M, hour, min, sec, ms);
  us:=0;
{$ELSE}
  // "Now" doesn't report milliseconds on Linux... appears to be broken.
  // I opted for this approach which also provides microsecond precision.
  fpgettimeofday(@t,nil);
  EpochToLocal(t.tv_sec, Y, M, D, hour, min, sec);
  ms:=t.tv_usec div MilliPerSec;
  us:=t.tv_usec mod MilliPerSec;
{$ENDIF}
  result:='';
  if FWantDays then
    result := format('%4.4d/%2.2d/%2.2d-',[Y,M,D]);
  result := result + format('%2.2d:%2.2d:%2.2d',[hour,min,sec]);
  if FWantMS then
    result := result + format('.%3.3d%3.3d',[ms,us])
end;

(* * * Overloaded methods to use the component's internal timer data * * *)

PROCEDURE TEpikTimer.clear; begin clear(BuiltInTimer) end;
PROCEDURE TEpikTimer.start; begin start(BuiltInTimer) end;
PROCEDURE TEpikTimer.stop;  begin stop(BuiltInTimer) end;
FUNCTION  TEpikTimer.Elapsed: extended; begin result:=Elapsed(BuiltInTimer) end;
FUNCTION  TEpikTimer.ElapsedStr: string; begin result:=ElapsedStr(BuiltInTimer) end;
FUNCTION  TEpikTimer.ElapsedDHMS: string; begin result:=ElapsedDHMS(BuiltInTimer) end;

(* * * * * * * * * * TimeBase calibration section  * * * * * * * * * *)

// Set up compensation for call overhead to the Ticks and SystemSleep functions.
// The Timebase record contains Calibration parameters to be used for each
// timebase source. These have to be unique as the output of this measurement
// is measured in "ticks"... which are different periods for each timebase.

FUNCTION TEpikTimer.CalibrateCallOverheads(VAR TimeBase: TimeBaseData): integer;
VAR i:integer; St,Fin,total:TickType;
begin
  with TimeBase, TimeBase.CalibrationParms do
  begin
    total:=0; result:=1;
    for I:=1 to TicksIterations do // First get the base tick getting overhead
      begin
        St:=Ticks(); Fin:=Ticks();
        total:=total+(Fin-St); // dump the first sample
      end;
    TicksOverhead:=total div TicksIterations;
    total:=0;
    for I:=1 to SleepIterations do
    begin
      St:=Ticks();
      if SystemSleep(0)<>0 then exit;
      Fin:=Ticks();
      total:=total+((Fin-St)-TicksOverhead);
    end;
    SleepOverhead:=total div SleepIterations;
    OverheadCalibrated:=true; result:=0
  end
end;

// CalibrateTickFrequency is a fallback in case a microsecond resolution system
// clock isn't found. It's still important because the long term accuracy of the
// timers will depend on the determination of the tick frequency... in other words,
// the number of ticks it takes to make a second. If this measurement isn't
// accurate, the counters will proportionately drift over time.
//
// The technique used here is to gate a sample of the tick stream with a known
// time reference which, in this case, is nanosleep. There is a *lot* of jitter
// in a nanosleep call so an attempt is made to compensate for some of it here.

FUNCTION TEpikTimer.CalibrateTickFrequency(VAR TimeBase: TimeBaseData): integer;
VAR
  i: integer;
  total, SS, SE: TickType;
  ElapsedTicks, SampleTime: extended;
begin
  with TimeBase, TimeBase.CalibrationParms do
  begin
    result:=1; //maintain unitialized default in case something goes wrong.
    total:=0;
    for i:=1 to FreqIterations do
      begin
        SS:=Ticks();
        SystemSleep(FrequencyGateTimeMS);
        SE:=Ticks();
        total:=total+((SE-SS)-(SleepOverhead+TicksOverhead))
      end;
    //doing the floating point conversion allows SampleTime parms of < 1 second
    ElapsedTicks:=total div FreqIterations;
    SampleTime:=FrequencyGateTimeMS;

    TicksFrequency:=trunc( ElapsedTicks / (SampleTime / MilliPerSec));

    FreqCalibrated:=true;
  end;
end;

// Grab a snapshot of the system and hardware tick sources... as quickly as
// possible and with overhead compensation. These samples will be used to
// correct the accuracy of the hardware tick frequency source when precision
// long term measurements are desired.
PROCEDURE TEpikTimer.GetCorrelationSample(VAR CorrelationData: TimeBaseCorrelationData);
VAR
  TicksHW, TicksSys: TickType;
  THW, TSYS: TickCallFunc;
begin
  THW:=FHWTicks.Ticks; TSYS:=FSystemTicks.Ticks;
  TicksHW:=THW(); TicksSys:=TSYS();
  with CorrelationData do
    begin
      SystemTicks:= TicksSys-FSystemTicks.TicksOverhead;
      HWTicks:=TicksHW-FHWTicks.TicksOverhead;
    end
end;

(* * * * * * * * * * TimeBase correlation section  * * * * * * * * * *)

// Get another snapshot of the system and hardware tick sources and compute a
// corrected value for the hardware frequency. In a short amount of time, the
// microsecond system clock accumulates enough ticks to perform a *very*
// accurate frequency measurement of the typically picosecond time stamp counter.

FUNCTION TEpikTimer.GetTimebaseCorrelation: TickType;
VAR
  HWDiff, SysDiff, Corrected: extended;
begin
  if HWTickSupportAvailable then
    begin
      GetCorrelationSample(UpdatedCorrelationSample);
      HWDiff:=UpdatedCorrelationSample.HWTicks-StartupCorrelationSample.HWTicks;
      SysDiff:=UpdatedCorrelationSample.SystemTicks-StartupCorrelationSample.SystemTicks;
      Corrected:=HWDiff / (SysDiff / DefaultSystemTicksPerSecond);
      result:=trunc(Corrected)
    end
  else result:=0
end;

// If an accurate reference is available, update the TicksFrequency of the
// hardware timebase.
PROCEDURE TEpikTimer.CorrelateTimebases;
begin
  if MicrosecondSystemClockAvailable and HWTickSupportAvailable then
    FHWTicks.TicksFrequency:=GetTimebaseCorrelation
end;

(* * * * * * * * INITIALIZATION: CONSTRUCTOR and DESTRUCTOR  * * * * * * *)

CONSTRUCTOR TEpikTimer.create(AOwner: TComponent);

  PROCEDURE InitTimebases;
  begin

    // Tick frequency rates are different for the system and HW timebases so we
    // need to store calibration data in the period format of each one.
    FSystemTicks.Ticks:=@SystemTicks; // Point to Ticks routine
    with FSystemTicks.CalibrationParms do
      begin
        FreqCalibrated:=false;
        OverheadCalibrated:=false;
        TicksIterations:=5;
        SleepIterations:=10;
        FrequencyGateTimeMS:=100;
        FreqIterations:=1;
      end;

    // Initialize the HW tick source data
    FHWCapabilityDataAvailable:=false;
    FHWTickSupportAvailable:=false;
    FHWTicks.Ticks:=@NullHardwareTicks; // returns a zero if no HW support
    FHWTicks.TicksFrequency:=1;
    with FHWTicks.CalibrationParms do
      begin
        FreqCalibrated:=false;
        OverheadCalibrated:=false;
        TicksIterations:=10;
        SleepIterations:=20;
        FrequencyGateTimeMS:=150;
        FreqIterations:=1;
      end;

    if HasHardwareCapabilityData then
      begin
        FHWCapabilityDataAvailable:=true;
        if HasHardwareTickCounter then
          begin
            FHWTicks.Ticks:=@HardwareTicks;
            FHWTickSupportAvailable:=CalibrateCallOverheads(FHWTicks)=0
          end
      end;

    CalibrateCallOverheads(FSystemTicks);
    CalibrateTickFrequency(FSystemTicks);

    // Overheads are set... get starting timestamps for long term calibration runs
    GetCorrelationSample(StartupCorrelationSample);
    with FSystemTicks do
      if (TicksFrequency>(DefaultSystemTicksPerSecond-SystemTicksNormalRangeLimit)) and
        (TicksFrequency<(DefaultSystemTicksPerSecond+SystemTicksNormalRangeLimit)) then
        begin // We've got a good microsecond system clock
          FSystemTicks.TicksFrequency:=DefaultSystemTicksPerSecond; // assume it's pure
          FMicrosecondSystemClockAvailable:=true;
          if FHWTickSupportAvailable then
            begin
              SystemSleep(FHWTicks.CalibrationParms.FrequencyGateTimeMS); // rough gate
              CorrelateTimebases
            end
        end
      else
        begin
          FMicrosecondSystemClockAvailable:=false;
          if FHWTickSupportAvailable then
            CalibrateTickFrequency(FHWTicks) // sloppy but usable fallback calibration
        end;
 end;

begin
  inherited create(AOwner);
  StringPrecision := 6;
  FWantMS         := true;
  FWantDays       := true;
  InitTimebases;
  CorrelationMode := OnTimebaseSelect;
  // Default is the safe, cross-platform but less precise system timebase
  TimebaseSource  := SystemTimeBase;
  clear(BuiltInTimer)
end;

DESTRUCTOR TEpikTimer.destroy;
begin
  inherited destroy;
  // here in case we need to clean something up in a later version
end;

end.

