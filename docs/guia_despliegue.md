# Guía de despliegue

## Requisitos

- Docker con Compose v2 y al menos 8 GB de memoria asignada.
- [Ollama](https://ollama.com) instalado en el equipo (hace el chat con GPU).
- OpenSSL.
- Unos 8 GB libres en disco (imágenes y modelos).

En Apple Silicon, SQL Server se ejecuta emulado (`linux/amd64`); el arranque es más lento, pero funciona.

## 1. Configuración

```bash
git clone https://github.com/RubenGarcia11/dp800-sommelier-virtual.git
cd dp800-sommelier-virtual
cp .env.example .env
```

Edita `.env` y cambia `MSSQL_SA_PASSWORD` y `API_DB_PASSWORD` por contraseñas propias. SQL Server exige al menos 8 caracteres con mayúsculas, minúsculas, números y símbolos.

## 2. Certificado para el proxy TLS

`CREATE EXTERNAL MODEL` solo acepta endpoints HTTPS. El script crea una CA local y un certificado que SQL Server y Caddy comparten:

```bash
./ai/generar_certificados.sh
```

## 3. Modelo de chat (Ollama nativo)

```bash
ollama pull gemma3:4b
```

Comprueba que Ollama escucha en `http://localhost:11434`. Si usas otro modelo, cámbialo en `OLLAMA_CHAT_MODEL`.

## 4. Servicios base

```bash
docker compose up -d sqlserver ollama ollama-tls
docker compose up ollama-init     # descarga bge-m3 (unos 1,2 GB)
```

## 5. Base de datos

```bash
docker compose up db-init
```

Ejecuta en orden los scripts de `database/` y `ai/`: esquema, datos, vistas, procedimientos, seguridad, modelo externo, embeddings y RAG. Termina con `exited with code 0`. Es repetible: borra y recrea la base de datos cada vez.

## 6. API y frontal

```bash
docker compose --profile app up -d --build api web
```

| Servicio | URL |
|---|---|
| Aplicación | http://localhost:3000 |
| API y documentación | http://localhost:8000/docs |

## 7. Verificación

```bash
curl localhost:8000/health                         # {"estado":"ok"}
curl "localhost:8000/vinos?denominacion=Rioja"     # catálogo filtrado
curl "localhost:8000/buscar?q=vino%20para%20marisco&top=3"   # búsqueda semántica
```

Pruebas de las reglas de interpretación:

```bash
docker cp api/tests sommelier-api:/srv/tests
docker exec sommelier-api sh -c "pip install -q pytest && python -m pytest -q tests"
```

## Operación

| Tarea | Comando |
|---|---|
| Ver registros de la API | `docker compose logs -f api` |
| Reconstruir la API tras cambiar código | `docker compose --profile app up -d --build api` |
| Parar todo conservando datos | `docker compose --profile app down` |
| Borrar también volúmenes (datos y modelos) | `docker compose --profile app down -v` |
| Conectarse a SQL Server | `sqlcmd -C -S localhost,1433 -U sa -P "<contraseña>" -d SommelierVirtual` |

## Problemas frecuentes

- **`Error 500` al preguntar o "No he podido responder":** comprueba que la app de Ollama está abierta (`curl localhost:11434/api/version`) y que el modelo de `OLLAMA_CHAT_MODEL` está descargado (`ollama list`).
- **La respuesta tarda más de un minuto:** el modelo se está cargando por primera vez o no cabe en memoria. Usa un modelo más pequeño. El interruptor "Análisis profundo" añade entre 5 y 15 segundos; apágalo para respuestas más rápidas.
- **`db-init` falla con un error 404 al generar embeddings:** `bge-m3` no está descargado. Repite `docker compose up ollama-init`.
- **`db-init` falla con un error de certificado:** regenera los certificados (paso 2) y recrea SQL Server con `docker compose up -d --force-recreate sqlserver ollama-tls`.
- **El puerto 11434 está ocupado:** el contenedor de Ollama usa el 11435 para no chocar con el Ollama nativo. Cambia `OLLAMA_PORT` en `.env` si también está en uso.
- **En Linux,** el contenedor de la API alcanza el Ollama del equipo mediante `host.docker.internal`, que el compose resuelve con `host-gateway`. Si Ollama solo escucha en `127.0.0.1`, arráncalo con `OLLAMA_HOST=0.0.0.0`.
- **SQL Server tarda en arrancar en Mac con Apple Silicon:** es normal por la emulación. El `healthcheck` espera hasta dos minutos.
