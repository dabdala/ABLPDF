/******************************************************************************

    Program:        super.p
    
    Description:    This program illustrates how you can run PDFinclude as a
                    Session Super Procedure. This allows you to define 
                    PDFinclude only once and allows you to reuse the functions
                    in many different programs.
                    
                    Note: When using as a Session you should delete the
                          h_PDFinc handle at your initiating program when done
                          (see below).

******************************************************************************/

{pdf/pdf_inc.i }

RUN pdf/pruebas_ejemplos/super-1.p.
RUN pdf/pruebas_ejemplos/super-2.p.
RUN pdf/pruebas_ejemplos/super-3.p.

IF VALID-HANDLE(h_PDFinc) THEN
  DELETE PROCEDURE h_PDFinc.

/* end of super.pdf */
