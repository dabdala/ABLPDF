{nsra/utiles/runlevel.i} 
 /*------------------------------------------------------------------------
    File        : Color
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 03 10:31:00 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.Color:
  DEFINE PUBLIC EVENT Cambio VOID(INPUT ipobColor AS pdf.utiles.Color).
  
  DEFINE PROTECTED VARIABLE clgModificando AS LOGICAL NO-UNDO. 
  
  METHOD PROTECTED DECIMAL ajustarComponente(INPUT ipdeComponente AS DECIMAL):
    IF ipdeComponente LT 0 THEN
      ipdeComponente = 0.
    ELSE IF ipdeComponente GT 1 THEN DO:
      ipdeComponente = ipdeComponente / 255.
      IF ipdeComponente GT 1 THEN
        ipdeComponente = 1.
    END.
    RETURN ipdeComponente.
  END METHOD.
   
  DEFINE PUBLIC PROPERTY cdeRojo AS DECIMAL NO-UNDO
    GET.
    SET(INPUT ipdeNuevo AS DECIMAL):
      DEFINE VARIABLE mdeActual AS DECIMAL NO-UNDO.
      mdeActual = cdeRojo.
      cdeRojo = ajustarComponente(ipdeNuevo).
      IF NOT clgModificando AND ipdeNuevo NE mdeActual THEN
        Cambio:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY cdeVerde AS DECIMAL NO-UNDO
    GET.
    SET(INPUT ipdeNuevo AS DECIMAL):
      DEFINE VARIABLE mdeActual AS DECIMAL NO-UNDO.
      mdeActual = cdeVerde.
      cdeVerde = ajustarComponente(ipdeNuevo).
      IF NOT clgModificando AND ipdeNuevo NE mdeActual THEN
        Cambio:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY cdeAzul AS DECIMAL NO-UNDO
    GET.
    SET(INPUT ipdeNuevo AS DECIMAL):
      DEFINE VARIABLE mdeActual AS DECIMAL NO-UNDO.
      mdeActual = cdeAzul.
      cdeAzul = ajustarComponente(ipdeNuevo).
      IF NOT clgModificando AND ipdeNuevo NE mdeActual THEN
        Cambio:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY cchRojo AS CHARACTER NO-UNDO
    GET:
      IF SESSION:NUMERIC-FORMAT = "EUROPEAN" THEN
        RETURN REPLACE( STRING(cdeRojo),",",".").
      ELSE
        RETURN STRING(cdeRojo).
    END GET.
    
  DEFINE PUBLIC PROPERTY cchVerde AS CHARACTER NO-UNDO
    GET:
      IF SESSION:NUMERIC-FORMAT = "EUROPEAN" THEN
        RETURN REPLACE( STRING(cdeVerde),",",".").
      ELSE
        RETURN STRING(cdeVerde).
    END GET.
  DEFINE PUBLIC PROPERTY cchAzul AS CHARACTER NO-UNDO
    GET:
      IF SESSION:NUMERIC-FORMAT = "EUROPEAN" THEN
        RETURN REPLACE( STRING(cdeAzul),",",".").
      ELSE
        RETURN STRING(cdeAzul).
    END GET.
    
  CONSTRUCTOR PUBLIC Color():
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC Color(INPUT ipdeR AS DECIMAL, INPUT ipdeG AS DECIMAL, INPUT ipdeB AS DECIMAL):
    clgModificando = TRUE.
    cdeRojo = ipdeR.
    cdeVerde = ipdeG.
    cdeAzul = ipdeB.
    FINALLY:
      clgModificando = FALSE.
    END FINALLY.
  END CONSTRUCTOR.

  METHOD PRIVATE DECIMAL valorPDF(INPUT vp_Color AS CHARACTER):
    def var vl_Num             as int  no-undo.
   
    if substring(vp_Color, 1, 2) = "0x":U then
      vl_Num = HexToInt(substring(vp_Color, 3)).
    else
      vl_Num = int(vp_Color).
      
    if vl_Num GT 255 then RETURN 1.0.      
      
    RETURN ROUND(vl_Num / 255, 4).
  END METHOD.         

  METHOD PUBLIC VOID desdeCadena(INPUT ipchRGB AS CHARACTER):
    clgModificando = TRUE.
   IF SUBSTRING(ipchRGB, 1, 2) = "0x":U AND LENGTH(ipchRGB) EQ 8 THEN      /* Hex Value 0xRRGGBB */
      ASSIGN
        cdeRojo = valorPDF("0x":U + substring(ipchRGB, 3, 2))     /* RED */
        cdeVerde = valorPDF("0x":U + substring(ipchRGB, 5, 2))     /* GREEN */
        cdeAzul = valorPDF("0x":U + substring(ipchRGB, 7, 2))     /* BLUE */
      {&END}
   IF SUBSTRING(ipchRGB, 1, 1) = "#":U AND LENGTH(ipchRGB) = 7 THEN        /* Hex Value #RRGGBB */
      ASSIGN
        cdeRojo = valorPDF("0x":U + substring(ipchRGB, 2, 2))     /* RED */
        cdeVerde = valorPDF("0x":U + substring(ipchRGB, 4, 2))     /* GREEN */
        cdeAzul = valorPDF("0x":U + substring(ipchRGB, 6, 2))     /* BLUE */
      {&END}
   ELSE IF LENGTH(ipchRGB) = 9 THEN                                         /* Dec Value RRRGGGBBB */
      ASSIGN
        cdeRojo = valorPDF(substring(ipchRGB, 1, 3))              /* RED */
        cdeVerde = valorPDF(substring(ipchRGB, 4, 3))              /* GREEN */
        cdeAzul = valorPDF(substring(ipchRGB, 7, 3))              /* BLUE */
      {&END}
   ELSE IF NUM-ENTRIES(ipchRGB) = 3 THEN
     ASSIGN
      cdeRojo = valorPDF(ENTRY(1,ipchRGB))              /* RED */
      cdeVerde = valorPDF(ENTRY(2,ipchRGB))              /* GREEN */
      cdeAzul = valorPDF(ENTRY(3,ipchRGB))              /* BLUE */
    {&END}
    FINALLY:
      clgModificando = FALSE.
      Cambio:Publish(THIS-OBJECT).
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC VOID desdeRGB(INPUT ipdeR AS DECIMAL, INPUT ipdeV AS DECIMAL, INPUT ipdeA AS DECIMAL):
    clgModificando = TRUE.
    cdeRojo = ipdeR.
    cdeVerde = ipdeV.
    cdeAzul = ipdeA.
    FINALLY:
      clgModificando = FALSE.
      Cambio:Publish(THIS-OBJECT).
    END FINALLY.
  END METHOD.
  
  METHOD PRIVATE INTEGER HexToInt(input vp_Hex as char):
    def var vl_Num            as int  no-undo.
    def var vl_i              as int  no-undo.
    def var vl_pos            as int  no-undo.

    do vl_i = 1 to length(vp_Hex):
        vl_Pos = index("0123456789ABCDEF", substring(vp_Hex, vl_i, 1)).
        if vl_Pos = 0 then 
        do:
            vl_Num = 0.
            leave.
        end.
        if vl_Pos LE 10 then
            vl_Num = vl_Num + integer(substring(vp_Hex, vl_i, 1)) * exp(16, (length(vp_Hex) - vl_i)).
        else
            vl_Num = vl_Num + (vl_Pos - 1) * exp(16, (length(vp_Hex) - vl_i)).
    end.
    
    return vl_Num.
  END METHOD.
  
  METHOD PUBLIC VOID Copiar(INPUT ipobColor AS pdf.utiles.Color):
    clgModificando = TRUE.
    cdeRojo = ipobColor:cdeRojo.
    cdeVerde = ipobColor:cdeVerde.
    cdeAzul = ipobColor:cdeAzul.
    FINALLY:
      clgModificando = FALSE.
      Cambio:Publish(THIS-OBJECT).
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC LOGICAL EsIgual(INPUT ipobColor AS pdf.utiles.Color):
    RETURN cchRojo EQ ipobColor:cchRojo AND
      cchVerde EQ ipobColor:cchVerde AND
      cchAzul EQ ipobColor:cchAzul.       
  END METHOD.
END CLASS.