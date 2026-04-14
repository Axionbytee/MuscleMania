const data = [
    {
      status: 'ACTIVE',
      badgeClass: 'status-badge badge-good',
      bgClass: 'status-valid',
      issued: 'MARCH 18, 2026',
      expiry: 'APRIL 17, 2026',
      showTimer: false
    },
    {
      status: 'EXPIRED',
      badgeClass: 'status-badge badge-expired',
      bgClass: 'status-expired',
      issued: 'JANUARY 01, 2026',
      expiry: 'JANUARY 31, 2026',
      showTimer: false
    },
    {
      status: 'EXPIRING SOON',
      badgeClass: 'status-badge badge-warning',
      bgClass: 'status-warning',
      issued: 'APRIL 10, 2026',
      expiry: 'APRIL 17, 2026',
      showTimer: true
    }
  ];

  let currentIndex = 0;

  function nextCard() {
    currentIndex = (currentIndex + 1) % data.length;
    const current = data[currentIndex];
    
    const container = document.getElementById('container');
    const badge = document.getElementById('statusLabel');
    const timer = document.getElementById('expiry-timer');
    
    badge.innerText = current.status;
    document.getElementById('issuedDate').innerText = current.issued;
    document.getElementById('expiryDate').innerText = current.expiry;

    badge.className = current.badgeClass;
    container.className = `viewport-container ${current.bgClass}`;
    
    timer.style.display = current.showTimer ? 'block' : 'none';
  }

  function updateTimer() {
      // Force "now" to always reflect Philippine Time (GMT+8)
      const now = new Date(new Date().toLocaleString("en-US", {timeZone: "Asia/Manila"}));
      
      const hours = 23 - now.getHours();
      const minutes = 59 - now.getMinutes();
      const seconds = 59 - now.getSeconds();

      document.getElementById('expiry-timer').innerText = 
          ` ${hours.toString().padStart(2, '0')}h ${minutes.toString().padStart(2, '0')}m ${seconds.toString().padStart(2, '0')}s`;
  }
  
  setInterval(updateTimer, 1000);
  updateTimer();