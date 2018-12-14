 
 /*------------------------------------------------------------------------
    File        : Classes
    Purpose     : Resuelve el problema de los nombres de clases mal escritos, permitiendo la verificación en tiempo de compilación
    Syntax      : 
    Description : Nombres de las clases instanciables a través del objectBroker
    Author(s)   : nomade
    Created     : Wed Oct 19 12:14:20 ART 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/*$
Clase FINAL que define propiedades estáticas de solo lectura para obtener
los nombres de las clases instanciables a través del ObjectBroker para 
el módulo. Esto resuelve el problema de los nombres de clases
mal escritos, permitiendo la verificación en tiempo de compilación. 
$*/
CLASS pdf.utiles.Classes FINAL: 

  DEFINE PUBLIC STATIC PROPERTY TmptPDFProvider AS CHARACTER INITIAL 'pdf.utiles.TmptPDFProvider' NO-UNDO
    GET.
  DEFINE PUBLIC STATIC PROPERTY TmptPDFIncludeProvider AS CHARACTER INITIAL 'pdf.utiles.TmptPDFIncludeProvider' NO-UNDO
    GET.
END CLASS.