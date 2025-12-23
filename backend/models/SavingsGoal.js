const mongoose = require('mongoose');

const savingsGoalSchema = new mongoose.Schema({
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
    targetAmount: {
        type: Number,
        required: true,
        min: 0
    },
    currentAmount: {
        type: Number,
        default: 0,
        min: 0
    },
    targetDate: {
        type: Date
    },
    category: {
        type: String,
        trim: true,
        default: 'Other'
    },
    priority: {
        type: String,
        trim: true,
        default: 'Medium'
    },
    isCompleted: {
        type: Boolean,
        default: false
    },
    notes: {
        type: String,
        trim: true
    },
    color: {
        type: String,
        default: '#6C63FF'
    }
}, {
    timestamps: true
});

// Index for user-specific queries
savingsGoalSchema.index({ userId: 1 });

// Virtual for progress percentage
savingsGoalSchema.virtual('progress').get(function () {
    if (this.targetAmount === 0) return 0;
    return Math.min((this.currentAmount / this.targetAmount) * 100, 100);
});

module.exports = mongoose.model('SavingsGoal', savingsGoalSchema);

