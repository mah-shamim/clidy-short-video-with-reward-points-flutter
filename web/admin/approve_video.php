<?php
session_start();
require_once '../config/database.php';

if (isset($_GET['id'])) {
    $video_id = $_GET['id'];

    // Conectar a la base de datos
    $database = new Database();
    $db = $database->getConnection();

    try {
        // 1. Obtener el user_id y los puntos de video desde la configuración
        $query = "
            SELECT 
                user_id, 
                (SELECT video_points FROM reward_settings ORDER BY id DESC LIMIT 1) AS video_points 
            FROM videos 
            WHERE id = :video_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':video_id', $video_id);
        $stmt->execute();
        $video = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$video) {
            $_SESSION['message'] = "Video not found.";
            header("Location: review_videos.php");
            exit();
        }

        $user_id = $video['user_id'];
        $video_points = (int) $video['video_points'];

        // 2. Aprobar el video (cambiar review_status a 2)
        $approveQuery = "UPDATE videos SET review_status = 2 WHERE id = :video_id";
        $approveStmt = $db->prepare($approveQuery);
        $approveStmt->bindParam(':video_id', $video_id);
        $approveStmt->execute();

        // 3. Sumar los puntos al usuario
        $updatePointsQuery = "UPDATE users SET points = points + :points WHERE id = :user_id";
        $updatePointsStmt = $db->prepare($updatePointsQuery);
        $updatePointsStmt->bindParam(':points', $video_points);
        $updatePointsStmt->bindParam(':user_id', $user_id);
        $updatePointsStmt->execute();

        $_SESSION['message'] = "Video approved and points added.";
    } catch (Exception $e) {
        $_SESSION['message'] = "Error approving video: " . $e->getMessage();
    }

    // Redirigir de vuelta a la página de revisión
    header("Location: review_videos.php");
    exit();
}
?>
