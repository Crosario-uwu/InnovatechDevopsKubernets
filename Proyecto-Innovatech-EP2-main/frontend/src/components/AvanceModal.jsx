import { useEffect, useState } from "react";
import { crearAvance, eliminarAvance, getAvancesPorProyecto } from "../api/api";
import "../styles/modal.css";

export default function AvanceModal({ proyecto, onClose }) {
  const [avances, setAvances] = useState([]);
  const [descripcion, setDescripcion] = useState("");

  useEffect(() => {
    load();
  }, []);

  async function load() {
    const data = await getAvancesPorProyecto(proyecto.id);
    setAvances(data);
  }

  async function crear() {
    if (!descripcion.trim()) return;
    await crearAvance(proyecto.id, {
      fecha: new Date().toISOString().split("T")[0],
      descripcion,
      completado: false,
    });
    setDescripcion("");
    load();
  }

  async function eliminar(id) {
    await eliminarAvance(id);
    load();
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>Avances - {proyecto.nombre}</h2>
        <p className="modal-subtitle">Registra evidencias simples para demostrar persistencia de datos.</p>

        <div className="avance-form">
          <input
            placeholder="Descripción del avance"
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
          />
          <button className="primary" onClick={crear}>Agregar avance</button>
        </div>

        <ul className="lista">
          {avances.map((avance) => (
            <li key={avance.id}>
              <span>
                {avance.fecha} - {avance.descripcion}
              </span>

              <button
                className="danger"
                onClick={() => eliminar(avance.id)}
              >
                borrar
              </button>
            </li>
          ))}
        </ul>

        <button onClick={onClose}>Cerrar</button>
      </div>
    </div>
  );
}
