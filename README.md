# 🔐 Alto - Secure Messaging Application

A Flutter-based encrypted messaging app with end-to-end RSA encryption. Two users can establish a secure connection via QR code pairing and exchange messages, emojis, colors, URLs, and locations.

---

## 📋 Project Overview

**Alto** is an IUT-BUT Informatique R4.11 project that demonstrates:
- ✅ RSA-2048 encryption (pointycastle)
- ✅ Secure key storage (flutter_secure_storage)
- ✅ QR code generation & scanning
- ✅ RESTful API integration
- ✅ Multi-type message exchange

---

## ✨ Features Implemented

### ✅ Part 1: Pairing Initial (4/4 points)
- [x] **1.1** Generate RSA key pair (2048-bit) + UUID relationCode
- [x] **1.2** Scan QR code to match with partner
- [x] **1.3** Polling system (3-sec intervals) with 2-min timeout
- [x] **1.4** Finalization via DELETE /pairing + data persistence

### ✅ Part 2: Secure Exchange (8/8 points)
- [x] **2.1** Encrypt & send messages via POST /element
- [x] **2.2** Receive & decrypt messages via GET /element + auto-refresh (5-sec)
- [x] **2.3** Support for 5 message types:
  - MESSAGE (text)
  - ICON (emoji picker)
  - COLOR (color picker with hex display)
  - URL (with link icon)
  - LOCATION (with location icon)

### ✅ Part 3: Quality & Code (3.5/5 points)
- [x] **3.1** Error handling with try-catch blocks and user-friendly messages
- [x] **3.2** Cohesive Material Design UI with smooth navigation
- [x] **3.3** Clean architecture (screens/, services/, crypto/, models/)

### ❌ Bonus: Multi-Relations (0/3 points)
- [ ] Multiple simultaneous relations
- [ ] Relation management UI
- [ ] Contact list with selection


## 🏗️ Project Architecture

```
Alto/
├── lib/
│   ├── main.dart                    # App entry point with routes
│   │
│   ├── screens/
│   │   ├── Home/
│   │   │   ├── HomeScreen.dart         # Connection options
│   │   │   ├── InitPairingScreen.dart  # Generate QR code
│   │   │   └── ScanPairingScreen.dart  # Scan QR code
│   │   ├── relation/
│   │   │   └── RelationScreen.dart     # Secure messaging
│   │   └── theme/
│   │       └── theme.dart              # Material Design theme
│   │
│   ├── services/
│   │   ├── api_client.dart          # REST API calls
│   │   ├── element_service.dart     # Message exchange logic
│   │   └── pairing_service.dart     # Pairing orchestration
│   │
│   ├── crypto/
│   │   ├── key_generator.dart       # RSA key pair generation
│   │   ├── key_storage.dart         # Secure key persistence
│   │   └── rsa_crypto.dart          # Encryption/decryption
│   │
│   ├── models/
│   │   ├── element_model.dart       # Message model + ElementType enum
│   │   ├── pairing_session.dart     # Pairing session data
│   │   └── relation_info.dart       # Relation data (keys + codes)
│   │
│   └── routes/
│       └── app_routes.dart          # Route constants
│
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

---

