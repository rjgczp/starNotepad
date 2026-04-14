import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:startnotepad_flutter/begin/login.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../main/home.dart';

class Lead extends StatefulWidget {
  const Lead({super.key});

  @override
  State<Lead> createState() => _LeadState();
}

class _LeadState extends State<Lead> with TickerProviderStateMixin {
  Timer? _timer;
  int _skipIndex = 3;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setWhiteStatusBar();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _skipIndex--;
      });
      if (_skipIndex <= 0) {
        _goNext();
      }
    });
  }

  void _goNext() async {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();
    if (!mounted) return;

    // 检查token
    await _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      // 获取保存的token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // 检查是否选择了离线模式
      final offlineMode = prefs.getBool('offline_mode') ?? false;

      if (offlineMode) {
        // 用户选择了离线模式，直接进入首页
        _navigateToHome();
        return;
      }

      if (token == null || token.isEmpty) {
        // 没有token，去登录页
        _navigateToLogin();
        return;
      }

      // 有token，验证有效性
      final apiClient = ApiClient();
      final response = await apiClient.request(
        '/api/unote/checkToken',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = response.data;
      final code = body['code'];

      if (code == 200) {
        // token有效，保存新token并去首页
        final newToken = body['data']['token'];
        if (newToken != null) {
          await prefs.setString('token', newToken);
        }
        _navigateToHome();
      } else {
        // token无效，去登录页
        await prefs.remove('token');
        _navigateToLogin();
      }
    } catch (e) {
      // 出错，去登录页
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: const Login(),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: const Home(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  //状态栏图标为白色

  void _setWhiteStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/imgs/lead.png', fit: BoxFit.cover),
          ),
          //底部白色信息框
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/icons/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '星记事',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '把灵感、日程与待办都收进同一处',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _goNext,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('进入 ${_skipIndex}s'),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.18,
                      end: 0,
                      duration: 520.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
