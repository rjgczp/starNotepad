## ADDED Requirements

### Requirement: Pair-scoped realtime event channel
The system SHALL provide authenticated WebSocket connections for the two pair identities and SHALL deliver chat, presence, read-receipt, and signalling events only to the other identity in that pair.

#### Scenario: Connected user sends a signal
- **WHEN** an authenticated user sends a valid WebRTC signalling event
- **THEN** the currently connected counterpart receives the event in real time

### Requirement: Responsive two-person video layout
The client SHALL render local and remote video panels side-by-side on desktop and vertically on narrow screens, and SHALL let the user choose either panel as the primary panel.

#### Scenario: Mobile user promotes the local video
- **WHEN** a narrow-screen user selects the local panel as primary
- **THEN** the local panel expands and the remote panel becomes a compact secondary panel

### Requirement: Configurable NAT traversal
The client SHALL configure WebRTC ICE servers from deployment configuration so that STUN and TURN services can be used outside local networks.

#### Scenario: Production ICE configuration is provided
- **WHEN** the app is built with TURN configuration
- **THEN** a call peer connection includes the configured ICE server entries

### Requirement: Editable pair statuses
The system SHALL allow either pair identity to choose an enabled status option and SHALL show the latest status for both identities in the client.

#### Scenario: User changes availability
- **WHEN** a user selects an enabled status
- **THEN** the stored status updates and the counterpart receives the new status event
