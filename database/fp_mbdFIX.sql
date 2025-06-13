-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 10, 2025 at 09:34 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `fp_mbd`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_bin_check_capacity` (IN `p_location_id` INT, IN `p_capacity_kg` DECIMAL(6,2), IN `p_bin_code` VARCHAR(50))   BEGIN
    DECLARE v_total_capacity DECIMAL(10,2);


    SET v_total_capacity = kapasitas_total_tempat_sampah(p_location_id);


    IF (v_total_capacity + p_capacity_kg) > 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total capacity in this location would exceed 1000 kg.';
    END IF;


    INSERT INTO RECYCLEBIN(location_id, capacity_kg, bin_code)
    VALUES (p_location_id, p_capacity_kg, p_bin_code);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_complete_redemption` (IN `p_redemption_id` INT)   BEGIN
    DECLARE v_item_id INT;


    SELECT reward_item_id INTO v_item_id
    FROM REWARDREDEMPTION
    WHERE id = p_redemption_id AND status = 'pending';


    IF v_item_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Redemption ID invalid or already processed.';
    END IF;


    -- Mark as completed
    UPDATE REWARDREDEMPTION
    SET status = 'completed',
        processed_date = NOW()
    WHERE id = p_redemption_id;


    -- Decrease stock
    UPDATE REWARD_ITEM
    SET stock = stock - 1
    WHERE id = v_item_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_campaign_with_coordinator_check` (IN `p_staff_id` INT, IN `p_faculty_id` INT, IN `p_name` VARCHAR(255), IN `p_description` TEXT, IN `p_start_date` DATE, IN `p_end_date` DATE)   BEGIN
    DECLARE v_count INT;


    SET v_count = jumlah_koordinator_fakultas(p_faculty_id);


    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Faculty must have at least one coordinator.';
    END IF;


    INSERT INTO SUSTAINABILITY_CAMPAIGN(name, description, start_date, end_date, created_by)
    VALUES (p_name, p_description, p_start_date, p_end_date, p_staff_id);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_student_summary` (IN `p_user_id` INT)   BEGIN
    SELECT
        total_poin_mahasiswa(p_user_id) AS total_points,
        jumlah_kampanye_mahasiswa(p_user_id) AS total_campaigns_joined,
        total_sampah_disetor(p_user_id) AS total_waste_kg,
        jumlah_reward_ditukar(p_user_id) AS total_rewards_redeemed,
        status_mahasiswa(p_user_id) AS status;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ikut_kampanye` (IN `p_user_id` INT, IN `p_campaign_id` INT)   BEGIN
    IF ikut_kampanye(p_user_id, p_campaign_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mahasiswa sudah terdaftar di kampanye ini.';
    ELSE
        INSERT INTO USER_SUSTAINABILITY_CAMPAIGN(user_id, campaign_id, status)
        VALUES (p_user_id, p_campaign_id, 'active');
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporkan_aktivitas_sampah` (IN `p_user_id` INT, IN `p_bin_id` INT, IN `p_weight` DECIMAL(5,2), IN `p_status` ENUM('pending','verified'))   BEGIN
    DECLARE v_poin INT;


    -- Insert activity
    INSERT INTO RECYCLINGACTIVITY(user_id, recyclebin_id, weight_kg, status, timestamp)
    VALUES (p_user_id, p_bin_id, p_weight, p_status, NOW());


    -- Insert point if verified
    IF p_status = 'verified' THEN
        SET v_poin = fn_konversi_berat_ke_poin(p_weight);


        INSERT INTO BYN(user_id, campaign_id, point_amount, timestamp)
        VALUES (p_user_id, NULL, v_poin, NOW()); -- NULL if not tied to a campaign
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_redeem_reward` (IN `p_user_id` INT, IN `p_reward_id` INT)   BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_required_points INT;
    DECLARE v_discounted_points INT;
    DECLARE v_total_points INT;


    -- 1. Get student status
    SET v_status = status_mahasiswa(p_user_id);


    -- 2. Get reward cost
    SELECT points_required INTO v_required_points
    FROM REWARD_ITEM
    WHERE reward_id = p_reward_id;


    -- 3. Apply discount based on student status
    SET v_discounted_points = fn_hitung_diskon_reward(v_status, v_required_points);


    -- 4. Get total available points
    SELECT total_points INTO v_total_points
    FROM STUDENT
    WHERE stud_id = p_user_id;


    -- 5. Check if sufficient points
    IF v_total_points IS NULL OR v_total_points < v_discounted_points THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient points for redemption';
    END IF;


    -- 6. Deduct points directly from STUDENT table
    UPDATE STUDENT
    SET total_points = total_points - v_discounted_points
    WHERE stud_id = p_user_id;


    -- 7. Insert redemption log
    INSERT INTO REWARDREDEMPTION (user_id, reward_id, redeemed_at, status)
    VALUES (p_user_id, p_reward_id, NOW(), 'completed');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_student_status` (IN `p_user_id` INT)   BEGIN
    DECLARE v_last_activity TIMESTAMP;


    SELECT MAX(timestamp) INTO v_last_activity
    FROM RECYCLINGACTIVITY
    WHERE user_id = p_user_id;


    IF v_last_activity IS NULL OR v_last_activity < DATE_SUB(NOW(), INTERVAL 6 MONTH) THEN
        UPDATE STUDENT SET status = 'inactive' WHERE stud_id = p_user_id;
    ELSE
        UPDATE STUDENT SET status = 'active' WHERE stud_id = p_user_id;
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_hitung_diskon_reward` (`status_input` VARCHAR(20), `poin_awal` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   IF status_input = 'active' THEN
       RETURN ROUND(poin_awal * 0.9); -- 10% diskon
   ELSE 
       RETURN poin_awal;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_konversi_berat_ke_poin` (`berat_kg` DECIMAL(5,2)) RETURNS INT(11) DETERMINISTIC BEGIN
   RETURN ROUND(berat_kg * 10);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `ikut_kampanye` (`stud_id_input` INT, `campaign_id_input` INT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
   DECLARE jumlah INT;


   SELECT COUNT(*) INTO jumlah
   FROM USER_SUSTAINABILITY_CAMPAIGN
   WHERE user_id = stud_id_input AND campaign_id = campaign_id_input;


   RETURN jumlah > 0;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jumlah_kampanye_mahasiswa` (`stud_id_input` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE total_kampanye INT DEFAULT 0;


   SELECT COUNT(*)
   INTO total_kampanye
   FROM USER_SUSTAINABILITY_CAMPAIGN
   WHERE user_id = stud_id_input AND status = 'active';


   RETURN total_kampanye;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jumlah_koordinator_fakultas` (`faculty_id_input` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE jumlah INT;


   SELECT COUNT(*) INTO jumlah
   FROM SUSTAINABILITY_COORDINATOR
   WHERE faculty_id = faculty_id_input;


   RETURN jumlah;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jumlah_mahasiswa_aktif_fakultas` (`fac_id` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE jumlah INT DEFAULT 0;


   SELECT COUNT(*)
   INTO jumlah
   FROM STUDENT
   WHERE faculty_id = fac_id AND status = 'active';


   RETURN jumlah;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `jumlah_reward_ditukar` (`stud_id_input` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE jumlah INT DEFAULT 0;


   SELECT COUNT(*)
   INTO jumlah
   FROM REWARDREDEMPTION
   WHERE user_id = stud_id_input AND status = 'approved';


   RETURN jumlah;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `kampanye_dibuat_staff` (`staff_id_input` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE jumlah INT;


   SELECT COUNT(*) INTO jumlah
   FROM SUSTAINABILITY_CAMPAIGN
   WHERE created_by = staff_id_input;


   RETURN jumlah;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `kapasitas_total_tempat_sampah` (`loc_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
   DECLARE total DECIMAL(10,2);


   SELECT IFNULL(SUM(capacity_kg), 0)
   INTO total
   FROM RECYCLEBIN
   WHERE location_id = loc_id;


   RETURN total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `status_mahasiswa` (`stud_id_input` INT) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
   DECLARE status_result VARCHAR(20);


   SELECT status INTO status_result
   FROM STUDENT
   WHERE stud_id = stud_id_input;


   RETURN status_result;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_poin_mahasiswa` (`stud_id_input` INT) RETURNS INT(11) DETERMINISTIC BEGIN
   DECLARE total_poin INT DEFAULT 0;


   SELECT IFNULL(SUM(point_amount), 0)
   INTO total_poin
   FROM BYN
   WHERE user_id = stud_id_input;


   RETURN total_poin;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_sampah_disetor` (`stud_id_input` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
   DECLARE total_berat DECIMAL(10,2) DEFAULT 0;


   SELECT IFNULL(SUM(weight_kg), 0)
   INTO total_berat
   FROM RECYCLINGACTIVITY
   WHERE user_id = stud_id_input AND status = 'verified';


   RETURN total_berat;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`admin_id`, `username`, `password`, `name`, `email`, `phone`, `status`) VALUES
(1, 'admin1', 'rcf09*Dgh!', 'dr. Faizah Lailasari, S.Pt', 'cinta01@ud.or.id', '+62 (055) 957-8224', 'active'),
(2, 'admin2', ')2E1ZOLjBY', 'Sakura Hutasoit', 'lanjar64@hotmail.com', '+62 (38) 164-1168', 'active'),
(3, 'admin3', '7%d7Ae1zQ0', 'Harto Zulaika', 'galiono70@perum.mil.id', '+62 (09) 106-7390', 'active'),
(4, 'admin4', 'U6OVJ!i5*o', 'Balangga Prakasa', 'martakatamba@cv.org', '+62 (46) 152-4561', 'active'),
(5, 'admin5', 'o!2UBKkjEW', 'Danuja Saefullah, S.Pd', 'tedi66@gmail.com', '+62-697-749-5767', 'active'),
(6, 'admin6', '$YW_Eno3h9', 'Hj. Jamalia Wastuti, S.H.', 'luwar85@hotmail.com', '+62 (203) 186-9891', 'active'),
(7, 'admin7', 'm93BS3ce^R', 'Rika Dabukke', 'rmegantara@yahoo.com', '+62-021-937-5435', 'active'),
(8, 'admin8', 'V(n2TsWym#', 'Puji Aryani', 'sakurasusanti@yahoo.com', '+62-0590-806-5006', 'active'),
(9, 'admin9', 'm32AUE*s(L', 'Drs. Tina Novitasari', 'atarihoran@yahoo.com', '+62-56-802-6736', 'active'),
(10, 'admin10', 'QB8L(Odb&a', 'Patricia Uyainah', 'latuponoelvin@cv.id', '+62 (028) 626-6780', 'active'),
(11, 'admin11', '!^4a7NbW3F', 'Hardana Saragih', 'dewisitompul@gmail.com', '+62 (011) 373 5214', 'active'),
(12, 'admin12', '6$Y2DAizDf', 'H. Rudi Melani, S.E.', 'cakrabirawa12@gmail.com', '+62-016-342-9768', 'active'),
(13, 'admin13', 'VX8eNqr)o&', 'R.A. Ciaobella Aryani', 'manullangcahyanto@pd.my.id', '(0433) 590-9778', 'active'),
(14, 'admin14', '*qJd0L*hQ6', 'Puji Wijayanti, S.Psi', 'muni41@hotmail.com', '+62-094-701-0842', 'active'),
(15, 'admin15', '!0cUhIo+*D', 'Rahmi Manullang', 'maulanacici@pt.mil', '(0354) 184-4696', 'active'),
(16, 'admin16', '*FOcT7vc40', 'Dt. Panca Rajasa, M.TI.', 'caraka95@cv.mil.id', '+62 (13) 678 8585', 'active'),
(17, 'admin17', 'c&z3kCCx6v', 'Gangsar Mardhiyah, S.T.', 'cyuliarti@perum.net', '+62 (0308) 096-8790', 'active'),
(18, 'admin18', 'D&do1ASzJ+', 'Zahra Natsir', 'ridwan87@gmail.com', '+62 (654) 125-6874', 'active'),
(19, 'admin19', 'DYx69LSc&v', 'Ella Pudjiastuti', 'manullanggilang@cv.biz.id', '(000) 187 1363', 'active'),
(20, 'admin20', 'E!64M_QTym', 'Puti Najwa Siregar, M.Kom.', 'balapati02@ud.gov', '(0805) 956 1054', 'active'),
(21, 'admin21', 'yX%Easd^(3', 'Safina Wulandari', 'fpradana@perum.sch.id', '(0120) 070-8440', 'active'),
(22, 'admin22', '!4RL9Mrsd3', 'R. Surya Hidayat', 'calista68@perum.com', '+62 (003) 609 1785', 'active'),
(23, 'admin23', 'wB2OFKqn1@', 'Tgk. Rachel Winarsih, S.Gz', 'shariyah@yahoo.com', '(053) 413-2512', 'active'),
(24, 'admin24', '(TY9aAKkW!', 'Cut Alika Pangestu, M.Farm', 'yani64@yahoo.com', '0824521604', 'active'),
(25, 'admin25', ')IRZj6a_C9', 'Diah Usada', 'emil64@ud.sch.id', '(049) 109 9893', 'active'),
(26, 'admin26', '*3laAAW2mC', 'Cut Ida Putra, S.Farm', 'pangestuega@gmail.com', '+62 (521) 411-6267', 'active'),
(27, 'admin27', '^X7Wj2(g0a', 'H. Nardi Hassanah', 'gatra68@cv.net', '+62-025-469-3956', 'active'),
(28, 'admin28', '0gb^2VvY!w', 'Karsa Handayani', 'dirjapudjiastuti@pt.int', '+62 (072) 856-8369', 'active'),
(29, 'admin29', '1ZW2Rnpy%^', 'Makuta Sitorus', 'ibranimangunsong@pd.ponpes.id', '+62 (60) 820-6111', 'active'),
(30, 'admin30', '#0&GTVAphm', 'Tgk. Suci Tarihoran', 'firmansyahbetania@hotmail.com', '+62 (20) 527-8600', 'active'),
(31, 'admin31', '^9+HIpEb0x', 'Tantri Wastuti', 'irawanprakosa@yahoo.com', '+62 (11) 316-1839', 'active'),
(32, 'admin32', 'X+5GauwE%s', 'dr. Emil Marpaung', 'prabawatampubolon@ud.desa.id', '(0651) 584-1796', 'active'),
(33, 'admin33', 'Aq!1OzL3EI', 'Citra Tamba', 'permatamaras@hotmail.com', '+62 (38) 775-7802', 'active'),
(34, 'admin34', ')6BWd3hqgb', 'Cemeti Anggraini', 'cinta92@cv.mil', '+62-588-993-5628', 'active'),
(35, 'admin35', '&ORV7mCtA3', 'Anom Gunarto', 'lsinaga@gmail.com', '+62-0507-847-7119', 'active'),
(36, 'admin36', '4K*U7VdoO)', 'Rendy Sinaga, S.I.Kom', 'teguh51@perum.com', '+62 (516) 715-4718', 'active'),
(37, 'admin37', '$cuUD@jy5i', 'Gading Tampubolon', 'mardhiyahrafi@perum.sch.id', '(063) 322 7078', 'active'),
(38, 'admin38', '^QII9Mns)5', 'Legawa Kuswandari', 'puspasaridwi@hotmail.com', '+62-67-513-0157', 'active'),
(39, 'admin39', '6^$Y8LPcs1', 'Johan Haryanti', 'cawisadi46@cv.desa.id', '080 966 3922', 'active'),
(40, 'admin40', 'jG&K^4GhIs', 'Rosman Napitupulu, S.Farm', 'ssitorus@hotmail.com', '+62-022-214-2482', 'active'),
(41, 'admin41', 'elURVCql*4', 'Dr. Dasa Puspasari, M.Ak', 'namagaeka@gmail.com', '0816737591', 'active'),
(42, 'admin42', 'uGt9Evtvj_', 'Martaka Waskita, M.Farm', 'sakura61@hotmail.com', '(0151) 841 7710', 'active'),
(43, 'admin43', '&JSZXTsyU4', 'Michelle Pratiwi, S.E.', 'makarautami@perum.web.id', '+62 (0477) 762-8152', 'active'),
(44, 'admin44', 'Is&3HSbO^5', 'drg. Jati Yuliarti, S.H.', 'darimin78@hotmail.com', '(0563) 933-5584', 'active'),
(45, 'admin45', 'r&H8E$z^_R', 'Kamila Utami', 'nsiregar@pt.id', '+62 (0495) 872 7221', 'active'),
(46, 'admin46', '(HzJxqNQ_6', 'Ir. Hamima Rajasa, S.T.', 'maimunahwahyudin@pd.biz.id', '+62-129-698-2122', 'active'),
(47, 'admin47', 'iFaO6dBl^3', 'Drs. Nilam Widodo, S.E.', 'bajragin18@perum.or.id', '+62 (072) 162-6112', 'active'),
(48, 'admin48', '@8ZEBqczYI', 'Edison Permadi, S.Farm', 'ifa34@perum.org', '+62 (0478) 433-3473', 'active'),
(49, 'admin49', '2%4CQDFg91', 'Farhunnisa Putra', 'hesti85@ud.int', '+62 (0553) 308 1235', 'active'),
(50, 'admin50', '$Z9V##&s%c', 'dr. Rini Hakim', 'zhabibi@gmail.com', '0883809024', 'active'),
(51, 'admin51', '$xBdY9Vc+h', 'drg. Cagak Usada', 'maheswarasaadat@yahoo.com', '+62 (0945) 688-6225', 'active'),
(52, 'admin52', ')lhInT#l1D', 'Ganda Mayasari', 'kwaskita@hotmail.com', '+62 (007) 095 2132', 'active'),
(53, 'admin53', '3+52$GgTng', 'Kiandra Andriani, S.Pd', 'puspasarimaya@hotmail.com', '(0383) 755 6249', 'active'),
(54, 'admin54', '@7iGFkjmZF', 'Queen Yuliarti', 'ajiminwaskita@pt.edu', '(015) 211-2226', 'active'),
(55, 'admin55', 'kp3Ga)TyL#', 'H. Ridwan Tampubolon', 'hasanahivan@pd.int', '+62 (13) 042 9098', 'active'),
(56, 'admin56', '_2j19GRfk8', 'Tgk. Taufik Hidayat, M.Pd', 'puspitakadir@yahoo.com', '+62 (038) 116-7382', 'active'),
(57, 'admin57', '!O6(Qk9uG7', 'Tantri Natsir', 'yolandaikhsan@hotmail.com', '(084) 697 0212', 'active'),
(58, 'admin58', '+4Hbz8TIit', 'Baktiadi Megantara', 'msiregar@pt.biz.id', '(086) 707 8916', 'active'),
(59, 'admin59', '(S52Gb#r!&', 'Anastasia Maryati', 'rajatahairyanto@yahoo.com', '+62-671-244-9956', 'active'),
(60, 'admin60', 'Q(5PeA#pHc', 'Lili Laksita', 'latif17@perum.mil', '+62 (0253) 773 7273', 'active'),
(61, 'admin61', 'VoWmro(t)6', 'Gada Budiyanto, M.Kom.', 'lwijaya@pt.sch.id', '+62 (539) 939 8836', 'active'),
(62, 'admin62', '28MCJGd*$z', 'Kasiran Maryadi', 'fsuryatmi@ud.ac.id', '+62 (026) 892-1870', 'active'),
(63, 'admin63', 'J#i+R2QxC#', 'Eka Sirait', 'nwidodo@pd.org', '+62-37-570-8105', 'active'),
(64, 'admin64', 'tG3Dv4t**+', 'Anita Wijaya, S.Farm', 'maimunah17@gmail.com', '082 968 5584', 'active'),
(65, 'admin65', '@0Em*z1)Kx', 'Jarwa Hassanah', 'galarwastuti@pd.net', '+62 (0726) 308-2548', 'active'),
(66, 'admin66', 'Gp80HoJa$(', 'Gabriella Tarihoran', 'empluk00@perum.id', '+62 (99) 625 0471', 'active'),
(67, 'admin67', 'd3^EGp1p+5', 'Gilda Winarno', 'banawi65@ud.desa.id', '0859216423', 'active'),
(68, 'admin68', '@5Tf$9yzz0', 'Ajimin Aryani', 'pandumaheswara@perum.id', '+62 (0519) 836-2065', 'active'),
(69, 'admin69', 'O4g%pJx0$$', 'Samiah Wibisono', 'dodo15@gmail.com', '+62 (357) 315 3765', 'active'),
(70, 'admin70', '9sb(_JQF)^', 'Rahmi Simbolon', 'tasdik63@yahoo.com', '+62-319-961-3243', 'active'),
(71, 'admin71', '$8+KeX#rmk', 'dr. Edward Hasanah', 'paiman59@cv.mil.id', '+62 (379) 512 9599', 'active'),
(72, 'admin72', '!*A2dIf9R@', 'R. Nabila Prabowo, S.H.', 'kasiyah93@pt.com', '0812446849', 'active'),
(73, 'admin73', '(qH21UGdgJ', 'Drajat Simbolon', 'opannamaga@gmail.com', '+62 (15) 153-9702', 'active'),
(74, 'admin74', '(@9U%Q@f*Z', 'Natalia Manullang', 'yogasuartini@hotmail.com', '(081) 965 3925', 'active'),
(75, 'admin75', 'SV&1OxXai!', 'H. Mumpuni Sihombing', 'pratamacaraka@cv.my.id', '(0559) 527-3084', 'active'),
(76, 'admin76', '1%5Qtvie4x', 'Vino Latupono, M.M.', 'anggrainimursinin@pd.mil.id', '0869256081', 'active'),
(77, 'admin77', '!6zCMQPC_s', 'Cut Shania Mandala', 'najwanashiruddin@yahoo.com', '+62 (65) 449 3981', 'active'),
(78, 'admin78', 'z*0zFfVb8U', 'Hj. Padmi Kusmawati', 'mrahayu@yahoo.com', '+62 (0311) 363 5914', 'active'),
(79, 'admin79', 'MV3BW)n7q^', 'Caturangga Prasetyo', 'asmadi52@pt.sch.id', '+62 (002) 724 3070', 'active'),
(80, 'admin80', ')oa1CEjn_N', 'Sutan Pranata Kusmawati', 'wahyudinjais@pd.id', '+62 (157) 989 9113', 'active'),
(81, 'admin81', '^6VWTl)Q*V', 'Cut Qori Pertiwi, S.Kom', 'lpratiwi@gmail.com', '080 927 0432', 'active'),
(82, 'admin82', '9zSOgn0n_3', 'Paulin Pertiwi', 'pkusumo@hotmail.com', '+62 (067) 791 3165', 'active'),
(83, 'admin83', 'tbz1BcpB%!', 'Elisa Manullang', 'kairav99@pt.ponpes.id', '+62-260-284-3804', 'active'),
(84, 'admin84', '$cKb7Vlda@', 'Dian Siregar', 'bakiman39@cv.co.id', '+62 (488) 950-6685', 'active'),
(85, 'admin85', '#SyBUokT^3', 'R. Elisa Lestari', 'uwaissaka@hotmail.com', '(090) 234-2502', 'active'),
(86, 'admin86', '_iN36FsG6x', 'drg. Paris Aryani', 'hartomayasari@pd.mil', '+62 (30) 628-5517', 'active'),
(87, 'admin87', 'v91&aEcP5&', 'Sutan Prayoga Waluyo, S.H.', 'najamnainggolan@yahoo.com', '(0008) 603-5912', 'active'),
(88, 'admin88', 'h#T0kBKtqd', 'Ganep Habibi', 'zmayasari@pt.net.id', '+62 (696) 427-7696', 'active'),
(89, 'admin89', '_U$M1Ifz%b', 'Sutan Hasan Pudjiastuti, S.Kom', 'gabriellaharyanti@gmail.com', '+62 (702) 472-9253', 'active'),
(90, 'admin90', 'oYje0VTpS#', 'Dt. Capa Wijaya', 'nurainimahdi@pt.mil.id', '+62-90-008-7105', 'active'),
(91, 'admin91', 'v)@y0Jirc8', 'Prabu Kurniawan', 'upratama@yahoo.com', '+62 (19) 075-8242', 'active'),
(92, 'admin92', 'D3d5+Iqn^i', 'Silvia Dabukke', 'pancanuraini@pd.ponpes.id', '+62-0969-149-7037', 'active'),
(93, 'admin93', '1#2B3mDp_u', 'Olivia Habibi', 'dadap54@perum.or.id', '+62-103-447-4689', 'active'),
(94, 'admin94', 'ha)W^W7t!6', 'Cakrawala Utama', 'empluk51@ud.com', '+62-067-970-7736', 'active'),
(95, 'admin95', '6RKVrn5e!C', 'Taufan Firmansyah', 'dlailasari@gmail.com', '(0992) 949-2950', 'active'),
(96, 'admin96', 'Y^Ex1Moaw1', 'Laila Saefullah, M.Pd', 'dlazuardi@hotmail.com', '+62 (725) 125 2315', 'active'),
(97, 'admin97', '99aLWEAd#7', 'Opung Kuswandari, S.Sos', 'latuponoibrani@yahoo.com', '081 053 4246', 'active'),
(98, 'admin98', 'r(@pGMVgx7', 'Kania Gunawan', 'vpalastri@gmail.com', '0847348886', 'active'),
(99, 'admin99', 'R2NjY%ky!d', 'Teddy Rajasa', 'leo22@ud.sch.id', '(029) 421 7304', 'active'),
(100, 'admin100', '9GL0oSFN$f', 'Harsaya Yuliarti', 'napitupulukuncara@hotmail.com', '+62-352-793-0480', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `byn`
--

CREATE TABLE BIN_TYPE (
    id VARCHAR(12) PRIMARY KEY,
    bin_name VARCHAR(255),
    description VARCHAR(255), 
    color_code VARCHAR(20),
    status VARCHAR(8)
); ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `byn`
--

INSERT INTO `byn` (`byn_id`, `user_id`, `campaign_id`, `point_amount`, `timestamp`) VALUES
(1, 1, 71, 30, '2025-01-30 12:44:48'),
(2, 53, 84, 70, '2025-05-07 05:14:30'),
(3, 62, 84, 35, '2025-03-13 01:36:11'),
(4, 97, 37, 51, '2025-03-15 16:07:54'),
(5, 37, 83, 17, '2025-03-11 11:42:36'),
(6, 99, 12, 93, '2025-01-01 18:36:54'),
(7, 74, 30, 78, '2025-05-28 06:44:31'),
(8, 95, 93, 14, '2025-01-12 21:14:31'),
(9, 23, 54, 32, '2025-05-29 09:49:15'),
(10, 5, 51, 73, '2025-05-25 16:18:39'),
(11, 24, 96, 47, '2025-03-29 09:47:50'),
(12, 5, 2, 48, '2025-05-14 17:10:56'),
(13, 73, 78, 23, '2025-03-24 10:43:20'),
(14, 43, 37, 68, '2025-05-13 18:43:30'),
(15, 83, 70, 77, '2025-03-05 11:42:00'),
(16, 64, 18, 74, '2025-01-16 11:03:05'),
(17, 60, 35, 34, '2025-02-28 05:02:56'),
(18, 15, 43, 30, '2025-02-13 09:28:09'),
(19, 94, 59, 92, '2025-04-27 20:20:03'),
(20, 33, 92, 33, '2025-01-01 22:21:31'),
(21, 2, 95, 53, '2025-03-14 02:06:30'),
(22, 38, 73, 96, '2025-02-15 04:23:03'),
(23, 97, 25, 32, '2025-03-18 19:55:36'),
(24, 79, 82, 61, '2025-03-19 12:28:35'),
(25, 55, 66, 51, '2025-01-14 21:28:07'),
(26, 12, 52, 95, '2025-01-03 03:26:42'),
(27, 13, 24, 27, '2025-04-12 21:28:33'),
(28, 62, 42, 41, '2025-04-01 01:50:08'),
(29, 1, 34, 59, '2025-03-26 08:57:47'),
(30, 31, 58, 44, '2025-03-20 10:50:33'),
(31, 43, 39, 84, '2025-04-19 16:53:36'),
(32, 93, 74, 11, '2025-01-20 16:05:22'),
(33, 34, 84, 56, '2025-03-10 23:38:03'),
(34, 89, 31, 17, '2025-06-09 07:19:10'),
(35, 86, 16, 69, '2025-03-31 09:24:25'),
(36, 40, 21, 61, '2025-03-18 13:25:02'),
(37, 88, 65, 100, '2025-04-27 19:00:16'),
(38, 99, 40, 98, '2025-05-27 13:15:48'),
(39, 16, 82, 47, '2025-05-13 06:23:27'),
(40, 48, 79, 38, '2025-02-08 01:18:50'),
(41, 29, 18, 71, '2025-02-22 16:43:45'),
(42, 20, 59, 87, '2025-05-21 00:13:48'),
(43, 48, 54, 99, '2025-06-04 08:44:28'),
(44, 71, 61, 78, '2025-03-01 23:24:30'),
(45, 86, 28, 41, '2025-01-29 11:08:57'),
(46, 88, 97, 86, '2025-05-02 09:42:08'),
(47, 11, 68, 67, '2025-01-17 13:25:36'),
(48, 68, 91, 56, '2025-01-16 05:35:45'),
(49, 10, 73, 24, '2025-05-06 02:15:18'),
(50, 8, 71, 74, '2025-06-01 06:29:14'),
(51, 26, 74, 78, '2025-04-12 16:19:48'),
(52, 20, 22, 51, '2025-01-22 22:09:47'),
(53, 67, 57, 24, '2025-04-05 12:08:04'),
(54, 88, 27, 84, '2025-05-11 13:22:18'),
(55, 63, 12, 75, '2025-01-16 21:29:23'),
(56, 58, 8, 68, '2025-02-14 03:00:47'),
(57, 17, 66, 63, '2025-02-28 21:38:03'),
(58, 59, 73, 17, '2025-05-05 17:39:52'),
(59, 72, 60, 96, '2025-05-23 12:20:32'),
(60, 40, 93, 12, '2025-03-22 18:00:12'),
(61, 51, 33, 10, '2025-04-12 08:33:53'),
(62, 96, 28, 84, '2025-01-26 23:09:16'),
(63, 10, 6, 64, '2025-02-22 12:53:33'),
(64, 45, 90, 18, '2025-01-01 05:33:11'),
(65, 70, 8, 18, '2025-02-18 01:26:10'),
(66, 61, 5, 46, '2025-05-12 01:38:29'),
(67, 53, 24, 27, '2025-05-30 14:30:37'),
(68, 99, 83, 92, '2025-01-09 08:46:56'),
(69, 54, 48, 58, '2025-05-24 20:59:57'),
(70, 58, 49, 58, '2025-04-10 06:53:23'),
(71, 11, 88, 94, '2025-04-13 07:06:14'),
(72, 70, 18, 93, '2025-05-27 23:10:15'),
(73, 45, 16, 32, '2025-04-18 08:35:13'),
(74, 69, 51, 77, '2025-05-12 06:34:02'),
(75, 17, 94, 38, '2025-04-06 11:30:02'),
(76, 1, 97, 12, '2025-02-23 23:03:01'),
(77, 39, 60, 96, '2025-02-28 05:13:02'),
(78, 93, 70, 64, '2025-02-26 02:17:02'),
(79, 69, 49, 39, '2025-01-26 07:53:32'),
(80, 32, 59, 54, '2025-03-24 16:56:45'),
(81, 20, 36, 34, '2025-01-12 11:06:41'),
(82, 93, 98, 24, '2025-02-15 06:25:31'),
(83, 5, 85, 63, '2025-01-01 15:53:46'),
(84, 79, 99, 12, '2025-01-22 04:27:39'),
(85, 31, 27, 18, '2025-05-30 01:51:56'),
(86, 13, 77, 14, '2025-03-08 12:42:55'),
(87, 58, 77, 96, '2025-05-23 13:21:30'),
(88, 91, 7, 41, '2025-04-06 15:55:57'),
(89, 95, 6, 61, '2025-05-17 08:15:18'),
(90, 57, 30, 79, '2025-03-13 01:36:37'),
(91, 28, 97, 17, '2025-03-17 15:38:08'),
(92, 18, 65, 47, '2025-03-18 01:54:58'),
(93, 30, 94, 83, '2025-01-19 03:35:55'),
(94, 41, 74, 86, '2025-04-11 16:16:31'),
(95, 99, 87, 51, '2025-05-14 10:01:11'),
(96, 31, 39, 28, '2025-06-03 05:05:29'),
(97, 85, 67, 38, '2025-05-12 14:48:30'),
(98, 53, 39, 45, '2025-01-29 04:22:03'),
(99, 8, 72, 85, '2025-04-04 00:21:55'),
(100, 95, 23, 90, '2025-05-05 10:55:50');

-- --------------------------------------------------------

--
-- Table structure for table `byn_location`
--

CREATE TABLE `byn_location` (
  `location_id` int(11) NOT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `dept_id` int(11) DEFAULT NULL,
  `room` varchar(50) DEFAULT NULL,
  `building` varchar(100) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `byn_location`
--

INSERT INTO `byn_location` (`location_id`, `faculty_id`, `dept_id`, `room`, `building`, `status`) VALUES
(1, 4, 3, 'R-229', 'UD Suwarno', 'active'),
(2, 5, 38, 'R-439', 'Perum Pratiwi Halimah', 'active'),
(3, 7, 7, 'R-995', 'PT Hasanah Suryono', 'active'),
(4, 7, 29, 'R-202', 'PD Zulkarnain Tbk', 'active'),
(5, 5, 30, 'R-115', 'PD Wijayanti', 'active'),
(6, 6, 10, 'R-519', 'CV Kusumo Halimah (Persero) Tbk', 'active'),
(7, 7, 10, 'R-176', 'PD Yuliarti Tbk', 'active'),
(8, 4, 17, 'R-446', 'Perum Iswahyudi Uwais', 'active'),
(9, 5, 26, 'R-765', 'PD Pudjiastuti Prasetyo Tbk', 'active'),
(10, 1, 22, 'R-972', 'PT Permata', 'active'),
(11, 6, 35, 'R-489', 'PD Widiastuti', 'active'),
(12, 3, 32, 'R-993', 'PD Rahayu (Persero) Tbk', 'active'),
(13, 5, 3, 'R-732', 'UD Gunarto', 'active'),
(14, 1, 16, 'R-746', 'Perum Waluyo Siregar (Persero) Tbk', 'active'),
(15, 6, 19, 'R-332', 'CV Wastuti', 'active'),
(16, 6, 6, 'R-544', 'Perum Budiman Tbk', 'active'),
(17, 1, 7, 'R-554', 'PT Dongoran Firgantoro', 'active'),
(18, 2, 20, 'R-129', 'UD Rahimah Puspita (Persero) Tbk', 'active'),
(19, 1, 21, 'R-915', 'PT Hutasoit Marpaung Tbk', 'active'),
(20, 1, 19, 'R-467', 'PT Pranowo Suwarno Tbk', 'active'),
(21, 3, 28, 'R-249', 'CV Nainggolan (Persero) Tbk', 'active'),
(22, 2, 34, 'R-521', 'Perum Lestari Saefullah (Persero) Tbk', 'active'),
(23, 5, 12, 'R-274', 'Perum Siregar', 'active'),
(24, 2, 6, 'R-724', 'PT Budiman (Persero) Tbk', 'active'),
(25, 7, 25, 'R-734', 'UD Permadi (Persero) Tbk', 'active'),
(26, 6, 16, 'R-609', 'Perum Mardhiyah Anggraini', 'active'),
(27, 5, 10, 'R-337', 'CV Mandasari Pratiwi Tbk', 'active'),
(28, 4, 17, 'R-570', 'PD Usada', 'active'),
(29, 3, 1, 'R-923', 'PT Palastri Haryanti', 'active'),
(30, 4, 19, 'R-793', 'PT Zulkarnain Marbun', 'active'),
(31, 5, 11, 'R-175', 'PT Marbun Hardiansyah (Persero) Tbk', 'active'),
(32, 4, 23, 'R-701', 'PD Sitorus Tbk', 'active'),
(33, 3, 28, 'R-806', 'CV Napitupulu Kuswandari', 'active'),
(34, 3, 30, 'R-965', 'CV Widodo Nugroho Tbk', 'active'),
(35, 3, 13, 'R-493', 'PD Suartini', 'active'),
(36, 7, 31, 'R-209', 'PT Nugroho Pratiwi (Persero) Tbk', 'active'),
(37, 2, 25, 'R-685', 'UD Permadi', 'active'),
(38, 3, 37, 'R-402', 'CV Rajasa Anggraini Tbk', 'active'),
(39, 6, 19, 'R-122', 'UD Mandasari (Persero) Tbk', 'active'),
(40, 7, 26, 'R-381', 'Perum Pratama Tbk', 'active'),
(41, 1, 37, 'R-985', 'CV Widodo Susanti (Persero) Tbk', 'active'),
(42, 6, 4, 'R-720', 'PD Sitorus', 'active'),
(43, 6, 32, 'R-952', 'UD Wijayanti Tbk', 'active'),
(44, 3, 15, 'R-721', 'CV Jailani Hariyah Tbk', 'active'),
(45, 7, 23, 'R-324', 'PT Prakasa', 'active'),
(46, 6, 13, 'R-735', 'UD Sinaga Latupono', 'active'),
(47, 3, 9, 'R-743', 'PT Rahmawati (Persero) Tbk', 'active'),
(48, 1, 3, 'R-416', 'UD Hastuti Zulkarnain', 'active'),
(49, 7, 29, 'R-134', 'PD Susanti Tarihoran Tbk', 'active'),
(50, 5, 24, 'R-849', 'PT Thamrin Widiastuti', 'active'),
(51, 2, 6, 'R-402', 'PT Wacana Budiman Tbk', 'active'),
(52, 3, 27, 'R-279', 'PD Lazuardi Tbk', 'active'),
(53, 2, 9, 'R-905', 'PT Firmansyah', 'active'),
(54, 5, 24, 'R-643', 'Perum Wulandari', 'active'),
(55, 5, 18, 'R-950', 'PD Hastuti Tbk', 'active'),
(56, 2, 17, 'R-944', 'PD Mustofa Nuraini Tbk', 'active'),
(57, 4, 19, 'R-864', 'PT Budiyanto Tbk', 'active'),
(58, 7, 22, 'R-923', 'PD Mandala Najmudin Tbk', 'active'),
(59, 1, 30, 'R-177', 'Perum Agustina Santoso (Persero) Tbk', 'active'),
(60, 2, 15, 'R-980', 'PT Dongoran', 'active'),
(61, 6, 26, 'R-966', 'CV Firgantoro Siregar', 'active'),
(62, 7, 36, 'R-474', 'PD Adriansyah Tbk', 'active'),
(63, 1, 26, 'R-114', 'PD Santoso Hutapea Tbk', 'active'),
(64, 3, 35, 'R-226', 'PT Widodo Laksmiwati', 'active'),
(65, 4, 24, 'R-788', 'PD Habibi Pratiwi', 'active'),
(66, 6, 17, 'R-698', 'UD Nurdiyanti Tbk', 'active'),
(67, 4, 24, 'R-210', 'UD Suryatmi Laksmiwati Tbk', 'active'),
(68, 6, 15, 'R-582', 'UD Riyanti (Persero) Tbk', 'active'),
(69, 1, 40, 'R-674', 'Perum Sihotang Prayoga (Persero) Tbk', 'active'),
(70, 3, 40, 'R-326', 'CV Sihombing Mulyani Tbk', 'active'),
(71, 6, 5, 'R-750', 'CV Ardianto Pradipta', 'active'),
(72, 7, 30, 'R-817', 'Perum Anggraini', 'active'),
(73, 3, 27, 'R-219', 'PD Kuswandari Uwais', 'active'),
(74, 2, 3, 'R-138', 'PT Hasanah', 'active'),
(75, 3, 32, 'R-218', 'PT Sitorus Siregar', 'active'),
(76, 1, 16, 'R-650', 'CV Pradana', 'active'),
(77, 2, 25, 'R-564', 'CV Prasetyo Sihombing', 'active'),
(78, 3, 35, 'R-529', 'CV Waskita Wahyudin (Persero) Tbk', 'active'),
(79, 5, 10, 'R-524', 'Perum Habibi Wasita (Persero) Tbk', 'active'),
(80, 6, 7, 'R-953', 'PT Saefullah', 'active'),
(81, 4, 40, 'R-517', 'Perum Hastuti Firgantoro', 'active'),
(82, 3, 3, 'R-806', 'PT Budiman Laksmiwati Tbk', 'active'),
(83, 3, 14, 'R-554', 'CV Hidayat', 'active'),
(84, 4, 16, 'R-975', 'PT Marpaung Damanik', 'active'),
(85, 3, 7, 'R-802', 'Perum Winarno Sinaga', 'active'),
(86, 3, 35, 'R-760', 'PT Handayani', 'active'),
(87, 3, 4, 'R-507', 'PD Wijayanti Hariyah Tbk', 'active'),
(88, 3, 13, 'R-225', 'PT Purnawati', 'active'),
(89, 7, 30, 'R-193', 'PT Megantara Damanik (Persero) Tbk', 'active'),
(90, 6, 14, 'R-757', 'PD Hassanah', 'active'),
(91, 6, 39, 'R-121', 'PT Utama Pangestu Tbk', 'active'),
(92, 1, 22, 'R-349', 'PD Pudjiastuti Mayasari Tbk', 'active'),
(93, 2, 37, 'R-310', 'CV Santoso', 'active'),
(94, 1, 36, 'R-312', 'UD Hasanah', 'active'),
(95, 5, 14, 'R-932', 'PD Usada', 'active'),
(96, 7, 15, 'R-436', 'PT Suryatmi', 'active'),
(97, 7, 10, 'R-907', 'PD Latupono Agustina', 'active'),
(98, 5, 1, 'R-383', 'Perum Firgantoro Rahmawati (Persero) Tbk', 'active'),
(99, 7, 10, 'R-233', 'CV Padmasari Mustofa', 'active'),
(100, 5, 17, 'R-917', 'PD Andriani Tbk', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `faculty`
--

CREATE TABLE `faculty` (
  `faculty_id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faculty`
--

INSERT INTO `faculty` (`faculty_id`, `name`, `status`) VALUES
(1, 'FSAD', 'active'),
(2, 'FTEIC', 'active'),
(3, 'FTSPK', 'active'),
(4, 'FTIRS', 'active'),
(5, 'FTK', 'active'),
(6, 'FV', 'active'),
(7, 'FDKBD', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `faculty_department`
--

CREATE TABLE `faculty_department` (
  `dept_id` int(11) NOT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `department_name` varchar(100) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faculty_department`
--

INSERT INTO `faculty_department` (`dept_id`, `faculty_id`, `department_name`, `status`) VALUES
(1, 1, 'Fisika', 'active'),
(2, 1, 'Matematika', 'active'),
(3, 1, 'Statistika', 'active'),
(4, 1, 'Kimia', 'active'),
(5, 1, 'Biologi', 'active'),
(6, 1, 'Aktuaria', 'active'),
(7, 2, 'Teknik Elektro', 'active'),
(8, 2, 'Teknik Biomedik', 'active'),
(9, 2, 'Teknik Komputer', 'active'),
(10, 2, 'Teknik Informatika', 'active'),
(11, 2, 'Sistem Informasi', 'active'),
(12, 2, 'Teknologi Informasi', 'active'),
(13, 3, 'Teknik Sipil', 'active'),
(14, 3, 'Arsitektur', 'active'),
(15, 3, 'Teknik Lingkungan', 'active'),
(16, 3, 'Perencanaan Wilayah dan Kota', 'active'),
(17, 3, 'Teknik Geomatika', 'active'),
(18, 3, 'Teknik Geofisika', 'active'),
(19, 4, 'Teknik Mesin', 'active'),
(20, 4, 'Teknik Kimia', 'active'),
(21, 4, 'Teknik Fisika', 'active'),
(22, 4, 'Teknik Sistem dan Industri', 'active'),
(23, 4, 'Teknik Material dan Metalurgi', 'active'),
(24, 5, 'Teknik Perkapalan', 'active'),
(25, 5, 'Teknik Sistem Perkapalan', 'active'),
(26, 5, 'Teknik Kelautan', 'active'),
(27, 5, 'Teknik Transportasi Laut', 'active'),
(28, 5, 'Teknik Lepas Pantai', 'active'),
(29, 6, 'Teknik Infrastruktur Sipil', 'active'),
(30, 6, 'Teknik Mesin Industri', 'active'),
(31, 6, 'Teknik Elektro Otomasi', 'active'),
(32, 6, 'Teknik Kimia Industri', 'active'),
(33, 6, 'Teknik Instrumentasi', 'active'),
(34, 6, 'Statistika Bisnis', 'active'),
(35, 7, 'Desain Produk Industri', 'active'),
(36, 7, 'Desain Interior', 'active'),
(37, 7, 'Desain Komunikasi Visual', 'active'),
(38, 7, 'Manajemen Teknologi', 'active'),
(39, 7, 'Manajemen Bisnis', 'active'),
(40, 7, 'Studi Pembangunan', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `marketing`
--

CREATE TABLE `marketing` (
  `marketing_id` int(11) NOT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `platform` varchar(50) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `marketing`
--

INSERT INTO `marketing` (`marketing_id`, `campaign_id`, `platform`, `start_date`, `end_date`, `status`) VALUES
(1, 1, 'Instagram', '2024-09-16', '2025-05-10', 'active'),
(2, 2, 'Twitter', '2025-04-15', '2025-04-16', 'active'),
(3, 3, 'Twitter', '2025-04-20', '2025-06-08', 'active'),
(4, 4, 'LinkedIn', '2025-04-06', '2025-05-30', 'active'),
(5, 5, 'LinkedIn', '2024-09-21', '2024-12-12', 'active'),
(6, 6, 'Twitter', '2025-05-05', '2025-05-28', 'active'),
(7, 7, 'LinkedIn', '2025-03-25', '2025-05-17', 'active'),
(8, 8, 'Twitter', '2024-11-17', '2025-04-24', 'active'),
(9, 9, 'Twitter', '2025-05-16', '2025-05-29', 'active'),
(10, 10, 'LinkedIn', '2025-06-06', '2025-06-08', 'active'),
(11, 11, 'Instagram', '2025-02-20', '2025-06-08', 'active'),
(12, 12, 'Instagram', '2024-08-04', '2025-05-26', 'active'),
(13, 13, 'Twitter', '2025-01-28', '2025-03-19', 'active'),
(14, 14, 'LinkedIn', '2024-10-17', '2025-05-12', 'active'),
(15, 15, 'Instagram', '2025-03-19', '2025-04-11', 'active'),
(16, 16, 'Twitter', '2024-08-13', '2025-01-08', 'active'),
(17, 17, 'Twitter', '2025-03-24', '2025-04-01', 'active'),
(18, 18, 'LinkedIn', '2025-03-06', '2025-03-08', 'active'),
(19, 19, 'LinkedIn', '2024-10-16', '2025-04-27', 'active'),
(20, 20, 'Twitter', '2024-07-04', '2025-05-30', 'active'),
(21, 21, 'Instagram', '2024-12-04', '2025-04-04', 'active'),
(22, 22, 'LinkedIn', '2025-03-19', '2025-04-22', 'active'),
(23, 23, 'LinkedIn', '2024-11-27', '2025-03-05', 'active'),
(24, 24, 'LinkedIn', '2025-02-04', '2025-03-02', 'active'),
(25, 25, 'Instagram', '2025-06-01', '2025-06-07', 'active'),
(26, 26, 'Instagram', '2024-10-31', '2025-04-04', 'active'),
(27, 27, 'Twitter', '2024-06-10', '2024-12-06', 'active'),
(28, 28, 'LinkedIn', '2024-10-23', '2025-05-15', 'active'),
(29, 29, 'Instagram', '2024-08-26', '2025-04-20', 'active'),
(30, 30, 'Instagram', '2025-02-01', '2025-03-26', 'active'),
(31, 31, 'LinkedIn', '2024-08-13', '2024-12-25', 'active'),
(32, 32, 'Instagram', '2025-04-02', '2025-05-09', 'active'),
(33, 33, 'Twitter', '2025-02-14', '2025-03-02', 'active'),
(34, 34, 'Instagram', '2025-04-24', '2025-05-31', 'active'),
(35, 35, 'Instagram', '2024-07-27', '2024-10-26', 'active'),
(36, 36, 'Twitter', '2024-10-23', '2024-11-13', 'active'),
(37, 37, 'LinkedIn', '2024-07-24', '2025-02-15', 'active'),
(38, 38, 'Instagram', '2024-06-27', '2025-02-14', 'active'),
(39, 39, 'Twitter', '2025-01-29', '2025-05-05', 'active'),
(40, 40, 'LinkedIn', '2025-06-01', '2025-06-05', 'active'),
(41, 41, 'Twitter', '2024-08-29', '2025-04-09', 'active'),
(42, 42, 'Instagram', '2024-12-28', '2025-05-08', 'active'),
(43, 43, 'Twitter', '2025-06-03', '2025-06-06', 'active'),
(44, 44, 'Instagram', '2025-03-06', '2025-03-17', 'active'),
(45, 45, 'LinkedIn', '2024-11-12', '2025-04-05', 'active'),
(46, 46, 'LinkedIn', '2025-02-28', '2025-03-02', 'active'),
(47, 47, 'Twitter', '2024-12-18', '2025-05-14', 'active'),
(48, 48, 'Instagram', '2024-10-24', '2025-02-19', 'active'),
(49, 49, 'LinkedIn', '2024-12-01', '2025-05-16', 'active'),
(50, 50, 'Twitter', '2024-08-16', '2024-08-27', 'active'),
(51, 51, 'LinkedIn', '2025-03-21', '2025-05-18', 'active'),
(52, 52, 'LinkedIn', '2024-10-20', '2024-11-09', 'active'),
(53, 53, 'Instagram', '2025-03-31', '2025-04-01', 'active'),
(54, 54, 'LinkedIn', '2024-07-30', '2024-10-02', 'active'),
(55, 55, 'LinkedIn', '2024-12-08', '2025-01-20', 'active'),
(56, 56, 'Instagram', '2024-10-25', '2025-04-26', 'active'),
(57, 57, 'LinkedIn', '2024-12-23', '2025-03-04', 'active'),
(58, 58, 'LinkedIn', '2024-07-29', '2024-08-05', 'active'),
(59, 59, 'Instagram', '2024-12-07', '2025-03-16', 'active'),
(60, 60, 'Instagram', '2025-01-11', '2025-02-04', 'active'),
(61, 61, 'LinkedIn', '2024-08-13', '2024-08-30', 'active'),
(62, 62, 'LinkedIn', '2024-07-07', '2024-10-11', 'active'),
(63, 63, 'LinkedIn', '2025-02-23', '2025-04-08', 'active'),
(64, 64, 'LinkedIn', '2025-03-15', '2025-03-16', 'active'),
(65, 65, 'Twitter', '2024-06-19', '2025-05-05', 'active'),
(66, 66, 'LinkedIn', '2024-08-07', '2025-02-10', 'active'),
(67, 67, 'Instagram', '2024-10-05', '2024-11-21', 'active'),
(68, 68, 'Instagram', '2025-05-31', '2025-06-02', 'active'),
(69, 69, 'Instagram', '2024-11-13', '2025-03-28', 'active'),
(70, 70, 'Instagram', '2024-12-27', '2025-04-30', 'active'),
(71, 71, 'LinkedIn', '2024-11-09', '2025-01-13', 'active'),
(72, 72, 'LinkedIn', '2025-05-30', '2025-06-07', 'active'),
(73, 73, 'Twitter', '2024-07-31', '2024-12-28', 'active'),
(74, 74, 'LinkedIn', '2025-02-15', '2025-05-14', 'active'),
(75, 75, 'Instagram', '2025-06-02', '2025-06-04', 'active'),
(76, 76, 'LinkedIn', '2024-09-23', '2025-01-22', 'active'),
(77, 77, 'Twitter', '2024-10-11', '2024-10-20', 'active'),
(78, 78, 'LinkedIn', '2024-06-18', '2024-10-29', 'active'),
(79, 79, 'LinkedIn', '2025-03-22', '2025-05-31', 'active'),
(80, 80, 'Instagram', '2024-09-21', '2024-09-22', 'active'),
(81, 81, 'Twitter', '2024-09-08', '2024-10-22', 'active'),
(82, 82, 'LinkedIn', '2024-10-03', '2025-03-05', 'active'),
(83, 83, 'LinkedIn', '2025-05-10', '2025-05-25', 'active'),
(84, 84, 'Twitter', '2024-10-08', '2025-01-20', 'active'),
(85, 85, 'LinkedIn', '2024-10-06', '2025-06-04', 'active'),
(86, 86, 'Twitter', '2025-02-01', '2025-04-16', 'active'),
(87, 87, 'Twitter', '2025-05-17', '2025-06-06', 'active'),
(88, 88, 'Instagram', '2025-02-10', '2025-02-10', 'active'),
(89, 89, 'LinkedIn', '2024-08-31', '2024-12-07', 'active'),
(90, 90, 'Twitter', '2024-09-09', '2025-05-27', 'active'),
(91, 91, 'Twitter', '2024-06-19', '2025-01-31', 'active'),
(92, 92, 'Twitter', '2025-04-28', '2025-05-24', 'active'),
(93, 93, 'Instagram', '2025-02-09', '2025-04-15', 'active'),
(94, 94, 'LinkedIn', '2024-09-10', '2024-10-03', 'active'),
(95, 95, 'Instagram', '2024-06-15', '2024-08-15', 'active'),
(96, 96, 'Instagram', '2024-10-23', '2024-10-28', 'active'),
(97, 97, 'Twitter', '2024-12-19', '2025-05-04', 'active'),
(98, 98, 'Twitter', '2024-09-08', '2025-05-05', 'active'),
(99, 99, 'Twitter', '2024-10-07', '2025-02-22', 'active'),
(100, 100, 'Twitter', '2024-07-15', '2025-01-02', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `pics`
--

CREATE TABLE `pics` (
  `pic_id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `staff_id` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pics`
--

INSERT INTO `pics` (`pic_id`, `name`, `phone`, `email`, `staff_id`, `status`) VALUES
(1, 'Puti Kiandra Situmorang, S.E.', '088 211 6407', 'lwibisono@ud.go.id', 1, 'active'),
(2, 'R. Ratna Puspita, S.Sos', '+62-022-140-7116', 'lasmononatsir@pt.net', 2, 'active'),
(3, 'Drs. Anom Sudiati, S.Pt', '(0272) 134-4220', 'jwijaya@ud.my.id', 3, 'active'),
(4, 'Nurul Wacana', '+62-0541-508-7902', 'dfirgantoro@gmail.com', 4, 'active'),
(5, 'Rahayu Uyainah', '+62 (0748) 369 4826', 'sihombingwawan@hotmail.com', 5, 'active'),
(6, 'drg. Adika Mansur', '+62 (099) 791-3580', 'erik56@hotmail.com', 6, 'active'),
(7, 'Tgk. Zahra Wacana', '+62 (0425) 049-5469', 'permataozy@gmail.com', 7, 'active'),
(8, 'Jasmin Ramadan, S.I.Kom', '+62 (659) 634 1719', 'fnasyiah@hotmail.com', 8, 'active'),
(9, 'Dr. Nova Zulaika, S.Pd', '(002) 718-1035', 'gangsa96@gmail.com', 9, 'active'),
(10, 'dr. Malik Utami, S.Farm', '+62 (25) 696 4677', 'prabamaheswara@perum.web.id', 10, 'active'),
(11, 'Dr. Bakiman Ramadan, M.Ak', '(0040) 424-9109', 'yulianapradipta@ud.go.id', 11, 'active'),
(12, 'Vanesa Prakasa', '+62 (037) 279 9987', 'ruwais@perum.org', 12, 'active'),
(13, 'Malik Rahmawati', '0828980149', 'rahmanagustina@ud.id', 13, 'active'),
(14, 'Wani Santoso', '+62-0165-596-3831', 'aryaninaradi@cv.desa.id', 14, 'active'),
(15, 'Artawan Januar', '0876847586', 'karsamulyani@perum.or.id', 15, 'active'),
(16, 'Limar Megantara', '(0541) 223-1983', 'aastuti@hotmail.com', 16, 'active'),
(17, 'Cut Faizah Marbun', '+62 (55) 795-5747', 'pjanuar@cv.or.id', 17, 'active'),
(18, 'Lega Marbun, M.M.', '+62 (035) 939 6169', 'nhasanah@pd.mil.id', 18, 'active'),
(19, 'Ella Hidayat', '+62 (019) 350 7668', 'vmandala@cv.co.id', 19, 'active'),
(20, 'Dr. Purwadi Salahudin', '0850578036', 'bancarnapitupulu@cv.net.id', 20, 'active'),
(21, 'Titin Prasetyo, S.Psi', '(040) 144 7524', 'garan88@yahoo.com', 21, 'active'),
(22, 'Ilsa Susanti', '0808697470', 'umarbun@cv.biz.id', 22, 'active'),
(23, 'Humaira Utama', '(0924) 737-4812', 'zulkarnaingalur@gmail.com', 23, 'active'),
(24, 'Dr. Rangga Widiastuti, S.Farm', '089 322 5015', 'dlatupono@cv.sch.id', 24, 'active'),
(25, 'Dinda Mayasari', '(0424) 492 0184', 'nyomanhidayat@gmail.com', 25, 'active'),
(26, 'Warji Tamba', '(052) 332 2861', 'vanyasimbolon@cv.my.id', 26, 'active'),
(27, 'Cinta Prakasa', '(010) 527 7548', 'ajeng28@ud.or.id', 27, 'active'),
(28, 'Bahuraksa Hutasoit, M.Farm', '(0270) 836 8998', 'pranatanasyidah@gmail.com', 28, 'active'),
(29, 'Jayadi Suryatmi', '+62 (006) 418 0710', 'wasitaviman@ud.my.id', 29, 'active'),
(30, 'T. Laswi Haryanto', '+62-0380-936-5952', 'gabriella88@pt.net.id', 30, 'active'),
(31, 'Intan Ardianto', '+62-0730-666-8948', 'wzulkarnain@yahoo.com', 31, 'active'),
(32, 'drg. Almira Simbolon', '+62 (314) 313-5330', 'gandiagustina@gmail.com', 32, 'active'),
(33, 'Wardaya Safitri', '+62-110-433-4894', 'ayunajmudin@hotmail.com', 33, 'active'),
(34, 'drg. Ciaobella Yuliarti, M.M.', '+62 (90) 122 9095', 'usamahganjaran@yahoo.com', 34, 'active'),
(35, 'Ir. Puput Nainggolan', '+62 (31) 286-4791', 'puspautama@pd.mil', 35, 'active'),
(36, 'Nabila Rajata', '(0259) 881 8077', 'mayasaripangeran@gmail.com', 36, 'active'),
(37, 'Lanang Iswahyudi', '0820577650', 'eadriansyah@yahoo.com', 37, 'active'),
(38, 'Dwi Maulana', '+62 (001) 436 1260', 'marbunbancar@cv.int', 38, 'active'),
(39, 'Mulyono Suryono', '+62 (0180) 437-6009', 'sfujiati@hotmail.com', 39, 'active'),
(40, 'R. Hartaka Wastuti', '+62-735-516-1729', 'wmansur@pd.int', 40, 'active'),
(41, 'dr. Ganjaran Mahendra', '(0248) 605 4248', 'kusumoheru@gmail.com', 41, 'active'),
(42, 'Jaka Widiastuti', '(0103) 419-0384', 'prakasacinthia@cv.mil.id', 42, 'active'),
(43, 'Harjo Firmansyah', '+62 (0648) 996-6498', 'kriyanti@pt.net.id', 43, 'active'),
(44, 'Zulaikha Mangunsong', '+62 (25) 005-6953', 'calistasimanjuntak@ud.id', 44, 'active'),
(45, 'Baktiadi Kuswoyo', '(079) 347-6464', 'suryonokariman@hotmail.com', 45, 'active'),
(46, 'Muni Wijayanti, S.Farm', '089 128 0057', 'bmangunsong@pd.sch.id', 46, 'active'),
(47, 'Emong Hutasoit', '+62-675-528-8437', 'nugrohomartana@yahoo.com', 47, 'active'),
(48, 'Ir. Rahmi Wahyudin', '+62 (0384) 788 0416', 'znarpati@hotmail.com', 48, 'active'),
(49, 'Dacin Hutagalung', '(0755) 951 9571', 'asmankuswandari@yahoo.com', 49, 'active'),
(50, 'Bakda Marpaung', '0898652078', 'permadijail@pt.net', 50, 'active'),
(51, 'KH. Reza Mahendra, S.Ked', '+62 (04) 183 4471', 'hidayantocinta@hotmail.com', 51, 'active'),
(52, 'Maida Damanik', '+62 (0687) 486 7755', 'dalionoaryani@yahoo.com', 52, 'active'),
(53, 'drg. Hartana Setiawan, S.Ked', '+62-0089-998-7514', 'fujiatikani@hotmail.com', 53, 'active'),
(54, 'R. Harsaya Wahyuni', '(0782) 169-9619', 'winarnolatif@gmail.com', 54, 'active'),
(55, 'Kartika Salahudin', '+62-769-726-0654', 'emaspudjiastuti@gmail.com', 55, 'active'),
(56, 'Carla Habibi', '+62-211-056-8788', 'usaragih@cv.int', 56, 'active'),
(57, 'Jane Yulianti, S.Farm', '(099) 432 8303', 'anggriawancaturangga@hotmail.com', 57, 'active'),
(58, 'Drs. Jane Sihombing, S.Pt', '085 896 9504', 'lulutprastuti@gmail.com', 58, 'active'),
(59, 'Drs. Gambira Lazuardi', '(0961) 752 2325', 'gsihombing@cv.ac.id', 59, 'active'),
(60, 'Pangeran Uyainah', '+62 (60) 508 2723', 'mfirmansyah@cv.my.id', 60, 'active'),
(61, 'Cemeti Tarihoran', '+62-519-726-6485', 'lurhurdongoran@pt.edu', 61, 'active'),
(62, 'Violet Najmudin', '+62 (0153) 890-9036', 'mansurniyaga@perum.ac.id', 62, 'active'),
(63, 'Amelia Pranowo, S.Kom', '+62 (020) 466 8394', 'hastutiikhsan@hotmail.com', 63, 'active'),
(64, 'Hasim Nasyidah', '+62-73-905-3538', 'jagawibisono@hotmail.com', 64, 'active'),
(65, 'dr. Azalea Nurdiyanti', '+62 (088) 273-7119', 'putranarji@yahoo.com', 65, 'active'),
(66, 'Sutan Ismail Winarsih, S.I.Kom', '+62 (037) 477 1264', 'claradongoran@gmail.com', 66, 'active'),
(67, 'Ulva Saptono, S.T.', '+62-0679-194-1260', 'bahuwarnanatsir@ud.my.id', 67, 'active'),
(68, 'Banara Tamba, M.Pd', '+62 (263) 606-9295', 'whariyah@gmail.com', 68, 'active'),
(69, 'Zizi Namaga, S.IP', '+62-94-233-1012', 'farhunnisa74@pt.ponpes.id', 69, 'active'),
(70, 'Lembah Sihotang', '+62-0103-555-7562', 'nashiruddinhardi@hotmail.com', 70, 'active'),
(71, 'Kenes Permata', '+62 (776) 736-6296', 'puspitajaya@perum.net', 71, 'active'),
(72, 'Tgk. Emong Oktaviani', '(092) 092-6749', 'maryadidartono@yahoo.com', 72, 'active'),
(73, 'Akarsana Manullang', '+62-005-269-4171', 'vhariyah@pt.web.id', 73, 'active'),
(74, 'Ratih Hidayanto', '086 507 1911', 'siregarhilda@hotmail.com', 74, 'active'),
(75, 'Siska Hardiansyah', '+62 (46) 952-9306', 'xhandayani@ud.mil.id', 75, 'active'),
(76, 'Asirwanda Winarno, S.H.', '+62 (099) 000-4118', 'habibibahuwarna@pt.mil.id', 76, 'active'),
(77, 'Calista Suryono', '+62-033-466-6674', 'lprasasta@ud.net.id', 77, 'active'),
(78, 'Kamidin Halim', '+62 (018) 890-3282', 'dewihassanah@pt.sch.id', 78, 'active'),
(79, 'Reksa Zulkarnain', '(0898) 383 9092', 'adriansyahcemplunk@yahoo.com', 79, 'active'),
(80, 'Eko Mandala, M.Ak', '+62 (0463) 395 5295', 'damanikkanda@pt.co.id', 80, 'active'),
(81, 'Cici Sihotang', '(0011) 739 7101', 'atma53@pd.gov', 81, 'active'),
(82, 'Paris Wibisono', '+62 (071) 287 0393', 'cahya27@ud.id', 82, 'active'),
(83, 'Asirwada Agustina', '+62 (83) 475 0849', 'apermata@pt.co.id', 83, 'active'),
(84, 'Nabila Damanik', '+62 (029) 487-4707', 'oliva75@ud.sch.id', 84, 'active'),
(85, 'R. Anastasia Saptono', '+62 (019) 278 6742', 'mursininfirmansyah@cv.gov', 85, 'active'),
(86, 'Zulfa Rahmawati', '+62-071-136-4350', 'rjanuar@cv.org', 86, 'active'),
(87, 'Labuh Budiman, S.Ked', '+62 (45) 375-7475', 'hanasimanjuntak@cv.my.id', 87, 'active'),
(88, 'Gangsa Utami', '+62-036-293-9393', 'yyuniar@gmail.com', 88, 'active'),
(89, 'Drs. Jane Riyanti', '(0234) 084-3611', 'pranowoicha@pd.mil', 89, 'active'),
(90, 'Agnes Pradana', '(0482) 906-0148', 'martanahastuti@yahoo.com', 90, 'active'),
(91, 'dr. Jarwa Sihombing', '+62 (30) 751-9181', 'faridatantri@gmail.com', 91, 'active'),
(92, 'Arta Hidayat, S.Kom', '+62 (0428) 975-8982', 'olgakurniawan@ud.net', 92, 'active'),
(93, 'Caturangga Suryono, M.Ak', '+62 (472) 829-8018', 'nnapitupulu@ud.int', 93, 'active'),
(94, 'Almira Halim', '+62 (0178) 629-4096', 'asmianto87@hotmail.com', 94, 'active'),
(95, 'Nyana Kusmawati, S.Kom', '0810175726', 'badriansyah@perum.org', 95, 'active'),
(96, 'Karya Nasyidah, S.Ked', '+62-555-361-1129', 'ismailwidiastuti@perum.web.id', 96, 'active'),
(97, 'Ani Mulyani', '+62 (037) 022-1028', 'balijan32@hotmail.com', 97, 'active'),
(98, 'Dadi Hastuti', '+62-0473-020-7394', 'wiboworaden@hotmail.com', 98, 'active'),
(99, 'Ade Kurniawan', '(0252) 855-1936', 'eagustina@ud.mil.id', 99, 'active'),
(100, 'Tgk. Imam Sirait', '(047) 659-0281', 'wahyunicakrawangsa@pd.mil.id', 100, 'active');

-- --------------------------------------------------------

--
-- Table structure for table `pic_details`
--

CREATE TABLE `pic_details` (
  `pic_detail_id` int(11) NOT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `pic_id` int(11) DEFAULT NULL,
  `assigned_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pic_details`
--

INSERT INTO `pic_details` (`pic_detail_id`, `campaign_id`, `pic_id`, `assigned_date`) VALUES
(1, 67, 1, '2025-06-08'),
(2, 47, 2, '2025-03-12'),
(3, 80, 3, '2025-02-15'),
(4, 97, 4, '2025-05-31'),
(5, 64, 5, '2025-03-07'),
(6, 81, 6, '2025-03-01'),
(7, 57, 7, '2025-02-19'),
(8, 98, 8, '2025-06-01'),
(9, 7, 9, '2025-01-01'),
(10, 27, 10, '2025-02-27'),
(11, 35, 11, '2025-04-24'),
(12, 71, 12, '2025-02-28'),
(13, 17, 13, '2025-03-06'),
(14, 37, 14, '2025-02-17'),
(15, 57, 15, '2025-01-03'),
(16, 90, 16, '2025-05-09'),
(17, 63, 17, '2025-03-04'),
(18, 16, 18, '2025-03-18'),
(19, 4, 19, '2025-04-01'),
(20, 81, 20, '2025-01-03'),
(21, 78, 21, '2025-02-09'),
(22, 31, 22, '2025-02-25'),
(23, 91, 23, '2025-01-24'),
(24, 21, 24, '2025-03-18'),
(25, 40, 25, '2025-03-16'),
(26, 71, 26, '2025-05-24'),
(27, 2, 27, '2025-05-08'),
(28, 71, 28, '2025-03-12'),
(29, 53, 29, '2025-03-20'),
(30, 12, 30, '2025-05-13'),
(31, 29, 31, '2025-05-04'),
(32, 15, 32, '2025-05-26'),
(33, 60, 33, '2025-05-05'),
(34, 16, 34, '2025-01-01'),
(35, 83, 35, '2025-01-09'),
(36, 20, 36, '2025-01-02'),
(37, 64, 37, '2025-03-20'),
(38, 92, 38, '2025-01-09'),
(39, 38, 39, '2025-05-31'),
(40, 66, 40, '2025-02-08'),
(41, 91, 41, '2025-04-04'),
(42, 35, 42, '2025-05-24'),
(43, 54, 43, '2025-05-06'),
(44, 62, 44, '2025-01-08'),
(45, 61, 45, '2025-01-18'),
(46, 32, 46, '2025-04-20'),
(47, 59, 47, '2025-05-10'),
(48, 71, 48, '2025-04-15'),
(49, 19, 49, '2025-01-25'),
(50, 50, 50, '2025-03-29'),
(51, 25, 51, '2025-01-07'),
(52, 77, 52, '2025-04-21'),
(53, 66, 53, '2025-01-17'),
(54, 96, 54, '2025-05-21'),
(55, 18, 55, '2025-01-10'),
(56, 9, 56, '2025-05-23'),
(57, 36, 57, '2025-06-09'),
(58, 99, 58, '2025-03-13'),
(59, 54, 59, '2025-02-26'),
(60, 44, 60, '2025-01-31'),
(61, 65, 61, '2025-04-11'),
(62, 35, 62, '2025-04-09'),
(63, 1, 63, '2025-06-08'),
(64, 37, 64, '2025-06-08'),
(65, 93, 65, '2025-05-22'),
(66, 39, 66, '2025-05-23'),
(67, 76, 67, '2025-01-30'),
(68, 75, 68, '2025-02-19'),
(69, 85, 69, '2025-01-08'),
(70, 63, 70, '2025-05-11'),
(71, 20, 71, '2025-01-14'),
(72, 58, 72, '2025-05-20'),
(73, 69, 73, '2025-01-04'),
(74, 62, 74, '2025-01-13'),
(75, 45, 75, '2025-01-10'),
(76, 43, 76, '2025-04-22'),
(77, 71, 77, '2025-04-12'),
(78, 98, 78, '2025-03-03'),
(79, 70, 79, '2025-03-09'),
(80, 49, 80, '2025-05-26'),
(81, 59, 81, '2025-03-21'),
(82, 42, 82, '2025-01-20'),
(83, 25, 83, '2025-03-28'),
(84, 90, 84, '2025-05-14'),
(85, 31, 85, '2025-01-25'),
(86, 74, 86, '2025-03-22'),
(87, 50, 87, '2025-05-13'),
(88, 30, 88, '2025-04-18'),
(89, 100, 89, '2025-05-18'),
(90, 53, 90, '2025-02-17'),
(91, 6, 91, '2025-04-24'),
(92, 41, 92, '2025-04-16'),
(93, 96, 93, '2025-05-14'),
(94, 61, 94, '2025-01-04'),
(95, 91, 95, '2025-01-23'),
(96, 49, 96, '2025-04-26'),
(97, 50, 97, '2025-05-30'),
(98, 85, 98, '2025-04-20'),
(99, 84, 99, '2025-02-06'),
(100, 20, 100, '2025-02-24');

-- --------------------------------------------------------

--
-- Table structure for table `recyclebin`
--

CREATE TABLE `recyclebin` (
  `bin_id` int(11) NOT NULL,
  `location_id` int(11) DEFAULT NULL,
  `bin_type` varchar(50) DEFAULT NULL,
  `capacity_kg` decimal(5,2) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recyclebin`
--

INSERT INTO `recyclebin` (`bin_id`, `location_id`, `bin_type`, `capacity_kg`, `status`) VALUES
(1, 1, 'Plastic', 9.95, 'active'),
(2, 2, 'Plastic', 10.93, 'active'),
(3, 3, 'Paper', 40.55, 'active'),
(4, 4, 'Plastic', 31.50, 'active'),
(5, 5, 'Plastic', 12.84, 'active'),
(6, 6, 'Plastic', 10.70, 'active'),
(7, 7, 'Paper', 28.67, 'active'),
(8, 8, 'Metal', 7.86, 'active'),
(9, 9, 'Paper', 40.01, 'active'),
(10, 10, 'Metal', 31.71, 'active'),
(11, 11, 'Paper', 27.67, 'active'),
(12, 12, 'Metal', 6.95, 'active'),
(13, 13, 'Metal', 28.47, 'active'),
(14, 14, 'Paper', 33.95, 'active'),
(15, 15, 'Plastic', 7.74, 'active'),
(16, 16, 'Paper', 43.13, 'active'),
(17, 17, 'Paper', 35.87, 'active'),
(18, 18, 'Paper', 37.06, 'active'),
(19, 19, 'Paper', 8.31, 'active'),
(20, 20, 'Plastic', 19.50, 'active'),
(21, 21, 'Plastic', 7.96, 'active'),
(22, 22, 'Paper', 33.09, 'active'),
(23, 23, 'Metal', 29.68, 'active'),
(24, 24, 'Paper', 22.14, 'active'),
(25, 25, 'Metal', 28.88, 'active'),
(26, 26, 'Paper', 27.75, 'active'),
(27, 27, 'Paper', 9.46, 'active'),
(28, 28, 'Metal', 10.15, 'active'),
(29, 29, 'Metal', 34.29, 'active'),
(30, 30, 'Metal', 37.44, 'active'),
(31, 31, 'Plastic', 24.35, 'active'),
(32, 32, 'Plastic', 23.62, 'active'),
(33, 33, 'Paper', 22.94, 'active'),
(34, 34, 'Metal', 9.28, 'active'),
(35, 35, 'Paper', 19.06, 'active'),
(36, 36, 'Paper', 21.84, 'active'),
(37, 37, 'Plastic', 35.91, 'active'),
(38, 38, 'Paper', 8.02, 'active'),
(39, 39, 'Plastic', 9.20, 'active'),
(40, 40, 'Plastic', 38.51, 'active'),
(41, 41, 'Paper', 41.53, 'active'),
(42, 42, 'Metal', 7.70, 'active'),
(43, 43, 'Metal', 30.28, 'active'),
(44, 44, 'Metal', 10.50, 'active'),
(45, 45, 'Paper', 44.31, 'active'),
(46, 46, 'Paper', 44.06, 'active'),
(47, 47, 'Metal', 7.32, 'active'),
(48, 48, 'Paper', 32.02, 'active'),
(49, 49, 'Paper', 9.66, 'active'),
(50, 50, 'Metal', 14.57, 'active'),
(51, 51, 'Metal', 26.70, 'active'),
(52, 52, 'Plastic', 20.76, 'active'),
(53, 53, 'Metal', 21.54, 'active'),
(54, 54, 'Paper', 30.83, 'active'),
(55, 55, 'Paper', 43.03, 'active'),
(56, 56, 'Metal', 32.61, 'active'),
(57, 57, 'Metal', 30.05, 'active'),
(58, 58, 'Metal', 46.81, 'active'),
(59, 59, 'Metal', 17.04, 'active'),
(60, 60, 'Plastic', 17.30, 'active'),
(61, 61, 'Paper', 46.47, 'active'),
(62, 62, 'Paper', 5.27, 'active'),
(63, 63, 'Plastic', 30.48, 'active'),
(64, 64, 'Paper', 8.13, 'active'),
(65, 65, 'Metal', 33.49, 'active'),
(66, 66, 'Plastic', 9.13, 'active'),
(67, 67, 'Metal', 14.68, 'active'),
(68, 68, 'Paper', 25.41, 'active'),
(69, 69, 'Plastic', 21.65, 'active'),
(70, 70, 'Metal', 19.60, 'active'),
(71, 71, 'Metal', 31.83, 'active'),
(72, 72, 'Plastic', 12.00, 'active'),
(73, 73, 'Metal', 7.24, 'active'),
(74, 74, 'Plastic', 17.24, 'active'),
(75, 75, 'Metal', 24.08, 'active'),
(76, 76, 'Metal', 24.89, 'active'),
(77, 77, 'Paper', 14.70, 'active'),
(78, 78, 'Metal', 10.12, 'active'),
(79, 79, 'Paper', 9.99, 'active'),
(80, 80, 'Metal', 35.53, 'active'),
(81, 81, 'Paper', 28.71, 'active'),
(82, 82, 'Paper', 7.04, 'active'),
(83, 83, 'Paper', 49.30, 'active'),
(84, 84, 'Plastic', 5.35, 'active'),
(85, 85, 'Paper', 47.54, 'active'),
(86, 86, 'Plastic', 39.39, 'active'),
(87, 87, 'Paper', 19.77, 'active'),
(88, 88, 'Plastic', 27.38, 'active'),
(89, 89, 'Paper', 12.91, 'active'),
(90, 90, 'Paper', 28.97, 'active'),
(91, 91, 'Plastic', 27.51, 'active'),
(92, 92, 'Metal', 41.28, 'active'),
(93, 93, 'Plastic', 22.87, 'active'),
(94, 94, 'Metal', 6.90, 'active'),
(95, 95, 'Plastic', 25.69, 'active'),
(96, 96, 'Plastic', 43.79, 'active'),
(97, 97, 'Metal', 24.32, 'active'),
(98, 98, 'Paper', 36.93, 'active'),
(99, 99, 'Paper', 18.03, 'active'),
(100, 100, 'Paper', 5.94, 'active');

-- --------------------------------------------------------

--
-- Table structure for table `recyclingactivity`
--

CREATE TABLE `recyclingactivity` (
  `activity_id` int(11) NOT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `recycling_type_id` int(11) DEFAULT NULL,
  `weight_kg` decimal(5,2) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recyclingactivity`
--

INSERT INTO `recyclingactivity` (`activity_id`, `campaign_id`, `user_id`, `recycling_type_id`, `weight_kg`, `date`, `verified_by`, `status`) VALUES
(1, 42, 22, 5, 4.87, '2025-04-01', 89, 'verified'),
(2, 47, 12, 4, 8.52, '2025-04-12', 32, 'verified'),
(3, 56, 76, 4, 5.48, '2025-01-07', 51, 'verified'),
(4, 40, 96, 3, 2.60, '2025-03-21', 100, 'verified'),
(5, 22, 10, 5, 6.52, '2025-03-29', 68, 'verified'),
(6, 66, 25, 3, 3.84, '2025-04-14', 83, 'verified'),
(7, 19, 31, 1, 1.89, '2025-02-19', 26, 'verified'),
(8, 23, 78, 2, 7.72, '2025-05-26', 84, 'verified'),
(9, 10, 23, 4, 4.91, '2025-01-28', 73, 'verified'),
(10, 98, 75, 4, 6.97, '2025-04-20', 73, 'verified'),
(11, 83, 82, 5, 3.57, '2025-04-25', 81, 'verified'),
(12, 41, 20, 4, 1.15, '2025-04-19', 57, 'verified'),
(13, 81, 39, 3, 6.12, '2025-04-01', 46, 'verified'),
(14, 65, 10, 3, 4.89, '2025-05-24', 5, 'verified'),
(15, 8, 48, 3, 1.23, '2025-03-04', 12, 'verified'),
(16, 79, 77, 5, 4.15, '2025-05-14', 75, 'verified'),
(17, 71, 95, 1, 4.77, '2025-03-01', 74, 'verified'),
(18, 84, 25, 3, 6.25, '2025-01-14', 65, 'verified'),
(19, 20, 8, 4, 1.48, '2025-06-03', 44, 'verified'),
(20, 92, 11, 5, 6.64, '2025-02-01', 6, 'verified'),
(21, 32, 91, 4, 9.91, '2025-03-12', 68, 'verified'),
(22, 67, 79, 2, 3.96, '2025-01-28', 37, 'verified'),
(23, 50, 53, 3, 6.95, '2025-05-25', 7, 'verified'),
(24, 81, 83, 3, 1.13, '2025-01-10', 13, 'verified'),
(25, 72, 87, 4, 3.20, '2025-03-28', 93, 'verified'),
(26, 85, 78, 2, 3.67, '2025-04-20', 75, 'verified'),
(27, 85, 19, 3, 3.45, '2025-03-29', 84, 'verified'),
(28, 90, 85, 4, 1.73, '2025-01-28', 91, 'verified'),
(29, 11, 40, 5, 4.08, '2025-01-03', 43, 'verified'),
(30, 17, 86, 5, 1.39, '2025-05-23', 86, 'verified'),
(31, 55, 66, 3, 0.67, '2025-03-25', 40, 'verified'),
(32, 24, 28, 3, 9.50, '2025-02-01', 63, 'verified'),
(33, 25, 29, 2, 1.97, '2025-05-22', 38, 'verified'),
(34, 13, 65, 5, 8.43, '2025-06-07', 68, 'verified'),
(35, 5, 85, 3, 8.83, '2025-02-02', 80, 'verified'),
(36, 17, 77, 4, 1.97, '2025-05-20', 24, 'verified'),
(37, 89, 99, 5, 8.19, '2025-06-06', 22, 'verified'),
(38, 93, 57, 1, 4.40, '2025-04-13', 87, 'verified'),
(39, 93, 31, 4, 6.30, '2025-02-18', 97, 'verified'),
(40, 96, 58, 2, 5.57, '2025-04-14', 40, 'verified'),
(41, 61, 25, 3, 6.94, '2025-02-09', 74, 'verified'),
(42, 57, 60, 3, 7.89, '2025-02-07', 65, 'verified'),
(43, 68, 54, 2, 8.26, '2025-02-19', 78, 'verified'),
(44, 18, 33, 1, 6.59, '2025-03-21', 48, 'verified'),
(45, 71, 14, 5, 8.59, '2025-05-30', 37, 'verified'),
(46, 11, 98, 2, 3.09, '2025-06-06', 66, 'verified'),
(47, 19, 56, 1, 9.49, '2025-06-03', 29, 'verified'),
(48, 58, 45, 1, 4.44, '2025-01-25', 51, 'verified'),
(49, 65, 48, 2, 4.17, '2025-04-07', 11, 'verified'),
(50, 48, 29, 1, 3.53, '2025-05-09', 13, 'verified'),
(51, 92, 84, 3, 8.02, '2025-02-28', 18, 'verified'),
(52, 5, 37, 4, 7.11, '2025-01-10', 18, 'verified'),
(53, 98, 91, 4, 4.76, '2025-04-20', 1, 'verified'),
(54, 11, 3, 3, 2.55, '2025-01-01', 20, 'verified'),
(55, 71, 94, 5, 5.51, '2025-04-08', 15, 'verified'),
(56, 100, 37, 2, 3.36, '2025-01-26', 7, 'verified'),
(57, 31, 54, 5, 4.84, '2025-01-11', 15, 'verified'),
(58, 64, 77, 5, 0.66, '2025-01-23', 66, 'verified'),
(59, 74, 31, 2, 3.27, '2025-01-17', 1, 'verified'),
(60, 79, 46, 2, 5.92, '2025-04-10', 24, 'verified'),
(61, 86, 86, 1, 5.47, '2025-01-27', 47, 'verified'),
(62, 9, 68, 5, 5.32, '2025-06-01', 65, 'verified'),
(63, 71, 3, 4, 8.80, '2025-05-04', 6, 'verified'),
(64, 82, 50, 3, 2.91, '2025-01-30', 3, 'verified'),
(65, 46, 9, 3, 2.79, '2025-05-08', 85, 'verified'),
(66, 81, 14, 5, 7.48, '2025-05-12', 43, 'verified'),
(67, 18, 6, 3, 5.69, '2025-02-24', 83, 'verified'),
(68, 23, 100, 4, 9.82, '2025-02-02', 62, 'verified'),
(69, 81, 24, 2, 1.10, '2025-05-11', 100, 'verified'),
(70, 59, 5, 3, 2.42, '2025-02-08', 26, 'verified'),
(71, 6, 41, 3, 5.40, '2025-04-12', 70, 'verified'),
(72, 61, 33, 1, 7.66, '2025-03-28', 25, 'verified'),
(73, 37, 46, 1, 8.73, '2025-04-12', 43, 'verified'),
(74, 35, 16, 3, 4.65, '2025-02-13', 52, 'verified'),
(75, 96, 57, 4, 3.72, '2025-02-20', 24, 'verified'),
(76, 64, 89, 4, 3.99, '2025-05-03', 67, 'verified'),
(77, 35, 11, 4, 1.25, '2025-05-26', 78, 'verified'),
(78, 24, 70, 3, 3.55, '2025-05-17', 11, 'verified'),
(79, 42, 85, 3, 3.41, '2025-04-14', 78, 'verified'),
(80, 92, 55, 2, 7.05, '2025-03-11', 45, 'verified'),
(81, 58, 6, 3, 6.34, '2025-04-05', 56, 'verified'),
(82, 36, 82, 1, 1.21, '2025-06-08', 82, 'verified'),
(83, 52, 47, 5, 8.11, '2025-05-09', 87, 'verified'),
(84, 21, 4, 2, 8.56, '2025-04-12', 87, 'verified'),
(85, 57, 5, 2, 1.14, '2025-06-02', 100, 'verified'),
(86, 83, 47, 3, 4.14, '2025-04-29', 73, 'verified'),
(87, 5, 78, 2, 6.95, '2025-01-08', 48, 'verified'),
(88, 48, 57, 1, 5.95, '2025-05-27', 68, 'verified'),
(89, 47, 51, 3, 6.67, '2025-02-16', 32, 'verified'),
(90, 15, 4, 2, 5.24, '2025-04-05', 50, 'verified'),
(91, 72, 16, 3, 7.86, '2025-01-10', 91, 'verified'),
(92, 58, 28, 5, 3.21, '2025-05-08', 63, 'verified'),
(93, 26, 16, 2, 8.60, '2025-01-21', 58, 'verified'),
(94, 23, 92, 4, 9.97, '2025-03-07', 88, 'verified'),
(95, 41, 86, 3, 7.24, '2025-01-14', 71, 'verified'),
(96, 70, 38, 3, 8.59, '2025-01-08', 92, 'verified'),
(97, 91, 90, 2, 8.04, '2025-05-20', 66, 'verified'),
(98, 29, 16, 2, 8.02, '2025-03-26', 31, 'verified'),
(99, 64, 4, 3, 5.76, '2025-05-03', 48, 'verified'),
(100, 60, 71, 2, 6.31, '2025-06-05', 12, 'verified');

--
-- Triggers `recyclingactivity`
--
DELIMITER $$
CREATE TRIGGER `trg_auto_set_student_active_on_activity` AFTER INSERT ON `recyclingactivity` FOR EACH ROW BEGIN
    IF NEW.status = 'verified' THEN
        UPDATE STUDENT
        SET status = 'active'
        WHERE stud_id = NEW.user_id;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_verifikasi_aktivitas_to_poin` AFTER UPDATE ON `recyclingactivity` FOR EACH ROW BEGIN
    DECLARE v_poin INT;


    IF OLD.status != 'verified' AND NEW.status = 'verified' THEN
        SET v_poin = fn_konversi_berat_ke_poin(NEW.weight_kg);


        INSERT INTO BYN(user_id, campaign_id, point_amount, timestamp)
        VALUES (NEW.user_id, NULL, v_poin, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `rewardredemption`
--

CREATE TABLE `rewardredemption` (
  `redemption_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `reward_id` int(11) DEFAULT NULL,
  `redeemed_at` datetime DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rewardredemption`
--

INSERT INTO `rewardredemption` (`redemption_id`, `user_id`, `reward_id`, `redeemed_at`, `status`) VALUES
(1, 88, 79, '2025-04-14 08:35:06', 'redeemed'),
(2, 16, 17, '2025-04-30 16:11:22', 'redeemed'),
(3, 13, 51, '2025-04-01 05:58:01', 'redeemed'),
(4, 48, 44, '2025-05-24 01:05:51', 'redeemed'),
(5, 72, 47, '2025-05-20 13:14:15', 'redeemed'),
(6, 97, 19, '2025-06-01 10:03:06', 'redeemed'),
(7, 26, 78, '2025-05-10 13:17:55', 'redeemed'),
(8, 66, 52, '2025-05-25 20:06:21', 'redeemed'),
(9, 65, 6, '2025-06-05 21:16:58', 'redeemed'),
(10, 6, 5, '2025-02-02 13:11:59', 'redeemed'),
(11, 18, 92, '2025-05-30 09:56:27', 'redeemed'),
(12, 43, 61, '2025-01-31 02:46:45', 'redeemed'),
(13, 67, 59, '2025-01-02 06:04:37', 'redeemed'),
(14, 20, 78, '2025-02-08 13:45:25', 'redeemed'),
(15, 66, 18, '2025-05-28 01:06:12', 'redeemed'),
(16, 42, 79, '2025-02-16 19:42:12', 'redeemed'),
(17, 41, 21, '2025-01-26 10:06:52', 'redeemed'),
(18, 51, 79, '2025-04-19 18:46:06', 'redeemed'),
(19, 95, 39, '2025-05-28 11:35:57', 'redeemed'),
(20, 76, 44, '2025-04-08 07:17:37', 'redeemed'),
(21, 65, 66, '2025-03-02 02:43:23', 'redeemed'),
(22, 69, 63, '2025-05-12 01:32:12', 'redeemed'),
(23, 91, 73, '2025-01-09 04:24:15', 'redeemed'),
(24, 39, 61, '2025-05-31 21:28:36', 'redeemed'),
(25, 3, 48, '2025-04-25 22:16:30', 'redeemed'),
(26, 43, 87, '2025-03-14 00:00:28', 'redeemed'),
(27, 15, 54, '2025-05-29 13:15:42', 'redeemed'),
(28, 75, 40, '2025-01-17 04:54:23', 'redeemed'),
(29, 93, 89, '2025-02-13 19:27:31', 'redeemed'),
(30, 81, 4, '2025-04-21 01:39:03', 'redeemed'),
(31, 77, 61, '2025-03-05 07:07:28', 'redeemed'),
(32, 34, 84, '2025-03-30 17:44:45', 'redeemed'),
(33, 100, 75, '2025-05-26 06:28:29', 'redeemed'),
(34, 74, 30, '2025-04-19 09:28:22', 'redeemed'),
(35, 93, 7, '2025-01-31 13:07:14', 'redeemed'),
(36, 75, 62, '2025-06-02 21:54:43', 'redeemed'),
(37, 22, 68, '2025-05-11 04:26:03', 'redeemed'),
(38, 81, 93, '2025-03-11 01:26:49', 'redeemed'),
(39, 80, 100, '2025-04-14 15:03:08', 'redeemed'),
(40, 49, 19, '2025-01-28 01:43:13', 'redeemed'),
(41, 88, 32, '2025-01-01 01:03:41', 'redeemed'),
(42, 5, 74, '2025-02-17 09:23:30', 'redeemed'),
(43, 90, 15, '2025-03-02 12:40:56', 'redeemed'),
(44, 25, 3, '2025-06-08 10:49:04', 'redeemed'),
(45, 57, 41, '2025-01-31 03:35:11', 'redeemed'),
(46, 54, 20, '2025-04-27 01:35:36', 'redeemed'),
(47, 53, 89, '2025-02-26 23:02:23', 'redeemed'),
(48, 27, 53, '2025-01-17 01:41:36', 'redeemed'),
(49, 65, 100, '2025-05-17 08:12:32', 'redeemed'),
(50, 79, 61, '2025-03-11 19:33:16', 'redeemed'),
(51, 95, 94, '2025-02-15 17:55:49', 'redeemed'),
(52, 8, 91, '2025-05-24 15:54:28', 'redeemed'),
(53, 18, 67, '2025-05-27 13:28:46', 'redeemed'),
(54, 27, 72, '2025-05-24 04:29:42', 'redeemed'),
(55, 42, 85, '2025-03-07 22:34:52', 'redeemed'),
(56, 62, 68, '2025-02-07 12:47:20', 'redeemed'),
(57, 49, 41, '2025-01-18 16:33:28', 'redeemed'),
(58, 23, 59, '2025-01-06 08:55:03', 'redeemed'),
(59, 69, 44, '2025-02-21 12:44:15', 'redeemed'),
(60, 70, 46, '2025-01-26 14:50:28', 'redeemed'),
(61, 87, 99, '2025-01-16 19:49:17', 'redeemed'),
(62, 93, 88, '2025-01-26 10:58:59', 'redeemed'),
(63, 83, 89, '2025-04-14 09:34:10', 'redeemed'),
(64, 34, 79, '2025-02-19 09:06:02', 'redeemed'),
(65, 62, 25, '2025-03-01 14:23:10', 'redeemed'),
(66, 32, 36, '2025-03-19 11:21:59', 'redeemed'),
(67, 72, 39, '2025-05-09 03:25:42', 'redeemed'),
(68, 29, 39, '2025-02-05 04:24:46', 'redeemed'),
(69, 99, 37, '2025-01-09 11:43:07', 'redeemed'),
(70, 91, 27, '2025-04-17 10:42:10', 'redeemed'),
(71, 89, 91, '2025-05-20 09:25:30', 'redeemed'),
(72, 63, 41, '2025-01-13 06:42:57', 'redeemed'),
(73, 62, 45, '2025-02-08 03:14:58', 'redeemed'),
(74, 72, 93, '2025-02-17 18:53:52', 'redeemed'),
(75, 36, 37, '2025-04-22 23:54:44', 'redeemed'),
(76, 16, 74, '2025-01-23 17:12:31', 'redeemed'),
(77, 87, 70, '2025-01-11 02:47:04', 'redeemed'),
(78, 49, 51, '2025-01-21 03:13:29', 'redeemed'),
(79, 45, 99, '2025-02-10 11:59:48', 'redeemed'),
(80, 19, 38, '2025-03-18 17:15:24', 'redeemed'),
(81, 6, 37, '2025-03-11 14:39:14', 'redeemed'),
(82, 92, 11, '2025-05-16 11:43:25', 'redeemed'),
(83, 45, 57, '2025-05-13 01:30:53', 'redeemed'),
(84, 84, 33, '2025-04-17 03:37:17', 'redeemed'),
(85, 96, 62, '2025-01-03 17:58:25', 'redeemed'),
(86, 28, 26, '2025-05-30 13:44:24', 'redeemed'),
(87, 69, 35, '2025-03-19 03:22:41', 'redeemed'),
(88, 72, 90, '2025-04-06 00:00:15', 'redeemed'),
(89, 35, 18, '2025-04-27 12:17:59', 'redeemed'),
(90, 14, 79, '2025-03-28 05:16:06', 'redeemed'),
(91, 95, 76, '2025-06-09 16:35:45', 'redeemed'),
(92, 31, 32, '2025-05-17 23:58:32', 'redeemed'),
(93, 7, 86, '2025-02-26 03:11:37', 'redeemed'),
(94, 68, 29, '2025-02-07 13:12:09', 'redeemed'),
(95, 82, 30, '2025-03-12 00:17:08', 'redeemed'),
(96, 7, 13, '2025-01-15 18:02:34', 'redeemed'),
(97, 53, 43, '2025-01-11 15:15:01', 'redeemed'),
(98, 92, 61, '2025-04-13 04:55:35', 'redeemed'),
(99, 13, 88, '2025-05-18 23:22:01', 'redeemed'),
(100, 99, 18, '2025-04-06 14:24:16', 'redeemed');

--
-- Triggers `rewardredemption`
--
DELIMITER $$
CREATE TRIGGER `trg_decrease_reward_stock_after_redemption` AFTER INSERT ON `rewardredemption` FOR EACH ROW BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE REWARD_ITEM
        SET stock = stock - 1
        WHERE id = NEW.reward_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reward_item`
--

CREATE TABLE `reward_item` (
  `reward_id` int(11) NOT NULL,
  `item_name` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `points_required` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `stock` int(11) DEFAULT 10
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reward_item`
--

INSERT INTO `reward_item` (`reward_id`, `item_name`, `description`, `points_required`, `status`, `stock`) VALUES
(1, 'Reward 1', 'Ab a exercitationem.', 154, 'active', 10),
(2, 'Reward 2', 'Magnam quaerat nobis ratione.', 224, 'active', 10),
(3, 'Reward 3', 'Reiciendis voluptates fuga.', 360, 'active', 10),
(4, 'Reward 4', 'Recusandae a ea saepe.', 123, 'active', 10),
(5, 'Reward 5', 'Occaecati amet soluta vero.', 210, 'active', 10),
(6, 'Reward 6', 'Non cum aliquid dolorum.', 491, 'active', 10),
(7, 'Reward 7', 'Ut placeat iste a.', 417, 'active', 10),
(8, 'Reward 8', 'Corrupti molestias libero in.', 213, 'active', 10),
(9, 'Reward 9', 'Nemo ipsum vel neque.', 425, 'active', 10),
(10, 'Reward 10', 'Vel odio eum voluptatem vel.', 490, 'active', 10),
(11, 'Reward 11', 'Ullam doloremque magni totam.', 226, 'active', 10),
(12, 'Reward 12', 'Mollitia iure in.', 254, 'active', 10),
(13, 'Reward 13', 'Tempore veniam eveniet ea.', 116, 'active', 10),
(14, 'Reward 14', 'Quam illum voluptatem quo.', 439, 'active', 10),
(15, 'Reward 15', 'Nobis quae modi fugit.', 239, 'active', 10),
(16, 'Reward 16', 'Esse atque quis.', 313, 'active', 10),
(17, 'Reward 17', 'Eaque ab quisquam eum hic.', 337, 'active', 10),
(18, 'Reward 18', 'Suscipit minima eius iste.', 104, 'active', 10),
(19, 'Reward 19', 'Quo id aut dolor adipisci.', 213, 'active', 10),
(20, 'Reward 20', 'Labore nesciunt iusto labore.', 173, 'active', 10),
(21, 'Reward 21', 'Ex enim incidunt minus.', 288, 'active', 10),
(22, 'Reward 22', 'Exercitationem officia sit.', 112, 'active', 10),
(23, 'Reward 23', 'Vero nemo doloribus a.', 186, 'active', 10),
(24, 'Reward 24', 'Delectus quasi explicabo est.', 280, 'active', 10),
(25, 'Reward 25', 'Commodi explicabo omnis ipsa.', 176, 'active', 10),
(26, 'Reward 26', 'Necessitatibus ducimus omnis.', 122, 'active', 10),
(27, 'Reward 27', 'Rem magni autem dignissimos.', 99, 'active', 10),
(28, 'Reward 28', 'Blanditiis illum qui.', 75, 'active', 10),
(29, 'Reward 29', 'Autem dolorum aut.', 198, 'active', 10),
(30, 'Reward 30', 'Ipsam iste rerum qui.', 246, 'active', 10),
(31, 'Reward 31', 'Officia autem fugiat id.', 492, 'active', 10),
(32, 'Reward 32', 'Deleniti in tempore a.', 365, 'active', 10),
(33, 'Reward 33', 'Nostrum laborum nostrum.', 264, 'active', 10),
(34, 'Reward 34', 'Illum nulla dolorem dolorum.', 177, 'active', 10),
(35, 'Reward 35', 'Dolorum neque laboriosam.', 493, 'active', 10),
(36, 'Reward 36', 'Inventore optio ullam nihil.', 131, 'active', 10),
(37, 'Reward 37', 'Assumenda quibusdam alias.', 466, 'active', 10),
(38, 'Reward 38', 'Magni quo illo nisi in porro.', 217, 'active', 10),
(39, 'Reward 39', 'Eligendi unde odit.', 345, 'active', 10),
(40, 'Reward 40', 'Culpa consequatur eum natus.', 419, 'active', 10),
(41, 'Reward 41', 'Laborum accusantium vitae.', 210, 'active', 10),
(42, 'Reward 42', 'Enim sequi magnam doloremque.', 147, 'active', 10),
(43, 'Reward 43', 'Quae animi quasi.', 440, 'active', 10),
(44, 'Reward 44', 'Qui aliquam eligendi dolores.', 131, 'active', 10),
(45, 'Reward 45', 'Necessitatibus expedita quo.', 305, 'active', 10),
(46, 'Reward 46', 'Quae tempora maxime minus.', 313, 'active', 10),
(47, 'Reward 47', 'Expedita nisi dolorum magni.', 289, 'active', 10),
(48, 'Reward 48', 'Veritatis ipsum sint.', 305, 'active', 10),
(49, 'Reward 49', 'Ullam praesentium ad commodi.', 500, 'active', 10),
(50, 'Reward 50', 'Esse ad nesciunt quod.', 207, 'active', 10),
(51, 'Reward 51', 'Quis velit ipsa numquam fuga.', 304, 'active', 10),
(52, 'Reward 52', 'Eum deserunt qui.', 61, 'active', 10),
(53, 'Reward 53', 'Sit aperiam iste.', 96, 'active', 10),
(54, 'Reward 54', 'A aut assumenda harum.', 251, 'active', 10),
(55, 'Reward 55', 'Ipsa nobis nulla dolorem.', 308, 'active', 10),
(56, 'Reward 56', 'At qui adipisci repudiandae.', 284, 'active', 10),
(57, 'Reward 57', 'Nihil nostrum sed sint.', 173, 'active', 10),
(58, 'Reward 58', 'Facere consequuntur autem.', 160, 'active', 10),
(59, 'Reward 59', 'Soluta maiores quis.', 348, 'active', 10),
(60, 'Reward 60', 'Illum ea qui nam.', 230, 'active', 10),
(61, 'Reward 61', 'Quaerat voluptatum repellat.', 74, 'active', 10),
(62, 'Reward 62', 'Porro dolorem maxime earum.', 75, 'active', 10),
(63, 'Reward 63', 'Dolor eum aliquid.', 194, 'active', 10),
(64, 'Reward 64', 'Incidunt impedit animi esse.', 303, 'active', 10),
(65, 'Reward 65', 'Veniam placeat fuga.', 355, 'active', 10),
(66, 'Reward 66', 'Dolorum explicabo ut quod.', 481, 'active', 10),
(67, 'Reward 67', 'Ex tempore delectus.', 384, 'active', 10),
(68, 'Reward 68', 'Occaecati nisi dicta eaque.', 394, 'active', 10),
(69, 'Reward 69', 'Quia quae omnis sequi.', 290, 'active', 10),
(70, 'Reward 70', 'Harum nesciunt rem.', 196, 'active', 10),
(71, 'Reward 71', 'Error atque consequuntur.', 324, 'active', 10),
(72, 'Reward 72', 'Labore odio nihil quas.', 54, 'active', 10),
(73, 'Reward 73', 'Odit dolorum totam ab.', 483, 'active', 10),
(74, 'Reward 74', 'Possimus fugiat odit non.', 105, 'active', 10),
(75, 'Reward 75', 'Fugit facilis voluptatum.', 270, 'active', 10),
(76, 'Reward 76', 'Officia odit omnis error.', 118, 'active', 10),
(77, 'Reward 77', 'At vero sit dicta nihil eius.', 185, 'active', 10),
(78, 'Reward 78', 'Fugit hic nostrum nisi quam.', 422, 'active', 10),
(79, 'Reward 79', 'Repellendus eos commodi.', 237, 'active', 10),
(80, 'Reward 80', 'Occaecati vel odit vitae eos.', 441, 'active', 10),
(81, 'Reward 81', 'Eaque alias provident sit.', 256, 'active', 10),
(82, 'Reward 82', 'Laudantium fugit est.', 237, 'active', 10),
(83, 'Reward 83', 'Est ullam nam eligendi magni.', 73, 'active', 10),
(84, 'Reward 84', 'Officia cum non debitis.', 255, 'active', 10),
(85, 'Reward 85', 'Non nisi nesciunt suscipit.', 76, 'active', 10),
(86, 'Reward 86', 'Vitae quis nemo amet.', 341, 'active', 10),
(87, 'Reward 87', 'Nulla magnam suscipit.', 337, 'active', 10),
(88, 'Reward 88', 'Pariatur blanditiis saepe.', 149, 'active', 10),
(89, 'Reward 89', 'Cupiditate culpa ea corporis.', 235, 'active', 10),
(90, 'Reward 90', 'Aperiam odio amet blanditiis.', 333, 'active', 10),
(91, 'Reward 91', 'Fuga nisi doloribus non.', 197, 'active', 10),
(92, 'Reward 92', 'Est ad deleniti quae.', 87, 'active', 10),
(93, 'Reward 93', 'Autem error earum eius.', 247, 'active', 10),
(94, 'Reward 94', 'Ea iste accusantium possimus.', 308, 'active', 10),
(95, 'Reward 95', 'Nemo tempore libero optio.', 280, 'active', 10),
(96, 'Reward 96', 'Dicta ipsum natus.', 441, 'active', 10),
(97, 'Reward 97', 'Odio esse saepe.', 331, 'active', 10),
(98, 'Reward 98', 'Quis eum mollitia dolore.', 193, 'active', 10),
(99, 'Reward 99', 'Eaque molestiae temporibus.', 472, 'active', 10),
(100, 'Reward 100', 'Officia distinctio rem.', 369, 'active', 10);

--
-- Triggers `reward_item`
--
DELIMITER $$
CREATE TRIGGER `trg_status_reward_out_of_stock` AFTER UPDATE ON `reward_item` FOR EACH ROW BEGIN
    IF NEW.stock = 0 AND OLD.stock > 0 THEN
        UPDATE REWARD_ITEM
        SET status = 'out_of_stock'
        WHERE reward_id = NEW.reward_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `staff_id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `dept_id` int(11) DEFAULT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `staff`
--

INSERT INTO `staff` (`staff_id`, `name`, `email`, `dept_id`, `faculty_id`, `phone`, `status`) VALUES
(1, 'Cindy Hutasoit', 'xsuwarno@pt.org', 8, 1, '(0160) 657 0936', 'active'),
(2, 'Praba Narpati', 'yance12@yahoo.com', 18, 2, '+62 (049) 697-0816', 'active'),
(3, 'Ega Januar', 'rajatacengkal@pd.mil', 15, 2, '+62 (0601) 513-4163', 'active'),
(4, 'Ajimat Sirait', 'darman18@yahoo.com', 7, 6, '(0136) 125-8077', 'active'),
(5, 'Pia Napitupulu', 'suartinicakrawangsa@cv.ponpes.id', 35, 1, '+62-0112-832-0685', 'active'),
(6, 'Daniswara Aryani, M.TI.', 'mandalajayeng@pt.ponpes.id', 38, 4, '+62 (0411) 716 0541', 'active'),
(7, 'Gilda Saptono', 'lembahlailasari@ud.web.id', 3, 1, '081 060 1199', 'active'),
(8, 'Vivi Wastuti', 'radika37@perum.gov', 6, 2, '0846954911', 'active'),
(9, 'dr. Ifa Nababan', 'khardiansyah@gmail.com', 15, 5, '+62-285-536-4270', 'active'),
(10, 'Olga Kurniawan', 'anggabaya13@ud.mil.id', 39, 1, '+62-022-082-3190', 'active'),
(11, 'dr. Mahesa Safitri, S.H.', 'ibun65@cv.biz.id', 36, 2, '(0637) 986 1929', 'active'),
(12, 'Jumadi Hutasoit', 'usamahtami@hotmail.com', 35, 4, '+62-940-883-8775', 'active'),
(13, 'Eman Halim, S.T.', 'ranggriawan@hotmail.com', 15, 4, '+62 (04) 916-9882', 'active'),
(14, 'Puti Susanti', 'saragihslamet@gmail.com', 38, 3, '081 494 8188', 'active'),
(15, 'Ifa Mahendra', 'hadiprakasa@perum.ac.id', 1, 7, '+62-51-859-6926', 'active'),
(16, 'Cut Vicky Purnawati', 'ranggamandala@pt.desa.id', 11, 6, '+62 (0693) 852-7719', 'active'),
(17, 'H. Aditya Kusumo, S.Sos', 'queen87@hotmail.com', 28, 3, '(053) 780 7777', 'active'),
(18, 'Irma Simanjuntak', 'vimannarpati@yahoo.com', 18, 2, '(030) 312 4595', 'active'),
(19, 'Puti Lazuardi', 'mariahidayanto@yahoo.com', 14, 7, '+62 (640) 005 1959', 'active'),
(20, 'R.M. Banara Rajata', 'sihotangatmaja@yahoo.com', 22, 1, '+62-89-876-1024', 'active'),
(21, 'Gilda Tarihoran', 'sabri20@cv.ponpes.id', 6, 4, '+62 (0713) 535-4950', 'active'),
(22, 'drg. Elon Lazuardi, S.I.Kom', 'dacin53@ud.or.id', 7, 3, '(0786) 277 7012', 'active'),
(23, 'Timbul Mansur', 'mursita52@ud.mil.id', 23, 5, '+62-733-828-0064', 'active'),
(24, 'Kardi Pradipta', 'handayanijamal@pd.com', 17, 7, '+62 (343) 794 9917', 'active'),
(25, 'Violet Hutasoit', 'oastuti@perum.mil.id', 3, 6, '+62-0239-970-4262', 'active'),
(26, 'Sutan Liman Sitompul, S.E.', 'usinaga@ud.mil', 30, 5, '+62 (0219) 932-2761', 'active'),
(27, 'Ilsa Firgantoro', 'marpaunggamani@hotmail.com', 8, 4, '(0806) 052 2370', 'active'),
(28, 'Tgk. Ina Tampubolon, S.Pt', 'prabowoibrahim@hotmail.com', 6, 5, '+62 (0903) 910 0595', 'active'),
(29, 'Sutan Ivan Winarsih', 'karya25@gmail.com', 19, 7, '+62-072-844-2467', 'active'),
(30, 'Bakiono Ramadan, S.Ked', 'raditya32@perum.web.id', 40, 7, '+62 (014) 869-3477', 'active'),
(31, 'Lega Mandasari', 'galarkusmawati@gmail.com', 24, 5, '+62 (0109) 392 7316', 'active'),
(32, 'Luthfi Narpati, M.Farm', 'suwarnocahyo@cv.net.id', 13, 6, '+62-069-305-2623', 'active'),
(33, 'Farhunnisa Firmansyah', 'ganephartati@yahoo.com', 5, 1, '+62 (62) 596 3925', 'active'),
(34, 'Rafi Simbolon', 'rina57@gmail.com', 15, 7, '087 792 8791', 'active'),
(35, 'Hj. Jelita Suryono, S.Farm', 'bsiregar@perum.or.id', 19, 1, '+62 (042) 006-2367', 'active'),
(36, 'R.A. Nadia Januar, M.TI.', 'panduwijayanti@gmail.com', 15, 7, '(035) 389 8534', 'active'),
(37, 'Laswi Maheswara, S.I.Kom', 'sihombingemil@yahoo.com', 7, 4, '+62 (83) 230 1051', 'active'),
(38, 'Rachel Purnawati, S.Kom', 'waskitaputri@ud.mil', 18, 4, '+62 (70) 099-0121', 'active'),
(39, 'Laila Maryadi', 'olivia87@hotmail.com', 24, 2, '088 690 2903', 'active'),
(40, 'Yessi Saragih', 'prabowosamsul@yahoo.com', 24, 3, '(065) 022 1574', 'active'),
(41, 'Gaman Putra, M.Farm', 'mahfudsamosir@yahoo.com', 14, 6, '+62 (008) 277-4597', 'active'),
(42, 'Putri Laksmiwati', 'ymaulana@cv.ac.id', 18, 6, '+62 (81) 470-6708', 'active'),
(43, 'Prabowo Handayani', 'pangeranzulaika@cv.ponpes.id', 5, 5, '+62 (880) 466-6422', 'active'),
(44, 'Maida Situmorang', 'nfarida@ud.gov', 11, 5, '+62 (281) 013-6489', 'active'),
(45, 'Wakiman Winarno', 'tmahendra@pd.mil', 16, 2, '+62 (0968) 898 7058', 'active'),
(46, 'Amelia Laksmiwati', 'clarapratama@yahoo.com', 30, 4, '+62-28-339-5398', 'active'),
(47, 'Edi Sihombing', 'eka85@gmail.com', 18, 6, '+62-0259-264-5163', 'active'),
(48, 'drg. Nilam Padmasari, M.Pd', 'opurnawati@perum.my.id', 36, 2, '081 482 2650', 'active'),
(49, 'Faizah Utama', 'dadap96@pt.biz.id', 21, 7, '(0614) 172-7696', 'active'),
(50, 'Lulut Saptono, M.Kom.', 'jaya30@gmail.com', 4, 2, '084 158 0386', 'active'),
(51, 'Yuliana Najmudin', 'kwaskita@yahoo.com', 3, 7, '+62 (0817) 111 5734', 'active'),
(52, 'Kani Mardhiyah', 'tambaadikara@perum.or.id', 21, 4, '+62-78-869-9917', 'active'),
(53, 'Wulan Utami', 'zaenab56@hotmail.com', 18, 1, '+62 (22) 287 9092', 'active'),
(54, 'Carub Prasetya', 'utamawinarsih@gmail.com', 14, 5, '+62 (085) 816 6856', 'active'),
(55, 'Kasiyah Sirait', 'ghaliyatidamanik@ud.int', 21, 2, '+62 (949) 294-4342', 'active'),
(56, 'Titi Winarno, S.IP', 'hamimaanggraini@hotmail.com', 32, 4, '0835005796', 'active'),
(57, 'Cengkal Utama', 'nasimmansur@gmail.com', 30, 2, '+62 (150) 304-3530', 'active'),
(58, 'R.A. Jasmin Haryanto', 'tarihoranpaiman@gmail.com', 17, 2, '+62-414-271-7898', 'active'),
(59, 'Hj. Zulfa Pangestu, M.TI.', 'nashiruddinyunita@gmail.com', 16, 6, '+62 (077) 906 9746', 'active'),
(60, 'Jasmin Riyanti', 'amelia64@perum.edu', 36, 5, '+62 (035) 380-8326', 'active'),
(61, 'Satya Riyanti, S.Psi', 'kurnia19@yahoo.com', 17, 6, '+62-777-742-0001', 'active'),
(62, 'Murti Damanik, S.E.', 'haryantorosman@perum.web.id', 38, 4, '(0198) 200 6833', 'active'),
(63, 'Puti Winda Kusumo', 'balidinwijayanti@gmail.com', 38, 4, '(027) 983-5952', 'active'),
(64, 'Rina Hardiansyah, S.Psi', 'suryonoyance@yahoo.com', 24, 2, '081 835 7482', 'active'),
(65, 'drg. Karen Saputra, S.T.', 'enteng90@gmail.com', 9, 5, '+62 (0345) 319 1908', 'active'),
(66, 'Ir. Jamal Napitupulu, S.I.Kom', 'mitramustofa@perum.biz.id', 32, 1, '+62 (73) 643 6317', 'active'),
(67, 'Drs. Lalita Handayani', 'dipa02@gmail.com', 4, 7, '089 790 9300', 'active'),
(68, 'Jessica Dongoran', 'mandalarachel@pd.net', 8, 2, '+62 (962) 856-1194', 'active'),
(69, 'Umi Lestari', 'radityakuswandari@hotmail.com', 11, 7, '+62 (017) 392-8973', 'active'),
(70, 'T. Aswani Kusumo, S.T.', 'paryani@pt.or.id', 28, 5, '+62 (067) 009-6554', 'active'),
(71, 'Balapati Oktaviani', 'widiastutiajimin@pt.web.id', 5, 4, '+62-795-438-7847', 'active'),
(72, 'Liman Pangestu', 'agustinaqori@cv.co.id', 25, 5, '(0234) 440-5770', 'active'),
(73, 'R.M. Drajat Maryati', 'xmandala@hotmail.com', 30, 5, '+62 (007) 301-2805', 'active'),
(74, 'Bagas Padmasari, S.Kom', 'ajiono36@pt.co.id', 17, 5, '(0173) 863-0949', 'active'),
(75, 'Drs. Hafshah Hutagalung', 'asirwandakuswandari@pd.co.id', 1, 6, '+62 (0771) 662 1059', 'active'),
(76, 'Tania Puspasari', 'xmulyani@cv.net', 8, 6, '+62-306-185-5243', 'active'),
(77, 'Drs. Galar Purwanti, M.M.', 'reza21@hotmail.com', 35, 7, '(0210) 929 7468', 'active'),
(78, 'Ana Riyanti, S.Ked', 'saadatuwais@ud.int', 18, 7, '(085) 120 9302', 'active'),
(79, 'drg. Estiono Riyanti', 'prayitnapuspasari@yahoo.com', 22, 1, '+62 (012) 744 9850', 'active'),
(80, 'Sutan Vinsen Rajata, S.Gz', 'lnovitasari@hotmail.com', 19, 4, '(015) 864-0378', 'active'),
(81, 'Puti Wijaya', 'asmianto50@hotmail.com', 11, 4, '+62 (116) 899 7116', 'active'),
(82, 'Darmaji Prasasta', 'rajatayusuf@yahoo.com', 1, 6, '(070) 038-5638', 'active'),
(83, 'Rina Nasyidah, S.Pt', 'hairyantomarpaung@hotmail.com', 17, 5, '(063) 927-1327', 'active'),
(84, 'Saadat Palastri', 'bakijan85@perum.sch.id', 12, 5, '+62 (0594) 767-9555', 'active'),
(85, 'Karimah Suartini', 'iuyainah@hotmail.com', 7, 7, '+62 (573) 927 5677', 'active'),
(86, 'Mala Siregar', 'lasmanto52@ud.co.id', 20, 7, '+62 (92) 870 5240', 'active'),
(87, 'Wardi Salahudin', 'devi72@gmail.com', 33, 5, '(0966) 881-8666', 'active'),
(88, 'Tgk. Vanya Gunawan, M.TI.', 'pnajmudin@gmail.com', 13, 2, '080 973 7695', 'active'),
(89, 'Jasmin Nurdiyanti, M.M.', 'lukman77@gmail.com', 24, 7, '+62 (22) 889 4035', 'active'),
(90, 'Chelsea Utama, S.IP', 'okto63@yahoo.com', 11, 5, '(019) 077 0541', 'active'),
(91, 'Indah Maryati', 'ohariyah@pd.edu', 34, 1, '+62 (570) 849-3531', 'active'),
(92, 'Uli Suryatmi', 'znashiruddin@ud.int', 39, 3, '+62 (016) 307 9749', 'active'),
(93, 'Agnes Nasyidah', 'nsinaga@gmail.com', 32, 1, '(0202) 885 6439', 'active'),
(94, 'Cici Hartati', 'pandunasyidah@perum.go.id', 8, 3, '+62 (917) 842 2865', 'active'),
(95, 'Juli Gunawan', 'drajat38@pt.mil.id', 20, 2, '(0887) 417-1926', 'active'),
(96, 'Irma Wijayanti', 'zulaikalaras@pd.edu', 4, 2, '0872841957', 'active'),
(97, 'Eman Suwarno', 'purwantiputi@gmail.com', 37, 1, '+62 (0484) 203-8540', 'active'),
(98, 'Raisa Iswahyudi', 'usyiputra@gmail.com', 6, 6, '+62 (428) 728-6699', 'active'),
(99, 'Zelaya Zulkarnain, S.IP', 'parisrahayu@gmail.com', 32, 7, '(0072) 535-1863', 'active'),
(100, 'Juli Sitompul', 'mustofaradika@pt.co.id', 5, 7, '(030) 489 7386', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

CREATE TABLE `student` (
  `stud_id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `dept_id` int(11) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student`
--

INSERT INTO `student` (`stud_id`, `name`, `email`, `faculty_id`, `dept_id`, `phone`, `status`) VALUES
(1, 'Cemplunk Pangestu', 'candrakanta02@cv.mil', 2, 28, '+62 (0039) 653 6320', 'active'),
(2, 'Lintang Tarihoran', 'zulfa43@gmail.com', 7, 38, '+62 (554) 271 9447', 'active'),
(3, 'Iriana Agustina', 'setiawansatya@ud.ponpes.id', 5, 21, '+62-072-588-0209', 'active'),
(4, 'Dt. Lurhur Padmasari', 'adhiarjapudjiastuti@hotmail.com', 4, 29, '(012) 019-9625', 'active'),
(5, 'Paramita Ardianto, M.M.', 'esaragih@pt.biz.id', 4, 14, '+62 (74) 392 7176', 'active'),
(6, 'Prabowo Siregar', 'putripranowo@cv.ac.id', 5, 31, '+62 (103) 472 7566', 'active'),
(7, 'Tgk. Hendri Gunawan, M.TI.', 'kalimhandayani@hotmail.com', 7, 11, '+62-747-149-9385', 'active'),
(8, 'Slamet Wacana', 'hlaksmiwati@gmail.com', 6, 6, '+62 (0712) 620 7213', 'active'),
(9, 'Najwa Padmasari', 'reksa52@ud.org', 3, 33, '(0417) 391 5463', 'active'),
(10, 'Jais Mardhiyah, M.Farm', 'puspitacakrawala@gmail.com', 6, 40, '(0308) 532-0390', 'active'),
(11, 'Ibrani Tampubolon', 'citramulyani@yahoo.com', 3, 6, '084 307 6041', 'active'),
(12, 'Hartaka Waskita, M.M.', 'yuniaratma@gmail.com', 7, 16, '087 401 2084', 'active'),
(13, 'Natalia Agustina, S.H.', 'itarihoran@perum.ac.id', 6, 20, '+62 (768) 354 5034', 'active'),
(14, 'H. Danu Kurniawan', 'indah76@yahoo.com', 2, 13, '+62-0328-460-8284', 'active'),
(15, 'R.A. Icha Irawan', 'ynatsir@gmail.com', 2, 2, '(0424) 620 3688', 'active'),
(16, 'Putri Utama', 'mulya95@pt.desa.id', 1, 16, '+62 (07) 446-7099', 'active'),
(17, 'R.M. Anggabaya Latupono', 'birawan@pd.sch.id', 4, 40, '+62 (008) 384-7738', 'active'),
(18, 'Laswi Latupono', 'lalafirgantoro@pd.edu', 7, 5, '+62 (180) 378-9078', 'active'),
(19, 'Sabar Salahudin', 'titiwidodo@gmail.com', 4, 27, '+62 (0516) 633 5598', 'active'),
(20, 'Gangsa Simanjuntak', 'novitasarigaduh@yahoo.com', 6, 37, '+62-0321-181-9332', 'active'),
(21, 'Wulan Handayani', 'bhastuti@cv.ac.id', 2, 25, '+62-73-166-1938', 'active'),
(22, 'Lintang Utami', 'ehardiansyah@gmail.com', 4, 26, '(085) 826 1318', 'active'),
(23, 'dr. Mulyanto Maulana', 'kairav45@gmail.com', 2, 10, '+62 (0048) 768-8050', 'active'),
(24, 'Ophelia Astuti', 'mansurkarja@hotmail.com', 6, 1, '+62 (53) 598 2086', 'active'),
(25, 'Eka Prakasa', 'hmanullang@hotmail.com', 7, 7, '(089) 326-5361', 'active'),
(26, 'Hasta Widodo', 'csitorus@gmail.com', 7, 28, '+62 (95) 831-4308', 'active'),
(27, 'Dr. Bella Melani', 'cemplunk15@cv.ac.id', 2, 12, '+62-13-767-2922', 'active'),
(28, 'Karen Waskita', 'mardhiyahgara@hotmail.com', 7, 34, '+62 (597) 969 1410', 'active'),
(29, 'Gambira Situmorang', 'kmaryadi@perum.int', 4, 4, '+62 (563) 229-6873', 'active'),
(30, 'Catur Sudiati', 'sidiqrahimah@pd.edu', 5, 16, '(075) 197-3691', 'active'),
(31, 'Hardi Saefullah', 'wsaptono@hotmail.com', 7, 8, '(0426) 095 6355', 'active'),
(32, 'R.A. Icha Damanik', 'wibisonokasiran@yahoo.com', 4, 9, '+62 (979) 255-9258', 'active'),
(33, 'KH. Gangsar Manullang, S.Sos', 'xgunawan@pt.net', 7, 30, '+62 (02) 979 4929', 'active'),
(34, 'Puti Victoria Mustofa, S.Psi', 'panduusada@hotmail.com', 6, 34, '0846498215', 'active'),
(35, 'Maryadi Agustina', 'winarnokarsa@ud.or.id', 5, 39, '+62 (979) 813-3857', 'active'),
(36, 'Hasan Nababan', 'hamimapermata@gmail.com', 3, 29, '0818659885', 'active'),
(37, 'Drs. Tania Saragih, S.E.I', 'nugrahamahendra@cv.go.id', 5, 33, '+62 (090) 426 5527', 'active'),
(38, 'Lantar Mandasari', 'aurora35@hotmail.com', 4, 36, '(003) 444-3356', 'active'),
(39, 'H. Luwes Suryatmi, M.TI.', 'narpatigamani@gmail.com', 4, 11, '+62 (0585) 277-3274', 'active'),
(40, 'Yusuf Mardhiyah', 'nasab78@yahoo.com', 6, 31, '+62-991-842-5900', 'active'),
(41, 'drg. Marwata Waluyo', 'irawanzelda@ud.ac.id', 4, 17, '+62 (0711) 442-7668', 'active'),
(42, 'Bagus Utami', 'margana24@yahoo.com', 7, 16, '0888938487', 'active'),
(43, 'Endah Nuraini', 'halimahmakara@yahoo.com', 7, 18, '+62-01-586-0074', 'active'),
(44, 'Uchita Tarihoran', 'donowaskita@hotmail.com', 7, 34, '+62-0241-922-2971', 'active'),
(45, 'R. Purwanto Widiastuti', 'rnajmudin@gmail.com', 4, 16, '080 933 8940', 'active'),
(46, 'Hardi Firmansyah', 'kusumafirmansyah@cv.mil.id', 3, 29, '086 503 3637', 'active'),
(47, 'Lamar Mayasari', 'mariaprayoga@perum.net', 1, 19, '+62 (67) 523-7726', 'active'),
(48, 'Puti Agnes Mandala, S.Farm', 'dalimin49@gmail.com', 2, 18, '+62 (0649) 432 1276', 'active'),
(49, 'Silvia Nainggolan', 'wage73@gmail.com', 3, 21, '+62-889-737-7062', 'active'),
(50, 'Sadina Puspita', 'atma19@hotmail.com', 5, 6, '+62 (0091) 923-3006', 'active'),
(51, 'Dr. Kenes Ardianto, M.Kom.', 'suryonojagaraga@cv.ac.id', 2, 10, '(016) 926 7372', 'active'),
(52, 'Uli Wahyuni', 'yuniarvivi@perum.sch.id', 2, 25, '+62 (057) 509-2924', 'active'),
(53, 'Gina Andriani', 'bfirgantoro@hotmail.com', 6, 10, '+62-27-135-9931', 'active'),
(54, 'Titin Lazuardi', 'zsimanjuntak@hotmail.com', 6, 14, '+62 (81) 030-9245', 'active'),
(55, 'Jati Hasanah', 'yuliartitirta@cv.mil.id', 1, 27, '+62 (237) 194 1527', 'active'),
(56, 'Lasmanto Laksmiwati, S.Pd', 'hakimjindra@pt.my.id', 4, 22, '+62 (041) 846 2262', 'active'),
(57, 'Tgk. Vivi Wastuti, S.Ked', 'ssimbolon@pd.or.id', 5, 30, '+62 (005) 346 2195', 'active'),
(58, 'Novi Siregar', 'twidodo@perum.com', 4, 4, '+62 (0137) 006-4457', 'active'),
(59, 'Tiara Samosir', 'purwayuniar@gmail.com', 2, 27, '0891230697', 'active'),
(60, 'Karen Rajata', 'sabrina30@hotmail.com', 4, 38, '+62 (056) 123-1282', 'active'),
(61, 'Mulyanto Nasyidah', 'rnainggolan@gmail.com', 6, 2, '+62 (0635) 574 0380', 'active'),
(62, 'Azalea Puspasari', 'balangga48@pd.edu', 7, 37, '+62 (511) 000-1784', 'active'),
(63, 'Soleh Siregar', 'paiman27@hotmail.com', 4, 31, '+62 (200) 806 2499', 'active'),
(64, 'Dimas Laksita', 'damanikrudi@ud.desa.id', 1, 23, '(0808) 445 2712', 'active'),
(65, 'Simon Pradipta', 'damanikpaiman@pt.gov', 3, 25, '(0766) 805 4888', 'active'),
(66, 'dr. Nasim Pangestu', 'vivi66@yahoo.com', 7, 27, '+62 (16) 366-3723', 'active'),
(67, 'Ir. Rahayu Ardianto, M.Farm', 'rardianto@hotmail.com', 5, 35, '+62 (80) 755 1075', 'active'),
(68, 'Ir. Jono Wacana, M.Ak', 'pmustofa@yahoo.com', 7, 39, '+62-0389-331-8073', 'active'),
(69, 'Rini Maheswara', 'radityawacana@yahoo.com', 2, 32, '+62 (0000) 812 4182', 'active'),
(70, 'Banawa Maryati', 'ismailardianto@pt.co.id', 2, 18, '+62-030-248-4061', 'active'),
(71, 'Putri Farida, S.Kom', 'cramadan@cv.com', 4, 32, '+62-988-226-4028', 'active'),
(72, 'Ir. Ani Laksmiwati', 'kasimnovitasari@perum.sch.id', 1, 25, '0892785175', 'active'),
(73, 'Soleh Utama', 'warta16@yahoo.com', 3, 26, '(0308) 656 2801', 'active'),
(74, 'Jarwi Rahayu', 'rajasaharto@yahoo.com', 6, 11, '+62 (0871) 953-1739', 'active'),
(75, 'Lanang Haryanto', 'alikajanuar@gmail.com', 7, 30, '080 598 9384', 'active'),
(76, 'Ani Wahyuni, S.Kom', 'susantibajragin@ud.id', 2, 40, '+62-0476-819-3302', 'active'),
(77, 'Tgk. Kuncara Utama', 'enuraini@hotmail.com', 5, 2, '(045) 268-9438', 'active'),
(78, 'Ayu Permata', 'gara65@hotmail.com', 4, 38, '0864712956', 'active'),
(79, 'Tgk. Candrakanta Widodo, S.E.', 'okuswandari@ud.ac.id', 5, 2, '(0264) 319-2752', 'active'),
(80, 'Asmianto Halimah', 'vivigunarto@hotmail.com', 1, 28, '(0704) 319 4255', 'active'),
(81, 'Sakti Mulyani', 'purwadi61@gmail.com', 2, 30, '(047) 141 9186', 'active'),
(82, 'Fitria Kusumo, S.Ked', 'nurdiyanticaturangga@hotmail.com', 2, 4, '+62-0854-246-6089', 'active'),
(83, 'Kardi Firmansyah', 'padmakusumo@gmail.com', 3, 25, '+62-276-994-2503', 'active'),
(84, 'Gaman Waskita', 'gsinaga@yahoo.com', 3, 14, '+62 (094) 305 0951', 'active'),
(85, 'Tari Palastri', 'rahayuratna@pt.org', 4, 21, '+62-850-677-3047', 'active'),
(86, 'Dr. Julia Mardhiyah, S.Ked', 'mangunsonggaliono@cv.id', 3, 25, '+62-49-558-9194', 'active'),
(87, 'Gina Rajata, S.H.', 'vhidayat@yahoo.com', 3, 27, '0899121500', 'active'),
(88, 'Talia Marbun', 'lpratiwi@yahoo.com', 3, 6, '+62 (067) 643-1761', 'active'),
(89, 'Lidya Namaga', 'naradi67@cv.biz.id', 4, 2, '+62 (42) 505 5683', 'active'),
(90, 'Lintang Maheswara', 'vanesa93@pt.biz.id', 6, 35, '+62 (86) 008-2572', 'active'),
(91, 'drg. Puji Uwais', 'kajenwasita@perum.net', 1, 23, '+62 (346) 361-8665', 'active'),
(92, 'Siska Novitasari', 'luluhsihombing@pd.id', 2, 5, '(0098) 069 8711', 'active'),
(93, 'H. Jarwadi Tarihoran', 'chandra71@pd.int', 7, 3, '+62 (982) 695 5673', 'active'),
(94, 'Asmadi Purnawati', 'baktiantoriyanti@hotmail.com', 7, 2, '(068) 317-2739', 'active'),
(95, 'Halim Irawan', 'almira04@pt.ponpes.id', 2, 13, '(0164) 259-9847', 'active'),
(96, 'Hj. Nabila Halim, S.Pt', 'usudiati@pd.int', 7, 2, '+62 (0339) 711-7857', 'active'),
(97, 'Tari Widodo', 'makutaoktaviani@hotmail.com', 5, 10, '0827169208', 'active'),
(98, 'Belinda Putra', 'cahyonositumorang@pt.int', 2, 9, '+62 (0305) 505 7825', 'active'),
(99, 'Dr. Perkasa Najmudin, M.M.', 'tarihoranjohan@yahoo.com', 4, 8, '(077) 084-6726', 'active'),
(100, 'Nova Handayani', 'irma13@pt.mil.id', 5, 14, '(028) 007 5495', 'active');

-- --------------------------------------------------------

--
-- Table structure for table `sustainability_campaign`
--

CREATE TABLE `sustainability_campaign` (
  `campaign_id` int(11) NOT NULL,
  `campaign_name` varchar(100) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `total_points` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sustainability_campaign`
--

INSERT INTO `sustainability_campaign` (`campaign_id`, `campaign_name`, `start_date`, `end_date`, `description`, `total_points`, `created_by`, `created_at`) VALUES
(1, 'Campaign 1', '2023-11-15', '2024-01-17', 'Ullam sequi repellat.', 69, 14, '2025-04-12 14:18:58'),
(2, 'Campaign 2', '2023-10-03', '2024-10-10', 'Alias suscipit ipsam impedit officiis.', 390, 71, '2025-02-10 11:11:45'),
(3, 'Campaign 3', '2024-05-11', '2024-09-16', 'Labore similique accusamus rerum animi.', 89, 35, '2025-04-26 11:12:32'),
(4, 'Campaign 4', '2023-08-08', '2025-04-13', 'Amet est tempore dignissimos.', 154, 78, '2025-06-03 17:46:41'),
(5, 'Campaign 5', '2024-02-13', '2024-04-12', 'Accusantium nobis quae hic accusantium.', 117, 92, '2025-03-26 07:30:27'),
(6, 'Campaign 6', '2024-01-06', '2024-04-05', 'Necessitatibus veniam iste alias eveniet tempora.', 185, 27, '2025-05-21 23:54:01'),
(7, 'Campaign 7', '2023-07-02', '2025-03-21', 'A repudiandae repellat.', 361, 82, '2025-05-25 06:18:47'),
(8, 'Campaign 8', '2024-01-30', '2025-01-16', 'A maxime earum vero.', 446, 34, '2025-05-15 09:54:59'),
(9, 'Campaign 9', '2023-10-14', '2023-10-25', 'Delectus nemo impedit consequuntur quos.', 268, 63, '2025-06-07 10:13:53'),
(10, 'Campaign 10', '2023-12-06', '2025-05-06', 'Unde consectetur ipsam vel dignissimos.', 138, 7, '2025-01-21 06:59:35'),
(11, 'Campaign 11', '2023-10-17', '2024-07-15', 'Voluptas minus quos suscipit.', 57, 82, '2025-02-07 01:28:35'),
(12, 'Campaign 12', '2023-09-29', '2023-10-18', 'Doloremque minus aliquid.', 226, 36, '2025-03-21 21:44:03'),
(13, 'Campaign 13', '2024-02-28', '2025-01-10', 'Facere sapiente sunt animi impedit doloribus.', 32, 1, '2025-02-19 00:00:15'),
(14, 'Campaign 14', '2024-03-27', '2024-06-04', 'Numquam accusantium sequi expedita voluptatem et.', 180, 99, '2025-03-23 22:37:13'),
(15, 'Campaign 15', '2023-10-03', '2023-11-26', 'Cumque eum animi est molestias.', 76, 82, '2025-02-27 17:03:25'),
(16, 'Campaign 16', '2024-02-15', '2024-04-10', 'Libero id quo officia iure quo temporibus quis.', 144, 21, '2025-05-13 11:28:29'),
(17, 'Campaign 17', '2023-11-26', '2024-06-29', 'Quo animi quia.', 389, 57, '2025-02-22 03:30:42'),
(18, 'Campaign 18', '2024-02-11', '2024-07-18', 'Itaque libero itaque.', 292, 91, '2025-05-25 17:50:30'),
(19, 'Campaign 19', '2024-06-06', '2024-10-28', 'Esse reprehenderit accusamus repellat.', 228, 72, '2025-05-10 05:15:30'),
(20, 'Campaign 20', '2023-09-10', '2024-07-19', 'Minus ex hic quibusdam magni suscipit dicta.', 14, 15, '2025-01-18 18:00:49'),
(21, 'Campaign 21', '2023-08-22', '2023-10-23', 'A repudiandae placeat quos.', 48, 89, '2025-04-05 01:36:25'),
(22, 'Campaign 22', '2023-07-08', '2024-03-25', 'Illo laboriosam illo ducimus.', 472, 20, '2025-01-07 15:38:46'),
(23, 'Campaign 23', '2023-09-27', '2024-08-23', 'Impedit ipsa eum explicabo earum sint.', 289, 5, '2025-02-11 19:13:33'),
(24, 'Campaign 24', '2023-07-25', '2024-07-03', 'Neque vel modi alias.', 437, 48, '2025-02-18 11:23:49'),
(25, 'Campaign 25', '2023-08-20', '2024-11-03', 'Natus ipsum omnis unde aliquid.', 308, 71, '2025-02-14 02:06:49'),
(26, 'Campaign 26', '2023-12-15', '2024-11-07', 'Voluptatibus eaque nisi vel veritatis eius magni.', 85, 56, '2025-06-05 18:49:00'),
(27, 'Campaign 27', '2023-12-08', '2024-06-03', 'Quae dolore architecto perspiciatis debitis.', 75, 6, '2025-04-14 19:16:54'),
(28, 'Campaign 28', '2024-05-07', '2024-12-06', 'Omnis atque eius harum consequuntur.', 167, 47, '2025-02-05 12:56:14'),
(29, 'Campaign 29', '2024-02-08', '2025-06-01', 'Et officia quo aliquid placeat ad voluptate.', 470, 6, '2025-05-27 15:09:33'),
(30, 'Campaign 30', '2023-12-16', '2025-03-15', 'Recusandae quidem minima vel recusandae.', 470, 46, '2025-05-21 07:32:54'),
(31, 'Campaign 31', '2023-08-09', '2024-12-30', 'Distinctio saepe sapiente.', 117, 88, '2025-04-28 03:28:34'),
(32, 'Campaign 32', '2023-07-01', '2024-01-17', 'Similique velit ducimus rem dolores maxime.', 137, 86, '2025-03-21 03:10:05'),
(33, 'Campaign 33', '2024-01-01', '2024-02-09', 'Sit dolore ab omnis repellendus maxime modi.', 62, 46, '2025-05-17 06:33:14'),
(34, 'Campaign 34', '2023-11-19', '2024-07-17', 'Perferendis ratione nisi minus quia.', 409, 72, '2025-03-26 10:08:47'),
(35, 'Campaign 35', '2024-02-15', '2024-12-08', 'Rerum sit adipisci natus ex.', 462, 53, '2025-06-09 08:41:36'),
(36, 'Campaign 36', '2024-02-25', '2024-08-18', 'Sequi asperiores unde quas aspernatur eos quasi.', 327, 96, '2025-04-30 16:46:13'),
(37, 'Campaign 37', '2023-09-06', '2024-05-18', 'Eum quo ullam libero error amet. Id ex quaerat.', 89, 31, '2025-04-03 16:10:06'),
(38, 'Campaign 38', '2024-04-08', '2024-06-22', 'Vel eum quidem eligendi deserunt tenetur.', 452, 21, '2025-03-27 16:32:28'),
(39, 'Campaign 39', '2023-08-04', '2024-02-18', 'Assumenda nemo nemo ullam eum exercitationem.', 419, 23, '2025-02-16 08:11:24'),
(40, 'Campaign 40', '2023-07-02', '2024-07-08', 'Aspernatur at est deleniti soluta deleniti culpa.', 461, 53, '2025-03-14 07:13:00'),
(41, 'Campaign 41', '2023-07-05', '2024-02-07', 'Rerum a vel aspernatur doloribus ipsum.', 22, 23, '2025-04-03 23:06:03'),
(42, 'Campaign 42', '2024-01-28', '2024-08-04', 'Commodi dolore sint quaerat voluptates.', 387, 43, '2025-04-06 18:30:53'),
(43, 'Campaign 43', '2024-01-15', '2025-01-18', 'Consectetur eaque earum quam.', 410, 53, '2025-01-28 02:32:45'),
(44, 'Campaign 44', '2023-11-02', '2025-01-21', 'Omnis minus fugiat eaque occaecati ipsam odio.', 420, 86, '2025-03-07 23:34:57'),
(45, 'Campaign 45', '2023-11-28', '2024-02-09', 'Eius dignissimos quasi beatae odit.', 452, 95, '2025-01-05 06:01:30'),
(46, 'Campaign 46', '2023-07-09', '2025-01-01', 'Debitis minima iure ratione cupiditate occaecati.', 425, 32, '2025-05-08 10:09:31'),
(47, 'Campaign 47', '2024-02-04', '2024-07-31', 'Esse reprehenderit nihil quas libero libero.', 146, 21, '2025-01-09 05:53:52'),
(48, 'Campaign 48', '2024-03-21', '2024-11-08', 'Accusantium earum veniam alias enim inventore.', 413, 90, '2025-03-24 22:12:51'),
(49, 'Campaign 49', '2023-06-24', '2024-12-17', 'Accusamus beatae fugit sunt at.', 65, 49, '2025-01-01 10:33:55'),
(50, 'Campaign 50', '2024-02-03', '2024-07-10', 'Natus perspiciatis laborum.', 456, 5, '2025-05-11 02:17:50'),
(51, 'Campaign 51', '2024-03-13', '2025-02-25', 'Minus ullam doloribus unde illo.', 449, 61, '2025-02-19 01:28:24'),
(52, 'Campaign 52', '2024-01-02', '2024-05-15', 'Laudantium unde perspiciatis cumque veritatis.', 123, 26, '2025-03-21 07:15:56'),
(53, 'Campaign 53', '2023-07-06', '2024-08-23', 'Commodi magni porro harum laborum repudiandae.', 428, 59, '2025-01-11 10:41:40'),
(54, 'Campaign 54', '2024-01-07', '2024-12-10', 'Eveniet voluptate fuga nam ratione.', 189, 40, '2025-05-17 18:41:09'),
(55, 'Campaign 55', '2023-11-21', '2024-12-29', 'Ea dolorum provident totam et nemo.', 430, 30, '2025-03-13 12:25:08'),
(56, 'Campaign 56', '2023-12-15', '2025-01-26', 'Voluptate fugiat tempore hic quae.', 124, 4, '2025-05-26 04:18:55'),
(57, 'Campaign 57', '2023-07-12', '2024-05-18', 'Perferendis tempore ratione reprehenderit earum.', 347, 25, '2025-05-11 04:04:33'),
(58, 'Campaign 58', '2024-01-16', '2024-02-06', 'Ea deleniti alias deleniti.', 214, 43, '2025-03-08 06:36:19'),
(59, 'Campaign 59', '2023-06-19', '2024-05-20', 'Odit repudiandae pariatur suscipit perferendis.', 152, 9, '2025-05-11 01:03:34'),
(60, 'Campaign 60', '2023-12-01', '2024-10-21', 'Facilis quos ratione fugiat.', 405, 36, '2025-05-24 23:00:46'),
(61, 'Campaign 61', '2024-01-04', '2024-04-13', 'Inventore totam delectus iusto.', 189, 83, '2025-05-13 09:16:03'),
(62, 'Campaign 62', '2023-07-11', '2025-03-09', 'Odio quo nemo qui omnis corrupti molestias.', 270, 52, '2025-04-03 06:19:55'),
(63, 'Campaign 63', '2024-02-06', '2025-05-04', 'Cupiditate omnis enim laboriosam incidunt.', 357, 69, '2025-03-16 22:26:01'),
(64, 'Campaign 64', '2023-06-30', '2023-09-09', 'Inventore distinctio dolorem odit sint.', 179, 4, '2025-01-23 16:12:46'),
(65, 'Campaign 65', '2023-09-24', '2024-12-14', 'Possimus aliquam quibusdam eos.', 69, 34, '2025-06-06 01:00:44'),
(66, 'Campaign 66', '2023-12-19', '2024-10-19', 'Perferendis unde minus enim iste.', 101, 75, '2025-05-19 11:51:59'),
(67, 'Campaign 67', '2023-09-23', '2024-06-14', 'Est cum aperiam nam perferendis.', 145, 5, '2025-05-29 06:07:23'),
(68, 'Campaign 68', '2023-07-07', '2025-05-12', 'Non cumque animi fuga cumque nesciunt.', 65, 77, '2025-04-11 01:23:31'),
(69, 'Campaign 69', '2023-11-21', '2024-09-02', 'Reprehenderit nobis vel.', 232, 45, '2025-02-03 00:48:00'),
(70, 'Campaign 70', '2023-08-08', '2024-09-09', 'Eum culpa tempora assumenda.', 383, 41, '2025-02-09 17:22:48'),
(71, 'Campaign 71', '2024-04-08', '2024-04-29', 'Laudantium laboriosam magni doloribus.', 233, 78, '2025-03-28 19:24:59'),
(72, 'Campaign 72', '2024-06-06', '2024-08-27', 'Illum corporis quibusdam velit cupiditate.', 271, 15, '2025-01-12 16:03:40'),
(73, 'Campaign 73', '2023-08-19', '2024-03-27', 'Explicabo delectus quos doloribus.', 207, 74, '2025-01-02 09:03:26'),
(74, 'Campaign 74', '2023-07-21', '2024-10-09', 'Sequi non quo in eos molestiae.', 107, 33, '2025-01-31 03:44:29'),
(75, 'Campaign 75', '2023-09-18', '2024-10-23', 'Excepturi eum qui nemo.', 32, 91, '2025-01-29 00:03:36'),
(76, 'Campaign 76', '2023-07-23', '2024-08-31', 'Provident hic accusantium.', 233, 1, '2025-01-09 10:43:07'),
(77, 'Campaign 77', '2024-05-12', '2024-12-26', 'Tenetur numquam dicta.', 276, 69, '2025-05-18 21:05:14'),
(78, 'Campaign 78', '2023-06-30', '2024-05-03', 'Ipsa velit officiis pariatur.', 361, 93, '2025-03-07 14:22:45'),
(79, 'Campaign 79', '2024-03-30', '2024-08-05', 'Labore ab tempora praesentium ab quas.', 491, 95, '2025-01-11 06:43:06'),
(80, 'Campaign 80', '2024-01-27', '2024-08-31', 'Quibusdam esse libero facilis ea est distinctio.', 387, 86, '2025-04-12 07:24:09'),
(81, 'Campaign 81', '2023-06-30', '2024-07-17', 'Esse pariatur doloribus ea quidem id.', 110, 47, '2025-04-25 18:19:41'),
(82, 'Campaign 82', '2023-07-13', '2024-12-19', 'Dolor sunt recusandae illo.', 230, 9, '2025-03-03 16:47:34'),
(83, 'Campaign 83', '2023-10-02', '2025-01-28', 'Voluptates quo impedit rerum eaque id.', 495, 86, '2025-02-23 17:15:58'),
(84, 'Campaign 84', '2023-07-07', '2024-02-26', 'Harum illo nihil voluptate debitis.', 481, 43, '2025-02-16 12:41:20'),
(85, 'Campaign 85', '2024-03-15', '2024-10-07', 'Animi sunt exercitationem.', 329, 41, '2025-04-26 07:04:45'),
(86, 'Campaign 86', '2023-07-13', '2024-09-16', 'Commodi eius facilis. Repellendus hic ut velit.', 349, 16, '2025-03-03 08:54:00'),
(87, 'Campaign 87', '2023-09-02', '2024-11-21', 'Dicta iste molestiae illo recusandae error.', 378, 39, '2025-03-22 10:11:09'),
(88, 'Campaign 88', '2024-02-15', '2024-06-01', 'Vitae et ipsam placeat beatae iste.', 269, 40, '2025-01-05 20:13:39'),
(89, 'Campaign 89', '2023-11-08', '2024-08-07', 'Vel assumenda enim eum blanditiis asperiores.', 351, 53, '2025-05-11 22:27:10'),
(90, 'Campaign 90', '2023-09-22', '2025-01-27', 'Magnam deserunt occaecati. Animi earum quae.', 177, 52, '2025-02-04 00:39:16'),
(91, 'Campaign 91', '2024-01-03', '2025-01-21', 'Voluptatum eum tempora amet qui neque nemo.', 366, 38, '2025-01-25 04:52:06'),
(92, 'Campaign 92', '2024-01-29', '2025-02-24', 'Impedit dolor officia fuga.', 293, 17, '2025-03-11 00:30:54'),
(93, 'Campaign 93', '2023-10-12', '2024-09-06', 'Odio earum ad maxime sequi possimus veniam amet.', 108, 54, '2025-06-08 20:16:19'),
(94, 'Campaign 94', '2024-01-14', '2024-04-28', 'Ipsa quod saepe occaecati enim iure esse.', 350, 49, '2025-05-15 14:27:49'),
(95, 'Campaign 95', '2023-09-10', '2025-05-14', 'Nam doloribus natus eos sapiente et.', 356, 96, '2025-02-10 00:07:09'),
(96, 'Campaign 96', '2024-04-17', '2024-08-12', 'Praesentium illum excepturi.', 472, 23, '2025-03-18 05:02:10'),
(97, 'Campaign 97', '2023-10-06', '2024-12-10', 'Reprehenderit ea voluptate fugiat atque.', 325, 73, '2025-04-24 20:04:04'),
(98, 'Campaign 98', '2023-09-09', '2025-01-30', 'Veniam repudiandae a illo natus.', 164, 52, '2025-03-03 22:38:09'),
(99, 'Campaign 99', '2023-07-09', '2024-02-04', 'Magnam nam nisi quisquam ullam.', 290, 1, '2025-03-30 18:59:19'),
(100, 'Campaign 100', '2023-10-03', '2024-05-25', 'Et dignissimos corporis ducimus.', 165, 37, '2025-01-26 09:57:31');

-- --------------------------------------------------------

--
-- Table structure for table `sustainability_coordinator`
--

CREATE TABLE `sustainability_coordinator` (
  `staff_id` int(11) NOT NULL,
  `fullname` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `dept_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sustainability_coordinator`
--

INSERT INTO `sustainability_coordinator` (`staff_id`, `fullname`, `phone`, `email`, `faculty_id`, `dept_id`) VALUES
(1, 'Natalia Maryadi', '(005) 400 3777', 'darufirmansyah@hotmail.com', 5, 9),
(2, 'Nova Yuliarti', '+62 (640) 177-1405', 'xmangunsong@pd.desa.id', 2, 31),
(3, 'Cayadi Tamba', '088 941 6301', 'salahudingarang@pt.sch.id', 5, 11),
(4, 'Faizah Nasyiah', '+62 (768) 941-9329', 'wibisonogangsa@gmail.com', 3, 34),
(5, 'Gawati Thamrin', '+62-0614-586-3076', 'jsamosir@gmail.com', 7, 39),
(6, 'Melinda Rahayu', '+62 (05) 877 5481', 'gpradipta@pt.biz.id', 4, 14),
(7, 'Karsana Yuniar', '+62 (023) 287-2828', 'wnapitupulu@pt.go.id', 5, 13),
(8, 'Olivia Padmasari, M.M.', '+62 (57) 392 8885', 'anggriawanqori@perum.net.id', 6, 20),
(9, 'dr. Karimah Mayasari', '+62 (72) 249-5696', 'sitompulteguh@cv.co.id', 4, 24),
(10, 'Hamima Latupono', '+62 (042) 776 9982', 'asaptono@pt.int', 4, 34),
(11, 'R. Michelle Pangestu, S.T.', '+62-94-392-2380', 'qutami@yahoo.com', 4, 8),
(12, 'Rachel Maheswara, S.E.', '+62 (671) 248-9949', 'lantarsalahudin@pd.or.id', 2, 15),
(13, 'Balangga Saefullah', '(0784) 902-1022', 'puspitakunthara@pt.sch.id', 1, 22),
(14, 'Kairav Januar', '+62-0013-263-6879', 'ilailasari@pd.my.id', 1, 38),
(15, 'Chelsea Wijayanti, S.T.', '+62 (0451) 076-8187', 'jarwa87@hotmail.com', 5, 15),
(16, 'Aswani Hidayanto', '+62-015-721-7923', 'uutama@perum.or.id', 5, 15),
(17, 'Tgk. Simon Andriani, M.Pd', '+62 (049) 675-9240', 'uyainahellis@ud.co.id', 1, 5),
(18, 'KH. Oman Firgantoro', '+62 (061) 238-6263', 'nramadan@hotmail.com', 6, 4),
(19, 'drg. Dewi Iswahyudi, S.H.', '+62 (930) 408 0048', 'mansurzelaya@ud.mil.id', 2, 5),
(20, 'R. Kunthara Dabukke, S.Pd', '084 934 1454', 'nhakim@perum.ponpes.id', 1, 22),
(21, 'Cut Ghaliyati Rahimah', '+62-041-415-2943', 'fthamrin@cv.gov', 1, 33),
(22, 'Ulya Rajasa', '(0098) 077-3190', 'nurulsuartini@yahoo.com', 2, 18),
(23, 'Malika Sihombing, S.T.', '+62 (44) 528-4435', 'omarbudiyanto@hotmail.com', 6, 32),
(24, 'Ir. Kasiran Gunarto', '+62 (042) 876 0916', 'ihandayani@hotmail.com', 2, 35),
(25, 'Jais Fujiati', '+62-570-540-3580', 'januaraurora@pd.or.id', 2, 37),
(26, 'Wardi Budiyanto', '(0345) 200 3072', 'mustofacornelia@hotmail.com', 5, 31),
(27, 'R. Jane Wijaya, S.Ked', '0848342950', 'nilam64@gmail.com', 2, 31),
(28, 'Cut Salimah Habibi, S.E.I', '+62 (0167) 185 5297', 'wpratama@yahoo.com', 7, 27),
(29, 'dr. Jamalia Mahendra, S.Gz', '+62 (034) 505 1891', 'adiarjawibowo@gmail.com', 2, 7),
(30, 'Tgk. Paramita Namaga, S.Ked', '(0754) 069 2656', 'joko92@perum.net', 1, 28),
(31, 'Dariati Anggriawan', '+62-521-104-2176', 'gabriella57@yahoo.com', 3, 28),
(32, 'Bakiono Permadi', '(071) 316 6243', 'salwa54@ud.my.id', 4, 30),
(33, 'Yosef Kusmawati', '(0105) 562 9983', 'sihombingmuhammad@perum.net.id', 7, 4),
(34, 'Dalima Aryani', '+62 (051) 661 4167', 'jaemanandriani@yahoo.com', 6, 7),
(35, 'Opan Ramadan', '+62-72-147-8594', 'bahuwarna32@cv.net', 1, 26),
(36, 'Vicky Uwais', '(021) 424-5652', 'pranoworahmi@hotmail.com', 6, 22),
(37, 'Jaya Sitompul', '0848042260', 'bakidinwijaya@pt.id', 7, 7),
(38, 'Irnanto Mayasari', '0879732484', 'gamantosalahudin@perum.int', 2, 13),
(39, 'Lili Maryati, S.H.', '+62 (085) 850-1300', 'widiastutilintang@yahoo.com', 2, 35),
(40, 'Icha Usamah', '+62-124-514-9395', 'parisagustina@gmail.com', 4, 9),
(41, 'dr. Talia Maryati, S.Kom', '0812481832', 'bahuwiryapurwanti@pd.co.id', 4, 12),
(42, 'Kadir Haryanti', '+62-04-798-3835', 'prasetya23@hotmail.com', 3, 30),
(43, 'Martana Prasetyo', '+62 (804) 019 9970', 'jmardhiyah@gmail.com', 2, 5),
(44, 'Prabawa Widodo', '(035) 206 4445', 'dadinapitupulu@yahoo.com', 4, 36),
(45, 'Sutan Viman Hastuti', '+62-083-392-0526', 'gsusanti@cv.gov', 1, 4),
(46, 'Prasetyo Simbolon', '(0947) 778 8825', 'lwaluyo@yahoo.com', 6, 35),
(47, 'R. Warsa Farida', '(009) 782-8503', 'clara38@perum.desa.id', 7, 1),
(48, 'Budi Prasasta', '+62-039-232-8033', 'prabatarihoran@pt.web.id', 1, 16),
(49, 'Dr. Putri Mayasari, M.Ak', '+62 (120) 411 5181', 'gabriella14@gmail.com', 2, 27),
(50, 'Paris Safitri', '(001) 078 6532', 'baktiantohariyah@hotmail.com', 4, 31),
(51, 'Zulfa Rajasa', '+62 (0407) 355-6438', 'karmanhastuti@pt.biz.id', 2, 26),
(52, 'Yulia Haryanto, S.H.', '+62 (970) 748-3089', 'adiarja46@gmail.com', 1, 11),
(53, 'Betania Gunawan', '(097) 160 9630', 'harjasa24@pd.or.id', 4, 1),
(54, 'Cut Tira Usamah, S.I.Kom', '(040) 809-4034', 'hartana82@perum.sch.id', 4, 17),
(55, 'Cengkal Latupono', '+62 (884) 756-1961', 'putrajumadi@hotmail.com', 7, 30),
(56, 'Hartana Ramadan', '(0823) 822-0306', 'widiastutiviolet@perum.go.id', 3, 28),
(57, 'Rachel Utami', '+62-022-182-5994', 'kiandra76@yahoo.com', 6, 36),
(58, 'Drajat Zulkarnain', '+62-011-716-8793', 'pratamaoni@gmail.com', 6, 32),
(59, 'Sutan Muhammad Suryono', '(082) 948-4230', 'oman13@hotmail.com', 2, 13),
(60, 'Nilam Simanjuntak', '(0934) 816-2134', 'padmasarirahayu@cv.go.id', 3, 14),
(61, 'Ajeng Mulyani, S.Gz', '(067) 809 4797', 'rusmansantoso@gmail.com', 1, 38),
(62, 'Ir. Dimaz Gunawan', '+62 (298) 622-0925', 'jaisandriani@yahoo.com', 6, 35),
(63, 'Banara Hardiansyah, S.E.', '+62 (069) 297-2660', 'ami84@pd.gov', 1, 21),
(64, 'Gandewa Winarsih', '+62 (0040) 669 8390', 'mangunsongmursita@cv.net', 1, 4),
(65, 'Banawi Hutagalung, S.E.I', '+62 (000) 379-7705', 'imam92@gmail.com', 5, 31),
(66, 'Zalindra Iswahyudi', '+62-92-797-9992', 'cakrabirawayuniar@gmail.com', 5, 34),
(67, 'Puti Vanya Mangunsong, S.Sos', '(043) 711 5656', 'gunawannyana@yahoo.com', 2, 4),
(68, 'Zamira Nainggolan', '+62 (0523) 700-6279', 'irmasudiati@gmail.com', 5, 6),
(69, 'Oliva Rajasa', '+62 (44) 673 0775', 'soleh58@ud.desa.id', 7, 12),
(70, 'R. Almira Anggriawan, S.Kom', '+62 (0481) 120 6804', 'maryadi57@hotmail.com', 1, 39),
(71, 'drg. Jamalia Megantara', '(0561) 007-8960', 'pudjiastutidono@hotmail.com', 1, 16),
(72, 'H. Sabar Uyainah, M.M.', '+62 (049) 967-2384', 'jaya47@yahoo.com', 4, 8),
(73, 'Dr. Ozy Hakim, S.Pd', '+62 (0150) 211 1941', 'hamima24@hotmail.com', 5, 16),
(74, 'drg. Unggul Waluyo, S.H.', '+62 (98) 950-1521', 'caturwinarno@hotmail.com', 5, 39),
(75, 'Wadi Budiyanto', '087 892 6712', 'karya23@hotmail.com', 1, 40),
(76, 'Sutan Surya Yuliarti', '(0674) 948 7246', 'umithamrin@gmail.com', 1, 27),
(77, 'Daru Laksmiwati', '+62 (019) 302-6673', 'tasdik81@perum.go.id', 6, 38),
(78, 'Tgk. Elma Firgantoro, S.Gz', '+62 (324) 813 5385', 'susantisurya@ud.web.id', 5, 34),
(79, 'Titin Prasetya', '088 941 7967', 'lsirait@perum.org', 3, 17),
(80, 'Dr. Maya Ardianto', '(0849) 532-4237', 'zfirgantoro@hotmail.com', 2, 21),
(81, 'drg. Puti Laksmiwati', '+62-114-233-1648', 'waskitaajeng@yahoo.com', 2, 17),
(82, 'Sutan Kawaca Pradipta', '(061) 530 3397', 'jnamaga@yahoo.com', 4, 9),
(83, 'Asmadi Mangunsong', '+62-057-650-5287', 'akarsana47@gmail.com', 6, 20),
(84, 'Sabrina Pradipta', '0855347500', 'ardiantowisnu@pt.ponpes.id', 4, 21),
(85, 'Sutan Legawa Wahyuni, M.Kom.', '+62-0522-859-2199', 'oyulianti@pt.id', 7, 5),
(86, 'dr. Balangga Ramadan, S.I.Kom', '+62 (094) 486 7239', 'darmaji70@hotmail.com', 1, 30),
(87, 'Himawan Prabowo', '0839844202', 'hardirajasa@gmail.com', 5, 37),
(88, 'Lukita Saputra', '(0419) 415-4106', 'sabrinanasyiah@yahoo.com', 1, 5),
(89, 'T. Karsana Yolanda, M.M.', '+62-258-033-6119', 'galarwidodo@hotmail.com', 5, 14),
(90, 'Simon Mandala', '+62 (95) 306 7789', 'jefrisimanjuntak@yahoo.com', 5, 17),
(91, 'Rudi Haryanti', '(018) 637 2370', 'gagustina@cv.co.id', 2, 23),
(92, 'R.A. Melinda Waskita, M.Pd', '+62 (0009) 291 1573', 'bella68@gmail.com', 1, 16),
(93, 'Rudi Habibi', '+62 (31) 201-6788', 'hidayantojindra@pt.ponpes.id', 3, 19),
(94, 'Drs. Gara Kusmawati, S.Sos', '+62 (0299) 362-3064', 'irfansetiawan@gmail.com', 2, 29),
(95, 'Carub Nasyidah', '(039) 727 2117', 'damanikkawaca@pt.org', 7, 35),
(96, 'Eka Maryati', '+62 (042) 372-4067', 'nabila43@hotmail.com', 6, 20),
(97, 'Jane Yuliarti, S.T.', '+62-0020-068-6554', 'nmansur@yahoo.com', 5, 34),
(98, 'Daru Padmasari, S.Pt', '+62 (0230) 788-8040', 'futama@ud.biz.id', 1, 36),
(99, 'Jamil Yulianti', '0827135027', 'damanikqori@cv.gov', 3, 7),
(100, 'Harsanto Damanik', '+62 (078) 963 8414', 'rahmawatirafid@pt.ponpes.id', 2, 17);

-- --------------------------------------------------------

--
-- Table structure for table `user_sustainability_campaign`
--

CREATE TABLE `user_sustainability_campaign` (
  `campaign_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `role` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_sustainability_campaign`
--

INSERT INTO `user_sustainability_campaign` (`campaign_id`, `user_id`, `role`, `status`) VALUES
(1, 53, 'leader', 'active'),
(2, 54, 'leader', 'active'),
(9, 52, 'leader', 'active'),
(9, 65, 'leader', 'active'),
(10, 74, 'participant', 'active'),
(10, 76, 'participant', 'active'),
(11, 31, 'leader', 'active'),
(11, 32, 'participant', 'active'),
(12, 30, 'participant', 'active'),
(13, 25, 'leader', 'active'),
(14, 2, 'leader', 'active'),
(14, 56, 'leader', 'active'),
(14, 75, 'participant', 'active'),
(14, 90, 'leader', 'active'),
(19, 10, 'participant', 'active'),
(20, 20, 'leader', 'active'),
(21, 31, 'participant', 'active'),
(21, 43, 'leader', 'active'),
(22, 40, 'leader', 'active'),
(25, 28, 'leader', 'active'),
(28, 46, 'leader', 'active'),
(30, 16, 'participant', 'active'),
(30, 47, 'participant', 'active'),
(33, 42, 'participant', 'active'),
(33, 62, 'participant', 'active'),
(34, 85, 'participant', 'active'),
(35, 40, 'leader', 'active'),
(35, 65, 'leader', 'active'),
(36, 6, 'participant', 'active'),
(36, 24, 'leader', 'active'),
(36, 58, 'participant', 'active'),
(36, 93, 'leader', 'active'),
(37, 91, 'leader', 'active'),
(38, 5, 'participant', 'active'),
(38, 29, 'leader', 'active'),
(39, 2, 'participant', 'active'),
(40, 74, 'leader', 'active'),
(41, 16, 'participant', 'active'),
(42, 24, 'leader', 'active'),
(42, 32, 'participant', 'active'),
(43, 42, 'participant', 'active'),
(44, 4, 'leader', 'active'),
(44, 24, 'participant', 'active'),
(44, 36, 'leader', 'active'),
(46, 90, 'leader', 'active'),
(51, 92, 'participant', 'active'),
(53, 7, 'participant', 'active'),
(55, 15, 'participant', 'active'),
(55, 96, 'leader', 'active'),
(56, 23, 'leader', 'active'),
(56, 95, 'leader', 'active'),
(57, 11, 'participant', 'active'),
(57, 16, 'leader', 'active'),
(58, 3, 'participant', 'active'),
(58, 57, 'leader', 'active'),
(59, 12, 'leader', 'active'),
(60, 56, 'leader', 'active'),
(60, 90, 'leader', 'active'),
(61, 45, 'leader', 'active'),
(61, 62, 'leader', 'active'),
(61, 67, 'leader', 'active'),
(61, 71, 'leader', 'active'),
(63, 72, 'participant', 'active'),
(69, 55, 'leader', 'active'),
(71, 10, 'participant', 'active'),
(71, 38, 'participant', 'active'),
(72, 2, 'participant', 'active'),
(72, 98, 'leader', 'active'),
(73, 6, 'leader', 'active'),
(73, 80, 'participant', 'active'),
(74, 6, 'participant', 'active'),
(76, 55, 'leader', 'active'),
(78, 33, 'participant', 'active'),
(78, 77, 'participant', 'active'),
(78, 78, 'participant', 'active'),
(79, 69, 'leader', 'active'),
(79, 95, 'participant', 'active'),
(81, 76, 'participant', 'active'),
(82, 59, 'participant', 'active'),
(82, 63, 'participant', 'active'),
(82, 97, 'leader', 'active'),
(83, 20, 'leader', 'active'),
(85, 52, 'participant', 'active'),
(85, 70, 'leader', 'active'),
(85, 75, 'leader', 'active'),
(88, 30, 'leader', 'active'),
(88, 77, 'participant', 'active'),
(89, 32, 'leader', 'active'),
(89, 39, 'leader', 'active'),
(89, 61, 'leader', 'active'),
(89, 64, 'leader', 'active'),
(89, 77, 'leader', 'active'),
(90, 59, 'participant', 'active'),
(97, 60, 'leader', 'active'),
(98, 27, 'participant', 'active'),
(98, 87, 'leader', 'active'),
(99, 48, 'participant', 'active'),
(99, 52, 'participant', 'active'),
(100, 21, 'leader', 'active'),
(100, 67, 'leader', 'active');

--
-- Triggers `user_sustainability_campaign`
--
DELIMITER $$
CREATE TRIGGER `trg_prevent_duplicate_campaign_join` BEFORE INSERT ON `user_sustainability_campaign` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1
        FROM USER_SUSTAINABILITY_CAMPAIGN
        WHERE user_id = NEW.user_id AND campaign_id = NEW.campaign_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User already joined this campaign.';
    END IF;
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`);

--
-- Indexes for table `byn`
--
ALTER TABLE `byn`
  ADD PRIMARY KEY (`byn_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `campaign_id` (`campaign_id`);

--
-- Indexes for table `byn_location`
--
ALTER TABLE `byn_location`
  ADD PRIMARY KEY (`location_id`),
  ADD KEY `faculty_id` (`faculty_id`),
  ADD KEY `dept_id` (`dept_id`);

--
-- Indexes for table `faculty`
--
ALTER TABLE `faculty`
  ADD PRIMARY KEY (`faculty_id`);

--
-- Indexes for table `faculty_department`
--
ALTER TABLE `faculty_department`
  ADD PRIMARY KEY (`dept_id`),
  ADD KEY `faculty_id` (`faculty_id`);

--
-- Indexes for table `marketing`
--
ALTER TABLE `marketing`
  ADD PRIMARY KEY (`marketing_id`),
  ADD KEY `campaign_id` (`campaign_id`);

--
-- Indexes for table `pics`
--
ALTER TABLE `pics`
  ADD PRIMARY KEY (`pic_id`),
  ADD KEY `staff_id` (`staff_id`);

--
-- Indexes for table `pic_details`
--
ALTER TABLE `pic_details`
  ADD PRIMARY KEY (`pic_detail_id`),
  ADD KEY `campaign_id` (`campaign_id`),
  ADD KEY `pic_id` (`pic_id`);

--
-- Indexes for table `recyclebin`
--
ALTER TABLE `recyclebin`
  ADD PRIMARY KEY (`bin_id`),
  ADD KEY `location_id` (`location_id`);

--
-- Indexes for table `recyclingactivity`
--
ALTER TABLE `recyclingactivity`
  ADD PRIMARY KEY (`activity_id`),
  ADD KEY `campaign_id` (`campaign_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `verified_by` (`verified_by`);

--
-- Indexes for table `rewardredemption`
--
ALTER TABLE `rewardredemption`
  ADD PRIMARY KEY (`redemption_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `reward_id` (`reward_id`);

--
-- Indexes for table `reward_item`
--
ALTER TABLE `reward_item`
  ADD PRIMARY KEY (`reward_id`);

--
-- Indexes for table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`staff_id`),
  ADD KEY `dept_id` (`dept_id`),
  ADD KEY `faculty_id` (`faculty_id`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`stud_id`),
  ADD KEY `faculty_id` (`faculty_id`),
  ADD KEY `dept_id` (`dept_id`);

--
-- Indexes for table `sustainability_campaign`
--
ALTER TABLE `sustainability_campaign`
  ADD PRIMARY KEY (`campaign_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `sustainability_coordinator`
--
ALTER TABLE `sustainability_coordinator`
  ADD PRIMARY KEY (`staff_id`),
  ADD KEY `faculty_id` (`faculty_id`),
  ADD KEY `dept_id` (`dept_id`);

--
-- Indexes for table `user_sustainability_campaign`
--
ALTER TABLE `user_sustainability_campaign`
  ADD PRIMARY KEY (`campaign_id`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `byn`
--
ALTER TABLE `byn`
  ADD CONSTRAINT `byn_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `student` (`stud_id`),
  ADD CONSTRAINT `byn_ibfk_2` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`);

--
-- Constraints for table `byn_location`
--
ALTER TABLE `byn_location`
  ADD CONSTRAINT `byn_location_ibfk_1` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`),
  ADD CONSTRAINT `byn_location_ibfk_2` FOREIGN KEY (`dept_id`) REFERENCES `faculty_department` (`dept_id`);

--
-- Constraints for table `faculty_department`
--
ALTER TABLE `faculty_department`
  ADD CONSTRAINT `faculty_department_ibfk_1` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`);

--
-- Constraints for table `marketing`
--
ALTER TABLE `marketing`
  ADD CONSTRAINT `marketing_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`);

--
-- Constraints for table `pics`
--
ALTER TABLE `pics`
  ADD CONSTRAINT `pics_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`);

--
-- Constraints for table `pic_details`
--
ALTER TABLE `pic_details`
  ADD CONSTRAINT `pic_details_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`),
  ADD CONSTRAINT `pic_details_ibfk_2` FOREIGN KEY (`pic_id`) REFERENCES `pics` (`pic_id`);

--
-- Constraints for table `recyclebin`
--
ALTER TABLE `recyclebin`
  ADD CONSTRAINT `recyclebin_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `byn_location` (`location_id`);

--
-- Constraints for table `recyclingactivity`
--
ALTER TABLE `recyclingactivity`
  ADD CONSTRAINT `recyclingactivity_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`),
  ADD CONSTRAINT `recyclingactivity_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `student` (`stud_id`),
  ADD CONSTRAINT `recyclingactivity_ibfk_3` FOREIGN KEY (`verified_by`) REFERENCES `staff` (`staff_id`);

--
-- Constraints for table `rewardredemption`
--
ALTER TABLE `rewardredemption`
  ADD CONSTRAINT `rewardredemption_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `student` (`stud_id`),
  ADD CONSTRAINT `rewardredemption_ibfk_2` FOREIGN KEY (`reward_id`) REFERENCES `reward_item` (`reward_id`);

--
-- Constraints for table `staff`
--
ALTER TABLE `staff`
  ADD CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`dept_id`) REFERENCES `faculty_department` (`dept_id`),
  ADD CONSTRAINT `staff_ibfk_2` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`);

--
-- Constraints for table `student`
--
ALTER TABLE `student`
  ADD CONSTRAINT `student_ibfk_1` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`),
  ADD CONSTRAINT `student_ibfk_2` FOREIGN KEY (`dept_id`) REFERENCES `faculty_department` (`dept_id`);

--
-- Constraints for table `sustainability_campaign`
--
ALTER TABLE `sustainability_campaign`
  ADD CONSTRAINT `sustainability_campaign_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `staff` (`staff_id`);

--
-- Constraints for table `sustainability_coordinator`
--
ALTER TABLE `sustainability_coordinator`
  ADD CONSTRAINT `sustainability_coordinator_ibfk_1` FOREIGN KEY (`staff_id`) REFERENCES `staff` (`staff_id`),
  ADD CONSTRAINT `sustainability_coordinator_ibfk_2` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`),
  ADD CONSTRAINT `sustainability_coordinator_ibfk_3` FOREIGN KEY (`dept_id`) REFERENCES `faculty_department` (`dept_id`);

--
-- Constraints for table `user_sustainability_campaign`
--
ALTER TABLE `user_sustainability_campaign`
  ADD CONSTRAINT `user_sustainability_campaign_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `sustainability_campaign` (`campaign_id`),
  ADD CONSTRAINT `user_sustainability_campaign_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `student` (`stud_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
