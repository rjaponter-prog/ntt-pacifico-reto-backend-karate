# Informe de Estrategia de Automatización

## Enfoque general

La suite se construyó siguiendo un proceso de tres fases: **investigación** (documentación oficial + comprobación experimental de la API), **diseño** (matriz de casos con evidencia real detrás de cada uno) y **construcción** (arquitectura, código, y depuración iterativa contra errores reales de configuración).

Ninguna prueba se escribió antes de confirmar el comportamiento real de la API. Varios comportamientos documentados por ServeRest no coincidían exactamente con lo observado en pruebas manuales (ver "Hallazgos", más abajo), y se priorizó la evidencia por encima del supuesto en cada caso.

## Patrones y decisiones técnicas

**Parametrización con Scenario Outline (CT-03).** Se aplicó Scenario Outline únicamente donde varios casos comparten exactamente los mismos pasos y solo cambian datos o resultados esperados — como validar que 4 campos obligatorios distintos generan el mismo tipo de error con distinto mensaje. El resto de casos se mantuvo como Scenarios independientes, porque forzar la parametrización donde los pasos difieren perjudica la legibilidad más de lo que ahorra líneas.

**Independencia entre tests.** Cada Scenario que necesita un usuario preexistente lo crea por su cuenta mediante un feature reutilizable (`create-user.feature`, invocado con `call read(...)`), en lugar de depender del orden de ejecución de otros tests. Esto permite ejecutar cualquier caso de forma aislada sin efectos colaterales, y facilita el debugging y un futuro paralelismo.

**Datos dinámicos:** los emails se generan con un timestamp mediante la clase Java `users.helpers.DataGenerator`, invocada desde los features con `Java.type()`, evitando colisiones entre ejecuciones.

**Validación de tipos sobre las respuestas.** Se usó el mecanismo de matching de tipos propio de Karate (`#string`, `#array`, `#number`) para validar la estructura de las respuestas, no solo sus valores concretos. No se utilizó una librería de JSON Schema formal (draft estándar) porque el matching nativo de Karate cumple el mismo propósito — validar forma, no solo contenido — sin introducir una dependencia adicional para el alcance de este reto.

**Verificación cruzada en operaciones de escritura.** Los casos de actualización (CT-08) y eliminación (CT-11) no se dan por válidos únicamente con el mensaje de éxito de la API — cada uno hace una llamada GET adicional para confirmar que el cambio ocurrió realmente en el sistema. Esta decisión surgió tras comprobar que un status 200 en `DELETE` no siempre implica que algo fue eliminado (ver hallazgos).

**Generación de datos en Java, no en JavaScript.** Karate permite helpers en JS, pero se optó por una clase Java (`users.helpers.DataGenerator`) invocada con `Java.type()`. Ventajas: tipado estático, compilación verificada por Maven, depurable desde el IDE y coherente con el stack del proyecto — evita mezclar dos lenguajes de scripting para una sola responsabilidad.

## Hallazgos relevantes durante la investigación

- **Los mensajes de error de campos obligatorios no están documentados en el esquema OpenAPI**, pero siguen un patrón consistente y predecible (`{"<campo>": "<campo> é obrigatório"}`), confirmado experimentalmente para los 4 campos del recurso usuario.
- **`PUT` con un ID inexistente no devuelve error**: crea un usuario nuevo con un `_id` autogenerado, distinto al enviado en la URL — comportamiento no estándar que se documentó y cubrió explícitamente (CT-09).
- **`DELETE` con un ID inexistente devuelve status 200**, pero con un mensaje que indica que no se eliminó nada. Un test que solo valide el código de estado pasaría erróneamente sin detectar esta ambigüedad.
- **El campo `_id` requiere exactamente 16 caracteres alfanuméricos**; un ID con formato inválido es rechazado antes de que la API verifique su existencia, devolviendo un error distinto al de "no encontrado".

## Alcance y decisiones fuera de cobertura

Por priorización de tiempo, no se incluyó un caso negativo para el campo `administrador` con un valor fuera de los esperados (`"true"`/`"false"`), como un string arbitrario o un booleano sin comillas. Sería el siguiente caso a incorporar si el framework escalara.

Tampoco se implementó limpieza (cleanup) de los usuarios creados durante la ejecución: al ser ServeRest un sandbox público diseñado para pruebas, se priorizó la independencia y repetibilidad de los tests sobre la eliminación posterior de datos.

## Riesgos identificados y gestionados

El escaneo de seguridad del IDE reportó vulnerabilidades (CVEs) en dependencias transitivas de Karate (Netty, Jackson, Logback, Thymeleaf). Se evaluó el riesgo en el contexto de un proyecto de automatización que corre localmente contra una API pública de pruebas — sin exposición a red externa ni procesamiento de datos no confiables — y se decidió aceptar el riesgo sin mitigación activa.