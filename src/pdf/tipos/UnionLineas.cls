{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : UnionLineas
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 10:27:47 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.UnionLineas INHERITS pdf.tipos.ENUM FINAL:
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Recta,Redondeada,EnDesnivel'.
  END METHOD.
END CLASS.