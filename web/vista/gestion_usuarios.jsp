<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, modelo.Rol, java.util.List, java.time.DayOfWeek, java.time.LocalDate, java.time.ZoneId" %>
<%
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!"ADMINISTRADOR".equalsIgnoreCase(sesion.getNombreRol())) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=acceso"); return;
    }

    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    List<Rol>     roles    = (List<Rol>)    request.getAttribute("roles");

    // Si el servlet nos redirige de vuelta al formulario (error de validacion server)
    String accionForm = (String)  request.getAttribute("accion");
    String errorForm  = (String)  request.getAttribute("error");
    Usuario uForm     = (Usuario) request.getAttribute("usuario");

    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");

    boolean abrirModal = (accionForm != null);
    boolean esEdicion  = "actualizar".equals(accionForm);
    if (uForm == null) uForm = new Usuario();
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Gestión de Usuarios – Sistema Textil</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; display: flex; min-height: 100vh; }
    aside { width: 230px; background: #1a1a2e; color: #ccc; display: flex; flex-direction: column; flex-shrink: 0; }
    .logo { padding: 1.4rem 1.2rem; border-bottom: 1px solid #2d2d50; color: #e2b96f; font-weight: 700; font-size: .95rem; }
    .logo span { display: block; font-size: .7rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .6rem; padding: .65rem 1.2rem; color: #bbb; text-decoration: none; font-size: .85rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: #0f3460; color: #fff; }
    nav .sep { padding: .3rem 1.2rem; font-size: .68rem; color: #555; text-transform: uppercase; margin-top: .5rem; }
    nav .submenu { display: none; padding-left: 1.5rem; background: #1a1a2e; }
    nav .submenu.activo { display: block; }
    nav .submenu a { padding: .5rem 1.3rem; font-size: .8rem; }
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .85rem 1.5rem; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c; border-radius: 6px; background: transparent; cursor: pointer; font-size: .78rem; transition: all .2s; text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }
    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }
    .page-title { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.2rem; }
    .page-title h3 { font-size: 1.1rem; color: #1a1a2e; }
    .btn-nuevo { padding: .45rem 1.1rem; background: #0f3460; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .85rem; transition: background .2s; }
    .btn-nuevo:hover { background: #1a5ca8; }
    .alerta { padding: .7rem 1.1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .85rem; font-weight: 500; }
    .alerta-ok    { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    .card { background: #fff; border-radius: 12px; padding: 1.2rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; color: #555; font-weight: 600; padding: .75rem 1rem; text-align: center; border-bottom: 2px solid #eee; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; color: #333; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #fafbfc; }
    .badge-rol { display: inline-block; width: 130px; text-align: center; padding: .3rem 0; border-radius: 20px; font-size: .65rem; font-weight: 700; color: #fff; text-transform: uppercase; letter-spacing: 0.5px; }
    .r1 { background: #8e44ad; } .r2 { background: #2980b9; } .r3 { background: #16a085; }
    .r4 { background: #d35400; } .r5 { background: #27ae60; } .r6 { background: #7f8c8d; }
    .chip { display: inline-block; width: 80px; text-align: center; padding: .25rem 0; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .activo   { background: #d4edda; color: #155724; }
    .inactivo { background: #f8d7da; color: #721c24; }
    .btn-accion { display: inline-flex; align-items: center; justify-content: center; gap: 5px; width: 105px; height: 32px; border: none; border-radius: 6px; cursor: pointer; font-size: .75rem; font-weight: 600; text-decoration: none; transition: all .15s; vertical-align: middle; }
    .btn-editar { background: #ffc107; color: #1a1a2e; }
    .btn-deact  { background: #e74c3c; color: #fff; }
    .btn-actv   { background: #27ae60; color: #fff; }
    td form { display: inline-block; margin: 0; padding: 0; vertical-align: middle; }
    .btn-editar:hover { background: #e0a800; }
    .btn-deact:hover  { background: #c0392b; }
    .btn-actv:hover   { background: #229954; }
    .sin-datos { text-align: center; color: #aaa; padding: 2rem; font-size: .9rem; }
    .badge-horario {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: .3rem;
    width: 260px;                /* ancho fijo para todos */
    padding: .28rem .7rem;
    border-radius: 20px;
    font-size: .72rem;
    font-weight: 600;
    white-space: nowrap;
    }
        .horario-laboral { background: #e8f4fd; color: #1565c0; border: 1px solid #b3d4f5; }
        .horario-admin   { background: #f3f3f3; color: #888;     border: 1px solid #ddd; }

        /* ── MODAL ── */
        .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.55); z-index: 1000; justify-content: center; align-items: center; padding: 1rem; }
        .overlay.activo { display: flex; }

    /* 1. Aseguramos que el modal no se salga de la pantalla */
    .modal-flotante {
        background: #fff;
        border-radius: 14px;
        width: 100%;
        max-width: 700px;
        max-height: 90vh; /* Limita la altura al 90% de la ventana */
        display: flex;
        flex-direction: column;
        overflow: hidden;
        box-shadow: 0 20px 60px rgba(0,0,0,.3);
    }

    /* 2. ¡ESTO ES LO MÁS IMPORTANTE! */
    /* El form debe ser flex para pasarle el control del scroll al body */
    #formUsuario {
        display: flex;
        flex-direction: column;
        flex: 1;         /* Ocupa todo el espacio bajo el header */
        overflow: hidden; /* Evita que el form se desborde */
    }

    /* 3. El cuerpo es el único que tiene la barra lateral */
    .modal-body {
        padding: 1.5rem 2rem;
        flex: 1;                 /* Se expande para empujar el footer al fondo */
        overflow-y: auto;        /* Muestra la barra de scroll si es necesario */
        scrollbar-gutter: stable; /* Evita saltos visuales al aparecer la barra */
        min-height: 0;           /* Obligatorio para que funcione el scroll en flex */
    }

    /* 4. El footer se queda "pegado" siempre abajo */
    .modal-footer {
        padding: 1rem 2rem;
        border-top: 1px solid #f0f0f0;
        display: flex;
        gap: .8rem;
        justify-content: flex-end;
        flex-shrink: 0;          /* Prohíbe que los botones se achiquen o oculten */
        background: #fff;
    }
    /* Personalización de la barra de scroll (opcional, estilo moderno) */
    .modal-body::-webkit-scrollbar {
        width: 8px;
    }
    .modal-body::-webkit-scrollbar-track {
        background: #f1f1f1;
        border-radius: 10px;
    }
    .modal-body::-webkit-scrollbar-thumb {
        background: #ccc;
        border-radius: 10px;
    }
    .modal-body::-webkit-scrollbar-thumb:hover {
        background: #0f3460;
    }


    .modal-header {
        background: #1a1a2e;
        padding: 1rem 1.5rem;
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-shrink: 0; /* No permite que se encoja */
    }

        .modal-header h3 { color: #e2b96f; font-size: 1rem; }
        .modal-close { background: none; border: none; color: #ccc; font-size: 1.4rem; cursor: pointer; line-height: 1; padding: 0 .2rem; }
        .modal-close:hover { color: #fff; }
        .alerta-error-modal { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; padding: .7rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .85rem; }
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .field { margin-bottom: 1rem; }
        .field.full { grid-column: 1 / -1; }
        .modal-body label { display: block; font-size: .8rem; font-weight: 600; color: #555; margin-bottom: .3rem; }
        .req { color: #e74c3c; }
        .modal-body input[type="text"],
        .modal-body input[type="email"],
        .modal-body input[type="password"],
        .modal-body select { width: 100%; padding: .55rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .88rem; color: #333; transition: border-color .2s; outline: none; }
        .modal-body input:focus, .modal-body select:focus { border-color: #0f3460; }
        .hint { font-size: .72rem; color: #999; margin-top: .25rem; }
        /* SCROLL en select de roles */
        .check-wrap { display: flex; align-items: center; gap: .5rem; padding: .55rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; }
        .check-wrap input { width: auto; }
        .check-wrap label { margin: 0; font-weight: normal; font-size: .88rem; cursor: pointer; }
        .btn-guardar { padding: .6rem 1.5rem; background: #0f3460; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .88rem; font-weight: 600; transition: background .2s; }
        .btn-guardar:hover { background: #1a5ca8; }
        .btn-cancelar-modal { padding: .6rem 1.2rem; background: #f0f0f0; color: #555; border: none; border-radius: 8px; cursor: pointer; font-size: .88rem; transition: background .2s; }
        .btn-cancelar-modal:hover { background: #e0e0e0; }
        .btn-eliminar {
            background: #e67e22;  /* naranja oscuro */
            color: #fff;
            min-width: 30px;
        }
        .btn-eliminar:hover {
            background: #a04000;  /* más oscuro al pasar el mouse */
        }
        /* Contenedor de días */
    .dias-container {
        display: flex;
        gap: 6px;
        flex-wrap: wrap;
        margin-top: 5px;
    }

    /* Estilo de cada botón de día */
    .dia-chip {
        display: flex;
        align-items: center;
        gap: 4px;
        background: #fff;
        border: 1.5px solid #ddd;
        padding: 6px 12px;
        border-radius: 8px;
        cursor: pointer;
        font-size: 0.8rem;
        font-weight: 600;
        color: #555;
        transition: all 0.2s ease;
        user-select: none;
    }

    /* Cuando el checkbox interno está marcado */
    .dia-chip:has(input:checked) {
        background: #0f3460;
        color: #fff;
        border-color: #0f3460;
    }

    .dia-chip input {
        display: none; /* Escondemos el check original */
    }

    /* Estilo para campos deshabilitados */
    input:disabled, select:disabled {
        background-color: #f5f5f5 !important;
        cursor: not-allowed;
        opacity: 0.8;
    }
    /* Estilo unificado para los campos de tiempo */
    .modal-body input[type="time"] {
        width: 100%;
        padding: 0.6rem 0.8rem;
        border: 1.5px solid #ddd;
        border-radius: 8px;
        font-size: 0.9rem;
        font-family: 'Segoe UI', sans-serif;
        color: #333;
        background-color: #fff;
        transition: all 0.2s ease;
        cursor: pointer;
        outline: none;
        /* Ajuste para que el icono del reloj se vea mejor */
        position: relative;
    }

    /* Efecto al pasar el mouse */
    .modal-body input[type="time"]:hover {
        border-color: #0f3460;
        background-color: #f9fbff;
    }

    /* Efecto al enfocar (clic) */
    .modal-body input[type="time"]:focus {
        border-color: #0f3460;
        background-color: #fff;
        box-shadow: 0 0 0 3px rgba(15, 52, 96, 0.1);
    }

    /* Mejora visual para los contenedores de hora */
    .time-field-group {
        display: flex;
        gap: 15px;
        background: #fff;
        padding: 10px;
        border-radius: 10px;
    }

    .time-wrapper {
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .time-wrapper label {
        font-size: 0.75rem;
        color: #888;
        margin-bottom: 4px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    /* Contenedor de botones en la celda */
    td .acciones-container {
        display: flex;
        gap: 8px;
        justify-content: center;
        align-items: center;
    }

    /* Estilo unificado de botones cuadrados (Imagen 2) */
    .btn-accion {
        width: 32px;             /* Ancho fijo */
        height: 32px;            /* Alto fijo */
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        border-radius: 10px;     /* Esquinas redondeadas suaves */
        cursor: pointer;
        font-size: 1.1rem;       /* Tamaño del emoji */
        padding: 0;
        transition: all 0.2s ease;
        text-decoration: none;
        vertical-align: middle;
    }

    /* Colores específicos manteniendo la coherencia */
    .btn-editar   { background: #ffc107; color: #1a1a2e; } /* Amarillo */
    .btn-deact    { background: #e74c3c; color: #fff; }    /* Rojo (Desactivar) */
    .btn-actv     { background: #27ae60; color: #fff; }    /* Verde (Activar) */
    .btn-eliminar { background: #e67e22; color: #fff; }    /* Naranja (Eliminar) */

    /* Efecto hover */
    .btn-accion:hover {
        filter: brightness(0.9);
        transform: translateY(-2px);
    }

    /* Ajuste de la columna de acciones */
    td:last-child {
        min-width: 160px;
        text-align: center;
    }
  </style>
</head>
<body>

<aside>
  <div class="logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
    <div class="sep">Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard">🏠 Dashboard</a>
    <div class="sep">Seguridad</div>
    <a href="<%= request.getContextPath() %>/gestion-usuarios" class="activo">👥 Usuarios</a>
    <div class="sep">Módulos</div>
    <a onclick="toggleCatalogosMenu(event)">📋 Catálogos</a>
    <div id="submenu-catalogos" class="submenu">
      <a href="<%= request.getContextPath() %>/catalogo-telas">🧵 Telas</a>
      <a href="<%= request.getContextPath() %>/catalogo-modelos">👗 Modelos</a>
    </div>
    <a href="<%= request.getContextPath() %>/inventario">📦 Almacén</a>
    <a href="#">⚙️ Producción</a>
    <a href="#">✅ Calidad</a>
    <a href="#">📊 Reportes</a>
    <a href="${pageContext.request.contextPath}/maquinistas">🧑‍🏭 Maquinistas</a>
    <a href="<%= request.getContextPath() %>/gestion-especialidades">🏷️ Especialidades</a>
  </nav>
</aside>

<main>
  <header>
    <h2>👥 Gestión de Usuarios y Perfiles</h2>
    <div class="user-info">
      <span><%= sesion.getNombreCompleto() %></span>
      <span class="badge"><%= sesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
    </div>
  </header>

  <div class="contenido">
    <% if (msgExito != null) { %>
      <div class="alerta alerta-ok">✅ <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div>
    <% } %>
    <% if (msgError != null) { %>
      <div class="alerta alerta-error">❌ <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div>
    <% } %>

    <div class="page-title" style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.2rem;">
        <h3 style="margin:0; white-space: nowrap;">Lista de Usuarios (<%= usuarios != null ? usuarios.size() : 0 %>)</h3>

        <!-- Contenedor de filtros -->
        <div style="flex: 1; display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; justify-content: center;">

          <!-- Búsqueda por texto -->
          <div style="position: relative; flex: 1 1 180px; max-width: 300px;">
            <input type="text" id="busquedaUsuarios"
                   placeholder="Buscar usuario..."
                   style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                          border: 1.5px solid #ddd; border-radius: 8px;
                          font-size: .82rem; outline: none;">
            <span style="position: absolute; left: .6rem; top: 50%; transform: translateY(-50%);
                         color: #aaa; font-size: .9rem;">🔍</span>
          </div>

          <!-- Filtro por Rol -->
          <select id="busquedaRol" style="padding: .45rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .82rem; background: #fff;">
            <option value="">Todos los roles</option>
            <% if (roles != null) { for (Rol r : roles) { %>
              <option value="<%= r.getNombreRol() %>"><%= r.getNombreRol() %></option>
            <% }} %>
          </select>

          <!-- Filtro por Estado -->
          <select id="busquedaEstado" style="padding: .45rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; font-size: .82rem; background: #fff;">
            <option value="">Todos los estados</option>
            <option value="Activo">Activo</option>
            <option value="Inactivo">Inactivo</option>
          </select>

          <!-- Botón limpiar filtros -->
          <button type="button" onclick="limpiarFiltrosUsuarios()" style="padding: .45rem 1rem; background: #f0f0f0; color: #555; border: 1.5px solid #ddd; border-radius: 8px; cursor: pointer; font-size: .82rem;">
            Limpiar
          </button>

        </div>

        <button type="button" class="btn-nuevo" onclick="abrirModalNuevo()">+ Nuevo Usuario</button>
    </div>
    
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>#</th><th>Username</th><th>Nombre completo</th>
            <th>Email</th><th>Rol</th><th>Horario</th><th>Estado</th><th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% if (usuarios == null || usuarios.isEmpty()) { %>
            <tr><td colspan="8" class="sin-datos">No hay usuarios registrados.</td></tr>
          <% } else { int i = 1; for (Usuario u : usuarios) { String claseRol = "r" + u.getIdRol(); %>
          <tr>
            <td><%= i++ %></td>
            <td><strong><%= u.getUsername() %></strong></td>
            <td><%= u.getNombreCompleto() %></td>
            <td><%= u.getEmail() %></td>
            <td><span class="badge-rol <%= claseRol %>"><%= u.getNombreRol() %></span></td>
            <td style="text-align:center;">
                <% if (u.isHorarioRestringido()) { %>
                  <span class="badge-horario horario-laboral">
                    🕗 <%= u.getHorarioDias() != null ? u.getHorarioDias() : "Lun-Sáb" %>
                    &nbsp;<%= u.getHorarioInicio() != null ? u.getHorarioInicio().substring(0,5) : "07:00" %> – 
                    <%= u.getHorarioFin() != null ? u.getHorarioFin().substring(0,5) : "17:00" %>
                  </span>
                <% } else { %>
                  <span class="badge-horario horario-admin">🔓 Sin restricción</span>
                <% } %>
            </td>
            <td><span class="chip <%= u.isActivo() ? "activo" : "inactivo" %>"><%= u.isActivo() ? "Activo" : "Inactivo" %></span></td>
            <td>
              <button type="button" class="btn-accion btn-editar"
                onclick="abrirModalEditar(
                  '<%= u.getIdUsuario() %>',
                  '<%= u.getUsername() %>',
                  '<%= u.getNombre() != null ? u.getNombre().replace("'","\\x27") : "" %>',
                  '<%= u.getApellido() != null ? u.getApellido().replace("'","\\x27") : "" %>',
                  '<%= u.getEmail() != null ? u.getEmail().replace("'","\\x27") : "" %>',
                  '<%= u.getIdRol() %>',
                  '<%= u.isActivo() %>',
                  '<%= u.isHorarioRestringido() %>',
                  '<%= u.getHorarioDias() != null ? u.getHorarioDias().replace("'","\\x27") : "" %>',
                  '<%= u.getHorarioInicio() != null ? u.getHorarioInicio() : "" %>',
                  '<%= u.getHorarioFin() != null ? u.getHorarioFin() : "" %>'
                )">✏️</button>
              <% if (u.isActivo()) { %>
                <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" style="display:inline;" onsubmit="return confirm('¿Desactivar la cuenta de <%= u.getUsername() %>?')">
                  <input type="hidden" name="accion" value="desactivar">
                  <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-deact">🚫</button>
                </form>
              <% } else { %>
                <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios" style="display:inline;">
                  <input type="hidden" name="accion" value="activar">
                  <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-actv">✅</button>
                </form>
              <% } %>
              <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios"
                    style="display:inline;"
                    onsubmit="return confirm('¿Eliminar definitivamente a <%= u.getUsername() %>?\nEsta acción no se puede deshacer.')">
                <input type="hidden" name="accion" value="eliminar">
                <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                <button type="submit" class="btn-accion btn-eliminar" title="Eliminar usuario">🗑</button>
              </form>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>
  </div>
</main>

<!-- ══ MODAL FLOTANTE USUARIO ══ -->
<div class="overlay" id="overlayUsuario">
  <div class="modal-flotante">
    <div class="modal-header">
      <h3 id="modalTitulo">➕ Registrar nuevo usuario</h3>
      <button type="button" class="modal-close" onclick="cerrarModal()">✕</button>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/gestion-usuarios"
          novalidate onsubmit="return validarFormularioModal()" id="formUsuario">
      <div class="modal-body">
        <div id="modalAlertaError" class="alerta-error-modal" style="display:none;"></div>
        <input type="hidden" name="accion"    id="modalAccion"    value="guardar">
        <input type="hidden" name="idUsuario" id="modalIdUsuario" value="0">
        <div class="grid-2">
          <div class="field">
            <label>Username <span class="req">*</span></label>
            <input type="text" name="username" id="modalUsername" maxlength="50" placeholder="ej: jperez">
            <span class="hint" id="hintUsername" style="display:none;">El username no puede modificarse.</span>
          </div>
          <div class="field">
            <label>Email <span class="req">*</span></label>
            <input type="email" name="email" id="modalEmail" maxlength="150" placeholder="usuario@textil.pe">
          </div>
          <div class="field">
            <label>Nombre <span class="req">*</span></label>
            <input type="text" name="nombre" id="modalNombre" maxlength="100" placeholder="Juan">
          </div>
          <div class="field">
            <label>Apellido <span class="req">*</span></label>
            <input type="text" name="apellido" id="modalApellido" maxlength="100" placeholder="Pérez">
          </div>
          <div class="field">
            <label>Contraseña <span class="req" id="reqPassword">*</span></label>
            <input type="password" name="password" id="modalPassword" maxlength="100" placeholder="Mínimo 6 caracteres">
            <span class="hint" id="hintPassword" style="display:none;">Solo completa si deseas cambiar la contraseña.</span>
          </div>
          <div class="field">
            <label>Rol <span class="req">*</span></label>
            <select name="idRol" id="modalIdRol">
              <option value="">-- Seleccionar rol --</option>
              <% if (roles != null) { for (Rol r : roles) { %>
                <option value="<%= r.getIdRol() %>"><%= r.getNombreRol() %> — <%= r.getDescripcion() %></option>
              <% }} %>
            </select>
          </div>
          <div class="field" id="campoEstado" style="display:none;">
            <label>Estado</label>
            <div class="check-wrap">
              <input type="checkbox" name="activo" id="modalActivo" value="1">
              <label for="modalActivo">Cuenta activa</label>
            </div>
          </div>
          <div class="field full" style="margin-top:1rem; border-top: 1px solid #eee; pt-3">
            <label>Configuración de Horario</label>
            <div style="display:flex; align-items:center; gap:1rem; flex-wrap:wrap; margin-bottom: 1rem;">
                
            
                <div class="check-wrap">
                    <input type="checkbox" id="modalHorarioRestringido" onchange="actualizarHiddenHorario()">
                    <!-- Este es el que realmente viaja al Servlet -->
                    <input type="hidden" name="horarioRestringidoHidden" id="modalHorarioRestringidoHidden" value="true">
                    <label for="modalHorarioRestringido">Restringir acceso por horario</label>
                </div>
            </div>

            <div id="horarioCampos" style="display:none; background: #fafbfc; padding: 15px; border-radius: 12px; border: 1px solid #edf0f2;">
                <div class="grid-2">
                    <div class="field">
                        <label>Días permitidos <span class="req">*</span></label>
                        <div class="dias-container">
                            <% String[] dias = {"LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"};
                               for(String d : dias) { %>
                                <label class="dia-chip">
                                    <input type="checkbox" class="check-dia" value="<%= d %>" onchange="actualizarInputDias()"> <%= d %>
                                </label>
                            <% } %>
                        </div>
                        <!-- Campo oculto que recibe los días para el DAO -->
                        <input type="hidden" name="horarioDias" id="modalHorarioDias">
                    </div>

                    <div class="time-field-group">
                        <div class="time-wrapper">
                            <label>Desde</label>
                            <input type="time" name="horarioInicio" id="modalHorarioInicio" step="600">
                        </div>
                        <div class="time-wrapper">
                            <label>Hasta</label>
                            <input type="time" name="horarioFin" id="modalHorarioFin" step="600">
                        </div>
                    </div>
                  </div>
                </div>
            </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-cancelar-modal" onclick="cerrarModal()">✖ Cancelar</button>
        <button type="submit" class="btn-guardar" id="btnGuardarModal">✅ Registrar usuario</button>
      </div>
    </form>
  </div>
</div>

<script>
    function toggleCatalogosMenu(e) {
      e.preventDefault();
      document.getElementById('submenu-catalogos').classList.toggle('activo');
    }

    function abrirModalNuevo() {
      document.getElementById('modalTitulo').textContent     = '➕ Registrar nuevo usuario';
      document.getElementById('btnGuardarModal').textContent = '✅ Registrar usuario';
      document.getElementById('modalAccion').value    = 'guardar';
      document.getElementById('modalIdUsuario').value = '0';
      document.getElementById('modalUsername').value  = '';
      document.getElementById('modalUsername').readOnly = false;
      document.getElementById('modalUsername').style.background = '';
      document.getElementById('hintUsername').style.display  = 'none';
      document.getElementById('modalEmail').value    = '';
      document.getElementById('modalNombre').value   = '';
      document.getElementById('modalApellido').value = '';
      document.getElementById('modalPassword').value = '';
      document.getElementById('modalPassword').placeholder = 'Mínimo 6 caracteres';
      document.getElementById('hintPassword').style.display = 'none';
      document.getElementById('reqPassword').style.display  = '';
      document.getElementById('modalIdRol').value = '';
      document.getElementById('campoEstado').style.display   = 'none';
      document.getElementById('modalAlertaError').style.display = 'none';
      
      // 1. Valores por defecto para el horario
      document.getElementById('modalHorarioRestringido').checked = true;
      document.getElementById('modalHorarioInicio').value = '07:00';
      document.getElementById('modalHorarioFin').value = '17:00';
    
      // 2. IMPORTANTE: Forzar la validación de rol al abrir
      // Esto bloqueará la casilla si el rol por defecto no es Admin
      verificarRestriccionPorRol();
    
      // 3. Seleccionar días por defecto (ej: Lun-Sáb)
      setChecksDias("LUN,MAR,MIE,JUE,VIE,SAB");
      document.getElementById('overlayUsuario').classList.add('activo');
      document.getElementById('modalUsername').focus();
    }

    function abrirModalEditar(id, username, nombre, apellido, email, idRol, activo, restringido, dias, inicio, fin) {
        document.getElementById('modalTitulo').textContent     = '✏️ Editar cuenta de usuario';
        document.getElementById('btnGuardarModal').textContent = '💾 Guardar cambios';
        document.getElementById('modalAccion').value    = 'actualizar';
        document.getElementById('modalIdUsuario').value = id;
        document.getElementById('modalUsername').value  = username;
        document.getElementById('modalUsername').readOnly = true;
        document.getElementById('modalUsername').style.background = '#f8f8f8';
        document.getElementById('hintUsername').style.display  = '';
        document.getElementById('modalEmail').value    = email;
        document.getElementById('modalNombre').value   = nombre;
        document.getElementById('modalApellido').value = apellido;
        document.getElementById('modalPassword').value = '';
        document.getElementById('modalPassword').placeholder = 'Dejar vacío para no cambiar';
        document.getElementById('hintPassword').style.display = '';
        document.getElementById('reqPassword').style.display  = 'none';
        document.getElementById('modalIdRol').value = idRol;
        document.getElementById('campoEstado').style.display  = '';
        document.getElementById('modalActivo').checked = (activo === 'true');
        document.getElementById('modalAlertaError').style.display = 'none';

        // ── Horario (nuevo) ──────────────────────────────────────
        // 1. Cargar estado de restricción
        const isRestringido = (restringido === 'true' || restringido === true);
        document.getElementById('modalHorarioRestringido').checked = isRestringido;

        // 2. Cargar horas (formato HH:mm)
        document.getElementById('modalHorarioInicio').value = (inicio || '07:00').substring(0,5);
        document.getElementById('modalHorarioFin').value = (fin || '17:00').substring(0,5);

        // 3. Seleccionar los días guardados en la base de datos
        setChecksDias(dias); 

        // 4. Aplicar restricción según el ROL
        verificarRestriccionPorRol();
        document.getElementById('overlayUsuario').classList.add('activo');
        document.getElementById('modalNombre').focus();
    }

    function cerrarModal() {
      document.getElementById('overlayUsuario').classList.remove('activo');
    }

    document.getElementById('overlayUsuario').addEventListener('click', function(e) {
      if (e.target === this) cerrarModal();
    });

    function validarFormularioModal() {
      var accion   = document.getElementById('modalAccion').value;
      var esEdicion = (accion === 'actualizar');
      var username = document.getElementById('modalUsername').value.trim();
      var email    = document.getElementById('modalEmail').value.trim();
      var nombre   = document.getElementById('modalNombre').value.trim();
      var apellido = document.getElementById('modalApellido').value.trim();
      var password = document.getElementById('modalPassword').value;
      var idRol    = document.getElementById('modalIdRol').value;

      if (!esEdicion && username.length < 4)            { mostrarErrorModal('El username debe tener al menos 4 caracteres.'); return false; }
      if (!esEdicion && password.length < 6)            { mostrarErrorModal('La contraseña debe tener al menos 6 caracteres.'); return false; }
      if (password.length > 0 && password.length < 6)  { mostrarErrorModal('La nueva contraseña debe tener al menos 6 caracteres.'); return false; }
      if (!nombre || !apellido)                         { mostrarErrorModal('Nombre y apellido son obligatorios.'); return false; }
      if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email))   { mostrarErrorModal('El email no tiene formato válido.'); return false; }
      if (!idRol)                                       { mostrarErrorModal('Debes seleccionar un rol.'); return false; }
      return true;
    }

    function mostrarErrorModal(msg) {
      var el = document.getElementById('modalAlertaError');
      el.textContent = '❌ ' + msg;
      el.style.display = '';
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    <% if (abrirModal) { %>
    window.addEventListener('DOMContentLoaded', function() {
      <% if (esEdicion) { %>
        abrirModalEditar('<%= uForm.getIdUsuario() %>','<%= uForm.getUsername() != null ? uForm.getUsername() : "" %>','<%= uForm.getNombre() != null ? uForm.getNombre() : "" %>','<%= uForm.getApellido() != null ? uForm.getApellido() : "" %>','<%= uForm.getEmail() != null ? uForm.getEmail() : "" %>','<%= uForm.getIdRol() %>','<%= uForm.isActivo() %>');
      <% } else { %>
        abrirModalNuevo();
        document.getElementById('modalUsername').value = '<%= uForm.getUsername()  != null ? uForm.getUsername()  : "" %>';
        document.getElementById('modalNombre').value   = '<%= uForm.getNombre()    != null ? uForm.getNombre()    : "" %>';
        document.getElementById('modalApellido').value = '<%= uForm.getApellido()  != null ? uForm.getApellido()  : "" %>';
        document.getElementById('modalEmail').value    = '<%= uForm.getEmail()     != null ? uForm.getEmail()     : "" %>';
        document.getElementById('modalIdRol').value    = '<%= uForm.getIdRol() %>';
      <% } %>
      <% if (errorForm != null) { %>
        mostrarErrorModal('<%= errorForm %>');
      <% } %>
    });
    <% } %>
   
   // ===== Búsqueda avanzada de Usuarios (texto, rol, estado) =====
    var inputBusquedaUsr = document.getElementById('busquedaUsuarios');
    var selectRolUsr     = document.getElementById('busquedaRol');
    var selectEstadoUsr  = document.getElementById('busquedaEstado');

    // Función que aplica todos los filtros a la tabla
    function aplicarFiltrosUsuarios() {
      var texto  = inputBusquedaUsr.value.toLowerCase().trim();
      var rol    = selectRolUsr.value;
      var estado = selectEstadoUsr.value;

      var filas = document.querySelectorAll('table tbody tr');
      filas.forEach(function(tr) {
        // Saltar fila de "sin datos"
        if (tr.querySelector('.sin-datos')) return;

        // Columnas: 0→#, 1→Username, 2→Nombre completo, 4→Rol, 6→Estado
        var username = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var nombre   = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
        var colRol   = tr.cells[4] ? tr.cells[4].textContent.trim() : '';
        var colEstado = tr.cells[6] ? tr.cells[6].textContent.trim() : '';

        // 1. Filtro textual (username, nombre)
        if (texto && !username.includes(texto) && !nombre.includes(texto)) {
          tr.style.display = 'none';
          return;
        }

        // 2. Filtro por rol (el texto dentro del span .badge-rol)
        if (rol && colRol !== rol) {
          tr.style.display = 'none';
          return;
        }

        // 3. Filtro por estado (Activo / Inactivo)
        if (estado && colEstado !== estado) {
          tr.style.display = 'none';
          return;
        }

        // Si pasó todos los filtros, mostrar
        tr.style.display = '';
      });
    }

    // Asignar eventos
    inputBusquedaUsr.addEventListener('keyup', aplicarFiltrosUsuarios);
    selectRolUsr.addEventListener('change', aplicarFiltrosUsuarios);
    selectEstadoUsr.addEventListener('change', aplicarFiltrosUsuarios);

    // Limpiar filtros
    function limpiarFiltrosUsuarios() {
      inputBusquedaUsr.value = '';
      selectRolUsr.value = '';
      selectEstadoUsr.value = '';
      aplicarFiltrosUsuarios();
    }
    function toggleCamposHorario() {
        var checkbox = document.getElementById('modalHorarioRestringido');
        var campos = document.getElementById('horarioCampos');
        if (checkbox && campos) {
          campos.style.display = checkbox.checked ? 'flex' : 'none';
        }
    }
    // Función para actualizar el input oculto con los días marcados
    function actualizarInputDias() {
        const seleccionados = Array.from(document.querySelectorAll('.check-dia:checked'))
                                   .map(cb => cb.value);
        document.getElementById('modalHorarioDias').value = seleccionados.join(',');
    }

    // Función para cargar los días en los checkboxes al abrir el modal (Editar)
    function cargarChecksDias(diasString) {
        const checks = document.querySelectorAll('.check-dia');
        checks.forEach(cb => cb.checked = false); // reset
        if (diasString) {
            const lista = diasString.split(',');
            checks.forEach(cb => {
                if (lista.includes(cb.value)) cb.checked = true;
            });
        }
        actualizarInputDias();
    }
    function setChecksDias(diasStr) {
    // Limpiar todos primero
    const todosLosChecks = document.querySelectorAll('.check-dia');
    todosLosChecks.forEach(cb => cb.checked = false);

    if (diasStr && diasStr !== 'null') {
        const listaDias = diasStr.split(',');
        todosLosChecks.forEach(cb => {
            if (listaDias.includes(cb.value.toUpperCase())) {
                cb.checked = true;
            }
        });
    }
    actualizarInputDias(); // Actualiza el input hidden 'modalHorarioDias'
}
    // Lógica de bloqueo por Rol
    document.getElementById('modalIdRol').addEventListener('change', function() {
        const textoRol = this.options[this.selectedIndex].text.toUpperCase();
        const checkRestringido = document.getElementById('modalHorarioRestringido');

        if (textoRol.includes("ADMINISTRADOR")) {
            // El administrador puede elegir si se restringe o no
            checkRestringido.disabled = false;
        } else {
            // Cualquier otro rol queda restringido obligatoriamente
            checkRestringido.checked = true;
            checkRestringido.disabled = true;
        }
        toggleCamposHorario();
    });
    function verificarRestriccionPorRol() {
    const selectRol = document.getElementById('modalIdRol');
    const checkVisible = document.getElementById('modalHorarioRestringido');
    const inputHidden = document.getElementById('modalHorarioRestringidoHidden');
    
    const textoRol = selectRol.options[selectRol.selectedIndex].text.toUpperCase();

    if (textoRol.includes("ADMINISTRADOR")) {
        checkVisible.disabled = false;
        inputHidden.value = checkVisible.checked; // Sincroniza con el check manual
    } else {
        // Bloqueo para otros roles como se ve en image_9f3bdd.png
        checkVisible.checked = true;
        checkVisible.disabled = true;
        inputHidden.value = "true"; // Siempre envía true al servidor
    }
    toggleCamposHorario();
}

// Sincronizar el hidden si un Administrador cambia el check manualmente
document.getElementById('modalHorarioRestringido').addEventListener('change', function() {
    document.getElementById('modalHorarioRestringidoHidden').value = this.checked;
});
function verificarRestriccionPorRol() {
    const selectRol = document.getElementById('modalIdRol');
    const checkVisible = document.getElementById('modalHorarioRestringido');
    const inputHidden = document.getElementById('modalHorarioRestringidoHidden');
    
    const textoRol = selectRol.options[selectRol.selectedIndex].text.toUpperCase();

    if (textoRol.includes("ADMINISTRADOR")) {
        checkVisible.disabled = false;
        // Si es admin, el valor del hidden depende de lo que el usuario marque
        inputHidden.value = checkVisible.checked ? "true" : "false";
    } else {
        // Si es Tizador/Almacén, forzamos la restricción
        checkVisible.checked = true;
        checkVisible.disabled = true;
        inputHidden.value = "true"; 
    }
    toggleCamposHorario();
}

// Esta función debe ejecutarse CADA VEZ que el admin cambie el check manualmente
function actualizarHiddenHorario() {
    const check = document.getElementById('modalHorarioRestringido');
    document.getElementById('modalHorarioRestringidoHidden').value = check.checked ? "true" : "false";
    toggleCamposHorario();
}
</script>
</body>
</html>
