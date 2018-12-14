{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : EspacioDeColores
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 17 11:10:42 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.DispositivoCMYK INHERITS pdf.recursos.ContenidoSimple:
  CONSTRUCTOR DispositivoCMYK(INPUT ipobDocumento AS pdf.DocumentoExistente, INPUT ipobPDf AS pdf.utiles.PDFStream):
    SUPER(ipobDocumento,ipobPDF).
  END CONSTRUCTOR.  
  
  METHOD PROTECTED OVERRIDE CHARACTER tipoObjeto():
    RETURN "~/DeviceCMYK".
  END METHOD.
END CLASS.