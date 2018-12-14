/******************************************************************************

    Program:        layer2.p
    
    Description:    Called from Layer.p.  This portion outputs the list of 
                    Customer Orders to the PDF document.

                    NOTE: Must be attached to Sports2000 DB to run this
                          example

******************************************************************************/
DEFINE VARIABLE vStateBook  AS INTEGER NO-UNDO.
DEFINE VARIABLE vCustBook   AS INTEGER NO-UNDO.

{pdf/pdf_inc.i }  /* This is required because we are defining a PageFooter.  The
                  h_PDFinc handle is not recreated but, instead, the currently
                  running version of PDFinclude is found */

DEFINE INPUT PARAMETER p_CustNum      AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER p_ParentStream AS CHARACTER NO-UNDO.

RUN pdf_reset_stream ("xxx").

RUN pdf_new ("xxx","layer2-" + STRING(p_CustNum) + ".pdf").

/* Set the Footer and Header values */
pdf_PageFooter ("xxx",
                THIS-PROCEDURE:HANDLE,
                "PageFooter").

/* Set the Last Procedure to call before closing a stream.  
   In this example we are using it to perform the Merge to the Parent Stream */
pdf_LastProcedure ("xxx",
                   THIS-PROCEDURE:HANDLE,
                  "LastProcedure").

RUN pdf_set_BottomMargin("xxx",80).

RUN pdf_new_page  ("xxx").
RUN pdf_set_font  ("xxx","Courier",10.0).

RUN pdf_Skip ("xxx").

RUN pdf_bookmark ("xxx","CustNr : " + STRING(p_CustNum), 0, FALSE, OUTPUT vStateBook).

/* For each Customer - display their Orders */
FOR EACH Order WHERE Order.CustNum = p_CustNum NO-LOCK:

  RUN pdf_text_color ("xxx",.0,.0,.0).

  RUN pdf_bookmark ("xxx","OrdNr : " + STRING(OrderNum), vStateBook, FALSE, OUTPUT vCustBook).
  
  RUN pdf_text ("xxx", "Order:" + STRING(OrderNum) ).
  RUN pdf_Skip ("xxx").

END. /* each Order */

RUN pdf_close ("xxx").

/* end of layer2.p */

PROCEDURE PageFooter:
/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Footer -- on all pages.
------------------------------------------------------------------------------*/
  /* Display a Sample Watermark on every page */
  RUN pdf_watermark ("xxx","Customer #:" + STRING(p_CustNum) ,"Courier-Bold",34,.75,.75,.75,175,500).

  RUN pdf_text_color ("xxx",.0,.0,.0).
  RUN pdf_stroke_color ("xxx", .0,.0,.0).
  
  RUN pdf_skip ("xxx").
  RUN pdf_set_dash ("xxx",1,0).
  RUN pdf_line  ("xxx", 0, pdf_TextY("xxx") - 5, pdf_PageWidth("xxx") - 20 , pdf_TextY("xxx") - 5, 1).
  RUN pdf_skip ("xxx").
  RUN pdf_skip ("xxx").
  RUN pdf_text_to  ("xxx",  "Page: "
                           + STRING(pdf_page("xxx"))
                           + " of " + pdf_TotalPages("xxx"), 97).

END. /* PageFooter */

PROCEDURE LastProcedure:

   /* First copy of stream replace nothing */

   /* Second copy of stream replace order by chicken */
   RUN pdf_ReplaceText("xxx", 2, "order", "chicken").

   /* Third copy of stream replace order by eggs */
   RUN pdf_ReplaceText("xxx", 3, "order", "eggs").

   RUN pdf_merge_stream("xxx",p_ParentStream,3).

END PROCEDURE.


