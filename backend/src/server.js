require('dotenv').config();
const http = require('http');
const app = require('../app');
const { connectDB } = require('../config/database');
const { initSocket } = require('../index');
const logger = require('../utils/logger');

const PORT = process.env.PORT || 5000;

async function bootstrap() {

    console.log(process.env.MONGODB_URI);
  console.log(process.env.DATABASE_URL);
  
  // 1. Connect to MongoDB
  await connectDB();

  // 2. Create HTTP server
  const server = http.createServer(app);

  // 3. Init Socket.IO
  initSocket(server);

  // 4. Start listening
  server.listen(PORT, () => {
    logger.info(`Server running on port ${PORT} [${process.env.NODE_ENV}]`);
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    logger.info('SIGTERM received – shutting down gracefully');
    server.close(() => process.exit(0));
  });
}

bootstrap().catch((err) => {
  logger.error('Bootstrap error:', err);
  process.exit(1);
});
