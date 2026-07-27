## Context

This change removes the portions of the current `gin-vue-admin` integration that depend on official GVA-operated internet services or present official outbound links in the product UI. The current codebase includes several such integrations: AI-assisted error analysis, plugin-market navigation, plugin/skills download flows, and frontend proxy or config entries that target official domains. The goal is a self-hosted deployment that remains local-only or intranet-only without surprising remote dependencies.

## Goals / Non-Goals

**Goals:**
- Remove user-facing entry points that lead to official GVA websites or hosted plugin-market capabilities.
- Remove backend and frontend code paths that invoke official GVA-operated remote services.
- Remove default configuration and proxy entries that point to official GVA internet endpoints.
- Preserve local administrative functionality that does not depend on those remote services.

**Non-Goals:**
- Re-implement plugin-market, skills distribution, or AI analysis using a replacement internal service.
- Remove every possible third-party URL in the repository regardless of purpose; the scope is official online runtime/product features surfaced by this project.
- Redesign unrelated system-tool pages or menu structure beyond what is required to eliminate official online-only features.

## Decisions

### Decision: Remove online-only features instead of stubbing them
The implementation will remove UI entry points and backend invocations for official online-only features rather than leaving dead buttons or local placeholders. This keeps behavior explicit and avoids a misleading product surface.

Alternative considered: keep the menus/buttons but show a disabled state. Rejected because it still advertises unsupported remote features and leaves more maintenance surface.

### Decision: Remove outbound links at their source of truth
Official website and plugin-market links will be removed from seeded menu definitions and frontend/runtime configuration rather than filtered only in rendering. This prevents regeneration or reseeding from restoring unwanted external links.

Alternative considered: hide links in the frontend only. Rejected because backend-seeded menus can repopulate them and create drift between UI and initialization logic.

### Decision: Keep local features unless they directly require official endpoints
Features that remain local to the deployment are kept intact. Only code paths that directly require official hosted services or explicitly surface official remote destinations are removed.

Alternative considered: broadly remove all plugin/system-tools functionality. Rejected because it would over-delete useful local capabilities unrelated to outbound access.

## Risks / Trade-offs

- [Loss of convenience features] → Plugin-market, hosted AI, and remote skill download capabilities disappear entirely; this is accepted because local-only operation is the primary goal.
- [Possible hidden outbound references] → Perform a repository-wide search for official domains and link patterns before finishing implementation.
- [Seeded menu drift in existing databases] → Remove the source definitions now; note that already-seeded database rows may need cleanup or migration separately if they already exist in a running environment.

## Migration Plan

1. Remove source-level frontend and backend references to official online services and external menu entries.
2. Remove or simplify UI pages/actions that only exist to trigger official hosted features.
3. Verify the repository no longer contains runtime references to official GVA domains in the affected areas.
4. For existing deployments, clean already-seeded menu or configuration rows separately if runtime data was populated before the change.

## Open Questions

- Whether the existing deployment also contains database-seeded external links that should be cleaned by a migration or left for manual ops cleanup.
- Whether any additional official-domain references exist in plugin submodules not yet exercised in this repository state.
