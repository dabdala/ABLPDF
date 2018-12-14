/******************************************************************************

    Program:        rotatetext.p
    
    Description:    Illustrates the rotation of text available via PDFinclude.

******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

RUN pdf_new ("Spdf","rotatetext.pdf").
RUN pdf_new_page("Spdf").

/* Place some text */
RUN pdf_text    ("Spdf", FILL("HORIZONTAL ",2)).

RUN pdf_text_rotate ("Spdf",90).
RUN pdf_text    ("Spdf", FILL("VERTICAL ",2)).

RUN pdf_text_rotate ("Spdf",0).
RUN pdf_text    ("Spdf", FILL("HORIZON ",2)).

RUN pdf_text_rotate ("Spdf",270).
RUN pdf_text    ("Spdf", FILL("VERT ",2)).

RUN pdf_text_rotate ("Spdf",0).
RUN pdf_set_font ("Spdf",pdf_Font("Spdf"),12).
RUN pdf_text_color ("Spdf",1,0,0).
RUN pdf_text    ("Spdf", "SNAKEHEAD----8~~ ").

/* Part 2 */
RUN pdf_text_rotate ("Spdf",0).
RUN pdf_skipn("Spdf",15).
RUN pdf_text_at    ("Spdf", "HORIZONTAL HORIZONTAL  ",1).

RUN pdf_text_rotate ("Spdf",45).
RUN pdf_text    ("Spdf", " 045 DEGREES").

RUN pdf_text_rotate ("Spdf",315).
RUN pdf_text    ("Spdf", " 315 DEGREES").

RUN pdf_text_rotate ("Spdf",135).
RUN pdf_text    ("Spdf", " 135 DEGREES").

RUN pdf_text_rotate ("Spdf",225).
RUN pdf_text    ("Spdf", " 225 DEGREES").

RUN pdf_text_rotate ("Spdf",0).
RUN pdf_text    ("Spdf", "  HORIZONTAL HORIZONTAL ").
/* End Part 2 */


RUN pdf_close("Spdf").

/* end of rotatetext.p */
