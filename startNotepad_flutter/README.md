# 星记事 Flutter App

星记事移动端用于笔记、日记和离线同步，后端由父项目的 Gin API 提供。

## 环境

- Flutter SDK（Dart `^3.7.2`）
- Android Studio/Xcode 及对应平台工具链

```bash
flutter pub get
flutter doctor
```

## 运行

Android 模拟器默认 API 为 `http://10.0.2.2:8888`：

```bash
flutter run
```

真机、本地局域网或生产环境应在编译时传入地址：

```bash
flutter run --dart-define=BASE_URL=https://xiaoyu.ski
```

可选编译变量：

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `BASE_URL` | `http://10.0.2.2:8888` | API 网关根地址，不带末尾 `/api` |
| `EMAIL_VERIFY_CODE_MODE` | `false` | 是否启用邮件验证码模式 |

## 生成与检查

修改 Drift 数据表后：

```bash
dart run build_runner build --delete-conflicting-outputs
```

提交前：

```bash
flutter analyze
flutter test
```

生产构建示例：

```bash
flutter build apk --release --dart-define=BASE_URL=https://xiaoyu.ski
```

整套后端、本地 Compose 与生产部署见父项目 [文档索引](../docs/README.md)。
