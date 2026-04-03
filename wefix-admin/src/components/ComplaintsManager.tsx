import React, { useEffect, useState } from 'react';
import { collectionGroup, getDocs, query, orderBy, updateDoc, DocumentReference, type DocumentData } from 'firebase/firestore';
import { db } from '../firebase/config';
import { User, Building2, CheckCircle2, Clock, ShieldAlert, FastForward } from 'lucide-react';

interface Complaint {
    id: string;
    userId: string;
    shopId: string;
    shopName: string;
    deviceType: string;
    description: string;
    status: 'open' | 'in_progress' | 'resolved';
    createdAt: any;
    ref?: DocumentReference<DocumentData>;
}

const ComplaintsManager: React.FC = () => {
    const [complaints, setComplaints] = useState<Complaint[]>([]);
    const [, setLoading] = useState(true);

    useEffect(() => {
        fetchComplaints();
    }, []);

    const fetchComplaints = async () => {
        setLoading(true);
        try {
            const q = query(collectionGroup(db, 'complaints'), orderBy('createdAt', 'desc'));
            const snapshot = await getDocs(q);
            const data: Complaint[] = [];
            snapshot.forEach((doc) => {
                data.push({ id: doc.id, ref: doc.ref, ...doc.data() } as Complaint);
            });
            setComplaints(data);
        } catch (error) {
            console.error("Error fetching complaints:", error);
        }
        setLoading(false);
    };

    const updateStatus = async (complaint: Complaint, newStatus: 'in_progress' | 'resolved') => {
        if (!complaint.ref) return;
        const confirmMsg = newStatus === 'resolved' 
            ? "Mark this complaint as resolved?" 
            : "Move this complaint to 'In Progress'?";
            
        if (!window.confirm(confirmMsg)) return;
        
        try {
            await updateDoc(complaint.ref, {
                status: newStatus
            });
            fetchComplaints();
        } catch (error) {
            console.error("Error updating complaint status:", error);
            alert("Failed to update status.");
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'resolved': return 'var(--secondary)';
            case 'in_progress': return 'var(--warning)';
            default: return 'var(--danger)';
        }
    };

    return (
        <div className="animate-fade-in">
            <div style={{ marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>Customer Complaints</h1>
                <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>Centralized management for all customer issues and resolutions.</p>
            </div>

            <div className="data-table-container">
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>Complaint Details</th>
                            <th>Customer & Shop</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {complaints.map((comp) => (
                            <tr key={comp.id}>
                                <td style={{ maxWidth: '400px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                                        <ShieldAlert size={18} color="var(--danger)" />
                                        <span style={{ fontWeight: '600' }}>{comp.deviceType}</span>
                                    </div>
                                    <p style={{ fontSize: '0.9rem', color: 'var(--text-primary)', margin: 0, lineHeight: '1.5' }}>
                                        {comp.description}
                                    </p>
                                    <div style={{ marginTop: '0.5rem', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                                        ID: {comp.id} | Reported: {comp.createdAt ? new Date(comp.createdAt.toMillis()).toLocaleString() : 'N/A'}
                                    </div>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                            <User size={14} color="var(--text-secondary)" />
                                            <span>{comp.userId.substring(0, 8)}...</span>
                                        </div>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                            <Building2 size={14} color="var(--text-secondary)" />
                                            <span>{comp.shopName || 'Unknown Shop'}</span>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <span style={{
                                        background: 'rgba(0,0,0,0.03)',
                                        padding: '0.35rem 0.75rem',
                                        borderRadius: '20px',
                                        fontSize: '0.75rem',
                                        fontWeight: '700',
                                        textTransform: 'uppercase',
                                        display: 'inline-flex',
                                        alignItems: 'center',
                                        gap: '0.4rem',
                                        color: getStatusColor(comp.status)
                                    }}>
                                        {comp.status === 'resolved' ? <CheckCircle2 size={14} /> : comp.status === 'in_progress' ? <Clock size={14} /> : <ShieldAlert size={14} />}
                                        {comp.status.replace('_', ' ')}
                                    </span>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                                        {comp.status === 'open' && (
                                            <button 
                                                className="btn-primary"
                                                style={{ padding: '0.5rem 0.75rem', fontSize: '0.75rem', background: 'var(--warning)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
                                                onClick={() => updateStatus(comp, 'in_progress')}
                                            >
                                                <FastForward size={14} /> Start Review
                                            </button>
                                        )}
                                        {comp.status !== 'resolved' && (
                                            <button 
                                                className="btn-primary"
                                                style={{ padding: '0.5rem 0.75rem', fontSize: '0.75rem', background: 'var(--secondary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
                                                onClick={() => updateStatus(comp, 'resolved')}
                                            >
                                                <CheckCircle2 size={14} /> Resolve
                                            </button>
                                        )}
                                        {comp.status === 'resolved' && (
                                            <span style={{ fontSize: '0.875rem', color: 'var(--secondary)', fontWeight: '600' }}>Closed</span>
                                        )}
                                    </div>
                                </td>
                            </tr>
                        ))}
                        {complaints.length === 0 && (
                            <tr>
                                <td colSpan={4} style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-secondary)' }}>
                                    No complaints recorded.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default ComplaintsManager;
