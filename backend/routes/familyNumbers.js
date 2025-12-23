const express = require('express');
const router = express.Router();
const FamilyNumber = require('../models/FamilyNumber');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all family numbers
router.get('/', async (req, res) => {
    try {
        const { category, isEmergency } = req.query;
        const filter = { userId: req.familyId };

        if (category) filter.category = category;
        if (isEmergency !== undefined) filter.isEmergency = isEmergency === 'true';

        const numbers = await FamilyNumber.find(filter).sort({ isPrimary: -1, name: 1 });
        res.json(numbers);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get emergency contacts only
router.get('/emergency', async (req, res) => {
    try {
        const numbers = await FamilyNumber.find({ userId: req.familyId, isEmergency: true }).sort({ name: 1 });
        res.json(numbers);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get numbers by category
router.get('/category/:category', async (req, res) => {
    try {
        const numbers = await FamilyNumber.find({ userId: req.familyId, category: req.params.category }).sort({ name: 1 });
        res.json(numbers);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single family number
router.get('/:id', async (req, res) => {
    try {
        const number = await FamilyNumber.findOne({ _id: req.params.id, userId: req.familyId });
        if (!number) {
            return res.status(404).json({ error: 'Family number not found' });
        }
        res.json(number);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create family number
router.post('/', async (req, res) => {
    try {
        const number = new FamilyNumber({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await number.save();
        res.status(201).json(number);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update family number
router.put('/:id', async (req, res) => {
    try {
        const number = await FamilyNumber.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!number) {
            return res.status(404).json({ error: 'Family number not found' });
        }
        res.json(number);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete family number
router.delete('/:id', async (req, res) => {
    try {
        const number = await FamilyNumber.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!number) {
            return res.status(404).json({ error: 'Family number not found' });
        }
        res.json({ message: 'Family number deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Bulk add family numbers
router.post('/bulk', async (req, res) => {
    try {
        const numbersWithUserId = req.body.map(num => ({ ...num, userId: req.familyId, createdBy: req.userId }));
        const numbers = await FamilyNumber.insertMany(numbersWithUserId);
        res.status(201).json(numbers);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

module.exports = router;

