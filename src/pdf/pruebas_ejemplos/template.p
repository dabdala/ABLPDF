/******************************************************************************

    Program:        template.p

    Description:    This program illustrates how to include and use a template 
                    file.  The template only appears on the page where it is 
                    'used'.

    Note:           must be attached to the Sports2000 DB to run example.
    
******************************************************************************/

{pdf/pdf_inc.i "THIS-PROCEDURE"}

RUN pdf_new ("Spdf","template.pdf").

RUN pdf_load_template("Spdf","Temp1","pdf/pruebas_ejemplos/Temp1.cfg").
RUN pdf_load_template("Spdf","Temp2","pdf/pruebas_ejemplos/Temp2.cfg").
RUN pdf_load_template("Spdf","Portrait","pdf/pruebas_ejemplos/Portrait.cfg").

FOR EACH Order WHERE Order.CustNum = 1 NO-LOCK:
  RUN pdf_new_page("Spdf").
  RUN pdf_use_template("Spdf","Portrait").
  RUN pdf_use_template("Spdf","Temp1").

  RUN pdf_skipn("Spdf",5).
  RUN pdf_text_at("Spdf","Order #:" + STRING(Order.OrderNum),18).

  RUN pdf_skip("Spdf").
  RUN pdf_text_at("Spdf"," Cust #:" + STRING(Order.CustNum),18).

  RUN pdf_new_page("Spdf").
  RUN pdf_use_template("Spdf","Portrait").

  RUN pdf_text_at("Spdf","This page could be used to outline order processing requirements etc",10).
END.

RUN pdf_close("Spdf").

/* end of template.pdf */
