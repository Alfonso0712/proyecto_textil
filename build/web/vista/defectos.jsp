<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    if (!permisos.contains("CAL_DEFECTOS_REG") && usuarioSesion.getIdRol() != 6) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return;
    }

    List<DefectoReproceso> defectos = (List<DefectoReproceso>) request.getAttribute("defectos");
    List<DefectoReprocesoDAO.ResumenReprocesos> resumen =
        (List<DefectoReprocesoDAO.ResumenReprocesos>) request.getAttribute("resumenReprocesos");
    List<OrdenTrabajo> otsActivas  = (List<OrdenTrabajo>) request.getAttribute("otsActivas");
    List<Usuario> maquinistas      = (List<Usuario>) request.getAttribute("maquinistas");

    if (defectos    == null) defectos    = new ArrayList<>();
    if (resumen     == null) resumen     = new ArrayList<>();
    if (otsActivas  == null) otsActivas  = new ArrayList<>();
    if (maquinistas == null) maquinistas = new ArrayList<>();

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
  <title>Control de Defectos (HU06) – Sistema Textil</title>
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

    .dashboard-reprocesos { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
    .card-reproceso { background: var(--color-surface); border-left: 4px solid var(--danger-hover); padding: 16px; border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border-top: 1px solid var(--border-color); border-right: 1px solid var(--border-color); border-bottom: 1px solid var(--border-color); min-width: 200px; display: flex; align-items: center; justify-content: space-between; transition: transform 0.2s; }
    .card-reproceso:hover { transform: translateY(-2px); }
    .card-reproceso h4 { font-size: 0.88rem; color: var(--text-main); margin-bottom: 4px; }
    .card-reproceso .spec { font-size: 0.75rem; color: var(--text-muted); font-weight: 500; text-transform: uppercase; }
    .card-reproceso .count { font-size: 1.75rem; font-weight: 700; color: var(--color-secondary); }

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

    .card { background: var(--color-surface); border-radius: var(--radius-md); border: 1px solid var(--border-color); overflow-x: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.04);}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); vertical-align: middle; color:var(--text-main);}
    tr:hover td { background: #f8fafc; }
    .sin-datos { text-align: center; padding: 48px; color: var(--text-muted); }
    .sin-datos .ico { font-size: 3rem; display: block; margin-bottom: 12px; color:var(--success-text); }

    .chip-falla { display: flex; align-items: center; justify-content: center; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; background: var(--danger-bg); color: var(--danger-text); min-width: 150px; text-align: center; }
    .chip-estado { display: flex; align-items: center; justify-content: center; gap:4px; min-width: 120px; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; }
    
    .btn-accion { display: inline-flex; align-items: center; justify-content: center; gap:4px; padding: 6px 12px; border-radius: 6px; border: none; cursor: pointer; font-size: 0.8rem; font-weight:600; min-width: 110px; text-decoration: none; transition: 0.2s; color:#fff;}
    .btn-accion:hover { filter: brightness(0.9); }
    
    .fecha-td { color: var(--text-muted); font-size: 0.8rem; }
    .id-td    { color: var(--text-muted); font-family: monospace; font-weight:600;}

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15,23,42,.5); z-index: 1000; justify-content: center; align-items: center; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }
    .modal { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 520px; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--danger-hover); font-size: 1.1rem; font-weight: 600; display:flex; align-items:center; gap:8px;}
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-light); transition: .2s; }
    .close-modal:hover { color: var(--text-main); }
    
    label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); display: block; margin-bottom: 6px; }
    textarea { width: 100%; padding: 0.6rem 0.8rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); margin-bottom: 16px; font-family: inherit; font-size: 0.85rem; transition: border-color .2s; resize: vertical; min-height: 80px; }
    textarea:focus { outline: none; border-color: var(--danger-hover); box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1); }
    
    .btn-guardar { width: 100%; padding: 0.75rem; color: #fff; background: var(--danger-hover); border: none; border-radius: var(--radius-sm); cursor: pointer; font-weight: 600; font-size: 0.9rem; transition: .2s; display:flex; align-items:center; justify-content:center; gap:6px;}
    .btn-guardar:hover { background: #b91c1c; }
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-check-shield'></i> Calidad</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <a href="<%= _cp %>/defectos" class="menu-link activo">Control de Defectos</a>
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
    <h2><i class='bx bx-check-shield'></i> Control de Defectos y Reprocesos</h2>
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

    <% if (!resumen.isEmpty() && usuarioSesion.getIdRol() != 6) { %>
    <div class="dashboard-reprocesos">
      <% for (DefectoReprocesoDAO.ResumenReprocesos r : resumen) { %>
      <div class="card-reproceso">
        <div>
          <h4><%= r.getNombreMaquinista() %></h4>
          <span class="spec"><%= r.getEspecialidad() != null ? r.getEspecialidad() : "Sin esp." %></span>
        </div>
        <span class="count" id="count-<%= r.getIdMaquinista() %>"><%= r.getTotalReprocesos() %></span>
      </div>
      <% } %>
    </div>
    <% } %>

    <div class="section-title">
      <div>
        <h3>Registro Histórico de Defectos</h3>
        <p>Monitoreo de reprocesos por maquinista para control de calidad.</p>
      </div>
    </div>
    
    <div class="filtro-wrap">
        <div>
            <label><i class='bx bx-search'></i> Código OT</label>
            <input type="text" id="filtroOt" class="form-control" placeholder="Ej: OT-2026-001" style="width: 160px;">
        </div>
        <div>
            <label><i class='bx bx-cog'></i> Tipo de Falla</label>
            <select id="filtroTipoFalla" class="form-control" style="width: 180px;">
                <option value="">-- Todos --</option>
            </select>
        </div>
        <div>
            <label><i class='bx bx-user-pin'></i> Maquinista</label>
            <select id="filtroMaquinista" class="form-control" style="width: 200px;">
                <option value="">-- Todos --</option>
            </select>
        </div>
        <div>
            <label><i class='bx bx-filter'></i> Estado</label>
            <select id="filtroEstado" class="form-control" style="width: 150px;">
                <option value="">-- Todos --</option>
                <option value="PENDIENTE">Pendiente</option>
                <option value="REGISTRADO">Registrado</option>
                <option value="CORREGIDO">Corregido</option>
            </select>
        </div>
        <div>
            <label><i class='bx bx-calendar'></i> Fecha desde</label>
            <input type="date" id="filtroFechaDesde" class="form-control" style="width: 140px;">
        </div>
        <div>
            <label><i class='bx bx-calendar'></i> Fecha hasta</label>
            <input type="date" id="filtroFechaHasta" class="form-control" style="width: 140px;">
        </div>
        <div>
            <button id="btnLimpiarFiltros" class="btn-outline"><i class='bx bx-eraser'></i> Limpiar filtros</button>
        </div>
    </div>
    
    <div class="card">
      <% if (defectos.isEmpty()) { %>
        <div class="sin-datos">
          <i class='bx bx-check-shield ico'></i>
          No hay defectos registrados. ¡Excelente control de calidad!
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr><th>ID</th><th>OT #</th><th>Pieza</th><th style="text-align:center;">Faltantes</th><th>Tipo Falla</th><th>Maquinista</th><th>Fecha Registro</th><th style="text-align:center;">Estado</th><th style="text-align:center;">Acción</th></tr>
        </thead>
        <tbody id="tbody-defectos">
          <% for (DefectoReproceso d : defectos) { %>
          <tr>
            <td class="id-td">#<%= String.format("%04d", d.getIdDefecto()) %></td>
            <td><strong><%= d.getCodigoOt() %></strong></td>
            <td><%= d.getNombrePieza() != null ? d.getNombrePieza() : "-" %></td>
            <td style="text-align:center; color:var(--danger-hover); font-weight:bold;"><%= d.getCantidadFaltante() %></td>
            <td>
                <% if (d.getEstado() == DefectoReproceso.Estado.PENDIENTE) { %>
                    <span style="color:var(--text-light);">--</span>
                <% } else { %>
                    <span class="chip-falla"><%= d.getEtiquetaFalla() %></span>
                <% } %>
            </td>
            <td><%= d.getNombreMaquinista() %></td>
            <td class="fecha-td"><%= d.getFechaRegistro() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(d.getFechaRegistro()) : "-" %></td>
            <td style="text-align:center;">
                <% if (d.getEstado() == DefectoReproceso.Estado.PENDIENTE) { %>
                    <span class="chip-estado" style="background:var(--warning-bg); color:var(--warning-text);"><i class='bx bx-time-five'></i> Pendiente</span>
                <% } else if (d.getEstado() == DefectoReproceso.Estado.REGISTRADO) { %>
                    <span class="chip-estado" style="background:var(--success-bg); color:var(--success-text);"><i class='bx bx-check-circle'></i> Registrado</span>
                <% } else { %>
                    <span class="chip-estado" style="background:var(--info-bg); color:var(--info-text);"><i class='bx bx-check-double'></i> Corregido</span>
                <% } %>
            </td>
            <td style="text-align:center;">
                <% if (d.getEstado() == DefectoReproceso.Estado.PENDIENTE) { 
                    if (usuarioSesion.getIdRol() == 1 || usuarioSesion.getIdRol() == 5) { %>
                        <form method="post" action="<%= request.getContextPath() %>/defectos" style="display:inline-block; margin-right:5px;">
                            <input type="hidden" name="accion" value="revertir">
                            <input type="hidden" name="idDefecto" value="<%= d.getIdDefecto() %>">
                            <button type="submit" class="btn-accion" style="background:var(--info-text);" onclick="return confirm('¿Revertir? Se corregirá la producción a la cantidad esperada. El defecto se cerrará automáticamente.')"><i class='bx bx-refresh'></i> Revertir</button>
                        </form>
                        <button class="btn-accion btn-reponer" style="background:#d97706;" onclick="abrirModalReponer(<%= d.getIdDefecto() %>, '<%= d.getCodigoOt() %>', '<%= d.getNombrePieza() %>', <%= d.getCantidadFaltante() %>)"><i class='bx bx-revision'></i> Reponer</button>
                <% } else { %>
                    <span style="color:var(--text-light); font-size:0.8rem;">Sin permisos</span>
                <% }
                } else if (d.getEstado() == DefectoReproceso.Estado.REGISTRADO && d.getGeneraReposicion() == 1) { %>
                    <span class="chip-estado" style="background:var(--warning-bg); color:var(--warning-text); margin: 0 auto;"><i class='bx bx-revision'></i> Repuesto</span>
                <% } else if (d.getEstado() == DefectoReproceso.Estado.CORREGIDO) { %>
                    <span style="color:var(--success-text); font-weight:600; font-size:0.8rem;"><i class='bx bx-check'></i> Corregido</span>
                <% } else { %>
                    <span style="color:var(--text-light);">—</span>
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
    
<div class="overlay" id="overlayDefecto">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-error'></i> Completar Registro de Reproceso</h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>

    <div style="background:#f8fafc; padding:16px; border:radius:var(--radius-sm); border:1px solid var(--border-color); margin-bottom:16px; font-size:0.85rem;">
        <p style="margin-bottom:6px; color:var(--text-main);"><strong>Orden:</strong> <span id="lbl-modal-ot"></span></p>
        <p style="margin-bottom:6px; color:var(--text-main);"><strong>Pieza:</strong> <span id="lbl-modal-pieza"></span></p>
        <p style="margin-bottom:0; color:var(--text-main);"><strong>Responsable:</strong> <span id="lbl-modal-maq"></span></p>
    </div>

    <form method="post" action="<%= request.getContextPath() %>/defectos">
      <input type="hidden" name="accion" value="completar">
      <input type="hidden" name="idDefecto" id="hdn-idDefecto">

      <label>Tipo de Falla <span class="req">*</span></label>
      <select name="tipoFalla" class="form-control" required style="margin-bottom: 16px;">
        <option value="">Clasificación...</option>
        <% for (DefectoReproceso.TipoFalla tf : DefectoReproceso.TipoFalla.values()) { %><option value="<%= tf.name() %>"><%= tf.getEtiqueta() %></option><% } %>
      </select>

      <label>Observaciones Técnicas (Por qué se dañó)</label>
      <textarea name="observaciones" rows="3" placeholder="Detalle la falla, ej: La aguja rompió el hilo..."></textarea>

      <button type="submit" class="btn-guardar"><i class='bx bx-save'></i> Registrar Falla</button>
    </form>
  </div>
</div>

<div class="overlay" id="overlayReponer">
  <div class="modal">
    <div class="modal-header">
      <h3 style="color:#d97706;"><i class='bx bx-revision'></i> Reponer piezas faltantes</h3>
      <button class="close-modal" onclick="cerrarModalReponer()"><i class='bx bx-x'></i></button>
    </div>

    <div style="background:#f8fafc; padding:16px; border-radius:var(--radius-sm); border:1px solid var(--border-color); margin-bottom:16px; font-size:0.85rem;">
        <p style="margin-bottom:6px; color:var(--text-main);"><strong>Orden:</strong> <span id="lbl-reponer-ot"></span></p>
        <p style="margin-bottom:6px; color:var(--text-main);"><strong>Pieza:</strong> <span id="lbl-reponer-pieza"></span></p>
        <p style="margin-bottom:0; color:var(--text-main);"><strong>Cantidad a reponer:</strong> <span id="lbl-reponer-cantidad" style="font-weight:bold; color:#d97706; font-size:1rem;"></span></p>
    </div>

    <form method="post" action="<%= request.getContextPath() %>/defectos">
      <input type="hidden" name="accion" value="reponer">
      <input type="hidden" name="idDefecto" id="hdn-reponer-idDefecto">

      <label>Tipo de Falla <span class="req">*</span></label>
      <select name="tipoFalla" class="form-control" required style="margin-bottom: 16px;">
        <option value="">Clasificación...</option>
        <% for (DefectoReproceso.TipoFalla tf : DefectoReproceso.TipoFalla.values()) { %><option value="<%= tf.name() %>"><%= tf.getEtiqueta() %></option><% } %>
      </select>

      <label>Observaciones Técnicas</label>
      <textarea name="observaciones" rows="3" placeholder="Explique por qué se requieren piezas de reposición..."></textarea>

      <button type="submit" class="btn-guardar" style="background:#d97706;"><i class='bx bx-check'></i> Generar tarea de reposición</button>
    </form>
  </div>
</div>

<script>
// JS INTACTO
  function validarFormDefecto() {
    var ot  = document.getElementById('sel-ot').value;
    var fal = document.getElementById('sel-falla').value;
    var maq = document.getElementById('sel-maquinista').value;
    if (!ot || !fal || !maq) { alert('Por favor complete todos los campos obligatorios.'); return false; }
    return true;
  }
  function abrirModalCompletar(idDefecto, ot, pieza, maquinista) {
    document.getElementById('lbl-modal-ot').textContent = ot;
    document.getElementById('lbl-modal-pieza').textContent = pieza;
    document.getElementById('lbl-modal-maq').textContent = maquinista;
    document.getElementById('hdn-idDefecto').value = idDefecto;
    document.getElementById('overlayDefecto').classList.add('activo');
  }
  function cerrarModal() { document.getElementById('overlayDefecto').classList.remove('activo'); }
  document.getElementById('overlayDefecto').addEventListener('click', function(e) { if (e.target === this) cerrarModal(); });
  
function poblarFiltrosDefectos() {
    const tiposSet = new Set();
    const maquinistasSet = new Set();
    document.querySelectorAll('#tbody-defectos tr').forEach(row => {
        const fallaCell = row.cells[4];
        let tipoTexto = '';
        if (fallaCell) { const span = fallaCell.querySelector('span'); if (span) tipoTexto = span.innerText.trim(); else tipoTexto = fallaCell.innerText.trim(); }
        if (tipoTexto && tipoTexto !== '--') tiposSet.add(tipoTexto);
        
        const maqCell = row.cells[5];
        let maquinista = maqCell ? maqCell.innerText.trim() : '';
        if (maquinista) maquinistasSet.add(maquinista);
    });
    const selectTipo = document.getElementById('filtroTipoFalla');
    selectTipo.innerHTML = '<option value="">-- Todos --</option>';
    Array.from(tiposSet).sort().forEach(t => { const opt = document.createElement('option'); opt.value = t; opt.textContent = t; selectTipo.appendChild(opt); });
    const selectMaq = document.getElementById('filtroMaquinista');
    selectMaq.innerHTML = '<option value="">-- Todos --</option>';
    Array.from(maquinistasSet).sort().forEach(m => { const opt = document.createElement('option'); opt.value = m; opt.textContent = m; selectMaq.appendChild(opt); });
}

function aplicarFiltrosDefectos() {
    const filtroOt = document.getElementById('filtroOt').value.trim().toLowerCase();
    const filtroTipo = document.getElementById('filtroTipoFalla').value;
    const filtroMaq = document.getElementById('filtroMaquinista').value;
    const filtroEstado = document.getElementById('filtroEstado').value;
    const filtroFechaDesde = document.getElementById('filtroFechaDesde').value;
    const filtroFechaHasta = document.getElementById('filtroFechaHasta').value;
    
    const rows = document.querySelectorAll('#tbody-defectos tr');
    let visibles = 0;
    rows.forEach(row => {
        let visible = true;
        const otCell = row.cells[1];
        const otTexto = otCell ? otCell.innerText.trim().toLowerCase() : '';
        if (filtroOt && !otTexto.includes(filtroOt)) visible = false;
        
        if (visible && filtroTipo) {
            const fallaCell = row.cells[4];
            let tipoTexto = '';
            if (fallaCell) { const span = fallaCell.querySelector('span'); tipoTexto = span ? span.innerText.trim() : fallaCell.innerText.trim(); }
            if (tipoTexto !== filtroTipo) visible = false;
        }
        
        if (visible && filtroMaq) {
            const maqCell = row.cells[5];
            const maqTexto = maqCell ? maqCell.innerText.trim() : '';
            if (maqTexto !== filtroMaq) visible = false;
        }
        
        if (visible && filtroEstado) {
            const estadoCell = row.cells[7];
            let estadoTexto = '';
            if (estadoCell) {
                const span = estadoCell.querySelector('span');
                if (span) {
                    const texto = span.innerText.trim();
                    if (texto.includes('Pendiente')) estadoTexto = 'PENDIENTE';
                    else if (texto.includes('Registrado')) estadoTexto = 'REGISTRADO';
                    else if (texto.includes('Corregido')) estadoTexto = 'CORREGIDO';
                }
            }
            if (estadoTexto !== filtroEstado) visible = false;
        }
        
        if (visible && (filtroFechaDesde || filtroFechaHasta)) {
            const fechaCell = row.cells[6];
            let fechaStr = fechaCell ? fechaCell.innerText.trim() : '';
            let fechaDate = null;
            if (fechaStr && fechaStr !== '-') {
                const partes = fechaStr.split(' ');
                const fechaParte = partes[0].split('/');
                if (fechaParte.length === 3) { fechaDate = new Date(fechaParte[2], fechaParte[1]-1, fechaParte[0]); }
            }
            if (filtroFechaDesde && fechaDate) { const desde = new Date(filtroFechaDesde); if (fechaDate < desde) visible = false; }
            if (filtroFechaHasta && fechaDate && visible) { const hasta = new Date(filtroFechaHasta); if (fechaDate > hasta) visible = false; }
        }
        
        row.style.display = visible ? '' : 'none';
        if (visible) visibles++;
    });
}

function limpiarFiltrosDefectos() {
    document.getElementById('filtroOt').value = ''; document.getElementById('filtroTipoFalla').value = '';
    document.getElementById('filtroMaquinista').value = ''; document.getElementById('filtroEstado').value = '';
    document.getElementById('filtroFechaDesde').value = ''; document.getElementById('filtroFechaHasta').value = '';
    aplicarFiltrosDefectos();
}

document.addEventListener('DOMContentLoaded', () => {
    poblarFiltrosDefectos();
    aplicarFiltrosDefectos();
    const filtros = ['filtroOt', 'filtroTipoFalla', 'filtroMaquinista', 'filtroEstado', 'filtroFechaDesde', 'filtroFechaHasta'];
    filtros.forEach(id => {
        const el = document.getElementById(id);
        if (el) { if (el.tagName === 'INPUT' && el.type !== 'checkbox') el.addEventListener('keyup', aplicarFiltrosDefectos); else el.addEventListener('change', aplicarFiltrosDefectos); }
    });
    document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltrosDefectos);
});
function abrirModalReponer(idDefecto, ot, pieza, cantidad) {
    document.getElementById('hdn-reponer-idDefecto').value = idDefecto;
    document.getElementById('lbl-reponer-ot').textContent = ot;
    document.getElementById('lbl-reponer-pieza').textContent = pieza || "Ensamblaje";
    document.getElementById('lbl-reponer-cantidad').textContent = cantidad + " unds";
    document.getElementById('overlayReponer').classList.add('activo');
}
function cerrarModalReponer() { document.getElementById('overlayReponer').classList.remove('activo'); }
document.getElementById('overlayReponer').addEventListener('click', function(e) { if (e.target === this) cerrarModalReponer(); });
// Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>
</body>
</html>