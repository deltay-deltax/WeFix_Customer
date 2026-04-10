import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, addDoc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { db } from '../firebase/config';
import { Trash2, Plus, Ticket, Power, PowerOff } from 'lucide-react';

export interface Coupon {
    id: string;
    code: string;
    discountAmount: number;
    type: 'fixed' | 'percentage';
    isActive: boolean;
    createdAt: any;
}

const OffersManager = () => {
    const [coupons, setCoupons] = useState<Coupon[]>([]);
    const [showAddForm, setShowAddForm] = useState(false);
    const [newCoupon, setNewCoupon] = useState({
        code: '',
        discountAmount: 0,
        type: 'fixed' as 'fixed' | 'percentage',
    });

    useEffect(() => {
        const q = query(collection(db, 'coupons'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const couponsData: Coupon[] = [];
            snapshot.forEach((doc) => {
                couponsData.push({ id: doc.id, ...doc.data() } as Coupon);
            });
            couponsData.sort((a, b) => {
                if (!a.createdAt || !b.createdAt) return 0;
                return b.createdAt.toMillis() - a.createdAt.toMillis();
            });
            setCoupons(couponsData);
        });
        return () => unsubscribe();
    }, []);

    const handleAddCoupon = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newCoupon.code || newCoupon.discountAmount <= 0) return;

        try {
            await addDoc(collection(db, 'coupons'), {
                code: newCoupon.code.toUpperCase(),
                discountAmount: Number(newCoupon.discountAmount),
                type: newCoupon.type,
                isActive: true,
                createdAt: serverTimestamp(),
            });
            setNewCoupon({ code: '', discountAmount: 0, type: 'fixed' });
            setShowAddForm(false);
        } catch (error) {
            console.error("Error adding coupon:", error);
            alert("Failed to add coupon.");
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm("Are you sure you want to delete this coupon?")) return;
        try {
            await deleteDoc(doc(db, 'coupons', id));
        } catch (error) {
            console.error("Error deleting coupon:", error);
            alert("Failed to delete coupon.");
        }
    };

    const toggleStatus = async (coupon: Coupon) => {
        try {
            await updateDoc(doc(db, 'coupons', coupon.id), {
                isActive: !coupon.isActive
            });
        } catch (error) {
            console.error("Error toggling status:", error);
        }
    };

    return (
        <div className="animate-fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                    <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>Offers & Discounts</h1>
                    <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>Create and manage promo codes for customers.</p>
                </div>
                <button
                    onClick={() => setShowAddForm(!showAddForm)}
                    style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.75rem 1.5rem',
                        background: 'var(--primary)',
                        color: 'white',
                        borderRadius: '0.5rem',
                        fontWeight: '600',
                        border: 'none',
                        cursor: 'pointer',
                        boxShadow: 'var(--shadow-sm)'
                    }}
                >
                    <Plus size={20} />
                    {showAddForm ? 'Cancel' : 'New Coupon'}
                </button>
            </div>

            {showAddForm && (
                <div style={{
                    background: 'var(--surface)',
                    padding: '1.5rem',
                    borderRadius: '1rem',
                    border: '1px solid var(--border)',
                    marginBottom: '2rem',
                    boxShadow: 'var(--shadow)'
                }}>
                    <form onSubmit={handleAddCoupon} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', alignItems: 'end' }}>
                        <div>
                            <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', marginBottom: '0.5rem' }}>Coupon Code</label>
                            <input
                                type="text"
                                value={newCoupon.code}
                                onChange={(e) => setNewCoupon({ ...newCoupon, code: e.target.value })}
                                placeholder="E.g. WELCOME50"
                                style={{ width: '100%', padding: '0.625rem', borderRadius: '0.5rem', border: '1px solid var(--border)' }}
                                required
                            />
                        </div>
                        <div>
                            <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', marginBottom: '0.5rem' }}>Discount Amount</label>
                            <input
                                type="number"
                                value={newCoupon.discountAmount}
                                onChange={(e) => setNewCoupon({ ...newCoupon, discountAmount: Number(e.target.value) })}
                                placeholder="Value"
                                style={{ width: '100%', padding: '0.625rem', borderRadius: '0.5rem', border: '1px solid var(--border)' }}
                                required
                            />
                        </div>
                        <div>
                            <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', marginBottom: '0.5rem' }}>Type</label>
                            <select
                                value={newCoupon.type}
                                onChange={(e) => setNewCoupon({ ...newCoupon, type: e.target.value as any })}
                                style={{ width: '100%', padding: '0.625rem', borderRadius: '0.5rem', border: '1px solid var(--border)' }}
                            >
                                <option value="fixed">Fixed Amount (₹)</option>
                                <option value="percentage">Percentage (%)</option>
                            </select>
                        </div>
                        <button
                            type="submit"
                            style={{
                                padding: '0.625rem',
                                background: 'var(--secondary)',
                                color: 'white',
                                borderRadius: '0.5rem',
                                fontWeight: '600',
                                border: 'none',
                                cursor: 'pointer'
                            }}
                        >
                            Create Coupon
                        </button>
                    </form>
                </div>
            )}

            <div className="data-table-container">
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>Coupon Code</th>
                            <th>Discount</th>
                            <th>Type</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {coupons.map(coupon => (
                            <tr key={coupon.id}>
                                <td>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                                        <div style={{ padding: '0.5rem', background: '#f1f5f9', borderRadius: '0.5rem', color: 'var(--primary)' }}>
                                            <Ticket size={18} />
                                        </div>
                                        <span style={{ fontWeight: '700', letterSpacing: '0.05em' }}>{coupon.code}</span>
                                    </div>
                                </td>
                                <td style={{ fontWeight: '600' }}>
                                    {coupon.type === 'fixed' ? `₹${coupon.discountAmount}` : `${coupon.discountAmount}%`}
                                </td>
                                <td>
                                    <span style={{ 
                                        padding: '0.25rem 0.625rem', 
                                        borderRadius: '999px', 
                                        fontSize: '0.75rem', 
                                        fontWeight: '600',
                                        background: '#f1f5f9',
                                        color: 'var(--text-secondary)'
                                    }}>
                                        {coupon.type === 'fixed' ? 'Fixed' : 'Percentage'}
                                    </span>
                                </td>
                                <td>
                                    <span className={`badge ${coupon.isActive ? 'badge-active' : 'badge-inactive'}`}>
                                        {coupon.isActive ? 'Active' : 'Expired'}
                                    </span>
                                </td>
                                <td>
                                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                                        <button
                                            onClick={() => toggleStatus(coupon)}
                                            style={{
                                                padding: '0.5rem',
                                                borderRadius: '0.5rem',
                                                border: '1px solid var(--border)',
                                                background: 'white',
                                                color: coupon.isActive ? 'var(--warning)' : 'var(--secondary)',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center'
                                            }}
                                            title={coupon.isActive ? "Deactivate" : "Activate"}
                                        >
                                            {coupon.isActive ? <PowerOff size={16} /> : <Power size={16} />}
                                        </button>
                                        <button
                                            onClick={() => handleDelete(coupon.id)}
                                            style={{
                                                padding: '0.5rem',
                                                borderRadius: '0.5rem',
                                                border: '1px solid var(--border)',
                                                background: 'white',
                                                color: 'var(--danger)',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center'
                                            }}
                                            title="Delete"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                        {coupons.length === 0 && (
                            <tr>
                                <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-secondary)' }}>
                                    No coupons found. Create your first one above!
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default OffersManager;
