import { useState } from "react";
import { crearProyecto } from "../api/api";

export default function ProyectoForm({ onCreated }) {
  const [nombre, setNombre] = useState("");
  const [responsable, setResponsable] = useState("");
  const [estado, setEstado] = useState("Planificado");

  async function handleSubmit(event) {
    event.preventDefault();
    if (!nombre.trim() || !responsable.trim()) return;

    await crearProyecto({ nombre, responsable, estado });
    setNombre("");
    setResponsable("");
    setEstado("Planificado");
    onCreated();
  }

  return (
    <form className="form" onSubmit={handleSubmit}>
      <input
        placeholder="Nombre del proyecto"
        value={nombre}
        onChange={(e) => setNombre(e.target.value)}
      />

      <input
        placeholder="Responsable"
        value={responsable}
        onChange={(e) => setResponsable(e.target.value)}
      />

      <select value={estado} onChange={(e) => setEstado(e.target.value)}>
        <option>Planificado</option>
        <option>En progreso</option>
        <option>En revisión</option>
        <option>Finalizado</option>
      </select>

      <button type="submit">Crear proyecto</button>
    </form>
  );
}
