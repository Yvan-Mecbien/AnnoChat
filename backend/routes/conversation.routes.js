// conversation.routes.js
const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { listConversations, findOrCreate, markRead } = require('../controller/conversation.controller');

router.get('/', authenticate, listConversations);
router.post('/find-or-create', authenticate, findOrCreate);
router.post('/:id/read', authenticate, markRead);

module.exports = router;
