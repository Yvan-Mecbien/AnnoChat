const router = require('express').Router();
const User = require('../models/user.model');
const { authenticate } = require('../middlewares/auth.middleware');

// GET /api/users/:id – public profile (used by visitor to get owner's username)
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id).select('username isOnline lastSeen createdAt');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
