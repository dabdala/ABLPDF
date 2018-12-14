/******************************************************************************

    Program:        link.p
    
    Description:    Illustrates a text object used as a link

******************************************************************************/

{pdf/pdf_inc.i}

RUN pdf_new ("Spdf","link.pdf").
RUN pdf_new_page("Spdf").

/* Place some text */
RUN pdf_text  ("Spdf", FILL("123456789 ",8)). 
RUN pdf_skip  ("Spdf").
RUN pdf_text  ("Spdf", "Press the big blue rectangle below").
RUN pdf_link  ("Spdf", 100,100,300,300,"http://www.epro-sys.com",0.0,0.0,1.0,1,"I").

RUN pdf_close("Spdf").

/* end of link.p */
