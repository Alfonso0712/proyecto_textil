<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="modelo.*, java.util.*, java.text.SimpleDateFormat" %>
<%
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    List<Tela> listaTelas = (List<Tela>) request.getAttribute("listaTelas");
    if (listaTelas == null) listaTelas = new ArrayList<>();

    List<OrdenTrabajo> otsActivas = (List<OrdenTrabajo>) request.getAttribute("otsActivas");
    if (otsActivas == null) otsActivas = new ArrayList<>();
    
    List<CatalogoTela> catalogoTelas = (List<CatalogoTela>) request.getAttribute("catalogoTelas");
    if (catalogoTelas == null) catalogoTelas = new ArrayList<>();

    @SuppressWarnings("unchecked")
    Map<Integer, List<FotoTela>> fotosMap =
        (Map<Integer, List<FotoTela>>) request.getAttribute("fotosMap");
    if (fotosMap == null) fotosMap = new HashMap<>();

    String mensajeExito = (String) request.getAttribute("mensajeExito");
    String mensajeError = request.getParameter("error");

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();
    boolean puedeRegistrar = permisos.contains("ALM_TELA_REGISTRAR");

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    SimpleDateFormat sdfLargo = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");

    // Error de formulario al volver del servlet (modal reabre)
    String errorForm    = (String) request.getAttribute("error");
    boolean abrirModal  = (errorForm != null);

    String filtroCodigo    = (String) request.getAttribute("filtroCodigo");
    String filtroProveedor = (String) request.getAttribute("filtroProveedor");
    String filtroFechaIni  = (String) request.getAttribute("filtroFechaIni");
    String filtroFechaFin  = (String) request.getAttribute("filtroFechaFin");

    if (filtroCodigo == null)    filtroCodigo = "";
    if (filtroProveedor == null) filtroProveedor = "";
    if (filtroFechaIni == null)  filtroFechaIni = "";
    if (filtroFechaFin == null)  filtroFechaFin = "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Almacén – Tela Recibida</title>

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

    .contenido { flex: 1; padding: 24px; overflow-y: auto; }

    /* ── ALERTAS ── */
    .alerta { padding: 12px 16px; border-radius: var(--radius-md); font-size: 0.85rem; font-weight: 500; display: flex; align-items: center; gap: 8px; margin-bottom: 24px; }
    .alerta-ok { background: var(--success-bg); color: var(--success-text); border: 1px solid #a7f3d0; }
    .alerta-err { background: var(--danger-bg); color: var(--danger-text); border: 1px solid #fecaca; }
    .alerta-warn { background: var(--warning-bg); color: var(--warning-text); border: 1px solid #fcd34d; }

    /* ── TOOLBAR ── */
    .toolbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; margin-bottom: 20px; }
    .toolbar h3 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    
    .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; background: var(--color-surface); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s; font-family: 'Inter', sans-serif;}
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper { position: relative; flex: 1; min-width: 180px; }
    .search-wrapper .bx-search { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }
    .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); }
    .btn-outline:hover { background: var(--color-bg); }

    /* ── TABLA ── */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
    td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }
    .sin-datos { text-align: center; padding: 48px; color: var(--text-muted); }

    .badge-estado { display: inline-block; padding: 0.35rem 0.8rem; border-radius: 6px; font-size: 0.72rem; font-weight: 700; text-transform: uppercase; }
    .est-ACEPTADO  { background: var(--success-bg); color: var(--success-text); }
    .est-OBSERVADO { background: var(--warning-bg); color: var(--warning-text); }
    .est-RECHAZADO { background: var(--danger-bg); color: var(--danger-text); }
    
    .badge-origen { display: inline-block; padding: 0.35rem 0.8rem; border-radius: 6px; font-size: 0.72rem; font-weight: 600; }
    .or-CLIENTE { background: #e0e7ff; color: #3730a3; }
    .or-TALLER  { background: #f3e8ff; color: #6b21a8; }
    
    .dif-ok   { color: var(--success-text); font-weight: 600; }
    .dif-warn { color: #d97706; font-weight: 700; }
    .dif-err  { color: var(--danger-hover); font-weight: 700; }
    
    .reposo-badge { display: inline-block; background: var(--warning-bg); color: var(--warning-text); border-radius: 20px; padding: 0.2rem 0.6rem; font-size: 0.7rem; font-weight: 600; display:flex; align-items:center; gap:4px; width: max-content;}
    
    .acciones-container { display: flex; gap: 8px; }
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.view { color: #0369a1; background: #e0f2fe; }
    .btn-icon.view:hover { background: #bae6fd; color: #0284c7; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }

    /* ── MODALES ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: 1rem; backdrop-filter: blur(3px); }
    .overlay.activo { display: flex; }

    .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 820px; max-height: 92vh; display: flex; flex-direction: column; box-shadow: 0 20px 40px rgba(0,0,0,0.15); overflow: hidden; }
    .modal-flotante-lg { max-width: 1000px; }

    .modal-header { background: var(--color-secondary); padding: 1rem 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
    .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; display:flex; align-items:center; gap:8px; font-weight:600;}
    .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: 0.2s; }
    .modal-close:hover { color: #fff; }

    .modal-flotante > form { display: flex; flex-direction: column; flex: 1; min-height: 0; overflow: hidden; }
    .modal-body { padding: 1.5rem 2rem; overflow-y: auto; flex: 1; min-height: 0; }
    
    .modal-footer { padding: 1rem 2rem; border-top: 1px solid var(--border-color); display: flex; gap: 12px; justify-content: flex-end; flex-shrink: 0; background: #f8fafc; }

    /* Estilos dentro del modal */
    .alerta-error-modal { background: var(--danger-bg); border: 1px solid #fca5a5; color: var(--danger-text); border-radius: var(--radius-md); padding: 12px; font-size: 0.85rem; margin-bottom: 1.2rem; display:flex; align-items:center; gap:8px;}
    .sec-titulo { font-size: 0.85rem; font-weight: 700; color: var(--color-secondary); text-transform: uppercase; letter-spacing: 0.05em; border-bottom: 2px solid var(--border-color); padding-bottom: 0.4rem; margin: 1.5rem 0 1rem; display:flex; align-items:center; gap:6px;}
    .sec-titulo:first-of-type { margin-top: 0; }
    
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    
    .modal-body label { display: block; font-size: 0.82rem; font-weight: 600; color: var(--text-main); margin-bottom: 4px; }
    .req { color: var(--danger-hover); margin-left: 2px; }
    
    .modal-body textarea { resize: vertical; min-height: 80px; }
    .hint { font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; }
    
    .alerta-peso-detalle { background: var(--warning-bg); border: 1px solid #fcd34d; color: var(--warning-text); border-radius: var(--radius-md); padding: 10px 16px; font-size: 0.85rem; margin-top: 10px; display: flex; align-items: center; gap: 8px;}
    
    .check-fila { display: flex; align-items: center; gap: 10px; padding: 10px 16px; background: var(--color-bg); border: 1px solid var(--border-color); border-radius: var(--radius-sm); margin-top: 8px;}
    .check-fila input[type="checkbox"] { width: 16px; height: 16px; cursor: pointer; accent-color: var(--color-primary); }
    .check-fila label { margin: 0; font-weight: 600; cursor: pointer; font-size: 0.85rem; }
    
    .upload-area { border: 2px dashed var(--border-color); border-radius: var(--radius-md); padding: 1.5rem; text-align: center; background: var(--color-bg); transition: border-color .2s; cursor: pointer; }
    .upload-area:hover { border-color: var(--color-primary); background: #f0f4ff; }
    .upload-area .ico { font-size: 2rem; display: block; margin-bottom: 8px; color: var(--color-primary);}
    .upload-area p { font-size: 0.82rem; color: var(--text-muted); margin-bottom:4px;}
    .upload-area input[type="file"] { display: none; }
    
    #preview-fotos-modal, #preview-fotos-edicion { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
    #preview-fotos-modal img, #preview-fotos-edicion img { width: 70px; height: 70px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border-color); }
    
    .info-registrador { background: var(--color-bg); border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 0.55rem 1rem; font-size: 0.85rem; color: var(--text-main); display: flex; align-items: center; gap: 8px; }

    /* Layout Modal Detalle */
    .layout-detalle { display: grid; grid-template-columns: 1fr 280px; gap: 1.5rem; }
    .grid-datos { display: grid; grid-template-columns: 1fr 1fr; gap: 12px 24px; }
    .dato { padding: 6px 0; border-bottom: 1px solid var(--color-bg); }
    .dato .lbl { font-size: 0.75rem; color: var(--text-muted); font-weight: 600; text-transform: uppercase; margin-bottom: 2px; }
    .dato .val { font-size: 0.9rem; color: var(--text-main); font-weight: 500; }
    
    .galeria { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 8px; }
    .galeria a img { width: 120px; height: 120px; object-fit: cover; border-radius: var(--radius-md); border: 1px solid var(--border-color); transition: border-color .2s; }
    .galeria a:hover img { border-color: var(--color-primary); }
    .sin-fotos { color: var(--text-muted); font-size: 0.85rem; padding: 12px 0; }

    /* Scroll superior */
    .top-scroll-wrapper { overflow-x: auto; overflow-y: hidden; height: 14px; margin-bottom: 8px; position: sticky; top: -1.5rem; z-index: 10; display: none; }
    .top-scroll-wrapper::-webkit-scrollbar { height: 12px; }
    .top-scroll-wrapper::-webkit-scrollbar-track { background: var(--color-bg); border-radius: 6px; }
    .top-scroll-wrapper::-webkit-scrollbar-thumb { background: var(--text-light); border-radius: 6px; }
    .top-scroll-wrapper::-webkit-scrollbar-thumb:hover { background: var(--text-muted); }
    #top-scrollbar-fake-content { height: 1px; }
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-store'></i> Almacén</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navAlm) { %><a href="<%= _cp %>/inventario" class="menu-link activo">Tela Recibida</a><% } %>
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
    <h2><i class='bx bx-box'></i> Almacén – Control de Tela Recibida</h2>
    <div class="user-info">
      <span><%= sesion.getNombreCompleto() %></span>
      <span class="badge-rol"><%= sesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
    </div>
  </header>

  <div class="contenido">

    <% if (mensajeExito != null) { %>
      <% if (mensajeExito.contains("ALERTA")) { %>
        <div class="alerta alerta-warn"><i class='bx bx-error'></i> <%= mensajeExito %></div>
      <% } else { %>
        <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= mensajeExito %></div>
      <% } %>
    <% } %>
    <% if (mensajeError != null) { %>
      <div class="alerta alerta-err"><i class='bx bx-error-circle'></i> <%= java.net.URLDecoder.decode(mensajeError, "UTF-8") %></div>
    <% } %>
    
    <div class="toolbar">
        <h3>Registros de Tela Recibida (<%= listaTelas.size() %>)</h3>
        <% if (puedeRegistrar) { %>
          <button type="button" class="btn btn-primary" onclick="abrirModalRegistro()">
            <i class='bx bx-plus'></i> Registrar Ingreso de Tela
          </button>
        <% } %>
    </div>
      
    <form class="filtro-wrap" method="get" action="<%= request.getContextPath() %>/inventario">
        <div class="search-wrapper">
          <i class='bx bx-search'></i>
          <input type="text" name="fCodigo" class="form-control" placeholder="Código de tela..." value="<%= filtroCodigo %>">
        </div>
        <div>
          <input type="text" name="fProveedor" class="form-control" placeholder="Proveedor" value="<%= filtroProveedor %>" style="width:160px;">
        </div>
        <div>
          <input type="date" name="fFechaIni" class="form-control" value="<%= filtroFechaIni %>" title="Fecha inicio" style="width:140px;">
        </div>
        <div>
          <input type="date" name="fFechaFin" class="form-control" value="<%= filtroFechaFin %>" title="Fecha fin" style="width:140px;">
        </div>
        <div style="display: flex; gap: 8px;">
          <button type="submit" class="btn btn-primary"><i class='bx bx-filter-alt'></i> Buscar</button>
          <a href="<%= request.getContextPath() %>/inventario" class="btn btn-outline"><i class='bx bx-eraser'></i> Limpiar</a>
        </div>
    </form>

    <div id="top-scrollbar-container" class="top-scroll-wrapper">
        <div id="top-scrollbar-fake-content"></div>
    </div>        
    
    <div class="card">
      <% if (listaTelas.isEmpty()) { %>
        <div class="sin-datos">
          <i class='bx bx-box' style="font-size: 3rem; color: var(--border-color); display:block; margin-bottom:12px;"></i>
          No hay telas registradas aún.
          <% if (puedeRegistrar) { %>
            <br>
            <button type="button" class="btn btn-primary" style="margin-top:1rem;" onclick="abrirModalRegistro()">
              <i class='bx bx-plus'></i> Registrar primer ingreso
            </button>
          <% } %>
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th><th>Código Tela</th><th>OT Vinculada</th><th>Origen</th>
            <th>Proveedor</th><th style="text-align:right;">Peso Guía (kg)</th><th style="text-align:right;">Peso Real (kg)</th>
            <th style="text-align:center;">Diferencia</th><th style="text-align:center;">Estado Calidad</th><th>Reposo</th>
            <th>Registrado por</th><th>Fecha</th><th style="text-align:center;">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% int i = 1;
             for (Tela t : listaTelas) {
               double difVal  = t.getDiferenciaPeso() != null ? t.getDiferenciaPeso().doubleValue() : 0;
               double guiaVal = t.getPesoGuia() != null ? t.getPesoGuia().doubleValue() : 1;
               double pct     = guiaVal > 0 ? Math.abs(difVal / guiaVal * 100) : 0;
               String difClass = pct <= 0.5 ? "dif-ok" : (pct <= 1.0 ? "dif-warn" : "dif-err");
               List<FotoTela> fotasTela = fotosMap.getOrDefault(t.getIdTela(), new ArrayList<>());
               String fotasJSON = fotasTela.stream()
                   .map(f -> "'" + f.getRutaRelativa().replace("'","") + "'")
                   .collect(java.util.stream.Collectors.joining(","));
          %>
          <tr>
            <td style="color:var(--text-muted);"><%= i++ %></td>
            <td style="font-family:monospace; font-weight:700; color:var(--color-primary); font-size:0.95rem;"><%= t.getCodigoTela() %></td>
            <td><span style="font-family:monospace; font-size:.85rem; font-weight:600;"><%= t.getCodigoOt() != null ? t.getCodigoOt() : "—" %></span></td>
            <td><span class="badge-origen or-<%= t.getOrigen().name() %>"><%= t.getOrigen().name() %></span></td>
            <td><%= t.getProveedor() != null ? t.getProveedor() : "—" %></td>
            <td style="text-align:right; font-weight:500;"><%= t.getPesoGuia() %></td>
            <td style="text-align:right; font-weight:500;"><%= t.getPesoReal() %></td>
            <td style="text-align:center;" class="<%= difClass %>">
              <%= difVal >= 0 ? "+" : "" %><%= String.format("%.3f", difVal) %>
              <% if (pct > 1.0) { %> <i class='bx bx-error' style="font-size:0.8rem;"></i><% } %>
            </td>
            <td style="text-align:center;"><span class="badge-estado est-<%= t.getEstadoCalidad().name() %>"><%= t.getEstadoCalidad().name() %></span></td>
            <td>
              <% if (t.isRequiereReposo()) { %><span class="reposo-badge"><i class='bx bx-time-five'></i> Sí</span>
              <% } else { %><span style="color:var(--text-light); font-size:.75rem;">No</span><% } %>
            </td>
            <td style="font-size:.8rem;"><%= t.getNombreRegistrador() != null ? t.getNombreRegistrador() : "—" %></td>
            <td style="font-size:.78rem; color:var(--text-muted);"><%= t.getFechaIngreso() != null ? sdf.format(t.getFechaIngreso()) : "—" %></td>
            <td>
                <div class="acciones-container" style="justify-content:center;">
                  <button type="button" class="btn-icon view" title="Ver Detalle"
                    onclick="abrirModalDetalle(
                      '<%= t.getCodigoTela() %>',
                      '<%= t.getCodigoOt() != null ? t.getCodigoOt() : "—" %>',
                      '<%= t.getOrigen().name() %>',
                      '<%= t.getProveedor() != null ? t.getProveedor().replace("'","\\x27") : "—" %>',
                      '<%= t.getNombreCatalogoTela() != null ? t.getNombreCatalogoTela().replace("'","\\x27") : "—" %>',
                      '<%= t.getTipoTejido() != null ? t.getTipoTejido().replace("'","\\x27") : "—" %>',
                      '<%= t.getColor() != null ? t.getColor().replace("'","\\x27") : "—" %>',
                      '<%= t.getNumRollos() %>',
                      '<%= t.getPesoGuia() %>',
                      '<%= t.getPesoReal() %>',
                      '<%= String.format("%.3f", difVal) %>',
                      '<%= String.format("%.2f", pct) %>',
                      '<%= t.getEstadoCalidad().name() %>',
                      '<%= t.isRequiereReposo() %>',
                      `<%= t.getObservaciones() != null ? t.getObservaciones().replace("`","\\x60").replace("'","\\x27") : "" %>`,
                      '<%= t.getNombreRegistrador() != null ? t.getNombreRegistrador().replace("'","\\x27") : "—" %>',
                      '<%= t.getFechaIngreso() != null ? sdfLargo.format(t.getFechaIngreso()) : "—" %>',
                      [<%= fotasJSON %>]
                    )"><i class='bx bx-show'></i></button>
                    
                    <button type="button" class="btn-icon edit" title="Editar"
                    onclick="abrirModalEdicion(
                      '<%= t.getIdTela() %>',
                      '<%= t.getIdOt() %>',
                      '<%= t.getOrigen().name() %>',
                      '<%= t.getProveedor() != null ? t.getProveedor().replace("'", "\\x27") : "" %>',
                      '<%= t.getIdCatalogoTela() %>',
                      '<%= t.getTipoTejido() != null ? t.getTipoTejido().replace("'", "\\x27") : "" %>',
                      '<%= t.getColor() != null ? t.getColor().replace("'", "\\x27") : "" %>',
                      '<%= t.getNumRollos() %>',
                      '<%= t.getPesoGuia() != null ? t.getPesoGuia().toString().replace("'", "\\x27") : "" %>',
                      '<%= t.getPesoReal() != null ? t.getPesoReal().toString().replace("'", "\\x27") : "" %>',
                      '<%= t.getEstadoCalidad().name() %>',
                      '<%= t.getObservaciones() != null ? t.getObservaciones().replace("'", "\\x27").replace("\n", "\\n").replace("\r", "\\r") : "" %>',
                      <%= t.isRequiereReposo() %>,
                      '<%= t.getNombreRegistrador() != null ? t.getNombreRegistrador().replace("'", "\\x27") : "" %>'
                    )"><i class='bx bx-edit-alt'></i></button>
                </div>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>
  </div>
</main>

<div class="overlay" id="overlayRegistro">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3><i class='bx bx-box'></i> Registrar Ingreso de Tela</h3>
      <button type="button" class="modal-close" onclick="cerrarModalRegistro()">✕</button>
    </div>

    <form method="POST" action="<%= request.getContextPath() %>/inventario"
          enctype="multipart/form-data"
          onsubmit="return validarFormRegistro()"
          id="formRegistroTela">
      <div class="modal-body">

        <div id="errorRegistroModal" class="alerta-error-modal" style="display:none;"></div>

        <div class="sec-titulo"><i class='bx bx-list-ul'></i> Orden de Trabajo Vinculada</div>
        <div class="grid-2">
          <div>
            <label>Orden de Trabajo <span class="req">*</span></label>
            <select name="id_ot" id="m_id_ot" class="form-control" required onchange="actualizarProveedorPorOt()">
                <option value="">-- Selecciona una OT activa --</option>
                <% for (OrdenTrabajo ot : otsActivas) { %>
                  <option value="<%= ot.getIdOt() %>" data-cliente="<%= ot.getCliente().replace("\"", "&quot;") %>">
                    <%= ot.getCodigoOt() %> – <%= ot.getCliente() %>
                  </option>
                <% } %>
                <% if (otsActivas.isEmpty()) { %>
                  <option value="" disabled>No hay OTs activas</option>
                <% } %>
            </select>
            <div class="hint">Solo OTs en estado CREADA o EN_PROCESO.</div>
          </div>
          <div>
            <label>Registrado por</label>
            <div class="info-registrador">
              <i class='bx bx-user'></i> <strong><%= sesion.getNombreCompleto() %></strong>
              &nbsp;–&nbsp;<%= sesion.getNombreRol() %>
              <span style="margin-left:auto; font-size:.72rem; color:var(--text-muted);"><i class='bx bx-bot'></i> Auto</span>
            </div>
          </div>
        </div>

        <div class="sec-titulo"><i class='bx bx-cube'></i> Datos del Material</div>
        <div class="grid-2">
          <div>
            <label>Origen <span class="req">*</span></label>
            <select name="origen" id="m_origen" class="form-control" required onchange="actualizarProveedorPorOrigen()">
              <option value="">-- Selecciona --</option>
              <option value="CLIENTE">Del cliente</option>
              <option value="TALLER">Adquirida por el taller</option>
            </select>
          </div>
          <div>
            <label>Proveedor</label>
            <div style="display:flex; gap:0.4rem; align-items:center;">
              <input type="text" id="m_doc_prov" class="form-control" placeholder="RUC/DNI" maxlength="11" 
                     style="width:120px; display:none;" onkeypress="return event.charCode >= 48 && event.charCode <= 57">
                     
              <button type="button" id="btn_buscar_prov" class="btn btn-primary" 
                      style="display:none;" onclick="buscarProveedor()" title="Buscar en RENIEC/SUNAT"><i class='bx bx-search'></i></button>
                      
              <input type="text" name="proveedor" id="m_proveedor" class="form-control" maxlength="150" 
                     placeholder="Ej: Textiles Andes S.A.C." style="flex:1;">
            </div>
            <div class="hint" id="msg_prov"></div>
          </div>
        </div>
        <div class="grid-3" style="margin-top:1rem;">
          <div>
              <label>Material (Catálogo)</label>
              <select name="id_catalogo_tela" id="m_cat_tela" class="form-control" onchange="actualizarInfoCatalogo()">
                  <option value="">-- Seleccione del catálogo --</option>
                  <% for (CatalogoTela ct : catalogoTelas) { %>
                    <option value="<%= ct.getIdCatalogo() %>"
                            data-reposo="<%= ct.isRequiereReposo() ? "true" : "false" %>"
                            data-tiempo="<%= ct.getTiempoReposo() %>"
                            data-nombre="<%= ct.getNombre() %>">
                      <%= ct.getNombre() %> (<%= ct.getComposicion() %>)
                    </option>
                  <% } %>
                </select>
              </div>
             <div>
                <label>Tipo de Tela</label>
                <input type="text" id="m_tipo_tejido" class="form-control" name="tipo_tejido" maxlength="80" readonly style="background:var(--color-bg);">
             </div>
          <div>
            <label>Color</label>
            <input type="text" name="color" id="m_color" class="form-control" maxlength="50" placeholder="Ej: Negro">
          </div>
          <div>
            <label>N.° de Rollos</label>
            <input type="number" name="num_rollos" id="m_num_rollos" class="form-control" min="1" value="1" max="9999">
          </div>
        </div>

        <div class="sec-titulo"><i class='bx bx-tachometer'></i> Control de Peso – Guía vs Real</div>
        <div class="grid-2">
          <div>
            <label>Peso Guía de Remisión (kg) <span class="req">*</span></label>
            <input type="number" name="peso_guia" id="m_peso_guia" class="form-control"
                   step="0.001" min="0.001" placeholder="0.000" required oninput="calcularDifModal()">
          </div>
          <div>
            <label>Peso Real Medido (kg) <span class="req">*</span></label>
            <input type="number" name="peso_real" id="m_peso_real" class="form-control"
                   step="0.001" min="0.001" placeholder="0.000" required oninput="calcularDifModal()">
          </div>
        </div>
        <div id="alerta-peso-modal" style="display:none; background:var(--warning-bg); border:1px solid #fcd34d; color:var(--warning-text); border-radius:var(--radius-sm); padding:10px; font-size:0.85rem; margin-top:10px; align-items:center; gap:8px;">
          <i class='bx bx-error' style="font-size:1.2rem;"></i> <span>Diferencia: <strong id="dif-valor-modal"></strong> — supera el 1% permitido.</span>
        </div>

        <div class="sec-titulo"><i class='bx bx-check-shield'></i> Calidad y Observaciones</div>
        <div>
          <label>Estado de Calidad <span class="req">*</span></label>
          <select name="estado_calidad" id="m_estado_calidad" class="form-control" required>
            <option value="OBSERVADO">Observado (pendiente revisión)</option>
            <option value="ACEPTADO">Aceptado</option>
            <option value="RECHAZADO">Rechazado</option>
          </select>
        </div>
        <div style="margin-top:1rem;">
          <label>Observaciones <span class="req">*</span></label>
          <textarea name="observaciones" id="m_observaciones" class="form-control" required
            placeholder="Estado del material, condición del embalaje, manchas, fallas, diferencias de peso..."></textarea>
        </div>

        <div class="sec-titulo"><i class='bx bx-camera'></i> Evidencia Fotográfica</div>
        <label onclick="document.getElementById('m_fotos').click()" style="cursor:pointer; display:block;">
          <div class="upload-area" id="m_upload_area">
            <i class='bx bx-image-add ico'></i>
            <p><strong>Clic o arrastra fotos aquí</strong></p>
            <p>JPG, PNG, WEBP · Máx 5 MB · Hasta 4 fotos</p>
            <input type="file" id="m_fotos" name="fotos" accept=".jpg,.jpeg,.png,.webp"
                   multiple onchange="previsualizarModal(this)">
          </div>
        </label>
        <div id="preview-fotos-modal"></div>

        <div class="sec-titulo"><i class='bx bx-cog'></i> Configuración</div>
        <div class="check-fila">
          <input type="checkbox" id="m_reposo" name="requiere_reposo">
          <label for="m_reposo">Requiere reposo antes del corte
            <small style="color:var(--text-muted); font-weight:normal;">(vincula con Tiempos de Reposo)</small>
          </label>
        </div>

      </div><div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalRegistro()"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Registrar Ingreso</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="overlayDetalle">
  <div class="modal-flotante modal-flotante-lg">
    <div class="modal-header">
      <h3 id="detTitulo"><i class='bx bx-search-alt'></i> Detalle de Tela</h3>
      <button type="button" class="modal-close" onclick="cerrarModalDetalle()">✕</button>
    </div>
    <div class="modal-body">

      <div id="detAlertaPeso" class="alerta-peso-detalle" style="display:none;"></div>

      <div class="layout-detalle">
        <div>
          <div class="sec-titulo"><i class='bx bx-info-circle'></i> Identificación y Material</div>
          <div class="grid-datos">
            <div class="dato"><div class="lbl">Código Tela</div><div class="val" id="d_codigo" style="color:var(--color-primary); font-weight:700;"></div></div>
            <div class="dato"><div class="lbl">OT Vinculada</div><div class="val" id="d_ot"></div></div>
            <div class="dato"><div class="lbl">Origen</div><div class="val" id="d_origen"></div></div>
            <div class="dato"><div class="lbl">Proveedor</div><div class="val" id="d_proveedor"></div></div>
            <div class="dato"><div class="lbl">Material (Catálogo)</div><div class="val" id="d_material"></div></div>
            <div class="dato"><div class="lbl">Tipo de Tela</div><div class="val" id="d_tejido"></div></div>
            <div class="dato"><div class="lbl">Color</div><div class="val" id="d_color"></div></div>
            <div class="dato"><div class="lbl">N.° de Rollos</div><div class="val" id="d_rollos"></div></div>
            <div class="dato"><div class="lbl">Registrado por</div><div class="val" id="d_registrador"></div></div>
            <div class="dato"><div class="lbl">Fecha Ingreso</div><div class="val" id="d_fecha"></div></div>
          </div>

          <div class="sec-titulo"><i class='bx bx-tachometer'></i> Control de Peso</div>
          <div class="grid-datos">
            <div class="dato"><div class="lbl">Peso Guía</div><div class="val" id="d_peso_guia"></div></div>
            <div class="dato"><div class="lbl">Peso Real</div><div class="val" id="d_peso_real"></div></div>
            <div class="dato"><div class="lbl">Diferencia</div><div class="val" id="d_diferencia"></div></div>
          </div>

          <div class="sec-titulo"><i class='bx bx-check-shield'></i> Calidad</div>
          <div class="dato"><div class="lbl">Estado</div><div class="val" id="d_estado"></div></div>
          <div class="dato"><div class="lbl">Requiere Reposo</div><div class="val" id="d_reposo"></div></div>
          <div style="margin-top:1rem; background:var(--color-bg); border-radius:var(--radius-sm); padding:1rem; font-size:0.85rem; color:var(--text-main); border:1px solid var(--border-color);">
            <strong style="display:flex; align-items:center; gap:4px; margin-bottom:6px; color:var(--color-secondary); font-size:0.75rem; text-transform:uppercase; letter-spacing:0.05em;"><i class='bx bx-message-square-detail'></i> Observaciones</strong>
            <div id="d_observaciones"></div>
          </div>
        </div>

        <div>
          <div class="sec-titulo"><i class='bx bx-images'></i> Evidencia Fotográfica</div>
          <div id="d_fotos_contenedor"></div>
        </div>
      </div>
    </div>
   
    <div class="modal-footer">
      <button type="button" class="btn btn-outline" onclick="cerrarModalDetalle()">Cerrar</button>
    </div>
  </div>
</div>

<div class="overlay" id="overlayEdicion">
  <div class="modal-flotante modal-flotante-lg">
    <div class="modal-header">
      <h3><i class='bx bx-edit'></i> Editar Registro de Tela</h3>
      <button type="button" class="modal-close" onclick="cerrarModalEdicion()">✕</button>
    </div>
    <form method="POST" action="<%= request.getContextPath() %>/inventario"
          enctype="multipart/form-data" id="formEditarTela">
      <input type="hidden" name="accion" value="actualizarTela">
      <input type="hidden" name="id_tela" id="edit_id_tela">
      
      <div class="modal-body">
        <div id="errorEdicionModal" class="alerta-error-modal" style="display:none;"></div>

        <div class="sec-titulo"><i class='bx bx-list-ul'></i> Orden de Trabajo Vinculada</div>
        <div class="grid-2">
          <div>
            <label>Orden de Trabajo</label>
            <input type="hidden" name="id_ot" id="edit_id_ot_hidden">
            <select id="edit_id_ot" class="form-control"
                    <%= !"ADMINISTRADOR".equals(sesion.getNombreRol()) ? "disabled" : "" %> 
                    onchange="document.getElementById('edit_id_ot_hidden').value = this.value;">
              <option value="">-- Selecciona una OT --</option>
              <% for (OrdenTrabajo ot : otsActivas) { %>
                <option value="<%= ot.getIdOt() %>"><%= ot.getCodigoOt() %> – <%= ot.getCliente() %></option>
              <% } %>
            </select>
            <div class="hint">
              <%= "ADMINISTRADOR".equals(sesion.getNombreRol()) ? "Puedes modificar la OT (Nivel Administrador)." : "La orden de trabajo no se puede modificar." %>
            </div>
          </div>
          <div>
            <label>Registrado por</label>
            <div class="info-registrador">
              <i class='bx bx-user'></i> <span id="edit_nombre_registrador">--</span>
            </div>
          </div>
        </div>

        <div class="sec-titulo"><i class='bx bx-cube'></i> Datos del Material</div>
        <div class="grid-2">
          <div>
            <label>Origen <span class="req">*</span></label>
            <select name="origen" id="edit_origen" class="form-control" required>
              <option value="CLIENTE">Del cliente</option>
              <option value="TALLER">Adquirida por el taller</option>
            </select>
          </div>
          <div>
            <label>Proveedor</label>
            <input type="text" name="proveedor" id="edit_proveedor" class="form-control" maxlength="150">
          </div>
        </div>
        <div class="grid-3" style="margin-top:1rem;">
          <div>
            <label>Material (Catálogo)</label>
            <select name="id_catalogo_tela" id="edit_cat_tela" class="form-control" onchange="actualizarInfoCatalogoEdicion()">
              <option value="">-- Seleccione del catálogo --</option>
              <% for (CatalogoTela ct : catalogoTelas) { %>
                <option value="<%= ct.getIdCatalogo() %>"
                        data-reposo="<%= ct.isRequiereReposo() ? "true" : "false" %>"
                        data-nombre="<%= ct.getNombre() %>">
                  <%= ct.getNombre() %>
                </option>
              <% } %>
            </select>
          </div>
          <div>
            <label>Tipo de Tela</label>
            <input type="text" name="tipo_tejido" id="edit_tipo_tejido" class="form-control" maxlength="80">
          </div>
          <div>
            <label>Color</label>
            <input type="text" name="color" id="edit_color" class="form-control" maxlength="50">
          </div>
          <div>
            <label>N.° de Rollos</label>
            <input type="number" name="num_rollos" id="edit_num_rollos" class="form-control" min="1">
          </div>
        </div>

        <div class="sec-titulo"><i class='bx bx-tachometer'></i> Control de Peso – Guía vs Real</div>
        <div class="grid-2">
          <div>
            <label>Peso Guía de Remisión (kg)</label>
            <input type="number" name="peso_guia" id="edit_peso_guia" class="form-control" step="0.001" min="0">
          </div>
          <div>
            <label>Peso Real Medido (kg)</label>
            <input type="number" name="peso_real" id="edit_peso_real" class="form-control" step="0.001" min="0">
          </div>
        </div>
        <div id="alerta-peso-edicion" class="alerta-peso-detalle" style="display:none; align-items:center; gap:8px;"></div>

        <div class="sec-titulo"><i class='bx bx-check-shield'></i> Calidad y Observaciones</div>
        <div>
          <label>Estado de Calidad</label>
          <select name="estado_calidad" id="edit_estado_calidad" class="form-control" required>
            <option value="OBSERVADO">Observado</option>
            <option value="ACEPTADO">Aceptado</option>
            <option value="RECHAZADO">Rechazado</option>
          </select>
        </div>
        <div style="margin-top:1rem;">
          <label>Observaciones</label>
          <textarea name="observaciones" id="edit_observaciones" class="form-control" rows="3" required></textarea>
        </div>

        <div class="sec-titulo"><i class='bx bx-cog'></i> Configuración</div>
        <div class="check-fila">
          <input type="checkbox" id="edit_reposo" name="requiere_reposo">
          <label for="edit_reposo">Requiere reposo antes del corte</label>
        </div>

        <div class="sec-titulo"><i class='bx bx-images'></i> Agregar nuevas fotos (opcional)</div>
        <label onclick="document.getElementById('edit_fotos').click()" style="cursor:pointer; display:block;">
          <div class="upload-area" id="edit_upload_area">
            <i class='bx bx-image-add ico'></i>
            <p><strong>Clic o arrastra fotos aquí</strong></p>
            <p>JPG, PNG, WEBP · Máx 5 MB · Hasta 4 fotos</p>
            <input type="file" id="edit_fotos" name="fotos" accept=".jpg,.jpeg,.png,.webp"
                   multiple onchange="previsualizarEdicion(this)">
          </div>
        </label>
        <div id="preview-fotos-edicion"></div>
    
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModalEdicion()"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar Cambios</button>
      </div>
    </form>
  </div>
</div>

<script>
  // UI MENÚ ACORDEÓN
  function toggleSubmenu(element) {
      element.parentElement.classList.toggle('active');
  }

  // ════════════════════════════════════════════════════
  // LÓGICA JAVASCRIPT INTACTA
  // ════════════════════════════════════════════════════
  var CTX = '<%= request.getContextPath() %>';

  /* ── MODAL REGISTRO ── */
  function abrirModalRegistro() {
    document.getElementById('formRegistroTela').reset();
    document.getElementById('preview-fotos-modal').innerHTML = '';
    document.getElementById('alerta-peso-modal').style.display = 'none';
    document.getElementById('errorRegistroModal').style.display = 'none';
    document.getElementById('overlayRegistro').classList.add('activo');
    document.getElementById('m_id_ot').focus();
    actualizarProveedorPorOrigen();  // sincroniza proveedor al abrir
  }
  function cerrarModalRegistro() {
    document.getElementById('overlayRegistro').classList.remove('activo');
  }
  document.getElementById('overlayRegistro').addEventListener('click', function(e) {
    if (e.target === this) cerrarModalRegistro();
  });

  /* Diferencia de peso en tiempo real */
  function calcularDifModal() {
    var g = parseFloat(document.getElementById('m_peso_guia').value) || 0;
    var r = parseFloat(document.getElementById('m_peso_real').value) || 0;
    var d = r - g;
    var el = document.getElementById('alerta-peso-modal');
    if (g > 0 && Math.abs(d) > g * 0.01) {
      document.getElementById('dif-valor-modal').textContent =
        (d >= 0 ? '+' : '') + d.toFixed(3) + ' kg (' +
        Math.abs(d / g * 100).toFixed(1) + '%)';
      el.style.display = 'flex';
    } else {
      el.style.display = 'none';
    }
  }

  /* Previsualización fotos */
  function previsualizarModal(input) {
    var prev = document.getElementById('preview-fotos-modal');
    prev.innerHTML = '';
    Array.from(input.files).slice(0, 4).forEach(function(file) {
      var reader = new FileReader();
      reader.onload = function(e) {
        var img = document.createElement('img');
        img.src = e.target.result;
        img.title = file.name;
        prev.appendChild(img);
      };
      reader.readAsDataURL(file);
    });
  }

  /* Drag & drop */
  var mArea = document.getElementById('m_upload_area');
  mArea.addEventListener('dragover', function(e) { e.preventDefault(); mArea.style.borderColor='var(--color-primary)'; });
  mArea.addEventListener('dragleave', function() { mArea.style.borderColor=''; });
  mArea.addEventListener('drop', function(e) {
    e.preventDefault(); mArea.style.borderColor='';
    var inp = document.getElementById('m_fotos');
    inp.files = e.dataTransfer.files;
    previsualizarModal(inp);
  });

  /* Validación */
  function validarFormRegistro() {
    var ot  = document.getElementById('m_id_ot').value;
    var obs = document.getElementById('m_observaciones').value.trim();
    var pg  = document.getElementById('m_peso_guia').value;
    var pr  = document.getElementById('m_peso_real').value;
    if (!ot)  { mostrarErrorRegistro('Selecciona una Orden de Trabajo.'); return false; }
    if (!pg || parseFloat(pg) <= 0) { mostrarErrorRegistro('El peso de la guía es obligatorio y debe ser mayor a 0.'); return false; }
    if (!pr || parseFloat(pr) <= 0) { mostrarErrorRegistro('El peso real es obligatorio y debe ser mayor a 0.'); return false; }
    if (!obs) { mostrarErrorRegistro('Las observaciones son obligatorias (CA2 - HU01).'); return false; }
    return true;
  }
  function mostrarErrorRegistro(msg) {
    var el = document.getElementById('errorRegistroModal');
    el.innerHTML = "<i class='bx bx-error-circle'></i> " + msg;
    el.style.display = 'flex';
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  /* ── MODAL DETALLE ── */
  function abrirModalDetalle(codigo, ot, origen, proveedor, materialCatalogo, tejido, color, rollos,
        pesoGuia, pesoReal, diferencia, pct, estado, reposo, observaciones,
        registrador, fecha, fotos) {

        document.getElementById('detTitulo').innerHTML = "<i class='bx bx-search-alt'></i> Detalle – " + codigo;
        document.getElementById('d_codigo').textContent      = codigo;
        document.getElementById('d_ot').textContent          = ot;
        document.getElementById('d_origen').textContent      = origen;
        document.getElementById('d_proveedor').textContent   = proveedor;
        document.getElementById('d_material').textContent    = materialCatalogo;
        document.getElementById('d_tejido').textContent      = tejido;
        document.getElementById('d_color').textContent       = color;
        document.getElementById('d_rollos').textContent      = rollos;
        document.getElementById('d_peso_guia').textContent   = pesoGuia + ' kg';
        document.getElementById('d_peso_real').textContent   = pesoReal + ' kg';
        document.getElementById('d_registrador').textContent = registrador;
        document.getElementById('d_fecha').textContent       = fecha;
        document.getElementById('d_observaciones').textContent = observaciones;

        var dif = parseFloat(diferencia);
        var pctN = parseFloat(pct);
        var difTxt = (dif >= 0 ? '+' : '') + diferencia + ' kg (' + pct + '%) ';
        difTxt += pctN > 1.0 ? '⚠' : '✅';
        var difEl = document.getElementById('d_diferencia');
        difEl.textContent  = difTxt;
        difEl.style.color  = pctN > 1.0 ? 'var(--danger-hover)' : 'var(--success-text)';
        difEl.style.fontWeight = '700';

        // Alerta de peso
        var alertaEl = document.getElementById('detAlertaPeso');
        if (pctN > 1.0) {
          alertaEl.innerHTML = "<i class='bx bx-error'></i> Alerta de peso: diferencia de " + (dif >= 0 ? '+' : '') + diferencia + ' kg (' + pct + '%) — verificar con proveedor.';
          alertaEl.style.display = 'flex';
        } else {
          alertaEl.style.display = 'none';
        }

        // Estado calidad
        var estadoMap = { ACEPTADO: 'var(--success-bg)|var(--success-text)', OBSERVADO: 'var(--warning-bg)|var(--warning-text)', RECHAZADO: 'var(--danger-bg)|var(--danger-text)' };
        var colores = (estadoMap[estado] || 'var(--color-bg)|var(--text-main)').split('|');
        document.getElementById('d_estado').innerHTML =
          '<span style="background:' + colores[0] + ';color:' + colores[1] +
          ';padding:.25rem .8rem;border-radius:20px;font-size:.75rem;font-weight:700;">' + estado + '</span>';
          
        document.getElementById('d_reposo').innerHTML = reposo === 'true' ? "<span class='reposo-badge'><i class='bx bx-time-five'></i> Sí</span>" : 'No';

        // Fotos
        var cont = document.getElementById('d_fotos_contenedor');
        if (!fotos || fotos.length === 0) {
          cont.innerHTML = '<p class="sin-fotos">No se cargaron fotos para esta tela.</p>';
        } else {
          var html = '<p style="font-size:.78rem;color:var(--text-muted);margin-bottom:.5rem;">' + fotos.length + ' foto(s)</p><div class="galeria">';
          fotos.forEach(function(ruta) {
            html += '<a href="' + CTX + '/imagen/' + ruta + '" target="_blank">' +
                    '<img src="' + CTX + '/imagen/' + ruta + '" alt="Foto evidencia"></a>';
          });
          html += '</div>';
          cont.innerHTML = html;
        }

        document.getElementById('overlayDetalle').classList.add('activo');
  }

  function cerrarModalDetalle() {
    document.getElementById('overlayDetalle').classList.remove('activo');
  }
  document.getElementById('overlayDetalle').addEventListener('click', function(e) {
    if (e.target === this) cerrarModalDetalle();
  });

  /* Si el servlet devolvió error de formulario, reabrimos el modal de registro */
  <% if (abrirModal) { %>
  window.addEventListener('DOMContentLoaded', function() {
    abrirModalRegistro();
    mostrarErrorRegistro('<%= errorForm != null ? errorForm.replace("'","\\x27") : "" %>');
  });
  <% } %>

  function actualizarInfoCatalogo() {
      var sel = document.getElementById('m_cat_tela');
      var option = sel.options[sel.selectedIndex];
      var tipoText = document.getElementById('m_tipo_tejido');
      var reposoCheck = document.getElementById('m_reposo');
      var nombre = option.getAttribute('data-nombre') || '';
      var requiereReposo = option.getAttribute('data-reposo') === 'true';

      tipoText.value = nombre;
      reposoCheck.checked = requiereReposo;
  }

  // Llenar proveedor automático o mostrar buscador según el origen
  function actualizarProveedorPorOrigen() {
        var origen = document.getElementById('m_origen').value;
        var proveedorInput = document.getElementById('m_proveedor');
        var docInput = document.getElementById('m_doc_prov');
        var btnBuscar = document.getElementById('btn_buscar_prov');
        var msgProv = document.getElementById('msg_prov');

        if (origen === 'CLIENTE') {
            docInput.style.display = 'none';
            btnBuscar.style.display = 'none';
            msgProv.textContent = '';
            
            var selectOt = document.getElementById('m_id_ot');
            var selectedOption = selectOt.options[selectOt.selectedIndex];
            if (selectedOption && selectedOption.value) {
                var cliente = selectedOption.getAttribute('data-cliente') || '';
                proveedorInput.value = cliente;
            } else {
                proveedorInput.value = '';
            }
        } else if (origen === 'TALLER') {
            docInput.style.display = 'block';
            btnBuscar.style.display = 'block';
            docInput.value = '';
            proveedorInput.value = '';
            msgProv.textContent = 'DNI (8) o RUC (11) peruano, o escribe a mano.';
            msgProv.style.color = 'var(--text-muted)';
        } else {
            docInput.style.display = 'none';
            btnBuscar.style.display = 'none';
            proveedorInput.value = '';
            msgProv.textContent = '';
        }
  }

  // Cuando cambia la OT, si Origen es CLIENTE, actualizar proveedor
  function actualizarProveedorPorOt() {
        var origen = document.getElementById('m_origen').value;
        if (origen === 'CLIENTE') {
            var selectOt = document.getElementById('m_id_ot');
            var selectedOption = selectOt.options[selectOt.selectedIndex];
            if (selectedOption && selectedOption.value) {
                var cliente = selectedOption.getAttribute('data-cliente') || '';
                document.getElementById('m_proveedor').value = cliente;
            }
        }
  }

  function calcularDiferenciaEdicion() {
        var guia = parseFloat(document.getElementById('edit_peso_guia').value) || 0;
        var real = parseFloat(document.getElementById('edit_peso_real').value) || 0;
        var diff = real - guia;
        var alertaDiv = document.getElementById('alerta-peso-edicion');
        if (guia > 0 && Math.abs(diff) > guia * 0.01) {
            alertaDiv.innerHTML = "<i class='bx bx-error'></i> Diferencia de peso: " + (diff >= 0 ? '+' : '') + diff.toFixed(3) + ' kg (' + 
                                  Math.abs(diff / guia * 100).toFixed(1) + '%) — supera el 1% permitido.';
            alertaDiv.style.display = 'flex';
        } else {
            alertaDiv.style.display = 'none';
        }
  }

  function abrirModalEdicion(idTela, idOt, origen, proveedor, idCatalogo, tipoTejido, color,
                               numRollos, pesoGuia, pesoReal, estadoCalidad, observaciones,
                               requiereReposo, nombreRegistrador) {
         var elemMap = {
             'edit_id_tela': idTela,
             'edit_id_ot': idOt,
             'edit_origen': origen,
             'edit_proveedor': proveedor || '',
             'edit_cat_tela': idCatalogo || '',
             'edit_tipo_tejido': tipoTejido || '',
             'edit_color': color || '',
             'edit_num_rollos': numRollos,
             'edit_peso_guia': pesoGuia,
             'edit_peso_real': pesoReal,
             'edit_estado_calidad': estadoCalidad,
             'edit_observaciones': observaciones || '',
             'edit_reposo': requiereReposo === true || requiereReposo === 'true',
             'edit_nombre_registrador': nombreRegistrador || ''
         };
         
         for (var [id, valor] of Object.entries(elemMap)) {
             var el = document.getElementById(id);
             if (el) {
                 if (el.type === 'checkbox') {
                     el.checked = valor;
                 } else if (el.tagName === 'SELECT') {
                     var optionExists = false;
                     for (var i = 0; i < el.options.length; i++) {
                         if (el.options[i].value == valor) {
                             el.selectedIndex = i;
                             optionExists = true;
                             break;
                         }
                     }
                     if (!optionExists && el.options.length > 0) el.selectedIndex = 0;
                 } else {
                     el.value = valor;
                 }
             } else {
                 console.warn('Elemento no encontrado: ' + id);
             }
         }

         var prev = document.getElementById('preview-fotos-edicion');
         if (prev) prev.innerHTML = '';
         var errorDiv = document.getElementById('errorEdicionModal');
         if (errorDiv) errorDiv.style.display = 'none';
         var alertaDiv = document.getElementById('alerta-peso-edicion');
         if (alertaDiv) alertaDiv.style.display = 'none';

         calcularDiferenciaEdicion();
         
         var overlay = document.getElementById('overlayEdicion');
         if (overlay) overlay.classList.add('activo');
         
         document.getElementById('edit_id_ot_hidden').value = idOt;
  }
    
  document.getElementById('edit_peso_guia')?.addEventListener('input', calcularDiferenciaEdicion);
  document.getElementById('edit_peso_real')?.addEventListener('input', calcularDiferenciaEdicion);

  function cerrarModalEdicion() {
      document.getElementById('overlayEdicion').classList.remove('activo');
  }

  function previsualizarEdicion(input) {
      var prev = document.getElementById('preview-fotos-edicion');
      prev.innerHTML = '';
      Array.from(input.files).slice(0, 4).forEach(function(file) {
          var reader = new FileReader();
          reader.onload = function(e) {
              var img = document.createElement('img');
              img.src = e.target.result;
              img.title = file.name;
              img.style.width = '70px';
              img.style.height = '70px';
              img.style.objectFit = 'cover';
              img.style.borderRadius = '8px';
              img.style.border = '1px solid var(--border-color)';
              prev.appendChild(img);
          };
          reader.readAsDataURL(file);
      });
  }

  document.getElementById('overlayEdicion').addEventListener('click', function(e) {
      if (e.target === this) cerrarModalEdicion();
  });

  function actualizarInfoCatalogoEdicion() {
      var sel = document.getElementById('edit_cat_tela');
      if(sel.selectedIndex === 0) return;
      var option = sel.options[sel.selectedIndex];
      var tipoText = document.getElementById('edit_tipo_tejido');
      var reposoCheck = document.getElementById('edit_reposo');
      var nombre = option.getAttribute('data-nombre') || '';
      var requiereReposo = option.getAttribute('data-reposo') === 'true';
      tipoText.value = nombre;
      reposoCheck.checked = requiereReposo;
  }

  // ── LÓGICA PARA DOBLE BARRA DE SCROLL ──
  window.addEventListener('DOMContentLoaded', function() {
      var topScroll = document.getElementById('top-scrollbar-container');
      var topContent = document.getElementById('top-scrollbar-fake-content');
      var cardScroll = document.querySelector('.card');
      var tabla = document.querySelector('.card table');

      if (tabla && topScroll && cardScroll) {
          topScroll.style.display = 'block';

          function sincronizarAncho() {
              topContent.style.width = cardScroll.scrollWidth + 'px';
          }
          sincronizarAncho();

          topScroll.addEventListener('scroll', function() {
              cardScroll.scrollLeft = topScroll.scrollLeft;
          });

          cardScroll.addEventListener('scroll', function() {
              topScroll.scrollLeft = cardScroll.scrollLeft;
          });
          
          window.addEventListener('resize', sincronizarAncho);
      }
  });

  // Consultar API a través de nuestro propio Servlet (Backend Proxy)
  async function buscarProveedor() {
      var doc = document.getElementById('m_doc_prov').value.trim();
      var msgProv = document.getElementById('msg_prov');
      var provInput = document.getElementById('m_proveedor');

      if (doc.length !== 8 && doc.length !== 11) {
          msgProv.textContent = '❌ El documento debe tener 8 o 11 dígitos.';
          msgProv.style.color = 'var(--danger-hover)';
          return;
      }

      msgProv.textContent = '⏳ Buscando en base de datos...';
      msgProv.style.color = 'var(--color-primary)';
      provInput.value = '';

      try {
          let url = CTX + '/inventario?accion=buscarProveedor&doc=' + doc;
          let response = await fetch(url);
          
          if (!response.ok) throw new Error('No encontrado');
          
          let data = await response.json();
          if (doc.length === 8) {
              provInput.value = data.nombres + ' ' + data.apellidoPaterno + ' ' + data.apellidoMaterno;
          } else {
              provInput.value = data.razonSocial;
          }
          
          msgProv.textContent = '✅ Proveedor autocompletado.';
          msgProv.style.color = 'var(--success-text)';
          
      } catch (error) {
          msgProv.textContent = '⚠ No encontrado. Escribe el nombre manualmente arriba.';
          msgProv.style.color = '#b45309';
          provInput.focus();
      }
  }
</script>
</body>
</html>