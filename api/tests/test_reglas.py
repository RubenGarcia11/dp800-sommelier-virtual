import pytest

from app import reglas

DENOMINACIONES = [
    "Cava", "Jerez-Xérès-Sherry", "Priorat", "Rías Baixas", "Ribera del Duero", "Rioja", "Toro",
]
PAISES = ["Argentina", "España", "Francia", "Italia"]


@pytest.fixture(autouse=True)
def catalogo(monkeypatch):
    monkeypatch.setattr(reglas, "denominaciones", lambda: DENOMINACIONES)
    monkeypatch.setattr(reglas, "paises", lambda: PAISES)


def test_barbacoa_con_presupuesto():
    c = reglas.interpretar("voy a hacer una barbacoa, tienes un presupuesto de 20€")
    assert c.tipos == ["Tinto", "Rosado"] and c.tipos_sugeridos
    assert c.precio_max == 20


def test_pais_por_gentilicio():
    c = reglas.interpretar("dime un vino potente español")
    assert c.paises == ["España"]
    assert c.tipos == ["Tinto"]


def test_varios_paises():
    assert reglas.interpretar("un vino francés o italiano").paises == ["Francia", "Italia"]


def test_tipo_explicito_gana_a_la_sugerencia():
    c = reglas.interpretar("un blanco para el postre")
    assert c.tipos == ["Blanco"] and not c.tipos_sugeridos


def test_tipo_elegido_en_el_formulario():
    assert reglas.interpretar("marisco", tipo="Tinto").tipos == ["Tinto"]


@pytest.mark.parametrize(
    "pregunta, esperado",
    [
        ("un tinto de ribera", "Ribera del Duero"),
        ("quiero un albariño", "Rías Baixas"),
        ("un cava para brindar", "Cava"),
        ("algo de jerez", "Jerez-Xérès-Sherry"),
        ("rabo de toro", None),
        ("rioja o ribera", None),
    ],
)
def test_denominacion(pregunta, esperado):
    assert reglas.interpretar(pregunta).denominacion == esperado


@pytest.mark.parametrize(
    "pregunta, esperado",
    [
        ("por menos de 15 euros", 15),
        ("un vino de 12,50 €", 12.5),
        ("hasta 30", 30),
        ("una cena barata", 15),
        ("que no sea caro", 15),
        ("algo que no sea muy caro", 15),
        ("para hasta 12 personas", None),
        ("tengo 2 invitados y 20 euros", 20),
    ],
)
def test_precio_maximo(pregunta, esperado):
    assert reglas.interpretar(pregunta).precio_max == esperado


def test_precio_del_formulario_manda():
    assert reglas.interpretar("por menos de 15 euros", precio_max=40).precio_max == 40


def test_capricho_fija_precio_minimo():
    c = reglas.interpretar("un capricho para celebrar")
    assert c.precio_min == 50 and c.precio_max is None


def test_comensales_fijan_stock():
    assert reglas.interpretar("cena con 10 invitados").stock_min == 5
    assert reglas.interpretar("cena con 2 invitados").stock_min is None


def test_reglas_compatibles_se_intersectan():
    c = reglas.interpretar("barbacoa con un vino potente")
    assert c.tipos == ["Tinto"]


def test_reglas_incompatibles_se_unen():
    c = reglas.interpretar("cordero y marisco")
    assert set(c.tipos) == {"Tinto", "Blanco", "Espumoso"}
