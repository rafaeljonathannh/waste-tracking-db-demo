<?php
class Database {
    private $host = "localhost";
    private $db_name = "fp_mbd";
    private $username = "root";
    private $password = "";
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, 
                                $this->username, $this->password);
            $this->conn->exec("set names utf8");
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            echo "Connection error: " . $exception->getMessage();
        }
        return $this->conn;
    }

    // Method untuk execute stored procedure
    public function callProcedure($procedureName, $params = []) {
        try {
            $placeholders = str_repeat('?,', count($params));
            $placeholders = rtrim($placeholders, ',');
            
            $sql = "CALL {$procedureName}({$placeholders})";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch(PDOException $e) {
            return ['error' => $e->getMessage()];
        }
    }

    // Method untuk execute function
    public function callFunction($functionName, $params = []) {
        try {
            $placeholders = str_repeat('?,', count($params));
            $placeholders = rtrim($placeholders, ',');
            
            $sql = "SELECT {$functionName}({$placeholders}) as result";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['result'];
        } catch(PDOException $e) {
            return ['error' => $e->getMessage()];
        }
    }

    // Method untuk execute query biasa
    public function query($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch(PDOException $e) {
            return ['error' => $e->getMessage()];
        }
    }

    // Method untuk execute insert/update/delete
    public function execute($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute($params);
        } catch(PDOException $e) {
            return ['error' => $e->getMessage()];
        }
    }
}
?>