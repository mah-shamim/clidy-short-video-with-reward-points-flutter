<?php
session_start();
require_once '../config/database.php';

// Conectar a la base de datos
$database = new Database();
$db = $database->getConnection();

// Verificar si se ha enviado una solicitud de eliminación
if (isset($_POST['action']) && $_POST['action'] == 'delete' && isset($_POST['id'])) {
    $videoId = $_POST['id'];

    // Consulta para eliminar el video de la base de datos
    $query = "DELETE FROM videos WHERE id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':id', $videoId);

    if ($stmt->execute()) {
        echo 'success';
    } else {
        echo 'error';
    }
    exit;
}

// Obtener solo los videos aprobados
$query = "SELECT videos.*, users.name as user_name 
          FROM videos 
          LEFT JOIN users ON videos.user_id = users.id 
          WHERE videos.review_status = 0
          ORDER BY videos.created_date DESC";
$stmt = $db->prepare($query);
$stmt->execute();
$videos = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Manage Videos</title>
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
            <h2>Post List (<?php echo count($videos); ?>)</h2>
            <!-- Botón Add New para cargar el formulario de agregar video -->
            <button class="btn btn-success" onclick="loadAddVideo()">
                <i class="fas fa-plus"></i> Add New
            </button>
        </div>

        <!-- Tabs for All Post and Review -->
        <div class="mb-3">
            <button class="btn btn-primary me-2">All Post <span class="badge bg-light text-dark"><?php echo count($videos); ?></span></button>
            <button class="btn btn-outline-primary" onclick="loadReviewVideos()">Review</button>
        </div>

        <!-- Table for displaying videos -->
        <div class="table-responsive">
            <table class="table table-striped table-bordered">
                <thead class="table-light">
                    <tr>
                        <th>Post Video</th>
                        <th>Post Image</th>
                        <th>User</th>
                        <th>Post Description</th>
                        <th>Post Hashtag</th>
                        <th>Music</th> <!-- Nueva columna Music -->
                        <th>Total View</th>
                        <th>Suggested</th>
                        <th>Created Date</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($videos as $video): ?>
                        <tr id="video-<?= $video['id']; ?>">
                            <td>
                                <a href="#" class="btn btn-success btn-sm play-video"
                                    data-video="<?= htmlspecialchars('../uploads/videos/' . basename($video['video_path'])); ?>">
                                    <i class="fas fa-play"></i>
                                </a>
                            </td>

                            <td>
                                <?php
                                print_r($video['thumbnail']); // Depuración
                                $thumbnailPath = !empty($video['thumbnail'])
                                    ? '../uploads/thumbnails/' . basename($video['thumbnail'])
                                    : 'https://via.placeholder.com/50';
                                ?>
                                <img src="<?= htmlspecialchars($thumbnailPath); ?>"
                                    alt="Post Image" class="rounded"
                                    style="width: 50px; height: 50px;">
                            </td>

                            <td><?= htmlspecialchars($video['user_name'] ?? 'Anonymous'); ?></td>
                            <td><?= htmlspecialchars($video['description']); ?></td>

                            <td>
                                <?php print_r($video['hashtag']); ?>
                                <?= htmlspecialchars($video['hashtag'] ?? 'No hashtags'); ?>
                            </td>

                            <td>
                                <?php if (!empty($video['music_file'])): ?>
                                    <audio controls>
                                        <source src="<?= htmlspecialchars('../uploads/songs/' . basename($video['music_file'])); ?>" type="audio/mp3">
                                        Your browser does not support the audio element.
                                    </audio>
                                <?php else: ?>
                                    No Music
                                <?php endif; ?>
                            </td>

                            <td><?= htmlspecialchars($video['views'] ?? 0); ?></td>

                            <td>
                                <?php if (!empty($video['suggested']) && $video['suggested'] == 1): ?>
                                    <span class="badge bg-success">Yes</span>
                                <?php else: ?>
                                    <span class="badge bg-danger">No</span>
                                <?php endif; ?>
                            </td>

                            <td><?= htmlspecialchars($video['created_date']); ?></td>

                            <td>
                                <a href="#" class="btn btn-sm btn-danger" onclick="deleteVideo(<?= $video['id']; ?>)">
                                    <i class="fas fa-trash"></i>
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>

                </tbody>
            </table>
        </div>
    </div>

    <!-- Bootstrap Modal for Video Playback -->
    <div class="modal fade" id="videoModal" tabindex="-1" aria-labelledby="videoModalLabel" aria-hidden="true">
        <div class="modal-dialog" style="max-width: 600px;">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="videoModalLabel">Video Player</h5>
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
            // Función para reproducir el video
            $('.play-video').on('click', function(e) {
                e.preventDefault();
                const videoUrl = $(this).data('video');
                console.log("Intentando reproducir video:", videoUrl); // Para depuración

                // Verificar si la URL del video es válida
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
                        alert('Error al cargar el video. Verifica que la URL del video sea correcta.');
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

        // Función para eliminar un video usando AJAX
        function deleteVideo(videoId) {
            if (confirm('Are you sure you want to delete this video?')) {
                $.ajax({
                    url: 'manage_videos.php',
                    method: 'POST',
                    data: {
                        action: 'delete',
                        id: videoId
                    },
                    success: function(response) {
                        if (response === 'success') {
                            $('#video-' + videoId).remove();
                            alert('Video deleted successfully!');
                        } else {
                            alert('Error deleting video: ' + response);
                        }
                    },
                    error: function() {
                        alert('Error deleting video.');
                    }
                });
            }
        }

        // Función para cargar el formulario de agregar video
        function loadAddVideo() {
            $.ajax({
                url: 'add_video.php',
                method: 'GET',
                success: function(response) {
                    $('#main-content').html(response);
                },
                error: function() {
                    alert("Error loading the Add Video page.");
                }
            });
        }

        // Función para cargar el contenido de review_videos.php
        function loadReviewVideos() {
            $.ajax({
                url: 'review_videos.php',
                method: 'GET',
                success: function(response) {
                    $('#main-content').html(response);
                },
                error: function() {
                    alert("Error loading the Review Videos page.");
                }
            });
        }
    </script>
</body>

</html>