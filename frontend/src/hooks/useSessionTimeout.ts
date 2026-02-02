import { useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { sendHeartbeat } from '../services/api';

// Session configuration
const HEARTBEAT_INTERVAL = 4 * 60 * 1000; // 4 minutes
const INACTIVITY_TIMEOUT = 15 * 60 * 1000; // 15 minutes

export const useSessionTimeout = () => {
    const { logout, token } = useAuth();
    const inactivityTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
    const lastActivityRef = useRef<number>(Date.now());

    const resetInactivityTimer = useCallback(() => {
        lastActivityRef.current = Date.now();

        // Clear existing timer
        if (inactivityTimerRef.current) {
            clearTimeout(inactivityTimerRef.current);
        }

        // Set new inactivity timeout
        inactivityTimerRef.current = setTimeout(() => {
            console.warn('Session timeout: logging out due to inactivity');
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
            if (heartbeatTimerRef.current) clearTimeout(heartbeatTimerRef.current);
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
            if (heartbeatTimerRef.current) clearInterval(heartbeatTimerRef.current);
            activityEvents.forEach(event => {
                window.removeEventListener(event, handleActivity);
            });
        };
    }, [token, resetInactivityTimer, sendHeartbeatPing]);
};
