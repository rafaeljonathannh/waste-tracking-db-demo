<?php
require_once '../src/config/database.php';

class DatabaseModel {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    // ========== FUNCTIONS TESTING ==========
    
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
        $database = new Database();
        $db = $database->getConnection();
        
        try {
            $placeholders = str_repeat('?,', count($params));
            $placeholders = rtrim($placeholders, ',');
            
            $sql = "SELECT {$functionName}({$placeholders}) as result";
            $stmt = $db->prepare($sql);
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
                'query' => $sql,
                'params' => $params
            ];
        }
    }

    // ========== STORED PROCEDURES TESTING ==========
    
    public function getAllProcedures() {
        return [
            'sp_redeem_reward' => 'Redeem Reward (user_id, reward_id)',
            'sp_laporkan_aktivitas_sampah' => 'Laporkan Aktivitas Sampah (user_id, bin_id, weight, status)',
            'sp_ikut_kampanye' => 'Ikut Kampanye (user_id, campaign_id)',
            'sp_update_student_status' => 'Update Student Status (user_id)',
            'sp_generate_student_summary' => 'Generate Student Summary (user_id)',
            'sp_add_bin_check_capacity' => 'Add Bin Check Capacity (location_id, capacity_kg, bin_code)',
            'sp_complete_redemption' => 'Complete Redemption (redemption_id)'
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
                'query' => $sql,
                'params' => $params
            ];
        }
    }

    // ========== DATA VIEWER ==========
    
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
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC),
                'count' => $stmt->rowCount()
            ];
        } catch(Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function getTableList() {
        return [
            'student' => 'Students',
            'staff' => 'Staff',
            'faculty' => 'Faculties', 
            'faculty_department' => 'Departments',
            'byn' => 'Points (BYN)',
            'recyclingactivity' => 'Recycling Activities',
            'rewardredemption' => 'Reward Redemptions',
            'reward_item' => 'Reward Items',
            'sustainability_campaign' => 'Campaigns',
            'recyclebin' => 'Recycle Bins',
            'byn_location' => 'Locations'
        ];
    }

    // ========== TRIGGER MONITORING ==========
    
    public function getRecentActivities($limit = 20) {
        try {
            $sql = "
                SELECT 
                    'recycling_activity' as type,
                    activity_id as id,
                    user_id,
                    weight_kg as value,
                    status,
                    date as timestamp
                FROM recyclingactivity 
                ORDER BY activity_id DESC 
                LIMIT ?
            ";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$limit]);
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
        } catch(PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    public function getPointsHistory($limit = 20) {
        try {
            $sql = "
                SELECT 
                    b.byn_id,
                    b.user_id,
                    s.name as student_name,
                    b.point_amount,
                    b.timestamp,
                    b.campaign_id
                FROM byn b
                LEFT JOIN student s ON b.user_id = s.stud_id
                ORDER BY b.timestamp DESC 
                LIMIT ?
            ";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$limit]);
            
            return [
                'success' => true,
                'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
            ];
        } catch(PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    // ========== DASHBOARD STATS ==========
    
    public function getDashboardStats() {
        try {
            $stats = [];
            
            // Total Students
            $sql = "SELECT COUNT(*) as count FROM student";
            $stmt = $this->db->query($sql);
            $stats['total_students'] = $stmt->fetch()['count'];
            
            // Active Students
            $sql = "SELECT COUNT(*) as count FROM student WHERE status = 'active'";
            $stmt = $this->db->query($sql);
            $stats['active_students'] = $stmt->fetch()['count'];
            
            // Total Points Distributed
            $sql = "SELECT IFNULL(SUM(point_amount), 0) as total FROM byn";
            $stmt = $this->db->query($sql);
            $stats['total_points'] = $stmt->fetch()['total'];
            
            // Total Activities
            $sql = "SELECT COUNT(*) as count FROM recyclingactivity";
            $stmt = $this->db->query($sql);
            $stats['total_activities'] = $stmt->fetch()['count'];
            
            // Verified Activities
            $sql = "SELECT COUNT(*) as count FROM recyclingactivity WHERE status = 'verified'";
            $stmt = $this->db->query($sql);
            $stats['verified_activities'] = $stmt->fetch()['count'];
            
            return [
                'success' => true,
                'stats' => $stats
            ];
        } catch(PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }
}
?>