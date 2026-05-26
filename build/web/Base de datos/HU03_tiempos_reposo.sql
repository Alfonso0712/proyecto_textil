-- ============================================================
-- HU03: Gestión de Tiempos de Reposo y Corte
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x)
-- Ejecutar DESPUÉS de: schema.sql, HU09_gestion_perfiles.sql, HU01.sql
-- ============================================================

USE textil_db;

-- ------------------------------------------------------------
-- TABLA: tiempos_reposo
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tiempos_reposo (
    id_reposo           INT AUTO_INCREMENT PRIMARY KEY,
    id_tela             INT           NOT NULL,
    id_usuario_inicio   INT           NOT NULL,
    fecha_inicio        DATETIME      NOT NULL,
    duracion_minutos    INT           NOT NULL DEFAULT 60,
    fecha_fin_estimada  DATETIME      AS (DATE_ADD(fecha_inicio, INTERVAL duracion_minutos MINUTE)) STORED,
    fecha_fin_real      DATETIME      NULL,
    estado              ENUM('EN_REPOSO','APTO_CORTE','CANCELADO') NOT NULL DEFAULT 'EN_REPOSO',
    notificacion_enviada TINYINT(1)   NOT NULL DEFAULT 0,
    observaciones       TEXT          NULL,
    fecha_crea          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reposo_tela    FOREIGN KEY (id_tela)           REFERENCES telas(id_tela),
    CONSTRAINT fk_reposo_usuario FOREIGN KEY (id_usuario_inicio) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- ============================================================
-- PERMISOS HU03
-- INSERT IGNORE: seguro aunque HU09 ya se haya ejecutado antes
-- ============================================================

-- 1. Asegurar que los codigos de permiso existan
INSERT IGNORE INTO permisos (codigo, nombre, modulo, descripcion) VALUES
('PROD_REPOSO_VER',     'Ver tiempos de reposo', 'Producción', 'HU03: Consultar cronómetros de reposo'),
('PROD_REPOSO_GESTION', 'Gestionar tiempos',     'Producción', 'HU03: Iniciar/monitorear/finalizar reposo');

-- 2. ADMINISTRADOR (id_rol=1)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_REPOSO_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'PROD_REPOSO_GESTION';

-- 3. JEFE DE PRODUCCION (id_rol=3)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos WHERE codigo = 'PROD_REPOSO_VER';
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos WHERE codigo = 'PROD_REPOSO_GESTION';

-- ============================================================
-- DATO DE PRUEBA (solo si hay tela con requiere_reposo=1)
-- ============================================================
INSERT INTO tiempos_reposo (id_tela, id_usuario_inicio, fecha_inicio, duracion_minutos, estado, observaciones)
SELECT
    t.id_tela,
    (SELECT id_usuario FROM usuarios WHERE username = 'admin' LIMIT 1),
    DATE_SUB(NOW(), INTERVAL 90 MINUTE),
    60,
    'APTO_CORTE',
    'Dato de prueba HU03 - tela Jersey completó reposo.'
FROM telas t
WHERE t.requiere_reposo = 1
  AND NOT EXISTS (SELECT 1 FROM tiempos_reposo tr WHERE tr.id_tela = t.id_tela)
LIMIT 1;

-- ============================================================
-- VERIFICACION
-- SELECT r.nombre_rol, p.codigo
-- FROM rol_permiso rp
-- JOIN roles r ON rp.id_rol = r.id_rol
-- JOIN permisos p ON rp.id_permiso = p.id_permiso
-- WHERE p.codigo IN ('PROD_REPOSO_VER','PROD_REPOSO_GESTION')
-- ORDER BY rp.id_rol;
-- ============================================================
