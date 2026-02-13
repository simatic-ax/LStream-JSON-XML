NAMESPACE Simatic.Ax.Timer
    
    INTERFACE PUBLIC ITimerFunctions
        METHOD TimerFunction : BOOL
            VAR_INPUT
                signal : BOOL;
                duration : LTIME;
            END_VAR
        END_METHOD
    END_INTERFACE
    
END_NAMESPACE
