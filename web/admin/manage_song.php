<?php
session_start();
require_once '../config/database.php'; // Incluir la conexión a la base de datos mediante la clase Database

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Crear una instancia de la clase Database y obtener la conexión
$database = new Database();
$pdo = $database->getConnection(); // Obtener la conexión a la base de datos

// Inicializar $songs como un array vacío
$songs = [];

// Obtener todas las categorías desde la base de datos
$categories = [];
try {
    $query = "SELECT id, name FROM categories";  // Consulta para obtener las categorías
    $stmt = $pdo->query($query);
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC); // Guardar las categorías en un array
} catch (PDOException $e) {
    echo "Error al obtener las categorías: " . $e->getMessage();
}

// Verificar si se envía una solicitud para eliminar una canción
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_song'])) {
    $songId = $_POST['song_id'];

    // Eliminar la canción de la base de datos
    $deleteQuery = "DELETE FROM songs WHERE id = :song_id";
    $stmt = $pdo->prepare($deleteQuery);
    $stmt->bindParam(':song_id', $songId);

    if ($stmt->execute()) {
        $_SESSION['message'] = "Canción eliminada con éxito.";
    } else {
        $_SESSION['message'] = "Error al eliminar la canción.";
    }

    // Redirigir para evitar reenvío del formulario
    header("Location: manage_song.php");
    exit;
}

try {
    // Consulta para obtener todas las canciones de la base de datos
    $query = "SELECT * FROM songs";
    $stmt = $pdo->query($query);
    $songs = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "Error al obtener las canciones: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Manage Songs</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

    <?php if (isset($_SESSION['message'])): ?>
        <script>
            alert("<?= $_SESSION['message'] ?>");
        </script>
        <?php unset($_SESSION['message']); ?>
    <?php endif; ?>

    <div class="container mt-5">
        <div class="d-flex">
            <ul class="nav nav-tabs" id="myTab" role="tablist">
                <li class="nav-item">
                    <a class="nav-link active" id="songs-tab" data-bs-toggle="tab" href="#songs" role="tab">Canción</a>
                </li>
            </ul>
        </div>

        <div class="tab-content mt-3" id="myTabContent">
            <div class="tab-pane fade show active" id="songs" role="tabpanel" aria-labelledby="songs-tab">
                <h2 class="mt-3">Canción</h2>
                
                <div class="d-flex justify-content-between mb-3">
                    <input type="text" class="form-control w-25" placeholder="Buscar...">
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addSongModal">+ Nueva</button>
                </div>

                <!-- Tabla de canciones -->
                <table class="table table-bordered table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th>No</th>
                            <th>Nombre del Cantante</th>
                            <th>Título de la Canción</th>
                            <th>Categoría</th>
                            <th>Duración</th>
                            <th>Reproducir</th>
                            <th>Archivo</th>
                            <th>Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (!empty($songs)): ?>
                            <?php foreach ($songs as $index => $song): ?>
                            <tr>
                                <td><?= $index + 1 ?></td>
                                <td><?= $song['singer'] ?></td>
                                <td><?= $song['song_title'] ?></td>
                                <td><?= $song['category'] ?></td>
                                <td><?= $song['song_duration'] ?></td>
                                <td>
                                    <!-- Reproductor de audio -->
                                    <audio controls>
                                        <source src="../uploads/songs/<?= $song['song_file'] ?>" type="audio/mpeg">
                                        Tu navegador no soporta el elemento de audio.
                                    </audio>
                                </td>
                                <td>
                                    <a href="../uploads/songs/<?= $song['song_file'] ?>" download>Descargar</a>
                                </td>
                                <td>
                                    <!-- Formulario de eliminación -->
                                    <form method="POST" action="manage_song.php" style="display:inline;">
                                        <input type="hidden" name="song_id" value="<?= $song['id'] ?>">
                                        <input type="hidden" name="delete_song" value="1">
                                        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('¿Estás seguro de que deseas eliminar esta canción?');">Eliminar</button>
                                    </form>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <tr>
                                <td colspan="8">No hay canciones disponibles.</td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>

                <!-- Paginación -->
                <nav aria-label="Navegación de página">
                    <ul class="pagination justify-content-center">
                        <li class="page-item disabled">
                            <a class="page-link" href="#" tabindex="-1" aria-disabled="true">«</a>
                        </li>
                        <li class="page-item active"><a class="page-link" href="#">1</a></li>
                        <li class="page-item"><a class="page-link" href="#">2</a></li>
                        <li class="page-item">
                            <a class="page-link" href="#">»</a>
                        </li>
                    </ul>
                </nav>
            </div>
        </div>
    </div>

    <!-- Modal para agregar una nueva canción -->
    <div class="modal fade" id="addSongModal" tabindex="-1" aria-labelledby="addSongModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addSongModalLabel">Nueva Canción</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <!-- Formulario que envía los datos a add_song.php -->
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
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
