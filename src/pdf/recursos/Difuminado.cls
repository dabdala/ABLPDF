{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Difuminado
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 11:10:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.Difuminado INHERITS pdf.recursos.RecursoExistente:
  DEFINE PRIVATE VARIABLE cobFuncion AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobEspacioDeColores AS pdf.recursos.RecursoExistente NO-UNDO.
  
  CONSTRUCTOR Difuminado(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDF AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.  
  
  METHOD PUBLIC OVERRIDE VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  
    SUPER:LoadFromStream(ipinObjeto,ipinGeneracion,ipchNombre).
    cobPDF:preservarPos().
    IF VALID-OBJECT(cobDocumentoExistente:cobPaginaActual) THEN
      minPagina = cobDocumentoExistente:cobPaginaActual:cinNumero.    
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,ipinObjeto,ipinGeneracion,"~/Shading",minPagina).
    clcContenido = cobDocumentoExistente:ObjectContent(ipinObjeto,ipinGeneracion).
      
    minPagina = INDEX(clcContenido,'~/ColorSpace').
    IF minPagina GT 0 THEN DO:
      mchPorcion = TRIM(SUBSTR(clcContenido,minPagina,64)).
      cobEspacioDeColores = cobDocumentoExistente:agregarRecurso(INT(ENTRY(2, mchPorcion, " ")),INT(ENTRY(3, mchPorcion, " ")),"ColorSpace",ipinObjeto,ipinGeneracion,'').
    END.
    minPagina = INDEX(clcContenido,"~/Function").  
    IF minPagina GT 0 THEN DO:
      mchPorcion = TRIM(SUBSTR(clcContenido,minPagina,64)).
      cobFuncion = cobDocumentoExistente:agregarRecurso(INT(ENTRY(2, mchPorcion, " ")),INT(ENTRY(3, mchPorcion, " ")),"Function",ipinObjeto,ipinGeneracion,'').
    END.
      
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.  
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('Shading').
    RETURN TRUE.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDefinicion():
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDf).

    IF VALID-OBJECT(cobFuncion) THEN DO:
      cobFuncion:asignarObjetoPDF().      
      clcContenido = REPLACE(clcContenido,
                                   "~/Function " + STRING(cobFuncion:cinOriginal[1]) + ' ' + STRING(cobFuncion:cinOriginal[2]),
                                   "~/Function " + STRING(cobFuncion:cinObjetoPDF) + ' 0').
    END.
    IF VALID-OBJECT(cobEspacioDeColores) THEN DO:
      cobEspacioDeColores:asignarObjetoPDF().
      clcContenido = REPLACE(clcContenido,
                         "~/ColorSpace " + STRING(cobEspacioDeColores:cinOriginal[1]) + ' ' + STRING(cobEspacioDeColores:cinOriginal[2]),
                         "~/ColorSpace " + STRING(cobEspacioDeColores:cinObjetoPDF) + ' 0').
    END.
    cobDocumento:cobDestino:agregar(clcContenido).
    cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
    IF VALID-OBJECT(cobFuncion) THEN
      cobFuncion:generarDefinicion().    
  END METHOD.
END CLASS.