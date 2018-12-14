{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Letra
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 08:29:46 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.Letra INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'AnchoFijo,AnchoVariable'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY AnchoFijo AS INTEGER INITIAL 0 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY AnchoVariable AS INTEGER INITIAL 1 NO-UNDO GET.
END CLASS.