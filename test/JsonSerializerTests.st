USING Simatic.Ax;
USING Simatic.Ax.Timer;
USING AxUnit;
USING Simatic.Ax.LStream;
USING Simatic.Ax.LStream.Utilities;
USING System.Strings;
using Simatic.Ax.LStream.Models;
using System.Serialization;

NAMESPACE LStreamTest

    {TestFixture}
    CLASS JsonSerializerTests
        VAR
            timerInst : TimerFunctionsMock;       
            jsonSerializer : LStream_JsonSerializer;
            jsonByteOutputResult : ARRAY[0..600] OF BYTE;
            treeInput : ARRAY[0..200] OF LStream_typeElement;
            expectedJsonByteOutputResult : ARRAY[0..600] OF BYTE := [                
            BYTE#16#7B, BYTE#16#22, BYTE#16#73, BYTE#16#65, BYTE#16#73, BYTE#16#73, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#43, BYTE#16#6F, BYTE#16#6E, BYTE#16#74, BYTE#16#65, BYTE#16#78, BYTE#16#74, BYTE#16#22, BYTE#16#3A, BYTE#16#7B, BYTE#16#22, BYTE#16#73, BYTE#16#65, BYTE#16#73, BYTE#16#73, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#49, BYTE#16#64, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#31, BYTE#16#35, BYTE#16#34, BYTE#16#32, BYTE#16#33, BYTE#16#37, BYTE#16#31, BYTE#16#37, BYTE#16#31, BYTE#16#36, BYTE#16#31, BYTE#16#35, BYTE#16#39, BYTE#16#30, BYTE#16#35, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#6C, BYTE#16#6F, BYTE#16#63, BYTE#16#61, BYTE#16#6C, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#5F, BYTE#16#55, BYTE#16#53, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#70, BYTE#16#65, BYTE#16#72, BYTE#16#73, BYTE#16#49, BYTE#16#64, BYTE#16#22, BYTE#16#3A, BYTE#16#30, BYTE#16#7D, BYTE#16#2C, BYTE#16#22, BYTE#16#6D, BYTE#16#65, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#64, BYTE#16#4E, BYTE#16#61, BYTE#16#6D, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#76, BYTE#16#61, BYTE#16#6C, BYTE#16#65, BYTE#16#6F, BYTE#16#32, BYTE#16#57, BYTE#16#43, BYTE#16#2E, BYTE#16#63, BYTE#16#66, BYTE#16#57, BYTE#16#69, BYTE#16#70, BYTE#16#43, BYTE#16#6C, BYTE#16#6F, BYTE#16#73, BYTE#16#65, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#69, BYTE#16#6E, BYTE#16#41, BYTE#16#72, BYTE#16#67, BYTE#16#73, BYTE#16#22, BYTE#16#3A, BYTE#16#5B, BYTE#16#7B, BYTE#16#22, BYTE#16#6D, BYTE#16#6F, BYTE#16#64, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#30, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#73, BYTE#16#74, BYTE#16#61, BYTE#16#74, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#4E, BYTE#16#75, BYTE#16#6D, BYTE#16#62, BYTE#16#65, BYTE#16#72, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#53, BYTE#16#75, BYTE#16#62, BYTE#16#52, BYTE#16#69, BYTE#16#62, BYTE#16#30, BYTE#16#31, BYTE#16#30, BYTE#16#31, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#73, BYTE#16#74, BYTE#16#65, BYTE#16#70, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#30, BYTE#16#30, BYTE#16#31, BYTE#16#30, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#63, BYTE#16#79, BYTE#16#63, BYTE#16#6C, BYTE#16#65, BYTE#16#54, BYTE#16#69, BYTE#16#6D, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#32, BYTE#16#35, BYTE#16#33, BYTE#16#2E, BYTE#16#32, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#75, BYTE#16#6E, BYTE#16#69, BYTE#16#74, BYTE#16#41, BYTE#16#72, BYTE#16#72, BYTE#16#61, BYTE#16#79, BYTE#16#22, BYTE#16#3A, BYTE#16#5B, BYTE#16#7B, BYTE#16#22, BYTE#16#75, BYTE#16#6E, BYTE#16#69, BYTE#16#74, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#48, BYTE#16#4C, BYTE#16#46, BYTE#16#36, BYTE#16#35, BYTE#16#39, BYTE#16#37, BYTE#16#33, BYTE#16#34, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#70, BYTE#16#6F, BYTE#16#73, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#31, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#73, BYTE#16#74, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#31, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#66, BYTE#16#61, BYTE#16#69, BYTE#16#6C, BYTE#16#41, BYTE#16#72, BYTE#16#72, BYTE#16#61, BYTE#16#79, BYTE#16#22, BYTE#16#3A, BYTE#16#5B, BYTE#16#7B, BYTE#16#22, BYTE#16#66, BYTE#16#61, BYTE#16#69, BYTE#16#6C, BYTE#16#43, BYTE#16#6F, BYTE#16#64, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#43, BYTE#16#6F, BYTE#16#6E, BYTE#16#64, BYTE#16#65, BYTE#16#6E, BYTE#16#73, BYTE#16#61, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#20, BYTE#16#70, BYTE#16#6F, BYTE#16#73, BYTE#16#69, BYTE#16#74, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#63, BYTE#16#6F, BYTE#16#6D, BYTE#16#70, BYTE#16#4E, BYTE#16#61, BYTE#16#6D, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#42, BYTE#16#4F, BYTE#16#4D, BYTE#16#50, BYTE#16#4F, BYTE#16#53, BYTE#16#36, BYTE#16#30, BYTE#16#22, BYTE#16#7D, BYTE#16#5D, BYTE#16#2C, BYTE#16#22, BYTE#16#75, BYTE#16#6E, BYTE#16#69, BYTE#16#74, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#48, BYTE#16#4C, BYTE#16#46, BYTE#16#36, BYTE#16#35, BYTE#16#39, BYTE#16#37, BYTE#16#33, BYTE#16#35, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#70, BYTE#16#6F, BYTE#16#73, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#32, BYTE#16#22, BYTE#16#2C, BYTE#16#22, BYTE#16#73, BYTE#16#74, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#22, BYTE#16#3A, BYTE#16#22, BYTE#16#30, BYTE#16#22, BYTE#16#7D, BYTE#16#5D, BYTE#16#7D, BYTE#16#5D, BYTE#16#7D,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
            BYTE#16#0
];
        END_VAR
        

        {TestSetup}
        METHOD PUBLIC TestSetup 
            jsonSerializer.TimeoutTimer := timerInst;
            //Populate expected LStreamTypeElementArray
            // Populate expectedTreeOutput
            treeInput[0].types := SINT#16#0;
                treeInput[0].key := 'sessionContext';
                treeInput[0].value := 'NULL';
                treeInput[0].depth := SINT#16#0;
                treeInput[0].closingElement := FALSE;
    
                treeInput[1].types := SINT#16#02;
                treeInput[1].key := 'sessionId';
                treeInput[1].value := '154237171615905';
                treeInput[1].depth := SINT#16#01;
                treeInput[1].closingElement := FALSE;
    
                treeInput[2].types := SINT#16#02;
                treeInput[2].key := 'locale';
                treeInput[2].value := 'en_US';
                treeInput[2].depth := SINT#16#01;
                treeInput[2].closingElement := FALSE;
    
                treeInput[3].types := SINT#16#03;
                treeInput[3].key := 'persId';
                treeInput[3].value := '0';
                treeInput[3].depth := SINT#16#01;
                treeInput[3].closingElement := TRUE;
    
                treeInput[4].types := SINT#16#02;
                treeInput[4].key := 'methodName';
                treeInput[4].value := 'valeo2WC.cfWipClose';
                treeInput[4].depth := SINT#16#0;
                treeInput[4].closingElement := FALSE;
    
                treeInput[5].types := SINT#16#01; 
                treeInput[5].key := 'inArgs';
                treeInput[5].value := 'NULL';
                treeInput[5].depth := SINT#16#0;
                treeInput[5].closingElement := false;
    
                treeInput[6].types := SINT#16#02;
                treeInput[6].key := 'mode';
                treeInput[6].value := '0';
                treeInput[6].depth := SINT#16#02; 
                treeInput[6].closingElement := false;
    
                treeInput[7].types := SINT#16#02;
                treeInput[7].key := 'stationNumber';
                treeInput[7].value := 'SubRib0101';
                treeInput[7].depth := SINT#16#02;
                treeInput[7].closingElement := false;
    
                treeInput[8].types := SINT#16#02;
                treeInput[8].key := 'step';
                treeInput[8].value := '0010';
                treeInput[8].depth := SINT#16#02;
                treeInput[8].closingElement := false;
    
                treeInput[9].types := SINT#16#02;
                treeInput[9].key := 'cycleTime';
                treeInput[9].value := '253.2';
                treeInput[9].depth := SINT#16#02;
                treeInput[9].closingElement := false;
    
                treeInput[10].types := SINT#16#01;
                treeInput[10].key := 'unitArray';
                treeInput[10].value := 'NULL';
                treeInput[10].depth := SINT#16#02; 
                treeInput[10].closingElement := false;
    
                treeInput[11].types := SINT#16#02;
                treeInput[11].key := 'unit';
                treeInput[11].value := 'HLF659734';
                treeInput[11].depth := SINT#16#04;
                treeInput[11].closingElement := false;
    
                treeInput[12].types := SINT#16#02;
                treeInput[12].key := 'pos';
                treeInput[12].value := '1';
                treeInput[12].depth := SINT#16#04;
                treeInput[12].closingElement := false;
    
                treeInput[13].types := SINT#16#02;
                treeInput[13].key := 'state';
                treeInput[13].value := '1';
                treeInput[13].depth := SINT#16#04;
                treeInput[13].closingElement := false;
    
                treeInput[14].types := SINT#16#01;
                treeInput[14].key := 'failArray';
                treeInput[14].value := 'NULL';
                treeInput[14].depth := SINT#16#04;
                treeInput[14].closingElement := false;
    
                treeInput[15].types := SINT#16#02;
                treeInput[15].key := 'failCode';
                treeInput[15].value := 'Condensator position';
                treeInput[15].depth := SINT#16#06;
                treeInput[15].closingElement := false;
    
                treeInput[16].types := SINT#16#02;
                treeInput[16].key := 'compName';
                treeInput[16].value := 'BOMPOS60';
                treeInput[16].depth := SINT#16#06;
                treeInput[16].closingElement := true;
    
                treeInput[17].types := SINT#16#02;
                treeInput[17].key := 'unit';
                treeInput[17].value := 'HLF659735';
                treeInput[17].depth := SINT#16#04;
                treeInput[17].closingElement := FALSE;
    
                treeInput[18].types := SINT#16#02;
                treeInput[18].key := 'pos';
                treeInput[18].value := '2';
                treeInput[18].depth := SINT#16#04;
                treeInput[18].closingElement := FALSE;
    
                treeInput[19].types := SINT#16#02;
                treeInput[19].key := 'state';
                treeInput[19].value := '0';
                treeInput[19].depth := SINT#16#04;
                treeInput[19].closingElement := true;
        END_METHOD
        {Test}
        METHOD PUBLIC TestJsonSerializer
            VAR
                i : INT;                
            END_VAR;
            timerInst.SetTimerValue := FALSE;
            jsonSerializer.execute := TRUE;         
            WHILE (TRUE) DO
                jsonSerializer(tree := treeInput, jsonByteArray := jsonByteOutputResult);                
                IF(jsonSerializer.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(jsonSerializer.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE;
            //Test block execution 
            AxUnit.Assert.Equal(actual := jsonSerializer.count, expected := UINT#370);
            AXUnit.Assert.Equal(actual := jsonSerializer.busy, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonSerializer.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := jsonSerializer.done, expected := TRUE);
            //Test Output Content
            FOR i := 0 TO 400 DO             
                AxUnit.Assert.Equal(jsonByteOutputResult[i], expectedJsonByteOutputResult[i]);
            END_FOR;             
        END_METHOD
    END_CLASS
    
END_NAMESPACE