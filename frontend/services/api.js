/**
 * API service for interacting with the fp_mbd database
 * This file contains functions for making requests to the backend API
 */

// Replace with your actual API base URL
const API_BASE_URL = '/api/fp_mbd';

/**
 * Generic function to make API requests
 */
async function apiRequest(endpoint, method = 'GET', body = null) {
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, options);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed with status ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`API Error (${endpoint}):`, error);
    throw error;
  }
}

/**
 * User related API functions
 */
export const userAPI = {
  // Get user by ID
  getUser: (userId) => apiRequest(`/users/${userId}`),
  
  // Get user summary using stored procedure
  getUserSummary: (userId) => apiRequest('/procedures/sp_generate_user_summary', 'POST', { p_user_id: userId }),
  
  // Update user status using stored procedure
  updateUserStatus: (userId) => apiRequest('/procedures/sp_update_user_status', 'POST', { p_user_id: userId }),
};

/**
 * Activity related API functions
 */
export const activityAPI = {
  // Get activities for a user
  getUserActivities: (userId) => apiRequest(`/activities/${userId}`),
  
  // Report a new activity using stored procedure
  reportActivity: (userId, recyclingBinId, wasteTypeId, weightKg, adminId) => 
    apiRequest('/procedures/sp_laporkan_aktivitas_sampah', 'POST', {
      p_user_id: userId,
      p_recycling_bin_id: recyclingBinId,
      p_waste_type_id: wasteTypeId,
      p_weight_kg: weightKg,
      p_admin_id: adminId
    }),
  
  // Verify an activity using stored procedure
  verifyActivity: (activityId) => 
    apiRequest('/procedures/sp_verifikasi_aktivitas', 'POST', {
      p_recycling_activity_id: activityId
    }),
};

/**
 * Reward related API functions
 */
export const rewardAPI = {
  // Get all rewards
  getAllRewards: () => apiRequest('/rewards'),
  
  // Redeem a reward using stored procedure
  redeemReward: (userId, rewardId) => 
    apiRequest('/procedures/sp_redeem_reward', 'POST', {
      p_user_id: userId,
      p_reward_item_id: rewardId
    }),
  
  // Complete a redemption using stored procedure
  completeRedemption: (redemptionId) => 
    apiRequest('/procedures/sp_complete_redemption', 'POST', {
      p_redemption_id: redemptionId
    }),
    
  // Add stock to a reward using stored procedure
  addRewardStock: (rewardId, stockAmount) => 
    apiRequest('/procedures/sp_tambah_stok_reward', 'POST', {
      p_reward_id_item: rewardId,
      p_tambahan_stok: stockAmount
    }),
};

/**
 * Campaign related API functions
 */
export const campaignAPI = {
  // Get all campaigns
  getAllCampaigns: () => apiRequest('/campaigns'),
  
  // Get user's campaigns
  getUserCampaigns: (userId) => apiRequest(`/user-campaigns/${userId}`),
  
  // Join a campaign using stored procedure
  joinCampaign: (userId, campaignId) => 
    apiRequest('/procedures/sp_ikut_kampanye', 'POST', {
      p_user_id: userId,
      p_sustainability_campaign_id: campaignId
    }),
  
  // Create a campaign using stored procedure
  createCampaign: (coordinatorId, title, description, startDate, endDate, targetWasteReduction, bonusPoints, status) => 
    apiRequest('/procedures/sp_create_campaign_with_coordinator_check', 'POST', {
      p_sustainability_coordinator_id: coordinatorId,
      p_title: title,
      p_description: description,
      p_start_date: startDate,
      p_end_date: endDate,
      p_target_waste_reduction: targetWasteReduction,
      p_bonus_points: bonusPoints,
      p_status: status
    }),
};

/**
 * Recycling bin related API functions
 */
export const recyclingBinAPI = {
  // Get all recycling bins
  getAllBins: () => apiRequest('/recycling-bins'),
  
  // Get bin locations
  getBinLocations: () => apiRequest('/bin-locations'),
  
  // Get bin types
  getBinTypes: () => apiRequest('/bin-types'),
  
  // Add a new recycling bin using stored procedure
  addBin: (binLocationId, capacityKg, qrCode) => 
    apiRequest('/procedures/sp_add_recycling_bin', 'POST', {
      p_bin_location_id: binLocationId,
      p_capacity_kg: capacityKg,
      p_qr_code: qrCode
    }),
};

/**
 * Waste type related API functions
 */
export const wasteTypeAPI = {
  // Get all waste types
  getAllWasteTypes: () => apiRequest('/waste-types'),
};

export default {
  user: userAPI,
  activity: activityAPI,
  reward: rewardAPI,
  campaign: campaignAPI,
  recyclingBin: recyclingBinAPI,
  wasteType: wasteTypeAPI,
};