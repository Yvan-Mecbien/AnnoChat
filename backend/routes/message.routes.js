const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { getMessages, sendMessage } = require('../controller/message.controller');

router.get('/:conversationId', authenticate, getMessages);
router.post('/', authenticate, sendMessage);

module.exports = router;
