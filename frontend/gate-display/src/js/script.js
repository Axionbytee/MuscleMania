/* MuscleMania — Gate Display Script
 * Listens for scan_result events via Socket.io and renders member cards.
 */

// DOM references
const idleScreen = document.getElementById('idle-screen');
const container = document.getElementById('container');
const badge = document.getElementById('statusLabel');
const timerDisplay = document.getElementById('expiry-timer');
const expirationCountdownDisplay = document.getElementById('expirationCountdown');
const issuedDateDisplay = document.getElementById('issuedDate');
const expiryDateDisplay = document.getElementById('expiryDate');
const memberNameDisplay = document.getElementById('memberName');
const memberPhotoDisplay = document.getElementById('memberPhoto');

const AUTO_RESET_MS = 8000;

let resetTimer = null;
let countdownInterval = null;

// --- Socket.io Connection ---
const socket = io();

socket.on('connect', () => {
  console.log('[WS] Connected to server');
});

socket.on('disconnect', () => {
  console.log('[WS] Disconnected from server');
});

socket.on('scan_result', (data) => {
  clearTimeout(resetTimer);
  renderCard(data);
  resetTimer = setTimeout(resetToIdle, AUTO_RESET_MS);
});

// --- Card Rendering ---

/**
 * Render a membership card from scan data.
 * @param {{ status: string, member: object|null }} data
 */
function renderCard(data) {
  // Stop any running countdown
  clearInterval(countdownInterval);
  countdownInterval = null;

  // Hide idle, show card
  idleScreen.style.display = 'none';
  container.style.display = '';

  const { status, member } = data;

  // Map status to CSS classes
  const statusMap = {
    ACTIVE: {
      badgeClass: 'status-badge badge-good',
      bgClass: 'status-valid',
      label: 'ACTIVE'
    },
    EXPIRING_SOON: {
      badgeClass: 'status-badge badge-warning',
      bgClass: 'status-warning',
      label: 'EXPIRING SOON'
    },
    EXPIRED: {
      badgeClass: 'status-badge badge-expired',
      bgClass: 'status-expired',
      label: 'EXPIRED'
    },
    UNKNOWN: {
      badgeClass: 'status-badge badge-expired',
      bgClass: 'status-expired',
      label: 'NOT REGISTERED'
    }
  };

  const config = statusMap[status] || statusMap.UNKNOWN;

  // Apply status
  badge.innerText = config.label;
  badge.className = config.badgeClass;
  container.className = `viewport-container ${config.bgClass}`;

  if (member) {
    memberNameDisplay.innerText = (member.fullName || '— — —').toUpperCase();
    issuedDateDisplay.innerText = formatDate(member.issueDate);
    expiryDateDisplay.innerText = formatDate(member.expirationDate);

    // Display expiration countdown (days or weeks)
    const remainingDays = member.remainingDays || 0;
    const expirationText = formatExpirationCountdown(remainingDays);
    expirationCountdownDisplay.innerText = expirationText;

    // Photo — use uploaded photo or fallback
    if (member.photoUrl) {
      memberPhotoDisplay.src = member.photoUrl;
    } else {
      const name = member.fullName || 'Member';
      memberPhotoDisplay.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=008080&color=fff&size=256`;
    }

    // Start countdown if expiring soon
    if (status === 'EXPIRING_SOON') {
      timerDisplay.style.display = 'block';
      startCountdown(member.expirationDate);
    } else {
      timerDisplay.style.display = 'none';
    }
  } else {
    // UNKNOWN card
    memberNameDisplay.innerText = 'UNREGISTERED CARD';
    issuedDateDisplay.innerText = '— — —';
    expiryDateDisplay.innerText = '— — —';
    expirationCountdownDisplay.innerText = '— — —';
    timerDisplay.style.display = 'none';
    memberPhotoDisplay.src = 'https://ui-avatars.com/api/?name=X&background=e74c3c&color=fff&size=256';
  }
}

// --- Idle Screen ---

/**
 * Reset display back to the idle "Tap your card" screen.
 */
function resetToIdle() {
  clearInterval(countdownInterval);
  countdownInterval = null;
  container.style.display = 'none';
  idleScreen.style.display = '';
}

// --- Countdown Timer ---

/**
 * Start a live countdown timer to the expiration date.
 * @param {string} expirationDate — ISO date string
 */
function startCountdown(expirationDate) {
  clearInterval(countdownInterval);

  const expiryTarget = new Date(expirationDate);

  function tick() {
    const now = new Date(
      new Date().toLocaleString('en-US', { timeZone: 'Asia/Manila' })
    );
    const diff = expiryTarget - now;

    if (diff <= 0) {
      timerDisplay.innerText = '00h 00m 00s';
      clearInterval(countdownInterval);
      return;
    }

    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);

    timerDisplay.innerText =
      `${String(hours).padStart(2, '0')}h ` +
      `${String(minutes).padStart(2, '0')}m ` +
      `${String(seconds).padStart(2, '0')}s`;
  }

  tick();
  countdownInterval = setInterval(tick, 1000);
}

// --- Helpers ---

/**
 * Format an ISO date string into a readable label.
 * @param {string} isoDate
 * @returns {string} e.g. "APRIL 17, 2026"
 */
function formatDate(isoDate) {
  if (!isoDate) return '— — —';
  const d = new Date(isoDate);
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'Asia/Manila'
  }).toUpperCase();
}

/**
 * Format remaining days as "X days" or "X weeks".
 * @param {number} days — remaining days
 * @returns {string} e.g. "Expiring in 5 days" or "Expiring in 2 weeks"
 */
function formatExpirationCountdown(days) {
  if (days < 0) {
    return 'Expired';
  } else if (days === 0) {
    return 'Expires today';
  } else if (days === 1) {
    return 'Expiring in 1 day';
  } else if (days < 7) {
    return `Expiring in ${days} days`;
  } else {
    const weeks = Math.round(days / 7);
    return weeks === 1 ? 'Expiring in 1 week' : `Expiring in ${weeks} weeks`;
  }
}

// Start in idle state
resetToIdle();
