import { Router } from 'express';
import RfidCard from '../models/RfidCard.js';
import Member from '../models/Member.js';
import AttendanceLog from '../models/AttendanceLog.js';

const router = Router();

// Capture mode state — used for "Scan Now" in the admin member form
let captureMode = { active: false, uid: null, timestamp: null };

/**
 * POST /api/scan
 * Core scan endpoint — validates RFID UID, computes membership status,
 * logs attendance, and emits result via Socket.io.
 */
router.post('/', async (req, res) => {
  try {
    const { uid } = req.body;

    if (!uid || typeof uid !== 'string') {
      return res.status(400).json({ error: 'uid is required' });
    }

    // Capture mode: intercept scan for admin form instead of normal processing
    if (captureMode.active) {
      captureMode.uid = uid.trim();
      captureMode.active = false;
      return res.json({ captured: true });
    }

    // 1. Look up RFID card by UID
    const card = await RfidCard.findOne({ uid: uid.trim(), isActive: true });

    if (!card) {
      const unknownPayload = { status: 'UNKNOWN', member: null };
      req.app.get('io').emit('scan_result', unknownPayload);
      return res.status(404).json(unknownPayload);
    }

    // 2. Find linked member
    const member = await Member.findById(card.memberId);

    if (!member) {
      const unknownPayload = { status: 'UNKNOWN', member: null };
      req.app.get('io').emit('scan_result', unknownPayload);
      return res.status(404).json(unknownPayload);
    }

    // 3. Compute today's date in Asia/Manila timezone (UTC+8)
    const nowUTC = new Date();
    const manilaOffset = 8 * 60 * 60 * 1000;
    const manilaDate = new Date(nowUTC.getTime() + manilaOffset);
    const todayManila = new Date(
      manilaDate.getUTCFullYear(),
      manilaDate.getUTCMonth(),
      manilaDate.getUTCDate()
    );

    // 4. Compute difference in days
    const expiryDate = new Date(
      member.expirationDate.getUTCFullYear(),
      member.expirationDate.getUTCMonth(),
      member.expirationDate.getUTCDate()
    );
    const diffMs = expiryDate.getTime() - todayManila.getTime();
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    // 5. Determine status
    let status;
    if (diffDays < 0) {
      status = 'EXPIRED';
    } else if (diffDays <= 7) {
      status = 'EXPIRING_SOON';
    } else {
      status = 'ACTIVE';
    }

    // 6. Log attendance for active/expiring members
    if (status !== 'EXPIRED') {
      await AttendanceLog.create({ memberId: member._id });
    }

    // 7. Build and emit payload
    const payload = {
      status,
      member: {
        fullName: member.fullName,
        photoUrl: member.photoUrl,
        issueDate: member.issueDate,
        expirationDate: member.expirationDate,
        remainingDays: Math.max(diffDays, 0)
      }
    };

    req.app.get('io').emit('scan_result', payload);
    return res.json(payload);
  } catch (err) {
    console.error('[SCAN] Error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
