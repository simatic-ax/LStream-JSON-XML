USING System.Strings;
USING System.Serialization;
NAMESPACE Simatic.Ax.LStream.Utilities
    FUNCTION LStream_WriteOutString : INT  //Offset after the data has been written; -1 if there would have been an overflow
        VAR_INPUT
            offset : UINT;   // Position in the array to start writing
        END_VAR
        VAR_IN_OUT
            toWrite : STRING;   // The string that has to be written to the byte array
            xmlByteArray : ARRAY[*] of BYTE;  // The byte representation of the XML to write into
        END_VAR
        VAR_TEMP
            tempXmlUpperBound : DINT;   // The upper bound index of the XML Array
            tempCountWritten : UDINT; // Amount of characters written to the char array 
            tempOffsetArray : ARRAY[0..255] of BYTE;  
            Index : INT;
        END_VAR
        VAR CONSTANT
            RETURN_OUT_OF_BOUNDS : INT := -1;      // Return value, if the write would be out of bounds, no write happens
            MAX_LEN_STRING : UINT := UINT#254; // Max.length of String
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
		//WRITE INTO OUTPUT ARRAY WITH AN OFFSET TO AVOID WRITTING STRING SIZE - USE SIZE IN FIRST BYTE FOR LIMIT NUMBER OF ITERATIONS
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