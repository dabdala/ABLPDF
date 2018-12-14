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

CLASS pdf.recursos.EspacioDeColores INHERITS pdf.recursos.RecursoExistente:
  DEFINE PRIVATE VARIABLE cobSeparation AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobSeparation2 AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobIndexed AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobIndexed2 AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobICCBased AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobDeviceCMYK AS pdf.recursos.RecursoExistente NO-UNDO.
  DEFINE PRIVATE VARIABLE cobR11 AS pdf.recursos.RecursoExistente NO-UNDO.
  
  CONSTRUCTOR EspacioDeColores(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDf AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.  
  
  METHOD PUBLIC OVERRIDE VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE text-ptr    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE base-font   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_Entries   AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE descriptor  AS LOGICAL NO-UNDO.
  
    DEFINE VARIABLE obj-ptr   AS INTEGER NO-UNDO.
    DEFINE VARIABLE gen-ptr   AS INTEGER NO-UNDO.
    SUPER:LoadFromStream(ipinObjeto,ipinGeneracion,ipchNombre).
    cobPDF:preservarPos().
    IF VALID-OBJECT(cobDocumentoExistente:cobPaginaActual) THEN
      obj-ptr = cobDocumentoExistente:cobPaginaActual:cinNumero.
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,ipinObjeto,ipinGeneracion,"~/ColorSpace",obj-ptr).
    clcContenido = cobDocumentoExistente:ObjectContent(ipinObjeto,ipinGeneracion).
    cobPDF:SeekPos(cobDocumentoExistente:posicionObjeto(ipinObjeto,ipinGeneracion)).
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().

      IF INDEX(text-ptr,"~/Separation") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Separation"))).

        /* Output Separation ColorSpace */
        ASSIGN obj-ptr = INT(ENTRY(3, text-temp, " "))
               gen-ptr = INT(ENTRY(4, text-temp, " ")) NO-ERROR.

        IF NOT ERROR-STATUS:ERROR THEN DO:
          cobSeparation = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"SeparationColorSpace",ipinObjeto,ipinGeneracion,'').
        
          /* Output Separation ColorSpace */
          ASSIGN obj-ptr = INT(ENTRY(6, text-temp, " "))
                 gen-ptr = INT(ENTRY(7, text-temp, " ")).

          cobSeparation2 = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"SeparationColorSpace",ipinObjeto,ipinGeneracion,'').
        END. /* Not Error */
      END. /* Separation */

      IF INDEX(text-ptr,"~/ICCBased") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/ICCBased"))).
        ASSIGN obj-ptr = INT(ENTRY(2, text-temp, " "))
               gen-ptr = INT(ENTRY(3, text-temp, " ")).

        cobICCBased = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"ICCBased",ipinObjeto,ipinGeneracion,'').
      END.

      IF INDEX(text-ptr,"~/DeviceCMYK") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/DeviceCMYK"))).
        ASSIGN obj-ptr = INT(ENTRY(2, text-temp, " "))
               gen-ptr = INT(ENTRY(3, text-temp, " ")).

        cobDeviceCMYK = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"DeviceCMYK",ipinObjeto,ipinGeneracion,'').
      END.

      IF INDEX(text-ptr,"~/R11") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/R11"))).
        ASSIGN obj-ptr = INT(ENTRY(2, text-temp, " "))
               gen-ptr = INT(ENTRY(3, text-temp, " ")).

        cobR11 = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"R11",ipinObjeto,ipinGeneracion,'').
      END.

      IF INDEX(text-ptr,"~/Indexed") > 0 THEN DO:
        /*
        pueden ser dos objetos: [/Indexed o1 g1 R N o2 g2 R]
        o puede ser una combinación donde el primero o el segundo no es una referencia a objeto
        [/Indexed /DeviceRGB N o2 g2 R]
        [/Indexed o1 g1 R N <<>>]
        */
        text-ptr = TRIM(text-ptr).
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Indexed"))).

        ERROR-STATUS:ERROR = FALSE.
        ASSIGN obj-ptr = INT(ENTRY(2, text-temp, " "))
               gen-ptr = INT(ENTRY(3, text-temp, " "))
               NO-ERROR.

        IF NOT ERROR-STATUS:ERROR THEN DO:
          cobIndexed = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"Indexed",ipinObjeto,ipinGeneracion,'').
          ERROR-STATUS:ERROR = FALSE.
          /* Process Lookup */
          ASSIGN obj-ptr = INT(ENTRY(6, text-temp, " "))
                 gen-ptr = INT(ENTRY(7, text-temp, " "))
                 NO-ERROR.
        END.
        ELSE ASSIGN obj-ptr = INT(ENTRY(4, text-temp, " "))
           gen-ptr = INT(ENTRY(5, text-temp, " "))
           NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN
          cobIndexed2 = cobDocumentoExistente:agregarRecurso(obj-ptr,gen-ptr,"Indexed",ipinObjeto,ipinGeneracion,'').
      END.

      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END. /* True */
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcessColorSpaceDictionary */
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('ColorSpace').
    RETURN TRUE.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDefinicion():
    DEFINE VARIABLE mchOriginal AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchReemplazo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minInicio AS INTEGER NO-UNDO.
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).
    /* Change Indexed object for GIF Images */
    IF VALID-OBJECT(cobIndexed) OR VALID-OBJECT(cobIndexed2) THEN DO:
      minInicio = INDEX(clcContenido,'~/Indexed').
      mchOriginal = SUBSTRING(clcContenido,minInicio,INDEX(clcContenido,']',minInicio) - minInicio).
      mchReemplazo = mchOriginal.
      IF VALID-OBJECT(cobIndexed) THEN DO:
        cobIndexed:asignarObjetoPDF().
        ENTRY(2,mchReemplazo,' ') = STRING(cobIndexed:cinObjetoPDF). 
        ENTRY(3,mchReemplazo,' ') = '0'.
      END.
      IF VALID-OBJECT(cobIndexed2) THEN DO:
        cobIndexed2:asignarObjetoPDF().
        IF VALID-OBJECT(cobIndexed) THEN ASSIGN
          ENTRY(6,mchReemplazo,' ') = STRING(cobIndexed2:cinObjetoPDF) 
          ENTRY(7,mchReemplazo,' ') = '0'
        {&END}
        ELSE ASSIGN
          ENTRY(4,mchReemplazo,' ') = STRING(cobIndexed2:cinObjetoPDF) 
          ENTRY(5,mchReemplazo,' ') = '0'
        {&END}
      END.
      clcContenido = REPLACE(clcContenido,mchOriginal,mchReemplazo).
    END.
    IF VALID-OBJECT(cobSeparation) THEN DO:
      cobSeparation:asignarObjetoPDF().
      cobSeparation2:asignarObjetoPDF().
      minInicio = INDEX(clcContenido,'~/Separation').
      mchOriginal = SUBSTRING(clcContenido,minInicio,INDEX(clcContenido,']',minInicio) - minInicio).
      mchReemplazo = mchOriginal.
      ENTRY(2,mchReemplazo,' ') = STRING(cobSeparation:cinObjetoPDF). 
      ENTRY(3,mchReemplazo,' ') = '0'.
      ENTRY(6,mchReemplazo,' ') = STRING(cobSeparation2:cinObjetoPDF). 
      ENTRY(7,mchReemplazo,' ') = '0'.
      clcContenido = REPLACE(clcContenido,mchOriginal,mchReemplazo).      
    END.
    IF VALID-OBJECT(cobICCBased) THEN DO:
      cobICCBased:asignarObjetoPDF().
      clcContenido = REPLACE(clcContenido,
                         "~/ICCBased " + STRING(cobICCBased:cinOriginal[1]) + ' ' + STRING(cobICCBased:cinOriginal[2]),
                         "~/ICCBased " + STRING(cobICCBased:cinObjetoPDF) + ' 0').
    END.
    IF VALID-OBJECT(cobDeviceCMYK) THEN DO:
      cobDeviceCMYK:asignarObjetoPDF().
      clcContenido = REPLACE(clcContenido,
                         "~/DeviceCMYK " + STRING(cobDeviceCMYK:cinOriginal[1]) + ' ' + STRING(cobDeviceCMYK:cinOriginal[2]),
                         "~/DeviceCMYK " + STRING(cobDeviceCMYK:cinObjetoPDF) + ' 0').
    END.
    IF VALID-OBJECT(cobR11) THEN DO:
      cobR11:asignarObjetoPDF().
      clcContenido = REPLACE(clcContenido,
                         "~/R11 " + STRING(cobR11:cinOriginal[1]) + ' ' + STRING(cobR11:cinOriginal[2]),
                         "~/R11 " + STRING(cobR11:cinObjetoPDF) + ' 0').
    END.
    cobDocumento:cobDestino:agregar(clcContenido + {&pdfSKIP}).
    cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
    IF VALID-OBJECT(cobIndexed) THEN DO:
      cobIndexed:generarDefinicion().
      cobIndexed2:generarDefinicion().
    END.
    IF VALID-OBJECT(cobSeparation) THEN DO:
      cobSeparation:generarDefinicion().
      cobSeparation2:generarDefinicion().
    END.
    IF VALID-OBJECT(cobICCBased) THEN
      cobICCBased:generarDefinicion().
    IF VALID-OBJECT(cobDeviceCMYK) THEN
      cobDeviceCMYK:generarDefinicion().
    IF VALID-OBJECT(cobR11) THEN
      cobR11:generarDefinicion().
  END METHOD.
END CLASS.