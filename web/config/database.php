<?php
// proyect/config/database.php
// proyect/config/database.php

class Database {
    private $host = 'localhost';
    private $db_name = 'dkawoco1_democlidy';
    private $username = 'dkawoco1_democlidy';
    private $password = '02aV-227ny%U';
    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO('mysql:host=' . $this->host . ';dbname=' . $this->db_name, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION); // Agregar modo de error
            $this->conn->exec('set names utf8');
            // echo 'Conexi¨®n exitosa xd'; // Comentado para evitar salida extra
        } catch (PDOException $exception) {
            // Mostrar el error exacto si la conexi¨®n falla
            die('Error de conexi¨®n: ' . $exception->getMessage());
        }

        return $this->conn;
    }
}
