import React, { useEffect, useState } from 'react';
import { getAuditLogs, getUserLogs } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import { User, Clock, Shield, Activity as ActivityIcon, Download, FileText } from 'lucide-react';

interface SystemLogsProps {
    personal?: boolean;
}

export const SystemLogs: React.FC<SystemLogsProps> = ({ personal = false }) => {
    const { user } = useAuth();
    const [logs, setLogs] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        loadLogs();
    }, [personal]);

    const loadLogs = async () => {
        setLoading(true);
        try {
            const data = personal ? await getUserLogs() : await getAuditLogs();
            setLogs(data);
        } catch (e) {
            setError(personal ? 'Error cargando tu historial.' : 'Error cargando logs. Verifica que eres Administrador.');
        } finally {
            setLoading(false);
        }
    };

    const exportToCSV = () => {
        if (logs.length === 0) return;

        const headers = personal 
            ? ['ID', 'Timestamp', 'Proceso', 'Acción', 'Detalles']
            : ['ID', 'Timestamp', 'Usuario ID', 'Proceso', 'Acción', 'Detalles'];

        const rows = logs.map(log => {
            const baseRow = [
                log.id,
                log.timestamp ? new Date(log.timestamp).toLocaleString() : 'N/A',
            ];
            
            if (!personal) {
                baseRow.push(log.user_id || 'System');
            }
            
            baseRow.push(
                log.process_name || 'GENERAL',
                log.action,
                log.details || '-'
            );
            
            return baseRow.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',');
        });

        const csvContent = [
            headers.map(h => `"${h}"`).join(','),
            ...rows
        ].join('\n');

        const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `logs_${personal ? 'personal' : 'sistema'}_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    const exportToPDF = async () => {
        if (logs.length === 0) return;

        try {
            const jsPDF = (await import('jspdf')).default;
            const doc = new jsPDF();
            
            const pageWidth = doc.internal.pageSize.getWidth();
            const margin = 10;
            const maxWidth = pageWidth - 2 * margin;
            let yPos = 20;
            const lineHeight = 7;
            const pageHeight = doc.internal.pageSize.getHeight();

            doc.setFontSize(16);
            doc.text(personal ? 'Mi Historial de Actividad' : 'Registros de Auditoría del Sistema', margin, yPos);
            yPos += 10;

            doc.setFontSize(10);
            doc.text(`Fecha de exportación: ${new Date().toLocaleString()}`, margin, yPos);
            doc.text(`Total de registros: ${logs.length}`, margin, yPos + 5);
            yPos += 15;

            doc.setFontSize(8);
            const headers = personal 
                ? ['ID', 'Timestamp', 'Proceso', 'Acción', 'Detalles']
                : ['ID', 'Timestamp', 'Usuario', 'Proceso', 'Acción', 'Detalles'];

            const colWidths = personal 
                ? [15, 40, 30, 35, maxWidth - 120]
                : [15, 40, 20, 25, 30, maxWidth - 130];

            let xPos = margin;
            doc.setFont('helvetica', 'bold');
            headers.forEach((header, idx) => {
                doc.text(header, xPos, yPos);
                xPos += colWidths[idx];
            });
            yPos += lineHeight + 2;

            doc.setFont('helvetica', 'normal');
            doc.setDrawColor(200, 200, 200);
            doc.line(margin, yPos - 2, pageWidth - margin, yPos - 2);
            yPos += 3;

            logs.forEach((log, index) => {
                if (yPos > pageHeight - 20) {
                    doc.addPage();
                    yPos = 20;
                }

                const rowData = personal
                    ? [
                        String(log.id),
                        log.timestamp ? new Date(log.timestamp).toLocaleString() : 'N/A',
                        log.process_name || 'GENERAL',
                        log.action,
                        log.details || '-'
                    ]
                    : [
                        String(log.id),
                        log.timestamp ? new Date(log.timestamp).toLocaleString() : 'N/A',
                        String(log.user_id || 'System'),
                        log.process_name || 'GENERAL',
                        log.action,
                        log.details || '-'
                    ];

                xPos = margin;
                rowData.forEach((cell, idx) => {
                    const text = String(cell).substring(0, 30);
                    doc.text(text, xPos, yPos);
                    xPos += colWidths[idx];
                });
                yPos += lineHeight;

                if (index < logs.length - 1) {
                    doc.setDrawColor(50, 50, 50);
                    doc.line(margin, yPos - 1, pageWidth - margin, yPos - 1);
                }
            });

            doc.save(`logs_${personal ? 'personal' : 'sistema'}_${new Date().toISOString().split('T')[0]}.pdf`);
        } catch (error) {
            console.error('Error generando PDF:', error);
            alert('Error al generar el PDF. Por favor, intenta exportar a CSV.');
        }
    };

    if (loading) return <div className="text-center p-10 text-gray-500">Cargando registros...</div>;
    if (error) return <div className="p-4 bg-red-900/20 text-red-300 rounded-lg text-center">{error}</div>;

    const isAdmin = user?.is_admin || false;
    const showExportButtons = isAdmin && !personal && logs.length > 0;

    return (
        <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden shadow-xl animate-fade-in">
            <div className="p-4 sm:p-6 border-b border-gray-800 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                <h3 className="text-lg sm:text-xl font-bold text-gray-100 flex items-center gap-2">
                    <Shield className="text-emerald-500" />
                    {personal ? 'Mi Historial de Actividad' : 'Registros de Auditoría del Sistema'}
                </h3>
                <div className="flex items-center gap-3">
                    <span className="text-xs text-gray-500 font-mono bg-gray-950 px-2 py-1 rounded-md border border-gray-800">Total: {logs.length}</span>
                    {showExportButtons && (
                        <div className="flex items-center gap-2">
                            <button
                                onClick={exportToCSV}
                                className="flex items-center gap-2 px-3 py-1.5 bg-emerald-600/20 hover:bg-emerald-600/30 border border-emerald-500/30 hover:border-emerald-500/50 text-emerald-400 rounded-lg transition-all text-sm font-medium"
                                title="Exportar a CSV"
                            >
                                <Download className="w-4 h-4" />
                                CSV
                            </button>
                            <button
                                onClick={exportToPDF}
                                className="flex items-center gap-2 px-3 py-1.5 bg-red-600/20 hover:bg-red-600/30 border border-red-500/30 hover:border-red-500/50 text-red-400 rounded-lg transition-all text-sm font-medium"
                                title="Exportar a PDF"
                            >
                                <FileText className="w-4 h-4" />
                                PDF
                            </button>
                        </div>
                    )}
                </div>
            </div>
            <div className="w-full">
                {/* Desktop View */}
                <div className="hidden md:block overflow-x-auto max-h-96 overflow-y-auto">
                    <table className="w-full text-left border-collapse">
                        <thead className="sticky top-0 bg-gray-800/50 z-10">
                            <tr className="bg-gray-800/50 text-gray-400 text-xs uppercase tracking-wider">
                                <th className="p-4 font-medium">ID</th>
                                <th className="p-4 font-medium">Timestamp</th>
                                {!personal && <th className="p-4 font-medium">Usuario (ID)</th>}
                                <th className="p-4 font-medium">Proceso</th>
                                <th className="p-4 font-medium">Acción</th>
                                <th className="p-4 font-medium">Detalles</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-800 text-sm text-gray-300">
                            {logs.map((log) => (
                                <tr key={log.id} className="hover:bg-gray-800/30 transition-colors">
                                    <td className="p-4 font-mono text-gray-500">#{log.id}</td>
                                    <td className="p-4 font-mono whitespace-nowrap">
                                        <div className="flex items-center gap-2">
                                            <Clock size={14} className="text-blue-500" />
                                            {log.timestamp ? new Date(log.timestamp).toLocaleString() : 'N/A'}
                                        </div>
                                    </td>
                                    {!personal && (
                                        <td className="p-4">
                                            <div className="flex items-center gap-2">
                                                <User size={14} className="text-emerald-500" />
                                                {log.user_id ? `${log.user_id}` : 'System'}
                                            </div>
                                        </td>
                                    )}
                                    <td className="p-4">
                                        <div className="flex items-center gap-2">
                                            <ActivityIcon size={14} className="text-amber-500" />
                                            <span className="font-mono text-xs">{log.process_name || 'GENERAL'}</span>
                                        </div>
                                    </td>
                                    <td className="p-4">
                                        <span className={`px-2 py-1 rounded-full text-[10px] font-bold uppercase ${log.action.includes('LOGIN') ? 'bg-blue-900/30 text-blue-400 border border-blue-900/50' :
                                            log.action.includes('SCAN') ? 'bg-purple-900/30 text-purple-400 border border-purple-900/50' :
                                                log.action.includes('RANSOMWARE') ? 'bg-red-900/30 text-red-400 border border-red-900/50' :
                                                    'bg-gray-800 text-gray-400'
                                            }`}>
                                            {log.action}
                                        </span>
                                    </td>
                                    <td className="p-4 max-w-xs truncate text-gray-500 font-mono" title={log.details}>
                                        {log.details || '-'}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Mobile View */}
                <div className="md:hidden divide-y divide-gray-800 max-h-96 overflow-y-auto">
                    {logs.map((log) => (
                        <div key={log.id} className="p-4 space-y-3">
                            <div className="flex justify-between items-center">
                                <span className="text-[10px] font-mono text-gray-600">#{log.id}</span>
                                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${log.action.includes('LOGIN') ? 'bg-blue-900/30 text-blue-400' :
                                    log.action.includes('SCAN') ? 'bg-purple-900/30 text-purple-400' :
                                        log.action.includes('RANSOMWARE') ? 'bg-red-900/30 text-red-400' :
                                            'bg-gray-800 text-gray-400'
                                    }`}>
                                    {log.action}
                                </span>
                            </div>
                            <div className="flex flex-col gap-1.5 text-xs text-gray-400">
                                <div className="flex items-center gap-2">
                                    <Clock size={12} className="text-blue-500" />
                                    {log.timestamp ? new Date(log.timestamp).toLocaleString() : 'N/A'}
                                </div>
                                {!personal && (
                                    <div className="flex items-center gap-2">
                                        <User size={12} className="text-emerald-500" />
                                        ID Usuario: {log.user_id || 'System'}
                                    </div>
                                )}
                                <div className="flex items-center gap-2">
                                    <ActivityIcon size={12} className="text-amber-500" />
                                    Proceso: {log.process_name || 'GENERAL'}
                                </div>
                            </div>
                            <div className="bg-gray-950 p-2 rounded-lg border border-gray-800 text-[11px] font-mono text-gray-500">
                                {log.details || 'Sin detalles adicionales'}
                            </div>
                        </div>
                    ))}
                </div>

                {logs.length === 0 && (
                    <div className="p-12 text-center text-gray-500">
                        No hay registros disponibles.
                    </div>
                )}
            </div>
        </div>
    );
};
