<?php
// proyecto/admin/register.php
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

if ($_POST) {
    $query = "INSERT INTO users (name, username, email, password, avatarUrl, role) VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $db->prepare($query);

    // Encriptar la contraseña
    $password_hash = password_hash($_POST['password'], PASSWORD_BCRYPT);

    // Asignar el rol "admin" a cada usuario registrado
    $role = 'admin';

    $stmt->bindParam(1, $_POST['name']);
    $stmt->bindParam(2, $_POST['username']);
    $stmt->bindParam(3, $_POST['email']);
    $stmt->bindParam(4, $password_hash);
    $stmt->bindParam(5, $_POST['avatarUrl']);
    $stmt->bindParam(6, $role);

    if ($stmt->execute()) {
        echo "<p class='success-message'>Registro exitoso. <a href='login.php'>Inicia sesión aquí</a>.</p>";
    } else {
        echo "<p class='error-message'>Error al registrarse. Intenta de nuevo.</p>";
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registro de Administrador</title>
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
        }

        /* Contenedor principal */
        .register-container {
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            border-radius: 16px;
            padding: 40px;
            max-width: 400px;
            width: 100%;
            box-shadow: 0px 8px 30px rgba(0, 0, 0, 0.3);
            text-align: center;
        }

        .register-container h2 {
            color: #4e0275;
            font-size: 24px;
            margin-bottom: 10px;
        }

        .register-container p {
            color: #555;
            margin-bottom: 20px;
            font-size: 14px;
        }

        /* Campos de entrada */
        .input-field {
            width: 100%;
            margin-bottom: 20px;
            position: relative;
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

        /* Mensajes de éxito o error */
        .success-message {
            color: #4CAF50;
            margin-bottom: 15px;
            font-size: 14px;
        }

        .error-message {
            color: red;
            margin-bottom: 15px;
            font-size: 14px;
        }

        /* Botón de registro */
        .btn-register {
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
            box-shadow: 0px 4px 15px rgba(127, 47, 235, 0.3);
        }

        .btn-register:hover {
            transform: translateY(-4px);
            box-shadow: 0px 6px 20px rgba(127, 47, 235, 0.5);
        }

        /* Enlace para iniciar sesión */
        .login-link {
            font-size: 14px;
            margin-top: 20px;
        }

        .login-link a {
            color: #7f2feb;
            text-decoration: none;
            transition: color 0.3s;
        }

        .login-link a:hover {
            color: #ff3366;
        }
    </style>
</head>
<body>
    <div class="register-container">
        <h2>Clidy</h2>
        <p>Crear una cuenta de administrador</p>
        <h2>Registro</h2>

        <form method="post" action="register.php">
            <div class="input-field">
                <input type="text" id="name" name="name" placeholder="Nombre Completo" required>
            </div>
            <div class="input-field">
                <input type="text" id="username" name="username" placeholder="Nombre de Usuario" required>
            </div>
            <div class="input-field">
                <input type="email" id="email" name="email" placeholder="Correo Electrónico" required>
            </div>
            <div class="input-field">
                <input type="password" id="password" name="password" placeholder="Contraseña" required>
            </div>
            <div class="input-field">
                <input type="text" id="avatarUrl" name="avatarUrl" placeholder="URL del Avatar (opcional)">
            </div>
            <button type="submit" class="btn-register">Registrarse</button>
        </form>

        <p class="login-link">¿Ya tienes una cuenta? <a href="login.php">Inicia sesión aquí</a></p>
    </div>
</body>
</html>
