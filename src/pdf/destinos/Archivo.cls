{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Archivo
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 05 15:23:26 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.destinos.IDestino.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.destinos.Archivo IMPLEMENTS IDestino:
  
  DEFINE PRIVATE STREAM stArchivo.
  DEFINE PRIVATE VARIABLE clgAbierto AS LOGICAL NO-UNDO.
  
  DEFINE PUBLIC PROPERTY cchRuta AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY clgAceptaBinario AS LOGICAL INITIAL TRUE NO-UNDO
    GET. 

	METHOD PUBLIC VOID agregar( INPUT ipchTexto AS CHARACTER ):
    IF NOT clgAbierto THEN
     iniciar().
		PUT STREAM stArchivo UNFORMATTED ipchTexto.
	END METHOD.
  METHOD PUBLIC VOID agregar( INPUT ipmpBinario AS MEMPTR):
    IF NOT clgAbierto THEN
     iniciar().
    EXPORT STREAM stArchivo ipmpBinario.
  END METHOD.

	METHOD PUBLIC VOID agregar( INPUT iplcTexto AS LONGCHAR ):
		DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
		DEFINE VARIABLE minLongitud AS INT64 NO-UNDO.
		DEFINE VARIABLE minInicio AS INT64 INITIAL 1 NO-UNDO.
		DEFINE VARIABLE minPorcion AS INT64 NO-UNDO.

    IF NOT clgAbierto THEN
     iniciar().
    minLongitud = LENGTH(iplcTexto).
    DO WHILE minInicio LE minLongitud:
      minPorcion = minLongitud - minInicio + 1.
      IF minPorcion GT 30000 THEN
        minPorcion = 30000.
      mchPorcion = SUBSTRING(iplcTexto,minInicio,minPorcion).
      PUT STREAM stArchivo UNFORMATTED mchPorcion.
      minInicio = minInicio + minPorcion.
    END.    
	END METHOD.

	METHOD PUBLIC LOGICAL finalizar(  ):
	  IF NOT clgAbierto THEN
	   RETURN FALSE.
	  OUTPUT STREAM stArchivo CLOSE.
	  clgAbierto = FALSE.
	  RETURN TRUE.
	END METHOD.

	METHOD PUBLIC LOGICAL iniciar(  ):
	  IF clgAbierto THEN
	   RETURN FALSE.	
	  clgAbierto = TRUE.  
		OUTPUT STREAM stArchivo TO VALUE(cchRuta) BINARY UNBUFFERED NO-CONVERT.
		RETURN TRUE.
	END METHOD.

  METHOD PUBLIC INT64 posicion():
    RETURN SEEK(stArchivo).
  END METHOD.
  
  CONSTRUCTOR PUBLIC Archivo():
    SUPER().
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC Archivo(INPUT ipchRuta AS CHARACTER):
    SUPER().
    cchRuta = ipchRuta.
  END CONSTRUCTOR.
END CLASS.