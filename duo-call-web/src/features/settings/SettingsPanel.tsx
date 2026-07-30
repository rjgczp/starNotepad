import { Icon } from "@iconify/react";
import { type FormEvent, useEffect, useRef, useState } from "react";
import type { DuoPreferences, LightTheme, Theme } from "../../preferences";
import type { DuoStatus, Identity } from "../../domain";
import { ProfileAvatar } from "../../components/ProfileAvatar";
import { ThemePicker, themes } from "../../components/ThemeControls";

export function SettingsPanel({
  theme,
  preferences,
  setTheme,
  setPreferences,
  identity,
  statuses,
  saveProfile,
  uploadAvatar,
  leave,
}: {
  theme: Theme;
  preferences: DuoPreferences;
  setTheme: (value: Theme) => void;
  setPreferences: React.Dispatch<React.SetStateAction<DuoPreferences>>;
  identity?: Identity;
  statuses: DuoStatus[];
  saveProfile: (
    displayName: string,
    statusId: number | null,
  ) => Promise<Identity>;
  uploadAvatar: (file: File) => Promise<Identity>;
  leave: () => void;
}) {
  const [profileName, setProfileName] = useState(identity?.displayName || "");
  const [profileStatus, setProfileStatus] = useState(identity?.statusId || 0);
  const [profileBusy, setProfileBusy] = useState(false);
  const [avatarBusy, setAvatarBusy] = useState(false);
  const [profileMessage, setProfileMessage] = useState("");
  const [avatarPreview, setAvatarPreview] = useState("");
  const avatarInput = useRef<HTMLInputElement>(null);
  useEffect(() => {
    setProfileName(identity?.displayName || "");
    setProfileStatus(identity?.statusId || 0);
  }, [identity?.displayName, identity?.statusId]);
  const update = (values: Partial<DuoPreferences>) =>
    setPreferences((current) => ({ ...current, ...values }));
  const future = (label: string) =>
    alert(`${label}正在规划中，入口已经为后续功能预留。`);
  const setDefaultTheme = (value: LightTheme) => {
    update({
      defaultLightTheme: value,
      theme: preferences.followSystem ? preferences.theme : value,
    });
  };
  const submitProfile = async (event: FormEvent) => {
    event.preventDefault();
    setProfileBusy(true);
    setProfileMessage("");
    try {
      await saveProfile(profileName, profileStatus || null);
      setProfileMessage("已经同步给对方了");
    } catch (error) {
      setProfileMessage(error instanceof Error ? error.message : "保存资料失败");
    } finally {
      setProfileBusy(false);
    }
  };
  const changeAvatar = async (file: File) => {
    const preview = URL.createObjectURL(file);
    setAvatarPreview(preview);
    setAvatarBusy(true);
    setProfileMessage("");
    try {
      await uploadAvatar(file);
      setProfileMessage("新头像已经换好");
    } catch (error) {
      setProfileMessage(error instanceof Error ? error.message : "上传头像失败");
    } finally {
      URL.revokeObjectURL(preview);
      setAvatarPreview("");
      setAvatarBusy(false);
    }
  };
  return (
    <main className="settings-page">
      <header className="settings-heading">
        <p>MAKE IT YOURS</p>
        <h1>把小屋调成喜欢的样子。</h1>
        <span>昵称、头像和状态会同步给对方；外观偏好只保存在当前设备。</span>
      </header>
      <section className="settings-grid">
        <article className="settings-card profile-settings">
          <header>
            <Icon icon="solar:user-heart-rounded-bold-duotone" />
            <div><h2>我的资料</h2><p>让对方一眼认出此刻的你</p></div>
          </header>
          <form onSubmit={submitProfile}>
            <button
              className="avatar-uploader"
              type="button"
              onClick={() => avatarInput.current?.click()}
              disabled={avatarBusy}
            >
              <ProfileAvatar identity={identity} src={avatarPreview} />
              <span>
                <b>{avatarBusy ? "正在上传…" : "更换头像"}</b>
                <small>JPG、PNG、GIF 或 WebP，最大 5MB</small>
              </span>
              <Icon icon="solar:camera-add-bold-duotone" />
            </button>
            <input
              ref={avatarInput}
              hidden
              type="file"
              accept="image/jpeg,image/png,image/gif,image/webp"
              onChange={(event) => {
                const file = event.target.files?.[0];
                if (file) void changeAvatar(file);
                event.target.value = "";
              }}
            />
            <label htmlFor="profile-display-name">我的昵称</label>
            <input
              id="profile-display-name"
              className="profile-name-input"
              value={profileName}
              maxLength={24}
              onChange={(event) => setProfileName(event.target.value)}
              placeholder="给自己一个熟悉的称呼"
            />
            <label>现在的状态</label>
            <div className="profile-statuses" role="group" aria-label="选择当前状态">
              <button
                type="button"
                className={profileStatus === 0 ? "active" : ""}
                onClick={() => setProfileStatus(0)}
              >
                <span>🌙</span>暂不设置
              </button>
              {statuses.map((status) => (
                <button
                  type="button"
                  key={status.ID}
                  className={profileStatus === status.ID ? "active" : ""}
                  onClick={() => setProfileStatus(status.ID)}
                >
                  <span>{status.emoji || "✨"}</span>{status.label}
                </button>
              ))}
            </div>
            <div className="profile-save-row">
              <small className={profileMessage ? "visible" : ""}>{profileMessage || "资料只对你们两个人可见"}</small>
              <button type="submit" disabled={profileBusy || avatarBusy}>
                <Icon icon="solar:diskette-bold-duotone" />
                {profileBusy ? "正在保存…" : "保存我的资料"}
              </button>
            </div>
          </form>
        </article>
        <article className="settings-card appearance-settings">
          <header>
            <Icon icon="solar:palette-bold-duotone" />
            <div><h2>外观与颜色</h2><p>当前：{themes.find((item) => item.id === theme)?.label}</p></div>
          </header>
          <label>立即切换颜色</label>
          <ThemePicker theme={theme} setTheme={setTheme} />
          <div className="setting-row">
            <span><b>跟随系统明暗</b><small>深色系统自动使用晚安黑</small></span>
            <button
              type="button"
              className={`setting-switch ${preferences.followSystem ? "on" : ""}`}
              onClick={() => update({ followSystem: !preferences.followSystem })}
              aria-pressed={preferences.followSystem}
            ><i /></button>
          </div>
          <div className="default-theme">
            <span><b>默认浅色主题</b><small>系统为浅色时使用</small></span>
            <div>
              {(["blue", "pink"] as LightTheme[]).map((value) => (
                <button
                  key={value}
                  type="button"
                  className={preferences.defaultLightTheme === value ? "active" : ""}
                  onClick={() => setDefaultTheme(value)}
                >
                  <i className={`theme-dot ${value}`} />
                  {value === "blue" ? "晴空蓝" : "心动粉"}
                </button>
              ))}
            </div>
          </div>
        </article>

        <article className="settings-card">
          <header>
            <Icon icon="solar:bell-bing-bold-duotone" />
            <div><h2>声音与通知</h2><p>决定什么时候轻轻提醒你</p></div>
          </header>
          <div className="setting-row">
            <span><b>对方上线提示音</b><small>双方打开小屋时播放短提示音</small></span>
            <button
              type="button"
              className={`setting-switch ${preferences.soundsEnabled ? "on" : ""}`}
              onClick={() => update({ soundsEnabled: !preferences.soundsEnabled })}
              aria-pressed={preferences.soundsEnabled}
            ><i /></button>
          </div>
        </article>

        <article className="settings-card future-settings">
          <header>
            <Icon icon="solar:shield-keyhole-bold-duotone" />
            <div><h2>更多设置</h2><p>为以后慢慢完善的小功能留好位置</p></div>
          </header>
          {[
            ["solar:lock-password-bold-duotone", "隐私与显示", "锁屏内容、敏感信息显示"],
            ["solar:database-bold-duotone", "数据与备份", "回信、相册和聊天导出"],
            ["solar:info-circle-bold-duotone", "关于爱情小屋", "版本、更新记录与使用说明"],
          ].map(([icon, label, description]) => (
            <button type="button" key={label} onClick={() => future(label)}>
              <Icon icon={icon} />
              <span><b>{label}</b><small>{description}</small></span>
              <em>即将开放</em>
              <Icon icon="solar:alt-arrow-right-linear" />
            </button>
          ))}
        </article>

        <article className="settings-card session-settings">
          <header>
            <Icon icon="solar:key-minimalistic-square-bold-duotone" />
            <div><h2>当前设备</h2><p>退出会关闭当前连线并清除登录状态</p></div>
          </header>
          <button type="button" className="settings-logout" onClick={leave}>
            <Icon icon="solar:logout-2-bold" />退出爱情小屋
          </button>
        </article>
      </section>
    </main>
  );
}
