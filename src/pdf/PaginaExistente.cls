{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : PaginaExistente
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 13 09:17:08 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.Pagina.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.PaginaExistente INHERITS Pagina:
  DEFINE PROTECTED PROPERTY cobPDF AS pdf.utiles.PDFStream NO-UNDO
    GET.
    PRIVATE SET.
  
  DEFINE PUBLIC PROPERTY cobDocumentoExistente AS pdf.DocumentoExistente NO-UNDO
    GET:
      RETURN CAST(cobDocumento,pdf.DocumentoExistente).
    END GET.
    
  DEFINE PROTECTED PROPERTY clgContenidoRearmado AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
 
  DEFINE PUBLIC PROPERTY cchFiltroCompresion AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgComprimida AS LOGICAL NO-UNDO
    GET:
      RETURN cchFiltroCompresion NE ''.
    END.
    
  DEFINE PUBLIC PROPERTY cinDiccionarioRecursos AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.    
  DEFINE PUBLIC PROPERTY cchFont AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchXObjects AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchExtGState AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchColorSpace AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchShading AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchNombreXObject AS CHARACTER INITIAL '' NO-UNDO
    GET:
      IF cchNombreXObject EQ '' THEN
        cchNombreXObject = 'Pext' + STRING(cinNumero).
      RETURN cchNombreXObject.
    END GET.
    PRIVATE SET.

  CONSTRUCTOR PUBLIC PaginaExistente(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDF AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento).
    cobPDF = ipobPDF.
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC PaginaExistente(INPUT ipobDocumento AS pdf.Documento,INPUT ipobPagina AS pdf.PaginaExistente):
    SUPER(ipobDocumento).
    cchFiltroCompresion = ipobPagina:cchFiltroCompresion.
    cinDiccionarioRecursos = ipobPagina:cinDiccionarioRecursos.    
    cchFont = ipobPagina:cchFont.
    cchXObjects = ipobPagina:cchFont.
    cchExtGState = ipobPagina:cchExtGState.
    cchColorSpace = ipobPagina:cchColorSpace.
    cchShading = ipobPagina:cchShading.
  END CONSTRUCTOR.
  
  METHOD PROTECTED VOID ProcessBoxObject(INPUT pObject AS INTEGER, INPUT pGen AS INTEGER, INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE minIPos AS INT64 NO-UNDO.
    
    minIPos = cobPDF:SeekPos(?).
    cobPDF:SeekPos(cobDocumentoExistente:posicionObjeto(pObject,pGen)).
    cobPDF:ProcessBoxObject(ipobArea).
    FINALLY:
      cobPDF:SeekPos(minIPOs).
    END FINALLY.
  END METHOD.  /* ProcessMediaBox */
  
  
  METHOD PUBLIC VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchContents  AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE curr-ptr  AS INTEGER NO-UNDO.
    DEFINE VARIABLE iRotate   AS INTEGER NO-UNDO.
    
    DEFINE VARIABLE res-obj   AS INTEGER NO-UNDO. /* Resources */
    DEFINE VARIABLE res-gen   AS INTEGER NO-UNDO.
    DEFINE VARIABLE obj-cnt   AS INTEGER NO-UNDO.
    DEFINE VARIABLE con-obj   AS INTEGER NO-UNDO. /* Contents */
    DEFINE VARIABLE con-gen   AS INTEGER NO-UNDO.
  
    cobPDF:preservarPos().
    cobPDF:SeekPos(cobDocumentoExistente:posicionObjeto(ipinObjeto,ipinGeneracion)).
    DO WHILE TRUE:
        text-ptr = cobPDF:readline().

        IF INDEX(text-ptr,"~/MediaBox") > 0 THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/MediaBox")).
          text-temp = REPLACE(text-temp,"/MediaBox","").
          text-temp = REPLACE(text-temp,"[","").
          text-temp = SUBSTRING(text-temp,1,INDEX(text-temp,"]") - 1).

          /* If MediaBox is an Object then find the object and return the 
             MediaBox directives */
          IF ENTRY(3,text-temp," ") = "R" THEN
            ProcessBoxObject(INT(ENTRY(1,text-temp," ") ),INT(ENTRY(2,text-temp," ") ),cobMargenes).
          ELSE ASSIGN
            cobMargenes:cinIzquierda = INT(ENTRY(1,text-temp, " "))
            cobMargenes:cinAbajo = INT(ENTRY(2,text-temp, " "))
            cobMargenes:cinDerecha = INT(ENTRY(3,text-temp, " "))
            cobMargenes:cinArriba = INT(ENTRY(4,text-temp, " "))
          {&END}
        END. /* MediaBox */

        IF INDEX(text-ptr,"~/CropBox") > 0 THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/CropBox")).
          text-temp = REPLACE(text-temp,"/CropBox","").
          text-temp = REPLACE(text-temp,"[","").
          text-temp = SUBSTRING(text-temp,1,INDEX(text-temp,"]") - 1).

          /* If CropBox is an Object then find the object and return the 
             CropBox directives */
          IF ENTRY(3,text-temp," ") = "R" THEN
            ProcessBoxObject(INT(ENTRY(1,text-temp," ") ),INT(ENTRY(2,text-temp," ") ),cobAreaDeCorte).
          ELSE ASSIGN
            cobAreaDeCorte:cinIzquierda = INT(ENTRY(1,text-temp, " "))
            cobAreaDeCorte:cinAbajo = INT(ENTRY(2,text-temp, " "))
            cobAreaDeCorte:cinDerecha = INT(ENTRY(3,text-temp, " "))
            cobAreaDeCorte:cinArriba = INT(ENTRY(4,text-temp, " "))
          {&END}
        END. /* CropBox */

        IF INDEX(text-ptr,"~/Rotate") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Rotate"))).
          text-temp = TRIM(REPLACE(text-temp,"~/Rotate","")).

          IF INDEX(text-temp,"~/") > 0 THEN
            iRotate = INT(TRIM(SUBSTR(text-temp,1,INDEX(text-temp,"~/") - 1))).
          ELSE
            iRotate = INT(text-temp) NO-ERROR.

          cinRotacion = iRotate.
        END.

        IF INDEX(text-ptr,"~/Font") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Font"))).
          cchFont = cobDocumentoExistente:ProcessEntry (ipinObjeto,ipinGeneracion,"Font"). 
        END.

        IF INDEX(text-ptr,"~/Resources") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Resources"))).

          IF INDEX(text-temp, "~/Resources<<") = 0 
          AND INDEX(text-temp, "~/Resources <<") = 0 THEN DO:
            ASSIGN res-obj = INT(ENTRY(2, text-temp, " "))
                   res-gen = INT(ENTRY(3, text-temp, " ")) NO-ERROR.

            IF ERROR-STATUS:ERROR THEN NEXT.
            cinDiccionarioRecursos = res-obj.
            cobDocumentoExistente:ProcessResourceDictionary(res-obj, res-gen).
          END.
        END.

        IF INDEX(text-ptr,"~/Contents") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Contents"))).
          mchContents = REPLACE(text-temp,"~/Contents","").
          IF INDEX(mchContents,"~/") > 0 THEN
            mchContents = SUBSTR(mchContents,1,INDEX(mchContents,"~/") - 1).

          mchContents = REPLACE(mchcontents,"[","").
          mchcontents = REPLACE(mchcontents,"]","").
          mchcontents = TRIM(mchcontents).

          /* This is a temporary holder for the page content */
          clgContenidoRearmado =  NUM-ENTRIES(mchContents,' ') GT 3.
          DO obj-cnt = 1 TO NUM-ENTRIES(mchcontents," ") BY 3:

            ASSIGN con-obj = INT(ENTRY(obj-cnt, mchcontents, " "))
                   con-gen = INT(ENTRY(obj-cnt + 1, mchcontents, " ")) NO-ERROR.

            IF ERROR-STATUS:ERROR THEN NEXT.

            ProcessContent (obj-cnt, con-obj, con-gen).
          END.
        END.

        IF INDEX(text-ptr,"~/Xobject") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/XObject"))).
          cchXObjects = cobDocumentoExistente:ProcessEntry (ipinObjeto,ipinGeneracion,"XObject").
        END.

        IF INDEX(text-ptr,"~/ExtGState") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/ExtGState"))).
          cchExtGState = cobDocumentoExistente:ProcessEntry (ipinObjeto,ipinGeneracion,"ExtGState").
        END.

        IF INDEX(text-ptr,"~/ColorSpace") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/ColorSpace"))).
          cchColorSpace = cobDocumentoExistente:ProcessEntry (ipinObjeto,ipinGeneracion,"ColorSpace").
        END.

        IF INDEX(text-ptr,"~/Shading") > 0  THEN DO:
          text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Shading"))).
          cchShading = cobDocumentoExistente:ProcessEntry (ipinObjeto,ipinGeneracion,"Shading").
        END.

        IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
      END.      
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.  

  METHOD PROTECTED VOID ProcessContent(INPUT pCounter AS INTEGER, INPUT pObject  AS INTEGER, INPUT pGen     AS INTEGER):
    DEFINE VARIABLE text-ptr    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-sub    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp   AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE obj-cnt     AS INTEGER NO-UNDO.
    DEFINE VARIABLE con-obj     AS INTEGER NO-UNDO.
    DEFINE VARIABLE con-gen     AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE L_Length    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Ptr       AS INT64 NO-UNDO.
  
    DEFINE VARIABLE Entry4 AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mmpContenido AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mifCompresor AS pdf.compresores.ICompresor NO-UNDO.

    cobPDF:preservarPos().
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,pObject,pGen,"~/Content",cinNumero).
    L_Ptr = cobDocumentoExistente:posicionObjeto(pObject,pGen).
    /* Find Length */
    text-temp = cobPDF:leerLength(L_Ptr).
    IF NUM-ENTRIES(text-temp,' ') GT 1 THEN
      L_Length = cobDocumentoExistente:DetermineLength(THIS-OBJECT,INT(ENTRY(1, text-temp, " ")),INT(ENTRY(2, text-temp, " "))).
    ELSE
      l_Length = INT(text-temp) NO-ERROR.
    
    cobPDF:SeekPos(L_Ptr).
    IF l_Length > 0 THEN DO:
      DO WHILE TRUE:
        text-ptr = cobPDF:readline().
        IF INDEX(text-ptr,"~/Filter") > 0 THEN DO:
          text-sub = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Filter") + 7)).
          text-sub = REPLACE(ENTRY(1,text-sub," "),'~/','').        
          IF INDEX(text-sub,'>') GT 0 THEN
            text-sub = SUBSTRING(text-sub,1,INDEX(text-sub,'>') - 1).
          cchFiltroCompresion = TRIM(text-sub).          
          IF cobDocumentoExistente:clgCambiarMetodoCompresion OR clgContenidoRearmado THEN DO: 
            mifCompresor = cobDocumento:compresorRegistrado(cchFiltroCompresion).
            IF NOT VALID-OBJECT(mifCompresor) THEN
              UNDO, THROW NEW pdf.excepciones.PDFException('El PDF utiliza un método de compresión no registrado: ' + text-sub).
          END.
          LEAVE.
        END. /* Filter */
  
        IF INDEX(text-ptr,">>") > 0 
        OR INDEX(text-ptr,"endstream") > 0 THEN LEAVE.
      END. /* While True */
      IF clgComprimida THEN DO ON ERROR UNDO,THROW :
        /* Now Decompress the File */
        mmpContenido = cobPDF:contenidoBINStream(L_ptr,L_Length).
        IF VALID-OBJECT(mifCompresor) THEN 
          clcContenido = clcContenido + mifCompresor:Descomprimir(mmpContenido).
        ELSE
          clcContenido = BASE64-ENCODE(mmpContenido).          
        FINALLY:
          SET-SIZE(mmpContenido) = 0.
        END FINALLY.
      END.
      ELSE
        clcContenido = clcContenido + cobPDF:contenidoStream(L_Ptr,L_Length).
    END.
    ELSE DO WHILE TRUE:
      text-ptr = cobPDF:readline().
      /* If the Content was passed as an array of object pointers then we
             need to handle the actual contents here */
      IF INDEX(text-ptr,"[") > 0 THEN DO:
        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"[") + 1).
  
        IF INDEX(text-temp,"]") > 0 THEN 
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,"]") - 1).
  
        text-temp = TRIM(text-temp).
  
        /* This is a temporary holder for the page content */
        clgContenidoRearmado = clgContenidoRearmado OR NUM-ENTRIES(text-temp,' ') GT 3.
        DO obj-cnt = 1 TO NUM-ENTRIES(text-temp," ") BY 3:
  
          ASSIGN con-obj = INT(ENTRY(obj-cnt, text-temp, " "))
                   con-gen = INT(ENTRY(obj-cnt + 1, text-temp, " ")) NO-ERROR.
  
          IF ERROR-STATUS:ERROR THEN NEXT.
  
          ProcessContent(obj-cnt, con-obj, con-gen).
        END.
        LEAVE.
      END.

      IF INDEX(text-ptr,">>") > 0 
      OR INDEX(text-ptr,"endstream") > 0 THEN LEAVE.
    END. /* While True */

    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcressPageContent */
  
  METHOD PROTECTED CHARACTER ReemplazarObjetos(INPUT ipchLista AS CHARACTER):
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DO minIndex = 1 TO NUM-ENTRIES(ipchLista,' ') BY 4:
      ENTRY(minIndex,ipchLista,' ') = '~/' + ENTRY(minIndex,ipchLista,' '). 
      ENTRY(minIndex + 1,ipchLista,' ') = STRING(cobDocumentoExistente:nuevoObjeto(INTEGER(ENTRY(minIndex + 1,ipchLista,' ')))).
      ENTRY(minIndex + 2,ipchLista,' ') = '0'.
    END.
    RETURN ipchLista.
  END METHOD.
  
  METHOD PUBLIC VOID generarXObject():
    DEFINE VARIABLE mchPDF AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mliLen AS INT64 NO-UNDO.
    DEFINE VARIABLE minObjetoLen AS INTEGER NO-UNDO.
    DEFINE VARIABLE mmpContenido AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mifCompresor AS pdf.compresores.ICompresor NO-UNDO.
    
    asignarObjetoPDF().

    mchPDF = STRING(cinObjetoPDF) + " 0 obj" + {&pdfSKIP}
        + "<<" + {&pdfSKIP}
        + "/Type /XObject" + {&pdfSKIP}
        + "/Subtype /Form" + {&pdfSKIP}
        + "/FormType 1" + {&pdfSKIP}.
    cobDocumento:cobDestino:agregar(mchPDF).
    
    /* ajustar los elementos a los del documento, si no han sido especificados para la página */
    IF cobMargenes:cinAlto LE 0 THEN
      cobMargenes:Copiar(cobDocumentoExistente:cobDimensiones).
    IF cobAreaDeCorte:cinAlto LE 0 THEN
      cobAreaDeCorte:Copiar(cobDocumentoExistente:cobAreaDeCorte).
    /* Handle an External Object that was produced in Landscape Mode */
    IF cinRotacion EQ 90 THEN
      mchPDF = "/Matrix [0 -1 1 0 0 " + STRING(cinAncho) + "]" + {&pdfSKIP}
          + "/BBox [0 0 " + STRING(cinAncho) + " " + STRING(cinAlto) + "]" + {&pdfSKIP}.
    ELSE IF cobMargenes:cinAlto GT 0 THEN
      mchPDF =  "/Matrix [1 0 0 1 0 0]" + {&pdfSKIP}
        + "/BBox [" + STRING(cobMargenes:cinIzquierda) + " " + STRING(cobMargenes:cinAbajo - cobDocumento:cinAltoPieDePagina) + " " + STRING(cobMargenes:cinDerecha) + " " + STRING(cobMargenes:cinArriba + cobDocumento:cinAltoCabeceraDePagina) + "]" + {&pdfSKIP}.
    ELSE
      mchPDF =  "/Matrix [1 0 0 1 0 0]" + {&pdfSKIP}
        + "/BBox [0 0 " + STRING(cinAncho) + " " + STRING(cinAlto) + "]" + {&pdfSKIP}.

    IF cinDiccionarioRecursos GT 0 THEN
      cobDocumento:cobDestino:agregar(mchPDF + "/Resources " + STRING(cobDocumentoExistente:nuevoObjeto(cinDiccionarioRecursos)) + ' 0 R' + {&pdfSKIP}).      
    ELSE DO:
      cobDocumento:cobDestino:agregar(mchPDF + "/Resources <<" + {&pdfSKIP}).
  
      /* Font */
      mchPdf = "  /Font <<" + ReemplazarObjetos(cchFont) +  " >>" + {&pdfSKIP}.
      cobDocumento:cobDestino:agregar(mchPDF).
  
      /* XObject */
      mchPDF = "  /XObject <<" + {&pdfSKIP} + ReemplazarObjetos(cchXObjects) + " >>" + {&pdfSKIP}.
      cobDocumento:cobDestino:agregar(mchPDF).
  
      /* ExtGSpace */
      mchPDF = "  /ExtGState <<" + {&pdfSKIP} + ReemplazarObjetos(cchExtGState) + " >>" + {&pdfSKIP}.
      cobDocumento:cobDestino:agregar(mchPDF).
  
      /* ColorSpace */
      mchPDF = "  /ColorSpace <<" + {&pdfSKIP} + ReemplazarObjetos(cchColorSpace) + " >>" + {&pdfSKIP}.
      cobDocumento:cobDestino:agregar(mchPDF).
  
      /* Shading */
      mchPDF = "  /Shading <<" + {&pdfSKIP} + ReemplazarObjetos(cchShading) + " >>" + {&pdfSKIP}.      
      cobDocumento:cobDestino:agregar(mchPDF + " >>" + {&pdfSKIP}).      
    END.
    minObjetoLen = cobDocumento:crearObjeto('Length').
    mchPDF = "/Length " + STRING(minObjetoLen) + " 0 R" + {&pdfSKIP}.

    IF VALID-OBJECT(cobDocumento:cobCompresor) AND (NOT clgComprimida OR cobDocumentoExistente:clgCambiarMetodoCompresion) THEN
      mchPDF = mchPDF + "/Filter /" + cobDocumento:cobCompresor:cchNombreMetodo + {&pdfSKIP}.
    ELSE IF clgComprimida THEN
      mchPDF = mchPDF + '/Filter /' + cchFiltroCompresion + {&pdfSKIP}.

    cobDocumento:cobDestino:agregar(mchPDF + ">>"  + {&pdfSKIP} + "stream" + {&pdfSKIP}).

    /** Compression happens before Encryption **/
    IF clgComprimida THEN DO:
      IF cobDocumentoExistente:clgCambiarMetodoCompresion THEN DO:
        IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
          mmpContenido = cobDocumento:cobCompresor:Comprimir(clcContenido).
        ELSE DO:
          mifCompresor = cobDocumento:compresorRegistrado(cchFiltroCompresion).
          mmpContenido = mifCompresor:Comprimir(clcContenido).
        END.
      END.
      ELSE DO:
        IF clgContenidoRearmado THEN DO:
          mifCompresor = cobDocumento:compresorRegistrado(cchFiltroCompresion).
          mmpContenido = mifCompresor:Comprimir(clcContenido).
        END.
        ELSE
          mmpContenido = BASE64-DECODE(clcContenido).
      END.
      cobDocumento:cobDestino:agregar(mmpContenido).
      mliLen = GET-SIZE(mmpContenido).        
    END.
    ELSE IF VALID-OBJECT(cobDocumento:cobCompresor) THEN DO ON ERROR UNDO, THROW:
      mmpContenido = cobDocumento:cobCompresor:Comprimir(clcContenido).
      cobDocumento:cobDestino:agregar(mmpContenido).
      mliLen = GET-SIZE(mmpContenido).
    END.     
    ELSE DO:
      mliLen = cobDocumento:cobDestino:posicion().
      cobDocumento:cobDestino:agregar(clcContenido).
      mliLen = cobDocumento:cobDestino:posicion() - mliLen.
    END.

    mchPDF = {&pdfSKIP}  /* igc - added to ensure that the endstream was
                                    separated from the last command correctly 
                           */
              + "endstream" + {&pdfSKIP}
              +  "endobj" + {&pdfSKIP}.
  
    cobDocumento:cobDestino:agregar(mchPDF).
    /* igc - Added Sept 10, 2002 */
    cobDocumento:inicioObjeto(THIS-OBJECT,minObjetoLen).
    mchPDF = STRING(mliLen) + {&pdfSKIP} + "endobj" + {&pdfSKIP}.
    cobDocumento:cobDestino:agregar(mchPDf).
    FINALLY:
      SET-SIZE(mmpContenido) = 0.
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('ExternalPageDefinition').
    RETURN TRUE.
  END METHOD.
  
END CLASS.