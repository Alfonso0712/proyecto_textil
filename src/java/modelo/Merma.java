package modelo;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Entidad: mermas
 * HU04: Registro de Merma por Tipo de Tejido
 *
 * CUS 4.1 Registrar Merma por Tejido
 * CUS 4.2 Calcular Porcentaje de Merma por Orden de Corte (CA1)
 */
public class Merma {

    public enum Fase { TIZADO, CORTE }

    private int        idMerma;
    private int        idTela;
    private int        idOt;
    private int        idTizador;
    private Fase       fase;
    private BigDecimal pesoUtilizadoKg;
    private BigDecimal pesomermaKg;
    private BigDecimal porcentajeMerma;   // columna STORED en BD
    private String     observaciones;
    private Timestamp  fechaRegistro;

    // ── Campos JOIN para vistas ────────────────────────────────
    private String codigoTela;
    private String tipoTejido;
    private String codigoOt;
    private String cliente;
    private String nombreTizador;

    public Merma() {}

    // ── Getters / Setters ──────────────────────────────────────

    public int        getIdMerma()               { return idMerma; }
    public void       setIdMerma(int v)          { this.idMerma = v; }

    public int        getIdTela()                { return idTela; }
    public void       setIdTela(int v)           { this.idTela = v; }

    public int        getIdOt()                  { return idOt; }
    public void       setIdOt(int v)             { this.idOt = v; }

    public int        getIdTizador()             { return idTizador; }
    public void       setIdTizador(int v)        { this.idTizador = v; }

    public Fase       getFase()                  { return fase; }
    public void       setFase(Fase v)            { this.fase = v; }

    public BigDecimal getPesoUtilizadoKg()            { return pesoUtilizadoKg; }
    public void       setPesoUtilizadoKg(BigDecimal v){ this.pesoUtilizadoKg = v; }

    public BigDecimal getPesomermaKg()            { return pesomermaKg; }
    public void       setPesomermaKg(BigDecimal v){ this.pesomermaKg = v; }

    public BigDecimal getPorcentajeMerma()            { return porcentajeMerma; }
    public void       setPorcentajeMerma(BigDecimal v){ this.porcentajeMerma = v; }

    public String     getObservaciones()         { return observaciones; }
    public void       setObservaciones(String v) { this.observaciones = v; }

    public Timestamp  getFechaRegistro()             { return fechaRegistro; }
    public void       setFechaRegistro(Timestamp v)  { this.fechaRegistro = v; }

    // JOIN
    public String getCodigoTela()            { return codigoTela; }
    public void   setCodigoTela(String v)    { this.codigoTela = v; }

    public String getTipoTejido()            { return tipoTejido; }
    public void   setTipoTejido(String v)    { this.tipoTejido = v; }

    public String getCodigoOt()              { return codigoOt; }
    public void   setCodigoOt(String v)      { this.codigoOt = v; }

    public String getCliente()               { return cliente; }
    public void   setCliente(String v)       { this.cliente = v; }

    public String getNombreTizador()         { return nombreTizador; }
    public void   setNombreTizador(String v) { this.nombreTizador = v; }

    // ── Utilidad ───────────────────────────────────────────────

    /**
     * Clasificación visual del porcentaje de merma:
     *  ≤ 5%   → BAJA  (verde)
     *  ≤ 10%  → MEDIA (amarillo)
     *  > 10%  → ALTA  (rojo)
     */
    public String getNivelMerma() {
        if (porcentajeMerma == null) return "BAJA";
        double pct = porcentajeMerma.doubleValue();
        if (pct <= 5.0)  return "BAJA";
        if (pct <= 10.0) return "MEDIA";
        return "ALTA";
    }
}
