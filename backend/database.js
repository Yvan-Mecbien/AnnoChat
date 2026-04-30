const mongoose = require('mongoose');
const logger = require('../utils/logger');

const OPTS = {
  maxPoolSize: 20,
  serverSelectionTimeoutMS: 30000,   // 30s au lieu de 5s
  socketTimeoutMS: 0,                // Pas de timeout inactif
  family: 4,                         // Forcer IPv4 (utile sur certains clouds)
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
    logger.error('MongoDB connection failed:', err.message);
    process.exit(1);
  }
}

module.exports = { connectDB };
