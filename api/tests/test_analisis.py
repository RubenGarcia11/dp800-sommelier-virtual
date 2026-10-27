import pytest

from app import analisis, reglas
from app.analisis import Requisitos, combinar, sanear


@pytest.fixture(autouse=True)
def catalogo(monkeypatch):
    for modulo in (reglas, analisis):
        monkeypatch.setattr(modulo, "denominaciones", lambda: ["Rioja", "Rías Baixas", "Toro"])
        monkeypatch.setattr(modulo, "paises", lambda: ["España", "Francia"])


def test_sanear_descarta_lo_inventado():
    req = sanear(Requisitos(
        tipos=["tinto", "Verde"], paises=["españa", "Narnia"], denominacion="Rias Baixas",
        precio_max=-5, precio_min=10, comensales=0, busqueda="  tinto con cuerpo  ",
    ), "un albariño de rias baixas, algo español")
    assert req.tipos == ["Tinto"] and req.paises == ["España"]
    assert req.denominacion == "Rías Baixas"
    assert req.precio_max is None and req.precio_min == 10 and req.comensales is None
    assert req.busqueda == "tinto con cuerpo"


def test_sanear_descarta_precio_minimo_incoherente():
    assert sanear(Requisitos(precio_min=50, precio_max=20), "").precio_min is None


def test_sanear_rechaza_filtros_duros_no_mencionados():
    req = sanear(Requisitos(paises=["Francia"], denominacion="Rioja"), "un vino para un arroz con secreto")
    assert req.paises == [] and req.denominacion is None


def test_sanear_acepta_gentilicios():
    assert sanear(Requisitos(paises=["Francia"]), "algo francés potente").paises == ["Francia"]


def test_el_modelo_completa_lo_que_las_reglas_no_ven():
    pregunta = "voy a preparar fabada, algo español"
    base = reglas.interpretar(pregunta)
    assert base.tipos == []
    c = combinar(base, Requisitos(tipos=["Tinto"], precio_max=20), pregunta, set())
    assert c.tipos == ["Tinto"] and c.tipos_sugeridos and c.precio_max == 20 and c.paises == ["España"]


def test_el_precio_escrito_en_el_texto_manda_sobre_el_modelo():
    pregunta = "un vino por menos de 30 euros"
    c = combinar(reglas.interpretar(pregunta), Requisitos(precio_max=10), pregunta, set())
    assert c.precio_max == 30


def test_el_modelo_corrige_un_presupuesto_heuristico():
    pregunta = "un vino barato"
    c = combinar(reglas.interpretar(pregunta), Requisitos(precio_max=8), pregunta, set())
    assert c.precio_max == 8


def test_lo_elegido_en_el_formulario_no_se_toca():
    pregunta = "marisco"
    base = reglas.interpretar(pregunta, tipo="Tinto", denominacion="Toro", precio_max=40)
    c = combinar(base, Requisitos(tipos=["Blanco"], denominacion="Rioja", precio_max=5), pregunta,
                 {"tipo", "denominacion", "precio_max"})
    assert c.tipos == ["Tinto"] and c.denominacion == "Toro" and c.precio_max == 40


def test_el_tipo_explicito_del_texto_manda_sobre_el_modelo():
    pregunta = "un blanco para el postre"
    c = combinar(reglas.interpretar(pregunta), Requisitos(tipos=["Dulce"]), pregunta, set())
    assert c.tipos == ["Blanco"]


def test_comensales_del_modelo():
    pregunta = "una comida familiar"
    c = combinar(reglas.interpretar(pregunta), Requisitos(comensales=12), pregunta, set())
    assert c.stock_min == 6
