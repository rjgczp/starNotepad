import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/core/theme/theme_provider.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_api.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:startnotepad_flutter/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:startnotepad_flutter/features/echo/presentation/echo_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_list_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/category_manage_page.dart';
import 'package:startnotepad_flutter/tools/localData.dart';
import '../begin/login.dart';
import '../core/sync/sync_offline_repository.dart';
import '../core/icons/iconfont_widget.dart';
import '../core/db/app_database.dart';
import '../features/note/presentation/diary_page_simple.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  static const String _profileCacheKey = 'user_profile_cache';
  static const String _profileUpdatedAtKey = 'user_profile_updated_at';
  static const String _profileNeedRefreshKey = 'user_profile_need_refresh';

  final AuthApi _authApi = AuthApi(ApiClient());

  bool _loading = true;
  bool _avatarUploading = false;
  String? _error;
  Map<String, dynamic> _user = <String, dynamic>{};
  List<Map<String, dynamic>> _tags = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    final cached = _readCachedProfile();
    if (cached != null) {
      _applyProfileData(cached);
    }

    final shouldRequest =
        forceRefresh ||
        cached == null ||
        LocalData.getBool(_profileNeedRefreshKey) ||
        _isProfileBasicInfoChanged(cached['user']);

    if (!shouldRequest) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    try {
      final response = await _authApi.getCurrentUserProfile();
      if (response.statusCode != 200) {
        throw Exception('获取个人资料失败: ${response.statusCode}');
      }

      final body = _asMap(response.data);
      final code = body['code'];
      if (code != 0 && code != 200) {
        throw Exception(
          body['msg']?.toString() ?? body['message']?.toString() ?? '获取个人资料失败',
        );
      }

      final data = _asMap(body['data']);
      final user = _asMap(data['user']);
      if (user.isNotEmpty) {
        final updatedAt = user['updatedAt']?.toString() ?? '';
        if (updatedAt.isNotEmpty) {
          await LocalData.setString(_profileUpdatedAtKey, updatedAt);
        }

        final nickname = user['nickname']?.toString().trim() ?? '';
        final avatar = user['avatar']?.toString().trim() ?? '';
        final signature = user['signature']?.toString().trim() ?? '';
        if (nickname.isNotEmpty) {
          await LocalData.setString(
            AuthRepositoryImpl.userDisplayNameKey,
            nickname,
          );
        }
        if (avatar.isNotEmpty) {
          await LocalData.setString(
            AuthRepositoryImpl.userAvatarPathKey,
            avatar,
          );
        }
        if (signature.isNotEmpty) {
          await LocalData.setString(
            AuthRepositoryImpl.userSignatureKey,
            signature,
          );
        }
      }

      await LocalData.setString(_profileCacheKey, jsonEncode(data));
      await LocalData.setBool(_profileNeedRefreshKey, false);

      if (!mounted) return;
      setState(() {
        _applyProfileData(data);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _user.isEmpty ? e.toString() : null;
      });
    }
  }

  Map<String, dynamic>? _readCachedProfile() {
    final raw = LocalData.getString(_profileCacheKey).trim();
    if (raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      return _asMap(parsed);
    } catch (_) {
      return null;
    }
  }

  bool _isProfileBasicInfoChanged(dynamic cachedUserRaw) {
    final cachedUser = _asMap(cachedUserRaw);
    if (cachedUser.isEmpty) return false;
    final cachedNickname = cachedUser['nickname']?.toString().trim() ?? '';
    final cachedAvatar = cachedUser['avatar']?.toString().trim() ?? '';
    final cachedSignature = cachedUser['signature']?.toString().trim() ?? '';

    final savedNickname =
        LocalData.getString(AuthRepositoryImpl.userDisplayNameKey).trim();
    final savedAvatar =
        LocalData.getString(AuthRepositoryImpl.userAvatarPathKey).trim();
    final savedSignature =
        LocalData.getString(AuthRepositoryImpl.userSignatureKey).trim();

    return cachedNickname != savedNickname ||
        cachedAvatar != savedAvatar ||
        cachedSignature != savedSignature;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  void _applyProfileData(Map<String, dynamic> data) {
    final user = _asMap(data['user']);
    final rawTags = data['tags'];
    final tags = <Map<String, dynamic>>[];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is Map) {
          tags.add(Map<String, dynamic>.from(item));
        }
      }
    }
    _user = user;
    _tags = tags;
  }

  Future<void> _saveProfileCache({required bool needRefresh}) async {
    await LocalData.setString(
      _profileCacheKey,
      jsonEncode(<String, dynamic>{'user': _user, 'tags': _tags}),
    );
    await LocalData.setBool(_profileNeedRefreshKey, needRefresh);
  }

  Future<void> _syncBasicProfileLocalKeys() async {
    final nickname = _user['nickname']?.toString().trim() ?? '';
    final avatar = _user['avatar']?.toString().trim() ?? '';
    final signature = _user['signature']?.toString().trim() ?? '';
    if (nickname.isNotEmpty) {
      await LocalData.setString(
        AuthRepositoryImpl.userDisplayNameKey,
        nickname,
      );
    }
    if (avatar.isNotEmpty) {
      await LocalData.setString(AuthRepositoryImpl.userAvatarPathKey, avatar);
    }
    if (signature.isNotEmpty) {
      await LocalData.setString(AuthRepositoryImpl.userSignatureKey, signature);
    }
  }

  Future<void> _editProfileField({
    required String title,
    required String fieldKey,
    required String currentValue,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (_) => _ProfileFieldEditPage(
              title: title,
              initialValue: currentValue,
              keyboardType: keyboardType,
            ),
      ),
    );

    if (result == null) return;

    try {
      await _updateProfileFieldRemote(fieldKey: fieldKey, value: result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    setState(() {
      _user[fieldKey] = result;
    });

    await _syncBasicProfileLocalKeys();
    await _saveProfileCache(needRefresh: false);
  }

  Future<void> _updateProfileFieldRemote({
    required String fieldKey,
    required String value,
  }) {
    switch (fieldKey) {
      case 'nickname':
        return _authApi.updateCurrentUserProfile(nickname: value);
      case 'signature':
        return _authApi.updateCurrentUserProfile(signature: value);
      case 'username':
        return _authApi.updateCurrentUserProfile(username: value);
      case 'emailPhone':
        return _authApi.updateCurrentUserProfile(emailPhone: value);
      case 'gender':
        return _authApi.updateCurrentUserProfile(gender: value);
      case 'address':
        return _authApi.updateCurrentUserProfile(address: value);
      default:
        return Future<void>.error(Exception('不支持的资料字段：$fieldKey'));
    }
  }

  Future<void> _showAvatarPickOptions() async {
    if (_avatarUploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('拍照'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('取消'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_avatarUploading) return;
    final activeControlsColor = Theme.of(context).colorScheme.primary;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black87,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: activeControlsColor,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: '裁剪头像',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      if (croppedFile == null) return;

      if (!mounted) return;
      setState(() => _avatarUploading = true);

      final uploadRes = await _authApi.uploadFile(filePath: croppedFile.path);
      final uploadBody = _asMap(uploadRes.data);
      final uploadCode = uploadBody['code'];
      if (uploadCode != 200 && uploadCode != 0) {
        throw Exception(uploadBody['message']?.toString() ?? '头像上传失败');
      }

      final uploadData = _asMap(uploadBody['data']);
      final fileMap = _asMap(uploadData['file']);
      final avatarUrl = fileMap['url']?.toString().trim() ?? '';
      if (avatarUrl.isEmpty) {
        throw Exception('头像上传失败：未返回文件地址');
      }

      final putRes = await _authApi.updateCurrentUserProfile(avatar: avatarUrl);
      final putBody = _asMap(putRes.data);
      final putCode = putBody['code'];
      if (putCode != 200 && putCode != 0) {
        throw Exception(
          putBody['msg']?.toString() ??
              putBody['message']?.toString() ??
              '更新头像失败',
        );
      }

      if (!mounted) return;
      setState(() {
        _user['avatar'] = avatarUrl;
      });

      await _syncBasicProfileLocalKeys();
      await _saveProfileCache(needRefresh: false);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像更新成功')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  String _avatarUrl() {
    final raw = _user['avatar']?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiClient.baseUrl}$raw';
    return '${ApiClient.baseUrl}/api/ufile/download/$raw';
  }

  Color _parseTagColor(String? color) {
    final raw = (color ?? '').trim();
    if (!raw.startsWith('#') || raw.length != 7) {
      return const Color(0xFF595959);
    }
    final value = int.tryParse(raw.replaceFirst('#', '0xFF'));
    return value == null ? const Color(0xFF595959) : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final token = LocalData.getString(ApiClient.tokenKey);
    final name =
        _user['nickname']?.toString().trim().isNotEmpty == true
            ? _user['nickname'].toString().trim()
            : LocalData.getString(AuthRepositoryImpl.userDisplayNameKey);
    final signature =
        _user['signature']?.toString().trim().isNotEmpty == true
            ? _user['signature'].toString().trim()
            : LocalData.getString(AuthRepositoryImpl.userSignatureKey);
    final address = _user['address']?.toString().trim() ?? '';
    final username = _user['username']?.toString().trim() ?? '';
    final gender = _user['gender']?.toString().trim() ?? '';
    final emailPhone = _user['emailPhone']?.toString().trim() ?? '';
    final avatarUrl = _avatarUrl();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('我的资料'),
        backgroundColor: colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadProfile(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新资料',
          ),
        ],
      ),
      body:
          _loading && _user.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _user.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarPickOptions,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  _avatarUploading
                                      ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                      : (avatarUrl.isNotEmpty
                                          ? Image.network(
                                            avatarUrl,
                                            headers:
                                                token.isNotEmpty
                                                    ? {'x-token': token}
                                                    : null,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.person_rounded,
                                                    ),
                                          )
                                          : const Icon(Icons.person_rounded)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap:
                                    () => _editProfileField(
                                      title: '修改昵称',
                                      fieldKey: 'nickname',
                                      currentValue: name,
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name.isNotEmpty ? name : '未设置昵称',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      // Icon(
                                      //   Icons.edit_outlined,
                                      //   size: 16,
                                      //   color: Colors.black.withValues(
                                      //     alpha: 0.38,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap:
                                    () => _editProfileField(
                                      title: '修改个性签名',
                                      fieldKey: 'signature',
                                      currentValue: signature,
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          signature.isNotEmpty
                                              ? signature
                                              : '这个人很懒，什么都没写',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      // Icon(
                                      //   Icons.edit_outlined,
                                      //   size: 16,
                                      //   color: Colors.black.withValues(
                                      //     alpha: 0.32,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '信息',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          '用户名',
                          username,
                          onTap:
                              () => _editProfileField(
                                title: '修改用户名',
                                fieldKey: 'username',
                                currentValue: username,
                              ),
                        ),
                        _buildInfoRow(
                          '联系方式',
                          emailPhone,
                          onTap:
                              () => _editProfileField(
                                title: '修改联系方式',
                                fieldKey: 'emailPhone',
                                currentValue: emailPhone,
                                keyboardType: TextInputType.emailAddress,
                              ),
                        ),
                        _buildInfoRow(
                          '性别',
                          gender,
                          onTap:
                              () => _editProfileField(
                                title: '修改性别',
                                fieldKey: 'gender',
                                currentValue: gender,
                              ),
                        ),
                        _buildInfoRow(
                          '地址',
                          address,
                          onTap:
                              () => _editProfileField(
                                title: '修改地址',
                                fieldKey: 'address',
                                currentValue: address,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '拥有的标签',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_tags.isEmpty)
                          Text(
                            '暂无标签',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _tags.map((tag) {
                                  final name = tag['Name']?.toString() ?? '';
                                  final color = _parseTagColor(
                                    tag['Color']?.toString(),
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.black.withValues(alpha: 0.35),
            ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: content,
    );
  }
}

class _ProfileFieldEditPage extends StatefulWidget {
  const _ProfileFieldEditPage({
    required this.title,
    required this.initialValue,
    this.keyboardType = TextInputType.text,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;

  @override
  State<_ProfileFieldEditPage> createState() => _ProfileFieldEditPageState();
}

class _ProfileFieldEditPageState extends State<_ProfileFieldEditPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            hintText: '请输入',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDrawerHeader extends StatefulWidget {
  const _UserDrawerHeader({
    required this.primary,
    required this.onGuestTap,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  final Color primary;
  final VoidCallback onGuestTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  @override
  State<_UserDrawerHeader> createState() => _UserDrawerHeaderState();
}

class _UserDrawerHeaderState extends State<_UserDrawerHeader> {
  String _name = '';
  String _avatarPath = '';
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _name = LocalData.getString(AuthRepositoryImpl.userDisplayNameKey);
    _avatarPath = LocalData.getString(AuthRepositoryImpl.userAvatarPathKey);
    _signature = LocalData.getString(AuthRepositoryImpl.userSignatureKey);
    print('[Drawer] name: $_name, avatarPath: $_avatarPath');
  }

  String _fullAvatarUrl() {
    final raw = _avatarPath.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiClient.baseUrl}$raw';
    final url = '${ApiClient.baseUrl}/api/ufile/download/$raw';
    print('[Drawer] Full avatar URL: $url');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final url = _fullAvatarUrl();
    final token = LocalData.getString(ApiClient.tokenKey);
    final isLoggedIn = token.isNotEmpty;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.black,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black54,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isLoggedIn ? widget.onProfileTap : widget.onGuestTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: widget.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: widget.primary.withValues(alpha: 0.22),
                ),
              ),
              child: ClipOval(
                child:
                    url.isNotEmpty
                        ? Image.network(
                          url,
                          headers: token.isNotEmpty ? {'x-token': token} : null,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.person_rounded),
                            );
                          },
                        )
                        : const Center(child: Icon(Icons.person_rounded)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _name.isNotEmpty ? _name : '未登录',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _signature.isNotEmpty
                        ? _signature
                        : (isLoggedIn ? '这个人很懒，什么都没写' : '点击这里去登录'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.onSettingsTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: widget.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '设置',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsEntry(
                      icon: Icons.palette_outlined,
                      title: '主题颜色',
                      subtitle: '可在记事本页顶部调色板中切换',
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const _ThemeColorManagePage(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsEntry(
                      icon: Icons.cloud_done_outlined,
                      title: '版本信息',
                      subtitle: '当前为测试版本  V0.1',
                    ),
                    const SizedBox(height: 12),
                    _SettingsEntry(
                      icon: Icons.info_outline_rounded,
                      title: '更多设置',
                      subtitle: '后续可继续补充到账户、通知等选项',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: content,
    );
  }
}

class _ThemeColorManagePage extends StatefulWidget {
  const _ThemeColorManagePage();

  @override
  State<_ThemeColorManagePage> createState() => _ThemeColorManagePageState();
}

class _ThemeColorManagePageState extends State<_ThemeColorManagePage> {
  final ThemeProvider _provider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _reorder(int oldIndex, int newIndex) {
    _provider.reorderColors(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = _provider.allColors;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('主题颜色'),
        backgroundColor: cs.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '长按拖拽调整顺序；右侧可切换显示/隐藏。',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  colors.isEmpty
                      ? Center(
                        child: Text(
                          '暂无主题颜色',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: colors.length,
                        onReorder: _reorder,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              return Material(
                                color: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = colors[index];
                          final visible = _provider.isColorVisible(item.id);
                          final isSelected =
                              (_provider.primaryColor.toARGB32() & 0xFFFFFF) ==
                              (item.color.toARGB32() & 0xFFFFFF);
                          return Container(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      width: 28,
                                      height: 40,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '（当前主题）',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '#${(item.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                                          style: TextStyle(
                                            color: Colors.black.withValues(
                                              alpha: 0.52,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Material(
                                    color: Colors.grey.shade700.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap:
                                          () => _provider.setColorVisibility(
                                            item.id,
                                            !visible,
                                          ),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 52,
                                        ),
                                        height: 38,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          visible ? '隐藏' : '显示',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatefulWidget {
  const _CategorySelector({
    required this.primary,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final Color primary;
  final int? selectedCategoryId;
  final Function(int? categoryId) onCategorySelected;

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  final SyncOfflineRepository _repo = SyncOfflineRepository();
  static const String _categoryOrderKey = 'category_order_local_ids';
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  int _totalNotes = 0;

  List<int> _readSavedOrder() {
    final raw = LocalData.getString(_categoryOrderKey).trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  List<Map<String, dynamic>> _applySavedOrder(List<Map<String, dynamic>> list) {
    final order = _readSavedOrder();
    if (order.isEmpty) return list;
    final rank = <int, int>{};
    for (var i = 0; i < order.length; i++) {
      rank[order[i]] = i;
    }

    final sorted = [...list];
    sorted.sort((a, b) {
      final aId = a['id'] as int?;
      final bId = b['id'] as int?;
      final aRank = aId != null ? rank[aId] : null;
      final bRank = bId != null ? rank[bId] : null;
      if (aRank != null && bRank != null) return aRank.compareTo(bRank);
      if (aRank != null) return -1;
      if (bRank != null) return 1;
      return 0;
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTotalNotes();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _repo.getAllCategories();
      setState(() {
        final mapped =
            list
                .where((cat) {
                  if (cat.userId != 0) return true;
                  final key = 'category_visible_${cat.localId}';
                  final saved = LocalData.getValue(key);
                  return saved is bool ? saved : true;
                })
                .map(
                  (cat) => {
                    'id': cat.localId,
                    'ID': cat.remoteId,
                    'name': cat.name,
                    'color': cat.color,
                    'icon': cat.icon,
                    'userId': cat.userId,
                  },
                )
                .toList();
        _categories = _applySavedOrder(mapped);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTotalNotes() async {
    try {
      final pageResult = await _repo.loadPage(
        page: 1,
        pageSize: 1, // 只需要获取总数，不需要具体数据
        categoryId: null,
      );
      setState(() {
        _totalNotes = pageResult.total;
      });
    } catch (e) {
      // 如果获取失败，保持为 0
      setState(() {
        _totalNotes = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              '分类',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 全部按钮
          _buildCategoryButton(
            id: null,
            name: '全部',
            iconStr: 'apps',
            count: _totalNotes,
            isSelected: widget.selectedCategoryId == null,
          ),
          // 分类按钮列表
          ..._categories.map(
            (category) => _buildCategoryButton(
              id: category['ID'], // 修改：使用 'ID' 而不是 'id'
              name: category['name'] ?? '',
              iconStr: category['icon'] ?? '',
              color: category['color'],
              isSelected:
                  widget.selectedCategoryId == category['ID'], // 修改：使用 'ID'
            ),
          ),
          const SizedBox(height: 4),
          _buildManageCategoryEntry(),
        ],
      ),
    );
  }

  Widget _buildManageCategoryEntry() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final navigator = Navigator.of(context);
          navigator.pop();
          final created = await navigator.push<bool>(
            MaterialPageRoute(builder: (_) => const CategoryManagePage()),
          );
          if (created == true && mounted) {
            await _loadCategories();
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('分类已更新')));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: widget.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '管理分类',
                  style: TextStyle(
                    color: widget.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required int? id,
    required String name,
    required String iconStr,
    int? count,
    String? color,
    required bool isSelected,
  }) {
    Color buttonColor;
    if (isSelected) {
      buttonColor = widget.primary;
    } else if (color != null && color.startsWith('#')) {
      buttonColor = Color(int.parse(color.replaceFirst('#', '0xFF')));
    } else {
      buttonColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? widget.primary.withValues(alpha: 0.12)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onCategorySelected(id);
          Navigator.of(context).pop(); // 关闭侧栏
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconfontWidget(iconName: iconStr, size: 20, color: buttonColor),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? widget.primary : Colors.black87,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: widget.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavItemData {
  const _HomeNavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final iconColor = selected ? primary : Colors.black54;
    final base = Theme.of(context).textTheme.labelSmall;
    final textStyle = base
        ?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? primary : Colors.black54,
        )
        .copyWith(
          fontSize: ((base.fontSize ?? 11) / scale).clamp(10, 12),
          height: 1.0,
        );

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    selected
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary.withValues(alpha: 0.20),
                            primary.withValues(alpha: 0.08),
                          ],
                        )
                        : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                scale: selected ? 1.05 : 1.0,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  int? _selectedCategoryId;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController = PageController();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    ThemeProvider().syncFromApi();
    _updatePages();

    // 清理重复数据（异步执行，不阻塞UI）
    _cleanupDuplicateData();
  }

  Future<void> _cleanupDuplicateData() async {
    try {
      final db = AppDatabase();
      final deletedCount = await db.cleanupDuplicateNotes();
      if (deletedCount > 0) {
        print('清理了 $deletedCount 条重复笔记');
      }
    } catch (e) {
      print('清理重复数据失败: $e');
    }
  }

  void _openLoginFromDrawer() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
  }

  void _openSettingsPage() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _SettingsPage()));
  }

  void _openProfilePage() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _ProfilePage()));
  }

  Future<void> _syncDataFromDrawer() async {
    Navigator.of(context).pop();
    try {
      final noteRepo = SyncOfflineRepository();
      await noteRepo.syncSilently();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据同步完成')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('同步失败：$e')));
    }
  }

  Future<void> _logout() async {
    try {
      // 关闭侧栏
      Navigator.of(context).pop();

      // 执行退出登录
      final authRepo = AuthRepositoryImpl(AuthApi(ApiClient()));
      await authRepo.logout();

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已退出登录，进入离线模式'),
          duration: Duration(seconds: 2),
        ),
      );

      // 触发重建，进入离线模式
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败：$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updatePages() {
    _pages = <Widget>[
      NoteListPage(
        key: ValueKey('category_$_selectedCategoryId'),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        categoryId: _selectedCategoryId,
      ),
      const DiaryPage(),
      const EchoPage(),
      const AiAssistantPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const items = <_HomeNavItemData>[
      _HomeNavItemData(label: '记事本', icon: Icons.note_alt_outlined),
      _HomeNavItemData(label: '日记', icon: Icons.book_outlined),
      _HomeNavItemData(label: '回响', icon: Icons.hourglass_empty_rounded),
      _HomeNavItemData(label: '更多', icon: Icons.more_horiz_rounded),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _UserDrawerHeader(
                primary: colorScheme.primary,
                onGuestTap: _openLoginFromDrawer,
                onProfileTap: _openProfilePage,
                onSettingsTap: _openSettingsPage,
              ),
              const SizedBox(height: 12),
              _CategorySelector(
                primary: colorScheme.primary,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _updatePages();
                  });
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildDrawerActionButton(
                  icon: Icons.sync_rounded,
                  label: '同步数据',
                  color: colorScheme.primary,
                  onTap: _syncDataFromDrawer,
                ),
              ),
              // 退出登录按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '退出登录',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          // Floating bottom navigation
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final selected = index == _currentIndex;

                        return Expanded(
                          child: _HomeNavItem(
                            label: item.label,
                            icon: item.icon,
                            selected: selected,
                            primary: colorScheme.primary,
                            onTap: () {
                              if (_currentIndex == index) return;
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
