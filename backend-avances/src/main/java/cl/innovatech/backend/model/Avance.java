package cl.innovatech.backend.model;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
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

    // Se asigna en AvanceService.guardar() a partir del @PathVariable de la
    // URL, nunca viene en el body del cliente (ver AvanceController) -- por
    // eso no lleva @NotNull: si lo llevara, @Valid rechazaria con 400 toda
    // creacion real, ya que el body nunca trae este campo.
    private Long proyectoId;
}