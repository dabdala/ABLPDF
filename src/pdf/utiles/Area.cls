{nsra/utiles/runlevel.i} 
 /*------------------------------------------------------------------------
    File        : Area
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Tue Sep 04 11:26:07 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.utiles.Area: 
  DEFINE PUBLIC PROPERTY cinDerecha AS INTEGER INITIAL 0 NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinIzquierda AS INTEGER INITIAL 0 NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinArriba AS INTEGER INITIAL 0 NO-UNDO
    GET.
    SET.
  DEFINE PUBLIC PROPERTY cinAbajo AS INTEGER INITIAL 0 NO-UNDO
    GET.
    SET.
    
  DEFINE PUBLIC PROPERTY cinX AS INTEGER NO-UNDO
    GET:
      RETURN cinIzquierda.
    END GET.
    SET(INPUT ipinX AS INTEGER):
      cinIzquierda = ipinX.
    END SET.
  DEFINE PUBLIC PROPERTY cinY AS INTEGER NO-UNDO
    GET:
      RETURN cinAbajo.
    END GET.
    SET(INPUT ipinY AS INTEGER):
      cinAbajo = ipinY.
    END SET.
  DEFINE PUBLIC PROPERTY cinAncho AS INTEGER NO-UNDO
    GET:
      RETURN cinDerecha - cinIzquierda.
    END GET.
    SET(INPUT ipinA AS INTEGER):
      cinDerecha = cinIzquierda + ipinA.
    END SET.
  DEFINE PUBLIC PROPERTY cinAlto AS INTEGER NO-UNDO
    GET:
      RETURN cinArriba - cinAbajo.
    END GET.
    SET(INPUT ipinA AS INTEGER):
      cinArriba = cinAbajo + ipinA.
    END SET.
    
  METHOD PUBLIC VOID Copiar(INPUT ipobArea AS pdf.utiles.Area):
    IF NOT VALID-OBJECT(ipobArea) THEN ASSIGN
      cinIzquierda = 0
      cinDerecha = 0
      cinAbajo = 0
      cinArriba = 0
    {&END}
    ELSE ASSIGN
      cinIzquierda = ipobArea:cinIzquierda
      cinDerecha = ipobArea:cinDerecha
      cinAbajo = ipobArea:cinAbajo
      cinArriba = ipobArea:cinArriba
    {&END}
  END METHOD.
  
  METHOD PUBLIC VOID Mover(INPUT ipobDelta AS pdf.utiles.Area):
    IF NOT VALID-OBJECT(ipobDelta) THEN
      RETURN.
    ASSIGN
      cinIzquierda = cinIzquierda + ipobDelta:cinIzquierda
      cinDerecha = cinDerecha + ipobDelta:cinDerecha
      cinArriba = cinArriba + ipobDelta:cinArriba
      cinAbajo = cinAbajo + ipobDelta:cinAbajo
    {&END}
  END METHOD.
  
  METHOD PUBLIC VOID Estirar(INPUT ipinDelta AS INTEGER):
    ASSIGN
      cinIzquierda = cinIzquierda + ipinDelta
      cinDerecha = cinDerecha + ipinDelta
      cinArriba = cinArriba + ipinDelta
      cinAbajo = cinAbajo + ipinDelta
    {&END}
  END METHOD.
END CLASS.