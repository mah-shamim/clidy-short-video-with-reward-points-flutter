<?php
session_start();
require_once '../config/database.php';

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Conectar a la base de datos
$database = new Database();
$db = $database->getConnection();

// Manejar el envío del formulario vía AJAX
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Obtener y sanear los datos del formulario
        $description = htmlspecialchars($_POST['description']);
        $hashtags = isset($_POST['hashtags']) ? $_POST['hashtags'] : [];

        // Manejo de la subida del thumbnail
        if (isset($_FILES['thumbnail']) && $_FILES['thumbnail']['error'] == 0) {
            $thumbnailName = $_FILES['thumbnail']['name'];
            $thumbnailTmpName = $_FILES['thumbnail']['tmp_name'];
            $thumbnailPath = '../uploads/thumbnails/' . basename($thumbnailName);
            move_uploaded_file($thumbnailTmpName, $thumbnailPath);
        } else {
            $thumbnailPath = ''; // Si no hay thumbnail, dejar vacío o manejar como necesites
        }

        // Manejo de la subida del video
        if (isset($_FILES['video']) && $_FILES['video']['error'] == 0) {
            $videoName = $_FILES['video']['name'];
            $videoTmpName = $_FILES['video']['tmp_name'];
            $videoPath = 'uploads/videos/' . basename($videoName); // Ruta relativa desde la raíz del proyecto
            move_uploaded_file($videoTmpName, '../' . $videoPath); // Mueve el archivo a la carpeta correcta
        } else {
            $videoPath = ''; // Si no hay video, dejar vacío o manejar como necesites
        }

        // Convertir array de hashtags a una cadena separada por comas
        $hashtagsString = implode(',', $hashtags);

        // Insertar los datos en la base de datos con `review_status` = 1
        $query = "INSERT INTO videos (description, hashtag, thumbnail, video_path, usage_count, created_date, review_status) 
                  VALUES (:description, :hashtag, :thumbnail, :video_path, 0, NOW(), 1)"; // `review_status = 1` para revisión

        $stmt = $db->prepare($query);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':hashtag', $hashtagsString);
        $stmt->bindParam(':thumbnail', $thumbnailPath);
        $stmt->bindParam(':video_path', $videoPath);
        $stmt->execute();

        // Respuesta de éxito para el AJAX
        echo json_encode(['status' => 'success', 'message' => 'Video added successfully!']);
    } catch (PDOException $exception) {
        echo json_encode(['status' => 'error', 'message' => $exception->getMessage()]);
    }
    exit; // Finalizar la ejecución después de procesar el formulario
}

// Obtener los hashtags desde la tabla 'hashtags'
$query = "SELECT name FROM hashtags";
$stmt = $db->prepare($query);
$stmt->execute();
$hashtags = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Add New Video</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- jQuery para manejar AJAX -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>

<body>
    <div class="container mt-4">
        <div class="card">
            <div class="card-body">
                <h4 class="card-title">Add New Video</h4>
                <!-- El formulario ahora tiene un ID para manejarlo con jQuery -->
                <form id="addVideoForm" enctype="multipart/form-data">
                    <!-- Descripción del video -->
                    <div class="mb-3">
                        <label for="description" class="form-label">Description</label>
                        <textarea class="form-control" id="description" name="description" rows="3" placeholder="Enter video description"></textarea>
                    </div>

                    <!-- Seleccionar Hashtags -->
                    <div class="mb-3">
                        <label for="hashtags" class="form-label">Select Hashtags</label>
                        <select class="form-select" id="hashtags" name="hashtags[]" multiple>
                            <?php foreach ($hashtags as $hashtag): ?>
                                <option value="<?= htmlspecialchars($hashtag['name']) ?>">#<?= htmlspecialchars($hashtag['name']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <small class="form-text text-muted">You can select multiple hashtags</small>
                    </div>

                    <!-- Seleccionar Thumbnail -->
                    <div class="mb-3">
                        <label for="thumbnail" class="form-label">Select Thumbnail</label>
                        <input class="form-control" type="file" id="thumbnail" name="thumbnail" accept="image/*">
                    </div>

                    <!-- Seleccionar Video -->
                    <div class="mb-3">
                        <label for="video" class="form-label">Select Video</label>
                        <input class="form-control" type="file" id="video" name="video" accept="video/*">
                    </div>

                    <!-- Botones de Submit y Close -->
                    <div class="d-flex justify-content-end">
                        <button type="submit" class="btn btn-success me-2">Submit</button>
                        <button type="button" class="btn btn-secondary" onclick="loadManageVideos()">Close</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- AJAX Script -->
    <script>
        $(document).ready(function() {
            $('#addVideoForm').on('submit', function(e) {
                e.preventDefault(); // Prevenir el envío tradicional del formulario

                var formData = new FormData(this); // Crear un FormData con los datos del formulario

                $.ajax({
                    url: 'add_video.php', // Enviar al mismo archivo
                    type: 'POST',
                    data: formData,
                    contentType: false,
                    processData: false,
                    success: function(response) {
                        alert('Video added successfully!');
                        // Aquí puedes actualizar la UI o recargar la lista de videos
                        loadManageVideos();
                    },
                    error: function(xhr, status, error) {
                        alert('Error while adding video: ' + error);
                    }
                });
            });
        });
    </script>

    <!-- Bootstrap JS and dependencies -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>
