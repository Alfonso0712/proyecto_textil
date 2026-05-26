package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import modelo.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.*;

@WebServlet(name = "DashboardServlet", urlPatterns = {"/dashboard"})
public class DashboardServlet extends HttpServlet {

    private final OrdenTrabajoDAO    otDAO    = new OrdenTrabajoDAO();
    private final AsignacionCargaDAO cargaDAO = new AsignacionCargaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if ("json".equals(request.getParameter("accion"))) {
            servirJSON(response);
            return;
        }
        // Cargar OTs con progreso para renderizado directo en servidor
        try {
            List<OrdenTrabajo> ordenes = otDAO.listarTodas();
            java.util.Map<Integer, int[]> prog = new HashMap<>();
            try (java.sql.Connection cn = ConexionDB.obtenerConexion();
                 java.sql.PreparedStatement ps = cn.prepareStatement(
                    "SELECT id_ot, COUNT(*) AS total, " +
                    "SUM(CASE WHEN estado_fase='COMPLETADA' THEN 1 ELSE 0 END) AS comp, " +
                    "SUM(CASE WHEN estado_fase='EN_PROCESO' THEN 1 ELSE 0 END) AS proc " +
                    "FROM asignaciones_carga GROUP BY id_ot");
                 java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    prog.put(rs.getInt("id_ot"),
                             new int[]{rs.getInt("total"), rs.getInt("comp"), rs.getInt("proc")});
                }
            } catch (Exception ex2) {
                System.err.println("[Dashboard] asignaciones_carga: " + ex2.getMessage());
            }
            List<java.util.Map<String,Object>> filas = new ArrayList<>();
            for (OrdenTrabajo ot : ordenes) {
                int[] p    = prog.get(ot.getIdOt());
                int total  = p != null ? p[0] : 0;
                int comp   = p != null ? p[1] : 0;
                int proc   = p != null ? p[2] : 0;
                int pct    = total > 0 ? (comp * 100 / total) : 0;
                if ("FINALIZADA".equals(ot.getEstado())) pct = 100;
                String fecha = "";
                if (ot.getFechaCrea() != null)
                    fecha = ot.getFechaCrea().toString().substring(0, 16);
                java.util.Map<String,Object> fila = new HashMap<>();
                fila.put("codigo",      ot.getCodigoOt()         != null ? ot.getCodigoOt()         : "");
                fila.put("cliente",     ot.getCliente()           != null ? ot.getCliente()           : "");
                fila.put("responsable", ot.getNombreResponsable() != null ? ot.getNombreResponsable() : "");
                fila.put("estado",      ot.getEstado()            != null ? ot.getEstado()            : "");
                fila.put("fecha",       fecha);
                fila.put("progreso",    pct);
                fila.put("fasesComp",   comp);
                fila.put("fasesTotal",  total);
                fila.put("enProc",      proc);
                filas.add(fila);
            }
            request.setAttribute("otFilas", filas);
        } catch (Exception ex) {
            System.err.println("[Dashboard] Error cargando OTs: " + ex.getMessage());
            request.setAttribute("otFilas", new ArrayList<>());
        }
        request.getRequestDispatcher("vista/dashboard.jsp").forward(request, response);
    }

    private void servirJSON(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Cache-Control", "no-cache");
        PrintWriter out = response.getWriter();

        StringBuilder json = new StringBuilder("{");

        try (Connection cn = ConexionDB.obtenerConexion()) {

            // ── 1. OTs con progreso ──────────────────────────────────────────
            Map<Integer, int[]> prog = new HashMap<>();
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT id_ot, COUNT(*) AS total," +
                    "SUM(CASE WHEN estado_fase='COMPLETADA' THEN 1 ELSE 0 END) AS comp," +
                    "SUM(CASE WHEN estado_fase='EN_PROCESO' THEN 1 ELSE 0 END) AS proc " +
                    "FROM asignaciones_carga GROUP BY id_ot");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    prog.put(rs.getInt("id_ot"),
                             new int[]{rs.getInt("total"), rs.getInt("comp"), rs.getInt("proc")});
            } catch (Exception e) {
                System.err.println("[Dashboard JSON] asignaciones_carga: " + e.getMessage());
            }

            List<OrdenTrabajo> ordenes = otDAO.listarTodas();
            json.append("\"ordenes\":[");
            for (int i = 0; i < ordenes.size(); i++) {
                if (i > 0) json.append(",");
                OrdenTrabajo ot = ordenes.get(i);
                int[] p = prog.get(ot.getIdOt());
                int total = p != null ? p[0] : 0, comp = p != null ? p[1] : 0, proc = p != null ? p[2] : 0;
                int pct = total > 0 ? (comp * 100 / total) : 0;
                if ("FINALIZADA".equals(ot.getEstado())) pct = 100;
                String fecha = ot.getFechaCrea() != null ? ot.getFechaCrea().toString().substring(0, 16) : "";
                json.append("{")
                    .append("\"codigo\":\"").append(esc(ot.getCodigoOt())).append("\",")
                    .append("\"cliente\":\"").append(esc(ot.getCliente())).append("\",")
                    .append("\"responsable\":\"").append(esc(ot.getNombreResponsable())).append("\",")
                    .append("\"estado\":\"").append(esc(ot.getEstado())).append("\",")
                    .append("\"fecha\":\"").append(esc(fecha)).append("\",")
                    .append("\"progreso\":").append(pct).append(",")
                    .append("\"fasesComp\":").append(comp).append(",")
                    .append("\"fasesTotal\":").append(total).append(",")
                    .append("\"enProc\":").append(proc)
                    .append("}");
            }
            json.append("],");

            // ── 2. KPIs ─────────────────────────────────────────────────────
            int otActivas = (int) ordenes.stream()
                .filter(o -> "CREADA".equals(o.getEstado()) || "EN_PROCESO".equals(o.getEstado())).count();
            int otFinalizadas = (int) ordenes.stream().filter(o -> "FINALIZADA".equals(o.getEstado())).count();

            // Merma promedio real
            double mermaPromedio = 0;
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT AVG(porcentaje_merma) AS prom FROM mermas");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) mermaPromedio = rs.getDouble("prom");
            } catch (Exception e) { System.err.println("[Dashboard JSON] merma avg: " + e.getMessage()); }

            // Alertas de calidad = defectos PENDIENTE
            int alertasCalidad = 0;
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT COUNT(*) AS cnt FROM defectos_reproceso WHERE estado='PENDIENTE'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) alertasCalidad = rs.getInt("cnt");
            } catch (Exception e) { System.err.println("[Dashboard JSON] alertas: " + e.getMessage()); }

            // Telas listas para corte
            int telasListaCorte = 0;
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT COUNT(*) AS cnt FROM tiempos_reposo WHERE estado='APTO_CORTE'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) telasListaCorte = rs.getInt("cnt");
            } catch (Exception e) { System.err.println("[Dashboard JSON] telas corte: " + e.getMessage()); }

            // Eficiencia: % fases completadas sobre total
            double eficiencia = 0;
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT COUNT(*) AS total, SUM(CASE WHEN estado_fase='COMPLETADA' THEN 1 ELSE 0 END) AS comp " +
                    "FROM asignaciones_carga");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int t = rs.getInt("total"), c = rs.getInt("comp");
                    if (t > 0) eficiencia = Math.round((c * 100.0 / t) * 10) / 10.0;
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] eficiencia: " + e.getMessage()); }

            json.append("\"kpis\":{")
                .append("\"otActivas\":").append(otActivas).append(",")
                .append("\"prendas\":").append(otFinalizadas).append(",")
                .append("\"eficiencia\":").append(eficiencia).append(",")
                .append("\"alertas\":").append(alertasCalidad).append(",")
                .append("\"mermaPromedio\":").append(Math.round(mermaPromedio * 10) / 10.0).append(",")
                .append("\"telasListaCorte\":").append(telasListaCorte)
                .append("},");

            // ── 3. Maquinistas con cargas reales ────────────────────────────
            json.append("\"maquinistas\":[");
            try {
                List<AsignacionCargaDAO.ResumenCargaMaquinista> maq = cargaDAO.resumenCargaPorMaquinista();
                // También necesitamos completadas
                Map<Integer, Integer> completadas = new HashMap<>();
                try (PreparedStatement ps = cn.prepareStatement(
                        "SELECT id_maquinista, COUNT(*) AS cnt FROM asignaciones_carga " +
                        "WHERE estado_fase='COMPLETADA' GROUP BY id_maquinista");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) completadas.put(rs.getInt("id_maquinista"), rs.getInt("cnt"));
                }
                for (int i = 0; i < maq.size(); i++) {
                    if (i > 0) json.append(",");
                    AsignacionCargaDAO.ResumenCargaMaquinista m = maq.get(i);
                    int comp2 = completadas.getOrDefault(m.getIdMaquinista(), 0);
                    json.append("{")
                        .append("\"nombre\":\"").append(esc(m.getNombreMaquinista())).append("\",")
                        .append("\"completadas\":").append(comp2).append(",")
                        .append("\"pendientes\":").append(m.getTotalActivas())
                        .append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] maquinistas: " + e.getMessage()); }
            json.append("],");

            // ── 4. Mermas por tipo de defecto (tabla mermas) ─────────────────
            json.append("\"mermas\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT fase AS label, SUM(peso_merma_kg) AS valor FROM mermas GROUP BY fase ORDER BY valor DESC");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"label\":\"").append(esc(rs.getString("label"))).append("\",")
                        .append("\"valor\":").append(rs.getDouble("valor")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] mermas: " + e.getMessage()); }
            json.append("],");

            // ── 5. Merma % por OT ────────────────────────────────────────────
            json.append("\"mermaOT\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT ot.codigo_ot AS ot, " +
                    "ROUND(SUM(m.peso_merma_kg)/NULLIF(SUM(m.peso_utilizado_kg),0)*100,2) AS pct " +
                    "FROM mermas m JOIN orden_trabajo ot ON m.id_ot=ot.id_ot " +
                    "GROUP BY m.id_ot, ot.codigo_ot ORDER BY pct DESC LIMIT 10");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"ot\":\"").append(esc(rs.getString("ot"))).append("\",")
                        .append("\"pct\":").append(rs.getDouble("pct")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] mermaOT: " + e.getMessage()); }
            json.append("],");

            // ── 6. Defectos por tipo/gravedad ────────────────────────────────
            json.append("\"defectos\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT tipo_falla AS tipo, estado, COUNT(*) AS cantidad " +
                    "FROM defectos_reproceso GROUP BY tipo_falla, estado ORDER BY cantidad DESC");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"tipo\":\"").append(esc(rs.getString("tipo"))).append("\",")
                        .append("\"estado\":\"").append(esc(rs.getString("estado"))).append("\",")
                        .append("\"cantidad\":").append(rs.getInt("cantidad")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] defectos: " + e.getMessage()); }
            json.append("],");

            // ── 7. Telas por estado de calidad ───────────────────────────────
            json.append("\"telas\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT estado_calidad AS estado, origen, tipo_tejido AS tejido, COUNT(*) AS cantidad " +
                    "FROM telas GROUP BY estado_calidad, origen, tipo_tejido");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"estado\":\"").append(esc(rs.getString("estado"))).append("\",")
                        .append("\"origen\":\"").append(esc(rs.getString("origen"))).append("\",")
                        .append("\"tejido\":\"").append(esc(rs.getString("tejido"))).append("\",")
                        .append("\"cantidad\":").append(rs.getInt("cantidad")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] telas: " + e.getMessage()); }
            json.append("],");

            // ── 8. Tiempos de reposo ─────────────────────────────────────────
            json.append("\"reposos\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT t.codigo_tela AS tela, tr.estado, " +
                    "TIMESTAMPDIFF(HOUR, tr.fecha_inicio, IFNULL(tr.fecha_fin, NOW())) AS horas " +
                    "FROM tiempos_reposo tr JOIN telas t ON tr.id_tela=t.id_tela " +
                    "ORDER BY tr.fecha_inicio DESC LIMIT 10");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"tela\":\"").append(esc(rs.getString("tela"))).append("\",")
                        .append("\"estado\":\"").append(esc(rs.getString("estado"))).append("\",")
                        .append("\"horas\":").append(rs.getInt("horas")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] reposos: " + e.getMessage()); }
            json.append("],");

            // ── 9. Cargas por maquinista y fase ──────────────────────────────
            json.append("\"cargas\":[");
            // Detectar si fases_produccion existe; si no, usar tipo_tarea como agrupador
            boolean tieneFases = false;
            try (PreparedStatement testFp = cn.prepareStatement("SELECT 1 FROM fases_produccion LIMIT 1");
                 ResultSet rsFp = testFp.executeQuery()) { tieneFases = true; }
            catch (Exception eFp) { System.err.println("[Dashboard] fases_produccion no accesible: " + eFp.getMessage()); }
            String sqlCargas = tieneFases
                ? "SELECT CONCAT(u.nombre,' ',u.apellido) AS maquinista, fp.nombre AS fase, " +
                  "SUM(CASE WHEN ac.estado_fase='COMPLETADA' THEN 1 ELSE 0 END) AS completadas, " +
                  "SUM(CASE WHEN ac.estado_fase IN('PENDIENTE','EN_PROCESO') THEN 1 ELSE 0 END) AS pendientes " +
                  "FROM asignaciones_carga ac JOIN usuarios u ON ac.id_maquinista=u.id_usuario " +
                  "JOIN fases_produccion fp ON ac.id_fase=fp.id_fase " +
                  "WHERE ac.id_maquinista IS NOT NULL AND ac.tipo_tarea='NORMAL' " +
                  "GROUP BY ac.id_maquinista, fp.nombre ORDER BY completadas DESC LIMIT 20"
                : "SELECT CONCAT(u.nombre,' ',u.apellido) AS maquinista, ac.tipo_tarea AS fase, " +
                  "SUM(CASE WHEN ac.estado_fase='COMPLETADA' THEN 1 ELSE 0 END) AS completadas, " +
                  "SUM(CASE WHEN ac.estado_fase IN('PENDIENTE','EN_PROCESO') THEN 1 ELSE 0 END) AS pendientes " +
                  "FROM asignaciones_carga ac JOIN usuarios u ON ac.id_maquinista=u.id_usuario " +
                  "WHERE ac.id_maquinista IS NOT NULL " +
                  "GROUP BY ac.id_maquinista, ac.tipo_tarea ORDER BY completadas DESC LIMIT 20";
            try (PreparedStatement ps = cn.prepareStatement(sqlCargas);
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"maquinista\":\"").append(esc(rs.getString("maquinista"))).append("\",")
                        .append("\"fase\":\"").append(esc(rs.getString("fase"))).append("\",")
                        .append("\"completadas\":").append(rs.getInt("completadas")).append(",")
                        .append("\"pendientes\":").append(rs.getInt("pendientes")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] cargas: " + e.getMessage()); }
            json.append("],");

            // ── 10. Alertas reales: defectos PENDIENTE por OT ────────────────
            json.append("\"alertas\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT ot.codigo_ot AS codigo, COUNT(*) AS cant, " +
                    "CONCAT(COUNT(*),' defecto(s) pendiente(s)') AS mensaje " +
                    "FROM defectos_reproceso dr JOIN orden_trabajo ot ON dr.id_ot=ot.id_ot " +
                    "WHERE dr.estado='PENDIENTE' " +
                    "GROUP BY dr.id_ot, ot.codigo_ot ORDER BY cant DESC LIMIT 10");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"codigo\":\"").append(esc(rs.getString("codigo"))).append("\",")
                        .append("\"mensaje\":\"").append(esc(rs.getString("mensaje"))).append("\"}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] alertas: " + e.getMessage()); }
            json.append("],");

            // ── 11. Inventario telas críticas (peso_real ASC = menos tela) ───
            json.append("\"inventarioCritico\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT codigo_tela AS codigo, tipo_tejido AS tipo, " +
                    "CONCAT(ROUND(peso_real,1),' kg') AS restante " +
                    "FROM telas WHERE estado_calidad != 'RECHAZADO' " +
                    "ORDER BY peso_real ASC LIMIT 8");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"codigo\":\"").append(esc(rs.getString("codigo"))).append("\",")
                        .append("\"tipo\":\"").append(esc(rs.getString("tipo"))).append("\",")
                        .append("\"restante\":\"").append(esc(rs.getString("restante"))).append("\"}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] inventario: " + e.getMessage()); }
            json.append("],");

            // ── 12. Eficiencia semanal real ───────────────────────────────────
            json.append("\"eficienciaSemanal\":[");
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT DATE_FORMAT(fecha_asignacion,'%d/%m') AS semana, " +
                    "ROUND(SUM(CASE WHEN estado_fase='COMPLETADA' THEN 1 ELSE 0 END)*100.0/COUNT(*),1) AS pct " +
                    "FROM asignaciones_carga " +
                    "WHERE fecha_asignacion >= DATE_SUB(NOW(), INTERVAL 12 WEEK) " +
                    "GROUP BY YEARWEEK(fecha_asignacion) " +
                    "ORDER BY MIN(fecha_asignacion) ASC LIMIT 12");
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(","); first = false;
                    json.append("{\"semana\":\"").append(esc(rs.getString("semana"))).append("\",")
                        .append("\"pct\":").append(rs.getDouble("pct")).append("}");
                }
            } catch (Exception e) { System.err.println("[Dashboard JSON] eficienciaSemanal: " + e.getMessage()); }
            json.append("]");

            json.append("}");
            out.print(json.toString());

        } catch (Exception ex) {
            ex.printStackTrace();
            System.err.println("[DashboardServlet] Error general: " + ex.getMessage());
            out.print("{\"ordenes\":[],\"kpis\":{},\"maquinistas\":[],\"mermas\":[],\"mermaOT\":[]," +
                      "\"defectos\":[],\"telas\":[],\"reposos\":[],\"cargas\":[]," +
                      "\"alertas\":[],\"inventarioCritico\":[],\"eficienciaSemanal\":[]}");
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"")
                .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t");
    }
}
