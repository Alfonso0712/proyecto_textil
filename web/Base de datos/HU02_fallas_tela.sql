-- ============================================================
-- HU02: Mapeo Digital de Imperfecciones y Fallas en la Tela
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x / TiDB Cloud)
-- Ejecutar DESPUÉS de: schema.sql, HU09_gestion_perfiles.sql, HU01.sql
-- ============================================================

USE textil_db;

-- ------------------------------------------------------------
-- TABLA: fallas_tela
-- CUS 2.1 Mapear Imperfecciones
-- CUS 2.2 Categorizar Fallas (Mancha / Hueco / Defecto de Tejido)
-- CUS 2.3 Activar Alerta Visual de Áreas No Aptas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fallas_tela (
    id_falla        INT AUTO_INCREMENT PRIMARY KEY,
    id_tela         INT          NOT NULL,
    id_tizador      INT          NOT NULL,
    tipo_falla      ENUM('MANCHA','HUECO','DEFECTO_TEJIDO') NOT NULL,
    posicion_rollo  INT          NOT NULL,
    posicion_metro  DECIMAL(6,2) NOT NULL,
    ancho_cm        DECIMAL(6,2) NULL,
    largo_cm        DECIMAL(6,2) NULL,
    descripcion     TEXT         NULL,
    es_area_no_apta TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_registro  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_falla_tela    FOREIGN KEY (id_tela)    REFERENCES telas(id_tela),
    CONSTRAINT fk_falla_tizador FOREIGN KEY (id_tizador) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE INDEX idx_falla_tela ON fallas_tela(id_tela);
CREATE INDEX idx_falla_tipo ON fallas_tela(tipo_falla);

-- ============================================================
-- PERMISOS HU02
-- INSERT IGNORE: seguro aunque HU09 ya los haya creado
-- ============================================================
INSERT IGNORE INTO permisos (codigo, nombre, modulo, descripcion) VALUES
('PROD_FALLAS_VER', 'Ver mapa de fallas', 'Producción', 'HU02: Consultar imperfecciones'),
('PROD_FALLAS_REG', 'Registrar fallas',   'Producción', 'HU02: Mapear imperfecciones en tela');

-- ADMINISTRADOR (id_rol=1)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_FALLAS_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_FALLAS_REG';

-- JEFE_PRODUCCION (id_rol=3): solo ver
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos WHERE codigo = 'PROD_FALLAS_VER';

-- TIZADOR (id_rol=4): ver y registrar
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos WHERE codigo = 'PROD_FALLAS_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos WHERE codigo = 'PROD_FALLAS_REG';

-- ============================================================
-- DATO DE PRUEBA (sobre tela existente TELA-2026-0002)
-- ============================================================
INSERT INTO fallas_tela (id_tela, id_tizador, tipo_falla, posicion_rollo,
    posicion_metro, ancho_cm, largo_cm, descripcion, es_area_no_apta)
SELECT t.id_tela,
    (SELECT id_usuario FROM usuarios WHERE username='admin' LIMIT 1),
    'MANCHA', 1, 2.50, 5.00, 3.00,
    'Mancha de aceite en borde derecho del rollo 1', 1
FROM telas t WHERE t.codigo_tela='TELA-2026-0002'
  AND NOT EXISTS (SELECT 1 FROM fallas_tela f WHERE f.id_tela=t.id_tela)
LIMIT 1;

INSERT INTO fallas_tela (id_tela, id_tizador, tipo_falla, posicion_rollo,
    posicion_metro, ancho_cm, largo_cm, descripcion, es_area_no_apta)
SELECT t.id_tela,
    (SELECT id_usuario FROM usuarios WHERE username='admin' LIMIT 1),
    'HUECO', 1, 7.80, 2.00, 2.00,
    'Hueco pequeño en zona central', 1
FROM telas t WHERE t.codigo_tela='TELA-2026-0002'
LIMIT 1;
