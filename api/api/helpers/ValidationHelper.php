<?php
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
?>