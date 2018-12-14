 /******************************************************************************

    Program:        FormFill.p
    
    Description:    This program illustrates how to open an existing PDF 
                    document that has Text Form Fields in it.  This program then
                    goes onto show how to assign text to those form fields.

    Note:           Must be connected to the Sports2000 DB to run this example
    
******************************************************************************/

DEFINE VARIABLE i_LineCounter AS INTEGER NO-UNDO.

DEFINE VARIABLE dec_SubTotal  AS DECIMAL NO-UNDO.

DEFINE VARIABLE lobDocumento AS pdf.DocumentoExistente NO-UNDO.

lobDocumento = NEW pdf.DocumentoExistente('pdf/pruebas_ejemplos/POForm62.pdf').
lobDocumento:cobDestino = NEW pdf.destinos.Archivo('FormFill-cls.pdf').

/* Set the PageFooter Routine */
lobDocumento:PieDePagina:Subscribe('PageFooter').

RUN ProcessPOs.

lobDocumento:terminar().

/* ------------------- INTERNAL PROCEDURES ------------------------- */

PROCEDURE ProcessPOs:
  DEFINE VARIABLE minOrden AS INTEGER NO-UNDO. 
  
  FOR EACH PurchaseOrder WHERE PurchaseOrder.PoNum >= 8001 AND ponum <= 8002 NO-LOCK:
    IF minOrden EQ 0 THEN
      RUN completarCabecera.
    ELSE
      RUN DoNewPage.

    ASSIGN i_LineCounter = 0
           dec_SubTotal  = 0
           minOrden = minOrden + 1.

    FOR EACH POLine OF PurchaseOrder.
      i_LineCounter = i_LineCounter + 1.

      RUN DoPOLine.

      /* If more than 5 lines then create another page */
      IF i_LineCounter > 5 THEN DO:
        RUN DoNewPage.
        i_LineCounter = 0.
      END.
    END.
  END.

END.

PROCEDURE DoNewPage:
  lobDocumento:AgregarPagina().
  lobDocumento:cobPaginaActual:usarPaginaExterna(lobDocumento:paginaExistente(1)).
  RUN completarCabecera.
END.

PROCEDURE completarCabecera:
  DEFINE VARIABLE iobAlineacion AS pdf.tipos.Alineacion NO-UNDO.

  /* Get Supplier Info */
  FIND Supplier WHERE Supplier.SupplierID = PurchaseOrder.SupplierID 
       NO-LOCK NO-ERROR.

  message Supplier.Name view-as alert-box.
  iobAlineacion = NEW pdf.tipos.Alineacion().
  /* Display 'To' information */
  lobDocumento:cobPaginaActual:completarCampoFormulario("To_Name",Supplier.Name,iobAlineacion,FALSe).
  lobDocumento:cobPaginaActual:completarCampoFormulario("To_Address1",Supplier.Address,iobAlineacion,FALSE).
  lobDocumento:cobPaginaActual:completarCampoFormulario("To_Address2",Supplier.Address2,iobAlineacion,FALSE).

  /* Display 'Ship To' Information */
  lobDocumento:cobPaginaActual:completarCampoFormulario("PO_Number",STRING(PurchaseOrder.PONum,"99999"),iobAlineacion,FALSe).
  lobDocumento:cobPaginaActual:completarCampoFormulario("ShipTo_Name",Supplier.Name,iobAlineacion,FALSe).
  lobDocumento:cobPaginaActual:completarCampoFormulario("ShipTo_Address1",Supplier.Address,iobAlineacion,FALSe).
  lobDocumento:cobPaginaActual:completarCampoFormulario("ShipTo_Address2",Supplier.Address2,iobAlineacion,FALSe).

  /* Display 'PO Header' Information */
  iobAlineacion:cinValor = pdf.tipos.Alineacion:Centrado.
  lobDocumento:cobPaginaActual:completarCampoFormulario("PO_Date",
                    STRING(PurchaseOrder.DateEntered,"99/99/99"),iobAlineacion,FALSE).
  lobDocumento:cobPaginaActual:completarCampoFormulario("Terms","NET 30",iobAlineacion,FALSE).
END.

PROCEDURE PageFooter:
  DEFINE INPUT PARAMETER ipobDocumento AS pdf.Documento NO-UNDO.
  DEFINE VARIABLE iobAlineacion AS pdf.tipos.Alineacion NO-UNDO.
  iobAlineacion = NEW pdf.tipos.Alineacion().
  iobAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.
  ipobDocumento:cobPaginaActual:completarCampoFormulario("SubTotal",
                    STRING(dec_SubTotal,">,>>9.99"),iobAlineacion,FALSE).
  ipobDocumento:cobPaginaActual:completarCampoFormulario("PO_Total",
                    STRING(dec_SubTotal,">,>>9.99"),iobAlineacion,FALSE).
END.

PROCEDURE DoPOLine:
  DEFINE VARIABLE iobAlineacion AS pdf.tipos.Alineacion NO-UNDO.

  iobAlineacion = NEW pdf.tipos.Alineacion().
  iobAlineacion:cinValor = pdf.tipos.Alineacion:Derecha.

  lobDocumento:cobPaginaActual:completarCampoFormulario("Qty_" + STRING(i_LineCounter),
                    STRING(POLine.Qty,">,>>9.99"),iobAlineacion,FALSE).
  lobDocumento:cobPaginaActual:completarCampoFormulario("Unit_" + STRING(i_LineCounter),
                    STRING(POLine.Itemnum),iobAlineacion,FALSE).

  FIND Item WHERE Item.ItemNum = POLine.ItemNum NO-LOCK NO-ERROR.
  lobDocumento:cobPaginaActual:completarCampoFormulario(
                    "Description_" + STRING(i_LineCounter),
                    Item.ItemName,iobAlineacion,FALSE).

  lobDocumento:cobPaginaActual:completarCampoFormulario(
                    "UnitPrice_" + STRING(i_LineCounter),
                    STRING(Item.Price,">,>>9.99"),iobAlineacion,FALSE).
  lobDocumento:cobPaginaActual:completarCampoFormulario(
                    "Total_" + STRING(i_LineCounter),
                    STRING(Item.Price * POLine.Qty,">,>>9.99"),iobAlineacion,FALSE).

  ASSIGN dec_SubTotal = dec_SubTotal 
                      + Item.Price * POLine.Qty.
 
END.

/* end of FormFill.pdf */
 
