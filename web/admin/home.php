<?php
// Datos de muestra (puedes reemplazar estos datos con una consulta a la base de datos)
$totalUser = 36;
$totalPost = 14;
$totalVideo = 9;
$totalSong = 3;
$activeUserPercentage = 100;
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        /* CSS general */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }

        body {
            background-color: #f9f9f9;
            color: #333;
            padding: 0;
            margin: 0;
            height: 100vh;
        }

        /* Ajuste principal para el contenedor */
        .container {
            margin-left: 230px; /* Mueve el contenido más a la izquierda */
            margin-top: 20px; /* Baja el contenido ligeramente */
            padding: 20px;
            width: calc(100% - 230px); /* Ajusta el ancho para ocupar el espacio restante */
            background-color: #f4f6f9;
            border-radius: 10px;
        }

        /* Encabezado de métricas */
        .header {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            margin-bottom: 30px;
        }

        .box {
            flex: 1;
            background-color: #f1ebfe;
            color: #333;
            text-align: center;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
        }

        .box:hover {
            transform: translateY(-5px);
            box-shadow: 0 6px 12px rgba(107, 90, 248, 0.3);
        }

        .box p {
            font-size: 16px;
            color: #6b5af8;
            margin-top: 10px;
            font-weight: bold;
        }

        .box h2 {
            font-size: 36px;
            color: #333;
            margin-top: 5px;
        }

        .icon {
            font-size: 35px;
            color: #6b5af8;
            margin-bottom: 10px;
        }

        /* Sección de análisis y actividad */
        .analytics-section {
            display: flex;
            gap: 20px;
            margin-top: 20px;
        }

        .data-chart, .activity-section {
            background-color: #fff;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
            flex: 1;
            min-height: 250px;
        }

        .data-chart h3, .activity-section h3 {
            font-size: 18px;
            color: #333;
            margin-bottom: 20px;
            text-align: center;
        }

        /* Estilo del gráfico circular */
        .activity-chart {
            background: conic-gradient(#6b5af8 <?php echo $activeUserPercentage; ?>%, #f1ebfe <?php echo $activeUserPercentage; ?>%);
            border-radius: 50%;
            width: 120px;
            height: 120px;
            margin: 20px auto;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .activity-percentage {
            font-size: 26px;
            color: #333;
        }

        .legend {
            display: flex;
            justify-content: center;
            margin-top: 15px;
            gap: 10px;
            text-align: center;
        }

        .legend div {
            display: flex;
            align-items: center;
            font-size: 14px;
            color: #555;
        }

        .legend span {
            display: inline-block;
            width: 12px;
            height: 12px;
            margin-right: 5px;
            border-radius: 3px;
        }

        .total-user { background-color: #6b5af8; }
        .total-video { background-color: #333; }
        .total-short { background-color: #dda0dd; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="box">
                <div class="icon"><i class="fas fa-users"></i></div>
                <h2><?php echo $totalUser; ?></h2>
                <p>Total User</p>
            </div>
            <div class="box">
                <div class="icon"><i class="fas fa-file-alt"></i></div>
                <h2><?php echo $totalPost; ?></h2>
                <p>Total Post</p>
            </div>
            <div class="box">
                <div class="icon"><i class="fas fa-video"></i></div>
                <h2><?php echo $totalVideo; ?></h2>
                <p>Total Video</p>
            </div>
            <div class="box">
                <div class="icon"><i class="fas fa-music"></i></div>
                <h2><?php echo $totalSong; ?></h2>
                <p>Total Song</p>
            </div>
        </div>
        
        <div class="analytics-section">
            <div class="data-chart">
                <h3>Data Analytics</h3>
                <canvas id="chart"></canvas>
                <div class="legend">
                    <div><span class="total-user"></span> Total User</div>
                    <div><span class="total-video"></span> Total Video</div>
                    <div><span class="total-short"></span> Total Short</div>
                </div>
            </div>
            <div class="activity-section">
                <h3>Total User Activity</h3>
                <div class="activity-chart">
                    <div class="activity-percentage"><?php echo $activeUserPercentage; ?>%</div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        const ctx = document.getElementById('chart').getContext('2d');

        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['2024-07-15', '2024-08-02', '2024-08-15', '2024-10-09', '2024-10-14', '2024-10-28', '2024-11-02'],
                datasets: [
                    {
                        label: 'Total User',
                        data: [10, 15, 20, 30, 25, 40, <?php echo $totalUser; ?>],
                        borderColor: '#6b5af8',
                        fill: true,
                        backgroundColor: 'rgba(107, 90, 248, 0.2)'
                    },
                    {
                        label: 'Total Video',
                        data: [5, 8, 12, 18, 15, 20, <?php echo $totalVideo; ?>],
                        borderColor: '#333',
                        fill: true,
                        backgroundColor: 'rgba(51, 51, 51, 0.1)'
                    },
                    {
                        label: 'Total Short',
                        data: [2, 5, 7, 10, 8, 15, 3],
                        borderColor: '#dda0dd',
                        fill: true,
                        backgroundColor: 'rgba(221, 160, 221, 0.2)'
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: true
                    }
                }
            }
        });
    </script>
</body>
</html>
