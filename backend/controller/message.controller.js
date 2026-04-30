const mongoose = require('mongoose');
const Message = require('../models/message.model');
const Conversation = require('../models/conversation.model');

/**
 * GET /api/messages/:conversationId?cursor=<lastMessageId>&limit=30
 * Cursor-based pagination (newest first).
 */
async function getMessages(req, res, next) {
  try {
    const userId = req.user._id;
    const { conversationId } = req.params;
    const { cursor, limit = 30 } = req.query;

    if (!mongoose.isValidObjectId(conversationId)) {
      return res.status(400).json({ error: 'Invalid conversationId' });
    }

    // Verify user belongs to this conversation
    const conv = await Conversation.findOne({
      _id: conversationId,
      $or: [{ linkOwner: userId }, { visitor: userId }],
    });
    if (!conv) return res.status(403).json({ error: 'Access denied' });

    const query = { conversationId };
    if (cursor && mongoose.isValidObjectId(cursor)) {
      query._id = { $lt: new mongoose.Types.ObjectId(cursor) };
    }

    const messages = await Message.find(query)
      .sort({ _id: -1 })
      .limit(Math.min(Number(limit), 50))
      .lean();

    const isOwner = conv.linkOwner.toString() === userId.toString();

    // Apply anonymity: if owner, hide visitor senderId
    const sanitized = messages.map((msg) => {
      const senderIsVisitor = msg.senderId.toString() === conv.visitor.toString();
      return {
        ...msg,
        senderDisplay: isOwner && senderIsVisitor ? 'Anonyme' : undefined,
        // Don't expose raw senderId to owner if sender is visitor
        senderId: isOwner && senderIsVisitor ? null : msg.senderId,
        isMine: msg.senderId.toString() === userId.toString(),
      };
    });

    res.json({
      messages: sanitized.reverse(), // chronological order
      nextCursor: messages.length === Number(limit) ? messages[messages.length - 1]._id : null,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/messages
 * Send a message via REST (fallback; Socket.IO is preferred for real-time).
 */
async function sendMessage(req, res, next) {
  try {
    const userId = req.user._id;
    const { conversationId, content } = req.body;

    if (!conversationId || !content?.trim()) {
      return res.status(400).json({ error: 'conversationId and content required' });
    }

    const conv = await Conversation.findOne({
      _id: conversationId,
      $or: [{ linkOwner: userId }, { visitor: userId }],
    });
    if (!conv) return res.status(403).json({ error: 'Access denied' });

    const msg = await Message.create({
      conversationId,
      senderId: userId,
      content: content.trim(),
    });

    // Update conversation meta
    const otherId =
      conv.linkOwner.toString() === userId.toString()
        ? conv.visitor.toString()
        : conv.linkOwner.toString();

    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: { content: msg.content, senderId: userId, timestamp: msg.createdAt },
      $inc: { [`unreadCount.${otherId}`]: 1 },
    });

    res.status(201).json({ message: msg });
  } catch (err) {
    next(err);
  }
}

module.exports = { getMessages, sendMessage };
