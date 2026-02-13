//region BLOCK INFO HEADER
    //===============================================================================
    // SIEMENS AG / (c)Copyright 2024
    //-------------------------------------------------------------------------------
    // Title:            LStream_XmlDeserializer
    // Comment/Function: parses a XML string provided in the Raw parameter
    //                   and rebuilds the contained tree structure
    // Library/Family:   LStream
    // Author:           DI FA S SUP E&C
    // Tested with:      S7-1500 V3.1
    // Engineering:      Simatic AX
    // Restrictions:     --
    // Requirements:     LStream_FindStringInByteArrayAdv(FC), LStream_typeElement(UDT)
    //-------------------------------------------------------------------------------
    // Change log table:
    // Version  | Date       | Expert in charge | Changes applied
    //----------|------------|------------------|------------------------------------
    // 01.00.00 | 2021-03-10 | DI FA S SUP E&C  | First released version
    // 01.06.00 | 2023-04-10 | DI FA S SUP E&C  | Rework and refactoring of entire library
    // 02.00.00 | 2024-11-11 | DI FA S SUP E&C  | Migrate library to Simatic AX
    //===============================================================================

//end_region

USING Simatic.Ax.Timer;
USING System.Timer;
USING System.Strings;
USING Simatic.Ax.LStream.Utilities;
USING Simatic.Ax.LStream.Models;
NAMESPACE Simatic.Ax.LStream
    FUNCTION_BLOCK LStream_XmlDeserializer
        VAR_INPUT
            execute : BOOL;     // Rising edge starts action once
            search  : BOOL;     // TRUE: Searches rawdata for the value of the provided treekeys 
        END_VAR
        VAR_OUTPUT
            done : BOOL;        // TRUE: Commanded functionality has been completed successfully
            busy : BOOL;        // TRUE: FB is not finished and new output values can be expected
            error : BOOL;       // TRUE: An error occurred during the execution of the FB
            status : WORD := STATUS_NO_CALL;    //16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
            pointer : DINT;
            resultCount : DINT;     // Count of parsed XML elements
        END_VAR
        VAR_IN_OUT
            tree : ARRAY [*] of LStream_typeElement;    // Tree parsed information is written to, if search option active, keys must be provided
            raw : ARRAY[*] of BYTE;     // Byte array of raw xml data
        END_VAR
        VAR PUBLIC 
            TimeoutTimer : ITimerFunctions;
        END_VAR
        VAR
            statOldExecute : BOOL;      // Old value of 'execute' input for edge detection
            statDepth : SINT := SINT#-1;    // Static value of xml depth
            statError : BOOL;       // Static value of error
            statBusy : BOOL;        // Static value of busy
            statStatus : WORD := STATUS_NO_CALL;        // Static value of status
            statFBState : USINT := FB_STATE_NO_PROCESSING;      // Static value of fb state
            statDone : BOOL;        // Static value of done
            statResultCount : UINT; // Static value of result count
            statRawIndex : INT;     // Static value of raw index
            statTreeIndex : UINT;   // Static value of tree index
            statCountOfTree : INT;  // Static count of tree fields
            statCountOfRaw : INT;   // Static count of raw fields
            statIsKeyOpen : BOOL;   // TRUE: key is open, internal flag
            statIsValueOpen : BOOL; // TRUE: value is open, internal flag
            statElementOpen : UINT; // Determines the amount of open elements; if large than 0 then at least one element is still open at the current parse position
            statIsElementOpen : BOOL;   // TRUE: element is open, internal flag
            statInfoLen : UINT;     // Current  information length key or value 
            statInfoStartIndex : INT;   // Start index of current info in raw key or value
            statKeyWritten: BOOL;   // TRUE: key was written into tree
            statKey : STRING;   // Static key string
            statValue : STRING; // Static value string
            statSearch : BOOL;  // TRUE: Only keys provided in tree will be parsed
            statKeyFound : BOOL;    // TRUE: Key exisits in raw data
            statKeyNotFoundCount : UINT;    // Count of provided keys that weren't found
            statSearchIndex : DINT; // Static search index
            statOpenElements : ARRAY[0.. MAX_CONCURRENT_OPEN_ELEMENTS] of UINT; // Backtrackarray for getting the last elements open
            statAttrDelimiter : BYTE := BYTE#00;    // Delimiter for attributes
            instWatchDog : TimerFunctionsImpl;
        END_VAR
        VAR_TEMP
            tempRawIndex : INT; // Index of raw field
            tempExecute : BOOL; // Temp of input execute
            tempKeyToFind : STRING; // Provided key to which the value should be found
            tempSearchResult : DINT;    // Temp value of search result
            tempChar : BYTE;    // Temp value of a byte for searching / looping
        END_VAR
        VAR CONSTANT
            FB_STATE_NO_PROCESSING : USINT := USINT#0;  // FB state no processing, ideal state
            FB_STATE_PARSE : USINT := USINT#10; // FB state parse xml
            STATUS_EXECUTION_FINISHED : WORD := WORD#16#0000;   // NO error - execution finished without errors
            STATUS_NO_CALL : WORD := WORD#16#7000;  // No job being currently processed
            STATUS_FIRST_CALL : WORD := WORD#16#7001;   // First call after incoming new job (rising edge 'execute')
            STATUS_SUBSEQUENT_CALL : WORD := WORD#16#7002;  // Subsequent call during active processing without further details
            ERR_TREE_ARRAY_TOO_SMALL : WORD := WORD#16#8201;    // Error: provided array to too small
            ERR_EMPTY_RAW_DATA : WORD := WORD#16#8401;  // Error: no raw data provided 
            ERR_UNMATCHED_ELEMENT_CLOSE : WORD := WORD#16#8402; // Error: Encountered more closing tags than there are opening tags
            ERR_UNEXPECTED_QUOTES : WORD := WORD#16#8404;   // Error: Encountered an unexpected quotes character
            ERR_MALFORMED : WORD := WORD#16#8406;    // Error: Collection of all not further specified errors, e.g. unclosed elements before file end etc.
            ERR_UNDEFINED_STATE : WORD := WORD#16#8600; // Error: due to an undefined state in state machine
            CONTROL_CHARACTERS_UPPER : WORD := WORD#16#1F;  // ASCII code for Unit Separator which is numerically the hightest control character
            QUESTIONMARK : BYTE := BYTE#16#3F;  // ASCII code for ? indicates xml header
            EXCLAMATION : BYTE := BYTE#16#21;   // ASCII code for ! indicates comment
            DOUBLEQUOTES : BYTE := BYTE#16#22;  // ASCII code for " frames value
            QUOTES : BYTE := BYTE#16#27;    // ASCII code for ' frames value
            SMALLER : BYTE := BYTE#16#3C;   // ASCII code for < indicates a new key
            EQUALS : BYTE := BYTE#16#3D;    // ASCII code for '=' indicates key is finished follows by value
            GREATER : BYTE := BYTE#16#3E;   // ASCII code for  > indicates key can be written
            SPACE : BYTE := BYTE#16#20;     // ASCII codefor SPACE indicates key is finished
            SLASH : BYTE := BYTE#16#2F;     // ASCII code for / indicates closing
            CARRIAGE_RETURN : BYTE := BYTE#16#0D;   // ASCII code for carriage return
            LINE_FEED : BYTE := BYTE#16#0A; // ASCII code for line feed
            TAB : BYTE := BYTE#16#09;   // ASCII code for TAB
            MINUS : BYTE := BYTE#16#2D; // ASCII code for -
            EMPTY : SINT := SINT#0;     // Constant for zero value
            ELEMENT : SINT := SINT#0;   // Numerical identifier for XML type elemt
            ATTRIBUTE : SINT := SINT#1; // Numerical identifier for XML type attirbute
            FIRST_DIM : USINT := USINT#1;   // Constant for first array dimension
            MAX_LOOP_TIME : TIME := T#3ms;  // Max duration of loop, will be continued in next cycle
            INVALID_SEARCH : DINT := -1;    // Return value if Search in LParse_FindStringInCharrArrayAdv was not successfull
            KEY_NOT_FOUND : STRING := 'Key not found';  // String value in case key wasn't found
            STRING_NULL : STRING := 'NULL'; // String is default empty with string content named 'NULL'
            MAX_CONCURRENT_OPEN_ELEMENTS : UINT := UINT#150;    // Maximal number of elements that can be open at any time
            STRING_EMPTY : STRING := '';    // Empty string for resetting of fields

            
            QUESTIONMARKINT : INT := 63;
            EXCLAMATIONINT : INT := 33;
            DOUBLEQUOTESINT : INT := 34;
            QUOTESINT : INT := 39;
            SMALLERINT : INT := 60;
            EQUALSINT : INT := 61;
            GREATERINT : INT := 62;
            SPACEINT : INT := 32;
            SLASHINT : INT := 47;
            CARRIAGE_RETURNINT : INT := 13;
            LINE_FEEDINT : INT := 10;
            TABINT : INT := 9;
            MINUSINT : INT := 45;
        END_VAR
        tempExecute := execute;

        IF TimeoutTimer = NULL THEN
			TimeoutTimer := instWatchDog;
		END_IF;

    //region TRIGGERING

        IF ((tempExecute = TRUE) AND (statOldExecute = FALSE) AND (statStatus = STATUS_NO_CALL)) THEN
            
            //First call; Initialize FB
            statDone := FALSE;
            statBusy := TRUE;
            statStatus := STATUS_FIRST_CALL;

            //Initialize functionality: reset of variables, diagnostics, etc.
            statSearch := search;
            statCountOfRaw := TO_INT(UPPER_BOUND(raw, FIRST_DIM));
            statCountOfTree := TO_INT(UPPER_BOUND(tree, FIRST_DIM));
            statTreeIndex := TO_UINT(LOWER_BOUND(tree, FIRST_DIM));
            statDepth := SINT#0;
            statRawIndex := 0;
            statIsKeyOpen := FALSE;
            statIsValueOpen := FALSE;
            statIsElementOpen := FALSE;
            statElementOpen := UINT#0;
            statKeyWritten := FALSE;
            statInfoLen := UINT#0;
            statInfoStartIndex := 0;
            statKey := '';
            statValue := '';
            statKeyFound := FALSE;
            statSearchIndex := 0;
            statKeyNotFoundCount := UINT#0;
            
            // State machine - start processing
            statFBState := FB_STATE_PARSE;

            IF (NOT (statCountOfRaw > EMPTY)) THEN
                statStatus := ERR_EMPTY_RAW_DATA;
            END_IF;
            
            FOR tempRawIndex := TO_INT(statTreeIndex) TO statCountOfTree DO
                
                tree[tempRawIndex].types := SINT#-1;
                tree[tempRawIndex].depth := SINT#-1;
                tree[tempRawIndex].key := STRING_EMPTY;
                tree[tempRawIndex].value := STRING_NULL;
                
            END_FOR;
        ELSIF (statStatus = STATUS_FIRST_CALL) THEN
            statStatus := STATUS_SUBSEQUENT_CALL;
        END_IF;
        
        // Edge detection 'execute' input
        statOldExecute := tempExecute;

    //endRegion TRIGGERING
        IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
            RETURN;
        END_IF;
    //region PROGRAM LOGIC

        CASE statFBState OF
            FB_STATE_NO_PROCESSING:
                // #region NO PROCESSING
                    // No processing active (Note: this state must always be present AND left empty)
                    ;
                // #endregion NO PROCESSING
            FB_STATE_PARSE:
                // #region PARSE XML

                    //reset and start watchdog here so that for loop runs for a maximum of 5 seconds
                    TimeoutTimer.TimerFunction(signal := FALSE, duration := MAX_LOOP_TIME);
                    
                    //start watchdog
                    TimeoutTimer.TimerFunction(signal := TRUE, duration := MAX_LOOP_TIME);
                    

                    tempRawIndex := statRawIndex;

                    WHILE tempRawIndex <= statCountOfRaw DO
                        //pre check if key exist in raw data, only if search option is active and key wasn't already found
                        IF (statSearch AND statKeyFound = FALSE) THEN
                            IF (TO_DINT(statTreeIndex) < statCountOfTree) THEN              //Convert to DINT to prevent possible overflows
                                tempSearchResult := LStream_FindStringInByteCharArrayAdv(searchFor := tree[statTreeIndex].key, startPosition := statSearchIndex, searchIn := raw);
                                
                                IF tempSearchResult = INVALID_SEARCH THEN
                                    // Case key not found
                                    tree[statTreeIndex].value := KEY_NOT_FOUND;
                                    statTreeIndex := statTreeIndex + UINT#1;
                                    statKeyNotFoundCount := statKeyNotFoundCount + UINT#1;
                                ELSE
                                    // Case key found
                                    // move read pointer to last found index
                                    statSearchIndex := tempSearchResult;
                                    statKeyFound := TRUE;
                                END_IF;
                            END_IF;
                        END_IF;

                        statRawIndex := tempRawIndex;
                        // Swich case of current byte
                        CASE TO_INT(raw[tempRawIndex]) OF           //BYTE/ WORD Can not be selected as CASE selector
                            SMALLERINT: 
                                //region READ OPENING KEY SIMBOLS

                                    // There MUST be some characters after a open <
                                    // so if the array is too short the xml is malformed
                                    IF ((tempRawIndex + 1) > statCountOfRaw) THEN
                                        statStatus := ERR_MALFORMED;
                                        statDone := TRUE;
                                        EXIT;
                                    END_IF;
                                    IF statIsValueOpen
                                        AND statInfoLen > UINT#0
                                        AND tree[statOpenElements[statElementOpen]].value = STRING_NULL
                                        AND raw[statInfoStartIndex] <> SMALLER
                                    THEN
                                        //region WRITE VALUE
                                        IF statInfoLen < UINT#0 THEN
                                            statValue := STRING_EMPTY;
                                        ELSE
                                            CharsToString(chars := raw,
                                                        startPosition := statInfoStartIndex,
                                                        length:= statInfoLen,
                                                        result => statValue);
                                        END_IF;

                                        tree[statOpenElements[statElementOpen]].value := statValue;

                                        statInfoLen := UINT#0;
                                        statIsValueOpen := FALSE;

                                        //endregion WRITE VALUE
                                    END_IF;

                                    // Check if is XML Header or comment by looking ahead by one
                                    IF (raw[tempRawIndex +1] = QUESTIONMARK) OR (raw[tempRawIndex + 1] = EXCLAMATION) THEN
                                        
                                        CASE TO_INT(raw[tempRawIndex + 1]) OF                   //SAME CASE BYTE NOT ALLOWED
                                            EXCLAMATIONINT: 
                                                IF raw[tempRawIndex +2] = MINUS THEN
                                                    tempChar := MINUS;
                                                ELSE
                                                    tempChar := GREATER;
                                                END_IF;
                                            QUESTIONMARKINT:
                                                tempChar := QUESTIONMARK;
                                        END_CASE;

                                        //region IS IGNORABLE

                                            // At least two more characters have to be in the XML otherwise it is malformed
                                            // <? ?>

                                            IF tempRawIndex + 2 > statCountOfRaw THEN
                                                statStatus := ERR_MALFORMED;
                                                statDone := TRUE;
                                                EXIT;
                                            END_IF;
                                            IF tempRawIndex + 2 <= statCountOfRaw THEN
                                                tempRawIndex := tempRawIndex + 2;

                                                // Iterate until either ? or ! are found or until the end of the raw array is
                                                // reached; if the end of the array has been reached before the end of the 
                                                // header or comment then the XML must be malformed and therefore a error 
                                                // is set in the status
                                                WHILE raw[tempRawIndex] <> tempChar AND raw[tempRawIndex] <> GREATER DO
                                                    IF tempRawIndex + 1 > statCountOfRaw THEN
                                                        statStatus := ERR_MALFORMED;
                                                        statDone := TRUE;
                                                        EXIT;
                                                    END_IF;

                                                    IF raw[tempRawIndex + 1] = GREATER THEN
                                                        EXIT;
                                                    END_IF;

                                                    tempRawIndex := tempRawIndex + 1;

                                                END_WHILE; 

                                                // End of a comment, meaning that there has to be at least one more MINUS
                                                // before comment can be closed
                                                IF tempChar = MINUS THEN
                                                    
                                                    IF tempRawIndex + 1 > statCountOfRaw THEN
                                                        statStatus := ERR_MALFORMED;
                                                        statDone := TRUE;
                                                        EXIT;
                                                    END_IF;

                                                    tempRawIndex := tempRawIndex +1;
                                                END_IF;

                                                // Array ended before the comment or header could be closed which is illegal
                                                // In case the loop ran successfully we are here, which requires at least
                                                // one more character
                                                // <!-- Some Comment -->
                                                //                    ^
                                                //                    |
                                                //                    Current index

                                                IF statStatus.%X15 OR tempRawIndex + 1 > statCountOfRaw THEN
                                                    statStatus := ERR_MALFORMED;
                                                    statDone := TRUE;
                                                    EXIT;
                                                END_IF;
                                                
                                                IF raw[tempRawIndex + 1] <> GREATER THEN
                                                    statRawIndex := tempRawIndex;
                                                    statStatus := ERR_MALFORMED;
                                                    statDone := TRUE;
                                                    EXIT;
                                                END_IF;
                                                
                                                tempRawIndex := tempRawIndex +1;

                                            END_IF;

                                            statInfoLen := UINT#0;
                                            //rest length buffer
                                        //endregion IS IGNORABLE

                                        // Look ahead for closing otherwise open element 
                                    ELSIF (raw[tempRawIndex + 1] <> SLASH) THEN

                                        // Indicates opening of element
                                        //region OPENING OF ELEMENT
                                            IF (TO_DINT(statTreeIndex) > statCountOfTree + 1) THEN              //CONVERSION TO DINT 
                                                // data does not fit in the provided tree
                                                statStatus := ERR_TREE_ARRAY_TOO_SMALL;
                                                statDone := TRUE;
                                                EXIT;
                                            END_IF;

                                            IF statElementOpen + UINT#1 > MAX_CONCURRENT_OPEN_ELEMENTS THEN
                                                statStatus := ERR_MALFORMED;
                                                statDone := TRUE;
                                                pointer := tempRawIndex;
                                                EXIT;
                                            END_IF;

                                            // new element
                                            statElementOpen := statElementOpen + UINT#1; // increment the opened element count as a new element is "created" here
                                            
                                            statOpenElements[statElementOpen] := statTreeIndex;
                                            statIsValueOpen := FALSE;
                                            statDepth := statDepth + SINT#1;
                                            statInfoStartIndex := tempRawIndex + 1;
                                            statInfoLen := UINT#0;

                                            // Invalid as the xml can not stop after opening
                                            // <a>v</a><EOF
                                            //         ^
                                            //         | current

                                            IF tempRawIndex + 1 > statCountOfRaw THEN
                                                statStatus := ERR_MALFORMED;
                                                statDone := TRUE;
                                                pointer := tempRawIndex;
                                                EXIT;
                                            END_IF;

                                            tempRawIndex := tempRawIndex +1;

                                            //Region READ KEY OF NEW ELEMENT
                                                WHILE raw[tempRawIndex] <> SPACE AND raw[tempRawIndex] <> LINE_FEED
                                                    AND raw[tempRawIndex] <> CARRIAGE_RETURN
                                                    AND raw[tempRawIndex] <> TAB
                                                    AND raw[tempRawIndex] <> SMALLER
                                                    AND raw[tempRawIndex] <> BYTE#16#00
                                                    AND raw[tempRawIndex] <> GREATER
                                                    AND raw[tempRawIndex] > CONTROL_CHARACTERS_UPPER
                                                    AND raw[tempRawIndex] <> SLASH 
                                                DO
                                                    IF tempRawIndex + 1 > statCountOfRaw THEN
                                                        statStatus := ERR_MALFORMED;
                                                        statDone := TRUE;
                                                        pointer := tempRawIndex;
                                                        EXIT;
                                                    END_IF;

                                                    statInfoLen := statInfoLen + UINT#1;
                                                    tempRawIndex := tempRawIndex + 1;
                                                END_WHILE;

                                                IF statStatus.%X15 OR statInfoLen = UINT#0 THEN
                                                    statStatus := ERR_MALFORMED;
                                                    statDone := TRUE;
                                                    pointer := tempRawIndex;
                                                    EXIT;
                                                END_IF;

                                                IF (TO_DINT(statTreeIndex) > statCountOfTree) THEN
                                                    //data does not fit in the provided tree
                                                    statStatus := ERR_TREE_ARRAY_TOO_SMALL;
                                                    statDone := TRUE;
                                                    EXIT;
                                                END_IF;
                                                
                                                CharsToString(chars := raw,
                                                            startPosition := statInfoStartIndex,
                                                            length := statInfoLen,
                                                            result => statKey);
                                                IF (statSearch) THEN
                                                    //only write into tree, if key matches, otherwise continue with search for matching key
                                                    IF (statKey = tree[statTreeIndex].key) THEN
                                                        tree[statTreeIndex].depth := statDepth;
                                                        tree[statTreeIndex].types := ELEMENT;
                                                        statTreeIndex := statTreeIndex + UINT#1;
                                                        statKeyFound := FALSE;
                                                    END_IF;
                                                
                                                ELSE  // if search option isn't active (parse all) the add key to the current tree index
                                                    tree[statTreeIndex].key := statKey;
                                                    tree[statTreeIndex].types := ELEMENT;
                                                    tree[statTreeIndex].depth := statDepth;
                                                    statTreeIndex := statTreeIndex + UINT#1;
                                                    statKeyFound := FALSE;
                                                    statKeyWritten := TRUE;
                                                    statIsKeyOpen := FALSE;
                                                END_IF;
                                            //endregion READ KEY OF NEW ELEMENT

                                            statKeyWritten := FALSE;

                                            IF raw[tempRawIndex] = SLASH THEN
                                                statOpenElements[statElementOpen] := UINT#0;
                                                statElementOpen := statElementOpen - UINT#1;
                                                
                                                statIsValueOpen := FALSE;
                                                statDepth := statDepth - SINT#1;
                                                
                                                tempRawIndex := tempRawIndex +  1;
                                                
                                            ELSIF raw[tempRawIndex] = GREATER THEN
                                                statIsValueOpen := TRUE;
                                            ELSE
                                                statIsKeyOpen := TRUE;
                                            END_IF;

                                            statInfoStartIndex := tempRawIndex + 1;
                                            statInfoLen := UINT#0;
                                        //endregion OPENING OF ELEMENT
                                    ELSE
                                        statIsValueOpen := FALSE;
                                    END_IF;

                                //endregion READ OPENING KEY SIMBOLS

                            SLASHINT:
                                //region READ DELIMETER /
                                    IF statIsValueOpen THEN
                                        
                                        statInfoLen := statInfoLen + UINT#1;
                                        
                                    ELSE
                                        
                                        IF statElementOpen <= UINT#0 THEN
                                            
                                            statStatus := ERR_UNMATCHED_ELEMENT_CLOSE;
                                            statDone := TRUE;
                                            EXIT;
                                            
                                        END_IF;
                                        
                                        statDepth := statDepth - SINT#1;
                                        statInfoLen := UINT#0;
                                        IF statElementOpen >= UINT#0 THEN
                                            statOpenElements[statElementOpen] := UINT#0;
                                        END_IF;
                                        
                                        statElementOpen := statElementOpen - UINT#1;
                                        // Skip everything in the element key until the end of the key
                                        // 
                                        // </elementkey>
                                        //  ^          ^
                                        //  |          |
                                        //  current    skip position
                                        WHILE raw[tempRawIndex] <> GREATER DO
                                            
                                            IF tempRawIndex + 1 > statCountOfRaw THEN
                                                statStatus := ERR_MALFORMED;
                                                statDone := TRUE;
                                                EXIT;
                                            END_IF;
                                            
                                            tempRawIndex := tempRawIndex + 1;
                                            
                                        END_WHILE;
                                        
                                        // So that next iteration will be on the greater than > sign
                                        // </element>
                                        //         ^
                                        //         |
                                        //         Current index
                                        tempRawIndex := tempRawIndex - 1;
                                        
                                        // Array ended unexpected and is therefore malformed
                                        IF statStatus.%X15 THEN
                                            statStatus := ERR_MALFORMED;
                                            statDone := TRUE;
                                            EXIT;
                                        END_IF;
                                        
                                    END_IF;
                            //endregion READ DELIMETER /
                        
                        SPACEINT:
                            
                            IF statIsValueOpen THEN
                                    
                                statInfoLen := statInfoLen + UINT#1;
                                
                            ELSE
                                statIsKeyOpen := TRUE;
                                statInfoStartIndex := tempRawIndex + 1;
                                statInfoLen := UINT#0;
                            END_IF;
                        
                        GREATERINT:
                            //region READ WRITING KEY SYMBOLS
                            
                                IF NOT statIsValueOpen THEN
                                    statIsValueOpen := TRUE;
                                    statInfoStartIndex := tempRawIndex + 1;
                                    statInfoLen := UINT#0;
                                ELSE
                                    statInfoLen := statInfoLen + UINT#1;
                                END_IF;
                            
                            //endregion READ WRITING KEY SYMBOLS
                        
                        EQUALSINT:
                          
                            IF statIsValueOpen THEN
                                
                                statInfoLen := statInfoLen + UINT#1;
                                
                            ELSIF statIsKeyOpen THEN
                                
                                IF (TO_DINT(statTreeIndex) > statCountOfTree) THEN
                                    //data does not fit in the provided tree
                                    statStatus := ERR_TREE_ARRAY_TOO_SMALL;
                                    statDone := TRUE;
                                    EXIT;
                                END_IF;
                                
                                CharsToString(chars := raw,
                                            startPosition := statInfoStartIndex,
                                            length := statInfoLen,
                                            result => statKey);
                                
                                
                                IF (statSearch) THEN
                                    //only write into tree, if key matches, otherwise continue with search for matching key
                                    IF (statKey = tree[statTreeIndex].key) THEN
                                        tree[statTreeIndex].depth := statDepth;
                                        tree[statTreeIndex].types := ATTRIBUTE;
                                        statTreeIndex := statTreeIndex + UINT#1;
                                        statKeyFound := FALSE;
                                    END_IF;
                                    
                                ELSE// if search option isn't active (parse all) the add key to the current tree index
                                    tree[statTreeIndex].key := statKey;
                                    tree[statTreeIndex].types := ATTRIBUTE;
                                    tree[statTreeIndex].depth := statDepth;
                                    statTreeIndex := statTreeIndex + UINT#1;
                                    statKeyFound := FALSE;
                                    statKeyWritten := TRUE;
                                    
                                END_IF;
                                
                                statIsKeyOpen := FALSE;
                                statInfoStartIndex := tempRawIndex + 1;
                                statInfoLen := UINT#0;
                                
                            END_IF;
                            
                            IF NOT statIsValueOpen THEN
                                
                                IF tempRawIndex + 1 > statCountOfRaw THEN
                                    statStatus := ERR_MALFORMED;
                                    statDone := TRUE;
                                    pointer := tempRawIndex;
                                    EXIT;
                                END_IF;
                                
                                tempRawIndex := tempRawIndex + 1;
                                
                                WHILE raw[tempRawIndex] = SPACE
                                    OR raw[tempRawIndex] = LINE_FEED
                                    OR raw[tempRawIndex] = CARRIAGE_RETURN
                                    OR raw[tempRawIndex] = TAB
                                DO
                                    
                                    IF tempRawIndex + 1 > statCountOfRaw THEN
                                        statStatus := ERR_MALFORMED;
                                        statDone := TRUE;
                                        pointer := tempRawIndex;
                                        EXIT;
                                    END_IF;
                                    
                                    tempRawIndex := tempRawIndex + 1;
                                    
                                END_WHILE;
                                
                                // This is not valid, as a equals character '=' that is not within an element
                                // has to open an attribute with either ' or "
                                IF raw[tempRawIndex] <> DOUBLEQUOTES AND raw[tempRawIndex] <> QUOTES THEN
                                    
                                    statStatus := ERR_MALFORMED;
                                    statDone := TRUE;
                                    pointer := tempRawIndex;
                                    EXIT;
                                    
                                END_IF;
                                
                                statAttrDelimiter := raw[tempRawIndex];
                                
                                
                                IF tempRawIndex + 1 > statCountOfRaw THEN
                                    statStatus := ERR_MALFORMED;
                                    statDone := TRUE;
                                    pointer := tempRawIndex;
                                    EXIT;
                                END_IF;
                                
                                tempRawIndex := tempRawIndex + 1;
                                
                                statInfoLen := UINT#0;
                                statInfoStartIndex := tempRawIndex;
                                
                                WHILE raw[tempRawIndex] <> statAttrDelimiter DO
                                    
                                    IF tempRawIndex + 1 > statCountOfRaw OR raw[tempRawIndex] = SMALLER THEN
                                        statStatus := ERR_MALFORMED;
                                        statDone := TRUE;
                                        pointer := tempRawIndex;
                                        EXIT;
                                    END_IF;
                                    
                                    tempRawIndex := tempRawIndex + 1;
                                    statInfoLen := statInfoLen + UINT#1;
                                    
                                END_WHILE;
                                
                                IF statStatus.%X15 THEN
                                    EXIT;
                                END_IF;
                                
                                IF statInfoLen <= UINT#0 THEN
                                    statValue := STRING_EMPTY;
                                ELSE
                                    //attach value to last key node
                                    CharsToString(chars := raw,
                                                startPosition := statInfoStartIndex,
                                                length := statInfoLen,
                                                result => statValue);
                                END_IF;
                                
                                IF (statSearch) THEN
                                    //only write into tree, if key matches, otherwise continue with search for matching key
                                    IF (statKey = tree[statTreeIndex - UINT#1].key) THEN
                                        tree[statTreeIndex - UINT#1].depth := statDepth;
                                        tree[statTreeIndex - UINT#1].value := statValue;
                                        tree[statTreeIndex - UINT#1].types := ATTRIBUTE;
                                    END_IF;
                                ELSE
                                    // if search option isn't active (parse all) the add key to the current tree index
                                    tree[statTreeIndex - UINT#1].value := statValue;
                                    tree[statTreeIndex - UINT#1].types := ATTRIBUTE;
                                    tree[statTreeIndex - UINT#1].depth := statDepth;
                                    
                                    statIsValueOpen := false;
                                END_IF;
                                
                            END_IF;

                        QUOTESINT:
                            //region READ VALUE SYMBOLES
                                // Quotes can never occur within a key, which is always closed by a '=', '/>' or '>'
                                IF statIsKeyOpen THEN
                                    statStatus := ERR_UNEXPECTED_QUOTES;
                                    statDone := TRUE;
                                    pointer := tempRawIndex;
                                    EXIT;
                                END_IF;
                                
                                statInfoLen := statInfoLen + UINT#1;
                                
                            //endregion READ VALUE SYMBOLES     
                            
                        ELSE//all other characters  
                            //region READ OTHER SIGN
                                
                                statInfoLen := statInfoLen + UINT#1;
                                
                            //endregion READ OTHER SIGN
                        END_CASE;

                        statRawIndex := tempRawIndex;
                    
                        //quit and resume in next cycle if watchdogtimer is exceed
                        IF (TimeoutTimer.TimerFunction()) THEN
                            statRawIndex := statRawIndex + 1;
                            EXIT;
                        ELSIF tempRawIndex <= statCountOfRaw THEN
                            tempRawIndex := tempRawIndex + 1;
                        END_IF;
                    END_WHILE;

                    //if parser is through the entire raw data or end of tree array reached
                    IF (statRawIndex >= statCountOfRaw) OR (TO_DINT(statTreeIndex) > statCountOfTree) THEN
                        statStatus := STATUS_EXECUTION_FINISHED;
                        statResultCount := statTreeIndex - statKeyNotFoundCount;
                    END_IF;

                //endregion PARSE XML

            ELSE // Undefined state in state machine reached
                //region UNDEFINED STATE
                    statStatus := ERR_UNDEFINED_STATE;
                //endregion UNDEFINED STATE
        END_CASE;

    //endregion PROGRAM LOGIC

    //region OUTPUTS
    
        //Write Outputs
        IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
            //region EXECUTION FINISHED
                statDone := TRUE;
                statBusy := FALSE;
                statError := FALSE;
                // execution aborted --> set state no processing
                statFBState := FB_STATE_NO_PROCESSING;
            //endregion EXECUTION FINISHED
            
        ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
            //region ERROR OCCURED
                statDone := FALSE;
                statBusy := FALSE;
                statError := TRUE;
                // execution aborted --> set state no processing
                statFBState := FB_STATE_NO_PROCESSING;
            //endregion ERROR OCCURED
            
        ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
            //region EXECUTE RESETED
                statDone := FALSE;
                statBusy := FALSE;
                statError := FALSE;
                statStatus := STATUS_NO_CALL;
                // Reset application specific outputs
                statResultCount := UINT#0;
            //endregion EXECUTE RESETED
        END_IF;
        
        //region WRITE STATIC VALUES TO OUTPUTS
            // write application specific temp values to outputs
            resultCount := TO_INT(statResultCount);
            done := statDone;
            error := statStatus.%X15;
            status := statStatus;
            busy := statBusy;
        //endregion WRITE STATIC VALUES TO OUTPUTS
        
    //endregion OUTPUTS
    END_FUNCTION_BLOCK

END_NAMESPACE