<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, modelo.Rol, java.util.List, java.time.DayOfWeek, java.time.LocalDate, java.time.ZoneId" %>
<%
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!"ADMINISTRADOR".equalsIgnoreCase(sesion.getNombreRol())) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=acceso");
        return;
    }

    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    List<Rol>     roles    = (List<Rol>)    request.getAttribute("roles");
    String accionForm = (String)  request.getAttribute("accion");
    String errorForm  = (String)  request.getAttribute("error");
    Usuario uForm     = (Usuario) request.getAttribute("usuario");

    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");

    boolean abrirModal = (accionForm != null);
    boolean esEdicion  = "actualizar".equals(accionForm);
    if (uForm == null) uForm = new Usuario();
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Gestión de Usuarios – Sistema Textil</title>
  
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
    
    /* ── LAYOUT PRINCIPAL ── */
    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; transition: transform 0.3s ease; }
    .logo { padding: var(--space-6) var(--space-4); border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; width: 100%; }
    
    
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
    /* ── CABECERA ── */
    header { background: var(--color-surface); padding: 0.9rem var(--space-6); display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02);}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    
    .user-info { display: flex; align-items: center; gap: var(--space-3); font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; transition: all 0.2s; display:flex; align-items:center; gap:5px;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }

    /* ── CONTENIDO ── */
    .contenido { flex: 1; padding: var(--space-6); overflow-y: auto; }
    
    .alerta { padding: var(--space-3) var(--space-4); border-radius: var(--radius-md); margin-bottom: var(--space-4); font-size: 0.875rem; font-weight: 500; display: flex; align-items: center; gap: 8px; }
    .alerta i { font-size: 1.2rem; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-error { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    .toolbar { display: flex; align-items: center; justify-content: space-between; gap: var(--space-4); margin-bottom: var(--space-4); flex-wrap: wrap; }
    .toolbar-title { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .toolbar-filters { display: flex; align-items: center; gap: var(--space-2); flex-wrap: wrap; flex: 1; justify-content: flex-end; }
    
    .search-wrapper { position: relative; flex: 1; min-width: 200px; max-width: 280px; }
    .search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); transition: all 0.2s; outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }
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
    
    /* HOMOGENEIZACIÓN DE TAMAÑOS: ROLES */
    .badge-rol { 
        display: inline-block; 
        width: 140px; /* Ancho fijo para todos */
        text-align: center;
        padding: 0.35rem 0; 
        border-radius: 6px; 
        font-size: 0.72rem; 
        font-weight: 700; 
        color: #fff; 
        text-transform: uppercase; 
        letter-spacing: 0.5px; 
    }
    .r1 { background: #8b5cf6; } .r2 { background: #3b82f6; } .r3 { background: #10b981; }
    .r4 { background: #f59e0b; } .r5 { background: #14b8a6; } .r6 { background: #64748b; }
    
    /* HOMOGENEIZACIÓN DE TAMAÑOS: ESTADO */
    .chip { 
        display: inline-block; 
        width: 85px; /* Ancho fijo para todos */
        text-align: center;
        padding: 0.3rem 0; 
        border-radius: 6px; 
        font-size: 0.75rem; 
        font-weight: 600; 
    }
    .activo { background: var(--success-bg); color: var(--success-text); }
    .inactivo { background: var(--danger-bg); color: var(--danger-text); }
    
    .badge-horario { display: inline-flex; align-items: center; gap: 6px; padding: 0.3rem 0.8rem; border-radius: 6px; font-size: 0.75rem; font-weight: 500; }
    .badge-horario i { font-size: 0.95rem; }
    .horario-laboral { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
    .horario-admin { background: #f1f5f9; color: var(--text-muted); border: 1px solid var(--border-color); }

    /* HOMOGENEIZACIÓN DE TAMAÑOS: ACCIONES */
    .acciones-container { display: flex; gap: 8px; justify-content: center; }
    .btn-icon { 
        width: 34px; 
        height: 34px; 
        display: inline-flex; 
        align-items: center; 
        justify-content: center; 
        border: none; 
        border-radius: 6px; 
        cursor: pointer; 
        font-size: 1.15rem; 
        transition: all 0.2s; 
    }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }
    .btn-icon.toggle-on { color: #059669; background: #d1fae5; }
    .btn-icon.toggle-on:hover { background: #a7f3d0; color: #047857; }
    .btn-icon.toggle-off { color: #475569; background: #e2e8f0; }
    .btn-icon.toggle-off:hover { background: #cbd5e1; color: #334155; }

    /* ── MODAL ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: var(--space-4); backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 650px; max-height: 90vh; display: flex; flex-direction: column; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    .modal-header { background: var(--color-secondary); padding: 1rem var(--space-6); display: flex; align-items: center; justify-content: space-between; }
    .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: color 0.2s; }
    .modal-close:hover { color: #fff; }
    
    #formUsuario { display: flex; flex-direction: column; flex: 1; overflow: hidden; }
    .modal-body { padding: var(--space-6); flex: 1; overflow-y: auto; scrollbar-gutter: stable; }
    
    .grid-2 { display: grid; grid-template-columns: 1fr; gap: var(--space-4); }
    @media (min-width: 640px) { .grid-2 { grid-template-columns: 1fr 1fr; } }
    
    .field { display: flex; flex-direction: column; gap: 6px; }
    .field.full { grid-column: 1 / -1; }
    .field label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .req { color: var(--danger-hover); }
    .hint { font-size: 0.75rem; color: var(--text-muted); }
    
    .check-wrap { display: flex; align-items: center; gap: 10px; padding: 0.6rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); background: var(--color-surface); cursor: pointer; }
    .check-wrap input[type="checkbox"] { width: 1.1rem; height: 1.1rem; accent-color: var(--color-primary); cursor: pointer; }
    .check-wrap span { font-weight: 500; font-size: 0.85rem; }
    
    .dias-container { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 4px; }
    .dia-chip { display: flex; align-items: center; justify-content: center; background: var(--color-surface); border: 1px solid var(--border-color); padding: 0.4rem 0.6rem; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.8rem; font-weight: 600; color: var(--text-muted); transition: all 0.2s; flex: 1; min-width: 45px; text-align: center; }
    .dia-chip:has(input:checked) { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
    .dia-chip input { display: none; }
    
    .time-field-group { display: flex; gap: var(--space-4); background: var(--color-bg); padding: var(--space-4); border-radius: var(--radius-sm); margin-top: var(--space-3); border: 1px solid var(--border-color); }
    .time-wrapper { flex: 1; display: flex; flex-direction: column; gap: 6px; }
    
    .modal-footer { padding: 1rem var(--space-6); border-top: 1px solid var(--border-color); display: flex; gap: var(--space-3); justify-content: flex-end; background: #f8fafc; }
    input:disabled, select:disabled { background-color: var(--color-bg) !important; cursor: not-allowed; opacity: 0.7; }
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-shield-quarter'></i> Administración</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/gestion-usuarios" class="menu-link activo">Usuarios</a>
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
    <h2><i class='bx bx-user-circle'></i> Gestión de Usuarios y Perfiles</h2>
    <div class="user-info">
      <span><%= sesion.getNombreCompleto() %></span>
      <span class="badge"><%= sesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
    </div>
  </header>

  <div class="contenido">
    <% if (msgExito != null) { %>
      <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div>
    <% } %>
    <% if (msgError != null) { %>
      <div class="alerta alerta-error"><i class='bx bx-error-circle'></i> <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div>
    <% } %>

    <div class="toolbar">
        <h3 class="toolbar-title">Lista de Usuarios (<%= usuarios != null ? usuarios.size() : 0 %>)</h3>

        <div class="toolbar-filters">
          <div class="search-wrapper">
            <i class='bx bx-search search-icon'></i>
            <input type="text" id="busquedaUsuarios" class="form-control" placeholder="Buscar usuario o nombre...">
          </div>

          <select id="busquedaRol" class="form-control" style="width: auto;">
            <option value="">Todos los roles</option>
            <% if (roles != null) { for (Rol r : roles) { %>
              <option value="<%= r.getNombreRol() %>"><%= r.getNombreRol() %></option>
            <% }} %>
          </select>

          <select id="busquedaEstado" class="form-control" style="width: auto;">
            <option value="">Todos los estados</option>
            <option value="Activo">Activo</option>
            <option value="Inactivo">Inactivo</option>
          </select>

          <button type="button" class="btn btn-outline" onclick="limpiarFiltrosUsuarios()">Limpiar</button>
          <button type="button" class="btn btn-primary" onclick="abrirModalNuevo()"><i class='bx bx-plus'></i> Nuevo Usuario</button>
        </div>
    </div>
    
    <div class="card">
      <div class="table-responsive">
          <table>
            <thead>
              <tr>
                <th>#</th><th>Username</th><th>Nombre completo</th>
                <th>Email</th><th style="text-align:center;">Rol</th><th>Horario</th><th style="text-align:center;">Estado</th><th style="text-align:center;">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <% if (usuarios == null || usuarios.isEmpty()) { %>
                <tr><td colspan="8" style="text-align: center; padding: 2rem; color: var(--text-muted);">No hay usuarios registrados.</td></tr>
              <% } else { int i = 1; for (Usuario u : usuarios) { String claseRol = "r" + u.getIdRol(); %>
              <tr>
                <td><%= i++ %></td>
                <td><strong><%= u.getUsername() %></strong></td>
                <td><%= u.getNombreCompleto() %></td>
                <td><%= u.getEmail() %></td>
                <td style="text-align:center;"><span class="badge-rol <%= claseRol %>"><%= u.getNombreRol() %></span></td>
                <td>
                    <% if (u.isHorarioRestringido()) { %>
                      <span class="badge-horario horario-laboral">
                        <i class='bx bx-time-five'></i> <%= u.getHorarioDias() != null ? u.getHorarioDias() : "Lun-Sáb" %>
                        | <%= u.getHorarioInicio() != null ? u.getHorarioInicio().substring(0,5) : "07:00" %>–<%= u.getHorarioFin() != null ? u.getHorarioFin().substring(0,5) : "17:00" %>
                      </span>
                    <% } else { %>
                      <span class="badge-horario horario-admin"><i class='bx bx-lock-open-alt'></i> Sin restricción</span>
                    <% } %>
                </td>
                <td style="text-align:center;"><span class="chip <%= u.isActivo() ? "activo" : "inactivo" %>"><%= u.isActivo() ? "Activo" : "Inactivo" %></span></td>
                <td>
                  <div class="acciones-container">
                      <button type="button" class="btn-icon edit" title="Editar usuario"
                        onclick="abrirModalEditar(
                          '<%= u.getIdUsuario() %>', '<%= u.getUsername() %>',
                          '<%= u.getNombre() != null ? u.getNombre().replace("'","\\x27") : "" %>',
                          '<%= u.getApellido() != null ? u.getApellido().replace("'","\\x27") : "" %>',
                          '<%= u.getEmail() != null ? u.getEmail().replace("'","\\x27") : "" %>',
                          '<%= u.getIdRol() %>', '<%= u.isActivo() %>', '<%= u.isHorarioRestringido() %>',
                          '<%= u.getHorarioDias() != null ? u.getHorarioDias().replace("'","\\x27") : "" %>',
                          '<%= u.getHorarioInicio() != null ? u.getHorarioInicio() : "" %>',
                          '<%= u.getHorarioFin() != null ? u.getHorarioFin() : "" %>'
                        )"><i class='bx bx-edit-alt'></i></button>
                      
                      <% if (u.isActivo()) { %>
                        <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" style="display:inline;" onsubmit="return confirm('¿Desactivar la cuenta de <%= u.getUsername() %>?')">
                          <input type="hidden" name="accion" value="desactivar">
                          <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                          <button type="submit" class="btn-icon toggle-off" title="Desactivar"><i class='bx bx-block'></i></button>
                        </form>
                      <% } else { %>
                        <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" style="display:inline;">
                          <input type="hidden" name="accion" value="activar">
                          <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                          <button type="submit" class="btn-icon toggle-on" title="Activar"><i class='bx bx-check-circle'></i></button>
                        </form>
                      <% } %>
                      
                      <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" style="display:inline;" onsubmit="return confirm('¿Eliminar definitivamente a <%= u.getUsername() %>?\nEsta acción no se puede deshacer.')">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                        <button type="submit" class="btn-icon delete" title="Eliminar usuario"><i class='bx bx-trash'></i></button>
                      </form>
                  </div>
                </td>
              </tr>
              <% }} %>
            </tbody>
          </table>
      </div>
    </div>
  </div>
</main>

<div class="overlay" id="overlayUsuario">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3 id="modalTitulo"><i class='bx bx-user-plus'></i> Registrar nuevo usuario</h3>
      <button type="button" class="modal-close" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" novalidate onsubmit="return validarFormularioModal()" id="formUsuario">
      <div class="modal-body">
        <div id="modalAlertaError" class="alerta alerta-error" style="display:none;"></div>
        
        <input type="hidden" name="accion" id="modalAccion" value="guardar">
        <input type="hidden" name="idUsuario" id="modalIdUsuario" value="0">
        
        <div class="grid-2">
          <div class="field">
            <label>Username <span class="req">*</span></label>
            <input type="text" name="username" id="modalUsername" class="form-control" maxlength="50" placeholder="ej: jperez">
            <span class="hint" id="hintUsername" style="display:none;">El username no puede modificarse.</span>
          </div>
          <div class="field">
            <label>Email <span class="req">*</span></label>
            <input type="email" name="email" id="modalEmail" class="form-control" maxlength="150" placeholder="usuario@textil.pe">
          </div>
          <div class="field">
            <label>Nombre <span class="req">*</span></label>
            <input type="text" name="nombre" id="modalNombre" class="form-control" maxlength="100" placeholder="Juan">
          </div>
          <div class="field">
            <label>Apellido <span class="req">*</span></label>
            <input type="text" name="apellido" id="modalApellido" class="form-control" maxlength="100" placeholder="Pérez">
          </div>
          <div class="field">
            <label>Contraseña <span class="req" id="reqPassword">*</span></label>
            <input type="password" name="password" id="modalPassword" class="form-control" maxlength="100" placeholder="Mínimo 6 caracteres">
            <span class="hint" id="hintPassword" style="display:none;">Solo completa si deseas cambiar la contraseña.</span>
          </div>
          <div class="field">
            <label>Rol <span class="req">*</span></label>
            <select name="idRol" id="modalIdRol" class="form-control">
              <option value="">-- Seleccionar rol --</option>
              <% if (roles != null) { for (Rol r : roles) { %>
                <option value="<%= r.getIdRol() %>"><%= r.getNombreRol() %> — <%= r.getDescripcion() %></option>
              <% }} %>
            </select>
          </div>
          
          <div class="field" id="campoEstado" style="display:none;">
            <label>Estado</label>
            <label class="check-wrap" for="modalActivo">
              <input type="checkbox" name="activo" id="modalActivo" value="1">
              <span>Cuenta activa</span>
            </label>
          </div>
          
          <div class="field full" style="margin-top:var(--space-2); padding-top:var(--space-4); border-top: 1px solid var(--border-color);">
            <label style="font-size: 0.9rem; margin-bottom: 6px;"><i class='bx bx-calendar-alt'></i> Configuración de Horario</label>
            
            <label class="check-wrap" for="modalHorarioRestringido" style="margin-bottom: var(--space-3);">
                <input type="checkbox" id="modalHorarioRestringido" onchange="actualizarHiddenHorario()">
                <input type="hidden" name="horarioRestringidoHidden" id="modalHorarioRestringidoHidden" value="true">
                <span>Restringir acceso por horario</span>
            </label>

            <div id="horarioCampos" style="display:none; flex-direction: column; gap: var(--space-3);">
                <div class="field full">
                    <label>Días permitidos <span class="req">*</span></label>
                    <div class="dias-container">
                        <% String[] dias = {"LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"};
                           for(String d : dias) { %>
                            <label class="dia-chip">
                                <input type="checkbox" class="check-dia" value="<%= d %>" onchange="actualizarInputDias()"> <%= d %>
                            </label>
                        <% } %>
                    </div>
                    <input type="hidden" name="horarioDias" id="modalHorarioDias">
                </div>

                <div class="time-field-group">
                    <div class="time-wrapper">
                        <label>Hora Inicio</label>
                        <input type="time" name="horarioInicio" id="modalHorarioInicio" class="form-control" step="600">
                    </div>
                    <div class="time-wrapper">
                        <label>Hora Fin</label>
                        <input type="time" name="horarioFin" id="modalHorarioFin" class="form-control" step="600">
                    </div>
                </div>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal()">Cancelar</button>
        <button type="submit" class="btn btn-primary" id="btnGuardarModal"><i class='bx bx-save'></i> Registrar usuario</button>
      </div>
    </form>
  </div>
</div>

<script>
    // Se mantiene EXACTAMENTE la misma lógica JavaScript del código original
    function toggleCatalogosMenu(e) {
      e.preventDefault();
      document.getElementById('submenu-catalogos').classList.toggle('activo');
    }

    function abrirModalNuevo() {
      document.getElementById('modalTitulo').innerHTML     = "<i class='bx bx-user-plus'></i> Registrar nuevo usuario";
      document.getElementById('btnGuardarModal').innerHTML = "<i class='bx bx-save'></i> Registrar usuario";
      document.getElementById('modalAccion').value    = 'guardar';
      document.getElementById('modalIdUsuario').value = '0';
      document.getElementById('modalUsername').value  = '';
      document.getElementById('modalUsername').readOnly = false;
      document.getElementById('modalUsername').style.background = '';
      document.getElementById('hintUsername').style.display  = 'none';
      document.getElementById('modalEmail').value    = '';
      document.getElementById('modalNombre').value   = '';
      document.getElementById('modalApellido').value = '';
      document.getElementById('modalPassword').value = '';
      document.getElementById('modalPassword').placeholder = 'Mínimo 6 caracteres';
      document.getElementById('hintPassword').style.display = 'none';
      document.getElementById('reqPassword').style.display  = '';
      document.getElementById('modalIdRol').value = '';
      document.getElementById('campoEstado').style.display   = 'none';
      document.getElementById('modalAlertaError').style.display = 'none';
      document.getElementById('modalHorarioRestringido').checked = true;
      document.getElementById('modalHorarioInicio').value = '07:00';
      document.getElementById('modalHorarioFin').value = '17:00';
      verificarRestriccionPorRol();
      setChecksDias("LUN,MAR,MIE,JUE,VIE,SAB");
      document.getElementById('overlayUsuario').classList.add('activo');
      document.getElementById('modalUsername').focus();
    }

    function abrirModalEditar(id, username, nombre, apellido, email, idRol, activo, restringido, dias, inicio, fin) {
        document.getElementById('modalTitulo').innerHTML     = "<i class='bx bx-edit'></i> Editar cuenta de usuario";
        document.getElementById('btnGuardarModal').innerHTML = "<i class='bx bx-save'></i> Guardar cambios";
        document.getElementById('modalAccion').value    = 'actualizar';
        document.getElementById('modalIdUsuario').value = id;
        document.getElementById('modalUsername').value  = username;
        document.getElementById('modalUsername').readOnly = true;
        document.getElementById('modalUsername').style.background = 'var(--color-bg)';
        document.getElementById('hintUsername').style.display  = '';
        document.getElementById('modalEmail').value    = email;
        document.getElementById('modalNombre').value   = nombre;
        document.getElementById('modalApellido').value = apellido;
        document.getElementById('modalPassword').value = '';
        document.getElementById('modalPassword').placeholder = 'Dejar vacío para no cambiar';
        document.getElementById('hintPassword').style.display = '';
        document.getElementById('reqPassword').style.display  = 'none';
        document.getElementById('modalIdRol').value = idRol;
        document.getElementById('campoEstado').style.display  = '';
        document.getElementById('modalActivo').checked = (activo === 'true');
        document.getElementById('modalAlertaError').style.display = 'none';

        const isRestringido = (restringido === 'true' || restringido === true);
        document.getElementById('modalHorarioRestringido').checked = isRestringido;
        document.getElementById('modalHorarioInicio').value = (inicio || '07:00').substring(0,5);
        document.getElementById('modalHorarioFin').value = (fin || '17:00').substring(0,5);
        setChecksDias(dias);
        verificarRestriccionPorRol();
        document.getElementById('overlayUsuario').classList.add('activo');
        document.getElementById('modalNombre').focus();
    }

    function cerrarModal() { document.getElementById('overlayUsuario').classList.remove('activo'); }
    document.getElementById('overlayUsuario').addEventListener('click', function(e) { if (e.target === this) cerrarModal(); });

    function validarFormularioModal() {
      var accion   = document.getElementById('modalAccion').value;
      var esEdicion = (accion === 'actualizar');
      var username = document.getElementById('modalUsername').value.trim();
      var email    = document.getElementById('modalEmail').value.trim();
      var nombre   = document.getElementById('modalNombre').value.trim();
      var apellido = document.getElementById('modalApellido').value.trim();
      var password = document.getElementById('modalPassword').value;
      var idRol    = document.getElementById('modalIdRol').value;

      if (!esEdicion && username.length < 4)            { mostrarErrorModal('El username debe tener al menos 4 caracteres.'); return false; }
      if (!esEdicion && password.length < 6)            { mostrarErrorModal('La contraseña debe tener al menos 6 caracteres.'); return false; }
      if (password.length > 0 && password.length < 6)  { mostrarErrorModal('La nueva contraseña debe tener al menos 6 caracteres.'); return false; }
      if (!nombre || !apellido)                         { mostrarErrorModal('Nombre y apellido son obligatorios.'); return false; }
      if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email))   { mostrarErrorModal('El email no tiene formato válido.'); return false; }
      if (!idRol)                                       { mostrarErrorModal('Debes seleccionar un rol.'); return false; }
      return true;
    }

    function mostrarErrorModal(msg) {
      var el = document.getElementById('modalAlertaError');
      el.innerHTML = "<i class='bx bx-error-circle'></i> " + msg;
      el.style.display = 'flex';
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    <% if (abrirModal) { %>
    window.addEventListener('DOMContentLoaded', function() {
      <% if (esEdicion) { %>
        abrirModalEditar('<%= uForm.getIdUsuario() %>','<%= uForm.getUsername() != null ? uForm.getUsername() : "" %>','<%= uForm.getNombre() != null ? uForm.getNombre() : "" %>','<%= uForm.getApellido() != null ? uForm.getApellido() : "" %>','<%= uForm.getEmail() != null ? uForm.getEmail() : "" %>','<%= uForm.getIdRol() %>','<%= uForm.isActivo() %>');
      <% } else { %>
        abrirModalNuevo();
        document.getElementById('modalUsername').value = '<%= uForm.getUsername() != null ? uForm.getUsername()  : "" %>';
        document.getElementById('modalNombre').value   = '<%= uForm.getNombre()    != null ? uForm.getNombre()    : "" %>';
        document.getElementById('modalApellido').value = '<%= uForm.getApellido()  != null ? uForm.getApellido()  : "" %>';
        document.getElementById('modalEmail').value    = '<%= uForm.getEmail()     != null ? uForm.getEmail()     : "" %>';
        document.getElementById('modalIdRol').value    = '<%= uForm.getIdRol() %>';
      <% } %>
      <% if (errorForm != null) { %> mostrarErrorModal('<%= errorForm %>'); <% } %>
    });
    <% } %>
   
    var inputBusquedaUsr = document.getElementById('busquedaUsuarios');
    var selectRolUsr     = document.getElementById('busquedaRol');
    var selectEstadoUsr  = document.getElementById('busquedaEstado');

    function aplicarFiltrosUsuarios() {
      var texto  = inputBusquedaUsr.value.toLowerCase().trim();
      var rol    = selectRolUsr.value;
      var estado = selectEstadoUsr.value;
      var filas = document.querySelectorAll('table tbody tr');

      filas.forEach(function(tr) {
        if (tr.querySelector('.sin-datos')) return;
        var username = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var nombre   = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
        var colRol   = tr.cells[4] ? tr.cells[4].textContent.trim() : '';
        var colEstado = tr.cells[6] ? tr.cells[6].textContent.trim() : '';

        if (texto && !username.includes(texto) && !nombre.includes(texto)) { tr.style.display = 'none'; return; }
        if (rol && colRol !== rol) { tr.style.display = 'none'; return; }
        if (estado && colEstado !== estado) { tr.style.display = 'none'; return; }
        tr.style.display = '';
      });
    }

    inputBusquedaUsr.addEventListener('keyup', aplicarFiltrosUsuarios);
    selectRolUsr.addEventListener('change', aplicarFiltrosUsuarios);
    selectEstadoUsr.addEventListener('change', aplicarFiltrosUsuarios);

    function limpiarFiltrosUsuarios() {
      inputBusquedaUsr.value = ''; selectRolUsr.value = ''; selectEstadoUsr.value = '';
      aplicarFiltrosUsuarios();
    }

    function toggleCamposHorario() {
        var checkbox = document.getElementById('modalHorarioRestringido');
        var campos = document.getElementById('horarioCampos');
        if (checkbox && campos) { campos.style.display = checkbox.checked ? 'flex' : 'none'; }
    }

    function actualizarInputDias() {
        const seleccionados = Array.from(document.querySelectorAll('.check-dia:checked')).map(cb => cb.value);
        document.getElementById('modalHorarioDias').value = seleccionados.join(',');
    }

    function cargarChecksDias(diasString) {
        const checks = document.querySelectorAll('.check-dia');
        checks.forEach(cb => cb.checked = false);
        if (diasString) {
            const lista = diasString.split(',');
            checks.forEach(cb => { if (lista.includes(cb.value)) cb.checked = true; });
        }
        actualizarInputDias();
    }

    function setChecksDias(diasStr) {
        const todosLosChecks = document.querySelectorAll('.check-dia');
        todosLosChecks.forEach(cb => cb.checked = false);
        if (diasStr && diasStr !== 'null') {
            const listaDias = diasStr.split(',');
            todosLosChecks.forEach(cb => { if (listaDias.includes(cb.value.toUpperCase())) { cb.checked = true; } });
        }
        actualizarInputDias();
    }

    document.getElementById('modalIdRol').addEventListener('change', function() {
        const textoRol = this.options[this.selectedIndex].text.toUpperCase();
        const checkRestringido = document.getElementById('modalHorarioRestringido');
        if (textoRol.includes("ADMINISTRADOR")) {
            checkRestringido.disabled = false;
        } else {
            checkRestringido.checked = true;
            checkRestringido.disabled = true;
        }
        toggleCamposHorario();
    });

    function verificarRestriccionPorRol() {
        const selectRol = document.getElementById('modalIdRol');
        const checkVisible = document.getElementById('modalHorarioRestringido');
        const inputHidden = document.getElementById('modalHorarioRestringidoHidden');
        if(!selectRol || selectRol.selectedIndex < 0) return;
        const textoRol = selectRol.options[selectRol.selectedIndex].text.toUpperCase();

        if (textoRol.includes("ADMINISTRADOR")) {
            checkVisible.disabled = false;
            inputHidden.value = checkVisible.checked ? "true" : "false";
        } else {
            checkVisible.checked = true;
            checkVisible.disabled = true;
            inputHidden.value = "true"; 
        }
        toggleCamposHorario();
    }

    document.getElementById('modalHorarioRestringido').addEventListener('change', function() {
        document.getElementById('modalHorarioRestringidoHidden').value = this.checked;
    });

    function actualizarHiddenHorario() {
        const check = document.getElementById('modalHorarioRestringido');
        document.getElementById('modalHorarioRestringidoHidden').value = check.checked ? "true" : "false";
        toggleCamposHorario();
    }
    // Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>
</body>
</html>