import React from 'react';
import { FileText, X, Activity } from 'lucide-react';
import clsx from 'clsx';

interface BatchResult {
    file: File;
    status: 'pending' | 'scanning' | 'complete' | 'error';
    data?: any;
    error?: string;
}

interface BatchResultsProps {
    batchQueue: BatchResult[];
    activeData: any;
    setData: (data: any) => void;
    setTarget: (target: string) => void;
    removeBatchItem: (index: number) => void;
    activeTab: string;
}

export const BatchResults: React.FC<BatchResultsProps> = ({ batchQueue, activeData, setData, setTarget, removeBatchItem }) => {
    if (batchQueue.length === 0) return null;

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-fade-in mt-8">
            {batchQueue.map((item, index) => (
                <div
                    key={index}
                    onClick={() => {
                        if (item.data) {
                            setData(item.data);
                            if (item.data.target) setTarget(item.data.target);
                        }
                    }}
                    className={clsx(
                        "bg-gray-900 border rounded-xl p-5 relative overflow-hidden transition-all duration-300",
                        activeData === item.data && activeData !== null ? "border-emerald-500 shadow-[0_0_20px_rgba(16,185,129,0.3)] ring-1 ring-emerald-500" : "border-gray-800 hover:border-gray-600 hover:bg-gray-800/50 cursor-pointer"
                    )}
                >
                    <div className="flex justify-between items-start mb-4">
                        <div className="flex items-center gap-3">
                            <div className={clsx("p-2 rounded-lg",
                                item.status === 'complete' ? (item.data?.summary.malicious ? "bg-red-900/30 text-red-400" : "bg-green-900/30 text-green-400") :
                                    item.status === 'error' ? "bg-red-900/30 text-red-400" : "bg-blue-900/30 text-blue-400"
                            )}>
                                <FileText size={20} />
                            </div>
                            <div className="overflow-hidden">
                                <h4 className="font-semibold text-gray-200 truncate max-w-[150px]" title={item.file.name}>{item.file.name}</h4>
                                <p className="text-xs text-gray-500">{(item.file.size / 1024).toFixed(1)} KB</p>
                            </div>
                        </div>
                        <button
                            onClick={(e) => { e.stopPropagation(); removeBatchItem(index); }}
                            className="text-gray-600 hover:text-red-400 transition-colors bg-transparent p-1 rounded-full hover:bg-gray-800"
                        >
                            <X size={16} />
                        </button>
                    </div>

                    {item.status === 'pending' && <p className="text-gray-500 text-sm">En cola...</p>}
                    {item.status === 'scanning' && (
                        <div className="flex items-center gap-2 text-emerald-400 text-sm">
                            <Activity size={14} className="animate-spin" />
                            Analizando hash...
                        </div>
                    )}
                    {item.status === 'error' && <p className="text-red-400 text-sm">Error: {item.error}</p>}

                    {item.status === 'complete' && item.data && (
                        <div className="space-y-3">
                            <div className="flex justify-between text-sm">
                                <span className="text-red-400 font-bold">{item.data.summary.malicious} Maliciosos</span>
                                <span className="text-green-400 font-bold">{item.data.summary.harmless} Seguros</span>
                            </div>
                            <div className="h-1.5 w-full bg-gray-800 rounded-full overflow-hidden flex">
                                <div className="bg-red-500 h-full" style={{ width: `${(item.data.summary.malicious / (item.data.summary.malicious + item.data.summary.suspicious + item.data.summary.harmless)) * 100}%` }} />
                                <div className="bg-yellow-500 h-full" style={{ width: `${(item.data.summary.suspicious / (item.data.summary.malicious + item.data.summary.suspicious + item.data.summary.harmless)) * 100}%` }} />
                                <div className="bg-green-500 h-full" style={{ width: `${(item.data.summary.harmless / (item.data.summary.malicious + item.data.summary.suspicious + item.data.summary.harmless)) * 100}%` }} />
                            </div>
                            <p className="text-xs text-emerald-500 mt-2 text-center font-medium opacity-0 group-hover:opacity-100 transition-opacity">Clic para ver detalles</p>
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
};
