/******************************************************************************

    Program:        super-3a.p
    
    Description:    This program uses the super Super of PDFinclude.
    
                    Called from super-3.p

******************************************************************************/

RUN pdf_new ("Spdf","super-3a.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_text    ("Spdf", "Super Three, eh!").

RUN pdf_close("Spdf").

/* end of super-3a.pdf */
