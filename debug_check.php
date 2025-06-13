<?php
// debug_check.php - Untuk debugging file structure
// Simpan di: C:\xampp\htdocs\waste-tracking-db-demo\

echo "<h2>🔍 File Structure Debug</h2>";

echo "<h3>📁 Checking Required Files:</h3>";

$files_to_check = [
    'src/config/database.php',
    'src/controllers/MainController.php', 
    'src/models/DatabaseModel.php', // INI YANG PENTING!
    'src/views/dashboard.php',
    'src/views/layouts/header.php',
    'src/views/layouts/footer.php',
    'public/index.php',
    'public/.htaccess'
];

foreach ($files_to_check as $file) {
    if (file_exists($file)) {
        echo "<div style='color: green;'>✅ {$file} - EXISTS</div>";
    } else {
        echo "<div style='color: red;'>❌ {$file} - MISSING</div>";
    }
}

echo "<hr>";
echo "<h3>📂 Contents of src/models/:</h3>";
$models_dir = 'src/models/';
if (is_dir($models_dir)) {
    $files = scandir($models_dir);
    foreach ($files as $file) {
        if ($file != '.' && $file != '..') {
            echo "<div>📄 {$file}</div>";
        }
    }
} else {
    echo "<div style='color: red;'>❌ Models directory not found</div>";
}

echo "<hr>";
echo "<h3>📂 Contents of src/controllers/:</h3>";
$controllers_dir = 'src/controllers/';
if (is_dir($controllers_dir)) {
    $files = scandir($controllers_dir);
    foreach ($files as $file) {
        if ($file != '.' && $file != '..') {
            echo "<div>📄 {$file}</div>";
        }
    }
} else {
    echo "<div style='color: red;'>❌ Controllers directory not found</div>";
}

echo "<hr>";
echo "<h3>🧪 Test Include Path:</h3>";
echo "<p><strong>Current working directory:</strong> " . getcwd() . "</p>";
echo "<p><strong>File path from public/index.php:</strong></p>";

// Simulate path from public folder
$test_path = '../src/models/DatabaseModel.php';
$full_path = realpath('public/' . $test_path);
echo "<p>Resolved path: " . ($full_path ? $full_path : 'PATH NOT RESOLVED') . "</p>";

if (file_exists('public/' . $test_path)) {
    echo "<div style='color: green;'>✅ Path from public/index.php is CORRECT</div>";
} else {
    echo "<div style='color: red;'>❌ Path from public/index.php is WRONG</div>";
}
?>