import React, { useEffect, useState } from 'react';
import { databases, DATABASE_ID, COLLECTIONS } from '../lib/appwrite';
import { Heart, Activity, Calendar, User, ClipboardList, Paperclip } from 'lucide-react';

const Health = () => {
    const [records, setRecords] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchRecords();
    }, []);

    const fetchRecords = async () => {
        try {
            const response = await databases.listDocuments(DATABASE_ID, COLLECTIONS.HEALTH_RECORDS);
            setRecords(response.documents);
        } catch (error) {
            console.error('Error fetching health records:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold text-gradient">Health Ecosystem</h2>
                    <p className="text-gray-400 text-sm">Overview of medical history and diagnostic reports</p>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {loading ? (
                    [1, 2, 3].map(i => <div key={i} className="h-64 glass-card animate-pulse"></div>)
                ) : records.length === 0 ? (
                    <div className="col-span-full glass-card p-12 text-center text-gray-500">No health records found</div>
                ) : (
                    records.map((record) => (
                        <div key={record.$id} className="glass-card p-6 flex flex-col hover:border-primary-500/30 transition-colors">
                            <div className="flex items-start justify-between mb-4">
                                <div className="space-y-1">
                                    <div className="flex items-center space-x-2 text-primary-400">
                                        <Heart size={18} fill="currentColor" className="fill-opacity-10" />
                                        <h3 className="font-bold text-lg">{record.record_type}</h3>
                                    </div>
                                    <p className="text-sm text-gray-400 flex items-center">
                                        <User size={14} className="mr-1.5" />
                                        {record.member_name}
                                    </p>
                                </div>
                                <span className="bg-primary-500/10 text-primary-400 text-[10px] font-bold px-2 py-1 rounded uppercase tracking-widest border border-primary-500/20">
                                    NEW
                                </span>
                            </div>

                            <div className="flex-1 space-y-4">
                                <div className="p-3 bg-white/5 rounded-xl space-y-2 border border-white/5">
                                    <div className="flex items-start space-x-2">
                                        <ClipboardList size={16} className="text-indigo-400 mt-0.5 shrink-0" />
                                        <p className="text-sm text-gray-200 line-clamp-2">{record.diagnosis || 'No diagnosis recorded'}</p>
                                    </div>
                                    <div className="flex items-center space-x-2 text-xs text-gray-400">
                                        <Calendar size={14} />
                                        <span>Visited: {new Date(record.date).toLocaleDateString()}</span>
                                    </div>
                                </div>

                                {record.doctor_name && (
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-gray-500 text-xs">Practitioner</span>
                                        <span className="font-medium text-gray-300">Dr. {record.doctor_name}</span>
                                    </div>
                                )}
                            </div>

                            <button className="mt-6 w-full py-2 bg-white/5 hover:bg-white/10 rounded-xl text-sm font-medium flex items-center justify-center space-x-2 transition-all">
                                <Paperclip size={16} />
                                <span>View Documents</span>
                            </button>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default Health;
