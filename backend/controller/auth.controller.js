const Joi = require('joi');
const User = require('../models/user.model');
const { signAccess, signRefresh, verifyRefresh } = require('../utils/jwt');

// ─── Validators ──────────────────────────────────────────────────────────────
const registerSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).required(),
  password: Joi.string().min(6).max(128).required(),
});

const loginSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
});

// ─── Helpers ─────────────────────────────────────────────────────────────────
function makeTokens(userId) {
  const payload = { userId: userId.toString() };
  return {
    accessToken: signAccess(payload),
    refreshToken: signRefresh(payload),
  };
}

// ─── Handlers ────────────────────────────────────────────────────────────────
async function register(req, res, next) {
  try {
    console.log(req.body);
    const { error, value } = registerSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { username, password } = value;
    const password_hash = await User.hashPassword(password);

    const user = await User.create({ username, password_hash });
    const tokens = makeTokens(user._id);

    res.status(201).json({
      user: user.toPublicJSON(),
      ...tokens,
    });
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { username, password } = value;

    const user = await User.findOne({ username }).select('+password_hash');
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const valid = await user.comparePassword(password);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

    // Update last seen
    user.lastSeen = new Date();
    await user.save();

    const tokens = makeTokens(user._id);
    res.json({ user: user.toPublicJSON(), ...tokens });
  } catch (err) {
    next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'refreshToken required' });

    const decoded = verifyRefresh(refreshToken);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(401).json({ error: 'User not found' });

    const tokens = makeTokens(user._id);
    res.json(tokens);
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Refresh token expired' });
    }
    next(err);
  }
}

async function getMe(req, res) {
  res.json({ user: req.user.toPublicJSON() });
}

module.exports = { register, login, refresh, getMe };
