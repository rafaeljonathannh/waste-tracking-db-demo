import React, { useContext } from 'react';
import { AppContext } from './app-context'; // Import AppContext
import { Icon } from './icon'; // Import Icon utility

// -------------------------------------------------------------------------------- //
// 1. Sidebar Component
// -------------------------------------------------------------------------------- //
const Sidebar = () => {
    // Access context values.
    const { currentPage, setCurrentPage, userId } = useContext(AppContext);

    const navItems = [
        { name: 'Dashboard', icon: 'Home', page: 'dashboard' },
        { name: 'Activities', icon: 'Activity', page: 'activities' },
        { name: 'Rewards', icon: 'Award', page: 'rewards' },
        { name: 'Users', icon: 'Users', page: 'users' },
        { name: 'Profile', icon: 'Settings', page: 'profile' },
    ];

    return (
        <aside className="w-64 bg-white shadow-lg p-6 flex flex-col rounded-r-lg">
            <div className="text-2xl font-bold text-green-600 mb-8">Reloop</div>
            <nav>
                <ul>
                    {navItems.map((item) => (
                        <li key={item.page} className="mb-4">
                            <button
                                onClick={() => setCurrentPage(item.page)}
                                className={`flex items-center gap-3 w-full p-3 rounded-lg transition-all duration-200 ease-in-out
                                    ${currentPage === item.page
                                        ? 'bg-green-100 text-green-700 font-semibold shadow-md'
                                        : 'text-gray-600 hover:bg-gray-50 hover:text-green-600'
                                    }`}
                            >
                                <Icon name={item.icon} className="w-5 h-5" />
                                <span>{item.name}</span>
                            </button>
                        </li>
                    ))}
                </ul>
            </nav>
            {/* User ID Display - MANDATORY for multi-user apps */}
            <div className="mt-auto pt-6 text-sm text-gray-500 border-t border-gray-200 rounded-t-lg">
                <p>User ID: <span className="font-mono text-xs break-all">{userId || 'Loading...'}</span></p>
            </div>
        </aside>
    );
};

export default Sidebar;
