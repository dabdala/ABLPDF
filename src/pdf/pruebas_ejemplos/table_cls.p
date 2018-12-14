DEFINE TEMP-TABLE TT_mydata NO-UNDO RCODE-INFORMATION
    FIELD Custno    LIKE Customer.CustNum
    FIELD CustName  LIKE Customer.Name
    FIELD PhoneNo   LIKE Customer.Phone
    FIELD State     LIKE Customer.State.

/* Build my Temp Table Data */
FOR EACH Customer WHERE name begins "A" NO-LOCK:
  CREATE TT_mydata.
  ASSIGN TT_mydata.CustNo   = Customer.CustNum
         TT_mydata.CustName = Customer.Name
         TT_mydata.PhoneNo  = Customer.Phone
         TT_mydata.State    = Customer.State.
END.

DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
DEFINE VARIABLE mobTabla AS pdf.herramientas.Tabla NO-UNDO.

mobPDF = NEW pdf.Documento().
mobPDF:cobDestino = NEW pdf.destinos.Archivo("table_cls.pdf").

mobPDF:cobCompresor = NEW pdf.compresores.FlateDecode().

/* Set Page Header procedure */
mobPDF:CabeceraDePagina:Subscribe("PageHeader").

/* Set Page Header procedure */
mobPDF:PieDePagina:Subscribe("PageFooter").

/* Don't want the table to be going until the end of the page or too near the 
   side */
mobPDF:cobMargenes:cinIzquierda = 20.
mobPDF:cobMargenes:cinAbajo = 10.
mobPDF:cobMargenes:cinArriba = 10.
mobPDF:cinAltoCabeceraDePagina = 40.
mobPDF:cinAltoPieDePagina = 30.

/* Link the Temp-Table to the PDF */
mobTabla = NEW pdf.herramientas.Tabla(mobPDF,TEMP-TABLE TT_mydata:HANDLE).

/* Now Setup some Parameters for the Table */

/* comment out this section to see what the default Table looks like */
mobTabla:cdeAnchoBordes = .5.
mobTabla:cobSeparacion:cinX = 2.
mobTabla:cobLetraTitulo:cchNombre = "Helvetica-Bold".
mobTabla:cobLetraTitulo:cdePuntos = 8.
mobTabla:cobFondoTitulo:desdeCadena("255,0,0").
mobTabla:cobColorTitulo:desdeCadena("255,255,255").

mobTabla:cobFondoContenido:desdeCadena("200,200,200").
mobTabla:cobColorContenido:desdeCadena("0,0,200").
mobTabla:cobLetraContenido:cchNombre = "Helvetica".
mobTabla:cobLetraContenido:cdePuntos = 8.
/* end of section */

/* Define Table Column Headers */
mobTabla:cchTitulos = "Customer #,Name,Phone #,State".

/* Define Table Column Widths */
mobTabla:cchAnchoColumnas = "60,180,70,50".

/* Now produce the table */
mobTabla:inicioCelda:Subscribe("TableCell").
mobTabla:generar().

mobPDF:terminar().

DELETE OBJECT mobTabla.
DELETE OBJECT mobPDF:cobDestino.
DELETE OBJECT mobPDF.

/* ------------------------ INTERNAL PROCEDURES ---------------------------- */
PROCEDURE TableCell:
  DEFINE INPUT PARAMETER ipobTabla AS pdf.herramientas.Tabla NO-UNDO.
  
  IF LENGTH(STRING(TT_mydata.Custno)) LT 4 THEN DO:
    ipobTabla:cobFondoContenido:desdeCadena("0,180,10").
    ipobTabla:cobColorContenido:desdeRGB(1,0.8,1).
  END.
  ELSE DO:
    ipobTabla:cobFondoContenido:desdeCadena("200,200,200").
    mobTabla:cobColorContenido:desdeCadena("0,0,200").
  END.
END PROCEDURE.

PROCEDURE PageHeader:
  DEFINE INPUT PARAMETER ipobDoc AS pdf.Documento NO-UNDO.

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Header -- on all pages.
------------------------------------------------------------------------------*/
  DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.

  /* Set Header Font Size and Colour */
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = "Courier-Bold".
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = 14.  
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(1.0,.0,.0).

  /* Output Report Header */
  mobPunto = NEW pdf.utiles.Punto().
  mobPunto:cinX = ipobDoc:cobMargenes:cinIzquierda.
  mobPunto:cinY = ipobDoc:cinAltoDePagina - 25.
  ipobDoc:cobPaginaActual:Texto("Customer List",mobPunto).

  ipobDoc:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(.0,.0,.0).
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = "Courier".
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = 10.  
  
  DELETE OBJECT mobPunto NO-ERROR.
END. /* PageHeader */

PROCEDURE PageFooter:
  DEFINE INPUT PARAMETER ipobDoc AS pdf.Documento NO-UNDO.

/*------------------------------------------------------------------------------
  Purpose:  Procedure to Print Page Footer -- on all pages.
------------------------------------------------------------------------------*/
  DEFINE VARIABLE mobPunto1 AS pdf.utiles.Punto NO-UNDO.
  DEFINE VARIABLE mobPunto2 AS pdf.utiles.Punto NO-UNDO.
  /* Set Footer Font Size and Colour */
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cchNombre = "Courier-Bold".
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobLetra:cdePuntos = 10.0.  
  ipobDoc:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(0.0,.0,.0).
  
  ipobDoc:cobPaginaActual:SaltoDeLinea().
  ipobDoc:cobPaginaActual:lineaInterrumpida(1,0).
  mobPunto1 = NEW pdf.utiles.Punto().
  mobPunto2 = NEW pdf.utiles.Punto().
  mobPunto1:cinX = ipobDoc:cobMargenes:cinIzquierda.
  mobPunto1:cinY = ipobDoc:cobPaginaActual:cobEstadoTexto:cobPosicion:cinY - 5.
  mobPunto2:cinX = ipobDoc:cinAnchoDePagina - 20 .
  mobPunto2:cinY = mobPunto1:cinY.
  ipobDoc:cobPaginaActual:linea(mobPunto1,mobPunto2, 1).
  ipobDoc:cobPaginaActual:SaltoDeLinea(2).
  ipobDoc:cobPaginaActual:TextoHastaColumna("Page: " 
                           + STRING(ipobDoc:cobPaginaActual:cinNumero)
                           + " of " + ipobDoc:cchMarcaTotalPaginas, 100).


END. /* PageFooter */
