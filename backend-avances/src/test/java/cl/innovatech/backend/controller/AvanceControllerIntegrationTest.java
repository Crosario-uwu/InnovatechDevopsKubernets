package cl.innovatech.backend.controller;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import cl.innovatech.backend.model.Avance;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AvanceControllerIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void flujoCompletoCrearListarYEliminarAvance() {
        Avance nuevo = new Avance();
        nuevo.setDescripcion("Configurar Fluent Bit");

        ResponseEntity<Avance> creado = restTemplate.postForEntity(
                "/api/v1/proyectos/1/avances", nuevo, Avance.class);
        assertThat(creado.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(creado.getBody()).isNotNull();
        assertThat(creado.getBody().getProyectoId()).isEqualTo(1L);

        Long id = creado.getBody().getId();

        ResponseEntity<Avance[]> porProyecto = restTemplate.getForEntity(
                "/api/v1/proyectos/1/avances", Avance[].class);
        assertThat(porProyecto.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(porProyecto.getBody()).extracting(Avance::getId).contains(id);

        restTemplate.delete("/api/v1/avances/" + id);

        ResponseEntity<Avance[]> listadoTrasBorrado = restTemplate.getForEntity(
                "/api/v1/proyectos/1/avances", Avance[].class);
        assertThat(listadoTrasBorrado.getBody()).extracting(Avance::getId).doesNotContain(id);
    }

    @Test
    void crearAvanceSinDescripcionDevuelveBadRequest() {
        Avance invalido = new Avance();

        ResponseEntity<String> respuesta = restTemplate.postForEntity(
                "/api/v1/proyectos/1/avances", invalido, String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void eliminarAvanceInexistenteDevuelveNotFound() {
        ResponseEntity<String> respuesta = restTemplate.exchange(
                "/api/v1/avances/999999", HttpMethod.DELETE, null, String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
