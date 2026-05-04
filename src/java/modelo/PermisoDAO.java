package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * DAO para las tablas permisos y rol_permiso.
 * Ubicación: modelo/PermisoDAO.java
 * HU09: Gestión de Perfiles y Permisos
 *
 * Responsabilidad:
 *  - Cargar los códigos de permiso que tiene un rol (para SesionFiltro)
 *  - Listar todos los permisos con flag "asignado" para la vista de matriz
 */
public class PermisoDAO {

    /**
     * Devuelve los CÓDIGOS de permiso asignados a un rol.
     * Se usa en SesionFiltro para verificar acceso en cada request.
     *
     * @param idRol  ID del rol
     * @return Set de códigos como "ALM_TELA_REGISTRAR", "RPT_DASHBOARD"…
     */
    public Set<String> obtenerCodigosPorRol(int idRol) {
        Set<String> codigos = new HashSet<>();
        String sql = """
                SELECT p.codigo
                  FROM permisos p
                  JOIN rol_permiso rp ON p.id_permiso = rp.id_permiso
                 WHERE rp.id_rol = ?
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idRol);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) codigos.add(rs.getString("codigo"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al obtener permisos del rol: " + e.getMessage(), e);
        }
        return codigos;
    }

    /**
     * Lista TODOS los permisos marcando cuáles están asignados a un rol.
     * Se usa en la vista de gestión de permisos (tabla con checkboxes).
     *
     * @param idRol  Rol a comparar
     * @return Lista completa con flag asignado = true/false
     */
    public List<Permiso> listarTodosConFlag(int idRol) {
        List<Permiso> lista = new ArrayList<>();
        // LEFT JOIN para saber si el permiso ya está en el rol
        String sql = """
                SELECT p.id_permiso, p.codigo, p.nombre, p.modulo, p.descripcion,
                       CASE WHEN rp.id_rol IS NOT NULL THEN 1 ELSE 0 END AS asignado
                  FROM permisos p
                  LEFT JOIN rol_permiso rp
                         ON p.id_permiso = rp.id_permiso AND rp.id_rol = ?
                 ORDER BY p.modulo, p.nombre
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idRol);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Permiso p = new Permiso(
                            rs.getInt("id_permiso"),
                            rs.getString("codigo"),
                            rs.getString("nombre"),
                            rs.getString("modulo"),
                            rs.getString("descripcion")
                    );
                    p.setAsignado(rs.getBoolean("asignado"));
                    lista.add(p);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar permisos con flag: " + e.getMessage(), e);
        }
        return lista;
    }

    /**
     * Lista los módulos únicos que tiene un rol (para construir menú dinámico).
     */
    public List<String> obtenerModulosPorRol(int idRol) {
        List<String> modulos = new ArrayList<>();
        String sql = """
                SELECT DISTINCT p.modulo
                  FROM permisos p
                  JOIN rol_permiso rp ON p.id_permiso = rp.id_permiso
                 WHERE rp.id_rol = ?
                 ORDER BY p.modulo
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idRol);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) modulos.add(rs.getString("modulo"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al obtener módulos del rol: " + e.getMessage(), e);
        }
        return modulos;
    }
}
