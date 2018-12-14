
/*------------------------------------------------------------------------
    File        : IObjetoPDF
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 05 19:07:26 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

INTERFACE pdf.IObjetoPDF:  
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
  METHOD PUBLIC LOGICAL asignarObjetoPDF().
END INTERFACE.