module.exports = {
  apps: [
    {
      name: 'musclemania-backend',
      script: './backend/server.js',
      watch: false,
      env: { NODE_ENV: 'production' }
    },
    {
      name: 'musclemania-scanner',
      script: './pi-reader/scanner.py',
      interpreter: 'python3',
      watch: false,
      restart_delay: 3000
    }
  ]
};
