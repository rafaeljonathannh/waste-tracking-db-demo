-- Cek Apakah Mahasiswa Mengikuti Kampanye Tertentu
DELIMITER $$

CREATE FUNCTION `cek_partisipasi_kampanye`(user_id_input CHAR(12), campaign_id_input CHAR(12)) RETURNS tinyint(1)
    DETERMINISTIC
BEGIN
   DECLARE jumlah INT DEFAULT 0;

   SELECT COUNT(*) INTO jumlah
   FROM USER_SUSTAINABILITY_CAMPAIGN
   WHERE user_id = user_id_input AND sustainability_campaign_id = campaign_id_input;

   RETURN jumlah > 0;
END$$

DELIMITER ;

-- Cek Status Mahasiswa
DELIMITER $$

CREATE FUNCTION `dapatkan_status_user`(user_id_input CHAR(12)) RETURNS varchar(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci
    DETERMINISTIC
BEGIN
   DECLARE status_hasil VARCHAR(20);

   SELECT status INTO status_hasil
   FROM USERR
   WHERE id = user_id_input;

   RETURN status_hasil;
END$$

DELIMITER ;

-- fn_hitung_diskon_reward
DELIMITER $$

CREATE FUNCTION `hitung_diskon_reward`(status_input VARCHAR(20), poin_awal INT) RETURNS int(11)
    DETERMINISTIC
BEGIN
   IF status_input = 'active' THEN
       RETURN ROUND(poin_awal * 0.9);
   ELSE
       RETURN poin_awal;
   END IF;
END$$

DELIMITER ;

-- Jumlah Kampanye yang Diikuti Mahasiswa
DELIMITER $$

CREATE FUNCTION `hitung_jumlah_kampanye_diikuti`(user_id_input CHAR(12)) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE jumlah_kampanye INT DEFAULT 0;

   SELECT COUNT(*)
   INTO jumlah_kampanye
   FROM USER_SUSTAINABILITY_CAMPAIGN
   WHERE user_id = user_id_input AND status = 'joined';

   RETURN jumlah_kampanye;
END$$

DELIMITER ;

-- Total Penukaran Reward Mahasiswa
DELIMITER $$

CREATE FUNCTION `hitung_jumlah_reward_ditukar`(user_id_input CHAR(12)) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE jumlah_reward INT DEFAULT 0;

   SELECT COUNT(*)
   INTO jumlah_reward
   FROM REWARDREDEMPTION
   WHERE user_id = user_id_input AND status = 'processed';

   RETURN jumlah_reward;
END$$

DELIMITER ;

-- Total Kampanye yang Dibuat oleh Staff
DELIMITER $$

CREATE FUNCTION `hitung_kampanye_dibuat_staff`(staff_id_input INT) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE jumlah_kampanye INT DEFAULT 0;

   SELECT COUNT(*)
   INTO jumlah_kampanye
   FROM SUSTAINABILITY_CAMPAIGN
   WHERE created_by = staff_id_input;

   RETURN jumlah_kampanye;
END$$

DELIMITER ;

-- Total Jumlah Koordinator Keberlanjutan per Fakultas
DELIMITER $$

CREATE FUNCTION `hitung_kampanye_per_koordinator`(koordinator_id_input CHAR(12)) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE jumlah_kampanye INT DEFAULT 0;

   SELECT COUNT(*)
   INTO jumlah_kampanye
   FROM SUSTAINABILITY_CAMPAIGN
   WHERE sustainability_coordinator_id = koordinator_id_input;

   RETURN jumlah_kampanye;
END$$

DELIMITER ;

-- Kapasitas Total Tempat Sampah di Lokasi Tertentu
DELIMITER $$

CREATE FUNCTION `hitung_kapasitas_total_lokasi`(lokasi_id_input CHAR(12)) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
   DECLARE total_kapasitas DECIMAL(10,2) DEFAULT 0;

   SELECT IFNULL(SUM(capacity_kg), 0)
   INTO total_kapasitas
   FROM RECYCLING_BIN
   WHERE bin_location_id = lokasi_id_input;

   RETURN total_kapasitas;
END$$

DELIMITER ;

-- Total Poin Mahasiswa dari Semua Kampanye
DELIMITER $$

CREATE FUNCTION `hitung_total_poin_user`(user_id_input CHAR(12)) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE total_poin INT DEFAULT 0;

   SELECT IFNULL(SUM(point), 0)
   INTO total_poin
   FROM POINTS
   WHERE user_id = user_id_input;

   RETURN total_poin;
END$$

DELIMITER ;

-- Jumlah Sampah yang Disetor oleh Mahasiswa
DELIMITER $$

CREATE FUNCTION `hitung_total_sampah_disetor`(user_id_input CHAR(12)) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
   DECLARE total_berat DECIMAL(10,2) DEFAULT 0;

   SELECT IFNULL(SUM(weight_kg), 0)
   INTO total_berat
   FROM RECYCLING_ACTIVITY
   WHERE user_id = user_id_input AND verification_staff = 'verified';

   RETURN total_berat;
END$$

DELIMITER ;

-- Jumlah Mahasiswa Aktif di Fakultas
DELIMITER $$

CREATE FUNCTION `hitung_user_aktif_per_fakultas`(fakultas_id_input CHAR(12)) RETURNS int(11)
    DETERMINISTIC
BEGIN
   DECLARE jumlah_user INT DEFAULT 0;

   SELECT COUNT(*)
   INTO jumlah_user
   FROM USERR
   WHERE faculty_id = fakultas_id_input AND status = 'active';

   RETURN jumlah_user;
END$$

DELIMITER ;

-- fn_konversi_berat_ke_poin
DELIMITER $$

CREATE FUNCTION `konversi_berat_ke_poin`(berat_kg DECIMAL(5,2)) 
RETURNS int(11)
    DETERMINISTIC
BEGIN
   RETURN ROUND(berat_kg * 10);
END$$

DELIMITER ;
