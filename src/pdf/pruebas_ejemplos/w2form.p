 /******************************************************************************

    Program:        w2form.p
    
    Description:    This program illustrates how to open the W2 Form .
                    

******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}
   
DEFINE VARIABLE iPage AS INTEGER NO-UNDO.

/* Create a new output document */
RUN pdf_new ("Spdf","w2form.pdf").

/* Compress the contents */
RUN pdf_set_parameter("Spdf","Compress","TRUE"). 

/* Open the blank Bill-of-Lading template */
RUN pdf_open_PDF("Spdf","pdf/pruebas_ejemplos/fw2.pdf","W2"). 

DO iPage = 2 TO INT(pdf_get_pdf_info("Spdf","W2","Pages")).
  RUN DoNewPage (iPage).
END.

RUN pdf_close("Spdf").

/* ------------------- INTERNAL PROCEDURES ------------------------- */
PROCEDURE DoNewPage:
  DEFINE INPUT PARAMETER pPage  AS INTEGER NO-UNDO.

  RUN pdf_new_page("Spdf").
  RUN pdf_use_PDF_page("Spdf","W2",pPage). 
END.

/* end of w2form.p */
 

