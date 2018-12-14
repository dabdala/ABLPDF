{pdf/pdf.i}
 
 /*------------------------------------------------------------------------
    File        : PDF
    Purpose     : Permitir la generación de PDF desde NSRA
    Syntax      : 
    Description : Implementación orientada a objetos de PDFInclude
    Author(s)   : D. Abdala
    Created     : Thu Aug 30 08:06:31 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.Documento:
  DEFINE PROTECTED STATIC TEMP-TABLE cttCompresores NO-UNDO
    FIELD chNombreMetodo AS CHARACTER
    FIELD chClase AS CHARACTER
    FIELD obCompresor AS Progress.Lang.Object
  {&END}  
  
  DEFINE STATIC PUBLIC PROPERTY cdeVersionPDf AS DECIMAL INITIAL 3.3 NO-UNDO
    GET.
    
  METHOD PROTECTED STATIC VOID registrarCompresores():
    DEFINE VARIABLE mifCompresor AS pdf.compresores.ICompresor NO-UNDO.
    DEFINE VARIABLE mchFileName AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchFullName AS CHARACTER NO-UNDO.
    
    FOR EACH cttCompresores:
      RETURN.
    END.
    /* no hay ningún compresor registrado, buscar y registrar */
    INPUT FROM OS-DIR('pdf/compresores') NO-ATTR-LIST.
    REPEAT ON ENDKEY UNDO, LEAVE ON ERROR UNDO, NEXT:
      IMPORT mchFileName mchFullName.
      IF INDEX(mchFileName,'.cls') EQ 0 THEN
        NEXT.
      IF mchFileName EQ 'ICompresor.cls' THEN
        NEXT.
      mifCompresor = ?.
      SUBSTRING(mchFileName,LENGTH(mchFileName) - 3,4) = ''. 
      mifCompresor = DYNAMIC-NEW('pdf.compresores.' + mchFileName)() NO-ERROR.
      IF VALID-OBJECT(mifCompresor) THEN DO:
        IF TYPE-OF(mifCompresor,pdf.compresores.ICompresor) THEN DO:
          CREATE cttCompresores.
          ASSIGN
            cttCompresores.chNombreMetodo = mifCompresor:cchNombreMetodo
            cttCompresores.chClase = 'pdf.compresores.' + mchFileName
            cttCompresores.obCompresor = mifCompresor
          {&END}
        END.
        ELSE
          DELETE OBJECT mifCompresor NO-ERROR.
      END.
    END.
    INPUT CLOSE.
  END METHOD.
  
  DEFINE PUBLIC PROPERTY cchIdentificador AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
     
  /*$
  Eventos disparados por la clase, para poder personalizar la generación del documento.
  $*/
  DEFINE PUBLIC EVENT CabeceraDePagina VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT InicioDePagina VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT PieDePagina VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT FinDePagina VOID (INPUT ipobDocumento AS pdf.Documento).
    
  /*$
  eventos durante la generación del PDF
  $*/
  DEFINE PUBLIC EVENT InicioDocumento VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT InicioPagina VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT FinPagina VOID (INPUT ipobDocumento AS pdf.Documento).
  DEFINE PUBLIC EVENT FinDocumento VOID (INPUT ipobDocumento AS pdf.Documento).
  
  DEFINE PUBLIC PROPERTY clgSaltoDePaginaAutomatico AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
  
/*-- estado actual del documento --*/  
  DEFINE PUBLIC PROPERTY clgTerminado AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clgReemplazarMarcadores AS LOGICAL NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinRotacion AS INTEGER NO-UNDO INITIAL 0
    GET.
    SET.
  DEFINE PUBLIC PROPERTY clgEnPieDePagina AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY clgEnCabeceraDePagina AS LOGICAL NO-UNDO
    GET.
    PROTECTED SET.      
  
  DEFINE PUBLIC PROPERTY cobPermisos AS pdf.utiles.Permisos NO-UNDO
    GET.
    PRIVATE SET.
  
/*-- gestión de tipos de letras --*/
  DEFINE PUBLIC PROPERTY cobLetraActual AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetraNormal AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetraNegrita AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetraCursiva AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetraNegritaCursiva AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED TEMP-TABLE cttDocumentoExterno NO-UNDO
    FIELD obDocumento AS Progress.Lang.Object.
    
  DEFINE PRIVATE PROPERTY cinSiguienteFuente AS INTEGER NO-UNDO INITIAL 0
    GET:
      cinSiguienteFuente = cinSiguienteFuente + 1.
      RETURN cinSiguienteFuente.
    END.
    SET.
  DEFINE PROTECTED TEMP-TABLE cttFuente NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chNombre AS CHARACTER
    FIELD obFuente AS Progress.Lang.Object
  {&END}

/*-- destino de generación del PDf, si no se especifica uno, se almacena en un LONGCHAR --*/
  DEFINE PUBLIC PROPERTY cobDestino AS pdf.destinos.IDestino NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cobDestino) THEN DO:
        cobDestino = NEW pdf.destinos.Cadena().
      END.
      RETURN cobDestino.
    END GET.
    SET.
          
/*-- propiedades del documento PDF --*/
  DEFINE PUBLIC PROPERTY cobModoDeVisualizacion AS pdf.utiles.ModoVisualizacion NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobDisposicionDePagina AS pdf.utiles.DisposicionDePagina NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobPreferencias AS pdf.utiles.PreferenciasDeVisualizacion NO-UNDO
    GET.
    PRIVATE SET.    
  DEFINE PUBLIC PROPERTY cchAutor AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchAutor = escaparTexto(ipchValor).
    END SET.
  DEFINE PUBLIC PROPERTY cchCreador AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchCreador = escaparTexto(ipchValor).
    END SET.
  DEFINE PUBLIC PROPERTY cchProductor AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchProductor = escaparTexto(ipchValor).
    END SET.
  DEFINE PUBLIC PROPERTY cchPalabrasClave AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchPalabrasClave = escaparTexto(ipchValor).
    END SET.
  DEFINE PUBLIC PROPERTY cchAsunto AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchAsunto = escaparTexto(ipchValor).
    END SET.
  DEFINE PUBLIC PROPERTY cchTitulo AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchValor AS CHARACTER):
      cchTitulo = escaparTexto(ipchValor).
    END SET.
      
  DEFINE PUBLIC PROPERTY cobCompresor AS pdf.compresores.ICompresor NO-UNDO
    GET.
    SET(INPUT ipobCompresor AS pdf.compresores.ICompresor):
      IF NOT cobDestino:clgAceptaBinario THEN
        RETURN.
      cobCompresor = ipobCompresor.
    END SET. 
  DEFINE PUBLIC PROPERTY cobEncriptador AS pdf.encriptadores.IEncriptador NO-UNDO
    GET.
    SET(INPUT ipobEncriptador AS pdf.encriptadores.IEncriptador):
      IF NOT cobDestino:clgAceptaBinario THEN
        RETURN.
      cobEncriptador = ipobEncriptador.
    END SET.
           
  DEFINE PUBLIC PROPERTY cdeEscalaEnX AS DECIMAL INITIAL 1 NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cdeEscalaEnY AS DECIMAL INITIAL 1 NO-UNDO
    GET.
    SET.
    
  /* un elemento vacío se reemplaza por ',' */
  DEFINE PUBLIC PROPERTY cchSeparadoresPalabra AS CHARACTER INITIAL ', ,-,;,~),~(,.,~[,~]' NO-UNDO
    GET.
    SET.
  
/*-- gestión de enlaces --*/
  DEFINE PROTECTED PROPERTY cinSiguienteEnlace AS INTEGER INITIAL 0 NO-UNDO
    GET:
      cinSiguienteEnlace = cinSiguienteEnlace + 1.
      RETURN cinSiguienteEnlace.
    END GET.
    SET.
  DEFINE PROTECTED TEMP-TABLE cttEnlace NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD obEnlace AS Progress.Lang.Object
  {&END}

/*-- gestión de objetos PDF --*/    
  DEFINE PROTECTED PROPERTY cinSiguienteObjeto AS INTEGER NO-UNDO INITIAL 5 /* Se crean con número del 1 al 4 algunos objetos "especiales" */
    GET.
    PRIVATE SET.
  DEFINE PROTECTED TEMP-TABLE cttObjeto NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chTipo AS CHARACTER
    FIELD dePosicion AS DECIMAL DECIMALS 0 FORMAT "9999999999"
    FIELD inGeneracion AS INTEGER FORMAT "99999"
    FIELD chTipoPDF AS CHARACTER FORMAT "X"
    INDEX ixObjeto IS PRIMARY IS UNIQUE inNumero
  {&END}
    /*$
    Crea un nuevo objeto PDF, del tipo especificado. Devuelve el número de objeto.
    $*/
    METHOD PUBLIC INTEGER crearObjeto(INPUT ipchTipo AS CHARACTER):
      RETURN crearObjeto(ipchTipo,cinSiguienteObjeto).
    END METHOD.
    METHOD PROTECTED INTEGER crearObjeto(INPUT ipchTipo AS CHARACTER,INPUT ipinNumero AS INTEGER):
      CREATE cttObjeto.
      ASSIGN
        cttObjeto.inNumero = ipinNumero
        cttObjeto.chTipo = ipchTipo
        cttObjeto.dePosicion = IF ipinNumero NE 0 THEN cobDestino:Posicion() + 1 ELSE 0
        cttObjeto.inGeneracion = IF ipinNumero NE 0 THEN 0 ELSE 65535
        cttObjeto.chTipoPDF = IF ipinNumero EQ 0 THEN "f" ELSE "n"
      {&END}
      IF ipinNumero GE cinSiguienteObjeto THEN
        cinSiguienteObjeto = ipinNumero + 1.
      RETURN ipinNumero.
    END METHOD.
    METHOD PUBLIC VOID inicioObjeto(INPUT ipobHijo AS pdf.IObjetoPDF, INPUT ipinObjeto AS INTEGER):
      IF ipobHijo:cobDocumento NE THIS-OBJECT THEN DO:
        DEFINE VARIABLE mlgEsHijo AS LOGICAL INITIAL FALSE NO-UNDO.
        FOR EACH cttDocumentoExterno:
          mlgEsHijo = cttDocumentoExterno.obDocumento EQ ipobHijo:cobDocumento.
          IF mlgEsHijo THEN
            LEAVE.
        END.
        IF NOT mlgEsHijo THEN
          RETURN.
      END.
      FIND cttObjeto WHERE cttObjeto.inNumero EQ ipinObjeto.
      cttObjeto.dePosicion = cobDestino:Posicion() + 1.
      cobDestino:agregar(STRING(ipinObjeto) + " " + STRING(cttObjeto.inGeneracion) + " obj" + {&pdfSKIP}).
    END METHOD.

/*-- referencias a objetos puntuales del PDF --*/      
  DEFINE PROTECTED PROPERTY cinObjetoRecursos AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cinObjetoPaginas AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PROTECTED PROPERTY cinCatalogoDeMarcasDeLectura AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PROTECTED PROPERTY cinCatalogoDeEncriptacion AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.

/*-- gestión de páginas --*/    
  DEFINE PUBLIC PROPERTY cobPaginaActual AS pdf.Pagina NO-UNDO
    GET.
    PROTECTED SET.
  DEFINE PUBLIC PROPERTY cobMargenes AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cinAltoPieDePagina AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinAltoCabeceraDePagina AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinAltoDePagina AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinAnchoDePagina AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cenOrientacion AS pdf.tipos.Orientacion NO-UNDO 
    GET:
      IF NOT VALID-OBJECT(cenOrientacion) THEN DO:
        cenOrientacion = NEW pdf.tipos.Orientacion().
        cenOrientacion:Cambio:Subscribe(CambioOrientacion).
      END.
      RETURN cenOrientacion.
    END GET.
    PRIVATE SET(INPUT ipenOrientacion AS pdf.tipos.Orientacion):
      IF ipenOrientacion EQ ? THEN
        DELETE OBJECT ipenOrientacion NO-ERROR.
      cenOrientacion = ipenOrientacion.
    END SET.
    
  METHOD PROTECTED VOID CambioOrientacion(INPUT ipinValor AS pdf.tipos.ENUM):
    DEFINE VARIABLE minTemp AS INTEGER NO-UNDO.
    minTemp = cinAltoDePagina.
    cinAltoDePagina = cinAnchoDePagina.
    cinAnchoDePagina = minTemp.
  END METHOD.
  /*$
  establece las dimensiones de la página, en base al tipo de página y su orientación
  $*/
  DEFINE PUBLIC PROPERTY cenTipoDePapel AS pdf.tipos.Papel NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cenTipoDePapel) THEN DO:
        cenTipoDePapel = NEW pdf.tipos.Papel().
        cenTipoDePapel:Cambio:Subscribe(CambioTipoDePapel).
      END.
      RETURN cenTipoDePapel. 
    END GET.
    PRIVATE SET(INPUT ipenTipo AS pdf.tipos.Papel):
      IF ipenTipo EQ ? THEN
        DELETE OBJECT cenTipoDePapel NO-ERROR.
      cenTipoDePapel = ipenTipo.
    END SET.
  METHOD PROTECTED VOID CambioTipoDePapel(INPUT ipenValor AS pdf.tipos.ENUM):
    DEFINE VARIABLE L_option  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_width   AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_height  AS INTEGER NO-UNDO.

    /* Determine the Paper Height and Width */
    CASE ipenValor:cinValor:
      WHEN pdf.tipos.Papel:A0 THEN
        ASSIGN L_width  = 2380
               L_height = 3368.
      WHEN pdf.tipos.Papel:A1 THEN
        ASSIGN L_width  = 1684
               L_height = 2380.
      WHEN pdf.tipos.Papel:A2 THEN
        ASSIGN L_width  = 1190
               L_height = 1684.
      WHEN pdf.tipos.Papel:A3 THEN
        ASSIGN L_width  = 842
               L_height = 1190.
      WHEN pdf.tipos.Papel:A4 THEN
        ASSIGN L_width  = 595
               L_height = 842.
      WHEN pdf.tipos.Papel:A5 THEN
        ASSIGN L_width  = 421
               L_height = 595.
      WHEN pdf.tipos.Papel:A6 THEN
        ASSIGN L_width  = 297
               L_height = 421.
      WHEN pdf.tipos.Papel:B5 THEN
        ASSIGN L_width  = 501
               L_height = 709.
      WHEN pdf.tipos.Papel:Legal THEN
        ASSIGN L_width  = 612
               L_height = 1008.
      WHEN pdf.tipos.Papel:Ledger THEN
        ASSIGN L_width  = 1224
               L_height = 792.
      OTHERWISE /* pdf.utiles.tipos.Papel:Letter */
        ASSIGN L_width  = 612
               L_height = 792.
    END CASE.

    /* Now Set the Page Height and Width Parameters */
    IF cenOrientacion:cinValor EQ pdf.tipos.Orientacion:Vertical THEN DO:
      cinAnchoDePagina = L_width.
      cinAltoDePagina = L_height.
    END.
    ELSE DO:
      cinAnchoDePagina = L_height.
      cinAltoDePagina = L_width.
    END.
  END METHOD.
    
  DEFINE PRIVATE PROPERTY cinSiguientePagina AS INTEGER NO-UNDO INITIAL 0
    GET:
      cinSiguientePagina = cinSiguientePagina + 1.
      RETURN cinSiguientePagina.
    END GET.
    SET.
  DEFINE PROTECTED TEMP-TABLE cttPagina NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD obPagina AS Progress.Lang.Object
  {&END}
  DEFINE PUBLIC PROPERTY cchMarcaTotalPaginas AS CHARACTER INITIAL "@@TOTALPages" NO-UNDO
    GET.
    SET(INPUT ipchNuevaMarca AS CHARACTER):
      IF ipchNuevaMarca EQ cchMarcaTotalPaginas THEN
        RETURN.
      FOR EACH cttPagina:
        CAST(cttPagina.obPagina,pdf.Pagina):ReemplazarTexto(cchMarcaTotalPaginas,ipchNuevaMarca).
      END.
      cchMarcaTotalPaginas = ipchNuevaMarca.
    END SET.
    
  DEFINE PUBLIC PROPERTY cchMarcaNumeroDePagina AS CHARACTER INITIAL "@@PAGEno" NO-UNDO
    GET.
    SET(INPUT ipchNuevaMarca AS CHARACTER):
      IF ipchNuevaMarca EQ cchMarcaNumeroDePagina THEN
        RETURN.
      FOR EACH cttPagina:
        CAST(cttPagina.obPagina,pdf.Pagina):ReemplazarTexto(cchMarcaNumeroDePagina,ipchNuevaMarca).
      END.
      cchMarcaNumeroDePagina = ipchNuevaMarca.
    END SET.
  DEFINE PUBLIC PROPERTY cinTotalPaginas AS INTEGER NO-UNDO
    GET:
      DEFINE BUFFER mbfPaginas FOR cttPagina.
      FOR EACH mbfPaginas BY mbfPaginas.inNumero DESC:
        RETURN mbfPaginas.inNumero.
      END.
      RETURN 0.
    END GET.
  DEFINE PUBLIC PROPERTY cinPaginaActual AS INTEGER NO-UNDO
    GET:
      IF VALID-OBJECT(cobPaginaActual) THEN
        RETURN cobPaginaActual:cinNumero.
      RETURN 0.
    END GET.  
    SET(INPUT ipinPagina AS INTEGER):
      DEFINE BUFFER mbfPaginas FOR cttPagina.
      IF VALID-OBJECT(cobPaginaActual) AND cobPaginaActual:cinNumerO EQ ipinPagina THEN
        RETURN.
      IF VALID-OBJECT(cobPaginaActual) THEN
        cobPaginaActual:Finalizar().
      DO WHILE ipinPagina  GT cinTotalPaginas:
        AgregarPagina().
      END.
      FIND mbfPaginas WHERE mbfPaginas.inNumero EQ ipinPagina.
      cobPaginaActual = CAST(mbfPaginas.obPagina,pdf.Pagina).
      IF cobPaginaActual:clgTerminada THEN  
        cobPaginaActual:reactivar().
    END SET.
    
    METHOD PROTECTED VOID ProcesarPieDePagina():
      clgEnPieDePagina = TRUE.
      PieDePagina:Publish(THIS-OBJECT).
      FINALLY:
        clgEnPieDePagina = FALSE.
      END.
    END METHOD.
    METHOD PROTECTED VOID ProcesarCabeceraDePagina():
      clgEnCabeceraDePagina = TRUE.
      CabeceraDePagina:Publish(THIS-OBJECT).
      FINALLY:
        clgEnCabeceraDePagina = FALSE.
      END FINALLY.
    END METHOD.
  /*$
  devuelve un objeto de compresión de los registrados
  $*/
  METHOD PUBLIC pdf.compresores.ICompresor compresorRegistrado(INPUT ipchNombreMetodo AS CHARACTER):
    FOR EACH cttCompresores WHERE cttCompresores.chNombreMetodo EQ ipchNombreMetodo:
      RETURN CAST(cttCompresores.obCompresor,pdf.compresores.ICompresor).
    END.
    RETURN ?.
  END METHOD.
  
  /*$
  agrega una página al documento, finalizando la página actual
  $*/
  METHOD PUBLIC pdf.Pagina AgregarPagina():
    RETURN AgregarPagina(?).
  END METHOD.
  METHOD PUBLIC pdf.Pagina AgregarPagina(INPUT ipobCopiar AS pdf.Pagina):
    DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
    IF VALID-OBJECT(cobPaginaActual) THEN
      finalizarPagina().
    CREATE cttPagina.
    ASSIGN
      mobPagina = NEW pdf.Pagina(THIS-OBJECT) WHEN ipobCopiar EQ ?
      mobPagina = NEW pdf.Pagina(THIS-OBJECT,ipobCopiar) WHEN ipobCopiar NE ?
      cttPagina.inNumero = cinSiguientePagina
      cttPagina.obPagina = mobPagina
      mobPagina:cinNumero = cttPagina.inNumero
    {&END}
    RETURN mobPagina.
    FINALLY:
      cobPaginaActual = mobPagina.
      IniciarPagina().
    END FINALLY.
  END METHOD.
  METHOD PUBLIC pdf.Pagina InsertarPagina(INPUT ipinDonde AS INTEGER, INPUT iplgDespues AS LOGICAL):
    RETURN InsertarPagina(ipinDonde,iplgDespues,?).
  END METHOD.
  METHOD PUBLIC pdf.Pagina InsertarPagina(INPUT ipinDonde AS INTEGER, INPUT iplgDespues AS LOGICAL, INPUT ipobCopiar AS pdf.Pagina):
    DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
    IF VALID-OBJECT(cobPaginaActual) THEN
      finalizarPagina().
    FOR EACH cttPagina:
      mobPagina = CAST(cttPagina.obPagina,pdf.Pagina).
      IF mobPagina:cinNumero GT ipinDonde THEN
        mobPagina:cinNumero = mobPagina:cinNumero + 1.
      ELSE IF NOT iplgDespues AND mobPagina:cinNumero EQ ipinDonde THEN
        mobPagina:cinNumero = mobPagina:cinNumero + 1.        
    END.
    CREATE cttPagina.
    ASSIGN
      cttPagina.inNumero = cinSiguientePagina
      mobPagina = NEW pdf.Pagina(THIS-OBJECT) WHEN ipobCopiar EQ ?
      mobPagina = NEW pdf.Pagina(THIS-OBJECT,ipobCopiar) WHEN ipobCopiar NE ?
      cttPagina.obPagina = mobPagina
      mobPagina:cinNumero = (IF iplgDespues THEN ipinDonde + 1 ELSE ipinDonde)
    {&END}
    RETURN mobPagina.
    FINALLY:
      cobPaginaActual = mobPagina.
      IniciarPagina().
    END FINALLY.    
  END METHOD.  
  /*$
  Finaliza la página actual.
  $*/  
  METHOD PUBLIC LOGICAL finalizarPagina():
    IF cobPaginaActual:clgTerminada THEN DO:
      cobPaginaActual:Finalizar().
      RETURN FALSE.
    END.
    cobPaginaActual:Finalizar().
    FinDePagina:Publish(THIS-OBJECT).
    cobPaginaActual:Pie:Unsubscribe(ProcesarPieDePagina).
    cobPaginaActual:Cabecera:Unsubscribe(ProcesarCabeceraDePagina).
    RETURN TRUE.
  END METHOD.
  /*$
  Inicia la página actual
  $*/
  METHOD PUBLIC LOGICAL iniciarPagina():
    cobPaginaActual:Cabecera:Subscribe(ProcesarCabeceraDePagina).
    cobPaginaActual:Pie:Subscribe(ProcesarPieDePagina).
    cobPaginaActual:iniciar().
    InicioDePagina:Publish(THIS-OBJECT).
  END METHOD.
    
/*-- gestión de colores --*/    
    DEFINE PROTECTED TEMP-TABLE cttColores NO-UNDO
      FIELD chNombre AS CHARACTER
      FIELD obColor AS Progress.Lang.Object
      FIELD chRGB AS CHARACTER INITIAL '0,0,0'
    {&END}
    DEFINE PUBLIC PROPERTY cobColorTexto AS pdf.utiles.Color NO-UNDO
      GET.
      PRIVATE SET.
    DEFINE PUBLIC PROPERTY cobColorRelleno AS pdf.utiles.Color NO-UNDO
      GET.
      PRIVATE SET.
    DEFINE PUBLIC PROPERTY cobColorPincel AS pdf.utiles.Color NO-UNDO
      GET.
      PRIVATE SET.
    METHOD PUBLIC CHARACTER definicionColor(INPUT ipchNombre AS CHARACTER):
      FIND cttColores WHERE cttColores.chNombre EQ ipchNombre NO-ERROR.
      IF NOT AVAILABLE cttColores THEN
        RETURN '0,0,0'.
      RETURN cttColores.chRGB.
    END METHOD.
    METHOD PUBLIC CHARACTER definicionColor(INPUT ipchNombre AS CHARACTER, INPUT ipinR AS DECIMAL, INPUT ipinG AS DECIMAL, INPUT ipinB AS DECIMAL):
      FIND cttColores WHERE cttColores.chNombre EQ ipchNombre NO-ERROR.
      IF NOT AVAILABLE cttColores THEN DO:
        CREATE cttColores.
        cttColores.chNombre = ipchNombre.
        cttColores.obColor = NEW pdf.utiles.Color().
      END.
      cttColores.chRGB = STRING(ipinR) + ',' + STRING(ipinG) + ',' + STRING(ipinB).
      CAST(cttColores.obColor,pdf.utiles.Color):desdeCadena(cttColores.chRGB).
      RETURN cttColores.chRGB.
    END METHOD.
    METHOD PUBLIC pdf.utiles.Color colorDefinido(INPUT ipchNombre AS CHARACTER):
      FIND cttColores WHERE cttColores.chNombre EQ ipchNombre NO-ERROR.
      IF NOT AVAILABLE cttColores THEN
        RETURN ?.
      RETURN CAST(cttColores.obColor,pdf.utiles.Color).      
    END METHOD.
    
/*-- gestión de marcas de lectura --*/
  DEFINE PROTECTED PROPERTY cinSiguienteMarcaDeLectura AS INTEGER INITIAL 0 NO-UNDO
    GET:
      cinSiguienteMarcaDeLectura = cinSiguienteMarcaDeLectura + 1.
      RETURN cinSiguienteMarcaDeLectura.
    END GET.
    PRIVATE SET.
  DEFINE PROTECTED TEMP-TABLE cttBookmark NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chNombre AS CHARACTER
    FIELD obMarca AS Progress.Lang.Object
    FIELD lgEsRaiz AS LOGICAL
    INDEX ixBookmark IS PRIMARY IS UNIQUE inNumero
  {&END}
  
    METHOD PUBLIC INTEGER agregarMarcaDeLectura(INPUT  ipobMarca AS pdf.utiles.MarcaDeLectura):
      DEFINE BUFFER B_TT_pdf_bookmark FOR cttBookmark.

      CREATE B_TT_pdf_bookmark.
      ASSIGN
             B_TT_pdf_bookmark.inNumero    = cinSiguienteMarcaDeLectura
             B_TT_pdf_bookmark.chNombre = ipobMarca:cchTitulo
             B_TT_pdf_bookmark.obMarca = ipobMarca
             B_TT_pdf_bookmark.lgEsRaiz = NOT VALID-OBJECT(ipobMarca:cobPadre)
      {&END}
      RETURN B_TT_pdf_bookmark.inNumero.
    END METHOD.
    METHOD PUBLIC pdf.utiles.MarcaDeLectura marcaDeLecturaRegistrada(INPUT ipinNumero AS INTEGER):
      FOR EACH cttBookmark WHERE cttBookmark.inNumero EQ ipinNumero:
        RETURN CAST(cttBookmark.obMarca,pdf.utiles.MarcaDeLectura).
      END.
      RETURN ?. 
    END METHOD.
    METHOD PUBLIC pdf.utiles.MarcaDeLectura marcaDeLecturaRegistrada(INPUT ipchNombre AS CHARACTER):
      RETURN marcaDeLecturaRegistrada(ipchNombre,cobPaginaActual:cinNumero). 
    END METHOD.
    METHOD PUBLIC pdf.utiles.MarcaDeLectura marcaDeLecturaRegistrada(INPUT ipchNombre AS CHARACTER, INPUT ipinPagina AS INTEGER):
      DEFINE VARIABLE mobMarca AS pdf.utiles.MarcaDeLectura NO-UNDO.
      FOR EACH cttBookmark WHERE cttBookmark.chNombre EQ ipchNombre:
        mobMarca = CAST(cttBookmark.obMarca,pdf.utiles.MarcaDeLectura).
        IF mobMarca:cobPagina:cinNumero EQ ipinPagina THEN 
          RETURN mobMarca. 
      END.
      RETURN ?. 
    END METHOD.
    METHOD PUBLIC INTEGER marcaDeLecturaRegistrada(INPUT ipobMarca AS pdf.utiles.MarcaDeLectura):
      FOR EACH cttBookmark WHERE cttBookmark.obMarca EQ ipobMarca:
        RETURN cttBookmark.inNumero.
      END.
      RETURN 0. 
    END METHOD.
    DEFINE PUBLIC PROPERTY cinCantidadMarcasDeLectura AS INTEGER NO-UNDO
      GET:
        DEFINE BUFFER mbfMarca FOR cttBookmark.
        FOR EACH mbfMarca BY mbfMarca.inNumero DESC:
          RETURN mbfMarca.inNumero.
        END.
        RETURN 0.
      END GET.


/*-- gestión de imágenes --*/
  DEFINE PRIVATE PROPERTY cinSiguienteImagen AS INTEGER NO-UNDO INITIAL 0
    GET:
      cinSiguienteImagen = cinSiguienteImagen + 1.
      RETURN cinSiguienteImagen.
    END.
    SET.
  DEFINE PROTECTED TEMP-TABLE cttImagen NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chNombre AS CHARACTER
    FIELD obImagen AS Progress.Lang.Object
  {&END}
  /*$
  agrega una imagen al PDF
  $*/
  METHOD PUBLIC INTEGER agregarImagen(INPUT ipobImagen AS pdf.imagenes.Imagen):
    FIND cttImagen WHERE cttImagen.chNombre EQ ipobImagen:cchNombre NO-ERROR.
    IF AVAILABLE cttImagen THEN
      RETURN 0.
    CREATE cttImagen.
    ASSIGN
      cttImagen.inNumero = cinSiguienteImagen
      cttImagen.chNombre = ipobImagen:cchNombre
      cttImagen.obImagen = ipobImagen
    {&END}
    ipobImagen:asignarObjetoPDF().
    RETURN cttImagen.inNumero.
  END METHOD.
  /*$
  devuelve una de las imágenes registradas en el documento
  $*/
  METHOD PUBLIC pdf.imagenes.Imagen imagenRegistrada(INPUT ipchNombre AS CHARACTER):
    FIND cttImagen WHERE cttImagen.chNombre EQ ipchNombre NO-ERROR.
    IF NOT AVAILABLE cttImagen THEN
      RETURN ?.
    RETURN CAST(cttImagen.obImagen,pdf.imagenes.Imagen).
  END METHOD.
  /*$
  devuelve la imagen registrada indicada
  $*/
  METHOD PUBLIC pdf.imagenes.Imagen imagenRegistrada(INPUT ipinNumero AS INTEGER):
    FIND cttImagen WHERE cttImagen.inNumero EQ ipinNumero NO-ERROR.
    IF NOT AVAILABLE cttImagen THEN
      RETURN ?.
    RETURN CAST(cttImagen.obImagen,pdf.imagenes.Imagen).
  END METHOD. 
  /*$
  devuelve la cantidad de imágenes registradas
  $*/
  DEFINE PUBLIC PROPERTY cinCantidadImagenes AS INTEGER NO-UNDO
    GET:
      DEFINE BUFFER mbfImg FOR cttImagen.
      FOR EACH mbfImg BY mbfImg.inNumero DESC:
        RETURN mbfImg.inNumero.
      END.
      RETURN 0.
    END GET.
/*-- gestión de tipos de letras --*/
  /*$
  devuelve la cantidad de letras definidas en el documento
  $*/
  DEFINE PUBLIC PROPERTY cinCantidadLetras AS INTEGER NO-UNDO
    GET:
      DEFINE BUFFER mbfFuente FOR cttFuente.
      FOR EACH mbfFuente BY mbfFuente.inNumero DESC:
        RETURN mbfFuente.inNumero.
      END.
      RETURN 0.
    END GET. 
  /*$
  devuelve el tipo de letra solicitado
  $*/
  METHOD PUBLIC pdf.letras.TipoDeLetra TipoDeLetraDefinido(INPUT ipinNumero AS INTEGER):
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    FIND cttFuente WHERE cttFuente.inNumero EQ ipinNumero NO-ERROR.
    IF NOT AVAILABLE cttFuente THEN
      RETURN ?.
    mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
    RETURN mobFuente.
  END METHOD.
  /*$
  Cambia el tipo de letra actual para el documento
  $*/
  METHOD PUBLIC pdf.letras.TipoDeLetra TipoDeLetraDefinido(INPUT ipchLetra AS CHARACTER):
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    FIND cttFuente WHERE cttFuente.chNombre EQ ipchLetra NO-ERROR.
    IF NOT AVAILABLE cttFuente THEN DO:
      FOR EACH cttFuente:
        mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
        IF mobFuente:cchNombre EQ ipchLetra THEN
          RETURN mobFuente.
      END.
      RETURN ?.
    END.
    mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
    RETURN mobFuente.
  END METHOD.
  /*$
  Registra los 14 tipos de letra estándar de PDF
  $*/
  METHOD PROTECTED VOID CargarLetrasEstandar():
    DEFINE VARIABLE minCual AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    DO WHILE minCual LT 14:
      CREATE cttFuente.
      ASSIGN
        minCual = cinSiguienteFuente
        cttFuente.inNumero = minCual
        mobFuente = NEW pdf.letras.TipoDeLetraEstandar(THIS-OBJECT,minCual)
        cttFuente.obFuente = mobFuente
        cttFuente.chNombre = mobFuente:cchNombreOriginal
      {&END}
      mobFuente:asignarObjetoPDF().
    END.
  END METHOD.
  /*$
  registra un tipo de letra particular
  $*/
  METHOD PUBLIC LOGICAL RegistrarTipoDeLetra(INPUT ipobLetra AS pdf.letras.TipoDeLetra):
    FIND cttFuente WHERE cttFuente.chNombre EQ ipobLetra:cchNombreOriginal NO-ERROR.
    IF AVAILABLE cttFuente THEN
      RETURN FALSE.
    CREATE cttFuente.
    ASSIGN
      cttFuente.inNumero = cinSiguienteFuente
      cttFuente.chNombre = ipobLetra:cchNombreOriginal
      cttFuente.obFuente = ipobLetra
    {&END}
  END METHOD.
  /*$
  determina si el tipo de letra ya ha sido registrado
  $*/
  METHOD PUBLIC LOGICAL TipoDeLetraDisponible(INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    FIND cttFuente WHERE cttFuente.chNombre EQ ipchNombre NO-ERROR.
    IF NOT AVAILABLE cttFuente THEN DO:
      FOR EACH cttFuente:
        mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
        IF mobFuente:cchNombre EQ ipchNombre THEN
          RETURN TRUE.
      END.
      RETURN FALSE.
    END.
    RETURN TRUE.
  END METHOD.
  
  /*$
  si se especifica la ruta a un documento existente, entonces se carga completo, sino se inicia un nuevo documento
  $*/
  CONSTRUCTOR PUBLIC Documento():
    cargarLetrasEstandar().
    establecerValoresEstandar().
    registrarCompresores().
  END CONSTRUCTOR.
  
  DESTRUCTOR Documento():
    FOR EACH cttColores:
      DELETE OBJECT obColor NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttColores.
    FOR EACH cttFuente:
      DELETE OBJECT cttFuente.obFuente NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttFuente.
    FOR EACH cttImagen:
      DELETE OBJECT cttImagen.obImagen NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttImagen.
    FOR EACH cttBookmark:
      DELETE OBJECT cttBookmark.obMarca NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttBookmark.
    FOR EACH cttEnlace:
      DELETE OBJECT cttEnlace.obEnlace NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttEnlace.    
    FOR EACH cttPagina:
      DELETE OBJECT cttPagina.obPagina NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttPagina.
    DELETE OBJECT cobColorTexto NO-ERROR.
    DELETE OBJECT cobColorPincel NO-ERROR.
    DELETE OBJECT cobColorRelleno NO-ERROR.
    DELETE OBJECT cobLetraNormal NO-ERROR.    
    DELETE OBJECT cobLetraNegrita NO-ERROR.    
    DELETE OBJECT cobLetraCursiva NO-ERROR.    
    DELETE OBJECT cobLetraNegritaCursiva NO-ERROR.    
    DELETE OBJECT cobLetraActual NO-ERROR.    
    DELETE OBJECT cobModoDeVisualizacion NO-ERROR.
    DELETE OBJECT cobDisposicionDePagina NO-ERROR.
    DELETE OBJECT cobPreferencias NO-ERROR.
    DELETE OBJECT cobPermisos NO-ERROR.
    cenOrientacion = ?.
    cenTipoDePapel = ?.
  END DESTRUCTOR.
  
  METHOD PROTECTED VOID establecerValoresEstandar():
    cenOrientacion:cinValor = pdf.tipos.Orientacion:Vertical.
    cobMargenes = NEW pdf.utiles.Area().
    cobMargenes:cinIzquierda = 10.
    cobMargenes:cinDerecha = 10.
    cobMargenes:cinArriba = 10.
    cobMargenes:cinAbajo = 10.
    cobLetraNormal = NEW pdf.letras.TipoDeLetraDocumento(THIS-OBJECT).
    cobLetraNegrita = NEW pdf.letras.TipoDeLetraDocumento(THIS-OBJECT).
    cobLetraCursiva = NEW pdf.letras.TipoDeLetraDocumento(THIS-OBJECT).
    cobLetraNegritaCursiva = NEW pdf.letras.TipoDeLetraDocumento(THIS-OBJECT).
    cobLetraActual = NEW pdf.letras.TipoDeLetraDocumento(THIS-OBJECT).
    cobLetraNormal:cchNombre = 'Courier'.
    cobLetraNormal:cdePuntos = 10.0.
    cobLetraNegrita:cchNombre = 'Courier-Bold'.
    cobLetraNegrita:cdePuntos = 10.0.
    cobLetraCursiva:cchNombre = 'Courier-Oblique'.
    cobLetraCursiva:cdePuntos = 10.0.
    cobLetraNegritaCursiva:cchNombre = 'Courier-BoldOblique'.
    cobLetraNegritaCursiva:cdePuntos = 10.0.
    cobLetraActual:Copiar(cobLetraNormal).
    definicionColor('Negro',0,0,0).
    definicionColor('Blanco',1,1,1).
    cobColorTexto = NEW pdf.utiles.Color().
    cobColorTexto:Copiar(colorDefinido('Negro')).
    cobColorRelleno = NEW pdf.utiles.Color().
    cobColorRelleno:Copiar(colorDefinido('Blanco')).
    cobColorPincel = NEW pdf.utiles.Color().
    cobColorPincel:Copiar(cobColorTexto).
    cenTipoDePapel:cinValor = pdf.tipos.Papel:A4.
    cinRotacion = 0.
    cobModoDeVisualizacion = NEW pdf.utiles.ModoVisualizacion().
    cobDisposicionDePagina = NEW pdf.utiles.DisposicionDePagina().
    cobPreferencias = NEW pdf.utiles.PreferenciasDeVisualizacion().
    cobPermisos = NEW pdf.utiles.Permisos().
  END METHOD.
  
  /*$
  termina la generación del PDf.
  $*/
  METHOD PUBLIC VOID terminar():
    IF clgTerminado THEN
      RETURN.
      
    finalizarPagina().

    InicioDocumento:Publish(THIS-OBJECT).
    /* Output PDF Header Requirements */
    generarCabecera().

    /* Load 12 Base Fonts - exclude wingdings etc */
    generarCodificacion().

    generarLetrasEstandar().

    generarLetrasDocumento().
    generarImagenesDocumento().

    generarElementosExternos().

    generarEnlacesDocumento().
    
    IF VALID-OBJECT(cobEncriptador) THEN DO:
      cobEncriptador:generarDiccionario().
      cinCatalogoDeEncriptacion = CAST(cobEncriptador,pdf.IObjetoPDF):cinObjetoPDf.
    END.

    generarRecursos().
    generarContenido().
    generarXref().

    FinDocumento:Publish(THIS-OBJECT).
    FINALLY:
      clgTerminado = TRUE.
    END FINALLY.
  END METHOD.
  
  METHOD PROTECTED VOID generarElementosExternos():
    FOR EACH cttDocumentoExterno:
      CAST(cttDocumentoExterno.obDocumento,pdf.DocumentoExistente):generarElementosExternos(THIS-OBJECT).
    END.
  END METHOD.
  
  METHOD PUBLIC VOID usarDocumento(INPUT ipobDocumento AS pdf.DocumentoExistente):
    CREATE cttDocumentoExterno.
    cttDocumentoExterno.obDocumento = ipobDocumento.
    copiarTiposDeLetra(ipobDocumento).
    copiarImagenes(ipobDocumento).
  END METHOD.
  
  METHOD PUBLIC pdf.Pagina agregarPaginaExterna(INPUT ipobPagina AS pdf.PaginaExistente):
    DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
    
    mobPagina = agregarPagina(ipobPagina).
    mobPagina:usarXObject(ipobPagina:cchNombreXObject).
    mobPagina:copiarCampos(ipobPagina).
  END METHOD.
  
  METHOD PUBLIC VOID usarPaginaExterna(INPUT ipobPagina AS pdf.PaginaExistente):
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    
    cobPaginaActual:usarXObject(ipobPagina:cchNombreXObject).
    DO minIndex = 1 TO ipobPagina:cinCamposFormulario:
      cobPaginaActual:registrarCampoFormulario(ipobPagina:campoFormulario(minIndex)).
    END.
  END METHOD.

/*-- producción del documento PDF y envío al cobDestino --*/  
  METHOD PROTECTED VOID generarCabecera():
    DEFINE VARIABLE mchCreationDate  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchPDf AS CHARACTER NO-UNDO.

    /* Version Compatibilities */
    mchPDF = "%PDF-1.4" + {&pdfSKIP}.
    /* Output 4 Binary Characters (greater than ASCII 128) to indicate to a binary
       file -- randomly selected codes */
    mchPDF = mchPDF + "%" + CHR(228) + CHR(227) + CHR(207) + CHR(210) + {&pdfSKIP}.
    cobDestino:agregar(mchPDF).
    mchPDF = ''.

    crearObjeto("Info",1).
    /* Display Creation, Title, Producer etc Information */
    mchPDF = mchPDF + "1 0 obj" + {&pdfSKIP} + "<<" + {&pdfSKIP}.
    mchCreationDate = "D:" + TRIM(STRING(YEAR(TODAY),"9999"))
                 + TRIM(STRING(MONTH(TODAY),"99"))
                 + TRIM(STRING(DAY(TODAY),"99"))
                 + REPLACE(STRING(TIME,"hh:mm:ss"),":","") + "-0800".

    IF VALID-OBJECT(cobEncriptador) THEN DO:
      IF LENGTH(cchAutor, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Author <" +  cobEncriptador:encriptarAHex(1,cchAutor) + ">" + {&pdfSKIP}.
      mchPDF = mchPDF +  "/CreationDate<" + cobEncriptador:encriptarAHex(1,mchCreationDate) + ">" + {&pdfSKIP}.
      IF LENGTH(cchCreador, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Creator <" + cobEncriptador:encriptarAHex(1,cchCreador) + ">" + {&pdfSKIP}.
      IF LENGTH(cchProductor, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Producer <" + cobEncriptador:encriptarAHex(1,cchProductor) + ">" + {&pdfSKIP}.
      IF LENGTH(cchAsunto, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Subject <" + cobEncriptador:encriptarAHex(1,cchAsunto) + ">" + {&pdfSKIP}.
      IF LENGTH(cchTitulo, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Title <" + cobEncriptador:encriptarAHex(1,cchTitulo) + ">" + {&pdfSKIP}.
      IF LENGTH(cchPalabrasClave, "character":u) GT 0 THEN
        mchPDF = mchPDF +  "/Keywords <" + cobEncriptador:encriptarAHex(1,cchPalabrasClave) + ">" + {&pdfSKIP}.
    END. /* If Encrypted PDF */
    ELSE DO: /* Not Encrypted */
      mchPDf = mchPDF + "/Author (" + cchAutor + ")" + {&pdfSKIP}
        + "/CreationDate (" + mchCreationDate + ")" + {&pdfSKIP}
        + "/Producer (" + cchProductor + ")" + {&pdfSKIP}
        + "/Creator (" + cchCreador + ")" + {&pdfSKIP}
        + "/Subject (" + cchAsunto + ")" + {&pdfSKIP}
        + "/Title (" + cchTitulo + ")" + {&pdfSKIP}
        + "/Keywords (" + cchPalabrasClave + ")" + {&pdfSKIP}.
    END. /* Not Encrypted */

    cobDestino:agregar(mchPDF + " >>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
  END METHOD.
  
  METHOD PROTECTED VOID generarCodificacion():
    cobDestino:agregar(STRING(crearObjeto("Encoding",4)) + " 0 obj" + {&pdfSKIP}
      + "<<" + {&pdfSKIP}
      + "/Type /Encoding" + {&pdfSKIP}
      + "/BaseEncoding /WinAnsiEncoding" + {&pdfSKIP}
      + ">>" + {&pdfSKIP}
      + "endobj" + {&pdfSKIP}).
  END METHOD.

  METHOD PROTECTED CHARACTER letrasEnRecursos():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    DEFINE VARIABLE mchLetras AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mobDE AS pdf.DocumentoExistente NO-UNDO.
    DEFINE VARIABLE mobFE AS pdf.letras.TipoDeLetra NO-UNDO.
    /* los documentos externos ya fueron generados, por lo     
    que las letras externas ya tienen un identificador de objeto válido */
    FOR EACH cttFuente:
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
      IF TYPE-OF(mobFuente,pdf.letras.TipoDeLetraExterna) THEN DO:
        FOR EACH cttDocumentoExterno:
          mobDE = CAST(cttDocumentoExterno.obDocumento,pdf.DocumentoExistente).
          mobFE = mobDE:TipoDeLetraDefinido(mobFuente:cchNombre).
          IF VALID-OBJECT(mobFE) THEN DO:
            mchLetras = mchLetras + ' ' + mobFuente:cchNombreInterno + ' ' + STRING(mobFE:cinObjetoPDF) + ' 0 R'.
            LEAVE.
          END.
        END.
        NEXT.
      END.
      mobFuente:asignarObjetoPDF().
      mchLetras = mchLetras + " " + mobFuente:cchNombreInterno + " " + STRING(mobFuente:cinObjetoPDF) + " 0 R".
    END.
    RETURN mchLetras.
  END METHOD.
  
  METHOD PROTECTED VOID generarRecursos():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    DEFINE VARIABLE mchPDF AS CHARACTER NO-UNDO.

    cinObjetoRecursos = crearObjeto("Resource").
    mchPDf = STRING(cinObjetoRecursos) + " 0 obj" + {&pdfSKIP}
      + "<<" + {&pdfSKIP} + "  /Font << ".
    mchPDF = mchPDF + letrasEnRecursos().
    mchPDF = mchPDF + " >>" + {&pdfSKIP}
      + "  /ProcSet [ /PDF /Text /ImageB /ImageC /ImageI ]" + {&pdfSKIP}
      + "  /XObject << " + {&pdfSKIP}.
    cobDestino:agregar(mchPDF).

    generarXObjectRecursos().
    
    cobDestino:agregar(" >>" + {&pdfSKIP} + ">>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
  END METHOD.
  
  METHOD PROTECTED VOID generarXObjectRecursos():
    DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
    DEFINE VARIABLE mobDocumento AS pdf.DocumentoExistente NO-UNDO.
    /* Output Image Definitions */
    FOR EACH cttImagen:
      mobImagen = CAST(cttImagen.obImagen,pdf.imagenes.Imagen).
      cobDestino:agregar(mobImagen:cchNombreInterno + " " + STRING(mobImagen:cinObjetoPDF) + " 0 R " + {&pdfSKIP}).
    END.
    /* generar los XObjects de los documentos externos usados */
    FOR EACH cttDocumentoExterno:
      mobDocumento = CAST(cttDocumentoExterno.obDocumento,pdf.DocumentoExistente).
      mobDocumento:generarXObjectRecursos(THIS-OBJECT).
    END.
  END METHOD.
  
  METHOD PROTECTED VOID generarContenido():
    DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
    
    cinObjetoPaginas = crearObjeto("Pages",3).
    
    /* Produce each Page one at a time */
    FOR EACH cttPagina BY cttPagina.inNumero:
      InicioPagina:Publish(THIS-OBJECT).
      mobPagina = CAST(cttPagina.obPagina,pdf.Pagina).      
      mobPagina:generarPagina(cinObjetoPaginas,cinObjetoRecursos).
      FinPagina:Publish(THIS-OBJECT).
    END. /* loop for each page */

    /* Load Bookmarks */
    generarMarcasDeLectura().
    generarCatalogo().
    generarCatalogoDePaginas().
  END METHOD.
  
  METHOD PROTECTED VOID generarMarcasDeLectura():
    DEFINE BUFFER mbfSiguiente FOR cttBookmark.
    DEFINE VARIABLE pdf_OutlinesLast AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Last AS INTEGER NO-UNDO.
    DEFINE VARIABLE minSiguiente AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobMarca AS pdf.utiles.MarcaDeLectura NO-UNDO.
    
    FOR EACH cttBookmark BY cttBookmark.inNumero DESC:
      L_Last = cttBookmark.inNumero.
      LEAVE.
    END.
    /* verificar cuáles son raiz realmente */
    FOR EACH cttBookmark:
      mobMarca = CAST(cttBookmark.obMarca,pdf.utiles.MarcaDeLectura).
      cttBookmark.lgEsRaiz = NOT VALID-OBJECT(mobMarca:cobPadre).
    END.

    FOR EACH cttBookmark WHERE cttBookmark.lgEsRaiz BY cttBookmark.inNumero:
      cinCatalogoDeMarcasDeLectura = crearObjeto('BookMark').
      pdf_OutlinesLast = cinCatalogoDeMarcasDeLectura + L_Last.
      /* Output the Bookmark Dictionary */
      cobDestino:agregar(STRING(cinCatalogoDeMarcasDeLectura) + " 0 obj" + {&pdfSKIP}
          + "<< " + {&pdfSKIP} + "/Type /Outlines" + {&pdfSKIP}
          + "/First " + STRING(cinCatalogoDeMarcasDeLectura + 1) + " 0 R" + {&pdfSKIP}
          + "/Last " + STRING(pdf_OutlinesLast) + " 0 R" + {&pdfSKIP}
          + "/Count " + STRING(L_Last) + {&pdfSKIP}
          + ">>" + {&pdfSKIP}
          + "endobj" + {&pdfSKIP}).
      LEAVE.
    END.
    FOR EACH cttBookmark WHERE cttBookmark.lgEsRaiz BY cttBookmark.inNumero:
      mobMarca = CAST(cttBookmark.obMarca,pdf.utiles.MarcaDeLectura).
      mobMarca:asignarObjetoPDF().
    END.
    L_last = 0.
    FOR EACH cttBookmark WHERE cttBookmark.lgEsRaiz BY cttBookmark.inNumero:
      mobMarca = CAST(cttBookmark.obMarca,pdf.utiles.MarcaDeLectura).
      minSiguiente = 0.
      FOR EACH mbfSiguiente WHERE mbfSiguiente.lgEsRaiz AND mbfSiguiente.inNumero GT cttBookmark.inNumero BY mbfSiguiente.inNumero:
        minSiguiente = CAST(mbfSiguiente.obMarca,pdf.utiles.MarcaDeLectura):cinObjetoPDF.        
        LEAVE.
      END.
      mobMarca:generarRama(cinCatalogoDeMarcasDeLectura,L_last,minSiguiente).
      L_last = mobMarca:cinObjetoPDF.
    END. /* each cttBookmark */
  END METHOD.
  
  METHOD PROTECTED CHARACTER numeroOctal(INPUT ipinNumero AS INTEGER):
    DEFINE VARIABLE mchOctal AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minResto AS INTEGER NO-UNDO.
    DO WHILE ipinNumero GE 8:
      mchOctal = STRING(ipinNumero MODULO 8) + mchOctal.
      ipinNumero = INTEGER(TRUNCATE(ipinNumero / 8,0)).
    END.
    mchOctal = STRING(ipinNumero) + mchOctal.
    DO WHILE LENGTH(mchOctal) LT 3:
      mchOctal = '0' + mchOctal.
    END.
    RETURN mchOctal.
  END METHOD.
  METHOD PUBLIC CHARACTER escaparTexto(INPUT ipchTexto AS CHARACTER):
    DEFINE VARIABLE minChar AS INTEGER NO-UNDO.
    DEFINE VARIABLE minAsc AS INTEGER NO-UNDO.
    /* Replace any special characters in the data string since this
     will create a bad PDF doccument */
    ASSIGN
      ipchTexto = REPLACE(ipchTexto,"~\","~\~\")
      ipchTexto = REPLACE(ipchTexto,"(","~\(")
      ipchTexto = REPLACE(ipchTexto,")","~\)")
      ipchTexto = REPLACE(ipchTexto,"[","~\[")
      ipchTexto = REPLACE(ipchTexto,"]","~\]")
    {&END}
    /* Reemplazar los caracteres "no-ascii" por los códigos correspondientes */
    IF SESSION:CPINTERNAL NE 'ISO8859-1' THEN
      ipchTexto = CODEPAGE-CONVERT(ipchTexto,'ISO8859-1',SESSION:CPINTERNAL).
    minChar = 1.
    DO WHILE minChar LE LENGTH(ipchTexto):
      minAsc = ASC(SUBSTRING(ipchTexto,minChar,1)).
      IF minAsc GT 128 THEN DO:
        SUBSTRING(ipchTexto,minChar,1) = '~\' + numeroOctal(minAsc).
        minChar = minChar + 3.
      END.
      minChar = minChar + 1.
    END.
    RETURN ipchTexto.
  END METHOD.
  
  METHOD PUBLIC INTEGER agregarEnlace(INPUT ipobEnlace AS pdf.enlaces.Enlace):
    DEFINE VARIABLE minNumero AS INTEGER NO-UNDO.
    minNumero = cinSiguienteEnlace.
    CREATE cttEnlace.
    ASSIGN
      cttEnlace.inNumero = minNumero
      cttEnlace.obEnlace = ipobEnlace
    {&END}
    RETURN minNumero. 
  END METHOD.
  METHOD PUBLIC pdf.enlaces.Enlace siguienteEnlace(INPUT ipobReferencia AS pdf.enlaces.Enlace, INPUT ipobPagina AS pdf.Pagina):
    DEFINE VARIABLE minNumero AS INTEGER NO-UNDO.
    DEFINE VARIABLE mlgEncontrado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE mobEnlace AS pdf.enlaces.Enlace NO-UNDO.
    mlgEncontrado = NOT VALID-OBJECT(ipobReferencia).
    minNumero = 0.
    IF NOT mlgEncontrado THEN DO:
      FOR EACH cttEnlace WHERE cttEnlace.obEnlace EQ ipobReferencia:
        minNumero = cttEnlace.inNumero.
        mlgEncontrado = TRUE.
        LEAVE.
      END.
    END.
    IF NOT mlgEncontrado THEN
      RETURN ?.
    IF NOT VALID-OBJECT(ipobPagina) THEN DO:
      FOR EACH cttEnlace WHERE cttEnlace.inNumero GT minNumero BY cttEnlace.inNumero:
        RETURN CAST(cttEnlace.obEnlace,pdf.enlaces.Enlace).
      END.
    END.
    ELSE DO:
      FOR EACH cttEnlace WHERE cttEnlace.inNumero GT minNumero BY cttEnlace.inNumero:
        mobEnlace = CAST(cttEnlace.obEnlace,pdf.enlaces.Enlace).
        IF mobEnlace:cobPagina:cinNumero EQ ipobPagina:cinNumero THEN 
          RETURN mobEnlace. 
      END.
    END.
    RETURN ?.
  END METHOD.
  
  METHOD PROTECTED VOID generarCatalogo():
    DEFINE VARIABLE mchPDF AS CHARACTER NO-UNDO.
    
    crearObjeto("Catalog", 2).
    mchPDf = "2 0 obj" + {&pdfSKIP} + "<<" + {&pdfSKIP} + "/Type /Catalog" + {&pdfSKIP} + "/Pages 3 0 R" + {&pdfSKIP}.

    IF cinCatalogoDeMarcasDeLectura NE 0 THEN
      mchPDF = mchPDF + "/Outlines " + STRING(cinCatalogoDeMarcasDeLectura) + " 0 R" + {&pdfSKIP}.
    /* Determine PageMode */
    mchPDF = mchPDF + "/PageMode /" + TRIM(cobModoDeVisualizacion:cchTipoPDF) + {&pdfSkip}.
    /* Determine PageLayout */
    mchPDF = mchPDF + "/PageLayout /" + TRIM(cobDisposicionDePagina:cchTipoPDF) + {&pdfSkip}.
    /* Do Viewer Preferences */
    mchPDf = mchPDF + "/ViewerPreferences << ".
    IF cobPreferencias:clgOcultarBarraDeHerramientas THEN
      mchPDF = mchPDf + "/HideToolbar true ".
    IF cobPreferencias:clgOcultarBarraDeMenu THEN
      mchPDf = mchPDF + "/HideMenubar true ".
    IF cobPreferencias:clgOcultarVentana THEN
      mchPDF = mchPDF + "/HideWindowUI true ".
    IF cobPreferencias:clgAcomodarALaVentana THEN
      mchPDF = mchPDF + "/FitWindow true ".
    IF cobPreferencias:clgCentrarVentana THEN
      mchPDf = mchPDF + "/CenterWindow true ".
    IF cobPreferencias:clgMostrarTitulo THEN
      mchPDF = mchPDF + "/DisplayDocTitle true ".
    mchPDF = mchPDF + " >>" + {&pdfSKIP}.
    /* end of Viewer Preferences */
    cobDestino:agregar(mchPDf + ">>"  + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
  END METHOD.
  
  METHOD PROTECTED VOID generarCatalogoDePaginas():
    DEFINE VARIABLE mchPDF AS CHARACTER NO-UNDO.
/* se hace antes de generar la páginas    cinObjetoPaginas = crearObjeto("Pages",3). */
/* pero hay que corregir la posición de inicio */
    FIND cttObjeto WHERE cttObjeto.inNumero EQ 3.
    cttObjeto.dePosicion = cobDestino:Posicion() + 1.
    mchPDf = "3 0 obj" + {&pdfSKIP}
        + "<<" + {&pdfSKIP}
        + "/Type /Pages" + {&pdfSKIP}
        + "/Count " + STRING(cinSiguientePagina - 1) + {&pdfSKIP}
        + "/Kids [ " + {&pdfSKIP}.
  
    FOR EACH cttObjeto WHERE cttObjeto.chTipo EQ "PageDefinition" NO-LOCK:
      mchPDf = mchPDF + STRING(cttObjeto.inNumero) + " 0 R " + {&pdfSKIP}.
    END. /* Display Pages */
  
    cobDestino:agregar(mchPDf + "]" + {&pdfSKIP} + ">>" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
  END METHOD.
  
  METHOD PROTECTED VOID generarXref():
    DEFINE VARIABLE mliStart AS INT64 NO-UNDO.

    crearObjeto("Xref", 0).

    /* Get the Xref start point */
    mliStart = cobDestino:posicion().
    cobDestino:agregar("xref" + {&pdfSKIP} + "0 " + STRING(cinSiguienteObjeto) + {&pdfSKIP}).
    cobDestino:agregar("0000000000" + " 65535 f" + {&pdfSKIP}).
    FOR EACH cttObjeto WHERE cttObjeto.inNumero GT 0 BY cttObjeto.inNumero:
      cttObjeto.dePosicion = cttObjeto.dePosicion - 1.
      cobDestino:agregar(STRING(cttObjeto.dePosicion, "9999999999") + " " + STRING(cttObjeto.inGeneracion, "99999") + " "
          + cttObjeto.chTipoPDF + {&pdfSKIP}).
    END. /* each Object */

    cobDestino:agregar("trailer" + {&pdfSKIP}
      + "<<" + {&pdfSKIP}
      + "/Size " + STRING(cinSiguienteObjeto) + {&pdfSKIP}
      + "/Root 2 0 R" + {&pdfSKIP}
      + "/Info 1 0 R" + {&pdfSKIP}).

    IF VALID-OBJECT(cobEncriptador)THEN DO:
      cobDestino:agregar("/Encrypt " + STRING(cinCatalogoDeEncriptacion) + " 0 R" + {&pdfSKIP}
          + "/ID [<" + cobEncriptador:cchIdentificadorPDF + "><" + cobEncriptador:cchIdentificadorPDF + ">]" + {&pdfSKIP}).
    END.

    cobDestino:agregar(">>" + {&pdfSKIP}
      + "startxref" + {&pdfSKIP}
      + STRING(mliStart) + {&pdfSKIP}
      + "%%EOF" + {&pdfSKIP}).

  END METHOD. /* pdf_xref */
  
  METHOD PROTECTED VOID generarLetrasEstandar():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    FOR EACH cttFuente BY cttFuente.inNumero:
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
      IF NOT TYPE-OF(mobFuente,pdf.letras.TipoDeLetraEstandar) THEN
        LEAVE.
      mobFuente:asignarObjetoPDF().
    END.

    FOR EACH cttFuente BY cttFuente.inNumero:
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
      IF NOT TYPE-OF(mobFuente,pdf.letras.TipoDeLetraEstandar) THEN
        LEAVE.
      inicioObjeto(mobFuente,mobFuente:cinObjetoPDF).
      cobDestino:agregar("<<" + {&pdfSKIP}
        + "/Type /Font" + {&pdfSKIP}
        + "/Subtype /Type1" + {&pdfSKIP}
        + "/Name " + mobFuente:cchNombreInterno + {&pdfSKIP}).

      IF mobFuente:cchNombre EQ "Symbol" 
        OR mobFuente:cchNombre EQ "ZapfDingbats" THEN
        cobDestino:agregar("/Encoding << /BaseEncoding /StandardEncoding >>" + {&pdfSKIP}).
      ELSE
        cobDestino:agregar("/Encoding 4 0 R" + {&pdfSKIP}).

      cobDestino:agregar("/BaseFont /" + mobFuente:cchNombre + {&pdfSKIP}
        + ">>" + {&pdfSKIP}
        + "endobj" + {&pdfSKIP}).
    END.
  END METHOD. /* pdf_Fonts */
  
  METHOD PROTECTED VOID generarLetrasDocumento():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    
    FOR EACH cttFuente BY cttFuente.inNumero:
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
      IF TYPE-OF(mobFuente,pdf.letras.TipoDeLetraEstandar) THEN
        NEXT.
      IF TYPE-OF(mobFuente,pdf.letras.TipoDeLetraExterna) THEN
        NEXT.
      mobFuente:generarDefinicion().
    END. /* each TTfont */
  END METHOD. /* pdf_Load_fonts */
  
  METHOD PROTECTED VOID generarImagenesDocumento():
    DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
    FOR EACH cttImagen:
      mobImagen = CAST(cttImagen.obImagen,pdf.imagenes.Imagen).
      mobImagen:generarDefinicion().
    END. /* each TT_pdf_image */
  END METHOD. /* pdf_load_images */
  
  METHOD PROTECTED VOID generarEnlacesDocumento():
    DEFINE VARIABLE mobEnlace AS pdf.enlaces.Enlace NO-UNDO.
    FOR EACH cttEnlace:
      mobEnlace = CAST(cttEnlace.obEnlace,pdf.enlaces.Enlace).
      mobEnlace:generarDefinicion().
    END.
  END METHOD.
  
 METHOD PUBLIC STATIC CHARACTER dec2string (INPUT decvalue AS DECIMAL): /* PRIVATE */
  IF SESSION:NUMERIC-FORMAT = "EUROPEAN" THEN
    RETURN REPLACE( STRING(ROUND(decvalue,5)),",",".").
  ELSE
    RETURN STRING(ROUND(decvalue,5)).
 END METHOD.  /* dec2string */
 
 METHOD PUBLIC INTEGER copiarTiposDeLetra(INPUT ipobDocumento AS pdf.Documento):
   DEFINE VARIABLE minFC AS INTEGER NO-UNDO.
   DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
   DEFINE VARIABLE mobNueva AS pdf.letras.TipoDeLetra NO-UNDO.
   DEFINE VARIABLE minIndice AS INTEGER NO-UNDO.
   
   DO minIndice = 1 TO ipobDocumento:cinCantidadLetras:
     mobFuente = ipobDocumento:TipoDeLetraDefinido(minIndice).
     IF TipoDeLetraDisponible(mobFuente:cchNombre) THEN
      NEXT.
     mobNueva = DYNAMIC-NEW(mobFuente:getClass():TypeName)(THIS-OBJECT,mobFuente).
     minFC = minFC + 1.
   END.
   RETURN minFC.
 END METHOD.
 
 METHOD PUBLIC INTEGER copiarImagenes(INPUT ipobDocumento AS pdf.Documento):
   DEFINE VARIABLE minImg AS INTEGER NO-UNDO.
   DEFINE VARIABLE mobImagen AS pdf.imagenes.Imagen NO-UNDO.
   DEFINE VARIABLE mobNueva AS pdf.imagenes.Imagen NO-UNDO.
   DEFINE VARIABLE minIndice AS INTEGER NO-UNDO.
   
   DO minIndice = 1 TO ipobDocumento:cinCantidadImagenes:
     mobImagen = ipobDocumento:ImagenRegistrada(minIndice).
     IF imagenRegistrada(mobImagen:cchNombre) NE ? THEN
      NEXT.
     mobNueva = DYNAMIC-NEW(mobImagen:getClass():TypeName)(THIS-OBJECT,mobImagen).
     minImg = minImg + 1.
   END.
   RETURN minImg.
 END METHOD.
  
 METHOD PUBLIC INTEGER copiarMarcasDeLectura(INPUT ipobDocumento AS pdf.Documento):
   RETURN copiarMarcasDeLectura(ipobDocumento,0).
 END METHOD.
 METHOD PUBLIC INTEGER copiarMarcasDeLectura(INPUT ipobDocumento AS pdf.Documento, INPUT ipinPagina AS INTEGER):
   DEFINE VARIABLE minM AS INTEGER NO-UNDO.
   DEFINE VARIABLE mobMarca AS pdf.utiles.MarcaDeLectura NO-UNDO.
   DEFINE VARIABLE mobNueva AS pdf.utiles.MarcaDeLectura NO-UNDO.
   DEFINE VARIABLE minIndice AS INTEGER NO-UNDO.
   
   IF ipinPagina EQ ? THEN
    ipinPagina = 0.
   
   DO minIndice = 1 TO ipobDocumento:cinCantidadMarcasDeLectura:
     mobMarca = ipobDocumento:marcaDeLecturaRegistrada(minIndice).
     IF ipinPagina GT 0 AND mobMarca:cobPagina:cinNumero NE ipinPagina THEN
      NEXT.
     mobNueva = marcaDeLecturaRegistrada(mobMarca:cchTitulo). 
     IF VALID-OBJECT(mobNueva) AND mobNueva:cobPagina:cinNumero EQ cobPaginaActual:cinNumero THEN
      NEXT.
     mobNueva = DYNAMIC-NEW(mobMarca:getClass():TypeName)(THIS-OBJECT,mobMarca).
     minM = minM + 1.
   END.
   RETURN minM.
 END METHOD.
 
END CLASS.
