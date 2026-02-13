USING AxUnit.ResultFunctions;
USING Simatic.Ax.LStream.Models;
USING System.Strings;

NAMESPACE LStreamTest.Assert
    FUNCTION PUBLIC LStreamTypeElementEqual
        VAR_IN_OUT
            testeeResult : ARRAY [*] OF LStream_typeElement;
            expectedResult : ARRAY [*] OF LStream_typeElement;
        END_VAR

        VAR_INPUT
            {CallerFilePath}
            file : WSTRING[1024];
            {CallerLineNumber}
            line : INT;
        END_VAR

        VAR
            i : DINT;
        END_VAR
        

        IF UPPER_BOUND(testeeResult, 1) <> UPPER_BOUND(expectedResult, 1) THEN
            axunit_Fail('Array size mismatch', file, line);      
        END_IF;    

        FOR i := LOWER_BOUND(testeeResult, 1) TO UPPER_BOUND(testeeResult, 1)  DO
            IF testeeResult[i].closingElement <> expectedResult[i].closingElement THEN
                axunit_Fail(Concat('Array content mismatch: closing element. In position: ', ToString(i) ) , file, line);   
            END_IF;
            IF testeeResult[i].depth <> expectedResult[i].depth THEN
                axunit_Fail(Concat('Array content mismatch: depth. In position: ', ToString(i) ), file, line);   
            END_IF;
            IF testeeResult[i].key <> expectedResult[i].key THEN
                axunit_Fail(Concat('Array content mismatch: key. In position: ', ToString(i) ), file, line);   
            END_IF;
            IF testeeResult[i].types <> expectedResult[i].types THEN
                axunit_Fail(Concat('Array content mismatch: types. In position: ', ToString(i) ), file, line);   
            END_IF;
            IF testeeResult[i].value <> expectedResult[i].value THEN
                axunit_Fail(Concat('Array content mismatch: vale. In position: ', ToString(i) ), file, line);   
            END_IF;
        END_FOR;
        axunit_Succeed();
    END_FUNCTION
END_NAMESPACE