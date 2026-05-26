package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Set;

/**
 * Servlet: CargasTrabajoServlet
 * Ruta: /cargas-trabajo
 * HU05: Distribución de Cargas de Trabajo
 *
 * Diagrama de secuencia HU05:
 *   Supervisor → UI → VerificarFasePrevia → ConsultarMaquinistasDisponibles
 *              → ValidarEspecialidad → AsignarCarga → NotificarAsignacion
 *
 * Permisos requeridos:
 *   - PROD_CARGAS_ASIG → ver fases pendientes y asignar maquinistas
 */
@WebServlet("/cargas-trabajo")
public class CargasTrabajoServlet extends HttpServlet {

    private final AsignacionCargaDAO cargaDAO   = new AsignacionCargaDAO();
    private final UsuarioDAO          usuarioDAO = new UsuarioDAO();

    // ── GET ───────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // Si es maquinista (rol 6), mostrar su vista personal sin verificar permiso PROD_CARGAS_ASIG
        if (usuario.getIdRol() == 6) {
            try {
                List<AsignacionCarga> tareasEnProceso = cargaDAO.listarTareasPorMaquinista(usuario.getIdUsuario());
                List<AsignacionCarga> tareasCompletadas = cargaDAO.listarTareasCompletadasPorMaquinista(usuario.getIdUsuario());

                req.setAttribute("tareas", tareasEnProceso);
                req.setAttribute("tareasCompletadas", tareasCompletadas);
                req.getRequestDispatcher("/vista/mis_tareas.jsp").forward(req, resp);
                return; // ✅ Correcto: Termina la ejecución aquí

            } catch (Exception e) { 
                e.printStackTrace(); 
                // ✅ FIX: Evitar IllegalStateException verificando isCommitted()
                if (!resp.isCommitted()) {
                    resp.sendRedirect(req.getContextPath() + "/dashboard?error=errorCargaDatos");
                }
                return; // ✅ FIX: ¡Te faltaba este return! Si hay error, no debe seguir bajando.
            }
        }

        // Para otros roles (SUPERVISOR, ADMIN, etc.) se requiere el permiso
        if (!tienePermiso(req, "PROD_CARGAS_ASIG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        // Resto del código para supervisor (listar fases pendientes, etc.)
        try {
            List<AsignacionCarga> fases = cargaDAO.listarFasesPendientes();
            req.setAttribute("fasesPendientes", fases);
            
            List<AsignacionCargaDAO.ResumenCargaMaquinista> resumen = cargaDAO.resumenCargaPorMaquinista();
            req.setAttribute("resumenCarga", resumen);
            List<Usuario> maquinistas = usuarioDAO.listarPorRol(6);
            req.setAttribute("maquinistas", maquinistas);
            req.getRequestDispatcher("/vista/cargas_trabajo.jsp").forward(req, resp);
        } catch (SQLException e) {
            req.setAttribute("errorBD", "Error al cargar las fases: " + e.getMessage());
            req.getRequestDispatcher("/vista/cargas_trabajo.jsp").forward(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String accion = req.getParameter("accion");

        // Si es maquinista (rol 6), solo puede completar tareas
        if (usuario.getIdRol() == 6) {
            if ("completar".equals(accion)) {
                completarFase(req, resp);
            } else {
                resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            }
            return;
        }

        // Para otros roles (SUPERVISOR, ADMIN) se requiere el permiso PROD_CARGAS_ASIG
        if (!tienePermiso(req, "PROD_CARGAS_ASIG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        // Supervisor/Admin: puede asignar y completar
        // Supervisor/Admin: puede asignar, reasignar y completar
        if ("asignar".equals(accion)) {
            asignarMaquinista(req, resp);
        } else if ("reasignar".equals(accion)) {
            reasignarMaquinista(req, resp);
        } else if ("completar".equals(accion)) {
            completarFase(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo");
        }
    }

    // ── Completar fase → desbloquea la siguiente ──────────────
    /**
    * Marca una fase como COMPLETADA, registra las piezas completadas y desbloquea la siguiente fase.
    * Además, genera una notificación para los roles: ADMINISTRADOR, JEFE_PRODUCCION y SUPERVISOR.
    */
    // ... imports y resto del código igual ...

    private void completarFase(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String idAsignStr = req.getParameter("idAsignacion");
        String piezasStr = req.getParameter("piezasCompletadas");

        if (idAsignStr == null || idAsignStr.isBlank() || piezasStr == null || piezasStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=Parámetros+inválidos");
            return;
        }

        try {
            int idAsignacion = Integer.parseInt(idAsignStr);
            int piezasCompletadas = Integer.parseInt(piezasStr);

            Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
            if (usuario == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

            AsignacionCarga asignacion = cargaDAO.obtenerPorId(idAsignacion);
            if (asignacion == null) {
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=Tarea+no+encontrada");
                return;
            }

            // Verificar ownership si es maquinista
            if (usuario.getIdRol() == 6 && asignacion.getIdMaquinista() != usuario.getIdUsuario()) {
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=No+autorizado");
                return;
            }

            int cantidadMeta = asignacion.getCantidadPiezas();
            int diferencia = cantidadMeta - piezasCompletadas;

            // Si la cantidad completada es menor a la meta, crear defecto pendiente
            if (diferencia > 0) {
                DefectoReprocesoDAO defectoDAO = new DefectoReprocesoDAO();
                DefectoReproceso defecto = new DefectoReproceso();
                defecto.setIdOt(asignacion.getIdOt());
                defecto.setIdPieza(asignacion.getIdPieza());
                defecto.setIdMaquinista(asignacion.getIdMaquinista()); // maquinista responsable
                defecto.setTipoFalla(DefectoReproceso.TipoFalla.OTRO);
                defecto.setObservaciones("Producción incompleta reportada por el maquinista. Faltan " + diferencia + " unidades.");
                defecto.setCantidadFaltante(diferencia);
                defecto.setEstado(DefectoReproceso.Estado.PENDIENTE);
                defecto.setIdAsignacion(idAsignacion);

                int idDefecto = defectoDAO.insertarDefectoPendienteRetornarId(defecto);
                if (idDefecto == -1) {
                    resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=No+se+pudo+crear+el+defecto");
                    return;
                }

                // Marcar la tarea como completada con la cantidad real (no con la meta)
                boolean ok = cargaDAO.completarFase(idAsignacion, piezasCompletadas);
                if (!ok) {
                    resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=No+se+pudo+completar+la+tarea");
                    return;
                }

                // Enviar mensaje informativo
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?exito=Tarea+completada+con+" + piezasCompletadas +
                        "/" + cantidadMeta + "+unidades.+Se+ha+generado+un+defecto+pendiente+para+que+el+supervisor+lo+revise.");
                return;
            }

            // Si la cantidad completada es igual a la meta, completar normalmente
            boolean ok = cargaDAO.completarFase(idAsignacion, piezasCompletadas);
            if (!ok) {
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=No+se+pudo+completar+la+tarea");
                return;
            }

            // Notificación
            NotificacionDAO notifDAO = new NotificacionDAO();
            Notificacion n = new Notificacion();
            n.setTitulo("✅ Tarea completada");
            n.setMensaje(String.format(
                "El maquinista %s completó la fase '%s' de '%s' para la OT %s (%d/%d unidades).",
                usuario.getNombreCompleto(),
                asignacion.getNombreFase(),
                asignacion.getNombrePieza() != null ? asignacion.getNombrePieza() : "Ensamblaje",
                asignacion.getCodigoOt(),
                piezasCompletadas, cantidadMeta
            ));
            n.setTipo("TAREA_COMPLETADA");
            n.setIdReferencia(idAsignacion);
            n.setParaRol("ADMINISTRADOR,JEFE_PRODUCCION,SUPERVISOR");
            notifDAO.insertar(n);

            // Verificar si la OT puede finalizar o pasar a ensamblaje
            String resultado = cargaDAO.verificarYFinalizarOT(asignacion.getIdOt());
            String msg = switch (resultado) {
                case "OT_FINALIZADA" -> "OT+FINALIZADA+correctamente.";
                case "ENSAMBLAJE_CREADO" -> "Todas+las+piezas+completadas.+Se+ha+creado+la+tarea+de+ensamblaje.";
                case "ENSAMBLAJE_PENDIENTE" -> "Tarea+completada.+Ensamblaje+pendiente+de+completar.";
                case "PIEZAS_PENDIENTES" -> "Tarea+completada.+Aún+hay+piezas+pendientes.";
                default -> "Tarea+completada";
            };
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?exito=" + msg);

        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }
    // ── Asignar maquinista a una fase ─────────────────────────
    /**
     * CUS 5.3 ValidarEspecialidad → CUS 5.4 AsignarCarga → CUS 5.5 NotificarAsignacion
     * Verifica internamente la regla de bloqueo de fase previa.
     */
    private void asignarMaquinista(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String idAsignStr  = req.getParameter("idAsignacion");
        String idMaqStr    = req.getParameter("idMaquinista");

        if (idAsignStr == null || idMaqStr == null ||
            idAsignStr.isBlank() || idMaqStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() +
                "/cargas-trabajo?error=Parámetros+incompletos");
            return;
        }

        try {
            int idAsignacion = Integer.parseInt(idAsignStr);
            int idMaquinista = Integer.parseInt(idMaqStr);

            boolean ok = cargaDAO.asignarMaquinista(idAsignacion, idMaquinista);

            if (ok) {
                resp.sendRedirect(req.getContextPath() +
                    "/cargas-trabajo?exito=Carga+asignada+correctamente");
            } else {
                // El DAO devuelve false si la fase previa no está completa
                resp.sendRedirect(req.getContextPath() +
                    "/cargas-trabajo?error=Bloqueo+activo:+la+fase+previa+aún+no+está+completada");
            }

        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=ID+inválido");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() +
                "/cargas-trabajo?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }
    private void reasignarMaquinista(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String idAsignStr = req.getParameter("idAsignacion");
        String idMaqStr   = req.getParameter("idMaquinista");

        if (idAsignStr == null || idMaqStr == null || idAsignStr.isBlank() || idMaqStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=Parámetros+inválidos");
            return;
        }
        try {
            int idAsignacion = Integer.parseInt(idAsignStr);
            int idMaquinista = Integer.parseInt(idMaqStr);

            // Validar que la tarea esté en estado EN_PROCESO (opcional, el DAO lo verifica)
            boolean ok = cargaDAO.reasignarMaquinista(idAsignacion, idMaquinista);
            if (ok) {
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?exito=Tarea+reasignada+correctamente");
            } else {
                resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=No+se+pudo+reasignar+(la+tarea+debe+estar+en+proceso)");
            }
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=ID+inválido");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() + "/cargas-trabajo?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }
    
    // ── Helper: verificar permiso en sesión ──────────────────
    private boolean tienePermiso(HttpServletRequest req, String codigo) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigo);
    }
}
