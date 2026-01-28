import React from 'react';
import { ShieldAlert, ShieldQuestion, CheckCircle, Search } from 'lucide-react';
import { ThreatChart } from '../common/ThreatChart';
import { SecurityEngineTable } from '../common/SecurityEngineTable';

interface ScanData {
    summary: {
        malicious: number;
        suspicious: number;
        harmless: number;
        undetected: number;
    };
    target?: string;
    scans: any[];
    mode: string;
    target_type: string;
}

interface ScanResultsProps {
    data: ScanData;
    activeTab: string;
    batchQueueLength: number;
    goBackToList: () => void;
}

export const ScanResults: React.FC<ScanResultsProps> = ({ data, activeTab, batchQueueLength, goBackToList }) => {
    if (!data || (activeTab !== 'input' && activeTab !== 'file')) return null;

    return (
        <div className="space-y-8 animate-fade-in">
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                    <h2 className="text-2xl font-bold text-white">Resultados del Escaneo</h2>
                    <span className={`text-sm font-semibold px-3 py-1 rounded-full ${
                        data.mode === 'demo' 
                            ? 'bg-amber-900/30 text-amber-300 border border-amber-700/50' 
                            : 'bg-emerald-900/30 text-emerald-300 border border-emerald-700/50'
                    }`}>
                        {data.mode === 'demo' ? '⚠️ MODO DEMO' : '✓ ANÁLISIS EN VIVO'}
                    </span>
                </div>
                <button
                    onClick={goBackToList}
                    className="flex items-center gap-2 px-5 py-2.5 bg-emerald-600/20 hover:bg-emerald-600/30 border border-emerald-500/30 hover:border-emerald-500/50 text-emerald-400 rounded-lg transition-all font-medium shadow-lg shadow-emerald-500/10 hover:shadow-emerald-500/20 z-10"
                >
                    <Search className="w-4 h-4" />
                    {batchQueueLength > 0 ? 'Volver a la Lista' : 'Nuevo Escaneo'}
                </button>
            </div>

            {data.mode === 'demo' && (
                <div className="bg-amber-900/20 border border-amber-700/50 rounded-lg p-4 flex items-start gap-3">
                    <div className="text-2xl">⚠️</div>
                    <div>
                        <p className="text-amber-200 font-semibold mb-1">Modo Demostración</p>
                        <p className="text-amber-300 text-sm">Las claves de API no están configuradas. Los resultados mostrados son limitados. Configure las API keys en el backend para obtener análisis en vivo contra VirusTotal, MalwareBazaar y otros motores de detección.</p>
                    </div>
                </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-gray-900 border border-red-900/30 rounded-2xl p-6 relative overflow-hidden group">
                    <div className="absolute top-0 right-0 -mr-4 -mt-4 w-24 h-24 bg-red-500/10 rounded-full blur-2xl group-hover:bg-red-500/20 transition-all"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-3 mb-2">
                            <ShieldAlert className="text-red-500" />
                            <h3 className="text-gray-400 font-medium tracking-wide">MALICIOSO</h3>
                        </div>
                        <p className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-br from-red-400 to-orange-600">{data.summary.malicious}</p>
                    </div>
                </div>

                <div className="bg-gray-900/50 backdrop-blur border border-yellow-900/30 rounded-2xl p-6 relative overflow-hidden group hover:border-yellow-500/50 transition-all duration-500">
                    <div className="absolute top-0 right-0 -mr-4 -mt-4 w-32 h-32 bg-yellow-500/10 rounded-full blur-3xl group-hover:bg-yellow-500/20 transition-all"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-3 mb-2">
                            <ShieldQuestion className="text-yellow-500" />
                            <h3 className="text-gray-400 font-medium tracking-wide">SOSPECHOSO</h3>
                        </div>
                        <p className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-br from-yellow-400 to-amber-600">{data.summary.suspicious}</p>
                    </div>
                </div>

                <div className="bg-gray-900/50 backdrop-blur border border-emerald-900/30 rounded-2xl p-6 relative overflow-hidden group hover:border-emerald-500/50 transition-all duration-500">
                    <div className="absolute top-0 right-0 -mr-4 -mt-4 w-32 h-32 bg-emerald-500/10 rounded-full blur-3xl group-hover:bg-emerald-500/20 transition-all"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-3 mb-2">
                            <CheckCircle className="text-emerald-500" />
                            <h3 className="text-gray-400 font-medium tracking-wide">SEGURO</h3>
                        </div>
                        <p className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-br from-emerald-400 to-green-600">{data.summary.harmless}</p>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="bg-gray-900 border border-gray-800 rounded-2xl p-6 lg:col-span-1 flex flex-col items-center justify-center">
                    <h3 className="text-lg font-semibold text-gray-200 mb-6 w-full text-left">Resumen de Detección</h3>
                    <div className="w-full max-w-[250px]">
                        <ThreatChart summary={data.summary} />
                    </div>
                </div>

                <div className="bg-gray-900 border border-gray-800 rounded-2xl p-6 lg:col-span-2 overflow-hidden shadow-2xl shadow-black/50">
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-lg font-semibold text-gray-200">Resultados por Motores</h3>
                        <span className="text-xs font-mono text-emerald-400 bg-gray-900 border border-emerald-900/50 px-3 py-1 rounded-full shadow-[0_0_10px_rgba(16,185,129,0.2)]">Tipo de Objetivo: {data.target_type}</span>
                    </div>
                    <div className="max-h-[400px] overflow-y-auto custom-scrollbar">
                        <SecurityEngineTable scans={data.scans} />
                    </div>
                </div>
            </div>
        </div>
    );
};
