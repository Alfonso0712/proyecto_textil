package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CatalogoTelaDAO {

    public List<CatalogoTela> listarTodos() {
        List<CatalogoTela> lista = new ArrayList<>();
        String sql = "SELECT * FROM catalogo_telas ORDER BY nombre";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new CatalogoTela(
                        rs.getInt("id_catalogo"),
                        rs.getString("nombre"),
                        rs.getString("composicion"),
                        rs.getString("proveedor_base"),
                        rs.getBoolean("requiere_reposo"),
                        rs.getInt("tiempo_reposo")
                ));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar catálogo de telas", e);
        }
        return lista;
    }

    public CatalogoTela buscarPorId(int id) {
        String sql = "SELECT * FROM catalogo_telas WHERE id_catalogo = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new CatalogoTela(
                            rs.getInt("id_catalogo"),
                            rs.getString("nombre"),
                            rs.getString("composicion"),
                            rs.getString("proveedor_base"),
                            rs.getBoolean("requiere_reposo"),
                            rs.getInt("tiempo_reposo")
                    );
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar tela", e);
        }
        return null;
    }

    public boolean insertar(CatalogoTela ct) {
        String sql = "INSERT INTO catalogo_telas (nombre, composicion, proveedor_base, requiere_reposo, tiempo_reposo) VALUES (?, ?, ?, ?, ?)";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, ct.getNombre());
            ps.setString(2, ct.getComposicion());
            ps.setString(3, ct.getProveedorBase());
            ps.setBoolean(4, ct.isRequiereReposo());
            ps.setInt(5, ct.getTiempoReposo());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar tela en catálogo", e);
        }
    }

    public boolean actualizar(CatalogoTela ct) {
        String sql = "UPDATE catalogo_telas SET nombre=?, composicion=?, proveedor_base=?, requiere_reposo=?, tiempo_reposo=? WHERE id_catalogo=?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, ct.getNombre());
            ps.setString(2, ct.getComposicion());
            ps.setString(3, ct.getProveedorBase());
            ps.setBoolean(4, ct.isRequiereReposo());
            ps.setInt(5, ct.getTiempoReposo());
            ps.setInt(6, ct.getIdCatalogo());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar tela en catálogo", e);
        }
    }

    public boolean eliminar(int id) {
        String sql = "DELETE FROM catalogo_telas WHERE id_catalogo = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar tela del catálogo", e);
        }
    }
    public boolean tieneUsoEnInventario(int idCatalogo) {
        String sql = "SELECT COUNT(*) FROM telas WHERE id_catalogo_tela = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idCatalogo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return true;
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al verificar uso en inventario: " + e.getMessage(), e);
        }
        return false;
    }
}