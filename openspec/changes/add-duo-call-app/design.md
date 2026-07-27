## Context

The repository contains a Go/Gin backend with MySQL and a Vue administration app, plus several independent frontend projects. The new application is a separate TSX client for exactly two people. It needs browser-compatible authentication, persistent media chat, low-latency signalling, and production-ready WebRTC traversal without changing existing personal-home or blog behavior.

## Goals / Non-Goals

**Goals:**

- Deliver a standalone responsive TSX application with blue, pink, and dark visual themes.
- Limit application access and data visibility to exactly two managed identities.
- Persist messages, image metadata, read state, and status choices in MySQL.
- Support WebSocket chat, read receipts, presence, and WebRTC offer/answer/ICE signalling.
- Provide Gin-Vue-Admin pages and APIs for administrative control.
- Provide Docker/TURN configuration suitable for deployment on `xiaoyu.ski`.

**Non-Goals:**

- Multi-party rooms, public accounts, group chat, video recording, E2EE key exchange, and native mobile applications are excluded.
- This change does not provision DNS records, certificates, firewall rules, or deploy to the user's server.
- Browser push notifications while the site is closed are excluded from the first version; live unread indicators are included.

## Decisions

### Separate Vite + React TSX client

Create `duo-call-web` as an independent Vite/React/TypeScript application, rather than embedding it into the Vue admin or existing Next apps. This isolates the visual language, supports fast responsive iteration, and keeps runtime dependencies small. Iconify React supplies all interface icons.

### Gin API and WebSocket endpoints under `duoCall`

Implement persistent APIs in the existing Go service, with public key-login endpoints and authenticated pair-scoped API/WebSocket endpoints. A signed JWT session identifies one of two fixed `slot` values. This uses the existing backend deployment and database rather than introducing a second application server.

### Reversibly encrypted keys and signed sessions

The two login keys are encrypted with AES-GCM using a deployment-only `DUO_CALL_KEY_ENCRYPTION_KEY`, allowing an administrator to view and change the key. The login endpoint compares a supplied key after decryption and issues a short-lived signed session. Plain keys are never returned in public endpoints or logs. A hash-only design was rejected because the stated administration requirement needs recoverable values.

### WebSocket for app events; WebRTC for media

WebSocket carries chat, read receipts, presence, and WebRTC signalling events. `RTCPeerConnection` carries audio/video directly when possible. Client ICE configuration is environment-driven and points to STUN/TURN in production. A WebSocket-only media transport was rejected because browsers require WebRTC for interoperable real-time media.

### Server-backed image media

Images are validated and written beneath the backend uploads directory. The database stores message metadata and a durable URL, while the existing upload-serving path delivers the file. Object storage can replace the local mounted volume later without changing the chat data model.

### Responsive two-panel call layout

Desktop uses side-by-side local/remote cards; narrow screens stack them vertically. Either card can be made primary, reducing the other to a picture-in-picture panel. This preserves the two-person focus on all form factors.

## Risks / Trade-offs

- [TURN traffic consumes bandwidth] → Configure coturn with a restricted relay port range, quotas, and an external IP; monitor traffic on the server.
- [Some networks block peer connectivity] → Use TLS for the web app and TURN over UDP/TCP, with the TURN host supplied through environment configuration.
- [Long-lived image storage fills 60GB disk] → Enforce format/size limits, retain originals in a mounted volume, and expose media inspection/deletion in admin.
- [Two concurrent sessions send duplicate events] → Use event ids and message ids; clients deduplicate and reload durable history on reconnect.
- [Encryption key rotation can make saved keys unreadable] → Support configured previous keys during rotation and document backup/rollback before changing the key.

## Migration Plan

1. Run backend migrations to add duo-call tables and create two disabled key slots plus default status choices.
2. Configure `DUO_CALL_JWT_SECRET`, `DUO_CALL_KEY_ENCRYPTION_KEY`, upload storage, and allowed frontend origin.
3. Deploy the frontend and proxy `/api` and `/ws` through HTTPS.
4. Deploy coturn, open TCP/UDP 3478 and the configured relay UDP range, then set `VITE_DUO_ICE_SERVERS`.
5. Enable both keys in admin and test login, two-browser messaging, and a cross-network call.
6. Roll back by stopping the independent frontend/coturn services; existing applications and data remain unaffected.

## Open Questions

- The exact public hostname for the app is not yet selected; `call.xiaoyu.ski` is the recommended deployment target.
- The production TURN shared secret and server public/private address must be set on the actual host before internet-wide call testing.
