<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ModeloPrenda, modelo.PiezaModelo, java.util.List, modelo.Usuario, java.util.Set, java.util.HashSet, modelo.FaseProduccion" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean verSeguridad   = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacen     = permisos.contains("ALM_TELA_VER");
    boolean verProduccion  = permisos.contains("PROD_OT_VER");

    List<ModeloPrenda> modelos = (List<ModeloPrenda>) request.getAttribute("modelos");
    ModeloPrenda modeloEditar = (ModeloPrenda) request.getAttribute("modeloEditar");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Catálogo de Modelos</title>
  
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
        --info-bg: #e0f2fe;
        --info-text: #0369a1;
        --radius-sm: 6px;
        --radius-md: 8px;
        --radius-lg: 12px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; background: var(--color-bg); display: flex; min-height: 100vh; color: var(--text-main); }
    
    /* ── LAYOUT PRINCIPAL ── */
    aside { width: 250px; background: var(--color-secondary); color: var(--text-light); display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 24px 16px; border-bottom: 1px solid rgba(255,255,255,0.05); color: var(--color-accent); font-weight: 700; font-size: 1.1rem; display:flex; flex-direction: column; gap: 4px;}
    .sidebar-logo span { font-size: 0.75rem; color: #94a3b8; font-weight: 400; }
    
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
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
    .badge { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; }
    .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; transition: all 0.2s; display:flex; align-items:center; gap:5px;}
    .btn-salir:hover { background: var(--danger-hover); color: #fff; }

    /* ── CONTENIDO Y COMPONENTES ── */
    .toolbar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 24px; flex-wrap: wrap; }
    .toolbar-title { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; }
    .toolbar-filters { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; flex: 1; justify-content: center; }
    
    .search-wrapper { position: relative; width: 100%; max-width: 450px; }
    .search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.1rem; }
    .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); transition: all 0.2s; outline: none; }
    .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
    .search-wrapper .form-control { padding-left: 2.5rem; }

    .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
    .btn i { font-size: 1.1rem; }
    .btn-primary { background: var(--color-primary); color: #fff; }
    .btn-primary:hover { background: var(--color-primary-hover); }

    /* ── TABLAS ── */
    .card { background: var(--color-surface); border-radius: var(--radius-md); box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin: 0 24px 24px 24px; overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
    th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 0.8rem 1.2rem; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; letter-spacing: 0.5px; }
    td { padding: 0.8rem 1.2rem; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #f8fafc; }
    
    .chip { display: inline-flex; align-items: center; justify-content: center; width: 85px; padding: 0.3rem 0; border-radius: 6px; font-size: 0.75rem; font-weight: 600; background: var(--info-bg); color: var(--info-text); }
    
    /* Botones de Acción */
    .acciones-container { display: flex; gap: 8px; }
    .btn-icon { width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; border: none; border-radius: 6px; cursor: pointer; font-size: 1.15rem; transition: all 0.2s; }
    .btn-icon.view { color: #0369a1; background: #e0f2fe; }
    .btn-icon.view:hover { background: #bae6fd; color: #0284c7; }
    .btn-icon.edit { color: #d97706; background: #fef3c7; }
    .btn-icon.edit:hover { background: #fde68a; color: #b45309; }
    .btn-icon.delete { color: #dc2626; background: #fee2e2; }
    .btn-icon.delete:hover { background: #fecaca; color: #b91c1c; }
    .btn-icon.disabled { opacity: 0.4; cursor: not-allowed; background: #e2e8f0; color: #64748b; }

    /* ── MODALES ── */
    .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); display: none; align-items: center; justify-content: center; z-index: 1000; backdrop-filter: blur(3px); }
    .modal-overlay.active { display: flex; }
    .modal-content { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 1200px; padding: 24px; max-height: 90vh; overflow-y: auto; box-shadow: 0 20px 40px rgba(0,0,0,0.15); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
    .modal-header h3 { color: var(--color-secondary); font-size: 1.1rem; font-weight: 600; display: flex; align-items: center; gap: 8px; }
    .close-modal { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: color 0.2s; }
    .close-modal:hover { color: var(--text-main); }
    
    .field { display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
    .field label { font-size: 0.82rem; font-weight: 600; color: var(--text-main); }
    .req { color: var(--danger-hover); }

    .btn-guardar { width: 100%; padding: 0.65rem; background: var(--color-primary); color: #fff; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; margin-top: 16px; transition: background 0.2s;}
    .btn-guardar:hover { background: var(--color-primary-hover); }

    /* Modal piezas */
    .tabla-piezas { width:100%; border-collapse:collapse; margin-top:12px; font-size:0.85rem; }
    .tabla-piezas th { background: #f8fafc; color: var(--text-muted); padding: 10px 16px; text-align: left; font-size: 0.72rem; text-transform: uppercase;}
    .tabla-piezas td { padding: 10px 16px; border-bottom: 1px solid var(--border-color); }
    .cant-badge { background: var(--color-primary); color: #fff; border-radius: 20px; padding: 2px 10px; font-size: 0.75rem; font-weight: 700; }
    
    .fila-pieza { background: var(--color-surface); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; margin-bottom: 12px; display: grid; grid-template-columns: 2fr 1fr 2fr auto; gap: 16px; align-items: start; }
    .fila-pieza .field { margin-bottom: 0; }
    
    .check-fase { display: inline-flex; align-items: center; margin-right: 12px; margin-bottom: 6px; font-size: 0.75rem; background: var(--bg-light); padding: 6px 10px; border-radius: 6px; cursor: pointer; border: 1px solid var(--border-color); transition: all 0.2s;}
    .check-fase:has(input:checked) { background: var(--info-bg); border-color: var(--info-text); color: var(--info-text); font-weight: 600;}
    .check-fase input { margin-right: 6px; accent-color: var(--color-primary);}
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
    <div class="menu-group active">
      <div class="menu-toggle" onclick="toggleSubmenu(this)">
        <span><i class='bx bx-folder'></i> Catálogos</span>
        <i class='bx bx-chevron-down arrow'></i>
      </div>
      <div class="menu-content">
        <% if (_navCatT) { %><a href="<%= _cp %>/catalogo-telas" class="menu-link">Catálogo Telas</a><% } %>
        <% if (_navCatM) { %><a href="<%= _cp %>/catalogo-modelos" class="menu-link activo">Catálogo Modelos</a><% } %>
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
      <h2><i class='bx bx-closet'></i> Catálogo de Modelos</h2>
      <div class="user-info">
        <span><%= usuarioSesion != null ? usuarioSesion.getNombreCompleto() : "Admin" %></span>
        <span class="badge"><%= usuarioSesion != null ? usuarioSesion.getNombreRol() : "ADMINISTRADOR" %></span>
        <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
      </div>
  </header>

  <div class="toolbar">
    <h3 class="toolbar-title">Listado de Modelos</h3>
    <div class="toolbar-filters">
      <div class="search-wrapper">
        <i class='bx bx-search search-icon'></i>
        <input type="text" id="busquedaModelos" class="form-control" placeholder="Buscar por modelo o temporada...">
      </div>
    </div>
    <button onclick="abrirModalNuevo()" class="btn btn-primary"><i class='bx bx-plus'></i> Nuevo Modelo</button>
  </div>

  <div class="card">
    <table>
      <thead>
        <tr><th>#</th><th>Modelo de Prenda</th><th>Colección / Temporada</th><th style="text-align:center;">Total Piezas</th><th>Acciones</th></tr>
      </thead>
      <tbody>
        <% if (modelos != null) { for (int i = 0; i < modelos.size(); i++) { ModeloPrenda m = modelos.get(i); %>
        <tr>
          <td><%= i + 1 %></td>
          <td><strong><%= m.getNombre() %></strong></td>
          <td><%= m.getTemporada() %></td>
          <td style="text-align:center;"><span class="chip"><%= m.getTotalPiezas() %> piezas</span></td>
          <td>
            <div class="acciones-container">
                <button type="button" class="btn-icon view" title="Ver Piezas" onclick="verPiezas(<%= m.getIdModelo() %>, '<%= m.getNombre().replace("'","\\'") %>')">
                  <i class='bx bx-show'></i>
                </button>

                <% if (m.isEnUso()) { %>
                    <button type="button" class="btn-icon disabled" title="En producción" onclick="alert('🔒 No se puede editar: Este modelo ya está en producción (Cargas de trabajo asignadas).')">
                        <i class='bx bx-edit-alt'></i>
                    </button>
                    <button type="button" class="btn-icon disabled" title="En producción" onclick="alert('🔒 No se puede eliminar: Este modelo ya está en producción.')">
                        <i class='bx bx-trash'></i>
                    </button>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/catalogo-modelos?accion=editar&id=<%= m.getIdModelo() %>" class="btn-icon edit" title="Editar">
                        <i class='bx bx-edit-alt'></i>
                    </a>
                    <form action="<%= request.getContextPath() %>/catalogo-modelos" method="POST" style="display:inline;" onsubmit="return confirm('¿Eliminar modelo de forma permanente?');">
                      <input type="hidden" name="accion" value="eliminar">
                      <input type="hidden" name="id_modelo" value="<%= m.getIdModelo() %>">
                      <button type="submit" class="btn-icon delete" title="Eliminar"><i class='bx bx-trash'></i></button>
                    </form>
                <% } %>
            </div>
          </td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>
</main>

<div id="modal-piezas" class="modal-overlay">
  <div class="modal-content" style="max-width: 520px;">
    <div class="modal-header">
      <h3 id="piezas-titulo" style="margin:0;"><i class='bx bx-show'></i> Piezas del Modelo</h3>
      <button class="close-modal" onclick="document.getElementById('modal-piezas').classList.remove('active')"><i class='bx bx-x'></i></button>
    </div>
    <div id="piezas-body">
      <p style="color:var(--text-muted);text-align:center;">Cargando...</p>
    </div>
  </div>
</div>

<div id="modal-modelo" class="modal-overlay">
  <div class="modal-content" style="max-width: 800px;">
    <div class="modal-header">
      <h3 id="modal-titulo" style="margin:0;"><i class='bx bx-closet'></i> Ficha Técnica de Modelo</h3>
      <button class="close-modal" onclick="cerrarModal()"><i class='bx bx-x'></i></button>
    </div>

    <form action="<%= request.getContextPath() %>/catalogo-modelos" method="POST">
      <input type="hidden" id="modal-id" name="id_modelo" value="">
      <input type="hidden" id="modal-accion" name="accion" value="">

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">
          <div class="field">
              <label>Nombre Modelo <span class="req">*</span></label>
              <input type="text" id="modal-nombre" name="nombre" class="form-control" required>
          </div>
          <div class="field">
              <label>Temporada</label>
              <input type="text" id="modal-temporada" name="temporada" class="form-control">
          </div>
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border-color); margin: 24px 0 16px; padding-bottom: 8px;">
        <span style="font-weight:700; color:var(--text-main); text-transform:uppercase; font-size:0.8rem;"><i class='bx bx-layer'></i> Estructura (Piezas)</span>
        <div style="display:flex; gap:8px;">
            <button type="button" class="btn btn-primary" style="padding:4px 10px; font-size:0.75rem;" onclick="abrirModalFase()"><i class='bx bx-plus'></i> Añadir Fase</button>
            <button type="button" class="btn btn-primary" style="padding:4px 10px; font-size:0.75rem;" onclick="agregarPieza('', 1)"><i class='bx bx-plus'></i> Añadir Pieza</button>
        </div>
      </div>

      <div id="contenedor-piezas" style="background:var(--color-bg); border:1px solid var(--border-color); border-radius:var(--radius-md); padding:16px; max-height:350px; overflow-y:auto;">
        </div>

      <button type="submit" class="btn-guardar"><i class='bx bx-save'></i> Guardar Modelo</button>
    </form>
  </div>
</div>

<div id="modal-fase" class="modal-overlay">
  <div class="modal-content" style="max-width: 480px;">
    <div class="modal-header">
      <h3><i class='bx bx-plus-circle'></i> Agregar Nueva Fase</h3>
      <button class="close-modal" onclick="cerrarModalFase()"><i class='bx bx-x'></i></button>
    </div>
    <form id="formAgregarFase">
      <div class="field">
        <label>Nombre de la Fase <span class="req">*</span></label>
        <input type="text" id="nombreFase" class="form-control" required>
      </div>
      <div class="field">
        <label>Orden <span class="req">*</span></label>
        <input type="number" id="ordenFase" class="form-control" min="1" required>
      </div>
      <div class="field">
        <label>Descripción</label>
        <textarea id="descripcionFase" class="form-control" rows="3" style="resize:vertical; padding:8px; border-radius:6px; border:1px solid #e2e8f0;"></textarea>
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px; border-top:1px solid var(--border-color); padding-top:16px;">
        <button type="button" class="btn" style="background:#f1f5f9;color:var(--text-main)" onclick="cerrarModalFase()">Cancelar</button>
        <button type="button" class="btn btn-primary" onclick="guardarNuevaFase()"><i class='bx bx-save'></i> Guardar Fase</button>
      </div>
    </form>
  </div>
</div>

<script>
    let contadorPiezas = 0;
    let listaFases = [
        <% for (modelo.FaseProduccion f : (List<modelo.FaseProduccion>) request.getAttribute("fases")) { 
               if (f.getIdFase() == 6 || "ENSAMBLAJE".equalsIgnoreCase(f.getNombre())) continue; %>
            { id: <%= f.getIdFase() %>, nombre: "<%= f.getNombre().replace("\"", "\\\"") %>" },
        <% } %>
    ];

  function agregarPieza(nombre, cantidad, fasesSeleccionadas = []) {
    const container = document.getElementById('contenedor-piezas');
    const div = document.createElement('div');
    div.className = 'fila-pieza';
    div.setAttribute('data-indice', contadorPiezas);

    const nombreEscapado = (nombre || '').replace(/"/g, '&quot;');
    let checkboxesHtml = '';
    for (let fase of listaFases) {
        let checked = fasesSeleccionadas.includes(fase.id.toString()) ? 'checked' : '';
        checkboxesHtml += '<label class="check-fase">' +
            '<input type="checkbox" name="fasesPieza_' + contadorPiezas + '" value="' + fase.id + '" ' + checked + '>' +
            fase.nombre +
            '</label>';
    }

    /* SE APLICÓ CLASE .form-control y .btn-icon A LOS ELEMENTOS DINÁMICOS */
    div.innerHTML = 
      '<div class="field">' +
        '<label>Nombre de la Pieza</label>' +
        '<input type="text" class="form-control" name="nombrePieza[]" value="' + nombreEscapado + '" placeholder="Ej: Copa izquierda" required>' +
      '</div>' +
      '<div class="field">' +
        '<label>Cantidad</label>' +
        '<input type="number" class="form-control" name="cantidadPieza[]" min="1" value="' + (cantidad || 1) + '" required>' +
      '</div>' +
      '<div class="field">' +
        '<label>Fases de producción</label>' +
        '<div style="display:flex; flex-wrap:wrap; gap:4px;">' + checkboxesHtml + '</div>' +
      '</div>' +
      '<button type="button" class="btn-icon delete" style="align-self:end; margin-bottom:2px;" onclick="this.parentElement.remove()"><i class="bx bx-trash"></i></button>';

    container.appendChild(div);
    contadorPiezas++;
  }

  function abrirModalNuevo() {
    contadorPiezas = 0;
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-plus-circle'></i> Nuevo Modelo";
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-accion').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-temporada').value = '';
    document.getElementById('contenedor-piezas').innerHTML = '';
    agregarPieza('', 1); 
    document.getElementById('modal-modelo').classList.add('active');
  }

  function cerrarModal() {
    document.getElementById('modal-modelo').classList.remove('active');
    history.replaceState(null, '', '<%= request.getContextPath() %>/catalogo-modelos');
  }

  <% if (modeloEditar != null) { %>
  window.addEventListener('DOMContentLoaded', function() {
    document.getElementById('modal-titulo').innerHTML = "<i class='bx bx-edit'></i> Editar Modelo";
    document.getElementById('modal-id').value = '<%= modeloEditar.getIdModelo() %>';
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-nombre').value = '<%= modeloEditar.getNombre().replace("'", "\\'") %>';
    document.getElementById('modal-temporada').value = '<%= modeloEditar.getTemporada() != null ? modeloEditar.getTemporada().replace("'", "\\'") : "" %>';
    
    <% for (PiezaModelo p : modeloEditar.getPiezas()) { 
        StringBuilder fasesStr = new StringBuilder();
        for (Integer idFase : p.getIdFasesAsignadas()) {
            if (fasesStr.length() > 0) fasesStr.append(",");
            fasesStr.append(idFase);
        }
    %>
        agregarPieza('<%= p.getNombrePieza().replace("'", "\\'") %>', <%= p.getCantidad() %>, '<%= fasesStr.toString() %>'.split(',').filter(f => f));
    <% } %>
        
    <% if (modeloEditar.getPiezas().isEmpty()) { %> agregarPieza('', 1); <% } %>
    document.getElementById('modal-modelo').classList.add('active');
  });
  <% } %>

  function verPiezas(id, nombre) {
    document.getElementById('piezas-titulo').innerHTML = "<i class='bx bx-show'></i> " + nombre;
    document.getElementById('piezas-body').innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:1rem;"><i class="bx bx-loader bx-spin"></i> Cargando...</p>';
    document.getElementById('modal-piezas').classList.add('active');

    fetch('<%= request.getContextPath() %>/catalogo-modelos?accion=verPiezas&id=' + id)
        .then(r => r.json())
        .then(piezas => {
            if (!piezas.length) {
                document.getElementById('piezas-body').innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:1rem;">Este modelo no tiene piezas registradas.</p>';
                return;
            }
            let html = '<table class="tabla-piezas"><thead>' +
                '<tr><th>#</th><th>Pieza</th><th style="text-align:center">Cant.</th><th>Fases</th></tr>' +
                '</thead><tbody>';
            piezas.forEach((p, i) => {
                let fasesHtml = '';
                if (p.fases && p.fases.length) {
                    fasesHtml = p.fases.map(f => '<span style="display:inline-block; background:var(--info-bg); color:var(--info-text); padding:2px 8px; border-radius:12px; margin:2px; font-size:0.7rem; font-weight:600;">' + f.nombre + '</span>').join('');
                } else {
                    fasesHtml = '<span style="color:var(--text-muted);">—</span>';
                }
                html += '<tr><td style="color:var(--text-muted)">' + (i+1) + '</td>' +
                    '<td><strong>' + p.nombre + '</strong></td>' +
                    '<td style="text-align:center"><span class="cant-badge">' + p.cantidad + '</span></td>' +
                    '<td>' + fasesHtml + '</td></tr>';
            });
            html += '</tbody></table>';
            document.getElementById('piezas-body').innerHTML = html;
        })
        .catch(() => { document.getElementById('piezas-body').innerHTML = '<p style="color:var(--danger-hover);text-align:center;">Error al cargar las piezas.</p>'; });
  }
    
  document.getElementById('busquedaModelos').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('td[colspan]')) return;
      var modelo = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      var temporada = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
      if (!filtro || modelo.includes(filtro) || temporada.includes(filtro)) { tr.style.display = ''; } else { tr.style.display = 'none'; }
    });
  });

  function abrirModalFase() { document.getElementById('modal-fase').classList.add('active'); }
  function cerrarModalFase() {
      document.getElementById('modal-fase').classList.remove('active');
      document.getElementById('nombreFase').value = '';
      document.getElementById('ordenFase').value = '';
      document.getElementById('descripcionFase').value = '';
  }

  function guardarNuevaFase() {
      const nombre = document.getElementById('nombreFase').value.trim();
      const orden = parseInt(document.getElementById('ordenFase').value);
      const descripcion = document.getElementById('descripcionFase').value.trim();
      if (!nombre) { alert('El nombre de la fase es obligatorio'); return; }
      if (isNaN(orden) || orden < 1) { alert('El orden debe ser un número positivo'); return; }

      fetch('<%= request.getContextPath() %>/catalogo-modelos', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ accion: 'agregarFase', nombre: nombre, orden: orden, descripcion: descripcion })
      }).then(response => {
          if (!response.ok) { return response.json().then(err => { throw new Error(err.error || 'Error en servidor'); }); }
          return response.json();
      }).then(data => {
          if (data.error) throw new Error(data.error);
          listaFases = data;
          refrescarCheckboxesEnTodasLasFilas();
          cerrarModalFase();
      }).catch(error => {
          console.error('Error:', error);
          alert('Error al guardar la fase: ' + error.message);
      });
  }

  function refrescarCheckboxesEnTodasLasFilas() {
      const filas = document.querySelectorAll('#contenedor-piezas .fila-pieza');
      filas.forEach((fila, idx) => {
          const nombreInput = fila.querySelector('input[name="nombrePieza[]"]');
          const cantidadInput = fila.querySelector('input[name="cantidadPieza[]"]');
          const nombre = nombreInput ? nombreInput.value : '';
          const cantidad = cantidadInput ? cantidadInput.value : 1;
          
          const checkboxesActuales = fila.querySelectorAll('input[type="checkbox"][name^="fasesPieza_"]');
          let fasesSeleccionadas = [];
          checkboxesActuales.forEach(cb => { if (cb.checked) fasesSeleccionadas.push(cb.value); });
          
          const nuevoDiv = document.createElement('div');
          nuevoDiv.className = 'fila-pieza';
          nuevoDiv.setAttribute('data-indice', idx);
          
          let checkboxesHtml = '';
          for (let fase of listaFases) {
              let checked = fasesSeleccionadas.includes(fase.id.toString()) ? 'checked' : '';
              checkboxesHtml += '<label class="check-fase">' +
                  '<input type="checkbox" name="fasesPieza_' + idx + '" value="' + fase.id + '" ' + checked + '>' +
                  fase.nombre + '</label>';
          }
          nuevoDiv.innerHTML = 
              '<div class="field"><label>Nombre de la Pieza</label><input type="text" class="form-control" name="nombrePieza[]" value="' + escapeHtml(nombre) + '" placeholder="Ej: Copa izquierda" required></div>' +
              '<div class="field"><label>Cant. por prenda</label><input type="number" class="form-control" name="cantidadPieza[]" min="1" value="' + cantidad + '" required></div>' +
              '<div class="field"><label>Fases de producción</label><div style="display:flex; flex-wrap:wrap; gap:4px;">' + checkboxesHtml + '</div></div>' +
              '<button type="button" class="btn-icon delete" style="align-self:end; margin-bottom:2px;" onclick="this.parentElement.remove()"><i class="bx bx-trash"></i></button>';
          
          fila.parentNode.replaceChild(nuevoDiv, fila);
      });
  }

  function escapeHtml(str) { return str.replace(/[&<>]/g, function(m) { if (m === '&') return '&amp;'; if (m === '<') return '&lt;'; if (m === '>') return '&gt;'; return m; }).replace(/"/g, '&quot;'); }
  // Función para desplegar el menú lateral
function toggleSubmenu(element) {
    element.parentElement.classList.toggle('active');
}
</script>

</body>
</html>