<?php
session_start();
require_once '../config/database.php'; // Incluir la conexión a la base de datos mediante la clase Database

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Crear una instancia de la clase Database y obtener la conexión
$database = new Database();
$pdo = $database->getConnection(); // Obtener la conexión a la base de datos

// Si se envía una solicitud POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Comprobar si la solicitud es para eliminar una categoría
    if (isset($_POST['delete_category'])) {
        $categoryId = $_POST['category_id'];

        // Eliminar la categoría de la base de datos
        $sql = "DELETE FROM categories WHERE id = :category_id";
        $stmt = $pdo->prepare($sql);
        $stmt->bindParam(':category_id', $categoryId);

        if ($stmt->execute()) {
            $_SESSION['message'] = "Categoría eliminada con éxito.";
        } else {
            $_SESSION['message'] = "Error al eliminar la categoría.";
        }

        // Redirigir de vuelta al dashboard
        header("Location: add_category_song.php");
        exit;
    }

    // Comprobar si la solicitud es para editar una categoría
    if (isset($_POST['edit_category'])) {
        $categoryId = $_POST['category_id'];
        $categoryTitle = $_POST['category_title'];

        // Actualizar la categoría en la base de datos
        $sql = "UPDATE categories SET name = :category_title WHERE id = :category_id";
        $stmt = $pdo->prepare($sql);
        $stmt->bindParam(':category_id', $categoryId);
        $stmt->bindParam(':category_title', $categoryTitle);

        if ($stmt->execute()) {
            $_SESSION['message'] = "Categoría actualizada con éxito.";
        } else {
            $_SESSION['message'] = "Error al actualizar la categoría.";
        }

        // Redirigir de vuelta al dashboard
        header("Location: add_category_song.php");
        exit;
    }

    // Comprobar si la solicitud es para agregar una nueva categoría
    if (isset($_POST['add_category'])) {
        $categoryTitle = $_POST['category_title'];

        if (!empty($categoryTitle)) {
            $sql = "INSERT INTO categories (name) VALUES (:category_title)";
            $stmt = $pdo->prepare($sql);
            $stmt->bindParam(':category_title', $categoryTitle);

            if ($stmt->execute()) {
                $_SESSION['message'] = "Categoría agregada con éxito.";
            } else {
                $_SESSION['message'] = "Error al agregar la categoría.";
            }
        } else {
            $_SESSION['message'] = "El título de la categoría no puede estar vacío.";
        }

        // Redirigir de vuelta al dashboard
        header("Location: add_category_song.php");
        exit;
    }
}

// Obtener las categorías desde la base de datos
$sound_categories = [];
try {
    $query = "SELECT * FROM categories";
    $stmt = $pdo->query($query);
    $sound_categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "Error al obtener las categorías: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sound Category List</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- DataTables CSS -->
    <link rel="stylesheet" href="https://cdn.datatables.net/1.11.5/css/dataTables.bootstrap5.min.css">
</head>
<body>

<div class="container mt-5">
    <h2 class="mb-4">Sound Category List (<?= count($sound_categories) ?>)</h2>

    <?php if (isset($_SESSION['message'])): ?>
        <div class="alert alert-info">
            <?= $_SESSION['message']; ?>
            <?php unset($_SESSION['message']); ?>
        </div>
    <?php endif; ?>
    
    <div class="d-flex justify-content-between mb-3">
        <div>
            <!-- Botón que abre el modal para agregar una nueva categoría -->
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addCategoryModal">Add Sound Category</button>
        </div>
        <div>
            <input type="search" class="form-control" placeholder="Search..." id="searchInput">
        </div>
    </div>

    <table id="soundCategoryTable" class="table table-striped table-bordered">
        <thead class="table-light">
            <tr>
                <th>#</th>
                <th>Sound Category Title</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($sound_categories as $index => $category): ?>
            <tr>
                <td><?= $index + 1 ?></td>
                <td><?= $category['name'] ?></td>
                <td>
                    <!-- Botón que abre el modal de edición -->
                    <button class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#editCategoryModal<?= $category['id'] ?>">Edit</button>
                    
                    <!-- Formulario de eliminación -->
                    <form method="POST" action="add_category_song.php" style="display:inline;">
                        <input type="hidden" name="category_id" value="<?= $category['id'] ?>">
                        <input type="hidden" name="delete_category" value="1">
                        <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('¿Estás seguro de que deseas eliminar esta categoría?');">Delete</button>
                    </form>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>

<!-- Modal para agregar una nueva categoría -->
<div class="modal fade" id="addCategoryModal" tabindex="-1" aria-labelledby="addCategoryModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="addCategoryModalLabel">Añadir Nueva Categoría</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form method="POST" action="add_category_song.php">
                    <input type="hidden" name="add_category" value="1">
                    <div class="mb-3">
                        <label for="categoryTitle" class="form-label">Título de la Categoría</label>
                        <input type="text" class="form-control" id="categoryTitle" name="category_title" required>
                    </div>
                    <button type="submit" class="btn btn-primary">Guardar</button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Modales para editar cada categoría -->
<?php foreach ($sound_categories as $category): ?>
<div class="modal fade" id="editCategoryModal<?= $category['id'] ?>" tabindex="-1" aria-labelledby="editCategoryModalLabel<?= $category['id'] ?>" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editCategoryModalLabel<?= $category['id'] ?>">Editar Categoría</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form method="POST" action="add_category_song.php">
                    <input type="hidden" name="category_id" value="<?= $category['id'] ?>">
                    <input type="hidden" name="edit_category" value="1">
                    <div class="mb-3">
                        <label for="categoryTitle<?= $category['id'] ?>" class="form-label">Título de la Categoría</label>
                        <input type="text" class="form-control" id="categoryTitle<?= $category['id'] ?>" name="category_title" value="<?= $category['name'] ?>" required>
                    </div>
                    <button type="submit" class="btn btn-primary">Guardar Cambios</button>
                </form>
            </div>
        </div>
    </div>
</div>
<?php endforeach; ?>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<!-- jQuery -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<!-- DataTables JS -->
<script src="https://cdn.datatables.net/1.11.5/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.11.5/js/dataTables.bootstrap5.min.js"></script>

<script>
    $(document).ready(function() {
        // Inicializar DataTable
        $('#soundCategoryTable').DataTable({
            "paging": true,
            "lengthChange": true,
            "searching": true,
            "ordering": true,
            "info": true,
            "autoWidth": false,
        });
    });
</script>

</body>
</html>
