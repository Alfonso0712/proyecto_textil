package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Set;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Servlet: DefectosServlet
 * Ruta: /defectos
 * HU06: Control de Defectos y Reprocesos
 *
 * Diagrama de secuencia HU06:
 *   Inspector Calidad → UI → RegistrarDefecto → IdentificarMaquinistaResponsable
 *                    → IncrementarContadorReprocesos → ActualizarEstadoPieza
 *                    → NotificarRegistro
 *
 * Permisos requeridos:
 *   - CAL_DEFECTOS_REG → registrar defectos y ver historial
 */
@WebServlet("/defectos")
public class DefectosServlet extends HttpServlet {

    private final DefectoReprocesoDAO defectoDAO = new DefectoReprocesoDAO();
    private final OrdenTrabajoDAO     otDAO      = new OrdenTrabajoDAO();
    private final UsuarioDAO          usuarioDAO = new UsuarioDAO();

    // ── GET ───────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null || !tienePermiso(req, "CAL_DEFECTOS_REG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        try {
            // ✅ FIX: Mostrar solo lo pertinente según el rol
            List<DefectoReproceso> defectos = defectoDAO.listarDefectos(usuario.getIdUsuario(), usuario.getNombreRol());
            req.setAttribute("defectos", defectos);

            List<DefectoReprocesoDAO.ResumenReprocesos> resumen = defectoDAO.resumenPorMaquinista();
            req.setAttribute("resumenReprocesos", resumen);

            List<OrdenTrabajo> otsActivas = otDAO.listarActivas();
            req.setAttribute("otsActivas", otsActivas);

            List<Usuario> maquinistas = usuarioDAO.listarPorRol(6);
            req.setAttribute("maquinistas", maquinistas);

            req.getRequestDispatcher("/vista/defectos.jsp").forward(req, resp);

        } catch (SQLException e) {
            req.setAttribute("errorBD", "Error al cargar defectos: " + e.getMessage());
            req.getRequestDispatcher("/vista/defectos.jsp").forward(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        if (!tienePermiso(req, "CAL_DEFECTOS_REG")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");
        try {
            if ("completar".equals(accion)) {
                int idDefecto = Integer.parseInt(req.getParameter("idDefecto"));
                String tipoFalla = req.getParameter("tipoFalla");
                String observaciones = req.getParameter("observaciones");
                
                // ✅ FIX: Era defectoDAO, no "dao"
                defectoDAO.completarDefecto(idDefecto, tipoFalla, observaciones); 
                resp.sendRedirect(req.getContextPath() + "/defectos?exito=Defecto+registrado");
                return;
            } if ("revertir".equals(accion)) {
                revertirDefecto(req, resp);
                return;
            }else if ("corregir".equals(accion)) {
                int idDefecto = Integer.parseInt(req.getParameter("idDefecto"));
                defectoDAO.corregirDefecto(idDefecto);
                resp.sendRedirect(req.getContextPath() + "/defectos?exito=Defecto+corregido+y+contador+ajustado");
                return;
            } // Modificar el caso "reponer" para que reciba tipoFalla y observaciones (desde el modal)
            if ("reponer".equals(accion)) {
                reponerDefecto(req, resp);
                return;
            }
            if ("registrar".equals(accion)) {
                registrarDefecto(req, resp);
            } else {
                resp.sendRedirect(req.getContextPath() + "/defectos");
            }
        } catch(SQLException e) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=" + java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }

    // ── Registrar defecto + incrementar contador ──────────────
    /**
     * CUS 6.1 RegistrarDefecto → CUS 6.2 IdentificarMaquinistaResponsable
     * → CUS 6.3 IncrementarContadorReprocesos (atómico en el DAO).
     */
    private void registrarDefecto(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String idOtStr  = req.getParameter("idOt");
        String idMaqStr = req.getParameter("idMaquinista");
        String tipoFalla = req.getParameter("tipoFalla");
        String obs       = req.getParameter("observaciones");
        String idPiezaStr = req.getParameter("idPieza");

        // Validaciones
        if (idOtStr == null || idOtStr.isBlank() ||
            idMaqStr == null || idMaqStr.isBlank() ||
            tipoFalla == null || tipoFalla.isBlank()) {
            resp.sendRedirect(req.getContextPath() +
                "/defectos?error=OT,+maquinista+y+tipo+de+falla+son+obligatorios");
            return;
        }

        try {
            DefectoReproceso d = new DefectoReproceso();
            d.setIdOt(Integer.parseInt(idOtStr));
            d.setIdMaquinista(Integer.parseInt(idMaqStr));
            // Pieza es opcional
            if (idPiezaStr != null && !idPiezaStr.isBlank()) {
                d.setIdPieza(Integer.parseInt(idPiezaStr));
            }
            // Mapear el tipo de falla (desde el nombre del enum)
            try {
                d.setTipoFalla(DefectoReproceso.TipoFalla.valueOf(tipoFalla));
            } catch (IllegalArgumentException e) {
                d.setTipoFalla(DefectoReproceso.TipoFalla.OTRO);
            }
            d.setObservaciones(obs != null ? obs.trim() : "");

            boolean ok = defectoDAO.insertarYActualizarContador(d);

            if (ok) {
                resp.sendRedirect(req.getContextPath() +
                    "/defectos?exito=Defecto+registrado+y+contador+actualizado");
            } else {
                resp.sendRedirect(req.getContextPath() +
                    "/defectos?error=No+se+pudo+registrar+el+defecto");
            }

        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=ID+inválido");
        } catch (SQLException e) {
            resp.sendRedirect(req.getContextPath() +
                "/defectos?error=" +
                java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
        }
    }
/**
 * Acción: Botón "Reponer" en el módulo de Defectos.
 *
 * Flujo:
 *  1. Obtiene el defecto pendiente (con cantidad_faltante > 0)
 *  2. Crea una tarea de REPOSICION en asignaciones_carga (estado=PENDIENTE, maquinista=null)
 *  3. Marca el defecto como genera_reposicion = 1
 *
 * El supervisor verá la nueva tarea en Cargas de Trabajo y podrá asignarla.
 */
/**
 * Acción "Revertir": corrige la tarea original para que tenga todas las piezas completadas
 * y marca el defecto como CORREGIDO. Esto desbloquea el flujo hacia ensamblaje.
 */
private void revertirDefecto(HttpServletRequest req, HttpServletResponse resp) throws IOException {
    String idDefectoStr = req.getParameter("idDefecto");
    if (idDefectoStr == null || idDefectoStr.isBlank()) {
        resp.sendRedirect(req.getContextPath() + "/defectos?error=Parámetros+inválidos");
        return;
    }

    try {
        int idDefecto = Integer.parseInt(idDefectoStr);
        DefectoReproceso defecto = defectoDAO.obtenerPorId(idDefecto);
        if (defecto == null || defecto.getEstado() != DefectoReproceso.Estado.PENDIENTE) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=Defecto+no+válido+o+ya+procesado");
            return;
        }

        AsignacionCargaDAO cargaDAO = new AsignacionCargaDAO();
        AsignacionCarga asignacion = cargaDAO.obtenerPorId(defecto.getIdAsignacion());
        if (asignacion == null) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=Tarea+asociada+no+encontrada");
            return;
        }

        // Corregir la asignación original: poner piezas_completadas = cantidad_piezas y estado COMPLETADA
        String sql = "UPDATE asignaciones_carga SET piezas_completadas = cantidad_piezas, estado_fase = 'COMPLETADA' WHERE id_asignacion = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, defecto.getIdAsignacion());
            ps.executeUpdate();
        }

        // Marcar el defecto como corregido (sin tocar otras asignaciones)
        defectoDAO.marcarCorregido(idDefecto);

        // Verificar si la OT puede avanzar (ensamblaje)
        String resultado = cargaDAO.verificarYFinalizarOT(asignacion.getIdOt());

        resp.sendRedirect(req.getContextPath() + "/defectos?exito=Defecto+revertido+y+cantidad+corregida. " +
            (resultado.equals("ENSAMBLAJE_CREADO") ? "Se+creó+la+tarea+de+ensamblaje." : ""));
    } catch (Exception e) {
        resp.sendRedirect(req.getContextPath() + "/defectos?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
    }
}
/**
 * Acción "Reponer": crea una tarea de reposición para las piezas faltantes,
 * registra tipo de falla y observaciones, y marca el defecto como REGISTRADO.
 */
private void reponerDefecto(HttpServletRequest req, HttpServletResponse resp) throws IOException {
    String idDefectoStr = req.getParameter("idDefecto");
    String tipoFalla = req.getParameter("tipoFalla");
    String observaciones = req.getParameter("observaciones");

    if (idDefectoStr == null || idDefectoStr.isBlank()) {
        resp.sendRedirect(req.getContextPath() + "/defectos?error=Parámetros+incompletos");
        return;
    }

    try {
        int idDefecto = Integer.parseInt(idDefectoStr);
        DefectoReproceso defecto = defectoDAO.obtenerPorId(idDefecto);
        if (defecto == null) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=Defecto+no+encontrado");
            return;
        }
        if (defecto.getCantidadFaltante() <= 0) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=No+hay+piezas+faltantes");
            return;
        }

        AsignacionCargaDAO cargaDAO = new AsignacionCargaDAO();

        // 1. Verificar si ya existe reposición activa
        if (cargaDAO.existeReposicionActiva(defecto.getIdAsignacion())) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=Ya+existe+una+reposición+activa");
            return;
        }

        // 2. Actualizar defecto con tipo de falla y observaciones, cambiar a estado REGISTRADO
        if (tipoFalla != null && !tipoFalla.isBlank()) {
            defectoDAO.completarDefecto(idDefecto, tipoFalla, observaciones);
        } else {
            defectoDAO.actualizarObservacionYEstado(idDefecto, observaciones);
        }

        // 3. Crear tarea de reposición (usa la versión sin Connection, autocommit)
        int idNuevaTarea = cargaDAO.crearTareaReposicion(defecto.getIdAsignacion(), defecto.getCantidadFaltante());
        if (idNuevaTarea == -1) {
            resp.sendRedirect(req.getContextPath() + "/defectos?error=La+reposición+no+pudo+crearse+o+ya+existe");
            return;
        }

        // 4. Marcar defecto como con reposición generada
        defectoDAO.marcarConReposicion(idDefecto);

        resp.sendRedirect(req.getContextPath() + "/defectos?exito=Reposición+creada+correctamente");

    } catch (NumberFormatException e) {
        resp.sendRedirect(req.getContextPath() + "/defectos?error=ID+inválido");
    } catch (SQLException e) {
        resp.sendRedirect(req.getContextPath() + "/defectos?error=" + java.net.URLEncoder.encode("Error BD: " + e.getMessage(), "UTF-8"));
    }
}
    // ── Helper ────────────────────────────────────────────────
    // ── Helper ────────────────────────────────────────────────
    private boolean tienePermiso(HttpServletRequest req, String codigo) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        
        Usuario usuario = (Usuario) session.getAttribute("usuarioSesion");
        // ✅ FIX 2: Si es maquinista (rol 6), siempre le damos permiso de pasar
        if (usuario != null && usuario.getIdRol() == 6) {
            return true;
        }
        
        @SuppressWarnings("unchecked")
        Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigo);
    }
}
