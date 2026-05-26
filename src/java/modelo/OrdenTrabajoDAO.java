package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: orden_trabajo
 * HU13: Creación de Orden de Trabajo (OT)
 * Implementa:
 *   - Generar código único OT-YYYY-NNNN (CUS 13.3)
 *   - Insertar OT con validación (CUS 13.2)
 *   - Listar todas las OTs con JOIN a usuarios (CUS 13.4)
 *   - Buscar por id
 *   - Anular OT
 * Relaciones: orden_trabajo → usuarios (id_responsable FK)
 *             telas → orden_trabajo (id_ot FK)  [HU01, no roto]
 */
public class OrdenTrabajoDAO {

    // ── Generar código único OT-YYYY-NNNN ─────────────────────
    /**
     * Genera el siguiente código OT en formato OT-2026-0001.
     * Consulta el máximo código existente del año actual y suma 1.
     */
    public String generarCodigoOt() throws SQLException {
        int anio = java.time.Year.now().getValue();
        String prefijo = "OT-" + anio + "-";
        String sql = "SELECT codigo_ot FROM orden_trabajo " +
                     "WHERE codigo_ot LIKE ? " +
                     "ORDER BY id_ot DESC LIMIT 1";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, prefijo + "%");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String ultimo = rs.getString("codigo_ot");
                // ultimo = "OT-2026-0042" → extraemos 0042
                String[] partes = ultimo.split("-");
                int numero = Integer.parseInt(partes[partes.length - 1]) + 1;
                return String.format("%s%04d", prefijo, numero);
            } else {
                return prefijo + "0001";
            }
        }
    }

    // ── Insertar una nueva OT ──────────────────────────────────
    /**
     * Persiste la OT en BD. El código se genera antes de llamar este método.
     * Estado inicial = 'CREADA'.
     * @return true si se insertó correctamente.
     */
    public boolean insertar(OrdenTrabajo ot) throws SQLException {
        String sql = "INSERT INTO orden_trabajo (codigo_ot, cliente, cantidad_est, estado, id_responsable, id_modelo) VALUES (?, ?, ?, 'CREADA', ?, ?)";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, ot.getCodigoOt());
            ps.setString(2, ot.getCliente());
            ps.setInt(3, ot.getCantidadEst());
            ps.setInt(4, ot.getIdResponsable());

            if (ot.getIdModelo() > 0) {
                ps.setInt(5, ot.getIdModelo());
            } else {
                ps.setNull(5, Types.INTEGER);
            }

            int filas = ps.executeUpdate();
            if (filas > 0) {
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) ot.setIdOt(keys.getInt(1));
            }
            return filas > 0;
        }
    }

    // ── Listar todas las OTs con nombre del responsable ───────
    /**
     * JOIN con usuarios para obtener nombre del jefe de producción responsable.
     * Ordenadas por fecha descendente (más recientes primero).
     */
    public List<OrdenTrabajo> listarTodas() throws SQLException {
        String sql = """
    SELECT ot.id_ot, ot.codigo_ot, ot.cliente,
           ot.cantidad_est, ot.estado, ot.id_responsable, ot.fecha_crea,
           ot.id_modelo, mp.nombre AS nombre_modelo,
           CONCAT(u.nombre, ' ', u.apellido) AS nombre_responsable
    FROM orden_trabajo ot
    JOIN usuarios u ON ot.id_responsable = u.id_usuario
    LEFT JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
    ORDER BY ot.fecha_crea DESC
    """;
        List<OrdenTrabajo> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }

    // ── Buscar por ID ──────────────────────────────────────────
    public OrdenTrabajo buscarPorId(int idOt) throws SQLException {
        String sql = """
            SELECT ot.id_ot, ot.codigo_ot, ot.cliente, 
                   ot.cantidad_est, ot.estado, ot.id_responsable, ot.fecha_crea,
                   ot.id_modelo, mp.nombre AS nombre_modelo,
                   CONCAT(u.nombre, ' ', u.apellido) AS nombre_responsable
            FROM orden_trabajo ot
            JOIN usuarios u ON ot.id_responsable = u.id_usuario
            LEFT JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
            WHERE ot.id_ot = ?
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

    // ── Buscar por código OT ───────────────────────────────────
    public OrdenTrabajo buscarPorCodigo(String codigoOt) throws SQLException {
        String sql = """
            SELECT ot.id_ot, ot.codigo_ot, ot.cliente, 
                   ot.cantidad_est, ot.estado, ot.id_responsable, ot.fecha_crea,
                   ot.id_modelo, mp.nombre AS nombre_modelo,
                   CONCAT(u.nombre, ' ', u.apellido) AS nombre_responsable
            FROM orden_trabajo ot
            JOIN usuarios u ON ot.id_responsable = u.id_usuario
            LEFT JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
            WHERE ot.codigo_ot = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, codigoOt);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        }
        return null;
    }

    // ── Cambiar estado de OT ───────────────────────────────────
    /**
     * Permite cambiar el estado: CREADA → EN_PROCESO → FINALIZADA | ANULADA
     */
    public boolean cambiarEstado(int idOt, String nuevoEstado) throws SQLException {
        String sql = "UPDATE orden_trabajo SET estado = ? WHERE id_ot = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nuevoEstado);
            ps.setInt   (2, idOt);
            return ps.executeUpdate() > 0;
        }
    }

    // ── Listar solo OTs ACTIVAS (CREADA o EN_PROCESO) ─────────
    public List<OrdenTrabajo> listarActivas() throws SQLException {
        String sql = """
            SELECT ot.id_ot, ot.codigo_ot, ot.cliente, 
                   ot.cantidad_est, ot.estado, ot.id_responsable, ot.fecha_crea,
                   ot.id_modelo, mp.nombre AS nombre_modelo,
                   CONCAT(u.nombre, ' ', u.apellido) AS nombre_responsable
            FROM orden_trabajo ot
            JOIN usuarios u ON ot.id_responsable = u.id_usuario
            LEFT JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
            WHERE ot.estado IN ('CREADA', 'EN_PROCESO')
            ORDER BY ot.fecha_crea DESC
            """;
        List<OrdenTrabajo> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }
    
    // Reemplaza tu método actualizar en OrdenTrabajoDAO.java con este:
    public boolean actualizar(int idOt, String cliente, int cantidadEst, int idModelo) throws SQLException {
        // La columna 'modelo' ya no existe, usamos 'id_modelo'
        String sql = """
            UPDATE orden_trabajo 
            SET cliente = ?, cantidad_est = ?, id_modelo = ?
            WHERE id_ot = ? AND estado = 'CREADA'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, cliente);
            ps.setInt(2, cantidadEst);
            ps.setInt(3, idModelo);
            ps.setInt(4, idOt);

            return ps.executeUpdate() > 0;
        }
    }

    public boolean eliminar(int idOt) throws SQLException {
        String checkTelas = "SELECT COUNT(*) FROM telas WHERE id_ot = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(checkTelas)) {
            ps.setInt(1, idOt);
            ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) return false;
        }
        String sql = "DELETE FROM orden_trabajo WHERE id_ot = ? AND estado = 'CREADA'";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idOt);
            return ps.executeUpdate() > 0;
        }
    }
    // ── Mapeo de ResultSet → OrdenTrabajo ─────────────────────
    private OrdenTrabajo mapear(ResultSet rs) throws SQLException {
        OrdenTrabajo ot = new OrdenTrabajo();
        ot.setIdOt           (rs.getInt      ("id_ot"));
        ot.setCodigoOt       (rs.getString   ("codigo_ot"));
        ot.setCliente        (rs.getString   ("cliente"));
        ot.setCantidadEst    (rs.getInt      ("cantidad_est"));
        ot.setEstado         (rs.getString   ("estado"));
        ot.setIdResponsable  (rs.getInt      ("id_responsable"));
        ot.setFechaCrea      (rs.getTimestamp("fecha_crea"));
        ot.setNombreResponsable(rs.getString ("nombre_responsable"));
        ot.setIdModelo(rs.getInt("id_modelo"));
        ot.setNombreModelo(rs.getString("nombre_modelo"));
        return ot;
    }
}
