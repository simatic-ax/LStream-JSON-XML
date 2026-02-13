NAMESPACE Simatic.Ax.Timer

    CLASS PUBLIC TimerFunctionsMock IMPLEMENTS ITimerFunctions
        
        VAR PUBLIC
            SetTimerValue : BOOL;
        END_VAR
     
         METHOD PUBLIC TimerFunction : BOOL
            VAR_INPUT
                signal : BOOL;
                duration : LTIME;
            END_VAR
            TimerFunction := SetTimerValue;
         END_METHOD
     END_CLASS
    
END_NAMESPACE
