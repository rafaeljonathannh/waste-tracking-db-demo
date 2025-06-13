<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
date_default_timezone_set('Asia/Jakarta');
session_start();

require_once __DIR__ . '/../src/controllers/MainController.php';

try {
    $controller = new MainController();
    $controller->handleRequest();
} catch (Exception $e) {
    http_response_code(500);
    
    if (isset($_GET['action'])) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'error' => 'Server Error: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    } else {
        ?>
        <!DOCTYPE html>
        <html>
        <head>
            <title>Error - Waste Tracking DB Demo</title>
            <style>body{font-family:monospace;background:#222;color:#ff0000;padding:20px;}</style>
        </head>
        <body>
            <h1>Application Error</h1>
            <p><strong>Error:</strong> <?= htmlspecialchars($e->getMessage()) ?></p>
            <p><strong>File:</strong> <?= htmlspecialchars($e->getFile()) ?></p>
            <p><strong>Line:</strong> <?= $e->getLine() ?></p>
            <p><a href="." style="color:#00ff00;">← Back to Homepage</a></p>
        </body>
        </html>
        <?php
    }
}
?>