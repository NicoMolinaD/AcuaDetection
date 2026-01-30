import React from 'react';
import clsx from 'clsx';
import { ShieldAlert, ShieldCheck, ShieldQuestion } from 'lucide-react';

interface ScanResult {
    source: string;
    engine: string;
    result: string;
    category: string;
}

interface Props {
    scans: ScanResult[];
}

export const SecurityEngineTable: React.FC<Props> = ({ scans }) => {
    if (!scans || scans.length === 0) return null;

    return (
        <div className="w-full">
            {/* Desktop Table View */}
            <div className="hidden md:block overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-700">
                    <thead className="sticky top-0 bg-gray-800/80 z-10">
                        <tr>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Fuente</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Motor</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Resultado</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Estado</th>
                        </tr>
                    </thead>
                    <tbody className="bg-gray-900 divide-y divide-gray-800">
                        {scans.map((scan, idx) => (
                            <tr key={idx} className="hover:bg-gray-800 transition-colors">
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">{scan.source}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">{scan.engine}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">{scan.result}</td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    <span className={clsx(
                                        "px-2 inline-flex text-xs leading-5 font-semibold rounded-full items-center gap-1",
                                        scan.category === 'malicious' && "bg-red-900/50 text-red-200",
                                        scan.category === 'suspicious' && "bg-yellow-900/50 text-yellow-200",
                                        scan.category === 'harmless' && "bg-green-900/50 text-green-200"
                                    )}>
                                        {scan.category === 'malicious' && <ShieldAlert size={14} />}
                                        {scan.category === 'suspicious' && <ShieldQuestion size={14} />}
                                        {scan.category === 'harmless' && <ShieldCheck size={14} />}
                                        {scan.category === 'malicious' ? 'Malicioso' : scan.category === 'suspicious' ? 'Sospechoso' : 'Seguro'}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Mobile Card View */}
            <div className="md:hidden space-y-4">
                {scans.map((scan, idx) => (
                    <div key={idx} className="bg-gray-850 border border-gray-800 rounded-xl p-4 space-y-3">
                        <div className="flex justify-between items-start">
                            <div>
                                <h4 className="text-white font-bold">{scan.engine}</h4>
                                <p className="text-xs text-gray-500 font-mono">{scan.source}</p>
                            </div>
                            <span className={clsx(
                                "px-2 py-0.5 text-[10px] font-bold rounded-full items-center gap-1 uppercase",
                                scan.category === 'malicious' && "bg-red-900/50 text-red-400 border border-red-900/50",
                                scan.category === 'suspicious' && "bg-yellow-900/50 text-yellow-400 border border-yellow-900/50",
                                scan.category === 'harmless' && "bg-green-900/50 text-emerald-400 border border-emerald-900/50"
                            )}>
                                {scan.category === 'malicious' ? 'Malicioso' : scan.category === 'suspicious' ? 'Sospechoso' : 'Seguro'}
                            </span>
                        </div>
                        <div className="bg-gray-900/50 rounded-lg p-2 text-xs font-mono text-gray-400 border border-gray-800">
                            {scan.result}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};
