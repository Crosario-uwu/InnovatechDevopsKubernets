package cl.innovatech.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import cl.innovatech.backend.model.Avance;

public interface AvanceRepository extends JpaRepository<Avance, Long> {
    List<Avance> findByProyectoId(Long proyectoId);
}