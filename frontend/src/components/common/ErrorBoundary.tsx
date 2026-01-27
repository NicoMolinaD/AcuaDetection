import { Component, ErrorInfo, ReactNode } from 'react';
import { ShieldAlert } from 'lucide-react';

interface Props {
    children: ReactNode;
}

interface State {
    hasError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
    public state: State = {
        hasError: false
    };

    public static getDerivedStateFromError(_: Error): State {
        // Actualiza el estado para que el siguiente renderizado muestre la interfaz de repuesto.
        return { hasError: true };
    }

    public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        // También puedes registrar el error en un servicio de reporte de errores
        console.error("Uncaught error:", error, errorInfo);
    }

    public render() {
        if (this.state.hasError) {
            return (
                <div className="min-h-[400px] flex flex-col items-center justify-center p-8 bg-red-900/10 border border-red-900/20 rounded-2xl animate-fade-in">
                    <ShieldAlert className="w-16 h-16 text-red-500 mb-4" />
                    <h2 className="text-2xl font-bold text-red-400 mb-2">Algo salió mal</h2>
                    <p className="text-gray-400 text-center max-w-md mb-6">
                        Se produjo un error inesperado en este componente. Hemos registrado el incidente.
                    </p>
                    <button
                        onClick={() => window.location.reload()}
                        className="px-6 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-lg transition-colors"
                    >
                        Recargar Página
                    </button>
                </div>
            );
        }

        return this.props.children;
    }
}
