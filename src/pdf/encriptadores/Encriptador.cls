{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EncriptadorBase
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 08:02:50 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.encriptadores.IEncriptador.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.encriptadores.Encriptador IMPLEMENTS IEncriptador, pdf.IObjetoPDF ABSTRACT:
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED STATIC TEMP-TABLE hexarray NO-UNDO
    FIELD hex-val   AS CHARACTER
    FIELD chr-val   AS INTEGER
  INDEX hex-idx AS PRIMARY
      hex-val
  INDEX chr-idx 
      chr-val
  {&END}
  
  METHOD PROTECTED INTEGER BinaryXOR(INPUT iFirstOperand AS integer,INPUT iSecondOperand AS integer):
    DEFINE VARIABLE iLoopCounter AS INTEGER no-undo.
    DEFINE VARIABLE iXORedResult AS INTEGER no-undo initial 0.
    DEFINE VARIABLE iFirstOpBit AS INTEGER no-undo.
    DEFINE VARIABLE iSecondOpBit AS INTEGER no-undo.
  
    DO iLoopCounter = 1 to 32:
      IF GET-BITS(iFirstOperand, iLoopCounter, 1) + GET-BITS(iSecondOperand, iLoopCounter, 1) EQ 1 THEN
      iXORedResult = iXORedResult + EXP(2, iLoopCounter - 1).
   END.
  
    RETURN iXORedResult.
  END METHOD. /* BinaryXOR */
  
  METHOD PROTECTED CHARACTER hex(INPUT asc-value AS INTEGER):
    RETURN hex(asc-value,TRUE).
  END METHOD.
  METHOD PROTECTED CHARACTER hex(INPUT asc-value AS INTEGER, INPUT iplg0x AS LOGICAL):
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
    
    IF iplg0x THEN
      h = "0x" + h.
    RETURN h.
  END METHOD. /* hex and hex2 */

  METHOD PROTECTED CHARACTER int2hex(INPUT vi AS INTEGER):
    RETURN int2hex(vi,FALSE).
  END METHOD.
  METHOD PROTECTED CHARACTER int2hex(INPUT vi AS INTEGER, INPUT iplg0x AS LOGICAL):
    DEFINE VARIABLE chex AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hexBit AS CHARACTER FORMAT "x(1)" EXTENT 16 NO-UNDO INIT
          ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'].
  
    IF vi < 16 THEN 
      chex = hexbit[vi + 1].
    ELSE
      chex = int2hex( integer( TRUNCATE( vi / 16, 0 ) ) ) + hexbit[ ( vi MODULO 16 ) + 1 ] .
    IF iplg0x THEN
      RETURN '0x' + chex.     
    RETURN chex. 
  END METHOD. 
  
  METHOD PRIVATE VOID LlenarHex():
    DEFINE VARIABLE vHexLoop AS INTEGER NO-UNDO.

    IF TEMP-TABLE hexarray:HANDLE:HAS-RECORDS THEN
      RETURN.
      
    DO vHexLoop = 0 TO 255:
      CREATE HexArray.
      ASSIGN
        HexArray.hex-val = hex(vHexLoop,FALSE)
        HexArray.chr-val = vHexLoop
      {&END}
    END.
  END METHOD.
  
  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
  
  DEFINE PUBLIC PROPERTY cchClaveMaestra AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cchClaveUsuario AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cchLlaveEncriptado AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cchIdentificadorPDF AS CHARACTER NO-UNDO
    GET:
      IF cchIdentificadorPDF EQ '' THEN DO ON ERROR UNDO, THROW:
        DEFINE VARIABLE mID AS MEMPTR NO-UNDO.
        DEFINE VARIABLE mHash AS RAW NO-UNDO.
        DEFINE VARIABLE minLen AS INTEGER NO-UNDO.
        SET-SIZE(mID) = LENGTH(cobDocumento:cchIdentificador).
        minLen = LENGTH(cobDocumento:cchIdentificador).
        PUT-STRING(mID,1,minLen) = cobDocumento:cchIdentificador.
        mHash = MD5-DIGEST(mId).
        cchIdentificadorPDf = GET-STRING(mHash,1,LENGTH(mHash)).
        FINALLY:
          /* Reallocate memory */
          SET-SIZE(mID) = 0.
        END FINALLY.        
      END.
      RETURN cchIdentificadorPDF.
    END GET.
    PRIVATE SET.
  
  DEFINE PUBLIC PROPERTY cchNombrePDF AS CHARACTER NO-UNDO
    GET:
      RETURN nombreMetodo().
    END GET.
    
  CONSTRUCTOR Encriptador(INPUT ipobDocumento AS pdf.Documento):
    cobDocumento = ipobDocumento.
    LlenarHex().
  END CONSTRUCTOR.
  
  METHOD PROTECTED CHARACTER nombreMetodo():
    UNDO, THROW NEW PDFException('METHOD NOT IMPLEMENTED').
  END METHOD. 

	METHOD PUBLIC LONGCHAR Desencriptar(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS MEMPTR):
    UNDO, THROW NEW PDFException("METHOD NOT IMPLEMENTED").
	END METHOD.

  METHOD PUBLIC MEMPTR Encriptar(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS LONGCHAR):
    UNDO, THROW NEW PDFException("METHOD NOT IMPLEMENTED").
  END METHOD.

  METHOD PUBLIC LONGCHAR EncriptarAHex(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS LONGCHAR):
    DEFINE VARIABLE mlcHex AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE mmpEnc AS MEMPTR NO-UNDO.
    DEFINE VARIABLE minSize AS INTEGER NO-UNDO.
    DEFINE VARIABLE l_Loop AS INTEGER NO-UNDO.
    
    mmpEnc = Encriptar(ipinObjetoPDF,iplcDatos).
    minSize = GET-SIZE(mmpEnc).
    DO l_Loop = 1 TO minSize:
      IF GET-BYTE(mmpEnc,l_Loop) = -1  THEN
        mlcHex = mlcHex + "00".
      ELSE
        mlcHex = mlcHex + SUBSTR(Hex( ASC(CHR(GET-BYTE(mmpEnc,l_Loop)))),3,2, "character":u).
    END.
    RETURN mlcHex.
    FINALLY:
      SET-SIZE(mmpEnc) = 0.
    END FINALLY.    
  END METHOD.
  
  
  METHOD PUBLIC VOID generarDiccionario():
    UNDO, THROW NEW PDFException("METHOD NOT IMPLEMENTED").
  END METHOD.  
  METHOD PUBLIC LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('Encrypt').
    RETURN TRUE.
  END METHOD.
END CLASS.