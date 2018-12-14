{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : DisposicionDePagina
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 07:42:29 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.DisposicionDePagina INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'PaginaSimple,UnaColumna,DosColumnasIzquierda,DosColumnasDerecha'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY PaginaSimple AS INTEGER INITIAL 0 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY UnaColumna AS INTEGER INITIAL 1 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY DosColumnasIzquierda AS INTEGER INITIAL 2 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY DosColumnasDerecha AS INTEGER INITIAL 3 NO-UNDO GET.
END CLASS.