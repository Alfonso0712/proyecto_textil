<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login – Sistema Textil</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
  
  <style>
    :root {
      --primary-dark: #0f3460;
      --primary-hover: #164377;
      --secondary-dark: #1a1a2e;
      --accent: #e2b96f;
      --text-main: #1e293b;
      --text-muted: #64748b;
      --bg-light: #f8fafc;
      --border-color: #e2e8f0;
      
      --danger-bg: #fee2e2;
      --danger-border: #fca5a5;
      --danger-text: #b91c1c;
      
      --warning-bg: #fff8f0;
      --warning-border: #e67e22;
      --warning-text: #7a3c00;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      min-height: 100vh;
      font-family: 'Inter', sans-serif;
      background: var(--bg-light);
      display: flex;
      position: relative;
      overflow-x: hidden;
    }

    /* --- CONTENEDOR SPLIT SCREEN DE ALTO NIVEL --- */
    .login-wrapper {
      display: flex;
      width: 100%;
      min-height: 100vh;
    }

    /* Panel Izquierdo: Imagen Industrial + Branding */
    .img-left {
      position: relative;
      width: 65%;
      background: url('https://deltamaquinastexteis.com.br/wp-content/uploads/2022/03/importancia-da-automacao-textil.jpg') center/cover;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      padding: 4rem;
      z-index: 1;
    }

    /* Superposición degradada premium azulada y oscura */
    .img-left::after {
      content: '';
      position: absolute;
      inset: 0;
      background: linear-gradient(135deg, rgba(15, 52, 96, 0.95) 0%, rgba(26, 26, 46, 0.7) 100%);
      z-index: -1;
    }

    .brand-info {
      color: #fff;
      z-index: 2;
      max-width: 500px;
      margin-top: auto;
    }

    .brand-info h1 {
      font-size: 2.5rem;
      font-weight: 700;
      line-height: 1.2;
      margin-bottom: 1rem;
      color: #ffffff;
    }

    .brand-info h1 span {
      color: var(--accent);
    }

    .brand-info p {
      color: #cbd5e1;
      font-size: 1.05rem;
      line-height: 1.6;
      font-weight: 300;
    }

    /* Panel Derecho: Formulario Estilizado */
    .form-right {
      width: 35%;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      padding: 4rem 3.5rem;
      background: #ffffff;
      z-index: 2;
      position: relative;
      box-shadow: -10px 0 40px rgba(15, 52, 96, 0.05);
    }

    .form-container {
      width: 100%;
      max-width: 380px;
      margin: 0 auto;
    }

    /* Marca / Logo */
    .logo-box {
      margin-bottom: 2.5rem;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .logo-icon-bg {
      background: var(--primary-dark);
      padding: 10px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 12px rgba(15, 52, 96, 0.2);
    }

    .logo-box h2 {
      color: var(--primary-dark);
      font-size: 1.4rem;
      font-weight: 700;
      letter-spacing: -0.5px;
    }

    .logo-box span {
      color: var(--text-muted);
      font-size: 0.78rem;
      display: block;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .form-header {
      margin-bottom: 2rem;
    }

    .form-header h2 {
      font-size: 1.6rem;
      color: var(--secondary-dark);
      font-weight: 700;
      margin-bottom: 0.4rem;
    }

    .form-header p {
      font-size: 0.92rem;
      color: var(--text-muted);
    }

    /* Contenedor de credenciales de prueba estilizado de forma discreta */
    .demo-credentials {
      background: var(--bg-light);
      border: 1px dashed var(--border-color);
      border-radius: 8px;
      padding: 10px 14px;
      margin-top: 1rem;
    }
    
    .demo-credentials h3, .demo-credentials h4 {
      font-size: 0.82rem;
      color: var(--text-muted);
      font-weight: 500;
      display: flex;
      justify-content: space-between;
    }
    .demo-credentials strong {
      color: var(--primary-dark);
      font-weight: 600;
    }

    /* --- INPUT CON LABEL FLOTANTE OPTIMIZADO --- */
    .input-group {
      position: relative;
      margin-bottom: 1.25rem;
    }

    .input-group i {
      position: absolute;
      left: 14px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
      font-size: 1.2rem;
      transition: color 0.2s;
    }

    .input-group input {
      width: 100%;
      padding: 1.2rem 1rem 0.6rem 2.6rem;
      border: 1.5px solid var(--border-color);
      border-radius: 8px;
      font-size: 0.95rem;
      outline: none;
      transition: all 0.2s ease;
      background: var(--bg-light);
      color: var(--text-main);
    }

    .input-group input:hover {
      border-color: #cbd5e1;
    }

    .input-group label {
      position: absolute;
      left: 2.6rem;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
      font-size: 0.95rem;
      transition: all 0.2s ease-out;
      pointer-events: none;
      padding: 0 4px;
    }

    .input-group input:focus {
      border-color: var(--primary-dark);
      background: #ffffff;
      box-shadow: 0 0 0 4px rgba(15, 52, 96, 0.08);
    }

    .input-group input:focus ~ i {
      color: var(--primary-dark);
    }

    .input-group input:focus + label, 
    .input-group input:not(:placeholder-shown) + label,
    .input-group input:-webkit-autofill + label {
      top: 0.6rem;
      font-size: 0.75rem;
      color: var(--primary-dark);
      font-weight: 600;
    }

    /* --- ALERTAS MODERNAS --- */
    .alerta-horario {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      background: var(--warning-bg);
      border: 1px solid var(--warning-border);
      color: var(--warning-text);
      border-radius: 8px;
      padding: 12px 14px;
      margin-bottom: 1.5rem;
      font-size: 0.85rem;
      line-height: 1.4;
      box-shadow: 0 2px 4px rgba(230, 126, 34, 0.05);
    }
    
    .alerta-horario strong {
      display: block;
      font-weight: 600;
      margin-bottom: 2px;
      color: #5a2d00;
    }

    .alerta-error {
      background: var(--danger-bg);
      border: 1px solid var(--danger-border);
      color: var(--danger-text);
      border-radius: 8px;
      padding: 12px 14px;
      font-size: 0.85rem;
      margin-bottom: 1.5rem;
      display: flex;
      align-items: center;
      gap: 10px;
      box-shadow: 0 2px 4px rgba(185, 28, 28, 0.05);
    }

    /* --- BOTÓN PRINCIPAL --- */
    .btn-login {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      width: 100%;
      padding: 0.85rem;
      margin-top: 1.5rem;
      background: var(--primary-dark);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0 4px 12px rgba(15, 52, 96, 0.15);
    }

    .btn-login:hover {
      background: var(--primary-hover);
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(15, 52, 96, 0.25);
    }

    .btn-login:active {
      transform: translateY(0);
    }

    .btn-login:disabled {
      background: #94a3b8;
      color: #e2e8f0;
      cursor: not-allowed;
      box-shadow: none;
      transform: none;
    }

    .footer-txt {
      text-align: center;
      font-size: 0.78rem;
      color: var(--text-muted);
      margin-top: auto;
      padding-top: 2rem;
    }

    /* --- RESPONSIVIDAD OPTIMIZADA --- */
    @media (max-width: 1100px) {
      .img-left { width: 55%; }
      .form-right { width: 45%; }
    }

    @media (max-width: 900px) {
      body { display: block; }
      .login-wrapper { flex-direction: column; }
      .img-left {
        width: 100%;
        min-height: 28vh;
        padding: 2rem;
      }
      .brand-info h1 { font-size: 1.8rem; }
      .brand-info p { font-size: 0.95rem; }
      
      .form-right {
        width: 100%;
        padding: 2.5rem 1.5rem;
        border-radius: 20px 20px 0 0;
        margin-top: -20px;
        min-height: auto;
      }
    }
  </style>
</head>
<body>

<div class="login-wrapper">

  <div class="img-left">
    <div class="brand-info">
      <h1>Control Inteligente de <span>Producción Textil</span></h1>
      <p>Optimice la gestión de inventario de telas, el mapeo preciso de fallas y la conciliación analítica de mermas en tiempo real.</p>
    </div>
  </div>

  <div class="form-right">
    <div class="form-container">
      
      <div class="logo-box">
        <div class="logo-icon-bg">
          <svg width="32" height="32" viewBox="0 0 48 48" fill="none">
            <rect width="48" height="48" rx="12" fill="#0f3460"/>
            <path d="M12 36 L24 12 L36 36" stroke="#e2b96f" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M16 28 L32 28" stroke="#e2b96f" stroke-width="2.5" stroke-linecap="round"/>
          </svg>
        </div>
        <div>
          <h2>Textil Control</h2>
          <span>Plataforma de Ingeniería</span>
        </div>
      </div>
      
      <div class="form-header">
        <h2>Bienvenido al Portal</h2>
        <p>Ingrese sus credenciales autorizadas.</p>
        
        <div class="demo-credentials">
          <h3>Usuario: <strong>admin</strong></h3>
          <h3>Contraseña: <strong>admin1</strong></h3>
        </div>
      </div>

      <%-- ALERTAS DINÁMICAS (BACKEND ORIGINAL CONSERVADO LINEA POR LINEA) --%>
      <%
        String errorHorarioLogin = (String) request.getAttribute("errorHorarioLogin");
        if (errorHorarioLogin != null && !errorHorarioLogin.isEmpty()) {
      %>
        <div class="alerta-horario">
          <i class='bx bx-time-five' style="font-size: 1.3rem; margin-top:1px;"></i>
          <div>
            <strong>Acceso fuera de horario</strong>
            <%= errorHorarioLogin %>
          </div>
        </div>
      <% } %>

      <%
        String errorMsg = (String) request.getAttribute("error");
        if (errorMsg != null && !errorMsg.trim().isEmpty()) {
      %>
        <div class="alerta-error">
          <i class='bx bx-error-circle' style="font-size: 1.3rem;"></i>
          <span><%= errorMsg %></span>
        </div>
      <% } %>

      <% if ("1".equals(request.getParameter("errorHorario"))) { %>
        <div class="alerta-error" style="border-color:#e67e22; background:#fff8f0; color:#7a3c00;">
          <i class='bx bx-lock-open-alt' style="font-size: 1.3rem; color:#e67e22;"></i>
          <span>
            Acceso fuera de horario laboral.<br>
            El sistema está disponible de <strong>7:00 AM a 5:00 PM</strong>.<br>
            Comunícate con el administrador si necesitas acceso fuera de este horario.
          </span>
        </div>
      <% } %>
      
      <form action="${pageContext.request.contextPath}/login" method="POST" onsubmit="showLoading()">
        
        <div class="input-group">
          <input type="text" id="username" name="username" placeholder=" " 
                 value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>" required>
          <label for="username">Usuario</label>
          <i class='bx bx-user'></i>
        </div>
        
        <div class="input-group">
          <input type="password" id="password" name="password" placeholder=" " required>
          <label for="password">Contraseña</label>
          <i class='bx bx-lock-alt'></i>
        </div>
        
        <button type="submit" class="btn-login" id="submitBtn">
          <span>Iniciar Sesión</span>
          <i class='bx bx-log-in-circle'></i>
        </button>
      </form>

      <p class="footer-txt">UPLA - Ingeniería de Sistemas &copy; 2026</p>
    </div>
  </div>

</div>

  <script>
    if (window.history.replaceState) {
      window.history.replaceState(null, null, window.location.href);
    }
    function showLoading() {
      const btn = document.getElementById('submitBtn');
      setTimeout(() => {
        btn.disabled = true;
        btn.innerHTML = "Ingresando... <i class='bx bx-loader-alt bx-spin' ></i>";
      }, 0);
    }
  </script>
</body>
</html>