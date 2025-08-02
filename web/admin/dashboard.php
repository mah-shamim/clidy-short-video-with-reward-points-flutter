<?php
session_start();
require_once '../config/database.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$database = new Database();
$pdo = $database->getConnection();
$userId = $_SESSION['user_id'];

$userData = [];
try {
    $query = "SELECT username, profile_image FROM users WHERE id = :user_id";
    $stmt = $pdo->prepare($query);
    $stmt->bindParam(':user_id', $userId);
    $stmt->execute();
    $userData = $stmt->fetch(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "Error al obtener los datos del usuario: " . $e->getMessage();
}

$profileImageUrl = isset($userData['profile_image']) && !empty($userData['profile_image']) 
    ? "../uploads/profile_image/" . $userData['profile_image'] 
    : "https://via.placeholder.com/40";

$username = isset($userData['username']) ? htmlspecialchars($userData['username']) : "Usuario";
?>

<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        /* Estilos generales */
        html, body {
            height: 100%;
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f4f6f9;
        }

        /* Estilos de la barra lateral */
        .sidebar {
            width: 280px;
            background-color: #2d2f36;
            color: #fff;
            position: fixed;
            height: 100%;
            padding-top: 20px;
            box-shadow: 3px 0 15px rgba(0, 0, 0, 0.2);
        }

        .sidebar .nav-link {
            color: #adb5bd;
            font-weight: 500;
            padding: 12px 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: background 0.3s ease, transform 0.3s;
            border-radius: 12px;
        }

        .sidebar .nav-link i {
            font-size: 18px;
            width: 24px;
            text-align: center;
        }

        .sidebar .nav-link:hover, .sidebar .nav-link.active {
            background-color: #495057;
            color: #fff;
            transform: scale(1.05);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }

        .main-header {
            background-color: #ffffff;
            padding: 15px;
            border-bottom: 1px solid #e1e5ea;
            position: fixed;
            width: calc(100% - 280px);
            left: 280px;
            z-index: 10;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .main-header .username {
            font-weight: bold;
            color: #2d2d44;
        }

        .main-header .user-profile img {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            margin-right: 10px;
        }

        #main-content {
            margin-left: 280px;
            padding-top: 80px;
            padding: 30px;
            background-color: #f4f6f9;
            min-height: 100vh;
        }

        /* Botón flotante */
        .custom-button {
            display: inline-flex;
            align-items: center;
            padding: 10px 20px;
            font-weight: 600;
            color: #ffffff;
            background: linear-gradient(145deg, #3a3f47, #2d2f36);
            border-radius: 12px;
            box-shadow: 6px 6px 12px #26272b, -6px -6px 12px #373b42;
            transition: all 0.3s ease;
        }

        .custom-button:hover {
            box-shadow: 4px 4px 6px rgba(0, 0, 0, 0.3);
            transform: translateY(-3px);
        }

        /* Estilos de spinner */
        .loading-spinner {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 50vh;
        }
    </style>
</head>

<body>

    <div class="sidebar">
        <div class="text-center mb-4">
            <h4 class="text-light">Dashboard</h4>
        </div>
        <ul class="nav flex-column">
            <li class="nav-item">
                <a href="#" class="nav-link active" id="dashboard-home"><i class="bi bi-house"></i> Home</a>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="manage-users-link"><i class="bi bi-people"></i> Users</a>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="manage-videos-link"><i class="bi bi-play-circle"></i> Videos</a>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="withdraw-request-link"><i class="bi bi-cash-stack"></i> Withdraw Request</a>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="manage-hashtag-link"><i class="bi bi-hash"></i> Hashtags</a>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="reports-link"><i class="bi bi-flag"></i> Reports</a>
            </li>
            <li class="nav-item dropdown">
                <a href="#" class="nav-link dropdown-toggle" id="songDropdown" data-bs-toggle="dropdown">
                    <i class="bi bi-music-note-list"></i> Song
                </a>
                <ul class="dropdown-menu">
                    <li><a class="dropdown-item" href="#" id="manage-song-link">Manage Songs</a></li>
                    <li><a class="dropdown-item" href="#" id="category-song-link">Category Song</a></li>
                </ul>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link" id="settings-link"><i class="bi bi-gear"></i> Settings</a>
            </li>
        </ul>
    </div>

    <div class="main-header">
        <div>
            <span class="username">Bienvenido, <?= $username; ?></span>
        </div>
        <div class="user-profile dropdown">
            <img src="<?= $profileImageUrl; ?>" alt="Profile Image">
            <a href="#" class="text-dark text-decoration-none dropdown-toggle" data-bs-toggle="dropdown">
                <?= $username; ?>
            </a>
            <ul class="dropdown-menu dropdown-menu-end">
                <li><a class="dropdown-item" href="#" id="profile-link">Profile</a></li>
                <li><hr class="dropdown-divider"></li>
                <li><a class="dropdown-item" href="logout.php">Sign out</a></li>
            </ul>
        </div>
    </div>

    <div id="main-content">
        <h1>Bienvenido al Dashboard</h1>
        <p>Selecciona una opción del menú para continuar.</p>

        <?php if (isset($_SESSION['message'])): ?>
            <div class="alert alert-success">
                <?= $_SESSION['message'] ?>
            </div>
            <?php unset($_SESSION['message']); ?>
        <?php endif; ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        function loadContent(url, target) {
            $(target).html('<div class="loading-spinner"><div class="spinner-border text-primary" role="status"></div></div>');
            $.ajax({
                url: url,
                method: 'GET',
                success: function(response) {
                    $(target).html(response);
                },
                error: function() {
                    $(target).html('<div class="alert alert-danger">Error loading content.</div>');
                }
            });
        }

        $('#dashboard-home').on('click', function(e) { e.preventDefault(); loadContent('home.php', '#main-content'); });
        $('#manage-users-link').on('click', function(e) { e.preventDefault(); loadContent('manage_users.php', '#main-content'); });
        $('#manage-videos-link').on('click', function(e) { e.preventDefault(); loadContent('manage_videos.php', '#main-content'); });
        $('#withdraw-request-link').on('click', function(e) { e.preventDefault(); loadContent('withdraw_request.php', '#main-content'); });
        $('#manage-hashtag-link').on('click', function(e) { e.preventDefault(); loadContent('manage_hashtag.php', '#main-content'); });
        $('#reports-link').on('click', function(e) { e.preventDefault(); loadContent('reports.php', '#main-content'); });
        $('#manage-song-link').on('click', function(e) { e.preventDefault(); loadContent('manage_song.php', '#main-content'); });
        $('#category-song-link').on('click', function(e) { e.preventDefault(); loadContent('add_category_song.php', '#main-content'); });
        $('#settings-link').on('click', function(e) { e.preventDefault(); loadContent('settings.php', '#main-content'); });
        $('#profile-link').on('click', function(e) { e.preventDefault(); loadContent('profile.php', '#main-content'); });

        $(document).ready(function() { $('#main-content').html('<h1>Home</h1><p>Contenido de la sección Home.</p>'); });
    </script>
</body>

</html>
