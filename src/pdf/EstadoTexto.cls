{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EstadoTexto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 11:05:20 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.EstadoTexto:
  DEFINE PUBLIC EVENT Rotacion VOID (INPUT ipobEstado AS pdf.EstadoTexto).
  DEFINE PUBLIC EVENT Inclinacion VOID (INPUT ipobEstado AS pdf.EstadoTexto).
  DEFINE PUBLIC EVENT Espejado VOID (INPUT ipobEstado AS pdf.EstadoTexto).
  DEFINE PUBLIC EVENT CambioDeLetra VOID (INPUT ipobEstdo AS pdf.EstadoTexto).
  DEFINE PUBLIC EVENT CambioDeColor VOID (INPUT ipobEstado AS pdf.EstadoTexto).
  DEFINE PUBLIC EVENT CambioDePosicion VOID (INPUT ipobEstado AS pdf.EstadoTexto).
   
  DEFINE PROTECTED PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobPosicion AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColor AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobLetra AS pdf.letras.TipoDeLetraDocumento NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cenEstiloTexto AS pdf.tipos.EstiloTexto NO-UNDO
    GET: 
      IF NOT VALID-OBJECT(cenEstiloTexto) THEN
        cenEstiloTexto = NEW pdf.tipos.EstiloTexto().
      RETURN cenEstiloTexto.
    END GET.
    PRIVATE SET(INPUT ipenRender AS pdf.tipos.EstiloTexto):
      IF ipenRender EQ ? THEN
        DELETE OBJECT cenEstiloTexto NO-ERROR.
      cenEstiloTexto = ipenRender.
    END SET. /* pdf_text_render */
    
  DEFINE PUBLIC PROPERTY cinAngulo AS INTEGER NO-UNDO INITIAL 0
    GET.
    SET(INPUT ipinAngulo AS INTEGER):
      DEFINE VARIABLE minPrev AS INTEGER NO-UNDO.
      /* lo ajusto a  -360° < ipinAngulo < 360° */
      minPrev = pdf.utiles.Trigonometria:ajustarGrados(ipinAngulo).
      IF ipinAngulo LT 0 THEN DO WHILE minPrev GT 0:
        minPrev = minPrev - 360.
      END.
      ipinAngulo = minPrev.
      minPrev = cinAngulo.
      cinAngulo = ipinAngulo.
      IF minPrev NE cinAngulo THEN
        Rotacion:Publish(THIS-OBJECT).
    END SET.
  /*
  de 89° a -89°
  */
  DEFINE PUBLIC PROPERTY cinAnguloLetra AS INTEGER NO-UNDO INITIAL 0
    GET.
    SET(INPUT ipinAngulo AS INTEGER):
      DEFINE VARIABLE minPrev AS INTEGER NO-UNDO.
      /* lo ajusto a  -360° < ipinAngulo < 360° */
      minPrev = pdf.utiles.Trigonometria:ajustarGrados(ipinAngulo).
      IF ipinAngulo LT 0 THEN DO WHILE minPrev GT 0:
        minPrev = minPrev - 360.
      END.
      ipinAngulo = minPrev.
      /* lo ajusto a -90° < ipinAngulo < 90° */
      IF ipinAngulo LE -90 THEN
        ipinAngulo = -89.
      IF ipinAngulo GE 90 THEN
        ipinAngulo = 89.
      minPrev = cinAnguloLetra.
      cinAnguloLetra = ipinAngulo.
      IF minPrev NE cinAnguloLetra THEN
        Inclinacion:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY clgEspejarEnX AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET(INPUT iplgEspejar AS LOGICAL):
      DEFINE VARIABLE mlgPrevio AS LOGICAL NO-UNDO.
      mlgPrevio = clgEspejarEnX.
      clgEspejarEnX = iplgEspejar.
      IF iplgEspejar NE mlgPrevio THEN
        Espejado:Publish(THIS-OBJECT).
    END SET.
  DEFINE PUBLIC PROPERTY clgEspejarEnY AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET(INPUT iplgEspejar AS LOGICAL):
      DEFINE VARIABLE mlgPrevio AS LOGICAL NO-UNDO.
      mlgPrevio = clgEspejarEnY.
      clgEspejarEnY = iplgEspejar.
      IF iplgEspejar NE mlgPrevio THEN
        Espejado:Publish(THIS-OBJECT).
    END SET.
    
  CONSTRUCTOR EstadoTexto(INPUT ipobDocumento AS pdf.Documento):
    cobDocumento = ipobDocumento.
    cobColor = NEW pdf.utiles.Color().
    cobColor:Copiar(cobDocumento:cobColorTexto).
    cobPosicion = NEW pdf.utiles.Punto().
    cobLetra = NEW pdf.letras.TipoDeLetraDocumento(ipobDocumento).
    cobLetra:cchNombre = cobDocumento:cobLetraActual:cchNombre.
    cobLetra:cdePuntos = cobDocumento:cobLetraActual:cdePuntos.
    /* EVENTOS */
    cobLetra:CambioLetra:Subscribe(InformarCambioLetra).
    cobLetra:CambioPuntos:Subscribe(InformarCambioLetra).
    cobColor:Cambio:Subscribe(InformarCambioColor).
    cobPosicion:CambioEnX:Subscribe(InformarCambioPosX).
    cobPosicion:CambioEnY:Subscribe(InformarCambioPosY).
  END CONSTRUCTOR.
  DESTRUCTOR EstadoTexto():
    DELETE OBJECT cobColor NO-ERROR.
    DELETE OBJECT cobPosicion NO-ERROR.
    DELETE OBJECT cobLetra NO-ERROR.
    cenEstiloTexto = ?.
  END DESTRUCTOR.
  
  METHOD PROTECTED VOID InformarCambioLetra(INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento):
    IF ipobLetra NE cobLetra THEN
      UNDO, THROW NEW PDFException('Solo pueden procesarse los cambios de la letra del estado de texto').
    CambioDeLetra:Publish(THIS-OBJECT).
  END METHOD.
  METHOD PROTECTED VOID InformarCambioColor(INPUT ipobColor AS pdf.utiles.Color):
    IF ipobColor NE cobColor THEN
      UNDO, THROW NEW PDFException('Solo pueden procesarse los cambios de color del estado de texto').
    CambioDeColor:Publish(THIS-OBJECT).
  END METHOD.
  METHOD PROTECTED VOID InformarCambioPosX(INPUT ipobPunto AS pdf.utiles.Punto):
    IF ipobPunto NE cobPosicion THEN
      UNDO, THROW NEW PDFException('Solo pueden procesarse los cambios de posición del estado de texto').
    IF ipobPunto:cinXPrevio NE ipobPunto:cinX THEN
      CambioDePosicion:Publish(THIS-OBJECT).
  END METHOD.
  METHOD PROTECTED VOID InformarCambioPosY(INPUT ipobPunto AS pdf.utiles.Punto):
    IF ipobPunto NE cobPosicion THEN
      UNDO, THROW NEW PDFException('Solo pueden procesarse los cambios de posición del estado de texto').
    IF ipobPunto:cinYPrevio NE ipobPunto:cinY THEN
      CambioDePosicion:Publish(THIS-OBJECT).
  END METHOD.
  
  METHOD PUBLIC VOID Copiar(INPUT ipobDesde AS pdf.EstadoTexto):
    cobPosicion:Copiar(ipobDesde:cobPosicion).
    cobColor:Copiar(ipobDesde:cobColor).
    cobLetra:Copiar(ipobDesde:cobLetra).
    cenEstiloTexto = ipobDesde:cenEstiloTexto.
    cinAngulo = ipobDesde:cinAngulo.
    cinAnguloLetra = ipobDesde:cinAnguloLetra.
    clgEspejarEnX = ipobDesde:clgEspejarEnX.
    clgEspejarEnY = ipobDesde:clgEspejarEnY.
  END METHOD.
END CLASS.