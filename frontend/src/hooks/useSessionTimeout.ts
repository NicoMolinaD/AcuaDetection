import { useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { sendHeartbeat } from '../services/api';

// Session configuration
const HEARTBEAT_INTERVAL = 2 * 60 * 1000; // 2 minutes
const INACTIVITY_TIMEOUT = 5 * 60 * 1000; // 5 minutes
const INACTIVITY_WARNING = 4.5 * 60 * 1000; // 4.5 minutes (show warning)

export const useSessionTimeout = () => {
    const { logout, token } = useAuth();
    const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const warningTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
    const lastActivityRef = useRef<number>(Date.now());
    const warningShownRef = useRef<boolean>(false);

    const resetInactivityTimer = useCallback(() => {
        lastActivityRef.current = Date.now();
        warningShownRef.current = false;

        // Clear existing timers
        if (inactivityTimerRef.current) {
            clearTimeout(inactivityTimerRef.current);
        }
        if (warningTimerRef.current) {
            clearTimeout(warningTimerRef.current);
        }

        // Set warning at 4.5 minutes
        warningTimerRef.current = setTimeout(() => {
            if (!warningShownRef.current) {
                warningShownRef.current = true;
                // Could add a toast notification here if desired
            }
        }, INACTIVITY_WARNING);

        // Set logout at 5 minutes
        inactivityTimerRef.current = setTimeout(() => {
            console.warn('Session timeout: logging out due to 5 minutes of inactivity');
            // Show notification before logout
            alert('Desconexión por inactividad');
            logout();
        }, INACTIVITY_TIMEOUT);
    }, [logout]);

    const sendHeartbeatPing = useCallback(async () => {
        if (!token) return;

        try {
            await sendHeartbeat();
            resetInactivityTimer();
        } catch (error) {
            console.error('Heartbeat failed:', error);
        }
    }, [token, resetInactivityTimer]);

    // Set up activity listeners
    useEffect(() => {
        if (!token) {
            // Clear timers if no token
            if (inactivityTimerRef.current) clearTimeout(inactivityTimerRef.current);
            if (warningTimerRef.current) clearTimeout(warningTimerRef.current);
            if (heartbeatTimerRef.current) clearInterval(heartbeatTimerRef.current);
            return;
        }

        // Initialize inactivity timer
        resetInactivityTimer();

        // Set up heartbeat (keeps session alive)
        heartbeatTimerRef.current = setInterval(sendHeartbeatPing, HEARTBEAT_INTERVAL);

        // Track user activity (mouse, keyboard, touch)
        const activityEvents = ['mousedown', 'keydown', 'touchstart', 'click'];

        const handleActivity = () => {
            resetInactivityTimer();
        };

        activityEvents.forEach(event => {
            window.addEventListener(event, handleActivity);
        });

        // Cleanup
        return () => {
            if (inactivityTimerRef.current) clearTimeout(inactivityTimerRef.current);
            if (warningTimerRef.current) clearTimeout(warningTimerRef.current);
            if (heartbeatTimerRef.current) clearInterval(heartbeatTimerRef.current);
            activityEvents.forEach(event => {
                window.removeEventListener(event, handleActivity);
            });
        };
    }, [token, resetInactivityTimer, sendHeartbeatPing]);
};
