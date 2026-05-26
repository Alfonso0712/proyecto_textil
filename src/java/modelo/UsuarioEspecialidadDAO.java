package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UsuarioEspecialidadDAO {

    // Obtener especialidades de un usuario
    public List<Especialidad> obtenerEspecialidadesPorUsuario(int idUsuario) {
        List<Especialidad> lista = new ArrayList<>();
        String sql = """
                SELECT e.id_especialidad, e.nombre, e.descripcion
                FROM especialidades e
                JOIN usuario_especialidad ue ON e.id_especialidad = ue.id_especialidad
                WHERE ue.id_usuario = ?
                ORDER BY e.nombre
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new Especialidad(
                            rs.getInt("id_especialidad"),
                            rs.getString("nombre"),
                            rs.getString("descripcion")
                    ));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al obtener especialidades del usuario", e);
        }
        return lista;
    }

    // Asignar una lista de especialidades a un usuario (reemplaza las anteriores)
    public boolean guardarEspecialidades(int idUsuario, List<Integer> idsEspecialidades) {
        String deleteSQL = "DELETE FROM usuario_especialidad WHERE id_usuario = ?";
        String insertSQL = "INSERT INTO usuario_especialidad (id_usuario, id_especialidad) VALUES (?, ?)";
        try (Connection cn = ConexionDB.obtenerConexion()) {
            cn.setAutoCommit(false);
            try {
                // Borra las existentes
                try (PreparedStatement psDel = cn.prepareStatement(deleteSQL)) {
                    psDel.setInt(1, idUsuario);
                    psDel.executeUpdate();
                }
                // Inserta las nuevas
                try (PreparedStatement psIns = cn.prepareStatement(insertSQL)) {
                    for (Integer idEsp : idsEspecialidades) {
                        psIns.setInt(1, idUsuario);
                        psIns.setInt(2, idEsp);
                        psIns.addBatch();
                    }
                    psIns.executeBatch();
                }
                cn.commit();
                return true;
            } catch (SQLException e) {
                cn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al guardar especialidades", e);
        }
    }
    
}