<?php
// test_connection.php - Simpan file ini di C:\xampp\htdocs\waste-tracking-db-demo\

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>🔍 Database Connection Test</h2>";

try {
    // Test database connection
    require_once 'src/config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if ($conn) {
        echo "<div style='color: green; font-weight: bold;'>✅ Database Connection: SUCCESS</div>";
        
        // Test query untuk check tabel
        $stmt = $conn->query("SHOW TABLES");
        $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        echo "<h3>📋 Available Tables:</h3>";
        echo "<ul>";
        foreach ($tables as $table) {
            echo "<li>$table</li>";
        }
        echo "</ul>";
        
        // Test salah satu function
        echo "<h3>🧪 Test Database Function:</h3>";
        $stmt = $conn->query("SELECT COUNT(*) as total_students FROM student");
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "<p><strong>Total Students:</strong> " . $result['total_students'] . "</p>";
        
    } else {
        echo "<div style='color: red; font-weight: bold;'>❌ Database Connection: FAILED</div>";
    }
    
} catch (Exception $e) {
    echo "<div style='color: red; font-weight: bold;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</div>";
}

echo "<hr>";
echo "<h3>🔧 Troubleshooting Checklist:</h3>";
echo "<ul>";
echo "<li>✅ XAMPP Apache running</li>";
echo "<li>✅ XAMPP MySQL running</li>";
echo "<li>✅ Database 'fp_mbd' exists</li>";
echo "<li>✅ Files uploaded to htdocs</li>";
echo "</ul>";

echo "<p><a href='public/' style='color: blue; text-decoration: underline;'>→ Go to Main Website</a></p>";
?>