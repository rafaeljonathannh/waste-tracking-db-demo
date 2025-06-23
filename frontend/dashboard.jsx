import React, { useState, useEffect, useContext } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 2. Dashboard Content Component
// -------------------------------------------------------------------------------- //
const Dashboard = () => {
    // Access global variable for app ID.
    const __app_id = typeof window.__app_id !== 'undefined' ? window.__app_id : 'default-app-id';
    
    // Access context values
    const { db, userId, openAddActivityModal } = useContext(AppContext);

    const [activities, setActivities] = useState([]);
    const [totalPoints, setTotalPoints] = useState(0);
    const [totalWeight, setTotalWeight] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        // Ensure Firebase is ready and userId is available before fetching data
        if (!db || !userId) { 
            setLoading(false); // Stop loading if no valid data source
            return;
        }

        setLoading(true);
        setError(null);

        const activitiesQuery = query(
            collection(db, `artifacts/${__app_id}/users/${userId}/activities`),
            orderBy('timestamp', 'desc') // Order by timestamp to get recent activities
        );

        // Set up a real-time listener for activities from Firestore
        const unsubscribeActivities = onSnapshot(activitiesQuery, (snapshot) => {
            const fetchedActivities = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            setActivities(fetchedActivities);

            // Calculate total points and weight from fetched activities
            let calculatedPoints = 0;
            let calculatedWeight = 0;
            fetchedActivities.forEach(activity => {
                calculatedPoints += activity.points || 0;
                calculatedWeight += activity.weight_kg || 0;
            });
            setTotalPoints(calculatedPoints);
            setTotalWeight(calculatedWeight);
            setLoading(false); // Data loaded, stop loading indicator
        }, (err) => {
            // Handle errors during real-time data fetching
            console.error("Error fetching activities: ", err);
            setError("Failed to load activities. Please try again.");
            setLoading(false);
        });

        // Cleanup the listener when the component unmounts or dependencies change
        return () => unsubscribeActivities();
    }, [db, userId, __app_id]); // Re-run effect if db, userId, or app_id changes

    // Display loading state
    if (loading) return <div className="text-center p-8"><Icon name="Loader" className="animate-spin w-8 h-8 text-green-500 mx-auto" /><p className="mt-2 text-gray-600">Loading Dashboard...</p></div>;
    // Display error state
    if (error) return <div className="text-center p-8 text-red-600"><p>{error}</p></div>;

    return (
        <div className="p-8">
            <h1 className="text-4xl font-bold text-gray-800 mb-6">Dashboard Overview</h1>
            
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
                <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200">
                    <h2 className="text-lg font-semibold text-gray-700 mb-2">Total Points</h2>
                    <p className="text-4xl font-bold text-green-600">{totalPoints}</p>
                    <p className="text-sm text-gray-500 mt-1">from all recycling activities</p>
                </div>
                <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200">
                    <h2 className="text-lg font-semibold text-gray-700 mb-2">Total Waste Recycled</h2>
                    <p className="text-4xl font-bold text-blue-600">{totalWeight.toFixed(2)} kg</p>
                    <p className="text-sm text-gray-500 mt-1">verified contributions</p>
                </div>
                <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200">
                    <h2 className="text-lg font-semibold text-gray-700 mb-2">Active Campaigns Joined</h2>
                    {/* Placeholder for campaigns - this data would ideally come from another Firestore collection */}
                    <p className="text-4xl font-bold text-purple-600">3</p>
                    <p className="text-sm text-gray-500 mt-1">current participation</p>
                </div>
            </div>

            {/* Recent Activities Section */}
            <div className="bg-white p-6 rounded-lg shadow-md">
                <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-bold text-gray-800">Recent Activities</h2>
                    <button
                        onClick={openAddActivityModal}
                        className="bg-green-500 hover:bg-green-600 text-white font-semibold py-2 px-4 rounded-lg shadow-md transition-colors duration-200 flex items-center gap-2"
                    >
                        <Icon name="PlusCircle" className="w-5 h-5" />
                        Add Activity
                    </button>
                </div>
                {activities.length === 0 ? (
                    <p className="text-gray-500 text-center py-4">No activities logged yet. Click "Add Activity" to get started!</p>
                ) : (
                    <div className="overflow-x-auto rounded-lg border border-gray-200">
                        <table className="min-w-full divide-y divide-gray-200">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Weight (kg)</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Points</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-gray-200">
                                {activities.slice(0, 5).map((activity) => ( // Show only top 5 recent activities
                                    <tr key={activity.id}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            {activity.timestamp?.toDate ? activity.timestamp.toDate().toLocaleDateString() : 'N/A'}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{activity.wasteType || 'General Waste'}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{activity.weight_kg?.toFixed(2) || '0.00'}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{activity.points || 0}</td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full
                                                ${activity.status === 'verified' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                                                {activity.status || 'Pending'}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Dashboard;
