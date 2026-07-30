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
