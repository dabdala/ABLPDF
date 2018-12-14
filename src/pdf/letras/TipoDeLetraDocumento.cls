{pdf/pdf.i}
 
 /*------------------------------------------------------------------------
    File        : TipoDeLetraDocumento
    Purpose     : Es el tipo de letra, y sus características, que actualmente utiliza el documento PDF
    Syntax      : 
    Description : Maneja la información de fuentes para un documento PDF
    Author(s)   : D. Abdala
    Created     : Thu Aug 30 08:24:07 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.PDFException.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.letras.TipoDeLetraDocumento:
  DEFINE PUBLIC EVENT CambioLetra VOID (INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento).
  DEFINE PUBLIC EVENT CambioPuntos VOID (INPUT ipobLetra AS pdf.letras.TipoDeLetraDocumento).
  
  DEFINE PROTECTED PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cdePuntos AS DECIMAL NO-UNDO INITIAL 10.0 
    GET.
    SET(INPUT ipdePuntos AS DECIMAL):
      DEFINE VARIABLE mdePrevio AS DECIMAL NO-UNDO.
      mdePrevio = cdePuntos.
      cdePuntos = ipdePuntos.
      IF mdePrevio NE ipdePuntos THEN
        CambioPuntos:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY cchPuntos AS CHARACTER NO-UNDO
    GET:
      RETURN pdf.Documento:dec2string(cdePuntos).
    END GET.
    
  DEFINE PUBLIC PROPERTY cchNombre AS CHARACTER NO-UNDO
    GET.
    SET(INPUT ipchCual AS CHARACTER):
      IF cobDocumento:TipoDeLetraDisponible(ipchCual) THEN DO:
        DEFINE VARIABLE mchActual AS CHARACTER NO-UNDO.
        mchActual = cchNombre.
        cchNombre = ipchCual.
        IF mchActual NE ipchCual THEN
          CambioLetra:Publish(THIS-OBJECT).
      END.
    END SET.
    
  DEFINE PUBLIC PROPERTY cobLetra AS pdf.letras.TipoDeLetra NO-UNDO
    GET:
      RETURN cobDocumento:TipoDeLetraDefinido(cchNombre).
    END GET.
    
  DEFINE PUBLIC PROPERTY cchNombreInterno AS CHARACTER NO-UNDO
    GET:
      RETURN cobLetra:cchNombreInterno.
    END GET.
    
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET:
      RETURN cobLetra:cinObjetoPDf.
    END GET.
    
  CONSTRUCTOR TipoDeLetraDocumento(INPUT ipobDocumento AS pdf.Documento):
    SUPER().
    cobDocumento = ipobDocumento.
  END CONSTRUCTOR.
  
  METHOD PUBLIC VOID Copiar(INPUT ipobDesde AS pdf.letras.TipoDeLetraDocumento):
    cdePuntos = ipobDesde:cdePuntos. 
    cchNombre = ipobDesde:cchNombre. 
  END METHOD.
END CLASS.