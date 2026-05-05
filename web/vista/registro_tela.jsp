<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario" %>
<%
    // Protección de sesión
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Registro de Tela – HU01</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; padding: 1.5rem; }

    .cabecera {
      display: flex; align-items: center; gap: 1rem;
      margin-bottom: 1.5rem;
    }
    .cabecera a { color: #0f3460; text-decoration: none; font-size: .88rem; }
    .cabecera h2 { color: #1a1a2e; font-size: 1.15rem; }

    .card {
      background: #fff; border-radius: 14px;
      padding: 2rem 2.2rem; max-width: 780px;
      box-shadow: 0 2px 12px rgba(0,0,0,.08);
    }

    .seccion-titulo {
      font-size: .78rem; font-weight: 700; color: #0f3460;
      text-transform: uppercase; letter-spacing: .06em;
      border-bottom: 2px solid #e5e7eb; padding-bottom: .4rem;
      margin: 1.5rem 0 1rem;
    }
    .seccion-titulo:first-of-type { margin-top: 0; }

    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; }
    .span-2 { grid-column: span 2; }

    label {
      display: block; font-size: .82rem; font-weight: 600;
      color: #374151; margin-bottom: .3rem;
    }
    label .req { color: #e74c3c; margin-left: 2px; }

    input[type="text"], input[type="number"],
    select, textarea {
      width: 100%; padding: .58rem .85rem;
      border: 1.5px solid #d1d5db; border-radius: 8px;
      font-size: .9rem; font-family: inherit;
      transition: border-color .2s; outline: none;
    }
    input:focus, select:focus, textarea:focus { border-color: #0f3460; }
    textarea { resize: vertical; min-height: 80px; }

    /* Alerta comparación de pesos */
    #alerta-peso {
      display: none; background: #fef3c7; border: 1px solid #fcd34d;
      color: #92400e; border-radius: 8px; padding: .6rem .9rem;
      font-size: .83rem; margin-top: .5rem;
    }
    #alerta-peso.visible { display: block; }

    /* Checkbox personalizado */
    .check-grupo {
      display: flex; align-items: center; gap: .6rem;
      padding: .7rem 0;
    }
    .check-grupo input[type="checkbox"] { width: 18px; height: 18px; cursor: pointer; }
    .check-grupo label { margin: 0; font-weight: 500; cursor: pointer; }

    .btn-guardar {
      display: inline-block; padding: .72rem 2rem;
      background: #0f3460; color: #fff; border: none;
      border-radius: 8px; font-size: .95rem; font-weight: 600;
      cursor: pointer; transition: background .2s; margin-top: 1.5rem;
    }
    .btn-guardar:hover { background: #1a5276; }

    .alerta-error {
      background: #fee2e2; border: 1px solid #fca5a5; color: #b91c1c;
      border-radius: 8px; padding: .65rem .9rem; font-size: .85rem;
      margin-bottom: 1rem;
    }
  </style>
</head>
<body>

<div class="cabecera">
  <a href="${pageContext.request.contextPath}/inventario">← Volver al inventario</a>
  <h2>📦 Registro de Ingreso de Tela <span style="color:#888;font-size:.85rem">(HU01)</span></h2>
</div>

<div class="card">

  <%-- Error de validación --%>
  <% if (request.getAttribute("error") != null) { %>
    <div class="alerta-error">⚠ <%= request.getAttribute("error") %></div>
  <% } %>

  <form action="${pageContext.request.contextPath}/inventario" method="POST">

    <!-- ── Sección 1: Orden de Trabajo ── -->
    <div class="seccion-titulo">Orden de Trabajo</div>
    <div class="grid-2">
      <div>
        <label for="id_ot">Orden de Trabajo (OT) <span class="req">*</span></label>
        <%-- En producción real cargarías el listado de OTs activas desde el servlet --%>
        <select id="id_ot" name="id_ot" required>
          <option value="">-- Selecciona una OT --</option>
          <%-- Ejemplo hardcoded; reemplaza con JSTL/forEach cuando tengas datos --%>
          <option value="1">OT-2026-0001 – Cliente Demo</option>
        </select>
      </div>
      <div>
        <label for="origen">Origen de la tela <span class="req">*</span></label>
        <select id="origen" name="origen" required>
          <option value="">-- Selecciona --</option>
          <option value="CLIENTE">Del cliente</option>
          <option value="TALLER">Adquirida por el taller</option>
        </select>
      </div>
    </div>

    <!-- ── Sección 2: Datos del Material ── -->
    <div class="seccion-titulo">Datos del Material</div>
    <div class="grid-3">
      <div>
        <label for="proveedor">Proveedor / Razón Social</label>
        <input type="text" id="proveedor" name="proveedor" placeholder="Ej: Textiles ABC S.A.C.">
      </div>
      <div>
        <label for="tipo_tejido">Tipo de Tejido</label>
        <input type="text" id="tipo_tejido" name="tipo_tejido" placeholder="Ej: Elástico 4 vías">
      </div>
      <div>
        <label for="color">Color</label>
        <input type="text" id="color" name="color" placeholder="Ej: Negro">
      </div>
    </div>

    <div class="grid-2" style="margin-top:1rem">
      <div>
        <label for="num_rollos">N.° de rollos</label>
        <input type="number" id="num_rollos" name="num_rollos"
               min="1" value="1" placeholder="1">
      </div>
    </div>

    <!-- ── Sección 3: Control de Peso (CA1 HU01) ── -->
    <div class="seccion-titulo">Control de Peso – Validación Guía vs Real</div>
    <div class="grid-2">
      <div>
        <label for="peso_guia">Peso en Guía de Remisión (kg) <span class="req">*</span></label>
        <input type="number" id="peso_guia" name="peso_guia"
               step="0.001" min="0" placeholder="0.000" required
               oninput="calcularDiferencia()">
      </div>
      <div>
        <label for="peso_real">Peso Real Medido (kg) <span class="req">*</span></label>
        <input type="number" id="peso_real" name="peso_real"
               step="0.001" min="0" placeholder="0.000" required
               oninput="calcularDiferencia()">
      </div>
    </div>

    <%-- Alerta JS en tiempo real --%>
    <div id="alerta-peso">
      ⚠ Diferencia de peso: <strong id="dif-valor">0 kg</strong> — supera el 1% permitido.
      Verifica con el proveedor antes de continuar.
    </div>

    <!-- ── Sección 4: Calidad y Observaciones (CA2 HU01) ── -->
    <div class="seccion-titulo">Calidad y Observaciones</div>
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

    <div style="margin-top:1rem">
      <label for="observaciones">
        Observaciones de Calidad Inicial <span class="req">*</span>
        <small style="color:#888;font-weight:400">(campo obligatorio – CA2)</small>
      </label>
      <textarea id="observaciones" name="observaciones" required
                placeholder="Describe el estado general de la tela recibida, condición del embalaje, manchas visibles, etc."></textarea>
    </div>

    <!-- ── Sección 5: Configuración ── -->
    <div class="seccion-titulo">Configuración Adicional</div>
    <div class="check-grupo">
      <input type="checkbox" id="requiere_reposo" name="requiere_reposo">
      <label for="requiere_reposo">
        Esta tela requiere tiempo de reposo antes del corte
        <small style="color:#888">(vincula con HU03)</small>
      </label>
    </div>

    <button type="submit" class="btn-guardar">💾 Registrar Ingreso de Tela</button>
  </form>
</div>

<script>
  /**
   * Calcula diferencia de peso en tiempo real y activa alerta visual (CA1 HU01).
   */
  function calcularDiferencia() {
    const guia = parseFloat(document.getElementById('peso_guia').value) || 0;
    const real = parseFloat(document.getElementById('peso_real').value) || 0;
    const dif  = real - guia;
    const alerta = document.getElementById('alerta-peso');

    if (guia > 0 && Math.abs(dif) > guia * 0.01) {
      document.getElementById('dif-valor').textContent =
        (dif > 0 ? '+' : '') + dif.toFixed(3) + ' kg';
      alerta.classList.add('visible');
    } else {
      alerta.classList.remove('visible');
    }
  }
</script>

</body>
</html>
