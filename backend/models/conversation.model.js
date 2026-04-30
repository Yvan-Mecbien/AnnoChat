const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema(
  {
    // participants[0] = linkOwner, participants[1] = visitor
    linkOwner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    visitor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    lastMessage: {
      content: String,
      senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      timestamp: { type: Date, default: Date.now },
    },
    // unread count per participant
    unreadCount: {
      type: Map,
      of: Number,
      default: {},
    },
  },
  { timestamps: true }
);

// ─── Indexes ─────────────────────────────────────────────────────────────────
conversationSchema.index({ linkOwner: 1, visitor: 1 }, { unique: true });
conversationSchema.index({ linkOwner: 1, updatedAt: -1 });
conversationSchema.index({ visitor: 1, updatedAt: -1 });

// ─── Methods ─────────────────────────────────────────────────────────────────
/**
 * Returns display name for `currentUserId`:
 *  - if currentUser == linkOwner → visitor is "Anonyme"
 *  - if currentUser == visitor   → linkOwner's real username
 */
conversationSchema.methods.getDisplayName = function (currentUserId, populatedVisitor, populatedOwner) {
  const isOwner = this.linkOwner.toString() === currentUserId.toString();
  if (isOwner) {
    return 'Anonyme';
  }
  return populatedOwner ? populatedOwner.username : 'Unknown';
};

module.exports = mongoose.model('Conversation', conversationSchema);
