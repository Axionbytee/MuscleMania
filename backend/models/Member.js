import mongoose from 'mongoose';

const memberSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, default: '' },
  phone: { type: String, default: '' },
  photoUrl: { type: String, default: '' },
  issueDate: { type: Date, required: true },
  expirationDate: { type: Date, required: true },
  membershipType: {
    type: String,
    enum: ['monthly', 'quarterly', 'annual'],
    default: 'monthly'
  }
}, { timestamps: true });

export default mongoose.models.Member || mongoose.model('Member', memberSchema);
