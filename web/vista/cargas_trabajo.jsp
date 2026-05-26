<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    if (!permisos.contains("PROD_CARGAS_ASIG")) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return;
    }

    List<AsignacionCarga> fases    = (List<AsignacionCarga>) request.getAttribute("fasesPendientes");
    List<AsignacionCargaDAO.ResumenCargaMaquinista> resumen =
        (List<AsignacionCargaDAO.ResumenCargaMaquinista>) request.getAttribute("resumenCarga");
    List<Usuario> maquinistas = (List<Usuario>) request.getAttribute("maquinistas");

    if (fases        == null) fases        = new ArrayList<>();
    if (resumen      == null) resumen      = new ArrayList<>();
    if (maquinistas  == null) maquinistas  = new ArrayList<>();

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
  <title>Cargas de Trabajo (HU05) – Sistema Textil</title>
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

    /* ── SIDEBAR & HEADER ── */
    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; }
    .logo { padding: 24px 16px; border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; } 
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }
    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    /* ── ALERTAS & DASHBOARD ── */
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 16px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-err { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    .dashboard-resumen { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
    .card-maquinista { background: var(--color-surface); border-left: 4px solid var(--danger-hover); padding: 16px; border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border-top: 1px solid var(--border-color); border-right: 1px solid var(--border-color); border-bottom: 1px solid var(--border-color); min-width: 200px; display: flex; align-items: center; justify-content: space-between; transition: transform 0.2s; }
    .card-maquinista.ok { border-left-color: var(--success-text); }
    .card-maquinista.warn { border-left-color: #d97706; }
    .card-maquinista h4 { font-size: 0.88rem; color: var(--text-main); margin-bottom: 4px; }
    .card-maquinista .spec { font-size: 0.75rem; color: var(--text-muted); font-weight: 500; text-transform: uppercase; }
    .card-maquinista .count { font-size: 1.75rem; font-weight: 700; color: var(--color-secondary); }

    /* ── TABLA & ACCORDION ── */
    .section-title { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
    .section-title h3 { color: var(--color-secondary); font-size: 1.15rem; font-weight: 600;}
    .section-title p { font-size: 0.85rem; color: var(--text-muted); margin-top: 4px; }
    
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-end; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; }
    .filtro-wrap > div { display: flex; flex-direction: column; gap: 6px; }
    .filtro-wrap label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); display:flex; align-items:center; gap:4px;}
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); transition: all 0.2s; outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); padding: 0.55rem 1rem; border-radius: var(--radius-sm); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: 0.2s; display:flex; align-items:center; gap:4px;}
    .btn-outline:hover { background: var(--color-bg); }

    .card { background: var(--color-surface); border-radius: var(--radius-md); border: 1px solid var(--border-color); overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.04);}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); vertical-align: middle; color: var(--text-main);}
    .sin-datos { text-align: center; padding: 48px; color: var(--text-muted); }
    .sin-datos .ico { font-size: 3rem; display: block; margin-bottom: 12px; color: var(--border-color);}

    /* ── CHIPS ── */
    .chip { display: inline-flex; align-items: center; justify-content: center; gap:4px; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; min-width: 110px; text-align: center; }
    .chip-completado { background: var(--success-bg); color: var(--success-text); }
    .chip-proceso    { background: var(--warning-bg); color: var(--warning-text); }
    .chip-pendiente  { background: #f1f5f9; color: var(--text-muted); }
    .chip-bloqueado  { background: var(--danger-bg); color: var(--danger-text); }
    
    .btn-asignar { display: inline-flex; align-items: center; justify-content: center; gap: 4px; padding: 0.35rem 0.85rem; background: var(--color-primary); color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 0.8rem; font-weight: 600; min-width: 100px; transition: 0.2s; }
    .btn-asignar:hover { background: var(--color-primary-hover); }
    .btn-bloqueado-label { display: inline-flex; align-items: center; gap: 4px; padding: 0.35rem 0.7rem; background: #f1f5f9; color: var(--text-muted); border-radius: 6px; font-size: 0.8rem; font-weight: 600; }

    /* ── ACCORDION ── */
    .btn-expandir-all { padding: 0.4rem 1rem; background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: .2s; display:flex; align-items:center; gap:6px;}
    .btn-expandir-all:hover { background: var(--color-bg); }
    .ot-row { display: flex; align-items: center; gap: 16px; padding: 14px 20px; background: var(--color-surface); border-bottom: 1px solid var(--border-color); cursor: pointer; transition: background .15s; }
    .ot-row:hover { background: #f8fafc; }
    .ot-row-left { display: flex; align-items: center; gap: 12px; flex: 1; }
    .ot-toggle-icon { font-size: 1rem; color: var(--text-muted); transition: transform .2s; }
    .ot-toggle-icon.open { transform: rotate(90deg); color: var(--color-primary); }
    .ot-codigo { font-weight: 700; font-size: 0.95rem; color: var(--color-secondary); }
    .ot-modelo { font-size: 0.85rem; color: var(--text-muted); margin-left: 8px; }
    .ot-row-stats { display: flex; gap: 6px; flex-wrap: wrap; }
    .stat-chip { display: inline-flex; align-items: center; gap:4px; padding: 0.25rem 0.7rem; border-radius: 20px; font-size: 0.72rem; font-weight: 600; }
    .ot-progress-wrap { display: flex; align-items: center; gap: 8px; min-width: 140px; }
    .ot-progress-bar { flex: 1; height: 8px; background: var(--border-color); border-radius: 4px; overflow: hidden; }
    .ot-progress-fill { height: 100%; background: var(--success-text); border-radius: 4px; transition: width .4s ease; }
    .ot-pct { font-size: 0.8rem; font-weight: 700; color: var(--success-text); min-width: 35px; text-align: right; }

    .fases-detalle { display: none; background: #f8fafc; border-bottom: 1px solid var(--border-color); overflow: hidden; }
    .fases-detalle.open { display: block; }
    
    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15,23,42,.5); z-index: 1000; justify-content: center; align-items: center; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 520px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,.15); }
    .modal-box { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 520px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--color-secondary); font-size: 1.1rem; font-weight: 600; display:flex; align-items:center; gap:8px;}
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-light); transition: .2s; }
    .close-modal:hover { color: var(--text-main); }
    
    .info-panel { display: flex; justify-content: space-between; background: #f8fafc; border: 1px solid var(--border-color); padding: 16px; border-radius: var(--radius-sm); margin-bottom: 20px; }
    .info-panel div span { color: var(--text-muted); font-size: 0.75rem; display: block; margin-bottom: 4px; font-weight:600;}
    .info-panel strong { font-size: 0.85rem; color: var(--text-main);}
    .alerta-bloqueo { background: var(--danger-bg); color: var(--danger-text); border-left: 4px solid var(--danger-hover); padding: 12px 16px; border-radius: 6px; font-size: 0.85rem; margin-bottom: 20px; display: none; }
    
    .field { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
    .field label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .btn-guardar { width: 100%; padding: 0.75rem; color: #fff; background: var(--color-primary); border: none; border-radius: var(--radius-sm); cursor: pointer; font-weight: 600; font-size: 0.9rem; transition: .2s; display:flex; align-items:center; justify-content:center; gap:6px;}
    .btn-guardar:hover { background: var(--color-primary-hover); }
    .btn-guardar:disabled { background: var(--border-color); color: var(--text-muted); cursor: not-allowed; }
    .btn-cancelar { padding: 0.55rem 1rem; border: 1px solid var(--border-color); background: var(--color-surface); color: var(--text-main); border-radius: var(--radius-sm); cursor: pointer; font-weight: 600; font-size: 0.85rem; }
    
    .badge-notif { display: none; background:var(--danger-hover); color:white; border-radius:20px; padding:2px 6px; font-size:0.7rem; position:absolute; top:-8px; right:-10px; font-weight:bold; }
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-cog'></i> Producción</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navOT)   { %><a href="<%= _cp %>/ordenes-trabajo" class="menu-link">Órdenes de Trabajo</a><% } %>
        <% if (_navRep)  { %><a href="<%= _cp %>/tiempos-reposo" class="menu-link">Tiempos de Reposo</a><% } %>
        <% if (_navFall) { %><a href="<%= _cp %>/fallas-tela" class="menu-link">Mapa de Fallas</a><% } %>
        <% if (_navMer)  { %><a href="<%= _cp %>/mermas" class="menu-link">Mermas</a><% } %>
        <% if (_navCarg) { %><a href="<%= _cp %>/cargas-trabajo" class="menu-link activo">Cargas de Trabajo</a><% } %>
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
    <h2><i class='bx bx-group'></i> Distribución de Cargas de Trabajo</h2>
    <div style="display: flex; align-items: center; gap: 20px;">
        <div class="notificacion-icon" style="position: relative; cursor: pointer;">
            <i class='bx bx-bell' style="font-size:1.4rem; color:var(--text-muted);"></i>
            <span id="notif-badge" class="badge-notif">0</span>
        </div>
        <div class="user-info">
            <span><%= usuarioSesion.getNombreCompleto() %></span>
            <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
            <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
        </div>
    </div>
  </header>

<div id="notif-panel" style="display:none; position:absolute; right:24px; top:64px; background:var(--color-surface); border:1px solid var(--border-color); width:320px; max-height:400px; overflow-y:auto; z-index:1000; box-shadow:0 10px 25px rgba(0,0,0,0.1); border-radius:var(--radius-md);">
    <div class="notif-header" style="padding:12px 16px; background:#f8fafc; border-bottom:1px solid var(--border-color); font-weight:600; color:var(--text-main);"><i class='bx bx-bell'></i> Notificaciones</div>
    <div id="notif-list"></div>
</div>
        
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

    <% if (!resumen.isEmpty()) { %>
    <div class="dashboard-resumen">
      <% for (AsignacionCargaDAO.ResumenCargaMaquinista r : resumen) {
           String colorClass = r.getTotalActivas() == 0 ? "ok" : (r.getTotalActivas() <= 3 ? "warn" : "");
      %>
      <div class="card-maquinista <%= colorClass %>">
        <div>
          <h4><%= r.getNombreMaquinista() %></h4>
          <span class="spec"><%= r.getEspecialidad() != null ? r.getEspecialidad() : "Sin especialidad" %></span>
        </div>
        <span class="count"><%= r.getTotalActivas() %></span>
      </div>
      <% } %>
    </div>
    <% } %>

    <div class="section-title">
      <div>
        <h3>Fases de Confección por Orden de Trabajo</h3>
        <p>Haz clic en una OT para ver sus fases. <strong>Bloqueo activo:</strong> no puede asignar si la fase previa está incompleta.</p>
      </div>
      <button class="btn-expandir-all" onclick="toggleTodos()"><i class='bx bx-menu'></i> <span id="txt-expand">Expandir todo</span></button>
    </div>
    
    <div class="filtro-wrap">
        <div>
            <label><i class='bx bx-search'></i> Código OT</label>
            <input type="text" id="filtroOt" class="form-control" placeholder="Ej: OT-2026-001" style="width: 160px;">
        </div>
        <div>
            <label><i class='bx bx-user-pin'></i> Maquinista</label>
            <select id="filtroMaquinista" class="form-control" style="width: 180px;">
                <option value="">-- Todos --</option>
            </select>
        </div>
        <div>
            <label><i class='bx bx-filter'></i> Estado de fase</label>
            <select id="filtroEstado" class="form-control" style="width: 150px;">
                <option value="">-- Todos --</option>
                <option value="PENDIENTE">Pendiente</option>
                <option value="EN_PROCESO">En Proceso</option>
                <option value="COMPLETADA">Completada</option>
                <option value="BLOQUEADO">Bloqueado</option>
            </select>
        </div>
        <div>
            <label><i class='bx bx-extension'></i> Pieza</label>
            <input type="text" id="filtroPieza" class="form-control" placeholder="Nombre de pieza" style="width: 180px;">
        </div>
        <div>
            <button id="btnLimpiarFiltros" class="btn-outline"><i class='bx bx-eraser'></i> Limpiar filtros</button>
        </div>
    </div>
    
    <div class="card" id="card-fases" style="padding:0; border:none; box-shadow:none; background:transparent;">
      <% if (fases.isEmpty()) { %>
        <div class="card sin-datos">
          <i class='bx bx-group ico'></i>
          No hay fases pendientes. Cambia una OT a estado EN_PROCESO para generar las cargas.
        </div>
      <% } else {
        java.util.Map<String, java.util.List<AsignacionCarga>> porOT = new java.util.LinkedHashMap<>();
        for (AsignacionCarga f : fases) { porOT.computeIfAbsent(f.getCodigoOt(), k -> new java.util.ArrayList<>()).add(f); }
        int otIdx = 0;
        for (java.util.Map.Entry<String, java.util.List<AsignacionCarga>> entry : porOT.entrySet()) {
            String codigoOt  = entry.getKey();
            java.util.List<AsignacionCarga> fasesOT = entry.getValue();
            AsignacionCarga primera = fasesOT.get(0);

            long completadas  = fasesOT.stream().filter(x -> x.getEstadoFase() != null && "COMPLETADA".equals(x.getEstadoFase().name())).count();
            long enProceso    = fasesOT.stream().filter(x -> x.getEstadoFase() != null && "EN_PROCESO".equals(x.getEstadoFase().name())).count();
            long pendientes   = fasesOT.size() - completadas - enProceso;
            int  pct          = (int) Math.round((completadas * 100.0) / fasesOT.size());
            String idGrupo    = "ot-" + otIdx;
      %>

        <div class="ot-row" onclick="toggleGrupo('<%= idGrupo %>')">
          <div class="ot-row-left">
            <i class='bx bx-chevron-right ot-toggle-icon' id="ico-<%= idGrupo %>"></i>
            <div>
              <span class="ot-codigo"><%= codigoOt %></span>
              <span class="ot-modelo"><%= primera.getNombreModelo() != null ? primera.getNombreModelo() : "-" %></span>
            </div>
          </div>
          <div class="ot-row-stats">
            <span class="stat-chip chip-completado"><i class='bx bx-check'></i> <%= completadas %> Completadas</span>
            <span class="stat-chip chip-proceso"><i class='bx bx-loader-alt bx-spin' style="animation-duration: 3s;"></i> <%= enProceso %> En Proceso</span>
            <span class="stat-chip chip-pendiente"><i class='bx bx-time-five'></i> <%= pendientes %> Pendientes</span>
          </div>
          <div class="ot-progress-wrap">
            <div class="ot-progress-bar"><div class="ot-progress-fill" style="width:<%= pct %>%"></div></div>
            <span class="ot-pct"><%= pct %>%</span>
          </div>
        </div>

        <div class="fases-detalle" id="<%= idGrupo %>">
            <table id="fases-detalle">
            <thead>
              <tr><th>Pieza</th><th>Cant.</th><th style="text-align:center;">Avance</th><th>Fase Previa</th><th>Fase a Asignar</th><th>Maquinista</th><th style="text-align:center;">Estado</th><th style="text-align:center;">Acción</th><th>Tipo</th></tr>
            </thead>
            <tbody>
              <% for (AsignacionCarga f : fasesOT) {
                   boolean bloqueado = !f.isFasePreviaCompleta();
                   String estadoFase = f.getEstadoFase() != null ? f.getEstadoFase().name() : "PENDIENTE";
              %>
              <tr>
                <td>
                    <% if (f.getNombrePieza() != null) { %><%= f.getNombrePieza() %><% } else { %>
                        <span style="font-weight: 700; color: var(--color-primary);"><i class='bx bx-closet'></i> PRENDA COMPLETA</span>
                    <% } %>
                </td>
                <td><%= f.getCantidadPiezas() %></td>
                <td style="text-align:center;">
                   <% if ("COMPLETADA".equals(estadoFase)) { %>
                      <span style="font-weight:700; color:var(--success-text);"><%= f.getPiezasCompletadas() %> / <%= f.getCantidadPiezas() %></span>
                   <% } else { %>
                      <span style="color:var(--text-muted);">0 / <%= f.getCantidadPiezas() %></span>
                   <% } %>
                </td>
                <td>
                  <% String prevEst = f.getFasePreviaEstado(); %>
                  <% if (prevEst == null) { %><span class="chip chip-completado"><i class='bx bx-check'></i> 1ra Fase</span>
                  <% } else if ("COMPLETADA".equalsIgnoreCase(prevEst)) { %><span class="chip chip-completado"><i class='bx bx-check-double'></i> Lista</span>
                  <% } else if ("EN_PROCESO".equalsIgnoreCase(prevEst)) { %><span class="chip chip-proceso"><i class='bx bx-loader-alt'></i> En Proceso</span>
                  <% } else { %><span class="chip chip-pendiente"><i class='bx bx-time-five'></i> <%= prevEst %></span><% } %>
                </td>
                <td><strong><%= f.getNombreFase() %></strong></td>
                <td>
                  <% if (f.getNombreMaquinista() != null && !f.getNombreMaquinista().isBlank()) { %><%= f.getNombreMaquinista() %>
                  <% } else { %><span style="color:var(--text-light); font-style:italic;">Sin asignar</span><% } %>
                </td>
                <td style="text-align:center;">
                    <% if ("COMPLETADA".equals(estadoFase)) { %><span class="chip chip-completado">Completada</span>
                    <% } else if ("EN_PROCESO".equals(estadoFase)) { %><span class="chip chip-proceso">En Proceso</span>
                    <% } else if (bloqueado) { %><span class="chip chip-bloqueado"><i class='bx bx-lock'></i> Bloqueado</span>
                    <% } else { %><span class="chip chip-pendiente">Pendiente</span><% } %>
                </td>
                <td style="text-align:center;">
                    <% if ("COMPLETADA".equals(estadoFase)) { %>
                      <span class="btn-bloqueado-label" style="background:var(--success-bg); color:var(--success-text);"><i class='bx bx-check'></i> Lista</span>
                    <% } else if ("EN_PROCESO".equals(estadoFase)) { %>
                    <div style="display: flex; gap: 6px; justify-content:center;">
                        <span class="btn-bloqueado-label" style="background:var(--warning-bg); color:var(--warning-text);"><i class='bx bx-loader-alt'></i> Proceso</span>
                        <% if (usuarioSesion.getIdRol() == 1 || usuarioSesion.getIdRol() == 3 || usuarioSesion.getIdRol() == 5) { %>
                            <button class="btn-asignar" style="background:var(--info-text);" onclick="abrirModalReasignar(<%= f.getIdAsignacion() %>, '<%= codigoOt.replace("'", "\\'") %>', '<%= f.getNombrePieza() != null ? f.getNombrePieza().replace("'", "\\'") : "PRENDA COMPLETA" %>', '<%= f.getNombreFase().replace("'", "\\'") %>', <%= f.getIdMaquinista() %>, false)"><i class='bx bx-refresh'></i> Reasignar</button>
                        <% } %>
                    </div>
                    <% } else if (bloqueado) { %>
                      <span class="btn-bloqueado-label"><i class='bx bx-lock'></i> Bloqueado</span>
                    <% } else { %>
                      <button class="btn-asignar" onclick="abrirModal(<%= f.getIdAsignacion() %>, '<%= codigoOt %>', '<%= f.getNombrePieza() != null ? f.getNombrePieza() : "PRENDA COMPLETA" %>', '<%= f.getNombreFase() %>', false)"><i class='bx bx-wrench'></i> Asignar</button>
                    <% } %>
                  </td>
                  <td>
                    <% String tipo = f.getTipoTarea();
                        if ("REPOSICION".equals(tipo)) { %><span class="chip" style="background:#fef3c7; color:#b45309;">Reposición</span>
                    <% } else if ("ENSAMBLAJE".equals(tipo)) { %><span class="chip" style="background:#e0e7ff; color:#3730a3;">Ensamblaje</span>
                    <% } else { %><span class="chip chip-pendiente">Normal</span><% } %>
                  </td>
              </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      <% otIdx++; } %>
      <% } %>
    </div>
  </div>
</main>

<div class="overlay" id="overlayAsignacion">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-wrench'></i> Asignar Maquinista a Fase</h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>

    <div id="alertaBloqueo" class="alerta-bloqueo">
      <strong><i class='bx bx-error'></i> Operación Bloqueada:</strong> La fase previa no ha sido reportada como completada.
    </div>

    <div class="info-panel">
      <div><span>Orden</span><strong id="lbl-ot"></strong></div>
      <div><span>Pieza</span><strong id="lbl-pieza"></strong></div>
      <div><span>Fase</span><strong id="lbl-fase" style="color:var(--color-primary);"></strong></div>
    </div>

    <form method="post" action="<%= request.getContextPath() %>/cargas-trabajo" onsubmit="return validarForm()">
      <input type="hidden" name="accion" id="modal-accion" value="asignar">
      <input type="hidden" name="idAsignacion" id="hdn-idAsignacion">
      
      <div class="field">
          <label>Maquinista Disponible <span class="req">*</span></label>
          <select name="idMaquinista" id="sel-maquinista" class="form-control" required>
            <option value="">-- Seleccione el maquinista --</option>
            <% for (Usuario m : maquinistas) { %><option value="<%= m.getIdUsuario() %>"><%= m.getNombreCompleto() %></option><% } %>
            <% if (maquinistas.isEmpty()) { %><option disabled>No hay maquinistas registrados</option><% } %>
          </select>
      </div>

      <button type="submit" id="btn-guardar" class="btn-guardar"><i class='bx bx-check'></i> Confirmar Asignación</button>
    </form>
  </div>
</div>

<div id="modalCompletar" class="overlay" style="display:none">
    <div class="modal-box">
        <div class="modal-header">
            <h3 id="modalTitulo"><i class='bx bx-check-shield'></i> Completar Tarea</h3>
            <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
        </div>
        <p id="modalDescripcion"></p>

        <form id="formCompletar" method="post" action="${pageContext.request.contextPath}/cargas-trabajo">
            <input type="hidden" name="accion"       value="completar">
            <input type="hidden" name="idAsignacion" id="hiddenIdAsig">
            <input type="hidden" name="cierreManual" id="hiddenCierreManual" value="">

            <div class="field">
                <label>Cantidad completada:</label>
                <input type="number" name="piezasCompletadas" id="inputCantidad" min="1" required class="form-control">
                <p id="metaInfo" style="font-size:0.82rem; color:var(--text-muted);"></p>
            </div>

            <div id="seccionCierreManual" style="display:none; margin-top:16px; background:var(--warning-bg); border-left:4px solid #f59e0b; padding:12px; border-radius:6px;">
                <p style="font-size:0.85rem; color:#856404; font-weight:600;"><i class='bx bx-error'></i> La cantidad ingresada es menor a la meta.</p>
                <p style="font-size:0.82rem; color:#555; margin-top:4px;">El sistema generará reposición. Activa esto para cierre forzado:</p>
                <label style="display:flex; align-items:center; gap:8px; margin-top:8px; cursor:pointer; font-weight:600; color:#856404; font-size:0.84rem;">
                    <input type="checkbox" id="chkCierreManual" onchange="document.getElementById('hiddenCierreManual').value = this.checked ? 'SI' : ''" style="accent-color:#d97706;">
                    Autorizar cierre manual (solo supervisor)
                </label>
            </div>

            <div style="display:flex; gap:10px; margin-top:24px; justify-content:flex-end;">
                <button type="button" onclick="cerrarModal()" class="btn-cancelar">Cancelar</button>
                <button type="submit" class="btn-guardar" style="width:auto;"><i class='bx bx-check'></i> Confirmar</button>
            </div>
        </form>
    </div>
</div>

<script>
// JS INTACTO - LÓGICA MANTENIDA
  function abrirModal(idAsignacion, ot, pieza, fase, bloqueado) {
    document.getElementById('lbl-ot').textContent   = ot;
    document.getElementById('lbl-pieza').textContent = pieza;
    document.getElementById('lbl-fase').textContent  = fase;
    document.getElementById('hdn-idAsignacion').value = idAsignacion;
    document.getElementById('modal-accion').value = 'asignar';
    var alerta = document.getElementById('alertaBloqueo');
    var btn    = document.getElementById('btn-guardar');
    var sel    = document.getElementById('sel-maquinista');

    if (bloqueado) { alerta.style.display = 'block'; btn.disabled = true; sel.disabled = true; } 
    else { alerta.style.display = 'none'; btn.disabled = false; sel.disabled = false; }
    document.getElementById('overlayAsignacion').classList.add('activo');
  }

  function cerrarModal() {
    document.getElementById('overlayAsignacion').classList.remove('activo');
    document.getElementById('modalCompletar').style.display = 'none';
  }

  document.getElementById('overlayAsignacion').addEventListener('click', function(e) { if (e.target === this) cerrarModal(); });
  function validarForm() {
    var sel = document.getElementById('sel-maquinista');
    if (!sel.value) { alert('Por favor seleccione un maquinista.'); sel.focus(); return false; }
    return true;
  }

  function toggleGrupo(id) {
        var detalle = document.getElementById(id);
        var icono   = document.getElementById('ico-' + id);
        if (!detalle) return;
        var isOpen = detalle.classList.toggle('open');
        if (icono) { if(isOpen) { icono.classList.remove('bx-chevron-right'); icono.classList.add('bx-chevron-down'); icono.style.color="var(--color-primary)"; } else { icono.classList.remove('bx-chevron-down'); icono.classList.add('bx-chevron-right'); icono.style.color="var(--text-muted)"; } }
  }

    var _todoExpandido = false;
    function toggleTodos() {
        var detalles = document.querySelectorAll('.fases-detalle');
        var iconos   = document.querySelectorAll('.ot-toggle-icon');
        var txt      = document.getElementById('txt-expand');
        _todoExpandido = !_todoExpandido;
        detalles.forEach(function(d) { if (_todoExpandido) { d.classList.add('open'); } else { d.classList.remove('open'); } });
        iconos.forEach(function(i) { 
            if (_todoExpandido) { i.classList.remove('bx-chevron-right'); i.classList.add('bx-chevron-down'); i.style.color="var(--color-primary)"; } 
            else { i.classList.remove('bx-chevron-down'); i.classList.add('bx-chevron-right'); i.style.color="var(--text-muted)"; } 
        });
        if (txt) txt.textContent = _todoExpandido ? 'Colapsar todo' : 'Expandir todo';
    }

    function cargarOpcionesMaquinista() {
        const maquinistasSet = new Set();
        document.querySelectorAll('.fases-detalle tbody tr').forEach(row => {
            const celda = row.cells[5]; 
            let nombre = celda ? celda.innerText.trim() : '';
            if (nombre && nombre !== 'Sin asignar') maquinistasSet.add(nombre);
        });
        maquinistasSet.add('Sin asignar');
        const select = document.getElementById('filtroMaquinista');
        select.innerHTML = '<option value="">-- Todos --</option>';
        Array.from(maquinistasSet).sort().forEach(nombre => {
            const opt = document.createElement('option');
            opt.value = nombre;
            opt.textContent = nombre;
            select.appendChild(opt);
        });
    }

    function aplicarFiltros() {
        const filtroOt = document.getElementById('filtroOt').value.trim().toLowerCase();
        const filtroMaq = document.getElementById('filtroMaquinista').value;
        const filtroEstado = document.getElementById('filtroEstado').value;
        const filtroPieza = document.getElementById('filtroPieza').value.trim().toLowerCase();
        const grupos = document.querySelectorAll('.ot-row');
        grupos.forEach(grupo => {
            const otCodigo = grupo.querySelector('.ot-codigo')?.innerText.trim().toLowerCase() || '';
            const detalle = grupo.nextElementSibling;
            if (!detalle || !detalle.classList.contains('fases-detalle')) return;
            const tabla = detalle.querySelector('table');
            if (!tabla) return;
            let algunaVisible = false;
            const filas = tabla.querySelectorAll('tbody tr');
            filas.forEach(fila => {
                const pieza = fila.cells[0]?.innerText.trim().toLowerCase() || '';
                const maquinista = fila.cells[5]?.innerText.trim() || '';
                const estadoSpan = fila.cells[6]?.querySelector('span.chip');
                const estado = estadoSpan ? estadoSpan.innerText.trim() : '';
                let estadoValue = '';
                if (estado.includes('Pendiente')) estadoValue = 'PENDIENTE';
                else if (estado.includes('Proceso')) estadoValue = 'EN_PROCESO';
                else if (estado.includes('Completada')) estadoValue = 'COMPLETADA';
                else if (estado.includes('Bloqueado')) estadoValue = 'BLOQUEADO';

                let visible = true;
                if (filtroOt && !otCodigo.includes(filtroOt)) visible = false;
                if (filtroMaq && maquinista !== filtroMaq) visible = false;
                if (filtroEstado && estadoValue !== filtroEstado) visible = false;
                if (filtroPieza && !pieza.includes(filtroPieza)) visible = false;

                fila.style.display = visible ? '' : 'none';
                if (visible) algunaVisible = true;
            });
            grupo.style.display = algunaVisible ? '' : 'none';
            const hayFiltros = filtroOt || filtroMaq || filtroEstado || filtroPieza;
            if (algunaVisible && hayFiltros) {
                if (!detalle.classList.contains('open')) {
                    detalle.classList.add('open');
                    const icono = grupo.querySelector('.ot-toggle-icon');
                    if (icono) { icono.classList.remove('bx-chevron-right'); icono.classList.add('bx-chevron-down'); }
                }
            }
        });
    }

    function limpiarFiltros() {
        document.getElementById('filtroOt').value = '';
        document.getElementById('filtroMaquinista').value = '';
        document.getElementById('filtroEstado').value = '';
        document.getElementById('filtroPieza').value = '';
        aplicarFiltros();
    }

    document.addEventListener('DOMContentLoaded', () => {
        cargarOpcionesMaquinista();
        aplicarFiltros();
        const inputs = ['filtroOt', 'filtroMaquinista', 'filtroEstado', 'filtroPieza'];
        inputs.forEach(id => {
            const el = document.getElementById(id);
            if (el) el.addEventListener('change', aplicarFiltros);
            if (el && (el.tagName === 'INPUT')) el.addEventListener('keyup', aplicarFiltros);
        });
        document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltros);
        
        actualizarNotificaciones();
        setInterval(actualizarNotificaciones, 30000);
        document.querySelector('.notificacion-icon').addEventListener('click', toggleNotificaciones);
    });

    function abrirModalReasignar(idAsignacion, ot, pieza, fase, idMaquinistaActual, bloqueado) {
        document.getElementById('lbl-ot').textContent = ot;
        document.getElementById('lbl-pieza').textContent = pieza;
        document.getElementById('lbl-fase').textContent = fase;
        document.getElementById('hdn-idAsignacion').value = idAsignacion;
        document.getElementById('modal-accion').value = 'reasignar';
        const select = document.getElementById('sel-maquinista');
        if (select && idMaquinistaActual > 0) {
            for (let i = 0; i < select.options.length; i++) {
                if (parseInt(select.options[i].value) === idMaquinistaActual) {
                    select.selectedIndex = i; break;
                }
            }
        } else { select.selectedIndex = 0; }

        const alerta = document.getElementById('alertaBloqueo');
        const btn = document.getElementById('btn-guardar');
        if (bloqueado) { alerta.style.display = 'block'; btn.disabled = true; select.disabled = true; } 
        else { alerta.style.display = 'none'; btn.disabled = false; select.disabled = false; }
        document.getElementById('overlayAsignacion').classList.add('activo');
    }

function actualizarNotificaciones() {
    fetch('<%= request.getContextPath() %>/notificaciones?accion=listarNoLeidas')
        .then(res => res.json())
        .then(data => {
            const badge = document.getElementById('notif-badge');
            if (data.length > 0) {
                badge.textContent = data.length;
                badge.style.display = 'inline-block';
            } else { badge.style.display = 'none'; }
        }).catch(console.error);
}

function toggleNotificaciones() {
    const panel = document.getElementById('notif-panel');
    if (panel.style.display === 'none') {
        document.getElementById('notif-list').innerHTML = '<div style="padding:16px; text-align:center; color:var(--text-muted);"><i class="bx bx-loader-alt bx-spin"></i> Cargando...</div>';
        panel.style.display = 'block';
        fetch('<%= request.getContextPath() %>/notificaciones?limite=20')
            .then(res => { if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
            .then(data => {
                const listaDiv = document.getElementById('notif-list');
                listaDiv.innerHTML = '';
                if (data.length === 0) { listaDiv.innerHTML = '<div style="padding:16px; text-align:center; color:var(--text-muted);">No hay notificaciones</div>'; return; }
                
                data.forEach(notif => {
                    const div = document.createElement('div');
                    div.style.padding = '12px 16px';
                    div.style.borderBottom = '1px solid var(--border-color)';
                    div.style.backgroundColor = notif.leida ? '#ffffff' : '#f0f4f8'; 
                    const fontWeight = notif.leida ? 'normal' : '600';
                    const colorTit = notif.leida ? 'var(--text-muted)' : 'var(--color-primary)';
                    const colorMsj = notif.leida ? 'var(--text-muted)' : 'var(--text-main)';
                    const titulo = notif.titulo || 'Notificación';
                    const mensaje = notif.mensaje || 'Sin detalles';
                    const fechaStr = notif.fecha ? new Date(notif.fecha).toLocaleString() : '';
                    div.innerHTML = 
                        '<strong style="color:' + colorTit + '; font-size:0.85rem; display:block; font-weight:' + fontWeight + ';">' + titulo + '</strong>' +
                        '<small style="color:var(--text-light); font-size:0.75rem;">' + fechaStr + '</small>' +
                        '<p style="margin:6px 0 0; font-size:0.85rem; color:' + colorMsj + '; line-height:1.4;">' + mensaje + '</p>';
                    listaDiv.appendChild(div);
                    if (!notif.leida && notif.id) { fetch('<%= request.getContextPath() %>/notificaciones?accion=marcarLeida&id=' + notif.id); }
                });
                actualizarNotificaciones();
            }).catch(err => {
                document.getElementById('notif-list').innerHTML = '<div style="padding:16px; color:var(--danger-hover); text-align:center;"><i class="bx bx-error"></i> Error al cargar data</div>';
            });
    } else { panel.style.display = 'none'; }
}

function abrirModalCompletar(idAsig, meta, tipoTarea, rolUsuario) {
    document.getElementById('hiddenIdAsig').value = idAsig;
    document.getElementById('hiddenCierreManual').value = '';
    document.getElementById('chkCierreManual').checked = false;
    document.getElementById('inputCantidad').max = meta;
    document.getElementById('metaInfo').textContent = 'Meta: ' + meta + ' unidades.';
    let esEnsamblaje = (tipoTarea === 'ENSAMBLAJE');
    let esSupervisor = (rolUsuario === 5 || rolUsuario === 1); 

    document.getElementById('modalTitulo').innerHTML = esEnsamblaje ? "<i class='bx bx-check-double'></i> Completar Ensamblaje Final" : "<i class='bx bx-check-shield'></i> Completar Tarea";

    document.getElementById('inputCantidad').oninput = function() {
        let val = parseInt(this.value) || 0;
        let mostrar = esEnsamblaje && esSupervisor && val < meta && val > 0;
        document.getElementById('seccionCierreManual').style.display = mostrar ? 'block' : 'none';
        if (!mostrar) { document.getElementById('hiddenCierreManual').value = ''; document.getElementById('chkCierreManual').checked = false; }
    };
    document.getElementById('modalCompletar').style.display = 'flex';
}
// Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>
</body>
</html>