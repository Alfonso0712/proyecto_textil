package modelo;

import java.sql.Timestamp;

/**
 * Entidad: defectos_reproceso
 * HU06: Control de Defectos y Reprocesos
 *
 * Diagrama de secuencia HU06:
 *   Inspector Calidad → UI → RegistrarDefecto → IdentificarMaquinistaResponsable
 *                    → IncrementarContadorReprocesos → ActualizarEstadoPieza
 *                    → NotificarRegistro
 *
 * El contador de reprocesos se refleja en el campo reprocesos_acum de usuarios.
 */
public class DefectoReproceso {

    public enum TipoFalla {
        ERROR_COSTURA("Error de costura"),
        SALTO_PUNTADA("Salto de puntada"),
        MANCHA_SUCIEDAD("Mancha / Suciedad"),
        TENSION_INCORRECTA("Tensión incorrecta"),
        CORTE_IRREGULAR("Corte irregular"),
        ENSAMBLAJE("Ensamblaje"),
        OTRO("Otro");
        

        private final String etiqueta;
        TipoFalla(String etiqueta) { this.etiqueta = etiqueta; }
        public String getEtiqueta() { return etiqueta; }
    }
    public enum Estado { PENDIENTE, REGISTRADO, CORREGIDO }

    private Estado estado;
    private int cantidadFaltante;
    private int idAsignacion;
    private int        idDefecto;
    private int        idOt;
    private Integer        idPieza;          // FK → piezas_modelo (puede ser null)
    private int        idMaquinista;     // responsable del defecto
    private TipoFalla  tipoFalla;
    private String     observaciones;
    private Timestamp  fechaRegistro;

    // ── Campos JOIN para vistas ────────────────────────────────
    private String codigoOt;
    private String nombreModelo;
    private String nombrePieza;
    private String nombreMaquinista;

    public DefectoReproceso() {}
    private int generaReposicion; // 0 = false, 1 = true

// Getters y Setters
public int getGeneraReposicion() { return generaReposicion; }
public void setGeneraReposicion(int generaReposicion) { this.generaReposicion = generaReposicion; }

    // ── Getters y Setters ──────────────────────────────────────

    public int getIdDefecto() { return idDefecto; }
    public void setIdDefecto(int v) { this.idDefecto = v; }

    public int getIdOt() { return idOt; }
    public void setIdOt(int v) { this.idOt = v; }

    // Y asegúrate de que el Getter/Setter también usen Integer
public Integer getIdPieza() { return idPieza; }
public void setIdPieza(Integer idPieza) { this.idPieza = idPieza; }

    public int getIdMaquinista() { return idMaquinista; }
    public void setIdMaquinista(int v) { this.idMaquinista = v; }

    public TipoFalla getTipoFalla() { return tipoFalla; }
    public void setTipoFalla(TipoFalla v) { this.tipoFalla = v; }

    public String getObservaciones() { return observaciones; }
    public void setObservaciones(String v) { this.observaciones = v; }

    public Timestamp getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(Timestamp v) { this.fechaRegistro = v; }

    // JOIN
    public String getCodigoOt() { return codigoOt; }
    public void setCodigoOt(String v) { this.codigoOt = v; }

    public String getNombreModelo() { return nombreModelo; }
    public void setNombreModelo(String v) { this.nombreModelo = v; }

    public String getNombrePieza() { return nombrePieza; }
    public void setNombrePieza(String v) { this.nombrePieza = v; }

    public String getNombreMaquinista() { return nombreMaquinista; }
    public void setNombreMaquinista(String v) { this.nombreMaquinista = v; }
    
    // Getters y Setters
    public Estado getEstado() { return estado; }
    public void setEstado(Estado estado) { this.estado = estado; }

    public int getCantidadFaltante() { return cantidadFaltante; }
    public void setCantidadFaltante(int cantidadFaltante) { this.cantidadFaltante = cantidadFaltante; }

    public int getIdAsignacion() { return idAsignacion; }
    public void setIdAsignacion(int idAsignacion) { this.idAsignacion = idAsignacion; }
    /** Etiqueta de visualización del tipo de falla */
    public String getEtiquetaFalla() {
        return tipoFalla != null ? tipoFalla.getEtiqueta() : "-";
    }
}
