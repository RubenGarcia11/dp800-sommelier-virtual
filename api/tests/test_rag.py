from app.rag import formatear_contexto


def test_vino_sin_anada_ni_notas():
    vino = {
        "id": 36, "nombre": "Tío Pepe Fino", "tipo": "Blanco", "uva": "Palomino Fino",
        "denominacion": "Jerez-Xérès-Sherry", "bodega": "González Byass", "pais": "España",
        "precio": 11.5, "similitud": 0.5,
    }
    texto = formatear_contexto({"vinos": [vino]})
    assert "Tío Pepe Fino" in texto and "sin añada" in texto and "11.5 EUR" in texto


def test_sin_vinos():
    assert "No hay ningún vino" in formatear_contexto({"vinos": []})
