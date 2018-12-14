{pdf/pdf.i} 
 /*------------------------------------------------------------------------
    File        : Grafico
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nomade
    Created     : Thu Sep 06 10:25:01 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.EstadoGrafico:
  DEFINE PUBLIC EVENT CambioDeColorRelleno VOID (INPUT ipobEstado AS pdf.EstadoGrafico).
  DEFINE PUBLIC EVENT CambioDeColorPincel VOID (INPUT ipobEstado AS pdf.EstadoGrafico).
  
  DEFINE PROTECTED PROPERTY cobDocumento AS pdf.Documento NO-UNDO
    GET.
    PRIVATE SET.
    
  DEFINE PUBLIC PROPERTY cobPosicion AS pdf.utiles.Punto NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorRelleno AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cobColorPincel AS pdf.utiles.Color NO-UNDO
    GET.
    PRIVATE SET.
  DEFINE PUBLIC PROPERTY cenUnionLineas AS pdf.tipos.UnionLineas NO-UNDO
    GET: 
      IF NOT VALID-OBJECT(cenUnionLineas) THEN
        cenUnionLineas = NEW pdf.tipos.UnionLineas().
      RETURN cenUnionLineas.
    END GET.
    PRIVATE SET(INPUT ipenUnion AS pdf.tipos.UnionLineas):
      IF ipenUnion EQ ? THEN
        DELETE OBJECT cenUnionLineas NO-ERROR.
      cenUnionLineas = ipenUnion.
    END SET.
  
  CONSTRUCTOR EstadoGrafico(INPUT ipobDocumento AS pdf.Documento):
    cobDocumento = ipobDocumento.
    cobColorRelleno = NEW pdf.utiles.Color().
    cobColorRelleno:Copiar(cobDocumento:cobColorRelleno).
    cobColorRelleno:Cambio:Subscribe(CambioRelleno).
    cobColorPincel = NEW pdf.utiles.Color().
    cobColorPincel:Copiar(cobDocumento:cobColorPincel).
    cobColorPincel:Cambio:Subscribe(CambioPincel).
    cobPosicion = NEW pdf.utiles.Punto().
  END CONSTRUCTOR.
  DESTRUCTOR EstadoGrafico():
    DELETE OBJECT cobColorRelleno NO-ERROR.
    DELETE OBJECT cobColorPincel NO-ERROR.
    DELETE OBJECT cobPosicion NO-ERROR.
    cenUnionLineas = ?.
  END DESTRUCTOR.

/*-- cambios en los colores --*/
  METHOD PROTECTED VOID cambioPincel(INPUT ipobColor AS pdf.utiles.Color):
    IF NOT VALID-OBJECT(cobDocumento:cobPaginaActual) THEN
      RETURN.
    CambioDeColorPincel:Publish(THIS-OBJECT).
  END METHOD.
  METHOD PROTECTED VOID cambioRelleno(INPUT ipobColor AS pdf.utiles.Color):
    IF NOT VALID-OBJECT(cobDocumento:cobPaginaActual) THEN
      RETURN.
    CambioDeColorRelleno:Publish(THIS-OBJECT).
  END METHOD.
  
  METHOD PUBLIC VOID Copiar(INPUT ipobDesde AS pdf.EstadoGrafico):
    cobPosicion:Copiar(ipobDesde:cobPosicion).
    cobColorRelleno:Copiar(ipobDesde:cobColorRelleno).
    cobColorPincel:Copiar(ipobDesde:cobColorPincel).
    cenUnionLineas = ipobDesde:cenUnionLineas.
  END METHOD.
END CLASS.