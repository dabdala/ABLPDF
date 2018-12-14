/******************************************************************************

    Program:        orient.p
    
    Description:    This program illustrates how you can change the orientation.
                    of the page within the PDF document.

******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

RUN pdf_new ("Spdf","orient.pdf").

RUN pdf_set_parameter("Spdf","PageLayout","OneColumn").

RUN pdf_new_page2("Spdf","Landscape").
RUN pdf_text("Spdf","This page appears in Landscape mode!").

RUN pdf_new_page2("Spdf","Portrait").
RUN pdf_text("Spdf","This page appears in Portrait mode!").

RUN pdf_new_page2("Spdf","Landscape").
RUN pdf_text("Spdf","Now I changed it back to landscape!").

RUN pdf_close("Spdf").

/* end of orient.pdf */
