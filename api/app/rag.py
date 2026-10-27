from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import Runnable, RunnableLambda, RunnablePassthrough
from langchain_ollama import ChatOllama

from app.config import settings
from app.db import json_unico
from app.reglas import Criterios

PROMPT = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "Eres un sommelier experto. Recomienda vinos usando únicamente los vinos "
            "del contexto. Si ninguno encaja con la pregunta, dilo con claridad. "
            "Menciona nombre, bodega y precio, explica brevemente por qué encaja "
            "y responde siempre en español. Respeta la denominación de origen "
            "el país y el presupuesto que indique el usuario: nunca recomiendes un vino más caro. "
            "Si el contexto no contiene ningún vino, di que no hay nada que cumpla lo pedido.",
        ),
        ("human", "Condiciones aplicadas: {condiciones}\n\nVinos disponibles:\n{contexto}\n\nPregunta: {pregunta}"),
    ]
)


def recuperar_vinos(entrada: dict) -> list[dict]:
    criterios: Criterios = entrada["criterios"]

    def consultar() -> list[dict]:
        return (
            json_unico(
                "EXEC dbo.usp_ContextoRag @Consulta = ?, @Top = ?, @Tipos = ?, @Denominacion = ?, "
                "@Paises = ?, @PrecioMin = ?, @PrecioMax = ?, @StockMin = ?",
                entrada.get("busqueda") or entrada["pregunta"],
                entrada["top"],
                ",".join(criterios.tipos) or None,
                criterios.denominacion,
                ",".join(criterios.paises) or None,
                criterios.precio_min,
                criterios.precio_max,
                criterios.stock_min or 1,
            )
            or []
        )

    vinos = consultar()
    if not vinos and criterios.tipos_sugeridos:
        # El tipo era solo una sugerencia: si no hay nada, se relaja
        criterios.tipos, criterios.tipos_sugeridos = [], False
        vinos = consultar()
    return vinos


def formatear_contexto(entrada: dict) -> str:
    # FOR JSON omite las claves con valor nulo, así que todo campo opcional se lee con get
    bloques = []
    for v in entrada["vinos"]:
        notas = v.get("notas") or []
        maridajes = "; ".join(n["maridaje"] for n in notas if n.get("maridaje"))
        sensaciones = "; ".join(
            " / ".join(n[c] for c in ("nariz", "boca") if n.get(c)) for n in notas
        )
        anada = v.get("anada") or "sin añada"
        precio = f"{v['precio']} EUR" if v.get("precio") is not None else "precio no disponible"
        bloques.append(
            f"- {v['nombre']} ({v.get('tipo', '')}, {v.get('uva', '')}, {anada}) de {v.get('bodega', '')} "
            f"({v.get('pais', '')}), D.O. {v.get('denominacion', '')}. Precio: {precio}. "
            f"{v.get('descripcion', '')} Cata: {sensaciones or 'sin notas'}. "
            f"Maridaje: {maridajes or 'sin datos'}."
        )
    return "\n".join(bloques) or "No hay ningún vino disponible que cumpla los criterios."


def construir_cadena() -> Runnable:
    llm = ChatOllama(
        model=settings.ollama_chat_model,
        base_url=settings.ollama_url,
        temperature=0.3,
        num_ctx=4096,
    )
    return (
        RunnablePassthrough.assign(vinos=RunnableLambda(recuperar_vinos))
        | RunnablePassthrough.assign(
            contexto=RunnableLambda(formatear_contexto),
            condiciones=RunnableLambda(lambda e: e["criterios"].descripcion()),
        )
        | RunnablePassthrough.assign(respuesta=PROMPT | llm | StrOutputParser())
    )
