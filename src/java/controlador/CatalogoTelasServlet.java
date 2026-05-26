package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.CatalogoTela;
import modelo.CatalogoTelaDAO;
import java.io.IOException;

@WebServlet("/catalogo-telas")
public class CatalogoTelasServlet extends HttpServlet {

    private final CatalogoTelaDAO dao = new CatalogoTelaDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

        // ✅ FIX: manejar accion=editar para cargar la tela a editar
        if ("editar".equals(accion)) {
            String idStr = req.getParameter("id");
            if (idStr != null && !idStr.isEmpty()) {
                CatalogoTela telaEditar = dao.buscarPorId(Integer.parseInt(idStr));
                req.setAttribute("telaEditar", telaEditar);
            }
        }

        req.setAttribute("telas", dao.listarTodos());
        req.getRequestDispatcher("/vista/catalogo_telas.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_catalogo"));
            if (dao.tieneUsoEnInventario(id)) {
                resp.sendRedirect(req.getContextPath() + "/catalogo-telas?error=Tela+en+uso,+no+se+puede+eliminar");
            } else {
                if (dao.eliminar(id)) {
                    resp.sendRedirect(req.getContextPath() + "/catalogo-telas?exito=Material+eliminado+correctamente");
                } else {
                    resp.sendRedirect(req.getContextPath() + "/catalogo-telas?error=Error+al+intentar+eliminar");
                }
            }
            return;
        }

        // Accion guardar o actualizar
        CatalogoTela tela = new CatalogoTela();
        String idStr = req.getParameter("id_catalogo");
        if (idStr != null && !idStr.isEmpty()) {
            tela.setIdCatalogo(Integer.parseInt(idStr));
        }
        tela.setNombre(req.getParameter("nombre"));
        tela.setComposicion(req.getParameter("composicion"));
        tela.setProveedorBase(req.getParameter("proveedor"));
        tela.setRequiereReposo("on".equals(req.getParameter("reposo")));
        String tiempoStr = req.getParameter("tiempo_reposo");
        tela.setTiempoReposo((tiempoStr != null && !tiempoStr.isEmpty()) ? Integer.parseInt(tiempoStr) : 0);

        if ("actualizar".equals(accion)) {
            // 1. Actualizar el catálogo
            dao.actualizar(tela);

            // 2. Sincronizar el flag en todas las telas que usan este material
            dao.actualizarReposoEnTelas(tela.getIdCatalogo(), tela.isRequiereReposo());
            resp.sendRedirect(req.getContextPath() + "/catalogo-telas?exito=Material+actualizado+y+telas+sincronizadas");
        } else {
            dao.insertar(tela);
            resp.sendRedirect(req.getContextPath() + "/catalogo-telas?exito=Material+guardado");
        }
    }
}