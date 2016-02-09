UNIT myTools;
INTERFACE
USES sysutils,myStringUtil;
TYPE
  P_progressEstimator=^T_progressEstimator;
  T_progressEstimator=object
    private
      cs:TRTLCriticalSection;
      progress:array of record
        time,fractionDone:double;
        message:ansistring;
      end;
      cancelled:boolean;
      calculationRunning:boolean;
      messages:boolean;
    public
      CONSTRUCTOR createWithMessages;
      CONSTRUCTOR createSimple;
      DESTRUCTOR destroy;
      PROCEDURE logStart;
      PROCEDURE logEnd;
      PROCEDURE logFractionDone(CONST fraction:double; CONST stepMessage:ansistring='');
      FUNCTION estimatedFinalTime:double;
      FUNCTION estimatedRemainingTime:double;
      FUNCTION getProgressString:ansistring;
      PROCEDURE cancelCalculation;
      FUNCTION cancellationRequested:boolean;
      FUNCTION calculating:boolean;
      PROCEDURE waitForEndOfCalculation;
  end;

IMPLEMENTATION

CONSTRUCTOR T_progressEstimator.createWithMessages;
  begin
    createSimple;
    messages:=true;
  end;

CONSTRUCTOR T_progressEstimator.createSimple;
  begin
    cancelled:=false;
    calculationRunning:=false;
    messages:=false;
    system.initCriticalSection(cs);
  end;

DESTRUCTOR T_progressEstimator.destroy;
  begin
    system.enterCriticalSection(cs);
    setLength(progress,0);
    system.leaveCriticalSection(cs);
    system.doneCriticalSection(cs);
  end;

PROCEDURE T_progressEstimator.logStart;
  begin
    system.enterCriticalSection(cs);
    cancelled:=false;
    calculationRunning:=true;
    setLength(progress,1);
    progress[0].time:=now;
    progress[0].fractionDone:=0;
    progress[0].message:='';
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimator.logEnd;
  begin
    system.enterCriticalSection(cs);
    if not(cancelled) then logFractionDone(1);
    calculationRunning:=false;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimator.logFractionDone(CONST fraction: double; CONST stepMessage:ansistring='');
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    if (length(progress)<30) or (messages) then setLength(progress,length(progress)+1)
    else for i:=0 to length(progress)-2 do progress[i]:=progress[i+1];
    with progress[length(progress)-1] do begin
      time:=now;
      fractionDone:=fraction;
      message:=stepMessage;
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimator.estimatedFinalTime: double;
  begin
    system.enterCriticalSection(cs);
    result:=(1-progress[0].fractionDone)/(progress[length(progress)-1].fractionDone-progress[0].fractionDone)
                                        *(progress[length(progress)-1].time        -progress[0].time        )+progress[0].time;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimator.estimatedRemainingTime: double;
  begin
    system.enterCriticalSection(cs);
    result:=estimatedFinalTime-now;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimator.getProgressString:ansistring;
  begin
    system.enterCriticalSection(cs);
    with progress[length(progress)-1] do result:=intToStr(round(fractionDone*100))+'%; rem: '+myTimeToStr(estimatedRemainingTime)+'; '+message;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimator.cancelCalculation;
  begin
    system.enterCriticalSection(cs);
    cancelled:=true;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimator.cancellationRequested: boolean;
  begin
    system.enterCriticalSection(cs);
    result:=cancelled;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimator.calculating:boolean;
  begin
    system.enterCriticalSection(cs);
    result:=calculationRunning;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimator.waitForEndOfCalculation;
  VAR sleepTime:longint=0;
  begin
    while calculating do begin inc(sleepTime); sleep(sleepTime); end;
  end;

end.
