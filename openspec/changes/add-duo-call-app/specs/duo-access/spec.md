## ADDED Requirements

### Requirement: Two-slot secret-key access
The system SHALL maintain exactly two pair identity slots and SHALL only establish an application session when an enabled slot's supplied secret key matches its encrypted stored key.

#### Scenario: Enabled key logs in
- **WHEN** a user submits the current key for an enabled slot
- **THEN** the system returns a signed session identifying that slot without returning the stored key

#### Scenario: Invalid or disabled key is rejected
- **WHEN** a user submits an unknown key or a key for a disabled slot
- **THEN** the system denies access without revealing which condition failed

### Requirement: Editable encrypted key management
The system SHALL allow an administrator to view, replace, enable, or disable either of the two stored keys and SHALL persist the key using reversible authenticated encryption.

#### Scenario: Administrator replaces a key
- **WHEN** an administrator saves a new value for a slot
- **THEN** the encrypted stored value is updated and existing sessions for that slot are invalidated
