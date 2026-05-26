package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: defectos_reproceso
 * HU06: Control de Defectos y Reprocesos
 *
 * Implementa:
 *   - Listar historial de defectos con JOIN a OT, modelo y maquinista
 *   - Insertar defecto + incrementar contador acumulado en usuarios (atómico)
 *   - Obtener resumen de reprocesos por maquinista (para el dashboard)
 *
 * Tablas relacionadas:
 *   defectos_reproceso → orden_trabajo, piezas_modelo, usuarios
 */
public class DefectoReprocesoDAO {

    // ── Listar historial completo de defectos ─────────────────
    /**
     * Devuelve todos los defectos registrados ordenados por fecha descendente.
     * JOIN con OT, modelo y maquinista para mostrar en la vista.
     */
    public List<DefectoReproceso> listarTodos() throws SQLException {
        String sql = """
            SELECT
                dr.id_defecto,
                dr.id_ot,
                dr.id_pieza,
                dr.id_maquinista,
                dr.tipo_falla,
                dr.observaciones,
                dr.fecha_registro,
                ot.codigo_ot,
                mp.nombre   AS nombre_modelo,
                pm.nombre_pieza,
                CONCAT(u.nombre, ' ', u.apellido) AS nombre_maquinista
            FROM defectos_reproceso dr
            JOIN orden_trabajo  ot ON dr.id_ot       = ot.id_ot
            JOIN modelos_prenda mp ON ot.id_modelo    = mp.id_modelo
            LEFT JOIN piezas_modelo pm ON dr.id_pieza = pm.id_pieza
            JOIN usuarios       u  ON dr.id_maquinista = u.id_usuario
            ORDER BY dr.fecha_registro DESC
            """;
        List<DefectoReproceso> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }

    // ── Insertar defecto y actualizar contador de maquinista ──
    /**
     * Registra el defecto e incrementa el campo reprocesos_acum del maquinista
     * en una sola transacción atómica (CUS 6.3 IncrementarContadorReprocesos).
     * @return true si ambas operaciones tuvieron éxito
     */
    public boolean insertarYActualizarContador(DefectoReproceso d) throws SQLException {
        String sqlInsert = """
            INSERT INTO defectos_reproceso
                (id_ot, id_pieza, id_maquinista, tipo_falla, observaciones, fecha_registro)
            VALUES (?, ?, ?, ?, ?, NOW())
            """;
        String sqlUpdate = """
            UPDATE usuarios
               SET reprocesos_acum = COALESCE(reprocesos_acum, 0) + 1
             WHERE id_usuario = ?
            """;
        Connection cn = null;
        try {
            cn = ConexionDB.obtenerConexion();
            cn.setAutoCommit(false); // Transacción atómica

            // 1. Insertar defecto
            try (PreparedStatement ps = cn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, d.getIdOt());
                if (d.getIdPieza() > 0) ps.setInt(2, d.getIdPieza()); else ps.setNull(2, Types.INTEGER);
                ps.setInt(3, d.getIdMaquinista());
                ps.setString(4, d.getTipoFalla() != null ? d.getTipoFalla().name() : null);
                ps.setString(5, d.getObservaciones());
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) d.setIdDefecto(keys.getInt(1));
            }

            // 2. Incrementar contador acumulado del maquinista (HU06)
            try (PreparedStatement ps = cn.prepareStatement(sqlUpdate)) {
                ps.setInt(1, d.getIdMaquinista());
                ps.executeUpdate();
            }

            cn.commit();
            return true;

        } catch (SQLException e) {
            if (cn != null) { try { cn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); } }
            throw e;
        } finally {
            if (cn != null) { try { cn.setAutoCommit(true); cn.close(); } catch (SQLException ex) { ex.printStackTrace(); } }
        }
    }
    public void insertarDefectoPendiente(DefectoReproceso d) throws SQLException {
    String sql = "INSERT INTO defectos_reproceso (id_ot, id_pieza, id_maquinista, cantidad_faltante, estado, id_asignacion) VALUES (?, ?, ?, ?, ?, ?)";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
        ps.setInt(1, d.getIdOt());
        ps.setInt(2, d.getIdPieza());
        ps.setInt(3, d.getIdMaquinista());
        ps.setInt(4, d.getCantidadFaltante());
        ps.setString(5, d.getEstado().name());
        ps.setInt(6, d.getIdAsignacion());
        ps.executeUpdate();
        try (ResultSet rs = ps.getGeneratedKeys()) {
            if (rs.next()) d.setIdDefecto(rs.getInt(1));
        }
    }
}
public void completarDefecto(int idDefecto, String tipoFalla, String observaciones) throws SQLException {
        String sqlDefecto = "UPDATE defectos_reproceso SET tipo_falla = ?, observaciones = ?, estado = 'REGISTRADO' WHERE id_defecto = ?";
        
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sqlDefecto)) {
            ps.setString(1, tipoFalla);
            ps.setString(2, observaciones);
            ps.setInt(3, idDefecto);
            ps.executeUpdate();
        }
    }
    public List<DefectoReproceso> listarDefectos(int idUsuario, String nombreRol) throws SQLException {
    boolean esAdmin = "ADMINISTRADOR".equals(nombreRol);
    boolean esSupervisor = "SUPERVISOR".equals(nombreRol);
    
    String sql = "SELECT d.*, ot.codigo_ot, mp.nombre AS nombre_modelo, " +
                 "pm.nombre_pieza, " +
                 "CONCAT(u.nombre,' ',u.apellido) AS nombre_maquinista " +
                 "FROM defectos_reproceso d " +
                 "JOIN orden_trabajo ot ON d.id_ot = ot.id_ot " +
                 "JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo " +
                 "LEFT JOIN piezas_modelo pm ON d.id_pieza = pm.id_pieza " +
                 "JOIN usuarios u ON d.id_maquinista = u.id_usuario " +
                 "WHERE 1=1 " +
                 (esAdmin || esSupervisor ? "" : " AND d.id_maquinista = ? ") +
                 "ORDER BY d.fecha_registro DESC";

    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
         
        if (!esAdmin && !esSupervisor) {
            ps.setInt(1, idUsuario);
        }
        
        try (ResultSet rs = ps.executeQuery()) {
            List<DefectoReproceso> lista = new ArrayList<>();
            while (rs.next()) {
                DefectoReproceso d = new DefectoReproceso();
                // ... mapeo de campos existentes ...
                d.setIdDefecto(rs.getInt("id_defecto"));
                d.setIdOt(rs.getInt("id_ot"));
                d.setIdPieza(rs.getInt("id_pieza"));
                d.setIdMaquinista(rs.getInt("id_maquinista"));
                d.setCantidadFaltante(rs.getInt("cantidad_faltante"));
                d.setIdAsignacion(rs.getInt("id_asignacion"));
                d.setGeneraReposicion(rs.getInt("genera_reposicion"));  // ← AGREGAR ESTA LÍNEA
                
                String tipo = rs.getString("tipo_falla");
                if (tipo != null) {
                    try { d.setTipoFalla(DefectoReproceso.TipoFalla.valueOf(tipo)); }
                    catch (IllegalArgumentException e) { d.setTipoFalla(DefectoReproceso.TipoFalla.OTRO); }
                }
                d.setObservaciones(rs.getString("observaciones"));
                d.setFechaRegistro(rs.getTimestamp("fecha_registro"));
                String estadoStr = rs.getString("estado");
                if (estadoStr != null) {
                    try { d.setEstado(DefectoReproceso.Estado.valueOf(estadoStr)); }
                    catch (IllegalArgumentException e) { d.setEstado(DefectoReproceso.Estado.PENDIENTE); }
                }
                d.setCodigoOt(rs.getString("codigo_ot"));
                d.setNombreModelo(rs.getString("nombre_modelo"));
                d.setNombrePieza(rs.getString("nombre_pieza"));
                d.setNombreMaquinista(rs.getString("nombre_maquinista"));
                
                lista.add(d);
            }
            return lista;
        }
    }
}
    // ── Resumen de reprocesos por maquinista (dashboard HU06) ─
    /**
     * Retorna el conteo de defectos registrados por maquinista.
     * Se ordena descendente para identificar a los que más reprocesos tienen.
     */
   // ── Resumen de reprocesos por maquinista (dashboard HU06) ─
    // ── Resumen de reprocesos por maquinista (dashboard HU06) ─
    public List<ResumenReprocesos> resumenPorMaquinista() throws SQLException {
        String sql = """
            SELECT 
                u.id_usuario,
                CONCAT(u.nombre, ' ', u.apellido) AS nombre_maquinista,
                GROUP_CONCAT(DISTINCT e.nombre SEPARATOR ', ') AS especialidad,
                COUNT(DISTINCT dr.id_defecto) AS total_reprocesos
            FROM usuarios u
            LEFT JOIN usuario_especialidad ue ON u.id_usuario = ue.id_usuario
            LEFT JOIN especialidades e ON ue.id_especialidad = e.id_especialidad
            LEFT JOIN defectos_reproceso dr ON dr.id_maquinista = u.id_usuario
            WHERE u.id_rol = 6 AND u.activo = TRUE
            GROUP BY u.id_usuario, u.nombre, u.apellido
            HAVING COUNT(DISTINCT dr.id_defecto) > 0
            ORDER BY total_reprocesos DESC
            """;
            
        List<ResumenReprocesos> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
             
            while (rs.next()) {
                ResumenReprocesos r = new ResumenReprocesos();
                r.setIdMaquinista(rs.getInt("id_usuario"));
                r.setNombreMaquinista(rs.getString("nombre_maquinista"));
                r.setEspecialidad(rs.getString("especialidad"));
                r.setTotalReprocesos(rs.getInt("total_reprocesos"));
                lista.add(r);
            }
        }
        return lista;
    }
    public boolean marcarConReposicion(int idDefecto) throws SQLException {
    String sql = "UPDATE defectos_reproceso SET genera_reposicion = 1, estado = 'REGISTRADO' WHERE id_defecto = ?";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idDefecto);
        return ps.executeUpdate() > 0;
    }
}

public DefectoReproceso obtenerPorId(int idDefecto) throws SQLException {
    String sql = "SELECT * FROM defectos_reproceso WHERE id_defecto = ?";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idDefecto);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                DefectoReproceso d = new DefectoReproceso();
                d.setIdDefecto(rs.getInt("id_defecto"));
                d.setIdOt(rs.getInt("id_ot"));
                d.setIdMaquinista(rs.getInt("id_maquinista"));
                d.setCantidadFaltante(rs.getInt("cantidad_faltante"));
                d.setIdAsignacion(rs.getInt("id_asignacion"));
                d.setGeneraReposicion(rs.getInt("genera_reposicion"));
                
                // 🌟 FIX: Aquí faltaba cargar el estado
                String estadoStr = rs.getString("estado");
                if (estadoStr != null) {
                    try {
                        d.setEstado(DefectoReproceso.Estado.valueOf(estadoStr));
                    } catch (IllegalArgumentException e) {
                        d.setEstado(DefectoReproceso.Estado.PENDIENTE);
                    }
                }
                
                return d;
            }
        }
    }
    return null;
}
/**
 * Igual que insertarDefectoPendiente pero retorna el ID generado.
 * Necesario para luego llamar marcarConReposicion(idDefecto).
 */
public int insertarDefectoPendienteRetornarId(DefectoReproceso defecto) throws SQLException {
    String sql = """
        INSERT INTO defectos_reproceso
            (id_ot, id_pieza, id_maquinista, tipo_falla, observaciones,
             cantidad_faltante, estado, id_asignacion)
        VALUES (?, ?, ?, ?, ?, ?, 'PENDIENTE', ?)
        """;
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

        ps.setInt   (1, defecto.getIdOt());

        // id_pieza puede ser null (caso ensamblaje)
        if (defecto.getIdPieza() <= 0 || defecto.getIdPieza() == 0) {
            ps.setNull(2, java.sql.Types.INTEGER);
        } else {
            ps.setInt(2, defecto.getIdPieza());
        }

        ps.setInt   (3, defecto.getIdMaquinista());
        ps.setString(4, defecto.getTipoFalla().name());
        ps.setString(5, defecto.getObservaciones());
        ps.setInt   (6, defecto.getCantidadFaltante());
        ps.setInt   (7, defecto.getIdAsignacion());

        ps.executeUpdate();

        try (ResultSet keys = ps.getGeneratedKeys()) {
            if (keys.next()) return keys.getInt(1); // ← retorna el ID
        }
    }
    return -1; // no debería llegar aquí
}
public void marcarCorregido(int idDefecto) throws SQLException {
    String sql = "UPDATE defectos_reproceso SET estado = 'CORREGIDO', cantidad_faltante = 0 WHERE id_defecto = ?";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idDefecto);
        ps.executeUpdate();
    }
}
    // ── Mapeo ResultSet → DefectoReproceso ────────────────────
    private DefectoReproceso mapear(ResultSet rs) throws SQLException {
        DefectoReproceso d = new DefectoReproceso();
        d.setIdDefecto(rs.getInt("id_defecto"));
        d.setIdOt(rs.getInt("id_ot"));
        d.setIdPieza(rs.getInt("id_pieza"));
        d.setIdMaquinista(rs.getInt("id_maquinista"));
        String falla = rs.getString("tipo_falla");
        if (falla != null) {
            try { d.setTipoFalla(DefectoReproceso.TipoFalla.valueOf(falla)); }
            catch (IllegalArgumentException e) { d.setTipoFalla(DefectoReproceso.TipoFalla.OTRO); }
        }
        d.setObservaciones(rs.getString("observaciones"));
        d.setFechaRegistro(rs.getTimestamp("fecha_registro"));
        d.setCodigoOt(rs.getString("codigo_ot"));
        d.setNombreModelo(rs.getString("nombre_modelo"));
        d.setNombrePieza(rs.getString("nombre_pieza"));
        d.setNombreMaquinista(rs.getString("nombre_maquinista"));
        return d;
    }
    public void corregirDefecto(int idDefecto) throws SQLException {
    // 1. Marcar defecto como 'CORREGIDO' y cantidad faltante a 0 (esto lo elimina de tu vista de defectos)
    String sqlDefecto = "UPDATE defectos_reproceso SET estado = 'CORREGIDO', cantidad_faltante = 0 WHERE id_defecto = ?";
    
    // 2. Sincronizar piezas: Igualar piezas_completadas a la cantidad_piezas original
    // Esto hace que el 80/100 se convierta automáticamente en 100/100
    String sqlCarga = "UPDATE asignaciones_carga ac " +
                      "JOIN defectos_reproceso dr ON ac.id_ot = dr.id_ot " +
                      "SET ac.piezas_completadas = ac.cantidad_piezas " +
                      "WHERE dr.id_defecto = ?";
                      
    Connection cn = null;
    try {
        cn = ConexionDB.obtenerConexion();
        cn.setAutoCommit(false); // Iniciar transacción
        
        // Ejecutar 1: Ocultar el defecto
        try (PreparedStatement ps1 = cn.prepareStatement(sqlDefecto)) {
            ps1.setInt(1, idDefecto);
            ps1.executeUpdate();
        }
        
        // Ejecutar 2: Actualizar el número de piezas completadas
        try (PreparedStatement ps2 = cn.prepareStatement(sqlCarga)) {
            ps2.setInt(1, idDefecto);
            ps2.executeUpdate();
        }
        
        cn.commit(); // Confirmar cambios
    } catch (SQLException e) {
        if (cn != null) cn.rollback();
        throw e;
    } finally {
        if (cn != null) { cn.setAutoCommit(true); cn.close(); }
    }
}
    public void actualizarObservacionYEstado(int idDefecto, String observaciones) throws SQLException {
    String sql = "UPDATE defectos_reproceso SET estado = 'REGISTRADO', observaciones = ? WHERE id_defecto = ?";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setString(1, observaciones != null ? observaciones : "");
        ps.setInt(2, idDefecto);
        ps.executeUpdate();
    }
}
    // ── Inner class DTO para dashboard ────────────────────────
    public static class ResumenReprocesos {
        private int idMaquinista;
        private String nombreMaquinista;
        private String especialidad;
        private int totalReprocesos;
        private int reprocesosHistorico;

        public int getIdMaquinista() { return idMaquinista; }
        public void setIdMaquinista(int v) { this.idMaquinista = v; }
        public String getNombreMaquinista() { return nombreMaquinista; }
        public void setNombreMaquinista(String v) { this.nombreMaquinista = v; }
        public String getEspecialidad() { return especialidad; }
        public void setEspecialidad(String v) { this.especialidad = v; }
        public int getTotalReprocesos() { return totalReprocesos; }
        public void setTotalReprocesos(int v) { this.totalReprocesos = v; }
        public int getReprocesosHistorico() { return reprocesosHistorico; }
        public void setReprocesosHistorico(int v) { this.reprocesosHistorico = v; }
    }
}
