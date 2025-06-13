<?php
// Error reporting for development
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set timezone
date_default_timezone_set('Asia/Jakarta');

// Start session
session_start();

// Include the main controller
require_once '../src/controllers/MainController.php';

try {
    // Create controller instance and handle request
    $controller = new MainController();
    $controller->handleRequest();
} catch (Exception $e) {
    // Error handling
    http_response_code(500);
    
    if (isset($_GET['action']) && in_array($_GET['action'], ['test_function', 'test_procedure', 'view_table', 'get_stats', 'get_recent_activities', 'get_points_history'])) {
        // Return JSON error for AJAX requests
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'error' => 'Server Error: ' . $e->getMessage()
        ]);
    } else {
        // Show error page for regular requests
        ?>
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Error - Waste Tracking DB Demo</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        </head>
        <body>
            <div class="container mt-5">
                <div class="row justify-content-center">
                    <div class="col-md-6">
                        <div class="card border-danger">
                            <div class="card-header bg-danger text-white">
                                <h5 class="mb-0"><i class="fas fa-exclamation-triangle me-2"></i>Application Error</h5>
                            </div>
                            <div class="card-body">
                                <p><strong>Error:</strong> <?= htmlspecialchars($e->getMessage()) ?></p>
                                <p><strong>File:</strong> <?= htmlspecialchars($e->getFile()) ?></p>
                                <p><strong>Line:</strong> <?= $e->getLine() ?></p>
                                <hr>
                                <h6>Debugging Information:</h6>
                                <ul>
                                    <li><strong>Request URI:</strong> <?= htmlspecialchars($_SERVER['REQUEST_URI']) ?></li>
                                    <li><strong>User IP:</strong> <?= htmlspecialchars($_SERVER['REMOTE_ADDR']) ?></li>
                                    <li><strong>User Agent:</strong> <?= htmlspecialchars($_SERVER['HTTP_USER_AGENT']) ?></li>
                                </ul>
                                <h6>Troubleshooting:</h6>
                                <ul>
                                    <li>Make sure XAMPP MySQL is running</li>
                                    <li>Check if database 'fp_mbd' exists</li>
                                    <li>Verify database connection settings</li>
                                    <li>Check if all required files are present</li>
                                </ul>
                                
                                <a href="/" class="btn btn-primary">
                                    <i class="fas fa-home me-2"></i>Back to Home
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </body>
        </html>
        <?php
    }
}
?>