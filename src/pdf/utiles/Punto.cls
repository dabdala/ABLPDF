 
 /*------------------------------------------------------------------------
    File        : Punto
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 09:18:37 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.Punto:
  DEFINE PUBLIC EVENT CambioEnY VOID (INPUT ipobPunto AS pdf.utiles.Punto).
  DEFINE PUBLIC EVENT CambioEnX VOID (INPUT ipobPunto AS pdf.utiles.Punto).
   
  DEFINE PUBLIC PROPERTY cinXPrevio AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cinYPrevio AS INTEGER NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cinX AS INTEGER NO-UNDO
    GET.
    SET(INPUT ipinX AS INTEGER):
      IF ipinX EQ cinX THEN
        RETURN.
      cinXPrevio = cinX.
      cinX = ipinX.
      CambioEnX:Publish(THIS-OBJECT). 
    END SET.
  DEFINE PUBLIC PROPERTY cinY AS INTEGER NO-UNDO
    GET.
    SET(INPUT ipinY AS INTEGER):
      IF ipinY EQ cinY THEN
        RETURN.
      cinYPrevio = cinY.
      cinY = ipinY.
      CambioEnY:Publish(THIS-OBJECT).
    END SET.
    
  DEFINE PUBLIC PROPERTY cinDesde AS INTEGER NO-UNDO
    GET:
      RETURN cinX.
    END GET.
    SET(INPUT ipinDesde AS INTEGER):
      cinX = ipinDesde.
    END SET.
  DEFINE PUBLIC PROPERTY cinHasta AS INTEGER NO-UNDO
    GET:
      RETURN cinY.
    END GET.
    SET(INPUT ipinHasta AS INTEGER):
      cinY = ipinHasta.
    END SET.
  METHOD PUBLIC VOID Copiar(INPUT ipobPunto AS pdf.utiles.Punto):
    cinX = ipobPunto:cinX.
    cinY = ipobPunto:cinY.
  END METHOD.
  
  METHOD PUBLIC VOID Mover(INPUT ipobPunto AS pdf.utiles.Punto):
    cinX = cinX + ipobPunto:cinX.
    cinY = cinY + ipobPunto:cinY.
  END METHOD.
  
  METHOD PUBLIC VOID DeltaX(INPUT ipinDelta AS INTEGER):
    cinX = cinX + ipinDelta.
  END METHOD.
  METHOD PUBLIC VOID DeltaY(INPUT ipinDelta AS INTEGER):
    cinY = cinY + ipinDelta.
  END METHOD.
  
  METHOD PUBLIC DECIMAL Distancia(INPUT ipobPunto AS pdf.utiles.Punto):
    RETURN SQRT(EXP(cinX - ipobPunto:cinX,2) + EXP(cinY - ipobPunto:cinY,2)).
  END METHOD. 
END CLASS.