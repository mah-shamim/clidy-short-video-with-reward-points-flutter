<?php
// Incluir la conexión a la base de datos
require_once '../config/database.php';

// Obtener la conexión de la base de datos usando PDO
$database = new Database();
$conn = $database->getConnection();

// Manejar la eliminación de usuarios antes de cualquier salida HTML
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'delete' && isset($_POST['id'])) {
    $userId = $_POST['id'];

    // Eliminar el usuario de la base de datos
    $query = "DELETE FROM users WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $userId);

    if ($stmt->execute()) {
        echo 'success';
    } else {
        echo 'error';
    }
    exit; // Salir para que no se ejecute el resto del código
}

// Consultar los usuarios desde la base de datos
$query = "SELECT id, name, username, email, createdDate, profile_image, status FROM users"; // Incluye el ID del usuario
$stmt = $conn->prepare($query);
$stmt->execute();

// Obtener los usuarios en un array asociativo
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Manage Users</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
<div class="container my-4">
    <h2>User List (<?php echo count($users); ?>)</h2>
    <div class="table-responsive">
        <table class="table table-striped table-bordered">
            <thead class="table-light">
                <tr>
                    <th>Profile</th>
                    <th>Full Name</th>
                    <th>Username</th>
                    <th>Email</th>
                    <th>Created Date</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($users as $user): ?>
                <tr id="user-<?php echo htmlspecialchars($user['id']); ?>">
                    <td>
                        <?php if (!empty($user['profile_image'])): ?>
                            <img src="../uploads/profile_image/<?php echo htmlspecialchars($user['profile_image']); ?>" alt="Profile Image" class="rounded" style="width: 50px; height: 50px;">
                        <?php else: ?>
                            <img src="https://via.placeholder.com/50" alt="No Image" class="rounded" style="width: 50px; height: 50px;">
                        <?php endif; ?>
                    </td>
                    <td><?php echo htmlspecialchars($user['name']); ?></td>
                    <td><?php echo htmlspecialchars($user['username']); ?></td>
                    <td><?php echo htmlspecialchars($user['email']); ?></td>
                    <td><?php echo htmlspecialchars($user['createdDate']); ?></td>
                    <td><span class="badge bg-success"><?php echo htmlspecialchars($user['status']); ?></span></td>
                    <td>
                        <!-- Botón para eliminar usuario -->
                        <button class="btn btn-sm btn-danger delete-user" data-id="<?php echo htmlspecialchars($user['id']); ?>">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- AJAX para eliminar usuario -->
<script>
$(document).ready(function() {
    // Eliminar usuario
    $('.delete-user').click(function() {
        var userId = $(this).data('id');
        
        if (confirm('Are you sure you want to delete this user?')) {
            $.ajax({
                url: 'manage_users.php', // Cambia a la URL correcta
                method: 'POST',
                data: { action: 'delete', id: userId },
                success: function(response) {
                    if (response === 'success') {
                        $('#user-' + userId).remove();
                        alert('User deleted successfully!');
                    } else {
                        alert('Error deleting user: ' + response);
                    }
                },
                error: function(xhr, status, error) {
                    console.error("Error status:", status);
                    console.error("XHR:", xhr);
                    console.error("Error:", error);
                    alert('Error deleting user.');
                }
            });
        }
    });
});
</script>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
