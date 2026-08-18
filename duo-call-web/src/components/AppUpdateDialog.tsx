import { Icon } from "@iconify/react";
import type { AppRelease } from "../appUpdate";

export function AppUpdateDialog({
  release,
  onLater,
}: {
  release: AppRelease;
  onLater: () => void;
}) {
  const startUpdate = () => {
    // A separate browsing context keeps a packaged WebView from navigating
    // away from the room while the installer is being downloaded.
    const downloadWindow = window.open(release.downloadUrl, "_blank", "noopener,noreferrer");
    if (!downloadWindow) window.location.assign(release.downloadUrl);
  };
  return (
    <div className="app-update-backdrop" role="presentation">
      <section
        className="app-update-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="app-update-title"
        aria-describedby="app-update-description"
      >
        <span className="app-update-icon" aria-hidden="true">
          <Icon icon="solar:download-minimalistic-bold-duotone" />
        </span>
        <p className="app-update-eyebrow">NEW VERSION AVAILABLE</p>
        <h1 id="app-update-title">爱情小屋有新版本</h1>
        <p id="app-update-description">
          已为你准备好 v{release.version}。下载并安装后，重新打开爱情小屋即可继续使用。
        </p>
        {release.releaseNotes && (
          <div className="app-update-notes" aria-label="更新说明">
            <b>本次更新</b>
            <p>{release.releaseNotes}</p>
          </div>
        )}
        <footer>
          {!release.forceUpdate && (
            <button type="button" className="secondary" onClick={onLater}>
              稍后再说
            </button>
          )}
          <button type="button" className="primary" onClick={startUpdate} autoFocus>
            立即下载更新 <Icon icon="solar:arrow-right-bold" />
          </button>
        </footer>
        {release.forceUpdate && <small>此版本为必要更新，请完成安装后再进入小屋。</small>}
      </section>
    </div>
  );
}
