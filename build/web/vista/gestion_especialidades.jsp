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
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Gestión de Especialidades – Sistema Textil</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>

  <style>
    :root {
        --color-primary: #0f3460; --color-primary-hover: #1a5ca8;
        --color-secondary: #1a1a2e; --color-accent: #e2b96f;
        --color-bg: #f4f6f8; --color-surface: #ffffff;
        --text-main: #334155; --text-muted: #64748b; --text-light: #cbd5e1;
        --border-color: #e2e8f0;
        --success-bg: #d1fae5; --success-text: #065f46;
        --danger-bg: #fee2e2; --danger-text: #991b1b; --danger-hover: #dc2626;
        --radius-sm: 6px; --radius-md: 8px; --radius-lg: 12px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; min-height: 100vh; color: var(--text-main); }

    /* Sidebar */
    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 24px 16px; border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .sidebar-logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }

    /* ── SIDEBAR CON MENÚ ACORDEÓN ── */
    .sidebar-nav { display: flex; flex-direction: column; gap: 4px; padding: 16px 12px; }

    .menu-link { display: flex; align-items: center; gap: 10px; padding: 10px 14px; color: var(--text-light); text-decoration: none; font-size: 0.88rem; border-radius: var(--radius-sm); transition: all 0.2s; }
    .menu-link i { font-size: 1.2rem; }
    .menu-link:hover, .menu-link.activo { background: rgba(15, 52, 96, 0.5); color: #fff; }
    .menu-link.activo { position: relative; }
    .menu-link.activo::before { content:''; position: absolute; left: 0; top: 15%; bottom: 15%; width: 4px; background: var(--color-accent); border-radius: 0 4px 4px 0; }

    .menu-group { margin-bottom: 2px; }
    .menu-toggle { display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; cursor: pointer; color: var(--text-muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase; border-radius: var(--radius-sm); transition: all 0.2s; user-select: none; }
    .menu-toggle span { display: flex; align-items: center; gap: 8px; letter-spacing: 0.5px;}
    .menu-toggle span i { font-size: 1.1rem; }
    .menu-toggle:hover { color: var(--text-light); background: rgba(255,255,255,0.05); }
    .menu-toggle .arrow { transition: transform 0.3s ease; font-size: 1.1rem;}

    .menu-group.active .menu-toggle .arrow { transform: rotate(180deg); }
    .menu-group.active .menu-toggle { color: #fff; }

    .menu-content { max-height: 0; overflow: hidden; transition: max-height 0.3s ease-out; display: flex; flex-direction: column; gap: 2px; }
    .menu-group.active .menu-content { max-height: 400px; margin-top: 4px; }
    .menu-content .menu-link { padding-left: 36px; font-size: 0.85rem; }
    /* Main */
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; width: 100%; }
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px; transition:0.2s;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }
    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    /* Alertas */
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 24px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-error { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    /* Toolbar */
    .toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
    .toolbar-title { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .search-wrapper { position: relative; flex: 1; max-width: 450px; }
    .search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper .form-control { padding-left: 2.5rem; }
    .btn { display: inline-flex; align-items: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }

    /* Tabla */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow: hidden; }
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { padding: 12px 16px; text-align: left; background: #f8fafc; color: var(--text-muted); font-weight: 600; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }
    .text-center { text-align: center; color: var(--text-muted); padding: 48px !important; }
    
    .acciones-container { display: flex; gap: 8px; justify-content:flex-start;}
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }

    /* Modal */
    .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; align-items: center; justify-content: center; display: none; backdrop-filter: blur(3px);}
    .modal-overlay.active { display: flex; }
    .modal-content { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 500px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--color-secondary); font-size: 1.1rem; font-weight: 600; display:flex; align-items:center; gap:8px;}
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-light); transition: 0.2s; }
    .close-modal:hover { color: var(--text-main); }
    
    .form-group { margin-bottom: 16px; display:flex; flex-direction:column; gap:6px;}
    .form-group label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    textarea.form-control { resize: vertical; min-height: 80px; }
    .btn-guardar { width: 100%; padding: 0.75rem; background: var(--color-primary); color: #fff; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.9rem; font-weight: 600; transition: 0.2s; display:flex; align-items:center; justify-content:center; gap:6px; margin-top: 24px;}
    .btn-guardar:hover { background: var(--color-primary-hover); }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">
    <div style="display:flex; align-items:center; gap:8px;"><i class='bx bxs-layer'></i> Textil Control</div>
    <span>Sistema de Producción</span>
  </div>
  <nav class="sidebar-nav">
    <%
        @SuppressWarnings("unchecked")
        java.util.Set<String> _ps = (java.util.Set<String>) session.getAttribute("permisosUsuario");
        if (_ps == null) _ps = new java.util.HashSet<>();
        modelo.Usuario _usr = (modelo.Usuario) session.getAttribute("usuarioSesion");
        boolean _isAdmin  = _usr != null && "ADMINISTRADOR".equalsIgnoreCase(_usr.getNombreRol());
        boolean _isMaq    = _usr != null && _usr.getIdRol() == 6;
        boolean _navSeg   = _ps.contains("SEG_USUARIOS_VER");
        boolean _navCatT  = _ps.contains("CAT_TELAS_VER")   || _isAdmin;
        boolean _navCatM  = _ps.contains("CAT_MODELOS_VER") || _isAdmin;
        boolean _navAlm   = _ps.contains("ALM_TELA_VER");
        boolean _navMaq   = _ps.contains("PROD_MAQUINISTAS_VER") || _isAdmin;
        boolean _navOT    = _ps.contains("PROD_OT_VER");
        boolean _navRep   = _ps.contains("PROD_REPOSO_VER")  || _isAdmin;
        boolean _navFall  = _ps.contains("PROD_FALLAS_VER")  || _isAdmin;
        boolean _navMer   = _ps.contains("PROD_MERMA_VER")   || _isAdmin;
        boolean _navCarg  = _ps.contains("PROD_CARGAS_ASIG") || _ps.contains("PROD_CARGAS_VER");
        boolean _navCal   = _ps.contains("CAL_DEFECTOS_REG") || _ps.contains("CAL_DEFECTOS_VER");
        boolean _navDesp  = _ps.contains("DES_CONCIL_REG")   || _ps.contains("DES_CONCIL_VER");
        boolean _navRepo  = _ps.contains("RPT_MERMAS_CALIDAD")   || _ps.contains("RPT_MERMAS_CALIDAD");
        String  _cp       = request.getContextPath();
        String  _uri      = request.getRequestURI();
    %>
    
    <a href="<%= _cp %>/dashboard" class="menu-link"><i class='bx bx-home-alt'></i> Dashboard</a>

    <% if (_navSeg) { %>
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-shield-quarter'></i> Administración</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/gestion-usuarios" class="menu-link">Usuarios</a>
        <a href="<%= _cp %>/gestion-especialidades" class="menu-link activo">Especialidades</a>
      </div>
    </div>
    <% } %>

    <% if (_navCatT || _navCatM) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-folder'></i> Catálogos</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navCatT) { %><a href="<%= _cp %>/catalogo-telas" class="menu-link">Catálogo Telas</a><% } %>
        <% if (_navCatM) { %><a href="<%= _cp %>/catalogo-modelos" class="menu-link">Catálogo Modelos</a><% } %>
      </div>
    </div>
    <% } %>

    <% if (_navAlm || _navMaq) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-store'></i> Almacén</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navAlm) { %><a href="<%= _cp %>/inventario" class="menu-link">Tela Recibida</a><% } %>
        <% if (_navMaq) { %><a href="<%= _cp %>/maquinistas" class="menu-link">Maquinistas</a><% } %>
      </div>
    </div>
    <% } %>

    <% if (_navOT || _navRep || _navFall || _navMer || _navCarg || _isMaq) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-cog'></i> Producción</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navOT)   { %><a href="<%= _cp %>/ordenes-trabajo" class="menu-link">Órdenes de Trabajo</a><% } %>
        <% if (_navRep)  { %><a href="<%= _cp %>/tiempos-reposo" class="menu-link">Tiempos de Reposo</a><% } %>
        <% if (_navFall) { %><a href="<%= _cp %>/fallas-tela" class="menu-link">Mapa de Fallas</a><% } %>
        <% if (_navMer)  { %><a href="<%= _cp %>/mermas" class="menu-link">Mermas</a><% } %>
        <% if (_navCarg) { %><a href="<%= _cp %>/cargas-trabajo" class="menu-link">Cargas de Trabajo</a><% } %>
        <% if (_isMaq && !_navCarg) { %><a href="<%= _cp %>/cargas-trabajo" class="menu-link">Mis Tareas</a><% } %>
      </div>
    </div>
    <% } %>

    <% if (_navCal) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-check-shield'></i> Calidad</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/defectos" class="menu-link">Control de Defectos</a>
      </div>
    </div>
    <% } %>

    <% if (_navDesp) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-package'></i> Despacho</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/despacho" class="menu-link">Conciliación y Despacho</a>
      </div>
    </div>
    <% } %>
    
    <% if (_navRepo) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-bar-chart-square'></i> Reportes</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/reportes" class="menu-link">Analíticas</a>
      </div>
    </div>
    <% } %>
    <% if (_navRepo) { %>
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-data'></i> BackUp</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/backup" class="menu-link">Copias Seguridad</a>
      </div>
    </div>
    <% } %>
  </nav>
</aside>

<main>
  <header>
    <h2><i class='bx bx-purchase-tag-alt'></i> Gestión de Especialidades</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Cerrar sesión</a>
    </div>
  </header>

  <div class="contenido">
    <% if (msgExito != null) { %><div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div><% } %>
    <% if (msgError != null) { %><div class="alerta alerta-error"><i class='bx bx-error-circle'></i> <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div><% } %>
    
    <div class="toolbar">
        <h3 class="toolbar-title">Lista de Especialidades (<%= lista != null ? lista.size() : 0 %>)</h3>
        <div class="search-wrapper">
          <i class='bx bx-search search-icon'></i>
          <input type="text" id="busquedaEspecialidades" class="form-control" placeholder="Buscar por nombre de especialidad...">
        </div>
        <% if (puedeGestionar) { %>
          <button onclick="abrirModalNuevo()" class="btn btn-primary"><i class='bx bx-plus'></i> Nueva Especialidad</button>
        <% } %>
    </div>

    <div class="card">
      <div style="overflow-x:auto;">
        <table>
          <thead>
            <tr><th>#</th><th>Nombre de la Especialidad</th><th>Descripción</th><th>Acciones</th></tr>
          </thead>
          <tbody>
            <% if (lista == null || lista.isEmpty()) { %>
              <tr><td colspan="4" class="text-center"><i class='bx bx-purchase-tag' style="font-size:3rem; display:block; margin-bottom:12px; color:var(--border-color);"></i> No hay especialidades registradas.</td></tr>
            <% } else {
                 int i = 1;
                 for (Especialidad e : lista) { %>
            <tr>
              <td style="color:var(--text-muted);"><%= i++ %></td>
              <td><strong><%= e.getNombre() %></strong></td>
              <td><%= e.getDescripcion() != null ? e.getDescripcion() : "—" %></td>
              <td>
                <% if (puedeGestionar) { %>
                  <div class="acciones-container">
                    <button type="button" class="btn-icon edit" title="Editar Especialidad"
                      onclick="abrirModalEditar(<%= e.getIdEspecialidad() %>, '<%= e.getNombre().replace("'","\\x27") %>', '<%= e.getDescripcion() != null ? e.getDescripcion().replace("'","\\x27") : "" %>')">
                      <i class='bx bx-edit-alt'></i>
                    </button>
                    <form action="<%= request.getContextPath() %>/gestion-especialidades" method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar la especialidad <%= e.getNombre() %>?')">
                      <input type="hidden" name="accion" value="eliminar">
                      <input type="hidden" name="id_especialidad" value="<%= e.getIdEspecialidad() %>">
                      <button type="submit" class="btn-icon delete" title="Eliminar Especialidad"><i class='bx bx-trash'></i></button>
                    </form>
                  </div>
                <% } %>
              </td>
            </tr>
            <% }} %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</main>

<div id="modal-especialidad" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo"><i class='bx bx-purchase-tag-alt'></i> Nueva Especialidad</h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>
    <form action="<%= request.getContextPath() %>/gestion-especialidades" method="POST">
      <input type="hidden" id="modal-accion" name="accion" value="guardar">
      <input type="hidden" id="modal-id" name="id_especialidad" value="">

      <div class="form-group">
        <label>Nombre de Especialidad <span style="color:var(--danger-hover)">*</span></label>
        <input type="text" id="modal-nombre" name="nombre" class="form-control" required maxlength="100" placeholder="Ej: Recta, Remalle...">
      </div>

      <div class="form-group">
        <label>Descripción / Observaciones</label>
        <textarea id="modal-descripcion" name="descripcion" class="form-control" rows="3" maxlength="200" placeholder="Detalles de la especialidad..."></textarea>
      </div>

      <button type="submit" class="btn-guardar"><i class='bx bx-save'></i> Guardar Especialidad</button>
    </form>
  </div>
</div>

<script>
  // LÓGICA JAVASCRIPT INTACTA
  function abrirModalNuevo() {
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-plus-circle'></i> Nueva Especialidad";
    document.getElementById('modal-accion').value = 'guardar';
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-descripcion').value = '';
    document.getElementById('modal-especialidad').classList.add('active');
  }

  function abrirModalEditar(id, nombre, descripcion) {
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-edit'></i> Editar Especialidad";
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-id').value = id;
    document.getElementById('modal-nombre').value = nombre;
    document.getElementById('modal-descripcion').value = descripcion;
    document.getElementById('modal-especialidad').classList.add('active');
  }

  function cerrarModal() {
    document.getElementById('modal-especialidad').classList.remove('active');
  }

  document.getElementById('modal-especialidad').addEventListener('click', function(e) {
    if (e.target === this) cerrarModal();
  });

  <% if (editar != null) { %>
  window.addEventListener('DOMContentLoaded', function() {
    abrirModalEditar(
      <%= editar.getIdEspecialidad() %>,
      '<%= editar.getNombre().replace("'","\\x27") %>',
      '<%= editar.getDescripcion() != null ? editar.getDescripcion().replace("'","\\x27") : "" %>'
    );
  });
  <% } %>

  document.getElementById('busquedaEspecialidades').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('td[colspan]')) return; 
      var nombre = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      if (!filtro || nombre.includes(filtro)) {
        tr.style.display = '';
      } else {
        tr.style.display = 'none';
      }
    });
  });
  // Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>

</body>
</html>