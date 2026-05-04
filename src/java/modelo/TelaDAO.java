
package modelo;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla telas.
 * Ubicación: modelo/TelaDAO.java
 * HU01: Registro y Control de Calidad de Tela Recibida
 */
public class TelaDAO {

    // ── INSERTAR ───────────────────────────────────────────────

    /**
     * Registra el ingreso de una tela (HU01).
     * La diferencia de peso es calculada por MySQL (columna STORED).
     */
    public boolean insertar(Tela t) {
        String sql = """
                INSERT INTO telas
                    (id_ot, id_registrador, codigo_tela, origen, proveedor,
                     peso_guia, peso_real, tipo_tejido, color, num_rollos,
                     observaciones, estado_calidad, requiere_reposo)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql,
                     Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,    t.getIdOt());
            ps.setInt(2,    t.getIdRegistrador());
            ps.setString(3, t.getCodigoTela());
            ps.setString(4, t.getOrigen().name());
            ps.setString(5, t.getProveedor());
            ps.setBigDecimal(6, t.getPesoGuia());
            ps.setBigDecimal(7, t.getPesoReal());
            ps.setString(8,  t.getTipoTejido());
            ps.setString(9,  t.getColor());
            ps.setInt(10,    t.getNumRollos());
            ps.setString(11, t.getObservaciones());
            ps.setString(12, t.getEstadoCalidad().name());
            ps.setBoolean(13,t.isRequiereReposo());

            int filas = ps.executeUpdate();
            if (filas > 0) {
                try (ResultSet rk = ps.getGeneratedKeys()) {
                    if (rk.next()) t.setIdTela(rk.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al registrar tela: " + e.getMessage(), e);
        }
        return false;
    }

    // ── LISTAR ────────────────────────────────────────────────

    /** Lista todas las telas con datos de OT y registrador. */
    public List<Tela> listarTodas() {
        return listarConFiltro(null, null);
    }

    /** Lista telas de una OT específica. */
    public List<Tela> listarPorOt(int idOt) {
        return listarConFiltro("t.id_ot = ?", idOt);
    }

    private List<Tela> listarConFiltro(String condicion, Object valor) {
        List<Tela> lista = new ArrayList<>();
        String sql = """
                SELECT t.*, ot.codigo_ot,
                       CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
                  FROM telas t
                  JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
                  JOIN usuarios u      ON t.id_registrador = u.id_usuario
                """ + (condicion != null ? " WHERE " + condicion : "") +
                " ORDER BY t.fecha_ingreso DESC";

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            if (valor != null) ps.setObject(1, valor);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapearTela(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar telas: " + e.getMessage(), e);
        }
        return lista;
    }

    /** Busca una tela por ID. */
    public Tela buscarPorId(int idTela) {
        String sql = """
                SELECT t.*, ot.codigo_ot,
                       CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
                  FROM telas t
                  JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
                  JOIN usuarios u      ON t.id_registrador = u.id_usuario
                 WHERE t.id_tela = ?
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearTela(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar tela: " + e.getMessage(), e);
        }
        return null;
    }

    // ── ACTUALIZAR ────────────────────────────────────────────

    /** Actualiza estado de calidad y observaciones. */
    public boolean actualizarEstado(int idTela, Tela.EstadoCalidad estado, String observaciones) {
        String sql = "UPDATE telas SET estado_calidad = ?, observaciones = ? WHERE id_tela = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, estado.name());
            ps.setString(2, observaciones);
            ps.setInt(3, idTela);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar tela: " + e.getMessage(), e);
        }
    }

    // ── MAPEADOR ──────────────────────────────────────────────

    private Tela mapearTela(ResultSet rs) throws SQLException {
        Tela t = new Tela();
        t.setIdTela(rs.getInt("id_tela"));
        t.setIdOt(rs.getInt("id_ot"));
        t.setIdRegistrador(rs.getInt("id_registrador"));
        t.setCodigoTela(rs.getString("codigo_tela"));
        t.setOrigen(Tela.Origen.valueOf(rs.getString("origen")));
        t.setProveedor(rs.getString("proveedor"));
        t.setPesoGuia(rs.getBigDecimal("peso_guia"));
        t.setPesoReal(rs.getBigDecimal("peso_real"));
        t.setDiferenciaPeso(rs.getBigDecimal("diferencia_peso"));
        t.setTipoTejido(rs.getString("tipo_tejido"));
        t.setColor(rs.getString("color"));
        t.setNumRollos(rs.getInt("num_rollos"));
        t.setObservaciones(rs.getString("observaciones"));
        t.setEstadoCalidad(Tela.EstadoCalidad.valueOf(rs.getString("estado_calidad")));
        t.setRequiereReposo(rs.getBoolean("requiere_reposo"));
        t.setFechaIngreso(rs.getTimestamp("fecha_ingreso"));
        t.setCodigoOt(rs.getString("codigo_ot"));
        t.setNombreRegistrador(rs.getString("nombre_registrador"));
        return t;
    }
}
