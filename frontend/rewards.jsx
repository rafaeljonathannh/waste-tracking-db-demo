import React, { useState, useEffect, useContext } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 4. Rewards Content Component
// -------------------------------------------------------------------------------- //
const Rewards = () => {
    // Access global variable for app ID.
    const __app_id = typeof window.__app_id !== 'undefined' ? window.__app_id : 'default-app-id';
    
    // Access context values
    const { db } = useContext(AppContext);

    const [rewards, setRewards] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        // Ensure Firebase is ready before fetching data
        if (!db) { 
            setLoading(false); // Stop loading if no valid data source
            return;
        }

        setLoading(true);
        setError(null);

        // Firestore query for public rewards data
        const rewardsQuery = query(
            collection(db, `artifacts/${__app_id}/public/data/rewards`),
            orderBy('pointsCost', 'asc') // Order rewards by their point cost
        );

        // Set up real-time listener for rewards
        const unsubscribe = onSnapshot(rewardsQuery, (snapshot) => {
            const fetchedRewards = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            setRewards(fetchedRewards);
            setLoading(false);
        }, (err) => {
            // Handle errors during real-time data fetching
            console.error("Error fetching rewards: ", err);
            setError("Failed to load rewards. Please try again.");
            setLoading(false);
        });

        // Clean up the listener when the component unmounts
        return () => unsubscribe();
    }, [db, __app_id]); // Re-run effect if db or app_id changes

    // Display loading state
    if (loading) return <div className="text-center p-8"><Icon name="Loader" className="animate-spin w-8 h-8 text-green-500 mx-auto" /><p className="mt-2 text-gray-600">Loading Rewards...</p></div>;
    // Display error state
    if (error) return <div className="text-center p-8 text-red-600"><p>{error}</p></div>;

    return (
        <div className="p-8">
            <h1 className="text-4xl font-bold text-gray-800 mb-6">Available Rewards</h1>
            {rewards.length === 0 ? (
                <p className="text-gray-500 text-center py-4">No rewards available at the moment. Check back later!</p>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {rewards.map(reward => (
                        <div key={reward.id} className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 flex flex-col items-center text-center">
                            {/* Placeholder image with fallback */}
                            <img src={reward.imageUrl || `https://placehold.co/100x100/A0DA88/FFFFFF?text=Reward`} alt={reward.name} className="w-24 h-24 object-cover rounded-full mb-4 border-2 border-green-200" />
                            <h2 className="text-xl font-semibold text-gray-800 mb-2">{reward.name}</h2>
                            <p className="text-gray-600 mb-3">{reward.description}</p>
                            <p className="text-2xl font-bold text-green-700">{reward.pointsCost} Points</p>
                            <button className="mt-4 bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded-lg shadow-md transition-colors duration-200">
                                Redeem Reward
                            </button>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Rewards;
