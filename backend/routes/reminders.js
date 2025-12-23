const express = require('express');
const router = express.Router();
const Reminder = require('../models/Reminder');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all reminders
router.get('/', async (req, res) => {
    try {
        const { isPaid, type } = req.query;
        const filter = { userId: req.familyId };

        if (isPaid !== undefined) filter.isPaid = isPaid === 'true';
        if (type) filter.type = type;

        const reminders = await Reminder.find(filter).sort({ dueDate: 1 });
        res.json(reminders);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get pending reminders
router.get('/pending', async (req, res) => {
    try {
        const reminders = await Reminder.find({
            userId: req.familyId,
            isPaid: false
        }).sort({ dueDate: 1 });
        res.json(reminders);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get overdue reminders
router.get('/overdue', async (req, res) => {
    try {
        const now = new Date();
        const reminders = await Reminder.find({
            userId: req.familyId,
            isPaid: false,
            dueDate: { $lt: now }
        }).sort({ dueDate: 1 });
        res.json(reminders);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single reminder
router.get('/:id', async (req, res) => {
    try {
        const reminder = await Reminder.findOne({ _id: req.params.id, userId: req.familyId });
        if (!reminder) {
            return res.status(404).json({ error: 'Reminder not found' });
        }
        res.json(reminder);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create reminder
router.post('/', async (req, res) => {
    try {
        const reminder = new Reminder({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await reminder.save();
        res.status(201).json(reminder);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update reminder
router.put('/:id', async (req, res) => {
    try {
        const reminder = await Reminder.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!reminder) {
            return res.status(404).json({ error: 'Reminder not found' });
        }
        res.json(reminder);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Mark reminder as paid
router.patch('/:id/pay', async (req, res) => {
    try {
        const reminder = await Reminder.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            { isPaid: true, paidDate: new Date() },
            { new: true }
        );
        if (!reminder) {
            return res.status(404).json({ error: 'Reminder not found' });
        }
        res.json(reminder);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete reminder
router.delete('/:id', async (req, res) => {
    try {
        const reminder = await Reminder.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!reminder) {
            return res.status(404).json({ error: 'Reminder not found' });
        }
        res.json({ message: 'Reminder deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
