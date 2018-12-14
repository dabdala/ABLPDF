{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : TipoDeLetra
    Purpose     : Encapsula la manipulación de fuentes
    Syntax      : 
    Description : Maneja la información de fuentes para un documento PDF
    Author(s)   : D. Abdala
    Created     : Thu Aug 30 08:24:07 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.PDFException.

ROUTINE-LEVEL ON ERROR UNDO, THROW.


CLASS pdf.letras.TipoDeLetra IMPLEMENTS pdf.IObjetoPDF:
  
  DEFINE STATIC PROTECTED TEMP-TABLE cttDiff NO-UNDO
    FIELD chLetra  AS CHARACTER
    FIELD inCaracter    AS INTEGER
    FIELD chNombre     AS CHARACTER
  {&END}
  
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cinObjetoPDFDescriptor AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PROTECTED PROPERTY cinObjetoPDFCodificacion AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PROTECTED PROPERTY cinObjetoPDFStream AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PROTECTED PROPERTY cinObjetoPDFStreamLength AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  
  DEFINE PRIVATE STREAM cstIn.
  
  DEFINE PUBLIC PROPERTY cchNombre AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchNombreOriginal AS CHARACTER NO-UNDO
    GET:
      IF cchNombreOriginal EQ ? OR cchNombreOriginal EQ '' THEN
        RETURN cchNombre.
      RETURN cchNombreOriginal.
    END GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchNombreInterno AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cenTipoDeLetra AS pdf.tipos.Letra NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cenTipoDeLetra) THEN
        cenTipoDeLetra = NEW pdf.tipos.Letra().
      RETURN cenTipoDeLetra.
    END GET.
    PRIVATE SET(INPUT ipobLetra AS pdf.tipos.Letra):
      IF ipobLetra EQ ? THEN
        DELETE OBJECT cenTipoDeLetra NO-ERROR.
      cenTipoDeLetra = ipobLetra.
    END SET.
    
  DEFINE PUBLIC PROPERTY clgEmbebida AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cchIsFixedPitch AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchFontWidth AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchWidths AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinItalicAngle AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchAscender AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchDescender AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchFontBBox AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchFirstChar AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchLastChar AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cchFlags AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY  cchFontFile AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY cchDIF AS CHARACTER NO-UNDO INITIAL ?
    GET.
    PROTECTED SET(INPUT ipchDIFFile AS CHARACTER):
      IF ipchDIFFile NE '' AND ipchDIFFile NE ? AND SEARCH(ipchDIFFile) EQ ? THEN
        UNDO, THROW NEW PDFException("Cannot find Font DIF file for loading!").
      cchDIF = ipchDIFFILE.
    END SET.
    
  CONSTRUCTOR PROTECTED TipoDeLetra(INPUT ipobDocumento AS pdf.Documento):
    SUPER().
    cobDocumento = ipobDocumento.
  END CONSTRUCTOR.
  CONSTRUCTOR TipoDeLetra(INPUT ipobDocumento AS pdf.Documento,INPUT ipchNombre AS CHARACTER,INPUT ipchArchivo AS CHARACTER,INPUT ipchAFM AS CHARACTER):
    cobDocumento = ipobDocumento.
    cchNombreOriginal = ipchNombre.    
    cchNombre = REPLACE(ipchNombre," ","#20").    
    loadFont(ipchArchivo,ipchAFM).
  END CONSTRUCTOR.
  CONSTRUCTOR TipoDeLetra(INPUT ipobDocumento AS pdf.Documento,INPUT ipchNombre AS CHARACTER,INPUT ipchArchivo AS CHARACTER,INPUT ipchAFM AS CHARACTER, INPUT ipchDIF AS CHARACTER):
    cobDocumento = ipobDocumento.
    cchNombreOriginal = ipchNombre.    
    cchNombre = REPLACE(ipchNombre," ","#20").
    cchDIF = ipchDIF.
    loadFont(ipchArchivo,ipchAFM).
  END CONSTRUCTOR.
  CONSTRUCTOR TipoDeLetra(INPUT ipobDocumento AS pdf.Documento,INPUT ipobFuente AS pdf.letras.TipoDeLetra):
    cobDocumento = ipobDocumento.
    cchNombre = ipobFuente:cchNombre.
    cchDIF = ipobFuente:cchDIF.
    cchFontFile = ipobFuente:cchFontFile.
    cchNombreOriginal = ipobFuente:cchNombreOriginal.    
    cchNombreInterno = ipobFuente:cchNombreInterno.
    cenTipoDeLetra:cinValor = ipobFuente:cenTipoDeLetra:cinValor.
    cchFontWidth = ipobFuente:cchFontWidth.
    cinItalicAngle  = ipobFuente:cinItalicAngle. 
    cchDescender    = ipobFuente:cchDescender.
    cchAscender     = ipobFuente:cchAscender.
    cchFontBBox     = ipobFuente:cchFontBBox.
    cchIsFixedPitch = ipobFuente:cchIsFixedPitch.
    cchFirstChar    = ipobFuente:cchFirstChar.
    cchLastChar     = ipobFuente:cchLastChar.     
    cchWidths       = ipobFuente:cchWidths.        
    cobDocumento:RegistrarTipoDeLetra(THIS-OBJECT).
  END CONSTRUCTOR.
  
  METHOD PROTECTED VOID loadFont(INPUT ipchArchivo AS CHARACTER,INPUT ipchAFM AS CHARACTER):
    IF SEARCH(ipchArchivo) EQ ? THEN
      UNDO, THROW NEW PDFException("Cannot find Font file for loading!").    
    IF SEARCH(ipchAFM) = ? THEN
      UNDO, THROW NEW PDFException("Cannot find Font AFM file for loading!").
    cchNombreInterno = "/" + cchNombre.

    ParseAFMFile(ipchAFM).

    cenTipoDeLetra:cinValor  = IF cchIsFixedPitch = "0" THEN pdf.tipos.Letra:AnchoFijo ELSE pdf.tipos.Letra:AnchoVariable.

    IF cenTipoDeLetra:cinValor EQ pdf.tipos.Letra:AnchoVariable THEN
      cchFontWidth = TRIM(cchWidths).
    ELSE
      cchFontWidth = ENTRY(1, TRIM(cchWidths)," ").
    cchFontFile = ipchArchivo.
    cobDocumento:RegistrarTipoDeLetra(THIS-OBJECT).
  END.

  METHOD PROTECTED VOID ParseAFMFile(INPUT ipchAFM AS CHARACTER):
    DEFINE VARIABLE L_data  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_key   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_flag  AS CHARACTER NO-UNDO
         INIT "00000000000000000000000000100010".
    /* Bit 6 (above) is set to identify NonSymbolic Fonts -- or Fonts that use
       the Standard Latin Character Set */

    DEFINE VARIABLE L_int   AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop  AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_exp   AS INTEGER NO-UNDO.

    ASSIGN
        cinItalicAngle  = 0
        cchDescender    = ""
        cchAscender     = ""
        cchFontBBox     = ""
        cchIsFixedPitch = ""
        cchFirstChar    = ""
        cchLastChar     = ""
        cchWidths       = ""
    {&END}

    INPUT STREAM cstIn FROM VALUE(SEARCH(ipchAFM)) BINARY NO-CONVERT NO-MAP NO-ECHO.

    REPEAT:
      IMPORT STREAM cstIn UNFORMATTED L_data.
      L_Key = ENTRY(1, L_data, " ") NO-ERROR.
      IF ERROR-STATUS:ERROR THEN NEXT.

      CASE L_key:
        WHEN "ItalicAngle" THEN
          cinItalicAngle = INT(ENTRY( 2, L_data, " ")) NO-ERROR.
        WHEN "Ascender" THEN
          cchAscender = ENTRY( 2, L_data, " ") NO-ERROR.
        WHEN "Descender" THEN
          cchDescender = ENTRY( 2, L_data, " ") .
        WHEN "FontBBox" THEN
          ASSIGN cchFontBBox = REPLACE(L_data,"FontBBox ","").
        WHEN "IsFixedPitch" THEN
          cchIsFixedPitch = IF ENTRY(2,L_data, " ") = "True" THEN "0" ELSE "1".
        WHEN "C" THEN DO:
          IF cchFirstChar = "" THEN
            cchFirstChar = ENTRY(2, L_data, " ") NO-ERROR.
          ASSIGN cchWidths = cchWidths + " " + ENTRY(5, L_data, " ") NO-ERROR.
          IF INT(ENTRY(2, L_data, " ")) > 0 THEN
           cchLastChar = ENTRY(2, L_data, " ") NO-ERROR.
        END.
      END CASE.
    END. /* REPEAT */

    INPUT STREAM cstIn CLOSE.

    /* Determine Font Flags */
    IF cchIsFixedPitch = "0" THEN
      OVERLAY( L_Flag, 32, 1, "CHARACTER") = "1".

    DO L_loop = LENGTH(L_Flag, "character":u) TO 1 BY -1 :
      IF SUBSTR(L_flag,L_loop,1, "character":u) = "1" THEN
        L_int = L_int + EXP(2, L_exp).
      L_exp = L_exp + 1.
    END.
    cchFlags = STRING( L_int ).
  END METHOD.
  
  METHOD PUBLIC INTEGER AnchoTexto(INPUT ipchTexto AS CHARACTER,INPUT ipdePunto AS DECIMAL):
    DEFINE VARIABLE L_width  AS INTEGER INITIAL 0 NO-UNDO.

    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_tot     AS INTEGER NO-UNDO.

    IF cenTipoDeLetra:cinValor EQ  pdf.tipos.Letra:AnchoFijo THEN DO:
      IF cchFontWidth EQ '' THEN
        cchFontWidth = '600'. 
      L_width = INT((LENGTH(ipchTexto, "character":u) * INT(cchFontWidth) / 1000) * ipdePunto).
    END.
    ELSE DO:
      DO L_loop = 1 TO LENGTH(ipchTexto, "character":u):
        L_tot = L_tot + INT(ENTRY(INT(ASC(SUBSTR(ipchTexto,L_Loop,1, "character":u))) + 1 ,cchWidths, " ")) NO-ERROR.
      END.
      l_width = INT((L_tot / 1000) * ipdePunto) NO-ERROR.
    END. /* Variable Width Font */
    RETURN l_width.
  END METHOD.
  
  METHOD PUBLIC DECIMAL AnchoTextoDec(INPUT ipchTexto AS CHARACTER,INPUT ipdePunto AS DECIMAL):
    DEFINE VARIABLE L_width   AS DECIMAL DECIMALS 5 NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_tot     AS DECIMAL NO-UNDO.

    IF cenTipoDeLetra:cinValor EQ pdf.tipos.Letra:AnchoFijo THEN DO:
      IF cchFontWidth EQ '' THEN
        cchFontWidth = '600'.       
      L_width = DEC((LENGTH(ipchTexto, "character":u) * INT(cchFontWidth) / 1000) * ipdePunto).
    END.
    ELSE DO:
      DO L_loop = 1 TO LENGTH(ipchTexto, "character":u):
        L_tot = L_tot + INT(ENTRY(INT(ASC(SUBSTR(ipchTexto,L_Loop,1, "character":u))) + 1 ,cchWidths, " ")) NO-ERROR.
      END.

      l_width = DEC((L_tot * ipdePunto) / 1000) NO-ERROR.
    END. /* Variable Width Font */
    RETURN L_width.
  END METHOD.
  
  METHOD PUBLIC INTEGER CantidadCaben(INPUT ipchTexto AS CHARACTER, INPUT ipobRango AS pdf.utiles.Punto, INPUT ipdePuntos AS DECIMAL):
    DEFINE VARIABLE iReqFMWidth AS INTEGER NO-UNDO. /* Required font-metric width */
    DEFINE VARIABLE iCurFMWidth AS DECIMAL NO-UNDO. /* Font-metric width of chars that fit */
    DEFINE VARIABLE minMax AS INTEGER NO-UNDO.
    DEFINE VARIABLE minLen AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDelta AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdeAncho AS DECIMAL NO-UNDO.

    iReqFMWidth = (ipobRango:cinHasta - ipobRango:cinDesde).

    minLen = LENGTH(ipchTexto,'CHARACTER':u).
    minMax = minLen.
    iCurFMWidth = AnchoTextoDec(ipchTexto,ipdePuntos).
    DO WHILE iCurFMWidth GT iReqFMWidth AND minMax GT 1:
      minMax = minMax / 2.  
      iCurFMWidth = AnchoTextoDec(SUBSTRING(ipchTexto,1,minMax),ipdePuntos).
    END. /* Loop through text */
    IF iCurFMWidth GT iReqFMWidth THEN
      minMax = minMax - 1.
    IF minMax GT 0 AND minMax LT minLen AND iCurFMWidth LT iReqFMWidth THEN DO:
      minDelta = minMax / 2.
      REPEAT:
        mdeAncho = AnchoTextoDec(SUBSTRING(ipchTexto,minMax,minDelta),ipdePuntos).
        IF icurFMWidth + mdeAncho LE iReqFMWidth THEN ASSIGN
          minMax = minMax + minDelta
          icurFMWidth = icurFMWidth + mdeAncho
        {&END}
        IF minDelta LE 1 THEN
          LEAVE.
        minDelta = minDelta / 2.
      END.
    END.
    RETURN minMax.
  END METHOD. /* pdf_GetNumFittingChars */
  
  METHOD PUBLIC LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('Font').
    RETURN TRUE.
  END METHOD.
  
  METHOD PUBLIC VOID agregarDiff(INPUT ipinCaracter AS INTEGER, INPUT ipchNombre AS CHARACTER):
    CREATE cttDiff.
    ASSIGN 
         cttDiff.chLetra  = cchNombre
         cttDiff.inCaracter = ipinCaracter
         cttDiff.chNombre  = IF ipchNombre BEGINS "/" THEN ipchNombre ELSE "/" + ipchNombre
    {&END}
  END METHOD.
  
  METHOD PUBLIC VOID generarDefinicion():
    DEFINE VARIABLE L_Size AS INT64 NO-UNDO.
    DEFINE VARIABLE mmpTmp AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpStream AS MEMPTR NO-UNDO.
    
    /* igc - Added Sept 10, 2002 */
    IF cinObjetoPDFDescriptor LE 0 THEN
      cinObjetoPDFDescriptor = cobDocumento:crearObjeto("FontDescriptor").
    
    /* Output the Font Descriptor */
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFDescriptor).
    cobDocumento:cobDestino:agregar("<< /Type /FontDescriptor" + {&pdfSKIP}
        + "   /Ascent " + cchAscender + {&pdfSKIP}
        + "   /Descent " + cchDescender + {&pdfSKIP}
        + "   /CapHeight " + cchAscender + {&pdfSKIP}
        + "   /Flags " + cchFlags + {&pdfSKIP}
        + "   /FontBBox [" + cchFontBBox + "]" + {&pdfSKIP}
        + "   /FontName /" + cchNombre + {&pdfSKIP}
        + "   /ItalicAngle " + STRING(cinItalicAngle) + {&pdfSKIP}).

    asignarObjetoPDF().
    /* igc - Aug 28 - Added this code to allow for remapping of characters */
    IF cinObjetoPDFCodificacion EQ 0 THEN
      cinObjetoPDFCodificacion = cobDocumento:crearObjeto('Encoding').
       
    IF clgEmbebida THEN DO:
      IF cinObjetoPDFStream EQ 0 THEN
        cinObjetoPDFStream = cobDocumento:crearObjeto('FontStream').
      cobDocumento:cobDestino:agregar("   /FontFile2 " + STRING(cinObjetoPDFStream) + " 0 R" + {&pdfSKIP}).
    END.

    cobDocumento:cobDestino:agregar(">>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).

    /* igc - Added Sept 10, 2002 */
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).
    cobDocumento:cobDestino:agregar("<<" + {&pdfSKIP}
        + "/Type /Font" + {&pdfSKIP}
        + "/Subtype /TrueType" + {&pdfSKIP}
        + "/FirstChar " + cchFirstChar + {&pdfSKIP}
        + "/LastChar " + cchLastChar + {&pdfSKIP}
        + "/Widths [ " + cchWidths + " ]" + {&pdfSKIP}
        + "/Encoding " + STRING(cinObjetoPDFCodificacion) + " 0 R" + {&pdfSKIP}
        + "/BaseFont /" + cchNombre + {&pdfSKIP}
        + "/FontDescriptor " + STRING(cinObjetoPDFDescriptor) + " 0 R" + {&pdfSKIP}
        + ">>" + {&pdfSKIP}
        + "endobj" + {&pdfSKIP}).

    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFCodificacion).
    cobDocumento:cobDestino:agregar("<< /Type /Encoding" + {&pdfSKIP}
        + "/BaseEncoding /WinAnsiEncoding" + {&pdfSKIP}).

    IF cchDIF NE "" OR CAN-FIND(FIRST cttDiff WHERE cttDiff.chNombre EQ cchNombre) THEN DO:
      cobDocumento:cobDestino:agregar("/Differences [ " + {&pdfSKIP}).

      IF cchDIF NE '' THEN DO ON ERROR UNDO, THROW:
        DEFINE VARIABLE L_data AS CHARACTER NO-UNDO.
        INPUT STREAM cstIn FROM VALUE(SEARCH(cchDIF)) NO-CONVERT NO-MAP NO-ECHO.
        REPEAT:
          IMPORT STREAM cstIn UNFORMATTED L_data.
          cobDocumento:cobDestino:agregar(L_Data + {&pdfSKIP}).
        END.
        FINALLY:
          INPUT STREAM cstIn CLOSE.
        END FINALLY.
      END. /* Differences File */

      FOR EACH cttDiff WHERE cttDiff.chNombre EQ cchNombre:
        cobDocumento:cobDestino:agregar(STRING(cttDiff.inCaracter) + " " + cttDiff.chNombre + {&pdfSKIP}).
      END.
      cobDocumento:cobDestino:agregar("]"). /* Close the Differences Array */
    END. /* Font Difference File exists, or record */

    cobDocumento:cobDestino:agregar(">>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).

    /* igc - Aug 28 - end of character mapping code */
    IF clgEmbebida THEN DO:
      /* igc - Added Sept 10, 2002 */
      IF cinObjetoPDFStream EQ 0 THEN
        cinObjetoPDFStream = cobDocumento:crearObjeto("FontStream").
      IF cinObjetoPDFStreamLength EQ 0 THEN
        cinObjetoPDFStreamLength = cobDocumento:crearObjeto('FontLength').
      
      COPY-LOB FROM FILE SEARCH(cchFontFile) TO mmpTmp.
      IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
        mmpStream = cobDocumento:cobCompresor:Comprimir(mmpTmp).
      ELSE ASSIGN
        mmpStream = mmpTmp
        mmpTmp = ?
      {&END}
      L_Size = GET-SIZE(mmpStream).

      /* Display Embedded Font Stream */
      cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFStream).
      cobDocumento:cobDestino:agregar("<<" + {&pdfSKIP}
          + "/Length " + STRING(cinObjetoPDFStreamLength) + " 0 R" + {&pdfSKIP}
          + "/Length1 " + STRING(L_Size) + {&pdfSKIP}).
      
      IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
        cobDocumento:cobDestino:agregar("/Filter /FlateDecode" + {&pdfSKIP}).

      cobDocumento:cobDestino:agregar(">>" + {&pdfSKIP} + "stream" + {&pdfSKIP}).

      /* Get PDF Stream Start Offset */
      cobDocumento:cobDestino:agregar(mmpStream).

      cobDocumento:cobDestino:agregar({&pdfSKIP} + "endstream" + {&PDFSKIP} + "endobj" + {&pdfSKIP}).

      /* igc - Added Sept 10, 2002 */
      /* Put out Length */
      cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDFStreamLength).
      cobDocumento:cobDestino:agregar("  " + STRING(L_Size) + {&pdfSKIP} + "endobj" + {&pdfSKIP}).        
    END. /* Embed */
    FINALLY:
      SET-SIZE(mmpTmp) = 0.
      SET-SIZE(mmpStream) = 0.
    END FINALLY.
  END METHOD.

  METHOD PUBLIC CHARACTER CortarTexto(INPUT ipchTexto AS CHARACTER, INPUT ipobRango AS pdf.utiles.Punto, INPUT ipdePuntos AS DECIMAL):
    /* corta el texto para que quepa en el espacio indicado, con el tamaño de letra especificado */
    DEFINE VARIABLE w-chars2fit AS INTEGER    NO-UNDO.
    w-chars2fit = CantidadCaben(ipchTexto, ipobRango,ipdePuntos).
    IF (w-chars2fit LT length(ipchTexto)) THEN
        ASSIGN ipchTexto = SUBSTR(ipchTexto, 1, w-chars2fit).
    RETURN ipchTexto.
  END METHOD.
  METHOD PUBLIC DECIMAL PuntosOptimos(INPUT ipchTexto AS CHARACTER, INPUT ipobRango AS pdf.utiles.Punto, INPUT ipdePuntos AS DECIMAL):
    /* Calculate the best font size to use to insert text into a given range along 
      the X axis - tests in 0.5 point size increments */
    DEFINE VARIABLE w-loop      AS DECIMAL    NO-UNDO.
    DEFINE VARIABLE w-chars2fit AS INTEGER    NO-UNDO.
    DEFINE VARIABLE mdeSmallest AS DECIMAL NO-UNDO.
    DEFINE VARIABLE minLen AS INTEGER NO-UNDO.

    ASSIGN
      minLen = LENGTH(ipchTexto)
      mdeSmallest = 1.0
    {&END}
    BESTLOOP:
    DO w-loop = ipdePuntos TO mdeSmallest BY -0.5:
      ASSIGN
        w-chars2fit = CantidadCaben(ipchTexto, ipobRango,w-loop).
        ipdePuntos = w-loop
      {&END}
      IF w-chars2fit GE minLen THEN
        LEAVE BESTLOOP.
    END.
    IF (ipdePuntos EQ mdeSmallest) AND (w-chars2fit LT minLen) THEN
      RETURN ?.
    RETURN ipdePuntos.
  END METHOD. /* pdf_GetBestFont */
  
END CLASS.