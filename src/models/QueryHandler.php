<?php

namespace App;

require_once __DIR__ . '/../config/database.php';

use Exception;
use PDO;
use Database;

class QueryHandler
{
    private $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function getTableData($tableName, $limit = 50)
    {
        try {
            $allowedTables = [
                'FACULTY',
                'FACULTY_DEPARTMENT',
                'STAFF',
                'SUSTAINABILITY_COORDINATOR',
                'SUSTAINABILITY_CAMPAIGN',
                'USERR',
                'USER_SUSTAINABILITY_CAMPAIGN',
                'BIN_TYPE',
                'BIN_LOCATION',
                'RECYCLING_BIN',
                'STAFF_RECYCLING_BIN',
                'ADMIN',
                'WASTE_TYPE',
                'RECYCLING_ACTIVITY',
                'POINTS',
                'REWARD_ITEM',
                'REWARDREDEMPTION'
            ];

            $tableName = strtoupper($tableName);

            if (!in_array($tableName, $allowedTables)) {
                $errorMsg = "Table '{$tableName}' is not allowed for data retrieval.";
                error_log("QueryHandler Error: " . $errorMsg);
                throw new Exception($errorMsg);
            }

            $sql = "SELECT * FROM {$tableName} LIMIT ?";
            $stmt = $this->db->prepare($sql);

            $stmt->bindValue(1, (int)$limit, PDO::PARAM_INT);

            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $countSql = "SELECT COUNT(*) as total FROM {$tableName}";
            $countStmt = $this->db->prepare($countSql);
            $countStmt->execute();
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];

            return [
                'success' => true,
                'data' => $data,
                'count' => $total
            ];
        } catch (Exception $e) {
            $errorMsg = "Error in getTableData for table '{$tableName}': " . $e->getMessage();
            error_log("QueryHandler Error: " . $errorMsg);
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function getTableList()
    {
        try {
            $stmt = $this->db->query("SHOW TABLES");
            $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
            return $tables;
        } catch (Exception $e) {
            $errorMsg = "Error fetching table list: " . $e->getMessage();
            error_log("QueryHandler Error: " . $errorMsg);
            return [];
        }
    }

    public function getDashboardStats()
    {
        try {
            $stats = [];

            $stmt = $this->db->query("SELECT COUNT(*) as count FROM USERR");
            $stats['total_users'] = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

            $stmt = $this->db->query("SHOW FUNCTION STATUS WHERE Db = 'fp_mbd'");
            $stats['total_functions'] = $stmt->rowCount();

            $stmt = $this->db->query("SHOW PROCEDURE STATUS WHERE Db = 'fp_mbd'");
            $stats['total_procedures'] = $stmt->rowCount();

            $stmt = $this->db->query("SHOW TABLES");
            $stats['total_tables'] = $stmt->rowCount();

            return $stats;
        } catch (Exception $e) {
            $errorMsg = "Error fetching dashboard stats: " . $e->getMessage();
            error_log("QueryHandler Error: " . $errorMsg);
            return [
                'total_users' => 0,
                'total_functions' => 0,
                'total_procedures' => 0,
                'total_tables' => 0
            ];
        }
    }

    /**
     * Retrieves recent recycling activities.
     *
     * @param int $limit The maximum number of activities to return.
     * @return array An array of recent activities, or an empty array on error.
     */
    public function getRecentActivities($limit = 10)
    {
        try {
            $sql = "SELECT ra.*, u.fullname as user_fullname, wt.waste_type_name
                    FROM RECYCLING_ACTIVITY ra
                    LEFT JOIN USERR u ON ra.user_id = u.id
                    LEFT JOIN WASTE_TYPE wt ON ra.waste_type_id = wt.id
                    ORDER BY ra.timestamp DESC LIMIT ?";

            $stmt = $this->db->prepare($sql);
            // Fix: Bind as integer for LIMIT
            $stmt->bindValue(1, (int)$limit, PDO::PARAM_INT);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            $errorMsg = "Error fetching recent activities: " . $e->getMessage();
            error_log("QueryHandler Error: " . $errorMsg);
            return [];
        }
    }

    /**
     * Retrieves points history.
     *
     * @param int $limit The maximum number of points entries to return.
     * @return array An array of points history entries, or an empty array on error.
     */
    public function getPointsHistory($limit = 10)
    {
        try {
            $sql = "SELECT p.*, u.fullname as user_fullname, ra.weight_kg, ra.timestamp as activity_timestamp
                    FROM POINTS p
                    LEFT JOIN USERR u ON p.user_id = u.id
                    LEFT JOIN RECYCLING_ACTIVITY ra ON p.recycling_activity_id = ra.id
                    ORDER BY p.when_earn DESC LIMIT ?";

            $stmt = $this->db->prepare($sql);
            // Fix: Bind as integer for LIMIT
            $stmt->bindValue(1, (int)$limit, PDO::PARAM_INT);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            $errorMsg = "Error fetching points history: " . $e->getMessage();
            error_log("QueryHandler Error: " . $errorMsg);
            return [];
        }
    }
}
