{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Orientacion
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 08:11:17 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.Orientacion INHERITS pdf.tipos.ENUM FINAL:
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Vertical,Apaisada'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY Vertical AS INTEGER NO-UNDO INITIAL 0 GET.
  DEFINE PUBLIC STATIC PROPERTY Apaisada AS INTEGER NO-UNDO INITIAL 1 GET.
END CLASS.