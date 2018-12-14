/******************************************************************************

    Program:        layer.p
    
    Description:    This program illustrates the creation of a single PDF 
                    document but generated across multiple program layers.
                    
                    NOTE: Must be attached to Sports2000 DB to run this
                          example

******************************************************************************/
DEF VAR vStateBook            AS INT             NO-UNDO.

{pdf/pdf_inc.i}

RUN pdf_reset_all. /* When procedures used as persistent session */

RUN pdf_new ("Spdf","layer.pdf").
  
/* Set the Footer */
pdf_PageHeader ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageHeader").

/* For each Customer - create a HEADER page */
FOR EACH Customer WHERE Customer.Name BEGINS "A" AND Customer.CustNum < 100 NO-LOCK:
  RUN pdf_new_page ("Spdf").
  RUN pdf_set_font ("Spdf","Courier",24.0).
  RUN pdf_text_color ("Spdf",.0,.0,.0).

  RUN pdf_bookmark ("Spdf",Customer.Name, 0, FALSE, OUTPUT vStateBook).
  
  RUN pdf_text ("Spdf", "Customer: " + Customer.Name).
  RUN pdf_skip ("Spdf").

  RUN pdf/pruebas_ejemplos/layer2.p (INPUT Customer.CustNum, "Spdf").

END. /* each Customer */

RUN pdf_close ("Spdf").

/* This is not needed when started as general session procedures */
IF VALID-HANDLE(h_PDFinc)
   THEN DELETE WIDGET h_PDFinc.

PROCEDURE PageHeader:
/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Header -- on all Customer pages only.
------------------------------------------------------------------------------*/
  /* Display a Watermark on every Customer Section page */
  RUN pdf_watermark ("Spdf","Customer Section","Courier-Bold",34,.75,.75,.75,175,500).

END. /* PageHeader */

/* end of layer.p */
