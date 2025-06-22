const AddActivityModal = () => {
    const [formData, setFormData] = useState({
      waste_type: '',
      weight: '',
      location: '',
      notes: ''
    });

    const handleSubmit = async (e) => {
      e.preventDefault();
      setLoading(true);
      
      try {
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1500));
        
        const newActivity = {
          id: activities.length + 1,
          waste_type: formData.waste_type,
          weight: parseFloat(formData.weight),
          points_earned: Math.floor(parseFloat(formData.weight) * 10),
          status: 'pending',
          timestamp: new Date().toLocaleString(),
          location: formData.location
        };
        
        setActivities(prev => [newActivity, ...prev]);
        setShowAddActivity(false);
        setFormData({ waste_type: '', weight: '', location: '', notes: '' });
        
        setNotifications(prev => [{
          type: 'activity_added',
          message: 'Recycling activity submitted for verification!',
          timestamp: new Date().toLocaleTimeString()
        }, ...prev.slice(0, 4)]);
        
      } catch (error) {
        console.error('Error adding activity:', error);
      } finally {
        setLoading(false);
      }
    };

    if (!showAddActivity) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white rounded-xl max-w-md w-full p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-gray-800">Add Recycling Activity</h3>
            <button 
              onClick={() => setShowAddActivity(false)}
              className="text-gray-500 hover:text-gray-700"
            >
              ✕
            </button>
          </div>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Waste Type *
              </label>
              <select 
                value={formData.waste_type}
                onChange={(e) => setFormData(prev => ({ ...prev, waste_type: e.target.value }))}
                className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                required
              >
                <option value="">Select waste type</option>
                <option value="Plastik">Plastik (10 pts/kg)</option>
                <option value="Kertas">Kertas (8 pts/kg)</option>
                <option value="Logam">Logam (15 pts/kg)</option>
                <option value="Kaca">Kaca (12 pts/kg)</option>
                <option value="Organik">Organik (5 pts/kg)</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Weight (kg) *
              </label>
              <input 
                type="number"
                step="0.1"
                min="0.1"
                value={formData.weight}
                onChange={(e) => setFormData(prev => ({ ...prev, weight: e.target.value }))}
                className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Enter weight in kg"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Location *
              </label>
              <select 
                value={formData.location}
                onChange={(e) => setFormData(prev => ({ ...prev, location: e.target.value }))}
                className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                required
              >
                <option value="">Select location</option>
                <option value="Gedung A Lt.1">Gedung A Lt.1</option>
                <option value="Gedung A Lt.2">Gedung A Lt.2</option>
                <option value="Gedung B Lt.1">Gedung B Lt.1</option>
                <option value="Gedung C Lt.3">Gedung C Lt.3</option>
                <option value="Kantin Utama">Kantin Utama</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Notes (Optional)
              </label>
              <textarea 
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Additional notes..."
                rows="3"
              />
            </div>
            
            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={() => setShowAddActivity(false)}
                className="flex-1 py-3 px-4 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="flex-1 py-3 px-4 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    Submitting...
                  </>
                ) : (
                  <>
                    <Plus size={18} />
                    Add Activity
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  };

  const RedeemModal = () => {
    if (!showRedeemModal || !selectedReward) return null;
    
    const discountAmount = user.status === 'active' ? Math.floor(selectedReward.points_cost * 0.1) : 0;
    const finalCost = selectedReward.points_cost - discountAmount;
    
    const handleRedeem = async () => {
      setLoading(true);
      
      try {
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1500));
        
        setUser(prev => ({
          ...prev,
          total_points: prev.total_pointsimport React, { useState, useEffect, useCallback } from 'react';
import { 
  Home, 
  Recycle, 
  Gift, 
  Users, 
  User, 
  Bell,
  Scan,
  TrendingUp,
  Trophy,
  Clock,
  MapPin,
  ChevronRight,
  Plus,
  QrCode,
  Camera,
  Weight,
  CheckCircle,
  AlertCircle,
  Star,
  Zap,
  Target,
  Activity
} from 'lucide-react';

const StudentDashboard = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [showAddActivity, setShowAddActivity] = useState(false);
  const [showRedeemModal, setShowRedeemModal] = useState(false);
  const [selectedReward, setSelectedReward] = useState(null);
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(false);
  
  const [user, setUser] = useState({
    id: 1,
    name: 'Ahmad Fauzi',
    npm: '2023110001',
    faculty: 'Teknik Informatika',
    total_points: 1250,
    status: 'active',
    avatar: '🧑‍🎓'
  });

  const [stats, setStats] = useState({
    thisMonth: 45,
    totalActivities: 23,
    redeemedRewards: 3,
    campaignsJoined: 2
  });

  const [activities, setActivities] = useState([
    {
      id: 1,
      waste_type: 'Plastik',
      weight: 2.5,
      points_earned: 25,
      status: 'verified',
      timestamp: '2025-06-20 14:30',
      location: 'Gedung A Lt.2'
    },
    {
      id: 2,
      waste_type: 'Kertas',
      weight: 1.8,
      points_earned: 18,
      status: 'pending',
      timestamp: '2025-06-19 10:15',
      location: 'Gedung B Lt.1'
    }
  ]);

  const [rewards, setRewards] = useState([
    {
      id: 1,
      name: 'Tumbler Eco-Friendly',
      points_cost: 500,
      stock: 12,
      image: '🥤',
      category: 'Drinkware'
    },
    {
      id: 2,
      name: 'Tote Bag Sustainability',
      points_cost: 300,
      stock: 8,
      image: '👜',
      category: 'Bags'
    },
    {
      id: 3,
      name: 'Voucher Kantin Rp.50k',
      points_cost: 800,
      stock: 5,
      image: '🎫',
      category: 'Voucher'
    }
  ]);

  const [campaigns, setCampaigns] = useState([
    {
      id: 1,
      title: 'Plastic Free June',
      description: 'Kurangi penggunaan plastik selama bulan Juni',
      participants: 156,
      end_date: '2025-06-30',
      status: 'active',
      joined: true
    },
    {
      id: 2,
      title: 'Paper Recycling Challenge',
      description: 'Kompetisi daur ulang kertas antar fakultas',
      participants: 89,
      end_date: '2025-07-15',
      status: 'active',
      joined: false
    }
  ]);

  // API Integration functions
  const fetchUserData = useCallback(async () => {
    try {
      const response = await fetch(`/api/user/${user.id}`);
      const userData = await response.json();
      setUser(prev => ({ ...prev, ...userData }));
      setStats(userData.stats || stats);
    } catch (error) {
      console.error('Error fetching user data:', error);
    }
  }, [user.id]);

  const fetchRealtimeUpdates = useCallback(async () => {
    try {
      const response = await fetch(`/api/realtime/${user.id}`);
      const updates = await response.json();
      
      if (updates.has_updates) {
        setNotifications(prev => [...updates.updates, ...prev.slice(0, 4)]);
        // Update points if needed
        const pointsUpdate = updates.updates.find(u => u.type === 'points_updated');
        if (pointsUpdate) {
          fetchUserData();
        }
      }
    } catch (error) {
      console.error('Error fetching updates:', error);
    }
  }, [user.id, fetchUserData]);

  // Simulasi real-time updates yang lebih realistic
  useEffect(() => {
    fetchUserData();
    
    const interval = setInterval(() => {
      fetchRealtimeUpdates();
      
      // Simulasi random point updates for demo
      if (Math.random() > 0.98) {
        setUser(prev => ({
          ...prev,
          total_points: prev.total_points + Math.floor(Math.random() * 25) + 5
        }));
        
        setNotifications(prev => [{
          type: 'points_updated',
          message: 'New recycling activity verified! Points added.',
          timestamp: new Date().toLocaleTimeString()
        }, ...prev.slice(0, 4)]);
      }
    }, 3000);

    return () => clearInterval(interval);
  }, [fetchUserData, fetchRealtimeUpdates]);

  const Sidebar = () => (
    <div className="w-64 bg-gradient-to-b from-green-800 to-green-900 text-white p-6 flex flex-col">
      <div className="flex items-center gap-3 mb-8">
        <div className="text-2xl">♻️</div>
        <div>
          <h1 className="text-xl font-bold">Reloop</h1>
          <p className="text-green-200 text-sm">Student Portal</p>
        </div>
      </div>

      <nav className="space-y-2 flex-1">
        {[
          { id: 'dashboard', icon: Home, label: 'Dashboard' },
          { id: 'activities', icon: Recycle, label: 'My Activities' },
          { id: 'rewards', icon: Gift, label: 'Rewards Store' },
          { id: 'campaigns', icon: Users, label: 'Campaigns' },
          { id: 'profile', icon: User, label: 'Profile' }
        ].map(item => (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-all ${
              activeTab === item.id 
                ? 'bg-white text-green-800 shadow-lg' 
                : 'hover:bg-green-700'
            }`}
          >
            <item.icon size={20} />
            <span className="font-medium">{item.label}</span>
          </button>
        ))}
      </nav>

      <div className="bg-green-700 rounded-lg p-4 mt-6">
        <div className="flex items-center gap-3 mb-2">
          <Trophy className="text-yellow-400" size={20} />
          <span className="font-semibold">Total Points</span>
        </div>
        <div className="text-2xl font-bold text-yellow-400">
          {user.total_points.toLocaleString()}
        </div>
        <div className="text-green-200 text-sm mt-1">
          {user.status === 'active' ? '✨ Active Member' : '💤 Inactive'}
        </div>
      </div>
    </div>
  );

  const DashboardContent = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Welcome back, {user.name}! 👋</h2>
          <p className="text-gray-600">{user.npm} • {user.faculty}</p>
        </div>
        <button className="bg-green-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-green-700 transition-colors">
          <Scan size={18} />
          Scan QR Code
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl p-6 shadow-lg border-l-4 border-blue-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Points This Month</p>
              <p className="text-2xl font-bold text-gray-800">{stats.thisMonth}</p>
            </div>
            <TrendingUp className="text-blue-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white rounded-xl p-6 shadow-lg border-l-4 border-green-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Total Activities</p>
              <p className="text-2xl font-bold text-gray-800">{stats.totalActivities}</p>
            </div>
            <Recycle className="text-green-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white rounded-xl p-6 shadow-lg border-l-4 border-purple-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Rewards Redeemed</p>
              <p className="text-2xl font-bold text-gray-800">{stats.redeemedRewards}</p>
            </div>
            <Gift className="text-purple-500" size={24} />
          </div>
        </div>
        
        <div className="bg-white rounded-xl p-6 shadow-lg border-l-4 border-orange-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600 text-sm">Campaigns Joined</p>
              <p className="text-2xl font-bold text-gray-800">{stats.campaignsJoined}</p>
            </div>
            <Users className="text-orange-500" size={24} />
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-xl p-6 shadow-lg">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="flex items-center gap-3 p-4 bg-green-50 rounded-lg hover:bg-green-100 transition-colors">
            <Plus className="text-green-600" size={20} />
            <span className="font-medium text-green-800">Add Recycling Activity</span>
          </button>
          <button className="flex items-center gap-3 p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors">
            <Gift className="text-purple-600" size={20} />
            <span className="font-medium text-purple-800">Browse Rewards</span>
          </button>
          <button className="flex items-center gap-3 p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors">
            <Users className="text-blue-600" size={20} />
            <span className="font-medium text-blue-800">Join Campaign</span>
          </button>
        </div>
      </div>

      {/* Recent Activities */}
      <div className="bg-white rounded-xl p-6 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-800">Recent Activities</h3>
          <button 
            onClick={() => setActiveTab('activities')}
            className="text-green-600 hover:text-green-700 flex items-center gap-1"
          >
            View all <ChevronRight size={16} />
          </button>
        </div>
        <div className="space-y-3">
          {activities.slice(0, 3).map(activity => (
            <div key={activity.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                  <Recycle className="text-green-600" size={18} />
                </div>
                <div>
                  <p className="font-medium text-gray-800">{activity.waste_type}</p>
                  <p className="text-sm text-gray-600">{activity.weight}kg • {activity.location}</p>
                </div>
              </div>
              <div className="text-right">
                <div className={`px-2 py-1 rounded-full text-xs font-medium ${
                  activity.status === 'verified' 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-yellow-100 text-yellow-800'
                }`}>
                  {activity.status === 'verified' ? '✅ Verified' : '⏳ Pending'}
                </div>
                <p className="text-sm text-gray-600 mt-1">+{activity.points_earned} pts</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const ActivitiesContent = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-800">My Recycling Activities</h2>
        <button className="bg-green-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-green-700 transition-colors">
          <Plus size={18} />
          Add New Activity
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left p-4 font-semibold text-gray-800">Date & Time</th>
                <th className="text-left p-4 font-semibold text-gray-800">Waste Type</th>
                <th className="text-left p-4 font-semibold text-gray-800">Weight (kg)</th>
                <th className="text-left p-4 font-semibold text-gray-800">Location</th>
                <th className="text-left p-4 font-semibold text-gray-800">Points</th>
                <th className="text-left p-4 font-semibold text-gray-800">Status</th>
              </tr>
            </thead>
            <tbody>
              {activities.map(activity => (
                <tr key={activity.id} className="border-b hover:bg-gray-50">
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <Clock size={16} className="text-gray-400" />
                      <span className="text-sm text-gray-600">{activity.timestamp}</span>
                    </div>
                  </td>
                  <td className="p-4 font-medium text-gray-800">{activity.waste_type}</td>
                  <td className="p-4 text-gray-600">{activity.weight}</td>
                  <td className="p-4">
                    <div className="flex items-center gap-1">
                      <MapPin size={14} className="text-gray-400" />
                      <span className="text-sm text-gray-600">{activity.location}</span>
                    </div>
                  </td>
                  <td className="p-4 font-semibold text-green-600">+{activity.points_earned}</td>
                  <td className="p-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      activity.status === 'verified' 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {activity.status === 'verified' ? '✅ Verified' : '⏳ Pending'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );

  const RewardsContent = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-800">Rewards Store</h2>
        <div className="flex items-center gap-4">
          <div className="text-right">
            <p className="text-sm text-gray-600">Available Points</p>
            <p className="text-xl font-bold text-green-600">{user.total_points.toLocaleString()}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {rewards.map(reward => (
          <div key={reward.id} className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
            <div className="p-6">
              <div className="text-center mb-4">
                <div className="text-4xl mb-2">{reward.image}</div>
                <h3 className="text-lg font-semibold text-gray-800">{reward.name}</h3>
                <p className="text-sm text-gray-600">{reward.category}</p>
              </div>
              
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Points Required:</span>
                  <span className="font-bold text-green-600">{reward.points_cost}</span>
                </div>
                
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Stock:</span>
                  <span className={`font-medium ${reward.stock > 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {reward.stock > 0 ? `${reward.stock} available` : 'Out of stock'}
                  </span>
                </div>
                
                <button 
                  disabled={reward.stock === 0 || user.total_points < reward.points_cost}
                  className={`w-full py-2 px-4 rounded-lg font-medium transition-colors ${
                    reward.stock > 0 && user.total_points >= reward.points_cost
                      ? 'bg-green-600 text-white hover:bg-green-700'
                      : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                  }`}
                >
                  {reward.stock === 0 ? 'Out of Stock' : 
                   user.total_points < reward.points_cost ? 'Not Enough Points' : 'Redeem Now'}
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const CampaignsContent = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-800">Sustainability Campaigns</h2>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {campaigns.map(campaign => (
          <div key={campaign.id} className="bg-white rounded-xl shadow-lg p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">{campaign.title}</h3>
                <p className="text-gray-600 text-sm mt-1">{campaign.description}</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                campaign.joined 
                  ? 'bg-green-100 text-green-800' 
                  : 'bg-blue-100 text-blue-800'
              }`}>
                {campaign.joined ? '✅ Joined' : '👥 Available'}
              </span>
            </div>
            
            <div className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600">Participants:</span>
                <span className="font-medium">{campaign.participants} students</span>
              </div>
              
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600">Ends:</span>
                <span className="font-medium">{campaign.end_date}</span>
              </div>
              
              <button 
                disabled={campaign.joined}
                className={`w-full py-2 px-4 rounded-lg font-medium transition-colors ${
                  campaign.joined
                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    : 'bg-blue-600 text-white hover:bg-blue-700'
                }`}
              >
                {campaign.joined ? 'Already Joined' : 'Join Campaign'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const ProfileContent = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-800">My Profile</h2>
      
      <div className="bg-white rounded-xl shadow-lg p-6">
        <div className="flex items-center gap-6 mb-6">
          <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center text-4xl">
            {user.avatar}
          </div>
          <div>
            <h3 className="text-xl font-semibold text-gray-800">{user.name}</h3>
            <p className="text-gray-600">{user.npm}</p>
            <p className="text-gray-600">{user.faculty}</p>
            <div className={`mt-2 px-3 py-1 rounded-full text-xs font-medium inline-block ${
              user.status === 'active' 
                ? 'bg-green-100 text-green-800' 
                : 'bg-gray-100 text-gray-800'
            }`}>
              {user.status === 'active' ? '✨ Active Member' : '💤 Inactive Member'}
            </div>
          </div>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center p-4 bg-green-50 rounded-lg">
            <div className="text-2xl font-bold text-green-600">{user.total_points}</div>
            <div className="text-sm text-gray-600">Total Points</div>
          </div>
          <div className="text-center p-4 bg-blue-50 rounded-lg">
            <div className="text-2xl font-bold text-blue-600">{stats.totalActivities}</div>
            <div className="text-sm text-gray-600">Activities</div>
          </div>
          <div className="text-center p-4 bg-purple-50 rounded-lg">
            <div className="text-2xl font-bold text-purple-600">{stats.redeemedRewards}</div>
            <div className="text-sm text-gray-600">Rewards</div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard': return <DashboardContent />;
      case 'activities': return <ActivitiesContent />;
      case 'rewards': return <RewardsContent />;
      case 'campaigns': return <CampaignsContent />;
      case 'profile': return <ProfileContent />;
      default: return <DashboardContent />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <main className="flex-1 overflow-auto p-6">
        {renderContent()}
      </main>
      
      {/* Real-time notification */}
      <div className="fixed top-4 right-4 max-w-sm">
        <div className="bg-green-600 text-white p-4 rounded-lg shadow-lg flex items-center gap-3 animate-pulse">
          <Bell size={20} />
          <div>
            <p className="font-medium">Real-time Active!</p>
            <p className="text-sm opacity-90">Dashboard auto-updates every 5s</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StudentDashboard;