USING Simatic.Ax;
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
            //Test1 (Test to try the LStream_JsonDeserializer.st by deserializing a JSON (inputString1 & inputString2) and comparing its output with the expected tree (expectedTreeOutput1))
            jsonDeserializer : LStream_JsonDeserializer;
            inputString1 : STRING := '{"sessionContext": {"sessionId": "154237171615905","locale": "en_US","persId": 0},"methodName": "valeo2WC.cfWipClose","inArgs": [{"mode": "0","stationNumber": "SubRib0101","step": "0010","cycleTime": "253.2","unitArray": [';
            inputString2 : STRING := '{"unit": "HLF659734","pos": "1", "state": "1","failArray": [{"failCode": "Condensator position","compName": "BOMPOS60"}]},{"unit": "HLF659735","pos": "2", "state": "0"}]}]}';
            rawInput1 : ARRAY[0..10000] OF BYTE;
            actualTreeOutput : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput1 : ARRAY[0..200] OF LStream_typeElement;


            //Test2 (Test to try the LStream_JsonDeserializer.st when the input JSON has empty brackets as value in the key (In this example: "items":[] & "edges":[]). The deserialize output tree is compared with the expected tree (expectedTreeOutput2))
            jsonDeserializer2 : LStream_JsonDeserializer;
            inputString3 : STRING := '{"id":"A","nodes":[{"nodeId":"CAT","items":[],"sequenceId":"A","released":"WORD","nodePosition":{"x":"1"}}],"edges":[]}';
            rawInput2 : ARRAY[0..10000] OF BYTE;
            actualTreeOutput2 : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput2 : ARRAY[0..200] OF LStream_typeElement;

       END_VAR

        {FixtureSetup}
        METHOD PUBLIC TestSetup

            //Test1 Setup
            StringToByteArray(string1 := inputString1, string2 := inputString2, byteArray := rawInput1);          

            expectedTreeOutput1[0].types := SINT#16#0;
            expectedTreeOutput1[0].key := 'sessionContext';
            expectedTreeOutput1[0].value := 'NULL';
            expectedTreeOutput1[0].depth := SINT#16#0;
            expectedTreeOutput1[0].closingElement := FALSE;

            expectedTreeOutput1[1].types := SINT#16#02;
            expectedTreeOutput1[1].key := 'sessionId';
            expectedTreeOutput1[1].value := '154237171615905';
            expectedTreeOutput1[1].depth := SINT#16#01;
            expectedTreeOutput1[1].closingElement := FALSE;

            expectedTreeOutput1[2].types := SINT#16#02;
            expectedTreeOutput1[2].key := 'locale';
            expectedTreeOutput1[2].value := 'en_US';
            expectedTreeOutput1[2].depth := SINT#16#01;
            expectedTreeOutput1[2].closingElement := FALSE;

            expectedTreeOutput1[3].types := SINT#16#03;
            expectedTreeOutput1[3].key := 'persId';
            expectedTreeOutput1[3].value := '0';
            expectedTreeOutput1[3].depth := SINT#16#01;
            expectedTreeOutput1[3].closingElement := TRUE;

            expectedTreeOutput1[4].types := SINT#16#02;
            expectedTreeOutput1[4].key := 'methodName';
            expectedTreeOutput1[4].value := 'valeo2WC.cfWipClose';
            expectedTreeOutput1[4].depth := SINT#16#0;
            expectedTreeOutput1[4].closingElement := FALSE;

            expectedTreeOutput1[5].types := SINT#16#01; 
            expectedTreeOutput1[5].key := 'inArgs';
            expectedTreeOutput1[5].value := 'NULL';
            expectedTreeOutput1[5].depth := SINT#16#0;
            expectedTreeOutput1[5].closingElement := false;

            expectedTreeOutput1[6].types := SINT#16#02;
            expectedTreeOutput1[6].key := 'mode';
            expectedTreeOutput1[6].value := '0';
            expectedTreeOutput1[6].depth := SINT#16#02; 
            expectedTreeOutput1[6].closingElement := false;

            expectedTreeOutput1[7].types := SINT#16#02;
            expectedTreeOutput1[7].key := 'stationNumber';
            expectedTreeOutput1[7].value := 'SubRib0101';
            expectedTreeOutput1[7].depth := SINT#16#02;
            expectedTreeOutput1[7].closingElement := false;

            expectedTreeOutput1[8].types := SINT#16#02;
            expectedTreeOutput1[8].key := 'step';
            expectedTreeOutput1[8].value := '0010';
            expectedTreeOutput1[8].depth := SINT#16#02;
            expectedTreeOutput1[8].closingElement := false;

            expectedTreeOutput1[9].types := SINT#16#02;
            expectedTreeOutput1[9].key := 'cycleTime';
            expectedTreeOutput1[9].value := '253.2';
            expectedTreeOutput1[9].depth := SINT#16#02;
            expectedTreeOutput1[9].closingElement := false;

            expectedTreeOutput1[10].types := SINT#16#01;
            expectedTreeOutput1[10].key := 'unitArray';
            expectedTreeOutput1[10].value := 'NULL';
            expectedTreeOutput1[10].depth := SINT#16#02; 
            expectedTreeOutput1[10].closingElement := false;

            expectedTreeOutput1[11].types := SINT#16#02;
            expectedTreeOutput1[11].key := 'unit';
            expectedTreeOutput1[11].value := 'HLF659734';
            expectedTreeOutput1[11].depth := SINT#16#04;
            expectedTreeOutput1[11].closingElement := false;

            expectedTreeOutput1[12].types := SINT#16#02;
            expectedTreeOutput1[12].key := 'pos';
            expectedTreeOutput1[12].value := '1';
            expectedTreeOutput1[12].depth := SINT#16#04;
            expectedTreeOutput1[12].closingElement := false;

            expectedTreeOutput1[13].types := SINT#16#02;
            expectedTreeOutput1[13].key := 'state';
            expectedTreeOutput1[13].value := '1';
            expectedTreeOutput1[13].depth := SINT#16#04;
            expectedTreeOutput1[13].closingElement := false;

            expectedTreeOutput1[14].types := SINT#16#01;
            expectedTreeOutput1[14].key := 'failArray';
            expectedTreeOutput1[14].value := 'NULL';
            expectedTreeOutput1[14].depth := SINT#16#04;
            expectedTreeOutput1[14].closingElement := false;

            expectedTreeOutput1[15].types := SINT#16#02;
            expectedTreeOutput1[15].key := 'failCode';
            expectedTreeOutput1[15].value := 'Condensator position';
            expectedTreeOutput1[15].depth := SINT#16#06;
            expectedTreeOutput1[15].closingElement := false;

            expectedTreeOutput1[16].types := SINT#16#02;
            expectedTreeOutput1[16].key := 'compName';
            expectedTreeOutput1[16].value := 'BOMPOS60';
            expectedTreeOutput1[16].depth := SINT#16#06;
            expectedTreeOutput1[16].closingElement := true;

            expectedTreeOutput1[17].types := SINT#16#02;
            expectedTreeOutput1[17].key := 'unit';
            expectedTreeOutput1[17].value := 'HLF659735';
            expectedTreeOutput1[17].depth := SINT#16#04;
            expectedTreeOutput1[17].closingElement := FALSE;

            expectedTreeOutput1[18].types := SINT#16#02;
            expectedTreeOutput1[18].key := 'pos';
            expectedTreeOutput1[18].value := '2';
            expectedTreeOutput1[18].depth := SINT#16#04;
            expectedTreeOutput1[18].closingElement := FALSE;

            expectedTreeOutput1[19].types := SINT#16#02;
            expectedTreeOutput1[19].key := 'state';
            expectedTreeOutput1[19].value := '0';
            expectedTreeOutput1[19].depth := SINT#16#04;
            expectedTreeOutput1[19].closingElement := true;



            //Test Setup Json Deserializer case 2       
            StringToByteArray(string1 := inputString3, byteArray := rawInput2);

            expectedTreeOutput2[0].types := SINT#16#02;
            expectedTreeOutput2[0].key := 'id';
            expectedTreeOutput2[0].value := 'A';
            expectedTreeOutput2[0].depth := SINT#16#0;
            expectedTreeOutput2[0].closingElement := FALSE;

            expectedTreeOutput2[1].types := SINT#16#01;
            expectedTreeOutput2[1].key := 'nodes';
            expectedTreeOutput2[1].value := 'NULL';
            expectedTreeOutput2[1].depth := SINT#16#0;
            expectedTreeOutput2[1].closingElement := FALSE;

            expectedTreeOutput2[2].types := SINT#16#02;
            expectedTreeOutput2[2].key := 'nodeId';
            expectedTreeOutput2[2].value := 'CAT';
            expectedTreeOutput2[2].depth := SINT#16#02;
            expectedTreeOutput2[2].closingElement := FALSE;

            expectedTreeOutput2[3].types := SINT#16#01;
            expectedTreeOutput2[3].key := 'items';
            expectedTreeOutput2[3].value := 'NULL';
            expectedTreeOutput2[3].depth := SINT#16#02;
            expectedTreeOutput2[3].closingElement := FALSE;

            expectedTreeOutput2[4].types := SINT#16#02;
            expectedTreeOutput2[4].key := 'sequenceId';
            expectedTreeOutput2[4].value := 'A';
            expectedTreeOutput2[4].depth := SINT#16#02;
            expectedTreeOutput2[4].closingElement := FALSE;

            expectedTreeOutput2[5].types := SINT#16#02;
            expectedTreeOutput2[5].key := 'released';
            expectedTreeOutput2[5].value := 'WORD';
            expectedTreeOutput2[5].depth := SINT#16#02;
            expectedTreeOutput2[5].closingElement := FALSE;

            expectedTreeOutput2[6].types := SINT#16#0;
            expectedTreeOutput2[6].key := 'nodePosition';
            expectedTreeOutput2[6].value := 'NULL';
            expectedTreeOutput2[6].depth := SINT#16#02;
            expectedTreeOutput2[6].closingElement := FALSE;

            expectedTreeOutput2[7].types := SINT#16#02;
            expectedTreeOutput2[7].key := 'x';
            expectedTreeOutput2[7].value := '1';
            expectedTreeOutput2[7].depth := SINT#16#03;
            expectedTreeOutput2[7].closingElement := TRUE;

            expectedTreeOutput2[8].types := SINT#16#01;
            expectedTreeOutput2[8].key := 'edges';
            expectedTreeOutput2[8].value := 'NULL';
            expectedTreeOutput2[8].depth := SINT#16#0;
            expectedTreeOutput2[8].closingElement := TRUE;

        END_METHOD

        //Test1
        {Test}
        METHOD PUBLIC TestJsonDeserializer           
            VAR
                i : INT;                   
            END_VAR;
            // Disable timeout timer for the test
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

            jsonDeserializer.execute := TRUE;
            WHILE (TRUE) DO
                jsonDeserializer(raw := rawInput1, tree := actualTreeOutput);
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
            AXUnit.Assert.Equal(actual := jsonDeserializer.status, expected := WORD#16#0000);
            //Tests for block output content
            Assert.LStreamTypeElementEqual(actualTreeOutput, expectedTreeOutput1);
        END_METHOD

        //Test2
        {Test}
        METHOD PUBLIC TestJsonDeserializer_EmptyBrackets
            VAR
                i : INT;                   
            END_VAR;
            // Disable timeout timer for the test
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

            jsonDeserializer2.execute := TRUE;
            WHILE (TRUE) DO
                jsonDeserializer2(raw := rawInput2, tree := actualTreeOutput2);
                IF(jsonDeserializer2.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(jsonDeserializer2.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE;            
            //Tests for block execution
            AxUnit.Assert.Equal(actual := jsonDeserializer2.resultCount, expected := 9);
            AXUnit.Assert.Equal(actual := jsonDeserializer2.busy, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer2.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer2.done, expected := TRUE);
            AXUnit.Assert.Equal(actual := jsonDeserializer2.status, expected := WORD#16#0000);
            //Tests for block output content
            Assert.LStreamTypeElementEqual(actualTreeOutput2, expectedTreeOutput2);
        END_METHOD        
    END_CLASS

    {TestFixture}
    CLASS JsonDeserializerStatusTest
        VAR
            //Test1 (Test to try the LStream_JsonDeserializer.st by deserializing a JSON (inputString1 & inputString2) and comparing its output with the expected tree (expectedTreeOutput1))
            jsonDeserializer : LStream_JsonDeserializer;
            jsonDeserializerEmpty : LStream_JsonDeserializer;

            // Test Error when given input tree is empty
            rawInputEmpty : ARRAY[0..5] OF BYTE;
            // Test Error when given output tree is empty
            rawInputTreeTooSmall : ARRAY[0..10000] OF BYTE;

            actualTreeOutput : ARRAY[0..0] OF LStream_typeElement;
            actualTreeOutputEmpty : ARRAY[0..0] OF LStream_typeElement;
            inputStringSimple : STRING := '{"id": "A","name":"Too Small Test","year":"2026","sessionContext": {"sessionId":"154237171615905","locale": "en_US","persId": 0}';
            
        END_VAR

        VAR CONSTANT
            /// No job being currently processed
            STATUS_NO_CALL : Word := WORD#16#7000;
            /// Error: provided array to too small
            ERR_TREE_ARRAY_TOO_SMALL : Word := WORD#16#8201;
            /// Error: no raw data provided
            ERR_EMPTY_RAW_DATA : Word := WORD#16#8401;
            /// Error: due to an undefined state in state machine
            ERR_UNDEFINED_STATE : Word := WORD#16#8600;
        END_VAR
        

        {TestSetup}
        METHOD PUBLIC TestSetup
            jsonDeserializer := jsonDeserializerEmpty;
            actualTreeOutput := actualTreeOutputEmpty;
        END_METHOD
        
        {Test}
        METHOD PUBLIC TestJsonDeserializer_ErrorEmptyRawData
            // Disable timeout timer for deterministic parsing progress
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

            jsonDeserializer.execute := FALSE;
            jsonDeserializer(raw := rawInputEmpty, tree := actualTreeOutput);

            jsonDeserializer.execute := TRUE;
            WHILE (TRUE) DO
                jsonDeserializer(raw := rawInputEmpty, tree := actualTreeOutput);
                IF(jsonDeserializer.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(jsonDeserializer.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE; 

            AXUnit.Assert.Equal(actual := jsonDeserializer.done, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.error, expected := TRUE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.busy, expected := FALSE);            
            AXUnit.Assert.Equal(actual := jsonDeserializer.status, expected := ERR_EMPTY_RAW_DATA);

            // Check if error reset
            jsonDeserializer(execute := FALSE, raw := rawInputEmpty, tree := actualTreeOutput);
            AXUnit.Assert.Equal(actual := jsonDeserializer.done, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.busy, expected := FALSE);            
            AXUnit.Assert.Equal(actual := jsonDeserializer.status, expected := STATUS_NO_CALL);
        END_METHOD

        {Test}
        METHOD PUBLIC TestJsonDeserializer_ErrorTreeTooSmall
            // Disable timeout timer for deterministic parsing progress
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

            // StringToByteArray(string1 := inputStringSimple, byteArray := rawInputTreeTooSmall);
            System.Serialization.Serialize(offset := 0, value := inputStringSimple, buffer := rawInputTreeTooSmall);
            
            jsonDeserializer.execute := FALSE;
            jsonDeserializer(raw := rawInputTreeTooSmall, tree := actualTreeOutput);

            jsonDeserializer.execute := TRUE;
            WHILE (TRUE) DO
                jsonDeserializer(raw := rawInputTreeTooSmall, tree := actualTreeOutput);
                IF(jsonDeserializer.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(jsonDeserializer.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE; 

            AXUnit.Assert.Equal(actual := jsonDeserializer.done, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.error, expected := TRUE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.busy, expected := FALSE);            
            AXUnit.Assert.Equal(actual := jsonDeserializer.status, expected := ERR_TREE_ARRAY_TOO_SMALL);

            // Check if error reset
            jsonDeserializer(execute := FALSE, raw := rawInputTreeTooSmall, tree := actualTreeOutput);
            AXUnit.Assert.Equal(actual := jsonDeserializer.done, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonDeserializer.busy, expected := FALSE);            
            AXUnit.Assert.Equal(actual := jsonDeserializer.status, expected := STATUS_NO_CALL);
        END_METHOD
    END_CLASS
END_NAMESPACE

