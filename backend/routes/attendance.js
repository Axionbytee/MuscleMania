import { Router } from 'express';
import AttendanceLog from '../models/AttendanceLog.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = Router();

/**
 * GET /api/attendance
 * Return attendance logs joined with member fullName.
 * Query params: ?memberId=, ?date=YYYY-MM-DD, ?limit=50
 */
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { memberId, date, limit } = req.query;
    const filter = {};

    if (memberId) {
      filter.memberId = memberId;
    }

    if (date) {
      const start = new Date(`${date}T00:00:00.000Z`);
      const end = new Date(`${date}T23:59:59.999Z`);
      filter.scannedAt = { $gte: start, $lte: end };
    }

    const maxResults = Math.min(parseInt(limit, 10) || 50, 500);

    const logs = await AttendanceLog.find(filter)
      .populate('memberId', 'fullName photoUrl')
      .sort({ scannedAt: -1 })
      .limit(maxResults)
      .lean();

    const result = logs.map((log) => ({
      _id: log._id,
      memberName: log.memberId ? log.memberId.fullName : 'Unknown',
      memberPhoto: log.memberId ? log.memberId.photoUrl : '',
      scannedAt: log.scannedAt,
      entryType: log.entryType
    }));

    return res.json(result);
  } catch (err) {
    console.error('[ATTENDANCE] GET error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
