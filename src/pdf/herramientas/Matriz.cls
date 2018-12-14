 
 /*------------------------------------------------------------------------
    File        : Matriz
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

CLASS pdf.herramientas.Matriz INHERITS HerramientaPDF: 
  /*$
  se dispara con cada celda que se va a generar, antes de comenzar a generarla
  $*/
  DEFINE PUBLIC EVENT inicioCelda VOID (INPUT ipobMatriz AS pdf.herramientas.Matriz).
  
  /*$
  cómo se alinea el contenido de cada celda.
  $*/
  DEFINE PUBLIC PROPERTY cenAlineacion AS pdf.tipos.Alineacion NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  tipo de letra del contenido de la matriz
  $*/
  DEFINE PUBLIC PROPERTY cobLetra AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColor AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorFondo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorBorde AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  grosor de las líneas
  $*/
  DEFINE PUBLIC PROPERTY cinAnchoBorde AS INTEGER NO-UNDO INITIAL 1
    GET.
    SET.
    
  /*$
  separación entre los bordes y el contenido (horizontal)
  $*/
  DEFINE PUBLIC PROPERTY cinSeparacionBorde AS INTEGER NO-UNDO INITIAL 0
    GET.
    SET.
    
  /*$
  valor a colocar en la celda actual
  $*/
  DEFINE PUBLIC PROPERTY cchValorCelda AS CHARACTER NO-UNDO
    GET.
    SET.
    
  /*$
  cantidad de filas de la matriz
  $*/
  DEFINE PUBLIC PROPERTY cinFilas AS INTEGER NO-UNDO INITIAL 2
    GET.
    SET.
    
  /*$
  cantidad de columnas de la matriz
  $*/
  DEFINE PUBLIC PROPERTY cinColumnas AS INTEGER NO-UNDO INITIAL 2
    GET.
    SET.
    
  /*$
  ancho de cada columna de la grilla
  $*/
  DEFINE PUBLIC PROPERTY cchAnchoColumna AS CHARACTER NO-UNDO
    GET.
    SET.

  /*$
  celda que se está generando actualmente
  $*/
  DEFINE PUBLIC PROPERTY cobCuadro AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cinFila AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinColumna AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  CONSTRUCTOR Matriz(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
    cobLetra = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobLetra:cdePuntos = 12.
    cobColor = NEW pdf.utiles.Color().
    cobColor:desdeRGB(0,0,0). /* negro */
    cobColorBorde = NEW pdf.utiles.Color().
    cobColorBorde:desdeRGB(0.5,0.5,0.5). /* gris */
    cobColorFondo = NEW pdf.utiles.Color().
    cobColorFondo:desdeRGB(1,1,1). /* blanco */
    cobCuadro = NEW pdf.utiles.Area().
    cenAlineacion = NEW pdf.tipos.Alineacion().
  END CONSTRUCTOR.
  
  DESTRUCTOR PUBLIC Matriz():
    DELETE OBJECT cobColor.
    DELETE OBJECT cobLetra.
    DELETE OBJECT cobColorFondo.
    DELETE OBJECT cobColorBorde.
    DELETE OBJECT cobCuadro.
    DELETE OBJECT cenAlineacion.
  END DESTRUCTOR. 
  
  METHOD PROTECTED VOID CambioColor(INPUT ipobColor AS pdf.utiles.Color):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColor).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondo).
  END METHOD.
  METHOD PROTECTED VOID CambioLetra(INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetra:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetra:cdePuntos.    
  END METHOD.
  
  METHOD PROTECTED VOID generarElementos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAlto AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAC AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetra:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetra:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColor).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondo).
    determinarArea(mobArea).
    /* me subscribo a los colores y letra, para detectar los cambios y realizarlos */
    cobColor:Cambio:Subscribe(CambioColor).
    cobColorFondo:Cambio:Subscribe(CambioColor).
    cobLetra:CambioLetra:Subscribe(CambioLetra).
    cobLetra:CambioPuntos:Subscribe(CambioLetra).
    cobCuadro:Copiar(mobArea).
    minAncho = TRUNCATE(mobArea:cinAncho / cinColumnas,0).    
    minAlto = TRUNCATE(mobArea:cinAlto / cinFilas,0).
    DO cinFila = 1 TO cinFilas:
      cobCuadro:cinArriba = mobArea:cinArriba - minAlto * (cinFila - 1).
      cobCuadro:cinAbajo = cobCuadro:cinArriba - minAlto.
      IF cchAnchoColumna NE '' THEN DO:
        minAncho = 0.
        DO cinColumna = 1 TO cinColumnas:
          cobCuadro:cinIzquierda = mobArea:cinIzquierda + minAncho.
          minAC = INTEGER(ENTRY(cinColumna,cchAnchoColumna)).
          IF minAC LE 0 THEN
            NEXT.
          minAncho = minAncho + minAC. 
          cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAC.
          cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobCuadro:cinArriba.
          inicioCelda:Publish(THIS-OBJECT).
          /* dibujar el rectángulo */
          cobDocumento:cobPaginaActual:Rectangulo(cobCuadro,cinAnchoBorde).          
          IF cchValorCelda NE '' THEN DO:
            CASE cenAlineacion:cinValor:
              WHEN pdf.tipos.Alineacion:Derecha THEN
                mobPunto:cinX = cobCuadro:cinDerecha - cinAnchoBorde - cinSeparacionBorde.
              WHEN pdf.tipos.Alineacion:Centrado THEN
                mobPunto:cinX = cobCuadro:cinIzquierda + minAC / 2 + cinAnchoBorde.
              OTHERWISE
                mobPunto:cinX = cobCuadro:cinIzquierda + cinAnchoBorde + cinSeparacionBorde.
            END.
            mobPunto:cinY = cobCuadro:cinAbajo + (cobCuadro:cinAlto - cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos) / 2 + cinAnchoBorde.
            cobDocumento:cobPaginaActual:TextoAlineado(cchValorCelda,cenAlineacion,mobPunto).
          END.
        END.
      END.
      ELSE DO cinColumna = 1 TO cinColumnas:
        cobCuadro:cinIzquierda = mobArea:cinIzquierda + (minAncho * (cinColumna - 1)).
        cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAncho.
        cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobCuadro:cinArriba.
        inicioCelda:Publish(THIS-OBJECT).
        /* dibujar el rectángulo */
        cobDocumento:cobPaginaActual:Rectangulo(cobCuadro,cinAnchoBorde).          
        IF cchValorCelda NE '' THEN DO:
          CASE cenAlineacion:cinValor:
            WHEN pdf.tipos.Alineacion:Derecha THEN
              mobPunto:cinX = cobCuadro:cinDerecha - cinAnchoBorde - cinSeparacionBorde.
            WHEN pdf.tipos.Alineacion:Centrado THEN
              mobPunto:cinX = cobCuadro:cinIzquierda + minAncho / 2 + cinAnchoBorde.
            OTHERWISE
              mobPunto:cinX = cobCuadro:cinIzquierda + cinAnchoBorde + cinSeparacionBorde.
          END.
          mobPunto:cinY = cobCuadro:cinAbajo + (cobCuadro:cinAlto - cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos) / 2 + cinAnchoBorde.
          cobDocumento:cobPaginaActual:TextoAlineado(cchValorCelda,cenAlineacion,mobPunto).
        END.
      END.
    END.
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = mobArea:cinAbajo.
      cobColor:Cambio:UnSubscribe(CambioColor).
      cobColorFondo:Cambio:UnSubscribe(CambioColor).
      cobLetra:CambioLetra:UnSubscribe(CambioLetra).
      cobLetra:CambioPuntos:UnSubscribe(CambioLetra).
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generar():
    DEFINE VARIABLE mchLetraPrevia AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mdeTamPrevio AS DECIMAL NO-UNDO.
    DEFINE VARIABLE mobFondoPrevio AS pdf.utiles.Color NO-UNDO.
    DEFINE VARIABLE mobColorPrevio AS pdf.utiles.Color NO-UNDO.
    DEFINE VARIABLE mobColorLinea AS pdf.utiles.Color NO-UNDO.
    
    mobFondoPrevio = NEW pdf.utiles.Color().
    mobFondoPrevio:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno).
    mobColorPrevio = NEW pdf.utiles.Color().
    mobColorPrevio:Copiar(cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor).
    mobColorLinea = NEW pdf.utiles.Color().
    mobColorLinea:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel).
    mchLetraPrevia = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre.
    mdeTamPrevio = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos.
    
    SUPER:generar().
    generarElementos().
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = mchLetraPrevia.
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = mdeTamPrevio.
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(mobFondoPrevio).
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(mobColorPrevio).
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:Copiar(mobColorLinea).
      DELETE OBJECT mobColorLinea.
      DELETE OBJECT mobColorPrevio.
      DELETE OBJECT mobFondoPrevio.
    END FINALLY.    
  END METHOD.
END CLASS.