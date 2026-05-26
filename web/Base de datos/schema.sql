-- ============================================================
-- Sistema de Control de Producción Textil
-- Script SQL - Iteración 1 (HU08, HU09, HU01)
-- Base de datos: MySQL 8.x
-- ============================================================

CREATE DATABASE IF NOT EXISTS textil_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE textil_db;

-- ------------------------------------------------------------
-- TABLA: roles
-- HU09: Gestión de Perfiles y Permisos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id_rol      INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol  VARCHAR(50)  NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL
) ENGINE=InnoDB;

INSERT INTO roles (nombre_rol, descripcion) VALUES
    ('ADMINISTRADOR',  'Acceso total al sistema, gestión de usuarios y catálogos'),
    ('JEFE_ALMACEN',   'Registro y control de tela recibida'),
    ('JEFE_PRODUCCION','Creación y monitoreo de órdenes de trabajo'),
    ('TIZADOR',        'Mapeo de imperfecciones, tiempos de reposo y mermas'),
    ('SUPERVISOR',     'Distribución de cargas, control de defectos y despacho'),
    ('MAQUINISTA',     'Consulta de tareas asignadas y registro de avance');

-- ------------------------------------------------------------
-- TABLA: usuarios
-- HU08: Autenticación | HU09: Gestión de Perfiles
-- Contraseñas cifradas con BCrypt cost=12
-- CONTRASEÑA DE CADA USUARIO = SU PROPIO USERNAME
-- Ejemplo: admin/admin, almacen1/almacen1, etc.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario  INT AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL COMMENT 'BCrypt hash',
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    id_rol      INT          NOT NULL,
    activo      TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '1=activo, 0=desactivado',
    fecha_crea  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_mod   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
) ENGINE=InnoDB;

-- Usuario administrador por defecto
-- Contraseña: admin  (BCrypt cost=12, verificado)
INSERT INTO usuarios (username, password, nombre, apellido, email, id_rol) VALUES
    ('admin',
     '$2a$12$9JhTiBR16hyrUmtKEZhFEe5ZjC0Loa6FtkxUM.Zqc4VGfXEmVusgi',
     'Administrador', 'Sistema', 'admin@textil.pe', 1);

-- ------------------------------------------------------------
-- TABLA: orden_trabajo
-- HU13 (referenciada desde HU01 para vincular tela a una OT)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orden_trabajo (
    id_ot           INT AUTO_INCREMENT PRIMARY KEY,
    codigo_ot       VARCHAR(20)  NOT NULL UNIQUE COMMENT 'Ej: OT-2026-0001',
    cliente         VARCHAR(150) NOT NULL,
    modelo          VARCHAR(100) NOT NULL,
    cantidad_est    INT          NOT NULL,
    estado          ENUM('CREADA','EN_PROCESO','FINALIZADA','ANULADA') NOT NULL DEFAULT 'CREADA',
    id_responsable  INT          NOT NULL,
    fecha_crea      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ot_responsable FOREIGN KEY (id_responsable) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TABLA: telas
-- HU01: Registro y Control de Calidad de Tela Recibida
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS telas (
    id_tela         INT AUTO_INCREMENT PRIMARY KEY,
    id_ot           INT            NOT NULL,
    id_registrador  INT            NOT NULL COMMENT 'Jefe de almacén que registra',
    codigo_tela     VARCHAR(30)    NOT NULL UNIQUE,
    origen          ENUM('CLIENTE','TALLER') NOT NULL COMMENT 'Quién provee la tela',
    proveedor       VARCHAR(150)   NULL      COMMENT 'Razón social o nombre',
    peso_guia       DECIMAL(10,3)  NOT NULL  COMMENT 'Peso en kg según guía de remisión',
    peso_real       DECIMAL(10,3)  NOT NULL  COMMENT 'Peso real medido al recibirlo',
    diferencia_peso DECIMAL(10,3)  AS (peso_real - peso_guia) STORED COMMENT 'Calculado automáticamente',
    tipo_tejido     VARCHAR(80)    NULL,
    color           VARCHAR(50)    NULL,
    num_rollos      INT            NOT NULL DEFAULT 1,
    observaciones   TEXT           NOT NULL COMMENT 'Campo obligatorio (CA2 HU01)',
    estado_calidad  ENUM('ACEPTADO','OBSERVADO','RECHAZADO') NOT NULL DEFAULT 'OBSERVADO',
    requiere_reposo TINYINT(1)     NOT NULL DEFAULT 0,
    fecha_ingreso   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tela_ot          FOREIGN KEY (id_ot)          REFERENCES orden_trabajo(id_ot),
    CONSTRAINT fk_tela_registrador FOREIGN KEY (id_registrador) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE INDEX idx_tela_ot ON telas(id_ot);
