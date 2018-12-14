{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : ImagenJPG
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 11 08:26:32 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.
USING pdf.imagenes.Imagen.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/* The following defines are used to determine the JPEG Image Height and Width */
&GLOBAL-DEFINE M_SOF0  "0xC0"   /* Start Of Frame N */
&GLOBAL-DEFINE M_SOF1  "0xC1"   /* N indicates which compression process */
&GLOBAL-DEFINE M_SOF2  "0xC2"       /* Only SOF0-SOF2 are now in common use */
&GLOBAL-DEFINE M_SOF3  "0xC3"
&GLOBAL-DEFINE M_SOF5  "0xC5"   /* NB: codes C4 and CC are NOT SOF markers */
&GLOBAL-DEFINE M_SOF6  "0xC6"
&GLOBAL-DEFINE M_SOF7  "0xC7"
&GLOBAL-DEFINE M_SOF9  "0xC9"
&GLOBAL-DEFINE M_SOF10 "0xCA"
&GLOBAL-DEFINE M_SOF11 "0xCB"
&GLOBAL-DEFINE M_SOF13 "0xCD"
&GLOBAL-DEFINE M_SOF14 "0xCE"
&GLOBAL-DEFINE M_SOF15 "0xCF"
&GLOBAL-DEFINE M_SOI   "0xD8"   /* Start Of Image (beginning of datastream) */
&GLOBAL-DEFINE M_EOI   "0xD9"   /* End Of Image (end of datastream) */
&GLOBAL-DEFINE M_SOS   "0xDA"   /* Start Of Scan (begins compressed data) */
&GLOBAL-DEFINE M_APP0  "0xE0"   /* Application-specific marker, type N */
&GLOBAL-DEFINE M_APP12 "0xEC"   /* (we don't bother to list all 16 APPn's) */
&GLOBAL-DEFINE M_COM   "0xFE"   /* COMment */
&GLOBAL-DEFINE M_MARK  "0xFF"   /* Marker */

CLASS pdf.imagenes.ImagenJPG INHERITS Imagen:
  
  DEFINE PRIVATE VARIABLE cliImageByte AS INT64 NO-UNDO.
  
  METHOD PROTECTED CHARACTER hex(INPUT asc-value AS INTEGER):
    DEF VAR j AS INT  NO-UNDO.
    DEF VAR h AS CHAR NO-UNDO.
  
    DO WHILE TRUE:
      j = asc-value MODULO 16.
      h = (IF j < 10 THEN STRING(j) ELSE CHR(ASC("A") + j - 10)) + h.
      IF asc-value < 16 THEN LEAVE.
        asc-value = (asc-value - j) / 16.
    END.
  
    IF LENGTH(h, "character":u) = 1 THEN
      h = "0" + h.
  
    RETURN ("0x" + h).
  END METHOD. /* hex */
  
  METHOD PROTECTED LOGICAL skip_variable():
    DEFINE VARIABLE L_Length  AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
  
    L_length = next2bytes().
  
    DO L_Loop = 1 TO (L_Length - 2):
      nextbyte().
    END. /* Loop */
  END METHOD. /* skip_variable */
  
  METHOD PROTECTED CHARACTER hex2(INPUT asc-value AS INTEGER):
    DEF VAR j AS INT  NO-UNDO.
    DEF VAR h AS CHAR NO-UNDO.
  
    DO WHILE TRUE:
      j = asc-value MODULO 16.
      h = (IF j < 10 THEN STRING(j) ELSE CHR(ASC("A") + j - 10)) + h.
      IF asc-value < 16 THEN LEAVE.
      asc-value = (asc-value - j) / 16.
    END.
  
    IF LENGTH(h) = 1 THEN
      h = "0" + h.
  
    RETURN h.
  END METHOD.
  
  METHOD PROTECTED INTEGER nextbyte():
    cliImageByte = cliImageByte + 1.
    RETURN GET-BYTE(cmpData,cliImageByte).
  END METHOD. /* nextbyte */
  
  METHOD PROTECTED LOGICAL first_marker():
    DEFINE VARIABLE L_c1        AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_c2        AS INTEGER NO-UNDO.
  
    L_c1 = nextbyte().
    L_c2 = nextbyte().
  
    IF hex(L_c1) <> {&M_Mark} AND hex(L_c2) <> {&M_SOI} THEN
      RETURN FALSE.
    ELSE RETURN TRUE.
  END METHOD.
  
  METHOD PROTECTED INTEGER next_marker ():
    DEFINE VARIABLE L_data    AS RAW NO-UNDO.
  
    LENGTH(L_data) = 1.
    DEFINE VARIABLE L_c       AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_discard AS INTEGER NO-UNDO.
  
    L_c = nextbyte().
    DO WHILE hex(L_c) <> {&M_MARK}:
      L_discard = L_discard + 1.
      L_c = nextbyte().
    END. /* <> 0xFF */
  
    DO WHILE hex(L_c) = {&M_MARK}:
      L_c = nextbyte().
    END.
  
    RETURN L_c.
  END METHOD. /* next_marker */
  
  METHOD PROTECTED INTEGER next2bytes():
    DEFINE VARIABLE L_c1      AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_c2      AS INTEGER NO-UNDO.
  
    L_c1 = nextbyte().
    L_c2 = nextbyte().
  
    RETURN INT(L_c1 * 256 + L_c2).
  END METHOD. /* next2bytes */
  METHOD PROTECTED LOGICAL process_SOF():
    DEFINE VARIABLE L_Length  AS INTEGER NO-UNDO.
  
    next2bytes().       /* Skip Length */
    nextbyte().         /* Skip Data Precision */
    cinAlto = next2bytes().
    cinAncho  = next2bytes().  
  END METHOD. /* process_SOF */  
  
  METHOD PROTECTED OVERRIDE VOID obtenerInformacionImagen():
    DEFINE VARIABLE iFileSize     AS INTEGER NO-UNDO.
    DEFINE VARIABLE pdf_marker    AS INTEGER NO-UNDO.

    FILE-INFO:FILE-NAME = cchArchivo.
    iFileSize = FILE-INFO:FILE-SIZE.
    cliImageByte = 0.

    SET-SIZE(cmpData) = iFileSize.
    COPY-LOB FROM FILE cchArchivo TO cmpData.

    IF NOT first_marker() THEN
      UNDO, THROW NEW PDFException("Cannot read image data!").

    DO WHILE TRUE:
      pdf_marker = next_marker().

      CASE hex(pdf_marker):
        WHEN {&M_SOF0} OR WHEN {&M_SOF1} OR WHEN {&M_SOF2} OR WHEN {&M_SOF3}
        OR WHEN {&M_SOF5} OR WHEN {&M_SOF6} OR WHEN {&M_SOF7} OR WHEN {&M_SOF9}
        OR WHEN {&M_SOF10} OR WHEN {&M_SOF11} OR WHEN {&M_SOF13}
        OR WHEN {&M_SOF14} OR WHEN {&M_SOF15} THEN DO:
          process_SOF().
          LEAVE.
        END.
        WHEN {&M_SOS} OR WHEN {&M_EOI} THEN
          LEAVE.
        OTHERWISE
          skip_variable().
      END CASE.
    END. /* true loop */
  
    FINALLY:
      cliImageByte = 0.
    END FINALLY.    
  END METHOD. 

  CONSTRUCTOR PUBLIC ImagenJPG(INPUT ipobDocumento AS pdf.Documento, INPUT ipchNombre AS CHARACTER, INPUT ipchArchivo AS CHARACTER):
    SUPER(ipobDocumento,ipchNombre, ipchArchivo).
  END CONSTRUCTOR.
END CLASS.