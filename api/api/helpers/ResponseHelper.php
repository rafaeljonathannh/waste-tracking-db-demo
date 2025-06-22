<?php
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
?>