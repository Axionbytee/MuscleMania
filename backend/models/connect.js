import mongoose from 'mongoose';

/**
 * Connect to MongoDB using the URI from environment variables.
 * Logs connection status and exits on fatal errors.
 */
async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('[DB] Connected to MongoDB');
  } catch (err) {
    console.error('[DB] Connection error:', err.message);
    process.exit(1);
  }
}

export default connectDB;
