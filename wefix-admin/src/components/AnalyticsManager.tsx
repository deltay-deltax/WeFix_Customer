import React, { useEffect, useState } from 'react';
import { collectionGroup, getDocs, query } from 'firebase/firestore';
import { db } from '../firebase/config';
import { TrendingUp, Truck, Percent, ShoppingBag, Activity, CheckCircle2 } from 'lucide-react';

interface AggregateStats {
    totalSales: number;
    totalBorzo: number;
    totalCommission: number;
    jobCount: number;
    statusCounts: Record<string, number>;
}

const AnalyticsManager: React.FC = () => {
    const [stats, setStats] = useState<AggregateStats>({
        totalSales: 0,
        totalBorzo: 0,
        totalCommission: 0,
        jobCount: 0,
        statusCounts: {}
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchGlobalStats();
    }, []);

    const fetchGlobalStats = async () => {
        setLoading(true);
        try {
            const q = query(collectionGroup(db, 'requests'));
            const snapshot = await getDocs(q);
            
            let sales = 0;
            let borzo = 0;
            let comm = 0;
            let count = 0;
            const statuses: Record<string, number> = {};

            snapshot.forEach((doc) => {
                const data = doc.data();
                count++;
                
                // Status distribution
                const s = data.status || 'unknown';
                statuses[s] = (statuses[s] || 0) + 1;

                // Revenue calculation (only for completed/paid statuses)
                const completedStatuses = ['payment_done', 'completed', 'paid'];
                if (completedStatuses.includes(s)) {
                    const cost = data.serviceDetails?.totalCost || Number(data.amount) || 0;
                    const bCost = Number(data.borzoDeliveryCost) || 0;
                    
                    sales += cost;
                    borzo += bCost;
                    comm += (cost * 0.20);
                }
            });

            setStats({
                totalSales: sales,
                totalBorzo: borzo,
                totalCommission: comm,
                jobCount: count,
                statusCounts: statuses
            });
        } catch (error) {
            console.error("Error fetching analytics:", error);
        }
        setLoading(false);
    };

    const MetricCard = ({ title, value, icon: Icon, color, subtitle }: any) => (
        <div className="glass" style={{ 
            padding: '2rem', 
            borderRadius: '24px', 
            background: 'white', 
            border: '1px solid var(--border)',
            boxShadow: 'var(--shadow)',
            display: 'flex',
            flexDirection: 'column',
            gap: '1rem',
            position: 'relative',
            overflow: 'hidden'
        }}>
            <div style={{
                position: 'absolute',
                top: '-10px',
                right: '-10px',
                width: '80px',
                height: '80px',
                background: `${color}10`,
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
            }}>
                <Icon size={40} style={{ color: color, opacity: 0.2 }} />
            </div>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div style={{ background: `${color}15`, padding: '0.6rem', borderRadius: '12px', color: color }}>
                    <Icon size={20} />
                </div>
                <span style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-secondary)' }}>{title}</span>
            </div>
            
            <div>
                <h2 style={{ fontSize: '2.5rem', fontWeight: '800', margin: 0, color: 'var(--text-primary)' }}>
                    ₹{value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
                </h2>
                {subtitle && <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: '500' }}>{subtitle}</p>}
            </div>
        </div>
    );

    return (
        <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto' }}>
            <div style={{ marginBottom: '3rem' }}>
                <h1 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--text-primary)', letterSpacing: '-0.02em' }}>Platform Intelligence</h1>
                <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem', fontSize: '1.1rem' }}>Aggregated revenue and logistics metrics across all service providers.</p>
            </div>

            {loading ? (
                <div style={{ textAlign: 'center', padding: '5rem' }}>
                    <Activity className="animate-pulse" size={48} color="var(--primary)" />
                    <p style={{ marginTop: '1rem', color: 'var(--text-secondary)' }}>Crunching global data...</p>
                </div>
            ) : (
                <>
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))',
                        gap: '2rem',
                        marginBottom: '3rem'
                    }}>
                        <MetricCard 
                            title="Total Service Provider Sales" 
                            value={stats.totalSales} 
                            icon={ShoppingBag} 
                            color="#2563eb"
                            subtitle="Gross sales generated by all partners"
                        />
                        <MetricCard 
                            title="Platform Commission (20%)" 
                            value={stats.totalCommission} 
                            icon={Percent} 
                            color="#7c3aed"
                            subtitle="Total revenue earned by WeFix platform"
                        />
                        <MetricCard 
                            title="Total Logistics Cost" 
                            value={stats.totalBorzo} 
                            icon={Truck} 
                            color="#059669"
                            subtitle="Aggregated Borzo delivery expenses"
                        />
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
                        <div className="glass" style={{ padding: '2rem', borderRadius: '24px' }}>
                            <h3 style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                                <TrendingUp size={20} color="var(--primary)" />
                                Status Distribution
                            </h3>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                                {Object.entries(stats.statusCounts).map(([status, count]) => {
                                    const percentage = (count / stats.jobCount) * 100;
                                    const isSuccess = ['completed', 'payment_done', 'paid'].includes(status);
                                    const isWarning = ['in_progress', 'pending'].includes(status);
                                    
                                    return (
                                        <div key={status}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem', fontSize: '0.875rem' }}>
                                                <span style={{ textTransform: 'capitalize', fontWeight: '600' }}>
                                                    {status.replace('_', ' ')}
                                                </span>
                                                <span style={{ color: 'var(--text-secondary)' }}>{count} jobs ({percentage.toFixed(0)}%)</span>
                                            </div>
                                            <div style={{ height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                                                <div style={{ 
                                                    height: '100%', 
                                                    width: `${percentage}%`, 
                                                    background: isSuccess ? '#22c55e' : isWarning ? '#f59e0b' : '#ef4444',
                                                    transition: 'width 1s ease-out'
                                                }} />
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        <div className="glass" style={{ padding: '2rem', borderRadius: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', textAlign: 'center' }}>
                            <div style={{ background: 'rgba(37, 99, 235, 0.05)', padding: '2rem', borderRadius: '50%', marginBottom: '1.5rem' }}>
                                <CheckCircle2 size={48} color="var(--primary)" />
                            </div>
                            <h3 style={{ fontSize: '1.5rem', fontWeight: '700', marginBottom: '0.5rem' }}>Total Jobs Processed</h3>
                            <p style={{ fontSize: '3rem', fontWeight: '800', color: 'var(--text-primary)', margin: 0 }}>{stats.jobCount}</p>
                            <p style={{ color: 'var(--text-secondary)', marginTop: '0.5rem' }}>Across all service categories</p>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

export default AnalyticsManager;
