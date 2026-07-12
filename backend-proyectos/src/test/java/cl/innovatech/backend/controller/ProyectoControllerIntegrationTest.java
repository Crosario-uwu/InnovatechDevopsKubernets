package cl.innovatech.backend.controller;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import cl.innovatech.backend.model.Proyecto;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ProyectoControllerIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    private static final String BASE_PATH = "/api/v1/proyectos";

    @Test
    void flujoCompletoCrearListarYEliminarProyecto() {
        Proyecto nuevo = new Proyecto();
        nuevo.setNombre("Despliegue EKS");
        nuevo.setResponsable("Equipo DevOps");

        ResponseEntity<Proyecto> creado = restTemplate.postForEntity(BASE_PATH, nuevo, Proyecto.class);
        assertThat(creado.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(creado.getBody()).isNotNull();
        assertThat(creado.getBody().getId()).isNotNull();
        assertThat(creado.getBody().getEstado()).isEqualTo("Planificado");

        Long id = creado.getBody().getId();

        ResponseEntity<Proyecto[]> listado = restTemplate.getForEntity(BASE_PATH, Proyecto[].class);
        assertThat(listado.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(listado.getBody()).extracting(Proyecto::getId).contains(id);

        restTemplate.delete(BASE_PATH + "/" + id);

        ResponseEntity<Proyecto[]> listadoTrasBorrado = restTemplate.getForEntity(BASE_PATH, Proyecto[].class);
        assertThat(listadoTrasBorrado.getBody()).extracting(Proyecto::getId).doesNotContain(id);
    }

    @Test
    void crearProyectoSinNombreDevuelveBadRequest() {
        Proyecto invalido = new Proyecto();
        invalido.setResponsable("Alguien");

        ResponseEntity<String> respuesta = restTemplate.postForEntity(BASE_PATH, invalido, String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void eliminarProyectoInexistenteDevuelveNotFound() {
        ResponseEntity<String> respuesta = restTemplate.exchange(
                BASE_PATH + "/999999", org.springframework.http.HttpMethod.DELETE, null, String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
