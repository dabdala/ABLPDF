 /******************************************************************************

    Program:        w2form.p
    
    Description:    This program illustrates how to open the W2 Form .
                    

******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}
   
DEFINE VARIABLE iPage AS INTEGER NO-UNDO.

/* Create a new output document */
RUN pdf_new ("Spdf","fw2-2005-out.pdf").

/* Compress the contents */
RUN pdf_set_parameter("Spdf","Compress","TRUE"). 

/* Open the blank Bill-of-Lading template */
RUN pdf_open_PDF("Spdf","pdf/pruebas_ejemplos/fw2-2005.pdf","W2"). 

/*
RUN DoNewPage (1).
RUN DoNewPage (2).
RUN DoNewPage (3).
RUN DoNewPage (4).
*/

RUN DoNewPage (5).  
/* RUN DoNewPage (6). */
/* RUN DoNewPage (7).  CANNOT READ PAGE 7 */
/* RUN DoNewPage (8). */
/* RUN DoNewPage (9).  CANNOT READ PAGE 9 */
/* RUN DoNewPage (10). */
/* RUN DoNewPage (11). READS PAGE BUT ERROR OCCURS WHEN DISPLAYING PAGE 11 */

RUN pdf_close("Spdf").

/* ------------------- INTERNAL PROCEDURES ------------------------- */
PROCEDURE DoNewPage:
  DEFINE INPUT PARAMETER pPage  AS INTEGER NO-UNDO.

  RUN pdf_new_page("Spdf").
  RUN pdf_use_PDF_page("Spdf","W2",pPage). 
END.

/* end of w2form.p */
 

