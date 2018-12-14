/*******************************************************************************

    Program:        custlist.cls
    
    DeCode 39ion:    Illustrates how to interact Progress reporting requirements
                    with ABLPDF

    History:        Based on custlist.p from PDFInclude    

*******************************************************************************/

DEFINE VARIABLE lobPDF AS pdf.Documento NO-UNDO.

DEFINE VARIABLE Vold_Y      AS INTEGER NO-UNDO.

DEFINE VARIABLE vStateBook  AS INTEGER NO-UNDO.
DEFINE VARIABLE vCustBook   AS INTEGER NO-UNDO.
DEFINE VARIABLE vNullBook   AS INTEGER NO-UNDO.

ETIME(yes).

/* Create stream for new PDF file */
lobPDF = NEW pdf.Documento().
lobPDF:cobDestino = NEW pdf.destinos.Archivo("custlist-comp-cls.pdf").

/* RUN pdf_set_parameter("Spdf","Encrypt","TRUE"). */ 

lobPDF:cobPermisos:clgImprimir = False.
lobPDF:cobPermisos:clgCopiar = False.
lobPDF:cobPermisos:clgModificar = False.

/* RUN pdf_set_parameter("Spdf","MasterPassword","Custom").
RUN pdf_set_parameter("Spdf","UserPassword","Custom"). */ 

lobPDF:cobCompresor = NEW pdf.compresores.FlateDecode().

lobPDF:CabeceraDePagina:Subscribe("PageHeader").
lobPDF:PieDePagina:Subscribe("PageFooter").

/* Load Bar Code Font */
NEW pdf.letras.TipoDeLetra(lobPDF,"Code 39","pdf/pruebas_ejemplos/code39.ttf","pdf/pruebas_ejemplos/code39.afm","").

/* Load PRO-SYS Logo File */
NEW pdf.imagenes.ImagenPNG(lobPDF,"NomadeLogo","pdf/pruebas_ejemplos/nomade-head.png").

/* Set Document Information */
lobPDF:cchAutor = 'David Abdala (actually Gordon Campbell)'
lobPDF:cchAsunto = "Accounts Receivable".
lobPDF:cchTitulo = "Customer List".
lobPDF:cchPalabrasClave = "Customer List Accounts Receivable".
lobPDF:cchCreador = "ABLPDF".
lobPDF:cchProductor = "custlist_cls.p".

/* Set the Bottom Margin to 80 - to allow for Page Footer */
lobPDF:cinAltoPieDePagina = 80.

/* Instantiate a New Page */
lobPDF:AgregarPagina().

/* Loop through appropriate record set */
FOR EACH customer WHERE NAME BEGINS "A"
                    /* AND ( State = "AZ" OR State = "AK" or state = "") */
                    NO-LOCK 
    BREAK BY State
          BY CustNum:

  /* Create a Bookmark to each State  */
  IF FIRST-OF(Customer.State) THEN DO:
    FIND FIRST State WHERE State.State = Customer.State NO-LOCK NO-ERROR.
    IF NOT AVAIL State THEN DO:
      lobMarca = NEW pdf.utiles.MarcaDeLectura(lobPDF,"Unknown - ('" + Customer.State + "')").
      vStateBook = mobPDF:marcaDeLecturaRegistrada(lobMarca).
    ELSE DO:
      lobMarca = NEW pdf.utiles.MarcaDeLectura(lobPDF,State.StateName).
      vStateBook = mobPDF:marcaDeLecturaRegistrada(lobMarca).
    END.
  END. /* First-of State */

  /* Output the appropriate Record information */
  lobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre ="Courier-Oblique".
  lobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = 10.0.
  lobPDF:cobPaginaActual:TextoEnColumna(customer.state,1).
  lobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre ="Courier".
  lobPDF:cobPaginaActual:TextoEnColumna(STRING(customer.CustNum,">>>9"),6).
  lobPDF:cobPaginaActual:TextoEnColumna(customer.NAME,12).
  lobPDF:cobPaginaActual:TextoEnColumna(customer.phone,44).
  lobPDF:cobPaginaActual:TextoHastaColumna(STRING(customer.balance),80).

  /* Create a Bookmark to Each Customer Name within a State 
  lobMarca = NEW pdf.utiles.MarcaDeLectura(lobPDF,Customer.Name).
  lobMarca:cobPadre = lobPDF:marcaDeLecturaRegistrada(vStateBook).
  vCustBook = mobPDF:marcaDeLecturaRegistrada(lobMarca).
  */

  /* Place a weblink around the Customer Name 
  RUN pdf_link ("Spdf",
                75,
                pdf_TextY("Spdf")/* pdf_PageHeight("Spdf") - (pdf_TopMargin("Spdf")) - ((Vlines + 2) * 10 ) */,
                260,
                pdf_TextY("Spdf") /* pdf_PageHeight("Spdf") - (pdf_TopMargin("Spdf")) - ((Vlines + 2) * 10) */ + 10,
                "http://www.epro-sys.com/Code 39s/cgiip.exe/WService=sports2000/custorderspdf.p?CustNum=" + STRING(Customer.CustNum),
                0,
                0,
                0,
                1,
                "I").
  */

  /* Display a BarCode for each Customer Number */
  lobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre ="Code 39".

  Vold_Y = pdf_TextY("Spdf").  /* Store Original Text Path */
  RUN pdf_text_xy ("Spdf", STRING(customer.CustNum,"999999"),500, pdf_textY("Spdf")).
  RUN pdf_set_TextY("Spdf",Vold_y). /* Reset Original Text Path */
  lobPDF:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre ="Courier".

  /* Skip to Next Text Line */
  lobPDF:cobPaginaActual:SaltoDeLinea().  
  
  /* Now Display all Orders for the Customer */
  FOR EACH Order WHERE Order.CustNum = Customer.CustNum NO-LOCK:
    lobPDF:cobPaginaActual:TextoEnColumna(Order.OrderNum,10).
    lobPDF:cobPaginaActual:TextoEnColumna(STRING(Order.OrderDate),30).

    /* Create a Bookmark to Each Order For a Customer 
    RUN pdf_bookmark("Spdf", Order.OrderNum, vCustBook, FALSE, OUTPUT vNullBook).
    */

    lobPDF:cobPaginaActual:SaltoDeLinea().  
  END.

  IF LAST-OF(Customer.State) THEN DO:
    /* Put a red line between each of the states */
    lobPDF:cobPaginaActual:SaltoDeLinea().
    RUN pdf_stroke_color ("Spdf",1.0,.0,.0).
    RUN pdf_set_dash ("Spdf",2,2).
    RUN pdf_line  ("Spdf", pdf_LeftMargin("Spdf") , pdf_TextY("Spdf") + 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") + 5, 0.5).
    RUN pdf_stroke_color ("Spdf",.0,.0,.0).
    RUN pdf_skip    ("Spdf").
  END. /* Last-of State */

END. /* each Customer */

RUN end_of_report.

lobPDF:terminar().

/* -------------------- INTERNAL PROCEDURES -------------------------- */

PROCEDURE end_of_report:
  /* Display Footer UnderLine and End of Report Tag (Centered) */
  lobPDF:cobPaginaActual:SaltoDeLinea().
  RUN pdf_stroke_fill ("Spdf",1.0,1.0,1.0).
  lobPDF:cobPaginaActual:TextoEnCaja("End of Report", 250, pdf_TextY("Spdf") - 20, pdf_Text_Width("Spdf","End of Report"), 16, "Left",1).
END. /* end_of_report */

PROCEDURE PageFooter:
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Footer -- on all pages.
------------------------------------------------------------------------------*/

  ipobDocumento:cobPaginaActual:SaltoDeLinea().
  RUN pdf_set_dash ("Spdf",1,0).
  RUN pdf_line  ("Spdf", 0, pdf_TextY("Spdf") - 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") - 5, 1).
  ipobDocumento:cobPaginaActual:SaltoDeLinea().
  ipobDocumento:cobPaginaActual:SaltoDeLinea().
  RUN pdf_text_to  ("Spdf",  "Page: " 
                           + STRING(pdf_page("Spdf"))
                           + " of " + pdf_TotalPages("Spdf"), 97).

END. /* PageFooter */

PROCEDURE PageHeader:
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Header -- on all pages.
------------------------------------------------------------------------------*/

  /* Display a Sample Watermark on every page */
  RUN pdf_watermark ("Spdf","Customer List","Courier-Bold",34,.87,.87,.87,175,500).

  /* Place Logo but only on first page of Report */
  IF pdf_Page("Spdf") = 1 THEN DO:
    RUN pdf_place_image ("Spdf","ProSysLogo",pdf_LeftMargin("Spdf"), pdf_TopMargin("Spdf") - 20 ,179,20).
  END.

  /* Set Header Font Size and Colour */
  RUN pdf_set_font ("Spdf","Courier-Bold",10.0).  
  RUN pdf_text_color ("Spdf",1.0,.0,.0).

  /* Put a Rectangle around the Header */
  RUN pdf_stroke_color ("Spdf", .0,.0,.0).
  RUN pdf_stroke_fill ("Spdf", .9,.9,.9).
  RUN pdf_rect ("Spdf", pdf_LeftMargin("Spdf"), pdf_TextY("Spdf") - 3, pdf_PageWidth("Spdf") - 30  , 12, 0.5).

  /* Output Report Header */
  RUN pdf_text_at  ("Spdf","St",1).
  RUN pdf_text_at  ("Spdf","Nbr",6).
  RUN pdf_text_at  ("Spdf","Customer Name",12). 
  RUN pdf_text_at  ("Spdf","Phone Number",44).
  RUN pdf_text_to  ("Spdf","Balance",80).

  /* Display Header UnderLine */
  RUN pdf_skip ("Spdf").
  RUN pdf_set_dash ("Spdf",1,0).
  RUN pdf_line  ("Spdf", pdf_LeftMargin("Spdf"), pdf_TextY("Spdf") + 5, pdf_PageWidth("Spdf") - 20 , pdf_TextY("Spdf") + 5, 1).
  RUN pdf_skip ("Spdf").
  
  /* Set Detail Font Colour */
  RUN pdf_text_color ("Spdf",.0,.0,.0).

END. /* PageHeader */

message etime view-as alert-box.

IF VALID-HANDLE(h_PDFinc) THEN
  DELETE PROCEDURE h_PDFinc.

/* end of custlist.p */
