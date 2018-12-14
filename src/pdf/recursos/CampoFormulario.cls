 
 /*------------------------------------------------------------------------
    File        : CampoFormulario
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Oct 30 09:55:22 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.recursos.CampoFormulario:
  DEFINE PUBLIC PROPERTY cchNombre AS CHARACTER NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cobArea AS pdf.utiles.Area NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cchFormato AS CHARACTER NO-UNDO
    GET.
    SET.
    
  CONSTRUCTOR CampoFormulario():
    cobArea = NEW pdf.utiles.Area().
  END CONSTRUCTOR.
  
  CONSTRUCTOR CampoFormulario(INPUT ipobCampo AS pdf.recursos.CampoFormulario):
    cobArea = NEW pdf.utiles.Area().
    cobArea:Copiar(ipobCampo:cobArea).
    cchNombre = ipobCampo:cchNombre.
    cchFormato = ipobCampo:cchFormato.
  END CONSTRUCTOR.
  
  DESTRUCTOR CampoFormulario():
    DELETE OBJECT cobArea.
  END DESTRUCTOR. 

END CLASS.