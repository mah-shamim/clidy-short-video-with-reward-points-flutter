<?php
session_start();
require_once '../config/database.php';

if (isset($_GET['id'])) {
    $video_id = $_GET['id'];

    // Conectar a la base de datos
    $database = new Database();
    $db = $database->getConnection();

    // Eliminar el video
    $query = "DELETE FROM videos WHERE id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':id', $video_id);

    if ($stmt->execute()) {
        $_SESSION['message'] = "Video deleted successfully.";
        header("Location: review_videos.php");
    } else {
        $_SESSION['message'] = "Error deleting video.";
        header("Location: review_videos.php");
    }
    exit();
}
?>
