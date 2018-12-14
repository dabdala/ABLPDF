 {pdf/pdf.i}
/*------------------------------------------------------------------------
   File        : Pagina
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : nomade
   Created     : Thu Aug 30 09:00:34 ART 2018
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

&GLOBAL-DEFINE BoldOnChar    CHR(1)
&GLOBAL-DEFINE BoldOffChar   CHR(2)
&GLOBAL-DEFINE ItalicOnChar  CHR(3)
&GLOBAL-DEFINE ItalicOffChar CHR(4)
&GLOBAL-DEFINE ColorOnChar   CHR(5)
&GLOBAL-DEFINE ColorOffChar  CHR(6)

CLASS pdf.Pagina IMPLEMENTS pdf.IObjetoPDF:
  DEFINE PUBLIC EVENT Cabecera VOID ().
  DEFINE PUBLIC EVENT Pie VOID ().
  
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET. 
  
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY clcContenido AS LONGCHAR NO-UNDO
    GET.
    PROTECTED SET.

  DEFINE PUBLIC PROPERTY clgPosicionHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgLetraHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgEstiloDeTextoHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgColorTextoHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgColorPincelHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgColorRellenoHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgUnionLineasHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgEscalaHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgRotacionHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgInclinacionHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgEspejadoHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY clgOrdenTransformacionesHaCambiado AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    PRIVATE SET.
    
  /*
  garantizo que el próximo bloque de texto, al comenzar, especifique la información
  necesaria respecto del estado del texto.
  */
  METHOD PROTECTED CHARACTER finBloqueTexto():
    clgLetraHaCambiado = TRUE.
    clgColorTextoHaCambiado = TRUE.
    clgPosicionHaCambiado = TRUE.    
    RETURN 'ET'.
  END METHOD.
  METHOD PROTECTED LOGICAL MasContenido(INPUT ipchMas AS CHARACTER):
    IF ipchMas EQ ? THEN
      RETURN FALSE.
    clcContenido = clcContenido + ipchMas.
    RETURN TRUE.
  END METHOD.
    
  DEFINE PUBLIC PROPERTY cinAncho AS INTEGER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cinAlto AS INTEGER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cobEstadoGrafico AS pdf.EstadoGrafico NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobEstadoTexto AS pdf.EstadoTexto NO-UNDO
    GET.
    PRIVATE SET.    
    
  DEFINE PUBLIC PROPERTY cinEspacioEntreLineas AS INTEGER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cdeEspacioVertical AS DECIMAL NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cdeEscalaEnX AS DECIMAL INITIAL 1 NO-UNDO
    GET.
    SET(INPUT ipdeNueva AS DECIMAL):
      IF ipdeNueva NE cdeEscalaEnX THEN /* no hago una asignación directa para no tener que hacer un OR */
        clgEscalaHaCambiado = TRUE.
      cdeEscalaEnX = ipdeNueva.
    END SET.
  DEFINE PUBLIC PROPERTY cdeEscalaEnY AS DECIMAL INITIAL 1 NO-UNDO
    GET.
    SET(INPUT ipdeNueva AS DECIMAL):
      IF ipdeNueva NE cdeEscalaEnY THEN /* no hago una asignación directa para no tener que hacer un OR */
        clgEscalaHaCambiado = TRUE.
      cdeEscalaEnY = ipdeNueva.
    END SET.
    
  DEFINE PUBLIC PROPERTY clgTerminada AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.
    
  /*$
  se utiliza para las operaciones que pueden generar un salto de página automático, por lo
  que su procesamiento puede no completarse en esta página, sino que debe "delegarse" a la
  nueva página actual del documento.
  $*/
  DEFINE PROTECTED PROPERTY clgCompletarEnNuevaPagina AS LOGICAL NO-UNDO
    GET.
    SET.
    
  DEFINE PROTECTED PROPERTY clgReposicionando AS LOGICAL NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY clgAgregandoTexto AS LOGICAL NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY clgAgregandoImagen AS LOGICAL NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY clgTieneTotalDePaginas AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clgTieneNumeroDePagina AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cinNumero AS INTEGER NO-UNDO /* número de página en el PDf */
    GET.
    SET.
    
  DEFINE PRIVATE VARIABLE cobADC AS pdf.utiles.Area NO-UNDO.
  DEFINE PUBLIC PROPERTY cobAreaDeCorte AS pdf.utiles.Area NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cobADC) THEN
        cobADC = NEW pdf.utiles.Area().
      RETURN cobADC.
    END GET.
    
  DEFINE PUBLIC PROPERTY cinRotacion AS INTEGER NO-UNDO
    GET.
    SET(INPUT ipinRotacion AS INTEGER):
      /* tienen que ser valores múltiplos de 90°, no importa qué se especifique
      se aplica el ángulo más próximo (inferior) múltiplo de 90° */
      DEFINE VARIABLE minCiclos AS INTEGER NO-UNDO.
      DO WHILE ipinRotacion GT 0 AND minCiclos LT 3:
        minCiclos = minCiclos + 1.
        ipinRotacion = ipinRotacion - 90.
      END. 
      IF ipinRotacion GT 0 THEN /* 360 y 0 son lo mismo */
        cinRotacion = 0.
      ELSE
        cinRotacion = minCiclos * 90.
    END SET.
    
  DEFINE PUBLIC PROPERTY cobMargenes AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cobUltimaPosicionActivaTexto AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cobUltimaPosicionActivaGraficos AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED TEMP-TABLE cttTransformaciones NO-UNDO
    FIELD inOrden AS INTEGER
    FIELD obTransformacion AS Progress.Lang.Object
    INDEX ixOrden inOrden
  {&END}
  
  METHOD PUBLIC VOID limpiarOrdenTransformaciones():
    FOR EACH cttTransformaciones:
      DELETE OBJECT cttTransformaciones.obTransformacion NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttTransformaciones.
    clgOrdenTransformacionesHaCambiado = TRUE.
  END METHOD.
  METHOD PUBLIC VOID agregarOrdenTransformacion(INPUT ipinTransformacion AS INTEGER):
    DEFINE VARIABLE minOrden AS INTEGER INITIAL 1 NO-UNDO.
    DEFINE VARIABLE mobTransformacion AS pdf.tipos.Transformacion NO-UNDO.
    FOR EACH cttTransformaciones BY cttTransformaciones.inOrden DESC:
      minOrden = cttTransformaciones.inOrden + 1.
      LEAVE.
    END.
    mobTransformacion = NEW pdf.tipos.Transformacion().
    mobTransformacion:cinValor = ipinTransformacion.
    CREATE cttTransformaciones.
    ASSIGN
      cttTransformaciones.inOrden = minOrden
      cttTransformaciones.obTransformacion = mobTransformacion
    {&END}
    clgOrdenTransformacionesHaCambiado = TRUE.
  END METHOD.
  
  DEFINE PROTECTED TEMP-TABLE cttColorPrevio NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD deRojo   AS DECIMAL
    FIELD deAzul   AS DECIMAL
    FIELD deVerde  AS DECIMAL
    FIELD chNombre AS CHARACTER
  {&END}
  METHOD PROTECTED VOID archivarColor(INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE minSiguiente AS INTEGER NO-UNDO.
    FOR EACH cttColorPrevio BY inNumero DESC:
      minSiguiente = inNumero.
      LEAVE.
    END.
    CREATE cttColorPrevio.
    ASSIGN
      cttColorPrevio.inNumero = minSiguiente + 1
      cttColorPrevio.deRojo   = cobEstadoTexto:cobColor:cdeRojo
      cttColorPrevio.deVerde  = cobEstadoTexto:cobColor:cdeVerde
      cttColorPrevio.deAzul   = cobEstadoTexto:cobColor:cdeAzul
      cttColorPrevio.chNombre = ipchNombre
    {&END}
  END METHOD.
    
  METHOD PROTECTED VOID desarchivarColor():
    FOR EACH cttColorPrevio BY cttColorPrevio.inNumero DESC:
      ASSIGN
        cobEstadoTexto:cobColor:cdeRojo  = cttColorPrevio.deRojo
        cobEstadoTexto:cobColor:cdeVerde = cttColorPrevio.deVerde
        cobEstadoTexto:cobColor:cdeAzul  = cttColorPrevio.deAzul
      {&END}
      DELETE cttColorPrevio.
      LEAVE.
    END.
  END METHOD.
  DEFINE PROTECTED PROPERTY cinColoresArchivados AS INTEGER NO-UNDO
    GET:
      FOR EACH cttColorPrevio BY cttColorPrevio.inNumero DESC:
        RETURN cttColorPrevio.inNumero.
      END.
      RETURN 0.
    END GET.

  /* manejo de campos de formularios */
  DEFINE PROTECTED TEMP-TABLE cttCampoFormulario NO-UNDO
    FIELD inNumero    AS INTEGER
    FIELD chNombre    AS CHARACTER
    FIELD obCampo      AS Progress.Lang.Object
  {&END}
  
  DEFINE PUBLIC PROPERTY cinCamposFormulario AS INTEGER NO-UNDO
    GET:
      DEFINE BUFFER mbfCF FOR cttCampoFormulario. 
      FOR EACH mbfCF BY mbfCF.inNumero DESC:
        RETURN mbfCF.inNumero.
      END.
      RETURN 0.
    END GET.
  
  METHOD PUBLIC VOID registrarCampoFormulario(INPUT ipobCampo AS pdf.recursos.CampoFormulario):
    FIND cttCampoFormulario WHERE cttCampoFormulario.chNombre EQ ipobCampo:cchNombre NO-ERROR.
    IF NOT AVAILABLE cttCampoFormulario THEN DO:
      CREATE cttCampoFormulario.
      ASSIGN
        cttCampoFormulario.inNumero = cinCamposFormulario + 1
        cttCampoFormulario.chNombre = ipobCampo:cchNombre
        cttCampoFormulario.obCampo = ipobCampo
      {&END}
    END.
  END METHOD.
  
  METHOD PUBLIC pdf.recursos.CampoFormulario campoFormulario(INPUT ipchNombre AS CHARACTER):
    FIND cttCampoFormulario WHERE cttCampoFormulario.chNombre EQ ipchNombre NO-ERROR.
    IF AVAILABLE cttCampoFormulario THEN
      RETURN CAST(cttCampoFormulario.obCampo,pdf.recursos.CampoFormulario).
    RETURN ?.
  END METHOD.
  METHOD PUBLIC pdf.recursos.CampoFormulario campoFormulario(INPUT ipinNumero AS INTEGER):
    FIND cttCampoFormulario WHERE cttCampoFormulario.inNumero EQ ipinNumero NO-ERROR.
    IF AVAILABLE cttCampoFormulario THEN
      RETURN CAST(cttCampoFormulario.obCampo,pdf.recursos.CampoFormulario).
    RETURN ?.
  END METHOD. 
    
  CONSTRUCTOR PUBLIC Pagina(INPUT ipobDocumento AS pdf.Documento):
    SUPER().
    cobEstadoGrafico = NEW pdf.EstadoGrafico(ipobDocumento).
    cobEstadoTexto = NEW pdf.EstadoTexto(ipobDocumento).
    cobDocumento = ipobDocumento.
    cinAncho = cobDocumento:cinAnchoDePagina.
    cinAlto = cobDocumento:cinAltoDePagina.
    cdeEscalaEnX = cobDocumento:cdeEscalaEnX.
    cdeEscalaEnY = cobDocumento:cdeEscalaEnY.
    cobMargenes = NEW pdf.utiles.Area().
    cobMargenes:Copiar(cobDocumento:cobMargenes).
    cobMargenes:cinAbajo = cobMargenes:cinAbajo + cobDocumento:cinAltoPieDePagina.
    cobMargenes:cinArriba = cobMargenes:cinArriba + cobDocumento:cinAltoCabeceraDePagina.
    /* EVENTOS */
    cobEstadoTexto:Rotacion:Subscribe(CambioRotacion).
    cobEstadoTexto:Inclinacion:Subscribe(CambioInclinacion).
    cobEstadoTexto:Espejado:Subscribe(CambioEspejado).
    cobEstadoTexto:CambioDeLetra:Subscribe(CambioDeLetra).
    cobEstadoTexto:CambioDeColor:Subscribe(CambioDeColorTexto).
    cobEstadoTexto:CambioDePosicion:Subscribe(CambioDePosicion).
    cobEstadoTexto:cenEstiloTexto:Cambio:Subscribe(CambioEstiloDeTexto).
    cobEstadoGrafico:cenUnionLineas:Cambio:Subscribe(CambioUnionLineas).
    cobEstadoGrafico:CambioDeColorPincel:Subscribe(CambioDeColorPincel).
    cobEstadoGrafico:CambioDeColorRelleno:Subscribe(CambioDeColorRelleno).
    cobEstadoTexto:cobPosicion:CambioEnY:Subscribe(CambioEnY).
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC Pagina(INPUT ipobDocumento AS pdf.Documento,INPUT ipobPagina AS pdf.Pagina):
    SUPER().
    cobEstadoGrafico = NEW pdf.EstadoGrafico(ipobDocumento).
    cobEstadoTexto = NEW pdf.EstadoTexto(ipobDocumento).
    cobDocumento = ipobDocumento.
    cinAncho = ipobPagina:cinAncho.
    cinAlto = ipobPagina:cinAlto.
    cdeEscalaEnX = ipobPagina:cdeEscalaEnX.
    cdeEscalaEnY = ipobPagina:cdeEscalaEnY.
    cdeEspacioVertical = ipobPagina:cdeEspacioVertical.
    cobMargenes = NEW pdf.utiles.Area().
    cobMargenes:Copiar(ipobPagina:cobMargenes).
    cobEstadoTexto:Copiar(ipobPagina:cobEstadoTexto).
    cobEstadoGrafico:Copiar(ipobPagina:cobEstadoGrafico).
    /* EVENTOS */
    cobEstadoTexto:Rotacion:Subscribe(CambioRotacion).
    cobEstadoTexto:Inclinacion:Subscribe(CambioInclinacion).
    cobEstadoTexto:Espejado:Subscribe(CambioEspejado).
    cobEstadoTexto:CambioDeLetra:Subscribe(CambioDeLetra).
    cobEstadoTexto:CambioDeColor:Subscribe(CambioDeColorTexto).
    cobEstadoTexto:CambioDePosicion:Subscribe(CambioDePosicion).
    cobEstadoTexto:cenEstiloTexto:Cambio:Subscribe(CambioEstiloDeTexto).
    cobEstadoGrafico:cenUnionLineas:Cambio:Subscribe(CambioUnionLineas).
    cobEstadoGrafico:CambioDeColorPincel:Subscribe(CambioDeColorPincel).
    cobEstadoGrafico:CambioDeColorRelleno:Subscribe(CambioDeColorRelleno).
    cobEstadoTexto:cobPosicion:CambioEnY:Subscribe(CambioEnY).
  END CONSTRUCTOR.
  
  DESTRUCTOR Pagina():
    DELETE OBJECT cobMargenes NO-ERROR.
    DELETE OBJECT cobEstadoTexto NO-ERROR.
    DELETE OBJECT cobEstadoGrafico NO-ERROR.
    DELETE OBJECT cobADC NO-ERROR.
    FOR EACH cttCampoFormulario:
      DELETE OBJECT cttCampoFormulario.obCampo NO-ERROR.
    END.
    DELETE OBJECT cobUltimaPosicionActivaGraficos NO-ERROR.
    DELETE OBJECT cobUltimaPosicionActivaTexto NO-ERROR.
  END DESTRUCTOR.
  
  METHOD PUBLIC VOID Iniciar():
    cobEstadoTexto:cobPosicion:cinY = cinAlto - cobMargenes:cinArriba + cobDocumento:cinAltoCabeceraDePagina.
    cobEstadoTexto:cobPosicion:cinX = cobMargenes:cinIzquierda.
    cobEstadoGrafico:cobPosicion:Copiar(cobEstadoTexto:cobPosicion).
    AgregarElemento("TEXT","","","").
    Cabecera:Publish().
    cobEstadoTexto:cobPosicion:cinY = cinAlto - cobMargenes:cinArriba.
  END METHOD.
  
  METHOD PUBLIC VOID Finalizar():
    IF NOT clgTerminada THEN DO:
      cobUltimaPosicionActivaGraficos = NEW pdf.utiles.Punto().
      cobUltimaPosicionActivaTexto = NEW pdf.utiles.Punto().
    END.    
    cobUltimaPosicionActivaTexto:Copiar(cobEstadoTExto:cobPosicion).
    cobUltimaPosicionActivaGraficos:Copiar(cobEstadoGrafico:cobPosicion).
    IF clgTerminada THEN
      RETURN.
    clgTerminada = TRUE.
    cobEstadoTexto:cobPosicion:cinY = cobMargenes:cinAbajo. /* ya se le sumó el alto del pie */
    cobEstadoTexto:cobPosicion:cinX = cobMargenes:cinIzquierda.
    cobEstadoGrafico:cobPosicion:Copiar(cobEstadoTexto:cobPosicion).
    AgregarElemento("TEXT","","","").
    
    Pie:Publish().
    
    FINALLY:
      IF clgAgregandoTexto THEN
        AgregarElemento("TEXTEND","ET","","").
      ELSE IF clgAgregandoImagen THEN
          AgregarElemento("GRAPHICEND","Q","","").
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC VOID reactivar():
    clgReposicionando = TRUE.    
    cobEstadoTexto:cobPosicion:Copiar(cobUltimaPosicionActivaTexto).
    cobEstadoGrafico:cobPosicion:Copiar(cobUltimaPosicionActivaGraficos).
    FINALLY:
      clgReposicionando = FALSE.
    END FINALLY.
  END METHOD.

  METHOD PUBLIC VOID usarXObject(INPUT ipchNombre AS CHARACTER):
    AgregarElemento("IMAGE-EXT","~/" + ipchNombre + " Do","","").    
  END METHOD.  
  METHOD PUBLIC VOID copiarCampos(INPUT ipobPagina AS pdf.Pagina):
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobCampo AS pdf.recursos.CampoFormulario NO-UNDO.
    DO minIndex = 1 TO ipobPagina:cinCamposFormulario:
      mobCampo = NEW pdf.recursos.CampoFormulario(ipobPagina:campoFormulario(minIndex)).
      registrarCampoFormulario(mobCampo).
    END.
  END METHOD.
  METHOD PUBLIC VOID usarPaginaExterna(INPUT ipobPagina AS pdf.PaginaExistente):
    usarXObject(ipobPagina:cchNombreXObject).
    copiarCampos(ipobPagina).
  END METHOD.
  METHOD PUBLIC VOID copiarContenido(INPUT ipobPagina AS pdf.Pagina):
    clcContenido = ipobPagina:clcContenido.
    clgTieneTotalDePaginas = INDEX(clcContenido,cobDocumento:cchMarcaTotalPaginas) GT 0.
    clgTieneNumeroDePagina = INDEX(clcContenido,cobDocumento:cchMarcaNumeroDePagina) GT 0.
  END METHOD.
  
  METHOD PUBLIC INTEGER copiarEnlaces(INPUT ipobPagina AS pdf.Pagina):
    DEFINE VARIABLE minCopiados AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobEnlace AS pdf.enlaces.Enlace NO-UNDO.
    DEFINE VARIABLE mobNuevo AS pdf.enlaces.Enlace NO-UNDO.
    DEFINE VARIABLE minPP AS INTEGER NO-UNDO.
    minPP = cobDocumento:cinPaginaActual.
    cobDocumento:cinPaginaActual = cinNumero.
    mobEnlace = ipobPagina:cobDocumento:siguienteEnlace(?,ipobPagina).
    DO WHILE VALID-OBJECT(mobEnlace):
      mobNuevo = DYNAMIC-NEW(mobEnlace:GetClass():TypeName)(cobDocumento).
      mobNuevo:Copiar(mobEnlace).
      mobEnlace = mobEnlace:siguiente().
      minPP = minPP + 1.
    END.
    RETURN minPP.
    FINALLY:
      cobDocumento:cinPaginaActual = minPP.
    END FINALLY.
  END.
  
  METHOD PROTECTED VOID multiplicarTM(INPUT ipdeP AS DECIMAL EXTENT 6, INPUT ipdeS AS DECIMAL EXTENT 6, OUTPUT opdeR AS DECIMAL EXTENT 6 ):
    /*
    a = a' x a'' + b' x c''
    b = a' x b'' + b' x d''
    c = c' x a'' + d' x c''
    d = c' x b'' + d' x d''
    e = e' x a'' + f' x c'' + e''
    f = e' x b'' + f' x d'' + f''
    */
    opdeR[1] = ipdeP[1] * ipdeS[1] + ipdeP[2] * ipdeS[3].
    opdeR[2] = ipdeP[1] * ipdeS[2] + ipdeP[2] * ipdeS[4].
    opdeR[3] = ipdeP[3] * ipdeS[1] + ipdeP[4] * ipdeS[3].
    opdeR[4] = ipdeP[3] * ipdeS[2] + ipdeP[4] * ipdeS[4].
    opdeR[5] = ipdeP[5] * ipdeS[1] + ipdeP[6] * ipdeS[3] + ipdeS[5].
    opdeR[6] = ipdeP[5] * ipdeS[2] + ipdeP[6] * ipdeS[4] + ipdeS[6].
  END METHOD.
  
  METHOD PROTECTED CHARACTER PDFTransformMatrix(INPUT ipinX AS INTEGER,INPUT ipinY AS INTEGER, INPUT iplgForzar AS LOGICAL):
    DEFINE VARIABLE mchResultado AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mdeP AS DECIMAL EXTENT 6 NO-UNDO.
    DEFINE VARIABLE mdeS AS DECIMAL EXTENT 6 NO-UNDO.
    DEFINE VARIABLE mlgPrevia AS LOGICAL NO-UNDO.
    
    IF NOT iplgForzar AND NOT clgRotacionHaCambiado AND NOT clgEscalaHaCambiado AND NOT clgInclinacionHaCambiado
        AND NOT clgEspejadoHaCambiado AND NOT clgOrdenTransformacionesHaCambiado AND NOT clgPosicionHaCambiado
        AND ipinX EQ cobEstadoTexto:cobPosicion:cinX AND ipinY EQ cobEstadoTexto:cobPosicion:cinY THEN
      RETURN ''.
    clgRotacionHaCambiado = FALSE.
    clgEscalaHaCambiado = FALSE.
    clgInclinacionHaCambiado = FALSE.
    clgEspejadoHaCambiado = FALSE.
    clgOrdenTransformacionesHaCambiado = FALSE.
    clgPosicionHaCambiado = FALSE.
    /*
    si realizo varias transformaciones, tengo que multiplicarlas entre si.
    a = a' x a'' + b' x c''
    b = a' x b'' + b' x d''
    c = c' x a'' + d' x c''
    d = c' x b'' + d' x d''
    e = e' x a'' + f' x c'' + e''
    f = e' x b'' + f' x d'' + f''
    
    Sin no hay un orden especificado, entonces:
       1 - escalar
       2 - inclinar
       3 - espejar
       4 - rotar
       5 - trasladar
    */
    FIND cttTransformaciones WHERE cttTransformaciones.inOrden EQ 1 NO-ERROR.
    IF AVAILABLE cttTransformaciones THEN DO:
      mdeP[1] = 1.
      mdeP[4] = 1.      
      FOR EACH cttTransformaciones BY cttTransformaciones.inOrden:
        ASSIGN
          mdeS[1] = 1
          mdeS[2] = 0
          mdeS[3] = 0
          mdeS[4] = 1
          mdeS[5] = 0
          mdeS[6] = 0
        {&END}
        CASE CAST(cttTransformaciones.obTransformacion,pdf.tipos.Transformacion):cinValor:
          WHEN pdf.tipos.Transformacion:Escalar THEN ASSIGN
            mdeS[1] = cdeEscalaEnX
            mdeS[4] = cdeEscalaEnY
          {&END}
          WHEN pdf.tipos.Transformacion:EscalarEnX THEN
            mdeS[1] = cdeEscalaEnX.
          WHEN pdf.tipos.Transformacion:EscalarEnY THEN
            mdeS[4] = cdeEscalaEnY.
          WHEN pdf.tipos.Transformacion:Espejar THEN DO:
            IF cobEstadoTExto:clgEspejarEnX THEN
              mdeS[1] = -1.
            IF cobEstadoTexto:clgEspejarEnY THEN
              mdeS[4] = -1.
          END.
          WHEN pdf.tipos.Transformacion:EspejarEnX THEN DO:
            IF cobEstadoTexto:clgEspejarEnX THEN
              mdeS[1] = -1.
          END.
          WHEN pdf.tipos.Transformacion:EspejarEnY THEN DO:
            IF cobEstadoTexto:clgEspejarenY THEN
              mdeS[4] = -1.
          END.
          WHEN pdf.tipos.Transformacion:Inclinar THEN DO:
            IF cobEstadoTExto:cinAnguloLetra NE 0 THEN DO: 
              mdeS[3] = pdf.utiles.Trigonometria:Tangente(ABS(cobEstadoTExto:cinAnguloLetra)).
              IF cobEstadoTexto:cinAnguloLetra GT 0 THEN
                mdeS[3] = - mdeS[3].
            END.
          END.
          WHEN pdf.tipos.Transformacion:Mover THEN ASSIGN
            mdeS[5] = ipinX
            mdeS[6] = ipinY
          {&END}
          WHEN pdf.tipos.Transformacion:Rotar THEN DO:
            IF cobEstadoTExto:cinAngulo NE 0 THEN DO:
              mdeS[1] = pdf.utiles.Trigonometria:CoSeno(cobEstadoTExto:cinAngulo).
              mdeS[2] = pdf.utiles.Trigonometria:Seno(cobEstadoTExto:cinAngulo).
              mdeS[3] = - mdeS[2].
              mdeS[4] = mdeS[1].
            END.
          END.
        END.
        multiplicarTM(mdeP,mdeS,OUTPUT mdeP).
      END.
    END.
    ELSE DO:
      mdeP[1] = cdeEscalaEnX.
      mdeP[4] = cdeEscalaEnY.
      mlgPrevia = mdeP[1] NE 1 OR mdeP[4] NE 1.
      IF cobEstadoTExto:cinAnguloLetra NE 0 THEN DO:      
        mdeS[1] = 1.
        mdeS[2] = 0.
        mdeS[3] = pdf.utiles.Trigonometria:Tangente(ABS(cobEstadoTExto:cinAnguloLetra)).
        IF cobEstadoTexto:cinAnguloLetra GT 0 THEN
          mdeS[3] = - mdeS[3].
        mdeS[4] = 1.
        IF mlgPrevia THEN
          multiplicarTM(mdeP,mdeS,OUTPUT mdeP).
        ELSE
          mdeP = mdeS.
        mlgPrevia = TRUE.
      END.
      
      IF cobEstadoTexto:clgEspejarEnX OR cobEstadoTexto:clgEspejarenY THEN DO:
        mdeS[1] = 1.
        mdeS[2] = 0.
        mdeS[3] = 0.
        mdeS[4] = 1.
        IF cobEstadoTExto:clgEspejarEnX THEN
          mdeS[1] = -1.
        IF cobEstadoTexto:clgEspejarEnY THEN
          mdeS[4] = -1.
        IF mlgPrevia THEN
          multiplicarTM(mdeP,mdeS,OUTPUT mdeP).      
        ELSE
          mdeP = mdeS.
        mlgPrevia = TRUE.
      END.
          
      IF cobEstadoTExto:cinAngulo NE 0 THEN DO:
        mdeS[1] = pdf.utiles.Trigonometria:CoSeno(cobEstadoTExto:cinAngulo).
        mdeS[2] = pdf.utiles.Trigonometria:Seno(cobEstadoTExto:cinAngulo).
        mdeS[3] = - mdeS[2].
        mdeS[4] = mdeS[1].
        IF mlgPrevia THEN
          multiplicarTM(mdeP,mdeS,OUTPUT mdeP).      
        ELSE
          mdeP = mdeS.
      END.
      mdeP[5] = ipinX.
      mdeP[6] = ipinY.
    END.
    RETURN pdf.Documento:dec2string(mdeP[1]) + ' ' + pdf.Documento:dec2string(mdeP[2]) + ' ' + pdf.Documento:dec2string(mdeP[3]) + ' ' + pdf.Documento:dec2string(mdeP[4]) + ' ' + STRING(INTEGER(mdeP[5])) + ' ' + STRING(INTEGER(mdeP[6])) + ' Tm' + {&pdfSKIP}.
  END METHOD.
  
  METHOD PUBLIC VOID SaltoDeLinea():
    SaltoDeLinea(1).
  END METHOD.
  METHOD PUBLIC VOID SaltoDeLinea(INPUT ipinCantidad AS INTEGER):
    DEFINE VARIABLE mchSalto AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minY AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdeDelta AS DECIMAL NO-UNDO.
  
    clgReposicionando = TRUE.
    IF cdeEspacioVertical NE ? AND cdeEspacioVertical NE 0 THEN
      mdeDelta = cdeEspacioVertical.
    ELSE
      mdeDelta = cobEstadoTexto:cobLetra:cdePuntos + cinEspacioEntreLineas.
    mchSalto = pdf.Documento:dec2string(mdeDelta).
    minY = cobEstadoTexto:cobPosicion:cinY.
    DO WHILE ipinCantidad GT 0: 
      AgregarElemento("TEXTSKIP",PDFTransformMatrix(cobMargenes:cinIzquierda,minY,FALSE)
        + "0 -" + mchSalto
        + " TD","","").
      ipinCantidad = ipinCantidad - 1.
      minY = minY - INT(mdeDelta).
      cobEstadoTexto:cobPosicion:cinX = cobMargenes:cinIzquierda.
      cobEstadoTexto:cobPosicion:cinY = minY.
      IF clgCompletarEnNuevaPagina THEN DO:
        cobDocumento:cobPaginaActual:SaltoDeLinea(ipinCantidad).
        RETURN.
      END.
    END.
    FINALLY:
      clgReposicionando = FALSE.
    END.
  END METHOD.
  
  METHOD PROTECTED VOID AgregarElemento(INPUT ipchTipo AS CHARACTER, INPUT ipchValorPrevio AS CHARACTER, INPUT ipchContenido AS CHARACTER, INPUT ipchValorPosterior AS CHARACTER):
    IF ipchTipo BEGINS "TEXT" AND clgAgregandoTexto THEN DO:
      especificarEstiloDeTexto(FALSE).
      AgregarContenido(ipchValorPrevio,ipchContenido,ipchValorPosterior).
      clgAgregandoTexto = ipchTipo NE 'TEXTEND'.
      RETURN.
    END.

    IF ipchTipo BEGINS "IMAGE" THEN DO:
      IF clgAgregandoImagen THEN
        MasContenido({&pdfSKIP} + "Q" + {&pdfSKIP} + "q" + {&pdfSKIP}).
      ELSE DO:
        IF clgAgregandoTexto THEN
          MasContenido({&pdfSkip} + finBloqueTexto()+ {&pdfSkip}).
        MasContenido({&pdfSkip} + "q" + {&pdfSkip}).
      END.
      
      ASSIGN
        clgAgregandoTexto  = FALSE
        clgAgregandoImagen = TRUE
      {&END}
    END. /* End Image */
    ELSE IF ipchTipo BEGINS "TEXT" THEN DO:
      IF NOT clgAgregandoTexto THEN DO:
        IF clgAgregandoImagen THEN
          MasContenido({&pdfSkip} + "Q" + {&pdfSkip}).
        MasContenido("BT" + {&pdfSkip} + letraActualPDF() + colorActualPDF() + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE)). 
      END.
      ASSIGN
        clgAgregandoImagen = FALSE
        clgAgregandoTexto  = TRUE
      {&END}
    END.
    ELSE DO:
      IF clgAgregandoTexto THEN
        MasContenido({&pdfSkip} + finBloqueTexto() + {&pdfskip}).
      IF NOT clgAgregandoImagen THEN
        MasContenido({&pdfSkip} + "q" + {&pdfskip}).
      ASSIGN 
        clgAgregandoTexto  = FALSE
        clgAgregandoImagen = TRUE
      {&END}
    END.
    IF ipchTipo BEGINS 'TEXT' THEN DO:
      especificarEstiloDeTexto(FALSE).
    END.
    ELSE DO:
      especificarColorPincel(FALSE).
      especificarUnionLineas(FALSE).
    END.
    AgregarContenido(ipchValorPrevio,ipchContenido,ipchValorPosterior).

    IF ipchTipo BEGINS "IMAGE" THEN DO:
      MasContenido({&pdfSkip} + "Q" + {&pdfSkip}).
      clgAgregandoImagen = FALSE.
    END.
    ELSE IF ipchTipo EQ 'TEXTEND' THEN
      clgAgregandoTexto = FALSE.
    ELSE IF ipchTipo EQ 'GRAPHICEND' THEN
      clgAgregandoImagen = FALSE.
  END METHOD.
  
  /* contadores necesarios para el anidamiento de marcas */
  DEFINE PROTECTED VARIABLE cinContadorNegrita AS INTEGER NO-UNDO.
  DEFINE PROTECTED VARIABLE cinContadorCursiva AS INTEGER NO-UNDO.
  
  METHOD PROTECTED CHARACTER prepararReemplazoMarcadores(INPUT ipchContenido AS CHARACTER):
    /* Convert tags to single characters - easier to work with */
    ASSIGN
      ipchContenido = REPLACE(ipchContenido, "<B>",  {&BoldOnChar} )
      ipchContenido = REPLACE(ipchContenido, "<~/B>", {&BoldOffChar} )
      ipchContenido = REPLACE(ipchContenido, "<I>",  {&ItalicOnChar} )
      ipchContenido = REPLACE(ipchContenido, "<~/I>", {&ItalicOffChar} ) 
      ipchContenido = REPLACE(ipchContenido, "<Color=",  {&ColorOnChar} )
      ipchContenido = REPLACE(ipchContenido, "<~/Color>", {&ColorOffChar} ) 
    NO-ERROR.
    RETURN ipchContenido.
  END METHOD.
  
  /*
  realiza las adecuaciones de estilo y color que corresponden al texto y devuelve la
  porción de texto que debe generarse con el nuevo estilo.
  */
  METHOD PROTECTED CHARACTER siguientePorcion(INPUT-OUTPUT bpchContenido AS CHARACTER):
    DEFINE VARIABLE minChar AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchLista AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchChar AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchColorChar AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchColor AS CHARACTER NO-UNDO.

    IF   INDEX(bpchContenido,{&BoldOnChar} ) EQ 0
      AND INDEX(bpchContenido,{&BoldOffChar} ) EQ 0
      AND INDEX(bpchContenido,{&ItalicOnChar} ) EQ 0
      AND INDEX(bpchContenido,{&ItalicOffChar} ) EQ 0
      AND INDEX(bpchContenido,{&ColorOnChar} ) EQ 0
      AND INDEX(bpchContenido,{&ColorOffChar} ) EQ 0 THEN DO:
      mchPorcion = bpchContenido.
      bpchContenido = ''.
      RETURN mchPorcion.
    END.
    /* cambiar estilo y devolver porción correspondiente */ 
    mchLista = {&BoldOnChar} + ',' + {&ItalicOnChar} + ',' + {&ColorOnChar} + ',' + {&ColorOffChar} + ',' + {&BoldOffChar} + ',' + {&ItalicOffChar}.
    /* Loop through the text finding the blocks to change */
    minChar = 1.
    DO WHILE minChar LE LENGTH(bpchContenido):
      ASSIGN
        mchChar = SUBSTRING(bpchContenido, minChar, 1)
        minChar = minChar + 1
      {&END}
      IF LOOKUP(mchChar,mchLista) EQ 0 THEN
        mchPorcion = mchPorcion + mchChar.
      ELSE DO:
        /* si cambia en algo el estilo, y ya tengo algo previo, hasta acá llegué */
        IF LENGTH(mchPorcion) GT 0 THEN DO:
          SUBSTRING(bpchContenido,1,minChar - 2) = ''.
          RETURN mchPorcion.
        END.
        /* Toggle Font */
        CASE mchChar:
          /* Toggle Bold ON */
          WHEN {&BoldOnChar} THEN DO:
            /* Increment the Bold level counter */
            cinContadorNegrita = cinContadorNegrita + 1.
            /* Determine whether we should bold and italicize or just bold */
            IF cinContadorCursiva GT  0 THEN ASSIGN 
                cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNegritaCursiva:cchNombre
                cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNegritaCursiva:cdePuntos
            {&END}
            ELSE ASSIGN
              cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNegrita:cchNombre
              cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNegrita:cdePuntos
            {&END}
          END. /* BoldOn */
          /* Toggle Bold OFF */
          WHEN {&BoldOffChar} THEN DO:
            /* Decrement the Bold level counter */
            cinContadorNegrita = cinContadorNegrita - 1.
            /* Determine whether we return to Italics or the Default font */
            IF cinContadorNegrita LE 0 THEN DO: 
              IF cinContadorCursiva GT 0 THEN ASSIGN
                  cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraCursiva:cchNombre
                  cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraCursiva:cdePuntos
              {&END}
              ELSE ASSIGN 
                cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNormal:cchNombre
                cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNormal:cdePuntos
              {&END}
            END.
          END.
          /* Toggle Italics ON */
          WHEN {&ItalicOnChar} THEN DO:
            /* Increment the Italic level counter */
            cinContadorCursiva = cinContadorCursiva + 1.
            /* Determine whether we should italicize and bold or just italicize */
            IF cinContadorNegrita GT 0 THEN ASSIGN
                cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNegritaCursiva:cchNombre
                cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNegritaCursiva:cdePuntos
            {&END}
            ELSE ASSIGN 
              cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraCursiva:cchNombre
              cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraCursiva:cdePuntos
            {&END}
          END.
          /* Toggle Italics OFF */
          WHEN {&ItalicOffChar} THEN DO:
            /* Decrement the Italic level counter */
            cinContadorCursiva = cinContadorCursiva - 1.
            /* Determine whether we return to Bold or the Default font */
            IF cinContadorCursiva LE 0 THEN DO: 
              IF cinContadorNegrita GT 0 THEN ASSIGN 
                  cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNegrita:cchNombre
                  cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNegrita:cdePuntos
              {&END}
              ELSE ASSIGN
                cobEstadoTexto:cobLetra:cchNombre = cobDocumento:cobLetraNormal:cchNombre
                cobEstadoTexto:cobLetra:cdePuntos = cobDocumento:cobLetraNormal:cdePuntos
              {&END} 
            END.
          END.
          /* Toggle Color ON */
          WHEN {&ColorOnChar} THEN DO:
            mchColor  = "".
            /* Read the colour */
            COLOR-LOOP:
            DO WHILE minChar LE LENGTH(bpchContenido):
              ASSIGN
                mchColorChar= SUBSTRING(bpchContenido, minChar, 1)
                minChar = minChar + 1
              {&END}
              IF mchColorChar EQ ">" THEN
                LEAVE COLOR-LOOP.
              ELSE
                mchColor = mchColor + mchColorChar.
            END.
            /* Store the Color */
            IF VALID-OBJECT(cobDocumento:colorDefinido(mchColor)) THEN DO:
              archivarColor(mchColor).
              /* Set Color */
              cobEstadoTexto:cobColor:Copiar(cobDocumento:colorDefinido(mchColor)).
            END.
          END.
          /* Toggle Color OFF */
          WHEN {&ColorOffChar} THEN DO:
            /* Remove the Last Color */
            desarchivarColor().
          END.
        END CASE.
      END. /* ELSE */
    END. /* Do minChar */
    /* si llegué hasta acá, es porque terminé de procesar el contenido */
    bpchContenido = ''.
    RETURN mchPorcion.
  END METHOD.
  
  METHOD PROTECTED VOID AgregarContenido(INPUT ipchPrevio AS CHARACTER, INPUT ipchContenido AS CHARACTER, INPUT ipchPost AS CHARACTER):
    MasContenido(ipchPrevio).
    MasContenido(ipchContenido).
    IF INDEX(ipchContenido,cobDocumento:cchMarcaTotalPaginas) > 0 THEN
      clgTieneTotalDePaginas = TRUE.
    IF INDEX(ipchContenido,cobDocumento:cchMarcaNumeroDePagina) > 0 THEN
      clgTieneNumeroDePagina = TRUE.
    MasContenido(ipchPost + {&pdfSKIP}).
END METHOD.

METHOD PUBLIC VOID colorTexto(INPUT ipobColor AS pdf.utiles.Color):
  cobDocumento:cobColorTexto:Copiar(ipobColor).
  AgregarElemento("TEXTCOLOR",ipobColor:cchRojo + " "
    + ipobColor:cchVerde + " " + ipobColor:cchAzul + " rg ","","").
  clgColorRellenoHaCambiado = clgColorRellenoHaCambiado OR NOT cobEstadoGrafico:cobColorRelleno:EsIgual(ipobColor).
END METHOD.
  
METHOD PUBLIC VOID generarPagina(INPUT ipinPadre AS INTEGER, INPUT ipinRecursos AS INTEGER):
  DEFINE VARIABLE mchPDF          AS CHARACTER          NO-UNDO.
  DEFINE VARIABLE minObjetoStream AS INTEGER            NO-UNDO.
  DEFINE VARIABLE minObjetoLength AS INTEGER            NO-UNDO.
  DEFINE VARIABLE mobEnlace       AS pdf.enlaces.Enlace NO-UNDO.
  DEFINE VARIABLE mliLen      AS INT64 NO-UNDO.
  DEFINE VARIABLE mlcContenido AS LONGCHAR NO-UNDO.
  /* cambiar números de página y total de página en el contenido */
  mlcContenido = clcContenido.
  IF clgTieneNumeroDePagina THEN
    mlcContenido = REPLACE(mlcContenido,cobDocumento:cchMarcaNumeroDePagina,STRING(cinNumero)).
  IF clgTieneTotalDePaginas THEN
    mlcContenido = REPLACE(mlcContenido,cobDocumento:cchMarcaTotalPaginas,STRING(cobDocumento:cinTotalPaginas)).
    
  asignarObjetoPDF().
  minObjetoStream = cobDocumento:crearObjeto("Content - PDFinclude").
  minObjetoLength = cobDocumento:crearObjeto('Length').
  cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).
  mchPDF = mchPDF + "<<" + {&pdfSKIP}
    + "/Type /Page" + {&pdfSKIP}
    + "/Parent " + STRING(ipinPadre) + " 0 R" + {&pdfSKIP}.
  mchPDF = mchPDf + "/Resources " + STRING(ipinRecursos) + " 0 R" + {&pdfSKIP} + "/Contents ".
  mchPDF = mchPDF + STRING(minObjetoStream) + " 0 R" + {&pdfSKIP}.
  mchPDF = mchPDF + "/Rotate " + STRING(cinRotacion) + {&pdfSKIP}.
  mchPDF = mchPDF + "/MediaBox [ 0 0 " + STRING(cinAncho) +  " " + STRING(cinAlto) + "]" + {&pdfSKIP}.
  IF VALID-OBJECT(cobADC) THEN 
    mchPDF = mchPDF + "/CropBox [ " + STRING(cobADC:cinIzquierda) + ' ' + STRING(cobADC:cinArriba) + ' ' + STRING(cobADC:cinDerecha) + ' ' + STRING(cobADC:cinAbajo) + " ]" + {&pdfSKIP}.

  mchPDF = mchPDF + "/Annots [ " + {&pdfSKIP}.

  /* Output Link Definitions */
  mobEnlace = cobDocumento:siguienteEnlace(?,THIS-OBJECT).
  DO WHILE VALID-OBJECT(mobEnlace):
    mobEnlace:asignarObjetoPDF().
    mchPDF = mchPDF + STRING(mobEnlace:cinObjetoPDF) + " 0 R" + {&pdfSKIP}.
    mobEnlace = mobEnlace:siguiente().
  END.

  cobDocumento:cobDestino:agregar(mchPDf + " ]" + {&pdfSKIP} + ">>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
  /* PDFinclude Content Stream */
  cobDocumento:inicioObjeto(THIS-OBJECT,minObjetoStream).
  mchPDF = "<<" + {&pdfSKIP} + "/Length " + STRING(minObjetoLength) + " 0 R" + {&pdfSKIP}.

  /* Only add the Filter if 'Compress' is turned on */
  IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
    mchPDF = mchPDF + "/Filter /" + cobDocumento:cobCompresor:cchNombreMetodo + {&pdfSKIP}.

  mchPDF = mchPDF + ">>" + {&pdfSKIP} + "stream" + {&pdfSKIP} .
  cobDocumento:cobDestino:agregar(mchPDF).
  /*
  encriptar/comprimir
  */
  IF VALID-OBJECT(cobDocumento:cobCompresor) THEN DO ON ERROR UNDO, THROW:
    DEFINE VARIABLE mmpTmp AS MEMPTR NO-UNDO.
    mmpTmp = cobDocumento:cobCompresor:Comprimir(mlcContenido).
    cobDocumento:cobDestino:agregar(mmpTmp).
    mliLen = GET-SIZE(mmpTmp).
    FINALLY:
      SET-SIZE(mmpTmp) = 0.
    END FINALLY.
  END.
  ELSE DO:
    mliLen = cobDocumento:cobDestino:posicion().
    cobDocumento:cobDestino:agregar(mlcContenido).
    mliLen = cobDocumento:cobDestino:posicion() - mliLen.
  END.
  /* End Page Definition */
  mchPDF = {&pdfSKIP} + "endstream" + {&pdfSKIP} + "endobj" + {&pdfSKIP}.
  /* Output Length */
  cobDocumento:cobDestino:agregar(mchPDF).
  cobDocumento:inicioObjeto(THIS-OBJECT,minObjetoLength).
  cobDocumento:cobDestino:agregar(STRING(mliLen) + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
END METHOD.
 
METHOD PUBLIC VOID moverA(INPUT ipobPunto AS pdf.utiles.Punto):
  AgregarElemento("GRAPHIC",STRING(ipobPunto:cinX) + " " + STRING(ipobPunto:cinY) + " m","","").
  cobEstadoGrafico:cobPosicion:Copiar(ipobPunto).
END METHOD.

METHOD PUBLIC VOID Rectangulo(INPUT ipobDonde AS pdf.utiles.Area, INPUT ipdcGrosor AS DECIMAL):
  Rectangulo(ipobDonde,ipdcGrosor,'B').
END METHOD. 
METHOD PUBLIC VOID Rectangulo(INPUT ipobDonde AS pdf.utiles.Area,INPUT ipdcGrosor AS DECIMAL, INPUT ipchEstilo AS CHARACTER):
  IF ipchEstilo NE 'S' THEN
    ipchEstilo = 'B'. 
  AgregarElemento("GRAPHIC",colorRellenoActualPDF() + pdf.Documento:dec2string(ipdcGrosor) + " w" + {&pdfSkip}  /* JES ADDED */
    + STRING(ipobDonde:cinX) + " " + STRING(ipobDonde:cinY) + " "
    + STRING(ipobDonde:cinAncho) + " " + STRING(ipobDonde:cinAlto)
    + " re" + {&pdfSkip}
    + ipchEstilo,
    "","").
  cobEstadoGrafico:cobPosicion:cinX = ipobDonde:cinAncho + ipobDonde:cinX.
  cobEstadoGrafico:cobPosicion:cinY = ipobDonde:cinY.
END METHOD.
 
METHOD PUBLIC VOID Curva(INPUT ipobPunto1 AS pdf.utiles.Punto,INPUT ipobPunto2 AS pdf.utiles.Punto,INPUT ipobPunto3 AS pdf.utiles.Punto, INPUT ipdcGrosor AS DECIMAL):
  /* A Bézier curve is added from the current Graphic X/Y Location to X3/Y3 
     using X1/Y1 and X2/Y2) as the control points. The X3/Y3 of the curve 
     becomes the new Graphic X/Y Location.  */
  IF cobEstadoGrafico:cobPosicion:cinY EQ 0 OR cobEstadoGrafico:cobPosicion:cinX EQ 0 THEN
    UNDO, THROW NEW PDFException("Graphic X/Y location has not been initialized!").
  
  AgregarElemento("GRAPHIC",
                            /* igc - rem CHR(10) + */ pdf.Documento:dec2string(ipdcGrosor)
    + " w" + {&pdfSkip} + colorRellenoActualPDF()    
    + STRING(ipobPunto1:cinX) + " " + STRING(ipobPunto1:cinY)
    + " " + STRING(ipobPunto2:cinX) + " " + STRING(ipobPunto2:cinY) + " "
    + STRING(ipobPunto3:cinX) + " " + STRING(ipobPunto3:cinY) + " c",
    "","").  
  /* Set the new Graphic Points */
  cobEstadoGrafico:cobPosicion:Copiar(ipobPunto3).
END METHOD. /* pdf_curve */

METHOD PUBLIC VOID Circulo(INPUT ipobCentro AS pdf.utiles.Punto,INPUT ipinRadio AS INTEGER, INPUT ipdcGrosor AS DECIMAL):
  /* Note:  pdfX and pdfY represent the center point of the circle.  These
            values become the new Graphic X and Y points after the drawing of
            the circle.  If you want the circle to be filled use pdf_stroke_fill
  */
  DEFINE VARIABLE l_Constant AS DECIMAL          DECIMALS 10 NO-UNDO.
  DEFINE VARIABLE l_Length   AS INTEGER          NO-UNDO.
  DEFINE VARIABLE mobP1      AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP2      AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobP3      AS pdf.utiles.Punto NO-UNDO.

  l_Constant = 0.5522847498. /* (4/3)*(sqrt(2)-1) - who knows where this calc came from */
  l_Length = INTEGER(ipinRadio * l_Constant).

  /* First Quadrant - Upper Right */
  mobP1 = NEW pdf.utiles.Punto().
  mobP2 = NEW pdf.utiles.Punto().
  mobP3 = NEW pdf.utiles.Punto().
    
  mobP1:Copiar(ipobCentro).
  mobP1:DeltaX(ipinRadio).
  MoverA(mobP1).
    
  mobP1:DeltaY(l_Length).
  mobP2:Copiar(ipobCentro).
  mobP2:DeltaX(l_Length).
  mobP2:DeltaY(ipinRadio).
  mobP3:Copiar(ipobCentro).
  mobP3:DeltaY(ipinRadio).

  Curva(mobP1,mobP2,mobP3,ipdcGrosor).

  /* Second Quadrant - Upper Left */
  mobP1:Copiar(cobEstadoGrafico:cobPosicion).
  mobP1:DeltaX(- L_Length).
  mobP2:Copiar(ipobCentro).
  mobP2:DeltaX(- ipinRadio).
  mobP2:DeltaY(- ipinRadio + l_Length).
  mobP3:cinX = ipobCentro:cinX - ipinRadio.
  mobP3:cinY = cobEstadoGrafico:cobPosicion:cinY - ipinRadio.
  Curva(mobP1,mobP2,mobP3,ipdcGrosor).

  /* Third Quadrant - Lower Left */
  mobP1:Copiar(ipobCentro).
  mobP1:DeltaX(- ipinRadio).
  mobP1:DeltaY(- l_Length).
  mobP2:Copiar(ipobCentro).
  mobP2:DeltaX(- l_Length).
  mobP2:DeltaY(- ipinRadio).
  mobP3:Copiar(ipobCentro).
  mobP3:DeltaY(- ipinRadio).
  Curva(mobP1,mobP2,mobP3,ipdcGrosor).

  /* Fourth Quadrant - Lower Right */
  mobP1:Copiar(ipobCentro).
  mobP1:DeltaY(- ipinRadio).
  mobP2:Copiar(ipobCentro).
  mobP2:DeltaX(ipinRadio).
  mobP2:DeltaY(- l_Length).
  mobP3:Copiar(ipobCentro).
  mobP3:DeltaX(ipinRadio).
  Curva(mobP1,mobP2,mobP3,ipdcGrosor).

  /* Close the Path */
  CerrarCurva().

  /* Set the current point to be the current Graphic X/Y Location */
  cobEstadoGrafico:cobPosicion:Copiar(ipobCentro).
  FINALLY:
    DELETE OBJECT mobP1 NO-ERROR.
    DELETE OBJECT mobP2 NO-ERROR.
    DELETE OBJECT mobP3 NO-ERROR.
  END FINALLY.
END METHOD. /* pdf_circle */
  
METHOD PUBLIC VOID CerrarCurva():
  AgregarElemento("GRAPHIC",
  /* igc - rem CHR(10) + */ "B",
    "","").
END METHOD.

METHOD PUBLIC VOID lineaInterrumpida(INPUT ipinInicio AS INTEGER, INPUT ipinFin AS INTEGER):
  IF ipinInicio LT 0 THEN
    ipinInicio = 1.
  IF ipinFin LT 0 THEN
    ipinFin = 1.

  AgregarElemento("GRAPHIC"," [" + STRING(ipinInicio) + " " + STRING(ipinFin)+ "] 0  d ","","").
END METHOD. /* pdf_set_dash */

METHOD PUBLIC VOID Linea(INPUT ipobInicio AS pdf.utiles.Punto, INPUT ipobFin AS pdf.utiles.Punto,INPUT ipdcGrosor AS DECIMAL):
  AgregarElemento("GRAPHIC",pdf.Documento:dec2string(ipdcGrosor) + " w" + {&pdfSkip}
    + STRING(ipobInicio:cinX) + " " + STRING(ipobInicio:cinY) + " m" + {&pdfSkip}
    + STRING(ipobFin:cinX) + " " + STRING(ipobFin:cinY) + " l" + {&pdfSkip}
    + "S","","").
  cobEstadoGrafico:cobPosicion:Copiar(ipobFin).
END METHOD. /* pdf_line */

METHOD PUBLIC VOID MarcaDeAgua(INPUT ipchTexto AS CHARACTER,INPUT ipobDonde AS pdf.utiles.Punto):
  DEFINE VARIABLE L_Font      AS CHARACTER NO-UNDO.
  DEFINE VARIABLE L_PointSize AS CHARACTER NO-UNDO.

  ipchTexto = cobDocumento:escaparTexto(ipchtexto).

  AgregarElemento("WATERMARK","BT" + {&pdfSkip} + letraActualPDF(TRUE)
    + PDFTransformMatrix(ipobDonde:cinX,ipobDonde:cinY,TRUE) + colorActualPDF(TRUE)
    + "T* (",
    ipchTexto,
    ") Tj" + {&pdfSkip} + finBloqueTexto()).
END METHOD. /* pdf_watermark */

/*
desplaza la posición actual en base al ángulo, la escala y el ancho del texto
especificado.
*/
METHOD PROTECTED VOID deltaPosTexto(INPUT ipobPunto AS pdf.utiles.Punto,INPUT ipdeAncho AS DECIMAL):
  DEFINE VARIABLE mdeCoseno AS DECIMAL NO-UNDO.
  DEFINE VARIABLE mdeSeno AS DECIMAL NO-UNDO.
  DEFINE VARIABLE minAngulo AS INTEGER NO-UNDO.
  /*
  x' = cos & * x + sen & * y
  y' = - sen & * x + cos & * y
  */
  clgReposicionando = TRUE.
  minAngulo = pdf.utiles.Trigonometria:ajustarGrados(cobEstadoTExto:cinAngulo).
  CASE minAngulo:
    WHEN 0 THEN
      ipobPunto:DeltaX(INTEGER(ipdeAncho)).  
    WHEN 180 THEN
      ipobPunto:DeltaX(INTEGER(- ipdeAncho)).
    WHEN 90 THEN
      ipobPunto:DeltaY(INTEGER(ipdeAncho)).  
    WHEN 270 THEN
      ipobPunto:DeltaY(INTEGER(- ipdeAncho)).  
    OTHERWISE DO:
      mdeCoseno = pdf.utiles.Trigonometria:CoSeno(cobEstadoTExto:cinAngulo).
      mdeSeno = pdf.utiles.Trigonometria:Seno(cobEstadoTExto:cinAngulo).
      ipobPunto:DeltaX(INTEGER(ipdeAncho * mdeCoseno * cdeEscalaEnX + mdeSeno * cobEstadoTexto:cobLetra:cdePuntos)).
      ipobPunto:DeltaY(INTEGER(mdeSeno * ipdeAncho + mdeCoseno * cdeEscalaEnY * cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  FINALLY:
    clgReposicionando = FALSE.
  END FINALLY.
END METHOD.

METHOD PUBLIC VOID Texto(INPUT ipchTexto AS CHARACTER):
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXT",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(",mchPorcion,") Tj").
      deltaPosTexto(cobEstadoTExto:cobPosicion,cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  ELSE DO:
    ipchTexto = cobDocumento:escaparTexto(ipchTexto).
    AgregarElemento("TEXT",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(",ipchTexto,") Tj").
    deltaPosTexto(cobEstadoTExto:cobPosicion,cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos)).
  END.
END METHOD. /* pdf_text */
METHOD PUBLIC VOID Caracter(INPUT ipinValor AS INTEGER):

  IF ipinValor LE 0 OR ipinValor GT 377 THEN
    UNDO, THROW NEW PDFException("Value must be >= 1 and <= 377!").

  AgregarElemento("TEXT",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(","~\" + STRING(ipinValor),") Tj").
  /* Increase by 1 Character Length */
  deltaPosTexto(cobEstadoTExto:cobPosicion,cobEstadoTexto:cobLetra:cobLetra:AnchoTexto('w',cobEstadoTexto:cobLetra:cdePuntos)).
END METHOD. /* pdf_text_char */

METHOD PUBLIC VOID Texto(INPUT ipchTexto AS CHARACTER, INPUT ipobPosicion AS pdf.utiles.Punto):
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTXY",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(",mchPorcion,") Tj").
    END.
  END.
  ELSE DO:
    AgregarElemento("TEXTXY", colorActualPDF() + letraActualPDF() + PDFTransformMatrix(ipobPosicion:cinX,ipobPosicion:cinY,FALSE)
      + "(",
      cobDocumento:escaparTexto(ipchTexto),
      ") Tj").
  END.
END METHOD. /* pdf_text_charxy */

METHOD PROTECTED VOID CambioEnY(INPUT ipobPunto AS pdf.utiles.Punto):
  IF ipobPunto NE cobEstadoTexto:cobPosicion THEN
    UNDO, THROW NEW PDFException('Solo pueden procesarse los cambios de posición del estado de texto').
  /* verificar si es necesario realizar un salto de página automático */
  IF NOT cobDocumento:clgSaltoDePaginaAutomatico OR cobDocumento:clgEnPieDePagina THEN
    RETURN.
  IF NOT clgTerminada AND ipobPunto:cinY LE cobMargenes:cinAbajo THEN DO:
    clgCompletarEnNuevaPagina = TRUE.
    cobDocumento:AgregarPagina().
  END.
END METHOD.

METHOD PROTECTED VOID CambioDePosicion(INPUT ipobEstado AS pdf.EstadoTexto):  
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de texto correspondientes a la página').
  clgPosicionHaCambiado = clgPosicionHaCambiado OR NOT clgReposicionando.
END METHOD.
METHOD PROTECTED VOID CambioRotacion(INPUT ipobEstado AS pdf.EstadoTexto):
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de texto correspondientes a la página').
  clgRotacionHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID CambioInclinacion(INPUT ipobEstado AS pdf.EstadoTexto):
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de texto correspondientes a la página').
  clgInclinacionHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID CambioEspejado(INPUT ipobEstado AS pdf.EstadoTexto):
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de texto correspondientes a la página').
  clgEspejadoHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID CambioDeLetra(INPUT ipobEstado AS pdf.EstadoTexto):
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de texto correspondientes a la página').
  clgLetraHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID cambioEstiloDeTexto(INPUT ipenRender AS pdf.tipos.ENUM):
  clgEstiloDeTextoHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID CambioDeColorTexto(INPUT ipobEstado AS pdf.EstadoTexto):
  IF ipobEstado NE cobEstadoTexto THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de color correspondientes a la página').
  clgColorTextoHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID cambioDeColorPincel(INPUT ipobEstado AS pdf.EstadoGrafico):
  IF ipobEstado NE cobEstadoGrafico THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de color correspondientes a la página').
  clgColorPincelHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID cambioDeColorRelleno(INPUT ipobEstado AS pdf.EstadoGrafico):
  IF ipobEstado NE cobEstadoGrafico THEN
    UNDO, THROW NEW PDFException('Solo se pueden procesar los cambios de color correspondientes a la página').
  clgColorRellenoHaCambiado = TRUE.
END METHOD.
METHOD PROTECTED VOID cambioUnionLineas(INPUT ipenTipoUnion AS pdf.tipos.ENUM):
  clgUnionLineasHaCambiado = TRUE.
END METHOD.

METHOD PROTECTED CHARACTER letraActualPDF():
  RETURN letraActualPDF(FALSE).
END METHOD.
METHOD PROTECTED CHARACTER letraActualPDF(INPUT iplgForzar AS LOGICAL):
  IF NOT clgLetraHaCambiado AND NOT iplgForzar THEN
    RETURN ''.
  clgLetraHaCambiado = FALSE.  
  RETURN cobEstadoTexto:cobLetra:cobLetra:cchNombreInterno + " " + cobEstadoTexto:cobLetra:cchPuntos +  " Tf" + {&pdfSkip}.
END METHOD. /* pdf_set_font */
METHOD PROTECTED CHARACTER colorActualPDF():
  RETURN colorActualPDF(FALSE).
END METHOD.
METHOD PROTECTED CHARACTER colorActualPDF(INPUT iplgForzar AS LOGICAL):
  IF NOT clgColorTextoHaCambiado AND NOT iplgForzar THEN
    RETURN ''.
  clgColorTextoHaCambiado = FALSE.
  IF NOT clgColorRellenoHaCambiado THEN DO:
    /* si el color del relleno no ha cambiado y no es el mismo que el texto, entonces
    marcarlo como que ha cambiado */
    clgColorRellenoHaCambiado = NOT cobEstadoTexto:cobColor:EsIgual(cobEstadoGrafico:cobColorRelleno).
  END.
  RETURN cobEstadoTexto:cobColor:cchRojo + " " + cobEstadoTexto:cobColor:cchVerde + " "
    + cobEstadoTexto:cobColor:cchAzul + " rg " + {&pdfSkip}.
END METHOD. /* pdf_text_color */
METHOD PROTECTED CHARACTER colorRellenoActualPDF():
  RETURN colorRellenoActualPDF(FALSE).
END METHOD.
METHOD PROTECTED CHARACTER colorRellenoActualPDF(INPUT iplgForzar AS LOGICAL):
  IF NOT clgColorRellenoHaCambiado AND NOT iplgForzar THEN
    RETURN ''.
  clgColorRellenoHaCambiado = FALSE.
  IF NOT clgColorTextoHaCambiado THEN DO:
    /* si el color del texto no ha cambiado y no es el mismo que el relleno, entonces
    marcarlo como que ha cambiado */
    clgColorTextoHaCambiado = NOT cobEstadoTexto:cobColor:EsIgual(cobEstadoGrafico:cobColorRelleno).
  END.
  RETURN cobEstadoGrafico:cobColorRelleno:cchRojo
    + " " + cobEstadoGrafico:cobColorRelleno:cchVerde
    + " " + cobEstadoGrafico:cobColorRelleno:cchAzul + " rg " + {&pdfSkip}.
END METHOD. /* pdf_stroke_fill */

METHOD PROTECTED VOID especificarEstiloDeTexto(INPUT iplgForzar AS LOGICAL):
  IF NOT clgEstiloDeTextoHaCambiado AND NOT iplgForzar THEN
    RETURN.
  clgEstiloDeTextoHaCambiado = FALSE.
  AgregarElemento("TEXTRENDER", STRING(cobEstadoTexto:cenEstiloTexto:cinValor) +  " Tr","","").
END METHOD.
METHOD PROTECTED VOID especificarColorPincel(INPUT iplgForzar AS LOGICAL):
  IF NOT clgColorPincelHaCambiado AND NOT iplgForzar THEN
    RETURN.
  clgColorPincelHaCambiado = FALSE.
  AgregarElemento("GRAPHIC"," " + cobEstadoGrafico:cobColorPincel:cchRojo
    + " " + cobEstadoGrafico:cobColorPincel:cchVerde
    + " " + cobEstadoGrafico:cobColorPincel:cchAzul + " RG ",
    "","").
END METHOD.
METHOD PROTECTED VOID especificarUnionLineas(INPUT iplgForzar AS LOGICAL):
  IF NOT clgUnionLineasHaCambiado AND NOT iplgForzar THEN
    RETURN.
  clgUnionLineasHaCambiado = FALSE.
  AgregarElemento("GRAPHIC",STRING(cobEstadoGrafico:cenUnionLineas:cinValor) + " j","","").
END. /* pdf_set_linejoin */

METHOD PUBLIC VOID InsertarImagen(INPUT ipobImagen AS pdf.imagenes.Imagen, INPUT ipobLugar AS pdf.utiles.Area):
  InsertarImagen(ipobImagen,ipobLugar,FALSE).
END METHOD.
METHOD PUBLIC VOID InsertarImagen(INPUT ipobImagen AS pdf.imagenes.Imagen, INPUT ipobLugar AS pdf.utiles.Area, INPUT iplg2 AS LOGICAL):
  DEFINE VARIABLE ipobRegistrada AS pdf.imagenes.Imagen NO-UNDO.
  ipobRegistrada = cobDocumento:imagenRegistrada(ipobImagen:cchNombre).
  IF NOT VALID-OBJECT(ipobRegistrada) THEN
    cobDocumento:agregarImagen(ipobImagen).

  AgregarElemento("IMAGE" + (IF iplg2 THEN '2' ELSE ''),STRING(ipobLugar:cinAncho) + " 0 0 " + STRING(ipobLugar:cinAlto)
    + " " + STRING(ipobLugar:cinX) + " "
    + STRING(cinAlto - ipobLugar:cinY) + " cm "
    + ipobImagen:cchNombreInterno + " Do",
    "","").

  cobEstadoGrafico:cobPosicion:cinX = ipobLugar:cinX.
  cobEstadoGrafico:cobPosicion:cinY = ipobLugar:cinY.
END METHOD. /* pdf_place_image */

METHOD PUBLIC VOID TextoEn(INPUT ipchTexto AS CHARACTER, INPUT ipobDonde AS pdf.utiles.Punto):
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTXY",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(ipobDonde:cinX,ipobDonde:cinY,FALSE) + "(",mchPorcion,") Tj").
      deltaPosTexto(ipobDonde,cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  ELSE DO:
    AgregarElemento("TEXTXY", letraActualPDF() + colorActualPDF() + PDFTransformMatrix(ipobDonde:cinX,ipobDonde:cinY,FALSE)
      + "(",
      cobDocumento:escaparTexto(ipchTexto),
      ") Tj").
  END.
END METHOD. /* pdf_text_xy */
METHOD PUBLIC VOID TextoHasta(INPUT ipchTexto AS CHARACTER, INPUT ipobDonde AS pdf.utiles.Punto):
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mchOriginal AS CHARACTER NO-UNDO.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    mchOriginal = ipchTexto.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = siguientePorcion(INPUT-OUTPUT ipchTexto).
      ipobDonde:DeltaX(- cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos)).
    END.
    ipchTexto = mchOriginal.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTXY",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(ipobDonde:cinX,ipobDonde:cinY,FALSE) + "(",mchPorcion,") Tj").
      ipobDonde:DeltaX(cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  ELSE DO:
    ipobDonde:DeltaX(- cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos)).
    AgregarElemento("TEXTXY", letraActualPDF() + colorActualPDF() + PDFTransformMatrix(ipobDonde:cinX,ipobDonde:cinY,FALSE)
      + "(",
      cobDocumento:escaparTexto(ipchTexto),
      ") Tj").
  END.
END METHOD. /* pdf_text_xy */

METHOD PUBLIC VOID TextoEnCaja(INPUT ipchTexto AS CHARACTER, INPUT ipobDonde AS pdf.utiles.Area, INPUT ipenAlineamiento AS pdf.tipos.Alineacion, INPUT ipdeGrosor AS DECIMAL):
  DEFINE VARIABLE mdeAncho AS DECIMAL NO-UNDO.
  DEFINE VARIABLE minX AS INTEGER NO-UNDO.
  DEFINE VARIABLE minNX AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mchOriginal AS CHARACTER NO-UNDO.
  
  clgReposicionando = TRUE.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    mchOriginal = ipchTexto.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = siguientePorcion(INPUT-OUTPUT ipchTexto).
      mdeAncho = mdeAncho + cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos).
    END.
  END.
  ELSE
    mdeAncho = cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos).
  CASE ipenAlineamiento:cinValor:
    WHEN  pdf.tipos.Alineacion:Derecha THEN 
      DO:
        minNX = ipobDonde:cinX + ipobDonde:cinAncho.
        minX = minNX - mdeAncho.
      END.
    WHEN pdf.tipos.Alineacion:Centrado THEN 
      DO:
        minNX = ipobDonde:cinX + (ipobDonde:cinAncho - mdeAncho) / 2.
        minX = minNX.
        minNX = minNX + mdeAncho.
      END.
    OTHERWISE 
    DO: /* Izquierda */ 
      minX = ipobDonde:cinX.
      minNX = minX + mdeAncho.
    END.
  END.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = mchOriginal.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mdeAncho = cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos).
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTXY", letraActualPDF() + colorActualPDF() + PDFTransformMatrix(minX,ipobDonde:cinY,FALSE) + "(",mchPorcion,") Tj").
      minX = minX + mdeAncho.
    END.
  END.
  ELSE
    AgregarElemento("TEXTXY", letraActualPDF() + colorActualPDF() + 
      PDFTransformMatrix(minX,ipobDonde:cinY,FALSE)
      + "(",
      cobDocumento:escaparTexto(ipchTexto),
      ") Tj").
  cobEstadoTexto:cobPosicion:cinX = minNX.

  /* IF pdfWeight = 0 THEN pdfWeight = 1. */
  IF ipdeGrosor GT 0 THEN DO:
    IF ipobDonde:cinAlto GE cobEstadoTexto:cobLetra:cdePuntos THEN
      ipobDonde:cinY = ipobDonde:cinY - 1.
    AgregarElemento("GRAPHIC",
      "q" + {&pdfSkip}
      + pdf.Documento:dec2string(ipdeGrosor) + " w" + {&pdfSkip}
      + STRING(ipobDonde:cinX) + " " + STRING(ipobDonde:cinY) + " "
      + STRING(ipobDonde:cinAncho) + " " + STRING(ipobDonde:cinAlto)
      + " re" + {&pdfSkip}
      + "S" + {&pdfSkip}
      + "Q",
      "",
      "").
  END.

  cobEstadoTexto:cobPosicion:cinY = ipobDonde:cinY.
  cobEstadoGrafico:cobPosicion:cinY = ipobDonde:cinY.
  FINALLY:
    clgReposicionando = FALSE.
  END FINALLY.    
END METHOD. /* pdf_text_boxed_xy */

METHOD PUBLIC VOID TextoCentrado(INPUT ipchTexto AS CHARACTER, INPUT ipobDonde AS pdf.utiles.Punto):
  ipobDonde:cinX = ipobDonde:cinX - INTEGER(cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos) / 2).
  TextoEn(ipchTexto,ipobDonde).
END METHOD. /* pdf_text_center */
  
METHOD PUBLIC VOID TextoEnColumna(INPUT ipchTexto AS CHARACTER,INPUT ipinColumna AS INTEGER):
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  DEFINE VARIABLE minX AS INTEGER NO-UNDO.
  IF ipinColumna LE  0 THEN
    UNDO, THROW NEW PDFException("Column cannot lower than 1!").
  clgReposicionando = TRUE.
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = FILL(' ', ipinColumna - 1) + prepararReemplazoMarcadores(ipchTexto).
    cobEstadoTexto:cobPosicion:cinX = cobMargenes:cinIzquierda.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTAT",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTExto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(",mchPorcion,") Tj").
      cobEstadoTexto:cobPosicion:DeltaX(cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion, cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  ELSE DO:
    ipchTexto = FILL(' ', ipinColumna - 1) + cobDocumento:escaparTexto(ipchTexto).  
    AgregarElemento("TEXTAT",colorActualPDF() + letraActualPDF()
      + PDFTransformMatrix(cobMargenes:cinIzquierda,cobEstadoTexto:cobPosicion:cinY,FALSE)
      + "(",
      ipchTexto,
      ") Tj ").
  
    /* Increase the TextX dimension to include the new text.  The Y Dimension
       shouldn't change */
    cobEstadoTexto:cobPosicion:DeltaX(cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto, cobEstadoTexto:cobLetra:cdePuntos)).
  END.
  FINALLY:
    clgReposicionando = FALSE.
  END FINALLY.
END METHOD. /* pdf_text_at */

METHOD PUBLIC VOID TextoHastaColumna(INPUT ipchTexto AS CHARACTER, INPUT ipinColumna AS INTEGER):
  DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchOriginal AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.

  clgReposicionando = TRUE.
  IF ipinColumna LE  0 THEN
    UNDO, THROW NEW PDFException("Column cannot be lower than 1!").

  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    minAncho = cobEstadoTexto:cobLetra:cobLetra:AnchoTexto("WiwI",cobEstadoTexto:cobLetra:cdePuntos) / 4 * ipinColumna.
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    mchOriginal = ipchTexto.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = siguientePorcion(INPUT-OUTPUT ipchTexto).
      minAncho = minAncho - cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion, cobEstadoTexto:cobLetra:cdePuntos).
    END.
  END.
  ELSE IF cobEstadoTexto:cobLetra:cobLetra:cenTipoDeLetra:cinValor EQ pdf.tipos.Letra:AnchoFijo THEN DO:
    minAncho = cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(" ",cobEstadoTexto:cobLetra:cdePuntos) * (ipinColumna - LENGTH(ipchTexto, "character":u) - 1).
  END.
  ELSE DO:
    minAncho = cobEstadoTexto:cobLetra:cobLetra:AnchoTexto("WiwI",cobEstadoTexto:cobLetra:cdePuntos) / 4 * ipinColumna
      - cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos).
  END.
  cobEstadoTexto:cobPosicion:cinX = cobMargenes:cinIzquierda + minAncho.   
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = mchOriginal.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTTO",colorActualPDF() + letraActualPDF() + PDFTransformMatrix(cobEstadoTExto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE) + "(",mchPorcion,") Tj").
      cobEstadoTexto:cobPosicion:DeltaX(cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion, cobEstadoTexto:cobLetra:cdePuntos)).
    END.
  END.
  ELSE DO:
    AgregarElemento("TEXTTO",colorActualPDF() + letraActualPDF()
      + PDFTransformMatrix(cobEstadoTexto:cobPosicion:cinX,cobEstadoTexto:cobPosicion:cinY,FALSE)
      + "(",
      cobDocumento:escaparTexto(ipchTexto),
      ") Tj ").

    /* Set the TextX dimension to the new text column.  The Y Dimension
       shouldn't change */
    cobEstadoTexto:cobPosicion:DeltaX(cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto, cobEstadoTexto:cobLetra:cdePuntos)).
  END. /* Fixed */
  FINALLY:
    clgReposicionando = FALSE.
  END FINALLY.
END METHOD. /* pdf_text_to */
  
METHOD PUBLIC VOID TextoAlineado(INPUT ipchTexto AS CHARACTER, INPUT ipenAlineacion AS pdf.tipos.Alineacion, INPUT ipobDonde AS pdf.utiles.Punto):
  DEFINE VARIABLE L_Width AS DECIMAL NO-UNDO.
  DEFINE VARIABLE minX    AS INTEGER NO-UNDO.
  DEFINE VARIABLE minNX   AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchOriginal AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.

  /* Begin Procedure Validation */
  IF ipobDonde:cinX EQ 0 THEN
    UNDO, THROW NEW PDFException("X location cannot be zero!").
  IF ipobDonde:cinY EQ 0 THEN
    UNDO, THROW NEW PDFException("Y location cannot be zero!").

  clgReposicionando = TRUE.
  /* end of validation */
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
    mchOriginal = ipchTexto.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = siguientePorcion(INPUT-OUTPUT ipchTexto).
      L_Width = L_Width + cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(mchPorcion, cobEstadoTexto:cobLetra:cdePuntos).
    END.
  END.
  ELSE
    L_Width = cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(ipchTexto,cobEstadoTexto:cobLetra:cdePuntos).
  CASE ipenAlineacion:cinValor:
    WHEN  pdf.tipos.Alineacion:Derecha THEN 
      DO:
        minX = ipobDonde:cinX - L_Width.
        minNX = ipobDonde:cinX.
      END.
    WHEN pdf.tipos.Alineacion:Centrado THEN 
      DO:
        L_Width = L_Width / 2.
        minX = ipobDonde:cinX - L_Width.
        minNX = minX + L_Width.
      END.
    OTHERWISE 
    DO: /* Izquierda */ 
      minX = ipobDonde:cinX.
      minNX = minX + L_Width.
    END.
  END.
  
  IF cobDocumento:clgReemplazarMarcadores THEN DO:
    ipchTexto = mchOriginal.
    DO WHILE LENGTH(ipchTexto) GT 0:
      mchPorcion = cobDocumento:escaparTexto(siguientePorcion(INPUT-OUTPUT ipchTexto)).
      AgregarElemento("TEXTXY",letraActualPDF() + colorActualPDF() + PDFTransformMatrix(minX,ipobDonde:cinY,FALSE)
        + "(",
        mchPorcion,
        ") Tj").
      minX = minX + cobEstadoTexto:cobLetra:cobLetra:AnchoTextoDec(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos).
    END.
  END.
  ELSE DO:
    ipchTexto = cobDocumento:escaparTexto(TRIM(ipchTexto)).
        
    AgregarElemento("TEXTXY",letraActualPDF() + colorActualPDF() + PDFTransformMatrix(minX,ipobDonde:cinY,FALSE)
      + "(",
      ipchTexto,
      ") Tj").
  END.
  cobEstadoTexto:cobPosicion:cinX = minNX.
  FINALLY:
    clgReposicionando = FALSE.
  END FINALLY.    
END METHOD. /* pdf_text_align */

METHOD PUBLIC INTEGER AlturaConCortes(INPUT ipchTexto AS CHARACTER, INPUT ipinAncho AS INTEGER ):
  DEFINE VAR      pdfHeight   AS INTEGER          NO-UNDO.

  DEFINE VAR      v-thisline  AS CHAR             NO-UNDO.
  DEFINE VAR      v-lastline  AS CHAR             NO-UNDO.
  DEFINE VAR      i           AS INTEGER          NO-UNDO.
  DEFINE VAR      v-pointsize AS INTEGER          NO-UNDO.
  DEFINE VAR      v-maxwidth  AS INTEGER          NO-UNDO.
  DEFINE VARIABLE mobPunto    AS pdf.utiles.Punto NO-UNDO.
  
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinDesde = 0.
  mobPunto:cinHasta = ipinAncho.
  v-maxwidth = cobEstadoTexto:cobLetra:cobLetra:CantidadCaben(FILL("W",ipinAncho),mobPunto,cobEstadoTexto:cobLetra:cdePuntos).

  v-pointsize = cdeEspacioVertical.
  IF v-PointSize EQ 0 THEN
    v-pointsize = cobEstadoTexto:cobLetra:cdePuntos.

  ASSIGN 
    ipchTexto = REPLACE(ipchTexto,"|","&pipe;").
  /* Spaces */
  ASSIGN 
    ipchTexto = REPLACE(ipchTexto," ","| ").
  /* Hyphens */
  ASSIGN 
    ipchTexto = REPLACE(ipchTexto,"-","-|").
  /* Commas */
  ASSIGN 
    ipchTexto = REPLACE(ipchTexto,",",",|").

  /* Divide up the pdf text into lines of width less than the
     available width */
  DO i = 1 TO NUM-ENTRIES(ipchTexto,"|"):
    ASSIGN 
      v-lastline = v-thisline.
    ASSIGN 
      v-thisline = v-thisline
                        + REPLACE(ENTRY(i,ipchTexto,"|"),"&pipe;","|").
  
    IF LENGTH(ipchTexto,'CHARACTER':U) GT v-maxwidth THEN 
    DO:
      ASSIGN 
        pdfHeight = pdfHeight + v-pointsize.
      ASSIGN 
        v-thisline = TRIM(REPLACE(ENTRY(i,ipchTexto,"|"),"&pipe;","|")).
    END.
  END.

  IF v-thisline NE "" THEN
    ASSIGN pdfHeight = pdfHeight + v-pointsize.

  RETURN pdfHeight.
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END METHOD. /* pdf_get_wrap_length */

/*
devuelve la cantidad de líneas que realmente se generaron
la lista de elmentos por línea contiene la cantidad de elementos y la longitud total de la línea, separados por |
*/
METHOD PROTECTED INTEGER TextoEnLineas(INPUT ipchTexto AS CHARACTER, INPUT ipobArea AS pdf.utiles.Area, INPUT ipenAlineacion AS pdf.tipos.Alineacion, INPUT ipchElementosPorLinea AS CHARACTER):
  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
  DEFINE VARIABLE minCantidad AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
  DEFINE VARIABLE minElemento AS INTEGER NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
  
  mobPunto = NEW pdf.utiles.Punto().
  cobEstadoTexto:cobPosicion:cinY = ipobArea:cinArriba.
  minElemento = 1.
  DO minIndex = 1 TO NUM-ENTRIES(ipchElementosPorLinea):
    ASSIGN
      minCantidad = INTEGER(ENTRY(1,ENTRY(minIndex,ipchElementosPorLinea),'|')) /* cantidad de elementos */
      mchLinea = ENTRY(minElemento,ipchTexto,'|')
      minElemento = minElemento + 1
    {&END}
    DO WHILE minCantidad GT 1:
      ASSIGN
        minCantidad = minCantidad - 1
        mchLinea = mchLinea + ENTRY(minElemento,ipchTexto,'|')
        minElemento = minElemento + 1
      {&END}
    END.
    IF mchLinea EQ '&skip;'THEN DO:
      SaltoDeLinea().
      IF cobEstadoTexto:cobPosicion:cinY LE ipobArea:cinAbajo OR clgCompletarEnNuevaPagina THEN
        RETURN minIndex.
      NEXT. 
    END.
    ASSIGN
      minAncho = INTEGER(ENTRY(2,ENTRY(minIndex,ipchElementosPorLinea),'|'))
      mobPunto:cinY = cobEstadoTexto:cobPosicion:cinY
    {&END}
    CASE ipenAlineacion:cinValor:
      WHEN pdf.tipos.Alineacion:Izquierda THEN
        mobPunto:cinX = ipobArea:cinIzquierda.
      WHEN pdf.tipos.Alineacion:Derecha THEN
        mobPunto:cinX = ipobArea:cinDerecha - minAncho.
      OTHERWISE
        mobPunto:cinX = ipobArea:cinIzquierda + (ipobArea:cinAncho - minAncho) / 2. 
    END CASE.
    TextoEn(mchLinea,mobPunto).
    SaltoDeLinea().
    IF cobEstadoTexto:cobPosicion:cinY LE ipobArea:cinAbajo OR clgCompletarEnNuevaPagina THEN
      RETURN minIndex. /* minEntry */ 
  END. /* elementos por línea */
  RETURN NUM-ENTRIES(ipchElementosPorLinea).
  FINALLY:
    DELETE OBJECT mobPunto.
  END FINALLY.
END METHOD.
  
METHOD PUBLIC VOID TextoConCortes(INPUT ipchTexto AS CHARACTER, INPUT ipobArea AS pdf.utiles.Area, INPUT ipenAlineacion AS pdf.tipos.Alineacion):
  DEFINE VARIABLE minAncho AS INTEGER NO-UNDO.
  DEFINE VARIABLE minMaximo AS INTEGER NO-UNDO.
  DEFINE VARIABLE minLinea AS INTEGER NO-UNDO.
  DEFINE VARIABLE minEntry AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchEntry AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mchLista AS CHARACTER NO-UNDO.
  DEFINE VARIABLE minCantidad AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  DEFINE VARIABLE minNE AS INTEGER NO-UNDO.
  
  clgReposicionando = TRUE.

  ASSIGN 
    minMaximo = ipobArea:cinDerecha - ipobArea:cinIzquierda
    /* Replace Pipes in text string with processor directive &pipe; */
    ipchTexto = REPLACE(ipchTexto,"|","&pipe;")
    /* Line Feeds */
    ipchTexto = REPLACE(ipchTexto,CHR(10),"|&skip;|")
  {&END}
  /* reemplazar todos los delimitadores posponiéndoles '|' */
  DO minEntry = 1 TO NUM-ENTRIES(cobDocumento:cchSeparadoresPalabra):
    mchEntry = ENTRY(minEntry,cobDocumento:cchSeparadoresPalabra).
    IF LENGTH(mchEntry) EQ 0 THEN
      mchEntry = ','.
    ipchTexto = REPLACE(ipchTexto,mchEntry,mchEntry + '|').
  END.

  IF cobDocumento:clgReemplazarMarcadores THEN
    ipchTexto = prepararReemplazoMarcadores(ipchTexto).
  
  /* determinar la cantidad de elementos por línea */
  /* Divide up the pdf text into lines of width less than the
     available width */
  minNE = NUM-ENTRIES(ipchTexto,"|").
  DO minEntry = 1 TO minNE:
    mchEntry = REPLACE(ENTRY(minEntry,ipchTexto,"|"),"&pipe;","|").

    IF mchEntry EQ "&skip;" THEN DO:
      IF minCantidad GT 0 THEN
        mchLista = mchLista + ',' + STRING(minCantidad) + '|' + STRING(minLinea).
      ASSIGN
        mchLista = mchLista + ',1|0'
        minCantidad = 0
        minLinea = 0
      {&END}
      NEXT. /* minEntry */
    END.
    minAncho = 0.
    DO WHILE LENGTH(mchEntry) GT 0:
      IF cobDocumento:clgReemplazarMarcadores THEN
        mchPorcion = siguientePorcion(INPUT-OUTPUT mchEntry).
      ELSE ASSIGN
        mchPorcion = mchEntry
        mchEntry = ''
      {&END}
      minAncho = minAncho + cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(mchPorcion,cobEstadoTexto:cobLetra:cdePuntos).        
    END.
    IF minLinea + minAncho GT minMaximo THEN ASSIGN
      mchLista = mchLista + ',' + STRING(minCantidad) + '|' + STRING(minLinea)
      minCantidad = 1
      minLinea = minAncho
    {&END}
    ELSE IF minLinea + minAncho EQ minMaximo THEN ASSIGN
      mchLista = mchLista + ',' + STRING(minCantidad + 1) + '|' + STRING(minLinea + minAncho)
      minCantidad = 0 
      minLinea = 0
    {&END}
    ELSE ASSIGN
      minCantidad = minCantidad + 1
      minLinea = minLinea + minAncho
    {&END}
  END. /* minEntry = NUM-ENTRIES */
  IF minCantidad GT 0 THEN
    mchLista = mchLista + ',' + STRING(minCantidad) + '|' + STRING(minLinea).
  SUBSTRING(mchLista,1,1) = ''. /* sobra una coma, que quito */
  minCantidad = TextoEnLineas(ipchTexto,ipobArea,ipenAlineacion,mchLista).
  IF clgCompletarEnNuevaPagina THEN DO:
    minEntry = 1.
    DO minMaximo = 1 TO minCantidad:
      minEntry = minEntry + INTEGER(ENTRY(1,ENTRY(minMaximo,mchLista),'|')).
    END.
    /* "reunificar" lo que queda del texto */
    mchPorcion = ''.
    DO minMaximo = minCantidad + 1 TO NUM-ENTRIES(mchLista):
      minLinea = INTEGER(ENTRY(1,ENTRY(minMaximo,mchLista),'|')).
      DO WHILE minLinea GT 0:
        mchPorcion = mchPorcion + ENTRY(minEntry,ipchTexto,'|').
        minEntry = minEntry + 1.
      END.
      ASSIGN
        mchPorcion = REPLACE(mchPorcion,"|&skip;|",CHR(10))
        mchPorcion = REPLACE(mchPorcion,"&pipe;",'|')
      {&END}
      IF SUBSTRING(mchPorcion,1,1) EQ CHR(10) THEN
        SUBSTRING(mchPorcion,1,1) = ''.
      IF cobDocumento:clgReemplazarMarcadores THEN DO:
        /* agregar todos los inicios necesarios para que la siguiente página establezca el estado de texto correcto */
        IF cinContadorNegrita GT 0 THEN
          mchPorcion = FILL({&BoldOnChar},cinContadorNegrita) + mchPorcion.
        IF cinContadorCursiva GT 0 THEN
          mchPorcion = FILL({&ItalicOnChar},cinContadorCursiva) + mchPorcion.
        IF cinColoresArchivados GT 0 THEN DO:
          FOR EACH cttColorPrevio BY cttColorPrevio.inNumero DESC:
            mchPorcion = {&ColorOnChar} + cttColorPrevio.chNombre + '>' + mchPorcion.
          END.
        END.
      END.
      cobDocumento:cobPaginaActual:TextoConCortes(mchPorcion,ipobArea,ipenAlineacion).
    END.
  END.
  FINALLY:
    IF cobDocumento:clgReemplazarMarcadores THEN DO:
      cinContadorCursiva = 0.
      cinContadorNegrita = 0.
      EMPTY TEMP-TABLE cttColorPrevio.
    END.
    clgReposicionando = FALSE.
  END FINALLY.
END METHOD. /* pdf_wrap_text */

METHOD PUBLIC VOID reemplazarTexto(INPUT ipchDe AS CHARACTER, INPUT ipchA AS CHARACTER):
  clcContenido = REPLACE(clcContenido,ipchDe,ipchA).
END METHOD.

METHOD PUBLIC LOGICAL completarCampoFormulario(INPUT ipchCampo AS CHARACTER, INPUT ipchTexto AS CHARACTER, INPUT ipenAlineacion AS pdf.tipos.Alineacion, INPUT iplgMultilinea AS LOGICAL):
  FIND cttCampoFormulario WHERE cttCampoFormulario.chNombre EQ ipchCampo NO-ERROR.
  IF NOT AVAILABLE cttCampoFormulario THEN
    RETURN FALSE.
  RETURN completarCampoFormulario(cttCampoFormulario.inNumero,ipchTexto,ipenAlineacion,iplgMultilinea). 
END METHOD.

METHOD PUBLIC LOGICAL completarCampoFormulario(INPUT ipinCampo AS INTEGER, INPUT ipchTexto AS CHARACTER, INPUT ipenAlineacion AS pdf.tipos.Alineacion, INPUT iplgMultilinea AS LOGICAL):
  DEFINE VARIABLE mobCampo AS pdf.recursos.CampoFormulario NO-UNDO.
  DEFINE VARIABLE mchFormato AS CHARACTER NO-UNDO.
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
  DEFINE VARIABLE mchNomLetra AS CHARACTER NO-UNDO.
  
  FIND cttCampoFormulario WHERE cttCampoFormulario.inNumero EQ ipinCampo NO-ERROR.
  IF NOT AVAILABLE cttCampoFormulario THEN
    RETURN FALSE.
  mobCampo = CAST(cttCampoFormulario.obCampo,pdf.recursos.CampoFormulario).
  IF mobCampo:cchFormato NE "" THEN DO:
    mchFormato = mobCampo:cchFormato.
    DO minIndex = 1 TO NUM-ENTRIES(mchFormato,'~/'):
      mchNomLetra = ENTRY(1,ENTRY(minIndex,mchFormato,'~/'),' ').
      cobEstadoTexto:cobLetra:cchNombre = mchNomLetra.
      IF mchNomLetra EQ cobEstadoTexto:cobLetra:cchNombre THEN
        LEAVE.      
    END.
    IF mchNomLetra NE '' AND mchNomLetra NE cobEstadoTexto:cobLetra:cchNombre THEN
      cobEstadoTexto:cobLetra:cchNombre = 'Courier'.
    IF INDEX(mchFormato," 0 Tf") EQ 0 AND INDEX(mchFormato," Tf") GT 0 THEN
      cobEstadoTexto:cobLetra:cdePuntos = DEC(ENTRY(LOOKUP("Tf",mchFormato," ") - 1,mchFormato," ")).
    minIndex = INDEX(mchFormato,' rg').
    IF minIndex GT 0 THEN DO ON ERROR UNDO, THROW:
      /* color */
      mchNomLetra = SUBSTRING(mchFormato,1,minIndex + 2).
      minIndex = LOOKUP('rg',mchNomLetra,' ').
      IF minIndex GT 3 THEN
        cobEstadoTexto:cobColor:desdeRGB(DECIMAL(ENTRY(minIndex - 3,mchNomLetra,' ')),DECIMAL(ENTRY(minIndex - 2,mchNomLetra,' ')),DECIMAL(ENTRY(minIndex - 1,mchNomLetra,' '))).
    CATCH pError AS Progress.Lang.Error :
      DELETE OBJECT pError.
    END CATCH.
    END.
  END.
  IF iplgMultilinea THEN
    TextoConCortes(ipchTexto,mobCampo:cobArea,ipenAlineacion).
  ELSE DO: 
    mobPunto = NEW pdf.utiles.Punto().
    mobPunto:cinY = mobCampo:cobArea:cinAbajo.
    mobPunto:cinX = mobCampo:cobArea:cinIzquierda.
    CASE ipenAlineacion:cinValor:
      WHEN pdf.tipos.Alineacion:Derecha THEN DO:
        mobPunto:cinX = mobCampo:cobArea:cinDerecha.
        deltaPosTexto(mobPunto,- cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto, cobEstadoTexto:cobLetra:cdePuntos)).
      END. /* Right */
      WHEN pdf.tipos.Alineacion:Centrado THEN DO:
        mobPunto:DeltaX(INTEGER(mobCampo:cobArea:cinAncho / 2)). 
        deltaPosTexto(mobPunto,- cobEstadoTexto:cobLetra:cobLetra:AnchoTexto(ipchTexto, cobEstadoTexto:cobLetra:cdePuntos) / 2).
      END. /* Center */
    END.
    TextoEn(ipchTexto,mobPunto).
  END.
  FINALLY:
    DELETE OBJECT mobPunto NO-ERROR.
  END FINALLY.
END METHOD.
  
METHOD PUBLIC LOGICAL asignarObjetoPDF():
  IF cinObjetoPDF GT 0 THEN
    RETURN FALSE.
  cinObjetoPDF = cobDocumento:crearObjeto('PageDefinition').
  RETURN TRUE.
END METHOD.
END CLASS.