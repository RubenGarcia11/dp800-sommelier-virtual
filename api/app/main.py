from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

from app.db import denominaciones, filas, json_unico, paises
from app.analisis import analizar, combinar
from app.rag import construir_cadena
from app.reglas import interpretar

app = FastAPI(title="Sommelier Virtual")
cadena = construir_cadena()


class Pregunta(BaseModel):
    pregunta: str = Field(min_length=3, max_length=500)
    tipo: str | None = None
    denominacion: str | None = None
    pais: str | None = None
    precio_max: float | None = Field(default=None, gt=0)
    analisis_profundo: bool = True
    top: int = Field(default=4, ge=1, le=10)


@app.get("/health")
def health() -> dict:
    filas("SELECT 1 AS ok")
    return {"estado": "ok"}


@app.get("/vinos")
def listar_vinos(
    tipo: str | None = None,
    precio_max: float | None = None,
    region: str | None = None,
    denominacion: str | None = None,
    pais: str | None = None,
) -> list[dict]:
    return filas(
        "EXEC dbo.usp_BuscarVinos @Tipo = ?, @PrecioMax = ?, @Region = ?, @Denominacion = ?, @Pais = ?",
        tipo,
        precio_max,
        region,
        denominacion,
        pais,
    )


@app.get("/paises")
def listar_paises() -> list[str]:
    return paises()


@app.get("/denominaciones")
def listar_denominaciones() -> list[str]:
    return denominaciones()


@app.get("/vinos/{vino_id}")
def ficha_vino(vino_id: int) -> dict:
    ficha = json_unico("EXEC dbo.usp_FichaVinoJson @VinoId = ?", vino_id)
    if not ficha:
        raise HTTPException(status_code=404, detail="Vino no encontrado")
    return ficha


@app.get("/buscar")
def buscar(
    q: str = Query(min_length=3),
    top: int = Query(5, ge=1, le=10),
    denominacion: str | None = None,
    pais: str | None = None,
) -> list[dict]:
    return filas(
        "EXEC dbo.usp_BuscarVinosSemantico @Consulta = ?, @Top = ?, @Denominacion = ?, @Pais = ?",
        q,
        top,
        denominacion,
        pais,
    )


@app.post("/preguntar")
def preguntar(datos: Pregunta) -> dict:
    criterios = interpretar(datos.pregunta, datos.tipo, datos.denominacion, datos.precio_max, datos.pais)
    busqueda, interpretacion, estado = datos.pregunta, None, "rapido"
    if datos.analisis_profundo:
        requisitos = analizar(datos.pregunta)
        if requisitos:
            forzados = {
                campo
                for campo, valor in (
                    ("tipo", datos.tipo), ("denominacion", datos.denominacion),
                    ("pais", datos.pais), ("precio_max", datos.precio_max),
                )
                if valor
            }
            criterios = combinar(criterios, requisitos, datos.pregunta, forzados)
            interpretacion = requisitos.busqueda or None
            busqueda = f"{datos.pregunta}. {interpretacion or ''}".strip()
            estado = "profundo"
        else:
            estado = "sin_analisis"
    resultado = cadena.invoke(
        {"pregunta": datos.pregunta, "busqueda": busqueda, "top": datos.top, "criterios": criterios}
    )
    return {
        "respuesta": resultado["respuesta"],
        "analisis": {"estado": estado, "interpretacion": interpretacion},
        "criterios": criterios.etiquetas(),
        "vinos": [
            {"id": v["id"], "nombre": v["nombre"], "similitud": v["similitud"]}
            for v in resultado["vinos"]
        ],
    }
