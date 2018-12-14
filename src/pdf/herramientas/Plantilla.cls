 {pdf/pdf.i}
 /*------------------------------------------------------------------------
    File        : Plantilla
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Nov 12 08:06:27 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.herramientas.HerramientaPDF.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.herramientas.Plantilla INHERITS HerramientaPDF:
  DEFINE PROTECTED TEMP-TABLE cttElemento NO-UNDO
    FIELD inOrden AS INTEGER
    FIELD chQue AS CHARACTER /* [T]exto, [I]magen, [R]ectangulo, [L]ínea */
    FIELD inX AS INTEGER
    FIELD inXAncho AS INTEGER
    FIELD inY AS INTEGER
    FIELD inYAlto AS INTEGER
    FIELD deRFondo AS DECIMAL
    FIELD deVFondo AS DECIMAL
    FIELD deAFondo AS DECIMAL
    FIELD deRojo AS DECIMAL /* color de trazo/texto */
    FIELD deAzul AS DECIMAL
    FIELD deVerde AS DECIMAL
    FIELD chLetra AS CHARACTER
    FIELD dePuntos AS DECIMAL INITIAL ? /* tamaño letra o grosor gráfico */
    FIELD chContenido AS CHARACTER /* nombre de imagen,ruta o texto */
    INDEX ixElemento inOrden
  {&END}
    
    
  DEFINE PROTECTED PROPERTY cobColor AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cobLetra AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cobPunto AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cobHasta AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cobPreLetra AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobPreColor AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobPreFondo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobPreLinea AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobPrePosT AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobPrePosG AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
    
    
  METHOD PROTECTED VOID interpretarLinea(INPUT ipchDatos AS CHARACTER):
    cttElemento.inX = INTEGER(ENTRY(1,ipchDatos,'|')).
    cttElemento.inY = INTEGER(ENTRY(2,ipchDatos,'|')).
    cttElemento.inXAncho = INTEGER(ENTRY(3,ipchDatos,'|')).
    cttElemento.inYAlto = INTEGER(ENTRY(4,ipchDatos,'|')).
    cttElemento.deRojo = DECIMAL(ENTRY(5,ipchDatos,'|')).
    cttElemento.deVerde = DECIMAL(ENTRY(6,ipchDatos,'|')).
    cttElemento.deAzul = DECIMAL(ENTRY(7,ipchDatos,'|')).
    IF ENTRY(8,ipchDatos,'|') NE '' THEN
      cttElemento.dePuntos = DECIMAL(ENTRY(8,ipchDatos,'|')).
    ELSE
      cttElemento.dePuntos = 1.
  END METHOD.
  METHOD PROTECTED VOID interpretarRectangulo(INPUT ipchDatos AS CHARACTER):
    cttElemento.inX = INTEGER(ENTRY(1,ipchDatos,'|')).
    cttElemento.inY = INTEGER(ENTRY(2,ipchDatos,'|')).
    cttElemento.inXAncho = INTEGER(ENTRY(3,ipchDatos,'|')).
    cttElemento.inYAlto = INTEGER(ENTRY(4,ipchDatos,'|')).
    cttElemento.deRojo = DECIMAL(ENTRY(5,ipchDatos,'|')).
    cttElemento.deVerde = DECIMAL(ENTRY(6,ipchDatos,'|')).
    cttElemento.deAzul = DECIMAL(ENTRY(7,ipchDatos,'|')).
    cttElemento.deRFondo = DECIMAL(ENTRY(8,ipchDatos,'|')).
    cttElemento.deVFondo = DECIMAL(ENTRY(9,ipchDatos,'|')).
    cttElemento.deAFondo = DECIMAL(ENTRY(10,ipchDatos,'|')).
    IF ENTRY(11,ipchDatos,'|') NE '' THEN
      cttElemento.dePuntos = DECIMAL(ENTRY(11,ipchDatos,'|')).
    ELSE
      cttElemento.dePuntos = 1.
  END METHOD.
  METHOD PROTECTED VOID interpretarImagen(INPUT ipchDatos AS CHARACTER):
    DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
    IF SEARCH(ENTRY(2,ipchDatos,'|')) EQ ? THEN DO:
      DELETE cttElemento.
      RETURN.
    END.
    mobImagen = NEW pdf.imagenes.ImagenJPG(cobDocumento,ENTRY(1,ipchDatos,'|'),ENTRY(2,ipchDatos,'|')).
    cobDocumento:agregarImagen(mobImagen).
    cttElemento.chContenido = ENTRY(1,ipchDatos,'|').
    cttElemento.inX = INTEGER(ENTRY(3,ipchDatos,'|')).
    cttElemento.inY = INTEGER(ENTRY(4,ipchDatos,'|')).
    cttElemento.inXAncho = INTEGER(ENTRY(5,ipchDatos,'|')).
    cttElemento.inYAlto = INTEGER(ENTRY(6,ipchDatos,'|')).
  END METHOD.
  METHOD PROTECTED VOID interpretarTexto(INPUT ipchDatos AS CHARACTER):
    cttElemento.chContenido = ENTRY(1,ipchDatos,'|').
    cttElemento.chLetra = ENTRY(2,ipchDatos,'|').
    cttElemento.inX = INTEGER(ENTRY(3,ipchDatos,'|')).
    cttElemento.inY = INTEGER(ENTRY(4,ipchDatos,'|')).
    IF ENTRY(5,ipchDatos,'|') NE '' THEN
      cttElemento.dePuntos = DECIMAL(ENTRY(5,ipchDatos,'|')).
    cttElemento.deRojo = DECIMAL(ENTRY(6,ipchDatos,'|')).
    cttElemento.deVerde = DECIMAL(ENTRY(7,ipchDatos,'|')).
    cttElemento.deAzul = DECIMAL(ENTRY(8,ipchDatos,'|')).
  END METHOD.
  
  METHOD PROTECTED VOID leerArchivo(INPUT ipchArchivo AS CHARACTER):
    DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minOrden AS INTEGER NO-UNDO.
    
    EMPTY TEMP-TABLE cttElemento.
    INPUT FROM VALUE(ipchArchivo).
    REPEAT ON ENDKEY UNDO, LEAVE:
      IMPORT UNFORMATTED mchLinea.
      /* saltear comentarios */
      IF SUBSTRING(TRIM(mchLinea),1,1) EQ '#' THEN
        NEXT.
      IF TRIM(mchLinea) EQ '' THEN
        NEXT.
      CREATE cttElemento.
      ASSIGN
        minOrden = minOrden + 1
        cttElemento.inOrden = minOrden
        cttElemento.chQue = ENTRY(1,mchLinea,':')
        SUBSTRING(mchLinea,1,LENGTH(cttElemento.chQue) + 1)  = ''
        cttElemento.chQue = TRIM(cttElemento.chQue)
      {&END}
      CASE SUBSTRING(cttElemento.chQue,1,1):
        WHEN 'L' THEN
          interpretarLinea(mchLinea).
        WHEN 'R' THEN
          interpretarRectangulo(mchLinea).
        WHEN 'I' THEN
          interpretarImagen(mchLinea).
        OTHERWISE
          interpretarTexto(mchLinea).
      END.
    END.    
    FINALLY:
      INPUT CLOSE.
    END FINALLY.
  END METHOD.
     
  CONSTRUCTOR Plantilla(INPUT ipobDocumento AS pdf.Documento, INPUT ipchArchivo AS CHARACTER):
    SUPER(ipobDocumento).
    FILE-INFO:FILE-NAME = SEARCH(ipchArchivo).
    IF FILE-INFO:FULL-PATHNAME EQ ? THEN
      UNDO, THROW NEW pdf.excepciones.PDFException('No se encuentra el archivo de configuración de la plantilla').
    cobColor = NEW pdf.utiles.Color().
    cobLetra = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobPunto = NEW pdf.utiles.Punto().
    cobHasta = NEW pdf.utiles.Punto().
    leerArchivo(FILE-INFO:FULL-PATHNAME).
    cobPreLetra = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobPreColor = NEW pdf.utiles.Color().
    cobPreFondo = NEW pdf.utiles.Color().
    cobPreLinea = NEW pdf.utiles.Color().
    cobPrePosT = NEW pdf.utiles.Punto().
    cobPrePosG = NEW pdf.utiles.Punto().
  END CONSTRUCTOR.
  
  DESTRUCTOR PUBLIC Plantilla():
    DELETE OBJECT cobColor.
    DELETE OBJECT cobLetra.
    DELETE OBJECT cobPunto.
    DELETE OBJECT cobHasta.
    DELETE OBJECT cobPreLetra.
    DELETE OBJECT cobPreColor.
    DELETE OBJECT cobPreFondo.
    DELETE OBJECT cobPreLinea.
    DELETE OBJECT cobPrePosT.
    DELETE OBJECT cobPrePosG.
  END DESTRUCTOR. 
  
  METHOD PROTECTED VOID generarTexto():
    IF cttElemento.chLetra NE '' THEN
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cttElemento.chLetra.
    IF cttElemento.dePuntos NE ? THEN
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cttElemento.dePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(cttElemento.deRojo,cttElemento.deVerde,cttElemento.deAzul).
    
    cobPunto:cinX = cttElemento.inX.
    cobPunto:cinY = cttElemento.inY.
    cobDocumento:cobPaginaActual:TextoEn(cttElemento.chContenido,cobPunto).
  END METHOD.
  
  METHOD PROTECTED VOID generarLinea():
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:desdeRGB(cttElemento.deRojo,cttElemento.deVerde,cttElemento.deAzul).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:desdeRGB(cttElemento.deRFondo,cttElemento.deVFondo,cttElemento.deAFondo).
    
    cobPunto:cinX = cttElemento.inX.
    cobPunto:cinY = cttElemento.inY.
    cobHasta:cinX = cttElemento.inXAncho.
    cobHasta:cinY = cttElemento.inYAlto.
    cobDocumento:cobPaginaActual:Linea(cobPunto,cobHasta,cttElemento.dePuntos).
  END METHOD.
  
  METHOD PROTECTED VOID generarImagen():
    cobArea:cinX = cttElemento.inX.
    cobArea:cinY = cttElemento.inY.
    cobArea:cinAncho = cttElemento.inXAncho.
    cobArea:cinAlto = cttElemento.inYAlto.    
    cobDocumento:cobPaginaActual:InsertarImagen(cobDocumento:imagenRegistrada(ENTRY(1,cttElemento.chContenido)),cobArea).
  END METHOD.
  
  METHOD PROTECTED VOID generarRectangulo():
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:desdeRGB(cttElemento.deRojo,cttElemento.deVerde,cttElemento.deAzul).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:desdeRGB(cttElemento.deRFondo,cttElemento.deVFondo,cttElemento.deAFondo).
    cobArea:cinX = cttElemento.inX.
    cobArea:cinY = cttElemento.inY.
    cobArea:cinAncho = cttElemento.inXAncho.
    cobArea:cinAlto = cttElemento.inYAlto.        
    cobDocumento:cobPaginaActual:Rectangulo(cobArea,cttElemento.dePuntos).
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generar():    
    SUPER:generar().
    cobPreLetra:cchNombre = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre.
    cobPreLetra:cdePuntos = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos.
    cobPreColor:Copiar(cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor).
    cobPreFondo:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno).
    cobPreLinea:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel).
    cobPrePosT:Copiar(cobDocumento:cobPaginaActual:cobEstadoTExto:cobPosicion).
    cobPrePosG:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobPosicion).
    FOR EACH cttElemento BY cttElemento.inOrden:
      CASE SUBSTRING(cttElemento.chQue,1,1):
        WHEN 'L' THEN
          generarLinea().
        WHEN 'I' THEN
          generarImagen().
        WHEN 'R' THEN
          generarRectangulo().
        OTHERWISE
          generarTexto().
      END.
    END.
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobPreLetra:cchNombre.
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobPreLetra:cdePuntos.
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobPreColor).
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobPreFondo).
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:Copiar(cobPreLinea).
      cobDocumento:cobPaginaActual:cobEstadoTExto:cobPosicion:Copiar(cobPrePosT).
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobPosicion:Copiar(cobPrePosG).
    END FINALLY.
  END METHOD.
END CLASS.