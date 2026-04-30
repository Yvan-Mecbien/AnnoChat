const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, 'Username is required'],
      unique: true,
      trim: true,
      minlength: [3, 'Username must be at least 3 characters'],
      maxlength: [30, 'Username must be at most 30 characters'],
      match: [/^[a-zA-Z0-9_.-]+$/, 'Username may only contain letters, numbers, _, . or -'],
    },
    password_hash: {
      type: String,
      required: true,
      select: false, // Never returned by default
    },
    lastSeen: { type: Date, default: Date.now },
    isOnline: { type: Boolean, default: false },
  },
  { timestamps: true }
);


// ─── Virtuals ─────────────────────────────────────────────────────────────────
// Link unique à l'utilisateur
userSchema.virtual('chatLink').get(function () {
  return `${process.env.BASE_URL}/chat/${this._id}`;
});

// ─── Methods ─────────────────────────────────────────────────────────────────
userSchema.methods.comparePassword = async function (plain) {
  return bcrypt.compare(plain, this.password_hash);
};

userSchema.methods.toPublicJSON = function () {
  return {
    _id: this._id,
    username: this.username,
    chatLink: this.chatLink,
    lastSeen: this.lastSeen,
    isOnline: this.isOnline,
    createdAt: this.createdAt,
  };
};

// ─── Statics ─────────────────────────────────────────────────────────────────
userSchema.statics.hashPassword = async function (plain) {
  return bcrypt.hash(plain, 12);
};

module.exports = mongoose.model('User', userSchema);
