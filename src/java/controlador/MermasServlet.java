package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

/**
 * Servlet: MermasServlet
 * URL: /mermas
 * HU04: Registro de Merma por Tipo de Tejido
 *
 * Permisos:
 *   PROD_MERMA_VER → listar (Admin, Jefe Producción, Tizador)
 *   PROD_MERMA_REG → registrar / eliminar (Admin, Tizador)
 *
 * Acciones:
 *   GET  (sin accion)  → listar mermas
 *   GET  "porOt"       → filtrar por OT (idOt=X)
 *   POST "registrar"   → CUS 4.1 + 4.2: registrar merma + calcular %
 *   POST "eliminar"    → eliminar (solo Admin)
 */
@WebServlet(name = "MermasServlet", urlPatterns = {"/mermas"})
public class MermasServlet extends HttpServlet {

    private final MermaDAO dao = new MermaDAO();

    // ─── GET ─────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) req.getSession().getAttribute("permisosUsuario");
        if (permisos == null) permisos = new java.util.HashSet<>();

        boolean esAdmin   = "ADMINISTRADOR".equalsIgnoreCase(usuario.getNombreRol());
        boolean esTizador = "TIZADOR".equalsIgnoreCase(usuario.getNombreRol());

        if (!permisos.contains("PROD_MERMA_VER") && !esAdmin) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion   = req.getParameter("accion");
        String idOtStr  = req.getParameter("idOt");

        try {
            List<Merma> lista;
            // Validar si idOtStr es un número válido (ignorar "null", vacío o no numérico)
            Integer idOt = null;
            if (idOtStr != null && !idOtStr.isEmpty() && !"null".equalsIgnoreCase(idOtStr)) {
                try {
                    idOt = Integer.parseInt(idOtStr);
                } catch (NumberFormatException e) {
                    // No es número válido, ignorar
                }
            }
            if ("porOt".equals(accion) && idOtStr != null) {
                lista = dao.listarPorOt(Integer.parseInt(idOtStr));
                req.setAttribute("idOtFiltro", idOtStr);
            } else if (esAdmin) {
                lista = dao.listarTodas();
            } else if (esTizador) {
                lista = dao.listarPorTizador(usuario.getIdUsuario());
            } else {
                lista = dao.listarTodas(); // Jefe producción: ve todo, sin registrar
            }

            // Calcular % acumulado por OT si hay filtro activo
            BigDecimal pctOt = null;
            if (idOt != null) {
                pctOt = dao.calcularPorcentajePorOt(idOt);
            }
                

            boolean puedeReg = permisos.contains("PROD_MERMA_REG") || esAdmin;

            List<Tela>         telasParaMerma = puedeReg ? dao.listarTelasParaMerma() : new java.util.ArrayList<>();
            List<OrdenTrabajo> otsConMermas   = dao.listarOtsConMermas();

            req.setAttribute("mermasList",     lista);
            req.setAttribute("telasParaMerma", telasParaMerma);
            req.setAttribute("otsConMermas",   otsConMermas);
            req.setAttribute("puedeRegistrar", puedeReg);
            req.setAttribute("pctOtActivo",    pctOt);
            req.getRequestDispatcher("vista/mermas.jsp").forward(req, resp);

        } catch (Exception e) {
            req.setAttribute("errorBD", "Error al cargar mermas: " + e.getMessage());
            req.getRequestDispatcher("vista/mermas.jsp").forward(req, resp);
        }
    }

    // ─── POST ────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) req.getSession().getAttribute("permisosUsuario");
        if (permisos == null) permisos = new java.util.HashSet<>();

        boolean esAdmin = "ADMINISTRADOR".equalsIgnoreCase(usuario.getNombreRol());

        if (!permisos.contains("PROD_MERMA_REG") && !esAdmin) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion   = req.getParameter("accion");
        String redirect = req.getContextPath() + "/mermas";

        try {
            switch (accion == null ? "" : accion) {

                // CUS 4.1 + 4.2: Registrar merma y calcular porcentaje
                case "registrar": {
                    Merma m = new Merma();
                    m.setIdTela(Integer.parseInt(req.getParameter("idTela")));
                    m.setIdOt(Integer.parseInt(req.getParameter("idOt")));
                    m.setIdTizador(usuario.getIdUsuario());
                    m.setFase(Merma.Fase.valueOf(req.getParameter("fase")));
                    m.setPesoUtilizadoKg(new BigDecimal(req.getParameter("pesoUtilizadoKg")));
                    m.setPesomermaKg(new BigDecimal(req.getParameter("pesomermaKg")));
                    String obs = req.getParameter("observaciones");
                    m.setObservaciones(obs != null ? obs : "");
                    // Validar que la OT esté en estado EN_PROCESO
                    OrdenTrabajoDAO otDao = new OrdenTrabajoDAO();
                    OrdenTrabajo ot = otDao.buscarPorId(m.getIdOt());
                    if (ot == null || !"EN_PROCESO".equals(ot.getEstado())) {
                        redirect += "?error=La OT no está en estado EN_PROCESO";
                        break;
                    }
                    // Validar que peso_merma <= peso_utilizado
                    if (m.getPesomermaKg().compareTo(m.getPesoUtilizadoKg()) > 0) {
                        redirect += "?error=mermaExcede";
                        break;
                    }

                    int id = dao.registrar(m);
                    // Redirigir mostrando el % calculado para esa OT (Notificar - diagrama secuencia)
                    redirect += id > 0
                        ? "?exito=registrado&idOt=" + m.getIdOt()
                        : "?error=falloInsercion";
                    break;
                }
                case "actualizar": {
                    if (!esAdmin) { redirect += "?error=sinPermiso"; break; }
                    int idMerma = Integer.parseInt(req.getParameter("idMerma"));
                    int idTela  = Integer.parseInt(req.getParameter("idTela")); // solo para validar, no se actualiza
                    String fase = req.getParameter("fase");
                    BigDecimal pesoUtilizado = new BigDecimal(req.getParameter("pesoUtilizadoKg"));
                    BigDecimal pesoMerma     = new BigDecimal(req.getParameter("pesomermaKg"));
                    String observaciones = req.getParameter("observaciones");

                    // Validar que la merma no sea mayor al utilizado
                    if (pesoMerma.compareTo(pesoUtilizado) > 0) {
                        redirect += "?error=mermaExcede";
                        break;
                    }

                    Merma m = new Merma();
                    m.setIdMerma(idMerma);
                    m.setFase(Merma.Fase.valueOf(fase));
                    m.setPesoUtilizadoKg(pesoUtilizado);
                    m.setPesomermaKg(pesoMerma);
                    m.setObservaciones(observaciones != null ? observaciones : "");

                    boolean ok = dao.actualizar(m);
                    redirect += ok ? "?exito=actualizado&idOt=" + req.getParameter("idOt") : "?error=falloActualizacion";
                    break;
                }
                
                case "eliminar": {
                    if (!esAdmin) { redirect += "?error=sinPermiso"; break; }
                    int idMerma = Integer.parseInt(req.getParameter("idMerma"));
                    boolean ok  = dao.eliminar(idMerma);
                    redirect += ok ? "?exito=eliminado" : "?error=noEliminado";
                    break;
                }

                default:
                    redirect += "?error=accionInvalida";
            }
        } catch (NumberFormatException e) {
            redirect += "?error=datosInvalidos";
        } catch (Exception e) {
            try {
                redirect += "?error=bd&msg=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8");
            } catch (Exception ex) { redirect += "?error=bd"; }
        }

        resp.sendRedirect(redirect);
    }
}
