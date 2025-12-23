const express = require('express');
const router = express.Router();
const Expense = require('../models/Expense');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all expenses with optional filters
router.get('/', async (req, res) => {
    try {
        const { category, startDate, endDate, limit } = req.query;
        const filter = { userId: req.familyId };

        if (category) filter.category = category;
        if (startDate || endDate) {
            filter.date = {};
            if (startDate) filter.date.$gte = new Date(startDate);
            if (endDate) filter.date.$lte = new Date(endDate);
        }

        let query = Expense.find(filter).sort({ date: -1 });
        if (limit) query = query.limit(parseInt(limit));

        const expenses = await query.populate('familyMemberId', 'name');
        res.json(expenses);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get monthly summary
router.get('/summary/monthly', async (req, res) => {
    try {
        const { month, year } = req.query;
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0);

        const expenses = await Expense.aggregate([
            {
                $match: {
                    userId: req.familyId,
                    date: { $gte: startDate, $lte: endDate }
                }
            },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const totalAmount = expenses.reduce((sum, e) => sum + e.total, 0);
        res.json({ expenses, totalAmount });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single expense
router.get('/:id', async (req, res) => {
    try {
        const expense = await Expense.findOne({ _id: req.params.id, userId: req.familyId }).populate('familyMemberId', 'name');
        if (!expense) {
            return res.status(404).json({ error: 'Expense not found' });
        }
        res.json(expense);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create expense
router.post('/', async (req, res) => {
    try {
        const expense = new Expense({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await expense.save();
        res.status(201).json(expense);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update expense
router.put('/:id', async (req, res) => {
    try {
        const expense = await Expense.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!expense) {
            return res.status(404).json({ error: 'Expense not found' });
        }
        res.json(expense);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete expense
router.delete('/:id', async (req, res) => {
    try {
        const expense = await Expense.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!expense) {
            return res.status(404).json({ error: 'Expense not found' });
        }
        res.json({ message: 'Expense deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

