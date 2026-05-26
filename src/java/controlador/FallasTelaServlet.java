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
 * Servlet: FallasTelaServlet
 * URL: /fallas-tela
 * HU02: Mapeo Digital de Imperfecciones y Fallas en la Tela
 *
 * Permisos:
 *   PROD_FALLAS_VER  → listar / ver (Admin, Jefe Producción, Tizador)
 *   PROD_FALLAS_REG  → registrar / eliminar (Admin, Tizador)
 *
 * Acciones (parámetro "accion"):
 *   GET  (sin accion)   → listar fallas
 *   GET  "porTela"      → filtrar por tela (idTela=X)
 *   POST "registrar"    → CUS 2.1 + 2.2: registrar falla categorizada
 *   POST "eliminar"     → eliminar falla (Admin o propio Tizador)
 */
@WebServlet(name = "FallasTelaServlet", urlPatterns = {"/fallas-tela"})
public class FallasTelaServlet extends HttpServlet {

    private final FallaTelaDAO dao = new FallaTelaDAO();

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

        if (!permisos.contains("PROD_FALLAS_VER") && !esAdmin) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion    = req.getParameter("accion");
        String idTelaStr = req.getParameter("idTela");

        try {
            List<FallaTela> lista;

            if ("porTela".equals(accion) && idTelaStr != null) {
                // Filtro por tela específica
                lista = dao.listarPorTela(Integer.parseInt(idTelaStr));
                req.setAttribute("idTelaFiltro", idTelaStr);
            } else if (esAdmin) {
                lista = dao.listarTodas();
            } else if (esTizador) {
                lista = dao.listarPorTizador(usuario.getIdUsuario());
            } else {
                // Jefe producción: ve todas pero no puede registrar
                lista = dao.listarTodas();
            }

            List<Tela> telasParaMapeo = (permisos.contains("PROD_FALLAS_REG") || esAdmin)
                    ? dao.listarTelasParaMapeo()
                    : new java.util.ArrayList<>();

            List<Tela> telasConFallas = dao.listarTelasConFallas();

            req.setAttribute("fallasList",      lista);
            req.setAttribute("telasParaMapeo",  telasParaMapeo);
            req.setAttribute("telasConFallas",  telasConFallas);
            req.setAttribute("puedeRegistrar",  permisos.contains("PROD_FALLAS_REG") || esAdmin);
            req.getRequestDispatcher("vista/fallas_tela.jsp").forward(req, resp);

        } catch (Exception e) {
            req.setAttribute("errorBD", "Error al cargar fallas: " + e.getMessage());
            req.getRequestDispatcher("vista/fallas_tela.jsp").forward(req, resp);
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

        if (!permisos.contains("PROD_FALLAS_REG") && !esAdmin) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion   = req.getParameter("accion");
        String redirect = req.getContextPath() + "/fallas-tela";

        try {
            switch (accion == null ? "" : accion) {

                // CUS 2.1 + 2.2: Categorizar y registrar falla
                case "registrar": {
                    FallaTela f = new FallaTela();
                    f.setIdTela(Integer.parseInt(req.getParameter("idTela")));
                    f.setIdTizador(usuario.getIdUsuario());

                    String tipoStr = req.getParameter("tipoFalla");
                    f.setTipoFalla(FallaTela.TipoFalla.valueOf(tipoStr));

                    f.setPosicionRollo(Integer.parseInt(req.getParameter("posicionRollo")));

                    String metroStr = req.getParameter("posicionMetro");
                    f.setPosicionMetro(new BigDecimal(metroStr));

                    String anchoStr = req.getParameter("anchoCm");
                    if (anchoStr != null && !anchoStr.isBlank())
                        f.setAnchoCm(new BigDecimal(anchoStr));

                    String largoStr = req.getParameter("largoCm");
                    if (largoStr != null && !largoStr.isBlank())
                        f.setLargoCm(new BigDecimal(largoStr));

                    f.setDescripcion(req.getParameter("descripcion"));

                    // CUS 2.3: área no apta se activa siempre (checkbox puede sobrescribir)
                    String noAptaStr = req.getParameter("esAreaNoApta");
                    f.setEsAreaNoApta(!"false".equals(noAptaStr));

                    int id = dao.registrar(f);
                    redirect += id > 0 ? "?exito=registrado" : "?error=falloInsercion";
                    break;
                }
                case "actualizar": {
                    int idFalla = Integer.parseInt(req.getParameter("idFalla"));
                    int idTela = Integer.parseInt(req.getParameter("idTela"));
                    String tipoStr = req.getParameter("tipoFalla");
                    int rollo = Integer.parseInt(req.getParameter("posicionRollo"));
                    BigDecimal metro = new BigDecimal(req.getParameter("posicionMetro"));
                    BigDecimal ancho = (req.getParameter("anchoCm") != null && !req.getParameter("anchoCm").isBlank())
                            ? new BigDecimal(req.getParameter("anchoCm")) : null;
                    BigDecimal largo = (req.getParameter("largoCm") != null && !req.getParameter("largoCm").isBlank())
                            ? new BigDecimal(req.getParameter("largoCm")) : null;
                    boolean esAreaNoApta = "true".equals(req.getParameter("esAreaNoApta"));
                    String descripcion = req.getParameter("descripcion");

                    FallaTela f = new FallaTela();
                    f.setIdFalla(idFalla);
                    f.setIdTela(idTela);
                    f.setIdTizador(usuario.getIdUsuario()); // opcional: conservar el tizador original
                    f.setTipoFalla(FallaTela.TipoFalla.valueOf(tipoStr));
                    f.setPosicionRollo(rollo);
                    f.setPosicionMetro(metro);
                    f.setAnchoCm(ancho);
                    f.setLargoCm(largo);
                    f.setEsAreaNoApta(esAreaNoApta);
                    f.setDescripcion(descripcion);

                    boolean ok = dao.actualizar(f);
                    redirect += ok ? "?exito=actualizado" : "?error=falloActualizacion";
                    break;
                }
                case "eliminar": {
                    int idFalla = Integer.parseInt(req.getParameter("idFalla"));
                    boolean ok  = dao.eliminar(idFalla);
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
            } catch (Exception ex) {
                redirect += "?error=bd";
            }
        }

        resp.sendRedirect(redirect);
    }
}
