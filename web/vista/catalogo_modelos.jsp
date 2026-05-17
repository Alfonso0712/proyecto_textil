<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ModeloPrenda, modelo.PiezaModelo, java.util.List, modelo.Usuario, java.util.Set, java.util.HashSet" %>
<%
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

    List<ModeloPrenda> modelos = (List<ModeloPrenda>) request.getAttribute("modelos");

    // ✅ FIX: leer el modelo a editar que ya pone el servlet
    ModeloPrenda modeloEditar = (ModeloPrenda) request.getAttribute("modeloEditar");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Catálogo de Modelos</title>
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

    .chip { display: inline-block; padding: .25rem .7rem; border-radius: 20px; font-size: .7rem; font-weight: 600; background: #e1effe; color: #1e429f; }
    .btn-accion {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 5px;
        min-width: 80px;          /* todos igual de anchos */
        padding: 0 10px;
        height: 30px;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: .75rem;
        font-weight: 600;
        color: #fff;
        text-decoration: none;
        transition: background-color 0.2s, filter 0.2s;
    }

    .btn-ver {
        background: #17a2b8;
    }
    .btn-ver:hover {
        background: #0f7a8a;      /* oscurece */
    }

    .btn-editar {
        background: #ffc107;
        color: #1a1a2e;           /* el texto oscuro ya contrasta */
    }
    .btn-editar:hover {
        background: #e0a800;
    }

    .btn-eliminar {
        background: #e67e22;       /* naranja oscuro, mejor que rojo para diferenciar */
    }
    .btn-eliminar:hover {
        background: #a04000;
    }

    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 1000; }
    .modal-overlay.active { display: flex; }
    .modal-content { background: #fff; border-radius: 12px; width: 90%; max-width: 650px; padding: 1.8rem; max-height: 90vh; overflow-y:auto;}
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.2rem; border-bottom: 2px solid #f0f0f0; padding-bottom: 0.8rem; }
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; }
    input[type="text"], input[type="number"] { width: 100%; padding: .55rem .8rem; border: 1.5px solid #d1d5db; border-radius: 8px; margin-bottom: .5rem; }
    .btn-guardar { width: 100%; padding: .65rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; margin-top: 1rem;}
    /* Modal piezas */
        #modal-piezas .modal-content { max-width: 520px; }
        .tabla-piezas { width:100%; border-collapse:collapse; margin-top:.8rem; font-size:.85rem; }
        .tabla-piezas th { background:var(--primary-dark); color:#fff; padding:.55rem 1rem; text-align:left; }
        .tabla-piezas td { padding:.55rem 1rem; border-bottom:1px solid #f0f0f0; }
        .tabla-piezas tr:last-child td { border:none; }
        .cant-badge { background:#0f3460; color:#fff; border-radius:20px; padding:.2rem .65rem; font-size:.75rem; font-weight:700; }
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
      <a href="<%= request.getContextPath() %>/catalogo-telas">🧵 Catálogo de Telas</a>
      <a href="<%= request.getContextPath() %>/catalogo-modelos" class="activo">👗 Catálogo de Modelos</a>
      <% } %>

      <% if (verAlmacen) { %>
      <div class="separador">Almacén</div>
      <a href="<%= request.getContextPath() %>/inventario">📦 Tela Recibida</a>
      <% } %>

      <% if (verProduccion) { %>
      <div class="separador">Producción</div>
      <a href="#">📋 Órdenes de Trabajo</a>
      <% } %>
  </nav>
</aside>

<main>
  <header>
      <h2>👗 Catálogo de Modelos</h2>
      <div class="user-info">
        <span><%= usuarioSesion != null ? usuarioSesion.getNombreCompleto() : "Admin" %></span>
        <span class="badge">
          <%= usuarioSesion != null ? usuarioSesion.getNombreRol() : "ADMINISTRADOR" %>
        </span>
        <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
      </div>
  </header>

  <div style="padding:1.5rem; display:flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
    <h3 style="margin:0; white-space: nowrap;">Listado de Modelos</h3>
    <div style="flex: 1; display: flex; justify-content: center;">
      <div style="position: relative; width: 100%; max-width: 450px;">
        <input type="text" id="busquedaModelos"
               placeholder="Buscar por modelo o temporada..."
               style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                      border: 1.5px solid #ddd; border-radius: 8px;
                      font-size: .90rem; outline: none;">
        <span style="position: absolute; left: .6rem; top: 40%; transform: translateY(-50%);
                     color: #aaa; font-size: .9rem;">🔍</span>
      </div>
    </div>
    <button onclick="abrirModalNuevo()" class="btn-nuevo">➕ Nuevo Modelo</button>
  </div>

  <div class="card">
    <table>
      <thead>
        <tr><th>#</th><th>Modelo de Prenda</th><th>Colección / Temporada</th><th>Total Piezas</th><th>Acciones</th></tr>
      </thead>
      <tbody>
        <% if (modelos != null) { for (int i = 0; i < modelos.size(); i++) { ModeloPrenda m = modelos.get(i); %>
        <tr>
          <td><%= i + 1 %></td>
          <td><strong><%= m.getNombre() %></strong></td>
          <td><%= m.getTemporada() %></td>
          <td><span class="chip"><%= m.getTotalPiezas() %> piezas</span></td>
          <td>
            <button type="button"
                                class="btn-accion btn-ver"
                                onclick="verPiezas(<%= m.getIdModelo() %>, '<%= m.getNombre().replace("'","\\'") %>')">
                          👁️‍🗨️ Ver
                        </button>

                        <a href="<%= request.getContextPath() %>/catalogo-modelos?accion=editar&id=<%= m.getIdModelo() %>"
               class="btn-accion btn-editar">✏️ Editar</a>

            <form action="<%= request.getContextPath() %>/catalogo-modelos" method="POST" style="display:inline;"
                  onsubmit="return confirm('¿Eliminar modelo?');">
              <input type="hidden" name="accion" value="eliminar">
              <input type="hidden" name="id_modelo" value="<%= m.getIdModelo() %>">
              <button type="submit" class="btn-accion btn-eliminar">🗑 Eliminar️</button>
            </form>
          </td>
        </tr>
        <% } } %>
      </tbody>
    </table>
  </div>
</main>
<!-- NUEVO: Modal Ver Piezas -->
<div id="modal-piezas" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="piezas-titulo" style="margin:0;">👁 Piezas del Modelo</h3>
      <button class="close-modal" onclick="document.getElementById('modal-piezas').classList.remove('active')">&times;</button>
    </div>
    <div id="piezas-body">
      <p style="color:#999;text-align:center;">Cargando...</p>
    </div>
  </div>
</div>
<div id="modal-modelo" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo" style="margin:0;">👗 Ficha Técnica de Modelo</h3>
      <button class="close-modal" onclick="cerrarModal()">&times;</button>
    </div>

    <form action="<%= request.getContextPath() %>/catalogo-modelos" method="POST">
      <%-- Campos ocultos: vacío = insertar, con valor = actualizar --%>
      <input type="hidden" id="modal-id" name="id_modelo" value="">
      <input type="hidden" id="modal-accion" name="accion" value="">

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
          <div><label>Nombre Modelo <span style="color:red">*</span></label><input type="text" id="modal-nombre" name="nombre" required></div>
          <div><label>Temporada</label><input type="text" id="modal-temporada" name="temporada"></div>
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid var(--primary-dark); margin: 1.5rem 0 1rem; padding-bottom: 0.5rem;">
        <span style="font-weight:700; color:var(--primary-dark); text-transform:uppercase; font-size:0.8rem;">Estructura (Piezas)</span>
        <button type="button" class="btn-nuevo" style="padding:0.2rem 0.6rem; font-size:0.75rem;" onclick="agregarPieza('', 1)">➕ Añadir Pieza</button>
      </div>

      <div id="contenedor-piezas" style="background:#fcfcfc; border:1px solid #eee; border-radius:8px; padding:1rem; max-height:250px; overflow-y:auto;">
        <!-- Las piezas se cargan dinámicamente por JS -->
      </div>

      <button type="submit" class="btn-guardar">💾 Guardar Modelo</button>
    </form>
  </div>
</div>

<script>
  function agregarPieza(nombre, cantidad) {
      const container = document.getElementById('contenedor-piezas');
      const div = document.createElement('div');
      div.style = 'display:grid; grid-template-columns:2fr 1fr auto; gap:0.5rem; margin-bottom:0.5rem; align-items:end;';
      div.innerHTML =
        '<div>' +
          '<label style="display:block; font-size:.82rem; font-weight:600; color:#374151; margin-bottom:.3rem;">Nombre de la Pieza</label>' +
          '<input type="text" name="nombrePieza[]" placeholder="Ej: Copa izquierda" value="' + nombre + '" required style="margin:0; width:100%;">' +
        '</div>' +
        '<div>' +
          '<label style="display:block; font-size:.82rem; font-weight:600; color:#374151; margin-bottom:.3rem;">Cant. por prenda</label>' +
          '<input type="number" name="cantidadPieza[]" min="1" value="' + cantidad + '" required style="margin:0; width:100%;">' +
        '</div>' +
        '<button type="button" class="btn-accion btn-eliminar" style="width:36px; padding:0; height:36px;" onclick="this.parentElement.remove()">🗑️</button>';
      container.appendChild(div);
      container.scrollTop = container.scrollHeight;
    }

  function abrirModalNuevo() {
    document.getElementById('modal-titulo').textContent = '👗 Nuevo Modelo';
    document.getElementById('modal-id').value = '';
    document.getElementById('modal-accion').value = '';
    document.getElementById('modal-nombre').value = '';
    document.getElementById('modal-temporada').value = '';
    document.getElementById('contenedor-piezas').innerHTML = '';
    agregarPieza('', 1); // fila vacía por defecto
    document.getElementById('modal-modelo').classList.add('active');
  }

  function cerrarModal() {
      document.getElementById('modal-modelo').classList.remove('active');
      // Limpia la URL para que F5 no vuelva a abrir el modal
      history.replaceState(null, '', '<%= request.getContextPath() %>/catalogo-modelos');
  }

  <%-- ✅ FIX: si el servidor envió modeloEditar, abrir el modal con los datos precargados --%>
  <% if (modeloEditar != null) { %>
  window.addEventListener('DOMContentLoaded', function() {
    document.getElementById('modal-titulo').textContent = '✏️ Editar Modelo';
    document.getElementById('modal-id').value = '<%= modeloEditar.getIdModelo() %>';
    document.getElementById('modal-accion').value = 'actualizar';
    document.getElementById('modal-nombre').value = '<%= modeloEditar.getNombre().replace("'", "\\'") %>';
    document.getElementById('modal-temporada').value = '<%= modeloEditar.getTemporada() != null ? modeloEditar.getTemporada().replace("'", "\\'") : "" %>';

    // Cargar piezas existentes
    <% for (PiezaModelo p : modeloEditar.getPiezas()) { %>
    agregarPieza('<%= p.getNombrePieza().replace("'", "\\'") %>', <%= p.getCantidad() %>);
    <% } %>

    // Si no tiene piezas aún, agregar una fila vacía
    <% if (modeloEditar.getPiezas().isEmpty()) { %>
    agregarPieza('', 1);
    <% } %>

    document.getElementById('modal-modelo').classList.add('active');
  });
  <% } %>
  function verPiezas(id, nombre) {
      document.getElementById('piezas-titulo').textContent = '👁 ' + nombre;
      document.getElementById('piezas-body').innerHTML = '<p style="color:#999;text-align:center;padding:1rem;">Cargando...</p>';
      document.getElementById('modal-piezas').classList.add('active');

      fetch('<%= request.getContextPath() %>/catalogo-modelos?accion=verPiezas&id=' + id)
        .then(r => r.json())
        .then(piezas => {
          if (!piezas.length) {
            document.getElementById('piezas-body').innerHTML =
              '<p style="color:#999;text-align:center;padding:1rem;">Este modelo no tiene piezas registradas.</p>';
            return;
          }
          let html = '<table class="tabla-piezas"><thead><tr><th>#</th><th>Pieza</th><th style="text-align:center">Cantidad</th></tr></thead><tbody>';
          piezas.forEach((p, i) => {
            html += '<tr><td style="color:#999">' + (i+1) + '</td>' +
                    '<td><strong>' + p.nombre + '</strong></td>' +
                    '<td style="text-align:center"><span class="cant-badge">' + p.cantidad + '</span></td></tr>';
          });
          html += '</tbody></table>';
          document.getElementById('piezas-body').innerHTML = html;
        })
        .catch(() => {
          document.getElementById('piezas-body').innerHTML =
            '<p style="color:#e74c3c;text-align:center;">Error al cargar las piezas.</p>';
        });
    }
    
    // Filtro de búsqueda para el catálogo de modelos
    document.getElementById('busquedaModelos').addEventListener('keyup', function() {
      var filtro = this.value.toLowerCase().trim();
      var filas = document.querySelectorAll('table tbody tr');
      filas.forEach(function(tr) {
        // ignorar la fila de "sin datos"
        if (tr.querySelector('td[colspan]')) return;

        // Columnas: 0→#, 1→Modelo de Prenda, 2→Colección / Temporada
        var modelo = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
        var temporada = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';

        if (!filtro || modelo.includes(filtro) || temporada.includes(filtro)) {
          tr.style.display = '';
        } else {
          tr.style.display = 'none';
        }
      });
    });
</script>

</body>
</html>
