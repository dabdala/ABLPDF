/*******************************************************************************

    Program:        column-list.p
    
    Description:    lllustrates the use of Column placement using a Proportional
                    Font.
                    
*******************************************************************************/

{pdf/pdf_inc.i}

DEFINE VARIABLE j# AS INTEGER   NO-UNDO.
DEFINE VARIABLE i# AS CHARACTER NO-UNDO.

/* Create stream for new PDF file */
RUN pdf_new        ("Spdf","column-list.pdf").

/* Load Arial Code Font */
RUN pdf_load_font  ("Spdf","Arial","c:\windows\fonts\arial.ttf","pdf\pruebas_ejemplos\arial.afm","").

/* Start a New Page */
RUN pdf_new_page("Spdf").

/* Set the Font to Arial */
RUN pdf_set_font ("Spdf","Arial",10.0).

REPEAT j# = 1 TO 5:
   i# = STRING( EXP( 10, j#) ).

   RUN pdf_text_at ("Spdf", i#,10).
   RUN pdf_text_at ("Spdf", STRING(j#),70).

   RUN pdf_skip("Spdf").
END.

RUN pdf_close("Spdf").


/* end of column-list.p */
