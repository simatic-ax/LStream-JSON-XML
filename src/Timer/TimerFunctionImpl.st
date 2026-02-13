USING System.Timer;


NAMESPACE Simatic.Ax.Timer
    
    CLASS PUBLIC TimerFunctionsImpl IMPLEMENTS ITimerFunctions 
        VAR
            Timer : OnDelay;
        END_VAR

        METHOD PUBLIC TimerFunction : BOOL
            VAR_INPUT
                signal : BOOL;
                duration : LTIME;
            END_VAR
            
            Timer(signal := signal, duration := duration);
            TimerFunction := Timer.output;
            
        END_METHOD
    END_CLASS
    
END_NAMESPACE
