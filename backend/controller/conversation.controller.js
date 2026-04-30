const mongoose = require('mongoose');
const Conversation = require('../models/conversation.model');
const User = require('../models/user.model');

/**
 * GET /api/conversations
 * List all conversations for the logged-in user.
 * Applies asymmetric anonymity: returns display name per conversation.
 */
async function listConversations(req, res, next) {
  try {
    const userId = req.user._id;

    const conversations = await Conversation.find({
      $or: [{ linkOwner: userId }, { visitor: userId }],
    })
      .populate('linkOwner', 'username isOnline lastSeen')
      .populate('visitor', 'username isOnline lastSeen')
      .sort({ updatedAt: -1 })
      .lean();

    const result = conversations.map((conv) => {
      const isOwner = conv.linkOwner._id.toString() === userId.toString();

      // Asymmetric anonymity
      const otherUser = isOwner ? conv.visitor : conv.linkOwner;
      const displayName = isOwner ? 'Anonyme' : conv.linkOwner.username;

      return {
        _id: conv._id,
        displayName,
        otherUserId: isOwner ? null : otherUser._id, // owner never sees visitor id
        isOnline: isOwner ? false : otherUser.isOnline,
        lastMessage: conv.lastMessage,
        unreadCount: conv.unreadCount?.[userId.toString()] || 0,
        updatedAt: conv.updatedAt,
      };
    });

    res.json({ conversations: result });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/conversations/find-or-create
 * Called when visitor opens linkOwner's link.
 * Body: { linkOwnerId }
 */
async function findOrCreate(req, res, next) {
  try {
    const visitorId = req.user._id;
    const { linkOwnerId } = req.body;

    if (!linkOwnerId) return res.status(400).json({ error: 'linkOwnerId required' });
    if (!mongoose.isValidObjectId(linkOwnerId)) {
      return res.status(400).json({ error: 'Invalid linkOwnerId' });
    }
    if (visitorId.toString() === linkOwnerId) {
      return res.status(400).json({ error: 'Cannot chat with yourself' });
    }

    const owner = await User.findById(linkOwnerId);
    if (!owner) return res.status(404).json({ error: 'User not found' });

    // Find existing or create
    let conv = await Conversation.findOne({
      linkOwner: linkOwnerId,
      visitor: visitorId,
    });

    if (!conv) {
      conv = await Conversation.create({
        linkOwner: linkOwnerId,
        visitor: visitorId,
        unreadCount: { [linkOwnerId]: 0, [visitorId.toString()]: 0 },
      });
    }

    res.json({
      conversationId: conv._id,
      ownerUsername: owner.username, // Visitor can see owner's username
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/conversations/:id/read
 * Mark conversation as read for current user.
 */
async function markRead(req, res, next) {
  try {
    const userId = req.user._id.toString();
    const { id } = req.params;

    await Conversation.findByIdAndUpdate(id, {
      $set: { [`unreadCount.${userId}`]: 0 },
    });

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
}

module.exports = { listConversations, findOrCreate, markRead };
