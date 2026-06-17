package cl.innovatech.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class HealthController {

    @GetMapping({"/ping", "/ping/proyectos"})
    public ResponseEntity<Map<String, String>> ping() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "service", "innovatech-proyectos-backend",
                "context", "microservicio-proyectos"
        ));
    }
}