-- 1. Tabla para el Catálogo Maestro de Telas y Materiales (HU10)
CREATE TABLE IF NOT EXISTS catalogo_telas (
                                              id_catalogo INT AUTO_INCREMENT PRIMARY KEY,
                                              nombre VARCHAR(150) NOT NULL,
                                              composicion VARCHAR(150) NOT NULL,
                                              proveedor_base VARCHAR(150),
                                              requiere_reposo TINYINT(1) DEFAULT 0,
                                              fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla para el Catálogo de Modelos / Corsets (HU12)
CREATE TABLE IF NOT EXISTS modelos_prenda (
                                              id_modelo INT AUTO_INCREMENT PRIMARY KEY,
                                              nombre VARCHAR(150) NOT NULL,
                                              temporada VARCHAR(100),
                                              fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla para el Desglose de Piezas de cada Modelo (Sub-entidad HU12)
CREATE TABLE IF NOT EXISTS piezas_modelo (
                                             id_pieza INT AUTO_INCREMENT PRIMARY KEY,
                                             id_modelo INT NOT NULL,
                                             nombre_pieza VARCHAR(150) NOT NULL,
                                             cantidad INT NOT NULL DEFAULT 1,
                                             CONSTRAINT fk_pieza_modelo
                                                 FOREIGN KEY (id_modelo)
                                                     REFERENCES modelos_prenda(id_modelo)
                                                     ON DELETE CASCADE
);
