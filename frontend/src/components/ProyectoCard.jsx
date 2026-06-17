import "../styles/card.css";

export default function ProyectoCard({ proyecto, onDelete, onOpen }) {
  return (
    <article className="card">
      <span className="badge">{proyecto.estado || "Planificado"}</span>
      <h3>{proyecto.nombre}</h3>
      <p>Responsable: {proyecto.responsable}</p>

      <div className="card-actions">
        <button onClick={() => onOpen(proyecto)}>Ver avances</button>

        <button
          className="danger"
          onClick={() => onDelete(proyecto.id)}
        >
          Eliminar
        </button>
      </div>
    </article>
  );
}
