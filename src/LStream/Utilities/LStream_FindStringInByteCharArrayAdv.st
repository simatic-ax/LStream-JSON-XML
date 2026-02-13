//REGION BLOCK INFO HEADER
//===============================================================================
  // SIEMENS AG / (c)Copyright 2021
  //-------------------------------------------------------------------------------
  // Title:            LStream_FindStringInByteCharArrayAdv
  // Comment/Function: Searches for a specified string within an array of char
  // Library/Family:   LStream
  // Author:           DI FA S SUP E&C
  // Tested with:      S7-1500 V2.8
  // Engineering:      TIA Portal V16
  // Restrictions:     --
  // Requirements:     --
  //-------------------------------------------------------------------------------
  // Change log table:
  // Version  | Date       | Expert in charge | Changes applied
  //----------|------------|------------------|------------------------------------
  // 01.00.00 | 2021-03-10 |DI FA S SUP E&C   | First released version
  //===============================================================================

//END_REGION 

USING System.Strings;
USING System.Math;
NAMESPACE Simatic.Ax.LStream.Utilities
  FUNCTION LStream_FindStringInByteCharArrayAdv : DINT  //Returns the index of found string
    VAR_INPUT
      searchFor : STRING;   // Text that is searched for
      startPosition : DINT; // Start position in array   //CHANGE TO UDINT;
    END_VAR
    VAR_IN_OUT
      searchIn : ARRAY[*] of BYTE;  // Array of Char to search in
    END_VAR
    VAR_TEMP
      tempLowerBound : DINT;   // Lower bound of given array
      tempNumElements : UDINT; // Number of elements in given array 
      tempLenSearchFor : INT;  // Length of text that is searched for
      tempPosInArray : DINT;   // Position in array during search (0-based)          
      tempPosInString : INT;   // Position in working string during search
      tempString : STRING;     // Temporary string to work with
    END_VAR
    VAR CONSTANT
      FIRST_DIM : USINT := USINT#1;      // Constant for first array dimension
      MAX_LEN_STRING : UINT := UINT#254; // Max.length of String
    END_VAR

    // Initialization
    tempPosInString := 0;
    tempPosInArray := startPosition; 
    tempLenSearchFor := LengthOf(value := searchFor);
    LStream_FindStringInByteCharArrayAdv := -1;
    
    // Get number of elements
    
    tempLowerBound := LOWER_BOUND(searchIn, FIRST_DIM);
    tempNumElements := TO_UDINT(UPPER_BOUND(searchIn,FIRST_DIM) - tempLowerBound + 1);

    IF (TO_LINT(tempPosInArray) > tempNumElements) THEN      //Convert to LINT to ensure that if i convert to UINT is not out of range 
      RETURN;
    END_IF;

    // Search for beginning of text until something was found and
    // as long as the index is less than the array size / number of elements in array
    WHILE ((tempPosInString <= 0) AND (TO_UDINT(tempPosInArray) < tempNumElements)) DO
      // Convert Chars to String
      CharsToString(chars := searchIn,
                    startPosition := tempPosInArray,
                    length:= TO_UINT(Min(MAX_LEN_STRING, tempNumElements)),
                    result => tempString);

      // Search for text at beginning
      tempPosInString := PositionOf(value := tempString, seekValue := searchFor);      //CHECH HOW TO IMPLEMENT

      // Keyword was found
      IF tempPosInString > 0 THEN
        // Output position of string
        LStream_findStringInByteCharArrayAdv := tempLowerBound + tempPosInArray + tempPosInString -1;
        EXIT;
      ELSE
        // Otherwise continue search in next string minus length of text at beginning to ensure
        // keywords are not broken up at the end of a string and thus missed
        tempPosInArray := tempPosInArray + TO_INT(MAX_LEN_STRING) - tempLenSearchFor;
      END_IF;
    END_WHILE;
    
  END_FUNCTION
END_NAMESPACE

