<%@ page contentType="text/html;charset=UTF-8" language="java" %>
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
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; display: flex; min-height: 100vh; }

    /* ── Sidebar ── */
    aside { width: 240px; background: #1a1a2e; color: #ccc; display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 1.5rem 1.2rem; border-bottom: 1px solid #2d2d50; color: #e2b96f; font-weight: 700; font-size: 1rem; }
    .sidebar-logo span { display: block; font-size: .72rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .65rem; padding: .7rem 1.3rem; color: #bbb; text-decoration: none; font-size: .88rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: #0f3460; color: #fff; }
    nav .sep { padding: .4rem 1.3rem; font-size: .7rem; color: #555; text-transform: uppercase; margin-top: .6rem; }

    /* ── Main ── */
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c; border-radius: 6px; background: transparent; text-decoration: none; font-size: .78rem; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }
    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }

    /* ── Alertas ── */
    .alerta { padding: .75rem 1.1rem; border-radius: 9px; margin-bottom: 1.2rem; font-size: .85rem; }
    .alerta-ok   { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-err  { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    .alerta-warn { background: #fff3cd; color: #856404; border: 1px solid #ffc107; }

    /* ── Tabla ── */
    .barra-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.3rem; }
    .barra-top h3 { font-size: 1.05rem; color: #1a1a2e; }
    .btn-nuevo { display: inline-flex; align-items: center; gap: .4rem; padding: .5rem 1.2rem; background: #0f3460; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .88rem; font-weight: 600; text-decoration: none; transition: background .2s; }
    .btn-nuevo:hover { background: #1a5ca8; }
    .card { background: #fff; border-radius: 12px; padding: 1.2rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; padding: .75rem 1rem; text-align: center; border-bottom: 2px solid #eee; white-space: nowrap; font-weight: 600; color: #555; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; color: #333; vertical-align: middle; }
    tr:hover td { background: #fafafa; }
    .badge-estado { display: inline-block; padding: .22rem .7rem; border-radius: 20px; font-size: .7rem; font-weight: 700; }
    .est-ACEPTADO  { background: #d1e7dd; color: #0a3622; }
    .est-OBSERVADO { background: #fff3cd; color: #664d03; }
    .est-RECHAZADO { background: #f8d7da; color: #58151c; }
    .badge-origen { display: inline-block; padding: .2rem .6rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .or-CLIENTE { background: #cfe2ff; color: #084298; }
    .or-TALLER  { background: #e2d9f3; color: #432874; }
    .dif-ok   { color: #0a3622; font-weight: 600; }
    .dif-warn { color: #856404; font-weight: 700; }
    .dif-err  { color: #58151c; font-weight: 700; }
    .btn-sm { display: inline-flex; align-items: center; gap: 4px; padding: .28rem .7rem; border: none; border-radius: 6px; cursor: pointer; font-size: .75rem; font-weight: 600; text-decoration: none; }
    .btn-ver { background: #e0f0ff; color: #0f3460; }
    .btn-ver:hover { background: #bee3f8; }
    .reposo-badge { display: inline-block; background: #fff3cd; color: #856404; border-radius: 20px; padding: .18rem .55rem; font-size: .68rem; font-weight: 600; }
    .sin-datos { text-align: center; padding: 3rem; color: #aaa; }

    /* ══════════════════════════════════════════
       OVERLAY + MODAL FLOTANTE
    ══════════════════════════════════════════ */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.55);
      z-index: 1000; justify-content: center; align-items: center; padding: 1rem; }
    .overlay.activo { display: flex; }

    .modal-flotante { background: #fff; border-radius: 14px; width: 100%;
      max-width: 820px; max-height: 92vh; display: flex; flex-direction: column;
      box-shadow: 0 20px 60px rgba(0,0,0,.3); overflow: hidden; }

    .modal-header { background: #1a1a2e; padding: 1rem 1.5rem; display: flex;
      align-items: center; justify-content: space-between; flex-shrink: 0; }
    .modal-header h3 { color: #e2b96f; font-size: 1rem; }
    .modal-close { background: none; border: none; color: #ccc; font-size: 1.4rem;
      cursor: pointer; line-height: 1; padding: 0 .2rem; }
    .modal-close:hover { color: #fff; }

    .modal-flotante > form {
      display: flex; flex-direction: column; flex: 1; min-height: 0; overflow: hidden;
    }
    .modal-body {
      padding: 1.5rem 2rem;
      overflow-y: scroll;
      flex: 1;
      min-height: 0;
      scrollbar-width: thin;
      scrollbar-color: #0f3460 #e5e7eb;
    }
    .modal-body::-webkit-scrollbar { width: 10px; }
    .modal-body::-webkit-scrollbar-track { background: #e5e7eb; border-radius: 6px; }
    .modal-body::-webkit-scrollbar-thumb { background: #0f3460; border-radius: 6px; border: 2px solid #e5e7eb; }
    .modal-body::-webkit-scrollbar-thumb:hover { background: #1a5ca8; }
    .modal-footer { padding: 1rem 2rem; border-top: 1px solid #f0f0f0;
      display: flex; gap: .8rem; justify-content: flex-end; flex-shrink: 0; background: #fff; }

    /* Formulario dentro del modal */
    .alerta-error-modal { background: #fee2e2; border: 1px solid #fca5a5; color: #b91c1c;
      border-radius: 8px; padding: .65rem .9rem; font-size: .86rem; margin-bottom: 1.2rem; }
    .sec-titulo { font-size: .76rem; font-weight: 700; color: #0f3460; text-transform: uppercase;
      letter-spacing: .07em; border-bottom: 2px solid #e5e7eb; padding-bottom: .4rem;
      margin: 1.4rem 0 1rem; }
    .sec-titulo:first-of-type { margin-top: 0; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    .modal-body label { display: block; font-size: .82rem; font-weight: 600; color: #374151; margin-bottom: .3rem; }
    .req { color: #e74c3c; margin-left: 2px; }
    .modal-body input[type="text"], .modal-body input[type="number"],
    .modal-body select, .modal-body textarea {
      width: 100%; padding: .58rem .85rem; border: 1.5px solid #d1d5db;
      border-radius: 8px; font-size: .88rem; font-family: inherit;
      transition: border-color .2s; outline: none; }
    .modal-body input:focus, .modal-body select:focus, .modal-body textarea:focus { border-color: #0f3460; }
    .modal-body textarea { resize: vertical; min-height: 80px; }
    .hint { font-size: .73rem; color: #9ca3af; margin-top: .22rem; }
    #alerta-peso-modal { display: none; background: #fef3c7; border: 1.5px solid #f59e0b;
      color: #78350f; border-radius: 9px; padding: .6rem 1rem; font-size: .83rem;
      margin-top: .6rem; }
    #alerta-peso-modal.activo { display: flex; align-items: center; gap: .5rem; }
    .check-fila { display: flex; align-items: center; gap: .6rem; padding: .6rem 0; }
    .check-fila input[type="checkbox"] { width: 18px; height: 18px; cursor: pointer; }
    .check-fila label { margin: 0; font-weight: 500; cursor: pointer; font-size: .88rem; }
    .upload-area { border: 2px dashed #d1d5db; border-radius: 10px; padding: 1.2rem;
      text-align: center; background: #fafafa; transition: border-color .2s; cursor: pointer; }
    .upload-area:hover { border-color: #0f3460; background: #f0f4ff; }
    .upload-area .ico { font-size: 1.8rem; display: block; margin-bottom: .3rem; }
    .upload-area p { font-size: .82rem; color: #6b7280; }
    .upload-area input[type="file"] { display: none; }
    #preview-fotos-modal { display: flex; flex-wrap: wrap; gap: .5rem; margin-top: .6rem; }
    #preview-fotos-modal img { width: 70px; height: 70px; object-fit: cover; border-radius: 8px; border: 2px solid #e5e7eb; }
    .info-registrador { background: #f8f9ff; border: 1px solid #e0e7ff; border-radius: 8px;
      padding: .6rem 1rem; font-size: .82rem; color: #374151; display: flex; align-items: center; gap: .5rem; }

    /* Botones modal */
    .btn-guardar-modal { padding: .6rem 1.5rem; background: #0f3460; color: #fff; border: none;
      border-radius: 8px; cursor: pointer; font-size: .88rem; font-weight: 600; }
    .btn-guardar-modal:hover { background: #1a5ca8; }
    .btn-cancelar-modal { padding: .6rem 1.2rem; background: #f0f0f0; color: #555; border: none;
      border-radius: 8px; cursor: pointer; font-size: .88rem; }
    .btn-cancelar-modal:hover { background: #e0e0e0; }

    /* Modal detalle */
    .modal-flotante-lg { max-width: 1000px; }
    .grid-datos { display: grid; grid-template-columns: 1fr 1fr; gap: .5rem 2rem; }
    .dato { padding: .4rem 0; border-bottom: 1px solid #f3f4f6; }
    .dato .lbl { font-size: .73rem; color: #9ca3af; font-weight: 600; text-transform: uppercase; margin-bottom: .12rem; }
    .dato .val { font-size: .88rem; color: #111; font-weight: 500; }
    .layout-detalle { display: grid; grid-template-columns: 1fr 260px; gap: 1.2rem; }
    .alerta-peso-detalle { background: #fef3c7; border: 1.5px solid #f59e0b; color: #78350f;
      border-radius: 9px; padding: .65rem 1rem; font-size: .83rem; margin-bottom: 1rem; }
    .galeria { display: flex; flex-wrap: wrap; gap: .6rem; margin-top: .5rem; }
    .galeria a img { width: 110px; height: 110px; object-fit: cover; border-radius: 9px;
      border: 2px solid #e5e7eb; transition: border-color .2s; }
    .galeria a:hover img { border-color: #0f3460; }
    .sin-fotos { color: #9ca3af; font-size: .85rem; padding: .8rem 0; }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
    <div class="sep">Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard">🏠 Inicio</a>
    <% if (permisos.contains("SEG_USUARIOS_VER")) { %>
    <div class="sep">Seguridad</div>
    <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
    <% } %>
    <% if (permisos.contains("CAT_TELAS_VER") || permisos.contains("CAT_MODELOS_VER")) { %>
    <div class="sep">Catálogos</div>
    <% if (permisos.contains("CAT_TELAS_VER")) { %><a href="<%= request.getContextPath() %>/catalogo-telas">🧵 Telas</a><% } %>
    <% if (permisos.contains("CAT_MODELOS_VER")) { %><a href="<%= request.getContextPath() %>/catalogo-modelos">👗 Modelos</a><% } %>
    <% } %>
    <div class="sep">Almacén</div>
    <a href="<%= request.getContextPath() %>/inventario" class="activo">📦 Tela Recibida</a>
    <% if (permisos.contains("PROD_OT_VER")) { %>
    <div class="sep">Producción</div>
    <a href="<%= request.getContextPath() %>/ordenes-trabajo">📋 Órdenes de Trabajo</a>
    <% } %>
  </nav>
</aside>

<main>
  <header>
    <h2>📦 Almacén – Control de Tela Recibida (HU01)</h2>
    <div class="user-info">
      <span><%= sesion.getNombreCompleto() %></span>
      <span class="badge"><%= sesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
    </div>
  </header>

  <div class="contenido">

    <% if (mensajeExito != null) { %>
      <% if (mensajeExito.contains("ALERTA")) { %>
        <div class="alerta alerta-warn"><%= mensajeExito %></div>
      <% } else { %>
        <div class="alerta alerta-ok"><%= mensajeExito %></div>
      <% } %>
    <% } %>
    <% if (mensajeError != null) { %>
      <div class="alerta alerta-err">❌ <%= java.net.URLDecoder.decode(mensajeError, "UTF-8") %></div>
    <% } %>
    
    <div class="barra-top" style="display:flex; flex-wrap:wrap; align-items:center; gap:1rem; margin-bottom:1.3rem;">
        <h3 style="margin:0; white-space:nowrap;">Registros de Tela Recibida (<%= listaTelas.size() %>)</h3>

        <% if (puedeRegistrar) { %>
          <button type="button" class="btn-nuevo" onclick="abrirModalRegistro()" style="white-space:nowrap;">
            + Registrar Ingreso de Tela
          </button>
        <% } %>
      </div>
      
      <div style="flex: 1; display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 20px; justify-content: center;">
          <form method="get" action="<%= request.getContextPath() %>/inventario" style="display:flex; align-items:center; gap:0.5rem; flex:1; flex-wrap:wrap;">
          <div style="position:relative; flex:1; min-width:180px;">
            <input type="text" name="fCodigo" placeholder="Código tela" value="<%= filtroCodigo %>"
                   style="width:100%; padding:.45rem 1rem .45rem 2rem; border:1.5px solid #ddd; border-radius:8px; font-size:.85rem;">
            <span style="position:absolute; left:.6rem; top:50%; transform:translateY(-50%); color:#aaa; font-size:.9rem;">🔍</span>
          </div>
          <input type="text" name="fProveedor" placeholder="Proveedor" value="<%= filtroProveedor %>"
                 style="width:160px; padding:.45rem .8rem; border:1.5px solid #ddd; border-radius:8px; font-size:.85rem;">
          <input type="date" name="fFechaIni" value="<%= filtroFechaIni %>" title="Fecha inicio"
                 style="width:140px; padding:.45rem .5rem; border:1.5px solid #ddd; border-radius:8px; font-size:.85rem;">
          <input type="date" name="fFechaFin" value="<%= filtroFechaFin %>" title="Fecha fin"
                 style="width:140px; padding:.45rem .5rem; border:1.5px solid #ddd; border-radius:8px; font-size:.85rem;">
          <button type="submit" class="btn-nuevo" style="padding:.5rem 1.2rem; background:#0f3460; color:#fff; border:none; border-radius:8px; cursor:pointer; font-size:.85rem;">
            🔍 Buscar
          </button>
          <a href="<%= request.getContextPath() %>/inventario" class="btn-cancelar-modal" style="padding:.5rem 1rem; background:#f0f0f0; color:#555; border:none; border-radius:8px; text-decoration:none; font-size:.85rem;">
            Limpiar
          </a>
        </form>
      </div>
    <div class="card">
      <% if (listaTelas.isEmpty()) { %>
        <div class="sin-datos">
          📦 No hay telas registradas aún.<br>
          <% if (puedeRegistrar) { %>
            <button type="button" class="btn-nuevo" style="margin-top:1rem;" onclick="abrirModalRegistro()">
              + Registrar primer ingreso
            </button>
          <% } %>
        </div>
      <% } else { %>
      <table>
        <thead>
          <tr>
            <th>#</th><th>Código Tela</th><th>OT Vinculada</th><th>Origen</th>
            <th>Proveedor</th><th>Peso Guía (kg)</th><th>Peso Real (kg)</th>
            <th>Diferencia</th><th>Estado Calidad</th><th>Reposo</th>
            <th>Registrado por</th><th>Fecha</th><th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% int i = 1; for (Tela t : listaTelas) {
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
            <td><%= i++ %></td>
            <td style="font-family:monospace; font-weight:700; color:#0f3460;"><%= t.getCodigoTela() %></td>
            <td><span style="font-family:monospace; font-size:.8rem;"><%= t.getCodigoOt() != null ? t.getCodigoOt() : "—" %></span></td>
            <td><span class="badge-origen or-<%= t.getOrigen().name() %>"><%= t.getOrigen().name() %></span></td>
            <td><%= t.getProveedor() != null ? t.getProveedor() : "—" %></td>
            <td style="text-align:right;"><%= t.getPesoGuia() %></td>
            <td style="text-align:right;"><%= t.getPesoReal() %></td>
            <td style="text-align:right;" class="<%= difClass %>">
              <%= difVal >= 0 ? "+" : "" %><%= String.format("%.3f", difVal) %>
              <% if (pct > 1.0) { %> ⚠<% } %>
            </td>
            <td><span class="badge-estado est-<%= t.getEstadoCalidad().name() %>"><%= t.getEstadoCalidad().name() %></span></td>
            <td>
              <% if (t.isRequiereReposo()) { %><span class="reposo-badge">⏱ Sí</span>
              <% } else { %><span style="color:#bbb; font-size:.75rem;">No</span><% } %>
            </td>
            <td style="font-size:.8rem;"><%= t.getNombreRegistrador() != null ? t.getNombreRegistrador() : "—" %></td>
            <td style="white-space:nowrap; font-size:.78rem; color:#777;"><%= t.getFechaIngreso() != null ? sdf.format(t.getFechaIngreso()) : "—" %></td>
            <td>
              <button type="button" class="btn-sm btn-ver"
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
                )">🔍 Ver</button>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
      <% } %>
    </div>
  </div>
</main>

<!-- ══════════════════════════════════════════════
     MODAL 1: REGISTRAR INGRESO DE TELA
══════════════════════════════════════════════ -->
<div class="overlay" id="overlayRegistro">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3>📦 Registrar Ingreso de Tela</h3>
      <button type="button" class="modal-close" onclick="cerrarModalRegistro()">✕</button>
    </div>

    <form method="POST" action="<%= request.getContextPath() %>/inventario"
          enctype="multipart/form-data"
          onsubmit="return validarFormRegistro()"
          id="formRegistroTela">
      <div class="modal-body">

        <div id="errorRegistroModal" class="alerta-error-modal" style="display:none;"></div>

        <!-- OT Vinculada -->
        <div class="sec-titulo">📋 Orden de Trabajo Vinculada</div>
        <div class="grid-2">
          <div>
            <label>Orden de Trabajo <span class="req">*</span></label>
            <select name="id_ot" id="m_id_ot" required>
              <option value="">-- Selecciona una OT activa --</option>
              <% for (OrdenTrabajo ot : otsActivas) { %>
                <option value="<%= ot.getIdOt() %>">
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
              👤 <strong><%= sesion.getNombreCompleto() %></strong>
              &nbsp;–&nbsp; <%= sesion.getNombreRol() %>
              <span style="margin-left:auto; font-size:.72rem; color:#9ca3af;">Automático</span>
            </div>
          </div>
        </div>

        <!-- Material -->
        <div class="sec-titulo">🧵 Datos del Material</div>
        <div class="grid-2">
          <div>
            <label>Origen <span class="req">*</span></label>
            <select name="origen" id="m_origen" required>
              <option value="">-- Selecciona --</option>
              <option value="CLIENTE">Del cliente</option>
              <option value="TALLER">Adquirida por el taller</option>
            </select>
          </div>
          <div>
            <label>Proveedor</label>
            <input type="text" name="proveedor" id="m_proveedor" maxlength="150" placeholder="Ej: Textiles Andes S.A.C.">
          </div>
        </div>
        <div class="grid-3" style="margin-top:1rem;">
          <div>
              <label>Material (Catálogo)</label>
              <select name="id_catalogo_tela" id="m_cat_tela" onchange="actualizarInfoCatalogo()">
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
                <input type="text" id="m_tipo_tejido" name="tipo_tejido" maxlength="80" readonly>
             </div>
          <div>
            <label>Color</label>
            <input type="text" name="color" id="m_color" maxlength="50" placeholder="Ej: Negro">
          </div>
          <div>
            <label>N.° de Rollos</label>
            <input type="number" name="num_rollos" id="m_num_rollos" min="1" value="1" max="9999">
          </div>
        </div>

        <!-- Pesos -->
        <div class="sec-titulo">⚖ Control de Peso – Guía vs Real</div>
        <div class="grid-2">
          <div>
            <label>Peso Guía de Remisión (kg) <span class="req">*</span></label>
            <input type="number" name="peso_guia" id="m_peso_guia"
                   step="0.001" min="0.001" placeholder="0.000" required oninput="calcularDifModal()">
          </div>
          <div>
            <label>Peso Real Medido (kg) <span class="req">*</span></label>
            <input type="number" name="peso_real" id="m_peso_real"
                   step="0.001" min="0.001" placeholder="0.000" required oninput="calcularDifModal()">
          </div>
        </div>
        <div id="alerta-peso-modal">
          ⚠ <span>Diferencia: <strong id="dif-valor-modal"></strong> — supera el 1% permitido.</span>
        </div>

        <!-- Calidad -->
        <div class="sec-titulo">✅ Calidad y Observaciones</div>
        <div>
          <label>Estado de Calidad <span class="req">*</span></label>
          <select name="estado_calidad" id="m_estado_calidad" required>
            <option value="OBSERVADO">Observado (pendiente revisión)</option>
            <option value="ACEPTADO">Aceptado</option>
            <option value="RECHAZADO">Rechazado</option>
          </select>
        </div>
        <div style="margin-top:1rem;">
          <label>Observaciones <span class="req">*</span></label>
          <textarea name="observaciones" id="m_observaciones" required
            placeholder="Estado del material, condición del embalaje, manchas, fallas, diferencias de peso..."></textarea>
        </div>

        <!-- Fotos -->
        <div class="sec-titulo">📷 Evidencia Fotográfica</div>
        <label onclick="document.getElementById('m_fotos').click()" style="cursor:pointer; display:block;">
          <div class="upload-area" id="m_upload_area">
            <span class="ico">📷</span>
            <p><strong>Clic o arrastra fotos aquí</strong></p>
            <p>JPG, PNG, WEBP · Máx 5 MB · Hasta 4 fotos</p>
            <input type="file" id="m_fotos" name="fotos" accept=".jpg,.jpeg,.png,.webp"
                   multiple onchange="previsualizarModal(this)">
          </div>
        </label>
        <div id="preview-fotos-modal"></div>

        <!-- Reposo -->
        <div class="sec-titulo">⚙ Configuración</div>
        <div class="check-fila">
          <input type="checkbox" id="m_reposo" name="requiere_reposo">
          <label for="m_reposo">Requiere reposo antes del corte
            <small style="color:#9ca3af;">(vincula con HU03)</small>
          </label>
        </div>

      </div><!-- /modal-body -->
      <div class="modal-footer">
        <button type="button" class="btn-cancelar-modal" onclick="cerrarModalRegistro()">✖ Cancelar</button>
        <button type="submit" class="btn-guardar-modal">💾 Registrar Ingreso de Tela</button>
      </div>
    </form>
  </div>
</div>

<!-- ══════════════════════════════════════════════
     MODAL 2: VER DETALLE DE TELA
══════════════════════════════════════════════ -->
<div class="overlay" id="overlayDetalle">
  <div class="modal-flotante modal-flotante-lg">
    <div class="modal-header">
      <h3 id="detTitulo">🔍 Detalle de Tela</h3>
      <button type="button" class="modal-close" onclick="cerrarModalDetalle()">✕</button>
    </div>
    <div class="modal-body">

      <div id="detAlertaPeso" class="alerta-peso-detalle" style="display:none;"></div>

      <div class="layout-detalle">
        <!-- Columna izquierda: datos -->
        <div>
          <div class="sec-titulo">📋 Identificación y Material</div>
          <div class="grid-datos">
            <div class="dato"><div class="lbl">Código Tela</div><div class="val" id="d_codigo"></div></div>
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

          <div class="sec-titulo">⚖ Control de Peso</div>
          <div class="grid-datos">
            <div class="dato"><div class="lbl">Peso Guía</div><div class="val" id="d_peso_guia"></div></div>
            <div class="dato"><div class="lbl">Peso Real</div><div class="val" id="d_peso_real"></div></div>
            <div class="dato"><div class="lbl">Diferencia</div><div class="val" id="d_diferencia"></div></div>
          </div>

          <div class="sec-titulo">✅ Calidad</div>
          <div class="dato"><div class="lbl">Estado</div><div class="val" id="d_estado"></div></div>
          <div class="dato"><div class="lbl">Requiere Reposo</div><div class="val" id="d_reposo"></div></div>
          <div style="margin-top:.8rem; background:#f9fafb; border-radius:9px; padding:1rem;
               font-size:.86rem; color:#374151; line-height:1.6; border:1px solid #e5e7eb;">
            <strong style="display:block; margin-bottom:.3rem; color:#0f3460; font-size:.73rem;
               text-transform:uppercase; letter-spacing:.06em;">Observaciones</strong>
            <div id="d_observaciones"></div>
          </div>
        </div>

        <!-- Columna derecha: fotos -->
        <div>
          <div class="sec-titulo">📷 Evidencia Fotográfica</div>
          <div id="d_fotos_contenedor"></div>
        </div>
      </div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn-cancelar-modal" onclick="cerrarModalDetalle()">✖ Cerrar</button>
    </div>
  </div>
</div>

<script>
  var CTX = '<%= request.getContextPath() %>';

  /* ── MODAL REGISTRO ── */
  function abrirModalRegistro() {
    document.getElementById('formRegistroTela').reset();
    document.getElementById('preview-fotos-modal').innerHTML = '';
    document.getElementById('alerta-peso-modal').classList.remove('activo');
    document.getElementById('errorRegistroModal').style.display = 'none';
    document.getElementById('overlayRegistro').classList.add('activo');
    document.getElementById('m_id_ot').focus();
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
      el.classList.add('activo');
    } else {
      el.classList.remove('activo');
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
  mArea.addEventListener('dragover', function(e) { e.preventDefault(); mArea.style.borderColor='#0f3460'; });
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
    el.textContent = '❌ ' + msg;
    el.style.display = '';
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  /* ── MODAL DETALLE ── */
  function abrirModalDetalle(codigo, ot, origen, proveedor, materialCatalogo, tejido, color, rollos,
    pesoGuia, pesoReal, diferencia, pct, estado, reposo, observaciones,
    registrador, fecha, fotos) {

    document.getElementById('detTitulo').textContent = '🔍 Detalle – ' + codigo;
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
    difEl.style.color  = pctN > 1.0 ? '#b45309' : '#0a3622';
    difEl.style.fontWeight = '700';

    // Alerta de peso
    var alertaEl = document.getElementById('detAlertaPeso');
    if (pctN > 1.0) {
      alertaEl.textContent = '⚠ Alerta de peso: diferencia de ' + (dif >= 0 ? '+' : '') + diferencia + ' kg (' + pct + '%) — verificar con proveedor.';
      alertaEl.style.display = '';
    } else {
      alertaEl.style.display = 'none';
    }

    // Estado calidad
    var estadoMap = { ACEPTADO: '#d1e7dd|#0a3622', OBSERVADO: '#fff3cd|#664d03', RECHAZADO: '#f8d7da|#58151c' };
    var colores = (estadoMap[estado] || '#eee|#333').split('|');
    document.getElementById('d_estado').innerHTML =
      '<span style="background:' + colores[0] + ';color:' + colores[1] +
      ';padding:.22rem .7rem;border-radius:20px;font-size:.75rem;font-weight:700;">' + estado + '</span>';

    document.getElementById('d_reposo').textContent = reposo === 'true' ? '✅ Sí (vinculado con HU03)' : 'No';

    // Fotos
    var cont = document.getElementById('d_fotos_contenedor');
    if (!fotos || fotos.length === 0) {
      cont.innerHTML = '<p class="sin-fotos">No se cargaron fotos para esta tela.</p>';
    } else {
      var html = '<p style="font-size:.78rem;color:#9ca3af;margin-bottom:.5rem;">' + fotos.length + ' foto(s)</p><div class="galeria">';
      fotos.forEach(function(ruta) {
        html += '<a href="' + CTX + '/' + ruta + '" target="_blank">' +
                '<img src="' + CTX + '/' + ruta + '" alt="Foto evidencia"></a>';
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
  // Opcional: mostrar tiempo de reposo en un span
}
</script>
</body>
</html>
