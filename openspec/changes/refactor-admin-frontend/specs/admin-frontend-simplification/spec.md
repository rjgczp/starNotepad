## ADDED Requirements

### Requirement: Simplified admin shell
The admin frontend MUST present a reduced shell that excludes framework-default controls and navigation entries that are not used in this deployment.

#### Scenario: Unused footer control removed
- **WHEN** an operator views the admin layout shell
- **THEN** the bottom Vue selection control is not shown
- **AND** no placeholder or dead control is left in its place

#### Scenario: Sidebar only shows deployment-relevant menus
- **WHEN** an operator opens the sidebar navigation
- **THEN** irrelevant GVA framework menus are absent
- **AND** the remaining menu structure still allows access to the intended operational pages

### Requirement: Stable icon rendering in admin views
The admin frontend MUST render icons consistently in shared layout and affected admin pages.

#### Scenario: Icons render in navigation and page actions
- **WHEN** an operator views the sidebar, page headers, or common action areas
- **THEN** configured icons render as intended instead of appearing broken, missing, or visually inconsistent

### Requirement: Readable list action presentation
The admin frontend MUST present list/table action buttons in a readable and non-colliding layout.

#### Scenario: Table row actions do not collapse into clutter
- **WHEN** an operator views a CRUD list page with multiple row operations
- **THEN** the available actions are visually separated and usable
- **AND** the action area does not collapse into overlapping or crowded controls

#### Scenario: Low-value duplicate actions are removed
- **WHEN** a page exposes multiple overlapping operation buttons
- **THEN** redundant or low-value actions are removed or grouped
- **AND** the primary operational flow remains available

### Requirement: Frontend simplification preserves main operator workflows
The frontend cleanup MUST keep core operator workflows usable after removing redundant UI surface.

#### Scenario: Core page access remains intact after sidebar pruning
- **WHEN** an operator needs to access a retained page
- **THEN** that page is still reachable through the remaining navigation or intended workflow entry
- **AND** cleanup of unrelated menus does not strand required functionality

#### Scenario: Shared layout cleanup does not break page rendering
- **WHEN** an operator navigates between retained admin pages
- **THEN** the pages still render within the simplified layout shell
- **AND** layout cleanup does not introduce broken containers, missing slots, or unusable page chrome
