package modelo;

import java.sql.Timestamp;

/**
 * Entidad: conciliacion_despacho
 * HU07: Conciliación de Inventario y Despacho Final
 *
 * Diagrama de secuencia HU07:
 *   Encargado Almacén → UI → IngresarConteoFisico → CompararConEstimado
 *                     → DetectarDiferencia → RegistrarMermaInventario
 *                     → GenerarNotaDespacho → ConfirmarDespacho
 *
 * Flujo de estados:
 *   PENDIENTE → CONCILIADO_OK | MERMA_DETECTADA → DESPACHADO
 */
public class ConciliacionDespacho {

    public enum EstadoConciliacion { PENDIENTE, CONCILIADO_OK, MERMA_DETECTADA, DESPACHADO }

    private int                idConciliacion;
    private int                idOt;
    private int                cantidadEstimada;   // del tizado
    private int                cantidadFinal;      // conteo físico real
    private int                diferencia;         // calculado: final - estimado
    private EstadoConciliacion estado;
    private int                idResponsable;      // usuario que realiza la conciliación
    private Timestamp          fechaConciliacion;
    private Timestamp          fechaDespacho;
    private String             observaciones;

    // ── Campos JOIN para vistas ────────────────────────────────
    private String codigoOt;
    private String cliente;
    private String nombreModelo;
    private String nombreResponsable;

    public ConciliacionDespacho() {}

    // ── Getters y Setters ──────────────────────────────────────

    public int getIdConciliacion() { return idConciliacion; }
    public void setIdConciliacion(int v) { this.idConciliacion = v; }

    public int getIdOt() { return idOt; }
    public void setIdOt(int v) { this.idOt = v; }

    public int getCantidadEstimada() { return cantidadEstimada; }
    public void setCantidadEstimada(int v) { this.cantidadEstimada = v; }

    public int getCantidadFinal() { return cantidadFinal; }
    public void setCantidadFinal(int v) { this.cantidadFinal = v; }

    public int getDiferencia() { return diferencia; }
    public void setDiferencia(int v) { this.diferencia = v; }

    public EstadoConciliacion getEstado() { return estado; }
    public void setEstado(EstadoConciliacion v) { this.estado = v; }

    public int getIdResponsable() { return idResponsable; }
    public void setIdResponsable(int v) { this.idResponsable = v; }

    public Timestamp getFechaConciliacion() { return fechaConciliacion; }
    public void setFechaConciliacion(Timestamp v) { this.fechaConciliacion = v; }

    public Timestamp getFechaDespacho() { return fechaDespacho; }
    public void setFechaDespacho(Timestamp v) { this.fechaDespacho = v; }

    public String getObservaciones() { return observaciones; }
    public void setObservaciones(String v) { this.observaciones = v; }

    // JOIN
    public String getCodigoOt() { return codigoOt; }
    public void setCodigoOt(String v) { this.codigoOt = v; }

    public String getCliente() { return cliente; }
    public void setCliente(String v) { this.cliente = v; }

    public String getNombreModelo() { return nombreModelo; }
    public void setNombreModelo(String v) { this.nombreModelo = v; }

    public String getNombreResponsable() { return nombreResponsable; }
    public void setNombreResponsable(String v) { this.nombreResponsable = v; }

    /**
     * Determina el estado de conciliación en base a la diferencia.
     * Usado al crear la conciliación (CUS 7.2 DetectarDiferencia).
     */
    public EstadoConciliacion calcularEstado() {
        if (diferencia == 0) return EstadoConciliacion.CONCILIADO_OK;
        return EstadoConciliacion.MERMA_DETECTADA;
    }

    /** @return true si la diferencia es negativa (menos unidades que estimado) */
    public boolean tieneMerma() {
        return diferencia < 0;
    }
}
