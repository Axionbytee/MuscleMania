/**
 * Create initial admin account for MuscleMania
 * Usage: node scripts/create-admin.js <username> <password>
 * 
 * Example:
 *   node scripts/create-admin.js admin password123
 */

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import Admin from '../models/Admin.js';

// Load .env from backend directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: join(__dirname, '..', '.env') });

const MONGO_URI = process.env.MONGO_URI;
const args = process.argv.slice(2);

if (args.length < 2) {
  console.error('❌ Usage: node scripts/create-admin.js <username> <password>');
  console.error('Example: node scripts/create-admin.js admin password123');
  process.exit(1);
}

const [username, password] = args;

async function createAdmin() {
  try {
    if (!MONGO_URI) {
      throw new Error('MONGO_URI is not defined in environment variables');
    }

    await mongoose.connect(MONGO_URI);
    console.log('[DB] Connected to MongoDB');

    // Check if admin already exists
    const existing = await Admin.findOne({ username });
    if (existing) {
      console.error(`❌ Admin with username "${username}" already exists`);
      process.exit(1);
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create admin
    const admin = new Admin({ username, passwordHash });
    await admin.save();

    console.log(`✅ Admin account created successfully`);
    console.log(`📝 Username: ${username}`);
    console.log(`🔐 Password: ${password}`);
    console.log(`\n🔗 Login at: http://localhost:${process.env.PORT}/admin`);

    process.exit(0);
  } catch (err) {
    console.error('❌ Error creating admin:', err.message);
    process.exit(1);
  }
}

createAdmin();
