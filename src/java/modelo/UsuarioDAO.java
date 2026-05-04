package modelo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla usuarios.
 * Ubicación: modelo/UsuarioDAO.java
 * HU08 (Login) | HU09 (Gestión de Perfiles)
 *
 * IMPORTANTE: Este DAO requiere BCrypt para el cifrado de contraseñas.
 * Descarga mindrot-jbcrypt-0.4.jar y colócalo en WEB-INF/lib/
 * (o usa la clase BCrypt incluida en muchos proyectos Spring/Maven).
 */
public class UsuarioDAO {

    // ── LOGIN ──────────────────────────────────────────────────

    /**
     * Valida credenciales de login (HU08).
     * @return Usuario con rol cargado, o null si las credenciales son incorrectas.
     */
    public Usuario validarLogin(String username, String passwordPlano) {
        String sql = """
                SELECT u.id_usuario, u.username, u.password, u.nombre, u.apellido,
                       u.email, u.id_rol, r.nombre_rol, u.activo
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
                    //}
                  
                    //if (passwordPlano.equals(hashAlmacenado)) {
                       // return mapearUsuario(rs);
                }}
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al validar login: " + e.getMessage(), e);
        }
        return null;
    }

    // ── CRUD ───────────────────────────────────────────────────

    /** Registra un nuevo usuario cifrando su contraseña (HU09). */
    public boolean insertar(Usuario u) {
        String sql = """
                INSERT INTO usuarios (username, password, nombre, apellido, email, id_rol)
                VALUES (?, ?, ?, ?, ?, ?)
                """;
        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, u.getUsername().trim());
            ps.setString(2, BCryptWrapper.cifrar(u.getPassword())); // Cifra aquí
            ps.setString(3, u.getNombre());
            ps.setString(4, u.getApellido());
            ps.setString(5, u.getEmail());
            ps.setInt(6,    u.getIdRol());
            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar usuario: " + e.getMessage(), e);
        }
    }

    /** Lista todos los usuarios con su rol (HU09 - gestión de perfiles). */
    public List<Usuario> listarTodos() {
        List<Usuario> lista = new ArrayList<>();
        String sql = """
                SELECT u.id_usuario, u.username, u.password, u.nombre, u.apellido,
                       u.email, u.id_rol, r.nombre_rol, u.activo
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

        String sql = cambiaPassword
            ? "UPDATE usuarios SET nombre=?, apellido=?, email=?, id_rol=?, password=?, activo=? WHERE id_usuario=?"
            : "UPDATE usuarios SET nombre=?, apellido=?, email=?, id_rol=?, activo=? WHERE id_usuario=?";

        try (Connection cn = ConexionDB.obtenerConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getEmail());
            ps.setInt(4,    u.getIdRol());
            if (cambiaPassword) {
                ps.setString(5, BCryptWrapper.cifrar(u.getPassword()));
                ps.setBoolean(6, u.isActivo());
                ps.setInt(7,    u.getIdUsuario());
            } else {
                ps.setBoolean(5, u.isActivo());
                ps.setInt(6,    u.getIdUsuario());
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
                       u.email, u.id_rol, r.nombre_rol, u.activo
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
}
