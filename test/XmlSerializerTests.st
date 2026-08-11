USING Simatic;
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

        //Test1 (Test to try the LStream_XmlSerializer.st by serializing a tree (treeInput) and comparing its output (actualXmlByteArrayOutput) with the expected byte array (expectedXmlByteOutputResult))
        xmlSerializer : LStream_XmlSerializer;     
        treeInput : ARRAY[0..200] OF LStream_typeElement;
        actualXmlByteArrayOutput : ARRAY[0..700] OF BYTE;    
        expectedXmlByteOutputResult : ARRAY[0..507] OF BYTE := [
    BYTE#16#3C, BYTE#16#3F, BYTE#16#78, BYTE#16#6D, BYTE#16#6C, BYTE#16#20, BYTE#16#76, BYTE#16#65, BYTE#16#72, BYTE#16#73, BYTE#16#69, BYTE#16#6F,
    BYTE#16#6E, BYTE#16#3D, BYTE#16#22, BYTE#16#31, BYTE#16#2E, BYTE#16#30, BYTE#16#22, BYTE#16#20, BYTE#16#65, BYTE#16#6E, BYTE#16#63, BYTE#16#6F,
    BYTE#16#64, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#41, BYTE#16#53, BYTE#16#43, BYTE#16#49, BYTE#16#49, BYTE#16#22,
    BYTE#16#3F, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#65,
    BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67,
    BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D, BYTE#16#22, BYTE#16#46, BYTE#16#69, BYTE#16#63, BYTE#16#74, BYTE#16#69, BYTE#16#6F, BYTE#16#6E,
    BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E,
    BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22, BYTE#16#3E, BYTE#16#54, BYTE#16#68, BYTE#16#65, BYTE#16#20, BYTE#16#47,
    BYTE#16#72, BYTE#16#65, BYTE#16#61, BYTE#16#74, BYTE#16#20, BYTE#16#47, BYTE#16#61, BYTE#16#74, BYTE#16#73, BYTE#16#62, BYTE#16#79, BYTE#16#3C,
    BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68,
    BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#46, BYTE#16#2E, BYTE#16#20, BYTE#16#53, BYTE#16#63, BYTE#16#6F, BYTE#16#74, BYTE#16#74, BYTE#16#20,
    BYTE#16#46, BYTE#16#69, BYTE#16#74, BYTE#16#7A, BYTE#16#67, BYTE#16#65, BYTE#16#72, BYTE#16#61, BYTE#16#6C, BYTE#16#64, BYTE#16#3C, BYTE#16#2F,
    BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72,
    BYTE#16#3E, BYTE#16#31, BYTE#16#39, BYTE#16#32, BYTE#16#35, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E,
    BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#31, BYTE#16#30, BYTE#16#2E, BYTE#16#39, BYTE#16#39,
    BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F,
    BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74,
    BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D, BYTE#16#22, BYTE#16#50, BYTE#16#72, BYTE#16#6F, BYTE#16#67, BYTE#16#72,
    BYTE#16#61, BYTE#16#6D, BYTE#16#6D, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74,
    BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22,
    BYTE#16#3E, BYTE#16#4C, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#6E, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#20, BYTE#16#58, BYTE#16#4D,
    BYTE#16#4C, BYTE#16#3C, BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75,
    BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#45, BYTE#16#72, BYTE#16#69, BYTE#16#6B, BYTE#16#20, BYTE#16#54, BYTE#16#2E,
    BYTE#16#20, BYTE#16#52, BYTE#16#61, BYTE#16#79, BYTE#16#3C, BYTE#16#2F, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72,
    BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#32, BYTE#16#30, BYTE#16#30, BYTE#16#33, BYTE#16#3C,
    BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65,
    BYTE#16#3E, BYTE#16#33, BYTE#16#39, BYTE#16#2E, BYTE#16#39, BYTE#16#35, BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63,
    BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F,
    BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D,
    BYTE#16#22, BYTE#16#46, BYTE#16#61, BYTE#16#6E, BYTE#16#74, BYTE#16#61, BYTE#16#73, BYTE#16#79, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74,
    BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65,
    BYTE#16#6E, BYTE#16#22, BYTE#16#3E, BYTE#16#48, BYTE#16#61, BYTE#16#72, BYTE#16#72, BYTE#16#79, BYTE#16#20, BYTE#16#50, BYTE#16#6F, BYTE#16#74,
    BYTE#16#74, BYTE#16#65, BYTE#16#72, BYTE#16#20, BYTE#16#61, BYTE#16#6E, BYTE#16#64, BYTE#16#20, BYTE#16#74, BYTE#16#68, BYTE#16#65, BYTE#16#20,
    BYTE#16#50, BYTE#16#68, BYTE#16#69, BYTE#16#6C, BYTE#16#6F, BYTE#16#73, BYTE#16#6F, BYTE#16#70, BYTE#16#68, BYTE#16#65, BYTE#16#72, BYTE#16#73,
    BYTE#16#20, BYTE#16#53, BYTE#16#74, BYTE#16#6F, BYTE#16#6E, BYTE#16#65, BYTE#16#3C, BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C,
    BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#4A, BYTE#16#2E,
    BYTE#16#4B, BYTE#16#2E, BYTE#16#20, BYTE#16#52, BYTE#16#6F, BYTE#16#77, BYTE#16#6C, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#3C, BYTE#16#2F,
    BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72,
    BYTE#16#3E, BYTE#16#31, BYTE#16#39, BYTE#16#39, BYTE#16#37, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E,
    BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#32, BYTE#16#30, BYTE#16#2E, BYTE#16#30, BYTE#16#30,
    BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F,
    BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F,
    BYTE#16#72, BYTE#16#65, BYTE#16#3E, BYTE#16#0];
        

       // Test 2 (Test to try the LStream_XmlSerializer.st when the input tree (treeInput2) contains empty nodes (either 'NULL' or ''). In this example, the empty nodes are treeInput2[5] and treeInput2[7])
        xmlSerializer2 : LStream_XmlSerializer;
        treeInput2 : ARRAY[0..200] OF LStream_typeElement;
        actualXmlByteArrayOutput2 : ARRAY[0..700] OF BYTE;
        expectedXmlByteOutputResult2 : ARRAY[0..170] OF BYTE := [
    BYTE#16#3C, BYTE#16#3F, BYTE#16#78, BYTE#16#6D, BYTE#16#6C, BYTE#16#20, BYTE#16#76, BYTE#16#65, BYTE#16#72, BYTE#16#73, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#3D, BYTE#16#22, BYTE#16#31,
    BYTE#16#2E, BYTE#16#30, BYTE#16#22, BYTE#16#20, BYTE#16#65, BYTE#16#6E, BYTE#16#63, BYTE#16#6F, BYTE#16#64, BYTE#16#69, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#41, BYTE#16#53,
    BYTE#16#43, BYTE#16#49, BYTE#16#49, BYTE#16#22, BYTE#16#3F, BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#65,
    BYTE#16#3E, BYTE#16#3C, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#20, BYTE#16#63, BYTE#16#61, BYTE#16#74, BYTE#16#65, BYTE#16#67, BYTE#16#6F, BYTE#16#72, BYTE#16#79, BYTE#16#3D,
    BYTE#16#22, BYTE#16#46, BYTE#16#69, BYTE#16#63, BYTE#16#74, BYTE#16#69, BYTE#16#6F, BYTE#16#6E, BYTE#16#22, BYTE#16#3E, BYTE#16#3C, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65,
    BYTE#16#20, BYTE#16#6C, BYTE#16#61, BYTE#16#6E, BYTE#16#67, BYTE#16#3D, BYTE#16#22, BYTE#16#65, BYTE#16#6E, BYTE#16#22, BYTE#16#3E, BYTE#16#4A, BYTE#16#61, BYTE#16#77, BYTE#16#73, BYTE#16#3C,
    BYTE#16#2F, BYTE#16#74, BYTE#16#69, BYTE#16#74, BYTE#16#6C, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C,
    BYTE#16#2F, BYTE#16#61, BYTE#16#75, BYTE#16#74, BYTE#16#68, BYTE#16#6F, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#32, BYTE#16#30,
    BYTE#16#30, BYTE#16#31, BYTE#16#3C, BYTE#16#2F, BYTE#16#79, BYTE#16#65, BYTE#16#61, BYTE#16#72, BYTE#16#3E, BYTE#16#3C, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E,
    BYTE#16#3C, BYTE#16#2F, BYTE#16#70, BYTE#16#72, BYTE#16#69, BYTE#16#63, BYTE#16#65, BYTE#16#3E, BYTE#16#3C, BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#3E, BYTE#16#3C,
    BYTE#16#2F, BYTE#16#62, BYTE#16#6F, BYTE#16#6F, BYTE#16#6B, BYTE#16#73, BYTE#16#74, BYTE#16#6F, BYTE#16#72, BYTE#16#65, BYTE#16#3E];
    END_VAR

    {FixtureSetup}
    METHOD PUBLIC TestSetup
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
        treeInput[8].depth := SINT#16#02;
        treeInput[8].closingElement := false;

        treeInput[9].types := SINT#16#01;
        treeInput[9].key := 'category';
        treeInput[9].value := 'Programming';
        treeInput[9].depth := SINT#16#02;
        treeInput[9].closingElement := false;

        treeInput[10].types := SINT#16#0;
        treeInput[10].key := 'title';
        treeInput[10].value := 'Learning XML';
        treeInput[10].depth := SINT#16#03;
        treeInput[10].closingElement := false;

        treeInput[11].types := SINT#16#01;
        treeInput[11].key := 'lang';
        treeInput[11].value := 'en';
        treeInput[11].depth := SINT#16#03;
        treeInput[11].closingElement := FALSE;

        treeInput[12].types := SINT#16#0;
        treeInput[12].key := 'author';
        treeInput[12].value := 'Erik T. Ray';
        treeInput[12].depth := SINT#16#03;
        treeInput[12].closingElement := false;

        treeInput[13].types := SINT#16#0;
        treeInput[13].key := 'year';
        treeInput[13].value := '2003';
        treeInput[13].depth := SINT#16#03;
        treeInput[13].closingElement := false;

        treeInput[14].types := SINT#16#0;
        treeInput[14].key := 'price';
        treeInput[14].value := '39.95';
        treeInput[14].depth := SINT#16#03;
        treeInput[14].closingElement := false;

        treeInput[15].types := SINT#16#0;
        treeInput[15].key := 'book';
        treeInput[15].value := 'NULL';
        treeInput[15].depth := SINT#16#02;
        treeInput[15].closingElement := false;

        treeInput[16].types := SINT#16#01;
        treeInput[16].key := 'category';
        treeInput[16].value := 'Fantasy';
        treeInput[16].depth := SINT#16#02;
        treeInput[16].closingElement := FALSE;

        treeInput[17].types := SINT#16#0;
        treeInput[17].key := 'title';
        treeInput[17].value := 'Harry Potter and the Philosophers Stone';
        treeInput[17].depth := SINT#16#03;
        treeInput[17].closingElement := FALSE;

        treeInput[18].types := SINT#16#01;
        treeInput[18].key := 'lang';
        treeInput[18].value := 'en';
        treeInput[18].depth := SINT#16#03;
        treeInput[18].closingElement := FALSE;

        treeInput[19].types := SINT#16#0;
        treeInput[19].key := 'author';
        treeInput[19].value := 'J.K. Rowling';
        treeInput[19].depth := SINT#16#03;
        treeInput[19].closingElement := FALSE;

        treeInput[20].types := SINT#16#0;
        treeInput[20].key := 'year';
        treeInput[20].value := '1997';
        treeInput[20].depth := SINT#16#03;
        treeInput[20].closingElement := false;

        treeInput[21].types := SINT#16#0;
        treeInput[21].key := 'price';
        treeInput[21].value := '20.00';
        treeInput[21].depth := SINT#16#03;
        treeInput[21].closingElement := false;

        //Test2 Setup
        treeInput2[0].types := SINT#16#0;
        treeInput2[0].key := 'bookstore';
        treeInput2[0].value := 'NULL';
        treeInput2[0].depth := SINT#16#01;
        treeInput2[0].closingElement := FALSE;

        treeInput2[1].types := SINT#16#0;
        treeInput2[1].key := 'book';
        treeInput2[1].value := 'NULL';
        treeInput2[1].depth := SINT#16#02;
        treeInput2[1].closingElement := FALSE;

        treeInput2[2].types := SINT#16#01;
        treeInput2[2].key := 'category';
        treeInput2[2].value := 'Fiction';
        treeInput2[2].depth := SINT#16#02;
        treeInput2[2].closingElement := FALSE;

        treeInput2[3].types := SINT#16#0;
        treeInput2[3].key := 'title';
        treeInput2[3].value := 'Jaws';
        treeInput2[3].depth := SINT#16#03;
        treeInput2[3].closingElement := FALSE;

        treeInput2[4].types := SINT#16#01;
        treeInput2[4].key := 'lang';
        treeInput2[4].value := 'en';
        treeInput2[4].depth := SINT#16#03;
        treeInput2[4].closingElement := FALSE;

        treeInput2[5].types := SINT#16#0;
        treeInput2[5].key := 'author';
        treeInput2[5].value := 'NULL';
        treeInput2[5].depth := SINT#16#03;
        treeInput2[5].closingElement := FALSE;

        treeInput2[6].types := SINT#16#0;
        treeInput2[6].key := 'year';
        treeInput2[6].value := '2001';
        treeInput2[6].depth := SINT#16#03;
        treeInput2[6].closingElement := FALSE;

        treeInput2[7].types := SINT#16#0;
        treeInput2[7].key := 'price';
        treeInput2[7].value := '';
        treeInput2[7].depth := SINT#16#03;
        treeInput2[7].closingElement := FALSE;


    END_METHOD
       

    {Test}
    METHOD PUBLIC TestXmlSerializer
        VAR
            i : INT;
        END_VAR;       
        // Disable timeout timer for the test
        AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

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
        AxUnit.Assert.Equal(actual := xmlSerializer.count, expected := UINT#507); //19
        AXUnit.Assert.Equal(actual := xmlSerializer.busy, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer.error, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer.done, expected := TRUE);

         //Test Content

        //Test Output Content
        FOR i := 0 TO 507 DO       
            AxUnit.Assert.Equal(actualXmlByteArrayOutput[i], expectedXmlByteOutputResult[i]);
        END_FOR;      

    END_METHOD


    {Test}
    METHOD PUBLIC TestXmlSerializer_EmptyValueNodes
        VAR
            i : INT;
        END_VAR;
        // Disable timeout timer for the test
        AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

        xmlSerializer2.execute := TRUE;

        WHILE (i < 200) DO
            xmlSerializer2(tree := treeInput2, xmlByteArray := actualXmlByteArrayOutput2);
            IF(xmlSerializer2.done = TRUE) THEN
                EXIT;
            END_IF;
            IF(xmlSerializer2.error = TRUE) THEN
                EXIT;
            END_IF;
            i := i + 1;
        END_WHILE;

        //Test Block execution
        AxUnit.Assert.Equal(actual := xmlSerializer2.count, expected := UINT#171);
        AXUnit.Assert.Equal(actual := xmlSerializer2.busy, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer2.error, expected := FALSE);
        AXUnit.Assert.Equal(actual := xmlSerializer2.done, expected := TRUE);

         //Test Content

         //Test Output Content
        FOR i := 0 TO 170 DO
            AxUnit.Assert.Equal(actualXmlByteArrayOutput2[i], expectedXmlByteOutputResult2[i]);
        END_FOR;
    END_METHOD

    
END_CLASS
END_NAMESPACE
