const express = require('express');
const router = express.Router();
const Task = require('../models/Task');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all tasks with filters
router.get('/', async (req, res) => {
    try {
        const { status, priority, isCompleted, category } = req.query;
        const filter = { userId: req.familyId };

        if (status) filter.status = status;
        if (priority) filter.priority = priority;
        if (isCompleted !== undefined) filter.isCompleted = isCompleted === 'true';
        if (category) filter.category = category;

        const tasks = await Task.find(filter)
            .sort({ dueDate: 1, priority: -1 })
            .populate('assignedTo', 'name');
        res.json(tasks);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get today's tasks
router.get('/today', async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const tasks = await Task.find({
            userId: req.familyId,
            dueDate: { $gte: today, $lt: tomorrow },
            isCompleted: false
        }).sort({ priority: -1 }).populate('assignedTo', 'name');

        res.json(tasks);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get overdue tasks
router.get('/overdue', async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const tasks = await Task.find({
            userId: req.familyId,
            dueDate: { $lt: today },
            isCompleted: false
        }).sort({ dueDate: 1 }).populate('assignedTo', 'name');

        res.json(tasks);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single task
router.get('/:id', async (req, res) => {
    try {
        const task = await Task.findOne({ _id: req.params.id, userId: req.familyId }).populate('assignedTo', 'name');
        if (!task) {
            return res.status(404).json({ error: 'Task not found' });
        }
        res.json(task);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create task
router.post('/', async (req, res) => {
    try {
        const task = new Task({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await task.save();
        res.status(201).json(task);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update task
router.put('/:id', async (req, res) => {
    try {
        const task = await Task.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!task) {
            return res.status(404).json({ error: 'Task not found' });
        }
        res.json(task);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Mark task as complete
router.patch('/:id/complete', async (req, res) => {
    try {
        const task = await Task.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            { isCompleted: true, completedAt: new Date(), status: 'Completed' },
            { new: true }
        );
        if (!task) {
            return res.status(404).json({ error: 'Task not found' });
        }
        res.json(task);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete task
router.delete('/:id', async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!task) {
            return res.status(404).json({ error: 'Task not found' });
        }
        res.json({ message: 'Task deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

