{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Imagen
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 08:22:53 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.imagenes.Imagen IMPLEMENTS pdf.IObjetoPDF ABSTRACT: 

  DEFINE PUBLIC PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cinAncho AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cinAlto AS INTEGER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchNombre AS CHARACTER NO-UNDO
    GET.
    PROTECTED SET.
    
  DEFINE PUBLIC PROPERTY cchNombreInterno AS CHARACTER NO-UNDO
    GET:
      RETURN '/Im' + REPLACE(cchNombre,' ','_').
    END GET.
    
  DEFINE PUBLIC PROPERTY cinObjetoPDF AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cchArchivo AS CHARACTER NO-UNDO
    GET.
    PRIVATE SET(INPUT ipchArchivo AS CHARACTER):
      cchArchivo = ipchArchivo.
      obtenerInformacionImagen().
    END SET.
    
  DEFINE PROTECTED PROPERTY cmpData AS MEMPTR NO-UNDO
    GET.
    SET.
    
  METHOD PROTECTED VOID obtenerInformacionImagen():
    UNDO, THROW NEW PDFException('No implementado').
  END METHOD.
    
  CONSTRUCTOR PUBLIC Imagen(INPUT ipobDocumento AS pdf.Documento, INPUT ipchNombre AS CHARACTER, INPUT ipchArchivo AS CHARACTER):
    cobDocumento = ipobDocumento.
    FILE-INFO:FILE-NAME = ipchArchivo.
    IF FILE-INFO:FULL-PATHNAME EQ ? THEN
      UNDO, THROW NEW PDFException('No puede localizarse la imagen').
    cchArchivo = FILE-INFO:FULL-PATHNAME.
    cchNombre = ipchNombre.
    cobDocumento:agregarImagen(THIS-OBJECT).
  END CONSTRUCTOR.
  CONSTRUCTOR PUBLIC Imagen(INPUT ipobDocumento AS pdf.Documento, INPUT ipobImagen AS pdf.imagenes.Imagen):
    cobDocumento = ipobDocumento.
    cchArchivo = ipobImagen:cchArchivo.
    cchNombre = ipobImagen:cchNombre.
    cinAncho = ipobImagen:cinAncho.
    cinAlto = ipobImagen:cinAlto.
    cobDocumento:agregarImagen(THIS-OBJECT).
  END CONSTRUCTOR.
  
  DESTRUCTOR Imagen():
    SET-SIZE(cmpData) = 0.
  END DESTRUCTOR.
  
  METHOD PUBLIC LOGICAL asignarObjetoPDF():
    IF cinObjetoPDF GT 0 THEN
      RETURN FALSE.
    cinObjetoPDF = cobDocumento:crearObjeto('Image').
    RETURN TRUE.
  END METHOD.
  
  METHOD PROTECTED CHARACTER generarBitsPerComponent():
    RETURN  "/BitsPerComponent 8" + {&pdfSKIP}.    
  END METHOD.
  
  METHOD PROTECTED CHARACTER generarColorSpace():
    RETURN "/ColorSpace /DeviceRGB" + {&pdfSKIP}.
  END METHOD.
  
  METHOD PROTECTED CHARACTER generarFilter():
    DEFINE VARIABLE mchFiltro AS CHARACTER NO-UNDO.
    IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
      mchFiltro = "/Filter [/FlateDecode /DCTDecode]".
    ELSE
      mchFiltro = "/Filter /DCTDecode".
    RETURN mchFiltro + {&pdfSKIP}.
  END METHOD.
  
  METHOD PROTECTED CHARACTER generarParametros():
    RETURN ''.
  END METHOD.
  
  METHOD PROTECTED VOID generarObjetosRelacionados():
  END METHOD.
  
  METHOD PUBLIC VOID generarDefinicion():
    DEFINE VARIABLE mmpRes AS MEMPTR NO-UNDO.

    IF VALID-OBJECT(cobDocumento:cobCompresor) THEN
      mmpRes = cobDocumento:cobCompresor:Comprimir(cmpData).
    ELSE
      COPY-LOB cmpData TO mmpRes.      

    /* igc - Added Sept 10, 2002 */
    asignarObjetoPDF().
    cobDocumento:inicioObjeto(THIS-OBJECT,cinObjetoPDF).

    cobDocumento:cobDestino:agregar("<<" + {&pdfSKIP}
        + "/Type /XObject" + {&pdfSKIP}
        + "/Subtype /Image" + {&pdfSKIP}
        + "/Name " + cchNombreInterno + {&pdfSKIP}
        + "/Width " + STRING(cinAncho) + {&pdfSKIP}
        + "/Height " + STRING(cinAlto) + {&pdfSKIP}
        + generarBitsPerComponent()
        + generarColorSpace()
        + "/Length " + STRING(GET-SIZE(mmpRes)) /* (TT_pdf_image.image_obj + 1) " 0 R" */ + {&pdfSKIP}
        + generarFilter()
        + generarParametros()).

    cobDocumento:cobDestino:agregar(">>" + {&pdfSKIP} + "stream" + {&pdfSKIP}).

    cobDocumento:cobDestino:agregar(mmpRes).

    cobDocumento:cobDestino:agregar({&pdfSKIP} + {&pdfSKIP} + "endstream" + {&pdfSKIP} + "endobj" + {&pdfSKIP}).
    //generar objetos asociados
    generarObjetosRelacionados().

    FINALLY:
      SET-SIZE(mmpRes) = 0.
    END FINALLY.
  END METHOD. /* pdf_load_images */
END CLASS.