const express = require('express');
const router = express.Router();
const Income = require('../models/Income');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all incomes with optional filters
router.get('/', async (req, res) => {
    try {
        const { source, startDate, endDate, limit } = req.query;
        const filter = { userId: req.familyId };

        if (source) filter.source = source;
        if (startDate || endDate) {
            filter.date = {};
            if (startDate) filter.date.$gte = new Date(startDate);
            if (endDate) filter.date.$lte = new Date(endDate);
        }

        let query = Income.find(filter).sort({ date: -1 });
        if (limit) query = query.limit(parseInt(limit));

        const incomes = await query.populate('familyMemberId', 'name');
        res.json(incomes);
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

        const incomes = await Income.aggregate([
            {
                $match: {
                    userId: req.familyId,
                    date: { $gte: startDate, $lte: endDate }
                }
            },
            {
                $group: {
                    _id: '$source',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const totalAmount = incomes.reduce((sum, i) => sum + i.total, 0);
        res.json({ incomes, totalAmount });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single income
router.get('/:id', async (req, res) => {
    try {
        const income = await Income.findOne({ _id: req.params.id, userId: req.familyId }).populate('familyMemberId', 'name');
        if (!income) {
            return res.status(404).json({ error: 'Income not found' });
        }
        res.json(income);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create income
router.post('/', async (req, res) => {
    try {
        const income = new Income({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await income.save();
        res.status(201).json(income);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update income
router.put('/:id', async (req, res) => {
    try {
        const income = await Income.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!income) {
            return res.status(404).json({ error: 'Income not found' });
        }
        res.json(income);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete income
router.delete('/:id', async (req, res) => {
    try {
        const income = await Income.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!income) {
            return res.status(404).json({ error: 'Income not found' });
        }
        res.json({ message: 'Income deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

