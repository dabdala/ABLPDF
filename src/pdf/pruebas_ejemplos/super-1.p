/******************************************************************************

    Program:        super-1.p
    
    Description:    This program uses the Session Super of PDFinclude.

                    Called from super.p

******************************************************************************/

RUN pdf_new ("Spdf","super-1.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_text    ("Spdf", "Super One!").

RUN pdf_close("Spdf").

/* end of super-1.pdf */
