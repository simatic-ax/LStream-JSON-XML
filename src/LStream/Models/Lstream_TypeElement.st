NAMESPACE Simatic.Ax.LStream.Models
    TYPE 
        LStream_TypeElement : STRUCT 
            types : SINT := SINT#-1;
            key : STRING := '';
            value : STRING := 'NULL';
            depth : SINT := SINT#-1;
            closingElement : BOOL; 
        END_STRUCT;
    END_TYPE
END_NAMESPACE