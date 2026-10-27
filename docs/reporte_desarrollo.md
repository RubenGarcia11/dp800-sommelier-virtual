# Reporte de desarrollo asistido por IA (Bloque B)

## 1. Herramienta y forma de trabajo

Desarrollé el proyecto con Claude Code, un asistente de programación que trabaja dentro de mi editor y puede crear ficheros y ejecutar comandos en mi equipo. Le definí el objetivo, la arquitectura y las restricciones en un prompt inicial, y trabajamos por fases. En cada fase el asistente generaba los ficheros, los ejecutaba en los contenedores y me resumía el resultado; yo revisaba, decidía y le daba la orden de continuar con la siguiente.

## 2. Prompts utilizados

**Prompt inicial.** Pedí al asistente que actuara como arquitecto de software y experto en SQL Server, le entregué la estructura del repositorio y le dividí el trabajo en seis fases (inicialización, base de datos, seguridad y optimización, embeddings y búsqueda vectorial, RAG y API, documentación). Establecí también la regla de parar al final de cada fase y esperar mi confirmación.

**Prompts por fase.** Tras cada resumen respondí con instrucciones cortas ("continúa") o con decisiones concretas:

| Momento | Mi indicación |
|---|---|
| Entorno | Pedí un `docker-compose` con SQL Server, Ollama y el resto de servicios. |
| Ejecución | Le pedí levantar los contenedores y ejecutar los scripts por su cuenta, reservándome la aprobación y las decisiones. |
| Embeddings | Ante tres opciones para mejorar la calidad de la búsqueda semántica, le pedí que eligiera la más óptima. Eligió cambiar a `bge-m3`. |
| Rendimiento | Cuando el chat iba a menos de 1 token por segundo, elegí usar el Ollama nativo del Mac en lugar de seguir en Docker. |
| Frontal | Pedí un frontal simple, elegante y funcional. |
| Datos | Pedí ampliar el catálogo con muchos vinos españoles y que se distinguieran las denominaciones (Ribera, Rioja, Rías Baixas…). |
| Errores | Reporté con capturas que el asistente se saltaba el presupuesto y que, según la consulta, aparecía un error 500. |
| Mejoras | Pedí reglas de interpretación de la pregunta, filtrado por país y un paso previo de análisis con el modelo que se pudiera desactivar. |
| Modelo | Con el modelo de 8B consumiendo demasiada memoria, le ordené terminar el proceso de Ollama y usar un modelo de 4B (`gemma3:4b`). |

## 3. Cómo verifiqué el código

No di por bueno ningún script sin ver su ejecución real. Todo se probó en los contenedores de Docker:

- **Esquema y datos.** Ejecuté los scripts en orden y comprobé los recuentos de bodegas, vinos, notas e inventario. Después amplié el catálogo con 47 vinos españoles de 15 denominaciones y comprobé que cada vino tenía su embedding.
- **Vistas y procedimientos.** Lancé el ranking por tipo, la búsqueda con filtros, la ficha en JSON, el mejor vino por bodega y el ajuste de stock, y comprobé que los resultados eran coherentes con los datos (por ejemplo, Château Margaux como mejor tinto con 98,5).
- **Seguridad.** Probé cada usuario con `EXECUTE AS`: un catador sin contexto ve 0 notas, con contexto ve solo las suyas, no puede insertar notas a nombre de otro, el usuario de consulta ve el precio de compra enmascarado y no accede a los márgenes.
- **Optimización.** Medí la misma consulta antes y después del índice con `STATISTICS IO/TIME` y comprobé el operador del plan: de Table Scan con 866 lecturas lógicas a Index Seek con 3.
- **Embeddings y búsqueda.** Verifiqué que todos los vinos tuvieran vector y probé cuatro consultas en lenguaje natural, valorando si el primer resultado tenía sentido.
- **API.** Llamé a cada endpoint y revisé que la respuesta del RAG se basara en los vinos recuperados.
- **Reproducibilidad.** Reconstruí la base de datos desde cero con `docker compose up db-init` y comprobé que los doce scripts se ejecutaban sin errores.

## 4. Errores detectados y correcciones

La revisión de las ejecuciones sacó varios fallos que se corrigieron:

1. **Restricción de fundación demasiado estricta.** El `CHECK` sobre el año de fundación rechazaba bodegas anteriores a 1500 (Antinori, 1385). Lo amplié a partir del año 1000.
2. **Precio de compra enmascarado para el gestor.** Faltaba conceder `UNMASK` a `rol_gestor`.
3. **Modelo de embeddings con poca precisión en español.** Con `nomic-embed-text`, consultas como "algo dulce para postre" o "espumoso para aperitivo" devolvían resultados poco relevantes. Cambié a `bge-m3` (1024 dimensiones) y regeneré los vectores.
4. **Descarga incompleta de `bge-m3`.** La primera descarga no terminó y SQL Server devolvía un error 404; la repetí y regeneré los embeddings.
5. **Chat demasiado lento.** En Docker, sin GPU, el LLM generaba menos de 1 token por segundo. Pasé el chat al Ollama nativo.
6. **Contexto desmesurado.** `llama3.1:8b` se cargaba con 131.072 tokens de contexto (23 GB). Fijé `num_ctx=4096` y, posteriormente, un modelo de 4B.
7. **Permisos de la API.** La API necesitaba leer todas las notas para el RAG, lo que obligó a crear un rol propio y ampliar el predicado de Row-Level Security, en lugar de conectar con `sa`.
8. **Presupuesto ignorado.** El precio de la pregunta solo llegaba al modelo como texto y recomendó un vino de 85 € para un presupuesto de 20 €. Ahora se detecta y se filtra en SQL.
9. **Error 500 según la consulta.** `FOR JSON` omite las claves nulas y los vinos sin añada rompían el formateo del contexto. Lo corregí y comprobé 73 consultas.
10. **Filtros inventados por el modelo.** En el análisis profundo el modelo añadió una denominación que nadie había pedido. Ahora el país y la denominación solo se aceptan si aparecen en el texto.

## 5. Limitaciones

La búsqueda semántica sobre solo 21 vinos no es perfecta: en la pregunta sobre marisco, un tinto entró entre los cuatro primeros resultados. El modelo de chat corrigió la selección en su respuesta, pero la recuperación mejoraría con más datos, un filtro por tipo o un reordenado de resultados.
