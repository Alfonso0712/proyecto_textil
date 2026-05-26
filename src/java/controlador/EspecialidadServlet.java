package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import modelo.Especialidad;
import modelo.EspecialidadDAO;

@WebServlet("/especialidades")
public class EspecialidadServlet extends HttpServlet {

    private final EspecialidadDAO especialidadDAO = new EspecialidadDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        @SuppressWarnings("unchecked")
        java.util.Set<String> permisos = (java.util.Set<String>) session.getAttribute("permisosUsuario");
        if (permisos == null || !permisos.contains("PROD_MAQUINISTAS_GESTION")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String nombre = req.getParameter("nombre");
        String descripcion = req.getParameter("descripcion");

        if (nombre == null || nombre.trim().isEmpty()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"error\":\"El nombre es obligatorio\"}");
            return;
        }

        Especialidad nueva = new Especialidad();
        nueva.setNombre(nombre.trim());
        nueva.setDescripcion(descripcion != null ? descripcion.trim() : "");

        Especialidad creada = especialidadDAO.insertar(nueva);
        if (creada != null) {
            resp.setContentType("application/json;charset=UTF-8");
            // Construcción manual del JSON sin Gson
            String json = String.format("{\"id\":%d,\"nombre\":\"%s\"}",
                    creada.getIdEspecialidad(),
                    creada.getNombre().replace("\"", "\\\""));
            resp.getWriter().write(json);
        } else {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "No se pudo crear la especialidad");
        }
    }
}