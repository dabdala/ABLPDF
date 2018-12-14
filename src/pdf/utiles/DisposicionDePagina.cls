 
 /*------------------------------------------------------------------------
    File        : DisposicionDePagina
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 10:08:17 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.DisposicionDePagina:
  DEFINE PUBLIC PROPERTY cenTipo AS pdf.tipos.DisposicionDePagina NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cenTipo) THEN
        cenTipo = NEW pdf.tipos.DisposicionDePagina().
      RETURN cenTipo.
    END GET.
    PRIVATE SET(INPUT ipobTipo AS pdf.tipos.DisposicionDepagina):
      IF ipobTipo EQ ? THEN
        DELETE OBJECT cenTipo NO-ERROR.
      cenTipo = ipobTipo.
    END SET.

  DEFINE PUBLIC PROPERTY cchTipoPDF AS CHARACTER NO-UNDO
    GET:
      RETURN cenTipo:Cual('OneColumn,TwoColumnLeft,TwoColumnRight,SinglePage').
    END GET.
    
  DESTRUCTOR DisposicionDePagina():
    cenTipo = ?.
  END DESTRUCTOR.
END CLASS.