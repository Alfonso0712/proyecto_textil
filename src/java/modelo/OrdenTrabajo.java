package modelo;

import java.sql.Timestamp;

/**
 * Entidad: orden_trabajo
 * HU13: Creación de Orden de Trabajo (OT)
 * Diagramas: CUS 13.1 Crear orden de trabajo, CUS 13.3 Generar número único de OT
 */
public class OrdenTrabajo {

    private int       idOt;
    private String    codigoOt;       // Ej: OT-2026-0001 (generado automáticamente)
    private String    cliente;
    private int       cantidadEst;
    private String    estado;         // CREADA, EN_PROCESO, FINALIZADA, ANULADA
    private int       idResponsable;
    private String    nombreResponsable; // Join con usuarios (para vistas)
    private Timestamp fechaCrea;
    private int idModelo;
    private String nombreModelo; // Para vistas

    public OrdenTrabajo() {}

    // ── Getters y Setters ──────────────────────────────────────

    public int getIdOt() { return idOt; }
    public void setIdOt(int idOt) { this.idOt = idOt; }

    public String getCodigoOt() { return codigoOt; }
    public void setCodigoOt(String codigoOt) { this.codigoOt = codigoOt; }

    public String getCliente() { return cliente; }
    public void setCliente(String cliente) { this.cliente = cliente; }

    public int getCantidadEst() { return cantidadEst; }
    public void setCantidadEst(int cantidadEst) { this.cantidadEst = cantidadEst; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public int getIdResponsable() { return idResponsable; }
    public void setIdResponsable(int idResponsable) { this.idResponsable = idResponsable; }

    public String getNombreResponsable() { return nombreResponsable; }
    public void setNombreResponsable(String nombreResponsable) { this.nombreResponsable = nombreResponsable; }

    public Timestamp getFechaCrea() { return fechaCrea; }
    public void setFechaCrea(Timestamp fechaCrea) { this.fechaCrea = fechaCrea; }
    
    // Getters y setters
    public int getIdModelo() { return idModelo; }
    public void setIdModelo(int idModelo) { this.idModelo = idModelo; }
    
    public String getNombreModelo() { return nombreModelo; }
    public void setNombreModelo(String nombreModelo) { this.nombreModelo = nombreModelo; }
}
