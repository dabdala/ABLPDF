# ABLPDF
PDF generation library for OpenEdge ABL, object oriented (10.2B onward), based on PDFInclude.

The library is mostly based on PDFInclude, taking its code and making classes to do the job.
Most of the code is taken from PDFInclude, but the library is also inspired on ZendPDF
implementation and on FPDF (some code has been taken from it too).

A pdf_inc.i and pdf_inc.p are provided in order to be able to use existing PDF procedures
(using PDFInclude) to run unchanged with this library (hopefully).

Most of the PDFInclude examples are provided (working) and some have been translated to
ABLPDF "notation".

Most of the library is written in spanish (sorry for that) as at the start of the project
I had an "anger momento with english". You can find the "translations" by looking at
pdf_inc.p.

The biggest difference (in usage) with PDFInclude is the use of PUBLISH/SUBSCRIBE for
customizations (Heade, Footer, etc.).

Tools (table, matrix, template, calendar) are somehow very different, and serveral
calendar variants are provided.

Not interlaced PNG images can be used.

Encription is not tested, and probably not working, as I didn't make the time to find
the required libraris in 64 bits.

#español
Librería para la generación de documentos PDF desde ABL, orientada a objetos (10.2B o superior),
basada en la versión libre de PDFInclude.

La mayor parte de la librería está basada en PDFInclude, restructurando el código en clases,
también está inspirada en la implemntación de ZendPDF y en FPDF (de este último he tomado
algo de código también).

Se proveen los archivos pdf_inc.i y pdf_inc.p, que internamente utilizan las clases de la librería,
para poder continuar utilizando los reportes que actualmente utilizan PDFInclude, sin cambios
(eso espero al menos).

La mayor parte de los ejemplos que vienen con PDFInclude están incluidos y funcionales, algunos
han sido traducidos a la versión que utiliza la libería en forma directa.

Prácticamente toda la librería está escrita en español (excepto el código proveniente de PDFInclude,
obviamente) dado que al comenzar el proyecto tuve un "enojo con el inglés". Se puede ver la
relación entre los nombres en inglés y sus correspondencias en español revisando pdf_inc.p.

La mayor diferencia con PDFInclude es el uso de PUBLISH/SUBSCRIBE para las modificaciones como
cabeceras, pies de página, y contenido de las herramientas (tabla, matriz, etc.).

Las herramientas (Tabla, Matriz, Calendario, Plantilla) son muy distintas de las provistas con
PDFInclude, y existen varias variantes de calendario.

Se pueden utilizar también (además de los JPG) imágenes PNG no entrelazadas.

La encriptación no está probada, y seguramente no funciona, porque no he tenido tiempo de
conseguir las librerías necesarias en 64 bits.
