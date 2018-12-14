{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : FlatDecode
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 07:42:12 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.compresores.ICompresor.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.compresores.FlateDecode IMPLEMENTS ICompresor: 
  DEFINE PUBLIC PROPERTY cchNombreMetodo AS CHARACTER INITIAL 'FlateDecode' NO-UNDO
    GET.
    
  /* ------------ Start of External Zlib procedure definitions --------------- */
  PROCEDURE compress EXTERNAL "{&zlib}" CDECL PERSISTENT: /* PRIVATE */
      DEFINE INPUT        PARAMETER pDestBuf    AS MEMPTR NO-UNDO.
      DEFINE INPUT-OUTPUT PARAMETER iDestSize   AS INT64 NO-UNDO.
      DEFINE INPUT        PARAMETER pSourceBuf  AS MEMPTR NO-UNDO.
      DEFINE INPUT        PARAMETER iSourceSize AS INT64 NO-UNDO.
      DEFINE RETURN PARAMETER iretcode AS INT64 NO-UNDO.
  END PROCEDURE.
  
  PROCEDURE uncompress EXTERNAL "{&zlib}" CDECL PERSISTENT: /* PRIVATE */
      DEFINE INPUT        PARAMETER pDestBuf    AS MEMPTR NO-UNDO.
      DEFINE INPUT-OUTPUT PARAMETER iDestSize   AS INT64 NO-UNDO.
      DEFINE INPUT        PARAMETER pSourceBuf  AS MEMPTR NO-UNDO.
      DEFINE INPUT        PARAMETER iSourceSize AS INT64 NO-UNDO.
      DEFINE RETURN PARAMETER iretcode AS INT64 NO-UNDO.
  END PROCEDURE.
  /* ---------------- End of External Zlib procedure definitions ------------- */

  /* Compress a piece of memory and return a pointer to the compressed data,
     in case of failure the size of compressed data = -1
  */
  METHOD PUBLIC MEMPTR Comprimir( INPUT ipmpDatos AS MEMPTR):
    DEFINE VARIABLE InputSize  AS INTEGER NO-UNDO.
    DEFINE VARIABLE OutputSize  AS INTEGER NO-UNDO.
    DEFINE VARIABLE TempBuffer AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE OutputBuffer AS MEMPTR  NO-UNDO.
    
    DEFINE VARIABLE retcode AS INT NO-UNDO.
  
    InputSize  = GET-SIZE(ipmpDatos).
    OutputSize = (InputSize * 1.01) + 12.
    SET-SIZE(TempBuffer) = OutputSize.
  
    RUN compress (TempBuffer,INPUT-OUTPUT OutputSize,ipmpDatos,InputSize,OUTPUT retcode) .
    
    IF retcode = 0 THEN DO:
      SET-SIZE(OutputBuffer) = OutputSize.
      OutputBuffer = GET-BYTES(TempBuffer, 1, OutputSize).
    END.
    ELSE 
       SET-SIZE(OutputBuffer) = 0.
  
    RETURN OutputBuffer.
    FINALLY:
      SET-SIZE(TempBuffer) = 0.
    END FINALLY.
  END METHOD.
  METHOD PUBLIC MEMPTR Comprimir( INPUT iplcDatos AS LONGCHAR ):
    DEFINE VARIABLE InputBuffer AS MEMPTR  NO-UNDO.
    
    COPY-LOB iplcDatos TO InputBuffer.
  
    RETURN Comprimir(InputBuffer).
    FINALLY:
      SET-SIZE(InputBuffer) = 0.
    END FINALLY.
	END METHOD.

  /* DeCompress a piece of memory and return a pointer to the decompressed data,
     in case of failure the size of decompressed data = -1
  */
  METHOD PUBLIC MEMPTR DescomprimirMP( INPUT ipmpDatos AS MEMPTR ):
    DEFINE VARIABLE InputSize  AS INTEGER NO-UNDO.
    DEFINE VARIABLE OutputSize  AS INTEGER NO-UNDO.
    DEFINE VARIABLE TempBuffer AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE OutputBuffer AS MEMPTR  NO-UNDO.
    
    DEFINE VARIABLE retcode AS INT NO-UNDO.
  
    InputSize  = GET-SIZE(ipmpDatos).
    OutputSize = (InputSize * 100).
    SET-SIZE(TempBuffer) = OutputSize.
  
    RUN uncompress (TempBuffer,INPUT-OUTPUT OutputSize,ipmpDatos,InputSize,OUTPUT retcode).
    
    IF retcode = 0 THEN DO:
      SET-SIZE(OutputBuffer) = OutputSize.
      OutputBuffer = GET-BYTES(TempBuffer, 1, OutputSize).
    END.
    ELSE
      SET-SIZE(OutputBuffer) = 0.
    RETURN OutputBuffer.
    FINALLY:
      SET-SIZE(TempBuffer) = 0.
    END FINALLY.
  END METHOD.
	METHOD PUBLIC LONGCHAR Descomprimir( INPUT ipmpDatos AS MEMPTR ):
    DEFINE VARIABLE OutputBuffer AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE mlcDatos AS LONGCHAR NO-UNDO.
    
    OutputBuffer = DescomprimirMP(ipmpDatos).
    IF GET-SIZE(OutputBuffer) GT 0 THEN DO ON ERROR UNDO, THROW:
      COPY-LOB OutputBuffer TO mlcDatos.
      CATCH pError AS Progress.Lang.Error :
        DELETE OBJECT pError.
        mlcDatos = ?.
      END CATCH.
    END.
    ELSE
       mlcDatos = ?.
    RETURN mlcDatos.
    FINALLY:
      SET-SIZE(OutputBuffer) = 0.
    END FINALLY.
	END METHOD.

  DESTRUCTOR FlateDecode():
    RELEASE EXTERNAL "{&zlib}".
  END DESTRUCTOR.
  
END CLASS.