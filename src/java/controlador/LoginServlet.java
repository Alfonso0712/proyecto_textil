package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.PermisoDAO;
import modelo.Usuario;
import modelo.UsuarioDAO;

import java.io.IOException;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Servlet de Login (HU08 + HU09).
 * Ubicación: controlador/LoginServlet.java
 *
 * Añadido para HU09:
 *  - Bloqueo por intentos fallidos (máx 5 en 10 min)
 *  - Carga de permisos en sesión después del login exitoso
 *  - Registro en tabla intentos_login (auditoría)
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private static final int MAX_INTENTOS = 5;
    private static final int MINUTOS_BLOQUEO = 10;

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final PermisoDAO permisoDAO = new PermisoDAO();

    /** Redireccionamiento por rol después del login */
    private static final Map<String, String> RUTA_POR_ROL = new HashMap<>();
    static {
        RUTA_POR_ROL.put("ADMINISTRADOR",   "/gestion-usuarios");
        RUTA_POR_ROL.put("JEFE_ALMACEN",    "/dashboard");
        RUTA_POR_ROL.put("JEFE_PRODUCCION", "/dashboard");
        RUTA_POR_ROL.put("TIZADOR",         "/dashboard");
        RUTA_POR_ROL.put("SUPERVISOR",      "/dashboard");
        RUTA_POR_ROL.put("MAQUINISTA",      "/dashboard");
    }

    // ── GET ───────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("usuarioSesion") != null) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }
        req.getRequestDispatcher("/vista/login.jsp").forward(req, resp);
    }

    // ── POST ──────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String ip       = req.getRemoteAddr();

        // ── Validación de campos vacíos ────────────────────────
        if (username == null || username.isBlank()
                || password == null || password.isBlank()) {
            req.setAttribute("error", "Ingresa usuario y contraseña.");
            req.getRequestDispatcher("/vista/login.jsp").forward(req, resp);
            return;
        }

        // ── Verificar bloqueo por intentos fallidos ────────────
        if (estaBloqueado(username, ip)) {
            req.setAttribute("error",
                    "Cuenta bloqueada por " + MINUTOS_BLOQUEO +
                    " min por múltiples intentos fallidos. Intenta más tarde.");
            req.getRequestDispatcher("/vista/login.jsp").forward(req, resp);
            return;
        }

        // ── Validar credenciales ───────────────────────────────
        Usuario usuario = usuarioDAO.validarLogin(username, password);

        if (usuario == null) {
            registrarIntento(username, ip, false);
            int restantes = MAX_INTENTOS - contarIntentosFallidos(username, ip);
            String msgError = restantes > 0
                    ? "Usuario o contraseña incorrectos. Intentos restantes: " + restantes
                    : "Cuenta bloqueada por " + MINUTOS_BLOQUEO + " min.";
            req.setAttribute("error", msgError);
            req.getRequestDispatcher("/vista/login.jsp").forward(req, resp);
            return;
        }

        // ── Login exitoso ──────────────────────────────────────
        registrarIntento(username, ip, true);

        // Cargar permisos del rol y guardar en sesión (cacheo)
        Set<String> permisos = permisoDAO.obtenerCodigosPorRol(usuario.getIdRol());

        HttpSession session = req.getSession(true);
        session.setAttribute("usuarioSesion",   usuario);
        session.setAttribute("permisosUsuario", permisos);
        session.setMaxInactiveInterval(60 * 30); // 30 minutos

        // Redirigir según rol
        String destino = RUTA_POR_ROL.getOrDefault(
                usuario.getNombreRol().toUpperCase(), "/dashboard");
        resp.sendRedirect(req.getContextPath() + destino);
    }

    // ── Bloqueo por intentos ──────────────────────────────────

    /**
     * Revisa si el usuario/IP tiene ≥ MAX_INTENTOS fallidos en los últimos MINUTOS_BLOQUEO.
     */
    private boolean estaBloqueado(String username, String ip) {
        String sql = """
                SELECT COUNT(*) FROM intentos_login
                 WHERE username  = ?
                   AND ip_origen = ?
                   AND exitoso   = 0
                   AND fecha     > DATE_SUB(NOW(), INTERVAL ? MINUTE)
                """;
        try (Connection cn = modelo.ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, ip);
            ps.setInt   (3, MINUTOS_BLOQUEO);
            ResultSet rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) >= MAX_INTENTOS;
        } catch (SQLException e) {
            // Si falla la consulta, dejamos pasar (no bloqueamos por error de BD)
            return false;
        }
    }

    /** Cuenta intentos fallidos recientes para mostrar cuántos restan. */
    private int contarIntentosFallidos(String username, String ip) {
        String sql = """
                SELECT COUNT(*) FROM intentos_login
                 WHERE username  = ?
                   AND ip_origen = ?
                   AND exitoso   = 0
                   AND fecha     > DATE_SUB(NOW(), INTERVAL ? MINUTE)
                """;
        try (Connection cn = modelo.ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, ip);
            ps.setInt   (3, MINUTOS_BLOQUEO);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            return 0;
        }
    }

    /** Registra el intento (exitoso o no) en la tabla intentos_login. */
    private void registrarIntento(String username, String ip, boolean exitoso) {
        String sql = "INSERT INTO intentos_login (username, ip_origen, exitoso) VALUES (?, ?, ?)";
        try (Connection cn = modelo.ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString (1, username);
            ps.setString (2, ip);
            ps.setBoolean(3, exitoso);
            ps.executeUpdate();
        } catch (SQLException e) {
            // Silencioso — no interrumpir el flujo por error de auditoría
        }
    }
}
