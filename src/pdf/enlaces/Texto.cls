{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Texto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 10 07:37:58 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.enlaces.Enlace.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.enlaces.Texto INHERITS Enlace:
  
  DEFINE PUBLIC PROPERTY cchEstilo AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cchIcono AS CHARACTER NO-UNDO
    GET.
    SET.
   
  METHOD PROTECTED OVERRIDE VOID CambioTipo(INPUT ipenTipo AS pdf.tipos.ENUM):
    IF ipenTipo:cinValor NE pdf.tipos.Enlace:Texto
      AND ipenTipo:cinValor NE pdf.tipos.Enlace:Marca THEN
      ipenTipo:cinValor = cinTipoPrevio.
    ELSE
      SUPER:CambioTipo(ipenTipo).
  END METHOD.

  METHOD PUBLIC OVERRIDE VOID generarDefinicionInterna():
    cobDocumento:cobDestino:agregar("/T (" + cchEstilo + ")" + {&PDFSkip}
        + "/Name /" + cchIcono + {&PDFSkip}
        + "/Border [0 0 " + STRING(cinGrosorBorde) + "]" + {&PDFSkip}
        + "/Contents " + {&PDFSkip}).

    IF VALID-OBJECT(cobDocumento:cobEncriptador)THEN
      cobDocumento:cobDestino:agregar("<" + cobDocumento:cobEncriptador:EncriptarAHex(cinObjetoPDF,cchContenido) + ">" + {&PDFSkip}).
    ELSE
      cobDocumento:cobDestino:agregar("(" + cobDocumento:escaparTexto(cchContenido) + ")" + {&PDFSkip}).
  END METHOD.
  
  CONSTRUCTOR Texto(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  METHOD PUBLIC OVERRIDE VOID Copiar(INPUT ipobEnlace AS pdf.enlaces.Enlace):
    DEFINE VARIABLE mobT AS pdf.enlaces.Texto NO-UNDO.
    SUPER:Copiar(ipobEnlace).
    IF NOT TYPE-OF(ipobEnlace,pdf.enlaces.Texto) THEN
      RETURN.
    mobT = CAST(ipobEnlace,pdf.enlaces.Texto).
    cchEstilo = mobT:cchEstilo.
    cchIcono = mobT:cchIcono.
  END METHOD.
END CLASS.