 
 /*------------------------------------------------------------------------
    File        : Calendario
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Nov 07 18:40:58 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.herramientas.HerramientaPDF.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.herramientas.CalendarioSemanal INHERITS pdf.herramientas.Calendario:
  DEFINE PUBLIC EVENT inicioRotulo VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  DEFINE PUBLIC EVENT inicioElemento VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  
  DEFINE PUBLIC PROPERTY cinMinutosElemento AS INTEGER NO-UNDO INITIAL 30
    GET.
    SET(INPUT ipinMinutos AS INTEGER):
      IF ipinMinutos LT 5 THEN
        ipinMinutos = 5.
      IF ipinMinutos GT (12 * 60) THEN
        ipinMinutos = 12 * 60.
      cinMinutosElemento = ipinMinutos.
    END SET.
    
  DEFINE PUBLIC PROPERTY cinPrimeraHoraMilitar AS INTEGER NO-UNDO INITIAL 600
    GET.
    SET(INPUT ipinHora AS INTEGER):
      IF ipinHora LT 0 THEN
        ipinHora = 0.
      IF ipinHora GT 2400 THEN
        ipinHora = 2400.
      cinPrimeraHoraMilitar = ipinHora.
    END SET.

  DEFINE PUBLIC PROPERTY cinUltimaHoraMilitar AS INTEGER NO-UNDO INITIAL 2200
    GET.
    SET(INPUT ipinHora AS INTEGER):
      IF ipinHora LT 0 THEN
        ipinHora = 0.
      IF ipinHora GT 2400 THEN
        ipinHora = 2400.
      cinUltimaHoraMilitar = ipinHora.
    END SET.
    
  CONSTRUCTOR PUBLIC CalendarioSemanal(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  METHOD PROTECTED OVERRIDE VOID calcularDimensiones():
    SUPER:calcularDimensiones().
    cinColumnas = 8. /* 7 días más los horarios */
    cinFilas = TRUNCATE((cinUltimaHoraMilitar - cinPrimeraHoraMilitar) / cinMinutosElemento,0) + (cinUltimaHoraMilitar - cinPrimeraHoraMilitar) MODULO cinMinutosElemento. 
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID determinarAreaElementos(INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    SUPER:determinarAreaElementos(ipobArea).
    ipobArea:cinAlto = ipobArea:cinAlto - cinAltoRotulo.
    minAncho = ipobArea:cinAncho / cinColumnas.
    ipobArea:cinIzquierda = ipobArea:cinIzquierda + minAncho.
    ipobArea:cinAncho = ipobArea:cinAncho - minAncho. 
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarCuadriculaRotulos(INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE minAA AS INTEGER NO-UNDO.
    
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoRotulos).
    minAA = ipobArea:cinAncho / cinColumnas.
    ipobArea:cinAbajo = ipobArea:cinAbajo - cinAltoRotulo.
    ipobArea:cinAlto = cinAltoRotulo.
    ipobArea:cinIzquierda = ipobArea:cinIzquierda + minAA.
    ipobArea:cinAncho = ipobArea:cinAncho - minAA.
    cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).
    determinarArea(ipobArea).
    ipobArea:cinAncho = minAA.
    minAA = (ipobArea:cinAlto - cinAltoRotulo) / cinFilas.
    ipobArea:cinAlto = minAA * cinFilas. 
    cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarRotulos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minColumna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAA AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDia AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdaFecha AS DATE NO-UNDO.
    DEFINE VARIABLE mchHora AS CHARACTER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    determinarArea(mobArea).
    minAA = TRUNCATE(mobArea:cinAncho / cinColumnas,0).
    cobCuadro:cinArriba = mobArea:cinArriba.
    cobCuadro:cinAbajo = cobCuadro:cinArriba - (cinAltoRotulo - cobLetraRotulos:cdePuntos).
    IF mobPunto:cinY LT cobCuadro:cinAbajo THEN 
      mobPunto:cinY = cobCuadro:cinAbajo.
    mdaFecha = cdaFecha.
    DO WHILE WEEKDAY(mdaFecha) GT 1:
      mdaFecha = mdaFecha - 1.
    END.
    cinMes = MONTH(cdaFecha).
    mobPunto:cinY = cobCuadro:cinAbajo.
    DO minColumna = 2 TO cinColumnas:
      cobCuadro:cinIzquierda = mobArea:cinIzquierda + minAA * (minColumna - 2).
      cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAA.
      mobPunto:cinX = cobCuadro:cinIzquierda + minAA / 2.
      cinDiaSemana = minColumna - 1.
      inicioRotulo:Publish(THIS-OBJECT).
      cobDocumento:cobPaginaActual:TextoCentrado(ENTRY(minColumna - 1,cchDias) + ' ' + STRING(DAY(mdaFecha)),mobPunto).
      mdaFecha = mdaFecha + 1.
    END.
    cobCuadro:cinIzquierda = mobArea:cinIzquierda.
    cobCuadro:cinDerecha = mobArea:cinIZquierda + minAA.
    mobPunto:cinX = mobArea:cinIzquierda + minAA / 2.
    minAA = TRUNCATE((mobArea:cinAlto - cinAltoRotulo) / cinFilas,0).
    minDia = cinPrimeraHoraMilitar.
    DO minFila = 1 TO cinFilas:
      cobCuadro:cinArriba =  mobArea:cinArriba - cinAltoRotulo - (minFila + 1) * minAA.
      cobCuadro:cinAbajo = cobCuadro:cinArriba - minAA.
      mobPunto:cinY = cobCuadro:cinAbajo.
      mchHora = STRING(minDia).
      IF LENGTH(mchHora) LT 4 THEN
        mchHora = FILL('0',4 - LENGTH(mchHora)) + mchHora.
      mchHora = SUBSTRING(mchHora,1,2) + ':' + SUBSTRING(mchHora,3,2).
      cinHora = minDia.
      inicioRotulo:Publish(THIS-OBJECT).
      cobDocumento:cobPaginaActual:TextoCentrado(mchHora,mobPunto).
      minDia = minDia + cinMinutosElemento.          
    END.
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = mobArea:cinAbajo.
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.

  METHOD PROTECTED OVERRIDE VOID generarContenidoElementos(INPUT ipobArea AS pdf.utiles.Area).
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minColumna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFilaInterna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minColumnaInterna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDia AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAlto AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAltoInterno AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAnchoInterno AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdaFecha AS DATE NO-UNDO.
    
    mobPunto = NEW pdf.utiles.Punto().
    /* contenido de cada elemento del calendrio,
    según el tipo de calendario, se genera algo, o simplemente se dispara
    la señal correspondiente */
    cobCuadro:Copiar(ipobArea).
    minAncho = TRUNCATE(ipobArea:cinAncho / cinColumnas,0).
    minAlto = TRUNCATE((ipobArea:cinAlto - cobLetraRotulos:cdePuntos) / cinFilas,0).
    cinMes = MONTH(cdaFecha).
    mdaFecha = DATE(cinMes,1,YEAR(cdaFecha)).
    /* determinar la semana a la que corresponde la fecha */
    cinSemana = 1.
    DO WHILE mdaFecha NE cdaFecha:
      mdaFecha = mdaFecha + 1.
      IF WEEKDAY(mdaFecha) EQ 1 THEN
        cinSemana = cinSemana + 1.
    END.
    mdaFecha = cdaFecha.
    DO WHILE WEEKDAY(mdaFecha) NE 1:
      mdaFecha = mdaFecha - 1.
    END.        
    ipobArea:cinArriba = ipobArea:cinArriba - cobLetraRotulos:cdePuntos.
    ipobArea:cinIzquierda = ipobArea:cinIzquierda + minAncho. 
    DO minColumna = 2 TO cinColumnas:
      cinDia = DAY(mdaFecha).
      cinDiaSemana = minColumna - 1.
      cobCuadro:cinIzquierda = ipobArea:cinIzquierda + (minAncho * (minColumna - 2)).
      cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAncho.
      DO minFila = 1 TO cinFilas:
        cobCuadro:cinArriba = ipobArea:cinArriba - minAlto * (minFila - 1).
        cobCuadro:cinAbajo = cobCuadro:cinArriba - minAlto.
        mobPunto:cinX = cobCuadro:cinIzquierda.
        mobPunto:cinY = cobCuadro:cinAbajo.
        cinHora = cinPrimeraHoraMilitar + (cinMinutosElemento * (minFila - 1)).
        inicioElemento:Publish(THIS-OBJECT).
      END.
      mdaFecha = mdaFecha + 1.
    END.
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobArea:cinAbajo.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.  
END CLASS.