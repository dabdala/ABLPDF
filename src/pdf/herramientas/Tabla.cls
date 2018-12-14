 {pdf/pdf.i}
 /*------------------------------------------------------------------------
    File        : Tabla
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Nov 07 16:57:28 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.herramientas.HerramientaPDF.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.herramientas.Tabla INHERITS HerramientaPDF:
  /*$
  se dispara con cada título (columna) que se va a generar, antes de comenzar a generarlo
  $*/
  DEFINE PUBLIC EVENT inicioTitulo VOID (INPUT ipobTabla AS pdf.herramientas.Tabla).
  /*$
  se dispara con cada celda de datos que se va a generar, antes de comenzar a generarla
  $*/
  DEFINE PUBLIC EVENT inicioCelda VOID (INPUT ipobTabla AS pdf.herramientas.Tabla).
  /*$
  se dispara con cada total (columna) que se va a generar, antes de comenzar a generarlo
  $*/
  DEFINE PUBLIC EVENT inicioTotal VOID (INPUT ipobTabla AS pdf.herramientas.Tabla).
  
  DEFINE PROTECTED PROPERTY chnTabla AS HANDLE NO-UNDO
    GET.
    SET.
    
  /*$
  nombre del campo por el cual se quiere ordenar la tabla
  si no se especifica, se utiliza el orden "natural"
  $*/
  DEFINE PUBLIC PROPERTY cchOrdenTabla AS CHARACTER NO-UNDO
    GET.
    SET.
  
  DEFINE PUBLIC PROPERTY cobLetraTitulo AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobColorTitulo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobFondoTitulo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobLetraContenido AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobFondoContenido AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorContenido AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  lista de nombres de campos a mostrar de la tabla,
  las entradas vacías corresponden a campos que no se muestran.
  $*/    
  DEFINE PUBLIC PROPERTY cchTitulos AS CHARACTER NO-UNDO
    GET.
    SET.
    
  /*$
  lista de anchos de columna para cada campo a mostrar,
  las entradas vacías no se muestran.
  $*/
  DEFINE PUBLIC PROPERTY cchAnchoColumnas AS CHARACTER NO-UNDO
    GET.
    SET.
    
  /*$
  alineación de cada columna
  $*/
  DEFINE PUBLIC PROPERTY cchAlineacion AS CHARACTER NO-UNDO
    GET.
    SET.
    
  /*$
  separación entre columnas y entre filas.
  Mínimo 1 punto de cada lado (es decir 2 puntos).
  $*/
  DEFINE PUBLIC PROPERTY cobSeparacion AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  cantidad de filas que ocupa cada fila de la tabla,
  se determina en base a los anchos de columnas a mostrar, y el espacio
  total destinado a la tabla.
  $*/
  DEFINE PUBLIC PROPERTY cinCantidadDeFilasPorFila AS INTEGER NO-UNDO INITIAL 1
    GET.
    PROTECTED SET.
  /*$
  determina el espacio a la izquierda a dejar para cada fila, en relación
  a la fila anterior, cuando son parte de una misma fila de datos
  (cinCantidadDeFilasPorFila > 1)
  $*/
  DEFINE PUBLIC PROPERTY cinEspacioPrimeraColumnaInterna AS INTEGER NO-UNDO INITIAL 5
    GET.
    SET.
    
  /*$
  determina si la última fila de la tabla es una fila de datos, o de totales
  $*/ 
  DEFINE PUBLIC PROPERTY clgIncluirTotales AS LOGICAL NO-UNDO INITIAL FALSE
    GET.
    SET.
    
    
  CONSTRUCTOR PUBLIC Tabla(INPUT ipobDocumento AS pdf.Documento, INPUT iphtTabla AS HANDLE):
    SUPER(ipobDocumento).
    chnTabla = iphtTabla.
    cobLetraTitulo = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobLetraTitulo:cdePuntos = 12.
    cobLetraContenido = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobLetraContenido:cdePuntos = 9.
    cobColorTitulo = NEW pdf.utiles.Color().
    cobColorContenido = NEW pdf.utiles.Color().
    cobFondoTitulo = NEW pdf.utiles.Color().
    cobFondoTitulo:desdeRGB(0.5,0.5,0.5). /* gris */
    cobFondoContenido = NEW pdf.utiles.Color().
    cobFondoContenido:desdeRGB(1,1,1). /* blanco */
    cobSeparacion = NEW pdf.utiles.Punto().
    cobSeparacion:cinX = 1.
    cobSeparacion:cinY = 1.
    cdeAnchoBordes = 0.5.
  END CONSTRUCTOR.
  
  DESTRUCTOR PUBLIC Tabla():
    DELETE OBJECT cobSeparacion.
    DELETE OBJECT cobLetraTitulo.
    DELETE OBJECT cobLetraContenido.
    DELETE OBJECT cobFondotitulo.
    DELETE OBJECT cobFondoContenido.
    DELETE OBJECT cobColorTitulo.
    DELETE OBJECT cobColorContenido.
  END DESTRUCTOR. 
  
  METHOD PROTECTED VOID calcularDimensiones():
    DEFINE VARIABLE mhnBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAnchoAux AS INTEGER NO-UNDO.
    
    mhnBuffer = chnTabla:DEFAULT-BUFFER-HANDLE.
    IF cchTitulos EQ '' THEN DO:
      DO minIndex = 1 TO mhnBuffer:NUM-FIELDS:
        cchTitulos = cchTitulos + ',' + mhnBuffer:BUFFER-FIELD(minIndex):COLUMN-LABEL.
      END.
      SUBSTRING(cchTitulos,1,1) = ''.
    END.
    IF cchAnchoColumnas EQ '' THEN DO:
      DO minIndex = 1 TO NUM-ENTRIES(cchtitulos):
        ASSIGN
          mchCampo = ENTRY(minIndex,cchTitulos) 
          cchAnchoColumnas = cchAnchoColumnas + ','
        {&END}
        IF mchCampo EQ '' THEN
          NEXT.
        minAncho = cobLetraContenido:cobLetra:AnchoTexto(FILL('W',LENGTH(mhnBuffer:BUFFER-FIELD (minIndex):FORMAT)),cobLetraContenido:cdePuntos).
        minAnchoAux = cobLetraTitulo:cobLetra:AnchoTexto(mchCampo,cobLetraTitulo:cdePuntos).
        IF minAnchoAux GT minAncho THEN
          minAncho = minAnchoAux.
        cchAnchoColumnas = cchAnchoColumnas + STRING(minAncho).
      END.
    END.
    /* verificar los valores de separación */
    IF cobSeparacion:cinX GT cobDocumento:cinAnchoDePagina / 4 THEN
      cobSeparacion:cinX = cobDocumento:cinAnchoDePagina / 4.
    IF cobSeparacion:cinY GT cobDocumento:cinAltoDePagina / 4 THEN
      cobSeparacion:cinY = cobDocumento:cinAltoDePagina / 4.
    /* determinar la cantidad de filas necesarias para que quepan todas las columnas en el
    ancho definido para la tabla */
    minAnchoAux = cobArea:cinDerecha - cobArea:cinIzquierda.
    IF minAnchoAux EQ 0 THEN
      minAnchoAux = cobDocumento:cobMargenes:cinDerecha - cobDocumento:cobMargenes:cinIzquierda.
    minAncho = cdeAnchobordes.
    cinCantidadDeFilasPorFila = 1.
    DO minIndex = 1 TO NUM-ENTRIES(cchTitulos):
      minAncho = minAncho + cobSeparacion:cinX * 2 + cdeAnchoBordes + INTEGER(ENTRY(minIndex,cchAnchoColumnas)).
      IF minAncho GT minAnchoAux THEN ASSIGN
        minAncho = cinEspacioPrimeraColumnaInterna * cinCantidadDeFilasPorFila 
        cinCantidadDeFilasPorFila = cinCantidadDeFilasPorFila + 1
      {&END}
    END.
    DO minIndex = NUM-ENTRIES(cchAlineacion) TO NUM-ENTRIES(cchTitulos):
      IF minIndex LT 1 THEN
        NEXT.
      IF minIndex GT 1 THEN
        cchAlineacion = cchAlineacion + ','.
      CASE mhnBuffer:BUFFER-FIELD(minIndex):DATA-TYPE:
        WHEN 'INTEGER' OR WHEN 'DECIMAL' OR WHEN 'INT64' THEN
          cchAlineacion = cchAlineacion + 'D'.
        WHEN 'DATE' OR WHEN 'DATETIME' OR WHEN 'DATETIMETZ' THEN
          cchAlineacion = cchAlineacion + 'C'.
        OTHERWISE
          cchAlineacion = cchAlineacion + 'I'.
      END.
    END.
  END METHOD.
  
  METHOD PROTECTED VOID CambioColorTitulo(INPUT ipobColor AS pdf.utiles.Color):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorTitulo).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobFondoTitulo).
  END METHOD.
  METHOD PROTECTED VOID CambioColorDatos(INPUT ipobColor AS pdf.utiles.Color):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorContenido).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobFondoContenido).
  END METHOD.
  
  METHOD PROTECTED VOID generarTitulos():
    DEFINE VARIABLE minX AS INTEGER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minEmitido AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAltoFila AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraTitulo:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraTitulo:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorTitulo).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobFondoTitulo).
    IF cobArea:cinIzquierda GT 0 THEN
      minX = cobArea:cinIzquierda.
    ELSE
      minX = cobDocumento:cobPaginaActual:cobMargenes:cinIzquierda.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX = minX.
    /* me subscribo a los colores, para detectar los cambios de color y realizarlos */
    cobColorTitulo:Cambio:Subscribe(CambioColorTitulo).
    cobFondoTitulo:Cambio:Subscribe(CambioColorTitulo).
    mobArea:cinIzquierda = minX.
    minEmitido = 0.
    minFila = 1.
    minAltoFila = cobSeparacion:cinY * 2 + cdeAnchoBordes * 2 + cobLetraTitulo:cdePuntos.
    mobArea:cinArriba = cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY + cobLetraTitulo:cdePuntos.
    mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
    DO minIndex = 1 TO NUM-ENTRIES(cchTitulos):
      ASSIGN
        minAncho = 0
        mchCampo = ENTRY(minIndex,cchTitulos)
        minAncho = INTEGER(ENTRY(minIndex,cchAnchoColumnas)) NO-ERROR
      {&END}
      IF mchCampo EQ '' OR minAncho EQ 0 THEN
        NEXT.
      mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
      IF minEmitido GT 0 AND cobArea:cinDerecha GT 0 AND mobArea:cinDerecha GT cobArea:cinDerecha THEN DO:
        mobArea:cinIzquierda = minX + cinEspacioPrimeraColumnaInterna * minFila.
        mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
        mobArea:cinArriba = mobArea:cinAbajo. 
        mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
        IF cobArea:cinAbajo GT 0 AND mobArea:cinAbajo GT cobArea:cinAbajo THEN
          LEAVE.
        minEmitido = 0.
        minFila = minFila + 1.
      END. 
      inicioTitulo:Publish(THIS-OBJECT).
      cobDocumento:cobPaginaActual:Rectangulo(mobArea,cdeAnchoBordes).
      mobPunto:cinX = mobArea:cinIzquierda + (mobArea:cinDerecha - mobArea:cinIzquierda) / 2.
      mobPunto:cinY = mobArea:cinAbajo + cobSeparacion:cinY + cdeAnchoBordes.
      cobDocumento:cobPaginaActual:TextoCentrado(mchCampo,mobPunto).
      minEmitido = minEmitido + 1.
      mobArea:cinIzquierda = mobArea:cinDerecha.
    END.
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = mobArea:cinAbajo.
      cobColorTitulo:Cambio:Unsubscribe(CambiocolorTitulo).
      cobFondoTitulo:Cambio:Unsubscribe(CambiocolorTitulo).
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED CHARACTER cortarTexto(INPUT ipchTexto AS CHARACTER, INPUT ipinAncho AS INTEGER):
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minCantidad AS INTEGER NO-UNDO.
    minAncho = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto,cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos).
    DO WHILE minAncho GT ipinAncho:
      minCantidad = (LENGTH(ipchTexto) * (minAncho - ipinAncho)) / minAncho.
      IF minCantidad LT 1 THEN
        minCantidad = 1.  
      SUBSTRING(ipchTexto,LENGTH(ipchTexto) - minCantidad,minCantidad) = ''.
      minAncho = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto,cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos).
    END.
    RETURN ipchTexto.
  END METHOD.

  METHOD PROTECTED LOGICAL generarDatos(INPUT iphnQuery AS HANDLE):
    DEFINE VARIABLE minX AS INTEGER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minEmitido AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE mhnBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE menAlineacion AS pdf.tipos.Alineacion NO-UNDO.
    DEFINE VARIABLE minAltoFila AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    menAlineacion = NEW pdf.tipos.Alineacion().
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraContenido:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraContenido:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorContenido).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobFondoContenido).
    IF cobArea:cinIzquierda GT 0 THEN
      minX = cobArea:cinIzquierda.
    ELSE
      minX = cobDocumento:cobPaginaActual:cobMargenes:cinIzquierda.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX = minX.
    /* me subscribo a los colores, para detectar los cambios de color y realizarlos */
    cobColorContenido:Cambio:Subscribe(CambioColorDatos).
    cobFondoContenido:Cambio:Subscribe(CambioColorDatos).
    mobArea:cinAbajo = cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
    minAltoFila =  cobSeparacion:cinY * 2 + cdeAnchoBordes * 2 + cobLetraContenido:cdePuntos.
    mhnBuffer = chnTabla:DEFAULT-BUFFER-HANDLE.
    DATOS:
    DO WHILE iphnQuery:GET-NEXT():
      IF clgIncluirTotales THEN DO:
        IF NOT iphnQuery:GET-NEXT () THEN
          RETURN TRUE.
        iphnQuery:GET-PREV().
      END.
      mobArea:cinArriba = mobArea:cinAbajo.
      mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
      IF cobArea:cinAbajo GT 0 AND mobArea:cinAbajo LT cobArea:cinAbajo THEN
        RETURN TRUE.
      ELSE IF mobArea:cinAbajo LT cobDocumento:cobPaginaActual:cobMargenes:cinAbajo THEN
        RETURN FALSE.
      mobArea:cinIzquierda = minX.
      minEmitido = 0.
      minFila = 1.
      DO minIndex = 1 TO NUM-ENTRIES(cchAnchoColumnas):
        ASSIGN
          minAncho = 0
          minAncho = INTEGER(ENTRY(minIndex,cchAnchoColumnas)) NO-ERROR
        {&END}
        IF minAncho EQ 0 THEN
          NEXT.
        mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
        IF minEmitido GT 0 AND cobArea:cinDerecha GT 0 AND mobArea:cinDerecha GT cobArea:cinDerecha THEN DO:
          mobArea:cinIzquierda = minX + cinEspacioPrimeraColumnaInterna * minFila.
          mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
          mobArea:cinArriba = mobArea:cinAbajo. 
          mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
          IF cobArea:cinAbajo GT 0 AND mobArea:cinAbajo LT cobArea:cinAbajo THEN
            RETURN TRUE.
          ELSE IF mobArea:cinAbajo LT cobDocumento:cobPaginaActual:cobMargenes:cinAbajo THEN
            RETURN FALSE.
          minEmitido = 0.
          minFila = minFila + 1.
        END. 
        inicioCelda:Publish(THIS-OBJECT).
        cobDocumento:cobPaginaActual:Rectangulo(mobArea,cdeAnchoBordes).
        mchCampo = mhnBuffer:BUFFER-FIELD(minIndex):BUFFER-VALUE.
        IF mchCampo NE '' AND mchCampo NE ? THEN DO:
          mobPunto:cinX = mobArea:cinIzquierda + cobSeparacion:cinX + cdeAnchoBordes.
          mobPunto:cinY = mobArea:cinAbajo + cobSeparacion:cinY + cdeAnchoBordes.
          CASE SUBSTRING(ENTRY(minIndex,cchAlineacion),1,1):
            WHEN 'D' THEN DO:
              mobPunto:cinX = mobArea:cinDerecha - cobSeparacion:cinX - cdeAnchoBordes.
              menAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
            END.
            WHEN 'C' THEN DO:
              mobPunto:cinX = mobArea:cinIzquierda + mobArea:cinAncho / 2.              
              menAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
            END.
            OTHERWISE
              menAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
          END.
          cobDocumento:cobPaginaActual:TextoAlineado(cortarTexto(mchCampo,minAncho),menAlineacion,mobPunto).
        END.
        minEmitido = minEmitido + 1.
        mobArea:cinIzquierda = mobArea:cinDerecha.
      END.
    END.
    RETURN FALSE.
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = mobArea:cinAbajo.
      cobColorContenido:Cambio:Unsubscribe(CambiocolorDatos).
      cobFondoContenido:Cambio:Unsubscribe(CambiocolorDatos).
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
      DELETE OBJECT menAlineacion.
    END FINALLY.
  END METHOD.

  METHOD PROTECTED VOID generarTotales(INPUT iphnQuery AS HANDLE):
    DEFINE VARIABLE minX AS INTEGER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minEmitido AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE mhnBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE menAlineacion AS pdf.tipos.Alineacion NO-UNDO.
    DEFINE VARIABLE minAltoFila AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    menAlineacion = NEW pdf.tipos.Alineacion().
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraTitulo:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraTitulo:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorTitulo).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobFondoTitulo).
    IF cobArea:cinIzquierda GT 0 THEN
      minX = cobArea:cinIzquierda.
    ELSE
      minX = cobDocumento:cobPaginaActual:cobMargenes:cinIzquierda.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinX = minX.
    /* me subscribo a los colores, para detectar los cambios de color y realizarlos */
    cobColorTitulo:Cambio:Subscribe(CambioColorTitulo).
    cobFondoTitulo:Cambio:Subscribe(CambioColorTitulo).
    mobArea:cinArriba = cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
    minAltoFila = cobSeparacion:cinY * 2 + cdeAnchoBordes * 2 + cobLetraTitulo:cdePuntos.
    mobArea:cinAbajo = mobArea:cinArriba - minAltoFila. 
    mhnBuffer = chnTabla:DEFAULT-BUFFER-HANDLE.
    IF iphnQuery:GET-LAST() THEN DO:
      IF cobArea:cinAbajo GT 0 AND mobArea:cinAbajo LT cobArea:cinAbajo THEN
        RETURN.
      ELSE IF mobArea:cinAbajo LT cobDocumento:cobPaginaActual:cobMargenes:cinAbajo THEN DO:
        cobDocumento:AgregarPagina().
        generarTitulos().
        mobArea:cinArriba = cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
        mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
      END.
      mobArea:cinIzquierda = minX.
      minEmitido = 0.
      minFila = 1.
      DO minIndex = 1 TO NUM-ENTRIES(cchAnchoColumnas):
        ASSIGN
          minAncho = 0
          minAncho = INTEGER(ENTRY(minIndex,cchAnchoColumnas)) NO-ERROR
        {&END}
        IF minAncho EQ 0 THEN
          NEXT.
        mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
        IF minEmitido GT 0 AND cobArea:cinDerecha GT 0 AND mobArea:cinDerecha GT cobArea:cinDerecha THEN DO:
          mobArea:cinIzquierda = minX + cinEspacioPrimeraColumnaInterna * minFila.
          mobArea:cinDerecha = mobArea:cinIzquierda + cobSeparacion:cinX * 2 + minAncho + cdeAnchoBordes * 2.
          mobArea:cinArriba = mobArea:cinAbajo. 
          mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
          IF cobArea:cinAbajo GT 0 AND mobArea:cinAbajo LT cobArea:cinAbajo THEN
            RETURN.
          ELSE IF mobArea:cinAbajo LT cobDocumento:cobPaginaActual:cobMargenes:cinAbajo THEN DO:
            cobDocumento:AgregarPagina().
            generarTitulos().
            mobArea:cinArriba = cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY.
            mobArea:cinAbajo = mobArea:cinArriba - minAltoFila.
          END.
          minEmitido = 0.
          minFila = minFila + 1.
        END. 
        inicioTotal:Publish(THIS-OBJECT).
        cobDocumento:cobPaginaActual:Rectangulo(mobArea,cdeAnchoBordes).
        mchCampo = mhnBuffer:BUFFER-FIELD(minIndex):BUFFER-VALUE.
        IF mchCampo NE '' AND mchCampo NE ? THEN DO:
          mobPunto:cinX = mobArea:cinIzquierda + cobSeparacion:cinX + cdeAnchoBordes.
          mobPunto:cinY = mobArea:cinAbajo + cobSeparacion:cinY + cdeAnchoBordes.
          CASE SUBSTRING(ENTRY(minIndex,cchAlineacion),1,1):
            WHEN 'D' THEN DO:
              mobPunto:cinX = mobArea:cinDerecha - cobSeparacion:cinX - cdeAnchoBordes.
              menAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
            END.
            WHEN 'C' THEN DO:
              mobPunto:cinX = mobArea:cinIzquierda + mobArea:cinAncho / 2.              
              menAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
            END.
            OTHERWISE
              menAlineacion:cinValor = pdf.tipos.Alineacion:Izquierda.
          END.
          cobDocumento:cobPaginaActual:TextoAlineado(cortarTexto(mchCampo,minAncho),menAlineacion,mobPunto).
        END.
        minEmitido = minEmitido + 1.
        mobArea:cinIzquierda = mobArea:cinDerecha.
      END.
    END.
    FINALLY:
      cobColorTitulo:Cambio:Unsubscribe(CambiocolorTitulo).
      cobFondoTitulo:Cambio:Unsubscribe(CambiocolorTitulo).
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
      DELETE OBJECT menAlineacion.
    END FINALLY.
  END METHOD.


  METHOD PUBLIC OVERRIDE VOID generar():
    DEFINE VARIABLE mchLetraPrevia AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mdeTamPrevio AS DECIMAL NO-UNDO.
    DEFINE VARIABLE mobFondoPrevio AS pdf.utiles.Color NO-UNDO.
    DEFINE VARIABLE mobColorPrevio AS pdf.utiles.Color NO-UNDO.
    DEFINE VARIABLE mhnQuery AS HANDLE NO-UNDO.
    
    SUPER:generar().
    CREATE QUERY mhnQuery. 
    mobFondoPrevio = NEW pdf.utiles.Color().
    mobFondoPrevio:Copiar(cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno).
    mobColorPrevio = NEW pdf.utiles.Color().
    mobColorPrevio:Copiar(cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor).
    mchLetraPrevia = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre.
    mdeTamPrevio = cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos.
    
    calcularDimensiones().
    mhnQuery:ADD-BUFFER(chnTabla:DEFAULT-BUFFER-HANDLE).
    IF cchOrdenTabla NE '' THEN
      mhnQuery:QUERY-PREPARE('PRESELECT EACH ' + chnTabla:NAME + ' BY ' + cchOrdenTabla).
    ELSE
      mhnQuery:QUERY-PREPARE('PRESELECT EACH ' + chnTabla:NAME).
    mhnQuery:QUERY-OPEN().
    DO WHILE TRUE:
      generarTitulos().
      IF NOT generarDatos(mhnQuery) THEN
        LEAVE.
      IF cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY LE cobArea:cinAbajo THEN
        cobDocumento:AgregarPagina().
    END.
    IF clgIncluirTotales THEN
      generarTotales(mhnQuery).
    mhnQuery:QUERY-CLOSE().
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = mchLetraPrevia.
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = mdeTamPrevio.
      cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(mobFondoPrevio).
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(mobColorPrevio).
      DELETE OBJECT mobColorPrevio.
      DELETE OBJECT mobFondoPrevio.
      DELETE OBJECT mhnQuery.
    END FINALLY.
  END METHOD.
END CLASS.