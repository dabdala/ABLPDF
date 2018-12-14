DEFINE VARIABLE vPage       AS INTEGER NO-UNDO.
DEFINE VARIABLE vTotalPages AS INTEGER NO-UNDO.

{pdf/pdf_inc.i "THIS-PROCEDURE" }

RUN pdf_new ("Spdf","xml.pdf").

pdf_PageHeader ("Spdf",
                THIS-PROCEDURE:HANDLE,
                "PageHeader").

RUN pdf_load_xml("Spdf","pdf/pruebas_ejemplos/invoice.xml").

RUN SetupShipHeader.

/* Run through each of the XML pages */
FOR EACH TT_pdf_xml WHERE TT_pdf_xml.xml_parent = "/Root/Sheets".
  RUN pdf_new_Page("Spdf").
  
  RUN SetupItemList.
END.

RUN pdf_close("Spdf").

/* -------------------- INTERNAL PROCEDURES --------------------------- */
PROCEDURE PageHeader:
  RUN pdf_set_font("Spdf","Helvetica",14.0).

  /* Output Company Name */
  RUN pdf_text_align("Spdf",
                     "COMMERCIAL INVOICE",
                     "CENTER",
                     pdf_PageWidth("Spdf") / 2,
                     pdf_PageHeight("Spdf") - pdf_TopMargin("Spdf")
                     ).

  /* Output Company Name */
  RUN pdf_set_font("Spdf","Helvetica",10.0).
  RUN pdf_text_align("Spdf",
                     GetXMLNodeValue("/Root/HeaderInfo","CompanyName"),
                     "CENTER",
                     pdf_PageWidth("Spdf") / 2,
                     pdf_GraphicY("Spdf") - 14
                     ).

  /* Output Invoice Number */
  RUN pdf_text_xy("Spdf",
                   "CI NO",
                   490,
                   pdf_PageHeight("Spdf") - pdf_TopMargin("Spdf")).
  RUN pdf_text_xy("Spdf",
                   GetXMLNodeValue("/Root/HeaderInfo","ComInvNo"),
                   540,
                   pdf_PageHeight("Spdf") - pdf_TopMargin("Spdf")).

  /* Output Page Number */
  RUN pdf_text_xy("Spdf",
                   "Page",
                   490,
                   pdf_GraphicY("Spdf") - 10).
  RUN pdf_text_xy("Spdf",
                   pdf_Page("Spdf"),
                   540,
                   pdf_GraphicY("Spdf") - 10).

  /* Output From Address */
  RUN pdf_set_font("Spdf","Helvetica-Bold",10.0).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","CompanyName"),
                  50,
                  700).

  RUN pdf_set_font("Spdf","Helvetica",10.0).
  RUN pdf_text_xy("Spdf",
                    GetXMLNodeValue("/Root/HeaderInfo/From","Address") 
                  + ", " + GetXMLNodeValue("/Root/HeaderInfo/From","State")
                  + " " + GetXMLNodeValue("/Root/HeaderInfo/From","Zip"),
                  50,
                  690).
  RUN pdf_text_xy("Spdf",
                  "Phone No. " + GetXMLNodeValue("/Root/HeaderInfo/From","Phone"),
                  50,
                  680).
  RUN pdf_text_xy("Spdf",
                  "Fax No. " + GetXMLNodeValue("/Root/HeaderInfo/From","Fax"),
                  50,
                  670).

  /* Output Federal ID */
  RUN pdf_set_font("Spdf","Helvetica-Bold",10.0).
  RUN pdf_text_xy("Spdf",
                  "Federal ID: " + GetXMLNodeValue("/Root/HeaderInfo","FederalID"),
                  50,
                  650).

  /* Output Container Info  */
  RUN pdf_set_font("Spdf","Helvetica",10.0).
  RUN pdf_text_xy("Spdf",
                  "NO. CARTONS",
                  50,
                  630).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","NumCartons"),
                  200,
                  630).
  RUN pdf_text_xy("Spdf",
                  "TRAILER NO.",
                  50,
                  620).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","TrailerNo"),
                  200,
                  620).
  RUN pdf_text_xy("Spdf",
                  "SEAL NO.",
                  50,
                  610).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","SealNo"),
                  200,
                  610).
  RUN pdf_text_xy("Spdf",
                  "WEIGHT",
                  50,
                  600).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","Weight"),
                  200,
                  600).
  RUN pdf_text_xy("Spdf",
                  "CONTAINER LENGTH",
                  50,
                  590).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","ContainerLength"),
                  200,
                  590).
  RUN pdf_text_xy("Spdf",
                  "BOOKING NO",
                  50,
                  580).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo","BookingNo"),
                  200,
                  580).

  /* Ship To Label */
  RUN pdf_text_align("Spdf",
                     "S",
                     "CENTER",
                     300,
                     630).
  RUN pdf_text_align("Spdf",
                     "H",
                     "CENTER",
                     300,
                     620).
  RUN pdf_text_align("Spdf",
                     "I",
                     "CENTER",
                     300,
                     610).
  RUN pdf_text_align("Spdf",
                     "P",
                     "CENTER",
                     300,
                     600).
  RUN pdf_text_align("Spdf",
                     "T",
                     "CENTER",
                     300,
                     580).
  RUN pdf_text_align("Spdf",
                     "O",
                     "CENTER",
                     300,
                     570).

  /* Ship To Info */
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo/To","ShipTo"),
                  320,
                  630).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo/To","Address"),
                  320,
                  620).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo/To","City"),
                  320,
                  610).
  RUN pdf_text_xy("Spdf",
                  GetXMLNodeValue("/Root/HeaderInfo/To","Country"),
                  320,
                  600).

  /* Now Produce Shipment Matrix info --- on each Page */
  RUN pdf_tool_create ("Spdf","ShipHeader").

END. /* PageHeader */

PROCEDURE SetupShipHeader:

  /* Create and Setup the ShipHeader Matrix */
  RUN pdf_tool_add ("Spdf","ShipHeader", "MATRIX", ?).
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","X",0,"50").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","Y",0,"550").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","Rows",0,"2").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","Columns",0,"7").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","GridWeight",0,"0.5").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","GridColor",0,"0,0,0").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","FontSize",0,"10.0").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","BGcolor",0,"255,255,255").

  /* Setup Row 1 -- the Header */
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","BGcolor",1,"151,201,255").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","Font",1,"Helvetica-Bold").

  /* Setup Row 2 -- the Information */
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","Font",2,"Helvetica").
 
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",1,"100").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",1,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",2,"125").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",2,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",3,"100").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",3,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",4,"50").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",4,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",5,"75").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",5,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",6,"60").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",6,"CENTER").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnWidth",7,"30").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","ColumnAlign",7,"CENTER").

  /* Load Row 1 - Header Data */
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",1,"SHIPMENT").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",2,"CUST.ORDER NO.").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",3,"TERRITORY").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",4,"TERMS").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",5,"SHIPPED VIA").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",6,"DATE").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",7,"F.O.B.").

  /* Load Row 2 - Information Data */
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",8,GetXMLNodeValue("/Root/HeaderInfo","ShippingNo")).
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",9,"N/A").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",10,GetXMLNodeValue("/Root/HeaderInfo","Territory")).
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",11,"N/A").
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",12,GetXMLNodeValue("/Root/HeaderInfo","ShippedVia")).
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",13,GetXMLNodeValue("/Root/HeaderInfo","DateShipped")).
  RUN pdf_set_tool_parameter("Spdf","ShipHeader","CellValue",14,"").

END. /* SetupShipHeader */

PROCEDURE SetupItemList:

  DEFINE VARIABLE ListName  AS CHARACTER NO-UNDO.

  DEFINE VARIABLE i_Cell    AS INTEGER NO-UNDO.
  DEFINE VARIABLE i_MaxY    AS INTEGER NO-UNDO.

  DEFINE BUFFER B_Page FOR TT_pdf_xml.
  DEFINE BUFFER B_Item FOR TT_pdf_xml.

  ListName = "ItemList" + STRING(pdf_Page("Spdf")).

  /* Create and Setup the Item Matrix */
  RUN pdf_tool_add ("Spdf",ListName, "MATRIX", ?).

  RUN pdf_set_tool_parameter("Spdf",ListName,"X",0,"50").
  RUN pdf_set_tool_parameter("Spdf",ListName,"Y",0,"500").
  RUN pdf_set_tool_parameter("Spdf",ListName,"Rows",0,"24").
  RUN pdf_set_tool_parameter("Spdf",ListName,"Columns",0,"8").
  RUN pdf_set_tool_parameter("Spdf",ListName,"GridWeight",0,"0.5").
  RUN pdf_set_tool_parameter("Spdf",ListName,"GridColor",0,"0,0,0").
  RUN pdf_set_tool_parameter("Spdf",ListName,"FontSize",0,"8.0").
  RUN pdf_set_tool_parameter("Spdf",ListName,"BGcolor",0,"255,255,255").

  /* Setup Row 1 -- the Header */
  RUN pdf_set_tool_parameter("Spdf",ListName,"BGcolor",1,"151,201,255").
  RUN pdf_set_tool_parameter("Spdf",ListName,"Font",1,"Helvetica-Bold").

  /* Setup Row 2 -- the Information */
  RUN pdf_set_tool_parameter("Spdf",ListName,"Font",2,"Helvetica").
 
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",1,"55").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnAlign",1,"RIGHT").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",2,"80").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",3,"30").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnAlign",3,"RIGHT").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",4,"175").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",5,"35").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",6,"50").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",7,"60").
  RUN pdf_set_tool_parameter("Spdf",ListName,"ColumnWidth",8,"55").

  /* Load Row 1 - Header Data */
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",1,"QUANTITY").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",2,"CODE").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",3,"CNTS").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",4,"DESCRIPTION").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",5,"BOX/LB").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",6,"TOT.WT/LB").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",7,"UNIT PRICE").
  RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",8,"AMOUNT").

  /* Now Load Item Data */
  i_Cell = 1.
  FOR EACH B_Page WHERE B_Page.xml_pnode = TT_pdf_xml.xml_seq
      BY B_Page.xml_seq:

    FOR EACH B_Item WHERE B_Item.xml_pnode = B_Page.xml_seq NO-LOCK:
      CASE B_Item.xml_node:
        WHEN "Quantity" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell,B_Item.xml_value).
        WHEN "Code" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 1,B_Item.xml_value).
        WHEN "Cnts" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 2,B_Item.xml_value).
        WHEN "Description" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 3,B_Item.xml_value).
        WHEN "Weight" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 4,B_Item.xml_value).
        WHEN "TotalWeight" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 5,B_Item.xml_value).
        WHEN "UnitPrice" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 6,B_Item.xml_value).
        WHEN "Amount" THEN
          RUN pdf_set_tool_parameter("Spdf",ListName,"CellValue",i_Cell + 7,B_Item.xml_value).
      END CASE.
    END.

    i_Cell = i_Cell + 8.
  END. /* each Page */

  RUN pdf_tool_create ("Spdf",ListName).
  
  /* After the Matrix - display the Disclaimer */
  RUN pdf_set_font("Spdf","Helvetica",6.0).
  RUN pdf_set_TextY("Spdf",260).
  RUN pdf_wrap_text("Spdf",
                    GetXMLNodeValue("/Root/HeaderInfo","Disclaimer"),
                    25,
                    300,
                    "LEFT",
                    OUTPUT i_MaxY).

END. /* LoadItemData */
