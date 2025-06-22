<?php
// api/helpers/DatabaseHelper.php
class DatabaseHelper {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    /**
     * Get waste types for dropdown
     */
    public function getWasteTypes() {
        $stmt = $this->db->prepare("
            SELECT id, waste_type_name, points_per_kg, description
            FROM WASTE_TYPE 
            WHERE status = 'active'
            ORDER BY waste_type_name
        ");
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Get recycling bins with locations
     */
    public function getRecyclingBins($faculty_id = null) {
        $sql = "
            SELECT rb.id, rb.qr_code, rb.capacity_kg, rb.status,
                   bl.description as location_desc, bl.floor,
                   bt.name as bin_type_name, bt.color_code,
                   f.name as faculty_name
            FROM RECYCLING_BIN rb
            JOIN BIN_LOCATION bl ON rb.bin_location_id = bl.id
            JOIN BIN_TYPE bt ON bl.bin_type_id = bt.id
            JOIN FACULTY f ON bl.faculty_id = f.id
            WHERE rb.status = 'available'
        ";
        
        $params = [];
        if ($faculty_id) {
            $sql .= " AND bl.faculty_id = ?";
            $params[] = $faculty_id;
        }
        
        $sql .= " ORDER BY f.name, bl.floor, bl.description";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Check if user can redeem reward (with discount calculation)
     */
    public function canRedeemReward($user_id, $reward_id) {
        // Get user status and total points
        $stmt = $this->db->prepare("
            SELECT status, total_points 
            FROM USERR 
            WHERE id = ?
        ");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            return ['can_redeem' => false, 'reason' => 'User not found'];
        }
        
        // Get reward details
        $stmt = $this->db->prepare("
            SELECT points_required, stock, status 
            FROM REWARD_ITEM 
            WHERE id = ?
        ");
        $stmt->execute([$reward_id]);
        $reward = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$reward || $reward['status'] !== 'available') {
            return ['can_redeem' => false, 'reason' => 'Reward not available'];
        }
        
        if ($reward['stock'] <= 0) {
            return ['can_redeem' => false, 'reason' => 'Out of stock'];
        }
        
        // Calculate discounted points using the database function
        $stmt = $this->db->prepare("SELECT hitung_diskon_reward(?, ?) as discounted_points");
        $stmt->execute([$user['status'], $reward['points_required']]);
        $discountedPoints = $stmt->fetchColumn();
        
        if ($user['total_points'] < $discountedPoints) {
            return [
                'can_redeem' => false, 
                'reason' => 'Insufficient points',
                'required' => $discountedPoints,
                'available' => $user['total_points'],
                'discount' => $reward['points_required'] - $discountedPoints
            ];
        }
        
        return [
            'can_redeem' => true,
            'required' => $discountedPoints,
            'original_price' => $reward['points_required'],
            'discount' => $reward['points_required'] - $discountedPoints
        ];
    }
    
    /**
     * Get user's campaign participation
     */
    public function getUserCampaigns($user_id) {
        $stmt = $this->db->prepare("
            SELECT sc.*, usc.status as participation_status,
                   COUNT(all_usc.user_id) as total_participants
            FROM SUSTAINABILITY_CAMPAIGN sc
            LEFT JOIN USER_SUSTAINABILITY_CAMPAIGN usc ON sc.id = usc.sustainability_campaign_id AND usc.user_id = ?
            LEFT JOIN USER_SUSTAINABILITY_CAMPAIGN all_usc ON sc.id = all_usc.sustainability_campaign_id
            WHERE sc.status = 'active'
            GROUP BY sc.id
            ORDER BY usc.status DESC, sc.start_date DESC
        ");
        $stmt->execute([$user_id]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Get recent activities for dashboard
     */
    public function getRecentActivities($user_id, $limit = 5) {
        $stmt = $this->db->prepare("
            SELECT ra.*, wt.waste_type_name, wt.points_per_kg,
                   bl.description as location, f.name as faculty_name
            FROM RECYCLING_ACTIVITY ra
            JOIN WASTE_TYPE wt ON ra.waste_type_id = wt.id
            JOIN RECYCLING_BIN rb ON ra.recycling_bin_id = rb.id
            JOIN BIN_LOCATION bl ON rb.bin_location_id = bl.id
            JOIN FACULTY f ON bl.faculty_id = f.id
            WHERE ra.user_id = ?
            ORDER BY ra.timestamp DESC
            LIMIT ?
        ");
        $stmt->execute([$user_id, $limit]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Get leaderboard for dashboard
     */
    public function getLeaderboard($limit = 10) {
        $stmt = $this->db->prepare("
            SELECT u.name, u.faculty_id, u.total_points,
                   f.name as faculty_name,
                   COUNT(ra.id) as total_activities
            FROM USERR u
            LEFT JOIN FACULTY f ON u.faculty_id = f.id
            LEFT JOIN RECYCLING_ACTIVITY ra ON u.id = ra.user_id AND ra.verification_staff = 'verified'
            WHERE u.status = 'active'
            GROUP BY u.id
            ORDER BY u.total_points DESC
            LIMIT ?
        ");
        $stmt->execute([$limit]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

// api/websocket.php - Simple real-time updates
class RealTimeUpdater {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    /**
     * Check for recent updates for a user
     */
    public function checkUpdates($user_id, $last_check = null) {
        $updates = [];
        
        if (!$last_check) {
            $last_check = date('Y-m-d H:i:s', strtotime('-1 minute'));
        }
        
        // Check for new points
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as new_points
            FROM RECYCLING_ACTIVITY 
            WHERE user_id = ? 
            AND verification_staff = 'verified'
            AND timestamp > ?
        ");
        $stmt->execute([$user_id, $last_check]);
        $newPoints = $stmt->fetchColumn();
        
        if ($newPoints > 0) {
            $updates[] = [
                'type' => 'points_updated',
                'message' => "You earned points from $newPoints verified activities!",
                'count' => $newPoints
            ];
        }
        
        // Check for reward stock updates
        $stmt = $this->db->prepare("
            SELECT ri.name, ri.stock
            FROM REWARD_ITEM ri
            WHERE ri.stock > 0 
            AND ri.stock < 5
            AND ri.status = 'available'
        ");
        $stmt->execute();
        $lowStockRewards = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($lowStockRewards as $reward) {
            $updates[] = [
                'type' => 'low_stock',
                'message' => "Hurry! Only {$reward['stock']} {$reward['name']} left!",
                'reward_name' => $reward['name'],
                'stock' => $reward['stock']
            ];
        }
        
        // Check for new campaigns
        $stmt = $this->db->prepare("
            SELECT sc.title, sc.description
            FROM SUSTAINABILITY_CAMPAIGN sc
            LEFT JOIN USER_SUSTAINABILITY_CAMPAIGN usc ON sc.id = usc.sustainability_campaign_id AND usc.user_id = ?
            WHERE sc.status = 'active'
            AND sc.start_date > ?
            AND usc.user_id IS NULL
        ");
        $stmt->execute([$user_id, $last_check]);
        $newCampaigns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($newCampaigns as $campaign) {
            $updates[] = [
                'type' => 'new_campaign',
                'message' => "New campaign available: {$campaign['title']}",
                'campaign_title' => $campaign['title']
            ];
        }
        
        return [
            'timestamp' => date('Y-m-d H:i:s'),
            'updates' => $updates,
            'has_updates' => !empty($updates)
        ];
    }
    
    /**
     * Get current user stats for real-time dashboard
     */
    public function getCurrentStats($user_id) {
        // Get updated total points
        $stmt = $this->db->prepare("SELECT total_points FROM USERR WHERE id = ?");
        $stmt->execute([$user_id]);
        $totalPoints = $stmt->fetchColumn();
        
        // Get today's activities
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as today_activities,
                   COALESCE(SUM(points_earned), 0) as today_points
            FROM RECYCLING_ACTIVITY 
            WHERE user_id = ? 
            AND DATE(timestamp) = CURDATE()
        ");
        $stmt->execute([$user_id]);
        $todayStats = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Get pending activities
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as pending_activities
            FROM RECYCLING_ACTIVITY 
            WHERE user_id = ? 
            AND verification_staff = 'pending'
        ");
        $stmt->execute([$user_id]);
        $pendingActivities = $stmt->fetchColumn();
        
        return [
            'total_points' => (int)$totalPoints,
            'today_activities' => (int)$todayStats['today_activities'],
            'today_points' => (int)$todayStats['today_points'],
            'pending_activities' => (int)$pendingActivities
        ];
    }
}

// api/endpoints/extended.php - Additional endpoints
class ExtendedAPI extends StudentAPI {
    private $helper;
    private $realtime;
    
    public function __construct() {
        parent::__construct();
        $this->helper = new DatabaseHelper($this->db);
        $this->realtime = new RealTimeUpdater($this->db);
    }
    
    /**
     * GET /api/waste-types - Get available waste types
     */
    public function getWasteTypes() {
        $wasteTypes = $this->helper->getWasteTypes();
        $this->sendResponse(200, $wasteTypes);
    }
    
    /**
     * GET /api/recycling-bins?faculty_id={id} - Get recycling bins
     */
    public function getRecyclingBins() {
        $facultyId = $_GET['faculty_id'] ?? null;
        $bins = $this->helper->getRecyclingBins($facultyId);
        $this->sendResponse(200, $bins);
    }
    
    /**
     * POST /api/check-reward - Check if user can redeem reward
     */
    public function checkReward() {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['user_id']) || !isset($data['reward_id'])) {
            $this->sendResponse(400, ['error' => 'Missing user_id or reward_id']);
            return;
        }
        
        $result = $this->helper->canRedeemReward($data['user_id'], $data['reward_id']);
        $this->sendResponse(200, $result);
    }
    
    /**
     * GET /api/leaderboard - Get points leaderboard
     */
    public function getLeaderboard() {
        $limit = $_GET['limit'] ?? 10;
        $leaderboard = $this->helper->getLeaderboard($limit);
        $this->sendResponse(200, $leaderboard);
    }
    
    /**
     * GET /api/realtime/{user_id} - Check for real-time updates
     */
    public function getRealTimeUpdates($user_id) {
        $lastCheck = $_GET['last_check'] ?? null;
        $updates = $this->realtime->checkUpdates($user_id, $lastCheck);
        $this->sendResponse(200, $updates);
    }
    
    /**
     * GET /api/live-stats/{user_id} - Get current live stats
     */
    public function getLiveStats($user_id) {
        $stats = $this->realtime->getCurrentStats($user_id);
        $this->sendResponse(200, $stats);
    }
}

// api/mock-data.php - Mock data untuk testing
class MockDataGenerator {
    private $db;
    
    public function __construct($database) {
        $this->db = $database;
    }
    
    /**
     * Generate sample data untuk testing dashboard
     */
    public function generateMockData() {
        // Sample waste types
        $wasteTypes = [
            ['id' => 'WT001', 'name' => 'Plastik', 'points_per_kg' => 10],
            ['id' => 'WT002', 'name' => 'Kertas', 'points_per_kg' => 8],
            ['id' => 'WT003', 'name' => 'Logam', 'points_per_kg' => 15],
            ['id' => 'WT004', 'name' => 'Kaca', 'points_per_kg' => 12],
            ['id' => 'WT005', 'name' => 'Organik', 'points_per_kg' => 5]
        ];
        
        // Sample rewards
        $rewards = [
            ['id' => 'RW001', 'name' => 'Tumbler Eco-Friendly', 'points' => 500, 'stock' => 12],
            ['id' => 'RW002', 'name' => 'Tote Bag Sustainability', 'points' => 300, 'stock' => 8],
            ['id' => 'RW003', 'name' => 'Voucher Kantin Rp.50k', 'points' => 800, 'stock' => 5],
            ['id' => 'RW004', 'name' => 'Power Bank Solar', 'points' => 1200, 'stock' => 3],
            ['id' => 'RW005', 'name' => 'Notebook Daur Ulang', 'points' => 200, 'stock' => 15]
        ];
        
        // Sample campaigns
        $campaigns = [
            ['id' => 'CP001', 'title' => 'Plastic Free June', 'participants' => 156],
            ['id' => 'CP002', 'title' => 'Paper Recycling Challenge', 'participants' => 89],
            ['id' => 'CP003', 'title' => 'Zero Waste Week', 'participants' => 203]
        ];
        
        return [
            'waste_types' => $wasteTypes,
            'rewards' => $rewards,
            'campaigns' => $campaigns,
            'message' => 'Mock data generated for testing'
        ];
    }
}
?>