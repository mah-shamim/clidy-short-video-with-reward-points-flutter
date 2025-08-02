<?php
session_start();
require_once '../config/database.php';

// Verificar si el usuario ha iniciado sesión
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Obtener las solicitudes de retiro de la base de datos (pendiente de implementar en la base de datos)
$withdrawRequests = [
    [
        'id' => 1,
        'username' => 'Benjamin Lee',
        'profile_image' => 'https://via.placeholder.com/40', // Imagen de perfil temporal
        'amount' => 1,
        'Points' => 25,
        'payment_gateway' => 'PayPal',
        'date' => date("m/d/Y, h:i:s A"),
    ]
];
?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Withdraw Requests</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            font-family: Arial, sans-serif;
        }

        .tab-container {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            padding: 10px 0;
        }

        .tab-container button {
            border: 2px solid #8f87f2;
            color: #8f87f2;
            border-radius: 30px;
            padding: 8px 20px;
            cursor: pointer;
            background: transparent;
            font-weight: bold;
        }

        .tab-container button.active {
            background-color: #8f87f2;
            color: white;
        }

        .table-container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        table {
            width: 100%;
            text-align: center;
        }

        th {
            background-color: #8f87f2;
            color: white;
            padding: 12px;
        }

        td {
            padding: 12px;
            vertical-align: middle;
        }

        .action-btn {
            padding: 5px 15px;
            border-radius: 5px;
            font-weight: bold;
            cursor: pointer;
            color: white;
        }

        .btn-info {
            background-color: #007bff;
        }

        .btn-pay {
            background-color: #28a745;
        }

        .btn-decline {
            background-color: #dc3545;
        }
    </style>
</head>

<body>

<div class="container mt-4">
    <div class="tab-container">
        <button class="active" id="pending-tab">Pending</button>
        <button id="accepted-tab">Accepted</button>
        <button id="declined-tab">Declined</button>
    </div>

    <div class="table-container">
        <h4 class="mb-4">Withdraw Request Table</h4>
        <table class="table">
            <thead>
                <tr>
                    <th>No</th>
                    <th>Username</th>
                    <th>Request amount(₹)</th>
                    <th>Points</th>
                    <th>Payment Gateway</th>
                    <th>Date</th>
                    <th>Info</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($withdrawRequests as $request): ?>
                    <tr>
                        <td><?= htmlspecialchars($request['id']) ?></td>
                        <td>
                            <img src="<?= htmlspecialchars($request['profile_image']) ?>" alt="Profile" class="rounded-circle me-2" width="30" height="30">
                            <?= htmlspecialchars($request['username']) ?>
                        </td>
                        <td><?= htmlspecialchars($request['amount']) ?></td>
                        <td><?= htmlspecialchars($request['Points']) ?></td>
                        <td><?= htmlspecialchars($request['payment_gateway']) ?></td>
                        <td><?= htmlspecialchars($request['date']) ?></td>
                        <td>
                            <button class="action-btn btn-info">Info</button>
                        </td>
                        <td>
                            <button class="action-btn btn-pay">Pay</button>
                            <button class="action-btn btn-decline">Decline</button>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<script>
    document.getElementById("pending-tab").addEventListener("click", function() {
        activateTab(this);
    });

    document.getElementById("accepted-tab").addEventListener("click", function() {
        activateTab(this);
    });

    document.getElementById("declined-tab").addEventListener("click", function() {
        activateTab(this);
    });

    function activateTab(tab) {
        document.querySelectorAll(".tab-container button").forEach(button => {
            button.classList.remove("active");
        });
        tab.classList.add("active");
        // Aquí puedes agregar la lógica para mostrar el contenido de cada pestaña
    }
</script>

</body>

</html>
