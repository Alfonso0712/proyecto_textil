package modelo;

/**
 * Entidad: usuarios
 * Ubicación: modelo/Usuario.java
 * HU08 (Login) | HU09 (Gestión de Perfiles)
 */
public class Usuario {

    private int    idUsuario;
    private String username;
    private String password;   // Hash BCrypt — NUNCA texto plano
    private String nombre;
    private String apellido;
    private String email;
    private int    idRol;
    private String nombreRol;  // Join con tabla roles (uso en vistas)
    private boolean activo;

    public Usuario() {}

    public Usuario(int idUsuario, String username, String nombre,
                   String apellido, String email, int idRol,
                   String nombreRol, boolean activo) {
        this.idUsuario  = idUsuario;
        this.username   = username;
        this.nombre     = nombre;
        this.apellido   = apellido;
        this.email      = email;
        this.idRol      = idRol;
        this.nombreRol  = nombreRol;
        this.activo     = activo;
    }

    // ── Getters y Setters ──────────────────────────────────────

    public int     getIdUsuario()  { return idUsuario;  }
    public void    setIdUsuario(int idUsuario)  { this.idUsuario = idUsuario; }

    public String  getUsername()   { return username;   }
    public void    setUsername(String username) { this.username = username; }

    public String  getPassword()   { return password;   }
    public void    setPassword(String password){ this.password = password; }

    public String  getNombre()     { return nombre;     }
    public void    setNombre(String nombre)    { this.nombre = nombre; }

    public String  getApellido()   { return apellido;   }
    public void    setApellido(String apellido){ this.apellido = apellido; }

    public String  getEmail()      { return email;      }
    public void    setEmail(String email)      { this.email = email; }

    public int     getIdRol()      { return idRol;      }
    public void    setIdRol(int idRol)         { this.idRol = idRol; }

    public String  getNombreRol()  { return nombreRol;  }
    public void    setNombreRol(String nombreRol) { this.nombreRol = nombreRol; }

    public boolean isActivo()      { return activo;     }
    public void    setActivo(boolean activo)   { this.activo = activo; }

    /** Nombre completo para mostrar en vistas */
    public String getNombreCompleto() {
        return nombre + " " + apellido;
    }
}
