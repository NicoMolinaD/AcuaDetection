import React, { useEffect, useState } from 'react';
import { getUsers, createUser, deleteUser, updateUser } from '../../services/api';
import { Users, UserPlus, Trash2, Shield, ShieldAlert, X, RefreshCw } from 'lucide-react';

interface User {
    id: number;
    username: string;
    is_active: boolean;
    is_admin: boolean;
    last_login: string | null;
    is_online?: boolean;
}

export const UserManagement: React.FC = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [showAddModal, setShowAddModal] = useState(false);

    const [newUsername, setNewUsername] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [newIsAdmin, setNewIsAdmin] = useState(false);

    const calculateTimeAgo = (lastLogin: string | null): string => {
        if (!lastLogin) {
            return 'Nunca se ha conectado';
        }

        const lastLoginDate = new Date(lastLogin);
        const now = new Date();
        const diffMs = now.getTime() - lastLoginDate.getTime();
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        // Consider user "connected" if last activity within 5 minutes
        if (diffMins < 5) {
            return 'Conectado';
        } else if (diffMins < 60) {
            return `Último ingreso hace ${diffMins} ${diffMins === 1 ? 'minuto' : 'minutos'}`;
        } else if (diffHours < 24) {
            return `Último ingreso hace ${diffHours} ${diffHours === 1 ? 'hora' : 'horas'}`;
        } else {
            return `Último ingreso hace ${diffDays} ${diffDays === 1 ? 'día' : 'días'}`;
        }
    };

    const loadUsers = async () => {
        setLoading(true);
        try {
            const data = await getUsers();
            setUsers(data);
            setError(null);
        } catch (err: any) {
            setError(err.message || 'Error cargando usuarios');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadUsers();
        // Refresh user list every 5 seconds to show real-time status changes
        const interval = setInterval(loadUsers, 5000);
        return () => clearInterval(interval);
    }, []);

    const handleCreateUser = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await createUser({ username: newUsername, password: newPassword, is_admin: newIsAdmin });
            setShowAddModal(false);
            setNewUsername('');
            setNewPassword('');
            setNewIsAdmin(false);
            loadUsers();
        } catch (err: any) {
            alert(err.response?.data?.detail || 'Error al crear usuario');
        }
    };

    const handleDeleteUser = async (id: number) => {
        if (!confirm('¿Estás seguro de que deseas eliminar este usuario?')) return;
        try {
            await deleteUser(id);
            loadUsers();
        } catch (err: any) {
            alert(err.response?.data?.detail || 'Error al eliminar usuario');
        }
    };

    const toggleAdmin = async (user: User) => {
        try {
            await updateUser(user.id, { is_admin: !user.is_admin });
            loadUsers();
        } catch (err: any) {
            alert(err.response?.data?.detail || 'Error al actualizar rol');
        }
    };

    return (
        <div className="space-y-6 animate-fade-in">
            <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
                <div>
                    <h2 className="text-2xl sm:text-3xl font-bold text-gray-100 flex items-center gap-3">
                        <Users className="text-blue-500" />
                        Gestión de Usuarios
                    </h2>
                    <p className="text-sm sm:text-base text-gray-400 mt-1">Administración de accesos y roles del sistema</p>
                </div>
                <button
                    onClick={() => setShowAddModal(true)}
                    className="w-full sm:w-auto flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-xl transition-all shadow-lg shadow-blue-900/20 font-bold"
                >
                    <UserPlus size={20} />
                    Nuevo Usuario
                </button>
            </header>

            {error && (
                <div className="bg-red-900/20 border border-red-900/50 text-red-400 p-4 rounded-xl flex items-center gap-3">
                    <ShieldAlert size={20} />
                    {error}
                </div>
            )}

            <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden shadow-2xl">
                {/* Desktop view */}
                <div className="hidden md:block">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-gray-950/50 text-gray-400 text-xs uppercase tracking-wider">
                                <th className="px-6 py-4 font-semibold">Username</th>
                                <th className="px-6 py-4 font-semibold">Rol</th>
                                <th className="px-6 py-4 font-semibold">Estado</th>
                                <th className="px-6 py-4 font-semibold text-right">Acciones</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-800">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                                        <RefreshCw className="animate-spin mx-auto mb-2" />
                                        Cargando usuarios...
                                    </td>
                                </tr>
                            ) : users.length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-6 py-12 text-center text-gray-500">No hay usuarios registrados.</td>
                                </tr>
                            ) : users.map(user => (
                                <tr key={user.id} className="hover:bg-gray-800/30 transition-colors">
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center text-blue-400 font-bold border border-gray-700">
                                                {user.username.charAt(0).toUpperCase()}
                                            </div>
                                            <span className="text-gray-200 font-medium">{user.username}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        {user.username === 'admin' ? (
                                            /* Admin root user - blue badge, not clickable */
                                            <span className="flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-blue-900/30 text-blue-400 border border-blue-900/50">
                                                <Shield size={12} />
                                                Administrador
                                            </span>
                                        ) : user.is_admin ? (
                                            /* Elevated user - green badge, clickable */
                                            <button
                                                onClick={() => toggleAdmin(user)}
                                                className="flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-900/30 text-emerald-400 border border-emerald-900/50 hover:bg-emerald-900/50 transition-colors"
                                            >
                                                <Shield size={12} />
                                                Privilegiado
                                            </button>
                                        ) : (
                                            /* Regular user - gray badge, clickable */
                                            <button
                                                onClick={() => toggleAdmin(user)}
                                                className="flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-gray-800 text-gray-400 border border-gray-700 hover:bg-gray-700 transition-colors"
                                            >
                                                <Shield size={12} />
                                                Analista
                                            </button>
                                        )}
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`flex items-center gap-1.5 text-xs ${user.is_online ? 'text-emerald-400' : 'text-gray-500'}`}>
                                            <div className={`w-1.5 h-1.5 rounded-full ${user.is_online ? 'bg-emerald-400' : 'bg-gray-500'}`} />
                                            {user.is_online ? 'Conectado' : calculateTimeAgo(user.last_login)}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        {user.username !== 'admin' && (
                                            <button
                                                onClick={() => handleDeleteUser(user.id)}
                                                className="p-2 text-gray-500 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all"
                                                title="Eliminar Usuario"
                                            >
                                                <Trash2 size={18} />
                                            </button>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Mobile view */}
                <div className="md:hidden divide-y divide-gray-800">
                    {loading ? (
                        <div className="p-8 text-center text-gray-500">
                            <RefreshCw className="animate-spin mx-auto mb-2" />
                            Cargando...
                        </div>
                    ) : users.length === 0 ? (
                        <div className="p-8 text-center text-gray-500">No hay usuarios registrados.</div>
                    ) : users.map(user => (
                        <div key={user.id} className="p-4 space-y-4">
                            <div className="flex justify-between items-start">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-full bg-gray-800 flex items-center justify-center text-blue-400 font-bold border border-gray-700">
                                        {user.username.charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                        <h4 className="text-gray-200 font-bold">{user.username}</h4>
                                        <span className={`flex items-center gap-1.5 text-[10px] mt-0.5 ${user.is_online ? 'text-emerald-400' : 'text-gray-500'}`}>
                                            <div className={`w-1 h-1 rounded-full ${user.is_online ? 'bg-emerald-400' : 'bg-gray-500'}`} />
                                            {(user.is_online ? 'Conectado' : calculateTimeAgo(user.last_login)).toUpperCase()}
                                        </span>
                                    </div>
                                </div>
                                {user.username !== 'admin' && (
                                    <button
                                        onClick={() => handleDeleteUser(user.id)}
                                        className="p-2 text-gray-500 hover:text-red-400"
                                    >
                                        <Trash2 size={18} />
                                    </button>
                                )}
                            </div>
                            <div className="flex items-center justify-between">
                                {user.username === 'admin' ? (
                                    /* Admin root user - blue badge, not clickable */
                                    <span className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold bg-blue-900/30 text-blue-400 border border-blue-900/50">
                                        <Shield size={14} />
                                        Administrador
                                    </span>
                                ) : user.is_admin ? (
                                    /* Elevated user - green badge, clickable */
                                    <button
                                        onClick={() => toggleAdmin(user)}
                                        className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-900/30 text-emerald-400 border border-emerald-900/50 hover:bg-emerald-900/50 transition-colors"
                                    >
                                        <Shield size={14} />
                                        Privilegiado
                                    </button>
                                ) : (
                                    /* Regular user - gray badge, clickable */
                                    <button
                                        onClick={() => toggleAdmin(user)}
                                        className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold bg-gray-800 text-gray-400 border border-gray-700 hover:bg-gray-700 transition-colors"
                                    >
                                        <Shield size={14} />
                                        Analista
                                    </button>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {showAddModal && (
                <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-gray-900 border border-gray-700 rounded-2xl shadow-2xl w-full max-w-md p-6 animate-scale-in">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-xl font-bold text-gray-100 flex items-center gap-2">
                                <UserPlus className="text-blue-500" />
                                Crear Nuevo Usuario
                            </h3>
                            <button onClick={() => setShowAddModal(false)} className="text-gray-500 hover:text-gray-300">
                                <X size={24} />
                            </button>
                        </div>
                        <form onSubmit={handleCreateUser} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-400 mb-1">Nombre de Usuario</label>
                                <input
                                    type="text"
                                    value={newUsername}
                                    onChange={(e) => setNewUsername(e.target.value)}
                                    className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-2.5 text-gray-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all outline-none"
                                    placeholder="ej: analista_01"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-400 mb-1">Contraseña</label>
                                <input
                                    type="password"
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                    className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-2.5 text-gray-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all outline-none"
                                    placeholder="••••••••"
                                    required
                                />
                            </div>
                            <div className="flex items-center gap-3 p-3 bg-gray-850 rounded-xl border border-gray-800">
                                <input
                                    type="checkbox"
                                    id="isAdmin"
                                    checked={newIsAdmin}
                                    onChange={(e) => setNewIsAdmin(e.target.checked)}
                                    className="w-4 h-4 rounded border-gray-700 bg-gray-800 text-emerald-600 focus:ring-emerald-500"
                                />
                                <label htmlFor="isAdmin" className="text-sm text-gray-300 font-medium cursor-pointer flex-1">
                                    ¿Asignar permisos privilegiados?
                                </label>
                                <Shield className={newIsAdmin ? 'text-emerald-400' : 'text-gray-600'} size={18} />
                            </div>
                            <div className="pt-4 flex gap-3">
                                <button
                                    type="button"
                                    onClick={() => setShowAddModal(false)}
                                    className="flex-1 px-4 py-2.5 rounded-xl border border-gray-700 text-gray-400 hover:bg-gray-800 transition-all font-medium"
                                >
                                    Cancelar
                                </button>
                                <button
                                    type="submit"
                                    className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-xl transition-all font-bold shadow-lg shadow-blue-900/20"
                                >
                                    Crear Usuario
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};
