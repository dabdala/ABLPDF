/******************************************************************************

  Program:      calendar-eoru.p
  
  Written By:   Gordon Campbell
  Written On:   June 2004
  
  Description:  This program illustrates the use of the CALENDAR tool that was
                added to the pdftool.p procedure in February 2004.

                This procedure creates four calendars on a single page.  You
                can manipulate the size, location, fonts, colours, and text
                of the calendar.
                
                In future, I will add the functionality to associate a 
                different colour scheme for a specific day.
                
                This uses the European format for the Day Label ... starting on
                a Monday not a Sunday.
                
******************************************************************************/

DEFINE VARIABLE i_Month AS INTEGER NO-UNDO.
DEFINE VARIABLE i_Row   AS INTEGER NO-UNDO.
DEFINE VARIABLE i_X     AS INTEGER NO-UNDO.
DEFINE VARIABLE i_Y     AS INTEGER NO-UNDO.

DEFINE VARIABLE c_Months  AS CHARACTER NO-UNDO
       INIT "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec".

{pdf/pdf_inc.i}

RUN pdf_new("Spdf","calendar-euro.pdf").

RUN pdf_set_parameter("Spdf","Compress","TRUE").

RUN pdf_new_page("Spdf").

/* Make the rectangles in the CALENDAR be filled with White */
RUN pdf_stroke_fill("Spdf",1.0,1.0,1.0).

ASSIGN i_X = 10
       i_Y = 600.

DO i_Month = 1 TO 12:

  RUN pdf_tool_add ("Spdf","Month" + STRING(i_Month), "CALENDAR", ?).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"HeaderHeight",0,"50").
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Title",0,ENTRY(i_Month,c_Months) + " " + STRING(YEAR(TODAY))).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Height",0,STRING(125)).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Width",0,STRING(125)).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"X",0,STRING(i_X)).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Y",0,STRING(i_Y)).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Year",0,STRING(YEAR(TODAY))).
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Month",0,STRING(i_Month)).

  /* For Starting Day on Monday 
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Weekdays",0,"Mon,Tue,Wed,Thu,Fri,Sat,Sun"). 
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"WeekdayStart",0,"2"). */

  /* For Starting Day on Friday
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Weekdays",0,"Fri,Sat,Sun,Mon,Tue,Wed,Thu"). 
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"WeekdayStart",0,"6").
  */

  /* For Starting Day on Saturday */
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"Weekdays",0,"Sat,Sun,Mon,Tue,Wed,Thu,Fri"). 
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"WeekdayStart",0,"7").

  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayFontSize",0,"6").
  RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayLabelFontSize",0,"6").

  /* If drawing the current month, then highlight todays date */
  IF i_Month = MONTH(TODAY) THEN DO:
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayFontSize",DAY(TODAY),"9").
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayFontColor",DAY(TODAY),"255,0,0").    
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayHighlight",DAY(TODAY),"This is the current day of the year").    
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"HighlightColor",0,"0,255,0").    
  END.

  IF i_Month = 06 THEN DO:
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayFontSize",14,"9").
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayFontColor",DAY(TODAY),"0,0,0").    
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"DayHighlight",14,"This is Gordon's Birthday").    
    RUN pdf_set_tool_parameter("Spdf","Month" + STRING(i_Month),"HighlightColor",0,"255,0,0").    
  END.

  /* Now produce the CALENDAR */
  RUN pdf_tool_create ("Spdf","Month" + STRING(i_Month)).

  i_X = i_X + 135.

  IF i_Month MODULO 3 = 0 THEN
    ASSIGN i_Y = i_Y - 150
           i_X = 10.

END. /* i_Month */

RUN pdf_close("Spdf").

/* ------------------------ INTERNAL PROCEDURES ---------------------------- */
