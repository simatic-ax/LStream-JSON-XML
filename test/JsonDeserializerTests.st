USING Simatic.Ax;
USING Simatic.Ax.Timer;
USING AxUnit;
USING Simatic.Ax.LStream;
USING Simatic.Ax.LStream.Utilities;
USING Simatic.Ax.System.Strings;
using Simatic.Ax.LStream.Models;

NAMESPACE LStreamTest

    ///////////////// Tests for JSON Blocks
    {TestFixture}
    CLASS JsonDeserializerTests
        VAR          
            //Mock Timer
            TimerInst : TimerFunctionsMock;       
            //Test Variables Json Deserializer
            jsonDeserializer : LStream_JsonDeserializer;
            inputString1 : STRING := '{"sessionContext": {"sessionId": "154237171615905","locale": "en_US","persId": 0},"methodName": "valeo2WC.cfWipClose","inArgs": [{"mode": "0","stationNumber": "SubRib0101","step": "0010","cycleTime": "253.2","unitArray": [';
            inputString2 : STRING := '{"unit": "HLF659734","pos": "1", "state": "1","failArray": [{"failCode": "Condensator position","compName": "BOMPOS60"}]},{"unit": "HLF659735","pos": "2", "state": "0"}]}]}';
            rawInput : ARRAY[0..10000] OF BYTE;
            actualTreeOutput : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput : ARRAY[0..200] OF LStream_typeElement;
       END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup

            //Test Setup Json Deserializer case 1
            jsonDeserializer.TimeoutTimer := TimerInst;
            StringToByteArray(string1 := inputString1, string2 := inputString2, byteArray := rawInput);          
            // Populate expected LStreamTypeElementArray
            // Populate expectedTreeOutput
            expectedTreeOutput[0].types := SINT#16#0;
            expectedTreeOutput[0].key := 'sessionContext';
            expectedTreeOutput[0].value := 'NULL';
            expectedTreeOutput[0].depth := SINT#16#0;
            expectedTreeOutput[0].closingElement := FALSE;

            expectedTreeOutput[1].types := SINT#16#02;
            expectedTreeOutput[1].key := 'sessionId';
            expectedTreeOutput[1].value := '154237171615905';
            expectedTreeOutput[1].depth := SINT#16#01;
            expectedTreeOutput[1].closingElement := FALSE;

            expectedTreeOutput[2].types := SINT#16#02;
            expectedTreeOutput[2].key := 'locale';
            expectedTreeOutput[2].value := 'en_US';
            expectedTreeOutput[2].depth := SINT#16#01;
            expectedTreeOutput[2].closingElement := FALSE;

            expectedTreeOutput[3].types := SINT#16#03;
            expectedTreeOutput[3].key := 'persId';
            expectedTreeOutput[3].value := '0';
            expectedTreeOutput[3].depth := SINT#16#01;
            expectedTreeOutput[3].closingElement := TRUE;

            expectedTreeOutput[4].types := SINT#16#02;
            expectedTreeOutput[4].key := 'methodName';
            expectedTreeOutput[4].value := 'valeo2WC.cfWipClose';
            expectedTreeOutput[4].depth := SINT#16#0;
            expectedTreeOutput[4].closingElement := FALSE;

            expectedTreeOutput[5].types := SINT#16#01; 
            expectedTreeOutput[5].key := 'inArgs';
            expectedTreeOutput[5].value := 'NULL';
            expectedTreeOutput[5].depth := SINT#16#0;
            expectedTreeOutput[5].closingElement := false;

            expectedTreeOutput[6].types := SINT#16#02;
            expectedTreeOutput[6].key := 'mode';
            expectedTreeOutput[6].value := '0';
            expectedTreeOutput[6].depth := SINT#16#02; 
            expectedTreeOutput[6].closingElement := false;

            expectedTreeOutput[7].types := SINT#16#02;
            expectedTreeOutput[7].key := 'stationNumber';
            expectedTreeOutput[7].value := 'SubRib0101';
            expectedTreeOutput[7].depth := SINT#16#02;
            expectedTreeOutput[7].closingElement := false;

            expectedTreeOutput[8].types := SINT#16#02;
            expectedTreeOutput[8].key := 'step';
            expectedTreeOutput[8].value := '0010';
            expectedTreeOutput[8].depth := SINT#16#02;
            expectedTreeOutput[8].closingElement := false;

            expectedTreeOutput[9].types := SINT#16#02;
            expectedTreeOutput[9].key := 'cycleTime';
            expectedTreeOutput[9].value := '253.2';
            expectedTreeOutput[9].depth := SINT#16#02;
            expectedTreeOutput[9].closingElement := false;

            expectedTreeOutput[10].types := SINT#16#01;
            expectedTreeOutput[10].key := 'unitArray';
            expectedTreeOutput[10].value := 'NULL';
            expectedTreeOutput[10].depth := SINT#16#02; 
            expectedTreeOutput[10].closingElement := false;

            expectedTreeOutput[11].types := SINT#16#02;
            expectedTreeOutput[11].key := 'unit';
            expectedTreeOutput[11].value := 'HLF659734';
            expectedTreeOutput[11].depth := SINT#16#04;
            expectedTreeOutput[11].closingElement := false;

            expectedTreeOutput[12].types := SINT#16#02;
            expectedTreeOutput[12].key := 'pos';
            expectedTreeOutput[12].value := '1';
            expectedTreeOutput[12].depth := SINT#16#04;
            expectedTreeOutput[12].closingElement := false;

            expectedTreeOutput[13].types := SINT#16#02;
            expectedTreeOutput[13].key := 'state';
            expectedTreeOutput[13].value := '1';
            expectedTreeOutput[13].depth := SINT#16#04;
            expectedTreeOutput[13].closingElement := false;

            expectedTreeOutput[14].types := SINT#16#01;
            expectedTreeOutput[14].key := 'failArray';
            expectedTreeOutput[14].value := 'NULL';
            expectedTreeOutput[14].depth := SINT#16#04;
            expectedTreeOutput[14].closingElement := false;

            expectedTreeOutput[15].types := SINT#16#02;
            expectedTreeOutput[15].key := 'failCode';
            expectedTreeOutput[15].value := 'Condensator position';
            expectedTreeOutput[15].depth := SINT#16#06;
            expectedTreeOutput[15].closingElement := false;

            expectedTreeOutput[16].types := SINT#16#02;
            expectedTreeOutput[16].key := 'compName';
            expectedTreeOutput[16].value := 'BOMPOS60';
            expectedTreeOutput[16].depth := SINT#16#06;
            expectedTreeOutput[16].closingElement := true;

            expectedTreeOutput[17].types := SINT#16#02;
            expectedTreeOutput[17].key := 'unit';
            expectedTreeOutput[17].value := 'HLF659735';
            expectedTreeOutput[17].depth := SINT#16#04;
            expectedTreeOutput[17].closingElement := FALSE;

            expectedTreeOutput[18].types := SINT#16#02;
            expectedTreeOutput[18].key := 'pos';
            expectedTreeOutput[18].value := '2';
            expectedTreeOutput[18].depth := SINT#16#04;
            expectedTreeOutput[18].closingElement := FALSE;

            expectedTreeOutput[19].types := SINT#16#02;
            expectedTreeOutput[19].key := 'state';
            expectedTreeOutput[19].value := '0';
            expectedTreeOutput[19].depth := SINT#16#04;
            expectedTreeOutput[19].closingElement := true;
        END_METHOD

        {Test}
        METHOD PUBLIC TestJsonDeserializer
            VAR
                i : INT;                   
            END_VAR;
            TimerInst.SetTimerValue := FALSE;
            jsonDeserializer.execute := TRUE;
            WHILE (TRUE) DO
                jsonDeserializer(raw := rawInput, tree := actualTreeOutput);
                IF(jsonDeserializer.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(jsonDeserializer.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE;            
            //Tests for block execution
            AxUnit.Assert.Equal(actual := jsonDeserializer.resultCount, expected := 20);
            AXUnit.Assert.Equal(actual := jsonDeserializer.busy, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.done, expected := TRUE);
            //Tests for block output content
            Assert.LStreamTypeElementEqual(actualTreeOutput, expectedTreeOutput);
        END_METHOD
    END_CLASS
END_NAMESPACE

