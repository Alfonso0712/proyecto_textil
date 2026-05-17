<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*, java.text.SimpleDateFormat" %>
<%
    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    if (sesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Tela tela = (Tela) request.getAttribute("tela");
    List<FotoTela> fotos = (List<FotoTela>) request.getAttribute("fotos");
    if (fotos == null) fotos = new ArrayList<>();

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");

    double difVal  = tela.getDiferenciaPeso() != null ? tela.getDiferenciaPeso().doubleValue() : 0;
    double guiaVal = tela.getPesoGuia()        != null ? tela.getPesoGuia().doubleValue()        : 1;
    double pct     = guiaVal > 0 ? Math.abs(difVal / guiaVal * 100) : 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Detalle Tela – <%= tela.getCodigoTela() %></title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', sans-serif; background: #f0f2f5; padding: 1.8rem; }
    .cabecera { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
    .cabecera a { color: #0f3460; text-decoration: none; font-size: .88rem; }
    .cabecera a:hover { text-decoration: underline; }
    .cabecera h2 { color: #1a1a2e; font-size: 1.1rem; }
    .layout { display: grid; grid-template-columns: 1fr 340px; gap: 1.5rem; max-width: 1100px; }
    .card { background: #fff; border-radius: 14px; padding: 1.8rem 2rem; box-shadow: 0 2px 12px rgba(0,0,0,.08); }
    .sec-titulo { font-size: .76rem; font-weight: 700; color: #0f3460; text-transform: uppercase;
      letter-spacing: .07em; border-bottom: 2px solid #e5e7eb; padding-bottom: .4rem;
      margin: 1.4rem 0 1rem; }
    .sec-titulo:first-of-type { margin-top: 0; }
    .grid-datos { display: grid; grid-template-columns: 1fr 1fr; gap: .5rem 2rem; }
    .dato { padding: .4rem 0; border-bottom: 1px solid #f3f4f6; }
    .dato .lbl { font-size: .76rem; color: #9ca3af; font-weight: 600; text-transform: uppercase; margin-bottom: .15rem; }
    .dato .val { font-size: .9rem; color: #111; font-weight: 500; }
    .badge-estado { display: inline-block; padding: .28rem .8rem; border-radius: 20px; font-size: .78rem; font-weight: 700; }
    .est-ACEPTADO  { background: #d1e7dd; color: #0a3622; }
    .est-OBSERVADO { background: #fff3cd; color: #664d03; }
    .est-RECHAZADO { background: #f8d7da; color: #58151c; }
    .alerta-peso { background: #fef3c7; border: 1.5px solid #f59e0b; color: #78350f;
      border-radius: 9px; padding: .7rem 1rem; font-size: .85rem; margin-bottom: 1rem; }
    /* Fotos */
    .galeria { display: flex; flex-wrap: wrap; gap: .7rem; margin-top: .5rem; }
    .galeria a img { width: 130px; height: 130px; object-fit: cover; border-radius: 10px;
      border: 2px solid #e5e7eb; transition: border-color .2s; }
    .galeria a:hover img { border-color: #0f3460; }
    .sin-fotos { color: #9ca3af; font-size: .88rem; padding: 1rem 0; }
  </style>
</head>
<body>

<div class="cabecera">
  <a href="<%= request.getContextPath() %>/inventario">← Volver al listado</a>
  <h2>📦 Detalle de Tela – <code><%= tela.getCodigoTela() %></code></h2>
</div>

<div class="layout">
  <!-- Columna principal -->
  <div>
    <div class="card">

      <% if (tela.hayDiscrepanciaPeso()) { %>
        <div class="alerta-peso">
          ⚠ <strong>Alerta de peso:</strong> diferencia de
          <%= String.format("%+.3f", difVal) %> kg
          (<%= String.format("%.1f", pct) %>%) respecto a la guía de remisión.
          Se requiere verificación con el proveedor.
        </div>
      <% } %>

      <!-- Identificación -->
      <div class="sec-titulo">📋 Identificación</div>
      <div class="grid-datos">
        <div class="dato"><div class="lbl">Código Tela</div><div class="val"><code><%= tela.getCodigoTela() %></code></div></div>
        <div class="dato"><div class="lbl">OT Vinculada</div><div class="val"><code><%= tela.getCodigoOt() != null ? tela.getCodigoOt() : "—" %></code></div></div>
        <div class="dato"><div class="lbl">Origen</div><div class="val"><%= tela.getOrigen().name() %></div></div>
        <div class="dato"><div class="lbl">Proveedor</div><div class="val"><%= tela.getProveedor() != null ? tela.getProveedor() : "—" %></div></div>
        <div class="dato"><div class="lbl">Tipo de tejido</div><div class="val"><%= tela.getTipoTejido() != null ? tela.getTipoTejido() : "—" %></div></div>
        <div class="dato"><div class="lbl">Color</div><div class="val"><%= tela.getColor() != null ? tela.getColor() : "—" %></div></div>
        <div class="dato"><div class="lbl">N.° de Rollos</div><div class="val"><%= tela.getNumRollos() %></div></div>
        <div class="dato"><div class="lbl">Fecha de ingreso</div><div class="val"><%= tela.getFechaIngreso() != null ? sdf.format(tela.getFechaIngreso()) : "—" %></div></div>
        <div class="dato"><div class="lbl">Registrado por</div><div class="val"><%= tela.getNombreRegistrador() != null ? tela.getNombreRegistrador() : "—" %></div></div>
      </div>

      <!-- Control de peso (CUS 1.2) -->
      <div class="sec-titulo">⚖ Control de Peso (CUS 1.2)</div>
      <div class="grid-datos">
        <div class="dato"><div class="lbl">Peso Guía de Remisión</div><div class="val"><%= tela.getPesoGuia() %> kg</div></div>
        <div class="dato"><div class="lbl">Peso Real Medido</div><div class="val"><%= tela.getPesoReal() %> kg</div></div>
        <div class="dato">
          <div class="lbl">Diferencia</div>
          <div class="val" style="color:<%= pct > 1.0 ? '#b45309' : '#0a3622' %>; font-weight:700;">
            <%= String.format("%+.3f", difVal) %> kg
            (<%= String.format("%.2f", pct) %>%)
            <% if (pct > 1.0) { %> ⚠<% } else { %> ✅<% } %>
          </div>
        </div>
      </div>

      <!-- Calidad (CUS 1.3) -->
      <div class="sec-titulo">✅ Calidad y Observaciones (CUS 1.3)</div>
      <div class="dato" style="margin-bottom:.8rem;">
        <div class="lbl">Estado de Calidad</div>
        <div class="val">
          <span class="badge-estado est-<%= tela.getEstadoCalidad().name() %>">
            <%= tela.getEstadoCalidad().name() %>
          </span>
        </div>
      </div>
      <div class="dato">
        <div class="lbl">Requiere Reposo</div>
        <div class="val"><%= tela.isRequiereReposo() ? "✅ Sí (vinculado con HU03)" : "No" %></div>
      </div>
      <div style="margin-top:1rem; background:#f9fafb; border-radius:9px; padding:1rem; font-size:.88rem; color:#374151; line-height:1.6; border: 1px solid #e5e7eb;">
        <strong style="display:block; margin-bottom:.4rem; color:#0f3460; font-size:.76rem; text-transform:uppercase; letter-spacing:.06em;">Observaciones registradas</strong>
        <%= tela.getObservaciones() %>
      </div>

    </div>
  </div>

  <!-- Columna lateral: fotos (CUS 1.4) -->
  <div>
    <div class="card">
      <div class="sec-titulo">📷 Evidencia Fotográfica (CUS 1.4)</div>
      <% if (fotos.isEmpty()) { %>
        <p class="sin-fotos">No se cargaron fotos para esta tela.</p>
      <% } else { %>
        <p style="font-size:.8rem; color:#9ca3af; margin-bottom:.7rem;"><%= fotos.size() %> foto(s) registradas</p>
        <div class="galeria">
          <% for (FotoTela f : fotos) { %>
            <a href="<%= request.getContextPath() %>/<%= f.getRutaRelativa() %>" target="_blank">
              <img src="<%= request.getContextPath() %>/<%= f.getRutaRelativa() %>"
                   alt="Foto evidencia" title="<%= f.getNombreArchivo() %>">
            </a>
          <% } %>
        </div>
      <% } %>
    </div>
  </div>

</div><!-- /layout -->

</body>
</html>
