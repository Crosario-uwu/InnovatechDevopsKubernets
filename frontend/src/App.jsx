import { useEffect, useState } from "react";
import ProyectoCard from "./components/ProyectoCard";
import ProyectoForm from "./components/ProyectoForm";
import AvanceModal from "./components/AvanceModal";
import { eliminarProyecto, getProyectos } from "./api/api";

export default function App() {
  const [proyectos, setProyectos] = useState([]);
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    loadProyectos();
  }, []);

  async function loadProyectos() {
    const data = await getProyectos();
    setProyectos(data);
  }

  async function handleEliminar(id) {
    await eliminarProyecto(id);
    loadProyectos();
  }

  return (
    <main className="container">
      <section className="hero">
        <p className="eyebrow">Innovatech Chile · EP2 DevOps</p>
        <h1>Gestión de Proyectos Innovatech</h1>
        <p className="subtitle">
          Demo funcional para validar contenedores, persistencia, comunicación Frontend → Backend y despliegue automatizado en AWS.
        </p>
      </section>

      <ProyectoForm onCreated={loadProyectos} />

      <div className="grid">
        {proyectos.map((proyecto) => (
          <ProyectoCard
            key={proyecto.id}
            proyecto={proyecto}
            onDelete={handleEliminar}
            onOpen={setSelected}
          />
        ))}
      </div>

      {selected && (
        <AvanceModal
          proyecto={selected}
          onClose={() => setSelected(null)}
        />
      )}
    </main>
  );
}
