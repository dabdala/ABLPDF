{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EspacioDeColores
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 11:10:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.ContenidoSimple INHERITS pdf.recursos.RecursoExistente ABSTRACT:
  CONSTRUCTOR ContenidoSimple(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDf AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.
    
  METHOD PUBLIC OVERRIDE VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    SUPER:LoadFromStream(ipinObjeto,ipinGeneracion,ipchNombre).
    cobPDF:preservarPos().
    IF VALID-OBJECT(cobDocumentoExistente:cobPaginaActual) THEN
      minPagina = cobDocumentoExistente:cobPaginaActual:cinNumero.
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,ipinObjeto,ipinGeneracion,tipoObjeto(),minPagina).
    obtenerContenido(ipinObjeto, ipinGeneracion).
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED VOID obtenerContenido(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    DEFINE VARIABLE mlcContenido AS LONGCHAR NO-UNDO.
    clcContenido = cobDocumentoExistente:ObjectContent(ipinObjeto,ipinGeneracion).
    clcStream = cobDocumentoExistente:StreamContent(ipinObjeto,ipinGeneracion,TRUE).
  END METHOD.
  
  METHOD PROTECTED ABSTRACT CHARACTER tipoObjeto().
  
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto(SUBSTRING(tipoObjeto(),2)).
    RETURN TRUE.
  END METHOD.
  
END CLASS.