 
 /*------------------------------------------------------------------------
    File        : PreferenciasDeVisualizacion
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Wed Sep 05 15:16:27 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.PreferenciasDeVisualizacion: 

  DEFINE PUBLIC PROPERTY clgOcultarBarraDeHerramientas AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY clgOcultarBarraDeMenu AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY clgOcultarVentana AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY clgAcomodarALaVentana AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY clgCentrarVentana AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY clgMostrarTitulo AS LOGICAL INITIAL TRUE NO-UNDO
    GET.
    SET.
END CLASS.