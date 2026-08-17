USING Simatic;
USING AxUnit;
USING Simatic.Ax.LStream;
USING Simatic.Ax.LStream.Utilities;
USING System.Strings;
USING Simatic.Ax.LStream.Models;


NAMESPACE LStreamTest
    ///////////////// Tests for XML Blocks
    {TestFixture}
    CLASS XmlDeserializerTests
        VAR        
            //Test1 (Test to try the LStream_XmlDeserializer.st by deserializing XML (rawInput1, rawInput2, rawInput3) and comparing its output with the expected tree (expectedTreeOutput1))
            xmlDeserializer : LStream_XmlDeserializer;
            rawInput : ARRAY[0..10000] OF BYTE;
            actualTreeOutput : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput1 : ARRAY[0..200] OF LStream_typeElement;       

            rawInput1 : STRING := '<?xml version="1.0" encoding="ASCII"?><bookstore><book category="Fiction"><title lang="en">The Great Gatsby</title><author>F. Scott Fitzgerald</author><year>1925</year>';
            rawInput2 : STRING := '<price>10.99</price></book><book category="Programming"><title lang="en">Learning XML</title><author>Erik T. Ray</author><year>2003</year><price>39.95</price></book>';
            rawInput3 : STRING := '<book category="Fantasy"><title lang="en">Harry Potter and the Philosophers Stone</title><author>J.K. Rowling</author><year>1997</year><price>20.00</price></book></bookstore>';

            //Test2 (Test to try the LStream_XmlDeserializer.st when the input XML has spaces before the equals sign in attributes (category = "Science Fiction" or lang   ="en"). 
            //The deserialize output tree is compared with the expected tree (expectedTreeOutput2))
            xmlDeserializer2 : LStream_XmlDeserializer;
            rawInput4 : STRING := '<bookstore><book category = "Science Fiction" lang   ="en"><title>The Great Gatsby</title><author>F. Scott Fitzgerald</author><year>1925</year><price>10.99</price></book></bookstore>';
            rawInput_2 : ARRAY[0..10000] OF BYTE;
            actualTreeOutput2 : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput2 : ARRAY[0..200] OF LStream_typeElement;

        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup        
            // Disable timeout timer for all tests
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));   
            //Init timer and expected outputs            
            expectedTreeOutput1[0].types := SINT#16#0;
            expectedTreeOutput1[0].key := 'bookstore';
            expectedTreeOutput1[0].value := 'NULL';
            expectedTreeOutput1[0].depth := SINT#16#01;
            expectedTreeOutput1[0].closingElement := FALSE;

            expectedTreeOutput1[1].types := SINT#16#0;
            expectedTreeOutput1[1].key := 'book';
            expectedTreeOutput1[1].value := 'NULL';
            expectedTreeOutput1[1].depth := SINT#16#02;
            expectedTreeOutput1[1].closingElement := FALSE;

            expectedTreeOutput1[2].types := SINT#16#01;
            expectedTreeOutput1[2].key := 'category';
            expectedTreeOutput1[2].value := 'Fiction';
            expectedTreeOutput1[2].depth := SINT#16#02;
            expectedTreeOutput1[2].closingElement := FALSE;

            expectedTreeOutput1[3].types := SINT#16#0;
            expectedTreeOutput1[3].key := 'title';
            expectedTreeOutput1[3].value := 'The Great Gatsby';
            expectedTreeOutput1[3].depth := SINT#16#03;
            expectedTreeOutput1[3].closingElement := FALSE;

            expectedTreeOutput1[4].types := SINT#16#01;
            expectedTreeOutput1[4].key := 'lang';
            expectedTreeOutput1[4].value := 'en';
            expectedTreeOutput1[4].depth := SINT#16#03;
            expectedTreeOutput1[4].closingElement := FALSE;

            expectedTreeOutput1[5].types := SINT#16#0; 
            expectedTreeOutput1[5].key := 'author';
            expectedTreeOutput1[5].value := 'F. Scott Fitzgerald';
            expectedTreeOutput1[5].depth := SINT#16#03;
            expectedTreeOutput1[5].closingElement := false;

            expectedTreeOutput1[6].types := SINT#16#0;
            expectedTreeOutput1[6].key := 'year';
            expectedTreeOutput1[6].value := '1925';
            expectedTreeOutput1[6].depth := SINT#16#03; 
            expectedTreeOutput1[6].closingElement := false;

            expectedTreeOutput1[7].types := SINT#16#0;
            expectedTreeOutput1[7].key := 'price';
            expectedTreeOutput1[7].value := '10.99';
            expectedTreeOutput1[7].depth := SINT#16#03;
            expectedTreeOutput1[7].closingElement := false;

            expectedTreeOutput1[8].types := SINT#16#0;
            expectedTreeOutput1[8].key := 'book';
            expectedTreeOutput1[8].value := 'NULL';
            expectedTreeOutput1[8].depth := SINT#16#02;
            expectedTreeOutput1[8].closingElement := false;

            expectedTreeOutput1[9].types := SINT#16#01;
            expectedTreeOutput1[9].key := 'category';
            expectedTreeOutput1[9].value := 'Programming';
            expectedTreeOutput1[9].depth := SINT#16#02;
            expectedTreeOutput1[9].closingElement := false;

            expectedTreeOutput1[10].types := SINT#16#0;
            expectedTreeOutput1[10].key := 'title';
            expectedTreeOutput1[10].value := 'Learning XML'; 
            expectedTreeOutput1[10].depth := SINT#16#03;
            expectedTreeOutput1[10].closingElement := false;

            expectedTreeOutput1[11].types := SINT#16#01;
            expectedTreeOutput1[11].key := 'lang';
            expectedTreeOutput1[11].value := 'en';
            expectedTreeOutput1[11].depth := SINT#16#03;
            expectedTreeOutput1[11].closingElement := FALSE;

            expectedTreeOutput1[12].types := SINT#16#0;
            expectedTreeOutput1[12].key := 'author';
            expectedTreeOutput1[12].value := 'Erik T. Ray';
            expectedTreeOutput1[12].depth := SINT#16#03;
            expectedTreeOutput1[12].closingElement := false;

            expectedTreeOutput1[13].types := SINT#16#0;
            expectedTreeOutput1[13].key := 'year';
            expectedTreeOutput1[13].value := '2003';
            expectedTreeOutput1[13].depth := SINT#16#03;
            expectedTreeOutput1[13].closingElement := false;

            expectedTreeOutput1[14].types := SINT#16#0;
            expectedTreeOutput1[14].key := 'price';
            expectedTreeOutput1[14].value := '39.95';
            expectedTreeOutput1[14].depth := SINT#16#03;
            expectedTreeOutput1[14].closingElement := false;

            expectedTreeOutput1[15].types := SINT#16#0;
            expectedTreeOutput1[15].key := 'book';
            expectedTreeOutput1[15].value := 'NULL';
            expectedTreeOutput1[15].depth := SINT#16#02;
            expectedTreeOutput1[15].closingElement := false;

            expectedTreeOutput1[16].types := SINT#16#01;
            expectedTreeOutput1[16].key := 'category';
            expectedTreeOutput1[16].value := 'Fantasy';
            expectedTreeOutput1[16].depth := SINT#16#02;
            expectedTreeOutput1[16].closingElement := FALSE;

            expectedTreeOutput1[17].types := SINT#16#0;
            expectedTreeOutput1[17].key := 'title';
            expectedTreeOutput1[17].value := 'Harry Potter and the Philosophers Stone';
            expectedTreeOutput1[17].depth := SINT#16#03;
            expectedTreeOutput1[17].closingElement := FALSE;

            expectedTreeOutput1[18].types := SINT#16#01;
            expectedTreeOutput1[18].key := 'lang';
            expectedTreeOutput1[18].value := 'en';
            expectedTreeOutput1[18].depth := SINT#16#03;
            expectedTreeOutput1[18].closingElement := FALSE;

            expectedTreeOutput1[19].types := SINT#16#0;
            expectedTreeOutput1[19].key := 'author';
            expectedTreeOutput1[19].value := 'J.K. Rowling';
            expectedTreeOutput1[19].depth := SINT#16#03;
            expectedTreeOutput1[19].closingElement := FALSE;

            expectedTreeOutput1[20].types := SINT#16#0;
            expectedTreeOutput1[20].key := 'year';
            expectedTreeOutput1[20].value := '1997';
            expectedTreeOutput1[20].depth := SINT#16#03;
            expectedTreeOutput1[20].closingElement := false;

            expectedTreeOutput1[21].types := SINT#16#0;
            expectedTreeOutput1[21].key := 'price';
            expectedTreeOutput1[21].value := '20.00';
            expectedTreeOutput1[21].depth := SINT#16#03;
            expectedTreeOutput1[21].closingElement := false;

            //Test2 Setup

            expectedTreeOutput2[0].types := SINT#16#0;
            expectedTreeOutput2[0].key := 'bookstore';
            expectedTreeOutput2[0].value := 'NULL';
            expectedTreeOutput2[0].depth := SINT#16#01;
            expectedTreeOutput2[0].closingElement := FALSE;

            expectedTreeOutput2[1].types := SINT#16#0;
            expectedTreeOutput2[1].key := 'book';
            expectedTreeOutput2[1].value := 'NULL';
            expectedTreeOutput2[1].depth := SINT#16#02;
            expectedTreeOutput2[1].closingElement := FALSE;

            expectedTreeOutput2[2].types := SINT#16#01;
            expectedTreeOutput2[2].key := 'category';
            expectedTreeOutput2[2].value := 'Science Fiction';
            expectedTreeOutput2[2].depth := SINT#16#02;
            expectedTreeOutput2[2].closingElement := FALSE;

            expectedTreeOutput2[3].types := SINT#16#01;
            expectedTreeOutput2[3].key := 'lang';
            expectedTreeOutput2[3].value := 'en';
            expectedTreeOutput2[3].depth := SINT#16#02;
            expectedTreeOutput2[3].closingElement := FALSE;

            expectedTreeOutput2[4].types := SINT#16#0;
            expectedTreeOutput2[4].key := 'title';
            expectedTreeOutput2[4].value := 'The Great Gatsby';
            expectedTreeOutput2[4].depth := SINT#16#03;
            expectedTreeOutput2[4].closingElement := FALSE;

            expectedTreeOutput2[5].types := SINT#16#0;
            expectedTreeOutput2[5].key := 'author';
            expectedTreeOutput2[5].value := 'F. Scott Fitzgerald';
            expectedTreeOutput2[5].depth := SINT#16#03;
            expectedTreeOutput2[5].closingElement := FALSE;

            expectedTreeOutput2[6].types := SINT#16#0;
            expectedTreeOutput2[6].key := 'year';
            expectedTreeOutput2[6].value := '1925';
            expectedTreeOutput2[6].depth := SINT#16#03;
            expectedTreeOutput2[6].closingElement := FALSE;

            expectedTreeOutput2[7].types := SINT#16#0;
            expectedTreeOutput2[7].key := 'price';
            expectedTreeOutput2[7].value := '10.99';
            expectedTreeOutput2[7].depth := SINT#16#03;
            expectedTreeOutput2[7].closingElement := FALSE;
        END_METHOD
            
        //Test1
        {Test}
        METHOD PUBLIC TestXmlDeserializer
            VAR
                i : INT;
            END_VAR;
            // Disable timeout timer for the test
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));

            xmlDeserializer.search := FALSE;
            xmlDeserializer.execute := TRUE;        
            StringToByteArray(string1 := rawInput1, string2 := rawInput2, string3 := rawInput3, byteArray := rawInput);
            WHILE (TRUE) DO
                xmlDeserializer(raw := rawInput, tree := actualTreeOutput);
                // Copy data from the fixed-size byte array to xmlDeserializer.raw
                IF(xmlDeserializer.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF(xmlDeserializer.error = TRUE) THEN
                    EXIT;
                END_IF;          
            END_WHILE;
            //Test Block execution
            AxUnit.Assert.Equal(actual := xmlDeserializer.resultCount, expected := 22); //19
            AXUnit.Assert.Equal(actual := xmlDeserializer.busy, expected := FALSE);
            AXUnit.Assert.Equal(actual := xmlDeserializer.error, expected := FALSE);
            AXUnit.Assert.Equal(actual := xmlDeserializer.done, expected := TRUE);
            //Test Block Content
            Assert.LStreamTypeElementEqual(actualTreeOutput,expectedTreeOutput1);    
        END_METHOD

        //Test2
        {Test}
        METHOD PUBLIC TestXmlDeserializer_Empty_Spaces
            // Disable timeout timer for the test
            AxUnit.Mocking.Mock(mockeeFn := NAME_OF(System.Timer.OnDelay), mockFn := NAME_OF(Simatic.Ax.Mocks.OnDelayMock_false));
            
            xmlDeserializer2.search := FALSE;
            xmlDeserializer2.execute := TRUE;

            StringToByteArray(string1 := rawInput4, byteArray := rawInput_2);

            WHILE (TRUE) DO
                xmlDeserializer2(raw := rawInput_2, tree := actualTreeOutput2);
                IF (xmlDeserializer2.done = TRUE) THEN
                    EXIT;
                END_IF;
                IF (xmlDeserializer2.error = TRUE) THEN
                    EXIT;
                END_IF;
            END_WHILE;

            AxUnit.Assert.Equal(actual := xmlDeserializer2.resultCount, expected := 8);
            AxUnit.Assert.Equal(actual := xmlDeserializer2.busy, expected := FALSE);
            AxUnit.Assert.Equal(actual := xmlDeserializer2.error, expected := FALSE);
            AxUnit.Assert.Equal(actual := xmlDeserializer2.done, expected := TRUE);
            Assert.LStreamTypeElementEqual(actualTreeOutput2, expectedTreeOutput2);
        END_METHOD    
    END_CLASS
END_NAMESPACE