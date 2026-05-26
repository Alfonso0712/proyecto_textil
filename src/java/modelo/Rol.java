package modelo;

/**
 * Entidad: roles
 * Ubicación: modelo/Rol.java
 * HU09: Gestión de Perfiles y Permisos
 *
 * Representa un rol del sistema (ADMINISTRADOR, SUPERVISOR, etc.)
 */
public class Rol {

    private int    idRol;
    private String nombreRol;
    private String descripcion;

    public Rol() {}

    public Rol(int idRol, String nombreRol, String descripcion) {
        this.idRol      = idRol;
        this.nombreRol  = nombreRol;
        this.descripcion = descripcion;
    }

    // ── Getters y Setters ──────────────────────────────────────

    public int    getIdRol()       { return idRol;       }
    public void   setIdRol(int id) { this.idRol = id;    }

    public String getNombreRol()              { return nombreRol;   }
    public void   setNombreRol(String nombre) { this.nombreRol = nombre; }

    public String getDescripcion()            { return descripcion; }
    public void   setDescripcion(String d)    { this.descripcion = d; }

    /** Para mostrar en JComboBox directamente */
    @Override
    public String toString() {
        return nombreRol;
    }
}
