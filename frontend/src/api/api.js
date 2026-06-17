const API = "/api/v1";

export async function getProyectos() {
  const res = await fetch(`${API}/proyectos`);
  return res.json();
}

export async function crearProyecto(proyecto) {
  const res = await fetch(`${API}/proyectos`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(proyecto),
  });
  return res.json();
}

export async function eliminarProyecto(id) {
  await fetch(`${API}/proyectos/${id}`, { method: "DELETE" });
}

export async function getAvancesPorProyecto(proyectoId) {
  const res = await fetch(`${API}/proyectos/${proyectoId}/avances`);
  return res.json();
}

export async function crearAvance(proyectoId, avance) {
  const res = await fetch(`${API}/proyectos/${proyectoId}/avances`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(avance),
  });
  return res.json();
}

export async function eliminarAvance(id) {
  await fetch(`${API}/avances/${id}`, { method: "DELETE" });
}
