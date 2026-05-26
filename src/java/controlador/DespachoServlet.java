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
 * Servlet: DespachoServlet
 * Ruta: /despacho
 * HU07: Conciliación de Inventario y Despacho Final
 *
 * Diagrama de secuencia HU07:
 *   Encargado Almacén → UI → IngresarConteoFisico → CompararConEstimado
 *                     → DetectarDiferencia → RegistrarMermaInventario
 *                     → GenerarNotaDespacho → ConfirmarDespacho
 *
 * Permisos requeridos:
 *   - DES_CONCIL_REG → realizar conciliación y despacho
 */
@WebServlet("/despacho")
public class DespachoServlet extends HttpServlet {

    private final ConciliacionDespachoDAO despachoDAO = new ConciliacionDespachoDAO();

    // ── GET ───────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        

        if (!tienePermiso(req, "DES_CONCIL_REG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");

        if ("nota".equals(accion)) {
            // Vista previa de nota de despacho para impresión (CUS 7.4)
            verNotaDespacho(req, resp);
        } else {
            listarLotes(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        if (!tienePermiso(req, "DES_CONCIL_REG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");

        if ("conciliar".equals(accion)) {
            // CUS 7.2 CompararConEstimado + CUS 7.3 RegistrarMermaInventario
            registrarConciliacion(req, resp);
        } else if ("despachar".equals(accion)) {
            // CUS 7.4 GenerarNotaDespacho + CUS 7.5 ConfirmarDespacho
            confirmarDespacho(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/despacho");
        }
    }

    // ── Listar lotes listos para conciliar/despachar ─────────
    private void listarLotes(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<ConciliacionDespacho> lotes = despachoDAO.listarLotesParaDespacho();
            req.setAttribute("lotes", lotes);
            req.getRequestDispatcher("/vista/despacho.jsp").forward(req, resp);
        } catch (SQLException e) {
            req.setAttribute("errorBD", "Error al cargar lotes: " + e.getMessage());
            req.getRequestDispatcher("/vista/despacho.jsp").forward(req, resp);
        }
    }

    // ── Registrar conciliación de conteo físico vs. estimado ──
    /**
     * CUS 7.1 IngresarConteoFisico → CUS 7.2 CompararConEstimado
     * → CUS 7.3 DetectarDiferencia → si hay merma: RegistrarMermaInventario
     */
    private void registrarConciliacion(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String idOtStr      = req.getParameter("idOt");
        String cantEstStr   = req.getParameter("cantidadEstimada");
        String cantFinalStr = req.getParameter("cantidadFinal");
        String obs          = req.getParameter("observaciones");

        if (idOtStr == null || cantFinalStr == null ||
            idOtStr.isBlank() || cantFinalStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() +
                "/despacho?error=La+OT+y+el+conteo+final+son+obligatorios");
            return;
        }

        try {
            HttpSession session = req.getSession(false);
            Usuario u = (Usuario) session.getAttribute("usuarioSesion");

            ConciliacionDespacho c = new ConciliacionDespacho();
            c.setIdOt(Integer.parseInt(idOtStr));
            c.setCantidadEstimada(Integer.parseInt(cantEstStr));
            c.setCantidadFinal(Integer.parseInt(cantFinalStr));
            c.setIdResponsable(u.getIdUsuario());
            c.setObservaciones(obs != null ? obs.trim() : "");

            boolean ok = despachoDAO.insertar(c);

            if (ok) {
                int dif = c.getDiferencia();
                String msg = dif == 0
                    ? "Conciliación+exitosa:+sin+diferencias"
                    : "Conciliación+registrada.+Merma+de+" + Math.abs(dif) + "+unidades+detectada";
                resp.sendRedirect(req.getContextPath() + "/despacho?exito=" + msg);
            } else {
                resp.sendRedirect(req.getContextPath() +
                    "/despacho?error=No+se+pudo+registrar+la+conciliación");
            }

        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/despacho?error=Valores+numéricos+inválidos");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() +
                "/despacho?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }

    // ── Confirmar despacho final ──────────────────────────────
    /**
     * CUS 7.4 GenerarNotaDespacho → CUS 7.5 ConfirmarDespacho
     * Cambia el estado de la conciliación a DESPACHADO.
     */
    private void confirmarDespacho(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String idConcilStr = req.getParameter("idConciliacion");
        if (idConcilStr == null || idConcilStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/despacho?error=ID+de+conciliación+inválido");
            return;
        }

        try {
            int idConciliacion = Integer.parseInt(idConcilStr);
            boolean ok = despachoDAO.confirmarDespacho(idConciliacion);

            String msg = ok
                ? "Despacho+confirmado+y+nota+generada"
                : "No+se+pudo+confirmar+el+despacho.+Verifique+el+estado";
            resp.sendRedirect(req.getContextPath() + "/despacho?" + (ok ? "exito=" : "error=") + msg);

        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/despacho?error=ID+inválido");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() +
                "/despacho?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }

    // ── Ver nota de despacho (impresión) ─────────────────────
    private void verNotaDespacho(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idOtStr = req.getParameter("idOt");
        if (idOtStr == null) {
            resp.sendRedirect(req.getContextPath() + "/despacho");
            return;
        }
        try {
            ConciliacionDespacho c = despachoDAO.buscarPorIdOt(Integer.parseInt(idOtStr));
            req.setAttribute("conciliacion", c);
            req.getRequestDispatcher("/vista/nota_despacho.jsp").forward(req, resp);
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/despacho?error=No+se+encontró+la+conciliación");
        }
    }

    // ── Helper ────────────────────────────────────────────────
    private boolean tienePermiso(HttpServletRequest req, String codigo) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigo);
    }
}
