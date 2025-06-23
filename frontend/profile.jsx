import React, { useState, useEffect, useContext } from 'react';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 6. Profile Content Component
// -------------------------------------------------------------------------------- //
const ProfileContent = () => {
    // Access context values
    const { auth, userId } = useContext(AppContext);

    const [profileData, setProfileData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        // Only set profile data once authentication is ready and userId is known
        if (auth && userId) {
            setLoading(false);
            setProfileData({
                id: userId, // The authenticated user's ID
                email: auth.currentUser?.email || 'N/A', // User's email from Firebase Auth, if available
                status: 'Active', // Placeholder status
                faculty: 'Computer Science', // Placeholder faculty
            });
        } else if (!auth) {
            // Handle case where Firebase Auth is not yet initialized
            setError("Authentication not ready.");
            setLoading(false);
        }
    }, [auth, userId]); // Dependencies: re-run when auth or userId changes

    // Display loading state
    if (loading) return <div className="text-center p-8"><Icon name="Loader" className="animate-spin w-8 h-8 text-green-500 mx-auto" /><p className="mt-2 text-gray-600">Loading Profile...</p></div>;
    // Display error state
    if (error) return <div className="text-center p-8 text-red-600"><p>{error}</p></div>;
    // Display message if no profile data could be loaded
    if (!profileData) return <div className="text-center p-8 text-gray-500"><p>No profile data available. Please ensure you are logged in.</p></div>;

    return (
        <div className="p-8">
            <h1 className="text-4xl font-bold text-gray-800 mb-6">My Profile</h1>
            <div className="bg-white p-6 rounded-lg shadow-md max-w-2xl mx-auto">
                <div className="mb-4">
                    <p className="text-gray-600">User ID:</p>
                    <p className="text-lg font-semibold text-gray-800 break-all">{profileData.id}</p>
                </div>
                <div className="mb-4">
                    <p className="text-gray-600">Email:</p>
                    <p className="text-lg font-semibold text-gray-800">{profileData.email}</p>
                </div>
                <div className="mb-4">
                    <p className="text-gray-600">Status:</p>
                    <p className="text-lg font-semibold text-gray-800">{profileData.status}</p>
                </div>
                <div className="mb-4">
                    <p className="text-gray-600">Faculty:</p>
                    <p className="text-lg font-semibold text-gray-800">{profileData.faculty}</p>
                </div>
                <p className="text-sm text-gray-500 mt-6">
                    Note: For a full profile, additional data fields (name, faculty, etc.) would typically be fetched from a dedicated 'users' collection in Firestore, separate from authentication details.
                </p>
            </div>
        </div>
    );
};

export default ProfileContent;
