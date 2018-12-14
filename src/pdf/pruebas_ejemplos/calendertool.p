/******************************************************************************

  Program:      calendartool.p
  
  Written By:   Gordon Campbell
  Written On:   February 2004
  
  Description:  This program illustrates the use of the CALENDAR tool that was
                added to the pdftool.p procedure in February 2004.

                This procedure creates four calendars on a single page.  You
                can manipulate the size, location, fonts, colours, and text
                of the calendar.
                
                In future, I will add the functionality to associate a 
                different colour scheme for a specific day.
                
******************************************************************************/
{pdf/pdf_inc.i}

RUN pdf_new("Spdf","calendartool.pdf").

RUN pdf_new_page("Spdf").

/* Make the rectangles in the CALENDAR be filled with White */
RUN pdf_stroke_fill("Spdf",1.0,1.0,1.0).

/* Now Setup some Parameters for the CALENDAR for May 2004 */
RUN pdf_tool_add ("Spdf","Month5", "CALENDAR", ?).
RUN pdf_set_tool_parameter("Spdf","Month5","HeaderHeight",0,"50").
RUN pdf_set_tool_parameter("Spdf","Month5","Title",0,"May 2004").
RUN pdf_set_tool_parameter("Spdf","Month5","Height",0,STRING(200)).
RUN pdf_set_tool_parameter("Spdf","Month5","Width",0,STRING(200)).
RUN pdf_set_tool_parameter("Spdf","Month5","X",0,"10").
RUN pdf_set_tool_parameter("Spdf","Month5","Y",0,"575").
RUN pdf_set_tool_parameter("Spdf","Month5","Year",0,"2004").
RUN pdf_set_tool_parameter("Spdf","Month5","Month",0,"5").
RUN pdf_set_tool_parameter("Spdf","Month5","Weekdays",0,"Sun,Mon,Tue,Wed,Thu,Fri,Sat").

/* Now produce the CALENDAR */
RUN pdf_tool_create ("Spdf","Month5").

/* Now Setup some Parameters for the CALENDAR for February 2004 */
RUN pdf_tool_add ("Spdf","Month2", "CALENDAR", ?).
RUN pdf_set_tool_parameter("Spdf","Month2","Title",0,"February 2004").
RUN pdf_set_tool_parameter("Spdf","Month2","HeaderHeight",0,"50").

RUN pdf_set_tool_parameter("Spdf","Month2","HeaderFontSize",0,"24").
RUN pdf_set_tool_parameter("Spdf","Month2","HeaderFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month2","DayLabelHeight",0,"15").
RUN pdf_set_tool_parameter("Spdf","Month2","DayLabelFontSize",0,"10").
RUN pdf_set_tool_parameter("Spdf","Month2","DayLabelFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month2","DayFontSize",0,"8").
RUN pdf_set_tool_parameter("Spdf","Month2","DayFont",0,"Helvetica").

RUN pdf_set_tool_parameter("Spdf","Month2","Height",0,STRING(200)).
RUN pdf_set_tool_parameter("Spdf","Month2","Width",0,STRING(200)).
RUN pdf_set_tool_parameter("Spdf","Month2","X",0,"220").
RUN pdf_set_tool_parameter("Spdf","Month2","Y",0,"575").
RUN pdf_set_tool_parameter("Spdf","Month2","Year",0,"2004").
RUN pdf_set_tool_parameter("Spdf","Month2","Month",0,"2").
RUN pdf_set_tool_parameter("Spdf","Month2","Weekdays",0,"Sun,Mon,Tue,Wed,Thu,Fri,Sat").

RUN pdf_tool_create ("Spdf","Month2").

/* Now Setup some Parameters for the CALENDAR for March 2004 */
RUN pdf_tool_add ("Spdf","Month3", "CALENDAR", ?).
RUN pdf_set_tool_parameter("Spdf","Month3","Title",0,"March 2004").
RUN pdf_set_tool_parameter("Spdf","Month3","HeaderHeight",0,"20").

RUN pdf_set_tool_parameter("Spdf","Month3","HeaderFontSize",0,"15").
RUN pdf_set_tool_parameter("Spdf","Month3","HeaderFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3","HeaderFontColor",0,"256,0,0").
RUN pdf_set_tool_parameter("Spdf","Month3","HeaderBGColor",0,"200,0,0").

RUN pdf_set_tool_parameter("Spdf","Month3","DayLabelHeight",0,"10").
RUN pdf_set_tool_parameter("Spdf","Month3","DayLabelFontSize",0,"5").
RUN pdf_set_tool_parameter("Spdf","Month3","DayLabelFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3","DayLabelFontColor",0,"0,200,0").
RUN pdf_set_tool_parameter("Spdf","Month3","DayLabelBGColor",0,"0,106,0").

RUN pdf_set_tool_parameter("Spdf","Month3","DayFontSize",0,"6").
RUN pdf_set_tool_parameter("Spdf","Month3","DayFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3","DayFontColor",0,"256,256,256").
RUN pdf_set_tool_parameter("Spdf","Month3","DayBGColor",0,"141,182,205").
                                                                  
RUN pdf_set_tool_parameter("Spdf","Month3","Height",0,STRING(100)).
RUN pdf_set_tool_parameter("Spdf","Month3","Width",0,STRING(100)).
RUN pdf_set_tool_parameter("Spdf","Month3","X",0,"10").
RUN pdf_set_tool_parameter("Spdf","Month3","Y",0,"450").
RUN pdf_set_tool_parameter("Spdf","Month3","Year",0,"2004").
RUN pdf_set_tool_parameter("Spdf","Month3","Month",0,"3").
RUN pdf_set_tool_parameter("Spdf","Month3","Weekdays",0,"Sun,Mon,Tue,Wed,Thu,Fri,Sat").

RUN pdf_tool_create ("Spdf","Month3").

/* New Redo the May 2004 in different colours and size and French */
RUN pdf_tool_add ("Spdf","Month3B", "CALENDAR", ?).
RUN pdf_set_tool_parameter("Spdf","Month3B","Title",0,"Mars 2004").
RUN pdf_set_tool_parameter("Spdf","Month3B","HeaderHeight",0,"100").

RUN pdf_set_tool_parameter("Spdf","Month3B","HeaderFontSize",0,"15").
RUN pdf_set_tool_parameter("Spdf","Month3B","HeaderFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3B","HeaderFontColor",0,"256,256,256").
RUN pdf_set_tool_parameter("Spdf","Month3B","HeaderBGColor",0,"200,0,0").

RUN pdf_set_tool_parameter("Spdf","Month3B","DayLabelHeight",0,"10").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayLabelFontSize",0,"8").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayLabelFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayLabelFontColor",0,"256,256,256").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayLabelBGColor",0,"0,106,0").

RUN pdf_set_tool_parameter("Spdf","Month3B","DayFontSize",0,"6").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayFont",0,"Helvetica").
RUN pdf_set_tool_parameter("Spdf","Month3B","DayFontColor",0,"0,0,256").
                                                                  
RUN pdf_set_tool_parameter("Spdf","Month3B","Height",0,STRING(300)).
RUN pdf_set_tool_parameter("Spdf","Month3B","Width",0,STRING(300)).
RUN pdf_set_tool_parameter("Spdf","Month3B","X",0,"250").
RUN pdf_set_tool_parameter("Spdf","Month3B","Y",0,"250").
RUN pdf_set_tool_parameter("Spdf","Month3B","Year",0,"2004").
RUN pdf_set_tool_parameter("Spdf","Month3B","Month",0,"3").
RUN pdf_set_tool_parameter("Spdf","Month3B","Weekdays",0,"Dimanche,Lundi,Mardi,Mercredi,Jeudi,Vendredi,Samedi").

RUN pdf_tool_create ("Spdf","Month3B").

RUN pdf_close("Spdf").

/* ------------------------ INTERNAL PROCEDURES ---------------------------- */
