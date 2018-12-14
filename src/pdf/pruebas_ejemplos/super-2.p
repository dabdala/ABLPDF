/******************************************************************************

    Program:        super-1.p
    
    Description:    This program uses the super Super of PDFinclude.

                    Called from super.p

******************************************************************************/

RUN pdf_new ("Spdf","super-2.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_text    ("Spdf", "Super Two!").

RUN pdf_close("Spdf").

/* end of super-2.pdf */
