{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : ObjetoX
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 11:10:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.ObjetoX INHERITS pdf.recursos.RecursoExistente:
  DEFINE PRIVATE VARIABLE cobEspacioDeColores AS pdf.recursos.RecursoExistente NO-UNDO.
  
  CONSTRUCTOR ObjetoX(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDF AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.  
  
  METHOD PROTECTED OVERRIDE VOID cambiarNombre(INPUT ipchNombre AS CHARACTER):
    clcContenido = REPLACE(clcContenido,'~/Name ' + cchNombre,'~/Name ' + ipchNombre).
    SUPER:cambiarNombre(ipchNombre).
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE mliLen AS INT64 NO-UNDO.
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchLen AS CHARACTER NO-UNDO.
    
    SUPER:LoadFromStream(ipinObjeto,ipinGeneracion,ipchNombre).
    cobPDF:preservarPos().
    IF VALID-OBJECT(cobDocumentoExistente:cobPaginaActual) THEN
      minPagina = cobDocumentoExistente:cobPaginaActual:cinNumero.
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,ipinObjeto,ipinGeneracion,"~/XObject",minPagina).
    mchLen = cobPDF:leerLength(cobDocumentoExistente:posicionObjeto(ipinObjeto,ipinGeneracion)).
    IF NUM-ENTRIES(mchLen,' ') GT 1 THEN
      mliLen = cobDocumentoExistente:DetermineLength (THIS-OBJECT,INT(ENTRY(1, mchLen, " ")),INT(ENTRY(2, mchLen, " "))).
    ELSE
      mliLen = INT(mchLen) NO-ERROR.
       
    IF mliLen GT 0 THEN
      clcStream = cobDocumentoExistente:StreamContent(ipinObjeto,ipinGeneracion,TRUE).
    clcContenido = cobDocumentoExistente:objectContent(ipinObjeto,ipinGeneracion).
    /* preservar para su reemplazo */
    minPagina = INDEX(clcContenido,'~/ColorSpace').
    IF minPagina GT 0 THEN DO:
      mchLen = TRIM(SUBSTR(clcContenido,minPagina,64)).
      cobEspacioDeColores = cobDocumentoExistente:agregarRecurso(INT(ENTRY(2, mchLen, " ")),INT(ENTRY(3, mchLen, " ")),"ColorSpace",ipinObjeto,ipinGeneracion,'').
    END.  
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('XObject').
    RETURN TRUE.
  END METHOD.
  METHOD PROTECTED OVERRIDE VOID generarContenido():
    /* reemplazar las referencias a objetos */
    IF VALID-OBJECT(cobEspacioDeColores) THEN DO:
      cobEspacioDeColores:asignarObjetoPDF().
      clcContenido = REPLACE(clcContenido,
                         "~/ColorSpace " + STRING(cobEspacioDeColores:cinOriginal[1]) + ' ' + STRING(cobEspacioDeColores:cinOriginal[2]),
                         "~/ColorSpace " + STRING(cobEspacioDeColores:cinObjetoPDF) + ' 0').
    END.
    SUPER:generarContenido().
  END METHOD.
END CLASS.