{pdf/pdf.i}
 
 /*------------------------------------------------------------------------
    File        : TipoDeLetra
    Purpose     : Encapsula la manipulación de fuentes
    Syntax      : 
    Description : Maneja la información de fuentes para un documento PDF
    Author(s)   : D. Abdala
    Created     : Thu Aug 30 08:24:07 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING pdf.excepciones.PDFException.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS pdf.letras.TipoDeLetraEstandar INHERITS pdf.letras.TipoDeLetra:
  
  CONSTRUCTOR TipoDeLetraEstandar(INPUT ipobDocumento AS pdf.Documento,INPUT ipinNumero AS INTEGER):
    SUPER(ipobDocumento).
    IF ipinNumero LT 1 OR ipinNumero GT 14 THEN
      UNDO, THROW NEW PDFException('Los tipos de letra estándar van de 1 a 14').
    ASSIGN
      cchFontFile  = "PDFBASE14"
      cchDIF   = ""
      cchNombreInterno   = "/BF" + STRING(ipinNumero)
    {&END}
    IF ipinNumero LT 5 THEN ASSIGN
        cenTipoDeLetra:cinValor  = pdf.tipos.Letra:AnchoFijo
        cchFontWidth = "600"
        cchNombre  = "Courier"  
    {&END}
    ELSE IF ipinNumero LT 9 THEN ASSIGN
        cenTipoDeLetra:cinValor = pdf.tipos.Letra:AnchoVariable
        cchNombre  = "Helvetica"
        cchFontWidth = FILL("788 ",32)      
    {&END}
    ELSE IF ipinNumero LT 13 THEN ASSIGN
        cenTipoDeLetra:cinValor = pdf.tipos.Letra:AnchoVariable
        cchNombre  = "Times"
        cchFontWidth = FILL("788 ",32)      
    {&END}
    ELSE IF ipinNumero EQ 13 THEN ASSIGN
        cenTipoDeLetra:cinValor = pdf.tipos.Letra:AnchoFijo
        cchFontWidth = "600"
        cchNombre  = "Symbol"      
    {&END}
    ELSE ASSIGN
        cenTipoDeLetra:cinValor = pdf.tipos.Letra:AnchoFijo
        cchFontWidth = "600"
        cchNombre  = "ZapfDingbats"
    {&END}
    AjustarNombre(ipinNumero).
    IF cenTipoDeLetra:cinValor EQ  pdf.tipos.Letra:AnchoVariable THEN
      AjustarAnchos(ipinNumero).
  END CONSTRUCTOR.
  
  METHOD PROTECTED VOID AjustarNombre(INPUT ipinCual AS INTEGER):
    CASE ipinCual:
      WHEN 2 OR WHEN 6 THEN
        cchNombre  = cchNombre + "-Oblique".
      WHEN 3 OR WHEN 7 OR WHEN 11 THEN
        cchNombre  = cchNombre + "-Bold".
      WHEN 4 OR WHEN 8 THEN
        cchNombre  = cchNombre + "-BoldOblique".
      WHEN 9 THEN
        cchNombre  = cchNombre + '-Roman'.
      WHEN 10 THEN
        cchNombre  = cchNombre + "-Italic".
      WHEN 12 THEN
        cchNombre  = cchNombre + "-BoldItalic".
    END.
  END.
  
  METHOD PROTECTED VOID AjustarAnchos(INPUT ipinCual AS INTEGER):
    CASE ipinCual:
      WHEN 5 OR WHEN 6 THEN
         cchWidths = cchFontWidth + "278 278 355 556 556 889 "
                                + "667 222 333 333 389 584 278 333 278 278 556 "
                                + "556 556 556 556 556 556 556 556 556 278 278 "
                                + "584 584 584 556 1015 667 667 722 722 667 611 778 "
                                + "722 278 500 667 556 833 722 778 667 778 722 "
                                + "667 611 722 667 944 667 667 611 278 278 278 "
                                + "469 556 222 556 556 500 556 556 278 556 556 "
                                + "222 222 500 222 833 556 556 556 556 333 500 "
                                + "278 556 500 722 500 500 500 334 260 334 584 "
                                + "333 556 556 167 556 556 556 556 191 333 556 "
                                + "333 333 500 500 556 556 556 278 537 350 222 "
                                + "333 333 556 1000 1000 611 333 333 333 333 333 "
                                + "333 333 333 333 333 333 333 333 1000 1000 370 "
                                + "556 778 1000 365 889 278 222 611 944 611".
      WHEN 7 OR WHEN 8 THEN
        cchWidths = cchFontWidth +  "278 333 474 556 556 889 " 
                                + "722 278 333 333 389 584 278 333 278 278 556 "
                                + "556 556 556 556 556 556 556 556 556 333 333 "
                                + "584 584 584 611 975 722 722 722 722 667 611 "
                                + "778 722 278 556 722 611 833 722 778 667 778 "
                                + "722 667 611 722 667 944 667 667 611 333 278 "
                                + "333 584 556 278 556 611 556 611 556 333 611 "
                                + "611 278 278 556 278 889 611 611 611 611 389 "
                                + "556 333 611 556 778 556 556 500 389 280 389 "
                                + "584 333 556 556 167 556 556 556 556 238 500 "
                                + "556 333 333 611 611 556 556 556 278 556 350 "
                                + "278 500 500 556 1000 1000 611 333 333 333 333 "
                                + "333 333 333 333 333 333 333 333 333 1000 "
                                + "1000 370 611 778 1000 365 889 278 278 611 "
                                + "944 611".
      WHEN 9 THEN
         cchWidths =   cchFontWidth + "250 " + "333 " + "408 "
                                + "500 500 833 778 180 333 333 500 564 250 "
                                + "333 250 278 500 500 500 500 500 500 500 "
                                + "500 500 500 278 278 564 564 564 444 921 "
                                + "722 667 667 722 611 556 722 722 333 389 "
                                + "722 611 889 722 722 556 722 667 556 611 "
                                + "722 722 944 722 722 611 333 278 333 469 "
                                + "500 333 444 500 444 500 444 333 500 500 "
                                + "278 278 500 278 778 500 500 500 500 333 "
                                + "389 278 500 500 722 500 500 444 480 200 "
                                + "480 541 778 500 578 333 500 444 1000 500 "
                                + "500 333 1000 556 333 889 667 611 722 444 "
                                + "333 333 444 444 350 500 1000 333 980 389 "
                                + "333 722 486 444 722 250 333 500 500 500 "
                                + "500 200 500 333 760 276 500 564 333 760 "
                                + "500 400 549 300 300 333 576 453 250 333 "
                                + "300 310 500 750 750 750 444 722 722 722 "
                                + "722 722 722 889 667 611 611 611 611 333 "
                                + "333 333 333 722 722 722 722 722 722 722 "
                                + "564 722 722 722 722 722 722 556 500 444 "
                                + "444 444 444 444 444 667 444 444 444 444 "
                                + "444 278 278 278 278 500 500 500 500 500 "
                                + "500 500 549 500 500 500 500 500 500 500 "
                                + "500".
      WHEN 10 THEN
         cchWidths =   cchFontWidth + "250 333 420 500 500 "
                                + "833 778 333 333 333 500 675 250 333 250 278 "
                                + "500 500 500 500 500 500 500 500 500 500 333 "
                                + "333 675 675 675 500 920 611 611 667 722 611 "
                                + "611 722 722 333 444 667 556 833 667 722 611 "
                                + "500 559 722 611 833 611 556 556 389 278 389 "
                                + "422 500 333 500 500 444 500 444 278 500 500 "
                                + "278 278 444 278 722 500 500 500 500 389 389 "
                                + "278 500 444 667 444 444 389 400 278 400 541 "
                                + "389 500 500 167 500 500 500 500 214 556 500 "
                                + "333 333 500 500 500 500 500 250 523 350 333 "
                                + "556 556 500 889 1000 500 333 333 333 333 333 "
                                + "333 333 333 333 333 333 333 333 889 889 276"
                                + "556 722 944 310 667 278 278 500 667 500".
      WHEN 11 THEN
         cchWidths =   cchFontWidth + "250 333 555 500 500 "
                                + "1000 833 333 333 333 500 570 250 333 250 "
                                + "278 500 500 500 500 500 500 500 500 500 500 "
                                + "333 333 570 570 570 500 930 722 667 722 722 "
                                + "667 611 778 778 389 500 778 667 944 722 778 "
                                + "611 778 722 556 667 722 722 1000 722 722 667 "
                                + "333 278 333 581 500 333 500 556 444 556 444 "
                                + "333 500 556 278 333 556 278 833 556 500 556 "
                                + "556 444 389 333 556 500 722 500 500 444 394 "
                                + "220 394 520 333 500 500 167 500 500 500 500 "
                                + "278 500 500 333 333 556 556 500 500 500 250 "
                                + "540 350 333 500 500 500 1000 1000 500 333 333 "
                                + "333 333 333 333 333 333 333 333 333 333 333 "
                                + "1000 1000 300 667 778 1000 330 722 278 278 "
                                + "500 722 556".
      WHEN 12 THEN
         cchWidths =   cchFontWidth + "250 389 555 500 500 833 "
                                + "778 333 333 333 500 570 250 333 250 278 500 "
                                + "500 500 500 500 500 500 500 500 500 333 333 "
                                + "570 570 570 500 832 667 667 667 722 667 667 "
                                + "722 778 389 500 667 611 889 722 722 611 722 "
                                + "667 556 611 722 667 889 667 611 611 333 278 "
                                + "333 570 500 333 500 500 444 500 444 333 500 "
                                + "556 278 278 500 278 778 556 500 500 500 389 "
                                + "278 556 444 667 500 444 389 348 220 348 570 "
                                + "389 500 500 167 500 500 500 500 278 500 500 "
                                + "333 333 556 556 500 500 500 250 500 350 333 "
                                + "500 500 500 1000 1000 500 333 333 333 333 333 "
                                + "333 333 333 333 333 333 333 333 1000 944 266 "
                                + "611 722 944 300 722 278 278 500 722 500".
    END.
  END METHOD.

END CLASS.