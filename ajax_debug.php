<?php
// 🔍 AJAX DEBUG SCRIPT
// Simpan sebagai: ajax_debug.php di root folder
// Akses: http://localhost/waste-tracking-db-demo/ajax_debug.php

error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
<!DOCTYPE html>
<html>
<head>
    <title>🔍 AJAX & JavaScript Debug</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #00ff00; padding: 20px; }
        .success { color: #00ff00; font-weight: bold; }
        .error { color: #ff0000; font-weight: bold; }
        .warning { color: #ffaa00; font-weight: bold; }
        .info { color: #00aaff; }
        .box { border: 1px solid #333; padding: 15px; margin: 10px 0; background: #222; }
        button { background: #00ff00; color: #000; padding: 10px 20px; border: none; cursor: pointer; font-weight: bold; margin: 5px; }
        button:hover { background: #00aa00; }
        pre { background: #000; padding: 10px; border-left: 3px solid #00ff00; overflow-x: auto; white-space: pre-wrap; }
        .result { background: #333; padding: 10px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>

<h1>🔍 AJAX & JAVASCRIPT DEBUG</h1>
<p class="info">Functions sudah ada ✅ - Sekarang debug AJAX calls!</p>

<?php
// TEST 1: Direct function test di phpMyAdmin
echo "<div class='box'>";
echo "<h2>🧪 TEST 1: Direct Function Test</h2>";

try {
    require_once 'src/config/database.php';
    $database = new Database();
    $conn = $database->getConnection();
    
    // Test direct function call
    $stmt = $conn->query("SELECT total_poin_mahasiswa(1) as result");
    $result = $stmt->fetch();
    
    echo "<span class='success'>✅ Direct SQL: total_poin_mahasiswa(1) = {$result['result']}</span><br>";
    
    // Check if student with ID=1 exists
    $stmt = $conn->query("SELECT COUNT(*) as count FROM student WHERE stud_id = 1");
    $student_check = $stmt->fetch();
    echo "<span class='info'>📊 Student ID=1 exists: " . ($student_check['count'] > 0 ? 'YES' : 'NO') . "</span><br>";
    
    // Check if there's any points data
    $stmt = $conn->query("SELECT COUNT(*) as count FROM byn WHERE user_id = 1");
    $points_check = $stmt->fetch();
    echo "<span class='info'>📊 Points data for user 1: {$points_check['count']} records</span><br>";
    
} catch (Exception $e) {
    echo "<span class='error'>❌ Direct test error: " . $e->getMessage() . "</span><br>";
}
echo "</div>";

// TEST 2: DatabaseModel class test
echo "<div class='box'>";
echo "<h2>🧪 TEST 2: DatabaseModel Class</h2>";

try {
    require_once 'src/models/DatabaseModel.php';
    $model = new DatabaseModel();
    
    echo "<span class='success'>✅ DatabaseModel loaded</span><br>";
    
    // Test the exact method used by website
    $result = $model->testFunction('total_poin_mahasiswa', [1]);
    
    echo "<span class='info'>DatabaseModel testFunction result:</span><br>";
    echo "<pre>" . print_r($result, true) . "</pre>";
    
    if (isset($result['success']) && $result['success']) {
        echo "<span class='success'>✅ DatabaseModel method: WORKING</span><br>";
    } else {
        echo "<span class='error'>❌ DatabaseModel method: FAILED</span><br>";
    }
    
} catch (Exception $e) {
    echo "<span class='error'>❌ DatabaseModel error: " . $e->getMessage() . "</span><br>";
}
echo "</div>";

// TEST 3: MainController test
echo "<div class='box'>";
echo "<h2>🧪 TEST 3: MainController AJAX Endpoint</h2>";

echo "<button onclick='testMainController()'>🧪 Test AJAX Endpoint</button>";
echo "<div id='controller-result' class='result'></div>";

echo "<script>
function testMainController() {
    const resultDiv = document.getElementById('controller-result');
    resultDiv.innerHTML = '⏳ Testing MainController AJAX endpoint...';
    
    const formData = new FormData();
    formData.append('function_name', 'total_poin_mahasiswa');
    formData.append('param1', '1');
    
    console.log('Sending AJAX request to: public/?action=test_function');
    
    fetch('public/?action=test_function', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        console.log('Response status:', response.status);
        console.log('Response headers:', response.headers);
        return response.text();
    })
    .then(data => {
        console.log('Raw response:', data);
        resultDiv.innerHTML = '<strong>Raw Response:</strong><pre>' + data + '</pre>';
        
        // Try to parse as JSON
        try {
            const jsonData = JSON.parse(data);
            resultDiv.innerHTML += '<strong>Parsed JSON:</strong><pre>' + JSON.stringify(jsonData, null, 2) + '</pre>';
            
            if (jsonData.success) {
                resultDiv.innerHTML += '<span class=\"success\">✅ AJAX SUCCESS! Result: ' + jsonData.result + '</span>';
            } else {
                resultDiv.innerHTML += '<span class=\"error\">❌ AJAX ERROR: ' + jsonData.error + '</span>';
            }
        } catch (e) {
            resultDiv.innerHTML += '<span class=\"error\">❌ Response is not valid JSON. Error: ' + e.message + '</span>';
        }
    })
    .catch(error => {
        console.error('AJAX Error:', error);
        resultDiv.innerHTML = '<span class=\"error\">❌ AJAX request failed: ' + error + '</span>';
    });
}
</script>";

echo "</div>";

// TEST 4: Test data existence
echo "<div class='box'>";
echo "<h2>🧪 TEST 4: Data Check</h2>";

try {
    // Check essential tables
    $tables_to_check = ['student', 'byn', 'sustainability_campaign'];
    
    foreach ($tables_to_check as $table) {
        $stmt = $conn->query("SELECT COUNT(*) as count FROM {$table}");
        $count = $stmt->fetch();
        echo "<span class='info'>📊 Table {$table}: {$count['count']} records</span><br>";
    }
    
    // Show sample data
    echo "<br><span class='info'>Sample student data:</span><br>";
    $stmt = $conn->query("SELECT stud_id, name FROM student LIMIT 3");
    $students = $stmt->fetchAll();
    foreach ($students as $student) {
        echo "<span class='success'>Student ID {$student['stud_id']}: {$student['name']}</span><br>";
    }
    
} catch (Exception $e) {
    echo "<span class='error'>❌ Data check error: " . $e->getMessage() . "</span><br>";
}
echo "</div>";

// TEST 5: JavaScript Console Test
echo "<div class='box'>";
echo "<h2>🧪 TEST 5: JavaScript Console Check</h2>";
echo "<p class='warning'>⚠️ IMPORTANT: Buka Browser Developer Tools (F12) → Console tab</p>";
echo "<button onclick='testConsole()'>🧪 Test Console & Errors</button>";
echo "<div id='console-result' class='result'></div>";

echo "<script>
function testConsole() {
    const resultDiv = document.getElementById('console-result');
    
    console.log('🧪 Console test - this should appear in browser console');
    console.error('🧪 Test error - this should appear as red error in console');
    
    resultDiv.innerHTML = `
        <p class='success'>✅ JavaScript working!</p>
        <p class='info'>Check browser console (F12) for:</p>
        <ul>
            <li>Blue message: 'Console test'</li>
            <li>Red error: 'Test error'</li>
            <li>Any other red errors from the website</li>
        </ul>
    `;
    
    // Test if jQuery is loaded (website might use jQuery)
    if (typeof $ !== 'undefined') {
        resultDiv.innerHTML += '<p class=\"success\">✅ jQuery: Available</p>';
    } else {
        resultDiv.innerHTML += '<p class=\"warning\">⚠️ jQuery: Not loaded</p>';
    }
    
    // Test fetch API
    if (typeof fetch !== 'undefined') {
        resultDiv.innerHTML += '<p class=\"success\">✅ Fetch API: Available</p>';
    } else {
        resultDiv.innerHTML += '<p class=\"error\">❌ Fetch API: Not available</p>';
    }
}

// Auto-check for console errors when page loads
window.addEventListener('error', function(e) {
    console.error('🚨 JavaScript Error detected:', e.error);
});
</script>";

echo "</div>";
?>

<div class="box">
    <h2>🎯 DEBUGGING CHECKLIST</h2>
    <p><strong>Jalankan semua tests di atas, lalu kasih tau:</strong></p>
    <ol>
        <li><strong>TEST 1:</strong> Berapa hasil total_poin_mahasiswa(1)?</li>
        <li><strong>TEST 2:</strong> Apakah DatabaseModel success atau ada error?</li>
        <li><strong>TEST 3:</strong> Apa hasil AJAX endpoint test?</li>
        <li><strong>TEST 4:</strong> Berapa records di table student dan byn?</li>
        <li><strong>TEST 5:</strong> Ada error merah di browser console (F12)?</li>
    </ol>
</div>

<div class="box">
    <h2>📝 MOST LIKELY FIXES</h2>
    <p><strong>Berdasarkan hasil test, kemungkinan solusi:</strong></p>
    <ul>
        <li><strong>Jika TEST 1 = 0:</strong> Perlu insert test data ke table byn</li>
        <li><strong>Jika TEST 2 gagal:</strong> Problem di DatabaseModel class</li>
        <li><strong>Jika TEST 3 gagal:</strong> Problem di MainController routing</li>
        <li><strong>Jika ada JS error:</strong> Problem di dashboard.php JavaScript</li>
    </ul>
</div>

</body>
</html>