## Why

The current `gin-vue-admin` integration still contains several official online capabilities and hard-coded outbound links. For a self-hosted deployment, these dependencies create unwanted external network traffic, expose users to remote-service gating, and make the runtime behavior less predictable in restricted or offline environments.

## What Changes

- Remove official online capabilities that depend on remote GVA-operated services.
- Remove hard-coded outbound links to official GVA sites and plugin-market domains from seeded menus and frontend/runtime paths.
- Disable or delete UI entry points that only work when remote official services are reachable.
- **BREAKING**: plugin-market, skills-download, and GVA-hosted AI analysis features will no longer be available after this change.
- Keep local/admin functionality intact wherever it does not require outbound access.

## Capabilities

### New Capabilities
- `offline-safe-runtime`: Ensure the deployed system runs without official GVA online-service dependencies or hard-coded outbound links.

### Modified Capabilities
- None.

## Impact

- Affected frontend areas: system tools, error-log analysis UI, plugin-related UI entry points, Vite proxy configuration.
- Affected backend areas: seeded menu definitions, remote plugin/skills download services, configuration defaults referencing official endpoints.
- Affected behavior: the application will no longer surface official plugin-market or hosted AI capabilities; deployments can remain local-only or intranet-only without contacting GVA domains.
