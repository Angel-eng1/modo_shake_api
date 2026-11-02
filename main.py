from decimal import Decimal

import mysql.connector
from fastapi import FastAPI, HTTPException, Query
from fastapi.encoders import jsonable_encoder

from database import obtener_conexion


app = FastAPI(
    title="API de Analítica - Modo Shake",
    description="Consultas analíticas del sistema de pedidos de Modo Shake",
    version="1.0.0",
)


def consultar(sql: str, parametros: tuple = ()) -> list[dict]:
    conexion = None
    cursor = None

    try:
        conexion = obtener_conexion()
        cursor = conexion.cursor(dictionary=True)
        cursor.execute(sql, parametros)
        resultados = cursor.fetchall()

        # Conserva los valores DECIMAL como texto para no perder precisión.
        return jsonable_encoder(
            resultados,
            custom_encoder={Decimal: lambda valor: format(valor, "f")},
        )

    except mysql.connector.Error as error:
        print(f"Error de MySQL: {error}")
        raise HTTPException(
            status_code=500,
            detail="No se pudo realizar la consulta a la base de datos.",
        )

    finally:
        if cursor is not None:
            cursor.close()
        if conexion is not None and conexion.is_connected():
            conexion.close()


@app.get("/api/reportes/clasificacion-top")
def clasificacion_top():
    sql = """
        SELECT
            c.id_categoria,
            c.nombre AS categoria,
            SUM(operaciones.total_categoria) AS consumo_total,
            AVG(operaciones.total_categoria) AS promedio_por_operacion
        FROM categorias c
        INNER JOIN (
            SELECT
                pe.id_pedido,
                pr.id_categoria,
                SUM(dp.cantidad * dp.precio_unitario) AS total_categoria
            FROM pedidos pe
            INNER JOIN detalle_pedido dp
                ON dp.id_pedido = pe.id_pedido
            INNER JOIN productos pr
                ON pr.id_producto = dp.id_producto
            WHERE pe.estado <> 'Cancelado'
            GROUP BY pe.id_pedido, pr.id_categoria
        ) AS operaciones
            ON operaciones.id_categoria = c.id_categoria
        GROUP BY c.id_categoria, c.nombre
        HAVING AVG(operaciones.total_categoria) > (
            SELECT AVG(transacciones.total_categoria)
            FROM (
                SELECT
                    pe2.id_pedido,
                    pr2.id_categoria,
                    SUM(dp2.cantidad * dp2.precio_unitario) AS total_categoria
                FROM pedidos pe2
                INNER JOIN detalle_pedido dp2
                    ON dp2.id_pedido = pe2.id_pedido
                INNER JOIN productos pr2
                    ON pr2.id_producto = dp2.id_producto
                WHERE pe2.estado <> 'Cancelado'
                GROUP BY pe2.id_pedido, pr2.id_categoria
            ) AS transacciones
        )
        ORDER BY promedio_por_operacion DESC
    """
    return consultar(sql)


@app.get("/api/analitica/actores-estrella")
def actores_estrella():
    sql = """
        SELECT
            c.id_cliente,
            c.nombre AS cliente,
            SUM(dp.cantidad * dp.precio_unitario) AS consumo_acumulado
        FROM clientes c
        INNER JOIN pedidos pe
            ON pe.id_cliente = c.id_cliente
        INNER JOIN detalle_pedido dp
            ON dp.id_pedido = pe.id_pedido
        WHERE pe.estado <> 'Cancelado'
        GROUP BY c.id_cliente, c.nombre
        HAVING SUM(dp.cantidad * dp.precio_unitario) > (
            SELECT AVG(consumos.total_cliente)
            FROM (
                SELECT
                    pe2.id_cliente,
                    SUM(dp2.cantidad * dp2.precio_unitario) AS total_cliente
                FROM pedidos pe2
                INNER JOIN detalle_pedido dp2
                    ON dp2.id_pedido = pe2.id_pedido
                WHERE pe2.id_cliente IS NOT NULL
                  AND pe2.estado <> 'Cancelado'
                GROUP BY pe2.id_cliente
            ) AS consumos
        )
        ORDER BY consumo_acumulado DESC
    """
    return consultar(sql)


@app.get("/api/items/desviacion-grupo")
def desviacion_grupo():
    sql = """
        SELECT
            p.id_producto,
            p.nombre AS producto,
            c.nombre AS categoria,
            COALESCE(
                SUM(CASE
                    WHEN pe.id_pedido IS NOT NULL THEN dp.cantidad
                    ELSE 0
                END),
                0
            ) AS unidades_vendidas
        FROM productos p
        INNER JOIN categorias c
            ON c.id_categoria = p.id_categoria
        LEFT JOIN detalle_pedido dp
            ON dp.id_producto = p.id_producto
        LEFT JOIN pedidos pe
            ON pe.id_pedido = dp.id_pedido
           AND pe.estado <> 'Cancelado'
        GROUP BY
            p.id_producto,
            p.id_categoria,
            p.nombre,
            c.nombre
        HAVING COALESCE(
            SUM(CASE
                WHEN pe.id_pedido IS NOT NULL THEN dp.cantidad
                ELSE 0
            END),
            0
        ) < (
            SELECT
                COALESCE(
                    SUM(CASE
                        WHEN pe2.id_pedido IS NOT NULL THEN dp2.cantidad
                        ELSE 0
                    END),
                    0
                ) / NULLIF(COUNT(DISTINCT p2.id_producto), 0)
            FROM productos p2
            LEFT JOIN detalle_pedido dp2
                ON dp2.id_producto = p2.id_producto
            LEFT JOIN pedidos pe2
                ON pe2.id_pedido = dp2.id_pedido
               AND pe2.estado <> 'Cancelado'
            WHERE p2.id_categoria = p.id_categoria
        )
        ORDER BY unidades_vendidas ASC
    """
    return consultar(sql)


@app.get("/api/segmentos/analisis-limpio")
def analisis_limpio():
    sql = """
        SELECT
            e.puesto AS contexto_operativo,
            COUNT(DISTINCT pe.id_pedido) AS cantidad_pedidos,
            SUM(dp.cantidad * dp.precio_unitario) AS total_ventas
        FROM empleados e
        INNER JOIN pedidos pe
            ON pe.id_empleado = e.id_empleado
        INNER JOIN detalle_pedido dp
            ON dp.id_pedido = pe.id_pedido
        WHERE NOT EXISTS (
            SELECT 1
            FROM pedidos cancelado
            WHERE cancelado.id_pedido = pe.id_pedido
              AND cancelado.estado = 'Cancelado'
        )
        GROUP BY e.puesto
        ORDER BY total_ventas DESC
    """
    return consultar(sql)


@app.get("/api/operaciones/resumen-dinamico")
def resumen_dinamico(
    min_operaciones: int = Query(default=2, ge=1)
):
    sql = """
        SELECT
            metodo_pago,
            COUNT(*) AS cantidad_operaciones,
            SUM(monto) AS total_recaudado,
            AVG(monto) AS promedio_por_pago
        FROM pagos
        WHERE estado = 'Registrado'
        GROUP BY metodo_pago
        HAVING COUNT(*) >= %s
           AND AVG(monto) > (
               SELECT MIN(precio)
               FROM productos
               WHERE estado = 'Activo'
           )
        ORDER BY total_recaudado DESC
    """
    return consultar(sql, (min_operaciones,))