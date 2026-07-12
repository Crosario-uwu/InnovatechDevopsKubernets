package cl.innovatech.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import cl.innovatech.backend.exception.ResourceNotFoundException;
import cl.innovatech.backend.model.Proyecto;
import cl.innovatech.backend.repository.ProyectoRepository;

@ExtendWith(MockitoExtension.class)
class ProyectoServiceTest {

    @Mock
    private ProyectoRepository proyectoRepository;

    @InjectMocks
    private ProyectoService proyectoService;

    @Test
    void listarDelegaEnElRepositorio() {
        Proyecto proyecto = new Proyecto();
        proyecto.setNombre("Migracion EKS");
        when(proyectoRepository.findAll()).thenReturn(List.of(proyecto));

        List<Proyecto> resultado = proyectoService.listar();

        assertThat(resultado).containsExactly(proyecto);
    }

    @Test
    void guardarAsignaEstadoPlanificadoPorDefectoCuandoNoViene() {
        Proyecto proyecto = new Proyecto();
        proyecto.setNombre("Nuevo proyecto");
        proyecto.setResponsable("Ana");
        proyecto.setEstado(null);
        when(proyectoRepository.save(any(Proyecto.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Proyecto guardado = proyectoService.guardar(proyecto);

        assertThat(guardado.getEstado()).isEqualTo("Planificado");
    }

    @Test
    void guardarRespetaEstadoExplicito() {
        Proyecto proyecto = new Proyecto();
        proyecto.setNombre("Proyecto en curso");
        proyecto.setEstado("En progreso");
        when(proyectoRepository.save(any(Proyecto.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Proyecto guardado = proyectoService.guardar(proyecto);

        assertThat(guardado.getEstado()).isEqualTo("En progreso");
    }

    @Test
    void eliminarLanzaExcepcionSiNoExiste() {
        when(proyectoRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> proyectoService.eliminar(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("99");

        verify(proyectoRepository, never()).deleteById(any());
    }

    @Test
    void eliminarBorraCuandoExiste() {
        when(proyectoRepository.existsById(1L)).thenReturn(true);

        proyectoService.eliminar(1L);

        verify(proyectoRepository, times(1)).deleteById(1L);
    }
}
