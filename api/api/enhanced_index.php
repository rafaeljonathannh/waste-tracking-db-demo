<?php
// api/enhanced_index.php - Enhanced API Router for FASE 2
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once '../src/config/database.php';
require_once 'helpers/ResponseHelper.php';
require_once 'helpers/ValidationHelper.php';
require_once 'helpers/SecurityHelper.php';

class EnhancedStudentAPI {
    private $db;
    private $responseHelper;
    private $validator;
    private $security;
    
    public function __construct() {
        try {
            $database = new Database();
            $this->db = $database->getConnection();
            $this->responseHelper = new ResponseHelper();
            $this->validator = new ValidationHelper();
            $this->security = new SecurityHelper();
        } catch (Exception $e) {
            $this->sendErrorResponse(500, 'Database connection failed: ' . $e->getMessage());
        }
    }
    
    public function handleRequest() {
        try {
            $method = $_SERVER['REQUEST_METHOD'];
            $path = trim($_SERVER['REQUEST_URI'], '/');
            $segments = explode('/', $path);
            
            // Remove base path segments
            while (!empty($segments) && !in_array($segments[0], ['api', 'enhanced-api'])) {
                array_shift($segments);
            }
            if (!empty($segments) && in_array($segments[0], ['api', 'enhanced-api'])) {
                array_shift($segments);
            }
            
            $endpoint = $segments[0] ?? '';
            $id = $segments[1] ?? null;
            $action = $segments[2] ?? null;
            
            // Rate limiting check
            if (!$this->security->checkRateLimit()) {
                $this->sendErrorResponse(429, 'Too many requests. Please try again later.');
                return;
            }
            
            // Route to appropriate handler
            switch ($endpoint) {
                case 'user':
                    $this->handleUser($method, $id, $action);
                    break;
                case 'activities':
                    $this->handleActivities($method, $id, $action);
                    break;
                case 'rewards':
                    $this->handleRewards($method, $id, $action);
                    break;
                case 'campaigns':
                    $this->handleCampaigns($method, $id, $action);
                    break;
                case 'stats':
                    $this->handleStats($method, $id, $action);
                    break;
                case 'realtime':
                    $this->handleRealTime($method, $id, $action);
                    break;
                case 'leaderboard':
                    $this->handleLeaderboard($method, $id, $action);
                    break;
                case 'waste-types':
                    $this->handleWasteTypes($method, $id, $action);
                    break;
                case 'locations':
                    $this->handleLocations($method, $id, $action);
                    break;
                case 'upload':
                    $this->handleFileUpload($method, $id, $action);
                    break;
                case 'test':
                    $this->handleTest($method, $id, $action);
                    break;
                default:
                    $this->sendErrorResponse(404, 'Endpoint not found');
            }
        } catch (Exception $e) {
            error_log("API Error: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Internal server error');
        }
    }
    
    // Enhanced User Endpoints
    private function handleUser($method, $id, $action) {
        switch ($method) {
            case 'GET':
                if ($action === 'profile') {
                    $this->getUserProfile($id);
                } elseif ($action === 'achievements') {
                    $this->getUserAchievements($id);
                } elseif ($action === 'history') {
                    $this->getUserHistory($id);
                } elseif ($id) {
                    $this->getUserData($id);
                } else {
                    $this->sendErrorResponse(400, 'User ID required');
                }
                break;
            case 'PUT':
                if ($action === 'profile') {
                    $this->updateUserProfile($id);
                } else {
                    $this->sendErrorResponse(400, 'Invalid action');
                }
                break;
            default:
                $this->sendErrorResponse(405, 'Method not allowed');
        }
    }
    
    private function getUserData($userId) {
        if (!$this->validator->validateUserId($userId)) {
            $this->sendErrorResponse(400, 'Invalid user ID');
            return;
        }
        
        try {
            // Get user basic info with enhanced data
            $stmt = $this->db->prepare("
                SELECT u.*, 
                       COALESCE(u.total_points, 0) as total_points,
                       f.name as faculty_name,
                       fd.name as department_name,
                       DATEDIFF(CURDATE(), u.created_at) as membership_days,
                       (SELECT COUNT(*) FROM RECYCLING_ACTIVITY WHERE user_id = u.id AND verification_staff = 'verified') as total_activities,
                       (SELECT COUNT(*) FROM REWARDREDEMPTION WHERE user_id = u.id AND status = 'completed') as redeemed_rewards,
                       (SELECT COUNT(*) FROM USER_SUSTAINABILITY_CAMPAIGN WHERE user_id = u.id AND status = 'active') as active_campaigns
                FROM USERR u 
                LEFT JOIN FACULTY f ON u.faculty_id = f.id
                LEFT JOIN FACULTY_DEPARTMENT fd ON u.dept_id = fd.id
                WHERE u.id = ?
            ");
            $stmt->execute([$userId]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                $this->sendErrorResponse(404, 'User not found');
                return;
            }
            
            // Get user level and streak
            $user['level'] = $this->calculateUserLevel($user['total_points']);
            $user['streak_days'] = $this->calculateStreak($userId);
            
            // Get recent stats
            $user['stats'] = $this->getUserStats($userId);
            
            $this->responseHelper->sendSuccess($user);
            
        } catch (PDOException $e) {
            error_log("Database error in getUserData: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Failed to fetch user data');
        }
    }
    
    private function getUserStats($userId) {
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    COALESCE(SUM(CASE WHEN MONTH(timestamp) = MONTH(CURRENT_DATE()) AND YEAR(timestamp) = YEAR(CURRENT_DATE()) AND verification_staff = 'verified' THEN points_earned ELSE 0 END), 0) as points_this_month,
                    COALESCE(SUM(CASE WHEN DATE(timestamp) = CURDATE() THEN points_earned ELSE 0 END), 0) as points_today,
                    COUNT(CASE WHEN verification_staff = 'pending' THEN 1 END) as pending_activities,
                    COUNT(CASE WHEN verification_staff = 'verified' THEN 1 END) as verified_activities
                FROM RECYCLING_ACTIVITY 
                WHERE user_id = ?
            ");
            $stmt->execute([$userId]);
            $stats = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Get weekly points for chart
            $stmt = $this->db->prepare("
                SELECT DATE(timestamp) as date, SUM(points_earned) as daily_points
                FROM RECYCLING_ACTIVITY 
                WHERE user_id = ? 
                AND verification_staff = 'verified'
                AND timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
                GROUP BY DATE(timestamp)
                ORDER BY date ASC
            ");
            $stmt->execute([$userId]);
            $weeklyData = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Fill missing days with 0
            $weeklyPoints = array_fill(0, 7, 0);
            foreach ($weeklyData as $day) {
                $dayIndex = (int)date('w', strtotime($day['date']));
                $weeklyPoints[$dayIndex] = (int)$day['daily_points'];
            }
            
            $stats['weekly_points'] = $weeklyPoints;
            
            return $stats;
            
        } catch (PDOException $e) {
            error_log("Database error in getUserStats: " . $e->getMessage());
            return [];
        }
    }
    
    // Enhanced Activities Endpoints
    private function handleActivities($method, $id, $action) {
        switch ($method) {
            case 'GET':
                if ($action === 'recent') {
                    $this->getRecentActivities($id);
                } elseif ($action === 'pending') {
                    $this->getPendingActivities($id);
                } elseif ($id) {
                    $this->getUserActivities($id);
                } else {
                    $this->sendErrorResponse(400, 'User ID required');
                }
                break;
            case 'POST':
                $this->createActivity();
                break;
            case 'PUT':
                if ($action === 'verify') {
                    $this->verifyActivity($id);
                } else {
                    $this->sendErrorResponse(400, 'Invalid action');
                }
                break;
            default:
                $this->sendErrorResponse(405, 'Method not allowed');
        }
    }
    
    private function createActivity() {
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Enhanced validation
        $validation = $this->validator->validateActivityData($data);
        if (!$validation['valid']) {
            $this->sendErrorResponse(400, 'Validation failed', $validation['errors']);
            return;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Insert activity with enhanced data
            $stmt = $this->db->prepare("
                INSERT INTO RECYCLING_ACTIVITY (
                    user_id, recycling_bin_id, waste_type_id, weight_kg, 
                    verification_staff, timestamp, notes, photo_path
                ) VALUES (?, ?, ?, ?, 'pending', NOW(), ?, ?)
            ");
            
            $stmt->execute([
                $data['user_id'],
                $data['recycling_bin_id'],
                $data['waste_type_id'],
                $data['weight_kg'],
                $data['notes'] ?? null,
                $data['photo_path'] ?? null
            ]);
            
            $activityId = $this->db->lastInsertId();
            
            // Calculate estimated points
            $stmt = $this->db->prepare("
                SELECT points_per_kg FROM WASTE_TYPE WHERE id = ?
            ");
            $stmt->execute([$data['waste_type_id']]);
            $pointsPerKg = $stmt->fetchColumn();
            
            $estimatedPoints = $pointsPerKg * $data['weight_kg'];
            
            $this->db->commit();
            
            $this->responseHelper->sendSuccess([
                'message' => 'Activity recorded successfully',
                'activity_id' => $activityId,
                'estimated_points' => $estimatedPoints,
                'status' => 'pending'
            ], 201);
            
        } catch (PDOException $e) {
            $this->db->rollBack();
            error_log("Database error in createActivity: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Failed to record activity');
        }
    }
    
    private function getUserActivities($userId) {
        if (!$this->validator->validateUserId($userId)) {
            $this->sendErrorResponse(400, 'Invalid user ID');
            return;
        }
        
        try {
            $limit = $_GET['limit'] ?? 20;
            $offset = $_GET['offset'] ?? 0;
            $status = $_GET['status'] ?? null;
            
            $whereClause = "WHERE ra.user_id = ?";
            $params = [$userId];
            
            if ($status) {
                $whereClause .= " AND ra.verification_staff = ?";
                $params[] = $status;
            }
            
            $stmt = $this->db->prepare("
                SELECT ra.*, 
                       wt.waste_type_name, wt.points_per_kg,
                       bl.description as location_name,
                       f.name as faculty_name,
                       rb.bin_type
                FROM RECYCLING_ACTIVITY ra
                JOIN WASTE_TYPE wt ON ra.waste_type_id = wt.id
                JOIN RECYCLING_BIN rb ON ra.recycling_bin_id = rb.id
                JOIN BIN_LOCATION bl ON rb.bin_location_id = bl.id
                JOIN FACULTY f ON bl.faculty_id = f.id
                {$whereClause}
                ORDER BY ra.timestamp DESC
                LIMIT ? OFFSET ?
            ");
            
            $params[] = (int)$limit;
            $params[] = (int)$offset;
            $stmt->execute($params);
            $activities = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get total count
            $stmt = $this->db->prepare("
                SELECT COUNT(*) FROM RECYCLING_ACTIVITY ra {$whereClause}
            ");
            $stmt->execute(array_slice($params, 0, -2));
            $totalCount = $stmt->fetchColumn();
            
            $this->responseHelper->sendSuccess([
                'activities' => $activities,
                'total_count' => (int)$totalCount,
                'limit' => (int)$limit,
                'offset' => (int)$offset
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getUserActivities: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Failed to fetch activities');
        }
    }
    
    // Enhanced Rewards Endpoints
    private function handleRewards($method, $id, $action) {
        switch ($method) {
            case 'GET':
                if ($action === 'check') {
                    $this->checkRewardEligibility($id, $_GET['user_id'] ?? null);
                } elseif ($action === 'history') {
                    $this->getRewardHistory($id);
                } elseif ($id) {
                    $this->getRewardDetails($id);
                } else {
                    $this->getAllRewards();
                }
                break;
            case 'POST':
                if ($action === 'redeem') {
                    $this->redeemReward();
                } else {
                    $this->sendErrorResponse(400, 'Invalid action');
                }
                break;
            default:
                $this->sendErrorResponse(405, 'Method not allowed');
        }
    }
    
    private function getAllRewards() {
        try {
            $category = $_GET['category'] ?? null;
            $available_only = $_GET['available_only'] ?? 'true';
            
            $whereClause = "WHERE 1=1";
            $params = [];
            
            if ($category) {
                $whereClause .= " AND category = ?";
                $params[] = $category;
            }
            
            if ($available_only === 'true') {
                $whereClause .= " AND status = 'available' AND stock > 0";
            }
            
            $stmt = $this->db->prepare("
                SELECT ri.*, 
                       (SELECT COUNT(*) FROM REWARDREDEMPTION WHERE reward_item_id = ri.id) as redemption_count,
                       CASE 
                           WHEN ri.stock = 0 THEN 'out_of_stock'
                           WHEN ri.stock < 5 THEN 'low_stock'
                           ELSE 'available'
                       END as stock_status
                FROM REWARD_ITEM ri
                {$whereClause}
                ORDER BY ri.points_required ASC
            ");
            $stmt->execute($params);
            $rewards = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Calculate popularity for each reward
            foreach ($rewards as &$reward) {
                $popularity = 0;
                if ($reward['redemption_count'] > 0) {
                    $popularity = min(100, ($reward['redemption_count'] / 10) * 100);
                }
                $reward['popularity'] = $popularity;
                
                // Add discount simulation (for demo)
                $reward['discount'] = rand(0, 1) ? rand(5, 20) : 0;
            }
            
            $this->responseHelper->sendSuccess($rewards);
            
        } catch (PDOException $e) {
            error_log("Database error in getAllRewards: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Failed to fetch rewards');
        }
    }
    
    // Enhanced Real-time Endpoints
    private function handleRealTime($method, $id, $action) {
        if ($method !== 'GET') {
            $this->sendErrorResponse(405, 'Method not allowed');
            return;
        }
        
        switch ($action) {
            case 'updates':
                $this->getRealTimeUpdates($id);
                break;
            case 'stats':
                $this->getLiveStats($id);
                break;
            case 'notifications':
                $this->getNotifications($id);
                break;
            default:
                $this->sendErrorResponse(400, 'Invalid action');
        }
    }
    
    private function getRealTimeUpdates($userId) {
        if (!$this->validator->validateUserId($userId)) {
            $this->sendErrorResponse(400, 'Invalid user ID');
            return;
        }
        
        try {
            $lastCheck = $_GET['last_check'] ?? date('Y-m-d H:i:s', strtotime('-1 hour'));
            $updates = [];
            
            // Check for newly verified activities
            $stmt = $this->db->prepare("
                SELECT ra.*, wt.waste_type_name
                FROM RECYCLING_ACTIVITY ra
                JOIN WASTE_TYPE wt ON ra.waste_type_id = wt.id
                WHERE ra.user_id = ? 
                AND ra.verification_staff = 'verified'
                AND ra.verified_at > ?
                ORDER BY ra.verified_at DESC
                LIMIT 5
            ");
            $stmt->execute([$userId, $lastCheck]);
            $newVerifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($newVerifications as $activity) {
                $updates[] = [
                    'type' => 'activity_verified',
                    'message' => "Your {$activity['waste_type_name']} recycling activity has been verified!",
                    'points' => $activity['points_earned'],
                    'timestamp' => $activity['verified_at']
                ];
            }
            
            // Check for new campaigns
            $stmt = $this->db->prepare("
                SELECT sc.* FROM SUSTAINABILITY_CAMPAIGN sc
                WHERE sc.status = 'active'
                AND sc.created_at > ?
                AND sc.id NOT IN (
                    SELECT sustainability_campaign_id 
                    FROM USER_SUSTAINABILITY_CAMPAIGN 
                    WHERE user_id = ?
                )
                ORDER BY sc.created_at DESC
                LIMIT 3
            ");
            $stmt->execute([$lastCheck, $userId]);
            $newCampaigns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($newCampaigns as $campaign) {
                $updates[] = [
                    'type' => 'new_campaign',
                    'message' => "New campaign available: {$campaign['title']}",
                    'campaign_id' => $campaign['id'],
                    'timestamp' => $campaign['created_at']
                ];
            }
            
            // Check for low stock rewards (if user has enough points)
            $stmt = $this->db->prepare("
                SELECT total_points FROM USERR WHERE id = ?
            ");
            $stmt->execute([$userId]);
            $userPoints = $stmt->fetchColumn();
            
            $stmt = $this->db->prepare("
                SELECT * FROM REWARD_ITEM 
                WHERE status = 'available' 
                AND stock <= 5 
                AND stock > 0
                AND points_required <= ?
                ORDER BY stock ASC
                LIMIT 2
            ");
            $stmt->execute([$userPoints]);
            $lowStockRewards = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($lowStockRewards as $reward) {
                $updates[] = [
                    'type' => 'low_stock_alert',
                    'message' => "Hurry! Only {$reward['stock']} {$reward['name']} left in stock!",
                    'reward_id' => $reward['id'],
                    'timestamp' => date('Y-m-d H:i:s')
                ];
            }
            
            $this->responseHelper->sendSuccess([
                'timestamp' => date('Y-m-d H:i:s'),
                'updates' => $updates,
                'has_updates' => !empty($updates),
                'next_check_in' => 30 // seconds
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getRealTimeUpdates: " . $e->getMessage());
            $this->sendErrorResponse(500, 'Failed to get real-time updates');
        }
    }
    
    // Enhanced Utility Methods
    private function calculateUserLevel($points) {
        if ($points >= 2000) return 'Platinum Member';
        if ($points >= 1000) return 'Gold Member';
        if ($points >= 500) return 'Silver Member';
        if ($points >= 100) return 'Bronze Member';
        return 'New Member';
    }
    
    private function calculateStreak($userId) {
        try {
            $stmt = $this->db->prepare("
                SELECT DATE(timestamp) as activity_date
                FROM RECYCLING_ACTIVITY 
                WHERE user_id = ? 
                AND verification_staff = 'verified'
                GROUP BY DATE(timestamp)
                ORDER BY activity_date DESC
                LIMIT 30
            ");
            $stmt->execute([$userId]);
            $dates = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            if (empty($dates)) return 0;
            
            $streak = 0;
            $currentDate = new DateTime();
            
            foreach ($dates as $dateStr) {
                $activityDate = new DateTime($dateStr);
                $daysDiff = $currentDate->diff($activityDate)->days;
                
                if ($daysDiff === $streak) {
                    $streak++;
                } else {
                    break;
                }
            }
            
            return $streak;
            
        } catch (Exception $e) {
            error_log("Error calculating streak: " . $e->getMessage());
            return 0;
        }
    }
    
    // Helper method for error responses
    private function sendErrorResponse($code, $message, $details = null) {
        http_response_code($code);
        $response = ['error' => $message];
        if ($details) {
            $response['details'] = $details;
        }
        echo json_encode($response);
        exit;
    }
    
    // Test endpoint for development
    private function handleTest($method, $id, $action) {
        if ($method !== 'GET') {
            $this->sendErrorResponse(405, 'Method not allowed');
            return;
        }
        
        try {
            // Test database connection
            $stmt = $this->db->query("SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'fp_mbd'");
            $tableCount = $stmt->fetchColumn();
            
            // Test user data
            $stmt = $this->db->query("SELECT COUNT(*) as user_count FROM USERR");
            $userCount = $stmt->fetchColumn();
            
            $this->responseHelper->sendSuccess([
                'message' => 'Enhanced API is working!',
                'database_status' => 'connected',
                'tables_found' => $tableCount,
                'users_found' => $userCount,
                'timestamp' => date('Y-m-d H:i:s'),
                'api_version' => '2.0'
            ]);
            
        } catch (PDOException $e) {
            $this->sendErrorResponse(500, 'Database test failed: ' . $e->getMessage());
        }
    }
}

// Helper Classes

class ResponseHelper {
    public function sendSuccess($data, $code = 200) {
        http_response_code($code);
        echo json_encode([
            'success' => true,
            'data' => $data,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        exit;
    }
    
    public function sendError($message, $code = 400, $details = null) {
        http_response_code($code);
        $response = [
            'success' => false,
            'error' => $message,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        if ($details) {
            $response['details'] = $details;
        }
        echo json_encode($response);
        exit;
    }
}

class ValidationHelper {
    public function validateUserId($userId) {
        return is_numeric($userId) && $userId > 0;
    }
    
    public function validateActivityData($data) {
        $errors = [];
        
        if (empty($data['user_id']) || !$this->validateUserId($data['user_id'])) {
            $errors['user_id'] = 'Valid user ID required';
        }
        
        if (empty($data['waste_type_id']) || !is_numeric($data['waste_type_id'])) {
            $errors['waste_type_id'] = 'Valid waste type ID required';
        }
        
        if (empty($data['weight_kg']) || !is_numeric($data['weight_kg']) || $data['weight_kg'] <= 0) {
            $errors['weight_kg'] = 'Valid weight required (must be greater than 0)';
        }
        
        if (empty($data['recycling_bin_id']) || !is_numeric($data['recycling_bin_id'])) {
            $errors['recycling_bin_id'] = 'Valid recycling bin ID required';
        }
        
        if ($data['weight_kg'] > 100) {
            $errors['weight_kg'] = 'Weight cannot exceed 100kg';
        }
        
        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }
}

class SecurityHelper {
    private $rateLimit = 100; // requests per hour
    private $rateLimitWindow = 3600; // 1 hour in seconds
    
    public function checkRateLimit() {
        $clientIP = $_SERVER['REMOTE_ADDR'];
        $currentTime = time();
        $windowStart = $currentTime - $this->rateLimitWindow;
        
        // In production, use Redis or database to store rate limit data
        // For demo, we'll just return true
        return true;
    }
    
    public function sanitizeInput($input) {
        if (is_array($input)) {
            return array_map([$this, 'sanitizeInput'], $input);
        }
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
}

// Initialize and handle request
try {
    $api = new EnhancedStudentAPI();
    $api->handleRequest();
} catch (Exception $e) {
    error_log("Fatal API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Internal server error',
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?>