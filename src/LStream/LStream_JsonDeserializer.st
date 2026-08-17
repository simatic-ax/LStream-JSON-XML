//REGION BLOCK INFO HEADER
	//===============================================================================
	// SIEMENS AG / (c)Copyright 2021
	//-------------------------------------------------------------------------------
	// Title:            LStream_JsonDeserializer
	// Comment/Function: parses a JSON string provided in the raw parameter
	//                   and rebuilds the contained bytes into a tree structure
	// Library/Family:   LStream
	// Author:           DI FA S SUP E&C
	// Tested with:      S7-1500 V2.8
	// Engineering:      TIA Portal V16
	// Restrictions:     -- 
	// Requirements:     LStream_FindStringInByteArrayAdv(FC), LStream_typeElement(UDT)
	//-------------------------------------------------------------------------------
	// Change log table:
	// Version  | Date       | Expert in charge  | Changes applied
	//----------|------------|-------------------|-----------------------------------
	//  01.0.00 | 2021-03-10 | DI FA S SUP E&C   | First released version
	//  01.6.00 | 2023-04-10 | DI FA S SUP E&C   | Rework and refactoring of entire library
	//  01.6.02 | 2023-07-28 | DI FA S SUP E&C   | Raw byte and tree array start index bug fixing
	//===============================================================================
//END_REGION
USING System.Timer;
USING Simatic.Ax.System.Strings;
USING Simatic.Ax.LStream.Utilities;
USING Simatic.Ax.LStream.Models;
NAMESPACE Simatic.Ax.LStream
	/// Parses a JSON string provided in the raw parameter  and rebuilds the contained bytes into a tree structure
	FUNCTION_BLOCK LStream_JsonDeserializer
 	// LStream_JsonDeserializer
  	// Author : DI_FA_S_SUP_EuC
  	// Family : LStream
  	// Version : 1.0
	VAR_INPUT 
		/// Rising edge starts action once
		execute : Bool;
		/// TRUE: Search option is active
		search : Bool;
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
		/// Count of parsed JSON elements
		resultCount : Int;
	END_VAR
	VAR_IN_OUT 
		/// JSON tree containing the stored data
		tree : Array[*] of LStream_typeElement;
		/// raw JSON data to parse in byte format
		raw : Array[*] of Byte;
	END_VAR
	VAR PUBLIC 
		TimeoutTimer : System.Timer.OnDelay;
	END_VAR
	VAR 
		/// Old value of 'execute' input for edge detection
		statExecuteOld : Bool;
		/// Static value for output 'done'
		statDone : Bool;
		/// Static value for output 'busy'
		statBusy : Bool;
		/// Static value for output 'error'
		statError : Bool;
		/// Static value for output 'status'
		statStatus : Word := STATUS_NO_CALL;
		/// State in the state machine of the FB
		statFBState : DInt := FB_STATE_NO_PROCESSING;
		/// Static count of tree fields
		statCountOfTree : Int;
		/// Static value of result count
		statResultCount : Int;
		/// Static value of raw index
		statRawIndex : Int;
		/// TRUE: Only keys provided in tree will be parsed
		statSearch : Bool;
		/// TRUE: Key exists in raw data
		statKeyValueFound : Bool;
		/// Static value of tree index
		statTreeIndex : Int;
		/// Static search
		statSearchIndex : DInt;
		/// Static value of the last element JSON depth
		statLastDepth : SInt := SINT#-1;
		/// Static value of JSON depth
		statDepth : SInt := SINT#-1;
		/// TRUE: Key or Value is opened
		statOpen : Bool;
		/// Start index of current info in raw key or value
		statInfoStartIndex : Int;
		/// Next character to be ignored
		statIgnorableCharacter : Bool;
		/// Current  information length key or value
		statInfoLen : UInt;
		/// Static key string
		statKey : String;
		/// Static value string
		statValue : String;
		/// Count of provided keys that weren't found
		statKeyNotFoundCount : Int;
		/// TRUE: New JSON array is open
		statArrayOpen : Bool;
		/// TRUE: Is type array of object
		statObjectArray : Bool;
		/// Current type of element
		statType : SInt;
		/// TRUE: Value Type can be defined
		statDefineValueType : Bool;
		/// Name of array
		statArrayName : String;
		/// Value of the last input character
		statLastChar : Int;
		/// Boolean for compressed file format; FALSE= file format compressed
		statOpenFormat : Bool;
		/// Element is first element of an array; TRUE= first element
		statFirstElement : Bool;
		/// Flag bit for multi dimensional arrays
		statIsMultiArray : Bool;
		/// Empty element for clearing
		statEmptyTree : LStream_typeElement;
		/// Static start index number of the RAW array
		statRawStartIndex : Int;
		/// Static end index number of the RAW array
		statRawEndIndex : Int;
		/// Static start index number of the Tree array
		statTreeStartIndex : Int;
	END_VAR

	VAR_TEMP 
		/// Temporary value for input 'execute'
		tempExecute : Bool;
		/// Index of raw field
		tempRawIndex : Int;
		/// Provided key to which the value should be found
		tempKeyToFind : String;
		/// Temp value of search result
		tempSearchResult : DInt;
		/// Temp Index value for Multi dimensional array check
		tempMultiIndex : Int;
		/// Temp index for clearing the raw
		tempIteral : Int;
		/// Temp index for clearing the tree
		tempTreeIndex : Int;
	END_VAR

	VAR CONSTANT 
		/// FB state: No processing
		FB_STATE_NO_PROCESSING : DInt := 0;
		/// FB state: Processing Parsing
		FB_STATE_PARSE : DInt := 1;
		/// FB state clearing the tree array
		FB_STATE_CLEAR_BYTE_ARRAY : DInt := 2;
		/// FB state: Checking the JSON file format
		FB_STATE_FILE_FORMAT : DInt := 3;
		/// Execution finished without errors
		STATUS_EXECUTION_FINISHED : Word := WORD#16#0000;
		/// No job being currently processed
		STATUS_NO_CALL : Word := WORD#16#7000;
		/// First call after incoming new job (rising edge 'execute')
		STATUS_FIRST_CALL : Word := WORD#16#7001;
		/// Subsequent call during active processing without further details
		STATUS_SUBSEQUENT_CALL : Word := WORD#16#7002;
		/// Error: provided array to too small
		ERR_TREE_ARRAY_TOO_SMALL : Word := WORD#16#8201;
		/// Error: no raw data provided
		ERR_EMPTY_RAW_DATA : Word := WORD#16#8401;
		/// Error: due to an undefined state in state machine
		ERR_UNDEFINED_STATE : Word := WORD#16#8600;
		/// ASCII code for '"'
		JSON_QUOTATION_MARK : Byte := BYTE#16#22;
		/// ASCII code for ':'
		JSON_COLON : Byte := BYTE#16#3A;
		/// ASCII code for ','
		JSON_COMMA : Byte := BYTE#16#2C;
		/// ASCII code for '{'
		JSON_BRACES_OPEN : Byte := BYTE#16#7B;
		/// ASCII code for '}'
		JSON_BRACES_CLOSE : Byte := BYTE#16#7D;
		/// ASCII code for '['
		JSON_BRACKETS_OPEN : Byte := BYTE#16#5B;
		/// ASCII code for ]
		JSON_BRACKETS_CLOSE : Byte := BYTE#16#5D;
		/// ASCII coder for \ indicates closing
		JSON_PROTECTION_KEY : Byte := BYTE#16#5C;
		/// ASCII coder for / indicates closing
		JSON_CLOSE_KEY : Byte := BYTE#16#2F;
		/// ASCII code for line feed
		LINE_FEED : Byte := BYTE#16#0A;
		/// ASCII code for TAB
		TAB : Byte := BYTE#16#09;
		/// ASCII code for carriage return
		CARRIAGE_RETURN : Byte := BYTE#16#0D;
		/// ASCII code for blank space
		SPACE : Byte := BYTE#16#20;
		/// Constant for first array dimension
		FIRST_DIM : USInt := USINT#1;
		/// Max duration of loop, will be continued in next cycle
		MAX_LOOP_TIME : Time := T#3ms;
		/// Return value if Search in LStream_FindStringInByteCharArrayAdv was not successful
		INVALID_SEARCH : DInt := -1;
		/// Value string in case key wasn't found
		KEY_NOT_FOUND : String := 'Key not found';
		/// Constant to increment by one
		INCREMENT_BY_ONE : USInt := USINT#1;
		/// Constant to decrement by one
		DECREMENT_BY_ONE : SInt := SINT#1;
		/// Constant to decrement by two
		DECREMENT_BY_TWO : SInt := SINT#2;
		/// Constant for value typ object
		OBJECT : SInt := SINT#0;
		/// Constant for value typ array
		ARRAY_CONST : SInt := SINT#1;
		/// Constant for value type string
		STRING_CONST : SInt := SINT#2;
		/// Constant for value type number
		NUMBER : SInt := SINT#3;
		/// Constant for value type boolean
		BOOLEAN : SInt := SINT#4;
		/// Constant indicating depth wasn't yet defined
		DEPTH_NOT_DEFINED : Int := -1;
		/// Constant key value for identify multidimensional arrays
		MULTI_ARRAY : String := 'MultiArray';
		/// Constant empty byte
		NUL : Byte := BYTE#16#0;


		/// ASCII code for '"'
		JSON_QUOTATION_MARK_INT : INT := 34;
		/// ASCII code for ':'
		JSON_COLON_INT : INT := 58;
		/// ASCII code for ','
		JSON_COMMA_INT : INT := 44;
		/// ASCII code for '{'
		JSON_BRACES_OPEN_INT : INT := 123;
		/// ASCII code for '}'
		JSON_BRACES_CLOSE_INT : INT := 125;
		/// ASCII code for '['
		JSON_BRACKETS_OPEN_INT : INT := 91;
		/// ASCII code for ']'
		JSON_BRACKETS_CLOSE_INT : INT := 93;
		/// ASCII code for '\' indicates closing
		JSON_PROTECTION_KEY_INT : INT := 92;
		/// ASCII code for '/' indicates closing
		JSON_CLOSE_KEY_INT : INT := 47;
		/// ASCII code for line feed
		LINE_FEED_INT : INT := 10;
		/// ASCII code for TAB
		TAB_INT : INT := 9;
		/// ASCII code for carriage return
		CARRIAGE_RETURN_INT : INT := 13;
		/// ASCII code for blank space
		SPACE_INT : INT := 32;
		/// Constant empty byte
		NUL_INT : INT := 0;
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
				statRawStartIndex := TO_INT(LOWER_BOUND(raw, FIRST_DIM));
				statRawEndIndex := TO_INT(UPPER_BOUND(raw, FIRST_DIM));
				statCountOfTree := TO_INT(UPPER_BOUND(tree, FIRST_DIM));
				statTreeStartIndex := TO_INT(LOWER_BOUND(tree, FIRST_DIM));
				// State machine - start processing
				statFBState := FB_STATE_CLEAR_BYTE_ARRAY;
				
				// Initialize functionality: reset of variables, diagnostics, etc.
				statSearch := search;
				statOpen := FALSE;
				statDepth := SINT#-1;
				statRawIndex := statRawStartIndex;
				statIsMultiArray := false;
				statTreeIndex := statTreeStartIndex;
				statInfoLen := UINT#0;
				statSearchIndex := 0;
				statKeyNotFoundCount := 0;
				statType := SINT#-1;
				statDefineValueType := FALSE;
				statObjectArray := FALSE;
				
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
			
			CASE statFBState OF // State machine of FB
				FB_STATE_NO_PROCESSING: 
					//REGION NO PROCESSING
						// No processing active (Note: this state must always be present and left empty)
						;
					//END_REGION NO PROCESSING
					
				FB_STATE_CLEAR_BYTE_ARRAY: 
					//REGION CLEAR BYTE ARRAY
						IF statCountOfTree > 0 THEN
							
							FOR tempTreeIndex := statTreeStartIndex TO statCountOfTree DO
								tree[tempTreeIndex] := statEmptyTree;
							END_FOR;
						END_IF;
						statFBState := FB_STATE_FILE_FORMAT;
					//END_REGION CLEAR BYTE ARRAY
					
					
				FB_STATE_FILE_FORMAT: 
					// REGION FILE FORMAT
						//Searching FOR the last valid character number in the RAW array
						FOR tempRawIndex := statRawIndex TO statRawEndIndex DO
							IF raw[tempRawIndex] <> NUL THEN
								statLastChar := tempRawIndex;
							END_IF;
						END_FOR;
						// Cancel in case raw data is empty
						IF raw[statLastChar] = NUL THEN
							statStatus := ERR_EMPTY_RAW_DATA;
						ELSE
							// Continue processing if input not empty
							statRawIndex := statRawStartIndex;
							tempRawIndex := statRawStartIndex;
							// if there is a special format character before the closing bracket the JSON file is not compressed
							IF raw[statLastChar - 1] = LINE_FEED OR raw[statLastChar - 1] = CARRIAGE_RETURN OR raw[statLastChar - 1] = SPACE OR raw[statLastChar - 1] = TAB THEN
								statOpenFormat := true;
							ELSE
								statOpenFormat := false;
							END_IF;
							statFBState := FB_STATE_PARSE;
						END_IF;
						
					//END_REGION FILE FORMAT
					
					
					
				FB_STATE_PARSE: // Processing active
					//REGION PARSING
						
						//rest watchdog
						TimeoutTimer(signal := FALSE,
									duration := MAX_LOOP_TIME);
						//start watchdog
						TimeoutTimer(signal := TRUE,
									duration := MAX_LOOP_TIME);
						
						FOR tempRawIndex := statRawIndex TO statRawEndIndex DO
							
							//REGION FIND KEY
								//pre check if key exist in raw data, if search option is active
								IF (statSearch AND statKeyValueFound = FALSE) THEN
									IF (statTreeIndex < statCountOfTree) THEN
										tempSearchResult := LStream_FindStringInByteCharArrayAdv(searchFor := tree[statTreeIndex].key, startPosition := statSearchIndex, searchIn := raw);
										IF (tempSearchResult = INVALID_SEARCH) THEN
											//case key not found
											tree[statTreeIndex].value := KEY_NOT_FOUND;
											statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
											statKeyNotFoundCount := statKeyNotFoundCount + INCREMENT_BY_ONE;
										ELSE//case key found
											//move read pointer to last found index
											statSearchIndex := tempSearchResult;
											statKeyValueFound := TRUE;
										END_IF;
									END_IF;
								END_IF;
							//END_REGION FIND KEY   
							
							
							CASE TO_INT(raw[tempRawIndex]) OF
									
								JSON_BRACES_OPEN_INT: 
									//REGION OBJECT OPEN     
										
										statDepth := statDepth + TO_SINT(INCREMENT_BY_ONE);
										IF (statDefineValueType) THEN
											statDefineValueType := FALSE;
											statType := OBJECT;
											tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
										END_IF;
									//END_REGION OBJECT OPEN
									
								JSON_BRACES_CLOSE_INT: 
									//REGION OBJECT CLOSE      
										
										statDepth := statDepth - DECREMENT_BY_ONE;
										//last element closed, and there is still info in the buffer, then write value to last key
										IF (statDepth = -1 AND statInfoLen > UINT#0) THEN
											//in case of 0 length, Chars_To_String returns the maximum possible char combination
											CharsToString(chars := raw, startPosition := statInfoStartIndex - statRawStartIndex, length := statInfoLen, result => statValue);

											statInfoLen := UINT#0;
											//value Type wasn't yet defined must be either number or boolean
											IF (statDefineValueType) THEN
												statDefineValueType := FALSE;
												
												IF statValue = 'FALSE' OR statValue = 'TRUE'
													OR statValue = 'false' OR statValue = 'true' THEN
													statType := BOOLEAN;
												ELSE
													statType := NUMBER;
												END_IF;
											END_IF;
											IF (statSearch) THEN
												
												IF (statTreeIndex > 0) THEN
													//in case of 0 length, Chars_To_String returns the maximum possible char combination
													IF (statKey = tree[statTreeIndex - DECREMENT_BY_ONE].key) THEN
														//only write into tree, if key matches, otherwise continue with search for matching key
														tree[statTreeIndex - DECREMENT_BY_ONE].value := statValue;
														tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
														statKeyValueFound := FALSE;
													END_IF;
												ELSE
													IF (statKey = tree[statTreeIndex].key) THEN
														tree[statTreeIndex].value := statValue;
														tree[statTreeIndex].types := statType;
														statKeyValueFound := FALSE;
													END_IF;
												END_IF;
												
											ELSE // IF #search option isn't active (parse all) add key TO the current #tree index
												tree[statTreeIndex - DECREMENT_BY_ONE].value := statValue;
												tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
											END_IF;
										END_IF;
										
										//last element of an array->set closing element flag to true
										tree[statTreeIndex - 1].closingElement := true;
										
									//END_REGION OBJECT CLOSE
									
								JSON_BRACKETS_OPEN_INT: 
									//REGION ARRAY OPEN
										statDepth := statDepth + TO_SINT(INCREMENT_BY_ONE);
										
										statFirstElement := true;
										//checking for multidimensional array
										tempMultiIndex := tempRawIndex;
										// check that is it a multidimensional array structure or not
										WHILE ((NOT statIsMultiArray) AND tempMultiIndex > statRawStartIndex) DO
											
											CASE TO_INT(raw[tempMultiIndex - 1]) OF
													
												TAB_INT, LINE_FEED_INT, CARRIAGE_RETURN_INT, SPACE_INT:
													tempMultiIndex := tempMultiIndex - DECREMENT_BY_ONE;
												JSON_BRACKETS_OPEN_INT:
													statIsMultiArray := true;
													
												ELSE
													tempMultiIndex := 0;
											END_CASE;
										END_WHILE;
										
										// if it is a simple array
										IF (NOT statIsMultiArray) THEN
											
											IF (statTreeIndex > statTreeStartIndex) THEN//simple array
												//in multi dimensional array do not write over the existing format
												IF tree[statTreeIndex - DECREMENT_BY_ONE].key <> MULTI_ARRAY THEN
													//set the element type to array
													tree[statTreeIndex - DECREMENT_BY_ONE].types := ARRAY_CONST;
												ELSE// in multidimensional array keep the type
													;
												END_IF;
												//save arrayName
												statArrayName := tree[statTreeIndex - DECREMENT_BY_ONE].key;
												statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
											ELSE // first element, is of type array
												tree[statTreeIndex].typeS := ARRAY_CONST;
												
											END_IF;
										ELSE //multidimensional array
											
											//set the element type of the inside array
											tree[statTreeIndex - DECREMENT_BY_ONE].types := ARRAY_CONST;
											tree[statTreeIndex - DECREMENT_BY_ONE].key := MULTI_ARRAY;
											tree[statTreeIndex - DECREMENT_BY_ONE].depth := statDepth - DECREMENT_BY_ONE;
											//save arrayName
											statArrayName := MULTI_ARRAY;
											statTreeIndex := INCREMENT_BY_ONE;
											tree[statTreeIndex].types := ARRAY_CONST;
											statInfoStartIndex := statInfoStartIndex + INCREMENT_BY_ONE;
										END_IF;
										statArrayOpen := TRUE;
										statObjectArray := FALSE;
										statIsMultiArray := false;
										
									//END_REGION ARRAY OPEN
									
								JSON_BRACKETS_CLOSE_INT: 
									//REGION ARRAY CLOSE
										statDepth := statDepth - DECREMENT_BY_ONE;
										statArrayOpen := FALSE;
										
										// Empty array: undo the tree index reservation made by '['
										IF (statFirstElement = TRUE) THEN
											statTreeIndex := statTreeIndex - DECREMENT_BY_ONE; // undo the slot reservation
											statValue := 'NULL';
											statInfoLen := UINT#0;
											statType := ARRAY_CONST; // preserve array type through COMMA handler
										ELSE
											//last element of an array->set closing element flag to true
											tree[statTreeIndex - 1].closingElement := true;
										END_IF;
										
										statFirstElement := false;
									//END_REGION ARRAY CLOSE
								
								JSON_QUOTATION_MARK_INT: 
									//REGION QUOTATION_MARK
										IF (statOpen) THEN
											IF (NOT (raw[tempRawIndex - DECREMENT_BY_ONE] = JSON_PROTECTION_KEY)) THEN
												// previous sign \ then allowed in string adjust
												statOpen := FALSE;
											ELSE
												statInfoLen := statInfoLen + INCREMENT_BY_ONE;
											END_IF;
										ELSE
											statInfoStartIndex := tempRawIndex + INCREMENT_BY_ONE; //set reader to next sign
											statOpen := TRUE;
											statIgnorableCharacter := FALSE;
											//Quotation mark after column indicates value is of type string
											IF statDefineValueType THEN
												statType := STRING_CONST;
												tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
												statDefineValueType := FALSE;
											END_IF;
											
										END_IF;
									//END_REGION QUOTATION_MARK
								
								JSON_COLON_INT: 
									//REGION COLON
										
										//array is open, and a separate key is found indication for array of objects
										//
										IF statArrayOpen AND NOT statObjectArray THEN
											statObjectArray := TRUE;
											statTreeIndex := statTreeIndex - DECREMENT_BY_ONE;
											statFirstElement := FALSE; // array has at least one object element
										END_IF;
										
										//error handling
										IF (statTreeIndex > statCountOfTree) THEN
											//data does not fit in the provided tree 
											statStatus := ERR_TREE_ARRAY_TOO_SMALL;

											EXIT;
										END_IF;
										
										//write key, if colon is part of a string
										IF (NOT statOpen) THEN
											CharsToString(chars := raw, startPosition := statInfoStartIndex - statRawStartIndex, length := statInfoLen, result => statKey);
											
											statInfoLen := UINT#0;
											
											//After key was written, type of value can be defined, value can be object, array, string, number, or boolean
											statDefineValueType := TRUE;
											
											IF (statSearch) THEN
												//only write into tree, if key matches, otherwise continue with search for matching key
												IF (statKey = tree[statTreeIndex].key) THEN
													//#tree[#statTreeIndex].type := #statType;
													tree[statTreeIndex].depth := statDepth;
													statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
												END_IF;
											
											ELSE// if search option isn't active (parse all) the add key to the current tree index
												//
												IF statTreeIndex < statTreeStartIndex THEN
													statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
												END_IF;
												//
												tree[statTreeIndex].key := statKey;
												//#tree[#statTreeIndex].type := #statType;
												tree[statTreeIndex].depth := statDepth;
												tree[statTreeIndex].value := 'NULL';
												statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
												
											END_IF;
											
											statInfoStartIndex := tempRawIndex + 1;
											
										ELSE//case : included in string
											statInfoLen := statInfoLen + INCREMENT_BY_ONE;
										END_IF;
									//END_REGION COLON
									
								JSON_COMMA_INT: 
									//REGION COMMA
										
										//error handling
										IF (statTreeIndex > statCountOfTree + INCREMENT_BY_ONE) THEN
											//data does not fit in the provided tree 
											statStatus := ERR_TREE_ARRAY_TOO_SMALL;
											EXIT;
										END_IF;
										
										IF (NOT statOpen) THEN
											//write value comma isn't part of string
											IF (statInfoLen > UINT#0) THEN
												//in case of 0 length, Chars_To_String returns the maximum possible char combination
												
												//If it's compressed file or multi array etc., bracket can be the first element->need shit the start index by one
												IF raw[statInfoStartIndex] = JSON_BRACKETS_OPEN THEN
													CharsToString(chars := raw,
																startPosition := statInfoStartIndex - statRawStartIndex + 1,
																length := statInfoLen,
																result => statValue);
													statFirstElement := false;
													
													
												ELSE
													CharsToString(chars := raw, startPosition := statInfoStartIndex - statRawStartIndex, length := statInfoLen, result => statValue);
												END_IF;
												
												statInfoLen := UINT#0;
											ELSE
												statValue := 'NULL';
												statDefineValueType := FALSE;
												//no value Type default value type NULL/Default is correct
											END_IF;
											
											//value Type wasn't yet defined must be either number or boolean
											IF (statDefineValueType) THEN
												statDefineValueType := FALSE;
												
												IF statValue = 'FALSE' OR statValue = 'TRUE'
													OR statValue = 'false' OR statValue = 'true' THEN
													statType := BOOLEAN;
												ELSE
													statType := NUMBER;
												END_IF;
												
											END_IF;
											//add value always to the last JSON element
											IF (statSearch) THEN
												
												IF (statTreeIndex > statTreeStartIndex) THEN
													//in case of 0 length, Chars_To_String returns the maximum possible char combination
													IF (statKey = tree[statTreeIndex - DECREMENT_BY_ONE].key) THEN
														//only write into tree, if key matches, otherwise continue with search for matching key
														tree[statTreeIndex - DECREMENT_BY_ONE].value := statValue;
														tree[statTreeIndex].types := statType;
														statKeyValueFound := FALSE;
													END_IF;
												ELSE
													IF (statKey = tree[statTreeIndex].key) THEN
														// if search option isn't active (parse all) the add key to the current tree index 
														tree[statTreeIndex].value := statValue;
														tree[statTreeIndex].types := statType;
														statKeyValueFound := FALSE;
													END_IF;
												END_IF;
												
											ELSE//search option isn't active
												tree[statTreeIndex - DECREMENT_BY_ONE].value := statValue;
												tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
												//case simple array last information
												IF (tree[statTreeIndex - DECREMENT_BY_ONE].depth = DEPTH_NOT_DEFINED) THEN
													tree[statTreeIndex - DECREMENT_BY_ONE].depth := tree[statTreeIndex - DECREMENT_BY_TWO].depth;
													tree[statTreeIndex - DECREMENT_BY_ONE].key := statArrayName;
													//always take depth from previous entry of simple array e.g "ArrayName":["ArrayValue1","ArrayValue2"]
												END_IF;
											END_IF;
											
											IF (statArrayOpen AND NOT statObjectArray) THEN
												//only write if Array is open and simple array
												//
												tree[statTreeIndex - DECREMENT_BY_ONE].key := statArrayName;
												tree[statTreeIndex - DECREMENT_BY_ONE].depth := statDepth;
												tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
												statTreeIndex := statTreeIndex + INCREMENT_BY_ONE;
											END_IF;
											
											statInfoStartIndex := tempRawIndex + 1;
											
										ELSE//case ; included in string
											statInfoLen := statInfoLen + INCREMENT_BY_ONE;
										END_IF;
									
									//END_REGION
								
								TAB_INT, LINE_FEED_INT, CARRIAGE_RETURN_INT, SPACE_INT: 
									//REGION READ TAB LINE FEED CARRIAGE RETURN   
										IF (NOT statOpen) THEN
											//do nothing when tab, line feed, or carriage return
											statIgnorableCharacter := TRUE;
										ELSE//case space included in string
											statInfoLen := statInfoLen + INCREMENT_BY_ONE;
										END_IF;
										
									//END_REGION READ TAB LINE FEED CARRIAGE RETURN
								
								
								ELSE // all other characters
									//REGION ALL OTHER SIGNS
										IF (statIgnorableCharacter = TRUE) THEN
											statIgnorableCharacter := FALSE;
											statInfoStartIndex := tempRawIndex; // set KeyIndex after all ignorableCharacters are read
											statInfoLen :=statInfoLen + INCREMENT_BY_ONE;
										ELSE
											
											statInfoLen := statInfoLen + INCREMENT_BY_ONE;
										END_IF;
									//END_REGION ALL OTHER SIGNS 
							END_CASE;
							
							statRawIndex := tempRawIndex;
							
							// Call for Timeout timer to update value
							TimeoutTimer();
							//quit and resume in next cycle if watchdogtimer is exceed
							IF (TimeoutTimer.output) THEN
								statRawIndex := statRawIndex + INCREMENT_BY_ONE;
								EXIT;
							END_IF;
							
						END_FOR;
						// fill in last tree element  value and type if its empty
						IF statValue <> 'NULL' AND statRawIndex = statRawEndIndex THEN
							tree[statTreeIndex - DECREMENT_BY_ONE].value := statValue;
							tree[statTreeIndex - DECREMENT_BY_ONE].key := statKey;
							// investigation how many non-ignore or parenthetical characters were there in the depth
							tempRawIndex := statRawIndex;
							// at the last character stat depth already at 0 so need to find the last element depth
							WHILE tempRawIndex > statRawStartIndex DO
								CASE TO_INT(raw[tempRawIndex]) OF
									JSON_BRACES_CLOSE_INT, JSON_BRACKETS_CLOSE_INT: //if elements were closed tempDepth should increase search for the last element further
										statLastDepth := statLastDepth + TO_SINT(INCREMENT_BY_ONE);
										tempRawIndex := tempRawIndex - DECREMENT_BY_ONE;
										
									TAB_INT, LINE_FEED_INT, CARRIAGE_RETURN_INT, SPACE_INT, NUL_INT: // if there were just ignorable characters or  search for the last element further
										tempRawIndex := tempRawIndex - DECREMENT_BY_ONE;
									ELSE // any other character means we found the end of the last character
										tempRawIndex := statRawStartIndex;
								END_CASE;
							END_WHILE;
							//tempLastDepth is the last element depth
							tree[statTreeIndex - DECREMENT_BY_ONE].depth := statLastDepth;
							statLastDepth := SINT#-1;
						END_IF;
						
						IF statType <> -1 AND statRawIndex = statRawEndIndex THEN
							tree[statTreeIndex - DECREMENT_BY_ONE].types := statType;
						END_IF;
						//if parser is through the entire raw data or end of tree array reached
						IF ((statRawIndex >= statRawEndIndex) OR (statTreeIndex > statCountOfTree)) AND NOT (statStatus.%X15 = TRUE) THEN
							statStatus := STATUS_EXECUTION_FINISHED;
							statResultCount := statTreeIndex - statKeyNotFoundCount;
						END_IF;
					//END_REGION PARSING
					
				ELSE // Undefined state in state machine reached
					//REGION UNDEFINED STATE
						statStatus := ERR_UNDEFINED_STATE;
					//END_REGION UNDEFINED STATE
			END_CASE;
		//END_REGION STATE_MACHINE
		
		//REGION OUTPUTS
			// Write outputs
			IF (statStatus = STATUS_EXECUTION_FINISHED) AND (statDone = FALSE) THEN // Execution finished without errors
				//REGION EXECUTION FINISHED
					statDone := TRUE;
					statBusy := FALSE;
					statError := FALSE;
					// execution aborted --> set state no processing
					statFBState := FB_STATE_NO_PROCESSING;
				//END_REGION EXECUTION FINISHED
				
			ELSIF (statStatus.%X15 = TRUE) AND (statError = FALSE) THEN // Error occurred (#statStatus is 16#8000 to 16#FFFF)
				//REGION ERROR OCCURRED
					statDone := FALSE;
					statBusy := FALSE;
					statError := TRUE;
					// execution aborted --> set state no processing
					statFBState := FB_STATE_NO_PROCESSING;
				//END_REGION ERROR OCCURRED
				
			ELSIF (tempExecute = FALSE) AND ((statDone = TRUE) OR (statError = TRUE)) THEN // Reset outputs
				//REGION EXECUTE RESET
					statDone := FALSE;
					statBusy := FALSE;
					statError := FALSE;
					statStatus := STATUS_NO_CALL;
					// Reset application specific outputs
					statResultCount := 0;
				//END_REGION EXECUTE RESET
			END_IF;
			
			//REGION WRITE STATIC VALUES TO OUTPUTS
				done := statDone;
				busy := statBusy;
				error := statError;
				status := statStatus;
				
				//ENO := TRUE;																	//ENO NOT RECOGNIZABLE FOR AX; BUT BY DEFAULT IS TRUE
				// Write application specific static values to outputs
				resultCount := statResultCount;
			//END_REGION WRITE STATIC VALUES TO OUTPUT
		//END_REGION OUTPUTS
	END_FUNCTION_BLOCK


END_NAMESPACE