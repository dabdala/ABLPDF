{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Permisos
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Mon Sep 10 10:01:02 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.Permisos: 
    DEFINE PUBLIC PROPERTY clgImprimir AS LOGICAL NO-UNDO
      GET.
      SET.
      
    DEFINE PUBLIC PROPERTY clgCopiar AS LOGICAL NO-UNDO
      GET.
      SET.
    DEFINE PUBLIC PROPERTY clgModificar AS LOGICAL NO-UNDO
      GET.
      SET.
      
    DEFINE PUBLIC PROPERTY clgAnotar AS LOGICAL NO-UNDO
      GET.
      SET.
      
    DEFINE PUBLIC PROPERTY clgCompletar AS LOGICAL NO-UNDO
      GET.
      SET.
      
    DEFINE PUBLIC PROPERTY clgExtraer AS LOGICAL NO-UNDO
      GET.
      SET.
      
    DEFINE PUBLIC PROPERTY clgEnsamblar AS LOGICAL NO-UNDO
      GET.
      SET.
      
END CLASS.