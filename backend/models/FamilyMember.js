const mongoose = require('mongoose');

const familyMemberSchema = new mongoose.Schema({
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
    relation: {
        type: String,
        trim: true
    },
    dateOfBirth: {
        type: Date
    },
    bloodGroup: {
        type: String,
        enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', null]
    },
    phone: {
        type: String,
        trim: true
    },
    email: {
        type: String,
        trim: true,
        lowercase: true
    },
    avatarColor: {
        type: String,
        default: '#6C63FF'
    },
    isEmergencyContact: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Index for faster user-specific queries
familyMemberSchema.index({ userId: 1 });

module.exports = mongoose.model('FamilyMember', familyMemberSchema);

