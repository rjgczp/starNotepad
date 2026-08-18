import { Icon } from "@iconify/react";

export type AppDialogTone = "default" | "danger";

export function AppDialog({
  title,
  message,
  confirmLabel,
  cancelLabel,
  tone = "default",
  onConfirm,
  onCancel,
}: {
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel?: string;
  tone?: AppDialogTone;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const requiresConfirmation = Boolean(cancelLabel);
  return (
    <div
      className="app-dialog-backdrop"
      onClick={onCancel}
      role="presentation"
    >
      <section
        className={`app-dialog tone-${tone}`}
        role={requiresConfirmation ? "alertdialog" : "dialog"}
        aria-modal="true"
        aria-labelledby="app-dialog-title"
        aria-describedby="app-dialog-message"
        onClick={(event) => event.stopPropagation()}
      >
        <span className="app-dialog-icon" aria-hidden="true">
          <Icon
            icon={tone === "danger"
              ? "solar:danger-triangle-bold-duotone"
              : "solar:heart-angle-bold-duotone"}
          />
        </span>
        <div>
          <h2 id="app-dialog-title">{title}</h2>
          <p id="app-dialog-message">{message}</p>
        </div>
        <footer>
          {cancelLabel && (
            <button type="button" className="secondary" onClick={onCancel}>
              {cancelLabel}
            </button>
          )}
          <button
            type="button"
            className={tone === "danger" ? "danger" : "primary"}
            onClick={onConfirm}
            autoFocus
          >
            {confirmLabel}
          </button>
        </footer>
      </section>
    </div>
  );
}
