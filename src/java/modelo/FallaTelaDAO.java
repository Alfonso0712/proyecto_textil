package modelo;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: fallas_tela
 * HU02: Mapeo Digital de Imperfecciones y Fallas en la Tela
 */
public class FallaTelaDAO {

    // ── LECTURA ───────────────────────────────────────────────

    /** Todas las fallas (Admin ve todo) */
    public List<FallaTela> listarTodas() throws SQLException {
        return ejecutarQuery(
            """
            SELECT ft.*, t.codigo_tela, t.tipo_tejido, ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM fallas_tela ft
            JOIN telas t        ON ft.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON t.id_ot     = ot.id_ot
            JOIN usuarios u     ON ft.id_tizador = u.id_usuario
            ORDER BY ft.fecha_registro DESC
            """, -1);
    }

    /** Fallas registradas por un tizador específico */
    public List<FallaTela> listarPorTizador(int idTizador) throws SQLException {
        return ejecutarQuery(
            """
            SELECT ft.*, t.codigo_tela, t.tipo_tejido, ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM fallas_tela ft
            JOIN telas t        ON ft.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON t.id_ot     = ot.id_ot
            JOIN usuarios u     ON ft.id_tizador = u.id_usuario
            WHERE ft.id_tizador = ?
            ORDER BY ft.fecha_registro DESC
            """, idTizador);
    }

    /** Todas las fallas de una tela concreta */
    public List<FallaTela> listarPorTela(int idTela) throws SQLException {
        return ejecutarQuery(
            """
            SELECT ft.*, t.codigo_tela, t.tipo_tejido, ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM fallas_tela ft
            JOIN telas t        ON ft.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON t.id_ot     = ot.id_ot
            JOIN usuarios u     ON ft.id_tizador = u.id_usuario
            WHERE ft.id_tela = ?
            ORDER BY ft.posicion_rollo, ft.posicion_metro
            """, idTela);
    }

    /** Conteo de fallas agrupado por tipo para una tela (para el resumen visual) */
    public int contarFallasPorTipoYTela(int idTela, FallaTela.TipoFalla tipo) throws SQLException {
        String sql = "SELECT COUNT(*) FROM fallas_tela WHERE id_tela=? AND tipo_falla=?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            ps.setString(2, tipo.name());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /**
     * Devuelve las telas que tienen al menos una falla registrada.
     * Usado para el filtro de búsqueda del listado.
     */
    public List<Tela> listarTelasConFallas() throws SQLException {
        String sql = """
            SELECT DISTINCT t.id_tela, t.codigo_tela, t.tipo_tejido, t.color, ot.codigo_ot
            FROM fallas_tela ft
            JOIN telas t        ON ft.id_tela = t.id_tela
            JOIN orden_trabajo ot ON t.id_ot  = ot.id_ot
            ORDER BY t.codigo_tela
            """;
        List<Tela> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Tela t = new Tela();
                t.setIdTela(rs.getInt("id_tela"));
                t.setCodigoTela(rs.getString("codigo_tela"));
                t.setTipoTejido(rs.getString("tipo_tejido"));
                t.setColor(rs.getString("color"));
                t.setCodigoOt(rs.getString("codigo_ot"));
                lista.add(t);
            }
        }
        return lista;
    }

    /**
     * Devuelve las telas disponibles para registrar fallas
     * (solo telas en estado ACEPTADO u OBSERVADO, no rechazadas).
     */
    public List<Tela> listarTelasParaMapeo() throws SQLException {
        String sql = """
            SELECT t.id_tela, t.codigo_tela, t.tipo_tejido, t.color,
                   t.num_rollos, ot.codigo_ot
            FROM telas t
            JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
            WHERE t.estado_calidad IN ('ACEPTADO','OBSERVADO')
            ORDER BY t.codigo_tela
            """;
        List<Tela> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Tela t = new Tela();
                t.setIdTela(rs.getInt("id_tela"));
                t.setCodigoTela(rs.getString("codigo_tela"));
                t.setTipoTejido(rs.getString("tipo_tejido"));
                t.setColor(rs.getString("color"));
                t.setNumRollos(rs.getInt("num_rollos"));
                t.setCodigoOt(rs.getString("codigo_ot"));
                lista.add(t);
            }
        }
        return lista;
    }

    // ── ESCRITURA ─────────────────────────────────────────────

    /**
     * CUS 2.1 + 2.2: Registrar falla categorizada.
     * @return ID generado o -1 si falló
     */
    public int registrar(FallaTela f) throws SQLException {
        String sql = """
            INSERT INTO fallas_tela
              (id_tela, id_tizador, tipo_falla, posicion_rollo, posicion_metro,
               ancho_cm, largo_cm, descripcion, es_area_no_apta)
            VALUES (?,?,?,?,?,?,?,?,?)
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, f.getIdTela());
            ps.setInt(2, f.getIdTizador());
            ps.setString(3, f.getTipoFalla().name());
            ps.setInt(4, f.getPosicionRollo());
            ps.setBigDecimal(5, f.getPosicionMetro());
            ps.setBigDecimal(6, f.getAnchoCm());
            ps.setBigDecimal(7, f.getLargoCm());
            ps.setString(8, f.getDescripcion());
            ps.setBoolean(9, f.isEsAreaNoApta());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }
    
    public boolean actualizar(FallaTela f) throws SQLException {
        String sql = """
            UPDATE fallas_tela
            SET id_tela = ?, tipo_falla = ?, posicion_rollo = ?, posicion_metro = ?,
                ancho_cm = ?, largo_cm = ?, descripcion = ?, es_area_no_apta = ?
            WHERE id_falla = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, f.getIdTela());
            ps.setString(2, f.getTipoFalla().name());
            ps.setInt(3, f.getPosicionRollo());
            ps.setBigDecimal(4, f.getPosicionMetro());
            ps.setBigDecimal(5, f.getAnchoCm());
            ps.setBigDecimal(6, f.getLargoCm());
            ps.setString(7, f.getDescripcion());
            ps.setBoolean(8, f.isEsAreaNoApta());
            ps.setInt(9, f.getIdFalla());
            return ps.executeUpdate() > 0;
        }
    }
    /** Eliminar una falla por ID (solo admin o el propio tizador) */
    public boolean eliminar(int idFalla) throws SQLException {
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(
                     "DELETE FROM fallas_tela WHERE id_falla=?")) {
            ps.setInt(1, idFalla);
            return ps.executeUpdate() > 0;
        }
    }

    // ── HELPERS ───────────────────────────────────────────────

    private List<FallaTela> ejecutarQuery(String sql, int paramInt) throws SQLException {
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (paramInt >= 0) ps.setInt(1, paramInt);
            return mapear(ps.executeQuery());
        }
    }

    private List<FallaTela> mapear(ResultSet rs) throws SQLException {
        List<FallaTela> lista = new ArrayList<>();
        while (rs.next()) {
            FallaTela f = new FallaTela();
            f.setIdFalla(rs.getInt("id_falla"));
            f.setIdTela(rs.getInt("id_tela"));
            f.setIdTizador(rs.getInt("id_tizador"));
            String tipo = rs.getString("tipo_falla");
            if (tipo != null) f.setTipoFalla(FallaTela.TipoFalla.valueOf(tipo));
            f.setPosicionRollo(rs.getInt("posicion_rollo"));
            f.setPosicionMetro(rs.getBigDecimal("posicion_metro"));
            f.setAnchoCm(rs.getBigDecimal("ancho_cm"));
            f.setLargoCm(rs.getBigDecimal("largo_cm"));
            f.setDescripcion(rs.getString("descripcion"));
            f.setEsAreaNoApta(rs.getBoolean("es_area_no_apta"));
            f.setFechaRegistro(rs.getTimestamp("fecha_registro"));
            f.setCodigoTela(rs.getString("codigo_tela"));
            f.setTipoTejido(rs.getString("tipo_tejido"));
            f.setCodigoOt(rs.getString("codigo_ot"));
            f.setNombreTizador(rs.getString("nombre_tizador"));
            lista.add(f);
        }
        return lista;
    }
}
