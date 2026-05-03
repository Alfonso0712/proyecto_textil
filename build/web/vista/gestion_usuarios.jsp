<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, java.util.List" %>
<%
    /* ── Protección de sesión ───────────────────────────────── */
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!"ADMINISTRADOR".equalsIgnoreCase(sesion.getNombreRol())) {
        response.sendRedirect(request.getContextPath() + "/dashboard?error=acceso"); return;
    }

    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    String msgExito = request.getParameter("exito");
    String msgError = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Gestión de Usuarios – Sistema Textil</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5;
           display: flex; min-height: 100vh; }

    /* ── Sidebar ── */
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

    /* ── Main ── */
    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .85rem 1.5rem;
             display: flex; align-items: center; justify-content: space-between;
             box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff;
             padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c;
                 border-radius: 6px; background: transparent; cursor: pointer;
                 font-size: .78rem; transition: all .2s; text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }

    /* ── Contenido ── */
    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }
    .page-title { display: flex; align-items: center; justify-content: space-between;
                  margin-bottom: 1.2rem; }
    .page-title h3 { font-size: 1.1rem; color: #1a1a2e; }
    .btn-nuevo { padding: .45rem 1.1rem; background: #0f3460; color: #fff;
                 border: none; border-radius: 8px; cursor: pointer; font-size: .85rem;
                 text-decoration: none; transition: background .2s; }
    .btn-nuevo:hover { background: #1a5ca8; }

    /* ── Alertas ── */
    .alerta { padding: .7rem 1.1rem; border-radius: 8px; margin-bottom: 1rem;
              font-size: .85rem; font-weight: 500; }
    .alerta-ok    { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .alerta-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }

    /* ── Tabla ── */
    .card { background: #fff; border-radius: 12px; padding: 1.2rem;
            box-shadow: 0 2px 8px rgba(0,0,0,.07); }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; color: #555; font-weight: 600;
         padding: .75rem 1rem; text-align: left; border-bottom: 2px solid #eee; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; color: #333; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #fafbfc; }

    /* Badge de rol */
    .badge-rol { padding: .22rem .6rem; border-radius: 20px;
                 font-size: .7rem; font-weight: 600; color: #fff; display: inline-block; }
    .r1 { background: #8e44ad; } /* ADMINISTRADOR */
    .r2 { background: #2980b9; } /* JEFE_ALMACEN */
    .r3 { background: #16a085; } /* JEFE_PRODUCCION */
    .r4 { background: #d35400; } /* TIZADOR */
    .r5 { background: #27ae60; } /* SUPERVISOR */
    .r6 { background: #7f8c8d; } /* MAQUINISTA */

    /* Estado */
    .chip { padding: .18rem .55rem; border-radius: 20px;
            font-size: .7rem; font-weight: 600; display: inline-block; }
    .activo   { background: #d4edda; color: #155724; }
    .inactivo { background: #f8d7da; color: #721c24; }

    /* Botones de acción */
    .btn-accion { padding: .28rem .65rem; border: none; border-radius: 6px;
                  cursor: pointer; font-size: .75rem; font-weight: 600;
                  text-decoration: none; transition: all .15s; }
    .btn-editar   { background: #ffc107; color: #1a1a2e; }
    .btn-editar:hover { background: #e0a800; }
    .btn-deact    { background: #e74c3c; color: #fff; }
    .btn-deact:hover  { background: #c0392b; }
    .btn-actv     { background: #27ae60; color: #fff; }
    .btn-actv:hover   { background: #229954; }

    .sin-datos { text-align: center; color: #aaa; padding: 2rem; font-size: .9rem; }
  </style>
</head>
<body>

<!-- ── Sidebar ── -->
<aside>
  <div class="logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
    <div class="sep">Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard">🏠 Dashboard</a>
    <div class="sep">Seguridad</div>
    <a href="<%= request.getContextPath() %>/gestion-usuarios" class="activo">👥 Usuarios</a>
    <div class="sep">Módulos</div>
    <a href="<%= request.getContextPath() %>/inventario">📦 Almacén</a>
    <a href="#">⚙️ Producción</a>
    <a href="#">✅ Calidad</a>
    <a href="#">📊 Reportes</a>
  </nav>
</aside>

<!-- ── Main ── -->
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

    <!-- Mensajes -->
    <% if (msgExito != null) { %>
      <div class="alerta alerta-ok">✅ <%= java.net.URLDecoder.decode(msgExito, "UTF-8") %></div>
    <% } %>
    <% if (msgError != null) { %>
      <div class="alerta alerta-error">❌ <%= java.net.URLDecoder.decode(msgError, "UTF-8") %></div>
    <% } %>

    <div class="page-title">
      <h3>Lista de Usuarios (<%= usuarios != null ? usuarios.size() : 0 %> registros)</h3>
      <a href="<%= request.getContextPath() %>/gestion-usuarios?accion=nuevo" class="btn-nuevo">
        + Nuevo Usuario
      </a>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Username</th>
            <th>Nombre completo</th>
            <th>Email</th>
            <th>Rol</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% if (usuarios == null || usuarios.isEmpty()) { %>
            <tr><td colspan="7" class="sin-datos">No hay usuarios registrados.</td></tr>
          <% } else {
               int i = 1;
               for (Usuario u : usuarios) {
                 String claseRol = "r" + u.getIdRol();
          %>
          <tr>
            <td><%= i++ %></td>
            <td><strong><%= u.getUsername() %></strong></td>
            <td><%= u.getNombreCompleto() %></td>
            <td><%= u.getEmail() %></td>
            <td><span class="badge-rol <%= claseRol %>"><%= u.getNombreRol() %></span></td>
            <td>
              <span class="chip <%= u.isActivo() ? "activo" : "inactivo" %>">
                <%= u.isActivo() ? "Activo" : "Inactivo" %>
              </span>
            </td>
            <td>
              <!-- Editar -->
              <a href="<%= request.getContextPath() %>/gestion-usuarios?accion=editar&id=<%= u.getIdUsuario() %>"
                 class="btn-accion btn-editar">✏️ Editar</a>

              <!-- Desactivar / Activar -->
              <% if (u.isActivo()) { %>
                <form method="post"
                      action="<%= request.getContextPath() %>/gestion-usuarios"
                      style="display:inline;"
                      onsubmit="return confirm('¿Desactivar la cuenta de <%= u.getUsername() %>?')">
                  <input type="hidden" name="accion" value="desactivar">
                  <input type="hidden" name="id"     value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-deact">🚫 Desactivar</button>
                </form>
              <% } else { %>
                <form method="post"
                      action="<%= request.getContextPath() %>/gestion-usuarios"
                      style="display:inline;">
                  <input type="hidden" name="accion" value="activar">
                  <input type="hidden" name="id"     value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-actv">✅ Activar</button>
                </form>
              <% } %>
            </td>
          </tr>
          <% }} %>
        </tbody>
      </table>
    </div>

  </div>
</main>

</body>
</html>
