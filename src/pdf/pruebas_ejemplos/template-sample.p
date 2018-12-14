/******************************************************************************

    Program:        template-sample.p

    Description:    This program reads a sample invoice file and then
                    opens and applies a template.
    
******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

RUN pdf_new ("Spdf","template-sample.pdf").

RUN pdf_load_template("Spdf","Template","pdf/pruebas_ejemplos/template-sample.cfg").

DEFINE VARIABLE v_line  AS CHARACTER NO-UNDO.

RUN pdf_set_Font("Spdf","Courier",7). 
RUN pdf_set_LeftMargin("Spdf",30).

/* Create the first page */
RUN pdf_new_page("Spdf").
RUN pdf_use_template("Spdf","Template").

INPUT FROM "pdf/pruebas_ejemplos/template-sample.txt" NO-ECHO.
  REPEAT:
    IMPORT UNFORMATTED v_Line.

    RUN pdf_text    ("Spdf", v_Line).
    RUN pdf_skip    ("Spdf").

    /* If a Page Character is found then perform a New Page.  If text document
       contains no page characters the paging will occur automatically as soon
       as the BottomMargin is reached */
    IF INDEX(v_Line,CHR(12)) > 0 THEN DO:
      RUN pdf_new_page("Spdf").
      RUN pdf_use_template("Spdf","Template").
    END.
  END.
INPUT CLOSE.

RUN pdf_close("Spdf").

/* end of template.pdf */
