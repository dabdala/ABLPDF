 
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

CLASS pdf.herramientas.Calendario INHERITS HerramientaPDF ABSTRACT:
  DEFINE PUBLIC EVENT inicioTitulo VOID (INPUT ipobCalendario AS pdf.herramientas.Calendario).
  
  DEFINE PUBLIC PROPERTY cobLetraTitulo AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorTitulo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorFondoTitulo AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cenAlineacionTitulo AS pdf.tipos.Alineacion NO-UNDO
    GET.
    PRIVATE SET.
  
  DEFINE PUBLIC PROPERTY cobLetraRotulos AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetraElemento AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobColorRotulos AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorFondoRotulos AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorElemento AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorFondoElemento AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cdaFecha AS DATE NO-UNDO INITIAL ?
    GET:
      IF cdaFecha EQ ? THEN
        RETURN TODAY.
      RETURN cdaFecha.
    END GET.
    SET.
    
  /*$
  brindan información del estado actual del calendario, útil al
  capturar las señales que se generan.
  $*/
  DEFINE PUBLIC PROPERTY cinMes AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinSemana AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinDiaSemana AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cinDia AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.  
  DEFINE PUBLIC PROPERTY cinHora AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cobCuadro AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  /*$
  título del calendardio, se permiten los comandos de reemplazo:
    %MM: nombre del mes de cdaFecha
    %M: número de mes de cdaFecha
    %YYYY: año, cada Y es un dígito, de cdaFecha
    %DD: día de cdaFecha, uno o dos dígitos (cada D es un dígito)
    %S: número de semana de cdaFecha, en el año
  $*/
  DEFINE PUBLIC PROPERTY cchTitulo AS CHARACTER NO-UNDO INITIAL '%MM de %Y'
    GET.
    SET. 
    
  DEFINE PUBLIC PROPERTY cinAltoCabecera AS INTEGER NO-UNDO INITIAL 20
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cinAltoRotulo AS INTEGER NO-UNDO INITIAL 10
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cchDias AS CHARACTER NO-UNDO INITIAL 'Lunes,Martes,Miércoles,Jueves,Viernes,Sábado,Domingo'
    GET.
    SET(INPUT ipchDias AS CHARACTER):
      DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
      DEFINE VARIABLE minTotal AS INTEGER NO-UNDO.
      minTotal = NUM-ENTRIES(ipchDias).
      IF minTotal GT 7 THEN
        minTotal = 7. 
      DO minIndex = 1 TO minTotal:
        ENTRY(minIndex,cchDias) = ENTRY(minIndex,ipchDias).
      END.
    END SET.
  DEFINE PUBLIC PROPERTY cchMeses AS CHARACTER NO-UNDO INITIAL 'Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Setiembre,Octubre,Noviembre,Diciembre'
    GET.
    SET(INPUT ipchMeses AS CHARACTER):
      DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
      DEFINE VARIABLE minTotal AS INTEGER NO-UNDO.
      minTotal = NUM-ENTRIES(ipchMeses).
      IF minTotal GT 12 THEN
        minTotal = 12. 
      DO minIndex = 1 TO minTotal:
        ENTRY(minIndex,cchMeses) = ENTRY(minIndex,ipchMeses).
      END.
    END SET.
   
  /*$
  cantidad de columnas a utilizar para dibujar el calendario
  para algunos tipos de calendario es un número fijo, para otros se toma en cuenta
  $*/
  DEFINE PUBLIC PROPERTY cinColumnas AS INTEGER NO-UNDO
    GET.
    SET.
  /*$
  cantidad de filas usadas para representar el calendario,
  depende del tipo de calendario
  $*/
  DEFINE PUBLIC PROPERTY cinFilas AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  /*$
  grosor de las líneas que forman la estructura del calendario
  $*/
  DEFINE PUBLIC PROPERTY cdeBorde AS DECIMAL NO-UNDO INITIAL 0.5
    GET.
    SET(INPUT ipdeBorde AS DECIMAL):
      IF ipdeBorde LT 0.1 THEN
        ipdeBorde = 0.1.
      IF ipdeBorde GT 80 THEN
        ipdeBorde = 80.
      cdeBorde = ipdeBorde.
    END SET.
    
  /*$
  color de la línea que forma la cuadrícula
  $*/
  DEFINE PUBLIC PROPERTY cobColorCuadricula AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
   
    
  CONSTRUCTOR PUBLIC Calendario(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
    cobLetraRotulos = NEW pdf.letras.TipoDeLetraDocumento(cobDocumento).
    cobLetraRotulos:cdePuntos = 12.
    cobLetraElemento = NEW pdf.letras.TipoDeLetraDocumento(cobDocumento).
    cobLetraElemento:cdePuntos = 10.
    cobLetraTitulo = NEW pdf.letras.TipoDeLetraDocumento(cobDocumento).
    cobLetraTitulo:cdePuntos = 14.
    cobColorFondoRotulos = NEW pdf.utiles.Color().
    cobColorFondoRotulos:desdeRGB(0.9,0.9,0.9).
    cobColorFondoTitulo = NEW pdf.utiles.Color().
    cobColorFondoTitulo:desdeRGB(0.5,0.5,0.5).
    cobColorRotulos = NEW pdf.utiles.Color().
    cobColorRotulos:desdeRGB(0,0,0).
    cobColorTitulo = NEW pdf.utiles.Color().
    cobColorTitulo:desdeRGB(0,0,0).
    cobColorFondoElemento = NEW pdf.utiles.Color().
    cobcolorFondoElemento:desdeRGB(1,1,1).
    cobColorElemento = NEW pdf.utiles.Color().
    cobColorElemento:desdeRGB(0,0,0).
    cobColorCuadricula = NEW pdf.utiles.Color().
    cobColorCuadricula:desdeRGB(0,0,0).
    cobCuadro = NEW pdf.utiles.Area().
    cenAlineacionTitulo = NEW pdf.tipos.Alineacion().
    cenAlineacionTitulo:cinValor = pdf.tipos.Alineacion:Izquierda.
  END CONSTRUCTOR.
  
  DESTRUCTOR PUBLIC Calendario():
    DELETE OBJECT cobCuadro.
    DELETE OBJECT cobLetraTitulo.
    DELETE OBJECT cobLetraRotulos.
    DELETE OBJECT cobLetraElemento.
    DELETE OBJECT cobColorFondoRotulos.
    DELETE OBJECT cobColorRotulos.
    DELETE OBJECT cobColorTitulo.
    DELETE OBJECT cobColorElemento.
    DELETE OBJECT cobColorFondoElemento.
    DELETE OBJECT cobColorCuadricula.
    DELETE OBJECT cobColorFondoTitulo.
    DELETE OBJECT cenAlineacionTitulo.
  END DESTRUCTOR.
  
  METHOD PROTECTED INTEGER calcularFilasMes(INPUT ipinMes AS INTEGER):
    DEFINE VARIABLE minMes AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDiaSemana AS INTEGER NO-UNDO.
    DEFINE VARIABLE minDias AS INTEGER NO-UNDO.

    DO minMes = ipinMes TO 12:
      IF minMes LT 1 THEN
        NEXT.        
      minDiaSemana = WEEKDAY(DATE(minMes,1,YEAR(cdaFecha))).
      /* en 5 filas acomodo hasta 31 días, salvo que el 1° empiece a partir del Jueves */
      IF minDiaSemana GE 5 THEN DO:
        /* dependo de la cantidad de días que tenga el mes */
        IF minMes EQ 12 THEN
          minDias = DAY(DATE(1,1,YEAR(cdaFecha) + 1) - 1).
        ELSE
          minDias = DAY(DATE(minMes + 1,1,YEAR(cdaFecha)) - 1).
        IF minDias - 28 GT 8 - minDiaSemana THEN
          /* en 4 líneas caben 28 días, en la primer línea caben 7 menos los que no uso */
          RETURN 6.
      END.
      IF ipinMes GT 0 THEN
        LEAVE.
    END.
    RETURN 5.
  END METHOD.
  
  METHOD PROTECTED CHARACTER obtenerTitulo():
    DEFINE VARIABLE mchTitulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchReemplazo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minInicio AS INTEGER NO-UNDO.
    DEFINE VARIABLE minFinal AS INTEGER NO-UNDO.
    DEFINE VARIABLE minSemana AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdaFecha AS DATE NO-UNDO.
    
    mchTitulo = cchTitulo.
    DO WHILE TRUE:
      minInicio = INDEX(mchTitulo,'%').
      IF minInicio EQ 0 THEN
        LEAVE.
      minFinal = INDEX(mchTitulo,' ',minInicio + 1).
      mchReemplazo = SUBSTRING(mchTitulo,minInicio + 1,minFinal - minInicio - 1).
      CASE SUBSTRING(mchReemplazo,1,1):
        WHEN 'M' THEN DO:
          IF mchReemplazo EQ 'MM' THEN
            mchReemplazo = ENTRY(MONTH(cdaFecha),cchMeses).
          ELSE
            mchReemplazo = STRING(MONTH(cdaFecha)). 
        END.
        WHEN 'Y' THEN
          mchReemplazo = SUBSTRING(STRING(YEAR(cdaFecha)),4 - LENGTH(mchReemplazo) + 1, LENGTH(mchReemplazo)).          
        WHEN 'D' THEN DO:
          IF mchReemplazo EQ 'DD' THEN DO:
            mchReemplazo = STRING(DAY(cdaFecha)).
            IF LENGTH(mchReemplazo) LT 2 THEN
              mchReemplazo = '0' + mchReemplazo.
          END.
          ELSE
            mchReemplazo = STRING(DAY(cdaFecha)).
        END.
        WHEN 'S' THEN DO:
          minSemana = 1.
          mdaFecha = cdaFecha - 7.
          DO WHILE YEAR(mdaFecha) EQ YEAR(cdaFecha):
            minSemana = minSemana + 1.
            mdaFecha = mdaFecha - 7.
          END.
          mchReemplazo = STRING(minSemana).
        END.
      END.
      SUBSTRING(mchTitulo,minInicio,minFinal - minInicio) = mchReemplazo. 
    END.
    RETURN mchTitulo.
  END METHOD.
  
  METHOD PROTECTED VOID calcularDimensiones():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    mobArea = NEW pdf.utiles.Area().
    determinarArea(mobArea).
    IF mobArea:cinAncho LE 0 THEN
      mobArea:cinAncho = cobDocumento:cobMargenes:cinDerecha - cobDocumento:cobMargenes:cinIzquierda.    
    IF mobArea:cinAlto LE 0 THEN
      mobArea:cinAlto = cobDocumento:cobMargenes:cinArriba - cobDocumento:cobMargenes:cinAbajo - cobDocumento:cinAltoCabeceraDePagina - cobDocumento:cinAltoPieDePagina.
    IF cinAltoCabecera LT 0 THEN
      cinAltoCabecera = 0.
    IF cinAltoCabecera GT mobArea:cinAlto THEN
      cinAltoCabecera = mobArea:cinAlto.
    IF cinAltoRotulo LT 0 THEN
      cinAltoRotulo = 0.
    FINALLY:
      DELETE OBJECT mobArea.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED VOID determinarAreaElementos(INPUT ipobArea AS pdf.utiles.Area):
    determinarArea(ipobArea).
    ipobArea:cinArriba = ipobArea:cinArriba - cinAltoCabecera.
  END METHOD.
  
  METHOD PROTECTED VOID CambioColorRotulo(INPUT ipobColor AS pdf.utiles.Color):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorRotulos).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoRotulos).
  END METHOD.
  METHOD PROTECTED VOID CambioLetraRotulo(INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraRotulos:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraRotulos:cdePuntos.    
  END METHOD.
  METHOD PROTECTED VOID CambioColorElemento(INPUT ipobColor AS pdf.utiles.Color):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorElemento).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoElemento).
  END METHOD.
  METHOD PROTECTED VOID CambioLetraElemento(INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento):
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraElemento:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraElemento:cdePuntos.    
  END METHOD.
  
  METHOD PROTECTED VOID generarCuadriculaTitulo(INPUT ipobArea AS pdf.utiles.Area):
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:Copiar(cobColorCuadricula).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoTitulo).
    ipobArea:cinAbajo = ipobArea:cinArriba - cinAltoCabecera.
    ipobArea:cinAlto = cinAltoCabecera.
    cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).
  END METHOD.
  METHOD PROTECTED ABSTRACT VOID generarCuadriculaRotulos(INPUT ipobArea AS pdf.utiles.Area).
  
  METHOD PROTECTED VOID generarCuadriculaElementos(INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE mobDesde AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE mobHasta AS pdf.utiles.Punto NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAA AS INTEGER NO-UNDO.
    
    mobDesde = NEW pdf.utiles.Punto().
    mobHasta = NEW pdf.utiles.Punto().
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoElemento).
    cobDocumento:cobPaginaActual:Rectangulo(ipobArea,cdeAnchoBordes).
    mobDesde:cinX = ipobArea:cinIzquierda.
    mobDesde:cinY = ipobArea:cinArriba.
    mobHasta:Copiar(mobDesde).
    /* columnas */
    mobHasta:cinY = ipobArea:cinAbajo.
    minAA = TRUNCATE(ipobArea:cinAncho / cinColumnas,0).
    DO minIndex = 1 TO cinColumnas - 1:
      mobDesde:cinX = ipobArea:cinIzquierda + minIndex * minAA.
      mobHasta:cinX = mobDesde:cinX.
      cobDocumento:cobPaginaActual:Linea(mobDesde,mobHasta,cdeAnchoBordes).
    END.
    /* filas */
    mobDesde:cinX = ipobArea:cinIzquierda.
    mobHasta:cinX = ipobArea:cinDerecha.
    minAA = TRUNCATE(ipobArea:cinAlto / cinFilas,0).
    DO minIndex = 1 TO cinFilas - 1:
      mobDesde:cinY = ipobArea:cinArriba - minIndex * minAA.
      mobHasta:cinY = mobDesde:cinY.
      cobDocumento:cobPaginaActual:Linea(mobDesde,mobHasta,cdeAnchoBordes).      
    END.
    FINALLY:
      DELETE OBJECT mobDesde.
      DELETE OBJECT mobHasta.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED VOID generarCuadricula():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    determinarArea(mobArea).
    generarCuadriculaTitulo(mobArea).
    generarCuadriculaRotulos(mobArea).
    determinarAreaElementos(mobArea).
    generarCuadriculaElementos(mobArea).
    
    FINALLY:
      DELETE OBJECT mobArea.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED ABSTRACT VOID generarRotulos().
  
  METHOD PROTECTED VOID generarTitulos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    mobPunto = NEW pdf.utiles.Punto().
    determinarArea(mobArea).
    /* me subscribo a los colores y letra, para detectar los cambios y realizarlos */
    cobColorRotulos:Cambio:Subscribe(CambioColorRotulo).
    cobColorFondoRotulos:Cambio:Subscribe(CambioColorRotulo).
    cobLetraRotulos:CambioLetra:Subscribe(CambioLetraRotulo).
    cobLetraRotulos:CambioPuntos:Subscribe(CambioLetraRotulo).
    /* titulo principal */
    inicioTitulo:publish(THIS-OBJECT).
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraTitulo:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraTitulo:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorTitulo).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoTitulo).
    cobCuadro:Copiar(mobArea).
    cobCuadro:cinAbajo = cobCuadro:cinArriba - cinAltoCabecera.
    mobPunto:cinY = cobCuadro:cinAbajo + (cobCuadro:cinAlto - cobLetraTitulo:cdePuntos) / 2.
    cinMes = 0.
    cinDiaSemana = 0.
    cinHora = 0.
    CASE cenAlineacionTitulo:cinValor:
      WHEN pdf.tipos.Alineacion:Centrado THEN DO:
        mobPunto:cinX = mobArea:cinIzquierda + mobArea:cinAncho / 2.
        cobDocumento:cobPaginaActual:TextoCentrado(obtenerTitulo(),mobPunto).
      END.
      WHEN pdf.tipos.Alineacion:Derecha THEN DO:
        mobPunto:cinX = cobCuadro:cinDerecha - cdeAnchoBordes.
        cobDocumento:cobPaginaActual:TextoAlineado(obtenerTitulo(),cenAlineacionTitulo,mobPunto).
      END.
      OTHERWISE DO:
        mobPunto:cinX = cobCuadro:cinIzquierda + cdeAnchoBordes.
        cobDocumento:cobPaginaActual:TextoAlineado(obtenerTitulo(),cenAlineacionTitulo,mobPunto).
      END.
    END.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = mobArea:cinAbajo.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraRotulos:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraRotulos:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorRotulos).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoRotulos).    
    generarRotulos().
    FINALLY:
      cobColorRotulos:Cambio:Unsubscribe(CambiocolorRotulo).
      cobColorFondoRotulos:Cambio:Unsubscribe(CambiocolorRotulo).
      cobLetraRotulos:CambioLetra:UnSubscribe(CambioLetraRotulo).
      cobLetraRotulos:CambioPuntos:UnSubscribe(CambioLetraRotulo).
      DELETE OBJECT mobArea.
      DELETE OBJECT mobPunto.
    END FINALLY.
  END METHOD.

  METHOD PROTECTED ABSTRACT VOID generarContenidoElementos(INPUT ipobArea AS pdf.utiles.Area).
  
  METHOD PROTECTED VOID generarElementos():
    DEFINE VARIABLE mobArea AS pdf.utiles.Area NO-UNDO.
    
    mobArea = NEW pdf.utiles.Area().
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = cobLetraElemento:cchNombre.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = cobLetraElemento:cdePuntos.
    cobDocumento:cobPaginaActual:cobEstadoTexto:cobColor:Copiar(cobColorElemento).
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorRelleno:Copiar(cobColorFondoElemento).
    /* me subscribo a los colores y letra, para detectar los cambios y realizarlos */
    cobColorElemento:Cambio:Subscribe(CambioColorElemento).
    cobColorFondoElemento:Cambio:Subscribe(CambioColorElemento).
    cobLetraElemento:CambioLetra:Subscribe(CambioLetraElemento).
    cobLetraElemento:CambioPuntos:Subscribe(CambioLetraElemento).
    /* contenido de cada elemento del calendrio,
    según el tipo de calendario, se genera algo, o simplemente se dispara
    la señal correspondiente */
    determinarAreaElementos(mobArea).
    generarContenidoElementos(mobArea).
    
    FINALLY:
      cobDocumento:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY = cobArea:cinAbajo.
      cobColorElemento:Cambio:UnSubscribe(CambioColorElemento).
      cobColorFondoElemento:Cambio:UnSubscribe(CambioColorElemento).
      cobLetraElemento:CambioLetra:UnSubscribe(CambioLetraElemento).
      cobLetraElemento:CambioPuntos:UnSubscribe(CambioLetraElemento).
      DELETE OBJECT mobArea.
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
    calcularDimensiones().
    cobDocumento:cobPaginaActual:cobEstadoGrafico:cobColorPincel:Copiar(mobColorLinea).    
    generarCuadricula().
    generarTitulos().
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