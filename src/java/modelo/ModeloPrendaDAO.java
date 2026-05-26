package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ModeloPrendaDAO {

    public List<ModeloPrenda> listarTodos() {
        List<ModeloPrenda> lista = new ArrayList<>();
        // NUEVA CONSULTA: Agregamos una subconsulta (SELECT COUNT...) para saber si está en uso
        String sql = """
        SELECT m.id_modelo, m.nombre, m.temporada, COUNT(DISTINCT p.nombre_pieza) AS total_piezas,
               (SELECT COUNT(*) FROM orden_trabajo ot WHERE ot.id_modelo = m.id_modelo) > 0 AS en_uso
        FROM modelos_prenda m
        LEFT JOIN piezas_modelo p ON m.id_modelo = p.id_modelo
        GROUP BY m.id_modelo, m.nombre, m.temporada
        ORDER BY m.nombre
        """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ModeloPrenda m = new ModeloPrenda();
                m.setIdModelo(rs.getInt("id_modelo"));
                m.setNombre(rs.getString("nombre"));
                m.setTemporada(rs.getString("temporada"));
                m.setTotalPiezas(rs.getInt("total_piezas"));
                
                // Mapeamos el nuevo campo
                m.setEnUso(rs.getBoolean("en_uso")); 
                
                lista.add(m);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar modelos", e);
        }
        return lista;
    }
    public ModeloPrenda buscarPorId(int id) {
        String sqlM = "SELECT * FROM modelos_prenda WHERE id_modelo = ?";
        String sqlP = "SELECT * FROM piezas_modelo WHERE id_modelo = ?";
        String sqlF = "SELECT id_fase FROM pieza_ruta_fase WHERE id_pieza = ?"; // ← nueva consulta

        try (Connection cn = ConexionDB.obtenerConexion()) {
            ModeloPrenda m = null;
            try (PreparedStatement ps = cn.prepareStatement(sqlM)) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        m = new ModeloPrenda();
                        m.setIdModelo(rs.getInt("id_modelo"));
                        m.setNombre(rs.getString("nombre"));
                        m.setTemporada(rs.getString("temporada"));
                    }
                }
            }
            if (m != null) {
                try (PreparedStatement ps = cn.prepareStatement(sqlP)) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            PiezaModelo p = new PiezaModelo();
                            p.setIdPieza(rs.getInt("id_pieza"));
                            p.setIdModelo(rs.getInt("id_modelo"));
                            p.setNombrePieza(rs.getString("nombre_pieza"));
                            p.setCantidad(rs.getInt("cantidad"));

                            // ── NUEVO: Cargar las fases asignadas a esta pieza ──
                            List<Integer> fases = new ArrayList<>();
                            try (PreparedStatement psF = cn.prepareStatement(sqlF)) {
                                psF.setInt(1, p.getIdPieza());
                                try (ResultSet rsF = psF.executeQuery()) {
                                    while (rsF.next()) {
                                        fases.add(rsF.getInt("id_fase"));
                                    }
                                }
                            }
                            p.setIdFasesAsignadas(fases);

                            m.getPiezas().add(p);
                        }
                    }
                }
            }
            return m;
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar modelo", e);
        }
    }
    /**
     * Verifica si un modelo ya tiene órdenes de trabajo vinculadas (y por ende, cargas de trabajo).
     * Si devuelve TRUE, el modelo está bloqueado y no debe editarse ni eliminarse.
     */
    public boolean estaEnUso(int idModelo) {
        String sql = "SELECT COUNT(*) FROM orden_trabajo WHERE id_modelo = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idModelo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al verificar uso del modelo", e);
        }
    }
    public boolean insertarTransaccional(ModeloPrenda m) {
        String sqlModelo = "INSERT INTO modelos_prenda (nombre, temporada) VALUES (?, ?)";
        String sqlPieza = "INSERT INTO piezas_modelo (id_modelo, nombre_pieza, cantidad) VALUES (?, ?, ?)";
        // 🌟 Nueva sentencia para la tabla intermedia de rutas
        String sqlRuta = "INSERT INTO pieza_ruta_fase (id_pieza, id_fase) VALUES (?, ?)";

        try (Connection cn = ConexionDB.obtenerConexion()) {
            cn.setAutoCommit(false);
            try (PreparedStatement ps = cn.prepareStatement(sqlModelo, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, m.getNombre());
                ps.setString(2, m.getTemporada());
                ps.executeUpdate();

                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        int idModelo = rs.getInt(1);

                        // Preparamos los statements para piezas y rutas
                        try (PreparedStatement psPieza = cn.prepareStatement(sqlPieza, Statement.RETURN_GENERATED_KEYS);
                             PreparedStatement psRuta = cn.prepareStatement(sqlRuta)) {

                            for (PiezaModelo p : m.getPiezas()) {
                                // 1. Insertar Pieza
                                psPieza.setInt(1, idModelo);
                                psPieza.setString(2, p.getNombrePieza());
                                psPieza.setInt(3, p.getCantidad());
                                psPieza.executeUpdate();

                                // 2. Obtener ID de la pieza recién creada
                                try (ResultSet rsPieza = psPieza.getGeneratedKeys()) {
                                    if (rsPieza.next()) {
                                        int idPieza = rsPieza.getInt(1);

                                        // 3. Insertar las fases (Rutas) para esta pieza
                                        if (p.getIdFasesAsignadas() != null) {
                                            for (Integer idFase : p.getIdFasesAsignadas()) {
                                                psRuta.setInt(1, idPieza);
                                                psRuta.setInt(2, idFase);
                                                psRuta.addBatch();
                                            }
                                        }
                                    }
                                }
                            }
                            psRuta.executeBatch(); // Ejecutar todas las inserciones de rutas
                            // --- NUEVO: INSERTAR ENSAMBLAJE AUTOMÁTICAMENTE ---
                            String sqlRutaGlobal = "INSERT INTO pieza_ruta_fase (id_modelo, id_pieza, id_fase) VALUES (?, NULL, 6)";
                            try (PreparedStatement psRutaGlobal = cn.prepareStatement(sqlRutaGlobal)) {
                                psRutaGlobal.setInt(1, idModelo);
                                psRutaGlobal.executeUpdate();
                            }
                            // --------------------------------------------------
                        }
                    }
                }
                cn.commit();
                return true;
            } catch (SQLException e) {
                cn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error en transacción de modelo, piezas y rutas", e);
        }
    }
public void insertarRutaFaseGlobal(int idModelo, int idFase) throws SQLException {
    String sql = "INSERT INTO pieza_ruta_fase (id_modelo, id_pieza, id_fase) VALUES (?, NULL, ?)";
    
    // Aquí es donde obtienes la conexión usando tu clase ConexionDB
    try (Connection cn = ConexionDB.obtenerConexion(); 
         PreparedStatement ps = cn.prepareStatement(sql)) {
        
        ps.setInt(1, idModelo);
        ps.setInt(2, idFase);
        ps.executeUpdate();
        
    } catch (SQLException e) {
        throw e; // Lanza el error para que el Servlet lo maneje
    }
}
    public boolean actualizarTransaccional(ModeloPrenda m) {
        String sqlModelo = "UPDATE modelos_prenda SET nombre=?, temporada=? WHERE id_modelo=?";
        String sqlDelPiezas = "DELETE FROM piezas_modelo WHERE id_modelo=?";
        String sqlDelRutasPiezas = "DELETE prf FROM pieza_ruta_fase prf JOIN piezas_modelo p ON prf.id_pieza = p.id_pieza WHERE p.id_modelo = ?";
        String sqlInsPieza = "INSERT INTO piezas_modelo (id_modelo, nombre_pieza, cantidad) VALUES (?, ?, ?)";
        String sqlInsRuta = "INSERT INTO pieza_ruta_fase (id_pieza, id_fase) VALUES (?, ?)";

        try (Connection cn = ConexionDB.obtenerConexion()) {
            cn.setAutoCommit(false);
            try {
                // 1. Actualizar cabecera
                try (PreparedStatement ps = cn.prepareStatement(sqlModelo)) {
                    ps.setString(1, m.getNombre());
                    ps.setString(2, m.getTemporada());
                    ps.setInt(3, m.getIdModelo());
                    ps.executeUpdate();
                }
                // 2. Eliminar rutas de las piezas antiguas (más eficiente que hacerlo por cada pieza)
                try (PreparedStatement ps = cn.prepareStatement(sqlDelRutasPiezas)) {
                    ps.setInt(1, m.getIdModelo());
                    ps.executeUpdate();
                }
                // 3. Eliminar las piezas antiguas
                try (PreparedStatement ps = cn.prepareStatement(sqlDelPiezas)) {
                    ps.setInt(1, m.getIdModelo());
                    ps.executeUpdate();
                }
                // 4. Insertar nuevas piezas y sus rutas
                try (PreparedStatement psPieza = cn.prepareStatement(sqlInsPieza, Statement.RETURN_GENERATED_KEYS);
                     PreparedStatement psRuta = cn.prepareStatement(sqlInsRuta)) {
                    for (PiezaModelo p : m.getPiezas()) {
                        psPieza.setInt(1, m.getIdModelo());
                        psPieza.setString(2, p.getNombrePieza());
                        psPieza.setInt(3, p.getCantidad());
                        psPieza.executeUpdate();
                        try (ResultSet rs = psPieza.getGeneratedKeys()) {
                            if (rs.next()) {
                                int idPieza = rs.getInt(1);
                                if (p.getIdFasesAsignadas() != null) {
                                    for (Integer idFase : p.getIdFasesAsignadas()) {
                                        psRuta.setInt(1, idPieza);
                                        psRuta.setInt(2, idFase);
                                        psRuta.addBatch();
                                    }
                                }
                            }
                        }
                    }
                    psRuta.executeBatch();
                }
                
                // --- NUEVO: INSERTAR ENSAMBLAJE AUTOMÁTICAMENTE ---
                String sqlRutaGlobal = "INSERT INTO pieza_ruta_fase (id_modelo, id_pieza, id_fase) VALUES (?, NULL, 6)";
                try (PreparedStatement psRutaGlobal = cn.prepareStatement(sqlRutaGlobal)) {
                    psRutaGlobal.setInt(1, m.getIdModelo());
                    psRutaGlobal.executeUpdate();
                }
                // --------------------------------------------------
                
                cn.commit();
                return true;
            } catch (SQLException e) {
                cn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error en actualización transaccional de modelo, piezas y rutas", e);
        }
    }
    // En ModeloPrendaDAO.java
    public List<FaseProduccion> listarFases() {
        List<FaseProduccion> fases = new ArrayList<>();
        String sql = "SELECT id_fase, nombre, orden, descripcion FROM fases_produccion ORDER BY orden";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                FaseProduccion f = new FaseProduccion();
                f.setIdFase(rs.getInt("id_fase"));
                f.setNombre(rs.getString("nombre"));
                f.setOrden(rs.getInt("orden"));
                f.setDescripcion(rs.getString("descripcion"));
                fases.add(f);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar fases de producción", e);
        }
        return fases;
    }
    public boolean eliminar(int id) {
        String sql = "DELETE FROM modelos_prenda WHERE id_modelo = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar modelo", e);
        }
    }
    public boolean existeOrden(int orden) {
        String sql = "SELECT COUNT(*) FROM fases_produccion WHERE orden = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, orden);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    public void insertarFase(String nombre, int orden, String descripcion) {
        String sqlShift = "UPDATE fases_produccion SET orden = orden + 1 WHERE orden >= ?";
        String sqlInsert = "INSERT INTO fases_produccion (nombre, orden, descripcion) VALUES (?, ?, ?)";

        try (Connection cn = ConexionDB.obtenerConexion()) {
            cn.setAutoCommit(false);

            // 1. Desplazar los órdenes
            try (PreparedStatement ps = cn.prepareStatement(sqlShift)) {
                ps.setInt(1, orden);
                ps.executeUpdate();
            }

            // 2. Insertar la nueva fase
            try (PreparedStatement ps = cn.prepareStatement(sqlInsert)) {
                ps.setString(1, nombre);
                ps.setInt(2, orden);
                ps.setString(3, descripcion);
                ps.executeUpdate();
            }

            cn.commit();
        } catch (SQLException e) {
            // Si hay error de duplicado (1062), asignar automáticamente el siguiente orden
            if (e.getErrorCode() == 1062) {
                int nuevoOrden = getMaxOrden() + 1;
                try (Connection cn = ConexionDB.obtenerConexion();
                     PreparedStatement ps = cn.prepareStatement(sqlInsert)) {
                    ps.setString(1, nombre);
                    ps.setInt(2, nuevoOrden);
                    ps.setString(3, descripcion);
                    ps.executeUpdate();
                } catch (SQLException ex) {
                    throw new RuntimeException("Error al insertar fase con orden automático: " + ex.getMessage(), ex);
                }
            } else {
                throw new RuntimeException("Error al insertar fase: " + e.getMessage(), e);
            }
        }
    }

    // Método auxiliar para obtener el máximo orden
    private int getMaxOrden() {
        String sql = "SELECT COALESCE(MAX(orden), 0) FROM fases_produccion";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al obtener máximo orden: " + e.getMessage(), e);
        }
    }
}