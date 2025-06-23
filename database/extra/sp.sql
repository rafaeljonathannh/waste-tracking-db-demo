-- sp_redeem_reward
DELIMITER //

CREATE PROCEDURE sp_redeem_reward (
    IN p_user_id CHAR(12),
    IN p_reward_item_id CHAR(12)
)
BEGIN
    DECLARE v_user_status CHAR(8);
    DECLARE v_required_points INT;
    DECLARE v_discounted_points INT;
    DECLARE v_total_points INT;
    DECLARE v_reward_item_stock INT;

    -- 1. Get user status
    SET v_user_status = dapatkan_status_user(p_user_id);

    -- 2. Get reward item details
    SELECT points_required, stock INTO v_required_points, v_reward_item_stock
    FROM REWARD_ITEM
    WHERE id = p_reward_item_id;

    -- Check if reward item exists and is in stock
    IF v_required_points IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reward item not found.';
    END IF;

    IF v_reward_item_stock <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reward item is out of stock.';
    END IF;

    -- 3. Apply discount based on user status
    SET v_discounted_points = hitung_diskon_reward(v_user_status, v_required_points);

    -- 4. Get total available points from USERR table
    SELECT total_points INTO v_total_points
    FROM USERR
    WHERE id = p_user_id;

    -- 5. Check if sufficient points
    IF v_total_points IS NULL OR v_total_points < v_discounted_points THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Poin tidak cukup untuk penukaran.';
    END IF;

    -- 6. Deduct points directly from USERR table
    UPDATE USERR
    SET total_points = total_points - v_discounted_points
    WHERE id = p_user_id;

    -- 7. Insert redemption log
    -- Remove UUID() here; the trigger tg_rewardredemption_autogen_id will handle the ID.
    INSERT INTO REWARDREDEMPTION (user_id, reward_item_id, point_spent, redemption_date, status)
    VALUES (p_user_id, p_reward_item_id, v_discounted_points, NOW(), 'pending');
END;
//
DELIMITER ;

-- sp_laporkan_aktivitas_sampah
DELIMITER $$

CREATE PROCEDURE sp_laporkan_aktivitas_sampah(
    IN p_user_id CHAR(12),
    IN p_recycling_bin_id CHAR(12),
    IN p_waste_type_id CHAR(12),
    IN p_weight_kg DECIMAL(5,2),
    IN p_admin_id CHAR(12)
)
BEGIN
    INSERT INTO RECYCLING_ACTIVITY (
        weight_kg,
        points_earned,
        timestamp,
        verification_staff,
        admin_id,
        user_id,
        waste_type_id,
        recycling_bin_id
    )
    VALUES (
        p_weight_kg,
        0,
        NOW(),
        'pending',
        p_admin_id,
        p_user_id,
        p_waste_type_id,
        p_recycling_bin_id
    );
END$$

DELIMITER ;

-- sp_ikut_kampanye
DELIMITER $$

CREATE PROCEDURE sp_ikut_kampanye(
    IN p_user_id CHAR(12),
    IN p_sustainability_campaign_id CHAR(12)
)
BEGIN
    INSERT INTO USER_SUSTAINABILITY_CAMPAIGN(user_id, sustainability_campaign_id, status)
    VALUES (p_user_id, p_sustainability_campaign_id, 'active');
END$$

DELIMITER ;

-- sp_update_user_status
DELIMITER //

CREATE PROCEDURE sp_update_user_status(
    IN p_user_id CHAR(12)
)
BEGIN
    DECLARE v_last_activity DATETIME;

    -- Dapatkan waktu aktivitas daur ulang terakhir pengguna
    SELECT MAX(timestamp) INTO v_last_activity
    FROM RECYCLING_ACTIVITY
    WHERE user_id = p_user_id;

    -- Perbarui status pengguna di tabel USERR
    IF v_last_activity IS NULL OR v_last_activity < DATE_SUB(NOW(), INTERVAL 6 MONTH) THEN
        UPDATE USERR SET status = 'inactive' WHERE id = p_user_id;
    ELSE
        UPDATE USERR SET status = 'active' WHERE id = p_user_id;
    END IF;
END;
//
DELIMITER ;

-- sp_create_campaign_with_coordinator_check
DELIMITER //

CREATE PROCEDURE sp_create_campaign_with_coordinator_check(
    IN p_sustainability_coordinator_id CHAR(12),
    IN p_title VARCHAR(50),
    IN p_description VARCHAR(255),
    IN p_start_date DATETIME,
    IN p_end_date DATETIME,
    IN p_target_waste_reduction DECIMAL(6,2),
    IN p_bonus_points INT,
    IN p_status CHAR(9),
    IN p_staff_id CHAR(12)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM SUSTAINABILITY_COORDINATOR WHERE id = p_sustainability_coordinator_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid sustainability coordinator ID provided.';
    END IF;

    -- Masukkan kampanye baru
    INSERT INTO SUSTAINABILITY_CAMPAIGN(
        title,
        description,
        start_date,
        end_date,
        target_waste_reduction,
        bonus_points,
        status,
        created_by,
        sustainability_coordinator_id
    )
    VALUES (
        p_title,
        p_description,
        p_start_date,
        p_end_date,
        p_target_waste_reduction,
        p_bonus_points,
        p_status,
        p_staff_id,
        p_sustainability_coordinator_id
    );
END;
//
DELIMITER ;

-- sp_generate_user_summary
DELIMITER //

CREATE PROCEDURE sp_generate_user_summary(
    IN p_user_id CHAR(12)
)
BEGIN
    SELECT
        hitung_total_poin_user(p_user_id) AS total_points,
        hitung_jumlah_kampanye_diikuti(p_user_id) AS total_campaigns_joined,
        hitung_total_sampah_disetor(p_user_id) AS total_waste_kg,
        hitung_jumlah_reward_ditukar(p_user_id) AS total_rewards_redeemed,
        dapatkan_status_user(p_user_id) AS status;
END;
//
DELIMITER ;

-- sp_add_recycling_bin
DELIMITER //

CREATE PROCEDURE sp_add_recycling_bin(
    IN p_bin_location_id CHAR(12),
    IN p_capacity_kg DECIMAL(5,2),
    IN p_qr_code VARCHAR(100)
)
BEGIN
    DECLARE v_total_capacity DECIMAL(6,2);

    SET v_total_capacity = hitung_kapasitas_total_lokasi(p_bin_location_id);

    IF (v_total_capacity + p_capacity_kg) > 1000.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total kapasitas di lokasi ini akan melebihi 1000 kg.';
    END IF;

    INSERT INTO RECYCLING_BIN(
        capacity_kg,
        status,
        last_emptied,
        qr_code,
        bin_location_id
    )
    VALUES (
        p_capacity_kg,
        'available',
        NOW(),
        p_qr_code,
        p_bin_location_id
    );
END;
//
DELIMITER ;

-- sp_complete_redemption 
DELIMITER //

CREATE PROCEDURE sp_complete_redemption(
    IN p_redemption_id CHAR(12)
)
BEGIN
    DECLARE v_item_id CHAR(12);

    SELECT reward_item_id INTO v_item_id
    FROM REWARDREDEMPTION
    WHERE id = p_redemption_id AND status = 'pending';

    IF v_item_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID Penukaran tidak valid atau sudah diproses.';
    END IF;

    -- Tandai penukaran sebagai 'completed' dan set tanggal proses
    UPDATE REWARDREDEMPTION
    SET status = 'processed',
        processed_date = NOW()
    WHERE id = p_redemption_id;
END;
//
DELIMITER ;

-- sp_verifikasi_aktivitas 
DELIMITER //

CREATE PROCEDURE sp_verifikasi_aktivitas(
    IN p_recycling_activity_id CHAR(12)
)
BEGIN
    DECLARE v_current_status CHAR(8);

    START TRANSACTION;

    SELECT verification_staff INTO v_current_status
    FROM RECYCLING_ACTIVITY
    WHERE id = p_recycling_activity_id
    FOR UPDATE;

    IF v_current_status IS NULL THEN
        ROLLBACK;
    ELSEIF v_current_status = 'verified' THEN
        ROLLBACK;
    ELSE
        UPDATE RECYCLING_ACTIVITY
        SET verification_staff = 'verified'
        WHERE id = p_recycling_activity_id;

        COMMIT;
    END IF;
END;
//

DELIMITER ;

-- sp_tambah_stok_reward 
DELIMITER //

CREATE PROCEDURE sp_tambah_stok_reward(
    IN p_reward_id_item CHAR(12),
    IN p_tambahan_stok INT
)
BEGIN
    DECLARE v_stok_sekarang INT;

    START TRANSACTION;

    SELECT stock INTO v_stok_sekarang
    FROM REWARD_ITEM
    WHERE id = p_reward_id_item
    FOR UPDATE;

    IF v_stok_sekarang IS NULL THEN
        ROLLBACK;
    ELSE
        UPDATE REWARD_ITEM
        SET stock = stock + p_tambahan_stok
        WHERE id = p_reward_id_item;

        COMMIT;
    END IF;
END;
//

DELIMITER ;