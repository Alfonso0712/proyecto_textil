package modelo;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Entidad: fallas_tela
 * HU02: Mapeo Digital de Imperfecciones y Fallas en la Tela
 *
 * CUS 2.1 Mapear Imperfecciones
 * CUS 2.2 Categorizar Fallas (Mancha / Hueco / Defecto de Tejido)
 * CUS 2.3 Activar Alerta Visual de Áreas No Aptas
 */
public class FallaTela {

    public enum TipoFalla {
        MANCHA, HUECO, DEFECTO_TEJIDO;

        /** Etiqueta legible para la UI */
        public String etiqueta() {
            switch (this) {
                case MANCHA:         return "Mancha";
                case HUECO:          return "Hueco";
                case DEFECTO_TEJIDO: return "Defecto de Tejido";
                default:             return name();
            }
        }
    }

    private int        idFalla;
    private int        idTela;
    private int        idTizador;
    private TipoFalla  tipoFalla;
    private int        posicionRollo;
    private BigDecimal posicionMetro;
    private BigDecimal anchoCm;
    private BigDecimal largoCm;
    private String     descripcion;
    private boolean    esAreaNoApta;
    private Timestamp  fechaRegistro;

    // ── Campos JOIN para vistas ────────────────────────────────
    private String codigoTela;
    private String codigoOt;
    private String tipoTejido;
    private String nombreTizador;

    public FallaTela() {
        this.esAreaNoApta = true;
    }

    // ── Getters / Setters ──────────────────────────────────────

    public int        getIdFalla()              { return idFalla; }
    public void       setIdFalla(int v)         { this.idFalla = v; }

    public int        getIdTela()               { return idTela; }
    public void       setIdTela(int v)          { this.idTela = v; }

    public int        getIdTizador()            { return idTizador; }
    public void       setIdTizador(int v)       { this.idTizador = v; }

    public TipoFalla  getTipoFalla()            { return tipoFalla; }
    public void       setTipoFalla(TipoFalla v) { this.tipoFalla = v; }

    public int        getPosicionRollo()        { return posicionRollo; }
    public void       setPosicionRollo(int v)   { this.posicionRollo = v; }

    public BigDecimal getPosicionMetro()             { return posicionMetro; }
    public void       setPosicionMetro(BigDecimal v) { this.posicionMetro = v; }

    public BigDecimal getAnchoCm()              { return anchoCm; }
    public void       setAnchoCm(BigDecimal v)  { this.anchoCm = v; }

    public BigDecimal getLargoCm()              { return largoCm; }
    public void       setLargoCm(BigDecimal v)  { this.largoCm = v; }

    public String     getDescripcion()          { return descripcion; }
    public void       setDescripcion(String v)  { this.descripcion = v; }

    public boolean    isEsAreaNoApta()           { return esAreaNoApta; }
    public void       setEsAreaNoApta(boolean v) { this.esAreaNoApta = v; }

    public Timestamp  getFechaRegistro()            { return fechaRegistro; }
    public void       setFechaRegistro(Timestamp v) { this.fechaRegistro = v; }

    // JOIN
    public String getCodigoTela()            { return codigoTela; }
    public void   setCodigoTela(String v)    { this.codigoTela = v; }

    public String getCodigoOt()              { return codigoOt; }
    public void   setCodigoOt(String v)      { this.codigoOt = v; }

    public String getTipoTejido()            { return tipoTejido; }
    public void   setTipoTejido(String v)    { this.tipoTejido = v; }

    public String getNombreTizador()         { return nombreTizador; }
    public void   setNombreTizador(String v) { this.nombreTizador = v; }
}
