from dataclasses import replace
from functools import lru_cache

from langchain_core.prompts import ChatPromptTemplate
from langchain_ollama import ChatOllama
from pydantic import BaseModel, Field

from app.config import settings
from app.db import denominaciones, paises
import re

from app.reglas import (
    Criterios,
    detectar_denominacion,
    detectar_paises,
    detectar_precio_numerico,
    normalizar,
    stock_para,
)

TIPOS = ["Tinto", "Blanco", "Rosado", "Espumoso", "Dulce"]

PROMPT = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "Analizas peticiones dirigidas a un sommelier y extraes sus requisitos.\n"
            "- tipos: tipos de vino ({tipos}) que pide el usuario o que exige claramente el plato "
            "(carne roja: Tinto; marisco: Blanco y Espumoso). Lista vacía si no hay criterio claro.\n"
            "- paises: países mencionados, solo de esta lista: {paises}.\n"
            "- denominacion: denominación de origen mencionada, solo de esta lista: {denominaciones}; "
            "si no hay ninguna, null.\n"
            "- precio_max y precio_min: euros por botella si el usuario indica presupuesto o busca algo "
            "caro; si no, null.\n"
            "- comensales: número de personas si se menciona; si no, null.\n"
            "- busqueda: una frase en español que describa el vino ideal (estilo, cuerpo, aromas y "
            "maridaje), pensada para una búsqueda semántica.\n"
            "No inventes requisitos que el usuario no ha pedido.",
        ),
        ("human", "{pregunta}"),
    ]
)


class Requisitos(BaseModel):
    tipos: list[str] = Field(default_factory=list)
    paises: list[str] = Field(default_factory=list)
    denominacion: str | None = None
    precio_max: float | None = None
    precio_min: float | None = None
    comensales: int | None = None
    busqueda: str = ""


@lru_cache(maxsize=1)
def _extractor():
    llm = ChatOllama(
        model=settings.ollama_chat_model,
        base_url=settings.ollama_url,
        temperature=0,
        num_ctx=4096,
        num_predict=400,
    )
    return PROMPT | llm.with_structured_output(Requisitos, method="json_schema")


def analizar(pregunta: str) -> Requisitos | None:
    try:
        resultado = _extractor().invoke(
            {
                "pregunta": pregunta,
                "tipos": ", ".join(TIPOS),
                "paises": ", ".join(paises()),
                "denominaciones": ", ".join(denominaciones()),
            }
        )
    except Exception:
        return None
    return sanear(resultado, pregunta) if resultado else None


def _canonico(valor: str | None, validos: list[str]) -> str | None:
    mapa = {normalizar(v): v for v in validos}
    return mapa.get(normalizar(valor or ""))


def _mencionado(valor: str, texto: str) -> bool:
    return bool(re.search(rf"\b{re.escape(normalizar(valor))}\b", normalizar(texto)))


def sanear(req: Requisitos, texto: str) -> Requisitos:
    """Descarta lo que el modelo se haya inventado.

    El país y la denominación son filtros duros: solo se aceptan si el usuario los menciona.
    """
    tipos = [t for t in (_canonico(t, TIPOS) for t in req.tipos) if t]
    mencionados = detectar_paises(normalizar(texto))
    lista_paises = [
        p for p in (_canonico(p, paises()) for p in req.paises)
        if p and (p in mencionados or _mencionado(p, texto))
    ]
    denominacion = _canonico(req.denominacion, denominaciones())
    if denominacion and not (
        _mencionado(denominacion, texto) or detectar_denominacion(normalizar(texto)) == denominacion
    ):
        denominacion = None
    precio_max = req.precio_max if req.precio_max and req.precio_max > 0 else None
    precio_min = req.precio_min if req.precio_min and req.precio_min > 0 else None
    if precio_min and precio_max and precio_min > precio_max:
        precio_min = None
    return Requisitos(
        tipos=list(dict.fromkeys(tipos)),
        paises=list(dict.fromkeys(lista_paises)),
        denominacion=denominacion,
        precio_max=precio_max,
        precio_min=precio_min,
        comensales=req.comensales if req.comensales and req.comensales > 0 else None,
        busqueda=req.busqueda.strip()[:300],
    )


def combinar(base: Criterios, req: Requisitos, texto: str, forzados: set[str]) -> Criterios:
    """Prioridad: lo elegido en el formulario, lo explícito en el texto, el modelo y por último las reglas."""
    c = replace(base, tipos=list(base.tipos), paises=list(base.paises))

    if "tipo" not in forzados and req.tipos and not (base.tipos and not base.tipos_sugeridos):
        c.tipos, c.tipos_sugeridos = req.tipos, True
    if "pais" not in forzados and req.paises and not base.paises:
        c.paises = req.paises
    if "denominacion" not in forzados and req.denominacion and not base.denominacion:
        c.denominacion = req.denominacion

    if "precio_max" not in forzados and detectar_precio_numerico(normalizar(texto)) is None:
        if req.precio_max:
            c.precio_max = req.precio_max
    if c.precio_max is None and req.precio_min:
        c.precio_min = req.precio_min

    if c.stock_min is None and req.comensales:
        c.stock_min = stock_para(req.comensales)
    return c
