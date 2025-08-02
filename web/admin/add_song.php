<?php
session_start(); // Asegurarte de que la sesión esté activa

require_once '../config/database.php'; // Incluir la conexión a la base de datos mediante la clase Database

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Crear una instancia de la clase Database y obtener la conexión
$database = new Database();
$pdo = $database->getConnection(); // Obtener la conexión a la base de datos

// Obtener todas las categorías desde la base de datos
$categories = [];
try {
    $query = "SELECT id, name FROM categories";  // Consulta para obtener las categorías
    $stmt = $pdo->query($query);
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC); // Guardar las categorías en un array
} catch (PDOException $e) {
    echo "Error al obtener las categorías: " . $e->getMessage();
}

// Directorio donde se guardarán los archivos de las canciones
$target_dir = __DIR__ . "/../uploads/songs/";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $singer = $_POST['singer'];
    $songTitle = $_POST['song_title'];
    $songDuration = $_POST['song_duration'];
    $category = $_POST['category']; // Obtener la categoría seleccionada
    $songFile = $_FILES['song_file'];

    // Validar el archivo subido
    $target_file = $target_dir . basename($songFile['name']);
    $uploadOk = 1;
    $fileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

    // Verificar si el archivo es un MP3
    if ($fileType != "mp3") {
        $_SESSION['message'] = "Error: solo se permiten archivos MP3.";
        $uploadOk = 0;
    }

    // Validar que el archivo se haya subido sin errores
    if ($songFile['error'] !== UPLOAD_ERR_OK) {
        $_SESSION['message'] = "Error: hubo un problema al subir el archivo.";
        $uploadOk = 0;
    }

    // Validar que el directorio de destino exista
    if (!file_exists($target_dir)) {
        if (!mkdir($target_dir, 0777, true)) {
            $_SESSION['message'] = "Error: no se pudo crear el directorio de destino.";
            $uploadOk = 0;
        }
    }

    // Intentar subir el archivo si no hay errores
    if ($uploadOk && move_uploaded_file($songFile['tmp_name'], $target_file)) {
        // Preparar la consulta para insertar la canción en la base de datos
        $sql = "INSERT INTO songs (singer, song_title, song_duration, category, song_file, created_at) 
                VALUES (:singer, :song_title, :song_duration, :category, :song_file, NOW())";

        $stmt = $pdo->prepare($sql);
        $stmt->bindParam(':singer', $singer);
        $stmt->bindParam(':song_title', $songTitle);
        $stmt->bindParam(':song_duration', $songDuration);
        $stmt->bindParam(':category', $category); // Enlazar la categoría seleccionada
        $stmt->bindParam(':song_file', $songFile['name']);

        // Ejecutar la consulta e insertar en la base de datos
        if ($stmt->execute()) {
            $_SESSION['message'] = "La canción ha sido subida y guardada con éxito.";
        } else {
            $errorInfo = $stmt->errorInfo();
            $_SESSION['message'] = "Error: no se pudo guardar la canción en la base de datos. " . $errorInfo[2];
        }

    } else {
        $_SESSION['message'] = $_SESSION['message'] ?? "Error: no se pudo subir el archivo.";
    }

    // Redirigir de vuelta al dashboard para mostrar el mensaje
    header("Location: dashboard.php");
    exit;
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Añadir Canción</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<div class="container mt-5">
    <h2>Añadir Nueva Canción</h2>
    <form id="addSongForm" method="POST" action="add_song.php" enctype="multipart/form-data">
        <div class="mb-3">
            <label for="singerName" class="form-label">Nombre del Cantante</label>
            <input type="text" class="form-control" id="singerName" name="singer" required>
        </div>
        <div class="mb-3">
            <label for="songTitle" class="form-label">Título de la Canción</label>
            <input type="text" class="form-control" id="songTitle" name="song_title" required>
        </div>
        <div class="mb-3">
            <label for="songCategory" class="form-label">Categoría</label>
            <select class="form-control" id="songCategory" name="category" required>
                <option value="">Selecciona una categoría</option>
                <!-- Mostrar las categorías desde la base de datos -->
                <?php foreach ($categories as $category): ?>
                    <option value="<?= $category['name'] ?>"><?= $category['name'] ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="mb-3">
            <label for="songDuration" class="form-label">Duración de la Canción</label>
            <input type="text" class="form-control" id="songDuration" name="song_duration" required>
        </div>
        <div class="mb-3">
            <label for="songFile" class="form-label">Archivo MP3</label>
            <input type="file" class="form-control" id="songFile" name="song_file" accept=".mp3" required>
        </div>
        <button type="submit" class="btn btn-primary">Guardar</button>
    </form>
</div>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
