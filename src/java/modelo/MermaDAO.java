package modelo;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: mermas
 * HU04: Registro de Merma por Tipo de Tejido
 */
public class MermaDAO {

    // ── LECTURA ───────────────────────────────────────────────

    /** Todas las mermas — Admin ve todo */
    public List<Merma> listarTodas() throws SQLException {
        return query("""
            SELECT m.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot, ot.cliente,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM mermas m
            JOIN telas t         ON m.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON m.id_ot      = ot.id_ot
            JOIN usuarios u      ON m.id_tizador  = u.id_usuario
            ORDER BY m.fecha_registro DESC
            """, -1);
    }

    /** Mermas del tizador logueado */
    public List<Merma> listarPorTizador(int idTizador) throws SQLException {
        return query("""
            SELECT m.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot, ot.cliente,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM mermas m
            JOIN telas t         ON m.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON m.id_ot      = ot.id_ot
            JOIN usuarios u      ON m.id_tizador  = u.id_usuario
            WHERE m.id_tizador = ?
            ORDER BY m.fecha_registro DESC
            """, idTizador);
    }

    /** Mermas filtradas por OT */
    public List<Merma> listarPorOt(int idOt) throws SQLException {
        return query("""
            SELECT m.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot, ot.cliente,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_tizador
            FROM mermas m
            JOIN telas t         ON m.id_tela    = t.id_tela
            JOIN orden_trabajo ot ON m.id_ot      = ot.id_ot
            JOIN usuarios u      ON m.id_tizador  = u.id_usuario
            WHERE m.id_ot = ?
            ORDER BY m.fecha_registro DESC
            """, idOt);
    }

    /**
     * CUS 4.2: Porcentaje total de merma acumulado por OT.
     * Suma peso_merma / suma peso_utilizado * 100.
     */
    public BigDecimal calcularPorcentajePorOt(int idOt) throws SQLException {
        String sql = """
            SELECT CASE WHEN SUM(peso_utilizado_kg) > 0
                   THEN ROUND(SUM(peso_merma_kg) / SUM(peso_utilizado_kg) * 100, 3)
                   ELSE 0 END AS pct
            FROM mermas WHERE id_ot = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idOt);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getBigDecimal("pct") : BigDecimal.ZERO;
            }
        }
    }

   
        /**
        * Telas disponibles para registrar merma:
        * - Solo telas con estado ACEPTADO u OBSERVADO.
        * - Y cuya Orden de Trabajo asociada esté en estado EN_PROCESO.
        */
       public List<Tela> listarTelasParaMerma() throws SQLException {
           String sql = """
               SELECT t.id_tela, t.codigo_tela, t.tipo_tejido,
                      t.color, t.peso_real, t.num_rollos,
                      ot.id_ot, ot.codigo_ot, ot.cliente
               FROM telas t
               JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
               WHERE t.estado_calidad IN ('ACEPTADO','OBSERVADO')
                 AND ot.estado = 'EN_PROCESO'
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
                   t.setPesoReal(rs.getBigDecimal("peso_real"));
                   t.setNumRollos(rs.getInt("num_rollos"));
                   t.setIdOt(rs.getInt("id_ot"));
                   t.setCodigoOt(rs.getString("codigo_ot"));
                   lista.add(t);
               }
           }
           return lista;
       }

    /** OTs activas para el filtro del listado */
    public List<OrdenTrabajo> listarOtsConMermas() throws SQLException {
        String sql = """
            SELECT DISTINCT ot.id_ot, ot.codigo_ot, ot.cliente
            FROM mermas m
            JOIN orden_trabajo ot ON m.id_ot = ot.id_ot
            ORDER BY ot.codigo_ot
            """;
        List<OrdenTrabajo> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                OrdenTrabajo ot = new OrdenTrabajo();
                ot.setIdOt(rs.getInt("id_ot"));
                ot.setCodigoOt(rs.getString("codigo_ot"));
                ot.setCliente(rs.getString("cliente"));
                lista.add(ot);
            }
        }
        return lista;
    }

    // ── ESCRITURA ─────────────────────────────────────────────

    /**
     * CUS 4.1: Registrar merma.
     * El porcentaje se calcula automáticamente por la columna STORED en BD.
     * @return ID generado o -1 si falló
     */
    public int registrar(Merma m) throws SQLException {
        String sql = """
            INSERT INTO mermas
              (id_tela, id_ot, id_tizador, fase,
               peso_utilizado_kg, peso_merma_kg, observaciones)
            VALUES (?,?,?,?,?,?,?)
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql,
                     Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, m.getIdTela());
            ps.setInt(2, m.getIdOt());
            ps.setInt(3, m.getIdTizador());
            ps.setString(4, m.getFase().name());
            ps.setBigDecimal(5, m.getPesoUtilizadoKg());
            ps.setBigDecimal(6, m.getPesomermaKg());
            ps.setString(7, m.getObservaciones());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }
    /**
    * Actualiza un registro de merma (solo admin). No se puede cambiar la tela.
    * @return true si se actualizó al menos una fila
    */
    public boolean actualizar(Merma m) throws SQLException {
        String sql = """
            UPDATE mermas
            SET fase = ?, peso_utilizado_kg = ?, peso_merma_kg = ?, observaciones = ?
            WHERE id_merma = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, m.getFase().name());
            ps.setBigDecimal(2, m.getPesoUtilizadoKg());
            ps.setBigDecimal(3, m.getPesomermaKg());
            ps.setString(4, m.getObservaciones());
            ps.setInt(5, m.getIdMerma());
            return ps.executeUpdate() > 0;
        }
    }
    /** Eliminar merma (solo admin) */
    public boolean eliminar(int idMerma) throws SQLException {
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(
                     "DELETE FROM mermas WHERE id_merma=?")) {
            ps.setInt(1, idMerma);
            return ps.executeUpdate() > 0;
        }
    }

    // ── HELPERS ───────────────────────────────────────────────

    private List<Merma> query(String sql, int param) throws SQLException {
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (param >= 0) ps.setInt(1, param);
            return mapear(ps.executeQuery());
        }
    }

    private List<Merma> mapear(ResultSet rs) throws SQLException {
        List<Merma> lista = new ArrayList<>();
        while (rs.next()) {
            Merma m = new Merma();
            m.setIdMerma(rs.getInt("id_merma"));
            m.setIdTela(rs.getInt("id_tela"));
            m.setIdOt(rs.getInt("id_ot"));
            m.setIdTizador(rs.getInt("id_tizador"));
            String fase = rs.getString("fase");
            if (fase != null) m.setFase(Merma.Fase.valueOf(fase));
            m.setPesoUtilizadoKg(rs.getBigDecimal("peso_utilizado_kg"));
            m.setPesomermaKg(rs.getBigDecimal("peso_merma_kg"));
            m.setPorcentajeMerma(rs.getBigDecimal("porcentaje_merma"));
            m.setObservaciones(rs.getString("observaciones"));
            m.setFechaRegistro(rs.getTimestamp("fecha_registro"));
            m.setCodigoTela(rs.getString("codigo_tela"));
            m.setTipoTejido(rs.getString("tipo_tejido"));
            m.setCodigoOt(rs.getString("codigo_ot"));
            m.setCliente(rs.getString("cliente"));
            m.setNombreTizador(rs.getString("nombre_tizador"));
            lista.add(m);
        }
        return lista;
    }
}
