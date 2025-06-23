import React, { useContext } from 'react';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 8. Notification Toast Component
// -------------------------------------------------------------------------------- //
const Notification = () => {
    // Access context values
    const { notifications, removeNotification } = useContext(AppContext);

    return (
        <div className="fixed top-4 right-4 max-w-xs w-full z-50 flex flex-col gap-3">
            {notifications.map((notification) => (
                <div
                    key={notification.id}
                    className={`p-4 rounded-lg shadow-lg flex items-center gap-3 transition-all duration-300 transform
                        ${notification.type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'}
                        ${notification.fade ? 'opacity-0 -translate-y-4' : 'opacity-100 translate-y-0'}
                    `}
                    // Apply animation based on 'fade' property
                    style={{ animation: notification.fade ? 'none' : 'fadeInOut 5s forwards' }}
                >
                    {/* Display appropriate icon based on notification type */}
                    <Icon name={notification.type === 'success' ? 'CheckCircle' : 'X'} className="w-6 h-6" />
                    <div>
                        <p className="font-medium">{notification.message}</p>
                        {/* Special message for dashboard update notifications */}
                        {notification.type === 'dashboard_update' && (
                            <p className="text-sm opacity-90">Dashboard auto-updates every 5s</p>
                        )}
                    </div>
                    {/* Button to manually close the notification */}
                    <button onClick={() => removeNotification(notification.id)} className="ml-auto text-white opacity-75 hover:opacity-100">
                        <Icon name="X" className="w-5 h-5" />
                    </button>
                </div>
            ))}
        </div>
    );
};

export default Notification;
