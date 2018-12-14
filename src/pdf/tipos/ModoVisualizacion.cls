{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : ModoVisualizacion
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 07:47:53 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.ModoVisualizacion INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Ninguno,LineasGuia,Solapas,PantallaCompleta'.
  END METHOD.    
  DEFINE PUBLIC STATIC PROPERTY Ninguno AS INTEGER INITIAL 0 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY LineasGuia AS INTEGER INITIAL 1 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Solapas AS INTEGER INITIAL 2 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY PantallaCompleta AS INTEGER INITIAL 3 NO-UNDO GET.
END CLASS.