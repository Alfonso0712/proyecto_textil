<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario, java.util.Set" %>
<%
    /* ── Protección de sesión ─────────────────────────────── */
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    String rol = usuarioSesion.getNombreRol().toUpperCase();

    // Permisos cargados en sesión desde LoginServlet (HU09)
    @SuppressWarnings("unchecked")
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new java.util.HashSet<>();

    // Helper: ¿tiene el permiso dado?
    final Set<String> permsFinal = permisos;

    // Mensaje de error de acceso
    String errorAcceso = request.getParameter("error");

    // ── Menú dinámico: se construye según permisos ───────────
    // Cada sección del menú solo aparece si tiene al menos un permiso de ese módulo
    boolean verSeguridad   = permsFinal.contains("SEG_USUARIOS_VER");
    boolean verAlmacen     = permsFinal.contains("ALM_TELA_VER");
    boolean verProduccion  = permsFinal.contains("PROD_OT_VER");
    boolean verCalidad     = permsFinal.contains("CAL_DEFECTOS_VER");
    boolean verDespacho    = permsFinal.contains("DES_CONCIL_VER");
    boolean verReportes    = permsFinal.contains("RPT_MERMAS_CALIDAD");
    boolean verDashboard   = permsFinal.contains("RPT_DASHBOARD");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard – Sistema Textil</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5;
           display: flex; min-height: 100vh; }

    aside { width: 240px; background: #1a1a2e; color: #ccc;
            display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 1.5rem 1.2rem; border-bottom: 1px solid #2d2d50;
                    color: #e2b96f; font-weight: 700; font-size: 1rem; }
    .sidebar-logo span { display: block; font-size: .72rem; color: #888; margin-top: .2rem; }
    nav a { display: flex; align-items: center; gap: .65rem; padding: .7rem 1.3rem;
            color: #bbb; text-decoration: none; font-size: .88rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: #0f3460; color: #fff; }
    nav .separador { padding: .4rem 1.3rem; font-size: .7rem; color: #555;
                     text-transform: uppercase; margin-top: .6rem; }

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem;
             display: flex; align-items: center; justify-content: space-between;
             box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    header h2 { font-size: 1rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .8rem; font-size: .85rem; color: #555; }
    .badge-rol { background: #0f3460; color: #fff; padding: .25rem .7rem;
                 border-radius: 20px; font-size: .73rem; font-weight: 600; }
    .btn-salir { padding: .3rem .8rem; border: 1.5px solid #e74c3c; color: #e74c3c;
                 border-radius: 6px; background: transparent; cursor: pointer;
                 font-size: .8rem; transition: all .2s; text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }

    .contenido { flex: 1; padding: 1.5rem; overflow-y: auto; }

    /* Alerta sin permisos */
    .alerta-warn { background: #fff3cd; color: #856404; border: 1px solid #ffc107;
                   padding: .7rem 1rem; border-radius: 8px; margin-bottom: 1.2rem;
                   font-size: .85rem; }

    /* Bienvenida */
    .bienvenida { background: linear-gradient(135deg, #1a1a2e, #0f3460);
                  color: #fff; border-radius: 14px; padding: 1.6rem 2rem;
                  margin-bottom: 1.5rem; }
    .bienvenida h2 { font-size: 1.25rem; margin-bottom: .3rem; }
    .bienvenida p  { font-size: .85rem; color: #aac4e8; }

    /* Cards de módulos */
    .grid-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
                  gap: 1.1rem; }
    .card-modulo { background: #fff; border-radius: 12px; padding: 1.3rem 1.4rem;
                   box-shadow: 0 2px 8px rgba(0,0,0,.07); cursor: pointer;
                   transition: transform .15s, box-shadow .15s;
                   text-decoration: none; display: block; border-top: 4px solid transparent; }
    .card-modulo:hover { transform: translateY(-3px); box-shadow: 0 6px 18px rgba(0,0,0,.12); }
    .card-modulo .ico { font-size: 2rem; margin-bottom: .6rem; }
    .card-modulo h4 { font-size: .9rem; color: #1a1a2e; margin-bottom: .2rem; }
    .card-modulo p  { font-size: .75rem; color: #777; }
    .c-seg  { border-top-color: #8e44ad; }
    .c-alm  { border-top-color: #2980b9; }
    .c-prod { border-top-color: #16a085; }
    .c-cal  { border-top-color: #e67e22; }
    .c-des  { border-top-color: #27ae60; }
    .c-rpt  { border-top-color: #e74c3c; }

    .sin-modulos { color: #aaa; font-size: .9rem; padding: 1.5rem 0; }
  </style>
</head>
<body>

<!-- ── Sidebar (menú dinámico por permisos) ── -->
<aside>
  <div class="sidebar-logo">🧵 Textil Control<span>Sistema de Producción</span></div>
  <nav>
    <div class="separador">Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard" class="activo">🏠 Inicio</a>

    <% if (verSeguridad) { %>
    <div class="separador">Seguridad</div>
    <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
    <% } %>

    <% if (verAlmacen) { %>
    <div class="separador">Almacén</div>
    <a href="<%= request.getContextPath() %>/inventario">📦 Tela Recibida</a>
    <% } %>

    <% if (verProduccion) { %>
    <div class="separador">Producción</div>
    <a href="#">📋 Órdenes de Trabajo</a>
    <a href="#">⏱️ Tiempos de Reposo</a>
    <a href="#">✂️ Mermas</a>
    <a href="#">🗂️ Cargas de Trabajo</a>
    <a href="#">🔍 Fallas de Tela</a>
    <% } %>

    <% if (verCalidad) { %>
    <div class="separador">Calidad</div>
    <a href="#">🔎 Defectos y Reprocesos</a>
    <% } %>

    <% if (verDespacho) { %>
    <div class="separador">Despacho</div>
    <a href="#">📤 Conciliación y Despacho</a>
    <% } %>

    <% if (verReportes) { %>
    <div class="separador">Reportes</div>
    <a href="#">📊 Mermas y Calidad</a>
    <% } %>
  </nav>
</aside>

<!-- ── Main ── -->
<main>
  <header>
    <h2>🏠 Dashboard</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge-rol"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Cerrar sesión</a>
    </div>
  </header>

  <div class="contenido">

    <!-- Aviso de acceso denegado -->
    <% if ("sinPermiso".equals(errorAcceso)) { %>
      <div class="alerta-warn">
        ⚠️ No tienes permiso para acceder al módulo solicitado. Contacta al administrador.
      </div>
    <% } else if ("acceso".equals(errorAcceso)) { %>
      <div class="alerta-warn">
        🚫 Acceso restringido. Esta sección requiere privilegios de administrador.
      </div>
    <% } %>

    <!-- Bienvenida -->
    <div class="bienvenida">
      <h2>👋 Bienvenido, <%= usuarioSesion.getNombre() %></h2>
      <p>Rol: <strong><%= usuarioSesion.getNombreRol() %></strong> &nbsp;|&nbsp;
         Sistema de Control de Producción Textil</p>
    </div>

    <!-- Cards de módulos según permisos -->
    <div class="grid-cards">

      <% if (verSeguridad) { %>
      <a href="<%= request.getContextPath() %>/gestion-usuarios" class="card-modulo c-seg">
        <div class="ico">👥</div>
        <h4>Gestión de Usuarios</h4>
        <p>Crear, editar y desactivar cuentas</p>
      </a>
      <% } %>

      <% if (verAlmacen) { %>
      <a href="<%= request.getContextPath() %>/inventario" class="card-modulo c-alm">
        <div class="ico">📦</div>
        <h4>Almacén</h4>
        <p>Control de tela recibida</p>
      </a>
      <% } %>

      <% if (verProduccion) { %>
      <a href="#" class="card-modulo c-prod">
        <div class="ico">⚙️</div>
        <h4>Producción</h4>
        <p>Órdenes, tiempos y cargas de trabajo</p>
      </a>
      <% } %>

      <% if (verCalidad) { %>
      <a href="#" class="card-modulo c-cal">
        <div class="ico">✅</div>
        <h4>Calidad</h4>
        <p>Defectos, reprocesos e inspección</p>
      </a>
      <% } %>

      <% if (verDespacho) { %>
      <a href="#" class="card-modulo c-des">
        <div class="ico">📤</div>
        <h4>Despacho</h4>
        <p>Conciliación final y notas de envío</p>
      </a>
      <% } %>

      <% if (verReportes) { %>
      <a href="#" class="card-modulo c-rpt">
        <div class="ico">📊</div>
        <h4>Reportes</h4>
        <p>Mermas y calidad histórica</p>
      </a>
      <% } %>

      <% if (!verSeguridad && !verAlmacen && !verProduccion
              && !verCalidad && !verDespacho && !verReportes) { %>
      <p class="sin-modulos">
        ℹ️ No tienes módulos asignados. Contacta al administrador del sistema.
      </p>
      <% } %>

    </div>
  </div>
</main>

</body>
</html>
