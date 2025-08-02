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

// Obtener los videos en revisión junto con el nombre del usuario
$query = "SELECT videos.*, users.name as user_name 
          FROM videos 
          LEFT JOIN users ON videos.user_id = users.id 
          WHERE videos.review_status = 1 
          ORDER BY videos.created_date DESC";
$stmt = $db->prepare($query);
$stmt->execute();
$review_videos = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Review Videos</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>

<body>
    <div class="container my-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>Videos for Review (<?php echo count($review_videos); ?>)</h2>
        </div>

        <!-- Table for displaying review videos -->
        <div class="table-responsive">
            <table class="table table-striped table-bordered">
                <thead class="table-light">
                    <tr>
                        <th>Post Image</th>
                        <th>User</th>
                        <th>Post Description</th>
                        <th>Post Hashtag</th>
                        <th>Music</th> <!-- Nueva columna Music -->
                        <th>Created Date</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (count($review_videos) > 0): ?>
                        <?php foreach ($review_videos as $video): ?>
                            <tr>
                                <!-- Post image -->
                                <td>
                                    <?php
                                    // Ajustar la ruta al thumbnail
                                    $thumbnailPath = !empty($video['thumbnail']) ? '../uploads/thumbnails/' . basename($video['thumbnail']) : 'https://via.placeholder.com/50';
                                    ?>
                                    <img src="<?= htmlspecialchars($thumbnailPath); ?>" alt="Post Image" class="rounded" style="width: 50px; height: 50px;">
                                </td>
                                <!-- User -->
                                <td><?= htmlspecialchars($video['user_name'] ?? 'Anonymous'); ?></td>
                                <!-- Post Description -->
                                <td><?= htmlspecialchars($video['description']); ?></td>
                                <!-- Post Hashtag -->
                                <td><?= htmlspecialchars($video['hashtag']); ?></td>
                                <!-- Music -->
                                <td>
                                    <?php if (!empty($video['music_file'])): ?>
                                        <?php
                                        // Extraer el nombre de la canción sin la extensión
                                        $songName = pathinfo($video['music_file'], PATHINFO_FILENAME); // "explicale"
                                        ?>
                                        <div>
                                            <strong><?= htmlspecialchars($songName); ?></strong> <!-- Mostrar nombre de la canción -->
                                        </div>
                                        <audio controls>
                                            <source src="<?= htmlspecialchars('../uploads/songs/' . basename($video['music_file'])); ?>" type="audio/mp3">
                                            Your browser does not support the audio element.
                                        </audio>
                                    <?php else: ?>
                                        No Music
                                    <?php endif; ?>
                                </td>


                                <!-- Created Date -->
                                <td><?= htmlspecialchars($video['created_date']); ?></td>
                                <!-- Actions (Approve, Delete, View) -->
                                <td>
                                    <!-- Botón para ver el video -->
                                    <button class="btn btn-sm btn-info view-video" data-video="<?= htmlspecialchars('../uploads/videos/' . basename($video['video_path'])); ?>">
                                        <i class="fas fa-eye"></i> View
                                    </button>
                                    <!-- Botón para aprobar el video -->
                                    <a href="approve_video.php?id=<?= $video['id']; ?>" class="btn btn-sm btn-success">
                                        <i class="fas fa-check"></i> Approve
                                    </a>
                                    <!-- Botón para eliminar el video -->
                                    <a href="delete_video.php?id=<?= $video['id']; ?>" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure you want to delete this video?');">
                                        <i class="fas fa-trash"></i> Delete
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="7" class="text-center">No videos available for review.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Bootstrap Modal for Video Playback -->
    <div class="modal fade" id="videoModal" tabindex="-1" aria-labelledby="videoModalLabel" aria-hidden="true">
        <div class="modal-dialog" style="max-width: 600px;">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="videoModalLabel">View Video</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body d-flex justify-content-center">
                    <video id="modalVideoPlayer" style="width: 100%; max-height: 400px;" controls></video>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS and dependencies -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        $(document).ready(function() {
            // Función para reproducir el video en el modal
            $('.view-video').on('click', function() {
                const videoUrl = $(this).data('video');
                console.log("Intentando reproducir el video:", videoUrl); // Para depuración

                // Verificar si la URL del video existe
                $.ajax({
                    url: videoUrl,
                    method: 'HEAD',
                    success: function() {
                        let videoPlayer = document.getElementById('modalVideoPlayer');
                        videoPlayer.src = videoUrl;

                        let videoModal = new bootstrap.Modal(document.getElementById('videoModal'));
                        videoModal.show();

                        videoPlayer.play();
                    },
                    error: function() {
                        alert('Error al cargar el video. Por favor, verifica que la URL del video es correcta.');
                    }
                });
            });

            // Limpiar el video al cerrar el modal
            $('#videoModal').on('hidden.bs.modal', function() {
                let videoPlayer = document.getElementById('modalVideoPlayer');
                videoPlayer.pause();
                videoPlayer.src = '';
            });
        });
    </script>
</body>

</html>