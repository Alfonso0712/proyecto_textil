<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, modelo.Rol, java.util.List" %>
<%
    /* ── Protección de sesión ───────────────────────────────── */
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!"ADMINISTRADOR".equalsIgnoreCase(sesion.getNombreRol())) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=acceso"); return;
    }

    Usuario u      = (Usuario)      request.getAttribute("usuario");
    List<Rol> roles = (List<Rol>)   request.getAttribute("roles");
    String accion  = (String)        request.getAttribute("accion");  // guardar | actualizar
    String titulo  = (String)        request.getAttribute("titulo");
    String error   = (String)        request.getAttribute("error");
    boolean esEdicion = "actualizar".equals(accion);
    if (u == null) u = new Usuario();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= titulo %> – Sistema Textil</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5;
           display: flex; min-height: 100vh; }

    aside { width: 230px; background: #1a1a2e; color: #ccc;
            display: flex; flex-direction: column; flex-shrink: 0; }
    .logo { padding: 1.4rem 1.2rem; border-bottom: 1px solid #2d2d50;
            color: #e2b96f; font-weight: 700; font-size: .95rem; }
    .logo span { display: block; font-size: .7rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .6rem; padding: .65rem 1.2rem;
            color: #bbb; text-decoration: none; font-size: .85rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: #0f3460; color: #fff; }
    nav .sep { padding: .3rem 1.2rem; font-size: .68rem; color: #555;
               text-transform: uppercase; margin-top: .5rem; }

    main { flex: 1; display: flex; flex-direction: column; }
    header { background: #fff; padding: .85rem 1.5rem;
             display: flex; align-items: center; justify-content: space-between;
             box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem;
             border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c;
                 border-radius: 6px; background: transparent; font-size: .78rem;
                 text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }

    /* ── Formulario ── */
    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }
    .breadcrumb { font-size: .8rem; color: #888; margin-bottom: 1rem; }
    .breadcrumb a { color: #0f3460; text-decoration: none; }

    .form-card { background: #fff; border-radius: 12px; padding: 1.8rem 2rem;
                 box-shadow: 0 2px 8px rgba(0,0,0,.07); max-width: 680px; }
    .form-card h3 { font-size: 1rem; color: #1a1a2e; margin-bottom: 1.3rem;
                    padding-bottom: .6rem; border-bottom: 2px solid #f0f0f0; }

    .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb;
                    padding: .7rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .85rem; }

    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .field   { margin-bottom: 1rem; }
    .field.full { grid-column: 1 / -1; }

    label { display: block; font-size: .8rem; font-weight: 600; color: #555; margin-bottom: .3rem; }
    label .req { color: #e74c3c; }

    input[type="text"], input[type="email"],
    input[type="password"], select {
      width: 100%; padding: .55rem .8rem; border: 1.5px solid #ddd;
      border-radius: 8px; font-size: .88rem; color: #333;
      transition: border-color .2s; outline: none;
    }
    input:focus, select:focus { border-color: #0f3460; }

    .hint { font-size: .72rem; color: #999; margin-top: .25rem; }

    /* Estado (checkbox) */
    .check-wrap { display: flex; align-items: center; gap: .5rem;
                  padding: .55rem .8rem; border: 1.5px solid #ddd; border-radius: 8px; }
    .check-wrap input { width: auto; }
    .check-wrap label { margin: 0; font-weight: normal; font-size: .88rem; cursor: pointer; }

    /* Botones */
    .form-actions { display: flex; gap: .8rem; margin-top: 1.5rem; }
    .btn-guardar { padding: .6rem 1.5rem; background: #0f3460; color: #fff;
                   border: none; border-radius: 8px; cursor: pointer;
                   font-size: .88rem; font-weight: 600; transition: background .2s; }
    .btn-guardar:hover { background: #1a5ca8; }
    .btn-cancelar { padding: .6rem 1.2rem; background: #f0f0f0; color: #555;
                    border: none; border-radius: 8px; cursor: pointer;
                    font-size: .88rem; text-decoration: none; transition: background .2s; }
    .btn-cancelar:hover { background: #e0e0e0; }
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
    <a href="<%= request.getContextPath() %>/inventario">📦 Almacén</a>
  </nav>
</aside>

<main>
  <header>
    <h2><%= titulo %></h2>
    <div class="user-info">
      <span><%= sesion.getNombreCompleto() %></span>
      <span class="badge"><%= sesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
    </div>
  </header>

  <div class="contenido">
    <div class="breadcrumb">
      <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
      &rsaquo; <%= titulo %>
    </div>

    <div class="form-card">
      <h3><%= esEdicion ? "✏️ Editar cuenta de usuario" : "➕ Registrar nuevo usuario" %></h3>

      <% if (error != null) { %>
        <div class="alerta-error">❌ <%= error %></div>
      <% } %>

      <form method="post"
            action="<%= request.getContextPath() %>/gestion-usuarios"
            novalidate
            onsubmit="return validarFormulario()">

        <input type="hidden" name="accion"    value="<%= accion %>">
        <input type="hidden" name="idUsuario" value="<%= u.getIdUsuario() %>">

        <div class="grid-2">

          <!-- Username -->
          <div class="field">
            <label>Username <span class="req">*</span></label>
            <input type="text" name="username" id="username"
                   value="<%= u.getUsername() != null ? u.getUsername() : "" %>"
                   maxlength="50" placeholder="ej: jperez"
                   <%= esEdicion ? "readonly style='background:#f8f8f8;'" : "" %>>
            <% if (esEdicion) { %>
              <span class="hint">El username no puede modificarse.</span>
            <% } %>
          </div>

          <!-- Email -->
          <div class="field">
            <label>Email <span class="req">*</span></label>
            <input type="email" name="email" id="email"
                   value="<%= u.getEmail() != null ? u.getEmail() : "" %>"
                   maxlength="150" placeholder="usuario@textil.pe">
          </div>

          <!-- Nombre -->
          <div class="field">
            <label>Nombre <span class="req">*</span></label>
            <input type="text" name="nombre" id="nombre"
                   value="<%= u.getNombre() != null ? u.getNombre() : "" %>"
                   maxlength="100" placeholder="Juan">
          </div>

          <!-- Apellido -->
          <div class="field">
            <label>Apellido <span class="req">*</span></label>
            <input type="text" name="apellido" id="apellido"
                   value="<%= u.getApellido() != null ? u.getApellido() : "" %>"
                   maxlength="100" placeholder="Pérez">
          </div>

          <!-- Contraseña -->
          <div class="field">
            <label>Contraseña <% if (!esEdicion) { %><span class="req">*</span><% } %></label>
            <input type="password" name="password" id="password"
                   maxlength="100"
                   placeholder="<%= esEdicion ? "Dejar vacío para no cambiar" : "Mínimo 6 caracteres" %>">
            <% if (esEdicion) { %>
              <span class="hint">Solo completa si deseas cambiar la contraseña.</span>
            <% } %>
          </div>

          <!-- Rol -->
          <div class="field">
            <label>Rol <span class="req">*</span></label>
            <select name="idRol" id="idRol">
              <option value="">-- Seleccionar rol --</option>
              <% if (roles != null) {
                   for (Rol r : roles) { %>
                <option value="<%= r.getIdRol() %>"
                  <%= (u.getIdRol() == r.getIdRol()) ? "selected" : "" %>>
                  <%= r.getNombreRol() %> — <%= r.getDescripcion() %>
                </option>
              <% }} %>
            </select>
          </div>

          <!-- Estado (solo en edición) -->
          <% if (esEdicion) { %>
          <div class="field">
            <label>Estado</label>
            <div class="check-wrap">
              <input type="checkbox" name="activo" id="activo" value="1"
                     <%= u.isActivo() ? "checked" : "" %>>
              <label for="activo">Cuenta activa</label>
            </div>
          </div>
          <% } %>

        </div><!-- /grid-2 -->

        <div class="form-actions">
          <button type="submit" class="btn-guardar">
            <%= esEdicion ? "💾 Guardar cambios" : "✅ Registrar usuario" %>
          </button>
          <a href="<%= request.getContextPath() %>/gestion-usuarios" class="btn-cancelar">
            ✖ Cancelar
          </a>
        </div>

      </form>
    </div>
  </div>
</main>

<script>
/* Validación del lado cliente (refuerzo, la validación real está en el servidor) */
function validarFormulario() {
    const username = document.getElementById('username').value.trim();
    const email    = document.getElementById('email').value.trim();
    const nombre   = document.getElementById('nombre').value.trim();
    const apellido = document.getElementById('apellido').value.trim();
    const password = document.getElementById('password').value;
    const idRol    = document.getElementById('idRol').value;
    const esEdicion = '<%= esEdicion %>' === 'true';

    if (!esEdicion && username.length < 4) {
        alert('El username debe tener al menos 4 caracteres.'); return false;
    }
    if (!esEdicion && password.length < 6) {
        alert('La contraseña debe tener al menos 6 caracteres.'); return false;
    }
    if (password.length > 0 && password.length < 6) {
        alert('La nueva contraseña debe tener al menos 6 caracteres.'); return false;
    }
    if (!nombre || !apellido) {
        alert('Nombre y apellido son obligatorios.'); return false;
    }
    const emailReg = /^[\w.+-]+@[\w-]+\.[\w.-]+$/;
    if (!emailReg.test(email)) {
        alert('El email no tiene formato válido.'); return false;
    }
    if (!idRol) {
        alert('Debes seleccionar un rol.'); return false;
    }
    return true;
}
</script>
</body>
</html>
