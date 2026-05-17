-- ============================================================
-- HU13: Creación de Orden de Trabajo (OT)
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x)
-- Ejecutar DESPUÉS de schema.sql y HU09_gestion_perfiles.sql
-- ============================================================

USE textil_db;

-- ============================================================
-- NOTA: La tabla orden_trabajo ya fue creada en schema.sql
-- con la siguiente estructura:
--
-- CREATE TABLE IF NOT EXISTS orden_trabajo (
--     id_ot           INT AUTO_INCREMENT PRIMARY KEY,
--     codigo_ot       VARCHAR(20)  NOT NULL UNIQUE,  -- Ej: OT-2026-0001
--     cliente         VARCHAR(150) NOT NULL,
--     modelo          VARCHAR(100) NOT NULL,
--     cantidad_est    INT          NOT NULL,
--     estado          ENUM('CREADA','EN_PROCESO','FINALIZADA','ANULADA') NOT NULL DEFAULT 'CREADA',
--     id_responsable  INT          NOT NULL,
--     fecha_crea      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT fk_ot_responsable FOREIGN KEY (id_responsable) REFERENCES usuarios(id_usuario)
-- ) ENGINE=InnoDB;
--
-- La tabla telas (HU01) referencia orden_trabajo vía:
--     FOREIGN KEY (id_ot) REFERENCES orden_trabajo(id_ot)
-- Todas las relaciones están activas.
-- ============================================================

-- ------------------------------------------------------------
-- Los permisos PROD_OT_VER y PROD_OT_CREAR ya fueron insertados
-- en HU09_gestion_perfiles.sql. Solo verificamos que están asignados
-- correctamente a los roles que los necesitan.
-- ------------------------------------------------------------

-- Asegurar que JEFE_PRODUCCION (id_rol = 3) tiene PROD_OT_VER y PROD_OT_CREAR
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos
WHERE codigo IN ('PROD_OT_VER', 'PROD_OT_CREAR');

-- Asegurar que ADMINISTRADOR (id_rol = 1) también los tiene
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos
WHERE codigo IN ('PROD_OT_VER', 'PROD_OT_CREAR');

-- SUPERVISOR (id_rol = 5) puede ver OTs pero no crearlas
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 5, id_permiso FROM permisos
WHERE codigo = 'PROD_OT_VER';

-- JEFE_ALMACEN (id_rol = 2) puede ver OTs para asociar telas (HU01)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 2, id_permiso FROM permisos
WHERE codigo = 'PROD_OT_VER';

-- TIZADOR (id_rol = 4) puede ver OTs
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos
WHERE codigo = 'PROD_OT_VER';

-- MAQUINISTA (id_rol = 6) puede ver OTs
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 6, id_permiso FROM permisos
WHERE codigo = 'PROD_OT_VER';

-- ------------------------------------------------------------
-- Datos de prueba: algunas OTs de ejemplo para visualizar el módulo
-- (Solo insertar si la tabla está vacía)
-- ------------------------------------------------------------
INSERT INTO orden_trabajo (codigo_ot, cliente, modelo, cantidad_est, estado, id_responsable)
SELECT 'OT-2026-0001', 'Confecciones Andes S.A.C.', 'Corset Verano 2026', 300, 'EN_PROCESO',
       (SELECT id_usuario FROM usuarios WHERE username = 'jefe_prod' LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0001');

INSERT INTO orden_trabajo (codigo_ot, cliente, modelo, cantidad_est, estado, id_responsable)
SELECT 'OT-2026-0002', 'Moda Lima Export', 'Corset Clásico Talla M', 150, 'CREADA',
       (SELECT id_usuario FROM usuarios WHERE username = 'jefe_prod' LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0002');

INSERT INTO orden_trabajo (codigo_ot, cliente, modelo, cantidad_est, estado, id_responsable)
SELECT 'OT-2026-0003', 'Boutique Elegance', 'Corset Noche Premium', 80, 'FINALIZADA',
       (SELECT id_usuario FROM usuarios WHERE username = 'admin' LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0003');

-- ============================================================
-- VERIFICACIÓN: consulta para validar que todo está correcto
-- ============================================================
-- SELECT ot.codigo_ot, ot.cliente, ot.modelo, ot.cantidad_est, ot.estado,
--        CONCAT(u.nombre, ' ', u.apellido) AS responsable, ot.fecha_crea
-- FROM orden_trabajo ot
-- JOIN usuarios u ON ot.id_responsable = u.id_usuario
-- ORDER BY ot.fecha_crea DESC;
