package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.Tela;
import modelo.TelaDAO;
import modelo.Usuario;

import java.io.IOException;
import java.math.BigDecimal;

/**
 * Servlet de Inventario de Telas.
 * Ubicación: controlador/InventarioServlet.java
 * HU01: Registro y Control de Calidad de Tela Recibida
 *
 * Mapeos:
 *   GET  /inventario          → lista telas (inventario.jsp)
 *   GET  /inventario?accion=nuevo  → formulario vacío (registro_tela.jsp)
 *   POST /inventario          → guarda nueva tela
 */
@WebServlet("/inventario")
public class InventarioServlet extends HttpServlet {

    private final TelaDAO telaDAO = new TelaDAO();

    // ── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String accion = req.getParameter("accion");

        if ("nuevo".equals(accion)) {
            // Mostrar formulario en blanco
            req.getRequestDispatcher("/vista/registro_tela.jsp").forward(req, resp);
            return;
        }

        // Por defecto: listado de telas
        req.setAttribute("listaTelas", telaDAO.listarTodas());
        req.getRequestDispatcher("/vista/inventario.jsp").forward(req, resp);
    }

    // ── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        // ── Obtener usuario de sesión ──
        HttpSession session = req.getSession(false);
        Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");

        // ── Leer parámetros del formulario ──
        String  idOtStr       = req.getParameter("id_ot");
        String  origen        = req.getParameter("origen");
        String  proveedor     = req.getParameter("proveedor");
        String  pesoGuiaStr   = req.getParameter("peso_guia");
        String  pesoRealStr   = req.getParameter("peso_real");
        String  tipoTejido    = req.getParameter("tipo_tejido");
        String  color         = req.getParameter("color");
        String  numRollosStr  = req.getParameter("num_rollos");
        String  observaciones = req.getParameter("observaciones");
        String  estadoCal     = req.getParameter("estado_calidad");
        String  reposo        = req.getParameter("requiere_reposo");

        // ── Validaciones ──
        StringBuilder errores = new StringBuilder();

        if (idOtStr == null || idOtStr.isBlank())
            errores.append("Selecciona una Orden de Trabajo. ");
        if (origen == null || origen.isBlank())
            errores.append("Selecciona el origen de la tela. ");
        if (pesoGuiaStr == null || pesoGuiaStr.isBlank())
            errores.append("El peso de la guía es obligatorio. ");
        if (pesoRealStr == null || pesoRealStr.isBlank())
            errores.append("El peso real es obligatorio. ");
        if (observaciones == null || observaciones.isBlank())
            errores.append("Las observaciones son obligatorias (CA2 HU01). ");

        if (errores.length() > 0) {
            req.setAttribute("error", errores.toString().trim());
            req.getRequestDispatcher("/vista/registro_tela.jsp").forward(req, resp);
            return;
        }

        // ── Construir entidad ──
        Tela tela = new Tela();
        tela.setIdOt(Integer.parseInt(idOtStr));
        tela.setIdRegistrador(usuarioSesion.getIdUsuario());
        tela.setOrigen(Tela.Origen.valueOf(origen));
        tela.setProveedor(proveedor);
        tela.setPesoGuia(new BigDecimal(pesoGuiaStr));
        tela.setPesoReal(new BigDecimal(pesoRealStr));
        tela.setTipoTejido(tipoTejido);
        tela.setColor(color);
        tela.setNumRollos(numRollosStr != null && !numRollosStr.isBlank()
                ? Integer.parseInt(numRollosStr) : 1);
        tela.setObservaciones(observaciones);
        tela.setEstadoCalidad(
                estadoCal != null ? Tela.EstadoCalidad.valueOf(estadoCal)
                                  : Tela.EstadoCalidad.OBSERVADO);
        tela.setRequiereReposo("on".equals(reposo) || "true".equals(reposo));

        // Generar código único: TELA-{timestamp}
        tela.setCodigoTela("TELA-" + System.currentTimeMillis());

        // ── Calcular diferencia para alerta (CA1 HU01) ──
        BigDecimal diferencia = tela.getPesoReal().subtract(tela.getPesoGuia());
        tela.setDiferenciaPeso(diferencia);

        // ── Persistir ──
        boolean guardado = telaDAO.insertar(tela);

        if (guardado) {
            // Alerta si hay discrepancia de peso > 1%
            String msg = "Tela registrada correctamente.";
            if (tela.hayDiscrepanciaPeso()) {
                msg += " ⚠ ALERTA: diferencia de peso significativa ("
                       + diferencia + " kg).";
            }
            req.getSession().setAttribute("mensajeExito", msg);
            resp.sendRedirect(req.getContextPath() + "/inventario");
        } else {
            req.setAttribute("error", "No se pudo guardar el registro. Intenta nuevamente.");
            req.getRequestDispatcher("/vista/registro_tela.jsp").forward(req, resp);
        }
    }
}
