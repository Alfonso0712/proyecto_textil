package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class HistorialBackupDAO {

    public int insertar(int idUsuario, String nombreArchivo, long tamanio, String estado, String obs) throws SQLException {
        String sql = "INSERT INTO historial_backups (usuario_solicitante, nombre_archivo, tamanio_bytes, estado, observaciones) VALUES (?,?,?,?,?)";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, idUsuario);
            ps.setString(2, nombreArchivo);
            ps.setLong(3, tamanio);
            ps.setString(4, estado);
            ps.setString(5, obs);
            ps.executeUpdate();
            ResultSet rs = ps.getGeneratedKeys();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }
    public boolean eliminar(int idBackup) throws SQLException {
        String sql = "DELETE FROM historial_backups WHERE id_backup = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBackup);
            return ps.executeUpdate() > 0;
        }
    }

    public List<HistorialBackup> listarTodos() throws SQLException {
        String sql = "SELECT h.*, CONCAT(u.nombre,' ',u.apellido) AS nombre_usuario FROM historial_backups h JOIN usuarios u ON h.usuario_solicitante = u.id_usuario ORDER BY h.fecha_solicitud DESC";
        List<HistorialBackup> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                HistorialBackup h = new HistorialBackup();
                h.setIdBackup(rs.getInt("id_backup"));
                h.setFechaSolicitud(rs.getTimestamp("fecha_solicitud"));
                h.setUsuarioSolicitante(rs.getInt("usuario_solicitante"));
                h.setNombreArchivo(rs.getString("nombre_archivo"));
                h.setTamanioBytes(rs.getLong("tamanio_bytes"));
                h.setEstado(rs.getString("estado"));
                h.setObservaciones(rs.getString("observaciones"));
                h.setNombreUsuario(rs.getString("nombre_usuario"));
                lista.add(h);
            }
        }
        return lista;
    }
}