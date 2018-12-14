{nsra/utiles/runlevel.i} 
 /*------------------------------------------------------------------------
    File        : Compresor
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 07:37:40 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

INTERFACE pdf.compresores.ICompresor:
  METHOD PUBLIC MEMPTR Comprimir(INPUT iplcDatos AS LONGCHAR).
  METHOD PUBLIC MEMPTR Comprimir(INPUT iplcDatos AS MEMPTR).
  METHOD PUBLIC LONGCHAR Descomprimir(INPUT iplcDatos AS MEMPTR).
  METHOD PUBLIC MEMPTR DescomprimirMP(INPUT iplcDatos AS MEMPTR).
  DEFINE PUBLIC PROPERTY cchNombreMetodo AS CHARACTER NO-UNDO
    GET.   
END INTERFACE.