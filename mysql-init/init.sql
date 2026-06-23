-- =======================================================
-- Innovatech - Inicializacion de base de datos
-- Se ejecuta automaticamente al crear el contenedor MySQL.
--
-- Los nombres de tabla/columna coinciden con lo que genera
-- Hibernate (ddl-auto=update) a partir de las entidades JPA
-- Proyecto y Avance, para que estos datos de prueba sean
-- visibles por la aplicacion en vez de quedar en tablas
-- huerfanas sin usar.
-- =======================================================

CREATE DATABASE IF NOT EXISTS innovatech_db;
USE innovatech_db;

-- =======================================================
-- Tabla: proyectos (entidad Proyecto)
-- =======================================================
CREATE TABLE IF NOT EXISTS proyectos (
    id          BIGINT NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(255) NOT NULL,
    responsable VARCHAR(255) NOT NULL,
    estado      VARCHAR(255),
    PRIMARY KEY (id)
);

-- =======================================================
-- Tabla: avances (entidad Avance)
-- =======================================================
CREATE TABLE IF NOT EXISTS avances (
    id          BIGINT NOT NULL AUTO_INCREMENT,
    fecha       DATE,
    descripcion VARCHAR(255) NOT NULL,
    completado  TINYINT(1) NOT NULL DEFAULT 0,
    proyecto_id BIGINT NOT NULL,
    PRIMARY KEY (id)
);

-- =======================================================
-- Datos de prueba
-- =======================================================
INSERT INTO proyectos (nombre, responsable, estado) VALUES
  ('Proyecto Alpha', 'Equipo Innovatech', 'activo'),
  ('Proyecto Beta',  'Equipo Innovatech', 'en_progreso');

INSERT INTO avances (fecha, descripcion, completado, proyecto_id) VALUES
  ('2026-06-01', 'Diseno de base de datos completado', 1, 1),
  ('2026-06-10', 'Desarrollo de API REST', 0, 1),
  ('2026-06-05', 'Levantamiento de requerimientos', 1, 2);
