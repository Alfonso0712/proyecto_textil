<%-- /vista/tabla_backups.jsp --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, modelo.HistorialBackup" %>

<%
    List<HistorialBackup> historial = (List<HistorialBackup>) request.getAttribute("historial");
%>

<table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
    <thead>
        <tr style="border-bottom: 2px solid #e2e8f0; text-align: left;">
            <th style="padding: 10px;">Fecha</th>
            <th style="padding: 10px;">Usuario</th>
            <th style="padding: 10px;">Archivo</th>
            <th style="padding: 10px;">Tamaño</th>
            <th style="padding: 10px;">Estado</th>
            <th style="padding: 10px;">Acciones</th>
        </tr>
    </thead>
    <tbody>
        <% if (historial != null && !historial.isEmpty()) { 
            for (HistorialBackup h : historial) { %>
            <tr style="border-bottom: 1px solid #e2e8f0;">
                <td style="padding: 10px;"><%= h.getFechaSolicitud() %></td>
                <td style="padding: 10px;"><%= h.getNombreUsuario() %></td>
                <td style="padding: 10px;"><%= h.getNombreArchivo() %></td>
                <td style="padding: 10px;"><%= (h.getTamanioBytes() / 1024) %> KB</td>
                <td style="padding: 10px;"><span class="<%= h.getEstado().equals("EXITOSO") ? "alerta-ok" : "alerta-err" %>" style="padding: 4px 8px; font-size: 0.75rem;"><%= h.getEstado() %></span></td>
                <td style="padding: 10px;">
                    <% if (h.getEstado().equals("EXITOSO")) { %>
                        <a href="<%= request.getContextPath() %>/backup?accion=descargar&file=<%= h.getNombreArchivo() %>" class="btn-descargar" style="background: #0f3460; color: white; padding: 4px 8px; border-radius: 4px; text-decoration: none; margin-right: 8px;">⬇️ Descargar</a>
                    <% } %>
                    <button onclick="eliminarBackup(<%= h.getIdBackup() %>, '<%= h.getNombreArchivo() %>')" class="btn-eliminar" style="background: #dc2626; color: white; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer;">🗑️ Eliminar</button>
                </td>
            </tr>
        <%  } 
        } else { %>
            <tr><td colspan="6" style="padding: 20px; text-align: center;">No hay registros de backups.</td></tr>
        <% } %>
    </tbody>
</table>

<script>
function eliminarBackup(idBackup, nombreArchivo) {
    if (confirm('¿Eliminar permanentemente el backup "' + nombreArchivo + '"?')) {
        fetch('<%= request.getContextPath() %>/backup?accion=eliminar&id=' + idBackup + '&file=' + encodeURIComponent(nombreArchivo), { method: 'POST' })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Recargar la tabla de historial
                    fetch('<%= request.getContextPath() %>/backup?accion=listar')
                        .then(res => res.text())
                        .then(html => {
                            document.getElementById('historial-container').innerHTML = html;
                        });
                    // Mostrar mensaje temporal (opcional)
                    const msgDiv = document.getElementById('mensaje-area');
                    if (msgDiv) msgDiv.innerHTML = '<div class="alerta-ok">✅ Backup eliminado correctamente.</div>';
                    setTimeout(() => { if (msgDiv) msgDiv.innerHTML = ''; }, 3000);
                } else {
                    alert('Error: ' + data.error);
                }
            })
            .catch(err => alert('Error al eliminar: ' + err));
    }
}
</script>