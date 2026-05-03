<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login – Sistema Textil</title>
  <style>
    :root {
      --primary-dark: #0f3460;
      --accent: #e2b96f;
      --text-main: #333;
      --text-muted: #666;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      min-height: 100vh;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: #e5e7eb;
      position: relative;
      overflow-x: hidden;
    }

    .img-left {
      position: absolute;
      top: 0; left: 0; bottom: 0;
      width: 75%;
      background: url('https://deltamaquinastexteis.com.br/wp-content/uploads/2022/03/importancia-da-automacao-textil.jpg') center/cover;
    }

    .img-left::after {
      content: '';
      position: absolute;
      inset: 0;
      background: linear-gradient(90deg, rgba(0,0,0,0.4) 0%, transparent 100%);
    }

    .form-right {
      margin-left: auto;
      width: 40%;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      padding: 3rem;
      background: rgba(255, 255, 255, 0.98);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      z-index: 2;
      position: relative;
      box-shadow: -20px 0 50px rgba(0,0,0,0.1);
    }

    .form-container {
      max-width: 400px;
      width: 100%;
      margin: 0 auto;
    }

    .logo-box {
      margin-bottom: 2rem;
      display: flex;
      align-items: center;
      justify-content: center; /* <-- Agrega esta línea */
      gap: 15px;
    }

    .logo-box h2 {
      color: var(--primary-dark);
      font-size: 1.5rem;
      margin: 0;
    }

    .logo-box span {
      color: var(--text-muted);
      font-size: 0.8rem;
    }

    .form-header h2 {
      font-size: 1.4rem;
      color: var(--primary-dark);
      margin-bottom: 0.5rem;
    }

    .form-header p {
      font-size: 0.95rem;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
    }
    .form-header h3{
      font-size: 0.95rem;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
    }
    .form-header h4 {
      font-size: 0.95rem;
      color: var(--text-muted);
      margin-bottom: 2.5rem;
    }

    /* =========================================
       ESTILO: LABEL FLOTANTE ANIMADO
       ========================================= */
    .input-group {
      position: relative;
      margin-top: 1.5rem;
      margin-bottom: 1rem;
    }

    .input-group input {
      width: 100%;
      padding: 1rem 1rem 0.6rem 1rem;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 1rem;
      outline: none;
      transition: border-color .2s;
      background: transparent;
      color: var(--text-main);
    }

    .input-group label {
      position: absolute;
      left: 1rem;
      top: 50%;
      transform: translateY(-50%);
      color: #6b7280;
      font-size: 1rem;
      transition: all 0.2s ease-out;
      pointer-events: none;
      background: #fff;
      padding: 0 0.4rem;
      margin: 0;
    }

    .input-group input:focus, 
    .input-group input:not(:placeholder-shown) {
      border-color: var(--primary-dark);
    }

    .input-group input:focus + label, 
    .input-group input:not(:placeholder-shown) + label,
    .input-group input:-webkit-autofill + label {
      top: 0;
      font-size: 0.8rem;
      color: var(--primary-dark);
      font-weight: 600;
    }

    .btn-login {
      display: block;
      width: 100%;
      padding: .75rem;
      margin-top: 1.8rem;
      background: var(--primary-dark);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      transition: background .2s;
    }

    .btn-login:hover {
      background: #1a457b;
    }

    .btn-login:disabled {
      background: #4b5563;
      cursor: not-allowed;
    }

    .alerta-error {
      background: #fee2e2;
      border: 1px solid #fca5a5;
      color: #b91c1c;
      border-radius: 8px;
      padding: .75rem 1rem;
      font-size: .9rem;
      margin-bottom: 1.5rem;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .footer-txt {
      text-align: center;
      font-size: .8rem;
      color: #9ca3af;
      margin-top: 3rem;
    }


    @media (max-width: 900px) {
      body {
        display: flex;
        flex-direction: column;
      }
      .img-left {
        position: relative;
        width: 100%;
        min-height: 35vh;
      }
      .form-right {
        width: 100%;
        padding: 3rem 1.5rem;
        box-shadow: none;
        border-radius: 24px 24px 0 0;
        margin-top: -24px;
        min-height: auto;
      }
    }
  </style>
</head>
<body>

  <div class="img-left"></div>

  <div class="form-right">
    <div class="form-container">
      
      <!-- Logo y Marca -->
      <div class="logo-box">
        <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
          <rect width="48" height="48" rx="12" fill="#0f3460"/>
          <path d="M12 36 L24 12 L36 36" stroke="#e2b96f" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M16 28 L32 28" stroke="#e2b96f" stroke-width="2.5" stroke-linecap="round"/>
        </svg>
        <div>
          <h2>Sistema Textil</h2>
          <span>Control de Producción – Lima</span>
        </div>
      </div>
      
      <div class="form-header">
        <h2>Acceso al Panel</h2>
        <p>Gestión de producción e inventario.</p>
        <h3>Usuario: admin</h3>
        <h4>Contraseña: admin</h4>
      </div>

      <%-- Alerta de error dinámica evaluada por el servidor --%>
      <% 
        String errorMsg = (String) request.getAttribute("error");
        if (errorMsg != null && !errorMsg.trim().isEmpty()) { 
      %>
        <div class="alerta-error">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
          <span><%= errorMsg %></span>
        </div>
      <% } %>
      
      <!-- FORMULARIO conectado al Servlet -->
      <form action="${pageContext.request.contextPath}/login" method="POST" onsubmit="showLoading()">
        
        <div class="input-group">
          <!-- Es crucial que el placeholder tenga un espacio " " para los labels flotantes -->
          <input type="text" id="username" name="username" placeholder=" " 
                 value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>" required>
          <label for="username">Usuario</label>
        </div>
        
        <div class="input-group">
          <input type="password" id="password" name="password" placeholder=" " required>
          <label for="password">Contraseña</label>
        </div>
        
        <button type="submit" class="btn-login" id="submitBtn">Iniciar Sesión</button>
      </form>

      <p class="footer-txt">UPLA-Ing. de Sistemas 2026</p>
    </div>
  </div>

  <script>
    // Evitar el reenvío del formulario al recargar la página (F5)
    if (window.history.replaceState) {
      window.history.replaceState(null, null, window.location.href);
    }
    function showLoading() {
      const btn = document.getElementById('submitBtn');
      // Usamos setTimeout para permitir que el formulario se envíe antes de deshabilitar el botón
      setTimeout(() => {
        btn.disabled = true;
        btn.textContent = 'Ingresando...';
      }, 0);
    }
  </script>
</body>
</html>