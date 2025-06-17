<?php

namespace App;

require_once __DIR__ . '/../config/database.php';

use PDO;
use PDOException;
use Database;

class StoredProcedures
{
    private $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function getAllProcedures()
    {
        return [
            'sp_redeem_reward'                        => 'Redeem Reward (p_user_id CHAR(12), p_reward_item_id CHAR(12))',
            'sp_laporkan_aktivitas_sampah'            => 'Laporkan Aktivitas Sampah (p_user_id CHAR(12), p_recycling_bin_id CHAR(12), p_waste_type_id CHAR(12), p_weight_kg DECIMAL(5,2), p_admin_id CHAR(12)',
            'sp_generate_user_summary'                => 'Generate Ringkasan Pengguna (p_user_id CHAR(12))',
            'sp_update_user_status'                   => 'Update Status Pengguna (p_user_id CHAR(12))',
            'sp_add_recycling_bin'                    => 'Tambah Tempat Daur Ulang & Cek Kapasitas (p_bin_location_id CHAR(12), p_capacity_kg DECIMAL(5,2), p_qr_code VARCHAR(100))',
            'sp_complete_redemption'                  => 'Selesaikan Penukaran Reward (p_redemption_id CHAR(12))',
            'sp_create_campaign_with_coordinator_check' => 'Buat Kampanye dengan Pengecekan Koordinator (p_sustainability_coordinator_id CHAR(12), p_title VARCHAR(50), p_description VARCHAR(255), p_start_date DATETIME, p_end_date DATETIME, p_target_waste_reduction DECIMAL(6,2), p_bonus_points INT, p_status CHAR(9))',
            'sp_ikut_kampanye'                        => 'Daftar Kampanye (p_user_id CHAR(12), p_sustainability_campaign_id CHAR(12))',
            'sp_verifikasi_aktivitas'                 => 'Verifikasi Aktivitas (p_recycling_activity_id CHAR(12))',
            'sp_tambah_stok_reward'                   => 'Tambah Stok Reward (p_reward_id_item CHAR(12), p_tambahan_stok INT)'
        ];
    }

    public function testProcedure($procedureName, $params)
    {
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
        } catch (PDOException $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'query' => $sql ?? 'N/A',
                'params' => $params
            ];
        }
    }
}
