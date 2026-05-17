package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ModeloPrendaDAO {

    public List<ModeloPrenda> listarTodos() {
        List<ModeloPrenda> lista = new ArrayList<>();
        String sql = """
        SELECT m.id_modelo, m.nombre, m.temporada, COUNT(DISTINCT p.nombre_pieza) AS total_piezas
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

    public boolean insertarTransaccional(ModeloPrenda m) {
        String sqlModelo = "INSERT INTO modelos_prenda (nombre, temporada) VALUES (?, ?)";
        String sqlPieza = "INSERT INTO piezas_modelo (id_modelo, nombre_pieza, cantidad) VALUES (?, ?, ?)";

        try (Connection cn = ConexionDB.obtenerConexion()) {
            cn.setAutoCommit(false);
            try (PreparedStatement ps = cn.prepareStatement(sqlModelo, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, m.getNombre());
                ps.setString(2, m.getTemporada());
                ps.executeUpdate();

                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        int idModelo = rs.getInt(1);
                        try (PreparedStatement psPieza = cn.prepareStatement(sqlPieza)) {
                            for (PiezaModelo p : m.getPiezas()) {
                                psPieza.setInt(1, idModelo);
                                psPieza.setString(2, p.getNombrePieza());
                                psPieza.setInt(3, p.getCantidad());
                                psPieza.addBatch();
                            }
                            psPieza.executeBatch();
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
            throw new RuntimeException("Error en transacción de modelo y piezas", e);
        }
    }

    public boolean actualizarTransaccional(ModeloPrenda m) {
        String sqlModelo = "UPDATE modelos_prenda SET nombre=?, temporada=? WHERE id_modelo=?";
        String sqlDelPiezas = "DELETE FROM piezas_modelo WHERE id_modelo=?";
        String sqlInsPieza = "INSERT INTO piezas_modelo (id_modelo, nombre_pieza, cantidad) VALUES (?, ?, ?)";
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
                // 2. Limpiar piezas anteriores (se reemplazarán)
                try (PreparedStatement ps = cn.prepareStatement(sqlDelPiezas)) {
                    ps.setInt(1, m.getIdModelo());
                    ps.executeUpdate();
                }
                // 3. Insertar piezas nuevas
                try (PreparedStatement ps = cn.prepareStatement(sqlInsPieza)) {
                    for (PiezaModelo p : m.getPiezas()) {
                        ps.setInt(1, m.getIdModelo());
                        ps.setString(2, p.getNombrePieza());
                        ps.setInt(3, p.getCantidad());
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                cn.commit();
                return true;
            } catch (SQLException e) {
                cn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error en actualización transaccional", e);
        }
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
}