const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    title: {
        type: String,
        required: true,
        trim: true
    },
    type: {
        type: String,
        trim: true,
        default: 'Bill'
    },
    dueDate: {
        type: Date,
        required: true
    },
    amount: {
        type: Number,
        min: 0
    },
    description: {
        type: String,
        trim: true
    },
    isRecurring: {
        type: Boolean,
        default: false
    },
    recurringType: {
        type: String,
        trim: true
    },
    notificationEnabled: {
        type: Boolean,
        default: true
    },
    notificationDaysBefore: {
        type: Number,
        default: 1
    },
    isPaid: {
        type: Boolean,
        default: false
    },
    paidDate: {
        type: Date
    }
}, {
    timestamps: true
});

reminderSchema.index({ userId: 1, dueDate: 1 });
reminderSchema.index({ userId: 1, isPaid: 1 });

module.exports = mongoose.model('Reminder', reminderSchema);
