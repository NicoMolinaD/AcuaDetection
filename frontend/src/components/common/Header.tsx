import React from 'react';
import { LogOut, History } from 'lucide-react';
import clsx from 'clsx';

interface HeaderProps {
    user: any;
    logout: () => void;
    showHistory: boolean;
    setShowHistory: (show: boolean) => void;
    scanHistoryLength: number;
}

export const Header: React.FC<HeaderProps> = ({ user, logout, showHistory, setShowHistory, scanHistoryLength }) => {
    return (
        <header className="border-b border-gray-800 bg-gray-900/50 backdrop-blur-md sticky top-0 z-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <img src="/logo_custom.png" alt="ThreatGuard Logo" className="w-10 h-10 sm:w-16 sm:h-16 object-contain drop-shadow-[0_0_15px_rgba(34,197,94,0.5)]" />
                    <div>
                        <span className="block text-lg sm:text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 via-teal-500 to-blue-500 tracking-tighter">
                            Panel de Detección
                        </span>
                        <span className="text-[10px] sm:text-xs text-gray-500 font-mono flex items-center gap-1">
                            <span className={clsx("w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full", user?.is_admin ? "bg-red-500 border border-red-400/50 shadow-[0_0_8px_rgba(239,68,68,0.4)]" : "bg-blue-500 border border-blue-400/50 shadow-[0_0_8px_rgba(59,130,246,0.4)]")}></span>
                            {user?.username} <span className="hidden sm:inline">{user?.is_admin && '(ADMIN)'}</span>
                        </span>
                    </div>
                </div>
                <div className="flex items-center gap-2 sm:gap-4">
                    <button
                        onClick={() => setShowHistory(!showHistory)}
                        className="text-gray-400 hover:text-emerald-400 transition-colors relative flex items-center gap-2 p-2 rounded-lg hover:bg-gray-800/50"
                        title="Historial de Análisis"
                    >
                        <History className="w-5 h-5 sm:w-4 sm:h-4" />
                        <span className="hidden sm:inline text-sm font-medium">Historial</span>
                        {scanHistoryLength > 0 && (
                            <span className="absolute -top-1 -right-1 sm:static bg-emerald-500 text-white text-[10px] sm:text-xs px-1.5 py-0.5 rounded-full ring-2 ring-gray-950 sm:ring-0">
                                {scanHistoryLength > 9 ? '9+' : scanHistoryLength}
                            </span>
                        )}
                    </button>
                    <div className="h-6 w-px bg-gray-800 mx-1 sm:mx-2"></div>
                    <button
                        onClick={logout}
                        className="text-gray-400 hover:text-red-400 transition-colors flex items-center gap-2 p-2 rounded-lg hover:bg-gray-800/50"
                        title="Cerrar Sesión"
                    >
                        <LogOut className="w-5 h-5 sm:w-4 sm:h-4" />
                        <span className="hidden sm:inline text-sm">Salir</span>
                    </button>
                </div>
            </div>
        </header>
    );
};
