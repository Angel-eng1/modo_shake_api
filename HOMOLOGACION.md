# Homologación del modelo Modo Shake

## Descripción del negocio

Modo Shake es un negocio de alimentos y bebidas saludables. El sistema registra los productos que ofrece, los pedidos de sus clientes y los pagos asociados. Esta homologación adapta los roles de entidades del taller a las tablas existentes en la base de datos modo_shake.

## Correspondencia de entidades

| Rol del taller | Entidad del proyecto | Justificación |
|---|---|---|
| Catálogo o entidad clasificadora | categorias | Clasifica los productos ofrecidos por el negocio. |
| Ítem o recurso | productos | Representa los productos que pueden incluirse en los pedidos. |
| Entidad transaccional | pedidos, detalle_pedido y pagos | pedidos almacena la cabecera y fecha de la operación; detalle_pedido contiene productos, cantidades y precios; pagos registra fecha, método, monto y estado del pago. |
| Actor o sujeto | clientes | Representa a los clientes cuyo consumo acumulado se analiza. |
| Contexto o segmentación | empleados.puesto | Permite agrupar los pedidos por cargo de quien registró la operación. El modelo no contiene una tabla de sedes, turnos o canales; por eso se usa el atributo operativo disponible. |

## Descripción de los endpoints

### 1. Clasificación por categoría

La ruta GET /api/reportes/clasificacion-top agrupa el consumo por categoría. Para cada operación se calcula el valor de los productos de esa categoría incluidos en un pedido. La respuesta contiene las categorías cuyo promedio por operación supera el promedio general. Se excluyen los pedidos cancelados. La consulta utiliza GROUP BY, una subconsulta en HAVING y tablas derivadas en FROM.

### 2. Clientes destacados

La ruta GET /api/analitica/actores-estrella calcula el consumo histórico de cada cliente sumando cantidad por precio unitario en sus pedidos no cancelados. Devuelve los clientes cuyo total supera el promedio acumulado de todos los clientes con pedidos. Los pedidos sin cliente asociado no se atribuyen a una persona. La consulta agrupa por cliente y compara los resultados con una subconsulta que calcula los totales individuales.

### 3. Productos con ventas por debajo del promedio de su categoría

La ruta GET /api/items/desviacion-grupo suma las unidades vendidas de cada producto en pedidos no cancelados y compara esa cantidad con el promedio de unidades vendidas por producto en su categoría. Los productos sin ventas se consideran con cero unidades. La consulta agrupa por producto y emplea una subconsulta correlacionada en HAVING.

### 4. Análisis por contexto operativo

La ruta GET /api/segmentos/analisis-limpio consolida la cantidad de pedidos y el valor vendido por cargo del empleado. Excluye pedidos cancelados mediante NOT EXISTS. El cargo se emplea como contexto operativo porque el esquema no tiene una entidad para sedes o canales.

### 5. Resumen dinámico de pagos

La ruta GET /api/operaciones/resumen-dinamico agrupa los pagos registrados por método de pago. Recibe el parámetro opcional min_operaciones, cuyo valor predeterminado es 2, exige que cada grupo alcance ese mínimo y compara su pago promedio con el precio mínimo de los productos activos. El valor se pasa a MySQL como parámetro, no se concatena al texto SQL.

## Decisiones técnicas

La API está construida con FastAPI y mysql-connector-python. Las consultas se ejecutan con SQL nativo mediante cursores; no se utiliza ORM. La conexión se configura en el archivo local .env, que se excluye del repositorio. Las rutas convierten los resultados a JSON y devuelven errores HTTP cuando falla la consulta.

Para las pruebas se puede usar la documentación interactiva de FastAPI en /docs o las cinco solicitudes guardadas en test_endpoints.http.
