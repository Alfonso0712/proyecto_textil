package modelo;

import java.sql.Timestamp;

/**
 * Entidad: asignaciones_carga
 * HU05: Distribución de Cargas de Trabajo
 *
 * Diagrama de secuencia HU05:
 *   Supervisor → UI → VerificarFasePrevia → ConsultarMaquinistasDisponibles
 *              → ValidarEspecialidad → AsignarCarga → NotificarAsignacion
 *
 * Regla de negocio: Una fase sólo puede asignarse si la fase inmediatamente
 * anterior de la misma pieza ya tiene estado = 'COMPLETADA'.
 */
public class AsignacionCarga {

    public enum EstadoFase { PENDIENTE, EN_PROCESO, COMPLETADA, BLOQUEADA }

    private int       idAsignacion;
    private int       idOt;
    private int       idPieza;
    private int       idFase;         // FK → fases_produccion
    private int       idMaquinista;
    private EstadoFase estadoFase;
    private Timestamp  fechaAsignacion;
    private Timestamp  fechaCompletado;
    private int cantidadPiezas;  // nuevo
    private int piezasCompletadas;



    // ── Campos JOIN para vistas ────────────────────────────────
    private String codigoOt;
    private String nombreModelo;
    private String nombrePieza;
    private String nombreFase;
    private String fasePreviaEstado; // estado de la fase previa (para bloqueo)
    private String nombreMaquinista;
    private String especialidadMaquinista;
    // En AsignacionCarga.java — agregar campo y getters/setters
    private String tipoTarea = "NORMAL"; // NORMAL, REPOSICION, ENSAMBLAJE
    private Integer idAsignacionPadre = null;

    public String getTipoTarea() { return tipoTarea; }
    public void setTipoTarea(String v) { this.tipoTarea = v; }

    public Integer getIdAsignacionPadre() { return idAsignacionPadre; }
    public void setIdAsignacionPadre(Integer v) { this.idAsignacionPadre = v; }
    public AsignacionCarga() {}

    // ── Getters y Setters ──────────────────────────────────────

    public int getIdAsignacion() { return idAsignacion; }
    public void setIdAsignacion(int v) { this.idAsignacion = v; }

    public int getIdOt() { return idOt; }
    public void setIdOt(int v) { this.idOt = v; }

    public int getIdPieza() { return idPieza; }
    public void setIdPieza(int v) { this.idPieza = v; }

    public int getIdFase() { return idFase; }
    public void setIdFase(int v) { this.idFase = v; }

    public int getIdMaquinista() { return idMaquinista; }
    public void setIdMaquinista(int v) { this.idMaquinista = v; }

    public EstadoFase getEstadoFase() { return estadoFase; }
    public void setEstadoFase(EstadoFase v) { this.estadoFase = v; }

    public Timestamp getFechaAsignacion() { return fechaAsignacion; }
    public void setFechaAsignacion(Timestamp v) { this.fechaAsignacion = v; }

    public Timestamp getFechaCompletado() { return fechaCompletado; }
    public void setFechaCompletado(Timestamp v) { this.fechaCompletado = v; }
    
    public int getCantidadPiezas() { return cantidadPiezas; }
    public void setCantidadPiezas(int v) { this.cantidadPiezas = v; }
    
    public int getPiezasCompletadas() { return piezasCompletadas; }
    public void setPiezasCompletadas(int v) { this.piezasCompletadas = v; }
    // JOIN
    public String getCodigoOt() { return codigoOt; }
    public void setCodigoOt(String v) { this.codigoOt = v; }

    public String getNombreModelo() { return nombreModelo; }
    public void setNombreModelo(String v) { this.nombreModelo = v; }

    public String getNombrePieza() { return nombrePieza; }
    public void setNombrePieza(String v) { this.nombrePieza = v; }

    public String getNombreFase() { return nombreFase; }
    public void setNombreFase(String v) { this.nombreFase = v; }

    public String getFasePreviaEstado() { return fasePreviaEstado; }
    public void setFasePreviaEstado(String v) { this.fasePreviaEstado = v; }

    public String getNombreMaquinista() { return nombreMaquinista; }
    public void setNombreMaquinista(String v) { this.nombreMaquinista = v; }

    public String getEspecialidadMaquinista() { return especialidadMaquinista; }
    public void setEspecialidadMaquinista(String v) { this.especialidadMaquinista = v; }

    /**
     * Verifica si la fase previa está completada (regla de bloqueo HU05).
     * @return true si la asignación puede proceder
     */
    public boolean isFasePreviaCompleta() {
        return fasePreviaEstado == null || "COMPLETADA".equalsIgnoreCase(fasePreviaEstado);
    }
}
