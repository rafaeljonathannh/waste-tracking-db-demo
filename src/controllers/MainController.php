<?php
require_once __DIR__ . '/../models/DatabaseModel.php';

class MainController {
    private $model;
    
    public function __construct() {
        $this->model = new DatabaseModel();
    }

    public function handleRequest() {
        $action = $_GET['action'] ?? 'dashboard';
        
        switch ($action) {
            case 'dashboard':
                $this->dashboard();
                break;
            case 'test_function':
                $this->testFunction();
                break;
            case 'test_procedure':
                $this->testProcedure();
                break;
            case 'view_table':
                $this->viewTable();
                break;
            case 'get_stats':
                $this->getStats();
                break;
            case 'get_recent_activities':
                $this->getRecentActivities();
                break;
            case 'get_points_history':
                $this->getPointsHistory();
                break;
            default:
                $this->dashboard();
        }
    }

    private function dashboard() {
        $stats = $this->model->getDashboardStats();
        $functions = $this->model->getAllFunctions();
        $procedures = $this->model->getAllProcedures();
        $tables = $this->model->getTableList();
        
        include __DIR__ . '/../views/dashboard.php';
    }

    private function testFunction() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['success' => false, 'error' => 'Method not allowed']);
            return;
        }
        
        $functionName = $_POST['function_name'] ?? '';
        $params = [];
        
        for ($i = 1; $i <= 5; $i++) {
            $paramValue = $_POST["param{$i}"] ?? '';
            if ($paramValue !== '') {
                $params[] = $paramValue;
            }
        }
        
        $result = $this->model->testFunction($functionName, $params);
        echo json_encode($result);
    }

    private function testProcedure() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['success' => false, 'error' => 'Method not allowed']);
            return;
        }
        
        $procedureName = $_POST['procedure_name'] ?? '';
        $params = [];
        
        for ($i = 1; $i <= 5; $i++) {
            $paramValue = $_POST["param{$i}"] ?? '';
            if ($paramValue !== '') {
                $params[] = $paramValue;
            }
        }
        
        $result = $this->model->testProcedure($procedureName, $params);
        echo json_encode($result);
    }

    private function viewTable() {
        header('Content-Type: application/json');
        
        $tableName = $_GET['table'] ?? '';
        $limit = $_GET['limit'] ?? 50;
        
        $result = $this->model->getTableData($tableName, $limit);
        echo json_encode($result);
    }

    private function getStats() {
        header('Content-Type: application/json');
        
        $stats = $this->model->getDashboardStats();
        echo json_encode(['success' => true, 'data' => $stats]);
    }

    private function getRecentActivities() {
        header('Content-Type: application/json');
        
        $activities = $this->model->getRecentActivities();
        echo json_encode(['success' => true, 'data' => $activities]);
    }

    private function getPointsHistory() {
        header('Content-Type: application/json');
        
        $history = $this->model->getPointsHistory();
        echo json_encode(['success' => true, 'data' => $history]);
    }
}
?>