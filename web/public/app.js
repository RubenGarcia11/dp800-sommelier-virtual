const $ = (sel) => document.querySelector(sel);
const API = "/api";

const euros = (n) =>
  Number(n).toLocaleString("es-ES", { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + " €";

const escapar = (t) =>
  String(t ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function markdown(texto) {
  const inline = (s) =>
    escapar(s).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>").replace(/(^|[\s(])\*(?!\s)(.+?)\*/g, "$1<em>$2</em>");
  const html = [];
  let lista = false;
  for (const linea of texto.split("\n")) {
    const item = linea.match(/^\s*[*-]\s+(.*)/);
    if (item) {
      if (!lista) { html.push("<ul>"); lista = true; }
      html.push(`<li>${inline(item[1])}</li>`);
      continue;
    }
    if (lista) { html.push("</ul>"); lista = false; }
    if (linea.trim()) html.push(`<p>${inline(linea)}</p>`);
  }
  if (lista) html.push("</ul>");
  return html.join("");
}

async function api(ruta, opciones = {}) {
  const resp = await fetch(API + ruta, opciones);
  if (!resp.ok) throw new Error(`Error ${resp.status}`);
  return resp.json();
}

/* Pestañas */
document.querySelectorAll(".pestana").forEach((boton) =>
  boton.addEventListener("click", () => {
    document.querySelectorAll(".pestana").forEach((b) => {
      b.classList.toggle("activa", b === boton);
      b.setAttribute("aria-selected", b === boton);
    });
    document.querySelectorAll(".vista").forEach((v) => v.classList.toggle("activa", v.id === boton.dataset.vista));
    if (boton.dataset.vista === "catalogo" && !catalogo.length) cargarCatalogo();
  })
);

/* Tarjetas */
function tarjeta(v, extra = "") {
  const precio = v.PrecioVenta ?? v.precio;
  return `
    <button class="tarjeta" data-id="${v.VinoId ?? v.id}">
      <span class="etiqueta t-${escapar(v.Tipo ?? v.tipo)}">${escapar(v.Tipo ?? v.tipo)}</span>
      <h3>${escapar(v.Nombre ?? v.nombre)}</h3>
      <span class="denominacion">D.O. ${escapar(v.Denominacion ?? v.denominacion)}</span>
      <span class="bodega">${escapar(v.Bodega ?? v.bodega)}${v.Pais ?? v.pais ? " · " + escapar(v.Pais ?? v.pais) : ""}</span>
      <span class="uva">${escapar(v.Uva ?? v.uva)}${v.Anada ?? v.anada ? " · " + (v.Anada ?? v.anada) : ""}</span>
      ${extra}
      <div class="pie">
        <span class="precio-valor">${precio != null ? euros(precio) : ""}</span>
        ${v.PuntuacionMedia ? `<span class="puntos">${Number(v.PuntuacionMedia).toFixed(1)} pts</span>` : ""}
      </div>
    </button>`;
}

document.addEventListener("click", (e) => {
  const t = e.target.closest(".tarjeta");
  if (t) abrirFicha(t.dataset.id);
});

/* Consulta RAG */
const resultado = $("#resultado");
const boton = $("#boton-preguntar");

async function preguntar(evento) {
  evento?.preventDefault();
  const pregunta = $("#pregunta").value.trim();
  if (pregunta.length < 3) return;

  boton.disabled = true;
  const profundo = $("#opcion-analisis").checked;
  resultado.innerHTML = `<div class="respuesta catando"><div class="copa"></div>${
    profundo ? "Analizando tu petición y consultando la bodega…" : "El sommelier está catando tu pregunta…"
  }</div>`;

  try {
    const datos = await api("/preguntar", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        pregunta,
        tipo: $("#opcion-tipo").value || null,
        denominacion: $("#opcion-do").value || null,
        pais: $("#opcion-pais").value || null,
        precio_max: Number($("#opcion-precio").value) || null,
        analisis_profundo: $("#opcion-analisis").checked,
        top: Number($("#opcion-top").value),
      }),
    });

    const fichas = await Promise.all(
      datos.vinos.map((v) => api(`/vinos/${v.id}`).then((f) => ({ ...f, similitud: v.similitud })).catch(() => null))
    );

    resultado.innerHTML = `
      <article class="respuesta"><h2>La recomendación</h2>${markdown(datos.respuesta)}
        ${notaAnalisis(datos)}
        ${datos.criterios.length ? `<div class="criterios"><span>Criterios aplicados</span>${datos.criterios.map((c) => `<em>${escapar(c)}</em>`).join("")}</div>` : ""}
      </article>
      <div>
        <p class="subtitulo">Vinos consultados en la bodega</p>
        <div class="rejilla">${fichas.filter(Boolean).map(tarjetaRag).join("")}</div>
      </div>`;
  } catch (err) {
    resultado.innerHTML = `<div class="respuesta error"><h2>No he podido responder</h2><p>${escapar(err.message)}. Comprueba que la API y Ollama están en marcha.</p></div>`;
  } finally {
    boton.disabled = false;
  }
}

function notaAnalisis({ analisis }) {
  if (analisis.estado === "profundo")
    return `<p class="nota-analisis"><strong>Análisis profundo.</strong> ${
      analisis.interpretacion ? "He buscado: " + escapar(analisis.interpretacion) : "Requisitos interpretados."
    }</p>`;
  if (analisis.estado === "sin_analisis")
    return `<p class="nota-analisis">No se pudo completar el análisis profundo; se usaron las reglas básicas.</p>`;
  return "";
}

function tarjetaRag(f) {
  const pct = Math.max(0, Math.min(100, Math.round(f.similitud * 100)));
  return tarjeta(
    { id: f.VinoId, Nombre: f.Nombre, Tipo: f.Tipo, Uva: f.Uva, Anada: f.Anada, Bodega: f.bodega.nombre, Pais: f.bodega.pais, Denominacion: f.denominacion, PrecioVenta: f.inventario?.precio },
    `<div class="barra"><span style="width:${pct}%"></span></div><span class="sim-texto">Afinidad con tu pregunta: ${pct}%</span>`
  );
}

try {
  const guardado = localStorage.getItem("analisis-profundo");
  if (guardado !== null) $("#opcion-analisis").checked = guardado === "1";
} catch {}
$("#opcion-analisis").addEventListener("change", (e) => {
  try { localStorage.setItem("analisis-profundo", e.target.checked ? "1" : "0"); } catch {}
});

$("#form-pregunta").addEventListener("submit", preguntar);
$("#pregunta").addEventListener("keydown", (e) => {
  if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) preguntar(e);
});
$("#sugerencias").addEventListener("click", (e) => {
  if (e.target.tagName !== "BUTTON") return;
  $("#pregunta").value = e.target.textContent;
  preguntar();
});

/* Catálogo */
let catalogo = [];
const MAX_PRECIO = 800;

async function cargarCatalogo() {
  $("#contador").textContent = "Cargando catálogo…";
  try {
    const tipo = $("#filtro-tipo").value;
    const precio = Number($("#filtro-precio").value);
    const params = new URLSearchParams();
    const denominacion = $("#filtro-do").value;
    if (tipo) params.set("tipo", tipo);
    if (denominacion) params.set("denominacion", denominacion);
    if ($("#filtro-pais").value) params.set("pais", $("#filtro-pais").value);
    if (precio < MAX_PRECIO) params.set("precio_max", precio);
    catalogo = await api("/vinos?" + params);
    pintarCatalogo();
  } catch (err) {
    $("#contador").textContent = "No se pudo cargar el catálogo: " + err.message;
  }
}

function pintarCatalogo() {
  const texto = $("#filtro-texto").value.trim().toLowerCase();
  const lista = catalogo.filter((v) =>
    [v.Nombre, v.Uva, v.Bodega, v.Denominacion].some((c) => c.toLowerCase().includes(texto))
  );
  $("#contador").textContent = `${lista.length} ${lista.length === 1 ? "vino" : "vinos"} disponibles`;
  $("#rejilla").innerHTML = lista.map((v) => tarjeta(v)).join("");
}

$("#filtro-texto").addEventListener("input", pintarCatalogo);
$("#filtro-tipo").addEventListener("change", cargarCatalogo);
$("#filtro-do").addEventListener("change", cargarCatalogo);
$("#filtro-pais").addEventListener("change", cargarCatalogo);
$("#filtro-precio").addEventListener("input", (e) => {
  const v = Number(e.target.value);
  $("#valor-precio").textContent = v >= MAX_PRECIO ? "sin límite" : v;
});
$("#filtro-precio").addEventListener("change", cargarCatalogo);
$("#valor-precio").textContent = "sin límite";

/* Ficha */
const dialogo = $("#ficha");

async function abrirFicha(id) {
  try {
    const f = await api(`/vinos/${id}`);
    const notas = (f.notas || [])
      .map(
        (n) => `
        <div class="nota">
          <p><strong>Vista:</strong> ${escapar(n.vista)}<br>
          <strong>Nariz:</strong> ${escapar(n.nariz)}<br>
          <strong>Boca:</strong> ${escapar(n.boca)}<br>
          <strong>Maridaje:</strong> ${escapar(n.maridaje)}</p>
          <span class="autor">${escapar(n.catador)} · ${n.puntuacion} puntos</span>
        </div>`
      )
      .join("");
    dialogo.innerHTML = `
      <div class="ficha">
        <button class="cerrar" aria-label="Cerrar">×</button>
        <span class="etiqueta t-${escapar(f.Tipo)}">${escapar(f.Tipo)}</span>
        <h2>${escapar(f.Nombre)}</h2>
        <span class="bodega">${escapar(f.bodega.nombre)} · ${escapar(f.bodega.pais)}</span>
        <dl class="datos">
          <div><dt>Denominación</dt><dd>${escapar(f.denominacion)}</dd></div>
          <div><dt>Uva</dt><dd>${escapar(f.Uva)}</dd></div>
          <div><dt>Añada</dt><dd>${f.Anada ?? "—"}</dd></div>
          <div><dt>Graduación</dt><dd>${f.Graduacion}%</dd></div>
          <div><dt>Precio</dt><dd>${f.inventario ? euros(f.inventario.precio) : "—"}</dd></div>
          <div><dt>Stock</dt><dd>${f.inventario ? f.inventario.stock + " uds." : "—"}</dd></div>
        </dl>
        <h3>Notas de cata</h3>
        ${notas || "<p>Aún sin notas de cata.</p>"}
      </div>`;
    dialogo.showModal();
  } catch (err) {
    alert("No se pudo abrir la ficha: " + err.message);
  }
}

dialogo.addEventListener("click", (e) => {
  if (e.target === dialogo || e.target.classList.contains("cerrar")) dialogo.close();
});

/* Denominaciones de origen */
api("/denominaciones")
  .then((lista) => {
    const opciones = lista.map((d) => `<option>${escapar(d)}</option>`).join("");
    $("#opcion-do").insertAdjacentHTML("beforeend", opciones);
    $("#filtro-do").insertAdjacentHTML("beforeend", opciones);
  })
  .catch(() => {});

api("/paises")
  .then((lista) => {
    const opciones = lista.map((p) => `<option>${escapar(p)}</option>`).join("");
    $("#opcion-pais").insertAdjacentHTML("beforeend", opciones);
    $("#filtro-pais").insertAdjacentHTML("beforeend", opciones);
  })
  .catch(() => {});
