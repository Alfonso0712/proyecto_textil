<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();
    
    boolean puedeGestionar = permisos.contains("PROD_MAQUINISTAS_GESTION");
    boolean puedeVer       = permisos.contains("PROD_MAQUINISTAS_VER");
    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    List<MaquinistaDTO> maquinistas = (List<MaquinistaDTO>) request.getAttribute("maquinistas");
    List<Especialidad> todasEspecialidades = (List<Especialidad>) request.getAttribute("especialidadesDisponibles");
    
    // Construir estructura de datos para JavaScript: Map<idUsuario, {datos, especialidades}>
    Map<Integer, String> nombresCompletos = new HashMap<>();
    Map<Integer, List<Integer>> especialidadesPorUsuario = new HashMap<>();
    if (maquinistas != null) {
        for (MaquinistaDTO dto : maquinistas) {
            int id = dto.getUsuario().getIdUsuario();
            nombresCompletos.put(id, dto.getUsuario().getNombreCompleto());
            List<Integer> idsEsp = new ArrayList<>();
            for (Especialidad e : dto.getEspecialidades()) idsEsp.add(e.getIdEspecialidad());
            especialidadesPorUsuario.put(id, idsEsp);
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Registro de Maquinistas – Sistema Textil</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>

  <style>
    /* ── SISTEMA DE DISEÑO (Variables) ── */
    :root {
        --color-primary: #0f3460;
        --color-primary-hover: #1a5ca8;
        --color-secondary: #1a1a2e;
        --color-accent: #e2b96f;
        --color-bg: #f4f6f8;
        --color-surface: #ffffff;
        
        --text-main: #334155;
        --text-muted: #64748b;
        --text-light: #cbd5e1;
        
        --border-color: #e2e8f0;
        
        --success-bg: #d1fae5;
        --success-text: #065f46;
        --danger-bg: #fee2e2;
        --danger-text: #991b1b;
        --danger-hover: #dc2626;
        
        --space-1: 4px;
        --space-2: 8px;
        --space-3: 12px;
        --space-4: 16px;
        --space-6: 24px;
        
        --radius-sm: 6px;
        --radius-md: 8px;
        --radius-lg: 12px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; min-height: 100vh; color: var(--text-main); }
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
    /* ── LAYOUT PRINCIPAL ── */
    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; transition: transform 0.3s ease; }
    .logo { padding: var(--space-6) var(--space-4); border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }
    

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; width: 100%; }
    
    /* ── CABECERA ── */
    header { background: var(--color-surface); padding: 0.9rem var(--space-6); display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02);}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    
    .user-info { display: flex; align-items: center; gap: var(--space-3); font-size: 0.85rem; font-weight: 500; }
    .badge-rol-header { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; transition: all 0.2s; display:flex; align-items:center; gap:5px;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }

    /* ── CONTENIDO ── */
    .contenido { flex: 1; padding: var(--space-6); overflow-y: auto; }
    
    .toolbar { display: flex; align-items: center; justify-content: space-between; gap: var(--space-4); margin-bottom: var(--space-4); flex-wrap: wrap; }
    .toolbar-title { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .toolbar-filters { display: flex; align-items: center; gap: var(--space-2); flex-wrap: wrap; flex: 1; justify-content: flex-end; }
    
    .search-wrapper { position: relative; flex: 1; min-width: 200px; max-width: 350px; }
    .search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); transition: all 0.2s; outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }
    .btn-success { background: #10b981; color: #fff; }
    .btn-success:hover { background: #059669; }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); }
    .btn-outline:hover { background: var(--color-bg); }

    /* ── TABLAS HOMOGENEIZADAS ── */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow:hidden;}
    .table-responsive { overflow-x: auto; width: 100%; }
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 0.8rem 1.2rem; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; letter-spacing: 0.5px; }
    td { padding: 0.8rem 1.2rem; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }
    
    /* HOMOGENEIZACIÓN DE TAMAÑOS: ESTADO Y ESPECIALIDADES */
    .chip { 
        display: inline-block; width: 85px; text-align: center; padding: 0.3rem 0;
        border-radius: 6px; font-size: 0.75rem; font-weight: 600; 
    }
    .activo { background: var(--success-bg); color: var(--success-text); }
    .inactivo { background: var(--danger-bg); color: var(--danger-text); }
    
    .especialidades-container { display: flex; gap: 6px; flex-wrap: wrap; }
    .chip-especialidad {
        display: inline-flex; align-items: center; padding: 0.25rem 0.6rem;
        background: #f1f5f9; color: #334155; border: 1px solid var(--border-color);
        border-radius: 6px; font-size: 0.75rem; font-weight: 500;
    }

    /* HOMOGENEIZACIÓN DE TAMAÑOS: ACCIONES */
    .acciones-container { display: flex; gap: 8px; justify-content: center; }
    .btn-icon { 
        width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; 
        border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s;
    }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }
    .btn-icon.toggle-on { color: #059669; background: #d1fae5; }
    .btn-icon.toggle-on:hover { background: #a7f3d0; color: #047857; }
    .btn-icon.toggle-off { color: #475569; background: #e2e8f0; }
    .btn-icon.toggle-off:hover { background: #cbd5e1; color: #334155; }

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: var(--space-4); backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 600px; max-height: 90vh; display: flex; flex-direction: column; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    
    /* El modal secundario necesita estar por encima */
    #modal-especialidad { z-index: 1010; }
    #modal-especialidad .modal-flotante { max-width: 450px; }

    .modal-header { background: var(--color-secondary); padding: 1rem var(--space-6); display: flex; align-items: center; justify-content: space-between; }
    .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: color 0.2s; }
    .modal-close:hover { color: #fff; }
    
    form.modal-form { display: flex; flex-direction: column; flex: 1; overflow: hidden; }
    .modal-body { padding: var(--space-6); flex: 1; overflow-y: auto; scrollbar-gutter: stable; }
    
    .grid-2 { display: grid; grid-template-columns: 1fr; gap: var(--space-4); }
    @media (min-width: 640px) { .grid-2 { grid-template-columns: 1fr 1fr; } }
    
    .field { display: flex; flex-direction: column; gap: 6px; }
    .field.full { grid-column: 1 / -1; }
    .field label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .req { color: var(--danger-hover); }
    
    /* Estilo tipo chip para los checkboxes de especialidades */
    .checklist-chips { display: flex; gap: 8px; flex-wrap: wrap; margin-top: var(--space-2); }
    .chip-check {
        display: inline-flex; align-items: center; padding: 0.4rem 0.8rem;
        background: var(--color-surface); border: 1px solid var(--border-color);
        border-radius: var(--radius-sm); cursor: pointer; font-size: 0.8rem; font-weight: 500;
        color: var(--text-muted); transition: all 0.2s;
    }
    .chip-check:has(input:checked) {
        background: var(--color-primary); color: #fff; border-color: var(--color-primary);
    }
    .chip-check input { display: none; }

    .modal-footer { padding: 1rem var(--space-6); border-top: 1px solid var(--border-color); display: flex; gap: var(--space-3); justify-content: flex-end; background: #f8fafc; }
  </style>
</head>
<body>

<aside id="sidebar">
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-store'></i> Almacén</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navAlm) { %><a href="<%= _cp %>/inventario" class="menu-link">Tela Recibida</a><% } %>
        <% if (_navMaq) { %><a href="<%= _cp %>/maquinistas" class="menu-link activo">Maquinistas</a><% } %>
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
    <h2><i class='bx bx-user-pin'></i> Registro de Maquinistas y Especialidades</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge-rol-header"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
    </div>
  </header>

  <div class="contenido">
    <div class="toolbar">
        <h3 class="toolbar-title">Lista de Maquinistas</h3>
        <div class="toolbar-filters">
          <div class="search-wrapper">
            <i class='bx bx-search search-icon'></i>
            <input type="text" id="busquedaMaquinistas" class="form-control" placeholder="Buscar por username o nombre...">
          </div>
          <% if (puedeGestionar) { %>
            <button onclick="abrirModalNuevo()" class="btn btn-primary"><i class='bx bx-plus'></i> Nuevo Maquinista</button>
          <% } %>
        </div>
    </div>

    <div class="card">
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Username</th>
              <th>Nombre completo</th>
              <th>Especialidades</th>
              <th style="text-align:center;">Estado</th>
              <th style="text-align:center;">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <% if (maquinistas == null || maquinistas.isEmpty()) { %>
              <tr><td colspan="6" class="sin-datos" style="text-align: center; padding: 2rem; color: var(--text-muted);">No hay maquinistas registrados.</td></tr>
            <% } else {
                 int i = 1;
                 for (MaquinistaDTO dto : maquinistas) {
                   Usuario u = dto.getUsuario();
            %>
            <tr>
              <td><%= i++ %></td>
              <td><strong><%= u.getUsername() %></strong></td>
              <td><%= u.getNombreCompleto() %></td>
              <td>
                <div class="especialidades-container">
                    <% for (Especialidad e : dto.getEspecialidades()) { %>
                      <span class="chip-especialidad"><%= e.getNombre() %></span>
                    <% } %>
                </div>
              </td>
              <td style="text-align:center;"><span class="chip <%= u.isActivo() ? "activo" : "inactivo" %>"><%= u.isActivo() ? "Activo" : "Inactivo" %></span></td>
              <td>
                <% if (puedeGestionar) { %>
                  <div class="acciones-container">
                      <button type="button" class="btn-icon edit" onclick="abrirModalEditar(<%= u.getIdUsuario() %>)" title="Editar maquinista"><i class='bx bx-edit-alt'></i></button>
                      
                      <% if (u.isActivo()) { %>
                        <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;" onsubmit="return confirm('¿Desactivar maquinista?')">
                          <input type="hidden" name="accion" value="desactivar">
                          <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                          <button type="submit" class="btn-icon toggle-off" title="Desactivar"><i class='bx bx-block'></i></button>
                        </form>
                      <% } else { %>
                        <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;">
                          <input type="hidden" name="accion" value="activar">
                          <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                          <button type="submit" class="btn-icon toggle-on" title="Activar"><i class='bx bx-check-circle'></i></button>
                        </form>
                      <% } %>
                      
                      <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar definitivamente al maquinista <%= u.getUsername() %>?')">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                        <button type="submit" class="btn-icon delete" title="Eliminar maquinista"><i class='bx bx-trash'></i></button>
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

<div id="modal-maquinista" class="overlay">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3 id="modal-titulo"><i class='bx bx-user-plus'></i> Nuevo Maquinista</h3>
      <button type="button" class="modal-close" onclick="cerrarModalMaquinista()"><i class='bx bx-x'></i></button>
    </div>
    
    <form action="<%= request.getContextPath() %>/maquinistas" method="POST" class="modal-form">
      <div class="modal-body">
          <input type="hidden" id="modal-accion" name="accion" value="guardar">
          <input type="hidden" id="modal-id" name="idUsuario" value="">

          <div class="grid-2">
              <div class="field">
                  <label>Username <span class="req">*</span></label>
                  <input type="text" id="modal-username" name="username" class="form-control" required>
              </div>
              <div class="field">
                  <label id="label-password">Contraseña <span class="req">*</span></label>
                  <input type="password" id="modal-password" name="password" class="form-control" required>
              </div>
              <div class="field">
                  <label>Nombre <span class="req">*</span></label>
                  <input type="text" id="modal-nombre" name="nombre" class="form-control" required>
              </div>
              <div class="field">
                  <label>Apellido <span class="req">*</span></label>
                  <input type="text" id="modal-apellido" name="apellido" class="form-control" required>
              </div>
              <div class="field full">
                  <label>Email</label>
                  <input type="email" id="modal-email" name="email" class="form-control" placeholder="ej: maquinista@textil.pe">
              </div>

              <div class="field full" style="margin-top: var(--space-2); padding-top: var(--space-4); border-top: 1px solid var(--border-color);">
                  <div style="display:flex; justify-content:space-between; align-items:center;">
                      <label style="font-size: 0.9rem; margin-bottom: 6px;"><i class='bx bx-purchase-tag-alt'></i> Especialidades Técnicas</label>
                      <button type="button" class="btn btn-success" style="padding: 0.35rem 0.6rem; font-size: 0.75rem;" onclick="abrirModalNuevaEspecialidad()"><i class='bx bx-plus'></i> Crear Especialidad</button>
                  </div>
                  <div id="contenedor-especialidades" class="checklist-chips">
                      </div>
              </div>
          </div>
      </div>
      <div class="modal-footer">
          <button type="button" class="btn btn-outline" onclick="cerrarModalMaquinista()">Cancelar</button>
          <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar</button>
      </div>
    </form>
  </div>
</div>

<div id="modal-especialidad" class="overlay">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3 id="modal-esp-titulo"><i class='bx bx-purchase-tag'></i> Nueva Especialidad</h3>
      <button type="button" class="modal-close" onclick="cerrarModalEspecialidad()"><i class='bx bx-x'></i></button>
    </div>
    <form id="form-nueva-especialidad" class="modal-form">
      <div class="modal-body">
          <div class="field">
              <label>Nombre <span class="req">*</span></label>
              <input type="text" id="esp-nombre" class="form-control" required>
          </div>
          <div class="field" style="margin-top: var(--space-3);">
              <label>Descripción (opcional)</label>
              <textarea id="esp-descripcion" rows="3" class="form-control" style="resize:vertical;"></textarea>
          </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalEspecialidad()">Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Registrar</button>
      </div>
    </form>
  </div>
</div>

<script>
    // Datos inyectados desde JSP
    const todasEspecialidades = [
      <% for (int i = 0; i < todasEspecialidades.size(); i++) {
           Especialidad e = todasEspecialidades.get(i);
           out.print("{\"id\":" + e.getIdEspecialidad() + ",\"nombre\":\"" + e.getNombre() + "\"}");
           if (i < todasEspecialidades.size() - 1) out.print(",");
         } %>
    ];

    const maquinistasData = {
      <% int count = 0;
         for (MaquinistaDTO dto : maquinistas) {
           Usuario u = dto.getUsuario();
           out.print("\"" + u.getIdUsuario() + "\":{");
           out.print("\"username\":\"" + u.getUsername() + "\",");
           out.print("\"nombre\":\"" + u.getNombre() + "\",");
           out.print("\"apellido\":\"" + u.getApellido() + "\",");
           out.print("\"email\":\"" + (u.getEmail() != null ? u.getEmail() : "") + "\",");
           out.print("\"especialidades\":[");
           for (int j = 0; j < dto.getEspecialidades().size(); j++) {
             out.print(dto.getEspecialidades().get(j).getIdEspecialidad());
             if (j < dto.getEspecialidades().size() - 1) out.print(",");
           }
           out.print("]}");
           if (count++ < maquinistas.size() - 1) out.print(",");
         }
      %>
    };

    // Llenar checkboxes de especialidades usando el nuevo diseño de chips
    function renderEspecialidades(seleccionadas) {
      const container = document.getElementById('contenedor-especialidades');
      container.innerHTML = '';
      todasEspecialidades.forEach(esp => {
        const label = document.createElement('label');
        label.className = 'chip-check';
        
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.name = 'especialidades';
        checkbox.value = esp.id;
        
        if (seleccionadas && seleccionadas.includes(esp.id)) checkbox.checked = true;
        
        const spanText = document.createElement('span');
        spanText.textContent = esp.nombre;
        
        label.appendChild(checkbox);
        label.appendChild(spanText);
        container.appendChild(label);
      });
    }

    // Abrir modal en modo nuevo
    function abrirModalNuevo() {
      document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-user-plus'></i> Nuevo Maquinista";
      document.getElementById('modal-accion').value = 'guardar';
      document.getElementById('modal-id').value = '';
      document.getElementById('modal-username').value = '';
      document.getElementById('modal-password').value = '';
      document.getElementById('modal-nombre').value = '';
      document.getElementById('modal-apellido').value = '';
      document.getElementById('modal-email').value = '';
      document.getElementById('label-password').innerHTML = 'Contraseña <span class="req">*</span>';
      document.getElementById('modal-password').required = true;
      renderEspecialidades([]);
      document.getElementById('modal-maquinista').classList.add('activo');
    }

    // Abrir modal en modo edición con datos precargados
    function abrirModalEditar(id) {
      const datos = maquinistasData[id];
      if (!datos) return;
      document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-edit'></i> Editar Maquinista";
      document.getElementById('modal-accion').value = 'actualizar';
      document.getElementById('modal-id').value = id;
      document.getElementById('modal-username').value = datos.username;
      document.getElementById('modal-password').value = '';
      document.getElementById('modal-nombre').value = datos.nombre;
      document.getElementById('modal-apellido').value = datos.apellido;
      document.getElementById('modal-email').value = datos.email;
      document.getElementById('label-password').innerHTML = 'Contraseña <span style="font-size:0.75rem; color:var(--text-muted); font-weight:normal;">(vacío para no cambiar)</span>';
      document.getElementById('modal-password').required = false;
      renderEspecialidades(datos.especialidades);
      document.getElementById('modal-maquinista').classList.add('activo');
    }

    function cerrarModalMaquinista() {
      document.getElementById('modal-maquinista').classList.remove('activo');
    }

    // Cerrar modal al hacer click en el overlay oscuro
    document.getElementById('modal-maquinista').addEventListener('click', function(e) { if (e.target === this) cerrarModalMaquinista(); });
    document.getElementById('modal-especialidad').addEventListener('click', function(e) { if (e.target === this) cerrarModalEspecialidad(); });

  // --- Manejo del modal de nueva especialidad ---
  function abrirModalNuevaEspecialidad() {
      document.getElementById('esp-nombre').value = '';
      document.getElementById('esp-descripcion').value = '';
      document.getElementById('modal-especialidad').classList.add('activo');
  }

  function cerrarModalEspecialidad() {
      document.getElementById('modal-especialidad').classList.remove('activo');
  }

  // Enviar formulario de nueva especialidad por AJAX
  document.getElementById('form-nueva-especialidad').addEventListener('submit', function(e) {
      e.preventDefault();
      const nombre = document.getElementById('esp-nombre').value.trim();
      const descripcion = document.getElementById('esp-descripcion').value.trim();

      if (!nombre) {
          alert('El nombre es obligatorio');
          return;
      }

      fetch('<%= request.getContextPath() %>/especialidades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ nombre: nombre, descripcion: descripcion })
      })
      .then(response => {
          if (!response.ok) throw new Error('Error de servidor');
          return response.json();
      })
      .then(data => {
          todasEspecialidades.push({ id: data.id, nombre: data.nombre });

          const checkboxes = document.querySelectorAll('#contenedor-especialidades input[type="checkbox"]');
          const seleccionadas = Array.from(checkboxes).filter(cb => cb.checked).map(cb => parseInt(cb.value));
          
          seleccionadas.push(data.id);
          renderEspecialidades(seleccionadas);
          cerrarModalEspecialidad();
      })
      .catch(error => {
          alert('Error al crear especialidad: ' + error.message);
      });
  });

  // Filtro de búsqueda en tiempo real para maquinistas
  document.getElementById('busquedaMaquinistas').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('.sin-datos')) return;

      var username = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      var nombreCompleto = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
      var celdaEspecialidades = tr.cells[3];
      var especialidadesTexto = celdaEspecialidades ? celdaEspecialidades.textContent.toLowerCase() : '';

      if (!filtro || username.includes(filtro) || nombreCompleto.includes(filtro) || especialidadesTexto.includes(filtro)) {
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
