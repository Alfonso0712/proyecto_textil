<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.*, java.util.*" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioSesion == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    ConciliacionDespacho c = (ConciliacionDespacho) request.getAttribute("conciliacion");
    if (c == null) { response.sendRedirect(request.getContextPath() + "/despacho"); return; }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nota de Despacho – <%= c.getCodigoOt() %></title>
  <style>
    :root {
      /* Ajuste a paleta global unificada */
      --primary: #0f3460;
      --secondary: #1a1a2e;
      --accent: #e2b96f;
      --accent-light: #fef3c7;
      --bg: #f4f6f8;
      --card-bg: #ffffff;
      --border: #e2e8f0;
      --text-main: #334155;
      --text-muted: #64748b;
      
      --success: #065f46;
      --success-bg: #d1fae5;
      --danger: #991b1b;
      --danger-bg: #fee2e2;
      --info: #0369a1;
      --info-bg: #e0f2fe;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body { 
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg); 
      color: var(--text-main);
      display: flex; 
      justify-content: center; 
      align-items: center;
      min-height: 100vh;
      padding: 2rem 1rem;
    }

    .nota { 
      background: var(--card-bg); 
      width: 100%; 
      max-width: 650px; 
      border-radius: 16px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
      border: 1px solid var(--border);
      overflow: hidden; 
    }

    .nota-header { 
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      color: #fff; 
      padding: 2.5rem 2rem; 
      text-align: center; 
      position: relative;
    }

    .nota-header::after {
      content: '';
      position: absolute;
      bottom: 0; left: 0; right: 0;
      height: 4px;
      background: var(--accent);
    }

    .nota-header h1 { 
      font-size: 1.5rem; 
      font-weight: 700;
      letter-spacing: 0.05em;
      color: #fff;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
    }

    .nota-header p { 
      font-size: 0.875rem; 
      color: #cbd5e1; 
      margin-top: 0.5rem;
      text-transform: uppercase;
      letter-spacing: 0.1em;
    }

    .nota-body { padding: 2.5rem 2rem; }

    .resaltado { 
      background: #f8fafc; 
      border-radius: 12px; 
      padding: 1.25rem; 
      margin-bottom: 2rem;
      border: 1px solid var(--border);
    }

    .fila { 
      display: flex; 
      justify-content: space-between;
      align-items: center;
      padding: 0.85rem 0; 
      border-bottom: 1px dashed var(--border); 
      font-size: 0.925rem;
    }

    .resaltado .fila { border-bottom: 1px solid rgba(0,0,0,0.05); }
    .resaltado .fila:last-child, .fila:last-child { border-bottom: none; }

    .fila .etiqueta { color: var(--text-muted); font-weight: 500; }
    .fila .valor { font-weight: 600; color: var(--secondary); }

    .ot-badge-val {
      font-family: 'SFMono-Regular', Consolas, monospace;
      font-size: 1.15rem;
      font-weight: 700 !important;
      color: var(--secondary);
    }

    .badge-estado {
      padding: 0.35rem 0.85rem;
      border-radius: 9999px; 
      font-size: 0.775rem; 
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
    }
    .estado-ok     { color: var(--success); background: var(--success-bg); }
    .estado-merma  { color: var(--danger); background: var(--danger-bg); }
    .estado-desp   { color: var(--info); background: var(--info-bg); }

    .nota-footer { 
      padding: 1.5rem 2rem; 
      background: #fafafa;
      border-top: 1px solid var(--border); 
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 1rem;
    }

    .nota-footer p { font-size: 0.75rem; color: var(--text-muted); }
    
    .actions-wrap {
      display: flex;
      width: 100%;
      justify-content: flex-end;
      gap: 0.75rem;
    }

    .btn {
      padding: 0.65rem 1.5rem; 
      border: none;
      border-radius: 8px; 
      cursor: pointer; 
      font-size: 0.875rem; 
      font-weight: 600; 
      transition: all 0.2s ease;
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      text-decoration: none;
    }

    .btn-volver { background: #e2e8f0; color: var(--text-main); }
    .btn-volver:hover { background: #cbd5e1; }

    .btn-imprimir { background: var(--primary); color: #fff; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
    .btn-imprimir:hover { background: var(--secondary); transform: translateY(-1px); }

    @media print {
      body { background: #fff; padding: 0; }
      .no-print { display: none !important; }
      .nota { border: none; box-shadow: none; width: 100%; max-width: 100%; }
      .nota-header { background: #fff !important; color: #000 !important; padding: 1rem 0; border-bottom: 2px solid #000; }
      .nota-header h1 { color: #000 !important; }
      .nota-header p { color: #555 !important; }
      .resaltado { background: #fff !important; border: 1px solid #000; }
      .badge-estado { border: 1px solid #000; padding: 0.2rem 0.5rem; background: transparent !important; color: #000 !important; }
    }
  </style>
</head>
<body>

<div class="nota">
  <div class="nota-header">
    <h1>🧵 NOTA DE DESPACHO</h1>
    <p>Sistema de Producción Textil</p>
  </div>

  <div class="nota-body">
    <div class="resaltado">
      <div class="fila">
        <span class="etiqueta">Orden de Trabajo</span>
        <span class="valor ot-badge-val"><%= c.getCodigoOt() %></span>
      </div>
      <div class="fila">
        <span class="etiqueta">Estado</span>
        <span>
          <% String est = c.getEstado() != null ? c.getEstado().name() : ""; %>
          <% if ("CONCILIADO_OK".equals(est)) { %>
            <span class="badge-estado estado-ok">✔ Conciliado OK</span>
          <% } else if ("MERMA_DETECTADA".equals(est)) { %>
            <span class="badge-estado estado-merma">⚠ Merma Detectada</span>
          <% } else { %>
            <span class="badge-estado estado-desp">🚚 Despachado</span>
          <% } %>
        </span>
      </div>
    </div>

    <div class="fila">
      <span class="etiqueta">Cliente</span>
      <span class="valor"><%= c.getCliente() %></span>
    </div>
    <div class="fila">
      <span class="etiqueta">Modelo / Prenda</span>
      <span class="valor"><%= c.getNombreModelo() != null ? c.getNombreModelo() : "—" %></span>
    </div>
    <div class="fila">
      <span class="etiqueta">Cantidad Estimada (Tizado)</span>
      <span class="valor"><%= c.getCantidadEstimada() %> unidades</span>
    </div>
    <div class="fila">
      <span class="etiqueta">Conteo Físico Final</span>
      <span class="valor" style="<%= c.getDiferencia() < 0 ? "color: var(--danger);" : "" %>">
        <%= c.getCantidadFinal() %> unidades
      </span>
    </div>
    <div class="fila">
      <span class="etiqueta">Diferencia (Merma/Ganancia)</span>
      <span class="valor" style="<%= c.getDiferencia() < 0 ? "color: var(--danger);" : (c.getDiferencia() > 0 ? "color: var(--info);" : "color: var(--success);") %>">
        <%= c.getDiferencia() == 0 ? "Sin diferencia" : (c.getDiferencia() > 0 ? "+" + c.getDiferencia() : c.getDiferencia()) + " unidades" %>
      </span>
    </div>
    <div class="fila">
      <span class="etiqueta">Responsable de Conciliación</span>
      <span class="valor"><%= c.getNombreResponsable() != null ? c.getNombreResponsable() : "—" %></span>
    </div>
    <div class="fila">
      <span class="etiqueta">Fecha de Conciliación</span>
      <span class="valor">
        <%= c.getFechaConciliacion() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(c.getFechaConciliacion()) : "—" %>
      </span>
    </div>
    
    <% if (c.getFechaDespacho() != null) { %>
    <div class="fila">
      <span class="etiqueta">Fecha de Despacho</span>
      <span class="valor"><%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(c.getFechaDespacho()) %></span>
    </div>
    <% } %>
    
    <% if (c.getObservaciones() != null && !c.getObservaciones().isBlank()) { %>
    <div class="fila" style="flex-direction: column; align-items: flex-start; gap: 0.5rem;">
      <span class="etiqueta">Observaciones</span>
      <span class="valor" style="font-weight: 400; color: var(--text-main); background: #f8fafc; padding: 0.75rem; border-radius: 8px; width: 100%; border: 1px solid var(--border); box-sizing: border-box;">
        <%= c.getObservaciones() %>
      </span>
    </div>
    <% } %>
  </div>

  <div class="nota-footer no-print">
    <p>Documento generado por el Sistema de Control de Producción Textil</p>
    <div class="actions-wrap">
      <a href="<%= request.getContextPath() %>/despacho" class="btn btn-volver">← Volver</a>
      <button class="btn btn-imprimir" onclick="window.print()">🖨️ Imprimir Nota</button>
    </div>
  </div>
</div>

</body>
</html>