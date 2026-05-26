package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.Notificacion;
import modelo.NotificacionDAO;
import modelo.Usuario;

import java.io.IOException;
import java.util.List;

@WebServlet("/notificaciones")
public class NotificacionesServlet extends HttpServlet {
    private NotificacionDAO dao = new NotificacionDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Usuario usuario = (Usuario) req.getSession().getAttribute("usuarioSesion");
        if (usuario == null) { resp.sendError(401); return; }
        
        // ✅ FIX 1: Forzar UTF-8 para que los Emojis y tildes no rompan el JSON
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8"); 
        
        String accion = req.getParameter("accion");
        if ("listarNoLeidas".equals(accion)) {
            List<Notificacion> lista = dao.listarNoLeidasPorRol(usuario.getNombreRol());
            resp.getWriter().print(toJson(lista));
        } else if ("marcarLeida".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id"));
            dao.marcarComoLeida(id);
            resp.setStatus(200);
        } else {
            int limite = req.getParameter("limite") != null ? Integer.parseInt(req.getParameter("limite")) : 20;
            List<Notificacion> lista = dao.listarTodasPorRol(usuario.getNombreRol(), limite);
            resp.getWriter().print(toJson(lista));
        }
    }

    private String toJson(List<Notificacion> lista) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            Notificacion n = lista.get(i);
            if (i > 0) sb.append(",");
            sb.append("{")
              .append("\"id\":").append(n.getIdNotificacion())
              .append(",\"titulo\":\"").append(escape(n.getTitulo())).append("\"")
              .append(",\"mensaje\":\"").append(escape(n.getMensaje())).append("\"")
              // ✅ FIX 2: Sin comillas alrededor del número, para que JS lo lea bien
              .append(",\"fecha\":").append(n.getFechaCreacion() != null ? n.getFechaCreacion().getTime() : 0)
              .append(",\"leida\":").append(n.isLeida())
              .append("}");
        }
        sb.append("]");
        return sb.toString();
    }
    
    // ✅ FIX 3: Un escape mucho más seguro para evitar que comillas simples o enters rompan la vista
    private String escape(String s) { 
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t"); 
    }
}