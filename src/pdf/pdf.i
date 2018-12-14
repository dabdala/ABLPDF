
/*------------------------------------------------------------------------
    File        : pdf.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Sep 07 10:30:36 ART 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
&GLOBAL-DEFINE pdfencryptlib   C:\Users\nomade\Progress\Developer Studio 4.3.1\workspace\nsra_server\pdf\encriptadores\procryptlib.dll
&IF OPSYS = "UNIX" &THEN
  &GLOBAL-DEFINE zlib          /sistemas/nsra/pdf/compresores/libz.so.1
&ELSE
  &GLOBAL-DEFINE zlib          C:\Users\nomade\Progress\Developer Studio 4.3.1\workspace\nsra_server\pdf\compresores\zlib1.dll
&ENDIF

&IF OPSYS = "UNIX" &THEN
  &GLOBAL-DEFINE pdfSKIP     CHR(13) + CHR(10)
&ELSE
  &GLOBAL-DEFINE pdfSKIP     "~~n"
&ENDIF

&GLOBAL-DEFINE END  .

&GLOBAL-DEFINE DEBUGGING TRUE

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
