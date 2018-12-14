{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : TipoEnlace
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 07:32:27 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.Enlace INHERITS pdf.tipos.ENUM FINAL: 
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Enlace,Texto,Marca,Resaltado,Subrayado,Rulitos,Tachado'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY Enlace AS INTEGER INITIAL 0 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Texto AS INTEGER INITIAL 1 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Marca AS INTEGER INITIAL 2 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Resaltado AS INTEGER INITIAL 3 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Subrayado AS INTEGER INITIAL 4 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Rulitos AS INTEGER INITIAL 5 NO-UNDO GET.
  DEFINE PUBLIC STATIC PROPERTY Tachado AS INTEGER INITIAL 6 NO-UNDO GET.
END CLASS.