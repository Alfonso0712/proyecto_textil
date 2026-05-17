<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    List<OrdenTrabajo> otsActivas = (List<OrdenTrabajo>) request.getAttribute("otsActivas");
    if (otsActivas == null) otsActivas = new ArrayList<>();

    String errorMsg = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Registrar Tela – HU01</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; padding: 1.8rem; }
    .cabecera { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
    .cabecera a { color: #0f3460; text-decoration: none; font-size: .88rem; }
    .cabecera a:hover { text-decoration: underline; }
    .cabecera h2 { color: #1a1a2e; font-size: 1.1rem; }
    .card { background: #fff; border-radius: 14px; padding: 2rem 2.2rem; max-width: 820px; box-shadow: 0 2px 12px rgba(0,0,0,.08); }
    .sec-titulo { font-size: .76rem; font-weight: 700; color: #0f3460; text-transform: uppercase;
      letter-spacing: .07em; border-bottom: 2px solid #e5e7eb; padding-bottom: .4rem;
      margin: 1.6rem 0 1rem; }
    .sec-titulo:first-of-type { margin-top: 0; }
    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    label { display: block; font-size: .82rem; font-weight: 600; color: #374151; margin-bottom: .3rem; }
    .req { color: #e74c3c; margin-left: 2px; }
    input[type="text"], input[type="number"], select, textarea {
      width: 100%; padding: .6rem .85rem; border: 1.5px solid #d1d5db;
      border-radius: 8px; font-size: .9rem; font-family: inherit;
      transition: border-color .2s; outline: none;
    }
    input:focus, select:focus, textarea:focus { border-color: #0f3460; }
    textarea { resize: vertical; min-height: 90px; }
    .hint { font-size: .74rem; color: #9ca3af; margin-top: .25rem; }

    /* Alerta peso */
    #alerta-peso { display: none; background: #fef3c7; border: 1.5px solid #f59e0b;
      color: #78350f; border-radius: 9px; padding: .65rem 1rem; font-size: .84rem;
      margin-top: .7rem; }
    #alerta-peso.activo { display: flex; align-items: center; gap: .5rem; }

    /* Checkbox */
    .check-fila { display: flex; align-items: center; gap: .6rem; padding: .6rem 0; }
    .check-fila input[type="checkbox"] { width: 18px; height: 18px; cursor: pointer; }
    .check-fila label { margin: 0; font-weight: 500; cursor: pointer; font-size: .88rem; }

    /* Upload fotos */
    .upload-area { border: 2px dashed #d1d5db; border-radius: 10px; padding: 1.5rem;
      text-align: center; background: #fafafa; transition: border-color .2s; cursor: pointer; }
    .upload-area:hover, .upload-area.drag-over { border-color: #0f3460; background: #f0f4ff; }
    .upload-area .ico { font-size: 2rem; display: block; margin-bottom: .4rem; }
    .upload-area p { font-size: .84rem; color: #6b7280; }
    .upload-area input[type="file"] { display: none; }
    #preview-fotos { display: flex; flex-wrap: wrap; gap: .6rem; margin-top: .8rem; }
    #preview-fotos img { width: 80px; height: 80px; object-fit: cover; border-radius: 8px;
      border: 2px solid #e5e7eb; }

    /* Botones */
    .fila-botones { display: flex; gap: .8rem; margin-top: 1.8rem; }
    .btn-guardar { padding: .72rem 2rem; background: #0f3460; color: #fff; border: none;
      border-radius: 8px; font-size: .95rem; font-weight: 600; cursor: pointer; }
    .btn-guardar:hover { background: #1a5276; }
    .btn-cancelar { padding: .72rem 1.5rem; background: #f3f4f6; color: #374151; border: none;
      border-radius: 8px; font-size: .95rem; cursor: pointer; text-decoration: none;
      display: inline-block; }
    .btn-cancelar:hover { background: #e5e7eb; }

    /* Error */
    .alerta-error { background: #fee2e2; border: 1px solid #fca5a5; color: #b91c1c;
      border-radius: 8px; padding: .65rem .9rem; font-size: .86rem; margin-bottom: 1.2rem; }

    /* Indicador de responsable */
    .info-registrador { background: #f8f9ff; border: 1px solid #e0e7ff; border-radius: 8px;
      padding: .65rem 1rem; font-size: .83rem; color: #374151;
      display: flex; align-items: center; gap: .5rem; }
  </style>
</head>
<body>

<div class="cabecera">
  <a href="<%= request.getContextPath() %>/inventario">← Volver al listado</a>
  <h2>📦 Registrar Ingreso de Tela
    <small style="color:#888; font-weight:400; font-size:.8rem">(HU01 – CUS 1.1 al 1.4)</small>
  </h2>
</div>

<div class="card">

  <% if (errorMsg != null) { %>
    <div class="alerta-error">⚠ <%= errorMsg %></div>
  <% } %>

  <form action="<%= request.getContextPath() %>/inventario"
        method="POST"
        enctype="multipart/form-data"
        onsubmit="return validarFormulario()">

    <!-- ══ CUS 1.1: Registrar Recepción ══ -->
    <div class="sec-titulo">📋 Orden de Trabajo Vinculada</div>
    <div class="grid-2">
      <div>
        <label for="id_ot">Orden de Trabajo (OT) <span class="req">*</span></label>
        <select id="id_ot" name="id_ot" required>
          <option value="">-- Selecciona una OT activa --</option>
          <% for (OrdenTrabajo ot : otsActivas) { %>
            <option value="<%= ot.getIdOt() %>">
              <%= ot.getCodigoOt() %> – <%= ot.getCliente() %>
            </option>
          <% } %>
          <% if (otsActivas.isEmpty()) { %>
            <option value="" disabled>No hay OTs activas disponibles</option>
          <% } %>
        </select>
        <div class="hint">Solo se muestran OTs en estado CREADA o EN_PROCESO.</div>
      </div>
      <div>
        <label>Registrado por</label>
        <div class="info-registrador">
          👤 <strong><%= sesion.getNombreCompleto() %></strong>
          &nbsp;–&nbsp; <%= sesion.getNombreRol() %>
          <span style="margin-left:auto; font-size:.73rem; color:#9ca3af;">Automático</span>
        </div>
      </div>
    </div>

    <!-- ══ Material ══ -->
    <div class="sec-titulo">🧵 Datos del Material</div>
    <div class="grid-2">
      <div>
        <label for="origen">Origen de la tela <span class="req">*</span></label>
        <select id="origen" name="origen" required>
          <option value="">-- Selecciona --</option>
          <option value="CLIENTE">Del cliente</option>
          <option value="TALLER">Adquirida por el taller</option>
        </select>
      </div>
      <div>
        <label for="proveedor">Proveedor / Razón Social</label>
        <input type="text" id="proveedor" name="proveedor"
               placeholder="Ej: Textiles Andes S.A.C." maxlength="150">
      </div>
    </div>
    <div class="grid-3" style="margin-top:1rem;">
      <div>
        <label for="tipo_tejido">Tipo de Tejido</label>
        <input type="text" id="tipo_tejido" name="tipo_tejido"
               placeholder="Ej: Elástico 4 vías" maxlength="80">
      </div>
      <div>
        <label for="color">Color</label>
        <input type="text" id="color" name="color"
               placeholder="Ej: Negro" maxlength="50">
      </div>
      <div>
        <label for="num_rollos">N.° de Rollos</label>
        <input type="number" id="num_rollos" name="num_rollos"
               min="1" value="1" max="9999">
      </div>
    </div>

    <!-- ══ CUS 1.2: Comparar Peso Real vs Guía ══ -->
    <div class="sec-titulo">⚖ Control de Peso – Guía vs Real (CUS 1.2)</div>
    <div class="grid-2">
      <div>
        <label for="peso_guia">Peso en Guía de Remisión (kg) <span class="req">*</span></label>
        <input type="number" id="peso_guia" name="peso_guia"
               step="0.001" min="0.001" placeholder="0.000" required
               oninput="calcularDiferencia()">
      </div>
      <div>
        <label for="peso_real">Peso Real Medido en Balanza (kg) <span class="req">*</span></label>
        <input type="number" id="peso_real" name="peso_real"
               step="0.001" min="0.001" placeholder="0.000" required
               oninput="calcularDiferencia()">
      </div>
    </div>
    <div id="alerta-peso">
      ⚠ <span>Diferencia: <strong id="dif-valor"></strong> — supera el 1% permitido.
      Verifica con el proveedor antes de continuar.</span>
    </div>

    <!-- ══ CUS 1.3: Observaciones de Calidad ══ -->
    <div class="sec-titulo">✅ Calidad y Observaciones (CUS 1.3)</div>
    <div class="grid-2">
      <div>
        <label for="estado_calidad">Estado de Calidad Inicial <span class="req">*</span></label>
        <select id="estado_calidad" name="estado_calidad" required>
          <option value="OBSERVADO">Observado (pendiente revisión)</option>
          <option value="ACEPTADO">Aceptado</option>
          <option value="RECHAZADO">Rechazado</option>
        </select>
      </div>
    </div>
    <div style="margin-top:1rem;">
      <label for="observaciones">
        Observaciones de Calidad Inicial <span class="req">*</span>
        <small style="color:#9ca3af; font-weight:400;">(campo obligatorio – CA2 HU01)</small>
      </label>
      <textarea id="observaciones" name="observaciones" required
        placeholder="Describe el estado general del material: condición del embalaje, manchas visibles, fallas detectadas, diferencias de peso, etc."></textarea>
    </div>

    <!-- ══ CUS 1.4: Evidencia Fotográfica ══ -->
    <div class="sec-titulo">📷 Evidencia Fotográfica (CUS 1.4)</div>
    <label onclick="document.getElementById('fotos').click()" style="cursor:pointer; display:block;">
      <div class="upload-area" id="upload-area">
        <span class="ico">📷</span>
        <p><strong>Haz clic o arrastra las fotos aquí</strong></p>
        <p>Formatos: JPG, PNG, WEBP · Máx 5 MB por foto · Hasta 4 fotos</p>
        <input type="file" id="fotos" name="fotos"
               accept=".jpg,.jpeg,.png,.webp"
               multiple
               onchange="previsualizarFotos(this)">
      </div>
    </label>
    <div id="preview-fotos"></div>
    <div class="hint">Las fotos son evidencia del estado de la tela al momento de la recepción.</div>

    <!-- ══ Configuración Adicional ══ -->
    <div class="sec-titulo">⚙ Configuración</div>
    <div class="check-fila">
      <input type="checkbox" id="requiere_reposo" name="requiere_reposo">
      <label for="requiere_reposo">
        Esta tela requiere tiempo de reposo antes del corte
        <small style="color:#9ca3af;">(vincula con HU03 – Gestión de tiempos de reposo)</small>
      </label>
    </div>

    <div class="fila-botones">
      <a href="<%= request.getContextPath() %>/inventario" class="btn-cancelar">✖ Cancelar</a>
      <button type="submit" class="btn-guardar">💾 Registrar Ingreso de Tela</button>
    </div>

  </form>
</div>

<script>
  /* ── CUS 1.2: Comparación de pesos en tiempo real ── */
  function calcularDiferencia() {
    const guia  = parseFloat(document.getElementById('peso_guia').value) || 0;
    const real  = parseFloat(document.getElementById('peso_real').value) || 0;
    const dif   = real - guia;
    const alerta = document.getElementById('alerta-peso');

    if (guia > 0 && Math.abs(dif) > guia * 0.01) {
      document.getElementById('dif-valor').textContent =
          (dif >= 0 ? '+' : '') + dif.toFixed(3) + ' kg (' +
          Math.abs(dif / guia * 100).toFixed(1) + '%)';
      alerta.classList.add('activo');
    } else {
      alerta.classList.remove('activo');
    }
  }

  /* ── CUS 1.4: Previsualización de fotos ── */
  function previsualizarFotos(input) {
    const preview = document.getElementById('preview-fotos');
    preview.innerHTML = '';
    const files = Array.from(input.files).slice(0, 4); // máx 4 fotos
    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = e => {
        const img = document.createElement('img');
        img.src = e.target.result;
        img.title = file.name;
        preview.appendChild(img);
      };
      reader.readAsDataURL(file);
    });
  }

  /* ── Drag & Drop ── */
  const area = document.getElementById('upload-area');
  area.addEventListener('dragover', e => { e.preventDefault(); area.classList.add('drag-over'); });
  area.addEventListener('dragleave', () => area.classList.remove('drag-over'));
  area.addEventListener('drop', e => {
    e.preventDefault();
    area.classList.remove('drag-over');
    const input = document.getElementById('fotos');
    input.files = e.dataTransfer.files;
    previsualizarFotos(input);
  });

  /* ── Validación antes de enviar ── */
  function validarFormulario() {
    const ot  = document.getElementById('id_ot').value;
    const obs = document.getElementById('observaciones').value.trim();
    const pg  = document.getElementById('peso_guia').value;
    const pr  = document.getElementById('peso_real').value;

    if (!ot)  { alert('Selecciona una Orden de Trabajo.'); return false; }
    if (!pg || parseFloat(pg) <= 0) { alert('El peso de la guía es obligatorio y debe ser mayor a 0.'); return false; }
    if (!pr || parseFloat(pr) <= 0) { alert('El peso real es obligatorio y debe ser mayor a 0.'); return false; }
    if (!obs) { alert('Las observaciones de calidad son obligatorias (Criterio de Aceptación 2 - HU01).'); return false; }
    return true;
  }
</script>
</body>
</html>
