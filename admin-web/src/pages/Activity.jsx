import React, { useEffect, useState } from 'react';
import { databases, DATABASE_ID, COLLECTIONS } from '../lib/appwrite';
import { Query } from 'appwrite';
import { Activity, Clock, Heart, Receipt, CreditCard, TrendingUp, Calendar, Filter, BarChart3, Users } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

const ActivityPage = () => {
    const [timeFilter, setTimeFilter] = useState('week'); // day, week, month, year
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [stats, setStats] = useState({
        totalActions: 0,
        activeServices: 0,
        mostUsedService: 'N/A'
    });

    useEffect(() => {
        fetchRealActivityData();
    }, [timeFilter]);

    const fetchRealActivityData = async () => {
        setLoading(true);
        try {
            // Fetch records from multiple collections to represent "Activity"
            const [exp, inc, health, subs, profiles] = await Promise.all([
                databases.listDocuments(DATABASE_ID, COLLECTIONS.EXPENSES, [Query.limit(50), Query.orderDesc('date')]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.INCOMES, [Query.limit(50), Query.orderDesc('date')]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.HEALTH_RECORDS, [Query.limit(50), Query.orderDesc('date')]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.SUBSCRIPTIONS, [Query.limit(50), Query.orderDesc('created_at')]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.USER_PROFILES, [Query.limit(50)])
            ]);

            // Transform different record types into unified "Activity" items
            const unifiedActivities = [
                ...exp.documents.map(d => ({ 
                    id: d.$id, type: 'Expense', name: d.description, date: d.date, icon: <Receipt size={14} />, color: 'text-red-400', bg: 'bg-red-500/10', uid: d.user_id 
                })),
                ...inc.documents.map(d => ({ 
                    id: d.$id, type: 'Income', name: d.description, date: d.date, icon: <TrendingUp size={14} />, color: 'text-green-400', bg: 'bg-green-500/10', uid: d.user_id 
                })),
                ...health.documents.map(d => ({ 
                    id: d.$id, type: 'Health', name: `${d.record_type} (${d.member_name})`, date: d.date, icon: <Heart size={14} />, color: 'text-pink-400', bg: 'bg-pink-500/10', uid: d.user_id 
                })),
                ...subs.documents.map(d => ({ 
                    id: d.$id, type: 'Subscription', name: d.name, date: d.created_at || d.$createdAt, icon: <CreditCard size={14} />, color: 'text-primary-400', bg: 'bg-primary-500/10', uid: d.user_id 
                }))
            ].sort((a, b) => new Date(b.date) - new Date(a.date));

            setActivities(unifiedActivities);

            // Calculate Metrics
            const serviceCounts = { Expense: 0, Income: 0, Health: 0, Subscription: 0 };
            unifiedActivities.forEach(a => serviceCounts[a.type]++);
            
            const topService = Object.keys(serviceCounts).reduce((a, b) => serviceCounts[a] > serviceCounts[b] ? a : b);

            setStats({
                totalActions: unifiedActivities.length,
                activeServices: Object.values(serviceCounts).filter(v => v > 0).length,
                mostUsedService: topService
            });

        } catch (error) {
            console.error('Error fetching activities:', error);
        } finally {
            setLoading(false);
        }
    };

    const getFilterLabel = () => {
        switch(timeFilter) {
            case 'day': return 'Today';
            case 'week': return 'This Week';
            case 'month': return 'This Month';
            case 'year': return 'This Year';
            default: return 'Time Period';
        }
    };

    // Realistic chart data based on the activities
    const getChartData = () => {
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const counts = new Array(7).fill(0);
        
        activities.forEach(a => {
            const d = new Date(a.date);
            counts[d.getDay()]++;
        });

        return days.map((day, i) => ({ name: day, value: counts[i] }));
    };

    return (
        <div className="space-y-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h2 className="text-2xl font-bold">Service Activity Insights</h2>
                    <p className="text-gray-400 text-sm">Real-time usage across Expense, Income, Health and Subscriptions</p>
                </div>
                
                <div className="flex bg-white/5 p-1 rounded-xl border border-white/10 self-start">
                    {['day', 'week', 'month', 'year'].map((filter) => (
                        <button
                            key={filter}
                            onClick={() => setTimeFilter(filter)}
                            className={`px-4 py-2 rounded-lg text-xs font-bold uppercase tracking-wider transition-all ${
                                timeFilter === filter ? 'bg-primary-500 text-white shadow-lg' : 'text-gray-500 hover:text-white'
                            }`}
                        >
                            {filter}
                        </button>
                    ))}
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="glass-card p-6 border-l-4 border-l-primary-500">
                    <div className="flex items-center justify-between opacity-50 mb-2">
                        <span className="text-xs font-bold uppercase">Total Actions</span>
                        <Activity size={18} />
                    </div>
                    <p className="text-3xl font-black">{stats.totalActions}</p>
                    <p className="text-xs text-primary-400 mt-1">{getFilterLabel()} analysis</p>
                </div>
                <div className="glass-card p-6 border-l-4 border-l-indigo-500">
                    <div className="flex items-center justify-between opacity-50 mb-2">
                        <span className="text-xs font-bold uppercase">Active Modules</span>
                        <Filter size={18} />
                    </div>
                    <p className="text-3xl font-black">{stats.activeServices}</p>
                    <p className="text-xs text-gray-400 mt-1">Modules with recorded data</p>
                </div>
                <div className="glass-card p-6 border-l-4 border-l-pink-500">
                    <div className="flex items-center justify-between opacity-50 mb-2">
                        <span className="text-xs font-bold uppercase">Most Active</span>
                        <BarChart3 size={18} />
                    </div>
                    <p className="text-3xl font-black">{stats.mostUsedService}</p>
                    <p className="text-xs text-pink-400 mt-1">Highest frequency module</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="glass-card p-6">
                    <h3 className="font-bold mb-8 flex items-center">
                        <BarChart3 size={18} className="mr-2 text-primary-400" />
                        Engagement Distribution
                    </h3>
                    <div className="h-64 w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={getChartData()}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.05)" />
                                <XAxis dataKey="name" stroke="rgba(255,255,255,0.3)" fontSize={12} tickLine={false} axisLine={false} />
                                <Tooltip 
                                    cursor={{fill: 'rgba(255,255,255,0.05)'}}
                                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px' }}
                                />
                                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                                    {getChartData().map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.value > 0 ? '#0ea5e9' : 'rgba(14, 165, 233, 0.1)'} />
                                    ))}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="glass-card flex flex-col">
                    <div className="p-6 border-b border-white/5 flex items-center justify-between">
                        <h3 className="font-bold italic">Real Activity Feed</h3>
                        <span className="text-[10px] bg-green-500/10 text-green-400 px-2 py-0.5 rounded-full border border-green-500/20 animate-pulse">
                            LIVE SYNC
                        </span>
                    </div>
                    <div className="flex-1 overflow-y-auto max-h-80 p-4 space-y-4">
                        {loading ? (
                            <div className="animate-pulse space-y-4">
                                {[1, 2, 3, 4].map(i => <div key={i} className="h-16 bg-white/5 rounded-xl"></div>)}
                            </div>
                        ) : activities.length === 0 ? (
                            <div className="text-center py-20">
                                <Activity size={40} className="mx-auto text-gray-600 mb-4 opacity-20" />
                                <p className="text-gray-500 text-sm italic">No service data found for this period.</p>
                            </div>
                        ) : (
                            activities.map((act) => (
                                <div key={act.id} className="flex items-center space-x-3 p-3 rounded-xl hover:bg-white/5 transition-colors border border-transparent hover:border-white/10 group">
                                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border border-white/5 group-hover:scale-110 transition-transform ${act.bg} ${act.color}`}>
                                        {act.icon}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center justify-between">
                                            <p className="text-xs font-bold uppercase tracking-wider opacity-50">{act.type}</p>
                                            <p className="text-[10px] text-gray-500">{new Date(act.date).toLocaleDateString()}</p>
                                        </div>
                                        <p className="text-sm font-medium text-gray-200 truncate">{act.name}</p>
                                        <p className="text-[10px] text-gray-500 truncate">User: {act.uid}</p>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ActivityPage;
