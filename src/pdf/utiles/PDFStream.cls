{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : PDFStream
    Purpose     : Abstracción para el manejo de bajo nivel de un archivo PDF
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 07:46:36 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

&SCOPED-DEFINE BUFF-SIZE 4096

CLASS pdf.utiles.PDFStream:
  DEFINE PRIVATE STREAM stIn.
  DEFINE PRIVATE VARIABLE cmpBuffer AS MEMPTR NO-UNDO.
  DEFINE PRIVATE VARIABLE cliBuffPos AS INT64 INITIAL 1 NO-UNDO.
  DEFINE PRIVATE VARIABLE cliStPos AS INT64 INITIAL 0 NO-UNDO.
  DEFINE PRIVATE VARIABLE cinLeido AS INTEGER NO-UNDO.
  
  DEFINE PRIVATE TEMP-TABLE cttStPos NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD inPosicion AS INT64
  {&END}
  
  METHOD PRIVATE INTEGER siguientePos():
    FOR EACH cttStPos BY inNumero DESC:
      RETURN cttStPos.inNumero + 1.
    END.
    RETURN 1.
  END METHOD.
  
  METHOD PUBLIC INTEGER preservarPos():
    DEFINE VARIABLE minSiguiente AS INTEGER NO-UNDO.
    minSiguiente = siguientePos().
    CREATE cttStPos.
    ASSIGN
      cttStPos.inNumero = minSiguiente
      /* la posición en cmpBuffer es siempre 1 más que en cstIn */
      cttStPos.inPosicion = cliStPos - cinLeido + cliBuffPos - 1
    {&END}
    RETURN minSiguiente.
  END METHOD.
  METHOD PUBLIC INTEGER restaurarPos():
    DEFINE VARIABLE minUltimo AS INTEGER NO-UNDO.
    FOR EACH cttStPos BY cttStPos.inNumero DESC:
      minUltimo = cttStPos.inNumero.
      IF cttStPos.inPosicion GE cliStPos
        OR cttStPos.inPosicion LT (cliStPos - cinLeido) THEN DO:
        SEEK STREAM stIn TO cttStPos.inPosicion.
        ASSIGN
          cliBuffPos = 1
          cliStPos = cttStPos.inPosicion
          cinLeido = 0
        {&END}
      END.
      ELSE DO: /* la posición en cliBuffPos es siempre uno más de la posición en el STREAM, ya que stIn empieza en 0 y cmpBuffer en 1 */
        cliBuffPos = cinLeido - (cliStPos - cttStPos.inPosicion) + 1. 
      END.
      DELETE cttStPos.
      LEAVE.
    END.
    RETURN minUltimo.
  END METHOD.
   
  DEFINE PUBLIC PROPERTY cchArchivo AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET.
    
  CONSTRUCTOR PDFStream(INPUT ipchArchivo AS CHARACTER):
    FILE-INFO:FILE-NAME = ipchArchivo.
    IF FILE-INFO:FULL-PATHNAME EQ ? THEN
      UNDO, THROW NEW PDFException('No existe el PDF').      
    cchArchivo = ipchArchivo.
    INPUT STREAM stIn FROM VALUE(ipchArchivo) BINARY NO-ECHO NO-CONVERT.
    SET-SIZE(cmpBuffer) = {&BUFF-SIZE}.
    cliBuffPos = 1.
    cinLeido = 0.
  END CONSTRUCTOR.
  
  DESTRUCTOR PDFStream():
    INPUT STREAM stIn CLOSE.
    SET-SIZE(cmpBuffer) = 0.
  END DESTRUCTOR.

  METHOD PUBLIC LOGICAL UpLine():
    DEFINE VARIABLE minFound AS INTEGER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE minByte AS INTEGER NO-UNDO.
    DEFINE VARIABLE minLast AS INTEGER NO-UNDO.

    Read-Loop:
    REPEAT ON ENDKEY UNDO, LEAVE:
      IF cliBuffPos EQ 1 THEN DO:
        IF cinLeido NE 0 THEN
          cliStPos = (cliStPos - 2 * {&BUFF-SIZE}).
        ELSE
          cliStPos = (cliStPos - {&BUFF-SIZE}).
        IF cliStPos LT 0 THEN
          cliStPos = 0.
        SEEK STREAM stIn TO cliStpos.
        IMPORT STREAM stIn cmpBuffer.
        ASSIGN
          cinLeido = SEEK(stIn) - cliStPos
          cliStPos = SEEK(stIn)
          cliBuffPos = cinLeido
        {&END}
      END.
      DO minIndex = cliBuffPos TO 1 BY -1:
        minByte = GET-BYTE(cmpBuffer,minIndex).
        /* Find the first linefeed */
        IF (minByte EQ 10) OR (minByte EQ 13) THEN DO:
          IF minFound NE 1 OR minByte NE 13 OR minLast NE 10 THEN /* saltear el 13, si está presente antes del 10 */
            minFound = minFound + 1.
          minLast = minByte.
          IF minFound EQ 2 THEN DO:
            cliBuffPos = minIndex + 1.
            LEAVE Read-Loop.
          END.
        END.
      END.
      cliBuffPos = 1.
    END. /* Read Loop */

    RETURN minFound EQ 2.
  END METHOD. /* UpLine */

  METHOD PUBLIC CHARACTER ReadLine():
    DEFINE VARIABLE minIndex  AS INTEGER NO-UNDO.
    DEFINE VARIABLE minByte AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchLine AS CHARACTER NO-UNDO.

    Read-Loop:
    REPEAT ON ENDKEY UNDO,LEAVE:
      IF cinLeido EQ 0 OR cliBuffPos GE cinLeido THEN DO:
        IMPORT STREAM stIn cmpBuffer.
        ASSIGN
          cinLeido = SEEK(stIn) - cliStPos
          cliStPos = SEEK(stIn)
          cliBuffPos = 1
        {&END}
      END.
      DO minIndex = cliBuffPos TO cinLeido:
        minByte = GET-BYTE(cmpBuffer,minIndex). 
        IF (minByte EQ 10 OR minByte EQ 13) THEN DO:
          IF minByte EQ 13 THEN DO:
            IF minIndex EQ cinLeido THEN DO:
              mchLine = mchLine + GET-STRING(cmpBuffer,cliBuffPos,minIndex - cliBuffPos + 1).
              cliBuffPos = minIndex + 1. /* por las dudas que la lectura falle */
              IMPORT STREAM stIn cmpBuffer.
              ASSIGN
                cinLeido = SEEK(stIn) - cliStPos
                cliStPos = SEEK(stIn)
                cliBuffPos = 1
                minIndex = 1
              {&END}
            END.
            IF GET-BYTE(cmpBuffer,minIndex + 1) EQ 10 THEN
              minIndex = minIndex + 1.
          END.
          mchLine = mchLine + GET-STRING(cmpBuffer,cliBuffPos,minIndex - cliBuffPos + 1).
          cliBuffPos = minIndex + 1.
          LEAVE Read-Loop.
        END.
      END.
      mchLine = mchLine + GET-STRING(cmpBuffer,cliBuffPos,cinLeido - cliBuffPos + 1).
      cliBuffPos = cinLeido.
    END.

    RETURN TRIM(mchLine).
  END METHOD. /* ReadLine */
  
  METHOD PUBLIC INT64 SeekPos(INPUT ipliPosicion AS INT64):
    IF ipliPosicion NE ? THEN DO:
      IF ipliPosicion GT cliStPos
          OR ipliPosicion LT (cliStPos - cinLeido) THEN DO:
        SEEK STREAM stIn TO ipliPosicion.
        ASSIGN
          cliStPos = ipliPosicion
          cliBuffPos = 1
          cinLeido = 0
        {&END}
      END.
      ELSE
        cliBuffPos = cinLeido - (cliStPos - ipliPosicion) + 1.
    END.
    RETURN cliStPos - cinLeido + cliBuffPos - 1.
  END METHOD.
  
  METHOD PUBLIC INT64 SeekEnd():
    SEEK STREAM stIn TO END.
    cliStPos = SEEK(stIn).
    cliBuffPos = 1.
    cinLeido = 0.
    RETURN cliStPos.
  END METHOD.
  
  METHOD PUBLIC INT64 SeekSet():
    SEEK STREAM stIn TO 0.
    cliStPos = 0.
    cliBuffPos = 1.
    cinLeido = 0.
    RETURN 0.
  END METHOD.
  
  METHOD PUBLIC CHARACTER ParseText(INPUT  pIn-Text  AS CHARACTER,INPUT  pReplace  AS CHARACTER):
    /* This removes any characters previous to the Replace text */
    pIn-Text = SUBSTR(pIn-Text, INDEX(pIn-Text,pReplace) + LENGTH(pReplace)).
    ASSIGN pIn-Text = REPLACE(pIn-Text,"~\(","&paraL;")
         pIn-Text = REPLACE(pIn-Text,"~\)","&paraR;")
         pIn-Text = TRIM(REPLACE(pIn-Text,pReplace,""))
    {&END}
    pIn-Text = SUBSTR(pIn-Text,1,INDEX(pIn-Text,')') ).
    ASSIGN
         pIn-Text = REPLACE(pIn-Text,"(","")
         pIn-Text = REPLACE(pIn-Text,")","")
         pIn-Text = REPLACE(pIn-Text,"&paraL;","(")
         pIn-Text = REPLACE(pIn-Text,"&paraR;",")")
     {&END}
    RETURN pIn-Text.
  END METHOD. /* ParseText */

  METHOD PUBLIC VOID ProcessBoxObject(INPUT ipobArea AS pdf.utiles.Area):
    DEFINE VARIABLE text-ptr  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE pMediaBox AS CHARACTER NO-UNDO.
    
    DO WHILE TRUE:
      text-ptr = readline().
      IF TRIM(text-ptr) BEGINS "[" THEN
        ASSIGN pMediaBox = REPLACE( text-ptr, "[", "")
               pMediaBox = REPLACE( pMediaBox, "]", "")
               pMediaBox = TRIM(pMediaBox).

      IF INDEX(text-ptr,"endobj") > 0 THEN LEAVE.
    END.
    ASSIGN 
      ipobArea:cinIzquierda = INT(ENTRY(1,pMediaBox, " "))
      ipobArea:cinAbajo = INT(ENTRY(2,pMediaBox, " "))
      ipobArea:cinDerecha = INT(ENTRY(3,pMediaBox, " "))
      ipobArea:cinArriba = INT(ENTRY(4,pMediaBox, " "))
    {&END}
  END METHOD.  /* ProcessMediaBox */
  
  METHOD PUBLIC LONGCHAR contenidoStream(INPUT ipliPosicion AS INT64, INPUT ipliLen AS INT64):
    DEFINE VARIABLE mlcContenido AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE mmpContenido AS MEMPTR NO-UNDO.
    DEFINE VARIABLE text-ptr AS CHARACTER NO-UNDO.
    
    IF ipliLEN LE 0 THEN
      RETURN ''.

    seekPos(ipliPosicion).
    /* Get Content */
    CONTENTS:
    DO WHILE TRUE:
      text-ptr = readline().

      IF INDEX(text-ptr,"stream") > 0 THEN DO ON ERROR UNDO, THROW:
        SET-SIZE(mmpContenido) = ipliLen.
        IF INDEX(text-ptr,'stream') LT LENGTH(text-ptr) - 6 THEN          
          SEEK STREAM stIn TO (seekPos(?) - (LENGTH(text-ptr) - INDEX(text-ptr,'stream') - 6)).
        ELSE
          SEEK STREAM stIn TO seekPos(?).
        IMPORT STREAM stIn mmpContenido.
        COPY-LOB mmpContenido TO mlcContenido.
        LEAVE CONTENTS.
        FINALLY:
          SET-SIZE(mmpContenido) = 0.
          SEEK STREAM stIn TO cliStPos.
        END FINALLY.
      END.
      /* Somehow we misssed the content? */
      IF INDEX(text-ptr,"endobj") > 0 THEN DO:
        LEAVE CONTENTS.
      END.
    END. /* While True */
    RETURN mlcContenido.
  END METHOD.

  METHOD PUBLIC MEMPTR contenidoBINStream(INPUT ipliPosicion AS INT64, INPUT ipliLen AS INT64):
    DEFINE VARIABLE mmpContenido AS MEMPTR NO-UNDO.
    DEFINE VARIABLE text-ptr AS CHARACTER NO-UNDO.

    SeekPos(ipliPosicion).
    /* Get Content */
    CONTENTS:
    DO WHILE TRUE:
      text-ptr = readline().

      IF INDEX(text-ptr,"stream") > 0 THEN DO ON ERROR UNDO, THROW:
        SET-SIZE(mmpContenido) = ipliLen.
        IF INDEX(text-ptr,'stream') LT LENGTH(text-ptr) - 6 THEN          
          SEEK STREAM stIn TO (seekPos(?) - (LENGTH(text-ptr) - INDEX(text-ptr,'stream') - 6)).
        ELSE
          SEEK STREAM stIn TO seekPos(?).
        IMPORT STREAM stIn mmpContenido.
        LEAVE CONTENTS.
        FINALLY:
          SEEK STREAM stIn TO cliStPos.
        END FINALLY.
      END.

      /* Somehow we misssed the content? */
      IF INDEX(text-ptr,"endobj") > 0 THEN DO:
        LEAVE CONTENTS.
      END.
    END. /* While True */
    RETURN mmpContenido.
  END METHOD.
  
  METHOD PUBLIC LONGCHAR contenido(INPUT ipinPosicion AS INT64):
    DEFINE VARIABLE mlcContenido AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE text-line AS CHARACTER NO-UNDO.
    
    SeekPos(ipinPosicion).
  
    /* text-line = readline().  /* Skip the Object Header */ */
     REPEAT:
       text-line = readline().
  
       /* Remove the Object Header info */
       IF INDEX(text-line, " obj") GT 0 THEN
         text-line = SUBSTRING(text-line,INDEX(text-line," obj") + 4).
  
       IF INDEX(text-line,"endobj") > 0 THEN LEAVE.
       
       IF INDEX(text-line,'stream') GT 0 THEN DO:
         mlcContenido = mlcContenido + SUBSTRING(text-line,1,INDEX(text-line,'stream') - 1).
         LEAVE.
       END.
  
       mlcContenido = mlcContenido + ' ' + text-line.
     END.
     RETURN mlcContenido.
  END METHOD.
  
  METHOD PUBLIC CHARACTER leerLength(INPUT ipliPosicion AS INT64):
    DEFINE VARIABLE mchLinea AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchEntry AS CHARACTER NO-UNDO.
    
    seekPos(ipliPosicion).
    DO WHILE mchLinea EQ '':
      mchLinea = readline().
      /* Remove the Object Header info */
      minIndex = INDEX(mchLinea, " obj").
      IF minIndex GT 0 THEN
        SUBSTRING(mchLinea,1,minIndex + 4) = ''.
    END.
    /* find the Length of the File */
    DO WHILE mchLinea NE '':
      IF INDEX(mchLinea,"~/Length ") > 0 THEN DO:
        mchLinea = SUBSTR(mchLinea,INDEX(mchLinea,"~/Length")).
        mchLinea = TRIM(REPLACE(mchLinea,"~/"," ")).
        mchEntry = ENTRY(4, mchLinea, " ") NO-ERROR.
        IF NOT mchEntry BEGINS "R" THEN DO:
          mchEntry = ENTRY(2, mchLinea, " ").
          DO minIndex = LENGTH(mchEntry) TO 1 BY -1:
            IF LOOKUP(SUBSTRING(mchEntry,minIndex,1),'0,1,2,3,4,5,6,7,8,9') EQ 0 THEN
              SUBSTRING(mchEntry,minIndex,1) = ''.
            ELSE
              LEAVE.
          END.
          RETURN mchEntry.
        END.
        ELSE
          RETURN ENTRY(2, mchLinea, " ") + ' ' + ENTRY(3, mchLinea, " ") + ' R'.
      END.
      /* no está garantizado que el objeto tenga realmente un stream.. */
      IF INDEX(mchLinea,"stream") GT 0 OR INDEX(mchLinea,'endobj') GT 0 THEN LEAVE.
      mchLinea = readline().
    END.
    RETURN '0'.
  END METHOD.

  METHOD PUBLIC INT64 GetLength(INPUT  ipinPosicion AS INT64):
    DEFINE VARIABLE orig-ptr    AS INTEGER NO-UNDO.
    DEFINE VARIABLE text-ptr    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE pLength AS INT64 NO-UNDO.
  
    preservarPos().
    SeekPos(ipinPosicion).
    /* Find Length */
    text-ptr = readline().
    pLength = INT(readline()) NO-ERROR.

    RETURN pLength.  
    FINALLY:
      restaurarPos().
    END FINALLY.
  END METHOD. /* DetermineLength */  
END CLASS.