import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, deleteDoc, addDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytesResumable, getDownloadURL, deleteObject } from 'firebase/storage';
import { db, storage } from '../firebase/config';
import { Trash2, Upload, Image as ImageIcon } from 'lucide-react';

export interface Banner {
    id: string;
    imageUrl: string;
    active: boolean;
    createdAt: any;
}

const BannersManager = () => {
    const [banners, setBanners] = useState<Banner[]>([]);
    const [uploading, setUploading] = useState(false);
    const [progress, setProgress] = useState(0);

    useEffect(() => {
        const q = query(collection(db, 'banners'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const bannersData: Banner[] = [];
            snapshot.forEach((doc) => {
                bannersData.push({ id: doc.id, ...doc.data() } as Banner);
            });
            bannersData.sort((a, b) => {
                if (!a.createdAt || !b.createdAt) return 0;
                return b.createdAt.toMillis() - a.createdAt.toMillis();
            });
            setBanners(bannersData);
        });
        return () => unsubscribe();
    }, []);

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setUploading(true);
        const storageRef = ref(storage, `banners/${Date.now()}_${file.name}`);
        const uploadTask = uploadBytesResumable(storageRef, file);

        uploadTask.on(
            'state_changed',
            (snapshot) => {
                const prog = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                setProgress(prog);
            },
            (error) => {
                console.error("Upload error:", error);
                alert("Failed to upload image.");
                setUploading(false);
            },
            async () => {
                const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
                await addDoc(collection(db, 'banners'), {
                    imageUrl: downloadURL,
                    active: true,
                    createdAt: serverTimestamp(),
                });
                setUploading(false);
                setProgress(0);
                if (e.target) e.target.value = '';
            }
        );
    };

    const handleDelete = async (banner: Banner) => {
        if (!window.confirm("Are you sure you want to delete this banner?")) return;

        try {
            await deleteDoc(doc(db, 'banners', banner.id));

            // Try to delete from storage if possible
            try {
                // Approximate extraction of storage path from URL
                const pathRegex = /o\/(.*)\?alt=media/;
                const match = banner.imageUrl.match(pathRegex);
                if (match && match[1]) {
                    const storagePath = decodeURIComponent(match[1]);
                    const storageRef = ref(storage, storagePath);
                    await deleteObject(storageRef);
                }
            } catch (storageErr) {
                console.error("Could not delete from storage:", storageErr);
            }
        } catch (error) {
            console.error("Error deleting banner:", error);
            alert("Failed to delete banner.");
        }
    };

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                    <h2 style={{ fontSize: '1.5rem', fontWeight: '600' }}>Banner Management</h2>
                    <p style={{ color: 'var(--text-secondary)' }}>Upload and manage banners shown on the app's home screen.</p>
                </div>
                <div>
                    <input
                        type="file"
                        accept="image/*"
                        id="banner-upload"
                        style={{ display: 'none' }}
                        onChange={handleFileChange}
                        disabled={uploading}
                    />
                    <label
                        htmlFor="banner-upload"
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            padding: '0.75rem 1.5rem',
                            background: uploading ? 'var(--text-secondary)' : 'var(--primary)',
                            color: 'white',
                            borderRadius: '0.5rem',
                            cursor: uploading ? 'not-allowed' : 'pointer',
                            fontWeight: '500'
                        }}
                    >
                        {uploading ? (
                            <span>Uploading {Math.round(progress)}%</span>
                        ) : (
                            <>
                                <Upload size={18} />
                                Upload New Banner
                            </>
                        )}
                    </label>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                {banners.map(banner => (
                    <div key={banner.id} style={{
                        background: 'var(--surface)',
                        border: '1px solid var(--border)',
                        borderRadius: '0.75rem',
                        overflow: 'hidden',
                        boxShadow: 'var(--shadow-sm)'
                    }}>
                        <div style={{ height: '160px', width: '100%', background: '#f1f5f9', position: 'relative' }}>
                            <img
                                src={banner.imageUrl}
                                alt="Banner"
                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            />
                        </div>
                        <div style={{ padding: '1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <span style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '0.25rem',
                                color: banner.active ? 'var(--secondary)' : 'var(--text-secondary)',
                                fontSize: '0.875rem',
                                fontWeight: '500'
                            }}>
                                <span style={{
                                    width: '8px',
                                    height: '8px',
                                    borderRadius: '50%',
                                    background: banner.active ? 'var(--secondary)' : 'var(--text-secondary)'
                                }}></span>
                                {banner.active ? 'Active' : 'Inactive'}
                            </span>
                            <button
                                onClick={() => handleDelete(banner)}
                                style={{
                                    background: 'transparent',
                                    color: 'var(--danger)',
                                    padding: '0.5rem',
                                    borderRadius: '0.25rem',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}
                                title="Delete Banner"
                            >
                                <Trash2 size={18} />
                            </button>
                        </div>
                    </div>
                ))}

                {banners.length === 0 && !uploading && (
                    <div style={{
                        gridColumn: '1 / -1',
                        padding: '4rem',
                        textAlign: 'center',
                        background: 'var(--surface)',
                        borderRadius: '0.75rem',
                        border: '1px dashed var(--border)'
                    }}>
                        <ImageIcon size={48} color="var(--text-secondary)" style={{ margin: '0 auto 1rem' }} />
                        <h3 style={{ fontSize: '1.25rem', fontWeight: '500', marginBottom: '0.5rem' }}>No banners yet</h3>
                        <p style={{ color: 'var(--text-secondary)' }}>Upload your first banner to display it on the mobile app.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default BannersManager;
