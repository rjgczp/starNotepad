import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'package:startnotepad_flutter/begin/agreement.dart';
import 'package:startnotepad_flutter/begin/retrievePassword.dart';
import 'package:startnotepad_flutter/main/home.dart';
import 'package:startnotepad_flutter/public/publicWidget.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/core/errors/app_exception.dart';
import 'package:startnotepad_flutter/core/device/device_id_provider.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_api.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:startnotepad_flutter/features/note/data/note_api.dart';
import 'package:startnotepad_flutter/features/note/data/note_offline_repository.dart';
import 'package:startnotepad_flutter/tools/localData.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isVisible = false;

  final NoteOfflineRepository _noteRepo = NoteOfflineRepository(
    NoteApi(ApiClient()),
  );

  String _errorMessage(Object e) {
    if (e is AppException) return e.message;
    return e.toString();
  }

  Future<void> _syncNotesAfterLogin() async {
    try {
      await _noteRepo.syncSilently();
    } catch (e) {
      print('[Login] silent note sync failed: $e');
    }
  }

  Future<void> _enterHomeAfterLogin() async {
    if (!mounted) return;
    Publicwidget.showLoading(context, "登录中...", 1);
    await _syncNotesAfterLogin();
    if (!mounted) return;
    await Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Home(),
        ),
      );
    });
  }

  Future<void> _showEmailVerifyDialog({
    required AuthRepositoryImpl repo,
    required String challengeId,
  }) async {
    final codeController = TextEditingController();
    final deviceId = await DeviceIdProvider.getOrCreate();

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
            child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0x1F000000),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '邮箱验证码验证',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '验证码已发送至邮箱，请输入验证码完成登录。',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: '验证码'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                try {
                                  await repo.loginVerify(
                                    challengeId: challengeId,
                                    emailCode: codeController.text,
                                    deviceId: deviceId,
                                  );
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  await _enterHomeAfterLogin();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  Publicwidget.showToast(
                                    context,
                                    _errorMessage(e),
                                    false,
                                  );
                                }
                              },
                              child: const Text('验证登录'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                .slideY(begin: 0.08, end: 0, duration: 260.ms),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = "123";
    _passwordController.text = "123456";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFF6F7F8)),
            ),
          ),
          // Positioned(
          //   top: 8,
          //   right: 8,
          //   child: SafeArea(
          //     child: FilledButton.tonal(
          //           onPressed: () {
          //             Publicwidget.showSupportDialog(context);
          //           },
          //           style: FilledButton.styleFrom(
          //             padding: const EdgeInsets.symmetric(
          //               horizontal: 12,
          //               vertical: 8,
          //             ),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(999),
          //             ),
          //           ),
          //           child: const Text('联系客服'),
          //         )
          //         .animate()
          //         .fadeIn(delay: 220.ms, duration: 380.ms)
          //         .slideX(begin: 0.08, end: 0, curve: Curves.easeOut),
          //   ),
          // ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: -80,
                    child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .move(
                          begin: const Offset(-12, -6),
                          end: const Offset(12, 6),
                          duration: 6.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    bottom: -140,
                    right: -110,
                    child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.98, 0.98),
                          end: const Offset(1.02, 1.02),
                          duration: 7.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 52,
                        maxWidth: 520,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(flex: 2),
                            Text(
                                  '登录',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.04,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(height: 10),
                            Text(
                                  '未注册账号将自动注册',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                    height: 1.25,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 120.ms, duration: 400.ms)
                                .slideY(begin: 0.04, end: 0, duration: 400.ms),
                            const SizedBox(height: 28),
                            Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    28,
                                    18,
                                    18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 24,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: const InputDecoration(
                                          labelText: '账号',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: !_isVisible,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: InputDecoration(
                                          labelText: '密码',
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isVisible = !_isVisible;
                                              });
                                            },
                                            icon: Icon(
                                              _isVisible
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Publicwidget.showSupportSheet(
                                                context,
                                              );
                                            },
                                            child: const Text(
                                              '联系客服',
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                PageTransition(
                                                  type:
                                                      PageTransitionType
                                                          .rightToLeft,
                                                  duration: Duration(
                                                    milliseconds: 400,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  child:
                                                      const RetrievePassword(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              '忘记密码？',
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 450.ms)
                                .slideY(begin: 0.06, end: 0, duration: 450.ms),
                            const SizedBox(height: 18),
                            ElevatedButton(
                                  onPressed: () async {
                                    final deviceId =
                                        await DeviceIdProvider.getOrCreate();
                                    final repo = AuthRepositoryImpl(
                                      AuthApi(ApiClient()),
                                    );

                                    try {
                                      await repo.login(
                                        username: _emailController.text,
                                        password: _passwordController.text,
                                        deviceId: deviceId,
                                      );
                                      await _enterHomeAfterLogin();
                                    } on NeedEmailVerifyException catch (e) {
                                      if (!context.mounted) return;
                                      Publicwidget.showToast(
                                        context,
                                        e.message,
                                        true,
                                      );
                                      await _showEmailVerifyDialog(
                                        repo: repo,
                                        challengeId: e.challengeId,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      Publicwidget.showToast(
                                        context,
                                        _errorMessage(e),
                                        false,
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '登录',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 320.ms, duration: 450.ms)
                                .slideY(begin: 0.06, end: 0, duration: 450.ms)
                                .scale(
                                  begin: const Offset(0.98, 0.98),
                                  end: const Offset(1, 1),
                                  duration: 350.ms,
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(height: 8),
                            TextButton(
                                  onPressed: () async {
                                    Publicwidget.showToast(
                                      context,
                                      "准备中...",
                                      true,
                                    );
                                    // 保存用户选择了离线模式
                                    await LocalData.setBool(
                                      'offline_mode',
                                      true,
                                    );
                                    await Future.delayed(Duration(seconds: 2));
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          duration: Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                          child: Home(),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '直接使用',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 380.ms, duration: 450.ms)
                                .slideY(begin: 0.06, end: 0, duration: 450.ms),
                            const Spacer(flex: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '点击登录即表示同意',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        duration: Duration(milliseconds: 400),
                                        curve: Curves.easeInOut,
                                        child: Agreement(),
                                      ),
                                    );
                                  },
                                  child: const Text('《用户服务协议》'),
                                ),
                              ],
                            ).animate().fadeIn(delay: 460.ms, duration: 450.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
