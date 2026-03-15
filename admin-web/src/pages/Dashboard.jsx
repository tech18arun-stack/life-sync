import React, { useEffect, useState } from 'react';
import { Users, Activity, CreditCard, Heart, TrendingUp, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { databases, DATABASE_ID, COLLECTIONS } from '../lib/appwrite';
import { Query } from 'appwrite';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const StatCard = ({ title, value, icon, change, trend }) => (
    <div className="glass-card p-6 flex flex-col">
        <div className="flex items-center justify-between mb-4">
            <div className="w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center text-primary-400 border border-white/5">
                {icon}
            </div>
            {change && (
                <div className={`flex items-center space-x-1 text-xs font-medium ${trend === 'up' ? 'text-green-400' : 'text-red-400'}`}>
                    <span>{change}</span>
                    {trend === 'up' ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
                </div>
            )}
        </div>
        <h3 className="text-gray-400 text-sm font-medium">{title}</h3>
        <p className="text-2xl font-bold text-white mt-1">{value}</p>
    </div>
);

const Dashboard = () => {
    const [stats, setStats] = useState({
        users: 0,
        activities: 0,
        logins: 0,
        subscriptions: 0
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        try {
            const [users, exp, inc, health, subs] = await Promise.all([
                databases.listDocuments(DATABASE_ID, COLLECTIONS.USER_PROFILES),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.EXPENSES, [Query.limit(0)]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.INCOMES, [Query.limit(0)]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.HEALTH_RECORDS, [Query.limit(0)]),
                databases.listDocuments(DATABASE_ID, COLLECTIONS.SUBSCRIPTIONS, [Query.limit(0)])
            ]);

            const totalActivityCount = exp.total + inc.total + health.total + subs.total;

            setStats({
                users: users.total,
                activities: totalActivityCount,
                logins: 24, // Mocked as we don't have separate login logs yet
                subscriptions: subs.total
            });
        } catch (error) {
            console.error('Error fetching stats:', error);
        } finally {
            setLoading(false);
        }
    };

    const data = [
        { name: 'Jan', value: 4000 },
        { name: 'Feb', value: 3000 },
        { name: 'Mar', value: 2000 },
        { name: 'Apr', value: 2780 },
        { name: 'May', value: 1890 },
        { name: 'Jun', value: 2390 },
        { name: 'Jul', value: 3490 },
    ];

    if (loading) {
        return <div className="animate-pulse space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {[1, 2, 3, 4].map(i => <div key={i} className="h-32 glass-card"></div>)}
            </div>
            <div className="h-96 glass-card"></div>
        </div>;
    }

    return (
        <div className="space-y-8">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold">Dashboard Overview</h2>
                    <p className="text-gray-400 text-sm">Welcome back to LifeSync Control Center</p>
                </div>
                <div className="flex items-center space-x-2 text-sm text-gray-400">
                    <TrendingUp size={16} className="text-green-400" />
                    <span>Real-time data enabled</span>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard title="Total Users" value={stats.users} icon={<Users size={24} />} change="+12%" trend="up" />
                <StatCard title="Total Activities" value={stats.activities} icon={<Activity size={24} />} change="+45%" trend="up" />
                <StatCard title="Service Logins" value={stats.logins} icon={<TrendingUp size={24} />} change="+18%" trend="up" />
                <StatCard title="Active Subs" value={stats.subscriptions} icon={<CreditCard size={24} />} change="+2%" trend="up" />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 glass-card p-6">
                    <h3 className="font-bold mb-6">User Engagement (Hits)</h3>
                    <div className="h-80 w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={data}>
                                <defs>
                                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#0ea5e9" stopOpacity={0.3}/>
                                        <stop offset="95%" stopColor="#0ea5e9" stopOpacity={0}/>
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.05)" />
                                <XAxis dataKey="name" stroke="rgba(255,255,255,0.3)" fontSize={12} tickLine={false} axisLine={false} />
                                <YAxis stroke="rgba(255,255,255,0.3)" fontSize={12} tickLine={false} axisLine={false} />
                                <Tooltip 
                                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px' }}
                                    itemStyle={{ color: '#fff' }}
                                />
                                <Area type="monotone" dataKey="value" stroke="#0ea5e9" fillOpacity={1} fill="url(#colorValue)" strokeWidth={2} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="glass-card p-6">
                    <h3 className="font-bold mb-6">Recent Users</h3>
                    <div className="space-y-4">
                        {[1, 2, 3, 4, 5].map((i) => (
                            <div key={i} className="flex items-center space-x-3">
                                <div className="w-10 h-10 rounded-full bg-indigo-500/20 text-indigo-400 flex items-center justify-center text-xs font-bold">
                                    JS
                                </div>
                                <div>
                                    <p className="text-sm font-medium">John Smith</p>
                                    <p className="text-xs text-gray-500">Premium Member</p>
                                </div>
                                <div className="ml-auto text-xs text-gray-500">2h ago</div>
                            </div>
                        ))}
                    </div>
                    <button className="w-full mt-6 py-2 text-sm text-primary-400 hover:text-primary-300 font-medium transition-colors">
                        View all users
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
