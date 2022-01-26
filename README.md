# Modelos dinámicos de fuegos en NetLogo 

* **FirePrende.nlogo** Es un modelo en que se selecciona la probabilidad de ocupacion del area y se puede usar el mouse para prender o apagar el fuego en distintos sitios. Tambien se puede grabar un video del area de modelado. **FirePrendeNoVid.nlogo" Desactiva la extension de video para que pueda ser usado directamente desde la web con este link:

<http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/FirePrendeNoVid.nlogo>

* **DynamicFire.nlogo** Es un modelo de fuego dinámico, con un sustrato fijo donde puede crecer la de vegetacion, es decir que hay una probabilidad maxima de cobertura de vegetación. Luego hay una probabilidad de ignicion de fuegos que es usualmente muy baja, y una tasa de crecimiento/recuperacion de la vegetación despues del fuego. El modelo puede guardar un archivo csv con la configuracion espacial a distintos momentos temporales, y tambien puede grabar un video. La version **DynamicFireWeb.nlogo** elimina las extensiones de video y csv para poder ser usado desde la web a partir de este link

	<http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/DynamicFireWeb.nlogo>

	* **DynamicFireAnalysis.Rmd** Es una análisis preliminar del comportamiento del modelo con distintos parámetros. 

	* **PresentacionDOCNA.Rmd** Son los slides de una presentación realizada para el curso de Ecología de Bosques 

* **DynamicFireForest.nlogo** Es un modelo de fuego dinámico con crecimiento dinámico de la vegetacion. Hay una probabilidad de ignicion de fuegos que es usualmente muy baja,  una tasa de crecimiento/recuperacion de la vegetación despues del fuego, una distancia de dispersion de la vegatación con una distribución power, y la posibilidad de agregar una variación anual en la tasa de ignición con una distribución de probabilides gamma.  El modelo registra el intervalo de retorno de fuegos por parche. 

* **DynamicDeforestFire.nlogo** A model of fire after deforestation with the following structure: 
	
	1) Forest growth: forest sites produce with probability P another forest site and send it to distance given by a power-law distribution with exponent DE (same as previous), if the target site was deforested < 3 years or burned < 3 years ago the forest do not growth. 

	2) Deforestation: deforestation grows from 4 nearest neighbors with a probability D

	3) Ignition: We take a random deforested site an set it on fire with probability f(t)

	4) Fire spread: a) fire can spread to neighbors sites with probability 1 if they are deforested > 365 days ago, or they are deforested and had a fire > 365 days ago. b) fire can spread to non-deforested sites with probability S at a distance given by a power-law distribution with exponent DS. It can be fire inside intact forest but it is more probable near fires produced by deforestation.

	5) Patches on fire in the previous step become burned. 

