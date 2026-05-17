package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla roles.
 * Ubicación: modelo/RolDAO.java
 * HU09: Gestión de Perfiles y Permisos
 *
 * Responsabilidad: operaciones de consulta sobre roles.
 * Los roles son catálogos fijos; no se crean/borran desde la UI.
 */
public class RolDAO {

    /**
     * Devuelve todos los roles para poblar ComboBox en el formulario de usuario.
     */
    public List<Rol> listarTodos() {
        List<Rol> lista = new ArrayList<>();
        String sql = "SELECT id_rol, nombre_rol, descripcion FROM roles ORDER BY id_rol";

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new Rol(
                        rs.getInt("id_rol"),
                        rs.getString("nombre_rol"),
                        rs.getString("descripcion")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar roles: " + e.getMessage(), e);
        }
        return lista;
    }

    /**
     * Busca un rol por su ID (útil al cargar datos de un usuario para edición).
     */
    public Rol buscarPorId(int idRol) {
        String sql = "SELECT id_rol, nombre_rol, descripcion FROM roles WHERE id_rol = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idRol);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Rol(rs.getInt(1), rs.getString(2), rs.getString(3));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar rol: " + e.getMessage(), e);
        }
        return null;
    }
}
