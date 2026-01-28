import React, { useState, useEffect } from 'react';
import { getRansomwareList, addRansomware, updateRansomware, deleteRansomware } from '../../services/api';
import { Plus, Database, ShieldAlert, X, Search, Edit2, Trash2 } from 'lucide-react';

export const RansomwareManager: React.FC = () => {
    const [ransomwareList, setRansomwareList] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchFilter, setSearchFilter] = useState('');

    const [showForm, setShowForm] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    
    const [newName, setNewName] = useState('');
    const [newDescription, setNewDescription] = useState('');
    const [newMD5, setNewMD5] = useState('');
    const [newSHA1, setNewSHA1] = useState('');
    const [newSHA256, setNewSHA256] = useState('');
    const [newIPs, setNewIPs] = useState<string[]>(['']);
    const [newDomains, setNewDomains] = useState('');
    const [formError, setFormError] = useState('');
    const [formSuccess, setFormSuccess] = useState('');

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await getRansomwareList();
            setRansomwareList(data);
        } catch (e) {
            console.error("Failed to load ransomware list", e);
        } finally {
            setLoading(false);
        }
    };

    const validateForm = (): boolean => {
        setFormError('');
        
        // Validate name
        if (!newName.trim()) {
            setFormError('El nombre/familia es requerido');
            return false;
        }

        // Check if at least one hash, IP or domain exists
        const hasHashes = newMD5.trim() || newSHA1.trim() || newSHA256.trim();
        const hasIPs = newIPs.some(ip => ip.trim());
        const hasDomains = newDomains.trim();

        if (!hasHashes && !hasIPs && !hasDomains) {
            setFormError('Debes proporcionar al menos un hash, IP o dominio');
            return false;
        }

        return true;
    };

    const resetForm = () => {
        setNewName('');
        setNewDescription('');
        setNewMD5('');
        setNewSHA1('');
        setNewSHA256('');
        setNewIPs(['']);
        setNewDomains('');
        setFormError('');
        setFormSuccess('');
        setIsEditing(false);
        setEditingId(null);
        setShowForm(false);
    };

    const handleEdit = (item: any) => {
        setEditingId(item.id);
        setIsEditing(true);
        setNewName(item.name);
        setNewDescription(item.description || '');
        
        // Parse hashes
        if (item.hashes) {
            setNewMD5(item.hashes.md5?.[0] || '');
            setNewSHA1(item.hashes.sha1?.[0] || '');
            setNewSHA256(item.hashes.sha256?.[0] || '');
        }
        
        setNewIPs(item.ips && item.ips.length > 0 ? item.ips : ['']);
        setNewDomains(item.domains?.join(', ') || '');
        setShowForm(true);
    };

    const handleAdd = async (e: React.FormEvent) => {
        e.preventDefault();
        
        if (!validateForm()) return;

        try {
            const hashesObj: { [key: string]: string[] } = {};
            if (newMD5.trim()) hashesObj.md5 = [newMD5.trim()];
            if (newSHA1.trim()) hashesObj.sha1 = [newSHA1.trim()];
            if (newSHA256.trim()) hashesObj.sha256 = [newSHA256.trim()];

            const ips = newIPs.filter(ip => ip.trim());
            const domains = newDomains.split(',').map(d => d.trim()).filter(Boolean);

            if (isEditing && editingId) {
                // Update existing
                await updateRansomware(editingId, {
                    description: newDescription,
                    hashes: hashesObj,
                    ips: ips,
                    domains: domains
                });
                setFormSuccess('Registro actualizado correctamente');
            } else {
                // Create new
                await addRansomware({
                    name: newName,
                    description: newDescription,
                    hashes: hashesObj,
                    ips: ips,
                    domains: domains
                });
                setFormSuccess('Registro creado correctamente');
            }
            
            setTimeout(() => {
                resetForm();
                loadData();
            }, 1500);
        } catch (e: any) {
            if (e.response?.status === 409) {
                setFormError('Ya existe un registro de ransomware con este nombre');
            } else {
                setFormError(`Error: ${isEditing ? 'al actualizar' : 'al crear'} el registro de ransomware`);
            }
        }
    };

    const handleDelete = async (id: number, name: string) => {
        if (window.confirm(`¿Estás seguro de que quieres eliminar a ${name}?`)) {
            try {
                await deleteRansomware(id);
                setFormSuccess('Registro eliminado correctamente');
                setTimeout(() => {
                    setFormSuccess('');
                    loadData();
                }, 1500);
            } catch (e) {
                setFormError('Error al eliminar el registro');
            }
        }
    };

    const addIPField = () => {
        setNewIPs([...newIPs, '']);
    };

    const removeIPField = (index: number) => {
        setNewIPs(newIPs.filter((_, i) => i !== index));
    };

    const updateIPField = (index: number, value: string) => {
        const newList = [...newIPs];
        newList[index] = value;
        setNewIPs(newList);
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div>
                <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-2">
                    <h2 className="text-xl sm:text-2xl font-bold text-gray-100 flex items-center gap-2">
                        <Database className="text-emerald-500" />
                        BBDD de Ransomware
                    </h2>
                    <button
                        onClick={() => {
                            if (!isEditing) resetForm();
                            setShowForm(!showForm);
                        }}
                        className="w-full sm:w-auto bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2.5 rounded-xl flex items-center justify-center gap-2 transition-all shadow-lg shadow-emerald-900/20 font-bold"
                    >
                        <Plus size={18} />
                        Añadir Registro
                    </button>
                </header>
                <p className="text-gray-500 text-sm">Gestiona y almacena información de familias de ransomware, incluyendo hashes, IPs y dominios maliciosos para la detección local.</p>
            </div>

            {showForm && (
                <form onSubmit={handleAdd} className="bg-gray-900 border border-gray-800 p-6 rounded-xl space-y-4 animate-fade-in shadow-xl">
                    {formError && (
                        <div className="bg-red-900/20 border border-red-900/50 p-3 rounded-lg text-red-300 text-sm">
                            {formError}
                        </div>
                    )}
                    
                    {formSuccess && (
                        <div className="bg-emerald-900/20 border border-emerald-900/50 p-3 rounded-lg text-emerald-300 text-sm">
                            {formSuccess}
                        </div>
                    )}
                    
                    {isEditing && (
                        <div className="bg-blue-900/20 border border-blue-900/50 p-3 rounded-lg text-blue-300 text-sm">
                            Editando: <span className="font-bold">{newName}</span>
                        </div>
                    )}
                    
                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-1">Nombre / Familia *</label>
                        <input
                            type="text"
                            value={newName}
                            onChange={(e) => setNewName(e.target.value)}
                            disabled={isEditing}
                            className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500 disabled:opacity-50"
                            placeholder="Ej. WannaCry, LockBit 3.0"
                        />
                    </div>

                    <div className="bg-gray-800/30 border border-gray-700/30 rounded-lg p-4 space-y-3">
                        <h3 className="text-sm font-medium text-gray-300">Hashes:</h3>
                        <div>
                            <label className="block text-xs font-medium text-gray-500 mb-1">MD5</label>
                            <input
                                type="text"
                                value={newMD5}
                                onChange={(e) => setNewMD5(e.target.value)}
                                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500 font-mono text-xs"
                                placeholder="Hash MD5..."
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-gray-500 mb-1">SHA1</label>
                            <input
                                type="text"
                                value={newSHA1}
                                onChange={(e) => setNewSHA1(e.target.value)}
                                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500 font-mono text-xs"
                                placeholder="Hash SHA1..."
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-gray-500 mb-1">SHA256</label>
                            <input
                                type="text"
                                value={newSHA256}
                                onChange={(e) => setNewSHA256(e.target.value)}
                                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500 font-mono text-xs"
                                placeholder="Hash SHA256..."
                            />
                        </div>
                    </div>

                    <div className="bg-gray-800/30 border border-gray-700/30 rounded-lg p-4 space-y-3">
                        <div className="flex items-center justify-between">
                            <h3 className="text-sm font-medium text-gray-300">IP:</h3>
                            <button
                                type="button"
                                onClick={addIPField}
                                className="text-xs text-emerald-400 hover:text-emerald-300 flex items-center gap-1"
                            >
                                <Plus size={14} />
                                Añadir
                            </button>
                        </div>
                        {newIPs.map((ip, index) => (
                            <div key={index} className="flex gap-2">
                                <input
                                    type="text"
                                    value={ip}
                                    onChange={(e) => updateIPField(index, e.target.value)}
                                    className="flex-1 bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500 font-mono text-xs"
                                    placeholder="Ej. 192.168.1.1"
                                />
                                {newIPs.length > 1 && (
                                    <button
                                        type="button"
                                        onClick={() => removeIPField(index)}
                                        className="bg-red-900/30 hover:bg-red-900/50 border border-red-700/30 text-red-400 p-2 rounded-lg transition-all"
                                    >
                                        <X size={16} />
                                    </button>
                                )}
                            </div>
                        ))}
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-1">Dominio:</label>
                        <input
                            type="text"
                            value={newDomains}
                            onChange={(e) => setNewDomains(e.target.value)}
                            className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white focus:ring-1 focus:ring-emerald-500"
                            placeholder="Ej. malicious.com, evil.net (separados por coma)"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-1">Descripción:</label>
                        <textarea
                            value={newDescription}
                            onChange={(e) => setNewDescription(e.target.value)}
                            className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2 text-white h-20 focus:ring-1 focus:ring-emerald-500"
                            placeholder="Información adicional sobre el ransomware..."
                        />
                    </div>

                    <div className="flex justify-end gap-2 pt-4 border-t border-gray-800">
                        <button
                            type="button"
                            onClick={resetForm}
                            className="text-gray-400 hover:text-white px-4 py-2"
                        >
                            Cancelar
                        </button>
                        <button
                            type="submit"
                            className="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-lg"
                        >
                            {isEditing ? 'Actualizar' : 'Guardar'}
                        </button>
                    </div>
                </form>
            )}

            {ransomwareList.length > 0 && (
                <div className="mb-6">
                    <div className="relative">
                        <Search className="absolute left-3 top-3 w-5 h-5 text-gray-500" />
                        <input
                            type="text"
                            placeholder="Buscar ransomware por nombre, IP o dominio..."
                            value={searchFilter}
                            onChange={(e) => setSearchFilter(e.target.value)}
                            className="w-full bg-gray-950 border border-gray-700 rounded-lg p-3 pl-10 text-white focus:ring-1 focus:ring-emerald-500"
                        />
                    </div>
                </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {ransomwareList
                    .filter(item => 
                        searchFilter === '' ||
                        item.name.toLowerCase().includes(searchFilter.toLowerCase()) ||
                        item.description?.toLowerCase().includes(searchFilter.toLowerCase()) ||
                        (item.ips && item.ips.some((ip: string) => ip.includes(searchFilter))) ||
                        (item.domains && item.domains.some((domain: string) => domain.includes(searchFilter)))
                    )
                    .map((item) => (
                    <div key={item.id} className="bg-gray-900 border border-gray-800 p-5 rounded-xl hover:border-gray-700 transition-colors">
                        <div className="flex items-start justify-between mb-3">
                            <h3 className="font-bold text-lg text-emerald-400">{item.name}</h3>
                            <div className="flex gap-1">
                                <button
                                    onClick={() => handleEdit(item)}
                                    className="p-1.5 hover:bg-gray-800 rounded-lg transition-colors text-blue-400 hover:text-blue-300"
                                    title="Editar"
                                >
                                    <Edit2 size={16} />
                                </button>
                                <button
                                    onClick={() => handleDelete(item.id, item.name)}
                                    className="p-1.5 hover:bg-gray-800 rounded-lg transition-colors text-red-400 hover:text-red-300"
                                    title="Eliminar"
                                >
                                    <Trash2 size={16} />
                                </button>
                            </div>
                        </div>
                        
                        {item.description && (
                            <p className="text-gray-500 text-xs mb-3 line-clamp-2">{item.description}</p>
                        )}

                        <div className="space-y-2 text-xs">
                            {item.hashes && Object.keys(item.hashes).length > 0 && (
                                <div>
                                    <p className="text-gray-500 font-medium mb-1">Hashes:</p>
                                    {Object.entries(item.hashes).map(([type, hashes]: [string, any]) => (
                                        <div key={type} className="text-gray-600 ml-2">
                                            <span className="text-gray-700">{type.toUpperCase()}:</span> {Array.isArray(hashes) ? hashes.length : 0}
                                        </div>
                                    ))}
                                </div>
                            )}
                            
                            {item.ips && item.ips.length > 0 && (
                                <div>
                                    <p className="text-gray-500 font-medium mb-1">IPs: {item.ips.length}</p>
                                    <div className="ml-2 space-y-0.5">
                                        {item.ips.slice(0, 2).map((ip: string, idx: number) => (
                                            <p key={idx} className="text-gray-700 font-mono text-[10px]">{ip}</p>
                                        ))}
                                        {item.ips.length > 2 && (
                                            <p className="text-gray-600 text-[10px]">+{item.ips.length - 2} más</p>
                                        )}
                                    </div>
                                </div>
                            )}
                            
                            {item.domains && item.domains.length > 0 && (
                                <div>
                                    <p className="text-gray-500 font-medium mb-1">Dominios: {item.domains.length}</p>
                                    <div className="ml-2 space-y-0.5">
                                        {item.domains.slice(0, 2).map((domain: string, idx: number) => (
                                            <p key={idx} className="text-gray-700 font-mono text-[10px]">{domain}</p>
                                        ))}
                                        {item.domains.length > 2 && (
                                            <p className="text-gray-600 text-[10px]">+{item.domains.length - 2} más</p>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>

                        <p className="text-gray-600 text-xs mt-3 pt-3 border-t border-gray-800">
                            IOCs Registrados: {
                                (Object.values(item.hashes || {}).reduce((acc: number, h: any) => acc + (Array.isArray(h) ? h.length : 0), 0) || 0) +
                                (item.ips?.length || 0) + 
                                (item.domains?.length || 0)
                            }
                        </p>
                    </div>
                ))}
            </div>
            {ransomwareList.length === 0 && !loading && (
                <div className="text-center py-12 text-gray-500">
                    No hay registros. Añade uno para comenzar la detección local.
                </div>
            )}
        </div>
    );
};
