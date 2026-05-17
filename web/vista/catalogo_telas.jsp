<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.CatalogoTela, java.util.List, modelo.Usuario, java.util.Set, java.util.HashSet" %>
<%
    /* 1. Recuperar sesión y permisos */
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();

    boolean verSeguridad   = permisos.contains("SEG_USUARIOS_VER");
    boolean verAlmacen     = permisos.contains("ALM_TELA_VER");
    boolean verProduccion  = permisos.contains("PROD_OT_VER");

    List<CatalogoTela> telas = (List<CatalogoTela>) request.getAttribute("telas");
        // Mensajes de éxito y error
    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");

    // ✅ FIX: leer el atributo que ahora sí envía el servlet
    CatalogoTela telaEditar = (CatalogoTela) request.getAttribute("telaEditar");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Catálogo de Telas</title>
  <style>
  header h2 { font-size: .95rem; color: #1a1a2e; }
  .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
      .badge { background: #0f3460; color: #fff;
               padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
      .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c;
                   border-radius: 6px; background: transparent; cursor: pointer;
                   font-size: .78rem; transition: all .2s; text-decoration: none; }
      .btn-salir:hover { background: #e74c3c; color: #fff; }
    :root {
            --primary-dark: #0f3460;
            --accent: #e2b96f;
            --text-main: #333;
            --bg-light: #f0f2f5;
        }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: var(--bg-light); color: var(--text-main); display: flex; min-height: 100vh; }

    aside {
            width: 240px;
            background: #1a1a2e;
            color: #ccc;
            display: flex;
            flex-direction: column;
            flex-shrink: 0;
        }

        .sidebar-logo {
            padding: 1.5rem 1.2rem;
            border-bottom: 1px solid #2d2d50;
            color: var(--accent);
            font-weight: 700;
            font-size: 1rem;
        }

        nav a {
            display: flex;
            align-items: center;
            gap: .65rem;
            padding: .7rem 1.3rem;
            color: #bbb;
            text-decoration: none;
            font-size: .88rem;
            transition: background .15s;
        }

        nav a:hover, nav a.activo {
            background: var(--primary-dark);
            color: #fff;

        }

        nav .separador {
            padding: .4rem 1.3rem;
            font-size: .7rem;
            color: #555;
            text-transform: uppercase;
            margin-top: .6rem;
        }

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem; display: flex; justify-content: space-between; box-shadow: 0 1px 4px rgba(0,0,0,.08); z-index: 10; }
    .btn-nuevo { padding: .45rem 1.1rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .85rem; }
    .card { background: #fff; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); margin: 1.5rem; overflow:auto;}
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; padding: .75rem 1rem; text-align: left; border-bottom: 2px solid #eee; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; }

    .chip {
        display: inline-block;
        padding: .25rem .7rem;
        border-radius: 20px;
        font-size: .7rem;
        font-weight: 600;
        text-align: center; /* Asegura que el texto esté al centro */
        min-width: 110px;   /* Define un ancho mínimo para que ambos sean iguales */
    }
    .activo { background: #d4edda; color: #155724; }
    .inactivo { background: #eee; color: #555; }
    .btn-accion {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 5px;
        width: auto;
        min-width: 80px;
        padding: 0 10px;
        height: 30px;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: .75rem;
        font-weight: 600;
        color: #fff;
    }
    .btn-editar {
        background: #ffc107;
        color: #1a1a2e;
    }
    .btn-editar:hover {
        background: #e0a800;        /* amarillo más oscuro */
    }

    .btn-eliminar {
        background: #e67e22;        /* naranja oscuro en lugar de rojo */
        /* se hereda min-width:80px de .btn-accion, no se sobreescribe */
    }
    .btn-eliminar:hover {
        background: #a04000;        /* aún más oscuro */
    }

    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 1000; }
    .modal-overlay.active { display: flex; }
    .modal-content { background: #fff; border-radius: 12px; width: 90%; max-width: 600px; padding: 1.8rem; }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.2rem; border-bottom: 2px solid #f0f0f0; padding-bottom: 0.8rem; }
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; }
    input[type="text"] { width: 100%; padding: .55rem .8rem; border: 1.5px solid #d1d5db; border-radius: 8px; margin-bottom: 1rem; }
    .btn-guardar { width: 100%; padding: .65rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; margin-top: 1rem;}

    /* === Panel de Reposos Activos === */
    #panel-reposos {
      position: fixed; bottom: 1.5rem; right: 1.5rem;
      width: 320px; z-index: 2000;
      display: flex; flex-direction: column; gap: .6rem;
    }
    .reposo-card {
      background: #fff; border-radius: 12px; padding: 1rem 1.2rem;
      box-shadow: 0 4px 20px rgba(0,0,0,.18);
      border-left: 4px solid #0f3460;
      animation: slideIn .3s ease;
    }
    .reposo-card.terminado { border-left-color: #16a34a; background: #f0fdf4; }
    .reposo-card.urgente   { border-left-color: #ef4444; }
    @keyframes slideIn { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
    .reposo-card h4 { font-size:.82rem; color:#0f3460; margin-bottom:.3rem; }
    .reposo-card .countdown { font-size:1.4rem; font-weight:700; font-variant-numeric: tabular-nums; color:#1a1a2e; }
    .reposo-card .countdown.urgente { color:#ef4444; }
    .reposo-card .countdown.terminado { color:#16a34a; }
    .reposo-card .btn-cerrar-card { float:right; background:none; border:none; cursor:pointer; color:#999; font-size:1rem; }

    /* Alerta modal de fin de reposo */
    #alerta-overlay {
      position:fixed; inset:0; background:rgba(0,0,0,.55);
      display:none; align-items:center; justify-content:center; z-index:3000;
    }
    #alerta-overlay.active { display:flex; }
    #alerta-box {
      background:#fff; border-radius:16px; padding:2.2rem 2rem;
      text-align:center; max-width:380px; width:90%;
      box-shadow: 0 8px 40px rgba(0,0,0,.25);
      animation: slideIn .3s ease;
    }
    .alerta { padding: .7rem 1.1rem; border-radius: 8px; margin-top: 1rem; font-size: .85rem; }
    .alerta-ok    { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    #alerta-box .icon { font-size:3rem; margin-bottom:.6rem; }
    #alerta-box h3 { color:#16a34a; margin-bottom:.5rem; }
    #alerta-box p  { color:#555; font-size:.88rem; margin-bottom:1.2rem; }
    #alerta-box button { padding:.6rem 1.8rem; background:#0f3460; color:#fff; border:none; border-radius:8px; cursor:pointer; font-size:.9rem; }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">
    🧵 Textil Control
    <span style="display:block;font-size:0.7rem;color:#888;">Sistema de Producción</span>
  </div>
  <nav>
      <div class="separador">Menú Principal</div>
      <a href="<%= request.getContextPath() %>/dashboard">🏠 Dashboard</a>

      <% if (verSeguridad) { %>
      <div class="separador">Seguridad</div>
      <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
      <% } %>

      <% if ("ADMINISTRADOR".equalsIgnoreCase(usuarioSesion.getNombreRol())) { %>
      <div class="separador">Catalogos</div>
      <a href="<%= request.getContextPath() %>/catalogo-telas" class="activo">🧵 Catálogo de Telas</a>
      <a href="<%= request.getContextPath() %>/catalogo-modelos">👗 Catálogo de Modelos</a>
      <% } %>

      <% if (verAlmacen) { %>
      <div class="separador">Almacén</div>
      <a href="<%= request.getContextPath() %>/inventario">📦 Tela Recibida</a>
      <% } %>

      <% if (verProduccion) {%>
      <div class="separador">Producción</div>
      <a href="#">📋 Órdenes de Trabajo</a>
      <% } %>
  </nav>
</aside>

<main>
<header>
  <h2>🧵 Catálogo de Telas y Materiales</h2>
  <div class="user-info">
    <span><%= usuarioSesion != null ? usuarioSesion.getNombreCompleto() : "Admin" %></span>
    <span class="badge"><%= usuarioSesion != null ? usuarioSesion.getNombreRol() : "Sin Rol" %></span>
    <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
  </div>
</header>
      <% if (msgExito != null && !msgExito.isEmpty()) { %>
      <div class="alerta alerta-ok">✅ <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div>
    <% } %>
    <% if (msgError != null && !msgError.isEmpty()) { %>
      <div class="alerta alerta-error">❌ <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div>
    <% } %>

  <div style="padding:1.5rem; display:flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
    <h3 style="margin:0; white-space: nowrap;">Listado de Materiales</h3>
    <div style="flex: 1; display: flex; justify-content: center;">
      <div style="position: relative; width: 100%; max-width: 450px; padding-top: 20px;">
        <input type="text" id="busquedaTelas"
               placeholder="Buscar por nombre del tejido o proveedor..."
               style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                      border: 1.5px solid #ddd; border-radius: 8px;
                      font-size: .85rem; outline: none;">
        <span style="position: absolute; left: .6rem; top: 50%; transform: translateY(-50%);
                     color: #aaa; font-size: .9rem;">🔍</span>
      </div>
    </div>
    <button onclick="abrirModalNuevo()" class="btn-nuevo">➕ Nuevo Material</button>
  </div>

  <div class="card">
    <table>
      <thead>
        <tr><th>#</th><th>Nombre del Tejido</th><th>Composición</th><th>Proveedor Base</th><th>Reposo</th><th>Tiempo</th><th>Acciones</th></tr>
      </thead>
      <tbody>
        <% if (telas != null) { for (int i = 0; i < telas.size(); i++) { CatalogoTela t = telas.get(i); %>
        <tr>
          <td><%= i + 1 %></td>
          <td><strong><%= t.getNombre() %></strong></td>
          <td><%= t.getComposicion() %></td>
          <td><%= t.getProveedorBase() %></td>
          <td>
            <span class="chip <%= t.isRequiereReposo() ? "activo" : "inactivo" %>">
              <%= t.isRequiereReposo() ? "Requiere Reposo" : "Sin Reposo" %>
            </span>
          </td>
          <td>
            <% if (t.isRequiereReposo() && t.getTiempoReposo() > 0) { %>
              <span style="font-size:.8rem; color:#555;">⏱ <%= t.getTiempoReposo() %> min</span><br>
              <button type="button" class="btn-accion"
                      id="btn-reposo-<%= t.getIdCatalogo() %>"
                      data-reposo-id="<%= t.getIdCatalogo() %>"
                      style="background:#0f3460; margin-top:4px; font-size:.7rem;"
                      onclick="iniciarReposo(<%= t.getIdCatalogo() %>, '<%= t.getNombre().replace("'", "\\'") %>', <%= t.getTiempoReposo() %>)">
                ▶ Iniciar Reposo
              </button>
            <% } else { %>
              <span style="color:#bbb; font-size:.78rem;">—</span>
            <% } %>
          </td>
          <td>
            <%-- ✅ FIX: usar JS para abrir el modal con datos, en lugar de navegar a otra URL --%>
            <button type="button"
                    class="btn-accion btn-editar"
                    onclick="abrirModalEditar(
                      <%= t.getIdCatalogo() %>,
                      '<%= t.getNombre().replace("'", "\\'") %>',
                      '<%= t.getComposicion().replace("'", "\\'") %>',
                      '<%= t.getProveedorBase() != null ? t.getProveedorBase().replace("'", "\\'") : "" %>',
                      <%= t.isRequiereReposo() %>,
                      <%= t.getTiempoReposo() %>
                    )">✏️ Editar</button>

            <form action="<%= request.getContextPath() %>/catalogo-telas" method="POST" style="display:inline;"
                  onsubmit="return confirm('¿Eliminar tela?');">
              <input type="hidden" name="accion" value="eliminar">
              <input type="hidden" name="id_catalogo" value="<%= t.getIdCatalogo() %>">
              <button type="submit" class="btn-accion btn-eliminar" title="Eliminar tela">🗑 Eliminar️</button>
            </form>
          </td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>
</main>

<%-- Alerta de fin de reposo --%>
<div id="alerta-overlay">
  <div id="alerta-box">
    <div class="icon">✅</div>
    <h3>¡Reposo Completado!</h3>
    <p id="alerta-msg">La tela ya está lista para el corte.</p>
    <button onclick="cerrarAlerta()">Entendido</button>
  </div>
</div>

<%-- Panel de cronómetros activos --%>
<div id="panel-reposos"></div>

<%-- Modal para NUEVO o EDITAR material --%>
<div id="modal-tela" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo" style="margin:0;">🧵 Registrar Material</h3>
      <button class="close-modal" onclick="cerrarModal()">&times;</button>
    </div>
    <form action="<%= request.getContextPath() %>/catalogo-telas" method="POST">
      <%-- Campo oculto: vacío = insertar, con valor = actualizar --%>
      <input type="hidden" id="modal-id" name="id_catalogo" value="">
      <input type="hidden" id="modal-accion" name="accion" value="">

      <label>Nombre <span style="color:red">*</span></label>
      <input type="text" id="modal-nombre" name="nombre" required>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
          <div><label>Composición <span style="color:red">*</span></label><input type="text" id="modal-composicion" name="composicion" required></div>
          <div><label>Proveedor</label><input type="text" id="modal-proveedor" name="proveedor"></div>
      </div>

      <div style="background:#f8f9fa; padding:1rem; border-radius:8px; border:1px solid #eee;">
        <div style="display:flex; gap:10px; align-items:center;">
          <input type="checkbox" name="reposo" id="chk_reposo" onchange="toggleTiempoReposo()">
          <label for="chk_reposo" style="margin:0;">Requiere tiempo de reposo antes del corte</label>
        </div>
        <div id="div-tiempo-reposo" style="display:none; margin-top:.85rem;">
          <label style="font-size:.85rem; font-weight:600; color:#0f3460;">⏱ Duración del reposo (minutos) <span style="color:red">*</span></label>
          <div style="display:flex; align-items:center; gap:.5rem; margin-top:.3rem;">
            <input type="number" id="modal-tiempo" name="tiempo_reposo" min="1" max="14400"
                   placeholder="ej: 30"
                   style="width:130px; margin-bottom:0; padding:.5rem .8rem; border:1.5px solid #d1d5db; border-radius:8px;">
            <span style="font-size:.8rem; color:#777;">min &nbsp;(max 240 h)</span>
          </div>
          <p style="font-size:.75rem; color:#888; margin-top:.4rem;">💡 Podrás iniciar el cronómetro desde la tabla y recibirás una alerta al terminar.</p>
        </div>
      </div>
      <button type="submit" class="btn-guardar">💾 Guardar Material</button>
    </form>
  </div>
</div>

<script>
  /* ===== MODAL ===== */
  function toggleTiempoReposo() {
    const chk = document.getElementById('chk_reposo');
    const div = document.getElementById('div-tiempo-reposo');
    const inp = document.getElementById('modal-tiempo');
    div.style.display = chk.checked ? 'block' : 'none';
    inp.required = chk.checked;
    if (!chk.checked) inp.value = '';
  }

  function abrirModalNuevo() {
    document.getElementById('modal-titulo').textContent = '🧵 Registrar Material';
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-accion').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-composicion').value = '';
    document.getElementById('modal-proveedor').value = '';
    document.getElementById('chk_reposo').checked = false;
    document.getElementById('modal-tiempo').value = '';
    document.getElementById('div-tiempo-reposo').style.display = 'none';
    document.getElementById('modal-tiempo').required = false;
    document.getElementById('modal-tela').classList.add('active');
  }

  function abrirModalEditar(id, nombre, composicion, proveedor, reposo, tiempoReposo) {
    document.getElementById('modal-titulo').textContent = '✏️ Editar Material';
    document.getElementById('modal-id').value = id;
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-nombre').value = nombre;
    document.getElementById('modal-composicion').value = composicion;
    document.getElementById('modal-proveedor').value = proveedor;
    document.getElementById('chk_reposo').checked = reposo;
    document.getElementById('modal-tiempo').value = tiempoReposo > 0 ? tiempoReposo : '';
    document.getElementById('div-tiempo-reposo').style.display = reposo ? 'block' : 'none';
    document.getElementById('modal-tiempo').required = reposo;
    document.getElementById('modal-tela').classList.add('active');
  }

  function cerrarModal() {
    document.getElementById('modal-tela').classList.remove('active');
  }

  /* ===== SISTEMA DE REPOSOS (localStorage) ===== */
  const STORAGE_KEY = 'reposos_activos';

  function cargarReposos() {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}; }
    catch(e) { return {}; }
  }
  function guardarReposos(obj) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(obj));
  }

  /* Habilita o deshabilita el botón "Iniciar Reposo" de una tela */
  function actualizarBoton(id, activo) {
    const btn = document.getElementById('btn-reposo-' + id);
    if (!btn) return;
    btn.disabled = activo;
    btn.style.opacity  = activo ? '0.5' : '1';
    btn.style.cursor   = activo ? 'not-allowed' : 'pointer';
    btn.textContent    = activo ? '⏳ En Reposo...' : '▶ Iniciar Reposo';
  }

  function iniciarReposo(idCatalogo, nombre, minutos) {
    const reposos = cargarReposos();
    /* Si ya hay un reposo activo el botón estará deshabilitado,
       pero por seguridad también lo verificamos aquí */
    if (reposos[idCatalogo]) return;

    reposos[idCatalogo] = {
      nombre: nombre,
      fin: Date.now() + minutos * 60 * 1000,
      minutos: minutos
    };
    guardarReposos(reposos);
    actualizarBoton(idCatalogo, true);
    renderPanel();
  }

  /* ===================================================
     renderPanel: actualiza las tarjetas EN SITIO para
     evitar que la animación se relance cada segundo.
     =================================================== */
  function renderPanel() {
    const panel   = document.getElementById('panel-reposos');
    const reposos = cargarReposos();

    /* 1. Eliminar tarjetas de reposos que ya no existen */
    panel.querySelectorAll('.reposo-card').forEach(card => {
      const id = card.id.replace('rcard-', '');
      if (!reposos[id]) card.remove();
    });

    /* 2. Recorrer reposos activos */
    for (const [id, data] of Object.entries(reposos)) {
      const restMs   = data.fin - Date.now();
      const terminado = restMs <= 0;
      const urgente   = !terminado && restMs < 5 * 60 * 1000;

      /* --- Reposo terminado: mostrar alerta y limpiar --- */
      if (terminado) {
        const cardVieja = document.getElementById('rcard-' + id);
        if (cardVieja) cardVieja.remove();

        const rep = cargarReposos();
        delete rep[id];
        guardarReposos(rep);

        actualizarBoton(id, false);   // volver a habilitar el botón
        mostrarAlerta(data.nombre);
        continue;
      }

      /* --- Formatear tiempo restante --- */
      const totalSeg = Math.ceil(restMs / 1000);
      const h = Math.floor(totalSeg / 3600);
      const m = Math.floor((totalSeg % 3600) / 60);
      const s = totalSeg % 60;
      const tiempoStr = (h > 0 ? h + 'h ' : '') +
                        String(m).padStart(2,'0') + ':' +
                        String(s).padStart(2,'0');

      /* --- Crear la tarjeta solo si NO existe todavía Y no está minimizada --- */
      let card = document.getElementById('rcard-' + id);
      if (!card && !data.minimizado) {
        card = document.createElement('div');
        card.id = 'rcard-' + id;
        card.innerHTML =
          '<button class="btn-cerrar-card" title="Ocultar (el temporizador sigue corriendo)" onclick="minimizarReposo(\'' + id + '\')">✕</button>' +
          '<h4>🧵 ' + data.nombre + '</h4>' +
          '<div class="countdown" id="cd-' + id + '"></div>' +
          '<div style="font-size:.72rem;color:#888;margin-top:.3rem;">⏳ Tiempo restante</div>';
        panel.appendChild(card);
      }

      /* --- Si está minimizado, no mostrar tarjeta --- */
      if (data.minimizado) {
        if (card) card.remove();
        actualizarBoton(id, true);
        continue;
      }

      /* --- Actualizar solo el texto del countdown (sin recrear el DOM) --- */
      card.className = 'reposo-card' + (urgente ? ' urgente' : '');
      const cd = document.getElementById('cd-' + id);
      if (cd) {
        cd.textContent = tiempoStr;
        cd.className   = 'countdown' + (urgente ? ' urgente' : '');
      }

      /* Asegurar que el botón esté deshabilitado mientras corre */
      actualizarBoton(id, true);
    }
  }

  /* Oculta la tarjeta pero el temporizador sigue corriendo en segundo plano */
  function minimizarReposo(id) {
    const rep = cargarReposos();
    if (!rep[id]) return;
    rep[id].minimizado = true;
    guardarReposos(rep);

    const card = document.getElementById('rcard-' + id);
    if (card) card.remove();
    /* El botón de la tabla sigue deshabilitado (el reposo sigue activo) */
  }

  /* Cancelar definitivamente (ya no se usa desde el panel, se puede llamar si se desea) */
  function cancelarReposo(id) {
    const rep = cargarReposos();
    delete rep[id];
    guardarReposos(rep);

    const card = document.getElementById('rcard-' + id);
    if (card) card.remove();

    actualizarBoton(id, false);
  }

  function mostrarAlerta(nombre) {
    document.getElementById('alerta-msg').textContent =
      '✅ "' + nombre + '" ha completado su tiempo de reposo y está lista para el corte.';
    document.getElementById('alerta-overlay').classList.add('active');
    if (Notification && Notification.permission === 'granted') {
      new Notification('⏰ Reposo Completado', {
        body: '"' + nombre + '" está lista para el corte.',
        icon: ''
      });
    }
  }

  function cerrarAlerta() {
    document.getElementById('alerta-overlay').classList.remove('active');
  }

  /* Pedir permiso de notificaciones al cargar */
  if (Notification && Notification.permission === 'default') {
    Notification.requestPermission();
  }

  /* Arrancar: sincronizar estado de botones con localStorage y empezar tick */
  (function init() {
    const reposos = cargarReposos();
    /* Deshabilitar botones de reposos que siguen activos tras recargar la página */
    document.querySelectorAll('[data-reposo-id]').forEach(btn => {
      const id = btn.dataset.reposoId;
      if (reposos[id]) actualizarBoton(id, true);
    });
    renderPanel();
    setInterval(renderPanel, 1000);
  })();
  // Filtro de búsqueda para el catálogo de telas
    document.getElementById('busquedaTelas').addEventListener('keyup', function() {
      var filtro = this.value.toLowerCase().trim();
      var filas = document.querySelectorAll('table tbody tr');
      filas.forEach(function(tr) {
        // Saltar fila vacía o de "sin datos"
        if (tr.querySelector('td[colspan]')) return;

        // Columnas: 0→#, 1→Nombre del Tejido, 2→Composición, 3→Proveedor Base
        var nombre = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var proveedor = tr.cells[3] ? tr.cells[3].textContent.toLowerCase() : '';

        if (!filtro || nombre.includes(filtro) || proveedor.includes(filtro)) {
          tr.style.display = '';
        } else {
          tr.style.display = 'none';
        }
      });
    });
</script>

</body>
</html>
