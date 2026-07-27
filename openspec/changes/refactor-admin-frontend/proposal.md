## Why

The current admin frontend has accumulated visible UI defects and unnecessary product surface, including broken icon display, crowded list action buttons, footer controls that are not needed, and many GVA sidebar menus that are irrelevant to this deployment. These issues are already affecting usability and maintenance, so the frontend needs a focused simplification and cleanup rather than more incremental fixes.

## What Changes

- Refactor the admin frontend layout and page presentation to fix recurring UI defects such as icon rendering issues and crowded action-button areas in data tables.
- Remove redundant frontend controls that are not needed for this deployment, including the bottom Vue selection control.
- Remove unused GVA sidebar menus and related entry points that are not part of the intended product scope.
- Simplify page-level interactions where the current UI exposes too many low-value or duplicate actions.
- **BREAKING**: some existing navigation entries and UI controls will be removed from the admin frontend.

## Capabilities

### New Capabilities
- `admin-frontend-simplification`: Defines the required simplified admin experience, including cleaner table actions, consistent icons, reduced footer controls, and a pruned sidebar menu.

### Modified Capabilities
- None.

## Impact

- Affected frontend areas: layout shell, sidebar navigation, footer area, shared list/table actions, menu management pages, and icon usage across admin views.
- Affected behavior: some menu entries, footer controls, and low-value actions will no longer be visible; table operations and icon presentation will change to a simplified UI.
- Affected code: `gin-vue-admin/web/src/view/`, layout components, shared UI utilities, and menu-related frontend configuration.
