import React, { useEffect, useState } from 'react';
import { fetchMalcomData } from '../../services/api';
import { Activity, AlertTriangle, Network, Shield, Globe, Maximize, X } from 'lucide-react';

interface Node {
    id: string;
    type: 'source' | 'destination' | 'malware';
    label: string;
    risk_score: number;
    x?: number;
    y?: number;
}

interface Link {
    source: string;
    target: string;
    protocol: string;
    port: number;
}

interface MalcomData {
    nodes: Node[];
    links: Link[];
    stats: {
        total_connections: number;
        malicious_hits: number;
        bytes_transferred: string;
    };
}

interface MalcomDashboardProps {
    target?: string;
    isMalicious?: boolean;
}

export const MalcomDashboard: React.FC<MalcomDashboardProps> = ({ target, isMalicious }) => {
    const [data, setData] = useState<MalcomData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const [isExpanded, setIsExpanded] = useState(false);

    useEffect(() => {
        const loadData = async () => {
            setLoading(true);
            try {
                const result = await fetchMalcomData(target, isMalicious);
                const typedData: MalcomData = {
                    nodes: result.data.nodes.map((node: any) => ({
                        ...node,
                        type: node.type as 'source' | 'destination' | 'malware'
                    })),
                    links: result.data.links,
                    stats: result.data.stats
                };
                setData(typedData);
            } catch (err: any) {
                setError(err.message || 'Error cargando datos de Malcom');
            } finally {
                setLoading(false);
            }
        };
        loadData();
    }, [target, isMalicious]);

    const [nodes, setNodes] = useState<Node[]>([]);

    // Layout logic for both mini and expanded views
    const runLayout = (width: number, height: number) => {
        if (!data) return;

        const center = { x: width / 2, y: height / 2 };
        const newNodes = data.nodes.map((node, i) => {
            // Keep source centered
            if (node.type === 'source') {
                return { ...node, x: center.x, y: center.y };
            }

            const angle = (i / data.nodes.length) * 2 * Math.PI;
            const radius = Math.min(width, height) * 0.35;
            const r = node.type === 'malware' ? radius * 1.2 : radius;

            return {
                ...node,
                x: center.x + Math.cos(angle) * r,
                y: center.y + Math.sin(angle) * r
            };
        });
        setNodes(newNodes);
    };


    useEffect(() => {
        runLayout(800, 500);
    }, [data]);

    useEffect(() => {
        if (isExpanded) {
            runLayout(1200, 800);
        } else {
            runLayout(800, 500);
        }
    }, [isExpanded, data]);


    if (loading) return <div className="text-center p-20"><Activity className="animate-spin h-12 w-12 text-cyan-500 mx-auto" /></div>;
    if (error) return <div className="text-center p-20 text-red-400"><AlertTriangle className="h-12 w-12 mx-auto mb-4" />{error}</div>;
    if (!data) return null;

    const renderGraph = (width: number, height: number, isFull: boolean) => (
        <div className="relative w-full h-full bg-gray-950 rounded-xl overflow-hidden">
            {!isFull && (
                <button
                    onClick={() => setIsExpanded(true)}
                    className="absolute top-4 right-4 z-20 bg-gray-800 hover:bg-gray-700 text-cyan-400 p-2 rounded-lg transition-colors border border-gray-700"
                    title="Ampliar Mapa"
                >
                    <Maximize size={20} />
                </button>
            )}
            {isFull && (
                <button
                    onClick={() => setIsExpanded(false)}
                    className="absolute top-4 right-4 z-20 bg-gray-800 hover:bg-gray-700 text-gray-200 p-2 rounded-lg transition-colors border border-gray-700"
                    title="Cerrar"
                >
                    <X size={20} />
                </button>
            )}

            <h3 className="text-lg font-semibold text-gray-300 absolute top-4 left-4 z-10 pointer-events-none">
                {isFull ? "Análisis Detallado de Red" : "Mapa de Conexiones"}
            </h3>

            <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-full">
                {data.links.map((link, i) => {
                    const sourceNode = nodes.find(n => n.id === link.source);
                    const targetNode = nodes.find(n => n.id === link.target);
                    if (!sourceNode || !targetNode || !sourceNode.x || !targetNode.x) return null;

                    const isMalicious = sourceNode.type === 'malware' || targetNode.type === 'malware';

                    return (
                        <g key={i}>
                            <line
                                x1={sourceNode.x} y1={sourceNode.y}
                                x2={targetNode.x} y2={targetNode.y}
                                stroke={isMalicious ? "rgba(239, 68, 68, 0.4)" : "rgba(56, 189, 248, 0.2)"}
                                strokeWidth={isMalicious ? 2 : 1}
                                strokeDasharray={isMalicious ? "5,5" : "none"}
                            />
                        </g>
                    );
                })}

                {/* Nodes */}
                {nodes.map((node, i) => (
                    <g key={i} transform={`translate(${node.x},${node.y})`} className="cursor-pointer hover:opacity-80 transition-opacity">
                        <circle
                            r={node.type === 'source' ? (isFull ? 30 : 20) : (isFull ? 18 : 12)}
                            fill={node.type === 'malware' ? "#ef4444" : node.type === 'source' ? "#3b82f6" : "#10b981"}
                            opacity="0.9"
                            stroke="#1f2937"
                            strokeWidth="2"
                        />
                        <text
                            y={node.type === 'source' ? (isFull ? 45 : 35) : (isFull ? 35 : 25)}
                            textAnchor="middle"
                            fill={node.type === 'malware' ? "#fca5a5" : "#e5e7eb"}
                            fontSize={isFull ? "14" : "12"}
                            className="font-mono select-none"
                            style={{ textShadow: '0px 1px 3px rgba(0,0,0,0.8)' }}
                        >
                            {node.label}
                        </text>
                    </g>
                ))}
            </svg>

            <div className="absolute bottom-4 right-4 flex gap-4 text-xs bg-gray-900/80 p-2 rounded-lg backdrop-blur-sm border border-gray-800">
                <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-blue-500"></span> Objetivo</div>
                <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-green-500"></span> Seguro</div>
                <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-red-500"></span> Malicioso</div>
            </div>
        </div>
    );

    return (
        <div className="space-y-6 animate-fade-in relative">
            {/* Modal Overlay for Fullscreen */}
            {isExpanded && (
                <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in">
                    <div className="w-[95vw] h-[90vh] bg-gray-900 border border-gray-700 rounded-2xl shadow-2xl overflow-hidden flex flex-col">
                        <div className="flex-1 min-h-0">
                            {renderGraph(1200, 800, true)}
                        </div>
                    </div>
                </div>
            )}

            <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 mb-8">
                <div>
                    <h2 className="text-2xl sm:text-3xl font-bold text-gray-100 flex items-center gap-3">
                        <Network className="text-violet-500" />
                        Network Analysis
                    </h2>
                    <p className="text-sm sm:text-base text-gray-400 mt-1">Tráfico de red y detección de amenazas</p>
                </div>
                <div className="flex gap-4 w-full sm:w-auto">
                    <div className="flex-1 sm:flex-none bg-gray-900 border border-gray-800 px-4 py-2 rounded-xl text-center">
                        <p className="text-[10px] text-gray-500 uppercase tracking-wider">Conexiones</p>
                        <p className="text-lg sm:text-xl font-bold text-cyan-400">{data.stats.total_connections}</p>
                    </div>
                    <div className="flex-1 sm:flex-none bg-gray-900 border border-red-900/30 px-4 py-2 rounded-xl text-center">
                        <p className="text-[10px] text-red-400 uppercase tracking-wider">Amenazas</p>
                        <p className="text-lg sm:text-xl font-bold text-red-500">{data.stats.malicious_hits}</p>
                    </div>
                </div>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Network Graph (Main View) */}
                <div className="lg:col-span-2 bg-gray-900 border border-gray-800 rounded-2xl p-4 overflow-hidden shadow-2xl relative min-h-[500px]">
                    {renderGraph(800, 500, false)}
                </div>

                {/* Details / List */}
                <div className="bg-gray-900 border border-gray-800 rounded-2xl p-6 flex flex-col h-[500px]">
                    <h3 className="text-lg font-semibold text-gray-200 mb-4">Registro de Tráfico</h3>
                    <div className="flex-1 overflow-auto custom-scrollbar space-y-3">
                        {data.links.map((link, i) => {
                            const targetNode = data.nodes.find(n => n.id === link.target);
                            const isMalicious = targetNode?.type === 'malware';

                            return (
                                <div key={i} className={`p-3 rounded-lg border flex items-center justify-between ${isMalicious ? 'bg-red-900/10 border-red-900/30' : 'bg-gray-800/30 border-gray-800'}`}>
                                    <div className="flex items-center gap-3">
                                        <div className={`p-2 rounded-lg ${isMalicious ? 'bg-red-500/20 text-red-400' : 'bg-blue-500/20 text-blue-400'}`}>
                                            {isMalicious ? <Shield size={16} /> : <Globe size={16} />}
                                        </div>
                                        <div>
                                            <p className="text-sm font-mono text-gray-300">{targetNode?.label}</p>
                                            <p className="text-xs text-gray-500 uppercase">{link.protocol} : {link.port}</p>
                                        </div>
                                    </div>
                                    {isMalicious && <AlertTriangle size={16} className="text-red-500" />}
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>
        </div>
    );
};
