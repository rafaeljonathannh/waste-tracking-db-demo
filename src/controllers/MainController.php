<?php

namespace App;

require_once __DIR__ . '/../models/Functions.php';
require_once __DIR__ . '/../models/StoredProcedures.php';
require_once __DIR__ . '/../models/QueryHandler.php';

use App\Functions;
use App\StoredProcedures;
use App\QueryHandler;

class MainController
{
    private $functions;
    private $procedures;
    private $queryHandler;

    public function __construct()
    {
        $this->functions = new Functions();
        $this->procedures = new StoredProcedures();
        $this->queryHandler = new QueryHandler();
    }

    public function handleRequest()
    {
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

    private function dashboard()
    {
        $stats = $this->queryHandler->getDashboardStats();
        $functions = $this->functions->getAllFunctions();
        $procedures = $this->procedures->getAllProcedures();
        $tables = $this->queryHandler->getTableList();

        include __DIR__ . '/../views/dashboard.php';
    }

    private function testFunction()
    {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST.']);
            return;
        }

        $functionName = $_POST['function_name'] ?? '';
        $params = [];

        for ($i = 1; $i <= 8; $i++) {
            $paramValue = $_POST["param{$i}"] ?? '';
            if ($paramValue !== '') {
                $params[] = $paramValue;
            }
        }

        $result = $this->functions->testFunction($functionName, $params);
        echo json_encode($result);
    }

    private function testProcedure()
    {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST.']);
            return;
        }

        $procedureName = $_POST['procedure_name'] ?? '';
        $params = [];

        for ($i = 1; $i <= 8; $i++) {
            $paramValue = $_POST["param{$i}"] ?? '';
            if ($paramValue !== '') {
                $params[] = $paramValue;
            }
        }

        $result = $this->procedures->testProcedure($procedureName, $params);
        echo json_encode($result);
    }

    private function viewTable()
    {
        header('Content-Type: application/json');

        $tableName = $_GET['table'] ?? '';
        $limit = $_GET['limit'] ?? 50;

        $result = $this->queryHandler->getTableData($tableName, $limit);
        echo json_encode($result);
    }

    private function getStats()
    {
        header('Content-Type: application/json');

        $stats = $this->queryHandler->getDashboardStats();
        echo json_encode(['success' => true, 'data' => $stats]);
    }

    private function getRecentActivities()
    {
        header('Content-Type: application/json');

        $activities = $this->queryHandler->getRecentActivities();
        echo json_encode(['success' => true, 'data' => $activities]);
    }

    private function getPointsHistory()
    {
        header('Content-Type: application/json');

        $history = $this->queryHandler->getPointsHistory();
        echo json_encode(['success' => true, 'data' => $history]);
    }
}
