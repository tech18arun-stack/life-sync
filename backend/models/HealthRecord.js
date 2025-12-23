const mongoose = require('mongoose');

const healthRecordSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    memberName: {
        type: String,
        required: true,
        trim: true
    },
    recordType: {
        type: String,
        trim: true,
        default: 'Checkup'
    },
    date: {
        type: Date,
        default: Date.now
    },
    description: {
        type: String,
        trim: true
    },
    doctorName: {
        type: String,
        trim: true
    },
    medication: {
        type: String,
        trim: true
    },
    nextVisit: {
        type: Date
    }
}, {
    timestamps: true
});

healthRecordSchema.index({ userId: 1, date: -1 });
healthRecordSchema.index({ userId: 1, memberName: 1 });

module.exports = mongoose.model('HealthRecord', healthRecordSchema);
