const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
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
    description: {
        type: String,
        trim: true
    },
    dueDate: {
        type: Date
    },
    priority: {
        type: String,
        trim: true,
        default: 'Medium'
    },
    status: {
        type: String,
        trim: true,
        default: 'Pending'
    },
    isCompleted: {
        type: Boolean,
        default: false
    },
    completedAt: {
        type: Date
    },
    assignedTo: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'FamilyMember'
    },
    category: {
        type: String,
        trim: true,
        default: 'Other'
    }
}, {
    timestamps: true
});

taskSchema.index({ userId: 1, dueDate: 1 });
taskSchema.index({ userId: 1, isCompleted: 1 });
taskSchema.index({ userId: 1, priority: 1 });

module.exports = mongoose.model('Task', taskSchema);

