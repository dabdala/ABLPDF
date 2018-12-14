/******************************************************************************

    Program:        rotatetext.p
    
    Description:    Illustrates the rotation of text available via new implementation.

******************************************************************************/

DEFINE VARIABLE mobPDF AS pdf.Documento NO-UNDO.
DEFINE VARIABLE mobPunto AS pdf.utiles.Punto NO-UNDO.

mobPunto = NEW pdf.utiles.Punto().
mobPDF = NEW pdf.Documento().
mobPDF:cobDestino = NEW pdf.destinos.Archivo("rotatetext_cls.pdf").
mobPDF:cobMargenes:cinArriba = 60.

mobPDF:AgregarPagina().

/* Place some text */
mobPDF:cobPaginaActual:Texto(FILL("HORIZONTAL ",2)).

mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -90.
mobPDF:cobPaginaActual:Texto(FILL("VERTICAL ",2)).

mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:Texto(FILL("HORIZON ",2)).

mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -270.
mobPDF:cobPaginaActual:Texto(FILL("VERT ",2)).

mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:cobEstadoTExto:cobLetra:cdePuntos = 12.
mobPDF:cobPaginaActual:cobEstadoTexto:cobColor:desdeRGB(1,0,0).
mobPDF:cobPaginaActual:Texto("SNAKEHEAD----8~~ ").

/* Part 2 */
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:SaltoDeLinea(15).
mobPDF:cobPaginaActual:TextoEnColumna("HORIZONTAL HORIZONTAL  ",1).

mobPunto:Copiar(mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -45.
mobPDF:cobPaginaActual:Texto(" 045 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -315.
mobPDF:cobPaginaActual:Texto(" 315 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -135.
mobPDF:cobPaginaActual:Texto(" 135 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -225.
mobPDF:cobPaginaActual:Texto(" 225 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:Texto("  HORIZONTAL HORIZONTAL ").
/* End Part 2 */

/* Part 3 */
mobPDF:AgregarPagina().
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Escalar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Espejar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Inclinar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Rotar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Mover).

mobPDF:cobPaginaActual:SaltoDeLinea(15).
mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = -30.
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:TextoEnColumna("HORIZONTAL HORIZONTAL  ",1).

mobPunto:Copiar(mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -45.
mobPDF:cobPaginaActual:cdeEscalaEnX = 1.5.
mobPDF:cobPaginaActual:cdeEscalaEnY = 0.8.
mobPDF:cobPaginaActual:Texto(" 045 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -315.
mobPDF:cobPaginaActual:Texto(" 315 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -135.
mobPDF:cobPaginaActual:Texto(" 135 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -225.
mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = TRUE.
mobPDF:cobPaginaActual:Texto(" 225 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = FALSE.
mobPDF:cobPaginaActual:Texto("  HORIZONTAL HORIZONTAL ").
/* End Part 3 */

/* Part 4 */
mobPDF:AgregarPagina().
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Inclinar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Rotar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Mover).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Escalar).
mobPDF:cobPaginaActual:agregarOrdenTransformacion(pdf.tipos.Transformacion:Espejar).

mobPDF:cobPaginaActual:SaltoDeLinea(15).
mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = FALSE.
mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = -30.
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:cdeEscalaEnX = 1.5.
mobPDF:cobPaginaActual:cdeEscalaEnY = 0.8.
mobPDF:cobPaginaActual:TextoEnColumna("HORIZONTAL HORIZONTAL  ",1).

mobPunto:Copiar(mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -45.
mobPDF:cobPaginaActual:Texto(" 045 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -315.
mobPDF:cobPaginaActual:Texto(" 315 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -135.
mobPDF:cobPaginaActual:Texto(" 135 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = TRUE.
mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = -225.
mobPDF:cobPaginaActual:Texto(" 225 DEGREES").

mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = FALSE.
mobPDF:cobPaginaActual:cobEstadoTexto:cobPosicion:Copiar(mobPunto).
mobPDF:cobPaginaActual:cobEstadoTexto:cinAngulo = 0.
mobPDF:cobPaginaActual:Texto("  HORIZONTAL HORIZONTAL ").
/* End Part 4 */

/* Part 5 */
mobPDF:AgregarPagina().

mobPDF:cobPaginaActual:SaltoDeLinea(2).
mobPDF:cobPaginaActual:TextoEnColumna("NORMALMENTE NORMAL",1).
mobPDF:cobPaginaActual:SaltoDeLinea(2).
mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = TRUE.
mobPDF:cobPaginaActual:TextoEnColumna("ESPEJADAMENTE ESPEJADO EN Y",1).
mobPDF:cobPaginaActual:cobEstadoTexto:clgEspejarEnY = FALSE.
mobPDF:cobPaginaActual:SaltoDeLinea(2).
mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 15.
mobPDF:cobPaginaActual:TextoEnColumna("ANGULADAMENTE INCLINADA",1).
mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = 0.
mobPDF:cobPaginaActual:SaltoDeLinea(2).
mobPDF:cobPaginaActual:cdeEscalaEnX = 1.5.
mobPDF:cobPaginaActual:TextoEnColumna("ESCALADAMENTE ESCALADA",1).
mobPDF:cobPaginaActual:cdeEscalaEnX = 1.
mobPDF:cobPaginaActual:SaltoDeLinea(2).
mobPDF:cobPaginaActual:cobEstadoTExto:cinAnguloLetra = -30.
mobPDF:cobPaginaActual:TextoEnColumna("INCLINDADA, PARA EL OTRO LADO",1).


/* End Part 5 */


mobPDF:terminar().
DELETE OBJECT mobPDF:cobDestino.
DELETE OBJECT mobPDF.
DELETE OBJECT mobPunto.
/* end of rotatetext.p */
