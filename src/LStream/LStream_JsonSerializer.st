//REGION BLOCK INFO HEADER
	//===============================================================================
	// SIEMENS AG / (c)Copyright 2023
	//-------------------------------------------------------------------------------
	// Title:            LStream_JsonSerializer
	// Comment/Function: parses a JSON string provided in the raw parameter
	//                   and rebuilds the contained bytes into a tree structure
	// Library/Family:   LStream
	// Author:           DI FA S SUP E&C
	// Tested with:      S7-1500 V2.8
	// Engineering:      TIA Portal V16
	// Restrictions:     -- 
	// Requirements:     LStream_typeElement(UDT)
	//-------------------------------------------------------------------------------
	// Change log table:
	// Version  | Date       | Expert in charge       | Changes applied
	//----------|------------|------------------------|------------------------------
	// 01.00.00 | 2021-06-10 | DI FA S SUP E&C        | First released version
	// 01.06.00 | 2023-04-10 | DI FA S SUP E&C        | Rework and refactoring of entire library
	// 01.06.01 | 2023-06-28 | DI FA S SUP E&C        | Bug fix (First element String type issue)
	// 01.06.04 | 2023-07-28 | DI FA S SUP E&C        | Bug fix (JsonByte and Tree array start index issue)
	//===============================================================================
//END_REGION
USING System.Timer;
USING System.Strings;
USING System.Serialization;
USING Simatic.Ax.LStream.Models;
NAMESPACE Simatic.Ax.LStream

	FUNCTION_BLOCK LStream_JsonSerializer
	/// LStream_JsonDeserializer
	// Author : DI_FA_S_SUP_EuC
	// Family : LStream
	// Version : 1.0
	//parses a JSON string provided in the raw parameter  and rebuilds the contained bytes into a tree structure
	VAR_INPUT 
		/// Rising edge starts action once
		execute : Bool;
	END_VAR

	VAR_OUTPUT 
		/// TRUE: Commanded functionality has been completed successfully
		done : Bool;
		/// TRUE: FB is not finished and new output values can be expected
		busy : Bool;
		/// TRUE: An error occurred during the execution of the FB
		error : Bool;
		/// 16#0000 - 16#7FFF: Status of the FB, 16#8000 - 16#FFFF: Error identification
		status : Word := STATUS_NO_CALL;
		/// Count of char/ byte info elements in byte array
		count : UInt;
	END_VAR
    VAR PUBLIC 
		TimeoutTimer : System.Timer.OnDelay;
	END_VAR
	VAR_IN_OUT 
		tree : Array[*] of LStream_typeElement;
		/// JSON structure as array of bytes
		jsonByteArray : Array[*] of Byte;
	END_VAR

	VAR 		
		/// Old value of 'execute' input for edge detection
		statExecuteOld : Bool := FALSE;
		/// Static value for output 'done'
		statDone : Bool := FALSE;
		/// Static value for output 'busy'
		statBusy : Bool := FALSE;
		/// Static value for output 'error'
		statError : Bool := FALSE;
		/// Static value for output 'count'
		statCount : UInt := UINT#0;
		/// Static value for output 'status'
		statStatus : Word := STATUS_NO_CALL;
		/// State in the state machine of the FB
		statFbState : DInt := FB_STATE_NO_PROCESSING;
		/// Previous state in the state machine of the FB
		statFbPreviousState : DInt := FB_STATE_NO_PROCESSING;
		/// Next state in the state machine of the FB
		statFbNextState : DInt := FB_STATE_NO_PROCESSING;
		/// Index indicating current element of byte array to be written
		statIndexJsonByteArray : UInt := UINT#0;
		/// Index indicating current element of tree array to be read
		statIndexTreeArray : UInt := UINT#0;
		/// Length of tree array
		statTreeLen : DInt := 0;
		/// Static value of current information that should be written to XML
		statInfoToWrite : String := '';
		/// TRUE: is last element in tree array
		statIsLastElement : Bool := FALSE;
		/// TRUE: Last JSON  element is closed
		statLastElementIsClosed : Bool := FALSE;
		/// Stack of open elements
		statStackIndexOpenElement : Array[0..STACK_SIZE] of Char;
		/// Stack pointer and current depth
		statStackIndex : Int := -1;
		/// Static value indicating whether an array is open
		statIsArrayOpen : Bool;
		/// Static value indicating whether an array field was closed
		statIsArrayFieldClosed : Bool;
		/// TRUE: first field of simple array
		statIsFirstElement : Bool;
		/// First key of array, used to check for new array beginning
		statFirstArrayKey : String;
		/// Name of Array
		statArrayName : String;
		/// Static Json array starting index
		statJsonEndIndex : Int;
		/// Static Json array ending index
		statJsonStartIndex : Int;
		/// Static tree array starting index
		statTreeStartIndex : Int;
		
	END_VAR

	VAR_TEMP 
		/// Temporary value for input 'execute'
		tempExecute : Bool;
		/// Temporary value indicating count of chars added to byte array //REVIEW
		tempCntCharsAdded : UDInt;
		/// Temporary integer for clearing byte array for cycle
		tempIteral : Int;
		Index : INT;
		tempOffsetArray : ARRAY[0..255] OF BYTE;   
	END_VAR

	VAR CONSTANT 
		/// FB state: No processing
		FB_STATE_NO_PROCESSING : DInt := 0;
		/// FB state: Clearing the output JSON byte array
		FB_STATE_CLEAR_BYTE_ARRAY : DInt := 1;
		/// FB state: Get Next Element
		FB_STATE_NEXT_ELEMENT : DInt := 2;
		/// FB state: Switch Value type
		FB_STATE_VALUE_TYPE : DInt := 3;
		/// FB state: Add Information to xml byte array
		FB_STATE_WRITE_TO_JSON : DInt := 4;
		/// FB state: Close Parent Element
		FB_STATE_CLOSE_STACK_ELEMENT : DInt := 5;
		/// Execution finished without errors
		STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;
		/// No job being currently processed
		STATUS_NO_CALL : Word := WORD#16#7000;
		/// First call after incoming new job (rising edge 'execute')
		STATUS_FIRST_CALL : Word := WORD#16#7001;
		/// Subsequent call during active processing without further details
		STATUS_SUBSEQUENT_CALL : Word := WORD#16#7002;
		/// Error: due to an undefined state in state machine
		ERR_UNDEFINED_STATE : Word := WORD#16#8600;
		/// Error: wrong operation of the function block
		ERR_IN_BLOCK_OPERATION : Word := WORD#16#8001;
		/// Error: during parameterization
		ERR_PARAMETRIZATION : Word := WORD#16#8200;
		/// Error: when processing from outside (e. g. wrong I/O signals, axis not referenced)
		ERR_PROCESSING_EXTERN : Word := WORD#16#8400;
		/// Error: user enter undefined type
		ERR_UNDEFINED_TYPE : Word := WORD#16#8401;
		/// Error: provided json tree structure is too deep
		ERR_UNEXPECTED_DEPTH : Word := WORD#16#8402;
		/// Error: provided json tree structure does not contain correct depth
		ERR_DEPTH_MISSING : Word := WORD#16#8403;
		/// Error: when processing internally (e. g. when calling a system function)
		ERR_PROCESSING_INTERN : Word := WORD#16#8600;
		/// Error: tree array out of bounds
		ERR_TREE_OUT_OF_BOUNDS : Word := WORD#16#8601;
		/// Error: byte array out of bounds
		ERR_JSON_OUT_OF_BOUNDS : Word := WORD#16#8602;
		/// Error: stack array out of bounds
		ERR_STACK_OUT_OF_BOUNDS : Word := WORD#16#8603;
		/// Error: reserved area
		ERR_AREA_RESERVED : Word := WORD#16#8800;
		/// Error: user-defined error classes
		ERR_USER_DEFINED_CLASSES : Word := WORD#16#9000;
		/// ASCII code for '"'
		QUOTATION_MARK : Char := '"';
		/// ASCII code for ':'
		COLON : Char := ':';
		/// ASCII code for ','
		COMMA : Char := ',';
		/// ASCII code for '{'
		BRACES_OPEN : Char := '{';
		/// ASCII code for '}'
		BRACES_CLOSE : Char := '}';
		/// ASCII code for '['
		BRACKETS_OPEN : Char := '[';
		/// ASCII code for ]
		BRACKETS_CLOSE : Char := ']';
		/// ASCII coder for \ indicates closing
		PROTECTION_KEY : Char := '\';
		/// ASCII code for line feed
		LINE_FEED : Char := '$L';
		/// ASCII code for TAB
		TAB : Char := '$T';
		/// ASCII code for carriage return
		CARRIAGE_RETURN : Char := '$R';
		/// ASCII code for blank space
		SPACE : Char := ' ';
		/// Constant for first array dimension
		FIRST_DIM : USInt := USINT#1;
		/// Max duration of loop, will be continued in next cycle
		MAX_REPEAT_TIME : Time := T#3ms;
			/// Return value if Search in LStream_FindStringInByteCharArrayAdv was not successful
		INVALID_SEARCH : DInt := -1;
		/// Value string in case key wasn't found
		KEY_NOT_FOUND : String := 'Key not found';
		/// Constant to increment by one
		INCREMENT_BY_ONE : USInt := USINT#1;
		/// Constant to decrement by one
		DECREMENT_BY_ONE : SInt := SINT#1;
		/// Constant for value typ object
		OBJECT : SInt := Sint#0;
		/// Constant for value typ array
		ARRAY_CONST : SInt := SINT#1;
		/// Constant for value type string
		STRING_CONST : SInt := SINT#2;
		/// Constant for value type number
		NUMBER : SInt := SINT#3;
		/// Constant for value type boolean
		BOOLEAN : SInt := SINT#4;
		/// Constant value to get next index
		NEXT_INDEX : UInt := UINT#1;
		/// Constant for Stack Size, equals max depth
		STACK_SIZE : UInt := UINT#10;
		/// ASCII code for white space
		WHITE_SPACE : Char := ' ';
			/// Constant value representing not initialized tree element
		NOT_initialized : SInt := SINT#-1;
		/// Constant value representing an empty string
		EMPTY : String := '';
		/// Constant value representing an empty byte
		EMPTY_BYTE : Byte := BYTE#0;
		//EMPTY_CHAR : Char := ' '; // Constant value representing an empty char
		/// Constant value representing null
		NULL_CONST : String := 'NULL';
		/// Constant key value for identify multidimensional arrays
		MULTI_ARRAY : String := 'MultiArray';
	END_VAR
		
		tempExecute := execute; // Work with temporary value / create process image
		
		//REGION TRIGGERING
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
				statJsonEndIndex := TO_INT(UPPER_BOUND(jsonByteArray, FIRST_DIM));
				statJsonStartIndex := TO_INT(LOWER_BOUND(jsonByteArray, FIRST_DIM));
				statTreeLen := UPPER_BOUND(tree, FIRST_DIM);
				statTreeStartIndex := TO_INT(LOWER_BOUND(tree, FIRST_DIM));
				statIndexTreeArray := TO_UINT(statTreeStartIndex);
				statIndexJsonByteArray := UINT#0;
				statIsLastElement := FALSE;
				statLastElementIsClosed := FALSE;
				statStackIndex := -1;
				statIsArrayOpen := FALSE;
				
			ELSIF (statStatus = STATUS_FIRST_CALL) THEN
				statStatus := STATUS_SUBSEQUENT_CALL;
			END_IF;
			
			// Edge detection 'execute' input
			statExecuteOld := tempExecute;
		//END_REGION TRIGGERING
		
		IF (statStatus = STATUS_NO_CALL) THEN // Nothing to do -> End here to reduce "system load"
			RETURN;
		END_IF;
		
		//REGION STATE_MACHINE
			
			//rest and start watchdog here so that repeat until has a maximum duration of constant MAX_LOOP_TIME
			TimeoutTimer(signal := FALSE,
							duration := MAX_REPEAT_TIME);
			//start watchdog
			TimeoutTimer(signal := TRUE,
							duration := MAX_REPEAT_TIME);
			REPEAT
				statFbPreviousState := statFbState;
				
				CASE statFbState OF // State machine of FB
						
					FB_STATE_NO_PROCESSING: 
						//REGION NO_PROCESSING
							// No processing active (Note: this state must always be present and left empty)
							;
						//END_REGION NO_PROCESSING
						
					FB_STATE_CLEAR_BYTE_ARRAY: 
						//REGION CLEAR BYTE ARRAY
							IF statJsonEndIndex > 0 THEN
								FOR tempIteral := statJsonStartIndex TO statJsonEndIndex DO
									jsonByteArray[tempIteral] := EMPTY_BYTE;
								END_FOR;
							END_IF;
							statFbState := FB_STATE_NEXT_ELEMENT;
						//END_REGION CLEAR BYTE ARRAY
						
					FB_STATE_NEXT_ELEMENT: // Work on next Element
						//REGION NEXT_ELEMENT
							//REGION ERROR_HANDLING
								//check for last Element, either end of provided tree reached, or tree element is -1 = not initialized
								//this prevents index out of bounds error
								IF (statIndexTreeArray = statTreeLen -1 ) OR tree[statIndexTreeArray + NEXT_INDEX].types = NOT_initialized THEN
									statIsLastElement := TRUE;
									
								ELSIF (statIndexTreeArray = statTreeLen) THEN
									//Error: Tree out of Bound
									statStatus := ERR_TREE_OUT_OF_BOUNDS;
								END_IF;
								
								//Error: provided json tree is too deep
								//max depth size allowed is size of stack, otherwise array out of bounds error will occur
								IF (TO_DINT(tree[statIndexTreeArray].depth) = STACK_SIZE) THEN
									statStatus := ERR_UNEXPECTED_DEPTH;
								ELSIF (tree[statIndexTreeArray].depth = NOT_initialized) THEN
									//depth wasn't provided by user
									statStatus := ERR_DEPTH_MISSING;
								END_IF;
							//END_REGION ERROR_HANDLING
							
							//REGION FIRST_ELEMENT
								// stackIndex is used as current depth, is initialized with -1 therefore first element, will always open an object 
								IF statStackIndex < 0 THEN
									//open object if first tree element depth less than 1
									IF tree[statIndexTreeArray].depth < 1 THEN
										statInfoToWrite := BRACES_OPEN; //METHOD TO CONVERT SINGLE CHAR IN STRING
										//increase stack index and push closing elements on to it
										statStackIndex := statStackIndex + INCREMENT_BY_ONE;
										statStackIndexOpenElement[statStackIndex] := BRACES_CLOSE;
									ELSE // if JSON is an ARRAY containing objects
										statInfoToWrite := Concat(string1 := BRACKETS_OPEN, string2 :=  BRACES_OPEN);
										//increase stack index and push closing elements on to it
										statStackIndex := statStackIndex + INCREMENT_BY_ONE;
										statStackIndexOpenElement[statStackIndex] := BRACKETS_CLOSE;
										statStackIndex := statStackIndex + INCREMENT_BY_ONE;
										statStackIndexOpenElement[statStackIndex] := BRACES_CLOSE;
									END_IF;
								END_IF;
							//END_REGION FIRST_ELEMENT
							//Move to state Write
							statFbState := FB_STATE_WRITE_TO_JSON;
							//Set state, that should be executed after writing
							//move on to next state
							statFbNextState := FB_STATE_VALUE_TYPE;
							
						//END_REGION NEXT_ELEMENT 
						
					FB_STATE_VALUE_TYPE: // Depending on value type, write value
						//REGION VALUE DEPENDENCY OF TYPE
							CASE tree[statIndexTreeArray].types OF
									
								OBJECT: 
									//REGION OBJECT
										//nothing to do when type is object just add line feed, { opening will occur with next depth
										statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK,
																string4 := COLON);
										statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACES_OPEN);
										
										//increase stack index and push closing elements on to it
										statStackIndex := statStackIndex + INCREMENT_BY_ONE;
										statStackIndexOpenElement[statStackIndex] := BRACES_CLOSE;
									//END_REGION OBJECT
									
								ARRAY_CONST: 
									//REGION ARRAY
										
										// checking for nested object inside the array //or nested array
										IF tree[statIndexTreeArray].depth + 1 < tree[statIndexTreeArray + NEXT_INDEX].depth THEN
											statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 :=  QUOTATION_MARK,
																string4 := COLON);
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 :=  BRACKETS_OPEN, string3 := BRACES_OPEN);
											
											//increase stack index and push closing elements on to it
											statStackIndex := statStackIndex + INCREMENT_BY_ONE;
											statStackIndexOpenElement[statStackIndex] := BRACKETS_CLOSE;
											statStackIndex := statStackIndex + INCREMENT_BY_ONE;
											statStackIndexOpenElement[statStackIndex] := BRACES_CLOSE;
											//there are no nested elements
										ELSIF tree[statIndexTreeArray].depth + 1 = tree[statIndexTreeArray + NEXT_INDEX].depth AND tree[statIndexTreeArray].key <> MULTI_ARRAY THEN
											statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK,
																string4 :=COLON);
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACKETS_OPEN);
											//increase stack index and push closing elements on to it
											statStackIndex := statStackIndex +  INCREMENT_BY_ONE;
											statStackIndexOpenElement[statStackIndex] := BRACKETS_CLOSE;
										ELSIF tree[statIndexTreeArray].depth + 1 = tree[statIndexTreeArray + NEXT_INDEX].depth AND tree[statIndexTreeArray].key = MULTI_ARRAY THEN
											statInfoToWrite := BRACKETS_OPEN;
											//increase stack index and push closing elements on to it
											statStackIndex := statStackIndex + INCREMENT_BY_ONE;
											statStackIndexOpenElement[statStackIndex] := BRACKETS_CLOSE;
										ELSIF statIsLastElement OR (tree[statIndexTreeArray + NEXT_INDEX].depth <= tree[statIndexTreeArray].depth) THEN
											// Empty array: output "key":[]
											statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK, string4 := COLON);
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACKETS_OPEN, string3 := BRACKETS_CLOSE);
											// Handle closing element transition (same as STRING/NUMBER handlers)
											IF statIndexTreeArray < TO_UINT(statTreeLen) THEN
												IF (NOT statIsLastElement) AND tree[statIndexTreeArray].closingElement AND tree[statIndexTreeArray].depth = tree[statIndexTreeArray + NEXT_INDEX].depth THEN
													IF statStackIndexOpenElement[statStackIndex] = BRACES_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACES_CLOSE, string3 := COMMA, string4 := BRACES_OPEN);
													ELSIF statStackIndexOpenElement[statStackIndex] = BRACKETS_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACKETS_CLOSE, string3 := COMMA, string4 := BRACKETS_OPEN);
													ELSE
														statStatus := ERR_UNEXPECTED_DEPTH;
													END_IF;
												END_IF;
											END_IF;
										ELSE
											statStatus := ERR_TREE_OUT_OF_BOUNDS;
										END_IF;
										
									//END_REGION ARRAY 
									
								STRING_CONST: 
									//REGION STRING
										IF TO_DINT(statIndexTreeArray) > statTreeStartIndex THEN
											//write value as string - value enclosed with quotation mark 
											IF (tree[statIndexTreeArray].value <> NULL_CONST) AND (tree[statIndexTreeArray].key <> tree[statIndexTreeArray - UINT#1].key) THEN
												statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 :=  QUOTATION_MARK,
																string4 := COLON);
												statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := QUOTATION_MARK, string3 := tree[statIndexTreeArray].value, string4 :=  QUOTATION_MARK);
																								
											ELSIF (tree[statIndexTreeArray].value <> NULL_CONST) AND (tree[statIndexTreeArray].key = tree[statIndexTreeArray - UINT#1].key) THEN
												statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].value, string3 :=  QUOTATION_MARK);
														
											ELSE  // empty value still needs "" otherwise syntax error
												statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 :=  QUOTATION_MARK,
																string4 := COLON);
												statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := QUOTATION_MARK, string3 := QUOTATION_MARK);
											END_IF;
											
											IF statIndexTreeArray < statTreeLen THEN
												//if this is a nested closing element could be that next element has the same depth because the next element could start a new element
												IF tree[statIndexTreeArray].closingElement AND tree[statIndexTreeArray].depth = tree[statIndexTreeArray + INCREMENT_BY_ONE].depth THEN
													IF statStackIndexOpenElement[statStackIndex] = BRACES_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACES_CLOSE, string3 := COMMA, string4 := BRACES_OPEN);	
													ELSIF statStackIndexOpenElement[statStackIndex] = BRACKETS_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACKETS_CLOSE,
														 						string3 :=  COMMA, string4 := BRACKETS_OPEN);
													ELSE
														statStatus := ERR_UNEXPECTED_DEPTH;
													END_IF;
												END_IF;
											END_IF;
											//bug??
										ELSE
											statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK,
																string4 := COLON);
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := QUOTATION_MARK, string3 := tree[statIndexTreeArray].value, string4 := QUOTATION_MARK);
										END_IF;
									//END_REGION STRING
									
								NUMBER, BOOLEAN: 
									//REGION NUMBER_BOOLEAN
										//write value as number or boolean - value enclosed without quotation mark 
										IF TO_DINT(statIndexTreeArray) > statTreeStartIndex THEN
											IF ((tree[statIndexTreeArray].value <> NULL_CONST) AND (tree[statIndexTreeArray].key <> tree[statIndexTreeArray - UINT#1].key) AND (tree[statIndexTreeArray].key <> '')) THEN
												statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK,
																string4 := COLON);
												statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := tree[statIndexTreeArray].value);
						
												//deserializer gives back in the simple array the numbers and the booleans with the key value of the array key
											ELSIF ((tree[statIndexTreeArray].value <> NULL_CONST) AND (tree[statIndexTreeArray].key = tree[statIndexTreeArray - UINT#1].key)) THEN
												statInfoToWrite := tree[statIndexTreeArray].value;
											END_IF;
											
											IF statIndexTreeArray < statTreeLen THEN
												//if this is a nested closing element could be that next element has the same depth because the next element could start a new element
												IF tree[statIndexTreeArray].closingElement AND tree[statIndexTreeArray].depth = tree[statIndexTreeArray + INCREMENT_BY_ONE].depth THEN
													IF statStackIndexOpenElement[statStackIndex] = BRACES_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACES_CLOSE, string3 :=  COMMA, string4 := BRACES_OPEN);
														
													ELSIF statStackIndexOpenElement[statStackIndex] = BRACKETS_CLOSE THEN
														statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACKETS_CLOSE, string3 := COMMA, string4 := BRACKETS_OPEN);
													ELSE
														statStatus := ERR_UNEXPECTED_DEPTH;
													END_IF;
												END_IF;
											END_IF;
										ELSE
											statInfoToWrite := Concat(string1 := QUOTATION_MARK, string2 := tree[statIndexTreeArray].key, string3 := QUOTATION_MARK, string4 := COLON);
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := tree[statIndexTreeArray].value);
										END_IF;
										
									//END_REGION NUMBER_BOOLEAN
									
								ELSE // Undefined state in state machine reached
									//REGION UNDEFINED STATE
										statStatus := ERR_UNDEFINED_STATE;
									//END_REGION UNDEFINED STATE          
									
							END_CASE;
							
							//Move to state Write
							statFbState := FB_STATE_WRITE_TO_JSON;
							
							//Set state, that should be executed after writing
							//move on to next state
							statFbNextState := FB_STATE_NEXT_ELEMENT;
							
							IF statIsLastElement OR tree[statIndexTreeArray].depth > tree[statIndexTreeArray + NEXT_INDEX].depth THEN
								//Next Element has lower depth, therefore Elements have to be closed
								statFbNextState := FB_STATE_CLOSE_STACK_ELEMENT;
							ELSIF statIsLastElement OR tree[statIndexTreeArray].depth = tree[statIndexTreeArray + NEXT_INDEX].depth
								AND NOT tree[statIndexTreeArray].closingElement THEN
								statInfoToWrite := Concat(string1 := statInfoToWrite,
														string2 := COMMA);
							ELSIF statIsLastElement OR tree[statIndexTreeArray].depth = tree[statIndexTreeArray + NEXT_INDEX].depth
								AND tree[statIndexTreeArray].closingElement THEN
								;
							END_IF;
							
							
							//increase tree index to access next element 
							statIndexTreeArray := statIndexTreeArray + INCREMENT_BY_ONE;
							
						//END_REGION VALUE DEPENDENCY OF TYPE
						
					FB_STATE_WRITE_TO_JSON: // Write to Byte Array
						//REGION WRITE TO JSON                
							//add information to json byte array
							IF ((TO_UINT(LengthOf(statInfoToWrite)) + TO_DINT(statIndexJsonByteArray)) < statJsonEndIndex) THEN
								tempCntCharsAdded := Serialize(offset := UDINT#0, value := statInfoToWrite, buffer := tempOffsetArray);
										//WRITE INTO OUTPUT ARRAY WITH AN OFFSET TO AVOID WRITING STRING SIZE
								FOR Index := 0 TO TO_INT(tempOffsetArray[0]) - 1 DO                
									jsonByteArray[TO_INT(statIndexJsonByteArray) + Index] := tempOffsetArray[Index + 1];    
								END_FOR;
								//clean written data and values							
								statInfoToWrite := EMPTY;
								//move index of byte array 
								statIndexJsonByteArray := statIndexJsonByteArray + TO_UINT(tempCntCharsAdded) - UINT#1;  //FIXED,  
								//statIndexJsonByteArray := TO_UINT(TO_UDINT(statIndexJsonByteArray) + tempCntCharsAdded);	//REVIEW, NOT WORK AS TIA PORTAL FUNCTION
								//move to next state previously allocated
								statFbState := statFbNextState;
							ELSE // Error: Index out of bounds
								statStatus := ERR_JSON_OUT_OF_BOUNDS;
							END_IF;
							
							IF statLastElementIsClosed THEN
								//writer has written last information and execution is done
								statStatus := STATUS_EXECUTION_FINISHED;
								//current index equals count/size of json byte array
								statCount := statIndexJsonByteArray;
							END_IF;
						//END_REGION WRITE TO JSON
						
					FB_STATE_CLOSE_STACK_ELEMENT: //Close Open Stack Elements
						//REGION CLOSE ELEMENT FROM STACK
							//close element with syntax </key>
							
							
							IF statStackIndex >= 0 THEN //more open elements available, not all elements are closed
								
								//statInfoToWrite --> } or ]
								statInfoToWrite :=  statStackIndexOpenElement[statStackIndex];	//REVIEW
								
								IF statInfoToWrite = BRACKETS_CLOSE THEN
									//reset flag
									statIsArrayOpen := FALSE;
									
								END_IF;
								
								//pop element from stack 
								statStackIndex := statStackIndex - TO_INT(DECREMENT_BY_ONE);
								
								IF statStackIndex >= 0 THEN //more open elements available, not all elements are closed
									//look at current stack item depth, if next tree element has 
									IF NOT statIsLastElement AND statStackIndex = tree[statIndexTreeArray].depth THEN
										//move to next element
										//write comma as JSON dictates same depth a divided by comma,
										//here we move on to the next element with the same depth
										statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := COMMA);
										
										// //if Array is still open and the same length is reached,
										// //new element in array, distinguish new entry with BRACES
										IF statIsArrayOpen THEN
											statInfoToWrite := Concat(string1 := statInfoToWrite, string2 := BRACES_CLOSE, string3 := COMMA);
											//pop element from stack 
											statStackIndex := statStackIndex - TO_INT(DECREMENT_BY_ONE);
											statIsArrayFieldClosed := TRUE;
										END_IF;
										statFbNextState := FB_STATE_NEXT_ELEMENT;
										
									ELSE
										//do nothing and return to fb state close element 
										statFbNextState := FB_STATE_CLOSE_STACK_ELEMENT;
									END_IF;
									
								ELSE
									//no more open Elements, last Element was closed
									statIsLastElement := TRUE;
									
									//only if this flag is set, can writer be finished
									statLastElementIsClosed := TRUE;
									
								END_IF;
								
							ELSE
								//no more open Elements, last Element was closed
								statIsLastElement := TRUE;
								
								//only if this flag is set, can writer be finished
								statLastElementIsClosed := TRUE;
								
							END_IF;
							
							//Move to state Write
							statFbState := FB_STATE_WRITE_TO_JSON;
							
						//END_REGION CLOSE ELEMENT FROM STACK
						
					ELSE // Undefined state in state machine reached
						//REGION UNDEFINED STATE
							statStatus := ERR_UNDEFINED_STATE;
						//END_REGION UNDEFINED STATE     
						
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
		//END_REGION STATE_MACHINE
		
		//REGION OUTPUTS
			// Write outputs
			IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
				//REGION EXECUTION FINISHED
					statDone := TRUE;
					statBusy := FALSE;
					statError := FALSE;
					// execution aborted --> set state no processing
					statFbState := FB_STATE_NO_PROCESSING;
				//END_REGION EXECUTION FINISHED
				
			ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
				//REGION ERROR OCCURRED
					statDone := FALSE;
					statBusy := FALSE;
					statError := TRUE;
					// execution aborted --> set state no processing
					statFbState := FB_STATE_NO_PROCESSING;
				//END_REGION ERROR OCCURRED
				
			ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
				//REGION EXECUTE RESET
					statDone := FALSE;
					statBusy := FALSE;
					statError := FALSE;
					statStatus := STATUS_NO_CALL;
					// Reset application specific outputs
					statCount := UINT#0;
				//END_REGION EXECUTE RESET
			END_IF;
			
			//REGION WRITE STATIC VALUES TO OUTPUTS
				done := statDone;
				busy := statBusy;
				error := statError;
				status := statStatus;
				//  ENO mechanism is not used 
				//ENO := TRUE;		//ENO NOT AVAILABLE
				// Write application specific static values to outputs
				count := statCount;
			//END_REGION WRITE STATIC VALUES TO OUTPUTS
		//END_REGION OUTPUTS
		
	END_FUNCTION_BLOCK


END_NAMESPACE