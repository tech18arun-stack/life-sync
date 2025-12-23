const express = require('express');
const router = express.Router();
const FamilyMember = require('../models/FamilyMember');
const { authMiddleware } = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get all family members for current user
router.get('/', async (req, res) => {
    try {
        const members = await FamilyMember.find({ userId: req.familyId }).sort({ createdAt: -1 });
        res.json(members);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get single family member
router.get('/:id', async (req, res) => {
    try {
        const member = await FamilyMember.findOne({ _id: req.params.id, userId: req.familyId });
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }
        res.json(member);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create family member
router.post('/', async (req, res) => {
    try {
        const member = new FamilyMember({
            ...req.body,
            userId: req.familyId,
            createdBy: req.userId
        });
        await member.save();
        res.status(201).json(member);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update family member
router.put('/:id', async (req, res) => {
    try {
        const member = await FamilyMember.findOneAndUpdate(
            { _id: req.params.id, userId: req.familyId },
            req.body,
            { new: true, runValidators: true }
        );
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }
        res.json(member);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete family member
router.delete('/:id', async (req, res) => {
    try {
        const member = await FamilyMember.findOneAndDelete({ _id: req.params.id, userId: req.familyId });
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }
        res.json({ message: 'Family member deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;

