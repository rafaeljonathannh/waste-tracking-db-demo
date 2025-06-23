import { createContext } from 'react';

// Defines and exports the AppContext to be used throughout the application.
// This context will provide Firebase instances, user ID, navigation state,
// and notification functions to consuming components.
export const AppContext = createContext();
