package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Set;

/**
 * Servlet: TiemposReposoServlet
 * URL: /tiempos-reposo
 * HU03: Gestión de Tiempos de Reposo y Corte
 *
 * Permisos requeridos:
 *   PROD_REPOSO_VER      → listar / ver
 *   PROD_REPOSO_GESTION  → registrar inicio, marcar apto, cancelar
 *
 * Acciones disponibles (parámetro "accion"):
 *   GET  (sin accion)  → listar reposos
 *   GET  "polling"     → verificar vencimientos + devolver JSON de activos
 *   POST "iniciar"     → CUS 3.2: Registrar Inicio de Reposo
 *   POST "apto"        → CUS 3.3: Marcar Apto para Corte
 *   POST "cancelar"    → Cancelar reposo activo
 */
@WebServlet(name = "TiemposReposoServlet", urlPatterns = {"/tiempos-reposo"})
public class TiemposReposoServlet extends HttpServlet {

    private final TiempoReposoDAO dao = new TiempoReposoDAO();

    // ─── GET ─────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) req.getSession().getAttribute("permisosUsuario");
        if (permisos == null) permisos = new java.util.HashSet<>();

        if (!permisos.contains("PROD_REPOSO_VER")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");

        // ── Polling AJAX: verificar vencimientos y devolver JSON ──
        if ("polling".equals(accion)) {
            try {
                dao.verificarYNotificar();
                List<TiempoReposo> activos = esAdmin(usuario)
                        ? dao.listarTodos()
                        : dao.listarPorUsuario(usuario.getIdUsuario());

                resp.setContentType("application/json;charset=UTF-8");
                PrintWriter out = resp.getWriter();
                out.print(construirJsonActivos(activos));
            } catch (Exception e) {
                resp.setStatus(500);
                resp.getWriter().print("{\"error\":\"" + escaparJson(e.getMessage()) + "\"}");
            }
            return;
        }

        // ── Vista principal ───────────────────────────────────────
        try {
            List<TiempoReposo> lista = esAdmin(usuario)
                    ? dao.listarTodos()
                    : dao.listarPorUsuario(usuario.getIdUsuario());

            List<Tela> telasDisponibles = dao.listarTelasDisponiblesParaReposo();

            req.setAttribute("reposoList",        lista);
            req.setAttribute("telasDisponibles",   telasDisponibles);
            boolean hayTelasParaReposo = !telasDisponibles.isEmpty();
            req.setAttribute("hayTelasParaReposo", hayTelasParaReposo);
            req.getRequestDispatcher("/vista/tiempos_reposo.jsp").forward(req, resp);

        } catch (Exception e) {
            req.setAttribute("errorBD", "Error al cargar los tiempos de reposo: " + e.getMessage());
            req.getRequestDispatcher("/vista/tiempos_reposo.jsp").forward(req, resp);
        }
    }

    // ─── POST ────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) req.getSession().getAttribute("permisosUsuario");
        if (permisos == null) permisos = new java.util.HashSet<>();

        if (!permisos.contains("PROD_REPOSO_GESTION")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");
        String redirect = req.getContextPath() + "/tiempos-reposo";

        try {
            switch (accion == null ? "" : accion) {

                // ── CUS 3.2: Registrar Inicio de Reposo ──────────
                case "iniciar": {
                    int    idTela    = Integer.parseInt(req.getParameter("idTela"));
                                    boolean disponible = dao.verificarTelaDisponibleParaReposo(idTela);
                    if (!disponible) {
                        redirect += "?error=telaNoDisponible";
                        break;
                    }
                    int    duracion  = Integer.parseInt(req.getParameter("duracionMinutos"));
                    String obs       = req.getParameter("observaciones");
                    if (obs == null) obs = "";

                    int nuevoId = dao.registrarInicio(idTela, usuario.getIdUsuario(), duracion, obs);
                    if (nuevoId > 0) {
                        redirect += "?exito=iniciado";
                    } else {
                        redirect += "?error=falloInsercion";
                    }
                    break;
                }
                case "eliminar": {
                    int idReposo = Integer.parseInt(req.getParameter("idReposo"));
                    boolean ok = dao.eliminar(idReposo);
                    redirect += ok ? "?exito=eliminado" : "?error=noEliminado";
                    break;
                }
                // ── CUS 3.3: Marcar Apto para Corte (notificación) ─
                case "apto": {
                    int idReposo = Integer.parseInt(req.getParameter("idReposo"));
                    boolean ok = dao.marcarAptoCorte(idReposo);
                    redirect += ok ? "?exito=apto" : "?error=noActualizado";
                    break;
                }

                // ── Cancelar reposo ───────────────────────────────
                case "cancelar": {
                    int idReposo = Integer.parseInt(req.getParameter("idReposo"));
                    boolean ok = dao.cancelar(idReposo);
                    redirect += ok ? "?exito=cancelado" : "?error=noActualizado";
                    break;
                }

                default:
                    redirect += "?error=accionInvalida";
            }
        } catch (NumberFormatException e) {
            redirect += "?error=datosInvalidos";
        } catch (Exception e) {
            redirect += "?error=bd&msg=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8");
        }

        resp.sendRedirect(redirect);
    }

    // ─── Helpers ─────────────────────────────────────────────────

    private boolean esAdmin(Usuario u) {
        return "ADMINISTRADOR".equalsIgnoreCase(u.getNombreRol());
    }

    /**
     * Genera JSON con los reposos activos (EN_REPOSO) para el polling AJAX.
     * Incluye porcentaje, minutos restantes y si hay nuevos aptosParaCorte.
     */
    private String construirJsonActivos(List<TiempoReposo> lista) {
        StringBuilder sb = new StringBuilder("{\"reposos\":[");
        boolean primero = true;
        for (TiempoReposo tr : lista) {
            if (!primero) sb.append(",");
            primero = false;
            sb.append("{");
            sb.append("\"id\":").append(tr.getIdReposo()).append(",");
            sb.append("\"codigo\":\"").append(escaparJson(tr.getCodigoTela())).append("\",");
            sb.append("\"ot\":\"").append(escaparJson(tr.getCodigoOt())).append("\",");
            sb.append("\"estado\":\"").append(tr.getEstado()).append("\",");
            sb.append("\"pct\":").append(tr.getPorcentajeCompletado()).append(",");
            sb.append("\"minRest\":").append(tr.getMinutosRestantes()).append(",");
            sb.append("\"notif\":").append(tr.isNotificacionEnviada());
            sb.append("}");
        }
        sb.append("]}");
        return sb.toString();
    }

    private String escaparJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}
