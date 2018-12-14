 
 /*------------------------------------------------------------------------
    File        : Cadena
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 05 15:29:57 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.destinos.IDestino.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.destinos.Cadena IMPLEMENTS IDestino:
  DEFINE PUBLIC PROPERTY clcValor AS LONGCHAR NO-UNDO
    GET.
    PRIVATE SET.     

  DEFINE PUBLIC PROPERTY clgAceptaBinario AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
     
	METHOD PUBLIC VOID agregar( INPUT ipchTexto AS CHARACTER ):
	  IF ipchTexto NE ? THEN
		  clcValor = clcValor + ipchTexto.
	END METHOD.
  METHOD PUBLIC VOID agregar( INPUT ipmpBinario AS MEMPTR):
    clcValor = clcValor + BASE64-ENCODE(ipmpBinario).
  END METHOD.

	METHOD PUBLIC VOID agregar( INPUT iplcTexto AS LONGCHAR ):
	  IF iplcTexto NE ? THEN
	   clcValor = clcValor + iplcTexto.
	END METHOD.

	METHOD PUBLIC LOGICAL finalizar(  ):
	  RETURN TRUE.
	END METHOD.

	METHOD PUBLIC LOGICAL iniciar(  ):
		clcValor = ''.
		RETURN TRUE.
	END METHOD.

  METHOD PUBLIC INT64 posicion():
    RETURN LENGTH(clcValor,'RAW':u).
  END METHOD.
END CLASS.