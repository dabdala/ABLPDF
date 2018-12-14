/*******************************************************************************

    Program:        itemlist.p
    
    Description:    Sample PDF generation using PDFinlucde.  This sample 
                    illustrates many different options available with PDFinclude.
                    Including font embedding, image embedding, and text
                    placements etc.

*******************************************************************************/

{pdf/pdf_inc.i}

DEFINE VARIABLE Vitems      AS INTEGER NO-UNDO.
DEFINE VARIABLE Vrow        AS INTEGER NO-UNDO.
DEFINE VARIABLE Vcat-desc   AS CHARACTER EXTENT 4 FORMAT "X(40)" NO-UNDO.

/* Create stream for new PDF file */
RUN pdf_new        ("Spdf","itemlist.pdf").

/* Load Bar Code Font */
RUN pdf_load_font  ("Spdf","Code39","pdf/pruebas_ejemplos/code39.ttf","pdf/pruebas_ejemplos/code39.afm",""). 

/* Load and Image that we will use to show how to place onto the page */
RUN pdf_load_image ("Spdf","Product","pdf/pruebas_ejemplos/product.jpg"). 

/* Set Document Information */ 
RUN pdf_set_info("Spdf","Author","Gordon Campbell").
RUN pdf_set_info("Spdf","Subject","Inventory").
RUN pdf_set_info("Spdf","Title","Item Catalog").
RUN pdf_set_info("Spdf","Keywords","Item Catalog Inventory").
RUN pdf_set_info("Spdf","Creator","PDFinclude V2").
RUN pdf_set_info("Spdf","Producer","itemlist.p").

/* Instantiate a New Page */
RUN new_page.

DEFINE VARIABLE minPaginas AS INTEGER NO-UNDO.
/* Loop through appropriate record set */
FOR EACH ITEM NO-LOCK 
    BREAK BY ItemNum:

  Vitems = Vitems + 1.
 
  RUN display_item_info.

  /* Process Record Counter */
  IF Vitems = 6 THEN DO:
    minPaginas = minPaginas + 1.
    IF minPaginas GT 2 THEN
      LEAVE.
    RUN new_page.
  END.

END.

RUN pdf_close("Spdf").

/* -------------------- INTERNAL PROCEDURES -------------------------- */

PROCEDURE display_item_info:

  /* Draw main item Box */
  RUN pdf_stroke_fill("Spdf",.8784,.8588,.7098).
  RUN pdf_rect ("Spdf", pdf_LeftMargin("Spdf"), Vrow, 
                        pdf_PageWidth("Spdf") - 20 , 110,1.0).

  /* Draw Smaller box (beige filled) to contain Category Description */
  RUN pdf_rect ("Spdf", 350, Vrow + 10, 240, 45,1.0).

  /* Draw Smaller box (white filled) to contain Item Picture (when avail) */
  RUN pdf_stroke_fill("Spdf",1.0,1.0,1.0).
  RUN pdf_rect ("Spdf", pdf_LeftMargin("Spdf") + 10, Vrow + 10, 
                        pdf_LeftMargin("Spdf") + 100  , 90,1.0).

  /* Place Link around the Image Box */
  RUN pdf_link ("Spdf", 
                20,                            
                pdf_GraphicY("Spdf") - 90 ,    
                130,                           
                pdf_GraphicY("Spdf"),          
                "http://www.epro-sys.com?ItemNum=" + STRING(Item.ItemNum ),
                1,
                0,
                0,
                1,
                "P").

  /* Display a JPEG picture in the First Box of each Frame */
  IF Vitems = 1 THEN DO:
    RUN pdf_place_image ("Spdf","Product",
                         pdf_LeftMargin("spdf") + 12, 
                         pdf_PageHeight("Spdf") - Vrow - 13,
                         pdf_LeftMargin("Spdf") + 95, 86).
  END.

  /* Display Labels with Bolded Font */
  RUN pdf_set_font("Spdf","Courier-Bold",10.0).
  RUN pdf_text_xy ("Spdf","Part Number:", 140, Vrow + 90).
  RUN pdf_text_xy ("Spdf","Part Name:", 140, Vrow + 80).
  RUN pdf_text_xy ("Spdf","Category 1:", 140, Vrow + 40).
  RUN pdf_text_xy ("Spdf","Category 2:", 140, Vrow + 30).
  RUN pdf_text_xy ("Spdf","Qty On-Hand:", 350, Vrow + 90).
  RUN pdf_text_xy ("Spdf","Price:", 350, Vrow + 80).
  RUN pdf_text_xy ("Spdf","Category Description:", 350, Vrow + 60).
  
  /* Display Fields with regular Font */
  RUN pdf_set_font("Spdf","Courier",10.0).
  RUN pdf_text_xy ("Spdf",STRING(item.ItemNuM), 230, Vrow + 90).
  RUN pdf_text_xy ("Spdf",item.ItemName, 230, Vrow + 80).
  RUN pdf_text_xy ("Spdf",item.Category1, 230, Vrow + 40).
  RUN pdf_text_xy ("Spdf",item.Category2, 230, Vrow + 30).
  RUN pdf_text_xy ("Spdf",STRING(item.OnHand), 440, Vrow + 90).
  RUN pdf_text_xy ("Spdf",TRIM(STRING(item.Price,"$>>,>>9.99-")), 440, Vrow + 80).

  /* Now Load and Display the Category Description */
  RUN load_cat_desc.
  RUN pdf_text_xy ("Spdf",Vcat-desc[1], 352, Vrow + 46).
  RUN pdf_text_xy ("Spdf",Vcat-desc[2], 352, Vrow + 36).
  RUN pdf_text_xy ("Spdf",Vcat-desc[3], 352, Vrow + 26).
  RUN pdf_text_xy ("Spdf",Vcat-desc[4], 352, Vrow + 16).

  /* Display text in Image Box - but not for the first product */
  IF Vitems <> 1 THEN DO:
    RUN pdf_text_color("Spdf",1.0,.0,.0).
    RUN pdf_text_xy ("Spdf","NO", 40, Vrow + 66).
    RUN pdf_text_xy ("Spdf","IMAGE", 40, Vrow + 56).
    RUN pdf_text_xy ("Spdf","AVAILABLE", 40, Vrow + 46).
  END.

  RUN pdf_text_color("Spdf",.0,.0,.0).

  /* Display the Product Number as a Bar Code */
  RUN pdf_set_font("Spdf","Code39",14.0). 
  RUN pdf_text_xy ("Spdf",STRING(item.ItemNuM,"999999999"), 140, Vrow + 60).
  
  Vrow = Vrow - 120.
END. /* display_item_info */

PROCEDURE new_page:
  RUN pdf_new_page("Spdf").

  /* Reset Page Positioning etc */
  ASSIGN Vrow   = pdf_PageHeight("Spdf") - pdf_TopMargin("Spdf") - 110
         Vitems = 0.

END. /* new_page */

PROCEDURE load_cat_desc:
  DEFINE VARIABLE L_cat     AS CHARACTER NO-UNDO.

  DEFINE VARIABLE L_loop    AS INTEGER NO-UNDO.
  DEFINE VARIABLE L_extent  AS INTEGER NO-UNDO.
  
  ASSIGN Vcat-desc = ""
         L_cat      = item.catdescr.
  REPLACE(L_cat,CHR(13),"").
  REPLACE(L_cat,CHR(10),"").

  L_extent = 1.
  DO L_Loop = 1 TO NUM-ENTRIES(L_cat," "):
    IF (LENGTH(Vcat-desc[L_extent]) + LENGTH(ENTRY(L_loop,L_cat," ")) + 1) > 40 
    THEN DO:
      IF L_extent = 4 THEN LEAVE.
      
      L_extent = L_extent + 1.
    END.

    Vcat-desc[L_extent] = Vcat-desc[L_extent] + ENTRY(L_loop,L_cat," ") + " ".
  END.
END. /* load_cat_desc */

/* end of itemlist.p */
