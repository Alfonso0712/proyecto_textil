-- Ejecuta este script en textil_db

-- Tabla de especialidades técnicas
CREATE TABLE IF NOT EXISTS especialidades (
    id_especialidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL UNIQUE,
    descripcion    VARCHAR(200)
) ENGINE=InnoDB;

-- Poblar especialidades típicas
INSERT INTO especialidades (nombre, descripcion) VALUES
    ('ORILLADO',  'Acabado de bordes'),
    ('REMALLADO', 'Unión de piezas con remalladora'),
    ('PESPUNTADO','Costura decorativa y refuerzo'),
    ('CORTE',     'Corte de telas'),
    ('PLANCHADO', 'Planchado y presentación final');

-- Relación usuario - especialidad
CREATE TABLE IF NOT EXISTS usuario_especialidad (
    id_usuario      INT NOT NULL,
    id_especialidad INT NOT NULL,
    PRIMARY KEY (id_usuario, id_especialidad),
    CONSTRAINT fk_ue_usuario      FOREIGN KEY (id_usuario)      REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_ue_especialidad FOREIGN KEY (id_especialidad) REFERENCES especialidades(id_especialidad) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Permisos para HU11
INSERT INTO permisos (codigo, nombre, modulo, descripcion) VALUES
('PROD_MAQUINISTAS_VER',    'Ver maquinistas',       'Producción', 'Listar personal de maquila y sus especialidades'),
('PROD_MAQUINISTAS_GESTION','Gestionar maquinistas',  'Producción', 'Crear, editar y desactivar maquinistas');

-- Asignar a SUPERVISOR (id_rol = 5)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 5, id_permiso FROM permisos
WHERE codigo IN ('PROD_MAQUINISTAS_VER', 'PROD_MAQUINISTAS_GESTION');

-- Si quieres que el admin también los vea (ya tiene todos, pero no sobra)
-- Opcional: INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
-- SELECT 1, id_permiso FROM permisos WHERE codigo IN (...);
-- Dar los permisos de maquinistas al rol ADMINISTRADOR (id_rol = 1)
INSERT IGNORE INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso
FROM permisos
WHERE codigo IN ('PROD_MAQUINISTAS_VER', 'PROD_MAQUINISTAS_GESTION');