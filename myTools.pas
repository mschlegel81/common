UNIT myTools;
INTERFACE
USES sysutils;
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
      PROCEDURE cancelCalculation;
      FUNCTION cancellationRequested:boolean;
  end;  
  
IMPLEMENTATION

constructor T_progressEstimator.createWithMessages;
  begin
    createSimple;
    messages:=true;
  end;

constructor T_progressEstimator.createSimple;
  begin
    cancelled:=false;
    calculationRunning:=false;
    messages:=false;
    system.InitCriticalSection(cs);
  end;

destructor T_progressEstimator.destroy;
  begin
    system.EnterCriticalsection(cs);
    setLength(progress,0);
    system.LeaveCriticalsection(cs);
    system.DoneCriticalsection(cs);
  end;

procedure T_progressEstimator.logStart;
  begin
    system.EnterCriticalsection(cs);
    cancelled:=false;
    calculationRunning:=true;
    setLength(progress,1);
    progress[0].time:=now;
    progress[0].fractionDone:=0;
    progress[0].message:='';
    system.LeaveCriticalsection(cs);
  end;

procedure T_progressEstimator.logEnd;
  begin
    system.EnterCriticalsection(cs);
    if not(cancelled) then logFractionDone(1);
    calculationRunning:=false;
    system.LeaveCriticalsection(cs);
  end;

procedure T_progressEstimator.logFractionDone(const fraction: double; CONST stepMessage:ansistring='');
  VAR i:longint;
  begin
    system.EnterCriticalsection(cs);
    if (length(progress)<30) or (messages) then setLength(progress,length(progress)+1)
    else for i:=0 to length(progress)-2 do progress[i]:=progress[i+1];
    with progress[length(progress)-1] do begin
      time:=now;
      fractionDone:=fraction;
      message:=stepMessage;
    end;
    system.LeaveCriticalsection(cs);
  end;

function T_progressEstimator.estimatedFinalTime: double;
  begin
    system.EnterCriticalsection(cs);
    result:=(1-progress[0].fractionDone)/(progress[length(progress)-1].fractionDone-progress[0].fractionDone)
                                        *(progress[length(progress)-1].time        -progress[0].time        )+progress[0].time;
    system.LeaveCriticalsection(cs);
  end;

function T_progressEstimator.estimatedRemainingTime: double;
  begin
    system.EnterCriticalsection(cs);
    result:=estimatedFinalTime-now;
    system.LeaveCriticalsection(cs);
  end;

procedure T_progressEstimator.cancelCalculation;
  begin
    system.EnterCriticalsection(cs);
    cancelled:=true;
    system.LeaveCriticalsection(cs);
  end;

function T_progressEstimator.cancellationRequested: boolean;
  begin
    system.EnterCriticalsection(cs);
    result:=cancelled;
    system.LeaveCriticalsection(cs);
  end;

end.
