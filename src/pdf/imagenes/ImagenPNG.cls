{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : ImagenPNG
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 11 08:26:32 ART 2018
    Notes       : Basado en la implementación de FPDF
                  www.fpdf.org
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.
USING pdf.imagenes.Imagen.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.imagenes.ImagenPNG INHERITS Imagen:
  
  DEFINE PUBLIC PROPERTY cinBitsPerComponent AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchEspacioDeColores AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PROTECTED PROPERTY cinObjetoPaleta AS INTEGER INITIAL ? NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cinCT AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cchTransparencia AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cmpPaleta AS MEMPTR NO-UNDO
    GET.
    PRIVATE SET.
    
  DESTRUCTOR ImagenPNG():
    SET-SIZE(cmpPaleta) = 0.
  END DESTRUCTOR.
  
  METHOD PROTECTED OVERRIDE VOID obtenerInformacionImagen():
    DEFINE VARIABLE mmpIInfo AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpTemp AS MEMPTR NO-UNDO.
    DEFINE VARIABLE minPosA AS INTEGER NO-UNDO.
    DEFINE VARIABLE minTamA AS INTEGER NO-UNDO.
    DEFINE VARIABLE minInt AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAux AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchQue AS CHARACTER NO-UNDO.
    
    FILE-INFO:FILE-NAME = cchArchivo.
    minTamA = FILE-INFO:FILE-SIZE.
    /* verificar firma */
    SET-BYTE-ORDER(mmpIInfo) = BIG-ENDIAN.
    SET-SIZE(mmpIInfo) = 12.
    minPosA = 1.
    COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR 12 TO mmpIInfo.
    IF GET-BYTE(mmpIInfo,1) NE 137 OR
        GET-BYTE(mmpIInfo,2) NE ASC('P') OR
        GET-BYTE(mmpIInfo,3) NE ASC('N') OR
        GET-BYTE(mmpIInfo,4) NE ASC('G') OR
        GET-BYTE(mmpIInfo,5) NE 13 OR
        GET-BYTE(mmpIInfo,6) NE 10 OR
        GET-BYTE(mmpIInfo,7) NE 26 OR
        GET-BYTE(mmpIInfo,8) NE 10 THEN
      UNDO, THROW NEW PDFException('El archivo "' + cchArchivo + '" no tiene una firma PNG válida').
    minPosA = minPosA + 12.
    
    COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR 4 TO mmpIInfo.
    IF GET-STRING(mmpIInfo,1,4) NE 'IHDR' THEN
      UNDO, THROW NEW PDFException('Archivo PNG con estructura incorrecta').
    minPosA = minPosA + 4.
    
    /* obtener ancho y alto */
    COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR 9 TO mmpIInfo.
    cinAncho = GET-LONG(mmpIInfo,1).
    cinAlto = GET-LONG(mmpIInfo,5).
    cinBitsPerComponent = GET-BYTE(mmpIInfo,9).
    IF cinBitsPerComponent GT 8 THEN
      UNDO, THROW NEW PDFException('Las imágenes con profundidad de más de 8 bit no está soportada').
    minPosA = minPosA + 9.
    /* obtener la información de la imagen */
    COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR 4 TO mmpIInfo.
    cinCT = GET-BYTE(mmpIInfo,1).
    IF cinCT EQ 0 THEN
      cchEspacioDeColores = 'DeviceGray'.
    ELSE IF cinCT EQ 2 THEN
      cchEspacioDeColores = 'DeviceRGB'.
    ELSE IF cinCT EQ 3 THEN
      cchEspacioDeColores = 'Indexed'.
    ELSE
      UNDO, THROW NEW PDFException('El canal alfa en imágenes PNG no está soportado').
    IF GET-BYTE(mmpIInfo,2) NE 0 THEN
      UNDO, THROW NEW PDFException('Método de compresión desconocido').
    IF GET-BYTE(mmpIInfo,3) NE 0 THEN
      UNDO, THROW NEW PDFException('Filtro desconocido').
    IF GET-BYTE(mmpIInfo,4) NE 0 THEN
      UNDO, THROW NEW PDFException('El entrelazado no está soportado').

    minPosA = minPosA + 8.
    //Scan chunks looking for palette, transparency and image data
    REPEAT:
      COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR 8 TO mmpIInfo.
      minInt = GET-LONG(mmpIInfo,1).
      mchQue = GET-STRING(mmpIInfo,5,4).
      minPosA = minPosA + 8. 
      IF mchQue  EQ 'PLTE' THEN DO:
        //Read palette
        SET-SIZE(cmpPaleta) = minInt.
        COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR minInt TO cmpPaleta.
      END.
      ELSE IF mchQue EQ 'tRNS' THEN DO:
        //Read transparency info
        IF minInt GT 12 THEN
          SET-SIZE(mmpIInfo) = minInt.
        COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR minInt TO mmpIInfo. 
        IF cinCT EQ 0 THEN
          cchTransparencia = STRING(GET-BYTE(mmpIInfo,1)).
        ELSE IF cinCT EQ 2 THEN 
          cchTransparencia = STRING(GET-BYTE(mmpIInfo,1)) + ',' + STRING(GET-BYTE(mmpIInfo,3)) + ',' + STRING(GET-BYTE(mmpIInfo,5)).
        ELSE DO:
          DO minAux = 1 TO minInt:
            IF GET-BYTE(mmpIInfo,minAux) EQ 0 THEN DO:
              cchTransparencia = STRING(minAux).
              LEAVE.
            END.
          END.
        END.
      END.
      ELSE IF mchQue EQ 'IDAT' THEN DO:
        //Read image data block
        IF GET-SIZE(cmpData) GT 0 THEN DO ON ERROR UNDO, THROW:
          COPY-LOB cmpData TO mmpTemp.
          SET-SIZE(cmpData) = 0.
          SET-SIZE(cmpData) = GET-SIZE(mmpTemp) + minInt.
          COPY-LOB mmpTemp TO cmpData OVERLAY AT 1.
          COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR minInt TO cmpData OVERLAY AT (GET-SIZE(mmpTemp) + 1).
          FINALLY:
            SET-SIZE(mmpTemp) = 0.
          END FINALLY.
        END.
        ELSE DO:
          SET-SIZE(cmpData) = minInt.
          COPY-LOB FROM FILE cchArchivo STARTING AT minPosA FOR minInt TO cmpData.
        END.
      END.
      ELSE IF mchQue EQ 'IEND' THEN
        LEAVE.
      minPosA = minPosA + minInt + 4.
      IF minPosA GE minTamA THEN
        LEAVE.
    END.
    IF cchEspacioDeColores EQ 'Indexed' AND GET-SIZE(cmpPaleta) EQ 0 THEN
      UNDO, THROW NEW PDFException('Falta la información de paleta para la imagen').
    FINALLY:
      SET-SIZE(mmpIInfo) = 0.
      SET-SIZE(mmpTemp) = 0.
    END FINALLY.   
  END METHOD.
  
  METHOD PROTECTED OVERRIDE CHARACTER generarBitsPerComponent():
    RETURN  "/BitsPerComponent " + STRING(cinBitsPerComponent) +  {&pdfSKIP}.    
  END METHOD.
  
  METHOD PROTECTED OVERRIDE CHARACTER generarColorSpace():
    DEFINE VARIABLE mchCS AS CHARACTER NO-UNDO.
    IF cchEspacioDeColores EQ 'Indexed' THEN DO:
      mchCS = '/ColorSpace [/Indexed /DeviceRGB '.
      IF cinObjetoPaleta EQ ? THEN
        cinObjetoPaleta = cobDocumento:crearObjeto('ColorPalette').
      mchCS = mchCS + STRING(GET-SIZE(cmpPaleta) / 3 - 1) + ' ' + STRING(cinObjetoPaleta) + ' 0 R]'.
    END.
    ELSE DO:
      mchCS = '/ColorSpace /' + cchEspacioDeColores.
      IF cchEspacioDeColores EQ 'DeviceCMYK' THEN
        mchCS = mchCS + ' /Decode [1 0 1 0 1 0 1 0]'.
    END.
    RETURN mchCS + {&pdfSKIP}.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE CHARACTER generarFilter():
    RETURN "/Filter /FlateDecode" + {&pdfSKIP}.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE CHARACTER generarParametros():
    DEFINE VARIABLE mchParams AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    
    mchParams = '/DecodeParms <</Predictor 15 /Colors '.
    IF cinCT EQ 2 THEN
      mchParams = mchParams + '3'.
    ELSE
      mchParams = mchParams + '1'.
    mchParams = mchParams + ' /BitsPerComponent ' + STRING(cinBitsPerComponent) + ' /Columns ' + STRING(cinAncho) + '>>'.
    IF cchTransparencia NE '' THEN DO:
      mchParams = mchParams + ' /Mask ['.
      DO minIndex = 1 TO NUM-ENTRIES(cchTransparencia):
        mchParams = mchParams + ENTRY(minIndex,cchTransparencia) + ' ' + ENTRY(minIndex,cchTransparencia) + ' '.
      END.
      mchParams = mchParams + ']'.
    END. 
    RETURN mchParams + {&pdfSKIP}.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarObjetosRelacionados():
    DEFINE VARIABLE mmpPaleta AS MEMPTR NO-UNDO.
    
    IF cinObjetoPaleta EQ ? THEN
      RETURN.
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPaleta).
    cobDocumento:cobDestino:agregar('<<').
    IF VALID-OBJECT(cobDocumento:cobCompresor) THEN DO:
      mmpPaleta = cobDocumento:cobCompresor:Comprimir(cmpPaleta).
      cobDocumento:cobDestino:agregar('/Filter /' + cobDocumento:cobCompresor:cchNombreMetodo).
    END.
    ELSE
      COPY-LOB cmpPaleta TO mmpPaleta.
    cobDocumento:cobDestino:agregar('/Length ' + STRING(GET-SIZE(mmpPaleta)) + '>>' + {&pdfSKIP} + 'stream' + {&pdfSKIP}).
    cobDocumento:cobDestino:agregar(mmpPaleta).
    cobDocumento:cobDestino:agregar({&pdfSKIP} + {&pdfSKIP} + "endstream" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
    FINALLY:
      SET-SIZE(mmpPaleta) = 0.
    END FINALLY.
  END METHOD.

  CONSTRUCTOR PUBLIC ImagenPNG(INPUT ipobDocumento AS pdf.Documento, INPUT ipchNombre AS CHARACTER, INPUT ipchArchivo AS CHARACTER):
    SUPER(ipobDocumento,ipchNombre, ipchArchivo).
  END CONSTRUCTOR.
END CLASS.