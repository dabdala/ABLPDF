DEFINE VARIABLE v_MonthList AS CHARACTER NO-UNDO
       INIT "January,February,March,April,May,June,July,August,September,October,November,December".
DEFINE VARIABLE v_DayList AS CHARACTER NO-UNDO
       INIT "SUNDAY,MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY".

DEFINE VARIABLE v_Month   AS INTEGER NO-UNDO.
DEFINE VARIABLE v_Day     AS INTEGER NO-UNDO.
DEFINE VARIABLE v_WeekDay AS INTEGER NO-UNDO.
DEFINE VARIABLE v_Row     AS INTEGER NO-UNDO.
DEFINE VARIABLE v_X       AS INTEGER NO-UNDO.
DEFINE VARIABLE v_Y       AS INTEGER NO-UNDO.
DEFINE VARIABLE v_Loop    AS INTEGER NO-UNDO.

{pdf/pdf_inc.i}

RUN pdf_new("Spdf","calendar.pdf").
RUN pdf_set_orientation("Spdf","Landscape").

DO v_Month = 1 TO 12:
  RUN pdf_new_page("Spdf").

  /* Draw Border */
  RUN pdf_stroke_fill  ("Spdf",1.0,1.0,1.0).
  RUN pdf_rect  ("Spdf", 30, 
                         30, 
                         pdf_PageWidth("Spdf") - 50, 
                         pdf_PageHeight("Spdf") - 50, .5).
  RUN pdf_rect  ("Spdf", 33, 
                         33, 
                         pdf_PageWidth("Spdf") - 56, 
                         pdf_PageHeight("Spdf") - 56, .5).

  /* Draw Week Sections - 5 per month */
  DO v_Loop = 1 TO 6:
    RUN pdf_line  ("Spdf", 33, 
                           100 * v_Loop - 67, 
                           pdf_PageWidth("Spdf") - 24, 
                           100 * v_Loop - 67, 
                           .5).

  END. /* week sections */

  /* Draw Day Sections - 7 per week */
  DO v_Loop = 1 TO 7:

    RUN pdf_line  ("Spdf", 105 * v_Loop - (72),
                           33,
                            105 * v_Loop - (72),
                           pdf_PageHeight("Spdf") - 63,
                           .5).

  END. /* week sections */
  
  /* Draw Day Boxes */
  RUN pdf_stroke_fill  ("Spdf",.9,.9,.9).
  DO v_Loop = 1 TO 7:

    /* Need this to ensure that the lines meet correctly */
    IF v_Loop = 7 THEN
      RUN pdf_rect  ("Spdf", 105 * v_Loop - (72), 
                             535 ,
                             106, 
                             20, .5).
    ELSE
      RUN pdf_rect  ("Spdf", 105 * v_Loop - (72), 
                             535 ,
                             105, 
                             20, .5).
  END. /* Day Boxes */

  /* Draw The Month on the Top Left Hand Corner */
  RUN pdf_set_font("Spdf","Courier-Bold",24.0).
  RUN pdf_text_color("Spdf",0.9,0.0,0.0).
  RUN pdf_text_xy("Spdf",ENTRY(v_Month, v_MonthList) 
                         + " " + STRING(YEAR(TODAY)) ,40, 565).

  /* Draw Day Titles*/
  RUN pdf_set_font("Spdf","Courier",10.0).
  RUN pdf_text_color("Spdf",0.0,0.0,0.0).
  DO v_Loop = 1 TO 7:

    RUN pdf_text_xy  ("Spdf", 
                      ENTRY(v_Loop, v_DayList),
                      105 * v_Loop - (65),
                      540).
  END. /* Day Boxes */

  /* Determine how many Days in the Current Year/Month */
  /* Now go through each day in the Month and add to Calendar */
  v_Loop = DAY(DATE((v_Month MODULO 12) + 1, 1,
                    YEAR(TODAY) + INTEGER(TRUNCATE(v_Month / 12, 0))) - 1).
  ASSIGN v_Row = 0
         v_Y   = 520.
  DO v_Day = 1 TO v_Loop:

    v_WeekDay = WEEKDAY(DATE(v_Month,v_Day ,YEAR(TODAY))).

    IF v_WeekDay = 1 AND v_Day <> 1 THEN
      v_Row = v_Row + 1.

    /* This is to accommodate Months (like May 2004) that actually have more
       than 5 rows of days */
    IF v_Row = 5 THEN DO:
      RUN pdf_text_xy("Spdf",
                      STRING(v_Day),
                      105 * v_WeekDay - (65),
                      (v_Y - (v_Row * 100)) + 50).

      RUN pdf_line  ("Spdf", 105 * v_WeekDay - (65),
                             (v_Y - (v_Row * 100)) + 60,
                              105 * v_WeekDay - (65) + 80,
                             (v_Y - (v_Row * 100)) + 60,
                             .5).

    END. /* Row 5 */

    ELSE
      RUN pdf_text_xy("Spdf",
                      STRING(v_Day),
                      105 * v_WeekDay - (65),
                      v_Y - (v_Row * 100)).

  END. /* Show Day Numbers */

END. /* Month */

RUN pdf_close("Spdf").

