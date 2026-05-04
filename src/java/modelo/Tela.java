package modelo;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Entidad: telas
 * Ubicación: modelo/Tela.java
 * HU01: Registro y Control de Calidad de Tela Recibida
 */
public class Tela {

    public enum Origen         { CLIENTE, TALLER }
    public enum EstadoCalidad  { ACEPTADO, OBSERVADO, RECHAZADO }

    private int          idTela;
    private int          idOt;
    private int          idRegistrador;
    private String       codigoTela;
    private Origen       origen;
    private String       proveedor;
    private BigDecimal   pesoGuia;         // Peso según guía de remisión
    private BigDecimal   pesoReal;         // Peso medido en balanza
    private BigDecimal   diferenciaPeso;   // Calculado: pesoReal - pesoGuia
    private String       tipoTejido;
    private String       color;
    private int          numRollos;
    private String       observaciones;    // Campo obligatorio (CA2 HU01)
    private EstadoCalidad estadoCalidad;
    private boolean      requiereReposo;
    private Timestamp    fechaIngreso;

    // Datos de join (para vistas)
    private String nombreRegistrador;
    private String codigoOt;

    public Tela() {
        this.numRollos    = 1;
        this.estadoCalidad = EstadoCalidad.OBSERVADO;
        this.requiereReposo = false;
    }

    // ── Getters y Setters ──────────────────────────────────────

    public int         getIdTela()           { return idTela; }
    public void        setIdTela(int v)      { this.idTela = v; }

    public int         getIdOt()             { return idOt; }
    public void        setIdOt(int v)        { this.idOt = v; }

    public int         getIdRegistrador()    { return idRegistrador; }
    public void        setIdRegistrador(int v){ this.idRegistrador = v; }

    public String      getCodigoTela()       { return codigoTela; }
    public void        setCodigoTela(String v){ this.codigoTela = v; }

    public Origen      getOrigen()           { return origen; }
    public void        setOrigen(Origen v)   { this.origen = v; }

    public String      getProveedor()        { return proveedor; }
    public void        setProveedor(String v){ this.proveedor = v; }

    public BigDecimal  getPesoGuia()         { return pesoGuia; }
    public void        setPesoGuia(BigDecimal v){ this.pesoGuia = v; }

    public BigDecimal  getPesoReal()         { return pesoReal; }
    public void        setPesoReal(BigDecimal v){ this.pesoReal = v; }

    public BigDecimal  getDiferenciaPeso()   { return diferenciaPeso; }
    public void        setDiferenciaPeso(BigDecimal v){ this.diferenciaPeso = v; }

    public String      getTipoTejido()       { return tipoTejido; }
    public void        setTipoTejido(String v){ this.tipoTejido = v; }

    public String      getColor()            { return color; }
    public void        setColor(String v)    { this.color = v; }

    public int         getNumRollos()        { return numRollos; }
    public void        setNumRollos(int v)   { this.numRollos = v; }

    public String      getObservaciones()    { return observaciones; }
    public void        setObservaciones(String v){ this.observaciones = v; }

    public EstadoCalidad getEstadoCalidad()  { return estadoCalidad; }
    public void        setEstadoCalidad(EstadoCalidad v){ this.estadoCalidad = v; }

    public boolean     isRequiereReposo()    { return requiereReposo; }
    public void        setRequiereReposo(boolean v){ this.requiereReposo = v; }

    public Timestamp   getFechaIngreso()     { return fechaIngreso; }
    public void        setFechaIngreso(Timestamp v){ this.fechaIngreso = v; }

    public String      getNombreRegistrador(){ return nombreRegistrador; }
    public void        setNombreRegistrador(String v){ this.nombreRegistrador = v; }

    public String      getCodigoOt()        { return codigoOt; }
    public void        setCodigoOt(String v){ this.codigoOt = v; }

    /**
     * Indica si la diferencia de peso supera el 1 % → generar alerta (CA1 HU01).
     */
    public boolean hayDiscrepanciaPeso() {
        if (pesoGuia == null || pesoReal == null) return false;
        BigDecimal umbral = pesoGuia.multiply(new BigDecimal("0.01"));
        return diferenciaPeso != null && diferenciaPeso.abs().compareTo(umbral) > 0;
    }
}
