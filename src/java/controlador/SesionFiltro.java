package controlador;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import modelo.PermisoDAO;
import modelo.Usuario;

import java.io.IOException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
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

    // ── Control de horario laboral ────────────────────────────
    private static final LocalTime HORA_INICIO_LABORAL = LocalTime.of(7, 0);
    private static final LocalTime HORA_FIN_LABORAL    = LocalTime.of(17, 0);
    private static final ZoneId    ZONA_HORARIA         = ZoneId.of("America/Lima");
    private static final String    ROL_SIN_HORARIO      = "ADMINISTRADOR";
    // Los domingos no hay trabajo (DayOfWeek.SUNDAY = 7)
    // El check se hace dinámicamente en doFilter

    /**
     * Mapa de ruta → código de permiso requerido.
     * Si una ruta no aparece aquí solo requiere sesión activa.
     */
    private static final Object[][] RUTAS_PERMISOS = {
        { "/gestion-usuarios",  "SEG_USUARIOS_VER"    },
        { "/inventario",        "ALM_TELA_VER"        },
        { "/registro-tela",     "ALM_TELA_REGISTRAR"  },
            { "/catalogo-telas",    "CAT_TELAS_VER"       },
            { "/catalogo-modelos",  "CAT_MODELOS_VER"     },
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

        // ── 3. Verificar horario laboral para no-ADMINISTRADORES ─
        if (usuario.isHorarioRestringido() && !"ADMINISTRADOR".equalsIgnoreCase(usuario.getNombreRol())) {
            // Obtener fecha/hora actual
            java.time.ZonedDateTime ahora = java.time.ZonedDateTime.now(ZONA_HORARIA);
            java.time.DayOfWeek diaActual = ahora.getDayOfWeek();

            // Verificar día permitido
            String diasPermitidos = usuario.getHorarioDias() != null ? usuario.getHorarioDias().toUpperCase() : "";
            boolean diaOk = false;
            if (!diasPermitidos.isBlank()) {
                java.util.Map<String, String> mapaDias = java.util.Map.of(
                    "MONDAY", "LUN", "TUESDAY", "MAR", "WEDNESDAY", "MIE",
                    "THURSDAY", "JUE", "FRIDAY", "VIE", "SATURDAY", "SAB", "SUNDAY", "DOM"
                );
                String diaCorto = mapaDias.getOrDefault(diaActual.name(), "");
                diaOk = diasPermitidos.contains(diaCorto);
            }

            if (!diaOk) {
                session.invalidate();
                response.sendRedirect(contextPath + "/login?errorHorario=1");
                return;
            }

            // Verificar hora
            java.time.LocalTime horaInicio = null, horaFin = null;
            try {
                if (usuario.getHorarioInicio() != null && !usuario.getHorarioInicio().isBlank())
                    horaInicio = java.time.LocalTime.parse(usuario.getHorarioInicio());
                if (usuario.getHorarioFin() != null && !usuario.getHorarioFin().isBlank())
                    horaFin = java.time.LocalTime.parse(usuario.getHorarioFin());
            } catch (Exception e) {
                horaInicio = HORA_INICIO_LABORAL;
                horaFin = HORA_FIN_LABORAL;
            }

            if (horaInicio != null && horaFin != null) {
                java.time.LocalTime ahoraHora = ahora.toLocalTime();
                if (ahoraHora.isBefore(horaInicio) || ahoraHora.isAfter(horaFin)) {
                    session.invalidate();
                    response.sendRedirect(contextPath + "/login?errorHorario=1");
                    return;
                }
            }
        }

        // ── 4. Verificar permiso por ruta ──────────────────────
        String codigoRequerido = obtenerCodigoRequerido(rutaRelativa);
        if (codigoRequerido != null) {
            Set<String> permisosUsuario = obtenerPermisosDeSession(session, usuario);
            if (!permisosUsuario.contains(codigoRequerido)) {
                // Sin permiso: redirigir al dashboard con aviso
                response.sendRedirect(contextPath + "/dashboard?error=sinPermiso");
                return;
            }
        }

        // ── 5. Acceso permitido ────────────────────────────────
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
