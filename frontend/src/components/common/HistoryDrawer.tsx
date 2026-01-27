import React from 'react';
import { History, X } from 'lucide-react';
import clsx from 'clsx';

interface HistoryItem {
    id: string;
    timestamp: string;
    target: string;
    filename?: string;
    data: any;
}

interface HistoryDrawerProps {
    showHistory: boolean;
    setShowHistory: (show: boolean) => void;
    scanHistory: HistoryItem[];
    loadFromHistory: (item: HistoryItem) => void;
    clearHistory: () => void;
}

export const HistoryDrawer: React.FC<HistoryDrawerProps> = ({ showHistory, setShowHistory, scanHistory, loadFromHistory, clearHistory }) => {
    if (!showHistory) return null;

    return (
        <div className="fixed inset-y-0 right-0 w-96 bg-gray-900 border-l border-gray-800 z-50 shadow-2xl animate-slide-in overflow-hidden flex flex-col">
            <div className="p-4 border-b border-gray-800 flex items-center justify-between">
                <h2 className="text-lg font-bold text-gray-200 flex items-center gap-2">
                    <History className="w-5 h-5 text-emerald-400" />
                    Historial de Análisis
                </h2>
                <button onClick={() => setShowHistory(false)} className="text-gray-400 hover:text-white">
                    <X className="w-5 h-5" />
                </button>
            </div>
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
                {scanHistory.length === 0 ? (
                    <p className="text-gray-500 text-center py-8">No hay análisis previos</p>
                ) : (
                    scanHistory.map((item) => (
                        <button
                            key={item.id}
                            onClick={() => loadFromHistory(item)}
                            className="w-full text-left bg-gray-800/50 hover:bg-gray-800 border border-gray-700 rounded-lg p-3 transition-all"
                        >
                            <div className="flex items-center justify-between mb-1">
                                <span className="text-sm font-medium text-gray-200 truncate max-w-[200px]" title={item.target}>
                                    {item.filename || item.target}
                                </span>
                                <span className={clsx("text-xs font-bold",
                                    item.data.summary.malicious > 0 ? "text-red-400" : "text-green-400"
                                )}>
                                    {item.data.summary.malicious > 0 ? 'MALICIOSO' : 'LIMPIO'}
                                </span>
                            </div>
                            <p className="text-xs text-gray-500">{item.timestamp}</p>
                        </button>
                    ))
                )}
            </div>
            {scanHistory.length > 0 && (
                <div className="p-4 border-t border-gray-800">
                    <button
                        onClick={clearHistory}
                        className="w-full text-sm text-red-400 hover:text-red-300 py-2"
                    >
                        Limpiar Historial
                    </button>
                </div>
            )}
        </div>
    );
};
