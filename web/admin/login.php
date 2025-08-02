<?php
session_start();
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

if ($_POST) {
    $query = "SELECT * FROM users WHERE email = ? OR username = ? LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(1, $_POST['identifier']); // Puede ser email o username
    $stmt->bindParam(2, $_POST['identifier']); // Puede ser email o username
    $stmt->execute();

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Verificar si el usuario existe y si la contraseña es correcta
    if ($user && password_verify($_POST['password'], $user['password'])) {
        // Verificar si el usuario es administrador
        if ($user['role'] === 'admin') { // Solo los administradores pueden acceder
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['role'] = $user['role'];
            header("Location: dashboard.php"); // Redirige al panel de administración
            exit;
        } else {
            // Mensaje de error si el usuario no es administrador
            $error_message = "Acceso denegado. Solo los administradores pueden acceder a esta página.";
        }
    } else {
        $error_message = "Usuario o contraseña incorrectos.";
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Iniciar Sesión</title>
    <style>
        /* Estilos generales */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Arial', sans-serif;
        }

        body {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #333;
            overflow: hidden;
            position: relative;
        }

        /* Fondo animado de partículas */
        .particle-background {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(78, 2, 117, 0.15), transparent);
            animation: particleMove 20s linear infinite;
            z-index: -1;
        }

        @keyframes particleMove {
            0% { transform: translate(0, 0); }
            50% { transform: translate(15%, 15%); }
            100% { transform: translate(0, 0); }
        }

        /* Contenedor principal */
        .login-container {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            border-radius: 16px;
            padding: 40px;
            max-width: 400px;
            width: 100%;
            box-shadow: 0px 8px 30px rgba(0, 0, 0, 0.3);
            text-align: center;
            position: relative;
            overflow: hidden;
            transform: scale(0.9);
            animation: scaleIn 1s forwards;
        }

        @keyframes scaleIn {
            from { opacity: 0; transform: scale(0.8); }
            to { opacity: 1; transform: scale(1); }
        }

        .login-container h2 {
            color: #4e0275;
            font-size: 24px;
            margin-bottom: 10px;
            opacity: 0;
            animation: fadeInUp 1s forwards 0.2s;
        }

        .login-container p {
            color: #555;
            margin-bottom: 20px;
            font-size: 14px;
            opacity: 0;
            animation: fadeInUp 1s forwards 0.4s;
        }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Campos de entrada */
        .input-field {
            width: 100%;
            margin-bottom: 20px;
            position: relative;
            opacity: 0;
            animation: fadeInUp 1s forwards 0.6s;
        }

        .input-field input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid transparent;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s, box-shadow 0.3s;
            box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.1);
        }

        .input-field input:focus {
            border-color: #7f2feb;
            outline: none;
            box-shadow: 0px 0px 12px rgba(127, 47, 235, 0.4);
        }

        .error-message {
            color: red;
            margin-bottom: 15px;
            font-size: 14px;
            opacity: 0;
            animation: fadeInUp 1s forwards 0.8s;
        }

        /* Botón de login */
        .btn-login {
            background: linear-gradient(135deg, #ff3366, #7f2feb);
            border: none;
            border-radius: 8px;
            padding: 12px;
            cursor: pointer;
            font-size: 16px;
            color: #fff;
            width: 100%;
            margin-top: 20px;
            transition: transform 0.3s, box-shadow 0.3s;
            animation: fadeInUp 1s forwards 1s;
            box-shadow: 0px 4px 15px rgba(127, 47, 235, 0.3);
        }

        .btn-login:hover {
            transform: translateY(-4px);
            box-shadow: 0px 6px 20px rgba(127, 47, 235, 0.5);
        }

        /* Enlace "Olvidaste tu contraseña" */
        .forgot-password {
            text-align: right;
            font-size: 14px;
            margin-top: 10px;
            opacity: 0;
            animation: fadeInUp 1s forwards 1.2s;
        }

        .forgot-password a {
            color: #7f2feb;
            text-decoration: none;
            transition: color 0.3s;
        }

        .forgot-password a:hover {
            color: #ff3366;
        }

        /* Enlace de registro */
        .register-link {
            font-size: 14px;
            margin-top: 20px;
            opacity: 0;
            animation: fadeInUp 1s forwards 1.4s;
        }

        .register-link a {
            color: #7f2feb;
            text-decoration: none;
            transition: color 0.3s;
        }

        .register-link a:hover {
            color: #ff3366;
        }
    </style>
</head>
<body>
    <div class="particle-background"></div>

    <div class="login-container">
        <h2>Clidy</h2>
        <p>Bienvenido de vuelta !!!</p>
        <h2>Iniciar Sesión</h2>

        <?php if (isset($error_message)): ?>
            <p class="error-message"><?= htmlspecialchars($error_message) ?></p>
        <?php endif; ?>

        <form method="post" action="login.php">
            <div class="input-field">
                <input type="text" id="identifier" name="identifier" placeholder="Correo Electrónico o Nombre de Usuario" required>
            </div>
            <div class="input-field">
                <input type="password" id="password" name="password" placeholder="Contraseña" required>
            </div>

            <div class="forgot-password">
                <a href="#">¿Olvidaste tu contraseña?</a>
            </div>

            <button type="submit" class="btn-login">LOGIN</button>
        </form>

        <p class="register-link">¿Aún no tienes cuenta? <a href="register.php">Regístrate aquí</a></p>
    </div>
</body>
</html>
