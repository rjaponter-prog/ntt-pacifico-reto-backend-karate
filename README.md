# Reto de Automatización QA Backend — API de Usuarios (ServeRest)

Suite de pruebas automatizadas con **Karate DSL** para la API de Usuarios de [ServeRest](https://serverest.dev/), desarrollada como parte de un proceso de selección de QA Automation con NTT DATA Perú.

## Objetivo

Automatizar las operaciones CRUD de usuarios (`GET`, `POST`, `PUT`, `DELETE`) cubriendo casos positivos, negativos y de borde, con validación de esquemas JSON y manejo de datos dinámicos.

## Tecnologías

| Herramienta | Versión |
|---|---|
| Java | 21 (Temurin) |
| Maven | 3.9.16 |
| Karate DSL | 1.5.2 |
| JUnit 5 | (incluido vía karate-junit5) |

## Requisitos previos

- JDK 21 instalado
- Maven 3.9+ instalado
- Conexión a internet (la suite corre contra la API pública real de ServeRest, sin mocks)

## Cómo ejecutar la suite

Clona el repositorio y, desde la raíz del proyecto, ejecuta:

```
./mvnw clean test
```
En Windows, usa `mvnw.cmd clean test` en lugar de `./mvnw clean test.`

Esto compila el proyecto y ejecuta 14 escenarios en total (13 correspondientes a los 11 casos de la matriz, más 1 del feature auxiliar de creación de usuario), generando automáticamente un reporte HTML.

### Ver el reporte de resultados

Al finalizar la ejecución, la consola muestra la ruta del reporte generado, por ejemplo: `target/karate-reports/karate-summary.html`

Ábrelo en cualquier navegador para ver el detalle de cada escenario ejecutado.

## Estructura del proyecto

```
src/test/java/
├── karate-config.js              # Configuración global (baseUrl del ambiente)
├── runners/
│   └── TestRunner.java           # Punto de entrada para ejecutar la suite vía Maven/JUnit
└── users/
    ├── users-crud.feature        # Los 11 casos de prueba (CRUD completo)
    ├── create-user.feature       # Feature reutilizable: crea un usuario y expone su _id/email
    ├── data/
    │   └── new-user.json     # Payload base de creación de usuario (externalizado)
    ├── schemas/
    │   └── user-schema.js        # JSON Schema para validar la estructura de un usuario
    └── helpers/
        └── DataGenerator.java    # Clase Java que genera emails únicos por ejecución (evita colisiones)
```


## Casos de prueba

| ID | Endpoint | Método | Tipo | Descripción |
|---|---|---|---|---|
| CT-01 | /usuarios | GET | Positivo | Listar usuarios registrados |
| CT-03 | /usuarios | POST | Negativo (parametrizado) | Rechaza el registro cuando falta un campo obligatorio (nome, email, password, administrador) |
| CT-05 | /usuarios | POST | Negativo | Rechaza registro con email ya utilizado |
| CT-06 | /usuarios/{_id} | GET | Positivo | Busca un usuario existente y valida su esquema JSON |
| CT-07 | /usuarios/{_id} | GET | Negativo | ID con formato válido pero inexistente |
| CT-08 | /usuarios/{_id} | PUT | Positivo | Actualiza un usuario y confirma el cambio real con un GET posterior |
| CT-09 | /usuarios/{_id} | PUT | Borde | Actualizar con un ID inexistente crea un usuario nuevo (comportamiento no estándar de la API) |
| CT-10 | /usuarios/{_id} | PUT | Negativo | Rechaza actualización con email usado por otro usuario |
| CT-11 | /usuarios/{_id} | DELETE | Positivo | Elimina un usuario y confirma su desaparición con un GET posterior |
| CT-12 | /usuarios/{_id} | DELETE | Borde | Eliminar un ID inexistente no genera error, pero tampoco borra nada |

## Decisiones de diseño

**Parametrización con Scenario Outline (CT-03):** los 4 campos obligatorios comparten exactamente los mismos pasos y solo cambian el dato y el mensaje esperado, por lo que se agrupan en un único Scenario Outline con 4 filas de Examples, en vez de 4 Scenarios casi idénticos.

**Independencia entre tests:** cada Scenario que necesita un usuario preexistente lo crea por su cuenta llamando a `create-user.feature` (vía `call read(...)`), en lugar de depender de que otro test se ejecute antes. Esto permite correr cualquier escenario de forma aislada sin efectos colaterales.

**Datos dinámicos:** los emails se generan con un timestamp mediante la clase Java `users.helpers.DataGenerator`, invocada desde los features con `Java.type()`, evitando colisiones entre ejecuciones.

**Verificación cruzada (CT-08 y CT-11):** actualizar o eliminar un usuario no solo valida el mensaje de éxito de la API, sino que hace una llamada GET adicional para confirmar que el cambio realmente ocurrió en el sistema.

**Validación de ID de 16 caracteres (CT-07, CT-09, CT-12):** se descubrió experimentalmente que la API valida el formato del `_id` (debe ser exactamente 16 caracteres alfanuméricos) antes de verificar su existencia. Los casos negativos usan IDs válidos en formato para aislar correctamente el escenario de "no encontrado" del de "formato inválido".

**Vulnerabilidades transitivas en dependencias:** el escaneo de seguridad del IDE reportó CVEs en dependencias transitivas de Karate (Netty, Jackson, Logback, Thymeleaf). Se evaluó el riesgo en el contexto de un proyecto de automatización que corre localmente contra un sandbox público, y se decidió aceptar el riesgo sin mitigación activa, priorizando el tiempo de desarrollo.

## Autor

Roberto Aponte — QA Automation