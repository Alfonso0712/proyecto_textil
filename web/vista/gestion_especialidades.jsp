<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();
    boolean puedeVer       = permisos.contains("ESPECIALIDADES_VER");
    boolean puedeGestionar = permisos.contains("ESPECIALIDADES_GESTION");
    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    List<Especialidad> lista = (List<Especialidad>) request.getAttribute("especialidades");
    Especialidad editar = (Especialidad) request.getAttribute("especialidadEditar");

    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Especialidades</title>
  <style>
    :root { --primary-dark: #0f3460; --accent: #e2b96f; --bg-light: #f0f2f5; }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: var(--bg-light); display: flex; min-height: 100vh; }

    /* Sidebar */
    aside { width: 240px; background: #1a1a2e; color: #ccc; display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 1.5rem 1.2rem; border-bottom: 1px solid #2d2d50; color: var(--accent); font-weight: 700; font-size: 1rem; }
    .sidebar-logo span { display: block; font-size: .7rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .65rem; padding: .7rem 1.3rem; color: #bbb; text-decoration: none; font-size: .88rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: var(--primary-dark); color: #fff; }
    nav .separador { padding: .4rem 1.3rem; font-size: .7rem; color: #555; text-transform: uppercase; margin-top: .6rem; }

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c; border-radius: 6px; background: transparent; text-decoration: none; font-size: .78rem; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }

    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }

    /* Alertas */
    .alerta { padding: .75rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .85rem; }
    .alerta-ok    { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }

    /* Tabla */
    .btn-nuevo { padding: .45rem 1.1rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .85rem; margin-left: auto; }
    .card { background: #fff; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; padding: .75rem 1rem; text-align: left; border-bottom: 2px solid #eee; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; }
    .btn-accion { display: inline-flex; align-items: center; justify-content: center; min-width: 80px; padding: 0 10px; height: 30px; border: none; border-radius: 6px; cursor: pointer; font-size: .75rem; font-weight: 600; color: #fff; }
    .btn-editar   { background: #ffc107; color: #1a1a2e; }
    .btn-eliminar { background: #ef4444; min-width: 30px; }

    /* Modal */
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 1000; }
    .modal-overlay.active { display: flex; }
    .modal-content { background: #fff; border-radius: 12px; width: 90%; max-width: 480px; padding: 1.8rem; }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; border-bottom: 2px solid #f0f0f0; padding-bottom: .8rem; }
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; }
    .modal-content label { display: block; font-size: .8rem; font-weight: 600; color: #555; margin-bottom: .3rem; }
    .modal-content input[type="text"], .modal-content textarea { width: 100%; padding: .55rem .8rem; border: 1.5px solid #d1d5db; border-radius: 8px; margin-bottom: 1rem; resize: vertical; }
    .btn-guardar { width: 100%; padding: .65rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .9rem; font-weight: 600; }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
      <div class="separador">Principal</div>
      <a href="<%= request.getContextPath() %>/dashboard">🏠 Dashboard</a>
      <% if (permisos.contains("ESPECIALIDADES_VER")) { %>
        <div class="separador">Catálogos</div>
        <a href="<%= request.getContextPath() %>/gestion-especialidades" class="activo">🏷️ Especialidades</a>
      <% } %>
      
  </nav>
</aside>

<main>
  <header>
    <h2>🏷️ Gestión de Especialidades</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
    </div>
  </header>

  <div class="contenido">
    <% if (msgExito != null) { %><div class="alerta alerta-ok">✅ <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div><% } %>
    <% if (msgError != null) { %><div class="alerta alerta-error">❌ <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div><% } %>
    
    <div style="display:flex; align-items:center; gap:1rem; margin-bottom:1.2rem; flex-wrap: wrap;">
        <h3 style="margin:0; white-space: nowrap;">Lista de Especialidades (<%= lista != null ? lista.size() : 0 %>)</h3>
        <div style="flex: 1; display: flex; justify-content: center;">
          <div style="position: relative; width: 100%; max-width: 450px;">
            <input type="text" id="busquedaEspecialidades"
                   placeholder="Buscar por nombre..."
                   style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                          border: 1.5px solid #ddd; border-radius: 8px;
                          font-size: .85rem; outline: none;">
            <span style="position: absolute; left: .6rem; top: 50%; transform: translateY(-50%);
                         color: #aaa; font-size: .9rem;">🔍</span>
          </div>
        </div>
        <% if (puedeGestionar) { %>
          <button onclick="abrirModalNuevo()" class="btn-nuevo">➕ Nueva Especialidad</button>
        <% } %>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr><th>#</th><th>Nombre</th><th>Descripción</th><th>Acciones</th></tr>
        </thead>
        <tbody>
          <% if (lista == null || lista.isEmpty()) { %>
            <tr><td colspan="4" style="text-align:center;color:#aaa;">No hay especialidades registradas.</td></tr>
          <% } else {
               int i = 1;
               for (Especialidad e : lista) { %>
          <tr>
            <td><%= i++ %></td>
            <td><strong><%= e.getNombre() %></strong></td>
            <td><%= e.getDescripcion() != null ? e.getDescripcion() : "—" %></td>
            <td>
              <% if (puedeGestionar) { %>
                <button type="button" class="btn-accion btn-editar"
                  onclick="abrirModalEditar(<%= e.getIdEspecialidad() %>, '<%= e.getNombre().replace("'","\\x27") %>', '<%= e.getDescripcion() != null ? e.getDescripcion().replace("'","\\x27") : "" %>')">
                  ✏️ Editar
                </button>
                <form action="<%= request.getContextPath() %>/gestion-especialidades" method="POST"
                      style="display:inline;" onsubmit="return confirm('¿Eliminar la especialidad <%= e.getNombre() %>?')">
                  <input type="hidden" name="accion" value="eliminar">
                  <input type="hidden" name="id_especialidad" value="<%= e.getIdEspecialidad() %>">
                  <button type="submit" class="btn-accion btn-eliminar" title="Eliminar">🗑 Eliminar️</button>
                </form>
              <% } %>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>
  </div>
</main>

<!-- Modal -->
<div id="modal-especialidad" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo">➕ Nueva Especialidad</h3>
      <button class="close-modal" onclick="cerrarModal()">&times;</button>
    </div>
    <form action="<%= request.getContextPath() %>/gestion-especialidades" method="POST">
      <input type="hidden" id="modal-accion" name="accion" value="guardar">
      <input type="hidden" id="modal-id" name="id_especialidad" value="">

      <label>Nombre <span style="color:red">*</span></label>
      <input type="text" id="modal-nombre" name="nombre" required maxlength="100">

      <label>Descripción</label>
      <textarea id="modal-descripcion" name="descripcion" rows="3" maxlength="200"></textarea>

      <button type="submit" class="btn-guardar">💾 Guardar</button>
    </form>
  </div>
</div>

<script>
  // Abrir modal en modo nuevo
  function abrirModalNuevo() {
    document.getElementById('modal-titulo').textContent = '➕ Nueva Especialidad';
    document.getElementById('modal-accion').value = 'guardar';
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-descripcion').value = '';
    document.getElementById('modal-especialidad').classList.add('active');
  }

  // Abrir modal en modo edición
  function abrirModalEditar(id, nombre, descripcion) {
    document.getElementById('modal-titulo').textContent = '✏️ Editar Especialidad';
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-id').value = id;
    document.getElementById('modal-nombre').value = nombre;
    document.getElementById('modal-descripcion').value = descripcion;
    document.getElementById('modal-especialidad').classList.add('active');
  }

  function cerrarModal() {
    document.getElementById('modal-especialidad').classList.remove('active');
  }

  // Cerrar modal al hacer clic fuera
  document.getElementById('modal-especialidad').addEventListener('click', function(e) {
    if (e.target === this) cerrarModal();
  });

  // Si el servidor envió especialidadEditar, abrir el modal en edición
  <% if (editar != null) { %>
  window.addEventListener('DOMContentLoaded', function() {
    abrirModalEditar(
      <%= editar.getIdEspecialidad() %>,
      '<%= editar.getNombre().replace("'","\\x27") %>',
      '<%= editar.getDescripcion() != null ? editar.getDescripcion().replace("'","\\x27") : "" %>'
    );
  });
  <% } %>
    // Filtro de búsqueda en tiempo real para especialidades
  document.getElementById('busquedaEspecialidades').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('td[colspan]')) return; // saltar fila "sin datos"
      var nombre = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      if (!filtro || nombre.includes(filtro)) {
        tr.style.display = '';
      } else {
        tr.style.display = 'none';
      }
    });
  });
</script>

</body>
</html>