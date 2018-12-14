/******************************************************************************

    Program:        curve.p
    
    Description:    Illustrates a curve

******************************************************************************/

{pdf/pdf_inc.i}

RUN pdf_new ("Spdf","curve.pdf").
RUN pdf_new_page("Spdf").

RUN pdf_stroke_color("Spdf",0.0, 1.0, 0.0). 
RUN pdf_stroke_fill("Spdf",0.0, 1.0, 0.0). 

RUN pdf_move_to("Spdf",250,200).
RUN pdf_curve("Spdf",350,282.84271,282.84271,350,200,350,1.0).
RUN pdf_close_path("Spdf"). 

RUN pdf_stroke_color("Spdf",0.0, 0.0, 1.0). 
RUN pdf_stroke_fill("Spdf",0.0, 0.0, 1.0). 

RUN pdf_move_to("Spdf",150,100).
RUN pdf_curve("Spdf",350,282.84271,282.84271,350,200,350,1.0).
RUN pdf_close_path("Spdf"). 

RUN pdf_close("Spdf").

/* end of curve.p */
