-- Fix untuk schema yang ada di fp_mbdFIX.sql
-- Jalankan ini SETELAH import fp_mbdFIX.sql

-- 1. Fix tabel BYN (seharusnya BYN bukan byn_location)
-- Pertama, drop table yang salah jika ada
DROP TABLE IF EXISTS BIN_TYPE;

-- Pastikan tabel BYN ada dan benar
CREATE TABLE IF NOT EXISTS `byn` (
  `byn_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `point_amount` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`byn_id`),
  KEY `user_id` (`user_id`),
  KEY `campaign_id` (`campaign_id`),
  CONSTRAINT `byn_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `student` (`stud_id`),
  CONSTRAINT `byn_ibfk_2` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Pastikan tabel STUDENT punya kolom total_points
ALTER TABLE `student` 
ADD COLUMN IF NOT EXISTS `total_points` int(11) DEFAULT 0 AFTER `status`;

-- 3. Fix tabel RECYCLINGACTIVITY - tambah kolom yang mungkin missing
ALTER TABLE `recyclingactivity` 
ADD COLUMN IF NOT EXISTS `recyclebin_id` int(11) DEFAULT NULL AFTER `user_id`,
ADD COLUMN IF NOT EXISTS `timestamp` timestamp NOT NULL DEFAULT current_timestamp() AFTER `status`;

-- 4. Update total_points untuk semua student berdasarkan BYN mereka
UPDATE student s 
SET total_points = (
    SELECT IFNULL(SUM(point_amount), 0) 
    FROM byn 
    WHERE user_id = s.stud_id
);

-- 5. Tambah index untuk performance
ALTER TABLE `recyclingactivity` ADD INDEX IF NOT EXISTS `idx_user_status` (`user_id`, `status`);
ALTER TABLE `byn` ADD INDEX IF NOT EXISTS `idx_user_timestamp` (`user_id`, `timestamp`);
ALTER TABLE `student` ADD INDEX IF NOT EXISTS `idx_status` (`status`);

-- 6. Insert beberapa data test tambahan untuk demo
INSERT IGNORE INTO `byn_location` (`location_id`, `faculty_id`, `dept_id`, `room`, `building`, `status`) VALUES
(101, 1, 1, 'Demo Room', 'Demo Building', 'active');

INSERT IGNORE INTO `recyclebin` (`bin_id`, `location_id`, `bin_type`, `capacity_kg`, `status`) VALUES
(101, 101, 'Demo Bin', 50.00, 'active');