<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="modelo.*, java.util.*, java.math.BigDecimal" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean esAdmin       = "ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean esTizador     = "TIZADOR".equalsIgnoreCase(usuarioSesion.getNombreRol());
    boolean puedeVer      = permisos.contains("PROD_MERMA_VER") || esAdmin;
    boolean puedeReg      = request.getAttribute("puedeRegistrar") != null
                             && (Boolean) request.getAttribute("puedeRegistrar");
    boolean verSeguridad  = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacen    = permisos.contains("ALM_TELA_VER");
    boolean verProduccion = permisos.contains("PROD_OT_VER");
    boolean verReposo     = permisos.contains("PROD_REPOSO_VER") || esAdmin;
    boolean verFallas     = permisos.contains("PROD_FALLAS_VER") || esAdmin;
    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    @SuppressWarnings("unchecked") List<Merma>        mermasList    = (List<Merma>)        request.getAttribute("mermasList");
    @SuppressWarnings("unchecked") List<Tela>         telasParaMerma= (List<Tela>)         request.getAttribute("telasParaMerma");
    @SuppressWarnings("unchecked") List<OrdenTrabajo> otsConMermas  = (List<OrdenTrabajo>) request.getAttribute("otsConMermas");
    BigDecimal pctOtActivo = (BigDecimal) request.getAttribute("pctOtActivo");
    if (mermasList    == null) mermasList    = new ArrayList<>();
    if (telasParaMerma== null) telasParaMerma= new ArrayList<>();
    if (otsConMermas  == null) otsConMermas  = new ArrayList<>();

    String exito     = request.getParameter("exito");
    String error     = request.getParameter("error");
    String idOtFilt  = request.getParameter("idOt");
    String errorBD   = (String) request.getAttribute("errorBD");
    // Totales para resumen
    BigDecimal totalUtilizado = BigDecimal.ZERO;
    BigDecimal totalMerma     = BigDecimal.ZERO;
    for (Merma m : mermasList) {
        if (m.getPesoUtilizadoKg() != null) totalUtilizado = totalUtilizado.add(m.getPesoUtilizadoKg());
        if (m.getPesomermaKg()     != null) totalMerma     = totalMerma.add(m.getPesomermaKg());
    }
    BigDecimal pctTotal = BigDecimal.ZERO;
    if (totalUtilizado.compareTo(BigDecimal.ZERO) > 0) {
        pctTotal = totalMerma.divide(totalUtilizado, 3, java.math.RoundingMode.HALF_UP)
                             .multiply(new BigDecimal("100"))
                             .setScale(2, java.math.RoundingMode.HALF_UP);
    }
    long cntTizado = mermasList.stream().filter(m -> m.getFase() == Merma.Fase.TIZADO).count();
    long cntCorte  = mermasList.stream().filter(m -> m.getFase() == Merma.Fase.CORTE).count();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mermas – Sistema Textil</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
  <style>
    /* ── SISTEMA DE DISEÑO HOMOGENEIZADO ── */
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
        --warning-bg: #fef3c7; 
        --warning-text: #92400e;
        --info-bg: #e0f2fe; 
        --info-text: #0369a1;
        --radius-sm: 6px; 
        --radius-md: 8px;
        --radius-lg: 12px;
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Inter', sans-serif;background:var(--color-bg);display:flex;min-height:100vh;color:var(--text-main);}

    /* ── SIDEBAR CON MENÚ ACORDEÓN (Standard) ── */
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

    main{flex:1;display:flex;flex-direction:column;overflow:hidden}
    header { background: var(--color-surface); padding: 0.9rem 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.02); z-index: 10;}
    header h2{font-size:1.15rem; color: var(--color-secondary); font-weight: 600; display:flex; align-items:center; gap:8px;}
    .user-info{display:flex;align-items:center;gap:.75rem;font-size:.85rem;font-weight: 500;}
    .badge{background:#e2e8f0;color:var(--text-main);padding:.25rem .6rem;border-radius:var(--radius-sm);font-size:.75rem;font-weight:600}
    .btn-salir{padding: 0.35rem 0.8rem; border: 1px solid var(--danger-hover); color: var(--danger-hover); border-radius: var(--radius-sm); font-size: 0.8rem; font-weight: 600; text-decoration: none; display:flex; align-items:center; gap:5px; transition:0.2s;}
    .btn-salir:hover{background:var(--danger-hover);color:#fff}
    .contenido{flex:1;padding:24px;overflow-y:auto}

    .alerta{padding:12px 16px;border-radius:var(--radius-md);margin-bottom:24px;font-size:.85rem; font-weight: 500;}
    .alerta-ok {background:var(--success-bg);color:var(--success-text);border:1px solid #a7f3d0}
    .alerta-err{background:var(--danger-bg);color:var(--danger-text);border:1px solid #fecaca}

    .barra-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:16px}
    .barra-top h3{font-size:1.15rem;color:var(--color-secondary); font-weight: 600;}
    .btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;padding:0.55rem 1.1rem;border:none;border-radius:var(--radius-sm);cursor:pointer;font-size:.85rem;font-weight:600;text-decoration:none;transition:all .2s;}
    .btn:hover{opacity:.85}
    .btn-primary{background:var(--color-primary);color:#fff}
    .btn-danger {background:var(--danger-hover);color:#fff}
    .btn-sm{padding:.3rem .75rem;font-size:.78rem}
    .btn-outline{background:var(--color-surface);border:1px solid var(--border-color);color:var(--text-main)}

    /* Resumen */
    .resumen-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:16px;margin-bottom:24px}
    .card-res{background:var(--color-surface);border-radius:var(--radius-md);padding:1.2rem;box-shadow:0 2px 8px rgba(0,0,0,.04);border: 1px solid var(--border-color);text-align:center}
    .card-res .num{font-size:2rem;font-weight:700;line-height:1;color:var(--text-main);}
    .card-res .lbl{font-size:.75rem;color:var(--text-muted);margin-top:6px;text-transform: uppercase;font-weight: 600;}
    .c-util  .num{color:var(--color-primary)}
    .c-merma .num{color:var(--danger-text)}
    .c-pct   .num{font-size:1.6rem}
    .c-pct.nivel-baja  .num{color:var(--success-text)}
    .c-pct.nivel-media .num{color:var(--warning-text)}
    .c-pct.nivel-alta  .num{color:var(--danger-text)}
    .c-tizado .num{color:#8e44ad}
    .c-corte  .num{color:#0369a1}

    /* Banner OT activa */
    .banner-ot{background:var(--color-surface);border-radius:var(--radius-md);padding:1rem 1.3rem; margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,.04);border: 1px solid var(--border-color); display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px}
    .banner-ot .ot-info{font-size:.88rem;color:var(--text-main); font-weight: 500;}
    .banner-ot .ot-pct{font-size:1.4rem;font-weight:700}
    .pct-baja {color:var(--success-text)}
    .pct-media{color:var(--warning-text)}
    .pct-alta {color:var(--danger-text)}
    .btn-editar   { background: var(--warning-bg); color: var(--warning-text); border: 1px solid #fcd34d;} 
    .btn-editar:hover { background: #fde68a; }

    /* Filtro */
    .filtro-wrap{background:var(--color-surface);border-radius:var(--radius-md);padding:16px; margin-bottom:24px;box-shadow:0 2px 8px rgba(0,0,0,.04);border: 1px solid var(--border-color); display:flex;align-items:center;gap:16px;flex-wrap:wrap}
    .filtro-wrap label{font-size:.82rem;font-weight:600;color:var(--text-main)}
    .filtro-wrap select, .filtro-wrap input {padding:0.55rem 1rem;border:1px solid var(--border-color);border-radius:var(--radius-sm);font-size:.85rem; outline: none; transition: 0.2s;}
    .filtro-wrap select:focus, .filtro-wrap input:focus{border-color:var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1);}

    /* Tabla */
    .tabla-wrap{background:var(--color-surface);border-radius:var(--radius-md);box-shadow:0 2px 8px rgba(0,0,0,.04);border: 1px solid var(--border-color);overflow-x:auto}
    .tabla-header{padding:16px;border-bottom:1px solid var(--border-color);display:flex;justify-content:space-between;align-items:center}
    .tabla-header h4{font-size:.95rem;color:var(--color-secondary); font-weight: 600;}
    table{width:100%;border-collapse:collapse;font-size:.85rem; white-space: nowrap;}
    th{padding:12px 16px;text-align:left;background:#f8fafc;color:var(--text-muted);font-weight:600;border-bottom:2px solid var(--border-color); text-transform: uppercase; font-size: 0.72rem;}
    td{padding:12px 16px;border-bottom:1px solid var(--border-color);color:var(--text-main);vertical-align:middle}
    tr:last-child td { border-bottom: none; }
    tr:hover td{background:#f8fafc}
    .text-center{text-align:center}
    .empty{text-align:center;padding:48px;color:var(--text-muted);font-size:.9rem}

    .badge-fase{display:inline-block;padding:.35rem .8rem;border-radius:6px;font-size:.72rem;font-weight:700; text-transform: uppercase;}
    .fase-tizado{background:#f3e8ff;color:#6b21a8}
    .fase-corte {background:#e0f2fe;color:#0369a1}
    .badge-nivel{display:inline-block;padding:.35rem .8rem;border-radius:6px;font-size:.72rem;font-weight:700; text-transform: uppercase;}
    .nivel-baja {background:var(--success-bg);color:var(--success-text)}
    .nivel-media{background:var(--warning-bg);color:var(--warning-text)}
    .nivel-alta {background:var(--danger-bg);color:var(--danger-text)}

    /* Modal */
    .overlay{display:none;position:fixed;inset:0;background:rgba(15, 23, 42, 0.5);z-index:1000;align-items:center;justify-content:center; backdrop-filter: blur(3px); padding: 1rem;}
    .overlay.activo{display:flex}
    .modal{background:var(--color-surface);border-radius:var(--radius-md);width:100%;max-width:540px;max-height:92vh;display:flex; flex-direction:column; box-shadow:0 20px 40px rgba(0,0,0,.15); overflow:hidden;}
    .modal-header{padding:1rem 1.5rem;background:var(--color-secondary);display:flex;justify-content:space-between;align-items:center;flex-shrink:0;}
    .modal-header h3{font-size:1.1rem;color:var(--color-surface); font-weight: 600;}
    .modal-body{padding:1.5rem 2rem; overflow-y: auto; flex: 1;}
    .modal-footer{padding:1rem 2rem;border-top:1px solid var(--border-color);display:flex;justify-content:flex-end;gap:12px;background:#f8fafc;flex-shrink:0;}
    .btn-cerrar{background:none;border:none;font-size:1.5rem;cursor:pointer;color:var(--text-light); transition: 0.2s;}
    .btn-cerrar:hover {color: #fff;}

    .form-group{margin-bottom:1rem}
    .form-group label{display:block;font-size:.82rem;font-weight:600;color:var(--text-main);margin-bottom:4px}
    .form-control{width:100%;padding:0.55rem 1rem;border:1px solid var(--border-color);border-radius:var(--radius-sm);font-size:.85rem;transition:0.2s; background:var(--color-surface); font-family: 'Inter', sans-serif;}
    .form-control:focus{outline:none;border-color:var(--color-primary); box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1);}
    .form-hint{font-size:.75rem;color:var(--text-muted);margin-top:4px}
    .form-row{display:grid;grid-template-columns:1fr 1fr;gap:1rem}

    /* Preview % en tiempo real */
    .pct-preview{background:var(--color-bg);border-radius:var(--radius-sm);padding:10px 16px;margin-top:8px;font-size:.85rem;font-weight:600;text-align:center;display:none; border: 1px solid var(--border-color);}
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
  </nav>
</aside>

<main>
  <header>
    <h2><i class='bx bx-trending-down'></i> Registro de Mermas por Tejido</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir"><i class='bx bx-log-out'></i> Salir</a>
    </div>
  </header>

  <div class="contenido">

    <%
      String msgOk = null;
      if ("registrado".equals(exito))  msgOk = "Merma registrada. El porcentaje ha sido calculado automáticamente.";
      else if ("eliminado".equals(exito)) msgOk = "Registro de merma eliminado.";
      String msgErr = null;
      if ("mermaExcede".equals(error)) msgErr = "El peso de merma no puede ser mayor al peso utilizado.";
      else if (error != null && !error.isEmpty()) msgErr = "Error al procesar la solicitud (código: " + error + ").";
    %>
    <% if (msgOk != null)  { %><div class="alerta alerta-ok"><i class='bx bx-check-circle'></i> <%= msgOk %></div><% } %>
    <% if (msgErr != null) { %><div class="alerta alerta-err"><i class='bx bx-error-circle'></i> <%= msgErr %></div><% } %>
    <% if (errorBD != null){ %><div class="alerta alerta-err"><i class='bx bx-error'></i> <%= errorBD %></div><% } %>

    <div class="barra-top">
      <h3>Historial de Mermas <%= esAdmin ? "(Vista Admin – todos los usuarios)" : "" %></h3>
      <% if (puedeReg) { %>
      <button class="btn btn-primary" onclick="abrirModal('overlay-reg')"><i class='bx bx-plus'></i> Registrar Merma</button>
      <% } %>
    </div>

    <div class="resumen-grid">
      <div class="card-res c-util">
        <div class="num"><%= totalUtilizado.setScale(2, java.math.RoundingMode.HALF_UP) %></div>
        <div class="lbl">Kg Utilizados (total)</div>
      </div>
      <div class="card-res c-merma">
        <div class="num"><%= totalMerma.setScale(2, java.math.RoundingMode.HALF_UP) %></div>
        <div class="lbl">Kg de Merma (total)</div>
      </div>
      <%
        String nivelCss = pctTotal.doubleValue() <= 5 ? "nivel-baja" : pctTotal.doubleValue() <= 10 ? "nivel-media" : "nivel-alta";
      %>
      <div class="card-res c-pct <%= nivelCss %>">
        <div class="num"><%= pctTotal %>%</div>
        <div class="lbl">% Merma promedio</div>
      </div>
      <div class="card-res c-tizado">
        <div class="num"><%= cntTizado %></div>
        <div class="lbl">Registros Tizado</div>
      </div>
      <div class="card-res c-corte">
        <div class="num"><%= cntCorte %></div>
        <div class="lbl">Registros Corte</div>
      </div>
    </div>

    <% if (pctOtActivo != null && idOtFilt != null) {
        String pctCss = pctOtActivo.doubleValue() <= 5 ? "pct-baja" : pctOtActivo.doubleValue() <= 10 ? "pct-media" : "pct-alta";
    %>
    <div class="banner-ot">
      <div class="ot-info">
        <i class='bx bx-spreadsheet'></i> Porcentaje total de merma para la OT seleccionada
        <small style="color:var(--text-muted)">(CUS 4.2 – CA1 HU04)</small>
      </div>
      <div class="ot-pct <%= pctCss %>"><%= pctOtActivo %>%</div>
    </div>
    <% } %>

    <div class="filtro-wrap">
      <label>Filtrar por OT:</label>
      <select id="selFiltroOt" onchange="filtrarPorOt(this.value)">
        <option value="">-- Todas las OT --</option>
        <% for (OrdenTrabajo ot : otsConMermas) { %>
        <option value="<%= ot.getIdOt() %>" <%= String.valueOf(ot.getIdOt()).equals(idOtFilt) ? "selected" : "" %>>
          <%= ot.getCodigoOt() %> | <%= ot.getCliente() %>
        </option>
        <% } %>
      </select>
      <% if (idOtFilt != null && !idOtFilt.isEmpty()) { %>
      <a href="<%= request.getContextPath() %>/mermas" class="btn btn-sm btn-outline"><i class='bx bx-x'></i> Quitar filtro</a>
      <% } %>
    </div>

    <div class="filtro-wrap" style="padding-bottom: 12px;">
      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <label>Tela:</label>
        <input type="text" id="filtroTela" class="form-control" placeholder="Código tela" style="width: 130px;">
      </div>

      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <label>Tejido:</label>
        <input type="text" id="filtroTejido" class="form-control" placeholder="Tipo tejido" style="width: 150px;">
      </div>

      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <label>Fase:</label>
        <select id="filtroFase" class="form-control" style="width: auto; min-width: 110px;">
          <option value="">-- Todas --</option>
          <option value="Tizado">Tizado</option>
          <option value="Corte">Corte</option>
        </select>
      </div>

      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <label>Fecha desde:</label>
        <input type="date" id="filtroFechaDesde" class="form-control" style="width: 130px;">
      </div>
      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <label>Fecha hasta:</label>
        <input type="date" id="filtroFechaHasta" class="form-control" style="width: 130px;">
      </div>

      <button id="btnLimpiarFiltros" class="btn btn-outline btn-sm">
        <i class='bx bx-eraser'></i> Limpiar
      </button>
    </div>

    <div class="tabla-wrap">
      <div class="tabla-header">
        <h4><i class='bx bx-list-ul'></i> Registros Detallados</h4>
        <span style="font-size:.8rem;color:var(--text-muted); font-weight: 500;" id="contadorMermas"><%= mermasList.size() %> registro(s)</span>
      </div>
      <% if (mermasList.isEmpty()) { %>
      <div class="empty">
        <i class='bx bx-box' style="font-size: 3rem; color: var(--border-color); display:block; margin-bottom:12px;"></i>
        No hay mermas registradas aún.
        <% if (puedeReg) { %><br><button class="btn btn-primary" style="margin-top:1rem;" onclick="abrirModal('overlay-reg')"><i class='bx bx-plus'></i> Registrar primera merma</button><% } %>
      </div>
      <% } else { %>
        <table id="tablaMermas">
          <thead>
            <tr>
              <th class="text-center">#</th>
              <th>Tela</th>
              <th>OT</th>
              <th>Cliente</th>
              <th>Tejido</th>
              <th>Fase</th>
              <th class="text-center">Kg Utiliz.</th>
              <th class="text-center">Kg Merma</th>
              <th class="text-center">% Merma</th>
              <th>Nivel</th>
              <th>Registrado por</th>
              <th>Fecha</th>
              <% if (esAdmin) { %><th class="text-center">Acción</th><% } %>
            </tr>
          </thead>
          <tbody>
            <% for (Merma m : mermasList) {
                String faseCss   = m.getFase() == Merma.Fase.TIZADO ? "fase-tizado" : "fase-corte";
                String faseLabel = m.getFase() == Merma.Fase.TIZADO ? "Tizado" : "Corte";
                String nivelLabel = m.getNivelMerma();
                String nivelBadge = "nivel-" + nivelLabel.toLowerCase();
            %>
            <tr>
              <td class="text-center" style="color:var(--text-muted);"><%= m.getIdMerma() %></td>
              <td style="font-family:monospace; font-weight:700; color:var(--color-primary); font-size:0.95rem;"><%= m.getCodigoTela() %></td>
              <td><span style="font-family:monospace; font-size:.85rem; font-weight:600;"><%= m.getCodigoOt() %></span></td>
              <td><%= m.getCliente() %></td>
              <td><%= m.getTipoTejido() != null ? m.getTipoTejido() : "—" %></td>
              <td><span class="badge-fase <%= faseCss %>"><%= faseLabel %></span></td>
              <td class="text-center"><%= m.getPesoUtilizadoKg() %> kg</td>
              <td class="text-center"><%= m.getPesomermaKg() %> kg</td>
              <td class="text-center"><strong><%= m.getPorcentajeMerma() %>%</strong></td>
              <td><span class="badge-nivel <%= nivelBadge %>"><%= nivelLabel %></span></td>
              <td style="font-size:.8rem;"><%= m.getNombreTizador() %></td>
              <td style="font-size:.78rem; color:var(--text-muted);"><%= m.getFechaRegistro() != null
                      ? new java.text.SimpleDateFormat("dd/MM/yy HH:mm").format(m.getFechaRegistro()) : "—" %></td>
              <% if (esAdmin) { %>
              <td class="text-center">
                <button type="button" class="btn btn-editar btn-sm" 
                onclick="abrirModalEditar(
                  '<%= m.getIdMerma() %>',
                  '<%= m.getCodigoTela() %>',
                  '<%= m.getIdTela() %>',
                  '<%= m.getFase().name() %>',
                  '<%= m.getPesoUtilizadoKg() != null ? m.getPesoUtilizadoKg() : "0" %>',
                  '<%= m.getPesomermaKg() != null ? m.getPesomermaKg() : "0" %>',
                  '<%= m.getObservaciones() != null ? m.getObservaciones().replace("'", "\\x27") : "" %>'
                )"><i class='bx bx-edit-alt'></i></button>
                <form method="post" action="<%= request.getContextPath() %>/mermas" style="display:inline" onsubmit="return confirm('¿Eliminar este registro de merma?')">
                  <input type="hidden" name="accion"   value="eliminar">
                  <input type="hidden" name="idMerma"  value="<%= m.getIdMerma() %>">
                  <button type="submit" class="btn btn-danger btn-sm"><i class='bx bx-trash'></i></button>
                </form>
              </td>
              <% } %>
            </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </div>

  </div></main>

<div class="overlay" id="overlay-reg">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-plus-circle'></i> Registrar Merma por Tejido</h3>
      <button class="btn-cerrar" onclick="cerrarModal('overlay-reg')">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/mermas" onsubmit="return validarMerma()">
      <input type="hidden" name="accion" value="registrar">
      <input type="hidden" name="idOt"   id="idOtHidden" value="">
      <div class="modal-body">

        <div class="form-group">
          <label for="idTela">Tela *</label>
          <select name="idTela" id="idTela" class="form-control" onchange="cargarDatosTela(this)" required>
            <option value="">-- Selecciona una tela --</option>
            <% for (Tela t : telasParaMerma) { %>
            <option value="<%= t.getIdTela() %>"
                    data-ot="<%= t.getIdOt() %>"
                    data-codigo-ot="<%= t.getCodigoOt() %>"
                    data-peso="<%= t.getPesoReal() %>"
                    data-tejido="<%= t.getTipoTejido() != null ? t.getTipoTejido() : "" %>">
              <%= t.getCodigoTela() %> <%= t.getCodigoOt() != null ? " | OT: " + t.getCodigoOt() : "" %> <%= t.getTipoTejido() != null ? " | " + t.getTipoTejido() : "" %>
            </option>
            <% } %>
          </select>
          <p class="form-hint" id="hintTela">Peso real disponible: —</p>
          <% if (telasParaMerma.isEmpty()) { %>
          <p class="form-hint" style="color:var(--danger-hover)">No hay telas disponibles.</p>
          <% } %>
        </div>

        <div class="form-group">
          <label for="fase">Fase de Generación *</label>
          <select name="fase" id="fase" class="form-control" required>
            <option value="TIZADO">Tizado</option>
            <option value="CORTE">Corte</option>
          </select>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="pesoUtilizadoKg">Peso Utilizado (kg) *</label>
            <input type="number" name="pesoUtilizadoKg" id="pesoUtilizadoKg" class="form-control" min="0.001" step="0.001" placeholder="Ej: 10.500" oninput="calcularPreviaPct()" required>
          </div>
          <div class="form-group">
            <label for="pesomermaKg">Peso de Merma (kg) *</label>
            <input type="number" name="pesomermaKg" id="pesomermaKg" class="form-control" min="0" step="0.001" placeholder="Ej: 0.850" oninput="calcularPreviaPct()" required>
          </div>
        </div>

        <div class="pct-preview" id="pctPreview">
          <i class='bx bx-pie-chart-alt-2'></i> Porcentaje estimado de merma: <span id="pctVal">0</span>%
        </div>

        <div class="form-group" style="margin-top:.8rem">
          <label for="observaciones">Observaciones</label>
          <textarea name="observaciones" id="observaciones" class="form-control" rows="3" placeholder="Ej: Merma por defecto de borde en fase de tizado..."></textarea>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal('overlay-reg')"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Registrar Merma</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="overlay-editar">
  <div class="modal">
    <div class="modal-header">
      <h3><i class='bx bx-edit'></i> Editar Registro de Merma</h3>
      <button class="btn-cerrar" onclick="cerrarModal('overlay-editar')">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/mermas" onsubmit="return validarEdicion()">
      <input type="hidden" name="accion" value="actualizar">
      <input type="hidden" name="idMerma" id="edit_idMerma">
      <div class="modal-body">

        <div class="form-group">
          <label>Tela</label>
          <input type="text" id="edit_codigoTela" class="form-control" style="background:var(--color-bg);" readonly disabled>
          <input type="hidden" name="idTela" id="edit_idTela">
        </div>

        <div class="form-group">
          <label for="edit_fase">Fase de Generación *</label>
          <select name="fase" id="edit_fase" class="form-control" required>
            <option value="TIZADO">Tizado</option>
            <option value="CORTE">Corte</option>
          </select>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="edit_pesoUtilizado">Peso Utilizado (kg) *</label>
            <input type="number" name="pesoUtilizadoKg" id="edit_pesoUtilizado" class="form-control" step="0.001" min="0.001" oninput="calcularPreviewEdicion()" required>
          </div>
          <div class="form-group">
            <label for="edit_pesoMerma">Peso de Merma (kg) *</label>
            <input type="number" name="pesomermaKg" id="edit_pesoMerma" class="form-control" step="0.001" min="0" oninput="calcularPreviewEdicion()" required>
          </div>
        </div>

        <div class="pct-preview" id="editPctPreview" style="display:none;">
          <i class='bx bx-pie-chart-alt-2'></i> Porcentaje estimado de merma: <span id="editPctVal">0</span>%
        </div>

        <div class="form-group" style="margin-top:.8rem">
          <label for="edit_observaciones">Observaciones</label>
          <textarea name="observaciones" id="edit_observaciones" class="form-control" rows="3"></textarea>
        </div>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="cerrarModal('overlay-editar')"><i class='bx bx-x'></i> Cancelar</button>
        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Guardar Cambios</button>
      </div>
    </form>
  </div>
</div>

<script>
  // ── LÓGICA DE MENÚ ACORDEÓN (HOMOGENEIZADO) ──
  document.addEventListener("DOMContentLoaded", function() {
      const currentPath = window.location.pathname;
      const menuLinks = document.querySelectorAll('.sidebar-nav .menu-link');
      
      menuLinks.forEach(link => {
          link.classList.remove('activo'); 
          if (link.getAttribute('href') === currentPath) {
              link.classList.add('activo');
              const parentGroup = link.closest('.menu-group');
              if (parentGroup) parentGroup.classList.add('active');
          }
      });
  });

  function toggleSubmenu(element) {
      element.parentElement.classList.toggle('active');
  }

  // ── LÓGICA ORIGINAL DE MODALES ──
  function abrirModal(id)  { document.getElementById(id).classList.add('activo'); }
  function cerrarModal(id) { document.getElementById(id).classList.remove('activo'); }
  document.querySelectorAll('.overlay').forEach(function(ov){
    ov.addEventListener('click', function(e){ if(e.target===ov) cerrarModal(ov.id); });
  });

  function cargarDatosTela(sel) {
    var opt = sel.options[sel.selectedIndex];
    var idOt   = opt.getAttribute('data-ot')   || '';
    var peso   = opt.getAttribute('data-peso')  || '—';
    var tejido = opt.getAttribute('data-tejido')|| '';
    document.getElementById('idOtHidden').value = idOt;
    document.getElementById('hintTela').textContent = 'Peso real de la tela: ' + peso + ' kg' + (tejido ? ' | Tejido: ' + tejido : '');
    calcularPreviaPct();
  }

  function calcularPreviaPct() {
    var util  = parseFloat(document.getElementById('pesoUtilizadoKg').value) || 0;
    var merma = parseFloat(document.getElementById('pesomermaKg').value)      || 0;
    var preview = document.getElementById('pctPreview');
    var pctVal  = document.getElementById('pctVal');
    if (util > 0) {
      var pct = ((merma / util) * 100).toFixed(3);
      pctVal.textContent = pct;
      preview.style.display = 'block';
      preview.style.background = pct <= 5 ? 'var(--success-bg)' : pct <= 10 ? 'var(--warning-bg)' : 'var(--danger-bg)';
      preview.style.color      = pct <= 5 ? 'var(--success-text)' : pct <= 10 ? 'var(--warning-text)' : 'var(--danger-text)';
      preview.style.borderColor = pct <= 5 ? '#a7f3d0' : pct <= 10 ? '#fde68a' : '#fecaca';
    } else {
      preview.style.display = 'none';
    }
  }

  function validarMerma() {
    var tela  = document.getElementById('idTela').value;
    var util  = parseFloat(document.getElementById('pesoUtilizadoKg').value);
    var merma = parseFloat(document.getElementById('pesomermaKg').value);
    if (!tela) { alert('Selecciona una tela.'); return false; }
    if (!util || util <= 0) { alert('El peso utilizado debe ser mayor a 0.'); return false; }
    if (isNaN(merma) || merma < 0) { alert('El peso de merma no puede ser negativo.'); return false; }
    if (merma > util) { alert('El peso de merma no puede superar el peso utilizado.'); return false; }
    return true;
  }

  function filtrarPorOt(val) {
    var base = '<%= request.getContextPath() %>/mermas';
    window.location = val ? base + '?accion=porOt&idOt=' + val : base;
  }

  // ── FILTROS PARA EL HISTORIAL DE MERMAS (CLIENTE) ──
  function aplicarFiltrosMermas() {
      var tela = document.getElementById('filtroTela').value.trim().toLowerCase();
      var tejido = document.getElementById('filtroTejido').value.trim().toLowerCase();
      var fase = document.getElementById('filtroFase').value;
      var fechaDesde = document.getElementById('filtroFechaDesde').value;
      var fechaHasta = document.getElementById('filtroFechaHasta').value;
      var rows = document.querySelectorAll('#tablaMermas tbody tr');
      var visibles = 0;

      rows.forEach(function(row) {
          var mostrar = true;
          var telaCelda = row.cells[1];
          var telaTexto = telaCelda ? telaCelda.innerText.trim().toLowerCase() : '';
          if (tela && !telaTexto.includes(tela)) mostrar = false;

          var tejidoCelda = row.cells[4];
          var tejidoTexto = tejidoCelda ? tejidoCelda.innerText.trim().toLowerCase() : '';
          if (tejido && !tejidoTexto.includes(tejido)) mostrar = false;

          var faseCelda = row.cells[5];
          var faseTexto = '';
          if (faseCelda) {
              var span = faseCelda.querySelector('span');
              if (span) faseTexto = span.innerText.trim();
          }
          if (fase && faseTexto !== fase) mostrar = false;

          var fechaCelda = row.cells[11];
          if (fechaCelda && (fechaDesde || fechaHasta)) {
              var fechaStr = fechaCelda.innerText.trim();
              if (fechaStr && fechaStr !== "—") {
                  var partes = fechaStr.split(' ')[0];
                  var partesDia = partes.split('/');
                  if (partesDia.length === 3) {
                      var fechaFalla = new Date(partesDia[2].length === 2 ? '20' + partesDia[2] : partesDia[2], partesDia[1]-1, partesDia[0]);
                      if (fechaDesde) {
                          var fechaDesdeObj = new Date(fechaDesde);
                          if (fechaFalla < fechaDesdeObj) mostrar = false;
                      }
                      if (fechaHasta && mostrar) {
                          var fechaHastaObj = new Date(fechaHasta);
                          if (fechaFalla > fechaHastaObj) mostrar = false;
                      }
                  }
              }
          }
          row.style.display = mostrar ? '' : 'none';
          if (mostrar) visibles++;
      });
      var contadorSpan = document.getElementById('contadorMermas');
      if (contadorSpan) contadorSpan.textContent = visibles + ' registro(s)';
  }

  function limpiarFiltrosMermas() {
      document.getElementById('filtroTela').value = '';
      document.getElementById('filtroTejido').value = '';
      document.getElementById('filtroFase').value = '';
      document.getElementById('filtroFechaDesde').value = '';
      document.getElementById('filtroFechaHasta').value = '';
      aplicarFiltrosMermas();
  }

  document.addEventListener('DOMContentLoaded', function() {
      aplicarFiltrosMermas();
      document.getElementById('filtroTela').addEventListener('input', aplicarFiltrosMermas);
      document.getElementById('filtroTejido').addEventListener('input', aplicarFiltrosMermas);
      document.getElementById('filtroFase').addEventListener('change', aplicarFiltrosMermas);
      document.getElementById('filtroFechaDesde').addEventListener('change', aplicarFiltrosMermas);
      document.getElementById('filtroFechaHasta').addEventListener('change', aplicarFiltrosMermas);
      document.getElementById('btnLimpiarFiltros').addEventListener('click', limpiarFiltrosMermas);
  });

  // ── EDICIÓN DE MERMA ──
  function abrirModalEditar(idMerma, codigoTela, idTela, fase, pesoUtilizado, pesoMerma, observaciones) {
    document.getElementById('edit_idMerma').value = idMerma;
    document.getElementById('edit_codigoTela').value = codigoTela;
    document.getElementById('edit_idTela').value = idTela;
    document.getElementById('edit_fase').value = fase;
    document.getElementById('edit_pesoUtilizado').value = pesoUtilizado;
    document.getElementById('edit_pesoMerma').value = pesoMerma;
    document.getElementById('edit_observaciones').value = observaciones;
    calcularPreviewEdicion();
    abrirModal('overlay-editar');
  }

  function calcularPreviewEdicion() {
      var util  = parseFloat(document.getElementById('edit_pesoUtilizado').value) || 0;
      var merma = parseFloat(document.getElementById('edit_pesoMerma').value) || 0;
      var preview = document.getElementById('editPctPreview');
      var pctSpan = document.getElementById('editPctVal');
      if (util > 0) {
          var pct = ((merma / util) * 100).toFixed(3);
          pctSpan.textContent = pct;
          preview.style.display = 'block';
          preview.style.background = pct <= 5 ? 'var(--success-bg)' : pct <= 10 ? 'var(--warning-bg)' : 'var(--danger-bg)';
          preview.style.color      = pct <= 5 ? 'var(--success-text)' : pct <= 10 ? 'var(--warning-text)' : 'var(--danger-text)';
          preview.style.borderColor = pct <= 5 ? '#a7f3d0' : pct <= 10 ? '#fde68a' : '#fecaca';
      } else {
          preview.style.display = 'none';
      }
  }

  function validarEdicion() {
      var util  = parseFloat(document.getElementById('edit_pesoUtilizado').value);
      var merma = parseFloat(document.getElementById('edit_pesoMerma').value);
      if (!util || util <= 0) { alert('El peso utilizado debe ser mayor a 0.'); return false; }
      if (isNaN(merma) || merma < 0) { alert('El peso de merma no puede ser negativo.'); return false; }
      if (merma > util) { alert('El peso de merma no puede superar el peso utilizado.'); return false; }
      return true;
  }
</script>
</body>
</html>