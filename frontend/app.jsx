import React, { useState, useEffect, useCallback } from 'react';
import { AppContext } from './app-context';
import Sidebar from './sidebar';
import Dashboard from './dashboard';
import Activities from './activities';
import AddActivities from './add-activities';
import Rewards from './rewards';
import UsersLeaderboard from './users-leaderboard';
import Profile from './profile';
import Notification from './notification';
import Icon from './icon';

/**
 * Main App component that serves as the entry point for the waste tracking application.
 * It provides the AppContext to all child components and handles database interactions.
 */
const App = () => {
  // User state from database
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // State for UI management
  const [activeTab, setActiveTab] = useState('dashboard');
  const [showAddActivity, setShowAddActivity] = useState(false);
  const [loading, setLoading] = useState(false);
  const [notifications, setNotifications] = useState([]);
  
  // Application data from database
  const [stats, setStats] = useState({
    thisMonth: 0,
    totalActivities: 0,
    redeemedRewards: 0,
    campaignsJoined: 0
  });
  const [activities, setActivities] = useState([]);
  const [rewards, setRewards] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [wasteTypes, setWasteTypes] = useState([]);
  const [recyclingBins, setRecyclingBins] = useState([]);

  // Current date and time
  const currentDateTime = '2025-06-23 14:17:50'; // Using the provided date
  const currentUser = 'PowerViber'; // Using the provided login

  // API URL base - replace with your actual API endpoint
  const API_BASE_URL = '/api/fp_mbd';

  /**
   * Add a new notification
   */
  const addNotification = (notification) => {
    setNotifications(prev => [
      {
        id: Date.now(),
        timestamp: new Date().toLocaleTimeString(),
        ...notification
      },
      ...prev.slice(0, 4)
    ]);
  };

  /**
   * Fetch user data from database
   */
  const fetchUserData = useCallback(async () => {
    try {
      setLoading(true);
      // In a real implementation, we would authenticate and get the user's ID
      // For demo, we'll use a hardcoded user ID
      const userId = 'USR0004'; // Example user ID from the database
      
      // Fetch user profile data
      const userResponse = await fetch(`${API_BASE_URL}/users/${userId}`);
      if (!userResponse.ok) {
        throw new Error('Failed to fetch user data');
      }
      const userData = await userResponse.json();
      setUser(userData);
      
      // Use the stored procedure to generate user summary
      const statsResponse = await fetch(`${API_BASE_URL}/procedures/sp_generate_user_summary`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ p_user_id: userId }),
      });
      
      if (!statsResponse.ok) {
        throw new Error('Failed to fetch user statistics');
      }
      
      const statsData = await statsResponse.json();
      setStats({
        thisMonth: statsData.total_waste_kg || 0,
        totalActivities: statsData.total_activities || 0,
        redeemedRewards: statsData.total_rewards_redeemed || 0,
        campaignsJoined: statsData.total_campaigns_joined || 0
      });

      return userData;
    } catch (error) {
      console.error('Error fetching user data:', error);
      setError('Failed to load user data. Please refresh the page.');
      addNotification({
        type: 'error',
        message: 'Failed to fetch user data. Please try again.'
      });
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Fetch recycling activities for the current user
   */
  const fetchActivities = useCallback(async (userId) => {
    if (!userId) return;
    
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/activities/${userId}`);
      
      if (!response.ok) {
        throw new Error('Failed to fetch activities');
      }
      
      const data = await response.json();
      
      // Transform data to match the application's format
      const formattedActivities = data.map(activity => ({
        id: activity.id,
        waste_type: activity.waste_type_name,
        weight: parseFloat(activity.weight_kg),
        points_earned: activity.points_earned,
        status: activity.verification_staff,
        timestamp: new Date(activity.timestamp).toLocaleString(),
        location: activity.bin_location_description || 'Unknown'
      }));
      
      setActivities(formattedActivities);
    } catch (error) {
      console.error('Error fetching activities:', error);
      addNotification({
        type: 'error',
        message: 'Failed to load recycling activities.'
      });
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Fetch available rewards from database
   */
  const fetchRewards = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/rewards`);
      
      if (!response.ok) {
        throw new Error('Failed to fetch rewards');
      }
      
      const data = await response.json();
      
      // Transform data to match the application's format
      const formattedRewards = data.map(reward => ({
        id: reward.id,
        name: reward.name,
        description: reward.description,
        points_cost: reward.points_required,
        stock: reward.stock,
        image: getEmojiForReward(reward.name),
        category: getCategoryForReward(reward.name)
      }));
      
      setRewards(formattedRewards);
    } catch (error) {
      console.error('Error fetching rewards:', error);
      addNotification({
        type: 'error',
        message: 'Failed to load rewards data.'
      });
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Fetch active campaigns from database
   */
  const fetchCampaigns = useCallback(async (userId) => {
    if (!userId) return;
    
    try {
      setLoading(true);
      
      // Fetch all campaigns
      const campaignsResponse = await fetch(`${API_BASE_URL}/campaigns`);
      if (!campaignsResponse.ok) {
        throw new Error('Failed to fetch campaigns');
      }
      const allCampaigns = await campaignsResponse.json();
      
      // Fetch user's joined campaigns
      const userCampaignsResponse = await fetch(`${API_BASE_URL}/user-campaigns/${userId}`);
      if (!userCampaignsResponse.ok) {
        throw new Error('Failed to fetch user campaigns');
      }
      const userCampaigns = await userCampaignsResponse.json();
      
      // Create a set of joined campaign IDs for quick lookup
      const joinedCampaignIds = new Set(userCampaigns.map(uc => uc.sustainability_campaign_id));
      
      // Transform data to match the application's format
      const formattedCampaigns = allCampaigns.map(campaign => ({
        id: campaign.id,
        title: campaign.title,
        description: campaign.description,
        participants: Math.floor(Math.random() * 200) + 50, // This would come from a count query in a real implementation
        end_date: new Date(campaign.end_date).toLocaleDateString(),
        status: campaign.status,
        joined: joinedCampaignIds.has(campaign.id)
      }));
      
      setCampaigns(formattedCampaigns);
    } catch (error) {
      console.error('Error fetching campaigns:', error);
      addNotification({
        type: 'error',
        message: 'Failed to load campaign data.'
      });
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Fetch waste types from database
   */
  const fetchWasteTypes = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/waste-types`);
      
      if (!response.ok) {
        throw new Error('Failed to fetch waste types');
      }
      
      const data = await response.json();
      setWasteTypes(data);
    } catch (error) {
      console.error('Error fetching waste types:', error);
      addNotification({
        type: 'error',
        message: 'Failed to load waste type data.'
      });
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Fetch recycling bins from database
   */
  const fetchRecyclingBins = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/recycling-bins`);
      
      if (!response.ok) {
        throw new Error('Failed to fetch recycling bins');
      }
      
      const data = await response.json();
      setRecyclingBins(data);
    } catch (error) {
      console.error('Error fetching recycling bins:', error);
      addNotification({
        type: 'error',
        message: 'Failed to load recycling bin data.'
      });
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Add a new recycling activity using the stored procedure
   */
  const addActivity = async (formData) => {
    if (!user) {
      addNotification({
        type: 'error',
        message: 'You must be logged in to perform this action.'
      });
      return false;
    }
    
    setLoading(true);
    try {
      // In a real implementation, these would be selected from dropdowns
      // For now, we'll use the first values from our database
      const recycling_bin_id = recyclingBins[0]?.id || 'RCB00000001';
      const waste_type_id = wasteTypes.find(wt => wt.waste_type_name === formData.waste_type)?.id || 'WT00000001';
      const admin_id = 'ADM0000001'; // Assuming a default admin ID
      
      // Call the stored procedure to add activity
      const response = await fetch(`${API_BASE_URL}/procedures/sp_laporkan_aktivitas_sampah`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_user_id: user.id,
          p_recycling_bin_id: recycling_bin_id,
          p_waste_type_id: waste_type_id,
          p_weight_kg: parseFloat(formData.weight),
          p_admin_id: admin_id
        }),
      });
      
      if (!response.ok) {
        throw new Error('Failed to add activity');
      }
      
      // Refresh activities list
      await fetchActivities(user.id);
      
      addNotification({
        type: 'success',
        message: 'Recycling activity submitted for verification!'
      });
      
      setShowAddActivity(false);
      return true;
    } catch (error) {
      console.error('Error adding activity:', error);
      addNotification({
        type: 'error',
        message: 'Failed to add activity. Please try again.'
      });
      return false;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Redeem a reward using the stored procedure
   */
  const redeemReward = async (rewardId) => {
    if (!user) {
      addNotification({
        type: 'error',
        message: 'You must be logged in to perform this action.'
      });
      return false;
    }
    
    setLoading(true);
    try {
      // Call the stored procedure to redeem the reward
      const response = await fetch(`${API_BASE_URL}/procedures/sp_redeem_reward`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_user_id: user.id,
          p_reward_item_id: rewardId
        }),
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to redeem reward');
      }
      
      // Refresh user data to get updated points
      await fetchUserData();
      // Refresh rewards to get updated stock
      await fetchRewards();
      
      addNotification({
        type: 'success',
        message: 'Reward successfully redeemed!'
      });
      
      return true;
    } catch (error) {
      console.error('Error redeeming reward:', error);
      addNotification({
        type: 'error',
        message: error.message || 'Failed to redeem reward. Please try again.'
      });
      return false;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Join a campaign using the stored procedure
   */
  const joinCampaign = async (campaignId) => {
    if (!user) {
      addNotification({
        type: 'error',
        message: 'You must be logged in to perform this action.'
      });
      return false;
    }
    
    setLoading(true);
    try {
      // Call the stored procedure to join the campaign
      const response = await fetch(`${API_BASE_URL}/procedures/sp_ikut_kampanye`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_user_id: user.id,
          p_sustainability_campaign_id: campaignId
        }),
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to join campaign');
      }
      
      // Refresh campaigns list
      await fetchCampaigns(user.id);
      
      addNotification({
        type: 'success',
        message: 'Successfully joined the campaign!'
      });
      
      return true;
    } catch (error) {
      console.error('Error joining campaign:', error);
      addNotification({
        type: 'error',
        message: error.message || 'Failed to join campaign. Please try again.'
      });
      return false;
    } finally {
      setLoading(false);
    }
  };

  // Helper function to get emoji for reward
  const getEmojiForReward = (name) => {
    if (name.toLowerCase().includes('tumbler') || name.toLowerCase().includes('bottle')) return '🥤';
    if (name.toLowerCase().includes('bag') || name.toLowerCase().includes('tote')) return '👜';
    if (name.toLowerCase().includes('voucher') || name.toLowerCase().includes('coupon')) return '🎫';
    if (name.toLowerCase().includes('t-shirt') || name.toLowerCase().includes('clothing')) return '👕';
    if (name.toLowerCase().includes('book') || name.toLowerCase().includes('notebook')) return '📔';
    if (name.toLowerCase().includes('pen') || name.toLowerCase().includes('stationery')) return '✏️';
    return '🎁'; // Default emoji
  };

  // Helper function to get category for reward
  const getCategoryForReward = (name) => {
    if (name.toLowerCase().includes('tumbler') || name.toLowerCase().includes('bottle')) return 'Drinkware';
    if (name.toLowerCase().includes('bag') || name.toLowerCase().includes('tote')) return 'Bags';
    if (name.toLowerCase().includes('voucher') || name.toLowerCase().includes('coupon')) return 'Voucher';
    if (name.toLowerCase().includes('t-shirt') || name.toLowerCase().includes('clothing')) return 'Clothing';
    if (name.toLowerCase().includes('book') || name.toLowerCase().includes('notebook')) return 'Stationery';
    if (name.toLowerCase().includes('pen')) return 'Stationery';
    return 'Other'; // Default category
  };

  // Initial data loading
  useEffect(() => {
    const initializeApp = async () => {
      setIsLoading(true);
      try {
        // Load user data first
        const userData = await fetchUserData();
        
        if (userData) {
          // Load other data after user is loaded
          await Promise.all([
            fetchActivities(userData.id),
            fetchRewards(),
            fetchCampaigns(userData.id),
            fetchWasteTypes(),
            fetchRecyclingBins()
          ]);
        }
      } catch (error) {
        console.error('Error initializing app:', error);
        setError('Failed to initialize application. Please refresh the page.');
      } finally {
        setIsLoading(false);
      }
    };

    initializeApp();
  }, [fetchUserData, fetchActivities, fetchRewards, fetchCampaigns, fetchWasteTypes, fetchRecyclingBins]);

  // Simulate real-time updates
  useEffect(() => {
    if (!user) return;
    
    const interval = setInterval(() => {
      // Random point updates for demo (approximately once every 5 minutes)
      if (Math.random() > 0.98) {
        const pointsAdded = Math.floor(Math.random() * 25) + 5;
        
        // Update user state
        setUser(prev => ({
          ...prev,
          total_points: prev.total_points + pointsAdded
        }));
        
        addNotification({
          type: 'points_updated',
          message: `New recycling activity verified! +${pointsAdded} points added.`
        });
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [user]);

  // Show loading screen while initializing
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="text-6xl mb-4">♻️</div>
          <div className="text-xl font-bold text-gray-800 mb-2">Reloop</div>
          <div className="text-gray-600 mb-4">Loading Student Dashboard...</div>
          <div className="w-8 h-8 border-4 border-green-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
        </div>
      </div>
    );
  }

  // Show error message if initialization failed
  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="text-6xl mb-4">⚠️</div>
          <div className="text-xl font-bold text-red-800 mb-2">Error</div>
          <div className="text-gray-600 mb-4">{error}</div>
          <button 
            onClick={() => window.location.reload()} 
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Refresh Page
          </button>
        </div>
      </div>
    );
  }

  // Show login message if no user
  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="text-6xl mb-4">🔒</div>
          <div className="text-xl font-bold text-gray-800 mb-2">Reloop</div>
          <div className="text-gray-600 mb-4">Please log in to access the dashboard.</div>
          <button 
            onClick={() => {
              // Simulate login for demo purposes
              setUser({
                id: 'USR0004',
                username: 'PowerViber',
                fullname: 'Dt. Omar Haryanti, M.Pd',
                email: 'user4@its.ac.id',
                phone: '+62(061)849-5931',
                registration_date: '2023-07-21 15:56:07',
                total_points: 456,
                status: 'active',
                faculty_id: 'F005',
                dept_id: 'FD026'
              });
            }} 
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Log In
          </button>
        </div>
      </div>
    );
  }

  // Main render function to determine which content to display
  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return (
          <Dashboard 
            user={user}
            stats={stats}
            activities={activities}
            onAddActivity={() => setShowAddActivity(true)}
            onViewAllActivities={() => setActiveTab('activities')}
            onBrowseRewards={() => setActiveTab('rewards')}
            onJoinCampaign={() => setActiveTab('campaigns')}
          />
        );
      case 'activities':
        return (
          <Activities 
            activities={activities}
            onAddActivity={() => setShowAddActivity(true)}
          />
        );
      case 'rewards':
        return (
          <Rewards 
            rewards={rewards}
            userPoints={user.total_points}
            onRedeemReward={redeemReward}
          />
        );
      case 'campaigns':
        return (
          <UsersLeaderboard 
            campaigns={campaigns}
            onJoinCampaign={joinCampaign}
          />
        );
      case 'profile':
        return (
          <Profile 
            user={user}
            stats={stats}
          />
        );
      default:
        return <Dashboard />;
    }
  };

  // Context value to be provided to all components
  const contextValue = {
    user,
    stats,
    activities,
    rewards,
    campaigns,
    loading,
    notifications,
    activeTab,
    setActiveTab,
    addNotification,
    addActivity,
    redeemReward,
    joinCampaign,
    wasteTypes,
    recyclingBins,
    currentDateTime
  };

  return (
    <AppContext.Provider value={contextValue}>
      <div className="flex min-h-screen bg-gray-100">
        <Sidebar />
        <main className="flex-1 overflow-auto">
          <div className="p-6">
            {renderContent()}
          </div>
        </main>
        
        {showAddActivity && (
          <AddActivities 
            onClose={() => setShowAddActivity(false)}
            onSubmit={addActivity}
            loading={loading}
            wasteTypes={wasteTypes}
            recyclingBins={recyclingBins}
          />
        )}
        
        {/* Display notifications */}
        <div className="fixed top-4 right-4 max-w-sm z-50 space-y-2">
          {notifications.map((notification, index) => (
            <Notification 
              key={notification.id || index}
              type={notification.type}
              message={notification.message}
              timestamp={notification.timestamp}
              onClose={() => setNotifications(prev => prev.filter((_, i) => i !== index))}
            />
          ))}
        </div>
      </div>
    </AppContext.Provider>
  );
};

export default App;