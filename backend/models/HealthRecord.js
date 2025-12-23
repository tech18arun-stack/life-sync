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
        default: 'Checkup',
        enum: ['Checkup', 'Vaccination', 'Medication', 'Lab Test', 'Vitals', 'Surgery', 'Allergy', 'Insurance', 'Other']
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
    hospitalName: {
        type: String,
        trim: true
    },
    medication: {
        type: String,
        trim: true
    },
    dosage: {
        type: String,
        trim: true
    },
    frequency: {
        type: String,
        trim: true
    },
    nextVisit: {
        type: Date
    },
    // Vitals Tracking
    vitals: {
        bloodPressureSystolic: Number,
        bloodPressureDiastolic: Number,
        heartRate: Number,
        temperature: Number,
        weight: Number,
        height: Number,
        bmi: Number,
        bloodSugar: Number,
        oxygenLevel: Number
    },
    // Lab Results
    labResults: {
        testName: String,
        result: String,
        normalRange: String,
        unit: String
    },
    // Allergy Information
    allergy: {
        allergen: String,
        severity: {
            type: String,
            enum: ['Mild', 'Moderate', 'Severe']
        },
        reactions: String,
        treatment: String
    },
    // Insurance Details
    insurance: {
        policyNumber: String,
        provider: String,
        validUntil: Date,
        coverageAmount: Number,
        policyType: String
    },
    // Blood Type
    bloodType: {
        type: String,
        enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', null]
    },
    // Vaccination specific
    vaccineDose: String,
    vaccineManufacturer: String,
    batchNumber: String,
    // Attachments/Documents
    attachments: [{
        fileName: String,
        fileUrl: String,
        fileType: String
    }],
    // Notes
    notes: {
        type: String,
        trim: true
    },
    // Status for medications
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

healthRecordSchema.index({ userId: 1, date: -1 });
healthRecordSchema.index({ userId: 1, memberName: 1 });
healthRecordSchema.index({ userId: 1, recordType: 1 });

module.exports = mongoose.model('HealthRecord', healthRecordSchema);

