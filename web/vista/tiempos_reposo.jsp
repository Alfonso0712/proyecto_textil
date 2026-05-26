<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean puedeVer     = permisos.contains("PROD_REPOSO_VER");
    boolean puedeGestion = permisos.contains("PROD_REPOSO_GESTION");
    boolean esAdmin      = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean verAlmacen   = permisos.contains("ALM_TELA_VER");
    boolean verProduccion= permisos.contains("PROD_OT_VER");
    boolean verSeguridad = permisos.contains("SEG_USUARIOS_VER");

    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    @SuppressWarnings("unchecked")
    List<TiempoReposo> reposoList    = (List<TiempoReposo>) request.getAttribute("reposoList");
    @SuppressWarnings("unchecked")
    List<Tela>         telasDisp     = (List<Tela>)         request.getAttribute("telasDisponibles");
    if (reposoList  == null) reposoList  = new ArrayList<>();
    if (telasDisp   == null) telasDisp   = new ArrayList<>();

    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");
    String errorBD      = (String) request.getAttribute("errorBD");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tiempos de Reposo – Sistema Textil</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>

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
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; height: 100vh; overflow: hidden; color: var(--text-main); }

    /* ── SIDEBAR ── */
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
    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    /* ── ALERTAS ── */
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 24px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-err { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }
    .alerta-warn { background: var(--warning-bg); color: var(--warning-text); border: 1px solid #fcd34d; }

    /* ── TOOLBAR Y FILTROS ── */
    .toolbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; margin-bottom: 20px; }
    .toolbar h3 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s; font-family: 'Inter', sans-serif;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }

    /* ── BOTONES ── */
    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); }
    .btn-outline:hover { background: var(--color-bg); }
    .btn-success { background: #16a34a; color: #fff; }
    .btn-success:hover { background: #15803d; }
    .btn-danger { background: var(--danger-bg); color: var(--danger-text); }
    .btn-danger:hover { background: #fca5a5; color: #7f1d1d; }
    .btn-sm { padding: 0.35rem 0.8rem; font-size: 0.78rem; }
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; background: var(--danger-bg); color: var(--danger-text);}
    .btn-icon:hover { background: #fca5a5; color: #7f1d1d; }

    /* ── CARDS DE REPOSO ── */
    .grid-reposo { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; margin-bottom: 30px; }
    .card-reposo { background: var(--color-surface); border-radius: var(--radius-md); padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); border-left: 4px solid var(--color-primary); }
    .card-reposo.apto { border-left-color: var(--success-text); }
    .card-reposo h4 { font-size: 1rem; color: var(--color-secondary); margin-bottom: 4px; font-weight: 700; display:flex; align-items:center; gap:6px;}
    .card-reposo .sub { font-size: 0.78rem; color: var(--text-muted); margin-bottom: 12px; font-family:monospace; }
    
    .progress-wrap { background: var(--color-bg); border-radius: 20px; height: 8px; overflow: hidden; margin: 8px 0 12px; border: 1px solid var(--border-color); }
    .progress-bar { height: 100%; border-radius: 20px; background: var(--color-primary); transition: width 1s linear; }
    .progress-bar.done { background: var(--success-text); }
    
    .card-meta { font-size: 0.75rem; color: var(--text-muted); display: flex; justify-content: space-between; align-items:center; }
    .card-acciones { display: flex; gap: 8px; margin-top: 16px; flex-wrap: wrap; }
    
    .badge-estado { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 12px; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; text-align: center; }
    .est-reposo { background: var(--info-bg); color: var(--info-text); }
    .est-apto   { background: var(--success-bg); color: var(--success-text); }
    .est-cancel { background: var(--color-bg); color: var(--text-muted); }

    /* ── TABLA HISTORIAL ── */
    .card-historial { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow: hidden; }
    .card-header { padding: 16px 20px; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; background: #f8fafc;}
    .card-header h4 { font-size: 0.95rem; color: var(--color-secondary); display:flex; align-items:center; gap:6px;}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:hover td { background: #f8fafc; }
    .text-center { text-align: center; }
    .empty { text-align: center; padding: 40px; color: var(--text-muted); font-size: 0.85rem; }

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: 1rem; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 520px; max-height: 92vh; display: flex; flex-direction: column; box-shadow: 0 20px 40px rgba(0,0,0,0.15); overflow: hidden; }
    .modal-header { background: var(--color-secondary); padding: 1rem 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
    .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; display:flex; align-items:center; gap:8px; font-weight:600;}
    .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: 0.2s; }
    .modal-close:hover { color: #fff; }
    .modal-body { padding: 1.5rem 2rem; overflow-y: auto; flex: 1; min-height: 0; }
    .modal-footer { padding: 1rem 2rem; border-top: 1px solid var(--border-color); display: flex; gap: 12px; justify-content: flex-end; flex-shrink: 0; background: #f8fafc; }
    
    .form-group { margin-bottom: 1.2rem; }
    .form-group label { display: block; font-size: 0.82rem; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
    .hint { font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

    /* ── NOTIFICACION FLOTANTE ── */
    #notif-banner { position: fixed; top: 20px; right: 20px; background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; padding: 16px 20px; border-radius: var(--radius-md); box-shadow: 0 4px 16px rgba(0,0,0,0.1); font-size: 0.88rem; font-weight: 600; z-index: 9999; display: none; animation: slideIn 0.3s ease; display:none; align-items:center; gap:8px;}
    @keyframes slideIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
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
        <% if (_navRep)  { %><a href="<%= _cp %>/tiempos-reposo" class="menu-link activo">Tiempos de Reposo</a><% } %>
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
  </nav>
</aside>

<main>
  <header>
    <h2><i class='bx bx-time-five'></i> Gestión de Tiempos de Reposo</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge-rol"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
    </div>
  </header>

  <div class="contenido">
    <%
      String msgExito = null;
      if ("iniciado".equals(mensajeExito)) msgExito = "Inicio de reposo registrado correctamente.";
      else if ("apto".equals(mensajeExito)) msgExito = "Tela marcada como APTA PARA CORTE. Notificación emitida.";
      else if ("cancelado".equals(mensajeExito)) msgExito = "Reposo cancelado.";
      else if ("eliminado".equals(mensajeExito)) msgExito = "Registro de reposo eliminado correctamente.";
    %>
    <% if (msgExito != null) { %>
    <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= msgExito %></div>
    <% } %>
    <% if (mensajeError != null && !mensajeError.isEmpty() && !"sinPermiso".equals(mensajeError)) { %>
    <div class="alerta alerta-err"><i class='bx bx-error-circle'></i> Ocurrió un error al procesar la solicitud (código: <%= mensajeError %>). Intente nuevamente.</div>
    <% } %>
    <% if (errorBD != null) { %>
    <div class="alerta alerta-err"><i class='bx bx-error'></i> <%= errorBD %></div>
    <% } %>

    <div class="toolbar">
      <h3>Tiempos de Reposo <%= esAdmin ? "<span style='font-size:0.8rem;color:var(--text-muted);font-weight:normal;'>(Vista Admin – todos los usuarios)</span>" : "" %></h3>
      <% if (puedeGestion) { %>
      <button class="btn btn-primary" onclick="abrirModalInicio()">
        <i class='bx bx-plus'></i> Registrar Inicio de Reposo
      </button>
      <% } %>
    </div>

    <%
      List<TiempoReposo> activos = new ArrayList<>();
      List<TiempoReposo> historial = new ArrayList<>();
      for (TiempoReposo tr : reposoList) {
          if (tr.getEstado() == TiempoReposo.Estado.EN_REPOSO) activos.add(tr);
          else historial.add(tr);
      }
    %>

    <% if (!activos.isEmpty()) { %>
    <p style="font-size:0.8rem; color:var(--text-muted); margin-bottom:12px; display:flex; align-items:center; gap:6px;">
      <i class='bx bx-refresh'></i> Las tarjetas se actualizan automáticamente cada 30 segundos.
    </p>
    <div class="grid-reposo" id="grid-activos">
      <% for (TiempoReposo tr : activos) { %>
      <div class="card-reposo" id="card-<%= tr.getIdReposo() %>">
        <h4><i class='bx bx-box'></i> <%= tr.getCodigoTela() %></h4>
        <div class="sub">OT: <%= tr.getCodigoOt() %>
          <% if (tr.getTipoTejido() != null) { %> &nbsp;|&nbsp; <%= tr.getTipoTejido() %><% } %>
        </div>

        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
          <span style="font-size:0.78rem; color:var(--text-main);">Progreso</span>
          <span style="font-size:0.78rem; font-weight:700; color:var(--color-primary);" id="pct-<%= tr.getIdReposo() %>"><%= tr.getPorcentajeCompletado() %>%</span>
        </div>
        <div class="progress-wrap">
          <div class="progress-bar" id="bar-<%= tr.getIdReposo() %>" style="width:<%= tr.getPorcentajeCompletado() %>%"></div>
        </div>

        <div class="card-meta" style="margin-bottom:8px;">
          <span><i class='bx bx-time'></i> Inicio: <%= tr.getFechaInicio() != null ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(tr.getFechaInicio()) : "-" %></span>
          <span id="rest-<%= tr.getIdReposo() %>"><i class='bx bx-timer'></i> Restan: <%= tr.getMinutosRestantes() %> min</span>
        </div>
        <div class="card-meta">
          <span>Por: <%= tr.getNombreRegistrador() %></span>
          <span class="badge-estado est-reposo">EN REPOSO</span>
        </div>

        <% if (puedeGestion) { %>
        <div class="card-acciones">
          <form method="post" action="<%= request.getContextPath() %>/tiempos-reposo" style="display:inline" onsubmit="return confirm('¿Marcar esta tela como APTA PARA CORTE?')">
            <input type="hidden" name="accion" value="apto">
            <input type="hidden" name="idReposo" value="<%= tr.getIdReposo() %>">
            <button type="submit" class="btn btn-success btn-sm"><i class='bx bx-check'></i> Marcar Apta</button>
          </form>
          <form method="post" action="<%= request.getContextPath() %>/tiempos-reposo" style="display:inline" onsubmit="return confirm('¿Cancelar este reposo?')">
            <input type="hidden" name="accion" value="cancelar">
            <input type="hidden" name="idReposo" value="<%= tr.getIdReposo() %>">
            <button type="submit" class="btn btn-outline btn-sm" style="color:var(--danger-text); border-color:var(--danger-text);"><i class='bx bx-x'></i> Cancelar</button>
          </form>
        </div>
        <% } %>
      </div>
      <% } %>
    </div>
    <% } else { %>
        <% if (!telasDisp.isEmpty()) { %>
            <div class="alerta alerta-warn" style="margin-bottom:24px;">
               <i class='bx bx-info-circle'></i> No hay telas actualmente en reposo.
               <% if (puedeGestion) { %>Para iniciar un reposo, haz clic en <strong>Registrar Inicio de Reposo</strong>.<% } %>
            </div>
        <% } else { %>
            <div class="alerta alerta-ok" style="margin-bottom:24px;">
              <i class='bx bx-check-circle'></i> No hay telas pendientes de reposo en el inventario. Todas las telas que requieren reposo ya fueron procesadas o aún no se han registrado.
            </div>
        <% } %>
    <% } %>

    <div class="filtro-wrap">
      <div style="display: flex; align-items: center; gap: 8px;">
        <label style="font-size:0.85rem; font-weight:600;">Estado:</label>
        <select id="filtroEstado" class="form-control" style="width: auto; min-width: 130px; padding:0.4rem 0.8rem;">
          <option value="">-- Todos --</option>
          <option value="APTO_CORTE">APTO CORTE</option>
          <option value="CANCELADO">CANCELADO</option>
        </select>
      </div>

      <div style="display: flex; align-items: center; gap: 8px;">
        <label style="font-size:0.85rem; font-weight:600;">Usuario:</label>
        <select id="filtroUsuario" class="form-control" style="width: auto; min-width: 150px; padding:0.4rem 0.8rem;">
          <option value="">-- Todos --</option>
        </select>
      </div>

      <div style="display: flex; align-items: center; gap: 8px;">
        <input type="text" id="filtroOt" class="form-control" placeholder="Código OT" style="width: 140px; padding:0.4rem 0.8rem;">
      </div>

      <div style="display: flex; align-items: center; gap: 8px;">
        <input type="text" id="filtroTejido" class="form-control" placeholder="Tipo de tejido" style="width: 150px; padding:0.4rem 0.8rem;">
      </div>

      <button id="btnLimpiarFiltros" class="btn btn-outline btn-sm">
        <i class='bx bx-eraser'></i> Limpiar
      </button>
    </div>

    <div class="card-historial">
      <div class="card-header">
        <h4><i class='bx bx-history'></i> Historial de Reposos</h4>
        <span style="font-size:0.78rem; color:var(--text-muted);" id="contadorHistorial"><%= historial.size() %> registro(s)</span>
      </div>
      <% if (historial.isEmpty()) { %>
      <div class="empty">Sin historial de reposos completados o cancelados.</div>
      <% } else { %>
      <div style="overflow-x:auto">
        <table id="tablaHistorial">
          <thead>
            <tr>
              <th class="text-center">#</th>
              <th>Tela</th>
              <th>OT</th>
              <th>Tejido</th>
              <th>Inicio</th>
              <th>Fin estimado</th>
              <th>Fin real</th>
              <th class="text-center">Duración (min)</th>
              <th class="text-center">Estado</th>
              <th class="text-center">Notif.</th>
              <th>Registrado por</th>
              <% if (esAdmin) { %><th class="text-center">Acción</th><% } %>
            </tr>
          </thead>
          <tbody>
            <% for (TiempoReposo tr : historial) { %>
            <tr>
              <td class="text-center" style="color:var(--text-muted);"><%= tr.getIdReposo() %></td>
              <td><strong style="color:var(--color-primary); font-family:monospace;"><%= tr.getCodigoTela() %></strong></td>
              <td><span style="font-family:monospace;"><%= tr.getCodigoOt() %></span></td>
              <td><%= tr.getTipoTejido() != null ? tr.getTipoTejido() : "—" %></td>
              <td style="font-size:0.78rem; color:var(--text-muted);"><%= tr.getFechaInicio() != null ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(tr.getFechaInicio()) : "—" %></td>
              <td style="font-size:0.78rem; color:var(--text-muted);"><%= tr.getFechaFinEstimada() != null ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(tr.getFechaFinEstimada()) : "—" %></td>
              <td style="font-size:0.78rem; color:var(--text-muted);"><%= tr.getFechaFinReal() != null ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(tr.getFechaFinReal()) : "—" %></td>
              <td class="text-center" style="font-weight:600;"><%= tr.getDuracionMinutos() %></td>
              <td class="text-center">
                <%
                  String estadoCss = "est-reposo", estadoLabel = "EN REPOSO";
                  if (tr.getEstado() == TiempoReposo.Estado.APTO_CORTE) {
                      estadoCss = "est-apto"; estadoLabel = "APTO CORTE";
                  } else if (tr.getEstado() == TiempoReposo.Estado.CANCELADO) {
                      estadoCss = "est-cancel"; estadoLabel = "CANCELADO";
                  }
                %>
                <span class="badge-estado <%= estadoCss %>"><%= estadoLabel %></span>
              </td>
              <td class="text-center">
                <%= tr.isNotificacionEnviada() ? "<i class='bx bx-check' style='color:var(--success-text); font-size:1.1rem;'></i>" : "<i class='bx bx-x' style='color:var(--danger-text); font-size:1.1rem;'></i>" %>
              </td>
              <td style="font-size:0.8rem;"><%= tr.getNombreRegistrador() %></td>
              <% if (esAdmin) { %>
              <td class="text-center">
                  <form method="post" action="<%= request.getContextPath() %>/tiempos-reposo"
                        onsubmit="return confirm('¿Eliminar permanentemente este registro de reposo? Esta acción no se puede deshacer.');">
                    <input type="hidden" name="accion" value="eliminar">
                    <input type="hidden" name="idReposo" value="<%= tr.getIdReposo() %>">
                    <button type="submit" class="btn-icon delete" title="Eliminar registro"><i class='bx bx-trash'></i></button>
                  </form>
              </td>
              <% } %>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
      <% } %>
    </div>
  </div>
</main>

<div class="overlay" id="overlay-inicio">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3><i class='bx bx-timer'></i> Registrar Inicio de Reposo</h3>
      <button type="button" class="modal-close" onclick="cerrarModal('overlay-inicio')">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/tiempos-reposo" onsubmit="return validarFormInicio()">
      <input type="hidden" name="accion" value="iniciar">
      <div class="modal-body">

        <div class="form-group">
          <label for="idTela">Tela del inventario <span class="req">*</span></label>
          <select name="idTela" id="idTela" class="form-control" required onchange="autocompletarTiempo()">
            <option value="">-- Selecciona una tela --</option>
            <% for (Tela t : telasDisp) { %>
            <option value="<%= t.getIdTela() %>" data-tiempo="<%= t.getTiempoReposoCatalogo() %>">
              <%= t.getCodigoTela() %>
              <%= t.getCodigoOt() != null ? " | OT: " + t.getCodigoOt() : "" %>
              <%= t.getTipoTejido() != null ? " | " + t.getTipoTejido() : "" %>
            </option>
            <% } %>
          </select>
          <% if (telasDisp.isEmpty()) { %>
          <div class="hint" style="color:var(--danger-text);">⚠️ No hay telas registradas en el inventario.</div>
          <% } else { %>
          <div class="hint">Se muestran todas las telas registradas en el inventario.</div>
          <% } %>
        </div>

        <div class="form-group">
          <label>Duración del reposo <span class="req">*</span></label>
          <div class="grid-2">
            <div>
              <input type="number" name="horas" id="horas" class="form-control" min="0" max="168" value="1" placeholder="Horas">
              <div class="hint">Horas (0 – 168)</div>
            </div>
            <div>
              <input type="number" name="minutos" id="minutos" class="form-control" min="0" max="59" value="0" placeholder="Minutos">
              <div class="hint">Minutos (0 – 59)</div>
            </div>
          </div>
          <input type="hidden" name="duracionMinutos" id="duracionMinutos" value="60">
        </div>

        <div class="form-group">
          <label for="observaciones">Observaciones</label>
          <textarea name="observaciones" id="observaciones" class="form-control" rows="3" placeholder="Ej: Tela de alto gramaje, requiere reposo extendido..."></textarea>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal('overlay-inicio')"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-play'></i> Iniciar Reposo</button>
      </div>
    </form>
  </div>
</div>

<div id="notif-banner"><i class='bx bx-check-circle' style="font-size:1.2rem;"></i> ¡Tela(s) lista(s) para corte! Revisa el módulo.</div>

<script>
  // UI MENÚ ACORDEÓN
  function toggleSubmenu(element) {
      element.parentElement.classList.toggle('active');
  }

  // ── Modal helpers ──
  function abrirModalInicio() { document.getElementById('overlay-inicio').classList.add('activo'); }
  function cerrarModal(id) { document.getElementById(id).classList.remove('activo'); }
  document.querySelectorAll('.overlay').forEach(function(ov) {
    ov.addEventListener('click', function(e) { if (e.target === ov) cerrarModal(ov.id); });
  });

  // ── Validación formulario ──
  function validarFormInicio() {
    var tela    = document.getElementById('idTela').value;
    var horas   = parseInt(document.getElementById('horas').value)   || 0;
    var minutos = parseInt(document.getElementById('minutos').value) || 0;
    var total   = (horas * 60) + minutos;

    if (!tela) { alert('Selecciona una tela.'); return false; }
    if (total < 1) { alert('La duración debe ser al menos 1 minuto.'); return false; }
    if (total > 10080) { alert('La duración no puede superar 7 días (10080 minutos).'); return false; }

    document.getElementById('duracionMinutos').value = total;
    return true;
  }

  // ── Polling ──
  var estadosAnteriores = {};
  var contexto = '<%= request.getContextPath() %>';

  function actualizarTarjetas() {
    fetch(contexto + '/tiempos-reposo?accion=polling')
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.reposos) return;
        var hayNuevoApto = false;

        data.reposos.forEach(function(r) {
          var bar  = document.getElementById('bar-'  + r.id);
          var pct  = document.getElementById('pct-'  + r.id);
          var rest = document.getElementById('rest-' + r.id);

          if (bar && pct && rest) {
            bar.style.width = r.pct + '%';
            pct.textContent = r.pct + '%';
            rest.innerHTML = "<i class='bx bx-timer'></i> Restan: " + r.minRest + " min";
            if (r.pct >= 100) { bar.classList.add('done'); }
          }

          if (r.estado === 'APTO_CORTE' && estadosAnteriores[r.id] === 'EN_REPOSO') {
            hayNuevoApto = true;
          }
          estadosAnteriores[r.id] = r.estado;
        });

        if (hayNuevoApto) {
          mostrarNotificacion();
          setTimeout(function() { location.reload(); }, 3000);
        }
      })
      .catch(function(e) { console.warn('Polling error:', e); });
  }

  function mostrarNotificacion() {
    var banner = document.getElementById('notif-banner');
    banner.style.display = 'flex';
    setTimeout(function() { banner.style.display = 'none'; }, 5000);
  }

  <% for (TiempoReposo tr : activos) { %>
  estadosAnteriores[<%= tr.getIdReposo() %>] = 'EN_REPOSO';
  <% } %>

  <% if (!activos.isEmpty()) { %>
  setInterval(actualizarTarjetas, 30000);
  <% } %>

  // ── Autocompletar tiempo desde el catálogo ──
  function autocompletarTiempo() {
    var select = document.getElementById('idTela');
    if (select.selectedIndex === 0) return;

    var option = select.options[select.selectedIndex];
    var totalMinutos = parseInt(option.getAttribute('data-tiempo')) || 0;

    if (totalMinutos > 0) {
      var h = Math.floor(totalMinutos / 60);
      var m = totalMinutos % 60;
      document.getElementById('horas').value = h;
      document.getElementById('minutos').value = m;
    } else {
      document.getElementById('horas').value = 1;
      document.getElementById('minutos').value = 0;
    }
  }

  // ── FILTROS PARA EL HISTORIAL ──
    function poblarUsuariosHistorial() {
        var usuariosSet = new Set();
        var rows = document.querySelectorAll('#tablaHistorial tbody tr');
        rows.forEach(function(row) {
            var usuario = row.cells[10]?.innerText.trim();
            if (usuario && usuario !== '—') usuariosSet.add(usuario);
        });
        var select = document.getElementById('filtroUsuario');
        select.innerHTML = '<option value="">-- Todos --</option>';
        Array.from(usuariosSet).sort().forEach(function(u) {
            var opt = document.createElement('option');
            opt.value = u;
            opt.textContent = u;
            select.appendChild(opt);
        });
    }

    function aplicarFiltrosHistorial() {
        var estado = document.getElementById('filtroEstado').value;
        var usuario = document.getElementById('filtroUsuario').value;
        var ot = document.getElementById('filtroOt').value.trim().toLowerCase();
        var tejido = document.getElementById('filtroTejido').value.trim().toLowerCase();

        var rows = document.querySelectorAll('#tablaHistorial tbody tr');
        var visibles = 0;
        rows.forEach(function(row) {
            var mostrar = true;

            var estadoCelda = row.cells[8];
            var estadoTexto = '';
            if (estadoCelda) {
                var span = estadoCelda.querySelector('span');
                if (span) estadoTexto = span.innerText.trim();
                if (estadoTexto === 'APTO CORTE') estadoTexto = 'APTO_CORTE';
            }
            if (estado && estadoTexto !== estado) mostrar = false;

            var usuarioCelda = row.cells[10];
            var usuarioTexto = usuarioCelda ? usuarioCelda.innerText.trim() : '';
            if (usuario && usuarioTexto !== usuario) mostrar = false;

            var otCelda = row.cells[2];
            var otTexto = otCelda ? otCelda.innerText.trim().toLowerCase() : '';
            if (ot && !otTexto.includes(ot)) mostrar = false;

            var tejidoCelda = row.cells[3];
            var tejidoTexto = tejidoCelda ? tejidoCelda.innerText.trim().toLowerCase() : '';
            if (tejido && !tejidoTexto.includes(tejido)) mostrar = false;

            row.style.display = mostrar ? '' : 'none';
            if (mostrar) visibles++;
        });

        var contadorSpan = document.getElementById('contadorHistorial');
        if (contadorSpan) {
            contadorSpan.textContent = visibles + ' registro(s)';
        }
    }

    function limpiarFiltrosHistorial() {
        document.getElementById('filtroEstado').value = '';
        document.getElementById('filtroUsuario').value = '';
        document.getElementById('filtroOt').value = '';
        document.getElementById('filtroTejido').value = '';
        aplicarFiltrosHistorial();
    }

    document.addEventListener('DOMContentLoaded', function() {
        poblarUsuariosHistorial();
        aplicarFiltrosHistorial();

        document.getElementById('filtroEstado').addEventListener('change', aplicarFiltrosHistorial);
        document.getElementById('filtroUsuario').addEventListener('change', aplicarFiltrosHistorial);
        document.getElementById('filtroOt').addEventListener('input', aplicarFiltrosHistorial);
        document.getElementById('filtroTejido').addEventListener('input', aplicarFiltrosHistorial);
        document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltrosHistorial);
    });
</script>

</body>
</html>