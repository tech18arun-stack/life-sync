import React, { useEffect, useState } from 'react';
import { databases, DATABASE_ID, COLLECTIONS } from '../lib/appwrite';
import { CreditCard, Calendar, AlertCircle, CheckCircle2, Clock } from 'lucide-react';

const Subscriptions = () => {
    const [subs, setSubs] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchSubs();
    }, []);

    const fetchSubs = async () => {
        try {
            const response = await databases.listDocuments(DATABASE_ID, COLLECTIONS.SUBSCRIPTIONS);
            setSubs(response.documents);
        } catch (error) {
            console.error('Error fetching subscriptions:', error);
        } finally {
            setLoading(false);
        }
    };

    const isRenewalDueSoon = (date) => {
        const renewalDate = new Date(date);
        const today = new Date();
        const diffTime = renewalDate - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays >= 0 && diffDays <= 7;
    };

    return (
        <div className="space-y-6">
            <div>
                <h2 className="text-2xl font-bold">Subscription Management</h2>
                <p className="text-gray-400 text-sm">Monitor active recurring payments across all users</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {loading ? (
                    [1, 2, 3].map(i => <div key={i} className="h-48 glass-card animate-pulse"></div>)
                ) : subs.length === 0 ? (
                    <div className="col-span-full glass-card p-12 text-center text-gray-500">No subscriptions found</div>
                ) : (
                    subs.map((sub) => (
                        <div key={sub.$id} className="glass-card p-6 relative overflow-hidden group">
                            <div className="flex items-center justify-between mb-6">
                                <div className="w-12 h-12 rounded-2xl bg-primary-500/10 flex items-center justify-center text-primary-400 group-hover:scale-110 transition-transform duration-300">
                                    <CreditCard size={24} />
                                </div>
                                <div className="text-right">
                                    <p className="text-2xl font-bold text-white">${sub.amount}</p>
                                    <p className="text-xs text-gray-400 uppercase tracking-wider">{sub.billing_cycle}</p>
                                </div>
                            </div>

                            <div className="space-y-3">
                                <h3 className="text-lg font-bold truncate">{sub.name}</h3>
                                <div className="flex items-center text-sm text-gray-400">
                                    <Calendar size={14} className="mr-2" />
                                    Next Billing: {new Date(sub.next_billing_date).toLocaleDateString()}
                                </div>
                                <div className="flex items-center text-sm text-gray-400">
                                    <Clock size={14} className="mr-2" />
                                    User ID: {sub.user_id.substring(0, 12)}...
                                </div>
                            </div>

                            <div className="mt-6 flex items-center justify-between">
                                <span className={`flex items-center space-x-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
                                    isRenewalDueSoon(sub.next_billing_date) 
                                        ? 'bg-amber-500/10 text-amber-500' 
                                        : 'bg-green-500/10 text-green-500'
                                }`}>
                                    {isRenewalDueSoon(sub.next_billing_date) ? <AlertCircle size={12} /> : <CheckCircle2 size={12} />}
                                    <span>{isRenewalDueSoon(sub.next_billing_date) ? 'Renewal Soon' : 'Status: OK'}</span>
                                </span>
                                
                                <span className="text-xs font-medium text-gray-500 px-2 py-1 bg-white/5 rounded-lg border border-white/5">
                                    {sub.category}
                                </span>
                            </div>
                            
                            <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity">
                                <span className="h-2 w-2 rounded-full bg-primary-500 animate-ping"></span>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default Subscriptions;
