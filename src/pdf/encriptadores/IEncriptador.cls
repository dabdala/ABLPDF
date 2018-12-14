
/*------------------------------------------------------------------------
    File        : IEncriptador
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 08:00:01 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

INTERFACE pdf.encriptadores.IEncriptador:  
  DEFINE PUBLIC PROPERTY cchIdentificadorPDF AS CHARACTER NO-UNDO
    GET.
  DEFINE PUBLIC PROPERTY cchClaveMaestra AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cchClaveUsuario AS CHARACTER NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cchLlaveEncriptado AS CHARACTER NO-UNDO
    GET.
    SET.  
  METHOD PUBLIC MEMPTR Encriptar(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS LONGCHAR).
  METHOD PUBLIC LONGCHAR Desencriptar(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS MEMPTR).
  METHOD PUBLIC LONGCHAR EncriptarAHex(INPUT ipinObjetoPDF AS INTEGER, INPUT iplcDatos AS LONGCHAR).
  METHOD PUBLIC VOID generarDiccionario().  
END INTERFACE.