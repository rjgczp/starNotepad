# offline-safe-runtime

## Purpose
TBD: Define the offline-safe runtime requirements for self-hosted operation without official GVA online dependencies.

## Requirements

### Requirement: Runtime does not depend on official GVA online services
The system SHALL not require any request to official GVA-operated internet services in order to load core administrative pages, execute standard local management actions, or complete routine self-hosted operation.

#### Scenario: Core admin usage in a restricted network
- **WHEN** an administrator uses the deployed system in an environment without internet access to official GVA domains
- **THEN** core administrative pages and routine local management features continue to function without attempting to call official GVA-operated services

### Requirement: Official online-only entry points are removed from the product surface
The system SHALL not expose user-facing entry points for official GVA-hosted capabilities that are unavailable without remote official services.

#### Scenario: Navigation and tool surfaces are rendered
- **WHEN** the application renders seeded menus, system-tool pages, and plugin-related entry points
- **THEN** it does not show links or actions for official websites, plugin markets, hosted AI analysis, or remote skill-download features

### Requirement: Source configuration does not hard-code official outbound endpoints
The system SHALL not ship with source-level configuration, proxy rules, or service defaults that reference official GVA internet endpoints for runtime features.

#### Scenario: Repository configuration is reviewed
- **WHEN** maintainers inspect runtime configuration and source-defined service endpoints
- **THEN** they do not find official GVA internet endpoints required for runtime features in default configuration or frontend proxy setup
