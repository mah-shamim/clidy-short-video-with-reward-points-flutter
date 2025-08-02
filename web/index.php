<?php
// proyecto/index.php
session_start();

// Verifica si el usuario ya ha iniciado sesión
if (isset($_SESSION['user_id'])) {
    // Si el usuario ha iniciado sesión, redirige al dashboard o página principal
    header("Location: admin/dashboard.php"); // Cambia esto por la ruta de tu dashboard o página principal
    exit;
} else {
    // Si no ha iniciado sesión, redirige al formulario de login
    header("Location: admin/login.php");
    exit;
}
?>
