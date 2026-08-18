import { Icon } from "@iconify/react";
import { useState } from "react";
import "./QixiInvitationDialog.css";

export function QixiInvitationDialog({
  onLater,
  onOpen,
}: {
  onLater: (dismissToday: boolean) => void;
  onOpen: (dismissToday: boolean) => void;
}) {
  const [dismissToday, setDismissToday] = useState(false);

  return (
    <div className="qixi-invitation-backdrop" role="presentation">
      <section
        className="qixi-invitation-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="qixi-invitation-title"
        aria-describedby="qixi-invitation-message"
      >
        <div className="qixi-invitation-orbit" aria-hidden="true">
          <i />
          <i />
          <i />
        </div>
        <span className="qixi-invitation-icon" aria-hidden="true">
          <Icon icon="solar:gift-bold-duotone" />
        </span>
        <p className="qixi-invitation-eyebrow">A LITTLE SURPRISE</p>
        <h1 id="qixi-invitation-title">今天，有一份特别的东西在等你</h1>
        <p id="qixi-invitation-message">
          对方在今天给你留了特别的东西，要现在去看看吗？
        </p>
        <label className="qixi-invitation-dismiss">
          <input
            type="checkbox"
            checked={dismissToday}
            onChange={(event) => setDismissToday(event.target.checked)}
          />
          <span aria-hidden="true"><Icon icon="solar:check-read-linear" /></span>
          今日不再提示
        </label>
        <footer>
          <button type="button" className="secondary" onClick={() => onLater(dismissToday)}>
            暂不查看
          </button>
          <button type="button" className="primary" onClick={() => onOpen(dismissToday)} autoFocus>
            立即前往 <Icon icon="solar:arrow-right-bold" />
          </button>
        </footer>
      </section>
    </div>
  );
}
