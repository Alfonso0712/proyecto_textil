package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.util.List;

/**
 * Servlet: Gestión de Usuarios (HU09)
 * Ubicación: controlador/GestionUsuariosServlet.java
 * URL base: /gestion-usuarios
 *
 * Responsabilidad:
 *  - Listar, crear, editar y desactivar cuentas de usuario
 *  - Solo accesible por el rol ADMINISTRADOR (protegido en SesionFiltro)
 *
 * Mapeo de acciones via parámetro ?accion=:
 *   listar   → GET  → muestra tabla de usuarios
 *   nuevo    → GET  → muestra formulario vacío
 *   editar   → GET  → carga formulario con datos del usuario
 *   guardar  → POST → inserta nuevo usuario
 *   actualizar → POST → actualiza usuario existente
 *   desactivar → POST → desactiva cuenta (soft delete)
 *   activar    → POST → reactiva cuenta
 */
@WebServlet("/gestion-usuarios")
public class GestionUsuariosServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final RolDAO     rolDAO     = new RolDAO();

    // ── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Solo ADMINISTRADOR puede entrar (doble seguridad además del filtro)
        if (!esAdministrador(req)) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=acceso");
            return;
        }

        String accion = req.getParameter("accion");
        if (accion == null) accion = "listar";

        switch (accion) {
            case "nuevo"  -> mostrarFormularioNuevo(req, resp);
            case "editar" -> mostrarFormularioEditar(req, resp);
            default       -> listarUsuarios(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!esAdministrador(req)) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=acceso");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        if (accion == null) accion = "";

        switch (accion) {
            case "guardar"     -> guardarNuevoUsuario(req, resp);
            case "actualizar"  -> actualizarUsuario(req, resp);
            case "desactivar"  -> cambiarEstado(req, resp, false);
            case "activar"     -> cambiarEstado(req, resp, true);
            default            -> listarUsuarios(req, resp);
        }
    }

    // ── LISTAR ────────────────────────────────────────────────

    private void listarUsuarios(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Usuario> usuarios = usuarioDAO.listarTodos();
        req.setAttribute("usuarios", usuarios);
        req.setAttribute("titulo",   "Gestión de Usuarios");
        req.getRequestDispatcher("/vista/gestion_usuarios.jsp").forward(req, resp);
    }

    // ── FORMULARIO NUEVO ──────────────────────────────────────

    private void mostrarFormularioNuevo(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("roles",    rolDAO.listarTodos());
        req.setAttribute("accion",   "guardar");
        req.setAttribute("titulo",   "Nuevo Usuario");
        req.setAttribute("usuario",  new Usuario()); // Objeto vacío para el form
        req.getRequestDispatcher("/vista/form_usuario.jsp").forward(req, resp);
    }

    // ── FORMULARIO EDITAR ─────────────────────────────────────

    private void mostrarFormularioEditar(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idParam = req.getParameter("id");
        if (idParam == null || idParam.isBlank()) {
            redirigirConMensaje(resp, req, "error", "ID de usuario inválido.");
            return;
        }
        try {
            int id = Integer.parseInt(idParam);
            Usuario u = usuarioDAO.buscarPorId(id);
            if (u == null) {
                redirigirConMensaje(resp, req, "error", "Usuario no encontrado.");
                return;
            }
            req.setAttribute("usuario", u);
            req.setAttribute("roles",   rolDAO.listarTodos());
            req.setAttribute("accion",  "actualizar");
            req.setAttribute("titulo",  "Editar Usuario");
            req.getRequestDispatcher("/vista/form_usuario.jsp").forward(req, resp);
        } catch (NumberFormatException e) {
            redirigirConMensaje(resp, req, "error", "ID de usuario inválido.");
        }
    }

    // ── GUARDAR NUEVO ─────────────────────────────────────────

    private void guardarNuevoUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String username  = req.getParameter("username");
        String password  = req.getParameter("password");
        String nombre    = req.getParameter("nombre");
        String apellido  = req.getParameter("apellido");
        String email     = req.getParameter("email");
        String idRolStr  = req.getParameter("idRol");

        // ── Validaciones ──────────────────────────────────────
        String errorMsg = validarCamposNuevoUsuario(username, password, nombre,
                                                    apellido, email, idRolStr);
        if (errorMsg != null) {
            req.setAttribute("error",   errorMsg);
            req.setAttribute("roles",   rolDAO.listarTodos());
            req.setAttribute("accion",  "guardar");
            req.setAttribute("titulo",  "Nuevo Usuario");
            // Preservar valores ingresados
            Usuario u = new Usuario();
            u.setUsername(username); u.setNombre(nombre);
            u.setApellido(apellido); u.setEmail(email);
            req.setAttribute("usuario", u);
            req.getRequestDispatcher("/vista/form_usuario.jsp").forward(req, resp);
            return;
        }

        Usuario u = new Usuario();
        u.setUsername(username.trim());
        u.setPassword(password);          // DAO cifrará con BCrypt
        u.setNombre(nombre.trim());
        u.setApellido(apellido.trim());
        u.setEmail(email.trim());
        u.setIdRol(Integer.parseInt(idRolStr));
        u.setActivo(true);

        try {
            boolean ok = usuarioDAO.insertar(u);
            if (ok) {
                redirigirConMensaje(resp, req, "exito",
                        "Usuario '" + username + "' creado exitosamente.");
            } else {
                redirigirConMensaje(resp, req, "error",
                        "No se pudo crear el usuario. Intente nuevamente.");
            }
        } catch (RuntimeException e) {
            String msg = e.getMessage().contains("Duplicate")
                    ? "El username o email ya está registrado."
                    : "Error al crear usuario: " + e.getMessage();
            req.setAttribute("error",  msg);
            req.setAttribute("roles",  rolDAO.listarTodos());
            req.setAttribute("accion", "guardar");
            req.setAttribute("titulo", "Nuevo Usuario");
            req.setAttribute("usuario", u);
            req.getRequestDispatcher("/vista/form_usuario.jsp").forward(req, resp);
        }
    }

    // ── ACTUALIZAR ────────────────────────────────────────────

    private void actualizarUsuario(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String idStr    = req.getParameter("idUsuario");
        String nombre   = req.getParameter("nombre");
        String apellido = req.getParameter("apellido");
        String email    = req.getParameter("email");
        String idRolStr = req.getParameter("idRol");
        String password = req.getParameter("password"); // Puede estar vacío (no cambiar)
        String activoStr = req.getParameter("activo");

        if (idStr == null || idStr.isBlank()) {
            redirigirConMensaje(resp, req, "error", "ID inválido.");
            return;
        }

        // Validación básica
        if (nombre == null || nombre.isBlank()
                || apellido == null || apellido.isBlank()
                || email == null || email.isBlank()
                || idRolStr == null || idRolStr.isBlank()) {
            redirigirConMensaje(resp, req, "error", "Todos los campos son obligatorios.");
            return;
        }
        if (!email.matches("^[\\w.+-]+@[\\w-]+\\.[\\w.-]+$")) {
            redirigirConMensaje(resp, req, "error", "Email inválido.");
            return;
        }
        // Si ingresó nueva contraseña, validar longitud mínima
        if (password != null && !password.isBlank() && password.length() < 6) {
            redirigirConMensaje(resp, req, "error",
                    "La nueva contraseña debe tener al menos 6 caracteres.");
            return;
        }

        Usuario u = new Usuario();
        u.setIdUsuario(Integer.parseInt(idStr));
        u.setNombre(nombre.trim());
        u.setApellido(apellido.trim());
        u.setEmail(email.trim());
        u.setIdRol(Integer.parseInt(idRolStr));
        u.setActivo("1".equals(activoStr) || "true".equals(activoStr));
        // Si password viene vacío, DAO lo omite
        u.setPassword((password != null && !password.isBlank()) ? password : "");

        boolean ok = usuarioDAO.actualizar(u);
        if (ok) {
            redirigirConMensaje(resp, req, "exito", "Usuario actualizado correctamente.");
        } else {
            redirigirConMensaje(resp, req, "error",
                    "No se pudo actualizar el usuario.");
        }
    }

    // ── CAMBIAR ESTADO (activar/desactivar) ───────────────────

    private void cambiarEstado(HttpServletRequest req, HttpServletResponse resp,
                                boolean activar) throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            redirigirConMensaje(resp, req, "error", "ID inválido.");
            return;
        }
        int id = Integer.parseInt(idStr.trim());

        // No permitir desactivar al propio administrador logueado
        Usuario sesion = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (sesion != null && sesion.getIdUsuario() == id && !activar) {
            redirigirConMensaje(resp, req, "error",
                    "No puedes desactivar tu propia cuenta.");
            return;
        }

        boolean ok;
        String msg;
        if (activar) {
            // Reutilizamos actualizar con activo=true
            Usuario u = usuarioDAO.buscarPorId(id);
            if (u == null) { redirigirConMensaje(resp, req, "error", "Usuario no encontrado."); return; }
            u.setActivo(true);
            u.setPassword(""); // No cambiar contraseña
            ok  = usuarioDAO.actualizar(u);
            msg = ok ? "Cuenta activada." : "No se pudo activar la cuenta.";
        } else {
            ok  = usuarioDAO.desactivar(id);
            msg = ok ? "Cuenta desactivada." : "No se pudo desactivar la cuenta.";
        }
        redirigirConMensaje(resp, req, ok ? "exito" : "error", msg);
    }

    // ── HELPERS ───────────────────────────────────────────────

    /** Verifica que el usuario en sesión sea ADMINISTRADOR */
    private boolean esAdministrador(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioSesion");
        return u != null && "ADMINISTRADOR".equalsIgnoreCase(u.getNombreRol());
    }

    /** Redirige a listado con mensaje de éxito o error como parámetro */
    private void redirigirConMensaje(HttpServletResponse resp, HttpServletRequest req,
                                      String tipo, String msg) throws IOException {
        resp.sendRedirect(req.getContextPath()
                + "/gestion-usuarios?accion=listar&" + tipo + "="
                + java.net.URLEncoder.encode(msg, "UTF-8"));
    }

    /**
     * Valida los campos del formulario de nuevo usuario.
     * @return mensaje de error, o null si todo es válido.
     */
    private String validarCamposNuevoUsuario(String username, String password,
            String nombre, String apellido, String email, String idRolStr) {

        if (username == null || username.isBlank())  return "El username es obligatorio.";
        if (username.length() < 4)                   return "El username debe tener al menos 4 caracteres.";
        if (password == null || password.isBlank())  return "La contraseña es obligatoria.";
        if (password.length() < 6)                   return "La contraseña debe tener al menos 6 caracteres.";
        if (nombre == null   || nombre.isBlank())    return "El nombre es obligatorio.";
        if (apellido == null || apellido.isBlank())  return "El apellido es obligatorio.";
        if (email == null    || email.isBlank())     return "El email es obligatorio.";
        if (!email.matches("^[\\w.+-]+@[\\w-]+\\.[\\w.-]+$")) return "El email no tiene formato válido.";
        if (idRolStr == null || idRolStr.isBlank())  return "Debes seleccionar un rol.";
        try { Integer.parseInt(idRolStr); } catch (NumberFormatException e) { return "Rol inválido."; }
        return null;
    }
}
