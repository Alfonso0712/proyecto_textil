package modelo;

/**
 * Entidad: catalogo_telas
 * HU10: Catálogo maestro de Telas y Materiales
 */
public class CatalogoTela {
    private int idCatalogo;
    private String nombre;
    private String composicion;
    private String proveedorBase;
    private boolean requiereReposo;
    private int tiempoReposo; // en minutos

    public CatalogoTela() {}

    public CatalogoTela(int idCatalogo, String nombre, String composicion, String proveedorBase, boolean requiereReposo, int tiempoReposo) {
        this.idCatalogo = idCatalogo;
        this.nombre = nombre;
        this.composicion = composicion;
        this.proveedorBase = proveedorBase;
        this.requiereReposo = requiereReposo;
        this.tiempoReposo = tiempoReposo;
    }

    public int getIdCatalogo() { return idCatalogo; }
    public void setIdCatalogo(int idCatalogo) { this.idCatalogo = idCatalogo; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getComposicion() { return composicion; }
    public void setComposicion(String composicion) { this.composicion = composicion; }

    public String getProveedorBase() { return proveedorBase; }
    public void setProveedorBase(String proveedorBase) { this.proveedorBase = proveedorBase; }

    public boolean isRequiereReposo() { return requiereReposo; }
    public void setRequiereReposo(boolean requiereReposo) { this.requiereReposo = requiereReposo; }

    public int getTiempoReposo() { return tiempoReposo; }
    public void setTiempoReposo(int tiempoReposo) { this.tiempoReposo = tiempoReposo; }
}