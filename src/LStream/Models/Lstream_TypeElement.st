NAMESPACE Simatic.Ax.LStream.Models
    TYPE 
        {OpcUa = ReadWrite}
        {S7.Extern = ReadWrite}
        /// Represents a parsed element or attribute from an XML/JSON structure with its metadata
        LStream_TypeElement : STRUCT 
            /// Type identifier: 0 = Element, 1 = Attribute, -1 = Not initialized
            types : SINT := SINT#-1;
            /// The name or key of the element or attribute
            key : STRING := '';
            /// The value associated with the element or attribute; default 'NULL' if not set
            value : STRING := 'NULL';
            /// Nesting depth in the document hierarchy; -1 indicates not initialized
            depth : SINT := SINT#-1;
            /// TRUE if this element marks a closing tag or end of a structure
            closingElement : BOOL; 
        END_STRUCT;
    END_TYPE
END_NAMESPACE