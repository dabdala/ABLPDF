{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Transformación posible del texto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 08:56:40 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.Transformacion INHERITS pdf.tipos.ENUM FINAL:
  METHOD PROTECTED OVERRIDE CHARACTER NombresEnum():
    RETURN 'Espejar,Escalar,Inclinar,Mover,Rotar,EspejarEnX,EspejarEnY,EscalarEnX,EscalarEnY'.
  END METHOD.
  
  DEFINE PUBLIC STATIC PROPERTY Espejar AS INTEGER NO-UNDO INITIAL 0 GET.
  DEFINE PUBLIC STATIC PROPERTY Escalar AS INTEGER NO-UNDO INITIAL 1 GET.
  DEFINE PUBLIC STATIC PROPERTY Inclinar AS INTEGER NO-UNDO INITIAL 2 GET.
  DEFINE PUBLIC STATIC PROPERTY Mover AS INTEGER NO-UNDO INITIAL 3 GET.
  DEFINE PUBLIC STATIC PROPERTY Rotar AS INTEGER NO-UNDO INITIAL 4 GET.
  DEFINE PUBLIC STATIC PROPERTY EspejarEnX AS INTEGER NO-UNDO INITIAL 5 GET.
  DEFINE PUBLIC STATIC PROPERTY EspejarEnY AS INTEGER NO-UNDO INITIAL 6 GET.
  DEFINE PUBLIC STATIC PROPERTY EscalarEnX AS INTEGER NO-UNDO INITIAL 7 GET.
  DEFINE PUBLIC STATIC PROPERTY EscalarEnY AS INTEGER NO-UNDO INITIAL 8 GET.
END CLASS.