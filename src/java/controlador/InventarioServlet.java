package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;
import java.util.Map;
import java.util.HashMap;

import java.io.*;
import java.math.BigDecimal;
import java.nio.file.*;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Servlet de Inventario de Telas (HU01).
 * Ubicación: controlador/InventarioServlet.java
 *
 * Implementa los 4 casos de uso de HU01:
 *   CUS 1.1 Registrar Recepción de Tela
 *   CUS 1.2 Comparar Peso Real vs Guía  (lógica en Tela.hayDiscrepanciaPeso)
 *   CUS 1.3 Registrar Observaciones de Calidad
 *   CUS 1.4 Cargar Evidencia Fotográfica
 *
 * Mapeos URL:
 *   GET  /inventario              → lista de telas recibidas
 *   GET  /inventario?accion=nuevo → formulario de registro
 *   GET  /inventario?accion=detalle&id=N → detalle de una tela con fotos
 *   POST /inventario              → guardar nueva recepción de tela + fotos
 *
 * @MultipartConfig habilita recepción de archivos (fotos)
 */
@WebServlet("/inventario")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB en memoria antes de escribir a disco
    maxFileSize       = 5 * 1024 * 1024,  // 5 MB máximo por foto
    maxRequestSize    = 20 * 1024 * 1024  // 20 MB máximo por request total
)
public class InventarioServlet extends HttpServlet {

    private final TelaDAO     telaDAO     = new TelaDAO();
    private final FotoTelaDAO fotoDAO     = new FotoTelaDAO();

    // Subcarpeta dentro de la aplicación web donde se guardan las fotos
    private static final String CARPETA_FOTOS = "uploads" + File.separator + "telas";

    // ── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String accion = req.getParameter("accion");
        
        if ("buscarProveedor".equals(accion)) {
            buscarProveedorApi(req, resp);
            return;
        }
        
        if ("nuevo".equals(accion)) {
            mostrarFormularioNuevo(req, resp);
            return;
        }

        if ("detalle".equals(accion)) {
            mostrarDetalle(req, resp);
            return;
        }

        // Por defecto: listado
        listarTelas(req, resp);
    }

    // ── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        if ("actualizarTela".equals(accion)) {
            actualizarTela(req, resp);
        } else {
            registrarTela(req, resp);
        }
    }
    // ── BUSCAR PROVEEDOR EN API EXTERNA ─────────────────────────
    private void buscarProveedorApi(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String doc = req.getParameter("doc");
        
        // Validación básica
        if (doc == null || (doc.trim().length() != 8 && doc.trim().length() != 11)) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String urlApi = (doc.trim().length() == 8)
                ? "https://api.apis.net.pe/v2/reniec/dni?numero=" + doc.trim()
                : "https://api.apis.net.pe/v2/sunat/ruc?numero=" + doc.trim();

        // Tu token está seguro aquí en el backend
        String token = "sk_15791.nXVZFZyCxFNFXMirkAtNRE7ayH3eugWu"; 

        java.net.HttpURLConnection conexion = (java.net.HttpURLConnection) new java.net.URL(urlApi).openConnection();
        conexion.setRequestMethod("GET");
        conexion.setRequestProperty("Authorization", "Bearer " + token);
        conexion.setRequestProperty("Accept", "application/json");

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        try {
            int estado = conexion.getResponseCode();
            if (estado == 200) {
                // Leer la respuesta de la API y enviarla al JSP
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
    // ── LISTAR ───────────────────────────────────────────────

    private void listarTelas(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Leer parámetros de búsqueda
        String filtroCodigo    = req.getParameter("fCodigo");
        String filtroProveedor = req.getParameter("fProveedor");
        String filtroFechaIni  = req.getParameter("fFechaIni");
        String filtroFechaFin  = req.getParameter("fFechaFin");

        List<Tela> listaTelas;
        if ((filtroCodigo != null && !filtroCodigo.isBlank()) ||
            (filtroProveedor != null && !filtroProveedor.isBlank()) ||
            (filtroFechaIni != null && !filtroFechaIni.isBlank()) ||
            (filtroFechaFin != null && !filtroFechaFin.isBlank())) {
            listaTelas = telaDAO.listarConFiltros(filtroCodigo, filtroProveedor, filtroFechaIni, filtroFechaFin);
        } else {
            listaTelas = telaDAO.listarTodas();
        }

        // Pasar los filtros de vuelta a la vista
        req.setAttribute("filtroCodigo",    filtroCodigo);
        req.setAttribute("filtroProveedor", filtroProveedor);
        req.setAttribute("filtroFechaIni",  filtroFechaIni);
        req.setAttribute("filtroFechaFin",  filtroFechaFin);

        // El resto igual que antes (mensaje, OTs, catálogos, fotos)
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("mensajeExito") != null) {
            req.setAttribute("mensajeExito", session.getAttribute("mensajeExito"));
            session.removeAttribute("mensajeExito");
        }
        try {
            req.setAttribute("otsActivas", new OrdenTrabajoDAO().listarActivas());
        } catch (Exception ignored) {
            req.setAttribute("otsActivas", new ArrayList<>());
        }
        req.setAttribute("catalogoTelas", new CatalogoTelaDAO().listarTodos());

        Map<Integer, List<FotoTela>> fotosMap = new HashMap<>();
        for (Tela t : listaTelas) {
            fotosMap.put(t.getIdTela(), fotoDAO.listarPorTela(t.getIdTela()));
        }
        req.setAttribute("fotosMap", fotosMap);
        req.setAttribute("listaTelas", listaTelas);
        req.getRequestDispatcher("/vista/inventario.jsp").forward(req, resp);
    }
    // ── FORMULARIO NUEVO ─────────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Cargar OTs activas para el select del formulario (CUS 1.1)
        try {
            List<OrdenTrabajo> otsActivas = new OrdenTrabajoDAO().listarActivas();
            req.setAttribute("otsActivas", otsActivas);
        } catch (SQLException e) {
            req.setAttribute("otsActivas", new ArrayList<>());
        }

        req.getRequestDispatcher("/vista/registro_tela.jsp").forward(req, resp);
    }
   
    private void actualizarTela(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Obtener usuario de sesión para validar permisos
        HttpSession session = req.getSession(false);
        Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");

        int idTela = Integer.parseInt(req.getParameter("id_tela"));
        int idOtFormulario = Integer.parseInt(req.getParameter("id_ot"));

        // --- SEGURIDAD: Validar cambio de OT ---
        Tela telaOriginal = telaDAO.buscarPorId(idTela);
        int idOtFinal = telaOriginal.getIdOt(); // Por defecto, mantenemos la OT original
        
        // Solo si es administrador, permitimos que el id_ot del formulario reemplace al original
        if ("ADMINISTRADOR".equals(usuarioSesion.getNombreRol())) {
            idOtFinal = idOtFormulario;
        }
        
        // Parámetros editables
        String origen = req.getParameter("origen");
        String proveedor = req.getParameter("proveedor");
        String tipoTejido = req.getParameter("tipo_tejido");
        String color = req.getParameter("color");
        int numRollos = Integer.parseInt(req.getParameter("num_rollos"));
        BigDecimal pesoGuia = new BigDecimal(req.getParameter("peso_guia"));
        BigDecimal pesoReal = new BigDecimal(req.getParameter("peso_real"));
        String estadoCalidad = req.getParameter("estado_calidad");
        String observaciones = req.getParameter("observaciones");
        boolean requiereReposo = "on".equals(req.getParameter("requiere_reposo"));
        String idCatalogoStr = req.getParameter("id_catalogo_tela");
        Integer idCatalogo = (idCatalogoStr != null && !idCatalogoStr.isBlank()) ? Integer.parseInt(idCatalogoStr) : null;

        // Validaciones
        if (observaciones == null || observaciones.trim().isEmpty()) {
            enviarErrorEdicion(req, resp, "Las observaciones son obligatorias.");
            return;
        }
        if (pesoGuia.compareTo(BigDecimal.ZERO) <= 0 || pesoReal.compareTo(BigDecimal.ZERO) <= 0) {
            enviarErrorEdicion(req, resp, "Los pesos deben ser mayores a cero.");
            return;
        }

        // Actualizar en BD
        TelaDAO telaDAO = new TelaDAO();
        // Más abajo, cuando llamas a actualizarTelaCompleta, asegúrate de pasar idOtFinal en lugar de idOt
        boolean actualizado = telaDAO.actualizarTelaCompleta(idTela, idOtFinal, origen, proveedor,
                tipoTejido, color, numRollos, pesoGuia, pesoReal,
                Tela.EstadoCalidad.valueOf(estadoCalidad), observaciones, requiereReposo, idCatalogo);

        // Guardar nuevas fotos si se subieron
        if (actualizado) {
            guardarFotos(req, idTela);
        }

        session = req.getSession();
        if (actualizado) {
            session.setAttribute("mensajeExito", "✅ Tela actualizada correctamente.");
        }if (actualizado && "ACEPTADO".equals(estadoCalidad)) {
            verificarYCambiarOtAEnProceso(idOtFinal);
        } else {
            session.setAttribute("mensajeExito", "⚠️ No se realizaron cambios.");
        }
        resp.sendRedirect(req.getContextPath() + "/inventario");
    }

    private void enviarErrorEdicion(HttpServletRequest req, HttpServletResponse resp, String mensaje) throws IOException {
        HttpSession session = req.getSession();
        session.setAttribute("mensajeExito", "❌ " + mensaje);
        resp.sendRedirect(req.getContextPath() + "/inventario");
    }
    // ── DETALLE DE TELA ───────────────────────────────────────

    private void mostrarDetalle(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/inventario");
            return;
        }

        int idTela = Integer.parseInt(idStr);
        Tela tela  = telaDAO.buscarPorId(idTela);

        if (tela == null) {
            resp.sendRedirect(req.getContextPath() + "/inventario");
            return;
        }

        List<FotoTela> fotos = fotoDAO.listarPorTela(idTela);
        req.setAttribute("tela", tela);
        req.setAttribute("fotos", fotos);
        req.getRequestDispatcher("/vista/detalle_tela.jsp").forward(req, resp);
    }

    // ── REGISTRAR NUEVA TELA ─────────────────────────────────

    private void registrarTela(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── Obtener usuario de sesión ──
        HttpSession session = req.getSession(false);
        Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");

        // ── Leer parámetros ──
        String idOtStr       = req.getParameter("id_ot");
        String origen        = req.getParameter("origen");
        String proveedor     = req.getParameter("proveedor");
        String pesoGuiaStr   = req.getParameter("peso_guia");
        String pesoRealStr   = req.getParameter("peso_real");
        String tipoTejido    = req.getParameter("tipo_tejido");
        String color         = req.getParameter("color");
        String numRollosStr  = req.getParameter("num_rollos");
        String observaciones = req.getParameter("observaciones");
        String estadoCal     = req.getParameter("estado_calidad");
        String reposo        = req.getParameter("requiere_reposo");
        String idCatalogoStr = req.getParameter("id_catalogo_tela");
        int idCatalogo = 0;
        CatalogoTelaDAO catalogoDAO = new CatalogoTelaDAO();
        CatalogoTela catalogoSeleccionado = null;

        if (idCatalogoStr != null && !idCatalogoStr.isBlank()) {
            idCatalogo = Integer.parseInt(idCatalogoStr);
            catalogoSeleccionado = catalogoDAO.buscarPorId(idCatalogo);
        }

        // ── Validaciones (CUS 1.1 y CA2) ──
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
            mostrarFormularioNuevo(req, resp);
            return;
        }

        // ── Construir entidad Tela ──
        Tela tela = new Tela();
        tela.setIdOt(Integer.parseInt(idOtStr.trim()));
        tela.setIdRegistrador(usuarioSesion.getIdUsuario());
        tela.setOrigen(Tela.Origen.valueOf(origen));
        tela.setProveedor(proveedor != null ? proveedor.trim() : null);
        tela.setPesoGuia(new BigDecimal(pesoGuiaStr.trim()));
        tela.setPesoReal(new BigDecimal(pesoRealStr.trim()));
        tela.setTipoTejido(tipoTejido != null ? tipoTejido.trim() : null);
        tela.setColor(color != null ? color.trim() : null);
        tela.setNumRollos(numRollosStr != null && !numRollosStr.isBlank()
                ? Integer.parseInt(numRollosStr.trim()) : 1);
        tela.setObservaciones(observaciones.trim());
        tela.setEstadoCalidad(
                estadoCal != null && !estadoCal.isBlank()
                        ? Tela.EstadoCalidad.valueOf(estadoCal)
                        : Tela.EstadoCalidad.OBSERVADO);
        tela.setRequiereReposo("on".equals(reposo) || "true".equals(reposo));
        tela.setIdCatalogoTela(idCatalogo > 0 ? idCatalogo : 0);
        // Si se seleccionó un material del catálogo, heredar el nombre y posiblemente el reposo
        if (catalogoSeleccionado != null) {
            tela.setTipoTejido(catalogoSeleccionado.getNombre()); // usar el nombre del catálogo
            if (catalogoSeleccionado.isRequiereReposo()) {
                tela.setRequiereReposo(true); // forzar reposo según catálogo
            }
        }
        tela.setRequiereReposo("on".equals(reposo) || "true".equals(reposo) || 
        (catalogoSeleccionado != null && catalogoSeleccionado.isRequiereReposo()));
        // Código único
        tela.setCodigoTela(telaDAO.generarSiguienteCodigoTela());

        // Diferencia de peso para mostrar en alerta (CUS 1.2)
        BigDecimal diferencia = tela.getPesoReal().subtract(tela.getPesoGuia());
        tela.setDiferenciaPeso(diferencia);

        // ── Persistir tela en BD ──
        boolean guardado = telaDAO.insertar(tela);

        if (!guardado) {
            req.setAttribute("error", "No se pudo guardar el registro. Intenta nuevamente.");
            mostrarFormularioNuevo(req, resp);
            return;
        }

        // ── Guardar fotos (CUS 1.4) ──
        guardarFotos(req, tela.getIdTela());

        // ── Mensaje de éxito con alerta de peso si aplica (CA1 HU01) ──
        String msg = "✅ Tela " + tela.getCodigoTela() + " registrada correctamente.";
        if (guardado && tela.getEstadoCalidad() == Tela.EstadoCalidad.ACEPTADO) {
            verificarYCambiarOtAEnProceso(tela.getIdOt());
        }
        if (tela.hayDiscrepanciaPeso()) {
            msg += " ⚠ ALERTA: diferencia de peso de "
                   + String.format("%+.3f", diferencia.doubleValue())
                   + " kg — supera el 1% permitido. Verificar con el proveedor.";
        }

        session.setAttribute("mensajeExito", msg);
        resp.sendRedirect(req.getContextPath() + "/inventario");
    }
        // Nuevo método auxiliar
    private void verificarYCambiarOtAEnProceso(int idOt) {
        try {
            OrdenTrabajoDAO otDAO = new OrdenTrabajoDAO();
            OrdenTrabajo ot = otDAO.buscarPorId(idOt);
            if (ot != null && "CREADA".equals(ot.getEstado())) {
                boolean cambiado = otDAO.cambiarEstado(idOt, "EN_PROCESO");
                if (cambiado) {
                    new AsignacionCargaDAO().generarAsignaciones(idOt);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace(); // log error sin interrumpir el flujo principal
        }
    }
    // ── GUARDAR FOTOS ─────────────────────────────────────────

    /**
     * Procesa y guarda las fotos de evidencia fotográfica (CUS 1.4).
     * Las fotos se guardan en {webRoot}/uploads/telas/{idTela}/
     * y se registran en la tabla fotos_tela.
     */
    private void guardarFotos(HttpServletRequest req, int idTela) {
        try {
            // Ruta absoluta donde se guardarán las fotos
            String webRoot   = getServletContext().getRealPath("/");
            Path   carpeta   = Paths.get(webRoot, CARPETA_FOTOS,
                                         String.valueOf(idTela));
            Files.createDirectories(carpeta);

            // Extensiones permitidas
            java.util.Set<String> extPermitidas = java.util.Set.of(
                ".jpg", ".jpeg", ".png", ".webp"
            );

            for (Part part : req.getParts()) {
                // Solo procesar partes con name="fotos"
                if (!"fotos".equals(part.getName())) continue;

                String nombreOriginal = extraerNombreArchivo(part);
                if (nombreOriginal == null || nombreOriginal.isBlank()) continue;
                if (part.getSize() == 0) continue;

                // Validar extensión
                String ext = nombreOriginal.lastIndexOf('.') > 0
                        ? nombreOriginal.substring(nombreOriginal.lastIndexOf('.')).toLowerCase()
                        : "";
                if (!extPermitidas.contains(ext)) continue;

                // Nombre único para evitar colisiones
                String nombreUnico = UUID.randomUUID().toString() + ext;
                Path   destino     = carpeta.resolve(nombreUnico);

                // Guardar archivo en disco
                try (InputStream is = part.getInputStream()) {
                    Files.copy(is, destino, StandardCopyOption.REPLACE_EXISTING);
                }

                // Ruta relativa para src del <img> en JSP
               
                String rutaRelativa = "uploads/telas/" + idTela + "/" + nombreUnico;

                // Registrar en BD
                FotoTela foto = new FotoTela(idTela, nombreUnico, rutaRelativa);
                fotoDAO.insertar(foto);
            }

        } catch (Exception e) {
            // No interrumpir el flujo si falla la foto — solo loguear
            getServletContext().log("[InventarioServlet] Error al guardar fotos: "
                                   + e.getMessage(), e);
        }
    }

    /**
     * Extrae el nombre del archivo del header Content-Disposition de la parte.
     */
    private String extraerNombreArchivo(Part part) {
        String cd = part.getHeader("content-disposition");
        if (cd == null) return null;
        for (String token : cd.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim()
                            .replace("\"", "");
            }
        }
        return null;
    }
    
}
