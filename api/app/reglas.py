import math
import re
import unicodedata
from dataclasses import dataclass, field

from app.db import denominaciones, paises

# Platos y ocasiones que apuntan a determinados tipos de vino
REGLAS_TIPO = [
    (r"barbacoa|parrilla|brasa|costilla|hamburguesa", ["Tinto", "Rosado"]),
    (r"potente|con cuerpo|estructurado|intenso|contundente", ["Tinto"]),
    (r"fresco|ligero|refrescante|veraniego", ["Blanco", "Rosado", "Espumoso"]),
    (r"chuleton|cordero|cochinillo|ternera|solomillo|entrecot|\bcaza\b|venado|jabali|estofado|rabo de toro|cocido|carne roja", ["Tinto"]),
    (r"marisco|ostra|almeja|mejillon|gamba|langostino|percebe|pulpo|sushi|sashimi|ceviche", ["Blanco", "Espumoso"]),
    (r"pescado|merluza|bacalao|lubina|dorada|salmon|atun", ["Blanco", "Rosado", "Espumoso"]),
    (r"paella|arroz|risotto", ["Blanco", "Rosado"]),
    (r"ensalada|verdura|vegetariano", ["Blanco", "Rosado", "Espumoso"]),
    (r"postre|tarta|chocolate|helado|foie|queso azul", ["Dulce", "Espumoso"]),
    (r"aperitivo|brindar|brindis|celebrar|celebracion|cumpleanos|aniversario|boda", ["Espumoso", "Blanco"]),
]

# Tipo pedido de forma explícita en la pregunta
TIPOS_EXPLICITOS = {
    "Tinto": r"\btintos?\b",
    "Blanco": r"\bblancos?\b",
    "Rosado": r"\brosados?\b|\brose\b",
    "Espumoso": r"\bespumosos?\b|\bburbujas?\b",
    "Dulce": r"\bvinos? dulces?\b|\bdulces\b",
}

ALIAS_DENOMINACION = {
    "ribera": "Ribera del Duero",
    "albarino": "Rías Baixas",
    "rias baixas": "Rías Baixas",
    "sherry": "Jerez-Xérès-Sherry",
    "jerez": "Jerez-Xérès-Sherry",
    "manzanilla": "Jerez-Xérès-Sherry",
    "txakoli": "Getariako Txakolina",
    "do toro": "Toro",
    "vino de toro": "Toro",
    "vinos de toro": "Toro",
    "penedes": "Penedès",
}
# Denominaciones cuyo nombre se confunde con palabras corrientes
IGNORAR_NOMBRE = {"toro", "cava"}

# Gentilicios y variantes que remiten a un país
ALIAS_PAIS = {
    "espanol": "España", "espanola": "España", "espanoles": "España", "espanolas": "España",
    "frances": "Francia", "francesa": "Francia", "franceses": "Francia", "francesas": "Francia",
    "italiano": "Italia", "italiana": "Italia", "italianos": "Italia", "italianas": "Italia",
    "argentino": "Argentina", "argentina": "Argentina", "argentinos": "Argentina", "argentinas": "Argentina",
}

PRESUPUESTO_BAJO = 15.0
PRESUPUESTO_ALTO = 50.0
PERSONAS_MIN_STOCK = 4

_NUMERO = r"(\d+(?:[.,]\d+)?)(?!\d)"
_NO_PERSONAS = r"(?!\s*(?:personas|invitados|comensales|amigos|botellas))"
_PATRONES_PRECIO = [
    rf"{_NUMERO}\s*(?:€|eur\w*|euros?)",
    rf"(?:presupuesto|menos de|hasta|maximo|no mas de|por debajo de|como mucho|bajo)\D{{0,20}}?{_NUMERO}{_NO_PERSONAS}",
]
_PRESUPUESTO_BAJO = r"barat[oa]s?|economic|asequible|ajustado|buen precio|no (?:sea |muy |demasiado )*caro|sin gastar mucho|no cueste mucho|calidad[- ]precio"
_PRESUPUESTO_ALTO = r"premium|\blujo\b|capricho|alta gama|sin limite de presupuesto|cueste lo que cueste|el dinero no importa"
_PERSONAS = rf"{_NUMERO}\s*(?:personas|invitados|comensales|amigos)"


@dataclass
class Criterios:
    tipos: list[str] = field(default_factory=list)
    tipos_sugeridos: bool = False
    denominacion: str | None = None
    paises: list[str] = field(default_factory=list)
    precio_min: float | None = None
    precio_max: float | None = None
    stock_min: int | None = None

    def etiquetas(self) -> list[str]:
        etiquetas = []
        if self.tipos:
            etiquetas.append(" / ".join(self.tipos) + (" (sugerido)" if self.tipos_sugeridos else ""))
        if self.paises:
            etiquetas.append(" / ".join(self.paises))
        if self.denominacion:
            etiquetas.append(f"D.O. {self.denominacion}")
        if self.precio_max is not None:
            etiquetas.append(f"hasta {self.precio_max:g} €")
        if self.precio_min is not None:
            etiquetas.append(f"desde {self.precio_min:g} €")
        if self.stock_min and self.stock_min > 1:
            etiquetas.append(f"al menos {self.stock_min} botellas")
        return etiquetas

    def descripcion(self) -> str:
        partes = []
        if self.precio_max is not None:
            partes.append(f"precio máximo {self.precio_max:g} EUR")
        if self.precio_min is not None:
            partes.append(f"precio mínimo {self.precio_min:g} EUR")
        if self.paises:
            partes.append("país " + ", ".join(self.paises))
        if self.denominacion:
            partes.append(f"denominación {self.denominacion}")
        if self.tipos:
            partes.append("tipos " + ", ".join(self.tipos))
        return "; ".join(partes) or "ninguno"


def normalizar(texto: str) -> str:
    sin_acentos = unicodedata.normalize("NFD", texto.lower())
    return "".join(c for c in sin_acentos if unicodedata.category(c) != "Mn")


def detectar_denominacion(texto: str) -> str | None:
    candidatas = dict(ALIAS_DENOMINACION)
    for nombre in denominaciones():
        clave = normalizar(nombre)
        if clave not in IGNORAR_NOMBRE:
            candidatas[clave] = nombre
    if re.search(r"\bcavas?\b", texto) and not re.search(r"\bcava\s+(de|del)\b", texto):
        candidatas["cava"] = "Cava"
    encontradas = {
        destino for clave, destino in candidatas.items() if re.search(rf"\b{re.escape(clave)}\b", texto)
    }
    return encontradas.pop() if len(encontradas) == 1 else None


def detectar_paises(texto: str) -> list[str]:
    candidatos = dict(ALIAS_PAIS)
    for nombre in paises():
        candidatos[normalizar(nombre)] = nombre
    encontrados = []
    for clave, destino in candidatos.items():
        if re.search(rf"\b{re.escape(clave)}\b", texto) and destino not in encontrados:
            encontrados.append(destino)
    return encontrados


def detectar_tipos(texto: str) -> tuple[list[str], bool]:
    explicitos = [tipo for tipo, patron in TIPOS_EXPLICITOS.items() if re.search(patron, texto)]
    if explicitos:
        return explicitos, False
    coincidencias = [tipos for patron, tipos in REGLAS_TIPO if re.search(patron, texto)]
    if not coincidencias:
        return [], False
    # Con varias reglas se queda lo que todas permiten; si no hay nada en común, se une todo
    comunes = [t for t in coincidencias[0] if all(t in otras for otras in coincidencias[1:])]
    sugeridos = comunes or list(dict.fromkeys(t for tipos in coincidencias for t in tipos))
    return sugeridos, True


def detectar_precio_numerico(texto: str) -> float | None:
    for patron in _PATRONES_PRECIO:
        m = re.search(patron, texto)
        if m:
            return float(m.group(1).replace(",", "."))
    return None


def detectar_precio_max(texto: str) -> float | None:
    numerico = detectar_precio_numerico(texto)
    if numerico is not None:
        return numerico
    return PRESUPUESTO_BAJO if re.search(_PRESUPUESTO_BAJO, texto) else None


def stock_para(personas: int) -> int | None:
    # aproximadamente una botella por cada dos personas
    return math.ceil(personas / 2) if personas >= PERSONAS_MIN_STOCK else None


def detectar_stock_min(texto: str) -> int | None:
    m = re.search(_PERSONAS, texto)
    return stock_para(int(float(m.group(1).replace(",", ".")))) if m else None


def interpretar(
    pregunta: str,
    tipo: str | None = None,
    denominacion: str | None = None,
    precio_max: float | None = None,
    pais: str | None = None,
) -> Criterios:
    texto = normalizar(pregunta)
    criterios = Criterios()

    if tipo:
        criterios.tipos = [tipo]
    else:
        criterios.tipos, criterios.tipos_sugeridos = detectar_tipos(texto)

    criterios.denominacion = denominacion or detectar_denominacion(texto)
    criterios.paises = [pais] if pais else detectar_paises(texto)
    criterios.precio_max = precio_max or detectar_precio_max(texto)
    if criterios.precio_max is None and re.search(_PRESUPUESTO_ALTO, texto):
        criterios.precio_min = PRESUPUESTO_ALTO
    criterios.stock_min = detectar_stock_min(texto)
    return criterios
