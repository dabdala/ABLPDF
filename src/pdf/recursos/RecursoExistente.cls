{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : RecursoExistente
    Purpose     : Clase base de recursos
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 11:10:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.RecursoExistente IMPLEMENTS pdf.IObjetoPDF ABSTRACT:
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobDocumentoExistente AS pdf.DocumentoExistente NO-UNDO
    GET:
      RETURN CAST(cobDocumento,pdf.DocumentoExistente).
    END GET.
    
  DEFINE PROTECTED PROPERTY cobPDF AS pdf.utiles.PDFStream NO-UNDO
    GET.
    PRIVATE SET.

  DEFINE PUBLIC PROPERTY cinOriginal AS INTEGER EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinPadre AS INTEGER EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinPagina AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY chTipo AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchTexto AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchViejoTexto AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinNuevoObjeto AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinNuevaGeneracion AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcContenido AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcStream AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PRIVATE VARIABLE clgCambiandoNombre AS LOGICAL NO-UNDO.
  DEFINE PUBLIC PROPERTY cchNombre AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET(INPUT ipchNombre AS CHARACTER):
      IF clgCambiandoNombre THEN
        cchNombre = ipchNombre.
      ELSE DO:
        clgCambiandoNombre = TRUE.
        cambiarNombre(ipchNombre).
        clgCambiandoNombre = FALSE.
      END.
    END SET.
    
  CONSTRUCTOR RecursoExistente(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDF AS pdf.utiles.PDFStream):
    cobDocumento = ipobDocumento.
    cobPDF = ipobPDF.
    IF VALID-OBJECT(ipobDocumento:cobPaginaActual) THEN
      cinPagina = ipobDocumento:cobPaginaActual:cinNumero.
    ELSE
      cinPagina = 1.       
  END CONSTRUCTOR.
  
  METHOD PUBLIC VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    cinOriginal[1] = ipinObjeto.
    cinOriginal[2] = ipinGeneracion.
    cchNombre = ipchNombre.
  END METHOD.
  
  METHOD PROTECTED VOID cambiarNombre(INPUT ipchNombre AS CHARACTER):
    cchNombre = ipchNombre.
  END METHOD.
  
  METHOD PUBLIC ABSTRACT LOGICAL asignarObjetoPDF().
  
  METHOD PROTECTED VOID generarContenido():
    DEFINE VARIABLE mmpTmp AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpStream AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mchLength AS CHARACTER NO-UNDO.
    
    IF LENGTH(clcStream) GT 0 THEN DO:
      mmpTmp = BASE64-DECODE(clcStream).
      IF cobDocumentoExistente:clgCambiarMetodoCompresion AND VALID-OBJECT(cobDocumento:cobCompresor) THEN DO:
        mmpStream = cobDocumento:cobCompresor:Comprimir(mmpTmp).
        IF INDEX(clcContenido,'/Filter') GT 0 THEN DO:
          mchLength = SUBSTRING(clcContenido,INDEX(clcContenido,'/Filter')).
          mchLength = '/' + ENTRY(2,mchLength,'/') + '/' + ENTRY(3,mchLength,'/'). 
          clcContenido = REPLACE(clcContenido,mchLength,'/Filter/' + cobDocumento:cobCompresor:cchNombreMetodo).
        END.
        ELSE
          clcContenido = SUBSTRING(clcContenido,1,INDEX(clcContenido,'>>') - 1) + '/Filter/'  + cobDocumento:cobCompresor:cchNombreMetodo + '>>'.
      END.
      ELSE DO:
        mmpStream = mmpTmp.
        mmpTmp = ?.
        IF cobDocumentoExistente:clgCambiarMetodoCompresion AND INDEX(clcContenido,'/Filter') GT 0 THEN DO:
          mchLength = SUBSTRING(clcContenido,INDEX(clcContenido,'/Filter')).
          mchLength = '/' + ENTRY(2,mchLength,'/') + '/' + ENTRY(3,mchLength,'/'). 
          clcContenido = REPLACE(clcContenido,mchLength,'').
        END.
      END.
      IF INDEX(clcContenido,'/Length ') GT 0 THEN DO:
        mchLength = SUBSTRING(clcContenido,INDEX(clcContenido,'/Length ')).
        mchLength = ENTRY(2,mchLength,'/'). 
        clcContenido = REPLACE(clcContenido,mchLength,'Length ' + STRING(GET-SIZE(mmpStream))).
      END.      
      /* si era la última entrada, corregir el cierre del "inline stream" */
      IF INDEX(clcContenido,'>>') EQ 0 THEN
        clcContenido = clcContenido + '>>'.
      cobDocumento:cobDestino:agregar(clcContenido + 'stream' + {&pdfSKIP}).
      cobDocumento:cobDestino:agregar(mmpStream).
      cobDocumento:cobDestino:agregar({&pdfSKIP} + "endstream" + {&pdfSKIP}).
    END.
    ELSE
      cobDocumento:cobDestino:agregar(clcContenido).
    FINALLY:
      SET-SIZE(mmpTmp) = 0.
      SET-SIZE(mmpStream) = 0.
    END FINALLY.
  END METHOD.
  METHOD PUBLIC VOID generarDefinicion():
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDf).
    generarContenido().
    cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
  END METHOD.
END CLASS.