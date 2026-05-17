package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.ModeloPrenda;
import modelo.ModeloPrendaDAO;
import modelo.PiezaModelo;
import java.io.IOException;
import java.util.ArrayList;

@WebServlet("/catalogo-modelos")
public class CatalogoModelosServlet extends HttpServlet {

    private final ModeloPrendaDAO dao = new ModeloPrendaDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

// ── NUEVO: devuelve piezas en JSON para el modal ojo ──────────
        if ("verPiezas".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id"));
            ModeloPrenda m = dao.buscarPorId(id);
            resp.setContentType("application/json;charset=UTF-8");
            java.io.PrintWriter out = resp.getWriter();
            if (m == null) { out.print("[]"); return; }
            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < m.getPiezas().size(); i++) {
                PiezaModelo p = m.getPiezas().get(i);
                if (i > 0) json.append(",");
                json.append("{\"nombre\":\"")
                        .append(p.getNombrePieza().replace("\"","\\\""))
                        .append("\",\"cantidad\":").append(p.getCantidad())
                        .append("}");
            }
            json.append("]");
            out.print(json);
            return;
        }

        if ("editar".equals(accion)) {
            String idStr = req.getParameter("id");
            if (idStr != null) {
                ModeloPrenda m = dao.buscarPorId(Integer.parseInt(idStr));
                req.setAttribute("modeloEditar", m);
            }
        }

        req.setAttribute("modelos", dao.listarTodos());
        req.getRequestDispatcher("/vista/catalogo_modelos.jsp").forward(req, resp);
    }


    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_modelo"));
            dao.eliminar(id);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Eliminado+correctamente");
            return;
        }

        // Accion Guardar o Actualizar Modelo + Piezas
        ModeloPrenda modelo = new ModeloPrenda();
        String idStr = req.getParameter("id_modelo");
        if (idStr != null && !idStr.isEmpty()) {
            modelo.setIdModelo(Integer.parseInt(idStr));
        }

        modelo.setNombre(req.getParameter("nombre"));
        modelo.setTemporada(req.getParameter("temporada"));

        // Recuperar arrays dinámicos enviados por JS
        String[] nombresPiezas = req.getParameterValues("nombrePieza[]");
        String[] cantidadesPiezas = req.getParameterValues("cantidadPieza[]");

        if (nombresPiezas != null && cantidadesPiezas != null) {
            for (int i = 0; i < nombresPiezas.length; i++) {
                if (!nombresPiezas[i].trim().isEmpty()) {
                    PiezaModelo p = new PiezaModelo();
                    p.setNombrePieza(nombresPiezas[i].trim());
                    p.setCantidad(Integer.parseInt(cantidadesPiezas[i]));
                    modelo.getPiezas().add(p);
                }
            }
        }

        if ("actualizar".equals(accion)) {
            dao.actualizarTransaccional(modelo);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Modelo+actualizado");
        } else {
            dao.insertarTransaccional(modelo);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Modelo+y+piezas+guardados");
        }
    }
}