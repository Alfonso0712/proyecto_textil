package controlador;

import modelo.ReporteDAO;
import modelo.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

@WebServlet(name = "ReportesServlet", urlPatterns = {"/reportes"})
public class ReportesServlet extends HttpServlet {

    private ReporteDAO reporteDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        reporteDAO = new ReporteDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("usuarioSesion") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
        int idUsuario = usuarioSesion.getIdUsuario();
        String rol = usuarioSesion.getNombreRol();

        try {
            // Obtener los datos usando el DAO filtrado por rol
            List<Map<String, Object>> mermaPorOT = reporteDAO.obtenerMermaPorOT(idUsuario, rol);
            List<Map<String, Object>> tiemposMaquinistas = reporteDAO.obtenerTiemposMaquinistasPorOT(idUsuario, rol);
            List<Map<String, Object>> fallasPorTela = reporteDAO.obtenerFallasPorTela(idUsuario, rol);
            
            // Nuevos reportes para el rol máximo
            List<Map<String, Object>> eficienciaGlobal = reporteDAO.obtenerEficienciaGlobal();
            List<Map<String, Object>> inventarioTelas = reporteDAO.obtenerInventarioTelas();
            
            // Nuevos reportes estratégicos cruzados
            List<Map<String, Object>> calidadVsProductividad = null;
            List<Map<String, Object>> otsProblematicas = null;
            List<Map<String, Object>> desviacionDespacho = null;
            
            String r = rol.toUpperCase();
            if (r.contains("ADMIN") || r.contains("GERENTE") || r.contains("SUPERVISOR") || r.contains("JEFE")) {
                calidadVsProductividad = reporteDAO.obtenerCalidadVsProductividad();
                otsProblematicas = reporteDAO.obtenerOTsProblematicas();
                desviacionDespacho = reporteDAO.obtenerDespacho();
            }
            
            List<Map<String, Object>> rendimientoMaquinista = null;
            if (r.contains("MAQUINISTA")) {
                rendimientoMaquinista = reporteDAO.obtenerRendimientoMaquinista(idUsuario);
            }

            // Pasar los datos a la vista
            request.setAttribute("mermaPorOT", mermaPorOT);
            request.setAttribute("tiemposMaquinistas", tiemposMaquinistas);
            request.setAttribute("fallasPorTela", fallasPorTela);
            request.setAttribute("eficienciaGlobal", eficienciaGlobal);
            request.setAttribute("inventarioTelas", inventarioTelas);
            
            request.setAttribute("calidadVsProductividad", calidadVsProductividad);
            request.setAttribute("otsProblematicas", otsProblematicas);
            request.setAttribute("desviacionDespacho", desviacionDespacho);
            request.setAttribute("rendimientoMaquinista", rendimientoMaquinista);
            
            request.setAttribute("rolUsuario", rol);

            request.getRequestDispatcher("/vista/reportes.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("error", "Error al generar los reportes: " + e.getMessage());
            request.getRequestDispatcher("/vista/reportes.jsp").forward(request, response);
        }
    }
}
