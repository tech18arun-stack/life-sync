const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(express.json());

// MongoDB Connection with retry logic
const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        });
        console.log('✅ Connected to MongoDB - lifesync database');
    } catch (err) {
        console.error('❌ MongoDB connection error:', err.message);
        // Retry connection after 5 seconds
        console.log('🔄 Retrying connection in 5 seconds...');
        setTimeout(connectDB, 5000);
    }
};

connectDB();

// Routes
const authRouter = require('./routes/auth');
const familyMembersRouter = require('./routes/familyMembers');
const familyNumbersRouter = require('./routes/familyNumbers');
const expensesRouter = require('./routes/expenses');
const incomesRouter = require('./routes/incomes');
const tasksRouter = require('./routes/tasks');
const budgetsRouter = require('./routes/budgets');
const savingsRouter = require('./routes/savings');
const remindersRouter = require('./routes/reminders');
const healthRecordsRouter = require('./routes/healthRecords');

// Auth routes (no auth required)
app.use('/api/auth', authRouter);

// Protected routes
app.use('/api/family-members', familyMembersRouter);
app.use('/api/family-numbers', familyNumbersRouter);
app.use('/api/expenses', expensesRouter);
app.use('/api/incomes', incomesRouter);
app.use('/api/tasks', tasksRouter);
app.use('/api/budgets', budgetsRouter);
app.use('/api/savings', savingsRouter);
app.use('/api/reminders', remindersRouter);
app.use('/api/health-records', healthRecordsRouter);

// Health Check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        message: 'LifeSync API is running',
        database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    });
});

// Root URL - Welcome page
app.get('/', (req, res) => {
    res.json({
        name: 'LifeSync API',
        version: '1.0.0',
        description: 'Backend API for LifeSync Family Management App',
        status: 'running',
        endpoints: {
            health: '/api/health',
            auth: '/api/auth',
            expenses: '/api/expenses',
            incomes: '/api/incomes',
            tasks: '/api/tasks',
            budgets: '/api/budgets',
            savings: '/api/savings',
            reminders: '/api/reminders',
            healthRecords: '/api/health-records',
            familyMembers: '/api/family-members',
            familyNumbers: '/api/family-numbers'
        }
    });
});

// Start Server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`🚀 LifeSync Backend running on http://localhost:${PORT}`);
    console.log(`📊 API Health: http://localhost:${PORT}/api/health`);
});

