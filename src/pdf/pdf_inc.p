/******************************************************************************

    Program:        pdf_inc.p

    Written By:     D. Abdala - NomadeSoft SRL.
    Written On:     September 10, 2018

    Description:    Wrapper for using ABLPDF with pdfInclude procedures and functions.

    Note:           Based on PDFInclude implementation.

******************************************************************************/

{pdf/pdf.i}

DEFINE VARIABLE linLastY AS INTEGER NO-UNDO.

DEFINE TEMP-TABLE TT_pdf_stream NO-UNDO
  FIELD chStream AS CHARACTER
  FIELD obPDF AS Progress.Lang.Object
  FIELD hnFooter AS HANDLE
  FIELD chFooterProc AS CHARACTER
  FIELD hnHeader AS HANDLE
  FIELD chHeaderProc AS CHARACTER 
  FIELD hnLast AS HANDLE
  FIELD chLastProc AS CHARACTER
{&END}
DEFINE TEMP-TABLE TT_pdf_error NO-UNDO
  FIELD obj_stream  AS CHARACTER
  FIELD obj_func    AS CHARACTER FORMAT "x(20)"
  FIELD obj_error   AS CHARACTER FORMAT "x(40)"
INDEX obj_stream AS PRIMARY
      obj_stream
{&END}
DEFINE TEMP-TABLE TT_pdf_ReplaceTxt /* peki */ NO-UNDO
  FIELD obj_stream  AS CHARACTER
  FIELD mergenr     AS INTEGER
  FIELD txt_from    AS CHARACTER
  FIELD txt_to      AS CHARACTER
INDEX obj_stream    AS PRIMARY
      obj_stream
{&END}
/* This following temp-table is used to store/track XML definitions per stream */
DEFINE TEMP-TABLE TT_pdf_xml NO-UNDO
  FIELD obj_stream  AS CHARACTER
  FIELD xml_parent  AS CHARACTER 
  FIELD xml_pnode   AS INTEGER
  FIELD xml_node    AS CHARACTER
  FIELD xml_value   AS CHARACTER
  FIELD xml_seq     AS INTEGER
INDEX xml_seq AS PRIMARY
      xml_parent
      xml_seq
INDEX xml_pnode 
      xml_pnode .
/* conserva las herramientas instanciadas */
DEFINE TEMP-TABLE TT_pdf_tool NO-UNDO
  FIELD obj_stream   AS CHARACTER
  FIELD tool_name    AS CHARACTER
  FIELD tool_type    AS CHARACTER
  FIELD tool_obj  AS Progress.Lang.Object
INDEX obj_stream AS PRIMARY UNIQUE
      obj_stream
      tool_name.
      
/* conserva los parámetros de las matrices, para especificarlos cuando corresponda*/
DEFINE TEMP-TABLE TT_pdf_mparam NO-UNDO
  FIELD obj_stream AS CHARACTER
  FIELD obj_mat AS CHARACTER
  FIELD mat_row AS INTEGER
  FIELD mat_col AS INTEGER
  FIELD mat_param AS CHARACTER
  FIELD mat_value AS CHARACTER
INDEX obj_stream AS PRIMARY UNIQUE
  obj_stream
  obj_mat
  mat_row
  mat_col
  mat_param.

PROCEDURE pdf_error :  /* Private */
  DEFINE INPUT PARAMETER pdfStream     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFunction   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfError      AS CHARACTER NO-UNDO.

  CREATE TT_pdf_error.
  ASSIGN TT_pdf_error.obj_stream = pdfStream
         TT_pdf_error.obj_func   = pdfFunction
         TT_pdf_error.obj_error  = pdfError.
END. /* pdf_error */

/* ---------------------------- Define FUNCTIONS -------------------------- */
FUNCTION pdf_internal_getPDF RETURNS pdf.Documento
    (INPUT pdfStream AS CHARACTER,
    INPUT PaginaActiva AS LOGICAL): /* PRIVATE? */
  DEFINE VARIABLE lPDF AS pdf.Documento NO-UNDO.
  FIND FIRST TT_pdf_stream
       WHERE TT_pdf_stream.chstream = pdfStream NO-LOCK NO-ERROR.
  IF NOT AVAIL TT_pdf_stream THEN DO:
    RUN pdf_error(pdfStream,PROGRAM-NAME(2),"Cannot find Stream!").
    RETURN ERROR.
  END.  
  lPDF = CAST(TT_pdf_stream.obPDF,pdf.Documento).
  IF PaginaActiva THEN DO:
    IF NOT VALID-OBJECT(lPDF:cobPaginaActual) THEN DO:
      RUN pdf_error(pdfStream,PROGRAM-NAME(2),"There is no active page!").
      RETURN ERROR.
    END.
  END.
  RETURN lPDF.
END FUNCTION.
  
FUNCTION pdf_get_parameter RETURNS CHARACTER
         (INPUT pdfStream     AS CHARACTER,
          INPUT pdfParameter  AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobColor AS pdf.utiles.Color NO-UNDO.
  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).

  IF VALID-OBJECT(mobPDF) THEN DO:
    IF ENTRY(1,pdfParameter,':') EQ 'TagColor' THEN DO:
      mobColor = mobPDF:colorDefinido(ENTRY(2,pdfParameter,':')).
      IF VALID-OBJECT(mobColor) THEN
        RETURN SUBSTITUTE('&1,&2,&3',mobColor:cchRojo,mobColor:cchVerde,mobColor:cchAzul).
      RETURN ''.
    END.
    CASE pdfParameter:
      WHEN 'Compress' THEN DO:
        IF VALID-OBJECT(mobPDf:cobCompresor) THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'Encrypt' THEN DO:
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'UserPassword' THEN DO:
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN
          RETURN mobPDF:cobEncriptador:cchClaveUsuario.
      END.
      WHEN 'MasterPassword' THEN DO:
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN
          RETURN mobPDF:cobEncriptador:cchClaveMaestra.
      END.
      WHEN 'EncryptKey' THEN DO:
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN
          RETURN mobPDF:cobEncriptador:cchLlaveEncriptado.
      END.
      WHEN 'AllowPrint' THEN DO:
        IF mobPDF:cobPermisos:clgImprimir THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowCopy' THEN DO:
        IF mobPDF:cobPermisos:clgCopiar THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowModify' THEN DO:
        IF mobPDF:cobPermisos:clgModificar THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowAnnots' THEN DO:
        IF mobPDF:cobPermisos:clgAnotar THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowForms' THEN DO:
        IF mobPDF:cobPermisos:clgCompletar THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowExtract' THEN DO:
        IF mobPDF:cobPermisos:clgExtraer THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'AllowAssembly' THEN DO:
        IF mobPDF:cobPermisos:clgEnsamblar THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'LineSpacer' THEN DO:
        IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
          RETURN STRING(mobPDF:cobPaginaActual:cinEspacioEntreLineas).
      END.
      WHEN 'HideToolbar' THEN DO:
        IF mobPDF:cobPreferencias:clgOcultarBarraDeHerramientas THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'HideMenubar' THEN DO:
        IF mobPDF:cobPreferencias:clgOcultarBarraDeMenu THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'HideWindowUI' THEN DO:
        IF mobPDF:cobPreferencias:clgOcultarVentana THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'FitWindow' THEN DO:
        IF mobPDF:cobPreferencias:clgAcomodarALaVentana THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'CenterWindow' THEN DO:
        IF mobPDF:cobPreferencias:clgCentrarVentana THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'DisplayDocTitle' THEN DO:
        IF mobPDF:cobPreferencias:clgMostrarTitulo THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'PageMode' THEN
        RETURN mobPDF:cobModoDeVisualizacion:cchTipoPDF.
      WHEN 'PageLayout' THEN
        RETURN mobPDF:cobDisposicionDePagina:cchTipoPDF.
      WHEN 'UseExternalPageSize' THEN
        RETURN 'TRUE'.
      WHEN 'ScaleX' THEN
        RETURN STRING(mobPDF:cdeEscalaEnX).
      WHEN 'ScaleY' THEN
        RETURN STRING(mobPDF:cdeEscalaEnY).
      WHEN 'VERSION' THEN
        RETURN '4.0'.
      WHEN 'UseTags' THEN DO:
        IF mobPDF:clgReemplazarMarcadores THEN
          RETURN 'TRUE'.
        RETURN 'FALSE'.
      END.
      WHEN 'BoldFont' THEN
        RETURN mobPDF:cobLetraNegrita:cchNombre.
      WHEN 'ItalicFont' THEN
        RETURN mobPDF:cobLetraCursiva:cchNombre.
      WHEN 'BoldItalicFont' THEN
        RETURN mobPDF:cobLetraNegritaCursiva:cchNombre.
      WHEN 'DefaultFont' THEN
        RETURN mobPDF:cobLetraNormal:cchNombre.
      WHEN 'DefaultColor' THEN
        RETURN SUBSTITUTE('&1,&2,&3',mobPDF:cobColorTexto:cchRojo,mobPDF:cobColorTexto:cchVerde,mobPDF:cobColorTexto:cchAzul).
      WHEN 'ItalicCount' THEN
        RETURN '0'.
      WHEN 'BoldCount' THEN
        RETURN '0'.
      WHEN 'ColorLevel' THEN
        RETURN '0'.
    END.
  END.
  ELSE
    RETURN "".

END FUNCTION. /* pdf_get_parameter */

FUNCTION pdf_Page RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cinPaginaActual.
END FUNCTION. /* pdf_Page */


FUNCTION pdf_LeftMargin RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobMargenes:cinIzquierda.
END FUNCTION. /* pdf_LeftMargin */

FUNCTION pdf_TopMargin RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobMargenes:cinArriba.
END FUNCTION. /* pdf_TopMargin */

FUNCTION pdf_BottomMargin RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobMargenes:cinAbajo.
END FUNCTION. /* pdf_BottomMargin */

FUNCTION pdf_Font RETURN CHARACTER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobLetraActual:cchNombre.
END FUNCTION. /* pdf_Font */

FUNCTION pdf_Font_Loaded RETURN LOGICAL
        ( INPUT pdfStream AS CHARACTER,
          INPUT pdfFont   AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN VALID-OBJECT(mobPDF:TipoDeLetraDefinido(pdfFont)).
END FUNCTION. /* pdf_Font_Loaded */

FUNCTION pdf_FontType RETURN CHARACTER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF mobPDF:cobLetraActual:cobLetra:cenTipoDeLetra:cinValor EQ pdf.tipos.Letra:AnchoVariable THEN
    RETURN 'VARIABLE'.
  RETURN "FIXED".
END FUNCTION. /* pdf_FontType */

FUNCTION pdf_ImageDim RETURN INTEGER ( INPUT pdfStream AS CHARACTER,
                                       INPUT pdfImage  AS CHARACTER,
                                       INPUT pdfDim    AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobImagen = mobPDF:imagenRegistrada(pdfImage).
  IF VALID-OBJECT(mobImagen) THEN DO:
    IF pdfDim = "HEIGHT" THEN
      RETURN mobImagen:cinAlto.
    ELSE IF pdfDim = "WIDTH" THEN
      RETURN mobImagen:cinAncho.
    ELSE
      RETURN 0.
  END.
  RETURN 0.
END FUNCTION. /* pdf_ImageDim */

FUNCTION pdf_TextX RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX.
END FUNCTION. /* pdf_TextX*/

FUNCTION pdf_TextY RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
END FUNCTION. /* pdf_TextY */

PROCEDURE pdf_new :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFileName AS CHARACTER NO-UNDO.
  
  DEFINE BUFFER B_TT_pdf_Stream FOR TT_pdf_stream.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.

  IF INDEX(pdfStream, " ") > 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_new","Cannot have a space in the Stream Name!").
    RETURN.
  END.

  CREATE B_TT_pdf_stream.
  ASSIGN B_TT_pdf_stream.chstream = pdfStream
         mobPDF = NEW pdf.Documento()
         B_TT_pdf_stream.obPDF   = mobPDF
  {&END}
  mobPDF:cenTipoDePapel:cinValor = pdf.tipos.Papel:Letter.
  mobPDF:cobMargenes:cinArriba = 50.
  mobPDF:cobMargenes:cinAbajo = 1.
  mobPDF:cobMargenes:cinDerecha = 0.
  mobPDF:clgSaltoDePaginaAutomatico = TRUE.
  mobPDF:cobDestino = NEW pdf.destinos.Archivo(pdfFileName).
END. /* pdf_new */

PROCEDURE pdf_open_PDF:
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfName    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfID      AS CHARACTER NO-UNDO.


  DEFINE BUFFER B_TT_pdf_Stream FOR TT_pdf_stream.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPDFE AS pdf.Documento NO-UNDO.  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDFE = pdf_internal_getPDF(pdfID,FALSE).
  IF NOT ERROR-STATUS:ERROR THEN DO:
    RUN pdf_error(pdfStream,PROGRAM-NAME(1),pdfID + " already exists!").
    RETURN ERROR.
  END.
  
  IF INDEX(pdfID, " ") > 0 THEN DO:
    RUN pdf_error(pdfStream,PROGRAM-NAME(1),"Cannot have a space in the Stream Name!").
    RETURN.
  END.
  mobPDFE = NEW pdf.DocumentoExistente(pdfName).
  CREATE B_TT_pdf_stream.
  ASSIGN B_TT_pdf_stream.chstream = pdfID
         B_TT_pdf_stream.obPDF   = mobPDFE
  {&END}    
  mobPDF:usarDocumento(CAST(mobPDFE,pdf.DocumentoExistente)).
END. /* pdf_open_PDF */


FUNCTION pdf_VerticalSpace RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cdeEspacioVertical.
END FUNCTION. /* pdf_VerticalSpace */

FUNCTION pdf_PointSize RETURN DECIMAL ( INPUT pdfStream AS CHARACTER ):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobLetraActual:cdePuntos.
END FUNCTION. /* pdf_PointSize */

FUNCTION pdf_text_width RETURNS INTEGER ( INPUT pdfStream   AS CHARACTER,
                                          INPUT pdfText     AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobLetraActual:cobLetra:AnchoTexto(pdfText,mobPDF:cobLetraActual:cdePuntos).
END FUNCTION. /* pdf_text_width */

FUNCTION pdf_text_widthdec RETURNS DECIMAL ( INPUT pdfStream   AS CHARACTER,
                                             INPUT pdfText     AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobLetraActual:cobLetra:AnchoTextoDec(pdfText,mobPDF:cobLetraActual:cdePuntos).
END FUNCTION. /* pdf_text_widthDec */

FUNCTION pdf_text_widthdec2 RETURNS DECIMAL ( INPUT pdfStream   AS CHARACTER,
                                              INPUT pdfFontTag  AS CHARACTER, 
                                              INPUT pdfFontSize AS DECIMAL,
                                              INPUT pdfText     AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobLetra AS pdf.letras.TipoDeLetra NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobLetra = mobPDF:TipoDeLetraDefinido(pdfFontTag).
  IF NOT VALID-OBJECT(mobLetra) THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_widthdec2","Cannot find Font!").
    RETURN ERROR.
  END.
  RETURN mobLetra:AnchoTextoDec(pdfText,pdfFontSize).
END FUNCTION. /* pdf_text_widthDec2 */

FUNCTION pdf_text_fontwidth RETURNS DECIMAL ( INPUT pdfStream   AS CHARACTER,
                                              INPUT pdfFont     AS CHARACTER,
                                              INPUT pdfText     AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobLetra AS pdf.letras.TipoDeLetra NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobLetra = mobPDF:TipoDeLetraDefinido(pdfFont).
  IF NOT VALID-OBJECT(mobLetra) THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_fontwidth","Cannot find Font!").
    RETURN ERROR.
  END.
  RETURN mobLetra:AnchoTextoDec(pdfText,mobPDF:cobLetraActual:cdePuntos).
END FUNCTION. /* pdf_text_fontwidth */

FUNCTION pdf_text_fontwidth2 RETURNS DECIMAL ( INPUT pdfStream   AS CHARACTER,
                                               INPUT pdfFont     AS CHARACTER,
                                               INPUT pdfFontSize AS DECIMAL,
                                               INPUT pdfText     AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobLetra AS pdf.letras.TipoDeLetra NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobLetra = mobPDF:TipoDeLetraDefinido(pdfFont).
  IF VALID-OBJECT(mobLetra) THEN
    RETURN mobLetra:AnchoTextoDec(pdfText,pdfFontSize).    
  RETURN 0.
END FUNCTION. /* pdf_text_fontwidth2 */

PROCEDURE pdf_set_TextRed :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorTexto:cdeRojo = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:cdeRojo = pdfValue.
END. /* pdf_set_TextRed */

PROCEDURE pdf_set_TextGreen :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorTexto:cdeVerde = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:cdeVerde = pdfValue.
END. /* pdf_set_TextGreen */

PROCEDURE pdf_set_TextBlue :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorTexto:cdeAzul = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:cdeAzul = pdfValue.
END. /* pdf_set_TextBlue */

FUNCTION pdf_TextRed RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorTexto:cdeRojo.
END FUNCTION. /* pdf_TextRed */

FUNCTION pdf_TextGreen RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorTexto:cdeVerde.
END FUNCTION. /* pdf_TextGreen */

FUNCTION pdf_TextBlue RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorTexto:cdeAzul.
END FUNCTION. /* pdf_TextBlue */

PROCEDURE pdf_set_FillRed :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorRelleno:cdeRojo = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:cdeRojo = pdfValue.
END. /* pdf_set_FillRed */

PROCEDURE pdf_set_FillGreen :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorRelleno:cdeVerde = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:cdeVerde = pdfValue.
END. /* pdf_set_FillGreen */

PROCEDURE pdf_set_FillBlue :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorRelleno:cdeAzul = pdfValue.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:cdeAzul = pdfValue.
END. /* pdf_set_FillBlue */

FUNCTION pdf_FillRed RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorRelleno:cdeRojo.
END FUNCTION. /* pdf_FillRed */

FUNCTION pdf_FillGreen RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorRelleno:cdeVerde.
END FUNCTION. /* pdf_FillGreen */

FUNCTION pdf_FillBlue RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobColorRelleno:cdeAzul.
END FUNCTION. /* pdf_FillBlue */

FUNCTION pdf_PageRotate RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cinRotacion.
END FUNCTION. /* pdf_PageRotate */


FUNCTION pdf_PageWidth RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cinAnchoDePagina.
END FUNCTION. /* pdf_PageWidth */

FUNCTION pdf_Pageheight RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cinAltoDePagina.
END FUNCTION. /* pdf_PageHeight */

PROCEDURE pdf_set_PageWidth :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_PageWidth","Page Width cannot be zero!").
    RETURN.
  END.
  mobPDF:cinAnchoDePagina = pdfValue.
END. /* pdf_set_PageWidth */

PROCEDURE pdf_set_PageHeight :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_PageHeight","Page Height cannot be zero!").
    RETURN .
  END.
  mobPDF:cinAltoDePagina = pdfValue.
END. /* pdf_set_PageHeight */

PROCEDURE pdf_set_Page :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_page","Value passed cannot be zero!").
    RETURN.
  END.
  IF mobPDF:cinPaginaActual NE pdfValue THEN
    mobPDF:cinPaginaActual = pdfValue.
END. /* pdf_set_Page */

PROCEDURE pdf_set_PageRotate :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:cinRotacion = pdfValue.
END. /* pdf_set_PageRotate */

FUNCTION pdf_Angle RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN - mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo.
END. /* pdf_Angle */

PROCEDURE pdf_set_TextX :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue < 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_TextX","Value cannot be less than zero!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX = pdfValue.
END. /* pdf_set_TextX */

FUNCTION pdf_Orientation RETURN CHARACTER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF mobPDF:cenOrientacion:cinValor EQ pdf.tipos.Orientacion:Apaisada THEN
    RETURN 'Landscape'.
  RETURN 'Portrait'.
END. /* pdf_Orientation */

PROCEDURE pdf_set_TextY :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo EQ 0 AND pdfValue <= mobPDF:cobMargenes:cinAbajo
  AND NOT mobPDF:clgEnPieDePagina
  THEN DO:
    linLastY = mobPDF:cobMargenes:cinArriba.
    mobPDF:AgregarPagina().
    mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = linLastY.
  END.
  ELSE
    mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = pdfValue.
END. /* pdf_set_TextY */


PROCEDURE pdf_set_GraphicX :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL DECIMALS 4 NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue < 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_GraphicX","Value cannot be less than 0!").
    RETURN.
  END.
  mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinX = pdfValue.
END. /* pdf_set_GraphicX */

PROCEDURE pdf_set_GraphicY :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL DECIMALS 4 NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue < 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_GraphicY","Value cannot be less than zero!").
    RETURN.
  END.
  mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY = pdfValue.
END. /* pdf_set_GraphicY */

FUNCTION pdf_GraphicX RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinX.
END FUNCTION. /* pdf_GraphicX */

FUNCTION pdf_GraphicY RETURN DECIMAL ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY.
END. /* pdf_GraphicY */

PROCEDURE pdf_set_info :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfAttribute AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfvalue     AS CHARACTER NO-UNDO.

  DEFINE VARIABLE L_option  AS CHARACTER NO-UNDO INITIAL "Author,Creator,Producer,Keywords,Subject,Title,OutputTo".
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  IF LOOKUP(pdfAttribute,L_option) = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_info","Invalid Attribute passed!").
    RETURN .
  END.
  CASE pdfAttribute:
    WHEN 'Author' THEN
      mobPDF:cchAutor = pdfValue.
    WHEN 'Creator' THEN
      mobPDF:cchCreador = pdfValue.
    WHEN 'Producer' THEN
      mobPDF:cchProductor = pdfValue.
    WHEN 'Keywords' THEN
      mobPDF:cchPalabrasClave = pdfValue.
    WHEN 'Subject' THEN
      mobPDF:cchAsunto = pdfValue.
    WHEN 'Title' THEN
      mobPDF:cchTitulo = pdfValue.
    OTHERWISE DO:
      IF TYPE-OF(mobPDF:cobDestino,pdf.destinos.Archivo) THEN
        CAST(mobPDF:cobDestino,pdf.destinos.Archivo):cchRuta = pdfValue.
    END.
  END.
END. /* pdf_set_info */

FUNCTION pdf_get_info RETURNS CHARACTER ( INPUT pdfStream    AS CHARACTER,
                                          INPUT pdfAttribute AS CHARACTER):

  DEFINE VARIABLE L_option  AS CHARACTER NO-UNDO INITIAL "Author,Creator,Producer,Keywords,Subject,Title,OutputTo".
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  IF LOOKUP(pdfAttribute,L_option) = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_Get_Info","Invalid Attribute passed!").
    RETURN ERROR.
  END.
  CASE pdfAttribute:
    WHEN 'Author' THEN
      RETURN mobPDF:cchAutor.
    WHEN 'Creator' THEN
      RETURN mobPDF:cchCreador.
    WHEN 'Producer' THEN
      RETURN mobPDF:cchProductor.
    WHEN 'Keywords' THEN
      RETURN mobPDF:cchPalabrasClave.
    WHEN 'Subject' THEN
      RETURN mobPDF:cchAsunto.
    WHEN 'Title' THEN
      RETURN mobPDF:cchTitulo.
    OTHERWISE DO:
      IF TYPE-OF(mobPDF:cobDestino,pdf.destinos.Archivo) THEN
        RETURN CAST(mobPDF:cobDestino,pdf.destinos.Archivo):cchRuta.
    END.
  END.
  RETURN ''.
END FUNCTION. /* pdf_get_info */

FUNCTION pdf_get_pdf_info RETURNS CHARACTER
        (pdfSTREAM AS CHARACTER,
         pdfID     AS CHARACTER,
         pInfo     AS CHARACTER):
/* Returns information about a pdf loaded with pdf_open_pdf */
/* i.e.  numPages = integer(pdf_info("SPDF",1,"pages"))     */
/*       author   = pdf_info("SPDF",1,"author")             */

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPDFE AS pdf.DocumentoExistente NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfID,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF TYPE-OF(mobPDF,pdf.DocumentoExistente) THEN DO:
    mobPDFE = CAST(mobPDF,pdf.DocumentoExistente).
    CASE pInfo:
      WHEN "File" THEN RETURN mobPDFE:cchArchivo.
      WHEN "Version" THEN RETURN mobPDFE:cchVersionPDF.
      WHEN "ModDate" THEN RETURN STRING(mobPDFE:cdaModificacion).
      WHEN "ModTime" THEN RETURN mobPDFE:cchHoraModificacion.
      WHEN "CreationDate" THEN RETURN STRING(mobPDFE:cdaCreacion).
      WHEN "CreationTime" THEN RETURN mobPDFE:cchHoraCreacion.
      WHEN "PageWidth" THEN RETURN STRING(mobPDFE:cobDimensiones:cinAncho).
      WHEN "PageHeight" THEN RETURN STRING(mobPDFE:cobDimensiones:cinAlto).
      WHEN 'Pages' THEN RETURN STRING(mobPDFE:cinCantidadPaginasExistentes).
    END.
  END.
  RETURN "".
END FUNCTION.  /* pdf_get_pdf_info */

PROCEDURE pdf_move_to :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToX       AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToY       AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinX = pdfToX.
  mobPunto:cinY = pdfToY.
  mobPDF:cobPaginaActual:moverA(mobPunto).
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END. /* pdf_moveto */

PROCEDURE pdf_rect :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight    AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight    AS DECIMAL NO-UNDO.    /* JES ADDED */

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobArea = NEW pdf.utiles.Area().
  mobArea:cinX = pdfFromX.
  mobArea:cinY = pdfFromY.
  mobArea:cinAncho = pdfWidth.
  mobArea:cinAlto = pdfHeight.
  mobPDF:cobPaginaActual:Rectangulo(mobArea,pdfWeight).
  /* diferencia en posicionamiento vertical entre implementaciones */
  mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY = mobArea:cinArriba.
  FINALLY:
    DELETE OBJECT mobArea NO-ERROR.
  END FINALLY.
END. /* pdf_rect */

PROCEDURE pdf_rectdec :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX     AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY     AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth     AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight    AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight    AS DECIMAL NO-UNDO.    /* JES ADDED */

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobArea = NEW pdf.utiles.Area().
  mobArea:cinX = pdfFromX.
  mobArea:cinY = pdfFromY.
  mobArea:cinAncho = pdfWidth.
  mobArea:cinAlto = pdfHeight.
  mobPDF:cobPaginaActual:Rectangulo(mobArea,pdfWeight).
  /* diferencia en posicionamiento vertical entre implementaciones */
  mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY = mobArea:cinArriba.
  FINALLY:
    DELETE OBJECT mobArea NO-ERROR.
  END FINALLY.  
END. /* pdf_rectdec */

PROCEDURE pdf_rect2 :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight    AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight    AS DECIMAL NO-UNDO.    /* JES ADDED */

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobArea = NEW pdf.utiles.Area().
  mobArea:cinX = pdfFromX.
  mobArea:cinY = pdfFromY.
  mobArea:cinAncho = pdfWidth.
  mobArea:cinAlto = pdfHeight.
  mobPDF:cobPaginaActual:Rectangulo(mobArea,pdfWeight,'S').
  /* diferencia en posicionamiento vertical entre implementaciones */
  mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY = mobArea:cinArriba.
  FINALLY:
    DELETE OBJECT mobArea NO-ERROR.
  END FINALLY.

END. /* pdf_rect2 */

PROCEDURE pdf_circle :
  /* Note:  pdfX and pdfY represent the center point of the circle.  These
            values become the new Graphic X and Y points after the drawing of
            the circle.  If you want the circle to be filled use pdf_stroke_fill
  */
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfX         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfY         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfRadius    AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight     AS DECIMAL   NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobCentro AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobCentro = NEW pdf.utiles.Punto().
  mobCentro:cinX = pdfX.
  mobCentro:cinY = pdfY.
  mobPDF:cobPaginaActual:Circulo(mobCentro,pdfRadius,pdfWeight).
  FINALLY:
    DELETE OBJECT mobCentro NO-ERROR.
  END FINALLY.
END. /* pdf_circle */

PROCEDURE pdf_curve :
  /* A Bézier curve is added from the current Graphic X/Y Location to X3/Y3 
     using X1/Y1 and X2/Y2) as the control points. The X3/Y3 of the curve 
     becomes the new Graphic X/Y Location.  */
     
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfX1         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfY1         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfX2         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfY2         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfX3         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfY3         AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight     AS DECIMAL   NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP2 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP3 AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobP1 = NEW pdf.utiles.Punto().
  mobP2 = NEW pdf.utiles.Punto().
  mobP3 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfX1.
  mobP1:cinY = pdfY1.
  mobP2:cinX = pdfX2.
  mobP2:cinY = pdfY2.
  mobP3:cinX = pdfX3.
  mobP3:cinY = pdfY3.
  IF mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY EQ 0 OR mobPDF:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinX EQ 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_curve","Graphic X/Y location has not been initialized!").
    RETURN.
  END.
  
  mobPDF:cobPaginaActual:Curva(mobP1,mobP2,mobP3,pdfWeight).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
    DELETE OBJECT mobP2 NO-ERROR.
    DELETE OBJECT mobP3 NO-ERROR.
  END FINALLY.
END. /* pdf_curve */

PROCEDURE pdf_close_path:
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:CerrarCurva().
END.

PROCEDURE pdf_stroke_color :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed       AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen     AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue      AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.
  mobPDF:cobColorPincel:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorPincel:desdeRGB(pdfRed,pdfGreen,pdfBlue).
END. /* pdf_stroke_color */

PROCEDURE pdf_stroke_fill :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed       AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen     AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue      AS DECIMAL NO-UNDO.

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  mobPDF:cobColorRelleno:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:desdeRGB(pdfRed,pdfGreen,pdfBlue).
END. /* pdf_stroke_fill */

PROCEDURE pdf_set_dash :
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfOn      AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfOff     AS INTEGER NO-UNDO.

  IF pdfOn  < 0 THEN pdfOn = 1.
  IF pdfOff < 0 THEN pdfOff = 1.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:lineaInterrumpida(pdfOn,pdfOff).
END. /* pdf_set_dash */

PROCEDURE pdf_set_linejoin :
  /* Note:  This procedure allows you to define the Line Join Styles.  This will
            typically be used when drawing a Rectangle. Possible values are:

              0 - Miter Join
              1 - Round Join
              2 - Bevel Join
  */
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfJoin    AS INTEGER NO-UNDO.

  IF pdfJoin  < 0 OR pdfJoin > 2 THEN pdfJoin = 0.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:cobEstadoGrafico:cenUnionLineas:cinValor =  pdfJoin. 
END. /* pdf_set_linejoin */

PROCEDURE pdf_line :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToX       AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToY       AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight    AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP2 AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobP1 = NEW pdf.utiles.Punto().
  mobP2 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfFromX.
  mobP1:cinY = pdfFromY.
  mobP2:cinX = pdfToX.
  mobP2:cinY = pdfToY.
  mobPDF:cobPaginaActual:Linea(mobP1,mobP2,pdfWeight).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
    DELETE OBJECT mobP2 NO-ERROR.
  END FINALLY.
END. /* pdf_line */

PROCEDURE pdf_line_dec :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX     AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY     AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfToX       AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfToY       AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight    AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP2 AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobP1 = NEW pdf.utiles.Punto().
  mobP2 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfFromX.
  mobP1:cinY = pdfFromY.
  mobP2:cinX = pdfToX.
  mobP2:cinY = pdfToY.
  mobPDF:cobPaginaActual:Linea(mobP1,mobP2,pdfWeight).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
    DELETE OBJECT mobP2 NO-ERROR.
  END FINALLY.
END. /* pdf_line_dec */

PROCEDURE pdf_watermark:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFont     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfSize     AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed      AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen    AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue     AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfX        AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfY        AS INTEGER   NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mchPrevFnt AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mdePrevSz AS DECIMAL NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mchPrevFnt = mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre.
  mdePrevSz = mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos.
  mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = pdfFont.
  mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = pdfSize.
  mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  mobP1 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfX.
  mobP1:cinY = pdfY.
  mobPDF:cobPaginaActual:MarcaDeAgua(pdfText,mobP1).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
    mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = mchPrevFnt.
    mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = mdePrevSz.
  END FINALLY.
END. /* pdf_watermark */

PROCEDURE pdf_text :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE minX AS INTEGER NO-UNDO.
  DEFINE VARIABLE minA AS INTEGER NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  /* el manejo de ángulos es muy diferente, y ni hablar de los desplazamientos */
  linLastY = mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
  minX = mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX.
  mobPDF:cobPaginaActual:texto(pdfText).
  
  minA = pdf_Angle(pdfStream).

  IF minA NE 0 AND minA NE 90 AND minA NE 180 AND minA NE 270 THEN DO:
    RUN pdf_set_TextX(pdfStream, minX).
    RUN pdf_set_TextY(pdfStream, linLastY).
  END.
  ELSE IF minA EQ 90 THEN
    mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:DeltaY(INTEGER(- mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos)).
END. /* pdf_text */

PROCEDURE pdf_text_char :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue    AS INTEGER NO-UNDO.

  DEFINE VARIABLE L_Width       AS INTEGER NO-UNDO.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue <= 0 OR pdfValue > 377 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_char","Value must be >= 1 and <= 377!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:Caracter(pdfValue).
END. /* pdf_text_char */

PROCEDURE pdf_text_charxy :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow      AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_charxy","Column cannot be zero!").
    RETURN .
  END.
  IF pdfRow    = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_charxy","Row cannot be zero!").
    RETURN .
  END.
  mobP1 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfColumn.
  mobP1:cinY = pdfRow.
  mobPDF:cobPaginaActual:Texto(pdfText,mobP1).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
  END FINALLY.
END. /* pdf_text_charxy */

PROCEDURE pdf_text_rotate :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfAngle    AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  /* PDFInclude rota en el sentido de las agujas del reloj, que es justamente
  al revés */
  mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = - pdfAngle.
  CASE pdfAngle:
    WHEN 45 OR WHEN 135 OR
    WHEN 315 OR WHEN 225 THEN DO:
      IF pdfAngle EQ 45 OR pdfAngle EQ 225 THEN
        mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = -45.
      ELSE
        mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 45.
      mobPDF:cobPaginaActual:cdeEscalaEnX = 1.4.
      mobPDF:cobPaginaActual:cdeEscalaEnY = 0.75.
    END.
    OTHERWISE DO:
      mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 0.
      mobPDF:cobPaginaActual:cdeEscalaEnX = 1.
      mobPDF:cobPaginaActual:cdeEscalaEnY = 1.
    END.
  END.
END. /* pdf_text_rotate */

FUNCTION pdf_GetNumFittingChars RETURNS INTEGER
                                ( INPUT pdfStream   AS CHARACTER,
                                  INPUT pdfText     AS CHARACTER,
                                  INPUT pdfFromX    AS INTEGER,
                                  INPUT pdfToX      AS INTEGER ):


  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobP1 AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobP1 = NEW pdf.utiles.Punto().
  mobP1:cinX = pdfFromX.
  mobP1:cinY = pdfToX.
  RETURN mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cobLetra:CantidadCaben(pdfText,mobP1,mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
  END FINALLY.
END FUNCTION. /* pdf_GetNumFittingChars */

PROCEDURE pdf_set_font :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFont     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfSize     AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF NOT VALID-OBJECT(mobPDF:TipoDeLetraDefinido(pdfFont)) THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_font","Font (" + pdfFont + ")has not been loaded!").
    RETURN .
  END.
  mobPDF:cobLetraActual:cchNombre = pdfFont.
  mobPDF:cobLetraActual:cdePuntos = pdfSize.
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN DO:
    mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = pdfFont.
    mobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = pdfSize.
  END.
END. /* pdf_set_font */

PROCEDURE pdf_text_render :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRender   AS INTEGER NO-UNDO.

  IF pdfRender < 0 OR pdfRender > 3 THEN pdfRender = 0.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:cobEstadoTexto:cenEstiloTexto:cinValor = pdfRender.
END. /* pdf_text_render */

PROCEDURE pdf_text_color :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed      AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen    AS DECIMAL NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue     AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobColorTexto:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN
    mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
END. /* pdf_text_color */

PROCEDURE pdf_load_font :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFontName AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFontFile AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFontAFM  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFontDIF  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobLetra AS pdf.letras.TipoDeLetra NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  IF VALID-OBJECT(mobPDF:TipoDeLetraDefinido(ENTRY(1,pdfFontName,'|'))) THEN DO:
    RUN pdf_error(pdfStream,"pdf_load_font","Font '" + pdfFontName + "' has already been loaded!").
    RETURN .
  END.

  mobLetra = NEW pdf.letras.TipoDeLetra(mobPDF,ENTRY(1,pdfFontName,'|'),pdfFontFile,pdfFontAFM,pdfFontDIF).
  mobLetra:clgEmbebida = ENTRY(2,pdfFontName,"|") NE 'NOEMBED' NO-ERROR.
  /* el documento se encarga de la eliminación del tipo de letra */
END. /* pdf_load_font */

PROCEDURE pdf_font_diff:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFontName AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfCharNum  AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfPSName   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobLetra AS pdf.letras.TipoDeLetra NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobLetra = mobPDF:TipoDeLetraDefinido(pdfFontName).
  IF NOT VALID-OBJECT(mobLetra) THEN DO:
    RUN pdf_error(pdfStream,"pdf_font_diff","Cannot find Font Name = " + pdfFontName).
    RETURN .
  END.
  mobLetra:agregarDiff(pdfCharNum,pdfPSName).
END. /* pdf_font_diff */

PROCEDURE pdf_load_image :
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfImageName   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfImageFile   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF INDEX(pdfImageName," ") > 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_load_image","Image Name cannot contain spaces!").
    RETURN .
  END.
  IF VALID-OBJECT(mobPDF:imagenRegistrada(pdfImageName)) THEN DO:
    RUN pdf_error(pdfStream,"pdf_load_image","Image '" + pdfImageName + "' has already been loaded!").
    RETURN .
  END.

  IF SEARCH(pdfImageFile) = ? THEN DO:
    RUN pdf_error(pdfStream,"pdf_load_image","Cannot find Image File when Loading!").
    RETURN .
  END.
  /* determinar tipo en base a la extensión */
  IF INDEX(pdfImageFile,'.png') EQ LENGTH(pdfImageFile) - 3 THEN
    mobImagen = NEW pdf.imagenes.ImagenPNG(mobPDF,pdfImageName,pdfImageFile).
  ELSE
    mobImagen = NEW pdf.imagenes.ImagenJPG(mobPDF,pdfImageName,pdfImageFile).
  /* el documento se encarga de la eliminación de la imagen */
END. /* pdf_load_image */

PROCEDURE pdf_place_image :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfImageName AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn    AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow       AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight    AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
  DEFINE VARIABLE mobDonde AS pdf.utiles.Area NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobImagen = mobPDF:imagenRegistrada(pdfImageName).
  IF NOT VALID-OBJECT(mobImagen) THEN DO:
    RUN pdf_error(pdfStream,"pdf_place_image","Cannot find Image Name for Placement!").
    RETURN .
  END.
  mobDonde = NEW pdf.utiles.Area().
  mobDonde:cinX = pdfColumn.
  mobDonde:cinY = pdfRow.
  mobDonde:cinAncho = pdfWidth.
  mobDonde:cinAlto = pdfHeight.
  
  mobPDF:cobPaginaActual:InsertarImagen(mobImagen,mobDonde).
  FINALLY:
    DELETE OBJECT mobDonde NO-ERROR.
  END FINALLY.
END. /* pdf_place_image */

PROCEDURE pdf_place_image2 :
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfImageName AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn    AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow       AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth     AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight    AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
  DEFINE VARIABLE mobDonde AS pdf.utiles.Area NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobImagen = mobPDF:imagenRegistrada(pdfImageName).
  IF NOT VALID-OBJECT(mobImagen) THEN DO:
    RUN pdf_error(pdfStream,"pdf_place_image2","Cannot find Image Name for Placement!").
    RETURN .
  END.
  mobDonde = NEW pdf.utiles.Area().
  mobDonde:cinX = pdfColumn.
  mobDonde:cinY = pdfRow.
  mobDonde:cinAncho = pdfWidth.
  mobDonde:cinAlto = pdfHeight.
  
  mobPDF:cobPaginaActual:InsertarImagen(mobImagen,mobDonde,TRUE).
  FINALLY:
    DELETE OBJECT mobDonde NO-ERROR.
  END FINALLY.
END. /* pdf_place_image2 */

PROCEDURE pdf_skip :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:cobPaginaActual:SaltoDeLinea().
END. /* pdf_skip */

PROCEDURE pdf_skipn :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfNumber   AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfNumber <= 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_skipn","Lines to skip cannot be <= zero!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:SaltoDeLinea(pdfNumber).
END. /* pdf_skipn */

PROCEDURE pdf_text_xy :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow      AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_xy","Column cannot be zero!").
    RETURN .
  END.
  IF pdfRow    = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_xy","Row cannot be zero!").
    RETURN .
  END.
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinX = pdfColumn.
  mobPunto:cinY = pdfRow.
  mobPDF:cobPaginaActual:Texto(pdfText,mobPunto).
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END. /* pdf_text_xy */

PROCEDURE pdf_text_xy_dec :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow      AS DECIMAL DECIMALS 4 NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_xy_dec","Column cannot be zero!").
    RETURN .
  END.

  IF pdfRow    = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_xy_dec","Row cannot be zero!").
    RETURN .
  END.
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinX = pdfColumn.
  mobPunto:cinY = pdfRow.
  mobPDF:cobPaginaActual:Texto(pdfText,mobPunto).
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END. /* pdf_text_xy_dec */

PROCEDURE pdf_text_boxed_xy :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow      AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth    AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfJustify  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfWeight   AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobDonde AS pdf.utiles.Area NO-UNDO.
  DEFINE VARIABLE menAlineacion AS pdf.tipos.Alineacion NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_boxed_xy","Column cannot be zero!").
    RETURN .
  END.
  IF pdfRow    = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_boxed_xy","Row cannot be zero!").
    RETURN .
  END.
  IF pdfHeight = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_boxed_xy","Height cannot be zero!").
    RETURN .
  END.
  IF pdfWidth  = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_boxed_xy","Width cannot be zero!").
    RETURN .
  END.
  IF LOOKUP(pdfJustify,"Left,Right,Center") = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_boxed_xy","Invalid Justification option passed!").
    RETURN .
  END.
  mobDonde = NEW pdf.utiles.Area().
  mobDonde:cinX = pdfColumn.
  mobDonde:cinY = pdfRow.
  mobDonde:cinAncho = pdfWidth.
  mobDonde:cinAlto = pdfHeight.
  menAlineacion = NEW pdf.tipos.Alineacion().
  IF pdfJustify EQ 'Left' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
  ELSE IF pdfJustify EQ 'Right' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
  ELSE
    menAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
  mobPDF:cobPaginaActual:TextoEnCaja(pdfText,mobDonde,menAlineacion,pdfWeight).
  FINALLY:
    DELETE OBJECT mobDonde NO-ERROR.
    DELETE OBJECT menAlineacion NO-ERROR.
  END FINALLY.
END. /* pdf_text_boxed_xy */

PROCEDURE pdf_text_center:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRow      AS INTEGER NO-UNDO.

  RUN pdf_text_xy (pdfStream,pdfText,pdfColumn
                   - INTEGER(pdf_text_width(pdfStream,pdfText) / 2),pdfRow).

END. /* pdf_text_center */

PROCEDURE pdf_text_at :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_at","Column cannot be zero!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:TextoEnColumna(pdfText,pdfColumn).
END. /* pdf_text_at */

PROCEDURE pdf_text_to:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfColumn   AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfColumn = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_to","Column cannot be zero!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:TextoHastaColumna(pdfText,pdfColumn).
END. /* pdf_text_to */

PROCEDURE pdf_text_align:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfAlign    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfX        AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfY        AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobDonde AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE menAlineacion AS pdf.tipos.Alineacion NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF LOOKUP(pdfAlign,"LEFT,RIGHT,CENTER":U) = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_align","Invalid Alignment option passed!").
    RETURN .
  END.
  IF pdfX = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_align","X location cannot be zero!").
    RETURN .
  END.
  IF pdfY = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_text_align","Y location cannot be zero!").
    RETURN .
  END.
  mobDonde = NEW pdf.utiles.Punto().
  mobDonde:cinX = pdfX.
  mobDonde:cinY = pdfY.
  menAlineacion = NEW pdf.tipos.Alineacion().  
  IF pdfAlign EQ 'LEFT' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
  ELSE IF pdfAlign EQ 'RIGHT' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
  ELSE
    menAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
  mobPDF:cobPaginaActual:TextoAlineado(pdfText,menAlineacion,mobDonde).
  FINALLY:
    DELETE OBJECT mobDonde NO-ERROR.
    DELETE OBJECT menAlineacion NO-ERROR.
  END FINALLY.
END. /* pdf_text_align */

PROCEDURE pdf_set_Angle :  /* PRIVATE */
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  /* PDFInclude acepta una cantidad limitada de ángulos */
  IF LOOKUP(STRING(pdfValue),"0,45,90,135,180,225,270,315") = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_Angle","Invalid Angle option passed!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = - pdfValue.
  CASE pdfValue:
    WHEN 45 OR WHEN 135 OR
    WHEN 315 OR WHEN 225 THEN DO:
      IF pdfValue EQ 45 OR pdfValue EQ 225 THEN
        mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = -45.
      ELSE
        mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 45.
      mobPDF:cobPaginaActual:cdeEscalaEnX = 1.4.
      mobPDF:cobPaginaActual:cdeEscalaEnY = 0.75.
    END.
    OTHERWISE DO:
      mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 0.
      mobPDF:cobPaginaActual:cdeEscalaEnX = 1.
      mobPDF:cobPaginaActual:cdeEscalaEnY = 1.
    END.
  END.
END. /* pdf_set_Angle */

PROCEDURE pdf_set_Orientation :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue EQ 'Landscape' THEN
    mobPDF:cenOrientacion:cinValor = pdf.tipos.Orientacion:Apaisada.
  ELSE
    mobPDF:cenOrientacion:cinValor = pdf.tipos.Orientacion:Vertical.
END. /* pdf_set_Orientation */

PROCEDURE pdf_set_VerticalSpace :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS DECIMAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_VerticalSpace","Vertical Space cannot be zero!").
    RETURN .
  END.
  mobPDF:cobPaginaActual:cdeEspacioVertical = pdfValue.
END. /* pdf_set_VerticalSpace */

PROCEDURE pdf_set_LeftMargin :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_LeftMargin","Left Margin cannot be zero!").
    RETURN .
  END.
  mobPDf:cobMargenes:cinIzquierda = pdfValue.
END. /* pdf_set_LeftMargin */

PROCEDURE pdf_set_TopMargin :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_TopMargin","Top Margin cannot be zero!").
    RETURN .
  END.
  mobPDf:cobMargenes:cinArriba = pdfValue.
END. /* pdf_set_TopMargin */

PROCEDURE pdf_set_BottomMargin :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfValue <= 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_BottomMargin","Bottom Margin cannot be <= zero!").
    RETURN .
  END.
  mobPDf:cobMargenes:cinAbajo = pdfValue.
END. /* pdf_set_BottomMargin */

PROCEDURE pdf_set_PaperType :
  DEFINE INPUT PARAMETER pdfStream          AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue           AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF LOOKUP(pdfValue,"A0,A1,A2,A3,A4,A5,A6,B5,LETTER,LEGAL,LEDGER") = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_PaperType","Invalid Paper Type option passed!").
    RETURN .
  END.
  mobPDf:cenTipoDePapel:cchValor = pdfValue.
END. /* pdf_set_PaperType */

FUNCTION pdf_PaperType RETURN CHARACTER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDf:cenTipoDePapel:ToString().
END. /* pdf_PaperType */

FUNCTION pdf_Render RETURN INTEGER ( INPUT pdfStream AS CHARACTER):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDf:cobPaginaActual:cobEstadoTexto:cenEstiloTexto:cinValor.
END. /* pdf_Render */

FUNCTION pdf_get_wrap_length RETURNS INTEGER ( INPUT pdfStream   AS CHARACTER,
                                               INPUT pdfText AS CHARACTER,
                                               INPUT pdfWidth AS INTEGER ):
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  pdfWidth = mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cobLetra:AnchoTextoDec('w',mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cdePuntos) * pdfWidth.
  mobPDF:cobPaginaActual:alturaConCortes(pdfText,pdfWidth).
END FUNCTION. /* pdf_get_wrap_length */

PROCEDURE pdf_reset_all: 
  /* clear out all streams, and reset variables as required */
  FOR EACH TT_pdf_tool:
    DELETE OBJECT TT_pdf_tool.tool_obj NO-ERROR.
  END.
  /* Clear all temp-tables */
  FOR EACH TT_pdf_stream:
    DELETE OBJECT TT_pdf_stream.obPDF NO-ERROR.
  END.
  EMPTY TEMP-TABLE TT_pdf_stream.
  EMPTY TEMP-TABLE TT_pdf_error.
  EMPTY TEMP-TABLE TT_pdf_ReplaceTxt.
  EMPTY TEMP-TABLE TT_pdf_xml.
  EMPTY TEMP-TABLE TT_pdf_tool.
  EMPTY TEMP-TABLE TT_pdf_mparam.
END. /* pdf_reset_all */

PROCEDURE pdf_reset_stream .
  /* Clear out an individual stream - reset the variables */
  DEFINE INPUT PARAMETER pdfStream     AS CHARACTER NO-UNDO.

  FOR EACH TT_pdf_tool WHERE TT_pdf_tool.obj_stream EQ pdfStream:
    DELETE OBJECT TT_pdf_tool.tool_obj NO-ERROR.
    DELETE TT_pdf_tool.
  END.
  /* As far as I know, you gotta do a for each regardless of version */
  FOR EACH TT_pdf_stream WHERE TT_pdf_stream.chstream = pdfStream:
    DELETE OBJECT TT_pdf_stream.obPDF NO-ERROR.
    DELETE TT_pdf_stream .
  END.
  FOR EACH TT_pdf_error WHERE TT_pdf_error.obj_stream EQ pdfStream:
    DELETE TT_pdf_error.
  END.
  FOR EACH TT_pdf_ReplaceTxt WHERE TT_pdf_ReplaceTxt.obj_stream EQ pdfStream:
    DELETE TT_pdf_ReplaceTxt.
  END.
  FOR EACH TT_pdf_xml WHERE TT_pdf_xml.obj_stream EQ pdfStream:
    DELETE TT_pdf_xml.
  END.
  FOR EACH TT_pdf_mparam WHERE tt_pdf_mparam.obj_stream EQ pdfStream:
    DELETE TT_pdf_mparam.
  END.
END. /* pdf_reset_stream */

PROCEDURE pdf_wrap_text :
/*------------------------------------------------------------------------------
  Purpose:
  Parameters:  <none>
  Notes:
------------------------------------------------------------------------------*/
  DEFINE INPUT PARAMETER pdfStream     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText       AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromColumn AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToColumn   AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pdfAlignMent  AS CHARACTER NO-UNDO.
  DEFINE OUTPUT PARAMETER pdfMaxY      AS INTEGER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE menAlineacion AS pdf.tipos.Alineacion NO-UNDO.
  DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
  DEFINE VARIABLE mdeAncho AS DECIMAL NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  menAlineacion = NEW pdf.tipos.Alineacion().  
  IF pdfAlignment EQ 'CENTER' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
  ELSE IF pdfAlignment EQ 'RIGHT' THEN
    menAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
  ELSE
    menAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
  mobArea = NEW pdf.utiles.Area().
  /* "columns" están medidas en caracteres, pasar a puntos */
  mdeAncho = mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cobLetra:AnchoTextoDec(' ',mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cdePuntos).
  mobArea:cinIzquierda = mdeAncho * pdfFromColumn + mobPDF:cobMargenes:cinIzquierda.
  mdeAncho = mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cobLetra:AnchoTextoDec('W',mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cdePuntos).
  mobArea:cinDerecha = mdeAncho * pdfToColumn + mobPDF:cobMargenes:cinIzquierda.
  mobArea:cinArriba = mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
  mobArea:cinAbajo = 0.
  mobPDf:cobPaginaActual:TextoConCortes(pdfText,mobArea,menAlineacion).
  pdfMaxY = mobPdf:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
  FINALLY:
    DELETE OBJECT menAlineacion NO-ERROR.
    DELETE OBJECT mobArea NO-ERROR.
  END FINALLY.
END PROCEDURE. /* pdf_wrap_text */

FUNCTION pdf_TotalPages RETURN CHARACTER
   (INPUT pdfStream AS CHARACTER).

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  RETURN mobPDF:cchMarcaTotalPaginas.

END FUNCTION. /* pdf_TotalPages */

PROCEDURE pdf_link:
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromX    AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfFromY    AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfWidth    AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfHeight   AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfLink     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed      AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen    AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue     AS DECIMAL   NO-UNDO.
  DEFINE INPUT PARAMETER pdfBorder   AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfStyle    AS CHARACTER NO-UNDO.

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.

  IF LOOKUP(pdfStyle,"N,I,O,P") = 0 THEN
    pdfStyle = "N".

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobEnlace AS pdf.enlaces.URL NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobEnlace = NEW pdf.enlaces.URL(mobPDF).
  mobEnlace:cenEstiloEnlace:cchValor = pdfStyle.
  mobEnlace:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  mobEnlace:cchContenido = pdfLink.
  mobEnlace:cinGrosorBorde = pdfBorder.
  mobEnlace:cobRectangulo:cinIzquierda = pdfFromX.
  mobEnlace:cobRectangulo:cinAbajo = pdfFromY.
  mobEnlace:cobRectangulo:cinDerecha = pdfWidth.
  mobEnlace:cobRectangulo:cinArriba = pdfHeight.
END. /* pdf_link */

PROCEDURE pdf_new_page :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  linLastY = mobPDF:cinAltoDePagina - mobPDF:cobMargenes:cinArriba.
  mobPDF:AgregarPagina().
  mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = linLastY.
  
  PUBLISH "GeneratePDFPage" (INPUT pdfStream, mobPDf:cinPaginaActual).

END. /* pdf_new_page */

PROCEDURE pdf_new_page2 :
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfOrientation AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF pdfOrientation EQ 'Landscape' THEN
    mobPDF:cenOrientacion:cinValor = pdf.tipos.Orientacion:Apaisada.
  ELSE
    mobPDF:cenOrientacion:cinValor = pdf.tipos.Orientacion:Vertical.
  linLastY = mobPDF:cinAltoDePagina - mobPDF:cobMargenes:cinArriba.
  mobPDF:AgregarPagina().
  mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = linLastY.

  PUBLISH "GeneratePDFPage" (INPUT pdfStream, mobPDf:cinPaginaActual).

END. /* pdf_new_page2 */

PROCEDURE pdf_insert_page :
  DEFINE INPUT PARAMETER pdfStream       AS CHARACTER  NO-UNDO.
  DEFINE INPUT PARAMETER pageNo          AS INTEGER    NO-UNDO.
  DEFINE INPUT PARAMETER BeforeOrAfter   AS CHARACTER  NO-UNDO.
  
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:InsertarPagina(pageNo,BeforeOrAfter EQ 'AFTER').
END. /* pdf_insert_page */

PROCEDURE pdf_close :
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPDF:terminar().
  RUN pdf_reset_stream(pdfStream).
END PROCEDURE. /* pdf_Close */

PROCEDURE ProcesarPieDePagina: /* PRIVATE */
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
  
  FOR EACH TT_pdf_stream WHERE TT_pdf_stream.chFooterProc NE '':
    IF ipobDocumento EQ TT_pdf_stream.obPDF THEN DO:
      RUN VALUE(TT_pdf_stream.chFooterProc) IN TT_pdf_stream.hnFooter.
      LEAVE.
    END.
  END.
END PROCEDURE.

FUNCTION pdf_PageFooter RETURN LOGICAL (INPUT pdfStream     AS CHARACTER,
                                        INPUT pdfProcHandle AS HANDLE,
                                        INPUT pdfFooterProc AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  ASSIGN TT_pdf_stream.hnFooter = pdfProCHandle
         TT_pdf_stream.chFooterProc   = pdfFooterProc.
  mobPDF:PieDePagina:Subscribe(THIS-PROCEDURE,'ProcesarPieDePagina') NO-ERROR.  
  RETURN TRUE.
END FUNCTION. /* pdf_PageFooter */

PROCEDURE ProcesarCabeceraDePagina: /* PRIVATE */
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
  
  FOR EACH TT_pdf_stream WHERE TT_pdf_stream.chHeaderProc NE '':
    IF ipobDocumento EQ TT_pdf_stream.obPDF THEN DO:
      RUN VALUE(TT_pdf_stream.chHeaderProc) IN TT_pdf_stream.hnHeader.
      LEAVE.
    END.
  END.
  linLastY = ipobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
END PROCEDURE.

PROCEDURE CeldaMatriz: /* PRIVATE */
  DEFINE INPUT PARAMETER ipobMatriz AS pdf.herramientas.Matriz NO-UNDO.
  
  DEFINE VARIABLE mlgLetra AS LOGICAL NO-UNDO.
  DEFINE VARIABLE mlgColor AS LOGICAL NO-UNDO.
  DEFINE VARIABLE mlgFondo AS LOGICAL NO-UNDO.
  DEFINE VARIABLE mlgTam AS LOGICAL NO-UNDO.
  
  FOR EACH TT_pdf_tool:
    IF TT_pdf_tool.tool_obj EQ ipobMatriz THEN DO:
      ipobMatriz:cenAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
      /* propiedades genéricas de la columna */
      FOR EACH TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ TT_pdf_tool.obj_stream AND
        TT_pdf_mparam.obj_mat EQ TT_pdf_tool.tool_name AND
        TT_pdf_mparam.mat_row EQ 0 AND TT_pdf_mparam.mat_col EQ ipobMatriz:cinColumna:
        CASE TT_pdf_mparam.mat_param:
          WHEN 'ColumnAlign' THEN DO:
            CASE SUBSTRING(TT_pdf_mparam.mat_value,1,1):
              WHEN 'C' THEN
                ipobMatriz:cenAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
              WHEN 'R' THEN
                ipobMatriz:cenAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
              OTHERWISE
                ipobMatriz:cenAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
            END.
          END.
        END.
      END.
      /* propiedades genéricas de la fila */
      FOR EACH TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ TT_pdf_tool.obj_stream AND
        TT_pdf_mparam.obj_mat EQ TT_pdf_tool.tool_name AND
        TT_pdf_mparam.mat_row EQ ipobMatriz:cinFila AND TT_pdf_mparam.mat_col EQ 0:
        CASE TT_pdf_mparam.mat_param:
          WHEN 'Font' THEN
            ipobMatriz:cobLetra:cchNombre = TT_pdf_mparam.mat_value.
          WHEN 'FontSize' THEN
            ipobMatriz:cobLetra:cdePuntos = DECIMAL(TT_pdf_mparam.mat_value).
          WHEN 'TextColor' THEN
            ipobMatriz:cobColor:desdeCadena(TT_pdf_mparam.mat_value).
          WHEN 'BGColor' THEN          
            ipobMatriz:cobColorFondo:desdeCadena(TT_pdf_mparam.mat_value).
        END.
        ASSIGN
          mlgLetra = mlgLetra OR 'Font' EQ TT_pdf_mparam.mat_param        
          mlgTam = mlgTam OR 'FontSize' EQ TT_pdf_mparam.mat_param        
          mlgColor = mlgColor OR 'TextColor' EQ TT_pdf_mparam.mat_param        
          mlgFondo = mlgFondo OR 'BGColor' EQ TT_pdf_mparam.mat_param
        {&END}        
      END.
      /* si no se ha establecido la propiedad específicamente, usar la genérica */
      FOR EACH TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ TT_pdf_tool.obj_stream AND
        TT_pdf_mparam.obj_mat EQ TT_pdf_tool.tool_name AND
        TT_pdf_mparam.mat_row EQ 0 AND
        TT_pdf_mparam.mat_col EQ 0:
        CASE TT_pdf_mparam.mat_param:
          WHEN 'Font' THEN DO:
            IF NOT mlgLetra THEN 
              ipobMatriz:cobLetra:cchNombre = TT_pdf_mparam.mat_value.
          END.
          WHEN 'FontSize' THEN DO:
            IF NOT mlgTam THEN
              ipobMatriz:cobLetra:cdePuntos = DECIMAL(TT_pdf_mparam.mat_value).
          END.
          WHEN 'TextColor' THEN DO:
            IF NOT mlgColor THEN
              ipobMatriz:cobColor:desdeCadena(TT_pdf_mparam.mat_value).
          END.
          WHEN 'BGColor' THEN DO:
            IF NOT mlgFondo THEN          
              ipobMatriz:cobColorFondo:desdeCadena(TT_pdf_mparam.mat_value).
          END.
        END.
      END.
      /* propiedades propias de la celda */
      FOR EACH TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ TT_pdf_tool.obj_stream AND
        TT_pdf_mparam.obj_mat EQ TT_pdf_tool.tool_name AND
        TT_pdf_mparam.mat_row EQ ipobMatriz:cinFila AND
        TT_pdf_mparam.mat_col EQ ipobMAtriz:cinColumna:
        IF TT_pdf_mparam.mat_param EQ 'CellValue' THEN
          ipobMatriz:cchValorCelda = TT_pdf_mparam.mat_value.
      END.
      LEAVE.
    END.
  END.
END PROCEDURE.

PROCEDURE EstablecerUltimoY: /* PRIVATE */
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
  ipobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = linLastY.
END PROCEDURE.

FUNCTION pdf_PageHeader RETURN LOGICAL (INPUT pdfStream     AS CHARACTER,
                                        INPUT pdfProcHandle AS HANDLE,
                                        INPUT pdfHeaderProc AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  ASSIGN TT_pdf_stream.hnHeader = pdfProCHandle
         TT_pdf_stream.chHeaderProc   = pdfHeaderProc.
  mobPDF:CabeceraDePagina:Subscribe(THIS-PROCEDURE,'ProcesarCabeceraDePagina') NO-ERROR.
  mobPDF:InicioDePagina:Subscribe(THIS-PROCEDURE,'EstablecerUltimoY') NO-ERROR.  
  RETURN TRUE.
END FUNCTION. /* pdf_PageHeader */

PROCEDURE ProcesarFinGeneracion: /* PRIVATE */
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
  
  FOR EACH TT_pdf_stream:
    IF ipobDocumento EQ TT_pdf_stream.obPDF THEN DO:
      RUN VALUE(TT_pdf_stream.chLastProc) IN TT_pdf_stream.hnLast.
      LEAVE.
    END.
  END.
END PROCEDURE.

FUNCTION pdf_LastProcedure RETURN LOGICAL (INPUT pdfStream     AS CHARACTER,
                                           INPUT pdfProcHandle AS HANDLE,
                                           INPUT pdfLastProc   AS CHARACTER):

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  ASSIGN TT_pdf_stream.hnLast = pdfProCHandle
         TT_pdf_stream.chLastProc     = pdfLastProc.
  mobPDF:FinDocumento:Subscribe(THIS-PROCEDURE,'ProcesarFinGeneracion') NO-ERROR.  
  RETURN TRUE.
END FUNCTION. /* pdf_LastProcedure */

PROCEDURE pdf_set_parameter:
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfParameter AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfValue     AS CHARACTER NO-UNDO.

  DEFINE VARIABLE L_Error         AS LOGICAL INIT FALSE.
  DEFINE VARIABLE L_ErrorMsg      AS CHARACTER NO-UNDO.
  DEFINE VARIABLE L_Valid_params  AS CHARACTER NO-UNDO.
  DEFINE VARIABLE L_Integer       AS INTEGER NO-UNDO.
  DEFINE VARIABLE L_Decimal       AS DECIMAL NO-UNDO.


  L_Valid_params = "Compress,Encrypt,UserPassword,MasterPassword,EncryptKey,"
                 + "AllowPrint,AllowCopy,AllowModify,AllowAnnots,AllowForms,"
                 + "AllowExtract,AllowAssembly,"
                 + "LineSpacer," 
                 + "HideToolbar,HideMenubar,HideWindowUI,FitWindow,CenterWindow,DisplayDocTitle,"
                 + "PageMode,PageLayout,"
                 + "UseExternalPageSize,"
                 + "ScaleX,ScaleY,VERSION,"
                 + "UseTags,BoldFont,ItalicFont,BoldItalicFont,DefaultFont,DefaultColor,ItalicCount,BoldCount,ColorLevel".


  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  IF (NOT pdfParameter BEGINS "tmp" AND NOT pdfParameter BEGINS "TagColor:")
  AND LOOKUP(pdfParameter,L_valid_params) = 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_set_parameter","Invalid parameter (" + pdfParameter + ") trying to be set!").
    RETURN.
  END.

  IF NOT pdfParameter BEGINS "tmp" 
  AND NOT pdfParameter BEGINS "TagColor:" THEN DO:
    CASE pdfParameter:
      WHEN "Compress" OR WHEN "Encrypt" OR WHEN "AllowPrint"
        OR WHEN "AllowCopy" OR WHEN "AllowModify" OR WHEN "AllowAnnots"
        OR WHEN "AllowForms" OR WHEN "AllowExtract" OR WHEN "AllowAssembly" 
        OR WHEN "HideToolBar" OR WHEN "HideMenuBar" OR WHEN "HideWindowUI"
        OR WHEN "FitWindow" OR WHEN "CenterWindow" OR WHEN "DisplayDocTitle"
        OR WHEN "UseExternalPageSize" OR WHEN "UseTags"
        THEN DO:
          IF pdfValue <> "TRUE" AND pdfValue <> "FALSE" AND pdfValue <> "" THEN
            ASSIGN L_Error    = TRUE
                   L_ErrorMsg = "Only TRUE, FALSE or blank allowed for '" + pdfParameter + "' Parameter!".

        /* Default the Encryption Key to 40 Bits - Rev 2 */
        CASE pdfParameter:
          WHEN "Encrypt" THEN DO:
            IF NOT VALID-OBJECT(mobPDF:cobEncriptador) THEN
              mobPDF:cobEncriptador = NEW pdf.encriptadores.EncriptadorK40(mobPDF).
            ELSE IF NOT TYPE-OF(mobPDF:cobEncriptador,pdf.encriptadores.EncriptadorK40) THEN DO:
              DELETE OBJECT mobPDF:cobEncriptador NO-ERROR.
              mobPDF:cobEncriptador = NEW pdf.encriptadores.EncriptadorK40(mobPDF).
            END.
          END.
          WHEN 'Compress' THEN DO:
            IF VALID-OBJECT(mobPDF:cobCompresor) THEN DO:
              IF NOT TYPE-OF(mobPDF:cobCompresor,pdf.compresores.FlateDecode) THEN DO:
                DELETE OBJECT mobPDF:cobCompresor NO-ERROR.
                mobPDF:cobCompresor = NEW pdf.compresores.FlateDecode().                
              END.
            END.
            ELSE
              mobPDF:cobCompresor = NEW pdf.compresores.FlateDecode().
          END.
          WHEN 'AllowPrint' THEN
            mobPDF:cobPermisos:clgImprimir = LOGICAL(pdfValue).
          WHEN 'AllowCopy' THEN           
            mobPDF:cobPermisos:clgCopiar = LOGICAL(pdfValue).
          WHEN 'AllowModify' THEN           
            mobPDF:cobPermisos:clgModificar = LOGICAL(pdfValue).
          WHEN 'AllowAnnots' THEN           
            mobPDF:cobPermisos:clgAnotar = LOGICAL(pdfValue).
          WHEN 'AllowForms' THEN           
            mobPDF:cobPermisos:clgCompletar = LOGICAL(pdfValue).
          WHEN 'AllowExtract' THEN           
            mobPDF:cobPermisos:clgExtraer = LOGICAL(pdfValue).
          WHEN 'AllowAssembly' THEN           
            mobPDF:cobPermisos:clgEnsamblar = LOGICAL(pdfValue).
          WHEN 'HideToolBar' THEN           
            mobPDF:cobPreferencias:clgOcultarBarraDeHerramientas = LOGICAL(pdfValue).
          WHEN 'HideMenuBar' THEN           
            mobPDF:cobPreferencias:clgOcultarBarraDeMenu = LOGICAL(pdfValue).
          WHEN 'HideWindowUI' THEN           
            mobPDF:cobPreferencias:clgOcultarVentana = LOGICAL(pdfValue).
          WHEN 'FitWindow' THEN           
            mobPDF:cobPreferencias:clgAcomodarALaVentana = LOGICAL(pdfValue).
          WHEN 'CenterWindow' THEN           
            mobPDF:cobPreferencias:clgCentrarVentana = LOGICAL(pdfValue).
          WHEN 'DisplayDocTitle' THEN           
            mobPDF:cobPreferencias:clgMostrarTitulo = LOGICAL(pdfValue).
          WHEN 'UseExternalPageSize' THEN .
          WHEN 'UseTags' THEN 
            mobPDF:clgReemplazarMarcadores = LOGICAL(pdfValue).
        END.           
      END.

      WHEN "EncryptKey" THEN DO:
        /* Currently only allow for 40-Bit Encryption */
        IF pdfValue <> "40" AND pdfValue <> "128"  THEN
          ASSIGN L_Error    = TRUE
                 L_ErrorMsg = "Only a value of 40 or 128 is allowed for the '" + pdfParameter + "' Parameter!".
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN
          mobPDF:cobEncriptador:cchLlaveEncriptado = pdfValue.          
      END.

      WHEN "UserPassword" OR WHEN "MasterPassword" THEN DO:
        IF LENGTH(pdfValue, "character":u) > 32 THEN
          ASSIGN L_Error    = TRUE
                 L_ErrorMsg = "Password string cannot be greater than 32 characters for '" + pdfParameter + "' Parameter!".
        IF VALID-OBJECT(mobPDF:cobEncriptador) THEN DO:
          IF pdfParameter EQ 'UserPassword' THEN
            mobPDF:cobEncriptador:cchClaveUsuario = pdfValue.
          ELSE
            mobPDF:cobEncriptador:cchClaveMaestra = pdfValue.
        END.          
      END.

      WHEN "LineSpacer" THEN DO:
        L_Integer = INT(pdfValue) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
          ASSIGN L_Error    = TRUE
                 L_ErrorMsg = "'LineSpacer' Parameter must be an integer value!".
        ELSE DO:
          pdf_internal_getPDF(pdfStream,TRUE).
          IF ERROR-STATUS:ERROR THEN RETURN ERROR.
          mobPDF:cobPaginaActual:cinEspacioEntreLineas = L_Integer.
        END.
      END.

      WHEN "ScaleX" OR WHEN "ScaleY" THEN DO:
        L_Decimal = DEC(pdfValue) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
          ASSIGN L_Error    = TRUE
                 L_ErrorMsg = "'Scale X/Y' Parameters must be decimal values!".
        ELSE IF pdfParameter EQ 'ScaleX' THEN
          mobPDF:cdeEscalaEnX = L_Decimal.
        ELSE
          mobPDF:cdeEscalaEnY = L_Decimal.
      END.

      WHEN "PageMode" THEN DO:
        CASE pdfValue:
          WHEN 'UseNone' THEN
            mobPDF:cobModoDeVisualizacion:cenTipo:cinValor = pdf.tipos.ModoVisualizacion:Ninguno.
          WHEN 'UseOutlines' THEN
            mobPDF:cobModoDeVisualizacion:cenTipo:cinValor = pdf.tipos.ModoVisualizacion:LineasGuia.
          WHEN 'UseThumbs' THEN
            mobPDF:cobModoDeVisualizacion:cenTipo:cinValor = pdf.tipos.ModoVisualizacion:Solapas.
          WHEN 'FullScreen' THEN
            mobPDF:cobModoDeVisualizacion:cenTipo:cinValor = pdf.tipos.ModoVisualizacion:PantallaCompleta.
          OTHERWISE 
            ASSIGN L_Error    = TRUE
                   L_ErrorMsg = "Invalid entry (" + pdfValue + ") used for PageMode parameter!".
        END.
      END. /* PageMode */

      WHEN "PageLayout" THEN DO:
        CASE pdfValue:
          WHEN 'SinglePage' THEN
            mobPDF:cobDisposicionDePagina:cenTipo:cinValor = pdf.tipos.DisposicionDePagina:PaginaSimple.
          WHEN 'OneColumn' THEN
            mobPDF:cobDisposicionDePagina:cenTipo:cinValor = pdf.tipos.DisposicionDePagina:UnaColumna.
          WHEN 'TwoColumnLeft' THEN
            mobPDF:cobDisposicionDePagina:cenTipo:cinValor = pdf.tipos.DisposicionDePagina:DosColumnasIzquierda.
          WHEN 'TwoColumnRight' THEN
            mobPDF:cobDisposicionDePagina:cenTipo:cinValor = pdf.tipos.DisposicionDePagina:DosColumnasDerecha.
          OTHERWISE 
            ASSIGN L_Error    = TRUE
                   L_ErrorMsg = "Invalid entry (" + pdfValue + ") used for PageLayout parameter!".
        END.
      END. /* PageMode */

    END CASE.

    IF L_Error THEN DO:
      RUN pdf_error(pdfStream,"pdf_set_parameter",L_ErrorMsg).
      RETURN.
    END. /* L_error */
  END.
  ELSE IF pdfParameter BEGINS 'TagColor:' THEN
    mobPDF:definicionColor(ENTRY(2,pdfParameter,':'),DECIMAL(ENTRY(1,pdfValue)),DECIMAL(ENTRY(2,pdfValue)),DECIMAL(ENTRY(3,pdfValue))).  
END. /* pdf_set_parameter */

/* igc - added November 25, 2003 */
PROCEDURE pdf_Bookmark:
  DEFINE INPUT  PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pdfTitle     AS CHARACTER NO-UNDO.
  DEFINE INPUT  PARAMETER pdfParent    AS INTEGER   NO-UNDO.
  DEFINE INPUT  PARAMETER pdfExpand    AS LOGICAL   NO-UNDO.
  DEFINE OUTPUT PARAMETER pdfBookmark  AS INTEGER   NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobMarca AS pdf.utiles.MarcaDeLectura NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobMarca = NEW pdf.utiles.MarcaDeLectura(mobPDF,pdfTitle).
  mobMarca:cobPadre = mobPDF:marcaDeLecturaRegistrada(pdfParent).
  mobMarca:clgExpandir = pdfExpand.
  pdfBookmark = mobPDF:marcaDeLecturaRegistrada(mobMarca).
END. /* pdf_Bookmark */

PROCEDURE pdf_note :
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfNoteText    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfNoteTitle   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfIcon        AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfLLX         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfLLY         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfURX         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfURY         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen       AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue        AS DECIMAL DECIMALS 4 NO-UNDO.

  IF LOOKUP(pdfIcon,"Note,Comment,Insert,Key,Help,NewParagraph,Paragraph") = 0 
  THEN pdfIcon = "Note".

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobEnlace AS pdf.enlaces.Texto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  mobEnlace = NEW pdf.enlaces.Texto(mobPDF).
  mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Texto.
  mobEnlace:cchIcono = pdfIcon.
  mobEnlace:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  mobEnlace:cchContenido = pdfNoteText.
  mobEnlace:cchEstilo = pdfNoteTitle.
  mobEnlace:cobRectangulo:cinIzquierda = pdfLLX.
  mobEnlace:cobRectangulo:cinAbajo = pdfLLY.
  mobEnlace:cobRectangulo:cinDerecha = pdfURX.
  mobEnlace:cobRectangulo:cinArriba = pdfURY.
  mobEnlace:cinGrosorBorde = 0.
END. /* pdf_note */

PROCEDURE pdf_stamp :

  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfStampText   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfTitle       AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfStamp       AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfLLX         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfLLY         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfURX         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfURY         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfRed         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen       AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue        AS DECIMAL DECIMALS 4 NO-UNDO.

  DEFINE VARIABLE l_ValidStamps AS CHARACTER NO-UNDO.

  L_ValidStamps = "Approved,Experimental,NotApproved,"
                + "AsIs,Expired,NotForPublicRelease,"
                + "Confidential,Final,Sold,"
                + "Departmental,ForComment,TopSecret,"
                + "Draft,ForPublicRelease".

  IF LOOKUP(pdfStamp,L_ValidStamps) = 0 THEN
    pdfStamp = "Draft".

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobEnlace AS pdf.enlaces.Texto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  mobEnlace = NEW pdf.enlaces.Texto(mobPDF).
  mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Marca.
  mobEnlace:cchIcono = pdfStamp.
  mobEnlace:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  mobEnlace:cchContenido = pdfStampText.
  mobEnlace:cchEstilo = pdfTitle.
  mobEnlace:cobRectangulo:cinIzquierda = pdfLLX.
  mobEnlace:cobRectangulo:cinAbajo = pdfLLY.
  mobEnlace:cobRectangulo:cinDerecha = pdfURX.
  mobEnlace:cobRectangulo:cinArriba = pdfURY.
  mobEnlace:cinGrosorBorde = 0. 
END. /* pdf_stamp */

PROCEDURE pdf_Markup:

  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfContent     AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfTitle       AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfStyle       AS CHARACTER NO-UNDO CASE-SENSITIVE.

  DEFINE INPUT PARAMETER pdfX1          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfY1          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfX2          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfY2          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfX3          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfY3          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfX4          AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfY4          AS DECIMAL DECIMALS 4 NO-UNDO.

  DEFINE INPUT PARAMETER pdfRed         AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfGreen       AS DECIMAL DECIMALS 4 NO-UNDO.
  DEFINE INPUT PARAMETER pdfBlue        AS DECIMAL DECIMALS 4 NO-UNDO.
  
  IF LOOKUP(pdfStyle,"Highlight,Underline,Squiggly,StrikeOut") = 0 THEN 
    pdfStyle = "Highlight".

  pdfRed   = IF pdfRed < 0 THEN 0
             ELSE IF pdfRed > 1 THEN 1
             ELSE pdfRed.
  pdfGreen = IF pdfGreen < 0 THEN 0
             ELSE IF pdfGreen > 1 THEN 1
             ELSE pdfGreen.
  pdfBlue  = IF pdfBlue < 0 THEN 0
             ELSE IF pdfBlue > 1 THEN 1
             ELSE pdfBlue.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobEnlace AS pdf.enlaces.ModificadorDeTexto NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  mobEnlace = NEW pdf.enlaces.ModificadorDeTexto(mobPDF).
  IF pdfStyle EQ 'Highlight' THEN
    mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Resaltado.
  ELSE IF pdfStyle EQ 'Underline' THEN
    mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Subrayado.
  ELSE IF pdfStyle EQ 'Squiggly' THEN
    mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Rulitos.
  ELSE IF pdfStyle EQ 'StrikeOut' THEN
    mobEnlace:cenTipo:cinValor = pdf.tipos.Enlace:Tachado.
  mobEnlace:cobColor:desdeRGB(pdfRed,pdfGreen,pdfBlue).
  mobEnlace:cchContenido = pdfContent.
  mobEnlace:cobRectangulo:cinIzquierda = pdfX1.
  mobEnlace:cobRectangulo:cinAbajo = pdfY4.
  mobEnlace:cobRectangulo:cinDerecha = pdfX2.
  mobEnlace:cobRectangulo:cinArriba = pdfY1.
  mobEnlace:cobPunto1:cinX = pdfX1.
  mobEnlace:cobPunto1:cinY = pdfY1.
  mobEnlace:cobPunto2:cinX = pdfX2.
  mobEnlace:cobPunto2:cinY = pdfY2.
  mobEnlace:cobPunto3:cinX = pdfX3.
  mobEnlace:cobPunto3:cinY = pdfY3.
  mobEnlace:cobPunto4:cinX = pdfX4.
  mobEnlace:cobPunto4:cinY = pdfY4.
  mobEnlace:cinGrosorBorde = 0. 
END. /* pdf_Markup */

PROCEDURE pdf_rgb :
   def input param vp_Stream              as char no-undo.
   def input param vp_Function            as char no-undo.
   def input param vp_Color               as char no-undo.
   
  DEFINE VARIABLE mobColor AS pdf.utiles.Color NO-UNDO.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(vp_Stream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  CASE vp_Function:
    WHEN "pdf_text_color" THEN
      mobColor = mobPdf:cobColorTexto.
    WHEN "pdf_stroke_color" THEN
      mobColor = mobPdf:cobColorPincel.
    WHEN "pdf_stroke_fill" THEN
      mobColor = mobPdf:cobColorRelleno.
  END.
  mobColor:desdeCadena(vp_Color).
  IF VALID-OBJECT(mobPDF:cobPaginaActual) THEN DO:
    CASE vp_Function:
      WHEN "pdf_text_color" THEN
        mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(mobColor).
      WHEN "pdf_stroke_color" THEN
        mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorPincel:Copiar(mobColor).
      WHEN "pdf_stroke_fill" THEN
        mobPDF:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(mobColor).
    END.    
  END.
END PROCEDURE. /* pdf_rgb */


PROCEDURE pdf_GetBestFont:
/* Calculate the best font size to use to insert text into a given range along 
  the X axis - tests in 0.5 point size increments */

  DEFINE INPUT        PARAMETER pdfStream     AS CHARACTER  NO-UNDO. /* Stream name */
  DEFINE INPUT        PARAMETER pdfFont       AS CHARACTER  NO-UNDO. /* Font to use */
  DEFINE INPUT-OUTPUT PARAMETER pdfText       AS CHARACTER  NO-UNDO. /* Text to measure */
  DEFINE INPUT-OUTPUT PARAMETER pdfFontSize   AS DECIMAL    NO-UNDO. /* Start font size */
  DEFINE INPUT        PARAMETER pdfSmallest   AS DECIMAL    NO-UNDO. /* Smallest font size to use */
  DEFINE INPUT        PARAMETER pdfChopText   AS LOGICAL    NO-UNDO. /* If the smallest font is too */
                                                                       /* big then cut text to fit? */
  DEFINE INPUT        PARAMETER pdfFromX      AS INTEGER    NO-UNDO. /* Start X co-ord */
  DEFINE INPUT        PARAMETER pdfToX        AS INTEGER    NO-UNDO. /* End X co-ord   */

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobFont AS pdf.letras.TipoDeLetra NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE w-loop AS DECIMAL NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobFont = mobPDF:TipoDeLetraDefinido(pdfFont).
  IF NOT VALID-OBJECT(mobFont) THEN DO:
    RUN pdf_error(pdfStream,"pdf_GetBestFont","Cannot find Font!").
    RETURN ERROR.
  END.
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinDesde = pdfFromX.
  mobPunto:cinHasta = pdfToX.
  pdfToX = LENGTH(pdfText).
  BESTLOOP:
  DO w-loop = pdfFontSize TO pdfSmallest BY -0.5:
    pdfFromX = mobFont:CantidadCaben(pdfText,mobPunto,w-loop).
    IF pdfFromX <= pdfToX THEN DO:
      pdfFontSize = w-loop.
      LEAVE BESTLOOP.
    END.
    
    IF (w-loop EQ pdfSmallest) AND (pdfChopText = TRUE) THEN
      ASSIGN pdfText = SUBSTR(pdfText, 1, pdfFromX).
  END.
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END PROCEDURE. /* pdf_GetBestFont */

PROCEDURE pdf_fill_text:
  DEFINE INPUT PARAMETER pdfStream    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfFill      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfText      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfOptions   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobAlign AS pdf.tipos.Alineacion NO-UNDO.
  DEFINE VARIABLE mchAlign AS CHARACTER NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,TRUE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobAlign = NEW pdf.tipos.Alineacion().
  mobAlign:cinValor = pdf.tipos.Alineacion:Izquierda.
  IF pdfOptions NE "" THEN DO:          
    IF INDEX(pdfOptions,"align=") > 0 THEN DO:
      mchAlign = SUBSTRING(pdfOptions,INDEX(pdfOptions,"align=") + 6).
      mchAlign = ENTRY(1,mchAlign).
      CASE mchAlign:
        WHEN 'Right' THEN mobAlign:cinValor = pdf.tipos.Alineacion:Derecha.
        WHEN 'Center' THEN mobAlign:cinValor = pdf.tipos.Alineacion:Centrado.
      END.
    END.
  END. /* Options */
  mobPDF:cobPaginaActual:completarCampoFormulario(pdfFill,pdfText,mobAlign,INDEX(pdfOptions,"multiline") > 0).
  FINALLY:
    DELETE OBJECT mobAlign NO-ERROR.
  END FINALLY.
END. /* pdf_fill_text */


PROCEDURE pdf_ReplaceText:
   DEFINE INPUT PARAMETER pdfStream     AS CHARACTER NO-UNDO.
   DEFINE INPUT PARAMETER pdfMergeNbr   AS INTEGER   NO-UNDO.
   DEFINE INPUT PARAMETER pdfTextFrom   AS CHARACTER NO-UNDO.
   DEFINE INPUT PARAMETER pdfTextTo     AS CHARACTER NO-UNDO.

   CREATE TT_pdf_ReplaceTxt.
   ASSIGN TT_pdf_ReplaceTxt.obj_stream  = pdfStream
          TT_pdf_ReplaceTxt.mergenr     = pdfMergeNbr
          TT_pdf_ReplaceTxt.txt_from    = pdfTextFrom
          TT_pdf_ReplaceTxt.txt_to      = pdfTextTo.
END PROCEDURE. /* pdf_ReplaceText */

PROCEDURE pdf_merge_stream :
    DEF INPUT        PARAM pdfStreamFrom         AS CHAR         NO-UNDO.
    DEF INPUT        PARAM pdfStreamTo           AS CHAR         NO-UNDO.
    DEF INPUT        PARAM pdfNbrCopies          AS INT          NO-UNDO.

  DEFINE VARIABLE mobDesde AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobHacia AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE minCopia AS INTEGER NO-UNDO.
  DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
  DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
  
  mobDesde = pdf_internal_getPDF(pdfStreamFrom,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobHacia = pdf_internal_getPDF(pdfStreamTo,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  DO minCopia = 1 TO pdfNbrCopies:
    DO minPagina = 1 TO mobDesde:cinTotalPaginas:
      mobDesde:cinPaginaActual = minPagina.
      mobPagina = mobHacia:AgregarPagina(mobDesde:cobPaginaActual).
      mobPagina:copiarContenido(mobDesde:cobPaginaActual).
      FOR EACH TT_pdf_ReplaceTxt WHERE TT_pdf_ReplaceTxt.obj_stream EQ pdfStreamFrom
        AND TT_pdf_ReplaceTxt.mergenr EQ minCopia:
        mobPagina:reemplazarTexto(TT_pdf_ReplaceTxt.txt_from,TT_pdf_ReplaceTxt.txt_to).
      END.
      mobPagina:copiarEnlaces(mobDesde:cobPaginaActual).
      mobHacia:copiarMarcasDeLectura(mobDesde,minPagina).
    END.
  END.
  mobHacia:copiarTiposDeLetra(mobDesde).
  mobHacia:copiarImagenes(mobDesde).
END PROCEDURE. /* pdf_merge_stream */



/* Added functionality from Robert Ayris [rayris@comops.com.au] */
PROCEDURE pdf_bind_xml:
  DEFINE OUTPUT PARAMETER TABLE FOR TT_pdf_xml BIND.
END PROCEDURE.

PROCEDURE pdf_load_xml :
  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfXMLFile AS CHARACTER NO-UNDO.

  DEFINE VARIABLE hDoc    AS HANDLE NO-UNDO.
  DEFINE VARIABLE hRoot   AS HANDLE NO-UNDO.
  DEFINE VARIABLE hNode   AS HANDLE NO-UNDO.

  DEFINE VARIABLE Good    AS LOGICAL NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  CREATE X-DOCUMENT hDoc.
  CREATE X-NODEREF  hRoot.
  CREATE X-NODEREF  hNode.

  Good = hDoc:LOAD("FILE",pdfXMLFile,FALSE) NO-ERROR.
  Good = hdoc:GET-DOCUMENT-ELEMENT(hroot) NO-ERROR.

  IF NOT Good THEN STOP.

  RUN LoadXMLNode(pdfstream, hRoot,"/" + hRoot:NAME,0).

  DELETE OBJECT hRoot.
  DELETE OBJECT hDoc.
  DELETE OBJECT hNode.

END. /* pdf_load_xml */

PROCEDURE LoadXMLNode: /* PRIVATE */

  DEFINE INPUT PARAMETER pdfStream   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pNode       AS HANDLE    NO-UNDO.
  DEFINE INPUT PARAMETER pNodeName   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pParentNode AS INTEGER NO-UNDO.

  DEFINE VARIABLE X-Child AS INTEGER NO-UNDO.
  
  DEFINE VARIABLE Good    AS LOGICAL NO-UNDO.

  DEFINE VARIABLE hNode        AS HANDLE NO-UNDO.
  DEFINE VARIABLE hChildValue  AS HANDLE NO-UNDO.
  DEFINE VARIABLE xml-seq AS INTEGER NO-UNDO.

  DEFINE BUFFER B_TT_pdf_xml FOR TT_pdf_xml.

  FOR EACH B_TT_pdf_xml BY B_TT_pdf_xml.xml_seq DESC:
    xml-seq = B_TT_pdf_xml.xml_seq.
    LEAVE.
  END.
  
  CREATE X-NODEREF  hNode.
  CREATE X-NODEREF  hChildValue.

  DO X-Child = 1 TO pNode:NUM-CHILDREN:

    Good = pNode:GET-CHILD(hNode,x-child) NO-ERROR.

    IF NOT Good THEN NEXT.

    IF INDEX(hNode:NAME,"#text") > 0 THEN NEXT.

    Good = hNode:GET-CHILD(hChildValue,1) NO-ERROR.
    IF NOT Good THEN NEXT.

    CREATE B_TT_pdf_xml.
    ASSIGN B_TT_pdf_xml.obj_stream = pdfStream
           B_TT_pdf_xml.xml_parent = pNodeName
           B_TT_pdf_xml.xml_pnode  = pParentNode
           B_TT_pdf_xml.xml_node   = hNode:NAME
           B_TT_pdf_xml.xml_value  = hChildValue:NODE-VALUE
           B_TT_pdf_xml.xml_seq    = xml-seq + 1
           xml-seq                 = xml-seq + 1.

    /* remove CHR(10) from value -- don't know why it's setting this */
    IF B_TT_pdf_xml.xml_value = CHR(10) THEN
      B_TT_pdf_xml.xml_value = "".

    RUN LoadXMLNode(pdfStream, hNode,pNodeName + "/" + hNode:Name,xml-seq).
    FOR EACH B_TT_pdf_xml BY B_TT_pdf_xml.xml_seq DESC:
      xml-seq = B_TT_pdf_xml.xml_seq.
      LEAVE.
    END.

  END.

  DELETE OBJECT hNode.
  DELETE OBJECT hChildValue.
END. /* LoadXMLNode */

FUNCTION GetXMLNodeValue RETURNS CHARACTER 
  (INPUT pParent  AS CHARACTER,
   INPUT pNode    AS CHARACTER ):
  
  DEFINE BUFFER B_TT_pdf_xml FOR TT_pdf_xml.

  FIND FIRST B_TT_pdf_xml 
       WHERE B_TT_pdf_xml.xml_parent = pParent
         AND B_TT_pdf_xml.xml_node   = pNode 
         NO-LOCK NO-ERROR.
  IF AVAIL B_TT_pdf_xml THEN
    RETURN B_TT_pdf_xml.xml_value.
  ELSE
    RETURN "".
END. /* GetXMLNodeValue */

PROCEDURE pdf_use_PDF_page:
  DEFINE INPUT PARAMETER pdfStream  AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfID      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfPage    AS INTEGER   NO-UNDO.

  DEFINE VARIABLE mobEPDF AS pdf.DocumentoExistente NO-UNDO.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
  DEFINE VARIABLE mobPEx AS pdf.PaginaExistente NO-UNDO.
  mobEPDF = CAST(pdf_internal_getPDF(pdfID,FALSE),pdf.DocumentoExistente).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  mobPEx = mobEPDF:paginaExistente(pdfPage).
  IF NOT VALID-OBJECT(mobPEx) THEN DO:
    RUN pdf_error(pdfStream,"pdf_use_PDF_Page","Invalid Page # for PDF ID = " + pdfID).
    RETURN.    
  END.
  mobPDF:usarPaginaExterna(mobPEx).
  RUN ProcesarCabeceraDePagina(mobPDF).
END. /* pdf_use_PDF_page */

PROCEDURE pdf_tool_add : 
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolName    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolType    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolData    AS HANDLE    NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobTabla AS pdf.herramientas.Tabla NO-UNDO.
  DEFINE VARIABLE mobCalendario AS pdf.herramientas.Calendario NO-UNDO.
  DEFINE VARIABLE mobMatriz AS pdf.herramientas.Matriz NO-UNDO.
  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  IF INDEX(pdfToolName," ") > 0 THEN DO:
    RUN pdf_error(pdfStream,"pdf_tool_add","Tool Name cannot contain spaces!").
    RETURN .
  END.

  CREATE TT_pdf_tool.
  ASSIGN TT_pdf_tool.obj_stream   = pdfStream
         TT_pdf_tool.tool_name    = pdfToolName
         TT_pdf_tool.tool_Type    = pdfToolType
  .
  /* Now configure a bunch of defaults for the Tool */
  CASE TT_pdf_tool.tool_type:
    WHEN "TABLE" THEN DO:
      mobTabla  = NEW pdf.herramientas.Tabla(mobPDF,pdfToolData).
      TT_pdf_tool.tool_obj  = mobTabla.
      mobTabla:cobLetraTitulo:cchNombre = "Courier-Bold".
      mobTabla:cobLetraTitulo:cdePuntos = 10.
      mobTabla:cobFondoTitulo:desdeRGB(1,1,1).
      mobTabla:cobColorTitulo:desdeRGB(0,0,0).
      mobTabla:cobLetraContenido:cchNombre = "Courier".
      mobTabla:cobLetraContenido:cdePuntos = 10.
      mobTabla:cobFondoContenido:desdeRGB(1,1,1).
      mobTabla:cobColorContenido:desdeRGB(0,0,0).
      mobTabla:cobSeparacion:cinX = 5.
      mobTabla:cobSeparacion:cinY = 0.
    END.
    WHEN 'CALENDAR' THEN DO:
      mobCalendario = NEW pdf.herramientas.CalendarioMensual(mobPDF).
      TT_pdf_tool.tool_obj  = mobCalendario.
    END.
    WHEN 'MATRIX' THEN DO:
      mobMatriz  = NEW pdf.herramientas.Matriz(mobPDF).
      mobMAtriz:cinSeparacionBorde = 3.
      TT_pdf_tool.tool_obj  = mobMatriz.
      FOR EACH TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ pdfStream
        AND TT_pdf_mparam.obj_mat EQ pdfToolName:
        DELETE TT_pdf_mparam.
      END.
    END.
  END CASE.
END. /* pdf_tool_add */
PROCEDURE garantizarMParam: /* PRIVATE */
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolName    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolCol     AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolRow     AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolParam   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolValue   AS CHARACTER NO-UNDO.
  
    FIND TT_pdf_mparam WHERE TT_pdf_mparam.obj_stream EQ pdfStream AND TT_pdf_mparam.obj_mat EQ pdfToolName AND TT_pdf_mparam.mat_col EQ pdfToolCol
      AND TT_pdf_mparam.mat_row EQ pdfToolRow AND TT_pdf_mparam.mat_param EQ pdfToolParam NO-ERROR.
    IF NOT AVAILABLE TT_pdf_mparam THEN DO:
      CREATE TT_pdf_mparam.
      ASSIGN
        TT_pdf_mparam.obj_stream = pdfStream
        TT_pdf_mparam.obj_mat = pdfToolName
        TT_pdf_mparam.mat_col = pdfToolCol
        TT_pdf_mparam.mat_row = pdfToolRow
        TT_pdf_mparam.mat_param = pdfToolParam
      {&END}
    END.
    TT_pdf_mparam.mat_value = pdfToolValue.
END PROCEDURE.
PROCEDURE pdf_set_tool_parameter :

  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolName    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolParam   AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolCol     AS INTEGER   NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolValue   AS CHARACTER NO-UNDO.

  DEFINE VARIABLE L_Integer      AS INTEGER NO-UNDO.
  DEFINE VARIABLE L_Decimal      AS DECIMAL NO-UNDO.
  DEFINE VARIABLE minNumero AS INTEGER NO-UNDO.
  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.

  DEFINE VARIABLE L_TableParams  AS CHARACTER NO-UNDO.
  L_TableParams = "Outline,CellUnderline,"
                + "ColumnHeader,ColumnWidth,ColumnX,ColumnPadding,MaxX,MaxY,"
                + "HeaderFont,HeaderFontSize,HeaderBGColor,HeaderTextColor,"
                + "DetailFont,DetailFontSize,DetailBGColor,DetailTextColor,"
                + "UseFields,StartY,Pages".

  FIND TT_pdf_tool
       WHERE TT_pdf_tool.obj_stream = pdfStream
         AND TT_pdf_tool.tool_name  = pdfToolName NO-LOCK NO-ERROR.
  IF NOT AVAIL TT_pdf_Tool THEN DO:
    RUN pdf_error(pdfStream,"pdf_tool_parameter","Cannot find Tool ("
                                              + pdfToolName + "for Stream ("
                                              + pdfStream + "!").
    RETURN .
  END.
  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobTabla AS pdf.herramientas.Tabla NO-UNDO.
  DEFINE VARIABLE mobCalendario AS pdf.herramientas.Calendario NO-UNDO.
  DEFINE VARIABLE mobMatriz AS pdf.herramientas.Matriz NO-UNDO.
  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.

  CASE TT_pdf_tool.tool_type:
    WHEN "TABLE" THEN DO:
      IF LOOKUP(pdfToolParam,L_TableParams) = 0 THEN DO:
        RUN pdf_error(pdfStream,"pdf_tool_parameter","Invalid Table Parameter entered(" + pdfToolName + ")!").
        RETURN .
      END.

      /* Verify for Integer Content */
      IF LOOKUP(pdfToolParam,"ColumnWidth,ColumnX,MaxX,MaxY,Outline,CellUnderline,Pages,StartY") > 0 
      THEN DO:
        L_Integer = INT(pdfToolValue) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
          RUN pdf_error(pdfStream,"pdf_tool_parameter",
                                  "Parameter (" + pdfToolParam + ") requires"
                                  + " an Integer value!").
          RETURN .
        END.

        IF LOOKUP(pdfToolParam,"Outline") = 0 AND L_Integer <= 0 THEN DO:
          RUN pdf_error(pdfStream,"pdf_tool_parameter",
                                  "Parameter (" + pdfToolParam + ") requires"
                                  + " a positive (non-zero) value!").
          RETURN .
        END.
      END. /* Integer Verification */

      ELSE IF LOOKUP(pdfToolParam,"HeaderFontSize,DetailFontSize") > 0 THEN DO:
        L_Decimal = DEC(pdfToolValue) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
          RUN pdf_error(pdfStream,"pdf_tool_parameter",
                                  "Parameter (" + pdfToolParam + ") requires"
                                  + " a Decimal value!").
          RETURN .
        END.
      END. /* Decimal Verification */

      ELSE IF LOOKUP(pdfToolParam,"HeaderBGColor,DetailBGColor,HeaderTextColor,DetailTextColor") > 0 THEN DO:
        IF NUM-ENTRIES(pdfToolValue) <> 3 THEN DO:
          RUN pdf_error(pdfStream,"pdf_tool_parameter",
                                  "Parameter (" + pdfToolParam + ") requires"
                                  + " 3 Entries in RGB sequence comma-delimited!").
          RETURN .
        END.
      END. /* Color Verification */

      ELSE IF LOOKUP(pdfToolParam,"HeaderFont,DetailFont") > 0 THEN DO:
        IF mobPDF:TipoDeLetraDefinido(pdfToolValue) EQ ? THEN DO:
          RUN pdf_error(pdfStream,"pdf_tool_parameter",
                                  "Parameter (" + pdfToolParam + ") requires"
                                  + " an Valid Font Name!").
          RETURN .
        END.
      END. /* Font Name Verification */
      mobTabla = CAST(TT_pdf_tool.tool_obj,pdf.herramientas.Tabla).  
      CASE pdfToolParam:
        WHEN "Outline" THEN
          mobTabla:cdeAnchoBordes = DECIMAL(pdfToolValue).
        WHEN "CellUnderline" THEN
          mobTabla:cdeAnchoBordes = DECIMAL(pdfToolValue).
        WHEN "ColumnHeader" THEN DO:
          IF NUM-ENTRIES(mobTabla:cchTitulos) LT pdfToolCol THEN
            mobTabla:cchTitulos = mobTabla:cchTitulos + FILL(',',pdfToolCol - NUM-ENTRIES(mobTabla:cchTitulos)).
          ENTRY(pdfToolCol,mobTabla:cchTitulos) = pdfToolValue.
        END.
        WHEN "ColumnWidth" THEN DO:
          IF NUM-ENTRIES(mobTabla:cchAnchoColumnas) LT pdfToolCol THEN
            mobTabla:cchAnchoColumnas = mobTabla:cchAnchoColumnas + FILL(',',pdfToolCol - NUM-ENTRIES(mobTabla:cchAnchoColumnas)).
          /* el ancho se especifica en caracteres, cambiarlo a puntos */          
          ENTRY(pdfToolCol,mobTabla:cchAnchoColumnas) = STRING(INTEGER(mobTabla:cobLetraContenido:cobLetra:AnchoTexto('WiDd',mobTabla:cobLetraContenido:cdePuntos) / 4 * INTEGER(pdfToolValue))).
        END.
        WHEN "ColumnX" THEN
          /* no implementado */.
        WHEN "ColumnPadding" THEN
          mobTabla:cobSeparacion:cinX = INTEGER(pdfToolValue).
        WHEN "MaxX" THEN
          mobTabla:cobArea:cinDerecha = INTEGER(pdfToolValue).          
        WHEN "MaxY" THEN
          mobTabla:cobArea:cinArriba = INTEGER(pdfToolValue).          
        WHEN "HeaderFont" THEN
          mobTabla:cobLetraTitulo:cchNombre = pdfToolValue.
        WHEN "HeaderFontSize" THEN
          mobTabla:cobLetraTitulo:cdePuntos = DECIMAL(pdfToolValue).
        WHEN "HeaderBGColor" THEN
          mobTabla:cobFondoTitulo:desdeCadena(pdfToolValue).
        WHEN "HeaderTextColor" THEN
          mobTabla:cobColorTitulo:desdeCadena(pdfToolValue).
        WHEN "DetailFont" THEN
          mobTabla:cobLetraContenido:cchNombre = pdfToolValue.
        WHEN "DetailFontSize" THEN
          mobTabla:cobLetraContenido:cdePuntos = DECIMAL(pdfToolValue).
        WHEN "DetailBGColor" THEN
          mobTabla:cobFondoContenido:desdeCadena(pdfToolValue).
        WHEN "DetailTextColor" THEN
          mobTabla:cobColorContenido:desdeCadena(pdfToolVAlue).
        WHEN "UseFields" THEN DO:
          DO minIndex = 1 TO NUM-ENTRIES(pdfToolValue):
            minNumero = INTEGER(ENTRY(minIndex,pdfToolValue)).
            IF minNumero GT NUM-ENTRIES(mobTabla:cchTitulos) THEN
              mobTabla:cchTitulos = mobTabla:cchTitulos + FILL(',',minNumero - NUM-ENTRIES(mobTabla:cchTitulos)).
            ENTRY(minNumero,mobTabla:cchTitulos) = ''.
          END.
        END.
        WHEN "StartY" THEN
          mobTabla:cobArea:cinAbajo = INTEGER(pdfToolValue).          
        WHEN "Pages" THEN
          /* no implementado */.
      END.
    END. /* Table Parameter Check */
    WHEN 'CALENDAR' THEN DO:
      mobCalendario = CAST(TT_pdf_tool.tool_obj,pdf.herramientas.Calendario).
      CASE pdfToolParam:
        WHEN "Outline" THEN
          mobCalendario:cdeAnchoBordes = DECIMAL(pdfToolValue).
        WHEN "MaxX" THEN
          mobCalendario:cobArea:cinDerecha = INTEGER(pdfToolValue).          
        WHEN "MaxY" THEN
          mobCalendario:cobArea:cinAbajo = INTEGER(pdfToolValue).          
        WHEN "HeaderFont" THEN 
          mobCalendario:cobLetraTitulo:cchNombre = pdfToolValue.
        WHEN "DayLabelFont" THEN 
          mobCalendario:cobLetraRotulos:cchNombre = pdfToolValue.
        WHEN "HeaderFontSize" THEN
          mobCalendario:cobLetraTitulo:cdePuntos = DECIMAL(pdfToolValue).
        WHEN "DayLabelFontSize" THEN
          mobCalendario:cobLetraRotulos:cdePuntos = DECIMAL(pdfToolValue).
        WHEN "HeaderBGColor"  THEN
          mobCalendario:cobColorFondoTitulo:desdeCadena(pdfToolValue).
        WHEN "DayLabelBGColor" THEN
          mobCalendario:cobColorFondoRotulos:desdeCadena(pdfToolValue).
        WHEN "HeaderTextColor" OR WHEN "HeaderFontColor" THEN
          mobCalendario:cobColorTitulo:desdeCadena(pdfToolValue).
        WHEN "DayLabelFontColor" THEN
          mobCalendario:cobColorRotulos:desdeCadena(pdfToolValue).
        WHEN "DetailFont" THEN
          mobCalendario:cobLetraElemento:cchNombre = pdfToolValue.
        WHEN "DetailFontSize" THEN
          mobCalendario:cobLetraElemento:cdePuntos = DECIMAL(pdfToolValue).
        WHEN "DetailBGColor" THEN
          mobCalendario:cobColorFondoElemento:desdeCadena(pdfToolValue).
        WHEN "DetailTextColor" THEN
          mobCalendario:cobColorElemento:desdeCadena(pdfToolVAlue).
        WHEN "StartY" THEN DO:
          minNumero = mobCalendario:cobArea:cinAlto.
          mobCalendario:cobArea:cinAbajo = INTEGER(pdfToolValue) + mobPDF:cobMargenes:cinAbajo.
          mobCalendario:cobArea:cinAlto = minNumero.
        END.
        WHEN "HeaderHeight" THEN
          mobCalendario:cinAltoCabecera = INTEGER(pdfToolValue).          
        WHEN "DayLabelHeight" THEN
          mobCalendario:cinAltoRotulo = INTEGER(pdfToolValue).          
        WHEN "Title" THEN
          mobCalendario:cchTitulo = pdfToolValue.
        WHEN "Height" THEN
          mobCalendario:cobArea:cinAlto = INTEGER(pdfToolValue).
        WHEN "Width" THEN
          mobCalendario:cobArea:cinAncho = INTEGER(pdfToolValue).
        WHEN "X" THEN DO:
          minNumero = mobCalendario:cobArea:cinAncho.
          mobCalendario:cobArea:cinIzquierda = INTEGER(pdfToolValue) + mobPDF:cobMargenes:cinIzquierda.
          mobCalendario:cobArea:cinAncho = minNumero.
        END.
        WHEN "Y" THEN DO:
          minNumero = mobCalendario:cobArea:cinAlto.
          mobCalendario:cobArea:cinAbajo = INTEGER(pdfToolValue) + mobPDF:cobMargenes:cinAbajo.
          mobCalendario:cobArea:cinAlto = minNumero.
        END.
        WHEN "Year" THEN
          mobCalendario:cdaFecha = DATE(MONTH(mobCalendario:cdaFecha),DAY(mobCalendario:cdaFecha),INTEGER(pdfToolValue)).
        WHEN "Month" THEN
          mobCalendario:cdaFecha = DATE(INTEGER(pdfToolValue),DAY(mobCalendario:cdaFecha),YEAR(mobCalendario:cdaFecha)).
        WHEN "Weekdays" THEN
          mobCalendario:cchDias = pdfToolValue.
        WHEN "DayFontSize" THEN
          mobCalendario:cobLetraElemento:cdePuntos = INTEGER(pdfToolValue).
        WHEN "DayFont" THEN
          mobCalendario:cobLetraElemento:cchNombre = pdfToolValue.
        WHEN "DayBGColor" THEN
          mobCalendario:cobColorFondoElemento:desdeCadena(pdfToolValue).
        WHEN "DayFontColor" THEN
          mobCalendario:cobColorElemento:desdeCadena(pdfToolValue).
      END.
    END.
    WHEN 'MATRIX' THEN DO:
      mobMatriz = CAST(TT_pdf_tool.tool_obj,pdf.herramientas.Matriz).
      /* las "propiedades" se establecen por fila en PDFInclude */
      CASE pdfToolParam:
        WHEN "Outline"  OR WHEN "GridWeight" THEN
          mobMatriz:cdeAnchoBordes = DECIMAL(pdfToolValue).
        WHEN "MaxX" THEN
          mobMatriz:cobArea:cinDerecha = INTEGER(pdfToolValue).          
        WHEN "MaxY" THEN
          mobMatriz:cobArea:cinAbajo = INTEGER(pdfToolValue).          
        WHEN "Font" THEN DO:
          IF pdfToolCol EQ 0 THEN DO:
            mobMatriz:cobLetra:cchNombre = pdfToolValue.
            RUN garantizarMParam(pdfStream,pdfToolName,0,0,'Font',pdfToolValue).
          END.
          ELSE DO:
            RUN garantizarMParam(pdfStream,pdfToolName,0,pdfToolCol,'Font',pdfToolValue).
            mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
          END.          
        END.
        WHEN "FontSize" THEN DO:
          IF pdfToolCol EQ 0 THEN DO:
            mobMatriz:cobArea:cinArriba = mobMatriz:cobArea:cinArriba - mobMatriz:cobLetra:cdePuntos.
            mobMatriz:cobLetra:cdePuntos = DECIMAL(pdfToolValue).
            mobMatriz:cobArea:cinArriba = mobMatriz:cobArea:cinArriba + mobMatriz:cobLetra:cdePuntos.
            mobMatriz:cobArea:cinAbajo = mobMatriz:cobArea:cinArriba - mobMatriz:cinFilas * (mobMatriz:cobLetra:cdePuntos + mobMatriz:cinAnchoBorde * 2).
            RUN garantizarMParam(pdfStream,pdfToolName,0,0,'FontSize',pdfToolValue).
          END.
          ELSE DO:
            RUN garantizarMParam(pdfStream,pdfToolName,0,pdfToolCol,'FontSize',pdfToolValue).
            mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
          END.
        END.
        WHEN "BGColor" THEN DO:
          IF pdfToolCol EQ 0 THEN DO:
            mobMatriz:cobColorFondo:desdeCadena(pdfToolValue).
            RUN garantizarMParam(pdfStream,pdfToolName,0,0,'BGColor',pdfToolValue).
          END.
          ELSE DO:
            RUN garantizarMParam(pdfStream,pdfToolName,0,pdfToolCol,'BGColor',pdfToolValue).
            mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
          END.
        END.
        WHEN "GridColor" THEN
          mobMatriz:cobColorBorde:desdeCadena(pdfToolValue).
        WHEN "TextColor" THEN DO:
          IF pdfToolCol EQ 0 THEN DO:
            mobMatriz:cobColor:desdeCadena(pdfToolValue).
            RUN garantizarMParam(pdfStream,pdfToolName,0,0,'TextColor',pdfToolValue).
          END.
          ELSE DO:
            RUN garantizarMParam(pdfStream,pdfToolName,0,pdfToolCol,'TextColor',pdfToolValue).
            mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
          END.
        END.
        WHEN "X" THEN
          mobMatriz:cobArea:cinIzquierda = INTEGER(pdfToolValue).
        WHEN "Y" OR WHEN 'StartY' THEN DO:
          /* la implementación anterior utiliza como "Y", la base de la primer fila */
          mobMatriz:cobArea:cinArriba = INTEGER(pdfToolValue) + mobMatriz:cobLetra:cdePuntos + mobMatriz:cinAnchoBorde.
        END.
        WHEN "Rows" THEN DO:
          mobMatriz:cinFilas = INTEGER(pdfToolValue).
          /* el alto de la matriz se calcula en base a la cantidad de filas (12 según PDFInclude) */
          mobMatriz:cobArea:cinAbajo = mobMatriz:cobArea:cinArriba - mobMatriz:cinFilas * (mobMatriz:cobLetra:cdePuntos + mobMatriz:cinAnchoBorde * 2).
        END.                    
        WHEN "Cols" OR WHEN "Columns" THEN
          mobMatriz:cinColumnas = INTEGER(pdfToolValue).
        WHEN 'ColumnWidth' THEN DO:
          IF NUM-ENTRIES(mobMatriz:cchAnchoColumna) LT pdfToolCol THEN
            mobMatriz:cchAnchoColumna = mobMatriz:cchAnchoColumna + FILL(',', pdfToolCol - NUM-ENTRIES(mobMatriz:cchAnchoColumna)).
          ENTRY(pdfToolCol,mobMatriz:cchAnchoColumna) = pdfToolValue.
          L_integer = 0.
          DO minNumero = 1 TO NUM-ENTRIES(mobMatriz:cchAnchoColumna):
            L_integer = L_integer + INTEGER(ENTRY(minNumero,mobMatriz:cchAnchoColumna)).
          END.
          mobMatriz:cobArea:cinAncho = L_integer.  
        END.
        WHEN 'ColumnAlign' THEN DO:
          RUN garantizarMParam(pdfStream,pdfToolName,pdfToolCol,0,'ColumnAlign',pdfToolValue).
          mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
        END.
        WHEN 'CellValue' THEN DO:
          RUN garantizarMParam(pdfStream,pdfToolName,(pdfToolCol - 1) MODULO mobMatriz:cinColumnas + 1,TRUNCATE((pdfToolCol - 1) / mobMatriz:cinColumnas,0) + 1,'CellValue',pdfToolValue).
          mobMatriz:inicioCelda:Subscribe("CeldaMatriz") NO-ERROR. 
        END.
      END.
    END.
  END CASE.

END. /* pdf_set_tool_parameter */

PROCEDURE pdf_tool_create : /* PRIVATE */
  DEFINE INPUT PARAMETER pdfStream      AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfToolName    AS CHARACTER NO-UNDO.

  FIND TT_pdf_tool
       WHERE TT_pdf_tool.obj_stream = pdfStream
       AND TT_pdf_tool.tool_name  = pdfToolName NO-LOCK NO-ERROR.
  IF NOT AVAIL TT_pdf_Tool THEN DO:
    RUN pdf_error(pdfStream,"pdf_tool_create","Cannot find Tool ("
                                              + pdfToolName + "for Stream ("
                                              + pdfStream + "!").
    RETURN .
  END.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  IF NOT VALID-OBJECT(mobPDF:cobPaginaActual) THEN DO:
    linLastY = mobPDF:cobMargenes:cinArriba.
    mobPDF:AgregarPagina().
    mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = linLastY.
  END.

  CAST(TT_pdf_tool.tool_obj,pdf.herramientas.HerramientaPDF):generar().
END. /* pdf_tool_create */


PROCEDURE pdf_load_template:
  DEFINE INPUT PARAMETER pdfStream        AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfTemplateID    AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfTemplateFile  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  CREATE TT_pdf_tool.
  ASSIGN TT_pdf_tool.obj_stream   = pdfStream
         TT_pdf_tool.tool_name    = pdfTemplateID
         TT_pdf_tool.tool_Type    = 'Template'
         TT_pdf_tool.tool_obj = NEW pdf.herramientas.Plantilla(mobPDF,pdfTemplateFile)
  .
END. /* pdf_load_template */

PROCEDURE pdf_use_template:
  DEFINE INPUT PARAMETER pdfStream        AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pdfTemplateID    AS CHARACTER NO-UNDO.

  DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE mobPlantilla AS pdf.herramientas.Plantilla NO-UNDO.
  mobPDF = pdf_internal_getPDF(pdfStream,FALSE).
  IF ERROR-STATUS:ERROR THEN RETURN ERROR.
  
  FIND TT_pdf_tool
       WHERE TT_pdf_tool.obj_stream = pdfStream
         AND TT_pdf_tool.tool_name  = pdfTemplateID NO-LOCK NO-ERROR.
  IF NOT AVAIL TT_pdf_Tool THEN DO:
    RUN pdf_error(pdfStream,"pdf_use_template","Cannot find Template ("
                                              + pdfTemplateID + "for Stream ("
                                              + pdfStream + "!").
    RETURN .
  END.
  mobPlantilla = CAST(TT_pdf_Tool.tool_obj,pdf.herramientas.Plantilla).
  mobPlantilla:generar().
END. /* pdf_use_template */


/* end of pdf_inc.p */
