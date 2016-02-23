UNIT myTools;
INTERFACE
USES sysutils,myStringUtil,mySys,math;
CONST ESTIMATOR_PROGRESS_STEP_AIM=32;
TYPE
  T_callback=PROCEDURE of object;
  T_estimatorType=(et_uninitialized,
                   et_stepCounter_parallel,
                   et_commentedStepsOfVaryingCost_serial);
  T_estimatorQueueState=(eqs_invalid,   //on construction
                         eqs_reset,     //on force start
                         eqs_running,   //on enqueue
                         eqs_cancelling,//on cancel calculation
                         eqs_cancelled, //on eqs_cancelling and queuedCount=busyThreads=0
                         eqs_done);     //on logEnd or eqs_running and queuedCount=busyThreads=0


  T_taskState=(fts_pending,    //set on construction
               fts_evaluating, //set on dequeue
               fts_ready);     //set after evaluation

  P_queueToDo=^T_queueToDo;
  T_queueToDo=object
    state:T_taskState;
    next:P_queueToDo;
    CONSTRUCTOR create;
    DESTRUCTOR destroy; virtual;
    PROCEDURE execute; virtual;
  end;

  P_progressEstimatorQueue=^T_progressEstimatorQueue;
  T_progressEstimatorQueue=object
    private
      //shared variables:--------------//
      onEndCallback:T_callback;        //
      cs:TRTLCriticalSection;          //
      state:T_estimatorQueueState;     //
      childProgress:P_progressEstimatorQueue;
      //progress estimator variables:--//
      startOfCalculation:double;       //
      estimatorType:T_estimatorType;   //
      progress:array of record         //
        time,fractionDone:double;      //
        message:ansistring;            //
      end;                             //
      totalSteps,stepsDone:longint;    //
      //queue variables:---------------//
      first,last:P_queueToDo;          //
      poolThreadsRunning:longint;      //
      busyThreads:longint;             //
      queuedCount:longint;             //
      PROCEDURE logFractionDone(CONST fraction:double);
    public
      CONSTRUCTOR create(CONST child:P_progressEstimatorQueue=nil);
      PROCEDURE forceStart(CONST typ:T_estimatorType; CONST expectedTotalSteps:longint=0);
      DESTRUCTOR destroy;
      PROCEDURE logEnd;
      PROCEDURE logStepDone;
      PROCEDURE logStepMessage(CONST message:ansistring);
      FUNCTION estimatedTotalTime:double;
      FUNCTION estimatedRemainingTime:double;
      FUNCTION getProgressString:ansistring;
      PROCEDURE cancelCalculation(CONST waitForTerminate:boolean=false);
      FUNCTION cancellationRequested:boolean;
      FUNCTION calculating:boolean;
      PROCEDURE waitForEndOfCalculation;
      PROCEDURE registerOnEndCallback(CONST callback:T_callback);
      PROCEDURE ensureStop;

      PROCEDURE enqueue(CONST task:P_queueToDo);
      FUNCTION  dequeue:P_queueToDo;
      FUNCTION  activeDeqeue:boolean;
  end;

IMPLEMENTATION

{ T_queueToDo }

CONSTRUCTOR T_queueToDo.create;
  begin
    state:=fts_pending;
    next:=nil;
  end;

DESTRUCTOR T_queueToDo.destroy;
  begin
    state:=fts_pending;
    next:=nil;
  end;

PROCEDURE T_queueToDo.execute;
  begin writeln('Dummy-execute was called!!!!!'); end; //-dummy-

CONSTRUCTOR T_progressEstimatorQueue.create(CONST child:P_progressEstimatorQueue=nil);
  begin
    state:=eqs_invalid;
    estimatorType:=et_uninitialized;
    system.initCriticalSection(cs);
    onEndCallback:=nil;
    first:=nil;
    last:=nil;
    queuedCount:=0;
    childProgress:=child;
  end;

DESTRUCTOR T_progressEstimatorQueue.destroy;
  begin
    cancelCalculation(true);
    system.enterCriticalSection(cs);
    setLength(progress,0);
    system.leaveCriticalSection(cs);
    system.doneCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.forceStart(CONST typ:T_estimatorType; CONST expectedTotalSteps:longint=0);
  begin
    cancelCalculation(true);
    if typ=et_uninitialized then begin
      writeln(stderr,'Invalid estimator type!');
      halt;
    end;
    startOfCalculation:=now;
    estimatorType:=typ;
    totalSteps:=expectedTotalSteps;
    stepsDone:=0;
    system.enterCriticalSection(cs);
    state:=eqs_reset;
    setLength(progress,1);
    progress[0].time:=now;
    progress[0].fractionDone:=0;
    progress[0].message:='';
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.logEnd;
  begin
    system.enterCriticalSection(cs);
    if state in [eqs_reset,eqs_running] then begin
      logFractionDone(1);
      state:=eqs_done;
      if onEndCallback<>nil then onEndCallback();
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.logFractionDone(CONST fraction: double);
  VAR i:longint;
  begin
    system.enterCriticalSection(cs);
    if (length(progress)<ESTIMATOR_PROGRESS_STEP_AIM) or (estimatorType=et_commentedStepsOfVaryingCost_serial) then setLength(progress,length(progress)+1)
    else for i:=0 to length(progress)-2 do progress[i]:=progress[i+1];
    with progress[length(progress)-1] do begin
      time:=now;
      fractionDone:=fraction;
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.logStepMessage(CONST message:ansistring);
  VAR LI:longint;
  begin
    system.enterCriticalSection(cs);
    LI:=length(progress)-1;
    if (LI>=0) then progress[LI].message:=message;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.logStepDone;
  begin
    system.enterCriticalSection(cs);
    inc(stepsDone);
    logFractionDone(stepsDone/totalSteps);
    if stepsDone=totalSteps then logEnd;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimatorQueue.estimatedTotalTime: double;
  VAR LI:longint;
  begin
    system.enterCriticalSection(cs);
    LI:=length(progress)-1;
    if LI=0 then begin
      if (childProgress<>nil) and (childProgress^.calculating)
      then result:=childProgress^.estimatedTotalTime*totalSteps
      else result:=1;
    end else begin
      result:=(progress[LI].time-progress[0].time)/(progress[LI].fractionDone-progress[0].fractionDone);
      if (childProgress<>nil) and (childProgress^.calculating)
      then result:=result+childProgress^.estimatedTotalTime;
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimatorQueue.estimatedRemainingTime: double;
  begin
    system.enterCriticalSection(cs);
    result:=                 (1-progress[length(progress)-1].fractionDone)*estimatedTotalTime+(progress[length(progress)-1].time-now);
    if result<0 then result:=(1-progress[length(progress)-1].fractionDone)*estimatedTotalTime;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimatorQueue.getProgressString:ansistring;
  begin
    system.enterCriticalSection(cs);
    with progress[length(progress)-1] do case state of
      eqs_done:      result:='done ('+myTimeToStr(time-startOfCalculation)+')';
      eqs_cancelled: result:='cancelled ('+myTimeToStr(time-startOfCalculation)+')';
      eqs_reset,eqs_running,eqs_cancelling: begin
        if estimatorType=et_commentedStepsOfVaryingCost_serial
        then result:=intToStr(stepsDone)+'/'+intToStr(totalSteps)
        else result:=intToStr(round(fractionDone*100))+'%';
        result:=result+'; rem: '+myTimeToStr(estimatedRemainingTime)+'; '+message;
        if (childProgress<>nil) and (childProgress^.calculating) then result:=result+childProgress^.getProgressString;
      end;
      else result:='';
    end;
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.cancelCalculation(CONST waitForTerminate:boolean=false);
  VAR task:P_queueToDo;
  begin
    if childProgress<>nil then childProgress^.cancelCalculation(waitForTerminate);
    system.enterCriticalSection(cs);
    state:=eqs_cancelling;
    system.leaveCriticalSection(cs);
    while queuedCount>0 do begin
      task:=dequeue;
      if task<>nil then dispose(task,destroy);
    end;
    if waitForTerminate then while (busyThreads>0) do sleep(10);
  end;

FUNCTION T_progressEstimatorQueue.cancellationRequested: boolean;
  begin
    system.enterCriticalSection(cs);
    result:=state in [eqs_cancelling,eqs_cancelled];
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimatorQueue.calculating:boolean;
  begin
    system.enterCriticalSection(cs);
    if (busyThreads=0) and (queuedCount=0) then case state of
      eqs_running:    state:=eqs_done;
      eqs_cancelling: state:=eqs_cancelled;
    end;
    result:=state in [eqs_running,eqs_cancelling];
    system.leaveCriticalSection(cs);
  end;

PROCEDURE T_progressEstimatorQueue.waitForEndOfCalculation;
  begin
    while calculating do sleep(10);
  end;

PROCEDURE T_progressEstimatorQueue.registerOnEndCallback(CONST callback:T_callback);
  begin
    onEndCallback:=callback;
  end;

PROCEDURE T_progressEstimatorQueue.ensureStop;
  begin
    if calculating then cancelCalculation(true);
  end;

FUNCTION queueThreadPoolThread(p:pointer):ptrint;
  VAR currentTask:P_queueToDo;
      queue:P_progressEstimatorQueue;
      idleCount:longint=0;
  begin
    SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);
    randomize;
    queue:=P_progressEstimatorQueue(p);
    //Initially, the thread is considered busy
    InterLockedIncrement(queue^.busyThreads);
    repeat
      currentTask:=queue^.dequeue;
      if currentTask=nil then begin
        //The thread was busy before, mark it as idle once
        if idleCount=0 then interlockedDecrement(queue^.busyThreads);
        inc(idleCount);

        sleep(1);
      end else begin
        //If the thread was idle before, mark it as busy again
        if idleCount>0 then InterLockedIncrement(queue^.busyThreads);
        idleCount:=0;

        currentTask^.execute;
        dispose(currentTask,destroy);
      end;
    until (idleCount>10) or queue^.cancellationRequested;
    //The thread was busy before, finally mark it as idle
    if idleCount=0 then interlockedDecrement(queue^.busyThreads);
    //Say goodbye before you go
    interlockedDecrement(queue^.poolThreadsRunning);
    result:=0;
  end;

PROCEDURE T_progressEstimatorQueue.enqueue(CONST task:P_queueToDo);
  PROCEDURE ensurePoolThreads;
    begin
      if (poolThreadsRunning<getNumberOfCPUs) and (estimatorType=et_stepCounter_parallel)
      or (poolThreadsRunning=0              ) and (estimatorType=et_commentedStepsOfVaryingCost_serial)
      then begin
        InterLockedIncrement(poolThreadsRunning);
        beginThread(@queueThreadPoolThread,@self);
      end;
    end;

  begin
    task^.state:=fts_pending;
    task^.next:=nil;
    system.enterCriticalSection(cs);
    state:=eqs_running;
    if first=nil then begin
      queuedCount:=1;
      first:=task;
      last:=task;
    end else begin
      inc(queuedCount);
      last^.next:=task;
      last:=task;
    end;
    system.leaveCriticalSection(cs);
    ensurePoolThreads;
  end;

FUNCTION T_progressEstimatorQueue.dequeue:P_queueToDo;
  begin
    system.enterCriticalSection(cs);
    if first=nil then result:=nil
    else begin
      dec(queuedCount);
      result:=first;
      first:=first^.next;
      result^.state:=fts_evaluating;
    end;
    system.leaveCriticalSection(cs);
  end;

FUNCTION T_progressEstimatorQueue.activeDeqeue:boolean;
  VAR task:P_queueToDo;
  begin
    task:=dequeue;
    if task<>nil then begin
      task^.execute;
      dispose(task,destroy);
      result:=true;
    end else result:=false;
  end;

end.
