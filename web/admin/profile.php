<?php
session_start();
require_once '../config/database.php'; // Incluir la conexión a la base de datos mediante la clase Database

// Crear una instancia de la clase Database y obtener la conexión
$database = new Database();
$pdo = $database->getConnection(); // Obtener la conexión a la base de datos

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$userId = $_SESSION['user_id']; // ID del usuario actual

// Obtener los datos actuales del usuario
$userData = [];
try {
    $query = "SELECT username, email, profile_image FROM users WHERE id = :user_id";
    $stmt = $pdo->prepare($query);
    $stmt->bindParam(':user_id', $userId);
    $stmt->execute();
    $userData = $stmt->fetch(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "Error al obtener los datos del usuario: " . $e->getMessage();
}

// Si se envía el formulario, procesar la actualización
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $email = $_POST['email'];
    $password = !empty($_POST['password']) ? password_hash($_POST['password'], PASSWORD_DEFAULT) : null;

    // Procesar la imagen de perfil si se ha cargado
    $uploadDir = '../uploads/profile_image/';
    $profileImage = $_FILES['profile_image'];
    $fileName = null;

    if ($profileImage['error'] === UPLOAD_ERR_OK) {
        $tmpName = $profileImage['tmp_name'];
        $fileName = basename($profileImage['name']);
        $targetPath = $uploadDir . $fileName;

        // Mover la imagen a la carpeta de destino
        if (move_uploaded_file($tmpName, $targetPath)) {
            // Actualizar el nombre del archivo de imagen en la base de datos
            $updateQuery = "UPDATE users SET profile_image = :profile_image WHERE id = :user_id";
            $stmt = $pdo->prepare($updateQuery);
            $stmt->bindParam(':profile_image', $fileName);
            $stmt->bindParam(':user_id', $userId);
            $stmt->execute();
            $userData['profile_image'] = $fileName; // Actualizar la imagen en $userData
        } else {
            $_SESSION['message'] = "Error al cargar la imagen de perfil.";
        }
    }

    // Actualizar el resto de los datos del perfil
    $updateQuery = "UPDATE users SET username = :username, email = :email";
    if ($password) {
        $updateQuery .= ", password = :password";
    }
    $updateQuery .= " WHERE id = :user_id";

    $stmt = $pdo->prepare($updateQuery);
    $stmt->bindParam(':username', $username);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':user_id', $userId);
    if ($password) {
        $stmt->bindParam(':password', $password);
    }

    if ($stmt->execute()) {
        $_SESSION['message'] = "Perfil actualizado con éxito.";
        // Actualizar los datos del usuario
        $userData['username'] = $username;
        $userData['email'] = $email;
    } else {
        $_SESSION['message'] = "Error al actualizar el perfil.";
    }
}

// Definir la URL de la imagen de perfil
$profileImageUrl = isset($userData['profile_image']) && !empty($userData['profile_image']) 
    ? "../uploads/profile_image/" . $userData['profile_image'] 
    : "https://via.placeholder.com/120"; // Imagen por defecto si no hay una imagen de perfil
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Perfil de Usuario</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

<div class="container mt-5">
    <!-- Mostrar mensajes de éxito o error -->
    <?php if (isset($_SESSION['message'])): ?>
        <div class="alert alert-info">
            <?= $_SESSION['message']; ?>
            <?php unset($_SESSION['message']); ?>
        </div>
    <?php endif; ?>

    <div class="card mx-auto shadow-sm" style="max-width: 600px;">
        <div class="card-body">
            <h3 class="card-title text-center mb-4">Perfil de Usuario</h3>
            <form action="profile.php" method="POST" enctype="multipart/form-data">
                <!-- Imagen de perfil -->
                <div class="mb-3 text-center">
                    <img src="<?= htmlspecialchars($profileImageUrl); ?>" id="profilePreview" alt="Profile Image" class="rounded-circle img-thumbnail mb-3" style="width: 120px; height: 120px; object-fit: cover;">
                </div>
                <div class="mb-3">
                    <label for="profileImage" class="form-label">Imagen de Perfil</label>
                    <input class="form-control" type="file" id="profileImage" name="profile_image" accept="image/*" onchange="previewImage(event)">
                </div>

                <!-- Nombre de usuario -->
                <div class="mb-3">
                    <label for="username" class="form-label">Nombre de Usuario</label>
                    <input type="text" class="form-control" id="username" name="username" placeholder="Nombre de Usuario" value="<?= htmlspecialchars($userData['username']); ?>" required>
                </div>

                <!-- Contraseña -->
                <div class="mb-3">
                    <label for="password" class="form-label">Contraseña</label>
                    <input type="password" class="form-control" id="password" name="password" placeholder="Nueva Contraseña">
                </div>

                <!-- Email -->
                <div class="mb-3">
                    <label for="email" class="form-label">Correo Electrónico</label>
                    <input type="email" class="form-control" id="email" name="email" placeholder="Correo Electrónico" value="<?= htmlspecialchars($userData['email']); ?>" required>
                </div>

                <!-- Botón para guardar cambios -->
                <div class="text-center">
                    <button type="submit" class="btn btn-primary">Guardar Cambios</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<!-- JavaScript para vista previa de la imagen -->
<script>
    function previewImage(event) {
        const reader = new FileReader();
        reader.onload = function() {
            const output = document.getElementById('profilePreview');
            output.src = reader.result;
        }
        reader.readAsDataURL(event.target.files[0]);
    }
</script>

</body>
</html>
