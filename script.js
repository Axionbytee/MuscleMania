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
      expiry: 'APRIL 20, 2026',
      showTimer: true
    }
  ];
  
  let currentIndex = 0;
  
  const container = document.getElementById('container');
  const badge = document.getElementById('statusLabel');
  const timerDisplay = document.getElementById('expiry-timer');
  const issuedDateDisplay = document.getElementById('issuedDate');
  const expiryDateDisplay = document.getElementById('expiryDate');
  
  function nextCard() {
    currentIndex = (currentIndex + 1) % data.length;
    const current = data[currentIndex];
    
    badge.innerText = current.status;
    issuedDateDisplay.innerText = current.issued;
    expiryDateDisplay.innerText = current.expiry;
  
    badge.className = current.badgeClass;
    container.className = `viewport-container ${current.bgClass}`;
    
    timerDisplay.style.display = current.showTimer ? 'block' : 'none';
  
    updateTimer();
  }
  
  function updateTimer() {
    const current = data[currentIndex];
    
    if (!current.showTimer) return;
  
    const now = new Date(new Date().toLocaleString("en-US", {timeZone: "Asia/Manila"}));
    
    const expiryDate = new Date(current.expiry);
    
    const diff = expiryDate - now;
  
    if (diff <= 0) {
      timerDisplay.innerText = "00h 00m 00s";
      return;
    }
  
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);
  
    timerDisplay.innerText = `${hours.toString().padStart(2, '0')}h ${minutes.toString().padStart(2, '0')}m ${seconds.toString().padStart(2, '0')}s`;
  }
  
  setInterval(updateTimer, 1000);
  updateTimer();
