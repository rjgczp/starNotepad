# 情侣空间前端

基于 React、Vite 和 WebRTC 的双人空间，包含个人状态、记忆树主页、相册、每日回信、聊天和音视频通话。生产入口为 <https://ai.xiaoyu.ski>。

## 开发

```bash
cp .env.example .env.local
npm ci
DUO_API_PROXY=http://127.0.0.1:8888 npm run dev
```

访问 <http://localhost:3002>。

| 变量 | 用途 |
| --- | --- |
| `VITE_DUO_API_URL` | 浏览器 API 前缀，通常保持 `/api` |
| `DUO_API_PROXY` | Vite 开发服务器代理目标 |
| `VITE_DUO_ICE_SERVERS` | 本地 ICE 兜底 JSON；生产由后端返回 |

真实 TURN 用户名和密码由已认证的后端启动接口下发，不要写入前端 `.env` 或镜像。

## 检查与构建

```bash
npm run lint
npm test
npm run build
npm run preview
```

生产镜像使用 Nginx 提供 `dist/` 静态文件，根 Compose 服务名为 `duo-call-web`。WebSocket、TURN、微信与部署配置见父项目 [文档索引](../docs/README.md)。

## Android APK

Android 客户端使用 Capacitor，共用当前 React/Vite 页面。需要 JDK 21、Android
SDK，以及可用的 `ANDROID_HOME` 或 `ANDROID_SDK_ROOT`。

首次构建前准备原生环境配置：

```bash
cp .env.native.example .env.native
npm run android:build:debug
```

debug APK 输出到：

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

在 Android Studio 中调试可运行：

```bash
npm run android:sync
npm run android:open
```

生成供 Google Play 使用的 AAB：

```bash
npm run android:build:release
```

release 构建需要由发布者在本机或 CI 配置 Android keystore 和 Gradle signing
config。仓库会忽略 `.jks`、`.keystore` 和本地密码配置，不包含生产签名凭据。

## 三端一键打包

`npm run package:three-platforms` 会在一次检查后依次产出 Web 静态文件、Android
正式签名的 APK/AAB，以及当前操作系统的 Tauri 桌面安装包。首次使用前配置 Android
签名（私钥和密码均不会提交到仓库）：

```bash
cp android/keystore.properties.example android/keystore.properties
# 将正式 .jks 文件放到 android/keystore/release.jks，或修改 storeFile 为其真实路径
# 然后填写 storePassword、keyAlias、keyPassword
npm run package:three-platforms
```

脚本会校验 `package.json`、`src-tauri/tauri.conf.json` 与 Android 的 `versionName`
一致，不会覆盖已有发布目录。完成后文件位于 `releases/<版本号>/`：

- `web/`：可直接部署的网页静态文件；
- `android/`：用于安装/更新的 APK 与用于应用商店的 AAB；
- `desktop/`：当前构建系统的桌面安装包；
- `SHA256SUMS`：所有发布文件的校验和。

macOS 只能直接产出 macOS 桌面包；Windows 安装包继续使用仓库的 Windows GitHub
Actions 工作流生成。将 APK 或桌面安装包上传到可访问的 HTTPS 地址后，再在 GVA
“爱情小屋 → 应用发版”中填写该地址并发布即可。

## 桌面应用

桌面客户端使用 Tauri 2，共用同一份 `dist/`。需要 Rust stable，以及目标系统的
Tauri 平台依赖。

```bash
cp .env.native.example .env.native
npm run desktop:dev
npm run desktop:build
```

macOS 输出位于 `src-tauri/target/release/bundle/macos/` 和
`src-tauri/target/release/bundle/dmg/`。Windows 会在对应 bundle 目录生成
安装包；Linux 会生成当前工具链支持的包格式。

公开分发前应替换 `src-tauri/icons/` 中的占位图标，并在发布环境提供 Apple
Developer、Windows Authenticode 或 Linux 仓库所需的外部签名配置。证书和私钥
不得加入仓库。

## 应用更新与发布

爱情小屋会在启动时向后端查询已发布的、且高于当前版本的平台发行版；有新版本
时会显示更新弹窗、更新说明和下载按钮。可选更新在本次打开期间可以暂缓，强制
更新则必须下载安装新版后才能继续使用。

在 GVA 的“爱情小屋 → 应用发版”中创建发布记录：选择 `Android`、`桌面端` 或
`网页版`，填写语义化版本号（如 `0.2.0`），也可以直接上传 APK/AAB、DMG、MSI、EXE
等安装包；上传完成后下载地址会自动填入。再填写更新说明并勾选“立即发布”。草稿
不会被客户端读取。每个平台的版本号只能使用一次；若需要撤回，取消发布或删除该
记录即可。

发布客户端前，请同步递增 `package.json`、`src-tauri/tauri.conf.json` 和 Android
的 `versionName`/`versionCode`。构建时也可以传入
`VITE_DUO_APP_VERSION=0.2.0`，用于覆盖客户端上报的版本号；它必须与 GVA 中该
平台的发布版本一致。

## 原生运行时与服务端

打包客户端不能使用网页的相对 `/api` 代理，因此 `.env.native` 必须配置：

```dotenv
VITE_DUO_NATIVE=true
VITE_DUO_API_URL=https://ai.xiaoyu.ski/api
```

服务端情侣空间路由允许任意浏览器或 WebView Origin，但安全策略固定为：

- `Access-Control-Allow-Origin: *`
- 不发送 `Access-Control-Allow-Credentials`
- 只允许 `Authorization` 和 `Content-Type` 请求头
- 除登录外的业务接口仍要求显式 Bearer Token
- 登录请求体限制为 4 KiB，并按客户端 IP 限制尝试频率

因此新增 Capacitor hostname、Tauri scheme 或其他受信任客户端不需要重新部署
CORS 白名单。情侣客户端不得改用 Cookie 作为跨域身份凭据。

## 系统视频悬浮窗与品牌资源

通话控制中的“悬浮窗”在普通浏览器中调用视频 Picture-in-Picture，并在视频元
数据就绪后才发起请求。Windows、macOS 和 Linux 的 Tauri 客户端使用可恢复尺寸
的系统置顶视频窗，避免桌面 WebView 对 MediaStream 画中画支持不一致。Android
8.0 及以上通过应用内 Capacitor 插件进入原生 Activity 画中画，清单必须保留
`android:supportsPictureInPicture="true"`。

统一 Logo 母版位于 `assets/brand/logo-master.png`。修改母版后应重新运行：

```bash
npm exec tauri icon -- assets/brand/logo-master.png
```

并同步更新 Android `mipmap-*`、Web `public/` 图标和品牌启动图。不要恢复
Capacitor/Tauri 默认占位图标。

## Windows 自动构建

`.github/workflows/duo-windows-desktop.yml` 在真实 Windows runner 上构建 Tauri
NSIS `.exe` 与 MSI 安装包。工作流会运行前端测试，使用固定的线上 HTTPS API，
并把安装包上传为保留 30 天的 GitHub Actions artifact。

当前工作流不包含 Authenticode 私钥。未签名安装包适合私下测试，但 Windows
SmartScreen 可能显示“未知发布者”；公开分发前应在 CI 中接入外部代码签名服务。

## 真机验收

安装 APK 或桌面包后至少验证：

1. 两个身份分别登录，重启应用后会话仍可恢复。
2. 头像、聊天图片、相册和记忆树图片均从线上 `/uploads/` 正常显示。
3. 文本消息、已读状态、在线状态和 WebSocket 重连正常。
4. 首次通话会出现摄像头与麦克风权限提示。
5. Wi-Fi 与蜂窝网络之间进行一次 TURN 辅助的双向音视频通话。

debug APK 使用开发签名，只适合测试。公开 APK/AAB、DMG 或 Windows 安装包仍需
正式图标、版本号、签名与对应平台的分发审核。

### Android 通话真机验收

在 Android 13+ 首次开启消息提醒时允许系统通知；首次发起通话时允许相机和麦克风。
两台真机连接同一通话后，让其中一台在通话已建立后再开启摄像头，另一台应在无需
重连的情况下出现画面。随后按 Home 或切换应用：系统应显示“爱情小屋正在通话”
通知并进入画中画；点按小窗或通知应返回通话，挂断后小窗和常驻通知应消失。部分
厂商的省电策略会终止后台进程，应在系统设置中允许该应用后台活动后复测。
