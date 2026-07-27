## Context

The current `gin-vue-admin` frontend is being used as a constrained admin surface rather than a full framework showcase. In its current state, the UI mixes product-relevant functions with many framework-default controls and menus that are not needed for this deployment. At the same time, there are recurring presentation defects in the admin shell and CRUD pages, including icon rendering problems, table action buttons collapsing into crowded horizontal groups, and footer controls that distract from the intended operator workflow.

This change is a frontend simplification and stabilization effort. The goal is to reduce visual noise, remove low-value framework leftovers, and normalize a smaller set of admin interactions without redesigning the whole application or changing unrelated backend behavior.

## Goals / Non-Goals

**Goals:**
- Fix obvious frontend usability defects that make the current admin UI feel broken or unstable.
- Standardize table/list action presentation so operations are readable and no longer visually collide.
- Remove framework-default controls and menus that are not needed in this deployment.
- Simplify the layout shell, especially sidebar and footer surfaces, so operators see only the functions they actually use.
- Keep the implementation localized to frontend layout, navigation, and page-level presentation wherever possible.

**Non-Goals:**
- Rebuild the design system or replace the existing component library.
- Rewrite all admin pages or refactor unrelated business flows.
- Introduce new backend permission concepts solely for this cleanup.
- Re-implement removed GVA menus behind a custom replacement in the same change.
- Solve all historical frontend bugs in one pass; this change focuses on structural UI noise and the most visible recurring defects.

## Decisions

### Decision: Remove unused framework surface instead of hiding it conditionally
Unused GVA menus and footer controls will be deleted or disabled at their frontend source of truth rather than left behind in hidden or environment-gated states.

Alternative considered: keep these controls and hide them behind conditions or roles. Rejected because it preserves complexity, makes later maintenance harder, and increases the chance that removed framework features resurface unexpectedly.

### Decision: Normalize list actions with a shared presentation pattern
Crowded table/list operations will be simplified into a consistent action pattern, such as narrower action sets, dropdown grouping, or vertically stacked actions where needed, depending on the current page constraints.

Alternative considered: fix each page independently with one-off spacing tweaks. Rejected because the current issue is systemic and would quickly drift again without a shared presentation rule.

### Decision: Fix icon issues by aligning icon usage with current component expectations
Icon rendering problems will be fixed by auditing how icons are imported, passed, and rendered in shared admin pages and layout components, then updating those usages to a consistent working pattern.

Alternative considered: swap icon libraries or add compatibility wrappers. Rejected because the current problem is most likely integration inconsistency, not missing icon capability.

### Decision: Preserve business capability while shrinking navigation
The sidebar cleanup will remove menus that are irrelevant to the deployment, but the underlying business pages and permissions will only be removed where they are clearly unused and intentionally out of scope.

Alternative considered: aggressively delete all unused code with the menu cleanup. Rejected because navigation simplification and codebase-wide dead-code removal are different scopes and should not be coupled unless usage is certain.

## Risks / Trade-offs

- [Removing menu entries hides something operators still use] → Review the active sidebar and prune only clearly unwanted sections first; keep changes easy to reverse in code.
- [List-action simplification breaks page-specific workflows] → Apply a consistent pattern, but verify each high-traffic CRUD page after the change rather than assuming one layout fits all.
- [Icon fixes reveal broader component misuse] → Start from shared layout and admin pages where symptoms recur most often, then expand only where breakage is confirmed.
- [Footer control removal affects a niche workflow] → Remove only controls identified as framework leftovers, not business-critical status or navigation functions.

## Migration Plan

1. Audit current frontend shell and common admin pages to identify menus, footer controls, and repeated action-button patterns targeted by this change.
2. Update shared layout/navigation components first so the visible framework-default surface is reduced centrally.
3. Apply the action-layout and icon fixes to the affected admin list/detail pages.
4. Validate the simplified UI by exercising the main operator flows and checking for missing navigation, broken icons, and table-action regressions.
5. If a removed menu or control turns out to be required, restore it selectively without reverting the full simplification.

## Open Questions

- Which sidebar sections are considered definitively out of scope versus merely low-priority?
- Whether some crowded action areas should use dropdown menus versus inline compact buttons, depending on operator frequency.
- Whether the bottom Vue selector is purely decorative/framework-default or has any deployment-specific meaning in this fork.
