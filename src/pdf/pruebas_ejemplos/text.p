/******************************************************************************

    Program:        text.p
    
    Description:    Illustrates the many possible text rendering and placement
                    options available via PDFinclude.

******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

RUN pdf_new ("Spdf","text.pdf").
RUN pdf_new_page("Spdf").

/* Place some text */
RUN pdf_text    ("Spdf", FILL("123456789 ",8)).
RUN pdf_skip    ("Spdf").
RUN pdf_text_at ("Spdf", "Position AT Column 10",10).
RUN pdf_text_to ("Spdf", "Position TO Column 70",70).
RUN pdf_text    ("Spdf", "Text placed at last X/Y Coordinate").
RUN pdf_skip    ("Spdf").

/* Change the text color to red */
RUN pdf_text_color("Spdf",1.0,.0,.0).

RUN pdf_set_font("Spdf","Courier",14.0).
RUN pdf_text_xy ("Spdf","This is larger text placed using XY coordinates",100,100).
RUN pdf_set_font("Spdf","Courier",10.0).

/* Change the text color back to black */
RUN pdf_text_color("Spdf",.0,.0,.0).

/* Change the Rectangle border to red and the fill to white */
RUN pdf_stroke_color("Spdf",1.0,.0,.0).
RUN pdf_stroke_fill("Spdf",1.0,1.0,1.0).

/* Display a boxed text string */
RUN pdf_text_boxed_xy ("Spdf",
                       "This is BOXED text placed using XY coordinates",
                       100,
                       450,
                       pdf_text_width("Spdf", "This is BOXED text placed using XY coordinates"),
                       10,"Left",1).

RUN pdf_close("Spdf").

/* end of text.p */
