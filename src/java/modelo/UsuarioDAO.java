package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UsuarioDAO {

    // ── LOGIN ──────────────────────────────────────────────────

    /**
     * Valida credenciales de login (HU08).
     * @return Usuario con rol cargado, o null si las credenciales son incorrectas.
     */
    public Usuario validarLogin(String username, String passwordPlano) {
        String sql = """
            SELECT u.id_usuario, u.username, u.password, u.nombre, u.apellido,
                   u.email, u.id_rol, r.nombre_rol, u.activo,
                   u.horario_restringido, u.horario_dias, u.horario_inicio, u.horario_fin
              FROM usuarios u
              JOIN roles r ON u.id_rol = r.id_rol
             WHERE u.username = ? AND u.activo = 1
            """;

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, username.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String hashAlmacenado = rs.getString("password");
                    // Verificación BCrypt — compara texto plano con hash guardado
                    if (BCryptWrapper.verificar(passwordPlano, hashAlmacenado)) {
                        return mapearUsuario(rs);
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al validar login: " + e.getMessage(), e);
        }
        return null;
    }

    // ── CRUD ───────────────────────────────────────────────────

    /** Registra un nuevo usuario cifrando su contraseña (HU09). */
    /** Registra un nuevo usuario cifrando su contraseña. */
    public boolean insertar(Usuario u) {
        String sql = """
                INSERT INTO usuarios (username, password, nombre, apellido, email, id_rol, horario_restringido, horario_dias, horario_inicio, horario_fin)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;

        // CORRECCIÓN: Se agrega Statement.RETURN_GENERATED_KEYS aquí
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, u.getUsername().trim());
            ps.setString(2, BCryptWrapper.cifrar(u.getPassword()));
            ps.setString(3, u.getNombre());
            ps.setString(4, u.getApellido());
            ps.setString(5, u.getEmail());
            ps.setInt(6,    u.getIdRol());
            ps.setBoolean(7, u.isHorarioRestringido());
            ps.setString(8,  u.getHorarioDias());
            ps.setString(9,  u.getHorarioInicio());
            ps.setString(10, u.getHorarioFin());

            int filasAfectadas = ps.executeUpdate();

            if (filasAfectadas > 0) {
                // Ahora sí, esto funcionará sin errores
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        u.setIdUsuario(rs.getInt(1)); // Aquí se le asigna el ID real al objeto
                    }
                }
                return true;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar usuario: " + e.getMessage(), e);
        }
        return false;
    }

    /** Lista todos los usuarios con su rol (HU09 - gestión de perfiles). */
    public List<Usuario> listarTodos() {
        List<Usuario> lista = new ArrayList<>();
        String sql = """
            SELECT u.id_usuario, u.username, u.password, u.nombre, u.apellido,
                   u.email, u.id_rol, r.nombre_rol, u.activo,
                   u.horario_restringido, u.horario_dias, u.horario_inicio, u.horario_fin
              FROM usuarios u
              JOIN roles r ON u.id_rol = r.id_rol
             ORDER BY u.nombre
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapearUsuario(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar usuarios: " + e.getMessage(), e);
        }
        return lista;
    }

    /** Actualiza datos de un usuario; si password no está vacío, la re-cifra. */
    public boolean actualizar(Usuario u) {
        boolean cambiaPassword = (u.getPassword() != null && !u.getPassword().isBlank());

        String sql = """
            UPDATE usuarios SET
                nombre = ?,
                apellido = ?,
                email = ?,
                id_rol = ?,
                activo = ?,
                horario_restringido = ?,
                horario_dias = ?,
                horario_inicio = ?,
                horario_fin = ?
            """ + (cambiaPassword ? ", password = ?" : "") + " WHERE id_usuario = ?";

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getEmail());
            ps.setInt   (4, u.getIdRol());
            ps.setBoolean(5, u.isActivo());
            ps.setBoolean(6, u.isHorarioRestringido());
            ps.setString (7, u.getHorarioDias());
            ps.setString (8, u.getHorarioInicio());
            ps.setString (9, u.getHorarioFin());

            if (cambiaPassword) {
                ps.setString(10, BCryptWrapper.cifrar(u.getPassword()));
                ps.setInt   (11, u.getIdUsuario());
            } else {
                ps.setInt   (10, u.getIdUsuario());
            }

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar usuario: " + e.getMessage(), e);
        }
    }

    /** Desactiva (no elimina) una cuenta — HU09 criterio 2. */
    public boolean desactivar(int idUsuario) {
        String sql = "UPDATE usuarios SET activo = 0 WHERE id_usuario = ?";
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Error al desactivar usuario: " + e.getMessage(), e);
        }
    }

    /** Busca usuario por ID (útil para edición). */
    public Usuario buscarPorId(int idUsuario) {
        String sql = """
            SELECT u.id_usuario, u.username, u.password, u.nombre, u.apellido,
                   u.email, u.id_rol, r.nombre_rol, u.activo,
                   u.horario_restringido, u.horario_dias, u.horario_inicio, u.horario_fin
              FROM usuarios u
              JOIN roles r ON u.id_rol = r.id_rol
             WHERE u.id_usuario = ?
            """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearUsuario(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al buscar usuario: " + e.getMessage(), e);
        }
        return null;
    }
    /**
    * Verifica si el usuario tiene registros que impiden su eliminación.
    * Retorna true si NO se puede eliminar.
    */
   public boolean tieneActividades(int idUsuario) {
       // Verificar en orden_trabajo (id_responsable)
       String sqlOt = "SELECT COUNT(*) FROM orden_trabajo WHERE id_responsable = ?";
       // Verificar en telas (id_registrador)
       String sqlTelas = "SELECT COUNT(*) FROM telas WHERE id_registrador = ?";

       try (Connection cn = ConexionDB.obtenerConexion()) {
           try (PreparedStatement ps = cn.prepareStatement(sqlOt)) {
               ps.setInt(1, idUsuario);
               try (ResultSet rs = ps.executeQuery()) {
                   if (rs.next() && rs.getInt(1) > 0) return true;
               }
           }
           try (PreparedStatement ps = cn.prepareStatement(sqlTelas)) {
               ps.setInt(1, idUsuario);
               try (ResultSet rs = ps.executeQuery()) {
                   if (rs.next() && rs.getInt(1) > 0) return true;
               }
           }
       } catch (SQLException e) {
           throw new RuntimeException("Error al verificar actividades del usuario", e);
       }
       return false;
   }

   /**
    * Elimina definitivamente un usuario después de verificar que no tenga actividades.
    * Retorna true si se eliminó, false si no se pudo (por actividades).
    */
   public boolean eliminar(int idUsuario) {
       // Verificar actividades primero
       if (tieneActividades(idUsuario)) {
           return false; // No se puede eliminar
       }
       String deleteEspecialidades = "DELETE FROM usuario_especialidad WHERE id_usuario = ?";
       String deleteUsuario        = "DELETE FROM usuarios WHERE id_usuario = ?";
       try (Connection cn = ConexionDB.obtenerConexion()) {
           cn.setAutoCommit(false);
           try (PreparedStatement psEsp = cn.prepareStatement(deleteEspecialidades);
                PreparedStatement psUsr = cn.prepareStatement(deleteUsuario)) {
               psEsp.setInt(1, idUsuario);
               psEsp.executeUpdate();
               psUsr.setInt(1, idUsuario);
               int filas = psUsr.executeUpdate();
               cn.commit();
               return filas > 0;
           } catch (SQLException e) {
               cn.rollback();
               throw e;
           }
       } catch (SQLException e) {
           throw new RuntimeException("Error al eliminar usuario: " + e.getMessage(), e);
       }
   }
    // ── MAPEADOR ───────────────────────────────────────────────

    private Usuario mapearUsuario(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setIdUsuario(rs.getInt("id_usuario"));
        u.setUsername(rs.getString("username"));
        u.setPassword(rs.getString("password"));
        u.setNombre(rs.getString("nombre"));
        u.setApellido(rs.getString("apellido"));
        u.setEmail(rs.getString("email"));
        u.setIdRol(rs.getInt("id_rol"));
        u.setNombreRol(rs.getString("nombre_rol"));
        u.setActivo(rs.getBoolean("activo"));
        // Estas líneas son las que fallaban porque no estaban en el SELECT:
        u.setHorarioRestringido(rs.getBoolean("horario_restringido"));
        u.setHorarioDias(rs.getString("horario_dias"));
        u.setHorarioInicio(rs.getString("horario_inicio"));
        u.setHorarioFin(rs.getString("horario_fin"));
        return u;
    }

    // ── WRAPPER BCrypt (inner class) ───────────────────────────
    // Si ya tienes jbcrypt en tu classpath, elimina esta inner class
    // y usa directamente: BCrypt.checkpw() / BCrypt.hashpw()

    public static class BCryptWrapper {
        private static final int RONDAS = 12;

        /** Cifra una contraseña en texto plano. */
        public static String cifrar(String passwordPlano) {
            return org.mindrot.jbcrypt.BCrypt.hashpw(passwordPlano,
                   org.mindrot.jbcrypt.BCrypt.gensalt(RONDAS));
        }

        /** Compara texto plano con hash almacenado. */
        public static boolean verificar(String passwordPlano, String hash) {
            try {
                return org.mindrot.jbcrypt.BCrypt.checkpw(passwordPlano, hash);
            } catch (Exception e) {
                return false;
            }
        }
    }
    public List<Usuario> listarPorRol(int idRol) {
    List<Usuario> lista = new ArrayList<>();
    String sql = "SELECT u.*, r.nombre_rol FROM usuarios u JOIN roles r ON u.id_rol = r.id_rol WHERE u.id_rol = ? ORDER BY u.apellido";
    try (Connection cn = ConexionDB.obtenerConexion();
         PreparedStatement ps = cn.prepareStatement(sql)) {
        ps.setInt(1, idRol);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setIdUsuario(rs.getInt("id_usuario"));
                u.setUsername(rs.getString("username"));
                u.setNombre(rs.getString("nombre"));
                u.setApellido(rs.getString("apellido"));
                u.setEmail(rs.getString("email"));
                u.setIdRol(rs.getInt("id_rol"));
                u.setNombreRol(rs.getString("nombre_rol"));
                u.setActivo(rs.getBoolean("activo"));
                lista.add(u);
            }
        }
    } catch (SQLException e) {
        throw new RuntimeException("Error al listar usuarios por rol", e);
    }
    return lista;
}
    
}
