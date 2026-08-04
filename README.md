# FireNL: Modelos dinámicos de fuego en NetLogo

[![DOI](https://zenodo.org/badge/301216269.svg)](https://doi.org/10.5281/zenodo.5703538)


**FireNL** es una colección de modelos espaciales estocásticos desarrollados en **NetLogo** para estudiar la dinámica de incendios forestales, la recuperación de la vegetación y la interacción entre fuego, deforestación y procesos de regeneración del bosque.

Los modelos están orientados tanto a la investigación científica como a la docencia en ecología, sistemas complejos y modelado basado en agentes.

## Modelos incluidos

### FirePrende

Modelo interactivo para explorar la propagación del fuego sobre un paisaje estático.

Características:

- selección de la cobertura inicial de vegetación;
- ignición y extinción mediante el mouse;
- grabación de videos de la simulación.

La versión **FirePrendeNoVid.nlogo** elimina la extensión de video para ejecutarse directamente en NetLogo Web:

http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/FirePrendeNoVid.nlogo

---

### DynamicFire

Modelo dinámico donde la vegetación crece continuamente mientras ocurren incendios espontáneos.

Incluye:

- crecimiento y recuperación de la vegetación;
- ignición estocástica;
- exportación de configuraciones espaciales en formato CSV;
- grabación de videos.

La versión **DynamicFireWeb.nlogo** puede ejecutarse desde NetLogo Web:

http://netlogoweb.org/web?https://raw.githubusercontent.com/lsaravia/fireNL/main/DynamicFireWeb.nlogo

Archivos asociados:

- **DynamicFireAnalysis.Rmd**: análisis exploratorio del comportamiento del modelo.
- **PresentacionDOCNA.Rmd**: presentación utilizada en el curso de Ecología de Bosques.

---

### DynamicFireForest

Modelo de incendios con regeneración espacial del bosque.

Además del crecimiento y recuperación de la vegetación incorpora:

- dispersión a larga distancia mediante una distribución *power-law*;
- variabilidad interanual en la ignición utilizando una distribución Gamma;
- registro del intervalo de retorno del fuego para cada parche.

---

### DynamicDeforestFire

Modelo de incendios asociados a procesos de deforestación.

El modelo representa cinco procesos principales:

1. Crecimiento del bosque mediante dispersión de larga distancia.
2. Expansión espacial de la deforestación.
3. Ignición de incendios sobre áreas deforestadas.
4. Propagación del fuego hacia áreas deforestadas y bosques intactos.
5. Recuperación posterior al incendio.

Este modelo fue desarrollado para estudiar la interacción entre deforestación, incendios y regeneración forestal en paisajes tropicales.

## Publicaciones

Si utiliza alguno de estos modelos en trabajos científicos, por favor cite la publicación correspondiente.

Saravia, L. A., Allhoff, K. T., Bond-Lamberty, B., & Suweis, S. (2025). Modelling Amazon fire regimes under climate change scenarios. Oikos, e10764. https://doi.org/10.1111/oik.10764

### Cómo citar el software

Saravia, L. A. (2026). FireNL (Version 2.0.0). Zenodo.
https://doi.org/10.5281/zenodo.5703538

