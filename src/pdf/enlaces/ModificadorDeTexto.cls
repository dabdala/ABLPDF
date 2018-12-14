{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : MarcaDeTexto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Fri Sep 07 12:10:56 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.enlaces.Enlace.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.enlaces.ModificadorDeTexto INHERITS pdf.enlaces.Enlace:
  
  DEFINE PUBLIC PROPERTY cobPunto1 AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobPunto2 AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobPunto3 AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobPunto4 AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.    
    
  DEFINE PROTECTED PROPERTY cchTodosLosPuntos AS CHARACTER NO-UNDO
    GET:
      RETURN STRING(cobPunto1:cinX) + " "
                                    + STRING(cobPunto1:cinY) + " "
                                    + STRING(cobPunto2:cinX) + " "
                                    + STRING(cobPunto2:cinY) + " " 
                                    + STRING(cobPunto3:cinX) + " "
                                    + STRING(cobPunto3:cinY) + " " 
                                    + STRING(cobPunto4:cinX) + " "
                                    + STRING(cobPunto4:cinY).
    END GET.
     
  CONSTRUCTOR ModificadorDeTexto(INPUT ipobDocumento AS pdf.Documento):
    SUPER(ipobDocumento).
    cobPunto1 = NEW pdf.utiles.Punto().
    cobPunto2 = NEW pdf.utiles.Punto().
    cobPunto3 = NEW pdf.utiles.Punto().
    cobPunto4 = NEW pdf.utiles.Punto().
  END CONSTRUCTOR.
  
  DESTRUCTOR ModificadorDeTexto():
    DELETE OBJECT cobPunto1 NO-ERROR.
    DELETE OBJECT cobPunto2 NO-ERROR.
    DELETE OBJECT cobPunto3 NO-ERROR.
    DELETE OBJECT cobPunto4 NO-ERROR.
  END DESTRUCTOR.

  METHOD PROTECTED OVERRIDE VOID CambioTipo(INPUT ipenTipo AS pdf.tipos.ENUM):
    IF ipenTipo:cinValor NE pdf.tipos.Enlace:Resaltado
      AND ipenTipo:cinValor NE pdf.tipos.Enlace:Subrayado
      AND ipentipo:cinValor NE pdf.tipos.Enlace:Rulitos
      AND ipenTipo:cinValor NE pdf.tipos.Enlace:Tachado THEN
      cenTipo:cinValor = cInTipoPrevio.
    ELSE
      SUPER:CambioTipo(ipenTipo).
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID generarDefinicionInterna():
    cobDocumento:cobDestino:agregar("/QuadPoints [" + cchTodosLosPuntos + "]" + {&PDFSkip} 
            + "/T (" + cchTipoPDF + ")" + {&PDFSkip}
            + "/Border [0 0 " + '0' + "]" + {&PDFSkip} /* STRING(cinGrosorBorde) */
            + "/Contents " + {&PDFSkip}).

    IF VALID-OBJECT(cobDocumento:cobEncriptador) THEN
      cobDocumento:cobDestino:agregar("<" + cobDocumento:cobEncriptador:EncriptarAHex(cinObjetoPDF,cchContenido) + ">" + {&PDFSkip}).
    ELSE
      cobDocumento:cobDestino:agregar("(" + cobDocumento:escaparTexto(cchContenido) +  ")" + {&PDFSkip}).
  END METHOD.
  
  METHOD PUBLIC OVERRIDE VOID Copiar(INPUT ipobEnlace AS pdf.enlaces.Enlace):
    DEFINE VARIABLE mobMDT AS pdf.enlaces.ModificadorDeTexto NO-UNDO.
    SUPER:Copiar(ipobEnlace).
    IF NOT TYPE-OF(ipobEnlace,pdf.enlaces.ModificadorDeTexto) THEN
      RETURN.
    mobMDT = CAST(ipobEnlace,pdf.enlaces.ModificadorDeTexto).
    cobPunto1:Copiar(mobMDT:cobPunto1).
    cobPunto2:Copiar(mobMDT:cobPunto2).
    cobPunto3:Copiar(mobMDT:cobPunto3).
    cobPunto4:Copiar(mobMDT:cobPunto4).
  END METHOD.

END CLASS.