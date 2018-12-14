USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.tipos.ENUM ABSTRACT:
  DEFINE PUBLIC EVENT Cambio VOID (INPUT ipenEnum AS pdf.tipos.ENUM).
  
  METHOD PROTECTED CHARACTER NombresEnum():
    RETURN ''.
  END METHOD.
   
  DEFINE PUBLIC PROPERTY Nombres AS CHARACTER NO-UNDO
    GET:
      RETURN NombresEnum().
    END GET.
    
  DEFINE PUBLIC PROPERTY cinValor AS INTEGER INITIAL 0 NO-UNDO
    GET.
    SET(INPUT ipinValor AS INTEGER):
      IF ipinValor LT 0 THEN
        ipinValor = 0.
      ELSE IF ipinValor GE NUM-ENTRIES(Nombres) THEN
        ipinValor = NUM-ENTRIES(Nombres) - 1.
      IF cinValor NE ipinValor THEN DO:
        cinValor = ipinValor.
        Cambio:Publish(THIS-OBJECT).
      END.
    END SET.
  DEFINE PUBLIC PROPERTY cchValor AS CHARACTER NO-UNDO
    GET:
      RETURN ENTRY(cinValor + 1, Nombres).
      CATCH pError AS Progress.Lang.Error :
        DELETE OBJECT pError.
        RETURN ?.
      END CATCH.
    END GET.
    SET(INPUT ipchValor AS CHARACTER):
      cinValor = LOOKUP(ipchValor,Nombres) - 1.
    END SET.
    
  METHOD PUBLIC CHARACTER Cual(INPUT ipchLista AS CHARACTER):
    RETURN ENTRY(cinValor + 1,ipchLista).
    CATCH pError AS Progress.Lang.Error :
      DELETE OBJECT pError.
      RETURN ?.    		
    END CATCH.
  END METHOD.
END CLASS.