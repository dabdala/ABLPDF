/*******************************************************************************

    Program:        custlist.p
    
    DeCode 39ion:    Illustrates how to interact Progress reporting requirements
                    with PDFinclude

    History:        G Campbell - Updated Aug 26, 2003
    
                      Now uses PageFooter and PageHeader functionality.
                    
                    G Campbell - Updated November 25, 2003
                    
                      Now illustrates how Bookmarks work

*******************************************************************************/

{pdf/pdf_inc.i}

DEFINE VARIABLE Vold_Y      AS INTEGER NO-UNDO.

DEFINE VARIABLE vStateBook  AS INTEGER NO-UNDO.
DEFINE VARIABLE vCustBook   AS INTEGER NO-UNDO.
DEFINE VARIABLE vNullBook   AS INTEGER NO-UNDO.

etime(yes).

/* Create stream for new PDF file */
RUN pdf_new        ("Spdf","custlist-comp.pdf").

/* RUN pdf_set_parameter("Spdf","Encrypt","TRUE"). */ 

RUN pdf_set_parameter("Spdf","AllowPrint","FALSE").
RUN pdf_set_parameter("Spdf","AllowCopy","FALSE").
RUN pdf_set_parameter("Spdf","AllowModify","FALSE"). 

/* RUN pdf_set_parameter("Spdf","MasterPassword","Custom").
RUN pdf_set_parameter("Spdf","UserPassword","Custom"). */ 

RUN pdf_set_parameter("Spdf","Compress","TRUE"). 

pdf_PageFooter ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageFooter").
pdf_PageHeader ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageHeader").

/* Load Bar Code Font */
RUN pdf_load_font  ("Spdf","Code 39","pdf/pruebas_ejemplos/code39.ttf","pdf/pruebas_ejemplos/code39.afm","").

/* Load PRO-SYS Logo File */
RUN pdf_load_image ("Spdf","ProSysLogo","pdf/pruebas_ejemplos/prosyslogo.jpg").

/* Set Document Information */ 
RUN pdf_set_info("Spdf","Author","Gordon Campbell").
RUN pdf_set_info("Spdf","Subject","Accounts Receivable").
RUN pdf_set_info("Spdf","Title","Customer List").
RUN pdf_set_info("Spdf","Keywords","Customer List Accounts Receivable").
RUN pdf_set_info("Spdf","Creator","PDFinclude V2").
RUN pdf_set_info("Spdf","Producer","custlist.p").

/* Set the Bottom Margin to 80 - to allow for Page Footer */
RUN pdf_set_BottomMargin("Spdf",80).

/* Instantiate a New Page */
RUN pdf_new_page("Spdf").

/* Loop through appropriate record set */
FOR EACH customer WHERE NAME BEGINS "A"
                    /* AND ( State = "AZ" OR State = "AK" or state = "") */
                    NO-LOCK 
    BREAK BY State
          BY CustNum:

  /* Create a Bookmark to each State  */
  IF FIRST-OF(Customer.State) THEN DO:
    FIND FIRST State WHERE State.State = Customer.State NO-LOCK NO-ERROR.
    IF NOT AVAIL State THEN
      RUN pdf_bookmark("Spdf","Unknown - ('" + Customer.State + "')", 0, FALSE, OUTPUT vStateBook).
    ELSE DO:
      RUN pdf_bookmark("Spdf",State.StateName, 0, FALSE, OUTPUT vStateBook).
    END.
  END. /* First-of State */

  /* Output the appropriate Record information */
  RUN pdf_set_font ("Spdf","Courier-Oblique",10.0).
  RUN pdf_text_at  ("Spdf", customer.state,1).
  RUN pdf_set_font ("Spdf","Courier",10.0).
  RUN pdf_text_at  ("Spdf", STRING(customer.CustNum,">>>9"),6).
  RUN pdf_text_at  ("Spdf", customer.NAME,12).
  RUN pdf_text_at  ("Spdf", customer.phone,44).
  RUN pdf_text_to  ("Spdf", STRING(customer.balance),80).

  /* Create a Bookmark to Each Customer Name within a State 
  RUN pdf_bookmark("Spdf", Customer.Name, vStateBook, FALSE, OUTPUT vCustBook). 
  */

  /* Place a weblink around the Customer Name 
  RUN pdf_link ("Spdf",
                75,
                pdf_TextY("Spdf")/* pdf_PageHeight("Spdf") - (pdf_TopMargin("Spdf")) - ((Vlines + 2) * 10 ) */,
                260,
                pdf_TextY("Spdf") /* pdf_PageHeight("Spdf") - (pdf_TopMargin("Spdf")) - ((Vlines + 2) * 10) */ + 10,
                "http://www.epro-sys.com/Code 39s/cgiip.exe/WService=sports2000/custorderspdf.p?CustNum=" + STRING(Customer.CustNum),
                0,
                0,
                0,
                1,
                "I").
  */

  /* Display a BarCode for each Customer Number */
  RUN pdf_set_font ("Spdf","Code 39",10.0).

  Vold_Y = pdf_TextY("Spdf").  /* Store Original Text Path */
  RUN pdf_text_xy ("Spdf", STRING(customer.CustNum,"999999"),500, pdf_textY("Spdf")).
  RUN pdf_set_TextY("Spdf",Vold_y). /* Reset Original Text Path */
  RUN pdf_set_font ("Spdf","Courier",10.0).

  /* Skip to Next Text Line */
  RUN pdf_skip    ("Spdf").  
  
  /* Now Display all Orders for the Customer */
  FOR EACH Order WHERE Order.CustNum = Customer.CustNum NO-LOCK:
    RUN pdf_text_at  ("Spdf", Order.OrderNum,10).
    RUN pdf_text_at  ("Spdf", STRING(Order.OrderDate),30).

    /* Create a Bookmark to Each Order For a Customer 
    RUN pdf_bookmark("Spdf", Order.OrderNum, vCustBook, FALSE, OUTPUT vNullBook).
    */

    RUN pdf_skip    ("Spdf").  
  END.

  IF LAST-OF(Customer.State) THEN DO:
    /* Put a red line between each of the states */
    RUN pdf_skip ("Spdf").
    RUN pdf_stroke_color ("Spdf",1.0,.0,.0).
    RUN pdf_set_dash ("Spdf",2,2).
    RUN pdf_line  ("Spdf", pdf_LeftMargin("Spdf") , pdf_TextY("Spdf") + 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") + 5, 0.5).
    RUN pdf_stroke_color ("Spdf",.0,.0,.0).
    RUN pdf_skip    ("Spdf").
  END. /* Last-of State */

END. /* each Customer */

RUN end_of_report.

RUN pdf_close("Spdf").

/* -------------------- INTERNAL PROCEDURES -------------------------- */

PROCEDURE end_of_report:
  /* Display Footer UnderLine and End of Report Tag (Centered) */
  RUN pdf_skip ("Spdf").
  RUN pdf_stroke_fill ("Spdf",1.0,1.0,1.0).
  RUN pdf_text_boxed_xy ("Spdf", "End of Report", 250, pdf_TextY("Spdf") - 20, pdf_Text_Width("Spdf","End of Report"), 16, "Left",1).
END. /* end_of_report */

PROCEDURE PageFooter:
/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Footer -- on all pages.
------------------------------------------------------------------------------*/

  RUN pdf_skip ("Spdf").
  RUN pdf_set_dash ("Spdf",1,0).
  RUN pdf_line  ("Spdf", 0, pdf_TextY("Spdf") - 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") - 5, 1).
  RUN pdf_skip ("Spdf").
  RUN pdf_skip ("Spdf").
  RUN pdf_text_to  ("Spdf",  "Page: " 
                           + STRING(pdf_page("Spdf"))
                           + " of " + pdf_TotalPages("Spdf"), 97).

END. /* PageFooter */

PROCEDURE PageHeader:

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Header -- on all pages.
------------------------------------------------------------------------------*/

  /* Display a Sample Watermark on every page */
  RUN pdf_watermark ("Spdf","Customer List","Courier-Bold",34,.87,.87,.87,175,500).

  /* Place Logo but only on first page of Report */
  IF pdf_Page("Spdf") = 1 THEN DO:
    RUN pdf_place_image ("Spdf","ProSysLogo",pdf_LeftMargin("Spdf"), pdf_TopMargin("Spdf") - 20 ,179,20).
  END.

  /* Set Header Font Size and Colour */
  RUN pdf_set_font ("Spdf","Courier-Bold",10.0).  
  RUN pdf_text_color ("Spdf",1.0,.0,.0).

  /* Put a Rectangle around the Header */
  RUN pdf_stroke_color ("Spdf", .0,.0,.0).
  RUN pdf_stroke_fill ("Spdf", .9,.9,.9).
  RUN pdf_rect ("Spdf", pdf_LeftMargin("Spdf"), pdf_TextY("Spdf") - 3, pdf_PageWidth("Spdf") - 30  , 12, 0.5).

  /* Output Report Header */
  RUN pdf_text_at  ("Spdf","St",1).
  RUN pdf_text_at  ("Spdf","Nbr",6).
  RUN pdf_text_at  ("Spdf","Customer Name",12). 
  RUN pdf_text_at  ("Spdf","Phone Number",44).
  RUN pdf_text_to  ("Spdf","Balance",80).

  /* Display Header UnderLine */
  RUN pdf_skip ("Spdf").
  RUN pdf_set_dash ("Spdf",1,0).
  RUN pdf_line  ("Spdf", pdf_LeftMargin("Spdf"), pdf_TextY("Spdf") + 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") + 5, 1).
  RUN pdf_skip ("Spdf").
  
  /* Set Detail Font Colour */
  RUN pdf_text_color ("Spdf",.0,.0,.0).

END. /* PageHeader */

message etime view-as alert-box.

IF VALID-HANDLE(h_PDFinc) THEN
  DELETE PROCEDURE h_PDFinc.

/* end of custlist.p */
