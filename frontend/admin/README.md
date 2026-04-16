# MuscleMania Admin Dashboard

## Access the Admin Page

Navigate to: **`http://localhost:3000/admin`**

## First-Time Setup: Create Admin Account

Before you can log in, you need to create an admin account.

### Step 1: Create Admin User

From the `backend/` directory, run:

```bash
node scripts/create-admin.js <username> <password>
```

**Example:**
```bash
node scripts/create-admin.js admin password123
```

You should see:
```
✅ Admin account created successfully
📝 Username: admin
🔐 Password: password123

🔗 Login at: http://localhost:3000/admin
```

### Step 2: Log In

1. Navigate to `http://localhost:3000/admin`
2. Enter your username and password
3. Click **Login**
4. You'll be redirected to the dashboard

## Admin Dashboard Features

Once logged in, you can access:

### 📊 Dashboard
- Overview of members and attendance statistics
- Quick stats and metrics

### 👥 Members
- View all members
- Add new members
- Edit member details (name, email, phone, etc.)
- Delete members
- Upload member photos

### 📅 Attendance
- View attendance logs
- Filter by date, member, or status
- Export attendance records

## Session & Logout

- Your login token is stored in browser localStorage with a **24-hour expiry**
- When the token expires, you'll need to log in again
- To log out manually, clear localStorage or close the browser

## Troubleshooting

### "Invalid credentials" error
- Double-check your username and password
- Make sure you created the admin account first using `create-admin.js`

### "Cannot find module" error
- Make sure you're in the `backend/` directory when running `create-admin.js`
- Ensure all dependencies are installed: `npm install`

### Cannot access admin page
- Make sure the backend is running: `pm2 logs musclemania-backend`
- Check that MongoDB is connected: `[DB] Connected to MongoDB`
- The port should be 3000 (check `backend/.env`)

## Pages Available

| Page | URL |
|------|-----|
| Login | `http://localhost:3000/admin` |
| Dashboard | `http://localhost:3000/admin/dashboard.html` |
| Members | `http://localhost:3000/admin/members.html` |
| Attendance | `http://localhost:3000/admin/attendance.html` |
