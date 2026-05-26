<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean puedeVer   = permisos.contains("PROD_OT_VER");
    boolean puedeCrear = permisos.contains("PROD_OT_CREAR");
    boolean verReposo  = permisos.contains("PROD_REPOSO_VER");
    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    List<OrdenTrabajo>  ordenes       = (List<OrdenTrabajo>)  request.getAttribute("ordenes");
    List<ModeloPrenda>  modelosPrenda = (List<ModeloPrenda>)  request.getAttribute("modelosPrenda");
    String              codigoPreview = (String)              request.getAttribute("codigoPreview");
    if (ordenes == null) ordenes = new ArrayList<>();

    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");
    String errorBD      = (String) request.getAttribute("errorBD");
    String errorCrear   = (String) request.getAttribute("errorCrear");
    boolean abrirModalOT = (errorCrear != null);

    boolean esAdmin = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Órdenes de Trabajo – Sistema Textil</title>
  
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
    .alerta-err-modal { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fca5a5; padding: 12px; border-radius: var(--radius-md); margin-bottom: 1.2rem; font-size: 0.85rem; display: flex; align-items: center; gap: 8px;}

    /* ── TOOLBAR Y FILTROS ── */
    .toolbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; margin-bottom: 20px; }
    .toolbar h3 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s; font-family: 'Inter', sans-serif;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper { position: relative; flex: 1; min-width: 250px; }
    .search-wrapper .bx-search { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    /* ── BOTONES ── */
    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); }
    .btn-outline:hover { background: var(--color-bg); }
    
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.sync { color: #0369a1; background: #e0f2fe; }
    .btn-icon.sync:hover { background: #bae6fd; color: #0284c7; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: var(--danger-text); background: var(--danger-bg); }
    .btn-icon.delete:hover { background: #fca5a5; color: #7f1d1d; }

    /* ── TABLA ── */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:hover td { background: #f8fafc; }
    .sin-datos { text-align: center; padding: 48px; color: var(--text-muted); }
    .sin-datos i { font-size: 3rem; color: var(--border-color); display:block; margin-bottom:12px; }
    .codigo-ot { font-family: monospace; font-weight: 700; color: var(--color-primary); font-size: 0.95rem; }
    .acciones { display: flex; gap: 8px; justify-content: flex-start;}

    .badge-estado { display: inline-block; padding: 0.35rem 0.8rem; border-radius: 6px; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; text-align: center; min-width: 100px;}
    .est-CREADA     { background: #e0e7ff; color: #3730a3; }
    .est-EN_PROCESO { background: var(--warning-bg); color: var(--warning-text); }
    .est-FINALIZADA { background: var(--success-bg); color: var(--success-text); }
    .est-ANULADA    { background: var(--danger-bg); color: var(--danger-text); }

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: 1rem; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 640px; max-height: 92vh; display: flex; flex-direction: column; box-shadow: 0 20px 40px rgba(0,0,0,0.15); overflow: hidden; }
    .modal-flotante.sm { max-width: 420px; }
    .modal-header { background: var(--color-secondary); padding: 1rem 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
    .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; display:flex; align-items:center; gap:8px; font-weight:600;}
    .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: 0.2s; }
    .modal-close:hover { color: #fff; }
    .modal-body { padding: 1.5rem 2rem; overflow-y: auto; flex: 1; min-height: 0; }
    .modal-footer { padding: 1rem 2rem; border-top: 1px solid var(--border-color); display: flex; gap: 12px; justify-content: flex-end; flex-shrink: 0; background: #f8fafc; }

    .form-group { margin-bottom: 1.2rem; }
    .form-group label { display: block; font-size: 0.82rem; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
    .req { color: var(--danger-hover); margin-left: 2px; }
    .hint { font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; }
    
    .info-responsable { background: var(--color-bg); border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 0.6rem 1rem; font-size: 0.85rem; color: var(--text-main); display: flex; align-items: center; gap: 8px; }

    .ot-preview { background: linear-gradient(135deg, var(--color-secondary), var(--color-primary)); color: #fff; border-radius: var(--radius-md); padding: 1.2rem 1.5rem; margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
    .ot-preview .lbl { font-size: 0.78rem; color: #aac4e8; margin-bottom: 4px;}
    .ot-preview .cod { font-size: 1.4rem; font-weight: 700; font-family: monospace; color: var(--color-accent); }
    .ot-preview .info { font-size: 0.75rem; color: #aac4e8; text-align: right; line-height: 1.3;}
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
        <% if (_navOT)   { %><a href="<%= _cp %>/ordenes-trabajo" class="menu-link activo">Órdenes de Trabajo</a><% } %>
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
  </nav>
</aside>

<main>
  <header>
    <h2><i class='bx bx-list-check'></i> Órdenes de Trabajo</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge-rol"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
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
    
    <div class="toolbar">
        <h3>Listado de Órdenes de Trabajo (<%= ordenes.size() %>)</h3>
        <% if (puedeCrear) { %>
          <button type="button" class="btn btn-primary" onclick="abrirModalOT()">
            <i class='bx bx-plus'></i> Nueva Orden de Trabajo
          </button>
        <% } %>
    </div>

    <div class="filtro-wrap">
      <div class="search-wrapper">
        <i class='bx bx-search'></i>
        <input type="text" id="busquedaOT" class="form-control" placeholder="Buscar por Código OT, cliente o modelo...">
      </div>

      <div>
        <select id="busquedaEstado" class="form-control" style="width:160px;">
          <option value="">Todos los estados</option>
          <option value="CREADA">CREADA</option>
          <option value="EN_PROCESO">EN PROCESO</option>
          <option value="FINALIZADA">FINALIZADA</option>
          <option value="ANULADA">ANULADA</option>
        </select>
      </div>

      <div>
        <input type="date" id="busquedaFechaIni" class="form-control" title="Fecha inicio" style="width:140px;">
      </div>

      <div>
        <input type="date" id="busquedaFechaFin" class="form-control" title="Fecha fin" style="width:140px;">
      </div>

      <div style="display: flex; gap: 8px;">
        <button type="button" class="btn btn-outline" onclick="limpiarFiltrosOT()"><i class='bx bx-eraser'></i> Limpiar</button>
      </div>
    </div>

    <div class="card">
      <% if (ordenes.isEmpty()) { %>
        <div class="sin-datos">
          <i class='bx bx-file-blank'></i>
          No hay órdenes de trabajo registradas.
          <% if (puedeCrear) { %>
            <br>
            <button type="button" class="btn btn-primary" style="margin-top:1rem;" onclick="abrirModalOT()">
              <i class='bx bx-plus'></i> Crear primera OT
            </button>
          <% } %>
        </div>
      <% } else { %>
        <table>
          <thead>
            <tr>
              <th>#</th><th>Código OT</th><th>Cliente</th><th>Modelo</th>
              <th style="text-align:center;">Cant. Est.</th><th>Estado</th><th>Responsable</th><th>Fecha Creación</th>
              <% if (puedeCrear) { %><th style="text-align:center;">Acciones</th><% } %>
            </tr>
          </thead>
          <tbody>
            <% int i = 1; for (OrdenTrabajo ot : ordenes) { %>
            <tr>
              <td style="color:var(--text-muted);"><%= i++ %></td>
              <td><span class="codigo-ot"><%= ot.getCodigoOt() %></span></td>
              <td style="font-weight:500;"><%= ot.getCliente() %></td>
              <td><%= ot.getNombreModelo() != null ? ot.getNombreModelo() : "Sin modelo" %></td>
              <td style="text-align:center; font-weight:600;"><%= ot.getCantidadEst() %></td>
              <td><span class="badge-estado est-<%= ot.getEstado() %>"><%= ot.getEstado().replace("_", " ") %></span></td>
              <td style="font-size:0.8rem;"><%= ot.getNombreResponsable() != null ? ot.getNombreResponsable() : "—" %></td>
              <td style="font-size:0.78rem; color:var(--text-muted);">
                <%= ot.getFechaCrea() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(ot.getFechaCrea()) : "—" %>
              </td>
              <% if (puedeCrear) { %>
              <td>
                  <div class="acciones">
                    <% if (!"ANULADA".equals(ot.getEstado()) && !"FINALIZADA".equals(ot.getEstado())) { %>
                      <button class="btn-icon sync" title="Cambiar Estado"
                        onclick="abrirModalEstado(<%= ot.getIdOt() %>, '<%= ot.getCodigoOt() %>', '<%= ot.getEstado() %>')">
                        <i class='bx bx-refresh'></i>
                      </button>
                      <% if ("CREADA".equals(ot.getEstado())) { %>
                        <button class="btn-icon edit" title="Editar OT"
                                onclick="abrirModalEditarOT('<%= ot.getIdOt() %>', '<%= ot.getCliente().replace("'","\\x27") %>', '<%= ot.getIdModelo() %>', '<%= ot.getCantidadEst() %>')">
                          <i class='bx bx-edit-alt'></i>
                        </button>
                        <button class="btn-icon delete" title="Eliminar OT"
                          onclick="confirmarEliminarOT(<%= ot.getIdOt() %>, '<%= ot.getCodigoOt() %>')">
                          <i class='bx bx-trash'></i>
                        </button>
                      <% } %>
                    <% } %>
                  </div>
            </td>
            <% } %>
            </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </div>
  </div>
</main>

<div class="overlay" id="modalEstado">
  <div class="modal-flotante sm">
    <div class="modal-header">
      <h3><i class='bx bx-refresh'></i> Cambiar Estado</h3>
      <button type="button" class="modal-close" onclick="cerrarModalEstado()">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/ordenes-trabajo">
      <div class="modal-body">
        <input type="hidden" name="accion" value="cambiarEstado">
        <input type="hidden" name="idOt" id="modalIdOt">
        
        <div style="margin-bottom:1rem; font-size:0.85rem;">
            Modificando el estado para la OT: <strong id="modalCodigo" style="color:var(--color-primary); font-family:monospace;"></strong>
        </div>

        <div class="form-group">
            <label>Nuevo estado:</label>
            <select name="nuevoEstado" id="modalNuevoEstado" class="form-control">
                <option value="CREADA">CREADA</option>
                <option value="EN_PROCESO">EN PROCESO</option>
                <option value="FINALIZADA">FINALIZADA</option>
                <option value="ANULADA">ANULADA</option>
            </select>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalEstado()"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar cambio</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="overlayEditarOT">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3><i class='bx bx-edit'></i> Editar Orden de Trabajo</h3>
      <button type="button" class="modal-close" onclick="cerrarModalEditarOT()">✕</button>
    </div>
    <form method="post" action="${pageContext.request.contextPath}/ordenes-trabajo" onsubmit="return validarFormEditarOT()">
      <div class="modal-body">
        <input type="hidden" name="accion" value="editar">
        <input type="hidden" name="idOt" id="editIdOt">
        <div id="editAlertaError" class="alerta-err-modal" style="display:none;"></div>
        
        <div class="form-group">
          <label>Cliente <span class="req">*</span></label>
          <input type="text" name="cliente" id="editCliente" class="form-control" maxlength="150">
        </div>
        
        <div class="form-group">
          <label>Modelo / Prenda <span class="req">*</span></label>
          <select name="idModelo" id="editModeloSelect" class="form-control" onchange="toggleOtroModeloEdicion()">
            <option value="">-- Selecciona un modelo --</option>
            <% if (modelosPrenda != null) for (ModeloPrenda mp : modelosPrenda) { %>
               <option value="<%= mp.getIdModelo() %>"><%= mp.getNombre() %></option>
            <% } %>
          </select>
          <div id="editCampoOtroModelo" style="display:none; margin-top:.8rem;">
            <input type="text" id="editModeloOtro" class="form-control" placeholder="Ingresa el nombre del modelo" maxlength="100">
          </div>
        </div>
        
        <div class="form-group">
          <label>Cantidad Estimada <span class="req">*</span></label>
          <input type="number" name="cantidadEst" id="editCantidad" class="form-control" min="1" max="99999">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalEditarOT()"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar Cambios</button>
      </div>
    </form>
  </div>
</div>      
      
<div class="overlay" id="overlayOT">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3><i class='bx bx-plus-circle'></i> Nueva Orden de Trabajo</h3>
      <button type="button" class="modal-close" onclick="cerrarModalOT()">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/ordenes-trabajo" onsubmit="return validarFormOT()" id="formOT">
      <div class="modal-body">
        <input type="hidden" name="accion" value="crear">

        <div id="otAlertaError" class="alerta-err-modal" style="display:none;"></div>

        <div class="ot-preview">
          <div>
            <div class="lbl">Código de OT asignado automáticamente:</div>
            <div class="cod" id="codigoPreviewDisplay"><%= codigoPreview != null ? codigoPreview : "OT-2026-XXXX" %></div>
          </div>
          <div class="info">
            Se generará al<br>confirmar el registro
          </div>
        </div>

        <div class="form-group">
          <label>Cliente <span class="req">*</span></label>
          <input type="text" name="cliente" id="otCliente" class="form-control" placeholder="Nombre del cliente o empresa" maxlength="150">
          <div class="hint">Razón social o nombre del cliente que solicita la maquila.</div>
        </div>

        <div class="form-group">
          <label>Modelo / Prenda <span class="req">*</span></label>
          <% if (modelosPrenda != null && !modelosPrenda.isEmpty()) { %>
            <select name="idModelo" id="otModelo" class="form-control" required>
                <option value="">-- Selecciona un modelo --</option>
                <% for (ModeloPrenda mp : modelosPrenda) { %>
                    <option value="<%= mp.getIdModelo() %>"><%= mp.getNombre() %> <%= mp.getTemporada() != null ? "(" + mp.getTemporada() + ")" : "" %></option>
                <% } %>
            </select>
          <% } else { %>
            <input type="text" name="modelo" id="otModelo" class="form-control" placeholder="Ej: Corset Verano 2026" maxlength="100">
            <div class="hint">No hay modelos en catálogo. Puedes ingresar el nombre manualmente.</div>
          <% } %>
        </div>

        <% if (modelosPrenda != null && !modelosPrenda.isEmpty()) { %>
        <div class="form-group" id="otCampoOtroModelo" style="display:none;">
          <label>Especificar modelo <span class="req">*</span></label>
          <input type="text" id="otModeloOtro" class="form-control" placeholder="Ingresa el nombre del modelo" maxlength="100">
          <div class="hint">Escribe el nombre del modelo de prenda.</div>
        </div>
        <% } %>

        <div class="form-group">
          <label>Cantidad Estimada <span class="req">*</span></label>
          <input type="number" name="cantidadEst" id="otCantidad" class="form-control" placeholder="Ej: 500" min="1" max="99999">
          <div class="hint">Número de prendas estimadas para esta orden.</div>
        </div>

        <div class="form-group">
          <label>Responsable</label>
          <div class="info-responsable">
            <i class='bx bx-user'></i> <strong><%= usuarioSesion.getNombreCompleto() %></strong>
            &nbsp;–&nbsp;<%= usuarioSesion.getNombreRol() %>
            <span style="margin-left:auto; font-size:0.75rem; color:var(--text-muted);"><i class='bx bx-bot'></i> Auto</span>
          </div>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalOT()"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-check'></i> Crear Orden de Trabajo</button>
      </div>
    </form>
  </div>
</div>

<script>
  // UI MENÚ ACORDEÓN
  function toggleSubmenu(element) {
      element.parentElement.classList.toggle('active');
  }

  /* ── Modal cambio estado con Máquina de Estados ── */
  function abrirModalEstado(idOt, codigo, estadoActual) {
    document.getElementById('modalIdOt').value = idOt;
    document.getElementById('modalCodigo').textContent = codigo;
    
    var select = document.getElementById('modalNuevoEstado');
    select.innerHTML = ''; // Limpiamos opciones anteriores

    if (estadoActual === 'CREADA') {
        addOption(select, 'EN_PROCESO', 'EN PROCESO');
        addOption(select, 'ANULADA', 'ANULADA');
    } else if (estadoActual === 'EN_PROCESO') {
        addOption(select, 'ANULADA', 'ANULADA'); // Finalizar está bloqueado aquí, debe ser automático por el sistema
    } else {
        // Si está FINALIZADA o ANULADA, no se puede cambiar
        addOption(select, estadoActual, estadoActual);
        select.disabled = true;
    }
    
    document.getElementById('modalEstado').classList.add('activo');
  }

  function addOption(select, value, text) {
      var opt = document.createElement('option');
      opt.value = value;
      opt.textContent = text;
      select.appendChild(opt);
  }
  function cerrarModalEstado() {
    document.getElementById('modalEstado').classList.remove('activo');
  }
  document.getElementById('modalEstado').addEventListener('click', function(e) {
    if (e.target === this) cerrarModalEstado();
  });

  /* ── Modal nueva OT ── */
  function abrirModalOT() {
    document.getElementById('otCliente').value  = '';
    document.getElementById('otCantidad').value = '';
    var otModelo = document.getElementById('otModelo');
    if (otModelo) otModelo.value = '';
    var otOtro = document.getElementById('otModeloOtro');
    if (otOtro) { otOtro.value = ''; otOtro.required = false; }
    var campoOtro = document.getElementById('otCampoOtroModelo');
    if (campoOtro) campoOtro.style.display = 'none';
    document.getElementById('otAlertaError').style.display = 'none';
    document.getElementById('overlayOT').classList.add('activo');
    document.getElementById('otCliente').focus();
  }

  function cerrarModalOT() {
    document.getElementById('overlayOT').classList.remove('activo');
  }

  document.getElementById('overlayOT').addEventListener('click', function(e) {
    if (e.target === this) cerrarModalOT();
  });

  /* Manejo del select "Otro" en el modal */
  var selectModelo = document.getElementById('otModelo');
  var campoOtro    = document.getElementById('otCampoOtroModelo');
  var inputOtro    = document.getElementById('otModeloOtro');
  if (selectModelo && selectModelo.tagName === 'SELECT') {
    selectModelo.addEventListener('change', function() {
      if (this.value === '__otro__') {
        if (campoOtro) campoOtro.style.display = 'block';
        if (inputOtro) inputOtro.required = true;
      } else {
        if (campoOtro) campoOtro.style.display = 'none';
        if (inputOtro) { inputOtro.required = false; inputOtro.value = ''; }
      }
    });
  }

  function validarFormOT() {
    var cliente    = document.getElementById('otCliente');
    var modeloEl   = document.getElementById('otModelo');
    var cantidadEl = document.getElementById('otCantidad');
    if (!cliente || cliente.value.trim() === '') {
      mostrarErrorOT('El nombre del cliente es obligatorio.');
      if (cliente) cliente.focus(); return false;
    }

    if (modeloEl && modeloEl.tagName === 'SELECT' && modeloEl.value === '__otro__') {
      if (!inputOtro || inputOtro.value.trim() === '') {
        mostrarErrorOT('Por favor especifica el nombre del modelo.');
        if (inputOtro) inputOtro.focus(); return false;
      }
      var opt = document.createElement('option');
      opt.value = inputOtro.value.trim();
      opt.text  = inputOtro.value.trim();
      opt.selected = true;
      modeloEl.appendChild(opt);
      modeloEl.value = inputOtro.value.trim();
    } else if (!modeloEl || modeloEl.value.trim() === '') {
      mostrarErrorOT('El modelo de prenda es obligatorio.');
      if (modeloEl) modeloEl.focus(); return false;
    }

    if (!cantidadEl || cantidadEl.value <= 0) {
      mostrarErrorOT('La cantidad estimada debe ser mayor a 0.');
      if (cantidadEl) cantidadEl.focus(); return false;
    }
    return true;
  }

  function mostrarErrorOT(msg) {
    var el = document.getElementById('otAlertaError');
    el.innerHTML = "<i class='bx bx-error-circle'></i> " + msg;
    el.style.display = 'flex';
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  /* Si el servlet devuelve con error al crear OT, reabrimos el modal */
  <% if (abrirModalOT) { %>
  window.addEventListener('DOMContentLoaded', function() {
    abrirModalOT();
    mostrarErrorOT('<%= errorCrear %>');
  });
  <% } %>
  
  
    function abrirModalEditarOT(idOt, cliente, idModelo, cantidad) {
       // 1. Asignar valores básicos
       document.getElementById('editIdOt').value = idOt;
       document.getElementById('editCliente').value = cliente;
       document.getElementById('editCantidad').value = cantidad;

       // 2. Seleccionar el modelo en el desplegable
       var select = document.getElementById('editModeloSelect');
       var campoOtro = document.getElementById('editCampoOtroModelo');

       // Intentamos seleccionar por ID
       select.value = idModelo;
       // 3. Lógica por si es un modelo manual o no se encuentra
       if (select.selectedIndex <= 0 && idModelo != "") {
           // Si no se seleccionó nada pero hay un ID/Valor, asumimos que es "Otro"
           select.value = "0";
           if(campoOtro) campoOtro.style.display = 'block';
       } else {
           if(campoOtro) campoOtro.style.display = 'none';
       }

       document.getElementById('overlayEditarOT').classList.add('activo');
   }

   // Función auxiliar para el cambio manual en edición
   function toggleOtroModeloEdicion() {
       var select = document.getElementById('editModeloSelect');
       var campoOtro = document.getElementById('editCampoOtroModelo');
       if (select.value === "0") {
           campoOtro.style.display = 'block';
       } else {
           campoOtro.style.display = 'none';
       }
   }

  function cerrarModalEditarOT() { document.getElementById('overlayEditarOT').classList.remove('activo'); }

  function confirmarEliminarOT(idOt, codigoOt) {
    if (confirm('¿Eliminar la OT ' + codigoOt + '?')) {
      var form = document.createElement('form');
      form.method = 'POST';
      form.action = '<%= request.getContextPath() %>/ordenes-trabajo';
      form.innerHTML = '<input type="hidden" name="accion" value="eliminar"><input type="hidden" name="idOt" value="' + idOt + '">';
      document.body.appendChild(form); form.submit();
    }
  }
  
  // ===== Búsqueda avanzada de Órdenes de Trabajo (texto, estado, fechas) =====
    var inputBusqueda   = document.getElementById('busquedaOT');
    var selectEstado    = document.getElementById('busquedaEstado');
    var inputFechaIni   = document.getElementById('busquedaFechaIni');
    var inputFechaFin   = document.getElementById('busquedaFechaFin');
    
    function aplicarFiltrosOT() {
      var texto    = inputBusqueda.value.toLowerCase().trim();
      var estado   = selectEstado.value;
      var fechaIni = inputFechaIni.value; // formato yyyy-MM-dd
      var fechaFin = inputFechaFin.value;

      var filas = document.querySelectorAll('table tbody tr');
      filas.forEach(function(tr) {
        if (tr.querySelector('.sin-datos')) return;

        var codigo  = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var cliente = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
        var modelo  = tr.cells[3] ? tr.cells[3].textContent.toLowerCase() : '';
        var estadoTd = tr.cells[5] ? tr.cells[5].textContent.trim() : '';
        var fechaTxt = tr.cells[7] ? tr.cells[7].textContent.trim() : '';

        if (texto && !codigo.includes(texto) && !cliente.includes(texto) && !modelo.includes(texto)) {
          tr.style.display = 'none';
          return;
        }
        if (estado && estadoTd !== estado) {
          tr.style.display = 'none';
          return;
        }
        if (fechaIni || fechaFin) {
          var partes = fechaTxt.split(' ')[0]; // solo la parte de fecha
          var fechaCelda = partes.split('/').reverse().join('-'); // dd/MM/yyyy -> yyyy-MM-dd

          if (fechaIni && fechaCelda < fechaIni) {
            tr.style.display = 'none';
            return;
          }
          if (fechaFin && fechaCelda > fechaFin) {
            tr.style.display = 'none';
            return;
          }
        }
        tr.style.display = '';
      });
    }

    inputBusqueda.addEventListener('keyup', aplicarFiltrosOT);
    selectEstado.addEventListener('change', aplicarFiltrosOT);
    inputFechaIni.addEventListener('input', aplicarFiltrosOT);
    inputFechaFin.addEventListener('input', aplicarFiltrosOT);

    function limpiarFiltrosOT() {
      inputBusqueda.value = '';
      selectEstado.value = '';
      inputFechaIni.value = '';
      inputFechaFin.value = '';
      aplicarFiltrosOT();
    }
</script>

</body>
</html>