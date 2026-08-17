USING System.Strings;
USING System.Serialization;
NAMESPACE Simatic.Ax.LStream.Utilities
    FUNCTION LStream_WriteOutString : INT  //Offset after the data has been written; -1 if there would have been an overflow
        VAR_INPUT
            /// Position in the array to start writing
            offset : UINT;
        END_VAR
        VAR_IN_OUT
            /// The string that has to be written to the byte array
            toWrite : STRING;
            /// The byte representation of the XML to write into
            xmlByteArray : ARRAY[*] of BYTE;
        END_VAR
        VAR_TEMP
            /// The upper bound index of the XML Array
            tempXmlUpperBound : DINT;
            /// Amount of characters written to the char array
            tempCountWritten : UDINT;
            tempOffsetArray : ARRAY[0..255] of BYTE;  
            Index : INT;
        END_VAR
        VAR CONSTANT
            /// Return value, if the write would be out of bounds, no write happens
            RETURN_OUT_OF_BOUNDS : INT := -1;
            /// Max.length of String
            MAX_LEN_STRING : UINT := UINT#254;
        END_VAR
        
        tempXmlUpperBound := UPPER_BOUND(xmlByteArray, 1);

        LStream_WriteOutString := RETURN_OUT_OF_BOUNDS;

        IF ((TO_UINT(LengthOf(toWrite)) + offset) > tempXmlUpperBound) THEN
            RETURN;
        END_IF;

        //add information to xml byte array
        
        // //SERIALIZE
        // tempCountWritten := Serialize(offset := offset, value := toWrite, buffer :=  xmlByteArray); //error due to serialize writing size in output byte array

        // //fixed serialize
        tempCountWritten := Serialize(offset := UDINT#0, value := toWrite, buffer := tempOffsetArray); //NOT WORKING BECAUSE STRING SIZE IS WRITTEN IN FIRST POSITION OF OUTPUT ARRAY
        //WRITE INTO OUTPUT ARRAY WITH AN OFFSET TO AVOID WRITING STRING SIZE - USE SIZE IN FIRST BYTE FOR LIMIT NUMBER OF ITERATIONS
        FOR Index := 0 TO TO_INT(tempOffsetArray[0]) - 1 DO                
            xmlByteArray[TO_INT(offset) + Index] := tempOffsetArray[Index + 1];    
        END_FOR;


        /*Strg_TO_Chars(Strg := toWrite,
                    pChars := offset,
                    Cnt => tempCountWritten,
                    Chars := xmlByteArray);
        */
        //move index of byte array 
        LStream_WriteOutString := LStream_WriteOutString + TO_INT(tempCountWritten) - 1;

      
    END_FUNCTION
  END_NAMESPACE