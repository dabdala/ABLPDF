{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : TipoDeLetraExterna
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 11:18:53 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.letras.TipoDeLetra.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.letras.TipoDeLetraExterna INHERITS TipoDeLetra:
  DEFINE PROTECTED PROPERTY cobPDF AS pdf.utiles.PDFStream NO-UNDO
    GET.
    PRIVATE SET.
  
  DEFINE PUBLIC PROPERTY clcContenido AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcDescendants AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcFont AS LONGCHAR EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcFont2 AS LONGCHAR EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcFont3 AS LONGCHAR EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcUnicode AS LONGCHAR EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcEncoding AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clcDescriptor AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY cchFuenteBase AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY cinFile2 AS INTEGER EXTENT 2 NO-UNDO  
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinFile3 AS INTEGER EXTENT 2 NO-UNDO 
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinUnicode AS INTEGER EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinEncoding AS INTEGER EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinDescend AS INTEGER EXTENT 2 NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinDescriptor AS INTEGER EXTENT 2 NO-UNDO  
    GET.
    PROTECTED SET.
    
  DEFINE PRIVATE VARIABLE cinObjetoPDFEncoding AS INTEGER NO-UNDO.
  DEFINE PRIVATE VARIABLE cinObjetoPDFDescendants AS INTEGER NO-UNDO.
  DEFINE PRIVATE VARIABLE cinObjetoPDFFile2 AS INTEGER NO-UNDO.
  DEFINE PRIVATE VARIABLE cinObjetoPDFFile3 AS INTEGER NO-UNDO.
  DEFINE PRIVATE VARIABLE cinObjetoPDFUnicode AS INTEGER NO-UNDO.
    
  
  DEFINE PUBLIC PROPERTY cinObjeto AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cinGeneracion AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY clgDescendiente AS LOGICAL NO-UNDO
    GET.
    SET.
  
  DEFINE PUBLIC PROPERTY cobDocumentoExistente AS pdf.DocumentoExistente NO-UNDO
    GET:
      RETURN CAST(cobDocumento,pdf.DocumentoExistente).
    END GET.
   
  CONSTRUCTOR PUBLIC TipoDeLetraExterna(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDf AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento).
    cobPDF = ipobPDF.
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC TipoDeLetraExterna(INPUT ipobDocumento AS pdf.Documento,INPUT ipobFuente AS pdf.letras.TipoDeLetraExterna):
    SUPER(ipobDocumento,ipobFuente).
    clgDescendiente = ipobFuente:clgDescendiente.
    clcContenido = ipobFuente:clcContenido.
    clcDescendants = ipobFuente:clcDescendants.
    clcFont = ipobFuente:clcFont.
    clcFont2 = ipobFuente:clcFont2.
    clcFont3 = ipobFuente:clcFont3.
    clcUnicode = ipobFuente:clcUnicode.
    clcEncoding = ipobFuente:clcEncoding.
    clcDescriptor = ipobFuente:clcDescriptor.
    cchFuenteBase = ipobFuente:cchFuenteBase.
    cinFile2 = ipobFuente:cinFile2.  
    cinFile3 = ipobFuente:cinFile3.  
    cinUnicode = ipobFuente:cinUnicode.
    cinEncoding = ipobFuente:cinEncoding.
    cinDescend = ipobFuente:cinDescend.  
    cinDescriptor = ipobFuente:cinDescriptor.  
  END CONSTRUCTOR.
  
  METHOD PUBLIC VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-ptr AS CHARACTER NO-UNDO.
    DEFINE VARIABLE descriptor AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cEntry4 AS CHARACTER NO-UNDO.
    
    cobPDF:preservarPos().
    clcContenido = cobDocumentoExistente:ObjectContent(ipinObjeto,ipinGeneracion).
    cobPDF:seekPos(cobDocumentoExistente:posicionObjeto(ipinObjeto,ipinGeneracion)).
    cchNombreInterno = '/' + ipchNombre.
    cinObjeto = ipinObjeto.
    cinGeneracion = ipinGeneracion.
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
      
      IF INDEX(text-ptr,"~/FontDescriptor") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/FontDescriptor"))).

        ASSIGN
          cinDescriptor[1] = INT(ENTRY(2, text-temp, " "))
          cinDescriptor[2] = INT(ENTRY(3, text-temp, " "))
        NO-ERROR {&END}

        descriptor = TRUE.
        clcDescriptor = cobDocumentoExistente:ObjectContent(cinDescriptor[1],cinDescriptor[2]).
        ProcessFontDescriptorDictionary(cinDescriptor[1],cinDescriptor[2]).
      END.

      IF INDEX(text-ptr,"~/ToUnicode") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/ToUnicode"))).

        ASSIGN
          cinUnicode[1] = INT(ENTRY(2, text-temp, " "))
          cinUnicode[2] = INT(ENTRY(3, text-temp, " "))
        NO-ERROR {&END}

        IF cinUnicode[1] > 0 THEN DO:
          clcUnicode[1] = cobDocumentoExistente:ObjectContent(cinUnicode[1], cinUnicode[2]).
          clcUnicode[2] = cobDocumentoExistente:StreamContent(cinUnicode[1], cinUnicode[2],TRUE).
        END.
      END.

      IF INDEX(text-ptr,"~/DescendantFonts") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/DescendantFonts"))).
        text-temp = REPLACE(text-temp,"~/DescendantFonts","").
        text-temp = REPLACE(text-temp,"["," ").
        text-temp = TRIM(text-temp).

        ASSIGN cinDescend[1] = INT(ENTRY(1, text-temp, " "))
               cinDescend[2] = INT(ENTRY(2, text-temp, " ")) NO-ERROR.

        IF cinDescend[1] > 0 THEN DO:
          cobDocumentoExistente:agregarTipoDeLetra(cinDescend[1],cinDescend[2],"DescendantFont",ipinObjeto,ipinGeneracion,ipchNombre).
          clcDescendants = cobDocumentoExistente:ObjectContent(cinDescend[1],cinDescend[2]).
        END.
      END.

      IF INDEX(text-ptr,"~/Encoding") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Encoding"))).

        ASSIGN cinEncoding[1] = INT(ENTRY(2, text-temp, " "))
               cinEncoding[2] = INT(ENTRY(3, text-temp, " ")) NO-ERROR.

        IF cinEncoding[1] <> 0 THEN
          clcEncoding = cobDocumentoExistente:ObjectContent(cinEncoding[1],cinEncoding[2]).
      END.

      IF INDEX(text-ptr,"~/Widths") > 0 THEN DO:
        cchWidths = ProcessFontWidths (text-ptr).
        cenTipoDeLetra:cinValor = pdf.tipos.Letra:AnchoVariable.
      END.

      IF cchFuenteBase = "" 
      AND INDEX(text-ptr,"~/BaseFont") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/BaseFont"))).

        cEntry4 = ENTRY(4, text-temp, " ") NO-ERROR.
        IF cEntry4 = "R" THEN DO:
          cchFuenteBase = ProcessBaseFont(INT( ENTRY(2, text-temp, " ") ),INT( ENTRY(3, text-temp, " ") )).
        END.
        ELSE
          cchFuenteBase = ENTRY(3, text-temp, "/").
      END.

      IF INDEX(text-ptr,"~/Name") > 0  THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Name"))).

        cchNombre = ENTRY(3,text-temp,"~/").
      END.

      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END. /* True */
    cobDocumento:RegistrarTipoDeLetra(THIS-OBJECT). 
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.  
  END METHOD.

  METHOD PROTECTED CHARACTER ProcessFontDescriptorDictionary(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchEntry AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
    cobPDF:SeekPos(cobDocumentoExistente:posicionObjeto(ipinObjeto,ipinGeneracion)).
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().

      IF INDEX(text-ptr,"~/FontName") > 0  THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/FontName"))).
        mchEntry = ENTRY(4, text-temp, " ") NO-ERROR.
        IF mchEntry EQ "R" THEN DO:
          cchNombre = ProcessFontName (INT( ENTRY(2,text-temp," ") ),INT( ENTRY(3,text-temp," ") )).
        END.
        ELSE 
          cchNombre  = ENTRY(3,text-temp,"~/").

         clcFont = cobDocumentoExistente:ObjectContent(ipinObjeto,ipinGeneracion).
      END.
      IF INDEX(text-ptr,"~/FontFile2") > 0 THEN DO:

        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/FontFile2")).

        ASSIGN
          cinfile2[1] = INT(ENTRY(2,text-temp," "))
          cinfile2[2] = INT(ENTRY(3,text-temp," "))
        {&END}
        clcFont2[1] = cobDocumentoExistente:ObjectContent(cinFile2[1],cinFile2[2]).
        clcFont2[2] = cobDocumentoExistente:StreamContent(cinFile2[1],cinFile2[2],TRUE).
      END.

      IF INDEX(text-ptr,"~/FontFile3") > 0 THEN DO:

        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/FontFile3")).

        ASSIGN 
          cinfile3[1] = INT(ENTRY(2,text-temp," "))
          cinfile3[2] = INT(ENTRY(3,text-temp," "))
        {&END}
        clcFont3[1] = cobDocumentoExistente:ObjectContent(cinFile3[1],cinFile3[2]).
        clcFont3[2] = cobDocumentoExistente:StreamContent(cinFile3[1],cinFile3[2],TRUE).
      END.

      IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
    END.  
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcessFontDescriptorDictionary */
  
  METHOD PROTECTED CHARACTER ProcessFontName(INPUT  pObject   AS INTEGER,INPUT  pGen      AS INTEGER):
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE pFontName AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
    cobPDF:seekPos(cobDocumentoExistente:posicionObjeto(pObject,pGen)).
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
     IF TRIM(text-ptr) BEGINS "~/" THEN
        ASSIGN pFontName = SUBSTR(text-ptr,2).

      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END.
    RETURN pFontName.
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.  /* ProcessFontName */
  METHOD PROTECTED CHARACTER ProcessFontWidths(INPUT  ipchLinea AS CHARACTER):
    DEFINE VARIABLE mchWidths AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
    DO WHILE INDEX(ipchLinea, '~/Widths') EQ 0:
      IF INDEX(ipchLinea,'endobj') GT 0 THEN
        RETURN ''.
      ipchLinea = cobPDF:readLine().
    END.
    mchWidths = TRIM(SUBSTR(ipchLinea,INDEX(ipchLinea,"~/Widths") + 7)).
    DO WHILE INDEX(mchWidths,']') EQ 0:
      mchWidths = mchWidths + ' ' + cobPDF:readline().
    END.
    mchWidths = SUBSTR(mchWidths,1,INDEX(mchWidths,"]") - 1).
    mchWidths = TRIM(REPLACE(mchWidths,"[","")).
    RETURN mchWidths.
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.  
  END METHOD.
  METHOD PROTECTED CHARACTER ProcessBaseFont(INPUT  pObject   AS INTEGER, INPUT  pGen      AS INTEGER ):
    DEFINE VARIABLE pBaseFont AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
    cobPDF:seekPos(cobDocumentoExistente:posicionObjeto(pObject,pGen)).
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
     IF TRIM(text-ptr) BEGINS "~/" THEN
        ASSIGN pBaseFont = SUBSTR(text-ptr,2).

      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END.
    RETURN pBaseFont.
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.  /* ProcessBaseFont */
  
  METHOD PROTECTED LONGCHAR generarStream(INPUT ipinObjeto AS INTEGER, INPUT iplcObj AS LONGCHAR, INPUT iplcStream AS LONGCHAR):
    DEFINE VARIABLE mmpStream AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpTmp AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mchLength AS CHARACTER NO-UNDO.
    /* el contenido está conservado como BASE64 */
    cobDocumento:inicioObjeto(THIS-OBJECT,ipinObjeto).
    mmpTmp = BASE64-DECODE(iplcStream).
    /* si el documento tiene especificado un método de compresión, utilizarlo */
    IF cobDocumentoExistente:clgCambiarMetodoCompresion AND VALID-OBJECT(cobDocumento:cobCompresor) THEN DO:
      mmpStream = cobDocumento:cobCompresor:Comprimir(mmpTmp).
      /* cualquiera fuera el método previo, hay que cambiarlo al nuevo método de compresión */
      IF INDEX(iplcObj,'/Filter') GT 0 THEN DO:
        mchLength = SUBSTRING(iplcObj,INDEX(iplcObj,'/Filter')).
        mchLength = '/' + ENTRY(2,mchLength,'/') + '/' + ENTRY(3,mchLength,'/'). 
        iplcObj = REPLACE(iplcObj,mchLength,'/Filter/' + cobDocumento:cobCompresor:cchNombreMetodo).
      END.
      ELSE
        iplcObj = SUBSTRING(iplcObj,1,INDEX(iplcObj,'>>') - 1) + '/Filter/'  + cobDocumento:cobCompresor:cchNombreMetodo + '>>'.
    END.
    ELSE DO:
      mmpStream = mmpTmp.
      mmpTmp = ?.
      /* si antes tenía un método de compresión, hay que quitarlo */
      IF cobDocumentoExistente:clgCambiarMetodoCompresion AND INDEX(iplcObj,'/Filter') GT 0 THEN DO:
        mchLength = SUBSTRING(iplcObj,INDEX(iplcObj,'/Filter')).
        mchLength = '/' + ENTRY(2,mchLength,'/') + '/' + ENTRY(3,mchLength,'/'). 
        iplcObj = REPLACE(iplcObj,mchLength,'').
      END.
    END.
    /* cambiar la vieja longitud, por la nueva */
    IF INDEX(iplcObj,'/Length ') GT 0 THEN DO:
      mchLength = SUBSTRING(iplcObj,INDEX(iplcObj,'/Length ')).
      mchLength = ENTRY(2,mchLength,'/'). 
      iplcObj = REPLACE(iplcObj,mchLength,'Length ' + STRING(GET-SIZE(mmpStream))).
    END.
    /* si era la última entrada, corregir el cierre del "inline stream" */
    IF INDEX(iplcObj,'>>') EQ 0 THEN
      iplcObj = iplcObj + '>>'.
    cobDocumento:cobDestino:agregar(iplcObj + 'stream' + {&pdfSKIP}).
    cobDocumento:cobDestino:agregar(mmpStream).
    cobDocumento:cobDestino:agregar({&pdfSKIP} + {&pdfSKIP} + "endstream" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
    RETURN iplcObj.
    FINALLY:
      SET-SIZE(mmpTmp) = 0.
      SET-SIZE(mmpStream) = 0.
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDefinicion():
    DEFINE VARIABLE mmpDecoded AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpComprimido AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mchLength AS CHARACTER NO-UNDO.
    
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).
    IF INDEX(clcContenido,'~/Name') EQ 0 THEN
      clcContenido = SUBSTRING(clcContenido,1,INDEX(clcContenido,'~/')) + 'Name ' + cchNombreInterno + SUBSTRING(clcContenido,INDEX(clcContenido,'~/')).
    IF INDEX(clcContenido,"~/FontDescriptor " + STRING(cinDescriptor[1]) + " " + STRING(cinDescriptor[2])) > 0 THEN DO:
      IF cinObjetoPDFDescriptor EQ 0 THEN
        cinObjetoPDFDescriptor = cobDocumento:crearObjeto('FontDescriptor').
      clcContenido = REPLACE(clcContenido,"~/FontDescriptor " + STRING(cinDescriptor[1]) + " "
                                       + STRING(cinDescriptor[2]),
                                       "~/FontDescriptor " + STRING(cinObjetoPDFDescriptor) + " 0").
    END.
  
    IF INDEX(clcContenido,"~/Encoding " + STRING(cinEncoding[1]) + " " + STRING(cinEncoding[2])) > 0 THEN DO:
      IF cinObjetoPDFCodificacion EQ 0 THEN
        cinObjetoPDFCodificacion = cobDocumento:crearObjeto('Encoding').
      clcContenido = REPLACE(clcContenido,
                                       "~/Encoding " 
                                       + STRING(cinEncoding[1]) + " "
                                       + STRING(cinEncoding[2]),
                                       "~/Encoding " 
                                       + STRING(cinObjetoPDFCodificacion) + " 0").
    END.
  
    /* Begin - Handle Descendant Fonts */
    IF INDEX(clcContenido,"~/DescendantFonts[" + STRING(cinDescend[1]) + " " + STRING(cinDescend[2])) > 0 
      THEN DO:
      IF cinObjetoPDFDescendants EQ 0 THEN
        cinObjetoPDFDescendants = cobDocumento:crearObjeto('DesdendantFonts').
      clcContenido = REPLACE(clcContenido,
                                       "~/DescendantFonts[" 
                                       + STRING(cinDescend[1]) + " "
                                       + STRING(cinDescend[2]),
                                       "~/DescendantFonts[" 
                                       + STRING(cinObjetoPDFDescendants) + " 0").
    END.
  
    IF INDEX(clcContenido,"~/DescendantFonts [ " + STRING(cinDescend[1]) + " " + STRING(cinDescend[2])) > 0 
      THEN DO:
      IF cinObjetoPDFDescendants EQ 0 THEN
        cinObjetoPDFDescendants = cobDocumento:crearObjeto('DesdendantFonts').      
      clcContenido = REPLACE(clcContenido,
                                       "~/DescendantFonts [ " 
                                       + STRING(cinDescend[1]) + " "
                                       + STRING(cinDescend[2]),
                                       "~/DescendantFonts [ " 
                                       + STRING(cinObjetoPDFDescendants) + " 0").
    END.
  
    IF INDEX(clcContenido,"~/ToUnicode " + STRING(cinUnicode[1]) + " " + STRING(cinUnicode[2])) > 0 THEN DO:
      IF cinObjetoPDFUnicode EQ 0 THEN
        cinObjetoPDFUnicode = cobDocumento:crearObjeto('ToUnicode').
      clcContenido = REPLACE(clcContenido,
                                       "~/ToUnicode " 
                                       + STRING(cinUnicode[1]) + " "
                                       + STRING(cinUnicode[2]),
                                       "~/ToUnicode  " 
                                       + STRING(cinObjetoPDFUnicode) + " 0").
    END.
  
                    /* End - Handle Descendant Fonts */
  
    cobDocumento:cobDestino:agregar(clcContenido + {&pdfSKIP}).
  
    cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
  
    
    /* Put Out Encoding Dictionary */
    IF cinObjetoPDFCodificacion NE 0 THEN DO:
      cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFCodificacion).
      IF INDEX(clcEncoding,"~/Encoding " + STRING(cinEncoding[1]) + " " + STRING(cinEncoding[2])) > 0 THEN DO:
        clcEncoding = REPLACE(clcEncoding,
                       "~/Encoding " 
                       + STRING(cinEncoding[1]) + " "
                       + STRING(cinEncoding[2]),
                       "~/Encoding " 
                       + STRING(cinObjetoPDFEncoding) + " 0").
      END.
      cobDocumento:cobDestino:agregar(clcEncoding + {&pdfSKIP}).
      cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
    END. /* Encoding */
    
    /* Put Out FontDescriptor Dictionary */
    IF cinObjetoPDFDescriptor GT 0 THEN DO:
      cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFDescriptor).
  
      IF INDEX(clcDescriptor,"~/FontFile2 " + STRING(cinFile2[1]) + " " + STRING(cinFile2[2])) > 0 THEN DO:
        IF cinObjetoPDFFile2 EQ 0 THEN
          cinObjetoPDFFile2 = cobDocumento:crearObjeto('FontFile2').
        clcDescriptor = REPLACE(clcDescriptor,
                         "~/FontFile2 " 
                         + STRING(cinFile2[1]) + " "
                         + STRING(cinFile2[2]),
                         "~/FontFile2 " 
                         + STRING(cinObjetoPDFFile2) + " 0").
      END.
  
      IF INDEX(clcDescriptor,"~/FontFile3 " + STRING(cinFile3[1]) + " " + STRING(cinFile3[2])) > 0 THEN DO:
        IF cinObjetoPDFFile3 EQ 0 THEN
          cinObjetoPDFFile3 = cobDocumento:crearObjeto('FontFile3').
        clcDescriptor = REPLACE(clcDescriptor,
                         "~/FontFile3 " 
                         + STRING(cinFile3[1]) + " "
                         + STRING(cinFile3[2]),
                         "~/FontFile3 " 
                         + STRING(cinObjetoPDFFile3) + " 0").
      END.
  
      cobDocumento:cobDestino:agregar(clcDescriptor + {&pdfSKIP}).
      cobDocumento:cobDestino:agregar("endobj" + {&pdfSKIP}).
    END. /* FontDescriptor */
    
    /* Put Out DescendantFonts Dictionary */
    IF cinDescend[1] NE 0 THEN DO:
      IF cinObjetoPDFDescendants EQ 0 THEN
        cinObjetoPDFDescendants = cobDocumento:crearObjeto('DescendantFonts').
      cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFDescendants).
      IF INDEX(clcDescendants,"~/FontDescriptor " + STRING(cinDescriptor[1]) + " " + STRING(cinDescriptor[2])) > 0 THEN DO:
            clcDescendants = REPLACE(clcDescendants,
                             "~/FontDescriptor " 
                             + STRING(cinDescriptor[1]) + " "
                             + STRING(cinDescriptor[2]),
                             "~/FontDescriptor " 
                             + STRING(cinObjetoPDFDescendants) + " 0").
       END.
  
      cobDocumento:cobDestino:agregar(clcDescendants + {&pdfSKIP}).
      cobDocumento:cobDestino:agregar({&pdfSKIP} + {&pdfSKIP} + "endstream" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
    
    END. /* DescendantFonts */
    
    /* Put Out ToUnicode Dictionary */
    IF cinUnicode[1] <> 0 THEN DO:
      IF cinObjetoPDFUnicode EQ 0 THEN
        cinObjetoPDFUnicode = cobDocumento:crearObjeto("ToUnicode").
      clcUnicode[1] = generarStream(cinObjetoPDFUnicode,clcUnicode[1],clcUnicode[2]).
    END. /* ToUnicode */
    
    /* Put Out FontFile2 Dictionary */
    IF cinFile2[1] <> 0 THEN DO:
      IF cinObjetoPDFFile2 EQ 0 THEN
        cinObjetoPDFFile2 = cobDocumento:crearObjeto("FontFile2").
      clcFont2[1] = generarStream(cinObjetoPDFFile2,clcFont2[1],clcFont2[2]).
    END. /* FontFile2 */
    
    /* Put Out FontFile3 Dictionary */
    IF cinFile3[1] <> 0 THEN DO:
      IF cinObjetoPDFFile3 EQ 0 THEN
        cinObjetoPDFFile3 = cobDocumento:crearObjeto("FontFile3").
      clcFont3[1] = generarStream(cinObjetoPDFFile3,clcFont3[1],clcFont3[2]).
    END. /* FontFile3 */
    FINALLY:
      SET-SIZE(mmpDecoded) = 0.
      SET-SIZE(mmpComprimido) = 0.
    END FINALLY.
  END METHOD.
END CLASS.