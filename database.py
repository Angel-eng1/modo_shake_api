import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()


def obtener_conexion():
    usuario = os.getenv("DB_USER")
    contrasena = os.getenv("DB_PASSWORD")

    if not usuario:
        raise RuntimeError("Configura DB_USER en el archivo .env.")
    if contrasena is None:
        raise RuntimeError("Configura DB_PASSWORD en el archivo .env.")

    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME", "modo_shake"),
        user=usuario,
        password=contrasena,
    )
