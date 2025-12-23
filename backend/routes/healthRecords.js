const express = require('express');
const router = express.Router();
const HealthRecord = require('../models/HealthRecord');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all health records
router.get('/', async (req, res) => {
    try {
        const { memberName, recordType } = req.query;
        const filter = { userId: req.familyId };

        if (memberName) filter.memberName = memberName;
        if (recordType) filter.recordType = recordType;

        const records = await HealthRecord.find(filter).sort({ date: -1 });
        res.json(records);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get upcoming visits
router.get('/upcoming-visits', async (req, res) => {
    try {
        const now = new Date();
        const records = await HealthRecord.find({
            userId: req.familyId,
            nextVisit: { $gte: now }
        }).sort({ nextVisit: 1 });
        res.json(records);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get records by member
router.get('/member/:memberName', async (req, res) => {
    try {
        const records = await HealthRecord.find({
            userId: req.familyId,
            memberName: req.params.memberName
        }).sort({ date: -1 });
        res.json(records);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single health record
router.get('/:id', async (req, res) => {
    try {
        const record = await HealthRecord.findOne({ _id: req.params.id, userId: req.familyId });
        if (!record) {
            return res.status(404).json({ error: 'Health record not found' });
        }
        res.json(record);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create health record
router.post('/', async (req, res) => {
    try {
        const record = new HealthRecord({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await record.save();
        res.status(201).json(record);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update health record
router.put('/:id', async (req, res) => {
    try {
        const record = await HealthRecord.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!record) {
            return res.status(404).json({ error: 'Health record not found' });
        }
        res.json(record);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete health record
router.delete('/:id', async (req, res) => {
    try {
        const record = await HealthRecord.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!record) {
            return res.status(404).json({ error: 'Health record not found' });
        }
        res.json({ message: 'Health record deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
