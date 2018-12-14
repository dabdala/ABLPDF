 
 /*------------------------------------------------------------------------
    File        : ModoVisualizacion
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 10:03:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.ModoVisualizacion:
  DEFINE PUBLIC PROPERTY cenTipo AS pdf.tipos.ModoVisualizacion NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cenTipo) THEN
        cenTipo = NEW pdf.tipos.ModoVisualizacion().
      RETURN cenTipo.
    END GET.
    PRIVATE SET(INPUT ipobModo AS pdf.tipos.ModoVisualizacion):
      IF ipobModo EQ ? THEN
        DELETE OBJECT cenTipo NO-ERROR.
      cenTipo = ipobModo.
    END SET.
    
  DEFINE PUBLIC PROPERTY cchTipoPDF AS CHARACTER NO-UNDO
    GET:
      RETURN cenTipo:Cual('UseOutlines,UseThumbs,FullScreen,UseNone').
    END GET.
    
  DESTRUCTOR ModoVisualizacion():
    cenTipo = ?.
  END DESTRUCTOR.
END CLASS.