const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    category: {
        type: String,
        required: true,
        trim: true
    },
    allocatedAmount: {
        type: Number,
        required: true,
        min: 0
    },
    spentAmount: {
        type: Number,
        default: 0,
        min: 0
    },
    month: {
        type: Number,
        required: true,
        min: 1,
        max: 12
    },
    year: {
        type: Number,
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    alertThreshold: {
        type: Number,
        default: 80,
        min: 0,
        max: 100
    }
}, {
    timestamps: true
});

budgetSchema.index({ userId: 1, month: 1, year: 1 });
budgetSchema.index({ userId: 1, category: 1 });

module.exports = mongoose.model('Budget', budgetSchema);

