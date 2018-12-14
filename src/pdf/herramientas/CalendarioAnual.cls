 
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

CLASS pdf.herramientas.CalendarioAnual INHERITS pdf.herramientas.Calendario:
  DEFINE PUBLIC EVENT inicioRotulo VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  DEFINE PUBLIC EVENT inicioElemento VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  
  /*$
  cantidad de filas de cada cuadro
  $*/
  DEFINE PUBLIC PROPERTY cinFilasInternas AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  CONSTRUCTOR PUBLIC CalendarioAnual(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  METHOD PROTECTED OVERRIDE VOID calcularDimensiones():
    DEFINE VARIABLE minAnchoAux AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    mobArea = NEW pdf.utiles.Area().
    determinarArea(mobArea).
    IF mobArea:cinAncho LE 0 THEN
      mobArea:cinAncho = cobDocumento:cobMargenes:cinDerecha - cobDocumento:cobMargenes:cinIzquierda.    
    IF mobArea:cinAlto LE 0 THEN
      mobArea:cinAlto = cobDocumento:cobMargenes:cinArriba - cobDocumento:cobMargenes:cinAbajo - cobDocumento:cinAltoCabeceraDePagina - cobDocumento:cinAltoPieDePagina.
    SUPER:calcularDimensiones().
    IF cinColumnas LE 0 OR cinColumnas GT 12 THEN DO:
      cinColumnas = 12.
      DO WHILE cinColumnas GT 3:
        cinFilas = 12 MODULO cinColumnas + TRUNCATE(12 / cinColumnas,0).
        minAnchoAux = TRUNCATE((mobArea:cinAlto - cinFilas * cinAltoRotulo) / cinFilas,0).
        IF minAnchoAux GT TRUNCATE(mobArea:cinAncho / cinColumnas,0) THEN
          cinColumnas = cinColumnas - 1.
        ELSE
          LEAVE.
      END. 
    END.
    cinFilas = 12 MODULO cinColumnas + TRUNCATE(12 / cinColumnas,0).
    cinFilasInternas = calcularFilasMes(0).
    FINALLY:
      DELETE OBJECT mobArea.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarCuadriculaRotulos(INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAlto AS INTEGER NO-UNDO.
    /* en lugar de una fila de rótulos, hay cinFilas de rótulos */
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoRotulos).
    minAlto = ipobArea:cinAlto / cinFilas.
    DO minFila = 1 TO cinFilas:
      ipobArea:cinAbajo = ipobArea:cinArriba - cinAltoRotulo.
      cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).
      ipobArea:cinArriba = ipobArea:cinArriba + minAlto.                 
    END.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarRotulos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minColumna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFila AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAlto AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAnchoM AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDia AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    determinarArea(mobArea).
    minAncho = TRUNCATE(mobArea:cinAncho / cinColumnas,0).
    minAlto = TRUNCATE(mobArea:cinAlto / cinFilas,0).
    cinDiaSemana = 0.
    DO minFila = 1 TO cinFilas:
      cobCuadro:cinArriba = mobArea:cinArriba + minAlto * (minFila - 1).
      mobPunto:cinY = cobCuadro:cinArriba - cobLetraRotulos:cdePuntos.
      cobCuadro:cinAbajo = cobCuadro:cinArriba - cinAltoRotulo. 
      DO minColumna = 1 TO cinColumnas:
        cinMes = (minFila - 1) * minColumna + minColumna.
        IF cinMes GT 12 THEN
          LEAVE.            
        cobCuadro:cinIzquierda = mobArea:cinIzquierda + minAncho * (minColumna - 1).
        cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAncho.
        mobPunto:cinX = cobCuadro:cinIzquierda + minAncho / 2.
        inicioRotulo:Publish(THIS-OBJECT).
        cobDocumento:cobPaginaActual:TextoCentrado(ENTRY(cinMes,cchMeses),mobPunto).
      END.
      mobPunto:cinY = mobPunto:cinY + cobLetraRotulos:cdePuntos + 2.
      minAnchoM = TRUNCATE(minAncho / 7,0).
      /* días de la semana */
      DO minColumna = 1 TO cinColumnas:
        cinMes = (minFila - 1) * minColumna + minColumna.            
        IF cinMes GT 12 THEN
          LEAVE.            
        mobPunto:cinX = mobArea:cinIzquierda + minAncho * (minColumna - 1).
        DO minDia = 1 TO 7:
          cobCuadro:cinIzquierda = mobPunto:cinX + (minDia - 1) * minAnchoM .
          cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAnchoM.
          mobPunto:cinX = cobCuadro:cinIzquierda + minAnchoM / 2.
          cinDiaSemana = minDia.
          inicioRotulo:Publish(THIS-OBJECT).
          cobDocumento:cobPaginaActual:TextoCentrado(SUBSTRING(ENTRY(minDia,cchDias),1,2),mobPunto).
        END.
      END.
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
    minAlto = TRUNCATE((ipobArea:cinAlto - cinFilas * cinAltoRotulo) / cinFilasInternas,0).
    minAnchoInterno = TRUNCATE(minAncho / 7,0).
    minAltoInterno = TRUNCATE(minAlto / cinFilasInternas,0).
    DO minFila = 1 TO cinFilas:
      ipobArea:cinArriba = ipobArea:cinArriba - cinAltoRotulo. 
      DO minColumna = 1 TO cinColumnas:
        /* cada mes */
        cinMes = (minFila - 1) * minColumna + minColumna.
        IF cinMes GT 12 THEN
          LEAVE.
        mdaFecha = DATE(cinMes,1,YEAR(cdaFecha)).            
        DO minFilaInterna = 1 TO cinFilasInternas:
          cobCuadro:cinArriba = ipobArea:cinArriba - minAltoInterno * (minFilaInterna - 1).
          cobCuadro:cinAbajo = cobCuadro:cinArriba - minAltoInterno.
          /* cada semana */
          cinSemana = minFilaInterna.
          cinDia = 0.
          /* saltear los cuadros iniciales que corresponden al mes anterior */
          DO minColumnaInterna = 1 TO WEEKDAY(mdaFecha) - 1:
            cinDiaSemana = minColumnaInterna.
            cobCuadro:cinIzquierda = ipobArea:cinIzquierda + (minAncho * (minColumna - 1)) + (minAnchoInterno * (minColumnaInterna - 1)).
            cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAnchoInterno.
            inicioElemento:Publish(THIS-OBJECT).                                
          END. 
          DO minColumnaInterna = WEEKDAY(mdaFecha) TO 7:
            cinDiaSemana = minColumnaInterna.
            cinDia = DAY(mdaFecha).
            cobCuadro:cinIzquierda = ipobArea:cinIzquierda + (minAncho * (minColumna - 1)) + (minAnchoInterno * (minColumnaInterna - 1)).
            cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAnchoInterno.
            mobPunto:cinX = cobCuadro:cinIzquierda + minAncho / 2.
            mobPunto:cinY = cobCuadro:cinAbajo.
            inicioElemento:Publish(THIS-OBJECT).                                
            cobDocumento:cobPaginaActual:TextoCentrado(STRING(DAY(mdaFecha)),mobPunto).
            mdaFecha = mdaFecha + 1.
          END.
        END.
      END.
    END.
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobArea:cinAbajo.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.
  
END CLASS.