import React, { useEffect, useState } from 'react';
import type { Shop } from '../pages/Dashboard';
import { collection, collectionGroup, getDocs, query, where } from 'firebase/firestore';
import type { DocumentData, QueryDocumentSnapshot } from 'firebase/firestore';
import { db } from '../firebase/config';
import { X, MapPin, Phone, Mail, FileText, AlertCircle, TrendingUp, Star, Clock, ShieldCheck, ZapOff } from 'lucide-react';

interface ShopDetailsModalProps {
    shop: Shop;
    onClose: () => void;
    onToggleStatus: () => void;
}

const ShopDetailsModal: React.FC<ShopDetailsModalProps> = ({ shop, onClose, onToggleStatus }) => {
    const [stats, setStats] = useState({
        earnings: 0,
        ratingsAverage: 0,
        ratingsCount: 0,
        complaints: 0,
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            setLoading(true);
            let earnings = 0;
            let ratingsSum = 0;
            let ratingsCount = 0;
            let complaintsCount = 0;

            try {
                // Fetch Requests to calculate earnings using completed statuses
                const reqQuery = query(
                    collectionGroup(db, 'requests'),
                    where('shopId', '==', shop.id),
                    where('status', 'in', ['payment_done', 'completed', 'paid'])
                );
                const reqSnap = await getDocs(reqQuery);
                reqSnap.forEach((doc: QueryDocumentSnapshot<DocumentData>) => {
                    const data = doc.data();
                    const amount = data.serviceDetails?.totalCost || Number(data.amount) || 0;
                    earnings += amount;
                });
            } catch (err) {
                console.error("Error fetching earnings:", err);
            }

            try {
                // Fetch Ratings list. The Flutter app saves ratings to `shop_users/{shopId}/ratings/{requestId}`
                const ratingsQuery = collection(db, `shop_users/${shop.id}/ratings`);
                const ratingsSnap = await getDocs(ratingsQuery);
                ratingsSnap.forEach((doc: QueryDocumentSnapshot<DocumentData>) => {
                    const data = doc.data();
                    const r = data.rating;
                    if (typeof r === 'number') {
                        ratingsSum += r;
                        ratingsCount++;
                    }
                });
            } catch (err) {
                console.error("Error fetching ratings:", err);
            }

            try {
                // Fetch Complaints
                const compQuery = query(
                    collectionGroup(db, 'complaints'),
                    where('shopId', '==', shop.id)
                );
                const compSnap = await getDocs(compQuery);
                complaintsCount = compSnap.size;
            } catch (err) {
                console.error("Error fetching complaints:", err);
            }

            setStats({
                earnings,
                ratingsAverage: ratingsCount > 0 ? (ratingsSum / ratingsCount) : 0,
                ratingsCount,
                complaints: complaintsCount
            });
            setLoading(false);
        };

        fetchStats();
    }, [shop.id]);

    return (
        <div style={{
            position: 'fixed',
            top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.6)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'flex-start',
            justifyContent: 'flex-end',
            zIndex: 50,
            animation: 'fadeIn 0.2s ease-out forwards'
        }}>
            <div className="glass" style={{
                backgroundColor: 'var(--surface)',
                width: '100%',
                maxWidth: '550px',
                height: '100vh',
                overflowY: 'auto',
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                boxShadow: '-10px 0 30px rgba(0, 0, 0, 0.1)',
                transform: 'translateX(0)',
                animation: 'slideInRight 0.3s ease-out forwards'
            }}>
                <style>{`
          @keyframes slideInRight {
            from { transform: translateX(100%); }
            to { transform: translateX(0); }
          }
        `}</style>

                {/* Header Image */}
                <div style={{ position: 'relative', height: '200px', width: '100%', backgroundColor: '#e2e8f0' }}>
                    {shop.primaryPhoto ? (
                        <img
                            src={shop.primaryPhoto}
                            alt={shop.companyLegalName}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                    ) : (
                        <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
                            No Cover Photo
                        </div>
                    )}

                    <button
                        onClick={onClose}
                        style={{
                            position: 'absolute',
                            top: '1rem',
                            right: '1rem',
                            background: 'rgba(0,0,0,0.5)',
                            color: 'white',
                            padding: '0.5rem',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            transition: 'background 0.2s'
                        }}
                        onMouseOver={(e) => e.currentTarget.style.background = 'rgba(0,0,0,0.8)'}
                        onMouseOut={(e) => e.currentTarget.style.background = 'rgba(0,0,0,0.5)'}
                    >
                        <X size={20} />
                    </button>
                </div>

                <div style={{ padding: '2rem', flex: 1 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
                        <div>
                            <h2 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)' }}>{shop.companyLegalName}</h2>
                            <span className={`badge ${shop.active ? 'badge-active' : 'badge-inactive'}`} style={{ marginTop: '0.5rem' }}>
                                {shop.active ? 'Verification: Active' : 'Verification: Pending'}
                            </span>
                        </div>

                        <button
                            className={shop.active ? 'btn-danger' : 'btn-primary'}
                            onClick={onToggleStatus}
                            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                        >
                            {shop.active ? <ZapOff size={18} /> : <ShieldCheck size={18} />}
                            {shop.active ? 'Revoke Verification' : 'Verify Shop'}
                        </button>
                    </div>

                    {/* Stats Grid */}
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '2rem' }}>
                        <div style={{ background: '#f8fafc', padding: '1.25rem', borderRadius: 'var(--radius)', border: '1px solid var(--border)' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', marginBottom: '0.5rem' }}>
                                <TrendingUp size={16} />
                                <span style={{ fontSize: '0.875rem', fontWeight: '500' }}>Earnings</span>
                            </div>
                            <div style={{ fontSize: '1.25rem', fontWeight: '700' }}>
                                {loading ? '...' : `₹${stats.earnings.toLocaleString()}`}
                            </div>
                        </div>

                        <div style={{ background: '#fcf6e5', padding: '1.25rem', borderRadius: 'var(--radius)', border: '1px solid #fde68a' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#b45309', marginBottom: '0.5rem' }}>
                                <Star size={16} />
                                <span style={{ fontSize: '0.875rem', fontWeight: '500' }}>Ratings</span>
                            </div>
                            <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#92400e' }}>
                                {loading ? '...' : `${stats.ratingsAverage.toFixed(1)} / 5`}
                                <span style={{ fontSize: '0.75rem', fontWeight: '500', marginLeft: '0.25rem', color: '#d97706' }}>({stats.ratingsCount})</span>
                            </div>
                        </div>

                        <div style={{ background: '#fef2f2', padding: '1.25rem', borderRadius: 'var(--radius)', border: '1px solid #fecaca' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#b91c1c', marginBottom: '0.5rem' }}>
                                <AlertCircle size={16} />
                                <span style={{ fontSize: '0.875rem', fontWeight: '500' }}>Complaints</span>
                            </div>
                            <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#991b1b' }}>
                                {loading ? '...' : stats.complaints}
                            </div>
                        </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                        <h3 style={{ fontSize: '1.125rem', fontWeight: '600', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>Shop Details</h3>

                        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(120px, auto) 1fr', gap: '1rem', alignItems: 'start' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                <MapPin size={16} /> Address
                            </div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '500' }}>
                                {shop.address?.line1}<br />
                                {shop.address?.line2 && <>{shop.address.line2}<br /></>}
                                {shop.address?.city}, {shop.address?.state}
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                <Phone size={16} /> Phone
                            </div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '500' }}>{shop.phone}</div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                <Mail size={16} /> Email
                            </div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '500' }}>{shop.email || 'N/A'}</div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                <FileText size={16} /> Category
                            </div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '500' }}>{shop.shopCategory}</div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                <Clock size={16} /> Registered On
                            </div>
                            <div style={{ fontSize: '0.95rem', fontWeight: '500' }}>
                                {shop.createdAt ? new Date(shop.createdAt.toMillis()).toLocaleString() : 'N/A'}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ShopDetailsModal;
