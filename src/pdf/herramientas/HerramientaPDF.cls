 
 /*------------------------------------------------------------------------
    File        : HerramientaPDF
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Nov 07 16:53:10 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.herramientas.HerramientaPDF ABSTRACT:
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET. 

  /*$
  dimensiones totales destinadas a la herramienta.
  cuando es 0, significa que no hay límite en esa dimensión.
  $*/
  DEFINE PUBLIC PROPERTY cobArea AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  determina si se dibujan líneas alrededor, y de qué grosor
  $*/
  DEFINE PUBLIC PROPERTY cdeAnchoBordes AS DECIMAL NO-UNDO INITIAL 1
    GET.
    SET.
    
  CONSTRUCTOR PUBLIC HerramientaPDF(INPUT ipobDocumento AS pdf.Documento):
    cobDocumento = ipobDocumento.
    cobArea = NEW pdf.utiles.Area().
    cobArea:Copiar(ipobDocumento:cobMargenes).
    cobArea:cinAbajo = cobArea:cinAbajo + ipobDocumento:cinAltoPieDePagina.     
    cobArea:cinArriba = ipobDocumento:cinAltoDePagina - cobArea:cinArriba - ipobDocumento:cinAltoCabeceraDePagina.
    cobArea:cinDerecha = ipobDocumento:cinAnchoDePagina - cobArea:cinDerecha.
  END CONSTRUCTOR.
  
  DESTRUCTOR PUBLIC HerramientaPDF():
    DELETE OBJECT cobArea.
  END DESTRUCTOR.
  
  METHOD PUBLIC VOID generar():
    IF cobDocumento:clgTerminado THEN
      UNDO, THROW NEW PDFException('No puede modificarse un documento PDF ya finalizado').
    IF NOT VALID-OBJECT(cobDocumento:cobPaginaActual) THEN
      cobDocumento:AgregarPagina().   
  END METHOD.

  METHOD PROTECTED VOID determinarArea(INPUT ipobArea AS pdf.utiles.Area):
    ipobArea:Copiar(cobArea).
    IF ipobArea:cinIzquierda LE 0 THEN
      ipobArea:cinIzquierda = cobDocumento:cobPaginaActual:cobMargenes:cinIzquierda.
    IF ipobArea:cinDerecha LE 0 THEN
      ipobArea:cinDerecha = cobDocumento:cobPaginaActual:cobMargenes:cinDerecha.
    IF ipobArea:cinArriba LE 0 THEN
      ipobArea:cinArriba = cobDocumento:cobPaginaActual:cobEstadoGrafico:cobPosicion:cinY.
    IF ipobArea:cinAbajo LE 0 THEN
      ipobArea:cinAbajo =  cobDocumento:cobPaginaActual:cobMargenes:cinAbajo + cobDocumento:cinAltoPieDePagina.
  END METHOD.    
END CLASS.