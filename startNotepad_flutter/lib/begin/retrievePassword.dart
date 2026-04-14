import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'package:startnotepad_flutter/core/device/device_id_provider.dart';
import 'package:startnotepad_flutter/core/errors/app_exception.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_api.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:startnotepad_flutter/public/publicWidget.dart';

import '../begin/login.dart';

class RetrievePassword extends StatefulWidget {
  const RetrievePassword({super.key});

  @override
  State<RetrievePassword> createState() => _RetrievePasswordState();
}

class _RetrievePasswordState extends State<RetrievePassword> {
  final _usernameController = TextEditingController();
  final _emailPhoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  bool get _hasUsername => _usernameController.text.trim().isNotEmpty;
  bool get _hasEmailLocal => _emailPhoneController.text.trim().isNotEmpty;

  static const List<String> _emailSuffixOptions = <String>[
    '@163.com',
    '@qq.com',
    '@gmail.com',
    '@outlook.com',
    '@126.com',
  ];
  String _selectedEmailSuffix = '@163.com';

  bool _sending = false;
  int _secondsLeft = 0;

  String _errorMessage(Object e) {
    if (e is AppException) return e.message;
    return e.toString();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailPhoneController.dispose();
    _newPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String _) {
    if (!mounted) return;
    setState(() {});
  }

  void _onEmailLocalChanged(String _) {
    if (!mounted) return;
    setState(() {});
  }

  AuthRepositoryImpl _repo() => AuthRepositoryImpl(AuthApi(ApiClient()));

  Future<void> _pickEmailSuffix() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '选择邮箱后缀',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ..._emailSuffixOptions.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s),
                    trailing:
                        s == _selectedEmailSuffix
                            ? const Icon(Icons.check_rounded)
                            : null,
                    onTap: () => Navigator.pop(context, s),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;
    setState(() {
      _selectedEmailSuffix = selected;
    });
  }

  String _resolvedEmailPhone() {
    final local = _emailPhoneController.text.trim();
    if (local.isEmpty) return '';
    return '$local$_selectedEmailSuffix';
  }

  bool _validateIdentityOrToast() {
    final username = _usernameController.text.trim();
    final emailPhone = _resolvedEmailPhone();
    if (username.isEmpty && emailPhone.isEmpty) {
      Publicwidget.showToast(context, '用户名和邮箱至少填写一个', false);
      return false;
    }
    return true;
  }

  Future<void> _sendCode() async {
    if (_sending) return;
    if (!_validateIdentityOrToast()) return;
    setState(() {
      _sending = true;
    });

    try {
      final deviceId = await DeviceIdProvider.getOrCreate();
      await _repo().sendChangePasswordEmailCode(
        username: _usernameController.text.trim(),
        emailPhone: _resolvedEmailPhone(),
        deviceId: deviceId,
      );
      if (!mounted) return;
      Publicwidget.showToast(context, '验证码已发送', true);
      setState(() {
        _secondsLeft = 60;
      });
      while (mounted && _secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() {
          _secondsLeft--;
        });
      }
    } catch (e) {
      if (!mounted) return;
      Publicwidget.showToast(context, _errorMessage(e), false);
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _submit() async {
    try {
      if (!_validateIdentityOrToast()) return;
      if (_newPasswordController.text.isEmpty) {
        Publicwidget.showToast(context, '请输入新密码', false);
        return;
      }
      if (_codeController.text.trim().isEmpty) {
        Publicwidget.showToast(context, '请输入邮箱验证码', false);
        return;
      }
      final deviceId = await DeviceIdProvider.getOrCreate();
      await _repo().changePassword(
        username: _usernameController.text.trim(),
        emailPhone: _resolvedEmailPhone(),
        newPassword: _newPasswordController.text,
        emailCode: _codeController.text.trim(),
        deviceId: deviceId,
      );
      if (!mounted) return;
      Publicwidget.showLoading(context, '修改成功', 1);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: const Login(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Publicwidget.showToast(context, _errorMessage(e), false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                            '验证后重置你的密码',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          )
                          .animate()
                          .fadeIn(duration: 360.ms)
                          .slideY(begin: 0.03, end: 0, duration: 360.ms),
                      const SizedBox(height: 16),
                      Container(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                                  controller: _usernameController,
                                  enabled: !_hasEmailLocal,
                                  onChanged: _onUsernameChanged,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: '用户名',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    suffixIcon:
                                        _hasUsername
                                            ? IconButton(
                                              onPressed: () {
                                                _usernameController.clear();
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _emailPhoneController,
                                  enabled: !_hasUsername,
                                  onChanged: _onEmailLocalChanged,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: '邮箱',
                                    prefixIcon: const Icon(
                                      Icons.alternate_email,
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_hasEmailLocal)
                                          IconButton(
                                            onPressed: () {
                                              _emailPhoneController.clear();
                                              setState(() {});
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: _pickEmailSuffix,
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 120,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF3F4F6,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        _selectedEmailSuffix,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.expand_more_rounded,
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: '新密码',
                                    prefixIcon: Icon(Icons.lock_reset_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _codeController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: const InputDecoration(
                                          labelText: '邮箱验证码',
                                          prefixIcon: Icon(
                                            Icons.verified_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.tonal(
                                      onPressed:
                                          (_secondsLeft > 0) ? null : _sendCode,
                                      child: Text(
                                        _secondsLeft > 0
                                            ? '${_secondsLeft}s'
                                            : '获取验证码',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 420.ms)
                          .slideY(begin: 0.05, end: 0, duration: 420.ms),
                      const SizedBox(height: 18),
                      FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '提交修改',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 220.ms, duration: 450.ms)
                          .slideY(begin: 0.06, end: 0, duration: 450.ms),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
