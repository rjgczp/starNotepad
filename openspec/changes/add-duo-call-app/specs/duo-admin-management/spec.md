## ADDED Requirements

### Requirement: Pair administration
The administration interface SHALL provide management for the two access keys and enabled status options.

#### Scenario: Administrator changes status options
- **WHEN** an administrator creates, edits, orders, enables, or disables a status option
- **THEN** the client status selector reflects the enabled ordered options after refresh

### Requirement: Message and media inspection
The administration interface SHALL allow authorized administrators to filter and view every pair message, its sender, sent/read timestamps, and associated uploaded image.

#### Scenario: Administrator opens an image message
- **WHEN** an administrator selects a message with an image
- **THEN** the interface displays the stored image and its message metadata
