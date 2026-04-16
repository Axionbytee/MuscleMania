import { Router } from 'express';
import Member from '../models/Member.js';
import RfidCard from '../models/RfidCard.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = Router();

/**
 * GET /api/members
 * List all members joined with their RFID card UID.
 */
router.get('/', authMiddleware, async (req, res) => {
  try {
    const members = await Member.find().sort({ createdAt: -1 }).lean();

    // Attach RFID UID to each member
    const memberIds = members.map((m) => m._id);
    const cards = await RfidCard.find({ memberId: { $in: memberIds } }).lean();
    const cardMap = {};
    for (const card of cards) {
      cardMap[card.memberId.toString()] = card;
    }

    const result = members.map((m) => {
      const card = cardMap[m._id.toString()];
      return {
        ...m,
        rfidUid: card ? card.uid : null,
        rfidActive: card ? card.isActive : false
      };
    });

    return res.json(result);
  } catch (err) {
    console.error('[MEMBERS] GET error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/members
 * Create a new member and optionally assign an RFID UID.
 * Body: { fullName, email?, phone?, photoUrl?, issueDate, expirationDate, membershipType?, rfidUid? }
 */
router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      fullName,
      email,
      phone,
      photoUrl,
      issueDate,
      expirationDate,
      membershipType,
      rfidUid
    } = req.body;

    if (!fullName || !issueDate || !expirationDate) {
      return res.status(400).json({ error: 'fullName, issueDate, and expirationDate are required' });
    }

    const member = await Member.create({
      fullName,
      email: email || '',
      phone: phone || '',
      photoUrl: photoUrl || '',
      issueDate: new Date(issueDate),
      expirationDate: new Date(expirationDate),
      membershipType: membershipType || 'monthly'
    });

    // Optionally assign RFID card
    let card = null;
    if (rfidUid) {
      const existingCard = await RfidCard.findOne({ uid: rfidUid });
      if (existingCard) {
        return res.status(409).json({ error: `RFID UID "${rfidUid}" is already assigned` });
      }
      card = await RfidCard.create({ uid: rfidUid, memberId: member._id });
    }

    return res.status(201).json({
      ...member.toObject(),
      rfidUid: card ? card.uid : null
    });
  } catch (err) {
    console.error('[MEMBERS] POST error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/members/:id
 * Update member fields including renewal (expirationDate).
 */
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const updates = {};
    const allowedFields = [
      'fullName', 'email', 'phone', 'photoUrl',
      'issueDate', 'expirationDate', 'membershipType'
    ];

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = field.includes('Date')
          ? new Date(req.body[field])
          : req.body[field];
      }
    }

    const member = await Member.findByIdAndUpdate(id, updates, { new: true });

    if (!member) {
      return res.status(404).json({ error: 'Member not found' });
    }

    // Update RFID if provided
    if (req.body.rfidUid !== undefined) {
      await RfidCard.findOneAndUpdate(
        { memberId: member._id },
        { uid: req.body.rfidUid, memberId: member._id, isActive: true },
        { upsert: true, new: true }
      );
    }

    return res.json(member);
  } catch (err) {
    console.error('[MEMBERS] PUT error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/members/:id
 * Hard delete a member and their associated RFID card.
 */
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const member = await Member.findByIdAndDelete(id);

    if (!member) {
      return res.status(404).json({ error: 'Member not found' });
    }

    // Remove associated RFID cards
    await RfidCard.deleteMany({ memberId: id });

    return res.json({ success: true, deleted: member.fullName });
  } catch (err) {
    console.error('[MEMBERS] DELETE error:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
