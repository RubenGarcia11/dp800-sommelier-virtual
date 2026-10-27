# Sommelier Virtual

Asistente de recomendación de vinos sobre SQL Server 2025. La base de datos almacena el catálogo, las notas de cata y el inventario, genera embeddings con un modelo local servido por Ollama y responde preguntas en lenguaje natural mediante un flujo RAG expuesto por una API en Python.

Proyecto del nivel 3 (avanzado) de DP-800.

## Arquitectura

```
Pregunta ─► FastAPI ─► usp_ContextoRag (SQL Server 2025)
                          │  AI_GENERATE_EMBEDDINGS ─► Ollama (bge-m3) vía HTTPS
                          │  VECTOR_DISTANCE (coseno)
                          ▼
                    vinos + notas de cata (JSON)
                          │
              LangChain ─► Ollama nativo (gemma3:4b) ─► respuesta
```

| Servicio | Función | Puerto |
|---|---|---|
| `sqlserver` | SQL Server 2025 | 1433 |
| `ollama` | Embeddings (`bge-m3`) para SQL Server | 11435 |
| `ollama-tls` | Proxy Caddy con TLS (`CREATE EXTERNAL MODEL` exige HTTPS) | interno |
| `api` | FastAPI + LangChain | 8000 |
| `web` | Frontal estático servido por nginx, con proxy `/api` hacia la API | 3000 |

El modelo de chat se ejecuta en el Ollama nativo del equipo para aprovechar la GPU; los contenedores lo alcanzan por `host.docker.internal:11434`.

## Estructura

```
├── database/   esquema, datos, vistas, procedimientos, seguridad y optimización
│   └── demos/  índice de la demo de optimización (no se ejecuta automáticamente)
├── ai/         modelo externo, embeddings, búsqueda vectorial y RAG
├── api/        backend FastAPI + LangChain
├── web/        frontal (HTML, CSS y JS sin dependencias) y configuración de nginx
├── proxy/      configuración de Caddy
├── docs/       guía de despliegue y reporte de desarrollo asistido por IA
└── docker-compose.yml
```

## Puesta en marcha

Guía completa, con verificación y solución de problemas: [docs/guia_despliegue.md](docs/guia_despliegue.md).

Requisitos: Docker, OpenSSL y [Ollama](https://ollama.com) instalado en el equipo.

```bash
cp .env.example .env                 # ajusta las contraseñas
./ai/generar_certificados.sh         # CA y certificado para el proxy TLS
ollama pull gemma3:4b                # modelo de chat (Ollama nativo)
docker compose up -d sqlserver ollama ollama-tls
docker compose up ollama-init        # descarga bge-m3
docker compose up db-init            # crea la base de datos y ejecuta los scripts
docker compose --profile app up -d --build api web
```

La aplicación queda en <http://localhost:3000>: una pestaña para preguntar al sommelier y otra con el catálogo filtrable y la ficha de cada vino.

Con la API arriba, también se puede consultar directamente:

```bash
curl -X POST localhost:8000/preguntar -H 'Content-Type: application/json' \
  -d '{"pregunta": "Un vino para una cena de marisco con presupuesto ajustado"}'
```

Documentación interactiva en <http://localhost:8000/docs>.

## Base de datos

- **Esquema** (`02_create_tables.sql`): `Bodegas`, `Vinos`, `NotasCata` e `Inventario`, con claves primarias y foráneas, restricciones `CHECK` e índices.
- **Datos** (`03_seed_data.sql` y `03b_seed_espana.sql`): 49 bodegas, 68 vinos de 24 denominaciones de origen, con notas de cata e inventario. Cada vino lleva su propia `Denominacion` (Rioja, Ribera del Duero, Rías Baixas, Rueda, Priorat, Toro, Bierzo, Cava, Jerez…), porque una bodega puede elaborar en varias DO.
- **Vistas** (`04_views.sql`): catálogo, márgenes y ranking por tipo con CTE y funciones de ventana.
- **Procedimientos** (`05_stored_procedures.sql`): búsqueda con filtros, alta de notas, ajuste de stock, ficha en JSON y mejor vino por bodega.

### Seguridad (`06_security.sql`, `09_api_user.sql`)

- Roles con permisos mínimos: `rol_consulta`, `rol_catador`, `rol_gestor` y `rol_api`.
- Row-Level Security sobre `NotasCata`: cada catador solo ve y registra sus notas, identificado mediante `SESSION_CONTEXT('catador')`.
- Enmascarado dinámico de `PrecioCompra`, visible solo con `UNMASK` para el gestor.
- La API se conecta con un login propio (`api_sommelier`), no con `sa`.

### Optimización (`07_optimization.sql`)

`usp_GastoClientePorMes` consulta 200.000 pedidos de una tabla sin índice clustered. Con el índice `IX_Pedidos_Cliente_Fecha` (`demos/optimizacion_indice.sql`) el plan pasa de Table Scan a Index Seek:

| | Operador | Lecturas lógicas | CPU |
|---|---|---|---|
| Sin índice | Table Scan | 866 | 477 ms |
| Con índice | Index Seek | 3 | 11 ms |

## IA

- `create_external_model.sql`: registra `ModeloEmbeddings` apuntando a Ollama a través del proxy TLS.
- `generate_embeddings.sql`: añade la columna `Vinos.Embedding VECTOR(1024)` y la rellena con `AI_GENERATE_EMBEDDINGS` a partir de la ficha y las notas de cata.
- `vector_search.sql`: `usp_BuscarVinosSemantico`, búsqueda por distancia coseno.
- `rag.sql`: `usp_ContextoRag`, contexto en JSON para el LLM.

## API

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Estado y conexión con la base de datos |
| GET | `/vinos` | Catálogo con filtros `tipo`, `precio_max`, `region`, `denominacion` y `pais` |
| GET | `/paises` | Países disponibles |
| GET | `/denominaciones` | Denominaciones de origen disponibles |
| GET | `/vinos/{id}` | Ficha completa con notas |
| GET | `/buscar?q=` | Búsqueda semántica |
| POST | `/preguntar` | Pregunta en lenguaje natural (RAG); filtra por la denominación indicada o detectada en el texto |

## Reglas de interpretación

Antes de buscar, la API (`api/app/reglas.py`) extrae criterios de la pregunta y los aplica como filtros en SQL. La interfaz muestra los criterios aplicados.

| Se detecta | Ejemplo | Efecto |
|---|---|---|
| Plato, estilo u ocasión | "barbacoa", "marisco", "potente", "fresco", "postre", "aperitivo" | Tipos de vino adecuados (sugeridos). Si varias reglas coinciden, se usa lo que comparten; si no hay resultados, se relaja |
| Tipo explícito | "un blanco", "tinto o rosado" | Filtra por ese tipo |
| País | "español", "francés", "italiano", "de Argentina" | Filtra por el país de la bodega (admite varios) |
| Denominación | "ribera", "albariño", "jerez" | Filtra por D.O. |
| Presupuesto | "20€", "menos de 15 euros", "barato" | Precio máximo |
| Capricho | "premium", "lujo" | Precio mínimo de 50 € |
| Comensales | "10 invitados" (4 o más) | Stock mínimo de una botella por cada dos personas |

### Análisis profundo (opcional)

Con el interruptor "Análisis profundo" activado (`analisis_profundo` en `/preguntar`), un paso previo del modelo interpreta la petición y devuelve los requisitos en JSON: tipos de vino, país, denominación, presupuesto, comensales y una descripción del vino ideal que se usa en la búsqueda semántica. Después se filtra en SQL con esos requisitos.

- **Validación:** todo lo que devuelve el modelo se contrasta con el catálogo. El país y la denominación solo se aceptan si aparecen en el texto del usuario, porque un modelo pequeño tiende a inventar filtros.
- **Prioridad:** lo elegido en el formulario, lo explícito en el texto (por ejemplo, un precio escrito en cifras), el modelo y, por último, las reglas.
- **Rendimiento:** añade entre 5 y 15 segundos. Con el interruptor apagado solo se aplican las reglas.
- **Fallo del modelo:** si el análisis falla, se usan las reglas y la interfaz lo indica.

Las reglas tienen pruebas automáticas:

```bash
docker cp api/tests sommelier-api:/srv/tests
docker exec sommelier-api sh -c "pip install -q pytest && python -m pytest -q tests"
```

## Limitaciones conocidas

- El conjunto de datos es pequeño (68 vinos), así que la recuperación semántica a veces coloca un vino poco relevante entre los primeros resultados.
- Las contraseñas de `.env.example` son solo para desarrollo.
- En Apple Silicon, SQL Server se ejecuta emulado (`linux/amd64`).
