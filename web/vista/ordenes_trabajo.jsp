<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean puedeVer   = permisos.contains("PROD_OT_VER");
    boolean puedeCrear = permisos.contains("PROD_OT_CREAR");

    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    List<OrdenTrabajo>  ordenes       = (List<OrdenTrabajo>)  request.getAttribute("ordenes");
    List<ModeloPrenda>  modelosPrenda = (List<ModeloPrenda>)  request.getAttribute("modelosPrenda");
    String              codigoPreview = (String)              request.getAttribute("codigoPreview");

    if (ordenes == null) ordenes = new ArrayList<>();

    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");
    String errorBD      = (String) request.getAttribute("errorBD");

    // Si el servlet nos devuelve con error al crear OT, reabrimos el modal
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
  <style>
    :root { --primary-dark: #0f3460; --accent: #e2b96f; --bg-light: #f0f2f5; }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: var(--bg-light); display: flex; min-height: 100vh; }
    aside { width: 240px; background: #1a1a2e; color: #ccc; display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 1.5rem 1.2rem; border-bottom: 1px solid #2d2d50; color: var(--accent); font-weight: 700; font-size: 1rem; }
    .sidebar-logo span { display: block; font-size: .72rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .65rem; padding: .7rem 1.3rem; color: #bbb; text-decoration: none; font-size: .88rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: var(--primary-dark); color: #fff; }
    nav .separador { padding: .4rem 1.3rem; font-size: .7rem; color: #555; text-transform: uppercase; margin-top: .6rem; }
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); z-index: 10; }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c; border-radius: 6px; background: transparent; cursor: pointer; font-size: .78rem; text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }
    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }
    .alerta { padding: .7rem 1.1rem; border-radius: 8px; margin-bottom: 1.2rem; font-size: .85rem; }
    .alerta-ok  { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-err { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    .barra-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.3rem; }
    .barra-top h3 { font-size: 1.05rem; color: #1a1a2e; }
    .btn { display: inline-flex; align-items: center; gap: .4rem; padding: .5rem 1.2rem; border: none; border-radius: 8px; cursor: pointer; font-size: .85rem; font-weight: 600; text-decoration: none; transition: opacity .15s; }
    .btn:hover { opacity: .85; }
    .btn-primary { background: #0f3460; color: #fff; }
    .btn-editar { background: #ffc107; color: #1a1a2e; }
    .btn-editar:hover { background: #e0a800; }
    .btn-success { background: #27ae60; color: #fff; }
    .btn-warn    { background: #084298; color: #fff; }
    .btn-danger  { background: #e74c3c; color: #fff; }
    .btn-sm      { padding: .3rem .75rem; font-size: .78rem; }
    .card { background: #fff; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; padding: .75rem 1rem; text-align: center; border-bottom: 2px solid #eee; white-space: nowrap; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }
    tr:hover td { background: #fafafa; }
    .badge-estado {
    display: inline-block;
        min-width: 110px;          /* ancho mínimo para igualar todos */
        text-align: center;        /* centra el texto en ese ancho */
        padding: .25rem .75rem;
        border-radius: 20px;
        font-size: .72rem;
        font-weight: 700;
        white-space: nowrap;
    }
    .est-CREADA     { background: #cfe2ff; color: #084298; }
    .est-EN_PROCESO { background: #fff3cd; color: #664d03; }
    .est-FINALIZADA { background: #d1e7dd; color: #0a3622; }
    .est-ANULADA    { background: #f8d7da; color: #58151c; }
    .sin-datos { text-align: center; padding: 3rem; color: #aaa; }
    .sin-datos .ico { font-size: 3rem; display: block; margin-bottom: .7rem; }
    .codigo-ot { font-family: monospace; font-weight: 700; color: #0f3460; font-size: .88rem; }
    .acciones { display: flex; gap: .4rem; }
    
    /* ── MODAL CAMBIO ESTADO (ya existia) ── */
    .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 100; justify-content: center; align-items: center; }
    .overlay.activo { display: flex; }
    .modal { background: #fff; border-radius: 14px; padding: 2rem; width: 380px; box-shadow: 0 10px 40px rgba(0,0,0,.2); }
    .modal h3 { margin-bottom: 1rem; color: #1a1a2e; font-size: 1rem; }
    .modal select { width: 100%; padding: .55rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .85rem; margin-bottom: 1.2rem; }
    .modal-botones { display: flex; gap: .7rem; justify-content: flex-end; }
    .btn-cancelar { background: #eee; color: #555; }

    /* ── MODAL FLOTANTE NUEVA OT ── */
    .overlay-ot { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.55); z-index: 200; justify-content: center; align-items: center; padding: 1rem; }
    .overlay-ot.activo { display: flex; }
    .modal-ot { background: #fff; border-radius: 14px; width: 100%; max-width: 640px; max-height: 92vh; display: flex; flex-direction: column; box-shadow: 0 20px 60px rgba(0,0,0,.3); overflow: hidden; }
    .modal-ot-header { background: #1a1a2e; padding: 1rem 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
    .modal-ot-header h3 { color: #e2b96f; font-size: 1rem; }
    .modal-ot-close { background: none; border: none; color: #ccc; font-size: 1.4rem; cursor: pointer; line-height: 1; padding: 0 .2rem; }
    .modal-ot-close:hover { color: #fff; }
    .modal-ot-body { padding: 1.8rem 2rem; overflow-y: auto; flex: 1; }

    /* Banner código OT */
    .ot-preview { background: linear-gradient(135deg, #1a1a2e, #0f3460); color: #fff; border-radius: 10px; padding: 1rem 1.5rem; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 1rem; }
    .ot-preview .lbl { font-size: .78rem; color: #aac4e8; }
    .ot-preview .cod { font-size: 1.4rem; font-weight: 700; font-family: monospace; color: var(--accent); }

    .form-group { margin-bottom: 1.2rem; }
    .form-group label { display: block; font-size: .84rem; font-weight: 600; color: #333; margin-bottom: .4rem; }
    .req { color: #e74c3c; margin-left: 2px; }
    .form-group input,
    .form-group select,
    .form-group textarea { width: 100%; padding: .6rem .9rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .88rem; font-family: inherit; transition: border-color .15s; }
    .form-group input:focus, .form-group select:focus { outline: none; border-color: #0f3460; }
    .form-group .hint { font-size: .75rem; color: #888; margin-top: .3rem; }
    .info-responsable { background: #f8f9ff; border: 1px solid #e0e7ff; border-radius: 8px; padding: .75rem 1rem; font-size: .83rem; color: #444; display: flex; align-items: center; gap: .5rem; }
    .alerta-err-modal { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: .7rem 1rem; border-radius: 8px; margin-bottom: 1.2rem; font-size: .85rem; }
    
    .modal-ot-footer { padding: 1rem 2rem; border-top: 1px solid #eee; display: flex; gap: .8rem; justify-content: flex-end; flex-shrink: 0; background: #fff; }
    .btn-ot-cancelar { padding: .55rem 1.2rem; background: #eee; color: #555; border: none; border-radius: 8px; cursor: pointer; font-size: .88rem; font-weight: 600; }
    .btn-ot-crear { padding: .55rem 1.4rem; background: #0f3460; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .88rem; font-weight: 600; }
    .btn-ot-crear:hover { background: #1a5ca8; }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
    <div class="separador">Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard">🏠 Inicio</a>
    <% if (permisos.contains("SEG_USUARIOS_VER")) { %>
    <div class="separador">Seguridad</div>
    <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
    <% } %>
    <% if (esAdmin) { %>
    <div class="separador">Catálogos</div>
    <a href="<%= request.getContextPath() %>/catalogo-telas">🧵 Catálogo de Telas</a>
    <a href="<%= request.getContextPath() %>/catalogo-modelos">👗 Catálogo de Modelos</a>
    <% } %>
    <% if (permisos.contains("ALM_TELA_VER")) { %>
    <div class="separador">Almacén</div>
    <a href="<%= request.getContextPath() %>/inventario">📦 Tela Recibida</a>
    <% } %>
    <% if (permisos.contains("PROD_MAQUINISTAS_VER")) { %>
    <a href="<%= request.getContextPath() %>/maquinistas">🧑‍🏭 Maquinistas</a>
    <% } %>
    <% if (permisos.contains("PROD_OT_VER")) { %>
    <div class="separador">Producción</div>
    <a href="<%= request.getContextPath() %>/ordenes-trabajo" class="activo">📋 Órdenes de Trabajo</a>
    <% } %>
  </nav>
</aside>

<main>
  <header>
    <h2>📋 Órdenes de Trabajo</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Cerrar sesión</a>
    </div>
  </header>

  <div class="contenido">
    <% if (mensajeExito != null && !mensajeExito.isEmpty()) { %>
      <div class="alerta alerta-ok">✅ <%= mensajeExito %></div>
    <% } %>
    <% if (mensajeError != null && !mensajeError.isEmpty()) { %>
      <div class="alerta alerta-err">❌ <%= mensajeError %></div>
    <% } %>
    <% if (errorBD != null) { %>
      <div class="alerta alerta-err">🔴 <%= errorBD %></div>
    <% } %>
    
    <div class="barra-top" style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.3rem;">
        <h3 style="margin:0; white-space: nowrap;">Listado de Órdenes de Trabajo (<%= ordenes.size() %>)</h3>

        

        <% if (puedeCrear) { %>
          <button type="button" class="btn btn-primary" onclick="abrirModalOT()">➕ Nueva Orden de Trabajo</button>
        <% } %>
      </div>
    <!-- Contenedor de filtros (se envuelven en varias líneas si es necesario) -->
        <div style="flex: 1; display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 20px; justify-content: center;">

          <!-- Búsqueda por texto -->
          <div style="position: relative; flex: 1 1 200px; max-width: 350px;">
            <input type="text" id="busquedaOT"
                   placeholder="Buscar por Código OT, cliente o modelo..."
                   style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                          border: 1.5px solid #ddd; border-radius: 8px;
                          font-size: .85rem; outline: none;">
            <span style="position: absolute; left: .6rem; top: 50%; transform: translateY(-50%);
                         color: #aaa; font-size: .9rem;">🔍</span>
          </div>

          <!-- Select de estado -->
          <select id="busquedaEstado" style="padding: .45rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .85rem; background: #fff;">
            <option value="">Todos los estados</option>
            <option value="CREADA">CREADA</option>
            <option value="EN_PROCESO">EN PROCESO</option>
            <option value="FINALIZADA">FINALIZADA</option>
            <option value="ANULADA">ANULADA</option>
          </select>

          <!-- Fecha inicio -->
          <input type="date" id="busquedaFechaIni" title="Fecha inicio"
                 style="padding: .45rem .5rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .85rem;">

          <!-- Fecha fin -->
          <input type="date" id="busquedaFechaFin" title="Fecha fin"
                 style="padding: .45rem .5rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .85rem;">

          <!-- Botón limpiar filtros (opcional) -->
          <button type="button" onclick="limpiarFiltrosOT()" style="padding: .45rem 1rem; background: #f0f0f0; color: #555; border: 1.5px solid #ddd; border-radius: 8px; cursor: pointer; font-size: .85rem;">
            Limpiar
          </button>

        </div>
    <div class="card">
      <% if (ordenes.isEmpty()) { %>
        <div class="sin-datos">
          <span class="ico">📋</span>
          No hay órdenes de trabajo registradas.<br>
          <% if (puedeCrear) { %>
            <!-- BOTÓN CREAR PRIMERA OT → también abre modal flotante -->
            <button type="button" class="btn btn-primary" style="margin-top:1rem;" onclick="abrirModalOT()">➕ Crear primera OT</button>
          <% } %>
        </div>
      <% } else { %>
        <table>
          <thead>
            <tr>
              <th>#</th><th>Código OT</th><th>Cliente</th><th>Modelo</th>
              <th>Cant. Est.</th><th>Estado</th><th>Responsable</th><th>Fecha Creación</th>
              <% if (puedeCrear) { %><th>Acciones</th><% } %>
            </tr>
          </thead>
          <tbody>
            <% int i = 1; for (OrdenTrabajo ot : ordenes) { %>
            <tr>
              <td><%= i++ %></td>
              <td><span class="codigo-ot"><%= ot.getCodigoOt() %></span></td>
              <td><%= ot.getCliente() %></td>
              <!-- Cambiar de ot.getModelo() a ot.getNombreModelo() -->
              <td><%= ot.getNombreModelo() != null ? ot.getNombreModelo() : "Sin modelo" %></td>
              <td style="text-align:center;"><strong><%= ot.getCantidadEst() %></strong></td>
              <td><span class="badge-estado est-<%= ot.getEstado() %>"><%= ot.getEstado().replace("_", " ") %></span></td>
              <td><%= ot.getNombreResponsable() != null ? ot.getNombreResponsable() : "-" %></td>
              <td style="white-space:nowrap; font-size:.78rem; color:#777;">
                <%= ot.getFechaCrea() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(ot.getFechaCrea()) : "-" %>
              </td>
              <% if (puedeCrear) { %>
              <td>
                  <div class="acciones">
                    <% if (!"ANULADA".equals(ot.getEstado()) && !"FINALIZADA".equals(ot.getEstado())) { %>
                      <button class="btn btn-warn btn-sm"
                        onclick="abrirModalEstado(<%= ot.getIdOt() %>, '<%= ot.getCodigoOt() %>', '<%= ot.getEstado() %>')">
                        🔄
                      </button>
                      <% if ("CREADA".equals(ot.getEstado())) { %>
                        <button class="btn btn-editar btn-sm"
                                onclick="abrirModalEditarOT('<%= ot.getIdOt() %>', '<%= ot.getCliente().replace("'","\\x27") %>', '<%= ot.getIdModelo() %>', '<%= ot.getCantidadEst() %>')">
                            ✏️
                        </button>
                        <button class="btn btn-danger btn-sm"
                          onclick="confirmarEliminarOT(<%= ot.getIdOt() %>, '<%= ot.getCodigoOt() %>')">
                          🗑
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

<!-- ── Modal Cambio de Estado (sin cambios) ── -->
<div class="overlay" id="modalEstado">
  <div class="modal">
    <h3>🔄 Cambiar Estado – <span id="modalCodigo"></span></h3>
    <form method="post" action="<%= request.getContextPath() %>/ordenes-trabajo">
      <input type="hidden" name="accion" value="cambiarEstado">
      <input type="hidden" name="idOt" id="modalIdOt">
      <label style="font-size:.85rem; color:#555; margin-bottom:.4rem; display:block;">Nuevo estado:</label>
      <select name="nuevoEstado" id="modalNuevoEstado">
        <option value="CREADA">CREADA</option>
        <option value="EN_PROCESO">EN PROCESO</option>
        <option value="FINALIZADA">FINALIZADA</option>
        <option value="ANULADA">ANULADA</option>
      </select>
      <div class="modal-botones">
        <button type="button" class="btn btn-cancelar" onclick="cerrarModalEstado()">Cancelar</button>
        <button type="submit" class="btn btn-primary">Guardar cambio</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay-ot" id="overlayEditarOT">
  <div class="modal-ot">
    <div class="modal-ot-header">
      <h3>✏️ Editar Orden de Trabajo</h3>
      <button type="button" class="modal-ot-close" onclick="cerrarModalEditarOT()">✕</button>
    </div>
    <form method="post" action="${pageContext.request.contextPath}/ordenes-trabajo" onsubmit="return validarFormEditarOT()">
      <div class="modal-ot-body">
        <input type="hidden" name="accion" value="editar">
        <input type="hidden" name="idOt" id="editIdOt">
        <div id="editAlertaError" class="alerta-err-modal" style="display:none;"></div>
        <div class="form-group">
          <label>Cliente <span class="req">*</span></label>
          <input type="text" name="cliente" id="editCliente" maxlength="150">
        </div>
        <div class="form-group">
          <label>Modelo / Prenda <span class="req">*</span></label>
          <select name="idModelo" id="editModeloSelect" onchange="toggleOtroModeloEdicion()">
            <option value="">-- Selecciona un modelo --</option>
            <% if (modelosPrenda != null) for (ModeloPrenda mp : modelosPrenda) { %>
              <option value="<%= mp.getIdModelo() %>"><%= mp.getNombre() %></option>
            <% } %>
          </select>
          <div id="editCampoOtroModelo" style="display:none; margin-top:.8rem;">
            <input type="text" id="editModeloOtro" placeholder="Ingresa el nombre del modelo" maxlength="100">
          </div>
        </div>
        <div class="form-group">
          <label>Cantidad Estimada <span class="req">*</span></label>
          <input type="number" name="cantidadEst" id="editCantidad" min="1" max="99999">
        </div>
      </div>
      <div class="modal-ot-footer">
        <button type="button" class="btn-ot-cancelar" onclick="cerrarModalEditarOT()">↩ Cancelar</button>
        <button type="submit" class="btn-ot-crear">💾 Guardar Cambios</button>
      </div>
    </form>
  </div>
</div>      
      
<!-- ══ MODAL FLOTANTE NUEVA ORDEN DE TRABAJO ══ -->
<div class="overlay-ot" id="overlayOT">
  <div class="modal-ot">
    <div class="modal-ot-header">
      <h3>📝 Nueva Orden de Trabajo</h3>
      <button type="button" class="modal-ot-close" onclick="cerrarModalOT()">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/ordenes-trabajo"
          onsubmit="return validarFormOT()" id="formOT">
      <div class="modal-ot-body">
        <input type="hidden" name="accion" value="crear">

        <div id="otAlertaError" class="alerta-err-modal" style="display:none;"></div>

        <!-- Banner código OT -->
        <div class="ot-preview">
          <div>
            <div class="lbl">Código de OT asignado automáticamente:</div>
            <div class="cod" id="codigoPreviewDisplay"><%= codigoPreview != null ? codigoPreview : "OT-2026-XXXX" %></div>
          </div>
          <div style="margin-left:auto; font-size:.75rem; color:#aac4e8; text-align:right;">
            Se generará al<br>confirmar el registro
          </div>
        </div>

        <!-- Cliente -->
        <div class="form-group">
          <label>Cliente <span class="req">*</span></label>
          <input type="text" name="cliente" id="otCliente" placeholder="Nombre del cliente o empresa" maxlength="150">
          <div class="hint">Razón social o nombre del cliente que solicita la maquila.</div>
        </div>

        <!-- Modelo de prenda -->
        <div class="form-group">
          <label>Modelo / Prenda <span class="req">*</span></label>
          <% if (modelosPrenda != null && !modelosPrenda.isEmpty()) { %>
            <select name="idModelo" id="otModelo" required>
                <option value="">-- Selecciona un modelo --</option>
                <% for (ModeloPrenda mp : modelosPrenda) { %>
                    <option value="<%= mp.getIdModelo() %>"><%= mp.getNombre() %> <%= mp.getTemporada() != null ? "(" + mp.getTemporada() + ")" : "" %></option>
                <% } %>
            </select>
          <% } else { %>
            <input type="text" name="modelo" id="otModelo" placeholder="Ej: Corset Verano 2026" maxlength="100">
            <div class="hint">No hay modelos en catálogo. Puedes ingresar el nombre manualmente.</div>
          <% } %>
        </div>

        <!-- Campo alternativo si elige "Otro" -->
        <% if (modelosPrenda != null && !modelosPrenda.isEmpty()) { %>
        <div class="form-group" id="otCampoOtroModelo" style="display:none;">
          <label>Especificar modelo <span class="req">*</span></label>
          <input type="text" id="otModeloOtro" placeholder="Ingresa el nombre del modelo" maxlength="100">
          <div class="hint">Escribe el nombre del modelo de prenda.</div>
        </div>
        <% } %>

        <!-- Cantidad estimada -->
        <div class="form-group">
          <label>Cantidad Estimada <span class="req">*</span></label>
          <input type="number" name="cantidadEst" id="otCantidad" placeholder="Ej: 500" min="1" max="99999">
          <div class="hint">Número de prendas estimadas para esta orden.</div>
        </div>

        <!-- Responsable -->
        <div class="form-group">
          <label>Responsable</label>
          <div class="info-responsable">
            👤 <strong><%= usuarioSesion.getNombreCompleto() %></strong>
            &nbsp;–&nbsp; <%= usuarioSesion.getNombreRol() %>
            <span style="margin-left:auto; font-size:.75rem; color:#777;">Asignado automáticamente</span>
          </div>
        </div>

      </div><!-- /modal-ot-body -->
      <div class="modal-ot-footer">
        <button type="button" class="btn-ot-cancelar" onclick="cerrarModalOT()">↩ Cancelar</button>
        <button type="submit" class="btn-ot-crear">✅ Crear Orden de Trabajo</button>
      </div>
    </form>
  </div>
</div>

<script>
  /* ── Modal cambio estado ── */
  function abrirModalEstado(idOt, codigo, estadoActual) {
    document.getElementById('modalIdOt').value = idOt;
    document.getElementById('modalCodigo').textContent = codigo;
    document.getElementById('modalNuevoEstado').value  = estadoActual;
    document.getElementById('modalEstado').classList.add('activo');
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
    el.textContent = '❌ ' + msg;
    el.style.display = '';
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
      var form = document.createElement('form'); form.method = 'POST';
      form.action = '<%= request.getContextPath() %>/ordenes-trabajo';
      form.innerHTML = '<input type="hidden" name="accion" value="eliminar"><input type="hidden" name="idOt" value="' + idOt + '">';
      document.body.appendChild(form); form.submit();
    }
  }
  
  // ===== Búsqueda avanzada de Órdenes de Trabajo (texto, estado, fechas) =====

    // Referencias a los elementos del filtro
    var inputBusqueda   = document.getElementById('busquedaOT');
    var selectEstado    = document.getElementById('busquedaEstado');
    var inputFechaIni   = document.getElementById('busquedaFechaIni');
    var inputFechaFin   = document.getElementById('busquedaFechaFin');

    // Función principal que aplica todos los filtros a la tabla
    function aplicarFiltrosOT() {
      var texto    = inputBusqueda.value.toLowerCase().trim();
      var estado   = selectEstado.value;
      var fechaIni = inputFechaIni.value;   // formato yyyy-MM-dd
      var fechaFin = inputFechaFin.value;

      var filas = document.querySelectorAll('table tbody tr');
      filas.forEach(function(tr) {
        // Saltar fila de "sin datos"
        if (tr.querySelector('.sin-datos')) return;

        // Columnas: 0→#, 1→Código OT, 2→Cliente, 3→Modelo, 5→Estado, 7→Fecha Creación
        var codigo  = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var cliente = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
        var modelo  = tr.cells[3] ? tr.cells[3].textContent.toLowerCase() : '';
        var estadoTd = tr.cells[5] ? tr.cells[5].textContent.trim() : '';
        var fechaTxt = tr.cells[7] ? tr.cells[7].textContent.trim() : '';

        // 1. Filtro textual (código, cliente, modelo)
        if (texto && !codigo.includes(texto) && !cliente.includes(texto) && !modelo.includes(texto)) {
          tr.style.display = 'none';
          return;
        }

        // 2. Filtro por estado
        if (estado && estadoTd !== estado) {
          tr.style.display = 'none';
          return;
        }

        // 3. Filtro por rango de fechas
        if (fechaIni || fechaFin) {
          // Parsear la fecha de la celda (formato dd/MM/yyyy HH:mm)
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

        // Si pasó todos los filtros, mostrar
        tr.style.display = '';
      });
    }

    // Asignar eventos a cada control
    inputBusqueda.addEventListener('keyup', aplicarFiltrosOT);
    selectEstado.addEventListener('change', aplicarFiltrosOT);
    inputFechaIni.addEventListener('input', aplicarFiltrosOT);
    inputFechaFin.addEventListener('input', aplicarFiltrosOT);

    // Limpiar todos los filtros
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
