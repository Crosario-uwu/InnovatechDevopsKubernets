package cl.innovatech.backend.model;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "avances")
@Getter
@Setter
public class Avance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate fecha = LocalDate.now();

    @NotBlank(message = "La descripción del avance es obligatoria")
    private String descripcion;

    private boolean completado;

    @NotNull(message = "El id del proyecto es obligatorio")
    private Long proyectoId;
}