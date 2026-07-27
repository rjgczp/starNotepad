## ADDED Requirements

### Requirement: Persistent pair chat
The system SHALL persist text, emoji, and image messages sent by either pair identity and SHALL return the pair's history in chronological pages.

#### Scenario: User sends text with emoji
- **WHEN** an authenticated user submits a non-empty text message containing emoji
- **THEN** the message is saved and delivered to the counterpart in real time

### Requirement: Long-term image messages
The system SHALL validate supported image uploads, persist the asset in durable storage, and create a chat message referencing the resulting image URL.

#### Scenario: User uploads a valid image
- **WHEN** an authenticated user uploads a permitted image within the configured size limit
- **THEN** the image is stored and appears as an image message to both identities

### Requirement: Read and unread state
The system SHALL track when each recipient has read incoming messages, provide an unread count, and publish read receipts to connected clients.

#### Scenario: Recipient opens unread history
- **WHEN** a recipient marks messages as read
- **THEN** the persisted read timestamp is set, their unread count decreases, and the sender receives a read receipt event
