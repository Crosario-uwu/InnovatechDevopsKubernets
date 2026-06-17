package cl.innovatech.backend.service;

import java.util.List;

import org.springframework.stereotype.Service;

import cl.innovatech.backend.exception.ResourceNotFoundException;
import cl.innovatech.backend.model.Proyecto;
import cl.innovatech.backend.repository.ProyectoRepository;

@Service
public class ProyectoService {

    private final ProyectoRepository proyectoRepository;

    public ProyectoService(ProyectoRepository proyectoRepository) {
        this.proyectoRepository = proyectoRepository;
    }

    public List<Proyecto> listar() {
        return proyectoRepository.findAll();
    }

    public Proyecto guardar(Proyecto proyecto) {
        if (proyecto.getEstado() == null || proyecto.getEstado().isBlank()) {
            proyecto.setEstado("Planificado");
        }
        return proyectoRepository.save(proyecto);
    }

    public void eliminar(Long id) {
        if (!proyectoRepository.existsById(id)) {
            throw new ResourceNotFoundException("Proyecto no encontrado con id: " + id);
        }
        proyectoRepository.deleteById(id);
    }
}
