package cl.innovatech.backend.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;

import cl.innovatech.backend.exception.ResourceNotFoundException;
import cl.innovatech.backend.model.Avance;
import cl.innovatech.backend.repository.AvanceRepository;

@Service
public class AvanceService {

    private final AvanceRepository avanceRepository;

    public AvanceService(AvanceRepository avanceRepository) {
        this.avanceRepository = avanceRepository;
    }

    public List<Avance> listar() {
        return avanceRepository.findAll();
    }

    public List<Avance> listarPorProyecto(Long proyectoId) {
        return avanceRepository.findByProyectoId(proyectoId);
    }

    public Avance guardar(Long proyectoId, Avance avance) {
        if (avance.getFecha() == null) {
            avance.setFecha(LocalDate.now());
        }
        avance.setProyectoId(proyectoId);
        return avanceRepository.save(avance);
    }

    public void eliminar(Long id) {
        if (!avanceRepository.existsById(id)) {
            throw new ResourceNotFoundException("Avance no encontrado con id: " + id);
        }
        avanceRepository.deleteById(id);
    }
}