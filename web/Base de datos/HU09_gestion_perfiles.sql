-- ============================================================
-- HU09: Gestión de Perfiles y Permisos
-- Sistema de Control de Producción Textil
-- Base de datos: textil_db (MySQL 8.x)
-- Ejecutar DESPUÉS del schema.sql base
-- ============================================================

USE textil_db;

-- ------------------------------------------------------------
-- TABLA: permisos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS permisos (
    id_permiso    INT AUTO_INCREMENT PRIMARY KEY,
    codigo        VARCHAR(60)  NOT NULL UNIQUE  COMMENT 'Clave técnica: MODULO_ACCION',
    nombre        VARCHAR(100) NOT NULL          COMMENT 'Nombre legible para UI',
    modulo        VARCHAR(50)  NOT NULL          COMMENT 'Agrupación de menú',
    descripcion   VARCHAR(200) NOT NULL
) ENGINE=InnoDB;

INSERT INTO permisos (codigo, nombre, modulo, descripcion) VALUES
-- SEGURIDAD
('SEG_USUARIOS_VER',    'Ver usuarios',           'Seguridad',   'Listar y consultar cuentas de usuario'),
('SEG_USUARIOS_CREAR',  'Crear usuarios',          'Seguridad',   'Registrar nuevas cuentas'),
('SEG_USUARIOS_EDITAR', 'Editar usuarios',         'Seguridad',   'Modificar datos y rol de un usuario'),
('SEG_USUARIOS_DEACT',  'Desactivar usuarios',     'Seguridad',   'Desactivar cuentas sin borrarlas'),
('SEG_ROLES_VER',       'Ver roles y permisos',    'Seguridad',   'Consultar la matriz de permisos'),
-- CATÁLOGOS
('CAT_TELAS_VER',       'Ver catálogo de telas',   'Catálogos',   'Consultar telas y materiales'),
('CAT_TELAS_EDIT',      'Gestionar telas',         'Catálogos',   'Crear y editar telas/materiales'),
('CAT_MODELOS_VER',     'Ver catálogo de modelos', 'Catálogos',   'Consultar fichas técnicas'),
('CAT_MODELOS_EDIT',    'Gestionar modelos',       'Catálogos',   'Crear y editar modelos de corset'),
-- ALMACÉN
('ALM_TELA_VER',        'Ver recepciones',         'Almacén',     'Ver registros de tela recibida'),
('ALM_TELA_REGISTRAR',  'Registrar tela',          'Almacén',     'HU01: Ingresar recepción de tela'),
-- PRODUCCIÓN
('PROD_OT_VER',         'Ver órdenes de trabajo',  'Producción',  'Consultar OTs'),
('PROD_OT_CREAR',       'Crear orden de trabajo',  'Producción',  'HU13: Generar nueva OT'),
('PROD_REPOSO_VER',     'Ver tiempos de reposo',   'Producción',  'HU03: Consultar cronómetros'),
('PROD_REPOSO_GESTION', 'Gestionar tiempos',       'Producción',  'HU03: Iniciar/monitorear reposo'),
('PROD_MERMA_VER',      'Ver mermas',              'Producción',  'HU04: Consultar porcentajes'),
('PROD_MERMA_REG',      'Registrar merma',         'Producción',  'HU04: Ingresar merma por tejido'),
('PROD_CARGAS_VER',     'Ver cargas de trabajo',   'Producción',  'HU05: Consultar asignaciones'),
('PROD_CARGAS_ASIG',    'Asignar cargas',          'Producción',  'HU05: Distribuir piezas a maquinistas'),
('PROD_FALLAS_VER',     'Ver mapa de fallas',      'Producción',  'HU02: Consultar imperfecciones'),
('PROD_FALLAS_REG',     'Registrar fallas',        'Producción',  'HU02: Mapear imperfecciones en tela'),
-- CALIDAD
('CAL_DEFECTOS_VER',    'Ver defectos',            'Calidad',     'HU06: Consultar registro de defectos'),
('CAL_DEFECTOS_REG',    'Registrar defectos',      'Calidad',     'HU06: Ingresar defectos y reprocesos'),
-- DESPACHO
('DES_CONCIL_VER',      'Ver conciliaciones',      'Despacho',    'HU07: Consultar despachos'),
('DES_CONCIL_REG',      'Registrar despacho',      'Despacho',    'HU07: Conciliar inventario y generar nota'),
-- DASHBOARD / REPORTES
('RPT_DASHBOARD',       'Ver dashboard',           'Dashboard',   'HU14: Visualizar eficiencia de taller'),
('RPT_MERMAS_CALIDAD',  'Reporte mermas/calidad',  'Reportes',    'HU15: Exportar reportes históricos');

-- ------------------------------------------------------------
-- TABLA: rol_permiso
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rol_permiso (
    id_rol_permiso INT AUTO_INCREMENT PRIMARY KEY,
    id_rol         INT NOT NULL,
    id_permiso     INT NOT NULL,
    UNIQUE KEY uq_rol_permiso (id_rol, id_permiso),
    CONSTRAINT fk_rp_rol     FOREIGN KEY (id_rol)     REFERENCES roles(id_rol),
    CONSTRAINT fk_rp_permiso FOREIGN KEY (id_permiso) REFERENCES permisos(id_permiso)
) ENGINE=InnoDB;

-- ADMINISTRADOR (id_rol = 1): TODOS los permisos
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos;

-- JEFE DE ALMACÉN (id_rol = 2)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 2, id_permiso FROM permisos
WHERE codigo IN (
    'ALM_TELA_VER', 'ALM_TELA_REGISTRAR',
    'PROD_OT_VER', 'CAT_TELAS_VER', 'RPT_DASHBOARD'
);

-- JEFE DE PRODUCCIÓN (id_rol = 3)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos
WHERE codigo IN (
    'PROD_OT_VER', 'PROD_OT_CREAR',
    'PROD_REPOSO_VER', 'PROD_REPOSO_GESTION',
    'PROD_MERMA_VER', 'CAT_TELAS_VER', 'CAT_MODELOS_VER',
    'RPT_DASHBOARD', 'RPT_MERMAS_CALIDAD'
);

-- TIZADOR (id_rol = 4)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos
WHERE codigo IN (
    'PROD_OT_VER', 'PROD_FALLAS_VER', 'PROD_FALLAS_REG',
    'PROD_REPOSO_VER', 'PROD_REPOSO_GESTION',
    'PROD_MERMA_VER', 'PROD_MERMA_REG',
    'CAT_TELAS_VER', 'RPT_DASHBOARD'
);

-- SUPERVISOR (id_rol = 5)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 5, id_permiso FROM permisos
WHERE codigo IN (
    'PROD_OT_VER', 'PROD_CARGAS_VER', 'PROD_CARGAS_ASIG',
    'CAL_DEFECTOS_VER', 'CAL_DEFECTOS_REG',
    'DES_CONCIL_VER', 'DES_CONCIL_REG',
    'RPT_DASHBOARD', 'RPT_MERMAS_CALIDAD'
);

-- MAQUINISTA (id_rol = 6)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 6, id_permiso FROM permisos
WHERE codigo IN (
    'PROD_OT_VER', 'PROD_CARGAS_VER', 'RPT_DASHBOARD'
);

-- ------------------------------------------------------------
-- TABLA: intentos_login
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS intentos_login (
    id_intento  INT AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL,
    ip_origen   VARCHAR(45)  NOT NULL,
    exitoso     TINYINT(1)   NOT NULL DEFAULT 0,
    fecha       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_il_username (username),
    INDEX idx_il_fecha    (fecha)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLA: sesiones_activas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sesiones_activas (
    id_sesion    INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario   INT         NOT NULL,
    token        VARCHAR(64) NOT NULL UNIQUE,
    ip_origen    VARCHAR(45) NOT NULL,
    fecha_inicio TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin    TIMESTAMP   NULL,
    activa       TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- VISTA: v_usuario_permisos
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_usuario_permisos AS
SELECT
    u.id_usuario, u.username, u.nombre, u.apellido,
    r.id_rol, r.nombre_rol,
    p.codigo  AS codigo_permiso,
    p.nombre  AS nombre_permiso,
    p.modulo
FROM usuarios u
JOIN roles       r  ON u.id_rol     = r.id_rol
JOIN rol_permiso rp ON r.id_rol     = rp.id_rol
JOIN permisos    p  ON rp.id_permiso = p.id_permiso
WHERE u.activo = 1;

-- ============================================================
-- Usuarios de prueba
-- CONTRASEÑA = USERNAME (BCrypt cost=12, verificado)
--   admin       / admin
--   almacen1    / almacen1
--   jefe_prod   / jefe_prod
--   tizador1    / tizador1
--   supervisor1 / supervisor1
--   maquinista1 / maquinista1
-- ============================================================
INSERT IGNORE INTO usuarios (username, password, nombre, apellido, email, id_rol) VALUES
('almacen1',
 '$2a$12$BkOCFAhWsdBdOy3nfOgunOmsNHpEM5q1miE3636jwFLW51BkIuhiG',
 'Carlos', 'Quispe', 'almacen@textil.pe', 2),
('jefe_prod',
 '$2a$12$3cos2abLNFqexDCCJL/C/Ot9BDuS13syDFarBBzytmBKvDHMipKZG',
 'Maria', 'Torres', 'produccion@textil.pe', 3),
('tizador1',
 '$2a$12$2d7gkvPuZ9t6LjIJOBhJie17zn9k/cwCereBuLzrKZ9RgqIPAyb8q',
 'Juan', 'Mendoza', 'tizador@textil.pe', 4),
('supervisor1',
 '$2a$12$UZZx4Hm997o6j6kasiD/oO.AZnTs6SJNgwJZS8XdMTST8.aC9v6Zu',
 'Rosa', 'Huanca', 'supervisor@textil.pe', 5),
('maquinista1',
 '$2a$12$BDmVKIi07P2jKz8BHJIuz.LFthSkSbCkTiEiyXNPrJAlMqEqB2mSe',
 'Pedro', 'Sullca', 'maquinista@textil.pe', 6);
