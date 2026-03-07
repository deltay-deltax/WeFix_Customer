import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, QuerySnapshot, QueryDocumentSnapshot, FirestoreError } from 'firebase/firestore';
import { db } from '../firebase/config';
import ShopDetailsModal from '../components/ShopDetailsModal';
import BannersManager from '../components/BannersManager';
import { LogOut, Users, Search, Activity, Image as ImageIcon } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export interface Shop {
    id: string;
    active: boolean;
    companyLegalName: string;
    phone: string;
    email: string;
    shopCategory: string;
    primaryPhoto: string;
    createdAt: any;
    address: {
        city: string;
        state: string;
        line1: string;
        line2: string;
    };
}

const Dashboard = () => {
    const [shops, setShops] = useState<Shop[]>([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedShop, setSelectedShop] = useState<Shop | null>(null);
    const [activeTab, setActiveTab] = useState<'shops' | 'banners'>('shops');
    const navigate = useNavigate();

    useEffect(() => {
        // Listen to registered_shop_users collection
        const q = query(collection(db, 'registered_shop_users'));
        const unsubscribe = onSnapshot(q, (snapshot: QuerySnapshot) => {
            const shopsData: Shop[] = [];
            snapshot.forEach((doc: QueryDocumentSnapshot) => {
                shopsData.push({ id: doc.id, ...doc.data() } as Shop);
            });
            // Sort by createdAt desc
            shopsData.sort((a, b) => {
                if (!a.createdAt || !b.createdAt) return 0;
                return b.createdAt.toMillis() - a.createdAt.toMillis();
            });
            setShops(shopsData);
        }, (error: FirestoreError) => {
            console.error("Error fetching shops:", error);
        });

        return () => unsubscribe();
    }, []);

    const handleLogout = () => {
        localStorage.removeItem('wefix_admin_auth');
        navigate('/login');
    };

    const toggleShopStatus = async (shopId: string, currentStatus: boolean) => {
        try {
            const shopRef = doc(db, 'registered_shop_users', shopId);
            await updateDoc(shopRef, {
                active: !currentStatus
            });
        } catch (error) {
            console.error("Error toggling shop status:", error);
            alert("Failed to update status. Please check your Firebase rules.");
        }
    };

    const filteredShops = shops.filter(shop =>
        shop.companyLegalName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        shop.phone?.includes(searchTerm) ||
        shop.address?.city?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="app-container">
            {/* Sidebar */}
            <aside style={{
                width: '260px',
                background: 'var(--surface)',
                borderRight: '1px solid var(--border)',
                display: 'flex',
                flexDirection: 'column',
                padding: '2rem 1.5rem',
            }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '3rem' }}>
                    <div style={{
                        background: 'var(--primary)',
                        color: 'white',
                        padding: '0.5rem',
                        borderRadius: '0.5rem'
                    }}>
                        <Activity size={24} />
                    </div>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: '700' }}>WeFix Admin</h2>
                </div>

                <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    <button
                        onClick={() => setActiveTab('shops')}
                        style={{
                            width: '100%',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.75rem',
                            padding: '0.75rem 1rem',
                            background: activeTab === 'shops' ? '#eff6ff' : 'transparent',
                            color: activeTab === 'shops' ? 'var(--primary)' : 'var(--text-secondary)',
                            borderRadius: 'var(--radius)',
                            fontWeight: '600',
                            fontSize: '0.95rem'
                        }}
                    >
                        <Users size={20} />
                        Shop Management
                    </button>
                    <button
                        onClick={() => setActiveTab('banners')}
                        style={{
                            width: '100%',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.75rem',
                            padding: '0.75rem 1rem',
                            background: activeTab === 'banners' ? '#eff6ff' : 'transparent',
                            color: activeTab === 'banners' ? 'var(--primary)' : 'var(--text-secondary)',
                            borderRadius: 'var(--radius)',
                            fontWeight: '600',
                            fontSize: '0.95rem'
                        }}
                    >
                        <ImageIcon size={20} />
                        Banners
                    </button>
                </nav>

                <button
                    onClick={handleLogout}
                    style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.75rem',
                        padding: '0.75rem 1rem',
                        color: 'var(--text-secondary)',
                        background: 'transparent',
                        fontWeight: '500',
                        transition: 'color 0.2s',
                    }}
                    onMouseOver={(e) => e.currentTarget.style.color = 'var(--danger)'}
                    onMouseOut={(e) => e.currentTarget.style.color = 'var(--text-secondary)'}
                >
                    <LogOut size={20} />
                    Logout
                </button>
            </aside>

            {/* Main Content */}
            <main className="main-content">
                {activeTab === 'shops' ? (
                    <>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                            <div>
                                <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>Shop Management</h1>
                                <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>View and verify registered shops on WeFix.</p>
                            </div>

                            <div style={{ position: 'relative', width: '300px' }}>
                                <Search style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                                <input
                                    type="text"
                                    placeholder="Search shops..."
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    style={{
                                        width: '100%',
                                        padding: '0.75rem 1rem 0.75rem 2.875rem',
                                        borderRadius: '999px',
                                        border: '1px solid var(--border)',
                                        outline: 'none',
                                        boxShadow: 'var(--shadow-sm)',
                                        transition: 'border-color 0.2s, box-shadow 0.2s',
                                    }}
                                    onFocus={(e) => {
                                        e.currentTarget.style.borderColor = 'var(--primary)';
                                        e.currentTarget.style.boxShadow = '0 0 0 3px rgba(59, 130, 246, 0.1)';
                                    }}
                                    onBlur={(e) => {
                                        e.currentTarget.style.borderColor = 'var(--border)';
                                        e.currentTarget.style.boxShadow = 'var(--shadow-sm)';
                                    }}
                                />
                            </div>
                        </div>

                        {/* Status Overview Cards */}
                        <div style={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
                            gap: '1.5rem',
                            marginBottom: '2rem'
                        }}>
                            <div className="glass" style={{ padding: '1.5rem', borderRadius: 'var(--radius)', background: 'var(--surface)', border: '1px solid var(--border)', boxShadow: 'var(--shadow)' }}>
                                <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', fontWeight: '500' }}>Total Shops</p>
                                <h3 style={{ fontSize: '2rem', fontWeight: '700', color: 'var(--text-primary)', marginTop: '0.5rem' }}>{shops.length}</h3>
                            </div>
                            <div className="glass" style={{ padding: '1.5rem', borderRadius: 'var(--radius)', background: 'var(--surface)', border: '1px solid var(--border)', boxShadow: 'var(--shadow)' }}>
                                <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', fontWeight: '500' }}>Active Shops</p>
                                <h3 style={{ fontSize: '2rem', fontWeight: '700', color: 'var(--secondary)', marginTop: '0.5rem' }}>{shops.filter(s => s.active).length}</h3>
                            </div>
                            <div className="glass" style={{ padding: '1.5rem', borderRadius: 'var(--radius)', background: 'var(--surface)', border: '1px solid var(--border)', boxShadow: 'var(--shadow)' }}>
                                <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', fontWeight: '500' }}>Pending Verification</p>
                                <h3 style={{ fontSize: '2rem', fontWeight: '700', color: 'var(--warning)', marginTop: '0.5rem' }}>{shops.filter(s => !s.active).length}</h3>
                            </div>
                        </div>

                        <div className="data-table-container animate-fade-in">
                            <table className="data-table">
                                <thead>
                                    <tr>
                                        <th>Shop Info</th>
                                        <th>Location</th>
                                        <th>Category</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filteredShops.map(shop => (
                                        <tr key={shop.id}>
                                            <td>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                                    <img
                                                        src={shop.primaryPhoto || 'https://via.placeholder.com/40'}
                                                        alt={shop.companyLegalName}
                                                        style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                                                    />
                                                    <div>
                                                        <div style={{ fontWeight: '600' }}>{shop.companyLegalName}</div>
                                                        <div style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>{shop.phone}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <div style={{ fontSize: '0.875rem' }}>
                                                    {shop.address?.city}, {shop.address?.state}
                                                </div>
                                            </td>
                                            <td>
                                                <span style={{
                                                    background: '#f1f5f9',
                                                    padding: '0.25rem 0.5rem',
                                                    borderRadius: '0.5rem',
                                                    fontSize: '0.875rem',
                                                    color: 'var(--text-secondary)',
                                                    display: 'inline-block',
                                                    maxWidth: '180px',
                                                    whiteSpace: 'nowrap',
                                                    overflow: 'hidden',
                                                    textOverflow: 'ellipsis'
                                                }}>
                                                    {shop.shopCategory}
                                                </span>
                                            </td>
                                            <td>
                                                <span className={`badge ${shop.active ? 'badge-active' : 'badge-inactive'}`}>
                                                    {shop.active ? 'Active' : 'Pending'}
                                                </span>
                                            </td>
                                            <td>
                                                <div style={{ display: 'flex', gap: '0.5rem' }}>
                                                    <button
                                                        className="btn-secondary"
                                                        style={{ padding: '0.5rem 1rem', fontSize: '0.875rem' }}
                                                        onClick={() => setSelectedShop(shop)}
                                                    >
                                                        View Details
                                                    </button>

                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {filteredShops.length === 0 && (
                                        <tr>
                                            <td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-secondary)' }}>
                                                No shops found matching your criteria.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </>
                ) : (
                    <BannersManager />
                )}
            </main>

            {/* Details Modal */}
            {selectedShop && (
                <ShopDetailsModal
                    shop={selectedShop}
                    onClose={() => setSelectedShop(null)}
                    onToggleStatus={() => toggleShopStatus(selectedShop.id, selectedShop.active)}
                />
            )}
        </div>
    );
};

export default Dashboard;
