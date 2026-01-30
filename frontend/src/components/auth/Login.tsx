import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { loginUser } from '../../services/api';
import { Lock, User, AlertCircle } from 'lucide-react';

// Validation patterns matching backend
const USERNAME_PATTERN = /^[a-zA-Z0-9_-]{3,50}$/;
const PASSWORD_MIN_LENGTH = 8;
const PASSWORD_MAX_LENGTH = 128;

interface ValidationError {
    username?: string;
    password?: string;
}

export const Login: React.FC = () => {
    const { login } = useAuth();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [validationErrors, setValidationErrors] = useState<ValidationError>({});

    const validateInputs = (): boolean => {
        const errors: ValidationError = {};

        // Validate username
        if (!username.trim()) {
            errors.username = 'El usuario es requerido';
        } else if (!USERNAME_PATTERN.test(username)) {
            errors.username = 'El usuario debe contener solo letras, números, guiones y guiones bajos (3-50 caracteres)';
        }

        // Validate password
        if (!password) {
            errors.password = 'La contraseña es requerida';
        } else if (password.length < PASSWORD_MIN_LENGTH || password.length > PASSWORD_MAX_LENGTH) {
            errors.password = `La contraseña debe tener entre ${PASSWORD_MIN_LENGTH} y ${PASSWORD_MAX_LENGTH} caracteres`;
        }

        setValidationErrors(errors);
        return Object.keys(errors).length === 0;
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setValidationErrors({});

        // Validate inputs before sending
        if (!validateInputs()) {
            setLoading(false);
            return;
        }

        try {
            const data = await loginUser(username, password);
            login(data.access_token, data.username, data.is_admin);

        } catch (err) {
            setError('Usuario o contraseña incorrectos');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-950 flex items-center justify-center p-4">
            <div className="max-w-md w-full bg-gray-900 border border-gray-800 rounded-2xl shadow-2xl p-8">
                <div className="text-center mb-8">
                    <img src="/logo_custom.png" alt="Logo" className="w-20 h-20 mx-auto mb-4 object-contain" />
                    <h2 className="text-3xl font-bold text-white tracking-tight">Bienvenido</h2>
                    <p className="text-gray-400 mt-2">Accede al Panel de Inteligencia</p>
                </div>

                {error && (
                    <div className="bg-red-900/30 border border-red-900/50 text-red-200 p-3 rounded-lg mb-6 text-sm text-center flex items-center gap-2 justify-center">
                        <AlertCircle size={16} />
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-300 ml-1">Usuario</label>
                        <div className="relative">
                            <User className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 h-5 w-5" />
                            <input
                                type="text"
                                value={username}
                                onChange={(e) => {
                                    setUsername(e.target.value);
                                    if (validationErrors.username) {
                                        setValidationErrors({ ...validationErrors, username: undefined });
                                    }
                                }}
                                className={`w-full bg-gray-950 border rounded-xl py-3 pl-10 pr-4 text-white focus:outline-none focus:ring-2 transition-all ${
                                    validationErrors.username 
                                        ? 'border-red-500/50 focus:ring-red-500/50 focus:border-red-500' 
                                        : 'border-gray-700 focus:ring-emerald-500/50 focus:border-emerald-500'
                                }`}
                                placeholder="Ingresa tu usuario"
                                required
                            />
                        </div>
                        {validationErrors.username && (
                            <p className="text-xs text-red-400 mt-1">{validationErrors.username}</p>
                        )}
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-300 ml-1">Contraseña</label>
                        <div className="relative">
                            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 h-5 w-5" />
                            <input
                                type="password"
                                value={password}
                                onChange={(e) => {
                                    setPassword(e.target.value);
                                    if (validationErrors.password) {
                                        setValidationErrors({ ...validationErrors, password: undefined });
                                    }
                                }}
                                className={`w-full bg-gray-950 border rounded-xl py-3 pl-10 pr-4 text-white focus:outline-none focus:ring-2 transition-all ${
                                    validationErrors.password 
                                        ? 'border-red-500/50 focus:ring-red-500/50 focus:border-red-500' 
                                        : 'border-gray-700 focus:ring-emerald-500/50 focus:border-emerald-500'
                                }`}
                                placeholder="••••••••"
                                required
                            />
                        </div>
                        {validationErrors.password && (
                            <p className="text-xs text-red-400 mt-1">{validationErrors.password}</p>
                        )}
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold py-3 rounded-xl transition-all shadow-lg shadow-emerald-900/20 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {loading ? 'Ingresando...' : 'Iniciar Sesión'}
                    </button>
                </form>
            </div>
        </div>
    );
};
