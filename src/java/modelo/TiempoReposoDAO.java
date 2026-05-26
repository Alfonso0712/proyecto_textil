package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO: tiempos_reposo
 * Ubicación: modelo/TiempoReposoDAO.java
 * HU03: Gestión de Tiempos de Reposo y Corte
 *
 * Operaciones:
 *   - listarTodos()               → Admin ve todos los registros
 *   - listarPorUsuario(idUsuario) → Jefe de producción ve solo los suyos
 *   - obtenerPorId(idReposo)      → Detalle para modal
 *   - registrarInicio(...)        → CUS 3.2: Registrar Inicio de Reposo
 *   - marcarAptoCorte(idReposo)   → CUS 3.3: Emitir Notificación de Aptitud
 *   - cancelar(idReposo)          → Cancelar reposo activo
 *   - listarTelasConReposo()      → Telas que requieren reposo (para el combo)
 *   - verificarYNotificar()       → Llamado por el temporizador/AJAX polling
 */
public class TiempoReposoDAO {

    // ─────────────────────────────────────────────────────────
    // LECTURA
    // ─────────────────────────────────────────────────────────

    /**
     * Lista TODOS los registros de reposo (uso Admin).
     */
    public List<TiempoReposo> listarTodos() throws SQLException {
        String sql = """
            SELECT tr.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
            FROM tiempos_reposo tr
            JOIN telas          t  ON tr.id_tela           = t.id_tela
            JOIN orden_trabajo  ot ON t.id_ot               = ot.id_ot
            JOIN usuarios       u  ON tr.id_usuario_inicio  = u.id_usuario
            ORDER BY tr.fecha_inicio DESC
            """;
        return ejecutarConsulta(sql);
    }

    /**
     * Lista registros de reposo iniciados por un usuario específico
     * (Jefe de producción ve solo los suyos).
     */
    public List<TiempoReposo> listarPorUsuario(int idUsuario) throws SQLException {
        String sql = """
            SELECT tr.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
            FROM tiempos_reposo tr
            JOIN telas          t  ON tr.id_tela           = t.id_tela
            JOIN orden_trabajo  ot ON t.id_ot               = ot.id_ot
            JOIN usuarios       u  ON tr.id_usuario_inicio  = u.id_usuario
            WHERE tr.id_usuario_inicio = ?
            ORDER BY tr.fecha_inicio DESC
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            return mapearResultados(ps.executeQuery());
        }
    }

    /**
     * Obtiene un registro por su ID.
     */
    public TiempoReposo obtenerPorId(int idReposo) throws SQLException {
        String sql = """
            SELECT tr.*, t.codigo_tela, t.tipo_tejido,
                   ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
            FROM tiempos_reposo tr
            JOIN telas          t  ON tr.id_tela           = t.id_tela
            JOIN orden_trabajo  ot ON t.id_ot               = ot.id_ot
            JOIN usuarios       u  ON tr.id_usuario_inicio  = u.id_usuario
            WHERE tr.id_reposo = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idReposo);
            List<TiempoReposo> lista = mapearResultados(ps.executeQuery());
            return lista.isEmpty() ? null : lista.get(0);
        }
    }

    /**
     * Retorna TODAS las telas registradas en el inventario (módulo Inventario).
     * Usada para llenar el combo al crear un nuevo reposo.
     * Se delega a TelaDAO para mantener consistencia con el módulo de inventario.
     */
    /**
    * Devuelve las telas del inventario que REQUIEREN REPOSO y que NUNCA han tenido un reposo registrado.
        */
      public List<Tela> listarTelasDisponiblesParaReposo() throws SQLException {
        String sql = """
            SELECT t.*, ot.codigo_ot, ct.tiempo_reposo
            FROM telas t
            JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
            LEFT JOIN catalogo_telas ct ON t.id_catalogo_tela = ct.id_catalogo
            WHERE t.requiere_reposo = true
              AND NOT EXISTS (
                  SELECT 1 FROM tiempos_reposo tr WHERE tr.id_tela = t.id_tela
              )
            ORDER BY t.fecha_ingreso DESC
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
                // ¡AQUÍ ESTÁ LA MAGIA! Guardamos el tiempo del catálogo (en minutos)
                t.setTiempoReposoCatalogo(rs.getInt("tiempo_reposo"));
                lista.add(t);
            }
        }
        return lista;
    }

    // ─────────────────────────────────────────────────────────
    // ESCRITURA
    // ─────────────────────────────────────────────────────────

    /**
     * CUS 3.2: Registrar Inicio de Reposo.
     * Inserta un nuevo registro y retorna el ID generado.
     *
     * @param idTela           ID de la tela que entra en reposo
     * @param idUsuario        ID del jefe de producción
     * @param duracionMinutos  Tiempo estimado de reposo
     * @param observaciones    Notas opcionales
     * @return ID del nuevo registro, o -1 si falló
     */
    public int registrarInicio(int idTela, int idUsuario,
                               int duracionMinutos, String observaciones)
            throws SQLException {
        String sql = """
            INSERT INTO tiempos_reposo
              (id_tela, id_usuario_inicio, fecha_inicio, duracion_minutos,
               estado, notificacion_enviada, observaciones)
            VALUES (?, ?, NOW(), ?, 'EN_REPOSO', 0, ?)
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql,
                     Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, idTela);
            ps.setInt(2, idUsuario);
            ps.setInt(3, duracionMinutos);
            ps.setString(4, observaciones);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        }
    }

    /**
     * CUS 3.3: Marcar tela como APTA PARA CORTE y emitir notificación.
     * Actualiza estado, fecha_fin_real y notificacion_enviada = 1.
     */
    public boolean marcarAptoCorte(int idReposo) throws SQLException {
        String sql = """
            UPDATE tiempos_reposo
            SET estado = 'APTO_CORTE',
                fecha_fin_real = NOW(),
                notificacion_enviada = 1
            WHERE id_reposo = ? AND estado = 'EN_REPOSO'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idReposo);
            return ps.executeUpdate() > 0;
        }
    }
    /**
    * Elimina un registro de reposo por su ID.
    * No hay restricciones de integridad referencial (ninguna tabla depende de tiempos_reposo).
    * @param idReposo ID del reposo a eliminar
    * @return true si se eliminó al menos una fila
    */
   public boolean eliminar(int idReposo) throws SQLException {
       String sql = "DELETE FROM tiempos_reposo WHERE id_reposo = ?";
       try (Connection cn = ConexionDB.obtenerConexion();
            PreparedStatement ps = cn.prepareStatement(sql)) {
           ps.setInt(1, idReposo);
           return ps.executeUpdate() > 0;
       }
   }
    /**
     * Cancela un reposo activo.
     */
    public boolean cancelar(int idReposo) throws SQLException {
        String sql = """
            UPDATE tiempos_reposo
            SET estado = 'CANCELADO'
            WHERE id_reposo = ? AND estado = 'EN_REPOSO'
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idReposo);
            return ps.executeUpdate() > 0;
        }
    }
    public boolean verificarTelaDisponibleParaReposo(int idTela) throws SQLException {
        String sql = """
            SELECT COUNT(*) FROM telas t
            WHERE t.id_tela = ? AND t.requiere_reposo = true
              AND NOT EXISTS (SELECT 1 FROM tiempos_reposo WHERE id_tela = t.id_tela)
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }
    /**
     * Verifica reposos cuyo tiempo ya venció y los marca como APTO_CORTE
     * automáticamente, emitiendo la notificación.
     * Llamado desde el servlet con polling AJAX.
     *
     * @return número de registros actualizados
     */
    public int verificarYNotificar() throws SQLException {
        String sql = """
            UPDATE tiempos_reposo
            SET estado = 'APTO_CORTE',
                fecha_fin_real = NOW(),
                notificacion_enviada = 1
            WHERE estado = 'EN_REPOSO'
              AND fecha_fin_estimada <= NOW()
              AND notificacion_enviada = 0
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            return ps.executeUpdate();
        }
    }

    // ─────────────────────────────────────────────────────────
    // HELPERS PRIVADOS
    // ─────────────────────────────────────────────────────────

    private List<TiempoReposo> ejecutarConsulta(String sql) throws SQLException {
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return mapearResultados(rs);
        }
    }

    private List<TiempoReposo> mapearResultados(ResultSet rs) throws SQLException {
        List<TiempoReposo> lista = new ArrayList<>();
        while (rs.next()) {
            TiempoReposo tr = new TiempoReposo();
            tr.setIdReposo(rs.getInt("id_reposo"));
            tr.setIdTela(rs.getInt("id_tela"));
            tr.setIdUsuarioInicio(rs.getInt("id_usuario_inicio"));
            tr.setFechaInicio(rs.getTimestamp("fecha_inicio"));
            tr.setDuracionMinutos(rs.getInt("duracion_minutos"));
            tr.setFechaFinEstimada(rs.getTimestamp("fecha_fin_estimada"));
            tr.setFechaFinReal(rs.getTimestamp("fecha_fin_real"));

            String estadoStr = rs.getString("estado");
            if (estadoStr != null) {
                tr.setEstado(TiempoReposo.Estado.valueOf(estadoStr));
            }
            tr.setNotificacionEnviada(rs.getBoolean("notificacion_enviada"));
            tr.setObservaciones(rs.getString("observaciones"));
            tr.setFechaCrea(rs.getTimestamp("fecha_crea"));

            // Campos de JOIN
            tr.setCodigoTela(rs.getString("codigo_tela"));
            tr.setTipoTejido(rs.getString("tipo_tejido"));
            tr.setCodigoOt(rs.getString("codigo_ot"));
            tr.setNombreRegistrador(rs.getString("nombre_registrador"));

            lista.add(tr);
        }
        return lista;
    }
}
