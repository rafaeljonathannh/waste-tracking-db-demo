import React, { useState, useEffect, useContext } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

const Activities = () => {
    // Access global variable for app ID.
    const __app_id = typeof window.__app_id !== 'undefined' ? window.__app_id : 'default-app-id';
    
    // Access context values
    const { db, userId, openAddActivityModal } = useContext(AppContext);

    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (!db || !userId) {
            setLoading(false);
            return;
        }

        setLoading(true);
        setError(null);

        const activitiesQuery = query(
            collection(db, `artifacts/${__app_id}/users/${userId}/activities`),
            orderBy('timestamp', 'desc')
        );

        const unsubscribe = onSnapshot(activitiesQuery, (snapshot) => {
            const fetchedActivities = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            setActivities(fetchedActivities);
            setLoading(false);
        }, (err) => {
            console.error("Error fetching all activities: ", err);
            setError("Failed to load activities. Please try again.");
            setLoading(false);
        });

        return () => unsubscribe();
    }, [db, userId, __app_id]);

    if (loading) return <div className="text-center p-8"><Icon name="Loader" className="animate-spin w-8 h-8 text-green-500 mx-auto" /><p className="mt-2 text-gray-600">Loading Activities...</p></div>;
    if (error) return <div className="text-center p-8 text-red-600"><p>{error}</p></div>;

    return (
        <div className="p-8">
            <h1 className="text-4xl font-bold text-gray-800 mb-6">All My Activities</h1>
            <div className="bg-white p-6 rounded-lg shadow-md">
                <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-bold text-gray-800">Recycling Log</h2>
                    <button
                        onClick={openAddActivityModal}
                        className="bg-green-500 hover:bg-green-600 text-white font-semibold py-2 px-4 rounded-lg shadow-md transition-colors duration-200 flex items-center gap-2"
                    >
                        <Icon name="PlusCircle" className="w-5 h-5" />
                        Add New Activity
                    </button>
                </div>
                {activities.length === 0 ? (
                    <p className="text-gray-500 text-center py-4">No activities logged yet. Start recycling!</p>
                ) : (
                    <div className="overflow-x-auto rounded-lg border border-gray-200">
                        <table className="min-w-full divide-y divide-gray-200">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Waste Type</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Weight (kg)</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Points Earned</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-gray-200">
                                {activities.map((activity) => (
                                    <tr key={activity.id}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            {activity.timestamp?.toDate ? activity.timestamp.toDate().toLocaleDateString() : 'N/A'}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{activity.wasteType || 'Unknown'}</td>
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

export default Activities;
