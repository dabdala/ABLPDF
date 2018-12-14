 {pdf/pdf.i}
 /*------------------------------------------------------------------------
    File        : EncriptadorK40
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 11 11:21:06 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.encriptadores.EncriptadorK40 INHERITS pdf.encriptadores.Encriptador:
  PROCEDURE endecrypt EXTERNAL "{&pdfencryptlib}" CDECL PERSISTENT:
      DEFINE INPUT        PARAMETER pBufferPtr    AS LONG   NO-UNDO.
      DEFINE INPUT        PARAMETER pBufferLen    AS LONG   NO-UNDO.
      DEFINE INPUT        PARAMETER pPasswordKey  AS LONG   NO-UNDO.
      DEFINE INPUT        PARAMETER pPasswordLen  AS LONG   NO-UNDO.
  END PROCEDURE.

  METHOD PROTECTED LOGICAL PDFendecrypt (INPUT BufferPtr    AS MEMPTR,INPUT PasswordPtr  AS MEMPTR):
    RUN endecrypt
              (INPUT GET-POINTER-VALUE(BufferPtr), 
               INPUT GET-SIZE(BufferPtr),
               INPUT GET-POINTER-VALUE(PasswordPtr),
               INPUT GET-SIZE(PasswordPtr) ) .
  
    RETURN TRUE.
  END METHOD. /* PDFendecrypt */

  DEFINE PROTECTED VARIABLE cmpMaestra AS MEMPTR NO-UNDO.
  DEFINE PROTECTED VARIABLE cmpUsuario AS MEMPTR NO-UNDO.
  DEFINE PROTECTED VARIABLE cmpMaestraEnc AS MEMPTR NO-UNDO.
  DEFINE PROTECTED VARIABLE cmpRC4KeyM AS MEMPTR NO-UNDO.
  DEFINE PROTECTED VARIABLE cmpRC4KeyU AS MEMPTR NO-UNDO.
  
  DEFINE PROTECTED VARIABLE cchMaestraHex AS CHARACTER NO-UNDO.
  DEFINE PROTECTED VARIABLE cchUsuarioHex AS CHARACTER NO-UNDO.
  DEFINE PROTECTED VARIABLE cinVP-Str AS INTEGER NO-UNDO. 

  CONSTRUCTOR EncriptadorK40(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  DESTRUCTOR EncriptadorK40():
    RELEASE EXTERNAL "{&pdfencryptlib}".
    SET-SIZE(cmpMaestra) = 0.
    SET-SIZE(cmpUsuario) = 0.
    SET-SIZE(cmpMaestraEnc) = 0.
    SET-SIZE(cmpRC4KeyM) = 0.
    SET-SIZE(cmpRC4KeyU) = 0.
  END DESTRUCTOR.


  METHOD PROTECTED MEMPTR inicializarMem(INPUT ipchTexto AS CHARACTER):
    DEFINE VARIABLE l_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE mmpTmp AS MEMPTR NO-UNDO.
  
    /* No Password  */
    IF LENGTH(ipchTexto) GT 0 AND LENGTH(ipchTexto) LE 32 THEN DO:
      SET-SIZE(mmpTmp) = 32.
  
      DO L_Loop = 1 TO LENGTH(ipchTexto):
        PUT-BYTE(mmpTmp, l_Loop) = ASC(SUBSTR(ipchTexto,l_Loop,1)).
      END.
    END.
    RETURN mmpTmp.
  END METHOD. /* InitString */
  
  METHOD PROTECTED VOID completarMem(INPUT ipinCuanto AS INTEGER, INPUT-OUTPUT ipmpDatos AS MEMPTR):
    DEFINE VARIABLE L_chr   AS MEMPTR NO-UNDO.
    DEFINE VARIABLE L_ctr   AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_pad   AS INTEGER NO-UNDO.

    /* SET-SIZE(L_chr) = 1. */
    /* Set Password Pad String */ 
    SET-SIZE(L_chr) = 32.
    PUT-BYTE(L_Chr,1)  = ASC(CHR(40)).
    PUT-BYTE(L_Chr,2)  = ASC(CHR(191)).
    PUT-BYTE(L_Chr,3)  = ASC(CHR(78)).
    PUT-BYTE(L_Chr,4)  = ASC(CHR(94)).
    PUT-BYTE(L_Chr,5)  = ASC(CHR(78)).
    PUT-BYTE(L_Chr,6)  = ASC(CHR(117)).
    PUT-BYTE(L_Chr,7)  = ASC(CHR(138)).
    PUT-BYTE(L_Chr,8)  = ASC(CHR(65)).
    PUT-BYTE(L_Chr,9)  = ASC(CHR(100)).
    PUT-BYTE(L_Chr,10) = 0.
    PUT-BYTE(L_Chr,11) = ASC(CHR(78)).
    PUT-BYTE(L_Chr,12) = ASC(CHR(86)).
    PUT-BYTE(L_Chr,13) = ASC(CHR(255)).
    PUT-BYTE(L_Chr,14) = ASC(CHR(250)).
    PUT-BYTE(L_Chr,15) = ASC(CHR(1)).
    PUT-BYTE(L_Chr,16) = ASC(CHR(8)).
    PUT-BYTE(L_Chr,17) = ASC(CHR(46)).
    PUT-BYTE(L_Chr,18) = ASC(CHR(46)).
    PUT-BYTE(L_Chr,19) = 0.
    PUT-BYTE(L_Chr,20) = ASC(CHR(182)).
    PUT-BYTE(L_Chr,21) = ASC(CHR(208)).
    PUT-BYTE(L_Chr,22) = ASC(CHR(104)).
    PUT-BYTE(L_Chr,23) = ASC(CHR(62)).
    PUT-BYTE(L_Chr,24) = ASC(CHR(128)).
    PUT-BYTE(L_Chr,25) = ASC(CHR(47)).
    PUT-BYTE(L_Chr,26) = ASC(CHR(12)).
    PUT-BYTE(L_Chr,27) = ASC(CHR(169)).
    PUT-BYTE(L_Chr,28) = ASC(CHR(254)).
    PUT-BYTE(L_Chr,29) = ASC(CHR(100)).
    PUT-BYTE(L_Chr,30) = ASC(CHR(83)).
    PUT-BYTE(L_Chr,31) = ASC(CHR(105)).
    PUT-BYTE(L_Chr,32) = ASC(CHR(122)).
  
    SET-SIZE(ipmpDatos) = 32.

    l_Ctr = ipinCuanto + 1.
    l_Pad = 1. 
    DO WHILE TRUE:
      IF ASC(CHR(GET-BYTE(l_Chr,l_pad))) = -1 THEN
        PUT-BYTE( ipmpDatos, L_Ctr) = 0. 
      ELSE
        PUT-BYTE( ipmpDatos, L_Ctr) = ASC(CHR(GET-BYTE(l_Chr,l_pad))). 
  
      l_Ctr = l_Ctr + 1.
      L_pad = L_pad + 1.
      IF L_Ctr GT 32 THEN LEAVE.
    END. /* While True */
    
    FINALLY:
      SET-SIZE(L_Chr) = 0.
    END FINALLY.
  END METHOD. /* PadString */


  METHOD PROTECTED VOID DetermineOwnerKey():
    DEFINE VARIABLE L_md5     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop2   AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Length  AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE L_Byte      AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_md5mem    AS MEMPTR  NO-UNDO.
  
    DEFINE VARIABLE mrwMD5 AS RAW NO-UNDO.
  
    IF GET-SIZE(cmpMaestra) GT 0 THEN
      RETURN.

    cmpMaestra = InicializarMem(cchClaveMaestra).
    cmpUsuario = InicializarMem(cchClaveUsuario).

    /* Use Algorithm 3.3 from the Adobe 1.4 Spec */

    /* Step 1 - Pad the Owner String to 32-bytes */
    IF LENGTH(cchClaveMaestra) LT 32 THEN
      CompletarMem(LENGTH(cchClaveMaestra),INPUT-OUTPUT cmpMaestra).

    /* Step 2 - pass the padded Owner Password String to md5 Encryption hash */
    mrwMD5 = MD5-DIGEST(cmpMaestra).

    /* Step 3 - only for Rev 3 encryption - do md5 hash another 50 times*/
    /* NOT THIS CLASS */

    /* Step 4 - create an RC4 Encryption key using the first n bytes of the
              MD5 hash obtained in Step 2. */
    L_Length = 5.
    SET-SIZE(cmpRC4KeyM) = L_Length.
    L_Byte = 1.
    /* Since the md5hash is in hex we need to convert to Binary */
    DO L_md5 = 1 TO L_Length:
      FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(GET-BYTE(mrwMD5,L_Md5),FALSE).
      IF HexArray.chr-val = 0 THEN
        PUT-BYTE(cmpRC4KeyM,L_Byte) = 0.
      ELSE
        PUT-BYTE(cmpRC4KeyM,L_Byte) = ASC(CHR(HexArray.chr-val)).
      L_Byte = L_Byte + 1.
    END.

    /* Step 5 - pad or truncate the User Password */
    IF LENGTH(cchClaveUsuario) LT 32 THEN
      CompletarMem(LENGTH(cchClaveUsuario),INPUT-OUTPUT cmpUsuario).

    /* Step 6 - Encrypt the result of Step 5 using RC4 Key obtained in Step 4 */
    COPY-LOB cmpUsuario TO cmpMaestraEnc.
    PDFendecrypt(cmpMaestraEnc, cmpRC4KeyM).

    /* Step 7 - Perform this 19 times */
    /* NOT THIS CLASS */

    cchMaestraHex = "".
    DO L_loop = 1 TO GET-SIZE(cmpMaestraEnc):
      IF ASC(CHR(GET-BYTE(cmpMaestraEnc,L_loop))) = -1 THEN
        cchMaestraHex = cchMaestraHex + "00".
      ELSE
        cchMaestraHex = cchMaestraHex + hex(ASC(CHR(GET-BYTE(cmpMaestraEnc,L_loop))),FALSE).
    END.
  END METHOD. /* DetermineOwnerKey */
  
  METHOD PROTECTED VOID DetermineUserKey():
    DEFINE VARIABLE vLast-hash  AS CHARACTER NO-UNDO.
  
    DEFINE VARIABLE L_md5     AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Byte    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
  
    DEFINE VARIABLE vPad-mem  AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE vP-mem    AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE vID-mem   AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE vTot-mem  AS MEMPTR  NO-UNDO.
    DEFINE VARIABLE mrwMD5 AS RAW NO-UNDO.
    
    IF cchUsuarioHex NE '' THEN
      RETURN.
  
    /* Step 1 - Create an Encryption Key based on Algorithm 3.2 */
  
    /* Step 1A - Pad the User Password */
    DetermineOwnerKey().
    
    /* Step 1B - Pass concatenation of:
                   - Padded User Password 
                   - the value of the /O value
                   - the value of the /P entry 
                   - the first element of the /ID entry
                 to the md5 hash function */
  
    SET-SIZE(vID-mem) = 16.    /* Set ID Memptr from /ID Hex string passed */
    L_Byte = 1.
    DO L_Loop = 1 TO 32 BY 2:
      FIND FIRST  HexArray WHERE HexArray.Hex-Val = SUBSTR(cchIdentificadorPDF,L_loop,2).
      IF HexArray.chr-val = 0 THEN
        PUT-BYTE(vID-mem,L_Byte) = 0.
      ELSE
        PUT-BYTE(vID-mem,L_Byte) = ASC(CHR(HexArray.chr-val)).
      L_Byte = L_Byte + 1.
    END.
  
    /* If non Rev 3 (or 128 Bit Encryption) then the following must be 1 since 
       they are not valid in Rev 2 Encryption */
    /*      p_AllowForms    = 1
           p_AllowExtract  = 1
           p_AllowAssembly = 1. */
  
    PUT-BITS(cinvP-Str,1,1)   = 0.   /* Reserved */
    PUT-BITS(cinvP-Str,2,1)   = 0.   /* Reserved */
    PUT-BITS(cinvP-Str,3,1)   = (IF cobDocumento:cobPermisos:clgImprimir THEN 1 ELSE 0).      /* Print the Document */
    PUT-BITS(cinvP-Str,4,1)   = (IF cobDocumento:cobPermisos:clgModificar THEN 1 ELSE 0).     /* Modify the Contents */
    PUT-BITS(cinvP-Str,5,1)   = (IF cobDocumento:cobPermisos:clgCopiar THEN 1 ELSE 0).       /* Copy Graphics or Text */
    PUT-BITS(cinVP-Str,6,1)   = (IF cobDocumento:cobPermisos:clgAnotar THEN 1 ELSE 0).     /* Add or modify Annotations */
    PUT-BITS(cinVP-Str,7,1)   = 1.                 /* Reserved - must be 1 */
    PUT-BITS(cinVP-Str,8,1)   = 1.                 /* Reserved - must be 1 */
    PUT-BITS(cinVP-Str,9,1)   = 1.      /* Fill in existing Form Fields */
    PUT-BITS(cinVP-Str,10,1)  = 1.    /* Extract text and Graphics - Rev 3 */
    PUT-BITS(cinVP-Str,11,1)  = 1.   /* Assemble the document - Rev 3 */
    PUT-BITS(cinVP-Str,12,1)  = 1.   /* Print the doc - Rev 3 */
    PUT-BITS(cinVP-Str,13,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,14,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,15,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,16,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,17,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,18,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,19,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,20,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,21,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,22,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,23,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,24,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,25,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,26,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,27,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,28,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,29,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,30,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,31,1)  = 1.   /* Reserved */
    PUT-BITS(cinVP-Str,32,1)  = 1.   /* Reserved */
  

    SET-SIZE(vP-Mem) = 4.
    PUT-BYTE(vP-Mem,1) = GET-BITS(cinvP-str,1,8).
    PUT-BYTE(vP-Mem,2) = GET-BITS(cinvP-str,9,8).
    PUT-BYTE(vP-Mem,3) = GET-BITS(cinvP-str,17,8).
    PUT-BYTE(vP-Mem,4) = GET-BITS(cinvP-str,25,8).


    SET-SIZE(vTot-mem) = GET-SIZE(cmpUsuario) + GET-SIZE(cmpMaestraEnc) + GET-SIZE(vP-mem) + GET-SIZE(vID-mem).

    /* Add Padded User Password string to Total String */
    L_Byte = 1.
    DO L_Loop = 1 TO GET-SIZE(cmpUsuario):
      IF ASC(CHR(GET-BYTE(cmpUsuario,L_loop))) = -1 THEN DO:
        PUT-BYTE(vTot-mem,L_Byte) = 0.
      END.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(ASC(CHR(GET-BYTE(cmpUsuario,L_loop))),FALSE).
        PUT-BYTE(vTot-mem,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.  
      L_Byte = L_byte + 1.
    END.

    /* Add /O entry to Total String */
    DO L_Loop = 1 TO GET-SIZE(cmpMaestraEnc):
      IF ASC(CHR(GET-BYTE(cmpMaestraEnc,L_loop))) = -1 THEN DO:
        PUT-BYTE(vTot-mem,L_Byte) = 0.
      END.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(ASC(CHR(GET-BYTE(cmpMaestraEnc,L_loop))),FALSE).
        PUT-BYTE(vTot-mem,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.
      L_Byte = L_byte + 1.
    END.

    /* add the /P entry to Total String - low-order byte first */
    DO L_Loop = 1 TO GET-SIZE(vP-mem):
      IF ASC(CHR(GET-BYTE(vP-mem,L_loop))) = -1 THEN DO:
        PUT-BYTE(vTot-mem,L_Byte) = 0.
      END.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(ASC(CHR(GET-BYTE(vP-mem,L_loop))),FALSE).
        PUT-BYTE(vTot-mem,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.
      L_Byte = L_byte + 1.
    END.

    /* Add the /ID entry to Total String */
    DO L_Loop = 1 TO GET-SIZE(vID-mem):
      IF ASC(CHR(GET-BYTE(vID-mem,L_loop))) = -1 THEN DO:
        PUT-BYTE(vTot-mem,L_Byte) = 0.
      END.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(ASC(CHR(GET-BYTE(vID-mem,L_loop))),FALSE).
        PUT-BYTE(vTot-mem,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.
      L_Byte = L_byte + 1.
    END.

    mrwMD5 = MD5-DIGEST(vTot-mem).  

    SET-SIZE(cmpRC4KeyU) = 5.
    L_Byte = 1.
    DO L_md5 = 1 TO 5:
      IF GET-STRING(mrwMD5, L_md5,1) = "00" THEN DO:
        PUT-BYTE(cmpRC4KeyU,L_Byte) = 0.
      END.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(GET-BYTE(mrwMD5,L_md5),FALSE).
        PUT-BYTE(cmpRC4KeyU,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.
      L_Byte = L_Byte + 1.
    END.

    /* Now that we've got the original encryption key - store it for future use */
    CompletarMem(0,INPUT-OUTPUT vPad-mem).

    /* Plus run the encryption routine on the padded User password with this key */
    PDFendecrypt(vpad-mem, cmpRC4KeyU).
  
    /* But since we are outputting in hex we need to convert back to hex values */
    cchUsuarioHex = "".
    DO L_loop = 1 TO GET-SIZE(vpad-mem):
      IF ASC(CHR(GET-BYTE(vpad-mem,L_loop))) = -1 THEN
        cchUsuarioHex = cchUsuarioHex + "00".
      ELSE
        cchUsuarioHex = cchUsuarioHex + hex(ASC(CHR(GET-BYTE(vpad-mem,L_loop))),FALSE).
    END.
  END METHOD.
  
  METHOD PROTECTED MEMPTR  generarLlaveEncriptacion(INPUT ipinObjeto AS INTEGER):
    DEFINE VARIABLE L_Hex     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_Hash    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE L_Keyptr  AS MEMPTR NO-UNDO.
    DEFINE VARIABLE L_Loop    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Byte    AS INTEGER NO-UNDO.
    DEFINE VARIABLE L_Len     AS INTEGER NO-UNDO.
    DEFINE VARIABLE p_EncryptKey AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mrwMD5 AS RAW NO-UNDO.
  
    DetermineUserKey().
    L_Len = 10.
    SET-SIZE(L_KeyPtr) = 5 + INT(l_Len / 2).

    /* Take first n-bytes of original Rc4-Key ... */
    PUT-BYTES(l_KeyPtr,1) = GET-BYTES(cmpRC4KeyU,1,INT(l_Len / 2)).

    /* Append Object Number - Low Order Bytes First */
    L_Hex = SUBSTR(int2hex(ipinObjeto,TRUE),9,2).
    FIND HexArray WHERE HexArray.Hex-Val = L_Hex NO-ERROR.
    IF NOT AVAIL HexArray OR HexArray.chr-val = 0 THEN
      PUT-BYTE(L_KeyPtr,6) = 0.
    ELSE
      PUT-BYTE(L_KeyPtr,6) = ASC(CHR(HexArray.chr-val)).

    L_Hex = SUBSTR(int2hex(ipinObjeto,TRUE),7,2).
    FIND HexArray WHERE HexArray.Hex-Val = L_Hex NO-ERROR.
    IF NOT AVAIL HexArray OR HexArray.chr-val = 0 THEN
      PUT-BYTE(L_KeyPtr,7) = 0.
    ELSE
      PUT-BYTE(L_KeyPtr,7) = ASC(CHR(HexArray.chr-val)).

    L_Hex = SUBSTR(int2hex(ipinObjeto,TRUE),5,2).
    FIND HexArray WHERE HexArray.Hex-Val = L_Hex NO-ERROR.
    IF NOT AVAIL HexArray OR HexArray.chr-val = 0 THEN
      PUT-BYTE(L_KeyPtr,8) = 0.
    ELSE
      PUT-BYTE(L_KeyPtr,8) = ASC(CHR(HexArray.chr-val)).

    /* Append Generation Number - currently always zero */
    PUT-BYTE( L_KeyPtr, 9)   = 0. 
    PUT-BYTE( L_KeyPtr, 10)  = 0. 

    /* Then run the md5 hash against that n-byte key - orig + obj + gen */
    mrwMD5 = MD5-DIGEST(l_KeyPtr).

    /* Now take the first n + 5 bytes of the resulting md5 hash as the new key */
    L_Byte = 1.
    DO L_loop = 1 TO (L_len + 5):
      IF GET-STRING(mrwMD5,L_loop,1) = "00" THEN
        PUT-BYTE(p_EncryptKey,L_Byte) = 0.
      ELSE DO:
        FIND FIRST HexArray WHERE HexArray.Hex-Val = hex(GET-BYTE(mrwMD5,L_Loop),FALSE) NO-ERROR.
        IF NOT AVAIL HexArray OR HexArray.chr-val = 0 THEN
          PUT-BYTE(p_EncryptKey,L_Byte) = 0.
        ELSE
          PUT-BYTE(p_EncryptKey,L_Byte) = ASC(CHR(HexArray.chr-val)).
      END.
      L_Byte = L_Byte + 1.
    END.
    RETURN p_EncryptKey.
    FINALLY:
      SET-SIZE(L_KeyPtr) = 0.
      cchLlaveEncriptado = BASE64-ENCODE(p_EncryptKey).
    END FINALLY.
  END METHOD.
  
  METHOD PUBLIC OVERRIDE MEMPTR Encriptar(INPUT ipinObjeto AS INTEGER,INPUT iplcDatos AS LONGCHAR):
    DEFINE VARIABLE L_Content   AS MEMPTR NO-UNDO.
    DEFINE VARIABLE mmpLlave AS MEMPTR NO-UNDO.
    
    mmpLlave = generarLlaveEncriptacion(ipinObjeto).
    
    COPY-LOB iplcDatos TO L_Content.
    PDFendecrypt(L_Content, mmpLlave).
  
    RETURN L_Content.
  END METHOD.

  METHOD PUBLIC OVERRIDE LONGCHAR Desencriptar(INPUT ipinObjeto AS INTEGER, INPUT iplcDatos AS MEMPTR):
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDiccionario():
     asignarObjetoPDF().
     cobDocumento:cobDestino:agregar(STRING(cinObjetoPDF) +  " 0 obj" + {&pdfSKIP}
        + "<<" + {&pdfSKIP}
        + "/Filter /Standard" + {&pdfSKIP}
        + "/V 1" + {&pdfSKIP}
        + "/R 2" + {&pdfSKIP}
        + "/O<" + cchMaestraHex + ">" + {&pdfSKIP}
        + "/U<" + cchUsuarioHex  + ">" + {&pdfSKIP}
        + "/P " + GET-STRING(cmpRC4KeyU,1) + {&pdfSKIP}
        + ">>" + {&pdfSKIP}
        + "endobj" + {&pdfSKIP}).
  END METHOD.     
END CLASS.
