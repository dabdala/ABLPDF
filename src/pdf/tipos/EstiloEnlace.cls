{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EstiloEnlace
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 11:49:40 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.EstiloEnlace INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'N,I,O,P'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY N AS INTEGER INITIAL 0 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY I AS INTEGER INITIAL 1 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY O AS INTEGER INITIAL 2 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY P AS INTEGER INITIAL 3 NO-UNDO GET.
END CLASS.