import json
from functools import lru_cache

import pyodbc

from app.config import settings

_CONEXION = (
    "DRIVER={{ODBC Driver 18 for SQL Server}};"
    "SERVER={host},{port};DATABASE={db};UID={user};PWD={pwd};"
    "Encrypt=yes;TrustServerCertificate=yes"
)


def conectar() -> pyodbc.Connection:
    return pyodbc.connect(
        _CONEXION.format(
            host=settings.db_host,
            port=settings.db_port,
            db=settings.db_name,
            user=settings.db_user,
            pwd=settings.db_password,
        ),
        timeout=10,
    )


def filas(sql: str, *params) -> list[dict]:
    with conectar() as cn:
        cur = cn.cursor()
        cur.execute(sql, *params)
        columnas = [c[0] for c in cur.description]
        return [dict(zip(columnas, fila)) for fila in cur.fetchall()]


def json_unico(sql: str, *params) -> list | dict | None:
    # FOR JSON devuelve el resultado fragmentado en varias filas
    with conectar() as cn:
        cur = cn.cursor()
        cur.execute(sql, *params)
        partes = [fila[0] for fila in cur.fetchall() if fila[0]]
    return json.loads("".join(partes)) if partes else None


@lru_cache(maxsize=1)
def denominaciones() -> list[str]:
    return [f["Denominacion"] for f in filas("SELECT DISTINCT Denominacion FROM dbo.vw_CatalogoVinos ORDER BY 1")]


@lru_cache(maxsize=1)
def paises() -> list[str]:
    return [f["Pais"] for f in filas("SELECT DISTINCT Pais FROM dbo.vw_CatalogoVinos ORDER BY 1")]
