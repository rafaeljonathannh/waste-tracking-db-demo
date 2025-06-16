-- sp_redeem_reward
DELIMITER //

CREATE PROCEDURE sp_redeem_reward (
    IN p_user_id INT,
    IN p_reward_id INT
)
BEGIN
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
END;
//
DELIMITER ;

-- sp_laporkan_aktivitas_sampah
DELIMITER $$

CREATE PROCEDURE sp_laporkan_aktivitas_sampah(
    IN p_user_id INT,
    IN p_bin_id INT,
    IN p_weight DECIMAL(5,2),
    IN p_status ENUM('pending', 'verified')
)
BEGIN
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

DELIMITER ;

-- sp_ikut_kampanye
DELIMITER $$

CREATE PROCEDURE sp_ikut_kampanye(
    IN p_user_id INT,
    IN p_campaign_id INT
)
BEGIN
    IF ikut_kampanye(p_user_id, p_campaign_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mahasiswa sudah terdaftar di kampanye ini.';
    ELSE
        INSERT INTO USER_SUSTAINABILITY_CAMPAIGN(user_id, campaign_id, status)
        VALUES (p_user_id, p_campaign_id, 'active');
    END IF;
END$$

DELIMITER ;

-- sp_update_student_status
DELIMITER //

CREATE PROCEDURE sp_update_student_status(
    IN p_user_id INT
)
BEGIN
    DECLARE v_last_activity TIMESTAMP;

    SELECT MAX(timestamp) INTO v_last_activity
    FROM RECYCLINGACTIVITY
    WHERE user_id = p_user_id;

    IF v_last_activity IS NULL OR v_last_activity < DATE_SUB(NOW(), INTERVAL 6 MONTH) THEN
        UPDATE STUDENT SET status = 'inactive' WHERE stud_id = p_user_id;
    ELSE
        UPDATE STUDENT SET status = 'active' WHERE stud_id = p_user_id;
    END IF;
END;
//
DELIMITER ;

-- sp_create_campaign_with_coordinator_check
DELIMITER //

CREATE PROCEDURE sp_create_campaign_with_coordinator_check(
    IN p_staff_id INT,
    IN p_faculty_id INT,
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_count INT;

    SET v_count = jumlah_koordinator_fakultas(p_faculty_id);

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Faculty must have at least one coordinator.';
    END IF;

    INSERT INTO SUSTAINABILITY_CAMPAIGN(name, description, start_date, end_date, created_by)
    VALUES (p_name, p_description, p_start_date, p_end_date, p_staff_id);
END;
//
DELIMITER ;

-- sp_generate_student_summary
DELIMITER //

CREATE PROCEDURE sp_generate_student_summary(IN p_user_id INT)
BEGIN
    SELECT 
        total_poin_mahasiswa(p_user_id) AS total_points,
        jumlah_kampanye_mahasiswa(p_user_id) AS total_campaigns_joined,
        total_sampah_disetor(p_user_id) AS total_waste_kg,
        jumlah_reward_ditukar(p_user_id) AS total_rewards_redeemed,
        status_mahasiswa(p_user_id) AS status;
END;
//
DELIMITER ;

-- sp_add_bin_check_capacity
DELIMITER //

CREATE PROCEDURE sp_add_bin_check_capacity(
    IN p_location_id INT,
    IN p_capacity_kg DECIMAL(6,2),
    IN p_bin_code VARCHAR(50)
)
BEGIN
    DECLARE v_total_capacity DECIMAL(10,2);

    SET v_total_capacity = kapasitas_total_tempat_sampah(p_location_id);

    IF (v_total_capacity + p_capacity_kg) > 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total capacity in this location would exceed 1000 kg.';
    END IF;

    INSERT INTO RECYCLEBIN(location_id, capacity_kg, bin_code)
    VALUES (p_location_id, p_capacity_kg, p_bin_code);
END;
//
DELIMITER ;

-- sp_complete_redemption
DELIMITER //

CREATE PROCEDURE sp_complete_redemption(IN p_redemption_id INT)
BEGIN
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
END;
//
DELIMITER ;
