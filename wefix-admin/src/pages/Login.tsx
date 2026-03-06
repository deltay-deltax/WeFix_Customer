import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail, ShieldCheck } from 'lucide-react';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db } from '../firebase/config';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const adminQuery = query(
                collection(db, 'admin'),
                where('email', '==', email)
            );
            const querySnapshot = await getDocs(adminQuery);

            if (querySnapshot.empty) {
                setError('Invalid admin credentials.');
                setLoading(false);
                return;
            }

            let isValid = false;
            querySnapshot.forEach((doc) => {
                const data = doc.data();
                if (data.pass === password) {
                    isValid = true;
                }
            });

            if (isValid) {
                localStorage.setItem('wefix_admin_auth', 'true');
                navigate('/');
            } else {
                setError('Invalid admin credentials.');
            }
        } catch (err) {
            console.error('Login error:', err);
            setError('Error connecting to database. Check your network.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-container" style={{
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)',
        }}>
            <div className="login-card glass animate-fade-in" style={{
                padding: '3rem',
                borderRadius: '1.5rem',
                width: '100%',
                maxWidth: '400px',
                boxShadow: 'var(--shadow-lg)'
            }}>
                <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
                    <div style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        width: '64px',
                        height: '64px',
                        borderRadius: '50%',
                        backgroundColor: 'var(--primary)',
                        color: 'white',
                        marginBottom: '1rem'
                    }}>
                        <ShieldCheck size={32} />
                    </div>
                    <h1 style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)' }}>Admin Portal</h1>
                    <p style={{ color: 'var(--text-secondary)', marginTop: '0.5rem' }}>Login to manage shops</p>
                </div>

                <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    {error && <div style={{ color: 'var(--danger)', fontSize: '0.875rem', textAlign: 'center' }}>{error}</div>}

                    <div style={{ position: 'relative' }}>
                        <Mail style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                        <input
                            type="email"
                            placeholder="Admin Email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            style={{
                                width: '100%',
                                padding: '0.75rem 1rem 0.75rem 3rem',
                                borderRadius: '0.75rem',
                                border: '1px solid var(--border)',
                                outline: 'none',
                                transition: 'border-color 0.2s',
                                fontSize: '1rem'
                            }}
                            required
                        />
                    </div>

                    <div style={{ position: 'relative' }}>
                        <Lock style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} size={20} />
                        <input
                            type="password"
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            style={{
                                width: '100%',
                                padding: '0.75rem 1rem 0.75rem 3rem',
                                borderRadius: '0.75rem',
                                border: '1px solid var(--border)',
                                outline: 'none',
                                transition: 'border-color 0.2s',
                                fontSize: '1rem'
                            }}
                            required
                        />
                    </div>

                    <button type="submit" disabled={loading} className="btn-primary" style={{ width: '100%', padding: '0.875rem', fontSize: '1rem', marginTop: '0.5rem', opacity: loading ? 0.7 : 1 }}>
                        {loading ? 'Authenticating...' : 'Sign In'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Login;
