<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    Set<String> permisos = (Set<String>) session.getAttribute("permisosUsuario");
    if (permisos == null) permisos = new HashSet<>();
    boolean puedeGestionar = permisos.contains("PROD_MAQUINISTAS_GESTION");
    boolean puedeVer       = permisos.contains("PROD_MAQUINISTAS_VER");
    if (!puedeVer) { response.sendRedirect(request.getContextPath() + "/dashboard?error=sinPermiso"); return; }

    List<MaquinistaDTO> maquinistas = (List<MaquinistaDTO>) request.getAttribute("maquinistas");
    List<Especialidad> todasEspecialidades = (List<Especialidad>) request.getAttribute("especialidadesDisponibles");

    // Construir estructura de datos para JavaScript: Map<idUsuario, {datos, especialidades}>
    Map<Integer, String> nombresCompletos = new HashMap<>();
    Map<Integer, List<Integer>> especialidadesPorUsuario = new HashMap<>();
    if (maquinistas != null) {
        for (MaquinistaDTO dto : maquinistas) {
            int id = dto.getUsuario().getIdUsuario();
            nombresCompletos.put(id, dto.getUsuario().getNombreCompleto());
            List<Integer> idsEsp = new ArrayList<>();
            for (Especialidad e : dto.getEspecialidades()) idsEsp.add(e.getIdEspecialidad());
            especialidadesPorUsuario.put(id, idsEsp);
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Registro de Maquinistas – Sistema Textil</title>
  <style>
      .btn-modal-primario {
            flex: 1;
            padding: .55rem 1rem;
            background: var(--primary-dark);
            color: #fff;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: .88rem;
            font-weight: 600;
            text-align: center;
        }

        .btn-modal-secundario {
            flex: 1;
            padding: .55rem 1rem;
            background: #f0f0f0;
            color: #555;
            border: 1px solid #ccc;
            border-radius: 8px;
            cursor: pointer;
            font-size: .88rem;
            font-weight: 600;
            text-align: center;
        }
    /* Estilos base y sidebar (copiados de catalogo_telas.jsp) */
    :root { --primary-dark: #0f3460; --accent: #e2b96f; --bg-light: #f0f2f5; }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: var(--bg-light); display: flex; min-height: 100vh; }

    aside { width: 240px; background: #1a1a2e; color: #ccc; display: flex; flex-direction: column; flex-shrink: 0; }
    .sidebar-logo { padding: 1.5rem 1.2rem; border-bottom: 1px solid #2d2d50; color: var(--accent); font-weight: 700; font-size: 1rem; }
    nav a { display: flex; align-items: center; gap: .65rem; padding: .7rem 1.3rem; color: #bbb; text-decoration: none; font-size: .88rem; transition: background .15s; }
    nav a:hover, nav a.activo { background: var(--primary-dark); color: #fff; }
    nav .separador { padding: .4rem 1.3rem; font-size: .7rem; color: #555; text-transform: uppercase; margin-top: .6rem; }

    main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
    header { background: #fff; padding: .9rem 1.5rem; display: flex; justify-content: space-between; box-shadow: 0 1px 4px rgba(0,0,0,.08); z-index: 10; }
    header h2 { font-size: .95rem; color: #1a1a2e; }
    .user-info { display: flex; align-items: center; gap: .75rem; font-size: .82rem; color: #555; }
    .badge { background: #0f3460; color: #fff; padding: .2rem .65rem; border-radius: 20px; font-size: .7rem; font-weight: 600; }
    .btn-salir { padding: .28rem .75rem; border: 1.5px solid #e74c3c; color: #e74c3c; border-radius: 6px; background: transparent; cursor: pointer; font-size: .78rem; text-decoration: none; }
    .btn-salir:hover { background: #e74c3c; color: #fff; }

    .btn-nuevo { padding: .45rem 1.1rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: .85rem; }
    .card { background: #fff; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,.07); margin: 1.5rem; overflow: auto; }
    table { width: 100%; border-collapse: collapse; font-size: .84rem; }
    th { background: #f7f8fa; padding: .75rem 1rem; text-align: left; border-bottom: 2px solid #eee; }
    td { padding: .7rem 1rem; border-bottom: 1px solid #f0f0f0; }

    .chip {
        display: inline-block;
        min-width: 110px;          /* ancho mínimo común para todos los chips */
        text-align: center;        /* centra el texto */
        padding: .25rem .7rem;
        border-radius: 20px;
        font-size: .7rem;
        font-weight: 600;
        white-space: nowrap;       /* evita que el texto se divida en varias líneas */
    }
    .btn-accion[disabled] { opacity: 0.6; cursor: not-allowed; }
    .activo   { background: #d4edda; color: #155724; }
    .inactivo { background: #f8d7da; color: #721c24; }
    .btn-accion { display: inline-flex; align-items: center; justify-content: center; gap: 5px; width: 105px; height: 32px; border: none; border-radius: 6px; cursor: pointer; font-size: .75rem; font-weight: 600; text-decoration: none; transition: all .15s; vertical-align: middle; }
    .btn-editar { background: #ffc107; color: #1a1a2e; }
    .btn-desactivar  { background: #e74c3c; color: #fff; }
    .btn-activar   { background: #27ae60; color: #fff; }
    .btn-editar:hover { background: #e0a800; }
    .btn-desactivar:hover  { background: #c0392b; }
    .btn-activar:hover   { background: #229954; }
    /* Modal */
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 1000; }
    .modal-overlay.active { display: flex; }
    .modal-content { background: #fff; border-radius: 12px; width: 90%; max-width: 550px; padding: 1.8rem; max-height: 90vh; overflow-y: auto; }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.2rem; border-bottom: 2px solid #f0f0f0; padding-bottom: 0.8rem; }
    .close-modal { background: none; border: none; font-size: 1.5rem; cursor: pointer; }
    .modal-content label { display: block; font-size: .8rem; font-weight: 600; color: #555; margin-bottom: .3rem; }
    .modal-content input[type="text"], .modal-content input[type="email"], .modal-content input[type="password"] { width: 100%; padding: .55rem .8rem; border: 1.5px solid #d1d5db; border-radius: 8px; margin-bottom: 1rem; }
    .btn-guardar { width: 100%; padding: .65rem; background: var(--primary-dark); color: #fff; border: none; border-radius: 8px; cursor: pointer; margin-top: 1rem; font-size: .9rem; font-weight: 600; }

    .checklist { display: flex; flex-wrap: wrap; gap: 1rem; margin-top: .5rem; }
    .checklist label { display: flex; align-items: center; gap: .4rem; font-weight: normal; cursor: pointer; }
    .btn-eliminar {
        background: #e67e22;  /* naranja oscuro */
        color: #fff;
        min-width: 30px;
    }
    .btn-eliminar:hover {
        background: #a04000;  /* más oscuro al pasar el mouse */
    }
  </style>
</head>
<body>

<aside>
  <div class="sidebar-logo">🧵 Textil Control<span style="display:block;font-size:0.7rem;color:#888;">Sistema de Producción</span></div>
  <nav>
    <div class="separador">Menú Principal</div>
    <a href="<%= request.getContextPath() %>/dashboard">🏠 Dashboard</a>
    <% if (permisos.contains("SEG_USUARIOS_VER")) { %>
      <div class="separador">Seguridad</div>
      <a href="<%= request.getContextPath() %>/gestion-usuarios">👥 Usuarios</a>
    <% } %>
    <% if (permisos.contains("PROD_MAQUINISTAS_VER")) { %>
      <div class="separador">Producción</div>
      <a href="<%= request.getContextPath() %>/maquinistas" class="activo">🧑‍🏭 Maquinistas</a>
    <% } %>
  </nav>
</aside>

<main>
  <header>
    <h2>🧑‍🏭 Registro de Maquinistas y Especialidades</h2>
    <div class="user-info">
      <span><%= usuarioSesion.getNombreCompleto() %></span>
      <span class="badge"><%= usuarioSesion.getNombreRol() %></span>
      <a href="<%= request.getContextPath() %>/logout" class="btn-salir">Salir</a>
    </div>
  </header>
  
  <div style="padding:1.5rem; display:flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
    <h3 style="margin:0; white-space: nowrap;">Lista de Maquinistas</h3>
    <div style="flex: 1; display: flex; justify-content: center;">
      <div style="position: relative; width: 100%; max-width: 450px;">
        <input type="text" id="busquedaMaquinistas"
               placeholder="Buscar por username, nombre o especialidad..."
               style="width: 100%; padding: .45rem 1rem .45rem 2rem;
                      border: 1.5px solid #ddd; border-radius: 8px;
                      font-size: .85rem; outline: none;">
        <span style="position: absolute; left: .6rem; top: 50%; transform: translateY(-50%);
                     color: #aaa; font-size: .9rem;">🔍</span>
      </div>
    </div>
    <% if (puedeGestionar) { %>
      <button onclick="abrirModalNuevo()" class="btn-nuevo">➕ Nuevo Maquinista</button>
    <% } %>
  </div>
  <div class="card">
    <table>
      <thead>
        <tr><th>#</th><th>Username</th><th>Nombre completo</th><th>Especialidades</th><th>Estado</th><th>Acciones</th></tr>
      </thead>
      <tbody>
        <% if (maquinistas == null || maquinistas.isEmpty()) { %>
          <tr><td colspan="6" class="sin-datos">No hay maquinistas registrados.</td></tr>
        <% } else {
             int i = 1;
             for (MaquinistaDTO dto : maquinistas) {
               Usuario u = dto.getUsuario();
        %>
        <tr>
          <td><%= i++ %></td>
          <td><strong><%= u.getUsername() %></strong></td>
          <td><%= u.getNombreCompleto() %></td>
          <td>
            <% for (Especialidad e : dto.getEspecialidades()) { %>
              <span class="chip activo"><%= e.getNombre() %></span>
            <% } %>
          </td>
          <td><span class="chip <%= u.isActivo() ? "activo" : "inactivo" %>"><%= u.isActivo() ? "Activo" : "Inactivo" %></span></td>
          <td>
            <% if (puedeGestionar) { %>
              <button type="button" class="btn-accion btn-editar" onclick="abrirModalEditar(<%= u.getIdUsuario() %>)">✏️ Editar</button>
              <% if (u.isActivo()) { %>
                <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;" onsubmit="return confirm('¿Desactivar maquinista?')">
                  <input type="hidden" name="accion" value="desactivar">
                  <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-desactivar">🚫 Desactivar</button>
                </form>
              <% } else { %>
                <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;">
                  <input type="hidden" name="accion" value="activar">
                  <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                  <button type="submit" class="btn-accion btn-activar">✅ Activar</button>
                </form>
              <% } %>
              <form action="<%= request.getContextPath() %>/maquinistas" method="POST" style="display:inline;"
                    onsubmit="return confirm('¿Eliminar definitivamente al maquinista <%= u.getUsername() %>?')">
                <input type="hidden" name="accion" value="eliminar">
                <input type="hidden" name="id" value="<%= u.getIdUsuario() %>">
                <button type="submit" class="btn-accion btn-eliminar" title="Eliminar maquinista">🗑 Eliminar️</button>
              </form>
            <% } %>
          </td>
        </tr>
        <% }} %>
      </tbody>
    </table>
  </div>
</main>

<!-- Modal para crear/editar maquinista -->
<div id="modal-maquinista" class="modal-overlay">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modal-titulo" style="margin:0;">➕ Nuevo Maquinista</h3>
      <button class="close-modal" onclick="cerrarModalMaquinista()">&times;</button>
    </div>
    <form action="<%= request.getContextPath() %>/maquinistas" method="POST">
      <input type="hidden" id="modal-accion" name="accion" value="guardar">
      <input type="hidden" id="modal-id" name="idUsuario" value="">

      <label>Username <span style="color:red">*</span></label>
      <input type="text" id="modal-username" name="username" required>

      <label id="label-password">Contraseña <span style="color:red">*</span></label>
      <input type="password" id="modal-password" name="password" required>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">
        <div>
          <label>Nombre <span style="color:red">*</span></label>
          <input type="text" id="modal-nombre" name="nombre" required>
        </div>
        <div>
          <label>Apellido <span style="color:red">*</span></label>
          <input type="text" id="modal-apellido" name="apellido" required>
        </div>
      </div>
      <label>Email</label>
      <input type="email" id="modal-email" name="email" placeholder="ej: maquinista@textil.pe">

      <!-- Checkboxes de especialidades -->
      <fieldset style="margin-top:1.2rem; padding:1rem; border:1px solid #ddd; border-radius:8px;">
        <legend style="font-weight:600; color:#0f3460;">🏷️ Especialidades técnicas</legend>
        <div id="contenedor-especialidades" class="checklist">
          <!-- Se llena dinámicamente con JS -->
        </div>
        <button type="button" id="btn-nueva-esp" class="btn-nuevo" style="margin-top:.8rem; padding:.3rem .8rem; font-size:.8rem; background:#27ae60;" onclick="abrirModalNuevaEspecialidad()">➕ Nueva Especialidad</button>
      </fieldset>

      <button type="submit" class="btn-guardar">💾 Guardar</button>
    </form>
  </div>
</div>
<!-- Modal NUEVA ESPECIALIDAD (anidado sobre el modal de maquinista) -->
<div id="modal-especialidad" class="modal-overlay">
  <div class="modal-content" style="max-width: 400px;">
    <div class="modal-header">
      <h3 id="modal-esp-titulo">➕ Nueva Especialidad</h3>
      <button class="close-modal" onclick="cerrarModalEspecialidad()">&times;</button>
    </div>
    <form id="form-nueva-especialidad">
      <label>Nombre <span style="color:red">*</span></label>
      <input type="text" id="esp-nombre" required style="margin-bottom:1rem;">

      <label>Descripción (opcional)</label>
      <textarea id="esp-descripcion" rows="3" style="width:100%; padding:.5rem; border-radius:8px; border:1.5px solid #d1d5db; resize:vertical;"></textarea>
      <div style="display:flex; gap:.8rem; margin-top:1.2rem;">
        <button type="button" class="btn-modal-secundario" onclick="cerrarModalEspecialidad()">Cancelar</button>
        <button type="submit" class="btn-modal-primario">💾 Guardar</button>
      </div>
    </form>
  </div>
</div>
<script>
    // Datos inyectados desde JSP
    const todasEspecialidades = [
      <% for (int i = 0; i < todasEspecialidades.size(); i++) {
           Especialidad e = todasEspecialidades.get(i);
           out.print("{\"id\":" + e.getIdEspecialidad() + ",\"nombre\":\"" + e.getNombre() + "\"}");
           if (i < todasEspecialidades.size() - 1) out.print(",");
         } %>
    ];

    const maquinistasData = {
      <% int count = 0;
         for (MaquinistaDTO dto : maquinistas) {
           Usuario u = dto.getUsuario();
           out.print("\"" + u.getIdUsuario() + "\":{");
           out.print("\"username\":\"" + u.getUsername() + "\",");
           out.print("\"nombre\":\"" + u.getNombre() + "\",");
           out.print("\"apellido\":\"" + u.getApellido() + "\",");
           out.print("\"email\":\"" + (u.getEmail() != null ? u.getEmail() : "") + "\",");
           out.print("\"especialidades\":[");
           for (int j = 0; j < dto.getEspecialidades().size(); j++) {
             out.print(dto.getEspecialidades().get(j).getIdEspecialidad());
             if (j < dto.getEspecialidades().size() - 1) out.print(",");
           }
           out.print("]}");
           if (count++ < maquinistas.size() - 1) out.print(",");
         }
      %>
    };

    // Llenar checkboxes de especialidades
    function renderEspecialidades(seleccionadas) {
      const container = document.getElementById('contenedor-especialidades');
      container.innerHTML = '';
      todasEspecialidades.forEach(esp => {
        const label = document.createElement('label');
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.name = 'especialidades';
        checkbox.value = esp.id;
        if (seleccionadas && seleccionadas.includes(esp.id)) checkbox.checked = true;
        label.appendChild(checkbox);
        label.appendChild(document.createTextNode(' ' + esp.nombre));
        container.appendChild(label);
      });
    }

    // Abrir modal en modo nuevo
    function abrirModalNuevo() {
      document.getElementById('modal-titulo').textContent = '➕ Nuevo Maquinista';
      document.getElementById('modal-accion').value = 'guardar';
      document.getElementById('modal-id').value = '';
      document.getElementById('modal-username').value = '';
      document.getElementById('modal-password').value = '';
      document.getElementById('modal-nombre').value = '';
      document.getElementById('modal-apellido').value = '';
      document.getElementById('modal-email').value = '';
      document.getElementById('label-password').innerHTML = 'Contraseña <span style="color:red">*</span>';
      document.getElementById('modal-password').required = true;
      renderEspecialidades([]);
      document.getElementById('modal-maquinista').classList.add('active');
    }

    // Abrir modal en modo edición con datos precargados
    function abrirModalEditar(id) {
      const datos = maquinistasData[id];
      if (!datos) return;
      document.getElementById('modal-titulo').textContent = '✏️ Editar Maquinista';
      document.getElementById('modal-accion').value = 'actualizar';
      document.getElementById('modal-id').value = id;
      document.getElementById('modal-username').value = datos.username;
      document.getElementById('modal-password').value = '';
      document.getElementById('modal-nombre').value = datos.nombre;
      document.getElementById('modal-apellido').value = datos.apellido;
      document.getElementById('modal-email').value = datos.email;
      document.getElementById('label-password').innerHTML = 'Contraseña (dejar vacío para no cambiar)';
      document.getElementById('modal-password').required = false;
      renderEspecialidades(datos.especialidades);
      document.getElementById('modal-maquinista').classList.add('active');
    }

    function cerrarModalMaquinista() {
      document.getElementById('modal-maquinista').classList.remove('active');
    }
    // --- Manejo del modal de nueva especialidad ---
  function abrirModalNuevaEspecialidad() {
      document.getElementById('esp-nombre').value = '';
      document.getElementById('esp-descripcion').value = '';
      document.getElementById('modal-especialidad').classList.add('active');
  }

  function cerrarModalEspecialidad() {
      document.getElementById('modal-especialidad').classList.remove('active');
  }

  // Enviar formulario de nueva especialidad por AJAX
  document.getElementById('form-nueva-especialidad').addEventListener('submit', function(e) {
      e.preventDefault();
      const nombre = document.getElementById('esp-nombre').value.trim();
      const descripcion = document.getElementById('esp-descripcion').value.trim();

      if (!nombre) {
          alert('El nombre es obligatorio');
          return;
      }

      fetch('<%= request.getContextPath() %>/especialidades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ nombre: nombre, descripcion: descripcion })
      })
      .then(response => {
          if (!response.ok) throw new Error('Error de servidor');
          return response.json();
      })
      .then(data => {
          // Agregar la nueva especialidad al arreglo global
          todasEspecialidades.push({ id: data.id, nombre: data.nombre });

          // Obtener las especialidades actualmente seleccionadas en el modal principal
          const checkboxes = document.querySelectorAll('#contenedor-especialidades input[type="checkbox"]');
          const seleccionadas = Array.from(checkboxes)
                                     .filter(cb => cb.checked)
                                     .map(cb => parseInt(cb.value));

          // Agregar el nuevo ID a las seleccionadas (auto-check)
          seleccionadas.push(data.id);

          // Reconstruir los checkboxes con la lista actualizada
          renderEspecialidades(seleccionadas);

          // Cerrar el modal de especialidad
          cerrarModalEspecialidad();
      })
      .catch(error => {
          alert('Error al crear especialidad: ' + error.message);
      });
  });
  // Filtro de búsqueda en tiempo real para maquinistas
  document.getElementById('busquedaMaquinistas').addEventListener('keyup', function() {
    var filtro = this.value.toLowerCase().trim();
    var filas = document.querySelectorAll('table tbody tr');
    filas.forEach(function(tr) {
      if (tr.querySelector('.sin-datos')) return;

      var username = tr.cells[1] ? tr.cells[1].textContent.toLowerCase() : '';
      var nombreCompleto = tr.cells[2] ? tr.cells[2].textContent.toLowerCase() : '';
      // Especialidades están en la celda índice 3 como varios <span class="chip">
      var celdaEspecialidades = tr.cells[3];
      var especialidadesTexto = celdaEspecialidades ? celdaEspecialidades.textContent.toLowerCase() : '';

      if (!filtro || username.includes(filtro) || nombreCompleto.includes(filtro) || especialidadesTexto.includes(filtro)) {
        tr.style.display = '';
      } else {
        tr.style.display = 'none';
      }
    });
  });
</script>

</body>
</html>