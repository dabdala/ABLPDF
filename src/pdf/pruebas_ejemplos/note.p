/*******************************************************************************

    Program:        note.p
    
    Description:    This sample illustrates some of the different annotations
                    available.  Namely:
                    
                    Note
                    Stamp
                    Markup (Highlight,Squiggly,Underline or StrikeOut)

*******************************************************************************/

{pdf/pdf_inc.i}

DEFINE VARIABLE Vitems      AS INTEGER NO-UNDO.
DEFINE VARIABLE Vrow        AS INTEGER NO-UNDO.
DEFINE VARIABLE Vcat-desc   AS CHARACTER EXTENT 4 FORMAT "X(40)" NO-UNDO.

/* Create stream for new PDF file */
RUN pdf_new        ("Spdf","note.pdf").

RUN pdf_set_parameter("Spdf","COMPRESS","TRUE"). 
RUN pdf_set_BottomMargin("Spdf",80).

/* Set Document Information */ 
RUN pdf_set_info("Spdf","Author","Gordon Campbell").
RUN pdf_set_info("Spdf","Subject","Inventory").
RUN pdf_set_info("Spdf","Title","Item Notes").
RUN pdf_set_info("Spdf","Keywords","Item Notes").
RUN pdf_set_info("Spdf","Creator","PDFinclude").
RUN pdf_set_info("Spdf","Producer","note.p").

/* Instantiate a New Page */
RUN pdf_new_page("Spdf").

/* add a 'Stamp' annotation to the first page */
RUN pdf_stamp("Spdf",
             "This is a Stamp Annotation and it appears on Page 1 only.",
             "Draft Header",
             "Draft",
             450,
             725,
             550,
             775,
             0.0,
             0.0,
             1.0).

/* Loop through appropriate record set */
FOR EACH ITEM NO-LOCK 
    BREAK BY ItemNum:
 
  RUN pdf_text_at("Spdf",STRING(item.itemnum),10).
  RUN pdf_text("Spdf"," " + item.ItemName).
  RUN pdf_text_to("Spdf",STRING(item.price),40).

  /* add a 'Note' annotation for the item */
  RUN pdf_note("Spdf",
               item.CatDescription,
               item.ItemName,
               "Comment",
               300,
               pdf_TextY("Spdf") + pdf_PointSize("Spdf"),
               310,
               pdf_TextY("Spdf") + pdf_PointSize("Spdf"),
               1.0,
               0.0,
               0.0).

  /* add a 'Highlight' annotation for the item */
  RUN pdf_markup("Spdf",
               item.CatDescription,
               item.ItemName,
               "Highlight",

               60,  
               pdf_TextY("Spdf") + 8 ,
               200,
               pdf_TextY("Spdf") + 8,

               60,
               pdf_TextY("Spdf") - 2,
               200,
               pdf_TextY("Spdf") - 2,

               1.0,
               1.0,
               0.0).

  RUN pdf_skipn("Spdf",2).

END.

RUN pdf_close("Spdf").

/* note.p */
