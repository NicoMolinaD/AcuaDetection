import React, { useState, useEffect } from 'react';
import { scanTarget, uploadFile, getUserLogs } from './services/api';
import { MalcomDashboard } from './components/dashboard/MalcomDashboard';
import { Login } from './components/auth/Login';
import { RansomwareManager } from './components/dashboard/RansomwareManager';
import { SystemLogs } from './components/admin/SystemLogs';
import { UserManagement } from './components/admin/UserManagement';
import { ErrorBoundary } from './components/common/ErrorBoundary';
import { Header } from './components/common/Header';
import { HistoryDrawer } from './components/common/HistoryDrawer';
import { ScanResults } from './components/dashboard/ScanResults';
import { BatchResults } from './components/dashboard/BatchResults';
import { useAuth } from './context/AuthContext';
import { useSessionTimeout } from './hooks/useSessionTimeout';
import { Upload, AlertTriangle, Activity, Database, Terminal, Users, Clock, Search as SearchIcon, Activity as Pulse } from 'lucide-react';
import clsx from 'clsx';

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

interface BatchResult {
    file: File;
    status: 'pending' | 'scanning' | 'complete' | 'error';
    data?: ScanData;
    error?: string;
}

interface HistoryItem {
    id: string;
    timestamp: string;
    target: string;
    filename?: string;
    data: ScanData;
}

const App: React.FC = () => {
    const { user, logout, isLoading } = useAuth();
    useSessionTimeout(); // Set up session timeout and heartbeat
    const [target, setTarget] = useState('');
    const [scanning, setScanning] = useState(false);
    const [data, setData] = useState<ScanData | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [activeTab, setActiveTab] = useState<'input' | 'file' | 'malcom' | 'ransomware' | 'logs' | 'users' | 'history'>('input');
    const [showHistory, setShowHistory] = useState(false);
    const [scanHistory, setScanHistory] = useState<HistoryItem[]>([]);

    const [batchQueue, setBatchQueue] = useState<BatchResult[]>([]);
    const [batchScanning, setBatchScanning] = useState(false);

    useEffect(() => {
        if (user) {
            loadBackendHistory();
        } else {
            setScanHistory([]);
        }
    }, [user?.username]);

    const loadBackendHistory = async () => {
        try {
            const logs = await getUserLogs();
            const historyItems: HistoryItem[] = logs
                .filter((log: any) => log.action === 'SCAN_TARGET' && log.details)
                .map((log: any) => {
                    try {
                        const scanData = JSON.parse(log.details);
                        return {
                            id: log.id.toString(),
                            timestamp: new Date(log.timestamp).toLocaleString(),
                            target: scanData.target || 'N/A',
                            data: scanData
                        };
                    } catch (e) {
                        return null;
                    }
                })
                .filter(Boolean);
            setScanHistory(historyItems);
        } catch (err) {
            console.error("Failed to load backend history", err);
        }
    };

    // Reset navigation and state on login/user change or logout
    useEffect(() => {
        setActiveTab('input');
        setData(null);
        setTarget('');
        setError(null);
    }, [user?.username]); // Trigger on different user logins or logout (user becomes null)

    const addToHistory = (_newData: ScanData, _filename?: string) => {
        loadBackendHistory();
    };

    const handleScan = async () => {
        if (!target) return;
        setScanning(true);
        setError(null);
        setData(null);
        try {
            const result = await scanTarget(target);
            const newData = result;
            setData(newData);
            if (newData.target) setTarget(newData.target);
            addToHistory(newData);
        } catch (err: any) {
            setError(err.message || 'Error al conectar con el servidor');
        } finally {
            setScanning(false);
        }
    };

    const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const newItems: BatchResult[] = Array.from(files).map(file => ({
            file,
            status: 'pending'
        }));

        setBatchQueue(prev => [...prev, ...newItems]);
    };

    const removeBatchItem = (index: number) => {
        setBatchQueue(prev => prev.filter((_, i) => i !== index));
        if (data && batchQueue[index]?.data === data) {
            setData(null);
        }
    };

    const processQueue = async () => {
        if (batchScanning) return;
        setBatchScanning(true);

        const queue = [...batchQueue];
        for (let i = 0; i < queue.length; i++) {
            if (queue[i].status !== 'pending') continue;

            setBatchQueue(prev => {
                const next = [...prev];
                next[i].status = 'scanning';
                return next;
            });

            try {
                const response = await uploadFile(queue[i].file);
                const resultData = response;
                setBatchQueue(prev => {
                    const next = [...prev];
                    next[i].status = 'complete';
                    next[i].data = resultData;
                    return next;
                });
                addToHistory(resultData, queue[i].file.name);
            } catch (err: any) {
                setBatchQueue(prev => {
                    const next = [...prev];
                    next[i].status = 'error';
                    next[i].error = err.message || 'Error de analísis';
                    return next;
                });
            }
        }
        setBatchScanning(false);
    };

    useEffect(() => {
        const pending = batchQueue.some(item => item.status === 'pending');
        if (pending && !batchScanning) {
            processQueue();
        }
    }, [batchQueue, batchScanning]);

    const loadFromHistory = (item: HistoryItem) => {
        setData(item.data);
        setTarget(item.target);
        setActiveTab('input');
        setShowHistory(false);
    };

    if (isLoading) return <div className="min-h-screen bg-gray-950 flex items-center justify-center text-white">Cargando...</div>;
    if (!user) return <Login />;

    const TabButton: React.FC<{ id: typeof activeTab; label: string; icon: any; adminOnly?: boolean }> = ({ id, label, icon: Icon, adminOnly }) => {
        if (adminOnly && !user.is_admin) return null;
        return (
            <button
                onClick={() => setActiveTab(id)}
                className={clsx(
                    "flex items-center gap-2 px-4 sm:px-6 py-2.5 sm:py-3 rounded-lg font-medium transition-all whitespace-nowrap",
                    activeTab === id ? "bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 shadow-lg shadow-emerald-500/5" : "text-gray-400 hover:bg-gray-800"
                )}
            >
                <Icon size={18} />
                <span className="hidden sm:inline">{label}</span>
                <span className="sm:hidden text-xs">{label.split(' ')[0]}</span>
            </button>
        );
    };

    return (
        <div className="min-h-screen bg-gray-950 text-gray-100 font-sans selection:bg-emerald-500/30">
            <Header
                user={user}
                logout={logout}
                showHistory={showHistory}
                setShowHistory={setShowHistory}
                scanHistoryLength={scanHistory.length}
            />

            <HistoryDrawer
                showHistory={showHistory}
                setShowHistory={setShowHistory}
                scanHistory={scanHistory}
                loadFromHistory={loadFromHistory}
                clearHistory={() => { }}
            />

            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                <ErrorBoundary>
                    {/* Navigation Tabs */}
                    <nav className="flex flex-wrap gap-2 mb-8 sm:mb-12 bg-gray-900/30 p-1.5 rounded-xl border border-gray-800/50 w-full lg:max-w-fit overflow-x-auto no-scrollbar">
                        <TabButton id="input" label="Escaneo Rápido" icon={SearchIcon} />
                        <TabButton id="file" label="Analizador de Archivos" icon={Upload} />
                        <TabButton id="malcom" label="Tráfico de Red" icon={Pulse} />
                        <TabButton id="ransomware" label="Inteligencia" icon={Database} adminOnly />
                        <TabButton id="users" label="Usuarios" icon={Users} adminOnly />
                        <TabButton id="logs" label="Logs" icon={Terminal} adminOnly />
                        <TabButton id="history" label="Mi Actividad" icon={Clock} />
                    </nav>

                    {/* Dashboard Views */}
                    {activeTab === 'input' && !data && (
                        <div className="max-w-3xl mx-auto text-center space-y-6 sm:space-y-8 animate-fade-in py-8 sm:py-12">
                            <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight">
                                Central de <span className="text-emerald-500">Ciberinteligencia</span>
                            </h1>
                            <p className="text-base sm:text-lg text-gray-400">Analiza IPs, Hashes y Dominios en tiempo real con inteligencia avanzada.</p>
                            <div className="relative group">
                                <div className="absolute -inset-1 bg-gradient-to-r from-emerald-600 to-blue-600 rounded-2xl blur opacity-25 group-hover:opacity-50 transition duration-1000"></div>
                                <div className="relative flex flex-col sm:flex-row bg-gray-950 border border-gray-800 rounded-2xl p-2">
                                    <input
                                        type="text"
                                        value={target}
                                        onChange={(e) => setTarget(e.target.value)}
                                        placeholder="IP, Hash o Dominio..."
                                        className="flex-1 bg-transparent border-none focus:ring-0 text-white px-4 sm:px-6 py-3 sm:py-4 text-base sm:text-lg font-mono"
                                        onKeyPress={(e) => e.key === 'Enter' && handleScan()}
                                    />
                                    <button
                                        onClick={handleScan}
                                        disabled={scanning || !target}
                                        className="bg-emerald-600 hover:bg-emerald-500 text-white font-bold px-6 sm:px-8 py-3 sm:py-4 rounded-xl transition-all shadow-lg active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                                    >
                                        {scanning ? <Activity className="animate-spin h-5 w-5" /> : <SearchIcon className="h-5 w-5" />}
                                        <span className="sm:inline">Analizar</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'file' && !data && (
                        <div className="max-w-3xl mx-auto py-12">
                            <h2 className="text-3xl font-bold text-center mb-8">Análisis de Archivos por Hash</h2>
                            <label className="flex flex-col items-center justify-center border-2 border-dashed border-gray-800 hover:border-emerald-500/50 bg-gray-900/50 hover:bg-emerald-500/5 rounded-3xl p-16 transition-all cursor-pointer group">
                                <Upload className="w-16 h-16 text-gray-600 group-hover:text-emerald-500 transition-colors mb-6" />
                                <span className="text-xl font-medium text-gray-300">Selecciona o arrastra archivos</span>
                                <span className="text-sm text-gray-500 mt-2">Los archivos no se suben, solo se calcula su hash localmente</span>
                                <input type="file" multiple className="hidden" onChange={handleFileUpload} />
                            </label>
                        </div>
                    )}

                    {error && (
                        <div className="max-w-xl mx-auto bg-red-900/20 border border-red-900/50 p-4 rounded-xl flex items-center gap-3 text-red-200 mt-8">
                            <AlertTriangle className="text-red-500 flex-shrink-0" />
                            <p>{error}</p>
                        </div>
                    )}

                    {(activeTab === 'input' || activeTab === 'file') && data && (
                        <ScanResults
                            data={data}
                            activeTab={activeTab}
                            batchQueueLength={batchQueue.length}
                            goBackToList={() => {
                                setData(null);
                                setTarget('');
                                setError(null);
                            }}
                        />
                    )}

                    {activeTab === 'malcom' && <MalcomDashboard target={target || data?.target || 'Unknown'} isMalicious={data?.summary.malicious ? data.summary.malicious > 0 : false} />}
                    {activeTab === 'ransomware' && user.is_admin && <RansomwareManager />}
                    {activeTab === 'users' && user.is_admin && <UserManagement />}
                    {activeTab === 'logs' && user.is_admin && <SystemLogs />}
                    {activeTab === 'history' && <SystemLogs personal />}

                    {/* Global Processing Queue - Visible across relevant tabs */}
                    {batchQueue.length > 0 && (activeTab === 'input' || activeTab === 'file' || activeTab === 'malcom') && (
                        <div className="mt-12 border-t border-gray-800 pt-8 animate-fade-in relative z-10">
                            <div className="flex items-center justify-between mb-6">
                                <h3 className="text-xl font-bold text-gray-200">Cola de Procesamiento</h3>
                                <button
                                    onClick={() => { setBatchQueue([]); if (data) setData(null); }}
                                    className="text-xs text-red-400 hover:text-red-300 transition-colors"
                                >
                                    Limpiar Todo
                                </button>
                            </div>
                            <BatchResults
                                batchQueue={batchQueue}
                                activeData={data}
                                setData={setData}
                                setTarget={setTarget}
                                removeBatchItem={removeBatchItem}
                                activeTab={activeTab}
                            />
                        </div>
                    )}
                </ErrorBoundary>
            </main>
        </div>
    );
};

export default App;
