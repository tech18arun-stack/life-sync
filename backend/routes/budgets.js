const express = require('express');
const router = express.Router();
const Budget = require('../models/Budget');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all budgets
router.get('/', async (req, res) => {
    try {
        const { month, year, isActive } = req.query;
        const filter = { userId: req.familyId };

        if (month) filter.month = parseInt(month);
        if (year) filter.year = parseInt(year);
        if (isActive !== undefined) filter.isActive = isActive === 'true';

        const budgets = await Budget.find(filter).sort({ category: 1 });
        res.json(budgets);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get current month's budgets
router.get('/current', async (req, res) => {
    try {
        const now = new Date();
        const budgets = await Budget.find({
            userId: req.familyId,
            month: now.getMonth() + 1,
            year: now.getFullYear(),
            isActive: true
        });
        res.json(budgets);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get over-budget categories
router.get('/over-budget', async (req, res) => {
    try {
        const now = new Date();
        const budgets = await Budget.find({
            userId: req.familyId,
            month: now.getMonth() + 1,
            year: now.getFullYear(),
            isActive: true,
            $expr: { $gte: ['$spentAmount', '$allocatedAmount'] }
        });
        res.json(budgets);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single budget
router.get('/:id', async (req, res) => {
    try {
        const budget = await Budget.findOne({ _id: req.params.id, userId: req.familyId });
        if (!budget) {
            return res.status(404).json({ error: 'Budget not found' });
        }
        res.json(budget);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create budget
router.post('/', async (req, res) => {
    try {
        const budget = new Budget({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await budget.save();
        res.status(201).json(budget);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update budget
router.put('/:id', async (req, res) => {
    try {
        const budget = await Budget.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!budget) {
            return res.status(404).json({ error: 'Budget not found' });
        }
        res.json(budget);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Add spending to budget
router.patch('/:id/spend', async (req, res) => {
    try {
        const { amount } = req.body;
        const budget = await Budget.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            { $inc: { spentAmount: amount } },
            { new: true }
        );
        if (!budget) {
            return res.status(404).json({ error: 'Budget not found' });
        }
        res.json(budget);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete budget
router.delete('/:id', async (req, res) => {
    try {
        const budget = await Budget.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!budget) {
            return res.status(404).json({ error: 'Budget not found' });
        }
        res.json({ message: 'Budget deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

