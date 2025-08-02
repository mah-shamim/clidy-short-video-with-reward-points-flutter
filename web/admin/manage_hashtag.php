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

ob_start(); // Esto asegura que no haya salidas inesperadas

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        $action = $_POST['action'];

        // Eliminar hashtag
        if ($action === 'delete') {
            $hashtagId = $_POST['id'];
            try {
                $query = "DELETE FROM hashtags WHERE id = :id";
                $stmt = $db->prepare($query);
                $stmt->bindParam(':id', $hashtagId);
                $stmt->execute();
                echo json_encode(['status' => 'success', 'message' => 'Hashtag eliminado correctamente']);
            } catch (PDOException $exception) {
                echo json_encode(['status' => 'error', 'message' => 'Error al eliminar: ' . $exception->getMessage()]);
            }
            exit;
        }

        // Editar hashtag
        if ($action === 'edit') {
            $hashtagId = $_POST['id'];
            $newHashtagName = trim($_POST['hashtag_name_edit']);

            if (empty($newHashtagName)) {
                echo json_encode(['status' => 'error', 'message' => 'El nombre del hashtag no puede estar vacío']);
                exit;
            }

            try {
                $query = "UPDATE hashtags SET name = :name WHERE id = :id";
                $stmt = $db->prepare($query);
                $stmt->bindParam(':name', $newHashtagName);
                $stmt->bindParam(':id', $hashtagId);
                $stmt->execute();
                echo json_encode(['status' => 'success', 'message' => 'Hashtag editado correctamente']);
            } catch (PDOException $exception) {
                echo json_encode(['status' => 'error', 'message' => 'Error al editar: ' . $exception->getMessage()]);
            }
            exit;
        }
    }

    // Insertar un nuevo hashtag
    $hashtagName = trim($_POST['hashtag_name_add']);
    if (!empty($hashtagName)) {
        try {
            $query = "INSERT INTO hashtags (name, usage_count, created_date) VALUES (:name, 0, NOW())";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':name', $hashtagName);
            $stmt->execute();

            $newHashtagId = $db->lastInsertId();
            $query = "SELECT id, name, usage_count, DATE_FORMAT(created_date, '%d %M %Y') as created_date FROM hashtags WHERE id = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':id', $newHashtagId);
            $stmt->execute();
            $newHashtag = $stmt->fetch(PDO::FETCH_ASSOC);

            ob_clean();
            echo json_encode(['status' => 'success', 'data' => $newHashtag]);
        } catch (PDOException $exception) {
            ob_clean();
            echo json_encode(['status' => 'error', 'message' => 'PDO Error: ' . $exception->getMessage()]);
        }
    } else {
        ob_clean();
        echo json_encode(['status' => 'error', 'message' => 'El nombre del hashtag no puede estar vacío']);
    }
    exit;
}

ob_end_flush();

// Obtener los hashtags desde la base de datos
$query = "SELECT id, name, usage_count, DATE_FORMAT(created_date, '%d %M %Y') as created_date FROM hashtags";
$stmt = $db->prepare($query);
$stmt->execute();
$hashtags = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Administrar Hashtags</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>

<body>
    <div class="container mt-5">
        <h2>Tabla de Hashtags</h2>

        <!-- Contenedor de la alerta personalizada -->
        <div id="alertContainer" class="alert alert-success d-none" role="alert"></div>

        <!-- Botón para agregar nuevo hashtag -->
        <div class="d-flex justify-content-between mb-3">
            <input type="text" class="form-control w-25" placeholder="Buscar...">
            <button class="btn btn-primary" id="newHashtagButton" data-bs-toggle="modal" data-bs-target="#addHashtagModal">+ Nuevo</button>
        </div>

        <!-- Tabla de hashtags -->
        <table class="table table-bordered table-hover">
            <thead class="table-dark">
                <tr>
                    <th>No</th>
                    <th>Hashtag</th>
                    <th>Contador de Uso</th>
                    <th>Fecha de Creación</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody id="hashtagTableBody">
                <?php foreach ($hashtags as $index => $hashtag): ?>
                    <tr id="hashtag-<?= $hashtag['id'] ?>">
                        <td><?= $index + 1 ?></td>
                        <td>#<?= htmlspecialchars($hashtag['name']) ?></td>
                        <td><?= htmlspecialchars($hashtag['usage_count']) ?></td>
                        <td><?= htmlspecialchars($hashtag['created_date']) ?></td>
                        <td>
                            <button class="btn btn-success btn-sm edit-hashtag" data-id="<?= $hashtag['id'] ?>" data-name="<?= htmlspecialchars($hashtag['name']) ?>">Editar</button>
                            <button class="btn btn-danger btn-sm delete-hashtag" data-id="<?= $hashtag['id'] ?>">Eliminar</button>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <!-- Modal para agregar hashtag -->
    <div class="modal fade" id="addHashtagModal" tabindex="-1" aria-labelledby="addHashtagModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addHashtagModalLabel">Agregar Hashtag</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body">
                    <form id="addHashtagForm">
                        <div class="mb-3">
                            <label for="hashtagInputAdd" class="form-label">Hashtag</label>
                            <div class="input-group">
                                <span class="input-group-text">#</span>
                                <input type="text" class="form-control" id="hashtagInputAdd" name="hashtag_name_add" placeholder="Ingrese el hashtag" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary">Agregar</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal para editar hashtag -->
    <div class="modal fade" id="editHashtagModal" tabindex="-1" aria-labelledby="editHashtagModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editHashtagModalLabel">Editar Hashtag</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                </div>
                <div class="modal-body">
                    <form id="editHashtagForm">
                        <input type="hidden" id="hashtagId">
                        <div class="mb-3">
                            <label for="hashtagInputEdit" class="form-label">Hashtag</label>
                            <div class="input-group">
                                <span class="input-group-text">#</span>
                                <input type="text" class="form-control" id="hashtagInputEdit" name="hashtag_name_edit" placeholder="Editar el hashtag" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary">Guardar</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Scripts -->
    <script>
        $(document).ready(function() {
            var addModalInstance = new bootstrap.Modal(document.getElementById('addHashtagModal'));
            var editModalInstance = new bootstrap.Modal(document.getElementById('editHashtagModal'));

            // Acción para agregar hashtag
            $('#addHashtagForm').on('submit', function(e) {
                e.preventDefault();
                var hashtagName = $('#hashtagInputAdd').val().trim();

                if (hashtagName === '') {
                    alert('Por favor, ingresa un nombre válido para el hashtag.');
                    return;
                }

                $.ajax({
                    url: 'manage_hashtag.php',
                    method: 'POST',
                    data: { action: 'insert', hashtag_name_add: hashtagName },
                    success: function(response) {
                        var result = JSON.parse(response);
                        if (result.status === 'success') {
                            var newRow = `
                                <tr id="hashtag-${result.data.id}">
                                    <td>${$('#hashtagTableBody tr').length + 1}</td>
                                    <td>#${result.data.name}</td>
                                    <td>${result.data.usage_count}</td>
                                    <td>${result.data.created_date}</td>
                                    <td>
                                        <button class="btn btn-success btn-sm edit-hashtag" data-id="${result.data.id}" data-name="${result.data.name}">Editar</button>
                                        <button class="btn btn-danger btn-sm delete-hashtag" data-id="${result.data.id}">Eliminar</button>
                                    </td>
                                </tr>
                            `;
                            $('#hashtagTableBody').append(newRow);
                            $('#alertContainer').text('¡Nuevo hashtag agregado exitosamente!').removeClass('d-none').fadeIn();
                            setTimeout(function() { $('#alertContainer').fadeOut(); }, 3000);
                            addModalInstance.hide();
                        } else {
                            alert("Error: " + result.message);
                        }
                    }
                });
            });

            // Acción para el botón editar
            $(document).on('click', '.edit-hashtag', function() {
                var hashtagId = $(this).data('id');
                var hashtagName = $(this).data('name');
                $('#hashtagId').val(hashtagId);
                $('#hashtagInputEdit').val(hashtagName);
                editModalInstance.show();
            });

            // Acción para editar hashtag
            $('#editHashtagForm').on('submit', function(e) {
                e.preventDefault();
                var hashtagId = $('#hashtagId').val();
                var hashtagName = $('#hashtagInputEdit').val().trim();

                if (hashtagName === '') {
                    alert('Por favor, ingresa un nombre válido para el hashtag.');
                    return;
                }

                $.ajax({
                    url: 'manage_hashtag.php',
                    method: 'POST',
                    data: { action: 'edit', id: hashtagId, hashtag_name_edit: hashtagName },
                    success: function(response) {
                        var result = JSON.parse(response);
                        if (result.status === 'success') {
                            $('#hashtag-' + hashtagId + ' td:nth-child(2)').text('#' + hashtagName);
                            $('#alertContainer').text('¡Hashtag editado correctamente!').removeClass('d-none').fadeIn();
                            setTimeout(function() { $('#alertContainer').fadeOut(); }, 3000);
                            editModalInstance.hide();
                        } else {
                            alert("Error: " + result.message);
                        }
                    }
                });
            });

            // Acción para el botón eliminar
            $(document).on('click', '.delete-hashtag', function() {
                var hashtagId = $(this).data('id');
                if (confirm('¿Estás seguro de que deseas eliminar este hashtag?')) {
                    $.ajax({
                        url: 'manage_hashtag.php',
                        method: 'POST',
                        data: { action: 'delete', id: hashtagId },
                        success: function(response) {
                            var result = JSON.parse(response);
                            if (result.status === 'success') {
                                $('#hashtag-' + hashtagId).remove();
                                $('#alertContainer').text('¡Hashtag eliminado correctamente!').removeClass('d-none').fadeIn();
                                setTimeout(function() { $('#alertContainer').fadeOut(); }, 3000);
                            } else {
                                alert("Error: " + result.message);
                            }
                        }
                    });
                }
            });
        });
    </script>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
