import mongoose from 'mongoose';

const rfidCardSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
  assignedAt: { type: Date, default: Date.now },
  isActive: { type: Boolean, default: true }
});

export default mongoose.models.RfidCard || mongoose.model('RfidCard', rfidCardSchema);
