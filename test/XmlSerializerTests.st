USING Simatic;
USING Simatic.Ax.Timer;
USING AxUnit;
USING Simatic.Ax.LStream;
USING Simatic.Ax.LStream.Utilities;
USING System.Strings;
USING Simatic.Ax.LStream.Models;


NAMESPACE LStreamTest
    ///////////////// Tests for XML Blocks
{TestFixture}
CLASS XmlSerializerTests
    VAR               
        xmlSerializer : LStream_XmlSerializer;     
        TimerInst : TimerFunctionsMock;
        treeInput : ARRAY[0..200] OF LStream_typeElement;
        actualXmlByteArrayOutput : ARRAY[0..400] OF BYTE;      
        expectedXmlByteOutputResult : ARRAY[0..400] OF BYTE := [
        BYTE#16#3C, BYTE#16#3F, BYTE#16#78, BYTE#16#6D, BYTE#16#6C, BYTE#16#20, BYTE#16#76, BYTE#16#65, BYTE#16#72, BYTE#16#73, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#3D, BYTE#16#22, BYTE#16#31, BYTE#16#2E, BYTE#16#30, BYTE#16#22, BYTE#16#20, BYTE#16#65, BYTE#16#6E, BYTE#16#63, BYTE#16#6F, BYTE#16#64, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#41, BYTE#16#53, BYTE#16#43, BYTE#16#49, BYTE#16#49, BYTE#16#22, BYTE#16#20, BYTE#16#3F, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D, BYTE#16#22, BYTE#16#46, BYTE#16#69, BYTE#16#63, BYTE#16#74, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22, BYTE#16#3C, BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D, BYTE#16#22, BYTE#16#50, BYTE#16#72, BYTE#16#6F, BYTE#16#67, BYTE#16#72, BYTE#16#61, BYTE#16#6D, BYTE#16#6D, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22, BYTE#16#3C, BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D, BYTE#16#22, BYTE#16#46, BYTE#16#61, BYTE#16#6E, BYTE#16#74, BYTE#16#61, BYTE#16#73, BYTE#16#79, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22, BYTE#16#3C, BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#65, BYTE#16#3E,
        BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0 ,BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
        BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0 ,BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0,
        BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0 ,BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0, BYTE#16#0];    
    END_VAR

    {TestSetup}
    METHOD PUBLIC TestSetup
        xmlSerializer.TimeoutTimer := TimerInst;
        //Populate tree input
        treeInput[0].types := SINT#16#0;
        treeInput[0].key := 'bookstore';
        treeInput[0].value := 'NULL';
        treeInput[0].depth := SINT#16#01;
        treeInput[0].closingElement := FALSE;

        treeInput[1].types := SINT#16#0;
        treeInput[1].key := 'book';
        treeInput[1].value := 'NULL';
        treeInput[1].depth := SINT#16#02;
        treeInput[1].closingElement := FALSE;

        treeInput[2].types := SINT#16#01;
        treeInput[2].key := 'category';
        treeInput[2].value := 'Fiction';
        treeInput[2].depth := SINT#16#02;
        treeInput[2].closingElement := FALSE;

        treeInput[3].types := SINT#16#0;
        treeInput[3].key := 'title';
        treeInput[3].value := 'The Great Gatsby';
        treeInput[3].depth := SINT#16#03;
        treeInput[3].closingElement := FALSE;

        treeInput[4].types := SINT#16#01;
        treeInput[4].key := 'lang';
        treeInput[4].value := 'en';
        treeInput[4].depth := SINT#16#03;
        treeInput[4].closingElement := FALSE;

        treeInput[5].types := SINT#16#0; 
        treeInput[5].key := 'author';
        treeInput[5].value := 'F. Scott Fitzgerald';
        treeInput[5].depth := SINT#16#03;
        treeInput[5].closingElement := false;

        treeInput[6].types := SINT#16#0;
        treeInput[6].key := 'year';
        treeInput[6].value := '1925';
        treeInput[6].depth := SINT#16#03; 
        treeInput[6].closingElement := false;

        treeInput[7].types := SINT#16#0;
        treeInput[7].key := 'price';
        treeInput[7].value := '10.99';
        treeInput[7].depth := SINT#16#03;
        treeInput[7].closingElement := false;

        treeInput[8].types := SINT#16#0;
        treeInput[8].key := 'book';
        treeInput[8].value := 'NULL';
        treeInput[8].depth := SINT#16#03;
        treeInput[8].closingElement := false;

        treeInput[9].types := SINT#16#01;
        treeInput[9].key := 'category';
        treeInput[9].value := 'Programming';
        treeInput[9].depth := SINT#16#03;
        treeInput[9].closingElement := false;

        treeInput[10].types := SINT#16#0;
        treeInput[10].key := 'title';
        treeInput[10].value := 'Learning XML';
        treeInput[10].depth := SINT#16#04; 
        treeInput[10].closingElement := false;

        treeInput[11].types := SINT#16#01;
        treeInput[11].key := 'lang';
        treeInput[11].value := 'en';
        treeInput[11].depth := SINT#16#04;
        treeInput[11].closingElement := FALSE;

        treeInput[12].types := SINT#16#0;
        treeInput[12].key := 'author';
        treeInput[12].value := 'Erik T. Ray';
        treeInput[12].depth := SINT#16#04;
        treeInput[12].closingElement := false;

        treeInput[13].types := SINT#16#0;
        treeInput[13].key := 'year';
        treeInput[13].value := '2003';
        treeInput[13].depth := SINT#16#04;
        treeInput[13].closingElement := false;

        treeInput[14].types := SINT#16#0;
        treeInput[14].key := 'price';
        treeInput[14].value := '39.95';
        treeInput[14].depth := SINT#16#04;
        treeInput[14].closingElement := false;

        treeInput[15].types := SINT#16#0;
        treeInput[15].key := 'book';
        treeInput[15].value := 'NULL';
        treeInput[15].depth := SINT#16#03;
        treeInput[15].closingElement := false;

        treeInput[16].types := SINT#16#01;
        treeInput[16].key := 'category';
        treeInput[16].value := 'Fantasy';
        treeInput[16].depth := SINT#16#03;
        treeInput[16].closingElement := FALSE;

        treeInput[17].types := SINT#16#0;
        treeInput[17].key := 'title';
        treeInput[17].value := 'Harry Potter and the Philosophers Stone';
        treeInput[17].depth := SINT#16#04;
        treeInput[17].closingElement := FALSE;

        treeInput[18].types := SINT#16#01;
        treeInput[18].key := 'lang';
        treeInput[18].value := 'en';
        treeInput[18].depth := SINT#16#04;
        treeInput[18].closingElement := FALSE;

        treeInput[19].types := SINT#16#0;
        treeInput[19].key := 'author';
        treeInput[19].value := 'J.K. Rowling';
        treeInput[19].depth := SINT#16#04;
        treeInput[19].closingElement := FALSE;

        treeInput[20].types := SINT#16#0;
        treeInput[20].key := 'year';
        treeInput[20].value := '1997';
        treeInput[20].depth := SINT#16#04;
        treeInput[20].closingElement := false;

        treeInput[21].types := SINT#16#0;
        treeInput[21].key := 'price';
        treeInput[21].value := '20.00';
        treeInput[21].depth := SINT#16#04;
        treeInput[21].closingElement := false;


    END_METHOD
       

    {Test}
    METHOD PUBLIC TestXmlSerializer
        VAR
            i : INT;
        END_VAR;
        TimerInst.SetTimerValue := FALSE;        
        xmlSerializer.execute := TRUE;      
        WHILE (i < 200) DO
            xmlSerializer(tree := treeInput, xmlByteArray := actualXmlByteArrayOutput);                
            IF(xmlSerializer.done = TRUE) THEN
                EXIT;
            END_IF;
            IF(xmlSerializer.error = TRUE) THEN
                EXIT;
            END_IF;
            i := i +1;
        END_WHILE;

        //Test Block execution
        AxUnit.Assert.Equal(actual := xmlSerializer.count, expected := UINT#360); //19
        AXUnit.Assert.Equal(actual := xmlSerializer.busy, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer.error, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer.done, expected := TRUE);

    //Test Content

    //Test Output Content
    FOR i := 0 TO 400 DO       
        AxUnit.Assert.Equal(actualXmlByteArrayOutput[i], expectedXmlByteOutputResult[i]);
    END_FOR;      

    END_METHOD

    
END_CLASS
END_NAMESPACE