//region BLOCK INFO HEADER
    //===============================================================================
    // SIEMENS AG / (c)Copyright 2024
    //-------------------------------------------------------------------------------
    // Title:            LStream_XmlSerializer
    // Comment/Function: FB converts prefilled array of udt LParse_typeElement to a xml structure.
    //                   XML structure is returned as a Byte array
    // Library/Family:   LStream
    // Author:           DI FA S SUP E&C
    // Tested with:      S7-1500 V3.1
    // Engineering:      Simatic AX
    // Restrictions:     --
    // Requirements:     LStream_WriteOutString(FC), LStream_typeElement(UDT)
    //-------------------------------------------------------------------------------
    // Change log table:
    // Version  | Date       | Expert in charge | Changes applied
    //----------|------------|------------------|------------------------------------
    // 01.00.00 | 2021-03-10 | DI FA S SUP E&C  | First released version
    // 01.06.00 | 2023-04-10 | DI FA S SUP E&C  | Rework and refactoring of entire library
    // 02.00.00 | 2024-11-11 | DI FA S SUP E&C  | Migrate library to Simatic AX
    //===============================================================================

//end_region
USING System.Timer;
USING Simatic.Ax.LStream.Utilities;
USING System.Strings;
USING Simatic.Ax.LStream.Models;
NAMESPACE Simatic.Ax.LStream
    FUNCTION_BLOCK LStream_XmlSerializer
        VAR_INPUT
            /// Rising edge starts action once
            execute : BOOL;
        END_VAR
        VAR_OUTPUT
            /// TRUE: Commanded functionality has been completed successfully
            done : BOOL;
            /// TRUE: FB is not finished and new output values can be expected
            busy : BOOL;
            /// TRUE: An error occurred during the execution of the FB
            error : BOOL;
            /// 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
            status : WORD := STATUS_NO_CALL;
            /// Count of char/ byte info elements in byte array
            count : UINT;
        END_VAR
        VAR_IN_OUT
            /// Describes the element for LStream libraries, by providing key-value pair and the depth of the element
            tree : ARRAY [*] of LStream_typeElement;
            /// XML structure as array of bytes
            xmlByteArray : ARRAY[*] of BYTE;
        END_VAR
        VAR PUBLIC 
            TimeoutTimer : System.Timer.OnDelay;
        END_VAR
        VAR
            /// Old value of 'execute' input for edge detection
            statExecuteOld : BOOL;
            /// Static value for output 'done'
            statDone : BOOL;
            /// Static value for output 'busy'
            statBusy : BOOL;
            /// Static value for output 'error'
            statError : BOOL;
            /// Static value for output 'count'
            statCount : UINT;
            /// Static value for output 'status'
            statStatus : WORD := STATUS_NO_CALL;
            /// State in the state machine of the FB
            statFBState : DINT := FB_STATE_NO_PROCESSING;
            /// Previous state in the state machine of the FB
            statFBPreviousState : DINT := FB_STATE_NO_PROCESSING;
            /// Next state in the state machine of the FB
            statFBNextState : DINT := FB_STATE_NO_PROCESSING;
            /// Index indicating current element of byte array to be written
            statIndexXmlByteArray : UINT;
            /// Index indicating current element of tree array to be read
            statIndexTreeArray : UINT;
            /// Length of tree array
            statTreeLen : DINT;
            /// Length of xml byte array
            statXmlByteLen : DINT;
            /// Static value of current information that should be written to XML
            statInfoToWrite : STRING;
            /// TRUE: is last element in tree array
            statIsLastElement : BOOL;
            /// Stack of open elements
            statStackIndexOpenElement : ARRAY[0..STACK_SIZE] OF UINT;
            /// Stack pointer
            statStackIndex : INT := -1;
            /// Depth of the current tree element
            statCurrentDepth : INT;
            statWorkingDepth : INT;
        END_VAR
        VAR_TEMP
            /// Temporary value for input 'execute'
            tempExecute : BOOL;
            /// Temporary value indicating count of chars added to byte array
            tempCntCharsAdded : INT;
            /// Temporary iterator value
            tempIterator : UINT;
            /// Temporary value indicating that the current element has nested elements
            tempHasNested : BOOL;
        END_VAR
        VAR CONSTANT
            /// FB state: No processing
            FB_STATE_NO_PROCESSING : DINT := 0;
            /// FB state: Clean the entire byte array
            FB_STATE_CLEAR_BYTE_ARRAY : DINT := 1;
            /// FB state: Write XML Header
            FB_STATE_XML_HEADER : DINT := 2;
            /// FB state: Get Next Element
            FB_STATE_NEXT_ELEMENT : DINT := 3;
            /// FB state: Switch Element type
            FB_STATE_ELEMENT_TYPE_OPEN : DINT := 4;
            /// FB state: Add Information to xml byte array
            FB_STATE_WRITE_TO_XML : DINT := 5;
            /// FB state: Close Parent Element
            FB_STATE_CLOSE_STACK_ELEMENT : DINT := 6;
            /// FB state: Error
            FB_STATE_ERROR : DINT := 7;
            /// FB state: Done
            FB_STATE_DONE : DINT := 8;
            /// Execution finished without errors
            STATUS_EXECUTION_FINISHED : WORD := WORD#16#0000;
            /// No job being currently processed
            STATUS_NO_CALL : WORD := WORD#16#7000;
            /// First call after incoming new job (rising edge 'execute')
            STATUS_FIRST_CALL : WORD := WORD#16#7001;
            /// Subsequent call during active processing without further details
            STATUS_SUBSEQUENT_CALL : WORD := WORD#16#7002;
            /// Subsequent call during active processing without further details
            ERR_UNDEFINED_STATE : WORD := WORD#16#8600;
            /// Error: wrong operation of the function block
            ERR_IN_BLOCK_OPERATION : WORD := WORD#16#8601;
            /// Error: during parameterization
            ERR_PARAMETRIZATION : WORD := WORD#16#8200;
            /// Error: when processing from outside (e. g. wrong I/O signals, axis not referenced)
            ERR_PROCESSING_EXTERN : WORD := WORD#16#8400;
            /// Error: user enter undefined type
            ERR_UNDEFINED_TYPE : WORD := WORD#16#8401;
            /// Error: provided xml tree structure is too deep
            ERR_UNEXPECTED_DEPTH : WORD := WORD#16#8402;
            /// Error: provided xml tree structure does not contain correct depth
            ERR_DEPTH_MISSING : WORD := WORD#16#8403;
            /// Error: when processing internally (e. g. when calling a system function)
            ERR_PROCESSING_INTERN : WORD := WORD#16#8600;
            /// Error: tree array out of bounds
            ERR_TREE_OUT_OF_BOUNDS : WORD := WORD#16#8601;
            /// Error: byte array out of bounds
            ERR_XML_OUT_OF_BOUNDS : WORD := WORD#16#8602;
            /// Error: stack array out of bounds
            ERR_STACK_OUT_OF_BOUNDS : WORD := WORD#16#8603;
            /// Error: reserved area
            ERR_AREA_RESERVED : WORD := WORD#16#8800;
            /// Error: user-defined error classes
            ERR_USER_DEFINED_CLASSES : WORD := WORD#16#9000;
            /// Constant to increment by one
            INCREMENT_BY_ONE : SINT := SINT#1;
            /// Constant to decrement by one
            DECREMENT_BY_ONE : SINT := SINT#1;
            /// Numerical identifier for XML type element
            ELEMENT : SINT := SINT#0;
            /// Numerical identifier for XML type attribute
            ATTRIBUTE : SINT := SINT#1;
            /// Numerical identifier for XML type text
            TEXT : SINT := SINT#2;
            /// Constant for first array dimension
            FIRST_DIM : USINT := USINT#1;
            /// Max duration of loop, will be continued in next cycle
            MAX_REPEAT_TIME : TIME := T#6ms;
            /// XML Header, leads every XML File
            XML_HEADER : STRING := '<?xml version="1.0" encoding="ASCII"?>';
            /// ASCII code for < indicates a new key
            XML_KEY_OPEN : CHAR := '<';
            /// ASCII code for '=' indicates key is finished follows by value
            XML_ATTRIBUTE_OPEN : STRING := '="';
            /// ASCII code for  > indicates key can be written
            XML_KEY_CLOSE_GREATER : CHAR := '>';
            /// ASCII code for / indicates closing
            XML_KEY_CLOSE_SLASH : CHAR := '/';
            /// ASCII code  for " frames value
            XML_ATTRIBUTE_CLOSE : CHAR := '"';
            /// Constant value to get next index
            NEXT_INDEX : UINT := UINT#1;
            /// Constant for Stack Size, equals max depth
            STACK_SIZE : UINT := UINT#30;
            /// ASCII code for white space
            WHITE_SPACE: CHAR := ' ';
            /// Constant value representing not initialized tree element
            NOT_INITIALIZED : SINT := SINT#-1;
            /// String for NULL value
            NULL_CONST : STRING := STRING#'NULL';
            /// Empty string for checking if value is contained within the string
            EMPTY_STRING : STRING := STRING#'';
            /// Empty byte for cleaning the byte array
            EMPTY_BYTE : BYTE := BYTE#16#0;
            
        END_VAR;

        tempExecute := execute; // Work with temporary value / create process image

        //region TRIGGERING
            IF (tempExecute = TRUE) AND (statExecuteOld = FALSE) // Check if FB is triggered
                AND (statStatus = STATUS_NO_CALL)
            THEN // First call; initialize FB
                statDone := FALSE;
                statBusy := TRUE;
                statError := FALSE;
                statStatus := STATUS_FIRST_CALL;
                // State machine - start processing
                statFbState := FB_STATE_CLEAR_BYTE_ARRAY;
                
                //Initialize functionality: reset OF variables, diagnostics, etc.
                statXmlByteLen := UPPER_BOUND(xmlByteArray, FIRST_DIM);
                statTreeLen := UPPER_BOUND(tree, FIRST_DIM);
                statIndexTreeArray := UINT#0;
                statIndexXmlByteArray := UINT#0;
                statIsLastElement := FALSE;
                statStackIndex := -1;
                
                statCurrentDepth := tree[statIndexTreeArray].depth;
                
            ELSIF (statStatus = STATUS_FIRST_CALL) THEN
                statStatus := STATUS_SUBSEQUENT_CALL;
            END_IF;
            
            // Edge detection 'execute' input
            statExecuteOld := tempExecute;
        //endregion TRIGGERING

        IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
            RETURN;
        END_IF;

        //region STATE_MACHINE
            //rest and start watchdog here so that repeat until has a maximum duration of constant MAX_LOOP_TIME
            TimeoutTimer(signal := FALSE, duration := MAX_REPEAT_TIME);
            //start watchdog
            TimeoutTimer(signal := TRUE, duration := MAX_REPEAT_TIME);
            REPEAT
                statFbPreviousState := statFbState;
        
                CASE statFbState OF // State machine of FB
                        
                    FB_STATE_NO_PROCESSING:
                        //region NO PROCESSING
                            // No processing active (Note: this state must always be present and left empty)
                            EXIT;
                        //endregion NO PROCESSING

                    FB_STATE_CLEAR_BYTE_ARRAY:
                        //region CLEAR BYTE ARRAY
                            WHILE TRUE DO
                            
                                IF statIndexXmlByteArray > statXmlByteLen THEN
                                    EXIT;
                                END_IF;
                                xmlByteArray[statIndexXmlByteArray] := EMPTY_BYTE;
                                statIndexXmlByteArray := statIndexXmlByteArray + UINT#1;
                            END_WHILE;
                            
                            statIndexXmlByteArray := tempIterator;
                            statFbState := FB_STATE_XML_HEADER;
                        //endregion CLEAR BYTE ARRAY
                    FB_STATE_XML_HEADER: // Add xml Header 
                        //region WRITE XML HEADER
                            // Write XML Header at the beginning of byte array
                            statInfoToWrite := XML_HEADER;
                            
                            //Move to state Write
                            tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);
                            
                            IF tempCntCharsAdded = -1 THEN
                                statStatus := ERR_XML_OUT_OF_BOUNDS;
                                statFbState := FB_STATE_ERROR;
                                CONTINUE;
                            END_IF;
                            
                            statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                            
                            //Set state, that should be executed after writing
                            statFbState := FB_STATE_NEXT_ELEMENT;
                            
                        //endregion WRITE XML HEADER    
                        
                    FB_STATE_NEXT_ELEMENT: // Get Next Element and write tree key
                        //region GET NEXT ELEMENT 
                            
                            IF statIndexTreeArray = UINT#204 THEN
                                statIndexTreeArray := UINT#204;
                            END_IF;
                            
                            IF statIsLastElement OR statIndexTreeArray + UINT#1 > statTreeLen THEN
                                statIsLastElement := TRUE;
                                statCurrentDepth := 0;
                                statFbState := FB_STATE_CLOSE_STACK_ELEMENT;
                                CONTINUE;
                            ELSIF tree[statIndexTreeArray].types = -1 THEN
                                statCurrentDepth := 0;
                                statIsLastElement := TRUE;
                                statFbState := FB_STATE_CLOSE_STACK_ELEMENT;
                                CONTINUE;
                            END_IF;
                            
                            
                            
                            
                            IF tree[statIndexTreeArray].depth < statCurrentDepth THEN
                                statCurrentDepth := tree[statIndexTreeArray].depth;
                                statFbState := FB_STATE_CLOSE_STACK_ELEMENT;
                                CONTINUE;
                            END_IF;
                            statCurrentDepth := tree[statIndexTreeArray].depth;
                            
                            
                            // The next index would be out of bounds of the tree array
                            // set last element flag and close all stack elements, if there are any
                            IF statIndexTreeArray + UINT#1 > statTreeLen THEN
                                statIsLastElement := TRUE;
                            ELSE
                                // Check if next element is initialized, if not set
                                // last element flag and close all stack elements, if there are any
                                IF tree[statIndexTreeArray + UINT#1].depth = -1
                                    OR tree[statIndexTreeArray + UINT#1].types = -1
                                    OR tree[statIndexTreeArray + UINT#1].key = EMPTY_STRING
                                THEN
                                    statIsLastElement := TRUE;
                                END_IF;
                                
                            END_IF;
                            
                            statFbState := FB_STATE_ELEMENT_TYPE_OPEN;
                            
                            // Overwrite state if the current element is the last element or the next
                            // element has a higher depth.
                            (*
                            IF #statIsLastElement THEN
                                #statFbState := #FB_STATE_CLOSE_STACK_ELEMENT;
                            END_IF;
                            *)
                            
                            
                            
                            
                        //endregion GET NEXT ELEMENT
                        
                    FB_STATE_ELEMENT_TYPE_OPEN: // Check Type and write tree value
                        
                        IF statIndexTreeArray = UINT#45 THEN
                            statIndexTreeArray := UINT#45;
                        END_IF;
                        
                        tempHasNested := FALSE;
                        
                        statInfoToWrite := Concat(string1 := XML_KEY_OPEN,
                                                string2 := tree[statIndexTreeArray].key);
                        
                        tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);
                        
                        IF tempCntCharsAdded <= -1 THEN
                            statStatus := ERR_XML_OUT_OF_BOUNDS;
                            CONTINUE;
                        END_IF;
                        
                        // Should not loose information as the condition of negative count is a error case
                        // and checked above
                        statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                        
                        tempIterator := statIndexTreeArray;
                        
                        WHILE tempIterator + UINT#1 < statTreeLen DO
                            
                            IF tree[tempIterator + UINT#1].types <> ATTRIBUTE THEN
                                EXIT;
                            END_IF;
                            
                            tempIterator := tempIterator + UINT#1;
                            
                            // Write attribute infos to the string, assuming that they are in combination shorter than the string datatype
                            statInfoToWrite := Concat(string1 := WHITE_SPACE,
                                                string2 := tree[tempIterator].key,
                                                string3 := XML_ATTRIBUTE_OPEN,
                                                string4 := tree[tempIterator].value);
                            /// ADD Temp String because 5 concat is not supported
                            statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := XML_ATTRIBUTE_CLOSE);
                            /*statInfoToWrite := Concat(
                                                              IN1 := WHITE_SPACE,
                                                              IN2 := tree[tempIterator].key,
                                                              IN3 := XML_ATTRIBUTE_OPEN,
                                                              IN4 := tree[tempIterator].value,
                                                              IN5 := XML_ATTRIBUTE_CLOSE);*/
                            
                            tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);
                            
                            IF tempCntCharsAdded = -1 THEN
                                statStatus := ERR_XML_OUT_OF_BOUNDS;
                                EXIT;
                            END_IF;
                            
                            // Should not loose information as the condition of negative count is a error case
                            // and checked above
                            statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                            
                        END_WHILE;
                        
                        IF statStatus = ERR_XML_OUT_OF_BOUNDS THEN
                            statFbState := FB_STATE_ERROR;
                            CONTINUE;
                        END_IF;
                        
                        IF tempIterator + UINT#1 <= statTreeLen THEN
                            // Has nested elements
                            IF tree[tempIterator + UINT#1].depth > statCurrentDepth THEN
                                IF (TO_DINT(statStackIndex) < STACK_SIZE) THEN
                                    statStackIndex := statStackIndex + TO_INT(INCREMENT_BY_ONE);
                                    statStackIndexOpenElement[statStackIndex] := statIndexTreeArray;
                                    tempHasNested := TRUE;
                                ELSE //Error: Stack out of Bound
                                    statStatus := ERR_STACK_OUT_OF_BOUNDS;
                                    statFbState := FB_STATE_ERROR;
                                    CONTINUE;
                                END_IF;
                            END_IF;
                        ELSE
                            statIsLastElement := TRUE;
                            statFbState := FB_STATE_CLOSE_STACK_ELEMENT;
                            CONTINUE;
                        END_IF;
                        
                        
                        IF tree[statIndexTreeArray].value <> NULL_CONST OR tempHasNested THEN
                            // Write attribute infos to the string, assuming that they are in combination shorter than the string datatype
                            statInfoToWrite := XML_KEY_CLOSE_GREATER;
                            
                            IF tree[statIndexTreeArray].value <> NULL_CONST THEN
                                statInfoToWrite := Concat(string1 := XML_KEY_CLOSE_GREATER, string2 := tree[statIndexTreeArray].value);
                                IF NOT tempHasNested THEN
                                    statInfoToWrite := Concat(string1 := statInfoToWrite,
                                                        string2 := XML_KEY_OPEN, 
                                                        string3 := XML_KEY_CLOSE_SLASH);           
                                    statInfoToWrite := Concat(string1 := statInfoToWrite, 
                                                            string2 := tree[statIndexTreeArray].key,
                                                            string3 := XML_KEY_CLOSE_GREATER);

                                END_IF;
                            END_IF;
                            
                            tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);
                            
                            IF tempCntCharsAdded = -1 THEN
                                statStatus := ERR_XML_OUT_OF_BOUNDS;
                                statFbState := FB_STATE_ERROR;
                                CONTINUE;
                            END_IF;
                            
                            // Should not loose information as the condition of negative count is a error case
                            // and checked above
                            statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                            
                            // Close element with short form '/>'
                        ELSIF tree[statIndexTreeArray].value = NULL_CONST THEN  
                            
                            // This IF considers the situation in which the value of the tree node is 'NULL'
                            IF NOT tempHasNested THEN

                            statInfoToWrite := XML_KEY_CLOSE_GREATER;

                            statInfoToWrite := Concat(string1 := statInfoToWrite,
                                                string2 := XML_KEY_OPEN, 
                                                string3 := XML_KEY_CLOSE_SLASH);           
                            statInfoToWrite := Concat(string1 := statInfoToWrite, 
                                                    string2 := tree[statIndexTreeArray].key,
                                                    string3 := XML_KEY_CLOSE_GREATER);

                            tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);

                            ELSE
                            
                            // Write attribute infos to the string, assuming that they are in combination shorter than the string datatype
                            statInfoToWrite := Concat(string1 := XML_KEY_CLOSE_SLASH, string2 := XML_KEY_CLOSE_GREATER);
                            tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);

                            END_IF;

                            IF tempCntCharsAdded = -1 THEN
                                statStatus := ERR_XML_OUT_OF_BOUNDS;
                                statFbState := FB_STATE_ERROR;
                                CONTINUE;
                            END_IF;
                            // Should not loose information as the condition of negative count is a error case
                            // and checked above
                            statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                            
                        END_IF;
                        
                        statIndexTreeArray := tempIterator + UINT#1;
                        statFbState := FB_STATE_NEXT_ELEMENT;
                        CONTINUE;
                        
                        
                    FB_STATE_CLOSE_STACK_ELEMENT: //Close Open Stack Elements
                        //region CLOSE ELEMENT FROM STACK
                            
                            IF statStackIndex < 0 THEN
                                
                                IF statIsLastElement THEN
                                    statFbState := FB_STATE_DONE;
                                ELSE
                                    statFbState := FB_STATE_NEXT_ELEMENT;
                                    statIndexTreeArray := statIndexTreeArray + UINT#1;
                                END_IF;
                                
                                CONTINUE;
                                
                            END_IF;
                            
                            WHILE tree[statStackIndexOpenElement[statStackIndex]].depth >= statCurrentDepth DO
                                
                                // Write attribute infos to the string, assuming that they are in combination shorter than the string datatype
                                statInfoToWrite := Concat(
                                                                  string1 := XML_KEY_OPEN,
                                                                  string2 := XML_KEY_CLOSE_SLASH,
                                                                  string3 := tree[statStackIndexOpenElement[statStackIndex]].key,
                                                                  string4 := XML_KEY_CLOSE_GREATER);
                                
                                tempCntCharsAdded := LStream_WriteOutString(offset := statIndexXmlByteArray, toWrite := statInfoToWrite, xmlByteArray := xmlByteArray);
                                
                                IF tempCntCharsAdded = -1 THEN
                                    statStatus := ERR_XML_OUT_OF_BOUNDS;
                                    EXIT;
                                END_IF;
                                
                                // Should not loose information as the condition of negative count is a error case
                                // and checked above
                                statIndexXmlByteArray := statIndexXmlByteArray + TO_UINT(tempCntCharsAdded) + UINT#1;
                                statWorkingDepth := tree[statStackIndexOpenElement[statStackIndex]].depth;
                                statStackIndexOpenElement[statStackIndex] := UINT#0;
                                statStackIndex := statStackIndex - DECREMENT_BY_ONE;
                                
                                IF statStackIndex < 0 THEN
                                    EXIT;
                                END_IF;
                                
                            END_WHILE;
                            statCurrentDepth := statWorkingDepth;
                            IF statIsLastElement THEN
                                // -> goto stack and close everything until depth = next elements depth
                                statFbState := FB_STATE_DONE;
                            ELSE
                                statFbState := FB_STATE_NEXT_ELEMENT;
                            END_IF;
                            
                        //endregion CLOSE ELEMENT FROM STACK
                        
                    FB_STATE_ERROR:
                        //region STATE ERROR 
                            
                            statFbState := FB_STATE_NO_PROCESSING;
                            statError := TRUE;
                            statDone := FALSE;
                            
                        //endregion STATE ERROR;
                        
                        
                    FB_STATE_DONE:
                        //region STATE MACHINE DONE
                            statCount := statIndexXmlByteArray;
                            statDone := FALSE;
                            statStatus := STATUS_EXECUTION_FINISHED;
                            statFbState := FB_STATE_NO_PROCESSING;
                            tempExecute := FALSE;
                            
                        //endregion STATE MACHINE DONE
                        
                    ELSE // Undefined state in state machine reached
                        //REGION UNDEFINED STATE
                            statStatus := ERR_UNDEFINED_STATE;
                        //endregion UNDEFINED STATE                
                        
                END_CASE;

                // Call for Timeout timer to update value
                TimeoutTimer();
                //Leave state machine if one of the following condition is true
                //1. state has not changed
                //2. error has occurred
                //3. watchdog timer expired 
                //4. execution has finished
                // otherwise stay in state machine
            UNTIL (statFbPreviousState = statFbState OR statStatus.%X15
            OR TimeoutTimer.output OR statStatus = STATUS_EXECUTION_FINISHED)
            END_REPEAT;
        //endregion STATE_MACHINE

    // REGION OUTPUTS
    // Write outputs
    IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
        // REGION EXECUTION FINISHED
            statDone := TRUE;
            statBusy := FALSE;
            statError := FALSE;
            // execution aborted --> set state no processing
            statFbState := FB_STATE_NO_PROCESSING;
        // END_REGION EXECUTION FINISHED
        
    ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (statStatus is 168000 to 16FFFF)
        // REGION ERROR OCCURRED
            statDone := FALSE;
            statBusy := FALSE;
            statError := TRUE;
            // execution aborted --> set state no processing
            statFbState := FB_STATE_NO_PROCESSING;
        // END_REGION ERROR OCCURRED
        
    ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
        // REGION EXECUTE RESET
            statDone := FALSE;
            statBusy := FALSE;
            statError := FALSE;
            statStatus := STATUS_NO_CALL;
            // Reset application specific outputs
            statCount := UINT#0;
        // END_REGION EXECUTE RESET
    END_IF;
    
    // REGION WRITE STATIC VALUES TO OUTPUTS
        done := statDone;
        busy := statBusy;
        error := statError;
        status := statStatus;        
        // Write application specific static values to outputs
        count := statCount;
    // END_REGION WRITE STATIC VALUES TO OUTPUTS
// END_REGION OUTPUTS

    END_FUNCTION_BLOCK
END_NAMESPACE