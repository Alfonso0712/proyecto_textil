package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: asignaciones_carga
 * HU05: Distribución de Cargas de Trabajo
 *
 * Implementa:
 *   - Listar fases pendientes de asignación con su estado de fase previa (para bloqueo)
 *   - Insertar asignación y cambiar estado de la fase a EN_PROCESO
 *   - Listar maquinistas disponibles según especialidad requerida
 *   - Obtener resumen de carga por maquinista
 *
 * Tablas relacionadas:
 *   asignaciones_carga → orden_trabajo, piezas_modelo, fases_produccion, usuarios
 */
public class AsignacionCargaDAO {

    // ── Listar fases pendientes con contexto de bloqueo ──────
    /**
     * Devuelve todas las fases de las OTs activas que aún no tienen maquinista
     * asignado, incluyendo el estado de la fase previa para implementar el
     * bloqueo de la HU05.
     */
    public List<AsignacionCarga> listarFasesPendientes() throws SQLException {
        String sql = """
            WITH asignaciones_con_prev AS (
                SELECT 
                    ac.id_asignacion, ac.id_ot, ac.id_pieza, ac.id_fase, 
                    ac.id_maquinista, ac.estado_fase, ac.fecha_asignacion,
                    ac.cantidad_piezas, ac.piezas_completadas, ac.tipo_tarea,
                    LAG(ac.id_fase) OVER (PARTITION BY ac.id_ot, ac.id_pieza ORDER BY fp.orden) AS id_fase_previa
                FROM asignaciones_carga ac
                JOIN fases_produccion fp ON ac.id_fase = fp.id_fase
                WHERE ac.estado_fase IN ('PENDIENTE', 'EN_PROCESO', 'COMPLETADA')
            )
            SELECT DISTINCT 
                ac.id_asignacion, ac.id_ot, ac.id_pieza, ac.id_fase, ac.id_maquinista,
                ac.estado_fase, ac.fecha_asignacion, ac.cantidad_piezas, ac.piezas_completadas,
                ot.codigo_ot, 
                ot.fecha_crea, 
                mp.nombre AS nombre_modelo, 
                pm.nombre_pieza,
                fp.nombre AS nombre_fase,
                fp.orden, -- 🌟 AÑADIDO: Ahora 'orden' está en el SELECT
                ac_prev.estado_fase AS fase_previa_estado,
                CONCAT(u.nombre, ' ', u.apellido) AS nombre_maquinista,
                ac.tipo_tarea
            FROM asignaciones_con_prev ac
            JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot
            JOIN modelos_prenda mp ON ot.id_modelo = mp.id_modelo
            LEFT JOIN piezas_modelo pm ON ac.id_pieza = pm.id_pieza
            JOIN fases_produccion fp ON ac.id_fase = fp.id_fase
            LEFT JOIN asignaciones_carga ac_prev
                   ON ac_prev.id_ot    = ac.id_ot
                  AND ac_prev.id_pieza = ac.id_pieza
                  AND ac_prev.id_fase  = ac.id_fase_previa
                  AND ac_prev.tipo_tarea = 'NORMAL' 
            LEFT JOIN usuarios u ON ac.id_maquinista = u.id_usuario
            WHERE ac.estado_fase IN ('PENDIENTE', 'EN_PROCESO', 'COMPLETADA')
            ORDER BY ot.fecha_crea DESC, pm.nombre_pieza, fp.orden
            """;
        
        List<AsignacionCarga> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }

    // ── Generar asignaciones al pasar OT a EN_PROCESO ─────────
    /**
     * Crea una fila PENDIENTE por cada combinación (pieza × fase)
     * del modelo de la OT. Se llama cuando el estado cambia a EN_PROCESO.
     * INSERT IGNORE sobre la UNIQUE KEY → idempotente (seguro llamar varias veces).
     * @return número de filas insertadas
     */
    public int generarAsignaciones(int idOt) throws SQLException {
        String sql = """
        INSERT IGNORE INTO asignaciones_carga
                (id_ot, id_pieza, id_fase, estado_fase, cantidad_piezas)
            SELECT 
                ot.id_ot, 
                prf.id_pieza, 
                prf.id_fase, 
                'PENDIENTE',
                ot.cantidad_est * pm.cantidad
            FROM orden_trabajo ot
            JOIN piezas_modelo pm ON pm.id_modelo = ot.id_modelo
            JOIN pieza_ruta_fase prf ON prf.id_pieza = pm.id_pieza
            WHERE ot.id_ot = ?
            ORDER BY pm.id_pieza, prf.id_fase
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idOt);
            return ps.executeUpdate();
        }
    }

    // ── Listar maquinistas disponibles por especialidad ──────
    /**
     * Devuelve los maquinistas activos que tienen la especialidad requerida
     * para la fase indicada.
     * @param nombreFase nombre de la fase (ej: "Orillado")
     */
    public List<Usuario> listarMaquinistasPorEspecialidad(String nombreFase) throws SQLException {
        String sql = """
            SELECT DISTINCT u.id_usuario, u.nombre, u.apellido, u.email, u.activo,
                            u.id_rol, u.username, u.horario_restringido,
                            u.horario_dias, u.horario_inicio, u.horario_fin,
                            r.nombre AS nombre_rol
            FROM usuarios u
            JOIN usuario_especialidad ue ON u.id_usuario = ue.id_usuario
            JOIN especialidades e ON ue.id_especialidad = e.id_especialidad
            JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.activo = TRUE
              AND u.id_rol = 6
              AND LOWER(e.nombre) LIKE LOWER(?)
            ORDER BY u.nombre, u.apellido
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, "%" + nombreFase + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearUsuario(rs));
                }
            }
        }
        return lista;
    }

    // ── Asignar maquinista a una fase ─────────────────────────
    /**
     * Asigna el maquinista a la fase indicada y cambia su estado a EN_PROCESO.
     * Verifica que la fase previa esté COMPLETADA antes de proceder (HU05).
     * @return true si la asignación fue exitosa
     */
    public boolean asignarMaquinista(int idAsignacion, int idMaquinista) throws SQLException {
        // Verificar que la fase previa esté completa
        if (!fasePreviaCompleta(idAsignacion)) {
            return false; // Bloqueo activo
        }
        String sql = """
            UPDATE asignaciones_carga
               SET id_maquinista   = ?,
                   estado_fase     = 'EN_PROCESO',
                   fecha_asignacion = NOW()
             WHERE id_asignacion  = ?
               AND estado_fase    = 'PENDIENTE'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idMaquinista);
            ps.setInt(2, idAsignacion);
            return ps.executeUpdate() > 0;
        }
    }

    // ── Completar una fase → desbloquea la siguiente ──────────
    /**
     * Marca la fase como COMPLETADA y registra la fecha.
     * Esto desbloquea la fase de orden+1 para la misma (id_ot, id_pieza).
     * @return true si el UPDATE afectó exactamente una fila
     */
    public boolean completarFase(int idAsignacion, int piezasCompletadas) throws SQLException {
        String sql = """
            UPDATE asignaciones_carga
               SET estado_fase      = 'COMPLETADA',
                   fecha_completado = NOW(),
                   piezas_completadas = ?
             WHERE id_asignacion = ?
               AND estado_fase   = 'EN_PROCESO'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, piezasCompletadas);
            ps.setInt(2, idAsignacion);
            return ps.executeUpdate() > 0;
        }
    }
    
    /**
 * Crea una tarea de reposición en asignaciones_carga vinculada a la tarea original.
 * 
 * Reglas:
 *  - tipo_tarea = 'REPOSICION'
 *  - id_asignacion_padre = idAsignacionOriginal
 *  - estado_fase = 'PENDIENTE' (el supervisor la asignará)
 *  - id_maquinista = NULL (sin asignar)
 *  - cantidad_piezas = cantidadAReponer (las que faltan)
 *
 * @param idAsignacionOriginal  id de la fila original con déficit
 * @param cantidadAReponer      piezas que faltan y se deben fabricar
 * @return id de la nueva tarea de reposición creada, o -1 si ya existe una activa
 */
// Versión pública: crea una nueva conexión y ejecuta la reposición
public int crearTareaReposicion(int idAsignacionOriginal, int cantidadAReponer) throws SQLException {
    try (Connection cn = ConexionDB.obtenerConexion()) {
        // Usamos autocommit true para evitar transacciones largas
        cn.setAutoCommit(true);
        return crearTareaReposicion(cn, idAsignacionOriginal, cantidadAReponer);
    }
}

// Versión interna: recibe una conexión (para ser usada dentro de una transacción si es necesario)
public int crearTareaReposicion(Connection cn, int idAsignacionOriginal, int cantidadAReponer) throws SQLException {
    // 1. Verificar que no exista ya una reposición activa para este padre
    String sqlCheck = """
        SELECT COUNT(*) FROM asignaciones_carga
        WHERE id_asignacion_padre = ? AND tipo_tarea = 'REPOSICION'
          AND estado_fase IN ('PENDIENTE', 'EN_PROCESO')
        """;
    try (PreparedStatement psCheck = cn.prepareStatement(sqlCheck)) {
        psCheck.setInt(1, idAsignacionOriginal);
        try (ResultSet rs = psCheck.executeQuery()) {
            if (rs.next() && rs.getInt(1) > 0) {
                return -1;
            }
        }
    }

    // 2. Obtener la asignación original
    AsignacionCarga original = obtenerPorId(cn, idAsignacionOriginal);
    if (original == null) {
        throw new SQLException("Asignación original no encontrada: " + idAsignacionOriginal);
    }

    // 3. Insertar la tarea de reposición
    String sqlInsert = """
        INSERT INTO asignaciones_carga
            (id_ot, id_pieza, id_fase, id_maquinista, estado_fase,
             cantidad_piezas, piezas_completadas, tipo_tarea, id_asignacion_padre)
        VALUES (?, ?, ?, NULL, 'PENDIENTE', ?, 0, 'REPOSICION', ?)
        """;
    try (PreparedStatement ps = cn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
        ps.setInt(1, original.getIdOt());
        ps.setInt(2, original.getIdPieza());
        ps.setInt(3, original.getIdFase());
        ps.setInt(4, cantidadAReponer);
        ps.setInt(5, idAsignacionOriginal);
        ps.executeUpdate();
        try (ResultSet rs = ps.getGeneratedKeys()) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        }
    }
    return -1;
}
    
/**
 * Crea la tarea de ENSAMBLAJE para una OT cuando todas las fases de piezas
 * están completadas (incluyendo reposiciones). Se llama automáticamente desde
 * verificarYFinalizarOT cuando las piezas están listas pero falta ensamblaje.
 *
 * @param idOt          OT a la que se le crea el ensamblaje
 * @param cantidadMeta  cantidad_est de la OT (meta de prendas)
 * @return id de la tarea de ensamblaje creada, o -1 si ya existe
 */
public int crearTareaEnsamblaje(int idOt, int cantidadMeta) throws SQLException {
    // Verificar que no exista ya una tarea de ensamblaje para esta OT
    String sqlCheck = "SELECT id_asignacion FROM asignaciones_carga WHERE id_ot = ? AND tipo_tarea = 'ENSAMBLAJE'";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sqlCheck)) {
        ps.setInt(1, idOt);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id_asignacion"); // Ya existe
        }
    }

    String sqlInsert = """
        INSERT INTO asignaciones_carga
            (id_ot, id_pieza, id_fase, id_maquinista, estado_fase,
             cantidad_piezas, tipo_tarea)
        VALUES (?, NULL, 6, NULL, 'PENDIENTE', ?, 'ENSAMBLAJE')
        """;
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
        ps.setInt(1, idOt);
        ps.setInt(2, cantidadMeta);
        ps.executeUpdate();
        try (ResultSet keys = ps.getGeneratedKeys()) {
            if (keys.next()) return keys.getInt(1);
        }
    }
    return -1;
}
    // ── Verificar si la fase previa está completa ─────────────
    private boolean fasePreviaCompleta(int idAsignacion) throws SQLException {
        String sql = """
            SELECT ac_prev.estado_fase
            FROM asignaciones_carga ac
            JOIN fases_produccion fp      ON ac.id_fase   = fp.id_fase
            LEFT JOIN fases_produccion fp_prev ON fp_prev.orden = fp.orden - 1
            LEFT JOIN asignaciones_carga ac_prev
                   ON ac_prev.id_ot    = ac.id_ot
                  AND ac_prev.id_pieza = ac.id_pieza
                  AND ac_prev.id_fase  = fp_prev.id_fase
            WHERE ac.id_asignacion = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idAsignacion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String estadoPrev = rs.getString("estado_fase");
                    // Si no hay fase previa (primera fase), siempre permitido
                    return estadoPrev == null || "COMPLETADA".equalsIgnoreCase(estadoPrev);
                }
            }
        }
        return true; // Sin fase previa: primera fase → permitida
    }
    /**
 * Motor de Integridad y Cierre de OT.
 *
 * Resultado posible:
 *   "PIEZAS_PENDIENTES"   → Hay fases de piezas (NORMAL o REPOSICION) sin completar.
 *   "ENSAMBLAJE_CREADO"   → Todas las piezas listas. Se creó la tarea de ensamblaje.
 *   "ENSAMBLAJE_PENDIENTE"→ La tarea de ensamblaje existe pero no está completada.
 *   "OT_FINALIZADA"       → Todo completado. OT pasó a FINALIZADA y se creó conciliación.
 *   "ERROR"               → Fallo inesperado.
 *
 * @param idOt  ID de la orden de trabajo a evaluar
 * @return String con el resultado del motor
 */
public String verificarYFinalizarOT(int idOt) throws SQLException {
    try (Connection cn = ConexionDB.obtenerConexion()) {
        cn.setAutoCommit(false); // Transacción
        try {
            // ── PASO 1: ¿Hay tareas de PIEZAS (NORMAL o REPOSICION) sin completar? ──
            String sqlPiezasPendientes = """
                SELECT COUNT(*) FROM asignaciones_carga
                WHERE id_ot = ?
                  AND tipo_tarea IN ('NORMAL', 'REPOSICION')
                  AND estado_fase NOT IN ('COMPLETADA')
                """;
            try (PreparedStatement ps = cn.prepareStatement(sqlPiezasPendientes)) {
                ps.setInt(1, idOt);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        cn.rollback();
                        return "PIEZAS_PENDIENTES"; // Bloqueo: no se puede ensamblar
                    }
                }
            }

            // ── PASO 2: ¿Existe tarea de ENSAMBLAJE? ──
            String sqlEnsamblaje = """
                SELECT id_asignacion, estado_fase, piezas_completadas, cantidad_piezas
                FROM asignaciones_carga
                WHERE id_ot = ? AND tipo_tarea = 'ENSAMBLAJE'
                """;
            try (PreparedStatement ps = cn.prepareStatement(sqlEnsamblaje)) {
                ps.setInt(1, idOt);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        // No existe → crearla automáticamente
                        cn.commit();
                        // Obtener cantidad_est de la OT
                        int cantidadEst = obtenerCantidadEst(idOt);
                        crearTareaEnsamblaje(idOt, cantidadEst);
                        return "ENSAMBLAJE_CREADO";
                    }

                    String estadoEnsamblaje = rs.getString("estado_fase");
                    int piezasCompletadas = rs.getInt("piezas_completadas");
                    int cantidadPiezas = rs.getInt("cantidad_piezas");
                    int idAsignEnsamblaje = rs.getInt("id_asignacion");

                    if (!"COMPLETADA".equals(estadoEnsamblaje)) {
                        cn.rollback();
                        return "ENSAMBLAJE_PENDIENTE"; // Supervisor/Maquinista debe completar
                    }

                    // ── PASO 3: Ensamblaje completado → FINALIZAR OT ──
                    String sqlFinalizar = "UPDATE orden_trabajo SET estado = 'FINALIZADA' WHERE id_ot = ? AND estado != 'FINALIZADA'";
                    try (PreparedStatement psFin = cn.prepareStatement(sqlFinalizar)) {
                        psFin.setInt(1, idOt);
                        int filasAfectadas = psFin.executeUpdate();

                        if (filasAfectadas > 0) {
                            // ── PASO 4: Crear registro en conciliacion_despacho ──
                            int cantidadEst = obtenerCantidadEst(idOt);
                            int diferencia = piezasCompletadas - cantidadEst;

                            String sqlConciliar = """
                                INSERT IGNORE INTO conciliacion_despacho
                                    (id_ot, cantidad_final, diferencia, estado,
                                     id_responsable, cantidad_ensamblaje, id_asignacion_ensamblaje)
                                SELECT
                                    ?, ?, ?, 'PENDIENTE',
                                    id_responsable, ?, ?
                                FROM orden_trabajo WHERE id_ot = ?
                                """;
                            try (PreparedStatement psCon = cn.prepareStatement(sqlConciliar)) {
                                psCon.setInt(1, idOt);
                                psCon.setInt(2, piezasCompletadas);   // cantidad_final = lo producido en ensamblaje
                                psCon.setInt(3, diferencia);           // negativo = merma
                                psCon.setInt(4, piezasCompletadas);   // cantidad_ensamblaje (campo nuevo)
                                psCon.setInt(5, idAsignEnsamblaje);
                                psCon.setInt(6, idOt);
                                psCon.executeUpdate();
                            }
                        }
                    }
                    cn.commit();
                    return "OT_FINALIZADA";
                }
            }
        } catch (SQLException e) {
            cn.rollback();
            throw e;
        } finally {
            cn.setAutoCommit(true);
        }
    }
}
private void finalizarOTYRegistrarDespacho(int idOt, int totalProd, int meta) throws SQLException {
    Connection cn = ConexionDB.obtenerConexion();
    try {
        cn.setAutoCommit(false);
        
        // 1. Finalizar OT
        try (PreparedStatement ps = cn.prepareStatement("UPDATE orden_trabajo SET estado = 'FINALIZADA' WHERE id_ot = ?")) {
            ps.setInt(1, idOt);
            ps.executeUpdate();
        }
        
        // 2. Insertar en Despacho
        String sqlDesp = """
            INSERT INTO conciliacion_despacho 
            (id_ot, cantidad_final, cantidad_estimada, diferencia, estado, id_responsable) 
            VALUES (?, ?, ?, ?, 'PENDIENTE', ?)
            """;
        try (PreparedStatement ps = cn.prepareStatement(sqlDesp)) {
            ps.setInt(1, idOt);
            ps.setInt(2, totalProd);
            ps.setInt(3, meta);
            ps.setInt(4, (totalProd - meta)); // Diferencia
            ps.setInt(5, 1); // ID del usuario administrador o sistema
            ps.executeUpdate();
        }
        
        cn.commit();
    } catch (SQLException e) {
        cn.rollback();
        throw e;
    } finally {
        cn.setAutoCommit(true);
        cn.close();
    }
}
// Helper privado
private int obtenerCantidadEst(int idOt) throws SQLException {
    String sql = "SELECT cantidad_est FROM orden_trabajo WHERE id_ot = ?";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idOt);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
    }
    return 0;
}

/**
 * Suma las piezas_completadas de la tarea original + todas sus reposiciones.
 * Usado para validar si se alcanzó la meta antes de habilitar el Ensamblaje.
 *
 * @param idAsignacionOriginal  ID de la tarea original (tipo_tarea = 'NORMAL')
 * @return suma de piezas completadas (original + todas sus reposiciones completadas)
 */
public int sumarPiezasCompletadasConReposiciones(int idAsignacionOriginal) throws SQLException {
    String sql = """
        SELECT COALESCE(SUM(piezas_completadas), 0) AS total
        FROM asignaciones_carga
        WHERE (id_asignacion = ? OR id_asignacion_padre = ?)
          AND estado_fase = 'COMPLETADA'
        """;
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idAsignacionOriginal);
        ps.setInt(2, idAsignacionOriginal);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("total");
        }
    }
    return 0;
}
    // ── Contar cargas activas por maquinista ──────────────────
    /**
     * Retorna el número de fases EN_PROCESO asignadas a cada maquinista.
     * Usado para el dashboard de distribución de carga.
     */
    public List<ResumenCargaMaquinista> resumenCargaPorMaquinista() throws SQLException {
        String sql = """
            SELECT u.id_usuario,
                   CONCAT(u.nombre, ' ', u.apellido) AS nombre_maquinista,
                   e.nombre AS especialidad,
                   COUNT(ac.id_asignacion) AS total_activas
            FROM usuarios u
            JOIN roles r ON u.id_rol = r.id_rol
            LEFT JOIN usuario_especialidad ue ON u.id_usuario = ue.id_usuario
            LEFT JOIN especialidades e ON ue.id_especialidad = e.id_especialidad
            LEFT JOIN asignaciones_carga ac
                   ON ac.id_maquinista = u.id_usuario
                  AND ac.estado_fase = 'EN_PROCESO'
            WHERE u.id_rol = 6 AND u.activo = TRUE
            GROUP BY u.id_usuario, nombre_maquinista, especialidad
            ORDER BY total_activas DESC
            """;
        List<ResumenCargaMaquinista> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ResumenCargaMaquinista r = new ResumenCargaMaquinista();
                r.setIdMaquinista(rs.getInt("id_usuario"));
                r.setNombreMaquinista(rs.getString("nombre_maquinista"));
                r.setEspecialidad(rs.getString("especialidad"));
                r.setTotalActivas(rs.getInt("total_activas"));
                lista.add(r);
            }
        }
        return lista;
    }

    // ── Mapeo ResultSet → AsignacionCarga ─────────────────────
    private AsignacionCarga mapear(ResultSet rs) throws SQLException {
        // Dentro de mapear(ResultSet rs):

        AsignacionCarga a = new AsignacionCarga();
        a.setIdAsignacion(rs.getInt("id_asignacion"));
        a.setIdOt(rs.getInt("id_ot"));
        a.setIdPieza(rs.getInt("id_pieza"));
        a.setIdFase(rs.getInt("id_fase"));
        a.setIdMaquinista(rs.getInt("id_maquinista"));
        a.setCantidadPiezas(rs.getInt("cantidad_piezas"));
        a.setPiezasCompletadas(rs.getInt("piezas_completadas"));
        String est = rs.getString("estado_fase");
        if (est != null) {
            try { a.setEstadoFase(AsignacionCarga.EstadoFase.valueOf(est)); }
            catch (IllegalArgumentException e) { a.setEstadoFase(AsignacionCarga.EstadoFase.PENDIENTE); }
        }
        a.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
        a.setCodigoOt(rs.getString("codigo_ot"));
        a.setNombreModelo(rs.getString("nombre_modelo"));
        a.setNombrePieza(rs.getString("nombre_pieza"));
        a.setNombreFase(rs.getString("nombre_fase"));
        a.setFasePreviaEstado(rs.getString("fase_previa_estado"));
        a.setNombreMaquinista(rs.getString("nombre_maquinista"));
        try { a.setTipoTarea(rs.getString("tipo_tarea")); } catch (Exception e) { /* columna opcional */ }
        try { int padre = rs.getInt("id_asignacion_padre");
              if (!rs.wasNull()) a.setIdAsignacionPadre(padre); } catch (Exception e) {}
        //a.setEspecialidadMaquinista(rs.getString("especialidad_maquinista"));
        return a;
    }

    private Usuario mapearUsuario(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setIdUsuario(rs.getInt("id_usuario"));
        u.setNombre(rs.getString("nombre"));
        u.setApellido(rs.getString("apellido"));
        u.setEmail(rs.getString("email"));
        u.setActivo(rs.getBoolean("activo"));
        u.setIdRol(rs.getInt("id_rol"));
        u.setUsername(rs.getString("username"));
        u.setNombreRol(rs.getString("nombre_rol"));
        return u;
    }
    
    public List<AsignacionCarga> listarTareasPorMaquinista(int idMaquinista) throws SQLException {
        String sql = """
            SELECT 
                ac.id_asignacion,
                ac.id_ot,
                ac.id_pieza,
                ac.id_fase,
                ac.id_maquinista,
                ac.estado_fase,
                ac.fecha_asignacion,
                ac.fecha_completado,
                ac.cantidad_piezas,
                ac.piezas_completadas,
                ot.codigo_ot,
                pm.nombre_pieza,
                fp.nombre AS nombre_fase
            FROM asignaciones_carga ac
            JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot
            LEFT JOIN piezas_modelo pm ON ac.id_pieza = pm.id_pieza
            JOIN fases_produccion fp ON ac.id_fase = fp.id_fase
            WHERE ac.id_maquinista = ?
            AND ac.estado_fase = 'EN_PROCESO' 
            ORDER BY ac.fecha_asignacion DESC
            """;
            
        List<AsignacionCarga> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idMaquinista);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    AsignacionCarga a = new AsignacionCarga();
                    a.setIdAsignacion(rs.getInt("id_asignacion"));
                    a.setIdOt(rs.getInt("id_ot"));
                    a.setIdPieza(rs.getInt("id_pieza"));
                    a.setIdFase(rs.getInt("id_fase"));
                    a.setIdMaquinista(rs.getInt("id_maquinista"));
                    
                    // Manejo seguro del Enum
                    String estado = rs.getString("estado_fase");
                    if (estado != null) {
                        a.setEstadoFase(AsignacionCarga.EstadoFase.valueOf(estado));
                    }
                    
                    a.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
                    a.setFechaCompletado(rs.getTimestamp("fecha_completado"));
                    a.setCantidadPiezas(rs.getInt("cantidad_piezas"));
                    a.setPiezasCompletadas(rs.getInt("piezas_completadas"));
                    
                    a.setCodigoOt(rs.getString("codigo_ot"));
                    a.setNombrePieza(rs.getString("nombre_pieza"));
                    a.setNombreFase(rs.getString("nombre_fase"));
                    lista.add(a);
                }
            }
        }
        return lista;
    }
    public AsignacionCarga obtenerPorId(int idAsignacion) throws SQLException {
        String sql = """
            SELECT 
                ac.id_asignacion, ac.id_ot, ac.id_pieza, ac.id_fase, 
                ac.id_maquinista, ac.cantidad_piezas, ac.piezas_completadas,
                ot.codigo_ot, pm.nombre_pieza, fp.nombre AS nombre_fase
            FROM asignaciones_carga ac
            JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot
            LEFT JOIN piezas_modelo pm ON ac.id_pieza = pm.id_pieza
            JOIN fases_produccion fp ON ac.id_fase = fp.id_fase
            WHERE ac.id_asignacion = ?
        """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idAsignacion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    AsignacionCarga a = new AsignacionCarga();
                    a.setIdAsignacion(rs.getInt("id_asignacion"));
                    a.setIdOt(rs.getInt("id_ot"));
                    a.setIdPieza(rs.getInt("id_pieza"));
                    a.setIdFase(rs.getInt("id_fase"));
                    a.setIdMaquinista(rs.getInt("id_maquinista"));
                    a.setCantidadPiezas(rs.getInt("cantidad_piezas"));
                    a.setPiezasCompletadas(rs.getInt("piezas_completadas"));
                    a.setCodigoOt(rs.getString("codigo_ot"));
                    a.setNombrePieza(rs.getString("nombre_pieza"));
                    a.setNombreFase(rs.getString("nombre_fase"));
                    return a;
                }
            }
        }
        return null;
    }
    public AsignacionCarga obtenerPorId(
        Connection cn,
        int idAsignacion
) throws SQLException {

    String sql = """
        SELECT *
        FROM asignaciones_carga
        WHERE id_asignacion = ?
        """;

    try (PreparedStatement ps = cn.prepareStatement(sql)) {

        ps.setInt(1, idAsignacion);

        try (ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {

                AsignacionCarga a = new AsignacionCarga();

                a.setIdAsignacion(
                        rs.getInt("id_asignacion"));

                a.setIdOt(
                        rs.getInt("id_ot"));

                a.setIdPieza(
                        rs.getInt("id_pieza"));

                a.setIdFase(
                        rs.getInt("id_fase"));

                a.setCantidadPiezas(
                        rs.getInt("cantidad_piezas"));

                return a;
            }
        }
    }

    return null;
}
   public boolean existeReposicionActiva(int idAsignacionPadre) throws SQLException {
    String sql = """
        SELECT COUNT(*) FROM asignaciones_carga
        WHERE id_asignacion_padre = ? AND tipo_tarea = 'REPOSICION'
          AND estado_fase IN ('PENDIENTE', 'EN_PROCESO')
        """;
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idAsignacionPadre);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        }
    }
    return false;
}
    public List<AsignacionCarga> listarTareasCompletadasPorMaquinista(int idMaquinista) throws SQLException {
        // ✅ FIX: Usamos IN para incluir cualquier estado que signifique que la tarea ya terminó
        String sql = """
            SELECT 
                ac.id_asignacion,
                ac.id_ot,
                ac.id_pieza,
                ac.id_fase,
                ac.id_maquinista,
                ac.estado_fase,
                ac.fecha_asignacion,
                ac.fecha_completado,
                ac.cantidad_piezas,
                ac.piezas_completadas,
                ot.codigo_ot,
                pm.nombre_pieza,
                fp.nombre AS nombre_fase
            FROM asignaciones_carga ac
            JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot
            LEFT JOIN piezas_modelo pm ON ac.id_pieza = pm.id_pieza
            JOIN fases_produccion fp ON ac.id_fase = fp.id_fase
            WHERE ac.id_maquinista = ? 
            AND ac.estado_fase IN ('COMPLETADA', 'REGISTRADO')
            ORDER BY ac.fecha_completado DESC
            """;
            
        List<AsignacionCarga> lista = new ArrayList<>();
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idMaquinista);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    AsignacionCarga a = new AsignacionCarga();
                    a.setIdAsignacion(rs.getInt("id_asignacion"));
                    a.setIdOt(rs.getInt("id_ot"));
                    a.setIdPieza(rs.getInt("id_pieza"));
                    a.setIdFase(rs.getInt("id_fase"));
                    a.setIdMaquinista(rs.getInt("id_maquinista"));
                    
                    // Manejo del Enum
                    String estado = rs.getString("estado_fase");
                    if (estado != null) {
                        try {
                            a.setEstadoFase(AsignacionCarga.EstadoFase.valueOf(estado));
                        } catch (IllegalArgumentException e) {
                            // Si el estado no coincide con el Enum, ponemos uno por defecto o saltamos
                        }
                    }
                    
                    a.setFechaAsignacion(rs.getTimestamp("fecha_asignacion"));
                    a.setFechaCompletado(rs.getTimestamp("fecha_completado"));
                    a.setCantidadPiezas(rs.getInt("cantidad_piezas"));
                    a.setPiezasCompletadas(rs.getInt("piezas_completadas"));
                    
                    a.setCodigoOt(rs.getString("codigo_ot"));
                    a.setNombrePieza(rs.getString("nombre_pieza"));
                    a.setNombreFase(rs.getString("nombre_fase"));
                    lista.add(a);
                }
            }
        }
        return lista;
    }
    public boolean reasignarMaquinista(int idAsignacion, int idMaquinista) throws SQLException {
        String sql = """
            UPDATE asignaciones_carga
               SET id_maquinista   = ?,
                   fecha_asignacion = NOW()
             WHERE id_asignacion = ?
               AND estado_fase = 'EN_PROCESO'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idMaquinista);
            ps.setInt(2, idAsignacion);
            return ps.executeUpdate() > 0;
        }
    }
    // ── Inner class DTO para resumen de carga ─────────────────
    public static class ResumenCargaMaquinista {
        private int idMaquinista;
        private String nombreMaquinista;
        private String especialidad;
        private int totalActivas;

        public int getIdMaquinista() { return idMaquinista; }
        public void setIdMaquinista(int v) { this.idMaquinista = v; }
        public String getNombreMaquinista() { return nombreMaquinista; }
        public void setNombreMaquinista(String v) { this.nombreMaquinista = v; }
        public String getEspecialidad() { return especialidad; }
        public void setEspecialidad(String v) { this.especialidad = v; }
        public int getTotalActivas() { return totalActivas; }
        public void setTotalActivas(int v) { this.totalActivas = v; }
    }
}
