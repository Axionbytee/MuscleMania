import 'dotenv/config';
import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import connectDB from './models/connect.js';
import scanRoutes from './routes/scan.js';
import memberRoutes from './routes/members.js';
import attendanceRoutes from './routes/attendance.js';
import authRoutes from './routes/auth.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// Make io accessible to routes via req.app.get('io')
app.set('io', io);

// Middleware
app.use(cors());
app.use(express.json());

// Static file serving — member photo uploads
app.use('/uploads', express.static(join(__dirname, 'uploads')));

// Static file serving — gate display (existing frontend)
app.use('/', express.static(join(__dirname, '..', 'frontend', 'gate-display')));

// Static file serving — admin dashboard
app.use('/admin', express.static(join(__dirname, '..', 'frontend', 'admin')));

// API Routes
app.use('/api/scan', scanRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/auth', authRoutes);

// Socket.io connection logging
io.on('connection', (socket) => {
  console.log(`[WS] Client connected: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`[WS] Client disconnected: ${socket.id}`);
  });
});

// Start server
const PORT = process.env.PORT || 3000;

async function start() {
  await connectDB();
  server.listen(PORT, () => {
    console.log(`[SERVER] MuscleMania running on http://localhost:${PORT}`);
  });
}

start();

export { io };
