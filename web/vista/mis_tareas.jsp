<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="modelo.*, java.util.*, java.text.SimpleDateFormat" %>
<%@ page import="java.sql.Timestamp" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    List<AsignacionCarga> tareas = (List<AsignacionCarga>) request.getAttribute("tareas");
    if (tareas == null) tareas = new ArrayList<>();

    // ✅ FIX: Te faltaba declarar tareasCompletadas, esto causaba el error 500
    List<AsignacionCarga> tareasCompletadas = (List<AsignacionCarga>) request.getAttribute("tareasCompletadas");
    if (tareasCompletadas == null) tareasCompletadas = new ArrayList<>();

    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<%! 
    public String calcularDuracion(Timestamp inicio, Timestamp fin) {
        if (inicio == null || fin == null) return "-";
        long diff = fin.getTime() - inicio.getTime(); // milisegundos
        long horas = diff / (60 * 60 * 1000);
        long minutos = (diff % (60 * 60 * 1000)) / (60 * 1000);
        if (horas > 0) {
            return horas + "h " + minutos + "m";
        } else {
            return minutos + "m";
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mis Tareas - Sistema Textil</title>

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

        /* ── ESTRUCTURA MAIN ── */
        .card { background: var(--color-surface); border-radius: var(--radius-md); padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border-color); margin-bottom: 24px; overflow-x: auto; }
        .card h3 { font-size: 1.1rem; color: var(--color-secondary); margin-bottom: 1rem; display:flex; align-items:center; gap:8px; }
        
        table { width: 100%; border-collapse: collapse; font-size: 0.85rem; white-space: nowrap; }
        th { background: #f8fafc; color: var(--text-muted); font-weight: 600; padding: 12px 16px; text-align: left; border-bottom: 2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem; }
        td { padding: 12px 16px; border-bottom: 1px solid var(--border-color); color: var(--text-main); vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #f8fafc; }
        .text-center { text-align: center; }

        .sin-datos { text-align: center; padding: 3rem; color: var(--text-muted); font-size: 0.95rem; display:flex; flex-direction:column; align-items:center; gap:10px; }
        .sin-datos i { font-size: 3rem; color: var(--border-color); }

        /* ── FILTROS Y BOTONES ── */
        .filtro-wrap { display: flex; flex-wrap: wrap; gap: 16px; align-items: flex-end; background: var(--color-bg); padding: 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 20px; }
        .filtro-wrap label { display:block; font-size: 0.75rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px;}
        .form-control { width: 100%; padding: 0.55rem 1rem; border: 1px solid var(--border-color); border-radius: var(--radius-sm); font-size: 0.85rem; color: var(--text-main); background: var(--color-surface); outline: none; transition: 0.2s; font-family: 'Inter', sans-serif;}
        .form-control:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1); }
        
        .btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.1rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.2s; text-decoration: none; }
        .btn-completar { background: #27ae60; color: #fff; padding: 0.45rem 0.9rem; border: none; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.8rem; font-weight: 600; transition: 0.2s; display:inline-flex; align-items:center; gap:5px; }
        .btn-completar:hover { background: #1e8449; }
        .btn-outline { background: var(--color-surface); color: var(--text-main); border: 1px solid var(--border-color); padding: 0.55rem 1rem; border-radius: var(--radius-sm); cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: 0.2s; display:inline-flex; align-items:center; gap:6px;}
        .btn-outline:hover { background: var(--color-bg); }
        .btn-primary { background: var(--color-primary); color: #fff; }
        .btn-primary:hover { background: var(--color-primary-hover); }

        /* ── MODALES (HOMOGENIZADO) ── */
        .overlay { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); z-index: 1000; justify-content: center; align-items: center; padding: 1rem; backdrop-filter: blur(3px); }
        .overlay.activo { display: flex; }
        .modal-flotante { background: var(--color-surface); border-radius: var(--radius-md); width: 100%; max-width: 500px; display: flex; flex-direction: column; box-shadow: 0 20px 40px rgba(0,0,0,0.15); overflow: hidden; }
        .modal-header { background: var(--color-secondary); padding: 1rem 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
        .modal-header h3 { color: var(--color-surface); font-size: 1.1rem; display:flex; align-items:center; gap:8px; font-weight:600;}
        .modal-close { background: none; border: none; color: var(--text-light); font-size: 1.5rem; cursor: pointer; transition: 0.2s; }
        .modal-close:hover { color: #fff; }
        .modal-body { padding: 1.5rem 2rem; overflow-y: auto; }
        .modal-footer { padding: 1rem 2rem; border-top: 1px solid var(--border-color); display: flex; gap: 12px; justify-content: flex-end; background: #f8fafc; }
        
        .modal-body label { display: block; font-size: 0.85rem; font-weight: 600; color: var(--text-main); margin-bottom: 6px; }
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
        <% if (_navFall) { %><a href="<%= _cp %>/fallas-tela" class="menu-link">Mapa de Fallas</a><% } %>
        <% if (_navMer)  { %><a href="<%= _cp %>/mermas" class="menu-link">Mermas</a><% } %>
        <% if (_navCarg) { %><a href="<%= _cp %>/cargas-trabajo" class="menu-link">Cargas de Trabajo</a><% } %>
        <% if (_isMaq && !_navCarg) { %><a href="<%= _cp %>/cargas-trabajo" class="menu-link activo">Mis Tareas</a><% } %>
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
        <h2><i class='bx bx-task'></i> Producción – Mis Tareas</h2>
        <div class="user-info">
            <span><%= usuarioSesion.getNombreCompleto() %></span>
            <span class="badge-rol"><%= usuarioSesion.getNombreRol() %></span>
            <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
        </div>
    </header>

    <div class="contenido">
        <% if (mensajeExito != null) { %>
            <div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= mensajeExito %></div>
        <% } %>
        <% if (mensajeError != null) { %>
            <div class="alerta alerta-err"><i class='bx bx-error-circle'></i> <%= mensajeError %></div>
        <% } %>

        <div class="card">
            <h3><i class='bx bx-time-five'></i> Tareas en proceso</h3>
            <% if (tareas.isEmpty()) { %>
                <div class="sin-datos">
                    <i class='bx bx-inbox'></i>
                    <span>No tienes tareas asignadas actualmente.</span>
                </div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th>OT</th>
                            <th>Pieza</th>
                            <th>Fase</th>
                            <th style="text-align:center;">Cantidad A Confeccionar</th>
                            <th>Fecha Asignación</th>
                            <th style="text-align:center;">Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (AsignacionCarga t : tareas) { %>
                            <tr>
                                <td style="font-family:monospace; font-weight:700; color:var(--color-primary);"><%= t.getCodigoOt() %></td>
                                <td>
                                    <% if (t.getNombrePieza() != null) { %>
                                        <%= t.getNombrePieza() %>
                                    <% } else { %>
                                        <span style="font-weight: 700; color: var(--color-primary);"><i class='bx bxs-t-shirt'></i> PRENDA COMPLETA</span>
                                    <% } %>
                                </td>
                                <td><span style="background:var(--color-bg); padding:4px 8px; border-radius:4px; font-size:0.75rem; font-weight:600;"><%= t.getNombreFase() %></span></td>
                                <td class="text-center" style="font-weight:600;"><%= t.getCantidadPiezas() %> und.</td>
                                <td><span style="color:var(--text-muted); font-size:0.8rem;"><%= t.getFechaAsignacion() != null ? sdf.format(t.getFechaAsignacion()) : "-" %></span></td>
                                <td class="text-center">
                                    <form method="post" action="<%= request.getContextPath() %>/cargas-trabajo" onsubmit="return completarTarea(event, this)">
                                      <input type="hidden" name="accion" value="completar">
                                      <input type="hidden" name="idAsignacion" value="<%= t.getIdAsignacion() %>">
                                      <input type="hidden" name="piezasCompletadas" id="piezas_<%= t.getIdAsignacion() %>" value="<%= t.getCantidadPiezas() %>">
                                      <button type="submit" class="btn-completar" onclick="return pedirCantidad(event, <%= t.getIdAsignacion() %>, <%= t.getCantidadPiezas() %>)"><i class='bx bx-check'></i> Completar</button>
                                    </form>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>
        
        <% if (tareasCompletadas != null && !tareasCompletadas.isEmpty()) { %>
        <div class="card">
            <h3><i class='bx bx-check-double'></i> Tareas completadas</h3>

            <div class="filtro-wrap">
                <div>
                    <label>Pieza</label>
                    <input type="text" id="filtroPieza" class="form-control" placeholder="Buscar por pieza" style="width: 180px;">
                </div>
                <div>
                    <label>Fecha desde</label>
                    <input type="date" id="filtroFechaDesde" class="form-control" style="width: 150px;">
                </div>
                <div>
                    <label>Fecha hasta</label>
                    <input type="date" id="filtroFechaHasta" class="form-control" style="width: 150px;">
                </div>
                <div>
                    <label>Fase</label>
                    <select id="filtroFase" class="form-control" style="width: 180px;">
                        <option value="">-- Todas --</option>
                    </select>
                </div>
                <div>
                    <button id="btnLimpiarFiltros" class="btn-outline"><i class='bx bx-eraser'></i> Limpiar filtros</button>
                </div>
            </div>

            <table id="tablaCompletadas">
                <thead>
                    <tr>
                        <th>Pieza</th>
                        <th class="text-center">Cantidad</th>
                        <th class="text-center">Completadas</th>
                        <th class="text-center">Faltante</th>
                        <th class="text-center">Fase</th>
                        <th class="text-center">Fecha Asignación</th>
                        <th class="text-center">Fecha Completado</th>
                        <th class="text-center">Duración</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (AsignacionCarga t : tareasCompletadas) { 
                        int completadas = t.getPiezasCompletadas();
                        int total = t.getCantidadPiezas();
                        int faltante = total - completadas;
                    %>
                    <tr>
                        <td style="font-weight:500;"><%= t.getNombrePieza() != null ? t.getNombrePieza() : "PRENDA COMPLETA" %></td>
                        <td class="text-center"><%= total %></td>
                        <td class="text-center" style="color:var(--success-text); font-weight:600;"><%= completadas %></td>
                        <td class="text-center"><%= faltante %></td>
                        <td class="text-center"><span style="background:var(--color-bg); padding:4px 8px; border-radius:4px; font-size:0.75rem; font-weight:600;"><%= t.getNombreFase() %></span></td>
                        <td class="text-center" style="color:var(--text-muted); font-size:0.8rem;"><%= t.getFechaAsignacion() != null ? sdf.format(t.getFechaAsignacion()) : "-" %></td>
                        <td class="text-center" style="color:var(--text-muted); font-size:0.8rem;"><%= t.getFechaCompletado() != null ? sdf.format(t.getFechaCompletado()) : "-" %></td>
                        <td class="text-center" style="font-weight:600;"><i class='bx bx-time-five' style="color:var(--color-primary);"></i> <%= calcularDuracion(t.getFechaAsignacion(), t.getFechaCompletado()) %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
        
    </div>
</main>

<%-- Modal Completar (modificado a la nueva estructura UI) --%>
<div class="overlay" id="modalCompletar">
    <div class="modal-flotante">
        <div class="modal-header">
            <h3 id="modalTitulo"><i class='bx bx-check-shield'></i> Completar Tarea</h3>
            <button type="button" class="modal-close" onclick="cerrarModal()">✕</button>
        </div>
        
        <form id="formCompletar" method="post" action="${pageContext.request.contextPath}/cargas-trabajo">
            <div class="modal-body">
                <p id="modalDescripcion" style="font-size:0.85rem; color:var(--text-muted); margin-bottom:1rem;"></p>
                <input type="hidden" name="accion" value="completar">
                <input type="hidden" name="idAsignacion" id="hiddenIdAsig">
                <input type="hidden" name="cierreManual" id="hiddenCierreManual" value="">

                <label>Cantidad completada:</label>
                <input type="number" name="piezasCompletadas" id="inputCantidad" min="1" required class="form-control" style="font-size: 1.1rem; padding:0.6rem;">
                <p id="metaInfo" style="font-size:0.78rem; color:var(--text-muted); margin-top:4px;"></p>

                <%-- Sección de cierre manual — solo visible para supervisor/admin en ENSAMBLAJE --%>
                <div id="seccionCierreManual" style="display:none; margin-top:1.5rem; background:var(--warning-bg); border:1px solid #fcd34d; padding:12px; border-radius:var(--radius-sm);">
                    <p style="font-size:0.85rem; color:var(--warning-text); font-weight:600; display:flex; align-items:center; gap:6px;">
                        <i class='bx bx-error'></i> La cantidad ingresada es menor a la meta.
                    </p>
                    <p style="font-size:0.8rem; color:#b45309; margin-top:0.4rem; line-height:1.4;">
                        Normalmente el sistema generará una tarea de reposición. Si deseas cerrar la OT con esta cantidad como producción final, activa el cierre manual:
                    </p>
                    <label style="display:flex; align-items:center; gap:8px; margin-top:10px; cursor:pointer;">
                        <input type="checkbox" id="chkCierreManual" style="width:16px; height:16px; accent-color:var(--warning-text);" onchange="document.getElementById('hiddenCierreManual').value = this.checked ? 'SI' : ''">
                        <span style="font-size:0.85rem; font-weight:600; color:var(--warning-text);">
                            Autorizar cierre manual con ${cantidad} prendas (solo supervisor)
                        </span>
                    </label>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" onclick="cerrarModal()" class="btn btn-outline"><i class='bx bx-x'></i> Cancelar</button>
                <button type="submit" class="btn btn-primary"><i class='bx bx-check'></i> Confirmar</button>
            </div>
        </form>
    </div>
</div>

<script>
    // UI MENÚ ACORDEÓN
    function toggleSubmenu(element) {
      element.parentElement.classList.toggle('active');
    }

    // ─── LÓGICA JAVASCRIPT INTACTA ──────────────────────────
    function pedirCantidad(event, idAsignacion, cantidadTotal) {
        event.preventDefault();
        var completadas = prompt("¿Cuántas piezas completó correctamente? (Máximo " + cantidadTotal + ")", cantidadTotal);
        if (completadas === null) return false;
        completadas = parseInt(completadas);
        if (isNaN(completadas) || completadas < 0 || completadas > cantidadTotal) {
            alert("Cantidad inválida. Debe ser entre 0 y " + cantidadTotal);
            return false;
        }
        document.getElementById('piezas_' + idAsignacion).value = completadas;
        event.target.closest('form').submit();
        return false;
    }

    function poblarFiltroFase() {
        const fasesSet = new Set();
        document.querySelectorAll('#tablaCompletadas tbody tr').forEach(row => {
            const fase = row.cells[4]?.innerText.trim();
            if (fase) fasesSet.add(fase);
        });
        const select = document.getElementById('filtroFase');
        select.innerHTML = '<option value="">-- Todas --</option>';
        Array.from(fasesSet).sort().forEach(f => {
            const opt = document.createElement('option');
            opt.value = f;
            opt.textContent = f;
            select.appendChild(opt);
        });
    }

    function aplicarFiltrosCompletadas() {
        const filtroPieza = document.getElementById('filtroPieza').value.trim().toLowerCase();
        const filtroFechaDesde = document.getElementById('filtroFechaDesde').value;
        const filtroFechaHasta = document.getElementById('filtroFechaHasta').value;
        const filtroFase = document.getElementById('filtroFase').value;
        
        const rows = document.querySelectorAll('#tablaCompletadas tbody tr');
        let visibles = 0;
        rows.forEach(row => {
            const pieza = row.cells[0]?.innerText.trim().toLowerCase() || '';
            const fase = row.cells[4]?.innerText.trim() || '';
            const fechaAsignacionStr = row.cells[5]?.innerText.trim() || '';
            const fechaCompletadoStr = row.cells[6]?.innerText.trim() || '';
            
            let visible = true;
            
            if (filtroPieza && !pieza.includes(filtroPieza)) visible = false;
            if (filtroFase && fase !== filtroFase) visible = false;
            
            if (filtroFechaDesde || filtroFechaHasta) {
                let fechaCompletado = null;
                if (fechaCompletadoStr && fechaCompletadoStr !== '-') {
                    let partes = fechaCompletadoStr.split(' ');
                    let fechaParte = partes[0].split('/');
                    if (fechaParte.length === 3) {
                        fechaCompletado = new Date(fechaParte[2], fechaParte[1]-1, fechaParte[0]);
                    }
                }
                if (filtroFechaDesde && fechaCompletado) {
                    let desde = new Date(filtroFechaDesde);
                    if (fechaCompletado < desde) visible = false;
                }
                if (filtroFechaHasta && fechaCompletado && visible) {
                    let hasta = new Date(filtroFechaHasta);
                    if (fechaCompletado > hasta) visible = false;
                }
            }
            row.style.display = visible ? '' : 'none';
            if (visible) visibles++;
        });
    }

    function limpiarFiltrosCompletadas() {
        document.getElementById('filtroPieza').value = '';
        document.getElementById('filtroFechaDesde').value = '';
        document.getElementById('filtroFechaHasta').value = '';
        document.getElementById('filtroFase').value = '';
        aplicarFiltrosCompletadas();
    }

    document.addEventListener('DOMContentLoaded', () => {
        if(document.getElementById('tablaCompletadas')){
            poblarFiltroFase();
            aplicarFiltrosCompletadas();
            
            document.getElementById('filtroPieza').addEventListener('keyup', aplicarFiltrosCompletadas);
            document.getElementById('filtroFechaDesde').addEventListener('change', aplicarFiltrosCompletadas);
            document.getElementById('filtroFechaHasta').addEventListener('change', aplicarFiltrosCompletadas);
            document.getElementById('filtroFase').addEventListener('change', aplicarFiltrosCompletadas);
            document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltrosCompletadas);
        }
    });

    function abrirModalCompletar(idAsig, meta, tipoTarea, rolUsuario) {
        document.getElementById('hiddenIdAsig').value = idAsig;
        document.getElementById('hiddenCierreManual').value = '';
        document.getElementById('chkCierreManual').checked = false;
        document.getElementById('inputCantidad').max = meta;
        document.getElementById('metaInfo').textContent = 'Meta: ' + meta + ' unidades.';
        
        let esEnsamblaje = (tipoTarea === 'ENSAMBLAJE');
        let esSupervisor = (rolUsuario === 5 || rolUsuario === 1);

        document.getElementById('modalTitulo').innerHTML =
            esEnsamblaje ? "<i class='bx bx-check-shield'></i> Completar Ensamblaje Final" : "<i class='bx bx-check-shield'></i> Completar Tarea";

        document.getElementById('inputCantidad').oninput = function() {
            let val = parseInt(this.value) || 0;
            let mostrar = esEnsamblaje && esSupervisor && val < meta && val > 0;
            document.getElementById('seccionCierreManual').style.display = mostrar ? 'block' : 'none';
            if (!mostrar) {
                document.getElementById('hiddenCierreManual').value = '';
                document.getElementById('chkCierreManual').checked = false;
            }
        };

        // Cambio visual de la clase para mostrar el nuevo modal
        document.getElementById('modalCompletar').classList.add('activo');
    }

    function cerrarModal() {
        document.getElementById('modalCompletar').classList.remove('activo');
    }
</script>
</body>
</html>