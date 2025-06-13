<?php
require_once __DIR__ . '/../config/database.php';

class DatabaseModel {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function getAllFunctions() {
        return [
            'total_poin_mahasiswa' => 'Total Poin Mahasiswa (stud_id)',
            'jumlah_kampanye_mahasiswa' => 'Jumlah Kampanye Mahasiswa (stud_id)', 
            'total_sampah_disetor' => 'Total Sampah Disetor (stud_id)',
            'jumlah_mahasiswa_aktif_fakultas' => 'Jumlah Mahasiswa Aktif Fakultas (faculty_id)',
            'jumlah_reward_ditukar' => 'Jumlah Reward Ditukar (stud_id)',
            'status_mahasiswa' => 'Status Mahasiswa (stud_id)',
            'jumlah_koordinator_fakultas' => 'Jumlah Koordinator Fakultas (faculty_id)',
            'kampanye_dibuat_staff' => 'Kampanye Dibuat Staff (staff_id)',
            'kapasitas_total_tempat_sampah' => 'Kapasitas Total Tempat Sampah (location_id)',
            'ikut_kampanye' => 'Cek Ikut Kampanye (stud_id, campaign_id)',
            'fn_konversi_berat_ke_poin' => 'Konversi Berat ke Poin (weight_kg)',
            'fn_hitung_diskon_reward' => 'Hitung Diskon Reward (status, points)'
        ];
    }

    public function testFunction($functionName, $params) {
        try {
            $placeholders = str_repeat('?,', count($params));
            $placeholders = rtrim($placeholders, ',');
            
            $sql = "SELECT {$functionName}({$placeholders}) as result";
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'result' => $result['result'],
                'query' => $sql,
                'params' => $params
            ];
        } catch(PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'query' => $sql ?? 'N/A',
                'params' => $params
            ];
        }
    }

    public function getAllProcedures() {
        return [
            'sp_redeem_reward' => 'Redeem Reward (user_id, reward_id)',
            'sp_laporkan_aktivitas_sampah' => 'Laporkan Aktivitas Sampah (user_id, bin_id, weight, status)',
            'sp_generate_student_summary' => 'Generate Student Summary (user_id)',
            'sp_update_student_status' => 'Update Student Status (user_id)',
            'sp_add_bin_check_capacity' => 'Add Bin Check Capacity (location_id, capacity_kg, bin_code)',
            'sp_complete_redemption' => 'Complete Redemption (redemption_id)',
            'sp_create_campaign_with_coordinator_check' => 'Create Campaign with Coordinator Check (staff_id, faculty_id, name, description, start_date, end_date)'
        ];
    }

    public function testProcedure($procedureName, $params) {
        try {
            $placeholders = str_repeat('?,', count($params));
            $placeholders = rtrim($placeholders, ',');
            
            $sql = "CALL {$procedureName}({$placeholders})";
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            
            $results = [];
            do {
                $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
                if (!empty($result)) {
                    $results[] = $result;
                }
            } while ($stmt->nextRowset());
            
            return [
                'success' => true,
                'results' => $results,
                'query' => $sql,
                'params' => $params
            ];
        } catch(PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'query' => $sql ?? 'N/A',
                'params' => $params
            ];
        }
    }

    public function getTableData($tableName, $limit = 50) {
        try {
            $allowedTables = [
                'student', 'staff', 'faculty', 'faculty_department', 
                'byn', 'recyclingactivity', 'rewardredemption', 'reward_item',
                'sustainability_campaign', 'recyclebin', 'byn_location'
            ];
            
            if (!in_array($tableName, $allowedTables)) {
                throw new Exception("Table not allowed");
            }
            
            $sql = "SELECT * FROM {$tableName} LIMIT ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$limit]);
            
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
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function getTableList() {
        try {
            $stmt = $this->db->query("SHOW TABLES");
            $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
            return $tables;
        } catch (Exception $e) {
            return [];
        }
    }

    public function getDashboardStats() {
        try {
            $stats = [];
            
            $stmt = $this->db->query("SELECT COUNT(*) as count FROM student");
            $stats['total_students'] = $stmt->fetch()['count'];
            
            $stmt = $this->db->query("SHOW FUNCTION STATUS WHERE Db = 'fp_mbd'");
            $stats['total_functions'] = $stmt->rowCount();
            
            $stmt = $this->db->query("SHOW PROCEDURE STATUS WHERE Db = 'fp_mbd'");
            $stats['total_procedures'] = $stmt->rowCount();
            
            $stmt = $this->db->query("SHOW TABLES");
            $stats['total_tables'] = $stmt->rowCount();
            
            return $stats;
        } catch (Exception $e) {
            return [
                'total_students' => 0,
                'total_functions' => 0,
                'total_procedures' => 0,
                'total_tables' => 0
            ];
        }
    }

    public function getRecentActivities($limit = 10) {
        try {
            $sql = "SELECT ra.*, s.name as student_name, sc.name as campaign_name 
                    FROM recyclingactivity ra
                    LEFT JOIN student s ON ra.user_id = s.stud_id
                    LEFT JOIN sustainability_campaign sc ON ra.campaign_id = sc.campaign_id
                    ORDER BY ra.timestamp DESC LIMIT ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$limit]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            return [];
        }
    }

    public function getPointsHistory($limit = 10) {
        try {
            $sql = "SELECT b.*, s.name as student_name, sc.name as campaign_name 
                    FROM byn b
                    LEFT JOIN student s ON b.user_id = s.stud_id
                    LEFT JOIN sustainability_campaign sc ON b.campaign_id = sc.campaign_id
                    ORDER BY b.timestamp DESC LIMIT ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$limit]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            return [];
        }
    }
}
?>