<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Incluir el archivo de conexión a la base de datos (ubicado en ../config/)
require_once '../config/database.php';

// Crear instancia de la clase Database y obtener la conexión
$database = new Database();
$db = $database->getConnection();

// Si se envía el formulario (a través de AJAX)
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $response = [];
    try {
        // Recuperar datos del formulario
        $points = $_POST['points'];
        $amount = $_POST['amount'];
        $registration_points = $_POST['registration_points'];
        $registration_enabled = isset($_POST['registration_enabled']) ? 1 : 0;
        $refer_points = $_POST['refer_points'];
        $refer_enabled = isset($_POST['refer_enabled']) ? 1 : 0;
        $video_points = $_POST['video_points'];
        $video_enabled = isset($_POST['video_enabled']) ? 1 : 0;

        // Verificar si ya existe un registro
        $query_check = "SELECT id FROM reward_settings LIMIT 1";
        $stmt_check = $db->prepare($query_check);
        $stmt_check->execute();
        $existing = $stmt_check->fetch(PDO::FETCH_ASSOC);

        if ($existing) {
            // Si el registro ya existe, actualizamos los datos
            $query_update = "UPDATE reward_settings 
                             SET points = :points, amount = :amount, 
                                 registration_points = :registration_points, registration_enabled = :registration_enabled,
                                 refer_points = :refer_points, refer_enabled = :refer_enabled,
                                 video_points = :video_points, video_enabled = :video_enabled
                             WHERE id = :id";
            $stmt_update = $db->prepare($query_update);
            $stmt_update->bindParam(':points', $points);
            $stmt_update->bindParam(':amount', $amount);
            $stmt_update->bindParam(':registration_points', $registration_points);
            $stmt_update->bindParam(':registration_enabled', $registration_enabled);
            $stmt_update->bindParam(':refer_points', $refer_points);
            $stmt_update->bindParam(':refer_enabled', $refer_enabled);
            $stmt_update->bindParam(':video_points', $video_points);
            $stmt_update->bindParam(':video_enabled', $video_enabled);
            $stmt_update->bindParam(':id', $existing['id']);
            
            if ($stmt_update->execute()) {
                $response['status'] = 'success';
            } else {
                throw new Exception('Error al actualizar los datos.');
            }
        } else {
            // Si no existe un registro, insertamos uno nuevo
            $query_insert = "INSERT INTO reward_settings 
                             (points, amount, registration_points, registration_enabled, 
                              refer_points, refer_enabled, video_points, video_enabled) 
                             VALUES (:points, :amount, :registration_points, :registration_enabled, 
                                     :refer_points, :refer_enabled, :video_points, :video_enabled)";
            $stmt_insert = $db->prepare($query_insert);
            $stmt_insert->bindParam(':points', $points);
            $stmt_insert->bindParam(':amount', $amount);
            $stmt_insert->bindParam(':registration_points', $registration_points);
            $stmt_insert->bindParam(':registration_enabled', $registration_enabled);
            $stmt_insert->bindParam(':refer_points', $refer_points);
            $stmt_insert->bindParam(':refer_enabled', $refer_enabled);
            $stmt_insert->bindParam(':video_points', $video_points);
            $stmt_insert->bindParam(':video_enabled', $video_enabled);

            if ($stmt_insert->execute()) {
                $response['status'] = 'success';
            } else {
                throw new Exception('Error al insertar los datos.');
            }
        }
    } catch (Exception $e) {
        // Capturar cualquier error inesperado y enviar mensaje de error
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }

    // Devolver respuesta como JSON
    header('Content-Type: application/json');
    echo json_encode($response);
    exit();
}

// Tu código HTML sigue aquí...


// Recuperar los valores actuales de la base de datos
$query_select = "SELECT * FROM reward_settings ORDER BY id DESC LIMIT 1";
$stmt = $db->prepare($query_select);
$stmt->execute();
$config = $stmt->fetch(PDO::FETCH_ASSOC);

// Asignar valores predeterminados si no hay datos en la base de datos
$points = $config ? $config['points'] : '';
$amount = $config ? $config['amount'] : '';
$registration_points = $config ? $config['registration_points'] : '5';
$registration_enabled = $config && $config['registration_enabled'] ? 'checked' : '';
$refer_points = $config ? $config['refer_points'] : '5';
$refer_enabled = $config && $config['refer_enabled'] ? 'checked' : '';
$video_points = $config ? $config['video_points'] : '10';
$video_enabled = $config && $config['video_enabled'] ? 'checked' : '';
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reward System</title>
    <!-- Incluyendo Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Incluir jQuery -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
</head>
<body>
    <div class="container mt-5">
        <h5 class="mb-4">Reward System</h5>
        <p>Ingresa los puntos, su monto equivalente, y el código de moneda.</p>

        <!-- Formulario para ingresar puntos, monto y código de moneda (USD) -->
        <form id="rewardForm">
            <div class="row justify-content-center align-items-center mb-3">
                <div class="col-md-4">
                    <label for="points" class="form-label">Points</label>
                    <input type="number" class="form-control" id="points" name="points" value="<?php echo $points; ?>" placeholder="Ingresa los puntos" required>
                </div>

                <div class="col-md-1 text-center">
                    <span class="fs-3">=</span>
                </div>

                <div class="col-md-4">
                    <label for="amount" class="form-label">Amount</label>
                    <input type="text" class="form-control" id="amount" name="amount" value="<?php echo $amount; ?>" placeholder="Ingresa el monto equivalente" required>
                </div>
            </div>

            <!-- Campo estático para Currency Code (USD) -->
            <div class="row justify-content-center mb-3">
                <div class="col-md-4">
                    <label for="currency" class="form-label">Currency Code</label>
                    <input type="text" class="form-control" id="currency" value="USD" readonly>
                </div>
            </div>

            <!-- Sección de Actividades con columna Enable/Disable -->
            <div class="mt-5">
                <h5>Actividades</h5>
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th scope="col">Activity Name</th>
                            <th scope="col">Points</th>
                            <th scope="col" class="text-center">Enable/Disable</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>App Registration Points:</td>
                            <td><input type="number" class="form-control" name="registration_points" value="<?php echo $registration_points; ?>" required></td>
                            <td class="text-center"><input type="checkbox" name="registration_enabled" <?php echo $registration_enabled; ?>></td>
                        </tr>
                        <tr>
                            <td>App Refer Points:</td>
                            <td><input type="number" class="form-control" name="refer_points" value="<?php echo $refer_points; ?>" required></td>
                            <td class="text-center"><input type="checkbox" name="refer_enabled" <?php echo $refer_enabled; ?>></td>
                        </tr>
                        <tr>
                            <td>Video Add Points:</td>
                            <td><input type="number" class="form-control" name="video_points" value="<?php echo $video_points; ?>" required></td>
                            <td class="text-center"><input type="checkbox" name="video_enabled" <?php echo $video_enabled; ?>></td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Botón Guardar al final de todo -->
            <div class="row justify-content-center mt-4">
                <div class="col-md-3">
                    <button type="submit" class="btn btn-primary w-100">Guardar</button>
                </div>
            </div>
        </form>
    </div>

    <!-- Incluyendo Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Script para manejar el envío del formulario mediante AJAX -->
    <script>
        $('#rewardForm').on('submit', function(e) {
            e.preventDefault(); // Evitar la recarga de la página inicialmente

            $.ajax({
                url: 'rewards.php',
                method: 'POST',
                data: $(this).serialize(),
                complete: function() {
                    // Redirigir a home.php siempre después de la solicitud AJAX
                    window.location.href = 'dashboard.php';
                }
            });
        });
    </script>
</body>
</html>
