import mongoose from 'mongoose';

/**
 * Connect to MongoDB using the URI from environment variables.
 * Logs connection status and exits on fatal errors.
 */
async function connectDB() {
  const mongoUri = process.env.MONGO_URI;
  
  if (!mongoUri) {
    console.error('[DB] MONGO_URI is not defined in environment variables');
    process.exit(1);
  }

  try {
    await mongoose.connect(mongoUri);
    console.log('[DB] Connected to MongoDB successfully');
  } catch (err) {
    console.error('[DB] Connection error:', err.message);
    process.exit(1);
  }
}

export default connectDB;
