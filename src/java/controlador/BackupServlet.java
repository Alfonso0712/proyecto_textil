package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.*;

@WebServlet("/backup")
public class BackupServlet extends HttpServlet {

    private static final String BACKUP_DIR = "backups";
    // Gestión de tareas asíncronas
    private static final ExecutorService executor = Executors.newSingleThreadExecutor();
    private static final Map<String, BackupJob> jobs = new ConcurrentHashMap<>();

    private static class BackupJob {
        String estado; // "IN_PROGRESS", "COMPLETED", "FAILED"
        String mensaje;
        String nombreArchivo;
        long tamanioBytes;
        int idHistorial;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");

        if ("listar".equals(accion)) {
            try {
                List<HistorialBackup> lista = new HistorialBackupDAO().listarTodos();
                req.setAttribute("historial", lista);
                req.getRequestDispatcher("/vista/tabla_backups.jsp").forward(req, resp);
                return;
            } catch (SQLException e) {
                resp.sendError(500, e.getMessage());
                return;
            }
        }

        if ("estado".equals(accion)) {
            // Consultar estado de una tarea asíncrona
            String jobId = req.getParameter("jobId");
            resp.setContentType("application/json");
            BackupJob job = jobs.get(jobId);
            if (job == null) {
                resp.getWriter().write("{\"estado\":\"NOT_FOUND\"}");
            } else {
                String json = String.format(
                    "{\"estado\":\"%s\",\"mensaje\":\"%s\",\"archivo\":\"%s\",\"tamanio\":%d,\"idHistorial\":%d}",
                    job.estado,
                    job.mensaje != null ? job.mensaje.replace("\"", "\\\"") : "",
                    job.nombreArchivo != null ? job.nombreArchivo : "",
                    job.tamanioBytes,
                    job.idHistorial
                );
                resp.getWriter().write(json);
                // Limpiar tarea completada/fail después de un tiempo? Se mantendrá para esta sesión.
            }
            return;
        }

        if ("descargar".equals(accion)) {
            // Descargar archivo de backup
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("usuarioSesion") == null) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            String fileName = req.getParameter("file");
            if (fileName == null || fileName.trim().isEmpty() || fileName.contains("..")) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            String webRoot = getServletContext().getRealPath("/");
            Path filePath = Paths.get(webRoot, BACKUP_DIR, fileName);
            if (!Files.exists(filePath) || !Files.isRegularFile(filePath)) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            resp.setContentType("application/octet-stream");
            resp.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            Files.copy(filePath, resp.getOutputStream());
            return;
        }

        // Mostrar página principal
        req.getRequestDispatcher("/vista/backup.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String accion = req.getParameter("accion");
        if ("crear".equals(accion)) {
            HttpSession session = req.getSession(false);
            Usuario usuario = (Usuario) session.getAttribute("usuarioSesion");
            if (usuario == null) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }

            // Generar ID único para el job
            String jobId = UUID.randomUUID().toString();
            BackupJob job = new BackupJob();
            job.estado = "IN_PROGRESS";
            job.mensaje = "Generando backup...";
            jobs.put(jobId, job);

            // Lanzar tarea asíncrona
            executor.submit(() -> {
                try {
                    realizarBackup(jobId, usuario.getIdUsuario());
                } catch (Exception e) {
                    job.estado = "FAILED";
                    job.mensaje = "Error: " + e.getMessage();
                }
            });

            // Redirigir a la página pasando el jobId (se mostrará en la URL)
            resp.sendRedirect(req.getContextPath() + "/backup?jobId=" + jobId);
        }else if ("eliminar".equals(accion)) {
            eliminarBackup(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/backup");
        }
    }

    private void realizarBackup(String jobId, int idUsuario) {
        BackupJob job = jobs.get(jobId);
        String webRoot = getServletContext().getRealPath("/");
        Path backupPath = Paths.get(webRoot, BACKUP_DIR);
        try {
            Files.createDirectories(backupPath);
        } catch (IOException e) {
            job.estado = "FAILED";
            job.mensaje = "No se pudo crear carpeta: " + e.getMessage();
            return;
        }

        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        String fileName = "backup_textil_" + timestamp + ".sql";
        Path filePath = backupPath.resolve(fileName);
        List<String> excludeTables = List.of("sesiones_activas", "intentos_login");

        try (Connection cn = ConexionDB.obtenerConexion();
             PrintWriter writer = new PrintWriter(Files.newBufferedWriter(filePath, StandardOpenOption.CREATE))) {

            // Obtener todas las tablas
            List<String> tables = new ArrayList<>();
            try (ResultSet rs = cn.getMetaData().getTables(null, null, "%", new String[]{"TABLE"})) {
                while (rs.next()) {
                    String tableName = rs.getString("TABLE_NAME");
                    if (!excludeTables.contains(tableName)) {
                        tables.add(tableName);
                    }
                }
            }

            for (String table : tables) {
                writer.println("-- ----------------------------------------");
                writer.println("-- Table: " + table);
                writer.println("DROP TABLE IF EXISTS `" + table + "`;");

                try (Statement st = cn.createStatement();
                     ResultSet rsCreate = st.executeQuery("SHOW CREATE TABLE " + table)) {
                    if (rsCreate.next()) {
                        writer.println(rsCreate.getString(2) + ";");
                    }
                }

                try (Statement st = cn.createStatement();
                     ResultSet rsData = st.executeQuery("SELECT * FROM " + table)) {
                    int columnCount = rsData.getMetaData().getColumnCount();
                    boolean hasRows = false;
                    while (rsData.next()) {
                        if (!hasRows) {
                            writer.println("INSERT INTO `" + table + "` VALUES ");
                            hasRows = true;
                        } else {
                            writer.println(",");
                        }
                        writer.print("(");
                        for (int i = 1; i <= columnCount; i++) {
                            if (i > 1) writer.print(",");
                            Object val = rsData.getObject(i);
                            if (val == null) {
                                writer.print("NULL");
                            } else if (val instanceof Number) {
                                writer.print(val);
                            } else if (val instanceof Timestamp) {
                                writer.print("'" + val + "'");
                            } else {
                                String strVal = val.toString().replace("'", "''");
                                writer.print("'" + strVal + "'");
                            }
                        }
                        writer.print(")");
                    }
                    if (hasRows) {
                        writer.println(";");
                    }
                }
                writer.println();
            }

            writer.flush();
            long fileSize = Files.size(filePath);

            // Registrar en historial
            HistorialBackupDAO dao = new HistorialBackupDAO();
            int idHistorial = dao.insertar(idUsuario, fileName, fileSize, "EXITOSO", "Backup generado desde el sistema");

            // Actualizar estado del job
            job.estado = "COMPLETED";
            job.mensaje = "Backup completado exitosamente";
            job.nombreArchivo = fileName;
            job.tamanioBytes = fileSize;
            job.idHistorial = idHistorial;

        } catch (SQLException | IOException e) {
            job.estado = "FAILED";
            job.mensaje = "Error: " + e.getMessage();
        }
    }
    private void eliminarBackup(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        PrintWriter out = resp.getWriter();
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("usuarioSesion") == null) {
            out.write("{\"success\":false,\"error\":\"No autenticado\"}");
            return;
        }
        String idStr = req.getParameter("id");
        String fileName = req.getParameter("file");
        if (idStr == null || fileName == null) {
            out.write("{\"success\":false,\"error\":\"Faltan parámetros\"}");
            return;
        }
        int idBackup;
        try {
            idBackup = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            out.write("{\"success\":false,\"error\":\"ID inválido\"}");
            return;
        }
        // Eliminar archivo físico
        String webRoot = getServletContext().getRealPath("/");
        Path filePath = Paths.get(webRoot, BACKUP_DIR, fileName);
        boolean fileDeleted = false;
        try {
            if (Files.exists(filePath)) {
                Files.delete(filePath);
                fileDeleted = true;
            } else {
                fileDeleted = true; // Si no existe, consideramos que ya está eliminado
            }
        } catch (IOException e) {
            out.write("{\"success\":false,\"error\":\"No se pudo eliminar el archivo: " + e.getMessage() + "\"}");
            return;
        }
        // Eliminar registro de BD
        try {
            HistorialBackupDAO dao = new HistorialBackupDAO();
            boolean dbDeleted = dao.eliminar(idBackup);

            if (dbDeleted) {
                out.write("{\"success\":true}");
            } else {
                out.write("{\"success\":false,\"error\":\"No se pudo eliminar el registro de la base de datos\"}");
            }
        } catch (SQLException e) {
            // Capturamos el error de BD y lo enviamos como respuesta JSON
            out.write("{\"success\":false,\"error\":\"Error de base de datos: " + e.getMessage() + "\"}");
        }
    }
}