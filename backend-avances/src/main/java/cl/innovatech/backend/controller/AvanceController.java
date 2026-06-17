package cl.innovatech.backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import cl.innovatech.backend.model.Avance;
import cl.innovatech.backend.service.AvanceService;
import jakarta.validation.Valid;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1")
public class AvanceController {

    private final AvanceService avanceService;

    public AvanceController(AvanceService avanceService) {
        this.avanceService = avanceService;
    }

    @GetMapping("/avances")
    public ResponseEntity<List<Avance>> listarAvances() {
        return ResponseEntity.ok(avanceService.listar());
    }

    @GetMapping("/proyectos/{proyectoId}/avances")
    public ResponseEntity<List<Avance>> listarAvancesPorProyecto(@PathVariable Long proyectoId) {
        return ResponseEntity.ok(avanceService.listarPorProyecto(proyectoId));
    }

    @PostMapping("/proyectos/{proyectoId}/avances")
    public ResponseEntity<Avance> crearAvance(@PathVariable Long proyectoId,
                                              @Valid @RequestBody Avance avance) {
        return ResponseEntity.status(HttpStatus.CREATED).body(avanceService.guardar(proyectoId, avance));
    }

    @DeleteMapping("/avances/{id}")
    public ResponseEntity<Void> eliminarAvance(@PathVariable Long id) {
        avanceService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}