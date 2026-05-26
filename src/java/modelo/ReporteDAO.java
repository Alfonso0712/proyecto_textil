package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DAO: Reportes
 * Maneja las consultas de los reportes filtrados por tipo de usuario.
 */
public class ReporteDAO {

    public List<Map<String, Object>> obtenerEficienciaGlobal() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT estado, COUNT(*) as total_ots FROM orden_trabajo GROUP BY estado";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("estado", rs.getString("estado"));
                fila.put("total", rs.getInt("total_ots"));
                lista.add(fila);
            }
        }
        return lista;
    }

    public List<Map<String, Object>> obtenerMermaPorOT(int idUsuario, String rol) throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        boolean verTodo = esRolGlobal(rol);
        
        String sql = "SELECT ot.codigo_ot, SUM(m.peso_utilizado_kg) as peso_utilizado, SUM(m.peso_merma_kg) as peso_merma " +
                     "FROM mermas m " +
                     "JOIN orden_trabajo ot ON m.id_ot = ot.id_ot ";
        if (!verTodo) {
            sql += "WHERE m.id_tizador = ? ";
        }
        sql += "GROUP BY ot.codigo_ot ORDER BY ot.codigo_ot";
        
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (!verTodo) {
                ps.setInt(1, idUsuario);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new HashMap<>();
                    fila.put("codigo_ot", rs.getString("codigo_ot"));
                    fila.put("peso_utilizado", rs.getBigDecimal("peso_utilizado"));
                    fila.put("peso_merma", rs.getBigDecimal("peso_merma"));
                    
                    double utilizado = rs.getDouble("peso_utilizado");
                    double merma = rs.getDouble("peso_merma");
                    double porcentaje = utilizado > 0 ? (merma / utilizado) * 100 : 0.0;
                    fila.put("porcentaje_merma", Math.round(porcentaje * 100.0) / 100.0);
                    lista.add(fila);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> obtenerTiemposMaquinistasPorOT(int idUsuario, String rol) throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        boolean esMaquinista = "MAQUINISTA".equalsIgnoreCase(rol);
        
        String sql = "SELECT ot.codigo_ot, CONCAT(u.nombre, ' ', u.apellido) as maquinista, " +
                     "DATE_FORMAT(MIN(ac.fecha_asignacion), '%d/%m/%Y %H:%i') as inicio_real, " +
                     "DATE_FORMAT(MAX(ac.fecha_completado), '%d/%m/%Y %H:%i') as fin_real, " +
                     "TIMESTAMPDIFF(MINUTE, MIN(ac.fecha_asignacion), MAX(ac.fecha_completado)) as minutos_absolutos, " +
                     "SUM(TIMESTAMPDIFF(MINUTE, ac.fecha_asignacion, ac.fecha_completado)) as minutos_trabajados " +
                     "FROM asignaciones_carga ac " +
                     "JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot " +
                     "JOIN usuarios u ON ac.id_maquinista = u.id_usuario " +
                     "WHERE ac.estado_fase IN ('COMPLETADA', 'REGISTRADO') AND ac.fecha_completado IS NOT NULL ";
                     
        if (esMaquinista) {
            sql += "AND ac.id_maquinista = ? ";
        }
        sql += "GROUP BY ot.codigo_ot, maquinista ORDER BY ot.codigo_ot, maquinista";
        
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (esMaquinista) {
                ps.setInt(1, idUsuario);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new HashMap<>();
                    fila.put("codigo_ot", rs.getString("codigo_ot"));
                    fila.put("maquinista", rs.getString("maquinista"));
                    fila.put("inicio_real", rs.getString("inicio_real"));
                    fila.put("fin_real", rs.getString("fin_real"));
                    int minAbsolutos = rs.getInt("minutos_absolutos");
                    fila.put("tiempo_absoluto", (minAbsolutos / 60) + "h " + (minAbsolutos % 60) + "m");
                    
                    int minutos = rs.getInt("minutos_trabajados");
                    fila.put("minutos_trabajados", minutos);
                    fila.put("tiempo_formateado", (minutos / 60) + "h " + (minutos % 60) + "m");
                    lista.add(fila);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> obtenerFallasPorTela(int idUsuario, String rol) throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        boolean verTodo = esRolGlobal(rol) || rol.toUpperCase().contains("CALIDAD");
        
        String sql = "SELECT t.codigo_tela, COUNT(ft.id_falla) as fallas_totales " +
                     "FROM fallas_tela ft " +
                     "JOIN telas t ON ft.id_tela = t.id_tela ";
        if (!verTodo) {
            sql += "WHERE ft.id_tizador = ? ";
        }
        sql += "GROUP BY t.codigo_tela ORDER BY fallas_totales DESC";
        
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (!verTodo) {
                ps.setInt(1, idUsuario);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new HashMap<>();
                    fila.put("codigo_tela", rs.getString("codigo_tela"));
                    fila.put("fallas_totales", rs.getInt("fallas_totales"));
                    lista.add(fila);
                }
            }
        }
        return lista;
    }

    public List<Map<String, Object>> obtenerInventarioTelas() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT estado_calidad, COUNT(*) as cantidad, SUM(peso_real) as peso_total, " +
                     "AVG(peso_real) as peso_promedio " +
                     "FROM telas GROUP BY estado_calidad";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("estado", rs.getString("estado_calidad"));
                fila.put("cantidad", rs.getInt("cantidad"));
                fila.put("peso_total", rs.getBigDecimal("peso_total"));
                fila.put("peso_promedio", rs.getBigDecimal("peso_promedio"));
                lista.add(fila);
            }
        }
        return lista;
    }

    public List<Map<String, Object>> obtenerDespacho() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT ot.codigo_ot, ot.cantidad_est, cd.cantidad_final, cd.diferencia " +
                     "FROM conciliacion_despacho cd JOIN orden_trabajo ot ON cd.id_ot = ot.id_ot";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("codigo_ot", rs.getString("codigo_ot"));
                fila.put("estimada", rs.getInt("cantidad_est"));
                fila.put("final", rs.getInt("cantidad_final"));
                fila.put("diferencia", rs.getInt("diferencia"));
                lista.add(fila);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return lista;
    }

    public List<Map<String, Object>> obtenerCalidadVsProductividad() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT CONCAT(u.nombre, ' ', u.apellido) as maquinista, " +
                     "SUM(TIMESTAMPDIFF(MINUTE, ac.fecha_asignacion, ac.fecha_completado)) as minutos_trabajados, " +
                     "COALESCE((SELECT COUNT(*) FROM defectos_reproceso dr WHERE dr.id_maquinista = u.id_usuario), 0) as defectos_generados " +
                     "FROM asignaciones_carga ac " +
                     "JOIN usuarios u ON ac.id_maquinista = u.id_usuario " +
                     "WHERE ac.estado_fase IN ('COMPLETADA', 'REGISTRADO') AND ac.fecha_completado IS NOT NULL " +
                     "GROUP BY u.id_usuario, u.nombre, u.apellido";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("maquinista", rs.getString("maquinista"));
                fila.put("minutos", rs.getInt("minutos_trabajados"));
                fila.put("defectos", rs.getInt("defectos_generados"));
                lista.add(fila);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return lista;
    }

    public List<Map<String, Object>> obtenerOTsProblematicas() throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT ot.codigo_ot, ot.cantidad_est, " +
                     "COALESCE(SUM(m.peso_merma_kg), 0) as total_merma, " +
                     "COALESCE((SELECT COUNT(*) FROM defectos_reproceso dr WHERE dr.id_ot = ot.id_ot), 0) as total_defectos " +
                     "FROM orden_trabajo ot " +
                     "LEFT JOIN mermas m ON ot.id_ot = m.id_ot " +
                     "GROUP BY ot.id_ot, ot.codigo_ot, ot.cantidad_est " +
                     "ORDER BY total_defectos DESC, total_merma DESC LIMIT 15";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("codigo_ot", rs.getString("codigo_ot"));
                fila.put("cantidad_est", rs.getInt("cantidad_est"));
                fila.put("merma", rs.getBigDecimal("total_merma"));
                int defectos = rs.getInt("total_defectos");
                int cantEst = rs.getInt("cantidad_est");
                fila.put("defectos", defectos);
                double tasaFalla = cantEst > 0 ? ((double)defectos / cantEst) * 100 : 0.0;
                fila.put("tasa_falla", Math.round(tasaFalla * 100.0) / 100.0);
                lista.add(fila);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return lista;
    }

    public List<Map<String, Object>> obtenerRendimientoMaquinista(int idUsuario) throws SQLException {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql = "SELECT ot.codigo_ot, ot.cantidad_est, " +
                     "DATE_FORMAT(ac.fecha_asignacion, '%d/%m/%Y') as fecha_asignada, " +
                     "TIMESTAMPDIFF(MINUTE, ac.fecha_asignacion, ac.fecha_completado) as minutos_trabajados, " +
                     "DATEDIFF(ac.fecha_completado, ac.fecha_asignacion) as dias_retraso, " +
                     "COALESCE((SELECT COUNT(*) FROM defectos_reproceso dr WHERE dr.id_ot = ot.id_ot AND dr.id_maquinista = ?), 0) as defectos_propios " +
                     "FROM asignaciones_carga ac " +
                     "JOIN orden_trabajo ot ON ac.id_ot = ot.id_ot " +
                     "WHERE ac.id_maquinista = ? AND ac.estado_fase IN ('COMPLETADA', 'REGISTRADO') AND ac.fecha_completado IS NOT NULL " +
                     "ORDER BY ac.fecha_completado DESC";
                     
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new HashMap<>();
                    fila.put("codigo_ot", rs.getString("codigo_ot"));
                    int cantEst = rs.getInt("cantidad_est");
                    fila.put("cantidad_est", cantEst);
                    fila.put("fecha_asignada", rs.getString("fecha_asignada"));
                    int minTra = rs.getInt("minutos_trabajados");
                    fila.put("minutos_trabajados", minTra);
                    int diasRetraso = rs.getInt("dias_retraso");
                    fila.put("dias_retraso", diasRetraso);
                    int defPropios = rs.getInt("defectos_propios");
                    fila.put("defectos_propios", defPropios);
                    
                    // Variables calculadas
                    double vel = cantEst > 0 ? (double)minTra / cantEst : minTra;
                    fila.put("velocidad_min_prenda", Math.round(vel * 100.0) / 100.0);
                    
                    String efiEnt = diasRetraso <= 0 ? "A Tiempo" : "Retraso (" + diasRetraso + "d)";
                    fila.put("eficiencia_entrega", efiEnt);
                    
                    double tasaResp = cantEst > 0 ? ((double)defPropios / cantEst) * 100 : 0;
                    fila.put("tasa_responsabilidad", Math.round(tasaResp * 100.0) / 100.0);
                    
                    lista.add(fila);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return lista;
    }

    private boolean esRolGlobal(String rol) {
        if (rol == null) return false;
        String r = rol.toUpperCase();
        return r.contains("ADMINISTRADOR") || r.contains("SUPERVISOR") || r.contains("GERENTE") || r.contains("JEFE");
    }
}
