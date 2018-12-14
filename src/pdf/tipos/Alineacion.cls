{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Alineacion
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 08:56:40 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.Alineacion INHERITS pdf.tipos.ENUM FINAL:
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Izquierda,Derecha,Centrado'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY Izquierda AS INTEGER NO-UNDO INITIAL 0 GET.
  DEFINE PUBLIC STATIC PROPERTY Derecha AS INTEGER NO-UNDO INITIAL 1 GET.
  DEFINE PUBLIC STATIC PROPERTY Centrado AS INTEGER NO-UNDO INITIAL 2 GET.
END CLASS.