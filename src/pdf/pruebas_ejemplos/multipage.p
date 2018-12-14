DEFINE VARIABLE iCurrentPage  AS INTEGER NO-UNDO.
{pdf/pdf_inc.i }

RUN pdf_new("Spdf","multipage.pdf").

/* The following produces 4 pages */
RUN pdf_new_page("Spdf").
RUN pdf_text("Spdf","Page1").

RUN pdf_new_page("Spdf").
RUN pdf_text("Spdf","Page2").

RUN pdf_new_page("Spdf").
RUN pdf_text("Spdf","Page3").

RUN pdf_new_page("Spdf").
RUN pdf_text("Spdf","Page4").

/* This codes places new text on each pages 1 thru 3 */
DO iCurrentPage = 1 To 3:
  RUN pdf_set_page("Spdf",iCurrentPage).
  RUN pdf_skip("Spdf").
  RUN pdf_text("Spdf","Page " + STRING(iCurrentPage) + " of 3").
  
END.

RUN pdf_close("Spdf").
