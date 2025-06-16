<?php

namespace App;

require_once __DIR__ . '/../config/database.php'; // Adjust path to your Database.php

use PDO;
use PDOException;
use Database;

class Functions
{
    private $db;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    public function getAllFunctions()
    {
        return [
            'cek_partisipasi_kampanye'         => 'Cek Partisipasi Pengguna dalam Kampanye (user_id CHAR(12), sustainability_campaign_id CHAR(12))',
            'dapatkan_status_user'            => 'Dapatkan Status Pengguna (user_id CHAR(12))',
            'hitung_diskon_reward'            => 'Hitung Diskon Reward (reward_status CHAR(12), user_total_points INT)', // Assuming parameters based on common logic
            'hitung_jumlah_kampanye_diikuti'  => 'Hitung Jumlah Kampanye Diikuti Pengguna (user_id CHAR(12))',
            'hitung_jumlah_reward_ditukar'    => 'Hitung Jumlah Reward Ditukar Pengguna (user_id CHAR(12))',
            'hitung_kampanye_dibuat_staff'    => 'Hitung Kampanye Dibuat Staff (staff_id CHAR(12))',
            'hitung_kampanye_per_koordinator' => 'Hitung Jumlah Kampanye Per Koordinator (sustainability_coordinator_id CHAR(12))',
            'hitung_kapasitas_total_lokasi'   => 'Hitung Kapasitas Total Tempat Sampah Lokasi (bin_location_id CHAR(12))',
            'hitung_total_poin_user'          => 'Hitung Total Poin Pengguna (user_id CHAR(12))',
            'hitung_total_sampah_disetor'     => 'Hitung Total Sampah Disetor Pengguna (user_id CHAR(12))',
            'hitung_user_aktif_per_fakultas'  => 'Hitung Pengguna Aktif Per Fakultas (faculty_id CHAR(12))',
            'konversi_berat_ke_poin'          => 'Konversi Berat ke Poin (weight_kg DECIMAL(5,2))'
        ];
    }

    public function testFunction($functionName, $params)
    {
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
