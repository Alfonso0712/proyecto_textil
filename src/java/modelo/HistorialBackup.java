package modelo;

import java.sql.Timestamp;

public class HistorialBackup {
    private int idBackup;
    private Timestamp fechaSolicitud;
    private int usuarioSolicitante;
    private String nombreArchivo;
    private long tamanioBytes;
    private String estado;
    private String observaciones;
    private String nombreUsuario; // para JOIN

    // Getters y setters (generarlos con tu IDE)

    /**
     * @return the idBackup
     */
    public int getIdBackup() {
        return idBackup;
    }

    /**
     * @param idBackup the idBackup to set
     */
    public void setIdBackup(int idBackup) {
        this.idBackup = idBackup;
    }

    /**
     * @return the fechaSolicitud
     */
    public Timestamp getFechaSolicitud() {
        return fechaSolicitud;
    }

    /**
     * @param fechaSolicitud the fechaSolicitud to set
     */
    public void setFechaSolicitud(Timestamp fechaSolicitud) {
        this.fechaSolicitud = fechaSolicitud;
    }

    /**
     * @return the usuarioSolicitante
     */
    public int getUsuarioSolicitante() {
        return usuarioSolicitante;
    }

    /**
     * @param usuarioSolicitante the usuarioSolicitante to set
     */
    public void setUsuarioSolicitante(int usuarioSolicitante) {
        this.usuarioSolicitante = usuarioSolicitante;
    }

    /**
     * @return the nombreArchivo
     */
    public String getNombreArchivo() {
        return nombreArchivo;
    }

    /**
     * @param nombreArchivo the nombreArchivo to set
     */
    public void setNombreArchivo(String nombreArchivo) {
        this.nombreArchivo = nombreArchivo;
    }

    /**
     * @return the tamanioBytes
     */
    public long getTamanioBytes() {
        return tamanioBytes;
    }

    /**
     * @param tamanioBytes the tamanioBytes to set
     */
    public void setTamanioBytes(long tamanioBytes) {
        this.tamanioBytes = tamanioBytes;
    }

    /**
     * @return the estado
     */
    public String getEstado() {
        return estado;
    }

    /**
     * @param estado the estado to set
     */
    public void setEstado(String estado) {
        this.estado = estado;
    }

    /**
     * @return the observaciones
     */
    public String getObservaciones() {
        return observaciones;
    }

    /**
     * @param observaciones the observaciones to set
     */
    public void setObservaciones(String observaciones) {
        this.observaciones = observaciones;
    }

    /**
     * @return the nombreUsuario
     */
    public String getNombreUsuario() {
        return nombreUsuario;
    }

    /**
     * @param nombreUsuario the nombreUsuario to set
     */
    public void setNombreUsuario(String nombreUsuario) {
        this.nombreUsuario = nombreUsuario;
    }
    
}