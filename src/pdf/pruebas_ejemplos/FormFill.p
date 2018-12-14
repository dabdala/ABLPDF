 /******************************************************************************

    Program:        FormFill.p
    
    Description:    This program illustrates how to open an existing PDF 
                    document that has Text Form Fields in it.  This program then
                    goes onto show how to assign text to those form fields.

    Note:           Must be connected to the Sports2000 DB to run this example
    
******************************************************************************/

{pdf/pdf_inc.i}

DEFINE VARIABLE i_LineCounter AS INTEGER NO-UNDO.

DEFINE VARIABLE dec_SubTotal  AS DECIMAL NO-UNDO.

RUN pdf_new ("Spdf","FormFill-enc.pdf").

/* Set the PageHeader Routine */
pdf_PageHeader ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageHeader").

/* Set the PageFooter Routine */
pdf_PageFooter ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageFooter").

/* RUN pdf_set_parameter("Spdf","Compress","TRUE"). */  

/*
RUN pdf_set_parameter("Spdf","Encrypt","TRUE"). 
RUN pdf_set_parameter("Spdf","EncryptKey","40"). 
RUN pdf_set_parameter("Spdf","AllowPrint","FALSE").
RUN pdf_set_parameter("Spdf","AllowCopy","FALSE").
RUN pdf_set_parameter("Spdf","AllowModify","FALSE"). 
RUN pdf_set_parameter("Spdf","MasterPassword","Custom"). 
/* RUN pdf_set_parameter("Spdf","UserPassword","Custom"). */
*/


RUN pdf_open_PDF("Spdf","pdf/pruebas_ejemplos/POForm62.pdf","PO"). 

RUN ProcessPOs.

RUN pdf_close("Spdf").

/* ------------------- INTERNAL PROCEDURES ------------------------- */

PROCEDURE ProcessPOs: 
  
  FOR EACH PurchaseOrder WHERE PurchaseOrder.PoNum >= 8001 AND ponum <= 8002 NO-LOCK:
    RUN DoNewPage.

    ASSIGN i_LineCounter = 0
           dec_SubTotal  = 0.

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
  RUN pdf_new_page("Spdf").
  RUN pdf_use_PDF_page("Spdf","PO",1). 
END.

PROCEDURE PageHeader:

  /* Get Supplier Info */
  FIND Supplier WHERE Supplier.SupplierID = PurchaseOrder.SupplierID 
       NO-LOCK NO-ERROR.

  message Supplier.Name view-as alert-box.
  /* Display 'To' information */
  RUN pdf_fill_text("Spdf","To_Name",Supplier.Name,"").
  RUN pdf_fill_text("Spdf","To_Address1",Supplier.Address,"").
  RUN pdf_fill_text("Spdf","To_Address2",Supplier.Address2,"").

  /* Display 'Ship To' Information */
  RUN pdf_fill_text("Spdf","PO_Number",STRING(PurchaseOrder.PONum,"99999"),"").
  RUN pdf_fill_text("Spdf","ShipTo_Name",Supplier.Name,"").
  RUN pdf_fill_text("Spdf","ShipTo_Address1",Supplier.Address,"").
  RUN pdf_fill_text("Spdf","ShipTo_Address2",Supplier.Address2,"").

  /* Display 'PO Header' Information */
  RUN pdf_fill_text("Spdf",
                    "PO_Date",
                    STRING(PurchaseOrder.DateEntered,"99/99/99"),
                    "align=center").
  RUN pdf_fill_text("Spdf",
                    "Terms",
                    "NET 30",
                    "align=center").

END.

PROCEDURE PageFooter:
  RUN pdf_fill_text("Spdf",
                    "SubTotal",
                    STRING(dec_SubTotal,">,>>9.99"),
                    "align=right").
  RUN pdf_fill_text("Spdf",
                    "PO_Total",
                    STRING(dec_SubTotal,">,>>9.99"),
                    "align=right").
END.

PROCEDURE DoPOLine:

  RUN pdf_fill_text("Spdf",
                    "Qty_" + STRING(i_LineCounter),
                    STRING(POLine.Qty,">,>>9.99"),
                    "align=right").
  RUN pdf_fill_text("Spdf",
                    "Unit_" + STRING(i_LineCounter),
                    POLine.ItemNum,
                    "align=center").

  FIND Item WHERE Item.ItemNum = POLine.ItemNum NO-LOCK NO-ERROR.
  RUN pdf_fill_text("Spdf",
                    "Description_" + STRING(i_LineCounter),
                    Item.ItemName,
                    "").

  RUN pdf_fill_text("Spdf",
                    "UnitPrice_" + STRING(i_LineCounter),
                    STRING(Item.Price,">,>>9.99"),
                    "align=right ").
  RUN pdf_fill_text("Spdf",
                    "Total_" + STRING(i_LineCounter),
                    STRING(Item.Price * POLine.Qty,">,>>9.99"),
                    "align=right").

  ASSIGN dec_SubTotal = dec_SubTotal 
                      + Item.Price * POLine.Qty.
 
END.

/* end of FormFill.pdf */
 
