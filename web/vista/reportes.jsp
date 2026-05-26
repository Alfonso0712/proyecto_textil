<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, java.util.Set, java.util.List, java.util.Map, java.math.BigDecimal" %>
<%
    // Protección de sesión
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    String rolUsuario = (String) request.getAttribute("rolUsuario");
    if (rolUsuario == null) rolUsuario = usuarioSesion.getNombreRol();
    String r = rolUsuario.toUpperCase();

    // Banderas de permisos visuales según esquema BD
    boolean esAdmin      = r.contains("ADMINISTRADOR");
    boolean esAlmacen    = r.contains("JEFE_ALMACEN") || esAdmin;
    boolean esProduccion = r.contains("JEFE_PRODUCCION") || esAdmin;
    boolean esTizador    = r.contains("TIZADOR") || esProduccion;
    boolean esSupervisor = r.contains("SUPERVISOR") || esProduccion;
    boolean esMaquinista = r.contains("MAQUINISTA");

    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new java.util.HashSet<>();

    boolean verSeguridad   = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacenPerm = permisos.contains("ALM_TELA_VER");
    boolean verProduccion  = permisos.contains("PROD_OT_VER");
    boolean verCalidadPerm = permisos.contains("CAL_DEFECTOS_REG");
    boolean verDespacho    = permisos.contains("DES_CONCIL_REG");
    boolean verCargas      = permisos.contains("PROD_CARGAS_ASIG");
    boolean verReportes    = permisos.contains("RPT_MERMAS_CALIDAD") || permisos.contains("RPT_DASHBOARD") || r.contains("ADMIN") || r.contains("GERENTE") || r.contains("SUPERVISOR") || r.contains("JEFE_PRODUCCION");
    boolean verReposo      = permisos.contains("PROD_REPOSO_VER") || esAdmin;
    boolean verFallas      = permisos.contains("PROD_FALLAS_VER") || esAdmin;
    boolean verMerma       = permisos.contains("PROD_MERMA_VER")  || esAdmin;

    @SuppressWarnings("unchecked")
    List<Map<String, Object>> mermaPorOT = (List<Map<String, Object>>) request.getAttribute("mermaPorOT");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> tiemposMaquinistas = (List<Map<String, Object>>) request.getAttribute("tiemposMaquinistas");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> fallasPorTela = (List<Map<String, Object>>) request.getAttribute("fallasPorTela");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> eficienciaGlobal = (List<Map<String, Object>>) request.getAttribute("eficienciaGlobal");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> inventarioTelas = (List<Map<String, Object>>) request.getAttribute("inventarioTelas");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> calidadVsProductividad = (List<Map<String, Object>>) request.getAttribute("calidadVsProductividad");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> otsProblematicas = (List<Map<String, Object>>) request.getAttribute("otsProblematicas");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> desviacionDespacho = (List<Map<String, Object>>) request.getAttribute("desviacionDespacho");
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> rendimientoMaquinista = (List<Map<String, Object>>) request.getAttribute("rendimientoMaquinista");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reportes Avanzados - Sistema Textil</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/xlsx/dist/xlsx.full.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    
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
            --radius-sm: 6px; --radius-md: 8px;
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
        main { flex: 1; display: flex; flex-direction: column; overflow-y: auto; overflow-x: hidden; }
        header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); flex-wrap: wrap; gap: 1rem; z-index: 10;}
        header h2 { font-size: 1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
        .user-info { display: flex; align-items: center; gap: 12px; font-size: 0.85rem; font-weight: 500; }
        .badge-rol { background: #e2e8f0; color: var(--text-main); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm); font-size: 0.75rem; font-weight: 600; text-transform: uppercase; }
        .btn-salir { padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px; transition:0.2s;}
        .btn-salir:hover { background: var(--danger-hover); color: #fff; }

        /* ── REPORTES CONTROLES ── */
        .header-actions { display: flex; gap: 0.5rem; flex-wrap: wrap; }
        .btn { padding: 0.5rem 1rem; border: none; border-radius: var(--radius-sm); font-size: 0.85rem; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; font-family: 'Inter', sans-serif;}
        .btn-pdf { background-color: var(--danger-text); color: white; } 
        .btn-pdf:hover { background-color: var(--danger-hover); }
        .btn-excel { background-color: var(--success-text); color: white; } 
        .btn-excel:hover { background-color: #047857; }
        .btn-view { background-color: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); } 
        .btn-view:hover { background-color: var(--color-bg); }
        .btn-view.active { background-color: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        
        /* TABS MODERNIZADOS */
        .tabs { display: flex; gap: 8px; padding: 16px 24px 0; border-bottom: 1px solid var(--border-color); background: var(--color-surface); flex-wrap: wrap; }
        .tab-btn { padding: 10px 16px; background: transparent; border: none; font-weight: 600; color: var(--text-muted); cursor: pointer; border-bottom: 3px solid transparent; transition: all 0.2s; font-size: 0.85rem; display:flex; align-items:center; gap:6px; font-family: 'Inter', sans-serif;}
        .tab-btn:hover { color: var(--color-primary); }
        .tab-btn.active { color: var(--color-primary); border-bottom-color: var(--color-primary); }
        
        .tab-content { display: none; padding: 24px; }
        .tab-content.active { display: block; }

        .section-title { font-size: 1.1rem; font-weight: 700; color: var(--color-secondary); margin-bottom: 1rem; padding-bottom: 0.5rem; border-bottom: 2px solid var(--border-color); }
        
        .view-controls { display: flex; justify-content: space-between; gap: 16px; margin: 16px 24px 0; background: var(--color-surface); padding: 12px 16px; border-radius: var(--radius-md); box-shadow: 0 1px 3px rgba(0,0,0,0.04); align-items: center; flex-wrap: wrap; border: 1px solid var(--border-color); }
        .view-controls span { font-weight: 600; font-size: 0.85rem; color: var(--text-main); margin-right: 8px; }

        /* GRID RESPONSIVO & CARDS */
        .grid-container { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 32px; transition: all 0.3s ease; align-items: stretch; }
        .grid-container.solo-tabla { grid-template-columns: 1fr; }
        .grid-container.solo-grafico { grid-template-columns: 1fr; }
        .grid-container.solo-tabla .card-grafico { position: absolute; visibility: hidden; opacity: 0; pointer-events: none; z-index: -1; height: 0; }
        .grid-container.solo-grafico .card-tabla { position: absolute; visibility: hidden; opacity: 0; pointer-events: none; z-index: -1; height: 0; }
        
        .card { background: var(--color-surface); border-radius: var(--radius-md); padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); display: flex; flex-direction: column; overflow: hidden; }
        
        .card-tabla { max-height: 400px; overflow-y: auto; overflow-x: auto; }
        
        .card-grafico { display: flex; justify-content: center; align-items: center; min-height: 350px; }
        .chart-wrapper { position: relative; height: 350px; width: 100%; }
        
        .modo-tabla .card-grafico { display: none; }
        .modo-grafico .card-tabla { display: none; }

        table { width: 100%; border-collapse: collapse; font-size: 0.82rem; white-space: nowrap;}
        th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border-color); color: var(--text-main); }
        th { background: #f8fafc; color: var(--text-muted); font-weight: 600; text-transform: uppercase; font-size: 0.72rem; position: sticky; top: 0; z-index: 2; border-bottom: 2px solid var(--border-color);}
        tfoot th { background: var(--color-secondary); color: white; font-weight: bold; border-bottom: none;}

        /* Responsive */
        @media (max-width: 1100px) {
            .grid-container { grid-template-columns: 1fr; }
            .chart-wrapper { height: 300px; }
        }
        @media (max-width: 768px) {
            body { flex-direction: column; }
            aside { width: 100%; height: auto; flex-direction: row; align-items: center; justify-content: space-between; padding-right: 1rem; }
            .sidebar-logo { border-bottom: none; }
            .sidebar-nav { display: flex; flex-direction: row; overflow-x: auto; padding: 0; }
            .menu-group { margin-bottom: 0; }
            header { flex-direction: column; align-items: flex-start; }
            .tabs { overflow-x: auto; white-space: nowrap; flex-wrap: nowrap; padding-bottom: 0.5rem; }
            .tab-btn { flex: 0 0 auto; }
            .view-controls { flex-direction: column; align-items: flex-start; }
            .btn-view { width: 100%; justify-content: center; }
        }
    </style>
</head>
<body class="modo-ambos">

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
        <div class="menu-group active">
         <div class="menu-toggle" onclick="toggleSubmenu(this)">
            <span><i class='bx bx-bar-chart-square'></i> Reportes</span>
            <i class='bx bx-chevron-down arrow'></i>
          </div>
          <div class="menu-content">
            <a href="<%= _cp %>/reportes" class="menu-link activo">Analíticas</a>
          </div>
        </div>
        <% } %>
      </nav>
    </aside>

    <main>
        <header>
            <h2><i class="bx bx-pie-chart-alt-2"></i> Panel de Reportes</h2>
            <div class="user-info">
                <span><%= usuarioSesion.getNombreCompleto() %></span>
                <span class="badge-rol"><%= rolUsuario %></span>
                <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class="bx bx-log-out"></i> Salir</a>
            </div>
        </header>

        <div class="tabs">
            <% if(esMaquinista) { %>
            <button class="tab-btn active" onclick="openTab(event, 'tabRendimiento')"><i class="fa-solid fa-user-gear"></i> Mi Rendimiento</button>
            <% } %>
            <% if(esProduccion) { %>
            <button class="tab-btn <%= !esMaquinista ? "active" : "" %>" onclick="openTab(event, 'tabEstrategico')"><i class="fa-solid fa-chess-knight"></i> Estratégico</button>
            <% } %>
            <% if(esSupervisor) { %>
            <button class="tab-btn <%= (!esProduccion && !esMaquinista) ? "active" : "" %>" onclick="openTab(event, 'tabEficiencia')"><i class="fa-solid fa-rocket"></i> Supervisión</button>
            <% } %>
            <% if(esTizador) { %>
            <button class="tab-btn <%= (!esSupervisor && !esMaquinista) ? "active" : "" %>" onclick="openTab(event, 'tabOperativa')"><i class="fa-solid fa-industry"></i> Preparación / Mermas</button>
            <% } %>
            <% if(esAlmacen) { %>
            <button class="tab-btn <%= (!esProduccion && !esSupervisor && !esTizador && !esMaquinista) ? "active" : "" %>" onclick="openTab(event, 'tabAlmacen')"><i class="fa-solid fa-boxes-stacked"></i> Almacén</button>
            <% } %>
        </div>

        <div id="area-reporte">
            
            <div class="view-controls">
                <div style="display:flex; gap:0.5rem; align-items:center; flex-wrap: wrap;">
                    <span><i class="fa-solid fa-eye"></i> Visualización:</span>
                    <button class="btn btn-view" id="btn-modo-tabla" onclick="setModo('tabla')"><i class="fa-solid fa-table"></i> Solo Tabla</button>
                    <button class="btn btn-view" id="btn-modo-grafico" onclick="setModo('grafico')"><i class="fa-solid fa-chart-bar"></i> Solo Gráfico</button>
                    <button class="btn btn-view active" id="btn-modo-ambos" onclick="setModo('ambos')"><i class="fa-solid fa-table-columns"></i> Ambos Lados</button>
                </div>
                <div class="header-actions">
                    <button class="btn btn-pdf" onclick="exportarPDF()"><i class="fa-solid fa-file-pdf"></i> Exportar PDF</button>
                    <button class="btn btn-excel" onclick="exportarExcel()"><i class="fa-solid fa-file-excel"></i> Exportar Excel</button>
                </div>
            </div>

            <% if(esMaquinista) { %>
            <div id="tabRendimiento" class="tab-content active">
                <div class="section-title">Mi Rendimiento Personal</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="rendimientoChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-rendimiento">
                            <thead><tr><th>OT</th><th>Asignado</th><th>Prendas Est.</th><th>Minutos Inv.</th><th>Estado Entrega</th><th>Min/Prenda</th><th>Defectos (Fallas)</th></tr></thead>
                            <tbody>
                                <% 
                                int totalMiMin = 0;
                                int totalMiPrendas = 0; int totalMiDef = 0;
                                if(rendimientoMaquinista != null && !rendimientoMaquinista.isEmpty()) {
                                    for(Map<String, Object> rMaq : rendimientoMaquinista) { 
                                        totalMiMin += (Integer)rMaq.get("minutos_trabajados");
                                        totalMiPrendas += (Integer)rMaq.get("cantidad_est");
                                        totalMiDef += (Integer)rMaq.get("defectos_propios");
                                %>
                                    <tr>
                                        <td style="font-family:monospace; font-weight:700;"><%= rMaq.get("codigo_ot") %></td>
                                        <td><%= rMaq.get("fecha_asignada") %></td>
                                        <td class="text-center"><%= rMaq.get("cantidad_est") %></td>
                                        <td class="text-center"><%= rMaq.get("minutos_trabajados") %></td>
                                        <td style="color:<%= rMaq.get("eficiencia_entrega").toString().startsWith("Retraso") ? "var(--danger-text)" : "var(--success-text)" %>; font-weight:600;"><%= rMaq.get("eficiencia_entrega") %></td>
                                        <td class="text-center"><%= rMaq.get("velocidad_min_prenda") %></td>
                                        <td class="text-center"><%= rMaq.get("defectos_propios") %></td>
                                    </tr>
                                <% } } else { %>
                                    <tr><td colspan="7" style="text-align:center; color:var(--text-muted); padding:2rem;">No tienes órdenes completadas aún.</td></tr>
                                <% } %>
                            </tbody>
                            <tfoot>
                                <tr>
                                    <th colspan="2">MIS ACUMULADOS</th>
                                    <th><%= totalMiPrendas %> pr</th>
                                    <th><%= totalMiMin/60 %>h <%= totalMiMin%60 %>m</th>
                                    <th>-</th>
                                    <th><%= totalMiPrendas > 0 ? String.format("%.2f", (double)totalMiMin/totalMiPrendas) : 0 %></th>
                                    <th><%= totalMiDef %> def</th>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
            <% } %>

            <% if(esProduccion) { %>
            <div id="tabEstrategico" class="tab-content <%= !esMaquinista ? "active" : "" %>">
                <div class="section-title">Cruce: Calidad vs Productividad del Maquinista</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="scatterChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-calidadproductividad">
                            <thead><tr><th>Maquinista</th><th>Minutos Trabajados</th><th>Defectos Generados</th><th>Tasa (Min/Defecto)</th></tr></thead>
                            <tbody>
                                <% 
                                int totalMin = 0;
                                int totalDefProd = 0;
                                if(calidadVsProductividad != null) {
                                    for(Map<String, Object> c : calidadVsProductividad) { 
                                        totalMin += (Integer)c.get("minutos");
                                        totalDefProd += (Integer)c.get("defectos");
                                    }
                                    for(Map<String, Object> c : calidadVsProductividad) {
                                        int m = (Integer)c.get("minutos");
                                        int d = (Integer)c.get("defectos");
                                        String tasa = d > 0 ? String.format("%.1f", (double)m/d) : "Perfecto (0 def)";
                                %>
                                    <tr><td style="font-weight:600;"><%= c.get("maquinista") %></td><td><%= m %></td><td><%= d %></td><td><%= tasa %></td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr>
                                    <th>PROMEDIOS GLOBALES</th>
                                    <th><%= totalMin %> min</th>
                                    <th><%= totalDefProd %> def</th>
                                    <th><%= totalDefProd > 0 ? String.format("%.1f", (double)totalMin/totalDefProd) : "0" %> min/def</th>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <div class="section-title">OTs Problemáticas (Top 15 con más Defectos/Merma)</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="otsProblematicasChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-otsproblematicas">
                            <thead><tr><th>OT</th><th>Cant. Estimada</th><th>Total Merma (Kg)</th><th>Defectos (Reproceso)</th><th>Tasa Falla (%)</th></tr></thead>
                            <tbody>
                                <% 
                                double totMermaProb = 0.0; int totDefProb = 0; int totCant = 0;
                                if(otsProblematicas != null) {
                                    for(Map<String, Object> ot : otsProblematicas) { 
                                        totMermaProb += ((BigDecimal)ot.get("merma")).doubleValue();
                                        totDefProb += (Integer)ot.get("defectos");
                                        totCant += (Integer)ot.get("cantidad_est");
                                    }
                                    for(Map<String, Object> ot : otsProblematicas) {
                                %>
                                    <tr><td style="font-family:monospace; font-weight:700;"><%= ot.get("codigo_ot") %></td><td><%= ot.get("cantidad_est") %></td><td><%= ot.get("merma") %></td><td><%= ot.get("defectos") %></td><td style="color:var(--danger-hover);font-weight:bold;"><%= ot.get("tasa_falla") %>%</td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <% String tFall = totCant > 0 ? String.format("%.1f", ((double)totDefProb/totCant)*100) : "0.0"; %>
                                <tr><th>TOTAL (Top 15)</th><th><%= totCant %> uds</th><th><%= String.format("%.2f", totMermaProb) %> Kg</th><th><%= totDefProb %> def</th><th><%= tFall %>%</th></tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <div class="section-title">Desviaciones de Despacho (Planeado vs Final)</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="desviacionesChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-desviaciones">
                            <thead><tr><th>OT</th><th>Planeado</th><th>Finalizado</th><th>Diferencia</th><th>% Desv.</th></tr></thead>
                            <tbody>
                                <% 
                                int totPlaneado = 0;
                                int totFinal = 0; int totDif = 0;
                                if(desviacionDespacho != null) {
                                    for(Map<String, Object> d : desviacionDespacho) { 
                                        totPlaneado += (Integer)d.get("estimada");
                                        totFinal += (Integer)d.get("final");
                                        totDif += (Integer)d.get("diferencia");
                                    }
                                    for(Map<String, Object> d : desviacionDespacho) {
                                        int p = (Integer)d.get("estimada");
                                        int dif = (Integer)d.get("diferencia");
                                        String pctDesc = p > 0 ? String.format("%.1f", ((double)dif/p)*100) : "0.0";
                                %>
                                    <tr>
                                        <td style="font-family:monospace; font-weight:700;"><%= d.get("codigo_ot") %></td><td><%= p %></td><td><%= d.get("final") %></td>
                                        <td style="color: <%= dif < 0 ? "var(--danger-text)" : "var(--success-text)" %>; font-weight:bold;"><%= dif >= 0 ? "+" : "" %><%= dif %></td>
                                        <td style="color: <%= dif < 0 ? "var(--danger-text)" : "var(--success-text)" %>"><%= pctDesc %>%</td>
                                    </tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <% String totPctDif = totPlaneado > 0 ? String.format("%.1f", ((double)totDif/totPlaneado)*100) : "0.0"; %>
                                <tr>
                                    <th>BALANCE</th><th><%= totPlaneado %></th><th><%= totFinal %></th>
                                    <th style="color: <%= totDif < 0 ? "#ff9999" : "#a8e6cf" %>"><%= totDif >= 0 ? "+" : "" %><%= totDif %></th>
                                    <th style="color: <%= totDif < 0 ? "#ff9999" : "#a8e6cf" %>"><%= totPctDif %>%</th>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
            <% } %>
            
            <% if(esSupervisor) { %>
            <div id="tabEficiencia" class="tab-content <%= !esProduccion ? "active" : "" %>">
                <div class="section-title">Eficiencia Global de Órdenes de Trabajo</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="eficienciaChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-eficiencia">
                            <thead><tr><th>Estado OT</th><th>Cantidad de OTs</th><th>% del Total</th></tr></thead>
                            <tbody>
                                <% 
                                int totEfi = 0;
                                if(eficienciaGlobal != null) {
                                    for(Map<String, Object> e : eficienciaGlobal) { totEfi += (Integer)e.get("total"); }
                                    for(Map<String, Object> e : eficienciaGlobal) { 
                                        int c = (Integer)e.get("total");
                                        String pct = totEfi > 0 ? String.format("%.1f", ((double)c/totEfi)*100) : "0.0";
                                %>
                                    <tr><td style="font-weight:600;"><%= e.get("estado") %></td><td><%= c %></td><td><%= pct %>%</td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr><th>TOTAL OTs</th><th><%= totEfi %></th><th>100%</th></tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <div class="section-title">Ciclo de Vida Maquinistas por OT</div>
                <div class="grid-container">
                    <div class="card card-tabla">
                        <table id="tabla-tiempos">
                            <thead><tr><th>OT</th><th>Maquinista</th><th>Inicio Real</th><th>Fin Real</th><th>Trabajo Efectivo</th></tr></thead>
                            <tbody>
                                <% 
                                int sumMin = 0;
                                if(tiemposMaquinistas != null && !tiemposMaquinistas.isEmpty()) {
                                    for(Map<String, Object> t : tiemposMaquinistas) { 
                                        sumMin += (Integer)t.get("minutos_trabajados");
                                %>
                                    <tr><td style="font-family:monospace; font-weight:700;"><%= t.get("codigo_ot") %></td><td><%= t.get("maquinista") %></td><td><%= t.get("inicio_real") %></td><td><%= t.get("fin_real") %></td><td style="color:var(--success-text);font-weight:bold;"><%= t.get("tiempo_formateado") %></td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr><th colspan="4">TOTAL HORAS EFECTIVAS EN PLANTA</th><th><%= sumMin/60 %>h <%= sumMin%60 %>m</th></tr>
                            </tfoot>
                        </table>
                    </div>
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="tiemposChart"></canvas></div>
                    </div>
                </div>
            </div>
            <% } %>

            <% if(esTizador) { %>
            <div id="tabOperativa" class="tab-content <%= (!esProduccion && !esSupervisor) ? "active" : "" %>">
                <div class="section-title">Merma por Orden de Trabajo</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="mermaChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-mermas">
                            <thead><tr><th>OT</th><th>Peso Utilizado (Kg)</th><th>Peso Merma (Kg)</th><th>% Merma</th></tr></thead>
                            <tbody>
                                <% 
                                double totUso = 0; double totMerma = 0;
                                if(mermaPorOT != null && !mermaPorOT.isEmpty()) {
                                    for(Map<String, Object> m : mermaPorOT) { 
                                        totUso += ((BigDecimal)m.get("peso_utilizado")).doubleValue();
                                        totMerma += ((BigDecimal)m.get("peso_merma")).doubleValue();
                                %>
                                    <tr><td style="font-family:monospace; font-weight:700;"><%= m.get("codigo_ot") %></td><td><%= m.get("peso_utilizado") %></td><td><%= m.get("peso_merma") %></td><td><%= m.get("porcentaje_merma") %>%</td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr>
                                    <th>HISTÓRICO</th>
                                    <th><%= String.format("%.2f", totUso) %> Kg</th>
                                    <th><%= String.format("%.2f", totMerma) %> Kg</th>
                                    <th><%= totUso > 0 ? String.format("%.2f", (totMerma/totUso)*100) : "0" %>%</th>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <div class="section-title">Fallas Registradas por Tipo de Tela</div>
                <div class="grid-container">
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="fallasChart"></canvas></div>
                    </div>
                    <div class="card card-tabla">
                        <table id="tabla-fallas">
                            <thead><tr><th>Código Tela</th><th>Cantidad de Fallas</th><th>% del Total</th></tr></thead>
                            <tbody>
                                <% 
                                int totFallas = 0;
                                if(fallasPorTela != null && !fallasPorTela.isEmpty()) {
                                    for(Map<String, Object> f : fallasPorTela) { totFallas += (Integer)f.get("fallas_totales"); }
                                    for(Map<String, Object> f : fallasPorTela) { 
                                        int c = (Integer)f.get("fallas_totales");
                                        String pct = totFallas > 0 ? String.format("%.1f", ((double)c/totFallas)*100) : "0.0";
                                %>
                                    <tr><td style="font-family:monospace; font-weight:700;"><%= f.get("codigo_tela") %></td><td><%= c %></td><td><%= pct %>%</td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr><th>INCIDENCIAS TOTALES</th><th><%= totFallas %></th><th>100%</th></tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
            <% } %>

            <% if(esAlmacen) { %>
            <div id="tabAlmacen" class="tab-content <%= (!esProduccion && !esSupervisor && !esTizador) ? "active" : "" %>">
                <div class="section-title">Inventario de Telas por Estado</div>
                <div class="grid-container">
                    <div class="card card-tabla">
                        <table id="tabla-inventario">
                            <thead><tr><th>Estado de Calidad</th><th>Rollos/Bultos</th><th>% Rollos</th><th>Peso Total (Kg)</th><th>Peso Promedio/Rollo</th></tr></thead>
                            <tbody>
                                <% 
                                int totRollos = 0;
                                double totPesoInv = 0;
                                if(inventarioTelas != null && !inventarioTelas.isEmpty()) {
                                    for(Map<String, Object> i : inventarioTelas) { 
                                        totRollos += (Integer)i.get("cantidad");
                                        if (i.get("peso_total") != null) totPesoInv += ((BigDecimal)i.get("peso_total")).doubleValue();
                                    }
                                    for(Map<String, Object> i : inventarioTelas) {
                                        int c = (Integer)i.get("cantidad");
                                        String pct = totRollos > 0 ? String.format("%.1f", ((double)c/totRollos)*100) : "0.0";
                                        String avgStr = i.get("peso_promedio") != null ? String.format("%.2f", ((BigDecimal)i.get("peso_promedio")).doubleValue()) : "0.0";
                                %>
                                    <tr><td style="font-weight:600;"><%= i.get("estado") %></td><td><%= c %></td><td><%= pct %>%</td><td><%= i.get("peso_total") %> Kg</td><td><%= avgStr %> Kg</td></tr>
                                <% } } %>
                            </tbody>
                            <tfoot>
                                <tr><th>TOTAL ALMACÉN</th><th><%= totRollos %> rollos</th><th>100%</th><th><%= String.format("%.2f", totPesoInv) %> Kg</th><th>-</th></tr>
                            </tfoot>
                        </table>
                    </div>
                    <div class="card card-grafico">
                        <div class="chart-wrapper"><canvas id="inventarioChart"></canvas></div>
                    </div>
                </div>
            </div>
            <% } %>

        </div>
    </main>

    <script>
        // UI MENÚ ACORDEÓN
        function toggleSubmenu(element) {
          element.parentElement.classList.toggle('active');
        }

        // ─── LÓGICA JAVASCRIPT INTACTA ──────────────────────────
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tab-content");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
                tabcontent[i].classList.remove("active");
            }
            tablinks = document.getElementsByClassName("tab-btn");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            document.getElementById(tabName).classList.add("active");
            evt.currentTarget.className += " active";
        }

        function setModo(modo) {
            document.body.className = 'modo-' + modo;
            document.getElementById('btn-modo-tabla').classList.remove('active');
            document.getElementById('btn-modo-grafico').classList.remove('active');
            document.getElementById('btn-modo-ambos').classList.remove('active');
            document.getElementById('btn-modo-' + modo).classList.add('active');

            const grids = document.querySelectorAll('.grid-container');
            grids.forEach(grid => {
                grid.className = 'grid-container';
                if(modo === 'tabla') grid.classList.add('solo-tabla');
                if(modo === 'grafico') grid.classList.add('solo-grafico');
            });
            Object.keys(Chart.instances).forEach(function(key) {
                Chart.instances[key].resize();
            });
        }

        function exportarPDF() {
            const element = document.querySelector('.tab-content.active');
            const opt = { 
                margin: 10, 
                filename: 'reporte-textil.pdf', 
                image: { type: 'jpeg', quality: 0.98 }, 
                html2canvas: { scale: 2 }, 
                jsPDF: { unit: 'mm', format: 'a4', orientation: 'landscape' }
            };
            html2pdf().set(opt).from(element).save();
        }

        function exportarExcel() {
            const wb = XLSX.utils.book_new();
            const tablas = document.querySelectorAll('.tab-content.active table');
            if(tablas.length === 0) { alert('No hay tablas en la pestaña actual para exportar.'); return; }
            tablas.forEach(tabla => {
                if (tabla.rows.length > 2) { 
                    const ws = XLSX.utils.table_to_sheet(tabla);
                    let title = tabla.id.replace('tabla-', '').substring(0, 31).toUpperCase();
                    XLSX.utils.book_append_sheet(wb, ws, title);
                }
            });
            XLSX.writeFile(wb, "Reportes_Textil_Actual.xlsx");
        }

        // CHART CONFIGURATIONS
        Chart.defaults.maintainAspectRatio = false;
        window.onload = function() {
            <% if(esProduccion) { %>
            const scatLabels = [], scatData = [];
            <% if(calidadVsProductividad != null) { for(Map<String, Object> c : calidadVsProductividad) { %>
                scatLabels.push('<%= c.get("maquinista") %>');
                scatData.push({ x: <%= c.get("minutos") %>, y: <%= c.get("defectos") %> });
            <% } } %>
            const scCtx = document.getElementById('scatterChart');
            if(scCtx && scatData.length > 0) {
                new Chart(scCtx, {
                    type: 'scatter',
                    data: {
                        labels: scatLabels,
                        datasets: [{
                            label: 'Maquinistas',
                            data: scatData,
                            backgroundColor: '#e74c3c',
                            pointRadius: 6,
                            pointHoverRadius: 8
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            title: { display: true, text: 'Productividad (X) vs Calidad (Y)' },
                            tooltip: {
                                callbacks: {
                                    label: function(ctx) { return scatLabels[ctx.dataIndex] + ': ' + ctx.raw.x + ' min, ' + ctx.raw.y + ' def'; }
                                }
                            }
                        },
                        scales: {
                            x: { title: { display: true, text: 'Minutos Totales Trabajados' } },
                            y: { title: { display: true, text: 'Defectos Generados' } }
                        }
                    }
                });
            }

            const otProbLabels = [], otProbDefData = [], otProbMermaData = [];
            <% if(otsProblematicas != null) { for(Map<String, Object> ot : otsProblematicas) { %>
                otProbLabels.push('<%= ot.get("codigo_ot") %>');
                otProbDefData.push(<%= ot.get("defectos") %>);
                otProbMermaData.push(<%= ot.get("merma") %>);
            <% } } %>
            const otpCtx = document.getElementById('otsProblematicasChart');
            if(otpCtx && otProbLabels.length > 0) {
                new Chart(otpCtx, {
                    type: 'bar',
                    data: {
                        labels: otProbLabels,
                        datasets: [
                            { label: 'Defectos', data: otProbDefData, backgroundColor: '#c0392b', yAxisID: 'y' },
                            { label: 'Merma (Kg)', data: otProbMermaData, backgroundColor: '#d35400', yAxisID: 'y1' }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: { title: { display: true, text: 'Defectos y Mermas por OT' } },
                        scales: {
                            y: { type: 'linear', display: true, position: 'left', title: {display: true, text: 'Cant. Defectos'} },
                            y1: { type: 'linear', display: true, position: 'right', grid: {drawOnChartArea: false}, title: {display: true, text: 'Merma (Kg)'} }
                        }
                    }
                });
            }

            const desvLabels = [], desvEstData = [], desvFinData = [];
            <% if(desviacionDespacho != null) { for(Map<String, Object> d : desviacionDespacho) { %>
                desvLabels.push('<%= d.get("codigo_ot") %>');
                desvEstData.push(<%= d.get("estimada") %>);
                desvFinData.push(<%= d.get("final") %>);
            <% } } %>
            const desvCtx = document.getElementById('desviacionesChart');
            if(desvCtx && desvLabels.length > 0) {
                new Chart(desvCtx, {
                    type: 'bar',
                    data: {
                        labels: desvLabels,
                        datasets: [
                            { label: 'Proyectado (Est)', data: desvEstData, backgroundColor: '#7f8c8d' },
                            { label: 'Despachado (Final)', data: desvFinData, backgroundColor: '#27ae60' }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: { title: { display: true, text: 'Proyectado vs Despachado por OT' } }
                    }
                });
            }
            <% } // fin esProduccion %>

            <% if(esSupervisor) { %>
            const efiLabels = [], efiData = [];
            <% if(eficienciaGlobal != null) { for(Map<String, Object> e : eficienciaGlobal) { %>
                efiLabels.push('<%= e.get("estado") %>');
                efiData.push(<%= e.get("total") %>);
            <% } } %>
            const efiCtx = document.getElementById('eficienciaChart');
            if(efiCtx && efiLabels.length > 0) {
                new Chart(efiCtx, {
                    type: 'doughnut',
                    data: { labels: efiLabels, datasets: [{ data: efiData, backgroundColor: ['#2ecc71', '#e74c3c', '#f1c40f', '#3498db', '#9b59b6'] }] },
                    options: { responsive: true, plugins: { title: { display: true, text: 'Eficiencia de Órdenes de Trabajo' } } }
                });
            }

            const tiemposLabels = [], tiemposData = [];
            <% if(tiemposMaquinistas != null) { int c=0; for(Map<String, Object> t : tiemposMaquinistas) { if(c++<10){ %>
                tiemposLabels.push('<%= t.get("maquinista") %>');
                tiemposData.push(<%= t.get("minutos_trabajados") %>);
            <% } } } %>
            const tCtx = document.getElementById('tiemposChart');
            if(tCtx && tiemposLabels.length > 0) {
                new Chart(tCtx, {
                    type: 'bar',
                    data: { labels: tiemposLabels, datasets: [{ label: 'Minutos', data: tiemposData, backgroundColor: 'rgba(52, 152, 219, 0.7)', borderRadius: 4 }] },
                    options: { indexAxis: 'y', responsive: true, plugins: { title: { display: true, text: 'Top 10 Tiempos Maquinistas' } } }
                });
            }
            <% } // fin esSupervisor %>

            <% if(esTizador) { %>
            const mermasLabels = [], mermasData = [];
            <% if(mermaPorOT != null) { for(Map<String, Object> m : mermaPorOT) { %>
                mermasLabels.push('<%= m.get("codigo_ot") %>');
                mermasData.push(<%= m.get("porcentaje_merma") %>);
            <% } } %>
            const merCtx = document.getElementById('mermaChart');
            if(merCtx && mermasLabels.length > 0) {
                new Chart(merCtx, {
                    type: 'bar',
                    data: { labels: mermasLabels, datasets: [{ label: '% Merma', data: mermasData, backgroundColor: 'rgba(231, 76, 60, 0.7)', borderRadius: 4 }] },
                    options: { responsive: true, plugins: { title: { display: true, text: '% de Merma por OT' } } }
                });
            }
            <% } // fin mermas esTizador %>

            <% if(esTizador) { %>
            const fallasLabels = [], fallasData = [];
            <% if(fallasPorTela != null) { for(Map<String, Object> f : fallasPorTela) { %>
                fallasLabels.push('<%= f.get("codigo_tela") %>');
                fallasData.push(<%= f.get("fallas_totales") %>);
            <% } } %>
            const fCtx = document.getElementById('fallasChart');
            if(fCtx && fallasLabels.length > 0) {
                new Chart(fCtx, {
                    type: 'pie',
                    data: { labels: fallasLabels, datasets: [{ data: fallasData, backgroundColor: ['#f1c40f', '#e67e22', '#e74c3c', '#9b59b6', '#34495e'] }] },
                    options: { responsive: true, plugins: { title: { display: true, text: 'Incidencias por Tipo de Tela' } } }
                });
            }
            <% } %>

            <% if(esAlmacen) { %>
            const invLabels = [], invData = [];
            <% if(inventarioTelas != null) { for(Map<String, Object> i : inventarioTelas) { %>
                invLabels.push('<%= i.get("estado") %>');
                invData.push(<%= i.get("cantidad") %>);
            <% } } %>
            const iCtx = document.getElementById('inventarioChart');
            if(iCtx && invLabels.length > 0) {
                new Chart(iCtx, {
                    type: 'bar',
                    data: { labels: invLabels, datasets: [{ label: 'Rollos en Stock', data: invData, backgroundColor: '#1abc9c', borderRadius: 4 }] },
                    options: { responsive: true, plugins: { title: { display: true, text: 'Estado Físico del Inventario' } } }
                });
            }
            <% } %>

            <% if(esMaquinista) { %>
            const rendLabels = [], rendData = [], rendDefData = [];
            <% if(rendimientoMaquinista != null) { int max=0; for(Map<String, Object> rMaq : rendimientoMaquinista) { if(max++<10) { %>
                rendLabels.push('<%= rMaq.get("codigo_ot") %>');
                rendData.push(<%= rMaq.get("velocidad_min_prenda") %>);
                rendDefData.push(<%= rMaq.get("defectos_propios") %>);
            <% } } } %>
            const rCtx = document.getElementById('rendimientoChart');
            if(rCtx && rendLabels.length > 0) {
                new Chart(rCtx, {
                    type: 'line',
                    data: { 
                        labels: rendLabels, 
                        datasets: [
                            { label: 'Velocidad (Min/Prenda)', data: rendData, borderColor: '#3498db', backgroundColor: '#3498db', yAxisID: 'y' },
                            { label: 'Defectos', data: rendDefData, type: 'bar', backgroundColor: 'rgba(231, 76, 60, 0.5)', yAxisID: 'y1' }
                        ] 
                    },
                    options: { 
                        responsive: true, 
                        plugins: { title: { display: true, text: 'Historial de Mi Rendimiento (Últimas OTs)' } },
                        scales: {
                            y: { type: 'linear', display: true, position: 'left', title: {display: true, text: 'Min/Prenda'} },
                            y1: { type: 'linear', display: true, position: 'right', grid: {drawOnChartArea: false}, title: {display: true, text: 'Defectos'} }
                        }
                    }
                });
            }
            <% } %>
        };
    </script>
</body>
</html>