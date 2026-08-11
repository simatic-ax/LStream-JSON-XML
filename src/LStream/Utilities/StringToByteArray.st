
USING System.Strings;
NAMESPACE Simatic.Ax.LStream.Utilities
    FUNCTION StringToByteArray : BOOL
        VAR_INPUT
            string1 : STRING;
            /// Optional
            string2 : STRING := '';
            /// Optional
            string3 : STRING := '';
            /// Optional
            string4 : STRING := '';
        END_VAR
        
        VAR_IN_OUT
            /// Ensure this array is large enough to hold all bytes
            byteArray : ARRAY[0..10000] OF BYTE;
        END_VAR
        
        VAR
            totalLength : INT := 0;
            stringLength : INT;
            byteIndex : INT := 0;
            SizeOfByteArray : DINT := 10000;
            i : INT;
        END_VAR
        
        // Process string1
        IF string1 <> '' THEN
            stringLength := LengthOf(string1);
            IF (totalLength + stringLength) > SizeOfByteArray THEN
                StringToByteArray := FALSE; // Not enough space in the byte array
                RETURN;
            END_IF;

            FOR i := 1 TO stringLength DO
                byteArray[byteIndex] := TO_BYTE(TO_USINT(string1[i]));
                byteIndex := byteIndex + 1;
            END_FOR;
            totalLength := totalLength + stringLength;
        END_IF;

        // Process string2
        IF string2 <> '' THEN
            stringLength := LengthOf(string2);
            IF (totalLength + stringLength) > SizeOfByteArray THEN
                StringToByteArray := FALSE; // Not enough space in the byte array
                RETURN;
            END_IF;

            FOR i := 1 TO stringLength DO
                byteArray[byteIndex] := TO_BYTE(TO_USINT(string2[i]));
                byteIndex := byteIndex + 1;
            END_FOR;
            totalLength := totalLength + stringLength;
        END_IF;

        // Process string3
        IF string3 <> '' THEN
            stringLength := LengthOf(string3);
            IF (totalLength + stringLength) > SizeOfByteArray THEN
                StringToByteArray := FALSE; // Not enough space in the byte array
                RETURN;
            END_IF;

            FOR i := 1 TO stringLength DO
                byteArray[byteIndex] := TO_BYTE(TO_USINT(string3[i]));
                byteIndex := byteIndex + 1;
            END_FOR;
            totalLength := totalLength + stringLength;
        END_IF;

        // Process string4
        IF string4 <> '' THEN
            stringLength := LengthOf(string4);
            IF (totalLength + stringLength) > SizeOfByteArray THEN
                StringToByteArray := FALSE; // Not enough space in the byte array
                RETURN;
            END_IF;

            FOR i := 1 TO stringLength DO
                byteArray[byteIndex] := TO_BYTE(TO_USINT(string4[i]));
                byteIndex := byteIndex + 1;
            END_FOR;
            totalLength := totalLength + stringLength;
        END_IF;

        // If all strings were successfully processed
        StringToByteArray := TRUE;
        RETURN;
    END_FUNCTION
    
END_NAMESPACE
