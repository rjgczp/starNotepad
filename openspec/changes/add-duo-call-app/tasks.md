## 1. Backend foundations

- [x] 1.1 Add pair slot, status, message, and session data models with automatic migration and seedable defaults.
- [x] 1.2 Add reversible key encryption, session issuance/validation, and pair-scoped REST APIs for login, status, history, unread state, and image upload.
- [x] 1.3 Add authenticated WebSocket hub for chat, read receipts, presence, and WebRTC signalling.

## 2. Administration

- [x] 2.1 Add backend management APIs for the two key slots, status options, and message/media inspection.
- [x] 2.2 Add a Gin-Vue-Admin management page for pair keys, status options, and chat history.

## 3. Independent call frontend

- [x] 3.1 Scaffold the `duo-call-web` TypeScript/React/Vite application with Iconify, environment configuration, and API/session client.
- [x] 3.2 Implement key-entry authentication and persistent blue, pink, and dark visual themes.
- [x] 3.3 Implement responsive video call controls and WebRTC/WebSocket signalling client.
- [x] 3.4 Implement real-time chat, emoji/image sending, history loading, unread indicators, and read receipts.

## 4. Deployment and verification

- [x] 4.1 Add Docker development service and production coturn configuration/template.
- [ ] 4.2 Run backend tests and frontend lint/type/build checks; manually verify two-browser login, message delivery, and call signalling.
