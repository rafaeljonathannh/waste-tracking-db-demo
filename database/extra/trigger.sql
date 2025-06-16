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
AFTER INSERT ON RECYCLING_ACTIVITY
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
AFTER INSERT ON REWARDREDEMPTION
FOR EACH ROW
BEGIN
    IF NEW.status = 'processed' THEN
        UPDATE REWARD_ITEM
        SET stock = stock - 1
        WHERE id = NEW.reward_item_id;
    END IF;
END$$

DELIMITER ;
