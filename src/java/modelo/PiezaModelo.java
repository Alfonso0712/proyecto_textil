package modelo;

import java.util.ArrayList;
import java.util.List;

public class PiezaModelo {
    private int idPieza;
    private int idModelo;
    private String nombrePieza;
    private int cantidad;
    
    // Nuevo: lista de IDs de las fases asignadas a esta pieza
    private List<Integer> idFasesAsignadas = new ArrayList<>();

    // Constructores, getters y setters
    public PiezaModelo() {}

    public int getIdPieza() { return idPieza; }
    public void setIdPieza(int idPieza) { this.idPieza = idPieza; }

    public int getIdModelo() { return idModelo; }
    public void setIdModelo(int idModelo) { this.idModelo = idModelo; }

    public String getNombrePieza() { return nombrePieza; }
    public void setNombrePieza(String nombrePieza) { this.nombrePieza = nombrePieza; }

    public int getCantidad() { return cantidad; }
    public void setCantidad(int cantidad) { this.cantidad = cantidad; }

    public List<Integer> getIdFasesAsignadas() { return idFasesAsignadas; }
    public void setIdFasesAsignadas(List<Integer> idFasesAsignadas) { this.idFasesAsignadas = idFasesAsignadas; }
}