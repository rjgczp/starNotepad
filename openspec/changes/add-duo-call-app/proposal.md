## Why

Create a dedicated, pleasant space for two people to make reliable video calls and stay in touch through persistent real-time chat. The existing projects do not provide a two-person WebRTC experience, pair-scoped access, or the associated private message management.

## What Changes

- Add an independent TypeScript/TSX web application with a lively cartoon design, responsive call layout, Iconify icons, and blue, pink, and dark themes.
- Add pair-scoped secret-key authentication: exactly two active identities can access the application and their keys are reversibly encrypted at rest while remaining editable by an administrator.
- Add a real-time WebRTC call room with WebSocket signalling and TURN-ready configuration.
- Add persistent text, emoji, and image chat with read receipts and unread notifications.
- Add editable presence/status options and a management interface for keys, statuses, messages, and uploaded images.

## Capabilities

### New Capabilities

- `duo-access`: Two-identity secret-key login, session lifecycle, and administrative key management.
- `duo-realtime-room`: Responsive two-person video calling, signalling, and status presence.
- `duo-chat`: Persistent pair chat with images, emoji, unread counts, and read receipts.
- `duo-admin-management`: Administrative configuration and inspection for keys, statuses, media, and messages.
- `duo-call-frontend`: Independent TSX application, responsive UI, and selectable visual themes.

### Modified Capabilities

None.

## Impact

- Adds a standalone frontend application and a new backend API/WebSocket domain within `gin-vue-admin/server`.
- Adds database models, media storage configuration, management routes, and realtime connection infrastructure.
- Adds deployment configuration for the web application, WebSocket API, and coturn/TURN service.
