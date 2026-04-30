const router = require('express').Router();
const { register, login, refresh, getMe } = require('../controller/auth.controller');
const { authenticate } = require('../middlewares/auth.middleware');

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refresh);
router.get('/me', authenticate, getMe);

module.exports = router;
