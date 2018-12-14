DEFINE VARIABLE h_PDFtable  AS HANDLE NO-UNDO.
DEFINE VARIABLE h_TT        AS HANDLE NO-UNDO.

DEFINE TEMP-TABLE TT_mydata NO-UNDO RCODE-INFORMATION
    FIELD Custno    LIKE Customer.CustNum
    FIELD CustName  LIKE Customer.Name
    FIELD PhoneNo   LIKE Customer.Phone
    FIELD State     LIKE Customer.State.

/* Build my Temp Table Data */
FOR EACH Customer WHERE name begins "A" NO-LOCK:
  CREATE TT_mydata.
  ASSIGN TT_mydata.CustNo   = Customer.CustNum
         TT_mydata.CustName = Customer.Name
         TT_mydata.PhoneNo  = Customer.Phone
         TT_mydata.State    = Customer.State.
END.

{pdf/pdf_inc.i }

RUN pdf_new("Spdf","table.pdf").

RUN pdf_set_parameter("Spdf","Compress","TRUE"). 

/* Set Page Header procedure */
pdf_PageHeader ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageHeader").

/* Set Page Header procedure */
pdf_PageFooter ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageFooter").

/* Don't want the table to be going until the end of the page or too near the 
   side */
RUN pdf_set_LeftMargin("Spdf",20).
RUN pdf_set_BottomMargin("Spdf",50).

/* Link the Temp-Table to the PDF */
h_TT = TEMP-TABLE TT_mydata:HANDLE.
RUN pdf_tool_add ("Spdf","CustList", "TABLE", h_TT).

/* Now Setup some Parameters for the Table */

/* comment out this section to see what the default Table looks like */
RUN pdf_set_tool_parameter("Spdf","CustList","Outline",0,".5").
RUN pdf_set_tool_parameter("Spdf","CustList","HeaderFont",0,"Helvetica-Bold").
RUN pdf_set_tool_parameter("Spdf","CustList","HeaderFontSize",0,"8").
RUN pdf_set_tool_parameter("Spdf","CustList","HeaderBGColor",0,"255,0,0").
RUN pdf_set_tool_parameter("Spdf","CustList","HeaderTextColor",0,"255,255,255").

RUN pdf_set_tool_parameter("Spdf","CustList","DetailBGColor",0,"200,200,200").
RUN pdf_set_tool_parameter("Spdf","CustList","DetailTextColor",0,"0,0,200").
RUN pdf_set_tool_parameter("Spdf","CustList","DetailFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","CustList","DetailFontSize",0,"8").
/* end of section */

/* Define Table Column Headers */
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnHeader",1,"Customer #").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnHeader",2,"Name").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnHeader",3,"Phone #").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnHeader",4,"State").

/* Define Table Column Widths */
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnWidth",1,"10").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnWidth",2,"30").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnWidth",3,"15").
RUN pdf_set_tool_parameter("Spdf","CustList","ColumnWidth",4,"10").

/* Now produce the table */
RUN pdf_tool_create ("Spdf","CustList").

RUN pdf_close("Spdf").

/* ------------------------ INTERNAL PROCEDURES ---------------------------- */
PROCEDURE PageHeader:

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Header -- on all pages.
------------------------------------------------------------------------------*/

  /* Set Header Font Size and Colour */
  RUN pdf_set_font ("Spdf","Courier-Bold",14.0).  
  RUN pdf_text_color ("Spdf",1.0,.0,.0).

  /* Output Report Header */
  RUN pdf_text_xy  ("Spdf","Customer List",pdf_LeftMargin("Spdf"),pdf_PageHeight("Spdf") - 25).

  RUN pdf_text_color ("Spdf",.0,.0,.0).
  RUN pdf_set_font ("Spdf","Courier",10.0).  

END. /* PageHeader */

PROCEDURE PageFooter:

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Footer -- on all pages.
------------------------------------------------------------------------------*/
  /* Set Footer Font Size and Colour */
  RUN pdf_set_font ("Spdf","Courier-Bold",10.0).  
  RUN pdf_text_color ("Spdf",0.0,.0,.0).
  
  RUN pdf_skip ("Spdf").
  RUN pdf_set_dash ("Spdf",1,0).
  RUN pdf_line  ("Spdf", pdf_LeftMargin("Spdf"), pdf_TextY("Spdf") - 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") - 5, 1).
  RUN pdf_skip ("Spdf").
  RUN pdf_skip ("Spdf").
  RUN pdf_text_to  ("Spdf",  "Page: " 
                           + STRING(pdf_page("Spdf"))
                           + " of " + pdf_TotalPages("Spdf"), 110).


END. /* PageFooter */
