<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean esAdmin       = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean esTizador     = "TIZADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean puedeVer      = permisos.contains("PROD_FALLAS_VER") || esAdmin;
    boolean puedeReg      = (Boolean) request.getAttribute("puedeRegistrar") != null ? (Boolean) request.getAttribute("puedeRegistrar") : false;
    boolean verSeguridad  = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacen    = permisos.contains("ALM_TELA_VER");
    boolean verProduccion = permisos.contains("PROD_OT_VER");
    boolean verReposo     = permisos.contains("PROD_REPOSO_VER") || esAdmin;

    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    @SuppressWarnings("unchecked") List<FallaTela> fallasList   = (List<FallaTela>) request.getAttribute("fallasList");
    @SuppressWarnings("unchecked") List<Tela>      telasMapeo   = (List<Tela>)      request.getAttribute("telasParaMapeo");
    @SuppressWarnings("unchecked") List<Tela>      telasConFall = (List<Tela>)      request.getAttribute("telasConFallas");

    if (fallasList   == null) fallasList   = new ArrayList<>();
    if (telasMapeo   == null) telasMapeo   = new ArrayList<>();
    if (telasConFall == null) telasConFall = new ArrayList<>();

    String exito      = request.getParameter("exito");
    String error      = request.getParameter("error");
    String errorBD    = (String) request.getAttribute("errorBD");
    String idTelaFilt = request.getParameter("idTela");

    long cntMancha  = fallasList.stream().filter(f -> f.getTipoFalla() == FallaTela.TipoFalla.MANCHA).count();
    long cntHueco   = fallasList.stream().filter(f -> f.getTipoFalla() == FallaTela.TipoFalla.HUECO).count();
    long cntDefecto = fallasList.stream().filter(f -> f.getTipoFalla() == FallaTela.TipoFalla.DEFECTO_TEJIDO).count();
    long cntNoApta  = fallasList.stream().filter(FallaTela::isEsAreaNoApta).count();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mapa de Fallas – Sistema Textil</title>
  
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
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 16px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-err { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }

    /* Barra top */
    .barra-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 12px; }
    .barra-top h3 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .btn { display: inline-flex; align-items: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; text-decoration: none; transition: all 0.2s; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }

    /* Tarjetas resumen */
    .resumen-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .card-res { background: var(--color-surface); border-radius: var(--radius-md); padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); display:flex; flex-direction:column; justify-content:center; }
    .card-res .num { font-size: 1.8rem; font-weight: 700; line-height: 1; margin-bottom: 4px; }
    .card-res .lbl { font-size: 0.75rem; color: var(--text-muted); font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; display:flex; align-items:center; gap:4px; }
    
    .c-total .num { color: var(--color-primary); }
    .c-mancha .num { color: #d97706; }
    .c-hueco .num { color: var(--danger-hover); }
    .c-defecto .num { color: #6366f1; }
    .c-noApta .num { color: var(--danger-text); }

    .alerta-noApta { background: var(--warning-bg); border: 1px solid #fcd34d; border-radius: var(--radius-md); padding: 12px 16px; font-size: 0.85rem; color: var(--warning-text); margin-bottom: 24px; display: flex; align-items: center; gap: 8px; font-weight: 500;}

    /* Filtros */
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-end; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
    .filtro-wrap > div { display: flex; flex-direction: column; gap: 6px; }
    .filtro-wrap label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); display:flex; align-items:center; gap:4px; }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .btn-outline { background: var(--color-surface); border: 1px solid var(--border-color); color: var(--text-main); padding: 0.55rem 1rem; border-radius: var(--radius-sm); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: 0.2s; display:inline-flex; align-items:center; gap:6px;}
    .btn-outline:hover { background: var(--color-bg); }

    /* Tabla */
    .tabla-wrap { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow: hidden; }
    .tabla-header { padding: 16px 20px; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; background: #f8fafc;}
    .tabla-header h4 { font-size: 0.95rem; color: var(--color-secondary); font-weight: 600;}
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { padding: 12px 16px; text-align: left; background: #f8fafc; color: var(--text-muted); font-weight: 600; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }
    .text-center { text-align: center; }

    .badge-tipo { display: inline-flex; align-items:center; justify-content:center; gap:4px; width: 130px; text-align: center; padding: 0.35rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; }
    .t-mancha  { background: #fef3c7; color: #b45309; }
    .t-hueco   { background: var(--danger-bg); color: var(--danger-text); }
    .t-defecto { background: #e0e7ff; color: #3730a3; }
    
    .badge-noApta { display: inline-flex; align-items:center; gap:4px; padding: 0.25rem 0.6rem; border-radius: 20px; font-size: 0.72rem; font-weight: 600; background: var(--danger-bg); color: var(--danger-text); }
    .badge-apta   { display: inline-flex; align-items:center; gap:4px; padding: 0.25rem 0.6rem; border-radius: 20px; font-size: 0.72rem; font-weight: 600; background: var(--success-bg); color: var(--success-text); }

    .empty { text-align: center; padding: 48px; color: var(--text-muted); font-size: 0.9rem; }

    .acciones-container { display: flex; gap: 8px; justify-content:center; }
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }

    /* Modal */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(3px);}
    .overlay.activo { display: flex; }
    .modal { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 580px; max-height: 90vh; overflow-y: auto; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    .modal-header { padding: 1.2rem 24px; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; background: #f8fafc; position: sticky; top: 0; z-index: 2;}
    .modal-header h3 { font-size: 1.1rem; color: var(--color-secondary); display:flex; align-items:center; gap:8px; font-weight:600;}
    .modal-body { padding: 24px; }
    .modal-footer { padding: 16px 24px; border-top: 1px solid var(--border-color); display: flex; justify-content: flex-end; gap: 12px; background: #f8fafc; position: sticky; bottom: 0; z-index: 2;}
    .btn-cerrar { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--text-light); transition: 0.2s; }
    .btn-cerrar:hover { color: var(--text-main); }

    /* Form */
    .form-group { margin-bottom: 16px; display:flex; flex-direction:column; gap:6px;}
    .form-group label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .form-hint { font-size: 0.75rem; color: var(--text-muted); }
    .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    textarea.form-control { resize: vertical; min-height: 80px; }

    /* Chips Selector */
    .tipo-selector { display: flex; gap: 12px; flex-wrap: wrap; margin-top:4px;}
    .tipo-chip { flex: 1; min-width: 120px; text-align: center; padding: 0.6rem 0.8rem; border-radius: var(--radius-sm); border: 2px solid var(--border-color); cursor: pointer; font-size: 0.82rem; font-weight: 600; transition: all 0.2s; background: var(--color-surface); color: var(--text-muted); display:flex; align-items:center; justify-content:center; gap:6px;}
    .tipo-chip:hover { border-color: var(--color-primary); color: var(--color-primary); }
    .tipo-chip.sel-mancha  { border-color: #d97706; background: #fef3c7; color: #b45309; }
    .tipo-chip.sel-hueco   { border-color: var(--danger-hover); background: var(--danger-bg); color: var(--danger-text); }
    .tipo-chip.sel-defecto { border-color: #6366f1; background: #e0e7ff; color: #3730a3; }
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
        <% if (_navRep)  { %><a href="<%= _cp %>/tiempos-reposo" class="menu-link">Tiempos de Reposo</a><% } %>
        <% if (_navFall) { %><a href="<%= _cp %>/fallas-tela" class="menu-link activo">Mapa de Fallas</a><% } %>
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
    <h2><i class='bx bx-map-alt'></i> Mapa de Fallas e Imperfecciones</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Cerrar sesión</a>
    </div>
  </header>

  <div class="contenido">

    <%
      String msgOk = null;
      if ("registrado".equals(exito))  msgOk = "Falla registrada correctamente.";
      else if ("eliminado".equals(exito)) msgOk = "Falla eliminada del sistema.";
    %>
    <% if (msgOk != null) { %>
    <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= msgOk %></div>
    <% } %>
    <% if (error != null && !error.isEmpty()) { %>
    <div class="alerta alerta-err"><i class='bx bx-error-circle'></i> Error al procesar la solicitud (código: <%= error %>).</div>
    <% } %>
    <% if (errorBD != null) { %>
    <div class="alerta alerta-err"><i class='bx bx-error'></i> <%= errorBD %></div>
    <% } %>
    <% if ("actualizado".equals(exito)) { %>
    <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> Falla actualizada correctamente.</div>
    <% } %>

    <div class="barra-top">
      <h3>Fallas Registradas <%= esAdmin ? "(Vista Admin)" : "" %></h3>
      <div class="barra-acciones">
        <% if (puedeReg) { %>
        <button class="btn btn-primary" onclick="abrirModal('overlay-reg')">
          <i class='bx bx-plus'></i> Registrar Falla
        </button>
        <% } %>
      </div>
    </div>
    
    <div class="resumen-grid">
      <div class="card-res c-total">
        <div class="num"><%= fallasList.size() %></div>
        <div class="lbl"><i class='bx bx-bar-chart-alt-2'></i> Total Fallas</div>
      </div>
      <div class="card-res c-mancha">
        <div class="num"><%= cntMancha %></div>
        <div class="lbl"><i class='bx bx-water'></i> Manchas</div>
      </div>
      <div class="card-res c-hueco">
        <div class="num"><%= cntHueco %></div>
        <div class="lbl"><i class='bx bx-radio-circle'></i> Huecos</div>
      </div>
      <div class="card-res c-defecto">
        <div class="num"><%= cntDefecto %></div>
        <div class="lbl"><i class='bx bx-grid-alt'></i> Def. Tejido</div>
      </div>
      <div class="card-res c-noApta">
        <div class="num"><%= cntNoApta %></div>
        <div class="lbl"><i class='bx bx-error-alt'></i> Áreas No Aptas</div>
      </div>
    </div>

    <% if (cntNoApta > 0) { %>
    <div class="alerta-noApta">
      <i class='bx bx-error' style="font-size: 1.5rem;"></i>
      <div>
        <strong>Alerta Crítica:</strong> Hay <strong><%= cntNoApta %></strong> área(s) marcada(s) como <strong>NO APTA(S)</strong> para el proceso de tizado. Revisa el detalle en la tabla.
      </div>
    </div>
    <% } %>

    <div class="filtro-wrap">
      <div>
          <label><i class='bx bx-cube'></i> Filtrar por tela:</label>
          <select id="selectFiltroTela" class="form-control" onchange="filtrarPorTela(this.value)" style="width: auto; min-width: 250px;">
            <option value="">-- Todas las telas --</option>
            <% for (Tela t : telasConFall) { %>
            <option value="<%= t.getIdTela() %>" <%= String.valueOf(t.getIdTela()).equals(idTelaFilt) ? "selected" : "" %>>
              <%= t.getCodigoTela() %> | OT: <%= t.getCodigoOt() %> <%= t.getTipoTejido() != null ? " | " + t.getTipoTejido() : "" %>
            </option>
            <% } %>
          </select>
      </div>
      <% if (idTelaFilt != null && !idTelaFilt.isEmpty()) { %>
      <div><a href="<%= request.getContextPath() %>/fallas-tela" class="btn btn-outline" style="height: 38px; display: flex;"><i class='bx bx-x'></i> Quitar filtro</a></div>
      <% } %>
    </div>

    <div class="filtro-wrap">
      <div>
        <label><i class='bx bx-filter-alt'></i> Tipo de falla:</label>
        <select id="filtroTipo" class="form-control" style="width: 150px;">
          <option value="">-- Todos --</option>
          <option value="MANCHA">Mancha</option>
          <option value="HUECO">Hueco</option>
          <option value="DEFECTO_TEJIDO">Defecto Tejido</option>
        </select>
      </div>
      <div>
        <label><i class='bx bx-user'></i> Registrado por:</label>
        <select id="filtroUsuario" class="form-control" style="width: 180px;">
          <option value="">-- Todos --</option>
        </select>
      </div>
      <div>
        <label><i class='bx bx-calendar'></i> Fecha desde:</label>
        <input type="date" id="filtroFechaDesde" class="form-control" style="width: 140px;">
      </div>
      <div>
        <label><i class='bx bx-calendar'></i> Fecha hasta:</label>
        <input type="date" id="filtroFechaHasta" class="form-control" style="width: 140px;">
      </div>
      <div>
        <button id="btnLimpiarFiltros" class="btn-outline"><i class='bx bx-eraser'></i> Limpiar filtros</button>
      </div>
    </div>

    <div class="tabla-wrap">
      <div class="tabla-header">
        <h4>Registro Detallado de Fallas</h4>
        <span style="font-size:0.8rem;color:var(--text-muted); font-weight:600; background:var(--color-bg); padding:4px 10px; border-radius:20px;"><%= fallasList.size() %> registros</span>
      </div>
      <% if (fallasList.isEmpty()) { %>
      <div class="empty">
        <i class='bx bx-search' style="font-size: 3rem; color: var(--border-color); display:block; margin-bottom:12px;"></i>
        <% if (idTelaFilt != null && !idTelaFilt.isEmpty()) { %>
          Sin fallas registradas para esta tela.
        <% } else { %>
          No hay fallas registradas aún.
          <% if (puedeReg) { %> Usa el botón <strong>Registrar Falla</strong> para comenzar el mapeo.<% } %>
        <% } %>
      </div>
      <% } else { %>
      <div style="overflow-x:auto">
        <table id="tablaFallas">
          <thead>
            <tr>
              <th>#</th><th>Tela</th><th>OT</th><th>Tipo de Falla</th>
              <th class="text-center">Rollo</th><th class="text-center">Metro</th>
              <th class="text-center">Ancho</th><th class="text-center">Largo</th>
              <th class="text-center">Área</th><th>Descripción</th><th>Registrado por</th>
              <th>Fecha</th>
              <% if (puedeReg) { %><th class="text-center">Acciones</th><% } %>
            </tr>
          </thead>
          <tbody>
            <% for (FallaTela f : fallasList) { %>
            <tr>
              <td class="text-center" style="color:var(--text-muted); font-family:monospace;"><%= f.getIdFalla() %></td>
              <td><strong><%= f.getCodigoTela() %></strong></td>
              <td><%= f.getCodigoOt() %></td>
              <td>
                <%
                  String tipoCss = "t-mancha", tipoLabel = "Mancha", icon="bx-water";
                  if (f.getTipoFalla() == FallaTela.TipoFalla.HUECO) { tipoCss="t-hueco"; tipoLabel="Hueco"; icon="bx-radio-circle"; }
                  else if (f.getTipoFalla() == FallaTela.TipoFalla.DEFECTO_TEJIDO) { tipoCss="t-defecto"; tipoLabel="Defecto Tejido"; icon="bx-grid-alt"; }
                %>
                <span class="badge-tipo <%= tipoCss %>"><i class='bx <%= icon %>'></i> <%= tipoLabel %></span>
              </td>
              <td class="text-center">R-<%= f.getPosicionRollo() %></td>
              <td class="text-center" style="font-weight:600;"><%= f.getPosicionMetro() %> m</td>
              <td class="text-center"><%= f.getAnchoCm() != null ? f.getAnchoCm() + " cm" : "—" %></td>
              <td class="text-center"><%= f.getLargoCm() != null ? f.getLargoCm() + " cm" : "—" %></td>
              <td class="text-center">
                <% if (f.isEsAreaNoApta()) { %>
                <span class="badge-noApta"><i class='bx bx-x-circle'></i> No Apta</span>
                <% } else { %>
                <span class="badge-apta"><i class='bx bx-check-circle'></i> Apta</span>
                <% } %>
              </td>
              <td style="max-width:180px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis" title="<%= f.getDescripcion() != null ? f.getDescripcion() : "" %>">
                <%= f.getDescripcion() != null && !f.getDescripcion().isEmpty() ? f.getDescripcion() : "—" %>
              </td>
              <td><%= f.getNombreTizador() %></td>
              <td style="color:var(--text-muted); font-size:0.8rem;"><%= f.getFechaRegistro() != null ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(f.getFechaRegistro()) : "—" %></td>
              <% if (puedeReg) { %>
              <td>
                <div class="acciones-container">
                    <button type="button" class="btn-icon edit" title="Editar"
                    onclick="abrirModalEditar(
                        '<%= f.getIdFalla() %>',
                        '<%= f.getIdTela() %>',
                        '<%= f.getTipoFalla().name() %>',
                        '<%= f.getPosicionRollo() %>',
                        '<%= f.getPosicionMetro() %>',
                        '<%= f.getAnchoCm() != null ? f.getAnchoCm() : "" %>',
                        '<%= f.getLargoCm() != null ? f.getLargoCm() : "" %>',
                        '<%= f.isEsAreaNoApta() %>',
                        '<%= f.getDescripcion() != null ? f.getDescripcion().replace("'","\\x27") : "" %>'
                    )"><i class='bx bx-edit-alt'></i></button>
                    <form method="post" action="<%= request.getContextPath() %>/fallas-tela" style="display:inline" onsubmit="return confirm('¿Eliminar esta falla del registro?')">
                      <input type="hidden" name="accion" value="eliminar">
                      <input type="hidden" name="idFalla" value="<%= f.getIdFalla() %>">
                      <button type="submit" class="btn-icon delete" title="Eliminar"><i class='bx bx-trash'></i></button>
                    </form>
                </div>
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

<div class="overlay" id="overlay-reg">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-map-alt'></i> Registrar Falla en Tela</h3>
      <button class="btn-cerrar" onclick="cerrarModal('overlay-reg')"><i class='bx bx-x'></i></button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/fallas-tela" onsubmit="return validarFalla()">
      <input type="hidden" name="accion" value="registrar">
      <input type="hidden" name="esAreaNoApta" id="esAreaNoApta" value="true">
      <div class="modal-body">

        <div class="form-group">
          <label for="idTela">Tela Mapeada <span class="req" style="color:var(--danger-hover)">*</span></label>
          <select name="idTela" id="idTela" class="form-control" onchange="actualizarMaxRollos(this)" required>
            <option value="">-- Selecciona una tela --</option>
            <% for (Tela t : telasMapeo) { %>
            <option value="<%= t.getIdTela() %>" data-rollos="<%= t.getNumRollos() %>">
              <%= t.getCodigoTela() %> <%= t.getCodigoOt() != null ? "| OT: " + t.getCodigoOt() : "" %> <%= t.getTipoTejido() != null ? "| " + t.getTipoTejido() : "" %>
            </option>
            <% } %>
          </select>
          <% if (telasMapeo.isEmpty()) { %>
          <p class="form-hint" style="color:var(--danger-hover)"><i class='bx bx-error'></i> No hay telas disponibles para mapeo.</p>
          <% } %>
        </div>

        <div class="form-group">
          <label>Tipo de Falla <span style="color:var(--danger-hover)">*</span> <small style="color:var(--text-muted);font-weight:400">(Criterio CA1 – HU02)</small></label>
          <div class="tipo-selector">
            <div class="tipo-chip" id="chip-mancha" onclick="seleccionarTipo('MANCHA','sel-mancha')"><i class='bx bx-water'></i> Mancha</div>
            <div class="tipo-chip" id="chip-hueco" onclick="seleccionarTipo('HUECO','sel-hueco')"><i class='bx bx-radio-circle'></i> Hueco</div>
            <div class="tipo-chip" id="chip-defecto" onclick="seleccionarTipo('DEFECTO_TEJIDO','sel-defecto')"><i class='bx bx-grid-alt'></i> Defecto Tejido</div>
          </div>
          <input type="hidden" name="tipoFalla" id="tipoFalla" value="">
          <p class="form-hint" id="tipoHint" style="color:var(--danger-hover);display:none"><i class='bx bx-error-circle'></i> Selecciona un tipo de falla.</p>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="posicionRollo">Número de Rollo <span style="color:var(--danger-hover)">*</span></label>
            <input type="number" name="posicionRollo" id="posicionRollo" class="form-control" min="1" max="999" value="1" required>
            <p class="form-hint" id="hintRollos"><i class='bx bx-info-circle'></i> Rollo dentro de la tela.</p>
          </div>
          <div class="form-group">
            <label for="posicionMetro">Posición (metro) <span style="color:var(--danger-hover)">*</span></label>
            <input type="number" name="posicionMetro" id="posicionMetro" class="form-control" min="0" step="0.01" value="" placeholder="Ej: 7.50" required>
            <p class="form-hint"><i class='bx bx-ruler'></i> Ubicación lineal.</p>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="anchoCm">Ancho falla (cm)</label>
            <input type="number" name="anchoCm" id="anchoCm" class="form-control" min="0" step="0.1" placeholder="Ej: 5.0">
          </div>
          <div class="form-group">
            <label for="largoCm">Largo falla (cm)</label>
            <input type="number" name="largoCm" id="largoCm" class="form-control" min="0" step="0.1" placeholder="Ej: 3.0">
          </div>
        </div>

        <div class="form-group" style="background:var(--color-bg); padding:16px; border-radius:8px; border:1px solid var(--border-color);">
          <label style="display:flex;align-items:center;gap:.5rem;cursor:pointer; margin-bottom:4px;">
            <input type="checkbox" id="chkNoApta" checked onchange="document.getElementById('esAreaNoApta').value = this.checked ? 'true':'false'" style="width:16px;height:16px; accent-color:var(--danger-hover);">
            <span style="color:var(--danger-text);">Marcar como Área No Apta para Tizado <small style="color:var(--text-muted)">(CA2 – HU02)</small></span>
          </label>
          <p class="form-hint"><i class='bx bx-bulb'></i> Activa la alerta visual crítica en el mapa de fallas.</p>
        </div>

        <div class="form-group">
          <label for="descripcion">Descripción y Detalles</label>
          <textarea name="descripcion" id="descripcion" class="form-control" placeholder="Ej: Mancha de aceite en borde derecho del rollo 1..."></textarea>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal('overlay-reg')">Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Registrar Falla</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="overlay-editar">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-edit'></i> Editar Falla en Tela</h3>
      <button class="btn-cerrar" onclick="cerrarModal('overlay-editar')"><i class='bx bx-x'></i></button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/fallas-tela" onsubmit="return validarEdicion()">
      <input type="hidden" name="accion" value="actualizar">
      <input type="hidden" name="idFalla" id="edit_idFalla">
      <div class="modal-body">

        <div class="form-group">
          <label>Tela Asociada</label>
          <input type="text" id="edit_codigoTela" class="form-control" readonly disabled style="background:var(--color-bg);">
          <input type="hidden" name="idTela" id="edit_idTela">
        </div>

        <div class="form-group">
          <label>Tipo de Falla <span style="color:var(--danger-hover)">*</span></label>
          <div class="tipo-selector">
            <div class="tipo-chip" id="edit-chip-mancha" onclick="seleccionarTipoEdicion('MANCHA','sel-mancha')"><i class='bx bx-water'></i> Mancha</div>
            <div class="tipo-chip" id="edit-chip-hueco" onclick="seleccionarTipoEdicion('HUECO','sel-hueco')"><i class='bx bx-radio-circle'></i> Hueco</div>
            <div class="tipo-chip" id="edit-chip-defecto" onclick="seleccionarTipoEdicion('DEFECTO_TEJIDO','sel-defecto')"><i class='bx bx-grid-alt'></i> Defecto Tejido</div>
          </div>
          <input type="hidden" name="tipoFalla" id="edit_tipoFalla" value="">
          <p class="form-hint" id="editTipoHint" style="color:var(--danger-hover);display:none">Selecciona un tipo de falla.</p>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Número de Rollo <span style="color:var(--danger-hover)">*</span></label>
            <input type="number" name="posicionRollo" id="edit_posicionRollo" class="form-control" min="1" required>
          </div>
          <div class="form-group">
            <label>Posición (metro) <span style="color:var(--danger-hover)">*</span></label>
            <input type="number" name="posicionMetro" id="edit_posicionMetro" class="form-control" step="0.01" required>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Ancho (cm)</label>
            <input type="number" name="anchoCm" id="edit_anchoCm" class="form-control" step="0.1">
          </div>
          <div class="form-group">
            <label>Largo (cm)</label>
            <input type="number" name="largoCm" id="edit_largoCm" class="form-control" step="0.1">
          </div>
        </div>

        <div class="form-group" style="background:var(--color-bg); padding:16px; border-radius:8px; border:1px solid var(--border-color);">
          <label style="display:flex;align-items:center;gap:.5rem;cursor:pointer; margin-bottom:4px;">
            <input type="checkbox" id="edit_chkNoApta" style="width:16px;height:16px; accent-color:var(--danger-hover);">
            <span style="color:var(--danger-text);">Marcar como Área No Apta para Tizado</span>
          </label>
          <input type="hidden" name="esAreaNoApta" id="edit_esAreaNoApta" value="true">
        </div>

        <div class="form-group">
          <label>Descripción</label>
          <textarea name="descripcion" id="edit_descripcion" class="form-control"></textarea>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal('overlay-editar')">Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar Cambios</button>
      </div>
    </form>
  </div>
</div>

<script>
  // LÓGICA JAVASCRIPT INTACTA
  function abrirModal(id)  { document.getElementById(id).classList.add('activo'); }
  function cerrarModal(id) { document.getElementById(id).classList.remove('activo'); }
  document.querySelectorAll('.overlay').forEach(function(ov){
    ov.addEventListener('click', function(e){ if(e.target===ov) cerrarModal(ov.id); });
  });

  var tipoSeleccionado = '';
  function seleccionarTipo(tipo, cls) {
    tipoSeleccionado = tipo;
    document.getElementById('tipoFalla').value = tipo;
    document.querySelectorAll('.tipo-chip').forEach(function(c){ c.className='tipo-chip'; });
    var id = tipo==='MANCHA'?'chip-mancha':tipo==='HUECO'?'chip-hueco':'chip-defecto';
    document.getElementById(id).classList.add(cls);
    document.getElementById('tipoHint').style.display = 'none';
  }

  function actualizarMaxRollos(sel) {
    var opt = sel.options[sel.selectedIndex];
    var maxRollos = opt.getAttribute('data-rollos') || 999;
    var inp = document.getElementById('posicionRollo');
    inp.max = maxRollos;
    document.getElementById('hintRollos').innerHTML = "<i class='bx bx-info-circle'></i> Rollo 1 a " + maxRollos + " disponibles en esta tela.";
  }

  function validarFalla() {
    if (!document.getElementById('idTela').value) { alert('Selecciona una tela.'); return false; }
    if (!tipoSeleccionado) { document.getElementById('tipoHint').style.display = 'block'; return false; }
    var metro = parseFloat(document.getElementById('posicionMetro').value);
    if (isNaN(metro) || metro < 0) { alert('Ingresa una posición en metros válida.'); return false; }
    return true;
  }

  function filtrarPorTela(val) {
    var base = '<%= request.getContextPath() %>/fallas-tela';
    window.location = val ? base + '?accion=porTela&idTela=' + val : base;
  }

  var tipoEdicionSeleccionado = '';
  function seleccionarTipoEdicion(tipo, cls) {
    tipoEdicionSeleccionado = tipo;
    document.getElementById('edit_tipoFalla').value = tipo;
    document.querySelectorAll('#overlay-editar .tipo-chip').forEach(function(c){ c.className = 'tipo-chip'; });
    var id = tipo==='MANCHA'?'edit-chip-mancha':tipo==='HUECO'?'edit-chip-hueco':'edit-chip-defecto';
    document.getElementById(id).classList.add(cls);
    document.getElementById('editTipoHint').style.display = 'none';
  }

  function abrirModalEditar(idFalla, idTela, tipoFalla, rollo, metro, ancho, largo, noApta, descripcion) {
    document.getElementById('edit_idFalla').value = idFalla;
    document.getElementById('edit_idTela').value = idTela;
    document.getElementById('edit_codigoTela').value = document.querySelector('option[value="'+idTela+'"]')?.text || idTela;
    document.getElementById('edit_posicionRollo').value = rollo;
    document.getElementById('edit_posicionMetro').value = metro;
    document.getElementById('edit_anchoCm').value = ancho;
    document.getElementById('edit_largoCm').value = largo;
    document.getElementById('edit_descripcion').value = descripcion;
    document.getElementById('edit_chkNoApta').checked = (noApta === true || noApta === 'true');
    document.getElementById('edit_esAreaNoApta').value = document.getElementById('edit_chkNoApta').checked ? 'true' : 'false';
    seleccionarTipoEdicion(tipoFalla, 'sel-'+ (tipoFalla==='MANCHA'?'mancha':tipoFalla==='HUECO'?'hueco':'defecto'));
    abrirModal('overlay-editar');
  }

  document.getElementById('edit_chkNoApta')?.addEventListener('change', function() {
    document.getElementById('edit_esAreaNoApta').value = this.checked ? 'true' : 'false';
  });

  function validarEdicion() {
    if (!document.getElementById('edit_tipoFalla').value) { document.getElementById('editTipoHint').style.display = 'block'; return false; }
    var metro = parseFloat(document.getElementById('edit_posicionMetro').value);
    if (isNaN(metro) || metro < 0) { alert('Ingresa una posición en metros válida.'); return false; }
    return true;
  }

  function poblarUsuarios() {
    var usuariosSet = new Set();
    var rows = document.querySelectorAll('#tablaFallas tbody tr');
    rows.forEach(function(row) {
        var usuario = row.cells[10]?.innerText.trim(); 
        if (usuario && usuario !== '—') usuariosSet.add(usuario);
    });
    var select = document.getElementById('filtroUsuario');
    select.innerHTML = '<option value="">-- Todos --</option>';
    Array.from(usuariosSet).sort().forEach(function(u) {
        var opt = document.createElement('option');
        opt.value = u; opt.textContent = u; select.appendChild(opt);
    });
  }

  function aplicarFiltros() {
    var tipo = document.getElementById('filtroTipo').value;
    var usuario = document.getElementById('filtroUsuario').value;
    var fechaDesde = document.getElementById('filtroFechaDesde').value;
    var fechaHasta = document.getElementById('filtroFechaHasta').value;

    var rows = document.querySelectorAll('#tablaFallas tbody tr');
    rows.forEach(function(row) {
        var mostrar = true;
        var tipoCelda = row.cells[3];
        var tipoTexto = '';
        if (tipoCelda) {
            var span = tipoCelda.querySelector('span');
            if (span) tipoTexto = span.innerText.trim();
            if (tipoTexto.includes('Mancha')) tipoTexto = 'MANCHA';
            else if (tipoTexto.includes('Hueco')) tipoTexto = 'HUECO';
            else if (tipoTexto.includes('Defecto Tejido')) tipoTexto = 'DEFECTO_TEJIDO';
        }
        if (tipo && tipoTexto !== tipo) mostrar = false;

        var usuarioCelda = row.cells[10];
        var usuarioTexto = usuarioCelda ? usuarioCelda.innerText.trim() : '';
        if (usuario && usuarioTexto !== usuario) mostrar = false;

        var fechaCelda = row.cells[11];
        if (fechaCelda && (fechaDesde || fechaHasta)) {
            var fechaStr = fechaCelda.innerText.trim();
            if (fechaStr && fechaStr !== '—') {
                var partes = fechaStr.split(' ')[0];
                var partesDia = partes.split('/');
                if (partesDia.length === 3) {
                    var fechaFalla = new Date(partesDia[2].length === 2 ? '20' + partesDia[2] : partesDia[2], partesDia[1]-1, partesDia[0]);
                    if (fechaDesde) { var fechaDesdeObj = new Date(fechaDesde); if (fechaFalla < fechaDesdeObj) mostrar = false; }
                    if (fechaHasta && mostrar) { var fechaHastaObj = new Date(fechaHasta); if (fechaFalla > fechaHastaObj) mostrar = false; }
                }
            }
        }
        row.style.display = mostrar ? '' : 'none';
    });
  }

  function limpiarFiltros() {
    document.getElementById('filtroTipo').value = ''; document.getElementById('filtroUsuario').value = '';
    document.getElementById('filtroFechaDesde').value = ''; document.getElementById('filtroFechaHasta').value = '';
    aplicarFiltros();
  }

  document.addEventListener('DOMContentLoaded', function() {
    poblarUsuarios();
    document.getElementById('filtroTipo').addEventListener('change', aplicarFiltros);
    document.getElementById('filtroUsuario').addEventListener('change', aplicarFiltros);
    document.getElementById('filtroFechaDesde').addEventListener('change', aplicarFiltros);
    document.getElementById('filtroFechaHasta').addEventListener('change', aplicarFiltros);
    document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltros);
  });
  // Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>

</body>
</html>