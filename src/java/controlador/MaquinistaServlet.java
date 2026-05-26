package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet("/maquinistas")
public class MaquinistaServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final EspecialidadDAO especialidadDAO = new EspecialidadDAO();
    private final UsuarioEspecialidadDAO ueDAO = new UsuarioEspecialidadDAO();

    // Rol MAQUINISTA (suponemos id = 6 según tu base de datos)
    private static final int ID_ROL_MAQUINISTA = 6;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Verificar que el usuario en sesión tenga permiso (SUPERVISOR o ADMIN)
        if (!tienePermiso(req, "PROD_MAQUINISTAS_VER")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        String accion = req.getParameter("accion");
        if ("nuevo".equals(accion) || "editar".equals(accion)) {
            mostrarFormulario(req, resp, accion);
        } else {
            listarMaquinistas(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!tienePermiso(req, "PROD_MAQUINISTAS_GESTION")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        if ("guardar".equals(accion)) {
            crearMaquinista(req, resp);
        } else if ("actualizar".equals(accion)) {
            actualizarMaquinista(req, resp);
        } else if ("desactivar".equals(accion)) {
            cambiarEstado(req, resp, false);
        } else if ("activar".equals(accion)) {
            cambiarEstado(req, resp, true);
        } else if ("eliminar".equals(accion)) {
            eliminarMaquinista(req, resp);
        }else {
            listarMaquinistas(req, resp);
        }
    }

    private void listarMaquinistas(HttpServletRequest req, HttpServletResponse resp)
        throws ServletException, IOException {
    List<Usuario> usuariosMaquinista = usuarioDAO.listarPorRol(ID_ROL_MAQUINISTA);
    List<MaquinistaDTO> maquinistas = new ArrayList<>();
    for (Usuario u : usuariosMaquinista) {
        List<Especialidad> especialidades = ueDAO.obtenerEspecialidadesPorUsuario(u.getIdUsuario());
        maquinistas.add(new MaquinistaDTO(u, especialidades));
    }
    req.setAttribute("maquinistas", maquinistas);
    // Lista completa de especialidades para el modal
    req.setAttribute("especialidadesDisponibles", especialidadDAO.listarTodos());
    req.getRequestDispatcher("/vista/maquinistas.jsp").forward(req, resp);
}

    private void mostrarFormulario(HttpServletRequest req, HttpServletResponse resp,
                                    String accion) throws ServletException, IOException {
        // Cargar lista de especialidades para el formulario
        List<Especialidad> todasEspecialidades = especialidadDAO.listarTodos();
        req.setAttribute("especialidades", todasEspecialidades);
        req.setAttribute("accion", accion.equals("nuevo") ? "guardar" : "actualizar");

        if ("editar".equals(accion)) {
            String idStr = req.getParameter("id");
            if (idStr != null) {
                int id = Integer.parseInt(idStr);
                Usuario usuario = usuarioDAO.buscarPorId(id);
                if (usuario == null || usuario.getIdRol() != ID_ROL_MAQUINISTA) {
                    resp.sendRedirect(req.getContextPath() + "/maquinistas?error=Usuario+no+encontrado");
                    return;
                }
                List<Especialidad> actuales = ueDAO.obtenerEspecialidadesPorUsuario(id);
                List<Integer> idsActuales = actuales.stream()
                        .map(Especialidad::getIdEspecialidad)
                        .collect(Collectors.toList());
                req.setAttribute("maquinista", usuario);
                req.setAttribute("especialidadesSeleccionadas", idsActuales);
            }
        }
        req.getRequestDispatcher("/vista/form_maquinista.jsp").forward(req, resp);
    }

    private void crearMaquinista(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Igual validación que en GestionUsuariosServlet pero fijando el rol
        String username  = req.getParameter("username");
        String password  = req.getParameter("password");
        String nombre    = req.getParameter("nombre");
        String apellido  = req.getParameter("apellido");
        String email     = req.getParameter("email");
        String[] especialidadesSelecc = req.getParameterValues("especialidades");

        // Validaciones básicas (replica las de GestionUsuariosServlet)
        if (username == null || username.isBlank() || username.length() < 4) {
            redirigirConError(req, resp, "Username inválido (mínimo 4 caracteres).");
            return;
        }
        if (password == null || password.length() < 6) {
            redirigirConError(req, resp, "Contraseña debe tener al menos 6 caracteres.");
            return;
        }
        if (nombre == null || nombre.isBlank() || apellido == null || apellido.isBlank()) {
            redirigirConError(req, resp, "Nombre y apellido son obligatorios.");
            return;
        }
        if (email == null || !email.matches("^[\\w.+-]+@[\\w-]+\\.[\\w.-]+$")) {
            redirigirConError(req, resp, "Email no válido.");
            return;
        }

        Usuario nuevo = new Usuario();
        nuevo.setUsername(username.trim());
        nuevo.setPassword(password);      // BCrypt en UsuarioDAO
        nuevo.setNombre(nombre.trim());
        nuevo.setApellido(apellido.trim());
        nuevo.setEmail(email.trim());
        nuevo.setIdRol(ID_ROL_MAQUINISTA);
        nuevo.setActivo(true);
        // --- CONFIGURACIÓN DE HORARIO POR DEFECTO ---
        nuevo.setHorarioRestringido(true);                        // NUEVO: Activa la restricción
        nuevo.setHorarioDias("LUN,MAR,MIE,JUE,VIE,SAB");           // NUEVO: Días por defecto
        nuevo.setHorarioInicio("07:00:00");                        // NUEVO: Hora inicio
        nuevo.setHorarioFin("17:00:00");                           // NUEVO: Hora fin
        try {
            boolean ok = usuarioDAO.insertar(nuevo);
            if (ok) {
                // Asignar especialidades
                if (especialidadesSelecc != null && especialidadesSelecc.length > 0) {
                    List<Integer> ids = new ArrayList<>();
                    for (String s : especialidadesSelecc) ids.add(Integer.parseInt(s));
                    ueDAO.guardarEspecialidades(nuevo.getIdUsuario(), ids);
                }
                resp.sendRedirect(req.getContextPath() + "/maquinistas?exito=Maquinista+creado");
            } else {
                redirigirConError(req, resp, "No se pudo crear el usuario.");
            }
        } catch (RuntimeException e) {
            redirigirConError(req, resp, "Error: " + e.getMessage());
        }
    }
    private void eliminarMaquinista(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=ID+inválido");
            return;
        }
        int id = Integer.parseInt(idStr);
        Usuario u = usuarioDAO.buscarPorId(id);
        if (u == null || u.getIdRol() != ID_ROL_MAQUINISTA) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=Usuario+no+encontrado");
            return;
        }

        // Verificar si tiene actividades
        if (usuarioDAO.tieneActividades(id)) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=El+usuario+tiene+actividades+registradas+y+no+puede+ser+eliminado");
            return;
        }

        try {
            boolean ok = usuarioDAO.eliminar(id);
            String msg = ok ? "Maquinista+eliminado" : "Error+al+eliminar";
            resp.sendRedirect(req.getContextPath() + "/maquinistas?" + (ok ? "exito=" : "error=") + msg);
        } catch (RuntimeException e) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=Error:" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
    private void actualizarMaquinista(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String idStr = req.getParameter("idUsuario");
        String nombre = req.getParameter("nombre");
        String apellido = req.getParameter("apellido");
        String email = req.getParameter("email");
        String password = req.getParameter("password"); // opcional
        String[] especialidadesSelecc = req.getParameterValues("especialidades");

        if (idStr == null || idStr.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=ID+inválido");
            return;
        }
        int id = Integer.parseInt(idStr);
        Usuario u = usuarioDAO.buscarPorId(id);
        if (u == null || u.getIdRol() != ID_ROL_MAQUINISTA) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=Usuario+no+encontrado");
            return;
        }

        u.setNombre(nombre.trim());
        u.setApellido(apellido.trim());
        u.setEmail(email.trim());
        // Si se ingresó nueva contraseña
        if (password != null && !password.isBlank()) {
            u.setPassword(password);
        }

        boolean userOk = usuarioDAO.actualizar(u);
        if (userOk) {
            if (especialidadesSelecc != null) {
                List<Integer> ids = new ArrayList<>();
                for (String s : especialidadesSelecc) ids.add(Integer.parseInt(s));
                ueDAO.guardarEspecialidades(id, ids);
            }
            resp.sendRedirect(req.getContextPath() + "/maquinistas?exito=Maquinista+actualizado");
        } else {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=No+se+pudo+actualizar");
        }
    }

    private void cambiarEstado(HttpServletRequest req, HttpServletResponse resp, boolean activar)
            throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=ID+inválido");
            return;
        }
        int id = Integer.parseInt(idStr);
        Usuario u = usuarioDAO.buscarPorId(id);
        if (u == null || u.getIdRol() != ID_ROL_MAQUINISTA) {
            resp.sendRedirect(req.getContextPath() + "/maquinistas?error=Usuario+no+encontrado");
            return;
        }
        u.setActivo(activar);
        u.setPassword(""); // no cambia
        boolean ok = usuarioDAO.actualizar(u);
        String msg = activar ? "Maquinista+activado" : "Maquinista+desactivado";
        resp.sendRedirect(req.getContextPath() + "/maquinistas?" + (ok ? "exito=" : "error=") + msg);
    }

    private boolean tienePermiso(HttpServletRequest req, String codigoPermiso) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        @SuppressWarnings("unchecked")
        java.util.Set<String> permisos = (java.util.Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigoPermiso);
    }

    private void redirigirConError(HttpServletRequest req, HttpServletResponse resp, String mensaje)
            throws IOException {
        resp.sendRedirect(req.getContextPath() + "/maquinistas?error=" + java.net.URLEncoder.encode(mensaje, "UTF-8"));
    }
}