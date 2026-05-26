package modelo;

public class FaseProduccion {
    private int idFase;
    private String nombre;
    private int orden;
    private String descripcion;

    public FaseProduccion() {}

    // getters y setters
    public int getIdFase() { return idFase; }
    public void setIdFase(int idFase) { this.idFase = idFase; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public int getOrden() { return orden; }
    public void setOrden(int orden) { this.orden = orden; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
}