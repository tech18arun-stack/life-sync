const express = require('express');
const router = express.Router();
const SavingsGoal = require('../models/SavingsGoal');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all savings goals
router.get('/', async (req, res) => {
    try {
        const { category, isCompleted, priority } = req.query;
        const filter = { userId: req.familyId };

        if (category) filter.category = category;
        if (isCompleted !== undefined) filter.isCompleted = isCompleted === 'true';
        if (priority) filter.priority = priority;

        const goals = await SavingsGoal.find(filter).sort({ targetDate: 1 });
        res.json(goals);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get active goals summary
router.get('/summary', async (req, res) => {
    try {
        const goals = await SavingsGoal.find({ userId: req.familyId, isCompleted: false });
        const totalTarget = goals.reduce((sum, g) => sum + g.targetAmount, 0);
        const totalSaved = goals.reduce((sum, g) => sum + g.currentAmount, 0);
        const overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

        res.json({
            activeGoals: goals.length,
            totalTarget,
            totalSaved,
            overallProgress: Math.round(overallProgress * 100) / 100
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single savings goal
router.get('/:id', async (req, res) => {
    try {
        const goal = await SavingsGoal.findOne({ _id: req.params.id, userId: req.familyId });
        if (!goal) {
            return res.status(404).json({ error: 'Savings goal not found' });
        }
        res.json(goal);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create savings goal
router.post('/', async (req, res) => {
    try {
        const goal = new SavingsGoal({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await goal.save();
        res.status(201).json(goal);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update savings goal
router.put('/:id', async (req, res) => {
    try {
        const goal = await SavingsGoal.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!goal) {
            return res.status(404).json({ error: 'Savings goal not found' });
        }
        res.json(goal);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Add contribution to savings goal
router.patch('/:id/contribute', async (req, res) => {
    try {
        const { amount } = req.body;
        const goal = await SavingsGoal.findOne({ _id: req.params.id, userId: req.familyId });

        if (!goal) {
            return res.status(404).json({ error: 'Savings goal not found' });
        }

        goal.currentAmount += amount;

        // Check if goal is completed
        if (goal.currentAmount >= goal.targetAmount) {
            goal.isCompleted = true;
        }

        await goal.save();
        res.json(goal);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete savings goal
router.delete('/:id', async (req, res) => {
    try {
        const goal = await SavingsGoal.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!goal) {
            return res.status(404).json({ error: 'Savings goal not found' });
        }
        res.json({ message: 'Savings goal deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

