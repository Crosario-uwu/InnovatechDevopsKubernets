package cl.innovatech.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import cl.innovatech.backend.exception.ResourceNotFoundException;
import cl.innovatech.backend.model.Avance;
import cl.innovatech.backend.repository.AvanceRepository;

@ExtendWith(MockitoExtension.class)
class AvanceServiceTest {

    @Mock
    private AvanceRepository avanceRepository;

    @InjectMocks
    private AvanceService avanceService;

    @Test
    void listarPorProyectoDelegaEnElRepositorio() {
        Avance avance = new Avance();
        avance.setDescripcion("Avance inicial");
        avance.setProyectoId(5L);
        when(avanceRepository.findByProyectoId(5L)).thenReturn(List.of(avance));

        List<Avance> resultado = avanceService.listarPorProyecto(5L);

        assertThat(resultado).containsExactly(avance);
    }

    @Test
    void guardarAsignaProyectoIdYFechaPorDefecto() {
        Avance avance = new Avance();
        avance.setDescripcion("Avance sin fecha");
        avance.setFecha(null);
        when(avanceRepository.save(any(Avance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Avance guardado = avanceService.guardar(7L, avance);

        assertThat(guardado.getProyectoId()).isEqualTo(7L);
        assertThat(guardado.getFecha()).isEqualTo(LocalDate.now());
    }

    @Test
    void guardarRespetaFechaExplicita() {
        LocalDate fecha = LocalDate.of(2026, 1, 15);
        Avance avance = new Avance();
        avance.setDescripcion("Avance con fecha fija");
        avance.setFecha(fecha);
        when(avanceRepository.save(any(Avance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Avance guardado = avanceService.guardar(3L, avance);

        assertThat(guardado.getFecha()).isEqualTo(fecha);
    }

    @Test
    void eliminarLanzaExcepcionSiNoExiste() {
        when(avanceRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> avanceService.eliminar(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("99");

        verify(avanceRepository, never()).deleteById(any());
    }

    @Test
    void eliminarBorraCuandoExiste() {
        when(avanceRepository.existsById(1L)).thenReturn(true);

        avanceService.eliminar(1L);

        verify(avanceRepository, times(1)).deleteById(1L);
    }
}
