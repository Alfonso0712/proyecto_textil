package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.*;
import java.nio.file.Files;

@WebServlet("/imagen/*")
public class ImagenServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        // Obtener la ruta relativa (ej: "uploads/telas/123/foto.png")
        String rutaRelativa = pathInfo.substring(1);
        
        // Construir la ruta física absoluta dentro de la aplicación
        String rutaCompleta = getServletContext().getRealPath("/") + rutaRelativa;
        File archivo = new File(rutaCompleta);
        
        if (!archivo.exists()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        
        // Determinar el tipo MIME
        String mime = getServletContext().getMimeType(archivo.getName());
        if (mime == null) {
            mime = "application/octet-stream";
        }
        
        resp.setContentType(mime);
        resp.setContentLengthLong(archivo.length());
        
        // Enviar el archivo al cliente
        try (InputStream is = Files.newInputStream(archivo.toPath());
             OutputStream os = resp.getOutputStream()) {
            is.transferTo(os);
        }
    }
}