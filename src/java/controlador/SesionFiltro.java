package controlador;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import modelo.PermisoDAO;
import modelo.Usuario;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Filtro de Seguridad de Sesión y Permisos.
 * Ubicación: controlador/SesionFiltro.java
 * HU08 + HU09: Autenticación + Control de Acceso por Rol
 *
 * Reemplaza el SesionFiltro anterior añadiendo:
 *  - Carga de permisos del usuario al momento del login
 *  - Verificación de permiso por ruta en cada request
 *  - Bloqueo por intentos fallidos (gestionado en LoginServlet)
 */
@WebFilter("/*")
public class SesionFiltro implements Filter {

    private static final Set<String> RUTAS_PUBLICAS = new HashSet<>(Arrays.asList(
        "/login", "/login.jsp", "/index.html",
        "/css", "/js", "/img", "/favicon.ico",
        "/setup"
));

    /**
     * Mapa de ruta → código de permiso requerido.
     * Si una ruta no aparece aquí solo requiere sesión activa.
     */
    private static final Object[][] RUTAS_PERMISOS = {
        { "/gestion-usuarios",  "SEG_USUARIOS_VER"    },
        { "/inventario",        "ALM_TELA_VER"        },
        { "/registro-tela",     "ALM_TELA_REGISTRAR"  },
        { "/ordenes-trabajo",   "PROD_OT_VER"         },
        { "/tiempos-reposo",    "PROD_REPOSO_GESTION" },
        { "/mermas",            "PROD_MERMA_REG"      },
        { "/fallas-tela",       "PROD_FALLAS_REG"     },
        { "/cargas-trabajo",    "PROD_CARGAS_ASIG"    },
        { "/defectos",          "CAL_DEFECTOS_REG"    },
        { "/despacho",          "DES_CONCIL_REG"      },
        { "/reportes",          "RPT_MERMAS_CALIDAD"  },
    };

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        String contextPath  = request.getContextPath();
        String requestURI   = request.getRequestURI();
        String rutaRelativa = requestURI.substring(contextPath.length());

        // ── 1. Recursos públicos: pasar sin revisión ───────────
        if (esRutaPublica(rutaRelativa)) {
            chain.doFilter(req, res);
            return;
        }

        // ── 2. Verificar sesión activa ─────────────────────────
        HttpSession session = request.getSession(false);
        Usuario usuario = (session != null)
                ? (Usuario) session.getAttribute("usuarioSesion")
                : null;

        if (usuario == null) {
            response.sendRedirect(contextPath + "/login");
            return;
        }

        // ── 3. Verificar permiso por ruta ──────────────────────
        String codigoRequerido = obtenerCodigoRequerido(rutaRelativa);
        if (codigoRequerido != null) {
            Set<String> permisosUsuario = obtenerPermisosDeSession(session, usuario);
            if (!permisosUsuario.contains(codigoRequerido)) {
                // Sin permiso: redirigir al dashboard con aviso
                response.sendRedirect(contextPath + "/dashboard?error=sinPermiso");
                return;
            }
        }

        // ── 4. Acceso permitido ────────────────────────────────
        chain.doFilter(req, res);
    }

    // ── Helpers ───────────────────────────────────────────────

    private boolean esRutaPublica(String ruta) {
        for (String publica : RUTAS_PUBLICAS) {
            if (ruta.equals(publica) || ruta.startsWith(publica + "/")) return true;
        }
        return false;
    }

    /**
     * Determina el código de permiso requerido para la ruta dada.
     * @return código (ej: "ALM_TELA_VER") o null si no hay restricción específica.
     */
    private String obtenerCodigoRequerido(String ruta) {
        for (Object[] entrada : RUTAS_PERMISOS) {
            String prefijo = (String) entrada[0];
            if (ruta.startsWith(prefijo)) {
                return (String) entrada[1];
            }
        }
        return null;
    }

    /**
     * Obtiene los permisos del usuario cacheados en sesión.
     * Si aún no están cargados, los consulta de BD y los guarda en sesión.
     * Esto evita consultas a BD en cada request.
     */
    @SuppressWarnings("unchecked")
    private Set<String> obtenerPermisosDeSession(HttpSession session, Usuario usuario) {
        Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
        if (permisos == null) {
            // Carga desde BD y cachea en sesión
            permisos = new PermisoDAO().obtenerCodigosPorRol(usuario.getIdRol());
            session.setAttribute("permisosUsuario", permisos);
        }
        return permisos;
    }
}
