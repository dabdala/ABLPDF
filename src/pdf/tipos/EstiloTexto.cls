{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EstiloTexto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 11 08:09:36 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.EstiloTexto INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'ColorDeRelleno,ColorDePincel,AmbosColores,Invisible'.
  END METHOD.
END CLASS.