 
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

CLASS pdf.herramientas.CalendarioMensual INHERITS pdf.herramientas.Calendario:
  DEFINE PUBLIC EVENT inicioRotulo VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  DEFINE PUBLIC EVENT inicioElemento VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  
  CONSTRUCTOR PUBLIC CalendarioMensual(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  METHOD PROTECTED OVERRIDE VOID calcularDimensiones():
    SUPER:calcularDimensiones().
    cinColumnas = 7.
    cinFilas = calcularFilasMes(MONTH(cdaFecha)).
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID determinarAreaElementos(INPUT ipobArea AS pdf.utiles.Area):
    SUPER:determinarAreaElementos(ipobArea).
    ipobArea:cinAlto = ipobArea:cinAlto - cinAltoRotulo.
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarCuadriculaRotulos(INPUT ipobArea AS pdf.utiles.Area):
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoRotulos).
    ipobArea:cinAbajo = ipobArea:cinAbajo - cinAltoRotulo.
    ipobArea:cinAlto = cinAltoRotulo.
    cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).      
  END METHOD.
  
  METHOD PROTECTED OVERRIDE VOID generarRotulos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minColumna AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAA AS INTEGER NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    determinarArea(mobArea).
    mobArea:cinArriba = mobArea:cinArriba - cinAltoCabecera.
    /* título de cada cuadro */
    cinMes = MONTH(cdaFecha).
    minAA = TRUNCATE(mobArea:cinAncho / cinColumnas,0).
    cobCuadro:cinArriba = mobArea:cinArriba.
    cobCuadro:cinAbajo = mobArea:cinArriba - cinAltoRotulo.
    mobPunto:cinY = cobCuadro:cinAbajo + (cinAltoRotulo - cobLetraRotulos:cdePuntos).
    IF mobPunto:cinY LT cobCuadro:cinAbajo THEN 
      mobPunto:cinY = cobCuadro:cinAbajo.
    DO minColumna = 1 TO cinColumnas:
      cobCuadro:cinIzquierda = mobArea:cinIzquierda + minAA * (minColumna - 1).
      cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAA.
      mobPunto:cinX = cobCuadro:cinIzquierda + minAA / 2.
      cinDiaSemana = minColumna.
      inicioRotulo:Publish(THIS-OBJECT).
      cobDocumento:cobPaginaActual:TextoCentrado(ENTRY(minColumna,cchDias),mobPunto).
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
    DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAlto AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdaFecha AS DATE NO-UNDO.
    
    mobPunto = NEW pdf.utiles.Punto().
    /* contenido de cada elemento del calendrio,
    según el tipo de calendario, se genera algo, o simplemente se dispara
    la señal correspondiente */
    cobCuadro:Copiar(ipobArea).
    minAncho = TRUNCATE(ipobArea:cinAncho / cinColumnas,0).
    minAlto = TRUNCATE(ipobArea:cinAlto  / cinFilas,0).
    cinMes = MONTH(cdaFecha).
    ipobArea:cinArriba = ipobArea:cinArriba. 
    mdaFecha = DATE(cinMes,1,YEAR(cdaFecha)).            
    DO minFila = 1 TO cinFilas:
      cobCuadro:cinArriba = ipobArea:cinArriba - minAlto * (minFila - 1).
      cobCuadro:cinAbajo = cobCuadro:cinArriba - minAlto.
      /* cada semana */
      cinSemana = minFila.
      cinDia = 0.
      /* saltear los cuadros iniciales que corresponden al mes anterior */
      DO minColumna = 1 TO WEEKDAY(mdaFecha) - 1:
        cinDiaSemana = minColumna.
        cobCuadro:cinIzquierda = ipobArea:cinIzquierda + (minAncho * (minColumna - 1)).
        cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAncho.
        inicioElemento:Publish(THIS-OBJECT).                                
      END. 
      DO minColumna = WEEKDAY(mdaFecha) TO 7:
        cinDiaSemana = minColumna.
        cinDia = DAY(mdaFecha).
        IF cinDia EQ 1 AND MONTH(mdaFecha) NE cinMes THEN
          LEAVE.
        cobCuadro:cinIzquierda = ipobArea:cinIzquierda + (minAncho * (minColumna - 1)).
        cobCuadro:cinDerecha = cobCuadro:cinIzquierda + minAncho.
        mobPunto:cinX = cobCuadro:cinIzquierda + cdeAnchoBordes.
        mobPunto:cinY = cobCuadro:cinArriba - cobLetraElemento:cdePuntos.
        inicioElemento:Publish(THIS-OBJECT).                                
        cobDocumento:cobPaginaActual:TextoEn(STRING(DAY(mdaFecha)),mobPunto).
        mdaFecha = mdaFecha + 1.            
      END.
    END.
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobArea:cinAbajo.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.  
END CLASS.