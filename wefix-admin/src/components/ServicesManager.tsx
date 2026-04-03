import React, { useEffect, useState } from 'react';
import { collection, collectionGroup, getDocs, query, where, orderBy } from 'firebase/firestore';
import { db } from '../firebase/config';
import type { Shop } from '../pages/Dashboard';
import { ChevronLeft } from 'lucide-react';

interface ServiceRequest {
    id: string;
    yourName: string;
    deviceType: string;
    amount: string;
    serviceDetails?: {
        totalCost: number;
        laborCost: number;
        partsCost: number;
    };
    borzoDeliveryCost?: string;
    createdAt: any;
    status: string;
}

const ServicesManager: React.FC = () => {
    const [shops, setShops] = useState<Shop[]>([]);
    const [selectedShop, setSelectedShop] = useState<Shop | null>(null);
    const [requests, setRequests] = useState<ServiceRequest[]>([]);
    const [, setLoading] = useState(true);
    const [shopStats, setShopStats] = useState<Record<string, { count: number, earnings: number }>>({});

    useEffect(() => {
        const fetchShops = async () => {
            setLoading(true);
            const q = query(collection(db, 'registered_shop_users'));
            const snapshot = await getDocs(q);
            const shopsData: Shop[] = [];
            snapshot.forEach((doc) => {
                shopsData.push({ id: doc.id, ...doc.data() } as Shop);
            });
            setShops(shopsData);

            // Fetch aggregate stats for all shops (using collectionGroup without filters to avoid index issues)
            const allReqQuery = query(collectionGroup(db, 'requests'));
            const allReqSnap = await getDocs(allReqQuery);
            const stats: Record<string, { count: number, earnings: number }> = {};

            allReqSnap.forEach((doc) => {
                const data = doc.data();
                const sId = data.shopId;
                if (!sId) return;

                // Count all services
                if (!stats[sId]) stats[sId] = { count: 0, earnings: 0 };
                stats[sId].count++;

                // Only sum earnings for completed/paid statuses
                const completedStatuses = ['payment_done', 'completed', 'paid'];
                if (completedStatuses.includes(data.status)) {
                    const amount = data.serviceDetails?.totalCost || Number(data.amount) || 0;
                    stats[sId].earnings += amount;
                }
            });
            setShopStats(stats);
            setLoading(false);
        };

        fetchShops();
    }, []);

    const fetchShopRequests = async (shop: Shop) => {
        setLoading(true);
        setSelectedShop(shop);
        try {
            // Using direct path to avoid index issues with collectionGroup + where
            const q = query(
                collection(db, 'shop_users', shop.id, 'requests'),
                orderBy('createdAt', 'desc')
            );
            const snapshot = await getDocs(q);
            const reqs: ServiceRequest[] = [];
            snapshot.forEach((doc) => {
                reqs.push({ id: doc.id, ...doc.data() } as ServiceRequest);
            });
            setRequests(reqs);
        } catch (error) {
            console.error("Error fetching requests:", error);
            // Fallback to collectionGroup if shop_users path fails for some reason
            const qGroup = query(
                collectionGroup(db, 'requests'),
                where('shopId', '==', shop.id)
            );
            const snapshot = await getDocs(qGroup);
            const reqs: ServiceRequest[] = [];
            snapshot.forEach((doc) => {
                reqs.push({ id: doc.id, ...doc.data() } as ServiceRequest);
            });
            setRequests(reqs);
        }
        setLoading(false);
    };

    const calculateTotals = () => {
        let totalService = 0;
        let totalBorzo = 0;
        let totalCommission = 0;

        requests.forEach(req => {
            const serviceCost = req.serviceDetails?.totalCost || Number(req.amount) || 0;
            const borzoCost = Number(req.borzoDeliveryCost) || 0;
            const commission = serviceCost * 0.20;

            totalService += serviceCost;
            totalBorzo += borzoCost;
            totalCommission += commission;
        });

        const totalSettlement = totalService - totalCommission;
        return { totalService, totalBorzo, totalCommission, totalSettlement };
    };

    if (selectedShop) {
        const { totalService, totalBorzo, totalCommission, totalSettlement } = calculateTotals();

        return (
            <div className="animate-fade-in">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                    <button
                        onClick={() => setSelectedShop(null)}
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            color: 'var(--text-secondary)',
                            background: 'transparent',
                            fontSize: '0.95rem',
                            fontWeight: '500',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        <ChevronLeft size={20} />
                        Back to Shop List
                    </button>

                    <div className="glass" style={{ padding: '0.75rem 1.5rem', borderRadius: '12px', border: '1px solid var(--primary)', background: 'rgba(37, 99, 235, 0.05)' }}>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', textTransform: 'uppercase', fontWeight: '700', letterSpacing: '0.05em' }}>Total Settlement Due</div>
                        <div style={{ color: 'var(--primary)', fontSize: '1.5rem', fontWeight: '800' }}>₹{totalSettlement.toLocaleString()}</div>
                    </div>
                </div>

                <div style={{ marginBottom: '2rem' }}>
                    <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>
                        Ledger: {selectedShop.companyLegalName}
                    </h1>
                </div>

                <div className="data-table-container">
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Service/ID</th>
                                <th>Customer</th>
                                <th>Service Cost</th>
                                <th>Borzo Cost</th>
                                <th>Commission (20%)</th>
                                <th style={{ color: 'var(--primary)' }}>Settlement</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            {requests.map((req) => {
                                const serviceCost = req.serviceDetails?.totalCost || Number(req.amount) || 0;
                                const borzoCost = Number(req.borzoDeliveryCost) || 0;
                                const commission = serviceCost * 0.20;
                                const settlement = serviceCost - commission;

                                return (
                                    <tr key={req.id}>
                                        <td>
                                            <div style={{ fontWeight: '600' }}>{req.deviceType}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>ID: {req.id}</div>
                                        </td>
                                        <td>
                                            <div>{req.yourName || 'Unknown'}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                                                {req.createdAt ? new Date(req.createdAt.toMillis()).toLocaleDateString() : 'N/A'}
                                            </div>
                                        </td>
                                        <td>₹{serviceCost.toLocaleString()}</td>
                                        <td>₹{borzoCost.toLocaleString()}</td>
                                        <td style={{ color: 'var(--danger)', fontWeight: '600' }}>-₹{commission.toLocaleString()}</td>
                                        <td style={{ fontWeight: '800', color: 'var(--primary)' }}>₹{settlement.toLocaleString()}</td>
                                        <td>
                                            <span style={{
                                                fontSize: '0.75rem',
                                                textTransform: 'uppercase',
                                                fontWeight: '700',
                                                color: req.status === 'completed' || req.status === 'payment_done' ? 'var(--secondary)' : 'var(--warning)'
                                            }}>
                                                {req.status?.replace('_', ' ')}
                                            </span>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                        <tfoot style={{ background: 'rgba(37, 99, 235, 0.03)', fontWeight: '800' }}>
                            <tr>
                                <td colSpan={2} style={{ textAlign: 'right', padding: '1.25rem' }}>TOTALS:</td>
                                <td style={{ padding: '1.25rem' }}>₹{totalService.toLocaleString()}</td>
                                <td style={{ padding: '1.25rem' }}>₹{totalBorzo.toLocaleString()}</td>
                                <td style={{ padding: '1.25rem', color: 'var(--danger)' }}>-₹{totalCommission.toLocaleString()}</td>
                                <td style={{ padding: '1.25rem', color: 'var(--primary)', fontSize: '1.1rem' }}>₹{totalSettlement.toLocaleString()}</td>
                                <td></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        );
    }

    return (
        <div className="animate-fade-in">
            <div style={{ marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: 'var(--text-primary)' }}>Services Overview</h1>
                <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>Tracking shop earnings and platform commissions.</p>
            </div>

            <div className="data-table-container">
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>Shop Name</th>
                            <th>Category</th>
                            <th>Total Services</th>
                            <th>Gross Earnings</th>
                            <th>Estimated Commission</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {shops.map((shop) => {
                            const stats = shopStats[shop.id] || { count: 0, earnings: 0 };
                            return (
                                <tr key={shop.id}>
                                    <td>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                            <img
                                                src={shop.primaryPhoto || 'https://via.placeholder.com/40'}
                                                alt={shop.companyLegalName}
                                                style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                                            />
                                            <div style={{ fontWeight: '600' }}>{shop.companyLegalName}</div>
                                        </div>
                                    </td>
                                    <td>
                                        <span style={{
                                            background: '#f1f5f9',
                                            padding: '0.25rem 0.5rem',
                                            borderRadius: '0.5rem',
                                            fontSize: '0.875rem',
                                            color: 'var(--text-secondary)'
                                        }}>
                                            {shop.shopCategory}
                                        </span>
                                    </td>
                                    <td>{stats.count} Jobs</td>
                                    <td style={{ fontWeight: '700' }}>₹{stats.earnings.toLocaleString()}</td>
                                    <td style={{ fontWeight: '700', color: 'var(--secondary)' }}>₹{(stats.earnings * 0.20).toLocaleString()}</td>
                                    <td>
                                        <button
                                            className="btn-primary"
                                            style={{ padding: '0.5rem 1rem', fontSize: '0.875rem' }}
                                            onClick={() => fetchShopRequests(shop)}
                                        >
                                            View Logs
                                        </button>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default ServicesManager;
