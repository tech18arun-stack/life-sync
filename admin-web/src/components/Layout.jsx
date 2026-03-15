import React from 'react';
import { LayoutDashboard, Users, Activity, CreditCard, Heart, LogOut, Menu, X } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { motion, AnimatePresence } from 'framer-motion';

const Sidebar = ({ isOpen, toggleSidebar }) => {
    const location = useLocation();
    const { logout } = useAuth();

    const menuItems = [
        { icon: <LayoutDashboard size={20} />, label: 'Dashboard', path: '/' },
        { icon: <Users size={20} />, label: 'Users', path: '/users' },
        { icon: <Activity size={20} />, label: 'Activity', path: '/activity' },
        { icon: <CreditCard size={20} />, label: 'Subscriptions', path: '/subscriptions' },
        { icon: <Heart size={20} />, label: 'Health', path: '/health' },
    ];

    return (
        <aside className={`glass-sidebar fixed inset-y-0 left-0 z-50 w-64 transform ${isOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0 transition-transform duration-300 ease-in-out`}>
            <div className="flex flex-col h-full p-4">
                <div className="flex items-center justify-between mb-8 px-2">
                    <h1 className="text-2xl font-bold text-gradient">LifeSync Admin</h1>
                    <button onClick={toggleSidebar} className="lg:hidden text-gray-400 hover:text-white">
                        <X size={24} />
                    </button>
                </div>

                <nav className="flex-1 space-y-2">
                    {menuItems.map((item) => (
                        <Link
                            key={item.path}
                            to={item.path}
                            className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                                location.pathname === item.path
                                    ? 'bg-primary-500/20 text-primary-400 border border-primary-500/30'
                                    : 'text-gray-400 hover:bg-white/5 hover:text-white'
                            }`}
                        >
                            {item.icon}
                            <span className="font-medium">{item.label}</span>
                        </Link>
                    ))}
                </nav>

                <button
                    onClick={logout}
                    className="flex items-center space-x-3 px-4 py-3 text-gray-400 hover:text-red-400 hover:bg-red-500/10 rounded-xl transition-all duration-200 mt-auto"
                >
                    <LogOut size={20} />
                    <span className="font-medium">Logout</span>
                </button>
            </div>
        </aside>
    );
};

const Topbar = ({ toggleSidebar }) => {
    const { user } = useAuth();

    return (
        <header className="h-16 glass-sidebar flex items-center justify-between px-6 sticky top-0 z-40 bg-opacity-50">
            <button onClick={toggleSidebar} className="lg:hidden text-gray-400 hover:text-white">
                <Menu size={24} />
            </button>
            
            <div className="flex items-center space-x-4">
                <div className="text-right">
                    <p className="text-sm font-medium text-white">{user?.name || 'Admin User'}</p>
                    <p className="text-xs text-gray-400">{user?.email}</p>
                </div>
                <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-primary-500 to-indigo-500 flex items-center justify-center text-white font-bold">
                    {user?.name?.charAt(0) || 'A'}
                </div>
            </div>
        </header>
    );
};

const Layout = ({ children }) => {
    const [isSidebarOpen, setIsSidebarOpen] = React.useState(false);
    const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

    return (
        <div className="min-h-screen flex bg-[#0f172a] text-white">
            <Sidebar isOpen={isSidebarOpen} toggleSidebar={toggleSidebar} />
            
            <div className="flex-1 lg:ml-64 flex flex-col">
                <Topbar toggleSidebar={toggleSidebar} />
                <main className="p-6">
                    <AnimatePresence mode="wait">
                        <motion.div
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            transition={{ duration: 0.2 }}
                        >
                            {children}
                        </motion.div>
                    </AnimatePresence>
                </main>
            </div>
        </div>
    );
};

export default Layout;
