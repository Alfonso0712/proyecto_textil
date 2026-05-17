package modelo;

import java.util.ArrayList;
import java.util.List;

/**
 * Entidad: modelos_prenda
 * HU12: Catálogo de Modelos (Corsets)
 */
public class ModeloPrenda {
    private int idModelo;
    private String nombre;
    private String temporada;

    // Lista de piezas asociadas y un contador para vistas
    private List<PiezaModelo> piezas = new ArrayList<>();
    private int totalPiezas;

    public ModeloPrenda() {}

    public int getIdModelo() { return idModelo; }
    public void setIdModelo(int idModelo) { this.idModelo = idModelo; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getTemporada() { return temporada; }
    public void setTemporada(String temporada) { this.temporada = temporada; }

    public List<PiezaModelo> getPiezas() { return piezas; }
    public void setPiezas(List<PiezaModelo> piezas) { this.piezas = piezas; }

    public int getTotalPiezas() { return totalPiezas; }
    public void setTotalPiezas(int totalPiezas) { this.totalPiezas = totalPiezas; }
}