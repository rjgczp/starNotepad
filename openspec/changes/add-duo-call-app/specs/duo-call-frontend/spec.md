## ADDED Requirements

### Requirement: Themeable cartoon visual system
The client SHALL provide selectable blue, pink, and dark themes, applying each theme consistently to the page background, cards, typography, focus states, and controls.

#### Scenario: User selects pink theme
- **WHEN** a user selects the pink theme
- **THEN** the active UI updates to the pink design tokens and persists the preference locally

### Requirement: Secret-key entry screen
The client SHALL show a focused key-entry screen before rendering pair-only content and SHALL route a successful login to the call home screen.

#### Scenario: Login succeeds
- **WHEN** the login API accepts an entered key
- **THEN** the client saves the session securely for the browser and shows the call home screen
