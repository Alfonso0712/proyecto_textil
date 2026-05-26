package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla fotos_tela.
 * Ubicación: modelo/FotoTelaDAO.java
 * HU01 – CUS 1.4: Cargar Evidencia Fotográfica
 */
public class FotoTelaDAO {

    /**
     * Inserta una foto asociada a una tela.
     * @param foto objeto FotoTela con idTela, nombreArchivo y rutaRelativa
     * @return true si se insertó correctamente
     */
    public boolean insertar(FotoTela foto) {
        String sql = """
                INSERT INTO fotos_tela (id_tela, nombre_archivo, ruta_relativa)
                VALUES (?, ?, ?)
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql,
                     Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,    foto.getIdTela());
            ps.setString(2, foto.getNombreArchivo());
            ps.setString(3, foto.getRutaRelativa());

            int filas = ps.executeUpdate();
            if (filas > 0) {
                try (ResultSet rk = ps.getGeneratedKeys()) {
                    if (rk.next()) foto.setIdFoto(rk.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al guardar foto: " + e.getMessage(), e);
        }
        return false;
    }

    /**
     * Lista todas las fotos de una tela específica.
     * @param idTela ID de la tela
     * @return lista de FotoTela ordenadas por fecha de subida
     */
    public List<FotoTela> listarPorTela(int idTela) {
        List<FotoTela> lista = new ArrayList<>();
        String sql = """
                SELECT id_foto, id_tela, nombre_archivo, ruta_relativa, fecha_subida
                  FROM fotos_tela
                 WHERE id_tela = ?
                 ORDER BY fecha_subida ASC
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    FotoTela f = new FotoTela();
                    f.setIdFoto(rs.getInt("id_foto"));
                    f.setIdTela(rs.getInt("id_tela"));
                    f.setNombreArchivo(rs.getString("nombre_archivo"));
                    f.setRutaRelativa(rs.getString("ruta_relativa"));
                    f.setFechaSubida(rs.getTimestamp("fecha_subida"));
                    lista.add(f);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar fotos: " + e.getMessage(), e);
        }
        return lista;
    }

    /**
     * Cuenta las fotos de una tela.
     */
    public int contarPorTela(int idTela) {
        String sql = "SELECT COUNT(*) FROM fotos_tela WHERE id_tela = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al contar fotos: " + e.getMessage(), e);
        }
        return 0;
    }
}
