import React, { useState, useEffect, useContext } from 'react';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 7. Add Activity Modal Component
// -------------------------------------------------------------------------------- //
const AddActivityModal = () => {
    // Access global variable for app ID.
    const __app_id = typeof window.__app_id !== 'undefined' ? window.__app_id : 'default-app-id';
    
    // Access context values
    const { isAddActivityModalOpen, closeAddActivityModal, db, userId, showNotification } = useContext(AppContext);
    
    // Local state for form inputs and submission status
    const [wasteType, setWasteType] = useState('');
    const [weight, setWeight] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState(null);

    const handleSubmit = async (e) => {
        e.preventDefault(); // Prevent default form submission behavior
        setError(null); // Clear previous errors
        setSubmitting(true); // Set submitting state to true

        // Basic validation: Check if Firebase is initialized and user is authenticated
        if (!db || !userId) {
            setError("Database not initialized or user not authenticated. Please ensure the main App is running and authenticated.");
            setSubmitting(false);
            return;
        }

        // Validate form inputs
        if (!wasteType || !weight || isNaN(parseFloat(weight)) || parseFloat(weight) <= 0) {
            setError("Please provide a valid waste type and weight (must be a positive number).");
            setSubmitting(false);
            return;
        }

        const weightKg = parseFloat(weight);
        // Simple point conversion logic (e.g., 1 kg = 10 points)
        const pointsEarned = Math.round(weightKg * 10);

        try {
            // Add a new document to the 'activities' subcollection for the current user
            // The path includes `artifacts/{__app_id}/users/{userId}/activities` for private user data.
            await addDoc(collection(db, `artifacts/${__app_id}/users/${userId}/activities`), {
                wasteType: wasteType,
                weight_kg: weightKg,
                points: pointsEarned,
                status: 'pending_verification', // Initial status for new activities
                timestamp: serverTimestamp(), // Firestore's server timestamp for consistency
                userId: userId // Store userId within the document for easier querying if needed
            });

            showNotification('Activity added successfully!', 'success'); // Show success notification
            // Reset form fields and close modal on success
            setWasteType('');
            setWeight('');
            closeAddActivityModal();
        } catch (e) {
            // Handle errors during Firestore operation
            console.error("Error adding document: ", e);
            setError("Failed to add activity. Please try again.");
            showNotification('Failed to add activity!', 'error');
        } finally {
            setSubmitting(false); // Reset submitting state
        }
    };

    // If the modal is not open, return null to render nothing
    if (!isAddActivityModalOpen) return null;

    return (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75 flex items-center justify-center p-4 z-50">
            <div className="bg-white p-8 rounded-lg shadow-xl w-full max-w-md relative animate-fade-in-up">
                {/* Close button for the modal */}
                <button
                    onClick={closeAddActivityModal}
                    className="absolute top-4 right-4 text-gray-500 hover:text-gray-700 transition-colors duration-200"
                >
                    <Icon name="X" className="w-6 h-6" />
                </button>
                <h2 className="text-2xl font-bold text-gray-800 mb-6 text-center">Add New Recycling Activity</h2>
                <form onSubmit={handleSubmit}>
                    {/* Waste Type Selection */}
                    <div className="mb-4">
                        <label htmlFor="wasteType" className="block text-gray-700 text-sm font-medium mb-2">Waste Type</label>
                        <select
                            id="wasteType"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all duration-200"
                            value={wasteType}
                            onChange={(e) => setWasteType(e.target.value)}
                            required
                        >
                            <option value="">Select a waste type</option>
                            <option value="Plastic">Plastic</option>
                            <option value="Paper">Paper</option>
                            <option value="Glass">Glass</option>
                            <option value="Metal">Metal</option>
                            <option value="Organic">Organic</option>
                            <option value="Electronic">Electronic</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    {/* Weight Input */}
                    <div className="mb-6">
                        <label htmlFor="weight" className="block text-gray-700 text-sm font-medium mb-2">Weight (kg)</label>
                        <input
                            type="number"
                            id="weight"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all duration-200"
                            placeholder="e.g., 2.5"
                            step="0.01" // Allows decimal values
                            min="0.01" // Ensures positive weight
                            value={weight}
                            onChange={(e) => setWeight(e.target.value)}
                            required
                        />
                    </div>
                    {/* Error message display */}
                    {error && <p className="text-red-500 text-sm mb-4 text-center">{error}</p>}
                    {/* Submit button */}
                    <button
                        type="submit"
                        className="w-full bg-green-600 hover:bg-green-700 text-white font-semibold py-3 rounded-lg shadow-md transition-colors duration-200 flex items-center justify-center gap-2"
                        disabled={submitting} // Disable button while submitting
                    >
                        {submitting && <Icon name="Loader" className="animate-spin w-5 h-5" />}
                        {submitting ? 'Adding...' : 'Add Activity'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default AddActivityModal;
