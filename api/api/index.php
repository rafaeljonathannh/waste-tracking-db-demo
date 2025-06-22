<?php
// api/index.php - Main API Router
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../src/config/database.php';

class StudentAPI {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    public function handleRequest() {
        $method = $_SERVER['REQUEST_METHOD'];
        $path = trim($_SERVER['REQUEST_URI'], '/');
        $segments = explode('/', $path);
        
        // Remove 'api' from segments if present
        if ($segments[0] === 'api') {
            array_shift($segments);
        }
        
        $endpoint = $segments[0] ?? '';
        $id = $segments[1] ?? null;
        
        try {
            switch ($endpoint) {
                case 'user':
                    $this->handleUser($method, $id);
                    break;
                case 'recycling-activities':
                    $this->handleRecyclingActivities($method, $id);
                    break;
                case 'rewards':
                    $this->handleRewards($method, $id);
                    break;
                case 'campaigns':
                    $this->handleCampaigns($method, $id);
                    break;
                case 'stats':
                    $this->handleStats($method, $id);
                    break;
                default:
                    $this->sendResponse(404, ['error' => 'Endpoint not found']);
            }
        } catch (Exception $e) {
            $this->sendResponse(500, ['error' => $e->getMessage()]);
        }
    }
    
    // GET /api/user/{id} - Get user profile and total points
    private function handleUser($method, $id) {
        if ($method === 'GET' && $id) {
            $stmt = $this->db->prepare("
                SELECT u.*, 
                       COALESCE(u.total_points, 0) as total_points,
                       f.name as faculty_name,
                       fd.name as department_name
                FROM USERR u 
                LEFT JOIN FACULTY f ON u.faculty_id = f.id
                LEFT JOIN FACULTY_DEPARTMENT fd ON u.dept_id = fd.id
                WHERE u.id = ?
            ");
            $stmt->execute([$id]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($user) {
                // Calculate additional stats
                $stats = $this->getUserStats($id);
                $user['stats'] = $stats;
                $this->sendResponse(200, $user);
            } else {
                $this->sendResponse(404, ['error' => 'User not found']);
            }
        } else {
            $this->sendResponse(405, ['error' => 'Method not allowed']);
        }
    }
    
    // GET /api/recycling-activities/{user_id} - Get user's recycling activities
    // POST /api/recycling-activities - Create new activity
    private function handleRecyclingActivities($method, $user_id) {
        if ($method === 'GET' && $user_id) {
            $stmt = $this->db->prepare("
                SELECT ra.*, 
                       wt.waste_type_name,
                       wt.points_per_kg,
                       bl.description as bin_location,
                       f.name as faculty_name
                FROM RECYCLING_ACTIVITY ra
                JOIN WASTE_TYPE wt ON ra.waste_type_id = wt.id
                JOIN RECYCLING_BIN rb ON ra.recycling_bin_id = rb.id
                JOIN BIN_LOCATION bl ON rb.bin_location_id = bl.id
                JOIN FACULTY f ON bl.faculty_id = f.id
                WHERE ra.user_id = ?
                ORDER BY ra.timestamp DESC
                LIMIT 50
            ");
            $stmt->execute([$user_id]);
            $activities = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $this->sendResponse(200, $activities);
            
        } elseif ($method === 'POST') {
            $data = json_decode(file_get_contents('php://input'), true);
            
            // Validate required fields
            $required = ['user_id', 'recycling_bin_id', 'waste_type_id', 'weight_kg'];
            foreach ($required as $field) {
                if (!isset($data[$field])) {
                    $this->sendResponse(400, ['error' => "Missing required field: $field"]);
                    return;
                }
            }
            
            try {
                // Call stored procedure to add activity
                $stmt = $this->db->prepare("
                    CALL sp_laporkan_aktivitas_sampah(?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([
                    $data['user_id'],
                    $data['recycling_bin_id'],
                    $data['waste_type_id'],
                    $data['weight_kg'],
                    $data['admin_id'] ?? 'ADMIN001',
                    $data['verification_status'] ?? 'pending'
                ]);
                
                $this->sendResponse(201, ['message' => 'Activity recorded successfully']);
                
            } catch (PDOException $e) {
                $this->sendResponse(500, ['error' => 'Failed to record activity: ' . $e->getMessage()]);
            }
        } else {
            $this->sendResponse(405, ['error' => 'Method not allowed']);
        }
    }
    
    // GET /api/rewards - Get available rewards
    // POST /api/rewards/redeem - Redeem reward
    private function handleRewards($method, $id) {
        if ($method === 'GET') {
            if ($id === 'redeem') {
                // Handle POST to redeem endpoint
                $this->redeemReward();
            } else {
                // Get all available rewards
                $stmt = $this->db->prepare("
                    SELECT * FROM REWARD_ITEM 
                    WHERE status = 'available' AND stock > 0
                    ORDER BY points_required ASC
                ");
                $stmt->execute();
                $rewards = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $this->sendResponse(200, $rewards);
            }
        } elseif ($method === 'POST' && $id === 'redeem') {
            $this->redeemReward();
        } else {
            $this->sendResponse(405, ['error' => 'Method not allowed']);
        }
    }
    
    private function redeemReward() {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['user_id']) || !isset($data['reward_item_id'])) {
            $this->sendResponse(400, ['error' => 'Missing user_id or reward_item_id']);
            return;
        }
        
        try {
            $stmt = $this->db->prepare("CALL sp_redeem_reward(?, ?)");
            $stmt->execute([$data['user_id'], $data['reward_item_id']]);
            
            $this->sendResponse(200, ['message' => 'Reward redeemed successfully']);
            
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'tidak cukup') !== false) {
                $this->sendResponse(400, ['error' => 'Insufficient points']);
            } elseif (strpos($e->getMessage(), 'out of stock') !== false) {
                $this->sendResponse(400, ['error' => 'Reward out of stock']);
            } else {
                $this->sendResponse(500, ['error' => 'Failed to redeem reward: ' . $e->getMessage()]);
            }
        }
    }
    
    // GET /api/campaigns - Get active campaigns
    // POST /api/campaigns/join - Join campaign
    private function handleCampaigns($method, $id) {
        if ($method === 'GET') {
            if ($id === 'join') {
                $this->sendResponse(405, ['error' => 'Use POST method to join campaigns']);
            } else {
                $stmt = $this->db->prepare("
                    SELECT sc.*, 
                           COUNT(usc.user_id) as participants
                    FROM SUSTAINABILITY_CAMPAIGN sc
                    LEFT JOIN USER_SUSTAINABILITY_CAMPAIGN usc ON sc.id = usc.sustainability_campaign_id
                    WHERE sc.status = 'active'
                    GROUP BY sc.id
                    ORDER BY sc.start_date DESC
                ");
                $stmt->execute();
                $campaigns = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                $this->sendResponse(200, $campaigns);
            }
        } elseif ($method === 'POST' && $id === 'join') {
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['user_id']) || !isset($data['campaign_id'])) {
                $this->sendResponse(400, ['error' => 'Missing user_id or campaign_id']);
                return;
            }
            
            try {
                $stmt = $this->db->prepare("CALL sp_ikut_kampanye(?, ?)");
                $stmt->execute([$data['user_id'], $data['campaign_id']]);
                
                $this->sendResponse(200, ['message' => 'Successfully joined campaign']);
                
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate') !== false) {
                    $this->sendResponse(400, ['error' => 'Already joined this campaign']);
                } else {
                    $this->sendResponse(500, ['error' => 'Failed to join campaign: ' . $e->getMessage()]);
                }
            }
        } else {
            $this->sendResponse(405, ['error' => 'Method not allowed']);
        }
    }
    
    // GET /api/stats/{user_id} - Get user statistics
    private function handleStats($method, $user_id) {
        if ($method === 'GET' && $user_id) {
            $stats = $this->getUserStats($user_id);
            $this->sendResponse(200, $stats);
        } else {
            $this->sendResponse(405, ['error' => 'Method not allowed']);
        }
    }
    
    private function getUserStats($user_id) {
        // Points this month
        $stmt = $this->db->prepare("
            SELECT COALESCE(SUM(points_earned), 0) as points_this_month
            FROM RECYCLING_ACTIVITY 
            WHERE user_id = ? 
            AND MONTH(timestamp) = MONTH(CURRENT_DATE())
            AND YEAR(timestamp) = YEAR(CURRENT_DATE())
            AND verification_staff = 'verified'
        ");
        $stmt->execute([$user_id]);
        $pointsThisMonth = $stmt->fetchColumn();
        
        // Total activities
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as total_activities
            FROM RECYCLING_ACTIVITY 
            WHERE user_id = ?
        ");
        $stmt->execute([$user_id]);
        $totalActivities = $stmt->fetchColumn();
        
        // Redeemed rewards count
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as redeemed_rewards
            FROM REWARDREDEMPTION 
            WHERE user_id = ? AND status = 'completed'
        ");
        $stmt->execute([$user_id]);
        $redeemedRewards = $stmt->fetchColumn();
        
        // Campaigns joined
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as campaigns_joined
            FROM USER_SUSTAINABILITY_CAMPAIGN 
            WHERE user_id = ? AND status = 'active'
        ");
        $stmt->execute([$user_id]);
        $campaignsJoined = $stmt->fetchColumn();
        
        return [
            'points_this_month' => (int)$pointsThisMonth,
            'total_activities' => (int)$totalActivities,
            'redeemed_rewards' => (int)$redeemedRewards,
            'campaigns_joined' => (int)$campaignsJoined
        ];
    }
    
    private function sendResponse($code, $data) {
        http_response_code($code);
        echo json_encode($data);
        exit;
    }
}

// Initialize and handle request
$api = new StudentAPI();
$api->handleRequest();
?>