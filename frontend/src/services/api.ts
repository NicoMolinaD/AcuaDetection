import axios from 'axios';

export const api = axios.create({
    baseURL: '/api/v1',
});

export const setAuthToken = (token: string | null) => {
    if (token) {
        api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
        delete api.defaults.headers.common['Authorization'];
    }
};

export const loginUser = async (username: string, password: string) => {
    const formData = new FormData();
    formData.append('username', username);
    formData.append('password', password);
    const response = await api.post('/auth/login/access-token', formData);
    return response.data;
};

export const logoutUser = async () => {
    const response = await api.post('/auth/logout');
    return response.data;
};

export const sendHeartbeat = async () => {
    const response = await api.post('/session/heartbeat');
    return response.data;
};

export const scanTarget = async (target: string, filename?: string) => {
    try {
        const response = await api.get('/scan/', { params: { target, filename } });
        return response.data;
    } catch (error) {
        console.error('API Scan Error:', error);
        throw error;
    }
};

export const uploadFile = async (file: File) => {
    const buffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    return scanTarget(hashHex, file.name);
}

export const fetchMalcomData = async (target?: string, isMalicious?: boolean) => {
    try {
        const response = await api.get('/malcom/', {
            params: { target, is_malicious: isMalicious }
        });
        return { data: response.data };
    } catch (error) {
        console.error('Error fetching Malcom data:', error);
        throw error;
    }
};

export const getRansomwareList = async () => {
    const response = await api.get('/ransomware/');
    return response.data;
};

export const addRansomware = async (data: any) => {
    const response = await api.post('/ransomware/', data);
    return response.data;
};

export const updateRansomware = async (id: number, data: any) => {
    const response = await api.put(`/ransomware/${id}`, data);
    return response.data;
};

export const deleteRansomware = async (id: number) => {
    const response = await api.delete(`/ransomware/${id}`);
    return response.data;
};

export const getAuditLogs = async () => {
    const response = await api.get('/logs/');
    return response.data;
};

export const getUserLogs = async () => {
    const response = await api.get('/logs/me');
    return response.data;
};

export const getUsers = async () => {
    const response = await api.get('/users/');
    return response.data;
};

export const createUser = async (userData: any) => {
    const response = await api.post('/users/', userData);
    return response.data;
};

export const deleteUser = async (userId: number) => {
    const response = await api.delete(`/users/${userId}`);
    return response.data;
};

export const updateUser = async (userId: number, userData: any) => {
    const response = await api.patch(`/users/${userId}`, userData);
    return response.data;
};
