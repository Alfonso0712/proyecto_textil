package controlador;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import modelo.ConexionDB;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * HorarioScheduler — Controlador de horario automático de trabajadores.
 *
 * Lógica:
 *  - Cada minuto revisa la hora actual (zona horaria Lima, Peru: America/Lima)
 *  - A las 07:00 AM exactas → activa todos los usuarios que NO son ADMINISTRADOR
 *  - A las 17:00 (5:00 PM) exactas → desactiva todos los usuarios que NO son ADMINISTRADOR
 *
 * Los ADMINISTRADORES nunca son tocados por este scheduler.
 *
 * Al arrancar el servidor también ejecuta una verificación inmediata:
 *  - Si la hora actual está dentro del horario (7:00 - 17:00) activa trabajadores
 *  - Si está fuera del horario los desactiva
 * Esto garantiza el estado correcto aunque el servidor se reinicie.
 */
@WebListener
public class HorarioScheduler implements ServletContextListener {

    private static final Logger LOG = Logger.getLogger(HorarioScheduler.class.getName());

    // Horario del taller: 07:00 - 17:00
    private static final LocalTime HORA_INICIO = LocalTime.of(7, 0);
    private static final LocalTime HORA_FIN    = LocalTime.of(17, 0);

    // Zona horaria de Peru
    private static final ZoneId ZONA = ZoneId.of("America/Lima");

    // Nombre del rol que NO tiene restricción de horario
    private static final String ROL_ADMIN = "ADMINISTRADOR";

    private ScheduledExecutorService scheduler;

    // ── Inicio del servidor ───────────────────────────────────

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        LOG.info("[HorarioScheduler] Iniciando scheduler de horario de trabajadores...");

        // 1. Aplicar estado correcto inmediatamente al arrancar
        aplicarEstadoSegunHoraActual();

        // 2. Lanzar tarea periódica cada 60 segundos para revisar
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "HorarioScheduler-Thread");
            t.setDaemon(true); // No bloquea el apagado del servidor
            return t;
        });

        scheduler.scheduleAtFixedRate(
            this::revisarYAplicarHorario,
            60,   // espera 60 seg antes de la primera ejecución periódica
            60,   // repite cada 60 segundos
            TimeUnit.SECONDS
        );

        LOG.info("[HorarioScheduler] Scheduler activo. Horario: "
                + HORA_INICIO + " - " + HORA_FIN + " (" + ZONA.getId() + ")");
    }

    // ── Cierre del servidor ───────────────────────────────────

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null && !scheduler.isShutdown()) {
            scheduler.shutdownNow();
            LOG.info("[HorarioScheduler] Scheduler detenido.");
        }
    }

    // ── Lógica principal ──────────────────────────────────────

    /**
     * Revisa la hora actual y, si coincide con la hora de inicio o fin,
     * ejecuta la activación o desactivación de todos los trabajadores.
     * Se ejecuta cada 60 segundos.
     */
    private void revisarYAplicarHorario() {
        try {
            LocalTime ahora  = LocalTime.now(ZONA);
            DayOfWeek diaSem = LocalDate.now(ZONA).getDayOfWeek();
            boolean   esDomingo = (diaSem == DayOfWeek.SUNDAY);

            if (esDomingo) {
                // Domingo: asegurar que todos estén desactivados
                actualizarEstadoTrabajadores(false);
                return;
            }

            // Lunes a Sábado: activar a las 07:00, desactivar a las 17:00
            if (esMismoMinuto(ahora, HORA_INICIO)) {
                LOG.info("[HorarioScheduler] Son las 07:00 (" + diaSem + ") → Activando trabajadores...");
                int afectados = actualizarEstadoTrabajadores(true);
                LOG.info("[HorarioScheduler] Trabajadores activados: " + afectados);

            } else if (esMismoMinuto(ahora, HORA_FIN)) {
                LOG.info("[HorarioScheduler] Son las 17:00 (" + diaSem + ") → Desactivando trabajadores...");
                int afectados = actualizarEstadoTrabajadores(false);
                LOG.info("[HorarioScheduler] Trabajadores desactivados: " + afectados);
            }

        } catch (Exception e) {
            LOG.log(Level.WARNING, "[HorarioScheduler] Error en revisión periódica", e);
        }
    }

    /**
     * Al arrancar el servidor, aplica el estado correcto según la hora actual.
     * - Si es horario laboral (7:00 <= ahora < 17:00) → activa
     * - Si está fuera → desactiva
     */
    private void aplicarEstadoSegunHoraActual() {
        try {
            LocalTime   ahora  = LocalTime.now(ZONA);
            DayOfWeek   diaSem = LocalDate.now(ZONA).getDayOfWeek();
            boolean     esDomingo      = (diaSem == DayOfWeek.SUNDAY);
            boolean     esHorarioLaboral = !esDomingo
                                        && !ahora.isBefore(HORA_INICIO)
                                        && ahora.isBefore(HORA_FIN);

            LOG.info("[HorarioScheduler] Hora actual (" + ZONA.getId() + "): " + ahora
                    + " | Día: " + diaSem
                    + " → " + (esHorarioLaboral ? "HORARIO LABORAL" : "FUERA DE HORARIO/DOMINGO"));

            int afectados = actualizarEstadoTrabajadores(esHorarioLaboral);
            LOG.info("[HorarioScheduler] Usuarios " + (esHorarioLaboral ? "activados" : "desactivados")
                    + " al arrancar: " + afectados);

        } catch (Exception e) {
            LOG.log(Level.WARNING, "[HorarioScheduler] Error al aplicar estado inicial", e);
        }
    }

    /**
     * Actualiza el campo 'activo' de todos los usuarios que NO son ADMINISTRADOR.
     *
     * @param activar true = activar (activo=1), false = desactivar (activo=0)
     * @return número de filas afectadas
     */
    private int actualizarEstadoTrabajadores(boolean activar) throws SQLException {
        // Solo afecta a usuarios cuyo rol NO sea ADMINISTRADOR
        String sql = """
                UPDATE usuarios u
                   JOIN roles r ON u.id_rol = r.id_rol
                SET u.activo = ?
                WHERE r.nombre_rol != ?
                """;

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setBoolean(1, activar);
            ps.setString(2, ROL_ADMIN);
            return ps.executeUpdate();
        }
    }

    /**
     * Compara si dos LocalTime son el mismo minuto (hora y minuto iguales).
     * Permite que el check de cada 60s capture el momento exacto.
     */
    private boolean esMismoMinuto(LocalTime a, LocalTime b) {
        return a.getHour() == b.getHour() && a.getMinute() == b.getMinute();
    }
}
