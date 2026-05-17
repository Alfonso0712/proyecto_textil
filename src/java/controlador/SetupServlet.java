package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.ConexionDB;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * SetupServlet — HU09: Utilidad de inicialización de contraseñas
 * ---------------------------------------------------------------
 * URL: /setup
 *
 * PROPÓSITO: Actualiza las contraseñas de todos los usuarios de prueba
 * para que su contraseña sea IGUAL a su username (ej: maquinista1 / maquinista1).
 * Usa BCrypt con cost=12, igual que el resto del sistema.
 *
 * USO: Ejecutar UNA SOLA VEZ después de importar el schema.sql y el
 * HU09_gestion_perfiles.sql.  Visita http://localhost:8080/proyecto_textil/setup
 *
 * SEGURIDAD: Este servlet solo opera en entorno de desarrollo/prueba.
 * Elimínalo o protégelo antes de pasar a producción.
 */
@WebServlet("/setup")
public class SetupServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        out.println("<!DOCTYPE html><html lang='es'><head>");
        out.println("<meta charset='UTF-8'>");
        out.println("<title>Setup – Sistema Textil</title>");
        out.println("<style>");
        out.println("body{font-family:'Segoe UI',sans-serif;background:#f0f2f5;padding:2rem;}");
        out.println(".card{background:#fff;border-radius:12px;padding:2rem;max-width:700px;");
        out.println("      margin:0 auto;box-shadow:0 2px 8px rgba(0,0,0,.08);}");
        out.println("h2{color:#1a1a2e;margin-bottom:1rem;}");
        out.println(".ok{color:#155724;background:#d4edda;padding:.5rem .9rem;");
        out.println("    border-radius:6px;margin:.4rem 0;font-size:.9rem;}");
        out.println(".err{color:#721c24;background:#f8d7da;padding:.5rem .9rem;");
        out.println("     border-radius:6px;margin:.4rem 0;font-size:.9rem;}");
        out.println(".info{color:#004085;background:#cce5ff;padding:.5rem .9rem;");
        out.println("      border-radius:6px;margin:.4rem 0;font-size:.9rem;}");
        out.println("table{width:100%;border-collapse:collapse;margin-top:1rem;font-size:.85rem;}");
        out.println("th{background:#f7f8fa;padding:.6rem 1rem;text-align:left;");
        out.println("   border-bottom:2px solid #eee;color:#555;}");
        out.println("td{padding:.6rem 1rem;border-bottom:1px solid #f0f0f0;}");
        out.println(".btn{display:inline-block;margin-top:1.5rem;padding:.6rem 1.5rem;");
        out.println("     background:#0f3460;color:#fff;border-radius:8px;text-decoration:none;}");
        out.println("</style></head><body><div class='card'>");
        out.println("<h2>⚙️ Setup – Inicialización de Contraseñas</h2>");

        // ── Usuarios a configurar: contraseña = username ──────────────────────
        String[][] usuarios = {
            {"admin",       "admin"},
            {"almacen1",    "almacen1"},
            {"jefe_prod",   "jefe_prod"},
            {"tizador1",    "tizador1"},
            {"supervisor1", "supervisor1"},
            {"maquinista1", "maquinista1"}
        };

        out.println("<div class='info'>ℹ️ Actualizando contraseñas: <strong>contraseña = username</strong></div>");
        out.println("<table><thead><tr><th>Usuario</th><th>Contraseña</th><th>Estado</th></tr></thead><tbody>");

        int ok = 0, errores = 0;

        String sql = "UPDATE usuarios SET password = ? WHERE username = ?";

        try (Connection cn = ConexionDB.obtenerConexion()) {
            for (String[] par : usuarios) {
                String username = par[0];
                String password = par[1]; // contraseña = username

                try (PreparedStatement ps = cn.prepareStatement(sql)) {
                    // Generar hash BCrypt con cost 12 (igual que el resto del sistema)
                    String hash = BCrypt.hashpw(password, BCrypt.gensalt(12));
                    ps.setString(1, hash);
                    ps.setString(2, username);
                    int filas = ps.executeUpdate();
                    if (filas > 0) {
                        out.println("<tr><td><strong>" + username + "</strong></td>");
                        out.println("<td>" + password + "</td>");
                        out.println("<td><span style='color:#155724;'>✅ Actualizado</span></td></tr>");
                        ok++;
                    } else {
                        out.println("<tr><td><strong>" + username + "</strong></td>");
                        out.println("<td>" + password + "</td>");
                        out.println("<td><span style='color:#856404;'>⚠️ No encontrado en BD</span></td></tr>");
                    }
                } catch (Exception e) {
                    out.println("<tr><td><strong>" + username + "</strong></td>");
                    out.println("<td>" + password + "</td>");
                    out.println("<td><span style='color:#721c24;'>❌ Error: " + e.getMessage() + "</span></td></tr>");
                    errores++;
                }
            }
        } catch (Exception e) {
            out.println("</tbody></table>");
            out.println("<div class='err'>❌ Error de conexión a la base de datos: " + e.getMessage() + "</div>");
            out.println("<p style='margin-top:1rem;font-size:.85rem;color:#666;'>Verifica que MySQL esté corriendo y que el archivo <code>context.xml</code> tenga los datos correctos.</p>");
            out.println("</div></body></html>");
            return;
        }

        out.println("</tbody></table>");

        if (errores == 0) {
            out.println("<div class='ok' style='margin-top:1rem;'>✅ Setup completado: " + ok + " usuario(s) actualizado(s).</div>");
        } else {
            out.println("<div class='err' style='margin-top:1rem;'>⚠️ " + ok + " ok, " + errores + " con error.</div>");
        }

        out.println("<div style='margin-top:1.5rem;padding:1rem;background:#f8f9fa;border-radius:8px;font-size:.85rem;'>");
        out.println("<strong>📋 Credenciales de acceso:</strong><br><br>");
        out.println("<table style='margin-top:0;'>");
        out.println("<tr><th>Usuario</th><th>Contraseña</th><th>Rol</th></tr>");
        out.println("<tr><td>admin</td><td>admin</td><td>ADMINISTRADOR</td></tr>");
        out.println("<tr><td>almacen1</td><td>almacen1</td><td>JEFE_ALMACEN</td></tr>");
        out.println("<tr><td>jefe_prod</td><td>jefe_prod</td><td>JEFE_PRODUCCION</td></tr>");
        out.println("<tr><td>tizador1</td><td>tizador1</td><td>TIZADOR</td></tr>");
        out.println("<tr><td>supervisor1</td><td>supervisor1</td><td>SUPERVISOR</td></tr>");
        out.println("<tr><td>maquinista1</td><td>maquinista1</td><td>MAQUINISTA</td></tr>");
        out.println("</table></div>");

        out.println("<a href='" + req.getContextPath() + "/login' class='btn'>🔐 Ir al Login</a>");
        out.println("</div></body></html>");
    }
}
