import mongoose from 'mongoose';

const attendanceLogSchema = new mongoose.Schema({
  memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
  scannedAt: { type: Date, default: Date.now },
  entryType: { type: String, default: 'entry' }
});

export default mongoose.models.AttendanceLog || mongoose.model('AttendanceLog', attendanceLogSchema);
