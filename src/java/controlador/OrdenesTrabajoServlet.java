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
 * Servlet: OrdenesTrabajoServlet
 * Ruta: /ordenes-trabajo
 * HU13: Creación de Orden de Trabajo (OT)
 *
 * Diagrama de secuencia HU13:
 *   Jefe de producción → UI → ValidarDatosOrden → ConsultarDatosOrden
 *                       → GenerarNumeroUnico → IniciarFlujoProduccion
 *                       → GuardarOrdenTrabajo → ConfirmarRegistro
 *
 * Permisos requeridos:
 *   - PROD_OT_VER    → ver listado de OTs
 *   - PROD_OT_CREAR  → crear nuevas OTs / cambiar estado
 */
@WebServlet("/ordenes-trabajo")
public class OrdenesTrabajoServlet extends HttpServlet {

    private final OrdenTrabajoDAO    otDAO         = new OrdenTrabajoDAO();
    private final UsuarioDAO          usuarioDAO    = new UsuarioDAO();
    private final AsignacionCargaDAO  cargaDAO      = new AsignacionCargaDAO();

    // ── GET ───────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!tienePermiso(req, "PROD_OT_VER")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");
        
        // NUEVO: Interceptar la búsqueda a la API
        if ("buscarCliente".equals(accion)) {
            buscarClienteApi(req, resp);
            return;
        }
        if ("nueva".equals(accion)) {
            // Formulario de nueva OT (CUS 13.1)
            mostrarFormularioNueva(req, resp);
        } else if ("ver".equals(accion)) {
            // Detalle de una OT específica
            verDetalle(req, resp);
        } else {
            // Listado de todas las OTs (CUS 13.4)
            listarOrdenes(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        if ("crear".equals(accion)) {
            if (!tienePermiso(req, "PROD_OT_CREAR")) {
                resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
                return;
            }
            crearOrdenTrabajo(req, resp);

        } else if ("cambiarEstado".equals(accion)) {
            if (!tienePermiso(req, "PROD_OT_CREAR")) {
                resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
                return;
            }
            cambiarEstadoOT(req, resp);

        } else if ("editar".equals(accion)) {
            if (!tienePermiso(req, "PROD_OT_CREAR")) { /* redirigir a dashboard */ return; }
            editarOT(req, resp);
        } else if ("eliminar".equals(accion)) {
            if (!tienePermiso(req, "PROD_OT_CREAR")) { /* redirigir a dashboard */ return; }
            eliminarOT(req, resp);
        
        } else {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo");
        }
    }

    // ── Listar todas las OTs ──────────────────────────────────
    private void listarOrdenes(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<OrdenTrabajo> ordenes = otDAO.listarTodas();
            req.setAttribute("ordenes", ordenes);
            // Pre-cargar datos para el modal flotante de nueva OT
            try {
                req.setAttribute("codigoPreview", otDAO.generarCodigoOt());
                req.setAttribute("modelosPrenda", new ModeloPrendaDAO().listarTodos());
            } catch (Exception ignored) { /* no critico, el modal pedira estos datos */ }
            req.getRequestDispatcher("/vista/ordenes_trabajo.jsp").forward(req, resp);
        } catch (SQLException e) {
            req.setAttribute("errorBD", "Error al cargar las órdenes: " + e.getMessage());
            req.getRequestDispatcher("/vista/ordenes_trabajo.jsp").forward(req, resp);
        }
    }
    // ── BUSCAR CLIENTE EN API EXTERNA (DNI/RUC) ─────────────────────────
    private void buscarClienteApi(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String doc = req.getParameter("doc");
        
        // Validación básica
        if (doc == null || (doc.trim().length() != 8 && doc.trim().length() != 11)) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        // URLs según la documentación de apisperu.com
        String urlApi = (doc.trim().length() == 8)
                ? "https://dniruc.apisperu.com/api/v1/dni/" + doc.trim()
                : "https://dniruc.apisperu.com/api/v1/ruc/" + doc.trim();

        // Tu token
        String token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImdhYnJpZWxsb3phbm8xNzZAZ21haWwuY29tIn0.yjtS6jGyJUP8EDCvCE9dHba1am2D7WxVGWA5h4OyIp4";

        java.net.HttpURLConnection conexion = (java.net.HttpURLConnection) new java.net.URL(urlApi).openConnection();
        conexion.setRequestMethod("GET");
        conexion.setRequestProperty("Authorization", "Bearer " + token);
        conexion.setRequestProperty("Accept", "application/json");

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        try {
            int estado = conexion.getResponseCode();
            if (estado == 200) {
                // Leer la respuesta y enviarla al JSP
                try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(conexion.getInputStream(), "UTF-8"));
                     java.io.PrintWriter out = resp.getWriter()) {
                    String linea;
                    while ((linea = br.readLine()) != null) {
                        out.print(linea);
                    }
                }
            } else {
                resp.setStatus(estado);
                resp.getWriter().write("{\"error\":\"No encontrado\"}");
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\":\"Error interno de conexión\"}");
        }
    }
    // ── Mostrar formulario nueva OT ───────────────────────────
    private void mostrarFormularioNueva(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            // Pre-generar el código para mostrárselo al usuario (CUS 13.3)
            String codigoPreview = otDAO.generarCodigoOt();
            req.setAttribute("codigoPreview", codigoPreview);

            // Cargar modelos de prenda disponibles (HU12) para el select
            ModeloPrendaDAO modeloDAO = new ModeloPrendaDAO();
            req.setAttribute("modelosPrenda", modeloDAO.listarTodos());

            req.getRequestDispatcher("/vista/form_orden_trabajo.jsp").forward(req, resp);
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=" +
                java.net.URLEncoder.encode("Error al preparar formulario: " + e.getMessage(), "UTF-8"));
        }
    }

    // ── Ver detalle de una OT ─────────────────────────────────
    private void verDetalle(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idStr = req.getParameter("id");
        if (idStr == null) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo");
            return;
        }
        try {
            int id = Integer.parseInt(idStr);
            OrdenTrabajo ot = otDAO.buscarPorId(id);
            if (ot == null) {
                resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=OT+no+encontrada");
                return;
            }
            req.setAttribute("ot", ot);
            req.getRequestDispatcher("/vista/detalle_orden_trabajo.jsp").forward(req, resp);
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=ID+inválido");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=" +
                java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    // ── Crear nueva OT (CUS 13.1 → 13.5) ─────────────────────
    /**
     * Flujo según diagrama de secuencia HU13:
     * 1. ValidarDatosOrden (campos obligatorios)
     * 2. GenerarNumeroUnico (codigo OT)
     * 3. IniciarFlujoProduccion (estado = CREADA)
     * 4. GuardarOrdenTrabajo (INSERT)
     * 5. ConfirmarRegistro → NotificarRegistro
     */
    private void crearOrdenTrabajo(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        // 1. Leer parámetros del formulario
        String cliente     = req.getParameter("cliente");
        String idModeloStr = req.getParameter("idModelo");
        String cantidadStr = req.getParameter("cantidadEst");
        
        if (cliente == null || idModeloStr == null || idModeloStr.equals("0") || idModeloStr.isEmpty()) {
            redirigirConError(req, resp, "Cliente y Modelo son obligatorios.");
            return;
        }

        // 2. Validar campos obligatorios (CUS 13.2 ValidarDatosOrden)
        if (cliente == null || cliente.isBlank()) {
            redirigirConError(req, resp, "El nombre del cliente es obligatorio.");
            return;
        }
   
        if (cantidadStr == null || cantidadStr.isBlank()) {
            redirigirConError(req, resp, "La cantidad estimada es obligatoria.");
            return;
        }

        int cantidad;
        int idModelo;
        try {
            idModelo = Integer.parseInt(idModeloStr);
            cantidad = Integer.parseInt(cantidadStr.trim());
            if (cantidad <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            redirigirConError(req, resp, "La cantidad debe ser un número entero positivo.");
            return;
        }

        // 3. Obtener usuario responsable (Jefe de Producción en sesión)
        HttpSession session = req.getSession(false);
        Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");

        try {
            // 4. Generar código único (CUS 13.3)
            String codigoOt = otDAO.generarCodigoOt();

            // 5. Construir y persistir la OT (CUS 13.4 + 13.5)
            OrdenTrabajo ot = new OrdenTrabajo();
            ot.setCodigoOt    (codigoOt);
            ot.setCliente     (cliente.trim());
            ot.setIdModelo(idModelo); // Asignamos el ID
            ot.setCantidadEst (cantidad);
            ot.setEstado      ("CREADA");
            ot.setIdResponsable(usuarioSesion.getIdUsuario());

            boolean ok = otDAO.insertar(ot);
            if (ok) {
                // Redirigir al detalle de la OT recién creada (CUS 13.5 NotificarRegistro)
                resp.sendRedirect(req.getContextPath() +
                    "/ordenes-trabajo?exito=OT+" + codigoOt + "+creada+exitosamente");
            } else {
                redirigirConError(req, resp, "No se pudo guardar la Orden de Trabajo. Intenta nuevamente.");
            }

        } catch (SQLException e) {
            redirigirConError(req, resp, "Error de base de datos: " + e.getMessage());
        }
    }

    // ── Cambiar estado de la OT ───────────────────────────────
    private void cambiarEstadoOT(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        String idStr     = req.getParameter("idOt");
        String nuevoEst  = req.getParameter("nuevoEstado");

        if (idStr == null || nuevoEst == null) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=Parámetros+inválidos");
            return;
        }

        // Validar que el estado sea uno de los permitidos
        if (!nuevoEst.matches("CREADA|EN_PROCESO|FINALIZADA|ANULADA")) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=Estado+no+válido");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            // 1. Buscamos el estado actual real de la base de datos
            OrdenTrabajo otActual = otDAO.buscarPorId(id);
            String estadoActual = otActual.getEstado();
            
            // 2. Validar reglas de negocio (Máquina de estados)
            boolean transicionValida = false;
            if ("CREADA".equals(estadoActual)) {
                if ("ANULADA".equals(nuevoEst)) {
                    transicionValida = true;
                }
            } else if ("EN_PROCESO".equals(estadoActual)) {
                if ("ANULADA".equals(nuevoEst)) {
                    transicionValida = true;
                }
            }
            // FINALIZADA o ANULADA no permiten transiciones

            if (!transicionValida) {
                resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=Transición+de+estado+no+permitida");
                return;
            }
            
            // 3. Si es válida, aplicar cambio
            boolean ok = otDAO.cambiarEstado(id, nuevoEst);
            if (ok) {
                // ── Auto-generar cargas de trabajo al iniciar producción ──
                // Cuando la OT pasa a EN_PROCESO se crean automáticamente
                // las filas pieza×fase en asignaciones_carga (HU05).
                if ("EN_PROCESO".equals(nuevoEst)) {
                    try {
                        int filasGeneradas = cargaDAO.generarAsignaciones(id);
                        String msg = filasGeneradas > 0
                            ? "Estado+actualizado.+Se+generaron+" + filasGeneradas + "+asignaciones+en+Cargas+de+Trabajo"
                            : "Estado+actualizado+(las+asignaciones+ya+existían)";
                        resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?exito=" + msg);
                    } catch (SQLException eGen) {
                        // El cambio de estado fue exitoso, solo falló la generación
                        resp.sendRedirect(req.getContextPath() +
                            "/ordenes-trabajo?exito=Estado+actualizado&error=No+se+pudieron+generar+las+cargas+de+trabajo");
                    }
                } else {
                    resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?exito=Estado+actualizado");
                }
            } else {
                resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=No+se+pudo+actualizar+el+estado");
            }
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=ID+inválido");
        } catch (SQLException e) {
            redirigirConError(req, resp, "Error: " + e.getMessage());
        }
    }
    
    
    private void editarOT(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        String idStr = req.getParameter("idOt");
        String cliente = req.getParameter("cliente");
        String idModeloStr = req.getParameter("idModelo"); // <-- Asegúrate que el JSP envíe "idModelo"
        String cantidadStr = req.getParameter("cantidadEst");

        try {
            int id = Integer.parseInt(idStr);
            int cant = Integer.parseInt(cantidadStr.trim());
            int idModelo = Integer.parseInt(idModeloStr); // <-- Convertir a int

            if (cant <= 0) throw new NumberFormatException();

            // Ahora la llamada coincide con la firma del DAO (int, String, int, int)
            boolean ok = otDAO.actualizar(id, cliente.trim(), cant, idModelo); 

            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?exito=" +
                (ok ? "OT+actualizada" : "Error.+Solo+OT+en+estado+CREADA+pueden+editarse"));

        } catch (NumberFormatException | SQLException e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=Datos+invalidos");
        }
    }

    private void eliminarOT(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String idStr = req.getParameter("idOt");

        try {
            // 1. Validar que el ID sea un número
            int id = Integer.parseInt(idStr);

            // 2. Intentar eliminar (aquí es donde saltaba el error de SQLException)
            boolean ok = otDAO.eliminar(id);

            // 3. Redirigir según el resultado booleano del DAO
            if (ok) {
                resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?exito=OT+eliminada");
            } else {
                resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=No+se+pudo+eliminar.+Verifique+que+este+en+CREADA+y+sin+telas+asociadas");
            }

        } catch (NumberFormatException e) {
            // Error si idOt no es un número válido
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=ID+de+orden+invalido");

        } catch (java.sql.SQLException e) {
            // CORRECCIÓN: Captura el error de base de datos que pedía el IDE
            e.printStackTrace(); // Para ver el error en la consola del servidor
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo?error=Error+interno+en+la+base+de+datos");
        }
    }
    // ── Helpers ───────────────────────────────────────────────

    private boolean tienePermiso(HttpServletRequest req, String codigo) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigo);
    }

    private void redirigirConError(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws IOException, ServletException {
        // Volver al listado con el modal abierto y el error mostrado
        try {
            List<OrdenTrabajo> ordenes = otDAO.listarTodas();
            req.setAttribute("ordenes", ordenes);
        } catch (SQLException e2) { /* ignorar */ }
        try {
            req.setAttribute("codigoPreview", otDAO.generarCodigoOt());
            req.setAttribute("modelosPrenda", new ModeloPrendaDAO().listarTodos());
        } catch (Exception ignored) { }
        req.setAttribute("errorCrear", msg); // señal para reabrir el modal
        try {
            req.getRequestDispatcher("/vista/ordenes_trabajo.jsp").forward(req, resp);
        } catch (Exception e) {
            resp.sendRedirect(req.getContextPath() + "/ordenes-trabajo");
        }
    }
}
