package modelo;

/**
 * Entidad: permisos
 * Ubicación: modelo/Permiso.java
 * HU09: Gestión de Perfiles y Permisos
 *
 * Representa un permiso/funcionalidad del sistema.
 * Los permisos se asignan a roles (tabla rol_permiso).
 */
public class Permiso {

    private int    idPermiso;
    private String codigo;       // Clave técnica: MODULO_ACCION (ej: ALM_TELA_REGISTRAR)
    private String nombre;       // Nombre legible para UI
    private String modulo;       // Agrupación de menú (Almacén, Producción, etc.)
    private String descripcion;
    private boolean asignado;    // Útil para la vista de matriz rol-permisos

    public Permiso() {}

    public Permiso(int idPermiso, String codigo, String nombre,
                   String modulo, String descripcion) {
        this.idPermiso   = idPermiso;
        this.codigo      = codigo;
        this.nombre      = nombre;
        this.modulo      = modulo;
        this.descripcion = descripcion;
    }

    // ── Getters y Setters ──────────────────────────────────────

    public int    getIdPermiso()           { return idPermiso;   }
    public void   setIdPermiso(int id)     { this.idPermiso = id; }

    public String getCodigo()              { return codigo;      }
    public void   setCodigo(String c)      { this.codigo = c;    }

    public String getNombre()              { return nombre;      }
    public void   setNombre(String n)      { this.nombre = n;    }

    public String getModulo()              { return modulo;      }
    public void   setModulo(String m)      { this.modulo = m;    }

    public String getDescripcion()         { return descripcion; }
    public void   setDescripcion(String d) { this.descripcion = d; }

    public boolean isAsignado()            { return asignado;    }
    public void    setAsignado(boolean a)  { this.asignado = a;  }

    @Override
    public String toString() { return nombre; }
}
