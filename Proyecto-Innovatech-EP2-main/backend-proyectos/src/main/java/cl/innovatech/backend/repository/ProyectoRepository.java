package cl.innovatech.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import cl.innovatech.backend.model.Proyecto;

public interface ProyectoRepository extends JpaRepository<Proyecto, Long> {}
