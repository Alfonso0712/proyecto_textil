
package modelo;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla telas.
 * Ubicación: modelo/TelaDAO.java
 * HU01: Registro y Control de Calidad de Tela Recibida
 */
public class TelaDAO {

    // ── INSERTAR ───────────────────────────────────────────────

    /**
     * Registra el ingreso de una tela (HU01).
     * La diferencia de peso es calculada por MySQL (columna STORED).
     */
    public boolean insertar(Tela t) {
        String sql = """
                INSERT INTO telas
                    (id_ot, id_registrador, codigo_tela, origen, proveedor,
                     peso_guia, peso_real, tipo_tejido, color, num_rollos,
                     observaciones, estado_calidad, requiere_reposo, id_catalogo_tela)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql,
                     Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,    t.getIdOt());
            ps.setInt(2,    t.getIdRegistrador());
            ps.setString(3, t.getCodigoTela());
            ps.setString(4, t.getOrigen().name());
            ps.setString(5, t.getProveedor());
            ps.setBigDecimal(6, t.getPesoGuia());
            ps.setBigDecimal(7, t.getPesoReal());
            ps.setString(8,  t.getTipoTejido());
            ps.setString(9,  t.getColor());
            ps.setInt(10,    t.getNumRollos());
            ps.setString(11, t.getObservaciones());
            ps.setString(12, t.getEstadoCalidad().name());
            ps.setBoolean(13,t.isRequiereReposo());
            ps.setObject(14, t.getIdCatalogoTela() > 0 ? t.getIdCatalogoTela() : null, Types.INTEGER);

            int filas = ps.executeUpdate();
            if (filas > 0) {
                try (ResultSet rk = ps.getGeneratedKeys()) {
                    if (rk.next()) t.setIdTela(rk.getInt(1));
                }
                return true;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al registrar tela: " + e.getMessage(), e);
        }
        return false;
    }

    // ── LISTAR ────────────────────────────────────────────────

    /** Lista todas las telas con datos de OT y registrador. */
    public List<Tela> listarTodas() {
        return listarConFiltro(null, null);
    }

    /** Lista telas de una OT específica. */
    public List<Tela> listarPorOt(int idOt) {
        return listarConFiltro("t.id_ot = ?", idOt);
    }

    private List<Tela> listarConFiltro(String condicion, Object valor) {
    List<Tela> lista = new ArrayList<>();
    String sql = """
            SELECT t.*, ot.codigo_ot,
                   CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador,
                   ct.nombre AS nombre_catalogo_tela
              FROM telas t
              JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
              JOIN usuarios u      ON t.id_registrador = u.id_usuario
              LEFT JOIN catalogo_telas ct ON t.id_catalogo_tela = ct.id_catalogo
            """ + (condicion != null ? " WHERE " + condicion : "") +
            " ORDER BY t.fecha_ingreso DESC";

    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {

        if (valor != null) ps.setObject(1, valor);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapearTela(rs));
        }
    } catch (SQLException e) {
        throw new RuntimeException("Error al listar telas: " + e.getMessage(), e);
    }
    return lista;
}

    /** Busca una tela por ID. */
    public Tela buscarPorId(int idTela) {
        String sql = """
                SELECT t.*, ot.codigo_ot,
                       CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador
                  FROM telas t
                  JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
                  JOIN usuarios u      ON t.id_registrador = u.id_usuario
                 WHERE t.id_tela = ?
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idTela);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearTela(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar tela: " + e.getMessage(), e);
        }
        return null;
    }

    // ── ACTUALIZAR ────────────────────────────────────────────

    /** Actualiza estado de calidad y observaciones. */
    public boolean actualizarEstado(int idTela, Tela.EstadoCalidad estado, String observaciones) {
        String sql = "UPDATE telas SET estado_calidad = ?, observaciones = ? WHERE id_tela = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, estado.name());
            ps.setString(2, observaciones);
            ps.setInt(3, idTela);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar tela: " + e.getMessage(), e);
        }
    }
    /**
    * Genera el siguiente código de tela en formato TELA-AAAA-NNNN.
    * Busca el último número usado en el año actual y le suma 1.
    * Si no hay registros en el año, empieza en 1.
    */
   public String generarSiguienteCodigoTela() {
       String año = String.valueOf(java.time.Year.now().getValue());
       String prefijo = "TELA-" + año + "-";
       String sql = "SELECT MAX(CAST(SUBSTRING(codigo_tela, " + (prefijo.length() + 1) + ") AS UNSIGNED)) FROM telas WHERE codigo_tela LIKE ?";
       // Alternativa más simple y portable:
       sql = "SELECT MAX(codigo_tela) FROM telas WHERE codigo_tela LIKE ?";
       try (Connection cn = ConexionDB.obtenerConexion();
            PreparedStatement ps = cn.prepareStatement(sql)) {
           ps.setString(1, prefijo + "%");
           try (ResultSet rs = ps.executeQuery()) {
               if (rs.next()) {
                   String maxCodigo = rs.getString(1);
                   if (maxCodigo != null && !maxCodigo.isEmpty()) {
                       // Extrae el número después del prefijo
                       String numeroStr = maxCodigo.substring(prefijo.length());
                       try {
                           int siguiente = Integer.parseInt(numeroStr) + 1;
                           return prefijo + String.format("%04d", siguiente);
                       } catch (NumberFormatException e) {
                           // Si falla, inicia en 1
                       }
                   }
               }
           }
       } catch (SQLException e) {
           throw new RuntimeException("Error al generar código de tela: " + e.getMessage(), e);
       }
       // Si no hay ninguna tela en el año, comienza en 0001
       return prefijo + "0001";
   }
    // ── MAPEADOR ──────────────────────────────────────────────

    private Tela mapearTela(ResultSet rs) throws SQLException {
        Tela t = new Tela();
        t.setIdTela(rs.getInt("id_tela"));
        t.setIdOt(rs.getInt("id_ot"));
        t.setIdRegistrador(rs.getInt("id_registrador"));
        t.setCodigoTela(rs.getString("codigo_tela"));
        t.setOrigen(Tela.Origen.valueOf(rs.getString("origen")));
        t.setProveedor(rs.getString("proveedor"));
        t.setPesoGuia(rs.getBigDecimal("peso_guia"));
        t.setPesoReal(rs.getBigDecimal("peso_real"));
        t.setDiferenciaPeso(rs.getBigDecimal("diferencia_peso"));
        t.setTipoTejido(rs.getString("tipo_tejido"));
        t.setColor(rs.getString("color"));
        t.setNumRollos(rs.getInt("num_rollos"));
        t.setObservaciones(rs.getString("observaciones"));
        t.setEstadoCalidad(Tela.EstadoCalidad.valueOf(rs.getString("estado_calidad")));
        t.setRequiereReposo(rs.getBoolean("requiere_reposo"));
        t.setFechaIngreso(rs.getTimestamp("fecha_ingreso"));
        t.setCodigoOt(rs.getString("codigo_ot"));
        t.setNombreRegistrador(rs.getString("nombre_registrador"));
        t.setNombreCatalogoTela(rs.getString("nombre_catalogo_tela"));
        // Nota: realmente id_catalogo_tela ya está en rs.getInt("id_catalogo_tela") que también podrías setear,
        // pero si prefieres guardarlo también, agrega:
        t.setIdCatalogoTela(rs.getInt("id_catalogo_tela"));
        return t;
    }
    
    /**
    * Lista telas aplicando filtros opcionales de búsqueda.
    * @param codigo       texto contenido en el código de tela (opcional)
    * @param proveedor    texto contenido en el proveedor (opcional)
    * @param fechaInicio  fecha mínima de ingreso (opcional, formato 'yyyy-MM-dd')
    * @param fechaFin     fecha máxima de ingreso (opcional, formato 'yyyy-MM-dd')
    */
   public List<Tela> listarConFiltros(String codigo, String proveedor, String fechaInicio, String fechaFin) {
       List<Tela> lista = new ArrayList<>();
       StringBuilder sql = new StringBuilder("""
               SELECT t.*, ot.codigo_ot,
                      CONCAT(u.nombre,' ',u.apellido) AS nombre_registrador,
                      ct.nombre AS nombre_catalogo_tela
                 FROM telas t
                 JOIN orden_trabajo ot ON t.id_ot = ot.id_ot
                 JOIN usuarios u      ON t.id_registrador = u.id_usuario
                 LEFT JOIN catalogo_telas ct ON t.id_catalogo_tela = ct.id_catalogo
                WHERE 1=1
               """);

       List<Object> parametros = new ArrayList<>();

       if (codigo != null && !codigo.trim().isEmpty()) {
           sql.append(" AND t.codigo_tela LIKE ?");
           parametros.add("%" + codigo.trim() + "%");
       }
       if (proveedor != null && !proveedor.trim().isEmpty()) {
           sql.append(" AND t.proveedor LIKE ?");
           parametros.add("%" + proveedor.trim() + "%");
       }
       if (fechaInicio != null && !fechaInicio.trim().isEmpty()) {
           sql.append(" AND t.fecha_ingreso >= ?");
           parametros.add(fechaInicio.trim() + " 00:00:00");
       }
       if (fechaFin != null && !fechaFin.trim().isEmpty()) {
           sql.append(" AND t.fecha_ingreso <= ?");
           parametros.add(fechaFin.trim() + " 23:59:59");
       }

       sql.append(" ORDER BY t.fecha_ingreso DESC");

       try (Connection cn = ConexionDB.obtenerConexion();
            PreparedStatement ps = cn.prepareStatement(sql.toString())) {

           for (int i = 0; i < parametros.size(); i++) {
               ps.setObject(i + 1, parametros.get(i));
           }

           try (ResultSet rs = ps.executeQuery()) {
               while (rs.next()) {
                   lista.add(mapearTela(rs));
               }
           }
       } catch (SQLException e) {
           throw new RuntimeException("Error al listar telas con filtros: " + e.getMessage(), e);
       }
       return lista;
   }
}
