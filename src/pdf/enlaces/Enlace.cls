{pdf/pdf.i}
 /*------------------------------------------------------------------------
    File        : Enlace
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 11:30:01 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.enlaces.Enlace IMPLEMENTS  pdf.IObjetoPDF ABSTRACT: 
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.

  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobPagina AS pdf.Pagina NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cinTipoPrevio AS INTEGER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cenTipo AS pdf.tipos.Enlace NO-UNDO 
    GET:
      IF NOT VALID-OBJECT(cenTipo) THEN DO:
        cenTipo = NEW pdf.tipos.Enlace().
        cenTipo:Cambio:Subscribe(CambioTipo).
      END.
      RETURN cenTipo.
    END GET.
    PRIVATE SET(INPUT ipenTipo AS pdf.tipos.Enlace):
      IF ipenTipo EQ ? THEN
        DELETE OBJECT cenTipo NO-ERROR.
      cenTipo = ipenTipo.
    END SET.
    
  METHOD PROTECTED VOID CambioTipo(INPUT ipenTipo AS pdf.tipos.ENUM):
    cinTipoPrevio = ipenTipo:cinValor.
  END METHOD.
  
  DEFINE PUBLIC PROPERTY cchTipoPDF AS CHARACTER NO-UNDO
    GET:
      RETURN cenTipo:Cual('Link,Text,Stamp,Highlight,Underline,Squiggly,Strikeout').
    END GET.
    
  DEFINE PUBLIC PROPERTY cobColor AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  
  DEFINE PROTECTED PROPERTY cchColor AS CHARACTER NO-UNDO
    GET:
      RETURN cobcolor:cchRojo + ' ' + cobColor:cchVerde + ' ' + cobColor:cchAzul.
    END GET.
    
  DEFINE PUBLIC PROPERTY cchContenido AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cobRectangulo AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PROTECTED PROPERTY cchRectangulo AS CHARACTER NO-UNDO
    GET:
      RETURN STRING(cobRectangulo:cinIzquierda) + ' ' + STRING(cobRectangulo:cinAbajo) + ' ' + STRING(cobRectangulo:cinDerecha) + ' ' + STRING(cobRectangulo:cinArriba).
    END GET.
    
  DEFINE PUBLIC PROPERTY cinGrosorBorde AS INTEGER NO-UNDO
    GET.
    SET.
    
  METHOD PUBLIC LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('Link').
    RETURN TRUE.
  END METHOD.
  
  CONSTRUCTOR Enlace(INPUT ipobDocumento AS pdf.Documento):
    cobDocumento = ipobDocumento.
    cobPagina = cobDocumento:cobPaginaActual.
    cobColor = NEW pdf.utiles.Color().
    cobColor:Copiar(cobDocumento:cobColorTexto).
    cobRectangulo = NEW pdf.utiles.Area().
    cobRectangulo:Copiar(cobPagina:cobMargenes).
    cobDocumento:agregarEnlace(THIS-OBJECT).
  END CONSTRUCTOR.
  
  DESTRUCTOR Enlace():
    DELETE OBJECT cobRectangulo NO-ERROR.
    DELETE OBJECT cobColor NO-ERROR.
  END DESTRUCTOR.
  
  METHOD PUBLIC pdf.enlaces.Enlace siguiente():
    RETURN cobDocumento:siguienteEnlace(THIS-OBJECT,cobPagina).
  END METHOD.
  
  METHOD PROTECTED VOID generarDefinicionInterna():
  END METHOD.
  
  METHOD PUBLIC VOID generarDefinicion():
    DEFINE VARIABLE mchPorcion AS CHARACTER NO-UNDO.
    /* igc - Added Sept 10, 2002 */
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).
    mchPorcion = "<<" + {&PDFSkip} + "/Type /Annot" + {&PDFSkip}.
    mchPorcion = mchPorcion + "/Subtype /" + cchTipoPDF + {&PDFSkip}.
    mchPorcion = mchPorcion + "/Rect [ " + cchRectangulo + "]" + {&PDFSkip}.
    mchPorcion = mchPorcion + "/C [ " + cchColor + " ]" + {&PDFSkip}.
    cobDocumento:cobDestino:agregar(mchPorcion).
    generarDefinicionInterna().
    cobDocumento:cobDestino:agregar(">>" + {&PDFSkip} + "endobj" + {&PDFSkip}).    
  END METHOD.
  
  METHOD PUBLIC VOID Copiar(INPUT ipobEnlace AS pdf.enlaces.Enlace):
    cobColor:Copiar(ipobEnlace:cobColor).
    cobRectangulo:Copiar(ipobEnlace:cobRectangulo).
    cenTipo:cinValor = ipobEnlace:cenTipo:cinValor.    
  END METHOD.
END CLASS.