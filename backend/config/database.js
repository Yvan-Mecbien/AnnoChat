const mongoose = require('mongoose');
const logger = require('../utils/logger');

const OPTS = {
  maxPoolSize: 20,
  serverSelectionTimeoutMS: 20000,
  socketTimeoutMS: 0,
  family: 4,
  keepAliveInitialDelay: 300000
};

async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI, OPTS);
    logger.info('MongoDB connected');

    mongoose.connection.on('error', (err) => {
      logger.error('MongoDB error:', err);
    });
    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected – will auto‑reconnect');
    });
  } catch (err) {
    logger.error('MongoDB connection failed:', err);
    process.exit(1);
  }
}

module.exports = { connectDB };