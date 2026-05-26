-- ============================================================
-- HU04: Registro de Merma por Tipo de Tejido
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x / TiDB Cloud)
-- Ejecutar DESPUÉS de: schema.sql, HU09_gestion_perfiles.sql,
--                       HU01.sql, HU02_fallas_tela.sql,
--                       HU03_tiempos_reposo.sql
-- ============================================================

USE textil_db;

-- ------------------------------------------------------------
-- TABLA: mermas
-- CUS 4.1: Registrar Merma por Tejido
-- CUS 4.2: Calcular Porcentaje de Merma por Orden de Corte (CA1)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mermas (
    id_merma            INT AUTO_INCREMENT PRIMARY KEY,
    id_tela             INT             NOT NULL COMMENT 'Tela sobre la que se genera la merma',
    id_ot               INT             NOT NULL COMMENT 'Orden de trabajo/corte asociada',
    id_tizador          INT             NOT NULL COMMENT 'Tizador que registra',
    fase                ENUM('TIZADO','CORTE') NOT NULL COMMENT 'Fase donde se genera la merma',
    peso_utilizado_kg   DECIMAL(10,3)   NOT NULL COMMENT 'Kg de tela realmente usados en la fase',
    peso_merma_kg       DECIMAL(10,3)   NOT NULL COMMENT 'Kg de tela perdida (merma)',
    porcentaje_merma    DECIMAL(6,3)    AS (
                            CASE WHEN peso_utilizado_kg > 0
                            THEN ROUND((peso_merma_kg / peso_utilizado_kg) * 100, 3)
                            ELSE 0 END
                        ) STORED COMMENT 'CA1 HU04: % merma calculado automáticamente',
    observaciones       TEXT            NULL,
    fecha_registro      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_merma_tela    FOREIGN KEY (id_tela)    REFERENCES telas(id_tela),
    CONSTRAINT fk_merma_ot      FOREIGN KEY (id_ot)      REFERENCES orden_trabajo(id_ot),
    CONSTRAINT fk_merma_tizador FOREIGN KEY (id_tizador) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB COMMENT='HU04: Merma generada en tizado y corte por orden';

CREATE INDEX idx_merma_tela ON mermas(id_tela);
CREATE INDEX idx_merma_ot   ON mermas(id_ot);

-- ============================================================
-- PERMISOS HU04
-- PROD_MERMA_VER y PROD_MERMA_REG ya existen en HU09
-- INSERT IGNORE: seguro si ya están
-- ============================================================
INSERT IGNORE INTO permisos (codigo, nombre, modulo, descripcion) VALUES
('PROD_MERMA_VER', 'Ver mermas',      'Producción', 'HU04: Consultar porcentajes de merma'),
('PROD_MERMA_REG', 'Registrar merma', 'Producción', 'HU04: Ingresar merma por tejido');

-- ADMINISTRADOR (id_rol=1)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_MERMA_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_MERMA_REG';

-- JEFE_PRODUCCION (id_rol=3): solo ver
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos WHERE codigo = 'PROD_MERMA_VER';

-- TIZADOR (id_rol=4): ver y registrar
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos WHERE codigo = 'PROD_MERMA_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos WHERE codigo = 'PROD_MERMA_REG';

-- ============================================================
-- DATO DE PRUEBA (sobre tela y OT existentes)
-- ============================================================
INSERT INTO mermas (id_tela, id_ot, id_tizador, fase,
    peso_utilizado_kg, peso_merma_kg, observaciones)
SELECT
    t.id_tela,
    t.id_ot,
    (SELECT id_usuario FROM usuarios WHERE username='admin' LIMIT 1),
    'TIZADO',
    10.000,
    0.850,
    'Merma de prueba en fase de tizado - Jersey algodón elastano'
FROM telas t
WHERE t.codigo_tela = 'TELA-2026-0002'
  AND NOT EXISTS (SELECT 1 FROM mermas m WHERE m.id_tela = t.id_tela)
LIMIT 1;

-- ============================================================
-- VERIFICACION
-- SELECT m.id_merma, t.codigo_tela, ot.codigo_ot,
--        m.fase, m.peso_utilizado_kg, m.peso_merma_kg,
--        m.porcentaje_merma,
--        CONCAT(u.nombre,' ',u.apellido) AS tizador
-- FROM mermas m
-- JOIN telas t ON m.id_tela = t.id_tela
-- JOIN orden_trabajo ot ON m.id_ot = ot.id_ot
-- JOIN usuarios u ON m.id_tizador = u.id_usuario;
-- ============================================================
