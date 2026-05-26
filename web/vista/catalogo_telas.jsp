<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.CatalogoTela, java.util.List, modelo.Usuario, java.util.Set, java.util.HashSet" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean verSeguridad   = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacen     = permisos.contains("ALM_TELA_VER");
    boolean verProduccion  = permisos.contains("PROD_OT_VER");

    List<CatalogoTela> telas = (List<CatalogoTela>) request.getAttribute("telas");
    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");
    CatalogoTela telaEditar = (CatalogoTela) request.getAttribute("telaEditar");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Catálogo de Telas</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>

  <style>
    /* ── SISTEMA DE DISEÑO IDENTICO AL ANTERIOR ── */
    :root {
        --color-primary: #0f3460; --color-primary-hover: #1a5ca8;
        --color-secondary: #1a1a2e; --color-accent: #e2b96f;
        --color-bg: #f4f6f8; --color-surface: #ffffff;
        --text-main: #334155; --text-muted: #64748b; --text-light: #cbd5e1;
        --border-color: #e2e8f0;
        --success-bg: #d1fae5; --success-text: #065f46;
        --danger-bg: #fee2e2; --danger-text: #991b1b; --danger-hover: #dc2626;
        --warning-bg: #fef3c7; --warning-text: #92400e;
        --radius-sm: 6px; --radius-md: 8px; --radius-lg: 12px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; min-height: 100vh; color: var(--text-main); }
    
    /* LAYOUT */
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

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; width: 100%; }
    
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }

    /* CONTENIDO */
    .toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 24px; flex-wrap: wrap; }
    .toolbar-title { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .toolbar-filters { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; flex: 1; justify-content: center; }
    
    .search-wrapper { position: relative; width: 100%; max-width: 450px; }
    .search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }

    /* TABLA */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin: 0 24px 24px 24px; overflow-x: auto;}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 0.8rem 1.2rem; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 0.8rem 1.2rem; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }

    .chip { display: inline-flex; align-items: center; justify-content: center; width: 115px; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; }
    .activo { background: var(--warning-bg); color: var(--warning-text); }
    .inactivo { background: #f1f5f9; color: var(--text-muted); }

    .btn-accion { display: inline-flex; align-items: center; justify-content: center; gap: 4px; padding: 4px 10px; border-radius: 6px; border: none; font-size: 0.75rem; font-weight: 600; cursor: pointer; transition: all 0.2s; color: #fff;}
    .btn-play { background: var(--color-primary); }
    .btn-play:hover { background: var(--color-primary-hover); }
    .btn-play:disabled { opacity: 0.5; cursor: not-allowed; }

    .acciones-container { display: flex; gap: 8px; }
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }

    /* MODAL */
    .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); display: none; align-items: center; justify-content: center; z-index: 1000; backdrop-filter: blur(3px); }
    .modal-overlay.active { display: flex; }
    .modal-content { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 600px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--color-secondary); font-size: 1.1rem; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .close-modal { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: color 0.2s; }
    .close-modal:hover { color: var(--text-main); }
    
    .field { display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
    .field label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .req { color: var(--danger-hover); }
    .btn-guardar { width: 100%; padding: 0.65rem; background: var(--color-primary); color: #fff; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; margin-top: 16px; transition: background 0.2s;}
    .btn-guardar:hover { background: var(--color-primary-hover); }

    /* ALERTAS TOAST */
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin: 0 24px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-error { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    /* PANEL DE REPOSOS ACTUALIZADO */
    #panel-reposos { position: fixed; bottom: 24px; right: 24px; width: 320px; z-index: 2000; display: flex; flex-direction: column; gap: 12px; }
    .reposo-card { background: var(--color-surface); border-radius: var(--radius-md); padding: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid var(--border-color); border-left: 4px solid var(--color-primary); animation: slideIn .3s ease; position: relative;}
    .reposo-card.terminado { border-left-color: var(--success-text); background: var(--success-bg); }
    .reposo-card.urgente { border-left-color: var(--danger-hover); }
    @keyframes slideIn { from { opacity:0; transform:translateX(20px); } to { opacity:1; transform:translateX(0); } }
    
    .reposo-card h4 { font-size: 0.85rem; color: var(--text-main); margin-bottom: 4px; display:flex; align-items:center; gap:6px;}
    .reposo-card .countdown { font-size: 1.5rem; font-weight: 700; font-variant-numeric: tabular-nums; color: var(--color-secondary); }
    .reposo-card .countdown.urgente { color: var(--danger-hover); }
    .reposo-card .countdown.terminado { color: var(--success-text); }
    .btn-cerrar-card { position: absolute; top: 12px; right: 12px; background: none; border: none; cursor: pointer; color: var(--text-muted); font-size: 1.2rem; transition: color 0.2s;}
    .btn-cerrar-card:hover { color: var(--text-main); }

    /* Alerta modal de fin de reposo */
    #alerta-overlay { position:fixed; inset:0; background:rgba(15, 23, 42,.6); display:none; align-items:center; justify-content:center; z-index:3000; backdrop-filter: blur(3px);}
    #alerta-overlay.active { display:flex; }
    #alerta-box { background:var(--color-surface); border-radius:var(--radius-lg); padding:32px; text-align:center; max-width:400px; width:90%; box-shadow: 0 25px 50px -12px rgba(0,0,0,.25); animation: scaleUp .3s ease; }
    @keyframes scaleUp { from { opacity:0; transform:scale(0.95); } to { opacity:1; transform:scale(1); } }
    #alerta-box .icon { font-size:4rem; margin-bottom:16px; color: var(--success-text);}
    #alerta-box h3 { color:var(--text-main); margin-bottom:8px; font-size: 1.25rem;}
    #alerta-box p { color:var(--text-muted); font-size:0.95rem; margin-bottom:24px; }
    #alerta-box button { padding:10px 24px; background:var(--color-primary); color:#fff; border:none; border-radius:var(--radius-sm); cursor:pointer; font-size:0.95rem; font-weight: 600;}
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
    <div class="menu-group">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-shield-quarter'></i> Administración</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/gestion-usuarios" class="menu-link">Usuarios</a>
        <a href="<%= _cp %>/gestion-especialidades" class="menu-link">Especialidades</a>
      </div>
    </div>
    <% } %>

    <% if (_navCatT || _navCatM) { %>
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-folder'></i> Catálogos</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navCatT) { %><a href="<%= _cp %>/catalogo-telas" class="menu-link activo">Catálogo Telas</a><% } %>
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
  <h2><i class='bx bx-cube'></i> Catálogo de Telas y Materiales</h2>
  <div class="user-info">
    <span><%= usuarioSesion != null ? usuarioSesion.getNombreCompleto() : "Admin" %></span>
    <span class="badge"><%= usuarioSesion != null ? usuarioSesion.getNombreRol() : "Sin Rol" %></span>
    <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
  </div>
</header>
    <br>
    <% if (msgExito != null && !msgExito.isEmpty()) { %>
      <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div>
    <% } %>
    <% if (msgError != null && !msgError.isEmpty()) { %>
      <div class="alerta alerta-error"><i class='bx bx-error-circle'></i> <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div>
    <% } %>

  <div class="toolbar">
    <h3 class="toolbar-title">Listado de Materiales</h3>
    <div class="toolbar-filters">
      <div class="search-wrapper">
        <i class='bx bx-search search-icon'></i>
        <input type="text" id="busquedaTelas" class="form-control" placeholder="Buscar por tejido o proveedor...">
      </div>
    </div>
    <button onclick="abrirModalNuevo()" class="btn btn-primary"><i class='bx bx-plus'></i> Nuevo Material</button>
  </div>

  <div class="card">
    <table>
      <thead>
        <tr><th>#</th><th>Nombre del Tejido</th><th>Composición</th><th>Proveedor Base</th><th style="text-align:center;">Reposo</th><th style="text-align:center;">Tiempo</th><th style="text-align:center;">Acciones</th></tr>
      </thead>
      <tbody>
        <% if (telas != null) { for (int i = 0; i < telas.size(); i++) { CatalogoTela t = telas.get(i); %>
        <tr>
          <td><%= i + 1 %></td>
          <td><strong><%= t.getNombre() %></strong></td>
          <td><%= t.getComposicion() %></td>
          <td><%= t.getProveedorBase() %></td>
          <td style="text-align:center;">
            <span class="chip <%= t.isRequiereReposo() ? "activo" : "inactivo" %>">
              <% if(t.isRequiereReposo()){ %><i class='bx bx-time-five' style="margin-right:4px;"></i> Requiere<% } else { %>Sin Reposo<% } %>
            </span>
          </td>
          <td style="text-align:center;">
            <% if (t.isRequiereReposo() && t.getTiempoReposo() > 0) { %>
              <div style="font-size:0.8rem; color:var(--text-muted); font-weight:600; margin-bottom:4px;"><%= t.getTiempoReposo() %> min</div>
              <button type="button" class="btn-accion btn-play" id="btn-reposo-<%= t.getIdCatalogo() %>" data-reposo-id="<%= t.getIdCatalogo() %>" onclick="iniciarReposo(<%= t.getIdCatalogo() %>, '<%= t.getNombre().replace("'", "\\'") %>', <%= t.getTiempoReposo() %>)">
                <i class='bx bx-play'></i> Iniciar
              </button>
            <% } else { %>
              <span style="color:var(--text-light); font-size:0.85rem;">—</span>
            <% } %>
          </td>
          <td>
            <div class="acciones-container" style="justify-content:center;">
                <button type="button" class="btn-icon edit" onclick="abrirModalEditar( <%= t.getIdCatalogo() %>, '<%= t.getNombre().replace("'", "\\'") %>', '<%= t.getComposicion().replace("'", "\\'") %>', '<%= t.getProveedorBase() != null ? t.getProveedorBase().replace("'", "\\'") : "" %>', <%= t.isRequiereReposo() %>, <%= t.getTiempoReposo() %> )" title="Editar">
                    <i class='bx bx-edit-alt'></i>
                </button>
                <form action="<%= request.getContextPath() %>/catalogo-telas" method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar tela?');">
                  <input type="hidden" name="accion" value="eliminar">
                  <input type="hidden" name="id_catalogo" value="<%= t.getIdCatalogo() %>">
                  <button type="submit" class="btn-icon delete" title="Eliminar"><i class='bx bx-trash'></i></button>
                </form>
            </div>
           </td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>
</main>

<%-- Alerta de fin de reposo --%>
<div id="alerta-overlay">
  <div id="alerta-box">
    <div class="icon"><i class='bx bxs-check-circle'></i></div>
    <h3>¡Reposo Completado!</h3>
    <p id="alerta-msg">La tela ya está lista para el corte.</p>
    <button onclick="cerrarAlerta()">Entendido</button>
  </div>
</div>

<div id="panel-reposos"></div>

<%-- Modal Tela --%>
<div id="modal-tela" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo" style="margin:0;"><i class='bx bx-cube'></i> Registrar Material</h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>
    <form action="<%= request.getContextPath() %>/catalogo-telas" method="POST">
      <input type="hidden" id="modal-id" name="id_catalogo" value="">
      <input type="hidden" id="modal-accion" name="accion" value="">

      <div class="field">
          <label>Nombre <span class="req">*</span></label>
          <input type="text" id="modal-nombre" name="nombre" class="form-control" required>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom: 12px;">
          <div class="field"><label>Composición <span class="req">*</span></label><input type="text" id="modal-composicion" name="composicion" class="form-control" required></div>
          <div class="field"><label>Proveedor</label><input type="text" id="modal-proveedor" name="proveedor" class="form-control"></div>
      </div>

      <div style="background:var(--color-bg); padding:16px; border-radius:var(--radius-md); border:1px solid var(--border-color);">
        <label style="display:flex; gap:10px; align-items:center; cursor:pointer; font-weight:500; font-size:0.85rem;">
          <input type="checkbox" name="reposo" id="chk_reposo" onchange="toggleTiempoReposo()" style="width:16px; height:16px; accent-color:var(--color-primary);">
          Requiere tiempo de reposo antes del corte
        </label>
        
        <div id="div-tiempo-reposo" style="display:none; margin-top:16px; padding-top:16px; border-top:1px solid var(--border-color);">
          <div class="field">
              <label><i class='bx bx-time'></i> Duración del reposo (minutos) <span class="req">*</span></label>
              <div style="display:flex; align-items:center; gap:8px;">
                <input type="number" id="modal-tiempo" name="tiempo_reposo" min="1" max="14400" placeholder="ej: 30" class="form-control" style="width:130px; margin-bottom:0;">
                <span style="font-size:0.8rem; color:var(--text-muted);">(max 240 h)</span>
              </div>
          </div>
          <p style="font-size:0.75rem; color:var(--text-muted); margin-top:6px;"><i class='bx bx-bulb'></i> Podrás iniciar el cronómetro desde la tabla y recibirás una alerta al terminar.</p>
        </div>
      </div>
      <button type="submit" class="btn-guardar"><i class='bx bx-save'></i> Guardar Material</button>
    </form>
  </div>
</div>

<script>
  // TODA LA LÓGICA JAVASCRIPT PERMANECE INTACTA, SOLO SE MODIFICÓ EL HTML QUE IMPRIME EN EL DOM
  function toggleTiempoReposo() {
    const chk = document.getElementById('chk_reposo');
    const div = document.getElementById('div-tiempo-reposo');
    const inp = document.getElementById('modal-tiempo');
    div.style.display = chk.checked ? 'block' : 'none';
    inp.required = chk.checked;
    if (!chk.checked) inp.value = '';
  }

  function abrirModalNuevo() {
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-cube'></i> Registrar Material";
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-accion').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-composicion').value = '';
    document.getElementById('modal-proveedor').value = '';
    document.getElementById('chk_reposo').checked = false;
    document.getElementById('modal-tiempo').value = '';
    document.getElementById('div-tiempo-reposo').style.display = 'none';
    document.getElementById('modal-tiempo').required = false;
    document.getElementById('modal-tela').classList.add('active');
  }

  function abrirModalEditar(id, nombre, composicion, proveedor, reposo, tiempoReposo) {
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-edit'></i> Editar Material";
    document.getElementById('modal-id').value = id;
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-nombre').value = nombre;
    document.getElementById('modal-composicion').value = composicion;
    document.getElementById('modal-proveedor').value = proveedor;
    document.getElementById('chk_reposo').checked = reposo;
    document.getElementById('modal-tiempo').value = tiempoReposo > 0 ? tiempoReposo : '';
    document.getElementById('div-tiempo-reposo').style.display = reposo ? 'block' : 'none';
    document.getElementById('modal-tiempo').required = reposo;
    document.getElementById('modal-tela').classList.add('active');
  }

  function cerrarModal() { document.getElementById('modal-tela').classList.remove('active'); }

  const STORAGE_KEY = 'reposos_activos';
  function cargarReposos() { try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}; } catch(e) { return {}; } }
  function guardarReposos(obj) { localStorage.setItem(STORAGE_KEY, JSON.stringify(obj)); }

  function actualizarBoton(id, activo) {
    const btn = document.getElementById('btn-reposo-' + id);
    if (!btn) return;
    btn.disabled = activo;
    btn.innerHTML = activo ? "<i class='bx bx-loader bx-spin'></i> En Reposo" : "<i class='bx bx-play'></i> Iniciar";
  }

  function iniciarReposo(idCatalogo, nombre, minutos) {
    const reposos = cargarReposos();
    if (reposos[idCatalogo]) return;
    reposos[idCatalogo] = { nombre: nombre, fin: Date.now() + minutos * 60 * 1000, minutos: minutos };
    guardarReposos(reposos);
    actualizarBoton(idCatalogo, true);
    renderPanel();
  }

  function renderPanel() {
    const panel = document.getElementById('panel-reposos');
    const reposos = cargarReposos();
    panel.querySelectorAll('.reposo-card').forEach(card => {
      const id = card.id.replace('rcard-', '');
      if (!reposos[id]) card.remove();
    });
    for (const [id, data] of Object.entries(reposos)) {
      const restMs = data.fin - Date.now();
      const terminado = restMs <= 0;
      const urgente = !terminado && restMs < 5 * 60 * 1000;
      
      if (terminado) {
        const cardVieja = document.getElementById('rcard-' + id);
        if (cardVieja) cardVieja.remove();
        const rep = cargarReposos();
        delete rep[id];
        guardarReposos(rep);
        actualizarBoton(id, false);
        mostrarAlerta(data.nombre);
        continue;
      }

      const totalSeg = Math.ceil(restMs / 1000);
      const h = Math.floor(totalSeg / 3600);
      const m = Math.floor((totalSeg % 3600) / 60);
      const s = totalSeg % 60;
      const tiempoStr = (h > 0 ? h + 'h ' : '') + String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0');
      
      let card = document.getElementById('rcard-' + id);
      if (!card && !data.minimizado) {
        card = document.createElement('div');
        card.id = 'rcard-' + id;
        /* ACTUALIZADO CON ICONOS Y CLASES MODERNAS */
        card.innerHTML =
          '<button class="btn-cerrar-card" title="Ocultar (sigue corriendo)" onclick="minimizarReposo(\'' + id + '\')"><i class="bx bx-x"></i></button>' +
          '<h4><i class="bx bx-cube" style="color:var(--color-primary)"></i> ' + data.nombre + '</h4>' +
          '<div class="countdown" id="cd-' + id + '"></div>' +
          '<div style="font-size:0.75rem; color:var(--text-muted); margin-top:4px;"><i class="bx bx-time-five"></i> Tiempo restante</div>';
        panel.appendChild(card);
      }

      if (data.minimizado) {
        if (card) card.remove();
        actualizarBoton(id, true);
        continue;
      }

      card.className = 'reposo-card' + (urgente ? ' urgente' : '');
      const cd = document.getElementById('cd-' + id);
      if (cd) {
        cd.textContent = tiempoStr;
        cd.className = 'countdown' + (urgente ? ' urgente' : '');
      }
      actualizarBoton(id, true);
    }
  }

  function minimizarReposo(id) {
    const rep = cargarReposos();
    if (!rep[id]) return;
    rep[id].minimizado = true;
    guardarReposos(rep);
    const card = document.getElementById('rcard-' + id);
    if (card) card.remove();
  }

  function mostrarAlerta(nombre) {
    document.getElementById('alerta-msg').innerHTML = '<strong>' + nombre + '</strong> ha completado su tiempo de reposo.';
    document.getElementById('alerta-overlay').classList.add('active');
    if (Notification && Notification.permission === 'granted') {
      new Notification('⏰ Reposo Completado', { body: '"' + nombre + '" está lista para el corte.' });
    }
  }

  function cerrarAlerta() { document.getElementById('alerta-overlay').classList.remove('active'); }

  if (Notification && Notification.permission === 'default') { Notification.requestPermission(); }

  (function init() {
    const reposos = cargarReposos();
    document.querySelectorAll('[data-reposo-id]').forEach(btn => {
      const id = btn.dataset.reposoId;
      if (reposos[id]) actualizarBoton(id, true);
    });
    renderPanel();
    setInterval(renderPanel, 1000);
  })();

  document.getElementById('busquedaTelas').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('td[colspan]')) return;
      var nombre = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      var proveedor = tr.cells[3] ? tr.cells[3].textContent.toLowerCase() : '';
      if (!filtro || nombre.includes(filtro) || proveedor.includes(filtro)) { tr.style.display = ''; } else { tr.style.display = 'none'; }
    });
  });
  // Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>

</body>
</html>