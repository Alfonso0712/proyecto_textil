package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.ModeloPrenda;
import modelo.ModeloPrendaDAO;
import modelo.PiezaModelo;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import modelo.FaseProduccion;
import static org.apache.tomcat.jakartaee.commons.lang3.StringEscapeUtils.escapeJson;

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
            PrintWriter out = resp.getWriter();
            if (m == null) { out.print("[]"); return; }

            // Cargar todas las fases para mapear id → nombre
            List<FaseProduccion> todasFases = dao.listarFases();
            Map<Integer, String> mapaFases = new HashMap<>();
            for (FaseProduccion f : todasFases) {
                mapaFases.put(f.getIdFase(), f.getNombre());
            }

            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < m.getPiezas().size(); i++) {
                PiezaModelo p = m.getPiezas().get(i);
                if (i > 0) json.append(",");
                json.append("{\"nombre\":\"")
                    .append(p.getNombrePieza().replace("\"", "\\\""))
                    .append("\",\"cantidad\":").append(p.getCantidad())
                    .append(",\"fases\":[");
                List<Integer> fasesIds = p.getIdFasesAsignadas();
                for (int j = 0; j < fasesIds.size(); j++) {
                    if (j > 0) json.append(",");
                    int idFase = fasesIds.get(j);
                    String nombreFase = mapaFases.getOrDefault(idFase, "Desconocida");
                    json.append("{\"id\":").append(idFase)
                        .append(",\"nombre\":\"").append(escapeJsonManual(nombreFase)).append("\"}");
                }
                json.append("]}");
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
        List<FaseProduccion> fases = dao.listarFases();
        req.setAttribute("fases", fases);
        req.getRequestDispatcher("/vista/catalogo_modelos.jsp").forward(req, resp);
    }


    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_modelo"));
            
            // --- NUEVA REGLA: Bloqueo si está en uso ---
            if (dao.estaEnUso(id)) {
                resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?error=No+se+puede+eliminar:+El+modelo+ya+está+siendo+usado+en+Producción.");
                return;
            }
            // -------------------------------------------
            
            dao.eliminar(id);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Eliminado+correctamente");
            return;
        }
        if ("agregarFase".equals(accion)) {
            try {
                String nombre = req.getParameter("nombre");
                int orden = Integer.parseInt(req.getParameter("orden"));
                String descripcion = req.getParameter("descripcion");

                // Validar
                if (nombre == null || nombre.trim().isEmpty()) {
                    throw new IllegalArgumentException("El nombre es obligatorio");
                }

                dao.insertarFase(nombre, orden, descripcion);
                List<FaseProduccion> fases = dao.listarFases();

                // Construir JSON manualmente
                StringBuilder json = new StringBuilder("[");
                for (int i = 0; i < fases.size(); i++) {
                    if (i > 0) json.append(",");
                    FaseProduccion f = fases.get(i);
                    json.append("{")
                        .append("\"id\":").append(f.getIdFase())
                        .append(",\"nombre\":\"").append(escapeJson(f.getNombre()))
                        .append("\",\"orden\":").append(f.getOrden())
                        .append(",\"descripcion\":\"").append(escapeJson(f.getDescripcion()))
                        .append("\"}");
                }
                json.append("]");

                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().print(json.toString());
                return;
            } catch (Exception e) {
                e.printStackTrace(); // Ver en consola del servidor
                resp.setContentType("application/json;charset=UTF-8");
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.getWriter().print("{\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
                return;
            }
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
            
            String[] fasesMarcadas = req.getParameterValues("fasesPieza_" + i);
            if (fasesMarcadas != null) {
                List<Integer> listaFases = new ArrayList<>();
                for (String idFaseStr : fasesMarcadas) {
                    // Simplemente añadimos las fases normales a la pieza
                    listaFases.add(Integer.parseInt(idFaseStr));
                }
                p.setIdFasesAsignadas(listaFases);
            }
            modelo.getPiezas().add(p);
        }
    }
}

        if ("actualizar".equals(accion)) {
            // --- NUEVA REGLA: Bloqueo si está en uso ---
            if (dao.estaEnUso(modelo.getIdModelo())) {
                resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?error=No+se+puede+editar:+El+modelo+ya+tiene+órdenes+de+trabajo+asignadas.");
                return;
            }
            // -------------------------------------------
            
            dao.actualizarTransaccional(modelo);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Modelo+actualizado");
        } else {
            // Lógica de insertar (esta se queda igual, porque un modelo nuevo nunca está en uso)
            dao.insertarTransaccional(modelo);
            resp.sendRedirect(req.getContextPath() + "/catalogo-modelos?exito=Modelo+y+piezas+guardados");
        }
    }
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }
    private String escapeJsonManual(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }
}