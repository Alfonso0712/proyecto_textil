package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: conciliacion_despacho
 * HU07: Conciliación de Inventario y Despacho Final
 *
 * Implementa:
 *   - Listar OTs FINALIZADAS listas para conciliación/despacho
 *   - Obtener conciliación por OT
 *   - Insertar conciliación (conteo físico vs. estimado)
 *   - Confirmar despacho → cambia estado a DESPACHADO
 *
 * Tablas:
 *   conciliacion_despacho → orden_trabajo, modelos_prenda, usuarios
 */
public class ConciliacionDespachoDAO {

    // ── Listar lotes listos para conciliación ─────────────────
    /**
     * Devuelve las OTs FINALIZADAS junto con su conciliación (si existe).
     * Si no hay conciliación registrada aún, aparece como PENDIENTE.
     */
    public List<ConciliacionDespacho> listarLotesParaDespacho() throws SQLException {
        String sql = """
            SELECT
                COALESCE(cd.id_conciliacion, 0)      AS id_conciliacion,
                ot.id_ot,
                ot.cantidad_est                       AS cantidad_estimada,
                COALESCE(cd.cantidad_final, 0)        AS cantidad_final,
                COALESCE(cd.diferencia, 0)            AS diferencia,
                COALESCE(cd.estado, 'PENDIENTE')      AS estado,
                COALESCE(cd.id_responsable, 0)        AS id_responsable,
                cd.fecha_conciliacion,
                cd.fecha_despacho,
                cd.observaciones,
                ot.codigo_ot,
                ot.cliente,
                mp.nombre                             AS nombre_modelo,
                CONCAT(u.nombre, ' ', u.apellido)     AS nombre_responsable
            FROM orden_trabajo ot
            JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
            LEFT JOIN conciliacion_despacho cd ON cd.id_ot = ot.id_ot
            LEFT JOIN usuarios u ON cd.id_responsable = u.id_usuario
            WHERE ot.estado = 'FINALIZADA'
            ORDER BY ot.fecha_crea DESC
            """;
        List<ConciliacionDespacho> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }

    // ── Obtener conciliación por id de OT ─────────────────────
    public ConciliacionDespacho buscarPorIdOt(int idOt) throws SQLException {
        String sql = """
            SELECT cd.*, ot.codigo_ot, ot.cliente, ot.cantidad_est AS cantidad_estimada,
                   mp.nombre AS nombre_modelo,
                   CONCAT(u.nombre, ' ', u.apellido) AS nombre_responsable
            FROM conciliacion_despacho cd
            JOIN orden_trabajo  ot ON cd.id_ot        = ot.id_ot
            JOIN modelos_prenda mp ON ot.id_modelo     = mp.id_modelo
            LEFT JOIN usuarios  u  ON cd.id_responsable = u.id_usuario
            WHERE cd.id_ot = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idOt);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    // ── Insertar conciliación ─────────────────────────────────
    /**
     * Registra la conciliación: guarda el conteo final, calcula la diferencia
     * y determina el estado (CONCILIADO_OK o MERMA_DETECTADA).
     * (CUS 7.2 CompararConEstimado + CUS 7.3 RegistrarMermaInventario)
     * @return true si el INSERT fue exitoso
     */
    public boolean insertar(ConciliacionDespacho c) throws SQLException {
        // Calcular diferencia y estado
        int diferencia = c.getCantidadFinal() - c.getCantidadEstimada();
        c.setDiferencia(diferencia);
        c.setEstado(c.calcularEstado());

        // 1. Intentamos actualizar (porque el Ensamblaje ya creó el registro en estado PENDIENTE)
        String sqlUpdate = """
            UPDATE conciliacion_despacho
               SET cantidad_final = ?, diferencia = ?, estado = ?, 
                   id_responsable = ?, fecha_conciliacion = NOW(), observaciones = ?
             WHERE id_ot = ? AND estado = 'PENDIENTE'
            """;
            
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement psU = cn.prepareStatement(sqlUpdate)) {
            psU.setInt(1, c.getCantidadFinal());
            psU.setInt(2, diferencia);
            psU.setString(3, c.getEstado().name());
            psU.setInt(4, c.getIdResponsable());
            psU.setString(5, c.getObservaciones());
            psU.setInt(6, c.getIdOt());
            
            int filasAfectadas = psU.executeUpdate();
            if (filasAfectadas > 0) return true; // Se actualizó correctamente
        }

        // 2. Si no se actualizó nada (es una OT antigua que no tenía registro previo), insertamos
        String sqlInsert = """
            INSERT INTO conciliacion_despacho
                (id_ot, cantidad_final, diferencia, estado, id_responsable,
                 fecha_conciliacion, observaciones)
            VALUES (?, ?, ?, ?, ?, NOW(), ?)
            """;
            
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement psI = cn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
            psI.setInt(1, c.getIdOt());
            psI.setInt(2, c.getCantidadFinal());
            psI.setInt(3, diferencia);
            psI.setString(4, c.getEstado().name());
            psI.setInt(5, c.getIdResponsable());
            psI.setString(6, c.getObservaciones());
            
            int filas = psI.executeUpdate();
            if (filas > 0) {
                ResultSet keys = psI.getGeneratedKeys();
                if (keys.next()) c.setIdConciliacion(keys.getInt(1));
            }
            return filas > 0;
        }
    }
    // ── Confirmar despacho ────────────────────────────────────
    /**
     * Cambia el estado de la conciliación a DESPACHADO y registra la fecha.
     * (CUS 7.4 GenerarNotaDespacho → CUS 7.5 ConfirmarDespacho)
     * @return true si la actualización fue exitosa
     */
    public boolean confirmarDespacho(int idConciliacion) throws SQLException {
        String sql = """
            UPDATE conciliacion_despacho
               SET estado         = 'DESPACHADO',
                   fecha_despacho = NOW()
             WHERE id_conciliacion = ?
               AND estado IN ('CONCILIADO_OK', 'MERMA_DETECTADA')
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idConciliacion);
            return ps.executeUpdate() > 0;
        }
    }

    // ── Mapeo ResultSet → ConciliacionDespacho ────────────────
    private ConciliacionDespacho mapear(ResultSet rs) throws SQLException {
        ConciliacionDespacho c = new ConciliacionDespacho();
        c.setIdConciliacion(rs.getInt("id_conciliacion"));
        c.setIdOt(rs.getInt("id_ot"));
        c.setCantidadEstimada(rs.getInt("cantidad_estimada"));
        c.setCantidadFinal(rs.getInt("cantidad_final"));
        c.setDiferencia(rs.getInt("diferencia"));
        String est = rs.getString("estado");
        if (est != null) {
            try { c.setEstado(ConciliacionDespacho.EstadoConciliacion.valueOf(est)); }
            catch (IllegalArgumentException e) { c.setEstado(ConciliacionDespacho.EstadoConciliacion.PENDIENTE); }
        }
        c.setIdResponsable(rs.getInt("id_responsable"));
        c.setFechaConciliacion(rs.getTimestamp("fecha_conciliacion"));
        c.setFechaDespacho(rs.getTimestamp("fecha_despacho"));
        c.setObservaciones(rs.getString("observaciones"));
        c.setCodigoOt(rs.getString("codigo_ot"));
        c.setCliente(rs.getString("cliente"));
        c.setNombreModelo(rs.getString("nombre_modelo"));
        c.setNombreResponsable(rs.getString("nombre_responsable"));
        return c;
    }
}
