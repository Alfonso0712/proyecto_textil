package modelo;

import java.util.List;

public class MaquinistaDTO {
    private Usuario usuario;
    private List<Especialidad> especialidades;

    public MaquinistaDTO() {}

    public MaquinistaDTO(Usuario usuario, List<Especialidad> especialidades) {
        this.usuario = usuario;
        this.especialidades = especialidades;
    }

    // Getters y Setters
    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public List<Especialidad> getEspecialidades() { return especialidades; }
    public void setEspecialidades(List<Especialidad> especialidades) { this.especialidades = especialidades; }
}