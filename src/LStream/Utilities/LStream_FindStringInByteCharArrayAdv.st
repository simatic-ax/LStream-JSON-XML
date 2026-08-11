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
      /// Text that is searched for
      searchFor : STRING;
      /// Start position in array   //CHANGE TO UDINT;
      startPosition : DINT;
    END_VAR
    VAR_IN_OUT
      /// Array of Char to search in
      searchIn : ARRAY[*] of BYTE;
    END_VAR
    VAR_TEMP
      /// Lower bound of given array
      tempLowerBound : DINT;
      /// Number of elements in given array
      tempNumElements : UDINT;
      /// Length of text that is searched for
      tempLenSearchFor : INT;
      /// Position in array during search (0-based)
      tempPosInArray : DINT;
      /// Position in working string during search
      tempPosInString : INT;
      /// Temporary string to work with
      tempString : STRING;
    END_VAR
    VAR CONSTANT
      /// Constant for first array dimension
      FIRST_DIM : USINT := USINT#1;
      /// Max.length of String
      MAX_LEN_STRING : UINT := UINT#254;
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
      tempPosInString := PositionOf(value := tempString, seekValue := searchFor);      //CHECK HOW TO IMPLEMENT

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

