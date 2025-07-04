-- trg_verifikasi_aktivitas_to_poin
DELIMITER $$

CREATE TRIGGER trg_verifikasi_aktivitas_to_poin
AFTER UPDATE ON RECYCLING_ACTIVITY
FOR EACH ROW
BEGIN
    DECLARE v_points_earned INT;

    IF OLD.verification_staff != 'verified' AND NEW.verification_staff = 'verified' THEN
        SET v_points_earned = konversi_berat_ke_poin(NEW.weight_kg);

        INSERT INTO POINTS (
            description,
            point,
            when_earn,
            status,
            user_id,
            recycling_activity_id
        )
        VALUES (
            'Poin didapat dari aktivitas daur ulang yang diverifikasi', 
            v_points_earned,                                           
            NOW(),                                                    
            'earned',                                                
            NEW.user_id,                                             
            NEW.id                                                     
        );

        UPDATE USERR
        SET total_points = total_points + v_points_earned
        WHERE id = NEW.user_id;
    END IF;
END$$

DELIMITER ;

-- trg_reward_item_stock_status
DELIMITER $$

CREATE TRIGGER trg_reward_item_stock_status
BEFORE UPDATE ON REWARD_ITEM
FOR EACH ROW
BEGIN
    IF NEW.stock = 0 AND OLD.stock > 0 THEN
        SET NEW.status = 'out_of_stock';
    ELSEIF NEW.stock > 0 AND OLD.stock = 0 AND OLD.status = 'out_of_stock' THEN
        SET NEW.status = 'available'; 
    END IF;
END$$

DELIMITER ;

-- trg_prevent_duplicate_campaign_join
DELIMITER $$

CREATE TRIGGER trg_prevent_duplicate_campaign_join
BEFORE INSERT ON USER_SUSTAINABILITY_CAMPAIGN
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM USER_SUSTAINABILITY_CAMPAIGN
        WHERE user_id = NEW.user_id
          AND sustainability_campaign_id = NEW.sustainability_campaign_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User already joined this campaign.';
    END IF;
END$$

DELIMITER ;


-- trg_auto_set_student_active_on_activity
DELIMITER $$

CREATE TRIGGER trg_auto_set_student_active_on_activity
AFTER UPDATE ON RECYCLING_ACTIVITY
FOR EACH ROW
BEGIN
    IF NEW.verification_staff = 'verified' THEN
        UPDATE USERR 
        SET status = 'active'
        WHERE id = NEW.user_id;
    END IF;
END$$

DELIMITER ;

-- trg_decrease_reward_stock_after_redemption
DELIMITER $$

CREATE TRIGGER trg_decrease_reward_stock_after_redemption
AFTER UPDATE ON REWARDREDEMPTION
FOR EACH ROW
BEGIN
    IF NEW.status = 'processed' THEN
        UPDATE REWARD_ITEM
        SET stock = stock - 1
        WHERE id = NEW.reward_item_id;
    END IF;
END$$

DELIMITER ;


-- Trigger for auto assign id

DELIMITER $$
-- Trigger for FACULTY table
CREATE TRIGGER tg_faculty_autogen_id BEFORE INSERT ON FACULTY
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 2) AS UNSIGNED)), 0) INTO last_num 
        FROM FACULTY 
        WHERE id REGEXP '^F[0-9]+$';
        
        SET NEW.id = CONCAT('F', LPAD(last_num + 1, 3, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for FACULTY_DEPARTMENT table
CREATE TRIGGER tg_faculty_department_autogen_id BEFORE INSERT ON FACULTY_DEPARTMENT
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 3) AS UNSIGNED)), 0) INTO last_num 
        FROM FACULTY_DEPARTMENT 
        WHERE id REGEXP '^FD[0-9]+$';
        
        SET NEW.id = CONCAT('FD', LPAD(last_num + 1, 3, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for STAFF table
CREATE TRIGGER tg_staff_autogen_id BEFORE INSERT ON STAFF
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM STAFF 
        WHERE id REGEXP '^STF[0-9]+$';
        
        SET NEW.id = CONCAT('STF', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for SUSTAINABILITY_COORDINATOR table
CREATE TRIGGER tg_sustainability_coordinator_autogen_id BEFORE INSERT ON SUSTAINABILITY_COORDINATOR
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM SUSTAINABILITY_COORDINATOR 
        WHERE id REGEXP '^COO[0-9]+$';
        
        SET NEW.id = CONCAT('COO', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for SUSTAINABILITY_CAMPAIGN table
CREATE TRIGGER tg_sustainability_campaign_autogen_id BEFORE INSERT ON SUSTAINABILITY_CAMPAIGN
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM SUSTAINABILITY_CAMPAIGN 
        WHERE id REGEXP '^CMP[0-9]+$';
        
        SET NEW.id = CONCAT('CMP', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for USERR table
CREATE TRIGGER tg_userr_autogen_id BEFORE INSERT ON USERR
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM USERR 
        WHERE id REGEXP '^USR[0-9]+$';
        
        SET NEW.id = CONCAT('USR', LPAD(last_num + 1, 4, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for USER_SUSTAINABILITY_CAMPAIGN table
CREATE TRIGGER tg_user_sustainability_campaign_autogen_id BEFORE INSERT ON USER_SUSTAINABILITY_CAMPAIGN
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM USER_SUSTAINABILITY_CAMPAIGN 
        WHERE id REGEXP '^USC[0-9]+$';
        
        SET NEW.id = CONCAT('USC', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for BIN_TYPE table
CREATE TRIGGER tg_bin_type_autogen_id BEFORE INSERT ON BIN_TYPE
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM BIN_TYPE 
        WHERE id REGEXP '^BNT[0-9]+$';
        
        SET NEW.id = CONCAT('BNT', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for BIN_LOCATION table
CREATE TRIGGER tg_bin_location_autogen_id BEFORE INSERT ON BIN_LOCATION
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM BIN_LOCATION 
        WHERE id REGEXP '^LOC[0-9]+$';
        
        SET NEW.id = CONCAT('LOC', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for RECYCLING_BIN table
CREATE TRIGGER tg_recycling_bin_autogen_id BEFORE INSERT ON RECYCLING_BIN
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM RECYCLING_BIN 
        WHERE id REGEXP '^RCB[0-9]+$';
        
        SET NEW.id = CONCAT('RCB', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for STAFF_RECYCLING_BIN table
CREATE TRIGGER tg_staff_recycling_bin_autogen_id BEFORE INSERT ON STAFF_RECYCLING_BIN
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM STAFF_RECYCLING_BIN 
        WHERE id REGEXP '^SRB[0-9]+$';
        
        SET NEW.id = CONCAT('SRB', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for ADMIN table
CREATE TRIGGER tg_admin_autogen_id BEFORE INSERT ON ADMIN
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM ADMIN 
        WHERE id REGEXP '^ADM[0-9]+$';
        
        SET NEW.id = CONCAT('ADM', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for WASTE_TYPE table
CREATE TRIGGER tg_waste_type_autogen_id BEFORE INSERT ON WASTE_TYPE
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM WASTE_TYPE 
        WHERE id REGEXP '^WST[0-9]+$';
        
        SET NEW.id = CONCAT('WST', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for RECYCLING_ACTIVITY table
CREATE TRIGGER tg_recycling_activity_autogen_id BEFORE INSERT ON RECYCLING_ACTIVITY
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM RECYCLING_ACTIVITY 
        WHERE id REGEXP '^RAC[0-9]+$';
        
        SET NEW.id = CONCAT('RAC', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for REWARD_ITEM table
CREATE TRIGGER tg_reward_item_autogen_id BEFORE INSERT ON REWARD_ITEM
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM REWARD_ITEM 
        WHERE id REGEXP '^RWD[0-9]+$';
        
        SET NEW.id = CONCAT('RWD', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;

DELIMITER $$
-- Trigger for REWARDREDEMPTION table
CREATE TRIGGER tg_rewardredemption_autogen_id BEFORE INSERT ON REWARDREDEMPTION
FOR EACH ROW
BEGIN
    DECLARE last_num INT DEFAULT 0;
    
    IF (NEW.id IS NULL OR NEW.id = '') THEN
        SELECT IFNULL(MAX(CAST(SUBSTRING(id, 4) AS UNSIGNED)), 0) INTO last_num 
        FROM REWARDREDEMPTION 
        WHERE id REGEXP '^RDM[0-9]+$';
        
        SET NEW.id = CONCAT('RDM', LPAD(last_num + 1, 9, '0'));
    END IF;
END$$
DELIMITER ;