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
    CLASS XmlDeserializerTests
        VAR        
            xmlDeserializer : LStream_XmlDeserializer;
            rawInput : ARRAY[0..10000] OF BYTE;
            actualTreeOutput : ARRAY[0..200] OF LStream_typeElement;
            expectedTreeOutput : ARRAY[0..200] OF LStream_typeElement;       
            timerInst : TimerFunctionsMock;
            rawInput1 : STRING := '<?xml version="1.0" encoding="ASCII"?><bookstore><book category="Fiction"><title lang="en">The Great Gatsby</title><author>F. Scott Fitzgerald</author><year>1925</year><price>10.99</price>';
            rawInput2 : STRING := '<book category="Programming"><title lang="en">Learning XML</title><author>Erik T. Ray</author><year>2003</year><price>39.95</price></book>';
            rawInput3 : STRING := '<book category="Fantasy"><title lang="en">Harry Potter and the Philosophers Stone</title><author>J.K. Rowling</author><year>1997</year><price>20.00</price></book></bookstore>';
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup           
            //Init timer and expected outputs 
            xmlDeserializer.TimeoutTimer := timerInst;            
            expectedTreeOutput[0].types := SINT#16#0;
            expectedTreeOutput[0].key := 'bookstore';
            expectedTreeOutput[0].value := 'NULL';
            expectedTreeOutput[0].depth := SINT#16#01;
            expectedTreeOutput[0].closingElement := FALSE;

            expectedTreeOutput[1].types := SINT#16#0;
            expectedTreeOutput[1].key := 'book';
            expectedTreeOutput[1].value := 'NULL';
            expectedTreeOutput[1].depth := SINT#16#02;
            expectedTreeOutput[1].closingElement := FALSE;

            expectedTreeOutput[2].types := SINT#16#01;
            expectedTreeOutput[2].key := 'category';
            expectedTreeOutput[2].value := 'Fiction';
            expectedTreeOutput[2].depth := SINT#16#02;
            expectedTreeOutput[2].closingElement := FALSE;

            expectedTreeOutput[3].types := SINT#16#0;
            expectedTreeOutput[3].key := 'title';
            expectedTreeOutput[3].value := 'The Great Gatsby';
            expectedTreeOutput[3].depth := SINT#16#03;
            expectedTreeOutput[3].closingElement := FALSE;

            expectedTreeOutput[4].types := SINT#16#01;
            expectedTreeOutput[4].key := 'lang';
            expectedTreeOutput[4].value := 'en';
            expectedTreeOutput[4].depth := SINT#16#03;
            expectedTreeOutput[4].closingElement := FALSE;

            expectedTreeOutput[5].types := SINT#16#0; 
            expectedTreeOutput[5].key := 'author';
            expectedTreeOutput[5].value := 'F. Scott Fitzgerald';
            expectedTreeOutput[5].depth := SINT#16#03;
            expectedTreeOutput[5].closingElement := false;

            expectedTreeOutput[6].types := SINT#16#0;
            expectedTreeOutput[6].key := 'year';
            expectedTreeOutput[6].value := '1925';
            expectedTreeOutput[6].depth := SINT#16#03; 
            expectedTreeOutput[6].closingElement := false;

            expectedTreeOutput[7].types := SINT#16#0;
            expectedTreeOutput[7].key := 'price';
            expectedTreeOutput[7].value := '10.99';
            expectedTreeOutput[7].depth := SINT#16#03;
            expectedTreeOutput[7].closingElement := false;

            expectedTreeOutput[8].types := SINT#16#0;
            expectedTreeOutput[8].key := 'book';
            expectedTreeOutput[8].value := 'NULL';
            expectedTreeOutput[8].depth := SINT#16#03;
            expectedTreeOutput[8].closingElement := false;

            expectedTreeOutput[9].types := SINT#16#01;
            expectedTreeOutput[9].key := 'category';
            expectedTreeOutput[9].value := 'Programming';
            expectedTreeOutput[9].depth := SINT#16#03;
            expectedTreeOutput[9].closingElement := false;

            expectedTreeOutput[10].types := SINT#16#0;
            expectedTreeOutput[10].key := 'title';
            expectedTreeOutput[10].value := 'Learning XML';
            expectedTreeOutput[10].depth := SINT#16#04; 
            expectedTreeOutput[10].closingElement := false;

            expectedTreeOutput[11].types := SINT#16#01;
            expectedTreeOutput[11].key := 'lang';
            expectedTreeOutput[11].value := 'en';
            expectedTreeOutput[11].depth := SINT#16#04;
            expectedTreeOutput[11].closingElement := FALSE;

            expectedTreeOutput[12].types := SINT#16#0;
            expectedTreeOutput[12].key := 'author';
            expectedTreeOutput[12].value := 'Erik T. Ray';
            expectedTreeOutput[12].depth := SINT#16#04;
            expectedTreeOutput[12].closingElement := false;

            expectedTreeOutput[13].types := SINT#16#0;
            expectedTreeOutput[13].key := 'year';
            expectedTreeOutput[13].value := '2003';
            expectedTreeOutput[13].depth := SINT#16#04;
            expectedTreeOutput[13].closingElement := false;

            expectedTreeOutput[14].types := SINT#16#0;
            expectedTreeOutput[14].key := 'price';
            expectedTreeOutput[14].value := '39.95';
            expectedTreeOutput[14].depth := SINT#16#04;
            expectedTreeOutput[14].closingElement := false;

            expectedTreeOutput[15].types := SINT#16#0;
            expectedTreeOutput[15].key := 'book';
            expectedTreeOutput[15].value := 'NULL';
            expectedTreeOutput[15].depth := SINT#16#03;
            expectedTreeOutput[15].closingElement := false;

            expectedTreeOutput[16].types := SINT#16#01;
            expectedTreeOutput[16].key := 'category';
            expectedTreeOutput[16].value := 'Fantasy';
            expectedTreeOutput[16].depth := SINT#16#03;
            expectedTreeOutput[16].closingElement := FALSE;

            expectedTreeOutput[17].types := SINT#16#0;
            expectedTreeOutput[17].key := 'title';
            expectedTreeOutput[17].value := 'Harry Potter and the Philosophers Stone';
            expectedTreeOutput[17].depth := SINT#16#04;
            expectedTreeOutput[17].closingElement := FALSE;

            expectedTreeOutput[18].types := SINT#16#01;
            expectedTreeOutput[18].key := 'lang';
            expectedTreeOutput[18].value := 'en';
            expectedTreeOutput[18].depth := SINT#16#04;
            expectedTreeOutput[18].closingElement := FALSE;

            expectedTreeOutput[19].types := SINT#16#0;
            expectedTreeOutput[19].key := 'author';
            expectedTreeOutput[19].value := 'J.K. Rowling';
            expectedTreeOutput[19].depth := SINT#16#04;
            expectedTreeOutput[19].closingElement := FALSE;

            expectedTreeOutput[20].types := SINT#16#0;
            expectedTreeOutput[20].key := 'year';
            expectedTreeOutput[20].value := '1997';
            expectedTreeOutput[20].depth := SINT#16#04;
            expectedTreeOutput[20].closingElement := false;

            expectedTreeOutput[21].types := SINT#16#0;
            expectedTreeOutput[21].key := 'price';
            expectedTreeOutput[21].value := '20.00';
            expectedTreeOutput[21].depth := SINT#16#04;
            expectedTreeOutput[21].closingElement := false;
        END_METHOD
            
        {Test}
        METHOD PUBLIC TestXmlDeserializer
            VAR
                i : INT;
            END_VAR;
            timerInst.SetTimerValue := FALSE;
            xmlDeserializer.search := FALSE;
            xmlDeserializer.execute := TRUE;        
            StringToByteArray(string1 := rawInput1, string2 := rawInput2, string3 := rawInput3, byteArray := rawInput);
            WHILE (TRUE) DO
                xmlDeserializer(raw := rawInput, tree := actualTreeOutput);
                // Copy data from the fixed-size byte array to jsonDeserializer.raw
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
            //Test Blopck Content
            Assert.LStreamTypeElementEqual(actualTreeOutput,expectedTreeOutput);    
        END_METHOD    
    END_CLASS
END_NAMESPACE