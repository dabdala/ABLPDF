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

CLASS pdf.recursos.Diccionario INHERITS pdf.recursos.RecursoExistente:
  DEFINE PROTECTED PROPERTY cchFont AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cchXObject AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cchExtGState AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cchColorSpace AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cchShading AS CHARACTER NO-UNDO
    GET.
    SET.
    
  CONSTRUCTOR Diccionario(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDf AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.
    
  METHOD PUBLIC OVERRIDE VOID LoadFromStream(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    
    SUPER:LoadFromStream(ipinObjeto,ipinGeneracion,ipchNombre).
    IF VALID-OBJECT(cobDocumentoExistente:cobPaginaActual) THEN
      minPagina = cobDocumentoExistente:cobPaginaActual:cinNumero.
    cobDocumentoExistente:establecerTipoYPagina(THIS-OBJECT,ipinObjeto,ipinGeneracion,"~/Resource",minPagina).
    clcContenido = cobDocumentoExistente:objectContent(ipinObjeto,ipinGeneracion).
    IF INDEX(clcContenido,"~/Font") GT 0 THEN
      cchFont = cobDocumentoExistente:ProcessEntry(ipinObjeto,ipinGeneracion,"Font").
    IF INDEX(clcContenido,"~/XObject") GT 0 THEN
      cchXObject = cobDocumentoExistente:ProcessEntry(ipinObjeto,ipinGeneracion,"XObject").
    IF INDEX(clcContenido,"~/ExtGState") > 0 THEN
      cchExtGState = cobDocumentoExistente:ProcessEntry(ipinObjeto,ipinGeneracion,"ExtGState").
    IF INDEX(clcContenido,"~/ColorSpace") > 0 THEN
      cchColorSpace = cobDocumentoExistente:ProcessEntry(ipinObjeto,ipinGeneracion,"ColorSpace").
    IF INDEX(clcContenido,"~/Shading") > 0 THEN
      cchShading = cobDocumentoExistente:ProcessEntry(ipinObjeto,ipinGeneracion,"Shading").
  END METHOD.
  
  METHOD PUBLIC OVERRIDE LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('ResourceDictionary').
    RETURN TRUE.
  END METHOD.
  
  METHOD PROTECTED CHARACTER ReemplazarObjetos(INPUT ipchLista AS CHARACTER):
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DO minIndex = 1 TO NUM-ENTRIES(ipchLista,' ') BY 4:
      ENTRY(minIndex,ipchLista,' ') = '~/' + ENTRY(minIndex,ipchLista,' '). 
      ENTRY(minIndex + 1,ipchLista,' ') = STRING(cobDocumentoExistente:nuevoObjeto(INTEGER(ENTRY(minIndex + 1,ipchLista,' ')))).
      ENTRY(minIndex + 2,ipchLista,' ') = '0'.
    END.
    RETURN ipchLista.
  END METHOD.
  
  METHOD PROTECTED VOID ReemplazarContenido(INPUT ipchQue AS CHARACTER, INPUT ipchLista AS CHARACTER):
    DEFINE VARIABLE mchReemplazo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minDesde AS INTEGER NO-UNDO.
    DEFINE VARIABLE minCuanto AS INTEGER NO-UNDO.
    /* salteo el << inicial */
    IF SUBSTRING(ipchQue,1,1) NE '~/' THEN
      ipchQue = '~/' + ipchQue.
    minDesde = INDEX(clcContenido,ipchQue).
    mchReemplazo = SUBSTRING(clcContenido,minDesde + LENGTH(ipchQue)).
    minCuanto = LENGTH(mchReemplazo) - LENGTH(TRIM(mchReemplazo)).
    mchReemplazo = TRIM(mchReemplazo).
    IF SUBSTRING(mchReemplazo,1,1) EQ '~<' THEN
      mchReemplazo = SUBSTRING(mchReemplazo,1,INDEX(mchReemplazo,'~>') + 1).
    ELSE IF SUBSTRING(mchReemplazo,1,1) EQ '~[' THEN
      mchReemplazo = SUBSTRING(mchReemplazo,1,INDEX(mchReemplazo,'~]')).
    ELSE DO:
      mchReemplazo = ENTRY(1,mchReemplazo,'~/').
      IF SUBSTRING(mchReemplazo,LENGTH(mchReemplazo),1) EQ '~>' THEN
        SUBSTRING(mchReemplazo,LENGTH(mchReemplazo) - 1, 2) = ''.
    END.
    minCuanto = minCuanto + LENGTH(mchReemplazo) + LENGTH(ipchQue).
    SUBSTRING(clcContenido,minDesde,minCuanto) = ipchQue + ' <<' + ReemplazarObjetos(ipchLista) + '>>'.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarContenido():
    /* reemplazar todas las referencias a objetos, por los nuevos objetos */
    IF cchFont NE '' THEN
      ReemplazarContenido('Font',cchFont).
    IF cchXObject NE '' THEN
      ReemplazarContenido('XObject',cchXObject).
    IF cchExtGState NE '' THEN
      ReemplazarContenido('ExtGState',cchExtGState).
    IF cchColorSpace NE '' THEN
      ReemplazarContenido('ColorSpace',cchColorSpace).
    IF cchShading NE '' THEN
      ReemplazarContenido('Shading',cchShading).
    SUPER:generarContenido().
  END METHOD.
END CLASS.