import React, { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase/config';
import { User, Mail, Phone, Calendar, Search, UserCheck } from 'lucide-react';

interface PlatformUser {
    id: string;
    name?: string;
    email?: string;
    phone?: string;
    createdAt?: any;
    updatedAt?: any;
}

const UsersManager: React.FC = () => {
    const [users, setUsers] = useState<PlatformUser[]>([]);
    const [filteredUsers, setFilteredUsers] = useState<PlatformUser[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchUsers();
    }, []);

    useEffect(() => {
        const term = searchTerm.toLowerCase();
        const filtered = users.filter(user => 
            (user.name?.toLowerCase().includes(term)) ||
            (user.email?.toLowerCase().includes(term)) ||
            (user.phone?.includes(term))
        );
        setFilteredUsers(filtered);
    }, [searchTerm, users]);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'));
            const snapshot = await getDocs(q);
            const data: PlatformUser[] = [];
            snapshot.forEach((doc) => {
                data.push({ id: doc.id, ...doc.data() } as PlatformUser);
            });
            setUsers(data);
            setFilteredUsers(data);
        } catch (error) {
            console.error("Error fetching users:", error);
        }
        setLoading(false);
    };

    return (
        <div className="animate-fade-in">
            <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
                <div>
                    <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>User Management</h1>
                    <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>Overview of all registered customers on the platform.</p>
                </div>
                
                <div style={{ position: 'relative', width: '300px' }}>
                    <Search style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={18} />
                    <input 
                        type="text"
                        placeholder="Search name, email, phone..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{
                            width: '100%',
                            padding: '0.75rem 1rem 0.75rem 2.75rem',
                            borderRadius: '12px',
                            border: '1px solid var(--border)',
                            outline: 'none',
                            fontSize: '0.9rem',
                            backgroundColor: 'white',
                            boxShadow: 'var(--shadow-sm)'
                        }}
                    />
                </div>
            </div>

            <div className="data-table-container">
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>User Profile</th>
                            <th>Contact Info</th>
                            <th>Joined Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map((user) => (
                            <tr key={user.id}>
                                <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{
                                            width: '44px',
                                            height: '44px',
                                            borderRadius: '50%',
                                            backgroundColor: 'rgba(37, 99, 235, 0.1)',
                                            color: 'var(--primary)',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            fontWeight: '700',
                                            fontSize: '1.1rem'
                                        }}>
                                            {user.name ? user.name.charAt(0).toUpperCase() : <User size={20} />}
                                        </div>
                                        <div>
                                            <div style={{ fontWeight: '600', color: 'var(--text-primary)' }}>{user.name || 'Anonymous User'}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>UID: {user.id.substring(0, 8)}...</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                            <Mail size={14} color="var(--text-secondary)" />
                                            <span>{user.email || 'No Email'}</span>
                                        </div>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                            <Phone size={14} color="var(--text-secondary)" />
                                            <span>{user.phone || 'No Phone'}</span>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                        <Calendar size={14} color="var(--text-secondary)" />
                                        <span>{user.createdAt ? new Date(user.createdAt.toMillis()).toLocaleDateString() : 'Unknown'}</span>
                                    </div>
                                </td>
                                <td>
                                    <span style={{
                                        background: 'rgba(34, 197, 94, 0.1)',
                                        color: 'rgb(34, 197, 94)',
                                        padding: '0.25rem 0.75rem',
                                        borderRadius: '20px',
                                        fontSize: '0.75rem',
                                        fontWeight: '700',
                                        display: 'inline-flex',
                                        alignItems: 'center',
                                        gap: '0.35rem'
                                    }}>
                                        <UserCheck size={14} /> Active
                                    </span>
                                </td>
                            </tr>
                        ))}
                        {filteredUsers.length === 0 && (
                            <tr>
                                <td colSpan={4} style={{ textAlign: 'center', padding: '4rem' }}>
                                    {loading ? 'Loading users...' : 'No users found matching your search.'}
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default UsersManager;
