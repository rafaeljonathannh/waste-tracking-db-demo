<?php
// 🚀 WASTE TRACKING DB DEMO - AUTO FIX SCRIPT
// Simpan sebagai: C:\xampp\htdocs\waste-tracking-db-demo\auto_fix.php
// Akses: http://localhost/waste-tracking-db-demo/auto_fix.php

error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
<!DOCTYPE html>
<html>
<head>
    <title>🚀 Auto Fix - Waste Tracking DB Demo</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #00ff00; padding: 20px; }
        .success { color: #00ff00; }
        .error { color: #ff0000; }
        .warning { color: #ffaa00; }
        .info { color: #00aaff; }
        .box { border: 1px solid #333; padding: 15px; margin: 10px 0; background: #222; }
        button { background: #00ff00; color: #000; padding: 10px 20px; border: none; cursor: pointer; font-weight: bold; }
        button:hover { background: #00aa00; }
        pre { background: #000; padding: 10px; border-left: 3px solid #00ff00; overflow-x: auto; }
    </style>
</head>
<body>

<h1>🚀 WASTE TRACKING DB DEMO - AUTO FIX</h1>
<p class="info">Script ini akan automatically detect dan fix semua masalah!</p>

<?php
if ($_GET['action'] ?? '' === 'fix') {
    echo "<div class='box'>";
    echo "<h2>🔄 STARTING AUTO FIX PROCESS...</h2>";
    
    $success_count = 0;
    $total_checks = 8;
    
    // ===============================
    // CHECK 1: XAMPP Services
    // ===============================
    echo "<h3>📋 CHECK 1: XAMPP Services</h3>";
    
    // Test MySQL connection
    try {
        $test_conn = new PDO("mysql:host=localhost", "root", "");
        echo "<span class='success'>✅ MySQL: RUNNING</span><br>";
        $success_count++;
    } catch (Exception $e) {
        echo "<span class='error'>❌ MySQL: NOT RUNNING - START XAMPP MYSQL!</span><br>";
    }
    
    // ===============================
    // CHECK 2: Database Exists
    // ===============================
    echo "<h3>📋 CHECK 2: Database fp_mbd</h3>";
    
    try {
        $conn = new PDO("mysql:host=localhost", "root", "");
        
        // Check if database exists
        $stmt = $conn->query("SHOW DATABASES LIKE 'fp_mbd'");
        if ($stmt->rowCount() > 0) {
            echo "<span class='success'>✅ Database fp_mbd: EXISTS</span><br>";
            $success_count++;
        } else {
            echo "<span class='warning'>⚠️ Database fp_mbd: MISSING - CREATING...</span><br>";
            $conn->exec("CREATE DATABASE fp_mbd");
            echo "<span class='success'>✅ Database fp_mbd: CREATED</span><br>";
            $success_count++;
        }
    } catch (Exception $e) {
        echo "<span class='error'>❌ Database Error: " . $e->getMessage() . "</span><br>";
    }
    
    // ===============================
    // CHECK 3: Database Schema
    // ===============================
    echo "<h3>📋 CHECK 3: Database Schema & Functions</h3>";
    
    try {
        $conn = new PDO("mysql:host=localhost;dbname=fp_mbd", "root", "");
        
        // Check if tables exist
        $stmt = $conn->query("SHOW TABLES");
        $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        if (count($tables) > 5) {
            echo "<span class='success'>✅ Tables: " . count($tables) . " tables found</span><br>";
            
            // Check functions
            try {
                $stmt = $conn->query("SELECT total_poin_mahasiswa(1) as test");
                echo "<span class='success'>✅ Functions: WORKING</span><br>";
                $success_count++;
            } catch (Exception $e) {
                echo "<span class='warning'>⚠️ Functions: MISSING - Need to import SQL</span><br>";
                echo "<span class='info'>📝 Manual action required: Import database/fp_mbdFIX.sql</span><br>";
            }
        } else {
            echo "<span class='warning'>⚠️ Tables: MISSING (" . count($tables) . " found)</span><br>";
            echo "<span class='info'>📝 Manual action required: Import database/fp_mbdFIX.sql</span><br>";
        }
    } catch (Exception $e) {
        echo "<span class='error'>❌ Schema Error: " . $e->getMessage() . "</span><br>";
    }
    
    // ===============================
    // CHECK 4: File Structure
    // ===============================
    echo "<h3>📋 CHECK 4: File Structure</h3>";
    
    $required_files = [
        'src/config/database.php',
        'src/controllers/MainController.php',
        'src/models/DatabaseModel.php',
        'src/views/dashboard.php',
        'public/index.php'
    ];
    
    $missing_files = [];
    foreach ($required_files as $file) {
        if (file_exists($file)) {
            echo "<span class='success'>✅ {$file}</span><br>";
        } else {
            echo "<span class='error'>❌ {$file} - MISSING!</span><br>";
            $missing_files[] = $file;
        }
    }
    
    if (empty($missing_files)) {
        echo "<span class='success'>✅ All required files: PRESENT</span><br>";
        $success_count++;
    } else {
        echo "<span class='error'>❌ Missing files: " . count($missing_files) . "</span><br>";
    }
    
    // ===============================
    // CHECK 5: Database Config
    // ===============================
    echo "<h3>📋 CHECK 5: Database Configuration</h3>";
    
    if (file_exists('src/config/database.php')) {
        $config_content = file_get_contents('src/config/database.php');
        if (strpos($config_content, 'fp_mbd') !== false) {
            echo "<span class='success'>✅ Database config: CORRECT</span><br>";
            $success_count++;
        } else {
            echo "<span class='warning'>⚠️ Database config: NEEDS FIX</span><br>";
            // Auto-fix config
            $fixed_config = '<?php
class Database {
    private $host = "localhost";
    private $db_name = "fp_mbd";
    private $username = "root";
    private $password = "";
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8", 
                                $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            die("Connection error: " . $exception->getMessage());
        }
        return $this->conn;
    }
}
?>';
            file_put_contents('src/config/database.php', $fixed_config);
            echo "<span class='success'>✅ Database config: FIXED!</span><br>";
            $success_count++;
        }
    } else {
        echo "<span class='error'>❌ Database config: FILE MISSING</span><br>";
    }
    
    // ===============================
    // CHECK 6: Public Index
    // ===============================
    echo "<h3>📋 CHECK 6: Public Index File</h3>";
    
    if (file_exists('public/index.php')) {
        $index_content = file_get_contents('public/index.php');
        if (strpos($index_content, 'MainController') !== false) {
            echo "<span class='success'>✅ Public index: CORRECT</span><br>";
            $success_count++;
        } else {
            echo "<span class='warning'>⚠️ Public index: NEEDS FIX</span><br>";
        }
    } else {
        echo "<span class='error'>❌ Public index: MISSING</span><br>";
    }
    
    // ===============================
    // CHECK 7: Test Connection
    // ===============================
    echo "<h3>📋 CHECK 7: Application Connection Test</h3>";
    
    try {
        if (file_exists('src/config/database.php')) {
            require_once 'src/config/database.php';
            $database = new Database();
            $conn = $database->getConnection();
            
            if ($conn) {
                echo "<span class='success'>✅ Application DB connection: SUCCESS</span><br>";
                $success_count++;
            } else {
                echo "<span class='error'>❌ Application DB connection: FAILED</span><br>";
            }
        } else {
            echo "<span class='error'>❌ Cannot test - config file missing</span><br>";
        }
    } catch (Exception $e) {
        echo "<span class='error'>❌ Connection test error: " . $e->getMessage() . "</span><br>";
    }
    
    // ===============================
    // CHECK 8: Website Access Test
    // ===============================
    echo "<h3>📋 CHECK 8: Website Access Test</h3>";
    
    if (file_exists('public/index.php')) {
        echo "<span class='success'>✅ Website should be accessible at: </span>";
        echo "<a href='public/' target='_blank' style='color: #00ff00;'>http://localhost/waste-tracking-db-demo/public/</a><br>";
        $success_count++;
    } else {
        echo "<span class='error'>❌ Website: Cannot access - missing files</span><br>";
    }
    
    // ===============================
    // SUMMARY
    // ===============================
    echo "<div class='box'>";
    echo "<h2>📊 FINAL RESULT</h2>";
    echo "<p><strong>Success Rate: {$success_count}/{$total_checks} (" . round($success_count/$total_checks*100) . "%)</strong></p>";
    
    if ($success_count >= 7) {
        echo "<div class='success'>";
        echo "<h3>🎉 SUCCESS! Your application should be working now!</h3>";
        echo "<p>✅ Access your website: <a href='public/' target='_blank'>http://localhost/waste-tracking-db-demo/public/</a></p>";
        echo "</div>";
    } elseif ($success_count >= 5) {
        echo "<div class='warning'>";
        echo "<h3>⚠️ PARTIALLY WORKING - Manual fixes needed</h3>";
        echo "<p>Most components are working, but you need to:</p>";
        echo "<ul>";
        echo "<li>Import database/fp_mbdFIX.sql to phpMyAdmin</li>";
        echo "<li>Import database/schema_fixes.sql to phpMyAdmin</li>";
        echo "</ul>";
        echo "</div>";
    } else {
        echo "<div class='error'>";
        echo "<h3>❌ MAJOR ISSUES DETECTED</h3>";
        echo "<p>Critical problems found. Manual intervention required:</p>";
        echo "<ul>";
        echo "<li>Start XAMPP MySQL service</li>";
        echo "<li>Check file permissions</li>";
        echo "<li>Verify folder structure</li>";
        echo "</ul>";
        echo "</div>";
    }
    echo "</div>";
    
    // ===============================
    // MANUAL ACTIONS NEEDED
    // ===============================
    echo "<div class='box'>";
    echo "<h2>📝 MANUAL ACTIONS STILL NEEDED</h2>";
    echo "<ol>";
    echo "<li><strong>Import Database Schema:</strong></li>";
    echo "<pre>1. Open http://localhost/phpmyadmin
2. Select database 'fp_mbd'
3. Click 'Import' tab
4. Choose file: database/fp_mbdFIX.sql
5. Click 'Go'
6. Import database/schema_fixes.sql (same way)</pre>";
    
    echo "<li><strong>Test Website:</strong></li>";
    echo "<pre>Access: <a href='public/' target='_blank'>http://localhost/waste-tracking-db-demo/public/</a></pre>";
    
    echo "<li><strong>Test Functions:</strong></li>";
    echo "<pre>In phpMyAdmin, run: SELECT total_poin_mahasiswa(1);</pre>";
    echo "</ol>";
    echo "</div>";
    
    echo "</div>";
} else {
    // Show initial page
    echo "<div class='box'>";
    echo "<h2>🎯 READY TO AUTO-FIX?</h2>";
    echo "<p>Script ini akan:</p>";
    echo "<ul>";
    echo "<li>✅ Check XAMPP services</li>";
    echo "<li>✅ Create database if missing</li>";
    echo "<li>✅ Verify file structure</li>";
    echo "<li>✅ Fix configuration files</li>";
    echo "<li>✅ Test database connections</li>";
    echo "<li>✅ Provide exact next steps</li>";
    echo "</ul>";
    echo "<button onclick=\"window.location.href='?action=fix'\">🚀 START AUTO FIX</button>";
    echo "</div>";
    
    echo "<div class='box'>";
    echo "<h3>📋 Pre-Requirements</h3>";
    echo "<p>Pastikan sebelum run script:</p>";
    echo "<ul>";
    echo "<li>XAMPP installed</li>";
    echo "<li>Folder project di: C:\\xampp\\htdocs\\waste-tracking-db-demo\\</li>";
    echo "<li>Files database/fp_mbdFIX.sql ada</li>";
    echo "</ul>";
    echo "</div>";
}
?>

<div class="box">
    <h3>🆘 NEED HELP?</h3>
    <p>Jika masih ada masalah setelah auto-fix:</p>
    <ol>
        <li>Screenshot hasil auto-fix ini</li>
        <li>Copy error message yang muncul</li>
        <li>Test akses: <a href="public/" target="_blank">http://localhost/waste-tracking-db-demo/public/</a></li>
    </ol>
</div>

</body>
</html>