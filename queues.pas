UNIT queues;
INTERFACE
USES sysutils;
TYPE
  T_taskState=(fts_pending, //set on construction
               fts_evaluating, //set on dequeue
               fts_ready); //set after evaluation



  P_task=^T_task;
  T_task=record
    task:pointer;
    state:T_taskState;
    next:P_task;
  end;

  { T_taskQueue }

  T_taskQueue=object
    first,last:P_task;
    queuedCount:longint;
    cs:system.TRTLCriticalSection;

    CONSTRUCTOR create;
    DESTRUCTOR destroy;
    FUNCTION  enqueue(CONST todo:pointer):P_task;
    FUNCTION  dequeue:P_task;
    FUNCTION  activeDeqeue:P_task;
    FUNCTION  fill:longint;
    PROCEDURE dropPending;
  end;

  T_evaluationFunction=PROCEDURE(CONST task:pointer);
  T_disposeFunction   =PROCEDURE(p:pointer);
VAR evaluationFunction:T_evaluationFunction=nil;
    disposeFunction   :T_disposeFunction=nil;
    pendingTasks:T_taskQueue;

FUNCTION numberOfBusyThreads:longint;
IMPLEMENTATION
VAR poolThreadsRunning:longint=0;
    busyThreads:longint=0;
FUNCTION numberOfBusyThreads:longint; begin result:=busyThreads; end;

PROCEDURE customTaskDestroy(VAR task:P_task);
  begin
    if disposeFunction<>nil then begin
      disposeFunction(task^.task);
      freeMem(task,sizeOf(T_task));
      task:=nil;
    end;
  end;

FUNCTION threadPoolThread(p:pointer):ptrint;
  VAR sleepTime:longint;
      currentTask:P_task;
  begin
    sleepTime:=0;
    repeat
      currentTask:=pendingTasks.dequeue;
      if currentTask=nil then begin
        inc(sleepTime);
        sleep(sleepTime div 5);
      end else begin
        InterLockedIncrement(busyThreads);
        if evaluationFunction<>nil then evaluationFunction(currentTask^.task);
        customTaskDestroy(currentTask);
        sleepTime:=0;
        interlockedDecrement(busyThreads);
      end;
    until sleepTime>=500;
    result:=0;
    interlockedDecrement(poolThreadsRunning);
  end;

PROCEDURE ensurePoolThreads;
  begin
    if (poolThreadsRunning<3) then begin
      InterLockedIncrement(poolThreadsRunning);
      beginThread(@threadPoolThread);
    end;
  end;

CONSTRUCTOR T_taskQueue.create;
  begin
    system.initCriticalSection(cs);
    first:=nil;
    last:=nil;
    queuedCount:=0;
  end;

DESTRUCTOR T_taskQueue.destroy;
  begin
    system.doneCriticalSection(cs);
  end;

FUNCTION T_taskQueue.enqueue(CONST todo:pointer):P_task;
  begin
    getMem(result,sizeOf(T_task));
    result^.task:=todo;
    result^.state:=fts_pending;
    result^.next:=nil;
    if result^.state=fts_pending then begin
      system.enterCriticalSection(cs);
      if first=nil then begin
        queuedCount:=1;
        first:=result;
        last:=result;
      end else begin
        inc(queuedCount);
        last^.next:=result;
        last:=result;
      end;
      ensurePoolThreads;
      system.leaveCriticalSection(cs);
    end;
  end;

FUNCTION  T_taskQueue.dequeue:P_task;
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

FUNCTION T_taskQueue.activeDeqeue:P_task;
  begin
    result:=dequeue;
    if result<>nil then begin
      if evaluationFunction<>nil then evaluationFunction(result^.task);
      customTaskDestroy(result);
    end;
  end;

FUNCTION T_taskQueue.fill:longint;
  begin
    result:=queuedCount;
  end;

PROCEDURE T_taskQueue.dropPending;
  VAR task:P_task;
  begin
    while fill>0 do begin
      task:=dequeue;
      if task=nil then exit;
      customTaskDestroy(task);
    end;
  end;

INITIALIZATION
  pendingTasks.create;
FINALIZATION
  pendingTasks.destroy;
end.
