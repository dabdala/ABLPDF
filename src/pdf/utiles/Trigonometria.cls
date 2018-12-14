{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Trigonometria
    Purpose     : Calcular Senos y Cosenos
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Nov 29 07:14:34 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.Trigonometria: 

  /*
  solo necesito calcular el primer cuadrante 0° a 90°, los otros tres se corresponden
  a este cuadrante, con cambio de signo.
  */
  DEFINE PROTECTED STATIC TEMP-TABLE cttCoSenos NO-UNDO
    FIELD deGrados AS DECIMAL
    FIELD deSeno AS DECIMAL
    FIELD deCoseno AS DECIMAL
    FIELD deTangente AS DECIMAL
    INDEX ixAngulo deGrados
  {&END}
  
  DEFINE PROTECTED STATIC TEMP-TABLE cttFactorial NO-UNDO
    FIELD inNumero AS INTEGER
    FIELD liFactorial AS INT64
    INDEX ixNumero inNumero
  {&END}
  
  METHOD PUBLIC STATIC INT64 factorial(INPUT ipinNumero AS INTEGER):
    DEFINE VARIABLE mliResultado AS INT64 NO-UNDO.
    FIND cttFactorial WHERE cttFactorial.inNumero EQ ipinNumero NO-ERROR.
    IF AVAILABLE cttFactorial THEN
      RETURN cttFactorial.liFactorial.
    CREATE cttFactorial.
    cttFactorial.inNumero = ipinNumero.
    mliResultado = ipinNumero.
    DO WHILE ipinNumero GT 1:
      ipinNumero = ipinNumero - 1.
      mliResultado = mliResultado * ipinNumero.
    END.
    cttFactorial.liFactorial = mliResultado.
    RETURN mliResultado.
  END METHOD.
  
  METHOD PUBLIC STATIC DECIMAL GradosARadianes(INPUT ipdeGrados AS DECIMAL):
    RETURN (ipdeGrados * 3.1415927) / 180. 
  END METHOD. 
  
  /*
  sen X = x - x3 / 3! + x5 / 5! - x7 / 7! + x9 / 9! ...
  */
  METHOD PROTECTED STATIC DECIMAL calcularSeno(INPUT ipdeRadianes AS DECIMAL):
    DEFINE VARIABLE mdeSeno AS DECIMAL NO-UNDO.    
    mdeSeno = ipdeRadianes - EXP(ipdeRadianes,3) / factorial(3).
    mdeSeno = mdeSeno + EXP(ipderadianes,5) / factorial(5).
    mdeSeno = mdeSeno - EXP(ipdeRadianes,7) / factorial(7).
    mdeSeno = mdeSeno + EXP(ipdeRadianes,9) / factorial(9).
    mdeSeno = mdeSeno - EXP(ipdeRadianes,11) / factorial(11).
    RETURN ROUND(mdeSeno + EXP(ipdeRadianes,13) / factorial(13),4).
  END METHOD.
  
  /*
  cos X = 1 - x2 / 2! + x4 / 4! - x6 / 6! + x8 / 8! ... 
  */
  METHOD PROTECTED STATIC DECIMAL calcularCoseno(INPUT ipdeRadianes AS DECIMAL):
    DEFINE VARIABLE mdeCoseno AS DECIMAL NO-UNDO.
    mdeCoseno = 1 - EXP(ipdeRadianes,2) / factorial(2).
    mdeCoseno = mdeCoseno + EXP(ipdeRadianes,4) / factorial(4).
    mdeCoseno = mdeCoseno - EXP(ipdeRadianes,6) / factorial(6).
    mdeCoseno = mdeCoseno + EXP(ipdeRadianes,8) / factorial(8).
    mdeCoseno = mdeCoseno - EXP(ipdeRadianes,10) / factorial(10).
    RETURN ROUND(mdeCoseno + EXP(ipdeRadianes,12) / factorial(12),4).
  END METHOD.
  
  /*
  traslada cualquier ángulo al rango 0° <= ang < 360°
  */
  METHOD PUBLIC STATIC DECIMAL ajustarGrados(INPUT ipdeAngulo AS DECIMAL):
    DO WHILE ipdeAngulo GE 360:
      ipdeAngulo = ipdeAngulo - 360.
    END.
    DO WHILE ipdeAngulo LT 0:
      ipdeAngulo = ipdeAngulo + 360.
    END.  
    RETURN ipdeAngulo.
  END METHOD.
  METHOD PUBLIC STATIC INTEGER cuadranteGrados(INPUT ipdeAngulo AS DECIMAL, OUTPUT opdeAjustado AS DECIMAL):
    DEFINE VARIABLE minCuadrante AS INTEGER INITIAL 1 NO-UNDO.
    opdeAjustado = ajustarGrados(ipdeAngulo).
    DO WHILE opdeAjustado GT 90:
      minCuadrante = minCuadrante + 1.
      opdeAjustado = opdeAjustado - 90.
    END.
    RETURN minCuadrante.
  END.
  
  /*
  tan a = sen a / cos a
  */
  METHOD PROTECTED STATIC VOID calcular(INPUT ipdeAngulo AS DECIMAL):
    DEFINE VARIABLE minCuadrante AS INTEGER NO-UNDO.
    DEFINE VARIABLE mdeGrados AS DECIMAL NO-UNDO.
    DEFINE BUFFER mbfCoSenos FOR cttCoSenos.
    DEFINE VARIABLE mdeRadianes AS DECIMAL NO-UNDO.
    
    /*
    se asume que ya está ajustado y que efectivamente no está ya calculado
    ipdeAngulo = ajustarGrados(ipdeAngulo). */
    minCuadrante = cuadranteGrados(ipdeAngulo,OUTPUT mdeGrados).
    IF minCuadrante EQ 1 THEN DO:
      mdeRadianes = pdf.utiles.Trigonometria:GradosARadianes(ipdeAngulo).
      CREATE cttCoSenos.
      ASSIGN
        cttCoSenos.deGrados = ipdeAngulo
        cttCoSenos.deSeno = calcularSeno(mdeRadianes)
        cttCoSenos.deCoseno = calcularCoseno(mdeRadianes)
        cttCoSenos.deTangente = ROUND(cttCoSenos.deSeno / cttCoSenos.deCoseno,4)
      {&END}
    END.
    ELSE DO:
      /* garantizar la existencia del ángulo correspondiente del primer cuadrante */
      FIND mbfCoSenos WHERE mbfCoSenos.deGrados EQ mdeGrados NO-ERROR.
      IF NOT AVAILABLE mbfCoSenos THEN DO: 
        calcular(mdeGrados).
        FIND mbfCoSenos WHERE mbfCoSenos.deGrados EQ mdeGrados.
      END.
      CREATE cttCoSenos.
      ASSIGN
        cttCoSenos.deGrados = ipdeAngulo
        cttCoSenos.deSeno = mbfCoSenos.deSeno WHEN minCuadrante EQ 2 
        cttCoSenos.deCoseno = mbfCoSenos.deCoseno WHEN minCuadrante EQ 4 
        cttCoSenos.deSeno = - mbfCoSenos.deSeno WHEN minCuadrante NE 2 
        cttCoSenos.deCoseno = - mbfCoSenos.deCoseno WHEN minCuadrante NE 4 
        cttCoSenos.deTangente = ROUND(cttCoSenos.deSeno / cttCoSenos.deCoseno,4)
      {&END}
    END.
  END METHOD.
  
  METHOD PUBLIC STATIC DECIMAL Tangente(INPUT ipdeAngulo AS DECIMAL):
    ipdeAngulo = ajustarGrados(ipdeAngulo).
    FIND cttCoSenos WHERE cttCoSenos.deGrados EQ ipdeAngulo NO-ERROR.
    IF NOT AVAILABLE cttCoSenos THEN
      calcular(ipdeAngulo).
    RETURN cttCoSenos.deTangente.
  END METHOD.
  METHOD PUBLIC STATIC DECIMAL Seno(INPUT ipdeAngulo AS DECIMAL):
    ipdeAngulo = ajustarGrados(ipdeAngulo).
    FIND cttCoSenos WHERE cttCoSenos.deGrados EQ ipdeAngulo NO-ERROR.
    IF NOT AVAILABLE cttCoSenos THEN
      calcular(ipdeAngulo).
    RETURN cttCoSenos.deSeno.
  END METHOD.
  METHOD PUBLIC STATIC DECIMAL Coseno(INPUT ipdeAngulo AS DECIMAL):
    ipdeAngulo = ajustarGrados(ipdeAngulo).
    FIND cttCoSenos WHERE cttCoSenos.deGrados EQ ipdeAngulo NO-ERROR.
    IF NOT AVAILABLE cttCoSenos THEN
      calcular(ipdeAngulo).
    RETURN cttCoSenos.deCoSeno.
  END METHOD.  
END CLASS.