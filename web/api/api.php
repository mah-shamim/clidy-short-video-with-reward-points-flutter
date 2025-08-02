

<?php

// Headers CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Manejar preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}
require_once '../config/database.php'; // Conexión a la base de datos

header("Content-Type: application/json");

// Definimos la URL base automáticamente
define('BASE_URL', 'https://' . $_SERVER['HTTP_HOST']);

// Conexión a la base de datos
$database = new Database();
$conn = $database->getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    // Verificar la acción
    if (isset($data['action'])) {
        // Acción para login...
        // Acción para login...
if ($data['action'] === 'login') {
    if (!empty($data['email']) && !empty($data['password'])) {
        // Consulta para verificar si el usuario existe
        $query = "SELECT id, name, username, email, password FROM users WHERE email = :email";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':email', $data['email']);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($data['password'], $user['password'])) {
            // Generar token
            $token = bin2hex(random_bytes(32)); // Genera un token aleatorio
            
            // Opcional: Guardar el token en la base de datos
            $updateTokenQuery = "UPDATE users SET auth_token = :token WHERE id = :id";
            $updateStmt = $conn->prepare($updateTokenQuery);
            $updateStmt->bindParam(':token', $token);
            $updateStmt->bindParam(':id', $user['id']);
            $updateStmt->execute();

            // Si el login es exitoso
            http_response_code(200);
            echo json_encode([
                "message" => "Login successful.",
                "user" => [
                    "id" => $user['id'],
                    "name" => $user['name'],
                    "username" => $user['username'],
                    "email" => $user['email'],
                    "token" => $token // Incluir el token en la respuesta
                ]
            ]);
            exit();
        } else {
            http_response_code(401);
            echo json_encode(["message" => "Invalid email or password."]);
            exit();
        }
    } else {
        http_response_code(400);
        echo json_encode(["message" => "Email and password are required."]);
        exit();
    }
}

        // Acción para registro de usuario
        else if ($data['action'] === 'register') {
            if (!empty($data['name']) && !empty($data['username']) && !empty($data['email']) && !empty($data['password'])) {

                // Verificar si el usuario ya existe con el mismo correo electrónico
                $query = "SELECT id FROM users WHERE email = :email";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':email', $data['email']);
                $stmt->execute();

                if ($stmt->rowCount() > 0) {
                    // Usuario ya registrado
                    http_response_code(409); // Código 409: Conflicto
                    echo json_encode(["message" => "El correo electrónico ya está en uso."]);
                    exit();
                } else {
                    // Registrar el nuevo usuario
                    $query = "INSERT INTO users (name, username, email, password) VALUES (:name, :username, :email, :password)";
                    $stmt = $conn->prepare($query);

                    // Cifrar la contraseña
                    $hashed_password = password_hash($data['password'], PASSWORD_BCRYPT);

                    $stmt->bindParam(':name', $data['name']);
                    $stmt->bindParam(':username', $data['username']);
                    $stmt->bindParam(':email', $data['email']);
                    $stmt->bindParam(':password', $hashed_password);

                    if ($stmt->execute()) {
                        // Registro exitoso
                        http_response_code(201); // Código 201: Creado
                        echo json_encode(["message" => "Usuario registrado correctamente."]);
                        exit();
                    } else {
                        // Error al registrar
                        http_response_code(500); // Código 500: Error interno del servidor
                        echo json_encode(["message" => "No se pudo registrar el usuario."]);
                        exit();
                    }
                }
            } else {
                // Datos incompletos
                http_response_code(400); // Código 400: Solicitud incorrecta
                echo json_encode(["message" => "Todos los campos son obligatorios."]);
                exit();
            }
        } 
        
        // Acción para obtener todos los videos
        else if ($data['action'] === 'getAllVideos') {
    try {
        if (!empty($data['user_id'])) {
            $user_id = $data['user_id'];

            $query = "SELECT 
                v.id, v.description, v.hashtag, v.video_path, v.thumbnail, 
                v.created_date, u.id as user_id, u.username, 
                COALESCE(u.profile_image, '') AS profile_image, 
                v.favorites_count, 
                (SELECT COUNT(*) FROM comments WHERE video_id = v.id) AS comment_count,  
                CASE 
                    WHEN v.favorites LIKE CONCAT('%', :user_id, '%') THEN 1 
                    ELSE 0 
                END AS is_favorite
            FROM videos v
            JOIN users u ON v.user_id = u.id";

            $stmt = $conn->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->execute();
            $videos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if ($videos) {
                foreach ($videos as &$video) {
                    $video['is_favorite'] = $video['is_favorite'] > 0;

                    // Verificar si la ruta ya es completa para evitar duplicación
                    $video['video_path'] = strpos($video['video_path'], 'http') === 0 
                        ? $video['video_path'] 
                        : BASE_URL . "/uploads/videos/" . $video['video_path'];

                    $video['thumbnail'] = strpos($video['thumbnail'], 'http') === 0 
                        ? $video['thumbnail'] 
                        : BASE_URL . "/uploads/thumbnails/" . $video['thumbnail'];

                    $video['profile_image'] = !empty($video['profile_image'])
                        ? (strpos($video['profile_image'], 'http') === 0 
                            ? $video['profile_image'] 
                            : BASE_URL . "/uploads/profile_image/" . $video['profile_image'])
                        : BASE_URL . "/assets/default_profile.png";
                }

                http_response_code(200);
                echo json_encode([
                    "message" => "Videos retrieved successfully.",
                    "videos" => $videos
                ]);
                exit();
            } else {
                http_response_code(404);
                echo json_encode(["message" => "No videos available."]);
                exit();
            }
        } else {
            http_response_code(400);
            echo json_encode(["message" => "User ID is required."]);
            exit();
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["message" => "Error retrieving videos: " . $e->getMessage()]);
        exit();
    }
}

else if ($data['action'] === 'searchVideos') {
    $query = isset($data['query']) ? trim($data['query']) : '';

    if (!empty($query)) {
        $searchTerm = "%" . $query . "%";

        // Agregar el JOIN para obtener el `username` del usuario que subió el video
        $sql = "SELECT v.id, v.description, v.hashtag, v.video_path, v.thumbnail, v.created_date,
                       u.username
                FROM videos v
                JOIN users u ON v.user_id = u.id
                WHERE v.description LIKE :query OR v.hashtag LIKE :query
                ORDER BY v.created_date DESC";
                
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':query', $searchTerm, PDO::PARAM_STR);

        if ($stmt->execute()) {
            $videos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($videos as &$video) {
                $video['video_path'] = BASE_URL . "/uploads/videos/" . $video['video_path'];
                $video['thumbnail'] = BASE_URL . "/uploads/thumbnails/" . $video['thumbnail'];
            }

            http_response_code(200);
            echo json_encode([
                "message" => "Videos retrieved successfully.",
                "videos" => $videos
            ]);
            exit();
        }
    }
}


        // Acción para agregar un comentario a un video
        else if ($data['action'] === 'addComment') {
            if (!empty($data['video_id']) && !empty($data['user_id']) && !empty($data['comment'])) {
                $video_id = $data['video_id'];
                $user_id = $data['user_id'];
                $comment = $data['comment'];

                // Consulta para insertar el comentario
                $query = "INSERT INTO comments (video_id, user_id, comment) VALUES (:video_id, :user_id, :comment)";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':video_id', $video_id);
                $stmt->bindParam(':user_id', $user_id);
                $stmt->bindParam(':comment', $comment);

                if ($stmt->execute()) {
                    http_response_code(201); // Código 201: Creado
                    echo json_encode(["message" => "Comentario agregado correctamente."]);
                    exit();
                } else {
                    http_response_code(500); // Código 500: Error interno del servidor
                    echo json_encode(["message" => "No se pudo agregar el comentario."]);
                    exit();
                }
            } else {
                http_response_code(400); // Código 400: Solicitud incorrecta
                echo json_encode(["message" => "Video ID, User ID y Comment son requeridos."]);
                exit();
            }
        }

        // Acción para obtener los comentarios de un video
       else if ($data['action'] === 'getComments') {
    if (!empty($data['video_id'])) {
        $video_id = $data['video_id'];

        // Consulta para obtener los comentarios del video con la URL completa de la imagen
        $query = "SELECT c.comment, c.created_at, u.username, 
                         CASE 
                            WHEN u.profile_image IS NOT NULL 
                            THEN CONCAT('" . BASE_URL . "/uploads/profile_image/', u.profile_image)
                            ELSE 'https://via.placeholder.com/30' 
                         END AS profile_image
                  FROM comments c 
                  JOIN users u ON c.user_id = u.id 
                  WHERE c.video_id = :video_id 
                  ORDER BY c.created_at DESC";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':video_id', $video_id);
        $stmt->execute();
        $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if ($comments) {
            http_response_code(200); // Código 200: éxito
            echo json_encode([
                "message" => "Comentarios obtenidos correctamente.",
                "comments" => $comments
            ]);
            exit();
        } else {
            http_response_code(404); // Código 404: No encontrado
            echo json_encode(["message" => "No hay comentarios para este video."]);
            exit();
        }
    } else {
        http_response_code(400); // Código 400: Solicitud incorrecta
        echo json_encode(["message" => "Video ID es requerido."]);
        exit();
    }
}



        else if ($data['action'] === 'getUserData') {
    if (!empty($data['user_id'])) {
        $user_id = $data['user_id'];

        // Consulta para obtener los datos del usuario
        $query = "SELECT id, name, username, email, profile_image, followers, following, points 
                  FROM users 
                  WHERE id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':id', $user_id);

        if ($stmt->execute()) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user) {
                // Validar y generar la URL de la imagen de perfil
                $user['profile_image'] = !empty($user['profile_image']) 
                    ? BASE_URL . "/uploads/profile_image/" . $user['profile_image'] 
                    : 'https://via.placeholder.com/80'; // Imagen por defecto

                http_response_code(200); // Éxito
                echo json_encode([
                    "message" => "User data retrieved successfully.",
                    "user" => $user
                ]);
            } else {
                http_response_code(404); // Usuario no encontrado
                echo json_encode(["message" => "User not found."]);
            }
        } else {
            http_response_code(500); // Error de consulta
            echo json_encode(["message" => "Error executing query."]);
        }
    } else {
        http_response_code(400); // Solicitud incorrecta
        echo json_encode(["message" => "User ID is required."]);
    }
    exit();
}

  
  // Acción para obtener el conteo de posts de un usuario
else if ($data['action'] === 'getPostCount') {
    if (!empty($data['user_id'])) {
        $user_id = $data['user_id'];

        try {
            // Consulta para obtener el número de videos del usuario
            $query = "SELECT COUNT(*) AS post_count FROM videos WHERE user_id = :user_id";
            $stmt = $conn->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($result) {
                http_response_code(200); // Éxito
                echo json_encode([
                    "message" => "Post count retrieved successfully.",
                    "post_count" => (int) $result['post_count']
                ]);
            } else {
                http_response_code(404); // No encontrado
                echo json_encode(["message" => "No posts found for this user."]);
            }
        } catch (PDOException $e) {
            http_response_code(500); // Error interno del servidor
            echo json_encode(["message" => "Error retrieving post count: " . $e->getMessage()]);
        }
    } else {
        http_response_code(400); // Solicitud incorrecta
        echo json_encode(["message" => "User ID is required."]);
    }
    exit();
}



        // Acción para obtener datos específicos de un video
        else if ($data['action'] === 'getVideoData') {
    if (!empty($data['video_id'])) {
        $video_id = $data['video_id'];

        $query = "SELECT v.description, v.hashtag, u.username, u.profile_image, 
                         v.favorites_count, (SELECT COUNT(*) FROM comments WHERE video_id = v.id) AS comment_count 
                  FROM videos v
                  JOIN users u ON v.user_id = u.id
                  WHERE v.id = :video_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':video_id', $video_id);
        $stmt->execute();
        $video = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($video) {
            // Agregar la URL completa al profile_image
            $video['profile_image'] = !empty($video['profile_image']) 
                ? BASE_URL . "/uploads/profile_image/" . $video['profile_image'] 
                : 'https://via.placeholder.com/80';

            http_response_code(200); // Código 200: éxito
            echo json_encode([
                "message" => "Video data retrieved successfully.",
                "video" => [
                    "description" => $video['description'],
                    "hashtags" => $video['hashtag'],
                    "username" => $video['username'],
                    "profile_image" => $video['profile_image'],
                    "favorites_count" => $video['favorites_count'] ?? 0,
                    "comment_count" => $video['comment_count'] ?? 0
                ]
            ]);
            exit();
        } else {
            http_response_code(404); // No encontrado
            echo json_encode(["message" => "Video not found."]);
            exit();
        }
    } else {
        http_response_code(400); // Solicitud incorrecta
        echo json_encode(["message" => "Video ID is required."]);
        exit();
    }
}




        // Acción para actualizar el username y email
        else if ($data['action'] === 'updateUserData') {
    if (!empty($data['user_id'])) {
        $user_id = $data['user_id'];
        $new_username = !empty($data['new_username']) ? $data['new_username'] : null;
        $new_email = !empty($data['new_email']) ? $data['new_email'] : null;
        
        // Crear la consulta dinámicamente según los campos enviados
        $fields = [];
        if ($new_username) {
            $fields[] = "username = :new_username";
        }
        if ($new_email) {
            $fields[] = "email = :new_email";
        }

        if (count($fields) === 0) {
            http_response_code(400);
            echo json_encode(["message" => "No hay cambios para actualizar."]);
            exit();
        }

        $query = "UPDATE users SET " . implode(', ', $fields) . " WHERE id = :id";
        $stmt = $conn->prepare($query);

        // Enlazar parámetros según los campos enviados
        if ($new_username) {
            $stmt->bindParam(':new_username', $new_username);
        }
        if ($new_email) {
            $stmt->bindParam(':new_email', $new_email);
        }
        $stmt->bindParam(':id', $user_id);

        // Ejecutar la consulta y verificar si se actualizó
        if ($stmt->execute()) {
            http_response_code(200); // Éxito
            echo json_encode(["message" => "User data updated successfully."]);
        } else {
            http_response_code(500); // Error interno del servidor
            echo json_encode(["message" => "Failed to update user data."]);
        }
    } else {
        http_response_code(400); // Solicitud incorrecta
        echo json_encode(["message" => "User ID is required."]);
    }
    exit();
}

        // Acción para agregar un seguidor
        else if ($data['action'] === 'addFollower') {
            if (!empty($data['user_id']) && !empty($data['follower_id'])) {
                $user_id = $data['user_id']; // ID del usuario al que se sigue
                $follower_id = $data['follower_id']; // ID del usuario que está siguiendo

                // Actualizar el conteo de seguidores del usuario seguido
                $query = "UPDATE users SET followers = followers + 1 WHERE id = :id";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':id', $user_id);

                // Actualizar el conteo de los que sigue el usuario que sigue
                $queryFollowing = "UPDATE users SET following = following + 1 WHERE id = :follower_id";
                $stmtFollowing = $conn->prepare($queryFollowing);
                $stmtFollowing->bindParam(':follower_id', $follower_id);

                // Ejecutar ambas consultas
                if ($stmt->execute() && $stmtFollowing->execute()) {
                    http_response_code(200); // Código 200: éxito
                    echo json_encode(["message" => "Follower added successfully."]);
                    exit();
                } else {
                    http_response_code(500); // Código 500: Error interno del servidor
                    echo json_encode(["message" => "Failed to add follower."]);
                    exit();
                }
            } else {
                http_response_code(400); // Código 400: Solicitud incorrecta
                echo json_encode(["message" => "User ID and follower ID are required."]);
                exit();
            }
        }


        // Acción para eliminar un seguidor
        else if ($data['action'] === 'removeFollower') {
            if (!empty($data['user_id']) && !empty($data['follower_id'])) {
                $user_id = $data['user_id']; // ID del usuario al que se deja de seguir
                $follower_id = $data['follower_id']; // ID del usuario que está dejando de seguir

                // Actualizar el conteo de seguidores del usuario seguido
                $query = "UPDATE users SET followers = followers - 1 WHERE id = :id AND followers > 0";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':id', $user_id);

                // Actualizar el conteo de los que sigue el usuario que deja de seguir
                $queryFollowing = "UPDATE users SET following = following - 1 WHERE id = :follower_id AND following > 0";
                $stmtFollowing = $conn->prepare($queryFollowing);
                $stmtFollowing->bindParam(':follower_id', $follower_id);

                // Ejecutar ambas consultas
                if ($stmt->execute() && $stmtFollowing->execute()) {
                    http_response_code(200); // Código 200: éxito
                    echo json_encode(["message" => "Follower removed successfully."]);
                    exit();
                } else {
                    http_response_code(500); // Código 500: Error interno del servidor
                    echo json_encode(["message" => "Failed to remove follower."]);
                    exit();
                }
            } else {
                http_response_code(400); // Código 400: Solicitud incorrecta
                echo json_encode(["message" => "User ID and follower ID are required."]);
                exit();
            }
        }

        //funcion de agrega favoritos
        else if ($data['action'] === 'addFavorite') {
            if (!empty($data['video_id']) && !empty($data['user_id'])) {
                $video_id = $data['video_id'];
                $user_id = $data['user_id'];

                $updateQuery = "UPDATE videos 
                                SET favorites = CONCAT(IFNULL(favorites, ''), ',', :user_id), 
                                    favorites_count = favorites_count + 1 
                                WHERE id = :video_id";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bindParam(':user_id', $user_id);
                $stmt->bindParam(':video_id', $video_id);

                if ($stmt->execute()) {
                    http_response_code(200);
                    echo json_encode(["message" => "Favorite added successfully."]);
                    exit();
                } else {
                    http_response_code(500);
                    echo json_encode(["message" => "Failed to add favorite."]);
                    exit();
                }
            } else {
                http_response_code(400);
                echo json_encode(["message" => "Video ID and User ID are required."]);
                exit();
            }
        }




        // Función para remover favoritos
        else if ($data['action'] === 'removeFavorite') {
            if (!empty($data['video_id']) && !empty($data['user_id'])) {
                $video_id = $data['video_id'];
                $user_id = $data['user_id'];

                $updateQuery = "UPDATE videos 
                                SET favorites = TRIM(BOTH ',' FROM REPLACE(favorites, CONCAT(',', :user_id), '')),
                                    favorites_count = CASE WHEN favorites_count > 0 THEN favorites_count - 1 ELSE 0 END
                                WHERE id = :video_id";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bindParam(':user_id', $user_id);
                $stmt->bindParam(':video_id', $video_id);

                if ($stmt->execute()) {
                    http_response_code(200);
                    echo json_encode(["message" => "Favorite removed successfully."]);
                    exit();
                } else {
                    http_response_code(500);
                    echo json_encode(["message" => "Failed to remove favorite."]);
                    exit();
                }
            } else {
                http_response_code(400);
                echo json_encode(["message" => "Video ID and User ID are required."]);
                exit();
            }
        }


        // Acción para subir la imagen de perfil
        else if ($data['action'] === 'uploadProfileImage') {
            // Verificar que el user_id y la imagen están presentes
            if (!empty($data['user_id']) && !empty($data['image_data'])) {
                $user_id = $data['user_id'];
                $image_data = $data['image_data']; // La imagen debería enviarse como una cadena Base64

                // Decodificar la imagen de base64
                $image = base64_decode($image_data);
                $file_name = 'profile_' . $user_id . '.png';
                $file_path = '../uploads/profile_image/' . $file_name; // Ruta completa para guardar la imagen

                // Crear la carpeta si no existe
                if (!file_exists('../uploads/profile_image')) {
                    mkdir('../uploads/profile_image', 0777, true);
                }

                // Guardar la imagen en el servidor
                if (file_put_contents($file_path, $image)) {
                    // Actualizar la ruta de la imagen en la base de datos
                    $query = "UPDATE users SET profile_image = :profile_image WHERE id = :id";
                    $stmt = $conn->prepare($query);
                    $stmt->bindParam(':profile_image', $file_name); // Guardar solo el nombre del archivo en la base de datos
                    $stmt->bindParam(':id', $user_id);

                    if ($stmt->execute()) {
                        http_response_code(200);
                        echo json_encode(["message" => "Profile image uploaded successfully."]);
                        exit();
                    } else {
                        http_response_code(500);
                        echo json_encode(["message" => "Failed to update profile image path in the database."]);
                        exit();
                    }
                } else {
                    http_response_code(500);
                    echo json_encode(["message" => "Failed to save profile image."]);
                    exit();
                }
            } else {
                http_response_code(400);
                echo json_encode(["message" => "User ID and image data are required."]);
                exit();
            }
        }

        // Acción para obtener todas las canciones
        else if ($data['action'] === 'getSongs') {
            try {
                // Consulta para obtener todas las canciones de la base de datos
                $query = "SELECT s.id, s.singer, s.song_title, s.song_duration, s.song_file, c.name AS category
                          FROM songs s
                          LEFT JOIN categories c ON s.category = c.id";
                $stmt = $conn->prepare($query);
                $stmt->execute();
                $songs = $stmt->fetchAll(PDO::FETCH_ASSOC);

                // Verificar si hay canciones
                if ($songs) {
                    http_response_code(200); // Código 200: éxito
                    echo json_encode([
                        "message" => "Songs retrieved successfully.",
                        "songs" => $songs
                    ]);
                    exit();
                } else {
                    // No hay canciones disponibles
                    http_response_code(404); // Código 404: No encontrado
                    echo json_encode(["message" => "No songs available."]);
                    exit();
                }
            } catch (PDOException $e) {
                http_response_code(500); // Código 500: Error interno del servidor
                echo json_encode(["message" => "Error retrieving songs: " . $e->getMessage()]);
                exit();
            }
        }

        // Acción para obtener los videos del usuario
        else if ($data['action'] === 'getUserVideos') {
            // Verificar que el user_id está presente en la solicitud
            if (!empty($data['user_id'])) {
                $user_id = $data['user_id'];

                // Consulta para obtener los videos del usuario
                $query = "SELECT id, video_path, thumbnail, created_date, music_file
                  FROM videos
                  WHERE user_id = :user_id";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':user_id', $user_id);
                $stmt->execute();
                $videos = $stmt->fetchAll(PDO::FETCH_ASSOC);

                if ($videos) {
                    // Mapeamos cada video para incluir las URLs completas
                    foreach ($videos as &$video) {
                        $video['video_path'] = "uploads/videos/" . basename($video['video_path']);
                        $video['thumbnail'] = "uploads/thumbnails/" . basename($video['thumbnail']);
                    }


                    http_response_code(200); // Código 200: éxito
                    echo json_encode([
                        "message" => "Videos retrieved successfully.",
                        "videos" => $videos
                    ]);
                    exit();
                } else {
                    // No hay videos disponibles
                    http_response_code(404); // Código 404: No encontrado
                    echo json_encode(["message" => "No videos found for this user."]);
                    exit();
                }
            } else {
                // ID del usuario no proporcionado
                http_response_code(400); // Código 400: Solicitud incorrecta
                echo json_encode(["message" => "User ID is required."]);
                exit();
            }
        }

        // Acción para obtener todos los hashtags
        else if ($data['action'] === 'getHashtags') {
            try {
                // Consulta para obtener todos los hashtags
                $query = "SELECT id, name, usage_count, DATE_FORMAT(created_date, '%d %M %Y') as created_date FROM hashtags";
                $stmt = $conn->prepare($query);
                $stmt->execute();
                $hashtags = $stmt->fetchAll(PDO::FETCH_ASSOC);

                // Verificar si hay hashtags
                if ($hashtags) {
                    http_response_code(200); // Código 200: éxito
                    echo json_encode([
                        "message" => "Hashtags retrieved successfully.",
                        "hashtags" => $hashtags
                    ]);
                    exit();
                } else {
                    // No hay hashtags disponibles
                    http_response_code(404); // Código 404: No encontrado
                    echo json_encode(["message" => "No hashtags available."]);
                    exit();
                }
            } catch (PDOException $e) {
                http_response_code(500); // Código 500: Error interno del servidor
                echo json_encode(["message" => "Error retrieving hashtags: " . $e->getMessage()]);
                exit();
            }
        } else if ($data['action'] === 'getPointsAndAmount') {
            try {
                // Consulta para obtener los puntos y el monto desde la configuración de recompensas
                $query = "SELECT points, amount FROM reward_settings ORDER BY id DESC LIMIT 1";
                $stmt = $conn->prepare($query);
                $stmt->execute();
                $settings = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($settings) {
                    http_response_code(200); // Código 200: éxito
                    echo json_encode([
                        "message" => "Points and amount retrieved successfully.",
                        "points_and_amount" => $settings, // Devolvemos los datos como JSON
                        "currency_code" => "USD" // Código de moneda fijo
                    ]);
                } else {
                    http_response_code(404); // Código 404: No encontrado
                    echo json_encode(["message" => "No reward settings found."]);
                }
            } catch (PDOException $e) {
                http_response_code(500); // Código 500: Error interno del servidor
                echo json_encode(["message" => "Error retrieving points and amount: " . $e->getMessage()]);
            }
            exit();
        } else if ($data['action'] === 'getUserPoints') {
            if (!empty($data['user_id'])) {
                $user_id = $data['user_id'];

                try {
                    $query = "SELECT points FROM users WHERE id = :user_id";
                    $stmt = $conn->prepare($query);
                    $stmt->bindParam(':user_id', $user_id);
                    $stmt->execute();
                    $user = $stmt->fetch(PDO::FETCH_ASSOC);

                    if ($user) {
                        http_response_code(200); // Éxito
                        echo json_encode([
                            "message" => "User points retrieved successfully.",
                            "points" => $user['points'] ?? 0 // Asegurarse de devolver 0 si es null
                        ]);
                    } else {
                        http_response_code(404); // Usuario no encontrado
                        echo json_encode(["message" => "User not found."]);
                    }
                } catch (Exception $e) {
                    http_response_code(500); // Error del servidor
                    echo json_encode(["message" => "Error retrieving points: " . $e->getMessage()]);
                }
            } else {
                http_response_code(400); // Solicitud incorrecta
                echo json_encode(["message" => "User ID is required."]);
            }
            exit();
        }



        // Acción para obtener todos los videos de un usuario con hashtags y descripciones
        else if ($data['action'] === 'getUserVideosWithHashtags') {
            if (!empty($data['user_id'])) {
                $user_id = $data['user_id'];
                error_log("Obteniendo videos para user_id: $user_id");

                // Asegúrate de que la consulta está correcta
                $query = "SELECT * FROM videos WHERE user_id = :user_id";
                $stmt = $conn->prepare($query);
                $stmt->bindParam(':user_id', $user_id);

                if ($stmt->execute()) {
                    $videos = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    error_log("Videos encontrados para user_id $user_id: " . print_r($videos, true));

                    if ($videos) {
                        http_response_code(200);
                        echo json_encode([
                            "message" => "Videos retrieved successfully.",
                            "videos" => $videos
                        ]);
                    } else {
                        error_log("No se encontraron videos para user_id: $user_id");
                        http_response_code(404);
                        echo json_encode(["message" => "No videos found for this user."]);
                    }
                } else {
                    error_log("Error al ejecutar la consulta de getUserVideosWithHashtags: " . print_r($stmt->errorInfo(), true));
                    http_response_code(500);
                    echo json_encode(["message" => "Error executing query."]);
                }
                exit();
            }
        }


        // Acción para obtener la configuración del sistema de recompensas
        else if ($data['action'] === 'getRewardSettings') {
            try {
                // Consulta para obtener las configuraciones más recientes
                $query = "SELECT * FROM reward_settings ORDER BY id DESC LIMIT 1";
                $stmt = $conn->prepare($query);
                $stmt->execute();
                $rewardSettings = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($rewardSettings) {
                    http_response_code(200); // Éxito
                    echo json_encode([
                        "message" => "Reward settings retrieved successfully.",
                        "reward_settings" => $rewardSettings
                    ]);
                } else {
                    http_response_code(404); // No encontrado
                    echo json_encode(["message" => "No reward settings found."]);
                }
            } catch (PDOException $e) {
                http_response_code(500); // Error interno del servidor
                echo json_encode(["message" => "Error retrieving reward settings: " . $e->getMessage()]);
            }
            exit();
        }


        // Acción para obtener la configuración de las actividades del sistema de recompensas
        else if ($data['action'] === 'getActivitySettings') {
            try {
                $query = "SELECT 
                    registration_points, registration_enabled, 
                    refer_points, refer_enabled, 
                    video_points, video_enabled 
                  FROM reward_settings 
                  ORDER BY id DESC LIMIT 1";
                $stmt = $conn->prepare($query);
                $stmt->execute();
                $settings = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($settings) {
                    http_response_code(200); // Éxito
                    echo json_encode([
                        "message" => "Activity settings retrieved successfully.",
                        "activity_settings" => $settings
                    ]);
                } else {
                    http_response_code(404); // No encontrado
                    echo json_encode(["message" => "No activity settings found."]);
                }
            } catch (PDOException $e) {
                http_response_code(500); // Error interno
                echo json_encode(["message" => "Error retrieving activity settings: " . $e->getMessage()]);
            }
            exit();
        } else if ($data['action'] === 'uploadVideo') {
            if (!empty($data['user_id']) && !empty($data['description']) && !empty($data['video_data'])) {
                $user_id = $data['user_id'];
                $description = $data['description'];
                $video_data = $data['video_data'];
                $thumbnail_data = $data['thumbnail_data'] ?? null;  // Opcional
                $hashtags = $data['hashtags'] ?? [];  // Opcional
                $audio_name = $data['audio_name'] ?? null;  // Opcional

                try {
                    // Verificar si el usuario existe
                    $user_check_query = "SELECT id FROM users WHERE id = :user_id";
                    $user_stmt = $conn->prepare($user_check_query);
                    $user_stmt->bindParam(':user_id', $user_id);
                    $user_stmt->execute();

                    if ($user_stmt->rowCount() === 0) {
                        http_response_code(404); // Usuario no encontrado
                        echo json_encode(["message" => "User not found."]);
                        exit();
                    }

                    // Guardar el video en el servidor
                    $video_file_name = 'video_' . uniqid() . '.mp4';
                    $video_file_path = '../uploads/videos/' . $video_file_name;
                    if (!file_put_contents($video_file_path, base64_decode($video_data))) {
                        http_response_code(500); // Error al guardar el video
                        echo json_encode(["message" => "Failed to save video."]);
                        exit();
                    }

                    // Guardar el thumbnail si se envía
                    $thumbnail_file_name = null;
                    if ($thumbnail_data) {
                        $thumbnail_file_name = 'thumb_' . uniqid() . '.png';
                        $thumbnail_file_path = '../uploads/thumbnails/' . $thumbnail_file_name;
                        if (!file_put_contents($thumbnail_file_path, base64_decode($thumbnail_data))) {
                            http_response_code(500); // Error al guardar el thumbnail
                            echo json_encode(["message" => "Failed to save thumbnail."]);
                            exit();
                        }
                    }

                    // Insertar el video en la base de datos
                    $insert_video_query = "INSERT INTO videos (user_id, description, video_path, thumbnail, hashtag, music_file, review_status) 
                                           VALUES (:user_id, :description, :video_path, :thumbnail, :hashtag, :music_file, 0)";
                    $insert_stmt = $conn->prepare($insert_video_query);
                    $insert_stmt->bindParam(':user_id', $user_id);
                    $insert_stmt->bindParam(':description', $description);
                    $insert_stmt->bindParam(':video_path', $video_file_name);
                    $insert_stmt->bindParam(':thumbnail', $thumbnail_file_name);
                    $insert_stmt->bindParam(':hashtag', implode(',', $hashtags));
                    $insert_stmt->bindParam(':music_file', $audio_name);

                    if ($insert_stmt->execute()) {
                        // Actualizar los puntos del usuario
                        $update_points_query = "UPDATE users SET points = points + 10 WHERE id = :user_id";
                        $update_points_stmt = $conn->prepare($update_points_query);
                        $update_points_stmt->bindParam(':user_id', $user_id);
                        $update_points_stmt->execute();

                        http_response_code(200); // Éxito
                        echo json_encode(["status" => "success", "message" => "Video uploaded successfully and points added."]);
                    } else {
                        http_response_code(500); // Error al insertar en la base de datos
                        echo json_encode(["message" => "Failed to insert video into database."]);
                    }
                } catch (Exception $e) {
                    http_response_code(500); // Error del servidor
                    echo json_encode(["message" => "Error uploading video: " . $e->getMessage()]);
                }
            } else {
                http_response_code(400); // Solicitud incorrecta
                echo json_encode(["message" => "Required fields are missing."]);
            }
            exit();
        }



        // Acción inválida
        else {
            http_response_code(400); // Código 400: Solicitud incorrecta
            echo json_encode(["message" => "Invalid action."]);
            exit();
        }
    } else {
        http_response_code(400); // Código 400: Solicitud incorrecta
        echo json_encode(["message" => "Action is required."]);
        exit();
    }
} else {
    // Si el método HTTP no es POST, devolver un error 405
    http_response_code(405); // Código 405: Método no permitido
    echo json_encode(["message" => "Invalid request method. Only POST is allowed."]);
    exit();
}