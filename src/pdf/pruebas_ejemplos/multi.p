/******************************************************************************

    Program:        multi.p
    
    Description:    This program illustrates the creation of multiple documents
                    within a single procedure.

******************************************************************************/

{pdf/pdf_inc.i}

RUN pdf_new ("Spdf","multiOne.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_text    ("Spdf", "Multiple Document One!").
 
RUN pdf_close("Spdf").

RUN pdf_new ("Spdf","multiTwo.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_text    ("Spdf", "Multiple Document Two!").

RUN pdf_close("Spdf").

/* end of multi.p */
