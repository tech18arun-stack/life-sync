const mongoose = require('mongoose');

const familyNumberSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        required: true,
        trim: true
    },
    relation: {
        type: String,
        trim: true,
        default: 'Other'
    },
    category: {
        type: String,
        trim: true,
        default: 'Family'
    },
    isEmergency: {
        type: Boolean,
        default: false
    },
    isPrimary: {
        type: Boolean,
        default: false
    },
    notes: {
        type: String,
        trim: true
    },
    avatarColor: {
        type: String,
        default: '#6C63FF'
    }
}, {
    timestamps: true
});

// Index for faster queries
familyNumberSchema.index({ userId: 1, category: 1 });
familyNumberSchema.index({ userId: 1, isEmergency: 1 });

module.exports = mongoose.model('FamilyNumber', familyNumberSchema);

