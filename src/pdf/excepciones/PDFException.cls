{pdf/pdf.i}
ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING nsra.utiles.excepciones.Exception.
/*$
Excepción de la implementación de PDF.
$enlace
pdf.utiles.Documento
$*/
CLASS pdf.excepciones.PDFException INHERITS Exception:
  CONSTRUCTOR PUBLIC PDFException(INPUT ipchReason AS CHARACTER):
    SUPER(ipchReason).
  END CONSTRUCTOR.
END CLASS.
