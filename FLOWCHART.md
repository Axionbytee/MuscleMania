flowchart TD
    subgraph Hardware["🔌 Hardware Layer"]
        RC522[RC522 RFID Reader]
        PI[Raspberry Pi]
    end

    subgraph Reader["📡 reader/scanner.py"]
        SCAN[Read RFID UID]
        POST_SCAN[POST /api/scan\nwith UID]
    end

    subgraph Backend["🖥️ backend/server.js — Express + Socket.io"]
        direction TB
        CONNECT[connectDB\nMongoDB Atlas]

        subgraph Routes["API Routes"]
            R_SCAN[POST /api/scan]
            R_MEMBERS[/api/members\nGET · POST · PATCH · DELETE]
            R_ATTENDANCE[GET /api/attendance]
            R_AUTH[POST /api/auth/login]
        end

        subgraph Middleware
            AUTH[authMiddleware\nJWT verify]
        end

        subgraph Models["MongoDB Models"]
            M_RFID[(RfidCard)]
            M_MEMBER[(Member)]
            M_ATTEND[(AttendanceLog)]
            M_ADMIN[(Admin)]
        end

        subgraph ScanLogic["Scan Logic"]
            CAPTURE{Capture\nMode?}
            FIND_CARD[Find active RfidCard\nby UID]
            FIND_MEMBER[Find Member\nby card.memberId]
            COMPUTE_STATUS{Membership\nStatus}
            LOG_ATTEND[Create AttendanceLog]
            EMIT[Socket.io emit\nscan_result]
        end
    end

    subgraph Frontend["🌐 frontend/"]
        direction LR
        GATE[gate-display/index.html\nKiosk Screen]
        ADMIN_LOGIN[admin/index.html\nLogin Page]
        ADMIN_DASH[admin/dashboard.html]
        ADMIN_MEM[admin/members.html]
        ADMIN_ATT[admin/attendance.html]
    end

    subgraph Display["Gate Kiosk Response"]
        APPROVED[✅ APPROVED\nShow member name + photo]
        EXPIRED[⚠️ EXPIRED\nShow expiry warning]
        UNKNOWN[❌ UNKNOWN\nCard not registered]
    end

    %% Hardware → Reader
    RC522 -->|SPI| PI
    PI --> SCAN
    SCAN --> POST_SCAN

    %% Reader → Backend
    POST_SCAN --> R_SCAN
    R_SCAN --> CAPTURE

    CAPTURE -->|Yes| CAPTURED[Return captured UID\nto admin form]
    CAPTURE -->|No| FIND_CARD

    FIND_CARD -->|Not found| EMIT
    FIND_CARD -->|Found| FIND_MEMBER
    FIND_MEMBER -->|Not found| EMIT
    FIND_MEMBER -->|Found| COMPUTE_STATUS

    COMPUTE_STATUS -->|APPROVED| LOG_ATTEND
    COMPUTE_STATUS -->|EXPIRED| LOG_ATTEND
    COMPUTE_STATUS -->|UNKNOWN| EMIT

    LOG_ATTEND --> M_ATTEND
    LOG_ATTEND --> EMIT

    %% DB lookups
    FIND_CARD -.->|query| M_RFID
    FIND_MEMBER -.->|query| M_MEMBER

    %% Socket.io → Gate Display
    EMIT -->|WebSocket| GATE
    GATE --> APPROVED
    GATE --> EXPIRED
    GATE --> UNKNOWN

    %% Admin flow
    ADMIN_LOGIN -->|POST /api/auth/login| R_AUTH
    R_AUTH -.->|verify| M_ADMIN
    R_AUTH -->|JWT token| ADMIN_LOGIN
    ADMIN_LOGIN -->|Redirect| ADMIN_DASH

    ADMIN_MEM -->|GET/POST/PATCH/DELETE| AUTH
    ADMIN_ATT -->|GET| AUTH
    AUTH -->|Valid| R_MEMBERS
    AUTH -->|Valid| R_ATTENDANCE

    R_MEMBERS -.->|read/write| M_MEMBER
    R_MEMBERS -.->|read/write| M_RFID
    R_ATTENDANCE -.->|read| M_ATTEND

    %% Static serving
    CONNECT --- Backend
    Backend -->|serves /| GATE
    Backend -->|serves /admin| ADMIN_DASH

