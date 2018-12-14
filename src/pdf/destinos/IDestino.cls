
/*------------------------------------------------------------------------
    File        : IDestino
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 05 15:22:12 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

INTERFACE pdf.destinos.IDestino:  
  METHOD PUBLIC VOID agregar(INPUT ipchTexto AS CHARACTER).
  METHOD PUBLIC VOID agregar(INPUT iplcTexto AS LONGCHAR).
  METHOD PUBLIC VOID agregar(INPUT ipmpBinario AS MEMPTR).
  METHOD PUBLIC LOGICAL iniciar().
  METHOD PUBLIC LOGICAL finalizar().
  METHOD PUBLIC INT64 posicion().
  DEFINE PUBLIC PROPERTY clgAceptaBinario AS LOGICAL NO-UNDO GET.  
END INTERFACE.