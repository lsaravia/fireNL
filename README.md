# Modelos dinámicos de fuegos en NetLogo

* **FirePrende.nlogo**: Es un modelo en el que se selecciona la probabilidad de ocupación del área, y se puede usar el mouse para encender o apagar el fuego en distintos sitios. También permite grabar un video del área modelada. La versión **FirePrendeNoVid.nlogo** desactiva la extensión de video para que pueda ser utilizada directamente desde la web con el siguiente enlace:

   <http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/FirePrendeNoVid.nlogo>

* **DynamicFire.nlogo**: Es un modelo de fuego dinámico, con un sustrato fijo donde puede crecer vegetación, es decir, hay una probabilidad máxima de cobertura de vegetación. Además, hay una probabilidad de ignición de fuegos, usualmente baja, y una tasa de crecimiento/recuperación de la vegetación después del fuego. El modelo puede guardar un archivo CSV con la configuración espacial en distintos momentos temporales y también permite grabar un video. La versión **DynamicFireWeb.nlogo** elimina las extensiones de video y CSV para ser utilizada desde la web mediante este enlace:

   <http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/DynamicFireWeb.nlogo>

   * **DynamicFireAnalysis.Rmd**: Es un análisis preliminar del comportamiento del modelo con distintos parámetros.

   * **PresentacionDOCNA.Rmd**: Son los slides de una presentación realizada para el curso de Ecología de Bosques.

* **DynamicFireForest.nlogo**: Es un modelo de fuego dinámico con crecimiento de vegetación. Incluye una probabilidad de ignición de fuegos, una tasa de crecimiento/recuperación de la vegetación después del fuego, una distancia de dispersión de la vegetación con una distribución tipo power-law, y la posibilidad de agregar variación anual en la tasa de ignición usando una distribución gamma. El modelo registra el intervalo de retorno de fuegos por parche.

* **DynamicDeforestFire.nlogo**: Es un modelo de fuego post-deforestación con la siguiente estructura:

   1) **Crecimiento del bosque**: Los sitios forestales producen con probabilidad P otro sitio forestal, enviándolo a una distancia dada por una distribución power-law con exponente DE (igual que en el anterior). Si el sitio objetivo fue deforestado o quemado hace menos de 3 años, el bosque no crece.

   2) **Deforestación**: La deforestación se propaga desde los 4 vecinos más cercanos con una probabilidad D.

   3) **Ignición**: Se selecciona un sitio deforestado al azar y se incendia con una probabilidad f(t).

   4) **Propagación del fuego**: 
      a) El fuego puede propagarse a los sitios vecinos con probabilidad 1 si han sido deforestados hace más de 365 días o quemados hace más de 365 días.  
      b) El fuego puede propagarse a sitios no deforestados con una probabilidad S, a una distancia dada por una distribución power-law con exponente DS. El fuego puede propagarse dentro de bosques intactos, pero es más probable cerca de incendios originados por la deforestación.

   5) Los parches que estuvieron en llamas en el paso anterior se consideran quemados.

