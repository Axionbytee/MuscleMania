# MuscleMania - Membership Card Viewer

## Project Status: **ACTIVE DEVELOPMENT** ✅

### Current State of Codebase
The MuscleMania membership card viewer application is **functionally complete** with core features implemented and working.

---

## Features Implemented

### ✅ Membership Card Display
- **Status-Based Card Rendering**: Displays membership cards with three different statuses:
  - **ACTIVE** (green badge) - Valid membership
  - **EXPIRED** (red badge) - Expired membership  
  - **EXPIRING SOON** (yellow badge) - Warning status with countdown timer
- **Card Information Display**: Shows member name, issue date, and expiry date
- **Card Navigation**: "Next" button cycles through sample membership cards

### ✅ Dynamic Background Effects
- Blurred background image with status-based color filtering:
  - **Active**: Standard teal gradient with normal brightness
  - **Expired**: Darkened with sepia + desaturated red tint
  - **Warning**: Amber/orange tinted for alerts

### ✅ Countdown Timer
- Real-time countdown display for expiring-soon memberships
- Timezone-aware (set to Asia/Manila)
- Displays remaining hours, minutes, and seconds
- Updates every second with live countdown

### ✅ Responsive Design
- Full viewport coverage (100vh/100vw)
- Modern UI with rounded corners and gradients
- Mobile-friendly viewport meta tags

---

## Project Structure

```
MuscleMania/
├── index.html              # Main HTML structure
├── README.md              # Project documentation
└── src/
    ├── css/
    │   ├── fonts.css      # Font definitions
    │   └── style.css      # Main styling & layout
    ├── js/
    │   └── script.js      # Card logic & timer functionality
    └── assets/
        └── images/
            ├── bgImage.png    # Background image
            ├── Naig.png       # Member photo
            └── [other assets]
```

---

## Technical Stack

- **HTML5** - Structure
- **CSS3** - Styling with gradients, filters, and transitions
- **Vanilla JavaScript** - Card switching logic and countdown timer
- **No Dependencies** - Pure frontend implementation

---

## Current Implementation Details

### Card Data Structure
Three sample membership states stored in `script.js`:
```javascript
const data = [
  { status: 'ACTIVE', issued: 'MARCH 18, 2026', expiry: 'APRIL 17, 2026', ... },
  { status: 'EXPIRED', issued: 'JANUARY 01, 2026', expiry: 'JANUARY 31, 2026', ... },
  { status: 'EXPIRING SOON', issued: 'APRIL 10, 2026', expiry: 'APRIL 20, 2026', showTimer: true }
]
```

### Key Functions
- `nextCard()` - Cycles to next membership state and updates UI
- `updateTimer()` - Calculates and displays countdown for expiring cards
- Dynamic class switching for visual state changes

---

## What's Working

✅ Card display and switching  
✅ Status badge rendering  
✅ Background color/filter transitions  
✅ Countdown timer logic  
✅ Date display formatting  
✅ UI responsiveness  

---

## Known Limitations / Future Enhancements

- [ ] Static sample data (no real database integration)
- [ ] Single member display (hardcoded "CHARLES GIANN MARCELO")
- [ ] No data persistence or API integration
- [ ] Timer timezone currently hardcoded to Asia/Manila
- [ ] Could benefit from animation transitions between card states

---

## How to Use

1. Open `index.html` in a web browser
2. Click the **"Next"** button to cycle through different membership statuses
3. View the countdown timer for the "EXPIRING SOON" card state
4. Observe dynamic background color changes based on status

---

**Last Updated**: April 16, 2026
