# API REST de Analítica de Modo Shake

API desarrollada con FastAPI para consultar indicadores de pedidos, productos, clientes y pagos de Modo Shake. Se conecta a la base MySQL modo_shake y ejecuta las consultas analíticas con SQL nativo y el conector de MySQL para Python.

## Requisitos

- Python 3.13
- MySQL Server en ejecución y la base de datos modo_shake
- Visual Studio Code (opcional, para editar el código)
- Extensión REST Client (opcional, para ejecutar test_endpoints.http)

## Instalación

Abre una terminal en esta carpeta y crea el entorno virtual con:

    py -3.13 -m venv .venv

Instala las dependencias con:

    .\.venv\Scripts\python.exe -m pip install -r requirements.txt

Copia la plantilla con Copy-Item .env.example .env y configura en .env las credenciales que utilizas para conectarte a MySQL. No publiques .env ni compartas su contraseña.

## Ejecución

Inicia el servidor con:

    .\.venv\Scripts\python.exe -m uvicorn main:app --reload

La API queda disponible localmente en http://127.0.0.1:8000. La documentación interactiva generada por FastAPI está en http://127.0.0.1:8000/docs.

## Endpoints

| Método | Ruta | Función |
|---|---|---|
| GET | /api/reportes/clasificacion-top | Categorías cuyo promedio de consumo por operación supera el promedio general |
| GET | /api/analitica/actores-estrella | Clientes cuyo consumo acumulado supera el promedio de consumo por cliente |
| GET | /api/items/desviacion-grupo | Productos con ventas inferiores al promedio de su categoría |
| GET | /api/segmentos/analisis-limpio | Ventas agrupadas por cargo, excluyendo pedidos cancelados |
| GET | /api/operaciones/resumen-dinamico?min_operaciones=3 | Pagos agrupados por método y filtrados por mínimo de operaciones |

Las respuestas se entregan en JSON. El parámetro min_operaciones es opcional y su valor predeterminado es 2.

## Pruebas

Con el servidor encendido, abre test_endpoints.http en Visual Studio Code. La extensión REST Client permite enviar cada solicitud y ver su respuesta. También se pueden ejecutar las rutas desde /docs.

## Archivos principales

- main.py: rutas GET, consultas SQL y manejo de errores de base de datos.
- database.py: configuración y apertura de conexiones MySQL.
- dump_proyecto.sql: estructura y datos de ejemplo de la base.
- HOMOLOGACION.md: correspondencia entre el modelo de Modo Shake y los roles analíticos del taller.
- test_endpoints.http: solicitudes para probar los cinco endpoints.
- requirements.txt: dependencias de Python.
- .env.example: plantilla de configuración sin credenciales reales.

El modelo conserva dos perfiles de sistema en roles (ADMIN y USUARIO). La tabla empleados contiene los registros de personas de prueba asociados a esos perfiles.

