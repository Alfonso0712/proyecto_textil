<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    if (!permisos.contains("DES_CONCIL_REG")) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return;
    }

    List<ConciliacionDespacho> lotes = (List<ConciliacionDespacho>) request.getAttribute("lotes");
    if (lotes == null) lotes = new ArrayList<>();
    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");
    String errorBD      = (String) request.getAttribute("errorBD");
    boolean esAdmin = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Conciliación y Despacho (HU07) – Sistema Textil</title>
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
        --warning-bg: #fef3c7; --warning-text: #92400e;
        --info-bg: #e0f2fe; --info-text: #0369a1;
        --radius-sm: 6px; --radius-md: 8px; --radius-lg: 12px;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; min-height: 100vh; color: var(--text-main); }

    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; }
    .logo { padding: 24px 16px; border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }
    
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

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px; transition:0.2s;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }
    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 16px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-err { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    .section-title { margin-bottom: 16px; }
    .section-title h3 { color: var(--color-secondary); font-size: 1.15rem; font-weight: 600; margin-bottom: 4px; }
    .section-title p { font-size: 0.85rem; color: var(--text-muted); }
    
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-end; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,.04);}
    .filtro-wrap > div { display: flex; flex-direction: column; gap: 6px; }
    .filtro-wrap label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); display:flex; align-items:center; gap:4px;}
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); transition: all 0.2s; outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); padding: 0.55rem 1rem; border-radius: var(--radius-sm); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: 0.2s; display:flex; align-items:center; gap:4px;}
    .btn-outline:hover { background: var(--color-bg); }

    .card { background: var(--color-surface); border-radius: var(--radius-md); border: 1px solid var(--border-color); overflow-x: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.04);}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); vertical-align: middle; color:var(--text-main);}
    tr:hover td { background: #f8fafc; }
    .sin-datos { text-align: center; padding: 48px; color: var(--text-muted); }
    .sin-datos .ico { font-size: 3rem; display: block; margin-bottom: 12px; color:var(--text-light); }

    /* ── CHIPS ── */
    .chip { display: inline-flex; align-items: center; justify-content: center; gap:4px; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; min-width: 130px; text-align: center; }
    .chip-pendiente    { background: #f1f5f9; color: var(--text-muted); }
    .chip-ok           { background: var(--success-bg); color: var(--success-text); }
    .chip-merma        { background: var(--danger-bg); color: var(--danger-text); }
    .chip-despachado   { background: var(--info-bg); color: var(--info-text); }
    .chip-estimado     { background: var(--info-bg); color: var(--info-text); }

    .dif-cero    { color: var(--success-text); font-weight: 700; }
    .dif-merma   { color: var(--danger-hover); font-weight: 700; }
    .dif-ganancia { color: var(--info-text); font-weight: 700; }

    /* ── BOTONES ACCIÓN ── */
    .btn-accion { display: inline-flex; align-items: center; justify-content: center; gap: 4px; padding: 6px 12px; border: none; border-radius: 6px; cursor: pointer; font-size: 0.8rem; font-weight: 600; color: #fff; min-width: 120px; text-decoration: none; transition: .2s; }
    .btn-conciliar  { background: #d97706; }
    .btn-conciliar:hover { background: #b45309; }
    .btn-despachar  { background: var(--color-primary); }
    .btn-despachar:hover { background: var(--color-primary-hover); }

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15,23,42,.5); z-index: 1000; justify-content: center; align-items: center; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 520px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--color-secondary); font-size: 1.1rem; font-weight: 600; display:flex; align-items:center; gap:8px;}
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-light); transition: .2s; }
    .close-modal:hover { color: var(--text-main); }
    
    .estimado-panel { background: var(--color-secondary); color: #fff; border-radius: var(--radius-sm); padding: 16px 24px; text-align: center; margin-bottom: 24px; }
    .estimado-panel .lbl { font-size: 0.8rem; color: var(--text-light); text-transform: uppercase; margin-bottom: 8px; font-weight:600; letter-spacing:0.5px;}
    .estimado-panel .num { font-size: 2.5rem; font-weight: 800; color: var(--color-accent); line-height:1;}
    
    label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); display: block; margin-bottom: 6px; }
    textarea { width: 100%; padding: 0.6rem 0.8rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); margin-bottom: 16px; font-family: inherit; font-size: 0.85rem; transition: border-color .2s; resize: vertical; min-height: 70px; }
    textarea:focus { outline: none; border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    
    .alerta-diferencia { background: var(--warning-bg); color: #92400e; border-left: 4px solid var(--warning-text); padding: 12px 16px; border-radius: 6px; font-size: 0.85rem; margin-bottom: 16px; display: none; text-align: center; }
    .btn-guardar { width: 100%; padding: 0.75rem; color: #fff; background: var(--color-primary); border: none; border-radius: var(--radius-sm); cursor: pointer; font-weight: 600; font-size: 0.9rem; transition: .2s; display:flex; align-items:center; justify-content:center; gap:6px;}
    .btn-guardar:hover { background: var(--color-primary-hover); }
  </style>
</head>
<body>

<aside>
  <div class="logo">
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-package'></i> Despacho</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/despacho" class="menu-link activo">Conciliación y Despacho</a>
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
    <h2><i class='bx bx-truck'></i> Conciliación y Despacho Final</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Cerrar sesión</a>
    </div>
  </header>

  <div class="contenido">

    <% if (mensajeExito != null && !mensajeExito.isEmpty()) { %>
      <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= mensajeExito %></div>
    <% } %>
    <% if (mensajeError != null && !mensajeError.isEmpty()) { %>
      <div class="alerta alerta-err"><i class='bx bx-error-circle'></i> <%= mensajeError %></div>
    <% } %>
    <% if (errorBD != null) { %>
      <div class="alerta alerta-err"><i class='bx bx-error'></i> <%= errorBD %></div>
    <% } %>

    <div class="section-title">
      <h3>Lotes Terminados Listos para Conciliación y Despacho</h3>
      <p>Valide el conteo físico final contra el estimado de tizado para detectar diferencias de inventario.</p>
    </div>
    
<div class="filtro-wrap">
  <div>
    <label><i class='bx bx-search'></i> Código OT</label>
    <input type="text" id="filtroOt" class="form-control" placeholder="Ej: OT-2026-001" style="width: 160px;">
  </div>
  <div>
    <label><i class='bx bx-buildings'></i> Cliente</label>
    <input type="text" id="filtroCliente" class="form-control" placeholder="Nombre cliente" style="width: 180px;">
  </div>
  <div>
    <label><i class='bx bx-filter'></i> Estado</label>
    <select id="filtroEstado" class="form-control" style="width: 150px;">
      <option value="">-- Todos --</option>
    </select>
  </div>
  <div>
    <label><i class='bx bx-closet'></i> Modelo</label>
    <select id="filtroModelo" class="form-control" style="width: 180px;">
      <option value="">-- Todos --</option>
    </select>
  </div>
  <div>
    <button id="btnLimpiarFiltros" class="btn-outline"><i class='bx bx-eraser'></i> Limpiar filtros</button>
  </div>
</div>
    <div class="card">
      <% if (lotes.isEmpty()) { %>
        <div class="sin-datos">
          <i class='bx bx-truck ico'></i>
          No hay lotes FINALIZADOS pendientes de conciliación o despacho.
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>OT #</th><th>Cliente</th><th>Modelo</th><th style="text-align:center;">Estimado</th><th style="text-align:center;">Conteo Final</th><th style="text-align:center;">Diferencia</th><th style="text-align:center;">Estado</th><th style="text-align:center;">Acciones</th>
          </tr>
        </thead>
        <tbody id="tbodyDespacho">
          <% for (ConciliacionDespacho c : lotes) {
               String estadoNombre = c.getEstado() != null ? c.getEstado().name() : "PENDIENTE";
          %>
          <tr data-ot="<%= c.getCodigoOt() %>" data-cliente="<%= c.getCliente() %>" data-modelo="<%= c.getNombreModelo() != null ? c.getNombreModelo() : "-" %>" data-estado="<%= estadoNombre %>">
            <td><strong><%= c.getCodigoOt() %></strong></td>
            <td><%= c.getCliente() %></td>
            <td><%= c.getNombreModelo() != null ? c.getNombreModelo() : "-" %></td>
            <td style="text-align:center;"><span class="chip chip-estimado"><%= c.getCantidadEstimada() %> unds</span></td>
            <td style="text-align:center;">
              <% if ("PENDIENTE".equals(estadoNombre)) { %>
                <span style="color:var(--text-light); font-style: italic;">—</span>
              <% } else if (c.getCantidadFinal() < c.getCantidadEstimada()) { %>
                <strong style="color:var(--danger-hover);"><%= c.getCantidadFinal() %> unds</strong>
              <% } else { %>
                <strong><%= c.getCantidadFinal() %> unds</strong>
              <% } %>
            </td>
            <td style="text-align:center;">
              <% if ("PENDIENTE".equals(estadoNombre)) { %>
                <span style="color:var(--text-light);">—</span>
              <% } else if (c.getDiferencia() == 0) { %>
                <span class="dif-cero">0</span>
              <% } else if (c.getDiferencia() < 0) { %>
                <span class="dif-merma"><%= c.getDiferencia() %></span>
              <% } else { %>
                <span class="dif-ganancia">+<%= c.getDiferencia() %></span>
              <% } %>
            </td>
            <td style="text-align:center;">
              <% if ("PENDIENTE".equals(estadoNombre)) { %>
                <span class="chip chip-pendiente"><i class='bx bx-time-five'></i> Pendiente</span>
              <% } else if ("CONCILIADO_OK".equals(estadoNombre)) { %>
                <span class="chip chip-ok"><i class='bx bx-check'></i> Conciliado OK</span>
              <% } else if ("MERMA_DETECTADA".equals(estadoNombre)) { %>
                <span class="chip chip-merma"><i class='bx bx-error'></i> Merma Detectada</span>
              <% } else if ("DESPACHADO".equals(estadoNombre)) { %>
                <span class="chip chip-despachado"><i class='bx bx-check-double'></i> Despachado</span>
              <% } %>
            </td>
            <td style="text-align:center;">
              <% if ("PENDIENTE".equals(estadoNombre)) { %>
                <button class="btn-accion btn-conciliar" onclick="abrirConciliacion(<%= c.getIdOt() %>, <%= c.getCantidadEstimada() %>, '<%= c.getCodigoOt() %>', <%= c.getCantidadFinal() %>)"><i class='bx bx-check-square'></i> Conciliar</button>
              <% } else if ("CONCILIADO_OK".equals(estadoNombre) || "MERMA_DETECTADA".equals(estadoNombre)) { %>
                <form method="post" action="<%= request.getContextPath() %>/despacho" style="display:inline;" onsubmit="return confirm('¿Confirmar el despacho de <%= c.getCodigoOt() %>?')">
                  <input type="hidden" name="accion" value="despachar">
                  <input type="hidden" name="idConciliacion" value="<%= c.getIdConciliacion() %>">
                  <button type="submit" class="btn-accion btn-despachar"><i class='bx bx-printer'></i> Despachar</button>
                </form>
              <% } else { %>
                <a href="<%= request.getContextPath() %>/despacho?accion=nota&idOt=<%= c.getIdOt() %>" class="btn-accion btn-despachar" style="background:var(--color-secondary);"><i class='bx bx-file'></i> Nota</a>
              <% } %>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>
  </div>
</main>

<div class="overlay" id="overlayConciliacion">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-check-square'></i> Conciliación de Conteo – <span id="lbl-ot-modal"></span></h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>

    <div class="estimado-panel">
      <div class="lbl">Estimado de Tizado</div>
      <div class="num" id="lbl-estimado">0</div>
    </div>

    <form method="post" action="<%= request.getContextPath() %>/despacho" onsubmit="return validarConciliacion()">
      <input type="hidden" name="accion" value="conciliar">
      <input type="hidden" name="idOt" id="hdn-idOt">
      <input type="hidden" name="cantidadEstimada" id="hdn-estimado">

      <label style="text-align: center; font-size: 0.95rem; margin-bottom: 8px;">Conteo Físico Real <span class="req">*</span></label>
      <input type="number" name="cantidadFinal" id="conteo-final" required min="0" placeholder="Ingrese el conteo de almacén..." oninput="calcularDiferencia()" class="form-control" style="font-size: 1.4rem; text-align: center; font-weight: bold; height: 56px; margin-bottom:16px;">

      <div class="alerta-diferencia" id="alertaDiferencia">
        <strong style="display:block; margin-bottom:4px;"><i class='bx bx-error'></i> Diferencia detectada</strong>
        <span id="lbl-diferencia" style="font-weight: 800; font-size: 1.1rem;"></span> unidades.<br>Esta merma se registrará en auditoría.
      </div>

      <label>Observaciones</label>
      <textarea name="observaciones" placeholder="Notas sobre el conteo físico..."></textarea>

      <button type="submit" class="btn-guardar"><i class='bx bx-down-arrow-circle'></i> Validar y Generar Nota</button>
    </form>
  </div>
</div>

<script>
// JS INTACTO
  var estimadoGlobal = 0;
  function abrirConciliacion(idOt, estimado, codigoOt, cantidadEnsamblada) {
    estimadoGlobal = estimado;
    document.getElementById('hdn-idOt').value    = idOt;
    document.getElementById('hdn-estimado').value = estimado;
    document.getElementById('lbl-estimado').textContent = estimado;
    document.getElementById('lbl-ot-modal').textContent = codigoOt;
    var inputConteo = document.getElementById('conteo-final');
    inputConteo.value = (cantidadEnsamblada > 0) ? cantidadEnsamblada : '';
    document.getElementById('alertaDiferencia').style.display = 'none';
    document.getElementById('overlayConciliacion').classList.add('activo');
    calcularDiferencia();
    setTimeout(function() { inputConteo.focus(); }, 100);
  }
  function cerrarModal() { document.getElementById('overlayConciliacion').classList.remove('activo'); }
  document.getElementById('overlayConciliacion').addEventListener('click', function(e) { if (e.target === this) cerrarModal(); });
  
  function calcularDiferencia() {
    var finalStr = document.getElementById('conteo-final').value;
    var alerta   = document.getElementById('alertaDiferencia');
    if (!finalStr) { alerta.style.display = 'none'; return; }
    var dif = parseInt(finalStr) - estimadoGlobal;
    if (dif !== 0) { document.getElementById('lbl-diferencia').textContent = Math.abs(dif); alerta.style.display = 'block'; } 
    else { alerta.style.display = 'none'; }
  }

  function validarConciliacion() {
    var val = document.getElementById('conteo-final').value;
    if (!val || parseInt(val) < 0) { alert('Por favor ingrese un conteo físico válido (≥ 0).'); return false; }
    return true;
  }

function poblarFiltros() {
    const estadosSet = new Set();
    const modelosSet = new Set();
    document.querySelectorAll('#tbodyDespacho tr').forEach(row => {
        const estado = row.getAttribute('data-estado'); if (estado) estadosSet.add(estado);
        const modelo = row.getAttribute('data-modelo'); if (modelo) modelosSet.add(modelo);
    });
    const selectEstado = document.getElementById('filtroEstado');
    selectEstado.innerHTML = '<option value="">-- Todos --</option>';
    Array.from(estadosSet).sort().forEach(est => {
        let texto = est;
        if (est === 'PENDIENTE') texto = 'Pendiente'; else if (est === 'CONCILIADO_OK') texto = 'Conciliado OK'; else if (est === 'MERMA_DETECTADA') texto = 'Merma Detectada'; else if (est === 'DESPACHADO') texto = 'Despachado';
        const opt = document.createElement('option'); opt.value = est; opt.textContent = texto; selectEstado.appendChild(opt);
    });
    const selectModelo = document.getElementById('filtroModelo');
    selectModelo.innerHTML = '<option value="">-- Todos --</option>';
    Array.from(modelosSet).sort().forEach(mod => { const opt = document.createElement('option'); opt.value = mod; opt.textContent = mod; selectModelo.appendChild(opt); });
}

function aplicarFiltros() {
    const filtroOt = document.getElementById('filtroOt').value.trim().toLowerCase();
    const filtroCliente = document.getElementById('filtroCliente').value.trim().toLowerCase();
    const filtroEstado = document.getElementById('filtroEstado').value;
    const filtroModelo = document.getElementById('filtroModelo').value;
    const rows = document.querySelectorAll('#tbodyDespacho tr');
    let visibleCount = 0;
    rows.forEach(row => {
        const ot = row.getAttribute('data-ot').toLowerCase();
        const cliente = row.getAttribute('data-cliente').toLowerCase();
        const modelo = row.getAttribute('data-modelo');
        const estado = row.getAttribute('data-estado');
        let visible = true;
        if (filtroOt && !ot.includes(filtroOt)) visible = false;
        if (filtroCliente && !cliente.includes(filtroCliente)) visible = false;
        if (filtroEstado && estado !== filtroEstado) visible = false;
        if (filtroModelo && modelo !== filtroModelo) visible = false;
        row.style.display = visible ? '' : 'none';
        if (visible) visibleCount++;
    });
    const sinDatosMsg = document.getElementById('sinResultadosMsg');
    if (sinDatosMsg) sinDatosMsg.remove();
    if (visibleCount === 0 && rows.length > 0) {
        const tbody = document.getElementById('tbodyDespacho');
        const msgRow = document.createElement('tr');
        msgRow.id = 'sinResultadosMsg';
        msgRow.innerHTML = '<td colspan="8" style="text-align:center; padding:48px; color:var(--text-muted);"><i class="bx bx-search" style="font-size:3rem; color:var(--text-light); display:block; margin-bottom:12px;"></i>No se encontraron resultados con los filtros aplicados.</td>';
        tbody.appendChild(msgRow);
    }
}

function limpiarFiltros() {
    document.getElementById('filtroOt').value = ''; document.getElementById('filtroCliente').value = ''; document.getElementById('filtroEstado').value = ''; document.getElementById('filtroModelo').value = '';
    aplicarFiltros();
}

document.addEventListener('DOMContentLoaded', () => {
    poblarFiltros(); aplicarFiltros();
    const filtros = ['filtroOt', 'filtroCliente', 'filtroEstado', 'filtroModelo'];
    filtros.forEach(id => {
        const el = document.getElementById(id);
        if (el) { if (el.tagName === 'INPUT') el.addEventListener('keyup', aplicarFiltros); else el.addEventListener('change', aplicarFiltros); }
    });
    document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltros);
});
// Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>
</body>
</html>