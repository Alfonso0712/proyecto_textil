package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.Especialidad;
import modelo.EspecialidadDAO;

import java.io.IOException;
import java.util.List;

@WebServlet("/gestion-especialidades")
public class GestionEspecialidadesServlet extends HttpServlet {

    private final EspecialidadDAO dao = new EspecialidadDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!tienePermiso(req, "ESPECIALIDADES_VER")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        // Cargar lista y datos para modal (si se pide edición)
        String accion = req.getParameter("accion");
        if ("editar".equals(accion)) {
            String idStr = req.getParameter("id");
            if (idStr != null && !idStr.isEmpty()) {
                Especialidad e = dao.buscarPorId(Integer.parseInt(idStr));
                req.setAttribute("especialidadEditar", e);
            }
        }

        req.setAttribute("especialidades", dao.listarTodos());
        req.getRequestDispatcher("/vista/gestion_especialidades.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!tienePermiso(req, "ESPECIALIDADES_GESTION")) {
            resp.sendRedirect(req.getContextPath() + "/dashboard?error=sinPermiso");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_especialidad"));
            boolean ok = dao.eliminar(id);
            resp.sendRedirect(req.getContextPath() + "/gestion-especialidades?exito="
                    + (ok ? "Especialidad+eliminada" : "Error+al+eliminar"));
            return;
        }

        // Guardar o actualizar
        Especialidad esp = new Especialidad();
        String idStr = req.getParameter("id_especialidad");
        if (idStr != null && !idStr.isEmpty()) {
            esp.setIdEspecialidad(Integer.parseInt(idStr));
        }
        esp.setNombre(req.getParameter("nombre"));
        esp.setDescripcion(req.getParameter("descripcion"));

        boolean ok;
        if (esp.getIdEspecialidad() > 0) {
            ok = dao.actualizar(esp);
        } else {
            Especialidad creada = dao.insertar(esp);
            ok = (creada != null);
        }

        resp.sendRedirect(req.getContextPath() + "/gestion-especialidades?exito="
                + (ok ? "Especialidad+guardada" : "Error+al+guardar"));
    }

    private boolean tienePermiso(HttpServletRequest req, String codigoPermiso) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        @SuppressWarnings("unchecked")
        java.util.Set<String> permisos = (java.util.Set<String>) session.getAttribute("permisosUsuario");
        return permisos != null && permisos.contains(codigoPermiso);
    }
}