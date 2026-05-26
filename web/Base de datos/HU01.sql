-- ============================================================
-- HU01: Registro y Control de Calidad de Tela Recibida
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x)
-- Ejecutar DESPUÉS de: schema.sql, HU09_gestion_perfiles.sql, HU13.sql
-- ============================================================

USE textil_db;

-- ============================================================
-- NOTA: La tabla telas ya fue creada en schema.sql
-- con la siguiente estructura y relaciones:
--
--   telas.id_ot          → orden_trabajo(id_ot)   [FK activa]
--   telas.id_registrador → usuarios(id_usuario)   [FK activa]
--
-- No se recrea aquí para evitar duplicados.
-- ============================================================

-- ------------------------------------------------------------
-- TABLA: fotos_tela
-- CUS 1.4: Cargar Evidencia Fotográfica
-- Relación: una tela puede tener MUCHAS fotos (1:N)
-- Relacionada con: telas(id_tela)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fotos_tela (
    id_foto      INT AUTO_INCREMENT PRIMARY KEY,
    id_tela      INT           NOT NULL COMMENT 'Tela a la que pertenece la foto',
    nombre_archivo VARCHAR(255) NOT NULL COMMENT 'Nombre del archivo guardado en disco',
    ruta_relativa  VARCHAR(500) NOT NULL COMMENT 'Ruta relativa desde el contexto web',
    fecha_subida   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_foto_tela FOREIGN KEY (id_tela)
        REFERENCES telas(id_tela)
        ON DELETE CASCADE  -- Si se borra la tela, se borran sus fotos
) ENGINE=InnoDB;

CREATE INDEX idx_foto_tela ON fotos_tela(id_tela);

-- ============================================================
-- PERMISOS HU01 (si no existen ya los inserta)
-- Roles que pueden VER el inventario de telas:
--   ADMINISTRADOR (1), JEFE_ALMACEN (2), JEFE_PRODUCCION (3),
--   SUPERVISOR (5)
-- Roles que pueden REGISTRAR tela:
--   ADMINISTRADOR (1), JEFE_ALMACEN (2)
-- ============================================================

-- ALM_TELA_VER para ADMINISTRADOR
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_VER';

-- ALM_TELA_VER para JEFE_ALMACEN
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 2, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_VER';

-- ALM_TELA_REGISTRAR para ADMINISTRADOR
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_REGISTRAR';

-- ALM_TELA_REGISTRAR para JEFE_ALMACEN
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 2, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_REGISTRAR';

-- ALM_TELA_VER para JEFE_PRODUCCION (puede ver telas asociadas a sus OTs)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_VER';

-- ALM_TELA_VER para SUPERVISOR
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 5, id_permiso FROM permisos WHERE codigo = 'ALM_TELA_VER';

-- ============================================================
-- DATOS DE PRUEBA
-- Inserta telas de ejemplo vinculadas a las OTs de HU13.sql
-- Solo si la tabla telas está vacía
-- ============================================================
INSERT INTO telas (
    id_ot, id_registrador, codigo_tela, origen, proveedor,
    peso_guia, peso_real, tipo_tejido, color, num_rollos,
    observaciones, estado_calidad, requiere_reposo
)
SELECT
    (SELECT id_ot FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0001' LIMIT 1),
    (SELECT id_usuario FROM usuarios WHERE username = 'almacen1' LIMIT 1),
    'TELA-2026-001',
    'CLIENTE',
    'Textiles Andes S.A.C.',
    120.500,
    119.800,
    'Elástico 4 vías',
    'Negro',
    3,
    'Material en buen estado. Embalaje íntegro. Se detecta leve diferencia de peso (-0.700 kg), dentro del rango aceptable del 1%. Sin imperfecciones visibles en inspección inicial.',
    'ACEPTADO',
    0
WHERE NOT EXISTS (SELECT 1 FROM telas WHERE codigo_tela = 'TELA-2026-001')
  AND EXISTS (SELECT 1 FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0001')
  AND EXISTS (SELECT 1 FROM usuarios WHERE username = 'almacen1');

INSERT INTO telas (
    id_ot, id_registrador, codigo_tela, origen, proveedor,
    peso_guia, peso_real, tipo_tejido, color, num_rollos,
    observaciones, estado_calidad, requiere_reposo
)
SELECT
    (SELECT id_ot FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0002' LIMIT 1),
    (SELECT id_usuario FROM usuarios WHERE username = 'almacen1' LIMIT 1),
    'TELA-2026-002',
    'TALLER',
    'Importaciones Lima Textil E.I.R.L.',
    85.000,
    92.300,
    'Jersey algodón elastano',
    'Blanco hueso',
    2,
    'ALERTA: diferencia de peso +7.300 kg (8.6% sobre la guía). Se solicita verificación urgente con el proveedor. Material con alta elasticidad, requiere reposo antes del corte.',
    'OBSERVADO',
    1
WHERE NOT EXISTS (SELECT 1 FROM telas WHERE codigo_tela = 'TELA-2026-002')
  AND EXISTS (SELECT 1 FROM orden_trabajo WHERE codigo_ot = 'OT-2026-0002')
  AND EXISTS (SELECT 1 FROM usuarios WHERE username = 'almacen1');
ALTER TABLE telas
ADD COLUMN id_catalogo_tela INT NULL;

ALTER TABLE telas
ADD CONSTRAINT fk_tela_catalogo
    FOREIGN KEY (id_catalogo_tela) REFERENCES catalogo_telas(id_catalogo)
    ON DELETE SET NULL ON UPDATE CASCADE;
-- ============================================================
-- VERIFICACIÓN: ejecutar para confirmar que todo está correcto
-- ============================================================
-- SELECT t.codigo_tela, ot.codigo_ot, t.origen, t.peso_guia, t.peso_real,
--        t.diferencia_peso, t.estado_calidad, t.requiere_reposo,
--        CONCAT(u.nombre,' ',u.apellido) AS registrador
-- FROM telas t
-- JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
-- JOIN usuarios u ON t.id_registrador = u.id_usuario
-- ORDER BY t.fecha_ingreso DESC;
--
-- SELECT ft.nombre_archivo, ft.ruta_relativa, ft.fecha_subida,
--        t.codigo_tela
-- FROM fotos_tela ft
-- JOIN telas t ON ft.id_tela = t.id_tela;
