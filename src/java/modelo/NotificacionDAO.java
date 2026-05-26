package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class NotificacionDAO {

    public void insertar(Notificacion n) {
        String sql = "INSERT INTO notificaciones (titulo, mensaje, tipo, id_referencia, para_rol) VALUES (?,?,?,?,?)";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, n.getTitulo());
            ps.setString(2, n.getMensaje());
            ps.setString(3, n.getTipo());
            if (n.getIdReferencia() != null) ps.setInt(4, n.getIdReferencia());
            else ps.setNull(4, Types.INTEGER);
            ps.setString(5, n.getParaRol());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar notificación", e);
        }
    }

    public List<Notificacion> listarNoLeidasPorRol(String nombreRol) {
        List<Notificacion> lista = new ArrayList<>();
        // Usamos LIKE para que encuentre el rol sin importar dónde esté en la cadena
        String sql = "SELECT * FROM notificaciones WHERE para_rol LIKE CONCAT('%', ?, '%') AND leida = 0 ORDER BY fecha_creacion DESC";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombreRol);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        return lista;
    }

    public List<Notificacion> listarTodasPorRol(String nombreRol, int limite) {
        List<Notificacion> lista = new ArrayList<>();
        String sql = "SELECT * FROM notificaciones WHERE para_rol LIKE CONCAT('%', ?, '%') ORDER BY fecha_creacion DESC LIMIT ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombreRol);
            ps.setInt(2, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
        return lista;
    }
    
    public void marcarComoLeida(int idNotificacion) {
        String sql = "UPDATE notificaciones SET leida = 1 WHERE id_notificacion = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idNotificacion);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private Notificacion mapear(ResultSet rs) throws SQLException {
        Notificacion n = new Notificacion();
        n.setIdNotificacion(rs.getInt("id_notificacion"));
        n.setTitulo(rs.getString("titulo"));
        n.setMensaje(rs.getString("mensaje"));
        n.setTipo(rs.getString("tipo"));
        n.setIdReferencia(rs.getInt("id_referencia"));
        n.setParaRol(rs.getString("para_rol"));
        n.setLeida(rs.getBoolean("leida"));
        n.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
        return n;
    }
}