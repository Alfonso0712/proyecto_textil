package modelo;

import java.sql.Timestamp;

/**
 * Entidad: tiempos_reposo
 * Ubicación: modelo/TiempoReposo.java
 * HU03: Gestión de Tiempos de Reposo y Corte
 *
 * Soporta los casos de uso:
 *   CUS 3.1 Gestionar Tiempos de Reposo
 *   CUS 3.2 Registrar Inicio de Reposo
 *   CUS 3.3 Emitir Notificación de Aptitud
 */
public class TiempoReposo {

    public enum Estado { EN_REPOSO, APTO_CORTE, CANCELADO }

    private int       idReposo;
    private int       idTela;
    private int       idUsuarioInicio;
    private Timestamp fechaInicio;
    private int       duracionMinutos;
    private Timestamp fechaFinEstimada;   // columna generada en BD
    private Timestamp fechaFinReal;
    private Estado    estado;
    private boolean   notificacionEnviada;
    private String    observaciones;
    private Timestamp fechaCrea;

    // ── Campos de JOIN para vistas ──
    private String codigoTela;
    private String codigoOt;
    private String tipoTejido;
    private String nombreRegistrador;

    public TiempoReposo() {
        this.duracionMinutos     = 60;
        this.estado              = Estado.EN_REPOSO;
        this.notificacionEnviada = false;
    }

    // ── Getters / Setters ──────────────────────────────────────

    public int       getIdReposo()              { return idReposo; }
    public void      setIdReposo(int v)         { this.idReposo = v; }

    public int       getIdTela()                { return idTela; }
    public void      setIdTela(int v)           { this.idTela = v; }

    public int       getIdUsuarioInicio()       { return idUsuarioInicio; }
    public void      setIdUsuarioInicio(int v)  { this.idUsuarioInicio = v; }

    public Timestamp getFechaInicio()           { return fechaInicio; }
    public void      setFechaInicio(Timestamp v){ this.fechaInicio = v; }

    public int       getDuracionMinutos()       { return duracionMinutos; }
    public void      setDuracionMinutos(int v)  { this.duracionMinutos = v; }

    public Timestamp getFechaFinEstimada()           { return fechaFinEstimada; }
    public void      setFechaFinEstimada(Timestamp v){ this.fechaFinEstimada = v; }

    public Timestamp getFechaFinReal()           { return fechaFinReal; }
    public void      setFechaFinReal(Timestamp v){ this.fechaFinReal = v; }

    public Estado    getEstado()                { return estado; }
    public void      setEstado(Estado v)        { this.estado = v; }

    public boolean   isNotificacionEnviada()          { return notificacionEnviada; }
    public void      setNotificacionEnviada(boolean v){ this.notificacionEnviada = v; }

    public String    getObservaciones()          { return observaciones; }
    public void      setObservaciones(String v)  { this.observaciones = v; }

    public Timestamp getFechaCrea()              { return fechaCrea; }
    public void      setFechaCrea(Timestamp v)   { this.fechaCrea = v; }

    // ── JOIN fields ────────────────────────────────────────────

    public String getCodigoTela()            { return codigoTela; }
    public void   setCodigoTela(String v)    { this.codigoTela = v; }

    public String getCodigoOt()              { return codigoOt; }
    public void   setCodigoOt(String v)      { this.codigoOt = v; }

    public String getTipoTejido()            { return tipoTejido; }
    public void   setTipoTejido(String v)    { this.tipoTejido = v; }

    public String getNombreRegistrador()         { return nombreRegistrador; }
    public void   setNombreRegistrador(String v) { this.nombreRegistrador = v; }

    // ── Utilidades ─────────────────────────────────────────────

    /**
     * Minutos transcurridos desde el inicio del reposo.
     * Retorna 0 si no hay fecha de inicio.
     */
    public long getMinutosTranscurridos() {
        if (fechaInicio == null) return 0;
        long ahora   = System.currentTimeMillis();
        long inicio  = fechaInicio.getTime();
        return Math.max(0, (ahora - inicio) / 60_000);
    }

    /**
     * Minutos restantes para que termine el reposo.
     * Retorna 0 si ya venció o si el estado no es EN_REPOSO.
     */
    public long getMinutosRestantes() {
        if (estado != Estado.EN_REPOSO || fechaInicio == null) return 0;
        long transcurridos = getMinutosTranscurridos();
        return Math.max(0, duracionMinutos - transcurridos);
    }

    /**
     * Porcentaje completado del reposo (0-100).
     */
    public int getPorcentajeCompletado() {
        if (duracionMinutos <= 0) return 100;
        long transcurridos = getMinutosTranscurridos();
        int pct = (int) ((transcurridos * 100) / duracionMinutos);
        return Math.min(100, pct);
    }

    /**
     * Indica si el tiempo de reposo ya venció y la tela está lista para corte.
     */
    public boolean estaListo() {
        return getMinutosRestantes() == 0 && estado == Estado.EN_REPOSO;
    }
}
