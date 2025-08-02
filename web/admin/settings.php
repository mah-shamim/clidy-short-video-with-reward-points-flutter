<?php
session_start();
require_once '../config/database.php'; // Conexión a la base de datos
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Settings</title>
    <!-- Incluyendo Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<div class="d-flex">
    <!-- Main content -->
    <div class="flex-grow-1 p-4" id="main-content">
        <div class="container mt-5">
            <h4 class="mb-4">Settings</h4>
            
            <!-- Mejoras en las pestañas con Bootstrap -->
            <ul class="nav nav-pills nav-fill mb-3 shadow-sm rounded-pill p-1 bg-light" id="pills-tab" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active rounded-pill" id="pills-settings-tab" data-bs-toggle="pill" data-bs-target="#pills-settings" type="button" role="tab" aria-controls="pills-settings" aria-selected="true">Settings</button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link rounded-pill" id="pills-storage-tab" data-bs-toggle="pill" data-bs-target="#pills-storage" type="button" role="tab" aria-controls="pills-storage" aria-selected="false">Storage Settings</button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link rounded-pill" id="pills-reward-tab" data-bs-toggle="pill" data-bs-target="#pills-reward" type="button" role="tab" aria-controls="pills-reward" aria-selected="false">Reward System</button>
                </li>
            </ul>

            <div class="tab-content" id="pills-tabContent">
                <!-- Tab de Settings -->
                <div class="tab-pane fade show active" id="pills-settings" role="tabpanel" aria-labelledby="pills-settings-tab">
                    <h5>General Settings</h5>
                    <p>Aquí puedes gestionar las configuraciones generales.</p>
                    
                    <!-- Formulario de Configuración de la App -->
                    <form id="appSettingsForm">
                        <div class="mb-3">
                            <label for="app_name" class="form-label">Nombre de la App</label>
                            <input type="text" class="form-control" id="app_name" name="app_name" placeholder="Ingresa el nombre de la app" required>
                        </div>
                        <div class="mb-3">
                            <label for="app_version" class="form-label">Versión de la App</label>
                            <input type="text" class="form-control" id="app_version" name="app_version" placeholder="Ingresa la versión de la app" required>
                        </div>
                        <div class="mb-3">
                            <label for="package_name" class="form-label">Nombre de Paquete de la App</label>
                            <input type="text" class="form-control" id="package_name" name="package_name" placeholder="Ingresa el nombre del paquete de la app" required>
                        </div>
                        <div class="mb-3">
                            <label for="developer_name" class="form-label">Nombre del Desarrollador</label>
                            <input type="text" class="form-control" id="developer_name" name="developer_name" placeholder="Ingresa el nombre del desarrollador" required>
                        </div>
                        <button type="submit" class="btn btn-primary">Guardar Cambios</button>
                    </form>
                </div>

                <!-- Tab de Storage Settings (incluyendo archivo storage_settings.php) -->
                <div class="tab-pane fade" id="pills-storage" role="tabpanel" aria-labelledby="pills-storage-tab">
                    <?php include 'storage_settings.php'; ?>
                </div>

                <!-- Tab de Reward System (incluyendo archivo rewards.php) -->
                <div class="tab-pane fade" id="pills-reward" role="tabpanel" aria-labelledby="pills-reward-tab">
                    <?php include 'rewards.php'; ?>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Incluyendo Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
