import React, { useState, useEffect, useContext } from 'react';
import { collection, query, orderBy, onSnapshot } from 'firebase/firestore';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 5. Users Content Component
// -------------------------------------------------------------------------------- //
const UsersContent = () => {
    // Access global variable for app ID.
    const __app_id = typeof window.__app_id !== 'undefined' ? window.__app_id : 'default-app-id';
    
    // Access context values
    const { db } = useContext(AppContext);

    const [users, setUsers] = useState([]);
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

        // Query for users. Assuming 'users' collection is public and has 'totalPoints' field.
        // Ensure your Firestore security rules allow public read access to this collection.
        const usersQuery = query(
            collection(db, `artifacts/${__app_id}/public/data/users`),
            orderBy('totalPoints', 'desc') // Order by totalPoints for a leaderboard
        );

        // Set up real-time listener for user data
        const unsubscribe = onSnapshot(usersQuery, (snapshot) => {
            const fetchedUsers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            setUsers(fetchedUsers);
            setLoading(false); // Data loaded
        }, (err) => {
            // Handle errors during real-time data fetching
            console.error("Error fetching users: ", err);
            setError("Failed to load users. Please try again.");
            setLoading(false);
        });

        // Clean up the listener on component unmount
        return () => unsubscribe();
    }, [db, __app_id]); // Re-run effect if db instance or app_id changes

    // Display loading state
    if (loading) return <div className="text-center p-8"><Icon name="Loader" className="animate-spin w-8 h-8 text-green-500 mx-auto" /><p className="mt-2 text-gray-600">Loading Users...</p></div>;
    // Display error state
    if (error) return <div className="text-center p-8 text-red-600"><p>{error}</p></div>;

    return (
        <div className="p-8">
            <h1 className="text-4xl font-bold text-gray-800 mb-6">User Leaderboard</h1>
            {users.length === 0 ? (
                <p className="text-gray-500 text-center py-4">No users found.</p>
            ) : (
                <div className="bg-white p-6 rounded-lg shadow-md overflow-x-auto rounded-lg border border-gray-200">
                    <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rank</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total Points</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User ID</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                            {users.map((user, index) => (
                                <tr key={user.id}>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{index + 1}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{user.name || 'Anonymous User'}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{user.totalPoints || 0}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-xs font-mono text-gray-500 break-all">{user.id}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
};

export default UsersContent;
