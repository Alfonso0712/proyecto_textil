package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class EspecialidadDAO {

    public List<Especialidad> listarTodos() {
        List<Especialidad> lista = new ArrayList<>();
        String sql = "SELECT * FROM especialidades ORDER BY nombre";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Especialidad(
                        rs.getInt("id_especialidad"),
                        rs.getString("nombre"),
                        rs.getString("descripcion")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar especialidades", e);
        }
        return lista;
    }
    // En modelo/EspecialidadDAO.java
    public Especialidad insertar(Especialidad esp) {
        String sql = "INSERT INTO especialidades (nombre, descripcion) VALUES (?, ?)";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, esp.getNombre());
            ps.setString(2, esp.getDescripcion());
            int filas = ps.executeUpdate();
            if (filas > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        esp.setIdEspecialidad(rs.getInt(1));
                        return esp;
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar especialidad", e);
        }
        return null;
    }
    public Especialidad buscarPorId(int id) {
        String sql = "SELECT * FROM especialidades WHERE id_especialidad = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Especialidad(
                            rs.getInt("id_especialidad"),
                            rs.getString("nombre"),
                            rs.getString("descripcion")
                    );
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar especialidad", e);
        }
        return null;
    }
    // ── Actualizar ────────────────────────────────────────────
    public boolean actualizar(Especialidad esp) {
        String sql = "UPDATE especialidades SET nombre = ?, descripcion = ? WHERE id_especialidad = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, esp.getNombre());
            ps.setString(2, esp.getDescripcion());
            ps.setInt(3, esp.getIdEspecialidad());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar especialidad", e);
        }
    }

    // ── Eliminar ──────────────────────────────────────────────
    public boolean eliminar(int id) {
        String sql = "DELETE FROM especialidades WHERE id_especialidad = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar especialidad", e);
        }
    }
}