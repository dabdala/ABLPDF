/*******************************************************************************

    Program:        usetags.p
    
    Description:    This sample illustrates the use of inline tagging.
                        

*******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

DEFINE VARIABLE sPDF  AS CHARACTER NO-UNDO INIT "sPDF".
DEFINE VARIABLE cText AS CHARACTER NO-UNDO.

DEFINE VARIABLE iMaxY AS INTEGER NO-UNDO.

ASSIGN cText = "This is some text that illustrates <b>bolded</b>,"
             + "<i>italicized</i> and <b><i>a combination of both</i></b>"
             + " formatting options." + CHR(10)
             + "This is in <color=red>red</color>." + CHR(10)
             + "<color=red>Starting in red, change to <color=black>black</color>"
             + " then continue in red</color> but end in default color"
             + "<color=green><i>,whoops, try italicized green</i></color>.".

/* Create stream for new PDF file */
RUN pdf_new        (sPDF,"usetags.pdf").

RUN pdf_set_parameter(sPDF,"COMPRESS","TRUE"). 

/* Setup Tagging */
RUN pdf_set_parameter(sPDF,"TagColor:Black","0,0,0").
RUN pdf_set_parameter(sPDF,"TagColor:Red","255,0,0").
RUN pdf_set_parameter(sPDF,"TagColor:Green","0,200,0").
RUN pdf_set_parameter(sPDF,"TagColor:Blue","0,0,255").

RUN pdf_set_parameter(sPDF,"UseTags","TRUE").
RUN pdf_set_parameter(sPDF,"BoldFont","Courier-Bold").
RUN pdf_set_parameter(sPDF,"ItalicFont","Courier-Oblique").
RUN pdf_set_parameter(sPDF,"BoldItalicFont","Courier-BoldOblique").
RUN pdf_set_parameter(sPDF,"DefaultFont","Courier").
RUN pdf_set_parameter(sPDF,"DefaultColor","Black").
 
/* Instantiate a New Page */
RUN pdf_new_page(sPDF).

/* This outputs the tagged text and formats it accordingly */
RUN pdf_wrap_text(sPDF,
                  cText,
                  5,
                  75,
                  "LEFT",
                  OUTPUT iMaxY).

RUN pdf_set_parameter(sPDF,"UseTags","FALSE").

cText = "This is some text that has tags like <b>bold</b> and <i>italic</i>"
      + " but tagging has been turned off so they won't be interpreted.".
RUN pdf_skipn(sPDF,2).
RUN pdf_wrap_text(sPDF,
                  cText,
                  5,
                  75,
                  "LEFT",
                  OUTPUT iMaxY).

RUN pdf_set_parameter(sPDF,"UseTags","TRUE").

cText = "Then I re-enable the tags like <b>bold</b> and <i>italic</i>"
      + " but I don't have to <color=red>reset</color> the tagging configuration".
RUN pdf_skipn(sPDF,2).
RUN pdf_wrap_text(sPDF,
                  cText,
                  5,
                  75,
                  "LEFT",
                  OUTPUT iMaxY).

RUN pdf_close(sPDF).

/* usetags.p */
