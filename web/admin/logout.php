<?php
session_start();

// Destruir todas las sesiones
session_unset();
session_destroy();

// Redirigir al usuario a la página de inicio de sesión
header("Location: login.php");
exit;
