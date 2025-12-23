const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { generateToken, authMiddleware } = require('../middleware/auth');

// Register new user
router.post('/register', async (req, res) => {
    try {
        const { name, email, password, phone } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Create new user
        const user = new User({
            name,
            email,
            password,
            phone
        });

        await user.save();

        // Generate token
        const token = generateToken(user._id);

        res.status(201).json({
            message: 'Registration successful',
            user: user.toJSON(),
            token
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Login user
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user by email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Update last login
        user.lastLogin = new Date();
        await user.save();

        // Generate token
        const token = generateToken(user._id);

        res.json({
            message: 'Login successful',
            user: user.toJSON(),
            token
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get current user profile
router.get('/me', authMiddleware, async (req, res) => {
    try {
        res.json(req.user);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update user profile
router.put('/me', authMiddleware, async (req, res) => {
    try {
        const { name, phone, avatar } = req.body;

        const user = await User.findByIdAndUpdate(
            req.userId,
            { name, phone, avatar },
            { new: true, runValidators: true }
        );

        res.json(user);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Change password
router.put('/change-password', authMiddleware, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        const user = await User.findById(req.userId);

        // Verify current password
        const isMatch = await user.comparePassword(currentPassword);
        if (!isMatch) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }

        // Update password
        user.password = newPassword;
        await user.save();

        res.json({ message: 'Password changed successfully' });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Logout (optional - for token blacklisting in future)
router.post('/logout', authMiddleware, async (req, res) => {
    try {
        // In a production app, you might want to blacklist the token
        res.json({ message: 'Logged out successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ===== FAMILY MEMBER USER MANAGEMENT =====

// Create family member user (child user with login credentials)
router.post('/family-members', authMiddleware, async (req, res) => {
    try {
        const { name, email, password, phone, relation } = req.body;

        // Only owners can create family members (or members of an existing family)
        const currentUser = req.user;
        const familyId = currentUser.familyId || currentUser._id;

        // Check if email already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Create family member user
        const familyMember = new User({
            name,
            email,
            password,
            phone,
            role: 'member',
            parentUserId: currentUser._id,
            familyId: familyId,
            relation
        });

        await familyMember.save();

        // If current user is owner and doesn't have familyId set, set it to their own ID
        if (currentUser.role === 'owner' && !currentUser.familyId) {
            await User.findByIdAndUpdate(currentUser._id, { familyId: currentUser._id });
        }

        res.status(201).json({
            message: 'Family member account created successfully',
            familyMember: familyMember.toJSON()
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Get all family members (users in the same family)
router.get('/family-members', authMiddleware, async (req, res) => {
    try {
        const currentUser = req.user;
        const familyId = currentUser.familyId || currentUser._id;

        // Get all users in the family (excluding current user)
        const familyMembers = await User.find({
            $or: [
                { familyId: familyId },
                { _id: familyId }
            ],
            _id: { $ne: currentUser._id }
        }).sort({ createdAt: -1 });

        res.json(familyMembers.map(member => member.toJSON()));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update family member
router.put('/family-members/:id', authMiddleware, async (req, res) => {
    try {
        const { name, phone, relation, isActive } = req.body;
        const memberId = req.params.id;

        const currentUser = req.user;
        const familyId = currentUser.familyId || currentUser._id;

        // Find the family member
        const member = await User.findById(memberId);
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }

        // Check if member belongs to same family
        if (member.familyId?.toString() !== familyId.toString() && member._id.toString() !== familyId.toString()) {
            return res.status(403).json({ error: 'Not authorized to update this user' });
        }

        const updatedMember = await User.findByIdAndUpdate(
            memberId,
            { name, phone, relation, isActive },
            { new: true, runValidators: true }
        );

        res.json(updatedMember.toJSON());
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete family member
router.delete('/family-members/:id', authMiddleware, async (req, res) => {
    try {
        const memberId = req.params.id;
        const currentUser = req.user;
        const familyId = currentUser.familyId || currentUser._id;

        // Find the family member
        const member = await User.findById(memberId);
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }

        // Check if member belongs to same family
        if (member.familyId?.toString() !== familyId.toString()) {
            return res.status(403).json({ error: 'Not authorized to delete this user' });
        }

        // Cannot delete an owner
        if (member.role === 'owner') {
            return res.status(403).json({ error: 'Cannot delete family owner account' });
        }

        await User.findByIdAndDelete(memberId);

        res.json({ message: 'Family member deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Reset family member password (by owner/parent)
router.put('/family-members/:id/reset-password', authMiddleware, async (req, res) => {
    try {
        const { newPassword } = req.body;
        const memberId = req.params.id;
        const currentUser = req.user;
        const familyId = currentUser.familyId || currentUser._id;

        // Find the family member
        const member = await User.findById(memberId);
        if (!member) {
            return res.status(404).json({ error: 'Family member not found' });
        }

        // Check if member belongs to same family
        if (member.familyId?.toString() !== familyId.toString()) {
            return res.status(403).json({ error: 'Not authorized to update this user' });
        }

        // Update password
        member.password = newPassword;
        await member.save();

        res.json({ message: 'Password reset successfully' });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

module.exports = router;
