package modelo;

import java.sql.Timestamp;

public class Notificacion {
    private int idNotificacion;
    private String titulo;
    private String mensaje;
    private String tipo;
    private Integer idReferencia;
    private String paraRol;
    private boolean leida;
    private Timestamp fechaCreacion;
    /**
     * @return the idNotificacion
     */
    public int getIdNotificacion() {
        return idNotificacion;
    }

    /**
     * @param idNotificacion the idNotificacion to set
     */
    public void setIdNotificacion(int idNotificacion) {
        this.idNotificacion = idNotificacion;
    }

    /**
     * @return the titulo
     */
    public String getTitulo() {
        return titulo;
    }

    /**
     * @param titulo the titulo to set
     */
    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    /**
     * @return the mensaje
     */
    public String getMensaje() {
        return mensaje;
    }

    /**
     * @param mensaje the mensaje to set
     */
    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    /**
     * @return the tipo
     */
    public String getTipo() {
        return tipo;
    }

    /**
     * @param tipo the tipo to set
     */
    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    /**
     * @return the idReferencia
     */
    public Integer getIdReferencia() {
        return idReferencia;
    }

    /**
     * @param idReferencia the idReferencia to set
     */
    public void setIdReferencia(Integer idReferencia) {
        this.idReferencia = idReferencia;
    }

    /**
     * @return the paraRol
     */
    public String getParaRol() {
        return paraRol;
    }

    /**
     * @param paraRol the paraRol to set
     */
    public void setParaRol(String paraRol) {
        this.paraRol = paraRol;
    }

    /**
     * @return the leida
     */
    public boolean isLeida() {
        return leida;
    }

    /**
     * @param leida the leida to set
     */
    public void setLeida(boolean leida) {
        this.leida = leida;
    }

    /**
     * @return the fechaCreacion
     */
    public Timestamp getFechaCreacion() {
        return fechaCreacion;
    }

    /**
     * @param fechaCreacion the fechaCreacion to set
     */
    public void setFechaCreacion(Timestamp fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }


    // getters y setters (generarlos con IDE o manual)
}