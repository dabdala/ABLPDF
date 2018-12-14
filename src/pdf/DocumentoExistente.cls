{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : DocumentoExistente
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 12 18:15:10 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/


ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING pdf.Documento FROM PROPATH.
USING pdf.excepciones.PDFException FROM PROPATH.

CLASS pdf.DocumentoExistente INHERITS Documento:
  DEFINE PROTECTED PROPERTY cobDocumentoDestino AS pdf.Documento NO-UNDO
    GET.
    SET(INPUT ipobDD AS pdf.Documento):
      cobDocumentoDestino = ipobDD.
      IF NOT VALID-OBJECT(ipobDD) THEN
        RETURN.
      cobDestino = ipobDD:cobDestino.
      cobCompresor = ipobDD:cobCompresor.
      cobEncriptador = ipobDD:cobEncriptador.
    END SET.
    
  DEFINE PRIVATE STATIC VARIABLE cobPDF AS pdf.utiles.PDFStream NO-UNDO.
  
  DEFINE PUBLIC PROPERTY cchArchivo AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cchVersionPDF AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cchPDFId AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY clgCambiarMetodoCompresion AS LOGICAL NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cdaModificacion AS DATE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cchHoraModificacion AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cdaCreacion AS DATE NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cchHoraCreacion AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobDimensiones AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobAreaDeCorte AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED TEMP-TABLE TT_Resource NO-UNDO
    FIELD par_obj     AS INTEGER
    FIELD par_gen     AS INTEGER
    FIELD page_id     AS INTEGER
    FIELD res_type    AS CHARACTER
    FIELD res_obj     AS INTEGER
    FIELD res_gen     AS INTEGER
    FIELD res_text    AS CHARACTER
    FIELD res_old     AS CHARACTER 
    FIELD new_obj     AS INTEGER
    FIELD new_gen     AS INTEGER
    FIELD obRecurso   AS Progress.Lang.Object
  INDEX page_id AS PRIMARY
        page_id
  {&END}

  DEFINE PRIVATE TEMP-TABLE TT_Info NO-UNDO
    FIELD info_name   AS CHARACTER
    FIELD info_value  AS CHARACTER
  {&END}
  METHOD PROTECTED VOID CreateInfo(INPUT pInfo  AS CHARACTER, INPUT pValue AS CHARACTER):
    IF pValue = "" OR pValue = ? THEN RETURN.
  
    CREATE TT_Info.
    ASSIGN 
           TT_info.info_name  = pInfo
           TT_info.info_value = pValue
    {&END}
  END METHOD. /* CreateInfo */

  DEFINE PRIVATE TEMP-TABLE cttReferencia NO-UNDO
    FIELD inObjeto AS INTEGER
    FIELD inGeneracion AS INTEGER
    FIELD chNombre AS CHARACTER
  {&END}
  
  METHOD PROTECTED INTEGER objetoReferencia(INPUT ipchNombre AS CHARACTER):
    FIND cttReferencia WHERE cttReferencia.chNombre EQ ipchNombre NO-ERROR.
    IF AVAILABLE cttReferencia THEN
      RETURN cttReferencia.inObjeto.
    RETURN ?.
  END METHOD.
  METHOD PROTECTED INTEGER generacionReferencia(INPUT ipchNombre AS CHARACTER):
    FIND cttReferencia WHERE cttReferencia.chNombre EQ ipchNombre NO-ERROR.
    IF AVAILABLE cttReferencia THEN
      RETURN cttReferencia.inGeneracion.
    RETURN ?.
  END METHOD.
  METHOD PROTECTED VOID registrarReferencia(INPUT ipchNombre AS CHARACTER, INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    FIND cttReferencia WHERE cttReferencia.chNombre EQ ipchNombre NO-ERROR.
    IF NOT AVAILABLE cttReferencia THEN
      CREATE cttReferencia.
    ASSIGN 
      cttReferencia.inObjeto = ipinObjeto
      cttReferencia.inGeneracion = ipinGeneracion
      cttReferencia.chNombre = ipchNombre
    {&END}
  END METHOD.
  
  DEFINE PUBLIC PROPERTY clgEncriptado AS LOGICAL NO-UNDO
    GET.
    PRIVATE SET.
    
/*-- gestión de los objetos obtenidos de un PDF existente --*/
  DEFINE PROTECTED PROPERTY cinSiguienteObjetoExistente AS INTEGER NO-UNDO
    GET:
      cinSiguienteObjetoExistente = cinSiguienteObjetoExistente + 1.
      RETURN cinSiguienteObjetoExistente.
    END GET.
    PRIVATE SET.
    
  DEFINE PROTECTED TEMP-TABLE cttObjetoExistente NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chTipo AS CHARACTER
    FIELD inPosicion AS INT64
    FIELD inObjeto AS INTEGER
    FIELD inGeneracion AS INTEGER
    FIELD inPagina AS INTEGER
  {&END}
  
  DEFINE PRIVATE BUFFER cttObjPos FOR cttObjetoExistente.
  METHOD PROTECTED INT64 setToPos(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    FOR EACH cttObjPos WHERE cttObjPos.inObjeto EQ ipinObjeto
                           AND cttObjPos.inGeneracion EQ ipinGeneracion
      BY cttObjPos.inNumero:
      cobPDF:seekPos(cttObjPos.inPosicion).
      RETURN cttObjPos.inPosicion.
    END.
    RETURN 0.
  END METHOD.
  
  METHOD PUBLIC INT64 posicionObjeto(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    FIND cttObjPos WHERE cttObjPos.inObjeto EQ ipinObjeto AND cttObjPos.inGeneracion EQ ipinGeneracion NO-ERROR.
    IF AVAILABLE cttObjPos THEN
      RETURN cttObjPos.inPosicion.
    RETURN ?.
  END METHOD.
  
  METHOD PUBLIC CHARACTER tipoObjeto(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    FIND cttObjPos WHERE cttObjPos.inObjeto EQ ipinObjeto AND cttObjPos.inGeneracion EQ ipinGeneracion NO-ERROR.
    IF AVAILABLE cttObjPos THEN
      RETURN cttObjPos.chTipo.
    RETURN ?.
  END METHOD.

  DEFINE PROTECTED TEMP-TABLE cttPaginaExistente NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD chNombreXObject AS CHARACTER
    FIELD obPagina AS Progress.Lang.Object
  {&END}
  DEFINE PUBLIC PROPERTY cinCantidadPaginasExistentes AS INTEGER NO-UNDO
    GET:
      DEFINE BUFFER mbfPE FOR cttPaginaExistente.
      FOR EACH mbfPE BY mbfPE.inNumero DESC:
        RETURN mbfPE.inNumero.
      END.
      RETURN 0.
    END GET.  
    
  METHOD PROTECTED pdf.PaginaExistente agregarPaginaExistente(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    DEFINE BUFFER mbfOE FOR cttObjetoExistente.
    DEFINE VARIABLE mobPagina AS pdf.PaginaExistente NO-UNDO.    
    
    FIND mbfOE WHERE mbfOE.inObjeto EQ ipinObjeto AND mbfOE.inGeneracion EQ ipinGeneracion.
    mobPagina = NEW pdf.PaginaExistente(THIS-OBJECT,cobPDF).
    CREATE cttPaginaExistente.
    ASSIGN
      cttPaginaExistente.inNumero = cinCantidadPaginasExistentes + 1      
      cttPaginaExistente.obPagina = mobPagina
      mobPagina:cinNumero = cttPaginaExistente.inNumero
      mbfOE.inPagina = cttPaginaExistente.inNumero
    {&END}
    cobPaginaActual = mobPagina.
    mobPagina:LoadFromStream(ipinObjeto,ipinGeneracion).
    RETURN mobPagina.
  END METHOD.
  
  METHOD PROTECTED VOID cargarPDF():
    DEFINE VARIABLE seek-ptr AS INT64 NO-UNDO.
    DEFINE VARIABLE xref-ptr AS INT64 NO-UNDO.
    DEFINE VARIABLE text-line AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mobPagina AS pdf.Pagina NO-UNDO.
    DEFINE VARIABLE mobPExt AS pdf.PaginaExistente NO-UNDO.
    
    cobPDF = NEW pdf.utiles.PDFStream(cchArchivo).
    /* Determine Version 
       - this should be on first line of a well-formed PDF document */
    text-line = cobPDF:ReadLine().
    cchVersionPDF = REPLACE(text-line,"%PDF-","").
  
    /* Go To End of File */
    seek-ptr = cobPDF:seekEnd().
  
    IF NOT cobPDF:UpLine() THEN  /* Get the %%EOF line */
      UNDO, THROW NEW PDFException('El archivo tiene el tamaño, o contenido incorrectos').
    IF NOT cobPDF:UpLine() THEN  /* Before the XREF pointer line */
      UNDO, THROW NEW PDFException('El archivo tiene el tamaño, o contenido incorrectos').
    xref-ptr = INT(cobPDF:ReadLine()).  /* Get the XREF Pointer line */
  
    IF xref-ptr = 0 THEN
      UNDO, THROW NEW PDFException("Incorrect starting point --- Why? I need to Figure that out!!").
  
    LoadObjectPointers(xref-ptr).
    IF clgEncriptado THEN
      UNDO, THROW NEW PDFException("Document is Encrypted").
  
    ProcessObjectPointers().
  
    CreateInfo("Pages",STRING(cinCantidadPaginasExistentes)).
    cobPaginaActual = ?.
    FOR EACH cttPaginaExistente BY cttPaginaExistente.inNumero:
      mobPExt = CAST(cttPaginaExistente.obPagina,pdf.PaginaExistente).
      mobPagina = agregarPagina(mobPExt).
      mobPagina:usarXObject(mobPExt:cchNombreXObject).
      mobPagina:copiarCampos(mobPExt).
    END.
    FINALLY:
      DELETE OBJECT cobPDF.
    END FINALLY.
  END METHOD. 

  CONSTRUCTOR PUBLIC DocumentoExistente(INPUT ipchArchivo AS CHARACTER):
    SUPER().
    FILE-INFO:FILE-NAME = ipchArchivo.
    IF FILE-INFO:FULL-PATHNAME EQ ? THEN
      UNDO, THROW NEW PDFException('No existe el PDF').      
    cchArchivo = ipchArchivo.
    cobAreaDeCorte = NEW pdf.utiles.Area().
    cobDimensiones = NEW pdf.utiles.Area().
    cargarPDF().    
  END CONSTRUCTOR.
  
  DESTRUCTOR DocumentoExistente():
    DELETE OBJECT cobAreaDeCorte NO-ERROR.
    DELETE OBJECT cobDimensiones NO-ERROR.
    FOR EACH TT_Resource:
      DELETE OBJECT TT_Resource.obRecurso NO-ERROR.
    END.
  END.
  
  METHOD PROTECTED VOID LoadObjectPointers(INPUT pPointer AS INT64):
    DEFINE VARIABLE prev-ptr  AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
    cobPDF:SeekPos(pPointer).

    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
      
      IF LENGTH(text-ptr) > 0 
      AND SUBSTR(text-ptr,LENGTH(text-ptr),1) = "n" THEN DO:
        CREATE cttObjetoExistente.
        ASSIGN 
          cttObjetoExistente.inPosicion = INT(ENTRY(1,text-ptr," "))
          cttObjetoExistente.inNumero   = cinSiguienteObjetoExistente
        {&END}
      END.
  
      IF INDEX(text-ptr,"~/Root") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr, INDEX(text-ptr,"~/Root") + 5)).
        registrarReferencia('Root',INT(ENTRY(1,text-temp," ")),INT(ENTRY(2,text-temp," "))).
      END.
  
      IF INDEX(text-ptr,"~/Info") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr, INDEX(text-ptr,"~/Info") + 5)).
        registrarReferencia('Info',INT(ENTRY(1,text-temp," ")),INT(ENTRY(2,text-temp," "))).
      END.
  
      IF INDEX(text-ptr,"~/Encrypt") > 0 THEN DO:
        clgEncriptado = TRUE.
        LEAVE.
      END.
  
      IF INDEX(text-ptr,"~/Prev") > 0 THEN DO:
        text-temp = TRIM(SUBSTR(text-ptr, INDEX(text-ptr,"~/Prev") + 5)).
        text-temp = REPLACE(text-temp,"~/"," ").
        prev-ptr = INT(ENTRY(1,text-temp," ")).
  
        LoadObjectPointers(prev-ptr). 
      END.
  
      IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
    END.
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* LoadObjectPointers */

  METHOD PROTECTED VOID ProcessObjectPointers():
    DEFINE VARIABLE text-line AS CHARACTER NO-UNDO.
  
    /* Determine Object and Generation Number */
    FOR EACH cttObjetoExistente:
  
      cobPDF:SeekPos(cttObjetoExistente.inPosicion).
      text-line  = cobPDF:ReadLine().
      
      cttObjetoExistente.inObjeto = INT(ENTRY(1,text-line," ")) NO-ERROR.
      cttObjetoExistente.inGeneracion = INT(ENTRY(2,text-line," ")) NO-ERROR.
  
      IF  cttObjetoExistente.inObjeto EQ objetoReferencia('Root') 
      AND cttObjetoExistente.inGeneracion EQ generacionReferencia('Root') THEN
        cttObjetoExistente.chTipo = "~/Root".
  
      IF  cttObjetoExistente.inObjeto EQ objetoReferencia('Info') 
          AND cttObjetoExistente.inGeneracion  EQ generacionReferencia('Info') THEN
        cttObjetoExistente.chTipo = "~/Info".
    END.
    
    /* Read the Info Dictionary and Determine Document Info */
    FOR EACH cttObjetoExistente WHERE cttObjetoExistente.chTipo EQ "~/Info"
        BY inObjeto BY inGeneracion BY inNumero: 
      ProcessInfoDictionary().
      LEAVE.
    END. /* Info Dictionary */
  
    /* Read the Root Dictionary and determine the Page Objects */
    FOR EACH cttObjetoExistente WHERE cttObjetoExistente.chTipo EQ "~/Root"
        BY inObjeto BY inGeneracion BY inNumero:
  
      ProcessRootDictionary().
      LEAVE.
    END. /* Root Dictionary */
  END. /* ProcessObjectPointers */
  
  METHOD PROTECTED VOID ProcessInfoDictionary():
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
  
    cobPDF:SeekPos(cttObjetoExistente.inPosicion).
  
    DO WHILE TRUE:
      text-ptr = cobPDF:Readline(). 
      
      IF INDEX(text-ptr,"~/Author") > 0 THEN DO:
        cchAutor = cobPDF:ParseText(text-ptr, "~/Author").
        CreateInfo ("Author",cchAutor).
      END.
      IF INDEX(text-ptr,"/Producer") > 0 THEN DO:
        cchProductor = cobPDF:ParseText (text-ptr, "~/Producer").
        CreateInfo ("Producer",cchProductor).
      END.
      IF INDEX(text-ptr,"/Creator") > 0 THEN DO:
        cchCreador = cobPDF:ParseText (text-ptr, "~/Creator").
        CreateInfo ("Creator",cchCreador).
      END.
      IF INDEX(text-ptr,"~/Title") > 0 THEN DO:
        cchTitulo = cobPDF:ParseText (text-ptr, "~/Title").
        CreateInfo ("Title",cchTitulo).
      END.
      IF INDEX(text-ptr,"~/Subject") > 0 THEN DO:
        cchAsunto = cobPDF:ParseText (text-ptr, "~/Subject").
        CreateInfo ("Subject",cchAsunto).
      END.
      IF INDEX(text-ptr,"~/Keywords") > 0 THEN DO:
        cchPalabrasClave = cobPDF:ParseText (text-ptr, "~/Keywords").
        CreateInfo ("Keywords",cchPalabrasClave).
      END.
      IF INDEX(text-ptr,"~/ModDate") > 0 THEN DO:
        mchPorcion = cobPDF:ParseText (text-ptr, "~/ModDate").
        cdaModificacion = DATE(INT(SUBSTR(mchPorcion,7,2)),
                           INT(SUBSTR(mchPorcion,9,2)),
                           INT(SUBSTR(mchPorcion,3,4))) NO-ERROR.
        CreateInfo ("ModDate",STRING(cdaModificacion)).
        cchHoraModificacion = SUBSTR(mchPorcion,11,2) + ":"
                    + SUBSTR(mchPorcion,13,2) + ":"
                    + SUBSTR(mchPorcion,15,2).
        CreateInfo ("ModTime",cchHoraModificacion).
      END.
      IF INDEX(text-ptr,"~/CreationDate") > 0 THEN DO:
        mchPorcion = cobPDF:ParseText (text-ptr, "~/CreationDate").
        cdaCreacion = DATE(INT(SUBSTR(mchPorcion,7,2)),
                             INT(SUBSTR(mchPorcion,9,2)),
                             INT(SUBSTR(mchPorcion,3,4))) NO-ERROR.
        CreateInfo ("CreationDate",STRING(cdaCreacion)).
        cchHoraCreacion = SUBSTR(mchPorcion,11,2) + ":"
                      + SUBSTR(mchPorcion,13,2) + ":"
                      + SUBSTR(mchPorcion,15,2).
        CreateInfo ("CreationTime",cchHoraCreacion).
      END.
      IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
    END.
  END. /* ProcessInfoDictionary */

  METHOD PROTECTED VOID ProcessRootDictionary():
    DEFINE VARIABLE text-ptr   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE temp-text  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE inObj AS INTEGER NO-UNDO.
    DEFINE VARIABLE inGen AS INTEGER NO-UNDO.
  
    cobPDF:SeekPos(cttObjetoExistente.inPosicion).
    /* text-line = Readline(). */
  
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
  
      IF INDEX(text-ptr,"~/Pages") > 0 THEN DO:
        temp-text = SUBSTR(text-ptr,INDEX(text-ptr,"~/Pages")).
        inobj = INT( ENTRY(2, temp-text, " ") ).
        ingen = INT( ENTRY(3, temp-text, " ") ).
        registrarReferencia('Pages',inObj,inGen).
      END.
      IF INDEX(text-ptr,"~/AcroForm") > 0 THEN DO:
        temp-text = SUBSTR(text-ptr,INDEX(text-ptr,"~/AcroForm")).
        inObj = INT( ENTRY(2, temp-text, " ") ).
        inGen = INT( ENTRY(3, temp-text, " ") ).
        registrarReferencia('AcroForm',inObj,inGen).
      END.
      IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
    END.
    /* procesar los objetos de interés */
    inObj = objetoReferencia('Pages').
    IF inObj NE ? THEN DO:
      inGen = generacionReferencia('Pages').
      ProcessPagesDictionary(inObj, inGen).
    END.
    inObj = objetoReferencia('AcroForm').
    IF inObj NE ? THEN DO:
      inGen = generacionReferencia('AcroForm').
      ProcessAcroFormDictionary (inObj, inGen).
    END.
  END METHOD. /* ProcessRootDictionary */
  METHOD PROTECTED VOID ProcessPagesDictionary(INPUT pObject  AS INTEGER, INPUT pGen     AS INTEGER ):
    IF setToPos(pObject,pGen) GT 0 THEN
      ProcessKids().
  END METHOD. /* ProcessPagesDictionary */
  METHOD PROTECTED VOID ProcessAcroFormDictionary(INPUT pObject  AS INTEGER, INPUT pGen     AS INTEGER):
    IF setToPos(pObject,pGen) GT 0 THEN
      ProcessFields().
  END METHOD. /* ProcessAcroFormDictionary */
  METHOD PROTECTED VOID ProcessKids():
    DEFINE VARIABLE L_InKids  AS LOGICAL NO-UNDO.
    DEFINE VARIABLE L_Kids    AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Obj     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Gen     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_ptr     AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE curr-ptr  AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
  
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
  
      IF INDEX(text-ptr,"~/Kids") > 0 THEN DO:
        ASSIGN
          L_InKids = TRUE
          L_Kids = SUBSTR(text-ptr,INDEX(text-ptr,"[") + 1)
          minIndex = INDEX(L_Kids,"]") 
        {&END}
        IF minIndex > 0 THEN DO:
          L_InKids = FALSE.
          L_Kids = SUBSTRING(L_Kids,1,minIndex - 1).
        END.
      END.
      ELSE IF L_InKids THEN DO:
        minIndex = INDEX(text-ptr,"]"). 
        IF minIndex > 0 THEN DO:
          L_Kids = L_Kids + " " + SUBSTR(text-ptr,1,minIndex - 1).
          L_InKids = FALSE.
          LEAVE.
        END.
        ELSE
          L_Kids = L_Kids + " " + text-ptr.
      END.
  
      IF INDEX(text-ptr,"~/MediaBox") > 0 THEN DO:
        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/MediaBox")).
        text-temp = REPLACE(text-temp,"/MediaBox","").
        text-temp = REPLACE(text-temp,"[","").
        text-temp = TRIM(REPLACE(text-temp,"]","")).
  
        /* If MediaBox is an Object then find the object and return the 
           MediaBox directives */
        IF ENTRY(3,text-temp," ") = "R" THEN
          ProcessBoxObject (INT(ENTRY(1,text-temp," ") ),INT(ENTRY(2,text-temp," ") ),cobDimensiones).
        ELSE ASSIGN
          cobDimensiones:cinIzquierda = INT(ENTRY(1,text-temp, " "))
          cobDimensiones:cinAbajo = INT(ENTRY(2,text-temp, " "))
          cobDimensiones:cinDerecha = INT(ENTRY(3,text-temp, " "))
          cobDimensiones:cinArriba = INT(ENTRY(4,text-temp, " "))
        {&END}
        cinAnchoDePagina = cobDimensiones:cinAncho.
        cinAltoDePagina = cobDimensiones:cinAlto.
      END. /* MediaBox */
  
      IF INDEX(text-ptr,"~/CropBox") > 0 THEN DO:
        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/CropBox")).
        text-temp = REPLACE(text-temp,"/CropBox","").
        text-temp = REPLACE(text-temp,"[","").
        text-temp = TRIM(REPLACE(text-temp,"]","")).
  
        /* If CropBox is an Object then find the object and return the 
           CropBox directives */
        IF ENTRY(3,text-temp," ") = "R" THEN
          ProcessBoxObject (INT(ENTRY(1,text-temp," ") ),INT(ENTRY(2,text-temp," ") ), cobAreaDeCorte).
        ELSE ASSIGN
          cobAreaDeCorte:cinIzquierda = INT(ENTRY(1,text-temp, " "))
          cobAreaDeCorte:cinAbajo = INT(ENTRY(2,text-temp, " "))
          cobAreaDeCorte:cinDerecha = INT(ENTRY(3,text-temp, " "))
          cobAreaDeCorte:cinArriba = INT(ENTRY(4,text-temp, " "))
        {&END}
      END. /* CropBox */
  
      IF INDEX(text-ptr,"~/Resources") > 0 THEN DO:
        text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/Resources")).
        ASSIGN L_obj = INT(ENTRY(2, text-temp, " "))
               L_gen = INT(ENTRY(3, text-temp, " ")) NO-ERROR.
  
        IF NOT ERROR-STATUS:ERROR THEN
          registrarReferencia('Resources',L_obj,L_gen).  
      END.
  
      IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
    END.
  
    L_obj = objetoReferencia('Resources').
    IF L_obj NE ? THEN
      ProcessResourceDictionary (L_obj, generacionReferencia('Resources')).
      
    L_Kids = TRIM(REPLACE(L_Kids,"~/Kids"," ")).
    IF INDEX(L_Kids,"~/") > 0 THEN
      L_Kids = SUBSTR(L_Kids,1,INDEX(L_Kids,"~/") - 1).
  
    DO L_Loop = 1 TO NUM-ENTRIES(L_Kids," ") BY 3:
      ASSIGN L_Obj = INT(ENTRY(L_Loop, L_Kids, " "))
             L_Gen = INT(ENTRY(L_Loop + 1, L_Kids, " ")).
  
      ProcessPageDictionary (L_Obj, L_Gen).
    END.  
  END METHOD. /* ProcessKids */
  
  METHOD PUBLIC pdf.recursos.Diccionario ProcessResourceDictionary(INPUT pObject  AS INTEGER, INPUT pGen AS INTEGER):
    DEFINE BUFFER B_TT_Object FOR cttObjetoExistente.
    DEFINE VARIABLE mobRecurso AS pdf.recursos.Diccionario NO-UNDO.
    
    
    FOR EACH TT_Resource WHERE
        TT_Resource.res_obj EQ pObject AND
        TT_Resource.res_gen EQ pGen BY
        TT_Resource.res_text:
      RETURN CAST(TT_Resource.obRecurso,pdf.recursos.Diccionario). 
    END.
      
    FOR EACH B_TT_Object WHERE B_TT_object.inObjeto EQ pObject
                           AND B_TT_object.inGeneracion EQ pGen
      BY B_TT_object.inNumero:
      IF B_TT_Object.chTipo EQ '' THEN ASSIGN
        B_TT_Object.chTipo = "~/Resource"
        B_TT_Object.inPagina  = 0
      {&END}
      mobRecurso = NEW pdf.recursos.Diccionario(THIS-OBJECT,cobPDF).
      CREATE TT_Resource.
      ASSIGN TT_Resource.par_Obj    = 0
             TT_Resource.par_gen    = 0
             TT_Resource.page_id    = 0
             TT_Resource.res_type   = 'Resource'
             TT_Resource.res_obj    = pObject
             TT_Resource.res_gen    = pGen
             TT_Resource.res_text   = "~/Resource"
             TT_Resource.res_old    = ""
             TT_Resource.obRecurso  = mobRecurso
      {&END}
      mobRecurso:LoadFromStream(pObject,pGen,'').
      LEAVE.
    END.      
  END METHOD. /* ProcressResourceDictionary */
  
  METHOD PROTECTED VOID ProcessFields():
    DEFINE VARIABLE L_InFields  AS LOGICAL NO-UNDO.
    DEFINE VARIABLE L_Fields    AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Obj     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Gen     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_ptr     AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE curr-ptr  AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
  
    DO WHILE TRUE:
      text-ptr = cobPDF:readline().
  
      IF INDEX(text-ptr,"~/Fields") > 0 THEN DO:
        L_InFields = TRUE.
  
        L_Fields = SUBSTR(text-ptr,INDEX(text-ptr,"[") + 1).
  
        IF INDEX(text-ptr,"]") > 0 THEN DO:
          L_InFields = FALSE.
          L_Fields = SUBSTR(L_Fields,1,INDEX(L_Fields,"]") - 1).
          /* L_Fields = REPLACE(L_Fields,"]",""). */
        END.
  
      END. /* Fields */
  
      ELSE IF L_InFields THEN DO:
        IF INDEX(text-ptr,"]") > 0 THEN DO:
          L_Fields = L_Fields + " " + SUBSTR(text-ptr,1,INDEX(text-ptr,"]") - 1).
          L_InFields = FALSE.
        END.
        ELSE
          L_Fields = L_Fields + " " + text-ptr.
  
      END.
  
      IF INDEX(text-ptr,"~/DR") > 0  THEN
         ProcessDR (text-ptr).
  
      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END.
  
    L_Fields = TRIM(REPLACE(L_Fields,"~/Fields"," ")).
  
    IF INDEX(L_Fields,"~/") > 0 THEN
      L_Fields = SUBSTR(L_Fields,1,INDEX(L_Fields,"~/") - 1).
  
    DO L_Loop = 1 TO NUM-ENTRIES(L_Fields," ") BY 3:
      ASSIGN
        L_Obj = INT(ENTRY(L_Loop, L_Fields, " "))
        L_Gen = INT(ENTRY(L_Loop + 1, L_Fields, " "))
      {&END}
      ProcessFieldDictionary (L_Obj, L_Gen, "", "", "").
    END.  
  END METHOD. /* ProcessFields */

  METHOD PUBLIC VOID ProcessBoxObject(INPUT pObject AS INTEGER, INPUT pGen AS INTEGER, INPUT ipobArea AS pdf.utiles.Area):
    cobPDF:preservarPos().
    IF SetToPos(pObject,pGen) GT 0 THEN
      cobPDF:ProcessBoxObject(ipobArea).
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.  /* ProcessMediaBox */
  
  
  METHOD PROTECTED VOID ProcessPageDictionary(INPUT pObject  AS INTEGER, INPUT pGen     AS INTEGER):
    DEFINE BUFFER B_TT_Object FOR cttObjetoExistente.
    
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE obj-type  AS CHARACTER NO-UNDO.
  
    FOR EACH B_TT_Object WHERE B_TT_object.inObjeto EQ pObject
                           AND B_TT_object.inGeneracion EQ pGen
      BY B_TT_object.inNumero:
      cobPDF:SeekPos(B_TT_Object.inPosicion).
      DO WHILE TRUE:
        text-ptr = cobPDF:readline().

        IF INDEX(text-ptr,"~/Type") > 0  THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/Type")).
          obj-type = TRIM(ENTRY(3, text-temp, "~/")).
          obj-type = REPLACE(obj-type,">>","").

          B_TT_object.chTipo = obj-type.
        END.

        CASE obj-type:
          WHEN "Pages" THEN DO:
            ProcessPagesDictionary(pObject, pGen).
            LEAVE.
          END.
          WHEN "Page" THEN DO:
            agregarPaginaExistente(pObject,pGen).
            LEAVE.
          END.
        END CASE.
        IF INDEX(text-ptr,">>") > 0 THEN LEAVE.
      END.
      LEAVE.
    END. /* each Pages Dictionary */  
  END METHOD. /* ProcessPAGEDictionary */

  METHOD PROTECTED VOID ProcessDR(INPUT text-ptr AS CHARACTER):
    DEFINE VARIABLE text-tmp  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_Entries AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE curr-pos  AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Obj     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Gen     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_FontNbr AS INTEGER NO-UNDO INIT 1.
  
    DEFINE VARIABLE L_InFonts AS LOGICAL NO-UNDO.
    DEFINE VARIABLE mlcContenido AS LONGCHAR NO-UNDO.
  
    cobPDF:preservarPos().
  
    DO WHILE TRUE:
  
      IF NOT L_InFonts AND INDEX(text-ptr,"~/Font") > 0 THEN DO:
        text-tmp = TRIM(SUBSTR(text-ptr,INDEX(text-ptr,"~/Font"))).
        text-ptr = text-tmp.
  
        IF INDEX(text-ptr,">>") > 0 THEN DO:
          text-tmp = SUBSTR(text-tmp,1,INDEX(text-tmp,">>") - 1).
          L_InFonts = FALSE.
        END.
  
        ELSE
          L_InFonts = TRUE.
      END.
      
      ELSE IF L_InFonts THEN DO:
  
        IF INDEX(text-ptr,">>") > 0 THEN DO:
          text-ptr = SUBSTR(text-ptr,1,INDEX(text-ptr,">>") - 1).
          L_InFonts = FALSE.
        END.
  
        text-tmp = text-tmp + " " + text-ptr.
  
      END.
  
      text-ptr = cobPDF:ReadLine().
  
      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END.
  
    text-tmp = TRIM(REPLACE(text-tmp,"~/Font"," ")).
    text-tmp = TRIM(REPLACE(text-tmp,"<<","")).
    text-tmp = TRIM(REPLACE(text-tmp,">>","")).
    text-tmp = TRIM(REPLACE(text-tmp,"~/"," ~/")).
    text-tmp = TRIM(REPLACE(text-tmp,"  ~/"," ~/")).
  
    DO L_Loop = 1 TO NUM-ENTRIES(text-tmp," ") BY 4:
      ASSIGN L_Obj = INT(ENTRY(L_Loop + 1, text-tmp, " "))
             L_Gen = INT(ENTRY(L_Loop + 2, text-tmp, " ")) NO-ERROR.
  
      agregarTipoDeLetra(L_Obj,L_Gen,'Font',0,0,'xTT' + STRING(L_FontNbr)).
      L_FontNbr = L_FontNbr + 1.
    END.    
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcessDR */

  METHOD PROTECTED VOID ProcessFieldDictionary(INPUT pObject  AS INTEGER,INPUT pGen     AS INTEGER, INPUT obj-name AS CHARACTER, INPUT obj-type AS CHARACTER, INPUT obj-disp AS CHARACTER):
    DEFINE VARIABLE par-obj   AS INTEGER NO-UNDO.
    DEFINE VARIABLE par-gen   AS INTEGER NO-UNDO.
    DEFINE VARIABLE par-page  AS INTEGER NO-UNDO.
  
    DEFINE BUFFER B_TT_Object FOR cttObjetoExistente.
    DEFINE BUFFER B_Par_Object FOR cttObjetoExistente.
    
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE obj-rect  AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE L_HasKids AS LOGICAL NO-UNDO.
    DEFINE VARIABLE mobCampo AS pdf.recursos.CampoFormulario NO-UNDO.
    
    FOR EACH B_TT_Object WHERE B_TT_object.inObjeto EQ pObject
                           AND B_TT_object.inGeneracion EQ pGen
      BY B_TT_object.inNumero:
      cobPDF:SeekPos(B_TT_Object.inPosicion).

      DO WHILE TRUE:
        text-ptr = cobPDF:readline().

        IF INDEX(text-ptr,"~/FT") > 0  THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/FT")).
          obj-type = TRIM(ENTRY(3, text-temp, "~/")).
          B_TT_object.chTipo = "Widget".
        END.
        
        IF INDEX(text-ptr,"~/Rect") > 0  THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/Rect") + 5).
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,"]")).

          obj-rect = REPLACE(text-temp,"[","").
          obj-rect = TRIM(REPLACE(obj-rect,"]","")).
        END.

        IF INDEX(text-ptr,"~/T ") > 0 THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/T ") + 3).
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,")")).

          obj-name = REPLACE(text-temp,"(","").
          obj-name = TRIM(REPLACE(obj-name,")","")).
        END.

        IF INDEX(text-ptr,"~/P ") > 0 THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/P ") + 3).

          ASSIGN par-obj = INT(ENTRY(1,text-temp," "))
                 par-gen = INT(ENTRY(2,text-temp," ")) NO-ERROR.

          FIND FIRST B_Par_object 
               WHERE B_par_object.inObjeto EQ par-obj
                 AND B_par_object.inGeneracion EQ par-gen NO-ERROR.
          IF AVAIL B_par_object THEN DO:
            /* Bit of a hack to ensure that the Field ID is set to the current
              document page - don't have time to figure out why the parent
              would be set as Page 0 (since it only happens sometimes) */
            IF b_Par_object.inPagina EQ 0 THEN
              b_Par_Object.inPagina = cobPaginaActual:cinNumero.
            par-page = B_par_object.inPagina.
          END.
          ELSE
            par-page = 1.
        END.

        IF INDEX(text-ptr,"~/T(") > 0 THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/T(") + 3).
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,")")).

          obj-name = REPLACE(text-temp,"(","").
          obj-name = TRIM(REPLACE(obj-name,")","")).
        END.

        IF INDEX(text-ptr,"~/DA") > 0  THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/DA") + 3).
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,")")).

          obj-disp = REPLACE(text-temp,"(","").
          obj-disp = TRIM(REPLACE(obj-disp,")","")).
        END.

        IF INDEX(text-ptr,"~/DR") > 0  THEN DO:
          ProcessDR(text-ptr).
        END.

        IF INDEX(text-ptr,"~/Kids") > 0  THEN DO:
          text-temp = SUBSTR(text-ptr,INDEX(text-ptr,"~/Kids") + 5).
          text-temp = SUBSTR(text-temp,1,INDEX(text-temp,"]")).
          text-temp = REPLACE(text-temp,"[","").
          text-temp = TRIM(REPLACE(text-temp,"]","")).

          ProcessFieldKids(text-temp, obj-name, obj-type, obj-disp).
          L_HasKids = TRUE.
        END.

        IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
      END. /* While True */

      /* A text form field was found */
      IF NOT l_HasKids AND obj-type = "TX" THEN DO:
        mobCampo = NEW pdf.recursos.CampoFormulario().
        mobCampo:cchNombre = obj-name.
        mobCampo:cchFormato = obj-disp.        
        mobCampo:cobArea:cinIzquierda = INTEGER(ENTRY(1,obj-rect,' ')).
        mobCampo:cobArea:cinAbajo = INTEGER(ENTRY(2,obj-rect,' ')).
        mobCampo:cobArea:cinDerecha = INTEGER(ENTRY(3,obj-rect,' ')).
        mobCampo:cobArea:cinArriba = INTEGER(ENTRY(4,obj-rect,' ')).
        cobPaginaActual:registrarCampoFormulario(mobCampo).
      END.
      LEAVE.
    END. /* each Field Dictionary */
  END METHOD. /* ProcessFIELDDictionary */

  METHOD PUBLIC CHARACTER ProcessEntry(INPUT  pObject AS INTEGER, INPUT  pGen AS INTEGER, INPUT  pType  AS CHARACTER):
    DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mlgArreglo AS LOGICAL NO-UNDO.
    DEFINE VARIABLE minObj AS INTEGER NO-UNDO.
    DEFINE VARIABLE minGen AS INTEGER NO-UNDO.
  
    cobPDF:preservarPos().
    
    IF setToPos(pObject,pGen) EQ 0 THEN
      RETURN ''.
    pType = pType.
  
    DO WHILE minIndex EQ 0:
      mchLinea = cobPDF:readline().
      minIndex = INDEX(mchLinea,'~/' + pType). 
    END.
    
    mchLinea = TRIM(SUBSTR(mchLinea,minIndex + LENGTH('~/' + pType))).
    DO WHILE mchLinea EQ '':
      mchLinea = TRIM(cobPDF:readline()).
    END.
    
    mlgArreglo = LOOKUP(SUBSTRING(mchLinea,1,1),'~[,~<') GT 0.
    IF mlgArreglo THEN DO:
      DO WHILE INDEX(mchLinea,']') EQ 0 AND INDEX(mchLinea,'>>') EQ 0:
        mchLinea = mchLinea + cobPDF:readLine().
      END.
      minIndex = INDEX(mchLinea,']').
      IF minIndex EQ 0 OR minIndex GT INDEX(mchLinea,'>>') THEN
        minIndex = INDEX(mchLinea,'>>').
      mchLinea = SUBSTRING(mchLinea,2,minIndex - 1).
      IF SUBSTRING(mchLinea,1,1) EQ '<' THEN ASSIGN
        SUBSTRING(mchLinea,LENGTH(mchLinea),1) = ''
        SUBSTRING(mchLinea,1,1) = ''
      {&END}
      mchLinea = TRIM(mchLinea).
    END.
    ELSE DO:
      DO WHILE INDEX(mchLinea,'R') EQ 0:
        mchLinea = mchLinea + cobPDF:readLine().
      END.
      mchLinea = TRIM(mchLinea).
      mchLinea = GetListOfFonts(INT(ENTRY(1, mchLinea, " ")), INT(ENTRY(2, mchLinea, " "))).
    END.
    /* en este punto ya tengo todo lo que tengo que procesar */
    mchLinea = TRIM(REPLACE(mchLinea,"~/"," ")).
    mchLinea = REPLACE(mchLinea,"  "," ").  /* This removes double-spaces */
  
    DO minIndex = 1 TO NUM-ENTRIES(mchLinea," ") BY 4:
      ASSIGN minObj = INT(ENTRY(minIndex + 1, mchLinea, " "))
             minGen = INT(ENTRY(minIndex + 2, mchLinea, " ")) NO-ERROR.
  
      IF ERROR-STATUS:ERROR THEN NEXT.
      
      IF pType EQ 'Font' OR pType EQ 'DescendantFont' THEN
        agregarTipoDeLetra(minObj,minGen,pType,pObject,pGen,ENTRY(minIndex, mchLinea, " ")).
      ELSE
        AgregarRecurso(minObj,minGen,pType,pObject,pGen,ENTRY(minIndex, mchLinea, " ")).
    END.
    RETURN mchLinea.
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcessEntry */
  
  METHOD PUBLIC pdf.letras.TipoDeLetraExterna agregarTipoDeLetra(INPUT ipinResObj AS INTEGER, INPUT ipinResGen AS INTEGER, INPUT ipchResType AS CHARACTER,
    INPUT ipinParObj AS INTEGER, INPUT ipinParGen AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetraExterna NO-UNDO.
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.

    IF VALID-OBJECT(cobPaginaActual) THEN
      minPagina = cobPaginaActual:cinNumero.
    /* Skip resources that have already been added */
    FIND FIRST tt_Resource
                  WHERE tt_Resource.page_id    EQ minPagina /* igc - 10/21/05 */
                    AND tt_Resource.res_text   EQ "~/" + ipchNombre
                    AND tt_Resource.res_type   EQ ipchResType
                    AND tt_Resource.res_obj    EQ ipinResObj
                    AND tt_Resource.res_gen    EQ ipinResGen NO-LOCK NO-ERROR.
    IF AVAILABLE TT_Resource THEN
      mobFuente = CAST(tt_Resource.obRecurso,pdf.letras.TipoDeLetraExterna).
    ELSE DO:
      mobFuente = NEW pdf.letras.TipoDeLetraExterna(THIS-OBJECT,cobPDF).
      mobFuente:clgDescendiente = ipchResType EQ 'DescendantFont'.
      CREATE TT_Resource.
      ASSIGN TT_Resource.par_Obj    = ipinParObj
             TT_Resource.par_gen    = ipinParGen
             TT_Resource.page_id    = minPagina
             TT_Resource.res_type   = ipchResType
             TT_Resource.res_obj    = ipinResObj
             TT_Resource.res_gen    = ipinResGen
             TT_Resource.res_text   = "~/" + ipchNombre
             TT_Resource.res_old    = ""
             TT_Resource.obRecurso  = mobFuente
      {&END}
      mobFuente:LoadFromStream(ipinResObj,ipinResGen,ipchNombre).
    END.
    RETURN mobFuente.
  END METHOD.
  
  METHOD PUBLIC pdf.recursos.RecursoExistente agregarRecurso(INPUT ipinResObj AS INTEGER, INPUT ipinResGen AS INTEGER, INPUT ipchResType AS CHARACTER,
    INPUT ipinParObj AS INTEGER, INPUT ipinParGen AS INTEGER, INPUT ipchNombre AS CHARACTER):
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetraExterna NO-UNDO.
    
    /* este método es "reentrante" por lo que no puedo usar el buffer por omisión, sino uno específico en cada invocación */
    DEFINE BUFFER mbfRecurso FOR TT_Resource.
    
    IF VALID-OBJECT(cobPaginaActual) THEN
      minPagina = cobPaginaActual:cinNumero.
    /* Skip resources that have already been added */
    FIND FIRST mbfRecurso
                  WHERE mbfRecurso.page_id    EQ minPagina /* igc - 10/21/05 */
                    AND mbfRecurso.res_text   EQ (IF ipchResType = "Xobject" THEN
                                        "~/" + cchPDFID + ipchNombre
                                      ELSE 
                                        "~/" + ipchNombre )
/* el tipo de recurso puede ser diferente, según quién lo solicite, pero el número de objeto es único
                    AND mbfRecurso.res_type   EQ ipchResType */ 
                    AND mbfRecurso.res_obj    EQ ipinResObj
                    AND mbfRecurso.res_gen    EQ ipinResGen NO-LOCK NO-ERROR.
    IF AVAILABLE mbfRecurso THEN
      RETURN CAST(mbfRecurso.obRecurso,pdf.recursos.RecursoExistente).
  
    CREATE mbfRecurso.
    ASSIGN mbfRecurso.par_Obj    = ipinParObj
             mbfRecurso.par_gen    = ipinParGen
             mbfRecurso.page_id    = minPagina
             mbfRecurso.res_type   = ipchResType
             mbfRecurso.res_obj    = ipinResObj
             mbfRecurso.res_gen    = ipinResGen
             mbfRecurso.res_text   = IF ipchResType EQ "Xobject" THEN
                                        "~/" + cchPDFID + ipchNombre
                                      ELSE 
                                        "~/" + ipchNombre
             mbfRecurso.res_old    = IF ipchResType EQ "Xobject" THEN
                                        "~/" + ipchNombre
                                      ELSE "".
    
    CASE ipchResType:
      WHEN "ColorSpace" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.EspacioDeColores(THIS-OBJECT,cobPDF).
      WHEN "Shading" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.Difuminado(THIS-OBJECT,cobPDF).
      WHEN "XObject" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.ObjetoX(THIS-OBJECT,cobPDF).
      WHEN "ExtGState" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.EstadoExtendido(THIS-OBJECT,cobPDF).
      WHEN 'Function' THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.Funcion(THIS-OBJECT,cobPDF).
      WHEN "SeparationColorSpace" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.SeparacionDeEspacioDeColores(THIS-OBJECT,cobPDF).
      WHEN "ICCBased" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.BasadoEnICC(THIS-OBJECT,cobPDF).
      WHEN "DeviceCMYK" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.DispositivoCMYK(THIS-OBJECT,cobPDF).
      WHEN "R11" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.R11(THIS-OBJECT,cobPDF).
      WHEN "Indexed" THEN
        mbfRecurso.obRecurso = NEW pdf.recursos.Indexado(THIS-OBJECT,cobPDF).
    END CASE.
    CAST(mbfRecurso.obRecurso,pdf.recursos.RecursoExistente):LoadFromStream(ipinResObj,ipinResGen,ipchNombre).
    RETURN CAST(mbfRecurso.obRecurso,pdf.recursos.RecursoExistente).
  END METHOD.

  METHOD PUBLIC LONGCHAR ObjectContent(INPUT pObject AS INTEGER,INPUT pGen    AS INTEGER):
    cobPDF:preservarPos().
  
    FIND FIRST cttObjPos 
         WHERE cttObjPos.inObjeto EQ pObject
           AND cttObjPos.inGeneracion EQ pGen NO-LOCK NO-ERROR.
    IF AVAILABLE cttObjPos THEN
      RETURN cobPDF:contenido(cttObjPos.inPosicion).
    ELSE
      RETURN ?.
  
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* OutputObject */

  METHOD PUBLIC VOID ProcessFontDictionary(INPUT pObject  AS INTEGER,INPUT pGen     AS INTEGER,INPUT pTag     AS CHARACTER):
    DEFINE BUFFER B_TT_object   FOR cttObjetoExistente.
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetraExterna NO-UNDO.
    
    cobPDF:preservarPos().
  
    FOR EACH B_TT_Object WHERE B_TT_object.inObjeto EQ pObject
                           AND B_TT_object.inGeneracion EQ pGen
      BY B_TT_object.inNumero:
      IF B_TT_Object.chTipo NE '' THEN
        RETURN.

      B_TT_Object.chTipo = "~/Font".
      
      mobFuente = NEW pdf.letras.TipoDeLetraExterna(THIS-OBJECT,cobPDF).
      mobFuente:LoadFromStream(pObject,pGen,pTag).
      LEAVE.
    END. /* each */
  
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.   
  END METHOD. /* ProcessFontDictionary */

  METHOD PROTECTED VOID ProcessFieldKids(INPUT text-ptr AS CHARACTER, INPUT obj-name AS CHARACTER, INPUT obj-type AS CHARACTER, INPUT obj-disp AS CHARACTER):
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Obj     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Gen     AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE text-temp AS CHARACTER NO-UNDO.
  
    cobPDF:preservarPos().
  
    DO L_Loop = 1 TO NUM-ENTRIES(text-ptr," ") BY 3:
      ASSIGN L_Obj = INT(ENTRY(L_Loop, text-ptr, " "))
             L_Gen = INT(ENTRY(L_Loop + 1, text-ptr, " ")).
  
      ProcessFieldDictionary (L_Obj, L_Gen, obj-name, obj-type, obj-disp).
    END.
  
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD. /* ProcessFieldKids */
  METHOD PROTECTED CHARACTER GetListOfFonts(INPUT  pObj AS INTEGER, INPUT  pGen AS INTEGER):
    DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mlgArreglo AS LOGICAL NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
  
    cobPDF:preservarPos().
  
    IF setToPos(pObj,pGen) EQ 0 THEN
      RETURN ''.
    DO WHILE mchLinea EQ '':
      mchLinea = TRIM(cobPDF:ReadLine()).
      minIndex = INDEX(mchLinea,'obj').
      IF minIndex GT 0 THEN
        SUBSTRING(mchLinea,1,minIndex + 3) = ''.
    END.   
    mlgArreglo = LOOKUP(SUBSTRING(mchLinea,1,1),'[,<') GT 0.
    IF mlgArreglo THEN DO:
      DO WHILE INDEX(mchLinea,'>') EQ 0 AND INDEX(mchLinea,']') EQ 0:
        mchLinea = mchLinea + ' ' + cobPDF:ReadLine().
      END.
      minIndex = INDEX(mchLinea,']').
      IF minIndex EQ 0 OR minIndex GT INDEX(mchLinea,'>') THEN
        minIndex = INDEX(mchLinea,'>').
      mchLinea = SUBSTRING(mchLinea,1,minIndex - 1).
      IF SUBSTRING(mchLinea,1,1) EQ '<' THEN ASSIGN
        SUBSTRING(mchLinea,LENGTH(mchLinea),1) = ''
        SUBSTRING(mchLinea,1,2) = ''      
      {&END}
      ELSE
        SUBSTRING(mchLinea,1,1) = ''.      
    END.
    ELSE DO:
      DO WHILE INDEX(mchLinea,'R') EQ 0:
        mchLinea = mchLinea + ' ' + cobPDF:REadLine().
      END.
      /* devolver una lista "válida" sin nombre de elemento */
      mchLinea = '~/NN ' + SUBSTRING(mchLinea,1,INDEX(mchLinea,'R') - 2).
    END.
    RETURN mchLinea.    
    FINALLY:
      cobPDF:restaurarPos().
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC INT64 DetermineLength(INPUT ipobHijo AS pdf.IObjetoPDF, INPUT  pObj    AS INTEGER,INPUT  pGen    AS INTEGER):
    IF ipobHijo:cobDocumento NE THIS-OBJECT THEN
      RETURN ?.
    RETURN DetermineLength(pObj,pGen).
  END METHOD.
  METHOD PROTECTED INT64 DetermineLength(INPUT  pObj    AS INTEGER,INPUT  pGen    AS INTEGER):
    DEFINE BUFFER B_TT_Object FOR cttObjetoExistente.
    DEFINE VARIABLE minPagina AS INTEGER NO-UNDO.
    
    IF VALID-OBJECT(cobPaginaActual) THEN
      minPagina = cobPaginaActual:cinNumero.
  
    FOR EACH B_TT_Object WHERE B_TT_object.inObjeto EQ pObj
                           AND B_TT_object.inGeneracion EQ pGen
                           BY B_TT_object.inNumero:
      ASSIGN
        B_TT_Object.chTipo = "~/Length"
        B_TT_Object.inPagina  = minPagina
      {&END}

      RETURN cobPDF:getLength(B_TT_Object.inPosicion).  
    END.
    RETURN 0.
  END METHOD. /* DetermineLength */
  
  METHOD PUBLIC LONGCHAR StreamContent(INPUT pObject AS INTEGER, INPUT pGen    AS INTEGER):
    RETURN StreamContent(pObject,pGen,FALSE).
  END METHOD.
  METHOD PUBLIC LONGCHAR StreamContent(INPUT pObject AS INTEGER, INPUT pGen    AS INTEGER, INPUT iplgB64 AS LOGICAL):
    DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchTmp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mifCompresor AS pdf.compresores.ICompresor NO-UNDO.
    DEFINE VARIABLE mmpOut AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mliPos AS INT64 NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE minLen AS INTEGER NO-UNDO.
  
    cobPDF:preservarPos().
    mliPos = SetToPos(pObject,pGen).
    IF mliPos EQ 0 THEN
      RETURN ?.
  
    /* find the Length of the File */
    mchLinea = cobPDF:leerLength(mliPos).
    IF NUM-ENTRIES(mchLinea,' ') GT 1 THEN
      minLen = DetermineLength (INT(ENTRY(1,mchLinea,' ')),INT(ENTRY(2,mchLinea,' '))).
    ELSE
      minLen = INT(mchLinea) NO-ERROR.

    IF minLen EQ 0 THEN RETURN ?.
      
    IF clgCambiarMetodoCompresion THEN DO:
      cobPDF:SeekPos(mliPos).
      DO WHILE mchLinea EQ '':
        mchLinea = cobPDF:readline().
        /* Remove the Object Header info */
        minIndex = INDEX(mchLinea, " obj").
        IF minIndex GT 0 THEN
          SUBSTRING(mchLinea,1,minIndex + 4) = ''.
      END.
      REPEAT:
        IF INDEX(mchLinea,"~/Filter") > 0 AND clgCambiarMetodoCompresion THEN DO:
          mchTmp = SUBSTR(mchLinea,INDEX(mchLinea,"~/Filter") + 7).
          mchTmp = TRIM(REPLACE(mchTmp,"~/"," ")).
          mchTmp = ENTRY(1,mchTmp,' ').
          IF INDEX(mchTmp,'>') GT 0 THEN
            mchTmp = SUBSTRING(mchTmp,1,INDEX(mchTmp,'>') - 1).
          mifCompresor = compresorRegistrado(mchTmp).
          IF NOT VALID-OBJECT(mifCompresor) THEN
            UNDO, THROW NEW PDFException('El PDF utiliza un método de compresión no registrado: ' + mchTmp).
          LEAVE.
        END.
    
        /* no está garantizado que el objeto tenga realmente un stream.. */
        IF INDEX(mchLinea,"stream") GT 0 OR INDEX(mchLinea,'endobj') GT 0 THEN LEAVE.
        mchLinea = cobPDF:readline().
      END.
    END.
    
    IF VALID-OBJECT(mifCompresor) THEN DO ON ERROR UNDO, THROW:
      DEFINE VARIABLE mmpTemp AS MEMPTR NO-UNDO.
      mmpTemp = cobPDF:contenidoBINStream(mliPos,minLen).
      IF iplgB64 THEN DO:
        mmpOut = mifCompresor:DescomprimirMP(mmpTemp).
        RETURN BASE64-ENCODE(mmpOut).
      END.
      ELSE
        RETURN mifCompresor:Descomprimir(mmpTemp).
      FINALLY:
        SET-SIZE(mmpTemp) = 0.
      END FINALLY.
    END.
    ELSE DO ON ERROR UNDO, THROW:
      IF iplgB64 THEN DO:
        mmpOut = cobPDF:contenidoBINStream(mliPos,minLen).
        RETURN BASE64-ENCODE(mmpOut).
      END.
      ELSE
        RETURN cobPDF:contenidoStream(mliPos,minLen).
    END.
  
    FINALLY:
      cobPDF:restaurarPos().
      SET-SIZE(mmpOut) = 0.
    END FINALLY.                   
  END METHOD. /* OutputFile */
  
  METHOD PUBLIC LOGICAL establecerTipoYPagina(INPUT ipliHijo AS pdf.IObjetoPDF, INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER,
    INPUT ipchTipo AS CHARACTER, INPUT ipinPagina AS INTEGER):
    DEFINE BUFFER mbfOE FOR cttObjetoExistente.
    
    IF ipliHijo:cobDocumento NE THIS-OBJECT THEN
      RETURN FALSE.
    
    FIND mbfOE WHERE mbfOE.inObjeto EQ ipinObjeto AND mbfOE.inGeneracion EQ ipinGeneracion NO-ERROR.
    IF NOT AVAILABLE mbfOE THEN
      RETURN FALSE.
    IF mbfOE.chTipo NE '' THEN
      RETURN FALSE.    
    ASSIGN
      mbfOE.inPagina = ipinPagina
      mbfOE.chTipo = ipchTipo
    {&END}
    RETURN TRUE.
  END METHOD.

  METHOD PROTECTED OVERRIDE VOID generarXObjectRecursos():
    DEFINE VARIABLE mobPagina AS pdf.PaginaExistente NO-UNDO.
    SUPER:generarXObjectRecursos().
    /* Output External Pages */
    FOR EACH cttPaginaExistente:
      mobPagina = CAST(cttPaginaExistente.obPagina,pdf.PaginaExistente).
      cobDestino:agregar( '~/' + mobPagina:cchNombreXObject + " " + STRING(mobPagina:cinObjetoPDF) + " 0 R " + {&pdfSKIP}).
    END.
  END METHOD.
  METHOD PUBLIC VOID generarXObjectRecursos(INPUT ipobDocumento AS pdf.Documento):
    cobDocumentoDestino = ipobDocumento.
    generarXObjectRecursos().
    FINALLY:
      cobDocumentoDestino = ?.
    END FINALLY.
  END METHOD.
  METHOD PUBLIC VOID generarElementosExternos(INPUT ipobDocumento AS pdf.Documento):
    cobDocumentoDestino = ipobDocumento.
    generarElementosExternos().
    FINALLY:
      cobDocumentoDestino = ?.
    END FINALLY.
  END METHOD.
  METHOD PROTECTED OVERRIDE VOID generarElementosExternos():
    DEFINE VARIABLE mobPagina AS pdf.PaginaExistente NO-UNDO.
    generarLetrasExternas().
    generarEstadosExtendidos().
    generarEspacioDeColores().
    generarDifuminado().
    generarXObjects().
    generarDiccionarioRecursos().
    FOR EACH cttPaginaExistente:
      mobPagina = CAST(cttPaginaExistente.obPagina,pdf.PaginaExistente).
      mobPagina:generarXObject().
    END.
  END METHOD.
  METHOD PROTECTED VOID generarLetrasExternas():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetraExterna NO-UNDO.
  
    FOR EACH cttFuente BY cttFuente.inNumero:
      IF NOT TYPE-OF(cttFuente.obFuente,pdf.letras.TipoDeLetraExterna) THEN
        NEXT.
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetraExterna).
      IF mobFuente:clgDescendiente THEN
        NEXT.
      mobFuente:generarDefinicion().
      FOR EACH TT_Resource WHERE TT_Resource.res_type EQ "Font"
            AND TT_Resource.res_obj EQ mobFuente:cinObjeto
            AND TT_Resource.res_gen EQ mobFuente:cinGeneracion
            BY TT_Resource.res_text:
        ASSIGN
          TT_Resource.new_gen = 0
          TT_Resource.new_obj = mobFuente:cinObjetoPDF
        {&END}
      END.      
    END.
  END METHOD. /* LoadExternalFonts */
  
  METHOD PUBLIC pdf.letras.TipoDeLetraExterna letraExterna(INPUT ipinObjeto AS INTEGER, INPUT ipinGeneracion AS INTEGER):
    DEFINE BUFFER mbfRecurso FOR TT_Resource.
    
    FIND mbfRecurso WHERE mbfRecurso.res_obj EQ ipinObjeto AND mbfRecurso.res_gen EQ ipinGeneracion.
    IF mbfRecurso.res_type EQ 'Font' OR mbfRecurso.res_type EQ 'DescendantFont' THEN
      RETURN CAST(mbfRecurso.obRecurso,pdf.letras.TipoDeLetraExterna).
    RETURN ?.
  END METHOD.
  METHOD PROTECTED VOID generarDiccionarioRecursos():
    FOR EACH TT_Resource
       WHERE TT_Resource.res_type   = "Resource"
         BY TT_Resource.res_text:

      CAST(TT_Resource.obRecurso,pdf.recursos.Diccionario):generarDefinicion().
      ASSIGN
        TT_Resource.new_gen = 0
        TT_Resource.new_obj = CAST(TT_Resource.obRecurso,pdf.recursos.Diccionario):cinObjetoPDF
      {&END}
    END.
  END METHOD. /* Diccionario */
  METHOD PROTECTED VOID generarEstadosExtendidos():
    DEFINE VARIABLE l_text  AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE file-content  AS MEMPTR NO-UNDO.
    FOR EACH TT_Resource
       WHERE TT_Resource.res_type   = "ExtGState"
      BY TT_Resource.res_text:
      /* Put Out ExtGState Dictionary */
      CAST(TT_Resource.obRecurso,pdf.recursos.RecursoExistente):generarDefinicion().
      ASSIGN
        TT_Resource.new_gen = 0
        TT_Resource.new_obj = CAST(TT_Resource.obRecurso,pdf.recursos.RecursoExistente):cinObjetoPDF
      {&END}
    END. /* Each ExtGState Resource */
  END METHOD. /* LoadExtGStates */
  METHOD PROTECTED VOID generarEspacioDeColores():
    FOR EACH TT_Resource
       WHERE TT_Resource.res_type   = "ColorSpace"
         BY TT_Resource.res_text:

      /* Put Out ColorSpace Dictionary */
      CAST(TT_Resource.obRecurso,pdf.recursos.EspacioDeColores):generarDefinicion().
      ASSIGN
        TT_Resource.new_gen = 0
        TT_Resource.new_obj = CAST(TT_Resource.obRecurso,pdf.recursos.EspacioDeColores):cinObjetoPDF
      {&END}
    END. /* Each ColorSpace Resource */  
  END METHOD. /* LoadColorSpaces */
  METHOD PROTECTED VOID generarDifuminado():
    FOR EACH TT_Resource
       WHERE TT_Resource.res_type   = "Shading"
      BY TT_Resource.res_text:
      /* Put Out Function Dictionary */
      CAST(TT_Resource.obRecurso,pdf.recursos.Difuminado):generarDefinicion().
      ASSIGN
        TT_Resource.new_gen = 0
        TT_Resource.new_obj = CAST(TT_Resource.obRecurso,pdf.recursos.Difuminado):cinObjetoPDF
      {&END}
    END.
  END METHOD. /* LoadFunction */
  METHOD PROTECTED VOID generarXObjects():
    FOR EACH TT_Resource
       WHERE TT_Resource.res_type   = "XObject"
      BY TT_Resource.res_text:
      
        /* Put Out XObject Dictionary */
      CAST(TT_Resource.obRecurso,pdf.recursos.ObjetoX):generarDefinicion().
      ASSIGN
        TT_Resource.new_gen = 0
        TT_Resource.new_obj = CAST(TT_Resource.obRecurso,pdf.recursos.ObjetoX):cinObjetoPDF
      {&END}
    END.
  END METHOD. /* LoadExternalXObjects */
  
  METHOD PUBLIC pdf.PaginaExistente paginaExistente(INPUT ipinPagina AS INTEGER):
    FIND cttPaginaExistente WHERE cttPaginaExistente.inNumero EQ ipinPagina NO-ERROR.
    IF AVAILABLE cttPaginaExistente THEN
      RETURN CAST(cttPaginaExistente.obPagina,pdf.PaginaExistente).
    RETURN ?.
  END METHOD.
  
  METHOD PUBLIC INTEGER nuevoObjeto(INPUT ipinObjetoViejo AS INTEGER):
    DEFINE BUFFER mbfRecurso FOR TT_Resource.
    FOR EACH mbfRecurso WHERE mbfRecurso.res_obj EQ ipinObjetoViejo BY mbfRecurso.res_gen:
      RETURN mbfRecurso.new_obj.
    END.
    RETURN 0.
  END METHOD.

  METHOD PROTECTED OVERRIDE CHARACTER letrasEnRecursos():
    DEFINE VARIABLE mobFuente AS pdf.letras.TipoDeLetra NO-UNDO.
    DEFINE VARIABLE mchLetras AS CHARACTER NO-UNDO.
    FOR EACH cttFuente:
      mobFuente = CAST(cttFuente.obFuente,pdf.letras.TipoDeLetra).
      IF TYPE-OF(mobFuente,pdf.letras.TipoDeLetraExterna) THEN
        NEXT.
      mobFuente:asignarObjetoPDF().
      mchLetras = mchLetras + " " + mobFuente:cchNombreInterno + " " + STRING(mobFuente:cinObjetoPDF) + " 0 R".
    END.
    RETURN mchLetras.
  END METHOD.
  
    METHOD PROTECTED OVERRIDE INTEGER crearObjeto(INPUT ipchTipo AS CHARACTER,INPUT ipinNumero AS INTEGER):
      IF VALID-OBJECT(cobDocumentoDestino) THEN
        RETURN cobDocumentoDestino:crearObjeto(ipchTipo).
      RETURN SUPER:crearObjeto(ipchTipo,ipinNumero).
    END METHOD.
    METHOD PUBLIC OVERRIDE VOID inicioObjeto(INPUT ipobHijo AS pdf.IObjetoPDF, INPUT ipinObjeto AS INTEGER):
      IF VALID-OBJECT(cobDocumentoDestino) THEN
        cobDocumentoDestino:inicioObjeto(ipobHijo,ipinObjeto).
      ELSE
        SUPER:inicioObjeto(ipobHijo,ipinObjeto).      
    END METHOD.
  
END CLASS.