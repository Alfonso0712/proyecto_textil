<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, java.util.Set, java.util.List, java.util.Map, java.util.ArrayList" %>
<%
    /* ── Protección de sesión ─────────────────────────────── */
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    String rol = usuarioSesion.getNombreRol().toUpperCase();

    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new java.util.HashSet<>();

    final Set<String> permsFinal = permisos;

    String errorAcceso = request.getParameter("error");
    boolean verSeguridad   = permsFinal.contains("SEG_USUARIOS_VER");
    boolean verAlmacen     = permsFinal.contains("ALM_TELA_VER");
    boolean verProduccion  = permsFinal.contains("PROD_OT_VER");
    boolean verCalidad     = permsFinal.contains("CAL_DEFECTOS_REG");
    boolean verDespacho    = permsFinal.contains("DES_CONCIL_REG");
    boolean verCargas      = permsFinal.contains("PROD_CARGAS_ASIG");
    boolean verReportes    = permsFinal.contains("RPT_MERMAS_CALIDAD");
    boolean verDashboard   = permsFinal.contains("RPT_DASHBOARD");
    boolean esAdmin        = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean verReposo      = permsFinal.contains("PROD_REPOSO_VER") || esAdmin;
    boolean verFallas      = permsFinal.contains("PROD_FALLAS_VER") || esAdmin;
    boolean verMerma       = permsFinal.contains("PROD_MERMA_VER")  || esAdmin;
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard – Sistema Textil</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
  
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  
  <style>
    /* ── SISTEMA DE DISEÑO (Variables) ── */
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
        
        --cat-seg: #8b5cf6; --cat-alm: #3b82f6; --cat-prod: #10b981; 
        --cat-cal: #f59e0b; --cat-des: #14b8a6; --cat-rpt: #ef4444;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; height: 100vh; overflow: hidden; color: var(--text-main); }

    /* ── SIDEBAR CON MENÚ ACORDEÓN ── */
    aside { width: 260px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; height: 100vh; overflow-y: auto; }
    aside::-webkit-scrollbar { width: 6px; }
    aside::-webkit-scrollbar-thumb { background-color: rgba(255,255,255,0.1); border-radius: 4px; }
    .sidebar-logo { padding: 24px 20px; border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.2rem; display:flex; flex-direction: column; gap: 4px;}
    .sidebar-logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }

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

    /* ── MAIN & HEADER ── */
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge-rol { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px; transition:0.2s;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }

    /* ── NOTIFICACIONES ── */
    .notificacion-icon { position: relative; display: inline-flex; align-items: center; cursor: pointer; color: var(--text-muted); font-size: 1.4rem; transition: color 0.2s;}
    .notificacion-icon:hover { color: var(--color-primary); }
    .badge-notif { display: none; background: var(--danger-hover); color: white; border-radius: 20px; padding: 2px 6px; font-size: 0.65rem; font-weight: 700; position: absolute; top: -6px; right: -8px; border: 2px solid var(--color-surface);}
    #notif-panel { display: none; position: absolute; right: 24px; top: 60px; background: var(--color-surface); border: 1px solid var(--border-color); width: 320px; max-height: 400px; overflow-y: auto; z-index: 1000; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border-radius: var(--radius-md); }
    .notif-header { padding: 12px 16px; background: #f8fafc; border-bottom: 1px solid var(--border-color); font-weight: 600; font-size: 0.9rem; color: var(--color-secondary); display:flex; align-items:center; gap:6px;}

    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    .alerta-warn { background: var(--warning-bg); color: var(--warning-text); border: 1px solid #fcd34d; padding: 12px 16px; border-radius: var(--radius-md); margin-bottom: 24px; font-size: 0.85rem; display: flex; align-items: center; gap: 8px;}
    
    .bienvenida { background: linear-gradient(135deg, var(--color-secondary), var(--color-primary)); color: #fff; border-radius: var(--radius-lg); padding: 24px 32px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(15, 52, 96, 0.15);}
    .bienvenida h2 { font-size: 1.5rem; margin-bottom: 4px; font-weight: 600;}
    .bienvenida p  { font-size: 0.9rem; color: #cbd5e1; }

    /* ── CARJETAS DE MÓDULOS ── */
    .grid-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; margin-bottom: 32px; }
    .card-modulo { background: var(--color-surface); border-radius: var(--radius-md); padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); cursor: pointer; transition: all 0.2s; text-decoration: none; display: flex; flex-direction: column; border-top: 4px solid transparent; }
    .card-modulo:hover { transform: translateY(-4px); box-shadow: 0 10px 20px rgba(0,0,0,0.08); }
    .card-modulo .ico { font-size: 2.2rem; margin-bottom: 12px; color: var(--color-primary);}
    .card-modulo h4 { font-size: 0.95rem; color: var(--color-secondary); margin-bottom: 4px; font-weight: 600;}
    .card-modulo p  { font-size: 0.75rem; color: var(--text-muted); line-height: 1.4;}
    
    .c-seg  { border-top-color: var(--cat-seg); } .c-seg .ico { color: var(--cat-seg); }
    .c-alm  { border-top-color: var(--cat-alm); } .c-alm .ico { color: var(--cat-alm); }
    .c-prod { border-top-color: var(--cat-prod); } .c-prod .ico { color: var(--cat-prod); }
    .c-cal  { border-top-color: var(--cat-cal); } .c-cal .ico { color: var(--cat-cal); }
    .c-des  { border-top-color: var(--cat-des); } .c-des .ico { color: var(--cat-des); }
    .c-rpt  { border-top-color: var(--cat-rpt); } .c-rpt .ico { color: var(--cat-rpt); }
    .sin-modulos { color: var(--text-muted); font-size: 0.9rem; padding: 24px 0; display:flex; align-items:center; gap:8px;}

    /* ── DASHBOARD SECCIONES ── */
    .dash-section-title { font-size: 1rem; font-weight: 700; color: var(--color-secondary); margin: 32px 0 16px; display: flex; align-items: center; gap: 8px;}

    /* Tarjetas KPI */
    .kpi-row { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .kpi-card { background: var(--color-surface); border-radius: var(--radius-md); padding: 16px 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); border-left: 4px solid var(--color-primary); }
    .kpi-card.verde   { border-left-color: #10b981; }
    .kpi-card.rojo    { border-left-color: #ef4444; }
    .kpi-card.naranja { border-left-color: #f59e0b; }
    .kpi-card.morado  { border-left-color: #8b5cf6; }
    .kpi-card.azul    { border-left-color: #3b82f6; }
    .kpi-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 4px; font-weight: 600; letter-spacing: 0.5px;}
    .kpi-value { font-size: 1.8rem; font-weight: 700; color: var(--color-secondary); line-height: 1;}
    .kpi-sub   { font-size: 0.7rem; color: var(--text-light); margin-top: 6px; }

    /* Flujo de producción */
    .flujo-bar { background: var(--color-surface); border-radius: var(--radius-md); padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin-bottom: 24px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
    .flujo-step { padding: 6px 16px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; color: #fff; display:flex; align-items:center; gap:4px;}
    .flujo-step.optimal  { background: var(--cat-prod); }
    .flujo-step.warning  { background: var(--cat-cal); }
    .flujo-step.critico  { background: var(--cat-rpt); }
    .flujo-arrow { color: var(--text-light); font-size: 1.2rem; }
    .flujo-legend { display: flex; gap: 16px; margin-left: auto; flex-wrap: wrap; }
    .flujo-leg-item { display: flex; align-items: center; gap: 6px; font-size: 0.75rem; color: var(--text-muted); font-weight: 500;}
    .flujo-dot { width: 10px; height: 10px; border-radius: 50%; }
    .flujo-dot.optimal { background: var(--cat-prod); }
    .flujo-dot.warning { background: var(--cat-cal); }
    .flujo-dot.critico { background: var(--cat-rpt); }

    /* Alertas e Inventario Box */
    .alertas-box, .inv-table-wrap { background: var(--color-surface); border-radius: var(--radius-md); padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin-bottom: 24px; }
    .alerta-item { display: flex; align-items: flex-start; gap: 12px; padding: 10px 0; border-bottom: 1px solid var(--border-color); }
    .alerta-item:last-child { border-bottom: none; padding-bottom: 0;}
    .dot-rojo { width: 8px; height: 8px; border-radius: 50%; background: var(--danger-hover); flex-shrink: 0; margin-top: 6px; }
    .alerta-item strong { font-size: 0.85rem; color: var(--text-main); display:block; margin-bottom:2px;}
    .alerta-item span { font-size: 0.75rem; color: var(--text-muted); display: block; line-height:1.4;}

    .inv-table-wrap table { width: 100%; border-collapse: collapse; font-size: 0.82rem; }
    .inv-table-wrap th { background: #f8fafc; color: var(--text-muted); padding: 10px 12px; text-align: left; font-weight: 600; font-size: 0.7rem; text-transform: uppercase; border-bottom: 2px solid var(--border-color);}
    .inv-table-wrap td { padding: 10px 12px; border-bottom: 1px solid var(--border-color); color: var(--text-main);}
    .inv-table-wrap tr:last-child td { border-bottom: none; }

    /* Gráficos */
    .graficos-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .grafico-card { background: var(--color-surface); border-radius: var(--radius-md); padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color);}
    .grafico-card.wide { grid-column: 1 / -1; }
    .grafico-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; flex-wrap: wrap; gap: 12px; }
    .grafico-title { font-size: 0.95rem; font-weight: 600; color: var(--color-secondary); display: flex; align-items: center; gap: 6px; }
    
    .grafico-filtros { display: flex; gap: 8px; flex-wrap: wrap; }
    .form-control { padding: 0.4rem 0.8rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.8rem; color: var(--text-main); background: var(--color-surface); cursor: pointer; outline: none; transition: 0.2s;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }

    .canvas-wrap { position: relative; width: 100%; height: 280px; }
    .canvas-wrap canvas { width: 100% !important; height: 100% !important; }

    /* Tabla OTs */
    .tabla-ot-wrap { background: var(--color-surface); border-radius: var(--radius-md); padding: 0; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin-bottom: 24px; overflow:hidden;}
    .tabla-ot-wrap table { width: 100%; border-collapse: collapse; font-size: 0.85rem; min-width: 800px; }
    .tabla-ot-wrap th { background: #f8fafc; color: var(--text-muted); padding: 14px 16px; text-align: left; font-weight: 600; font-size: 0.75rem; text-transform: uppercase; border-bottom: 2px solid var(--border-color);}
    .tabla-ot-wrap td { padding: 14px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main);}
    .tabla-ot-wrap tr:hover td { background: #f8fafc; }

    .badge-estado { display: inline-block; padding: 0.35rem 0.8rem; border-radius: 6px; font-size: 0.72rem; font-weight: 600; text-transform: uppercase; }
    .badge-estado.finalizada { background: var(--success-bg); color: var(--success-text); }
    .badge-estado.en_proceso { background: var(--warning-bg); color: var(--warning-text); }
    .badge-estado.creada     { background: var(--info-bg); color: var(--info-text); }
    .badge-estado.anulada    { background: var(--danger-bg); color: var(--danger-text); }

    .progress-bar-wrap { background: var(--color-bg); border-radius: 20px; height: 8px; min-width: 120px; overflow: hidden; border: 1px solid var(--border-color);}
    .progress-bar-fill { height: 100%; border-radius: 20px; transition: width 0.4s ease; }
    .progress-bar-fill.verde   { background: var(--success-text); }
    .progress-bar-fill.naranja { background: #f59e0b; }
    .progress-bar-fill.gris    { background: var(--text-light); }
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
    
    <a href="<%= _cp %>/dashboard" class="menu-link activo"><i class='bx bx-home-alt'></i> Dashboard</a>

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
    <h2><i class='bx bx-bar-chart-alt-2'></i> Dashboard de Eficiencia</h2>
    <div style="display: flex; align-items: center; gap: 16px;">
        <div class="notificacion-icon" onclick="toggleNotificaciones()">
            <i class='bx bx-bell'></i>
            <span id="notif-badge" class="badge-notif">0</span>
        </div>
        <div class="user-info">
          <span><%= usuarioSesion.getNombreCompleto() %></span>
          <span class="badge-rol"><%= usuarioSesion.getNombreRol() %></span>
          <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
        </div>
    </div>
  </header>

  <div id="notif-panel">
      <div class="notif-header"><i class='bx bx-bell'></i> Notificaciones</div>
      <div id="notif-list" style="padding:8px;"></div>
  </div>

  <div class="contenido">

    <% if ("sinPermiso".equals(errorAcceso)) { %>
      <div class="alerta-warn"><i class='bx bx-error'></i> No tienes permiso para acceder al módulo solicitado. Contacta al administrador.</div>
    <% } else if ("acceso".equals(errorAcceso)) { %>
      <div class="alerta-warn"><i class='bx bx-error-circle'></i> Acceso restringido. Esta sección requiere privilegios de administrador.</div>
    <% } %>

    <div class="bienvenida">
      <h2>👋 Bienvenido, <%= usuarioSesion.getNombre() %></h2>
      <p>Rol: <strong><%= usuarioSesion.getNombreRol() %></strong> &nbsp;|&nbsp; Sistema de Control de Producción Textil</p>
    </div>

    <div class="grid-cards">
      <% if (verSeguridad) { %>
      <a href="<%= request.getContextPath() %>/gestion-usuarios" class="card-modulo c-seg">
        <i class='bx bx-group ico'></i><h4>Gestión de Usuarios</h4><p>Crear, editar y desactivar cuentas</p>
      </a>
      <% } %>
      <% if (verAlmacen) { %>
      <a href="<%= request.getContextPath() %>/inventario" class="card-modulo c-alm">
        <i class='bx bx-box ico'></i><h4>Almacén</h4><p>Control de tela recibida</p>
      </a>
      <% } %>
      <% if (verProduccion) { %>
      <a href="<%= request.getContextPath() %>/ordenes-trabajo" class="card-modulo c-prod">
        <i class='bx bx-cog ico'></i><h4>Producción</h4><p>Órdenes, tiempos y cargas</p>
      </a>
      <% } %>
      <% if (verReposo) { %>
      <a href="<%= request.getContextPath() %>/tiempos-reposo" class="card-modulo c-prod">
        <i class='bx bx-time-five ico'></i><h4>Tiempos de Reposo</h4><p>Gestión de reposo y corte</p>
      </a>
      <% } %>
      <% if (verFallas) { %>
      <a href="<%= request.getContextPath() %>/fallas-tela" class="card-modulo c-prod">
        <i class='bx bx-map-alt ico'></i><h4>Mapa de Fallas</h4><p>Registro de imperfecciones</p>
      </a>
      <% } %>
      <% if (verMerma) { %>
      <a href="<%= request.getContextPath() %>/mermas" class="card-modulo c-prod">
        <i class='bx bx-trending-down ico'></i><h4>Mermas</h4><p>Merma por tejido y orden</p>
      </a>
      <% } %>
      <% if (verCargas) { %>
      <a href="<%= request.getContextPath() %>/cargas-trabajo" class="card-modulo c-prod">
        <i class='bx bx-group ico'></i><h4>Cargas de Trabajo</h4><p>Asignación a maquinistas</p>
      </a>
      <% } %>
      <% if (verCalidad) { %>
      <a href="<%= request.getContextPath() %>/defectos" class="card-modulo c-cal">
        <i class='bx bx-check-shield ico'></i><h4>Control de Defectos</h4><p>Reprocesos e inspección</p>
      </a>
      <% } %>
      <% if (verDespacho) { %>
      <a href="<%= request.getContextPath() %>/despacho" class="card-modulo c-des">
        <i class='bx bx-truck ico'></i><h4>Conciliación</h4><p>Conteo final y notas</p>
      </a>
      <% } %>
      <% if (verReportes) { %>
      <a href="<%= request.getContextPath() %>/reportes" class="card-modulo c-rpt">
        <i class='bx bx-bar-chart-alt-2 ico'></i><h4>Reportes</h4><p>Mermas y calidad histórica</p>
      </a>
      <% } %>
      <% if (esAdmin) { %>
      <a href="<%= request.getContextPath() %>/catalogo-telas" class="card-modulo c-alm">
        <i class='bx bx-cube ico'></i><h4>Catálogo de Telas</h4><p>Registro de materiales</p>
      </a>
      <a href="<%= request.getContextPath() %>/catalogo-modelos" class="card-modulo c-prod">
        <i class='bx bx-closet ico'></i><h4>Catálogo Modelos</h4><p>Ficha técnica de corsets</p>
      </a>
      <% } %>
      <% if (!verSeguridad && !verAlmacen && !verProduccion && !verCalidad && !verDespacho && !verReportes && !verReposo && !verFallas && !verMerma && !verCargas) { %>
      <p class="sin-modulos"><i class='bx bx-info-circle'></i> No tienes módulos asignados. Contacta al administrador del sistema.</p>
      <% } %>
    </div>

    <div class="dash-section-title"><i class='bx bx-line-chart'></i> RESUMEN DEL DÍA</div>

    <div class="kpi-row" id="kpi-row">
      <div class="kpi-card azul">
        <div class="kpi-label">Órdenes Activas</div>
        <div class="kpi-value" id="kpi-ot-activas">–</div>
        <div class="kpi-sub">Creada + En proceso</div>
      </div>
      <div class="kpi-card verde">
        <div class="kpi-label">Prendas Terminadas</div>
        <div class="kpi-value" id="kpi-prendas">–</div>
        <div class="kpi-sub">OTs finalizadas</div>
      </div>
      <div class="kpi-card naranja">
        <div class="kpi-label">Eficiencia General</div>
        <div class="kpi-value" id="kpi-eficiencia">–</div>
        <div class="kpi-sub">Piezas completadas</div>
      </div>
      <div class="kpi-card rojo">
        <div class="kpi-label">Alertas de Calidad</div>
        <div class="kpi-value" id="kpi-alertas">–</div>
        <div class="kpi-sub">Defectos pendientes</div>
      </div>
      <div class="kpi-card morado">
        <div class="kpi-label">% Merma Promedio</div>
        <div class="kpi-value" id="kpi-merma">–</div>
        <div class="kpi-sub">Sobre peso utilizado</div>
      </div>
      <div class="kpi-card verde">
        <div class="kpi-label">Telas Lista Corte</div>
        <div class="kpi-value" id="kpi-telas-corte">–</div>
        <div class="kpi-sub">Reposo completado</div>
      </div>
    </div>

    <div class="dash-section-title"><i class='bx bx-target-lock'></i> INDICADORES CLAVE (KPI)</div>
    <div class="graficos-grid" style="grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));">
      <div class="grafico-card">
        <div class="grafico-header"><span class="grafico-title">Eficiencia General</span></div>
        <div class="canvas-wrap" style="height:180px;"><canvas id="gaugeEficiencia"></canvas></div>
        <p style="text-align:center;font-weight:700;font-size:1.1rem;color:#f59e0b;" id="gaugeEficienciaVal">–</p>
      </div>
      <div class="grafico-card">
        <div class="grafico-header"><span class="grafico-title">% Merma Promedio</span></div>
        <div class="canvas-wrap" style="height:180px;"><canvas id="gaugeMerma"></canvas></div>
        <p style="text-align:center;font-weight:700;font-size:1.1rem;color:#10b981;" id="gaugeMermaVal">–</p>
      </div>
      <div class="grafico-card">
        <div class="grafico-header"><span class="grafico-title">OTs Finalizadas</span></div>
        <div class="canvas-wrap" style="height:180px;"><canvas id="gaugeOTs"></canvas></div>
        <p style="text-align:center;font-weight:700;font-size:1.1rem;color:#ef4444;" id="gaugeOTsVal">–</p>
      </div>
      <div class="grafico-card">
        <div class="grafico-header"><span class="grafico-title">Calidad (Sin alertas)</span></div>
        <div class="canvas-wrap" style="height:180px;"><canvas id="gaugeCalidad"></canvas></div>
        <p style="text-align:center;font-weight:700;font-size:1.1rem;color:#10b981;" id="gaugeCalidadVal">–</p>
      </div>
    </div>

    <div class="dash-section-title"><i class='bx bx-buildings'></i> FLUJO DE PRODUCCIÓN</div>
    <div style="display:grid;grid-template-columns:1fr 340px;gap:24px;margin-bottom:24px;flex-wrap:wrap;">
      <div>
        <div class="flujo-bar" id="flujo-bar">
          <span class="flujo-step optimal"><i class='bx bx-box'></i> Recepción</span>
          <span class="flujo-arrow"><i class='bx bx-right-arrow-alt'></i></span>
          <span class="flujo-step warning"><i class='bx bx-cut'></i> Corte</span>
          <span class="flujo-arrow"><i class='bx bx-right-arrow-alt'></i></span>
          <span class="flujo-step warning"><i class='bx bx-cog'></i> Confección</span>
          <span class="flujo-arrow"><i class='bx bx-right-arrow-alt'></i></span>
          <span class="flujo-step critico"><i class='bx bx-check-double'></i> Acabado</span>
          <div class="flujo-legend">
            <div class="flujo-leg-item"><div class="flujo-dot optimal"></div>Óptimo</div>
            <div class="flujo-leg-item"><div class="flujo-dot warning"></div>Atención</div>
            <div class="flujo-leg-item"><div class="flujo-dot critico"></div>Crítico</div>
          </div>
        </div>

        <div class="grafico-card" style="margin-top:0;">
          <div class="grafico-header">
            <span class="grafico-title"><i class='bx bx-bar-chart-alt-2'></i> Producción por Maquinista</span>
            <div class="grafico-filtros">
              <select id="filtroMaquinista" class="form-control" onchange="actualizarGraficoMaquinista()"><option value="todos">Todos</option></select>
              <select id="filtroTopMaq" class="form-control" onchange="actualizarGraficoMaquinista()">
                <option value="5">Top 5</option>
                <option value="10">Top 10</option>
                <option value="todos">Todos</option>
              </select>
              <select id="filtroEstadoMaq" class="form-control" onchange="actualizarGraficoMaquinista()">
                <option value="todos">Todos estados</option>
                <option value="FINALIZADA">Finalizadas</option>
                <option value="EN_PROCESO">En proceso</option>
              </select>
            </div>
          </div>
          <div class="canvas-wrap"><canvas id="chartMaquinista"></canvas></div>
        </div>
      </div>

      <div>
        <div class="alertas-box">
          <div style="font-weight:700;color:var(--warning-text);margin-bottom:12px; display:flex; align-items:center; gap:6px;"><i class='bx bx-error'></i> Alertas de Taller</div>
          <div id="alertas-taller-list">
            <p style="color:var(--text-muted);font-size:0.85rem; text-align:center;"><i class='bx bx-loader-alt bx-spin'></i> Cargando...</p>
          </div>
        </div>

        <div class="inv-table-wrap">
          <div style="font-weight:700;color:var(--color-secondary);margin-bottom:12px; display:flex; align-items:center; gap:6px;"><i class='bx bx-cube'></i> Inventario Crítico</div>
          <table>
            <thead><tr><th>Código</th><th>Tipo</th><th>Restante</th></tr></thead>
            <tbody id="inv-telas-body">
              <tr><td colspan="3" style="color:var(--text-muted);text-align:center;"><i class='bx bx-loader-alt bx-spin'></i> Cargando...</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="dash-section-title"><i class='bx bx-pie-chart-alt-2'></i> ANÁLISIS DE PRODUCCIÓN</div>
    <div class="graficos-grid">
      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-trending-down'></i> Mermas y Defectos</span>
          <div class="grafico-filtros">
            <select id="filtroMermaVista" class="form-control" onchange="actualizarGraficoMermas()">
              <option value="tipo_defecto">Por Tipo Defecto</option>
              <option value="tipo_tejido">Por Tipo Tejido</option>
              <option value="mes">Por Mes</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartMermas"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-list-ul'></i> OTs por Estado</span>
          <div class="grafico-filtros">
            <select id="filtroOTMes" class="form-control" onchange="actualizarGraficoOTEstado()">
              <option value="3">Últimos 3 meses</option>
              <option value="6">Últimos 6 meses</option>
              <option value="12">Último año</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartOTEstado"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-line-chart'></i> Eficiencia Semanal (%)</span>
          <div class="grafico-filtros">
            <select id="filtroEfSemanas" class="form-control" onchange="actualizarGraficoEficiencia()">
              <option value="4">4 semanas</option>
              <option value="8">8 semanas</option>
              <option value="12">12 semanas</option>
            </select>
            <select id="filtroEfOT" class="form-control" onchange="actualizarGraficoEficiencia()">
              <option value="todas">Todas las OTs</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartEficiencia"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-calculator'></i> % Merma por Orden</span>
          <div class="grafico-filtros">
            <select id="filtroMermaOT" class="form-control" onchange="actualizarGraficoMermaOT()">
              <option value="5">Top 5 OTs</option>
              <option value="10">Top 10 OTs</option>
              <option value="todas">Todas</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartMermaOT"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-time-five'></i> Tiempos de Reposo</span>
          <div class="grafico-filtros">
            <select id="filtroReposo" class="form-control" onchange="actualizarGraficoReposo()">
              <option value="todos">Todos</option>
              <option value="EN_REPOSO">En Reposo</option>
              <option value="APTO_CORTE">Apto para Corte</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartReposo"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-check-shield'></i> Defectos (Gravedad)</span>
          <div class="grafico-filtros">
            <select id="filtroDefectoVista" class="form-control" onchange="actualizarGraficoDefectos()">
              <option value="tipo">Por Tipo</option>
              <option value="gravedad">Por Gravedad</option>
              <option value="ot">Por OT</option>
            </select>
            <select id="filtroDefectoEstado" class="form-control" onchange="actualizarGraficoDefectos()">
              <option value="todos">Todos</option>
              <option value="PENDIENTE">Pendiente</option>
              <option value="REPROCESO">Reproceso</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartDefectos"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-layer'></i> Telas (Calidad)</span>
          <div class="grafico-filtros">
            <select id="filtroTelaCalidad" class="form-control" onchange="actualizarGraficoTelaCalidad()">
              <option value="estado">Por Estado</option>
              <option value="origen">Por Origen</option>
              <option value="tejido">Por Tejido</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartTelaCalidad"></canvas></div>
      </div>

      <div class="grafico-card">
        <div class="grafico-header">
          <span class="grafico-title"><i class='bx bx-hard-hat'></i> Cargas de Trabajo</span>
          <div class="grafico-filtros">
            <select id="filtroCargaFase" class="form-control" onchange="actualizarGraficoCarga()">
              <option value="todas">Todas</option>
              <option value="CORTE">Corte</option>
              <option value="CONFECCION">Confección</option>
            </select>
            <select id="filtroCargaEstado" class="form-control" onchange="actualizarGraficoCarga()">
              <option value="todos">Todos</option>
              <option value="PENDIENTE">Pendiente</option>
              <option value="COMPLETADA">Completado</option>
            </select>
          </div>
        </div>
        <div class="canvas-wrap"><canvas id="chartCarga"></canvas></div>
      </div>
    </div>

    <div class="dash-section-title"><i class='bx bx-list-ul'></i> DETALLE DE PROGRESO POR OT</div>
    <%
      @SuppressWarnings("unchecked")
      List<Map<String,Object>> otFilas = (List<Map<String,Object>>) request.getAttribute("otFilas");
      if (otFilas == null) otFilas = new ArrayList<>();
    %>
    <div class="tabla-ot-wrap">
      <div style="overflow-x:auto;">
        <table>
          <thead>
            <tr>
              <th>Código OT</th>
              <th>Cliente</th>
              <th>Responsable</th>
              <th>Estado</th>
              <th>Fecha Creación</th>
              <th>Progreso</th>
              <th>Fases</th>
            </tr>
          </thead>
          <tbody>
            <% if (otFilas.isEmpty()) { %>
            <tr><td colspan="7" style="text-align:center;color:var(--text-muted);padding:3rem;"><i class='bx bx-list-ul' style="font-size:3rem;display:block;margin-bottom:12px;color:var(--border-color);"></i>No hay órdenes registradas.</td></tr>
            <% } else { for (Map<String,Object> f : otFilas) {
              String est   = (String)  f.get("estado");
              int    pct   = (Integer) f.get("progreso");
              int    comp  = (Integer) f.get("fasesComp");
              int    total = (Integer) f.get("fasesTotal");
              int    proc  = (Integer) f.get("enProc");
              String barColor = pct == 100 ? "var(--success-text)" : pct > 0 ? "#f59e0b" : "var(--text-light)";
              
              String badgeCls = "creada";
              if ("FINALIZADA".equals(est))      badgeCls = "finalizada";
              else if ("EN_PROCESO".equals(est)) badgeCls = "en_proceso";
              else if ("ANULADA".equals(est))    badgeCls = "anulada";
              
              String estLabel = est != null ? est.replace("_"," ") : "";
            %>
            <tr>
              <td><strong><%= f.get("codigo") %></strong></td>
              <td><%= f.get("cliente") %></td>
              <td><%= f.get("responsable") %></td>
              <td><span class="badge-estado <%= badgeCls %>"><%= estLabel %></span></td>
              <td><%= f.get("fecha") %></td>
              <td>
                <div style="display:flex;align-items:center;gap:8px;">
                  <div class="progress-bar-wrap">
                    <div class="progress-bar-fill" style="width:<%= pct %>%; background:<%= barColor %>;"></div>
                  </div>
                  <span style="font-size:0.75rem;color:var(--text-muted);font-weight:600;"><%= pct %>%</span>
                </div>
              </td>
              <td style="font-size:0.8rem;color:var(--text-muted);"><%= comp %>/<%= total %> comp. | <%= proc %> en proc.</td>
            </tr>
            <% } } %>
          </tbody>
        </table>
      </div>
    </div>

  </div></main>

<script>
// ═══════════════════════════════════════════════════════════
// UI MENÚ ACORDEÓN
// ═══════════════════════════════════════════════════════════
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}

// ═══════════════════════════════════════════════════════════
// DATOS GLOBALES Y LÓGICA DE CHART.JS (INTACTA)
// ═══════════════════════════════════════════════════════════
let dashData = {
  kpis: {}, ordenes: [], maquinistas: [], mermas: [], defectos: [],
  telas: [], reposos: [], cargas: [], alertas: [], inventarioCritico: []
};
let chartInstances = {};

const COLORS = {
  azul:    '#3b82f6',
  verde:   '#10b981',
  naranja: '#f59e0b',
  rojo:    '#ef4444',
  morado:  '#8b5cf6',
  celeste: '#0ea5e9',
  gris:    '#94a3b8',
  amarillo:'#eab308'
};
const PALETTE = Object.values(COLORS);

function cargarDashboard() {
  fetch('<%= request.getContextPath() %>/dashboard?accion=json')
    .then(res => { if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
    .then(data => {
      if (data && typeof data === 'object' && !Array.isArray(data)) {
        if (data.ordenes)           dashData.ordenes           = data.ordenes;
        if (data.kpis)              dashData.kpis              = data.kpis;
        if (data.maquinistas)       dashData.maquinistas       = data.maquinistas;
        if (data.mermas)            dashData.mermas            = data.mermas;
        if (data.mermaOT)           dashData.mermaOT           = data.mermaOT;
        if (data.defectos)          dashData.defectos          = data.defectos;
        if (data.telas)             dashData.telas             = data.telas;
        if (data.reposos)           dashData.reposos           = data.reposos;
        if (data.cargas)            dashData.cargas            = data.cargas;
        if (data.alertas)           dashData.alertas           = data.alertas;
        if (data.inventarioCritico) dashData.inventarioCritico = data.inventarioCritico;
        if (data.eficienciaSemanal) dashData.eficienciaSemanal = data.eficienciaSemanal;
      }
      aplicarFallbackDemo();
      renderTodo();
    })
    .catch(err => {
      console.warn('fetch falló, usando datos demo:', err);
      aplicarFallbackDemo();
      renderTodo();
    });
}

function aplicarFallbackDemo() {
  if (!dashData.kpis || !dashData.kpis.otActivas) {
    const otActivas = dashData.ordenes.filter(o=>['CREADA','EN_PROCESO'].includes(o.estado)).length;
    const prendas   = dashData.ordenes.filter(o=>o.estado==='FINALIZADA').length;
    dashData.kpis = { otActivas: otActivas||0, prendas: prendas||0, eficiencia: 0, alertas: 0, mermaPromedio: 0, telasListaCorte: 0 };
  }
  if (!dashData.maquinistas) dashData.maquinistas = [];
  if (!dashData.mermas) dashData.mermas = [];
  if (!dashData.defectos) dashData.defectos = [];
  if (!dashData.telas) dashData.telas = [];
  if (!dashData.reposos) dashData.reposos = [];
  if (!dashData.cargas) dashData.cargas = [];
  if (!dashData.alertas) dashData.alertas = [];
  if (!dashData.inventarioCritico) dashData.inventarioCritico = [];
  if (!dashData.mermaOT) dashData.mermaOT = [];
  if (!dashData.eficienciaSemanal) dashData.eficienciaSemanal = [];
}

function renderTodo() {
  renderKPIs(); renderGauges(); renderAlertas(); renderInventarioCritico();
  poblarFiltrosMaquinista(); actualizarGraficoMaquinista(); actualizarGraficoMermas();
  actualizarGraficoOTEstado(); actualizarGraficoEficiencia(); actualizarGraficoMermaOT();
  actualizarGraficoReposo(); actualizarGraficoDefectos(); actualizarGraficoTelaCalidad();
  actualizarGraficoCarga();
}

function renderKPIs() {
  const k = dashData.kpis;
  document.getElementById('kpi-ot-activas').textContent   = k.otActivas ?? dashData.ordenes.filter(o=>['CREADA','EN_PROCESO'].includes(o.estado)).length;
  document.getElementById('kpi-prendas').textContent      = k.prendas   ?? dashData.ordenes.filter(o=>o.estado==='FINALIZADA').reduce((a,o)=>a+o.fasesComp,0);
  document.getElementById('kpi-eficiencia').textContent   = (k.eficiencia ?? 47) + '%';
  document.getElementById('kpi-alertas').textContent      = k.alertas   ?? dashData.alertas.length;
  document.getElementById('kpi-merma').textContent        = (k.mermaPromedio ?? 4.0) + '%';
  document.getElementById('kpi-telas-corte').textContent  = k.telasListaCorte ?? dashData.reposos.filter(r=>r.estado==='APTO_CORTE').length;
}

function crearGauge(id, pct, color, label) {
  const ctx = document.getElementById(id).getContext('2d');
  if (chartInstances[id]) chartInstances[id].destroy();
  const resto = 100 - pct;
  chartInstances[id] = new Chart(ctx, {
    type: 'doughnut',
    data: { datasets:[{ data: [pct, resto], backgroundColor: [color, '#e2e8f0'], borderWidth: 0, circumference: 180, rotation: 270 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '75%', plugins: { legend:{ display:false }, tooltip:{ enabled:false } } }
  });
}

function renderGauges() {
  const k = dashData.kpis;
  const ef = k.eficiencia ?? 47;
  const merma = k.mermaPromedio ?? 4.0;
  const total = dashData.ordenes.length;
  const final = dashData.ordenes.filter(o=>o.estado==='FINALIZADA').length;
  const otPct = total ? Math.round(final/total*100) : 0;
  const calPct = dashData.alertas && dashData.alertas.length === 0 ? 100 : Math.max(0, 100 - dashData.alertas.length*10);

  crearGauge('gaugeEficiencia', ef, COLORS.naranja);
  crearGauge('gaugeMerma', Math.min(merma*5, 100), COLORS.verde);
  crearGauge('gaugeOTs', otPct, COLORS.rojo);
  crearGauge('gaugeCalidad', calPct, COLORS.verde);

  document.getElementById('gaugeEficienciaVal').textContent = ef + '%';
  document.getElementById('gaugeMermaVal').textContent = merma + '%';
  document.getElementById('gaugeOTsVal').textContent = otPct + '%';
  document.getElementById('gaugeCalidadVal').textContent = calPct + '%';
}

function renderAlertas() {
  const el = document.getElementById('alertas-taller-list');
  if (!dashData.alertas || dashData.alertas.length === 0) {
    el.innerHTML = '<p style="color:var(--success-text);font-size:.82rem; text-align:center;"><i class="bx bx-check-circle"></i> Sin alertas activas</p>'; return;
  }
  el.innerHTML = dashData.alertas.map(a => `<div class="alerta-item"><div class="dot-rojo"></div><div><strong>${a.codigo}</strong><span>${a.mensaje}</span></div></div>`).join('');
}

function renderInventarioCritico() {
  const tbody = document.getElementById('inv-telas-body');
  if (!dashData.inventarioCritico || dashData.inventarioCritico.length === 0) {
      tbody.innerHTML = '<tr><td colspan="3" style="text-align:center; color:var(--success-text);"><i class="bx bx-check-circle"></i> Stock saludable</td></tr>'; return;
  }
  tbody.innerHTML = dashData.inventarioCritico.map(t => `<tr><td>${t.codigo}</td><td>${t.tipo}</td><td><strong>${t.restante}</strong></td></tr>`).join('');
}

function poblarFiltrosMaquinista() {
  const sel = document.getElementById('filtroMaquinista');
  dashData.maquinistas.forEach(m => {
    const opt = document.createElement('option'); opt.value=m.nombre; opt.textContent=m.nombre; sel.appendChild(opt);
  });
}

function mostrarSinDatos(id, mensaje) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  if (chartInstances[id]) { chartInstances[id].destroy(); delete chartInstances[id]; }
  const parent = ctx.parentElement;
  const prev = parent.querySelector('.sin-datos-msg');
  if (prev) prev.remove();
  const div = document.createElement('div');
  div.className = 'sin-datos-msg';
  div.style.cssText = 'display:flex;align-items:center;justify-content:center;height:120px;color:var(--text-muted);font-size:.82rem;font-style:italic; gap:6px;';
  div.innerHTML = `<i class='bx bx-info-circle'></i> ${mensaje || 'Sin datos para mostrar'}`;
  parent.appendChild(div);
  ctx.style.display = 'none';
}

function mostrarChart(id) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  ctx.style.display = '';
  const prev = ctx.parentElement.querySelector('.sin-datos-msg');
  if (prev) prev.remove();
}

function crearChart(id, config) {
  mostrarChart(id);
  const ctx = document.getElementById(id).getContext('2d');
  if (chartInstances[id]) chartInstances[id].destroy();
  chartInstances[id] = new Chart(ctx, config);
}

function actualizarGraficoMaquinista() {
  const filtroNombre = document.getElementById('filtroMaquinista').value;
  const topN = document.getElementById('filtroTopMaq').value;
  const filtroEst = document.getElementById('filtroEstadoMaq').value;
  let datos = [...dashData.maquinistas];
  if (filtroNombre !== 'todos') datos = datos.filter(m=>m.nombre===filtroNombre);
  if (topN !== 'todos') datos = datos.slice(0, parseInt(topN));
  if (datos.length === 0) { mostrarSinDatos('chartMaquinista', 'Sin maquinistas asignados'); return; }

  const labels = datos.map(m => m.nombre.split(' ')[0]);
  const datasets = filtroEst === 'todos'
    ? [ { label:'Completadas', data:datos.map(m=>m.completadas), backgroundColor: COLORS.verde, borderRadius:4 }, { label:'Pendientes', data:datos.map(m=>m.pendientes), backgroundColor: COLORS.naranja, borderRadius:4 } ]
    : filtroEst === 'FINALIZADA' ? [{ label:'Completadas', data:datos.map(m=>m.completadas), backgroundColor: COLORS.verde, borderRadius:4 }] : [{ label:'Pendientes', data:datos.map(m=>m.pendientes), backgroundColor: COLORS.naranja, borderRadius:4 }];
  
  crearChart('chartMaquinista', {
    type:'bar', data:{ labels, datasets }, options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } }, scales:{ y:{ beginAtZero:true } } }
  });
}

function actualizarGraficoMermas() {
  const vista = document.getElementById('filtroMermaVista').value;
  let labels, data;
  if (vista === 'mes') { labels = ['Ene','Feb','Mar','Abr','May']; data = [3.8, 4.1, 3.5, 4.8, 4.0]; } 
  else { labels = dashData.mermas.map(m=>m.label); data = dashData.mermas.map(m=>m.valor); }
  crearChart('chartMermas', {
    type: vista==='mes'?'line':'doughnut',
    data:{ labels, datasets:[{ data, backgroundColor: PALETTE.slice(0,labels.length), borderColor: PALETTE.slice(0,labels.length), fill:false, tension:.4 }] },
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } } }
  });
}

function actualizarGraficoOTEstado() {
  const n = parseInt(document.getElementById('filtroOTMes').value);
  const ahora = new Date();
  const mesesLabels = [];
  const mapFin = {}, mapProc = {}, mapCread = {};
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(ahora.getFullYear(), ahora.getMonth() - i, 1);
    const key = d.toLocaleString('es', { month: 'short', year: '2-digit' });
    mesesLabels.push(key);
    mapFin[key] = 0; mapProc[key] = 0; mapCread[key] = 0;
  }
  dashData.ordenes.forEach(function(o) {
    if (!o.fecha) return;
    const d = new Date(o.fecha);
    const key = d.toLocaleString('es', { month: 'short', year: '2-digit' });
    if (mapFin[key] !== undefined) {
      if (o.estado === 'FINALIZADA') mapFin[key]++;
      else if (o.estado === 'EN_PROCESO') mapProc[key]++;
      else if (o.estado === 'CREADA') mapCread[key]++;
    }
  });
  crearChart('chartOTEstado', {
    type: 'line',
    data: { labels: mesesLabels, datasets: [
      { label:'Finalizadas', data: mesesLabels.map(k=>mapFin[k]), borderColor:COLORS.verde, backgroundColor:COLORS.verde+'33', fill:true, tension:.4 },
      { label:'En Proceso', data: mesesLabels.map(k=>mapProc[k]), borderColor:COLORS.naranja, backgroundColor:COLORS.naranja+'33', fill:true, tension:.4 },
      { label:'Creadas', data: mesesLabels.map(k=>mapCread[k]), borderColor:COLORS.azul, backgroundColor:COLORS.azul+'33', fill:true, tension:.4 }
    ]},
    options: { responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } }, scales:{ y:{ beginAtZero:true, ticks:{ stepSize:1 } } } }
  });
}

function actualizarGraficoEficiencia() {
  const n = parseInt(document.getElementById('filtroEfSemanas').value);
  const datos = dashData.eficienciaSemanal.slice(-n);
  if (!datos || datos.length === 0) { mostrarSinDatos('chartEficiencia', 'Sin datos de eficiencia semanal'); return; }
  crearChart('chartEficiencia', {
    type:'line',
    data:{ labels:datos.map(d=>d.semana), datasets:[{ label:'Eficiencia (%)', data:datos.map(d=>d.pct), borderColor:COLORS.azul, backgroundColor:COLORS.azul+'22', fill:true, tension:.4, pointRadius:4 }]},
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } }, scales:{ y:{ beginAtZero:false, min:30, max:100, ticks:{ callback:v=>v+'%' } } } }
  });
}

function actualizarGraficoMermaOT() {
  const n = document.getElementById('filtroMermaOT').value;
  let datos = [...(dashData.mermaOT||[])].sort((a,b)=>b.pct-a.pct);
  if (n !== 'todas') datos = datos.slice(0, parseInt(n));
  if (datos.length === 0) { mostrarSinDatos('chartMermaOT', 'Sin mermas registradas'); return; }
  crearChart('chartMermaOT', {
    type:'bar',
    data:{ labels:datos.map(d=>d.ot), datasets:[{ label:'% Merma', data:datos.map(d=>d.pct), backgroundColor:datos.map(d=>d.pct>5?COLORS.rojo:d.pct>3?COLORS.naranja:COLORS.verde), borderRadius:4 }]},
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false } }, scales:{ y:{ beginAtZero:true, ticks:{ callback:v=>v+'%' } } } }
  });
}

function actualizarGraficoReposo() {
  const filtro = document.getElementById('filtroReposo').value;
  let datos = [...(dashData.reposos||[])];
  if (filtro !== 'todos') datos = datos.filter(r=>r.estado===filtro);
  if (datos.length === 0) { mostrarSinDatos('chartReposo', 'Sin registros de reposo'); return; }
  crearChart('chartReposo', {
    type:'bar',
    data:{ labels:datos.map(d=>d.tela), datasets:[{ label:'Horas Reposo', data:datos.map(d=>d.horas), backgroundColor:datos.map(d=>d.estado==='APTO_CORTE'?COLORS.verde:d.estado==='EN_REPOSO'?COLORS.naranja:COLORS.azul), borderRadius:4 }]},
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false }, tooltip:{ callbacks:{ label:ctx=>ctx.raw+' horas' } } }, scales:{ y:{ beginAtZero:true } } }
  });
}

function actualizarGraficoDefectos() {
  const vista = document.getElementById('filtroDefectoVista').value;
  const estado = document.getElementById('filtroDefectoEstado').value;
  let datos = [...dashData.defectos];
  if (estado !== 'todos') datos = datos.filter(d=>d.estado===estado);
  if (datos.length === 0) { mostrarSinDatos('chartDefectos', 'Sin defectos registrados'); return; }

  let labels, vals;
  if (vista === 'gravedad') {
    const grp = {}; datos.forEach(d=>{ grp[d.gravedad]=(grp[d.gravedad]||0)+d.cantidad; });
    labels = Object.keys(grp); vals = Object.values(grp);
  } else { labels = datos.map(d=>d.tipo); vals = datos.map(d=>d.cantidad); }

  crearChart('chartDefectos', {
    type: 'bar',
    data:{ labels, datasets:[{ label:'Cantidad', data:vals, backgroundColor:PALETTE.slice(0,labels.length), borderRadius:4 }]},
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ display:false } }, scales:{ y:{ beginAtZero:true } } }
  });
}

function actualizarGraficoTelaCalidad() {
  const vista = document.getElementById('filtroTelaCalidad').value;
  const grp = {};
  dashData.telas.forEach(t => { const key = vista==='estado'?t.estado:vista==='origen'?t.origen:t.tejido; grp[key] = (grp[key]||0) + t.cantidad; });
  const labels = Object.keys(grp), vals = Object.values(grp);
  if (labels.length === 0) { mostrarSinDatos('chartTelaCalidad', 'Sin datos de telas'); return; }
  crearChart('chartTelaCalidad', {
    type:'pie',
    data:{ labels, datasets:[{ data:vals, backgroundColor:PALETTE.slice(0,labels.length), borderWidth:1 }] },
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } } }
  });
}

function actualizarGraficoCarga() {
  const fase = document.getElementById('filtroCargaFase').value;
  const estdo = document.getElementById('filtroCargaEstado').value;
  let datos = [...dashData.cargas];
  if (fase !== 'todas') datos = datos.filter(c=>c.fase===fase);
  if (datos.length === 0) { mostrarSinDatos('chartCarga', 'Sin cargas de trabajo'); return; }

  const labels = datos.map(c=>c.maquinista.split(' ')[0]);
  const comp = datos.map(c=>c.completadas);
  const pend = datos.map(c=>c.pendientes);

  const datasets = estdo==='COMPLETADA' ? [{ label:'Completadas', data:comp, backgroundColor:COLORS.verde, borderRadius:4 }]
    : estdo==='PENDIENTE' ? [{ label:'Pendientes', data:pend, backgroundColor:COLORS.naranja, borderRadius:4 }]
    : [ { label:'Completadas', data:comp, backgroundColor:COLORS.verde, borderRadius:4 }, { label:'Pendientes', data:pend, backgroundColor:COLORS.naranja,borderRadius:4 } ];
  
  crearChart('chartCarga', {
    type:'bar',
    data:{ labels, datasets },
    options:{ responsive:true, maintainAspectRatio:false, plugins:{ legend:{ position:'bottom' } }, scales:{ x:{ stacked:true }, y:{ stacked:true, beginAtZero:true } } }
  });
}

function actualizarNotificaciones() {
  fetch('<%= request.getContextPath() %>/notificaciones?accion=listarNoLeidas')
    .then(res => res.json())
    .then(data => {
      const badge = document.getElementById('notif-badge');
      if (data.length > 0) { badge.textContent = data.length; badge.style.display = 'inline-block'; }
      else badge.style.display = 'none';
    }).catch(console.error);
}

function toggleNotificaciones() {
  const panel = document.getElementById('notif-panel');
  if (panel.style.display === 'none') {
    document.getElementById('notif-list').innerHTML = '<div style="padding:16px;text-align:center;color:var(--text-muted);"><i class="bx bx-loader-alt bx-spin"></i> Cargando...</div>';
    panel.style.display = 'block';
    fetch('<%= request.getContextPath() %>/notificaciones?limite=20')
      .then(res=>{ if(!res.ok) throw new Error('HTTP '+res.status); return res.json(); })
      .then(data => {
        const listaDiv = document.getElementById('notif-list');
        listaDiv.innerHTML = '';
        if (data.length === 0) { listaDiv.innerHTML='<div style="padding:16px;text-align:center;color:var(--text-muted);">No hay notificaciones</div>'; return; }
        data.forEach(notif => {
          const div = document.createElement('div');
          div.style.cssText = 'padding:12px 16px; border-bottom:1px solid var(--border-color); background:'+(notif.leida?'var(--color-surface)':'#f0f6ff');
          const tw = notif.leida?'normal':'600', ct=notif.leida?'var(--text-muted)':'var(--color-primary)', cm=notif.leida?'var(--text-light)':'var(--text-main)';
          const fechaStr = notif.fecha?new Date(notif.fecha).toLocaleString():'';
          div.innerHTML=`<strong style="color:${ct};font-size:0.85rem;display:block;font-weight:${tw};">${notif.titulo||'Notificación'}</strong>
                         <small style="color:var(--text-light);font-size:0.75rem;">${fechaStr}</small>
                         <p style="margin:4px 0 0;font-size:0.8rem;color:${cm};line-height:1.4;">${notif.mensaje||'Sin detalles'}</p>`;
          listaDiv.appendChild(div);
          if (!notif.leida && notif.id) fetch('<%= request.getContextPath() %>/notificaciones?accion=marcarLeida&id='+notif.id);
        });
        actualizarNotificaciones();
      }).catch(err=>{ document.getElementById('notif-list').innerHTML='<div style="padding:16px;color:var(--danger-hover);text-align:center;">Error al cargar</div>'; });
  } else { panel.style.display = 'none'; }
}

document.addEventListener('DOMContentLoaded', () => {
  actualizarNotificaciones();
  setInterval(actualizarNotificaciones, 30000);
  cargarDashboard();
});
</script>
</body>
</html>