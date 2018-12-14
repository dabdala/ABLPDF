{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EnlaceURL
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 12:01:08 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.enlaces.Enlace.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.enlaces.URL INHERITS pdf.enlaces.Enlace:
  
  DEFINE PUBLIC PROPERTY cenEstiloEnlace AS pdf.tipos.EstiloEnlace NO-UNDO
    GET: 
      IF NOT VALID-OBJECT(cenEstiloEnlace) THEN
        cenEstiloEnlace = NEW pdf.tipos.EstiloEnlace().
      RETURN cenEstiloEnlace.
    END GET.
    SET(INPUT ipenEstilo AS pdf.tipos.EstiloEnlace):
      IF ipenEstilo EQ ? THEN
        DELETE OBJECT cenEstiloEnlace NO-ERROR.
      cenEstiloEnlace = ipenEstilo.
    END SET.
  DEFINE PROTECTED PROPERTY cchEstilo AS CHARACTER NO-UNDO
    GET:
      CASE cenEstiloEnlace:cinValor:
        WHEN pdf.tipos.EstiloEnlace:I THEN
          RETURN 'I'.
        WHEN pdf.tipos.EstiloEnlace:O THEN
          RETURN 'O'.
        WHEN pdf.tipos.EstiloEnlace:P THEN
          RETURN 'P'.
        OTHERWISE
          RETURN 'N'.
      END.
    END GET.
    
  METHOD PROTECTED OVERRIDE VOID CambioTipo(INPUT ipenTipo AS pdf.tipos.ENUM):
    cenTipo:cinValor = pdf.tipos.Enlace:Enlace.
    SUPER:CambioTipo(ipenTipo).
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDefinicionInterna():
    cobDocumento:cobDestino:agregar("/Subtype /Link" + {&PDFSkip}
        + "/Border [0 0 " + STRING(cinGrosorBorde) + "]" + {&PDFSkip}
        + "/H /" + cchEstilo + {&PDFSkip}
        + "/A << " + {&PDFSkip}
        + "  /Type /Action" + {&PDFSkip}
        + "  /S /URI" + {&PDFSkip}
        + "  /URI ").

    IF VALID-OBJECT(cobDocumento:cobEncriptador)THEN
      cobDocumento:cobDestino:agregar("<" + cobDocumento:cobEncriptador:EncriptarAHex(cinObjetoPDF,cchContenido) + ">" + {&PDFSkip}).
    ELSE
      cobDocumento:cobDestino:agregar("(" + cobDocumento:escaparTexto(cchContenido) + ")" + {&PDFSkip}).

    cobDocumento:cobDestino:agregar("  >> " + {&PDFSkip}).
  END METHOD.
  
  CONSTRUCTOR URL(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
  END CONSTRUCTOR.
  
  METHOD PUBLIC OVERRIDE VOID Copiar(INPUT ipobEnlace AS pdf.enlaces.Enlace):
    DEFINE VARIABLE mobU AS pdf.enlaces.URL NO-UNDO.
    SUPER:Copiar(ipobEnlace).
    IF NOT TYPE-OF(ipobEnlace,pdf.enlaces.URL) THEN
      RETURN.
    mobU = CAST(ipobEnlace,pdf.enlaces.URL).
    cenEstiloEnlace:cinValor = mobU:cenEstiloEnlace:cinValor.
  END METHOD.  
END CLASS.