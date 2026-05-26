package modelo;

import java.sql.Timestamp;

/**
 * Entidad: fotos_tela
 * Ubicación: modelo/FotoTela.java
 * HU01 – CUS 1.4: Cargar Evidencia Fotográfica
 *
 * Relación: Una tela puede tener muchas fotos (1:N con telas)
 */
public class FotoTela {

    private int       idFoto;
    private int       idTela;
    private String    nombreArchivo;   // Nombre del archivo en disco
    private String    rutaRelativa;    // Ruta relativa para src del <img>
    private Timestamp fechaSubida;

    public FotoTela() {}

    public FotoTela(int idTela, String nombreArchivo, String rutaRelativa) {
        this.idTela        = idTela;
        this.nombreArchivo = nombreArchivo;
        this.rutaRelativa  = rutaRelativa;
    }

    public int       getIdFoto()         { return idFoto; }
    public void      setIdFoto(int v)    { this.idFoto = v; }

    public int       getIdTela()         { return idTela; }
    public void      setIdTela(int v)    { this.idTela = v; }

    public String    getNombreArchivo()  { return nombreArchivo; }
    public void      setNombreArchivo(String v) { this.nombreArchivo = v; }

    public String    getRutaRelativa()   { return rutaRelativa; }
    public void      setRutaRelativa(String v)  { this.rutaRelativa = v; }

    public Timestamp getFechaSubida()    { return fechaSubida; }
    public void      setFechaSubida(Timestamp v){ this.fechaSubida = v; }
}
